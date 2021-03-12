local robot = require("robot")

local gps = require("gps")
local action = require("action")
local database = require("database")
local scanner = require("scanner")
local posUtil = require("posUtil")
local config = require("config")

local lowestStat
local lowestStatSlot
local nearestReplacableSlot

local function updateLowest()
    lowestStat = 64
    lowestStatSlot = 0
    local farm = database.getFarm()
    local workingCrop = database.getFarm()[1].name
    for slot=1, config.farmArea, 2 do
        local crop = farm[slot]
        if crop ~= nil then
            local stat = crop.gr+crop.ga-crop.re
            if stat < lowestStat then
                lowestStat = stat
                lowestStatSlot = slot
            end
        end
    end

    nearestReplacableSlot = config.farmArea + 1
    for slot=1, config.farmArea, 2 do
        local crop = farm[slot]
        if crop.name == workingCrop then
            local pos = posUtil.farmToGlobal(slot)
            if pos[1] + pos[2] < nearestReplacableSlot then
                nearestReplacableSlot = slot
            end
        end
    end
end

local function findSuitableFarmSlot(crop)
    if nearestReplacableSlot <= config.farmArea then
        return nearestReplacableSlot
    elseif crop.gr+crop.ga-crop.re > lowestStat then
        return lowestStatSlot
    else
        return 0
    end
end

local function breedOnce()
    -- return true if all stats are maxed out
    -- 52 = 21(max gr) + 31(max ga) - 0 (min re)
    if lowestStat == 52 then
        return true
    end

    for slot=2, config.farmSize^2, 2 do
        gps.go(posUtil.farmToGlobal(slot))
        local crop = scanner.scan()
        if crop.name == "air" then
            action.placeCropStick(2)
        elseif (not config.assumeNoBareStick) and crop.name == "crop" then
            action.placeCropStick()
        elseif crop.isCrop then
            if crop.name == "weed" or crop.gr > 21 or
              (crop.name == "venomilia" and crop.gr > 7) then
                action.deweed()
                action.placeCropStick()
            elseif crop.name == database.getFarm()[1].name then
                local suitableSlot = findSuitableFarmSlot(crop)
                if suitableSlot == 0 then
                    action.deweed()
                    action.placeCropStick()
                else
                    action.transplant(posUtil.farmToGlobal(slot), posUtil.farmToGlobal(suitableSlot))
                    action.placeCropStick(2)
                    database.updateFarm(suitableSlot, crop)
                    updateLowest()
                end
            elseif config.keepNewCropWhileMinMaxing and (not database.existInStorage(crop)) then
                action.transplant(posUtil.farmToGlobal(slot), posUtil.storageToGlobal(database.nextStorageSlot()))
                action.placeCropStick(2)
                database.addToStorage(crop)
            else
                action.deweed()
                action.placeCropStick()
            end
        end
    end
    return false
end

local function destroyWeed()
    for slot=2, config.farmSize^2, 2 do
        gps.go(posUtil.farmToGlobal(slot))
        robot.swingDown()
        if config.takeCareOfDrops then
            robot.suckDown()
        end
    end
end

local function init()
    database.scanFarm()
    if config.keepNewCropWhileMinMaxing then
        database.scanStorage()
    end
    updateLowest()
    action.restockAll()
end

local function main()
    init()
    while not breedOnce() do
        gps.go({0,0})
        action.restockAll()
    end
    gps.go({0,0})
    destroyWeed()
    gps.go({0,0})
    if config.takeCareOfDrops then
        action.dumpInventory()
    end
    gps.turnTo(1)
    print("Done.\nAll crops are now 21/31/0")
end

main()
