local robot = require("robot")

local nowFacing = 1
local nowPos = {0, 0}
local savedPos = {}

local function getFacing()
    return nowFacing
end

local function getPos()
    return nowPos
end

local function safeForward()
    local forwardSuccess
    repeat
        forwardSuccess = robot.forward()
    until forwardSuccess
end

local function turnTo(facing)
    local delta = (facing - nowFacing) % 4
    nowFacing = facing
    if delta <= 2 then
        for _=1, delta do
            robot.turnRight()
        end
    else
        for _= 1, 4 - delta do
            robot.turnLeft()
        end
    end
end

local function turningDelta(facing)
    local delta = (facing - nowFacing) % 4
    if delta <= 2 then
        return delta
    else
        return 4-delta
    end
end

local function go(pos)
    if nowPos[1] == pos[1] and nowPos[2] == pos[2] then
        return
    end

    -- find path
    local posDelta = {pos[1]-nowPos[1], pos[2]-nowPos[2]}
    local path = {}

    if posDelta[1] > 0 then
        path[#path+1] = {2, posDelta[1]}
    elseif posDelta[1] < 0 then
        path[#path+1] = {4, -posDelta[1]}
    end

    if posDelta[2] > 0 then
        path[#path+1] = {1, posDelta[2]}
    elseif posDelta[2] < 0 then
        path[#path+1] = {3, -posDelta[2]}
    end

    -- optimal first turn
    if #path == 2 and turningDelta(path[2][1]) < turningDelta(path[1][1]) then
        path[1], path[2] = path[2], path[1]
    end

    for i=1, #path do
        turnTo(path[i][1])
        for _=1, path[i][2] do
            safeForward()
        end
    end

    nowPos = pos
end

local function down(distance)
    if distance == nil then
        distance = 1
    end
    for _=1, distance do
        robot.down()
    end
end

local function up(distance)
    if distance == nil then
        distance = 1
    end
    for _=1, distance do
        robot.up()
    end
end

local function save()
    savedPos[#savedPos+1] = nowPos
end

local function resume()
    if #savedPos == 0 then
        return
    end
    go(savedPos[#savedPos])
    savedPos[#savedPos] = nil
end

return {
    getFacing = getFacing,
    getPos = getPos,
    turnTo = turnTo,
    go = go,
    save = save,
    resume = resume,
    down = down,
    up = up
}
