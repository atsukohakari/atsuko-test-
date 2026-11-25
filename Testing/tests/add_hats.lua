local A = loadmodule("Hub/modules/alignment.lua")
local Ui = loadmodule("Hub/modules/alignment_ui.lua")

local function newEnv()
	local env = { files = {} }
	env.api = {
		fetch = function()
			return true, "return { version = 1, help = {}, slots = {}, rig = {}, scripts = {} }"
		end,
		saveCache = function(body)
			env.files.cache = body
			return true
		end,
		readCache = function()
			return env.files.cache
		end,
		readUser = function()
			return env.files.user
		end,
		writeUser = function(text)
			env.files.user = text
			return true
		end,
		cframe = function(...)
			return { cf = { ... } }
		end,
		publish = function(list, info)
			env.info = info
		end,
		resolveHat = function(id)
			if id == "4506945409" then
				return { mesh = "rbxassetid://111", tex = "rbxassetid://222", name = "My Hat" }
			end
			if id == "4506945410" then
				return { mesh = "rbxassetid://333", tex = "rbxassetid://444", name = "My Pistol" }
			end
			return nil, "no such hat"
		end,
	}
	return env
end

T.section("add_hats: one add is a gun and a sword for every script")
do
	local parsed, why = A.parseAdd("4506945409")
	T.ok(parsed ~= nil, "a plain id is understood: " .. tostring(why))
	T.eq(parsed.use, nil, "nothing after it")
	local section, target = A.useOf(parsed.use, 1, 1)
	T.eq(section, "shared", "it is for every script")
	T.eq(target, "any", "as any weapon")
	local s2, t2 = A.useOf(nil, 2, 2)
	T.eq(s2 .. "/" .. t2, "shared/any", "two ids are both for every script too")
	for _, word in ipairs({ "any", "all", "both", "weapon", "every" }) do
		local s, t = A.useOf(word, 1, 1)
		T.eq(s .. "/" .. tostring(t), "shared/any", "as " .. word .. " means every weapon")
	end
	local sg, tg = A.useOf("gun", 1, 1)
	T.eq(sg .. "/" .. tg, "shared/gun", "as gun keeps it to guns")
	local ss, ts = A.useOf("sword", 1, 1)
	T.eq(ss .. "/" .. ts, "shared/sword", "as sword keeps it to swords")
	local sp, tp, _, slot1 = A.useOf("pair", 1, 2)
	local _, _, _, slot2 = A.useOf("pair", 2, 2)
	T.eq(sp .. "/" .. tp, "script/Snake Banisher V3", "as pair is Snake Banisher's two guns")
	T.eq(slot1 .. "/" .. slot2, "gun1/gun2", "the first id is gun 1, the second gun 2")
	local sr, _, part = A.useOf("rightarm", 1, 1)
	T.eq(sr .. "/" .. part, "rig/Right Arm", "as rightarm is a body part")
	T.ok(A.parseAdd("123 as pair") ~= nil, "as pair is understood")
	T.ok(A.parseAdd("123 as any") ~= nil, "as any is understood")
	local bad, msg = A.parseAdd("123 as banana")
	T.eq(bad, nil, "an unknown job is refused")
	T.ok(string.find(msg, "any", 1, true) ~= nil and string.find(msg, "pair", 1, true) ~= nil, "and the message lists any and pair: " .. tostring(msg))
	T.eq(A.useText("shared", "any"), "gun and sword in every script", "the report says what it became")
	T.eq(A.useText("shared", "sword"), "sword in every script with a sword")
end

