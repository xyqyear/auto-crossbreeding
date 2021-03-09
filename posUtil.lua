local farmSize
local storageSize = 13 -- const

local function setFarmSize(n)
    farmSize = n
end

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
    return posToSlot(farmSize, globalPos)
end

local function farmToGlobal(farmSlot)
    return slotToPos(farmSize, farmSlot)
end

local function globalToStorage(globalPos)
    return posToSlot(storageSize, {-globalPos[1], globalPos[2]})
end

local function storageToGlobal(storageSlot)
    local globalPos = slotToPos(storageSize, storageSlot)
    globalPos[1] = -globalPos[1]
    return globalPos
end

return {
    setFarmSize = setFarmSize,
    globalToFarm = globalToFarm,
    farmToGlobal = farmToGlobal,
    globalToStorage = globalToStorage,
    storageToGlobal = storageToGlobal
}
