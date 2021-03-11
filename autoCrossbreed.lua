local gps = require("gps")
local action = require("action")
local database = require("database")
local scanner = require("scanner")
local posUtil = require("posUtil")
local config = require("config")

local lowestTier
local lowestTierSlot
local lowestGr
local lowestGrSlot
local lowestGa
local lowestGaSlot

local function updateLowestTier()
    lowestTier = 100
    lowestTierSlot = 0
    for slot, crop in pairs(database.getFarm()) do
        if crop.tier < lowestTier then
            lowestTier = crop.tier
            lowestTierSlot = slot
        end
    end
end

local function updateGrGaWithTier(tier)
    lowestGr = 100
    lowestGrSlot = 0
    lowestGa = 100
    lowestGaSlot = 0
    for slot, crop in pairs(database.getFarm()) do
        if crop.tier <= tier then
            if crop.gr < lowestGr then
                lowestGr = crop.gr
                lowestGrSlot = slot
            end
            if crop.ga < lowestGa then
                lowestGa = crop.ga
                lowestGaSlot = slot
            end
        end
    end
end

local function findSuitableFarmSlot(crop)
    -- if the return value > 0, then it's a valid crop slot
    -- if the return value == 0, then it's not a valid crop slot
    --     the caller may consider not to replace any crop.
    if crop.tier > lowestTier then
        return lowestTierSlot
    elseif crop.tier == lowestTier then
        -- make sure a lower tier crop does not replace a higher tier crop
        -- even though this has much worse performance than the previous commit
        -- this is how I lost a space plant :(
        updateGrGaWithTier(crop.tier)
        if crop.gr > lowestGr then
            return lowestGrSlot
        elseif crop.gr == lowestGr then
            if crop.ga > lowestGa then
                return lowestGaSlot
            end
        end
    end
    return 0
end

local function breedOnce()
    for slot=2, config.farmSize^2, 2 do
        gps.go(posUtil.farmToGlobal(slot))
        local crop = scanner.scan()
        if crop.name == "air" then
            action.cross()
            action.cross()
        elseif crop.name == "crop" then
            action.cross()
        elseif crop.isCrop then
            if crop.name == "weed" or crop.gr > 21 or
              (crop.name == "venomilia" and crop.ga > 7) then
                action.deweed()
                action.cross()
            else
                if database.existInStorage(crop) then
                    local suitableSlot = findSuitableFarmSlot(crop)
                    if suitableSlot == 0 or crop.re > 0 then
                        action.deweed()
                        action.cross()
                    else
                        action.transplant(posUtil.farmToGlobal(slot), posUtil.farmToGlobal(suitableSlot))
                        action.cross()
                        action.cross()
                        database.updateFarm(suitableSlot, crop)
                        updateLowestTier()
                    end
                else
                    action.transplant(posUtil.farmToGlobal(slot), posUtil.storageToGlobal(database.nextStorageSlot()))
                    action.cross()
                    action.cross()
                    database.addToStorage(crop)
                end
            end
        end
    end
end

local function init()
    database.scanAll()
    updateLowestTier()
    action.restockAll()
end

local function main()
    init()
    while true do
        breedOnce()
        gps.go({0,0})
        action.restockAll()
    end
end

main()
