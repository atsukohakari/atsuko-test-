local World = loadmodule("Testing/mocks/rbx_world.lua")
World.install({})
CFrame = loadmodule("Testing/mocks/cframe_math.lua").make(Vector3)
local makeApi = loadmodule("Testing/mocks/fake_fd.lua").make
local A = loadmodule("Hub/modules/alignment.lua")

local function comps(cf)
	return { cf:GetComponents() }
end
local function near(a, b, eps)
	local x, y = { a:GetComponents() }, { b:GetComponents() }
	for i = 1, 12 do
		if math.abs(x[i] - y[i]) > (eps or 1e-3) then
			return false
		end
	end
	return true
end

T.section("joined_pair: telling two parts of one item apart from two items")
T.eq(A.partsOf("Twin Blade Part 1", "Twin Blade Part 2"), true)
T.eq(A.partsOf("Big Gun (1/2)", "Big Gun (2/2)"), true)
T.eq(A.partsOf("Cannon Top", "Cannon Bottom"), true)
T.eq(A.partsOf("LC-Gun 1", "LC-Gun 2"), true, "the LC gun works the same way")
T.eq(A.partsOf("Left Katana", "Right Katana"), false, "two swords for two hands stay two hats")
T.eq(A.partsOf("Sword", "Sword"), false, "the same name twice isn't a pair")
T.eq(A.partsOf("Rifle", "Hat"), false)
T.eq(A.partsOf("1", "2"), false, "nothing but numbers says nothing")
T.eq(A.partsOf(nil, "Gun 2"), false)

T.section("joined_pair: how the parts sit together, from where they are worn")
do
	local back = { name = "BodyBackAttachment", cf = comps(CFrame.new()) }
	local back2 = { name = "BodyBackAttachment", cf = comps(CFrame.new(0, 1, 0)) }
	local rel = A.pairRel(back, back2)
	T.same(rel, { 0, -1, 0, 0, 0, 0 }, "two parts on the same spot keep their own offsets")
	local shoulder = { name = "RightShoulderAttachment", cf = comps(CFrame.new()) }
	T.same(A.pairRel(shoulder, back), { -1.5, -1, 0.5, 0, 0, 0 }, "parts on different spots are placed by the body")
	local turned = { name = "BodyBackAttachment", cf = comps(CFrame.Angles(0, math.rad(90), 0)) }
	local r = A.pairRel(back, turned)
	T.ok(math.abs(r[5] + 90) < 0.05 or math.abs(r[5] - 270) < 0.05, "turned parts keep their turn: " .. table.concat(r, ","))
	T.eq(A.pairRel(back, nil), nil, "without knowing where one is worn there is no fit")
	T.eq(A.pairRel(back, { name = "SomethingElse", cf = comps(CFrame.new()) }), nil)
	T.eq(A.cleanAtt({ name = "BodyBackAttachment", cf = { 1, 2 } }), nil, "a broken spot is dropped")
end

T.section("joined_pair: rows remember the second part")
do
	local row = A.cleanRow({ slot = "gun", mesh = "111", mate = "rbxassetid://222", rel = { 0, -1, 0, 0, 0, 0 } }, "script")
	T.eq(row.mate, "222")
	T.same(row.rel, { 0, -1, 0, 0, 0, 0 })
	local half = A.cleanRow({ slot = "gun", mesh = "111", mate = "222" }, "script")
	T.eq(half.mate, nil, "a mate without a fit is dropped")
	T.ok(string.find(A.rowText(row), "mate = \"222\"", 1, true) ~= nil and string.find(A.rowText(row), "rel = {0, -1, 0, 0, 0, 0}", 1, true) ~= nil, "and both are written to the file: " .. A.rowText(row))
end

local function newEnv(names, atts)
	local e = { files = {} }
	e.api = {
		fetch = function()
			return true, "return { version = 1, help = {}, slots = {}, rig = {}, scripts = {} }"
		end,
		readUser = function()
			return e.files.user
		end,
		writeUser = function(text)
			e.files.user = text
			return true
		end,
		cframe = function(x, y, z, rx, ry, rz)
			return CFrame.new(x, y, z) * CFrame.Angles(math.rad(rx), math.rad(ry), math.rad(rz))
		end,
		publish = function(_, info)
			e.info = info
		end,
		resolveHat = function(id)
			if names[id] then
				return { mesh = "rbxassetid://" .. id .. "0", tex = "", name = names[id], att = atts[id] }
			end
			return nil, "no such hat"
		end,
	}
	return e
