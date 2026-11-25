local hub = readsource("Hub/AtsukoHub.lua")

local NAMES = { "Core", "Runner", "X", "S", "Log", "Util", "HUB_VERSION", "realTask", "realCoroutine", "realInstance", "realPrint", "realWarn" }
local saved = {}
for _, name in ipairs(NAMES) do
	saved[name] = _G[name]
end

local function fn(header)
	local first = string.find(hub, "\n" .. header, 1, true)
	T.ok(first ~= nil, "found in the hub: " .. header)
	if not first then
		return ""
	end
	local last = string.find(hub, "\nend\n", first + 1, true)
	T.ok(last ~= nil, "found the end of: " .. header)
	if not last then
		return ""
	end
	return string.sub(hub, first + 1, last + 3)
end

local function run(code, name)
	local f, err = loadstring(code, "=" .. name)
	T.ok(f ~= nil, name .. " compiles: " .. tostring(err))
	if f then
		f()
	end
end

local W

local function newWorld()
	W = { deferred = {}, delayed = {}, spawned = 0, prints = {}, warns = {}, logs = {}, notified = {}, stops = {}, fenvs = {}, registered = {}, unregistered = {}, made = {} }
	Core = {}
	Runner = {
		stop = function(path)
			W.stops[#W.stops + 1] = path
		end,
	}
	X = {}
	S = { capturePrints = true }
	Log = {
		add = function(kind, src, msg)
			W.logs[#W.logs + 1] = kind .. "|" .. src .. "|" .. msg
		end,
	}
	Util = {
		join = function(...)
			local out = {}
			for i = 1, select("#", ...) do
				out[#out + 1] = tostring((select(i, ...)))
			end
			return table.concat(out, " ")
		end,
	}
	HUB_VERSION = "9.9.9"
	realTask = {
		spawn = function(f, ...)
			W.spawned += 1
			local co = coroutine.create(f)
			coroutine.resume(co, ...)
			return co
		end,
		defer = function(f, ...)
			local co = coroutine.create(f)
			W.deferred[#W.deferred + 1] = { co, ... }
			return co
		end,
		delay = function(t, f, ...)
			local co = coroutine.create(f)
			W.delayed[#W.delayed + 1] = { t, co, ... }
			return co
		end,
		wait = function() end,
	}
	realCoroutine = coroutine
	realInstance = {
		new = function(class)
			local o = { ClassName = class, Parent = "ROOT" }
			W.made[#W.made + 1] = o
			return o
		end,
	}
	realPrint = function(...)
		W.prints[#W.prints + 1] = Util.join(...)
	end
	realWarn = function(...)
		W.warns[#W.warns + 1] = Util.join(...)
	end
	Core.BASE_ENV = { game = "GAME", marker = "from base" }
	Core.API = {
		Notify = function(title, text, kind, dur)
			W.notified[#W.notified + 1] = table.concat({ tostring(title), tostring(text), tostring(kind), tostring(dur) }, "|")
			return "notified"
		end,
	}
	Core.Reanim = {
		provider = function()
			return W.provider
		end,
		stop = function(reason)
			W.reanimStops = (W.reanimStops or 0) + 1
			W.stopReason = reason
		end,
	}
	Core.pruneThreads = nil
	Core.pruneInsts = nil
	run(fn("function Core.pruneThreads(rec)"), "Core.pruneThreads")
	run(fn("function Core.pruneInsts(rec)"), "Core.pruneInsts")
	run(fn("function Core.makeEnv(rec)"), "Core.makeEnv")
end

local function newRec(over)
	local rec = { name = "Spin", path = "Scripts/Limb/Spin.lua", threads = {}, insts = {}, instBorn = {}, cleanups = {}, conns = {}, stopping = false }
	for k, v in pairs(over or {}) do
		rec[k] = v
	end
	return rec
end

T.section("sandbox_env: the AtsukoHub table")
do
	newWorld()
	local rec = newRec()
	local env = Core.makeEnv(rec)
	local A = env.AtsukoHub
	T.eq(A.Version, "9.9.9")
	T.eq(A.Name, "Spin")
	T.eq(A.Path, "Scripts/Limb/Spin.lua")
	T.eq(env.marker, "from base", "everything else comes from the executor's environment")
	T.eq(env.game, "GAME")
	T.eq(rawget(env, "marker"), nil)
	T.eq(type(A.OnStop), "function")
	T.eq(type(A.Stop), "function")
	T.eq(type(A.Notify), "function")
	T.eq(type(A.Commands.register), "function")
	T.eq(type(A.Commands.declare), "function")
end

T.section("sandbox_env: Notify passes all four arguments")
do
	newWorld()
	local env = Core.makeEnv(newRec())
	local result = env.AtsukoHub.Notify("Title", "Text", "warn", 7)
	T.eq(result, "notified", "and gives back what the hub gave")
	T.same(W.notified, { "Title|Text|warn|7" })
	env.AtsukoHub.Notify("Only", "two")
	T.eq(W.notified[2], "Only|two|nil|nil")
end

T.section("sandbox_env: OnStop and Stop")
do
	newWorld()
	local rec = newRec()
	local env = Core.makeEnv(rec)
	local called = 0
	env.AtsukoHub.OnStop(function()
		called += 1
	end)
	env.AtsukoHub.OnStop("not a function")
	env.AtsukoHub.OnStop(nil)
	T.eq(#rec.cleanups, 1, "only functions are kept")
	rec.cleanups[1]()
	T.eq(called, 1)
	env.AtsukoHub.Stop()
	T.same(W.stops, { "Scripts/Limb/Spin.lua" }, "Stop stops this script")
end

T.section("sandbox_env: AtsukoHub.Reanim says what the script runs on")
do
	newWorld()
	local env = Core.makeEnv(newRec())
	local R = env.AtsukoHub.Reanim
	T.eq(type(R), "table")
	T.eq(R.Kind, nil, "no reanimation running")
	T.eq(R.Provider, nil)
	T.eq(R.Clone, nil)
	T.eq(type(R.Stop), "function")
	R.Stop()
	T.eq(W.reanimStops, 1, "Stop stops the reanimation")
	T.eq(W.stopReason, "script", "and says it was the script, so Gelatek's are-you-sure question is not asked")

	newWorld()
	W.provider = { id = "atsuko", kind = "hat" }
	R = Core.makeEnv(newRec()).AtsukoHub.Reanim
	T.eq(R.Kind, "hat")
	T.eq(R.Provider, "atsuko")
	T.eq(R.Clone, nil, "a hat reanimation has no clone")

	newWorld()
	local model = { Name = "TalentlessDumbass" }
	W.provider = {
		id = "gelatek",
		kind = "limb",
		clone = function()
			return model
		end,
	}
	R = Core.makeEnv(newRec()).AtsukoHub.Reanim
	T.eq(R.Kind, "limb")
	T.eq(R.Provider, "gelatek")
	T.eq(R.Clone, model, "the clone the limb reanimation made")

	newWorld()
	W.provider = {
		id = "gelatek",
		kind = "limb",
		clone = function()
			error("no clone yet")
		end,
	}
	R = Core.makeEnv(newRec()).AtsukoHub.Reanim
	T.eq(R.Kind, "limb", "a clone lookup that throws does not stop the script from starting")
	T.eq(R.Clone, nil)

	newWorld()
	Core.Reanim.provider = function()
		error("registry broke")
	end
	R = Core.makeEnv(newRec()).AtsukoHub.Reanim
	T.eq(R.Kind, nil, "a registry that throws gives an empty answer")
	T.eq(R.Provider, nil)

	newWorld()
	Core.Reanim = nil
	R = Core.makeEnv(newRec()).AtsukoHub.Reanim
	T.eq(R.Kind, nil, "before the controller exists")
	R.Stop()

	newWorld()
	Core.Reanim = {}
	R = Core.makeEnv(newRec()).AtsukoHub.Reanim
	T.eq(R.Kind, nil, "a controller without a provider function")
	R.Stop()
end

T.section("sandbox_env: task and spawn are tracked")
do
	newWorld()
	local rec = newRec()
	local env = Core.makeEnv(rec)
	local ran = {}
	local a = env.task.spawn(function(x)
		ran[#ran + 1] = "spawn " .. x
	end, 1)
	T.eq(type(a), "thread")
	T.same(ran, { "spawn 1" })
	local b = env.task.defer(function() end)
	local c = env.task.delay(2, function() end)
	T.eq(type(b), "thread")
	T.eq(type(c), "thread")
	T.eq(#rec.threads, 3)
	T.eq(W.delayed[1][1], 2, "the delay is passed on")
	local d = env.spawn(function() end)
	local e = env.delay("3", function() end)
	local f = env.delay(nil, function() end)
	T.eq(type(d), "thread")
	T.eq(W.delayed[2][1], 0, "the legacy spawn runs at once")
	T.eq(W.delayed[3][1], 3, "the legacy delay reads numbers from text")
	T.eq(W.delayed[4][1], 0)
	T.eq(#rec.threads, 6)
	T.eq(env.task.wait, realTask.wait, "everything else on task is the real one")
	rec.stopping = true
	env.task.spawn(function() end)
	env.task.delay(1, function() end)
	T.eq(#rec.threads, 6, "nothing is tracked once the script is stopping")
end

T.section("sandbox_env: finished threads are dropped when the list gets long")
do
	newWorld()
	local rec = newRec()
	local env = Core.makeEnv(rec)
	for i = 1, 450 do
		env.task.spawn(function() end)
	end
	T.ok(#rec.threads < 100, "dead threads were cleaned: " .. #rec.threads)
	T.ok((rec.threadCap or 0) >= 400)
	local live = {}
	for i = 1, 30 do
		live[i] = env.task.delay(5, function() end)
	end
	for i = 1, 450 do
		env.task.spawn(function() end)
	end
	local kept = 0
	for _, th in ipairs(rec.threads) do
		if coroutine.status(th) ~= "dead" then
			kept += 1
		end
	end
	T.eq(kept, 30, "threads that are still waiting are never dropped")
	T.ok((rec.threadCap or 0) >= 400)
end

T.section("sandbox_env: coroutine create and wrap")
do
	newWorld()
	local rec = newRec()
	local env = Core.makeEnv(rec)
	local co = env.coroutine.create(function() end)
	T.eq(type(co), "thread")
	T.eq(#rec.threads, 1)
	local seen = {}
	local wrapped = env.coroutine.wrap(function(a, b)
		seen[#seen + 1] = a .. b
		local c = coroutine.yield(a + 1, "mid")
		seen[#seen + 1] = "c" .. c
		return "done", 1, nil
	end)
	T.eq(#rec.threads, 2, "wrap tracks its thread too")
	local r1, r2 = wrapped(1, 2)
	T.eq(r1, 2)
	T.eq(r2, "mid")
	local x, y, z = wrapped(9)
	T.eq(x, "done")
	T.eq(y, 1)
	T.eq(z, nil)
	T.same(seen, { "12", "c9" })
	local failing = env.coroutine.wrap(function()
		error("boom", 0)
	end)
	local ok, e = pcall(failing)
	T.eq(ok, false)
	T.eq(e, "boom", "an error comes out unchanged")
	T.eq(env.coroutine.status, coroutine.status, "the rest of coroutine is the real one")
	rec.stopping = true
	env.coroutine.create(function() end)
	T.eq(#rec.threads, 3, "not tracked while stopping")
end

T.section("sandbox_env: instances are tracked")
do
	newWorld()
	local rec = newRec()
	local env = Core.makeEnv(rec)
	local part = env.Instance.new("Part")
	T.eq(part.ClassName, "Part")
	T.eq(#rec.insts, 1)
	T.eq(rec.insts[1], part)
	T.eq(type(rec.instBorn[1]), "number")
	rec.stopping = true
	env.Instance.new("Part")
	T.eq(#rec.insts, 1, "not tracked while stopping")
	T.eq(#W.made, 2, "but still made")
end

T.section("sandbox_env: old destroyed instances are dropped when the list gets long")
do
	newWorld()
	local rec = newRec()
	local env = Core.makeEnv(rec)
	local mine = {}
	for i = 1, 4000 do
		mine[i] = env.Instance.new("Part")
	end
	T.eq(#rec.insts, 4000)
	for i = 1, 3000 do
		mine[i].Parent = nil
		rec.instBorn[i] = os.clock() - 100
	end
	env.Instance.new("Part")
	T.eq(#rec.insts, 1001, "3000 destroyed old ones were dropped, 1000 live ones and the new one stay")
	T.ok((rec.instCap or 0) >= 4000)
	for i = 1, 20 do
		local o = env.Instance.new("Part")
		o.Parent = nil
	end
	T.eq(#rec.insts, 1021, "young instances are kept even when parentless")
end

T.section("sandbox_env: print and warn")
do
	newWorld()
	local env = Core.makeEnv(newRec())
	env.print("hello", 3)
	env.warn("careful")
	T.same(W.prints, { "hello 3" })
	T.same(W.warns, { "careful" })
	T.same(W.logs, { "info|Spin|hello 3", "warn|Spin|careful" })
	S.capturePrints = false
	env.print("quiet")
	T.eq(#W.logs, 2, "nothing is logged when capture is off")
	T.eq(W.prints[2], "quiet", "but it still prints")
end

T.section("sandbox_env: loadstring keeps the script's environment")
do
	newWorld()
	local env = Core.makeEnv(newRec())
	T.eq(env.loadstring, nil, "no loadstring when the executor has none (the base one is used)")
	newWorld()
	local fenvs = {}
	X.loadstring = function(src, name)
		if src == "bad" then
			return nil, "syntax error"
		end
		return function()
			return src
		end
	end
	X.setfenv = function(f, e)
		fenvs[#fenvs + 1] = e
		return f
	end
	local env2 = Core.makeEnv(newRec())
	local f = env2.loadstring("code", "=x")
	T.eq(f(), "code")
	T.eq(fenvs[1], env2, "the new chunk runs in the same sandbox")
	local g, err = env2.loadstring("bad")
	T.eq(g, nil)
	T.eq(err, "syntax error")
	T.eq(#fenvs, 1)
	X.setfenv = function()
		error("not allowed")
	end
	local h = env2.loadstring("code")
	T.eq(h(), "code", "an executor that refuses setfenv does not break loadstring")
end

T.section("sandbox_env: commands")
do
	newWorld()
	local rec = newRec()
	local env = Core.makeEnv(rec)
	T.eq(env.AtsukoHub.Commands.register({ { id = "a", run = function() end } }), nil, "no dispatcher yet")
	T.eq(env.AtsukoHub.Commands.declare({ "a" }), nil)
	local handles = {}
	Core.Dispatch = {
		register = function(self, id, kind, list, opts)
			W.registered[#W.registered + 1] = { id = id, kind = kind, list = list, opts = opts }
			local h = {
				unregister = function()
					W.unregistered[#W.unregistered + 1] = id
				end,
			}
			handles[#handles + 1] = h
			return h
		end,
		declare = function(self, id, kind, list, opts)
			W.registered[#W.registered + 1] = { id = id, kind = kind, list = list, opts = opts, declared = true }
			return {}
		end,
		unregister = function(self, id)
			W.unregistered[#W.unregistered + 1] = id
		end,
	}
	local run = function() end
	local h = env.AtsukoHub.Commands.register({
		{ id = "spin", name = "Spin", aliases = { "s", 5, "" }, desc = "Spins", usage = "spin [speed]", kind = "toggle", run = run },
		{ id = "", run = run },
		{ id = "norun" },
		"junk",
		{ id = "plain", run = run },
	}, { legacyPrefixes = { "!", 7, "", "toolong", "?", "#", "%" }, short = "sp" })
	T.ok(h ~= nil)
	local r = W.registered[1]
	T.eq(r.id, "script:spin:1")
	T.eq(r.kind, "script")
	T.eq(#r.list, 2, "only well formed commands count")
	T.eq(r.list[1].id, "spin")
	T.same(r.list[1].aliases, { "s" })
	T.eq(r.list[1].kind, "toggle")
	T.eq(r.list[1].usage, "spin [speed]")
	T.eq(r.list[2].name, "plain", "the name falls back to the id")
	T.eq(r.list[2].kind, "action")
	T.eq(r.list[2].usage, "plain")
	T.eq(r.opts.label, "Spin")
	T.eq(r.opts.short, "sp")
	T.same(r.opts.legacyPrefixes, { "!", "?", "#" }, "text prefixes of four characters or fewer, three at most")
	env.AtsukoHub.Commands.register({ { id = "two", run = run } })
	T.eq(W.registered[2].id, "script:spin:2", "each call gets its own owner id")
	T.eq(W.registered[2].opts.short, "spin", "the short name comes from the script name")
	T.eq(#rec.cleanups, 1, "one cleanup covers every handle")
	rec.cleanups[1]()
	T.same(W.unregistered, { "script:spin:1", "script:spin:2" })
	local d = env.AtsukoHub.Commands.declare({ "ghost", 5, "boo" })
	T.ok(d ~= nil)
	T.eq(W.registered[3].declared, true)
	T.same(W.registered[3].list, { "ghost", "boo" })
	d.unregister()
	T.eq(W.unregistered[3], "script:spin:3")
	rec.stopping = true
	T.eq(env.AtsukoHub.Commands.register({ { id = "late", run = run } }), nil, "nothing registers while the script is stopping")
	T.eq(env.AtsukoHub.Commands.declare({ "late" }), nil)
	Core.Dispatch = nil
end

for _, name in ipairs(NAMES) do
	_G[name] = saved[name]
end
