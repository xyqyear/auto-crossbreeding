local robot = require("robot")

local gps = require("gps")
local action = require("action")
local database = require("database")
local scanner = require("scanner")
local posUtil = require("posUtil")
local config = require("config")

local lowestGr
local lowestGrSlot
local lowestGa
local lowestGaSlot

local function updateLowest()
    lowestGr = 100
    lowestGrSlot = 0
    lowestGa = 100
    lowestGaSlot = 0
    local farm = database.getFarm()
    local farmArea = config.farmSize^2
    for slot=1, farmArea, 2 do
        local crop = farm[slot]
        if crop ~= nil then
            if crop.gr < lowestGr then
                lowestGr = crop.gr
                lowestGrSlot = slot
            end
        end
    end
    for slot=1, farmArea, 2 do
        local crop = farm[slot]
        if crop ~= nil then
            if crop.gr == lowestGr then
                if crop.ga < lowestGa then
                    lowestGa = crop.ga
                    lowestGaSlot = slot
                end
            end
        end
    end
end

local function findSuitableFarmSlot(crop)
    if crop.gr > lowestGr then
        return lowestGrSlot
    elseif crop.gr == lowestGr then
        if crop.ga > lowestGa then
            return lowestGaSlot
        end
    end
    return 0
end

local function breedOnce()
    -- return true if all stats are maxed out
    if lowestGr == 21 and lowestGa == 31 then
        return true
    end

    for slot=2, config.farmSize^2, 2 do
        gps.go(posUtil.farmToGlobal(slot))
        local crop = scanner.scan()
        if crop.name == "air" then
            action.placeCropStick()
            action.placeCropStick()
        elseif crop.name == "crop" then
            action.placeCropStick()
        elseif crop.isCrop then
            if crop.name == "weed" or crop.gr > 21 or
              (crop.name == "venomilia" and crop.ga > 7) then
                action.deweed()
                action.placeCropStick()
            elseif crop.name == database.getFarm()[1].name then
                local suitableSlot = findSuitableFarmSlot(crop)
                if suitableSlot == 0 or crop.re > 0 then
                    action.deweed()
                    action.placeCropStick()
                else
                    action.transplant(posUtil.farmToGlobal(slot), posUtil.farmToGlobal(suitableSlot))
                    action.placeCropStick()
                    action.placeCropStick()
                    database.updateFarm(suitableSlot, crop)
                    updateLowest()
                end
            elseif config.keepNewCropWhileMinMaxing and (not database.existInStorage(crop)) then
                action.transplant(posUtil.farmToGlobal(slot), posUtil.storageToGlobal(database.nextStorageSlot()))
                action.placeCropStick()
                action.placeCropStick()
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