T.section("add_hats: a hat it can't read is the gun and the sword in every script")
do
	local env = newEnv()
	local svc = A.new(env.api)
	T.eq((svc:load()), true, "the hat list loads")
	local parsed = A.parseAdd("4506945409")
	local report = svc:addIds(parsed, {})
	T.eq(#report.added, 1, "it is added")
	T.eq(#report.failed, 0, "nothing failed")
	T.eq(report.added[1].use, "gun and sword in every script")
	T.eq(#svc:userRows("shared", "any"), 1, "saved once, under any")
	T.ok(string.find(env.files.user, "any = {", 1, true) ~= nil, "and written to the hat file")
	local hat = { mesh = "111", tex = "222", name = "My Hat" }
	local seen = {}
	for _, item in ipairs(Ui.JOBS) do
		local script, slots = item[1], item[2]
		for _, slot in ipairs(slots) do
			local row = env.info.match(script, slot, hat)
			local weapon = A.SHARED_SLOTS.any[slot] == true
			if weapon then
				T.ok(row ~= nil and row.src == "user", script .. " uses it as its " .. slot)
				seen[script] = true
			else
				T.eq(row, nil, script .. " leaves its " .. slot .. " alone")
			end
		end
	end
	for _, script in ipairs({ "Addict", "Commander V2", "Dubstep Gun", "Last Star", "Master Chief", "Neptunian V", "Neptunian V Gun", "Snake Banisher V3", "Studio Dummy V4", "The Hotline", "The Sniper" }) do
		T.ok(seen[script], script .. " picks it up")
	end
	T.eq(#env.info.mine("Snake Banisher V3", "gun1"), 1, "Snake Banisher's first gun reads it with mine")
	T.eq(#env.info.mine("Snake Banisher V3", "gun2"), 0, "its second gun waits for as pair")
	T.eq(#env.info.mine("Dubstep Gun", "gun"), 1, "Dubstep Gun reads it with mine too")
	local again = svc:addIds(A.parseAdd("4506945409"), {})
	T.eq(#again.added == 1 and again.added[1].already, true, "adding it twice says it's already added")
	T.eq(#svc:userRows("shared", "any"), 1, "and doesn't double it")
	local gunOnly = svc:addIds(A.parseAdd("4506945410 as gun"), {})
	T.eq(#gunOnly.added, 1)
	local pistol = { mesh = "333", tex = "444" }
	T.ok(env.info.match("The Hotline", "gun", pistol) ~= nil, "as gun is a gun")
	T.eq(env.info.match("Neptunian V", "sword", pistol), nil, "and not a sword")
	local first = env.info.rows("The Hotline", "gun")[1]
	T.eq(first.mesh, "333", "a hat added just for guns comes before the any hat for gun scripts")
	local reloaded = A.new(env.api)
	reloaded:load()
	T.eq(#reloaded:userRows("shared", "any"), 1, "it is still there after a reload")
end

T.section("add_hats: the hats window knows about any")
do
	T.same(Ui.SHARED, A.SHARED, "the window and the hat list know the same kinds")
	T.eq(Ui.WEAPONS[1][1], "any", "Any is the first weapon choice")
	T.eq(Ui.targetText({ target = "any" }), "Used by: every script with a weapon")
	T.ok(string.find(Ui.whoText("any"), "Last Star", 1, true) ~= nil, "Last Star is one of the scripts that use it")
	for kind, slots in pairs(A.SHARED_SLOTS) do
		for slot in pairs(slots) do
			T.eq(Ui.SHARED_SLOTS[kind][slot], true, "the window agrees on " .. kind .. " " .. slot)
		end
	end
end

T.section("add_hats: Last Star's empty sword wings take an added hat")
do
	local src = readsource("Scripts/Hat/FDless/LastStar.lua")
	T.ok(type(src) == "string", "Last Star can be read")
	if type(src) == "string" then
		T.ok(string.find(src, 'pcall(A.match, "Last Star", "sword"', 1, true) ~= nil, "it asks the hat list for swords you added")
		T.ok(string.find(src, 'row.src == "user"', 1, true) ~= nil, "and only takes hats you added")
	end
end

T.section("add_hats: a sword you wear is used by every sword script, however it asks")
do
	local env = newEnv()
	local svc = A.new(env.api)
	svc:load()
	local worn = { { mesh = "5551", tex = "6661", name = "Cool Katana" } }
	local report = svc:addIds(A.parseAdd("sword 5551"), worn)
	T.eq(#report.added, 1, "the worn sword is added")
	T.eq(#report.failed, 0)
	local probes = {
		["Neptunian V"] = { mesh = "5551", name = "Cool Katana" },
		["Neptunian V Gun"] = { mesh = "5551", tex = "6661", name = "Cool Katana" },
		["Last Star"] = { mesh = "5551", tex = "6661" },
	}
	for script, probe in pairs(probes) do
		local row = env.info.match(script, "sword", probe)
		T.ok(row ~= nil and row.src == "user", script .. " takes it as its sword")
	end
	local recolor = env.info.match("Neptunian V", "sword", { mesh = "5551", tex = "7777" })
	T.ok(recolor ~= nil and recolor.src == "user", "the same sword with another texture is still that sword")
	T.eq(env.info.match("Neptunian V", "sword", { mesh = "9999", tex = "6661" }), nil, "a different mesh with the same texture is not")
	T.eq(env.info.match("The Hotline", "gun", { mesh = "5551" }), nil, "a sword stays out of the gun scripts")
	local again = svc:addIds(A.parseAdd("sword 5551"), worn)
	T.eq(#again.failed, 0, "adding it again is not an error")
	T.eq(#again.added, 1, "it is reported")
	T.eq(again.added[1].already, true, "as already added")
	T.eq(again.added[1].section .. "/" .. again.added[1].target, "shared/sword", "and says what it is")
	T.eq(#svc:userRows("shared", "sword"), 1, "still one row")
end

T.section("add_hats: which running script restarts after an add")
do
	T.eq(Ui.uses("Neptunian V", { section = "shared", target = "sword" }), true, "Neptunian V uses an added sword")
	T.eq(Ui.uses("Neptunian V", { section = "shared", target = "any" }), true, "and an added weapon")
	T.eq(Ui.uses("Neptunian V", { section = "shared", target = "gun" }), false, "but not a gun")
	T.eq(Ui.uses("The Hotline", { section = "shared", target = "gun" }), true, "The Hotline uses a gun")
	T.eq(Ui.uses("Master Chief", { section = "shared", target = "gun" }), true, "Master Chief takes a gun as its rifle")
	T.eq(Ui.uses("Book Reader", { section = "script", target = "Book Reader" }), true, "Book Reader uses add book")
	T.eq(Ui.uses("Book Reader", { section = "shared", target = "sword" }), false, "and not a sword")
	T.eq(Ui.uses("FakeVR", { section = "rig" }), true, "a rig hat needs any reanimation to start again")
	T.eq(Ui.uses(nil, { section = "rig" }), false)
	for _, item in ipairs(Ui.JOBS) do
		local script = item[1]
		local any = false
		for _, kind in ipairs(A.SHARED) do
			if Ui.uses(script, { section = "shared", target = kind }) then
				any = true
			end
		end
		local wantsWeapon = false
		for _, slot in ipairs(item[2]) do
			if A.SHARED_SLOTS.any[slot] then
				wantsWeapon = true
			end
		end
		T.eq(any, wantsWeapon, script .. " restarts only for the weapons it has")
	end
end

T.section("add_hats: the add command restarts the running script that uses the hat")
do
	local hub = readsource("Hub/AtsukoHub.lua")
	T.ok(string.find(hub, "function R.restart()", 1, true) ~= nil, "main scripts can restart the running script")
	T.ok(string.find(hub, "ui.uses(key, item)", 1, true) ~= nil, "add checks whether the running script uses what was added")
	T.ok(string.find(hub, "uses and R.restart()", 1, true) ~= nil, "and restarts it when it does")
	T.ok(string.find(hub, '"Already added"', 1, true) ~= nil, "adding the same hat again says it was already added")
end

T.section("add_hats: a hat goes on the running script only")
do
	local U = loadmodule("Hub/modules/alignment_ui.lua")
	local M = loadmodule("Hub/modules/alignment.lua")
	T.eq(U.scriptKey("Neptunian V"), "Neptunian V", "a script on the list is itself")
	T.eq(U.scriptKey("Dubstep Gun (Hub)"), "Dubstep Gun", "both dubstep guns share one hat list")
	T.eq(U.scriptKey("Dubstep Gun (Original)"), "Dubstep Gun")
	T.eq(U.scriptKey("FakeVR"), nil, "a script that holds no hats")
	T.eq(U.scriptKey(nil), nil)
	T.eq(M.slotIn({ "sword", "gun" }, "gun"), "gun")
	T.eq(M.slotIn({ "sword", "gun" }, nil), "gun", "no job picks the first weapon")
	T.eq(M.slotIn({ "sword" }, "gun"), nil, "a gun on a sword script doesn't fit")
	T.eq(M.slotIn({ "rifle", "shotgun", "bullet" }, "gun"), "rifle", "a gun is Master Chief's rifle")
	T.eq(M.slotIn({ "gun", "bullet" }, "rifle"), "gun", "a rifle is a gun script's gun")
	T.eq(M.slotIn({ "gun1", "gun2" }, "gun"), "gun1", "a gun is Snake Banisher's first gun")
	T.eq(M.slotIn({ "book" }, "any"), "book")
	T.eq(M.slotIn({ "head", "torso" }, nil), nil, "InternalWar's titan parts aren't weapons")
	T.eq(M.weaponCount({ "sword", "gun", "slash", "bullet" }), 2)
end
