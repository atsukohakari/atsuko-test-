local Host = loadmodule("Hub/modules/reanim_host.lua")
local Controller = loadmodule("Hub/modules/reanim.lua")

Vector3 = Vector3 or { new = function(x, y, z)
	return { x = x, y = y, z = z }
end }
Enum = Enum or { HumanoidRigType = { R15 = "R15", R6 = "R6" } }

local current = nil
getgenv = function()
	return current and current.GE or nil
end
getRG = function()
	return current and current.RG or nil
end

local SHARED_SOURCE = table.concat({
	string.rep("local padding = 0\n", 20),
	"local RG = getRG()",
	"if RG.GenesisFDless then return RG.GenesisFDless end",
	"local g = getgenv()",
	"local config = { fling = g.fling, flingdirection = g.flingdirection, respawntp = g.respawntp }",
	"local on = nil",
	"local api = { modes = {} }",
	"api.addmode = function(key, mode) api.modes[key] = mode end",
	"local function reanimate() on = true return api end",
	"local function stopreanimate() on = nil end",
	"RG.GenesisFDless = { reanimate = reanimate, stopreanimate = stopreanimate, isReanimated = function() return on end, config = config }",
	"return RG.GenesisFDless",
}, "\n")

local function newBus()
	local bus = { map = {}, fired = {} }
	function bus.on(name, f)
		bus.map[name] = bus.map[name] or {}
		table.insert(bus.map[name], f)
	end
	function bus.off(name, f)
		local list = bus.map[name] or {}
		for i = #list, 1, -1 do
			if list[i] == f then
				table.remove(list, i)
			end
		end
	end
	function bus.fire(name, ...)
		bus.fired[#bus.fired + 1] = name
		for _, f in ipairs(table.clone(bus.map[name] or {})) do
			f(...)
		end
	end
	return bus
end

local function newWorld(opts)
	opts = opts or {}
	local GE = {}
	local RG = opts.same and GE or {}
	local w = { RG = RG, GE = GE, toasts = {}, logs = {}, stops = {}, started = {}, bodies = {}, saves = 0 }
	current = w
	w.bus = newBus()
	w.shared = { running = {} }
	w.repo = { byPath = {}, remote = {} }
	w.runner = { pending = {}, failed = {} }
	function w.runner.isActive(rec)
		return rec ~= nil and (rec.kind ~= "commands" or rec.active == true)
	end
	function w.runner.run(entry)
		w.started[#w.started + 1] = entry.path
		w.runner.pending[entry.path] = true
		w.runner.failed[entry.path] = nil
		task.spawn(function()
			task.wait(0.3)
			local rec = { name = entry.name, status = "running", kind = "plain", path = entry.path }
			w.shared.running[entry.path] = rec
			local body = w.bodies[entry.path]
			local ok, err = pcall(body, rec)
			if not ok then
				rec.status = "error"
				rec.err = tostring(err)
			end
			w.runner.pending[entry.path] = nil
		end)
	end
	w.onStop = {}
	w.kept = {}
	function w.runner.stop(path, quiet, keep)
		w.stops[#w.stops + 1] = path
		w.kept[#w.kept + 1] = keep == true
		local f = w.onStop[path]
		w.onStop[path] = nil
		if f then
			f()
		end
		local rec = w.shared.running[path]
		w.shared.running[path] = nil
		if rec and rec.added then
			for key in pairs(rec.added) do
				RG[key] = nil
			end
		end
	end
	function w.runner.respawn()
		return "old"
	end
	w.core = {
		mods = {},
		fileSource = function(rel)
			if rel == "Reanimation/Hat/FDless.lua" then
				return SHARED_SOURCE
			end
			return nil, "no such file"
		end,
		loadLib = function(name, key, need)
			if not opts.lumen then
				return nil, "not needed here"
			end
			local on = nil
			local held = false
			local lib = { version = 10, holds = {}, made = 0, handed = 0 }
			lib.isReanimated = function()
				return on
			end
			lib.reanimate = function()
				if on and held == false and lib.fresh then
					lib.fresh = false
					lib.handed = lib.handed + 1
				elseif not on then
					lib.made = lib.made + 1
				end
				on = true
				return { isReady = function()
					return true
				end }
			end
			lib.stopreanimate = function()
				if held then
					return false
				end
				on = nil
			end
			lib.hold = function(v)
				held = v == true
				lib.holds[#lib.holds + 1] = held
				if held then
					lib.fresh = true
				end
			end
			lib.rig = function(cfg)
				return { marker = "rig", cfg = cfg }
			end
			GE[key] = lib
			return lib
		end,
	}
	w.core.loadModule = function(name, retry, context)
		local rel
		if name == "reanim" then
			rel = "Hub/modules/reanim.lua"
		elseif string.sub(name, 1, 1) == "@" then
			rel = string.sub(name, 2) .. ".lua"
		else
			return nil, "no such module"
		end
		local mod = loadmodule(rel)
		if type(mod.init) == "function" then
			mod.init(context)
		end
		return mod
	end
	w.c = {
		S = { reanimSel = "", hatReanim = "atsuko", reanimLimb = "gelatek", reanimOpts = {} },
		saveSettings = function()
			w.saves = w.saves + 1
		end,
		notify = function(title, text, kind)
			w.toasts[#w.toasts + 1] = title .. "|" .. text .. "|" .. tostring(kind)
		end,
		Bus = w.bus,
		HUB = { alive = true },
		Log = { add = function(kind, src, msg)
			w.logs[#w.logs + 1] = kind .. "|" .. src .. "|" .. msg
		end },
		GENV = GE,
		RG = RG,
		X = { loadstring = loadstring },
		LP = { Character = nil },
		workspace = {},
		Runner = w.runner,
		Repo = w.repo,
		SHARED = w.shared,
		Core = w.core,
	}
	w.R = { path = nil, busy = nil }
	local ok, why = Host.install(w.c, w.R)
	T.ok(ok, "the controller and the four reanimations install: " .. tostring(why))
	return w
end

local function entryOf(w, name, path)
	local e = { path = path, name = name, category = "Hat / FDless", reanim = { "fdless" } }
	w.repo.byPath[path] = e
	return e
end

local function hasToast(w, needle)
	for _, t in ipairs(w.toasts) do
		if string.find(t, needle, 1, true) then
			return true
		end
	end
	return false
end

local function cleanup(w)
	if w.R.reg then
		pcall(function()
			w.R.reg:destroy()
		end)
	end
	Host.uninstall(w.c, w.R)
end

local function sharedBody(w)
	return function(rec)
		local FD = w.RG.GenesisFDless
		assert(type(FD) == "table", "the guard slot is empty, the shared copy is missing")
		FD.reanimate()
	end
end

T.section("fdless_flow: Last Star style script, getgenv() and _G are different tables")
do
	local w = newWorld()
	local e = entryOf(w, "Last Star", "Scripts/Hat/FDless/LastStar.lua")
	w.bodies[e.path] = sharedBody(w)
	T.ok(w.RG ~= w.GE, "the two tables are different, like in a real executor")
	w.R.start(e)
	task.wait(3)
	T.eq(w.R.current(), e.path, "the hub sees the script as the current reanimate")
	T.eq(w.R.reg:state(), "running", "the registry reached running instead of timing out")
	T.eq(type(w.RG.GenesisFDless), "table", "the shared FDless is where the scripts look for it")
	T.eq(w.GE.GenesisFDless, w.RG.GenesisFDless, "and the hub's own table has it too")
	T.eq(w.RG.GenesisFDless.config.fling, true, "the options were visible while the file loaded")
	T.eq(w.GE.fling, nil, "and they were taken back afterwards")
	T.ok(w.R.reg:get("fdless").api() ~= nil, "the hub kept the API the script got")
	T.eq(#w.stops, 0, "nothing was stopped")
	T.eq(hasToast(w, "Couldn't start"), false, "no failure toast")
	task.wait(60)
	T.eq(w.R.reg:state(), "running", "still running long after the start wait would have run out")
	T.eq(#w.stops, 0, "still nothing stopped")
	w.R.stop()
	task.wait(4)
	T.eq(w.R.reg:state(), "idle", "stopping works")
	T.eq(w.RG.GenesisFDless, nil, "the guard slot is empty again")
	T.eq(w.GE.GenesisFDless, nil, "in both tables")
	T.eq(#w.stops, 1)
	cleanup(w)
end

T.section("fdless_flow: Dubstep Gun style script that ships its own FDless")
do
	local w = newWorld()
	local e = entryOf(w, "Dubstep Gun (Original)", "Scripts/Hat/FDless/DubstepGun.lua")
	w.bodies[e.path] = function(rec)
		local FD = w.RG.GenesisFDless
		if type(FD) == "table" then
			rec.usedShared = true
			FD.reanimate()
			return
		end
		rec.own = true
		w.RG.GenesisFDless = { reanimate = function() end, stopreanimate = function() end, isReanimated = function() return true end }
		rec.added = { GenesisFDless = true }
	end
	w.R.start(e)
	task.wait(3)
	T.eq(w.R.reg:state(), "running", "the script runs")
	local rec = w.shared.running[e.path]
	T.eq(rec.usedShared, true, "its guard found the shared copy the hub put there first")
	T.eq(rec.own, nil, "so the FDless inside the script never ran")
	T.eq(w.RG.GenesisFDless.config.fling, true, "the shared copy read the FDless options")
	T.eq(w.GE.fling, nil, "and they were taken back")
	T.eq(getmetatable(w.RG), nil, "no trap is set on _G")
	T.eq(getmetatable(w.GE), nil, "or on the executor's table")
	T.ok(w.R.reg:get("fdless").api() ~= nil, "the hub kept the API, so emotes work")
	task.wait(30)
	T.eq(w.R.reg:state(), "running", "it is not stopped later")
	T.eq(#w.stops, 0)
	w.R.stop()
	task.wait(4)
	T.eq(w.R.reg:state(), "idle")
	T.eq(w.RG.GenesisFDless, nil, "the shared copy is taken out of the guard after the stop")
	cleanup(w)
end

T.section("fdless_flow: a script that ignores the reanimation it was given is reported")
do
	local w = newWorld()
	local e = entryOf(w, "Private", "Scripts/Hat/FDless/Private.lua")
	w.bodies[e.path] = function(rec)
		rec.private = true
	end
	w.R.start(e)
	task.wait(50)
	T.eq(w.R.reg:state(), "idle", "a script that never reanimates on the hub's pick is not called running")
	T.ok(hasToast(w, "Couldn't start"), "and the player is told")
	T.eq(w.RG.GenesisFDless, nil)
	cleanup(w)
end

T.section("fdless_flow: a script that dies is reported and cleaned up")
do
	local w = newWorld()
	local e = entryOf(w, "Dubstep Gun (Original)", "Scripts/Hat/FDless/DubstepGun.lua")
	w.bodies[e.path] = function()
		error("boom")
	end
	w.R.start(e)
	task.wait(4)
	T.eq(w.R.reg:state(), "idle")
	T.eq(w.R.current(), nil)
	T.ok(hasToast(w, "boom"), "the reason is shown")
	T.eq(w.RG.GenesisFDless, nil)
	T.eq(w.GE.GenesisFDless, nil)
	T.eq(getmetatable(w.RG), nil, "no trap is left behind")
	cleanup(w)
end

T.section("fdless_flow: a shared script that never calls reanimate is reported")
do
	local w = newWorld()
	local e = entryOf(w, "Last Star", "Scripts/Hat/FDless/LastStar.lua")
	w.bodies[e.path] = function() end
	w.R.start(e)
	task.wait(50)
	T.eq(w.R.reg:state(), "idle", "it is reported after the wait")
	T.ok(hasToast(w, "Couldn't start"), "and the user is told")
	T.eq(w.RG.GenesisFDless, nil)
	cleanup(w)
end

T.section("fdless_flow: an FDless that was already running is stopped first")
do
	local w = newWorld()
	local e = entryOf(w, "Last Star", "Scripts/Hat/FDless/LastStar.lua")
	local on = true
	local stops = 0
	local foreign = {
		reanimate = function() end,
		stopreanimate = function()
			stops = stops + 1
			on = nil
		end,
		isReanimated = function()
			return on
		end,
	}
	w.RG.GenesisFDless = foreign
	w.bodies[e.path] = sharedBody(w)
	w.R.start(e)
	task.wait(4)
	T.eq(stops, 1, "the other FDless was stopped once")
	T.eq(w.R.reg:state(), "running")
	T.ok(w.RG.GenesisFDless ~= foreign, "the hub's copy replaced it")
	T.ok(hasToast(w, "Stopped the FDless that was already running"), "and the user is told")
	w.R.stop()
	task.wait(4)
	T.eq(w.RG.GenesisFDless, foreign, "when the hub is done the previous value is back")
	cleanup(w)
end

T.section("fdless_flow: an FDless that cannot be stopped blocks the start with a clear reason")
do
	local w = newWorld()
	local e = entryOf(w, "Last Star", "Scripts/Hat/FDless/LastStar.lua")
	local stubborn = {
		reanimate = function() end,
		stopreanimate = function() end,
		isReanimated = function()
			return true
		end,
	}
	w.RG.GenesisFDless = stubborn
	w.bodies[e.path] = sharedBody(w)
	w.R.start(e)
	task.wait(8)
	T.eq(w.R.reg:state(), "idle")
	T.ok(hasToast(w, "another FDless is still running"), "the reason is shown")
	T.eq(#w.started, 0, "the script was never started")
	T.eq(w.RG.GenesisFDless, stubborn, "and nothing of the user's was touched")
	cleanup(w)
end

T.section("fdless_flow: FDless on its own, with different tables")
do
	local w = newWorld()
	w.R.reg:select("hat", "fdless")
	w.R.startSolo("hat")
	task.wait(3)
	T.eq(w.R.reg:state(), "running", "FDless on its own starts")
	T.eq(type(w.RG.GenesisFDless), "table")
	T.eq(w.GE.GenesisFDless, w.RG.GenesisFDless)
	w.R.stop()
	task.wait(4)
	T.eq(w.R.reg:state(), "idle")
	T.eq(w.RG.GenesisFDless, nil)
	T.eq(w.GE.GenesisFDless, nil)
	cleanup(w)
end

T.section("fdless_flow: one table for both, as on executors where getgenv() is _G")
do
	local w = newWorld({ same = true })
	local e = entryOf(w, "Last Star", "Scripts/Hat/FDless/LastStar.lua")
	w.bodies[e.path] = sharedBody(w)
	T.ok(w.RG == w.GE)
	w.R.start(e)
	task.wait(3)
	T.eq(w.R.reg:state(), "running")
	T.eq(type(w.RG.GenesisFDless), "table")
	w.R.stop()
	task.wait(4)
	T.eq(w.R.reg:state(), "idle")
	T.eq(w.RG.GenesisFDless, nil)
	cleanup(w)
end

T.section("fdless_flow: a locked table still gets the shared copy")
do
	local w = newWorld()
	setmetatable(w.RG, { __metatable = "locked" })
	local e = entryOf(w, "Dubstep Gun (Original)", "Scripts/Hat/FDless/DubstepGun.lua")
	w.bodies[e.path] = sharedBody(w)
	w.R.start(e)
	task.wait(4)
	T.eq(w.R.reg:state(), "running", "a locked metatable does not keep the hub from filling the guard")
	T.eq(hasToast(w, "emotes are off"), false, "and nothing is off")
	w.R.stop()
	task.wait(4)
	T.eq(w.R.reg:state(), "idle")
	cleanup(w)
end

T.section("fdless_flow: a hub-native script on Script Reanimate, with different tables")
do
	local w = newWorld({ lumen = true })
	local e = { path = "Scripts/Hat/DubstepGun.lua", name = "Dubstep Gun (Hub)", category = "Hat", reanim = { "atsuko", "fdless" } }
	w.repo.byPath[e.path] = e
	w.bodies[e.path] = function(rec)
		local L = w.GE.LumenReanim
		assert(type(L) == "table", "the library is missing")
		L.reanimate({})
	end
	w.R.start(e)
	task.wait(4)
	T.eq(w.R.reg:state(), "running", "a hub-native script starts")
	T.eq(w.R.current(), e.path)
	T.eq(w.RG.GenesisFDless.marker, "rig", "the rig sits in the guard slot too, a native script just does not use it")
	T.eq(w.GE.AtsukoHatFd, nil, "and there is no FDless for it to find")
	task.wait(30)
	T.eq(w.R.reg:state(), "running", "and it stays up")
	T.eq(#w.stops, 0)
	w.R.stop()
	task.wait(4)
	T.eq(w.R.reg:state(), "idle")
	cleanup(w)
end

T.section("fdless_flow: an FDless script put on Script Reanimate gets the rig in both tables and gives it back")
do
	local w = newWorld({ lumen = true })
	local e = { path = "Scripts/Other/Plain.lua", name = "Plain Script", category = "Other" }
	w.repo.byPath[e.path] = e
	w.bodies[e.path] = function(rec)
		local FD = w.RG.GenesisFDless
		assert(type(FD) == "table" and FD.marker == "rig", "the rig is not there")
		w.GE.LumenReanim.reanimate({})
	end
	local previous = { stale = true }
	w.RG.GenesisFDless = previous
	w.R.start(e)
	task.wait(4)
	T.eq(w.R.reg:state(), "running")
	T.eq(w.GE.GenesisFDless.marker, "rig", "the executor's table has it too")
	w.R.stop()
	task.wait(4)
	T.eq(w.RG.GenesisFDless, previous, "the old value is back")
	T.eq(w.GE.GenesisFDless, nil)
	cleanup(w)
end

T.section("fdless_flow: a hub-native script on FDless finds the shared copy in AtsukoHatFd")
do
	local w = newWorld()
	w.R.reg:select("hat", "fdless")
	local e = { path = "Scripts/Hat/SnakeBanisherV3.lua", name = "Snake Banisher V3", category = "Hat", reanim = { "atsuko", "fdless" } }
	w.repo.byPath[e.path] = e
	w.bodies[e.path] = function(rec)
		local hub = w.GE.AtsukoHatFd
		assert(type(hub) == "table" and type(hub.reanimate) == "function", "AtsukoHatFd is empty")
		w.GE.AtsukoScriptAligns = { { PartName = "Head", meshid = "1" } }
		rec.hub = hub
		hub.reanimate()
	end
	w.R.start(e)
	task.wait(4)
	T.eq(w.R.reg:state(), "running", "the hub's own script runs on FDless")
	T.eq(w.R.reg:activeProvider().id, "fdless")
	T.eq(w.shared.running[e.path].hub, w.RG.GenesisFDless, "it is the same shared copy the Main Scripts get")
	T.ok(w.R.reg:get("fdless").api() ~= nil, "and the hub follows it, so emotes work")
	w.R.stop()
	task.wait(4)
	T.eq(w.R.reg:state(), "idle")
	T.eq(w.GE.AtsukoHatFd, nil, "AtsukoHatFd is cleared")
	T.eq(w.GE.AtsukoScriptAligns, nil, "and so is the script's hat list")
	cleanup(w)
end

T.section("fdless_flow: switching between two FDless scripts never deanimates the hub")
do
	local w = newWorld()
	local a = entryOf(w, "Last Star", "Scripts/Hat/FDless/LastStar.lua")
	local b = entryOf(w, "Dubstep Gun", "Scripts/Hat/FDless/DubstepGun.lua")
	local reanimations = 0
	for _, e in ipairs({ a, b }) do
		w.bodies[e.path] = function(rec)
			local FD = w.RG.GenesisFDless
			assert(type(FD) == "table", "the guard slot is empty")
			if FD.isReanimated() then
				FD.stopreanimate()
			end
			reanimations = reanimations + 1
			FD.reanimate()
			w.onStop[e.path] = function()
				FD.stopreanimate()
			end
		end
	end
	local previous = { stale = true }
	w.RG.GenesisFDless = previous
	w.R.start(a)
	task.wait(4)
	T.eq(w.R.current(), a.path)
	local shared = w.RG.GenesisFDless
	T.eq(w.R.canSwitch(b), true, "a second FDless script can take over")
	w.toasts = {}
	w.R.start(b)
	T.eq(w.R.busy, "switching")
	task.wait(5)
	T.eq(w.R.busy, nil)
	T.eq(w.R.reg:state(), "running", "the hub is still reanimated")
	T.eq(w.R.current(), b.path, "on the new script")
	T.eq(w.R.reg:activeProvider().id, "fdless")
	T.same(w.stops, { a.path }, "only the old script was stopped")
	T.same(w.kept, { true }, "and without a respawn")
	T.eq(reanimations, 2)
	T.eq(w.RG.GenesisFDless, shared, "the same FDless stays in place")
	T.ok(w.R.reg:get("fdless").api() ~= nil, "and the hub follows the new script's body, so emotes keep working")
	T.ok(hasToast(w, "Switched from Last Star, still reanimated"), table.concat(w.toasts, " / "))
	T.eq(hasToast(w, "Couldn't"), false)
	T.eq(hasToast(w, "Stopped on its own"), false, "the old script letting go is not taken as a stop")
	task.wait(10)
	T.eq(w.R.reg:state(), "running", "it stays up")
	w.R.stop()
	task.wait(4)
	T.eq(w.R.reg:state(), "idle")
	T.eq(w.RG.GenesisFDless, previous, "what was there before the first script comes back after a switch too")
	cleanup(w)
end

T.section("fdless_flow: switching on Script Reanimate hands the same body over")
do
	local w = newWorld({ lumen = true })
	local a = { path = "Scripts/Hat/A.lua", name = "Alpha", category = "Hat", reanim = { "atsuko", "fdless" } }
	local b = { path = "Scripts/Hat/B.lua", name = "Beta", category = "Hat", reanim = { "atsuko", "fdless" } }
	for _, e in ipairs({ a, b }) do
		w.repo.byPath[e.path] = e
		w.bodies[e.path] = function(rec)
			local L = w.GE.LumenReanim
			L.reanimate({})
			w.onStop[e.path] = function()
				L.stopreanimate()
			end
		end
	end
	w.R.start(a)
	task.wait(4)
	T.eq(w.R.current(), a.path)
	local L = w.GE.LumenReanim
	T.eq(L.made, 1)
	w.R.start(b)
	task.wait(5)
	T.eq(w.R.reg:state(), "running")
	T.eq(w.R.current(), b.path)
	T.same(L.holds, { true, false }, "the body is held while the old script lets go")
	T.eq(L.isReanimated(), true, "so the old script's stop does nothing")
	T.eq(L.made, 1, "no second body was made")
	T.eq(L.handed, 1, "the new script was handed the one already standing")
	T.same(w.kept, { true })
	T.ok(hasToast(w, "Switched from Alpha, still reanimated"), table.concat(w.toasts, " / "))
	w.R.stop()
	task.wait(4)
	T.eq(w.R.reg:state(), "idle")
	T.eq(L.isReanimated(), nil, "a real stop still works")
	cleanup(w)
end

T.section("fdless_flow: nothing picked, nothing starts")
do
	local w = newWorld()
	w.c.S.hatReanim = ""
	local e = { path = "Scripts/Hat/FDless/Both.lua", name = "Both", category = "Hat", reanim = { "atsuko", "fdless" } }
	w.repo.byPath[e.path] = e
	w.bodies[e.path] = sharedBody(w)
	w.R.start(e)
	task.wait(2)
	T.eq(w.R.reg:state(), "idle")
	T.eq(#w.started, 0, "the script was not started")
	T.ok(hasToast(w, "Pick Script Reanimate or FDless first"), "the player is asked to pick")
	cleanup(w)
end

getgenv = nil
getRG = nil
current = nil
