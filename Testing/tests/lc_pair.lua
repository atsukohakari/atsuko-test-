local World = loadmodule("Testing/mocks/rbx_world.lua")
local env = World.install({})
local Exact = loadmodule("Testing/mocks/cframe_math.lua").make(Vector3)
CFrame = Exact
local makeApi = loadmodule("Testing/mocks/fake_fd.lua").make
local A = loadmodule("Hub/modules/alignment.lua")

local LC1, LC2, TEX = "97638566524944", "118424096643898", "128238174721913"
local CAT1, CAT2 = "111000111", "222000222"

local function near(a, b, eps)
	eps = eps or 1e-4
	local x = { a:GetComponents() }
	local y = { b:GetComponents() }
	for i = 1, 12 do
		if math.abs(x[i] - y[i]) > eps then
			return false
		end
	end
	return true
end
local function nearV(a, b, eps)
	return (a - b).Magnitude < (eps or 1e-4)
end

local function solve(api)
	local done = {}
	local root = api.V.HumanoidRootPart
	done[root] = true
	local more = true
	while more do
		more = false
		for _, j in ipairs(api.joints) do
			local a, b = j.Part0, j.Part1
			if a and b and a ~= b then
				if done[b] and not done[a] then
					api.cframes[a] = api.cframes[b] * j.C1 * j.C0:Inverse()
					done[a] = true
					more = true
				elseif done[a] and not done[b] then
					api.cframes[b] = api.cframes[a] * j.C0 * j.C1:Inverse()
					done[b] = true
					more = true
				end
			end
		end
	end
	return api.cframes
end

local UH_HAND = CFrame.new(0.05, -1, 0.15) * CFrame.Angles(math.pi, math.pi, 0)
local C1 = {
	[LC1] = CFrame.new(4.51, 1.525, 0.1, 0, -1, 0, 0, 0, 1, -1, 0, 0),
	[LC2] = CFrame.new(-0.5, -1.3, -0.1, 0, -1, 0, 0, 0, -1, 1, 0, 0),
}
local UH_M = CFrame.fromMatrix(Vector3.new(), Vector3.new(0, 1, 0), Vector3.new(0, 0, -1), Vector3.new(-1, 0, 0))

T.section("lc_pair: the hat list knows both halves of the LC gun")
do
	local h1 = A.holdOf({ mesh = "rbxassetid://" .. LC1, tex = "rbxassetid://" .. TEX })
	local h2 = A.holdOf({ mesh = "http://www.roblox.com/asset/?id=" .. LC2 })
	T.ok(h1 ~= nil and h2 ~= nil, "both halves are known from their mesh, as a link or an rbxassetid")
	T.eq(h1.half, 1, "LC Gun 1 is the first half")
	T.eq(h2.half, 2, "LC Gun 2 is the second half")
	T.eq(h1.mate.mesh, LC2, "the first half knows the second")
	T.eq(h2.mate.mesh, LC1, "and the second knows the first")
	T.eq(A.holdOf({ mesh = "4615369575" }), nil, "a gun that isn't a known half gets nothing")
	T.eq(A.holdOf(nil), nil, "nothing in, nothing out")
	T.ok(nearV(h1.fit.Position, Vector3.new(4.51, 1.525, -0.1)), "LC Gun 1 sits 4.5 studs ahead of the hand, along the barrel")
	T.ok(nearV(h2.fit.Position, Vector3.new(-0.5, 1.3, -0.1)), "LC Gun 2 sits at the hand")
	T.ok(nearV(h1.hatFwd, Vector3.new(-1, 0, 0)), "LC Gun 1's barrel is its -X")
	for _, mesh in ipairs({ LC1, LC2 }) do
		local h = A.holdOf({ mesh = mesh })
		local arm = CFrame.new(3, 4, 5) * CFrame.Angles(0.4, -1.1, 0.7)
		local held = arm * UH_HAND * UH_M * h.fit
		local uh = arm * UH_HAND * C1[mesh]:Inverse()
		T.ok(near(held, uh), h.name .. " is held exactly where Uhhhhhh holds it")
		local muzzle = arm * UH_HAND * UH_M * h.tip
		T.ok(nearV(held * h.hatTip, muzzle), h.name .. " knows where the muzzle is from its own handle")
	end
	local grip = CFrame.new(-2, 1, 0.5) * CFrame.Angles(1.2, 0.3, -0.8)
	local one = grip * h1.fit
	local two = grip * h2.fit
	T.ok(near(one * h1.mate.rel, two), "LC Gun 2 = LC Gun 1 moved by the joint the pair always has")
	T.ok(near(two * h2.mate.rel, one), "and the other way round")
