local gps = require("gps")
local posUtil = require("posUtil")
local scanner = require("scanner")
local config = require("config")

local storage = {}
local reverseStorage = {} -- for a faster lookup of already existing crops
local farm = {} -- odd slots only

local lowestTier
local lowestTierSlot
local lowestGr
local lowestGrSlot
local lowestGa
local lowestGaSlot

local function getStorage()
    return storage
end

local function getFarm()
    return farm
end

local function scanFarm()
    gps.save()
    for slot=1, config.farmSize^2, 2 do
        gps.go(posUtil.farmToGlobal(slot))
        local cropInfo = scanner.scan()
        if cropInfo.name == "air" then
            cropInfo.tier = 0
            cropInfo.gr = 0
            cropInfo.ga = 0
            cropInfo.re = 100
        end
        if cropInfo.isCrop then
            farm[slot] = cropInfo
        end
    end
    gps.resume()
end

local function updateLowestTier()
    lowestTier = 100
    lowestTierSlot = 0
    for slot, crop in pairs(farm) do
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
    for slot, crop in pairs(farm) do
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

local function scanStorage()
    gps.save()
    for slot=1, config.storageFarmSize^2 do
        gps.go(posUtil.storageToGlobal(slot))
        local cropInfo = scanner.scan()
        if cropInfo.name ~= "air" then
            storage[slot] = cropInfo
            reverseStorage[cropInfo.name] = slot
        else
            break
        end
    end
    gps.resume()
end

local function scanAll()
    scanFarm()
    updateLowestTier()
    scanStorage()
end

local function existInStorage(crop)
    -- I know I can simply write "return reverseStorage[crop.name]"
    -- But I want the api have a clean return value (alway bool)
    if reverseStorage[crop.name] then
        return true
    else
        return false
    end
end

local function nextStorageSlot()
    return #storage+1
end

local function addToStorage(crop)
    storage[#storage+1] = crop
    reverseStorage[crop.name] = #storage
end

local function updateFarm(slot, crop)
    farm[slot] = crop
    updateLowestTier()
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

return {
    getStorage = getStorage,
    getFarm = getFarm,
    scanAll = scanAll,
    existInStorage = existInStorage,
    nextStorageSlot = nextStorageSlot,
    addToStorage = addToStorage,
    updateFarm = updateFarm,
    findSuitableFarmSlot = findSuitableFarmSlot
}
