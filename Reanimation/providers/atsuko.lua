local ctx = nil

local SETTINGS = {
	{ key = "placeholders", type = "toggle", label = "Hat placeholders", desc = "Leaves a see-through copy of each hat where it sits", default = true, group = "Body", applies = "next" },
	{ key = "ghostTransparency", type = "number", label = "Placeholder fade", desc = "How see-through those copies are", min = 0, max = 1, default = 0.5, group = "Body", applies = "next" },
	{ key = "hideHealthGui", type = "toggle", label = "Hide health bar", desc = "Hides Roblox's health bar while you are reanimated", default = true, group = "Body", applies = "next" },
	{ key = "simrad", type = "toggle", label = "Simulation radius", desc = "Raises the simulation radius so your hats stay yours", default = true, group = "Body", applies = "next" },
	{ key = "ctrltp", type = "toggle", label = "Ctrl + click teleport", desc = "Hold Ctrl and click to teleport where you point", default = true, group = "Controls", applies = "next" },
}

local Provider = {
	AtsukoReanimProvider = true,
	id = "atsuko",
	kind = "hat",
	name = "Script Reanimate",
	credit = "Atsuko, style from Uhhhhhh by STEVETHEREALONE",
	caps = { fdApi = true, emotes = true, bodyCommands = true, fling = false, bullet = false, stoppable = true, respawnSafe = true, needsR6 = false },
	settings = SETTINGS,
	keep = { LumenReanim = true },
	NEED = 10,
	READY_LIMIT = 25,
}

local state = {
	linked = false,
	prior = nil,
	rig = nil,
}

local function firstLine(text)
	text = tostring(text)
	return (string.match(text, "^[^\r\n]*")) or text
end

local function holders()
	local list = {}
	local first = ctx and ctx.RG
	local second = ctx and ctx.G
	if type(first) == "table" then
		list[1] = first
	end
	if type(second) == "table" and second ~= first then
		list[#list + 1] = second
	end
	return list
end

local function snapshotFd()
	local out = {}
	for _, t in ipairs(holders()) do
		local ok, v = pcall(function()
			return t.GenesisFDless
		end)
		out[#out + 1] = { t = t, v = ok and v or nil }
	end
	return out
end

local function restoreFd(snap)
	for _, item in ipairs(snap or {}) do
		pcall(function()
			item.t.GenesisFDless = item.v
		end)
	end
end

local function putFd(value)
	for _, t in ipairs(holders()) do
		pcall(function()
			t.GenesisFDless = value
		end)
	end
end

local function clearHat()
	for _, t in ipairs({ ctx and ctx.genv, ctx and ctx.RG }) do
		if type(t) == "table" then
			pcall(function()
				t.AtsukoHatFd = nil
				t.AtsukoScriptAligns = nil
				t.AtsukoRigHats = nil
				t.AtsukoFreeWeapons = nil
				t.AtsukoRigView = nil
			end)
		end
	end
end

local function current()
	local L = ctx and ctx.genv and ctx.genv.LumenReanim
	if type(L) == "table" and type(L.isReanimated) == "function" then
		return L
	end
	return nil
end

function Provider.init(context)
	ctx = context
end

function Provider.available(X)
	if type(X) ~= "table" or not X.loadstring then
		return false, "your executor has no loadstring"
	end
	return true
end

function Provider.lib()
	local L = current()
	if L and (tonumber(L.version) or 0) >= Provider.NEED then
		return L
	end
	local lib, err = ctx.loadLib("Reanimate", "LumenReanim", Provider.NEED)
	if type(lib) ~= "table" then
		return nil, err or "couldn't load Script Reanimate"
	end
	return lib
end

function Provider.config(options)
	local cfg = {}
	options = options or {}
	for _, def in ipairs(SETTINGS) do
		local value = options[def.key]
		if value == nil then
			value = def.default
		end
		cfg[def.key] = value
	end
	return cfg
end

function Provider.prepare(entry, run)
	local L, err = Provider.lib()
	if not L then
		return false, err
	end
	clearHat()
	if not (run and run.swap and state.linked) then
		state.prior = snapshotFd()
	end
	state.linked = true
	local ok, rig = pcall(L.rig, Provider.config(run and run.options))
	if not ok or type(rig) ~= "table" then
		state.linked = false
		return false, firstLine(rig or "the reanimate could not be prepared")
	end
	state.rig = rig
	putFd(rig)
	return true
end

function Provider.start(run)
	local L, err = Provider.lib()
	if not L then
		return false, err
	end
	if L.isReanimated() then
		pcall(L.stopreanimate)
	end
	local ok, live = pcall(L.reanimate, Provider.config(run and run.options))
	if not ok then
		return false, firstLine(live)
	end
	if type(live) ~= "table" then
		return false, "Script Reanimate could not start"
	end
	local t0 = ctx.now()
	while ctx.now() - t0 < Provider.READY_LIMIT do
		if type(live.isReady) ~= "function" or live.isReady() then
			return true
		end
		if not L.isReanimated() then
			return false, "it stopped while getting ready"
		end
		ctx.wait(0.1)
	end
	return false, "it did not get ready in time"
end

function Provider.hold(on)
	local L = current()
	if L and type(L.hold) == "function" then
		pcall(L.hold, on == true)
	end
end

function Provider.isRunning()
	local L = current()
	if not L then
		return false
	end
	local ok, value = pcall(L.isReanimated)
	return ok and value == true
end

function Provider.stop()
	local L = current()
	if L and L.isReanimated() then
		pcall(L.stopreanimate)
		local t0 = ctx.now()
		while ctx.now() - t0 < 6 and L.isReanimated() do
			ctx.wait(0.1)
		end
	end
	return true
end

function Provider.reset()
	if ctx and state.linked then
		restoreFd(state.prior)
	end
	state.linked = false
	state.prior = nil
	state.rig = nil
end

function Provider.forget()
	Provider.reset()
end

function Provider.driver()
	local L = current()
	if L and type(L.driver) == "function" then
		return L.driver()
	end
	return nil
end

function Provider.commands()
	local L = current()
	if L and type(L.commands) == "table" then
		return L.commands
	end
	return nil
end

return Provider
