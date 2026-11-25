local World = loadmodule("Testing/mocks/rbx_world.lua")
local env = World.install({})
local Exact = loadmodule("Testing/mocks/cframe_math.lua").make(Vector3)
CFrame = Exact
local makeApi = loadmodule("Testing/mocks/fake_fd.lua").make
local A = loadmodule("Hub/modules/alignment.lua")

local LC1, LC2, TEX = "97638566524944", "118424096643898", "128238174721913"

local HATS = {
	["4500001"] = { mesh = "rbxassetid://5001", tex = "rbxassetid://6001", name = "Ice Katana" },
	["4500002"] = { mesh = "rbxassetid://5002", tex = "rbxassetid://6002", name = "Laser Pistol" },
	["4500003"] = { mesh = "rbxassetid://5003", tex = "rbxassetid://6003", name = "Fancy Top Hat" },
	["4500004"] = { mesh = "rbxassetid://5004", tex = "rbxassetid://6004", name = "Mystery Thing" },
	["4500005"] = { mesh = "rbxassetid://5005", tex = "rbxassetid://6005", name = "Gun Sword" },
}

local BUILTIN = [[return { version = 1, help = {}, slots = {}, rig = {}, scripts = {
	["Neptunian V"] = { { slot = "sword", mesh = "5004" } },
} }]]

local function newSvc(builtin)
	local e = { files = {} }
	e.api = {
		fetch = function()
			return true, builtin or "return { version = 1, help = {}, slots = {}, rig = {}, scripts = {} }"
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
		resolveHat = function(id)
			local h = HATS[id]
			if h then
				return { mesh = h.mesh, tex = h.tex, name = h.name }
			end
			return nil, "no such hat"
		end,
	}
	local svc = A.new(e.api)
	svc:load()
	return e, svc
end

T.section("add: the job can come first, after the id, or after as")
do
	local p = A.parseAdd("sword 4500001")
	T.ok(p ~= nil, "add sword <id> is understood")
	T.eq(p.use, "sword")
	T.same(p.ids, { "4500001" })
	T.eq(A.parseAdd("gun 4500002").use, "gun", "add gun <id>")
	T.eq(A.parseAdd("4500002 gun").use, "gun", "add <id> gun")
	T.eq(A.parseAdd("4500002 as gun").use, "gun", "add <id> as gun still works")
	T.eq(A.parseAdd("as sword 4500001").use, "sword", "add as sword <id>")
	T.eq(A.parseAdd("Sword 4500001").use, "sword", "any case")
	local two = A.parseAdd("guns 4500001 4500002")
	T.eq(two.use, "guns", "a plural is fine")
	T.eq(A.useOf(two.use, 1, 2), "shared", "and means the same")
	local _, target = A.useOf(two.use, 1, 2)
	T.eq(target, "gun")
	T.eq(A.parseAdd("right arm 4500003").use, "rightarm", "right arm as two words")
	T.eq(A.parseAdd("4500003 as left leg").use, "leftleg")
	T.eq(A.parseAdd("pair " .. LC1 .. " " .. LC2).use, "pair")
	local bad, why = A.parseAdd("gun 4500001 as sword")
	T.eq(bad, nil, "two different jobs are refused")
	T.ok(string.find(why, "one job per add", 1, true) ~= nil, "and it says so: " .. tostring(why))
	T.ok(A.parseAdd("gun 4500002 as gun") ~= nil, "saying the same job twice is fine")
	local nope, msg = A.parseAdd("banana 4500001")
	T.eq(nope, nil, "a word that isn't an id or a job is refused")
	T.ok(string.find(msg, "banana", 1, true) ~= nil and string.find(msg, "sword", 1, true) ~= nil, "naming the word and the jobs: " .. tostring(msg))
	local none, noneWhy = A.parseAdd("sword")
	T.eq(none, nil, "a job with no id is refused")
	T.ok(string.find(noneWhy, "add sword 4506945409", 1, true) ~= nil, "with an example: " .. tostring(noneWhy))
end

