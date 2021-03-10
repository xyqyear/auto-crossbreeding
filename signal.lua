local component = require("component")
local redstone = component.redstone
local sides = require("sides")
local os = require("os")

local function pulseDown(duration)
    if duration == nil then
        duration = 0.2
    end
    redstone.setOutput(sides.down, 15)
    os.sleep(duration)
    redstone.setOutput(sides.down, 0)
end

return {
    pulseDown = pulseDown
}
