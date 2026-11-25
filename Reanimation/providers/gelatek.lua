local ctx = nil

local SETTINGS = {
	{ key = "Reanimation", type = "choice", label = "Mode", desc = "Simple only follows you. Fling and Bullet can hit other players. Bullet needs the Pal Hair accessory", options = { "Simple", "Fling", "Bullet" }, default = "Simple", group = "Mode", applies = "next" },
	{ key = "Velocity", type = "number", label = "Velocity", desc = "How hard your limbs push other players in Fling and Bullet", min = 0, max = 200, default = 35, integer = true, group = "Mode", applies = "next" },
	{ key = "AttachHead", type = "toggle", label = "Attach head", desc = "Your real head follows the reanimate too", default = false, group = "Body", applies = "next" },
	{ key = "DisableAnimationsR6", type = "toggle", label = "Turn off R6 animations", desc = "Removes the default animations of the R6 clone", default = false, group = "Body", applies = "next" },
	{ key = "CloneParent", type = "choice", label = "Clone lives in", desc = "Where the clone is placed", options = { "Character", "Workspace" }, default = "Character", group = "Clone", applies = "next" },
	{ key = "CloneName", type = "text", label = "Clone name", desc = "What the clone is called in the game", default = "TalentlessDumbass", max = 40, group = "Clone", applies = "next" },

}

local Provider = {
	AtsukoReanimProvider = true,
	id = "gelatek",
	kind = "limb",
	name = "Gelatek",
	credit = "Gelatek, poncho",
	caps = { fdApi = false, emotes = true, bodyCommands = false, fling = true, bullet = true, stoppable = true, respawnSafe = false, needsR6 = false },
	settings = SETTINGS,
	keep = {},
	FILE = "Reanimation/Limb/Gelatek.lua",
	stopWarning = "Stopping respawns you. Continue?",
	LOAD_LIMIT = 15,
}

local state = {
	started = false,
	priorSettings = nil,
	hadSettings = false,
	loadError = nil,
}

local function firstLine(text)
	text = tostring(text)
	return (string.match(text, "^[^\r\n]*")) or text
end

local function call(target, name, ...)
	if type(target) == "table" and type(target[name]) == "function" then
		return pcall(target[name], target, ...)
	end
	return false
end

local function isOn()
	return ctx ~= nil and ctx.genv.Reanimated == true
end

function Provider.init(context)
	ctx = context
end

function Provider.available(X)
	if type(X) ~= "table" or not X.loadstring then
		return false, "your executor has no loadstring"
	end
	if ctx and ctx.world and ctx.world.isR15 and ctx.world.isR15() and not X.getobjects then
		return false, "your executor has no GetObjects, and R15 characters need it"
	end
	return true
end

function Provider.buildSettings(options)
	local out = {}
	options = options or {}
	for _, def in ipairs(SETTINGS) do
		local value = options[def.key]
		if value == nil then
			value = def.default
		end
		out[def.key] = value
	end
	local velocity = tonumber(out.Velocity) or 35
	out.Velocity = ctx.vec3(velocity, 0, 0)
	if out.CloneParent == "Workspace" then
		out.CloneParent = ctx.world.workspace()
	else
		out.CloneParent = ctx.world.character()
	end
	out.AllowNetBypass = true
	out.SimpleBulletFling = true
	return out
end

function Provider.start(run)
	local genv = ctx.genv
	local options = (run and run.options) or {}
	if genv.Reanimated == true then
		if state.started then
			return false, "Gelatek is already running"
		end
		return false, "Gelatek is already running from another script, reset your character to stop it"
	end
	if options.Reanimation == "Bullet" and not (ctx.world.hasAccessory and ctx.world.hasAccessory("Pal Hair")) then
		return false, "Bullet mode needs the Pal Hair accessory on your character"
	end
	if not ctx.world.character() then
		return false, "your character isn't loaded yet"
	end
	local src, err = ctx.loadFile(Provider.FILE)
	if type(src) ~= "string" or #src < 200 then
		return false, err or "couldn't read the Gelatek file"
	end
	local f, cerr = ctx.loadstring(src, "=Gelatek")
	if type(f) ~= "function" then
		return false, firstLine(cerr or "Gelatek would not compile")
	end
	state.hadSettings = true
	state.priorSettings = genv.Settings
	genv.Settings = Provider.buildSettings(options)
	state.loadError = nil
	state.started = true
	ctx.spawn(function()
		local ok, e = pcall(f)
		if not ok then
			state.loadError = firstLine(e)
		end
	end)
	local t0 = ctx.now()
	while ctx.now() - t0 < Provider.LOAD_LIMIT do
		if state.loadError then
			break
		end
		if genv.Reanimated == true then
			break
		end
		ctx.wait(0.1)
	end
	if genv.Reanimated ~= true then
		local why = state.loadError or "it did not start in time"
		Provider.stop(true)
		return false, why
	end
	if state.loadError then
		local why = state.loadError
		Provider.stop(false)
		return false, why
	end
	return true
end

function Provider.isRunning()
	return isOn()
end

function Provider.clone()
	if not ctx then
		return nil
	end
	local settings = ctx.genv.Settings
	if type(settings) ~= "table" then
		return nil
	end
	local parent, name = settings.CloneParent, settings.CloneName
	if parent == nil or type(name) ~= "string" or name == "" then
		return nil
	end
	local ok, found = pcall(function()
		return parent:FindFirstChild(name)
	end)
	if ok and found ~= nil then
		return found
	end
	return nil
end

function Provider.stop(quiet)
	if not ctx then
		return true
	end
	local genv = ctx.genv
	local settings = genv.Settings
	if type(settings) == "table" then
		settings.AllowNetBypass = false
	end
	local cleanup = genv.__GelatekCleanup
	local hadRun = state.started or genv.Reanimated == true
	if type(cleanup) == "table" then
		for _, connection in ipairs(cleanup.conns or {}) do
			call(connection, "Disconnect")
		end
		for _, object in ipairs(cleanup.objs or {}) do
			call(object, "Destroy")
		end
		cleanup.conns = {}
		cleanup.objs = {}
	end
	genv.Reanimated = false
	state.started = false
	if hadRun then
		pcall(ctx.world.restoreCamera)
		if not quiet then
			local ok, e = pcall(ctx.world.respawn)
			if not ok then
				return false, firstLine(e)
			end
		end
	end
	return true
end

function Provider.reset()
	if not ctx then
		return
	end
	local genv = ctx.genv
	if genv.Reanimated ~= true then
		genv.Reanimated = nil
	end
	genv.__GelatekCleanup = nil
	if state.hadSettings then
		genv.Settings = state.priorSettings
	end
	state.hadSettings = false
	state.priorSettings = nil
	state.started = false
	state.loadError = nil
end

function Provider.forget()
	Provider.reset()
end

return Provider
