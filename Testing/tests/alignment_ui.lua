local G = loadmodule("Testing/mocks/gui_mock.lua")
local A = loadmodule("Hub/modules/alignment.lua")
local Ui = loadmodule("Hub/modules/alignment_ui.lua")

T.section("alignment_ui: numbers")
T.eq(Ui.numberText(0), "0")
T.eq(Ui.numberText(1), "1")
T.eq(Ui.numberText(-0.00001), "0")
T.eq(Ui.numberText(0.5), "0.5")
T.eq(Ui.numberText(126.6693), "126.6693")
T.eq(Ui.numberText(-1.5), "-1.5")
T.eq(Ui.numberText(100), "100")
T.eq(Ui.numberText(10), "10")
T.eq(Ui.numberText(-2), "-2")
T.eq(Ui.numberText(1000000), "1000000")
T.eq(Ui.numberText(0.12345678), "0.1235")
T.eq(Ui.alignText({ 1, 2, 3 }), "1 2 3 0 0 0")
T.eq(Ui.alignText({ 0.017, 0, -0.23, -85, -9, 126 }), "0.017 0 -0.23 -85 -9 126")
T.eq(Ui.alignText({}), "0 0 0 0 0 0")
T.eq(Ui.alignText({ 1, 2, 3, 4, 5, 6, 7 }), "1 2 3 4 5 6")

T.section("alignment_ui: reading the alignment box")
T.same(Ui.parseAlign("1 2 3"), { 1, 2, 3 })
T.same(Ui.parseAlign("1, 2, 3, 4, 5, 6"), { 1, 2, 3, 4, 5, 6 })
T.same(Ui.parseAlign("  1;2;3  "), { 1, 2, 3 })
T.same(Ui.parseAlign("0.5 -1.25 1e2"), { 0.5, -1.25, 100 })
T.same(Ui.parseAlign("1,2,3,4"), { 1, 2, 3, 4 })
T.eq(Ui.parseAlign(""), nil)
T.eq(select(2, Ui.parseAlign("")), nil, "an empty box is not a mistake")
T.eq(Ui.parseAlign("   "), nil)
local none, why = Ui.parseAlign("1 2")
T.eq(none, nil)
T.eq(why, "give at least three numbers (x y z), or leave it empty")
none, why = Ui.parseAlign("1 2 abc")
T.eq(none, nil)
T.eq(why, '"abc" is not a number')
none, why = Ui.parseAlign("1 2 3 4 5 6 7")
T.eq(none, nil)
T.eq(why, "that is more than six numbers")
none, why = Ui.parseAlign("1 2 3 4 5 6")
T.ok(none ~= nil, "exactly six is fine")
none, why = Ui.parseAlign("1 2 nan")
T.eq(none, nil)
none, why = Ui.parseAlign("1 2 1e999")
T.eq(none, nil)
T.eq(why, '"1e999" is not a number')
none, why = Ui.parseAlign("1:2:3")
T.eq(none, nil)
T.eq(why, '"1:2:3" is not a number')
none, why = Ui.parseAlign("-1e999 2 3")
T.eq(none, nil)
T.eq(why, '"-1e999" is not a number')
none, why = Ui.parseAlign(string.rep("x", 60) .. " 1 2")
T.eq(why, '"' .. string.rep("x", 20) .. '" is not a number', "a long word is cut in the message")
T.eq(Ui.parseCount(""), 1)
T.eq(Ui.parseCount("  "), 1)
T.eq(Ui.parseCount("1"), 1)
T.eq(Ui.parseCount("3"), 3)
T.eq(Ui.parseCount("8"), 8)
T.eq(Ui.parseCount("2.9"), 2)
local bad
bad, why = Ui.parseCount("0")
T.eq(bad, nil)
T.eq(why, "how many has to be a number from 1 to 8")
bad = Ui.parseCount("9")
T.eq(bad, nil)
bad = Ui.parseCount("-1")
T.eq(bad, nil)
bad = Ui.parseCount("abc")
T.eq(bad, nil)
bad = Ui.parseCount("0.5")
T.eq(bad, nil, "a half is below one")
bad = Ui.parseCount("1e999")
T.eq(bad, nil)

T.section("alignment_ui: words that some executors read as numbers")
do
	local realTonumber = tonumber
	tonumber = function(value, base)
		if base == nil then
			if value == "nan" then
				return 0 / 0
			end
			if value == "inf" then
				return math.huge
			end
			if value == "-inf" then
				return -math.huge
			end
		end
		return realTonumber(value, base)
	end
	local gone, reason = Ui.parseAlign("1 2 nan")
	T.eq(gone, nil)
	T.eq(reason, '"nan" is not a number')
	gone, reason = Ui.parseAlign("inf 2 3")
	T.eq(gone, nil)
	T.eq(reason, '"inf" is not a number')
	gone, reason = Ui.parseAlign("1 -inf 3")
	T.eq(gone, nil)
	T.eq(reason, '"-inf" is not a number')
	gone, reason = Ui.parseCount("nan")
	T.eq(gone, nil)
	T.eq(reason, "how many has to be a number from 1 to 8")
	T.eq(Ui.parseCount("inf"), nil)
	T.same(Ui.parseAlign("1 2 3"), { 1, 2, 3 })
	T.eq(Ui.parseCount("4"), 4)
	tonumber = realTonumber
end

T.section("alignment_ui: a draft becomes a row")
local function draftWith(over)
	local d = Ui.newDraft()
	for k, v in pairs(over or {}) do
		d[k] = v
	end
	return d
end
T.same(Ui.newDraft(), { part = "Head", script = "", slot = "", hat = "", mesh = "", tex = "", acc = "", align = "", count = "1", note = "" })
T.eq(Ui.newDraft().editing, nil)
T.ok(Ui.newDraft() ~= Ui.newDraft(), "every draft is its own table")
local row, rowWhy = Ui.rowFromDraft(draftWith({ part = "Left Arm", mesh = "13831073174", tex = " rbxassetid://456 ", acc = "  Accessory (x)  ", align = "0.017 0 -0.23 -85 -9 126", count = "2", note = " a note " }), A)
T.eq(rowWhy, nil)
T.eq(row.part, "Left Arm")
T.eq(row.mesh, "13831073174")
T.eq(row.tex, "456")
T.eq(row.acc, "Accessory (x)")
T.same(row.align, { 0.017, 0, -0.23, -85, -9, 126 })
T.eq(row.count, 2)
T.eq(row.note, "a note")
T.eq(row.hat, nil)
row = Ui.rowFromDraft(draftWith({ hat = "https://www.roblox.com/catalog/4506945409/Corrupt-Demonic-Greatsword" }), A)
T.eq(row.hat, "4506945409", "a catalog link works")
T.eq(row.part, "Head")
T.eq(row.align, nil)
T.eq(row.count, nil, "one hat needs no count")
row = Ui.rowFromDraft(draftWith({ hat = " 4506945409 " }), A)
T.eq(row.hat, "4506945409")
row = Ui.rowFromDraft(draftWith({ acc = "Name only" }), A)
T.eq(row.acc, "Name only")
row = Ui.rowFromDraft(draftWith({ tex = "5" }), A)
T.eq(row.tex, "5", "a texture alone is enough to find a hat")
row = Ui.rowFromDraft(draftWith({ mesh = "7", count = "1" }), A)
T.eq(row.count, nil)
row = Ui.rowFromDraft({ part = "Torso", mesh = "5" }, A)
T.eq(row.mesh, "5", "boxes that are missing count as empty")
T.eq(row.part, "Torso")
T.eq(row.count, nil)
T.eq(row.note, nil)
row = Ui.rowFromDraft({ part = "Torso", mesh = "5", acc = "   ", note = "  " }, A)
T.eq(row.acc, nil)
row, rowWhy = Ui.rowFromDraft(draftWith({}), A)
T.eq(row, nil)
T.eq(rowWhy, "tell me which hat: a hat id, a mesh id, a texture id or the hat's name")
row, rowWhy = Ui.rowFromDraft(draftWith({ acc = "   " }), A)
T.eq(row, nil)
row, rowWhy = Ui.rowFromDraft(draftWith({ mesh = "abc" }), A)
T.eq(row, nil)
T.eq(rowWhy, "the mesh id doesn't look right, use the number or the link")
row, rowWhy = Ui.rowFromDraft(draftWith({ hat = "x" }), A)
T.eq(rowWhy, "the hat id doesn't look right, use the number or the link")
row, rowWhy = Ui.rowFromDraft(draftWith({ tex = "x", mesh = "1" }), A)
T.eq(rowWhy, "the texture id doesn't look right, use the number or the link")
row, rowWhy = Ui.rowFromDraft(draftWith({ mesh = "1", align = "1 2" }), A)
T.eq(row, nil)
T.eq(rowWhy, "give at least three numbers (x y z), or leave it empty")
row, rowWhy = Ui.rowFromDraft(draftWith({ mesh = "1", count = "99" }), A)
T.eq(row, nil)
T.eq(rowWhy, "how many has to be a number from 1 to 8")
row = Ui.rowFromDraft(draftWith({ mesh = "1", note = "   " }), A)
T.eq(row.note, nil)
for _, part in ipairs(Ui.PARTS) do
	T.eq(Ui.rowFromDraft(draftWith({ part = part[1], mesh = "1" }), A).part, part[1])
end
T.same(Ui.PARTS, { { "Head", "Head" }, { "Torso", "Torso" }, { "Left Arm", "L Arm" }, { "Right Arm", "R Arm" }, { "Left Leg", "L Leg" }, { "Right Leg", "R Leg" } })

