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

local function updateLowest()
    lowestTier = 100
    lowestTierSlot = 0
    lowestGr = 100
    lowestGrSlot = 0
    lowestGa = 100
    lowestGaSlot = 0
    local farm = database.getFarm()
    local farmArea = config.farmSize^2
    -- pairs() is slower than numeric for due to function call overhead.
    for slot=1, farmArea, 2 do
        local crop = farm[slot]
        if crop ~= nil then
            if crop.tier < lowestTier then
                lowestTier = crop.tier
                lowestTierSlot = slot
            end
        end
    end
    for slot=1, farmArea, 2 do
        local crop = farm[slot]
        if crop ~= nil then
            if crop.tier == lowestTier then
                if crop.gr < lowestGr then
                    lowestGr = crop.gr
                    lowestGrSlot = slot
                end
            end
        end
    end
    for slot=1, farmArea, 2 do
        local crop = farm[slot]
        if crop ~= nil then
            if crop.tier == lowestTier and crop.gr == lowestGr then
                if crop.ga < lowestGa then
                    lowestGa = crop.ga
                    lowestGaSlot = slot
                end
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
                        updateLowest()
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
    database.scanFarm()
    database.scanStorage()
    updateLowest()
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