end

T.section("lc_pair: join keeps the second half on the first, wherever a script puts it")
do
	local api = makeApi()
	local e1, j1 = api.hat("LC Gun 1", LC1, TEX)
	local e2, j2 = api.hat("LC Gun 2", LC2, TEX)
	local other = api.hat("Cool Hat", "999", "998")
	j1.Part1 = api.V["Right Arm"]
	j1.C0 = CFrame.new()
	j1.C1 = CFrame.new(0.05, -1, -0.15) * CFrame.Angles(-math.pi / 2, 0, 0) * CFrame.Angles(0, 0.3, 0)
	local home = { j2.Part1, j2.C0, j2.C1 }
	local undo, mate = A.join(api, e1)
	T.ok(type(undo) == "function", "join gives back a way to undo it")
	T.eq(mate, e2, "and the hat it joined")
	T.eq(j2.Part1, e1, "LC Gun 2 now hangs on LC Gun 1")
	local cfs = solve(api)
	local rel = A.holdOf({ mesh = LC1 }).mate.rel
	T.ok(near(cfs[e2], cfs[e1] * rel), "so it sits exactly where the pair joins")
	j1.Part1 = api.V.HumanoidRootPart
	j1.C1 = CFrame.new(1, -2, -3) * CFrame.Angles(0.5, 0.5, 0.5)
	cfs = solve(api)
	T.ok(near(cfs[e2], cfs[e1] * rel), "and still does after the script moves the gun somewhere else")
	local undo2 = A.join(api, e1)
	undo()
	T.eq(j2.Part1, e1, "an older undo doesn't pull it off while a newer join holds it")
	undo2()
	T.eq(j2.Part1, home[1], "the last undo puts it back where it was worn")
	T.ok(j2.C0 == home[2] and j2.C1 == home[3], "with its old offsets")
	T.eq(A.join(api, other), nil, "a hat that isn't a known half joins nothing")
	local lone = makeApi()
	local only = lone.hat("LC Gun 1", LC1, TEX)
	T.eq(A.join(lone, only), nil, "without the second half worn there is nothing to join")
	T.eq(A.join(nil, e1), nil, "no fd, no join")
	local back = makeApi()
	local b1 = back.hat("LC Gun 1", LC1, TEX)
	local b2, bj2 = back.hat("LC Gun 2", LC2, TEX)
	local bj1 = back.getPartJoint(b1)
	local u = A.join(back, b2)
	T.eq(bj1.Part1, b2, "holding LC Gun 2 joins LC Gun 1 to it instead")
	local bc = solve(back)
	T.ok(near(bc[b1], bc[b2] * A.holdOf({ mesh = LC2 }).mate.rel), "at the same joint, the other way round")
	u()
end

local function newEnv(canLook)
	local e = { files = {} }
	e.api = {
		fetch = function()
			return true, "return { version = 1, help = {}, slots = {}, rig = {}, scripts = {} }"
		end,
		saveCache = function(body)
			e.files.cache = body
			return true
		end,
		readCache = function()
			return e.files.cache
		end,
		readUser = function()
			return e.files.user
		end,
		writeUser = function(text)
			e.files.user = text
			return true
		end,
		cframe = function(...)
			return { cf = { ... } }
		end,
		publish = function(_, info)
			e.info = info
		end,
	}
	if canLook ~= false then
		e.api.resolveHat = function(id)
			if id == CAT1 then
				return { mesh = "rbxassetid://" .. LC1, tex = "rbxassetid://" .. TEX, name = "LC-Gun 1" }
			end
			if id == CAT2 then
				return { mesh = "rbxassetid://" .. LC2, tex = "rbxassetid://" .. TEX, name = "LC-Gun 2" }
			end
			if id == "4506945409" then
				return { mesh = "rbxassetid://111", tex = "rbxassetid://222", name = "My Blade" }
			end
			return nil, "no such hat"
		end
	end
	return e
