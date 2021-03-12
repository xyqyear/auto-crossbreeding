local shell = require("shell")
local args = {...}
local branch
if #args == 0 then
    branch = "main"
else
    branch = args[1]
end
shell.execute("wget https://raw.githubusercontent.com/xyqyear/auto-crossbreeding/"..branch.."/action.lua")
shell.execute("wget https://raw.githubusercontent.com/xyqyear/auto-crossbreeding/"..branch.."/config.lua")
shell.execute("wget https://raw.githubusercontent.com/xyqyear/auto-crossbreeding/"..branch.."/database.lua")
shell.execute("wget https://raw.githubusercontent.com/xyqyear/auto-crossbreeding/"..branch.."/gps.lua")
shell.execute("wget https://raw.githubusercontent.com/xyqyear/auto-crossbreeding/"..branch.."/posUtil.lua")
shell.execute("wget https://raw.githubusercontent.com/xyqyear/auto-crossbreeding/"..branch.."/scanner.lua")
shell.execute("wget https://raw.githubusercontent.com/xyqyear/auto-crossbreeding/"..branch.."/signal.lua")
shell.execute("wget https://raw.githubusercontent.com/xyqyear/auto-crossbreeding/"..branch.."/autoStat.lua")
shell.execute("wget https://raw.githubusercontent.com/xyqyear/auto-crossbreeding/"..branch.."/autoCrossbreed.lua")
shell.execute("wget https://raw.githubusercontent.com/xyqyear/auto-crossbreeding/"..branch.."/autoSpread.lua")