T.section("add: at belongs to the one hat right before it")
do
	local p = A.parseAdd("4500001 at 0 1 0 4500002")
	T.same(p.ids, { "4500001", "4500002" })
	T.same(p.aligns[1], { 0, 1, 0 }, "the first hat gets the spot")
	T.eq(p.aligns[2], nil, "the second one doesn't")
	local q = A.parseAdd("sword at 0 1 0 90 0 0 4500001")
	T.same(q.aligns[1], { 0, 1, 0, 90, 0, 0 }, "at before the id goes to the id after it")
	local r = A.parseAdd("4500001 at 1 2 3 4500002 at 4 5 6")
	T.same(r.aligns[2], { 4, 5, 6 }, "each hat can have its own")
	T.same(r.align, { 1, 2, 3 }, "align is still the first one, for older callers")
	T.eq((A.parseAdd("4500001 at 1 2 3 at 4 5 6")), nil, "two at for one hat is refused")
	T.eq((A.parseAdd("at 1 2 3")), nil, "an at with no hat is refused")
	T.eq((A.parseAdd("4500001 at 1 2")), nil, "at needs three numbers")
	local e, svc = newSvc()
	T.eq((A.parseAdd("sword 4500001 at 0 1 0 gun 4500002")), nil, "two jobs in one add are refused, even split up")
	local rep = svc:addIds(A.parseAdd("any 4500001 at 0 1 0 4500003"), {})
	T.eq(#rep.added, 2)
	local rows = svc:userRows("shared", "any")
	local byMesh = {}
	for _, row in ipairs(rows) do
		byMesh[row.mesh] = row
	end
	T.same(byMesh["5001"].align, { 0, 1, 0, 0, 0, 0 }, "the hat with at keeps its spot")
	T.eq(byMesh["5003"].align, nil, "and the other hat doesn't get a copy of it")
	T.ok(e.files.user ~= nil)
end

T.section("add: with no job it works out gun or sword")
do
	T.eq(A.kindFromName("Ice Katana"), "sword")
	T.eq(A.kindFromName("Classic Sword"), "sword")
	T.eq(A.kindFromName("Darkheart"), "sword", "the famous swords by name")
	T.eq(A.kindFromName("LightSaber"), "sword")
	T.eq(A.kindFromName("Battleaxe"), "sword")
	T.eq(A.kindFromName("Laser Pistol"), "gun")
	T.eq(A.kindFromName("LCGun1"), "gun", "joined words and numbers are split")
	T.eq(A.kindFromName("LC-Gun 2"), "gun")
	T.eq(A.kindFromName("Pump Shotgun"), "gun")
	T.eq(A.kindFromName("Handgun"), "gun")
	T.eq(A.kindFromName("Burgundy Hat"), nil, "gun inside another word doesn't count")
	T.eq(A.kindFromName("Fancy Top Hat"), nil)
	T.eq(A.kindFromName("Gun Sword"), nil, "both words means it can't tell")
	T.eq(A.kindFromName(nil), nil)

	local e, svc = newSvc(BUILTIN)
	local r = svc:addIds(A.parseAdd("4500001"), {})
	T.eq(#r.added, 1)
	T.eq(r.added[1].use, "sword in every script with a sword", "Ice Katana became a sword")
	T.eq(r.added[1].guess, "sword")
	T.eq(r.added[1].how, "name")
	T.eq(#r.unsure, 0, "it was sure")
	T.eq(#svc:userRows("shared", "sword"), 1)
	T.eq(svc:userRows("shared", "sword")[1].note, A.GUESS_NOTE, "the row says it was worked out")
	T.eq(e.info.match("The Hotline", "gun", { mesh = "5001", tex = "6001" }), nil, "so gun scripts leave it alone")
	T.ok(e.info.match("Neptunian V", "sword", { mesh = "5001", tex = "6001" }) ~= nil, "and sword scripts take it")

	local g = svc:addIds(A.parseAdd("4500002"), {})
	T.eq(g.added[1].use, "gun in every script with a gun", "Laser Pistol became a gun")
	T.ok(e.info.match("The Sniper", "gun", { mesh = "5002", tex = "6002" }) ~= nil)
	T.ok(e.info.match("Snake Banisher V3", "gun1", { mesh = "5002", tex = "6002" }) ~= nil, "Snake Banisher's first gun too")
	T.ok(e.info.match("Master Chief", "rifle", { mesh = "5002", tex = "6002" }) ~= nil, "a gun is Master Chief's rifle now")
	T.ok(e.info.match("Master Chief", "shotgun", { mesh = "5002", tex = "6002" }) ~= nil, "and his shotgun")
	T.eq(e.info.match("Last Star", "sword", { mesh = "5002", tex = "6002" }), nil, "but no sword")

	local k = svc:addIds(A.parseAdd("4500004"), {})
	T.eq(k.added[1].how, "list", "a hat the shipped list knows goes by the list")
	T.eq(k.added[1].use, "sword in every script with a sword")

	local u = svc:addIds(A.parseAdd("4500003"), {})
	T.eq(u.added[1].use, "gun and sword in every script", "a hat it can't read is both for now")
	T.eq(#u.unsure, 1, "and the report says it wasn't sure")
	T.eq(u.unsure[1].name, "Fancy Top Hat")
	local both = svc:addIds(A.parseAdd("4500005"), {})
	T.eq(#both.unsure, 1, "a gun sword can't be told either")

	local lc = svc:addIds(A.parseAdd(LC1), { { mesh = LC1, tex = TEX } })
	T.eq(lc.added[1].how, "known", "an LC gun half needs no name")
	T.eq(lc.added[1].use, "gun in every script with a gun")
end

T.section("add: saying the job later fixes a guess")
do
	local e, svc = newSvc()
	svc:addIds(A.parseAdd("4500003"), {})
	T.eq(#svc:userRows("shared", "any"), 1, "unsure, so it is under any")
	local r = svc:addIds(A.parseAdd("gun 4500003"), {})
	T.eq(#r.added, 1)
	T.eq(r.added[1].replaced, 1, "add gun swaps the any row out")
	T.eq(#svc:userRows("shared", "any"), 0, "no any row left")
	T.eq(#svc:userRows("shared", "gun"), 1, "it is a gun now")
	T.eq(e.info.match("Neptunian V", "sword", { mesh = "5003", tex = "6003" }), nil, "and not a sword any more")

	svc:addIds(A.parseAdd("4500001"), {})
	T.eq(#svc:userRows("shared", "sword"), 1, "Ice Katana was guessed a sword")
	local fix = svc:addIds(A.parseAdd("gun 4500001"), {})
	T.eq(fix.added[1].replaced, 1, "saying gun replaces the guess")
	T.eq(#svc:userRows("shared", "sword"), 0)

	svc:addIds(A.parseAdd("sword 4500002"), {})
	svc:addIds(A.parseAdd("gun 4500002"), {})
	local swords = 0
	for _, row in ipairs(svc:userRows("shared", "sword")) do
		if row.mesh == "5002" then
			swords += 1
		end
	end
	T.eq(swords, 1, "a job you said yourself stays when you add another")

	svc:addIds(A.parseAdd("4500003 as any at 0 2 0"), {})
	local moved = svc:addIds(A.parseAdd("sword 4500003"), {})
	T.eq(#moved.added, 1)
	local sw = nil
	for _, row in ipairs(svc:userRows("shared", "sword")) do
		if row.mesh == "5003" then
			sw = row
		end
	end
	T.same(sw and sw.align, { 0, 2, 0, 0, 0, 0 }, "a spot given with at comes along when the guess is fixed")

	local again = svc:addIds(A.parseAdd("4500001"), {})
	local again2 = svc:addIds(A.parseAdd("4500001"), {})
	local twice = 0
	for _, kind in ipairs(A.SHARED) do
		local n = 0
		for _, r in ipairs(svc:userRows("shared", kind)) do
			if r.mesh == "5001" then
				n += 1
			end
		end
		twice = math.max(twice, n)
	end
	T.eq(twice, 1, "adding the same guess twice doesn't double it")
	T.ok(#again2.added == 0 or again2.added[1].already == true, "and says it was already there")
	T.ok(#again.added + #again.failed >= 1)
end

T.section("add: LC gun halves stay out of Master Chief")
do
	local e, svc = newSvc()
	svc:addIds(A.parseAdd(LC1 .. " " .. LC2), { { mesh = LC1, tex = TEX }, { mesh = LC2, tex = TEX } })
	T.ok(e.info.match("The Hotline", "gun", { mesh = LC1, tex = TEX }) ~= nil, "gun scripts hold LC Gun 1")
	T.eq(e.info.match("Master Chief", "rifle", { mesh = LC1, tex = TEX }), nil, "Master Chief can't join the halves, so it doesn't take half a gun")
	T.eq(e.info.match("Master Chief", "shotgun", { mesh = LC1, tex = TEX }), nil)
	svc:addIds(A.parseAdd(LC1 .. " as rifle"), { { mesh = LC1, tex = TEX } })
	T.ok(e.info.match("Master Chief", "rifle", { mesh = LC1, tex = TEX }) ~= nil, "unless you say as rifle yourself")
	T.eq(A.sharedKind("rifle"), "rifle", "the closest kind comes first")
	T.same(A.sharedKinds("rifle"), { "rifle", "gun", "any" })
	T.same(A.sharedKinds("gun"), { "gun", "any" })
	T.same(A.sharedKinds("sword"), { "sword", "any" })
end

T.section("add: hats found on the reanimation")
do
	local accA = { Name = "Cool Sword" }
	local accB = { Name = "Fancy Top Hat" }
	local frames = {
		[{ m = "rbxassetid://7001", t = "rbxassetid://7002", p = { Parent = accA } }] = CFrame.new(),
		[{ m = "http://www.roblox.com/asset/?id=7003", t = "", p = { Parent = accB } }] = CFrame.new(),
		[{ p = {} }] = CFrame.new(),
	}
	local list = A.fdHats({ cframes = frames })
	T.eq(#list, 2, "the hats are read from the reanimation, body parts are skipped")
	local byMesh = {}
	for _, h in ipairs(list) do
		byMesh[h.mesh] = h
	end
	T.eq(byMesh["7001"] and byMesh["7001"].name, "Cool Sword", "with the accessory name")
	T.eq(byMesh["7003"] and byMesh["7003"].mesh, "7003", "a long mesh link is read too")
	T.same(A.fdHats(nil), {})
	T.same(A.fdHats({}), {})
	local joined = A.joinWorn({ { mesh = "7001", tex = "7002" } }, list)
	T.eq(#joined, 2, "the same hat from two places counts once")
	T.eq(joined[1].name, "Cool Sword", "and keeps a name if one place has it")
	local _, svc = newSvc()
	local r = svc:addIds(A.parseAdd("7001"), list)
	T.eq(#r.added, 1, "a mesh id of a hat on the reanimation is found without looking anything up")
	T.eq(r.added[1].use, "sword in every script with a sword", "and its name makes it a sword")
end

local function fakeAL(title, tabs)
	local AL = { title = title, tabs = tabs, vals = {}, held = {}, puts = 0, resets = 0 }
	for s = 1, #tabs do
		AL.vals[s] = { 0, 0, 0, 0, 0, 0 }
	end
	function AL.get(s)
		local v = AL.vals[s]
		if not v then
			return nil
		end
		return { v[1], v[2], v[3], v[4], v[5], v[6] }
	end
	function AL.put(s, v)
		AL.puts += 1
		for k = 1, 6 do
			AL.vals[s][k] = tonumber(v[k]) or 0
		end
	end
	function AL.reset(s)
		AL.resets += 1
		AL.put(s, { 0, 0, 0, 0, 0, 0 })
	end
	function AL.set(s, k, n)
		AL.vals[s][k] = n
	end
	function AL.hat(s)
		local h = AL.held[s]
		if h then
			return h[1], h[2], h[3], h[4]
		end
		return nil
	end
	return AL
end

T.section("spots: each hat keeps its own spot")
do
	local e, svc = newSvc()
	svc:addIds(A.parseAdd("gun 4500002"), {})
	svc:addIds(A.parseAdd("4500003"), {})
	T.eq(svc:isUserHat("5002"), true, "a hat you added is yours")
	T.eq(svc:isUserHat("4500002"), true, "by its hat id too")
	T.eq(svc:isUserHat("rbxassetid://5002"), true, "and as a link")
	T.eq(svc:isUserHat("7777"), false, "the script's own gun is not")
	T.eq(A.tracker(svc, {}), nil, "a script without hat tells is left alone")

	local AL = fakeAL("The Hotline", { "Gun", "Muzzle" })
	AL.vals[1] = { 1, 0, 0, 0, 0, 0 }
	local switches, changes = {}, 0
	local tr = A.tracker(svc, AL, {
		switch = function(s, key, how)
			switches[#switches + 1] = s .. ":" .. tostring(key) .. ":" .. tostring(how)
		end,
		changed = function()
			changes += 1
		end,
	})
	T.ok(tr ~= nil)
	tr:tick()
	T.eq(AL.puts, 0, "nothing held, nothing moved")

	AL.held[1] = { "7777", "7777", "LC Gun" }
	AL.held[2] = { "7777", "7777", "LC Gun" }
	tr:tick()
	T.eq(tr:keyOf(1), "7777")
	T.eq(tr:nameOf(1), "LC Gun")
	T.same(svc:spot("The Hotline", "Gun", "7777"), { 1, 0, 0, 0, 0, 0 }, "the script's own gun keeps the spot you had from before")
	T.eq(switches[1], "1:7777:kept")
	T.ok(changes > 0 and tr.dirty, "and it asks to be saved")

	AL.set(1, 2, 0.5)
	tr:tick()
	T.same(svc:spot("The Hotline", "Gun", "7777"), { 1, 0.5, 0, 0, 0, 0 }, "a nudge is saved for that gun")

	AL.held[1] = { "5002", "5002", "Laser Pistol" }
	AL.held[2] = { "5002", "5002", "Laser Pistol" }
	tr:tick()
	T.same(AL.vals[1], { 0, 0, 0, 0, 0, 0 }, "the pistol you added does not take the LC gun's spot")
	T.eq(switches[#switches - 1], "1:5002:new")
	T.eq(svc:spot("The Hotline", "Gun", "5002"), nil, "and nothing is saved for it until you move it")
	AL.set(1, 1, 2)
	AL.set(2, 3, -1)
	tr:tick()
	T.same(svc:spot("The Hotline", "Gun", "5002"), { 2, 0, 0, 0, 0, 0 }, "moving it saves its own spot")
	T.same(svc:spot("The Hotline", "Muzzle", "5002"), { 0, 0, -1, 0, 0, 0 }, "the muzzle is kept per gun too")

	AL.held[1] = { "5003", "5003", "Fancy Top Hat" }
	AL.held[2] = nil
	tr:tick()
	T.same(AL.vals[1], { 0, 0, 0, 0, 0, 0 }, "the next hat starts from the default, not the pistol's spot")

	AL.held[1] = { "8888", "8888", "Some Hat" }
	tr:tick()
	T.same(AL.vals[1], { 0, 0, 0, 0, 0, 0 }, "a hat the script found by itself starts from the default too")
	T.eq(svc:spot("The Hotline", "Gun", "8888"), nil)

	AL.held[1] = { "5002", "5002", "Laser Pistol" }
	tr:tick()
	T.same(AL.vals[1], { 2, 0, 0, 0, 0, 0 }, "back to the pistol, back to its spot")
	T.eq(switches[#switches], "1:5002:saved")
	AL.held[1] = { "7777", "7777", "LC Gun" }
	tr:tick()
	T.same(AL.vals[1], { 1, 0.5, 0, 0, 0, 0 }, "back to the LC gun, back to its spot")

	AL.set(1, 1, 9)
	T.eq(tr:reload(1), "saved", "reload puts the saved spot back")
	T.same(AL.vals[1], { 1, 0.5, 0, 0, 0, 0 })
	T.eq(tr:forget(1), true, "forget drops the spot")
	T.eq(svc:spot("The Hotline", "Gun", "7777"), nil)
	T.same(AL.vals[1], { 0, 0, 0, 0, 0, 0 }, "and goes back to the default")
	T.eq(tr:reload(1), "new")

	local AL2 = fakeAL("Neptunian V", { "Hand", "Back", "Base" })
	local tr2 = A.tracker(svc, AL2)
	AL2.vals[1] = { 0, 0, 0, 45, 0, 0 }
	AL2.held[1] = { "katana:9999", "9999", "Some Sword", true }
	tr2:tick()
	T.same(svc:spot("Neptunian V", "Hand", "katana:9999"), { 0, 0, 0, 45, 0, 0 }, "a script that already shows the hat's own spot keeps it")
	T.eq(AL2.puts, 0, "without putting anything back")

	local AL3 = fakeAL("Commander V2", { "Gun", "Muzzle" })
	AL3.hat = function()
		error("broken")
	end
	local tr3 = A.tracker(svc, AL3)
	tr3:tick()
	T.eq(tr3:keyOf(1), nil, "a script whose hat tell breaks is just skipped")

	T.ok(svc:save(), "it saves")
	T.ok(string.find(e.files.user, "spots = {", 1, true) ~= nil, "the spots are in your hat file")
	T.ok(string.find(e.files.user, '["The Hotline"] = {', 1, true) ~= nil)
	local again = A.new(e.api)
	again:load()
	T.same(again:spot("The Hotline", "Gun", "5002"), { 2, 0, 0, 0, 0, 0 }, "and come back after a restart")
	T.same(again:spot("The Hotline", "Muzzle", "5002"), { 0, 0, -1, 0, 0, 0 })
	T.eq(#again:userRows("shared", "gun"), 1, "next to your hats")
	again:addIds(A.parseAdd("sword 4500001"), {})
	local third = A.new(e.api)
	third:load()
	T.same(third:spot("The Hotline", "Gun", "5002"), { 2, 0, 0, 0, 0, 0 }, "adding another hat keeps them")
end

T.section("spots: bad values are dropped and there is a limit")
do
	local data, problems = A.clean({ spots = {
		X = { Gun = { ["1"] = { 1e9, 0, 0 }, ["2"] = { "a" }, ["3"] = { 1, 2, 3 }, [4] = { 4, 5, 6, 7, 8, 9 } } },
		Y = "nope",
	} })
	T.eq(data.spots.X.Gun["1"], nil, "a huge number is dropped")
	T.eq(data.spots.X.Gun["2"], nil, "text is dropped")
	T.same(data.spots.X.Gun["3"], { 1, 2, 3, 0, 0, 0 }, "three numbers are filled out")
	T.same(data.spots.X.Gun["4"], { 4, 5, 6, 7, 8, 9 }, "a number key becomes text")
	T.eq(data.spots.Y, nil)
	T.eq(#problems, 0)
	local _, p2 = A.clean({ spots = "nope" })
	T.eq(#p2, 1, "spots that aren't a table are a problem")
	local _, svc = newSvc()
	local saved = A.MAX_SPOTS
	A.MAX_SPOTS = 2
	T.ok(svc:setSpot("S", "Gun", "1", { 1, 0, 0 }))
	T.ok(svc:setSpot("S", "Gun", "2", { 1, 0, 0 }))
	local ok, why = svc:setSpot("S", "Gun", "3", { 1, 0, 0 })
	T.eq(ok, false, "past the limit a new hat isn't saved")
	T.ok(string.find(why, "2", 1, true) ~= nil)
	T.ok(svc:setSpot("S", "Gun", "1", { 2, 0, 0 }), "an old one can still move")
	A.MAX_SPOTS = saved
	T.eq(svc:setSpot("S", "Gun", "x", { 0 / 0, 0, 0 }), false, "not a number is refused")
	T.eq(svc:setSpot(nil, "Gun", "x", { 0, 0, 0 }), false)
	T.eq(svc:dropSpot("S", "Gun", "nope"), false)
	T.eq(svc:dropSpot("S", "Gun", "1"), true)
	T.eq(svc:dropSpot("S", "Gun", "2"), true)
	T.eq(svc.userData.spots.S, nil, "an empty script is cleaned away")
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
local oldWarn = warn
warn = function() end

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

local function runScript(path)
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
			S.h2, S.j2 = api.hat("LC Gun 2", LC2, TEX, Vector3.new(3, 1.5, 1))
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
	genv.AtsukoAlign = nil
	local fn, cerr = loadstring(readsource(path), "=" .. path)
	S.compiled, S.cerr = fn ~= nil, cerr
	task.spawn(function()
		pcall(fn)
	end)
	env.run(0.3)
	for _ = 1, 30 do
		if S.api and S.api.modes.default then
			S.api.modes.default.idle()
		end
		env.frame()
	end
	S.AL = genv.AtsukoAlign
	return S
end

T.section("spots: the scripts tell the hub which hat is on each tab")
do
	local svc = hubWith({ LC1 .. " " .. LC2 })
	local CASES = {
		{ "The Hotline", "Scripts/Hat/FDless/TheHotline.lua", { LC1, LC1 } },
		{ "Addict", "Scripts/Hat/FDless/Addict.lua", { LC1, LC1, false, false, false, false } },
		{ "Commander V2", "Scripts/Hat/FDless/CommanderV2.lua", { LC1, LC1 } },
		{ "Neptunian V", "Scripts/Hat/FDless/NeptunianVGun.lua", { false, LC1, LC1, false } },
		{ "Dubstep Gun", "Scripts/Hat/FDless/DubstepGun.lua", { LC1, LC1, false, false, false, false } },
		{ "Snake Banisher V3", "Scripts/Hat/SnakeBanisherV3.lua", { LC1, LC2, LC1 } },
	}
	for _, case in ipairs(CASES) do
		local title, path, want = case[1], case[2], case[3]
		local S = runScript(path)
		T.ok(S.compiled, title .. " compiles: " .. tostring(S.cerr))
		local AL = S.AL
		T.ok(type(AL) == "table" and type(AL.hat) == "function", title .. " has a hat tell")
		if type(AL) == "table" and type(AL.hat) == "function" then
			T.eq(AL.title, title)
			for s, key in ipairs(want) do
				local got, mesh, name = AL.hat(s)
				if key then
					T.eq(got, key, title .. " tab " .. tostring(AL.tabs[s]) .. " holds the right hat")
					T.eq(mesh, key, "with its mesh")
					T.ok(type(name) == "string" and string.find(name, "LC Gun", 1, true) ~= nil, "and its name: " .. tostring(name))
				else
					T.eq(got, nil, title .. " tab " .. tostring(AL.tabs[s]) .. " is not about a hat")
				end
			end
			local tr = A.tracker(svc, AL)
			tr:tick()
			T.eq(tr.how[1] or tr.how[2], "new", title .. ": the LC gun you added starts at the default spot")
			local tab = want[1] and 1 or 2
			T.same(AL.get(tab), { 0, 0, 0, 0, 0, 0 }, title .. ": nothing carried over")
			AL.set(tab, 2, 0.25)
			tr:tick()
			local spot = svc:spot(title, tr:tabName(tab), LC1)
			T.ok(spot ~= nil and spot[2] == 0.25, title .. ": a nudge is saved for LC Gun 1 only")
		end
		env.run(3)
	end
end

T.section("spots: Master Chief and Neptunian V tell their hats too")
do
	local mc = readsource("Scripts/Hat/FDless/MasterChief.lua")
	T.ok(string.find(mc, 'local r = M.slots[i == 1 and "rifle" or i == 2 and "shotgun" or ""]', 1, true) ~= nil, "Master Chief tells the rifle and the shotgun hat")
	T.ok(string.find(mc, "function AL.hat(i)", 1, true) ~= nil)
	local nv = readsource("Scripts/Hat/FDless/NeptunianV.lua")
	T.ok(string.find(nv, 'return tostring(activeKey) .. ":" .. id, id, type(name) == "string" and name or nil, true', 1, true) ~= nil, "Neptunian V keys the spot by sword and hat, and keeps the spot it shows")
	for _, path in ipairs({ "Scripts/Hat/FDless/MasterChief.lua", "Scripts/Hat/FDless/NeptunianV.lua" }) do
		local f, err = loadstring(readsource(path), "=" .. path)
		T.ok(f ~= nil, path .. " compiles: " .. tostring(err))
	end
end

_G.GenesisFDless = nil
_G.delay = nil
genv.AtsukoHatFd = nil
genv.AtsukoAlign = nil
warn = oldWarn
