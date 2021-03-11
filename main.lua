local gps = require("gps")
local action = require("action")
local database = require("database")
local scanner = require("scanner")
local posUtil = require("posUtil")
local config = require "config"

local function init()
    database.scanAll()
    action.restockAll()
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
            if crop.name == "weed" or crop.ga > 21 or crop.re > 2 then
                action.deweed()
                action.cross()
            else
                if database.existInStorage(crop) then
                    local suitableSlot = database.findSuitableFarmSlot(crop)
                    if suitableSlot == 0 then
                        action.deweed()
                        action.cross()
                    else
                        action.transplant(posUtil.farmToGlobal(slot), posUtil.farmToGlobal(suitableSlot))
                        action.cross()
                        action.cross()
                        database.updateFarm(suitableSlot, crop)
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

local function main()
    init()
    while true do
        breedOnce()
        gps.go({0,0})
        action.restockAll()
    end
end

main()
