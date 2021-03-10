local gps = require("gps")
local posUtil = require("posUtil")
local scanner = require("scanner")
local config = require("config")

local storage = {}
local reverseStorage = {} -- for a faster lookup of already existing crops
local farm = {} -- odd slots only

local lowestTier = 100
local lowestTierSlot = 0
local lowestGr = 100
local lowestGrSlot = 0
local lowestGa = 100
local lowestGaSlot = 0

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
        local cropInfo = scanner.scan("")
        if cropInfo.name ~= "air" then
            farm[slot] = cropInfo
        end
    end
    gps.resume()
end

local function updateHighestLowest()
    for slot, crop in pairs(farm) do
        if crop.tier < lowestTier then
            lowestTier = crop.tier
            lowestTierSlot = slot
        end
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

local function scanStorage()
    gps.save()
    for slot=1, config.storageFarmSize^2 do
        gps.go(posUtil.storageToGlobal(slot))
        local cropInfo = scanner.scan("")
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
    updateHighestLowest()
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
    updateHighestLowest()
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
    else
        return 0
    end
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
