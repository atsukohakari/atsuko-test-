local Registry = loadmodule("Reanimation/providers/registry.lua")
local Controller = loadmodule("Hub/modules/reanim.lua")

local function fakeProvider(id, kind, over)
	local p = {
		AtsukoReanimProvider = true,
		id = id,
		kind = kind,
		name = "Fake " .. id,
		credit = "Someone",
		blurb = "A fake one for the tests",
		caps = { fdApi = kind == "hat", emotes = true, bodyCommands = false, fling = false, bullet = false, stoppable = true, respawnSafe = true, needsR6 = false },
		settings = {
			{ key = "mode", type = "choice", label = "Mode", options = { "Simple", "Fling" }, default = "Simple" },
		},
		running = false,
		calls = {},
	}
	p.available = function()
		return true
	end
	p.prepare = function(entry, run)
		p.calls[#p.calls + 1] = "prepare:" .. tostring(entry and entry.name)
		p.entry = entry
		return true
	end
	p.start = function(run)
		p.calls[#p.calls + 1] = "start"
		task.wait(0.2)
		p.running = true
		return true
	end
	p.stop = function()
		p.calls[#p.calls + 1] = "stop"
		p.running = false
		return true
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

local function newWorld(opts)
	opts = opts or {}
	local w = {
		S = { reanimSel = "", hatReanim = "atsuko", reanimLimb = "gelatek", reanimOpts = {} },
		saves = 0,
		fires = 0,
		toasts = {},
		logs = {},
		events = {},
		pending = {},
		active = {},
		errors = {},
		stoppedScripts = {},
		ran = {},
		entries = {},
		lumen = opts.lumen,
		names = {},
		slowStop = nil,
		scriptDelay = 0.5,
		scriptFails = false,
		scriptErrors = nil,
		activates = true,
	}
	w.atsuko = fakeProvider("atsuko", "hat")
	w.fdless = fakeProvider("fdless", "hat")
	w.gelatek = fakeProvider("gelatek", "limb", { stopWarning = "Stopping respawns you. Continue?" })
	w.uhhhhhh = fakeProvider("uhhhhhh", "limb")
	w.hatOf = function(path)
		local p = w.reg:activeProvider()
		return p
	end
	local R = {}
	w.R = R
	w.reg = Registry.new({
		S = w.S,
		save = function()
			w.saves = w.saves + 1
		end,
		fire = function(name, payload)
			w.events[#w.events + 1] = payload.state .. ":" .. tostring(payload.provider)
			R.onEvent(payload)
		end,
		notify = function(title, text, kind)
			w.toasts[#w.toasts + 1] = title .. "|" .. text .. "|" .. tostring(kind)
		end,
		wait = task.wait,
		spawn = task.spawn,
		delay = task.delay,
		now = time,
		settle = 0,
		log = function(level, text)
			w.logs[#w.logs + 1] = level .. ": " .. text
		end,
		startLimit = 10,
		stopLimit = 2,
	})
	w.reg:register(w.atsuko)
	w.reg:register(w.fdless)
	w.reg:register(w.gelatek)
	w.reg:register(w.uhhhhhh)
	local deps = {
		S = w.S,
		save = function()
			w.saves = w.saves + 1
		end,
		fire = function(name)
			w.fires = w.fires + 1
		end,
		notify = function(title, text, kind)
			w.toasts[#w.toasts + 1] = title .. "|" .. text .. "|" .. tostring(kind)
		end,
		wait = task.wait,
		now = time,
		spawn = task.spawn,
		alive = function()
			return not w.dead
		end,
		log = function(level, text)
			w.logs[#w.logs + 1] = level .. ": " .. text
		end,
		entryOf = function(path)
			return w.entries[path]
		end,
		scriptActive = function(path)
			return w.active[path] == true
		end,
		scriptPending = function(path)
			return w.pending[path] == true
		end,
		scriptAlive = function(path)
			return w.active[path] == true and w.errors[path] == nil
		end,
		scriptError = function(path)
			return w.errors[path]
		end,
		activePaths = function()
			local out = {}
			for path in pairs(w.active) do
				if w.entries[path] then
					out[#out + 1] = path
				end
			end
			table.sort(out)
			return out
		end,
		runScript = function(e)
			w.ran[#w.ran + 1] = e.path
			if w.active[e.path] then
				return
			end
			w.pending[e.path] = true
			task.delay(w.scriptDelay, function()
				w.pending[e.path] = nil
				if w.scriptFails then
					return
				end
				w.active[e.path] = true
				if w.scriptErrors then
					w.errors[e.path] = w.scriptErrors
				end
				if w.activates then
					local p = w.reg:activeProvider()
					if p then
						p.running = true
					end
				end
			end)
		end,
		stopScript = function(path, keep)
			w.stoppedScripts[#w.stoppedScripts + 1] = path
			if keep then
				w.kept = (w.kept or 0) + 1
			end
			w.pending[path] = nil
			w.errors[path] = nil
			if w.slowStop then
				task.delay(w.slowStop, function()
					w.active[path] = nil
				end)
			else
				w.active[path] = nil
			end
		end,
		nameOf = function(path)
			return (w.entries[path] and w.entries[path].name) or w.names[path]
		end,
		isNative = Controller.isNative,
		kindOf = function(e)
			if e.kindThrows then
				error("kind lookup broke")
			end
			return e.kindHint
		end,
		fdlessOf = function(e)
			return e.fdlessHint
		end,
		lumen = function()
			return w.lumen
		end,
	}
	w.deps = deps
	Controller.attach(R, deps)
	R.setRegistry(w.reg)
	local function entry(path, name, extra)
		local e = { path = path, name = name, category = "Hat", size = 1, ext = "lua" }
		for k, v in pairs(extra or {}) do
			e[k] = v
		end
		w.entries[path] = e
		return e
	end
	w.entry = entry
	w.native = entry("Scripts/Hat/DubstepGun.lua", "Dubstep Gun")
	w.third = entry("Scripts/Main/LastStar.lua", "Last Star")
	return w
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

local function toastWith(w, text)
	for _, t in ipairs(w.toasts) do
		if string.find(t, text, 1, true) then
			return t
		end
	end
	return nil
end

T.section("reanim_ctl: helpers")
T.eq(Controller.isSolo("@solo:gelatek"), true)
T.eq(Controller.isSolo("Scripts/Hat/A.lua"), false)
T.eq(Controller.isSolo(nil), false)
T.eq(Controller.soloId("@solo:gelatek"), "gelatek")
T.eq(Controller.soloId("x"), nil)
T.eq(Controller.isNative({ path = "Scripts/Hat/DubstepGun.lua" }), true)
T.eq(Controller.isNative({ path = "scripts/Hat/DubstepGun.lua" }), true)
T.eq(Controller.isNative({ path = "Scripts/Main/LastStar.lua" }), false)
T.eq(Controller.isNative({ path = "Scripts/Hat/Sub/Other.lua" }), true)
T.eq(Controller.isNative({ path = "Scripts/Hat/FDless/NeptunianV.lua" }), false, "the Main Scripts in the FDless folder run on FDless, they are not hub-native")
T.eq(Controller.isNative({ path = "scripts/Hat/fdless/NeptunianV.lua" }), false)
T.eq(Controller.isNative({ path = "Scripts/Hat/FDLESS/x.lua" }), false)
T.eq(Controller.isNative({ path = "Scripts/Hat/FDlessy/x.lua" }), true, "only the FDless folder itself")
T.eq(Controller.isNative({ path = "Scripts/Hat/StudioDummyV4-Test.lua", reanim = { "atsuko" } }), true)
T.eq(Controller.isNative({ path = "Scripts/Hat/Other.lua", reanim = { "fdless" } }), true, "the manifest list no longer decides it, only the folder")
T.eq(Controller.isNative({ path = "Scripts/Hat/Other.lua", reanim = { "atsuko", "fdless" } }), true)
T.eq(Controller.isNative({ path = "Scripts/Hat/FDless/x.lua", native = true }), true, "an entry can say it is one of the hub's own")
T.eq(Controller.isNative({ path = "Scripts/Hat/Other.lua", reanim = {} }), true)
T.eq(Controller.isNative({ path = "Scripts/Hat/Other.lua", reanim = "fdless" }), true, "a reanim that is not a list is ignored")
T.eq(Controller.isNative({ path = 5 }), false)
T.eq(Controller.isNative({ path = "MyScripts/Hat/X.lua" }), false)
T.eq(Controller.isNative(nil), false)
T.eq(Controller.isNative({}), false)

T.section("reanim_ctl: a fresh controller knows nothing is running")
do
	local w = newWorld()
	local R = w.R
	T.eq(R.current(), nil)
	T.eq(R.busy, nil)
	T.eq(R.on(), false)
	T.eq(R.provider(), nil)
	T.eq(R.entry("Scripts/Hat/DubstepGun.lua"), w.native)
	T.eq(R.entry("@solo:gelatek"), nil)
	T.eq(R.entry(""), nil)
	T.eq(R.entry(nil), nil)
	T.eq(R.name("Scripts/Hat/DubstepGun.lua"), "Dubstep Gun")
	T.eq(R.name("@solo:gelatek"), "Fake gelatek")
	T.eq(R.name("@solo:nothing"), "nothing")
	T.eq(R.name("Scripts/Gone.lua"), "?")
	T.eq(R.active("Scripts/Hat/DubstepGun.lua"), false)
	T.eq(R.active(nil), false)
	T.eq(R.active("@solo:gelatek"), false)
	R.select("Scripts/Hat/DubstepGun.lua")
	T.eq(w.S.reanimSel, "Scripts/Hat/DubstepGun.lua")
	T.eq(w.saves, 1)
	R.select("Scripts/Hat/DubstepGun.lua")
	T.eq(w.saves, 1, "selecting the same script saves nothing")
	R.select("@solo:gelatek")
	T.eq(w.S.reanimSel, "Scripts/Hat/DubstepGun.lua", "a standalone run is never a selection")
end

T.section("reanim_ctl: starting a script runs the whole chain")
do
	local w = newWorld()
	local R = w.R
	R.start(w.third)
	T.eq(R.busy, "starting")
	T.eq(R.current(), w.third.path, "the script is current while it starts")
	T.eq(w.S.reanimSel, w.third.path)
	task.wait(3)
	T.eq(R.busy, nil)
	T.eq(R.current(), w.third.path)
	T.eq(R.active(w.third.path), true)
	T.eq(R.provider().id, "atsuko", "the selected hat reanimate was used")
	T.eq(flat(w.events), "starting:atsuko,running:atsuko")
	T.eq(flat(w.atsuko.calls), "prepare:Last Star")
	T.eq(w.atsuko.entry.native, false)
	T.eq(w.atsuko.entry.path, w.third.path)
	T.eq(w.atsuko.entry.category, "Hat")
	T.eq(flat(w.ran), w.third.path)
	T.ok(w.fires >= 2, "the page is told")
	R.start(w.third)
	T.eq(toastWith(w, "Last Star|Already running|info") ~= nil, true, "starting it again says so")
	T.eq(#w.ran, 1, "and does not run it twice")
end

T.section("reanim_ctl: the entry carries the FDless hint and the real selected provider is used")
do
	local w = newWorld()
	w.S.hatReanim = "fdless"
	local e = w.entry("Scripts/Main/Hotline.lua", "The Hotline", { fdlessHint = "own" })
	w.R.start(e)
	task.wait(3)
	T.eq(w.R.provider().id, "fdless")
	T.eq(w.fdless.entry.fdless, "own")
	T.eq(w.fdless.entry.native, false)
end

T.section("reanim_ctl: the hub's own scripts follow the pick too")
do
	local w = newWorld()
	w.S.hatReanim = "fdless"
	w.R.start(w.native)
	task.wait(3)
	T.eq(w.R.provider().id, "fdless", "nothing forces them onto Script Reanimate anymore")
	T.eq(w.fdless.entry.native, true, "the provider still knows it is one of the hub's own")
	T.eq(flat(w.atsuko.calls), "")
	T.eq(toastWith(w, "This script runs on"), nil, "nothing needs saying")
end
do
	local w = newWorld()
	w.S.hatReanim = "atsuko"
	w.R.start(w.native)
	task.wait(3)
	T.eq(w.R.provider().id, "atsuko")
	T.eq(w.atsuko.entry.native, true)
end

T.section("reanim_ctl: nothing is picked until the player picks")
do
	local w = newWorld()
	w.S.hatReanim = ""
	T.eq(w.reg:selected("hat"), nil, "no hat reanimation is picked for you")
	T.eq(w.reg:mustPick("hat"), true)
	T.eq(w.reg:mustPick("limb"), false, "the limb one still has Gelatek")
	T.eq(w.reg:selected("limb").id, "gelatek")
	T.eq(w.R.needsPick("hat"), true)
	w.R.start(w.third)
	task.wait(1)
	T.eq(w.reg:state(), "idle", "starting a hat script does nothing yet")
	T.eq(#w.ran, 0)
	T.eq(w.R.busy, nil)
	T.ok(toastWith(w, "Reanimation|Pick Script Reanimate or FDless first, at the top of the Hat tab|info") ~= nil, flat(w.toasts))
	T.eq(w.S.reanimSel, w.third.path, "the script stays selected for when you have picked")
end
do
	local w = newWorld()
	w.S.hatReanim = ""
	local asked = {}
	w.deps.pick = function(kind, after)
		asked[#asked + 1] = { kind = kind, after = after }
		return true
	end
	w.R.start(w.third)
	T.eq(#asked, 1, "the hub is asked to show the pick window")
	T.eq(asked[1].kind, "hat")
	T.eq(toastWith(w, "Pick Script Reanimate or FDless first"), nil, "and no toast, the window says it")
	T.eq(#w.ran, 0)
	local ok = w.reg:select("hat", "fdless")
	T.eq(ok, true)
	T.eq(w.S.hatReanim, "fdless")
	asked[1].after()
	task.wait(3)
	T.eq(w.R.provider().id, "fdless", "after the pick the script starts on it")
	T.eq(flat(w.ran), w.third.path)
	T.eq(w.R.needsPick("hat"), false)
end
do
	local w = newWorld()
	w.S.hatReanim = ""
	w.deps.pick = function()
		return false
	end
	w.R.start(w.third)
	T.ok(toastWith(w, "Pick Script Reanimate or FDless first") ~= nil, "a pick window that can't open falls back to the toast")
end
do
	local w = newWorld()
	w.S.hatReanim = ""
	w.deps.pick = function()
		error("the window broke")
	end
	w.R.start(w.third)
	T.ok(toastWith(w, "Pick Script Reanimate or FDless first") ~= nil, "and so does one that throws")
end
do
	local w = newWorld()
	w.S.hatReanim = ""
	local asked = 0
	w.deps.pick = function(kind, after)
		asked += 1
		return true
	end
	w.R.startSolo("hat")
	T.eq(asked, 1, "Reanimate with no script asks too")
	T.eq(w.reg:state(), "idle")
	w.R.startSolo("limb")
	task.wait(2)
	T.eq(asked, 1, "the limb one never asks")
	T.eq(w.reg:activeProvider().id, "gelatek")
end
do
	local w = newWorld()
	w.S.hatReanim = ""
	local e = w.entry("Scripts/Hat/FDless/OnlyFD.lua", "Only FD", { reanim = { "fdless" } })
	w.R.start(e)
	task.wait(3)
	T.eq(w.R.provider().id, "fdless", "a script that lists one reanimation needs no pick")
	T.ok(toastWith(w, "Only FD|This script runs on " .. w.fdless.name .. "|info") ~= nil, flat(w.toasts))
end
do
	local w = newWorld()
	w.S.hatReanim = ""
	local e = w.entry("Scripts/Hat/FDless/Both.lua", "Both", { reanim = { "atsuko", "fdless" } })
	w.R.start(e)
	task.wait(1)
	T.eq(#w.ran, 0, "a script that lists both still needs the pick")
end
do
	local w = newWorld()
	w.S.hatReanim = ""
	local ok, why = w.reg:start("hat", { path = "x", name = "x" }, {})
	T.eq(ok, false)
	T.eq(why, "Pick Script Reanimate or FDless first, at the top of the Hat tab", "the registry itself refuses too")
	T.eq(w.reg:state(), "idle")
	w.S.hatReanim = "nope"
	T.eq(w.reg:selected("hat"), nil, "a pick that does not exist counts as no pick")
end

T.section("reanim_ctl: a script the manifest ties to FDless runs on FDless whatever is selected")
do
	local w = newWorld()
	w.S.hatReanim = "atsuko"
	local e = w.entry("Scripts/Hat/FDless/NeptunianV.lua", "Neptunian V", { reanim = { "fdless" } })
	w.R.start(e)
	task.wait(3)
	T.eq(w.R.provider().id, "fdless")
	T.eq(w.S.hatReanim, "atsuko", "the choice itself is not changed")
	T.eq(flat(w.atsuko.calls), "")
	T.ok(toastWith(w, "Neptunian V|This script runs on " .. w.fdless.name .. "|info") ~= nil, "the player is told: " .. flat(w.toasts))
	T.eq(w.fdless.entry.native, false)
	T.eq(flat(w.ran), e.path)
end
do
	local w = newWorld()
	w.S.hatReanim = "fdless"
	local e = w.entry("Scripts/Hat/FDless/Both.lua", "Both", { reanim = { "atsuko", "fdless" } })
	w.R.start(e)
	task.wait(3)
	T.eq(w.R.provider().id, "fdless", "a script that can use either follows the choice")
	T.eq(toastWith(w, "This script runs on"), nil, "and nothing needs saying")
end
do
	local w = newWorld()
	w.S.hatReanim = "atsuko"
	local e = w.entry("Scripts/Hat/FDless/Both.lua", "Both", { reanim = { "fdless", "atsuko" } })
	w.R.start(e)
	task.wait(3)
	T.eq(w.R.provider().id, "atsuko")
	T.eq(toastWith(w, "This script runs on"), nil)
end
do
	local w = newWorld()
	w.S.hatReanim = "fdless"
	local e = w.entry("Scripts/Main/AtsukoOnly.lua", "Atsuko Only", { reanim = { "atsuko" } })
	w.R.start(e)
	task.wait(3)
	T.eq(w.R.provider().id, "atsuko")
	T.ok(toastWith(w, "Atsuko Only|This script runs on " .. w.atsuko.name .. "|info") ~= nil, flat(w.toasts))
end
do
	local w = newWorld()
	w.S.hatReanim = "atsuko"
	local e = w.entry("Scripts/Main/Odd.lua", "Odd", { reanim = { 5, true, "fdless" } })
	w.R.start(e)
	task.wait(3)
	T.eq(w.R.provider().id, "fdless", "entries that are not ids are skipped")
end
for index, reanim in ipairs({ {}, { "gelatek" }, { "uhhhhhh", "nothing" }, "fdless", 7 }) do
	local w = newWorld()
	w.S.hatReanim = "atsuko"
	local e = w.entry("Scripts/Main/Plain" .. index .. ".lua", "Plain" .. index, { reanim = reanim })
	w.R.start(e)
	task.wait(3)
	T.eq(w.R.provider().id, "atsuko", "no usable hat reanimation listed, so the choice is used (" .. index .. ")")
	T.eq(toastWith(w, "This script runs on"), nil)
end
do
	local w = newWorld()
	w.S.hatReanim = "atsuko"
	w.reg.providers.fdless = nil
	w.reg:markFailed("fdless", "no connection")
	local e = w.entry("Scripts/Hat/FDless/NeptunianV.lua", "Neptunian V", { reanim = { "fdless" } })
	w.R.start(e)
	task.wait(3)
	T.eq(w.reg:state(), "idle")
	T.eq(w.R.current(), nil)
	T.eq(w.R.busy, nil)
	T.eq(#w.ran, 0, "the script is not run on the wrong reanimation")
end

T.section("reanim_ctl: a script that does not start fails cleanly")
do
	local w = newWorld()
	w.scriptFails = true
	w.R.start(w.third)
	task.wait(5)
	T.eq(w.R.busy, nil, "nothing is left half done")
	T.eq(w.R.current(), nil)
	T.eq(w.R.run, nil)
	T.eq(w.R.starting, nil)
	T.eq(w.reg:state(), "idle")
	T.ok(toastWith(w, "Couldn't start: the script did not start") ~= nil, "the reason is shown: " .. flat(w.toasts))
	w.scriptFails = false
	w.R.start(w.third)
	task.wait(3)
	T.eq(w.R.current(), w.third.path, "and a second try works")
end

T.section("reanim_ctl: a script that throws is named in the message")
do
	local w = newWorld()
	w.scriptErrors = "attempt to index nil\nstack"
	w.R.start(w.third)
	task.wait(5)
	T.ok(toastWith(w, "the script hit an error: attempt to index nil") ~= nil, flat(w.toasts))
	T.eq(w.R.busy, nil)
	T.eq(w.reg:state(), "idle")
	T.eq(w.active[w.third.path], nil, "the broken script was stopped")
end

T.section("reanim_ctl: a script that never reanimates times out")
do
	local w = newWorld()
	w.activates = false
	w.R.start(w.third)
	task.wait(60)
	T.eq(w.R.busy, nil)
	T.eq(w.reg:state(), "idle")
	T.ok(toastWith(w, "Couldn't start") ~= nil, flat(w.toasts))
	T.eq(w.active[w.third.path], nil, "the script is stopped when the start fails")
end

T.section("reanim_ctl: stopping")
do
	local w = newWorld()
	local R = w.R
	R.start(w.third)
	task.wait(3)
	w.toasts = {}
	R.stop()
	T.eq(R.busy, "stopping")
	task.wait(3)
	T.eq(R.busy, nil)
	T.eq(R.current(), nil)
	T.eq(R.path, nil)
	T.eq(R.run, nil)
	T.eq(flat(w.events), "starting:atsuko,running:atsuko,stopping:atsuko,stopped:atsuko")
	T.eq(w.stoppedScripts[#w.stoppedScripts], w.third.path)
	T.eq(w.active[w.third.path], nil)
	T.ok(toastWith(w, "Last Star|Deanimated|info") ~= nil)
	R.stop()
	T.eq(R.busy, nil, "stopping nothing does nothing")
end

T.section("reanim_ctl: nothing selected starts the chosen reanimate alone")
do
	local w = newWorld()
	local R = w.R
	R.toggle()
	T.eq(R.busy, "starting")
	task.wait(3)
	T.eq(R.busy, nil)
	T.eq(R.current(), "@solo:atsuko")
	T.eq(R.name(R.current()), "Fake atsuko")
	T.eq(R.active("@solo:atsuko"), true)
	T.eq(#w.ran, 0, "no script was run")
	T.eq(flat(w.atsuko.calls), "start")
	R.toggle()
	task.wait(3)
	T.eq(R.current(), nil)
	T.eq(w.reg:state(), "idle")
	T.eq(R.busy, nil)
end

T.section("reanim_ctl: toggle with a script selected")
do
	local w = newWorld()
	local R = w.R
	R.select(w.third.path)
	R.toggle()
	task.wait(3)
	T.eq(R.current(), w.third.path)
	R.toggle(w.third)
	task.wait(3)
	T.eq(R.current(), nil)
	R.toggle(w.third)
	task.wait(3)
	T.eq(R.current(), w.third.path)
	w.toasts = {}
	R.toggle(w.native)
	T.eq(R.busy, "switching", "another script switches over instead of asking to deanimate")
	task.wait(3)
	T.eq(R.current(), w.native.path)
	T.eq(toastWith(w, "Deanimate"), nil, flat(w.toasts))
	T.ok(toastWith(w, "Switched from Last Star, still reanimated") ~= nil, flat(w.toasts))
	T.eq(w.S.reanimSel, w.native.path, "the switched script becomes the selected one")
	R.toggle()
	task.wait(3)
	T.eq(R.current(), nil)
end

T.section("reanim_ctl: switching scripts keeps you reanimated")
do
	local w = newWorld()
	local R = w.R
	T.eq(R.canSwitch(w.native), false, "nothing to switch from yet")
	R.start(w.third)
	task.wait(3)
	T.eq(R.current(), w.third.path)
	T.eq(R.canSwitch(w.third), false, "the running one can't switch to itself")
	T.eq(R.canSwitch(w.native), true)
	w.events = {}
	w.toasts = {}
	local stops = #w.atsuko.calls
	R.start(w.native)
	T.eq(R.busy, "switching")
	T.eq(R.starting, w.native.path)
	R.toggle(w.third)
	T.eq(R.busy, "switching", "taps while switching are ignored")
	task.wait(3)
	T.eq(R.busy, nil)
	T.eq(R.current(), w.native.path)
	T.eq(flat(w.events), "starting:atsuko,running:atsuko", "the reanimation never stops in between")
	T.eq(count(w.atsuko.calls, "stop"), 0, "the reanimation was not stopped")
	T.eq(count(w.atsuko.calls, "reset"), 0)
	T.eq(w.atsuko.calls[#w.atsuko.calls], "prepare:Dubstep Gun", "the new script was handed to the running reanimation")
	T.ok(#w.atsuko.calls > stops)
	T.eq(w.stoppedScripts[#w.stoppedScripts], w.third.path, "the old script was stopped")
	T.eq(w.kept, 1, "without a respawn")
	T.eq(w.active[w.third.path], nil)
	T.eq(w.active[w.native.path], true)
	T.eq(w.reg:state(), "running")
	T.eq(#w.toasts, 1, "one toast for the switch: " .. flat(w.toasts))
	R.toggle()
	task.wait(3)
	T.eq(R.current(), nil, "deanimating still works afterwards")
	T.eq(count(w.atsuko.calls, "stop"), 1)
end

T.section("reanim_ctl: what can't switch")
do
	local w = newWorld()
	local R = w.R
	R.start(w.third)
	task.wait(3)
	local limb = w.entry("Scripts/Limb/Kick.lua", "Kick", { kindHint = "limb" })
	T.eq(R.canSwitch(limb), false, "a limb script needs its own reanimation")
	local other = w.entry("Scripts/Hat/Only.lua", "Only FDless", { reanim = { "fdless" } })
	T.eq(R.canSwitch(other), false, "a script locked to another reanimation can't hot swap")
	w.toasts = {}
	R.toggle(limb)
	T.ok(toastWith(w, "Deanimate Last Star first") ~= nil, flat(w.toasts))
	T.eq(R.current(), w.third.path)
	local same = w.entry("Scripts/Hat/Fine.lua", "Fine", { reanim = { "atsuko", "fdless" } })
	T.eq(R.canSwitch(same), true, "a script that runs on the current one can")
	R.toggle()
	task.wait(3)
end

T.section("reanim_ctl: a switch that fails leaves you clean")
do
	local w = newWorld()
	local R = w.R
	R.start(w.third)
	task.wait(3)
	w.scriptFails = true
	w.toasts = {}
	R.switch(w.native)
	task.wait(3)
	T.eq(R.busy, nil)
	T.eq(R.current(), nil, "nothing half running")
	T.eq(w.reg:state(), "idle")
	T.eq(w.atsuko.running, false, "the reanimation was stopped after the failure")
	T.ok(toastWith(w, "Couldn't start") ~= nil, flat(w.toasts))
	T.eq(toastWith(w, "Couldn't switch"), nil, "only one error toast")
end

T.section("reanim_ctl: a limb reanimate on its own")
do
	local w = newWorld()
	local R = w.R
	R.startSolo("limb")
	task.wait(3)
	T.eq(R.current(), "@solo:gelatek")
	T.eq(R.provider().id, "gelatek")
	T.eq(flat(w.events), "starting:gelatek,running:gelatek")
	w.toasts = {}
	R.startSolo("hat")
	T.ok(toastWith(w, "Deanimate Fake gelatek first") ~= nil, "only one at a time: " .. flat(w.toasts))
	R.toggle(w.third)
	T.ok(toastWith(w, "Deanimate Fake gelatek first") ~= nil)
	T.eq(w.reg:state(), "running")
end

T.section("reanim_ctl: stopping Gelatek asks first and a second tap says yes")
do
	local w = newWorld()
	local R = w.R
	R.startSolo("limb")
	task.wait(3)
	R.stop()
	T.eq(R.busy, "asking", "the button is waiting for a second tap")
	T.ok(R.asking ~= nil)
	T.eq(R.asking.text, "Stopping respawns you. Continue?")
	T.eq(R.asking.name, "Fake gelatek")
	T.eq(w.reg:state(), "running", "nothing stops before the answer")
	T.eq(w.gelatek.running, true)
	R.toggle()
	task.wait(3)
	T.eq(R.asking, nil)
	T.eq(R.busy, nil)
	T.eq(R.current(), nil)
	T.eq(w.reg:state(), "idle")
	T.eq(w.gelatek.running, false)
end

T.section("reanim_ctl: the second tap can also come through stop")
do
	local w = newWorld()
	local R = w.R
	R.startSolo("limb")
	task.wait(3)
	R.stop()
	T.eq(R.busy, "asking")
	R.stop()
	task.wait(3)
	T.eq(R.busy, nil)
	T.eq(w.reg:state(), "idle")
end

T.section("reanim_ctl: no second tap means it keeps running")
do
	local w = newWorld()
	local R = w.R
	R.startSolo("limb")
	task.wait(3)
	w.toasts = {}
	R.stop()
	T.eq(R.busy, "asking")
	task.wait(Controller.ASK_SECONDS + 2)
	T.eq(R.asking, nil)
	T.eq(R.busy, nil)
	T.eq(w.reg:state(), "running")
	T.eq(w.gelatek.running, true)
	T.eq(R.current(), "@solo:gelatek")
	T.eq(toastWith(w, "Deanimated"), nil, "no stopped toast")
	T.eq(count(w.gelatek.calls, "stop"), 0)
	R.stop()
	R.stop()
	task.wait(3)
	T.eq(w.reg:state(), "idle", "asking again works")
end

T.section("reanim_ctl: a typed command does not ask")
do
	local w = newWorld()
	local R = w.R
	R.startSolo("limb")
	task.wait(3)
	R.stop("command")
	T.eq(R.busy, "stopping")
	task.wait(3)
	T.eq(w.reg:state(), "idle")
	T.eq(R.asking, nil)
end

T.section("reanim_ctl: a script asking to stop does not ask either")
do
	local w = newWorld()
	local R = w.R
	R.startSolo("limb")
	task.wait(3)
	T.eq(w.reg:state(), "running")
	R.stop("script")
	T.eq(R.busy, "stopping")
	task.wait(3)
	T.eq(w.reg:state(), "idle")
	T.eq(R.asking, nil)
end

T.section("reanim_ctl: a provider with no warning is stopped at once")
do
	local w = newWorld()
	w.S.reanimLimb = "uhhhhhh"
	w.R.startSolo("limb")
	task.wait(3)
	w.R.stop()
	T.eq(w.R.busy, "stopping")
	task.wait(3)
	T.eq(w.reg:state(), "idle")
end

T.section("reanim_ctl: taps while busy are ignored")
do
	local w = newWorld()
	local R = w.R
	R.start(w.third)
	T.eq(R.busy, "starting")
	R.start(w.native)
	R.toggle()
	R.stop()
	R.startSolo("limb")
	task.wait(3)
	T.eq(#w.ran, 1)
	T.eq(R.current(), w.third.path)
	T.eq(w.reg:state(), "running")
end

T.section("reanim_ctl: a script that ends by itself clears the controller")
do
	local w = newWorld()
	local R = w.R
	R.start(w.third)
	task.wait(3)
	T.eq(R.current(), w.third.path)
	w.atsuko.running = false
	task.wait(4)
	T.eq(w.reg:state(), "idle")
	T.eq(R.run, nil)
	T.eq(R.path, nil)
	T.eq(R.current(), nil)
	T.eq(R.busy, nil)
end

T.section("reanim_ctl: scripts that were run outside the registry are still found and stopped")
do
	local w = newWorld({ lumen = nil })
	local R = w.R
	w.active[w.third.path] = true
	T.eq(R.current(), w.third.path, "found by scanning the running scripts")
	local lumen = {
		live = true,
		isReanimated = function(self)
			return self.live
		end,
		stopreanimate = function()
		end,
	}
	local stops = 0
	local L = {
		isReanimated = function()
			return lumen.live
		end,
		stopreanimate = function()
			stops = stops + 1
			lumen.live = false
		end,
	}
	w.lumen = L
	T.eq(R.on(), true)
	R.stop()
	T.eq(R.busy, "stopping")
	task.wait(10)
	T.eq(R.busy, nil)
	T.eq(w.active[w.third.path], nil, "the script was stopped")
	T.eq(stops, 1, "and the library was told to stop because it stayed on")
	T.eq(R.current(), nil)
end

T.section("reanim_ctl: stopping with no script and no registry run stops a lingering library")
do
	local w = newWorld()
	local stops = 0
	local live = true
	w.lumen = {
		isReanimated = function()
			return live
		end,
		stopreanimate = function()
			stops = stops + 1
			live = false
		end,
	}
	w.R.stop()
	T.eq(stops, 1)
	T.eq(w.R.busy, nil)
end

T.section("reanim_ctl: before the registry exists")
do
	local w = newWorld()
	w.R.reg = nil
	w.R.start(w.third)
	T.ok(toastWith(w, "Still getting ready") ~= nil)
	T.eq(w.R.busy, nil)
	w.toasts = {}
	w.R.loadError = "couldn't find Reanimation/providers/registry.lua"
	w.R.start(w.third)
	T.eq(w.toasts[1], "Reanimation|Couldn't load: couldn't find Reanimation/providers/registry.lua|error")
	w.toasts = {}
	w.R.startSolo("limb")
	T.eq(w.toasts[1], "Reanimation|Couldn't load: couldn't find Reanimation/providers/registry.lua|error")
	T.eq(w.R.busy, nil)
end

T.section("reanim_ctl: an unexpected error in the registry does not wedge the buttons")
do
	local w = newWorld()
	local R = w.R
	local real = w.reg.start
	w.reg.start = function()
		error("internal trouble\nmore", 0)
	end
	R.start(w.third)
	task.wait(2)
	T.eq(R.busy, nil)
	T.eq(R.starting, nil)
	T.eq(R.run, nil)
	T.ok(toastWith(w, "Couldn't start: internal trouble") ~= nil, flat(w.toasts))
	T.ok(#w.logs >= 1)
	w.reg.start = real
	R.start(w.third)
	task.wait(3)
	T.eq(R.current(), w.third.path, "everything works again afterwards")
	local realStop = w.reg.stop
	w.toasts = {}
	w.reg.stop = function()
		error("stop trouble", 0)
	end
	R.stop()
	task.wait(2)
	T.eq(R.busy, nil)
	T.ok(toastWith(w, "Couldn't stop it: stop trouble") ~= nil, flat(w.toasts))
	w.reg.stop = realStop
end

T.section("reanim_ctl: shutting down")
do
	local w = newWorld()
	w.R.start(w.third)
	task.wait(3)
	w.R.shutdown()
	T.eq(w.R.reg, nil)
	T.eq(w.atsuko.running, false, "the running reanimate was stopped")
	w.toasts = {}
	w.R.start(w.native)
	T.ok(toastWith(w, "Still getting ready") ~= nil)
end

T.section("reanim_ctl: a dead hub ends the waits")
do
	local w = newWorld()
	w.R.startSolo("limb")
	task.wait(3)
	w.R.stop()
	T.eq(w.R.busy, "asking")
	w.dead = true
	task.wait(1)
	T.eq(w.R.asking, nil, "the question is dropped when the hub is gone")
	T.eq(w.reg:state(), "running")
end

T.section("reanim_ctl: option and selection events do not wipe the running state")
do
	local w = newWorld()
	local R = w.R
	R.start(w.third)
	task.wait(3)
	w.reg:select("hat", "fdless")
	w.reg:setOption("atsuko", "mode", "Fling")
	T.eq(R.current(), w.third.path)
	R.onEvent({ state = "stopped", option = "mode" })
	R.onEvent({ state = "stopped", selected = "fdless" })
	R.onEvent(nil)
	R.onEvent({ state = "running" })
	T.eq(R.run ~= nil, true)
	R.busy = "stopping"
	R.onEvent({ state = "stopped" })
	T.eq(R.run ~= nil, true, "while busy the controller clears things itself")
	R.busy = nil
	R.onEvent({ state = "stopped" })
	T.eq(R.run, nil)
	T.eq(R.path, nil)
end

local function bootFixtures(over)
	over = over or {}
	local seen = {}
	local b = {
		registryOptions = {
			S = { reanimOpts = {} },
			notify = function() end,
			wait = task.wait,
			spawn = task.spawn,
			delay = task.delay,
			now = time,
			settle = 0,
		},
		providerCtx = { marker = "provider ctx" },
		log = function(level, text)
			seen[#seen + 1] = level .. ": " .. text
		end,
		loadModule = function(name, ctx)
			seen[#seen + 1] = "load " .. name .. (ctx and " with ctx" or "")
			if over.fail and over.fail[name] then
				return nil, over.fail[name]
			end
			if name == "@Reanimation/providers/registry" then
				return Registry
			end
			local id = string.match(name, "providers/(%a+)$")
			local isHat = id == "atsuko" or id == "fdless"
			local p = fakeProvider(id, isHat and "hat" or "limb")
			if over.broken and over.broken[id] then
				p.start = nil
			end
			return p
		end,
	}
	return b, seen
end

T.section("reanim_ctl: boot loads the registry and every provider")
do
	local w = newWorld()
	local R = {}
	Controller.attach(R, w.deps)
	local b, seen = bootFixtures()
	local ok, loaded = Controller.boot(R, b)
	T.eq(ok, true)
	T.eq(loaded, 4)
	T.ok(R.reg ~= nil)
	T.eq(R.loadError, nil)
	T.eq(seen[1], "load @Reanimation/providers/registry")
	T.eq(seen[2], "load @Reanimation/providers/atsuko with ctx")
	T.eq(seen[3], "load @Reanimation/providers/fdless with ctx")
	T.eq(seen[4], "load @Reanimation/providers/gelatek with ctx")
	T.eq(seen[5], "load @Reanimation/providers/uhhhhhh with ctx")
	T.eq(#R.reg:list(), 4)
	T.eq(#R.reg:slots("hat"), 2)
	T.eq(type(R.reg.confirm), "function", "the question hook is installed")
end

T.section("reanim_ctl: boot keeps going when one provider will not load")
do
	local w = newWorld()
	local R = {}
	Controller.attach(R, w.deps)
	local b = bootFixtures({ fail = { ["@Reanimation/providers/uhhhhhh"] = "couldn't download it\nmore" }, broken = { fdless = true } })
	local ok, loaded = Controller.boot(R, b)
	T.eq(ok, true)
	T.eq(loaded, 2, "atsuko and gelatek loaded")
	local slots = R.reg:slots()
	T.eq(slots[2].id, "fdless")
	T.eq(slots[2].failed ~= nil, true, "the invalid provider is marked failed")
	T.ok(string.find(slots[2].failed, "start must be a function", 1, true), slots[2].failed)
	T.eq(slots[4].failed, "couldn't download it", "the missing one says why, on one line")
	T.eq(R.reg:slots("limb")[2].provider, nil)
	local selOk, selWhy = R.reg:select("limb", "uhhhhhh")
	T.eq(selOk, false)
	T.ok(string.find(selWhy, "couldn't load Uhhhhhh", 1, true))
end

T.section("reanim_ctl: boot reports a missing registry")
do
	local w = newWorld()
	local R = {}
	Controller.attach(R, w.deps)
	local b, seen = bootFixtures({ fail = { ["@Reanimation/providers/registry"] = "couldn't find Reanimation/providers/registry.lua inside Atsuko Hub\nmore" } })
	local ok, why = Controller.boot(R, b)
	T.eq(ok, false)
	T.eq(why, "couldn't find Reanimation/providers/registry.lua inside Atsuko Hub")
	T.eq(R.loadError, why)
	T.eq(R.reg, nil)
	T.eq(#seen, 2, "no providers are tried without the registry")
	T.ok(string.find(seen[2], "reanimation: couldn't find", 1, true))
	local bad = bootFixtures()
	bad.loadModule = function()
		return { notARegistry = true }
	end
	ok, why = Controller.boot(R, bad)
	T.eq(ok, false)
	T.eq(why, "couldn't load the reanimation files")
end

T.section("reanim_ctl: a tap late in the window still counts, and one after it does not")
do
	local w = newWorld()
	local R = w.R
	R.startSolo("limb")
	task.wait(3)
	R.stop()
	task.wait(Controller.ASK_SECONDS - 1)
	T.eq(R.busy, "asking", "still waiting after most of the window")
	R.stop()
	task.wait(3)
	T.eq(w.reg:state(), "idle")

	R.startSolo("limb")
	task.wait(3)
	R.stop()
	task.wait(Controller.ASK_SECONDS + 0.5)
	T.eq(R.busy, nil)
	R.stop()
	T.eq(R.busy, "asking", "a tap after the window starts a new question instead")
	task.wait(Controller.ASK_SECONDS + 1)
	T.eq(w.reg:state(), "running")
end

T.section("reanim_ctl: a script that dies while the reanimate is starting fails fast")
do
	local w = newWorld()
	w.activates = false
	w.R.start(w.third)
	task.wait(2)
	T.eq(w.active[w.third.path], true, "the script itself is running")
	T.eq(w.R.busy, "starting")
	w.active[w.third.path] = nil
	task.wait(1)
	T.eq(w.R.busy, nil)
	T.eq(w.reg:state(), "idle")
	T.ok(toastWith(w, "the script stopped before it reanimated") ~= nil, flat(w.toasts))
end

T.section("reanim_ctl: a stop that finds nothing registered still calls the script stop")
do
	local w = newWorld()
	w.active[w.third.path] = true
	w.R.stop()
	task.wait(8)
	T.eq(flat(w.stoppedScripts), w.third.path)
	T.eq(w.R.busy, nil)
	T.ok(toastWith(w, "Last Star|Deanimated|info") ~= nil)
end

T.section("reanim_ctl: the kind of a standalone start is checked")
do
	local w = newWorld()
	w.R.startSolo("anything")
	task.wait(3)
	T.eq(w.R.provider().id, "atsuko", "an unknown kind means hat")
	w.R.stop()
	task.wait(3)
	w.S.hatReanim = "fdless"
	w.R.startSolo("hat")
	task.wait(3)
	T.eq(w.R.provider().id, "fdless", "the selected hat reanimate is used")
	T.eq(w.R.current(), "@solo:fdless")
end

T.section("reanim_ctl: the question window has a sensible length")
T.ok(Controller.ASK_SECONDS >= 3 and Controller.ASK_SECONDS <= 8, "about as long as the hub's other tap-again prompts")
T.ok(Controller.STOP_WAIT >= 3, "a script gets a few seconds to stop")

T.section("reanim_ctl: ids that look like standalone runs are never scripts")
do
	local w = newWorld()
	w.entries["@solo:atsuko"] = { path = "@solo:atsuko", name = "Not a script" }
	T.eq(w.R.entry("@solo:atsuko"), nil)
	T.eq(w.R.name("@solo:atsuko"), "Fake atsuko", "and the name is the provider's")
end

T.section("reanim_ctl: active tells the standalone runs apart")
do
	local w = newWorld()
	local R = w.R
	R.startSolo("hat")
	task.wait(3)
	T.eq(R.active("@solo:atsuko"), true)
	T.eq(R.active("@solo:gelatek"), false, "another provider's id is not active")
	w.active[w.third.path] = true
	w.pending[w.third.path] = true
	T.eq(R.active(w.third.path), false, "a script that is still starting is not active yet")
	w.pending[w.third.path] = nil
	T.eq(R.active(w.third.path), true)
end

T.section("reanim_ctl: on follows the library and survives a library that throws")
do
	local w = newWorld()
	w.lumen = {
		isReanimated = function()
			return false
		end,
	}
	T.eq(w.R.on(), false, "present but not reanimated")
	w.lumen = {
		isReanimated = function()
			return true
		end,
	}
	T.eq(w.R.on(), true)
	w.lumen = {
		isReanimated = function()
			error("gone")
		end,
	}
	T.eq(w.R.on(), false, "a library that throws counts as off")
	w.lumen = { notALibrary = true }
	T.eq(w.R.on(), false)
	T.eq(w.R.lumen(), nil)
end

T.section("reanim_ctl: current drops a run that is no longer true")
do
	local w = newWorld()
	local R = w.R
	R.start(w.third)
	task.wait(3)
	T.eq(R.path, w.third.path, "the path is remembered")
	w.active[w.third.path] = nil
	T.eq(R.current(), nil, "the script stopped behind the controller's back")
	T.eq(R.run, nil, "so the old run is forgotten")
	R.run = nil
	w.reg:stop("script ended", true)
	task.wait(1)

	R.startSolo("hat")
	task.wait(3)
	T.eq(R.run.id, "atsuko")
	local stale = R.run
	w.reg:stop("test", true)
	w.reg:start("limb", nil, {})
	T.eq(w.reg:activeProvider().id, "gelatek")
	R.run = stale
	T.eq(R.current(), nil, "an old atsuko run is not mistaken for the gelatek one")
	T.eq(R.run, nil)
end

T.section("reanim_ctl: names come from the running record when the entry is gone")
do
	local w = newWorld()
	w.names["Scripts/Gone.lua"] = "Gone Script"
	T.eq(w.R.name("Scripts/Gone.lua"), "Gone Script")
end

T.section("reanim_ctl: a second question while one is open is refused")
do
	local w = newWorld()
	w.R.asking = { text = "first" }
	T.eq(w.R.ask("second", nil), false)
	T.eq(w.R.asking.text, "first", "the open question is untouched")
	w.R.asking = nil
end

T.section("reanim_ctl: the button goes back to stopping after the answer")
do
	local w = newWorld()
	local R = w.R
	R.startSolo("limb")
	task.wait(3)
	R.stop()
	T.eq(R.busy, "asking")
	R.stop()
	task.wait(0.15)
	T.eq(R.busy, "stopping", "busy again while the stop finishes, so nothing else can start")
	task.wait(3)
	T.eq(R.busy, nil)
end

T.section("reanim_ctl: stopNow only touches scripts and waits for them")
do
	local w = newWorld()
	w.R.stopNow("@solo:gelatek")
	w.R.stopNow(nil)
	T.eq(#w.stoppedScripts, 0, "a standalone run has no script to stop")
	w.active[w.third.path] = true
	w.slowStop = 2
	local t0 = time()
	w.R.stopNow(w.third.path)
	T.ok(time() - t0 >= 1.9, "it waited for the script to go")
	T.eq(w.active[w.third.path], nil)
end

T.section("reanim_ctl: stopNow leaves the library to the provider during a registry stop")
do
	local w = newWorld()
	local stops = 0
	local live = true
	w.lumen = {
		isReanimated = function()
			return live
		end,
		stopreanimate = function()
			stops = stops + 1
		end,
	}
	w.R.start(w.third)
	task.wait(3)
	w.R.stop()
	task.wait(8)
	T.eq(stops, 0, "the controller did not stop the library itself")
	T.eq(w.reg:state(), "idle")
end

T.section("reanim_ctl: a registry that fails halfway is put back to idle")
do
	local w = newWorld()
	local R = w.R
	local real = w.reg.start
	w.reg.start = function(self, kind, entry, ctl)
		self.cur = "starting"
		self.activeId = "atsuko"
		error("half done", 0)
	end
	R.start(w.third)
	task.wait(3)
	T.eq(w.reg:state(), "idle", "the forced stop cleaned up")
	T.eq(R.busy, nil)
	w.reg.start = real
	R.start(w.third)
	task.wait(3)
	T.eq(R.current(), w.third.path, "and the next start works")
end

T.section("reanim_ctl: a refused tap while busy changes nothing")
do
	local w = newWorld()
	local R = w.R
	R.start(w.third)
	R.start(w.native)
	T.eq(w.S.reanimSel, w.third.path, "the selection was not moved by the ignored tap")
	task.wait(3)
	T.eq(R.path, w.third.path)
end

T.section("reanim_ctl: a failed start after a switch leaves no stale run")
do
	local w = newWorld()
	local R = w.R
	R.start(w.third)
	task.wait(3)
	T.eq(R.run.path, w.third.path)
	w.scriptFails = true
	R.busy = nil
	R.start(w.native)
	task.wait(5)
	T.eq(w.reg:state(), "idle", "the first one was stopped to make room and the second failed")
	T.eq(R.run, nil)
	T.eq(R.current(), nil)
end

T.section("reanim_ctl: a standalone start shows up as current while it starts")
do
	local w = newWorld()
	local R = w.R
	R.startSolo("limb")
	T.eq(R.busy, "starting")
	T.eq(R.current(), "@solo:gelatek", "the limb reanimate, not the hat one")
	task.wait(3)
	T.eq(R.current(), "@solo:gelatek")
end

T.section("reanim_ctl: a limb script starts the limb reanimation first, then runs")
do
	local w = newWorld()
	local order = {}
	local startGelatek = w.gelatek.start
	w.gelatek.start = function(run)
		order[#order + 1] = "limb start"
		local ok, why = startGelatek(run)
		order[#order + 1] = "limb running"
		return ok, why
	end
	local runScript = w.deps.runScript
	w.deps.runScript = function(e)
		order[#order + 1] = "script"
		return runScript(e)
	end
	local e = w.entry("Scripts/Limb/Spin.lua", "Spin", { kindHint = "limb", category = "Limb" })
	w.R.start(e)
	task.wait(4)
	T.eq(flat(order), "limb start,limb running,script", "the limb reanimation is up before the script runs")
	T.eq(w.R.provider().id, "gelatek")
	T.eq(w.R.current(), e.path)
	T.eq(flat(w.atsuko.calls), "", "the hat reanimation is not touched")
	T.eq(flat(w.fdless.calls), "")
	T.eq(flat(w.gelatek.calls), "start")
	T.eq(w.reg:state(), "running")
	T.eq(toastWith(w, "This script runs on"), nil, "nothing needs saying when the choice already fits")
end
do
	local w = newWorld()
	w.S.reanimLimb = "uhhhhhh"
	local e = w.entry("Scripts/Limb/Spin.lua", "Spin", { kindHint = "limb" })
	w.R.start(e)
	task.wait(4)
	T.eq(w.R.provider().id, "uhhhhhh", "the chosen limb reanimation is used")
	T.eq(flat(w.gelatek.calls), "")
	T.eq(w.R.current(), e.path)
end

T.section("reanim_ctl: a limb script can name the limb reanimation it needs")
do
	local w = newWorld()
	w.S.reanimLimb = "gelatek"
	local e = w.entry("Scripts/Limb/OnlyUhhhhhh.lua", "Only Uhhhhhh", { kindHint = "limb", reanim = { "uhhhhhh" } })
	w.R.start(e)
	task.wait(4)
	T.eq(w.R.provider().id, "uhhhhhh")
	T.eq(w.S.reanimLimb, "gelatek", "the choice itself is not changed")
	T.ok(toastWith(w, "Only Uhhhhhh|This script runs on " .. w.uhhhhhh.name .. "|info") ~= nil, flat(w.toasts))
	T.eq(flat(w.gelatek.calls), "")
end
do
	local w = newWorld()
	w.S.reanimLimb = "uhhhhhh"
	local e = w.entry("Scripts/Limb/Either.lua", "Either", { kindHint = "limb", reanim = { "gelatek", "uhhhhhh" } })
	w.R.start(e)
	task.wait(4)
	T.eq(w.R.provider().id, "uhhhhhh", "a script that takes either follows the choice")
	T.eq(toastWith(w, "This script runs on"), nil)
end
do
	local w = newWorld()
	local e = w.entry("Scripts/Limb/HatList.lua", "Hat list", { kindHint = "limb", reanim = { "fdless" } })
	w.R.start(e)
	task.wait(4)
	T.eq(w.R.provider().id, "gelatek", "a hat reanimation in a limb script's list is ignored")
	T.eq(flat(w.fdless.calls), "")
end

T.section("reanim_ctl: a limb script is never a hub-native script")
do
	local w = newWorld()
	local e = w.entry("Scripts/Hat/Odd.lua", "Odd", { kindHint = "limb" })
	w.R.start(e)
	task.wait(4)
	T.eq(w.R.provider().id, "gelatek", "its kind decides, not its folder")
	T.eq(flat(w.atsuko.calls), "")
end

T.section("reanim_ctl: a broken kind lookup falls back to a hat script")
do
	local w = newWorld()
	local e = w.entry("Scripts/Hat/Broken.lua", "Broken", { kindThrows = true })
	w.R.start(e)
	task.wait(4)
	T.eq(w.R.provider().id, "atsuko")
	T.eq(w.R.current(), e.path)
	local bare = newWorld()
	bare.deps.kindOf = nil
	local e2 = bare.entry("Scripts/Hat/NoLookup.lua", "No lookup", { kindHint = "limb" })
	bare.R.start(e2)
	task.wait(4)
	T.eq(bare.R.provider().id, "atsuko", "no lookup at all means a hat script")
end

T.section("reanim_ctl: stopping a limb script asks, then stops both")
do
	local w = newWorld()
	local e = w.entry("Scripts/Limb/Spin.lua", "Spin", { kindHint = "limb" })
	w.R.start(e)
	task.wait(4)
	w.R.stop()
	T.eq(w.R.busy, "asking", "Gelatek warns that stopping respawns you")
	w.R.toggle()
	task.wait(4)
	T.eq(w.reg:state(), "idle")
	T.eq(w.gelatek.running, false)
	T.eq(flat(w.stoppedScripts), e.path)
	T.eq(w.R.current(), nil)
end

T.section("reanim_ctl: a limb script that fails leaves nothing running")
do
	local w = newWorld()
	w.scriptFails = true
	local e = w.entry("Scripts/Limb/Spin.lua", "Spin", { kindHint = "limb" })
	w.R.start(e)
	task.wait(6)
	T.eq(w.reg:state(), "idle")
	T.eq(w.gelatek.running, false, "the limb reanimation was put back")
	T.eq(w.R.current(), nil)
	T.eq(w.R.busy, nil)
end