end

T.section("joined_pair: add <part 1> <part 2> while a script runs")
do
	local names = { ["501"] = "Twin Blade Part 1", ["502"] = "Twin Blade Part 2" }
	local atts = {
		["501"] = { name = "BodyBackAttachment", cf = comps(CFrame.new()) },
		["502"] = { name = "BodyBackAttachment", cf = comps(CFrame.new(0, 2, 0)) },
	}
	local e = newEnv(names, atts)
	local svc = A.new(e.api)
	svc:load()
	local only = { name = "Linked Sword", slots = { "sword", "gun", "bullet" } }
	local report = svc:addIds(A.parseAdd("502 501"), {}, only)
	T.eq(#report.failed, 0, "nothing failed: " .. table.concat(report.failed, " | "))
	T.eq(#report.added, 1, "the two ids are one weapon")
	T.eq(report.added[1].joined, true)
	T.ok(string.find(report.added[1].use, "both parts joined", 1, true) ~= nil, report.added[1].use)
	T.eq(report.added[1].name, "Twin Blade Part 1 + Twin Blade Part 2", "part 1 leads, whatever order you typed")
	local rows = svc:userRows("script", "Linked Sword")
	T.eq(#rows, 1)
	T.eq(rows[1].slot, "sword", "a blade goes on the sword, not the bazooka")
	T.eq(rows[1].mesh, "5010")
	T.eq(rows[1].mate, "5020")
	T.same(rows[1].rel, { 0, -2, 0, 0, 0, 0 })
	local m = e.info.mate({ mesh = "5010" })
	T.ok(m ~= nil and m.mesh == "5020", "scripts can ask for the other part")

	local api = makeApi()
	local lead, leadJ = api.hat("Twin Blade Part 1", "5010", nil)
	local other, otherJ = api.hat("Twin Blade Part 2", "5020", nil)
	local undo, got = e.info.join(api, lead)
	T.ok(type(undo) == "function", "the script can join them")
	T.eq(got, other)
	T.eq(otherJ.Part1, lead, "the second part rides on the first")
	T.ok(near(otherJ.C1, CFrame.new(0, -2, 0)), "where it sits when worn")
	undo()
	T.eq(otherJ.Part1, api.V.Head, "and goes back after")
	T.eq(e.info.join(api, other), nil, "the second part alone joins nothing")
end

T.section("joined_pair: worn hats, a gun, and no script running")
do
	local e = newEnv({}, {})
	local svc = A.new(e.api)
	svc:load()
	local worn = {
		{ name = "Mega Cannon 1", mesh = "601", tex = "", att = { name = "RightShoulderAttachment", cf = comps(CFrame.new()) } },
		{ name = "Mega Cannon 2", mesh = "602", tex = "", att = { name = "BodyBackAttachment", cf = comps(CFrame.new()) } },
	}
	local report = svc:addIds(A.parseAdd("gun 601 602"), worn)
	T.eq(#report.added, 1)
	local guns = svc:userRows("shared", "gun")
	T.eq(#guns, 1, "one gun for every gun script")
	T.eq(guns[1].mate, "602")
	T.same(guns[1].rel, { -1.5, -1, 0.5, 0, 0, 0 })
end

T.section("joined_pair: when the fit can't be known they stay two hats")
do
	local names = { ["701"] = "Odd Sword 1", ["702"] = "Odd Sword 2" }
	local e = newEnv(names, {})
	local svc = A.new(e.api)
	svc:load()
	local report = svc:addIds(A.parseAdd("sword 701 702"), {}, { name = "Linked Sword", slots = { "sword", "gun", "bullet" } })
	T.ok(report.note ~= nil and string.find(report.note, "fit together", 1, true) ~= nil, "it says so: " .. tostring(report.note))
	T.eq(#svc:userRows("script", "Linked Sword"), 2, "and adds both")
	local plain = newEnv({ ["801"] = "Rifle", ["802"] = "Pistol" }, { ["801"] = { name = "BodyBackAttachment", cf = comps(CFrame.new()) }, ["802"] = { name = "BodyBackAttachment", cf = comps(CFrame.new()) } })
	local svc2 = A.new(plain.api)
	svc2:load()
	local r2 = svc2:addIds(A.parseAdd("gun 801 802"), {})
	T.eq(#r2.added, 2, "two different guns are two guns")
	for _, row in ipairs(svc2:userRows("shared", "gun")) do
		T.eq(row.mate, nil)
	end
end
