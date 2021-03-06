local database = require("database")
local gps = require("gps")
local posUtil = require("posUtil")
local scanner = require("scanner")
local action = require("action")
local config = require("config")

local args = {...}

local function spreadOnce()
    for slot=2, config.farmSize^2, 2 do
        gps.go(posUtil.farmToGlobal(slot))
        local crop = scanner.scan()
        if crop.name == "air" then
            action.placeCropStick(2)
        elseif (not config.assumeNoBareStick) and crop.name == "crop" then
            action.placeCropStick()
        elseif crop.isCrop then
            if crop.name == "weed" or crop.gr > 23 or
              (crop.name == "venomilia" and crop.gr > 7) then
                action.deweed()
                action.placeCropStick()
            elseif crop.name == database.getFarm()[1].name and
                  (not config.bestStatWhileSpreading or (crop.gr >= 21 and crop.ga == 31)) then
                local nextMultifarmPos = database.nextMultifarmPos()
                if nextMultifarmPos then
                    action.transplantToMultifarm(posUtil.farmToGlobal(slot), nextMultifarmPos)
                    action.placeCropStick(2)
                    database.updateMultifarm(nextMultifarmPos)
                else
                    return true
                end
            else
                action.deweed()
                action.placeCropStick()
            end
        end
        if action.needCharge() then
            action.charge()
        end
    end
    return false
end

local function init()
    database.scanFarm()
    local multifarmPos = {}
    if #args == 2 then
        multifarmPos[1] = tonumber(args[1])
        multifarmPos[2] = tonumber(args[2])
    end
    if multifarmPos[1] and multifarmPos[2] then
        database.setLastMultifarmPos(multifarmPos)
    else
        database.scanMultifarm()
    end
    action.restockAll()
end

local function main()
    init()
    while not spreadOnce() do
        gps.go({0, 0})
        action.restockAll()
    end
    gps.go({0,0})
    if #args == 1 and args[1] == "docleanup" then
        action.destroyAll()
        gps.go({0,0})
    end
    if config.takeCareOfDrops then
        action.dumpInventory()
    end
    gps.turnTo(1)
    print("Done.\nThe Multifarm is filled up.")
end

main()