T.section("alignment_ui: a hat with a job in one script")
T.same(Ui.jobsOf("Addict"), { "gun", "bullet" })
T.same(Ui.jobsOf("InternalWar"), { "head", "torso", "rarm", "larm", "rleg", "lleg" })
T.same(Ui.jobsOf("Nope"), {})
T.eq(Ui.jobName("gun1"), "Gun 1")
T.eq(Ui.jobName("rarm"), "Right arm")
T.eq(Ui.jobName("odd"), "Odd", "a job with no name of its own is still readable")
T.eq(Ui.jobName(nil), "")
T.eq(Ui.targetText(Ui.newDraft()), "Used by: every reanimation, as a body part")
T.eq(Ui.targetText(draftWith({ script = "Commander V2", slot = "bullet" })), "Used by: Commander V2  ·  Bullet")
T.eq(Ui.targetText(draftWith({ target = "gun" })), "Used by: every script with a gun")
T.eq(Ui.targetText(draftWith({ target = "sword", script = "Addict" })), "Used by: every script with a sword", "the target wins over a script left in the draft")
T.eq(Ui.targetText(draftWith({ target = "script" })), "Used by: pick a script")
T.eq(Ui.targetOf(Ui.newDraft()), "rig", "a new draft is for the rig")
T.eq(Ui.targetOf(draftWith({ script = "Addict" })), "script", "an old draft with a script is for that script")
T.eq(Ui.targetOf(draftWith({ target = "rig", script = "Addict" })), "rig")
T.eq(Ui.targetOf(draftWith({ target = "nope" })), "rig")
T.eq(Ui.targetOf(nil), "rig")
T.same(Ui.TARGETS, { { "rig", "Rig" }, { "weapon", "Weapon" }, { "script", "One script" } })
T.same(Ui.WEAPONS, { { "any", "Any" }, { "gun", "Gun" }, { "sword", "Sword" }, { "shotgun", "Shotgun" }, { "rifle", "Rifle" } })
T.eq(Ui.targetOf(draftWith({ target = "weapon" })), "gun", "a weapon with no kind is a gun")
T.eq(Ui.targetOf(draftWith({ target = "shotgun" })), "shotgun")
T.eq(Ui.targetOf(draftWith({ target = "rifle" })), "rifle")
T.eq(Ui.groupOf("rifle"), "weapon")
T.eq(Ui.groupOf("gun"), "weapon")
T.eq(Ui.groupOf("rig"), "rig")
T.eq(Ui.groupOf("script"), "script")
T.eq(Ui.targetText(draftWith({ target = "shotgun" })), "Used by: every script with a shotgun")
T.eq(Ui.targetText(draftWith({ target = "rifle" })), "Used by: every script with a rifle")
T.same(Ui.usersOf("shotgun"), { "Master Chief" }, "every script with a shotgun")
T.same(Ui.usersOf("rifle"), { "Master Chief" }, "every script with a rifle")
T.eq(Ui.whoText("rifle"), "Every script with a rifle uses it, the next time it starts: Master Chief. Wear the hat and the script picks it up.")
T.same(Ui.jobsOf("Master Chief"), { "rifle", "shotgun", "bullet" }, "Master Chief has a rifle, a shotgun and a bullet")
T.eq(Ui.jobName("rifle"), "Rifle")
T.eq(Ui.jobName("shotgun"), "Shotgun")
do
	local row = Ui.rowFromDraft(draftWith({ target = "shotgun", hat = "71041506045232", part = "Torso", count = "2" }), A)
	T.eq(row.slot, "shotgun", "a shotgun hat for every script")
	T.eq(row.part, nil, "has no body part")
	T.eq(row.count, nil, "and no count")
	T.eq(row.hat, "71041506045232")
	local back = Ui.draftFromRow({ slot = "rifle", hat = "117510548336968" }, 2, nil, "rifle")
	T.eq(back.target, "rifle")
	T.eq(back.script, "")
end
T.same(Ui.usersOf("gun"), { "AK-47", "Addict", "Banisher", "Commander V2", "Dubstep Gun", "Linked Sword", "Master Chief", "Neptunian V Gun", "Snake Banisher V3", "Studio Dummy V4", "The Hotline", "The Sniper" }, "every script with a gun, Master Chief's rifle and shotgun too")
T.same(Ui.usersOf("sword"), { "Last Star", "Linked Sword", "Neptunian V", "Neptunian V Gun" }, "every script with a sword")
T.same(Ui.usersOf("nope"), {})
T.same(Ui.SHARED, A.SHARED, "the form and the hat file know the same weapons")
for _, kind in ipairs({ "gun", "sword", "shotgun", "rifle" }) do
	for slot in pairs(Ui.SHARED_SLOTS[kind]) do
		T.ok(table.find(A.sharedKinds(slot), kind) ~= nil, "the form and the hat file agree that " .. kind .. " covers " .. slot)
	end
end
for _, item in ipairs(Ui.JOBS) do
	for _, slot in ipairs(item[2]) do
		local kind = A.sharedKind(slot)
		T.ok(kind == nil or Ui.SHARED_SLOTS[kind][slot], item[1] .. " " .. slot)
	end
