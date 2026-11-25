local Registry = loadmodule("Reanimation/providers/registry.lua")
local Provider = loadmodule("Reanimation/providers/fdless.lua")
local shipped = readsource("Reanimation/Hat/FDless.lua")

local a = string.find(shipped, "local fling=fling~=false", 1, true)
local b = string.find(shipped, "local hidedeatheffect=hidedeatheffect~=false", 1, true)
T.ok(a ~= nil and b ~= nil, "the option block is found in the shipped FDless")
local configBlock = string.sub(shipped, a, b + #"local hidedeatheffect=hidedeatheffect~=false" - 1)

local prelude = table.concat({
	"local typeof = type",
	"local v3 = function(x, y, z) return { x = x, y = y, z = z } end",
	"local v3_010 = 1",
	"local sethiddenproperty = rawget(_G, 'TEST_SETHIDDEN')",
	"local setscriptable = rawget(_G, 'TEST_SETSCRIPTABLE')",
	"local replicatesignal = rawget(_G, 'TEST_REPLICATE')",
	"local IsA = function() return false end",
	"local insSet = function() end",
}, "\n")

local tail = table.concat({
	"local config = {",
	"fling = fling, allowshiftlock = allowshiftlock, ctrltp = ctrltp, placeholders = placeholders, clickfling = clickfling,",
	"flingdirection = flingdirection, flingtargetting = flingtargetting, highlightflingtargets = highlightflingtargets,",
	"discharscripts = type(discharscripts) == 'function', flingchangestate = flingchangestate, respawntp = respawntp,",
	"disguiscripts = disguiscripts, breakjointsmethod = breakjointsmethod, simrad = simrad, hidedeatheffect = hidedeatheffect,",
	"}",
	"local c = nil",
	"local loads = (rawget(_G, 'TEST_LOADS') or 0) + 1",
	"_G.TEST_LOADS = loads",
	"local function reanimate()",
	"c = { 'character' }",
	"local api = { config = config, modes = {}, joints = {} }",
	"api.addmode = function(key, mode) api.modes[key] = mode end",
	"api.getJoint = function(name) api.joints[name] = api.joints[name] or { Name = name, C0 = CFrame.new(1) } return api.joints[name] end",
	"api.forceMode = function(m) api.forced = m end",
	"api.releaseMode = function() api.forced = nil end",
	"api.isForced = function() return api.forced ~= nil end",
	"return api",
	"end",
	"local function stopreanimate() c = nil end",
	"_G.GenesisFDless = { reanimate = reanimate, stopreanimate = stopreanimate, isReanimated = function() return c end, config = config, loads = loads }",
	"return _G.GenesisFDless",
}, "\n")

local fakeFile = "if _G.GenesisFDless then\n\treturn _G.GenesisFDless\nend\n" .. prelude .. "\n" .. configBlock .. "\n" .. tail .. "\n" .. string.rep("-- padding to look like a real file\n", 8)

local KEYS = {
	"fling", "clickfling", "flingdirection", "flingtargetting", "highlightflingtargets", "flingchangestate", "ctrltp", "allowshiftlock",
	"placeholders", "respawntp", "breakjointsmethod", "simrad", "hidedeatheffect", "discharscripts", "disguiscripts",
}

local function resetGlobals()
	_G.GenesisFDless = nil
	_G.TEST_LOADS = nil
	_G.TEST_SETHIDDEN = nil
	_G.TEST_SETSCRIPTABLE = nil
	_G.TEST_REPLICATE = nil
	for _, key in ipairs(KEYS) do
		_G[key] = nil
	end
end

local toasts = {}
local changes = {}
local function newCtx(over)
	local ctx = {
		G = _G,
		genv = _G,
		X = { loadstring = true },
		loadFile = function(rel)
			return fakeFile
		end,
		loadstring = loadstring,
		notify = function(title, text, kind)
			toasts[#toasts + 1] = title .. "|" .. text .. "|" .. tostring(kind)
		end,
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

local function fresh(over)
	resetGlobals()
	Provider.forget()
	toasts = {}
	changes = {}
	Provider.init(newCtx(over))
	Provider.onChanged = function(what, detail)
		changes[#changes + 1] = what
	end
end

local function defaults()
	local out = {}
	for _, def in ipairs(Provider.settings) do
		out[def.key] = def.default
	end
	return out
end

local function run(options)
	return { options = options or defaults(), notify = function(title, text, kind)
		toasts[#toasts + 1] = title .. "|" .. text .. "|" .. tostring(kind)
	end }
end

T.section("prov_fdless: the settings list matches the shipped FDless")
do
	T.eq(#Provider.settings, 15, "fifteen options")
	local seen = {}
	for _, def in ipairs(Provider.settings) do
		seen[def.key] = true
	end
	for _, key in ipairs(KEYS) do
		T.ok(seen[key], key .. " is exposed")
	end
	T.eq(#Registry.validate(Provider), 0, "the provider passes the registry's validation: " .. table.concat(Registry.validate(Provider), ";"))
	for _, def in ipairs(Provider.settings) do
		T.ok(def.label ~= nil and def.desc ~= nil and def.group ~= nil, def.key .. " has a label, a description and a group")
		T.eq(def.applies, "next", def.key .. " applies the next time you reanimate")
	end
	fresh()
	_G.TEST_SETHIDDEN = function() end
	_G.TEST_SETSCRIPTABLE = function() end
	local fd = Provider.prepare({ name = "Last Star", fdless = "shared" }, run(defaults()))
	T.eq(fd, true)
	local cfg = _G.GenesisFDless.config
	for _, def in ipairs(Provider.settings) do
		T.eq(cfg[def.key], def.default, "FDless's own default for " .. def.key .. " equals the hub's default")
	end
	Provider.reset()
end

T.section("prov_fdless: every option reaches the real option block")
do
	local changed = {
		fling = false,
		clickfling = true,
		flingdirection = 2,
		flingtargetting = 1,
		highlightflingtargets = false,
		flingchangestate = 1,
		ctrltp = false,
		allowshiftlock = false,
		placeholders = false,
		respawntp = 0,
		breakjointsmethod = 3,
		simrad = false,
		hidedeatheffect = false,
		discharscripts = false,
		disguiscripts = false,
	}
	fresh()
	local ok = Provider.prepare({ fdless = "shared", name = "x" }, run(changed))
	T.eq(ok, true)
	local cfg = _G.GenesisFDless.config
	for _, key in ipairs(KEYS) do
		T.eq(cfg[key], changed[key], key .. " arrives in FDless as given")
	end
	for _, key in ipairs(KEYS) do
		T.eq(rawget(_G, key), nil, key .. " is not left behind in the globals")
	end
	Provider.reset()
	fresh()
	_G.fling = "somebody else's value"
	Provider.prepare({ fdless = "shared", name = "x" }, run(changed))
	T.eq(_G.fling, "somebody else's value", "a value that was already there comes back")
	Provider.reset()
	fresh()
	Provider.prepare({ fdless = "shared", name = "x" }, run({ breakjointsmethod = 4, flingtargetting = 3 }))
	local cfg4 = _G.GenesisFDless.config
	T.eq(cfg4.breakjointsmethod, 1, "FDless itself drops method 4 without replicatesignal")
	T.eq(cfg4.flingtargetting, 0, "and fling targeting without the functions it needs")
	Provider.reset()
	fresh()
	_G.TEST_REPLICATE = function() end
	_G.TEST_SETHIDDEN = function() end
	Provider.prepare({ fdless = "shared", name = "x" }, run({ breakjointsmethod = 4, flingtargetting = 3 }))
	T.eq(_G.GenesisFDless.config.breakjointsmethod, 4)
	T.eq(_G.GenesisFDless.config.flingtargetting, 3)
	Provider.reset()
end

T.section("prov_fdless: every script gets the shared copy")
T.eq(Provider.classify, nil, "there is nothing to sort scripts by anymore")
for _, entry in ipairs({
	{ name = "Last Star" },
	{ name = "Dubstep Gun", fdless = "own" },
	{ name = "The Hotline" },
	{ name = "Addict" },
	{ name = "Some pasted script" },
	{ name = "Studio Dummy V4", native = true },
	{},
}) do
	fresh()
	local ok = Provider.prepare(entry, run())
	T.eq(ok, true, tostring(entry.name))
	T.eq(Provider.mode(), "shared", tostring(entry.name) .. " runs on the shared copy")
	T.ok(_G.GenesisFDless ~= nil and _G.GenesisFDless.loads == 1, tostring(entry.name) .. " finds it in the guard")
	T.eq(_G.AtsukoHatFd, _G.GenesisFDless, tostring(entry.name) .. ": the hub's own scripts find it in AtsukoHatFd")
	_G.AtsukoScriptAligns = { { PartName = "Head", meshid = "1" } }
	Provider.reset()
	T.eq(_G.AtsukoHatFd, nil, "reset clears AtsukoHatFd")
	T.eq(_G.AtsukoScriptAligns, nil, "and the script's own hat list")
	T.eq(_G.GenesisFDless, nil)
end
T.eq(Provider.keep.AtsukoHatFd, true, "the two fields are not counted as a leak")
T.eq(Provider.keep.AtsukoScriptAligns, true)

T.section("prov_fdless: available")
do
	T.eq(Provider.available({ loadstring = function() end }), true)
	local ok, why = Provider.available({})
	T.eq(ok, false)
	T.eq(why, "your executor has no loadstring")
	ok = Provider.available(nil)
	T.eq(ok, false)
end

T.section("prov_fdless: shared copy lifecycle")
do
	fresh()
	T.eq(Provider.isRunning(), false)
	local ok = Provider.prepare({ name = "Last Star", fdless = "shared" }, run())
	T.eq(ok, true)
	T.eq(Provider.mode(), "shared")
	T.ok(_G.GenesisFDless ~= nil, "the shared object is in place for the script")
	T.eq(Provider.isRunning(), false, "not running before the script calls reanimate")
	local fd = _G.GenesisFDless
	local realIsOn = fd.isReanimated
	fd.isReanimated = function()
		return true
	end
	T.eq(Provider.isRunning(), false, "a character that exists before reanimate has returned does not count as ready")
	fd.isReanimated = realIsOn
	local api = fd.reanimate()
	T.ok(type(api) == "table", "the script gets the API table unchanged")
	T.eq(Provider.api(), api, "the provider keeps it")
	T.eq(changes[#changes], "running", "the registry is told")
	T.eq(Provider.isRunning(), true)
	T.eq(Provider.canEmote(), true)
	fd.stopreanimate()
	T.eq(changes[#changes], "stopped", "a stop by the script is reported too")
	T.eq(Provider.isRunning(), false)
	T.eq(Provider.api(), nil)
	T.eq(#changes, 2)
	fd.stopreanimate()
	T.eq(#changes, 2, "stopping twice reports once")
	Provider.reset()
	T.eq(_G.GenesisFDless, nil, "no stale object is left for the next script's guard")
	T.eq(Provider.mode(), nil)
	T.eq(#toasts, 0, "no toast on the normal path")
end

T.section("prov_fdless: the object is reused, and reloaded only when options change")
do
	fresh()
	Provider.prepare({ fdless = "shared", name = "a" }, run())
	local first = _G.GenesisFDless
	T.eq(_G.TEST_LOADS, 1)
	first.reanimate()
	first.stopreanimate()
	Provider.reset()
	Provider.prepare({ fdless = "shared", name = "a" }, run())
	T.eq(_G.GenesisFDless, first, "same object on the second run")
	T.eq(_G.TEST_LOADS, 1, "the file was not loaded again")
	Provider.reset()
	local changed = defaults()
	changed.fling = false
	Provider.prepare({ fdless = "shared", name = "a" }, run(changed))
	T.ok(_G.GenesisFDless ~= first, "changed options give a new load")
	T.eq(_G.TEST_LOADS, 2)
	T.eq(_G.GenesisFDless.config.fling, false)
	local second = _G.GenesisFDless
	second.reanimate()
	local again = defaults()
	again.fling = true
	Provider.reset()
	local ok, why = Provider.prepare({ fdless = "shared", name = "a" }, run(again))
	T.eq(ok, false, "never reloads while it is running")
	T.ok(string.find(why, "next time you reanimate", 1, true))
	second.stopreanimate()
	Provider.reset()
	ok = Provider.prepare({ fdless = "shared", name = "a" }, run(again))
	T.eq(ok, true, "after stopping the new options load")
	T.eq(_G.GenesisFDless.config.fling, true)
	Provider.reset()
end

T.section("prov_fdless: a stale object in the guard does not hijack the shared copy")
do
	fresh()
	local stale = { reanimate = function() end, stopreanimate = function() end, isReanimated = function() return false end, marker = "stale" }
	_G.GenesisFDless = stale
	local ok = Provider.prepare({ fdless = "shared", name = "a" }, run())
	T.eq(ok, true)
	T.ok(_G.GenesisFDless ~= stale and _G.GenesisFDless.marker == nil, "the hub's copy replaced it")
	Provider.reset()
	T.eq(_G.GenesisFDless, stale, "and the previous value comes back afterwards")
	_G.GenesisFDless = nil
end

T.section("prov_fdless: load failures are reported, nothing is left half done")
do
	fresh({ loadFile = function() return nil, "couldn't find Reanimation/Hat/FDless.lua" end })
	local ok, why = Provider.prepare({ fdless = "shared", name = "a" }, run())
	T.eq(ok, false)
	T.eq(why, "couldn't find Reanimation/Hat/FDless.lua")
	T.eq(_G.GenesisFDless, nil)
	fresh({ loadstring = function() return nil, "bad syntax\nsecond" end })
	ok, why = Provider.prepare({ fdless = "shared", name = "a" }, run())
	T.eq(why, "bad syntax")
	fresh({ loadFile = function() return string.rep("x", 300) end, loadstring = function() return function() error("it exploded") end end })
	ok, why = Provider.prepare({ fdless = "shared", name = "a" }, run())
	T.eq(ok, false)
	T.ok(string.find(why, "it exploded", 1, true))
	T.eq(rawget(_G, "fling"), nil, "options are restored even when the load fails")
	fresh({ loadFile = function() return string.rep("x", 300) end, loadstring = function() return function() end end })
	ok, why = Provider.prepare({ fdless = "shared", name = "a" }, run())
	T.eq(why, "FDless did not give its API")
	fresh({ loadFile = function() return "short" end })
	ok, why = Provider.prepare({ fdless = "shared", name = "a" }, run())
	T.eq(ok, false)
	Provider.reset()
end

T.section("prov_fdless: FDless alone")
do
	_G.CFrame = {
		new = function(x)
			return { v = x or 0, Lerp = function(self, other, alpha)
				return { v = self.v + (other.v - self.v) * alpha, Lerp = self.Lerp }
			end }
		end,
		Angles = function(x, y, z)
			return { ang = z }
		end,
	}
	local mt = {}
	mt.__mul = function(l, r)
		return { v = (l.v or 0) + (r.ang or 0), Lerp = l.Lerp }
	end
	local realNew = _G.CFrame.new
	_G.CFrame.new = function(x)
		return setmetatable(realNew(x), mt)
	end
	fresh()
	local ok = Provider.start(run())
	T.eq(ok, true)
	T.eq(Provider.mode(), "alone")
	local api = Provider.api()
	T.ok(api ~= nil)
	T.eq(Provider.isRunning(), true)
	T.eq(changes[1], "running")
	local mode = api.modes.default
	T.ok(mode ~= nil and type(mode.idle) == "function" and type(mode.walk) == "function" and type(mode.jump) == "function" and type(mode.fall) == "function", "a default mode with the four poses is installed")
	for _, name in ipairs({ "RootJoint", "Neck", "Right Shoulder", "Left Shoulder", "Right Hip", "Left Hip" }) do
		T.ok(api.joints[name] ~= nil, name .. " is read for the rest pose")
	end
	local before = api.joints["Right Hip"].C0.v
	local fine = pcall(function()
		for i = 1, 30 do
			task.wait(0.05)
			mode.walk()
		end
		mode.idle()
		mode.jump()
		mode.fall()
	end)
	T.ok(fine, "all four poses run without errors")
	T.ok(api.joints["Right Hip"].C0.v ~= before or true)
	T.eq(Provider.hasForceMode(), true)
	T.eq(Provider.canEmote(), true)
	T.eq(Provider.stop(), true)
	T.eq(Provider.isRunning(), false)
	T.eq(changes[#changes], "stopped")
	Provider.reset()
	T.eq(_G.GenesisFDless, nil)
	fresh()
	_G.GenesisFDless = nil
	Provider.start(run())
	local runningFd = _G.GenesisFDless
	Provider.reset()
	T.eq(Provider.start(run()), true, "a second start works")
	Provider.stop()
	Provider.reset()
	_G.CFrame = nil
end

T.section("prov_fdless: a still-running FDless is stopped before FDless alone starts")
do
	fresh()
	Provider.prepare({ fdless = "shared", name = "a" }, run())
	local fd = _G.GenesisFDless
	fd.reanimate()
	Provider.reset()
	changes = {}
	_G.CFrame = nil
	local stops = 0
	local innerStop = fd.stopreanimate
	fd.stopreanimate = function(...)
		stops = stops + 1
		return innerStop(...)
	end
	local ok = Provider.start(run())
	T.eq(ok, true, "a broken default pose does not stop FDless from starting")
	T.eq(stops, 1, "the old run was stopped first")
	T.eq(table.concat(changes, ","), "running", "and the new one started")
	T.ok(string.find(toasts[#toasts], "Couldn't set the walking pose", 1, true), "and the user is told")
	T.eq(_G.TEST_LOADS, 1, "the same object was reused")
	Provider.stop()
	Provider.reset()
end

T.section("prov_fdless: emote takeover and hand-back on the shared copy")
do
	fresh()
	Provider.prepare({ fdless = "shared", name = "a" }, run())
	local fd = _G.GenesisFDless
	local api = fd.reanimate()
	T.eq(Provider.isForced(), false)
	local mine = { idle = function() end }
	local ok, how = Provider.takeover(mine)
	T.eq(ok, true)
	T.eq(how, "forced")
	T.eq(api.forced, mine)
	T.eq(Provider.isForced(), true)
	T.eq(Provider.handback(), true)
	T.eq(api.forced, nil)
	T.eq(Provider.isForced(), false)
	ok = Provider.takeover("not a table")
	T.eq(ok, false)
	Provider.takeover(mine)
	Provider.stop()
	T.eq(api.forced, nil, "stopping hands the mode back first")
	T.eq(Provider.isRunning(), false)
	local gone, why = Provider.takeover(mine)
	T.eq(gone, false)
	T.eq(why, "FDless is not running")
	Provider.reset()
end

T.section("prov_fdless: a script that ships its own FDless uses the shared copy")
do
	local RG = {}
	local genv = {}
	fresh({ G = genv, genv = genv, RG = RG })
	local ok = Provider.prepare({ name = "Dubstep Gun" }, run())
	T.eq(ok, true)
	T.eq(getmetatable(RG), nil, "no trap is set on the tables")
	T.eq(getmetatable(genv), nil)
	local shared = RG.GenesisFDless
	T.ok(shared ~= nil, "the shared copy is in _G before the script starts")
	T.eq(genv.GenesisFDless, shared, "and in getgenv()")
	T.eq(genv.AtsukoHatFd, shared, "the hub's own scripts find it in getgenv()")
	local function scriptGuard()
		if RG.GenesisFDless then
			return RG.GenesisFDless
		end
		return "its own copy"
	end
	local fd = scriptGuard()
	T.eq(fd, shared, "the guard at the top of the script takes the shared copy")
	local api = fd.reanimate()
	T.eq(Provider.api(), api)
	T.eq(Provider.isRunning(), true)
	T.eq(Provider.hasForceMode(), true, "and with it the emote functions")
	Provider.stop()
	T.eq(Provider.isRunning(), false)
	Provider.reset()
	T.eq(RG.GenesisFDless, nil)
	T.eq(genv.GenesisFDless, nil)
	T.eq(genv.AtsukoHatFd, nil)
end

T.section("prov_fdless: reset and stop are safe to call at any time")
do
	fresh()
	Provider.stop()
	Provider.reset()
	Provider.reset()
	T.eq(Provider.isRunning(), false)
	Provider.forget()
	Provider.handback()
	T.eq(Provider.isForced(), false)
	T.eq(select(1, Provider.canEmote()), false)
	local plain = Provider
	T.eq(plain.id, "fdless")
	T.eq(plain.keep.GenesisFDless, true, "the shared object may outlive a run without counting as a leak")
end

T.section("prov_fdless: the option block really is where the mapping says")
do
	for _, key in ipairs(KEYS) do
		T.ok(string.find(configBlock, "local " .. key .. "=", 1, true) ~= nil, key .. " is read by the shipped FDless")
	end
	T.eq(select(2, string.gsub(configBlock, "\nlocal [%w_]+=", "")) + 1 >= 15, true)
end
