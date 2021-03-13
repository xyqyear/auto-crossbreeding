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
    return (absX + absY) <= config.multifarmSize and (absX > 2 or absY > 2) and absX < config.multifarmSize-1 and absY < config.multifarmSize-1
end

local function globalPosToMultifarmPos(pos)
    return {pos[1], pos[2]-4}
end

local function multifarmPosToGlobalPos(pos)
    return {pos[1], pos[2]+4}
end

local function multifarmPosIsRelayFarmland(pos)
    for i = 1, #config.multifarmRelayFarmlandPoses do
        local rPos = config.multifarmRelayFarmlandPoses[i]
        if rPos[1] == pos[1] and rPos[2] == pos[2] then
            return true
        end
    end
    return false
end

local function nextRelayFarmland(pos)
    if pos == nil then
        return config.multifarmRelayFarmlandPoses[1]
    end
    for i = 1, #config.multifarmRelayFarmlandPoses do
        local rPos = config.multifarmRelayFarmlandPoses[i]
        if rPos[1] == pos[1] and rPos[2] == pos[2] and i < #config.multifarmRelayFarmlandPoses then
            return config.multifarmRelayFarmlandPoses[i+1]
        end
    end
end

local function findOptimalDislocator(pos)
    -- return: {dislocatorGlobalPos, relayFarmlandGlobalPos}
    local minDistance = 100
    local minPosI
    for i = 1, #config.multifarmDislocatorPoses do
        local rPos = config.multifarmDislocatorPoses[i]
        local distance = math.abs(pos[1] - rPos[1]) + math.abs(pos[2] - rPos[2])
        if distance < minDistance then
            minDistance = distance
            minPosI = i
        end
    end
    return {multifarmPosToGlobalPos(config.multifarmDislocatorPoses[minPosI]),
            multifarmPosToGlobalPos(config.multifarmRelayFarmlandPoses[minPosI])}
end

return {
    globalToFarm = globalToFarm,
    farmToGlobal = farmToGlobal,
    globalToStorage = globalToStorage,
    storageToGlobal = storageToGlobal,
    multifarmPosInFarm = multifarmPosInFarm,
    multifarmPosIsRelayFarmland = multifarmPosIsRelayFarmland,
    globalPosToMultifarmPos = globalPosToMultifarmPos,
    multifarmPosToGlobalPos = multifarmPosToGlobalPos,
    findOptimalDislocator = findOptimalDislocator,
    nextRelayFarmland = nextRelayFarmland
}