end
T.eq(Ui.whoText("gun"), "Every script with a gun uses it, the next time it starts: AK-47, Addict, Banisher, Commander V2, Dubstep Gun, Linked Sword, Master Chief, Neptunian V Gun, Snake Banisher V3, Studio Dummy V4, The Hotline, The Sniper. Wear the hat and the script picks it up.")
T.eq(Ui.whoText("sword"), "Every script with a sword uses it, the next time it starts: Last Star, Linked Sword, Neptunian V, Neptunian V Gun. Wear the hat and the script picks it up.")
T.eq(Ui.whoText("rig"), "It goes on that body part on every reanimation (Script Reanimate and FDless), for every hat script, the next time you reanimate.")
T.ok(string.find(Ui.whoText("script"), "Only the script you pick", 1, true) == 1)
local gunRow, gunWhy = Ui.rowFromDraft(draftWith({ target = "gun", mesh = "55", part = "Torso", count = "3", align = "0 1 0" }), A)
T.eq(gunWhy, nil)
T.eq(gunRow.slot, "gun", "a gun hat for every script")
T.eq(gunRow.part, nil, "has no body part")
T.eq(gunRow.count, nil, "and no count")
T.same(gunRow.align, { 0, 1, 0 })
local swordRow = Ui.rowFromDraft(draftWith({ target = "sword", hat = "4506945409", script = "Addict", slot = "bullet" }), A)
T.eq(swordRow.slot, "sword", "a sword hat ignores a script left in the draft")
T.eq(swordRow.hat, "4506945409")
local noScript, noScriptWhy = Ui.rowFromDraft(draftWith({ target = "script", mesh = "1" }), A)
T.eq(noScript, nil)
T.eq(noScriptWhy, "pick the script it is for")
local backGun = Ui.draftFromRow({ slot = "gun", mesh = "55" }, 3, nil, "gun")
T.eq(backGun.target, "gun")
T.eq(backGun.script, "", "a gun hat for every script has no script")
T.eq(backGun.slot, "")
T.eq(backGun.editing, 3)
T.eq(Ui.draftFromRow({ part = "Head", mesh = "1" }, 1).target, "rig")
T.eq(Ui.draftFromRow({ slot = "bullet", mesh = "1" }, 1, "Addict").target, "script")
local names = {}
for _, item in ipairs(Ui.JOBS) do
	names[#names + 1] = item[1]
	T.ok(#item[2] > 0, item[1] .. " has at least one job")
	for _, slot in ipairs(item[2]) do
		T.ok(Ui.JOB_NAMES[slot] ~= nil, item[1] .. " job " .. slot .. " has a name")
	end
end
T.same(names, { "AK-47", "Addict", "Banisher", "Book Reader", "Commander V2", "Dubstep Gun", "InternalWar", "Last Star", "Linked Sword", "Master Chief", "Neptunian V", "Neptunian V Gun", "Snake Banisher V3", "Studio Dummy V4", "The Hotline", "The Sniper" })
local job, jobWhy = Ui.rowFromDraft(draftWith({ script = "Addict", slot = "gun", mesh = "123", count = "5", part = "Torso", align = "1 2 3" }), A)
T.eq(jobWhy, nil)
T.eq(job.slot, "gun")
T.eq(job.mesh, "123")
T.eq(job.part, nil, "a script hat has no body part")
T.eq(job.count, nil, "and no count")
T.same(job.align, { 1, 2, 3 })
local noJob, noJobWhy = Ui.rowFromDraft(draftWith({ script = "Addict", slot = "sword", mesh = "123" }), A)
T.eq(noJob, nil)
T.eq(noJobWhy, "pick what the hat does in Addict")
T.eq(Ui.rowFromDraft(draftWith({ script = "Addict", slot = "gun", count = "nope" }), A), nil, "it still needs a hat")
local bodyRow = Ui.rowFromDraft(draftWith({ part = "Torso", mesh = "9", count = "3" }), A)
T.eq(bodyRow.part, "Torso")
T.eq(bodyRow.count, 3)
T.eq(bodyRow.slot, nil)
local back = Ui.draftFromRow({ slot = "bullet", mesh = "4307568890" }, 2, "Addict")
T.eq(back.script, "Addict")
T.eq(back.slot, "bullet")
T.eq(back.editing, 2)
T.eq(back.mesh, "4307568890")
local backBody = Ui.draftFromRow({ part = "Head", mesh = "1" }, 1)
T.eq(backBody.script, "")
T.eq(backBody.slot, "")

T.section("alignment_ui: a row goes back into the boxes")
local back = Ui.draftFromRow({ part = "Right Leg", hat = "5", mesh = "6", tex = "7", acc = "N", align = { 1, 2, 3, 0, 90, 0 }, count = 3, note = "n" }, 4)
T.eq(back.part, "Right Leg")
T.eq(back.hat, "5")
T.eq(back.mesh, "6")
T.eq(back.tex, "7")
T.eq(back.acc, "N")
T.eq(back.align, "1 2 3 0 90 0")
T.eq(back.count, "3")
T.eq(back.note, "n")
T.eq(back.editing, 4)
local plain = Ui.draftFromRow({ part = "Head", mesh = "1" }, 1)
T.eq(plain.align, "")
T.eq(plain.count, "1")
T.eq(plain.hat, "")
T.eq(plain.tex, "")
T.eq(plain.acc, "")
T.eq(plain.note, "")
T.eq(plain.mesh, "1")
T.eq(Ui.draftFromRow({}, 1).part, "Head")
local roundtrip = Ui.rowFromDraft(Ui.draftFromRow({ part = "Right Leg", mesh = "6", tex = "7", acc = "N", align = { 1, 2, 3, 0, 90, 0 }, count = 3, note = "n" }, 1), A)
T.eq(roundtrip.part, "Right Leg")
T.same(roundtrip.align, { 1, 2, 3, 0, 90, 0 })
T.eq(roundtrip.count, 3)
T.eq(roundtrip.note, "n")

T.section("alignment_ui: texts")
T.eq(Ui.rowSummary({ mesh = "1", tex = "2" }), "mesh 1  ·  tex 2")
T.eq(Ui.rowSummary({ hat = "9" }), "hat 9")
T.eq(Ui.rowSummary({ hat = "9", mesh = "1" }), "mesh 1")
T.eq(Ui.rowSummary({ hat = "9", tex = "1" }), "tex 1")
T.eq(Ui.rowSummary({ acc = "Name", count = 3 }), "Name  ·  x3")
T.eq(Ui.rowSummary({ mesh = "1", count = 2 }), "mesh 1  ·  x2")
T.eq(Ui.rowSummary({ mesh = "1", count = 1 }), "mesh 1")
T.eq(Ui.rowSummary({}), "no ids")
T.eq(Ui.statusText(nil), "not loaded yet")
T.eq(Ui.statusText("x"), "not loaded yet")
T.eq(Ui.statusText({ rigRows = 67, userRows = 2, source = "net" }, "GitHub"), "67 shipped, 2 yours  ·  GitHub")
T.eq(Ui.statusText({ rigRows = 67, userRows = 0, source = "net" }, "your folder"), "67 shipped, 0 yours  ·  your folder")
T.eq(Ui.statusText({ rigRows = 67, userRows = 0, source = "net" }), "67 shipped, 0 yours  ·  GitHub")
T.eq(Ui.statusText({ rigRows = 67, userRows = 0, source = "cache" }), "67 shipped, 0 yours  ·  saved copy")
T.eq(Ui.statusText({ rigRows = 0, userRows = 1, source = "none" }), "0 shipped, 1 yours  ·  file not found")
T.eq(Ui.statusText({ rigRows = 1, userRows = 0, source = "net", waiting = 2, lookupFailed = 1 }), "1 shipped, 0 yours  ·  GitHub, 2 waiting for a lookup, 1 not found")
T.eq(Ui.statusText({ rigRows = 1, userRows = 0, source = "net", pending = 3 }), "1 shipped, 0 yours  ·  GitHub", "only the lookups still to do are shown")
T.eq(Ui.statusText({ rigRows = 1, userRows = 0, source = "net", waiting = 0, lookupFailed = 0 }), "1 shipped, 0 yours  ·  GitHub")
T.eq(Ui.statusText({ rigRows = 1, userRows = 0, source = "net", waiting = 1 }), "1 shipped, 0 yours  ·  GitHub, 1 waiting for a lookup")
T.eq(Ui.statusText({ rigRows = 1, userRows = 0, source = "net", lookupFailed = 1 }), "1 shipped, 0 yours  ·  GitHub, 1 not found")
T.eq(Ui.cap("hello"), "Hello")
T.eq(Ui.cap("Hello"), "Hello")
T.eq(Ui.cap("hello world"), "Hello world")
T.eq(Ui.cap(nil), "")
T.eq(Ui.rowsText({}, A), "")
T.eq(Ui.rowsText({ { part = "Head", mesh = "1", src = "user", align = { 0, 1, 0, 0, 0, 0 } }, { part = "Torso", acc = "X" } }, A), '\t\t{part = "Head", mesh = "1", align = {0, 1, 0, 0, 0, 0}},\n\t\t{part = "Torso", acc = "X"},')
local pasted = A.parse("return { rig = {\n" .. Ui.rowsText({ { part = "Head", mesh = "1", align = { 0, 1, 0, 0, 0, 0 } } }, A) .. "\n} }")
T.eq(pasted.rig[1].mesh, "1", "the copied rows can be pasted into the file")

local function trimText(text)
	return (string.gsub(string.gsub(text, "^%s+", ""), "%s+$", ""))
end

local function fakeCtl()
	local C = { made = {} }
	local function make(kind, parent, order, fields)
		local row = Instance.new("Frame")
		row.Name = kind
		row.LayoutOrder = order
		row.Parent = parent
		local rec = { kind = kind, row = row, order = order, parent = parent, renders = 0 }
		for k, v in pairs(fields) do
			rec[k] = v
		end
		rec.render = function()
			rec.renders += 1
		end
		C.made[#C.made + 1] = rec
		return rec
	end
	function C.choice(parent, order, title, options, get, set)
		return make("choice", parent, order, { title = title, options = options, get = get, set = set })
	end
	function C.input(parent, order, title, placeholder, get, set)
		local rec = make("input", parent, order, { title = title, placeholder = placeholder, get = get, set = set })
		rec.box = Instance.new("TextBox")
		rec.box.Text = get()
		rec.render = function()
			rec.renders += 1
			rec.box.Text = get()
		end
		return rec
	end
	function C.note(parent, order, text)
		local rec = make("note", parent, order, { text = text })
		return rec.row
	end
	function C.info(parent, order, label, value)
		local rec = make("info", parent, order, { label = label })
		local v = Instance.new("TextLabel")
		v.Text = tostring(value)
		v.Parent = rec.row
		rec.value = v
		return v, rec.row
	end
	function C.action(parent, order, text, icon, danger, fn)
		local rec = make("action", parent, order, { title = text, icon = icon, danger = danger, fn = fn })
		return rec.row, rec
	end
	function C.buttons(parent, order, list, height)
		local rec = make("buttons", parent, order, { height = height, items = {} })
		local out = {}
		for i, item in ipairs(list) do
			local entry = { icon = item[1], text = item[2], fn = item[3], color = item[4] }
			rec.items[i] = entry
			out[i] = {
				btn = {},
				set = function(icon, text)
					entry.icon, entry.text = icon, text
				end,
			}
		end
		return out, rec.row
	end
	function C.live(kind)
		local out = {}
		for _, rec in ipairs(C.made) do
			if rec.row.Parent ~= nil and (kind == nil or rec.kind == kind) then
				out[#out + 1] = rec
			end
		end
		return out
	end
	function C.find(kind, title)
		for _, rec in ipairs(C.live(kind)) do
			if rec.title == title or rec.label == title then
				return rec
			end
		end
		return nil
	end
	function C.under(parent, kind)
		local out = {}
		for _, rec in ipairs(C.live(kind)) do
			if rec.parent == parent then
				out[#out + 1] = rec
			end
		end
		return out
	end
	return C
end

local BUILTIN_TEXT = [=====[
return {
	version = 1,
	rig = {
		{part = "Head", mesh = "111", align = {0, 0, 0, 0, 180, 0}},
		{part = "Left Arm", mesh = "222", tex = "333", align = {1, 2, 3, 4, 5, 6}},
	},
}
]=====]

local function newWorld(over)
	over = over or {}
	local env = G.install({ animations = false })
	local ctx = env.ctx
	local C = fakeCtl()
	ctx.Ctl = C
	local w = { C = C, toasts = {}, seconds = {}, copies = {}, files = {}, hats = over.hats or {}, resolves = 0, ctx = ctx }
	ctx.notify = function(title, text, kind, seconds)
		local line = title .. "|" .. tostring(text) .. "|" .. tostring(kind)
		w.toasts[#w.toasts + 1] = line
		w.seconds[line] = seconds
	end
	ctx.copyText = function(text, what)
		w.copies[#w.copies + 1] = { text = text, what = what }
	end
	ctx.section = function(parent, text, order)
		local label = Instance.new("TextLabel")
		label.Text = text
		label.LayoutOrder = order
		label.Parent = parent
		return label
	end
	if over.origin ~= false then
		ctx.Origin = over.origin or { where = function()
			return over.where or "GitHub"
		end }
	else
		ctx.Origin = nil
	end
	if over.noPlayer then
		ctx.LP = nil
	else
		ctx.LP = { Character = over.character }
	end
	local api = {
		fetch = function()
			if over.offline then
				return false, "offline"
			end
			return true, over.text or BUILTIN_TEXT
		end,
		readUser = function()
			return w.files.user
		end,
		writeUser = function(text)
			if over.failWrite then
				return false
			end
			w.files.user = text
			return true
		end,
		writeBackup = function() end,
		cframe = function(...)
			return { ... }
		end,
		publish = function(list, info)
			w.published = list
			w.info = info
		end,
		resolveHat = function(id)
			w.resolves += 1
			return w.hats[id], over.hatWhy and over.hatWhy[id] or "no such hat"
		end,
	}
	w.svc = A.new(api)
	w.svc:load()
	if over.userRows then
		for i = 1, over.userRows do
			w.svc:add("rig", nil, { part = "Head", mesh = tostring(1000 + i) })
		end
	end
	ctx.Core = {
		loadModule = function(name)
			if name == "alignment" and not over.noModule then
				return A
			end
			return nil, "missing"
		end,
		alignment = function()
			if over.noService then
				return nil
			end
			return w.svc
		end,
	}
	Ui.init(ctx)
	w.parent = Instance.new("Frame")
	return w
end

local function toastsOf(w)
	return table.concat(w.toasts, "\n")
end

local function lasted(w, line, seconds)
	T.eq(w.seconds[line], seconds, line)
end

local function press(rec)
	rec.fn()
end

local FIELD = {
	hat = "Hat id or catalog link",
	mesh = "Mesh id",
	tex = "Texture id",
	acc = "Hat name on your character",
	align = "Alignment: x y z rx ry rz",
	count = "How many of this hat",
}

local function fill(w, values)
	for key, text in pairs(values) do
		if key == "part" then
			w.C.find("choice", "Body part").set(text)
		else
			local rec = w.C.find("input", FIELD[key])
			rec.box.Text = text
			rec.set(trimText(text))
			rec.box.Text = rec.get()
		end
	end
end

local function typeOnly(w, key, text)
	w.C.find("input", FIELD[key]).box.Text = text
end

local function addButton(w)
	return w.C.live("buttons")[1].items[1]
end

local function toolsRow(w)
	for _, rec in ipairs(w.C.live("buttons")) do
		if rec.items[1].text == "Copy rows" then
			return rec
		end
	end
	return nil
end

local function yoursRows(w)
	local out = {}
	for _, rec in ipairs(w.C.live("info")) do
		if rec.label ~= "Alignment file" then
			out[#out + 1] = rec
		end
	end
	return out
end

local function hasNote(w, text)
	for _, rec in ipairs(w.C.live("note")) do
		if rec.text == text then
			return true
		end
	end
	return false
end

local function rowButtons(w, position)
	for _, rec in ipairs(w.C.live("buttons")) do
		if rec.order == position * 2 and rec.items[1].text == "Edit" then
			return rec.items[1], rec.items[2]
		end
	end
	return nil
end

local function spawnLater()
	local held = { list = {}, real = task.spawn }
	task.spawn = function(f)
		held.list[#held.list + 1] = f
	end
	function held.restore()
		task.spawn = held.real
	end
	return held
end

T.section("alignment_ui: the screen is built")
do
	local w = newWorld()
	local block = Ui.build(w.parent, 30)
	local C = w.C
	T.ok(block.alive)
	T.eq(block.frame.Name, "Hats")
	T.eq(block.frame.LayoutOrder, 30)
	T.eq(block.frame.Parent, w.parent)
	T.eq(block.frame.AutomaticSize, "AutomaticSize.Y", "the block grows with what is in it")
	T.eq(block.frame.BackgroundTransparency, 1)
	T.ok(block.frame:FindFirstChildOfClass("UIListLayout") ~= nil, "and its parts stack in order")
	T.eq(C.find("info", "Alignment file").value.Text, "2 shipped, 0 yours  ·  GitHub")
	local part = C.find("choice", "Body part")
	T.eq(#part.options, 6)
	T.eq(part.options[3][1], "Left Arm")
	T.eq(part.options[3][2], "L Arm")
	T.eq(part.get(), "Head")
	for _, title in pairs(FIELD) do
		T.ok(C.find("input", title) ~= nil, title)
	end
	T.eq(C.find("input", FIELD.count).get(), "1")
	for _, key in ipairs({ "hat", "mesh", "tex", "acc", "align" }) do
		T.eq(C.find("input", FIELD[key]).get(), "", key)
		T.eq(C.find("input", FIELD[key]).box.Text, "", key)
	end
	T.eq(C.find("input", FIELD.count).box.Text, "1")
	local placeholders = {
		hat = "optional, like 4506945409",
		mesh = "optional, when you have it",
		tex = "optional",
		acc = "optional",
		align = "0 0 0 0 0 0",
		count = "1",
	}
	for key, want in pairs(placeholders) do
		T.eq(C.find("input", FIELD[key]).placeholder, want, key)
	end
	for _, layout in ipairs({ block.frame:FindFirstChildOfClass("UIListLayout"), block.frame:FindFirstChild("Worn"):FindFirstChildOfClass("UIListLayout"), block.frame:FindFirstChild("Yours"):FindFirstChildOfClass("UIListLayout") }) do
		T.eq(layout.Padding.Offset, 6, "rows are 6 apart")
	end
	local buttons = C.live("buttons")
	T.eq(buttons[1].items[1].text, "Add hat")
	T.eq(buttons[1].items[1].icon, "plus")
	T.eq(buttons[1].items[2].text, "Clear")
	T.eq(buttons[1].items[2].icon, "x")
	T.ok(C.find("action", "Read the hats I'm wearing") ~= nil)
	T.eq(C.find("action", "Read the hats I'm wearing").icon, "glasses")
	T.eq(C.find("action", "Read the hats I'm wearing").danger, false)
	T.eq(buttons[2].items[1].text, "Copy rows")
	T.eq(buttons[2].items[1].icon, "copy")
	T.eq(buttons[2].items[2].text, "Copy file")
	T.eq(buttons[2].items[2].icon, "file-code")
	T.eq(buttons[2].items[3].text, "Reload")
	T.eq(buttons[2].items[3].icon, "refresh-cw")
	T.ok(hasNote(w, "You haven't added any hats yet"), "an empty list says so")
	T.eq(#C.live("buttons"), 2)
	Ui.destroy()
	T.eq(block.alive, false)
end

T.section("alignment_ui: where everything sits")
do
	local w = newWorld()
	local block = Ui.build(w.parent, 30)
	local C = w.C
	local inFrame = {}
	for _, rec in ipairs(C.live()) do
		if rec.parent == block.frame then
			inFrame[#inFrame + 1] = rec
		end
	end
	table.sort(inFrame, function(a, b)
		return a.order < b.order
	end)
	local expected = {
		{ 2, "info", "Alignment file" },
		{ 3, "note", "Set your hats once" },
		{ 4, "choice", "Used for" },
		{ 5, "choice", "Weapon" },
		{ 6, "note", "It goes on that body part on every reanimation" },
		{ 7, "action", "Used by: every reanimation, as a body part" },
		{ 8, "action", "" },
		{ 10, "choice", "Body part" },
		{ 11, "input", FIELD.hat },
		{ 12, "input", FIELD.mesh },
		{ 13, "input", FIELD.tex },
		{ 14, "input", FIELD.acc },
		{ 15, "input", FIELD.align },
		{ 16, "note", "Studs for x y z, degrees for the three turns." },
		{ 17, "input", FIELD.count },
		{ 18, "buttons", "Add hat" },
		{ 21, "action", "Read the hats I'm wearing" },
		{ 40, "buttons", "Copy rows" },
		{ 41, "note", "Your hats are saved in AtsukoHub/alignment_user.lua" },
	}
	T.eq(#inFrame, #expected)
	for i, want in ipairs(expected) do
		local got = inFrame[i]
		T.eq(got.order, want[1], "order " .. i)
		T.eq(got.kind, want[2], "kind " .. i)
		local name = got.title or got.label or (got.items and got.items[1].text) or got.text
		T.ok(string.find(name, want[3], 1, true) == 1, "name " .. i .. ": " .. tostring(name))
	end
	T.eq(inFrame[2].text, "Set your hats once: the rig hats go on your body parts on every reanimation. A weapon hat is used by every script with that weapon: the gun hat by every script that has a gun (Master Chief's rifle and shotgun too), the sword hat by every script that has a sword, and the shotgun and rifle hats by the scripts that have those. Any is all of them at once: the gun in the gun scripts and the sword in the sword scripts. One script gives a hat a job in a single script only. Limb reanimates don't use hats for their body. New hats can only be added while you're reanimated.")
	T.same(inFrame[3].options, Ui.TARGETS, "three choices: rig, weapon, one script")
	T.eq(inFrame[3].get(), "rig", "the rig is picked first")
	T.same(inFrame[4].options, Ui.WEAPONS, "the weapon row has gun, sword, shotgun and rifle")
	T.eq(inFrame[4].row.Visible, false, "and only shows for a weapon")
	T.eq(inFrame[6].icon, "users")
	T.eq(inFrame[7].icon, "crosshair")
	T.eq(inFrame[6].row.Visible, false, "the script row only shows for one script")
	T.eq(inFrame[7].row.Visible, false, "and the job row too")
	T.eq(inFrame[14].text, "Studs for x y z, degrees for the three turns. Leave it empty to keep the reanimate's own default.")
	T.eq(inFrame[19].text, "Your hats are saved in AtsukoHub/alignment_user.lua and go first, before the shipped ones. When you line a hat up with Alignment, the spot is saved there too, for that hat only.")
	T.eq(inFrame[16].height, 38)
	T.eq(inFrame[18].height, 38)
	local picker = block.frame:FindFirstChild("Picker")
	T.ok(picker ~= nil, "the picker list sits under the two rows")
	T.eq(picker.LayoutOrder, 9)
	T.eq(#C.under(picker), 0, "and it is closed at first")
	local sections = {}
	for _, child in ipairs(block.frame:GetChildren()) do
		if child.ClassName == "TextLabel" then
			sections[child.LayoutOrder] = child.Text
		end
	end
	T.eq(sections[1], "Hats & alignment")
	T.eq(sections[20], "Hats you wear")
	T.eq(sections[30], "Your hats")
	local worn = block.frame:FindFirstChild("Worn")
	local yours = block.frame:FindFirstChild("Yours")
	T.eq(worn.LayoutOrder, 22)
	T.eq(yours.LayoutOrder, 32)
	for _, holder in ipairs({ worn, yours }) do
		T.eq(holder.AutomaticSize, "AutomaticSize.Y", holder.Name)
		T.eq(holder.BackgroundTransparency, 1, holder.Name)
		T.ok(holder:FindFirstChildOfClass("UIListLayout") ~= nil, holder.Name)
	end
	Ui.destroy()
end

T.section("alignment_ui: where the file comes from")
do
	local w = newWorld({ where = "your folder" })
	Ui.build(w.parent, 1)
	T.eq(w.C.find("info", "Alignment file").value.Text, "2 shipped, 0 yours  ·  your folder")
	Ui.destroy()
	w = newWorld({ where = "your folder" })
	Ui.build(w.parent, 1)
	fill(w, { mesh = "5" })
	press(addButton(w))
	T.eq(w.C.find("info", "Alignment file").value.Text, "2 shipped, 1 yours  ·  your folder", "the place stays named after a change")
	Ui.destroy()
	w = newWorld({ origin = false })
	Ui.build(w.parent, 1)
	T.eq(w.C.find("info", "Alignment file").value.Text, "2 shipped, 0 yours  ·  GitHub")
	Ui.destroy()
	w = newWorld({ origin = {} })
	Ui.build(w.parent, 1)
	T.eq(w.C.find("info", "Alignment file").value.Text, "2 shipped, 0 yours  ·  GitHub")
	Ui.destroy()
end

T.section("alignment_ui: when the hat part did not load")
do
	local w = newWorld({ noModule = true })
	local block = Ui.build(w.parent, 5)
	T.eq(#w.C.live("input"), 0)
	T.eq(#w.C.live("note"), 1)
	T.eq(w.C.live("note")[1].text, "The hat part didn't load, so this stays empty. Reload the hub and look again.")
	T.eq(w.C.live("note")[1].order, 2)
	T.eq(#w.C.live("buttons"), 0)
	Ui.destroy()
	w = newWorld({ noService = true })
	block = Ui.build(w.parent, 5)
	T.eq(#w.C.live("input"), 0)
	T.eq(#w.C.live("note"), 1)
	T.eq(#w.C.live("action"), 0)
	Ui.destroy()
	T.eq(block.alive, false)
end

T.section("alignment_ui: adding a hat")
do
	local w = newWorld()
	local block = Ui.build(w.parent, 1)
	local C = w.C
	fill(w, { part = "Left Leg", mesh = "13831073174", tex = "456", align = "0 -0.62 0 90 0 0", acc = "Wings" })
	local add = addButton(w)
	T.eq(add.text, "Add hat")
	press(add)
	T.eq(#w.svc:userRows("rig"), 1)
	local stored = w.svc:userRows("rig")[1]
	T.eq(stored.part, "Left Leg")
	T.eq(stored.mesh, "13831073174")
	T.eq(stored.tex, "456")
	T.eq(stored.acc, "Wings")
	T.same(stored.align, { 0, -0.62, 0, 90, 0, 0 })
	T.eq(w.toasts[1], "Hat added|Used the next time you reanimate|ok")
	lasted(w, "Hat added|Used the next time you reanimate|ok", 2.5)
	T.eq(#w.toasts, 1)
	T.ok(string.find(w.files.user, 'mesh = "13831073174"', 1, true) ~= nil, "the hat is saved to a file")
	T.eq(w.published[1].PartName, "Left Leg", "and published for the reanimates")
	T.eq(C.find("choice", "Body part").get(), "Head", "the boxes are cleared afterwards")
	T.eq(C.find("input", FIELD.mesh).get(), "")
	T.eq(C.find("input", FIELD.mesh).box.Text, "")
	T.eq(C.find("input", FIELD.tex).box.Text, "")
	T.eq(C.find("input", FIELD.align).box.Text, "")
	T.eq(C.find("input", FIELD.count).box.Text, "1")
	T.ok(C.find("choice", "Body part").renders > 0, "the part picker is drawn again too")
	T.eq(C.find("info", "Alignment file").value.Text, "2 shipped, 1 yours  ·  GitHub")
	local rows = yoursRows(w)
	T.eq(#rows, 1)
	T.eq(rows[1].label, "Left Leg")
	T.eq(rows[1].value.Text, "mesh 13831073174  ·  tex 456  ·  Wings")
	T.eq(rows[1].order, 1)
	local edit, remove = rowButtons(w, 1)
	T.eq(edit.icon, "pencil")
	T.eq(remove.icon, "trash-2")
	T.eq(remove.text, "Remove")
	T.eq(remove.color, w.ctx.T.red, "removing is red")
	T.eq(edit.color, nil)
	for _, rec in ipairs(C.live("buttons")) do
		if rec.items[1].text == "Edit" then
			T.eq(rec.height, 32)
		end
	end
	T.eq(block.busy, false)
	Ui.destroy()
end

T.section("alignment_ui: giving a hat a job in one script")
do
	local w = newWorld()
	local block = Ui.build(w.parent, 1)
	local C = w.C
	local picker = block.frame:FindFirstChild("Picker")
	local used = C.find("choice", "Used for")
	local target = C.find("action", "Used by: every reanimation, as a body part")
	local jobRec = nil
	for _, rec in ipairs(C.live("action")) do
		if rec.icon == "crosshair" and rec.parent == block.frame then
			jobRec = rec
		end
	end
	T.ok(used ~= nil and target ~= nil and jobRec ~= nil)
	used.set("script")
	T.eq(block.draft.script, "AK-47", "picking one script starts on the first script")
	T.eq(block.draft.slot, "gun")
	T.eq(target.row.Visible, true, "the script row shows")
	press(target)
	local choices = C.under(picker, "action")
	T.eq(#choices, #Ui.JOBS, "every script is offered")
	T.eq(choices[1].title, "AK-47")
	press(target)
	T.eq(#C.under(picker, "action"), 0, "tapping it again closes the list")
	press(target)
	local listed = C.under(picker, "action")
	local pick = listed[2]
	for _, item in ipairs(listed) do
		if item.title == "Commander V2" then
			pick = item
		end
	end
	T.eq(listed[4].title, "Book Reader", "Book Reader is in the list")
	press(pick)
	T.eq(block.draft.script, "Commander V2")
	T.eq(block.draft.slot, "gun", "the first job is picked right away")
	T.eq(C.find("choice", "Body part").row.Visible, false, "a script hat has no body part")
	T.eq(C.find("input", FIELD.count).row.Visible, false, "and no count")
	T.eq(jobRec.row.Visible, true)
	T.eq(jobRec.Text, "What it does: Gun")
	T.eq(target.Text, "Used by: Commander V2  ·  Gun")
	local jobs = C.under(picker, "action")
	T.eq(#jobs, 2, "the jobs open by themselves")
	T.ok(string.find(jobs[2].title, "Bullet", 1, true) == 1, jobs[2].title)
	press(jobs[2])
	T.eq(block.draft.slot, "bullet")
	T.eq(#C.under(picker, "action"), 0)
	fill(w, { mesh = "4307568890" })
	press(addButton(w))
	local mine = w.svc:userRows("scripts", "Commander V2")
	T.eq(#mine, 1)
	T.eq(mine[1].slot, "bullet")
	T.eq(mine[1].mesh, "4307568890")
	T.eq(mine[1].part, nil)
	T.eq(#w.svc:userRows("rig"), 0, "nothing became a body part")
	T.eq(w.toasts[1], "Hat added|Used the next time you start Commander V2|ok")
	T.ok(string.find(w.files.user, "Commander V2", 1, true) ~= nil, "it is saved under the script")
	T.eq(block.draft.script, "Commander V2", "the script stays picked for the next hat")
	T.eq(block.draft.slot, "bullet")
	T.eq(used.get(), "script")
	T.eq(C.find("input", FIELD.mesh).box.Text, "", "but the boxes are empty again")
	local rows = yoursRows(w)
	T.eq(#rows, 1)
	T.eq(rows[1].label, "Commander V2  ·  Bullet")
	local edit = rowButtons(w, 1)
	T.eq(C.live("buttons")[1].items[2].text, "Clear")
	press(C.live("buttons")[1].items[2])
	T.eq(used.get(), "rig", "Clear puts it back to the rig")
	T.eq(C.find("choice", "Body part").row.Visible, true)
	press(edit)
	T.eq(block.draft.script, "Commander V2", "editing a script hat picks its script again")
	T.eq(block.draft.slot, "bullet")
	T.eq(used.get(), "script")
	T.eq(block.draft.editing, 1)
	fill(w, { mesh = "999" })
	press(addButton(w))
	T.eq(w.svc:userRows("scripts", "Commander V2")[1].mesh, "999", "and saving changes that row")
	T.eq(#w.svc:userRows("scripts", "Commander V2"), 1)
	used.set("rig")
	T.eq(target.row.Visible, false, "the rig needs no script")
	fill(w, { part = "Head", mesh = "77" })
	press(addButton(w))
	T.eq(#w.svc:userRows("rig"), 1)
	rows = yoursRows(w)
	T.eq(#rows, 2, "body parts and script hats are listed together")
	T.eq(rows[1].label, "Head")
	T.eq(rows[2].label, "Commander V2  ·  Bullet")
	local _, removeScript = rowButtons(w, 2)
	press(removeScript)
	T.eq(#w.svc:userRows("scripts", "Commander V2"), 0, "remove takes the script hat out")
	T.eq(#w.svc:userRows("rig"), 1, "and leaves the body part")
	Ui.destroy()
end

T.section("alignment_ui: a gun hat and a sword hat for every script")
do
	local w = newWorld()
	local block = Ui.build(w.parent, 1)
	local C = w.C
	local used = C.find("choice", "Used for")
	used.set("gun")
	T.eq(block.draft.target, "gun")
	T.eq(C.find("choice", "Body part").row.Visible, false, "a gun hat has no body part")
	T.eq(C.find("input", FIELD.count).row.Visible, false, "and no count")
	local whoRec = nil
	for _, rec in ipairs(C.live("note")) do
		if rec.order == 6 and rec.parent == block.frame then
			whoRec = rec
		end
	end
	T.ok(whoRec ~= nil and whoRec.row.Text == Ui.whoText("gun"), "the note says which scripts use it")
	fill(w, { mesh = "8888", align = "0 0 -1 0 90 0" })
	press(addButton(w))
	local guns = w.svc:userRows("shared", "gun")
	T.eq(#guns, 1, "saved once, for every script with a gun")
	T.eq(guns[1].slot, "gun")
	T.eq(guns[1].mesh, "8888")
	T.same(guns[1].align, { 0, 0, -1, 0, 90, 0 })
	T.eq(#w.svc:userRows("rig"), 0)
	T.eq(w.toasts[1], "Hat added|Every script with a gun uses it the next time it starts|ok")
	T.ok(string.find(w.files.user, "shared = {", 1, true) ~= nil, "it is in the hat file under shared")
	T.eq(used.get(), "weapon", "weapon stays picked")
	T.eq(C.find("choice", "Weapon").get(), "gun", "and so does the gun")
	T.eq(C.find("choice", "Weapon").row.Visible, true, "the weapon row shows")
	for _, name in ipairs(Ui.usersOf("gun")) do
		local slot = name == "Snake Banisher V3" and "gun1" or "gun"
		local hit = w.info.match(name, slot, { mesh = "8888" })
		T.ok(hit ~= nil and hit.src == "user", name .. " finds the gun hat")
		local mineList = w.info.mine(name, slot)
		T.eq(#mineList, 1, name .. " counts it as yours")
	end
	T.eq(w.info.match("Snake Banisher V3", "gun2", { mesh = "8888" }), nil, "the second gun of Snake Banisher keeps its own hats")
	T.eq(w.info.match("Addict", "bullet", { mesh = "8888" }), nil, "a bullet is not a gun")
	T.eq(w.info.match("Neptunian V", "sword", { mesh = "8888" }), nil, "and a sword script doesn't take it")
	used.set("sword")
	fill(w, { hat = "", mesh = "7777" })
	press(addButton(w))
	T.eq(#w.svc:userRows("shared", "sword"), 1)
	for _, name in ipairs(Ui.usersOf("sword")) do
		local hit = w.info.match(name, "sword", { mesh = "7777" })
		T.ok(hit ~= nil and hit.src == "user", name .. " finds the sword hat")
	end
	T.eq(w.info.match("Addict", "gun", { mesh = "7777" }), nil, "a gun script doesn't take the sword")
	local rows = yoursRows(w)
	T.eq(#rows, 2)
	T.eq(rows[1].label, "Gun  ·  every script with a gun")
	T.eq(rows[2].label, "Sword  ·  every script with a sword")
	local editGun = rowButtons(w, 1)
	press(editGun)
	T.eq(used.get(), "weapon", "editing the gun hat picks weapon again")
	T.eq(C.find("choice", "Weapon").get(), "gun", "and the gun")
	T.eq(block.draft.editing, 1)
	fill(w, { mesh = "8889" })
	press(addButton(w))
	T.eq(w.svc:userRows("shared", "gun")[1].mesh, "8889", "and saving changes it")
	T.eq(#w.svc:userRows("shared", "gun"), 1)
	T.ok(w.info.match("The Hotline", "gun", { mesh = "8889" }) ~= nil, "every gun script sees the change")
	local _, removeSword = rowButtons(w, 2)
	press(removeSword)
	T.eq(#w.svc:userRows("shared", "sword"), 0, "remove takes the sword hat out")
	T.eq(#w.svc:userRows("shared", "gun"), 1, "and leaves the gun hat")
	T.eq(w.info.match("Neptunian V", "sword", { mesh = "7777" }), nil, "and the sword scripts stop using it")
	T.eq(C.find("info", "Alignment file").value.Text, "2 shipped, 1 yours  ·  GitHub", "the gun hat counts as yours")
	Ui.destroy()
end

T.section("alignment_ui: typed text that was not confirmed yet is still used")
do
	local w = newWorld()
	Ui.build(w.parent, 1)
	typeOnly(w, "mesh", " 55 ")
	typeOnly(w, "align", "1 2 3")
	typeOnly(w, "acc", "Cape")
	typeOnly(w, "count", "2")
	typeOnly(w, "hat", "")
	press(addButton(w))
	local stored = w.svc:userRows("rig")[1]
	T.eq(stored.mesh, "55")
	T.same(stored.align, { 1, 2, 3, 0, 0, 0 })
	T.eq(stored.acc, "Cape")
	T.eq(stored.count, 2)
	Ui.destroy()
	w = newWorld()
	Ui.build(w.parent, 1)
	typeOnly(w, "align", "7 8 9")
	typeOnly(w, "count", "3")
	w.ctx.LP.Character = nil
	local list = w.C.find("action", "Read the hats I'm wearing")
	press(list)
	T.ok(hasNote(w, "No hats found on your character right now"))
	Ui.destroy()
end

T.section("alignment_ui: clearing the boxes")
do
	local w = newWorld()
	Ui.build(w.parent, 1)
	local add = addButton(w)
	fill(w, { part = "Torso", mesh = "5", tex = "6", acc = "N", align = "1 2 3", count = "4", hat = "7" })
	local clear = w.C.live("buttons")[1].items[2]
	press(clear)
	T.eq(w.C.find("choice", "Body part").get(), "Head")
	for _, key in ipairs({ "hat", "mesh", "tex", "acc", "align" }) do
		T.eq(w.C.find("input", FIELD[key]).box.Text, "", key)
	end
	T.eq(w.C.find("input", FIELD.count).box.Text, "1")
	T.eq(#w.svc:userRows("rig"), 0)
	T.eq(#w.toasts, 0)
	fill(w, { mesh = "1" })
	press(add)
	press(rowButtons(w, 1))
	T.eq(add.text, "Save changes")
	press(clear)
	T.eq(add.text, "Add hat", "clearing also stops changing a hat")
	fill(w, { mesh = "2" })
	press(add)
	T.eq(#w.svc:userRows("rig"), 2, "and the next hat is added, not saved over the old one")
	Ui.destroy()
end

T.section("alignment_ui: mistakes are explained, nothing is added")
do
	local w = newWorld()
	Ui.build(w.parent, 1)
	local add = addButton(w)
	press(add)
	T.eq(#w.svc:userRows("rig"), 0)
	T.eq(w.toasts[1], "Hats|Tell me which hat: a hat id, a mesh id, a texture id or the hat's name|info")
	lasted(w, "Hats|Tell me which hat: a hat id, a mesh id, a texture id or the hat's name|info", 3.5)
	w.toasts = {}
	fill(w, { mesh = "1", align = "1 2" })
	press(add)
	T.eq(w.toasts[1], "Hats|Give at least three numbers (x y z), or leave it empty|info")
	T.eq(#w.svc:userRows("rig"), 0)
	T.eq(w.C.find("input", FIELD.mesh).get(), "1", "what you typed stays so you can fix it")
	T.eq(w.C.find("input", FIELD.mesh).box.Text, "1")
	w.toasts = {}
	fill(w, { align = "", count = "50" })
	press(add)
	T.eq(w.toasts[1], "Hats|How many has to be a number from 1 to 8|info")
	fill(w, { count = "1" })
	press(add)
	T.eq(#w.svc:userRows("rig"), 1)
	w.toasts = {}
	fill(w, { mesh = "1" })
	press(add)
	T.eq(#w.svc:userRows("rig"), 1, "the same hat twice is refused")
	T.eq(w.toasts[1], "Hats|That row is already there|info")
	lasted(w, "Hats|That row is already there|info", 3.5)
	T.eq(w.C.find("input", FIELD.mesh).get(), "1", "and it stays in the boxes")
	Ui.destroy()
end

T.section("alignment_ui: a hat from its catalog id")
do
	local w = newWorld({ hats = { ["777"] = { mesh = "rbxassetid://424242", tex = "rbxassetid://434343", name = "New Sword" } } })
	Ui.build(w.parent, 1)
	local add = addButton(w)
	fill(w, { part = "Right Arm", hat = "https://www.roblox.com/catalog/777/New-Sword", align = "1 2 3" })
	press(add)
	local stored = w.svc:userRows("rig")[1]
	T.eq(stored.hat, "777")
	T.eq(stored.mesh, "424242", "the hat is looked up right away")
	T.eq(stored.tex, "434343")
	T.eq(stored.name, "New Sword")
	T.eq(w.resolves, 1)
	T.eq(w.published[1].meshid, "424242")
	w.toasts = {}
	fill(w, { hat = "888" })
	press(add)
	T.eq(#w.svc:userRows("rig"), 1, "a hat that can not be found is not added")
	T.eq(w.toasts[1], "Couldn't look that hat up|No such hat|error")
	lasted(w, "Couldn't look that hat up|No such hat|error", 5)
	T.eq(w.C.find("input", FIELD.hat).get(), "888", "the boxes keep what you typed")
	press(add)
	T.eq(w.resolves, 3, "and the button works again afterwards")
	Ui.destroy()
end

T.section("alignment_ui: a hat with ids already typed is not looked up")
do
	local w = newWorld({ hats = { ["5"] = { mesh = "999", tex = "" } } })
	Ui.build(w.parent, 1)
	fill(w, { hat = "5", mesh = "321" })
	press(addButton(w))
	T.eq(w.resolves, 0)
	T.eq(w.svc:userRows("rig")[1].mesh, "321")
	T.eq(w.svc:userRows("rig")[1].hat, "5")
	fill(w, { hat = "6", tex = "654" })
	press(addButton(w))
	T.eq(w.resolves, 0)
	T.eq(w.svc:userRows("rig")[2].tex, "654")
	Ui.destroy()
end

T.section("alignment_ui: changing a hat")
do
	local w = newWorld()
	Ui.build(w.parent, 1)
	local C = w.C
	local add = addButton(w)
	fill(w, { mesh = "1", align = "0 1 0" })
	press(add)
	fill(w, { part = "Torso", mesh = "2", count = "3", acc = "Cape" })
	press(add)
	T.eq(#w.svc:userRows("rig"), 2)
	local edit = rowButtons(w, 2)
	T.ok(edit ~= nil, "each hat has an Edit button")
	local before = C.find("input", FIELD.mesh).renders
	w.toasts = {}
	press(edit)
	T.eq(C.find("input", FIELD.mesh).get(), "2", "the boxes are filled with the hat")
	T.eq(C.find("input", FIELD.mesh).box.Text, "2")
	T.eq(C.find("choice", "Body part").get(), "Torso")
	T.eq(C.find("input", FIELD.count).get(), "3")
	T.eq(C.find("input", FIELD.count).box.Text, "3")
	T.eq(C.find("input", FIELD.acc).box.Text, "Cape")
	T.eq(C.find("input", FIELD.mesh).renders, before + 1, "and drawn again")
	T.eq(add.text, "Save changes")
	T.eq(add.icon, "plus")
	T.eq(w.toasts[1], "Editing|mesh 2  ·  Cape  ·  x3|info")
	lasted(w, "Editing|mesh 2  ·  Cape  ·  x3|info", 2)
	w.toasts = {}
	fill(w, { mesh = "22" })
	press(add)
	T.eq(#w.svc:userRows("rig"), 2)
	T.eq(w.svc:userRows("rig")[2].mesh, "22")
	T.eq(w.svc:userRows("rig")[2].count, 3)
	T.eq(w.svc:userRows("rig")[2].acc, "Cape")
	T.eq(w.svc:userRows("rig")[1].mesh, "1")
	T.eq(w.toasts[1], "Hat saved|Used the next time you reanimate|ok")
	lasted(w, "Hat saved|Used the next time you reanimate|ok", 2.5)
	T.eq(add.text, "Add hat", "back to adding")
	T.eq(C.find("input", FIELD.mesh).get(), "")
	T.eq(#yoursRows(w), 2)
	Ui.destroy()
end

T.section("alignment_ui: changing a hat into one that already exists")
do
	local w = newWorld()
	Ui.build(w.parent, 1)
	local add = addButton(w)
	fill(w, { mesh = "1" })
	press(add)
	fill(w, { mesh = "2" })
	press(add)
	press(rowButtons(w, 2))
	fill(w, { mesh = "1" })
	w.toasts = {}
	press(add)
	T.eq(w.toasts[1], "Hats|That row is already there|info")
	T.eq(w.svc:userRows("rig")[2].mesh, "2")
	T.eq(add.text, "Save changes", "still changing it so you can fix the number")
	Ui.destroy()
end

T.section("alignment_ui: removing a hat")
do
	local w = newWorld()
	Ui.build(w.parent, 1)
	local C = w.C
	local add = addButton(w)
	for i = 1, 3 do
		fill(w, { mesh = tostring(i) })
		press(add)
	end
	T.eq(#yoursRows(w), 3)
	local _, removeSecond = rowButtons(w, 2)
	w.toasts = {}
	press(removeSecond)
	T.eq(#w.svc:userRows("rig"), 2)
	T.eq(w.svc:userRows("rig")[1].mesh, "1")
	T.eq(w.svc:userRows("rig")[2].mesh, "3")
	T.eq(#yoursRows(w), 2, "the list is drawn again")
	T.eq(w.toasts[1], "Hat removed||ok")
	lasted(w, "Hat removed||ok", 1.5)
	T.eq(C.find("info", "Alignment file").value.Text, "2 shipped, 2 yours  ·  GitHub")
	T.ok(yoursRows(w)[1].value.Text == "mesh 1" and yoursRows(w)[2].value.Text == "mesh 3")
	T.ok(w.parent:FindFirstChild("Hats"):FindFirstChild("Yours"):FindFirstChildOfClass("UIListLayout") ~= nil, "the list keeps its layout")
	local editFirst = rowButtons(w, 1)
	press(editFirst)
	T.eq(add.text, "Save changes")
	T.eq(C.find("input", FIELD.mesh).get(), "1")
	local _, removeFirst = rowButtons(w, 1)
	press(removeFirst)
	T.eq(add.text, "Add hat", "removing the hat you are changing clears the boxes")
	T.eq(C.find("input", FIELD.mesh).get(), "")
	T.eq(w.svc:userRows("rig")[1].mesh, "3")
	_, removeFirst = rowButtons(w, 1)
	press(removeFirst)
	T.eq(#w.svc:userRows("rig"), 0)
	T.ok(hasNote(w, "You haven't added any hats yet"))
	T.eq(w.C.under(w.parent:FindFirstChild("Hats"):FindFirstChild("Yours"), "note")[1].order, 1)
	T.eq(#yoursRows(w), 0)
	Ui.destroy()
end

T.section("alignment_ui: removing a hat around the one you are changing")
do
	local w = newWorld()
	Ui.build(w.parent, 1)
	local add = addButton(w)
	for i = 1, 3 do
		fill(w, { mesh = tostring(i) })
		press(add)
	end
	press(rowButtons(w, 3))
	local _, removeFirst = rowButtons(w, 1)
	press(removeFirst)
	fill(w, { mesh = "33" })
	press(add)
	T.eq(#w.svc:userRows("rig"), 2)
	T.eq(w.svc:userRows("rig")[2].mesh, "33", "the right hat was changed after a row above it went away")
	T.eq(w.svc:userRows("rig")[1].mesh, "2")
	Ui.destroy()
	w = newWorld()
	Ui.build(w.parent, 1)
	add = addButton(w)
	for i = 1, 3 do
		fill(w, { mesh = tostring(i) })
		press(add)
	end
	press(rowButtons(w, 1))
	local _, removeLast = rowButtons(w, 3)
	press(removeLast)
	T.eq(add.text, "Save changes", "taking away a row below keeps the change going")
	fill(w, { mesh = "11" })
	press(add)
	T.eq(w.svc:userRows("rig")[1].mesh, "11")
	T.eq(w.svc:userRows("rig")[2].mesh, "2")
	T.eq(#w.svc:userRows("rig"), 2)
	Ui.destroy()
end

T.section("alignment_ui: removing the hat just before the one you are changing")
do
	local w = newWorld()
	Ui.build(w.parent, 1)
	local add = addButton(w)
	for i = 1, 3 do
		fill(w, { mesh = tostring(i) })
		press(add)
	end
	press(rowButtons(w, 2))
	local _, removeBefore = rowButtons(w, 1)
	press(removeBefore)
	T.eq(add.text, "Save changes")
	fill(w, { mesh = "22" })
	press(add)
	T.eq(#w.svc:userRows("rig"), 2)
	T.eq(w.svc:userRows("rig")[1].mesh, "22", "the hat right after a removed one is still the one being changed")
	T.eq(w.svc:userRows("rig")[2].mesh, "3")
	Ui.destroy()
end

T.section("alignment_ui: changing a hat that is found by its catalog id")
do
	local w = newWorld({ hats = { ["777"] = { mesh = "424242", tex = "", name = "New Sword" } } })
	Ui.build(w.parent, 1)
	local add = addButton(w)
	fill(w, { hat = "777" })
	press(add)
	T.eq(w.svc:userRows("rig")[1].mesh, "424242")
	press(rowButtons(w, 1))
	T.eq(w.C.find("input", FIELD.hat).get(), "777")
	T.eq(w.C.find("input", FIELD.mesh).get(), "424242")
	fill(w, { mesh = "", part = "Torso" })
	press(add)
	local stored = w.svc:userRows("rig")[1]
	T.eq(stored.part, "Torso")
	T.eq(stored.mesh, "424242", "the hat is filled in again for the changed row")
	T.eq(stored.hat, "777")
	T.eq(w.resolves, 1, "from memory, not from the catalog")
	Ui.destroy()
end

T.section("alignment_ui: buttons of a row that is already gone")
do
	local w = newWorld()
	Ui.build(w.parent, 1)
	local add = addButton(w)
	for i = 1, 3 do
		fill(w, { mesh = tostring(i) })
		press(add)
	end
	local staleEdit, staleRemove = rowButtons(w, 3)
	w.svc:remove("rig", nil, 3)
	w.toasts = {}
	press(staleEdit)
	T.eq(#w.toasts, 0)
	T.eq(add.text, "Add hat")
	press(staleRemove)
	T.eq(w.toasts[1], "Hats|That row is gone|info")
	lasted(w, "Hats|That row is gone|info", 3)
	T.eq(#w.svc:userRows("rig"), 2)
	Ui.destroy()
end

T.section("alignment_ui: the hats you wear")
do
	local function inst(class, props, kids)
		local o = { ClassName = class, Name = props.Name or class, kids = kids or {} }
		for k, v in pairs(props) do
			o[k] = v
		end
		function o:IsA(c)
			if c == "Accoutrement" then
				return self.ClassName == "Accessory" or self.ClassName == "Hat"
			end
			return self.ClassName == c or (c == "BasePart" and (self.ClassName == "MeshPart" or self.ClassName == "Part"))
		end
		function o:GetChildren()
			return self.kids
		end
		function o:FindFirstChild(n)
			for _, kid in ipairs(self.kids) do
				if kid.Name == n then
					return kid
				end
			end
			return nil
		end
		function o:FindFirstChildOfClass(c)
			for _, kid in ipairs(self.kids) do
				if kid.ClassName == c then
					return kid
				end
			end
			return nil
		end
		return o
	end
	local function hat(name, mesh, tex)
		return inst("Accessory", { Name = name }, { inst("MeshPart", { Name = "Handle", MeshId = "rbxassetid://" .. mesh, TextureID = tex and ("rbxassetid://" .. tex) or "" }) })
	end
	local character = inst("Model", { Name = "Me" }, {
		hat("Sword", "11", "12"),
		inst("Accessory", { Name = "Bare" }),
	})
	local w = newWorld({ character = character })
	Ui.build(w.parent, 1)
	local C = w.C
	local read = C.find("action", "Read the hats I'm wearing")
	press(read)
	local worn = w.parent:FindFirstChild("Hats"):FindFirstChild("Worn")
	local actions = C.under(worn, "action")
	T.eq(#C.under(worn, "note"), 0)
	T.eq(#actions, 2)
	T.eq(actions[1].title, "Sword  ·  mesh 11")
	T.eq(actions[2].title, "Bare  ·  no mesh found")
	T.eq(actions[1].order, 1)
	T.eq(actions[2].order, 2)
	T.eq(actions[1].icon, "plus")
	T.eq(actions[1].danger, false)
	fill(w, { hat = "123", count = "2" })
	typeOnly(w, "align", "4 5 6")
	typeOnly(w, "tex", "99")
	w.toasts = {}
	press(actions[1])
	T.eq(w.toasts[1], "Filled in|Sword|ok")
	lasted(w, "Filled in|Sword|ok", 1.5)
	T.eq(C.find("input", FIELD.mesh).get(), "11")
	T.eq(C.find("input", FIELD.tex).get(), "12")
	T.eq(C.find("input", FIELD.acc).get(), "Sword")
	T.eq(C.find("input", FIELD.hat).get(), "", "a hat id typed before is dropped so the worn hat's ids are used")
	T.eq(C.find("input", FIELD.align).get(), "4 5 6", "what you typed before is kept")
	T.eq(C.find("input", FIELD.count).get(), "2")
	T.eq(C.find("input", FIELD.mesh).box.Text, "11")
	fill(w, { part = "Left Arm" })
	press(addButton(w))
	local stored = w.svc:userRows("rig")[1]
	T.eq(stored.part, "Left Arm")
	T.eq(stored.mesh, "11")
	T.eq(stored.tex, "12")
	T.eq(stored.acc, "Sword")
	T.eq(stored.hat, nil)
	T.same(stored.align, { 4, 5, 6, 0, 0, 0 })
	T.eq(stored.count, 2)
	press(read)
	T.eq(#C.under(worn, "action"), 2, "reading again replaces the list instead of adding to it")
	fill(w, { mesh = "5", tex = "6" })
	press(C.under(worn, "action")[2])
	T.eq(C.find("input", FIELD.mesh).get(), "", "a hat with no mesh clears the number")
	T.eq(C.find("input", FIELD.tex).get(), "")
	T.eq(C.find("input", FIELD.acc).get(), "Bare")
	Ui.destroy()

	w = newWorld({ character = nil })
	Ui.build(w.parent, 1)
	press(w.C.find("action", "Read the hats I'm wearing"))
	T.ok(hasNote(w, "No hats found on your character right now"), "no character, no hats, and it says so")
	T.eq(w.C.under(w.parent:FindFirstChild("Hats"):FindFirstChild("Worn"), "note")[1].order, 1)
	T.eq(#w.C.under(w.parent:FindFirstChild("Hats"):FindFirstChild("Worn"), "action"), 0)
	Ui.destroy()
	w = newWorld({ character = inst("Model", { Name = "One" }, { hat("Solo", "31") }) })
	Ui.build(w.parent, 1)
	press(w.C.find("action", "Read the hats I'm wearing"))
	worn = w.parent:FindFirstChild("Hats"):FindFirstChild("Worn")
	T.eq(#w.C.under(worn, "action"), 1, "one hat is listed, not called 'no hats'")
	T.eq(w.C.under(worn, "action")[1].title, "Solo  ·  mesh 31")
	T.eq(#w.C.under(worn, "note"), 0)
	Ui.destroy()
	w = newWorld({ noPlayer = true })
	Ui.build(w.parent, 1)
	press(w.C.find("action", "Read the hats I'm wearing"))
	T.ok(hasNote(w, "No hats found on your character right now"))
	Ui.destroy()
end

T.section("alignment_ui: a lot of worn hats")
do
	local function inst(name, mesh)
		local handle = { ClassName = "MeshPart", Name = "Handle", MeshId = "rbxassetid://" .. mesh, TextureID = "" }
		function handle:IsA(c)
			return c == "MeshPart"
		end
		local o = { ClassName = "Accessory", Name = name }
		function o:IsA(c)
			return c == "Accoutrement" or c == "Accessory"
		end
		function o:FindFirstChild(n)
			return n == "Handle" and handle or nil
		end
		return o
	end
	local kids = {}
	for i = 1, 14 do
		kids[i] = inst("Hat" .. i, tostring(100 + i))
	end
	local character = {
		GetChildren = function()
			return kids
		end,
	}
	local w = newWorld({ character = character })
	Ui.build(w.parent, 1)
	press(w.C.find("action", "Read the hats I'm wearing"))
	local worn = w.parent:FindFirstChild("Hats"):FindFirstChild("Worn")
	T.eq(#w.C.under(worn, "action"), 12)
	T.eq(w.C.under(worn, "action")[12].title, "Hat12  ·  mesh 112")
	T.ok(hasNote(w, "and 2 more hats"))
	T.eq(w.C.under(worn, "note")[1].order, 13)
	Ui.destroy()
	kids[14] = nil
	w = newWorld({ character = character })
	Ui.build(w.parent, 1)
	press(w.C.find("action", "Read the hats I'm wearing"))
	worn = w.parent:FindFirstChild("Hats"):FindFirstChild("Worn")
	T.eq(#w.C.under(worn, "action"), 12)
	T.ok(hasNote(w, "and 1 more hat"), "one over twelve is said in the singular")
	Ui.destroy()
	kids[13] = nil
	w = newWorld({ character = character })
	Ui.build(w.parent, 1)
	press(w.C.find("action", "Read the hats I'm wearing"))
	worn = w.parent:FindFirstChild("Hats"):FindFirstChild("Worn")
	T.eq(#w.C.under(worn, "action"), 12)
	T.eq(#w.C.under(worn, "note"), 0, "exactly twelve needs no extra line")
	Ui.destroy()
end

T.section("alignment_ui: copying")
do
	local w = newWorld()
	Ui.build(w.parent, 1)
	local C = w.C
	local tools = toolsRow(w)
	press(tools.items[1])
	T.eq(#w.copies, 0, "nothing to copy yet")
	T.eq(w.toasts[1], "Nothing to copy|Add a body part hat first, Copy file has the script ones|info")
	lasted(w, "Nothing to copy|Add a body part hat first, Copy file has the script ones|info", 3)
	fill(w, { part = "Torso", mesh = "5", align = "1 2 3" })
	press(addButton(w))
	press(tools.items[1])
	T.eq(#w.copies, 1)
	T.eq(w.copies[1].text, '\t\t{part = "Torso", mesh = "5", align = {1, 2, 3, 0, 0, 0}},')
	T.eq(w.copies[1].what, "your rows, paste them inside rig = { } in Alignment/alignment.lua")
	press(tools.items[2])
	T.eq(w.copies[2].text, w.svc:userText())
	T.eq(w.copies[2].what, "your whole hat file")
	T.ok(string.find(w.copies[2].text, "return {", 1, true) ~= nil)
	Ui.destroy()
end

T.section("alignment_ui: reloading")
do
	local w = newWorld({ text = 'return { rig = { {part = "Head", hat = "55"}, {part = "Torso", mesh = "9"} } }', hats = { ["55"] = { mesh = "5555", tex = "" } } })
	Ui.build(w.parent, 1)
	local C = w.C
	T.eq(C.find("info", "Alignment file").value.Text, "2 shipped, 0 yours  ·  GitHub, 1 waiting for a lookup")
	local tools = toolsRow(w)
	w.toasts = {}
	press(tools.items[3])
	T.eq(w.resolves, 1, "hats waiting for a lookup are looked up")
	T.eq(C.find("info", "Alignment file").value.Text, "2 shipped, 0 yours  ·  GitHub")
	T.eq(w.toasts[1], "Reloaded|2 hats ready, looked up 1|ok")
	lasted(w, "Reloaded|2 hats ready, looked up 1|ok", 2.5)
	w.toasts = {}
	press(tools.items[3])
	T.eq(w.resolves, 1, "a hat that is known is not looked up again")
	T.eq(w.toasts[1], "Reloaded|2 hats ready|ok", "the hat found before is remembered")
	Ui.destroy()
end

T.section("alignment_ui: reloading when the file is missing or a hat is not found")
do
	local w = newWorld({ offline = true })
	Ui.build(w.parent, 1)
	w.toasts = {}
	press(toolsRow(w).items[3])
	T.eq(w.toasts[1], "Hats|Couldn't get Alignment/alignment.lua|error")
	lasted(w, "Hats|Couldn't get Alignment/alignment.lua|error", 4)
	T.eq(w.C.find("info", "Alignment file").value.Text, "0 shipped, 0 yours  ·  file not found")
	Ui.destroy()
	w = newWorld({ text = 'return { rig = { {part = "Head", hat = "404"} } }' })
	Ui.build(w.parent, 1)
	w.toasts = {}
	press(toolsRow(w).items[3])
	T.eq(w.toasts[1], "Reloaded|Couldn't look up 1 hat: No such hat|info")
	lasted(w, "Reloaded|Couldn't look up 1 hat: No such hat|info", 5)
	T.eq(w.C.find("info", "Alignment file").value.Text, "1 shipped, 0 yours  ·  GitHub, 1 not found")
	Ui.destroy()
	w = newWorld({ text = 'return { rig = { {part = "Head", hat = "404"}, {part = "Torso", hat = "405"} } }', hatWhy = { ["404"] = "first reason", ["405"] = "second reason" } })
	Ui.build(w.parent, 1)
	w.toasts = {}
	press(toolsRow(w).items[3])
	T.eq(w.toasts[1], "Reloaded|Couldn't look up 2 hats: First reason|info")
	Ui.destroy()
	w = newWorld({ text = 'return { rig = { {part = "Head", mesh = "9"} } }' })
	Ui.build(w.parent, 1)
	w.toasts = {}
	press(toolsRow(w).items[3])
	T.eq(w.toasts[1], "Reloaded|1 hat ready|ok")
	Ui.destroy()
	w = newWorld({ text = "this is not a table" })
	Ui.build(w.parent, 1)
	w.toasts = {}
	press(toolsRow(w).items[3])
	T.eq(string.sub(w.toasts[1], 1, 33), "Hats|Alignment/alignment.lua: lin")
	T.ok(string.find(w.toasts[1], "|error", 1, true) ~= nil)
	Ui.destroy()
end

T.section("alignment_ui: when saving to a file does not work")
do
	local w = newWorld({ failWrite = true })
	Ui.build(w.parent, 1)
	fill(w, { mesh = "5" })
	press(addButton(w))
	T.eq(#w.svc:userRows("rig"), 1, "the hat still works until you leave")
	T.eq(w.toasts[1], "Hat added|Used the next time you reanimate|ok")
	T.eq(w.toasts[2], "Not saved to a file|Couldn't save your hats|info")
	lasted(w, "Not saved to a file|Couldn't save your hats|info", 5)
	w.toasts = {}
	local _, remove = rowButtons(w, 1)
	press(remove)
	T.eq(w.toasts[1], "Removed, but not saved|Couldn't save your hats|info")
	lasted(w, "Removed, but not saved|Couldn't save your hats|info", 4)
	T.eq(#w.svc:userRows("rig"), 0)
	Ui.destroy()
end

T.section("alignment_ui: a long list is cut short but nothing is lost")
do
	local w = newWorld({ userRows = 40 })
	Ui.build(w.parent, 1)
	T.eq(#yoursRows(w), 40, "forty are shown")
	local yours = w.parent:FindFirstChild("Hats"):FindFirstChild("Yours")
	T.eq(#w.C.under(yours, "note"), 0, "and no extra line for exactly forty")
	T.eq(#w.C.under(yours, "buttons"), 40)
	T.eq(yoursRows(w)[40].order, 79)
	Ui.destroy()
	w = newWorld({ userRows = 41 })
	Ui.build(w.parent, 1)
	yours = w.parent:FindFirstChild("Hats"):FindFirstChild("Yours")
	T.eq(#yoursRows(w), 40)
	T.ok(hasNote(w, "and 1 more, it still works"))
	T.eq(w.C.under(yours, "note")[1].order, 81)
	Ui.destroy()
	w = newWorld({ userRows = 45 })
	Ui.build(w.parent, 1)
	T.eq(#yoursRows(w), 40)
	T.ok(hasNote(w, "and 5 more, they all still work"))
	Ui.destroy()
	w = newWorld({ userRows = 12 })
	Ui.build(w.parent, 1)
	local saved = Ui.MAX_DRAWN
	Ui.MAX_DRAWN = 3
	press(toolsRow(w).items[3])
	T.eq(#yoursRows(w), 3, "only a few are drawn")
	T.ok(hasNote(w, "and 9 more, they all still work"))
	Ui.MAX_DRAWN = saved
	T.eq(Ui.MAX_DRAWN, 40)
	Ui.destroy()
end

T.section("alignment_ui: pressing twice does not do it twice")
do
	local w = newWorld()
	Ui.build(w.parent, 1)
	local add = addButton(w)
	fill(w, { mesh = "1" })
	local held = spawnLater()
	press(add)
	press(add)
	held.restore()
	T.eq(#held.list, 1, "the second press is ignored while the first is working")
	held.list[1]()
	T.eq(#w.svc:userRows("rig"), 1)
	fill(w, { mesh = "2" })
	held = spawnLater()
	press(add)
	held.restore()
	T.eq(#held.list, 1, "and it works again after")
	held.list[1]()
	T.eq(#w.svc:userRows("rig"), 2)

	local reload = toolsRow(w).items[3]
	held = spawnLater()
	press(reload)
	press(reload)
	held.restore()
	T.eq(#held.list, 1)
	held.list[1]()
	held = spawnLater()
	press(reload)
	held.restore()
	T.eq(#held.list, 1, "reload works again too")
	held.list[1]()

	held = spawnLater()
	press(reload)
	press(add)
	held.restore()
	T.eq(#held.list, 1, "adding waits while the file is loading")
	held.list[1]()
	held = spawnLater()
	fill(w, { mesh = "3" })
	press(add)
	press(reload)
	held.restore()
	T.eq(#held.list, 1, "and loading waits while a hat is being added")
	Ui.destroy()
end

T.section("alignment_ui: leaving while something is still running")
do
	local w = newWorld({ hats = { ["9"] = { mesh = "99", tex = "" } } })
	local block = Ui.build(w.parent, 1)
	fill(w, { hat = "9" })
	local held = spawnLater()
	press(addButton(w))
	held.restore()
	T.eq(#held.list, 1, "adding runs in its own thread")
	Ui.destroy()
	T.eq(block.alive, false)
	local before = #w.toasts
	local madeBefore = #w.C.made
	held.list[1]()
	T.eq(#w.svc:userRows("rig"), 1, "the hat is still added")
	T.eq(#w.toasts, before, "but nothing is said")
	T.eq(#w.C.made, madeBefore, "and nothing is drawn into a screen that is gone")

	w = newWorld()
	block = Ui.build(w.parent, 1)
	fill(w, { hat = "404" })
	held = spawnLater()
	press(addButton(w))
	held.restore()
	Ui.destroy()
	before = #w.toasts
	held.list[1]()
	T.eq(#w.svc:userRows("rig"), 0)
	T.eq(#w.toasts, before, "a late 'could not look it up' stays quiet too")

	w = newWorld()
	block = Ui.build(w.parent, 1)
	held = spawnLater()
	press(toolsRow(w).items[3])
	held.restore()
	Ui.destroy()
	before = #w.toasts
	madeBefore = #w.C.made
	held.list[1]()
	T.eq(#w.toasts, before, "and so does a late reload")
	T.eq(#w.C.made, madeBefore)
	T.ok(w.svc.loaded)
end

T.section("alignment_ui: more than one screen, and closing twice")
do
	local w = newWorld()
	local one = Ui.build(w.parent, 1)
	local two = Ui.build(w.parent, 2)
	T.ok(one.alive and two.alive)
	Ui.destroy()
	T.eq(one.alive, false)
	T.eq(two.alive, false)
	T.eq(one.frame.Parent, nil, "the screens are taken down")
	T.eq(two.frame.Parent, nil)
	Ui.destroy()
	T.eq(one.alive, false)
	w = newWorld()
	one = Ui.build(w.parent, 1)
	two = Ui.build(w.parent, 2)
	one.destroy = function()
		error("boom")
	end
	Ui.destroy()
	T.eq(two.alive, false, "one screen failing to close does not stop the others")
	T.eq(two.frame.Parent, nil)
end

T.section("alignment_ui: the screen survives a broken notification function")
do
	local w = newWorld()
	Ui.build(w.parent, 1)
	w.ctx.notify = function()
		error("boom")
	end
	fill(w, { mesh = "1" })
	press(addButton(w))
	T.eq(#w.svc:userRows("rig"), 1, "an error in the toast does not stop the hat from being added")
	T.eq(#yoursRows(w), 1)
	w.ctx.notify = nil
	fill(w, { mesh = "2" })
	press(addButton(w))
	T.eq(#w.svc:userRows("rig"), 2, "and no toast function is fine too")
	press(addButton(w))
	local _, remove = rowButtons(w, 1)
	press(remove)
	T.eq(#w.svc:userRows("rig"), 1)
	Ui.destroy()
end
