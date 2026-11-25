local Dispatch = loadmodule("Hub/modules/dispatch.lua")
local Prefix = loadmodule("Hub/modules/prefix.lua")

local function makeClock()
	local c = { t = 100 }
	c.now = function()
		return c.t
	end
	return c
end

local function fresh(clock)
	local logs = {}
	local d = Dispatch.new({
		clock = clock and clock.now or nil,
		parse = Prefix.parse,
		newGuard = Prefix.newGuard,
		log = function(kind, who, msg)
			logs[#logs + 1] = kind .. ":" .. who .. ":" .. msg
		end,
	})
	return d, logs
end

local function cmd(id, hits, extra)
	local def = { id = id, name = id, aliases = {}, desc = "d", usage = id, kind = "action" }
	def.run = function(args, ctx)
		hits[#hits + 1] = { id = id, args = args, ctx = ctx }
	end
	for k, v in pairs(extra or {}) do
		def[k] = v
	end
	return def
end

T.section("dispatch: owners and priority")
local d = fresh()
local hits = {}
local hubTp = cmd("tp", hits, { aliases = { "goto" } })
local dummyTp = cmd("tp", hits)
local reanimSpeed = cmd("speed", hits)
local hubSpeed = cmd("speed", hits)
local h1 = d:register("hub", "hub", { hubTp, hubSpeed }, { label = "Atsuko Hub" })
T.ok(h1 ~= nil)
T.eq(d:ownerOf("tp"), "hub")
T.eq(d:ownerOf("goto"), "hub")
T.eq(d:ownerOf("nothing"), nil)
local h2 = d:register("studiodummy", "script", { dummyTp }, { label = "Studio Dummy", short = "dummy" })
T.eq(d:ownerOf("tp"), "studiodummy")
local owner, shadowed = d:ownerOf("tp")
T.eq(#shadowed, 1)
T.eq(shadowed[1].owner, "hub")
T.eq(d:ownerOf("goto"), "hub", "a token only the hub has stays with the hub")
local h3 = d:register("atsukoreanimate", "reanim", { reanimSpeed }, { label = "Script Reanimate" })
T.eq(d:ownerOf("speed"), "atsukoreanimate")
T.eq(d:ownerOf("tp"), "studiodummy", "script beats reanim beats hub")
h2.unregister()
T.eq(d:ownerOf("tp"), "hub", "hub command returns when the script stops")
h3.unregister()
T.eq(d:ownerOf("speed"), "hub")
T.eq(d:unregister("hub"), true)
T.eq(d:unregister("hub"), false)
T.eq(d:ownerOf("tp"), nil)
T.eq(select(2, d:register("x", "wizard", {})), "unknown owner kind")
T.eq(select(2, d:register("", "hub", {})), "owner needs an id")
h2.unregister()
h2.unregister()

T.section("dispatch: a stale handle cannot remove a newer registration")
d = fresh()
hits = {}
local first = d:register("sd", "script", { cmd("tp", hits) })
d:unregister("sd")
local second = d:register("sd", "script", { cmd("tp", hits) })
first.unregister()
T.eq(d:ownerOf("tp"), "sd")
second.unregister()
T.eq(d:ownerOf("tp"), nil)

T.section("dispatch: exact addresses always work")
d = fresh()
hits = {}
d:register("hub", "hub", { cmd("tp", hits) })
d:register("studiodummy", "script", { cmd("tp", hits) }, { short = "dummy" })
T.eq(d:run("tp", "1 2 3", "chat"), true)
T.eq(hits[#hits].ctx.owner, "studiodummy")
T.eq(hits[#hits].args, "1 2 3")
T.eq(d:run("hub:tp", "", "chat"), true)
T.eq(hits[#hits].ctx.owner, "hub")
T.eq(hits[#hits].args, nil)
T.eq(d:run("dummy:tp", "", "chat"), true)
T.eq(hits[#hits].ctx.owner, "studiodummy")
T.eq(d:run("studiodummy:tp", "", "chat"), true)
T.eq(d:run("nobody:tp", "", "chat"), false)
T.eq(d:run("hub:nothing", "", "chat"), false)
T.eq(#hits, 4)

T.section("dispatch: toggles, off names and the un rule")
d = fresh()
hits = {}
d:register("hub", "hub", { cmd("fly", hits, { kind = "toggle", offNames = { "land" } }), cmd("sit", hits) })
d:run("fly", "", "bar")
T.eq(hits[#hits].ctx.state, true)
d:run("fly", "off", "bar")
T.eq(hits[#hits].ctx.state, false)
T.eq(hits[#hits].args, nil)
d:run("fly", "on", "bar")
T.eq(hits[#hits].ctx.state, true)
T.eq(hits[#hits].args, nil)
d:run("fly", "toggle", "bar")
T.eq(hits[#hits].ctx.state, nil)
d:run("fly", "50", "bar")
T.eq(hits[#hits].ctx.state, true)
T.eq(hits[#hits].args, "50")
d:run("land", "", "bar")
T.eq(hits[#hits].ctx.state, false)
d:run("unfly", "", "bar")
T.eq(hits[#hits].ctx.state, false)
T.eq(hits[#hits].id, "fly")
T.eq(d:run("unsit", "", "bar"), false, "the un rule only works for toggles")
T.eq(d:has("unfly"), true)
T.eq(d:has("unsit"), false)
T.eq(d:has("FLY"), true)

T.section("dispatch: declared names")
d = fresh()
hits = {}
d:register("hub", "hub", { cmd("rejoin", hits), cmd("tp", hits) })
d:declare("oldscript", "script", { "rejoin", "RJ" })
T.eq(d:has("rejoin"), true)
T.eq(d:has("rj"), true)
local done, who = d:run("rejoin", "", "chat")
T.eq(done, true)
T.eq(who, "declared")
T.eq(#hits, 0, "the hub steps aside and the script's own listener acts")
T.eq(d:run("tp", "", "chat"), true)
T.eq(#hits, 1)
d:unregister("oldscript")
T.eq(d:run("rejoin", "", "chat"), true)
T.eq(#hits, 2)
T.eq(hits[2].ctx.owner, "hub")
T.eq(select(1, d:declare("late", "script", { "x" })) ~= nil, true)
T.eq(select(2, d:declare("bad", "nope", { "x" })), "unknown owner kind")

T.section("dispatch: chat flow with the real parser")
local clock = makeClock()
d = fresh(clock)
hits = {}
d:register("hub", "hub", { cmd("fly", hits, { kind = "toggle" }), cmd("speed", hits) })
T.eq(select(1, d:handle(";fly", "chat")), true)
T.eq(#hits, 1)
T.eq(select(1, d:handle(";fly", "chat")), true)
T.eq(#hits, 1, "the echo of the same message inside 0.35 s is dropped")
clock.t = clock.t + 0.1
T.eq(#hits, 1)
d:handle(";fly", "chat")
T.eq(#hits, 1)
clock.t = clock.t + 1
d:handle(";fly", "chat")
T.eq(#hits, 2, "a real repeat runs again")
d:handle(";speed 80", "chat")
T.eq(#hits, 3)
T.eq(hits[3].args, "80")
local consumed, info = d:handle(";)", "chat")
T.eq(consumed, false)
T.eq(info.kind, "none")
clock.t = clock.t + 1
consumed, info = d:handle("hello", "chat")
T.eq(consumed, false)
consumed, info = d:handle("-reload", "chat")
T.eq(consumed, false)
T.eq(info.kind, "reload")
consumed, info = d:handle("nope", "bar")
T.eq(consumed, false)
T.eq(info.kind, "unknown")
T.eq(info.word, "nope")
consumed = d:handle("fly", "bar")
T.eq(consumed, true)
T.eq(#hits, 4)
consumed = d:handle(";fly", "bar")
T.eq(consumed, true)
T.eq(#hits, 5, "the bar has no duplicate guard")
consumed = d:handle(";fly", "bar")
T.eq(#hits, 6)
T.eq(d:handle(nil, "chat"), false)
T.eq(d:handle("   ", "chat"), false)
T.eq(d:handle(5, "chat"), false)

T.section("dispatch: legacy prefixes")
clock = makeClock()
d = fresh(clock)
hits = {}
d:register("hub", "hub", { cmd("tp", hits), cmd("noclip", hits) })
d:register("studiodummy", "script", { cmd("tp", hits), cmd("dance", hits) }, { legacyPrefixes = { "-", "/e " } })
T.eq(select(1, d:handle("-tp 1 2", "chat")), true)
T.eq(#hits, 1)
T.eq(hits[1].ctx.owner, "studiodummy")
T.eq(hits[1].args, "1 2")
clock.t = clock.t + 1
T.eq(select(1, d:handle("/e dance", "chat")), true)
T.eq(hits[2].id, "dance")
clock.t = clock.t + 1
T.eq(select(1, d:handle("/E DANCE", "chat")), true)
T.eq(#hits, 3)
clock.t = clock.t + 1
T.eq(select(1, d:handle("-noclip", "chat")), false, "a legacy prefix only reaches its own owner's commands")
clock.t = clock.t + 1
T.eq(select(1, d:handle(";noclip", "chat")), true)
T.eq(hits[#hits].ctx.owner, "hub")
clock.t = clock.t + 1
T.eq(select(1, d:handle(";tp", "chat")), true)
T.eq(hits[#hits].ctx.owner, "studiodummy", "the hub prefix reaches the winner")
clock.t = clock.t + 1
T.eq(select(1, d:handle(";hub:tp", "chat")), true)
T.eq(hits[#hits].ctx.owner, "hub")
d:unregister("studiodummy")
clock.t = clock.t + 1
T.eq(select(1, d:handle("-tp", "chat")), false, "legacy prefixes vanish with the owner")

T.section("dispatch: a failing command is contained")
clock = makeClock()
local d4, logs = fresh(clock)
d4:register("hub", "hub", {
	{ id = "boom", name = "boom", kind = "action", run = function()
		error("kaboom")
	end },
	{ id = "ok", name = "ok", kind = "action", run = function() end },
})
T.eq(select(1, d4:handle(";boom", "chat")), true)
T.eq(#logs, 1)
T.ok(string.find(logs[1], "kaboom", 1, true) ~= nil)
T.eq(select(1, d4:handle(";ok", "chat")), true)
local d5, logs5 = fresh()
d5:register("hub", "hub", {}, {
	resolver = function(token)
		if token == "dyn" then
			return { id = "dyn", kind = "action" }, false
		end
		if token == "bad" then
			error("resolver exploded")
		end
		return nil
	end,
	runner = function(def, ctx, arg)
		error("runner exploded")
	end,
})
T.eq(d5:has("dyn"), true)
T.eq(d5:has("bad"), false)
T.eq(d5:run("dyn", "", "bar"), true)
T.eq(#logs5, 1)

T.section("dispatch: dynamic owners with a resolver")
local d6 = fresh()
local ran = {}
local registry = { fly = { id = "fly", kind = "toggle", offNames = { "land" } }, tp = { id = "tp", kind = "action" } }
d6:register("hub", "hub", {}, {
	label = "Atsuko Hub",
	resolver = function(token)
		if registry[token] then
			return registry[token], false
		end
		if token == "land" then
			return registry.fly, true
		end
		return nil
	end,
	runner = function(def, ctx, arg)
		ran[#ran + 1] = def.id .. ":" .. tostring(ctx.state) .. ":" .. tostring(arg)
	end,
	lister = function()
		return { registry.fly, registry.tp }
	end,
})
d6:run("fly", "", "bar")
d6:run("land", "", "bar")
d6:run("tp", "1 2", "bar")
T.same(ran, { "fly:true:nil", "fly:false:nil", "tp:nil:1 2" })
registry.late = { id = "late", kind = "action" }
T.eq(d6:has("late"), true)
T.eq(#d6:list(), 2)
d6:register("sd", "script", { cmd("tp", {}) })
local rows = d6:list()
T.eq(#rows, 3)
local shadowRows = 0
for _, row in ipairs(rows) do
	if row.shadowedBy then
		shadowRows = shadowRows + 1
		T.eq(row.owner, "hub")
		T.eq(row.shadowedBy, "sd")
	end
end
T.eq(shadowRows, 1)

T.section("dispatch: list is sorted and labelled")
local d7 = fresh()
d7:register("hub", "hub", { cmd("zoom", {}), cmd("alpha", {}), cmd("mid", {}) }, { label = "Atsuko Hub" })
d7:register("sd", "script", { cmd("beta", {}) }, { label = "Studio Dummy" })
rows = d7:list()
local names = {}
for _, row in ipairs(rows) do
	names[#names + 1] = row.def.id
end
T.same(names, { "alpha", "beta", "mid", "zoom" })
T.eq(rows[2].label, "Studio Dummy")
T.eq(rows[1].label, "Atsuko Hub")
T.same(d7:ownerIds(), { "sd", "hub" })
d7:clear()
T.eq(#d7:list(), 0)

T.section("dispatch: change notifications")
local changes = 0
local d8 = Dispatch.new({ onChange = function()
	changes = changes + 1
end, parse = Prefix.parse })
d8:register("hub", "hub", {})
d8:declare("s", "script", { "x" })
d8:unregister("s")
d8:unregister("s")
T.eq(changes, 4)

T.section("dispatch: exactly-once over 100 random sequences")
local seed = 12345
local function rnd(n)
	seed = (seed * 1103515245 + 12345) % 2147483648
	return (seed % n) + 1
end
local kinds = { "hub", "reanim", "script" }
local ownerNames = { "hub", "reanimA", "reanimB", "scriptA", "scriptB", "scriptC" }
local ownerKind = { hub = "hub", reanimA = "reanim", reanimB = "reanim", scriptA = "script", scriptB = "script", scriptC = "script" }
local tokenPool = { "tp", "noclip", "sit", "align", "antivoid", "emote", "video", "speed", "jump", "fly", "freeze", "goto", "rejoin", "refresh" }
local totalChecks, wrong = 0, 0
for sequence = 1, 100 do
	local clock2 = makeClock()
	local dd = Dispatch.new({ clock = clock2.now, parse = Prefix.parse, newGuard = Prefix.newGuard })
	local counts = {}
	local registered = {}
	local order = 0
	local function ownerCommands(name)
		local defs = {}
		local used = {}
		for i = 1, rnd(5) do
			local tok = tokenPool[rnd(#tokenPool)]
			if not used[tok] then
				used[tok] = true
				defs[#defs + 1] = {
					id = tok,
					name = tok,
					kind = "action",
					run = function()
						counts[name] = (counts[name] or 0) + 1
					end,
				}
			end
		end
		return defs, used
	end
	for step = 1, 80 do
		local op = rnd(5)
		if op <= 2 then
			local name = ownerNames[rnd(#ownerNames)]
			local defs, used = ownerCommands(name)
			dd:register(name, ownerKind[name], defs)
			order = order + 1
			registered[name] = { tokens = used, order = order, priority = Dispatch.PRIORITY[ownerKind[name]] }
		elseif op == 3 then
			local name = ownerNames[rnd(#ownerNames)]
			dd:unregister(name)
			registered[name] = nil
		else
			local tok = tokenPool[rnd(#tokenPool)]
			local best, bestName = nil, nil
			for name, r in pairs(registered) do
				if r.tokens[tok] then
					if not best or r.priority > best.priority or (r.priority == best.priority and r.order > best.order) then
						best, bestName = r, name
					end
				end
			end
			local before = {}
			local sumBefore = 0
			for _, n in ipairs(ownerNames) do
				before[n] = counts[n] or 0
				sumBefore = sumBefore + before[n]
			end
			clock2.t = clock2.t + 1
			local consumed = dd:handle(";" .. tok, "chat")
			local sumAfter = 0
			for _, n in ipairs(ownerNames) do
				sumAfter = sumAfter + (counts[n] or 0)
			end
			totalChecks = totalChecks + 1
			if best then
				if not consumed or sumAfter ~= sumBefore + 1 or (counts[bestName] or 0) ~= before[bestName] + 1 then
					wrong = wrong + 1
				end
			else
				if consumed or sumAfter ~= sumBefore then
					wrong = wrong + 1
				end
			end
		end
	end
end
T.ok(totalChecks > 1000, "enough handle calls were made")
T.eq(wrong, 0)