end

local function rowsFor(svc, section, script)
	local out = {}
	for _, row in ipairs(svc:userRows(section, script)) do
		out[#out + 1] = row
	end
	return out
end

T.section("lc_pair: add <LC Gun 1> <LC Gun 2> adds one joined gun")
do
	local e = newEnv()
	local svc = A.new(e.api)
	svc:load()
	local report = svc:addIds(A.parseAdd(CAT1 .. " " .. CAT2), {})
	T.eq(#report.failed, 0, "nothing failed")
	T.eq(#report.added, 1, "the two ids are reported as one gun")
	T.eq(report.added[1].name, "LC-Gun 1 + LC-Gun 2", "named after both halves")
	T.ok(string.find(report.added[1].use, "both halves joined", 1, true) ~= nil, "and says they stay joined: " .. tostring(report.added[1].use))
	T.eq(#rowsFor(svc, "shared", "any"), 0, "neither half is a sword anywhere")
	local guns = rowsFor(svc, "shared", "gun")
	T.eq(#guns, 1, "one gun row")
	T.eq(guns[1].mesh, LC1, "for LC Gun 1, the half the scripts hold")
	local sb = rowsFor(svc, "script", "Snake Banisher V3")
	local slots = {}
	for _, row in ipairs(sb) do
		slots[row.slot] = row.mesh
	end
	T.eq(slots.gun1, LC1, "Snake Banisher's gun 1 is LC Gun 1")
	T.eq(slots.gun2, LC2, "and its gun 2 is LC Gun 2")
	local lc1 = { mesh = LC1, tex = TEX }
	local lc2 = { mesh = LC2, tex = TEX }
	T.ok(e.info.match("The Hotline", "gun", lc1) ~= nil, "The Hotline holds LC Gun 1")
	T.eq(e.info.match("The Hotline", "gun", lc2), nil, "and not LC Gun 2 on its own, that one rides on the first")
	T.eq(e.info.match("Neptunian V", "sword", lc1), nil, "Neptunian V doesn't take it as a sword")
	T.eq(e.info.match("Last Star", "sword", lc2), nil, "and neither does Last Star")
	T.eq(#e.info.mine("Snake Banisher V3", "gun2"), 1, "Snake Banisher's second gun reads LC Gun 2")
	T.ok(type(e.info.hold) == "function" and e.info.hold(lc1) ~= nil, "scripts can ask how to hold it")
	T.ok(type(e.info.join) == "function", "and join the second half")
	local again = svc:addIds(A.parseAdd(CAT1 .. " " .. CAT2), {})
	T.eq(#again.added, 1, "adding the pair again is fine")
	T.eq(#rowsFor(svc, "shared", "gun"), 1, "and doesn't double anything")
	T.eq(#rowsFor(svc, "script", "Snake Banisher V3"), 2)
end

T.section("lc_pair: any order, as gun, as pair, and the old rows from before")
do
	local e = newEnv()
	local svc = A.new(e.api)
	svc:load()
	local r = svc:addIds(A.parseAdd(CAT2 .. " " .. CAT1), {})
	T.eq(#r.added, 1, "LC Gun 2 first works too")
	T.eq(rowsFor(svc, "shared", "gun")[1].mesh, LC1, "LC Gun 1 is still the half that is held")

	local old = newEnv()
	local svc2 = A.new(old.api)
	svc2:load()
	svc2:addIds(A.parseAdd(CAT1 .. " as any"), {})
	svc2:addIds(A.parseAdd(CAT2 .. " as any"), {})
	T.eq(#rowsFor(svc2, "shared", "any"), 2, "the way it was saved before: two any weapon rows")
	local fix = svc2:addIds(A.parseAdd(CAT1 .. " " .. CAT2), {})
	T.eq(fix.added[1].replaced, 2, "adding the pair again swaps those two rows out")
	T.eq(#rowsFor(svc2, "shared", "any"), 0, "no any weapon rows are left")
	T.eq(#rowsFor(svc2, "shared", "gun"), 1, "one gun row instead")
	local kept = newEnv()
	local svc3 = A.new(kept.api)
	svc3:load()
	svc3:addIds(A.parseAdd(CAT1 .. " as any at 1 2 3"), {})
	svc3:addIds(A.parseAdd(CAT1 .. " " .. CAT2), {})
	T.eq(#rowsFor(svc3, "shared", "any"), 1, "a row you lined up yourself is kept")

	local pe = newEnv()
	local svc4 = A.new(pe.api)
	svc4:load()
	local p = svc4:addIds(A.parseAdd(CAT2 .. " " .. CAT1 .. " as pair"), {})
	T.eq(#p.added, 1)
	T.eq(#rowsFor(svc4, "shared", "gun"), 0, "as pair keeps it to Snake Banisher")
	local s = {}
	for _, row in ipairs(rowsFor(svc4, "script", "Snake Banisher V3")) do
		s[row.slot] = row.mesh
	end
	T.eq(s.gun1 .. "/" .. s.gun2, LC1 .. "/" .. LC2, "with each half in its own slot, whatever order you typed")

	local ge = newEnv()
	local svc5 = A.new(ge.api)
	svc5:load()
	local g = svc5:addIds(A.parseAdd(CAT1 .. " " .. CAT2 .. " as gun"), {})
	T.eq(#g.added, 1, "as gun adds the joined gun too")

	local se = newEnv()
	local svc6 = A.new(se.api)
	svc6:load()
	local sw = svc6:addIds(A.parseAdd(CAT1 .. " " .. CAT2 .. " as sword"), {})
	T.eq(#sw.added, 2, "as sword is taken at its word, two swords")

	local oe = newEnv()
	local svc7 = A.new(oe.api)
	svc7:load()
	local one = svc7:addIds(A.parseAdd(CAT1), {})
	T.eq(one.added[1].use, "gun in every script with a gun", "one half alone is known to be a gun")
	T.eq(one.added[1].how, "known", "because the hat list knows the LC gun")

	local mix = newEnv()
	local svc8 = A.new(mix.api)
	svc8:load()
	local m = svc8:addIds(A.parseAdd(CAT1 .. " 4506945409 " .. CAT2), {})
	T.eq(#m.added, 2, "a third hat in the same add is added on its own")
	T.eq(#rowsFor(svc8, "shared", "sword"), 1, "its name says blade, so it is a sword")

	local worn = newEnv(false)
	local svc9 = A.new(worn.api)
	svc9:load()
	local w = svc9:addIds(A.parseAdd(LC1 .. " " .. LC2), { { mesh = LC1, tex = TEX, name = "LC Gun 1" }, { mesh = LC2, tex = TEX, name = "LC Gun 2" } })
	T.eq(#w.added, 1, "mesh ids of hats you wear are found without looking anything up")

	local blind = newEnv(false)
	local svc10 = A.new(blind.api)
	svc10:load()
	local b = svc10:addIds(A.parseAdd(CAT1 .. " " .. CAT2), {})
	T.eq(b.later, 2, "when the executor can't look hats up, both wait to be looked up later")
	T.eq(#b.added, 2, "and are kept the old way")
end

local cfMeta = getmetatable(CFrame.new())
cfMeta.ToEulerAnglesYXZ = cfMeta.ToEulerAnglesYXZ or function(cf)
	local _, _, _, _, _, r02, r10, r11, r12, _, _, r22 = cf:GetComponents()
	local atan2 = math.atan2 or math.atan
	local sx = math.max(-1, math.min(1, -r12))
	return atan2(sx, math.sqrt(1 - sx * sx)), atan2(r02, r22), atan2(r10, r11)
end
cfMeta.ToOrientation = cfMeta.ToOrientation or cfMeta.ToEulerAnglesYXZ
_G.delay = function(t, f)
	return task.delay(t, f)
end
local genv = env.genv
genv.AtsukoNotify = function() end
local warned = {}
local oldWarn = warn
warn = function(...)
	local parts = {}
	for i = 1, select("#", ...) do
		parts[#parts + 1] = tostring((select(i, ...)))
	end
	warned[#warned + 1] = table.concat(parts, " ")
end

local function hubWith(rows)
	local svc = A.new({
		fetch = function()
			return true, "return { version = 1, help = {}, slots = {}, rig = {}, scripts = {} }"
		end,
		cframe = function(x, y, z, a, b, c)
			return CFrame.new(x, y, z) * CFrame.Angles(math.rad(a), math.rad(b), math.rad(c))
		end,
		publish = function(list, info)
			genv.AtsukoAligns = list
			genv.AtsukoAlignment = info
		end,
	})
	svc:load()
	local worn = { { mesh = LC1, tex = TEX, name = "LC Gun 1" }, { mesh = LC2, tex = TEX, name = "LC Gun 2" } }
	for _, text in ipairs(rows) do
		svc:addIds(A.parseAdd(text), worn)
	end
	return svc
end

local function runScript(path, opts)
	opts = opts or {}
	local S = { on = false }
	local FD = {
		reanimate = function()
			S.on = true
			local api = makeApi()
			function api.getCamCF()
				return CFrame.new(0, 5, 10)
			end
			S.api = api
			S.h1, S.j1 = api.hat("LC Gun 1", LC1, TEX, Vector3.new(6, 1.5, 1))
			if not opts.alone then
				S.h2, S.j2 = api.hat("LC Gun 2", LC2, TEX, Vector3.new(3, 1.5, 1))
			end
			api.hat("Cool Cap", "555", "556")
			return api
		end,
		stopreanimate = function()
			S.on = false
		end,
		isReanimated = function()
			return S.on
		end,
	}
	_G.GenesisFDless = FD
	genv.AtsukoHatFd = FD
	local fn, cerr = loadstring(readsource(path), "=" .. path)
	S.compiled, S.cerr = fn ~= nil, cerr
	task.spawn(function()
		local ok, e = pcall(fn)
		S.ended = { ok, e }
	end)
	env.run(0.3)
	S.step = function(n)
		for _ = 1, n do
			if S.api and S.api.modes.default then
				S.api.modes.default.idle()
			end
			env.frame()
		end
	end
	S.step(30)
	return S
end

local REL12 = A.holdOf({ mesh = LC1 }).mate.rel
local GUNS = {
	{ "The Hotline", "Scripts/Hat/FDless/TheHotline.lua" },
	{ "Addict", "Scripts/Hat/FDless/Addict.lua" },
	{ "Commander V2", "Scripts/Hat/FDless/CommanderV2.lua" },
	{ "Neptunian V Gun", "Scripts/Hat/FDless/NeptunianVGun.lua" },
	{ "Dubstep Gun (original)", "Scripts/Hat/FDless/DubstepGun.lua" },
}

T.section("lc_pair: every gun script holds LC Gun 1 and keeps LC Gun 2 joined to it")
hubWith({ LC1 .. " " .. LC2 })
for _, item in ipairs(GUNS) do
	local name, path = item[1], item[2]
	local S = runScript(path)
	T.ok(S.compiled, name .. " compiles: " .. tostring(S.cerr))
	T.ok(S.api ~= nil, name .. " reanimated")
	if S.api then
		T.ok(S.j1.Part1 ~= S.api.V.Head, name .. " took LC Gun 1 as its gun")
		T.eq(S.j2.Part1, S.h1, name .. " hangs LC Gun 2 on LC Gun 1")
		T.ok(near(S.j2.C1, REL12), name .. " uses the joint the two halves always have")
		local cfs = solve(S.api)
		T.ok(near(cfs[S.h2], cfs[S.h1] * REL12), name .. ": the halves line up as one gun")
		S.step(20)
		cfs = solve(S.api)
		T.ok(near(cfs[S.h2], cfs[S.h1] * REL12), name .. ": and stay lined up while it plays")
		env.run(3)
		T.eq(S.j2.Part1, S.api.V.Head, name .. ": stopping puts LC Gun 2 back where it was worn")
	end
end

T.section("lc_pair: The Hotline holds LC Gun 1 the way Uhhhhhh does")
do
	local S = runScript("Scripts/Hat/FDless/TheHotline.lua")
	if S.api then
		local held = S.j1.C1 * S.j1.C0:Inverse()
		local uh = UH_HAND * C1[LC1]:Inverse()
		local hand = held * uh:Inverse()
		T.ok(nearV(hand.Position, Vector3.new(0, 0, 0), 2), "the grip ends up at the hand, the pose only turns it a little: " .. tostring(hand.Position))
		local fwd = held:VectorToWorldSpace(A.holdOf({ mesh = LC1 }).hatFwd)
		T.ok(fwd.Y < -0.5, "and the barrel points down the arm, out of the hand")
		env.run(3)
	end
end

T.section("lc_pair: Snake Banisher holds each half in its own slot, joined")
do
	hubWith({})
	local S = runScript("Scripts/Hat/SnakeBanisherV3.lua")
	T.ok(S.api ~= nil, "it reanimated")
	if S.api then
		T.eq(S.j1.Part1, S.api.V["Right Arm"], "LC Gun 1 is in the right hand")
		T.eq(S.j2.Part1, S.api.V["Right Arm"], "and so is LC Gun 2")
		local cfs = solve(S.api)
		T.ok(near(cfs[S.h2], cfs[S.h1] * REL12), "they meet like Uhhhhhh puts them together, not on top of each other")
		local held = S.j1.C1 * S.j1.C0:Inverse()
		T.ok(not near(held, S.j2.C1 * S.j2.C0:Inverse()), "the two halves are not in the same spot any more")
		env.run(3)
	end
end

T.section("lc_pair: old rows, one half alone and a plain gun")
do
	local old = hubWith({})
	local worn = { { mesh = LC1, tex = TEX, name = "LC Gun 1" }, { mesh = LC2, tex = TEX, name = "LC Gun 2" } }
	old:addIds(A.parseAdd(LC1), worn)
	old:addIds(A.parseAdd(LC2), worn)
	local S = runScript("Scripts/Hat/FDless/TheHotline.lua")
	if S.api then
		local lead, mate = S.h1, S.h2
		if S.j1.Part1 == S.h2 then
			lead, mate = S.h2, S.h1
		end
		local cfs = solve(S.api)
		local rel = A.holdOf({ mesh = rawget(lead, "m") }).mate.rel
		T.ok(near(cfs[mate], cfs[lead] * rel), "with both halves saved the old way, whichever is held carries the other")
		env.run(3)
	end
	hubWith({ LC1 .. " " .. LC2 })
	local A1 = runScript("Scripts/Hat/FDless/TheHotline.lua", { alone = true })
	if A1.api then
		T.ok(A1.j1.Part1 ~= A1.api.V.Head, "LC Gun 1 alone is still held")
		env.run(3)
		T.eq(A1.j1.Part1, A1.api.V.Head, "and let go on stop")
	end
	T.eq(#warned > 0 and string.find(table.concat(warned, "\n"), "hubJoin", 1, true) or nil, nil, "nothing about joining went wrong")
end

T.section("lc_pair: The Sniper and Dubstep Gun (hub) do the same in their code")
do
	local sniper = readsource("Scripts/_unlisted/TheSniper.lua")
	T.ok(string.find(sniper, "GUN.base = T2 * known.fit", 1, true) ~= nil, "The Sniper holds a known half the Uhhhhhh way")
	T.ok(string.find(sniper, "GUN.unjoin = hubJoin(best)", 1, true) ~= nil, "joins the other half when it picks its gun")
	local _, stops = string.gsub(sniper, "GUN.unjoin%(%)", "")
	T.eq(stops, 2, "and lets it go when the gun changes and when it stops")
	local hub = readsource("Scripts/Hat/DubstepGun.lua")
	T.ok(string.find(hub, "mate.rel:Inverse()*cf", 1, true) ~= nil, "Dubstep Gun (hub) puts the second half on its gun at the same joint")
end

_G.GenesisFDless = nil
_G.delay = nil
genv.AtsukoHatFd = nil
warn = oldWarn
