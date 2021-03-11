local component = require("component")
local geolyzer = component.geolyzer
local sides = require("sides")

local function scan()
    local rawResult = geolyzer.analyze(sides.down)
    if rawResult.name == "minecraft:air" or rawResult.name == "GalacticraftCore:tile.brightAir" then
        return {isCrop=false, name="air"}
    elseif rawResult.name == "IC2:blockCrop" then
        if rawResult["crop:name"] == nil then
            return {isCrop=false, name="crop"}
        elseif rawResult["crop:name"] == "weed" then
            return {isCrop=true, name="weed"}
        else
            return {
                isCrop=true,
                name = rawResult["crop:name"],
                gr = rawResult["crop:growth"],
                ga = rawResult["crop:gain"],
                re = rawResult["crop:resistance"],
                tier = rawResult["crop:tier"]
            }
        end
    else
        return {isCrop=false, name=rawResult.name}
    end
end

return {
    scan = scan
}
