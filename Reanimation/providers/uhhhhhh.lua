local ctx = nil

local SETTINGS = {
	{ key = "Mode", type = "choice", label = "Root part", desc = "Where the hidden root part sits. Only some games allow limb reanimation", options = { 0, 1, 2, 3, 4 }, labels = { "Far void", "Void", "Streamed", "Angle", "Torso" }, default = 0, group = "Body", applies = "next" },
	{ key = "Velocity", type = "choice", label = "Root velocity", desc = "What velocity the root part gets", options = { 0, 1, 2 }, labels = { "None", "Follow", "Fling" }, default = 0, group = "Body", applies = "next" },
	{ key = "InitMode", type = "choice", label = "Start by", desc = "How your real character is set up first", options = { 0, 1, 2 }, labels = { "Reset", "Timed + reset", "Timed" }, default = 2, group = "Body", applies = "next" },
	{ key = "ReplicateFPS10", type = "toggle", label = "Show me how I look", desc = "Makes other players see you move as your reanimate does", default = false, group = "Body", applies = "next" },
	{ key = "FlingEnabled", type = "toggle", label = "Target fling", desc = "Touching a player makes them lose ownership of their body", default = true, group = "Fling", applies = "next" },
	{ key = "UseNaNFling", type = "toggle", label = "NaN state fling", desc = "Flings with the NaN state", default = false, group = "Fling", applies = "next" },
	{ key = "UseToolKill", type = "toggle", label = "Tool kill", desc = "Uses a tool to kill what you touch", default = false, group = "Fling", applies = "next" },
	{ key = "UseCustomKill", type = "toggle", label = "Custom kill", desc = "Uses the fork's custom kill method", default = false, group = "Fling", applies = "next" },

}

local REQUIRED = { "loadstring", "request", "getcustomasset", "readfile", "writefile", "delfile", "isfile", "isfolder", "makefolder", "listfiles", "firetouchinterest" }

local Provider = {
	AtsukoReanimProvider = true,
	id = "uhhhhhh",
	kind = "limb",
	name = "Uhhhhhh",
	credit = "STEVETHEREALONE, BoredGal, Awes955",
	blurb = "Uhhhhhh's limb reanimate with its dances",
	caps = { fdApi = false, emotes = true, bodyCommands = false, fling = true, bullet = false, stoppable = true, respawnSafe = false, needsR6 = false },
	settings = SETTINGS,
	keep = { UhhhhhhLoaded = true, UhhhhhhAPI = true, Uhhhhhh = true, UhhhhhhHeadless = true },
	FILE = "Reanimation/Limb/Uhhhhhh.lua",
	LOAD_LIMIT = 90,
	START_LIMIT = 40,
	STOP_LIMIT = 10,
	REQUIRED = REQUIRED,
}

local state = {
	started = false,
	loadError = nil,
	loading = false,
}

local function firstLine(text)
	text = tostring(text)
	return (string.match(text, "^[^\r\n]*")) or text
end

local function lookup(key)
	if not ctx then
		return nil
	end
	local first = ctx.RG
	if type(first) == "table" then
		local ok, value = pcall(function()
			return first[key]
		end)
		if ok and value ~= nil then
			return value
		end
	end
	local second = ctx.G
	if type(second) == "table" and second ~= first then
		local ok, value = pcall(function()
			return second[key]
		end)
		if ok then
			return value
		end
	end
	return nil
end

local function api()
	local a = lookup("UhhhhhhAPI")
	if type(a) == "table" then
		return a
	end
	return nil
end

local function loaded()
	local a = api()
	if not a or type(a.IsLoaded) ~= "function" then
		return false
	end
	local ok, value = pcall(a.IsLoaded)
	return ok and value == true
end

function Provider.init(context)
	ctx = context
end

function Provider.available(X)
	if type(X) ~= "table" then
		return false, "your executor details are missing"
	end
	for _, name in ipairs(REQUIRED) do
		if not X[name] then
			return false, "your executor has no " .. name .. ", which Uhhhhhh needs"
		end
	end
	return true
end

function Provider.ensureLoaded(run)
	if loaded() then
		return api()
	end
	if state.loading then
		return nil, "Uhhhhhh is still loading"
	end
	if lookup("UhhhhhhLoaded") and not api() then
		return nil, "Uhhhhhh is already open from another script, rejoin to let the hub control it"
	end
	local src, err = ctx.loadFile(Provider.FILE)
	if type(src) ~= "string" or #src < 200 then
		return nil, err or "couldn't read the Uhhhhhh file"
	end
	local f, cerr = ctx.loadstring(src, "=Uhhhhhh")
	if type(f) ~= "function" then
		return nil, firstLine(cerr or "Uhhhhhh would not compile")
	end
	if run and run.notify then
		run.notify("Uhhhhhh", "Loading it, the first time can take a moment", "info", 4)
	end
	ctx.genv.UhhhhhhHeadless = true
	state.loading = true
	state.loadError = nil
	ctx.spawn(function()
		local ok, e = pcall(f)
		if not ok then
			state.loadError = firstLine(e)
		end
	end)
	local t0 = ctx.now()
	while ctx.now() - t0 < Provider.LOAD_LIMIT do
		if loaded() then
			break
		end
		if state.loadError then
			break
		end
		ctx.wait(0.2)
	end
	state.loading = false
	if not loaded() then
		return nil, state.loadError or "it did not finish loading in time"
	end
	return api()
end

function Provider.applyOptions(options)
	local a = api()
	if not a or type(a.Limb) ~= "table" then
		return false
	end
	options = options or {}
	for _, def in ipairs(SETTINGS) do
		local value = options[def.key]
		if value == nil then
			value = def.default
		end
		a.Limb[def.key] = value
	end
	return true
end

function Provider.start(run)
	local a, err = Provider.ensureLoaded(run)
	if not a then
		return false, err
	end
	if type(a.IsRunning) == "function" and a.IsRunning() then
		return false, "Uhhhhhh is already running" .. (state.started and "" or " from its own window")
	end
	if type(a.SetMethod) == "function" then
		a.SetMethod()
	end
	Provider.applyOptions(run and run.options)
	if type(a.SetUIVisible) == "function" then
		a.SetUIVisible(false)
	end
	local ok, why = a.Start(Provider.START_LIMIT)
	if not ok then
		return false, why or "it did not start"
	end
	state.started = true
	return true
end

function Provider.isRunning()
	local a = api()
	if not a or type(a.IsRunning) ~= "function" then
		return false
	end
	local ok, value = pcall(a.IsRunning)
	return ok and value == true
end

function Provider.stop()
	local a = api()
	if a and type(a.Stop) == "function" and (Provider.isRunning() or (type(a.State) == "function" and a.State() ~= "idle")) then
		local ok, why = a.Stop(Provider.STOP_LIMIT)
		if not ok then
			if ctx and ctx.notify then
				ctx.notify("Uhhhhhh", "Couldn't stop it: " .. tostring(why or "unknown"), "error", 5)
			end
			return false, why
		end
	end
	state.started = false
	return true
end

function Provider.reset()
	state.started = false
	state.loadError = nil
	state.loading = false
end

function Provider.forget()
	Provider.reset()
end

function Provider.playDance(name)
	local a = api()
	if a and type(a.PlayDance) == "function" then
		return a.PlayDance(name)
	end
	return false
end

function Provider.stopDance()
	local a = api()
	if a and type(a.StopDance) == "function" then
		return a.StopDance()
	end
	return false
end

function Provider.listDances()
	local a = api()
	if a and type(a.ListDances) == "function" then
		return a.ListDances()
	end
	return {}
end

return Provider
