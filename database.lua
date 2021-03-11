local gps = require("gps")
local posUtil = require("posUtil")
local scanner = require("scanner")
local config = require("config")

local storage = {}
local reverseStorage = {} -- for a faster lookup of already existing crops
local farm = {} -- odd slots only

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
            farm[slot] = cropInfo
        elseif cropInfo.isCrop then
            farm[slot] = cropInfo
        end
    end
    gps.resume()
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
end

return {
    getStorage = getStorage,
    getFarm = getFarm,
    scanAll = scanAll,
    existInStorage = existInStorage,
    nextStorageSlot = nextStorageSlot,
    addToStorage = addToStorage,
    updateFarm = updateFarm
}
