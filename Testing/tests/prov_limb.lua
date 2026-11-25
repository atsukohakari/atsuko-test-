local Registry = loadmodule("Reanimation/providers/registry.lua")
local Gelatek = loadmodule("Reanimation/providers/gelatek.lua")
local Uhhhhhh = loadmodule("Reanimation/providers/uhhhhhh.lua")
local Atsuko = loadmodule("Reanimation/providers/atsuko.lua")

local toasts = {}
local function note(title, text, kind)
	toasts[#toasts + 1] = title .. "|" .. text .. "|" .. tostring(kind)
end

local function world(over)
	local w = {
		calls = {},
		r15 = false,
		accessories = { ["Pal Hair"] = true },
		hasChar = true,
	}
	w.isR15 = function()
		return w.r15
	end
	w.hasAccessory = function(name)
		return w.accessories[name] == true
	end
	w.character = function()
		return w.hasChar and { Name = "Character" } or nil
	end
	w.workspace = function()
		return { Name = "Workspace" }
	end
	w.restoreCamera = function()
		w.calls[#w.calls + 1] = "camera"
	end
	w.respawn = function()
		w.calls[#w.calls + 1] = "respawn"
		return true
	end
	for k, v in pairs(over or {}) do
		w[k] = v
	end
	return w
end

local function newCtx(over)
	local ctx = {
		G = {},
		genv = {},
		X = {},
		world = world(),
		vec3 = function(x, y, z)
			return { x = x, y = y, z = z }
		end,
		loadFile = function(rel)
			return string.rep("-- fake source\n", 20)
		end,
		loadstring = function(src, name)
			return function() end
		end,
		notify = note,
		wait = task.wait,
		now = time,
		spawn = task.spawn,
		delay = task.delay,
		log = function() end,
	}
	for k, v in pairs(over or {}) do
		ctx[k] = v
	end
	return ctx
end

local function flat(t)
	return table.concat(t, ",")
end

local function run(options)
	return { options = options or {}, notify = note }
end

local FULL = {}
for _, n in ipairs({ "loadstring", "request", "getcustomasset", "readfile", "writefile", "delfile", "isfile", "isfolder", "makefolder", "listfiles", "firetouchinterest", "getobjects" }) do
	FULL[n] = true
end

T.section("prov_limb: both limb providers pass the registry's validation")
for _, P in ipairs({ Gelatek, Uhhhhhh, Atsuko }) do
	T.eq(#Registry.validate(P), 0, P.id .. ": " .. table.concat(Registry.validate(P), ";"))
end
T.eq(Gelatek.kind .. Uhhhhhh.kind .. Atsuko.kind, "limblimbhat")
T.eq(Gelatek.caps.fdApi or Uhhhhhh.caps.fdApi, false, "limb providers do not claim an FDless API")
T.eq(Gelatek.caps.bullet, true)
T.eq(Gelatek.stopWarning, "Stopping respawns you. Continue?")
T.eq(#Gelatek.settings, 6)
T.eq(#Uhhhhhh.settings, 8)
T.eq(#Atsuko.settings, 5)
for _, P in ipairs({ Gelatek, Uhhhhhh, Atsuko }) do
	T.ok(P.blurb == nil or (type(P.blurb) == "string" and #P.blurb > 10), P.id .. " has no blurb or a real one")
	for _, def in ipairs(P.settings) do
		T.ok(def.label ~= nil and def.desc ~= nil and def.group ~= nil, P.id .. "." .. def.key .. " has a label, a description and a group")
	end
end

T.section("prov_limb: Gelatek availability")
do
	local ctx = newCtx()
	Gelatek.init(ctx)
	T.eq(Gelatek.available({ loadstring = true }), true)
	local ok, why = Gelatek.available({})
	T.eq(why, "your executor has no loadstring")
	ctx.world.r15 = true
	ok, why = Gelatek.available({ loadstring = true })
	T.eq(ok, false)
	T.eq(why, "your executor has no GetObjects, and R15 characters need it")
	T.eq(Gelatek.available({ loadstring = true, getobjects = true }), true)
end

T.section("prov_limb: Gelatek builds the Settings table the script expects")
do
	local ctx = newCtx()
	Gelatek.init(ctx)
	local s = Gelatek.buildSettings({ Reanimation = "Fling", Velocity = 60, AttachHead = true, CloneParent = "Workspace", CloneName = "Bob" })
	T.eq(s.Reanimation, "Fling")
	T.same(s.Velocity, { x = 60, y = 0, z = 0 }, "the number becomes a Vector3")
	T.eq(s.AttachHead, true)
	T.eq(s.DisableAnimationsR6, false)
	T.eq(s.CloneName, "Bob")
	T.eq(s.CloneParent.Name, "Workspace")
	T.eq(s.AllowNetBypass, true, "the script's line 3 finds what it reads")
	T.eq(s.SimpleBulletFling, true)
	local d = Gelatek.buildSettings(nil)
	T.eq(d.Reanimation, "Simple")
	T.same(d.Velocity, { x = 35, y = 0, z = 0 }, "the script's own default velocity")
	T.eq(d.CloneName, "TalentlessDumbass")
	T.eq(d.CloneParent.Name, "Character")
end

T.section("prov_limb: Gelatek start, running and stop")
do
	local ctx = newCtx()
	ctx.genv.Settings = "somebody's settings"
	local cleaned = { conns = 0, objs = 0 }
	ctx.loadstring = function(src, name)
		return function()
			T.eq(type(ctx.genv.Settings), "table", "Settings exists before the script runs")
			T.eq(ctx.genv.Settings.Reanimation, "Fling")
			ctx.genv.Reanimated = true
			ctx.genv.__GelatekCleanup = {
				conns = { { Disconnect = function() cleaned.conns = cleaned.conns + 1 end }, { Disconnect = function() cleaned.conns = cleaned.conns + 1 end } },
				objs = { { Destroy = function() cleaned.objs = cleaned.objs + 1 end } },
			}
		end
	end
	Gelatek.init(ctx)
	toasts = {}
	T.eq(Gelatek.isRunning(), false)
	local ok = Gelatek.start(run({ Reanimation = "Fling" }))
	T.eq(ok, true)
	T.eq(Gelatek.isRunning(), true)
	local again, why = Gelatek.start(run({}))
	T.eq(again, false)
	T.eq(why, "Gelatek is already running")
	ctx.genv.Settings.AllowNetBypass = true
	T.eq(Gelatek.stop(), true)
	T.eq(ctx.genv.Reanimated, false, "Reanimated is false after stop")
	T.eq(ctx.genv.Settings.AllowNetBypass, false, "the net bypass loop is told to end")
	T.eq(cleaned.conns, 2, "every connection was disconnected")
	T.eq(cleaned.objs, 1, "every object was destroyed")
	T.eq(flat(ctx.world.calls), "camera,respawn", "the camera is restored and the character respawned")
	T.eq(Gelatek.isRunning(), false)
	Gelatek.reset()
	T.eq(ctx.genv.Settings, "somebody's settings", "the previous Settings value comes back")
	T.eq(ctx.genv.Reanimated, nil)
	T.eq(ctx.genv.__GelatekCleanup, nil)
	ctx.world.calls = {}
	T.eq(Gelatek.stop(), true, "a second stop is harmless")
	T.eq(#ctx.world.calls, 0, "and does not respawn again")
	Gelatek.reset()
end

T.section("prov_limb: Gelatek refuses what cannot work")
do
	local ctx = newCtx()
	Gelatek.init(ctx)
	ctx.genv.Reanimated = true
	local ok, why = Gelatek.start(run({}))
	T.eq(ok, false)
	T.ok(string.find(why, "already running from another script", 1, true), "an outside run is detected first: " .. tostring(why))
	ctx.genv.Reanimated = nil
	ctx.world.accessories = {}
	ok, why = Gelatek.start(run({ Reanimation = "Bullet" }))
	T.eq(ok, false)
	T.eq(why, "Bullet mode needs the Pal Hair accessory on your character")
	T.eq(ctx.genv.Settings, nil, "nothing was prepared")
	ctx.loadstring = function()
		return function()
			ctx.genv.Reanimated = true
		end
	end
	ok = Gelatek.start(run({ Reanimation = "Simple" }))
	T.eq(ok, true, "other modes do not need it")
	Gelatek.stop()
	Gelatek.reset()
	ctx.world.hasChar = false
	ok, why = Gelatek.start(run({}))
	T.eq(why, "your character isn't loaded yet")
	ctx.world.hasChar = true
	ctx.loadFile = function()
		return nil, "couldn't find Reanimation/Limb/Gelatek.lua"
	end
	ok, why = Gelatek.start(run({}))
	T.eq(why, "couldn't find Reanimation/Limb/Gelatek.lua")
	ctx.loadFile = function()
		return string.rep("x", 300)
	end
	ctx.loadstring = function()
		return nil, "unexpected symbol\nline two"
	end
	ok, why = Gelatek.start(run({}))
	T.eq(why, "unexpected symbol")
end

T.section("prov_limb: Gelatek start failures clean up")
do
	local ctx = newCtx()
	ctx.loadstring = function()
		return function()
			error("attempt to index nil\nstack", 0)
		end
	end
	Gelatek.init(ctx)
	local ok, why = Gelatek.start(run({}))
	T.eq(ok, false)
	T.eq(why, "attempt to index nil")
	T.eq(flat(ctx.world.calls), "camera", "it never took the body apart, so the camera is put back but nobody is respawned")
	Gelatek.reset()
	T.eq(ctx.genv.Settings, nil)

	local ctx2 = newCtx()
	ctx2.loadstring = function()
		return function()
			ctx2.genv.Reanimated = true
			error("it broke halfway", 0)
		end
	end
	Gelatek.init(ctx2)
	ok, why = Gelatek.start(run({}))
	T.eq(ok, false)
	T.eq(why, "it broke halfway")
	T.eq(flat(ctx2.world.calls), "camera,respawn", "a script that failed after taking the body apart respawns you")
	T.eq(ctx2.genv.Reanimated, false)
	Gelatek.reset()

	local ctx3 = newCtx()
	ctx3.loadstring = function()
		return function() end
	end
	Gelatek.init(ctx3)
	local t0 = time()
	ok, why = Gelatek.start(run({}))
	T.eq(ok, false)
	T.eq(why, "it did not start in time")
	T.ok(time() - t0 <= 16, "it gives up after about 15 seconds")
	Gelatek.reset()
end

T.section("prov_limb: Gelatek works through the registry, including the stop warning")
do
	local ctx = newCtx()
	ctx.loadstring = function()
		return function()
			ctx.genv.Reanimated = true
			ctx.genv.__GelatekCleanup = { conns = {}, objs = {} }
		end
	end
	Gelatek.init(ctx)
	local asked = {}
	local events = {}
	local reg = Registry.new({
		S = { reanimOpts = {} },
		fire = function(name, payload)
			events[#events + 1] = payload.state
		end,
		notify = note,
		wait = task.wait,
		spawn = task.spawn,
		delay = task.delay,
		now = time,
		X = FULL,
		settle = 0,
	})
	T.eq(reg:register(Gelatek), true)
	T.eq(reg:start("limb", nil, {}), true)
	T.eq(reg:active().id, "gelatek")
	T.eq(flat(events), "starting,running")
	T.eq(reg:stop("user"), true)
	T.eq(flat(events), "starting,running,stopping,stopped")
	T.eq(ctx.genv.Settings, nil)
	T.eq(ctx.genv.Reanimated, nil)
end

T.section("prov_limb: Gelatek knows where its clone is")
do
	local ctx = newCtx()
	Gelatek.init(ctx)
	T.eq(Gelatek.clone(), nil, "nothing before it runs")
	local child = { Name = "TalentlessDumbass" }
	local parent = {
		FindFirstChild = function(self, name)
			if name == child.Name then
				return child
			end
			return nil
		end,
	}
	ctx.genv.Settings = { CloneParent = parent, CloneName = "TalentlessDumbass" }
	T.eq(Gelatek.clone(), child, "found under the parent the settings name")
	ctx.genv.Settings = { CloneParent = parent, CloneName = "Other" }
	T.eq(Gelatek.clone(), nil, "a clone with another name is not found")
	ctx.genv.Settings = { CloneParent = parent, CloneName = "" }
	T.eq(Gelatek.clone(), nil)
	ctx.genv.Settings = { CloneParent = parent }
	T.eq(Gelatek.clone(), nil)
	ctx.genv.Settings = { CloneName = "TalentlessDumbass" }
	T.eq(Gelatek.clone(), nil)
	ctx.genv.Settings = { CloneParent = {}, CloneName = "x" }
	T.eq(Gelatek.clone(), nil, "a parent that cannot search does not throw")
	ctx.genv.Settings = "junk"
	T.eq(Gelatek.clone(), nil)
	T.eq(Uhhhhhh.clone, nil, "Uhhhhhh has no clone to give")
end

T.section("prov_limb: Uhhhhhh availability lists what is missing")
do
	T.eq(Uhhhhhh.available(FULL), true)
	for _, name in ipairs(Uhhhhhh.REQUIRED) do
		local X = {}
		for k, v in pairs(FULL) do
			X[k] = v
		end
		X[name] = nil
		local ok, why = Uhhhhhh.available(X)
		T.eq(ok, false, name .. " is required")
		T.eq(why, "your executor has no " .. name .. ", which Uhhhhhh needs")
	end
	T.eq(Uhhhhhh.available(nil), false)
end

local function fakeFork(ctx, over)
	local fork = { starts = 0, stops = 0, limit = nil, running = false, loads = 0, visible = true, setMethod = 0 }
	over = over or {}
	local home = over.home or ctx.G
	ctx.loadstring = function()
		return function()
			fork.loads = fork.loads + 1
			home.UhhhhhhLoaded = true
			fork.sawHeadless = ctx.genv.UhhhhhhHeadless
			if over.during then
				over.during(fork)
			end
			if over.loadError then
				error(over.loadError, 0)
			end
			task.delay(over.loadTime or 1, function()
				fork.loaded = true
			end)
			home.UhhhhhhAPI = {
				Version = 1,
				Limb = {},
				IsLoaded = function()
					return fork.loaded == true
				end,
				SetMethod = function()
					fork.setMethod = fork.setMethod + 1
					return true
				end,
				SetUIVisible = function(v)
					fork.visible = v
				end,
				State = function()
					return fork.running and "running" or (fork.stateOverride or "idle")
				end,
				IsRunning = function()
					return fork.running
				end,
				Start = function(limit)
					fork.starts = fork.starts + 1
					fork.limit = limit
					fork.snapshot = {}
					for k, v in pairs(home.UhhhhhhAPI.Limb) do
						fork.snapshot[k] = v
					end
					if over.startFails then
						return false, over.startFails
					end
					fork.running = true
					return true
				end,
				Stop = function(limit)
					fork.stops = fork.stops + 1
					fork.stopLimit = limit
					if over.stopFails then
						return false, "stop timed out"
					end
					fork.running = false
					return true
				end,
				PlayDance = function(name)
					fork.dance = name
					return true
				end,
				StopDance = function()
					fork.dance = nil
					return true
				end,
				ListDances = function()
					return { { Name = "Wave" } }
				end,
			}
		end
	end
	return fork
end

T.section("prov_limb: Uhhhhhh loads once, headless, and starts through its API")
do
	local ctx = newCtx()
	local fork = fakeFork(ctx)
	Uhhhhhh.init(ctx)
	toasts = {}
	T.eq(Uhhhhhh.isRunning(), false)
	local ok = Uhhhhhh.start(run({ Mode = 3, Velocity = 2, InitMode = 1, ReplicateFPS10 = true, FlingEnabled = false, UseNaNFling = true, UseToolKill = true, UseCustomKill = true }))
	T.eq(ok, true)
	T.eq(fork.loads, 1)
	T.eq(fork.sawHeadless, true, "UhhhhhhHeadless is set before the file runs")
	T.eq(fork.setMethod, 1, "the Limb reanimator is selected in memory")
	T.eq(fork.visible, false, "the window is hidden")
	T.eq(fork.starts, 1)
	T.eq(fork.limit, 40)
	T.eq(fork.snapshot.Mode, 3)
	T.eq(fork.snapshot.Velocity, 2)
	T.eq(fork.snapshot.InitMode, 1)
	T.eq(fork.snapshot.ReplicateFPS10, true)
	T.eq(fork.snapshot.FlingEnabled, false)
	T.eq(fork.snapshot.UseNaNFling, true)
	T.eq(fork.snapshot.UseToolKill, true)
	T.eq(fork.snapshot.UseCustomKill, true)
	T.eq(#toasts, 1, "one loading toast the first time")
	T.eq(Uhhhhhh.isRunning(), true)
	local again, why = Uhhhhhh.start(run({}))
	T.eq(again, false)
	T.ok(string.find(why, "already running", 1, true))
	T.eq(Uhhhhhh.stop(), true)
	T.eq(fork.stops, 1)
	T.eq(fork.stopLimit, 10, "the fork is given ten seconds to stop")
	T.eq(Uhhhhhh.isRunning(), false)
	fork.running = true
	local _, ownWindow = Uhhhhhh.start(run({}))
	T.eq(ownWindow, "Uhhhhhh is already running from its own window", "after a stop the hub no longer claims the run")
	fork.running = false
	Uhhhhhh.reset()
	toasts = {}
	T.eq(Uhhhhhh.start(run({})), true, "a second start reuses the loaded fork")
	T.eq(fork.loads, 1, "the file loaded only once")
	T.eq(#toasts, 0, "and no loading toast the second time")
	T.eq(fork.snapshot.Mode, 0, "defaults apply when no option is given")
	T.eq(fork.snapshot.InitMode, 2)
	T.eq(fork.snapshot.FlingEnabled, true)
	Uhhhhhh.stop()
	Uhhhhhh.reset()
	T.eq(Uhhhhhh.stop(), true, "stopping when idle is harmless")
	T.eq(fork.stops, 2, "and does not call the fork's Stop again")
	T.eq(Uhhhhhh.keep.UhhhhhhLoaded, true, "the fork stays loaded by design")
	T.same(Uhhhhhh.listDances(), { { Name = "Wave" } })
	Uhhhhhh.start(run({}))
	T.eq(Uhhhhhh.playDance("Wave"), true)
	T.eq(fork.dance, "Wave")
	T.eq(Uhhhhhh.stopDance(), true)
	Uhhhhhh.stop()
	Uhhhhhh.reset()
end

T.section("prov_limb: Uhhhhhh failures")
do
	local ctx = newCtx()
	local fork = fakeFork(ctx, { loadError = "attempt to call a nil value\nmore" })
	Uhhhhhh.init(ctx)
	local ok, why = Uhhhhhh.start(run({}))
	T.eq(ok, false)
	T.eq(why, "attempt to call a nil value")
	Uhhhhhh.reset()

	local ctx2 = newCtx()
	fakeFork(ctx2, { loadTime = 500 })
	Uhhhhhh.init(ctx2)
	local t0 = time()
	ok, why = Uhhhhhh.start(run({}))
	T.eq(ok, false)
	T.eq(why, "it did not finish loading in time")
	T.ok(time() - t0 < 100, "the wait is bounded")
	Uhhhhhh.reset()

	local ctx3 = newCtx()
	fakeFork(ctx3, { startFails = "start timed out" })
	Uhhhhhh.init(ctx3)
	ok, why = Uhhhhhh.start(run({}))
	T.eq(ok, false)
	T.eq(why, "start timed out")
	Uhhhhhh.reset()

	local ctx4 = newCtx()
	fakeFork(ctx4, { stopFails = true })
	Uhhhhhh.init(ctx4)
	T.eq(Uhhhhhh.start(run({})), true)
	toasts = {}
	local stopped, stopWhy = Uhhhhhh.stop()
	T.eq(stopped, false, "a stop that times out is reported")
	T.eq(stopWhy, "stop timed out")
	T.eq(toasts[#toasts], "Uhhhhhh|Couldn't stop it: stop timed out|error")
	T.eq(Uhhhhhh.isRunning(), true, "and IsRunning stays truthful")

	local ctx5 = newCtx()
	ctx5.G.UhhhhhhLoaded = true
	Uhhhhhh.init(ctx5)
	ok, why = Uhhhhhh.start(run({}))
	T.eq(ok, false)
	T.ok(string.find(why, "already open from another script", 1, true), "a copy loaded by another script is detected")

	local ctx6 = newCtx()
	ctx6.loadFile = function()
		return nil, "couldn't find Reanimation/Limb/Uhhhhhh.lua"
	end
	Uhhhhhh.init(ctx6)
	ok, why = Uhhhhhh.start(run({}))
	T.eq(why, "couldn't find Reanimation/Limb/Uhhhhhh.lua")
end

T.section("prov_limb: Uhhhhhh when _G and getgenv() are two different tables")
do
	local home = {}
	local ctx = newCtx({ RG = home })
	T.ok(ctx.G ~= ctx.RG, "the two tables really differ")
	local fork = fakeFork(ctx, { home = home })
	Uhhhhhh.init(ctx)
	T.eq(Uhhhhhh.isRunning(), false)
	local ok, why = Uhhhhhh.start(run({}))
	T.eq(ok, true, "the fork writes its API into _G and the hub still finds it: " .. tostring(why))
	T.eq(fork.loads, 1)
	T.eq(fork.starts, 1)
	T.eq(Uhhhhhh.isRunning(), true)
	T.eq(rawget(ctx.G, "UhhhhhhAPI"), nil, "nothing was written to getgenv()")
	T.eq(Uhhhhhh.stop(), true)
	T.eq(fork.stops, 1)
	T.eq(Uhhhhhh.isRunning(), false)
	Uhhhhhh.reset()

	local ctx2 = newCtx({ RG = {} })
	ctx2.RG.UhhhhhhLoaded = true
	Uhhhhhh.init(ctx2)
	local ok2, why2 = Uhhhhhh.start(run({}))
	T.eq(ok2, false)
	T.ok(string.find(why2, "already open from another script", 1, true), "a copy another script left in _G is detected too")
	Uhhhhhh.reset()

	local ctx3 = newCtx({ RG = {} })
	local fork3 = fakeFork(ctx3, { home = ctx3.G })
	Uhhhhhh.init(ctx3)
	T.eq(Uhhhhhh.start(run({})), true, "a fork that writes to getgenv() is still found")
	T.eq(fork3.starts, 1)
	Uhhhhhh.stop()
	Uhhhhhh.reset()
end

T.section("prov_limb: Atsuko prepare, start and stop")
do
	local rigs = {}
	local live = false
	local readyAt = nil
	local lib = {
		version = 10,
		isReanimated = function()
			return live
		end,
		stopreanimate = function()
			live = false
		end,
		reanimate = function(cfg)
			live = true
			readyAt = time() + 1
			lib.lastCfg = cfg
			return { isReady = function() return time() >= readyAt end }
		end,
		rig = function(cfg)
			local r = { cfg = cfg, marker = "rig" }
			rigs[#rigs + 1] = r
			return r
		end,
		driver = function()
			return { name = "driver" }
		end,
		commands = { { id = "fly" } },
	}
	local ctx = newCtx()
	ctx.genv.LumenReanim = lib
	ctx.loadLib = function(name, key, need)
		return lib
	end
	Atsuko.init(ctx)
	T.eq(Atsuko.available({ loadstring = true }), true)
	T.eq(Atsuko.available({}), false)
	ctx.G.GenesisFDless = "previous"
	local ok = Atsuko.prepare({ name = "Last Star" }, run({ placeholders = false, ghostTransparency = 0.9 }))
	T.eq(ok, true)
	T.eq(ctx.G.GenesisFDless.marker, "rig", "the rig is preseeded for the script")
	T.eq(ctx.G.GenesisFDless.cfg.placeholders, false)
	T.eq(ctx.G.GenesisFDless.cfg.ghostTransparency, 0.9)
	T.eq(ctx.G.GenesisFDless.cfg.ctrltp, true, "unset options use the defaults")
	Atsuko.reset()
	T.eq(ctx.G.GenesisFDless, "previous", "the previous value comes back")
	ctx.G.GenesisFDless = nil
	ctx.genv.AtsukoHatFd = "left over"
	ok = Atsuko.prepare({ name = "Dubstep Gun", native = true }, run({}))
	T.eq(ok, true)
	T.eq(ctx.G.GenesisFDless.marker, "rig", "the hub's own scripts get the rig in the guard too, they just don't use it")
	T.eq(ctx.genv.AtsukoHatFd, nil, "and AtsukoHatFd is empty, so they take Script Reanimate")
	Atsuko.reset()
	T.eq(ctx.G.GenesisFDless, nil)

	T.eq(Atsuko.isRunning(), false)
	local t0 = time()
	ok = Atsuko.start(run({}))
	T.eq(ok, true)
	T.ok(time() - t0 >= 1, "start waited for ready")
	T.eq(Atsuko.isRunning(), true)
	T.eq(Atsuko.driver().name, "driver")
	T.eq(Atsuko.commands()[1].id, "fly")
	T.eq(Atsuko.stop(), true)
	T.eq(Atsuko.isRunning(), false)
	T.eq(Atsuko.stop(), true)

	lib.isReanimated = function()
		return live
	end
	lib.reanimate = function()
		live = true
		return { isReady = function() return false end }
	end
	ok = Atsuko.start(run({}))
	T.eq(ok, false, "never ready gives a clear failure")
	Atsuko.stop()

	lib.reanimate = function()
		error("no character\nmore", 0)
	end
	local _, why = Atsuko.start(run({}))
	T.eq(why, "no character")
	ctx.loadLib = function()
		return nil, "couldn't download Reanimate"
	end
	ctx.genv.LumenReanim = nil
	ok, why = Atsuko.prepare({ name = "x" }, run({}))
	T.eq(ok, false)
	T.eq(why, "couldn't download Reanimate")
	T.eq(Atsuko.isRunning(), false)
	T.eq(Atsuko.driver(), nil)
	T.eq(Atsuko.commands(), nil)
end

T.section("prov_limb: Gelatek leaves somebody else's Settings alone when it never prepared anything")
do
	local ctx = newCtx()
	ctx.genv.Settings = "mine"
	ctx.world.accessories = {}
	Gelatek.reset()
	Gelatek.init(ctx)
	local ok = Gelatek.start(run({ Reanimation = "Bullet" }))
	T.eq(ok, false)
	Gelatek.reset()
	T.eq(ctx.genv.Settings, "mine", "an early refusal changes nothing")
	ctx.world.accessories = { ["Pal Hair"] = true }
	ctx.loadFile = function()
		return "tiny"
	end
	local _, why = Gelatek.start(run({}))
	T.eq(why, "couldn't read the Gelatek file", "a file that is too short is not accepted")
	Gelatek.reset()
	T.eq(ctx.genv.Settings, "mine")
	T.eq(#ctx.world.calls, 0)
end

T.section("prov_limb: forgetting only drops what the provider remembers")
do
	local ctx = newCtx()
	ctx.genv.Settings = "mine"
	ctx.loadstring = function()
		return function()
			ctx.genv.Reanimated = true
		end
	end
	Gelatek.reset()
	Gelatek.init(ctx)
	T.eq(Gelatek.start(run({})), true)
	Gelatek.stop()
	Gelatek.forget()
	T.eq(ctx.genv.Settings, "mine")
	T.eq(ctx.genv.Reanimated, nil)
	local before = #ctx.world.calls
	Gelatek.forget()
	T.eq(#ctx.world.calls, before, "forgetting twice does nothing more")

	local ctx2 = newCtx()
	local fork = fakeFork(ctx2)
	Uhhhhhh.reset()
	Uhhhhhh.init(ctx2)
	T.eq(Uhhhhhh.start(run({})), true)
	local stops = fork.stops
	Uhhhhhh.forget()
	T.eq(fork.stops, stops, "forget does not call the fork's Stop")
	Uhhhhhh.stop()
	Uhhhhhh.reset()

	local ctx3 = newCtx()
	ctx3.G.GenesisFDless = "previous"
	local lib = {
		version = 10,
		isReanimated = function()
			return false
		end,
		stopreanimate = function() end,
		rig = function()
			return { marker = "rig" }
		end,
	}
	ctx3.genv.LumenReanim = lib
	Atsuko.init(ctx3)
	T.eq(Atsuko.prepare({ name = "x" }, run({})), true)
	T.eq(ctx3.G.GenesisFDless.marker, "rig")
	Atsuko.forget()
	T.eq(ctx3.G.GenesisFDless, "previous", "forget restores the global")
	Atsuko.forget()
	T.eq(ctx3.G.GenesisFDless, "previous", "and a second forget leaves it alone")
end

T.section("prov_limb: Uhhhhhh while it is still loading")
do
	local ctx = newCtx()
	local inner = nil
	fakeFork(ctx, {
		during = function()
			inner = { Uhhhhhh.ensureLoaded(run({})) }
		end,
	})
	Uhhhhhh.reset()
	Uhhhhhh.init(ctx)
	T.eq(Uhhhhhh.start(run({})), true)
	T.eq(inner[1], nil, "a second request while loading does not load again")
	T.eq(inner[2], "Uhhhhhh is still loading")
	Uhhhhhh.stop()
	Uhhhhhh.reset()

	local ctx2 = newCtx()
	ctx2.loadFile = function()
		return "tiny"
	end
	Uhhhhhh.init(ctx2)
	local api, why = Uhhhhhh.ensureLoaded(run({}))
	T.eq(api, nil)
	T.eq(why, "couldn't read the Uhhhhhh file")

	local ctx3 = newCtx()
	ctx3.loadstring = function()
		return nil, "syntax problem\nmore"
	end
	Uhhhhhh.init(ctx3)
	api, why = Uhhhhhh.ensureLoaded(run({}))
	T.eq(why, "syntax problem")
end

T.section("prov_limb: Uhhhhhh gives up at once on a load error and says where it was started from")
do
	local ctx = newCtx()
	fakeFork(ctx, { loadError = "boom" })
	Uhhhhhh.reset()
	Uhhhhhh.init(ctx)
	local t0 = time()
	local ok, why = Uhhhhhh.start(run({}))
	T.eq(ok, false)
	T.eq(why, "boom")
	T.ok(time() - t0 < 5, "a load error does not wait out the full limit")
	Uhhhhhh.reset()

	local ctx2 = newCtx()
	local fork = fakeFork(ctx2)
	Uhhhhhh.init(ctx2)
	T.eq(Uhhhhhh.ensureLoaded(run({})) ~= nil, true)
	fork.running = true
	ok, why = Uhhhhhh.start(run({}))
	T.eq(ok, false)
	T.eq(why, "Uhhhhhh is already running from its own window")
	fork.running = false
	T.eq(Uhhhhhh.start(run({})), true)
	ok, why = Uhhhhhh.start(run({}))
	T.eq(why, "Uhhhhhh is already running", "started by the hub, so no mention of a window")
	Uhhhhhh.stop()
	Uhhhhhh.reset()
end

T.section("prov_limb: Uhhhhhh stops a fork that is busy even when IsRunning is false")
do
	local ctx = newCtx()
	local fork = fakeFork(ctx)
	Uhhhhhh.reset()
	Uhhhhhh.init(ctx)
	T.eq(Uhhhhhh.start(run({})), true)
	fork.running = false
	fork.stateOverride = "starting"
	local stops = fork.stops
	T.eq(Uhhhhhh.stop(), true)
	T.eq(fork.stops, stops + 1, "a fork that is still starting gets its Stop")
	fork.stateOverride = nil
	Uhhhhhh.reset()
end

T.section("prov_limb: Atsuko takes the library only at the right version")
do
	local oldLib = { version = 9, isReanimated = function() return false end, rig = function() return { marker = "old" } end }
	local newLib = { version = 10, isReanimated = function() return false end, rig = function() return { marker = "new" } end }
	local ctx = newCtx()
	ctx.genv.LumenReanim = oldLib
	local args = nil
	ctx.loadLib = function(name, key, need)
		args = name .. "|" .. key .. "|" .. tostring(need)
		return newLib
	end
	Atsuko.init(ctx)
	local lib = Atsuko.lib()
	T.eq(lib, newLib, "an older copy is too old, so the real one is loaded")
	T.eq(args, "Reanimate|LumenReanim|10")
	args = nil
	ctx.genv.LumenReanim = newLib
	T.eq(Atsuko.lib(), newLib)
	T.eq(args, nil, "a current library is not loaded again")
	ctx.genv.LumenReanim = { isReanimated = function() return false end }
	T.eq(Atsuko.lib() ~= nil, true)
	T.eq(args, "Reanimate|LumenReanim|10", "a library with no version is not trusted")
	ctx.genv.LumenReanim = nil
	ctx.loadLib = function()
		return nil
	end
	local none, why = Atsuko.lib()
	T.eq(none, nil)
	T.eq(why, "couldn't load Script Reanimate")
end

T.section("prov_limb: Atsuko when the rig cannot be built or the reanimate is stale")
do
	local live = true
	local stopped = 0
	local lib = {
		version = 10,
		isReanimated = function()
			return live
		end,
		stopreanimate = function()
			stopped = stopped + 1
			live = false
		end,
		rig = function()
			error("rig broke\nmore", 0)
		end,
		reanimate = function()
			live = true
			return { isReady = function() return true end }
		end,
	}
	local ctx = newCtx()
	ctx.genv.LumenReanim = lib
	ctx.G.GenesisFDless = "previous"
	Atsuko.init(ctx)
	local ok, why = Atsuko.prepare({ name = "x" }, run({}))
	T.eq(ok, false)
	T.eq(why, "rig broke")
	T.eq(ctx.G.GenesisFDless, "previous", "a failed rig leaves the global as it was")
	ctx.G.GenesisFDless = "changed later"
	Atsuko.reset()
	T.eq(ctx.G.GenesisFDless, "changed later", "a failed prepare claimed nothing, so reset leaves the global alone")
	ctx.G.GenesisFDless = "previous"
	T.eq(Atsuko.start(run({})), true)
	T.eq(stopped, 1, "a stale reanimate is stopped before the new one starts")
	Atsuko.stop()

	lib.reanimate = function()
		live = true
		return { isReady = function() return false end }
	end
	lib.isReanimated = function()
		return live
	end
	local calls = 0
	local liveObj = { isReady = function()
		calls = calls + 1
		if calls == 3 then
			live = false
		end
		return false
	end }
	lib.reanimate = function()
		live = true
		return liveObj
	end
	ok, why = Atsuko.start(run({}))
	T.eq(ok, false)
	T.eq(why, "it stopped while getting ready")
	lib.reanimate = function()
		return nil
	end
	ok, why = Atsuko.start(run({}))
	T.eq(why, "Script Reanimate could not start")
end

T.section("prov_limb: a hub-native script gets the rig and the library is ensured")
do
	local loads = 0
	local lib = { version = 10, isReanimated = function() return false end, rig = function() return { marker = "rig" } end }
	local ctx = newCtx()
	ctx.loadLib = function()
		loads = loads + 1
		return lib
	end
	Atsuko.init(ctx)
	T.eq(Atsuko.prepare({ native = true }, run({})), true)
	T.eq(loads, 1, "the library is made ready for the script")
	T.eq(ctx.G.GenesisFDless.marker, "rig")
	Atsuko.reset()
	ctx.loadLib = function()
		return nil, "no network"
	end
	local ok, why = Atsuko.prepare({ native = true }, run({}))
	T.eq(ok, false)
	T.eq(why, "no network")
end

T.section("prov_limb: Gelatek timing, teardown details and error text")
do
	local ctx = newCtx()
	local disconnects = 0
	ctx.loadstring = function()
		return function()
			ctx.genv.Reanimated = true
			ctx.genv.__GelatekCleanup = {
				conns = { { Disconnect = function() disconnects = disconnects + 1 end } },
				objs = {},
			}
		end
	end
	Gelatek.reset()
	Gelatek.init(ctx)
	local t0 = time()
	T.eq(Gelatek.start(run({ Reanimation = "Bullet" })), true, "Bullet starts when the accessory is there")
	T.ok(time() - t0 < 2, "a start that works returns at once, not after the limit")
	T.eq(Gelatek.stop(), true)
	T.eq(Gelatek.stop(), true)
	T.eq(disconnects, 1, "a connection is disconnected once even if stop runs twice")
	Gelatek.reset()

	local ctx2 = newCtx()
	ctx2.loadstring = function()
		return function()
			error("quick failure", 0)
		end
	end
	Gelatek.init(ctx2)
	t0 = time()
	local ok, why = Gelatek.start(run({}))
	T.eq(why, "quick failure")
	T.ok(time() - t0 < 2, "a script error is reported at once")
	Gelatek.reset()

	local ctx3 = newCtx()
	ctx3.loadstring = function()
		return function() end
	end
	Gelatek.init(ctx3)
	t0 = time()
	ok, why = Gelatek.start(run({}))
	T.ok(time() - t0 >= 14, "it really waits for the limit before giving up")
	Gelatek.reset()

	local ctx4 = newCtx()
	ctx4.loadstring = function()
		return nil
	end
	Gelatek.init(ctx4)
	ok, why = Gelatek.start(run({}))
	T.eq(why, "Gelatek would not compile")

	local ctx5 = newCtx()
	ctx5.loadstring = function()
		return function()
			ctx5.genv.Reanimated = true
		end
	end
	Gelatek.init(ctx5)
	T.eq(Gelatek.start(run({})), true)
	ctx5.world.respawn = function()
		error("cannot respawn\nmore", 0)
	end
	local stopped, stopWhy = Gelatek.stop()
	T.eq(stopped, false, "a respawn that fails is reported")
	T.eq(stopWhy, "cannot respawn")
	Gelatek.reset()
end

T.section("prov_limb: with nothing saved every shipped provider uses its defaults")
do
	local Fdless = loadmodule("Reanimation/providers/fdless.lua")
	local reg = Registry.new({ S = {}, X = FULL, settle = 0 })
	local all = { Atsuko, Fdless, Gelatek, Uhhhhhh }
	T.eq(#Registry.validate(Fdless), 0, table.concat(Registry.validate(Fdless), ";"))
	T.ok(Fdless.blurb == nil or (type(Fdless.blurb) == "string" and #Fdless.blurb > 10), "fdless has no blurb or a real one")
	for _, P in ipairs(all) do
		T.eq(reg:register(P), true, P.id .. " registers")
	end
	local checked = 0
	for _, P in ipairs(all) do
		local got = reg:optionsOf(P.id)
		for _, def in ipairs(P.settings) do
			T.eq(got[def.key], def.default, P.id .. "." .. def.key .. " starts at its default")
			checked = checked + 1
		end
	end
	T.eq(checked, 5 + 15 + 6 + 8, "every option of every provider was looked at")
	T.eq(reg:optionsOf("fdless").fling, true, "fling is on out of the box")
	T.eq(reg:optionsOf("fdless").flingtargetting, 3)
	local ok, clean = reg:setOption("fdless", "fling", false)
	T.eq(ok, true)
	T.eq(clean, false)
	T.eq(reg:optionsOf("fdless").fling, false)
	T.eq(reg:optionsOf("fdless").clickfling, false, "other options are untouched")
end
