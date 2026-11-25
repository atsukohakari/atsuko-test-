-- template, files starting with _ dont show up in the hub
-- copy it, rename it, put it in Scripts/<folder>/

-- @desc what it does
-- @author atsukohakari

-- script here

-- popups go to the hub's own notifications when the hub is open
local function notify(title, text, seconds)
	if AtsukoHub and AtsukoHub.Notify then
		AtsukoHub.Notify(title, text, "info", seconds)
	else
		pcall(warn, "[" .. tostring(title) .. "] " .. tostring(text))
	end
end


-- runs when you press stop (optional)
if AtsukoHub and AtsukoHub.Path then
	AtsukoHub.OnStop(function()

	end)
end

-- hats or guns to line up: put a table in getgenv().AtsukoAlign like Studio Dummy does and the hub's Align button opens it

-- scripts with their own run / stop (the hub's buttons call these):
-- _G.MyScriptCommands = { run = runCmd, stop = stopCmd, running = isRunning, kill = killAll }
