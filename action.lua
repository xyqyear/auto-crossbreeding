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

local function needCharge()
    return computer.energy() / computer.maxEnergy() < config.needChargeLevel
end

local function fullyCharged()
    return computer.energy() / computer.maxEnergy() > 0.99
end

local function needMoreStick()
    return robot.count(robot.inventorySize()+config.stickSlot) < 2
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
    dumpInventory(false)
    restockStick(false)
    charge(false)
    gps.resume()
end

local function cross()
    local selectedSlot = robot.select()
    if needMoreStick() then
        restockStick()
    end
    robot.select(robot.inventorySize()+config.stickSlot)
    inventory_controller.equip()
    robot.useDown()
    inventory_controller.equip()
    robot.select(selectedSlot)
end

local function deweed()
    local selectedSlot = robot.select()
    if fullInventory() then
        dumpInventory()
    end
    robot.select(robot.inventorySize()+config.spadeSlot)
    inventory_controller.equip()
    robot.useDown()
    robot.suckDown()
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
    robot.useDown()
    gps.go(src)
    robot.useDown()
    robot.useDown()
    robot.useDown() -- because why not
    gps.go(config.dislocatorPos)
    signal.pulseDown()

    -- transfer the crop to the destination
    robot.useDown()
    gps.go(dest)
    if scanner.scan().name == "air" then
        cross()
    end
    robot.useDown()
    robot.useDown()
    robot.useDown() -- because why not
    gps.go(config.dislocatorPos)
    signal.pulseDown()

    -- destroy the original crop
    gps.go(config.relayFarmlandPos)
    deweed()
    robot.swingDown()
    robot.suckDown()

    inventory_controller.equip()
    gps.resume()
    robot.select(selectedSlot)
end

return {
    needCharge = needCharge,
    charge = charge,
    restockStick = restockStick,
    dumpInventory = dumpInventory,
    restockAll = restockAll,
    cross = cross,
    deweed = deweed,
    transplant = transplant
}
