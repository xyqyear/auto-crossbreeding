local shell = require("shell")
local args = {...}
local scripts = {
    "action.lua",
    "database.lua",
    "gps.lua",
    "posUtil.lua",
    "scanner.lua",
    "signal.lua",
    "autoStat.lua",
    "autoCrossbreed.lua",
    "autoSpread.lua",
    "install.lua"
}

local function exists(filename)
    return filesystem.exists(shell.getWorkingDirectory().."/"..filename)
end

local branch
local option
if #args == 0 then
    branch = "main"
else
    branch = args[1]
end

if branch == "help" then
    print("Usage:\n./install or ./install [branch] [updateconfig]")
    return
end

if #args == 2 then
    option = args[2]
end

for i=1, #scripts do
    if exists(scripts[i]) then
        shell.execute("rm "..scripts[i])
    end
    shell.execute("wget https://raw.githubusercontent.com/xyqyear/auto-crossbreeding/"..branch.."/"..scripts[i])
end

if not exists("config.lua") then
    shell.execute("wget https://raw.githubusercontent.com/xyqyear/auto-crossbreeding/"..branch.."/config.lua")
end

if option == "updateconfig" then
    if exists("config.lua") then
        if exists("config.bak") then
            shell.execute("rm config.bak")
        end
        shell.execute("mv config.lua config.bak")
        print("Moved config.lua to config.bak")
    end
    shell.execute("wget https://raw.githubusercontent.com/xyqyear/auto-crossbreeding/"..branch.."/config.lua")
end
