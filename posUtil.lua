local config = require("config")

local function posToSlot(size, pos)
    local lastColNum
    if pos[1] % 2 == 1 then
        lastColNum = pos[2] + 1
    else
        lastColNum = size - pos[2]
    end
    return (pos[1] - 1) * size + lastColNum
end

local function slotToPos(size, slot)
    local x = (slot - 1) // size + 1
    local y
    local lastColNum = (slot - 1) % size
    if x % 2 == 1 then
        y = lastColNum
    else
        y = size - lastColNum - 1
    end
    return {x, y}
end

local function globalToFarm(globalPos)
    return posToSlot(config.farmSize, globalPos)
end

local function farmToGlobal(farmSlot)
    return slotToPos(config.farmSize, farmSlot)
end

local function globalToStorage(globalPos)
    return posToSlot(config.storageFarmSize, {-globalPos[1], globalPos[2]})
end

local function storageToGlobal(storageSlot)
    local globalPos = slotToPos(config.storageFarmSize, storageSlot)
    globalPos[1] = -globalPos[1]
    return globalPos
end

local function multifarmPosInFarm(pos)
    local absX = math.abs(pos[1])
    local absY = math.abs(pos[2])
    return (absX + absY) < 21 and (absX > 2 or absY > 2) and absX < 19 and absY < 19
end

local function multifarmPosInMiddle(pos)
    return math.abs(pos[1]) < 3 and math.abs(pos[2]) < 3
end

local function globalPosToMultifarmPos(pos)
    return {pos[1]+19, pos[2]-2}
end

local function posInMultifarm(pos)
    -- function calls in lua are expensive
    -- only do this for the sake of clarity
    return multifarmPosInFarm(globalPosToMultifarmPos(pos))
end

local function posInMiddleOfMultifarm(pos)
    return multifarmPosInMiddle(globalPosToMultifarmPos(pos))
end

return {
    globalToFarm = globalToFarm,
    farmToGlobal = farmToGlobal,
    globalToStorage = globalToStorage,
    storageToGlobal = storageToGlobal,
    posInMultifarm = posInMultifarm,
    posInMiddleOfMultifarm = posInMiddleOfMultifarm
}
