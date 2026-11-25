local hub = AtsukoHub
local TITLE = "Limb template"

local alive = true
local loud = false
local counter = 0

local function say(text, kind, seconds)
	if hub and hub.Notify then
		hub.Notify(TITLE, text, kind or "info", seconds or 3)
	else
		warn("[" .. TITLE .. "] " .. tostring(text))
	end
end

local function describe()
	local info = hub and hub.Reanim
	if not info or not info.Provider then
		return "no reanimation"
	end
	local text = info.Provider
	if info.Clone then
		text = text .. ", clone " .. tostring(info.Clone.Name)
	end
	return text
end

if hub and hub.Commands then
	hub.Commands.register({
		{
			id = "hello",
			name = "Hello",
			desc = "Shows a notice, with your own words if you add some",
			usage = "hello [words]",
			run = function(words)
				counter += 1
				say((words or "Hello") .. " (" .. counter .. ")", "ok", 3)
			end,
		},
		{
			id = "loud",
			name = "Loud",
			desc = "Turns the ticking notices on or off",
			usage = "loud [on|off|toggle]",
			kind = "toggle",
			run = function(_, context)
				if context.state == nil then
					loud = not loud
				else
					loud = context.state
				end
				say(loud and "Ticking is on" or "Ticking is off", "info", 2)
			end,
		},
		{
			id = "where",
			name = "Where",
			desc = "Says which limb reanimation this runs on",
			usage = "where",
			run = function()
				say("Running on " .. describe(), "info", 3)
			end,
		},
		{
			id = "quit",
			name = "Quit",
			desc = "Stops the script and the limb reanimation",
			usage = "quit",
			run = function()
				if hub.Reanim and hub.Reanim.Stop then
					hub.Reanim.Stop()
				else
					hub.Stop()
				end
			end,
		},
	}, { short = "limb" })
end

if hub and hub.OnStop then
	hub.OnStop(function()
		alive = false
		say("Stopped", "info", 2)
	end)
end

say("Running on " .. describe(), "ok", 3)

task.spawn(function()
	while alive do
		task.wait(10)
		if alive and loud then
			counter += 1
			say("Still here (" .. counter .. ")", "info", 2)
		end
	end
end)
