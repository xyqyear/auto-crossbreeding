local component = require("component")
local robot = require("robot")
local computer = require("computer")
local inventory_controller = component.inventory_controller

local os = require("os")
local sides = require("sides")
local gps = require("gps")
local config = require("config")
local signal = require("signal")
local scanner = require("scanner")
local posUtil = require("posUtil")

local function needCharge()
    return computer.energy() / computer.maxEnergy() < config.needChargeLevel
end

local function fullyCharged()
    return computer.energy() / computer.maxEnergy() > 0.99
end

local function fullInventory()
    for i=1, robot.inventorySize() do
        if robot.count(i) == 0 then
            return false
        end
    end
    return true
end

local function charge(resume)
    if resume ~= false then
        gps.save()
    end

    gps.go(config.chargerPos)
    repeat
        os.sleep(0.5)
    until fullyCharged()

    if resume ~= false then
        gps.resume()
    end
end

local function restockStick(resume)
    local selectedSlot = robot.select()
    if resume ~= false then
        gps.save()
    end
    gps.go(config.stickContainerPos)
    robot.select(robot.inventorySize()+config.stickSlot)
    for i=1, inventory_controller.getInventorySize(sides.down) do
        inventory_controller.suckFromSlot(sides.down, i, 64-robot.count())
        if robot.count() == 64 then
            break
        end
    end
    if resume ~= false then
        gps.resume()
    end
    robot.select(selectedSlot)
end

local function dumpInventory(resume)
    local selectedSlot = robot.select()
    if resume ~= false then
        gps.save()
    end
    gps.go(config.storagePos)
    for i=1, robot.inventorySize()+config.storageStopSlot do
        if robot.count(i) > 0 then
            robot.select(i)
            for e=1, inventory_controller.getInventorySize(sides.down) do
                if inventory_controller.getStackInSlot(sides.down, e) == nil then
                    inventory_controller.dropIntoSlot(sides.down, e)
                    break;
                end
            end
        end
    end
    if resume ~= false then
        gps.resume()
    end
    robot.select(selectedSlot)
end

local function restockAll()
    gps.save()
    if config.takeCareOfDrops then
        dumpInventory()
    end
    restockStick(false)
    charge(false)
    gps.resume()
end

local function placeCropStick(count)
    if count == nil then
        count = 1
    end
    local selectedSlot = robot.select()
    if robot.count(robot.inventorySize()+config.stickSlot) < count + 1 then
        restockStick()
    end
    robot.select(robot.inventorySize()+config.stickSlot)
    inventory_controller.equip()
    for _=1, count do
        robot.useDown()
    end
    inventory_controller.equip()
    robot.select(selectedSlot)
end

local function deweed()
    local selectedSlot = robot.select()
    if config.takeCareOfDrops and fullInventory() then
        dumpInventory()
    end
    robot.select(robot.inventorySize()+config.spadeSlot)
    inventory_controller.equip()
    robot.useDown()
    if config.takeCareOfDrops then
        robot.suckDown()
    end
    inventory_controller.equip()
    robot.select(selectedSlot)
end

local function transplant(src, dest)
    local selectedSlot = robot.select()
    gps.save()
    robot.select(robot.inventorySize()+config.binderSlot)
    inventory_controller.equip()

    -- transfer the crop to the relay location
    gps.go(config.dislocatorPos)
    robot.useDown(sides.down)
    gps.go(src)
    robot.useDown(sides.down, true) -- sneak-right-click on crops to prevent harvesting
    gps.go(config.dislocatorPos)
    signal.pulseDown()

    -- transfer the crop to the destination
    robot.useDown(sides.down)
    gps.go(dest)
    if scanner.scan().name == "air" then
        placeCropStick()
    end
    robot.useDown(sides.down, true)
    gps.go(config.dislocatorPos)
    signal.pulseDown()

    -- destroy the original crop
    gps.go(config.relayFarmlandPos)
    deweed()
    robot.swingDown()
    if config.takeCareOfDrops then
        robot.suckDown()
    end

    inventory_controller.equip()
    gps.resume()
    robot.select(selectedSlot)
end

local function transplantToMultifarm(src, dest)
    local globalDest = posUtil.multifarmPosToGlobalPos(dest)
    local optimalDislocatorSet = posUtil.findOptimalDislocator(dest)
    local dislocatorPos = optimalDislocatorSet[1]
    local relayFarmlandPos = optimalDislocatorSet[2]

    local selectedSlot = robot.select()
    gps.save()

    if robot.count(robot.inventorySize()+config.stickSlot) < 2 then
        restockStick()
    end

    robot.select(robot.inventorySize()+config.binderSlot)
    inventory_controller.equip()

    -- transfer the crop to the relay location
    gps.go(config.elevatorPos)
    gps.down(3)
    gps.go(dislocatorPos)
    robot.useDown(sides.down)

    gps.go(config.elevatorPos)
    gps.up(3)
    gps.go(src)
    robot.useDown(sides.down, true) -- sneak-right-click on crops to prevent harvesting

    gps.go(config.elevatorPos)
    gps.down(3)
    gps.go(dislocatorPos)
    signal.pulseDown()

    if not (relayFarmlandPos[1] == globalDest[1] and relayFarmlandPos[2] == globalDest[2]) then
        -- transfer the crop to the destination
        robot.useDown(sides.down)
        gps.go(globalDest)
        placeCropStick()
        robot.useDown(sides.down, true)
        gps.go(dislocatorPos)
        signal.pulseDown()

        -- destroy the original crop
        gps.go(relayFarmlandPos)
        robot.swingDown()
    end

    gps.go(config.elevatorPos)
    gps.up(3)

    inventory_controller.equip()
    gps.resume()
    robot.select(selectedSlot)
end

local function destroyAll()
    for slot=2, config.farmArea, 2 do
        gps.go(posUtil.farmToGlobal(slot))
        robot.swingDown()
        if config.takeCareOfDrops then
            robot.suckDown()
        end
    end
end

return {
    needCharge = needCharge,
    charge = charge,
    restockStick = restockStick,
    restockAll = restockAll,
    placeCropStick = placeCropStick,
    deweed = deweed,
    transplant = transplant,
    transplantToMultifarm = transplantToMultifarm,
    destroyAll = destroyAll
}
