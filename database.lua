local gps = require("gps")
local posUtil = require("posUtil")
local scanner = require("scanner")
local config = require("config")

--[[
If you are reading the source code and got confused by the whole "slot" thing,
here is some explanation:
So we have two farmlands:
A storage farm land for storing unseen crops.
Only one crop per type can exist in the storage farmland.
A farmland for main crossbreeding things, the crop used for crossbreeding
and the space for new crops to grow form a checkerboard pattern.
the slot number for storage farmland start with 1 and from the bottom-right corner of the land,
and the number increases in a zigzag pattern from right to left. Like this:
-------
|9|4|3|
|8|5|2|
|7|6|1|
-------
And the slot number for the main farmland follow the same rule as the storage farmland,
but the number increases from left to right. Like this:
-------
|3|4|9|
|2|5|8|
|1|6|7|
-------
]]

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
    scanFarm = scanFarm,
    scanStorage = scanStorage,
    existInStorage = existInStorage,
    nextStorageSlot = nextStorageSlot,
    addToStorage = addToStorage,
    updateFarm = updateFarm
}
