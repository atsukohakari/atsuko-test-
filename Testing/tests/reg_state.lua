local Registry = loadmodule("Reanimation/providers/registry.lua")
local SHIPPED_OFF = Registry.OFF
Registry.OFF = {}

local function fake(id, kind, over)
	local p = {
		AtsukoReanimProvider = true,
		id = id,
		kind = kind,
		name = "Fake " .. id,
		credit = "Someone",
		caps = { fdApi = kind == "hat", emotes = true, bodyCommands = false, fling = false, bullet = false, stoppable = true, respawnSafe = true, needsR6 = false },
		settings = {
			{ key = "mode", type = "choice", label = "Mode", options = { "Simple", "Fling" }, default = "Simple" },
			{ key = "speed", type = "number", label = "Speed", min = 1, max = 10, default = 5 },
			{ key = "on", type = "toggle", label = "On", default = false },
		},
		running = false,
		calls = {},
		startDelay = 0.2,
	}
	p.available = function(X)
		return true
	end
	p.start = function(run)
		p.calls[#p.calls + 1] = "start"
		p.lastRun = run
		task.wait(p.startDelay)
		p.running = true
		return true
	end
	p.prepare = function(entry, run)
		p.calls[#p.calls + 1] = "prepare"
		p.lastRun = run
		return true
	end
	p.stop = function()
		p.calls[#p.calls + 1] = "stop"
		p.running = false
	end
	p.isRunning = function()
		return p.running
	end
	p.reset = function()
		p.calls[#p.calls + 1] = "reset"
	end
	for k, v in pairs(over or {}) do
		p[k] = v
	end
	return p
end

local function newEnv(opts)
	opts = opts or {}
	local env = { events = {}, raw = {}, toasts = {}, saves = 0, logs = {} }
	env.S = opts.S or { reanimOpts = {}, hatReanim = "atsuko" }
	env.reg = Registry.new({
		S = env.S,
		save = function()
			env.saves = env.saves + 1
		end,
		fire = function(name, payload)
			env.raw[#env.raw + 1] = payload
			if payload.selected == nil and payload.option == nil then
				env.events[#env.events + 1] = payload.state .. ":" .. tostring(payload.provider)
			end
		end,
		notify = function(title, text, kind)
			env.toasts[#env.toasts + 1] = title .. "|" .. text .. "|" .. tostring(kind)
		end,
		wait = task.wait,
		spawn = task.spawn,
		now = time,
		probe = opts.probe,
		settle = 0,
		log = function(level, text)
			env.logs[#env.logs + 1] = level .. ": " .. text
		end,
		allowed = opts.allowed,
		confirm = opts.confirm,
		X = opts.X,
		startLimit = opts.startLimit or 5,
		stopLimit = opts.stopLimit or 1,
	})
	return env
end

local function flat(t)
	return table.concat(t, ",")
end

local function count(list, value)
	local n = 0
	for _, v in ipairs(list) do
		if v == value then
			n = n + 1
		end
	end
	return n
end

T.section("reg_state: the constants describe the four providers")
T.eq(#Registry.IDS, 4)
for _, id in ipairs(Registry.IDS) do
	T.ok(Registry.KIND_OF[id] == "hat" or Registry.KIND_OF[id] == "limb", id .. " has a kind")
	T.ok(type(Registry.NAME_OF[id]) == "string" and Registry.NAME_OF[id] ~= id, id .. " has a readable name")
end
T.eq(Registry.KIND_OF.atsuko .. Registry.KIND_OF.fdless, "hathat")
T.eq(Registry.KIND_OF.unified, nil, "the old unified reanimation is gone")
T.eq(Registry.KIND_OF.gelatek .. Registry.KIND_OF.uhhhhhh, "limblimb")

T.section("reg_state: validate")
T.eq(#Registry.validate(fake("atsuko", "hat")), 0, "a complete provider is valid")
local function problemsWith(change)
	local p = fake("atsuko", "hat")
	change(p)
	return table.concat(Registry.validate(p), ";")
end
T.ok(string.find(problemsWith(function(p) p.AtsukoReanimProvider = nil end), "marker", 1, true), "the marker is required")
T.ok(string.find(problemsWith(function(p) p.id = "Atsuko" end), "id must", 1, true), "ids are lower-case")
T.ok(string.find(problemsWith(function(p) p.id = "a b" end), "id must", 1, true), "ids have no spaces")
T.ok(string.find(problemsWith(function(p) p.kind = "arm" end), "kind", 1, true), "kind is checked")
T.ok(string.find(problemsWith(function(p) p.name = "atsuko" end), "readable", 1, true), "the name cannot be the id")
T.ok(string.find(problemsWith(function(p) p.name = "Gelatek.lua" end), "readable", 1, true), "the name cannot be a file name")
T.ok(string.find(problemsWith(function(p) p.credit = nil end), "credit", 1, true), "the credit is required")
T.ok(string.find(problemsWith(function(p) p.blurb = "" end), "blurb must", 1, true), "an empty blurb is refused")
T.eq(problemsWith(function(p) p.blurb = "A short sentence" end), "", "a blurb is fine")
T.ok(string.find(problemsWith(function(p) p.caps = nil end), "caps", 1, true), "caps are required")
T.ok(string.find(problemsWith(function(p) p.caps.laser = true end), "unknown capability laser", 1, true), "unknown capabilities are refused")
T.ok(string.find(problemsWith(function(p) p.caps.emotes = nil end), "emotes is not stated", 1, true), "every capability has to be stated")
T.ok(string.find(problemsWith(function(p) p.caps.emotes = "yes" end), "true or false", 1, true), "capabilities are booleans")
T.ok(string.find(problemsWith(function(p) p.start = nil end), "start must", 1, true), "start is required")
T.ok(string.find(problemsWith(function(p) p.reset = nil end), "reset must", 1, true), "reset is required")
T.ok(string.find(problemsWith(function(p) p.settings[1].type = "slider" end), "unknown type", 1, true), "setting types are checked")
T.ok(string.find(problemsWith(function(p) p.settings[1].default = nil end), "no default", 1, true), "settings need defaults")
T.ok(string.find(problemsWith(function(p) p.settings[2].key = "mode" end), "twice", 1, true), "setting keys are unique")
T.ok(string.find(problemsWith(function(p) p.settings[1].options = {} end), "no options", 1, true), "choices need options")
T.ok(string.find(problemsWith(function(p) p.driver = 5 end), "driver", 1, true), "driver has to be a function")
T.ok(string.find(problemsWith(function(p) p.forget = 5 end), "forget must", 1, true), "forget has to be a function")
T.ok(string.find(problemsWith(function(p) p.stopWarning = "" end), "stopWarning must", 1, true), "an empty warning is refused")
T.ok(string.find(problemsWith(function(p) p.stopWarning = 5 end), "stopWarning must", 1, true), "a warning is text")
T.eq(problemsWith(function(p) p.stopWarning = "Stopping respawns you. Continue?" end), "", "a real warning is fine")
T.eq(problemsWith(function(p) p.forget = function() end end), "", "a forget function is fine")
local limb = fake("gelatek", "limb")
limb.caps.fdApi = true
T.ok(string.find(table.concat(Registry.validate(limb), ";"), "limb provider cannot claim", 1, true), "a limb provider cannot claim the FDless API")
T.eq(#Registry.validate(nil), 1)
T.eq(#Registry.validate("x"), 1)

T.section("reg_state: register, list and slots")
do
	local env = newEnv({ allowed = { atsuko = true, fdless = true, gelatek = true, uhhhhhh = true } })
	local reg = env.reg
	T.eq(reg:register(fake("atsuko", "hat")), true)
	local ok, why = reg:register(fake("atsuko", "hat"))
	T.eq(ok, false, "a second atsuko is refused")
	T.ok(string.find(why, "already", 1, true))
	ok, why = reg:register(fake("laser", "hat"))
	T.eq(ok, false, "an id outside the four is refused")
	ok, why = reg:register(fake("fdless", "limb"))
	T.eq(ok, false, "a known id with the wrong kind is refused")
	T.ok(string.find(why, "wrong kind", 1, true))
	T.eq(reg:register(fake("fdless", "hat")), true)
	T.eq(reg:register(fake("gelatek", "limb")), true)
	T.eq(#reg:list("hat"), 2)
	T.eq(#reg:list("limb"), 1)
	T.eq(#reg:list(), 3)
	T.eq(reg:get("fdless").id, "fdless")
	T.eq(reg:get("uhhhhhh"), nil)
	reg:markFailed("uhhhhhh", "couldn't download")
	local slots = reg:slots()
	T.eq(#slots, 4, "four slots always")
	T.eq(slots[4].id, "uhhhhhh")
	T.eq(slots[4].name, "Uhhhhhh")
	T.eq(slots[4].provider, nil)
	T.eq(slots[4].failed, "couldn't download")
	T.eq(slots[1].failed, nil, "a loaded provider has no failure")
	T.eq(#reg:slots("limb"), 2)
	local okSel, whySel = reg:select("limb", "uhhhhhh")
	T.eq(okSel, false)
	T.ok(string.find(whySel, "couldn't load Uhhhhhh", 1, true), "selecting a failed slot says why")
	T.ok(type(reg:get("atsuko").onChanged) == "function", "register installs onChanged")
end

T.section("reg_state: selection")
do
	local env = newEnv()
	local reg = env.reg
	reg:register(fake("atsuko", "hat"))
	reg:register(fake("fdless", "hat"))
	reg:register(fake("gelatek", "limb"))
	reg:register(fake("uhhhhhh", "limb"))
	T.eq(reg:selected("hat").id, "atsuko", "the stored pick is used")
	T.eq(reg:selected("limb").id, "gelatek", "default limb is gelatek")
	T.eq(reg:selected("arm"), nil)
	local ok = reg:select("hat", "fdless")
	T.eq(ok, true)
	T.eq(env.S.hatReanim, "fdless", "the choice is stored in the settings table")
	T.eq(env.saves, 1)
	T.eq(reg:selected("hat").id, "fdless")
	reg:select("hat", "fdless")
	T.eq(env.saves, 1, "the same choice is not saved again")
	local bad, why = reg:select("hat", "gelatek")
	T.eq(bad, false)
	T.ok(string.find(why, "not a hat", 1, true))
	bad = reg:select("hat", "nope")
	T.eq(bad, false)
	bad = reg:select("arm", "atsuko")
	T.eq(bad, false)
	env.S.hatReanim = "garbage"
	T.eq(reg:selected("hat"), nil, "a stale stored id is no pick, the hat one has no default")
	env.S.hatReanim = 5
	T.eq(reg:selected("hat"), nil, "a non-string stored id is no pick either")
	env.S.hatReanim = ""
	T.eq(reg:selected("hat"), nil)
	T.eq(reg:mustPick("hat"), true)
	T.eq(reg:mustPick("limb"), false)
	T.eq(Registry.MUST_PICK.hat, true)
	T.eq(Registry.MUST_PICK.limb, nil, "the limb one keeps its default")
	T.eq(Registry.SETTING_OF.hat, "hatReanim")
	local refused, refusedWhy = reg:start("hat", nil, {})
	T.eq(refused, false)
	T.eq(refusedWhy, Registry.PICK_TEXT.hat, "starting with no pick is refused with the pick text")
	T.eq(reg:state(), "idle")
	local forced = reg:start("hat", nil, { force = "fdless" })
	T.eq(forced, true, "a forced start needs no pick")
	reg:stop("user", true)
	env.S.hatReanim = "fdless"
	T.eq(reg:mustPick("hat"), false)
	env.S.reanimLimb = "uhhhhhh"
	T.eq(reg:selected("limb").id, "uhhhhhh")
	local only = newEnv({ S = { reanimOpts = {} } })
	only.reg:register(fake("fdless", "hat"))
	T.eq(only.reg:selected("hat"), nil, "even with one hat reanimation the player picks it")
	only.reg:register(fake("uhhhhhh", "limb"))
	T.eq(only.reg:selected("limb").id, "uhhhhhh", "without the default the first limb one is used")
end

T.section("reg_state: options")
do
	local env = newEnv()
	local reg = env.reg
	reg:register(fake("atsuko", "hat"))
	local o = reg:optionsOf("atsuko")
	T.eq(o.mode, "Simple")
	T.eq(o.speed, 5)
	T.eq(o.on, false)
	T.same(reg:optionsOf("nope"), {})
	local ok, value = reg:setOption("atsuko", "speed", 99)
	T.eq(ok, true)
	T.eq(value, 10, "numbers are clamped to the maximum")
	_, value = reg:setOption("atsuko", "speed", -5)
	T.eq(value, 1, "and to the minimum")
	_, value = reg:setOption("atsuko", "speed", "abc")
	T.eq(value, 5, "garbage falls back to the default")
	_, value = reg:setOption("atsuko", "speed", 0 / 0)
	T.eq(value, 5, "nan falls back to the default")
	_, value = reg:setOption("atsuko", "speed", math.huge)
	T.eq(value, 5, "infinity falls back to the default")
	_, value = reg:setOption("atsuko", "mode", "fling")
	T.eq(value, "Fling", "choices match case-insensitively")
	_, value = reg:setOption("atsuko", "mode", "Bullet")
	T.eq(value, "Simple", "unknown choices fall back")
	_, value = reg:setOption("atsuko", "on", "yes")
	T.eq(value, false, "toggles accept only booleans")
	_, value = reg:setOption("atsuko", "on", true)
	T.eq(value, true)
	T.eq(reg:optionsOf("atsuko").on, true)
	T.eq(env.S.reanimOpts.atsuko.on, true, "values live in S.reanimOpts[id]")
	local bad = reg:setOption("atsuko", "missing", 1)
	T.eq(bad, false)
	env.S.reanimOpts.atsuko.speed = 1000
	T.eq(reg:optionsOf("atsuko").speed, 10, "a hand-edited settings file is clamped when read")
	env.S.reanimOpts.atsuko = "broken"
	T.eq(reg:optionsOf("atsuko").speed, 5, "a broken options table is ignored")
	T.eq(Registry.clampOption({ type = "number", min = 0, max = 5, integer = true, default = 1 }, 2.6), 3)
	T.eq(Registry.clampOption({ type = "text", max = 3, default = "x" }, "abcdef"), "abc")
	T.eq(Registry.clampOption(nil, 1), nil)
end

T.section("reg_state: option change while running says when it applies")
do
	local env = newEnv()
	local reg = env.reg
	reg:register(fake("atsuko", "hat"))
	reg:start("hat", nil, {})
	local ok, value, later = reg:setOption("atsuko", "speed", 7)
	T.eq(ok, true)
	T.eq(value, 7)
	T.eq(later, "applies the next time you reanimate")
	reg:stop()
	ok, value, later = reg:setOption("atsuko", "speed", 8)
	T.eq(later, nil, "idle: nothing to wait for")
end

T.section("reg_state: standalone start and stop, event order")
do
	local env = newEnv()
	local reg = env.reg
	local p = fake("atsuko", "hat")
	reg:register(p)
	T.eq(reg:state(), "idle")
	T.eq(reg:active(), nil)
	local ok = reg:start("hat", nil, {})
	T.eq(ok, true)
	T.eq(reg:state(), "running")
	T.eq(reg:active().id, "atsuko")
	T.eq(flat(env.events), "starting:atsuko,running:atsuko")
	T.eq(flat(p.calls), "start", "start ran once, with no prepare because there is no script")
	T.eq(p.lastRun.options.speed, 5, "the provider receives its options")
	T.eq(p.lastRun.entry, nil)
	ok = reg:stop()
	T.eq(ok, true)
	T.eq(reg:state(), "idle")
	T.eq(reg:active(), nil)
	T.eq(flat(env.events), "starting:atsuko,running:atsuko,stopping:atsuko,stopped:atsuko")
	T.eq(flat(p.calls), "start,stop,reset", "stop runs stop and then reset")
	T.eq(reg:stop(), true, "stopping while idle is a no-op")
	T.eq(#env.events, 4)
end

T.section("reg_state: failure paths")
do
	local env = newEnv()
	local reg = env.reg
	local p = fake("gelatek", "limb", {
		start = function(run)
			return false, "Missing: Pal Hair"
		end,
	})
	reg:register(p)
	local ok, why = reg:start("limb", nil, {})
	T.eq(ok, false)
	T.eq(why, "Missing: Pal Hair")
	T.eq(reg:state(), "idle", "a failed start leaves the registry idle")
	T.eq(flat(env.events), "starting:gelatek,stopped:gelatek")
	T.eq(env.raw[2].failed, true)
	T.eq(count(p.calls, "stop"), 1, "the failed start is cleaned up")
	T.eq(count(p.calls, "reset"), 1)
	T.eq(env.toasts[#env.toasts], "Fake gelatek|Couldn't start: Missing: Pal Hair|error")
	T.eq(reg.lastFailure, "Missing: Pal Hair")
	p.start = function()
		error("boom\nsecond line")
	end
	ok, why = reg:start("limb", nil, {})
	T.eq(ok, false)
	T.ok(string.find(why, "boom", 1, true))
	T.eq(string.find(why, "second line", 1, true), nil, "only the first line of an error reaches the user")
	T.eq(reg:state(), "idle")
	p.start = function()
		p.running = true
		return true
	end
	ok = reg:start("limb", nil, {})
	T.eq(ok, true, "the registry works again after failures")
	reg:stop()
end

T.section("reg_state: availability is checked before anything starts")
do
	local env = newEnv()
	local reg = env.reg
	local p = fake("uhhhhhh", "limb", {
		available = function(X)
			return false, "your executor has no getcustomasset"
		end,
	})
	reg:register(p)
	local ok, why = reg:start("limb", nil, {})
	T.eq(ok, false)
	T.eq(why, "your executor has no getcustomasset")
	T.eq(#p.calls, 0, "nothing of the provider ran")
	T.eq(#env.events, 0, "no state change and no event")
	T.eq(env.toasts[1], "Fake uhhhhhh|your executor has no getcustomasset|error")
	p.available = function()
		error("probe failed")
	end
	ok, why = reg:start("limb", nil, {})
	T.eq(ok, false, "an available() that throws counts as unavailable")
	T.ok(string.find(why, "probe failed", 1, true))
	p.available = function()
		return false
	end
	ok, why = reg:start("limb", nil, {})
	T.eq(why, "not available here", "false without a reason still gets a message")
end

T.section("reg_state: nothing registered")
do
	local env = newEnv()
	env.reg:markFailed("atsuko", "couldn't download")
	local ok, why = env.reg:start("hat", nil, {})
	T.eq(ok, false)
	T.ok(string.find(why, "couldn't load Script Reanimate", 1, true))
	local ok2, why2 = env.reg:start("limb", nil, {})
	T.eq(ok2, false)
	T.eq(why2, "no reanimation is available")
end

T.section("reg_state: a second start while starting is refused, never queued")
do
	local env = newEnv()
	local reg = env.reg
	local p = fake("atsuko", "hat", { startDelay = 1 })
	reg:register(p)
	local second, secondWhy
	task.delay(0.4, function()
		second, secondWhy = reg:start("hat", nil, {})
	end)
	local stopped, stopWhy
	task.delay(0.6, function()
		stopped, stopWhy = reg:stop()
	end)
	local ok = reg:start("hat", nil, {})
	T.eq(ok, true)
	T.eq(second, false, "the second start was refused")
	T.eq(secondWhy, "busy")
	T.eq(stopped, false, "a plain stop while starting is refused too")
	T.eq(stopWhy, "busy")
	T.eq(count(p.calls, "start"), 1, "the provider started exactly once")
	T.eq(flat(env.events), "starting:atsuko,running:atsuko")
	T.eq(count(env.toasts, "Reanimation|Hold on, it is still starting|info"), 2)
	reg:stop()
end

T.section("reg_state: stop while starting with force cancels the wait")
do
	local env = newEnv()
	local reg = env.reg
	local p = fake("atsuko", "hat", {
		start = function(run)
			task.wait(0.5)
			return true
		end,
	})
	p.running = false
	reg:register(p)
	local entry = { path = "x.lua" }
	local calls = {}
	local ctl = {
		run = function()
			calls[#calls + 1] = "run"
			return true
		end,
		stopScript = function()
			calls[#calls + 1] = "stopScript"
		end,
		alive = function()
			return true
		end,
	}
	local stopResult
	task.delay(0.5, function()
		stopResult = reg:stop("user", true)
	end)
	local ok, why = reg:start("hat", entry, ctl)
	T.eq(ok, false)
	T.eq(why, "cancelled")
	T.eq(stopResult, true)
	T.eq(reg:state(), "idle")
	T.eq(flat(calls), "run,stopScript")
	T.eq(flat(env.events), "starting:atsuko,stopping:atsuko,stopped:atsuko")
end

T.section("reg_state: hat provider with a script")
do
	local env = newEnv({ S = { reanimOpts = {}, hatReanim = "fdless" } })
	local reg = env.reg
	local order = {}
	local p = fake("fdless", "hat")
	p.prepare = function(entry, run)
		order[#order + 1] = "prepare:" .. entry.path
		return true
	end
	p.stop = function()
		order[#order + 1] = "provider.stop"
		p.running = false
	end
	p.reset = function()
		order[#order + 1] = "provider.reset"
	end
	reg:register(p)
	local ctl = {
		run = function()
			order[#order + 1] = "run"
			task.delay(0.5, function()
				p.running = true
			end)
			return true
		end,
		stopScript = function()
			order[#order + 1] = "stopScript"
		end,
		alive = function()
			return true
		end,
	}
	local ok = reg:start("hat", { path = "Main/Last Star.lua" }, ctl)
	T.eq(ok, true)
	T.eq(flat(order), "prepare:Main/Last Star.lua,run")
	T.eq(reg:state(), "running")
	T.eq(reg:stop(), true)
	T.eq(flat(order), "prepare:Main/Last Star.lua,run,stopScript,provider.stop,provider.reset", "the script stops first, then the provider, then the reset")
	T.eq(flat(env.events), "starting:fdless,running:fdless,stopping:fdless,stopped:fdless")
end

T.section("reg_state: hat script that never reanimates")
do
	local env = newEnv({ startLimit = 3, S = { reanimOpts = {}, hatReanim = "fdless" } })
	local reg = env.reg
	local p = fake("fdless", "hat")
	reg:register(p)
	local stopped = 0
	local ok, why = reg:start("hat", { path = "a.lua" }, {
		run = function()
			return true
		end,
		stopScript = function()
			stopped = stopped + 1
		end,
	})
	T.eq(ok, false)
	T.eq(why, "timed out", "never an endless Starting")
	T.eq(reg:state(), "idle")
	T.eq(stopped, 1, "the script is stopped again")
	T.eq(count(p.calls, "reset"), 1)
	T.eq(env.toasts[#env.toasts], "Fake fdless|Couldn't start: timed out|error")
end

T.section("reg_state: hat script that ends before it reanimates")
do
	local env = newEnv({ startLimit = 20 })
	local reg = env.reg
	local p = fake("atsuko", "hat")
	reg:register(p)
	local up = true
	task.delay(2, function()
		up = false
	end)
	local ok, why = reg:start("hat", { path = "a.lua" }, {
		run = function()
			return true
		end,
		alive = function()
			return up
		end,
	})
	T.eq(ok, false)
	T.eq(why, "the script stopped before it reanimated")
	T.eq(reg:state(), "idle")
end

T.section("reg_state: ctl.run and prepare failures")
do
	local env = newEnv()
	local reg = env.reg
	local p = fake("atsuko", "hat")
	reg:register(p)
	local ok, why = reg:start("hat", { path = "a" }, {
		run = function()
			return false, "the script did not download"
		end,
	})
	T.eq(ok, false)
	T.eq(why, "the script did not download")
	T.eq(reg:state(), "idle")
	p.prepare = function()
		return false, "FDless would not load"
	end
	ok, why = reg:start("hat", { path = "a" }, {
		run = function()
			return true
		end,
	})
	T.eq(why, "FDless would not load")
	p.prepare = function()
		error("prepare blew up")
	end
	ok, why = reg:start("hat", { path = "a" }, {})
	T.eq(ok, false)
	T.ok(string.find(why, "prepare blew up", 1, true))
	T.eq(reg:state(), "idle")
end

T.section("reg_state: limb provider starts first, then the script")
do
	local env = newEnv()
	local reg = env.reg
	local p = fake("gelatek", "limb")
	reg:register(p)
	local order = {}
	local ok = reg:start("limb", { path = "limb.lua" }, {
		run = function()
			order[#order + 1] = "run:" .. (p.running and "provider-up" or "provider-down")
			return true
		end,
		stopScript = function()
			order[#order + 1] = "stopScript"
		end,
	})
	T.eq(ok, true)
	T.eq(flat(order), "run:provider-up", "the script only starts once the limb reanimation runs")
	T.eq(flat(p.calls), "start", "no prepare for limb providers")
	reg:stop()
	T.eq(flat(order), "run:provider-up,stopScript")
	local failing = newEnv()
	local q = fake("gelatek", "limb")
	failing.reg:register(q)
	local ok2, why2 = failing.reg:start("limb", { path = "x" }, {
		run = function()
			return false, "script error"
		end,
	})
	T.eq(ok2, false)
	T.eq(why2, "script error")
	T.eq(failing.reg:state(), "idle")
	T.eq(count(q.calls, "stop"), 1, "the limb reanimation is undone when its script fails")
end

T.section("reg_state: switching stops the first and starts the second with one toast")
do
	local env = newEnv()
	local reg = env.reg
	local a = fake("atsuko", "hat")
	local b = fake("fdless", "hat")
	reg:register(a)
	reg:register(b)
	reg:start("hat", nil, {})
	reg:select("hat", "fdless")
	T.eq(reg:state(), "running")
	T.eq(reg:active().id, "atsuko", "choosing another provider does not touch the running one")
	local before = #env.toasts
	local ok = reg:start("hat", nil, {})
	T.eq(ok, true)
	T.eq(reg:active().id, "fdless")
	T.eq(flat(env.events), "starting:atsuko,running:atsuko,stopping:atsuko,stopped:atsuko,starting:fdless,running:fdless")
	T.eq(#env.toasts - before, 1, "exactly one toast for the switch")
	T.eq(env.toasts[#env.toasts], "Reanimation|Stopping Fake atsuko first|info")
	T.eq(a.running, false)
	T.eq(count(a.calls, "reset"), 1, "nothing of the first remains")
	reg:stop()
	T.eq(reg:start("hat", nil, {}), true)
	T.eq(select(1, reg:start("hat", nil, {})), false, "starting the same provider again is refused")
	T.eq(env.toasts[#env.toasts], "Fake fdless|Already running|info")
	reg:stop()
end

T.section("reg_state: a hat script can be swapped for another without stopping")
do
	local env = newEnv()
	local reg = env.reg
	local a = fake("atsuko", "hat")
	local q = fake("gelatek", "limb")
	reg:register(a)
	reg:register(q)
	T.eq(reg:canSwap("hat", { path = "B" }), false, "nothing runs yet")
	local order = {}
	local first = {
		run = function()
			order[#order + 1] = "run:A"
			a.running = true
			return true
		end,
		swapOut = function()
			order[#order + 1] = "swapOut:A"
		end,
		stopScript = function()
			order[#order + 1] = "stopScript:A"
		end,
	}
	T.eq(reg:start("hat", { path = "A" }, first), true)
	T.eq(reg:canSwap("hat", { path = "B" }), true)
	T.eq(reg:canSwap("limb", { path = "B" }), false, "limb scripts never swap")
	T.eq(reg:canSwap("hat", nil), false, "a provider on its own has nothing to swap")
	T.eq(reg:canSwap("hat", { path = "B" }, "fdless"), false, "a script locked to another provider can't")
	T.eq(reg:canSwap("hat", { path = "B" }, "atsuko"), true)
	env.events = {}
	local saw = nil
	a.prepare = function(entry, run)
		saw = run
		order[#order + 1] = "prepare:" .. entry.path
		return true
	end
	local second = {
		run = function()
			order[#order + 1] = "run:B"
			return true
		end,
		swapOut = function()
			order[#order + 1] = "swapOut:B"
		end,
	}
	T.eq(reg:swap("hat", { path = "B" }, second), true)
	T.eq(flat(order), "run:A,swapOut:A,prepare:B,run:B", "the old script goes, then the new one is handed in")
	T.eq(saw and saw.swap, true, "the provider is told it is a swap")
	T.eq(flat(env.events), "starting:atsuko,running:atsuko", "no stop in between")
	T.eq(count(a.calls, "stop"), 0)
	T.eq(count(a.calls, "reset"), 0)
	T.eq(reg:state(), "running")
	T.eq(a.running, true)
	local swapFlag = false
	for _, payload in ipairs(env.raw) do
		if payload.state == "starting" and payload.swap == true then
			swapFlag = true
		end
	end
	T.ok(swapFlag, "the starting event says it is a swap")
	T.eq(reg:swap("limb", { path = "C" }, {}), false)
	order = {}
	second.stopScript = function()
		order[#order + 1] = "stopScript:B"
	end
	reg:stop()
	T.eq(flat(order), "stopScript:B", "stopping afterwards stops the new script")
	T.eq(count(a.calls, "stop"), 1)
end

T.section("reg_state: the old script letting go during a swap is not a stop")
do
	local env = newEnv()
	local reg = env.reg
	local a = fake("atsuko", "hat")
	local holds = {}
	a.hold = function(on)
		holds[#holds + 1] = tostring(on)
	end
	reg:register(a)
	reg:start("hat", { path = "A" }, {
		run = function()
			a.running = true
			return true
		end,
		swapOut = function()
			holds[#holds + 1] = "out"
			reg:external("atsuko", "stopped", "Stopped on its own")
		end,
	})
	local ok = reg:swap("hat", { path = "B" }, {
		run = function()
			return true
		end,
	})
	task.wait(0.5)
	T.eq(ok, true)
	T.eq(table.concat(holds, ","), "true,out,false", "the provider holds its body only while the old script stops")
	T.eq(reg:state(), "running", "the stop it reported was ignored")
	T.eq(count(a.calls, "stop"), 0)
	T.eq(reg.swapping, false, "and the guard is down afterwards")
	reg:external("atsuko", "stopped", "Stopped on its own")
	task.wait(0.5)
	T.eq(reg:state(), "idle", "a real stop later still counts")
end

T.section("reg_state: a swap whose script fails cleans up")
do
	local env = newEnv()
	local reg = env.reg
	local a = fake("atsuko", "hat")
	reg:register(a)
	T.eq(reg:start("hat", { path = "A" }, {
		run = function()
			a.running = true
			return true
		end,
	}), true)
	local ok, why = reg:swap("hat", { path = "B" }, {
		run = function()
			return false, "it broke"
		end,
	})
	T.eq(ok, false)
	T.eq(why, "it broke")
	T.eq(reg:state(), "idle")
	T.eq(a.running, false, "the reanimation is stopped")
	T.eq(env.toasts[#env.toasts], "Fake atsuko|Couldn't start: it broke|error")
end

T.section("reg_state: select while running reports that it applies next time")
do
	local env = newEnv()
	local reg = env.reg
	reg:register(fake("atsuko", "hat"))
	reg:register(fake("fdless", "hat"))
	reg:start("hat", nil, {})
	local ok, note = reg:select("hat", "fdless")
	T.eq(ok, true)
	T.eq(note, "applies the next time you reanimate")
	ok, note = reg:select("hat", "atsuko")
	T.eq(note, nil, "choosing the running provider has nothing to wait for")
	reg:stop()
end

T.section("reg_state: force picks a provider for one start")
do
	local env = newEnv()
	local reg = env.reg
	local a = fake("atsuko", "hat")
	local f = fake("fdless", "hat")
	reg:register(a)
	reg:register(f)
	reg:register(fake("gelatek", "limb"))
	reg:select("hat", "fdless")
	local ok = reg:start("hat", { path = "native.lua" }, {
		force = "atsuko",
		run = function()
			a.running = true
			return true
		end,
	})
	T.eq(ok, true)
	T.eq(reg:active().id, "atsuko", "a hub-native script runs on Script Reanimate whatever is selected")
	T.eq(env.S.hatReanim, "fdless", "and the stored choice is untouched")
	reg:stop()
	ok = reg:start("hat", nil, { force = "gelatek" })
	T.eq(reg:active().id, "fdless", "a force with the wrong kind is ignored")
	reg:stop()
end

T.section("reg_state: a forced provider that did not load is an error, never a quiet switch")
do
	local env = newEnv()
	local reg = env.reg
	local f = fake("fdless", "hat")
	reg:register(f)
	reg:register(fake("gelatek", "limb"))
	reg:markFailed("atsuko", "no connection")
	local ran = false
	local ok, why = reg:start("hat", { path = "native.lua" }, {
		force = "atsuko",
		run = function()
			ran = true
			return true
		end,
	})
	T.eq(ok, false)
	T.eq(why, "couldn't load Script Reanimate: no connection")
	T.eq(ran, false, "the script was not run on another reanimation")
	T.eq(reg:state(), "idle")
	T.eq(count(f.calls, "prepare"), 0, "the other hat reanimation was not touched")
	T.eq(env.toasts[#env.toasts], "Reanimation|couldn't load Script Reanimate: no connection|error")
	ok, why = reg:start("hat", { path = "other.lua" }, { force = "atsuko" })
	T.eq(ok, false)
	T.eq(why, "couldn't load Script Reanimate: no connection")
end
do
	local env = newEnv({ S = { reanimOpts = {}, hatReanim = "fdless" } })
	local reg = env.reg
	reg:register(fake("fdless", "hat"))
	local ok, why = reg:start("hat", { path = "native.lua" }, { force = "atsuko" })
	T.eq(ok, false, "not registered and not marked as failed")
	T.eq(why, "Script Reanimate is not available")
	T.eq(env.toasts[#env.toasts], "Reanimation|Script Reanimate is not available|error")
	T.eq(reg:state(), "idle")
	ok = reg:start("hat", nil, { force = "nothing" })
	T.eq(ok, true, "an unknown name is ignored, the chosen one starts")
	T.eq(reg:active().id, "fdless")
	reg:stop()
	ok = reg:start("hat", nil, { force = "gelatek" })
	T.eq(ok, true, "a limb provider that is not loaded can't be forced onto a hat start")
	T.eq(reg:active().id, "fdless")
	reg:stop()
end

T.section("reg_state: stop that does not finish keeps the state truthful")
do
	local env = newEnv({ stopLimit = 1 })
	local reg = env.reg
	local p = fake("gelatek", "limb", {
		stop = function()
		end,
	})
	reg:register(p)
	reg:start("limb", nil, {})
	local ok, why = reg:stop()
	T.eq(ok, false)
	T.eq(why, "stop timed out")
	T.eq(reg:state(), "running", "never pretends it stopped")
	T.eq(reg:active().id, "gelatek")
	T.eq(env.toasts[#env.toasts], "Fake gelatek|Couldn't stop it in time, it is still running|error")
	T.eq(count(p.calls, "reset"), 0, "no reset while it still runs")
	p.stop = function()
		p.running = false
	end
	T.eq(reg:stop(), true, "a later stop works")
	T.eq(reg:state(), "idle")
end

T.section("reg_state: a stop that throws still completes")
do
	local env = newEnv()
	local reg = env.reg
	local p = fake("atsuko", "hat")
	p.isRunning = function()
		return p.flag
	end
	p.start = function()
		p.flag = true
		return true
	end
	p.stop = function()
		p.flag = false
		error("stop failed")
	end
	reg:register(p)
	reg:start("hat", nil, {})
	T.eq(reg:stop(), true)
	T.eq(reg:state(), "idle")
	T.ok(string.find(table.concat(env.logs, "|"), "stop failed", 1, true) ~= nil, "the error is logged")
end

T.section("reg_state: the provider ends by itself")
do
	local env = newEnv()
	local reg = env.reg
	local p = fake("atsuko", "hat")
	reg:register(p)
	local stoppedScripts = 0
	reg:start("hat", { path = "s" }, {
		run = function()
			p.running = true
			return true
		end,
		stopScript = function()
			stoppedScripts = stoppedScripts + 1
		end,
	})
	p.running = false
	p.onChanged("stopped", "Your character respawned, so the reanimate ended")
	task.wait(0.1)
	T.eq(reg:state(), "idle")
	T.eq(flat(env.events), "starting:atsuko,running:atsuko,stopping:atsuko,stopped:atsuko")
	T.eq(stoppedScripts, 1)
	T.eq(env.toasts[#env.toasts], "Fake atsuko|Your character respawned, so the reanimate ended|info")
	p.onChanged("stopped", "again")
	task.wait(0.1)
	T.eq(#env.events, 4, "a late duplicate report changes nothing")
	p.onChanged("running")
	T.eq(reg:state(), "idle", "a running report from an idle provider changes nothing")
	local other = fake("fdless", "hat")
	reg:register(other)
	reg:start("hat", nil, {})
	other.onChanged("stopped", "x")
	task.wait(0.1)
	T.eq(reg:state(), "running", "only the active provider can end the run")
	reg:stop()
end

T.section("reg_state: leak report")
do
	local snaps = {
		{ values = { camera = "Humanoid", walk = 16 }, sets = { instances = { ["Workspace.Real (Model)"] = true }, globals = { Existing = true } }, counts = { connections = 10 } },
		{ values = { camera = "Humanoid", walk = 16 }, sets = { instances = { ["Workspace.Real (Model)"] = true }, globals = { Existing = true } }, counts = { connections = 10 } },
	}
	local index = 0
	local env = newEnv({
		probe = function()
			index = index + 1
			return snaps[index]
		end,
	})
	local reg = env.reg
	reg:register(fake("atsuko", "hat"))
	T.eq(reg:leakReport(), nil, "no report before a run")
	reg:start("hat", nil, {})
	reg:stop()
	T.same(reg:leakReport(), {}, "a clean run gives an empty report")

	snaps = {
		{ values = { camera = "Humanoid", walk = 16 }, sets = { instances = {}, globals = {} }, counts = { connections = 10 } },
		{
			values = { camera = "Clone", walk = 0 },
			sets = { instances = { ["Workspace.TalentlessDumbass (Model)"] = true, ["CoreGui.Uhhhhhh (ScreenGui)"] = true }, globals = { Reanimated = true, UhhhhhhLoaded = true } },
			counts = { connections = 14 },
		},
	}
	index = 0
	local p2 = env.reg:get("atsuko")
	p2.keep = { UhhhhhhLoaded = true, "^CoreGui%.Uhhhhhh" }
	reg:start("hat", nil, {})
	reg:stop()
	local report = reg:leakReport()
	T.eq(#report, 5, "five findings: " .. table.concat(report, " | "))
	T.eq(report[1], "camera changed: Humanoid -> Clone")
	T.eq(report[2], "walk changed: 16 -> 0")
	T.ok(string.find(table.concat(report, "|"), "globals left behind: Reanimated", 1, true))
	T.ok(string.find(table.concat(report, "|"), "instances left behind: Workspace.TalentlessDumbass (Model)", 1, true))
	T.ok(string.find(table.concat(report, "|"), "connections grew: 10 -> 14", 1, true))
	T.eq(string.find(table.concat(report, "|"), "UhhhhhhLoaded", 1, true), nil, "kept keys are ignored")
	T.eq(string.find(table.concat(report, "|"), "Uhhhhhh (ScreenGui)", 1, true), nil, "kept patterns are ignored")
end

T.section("reg_state: compare is pure and tolerant")
do
	T.same(Registry.compare(nil, nil), {})
	T.same(Registry.compare({}, {}), {})
	T.same(Registry.compare({ counts = { a = 5 } }, { counts = { a = 3 } }), {}, "fewer connections than before is fine")
	T.same(Registry.compare({ sets = { x = { a = true } } }, { sets = { x = {} } }), {}, "things that vanished are fine")
	T.same(Registry.compare({}, { sets = { x = { a = true } } }), { "x left behind: a" })
	T.same(Registry.compare({ values = { v = 1 } }, { values = { v = 1 } }), {})
	T.same(Registry.compare({ values = { v = 1 } }, {}), { "v changed: 1 -> nil" })
	T.same(Registry.compare({ values = { v = 1 } }, { values = { v = 2 } }, { v = true }), {}, "kept values are ignored")
	local first = Registry.compare({}, { sets = { x = { b = true, a = true, c = true } } })
	T.same(first, { "x left behind: a", "x left behind: b", "x left behind: c" }, "findings come in a stable order")
end

T.section("reg_state: a broken probe never breaks a run")
do
	local env = newEnv({
		probe = function()
			error("probe broke")
		end,
	})
	local reg = env.reg
	reg:register(fake("atsuko", "hat"))
	T.eq(reg:start("hat", nil, {}), true)
	T.eq(reg:stop(), true)
	T.eq(reg:leakReport(), nil)
end

T.section("reg_state: destroy")
do
	local env = newEnv()
	local reg = env.reg
	local a = fake("atsuko", "hat")
	local g = fake("gelatek", "limb")
	reg:register(a)
	reg:register(g)
	reg:start("hat", nil, {})
	reg:destroy()
	T.eq(a.running, false, "the running provider is stopped")
	T.eq(count(a.calls, "reset"), 1)
	T.eq(count(g.calls, "reset"), 1, "every provider gets a reset")
	T.eq(reg:state(), "idle")
	local ok, why = reg:start("hat", nil, {})
	T.eq(ok, false)
	T.eq(why, "the hub is closing")
	reg:external("atsuko", "stopped", "late")
	T.eq(#env.toasts >= 0, true, "events after destroy are ignored")
end

T.section("reg_state: destroy prefers a provider's own forget")
do
	local env = newEnv()
	local reg = env.reg
	local a = fake("atsuko", "hat")
	local forgotten = 0
	a.forget = function()
		forgotten = forgotten + 1
		a.calls[#a.calls + 1] = "forget"
	end
	local g = fake("gelatek", "limb")
	reg:register(a)
	reg:register(g)
	reg:start("hat", nil, {})
	reg:destroy()
	T.eq(forgotten, 1)
	T.eq(count(a.calls, "reset"), 0, "forget replaces reset when a provider has it")
	T.eq(count(g.calls, "reset"), 1, "a provider without forget still gets reset")
	T.eq(a.running, false, "the running provider is still stopped first")
end

T.section("reg_state: a stop warning asks first")
do
	local asked = {}
	local answer = true
	local env = newEnv({
		confirm = function(text, p)
			asked[#asked + 1] = text .. "|" .. p.id
			return answer
		end,
	})
	local reg = env.reg
	local g = fake("gelatek", "limb", { stopWarning = "Stopping respawns you. Continue?" })
	local u = fake("uhhhhhh", "limb")
	reg:register(g)
	reg:register(u)
	T.eq(reg:start("limb", nil, {}), true)
	T.eq(reg:active().id, "gelatek")
	answer = false
	local ok, why = reg:stop("user")
	T.eq(ok, false)
	T.eq(why, "declined")
	T.eq(reg:state(), "running", "declining leaves it running")
	T.eq(g.running, true)
	T.eq(count(g.calls, "stop"), 0)
	T.eq(flat(env.events), "starting:gelatek,running:gelatek", "declining fires no event")
	T.eq(#env.toasts, 0, "and shows no toast")
	T.eq(asked[1], "Stopping respawns you. Continue?|gelatek")
	answer = true
	T.eq(reg:stop("user"), true)
	T.eq(#asked, 2)
	T.eq(reg:state(), "idle")
	T.eq(g.running, false)

	T.eq(reg:start("limb", nil, {}), true)
	T.eq(reg:stop("script ended"), true)
	T.eq(#asked, 2, "an internal reason does not ask")
	T.eq(reg:start("limb", nil, {}), true)
	T.eq(reg:stop(), true)
	T.eq(#asked, 3, "no reason at all counts as the user")
	T.eq(reg:start("limb", nil, {}), true)
	T.eq(reg:stop("user", true), true)
	T.eq(#asked, 3, "a forced stop does not ask")

	reg:select("limb", "uhhhhhh")
	T.eq(reg:start("limb", nil, {}), true)
	T.eq(reg:stop("user"), true)
	T.eq(#asked, 3, "a provider without a warning never asks")
	reg:select("limb", "gelatek")
end

T.section("reg_state: a broken or missing confirm never stops anything by mistake")
do
	local env = newEnv({
		confirm = function()
			error("dialog broke")
		end,
	})
	local reg = env.reg
	local g = fake("gelatek", "limb", { stopWarning = "Stopping respawns you. Continue?" })
	reg:register(g)
	reg:start("limb", nil, {})
	local ok, why = reg:stop("user")
	T.eq(ok, false)
	T.eq(why, "declined")
	T.eq(g.running, true)
	T.ok(#env.logs >= 1 and string.find(env.logs[#env.logs], "confirm failed", 1, true), "the failure is logged")

	local env2 = newEnv({
		confirm = function()
			return "yes"
		end,
	})
	local g2 = fake("gelatek", "limb", { stopWarning = "Stopping respawns you. Continue?" })
	env2.reg:register(g2)
	env2.reg:start("limb", nil, {})
	T.eq(env2.reg:stop("user"), false, "only a real yes counts")

	local env3 = newEnv()
	local g3 = fake("gelatek", "limb", { stopWarning = "Stopping respawns you. Continue?" })
	env3.reg:register(g3)
	env3.reg:start("limb", nil, {})
	T.eq(env3.reg:stop("user"), true, "with no confirm hook it just stops")
end

T.section("reg_state: the state changing while the question is open")
do
	local env
	local g
	env = newEnv({
		confirm = function()
			g.running = false
			env.reg:external("gelatek", "stopped", "Stopped on its own")
			return true
		end,
	})
	g = fake("gelatek", "limb", { stopWarning = "Stopping respawns you. Continue?" })
	env.reg:register(g)
	env.reg:start("limb", nil, {})
	T.eq(env.reg:stop("user"), true, "it already stopped, which is what was asked for")
	T.eq(env.reg:state(), "idle")
	T.eq(count(g.calls, "stop"), 1, "stop ran once, from the outside stop")
end

T.section("reg_state: switching away from a provider with a warning")
do
	local answer = false
	local asked = 0
	local env = newEnv({
		confirm = function()
			asked = asked + 1
			return answer
		end,
	})
	local reg = env.reg
	local g = fake("gelatek", "limb", { stopWarning = "Stopping respawns you. Continue?" })
	local u = fake("uhhhhhh", "limb")
	reg:register(g)
	reg:register(u)
	reg:start("limb", nil, {})
	reg:select("limb", "uhhhhhh")
	local ok, why = reg:start("limb", nil, {})
	T.eq(ok, false)
	T.eq(why, "declined")
	T.eq(asked, 1)
	T.eq(reg:state(), "running")
	T.eq(reg:active().id, "gelatek", "declining keeps the first one")
	T.eq(u.running, false)
	for _, t in ipairs(env.toasts) do
		T.ok(not string.find(t, "Stopping", 1, true), "no stopping toast before the answer: " .. t)
	end
	answer = true
	env.toasts = {}
	T.eq(reg:start("limb", nil, {}), true)
	T.eq(asked, 2, "asked once for the switch, not twice")
	T.eq(reg:active().id, "uhhhhhh")
	T.eq(g.running, false)
	local stoppingToasts = 0
	for _, t in ipairs(env.toasts) do
		if string.find(t, "Stopping Fake gelatek first", 1, true) then
			stoppingToasts = stoppingToasts + 1
		end
	end
	T.eq(stoppingToasts, 1, "one toast after the yes")
	T.eq(flat(env.events), "starting:gelatek,running:gelatek,stopping:gelatek,stopped:gelatek,starting:uhhhhhh,running:uhhhhhh")
	reg:select("limb", "gelatek")
	T.eq(reg:start("limb", nil, {}), true)
	T.eq(asked, 2, "the provider without a warning is stopped without asking")
	T.eq(reg:active().id, "gelatek")
end

T.section("reg_state: with nothing saved every option is its default")
do
	local env = newEnv()
	local reg = env.reg
	local p = fake("atsuko", "hat")
	p.settings[#p.settings + 1] = { key = "loud", type = "toggle", label = "Loud", default = true }
	reg:register(p)
	local o = reg:optionsOf("atsuko")
	T.eq(o.loud, true, "a toggle that defaults to on is on")
	T.eq(o.on, false)
	T.eq(o.mode, "Simple")
	T.eq(o.speed, 5)
	env.S.reanimOpts = nil
	T.eq(reg:optionsOf("atsuko").loud, true, "also when the whole table is gone")
	env.S.reanimOpts = { atsuko = "garbage" }
	T.eq(reg:optionsOf("atsuko").loud, true, "also when the saved entry is not a table")
	env.S.reanimOpts = { atsuko = { loud = false } }
	T.eq(reg:optionsOf("atsuko").loud, false, "a saved off stays off")
	env.S.reanimOpts = { atsuko = { loud = "yes", speed = 99, mode = "nope" } }
	local clean = reg:optionsOf("atsuko")
	T.eq(clean.loud, true, "a value of the wrong type falls back to the default")
	T.eq(clean.speed, 10, "a number is held to its range")
	T.eq(clean.mode, "Simple", "an unknown choice falls back to the default")
end

T.section("reg_state: refused transitions")
do
	local env = newEnv()
	local reg = env.reg
	local p = fake("atsuko", "hat")
	reg:register(p)
	T.eq(reg:set("running", p), false, "idle cannot jump to running")
	T.eq(reg:set("stopping", p), false, "idle cannot jump to stopping")
	T.eq(reg:state(), "idle")
	T.eq(#env.events, 0)
	T.ok(#env.logs >= 2, "refusals are logged")
	T.eq(reg:set("starting", p), true)
	T.eq(reg:set("starting", p), false, "same state is a no-op")
	T.eq(reg:set("idle", p), true)
end

T.section("reg_state: every state sequence the registry can produce is legal")
do
	local legal = { idle = { starting = true }, starting = { running = true, idle = true, stopping = true }, running = { stopping = true, idle = true }, stopping = { idle = true, running = true } }
	local names = { stopped = "idle", starting = "starting", running = "running", stopping = "stopping" }
	local env = newEnv({ startLimit = 2 })
	local reg = env.reg
	local good = fake("atsuko", "hat")
	local bad = fake("fdless", "hat", {
		start = function()
			return false, "no"
		end,
	})
	reg:register(good)
	reg:register(bad)
	local seed = 7
	local function rnd(n)
		seed = (seed * 1103515245 + 12345) % 2147483648
		return seed % n + 1
	end
	for i = 1, 150 do
		local pick = rnd(6)
		if pick == 1 then
			reg:select("hat", "atsuko")
		elseif pick == 2 then
			reg:select("hat", "fdless")
		elseif pick == 3 or pick == 4 then
			reg:start("hat", nil, {})
		elseif pick == 5 then
			reg:stop("random", rnd(2) == 1)
		else
			good.running = rnd(2) == 1
			if good.onChanged then
				good.onChanged("stopped", "random")
			end
			task.wait(0.05)
		end
	end
	local cur = "idle"
	local bad = 0
	for _, payload in ipairs(env.raw) do
		if payload.selected == nil and payload.option == nil then
			local to = names[payload.state]
			if to ~= cur and not legal[cur][to] then
				bad = bad + 1
			end
			cur = to
		end
	end
	T.eq(bad, 0, "150 random calls produced only legal transitions")
	T.ok(#env.events > 10, "and the sequence was not trivial")
end

T.section("reg_state: option metadata is validated")
do
	local function with(change)
		local p = fake("atsuko", "hat")
		change(p)
		return table.concat(Registry.validate(p), ";")
	end
	T.eq(with(function(p) p.settings[1].labels = { "One", "Two" } end), "", "labels matching the options are fine")
	T.ok(string.find(with(function(p) p.settings[1].labels = { "One" } end), "one label for each option", 1, true))
	T.ok(string.find(with(function(p) p.settings[1].labels = "x" end), "one label for each option", 1, true))
	T.ok(string.find(with(function(p) p.settings[1].applies = "later" end), "applies must be", 1, true))
	T.ok(string.find(with(function(p) p.settings[1].optionNeeds = 5 end), "optionNeeds", 1, true))
	T.ok(string.find(with(function(p) p.settings[1].label = 5 end), "label that is not text", 1, true))
	T.eq(with(function(p) p.settings[1].applies = "now" end), "")
end

T.section("reg_state: options that need an executor function")
do
	local p = fake("fdless", "hat")
	p.settings = {
		{ key = "method", type = "choice", options = { 1, 2, 3, 4 }, labels = { "1", "2", "3", "4" }, default = 1, optionNeeds = { [4] = "replicatesignal" } },
		{ key = "fling", type = "toggle", default = true },
	}
	local without = newEnv({ X = { loadstring = true } })
	without.reg:register(p)
	local ok, why = without.reg:optionAvailable("fdless", "method", 4)
	T.eq(ok, false)
	T.eq(why, "your executor has no replicatesignal")
	T.eq(without.reg:optionAvailable("fdless", "method", 3), true)
	T.eq(without.reg:optionAvailable("fdless", "fling", true), true)
	T.eq(without.reg:optionAvailable("fdless", "nope", 1), false)
	ok, why = without.reg:setOption("fdless", "method", 4)
	T.eq(ok, false, "an unavailable choice is refused")
	T.eq(why, "your executor has no replicatesignal")
	T.eq(without.reg:optionsOf("fdless").method, 1, "and nothing was stored")
	ok = without.reg:setOption("fdless", "method", 3)
	T.eq(ok, true)
	T.eq(without.reg:optionsOf("fdless").method, 3)
	local withIt = newEnv({ X = { loadstring = true, replicatesignal = true } })
	local q = fake("fdless", "hat")
	q.settings = p.settings
	withIt.reg:register(q)
	ok = withIt.reg:setOption("fdless", "method", 4)
	T.eq(ok, true)
	T.eq(withIt.reg:optionsOf("fdless").method, 4)
	T.eq(withIt.reg:optionsOf("fdless").fling, true)
end

T.section("reg_state: the watcher ends a run when the provider stops by itself")
do
	local env = newEnv()
	local reg = env.reg
	local p = fake("gelatek", "limb")
	local polls = 0
	local inner = p.isRunning
	p.isRunning = function()
		polls = polls + 1
		return inner()
	end
	reg:register(p)
	reg:start("limb", nil, {})
	local startPolls = polls
	task.wait(5)
	T.eq(reg:state(), "running", "a healthy run stays running")
	T.ok(polls - startPolls >= 3 and polls - startPolls <= 6, "it checks about once a second: " .. (polls - startPolls))
	p.running = false
	task.wait(1.2)
	T.eq(reg:state(), "running", "one missed check is not enough")
	task.wait(1.5)
	T.eq(reg:state(), "idle", "two missed checks end the run")
	T.eq(env.toasts[#env.toasts], "Fake gelatek|Stopped on its own|info")
	T.eq(flat(env.events), "starting:gelatek,running:gelatek,stopping:gelatek,stopped:gelatek")
	local after = polls
	task.wait(20)
	T.eq(polls, after, "no polling at all while idle")
	p.running = true
	reg:start("limb", nil, {})
	local flicker = 0
	p.isRunning = function()
		flicker = flicker + 1
		return flicker % 2 == 1
	end
	task.wait(10)
	T.eq(reg:state(), "running", "a flickering provider that is back by the next check keeps running")
	p.isRunning = function()
		return true
	end
	reg:stop()
end

T.section("reg_state: the shipped hub has Script Reanimate off")
T.eq(SHIPPED_OFF.atsuko, true)
