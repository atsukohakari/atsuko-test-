local Host = loadmodule("Hub/modules/reanim_host.lua")
local Controller = loadmodule("Hub/modules/reanim.lua")

Vector3 = { new = function(x, y, z)
	return { x = x, y = y, z = z }
end }
Enum = { HumanoidRigType = { R15 = "R15", R6 = "R6" } }

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

local function fakeChar(parts)
	local char = { items = parts.items or {}, hum = parts.hum }
	function char:FindFirstChildOfClass(class)
		if class == "Humanoid" then
			return self.hum
		end
		return nil
	end
	function char:GetChildren()
		return self.items
	end
	return char
end

local function accessory(name)
	return {
		Name = name,
		IsA = function(_, class)
			return class == "Accessory"
		end,
	}
end

local function newWorld(over)
	over = over or {}
	local w = { runs = {}, stops = {}, respawns = 0, saves = 0, toasts = {}, logs = {}, loaded = {}, fileCalls = {}, libCalls = {} }
	w.bus = newBus()
	w.runner = {
		pending = {},
		failed = {},
		isActive = function(rec)
			return rec ~= nil and (rec.kind ~= "commands" or rec.active == true)
		end,
		run = function(entry)
			w.runs[#w.runs + 1] = entry.path
		end,
		stop = function(path, quiet)
			w.stops[#w.stops + 1] = path .. "|" .. tostring(quiet)
		end,
		respawn = function()
			w.respawns = w.respawns + 1
			return "old"
		end,
	}
	w.repo = { byPath = {}, remote = {} }
	w.shared = { running = {} }
	w.hum = { RigType = "R15" }
	w.cam = {}
	w.lp = { Character = fakeChar({ hum = w.hum, items = { accessory("Pal Hair"), { Name = "Part", IsA = function() return false end } } }) }
	w.ws = { CurrentCamera = w.cam }
	w.X = { loadstring = loadstring }
	w.core = {
		mods = {},
		fileSource = function(rel)
			w.fileCalls[#w.fileCalls + 1] = rel
			return "source of " .. rel
		end,
		loadLib = function(name, key, need)
			w.libCalls[#w.libCalls + 1] = name .. "|" .. key .. "|" .. tostring(need)
			return { lib = name }
		end,
	}
	w.core.loadModule = function(name, retry, context)
		w.loaded[#w.loaded + 1] = name
		if over.loadModule then
			local mod, err, handled = over.loadModule(name, retry, context)
			if handled then
				return mod, err
			end
		end
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
		GENV = {},
		X = w.X,
		LP = w.lp,
		workspace = w.ws,
		Runner = w.runner,
		Repo = w.repo,
		SHARED = w.shared,
		Core = w.core,
	}
	return w
end

T.section("host deps: the script state comes from the hub")
do
	local w = newWorld()
	local d = Host.deps(w.c, Controller)
	T.eq(d.S, w.c.S)
	T.eq(d.save, w.c.saveSettings)
	T.eq(d.notify, w.c.notify)
	T.eq(d.isNative, Controller.isNative)
	T.eq(d.wait, task.wait)
	T.eq(d.spawn, task.spawn)
	T.eq(d.now, os.clock)
	T.eq(d.alive(), true)
	w.c.HUB.alive = false
	T.eq(d.alive(), false, "alive follows the hub")
	w.c.HUB.alive = nil
	T.eq(d.alive(), false)
	w.c.HUB.alive = true

	T.eq(d.scriptActive("a"), false)
	T.eq(d.scriptActive(nil), false)
	T.eq(d.scriptActive(5), false)
	w.shared.running["a"] = { name = "Alpha", status = "running" }
	T.eq(d.scriptActive("a"), true)
	T.eq(d.nameOf("a"), "Alpha")
	T.eq(d.nameOf("b"), nil)
	T.eq(d.nameOf(nil), nil)
	T.eq(d.scriptAlive("a"), true)
	w.shared.running["a"].status = "error"
	w.shared.running["a"].err = "boom"
	T.eq(d.scriptActive("a"), true, "a script with an error is still there")
	T.eq(d.scriptAlive("a"), false, "but it is not alive")
	T.eq(d.scriptError("a"), "boom")
	w.shared.running["a"].err = nil
	T.eq(d.scriptError("a"), "the script reported an error")
	w.shared.running["a"].status = "running"
	T.eq(d.scriptError("a"), nil)
	w.runner.failed["a"] = "couldn't download it"
	T.eq(d.scriptError("a"), "couldn't download it", "a start failure wins")
	w.runner.failed["a"] = nil
	T.eq(d.scriptAlive("zzz"), false)
	T.eq(d.scriptError("zzz"), nil)
	T.eq(d.scriptError(nil), nil)

	w.shared.running["cmd"] = { name = "Cmd", kind = "commands", active = false }
	T.eq(d.scriptActive("cmd"), false, "a stopped command script is not active")
	w.shared.running["cmd"].active = true
	T.eq(d.scriptActive("cmd"), true)

	T.eq(d.scriptPending("a"), false)
	w.runner.pending["a"] = true
	T.eq(d.scriptPending("a"), true)
	w.runner.pending["a"] = nil
	T.eq(d.scriptPending("a"), false)

	local entry = { path = "Scripts/Hat/A.lua", name = "A" }
	local remote = { path = "net/B", name = "B" }
	w.repo.byPath[entry.path] = entry
	w.repo.remote[remote.path] = remote
	T.eq(d.entryOf(entry.path), entry)
	T.eq(d.entryOf(remote.path), remote)
	T.eq(d.entryOf("none"), nil)
	T.eq(d.entryOf(nil), nil)
	T.eq(d.entryOf(7), nil)

	d.runScript(entry)
	T.same(w.runs, { entry.path })
	d.stopScript(entry.path)
	T.same(w.stops, { entry.path .. "|true" }, "a script is stopped quietly")

	w.shared.running = {
		["Scripts/Hat/Z.lua"] = { name = "Z" },
		["Scripts/Hat/A.lua"] = { name = "A" },
		["net/B"] = { name = "B" },
		["Scripts/Hat/Idle.lua"] = { name = "Idle", kind = "commands", active = false },
	}
	w.repo.byPath["Scripts/Hat/Z.lua"] = { path = "Scripts/Hat/Z.lua" }
	w.repo.byPath["Scripts/Hat/Idle.lua"] = { path = "Scripts/Hat/Idle.lua" }
	T.same(d.activePaths(), { "Scripts/Hat/A.lua", "Scripts/Hat/Z.lua" }, "only the hub's own active scripts, in a fixed order")
	w.shared.running = {}
	T.same(d.activePaths(), {})

	d.fire("reanim", { state = "running" })
	T.same(w.bus.fired, { "reanim" })
	local seen
	w.bus.on("x", function(a, b)
		seen = tostring(a) .. tostring(b)
	end)
	d.fire("x", "p")
	T.eq(seen, "pnil", "the payload goes through")
	d.log("error", "it broke")
	T.same(w.logs, { "error|Reanimation|it broke" })
	w.c.GENV.LumenReanim = { version = 4 }
	T.eq(d.lumen(), w.c.GENV.LumenReanim)
	w.c.GENV.LumenReanim = nil
	T.eq(d.lumen(), nil)
end

T.section("host registry options")
do
	local w = newWorld()
	local o = Host.registryOptions(w.c)
	T.eq(o.S, w.c.S, "the registry keeps its choices in the hub settings")
	T.eq(o.save, w.c.saveSettings)
	T.eq(o.X, w.X)
	T.eq(o.notify, w.c.notify)
	T.eq(o.wait, task.wait)
	T.eq(o.spawn, task.spawn)
	T.eq(o.delay, task.delay)
	T.eq(o.now, os.clock)
	local got
	w.bus.on("reanim", function(payload)
		got = payload
	end)
	o.fire("reanim", { state = "running", provider = "fdless" })
	T.eq(got.state, "running")
	T.eq(got.provider, "fdless")
	o.log("warn", "careful")
	T.same(w.logs, { "warn|Reanimation|careful" })
end

T.section("host provider context")
do
	local w = newWorld()
	local p = Host.providerCtx(w.c)
	T.eq(p.G, w.c.GENV)
	T.eq(p.genv, w.c.GENV)
	T.eq(p.X, w.X)
	T.eq(p.now, os.clock)
	T.eq(p.wait, task.wait)
	T.eq(p.spawn, task.spawn)
	T.eq(p.delay, task.delay)
	T.eq(p.notify, w.c.notify)
	T.eq(p.vec3, Vector3.new)
	T.eq(p.loadFile("Reanimation/Hat/FDless.lua"), "source of Reanimation/Hat/FDless.lua")
	T.same(w.fileCalls, { "Reanimation/Hat/FDless.lua" })
	local lib = p.loadLib("Reanimate", "LumenReanim", 4)
	T.eq(lib.lib, "Reanimate")
	T.same(w.libCalls, { "Reanimate|LumenReanim|4" })
	local f = p.loadstring("return 5", "=x")
	T.eq(f(), 5)
	w.X.loadstring = nil
	local none, why = p.loadstring("return 5", "=x")
	T.eq(none, nil)
	T.eq(why, "your executor has no loadstring")
	local bare = Host.providerCtx({ GENV = {}, Core = w.core, LP = w.lp, Runner = w.runner })
	T.eq(bare.X ~= nil, true, "a hub without executor functions still gives a context")
	T.eq(select(2, bare.loadstring("return 1", "=x")), "your executor has no loadstring")
end

T.section("host world helpers")
do
	local w = newWorld()
	local world = Host.world(w.c)
	T.eq(world.character(), w.lp.Character)
	T.eq(world.workspace(), w.ws)
	T.eq(world.isR15(), true)
	w.hum.RigType = "R6"
	T.eq(world.isR15(), false)
	w.lp.Character.hum = nil
	T.eq(world.isR15(), false, "no humanoid is not R15")
	w.lp.Character = nil
	T.eq(world.isR15(), false, "no character is not R15")
	T.eq(world.character(), nil)
	T.eq(world.hasAccessory("Pal Hair"), false, "no character has no accessory")
	w.lp.Character = fakeChar({ hum = w.hum, items = { accessory("Pal Hair"), accessory("Hat") } })
	T.eq(world.hasAccessory("Pal Hair"), true)
	T.eq(world.hasAccessory("Hat"), true)
	T.eq(world.hasAccessory("Wings"), false)
	w.lp.Character = fakeChar({ hum = w.hum, items = { { Name = "Pal Hair", IsA = function() return false end } } })
	T.eq(world.hasAccessory("Pal Hair"), false, "only accessories count")
	w.lp.Character = fakeChar({ hum = w.hum })
	world.restoreCamera()
	T.eq(w.cam.CameraSubject, w.hum, "the camera goes back to the character")
	w.cam.CameraSubject = nil
	w.lp.Character = nil
	world.restoreCamera()
	T.eq(w.cam.CameraSubject, nil, "without a character the camera is left alone")
	w.lp.Character = fakeChar({ hum = w.hum })
	w.ws.CurrentCamera = nil
	world.restoreCamera()
	T.eq(w.cam.CameraSubject, nil, "without a camera nothing happens")
	T.eq(world.respawn(), "old")
	T.eq(w.respawns, 1)
	local noLp = Host.world({ Runner = w.runner, workspace = w.ws })
	T.eq(noLp.character(), nil)
	T.eq(noLp.isR15(), false)
end

T.section("host install: the real controller and providers")
do
	local w = newWorld()
	local old = function() end
	local R = { start = old, current = old, path = "before", busy = nil, setRegistry = function(self, reg) self.reg = reg end }
	local ok, loaded = Host.install(w.c, R)
	T.eq(ok, true)
	T.eq(loaded, 4, "all four reanimations loaded")
	T.eq(R.start ~= old, true, "the controller took over")
	T.eq(R.loadError, nil)
	T.eq(type(R.reg), "table")
	T.eq(#R.reg:list("hat"), 2)
	T.eq(#R.reg:list("limb"), 2)
	T.eq(R.reg:get("atsuko").name, "Script Reanimate")
	T.eq(R.reg:get("fdless").name, "FDless")
	T.eq(R.reg:get("gelatek").name, "Gelatek")
	T.eq(R.reg:get("uhhhhhh").name, "Uhhhhhh")
	T.eq(w.loaded[1], "reanim")
	T.eq(w.loaded[2], "@Reanimation/providers/registry")
	T.eq(w.loaded[3], "@Reanimation/providers/atsuko")
	T.eq(#w.loaded, 6)
	T.eq(R.hostListener ~= nil, true)
	T.eq(#w.bus.map["reanim"], 1)
	R.busy = nil
	R.run = { path = "Scripts/Hat/A.lua" }
	R.path = "Scripts/Hat/A.lua"
	w.bus.fire("reanim", { state = "stopped" })
	T.eq(R.run, nil, "a stop event reaches the controller")
	T.eq(R.path, nil)
	R.run = { path = "x" }
	w.bus.fire("reanim")
	T.eq(R.run ~= nil, true, "an event without a payload is ignored")
	w.bus.fire("reanim", "text")
	T.eq(R.run ~= nil, true)
	Host.uninstall(w.c, R)
	T.eq(R.hostListener, nil)
	T.eq(#(w.bus.map["reanim"] or {}), 0)
	T.eq(R.reg, nil, "the registry is shut down")
end

T.section("host install: something is missing")
do
	local w = newWorld({
		loadModule = function(name)
			if name == "reanim" then
				return nil, "couldn't download reanim\nsecond line", true
			end
		end,
	})
	local old = function() end
	local R = { start = old, path = "before" }
	local ok, why = Host.install(w.c, R)
	T.eq(ok, false)
	T.eq(why, "couldn't download reanim")
	T.eq(R.loadError, "couldn't download reanim")
	T.eq(R.start, old, "nothing was replaced")
	T.eq(R.path, "before")
	T.eq(w.bus.map["reanim"], nil, "no listener was added")

	local w2 = newWorld({
		loadModule = function(name)
			if name == "reanim" then
				return {}, nil, true
			end
		end,
	})
	local R2 = { start = old }
	local ok2, why2 = Host.install(w2.c, R2)
	T.eq(ok2, false)
	T.eq(why2, "couldn't load the reanimation controller")
	T.eq(R2.start, old)

	local w3 = newWorld({
		loadModule = function(name)
			if name == "@Reanimation/providers/registry" then
				return nil, "couldn't download registry", true
			end
		end,
	})
	local R3 = { start = old, current = old, path = "kept", busy = nil, custom = 7 }
	local ok3, why3 = Host.install(w3.c, R3)
	T.eq(ok3, false)
	T.eq(why3, "couldn't download registry")
	T.eq(R3.start, old, "the old behaviour is back")
	T.eq(R3.current, old)
	T.eq(R3.path, "kept")
	T.eq(R3.custom, 7)
	T.eq(R3.reg, nil, "nothing of the controller is left")
	T.eq(R3.ask, nil)
	T.eq(R3.toggle, nil)
	T.eq(R3.loadError, "couldn't download registry")
	T.eq(#(w3.bus.map["reanim"] or {}), 0, "the listener is removed again")

	local w4 = newWorld({
		loadModule = function(name)
			if name == "@Reanimation/providers/registry" then
				return { new = function()
					error("registry exploded\nmore")
				end }, nil, true
			end
		end,
	})
	local R4 = { start = old, path = "kept" }
	local ok4, why4 = Host.install(w4.c, R4)
	T.eq(ok4, false)
	T.eq(string.find(why4, "registry exploded", 1, true) ~= nil, true)
	T.eq(string.find(why4, "\n", 1, true), nil, "only the first line is kept")
	T.eq(R4.start, old)
	T.eq(R4.path, "kept")
	T.eq(R4.loadError, why4)
end

T.section("host install: one provider that does not load")
do
	local w = newWorld({
		loadModule = function(name)
			if name == "@Reanimation/providers/uhhhhhh" then
				return nil, "couldn't download uhhhhhh", true
			end
		end,
	})
	local R = {}
	local ok, loaded = Host.install(w.c, R)
	T.eq(ok, true, "the others still work")
	T.eq(loaded, 3, "atsuko, fdless and gelatek loaded")
	T.eq(R.reg:get("uhhhhhh"), nil)
	T.eq(R.reg.failed.uhhhhhh, "couldn't download uhhhhhh")
end
