local A = loadmodule("Hub/modules/alignment.lua")

local function refuses(text, fragment)
	local value, why = A.parse(text)
	T.eq(value, nil, "refused: " .. string.sub(text, 1, 40))
	T.ok(type(why) == "string" and string.find(why, fragment, 1, true) ~= nil, "message for " .. string.sub(text, 1, 40) .. " :: " .. tostring(why))
end

T.section("alignment: parser reads plain tables")
local t = A.parse('return { a = 1, b = "x", c = { 1, 2, 3 }, d = true, e = false, f = -2.5, g = .5, h = 1e3, i = 5., j = -1.5e-2 }')
T.eq(t.a, 1)
T.eq(t.b, "x")
T.same(t.c, { 1, 2, 3 })
T.eq(t.d, true)
T.eq(t.e, false)
T.eq(t.f, -2.5)
T.eq(t.g, 0.5)
T.eq(t.h, 1000)
T.eq(t.i, 5)
T.near(t.j, -0.015)
T.same(A.parse("{ a = 1 }"), { a = 1 })
T.same(A.parse("return{a=1}"), { a = 1 })
T.same(A.parse("return { a = 1 };"), { a = 1 })
T.same(A.parse("return { 1; 2; 3 }"), { 1, 2, 3 })
T.same(A.parse("return { a = nil, 1, nil, 2 }"), { 1, 2 })
T.same(A.parse("return {}"), {})
local keyed = A.parse('return { ["a b"] = 1, [5] = "five", [ "c" ] = 3, plain = 4, 10, 20 }')
T.eq(keyed["a b"], 1)
T.eq(keyed[5], "five")
T.eq(keyed.c, 3)
T.eq(keyed.plain, 4)
T.eq(keyed[1], 10)
T.eq(keyed[2], 20)
local nested = A.parse("return { a = { b = { c = { d = 4 } } } }")
T.eq(nested.a.b.c.d, 4)

T.section("alignment: parser skips comments")
local commented = A.parse([=====[
-- top comment
return { -- after the brace
	a = 1, --[[ inline ]] b = 2,
	--[==[ long
	comment ]] still inside ]==]
	c = 3,
	d = 4 -- before the end
}
-- trailing
]=====])
T.same(commented, { a = 1, b = 2, c = 3, d = 4 })
T.same(A.parse("--[[ one ]] return { a = 1 } --[[ two ]]"), { a = 1 })

T.section("alignment: parser reads strings")
local strings = A.parse([=====[
return {
	a = "q\"uote",
	b = 'it\'s',
	c = "tab\there",
	d = "nl\nx",
	e = "back\\slash",
	f = "\65\066",
	g = "\x41\x7a",
	h = [[long
text]],
	i = [==[with ]] inside]==],
	j = "line\
cont",
	k = "",
	l = 'single "double" inside',
}
]=====])
T.eq(strings.a, 'q"uote')
T.eq(strings.b, "it's")
T.eq(strings.c, "tab\there")
T.eq(strings.d, "nl\nx")
T.eq(strings.e, "back\\slash")
T.eq(strings.f, "AB")
T.eq(strings.g, "Az")
T.eq(strings.h, "long\ntext")
T.eq(strings.i, "with ]] inside")
T.eq(strings.j, "line\ncont")
T.eq(strings.k, "")
T.eq(strings.l, 'single "double" inside')
T.eq(A.parse('return { a = "x\\ry" }').a, "x\ry")
T.eq(A.parse('return { a = "\\255" }').a, string.char(255))
T.eq(A.parse("return { a = [[\nabc]] }").a, "abc", "a line break right after [[ is not part of the text")
T.eq(A.parse("return { a = [[\r\nabc]] }").a, "abc")
T.eq(A.parse("return { a = [[\n\nabc]] }").a, "\nabc")

T.section("alignment: parser refuses what is not a plain table")
refuses("", "empty")
refuses("return 5", "has to be a table")
refuses("returns { }", "has to be a table")
refuses("return { a = ", "ends too early")
refuses("return { a = 1 ", "never ends")
refuses('return { a = "x }', "never ends")
refuses('return { a = "abc\ndef" }', "never ends")
refuses("return { a = [[abc }", "never ends")
refuses("return { a = 12abc }", "number is not valid")
refuses("return { a = 1.2.3 }", "number is not valid")
refuses("return { a = - }", "number is not valid")
refuses("return { a = foo }", "is not a value")
refuses("return { a = f(1) }", "is not a value")
refuses("return { a = 1 + 2 }", "expected a ,")
refuses("return { a = (1) }", "unexpected")
refuses("return { [x] = 1 }", "is not a value")
refuses("return { [{}] = 1 }", "key has to be")
refuses("return { [1 = 1 }", "missing its ]")
refuses("return { [1] 1 }", "missing its =")
refuses("return {} extra", "something after")
refuses("return {} {}", "something after")
refuses('return { a = "\\q" }', "escape that is not allowed")
refuses('return { a = "\\300" }', "too big")
refuses('return { a = "\\xZZ" }', "not valid")
refuses("--[[ never ends\nreturn {}", "never ends")
refuses("return { a = 1 == 1 }", "expected a ,")
refuses("return { a == 1 }", "is not a value")
refuses("return { a = 1e999 }", "number is not valid")
refuses('return { a = "\\256" }', "too big")
refuses("return { a = 1, , }", "unexpected")
refuses("return {\n\ta = 1,\n\tb = foo,\n}", "line 3:")
refuses("return {\n\ta = 1,\n\tb = 2\n\tc = 3,\n}", "line 4:")
refuses("\n\n\nreturn { a = ", "line 4:")

T.section("alignment: parser never runs code")
_G.__alignment_ran = false
refuses("return { os.execute('x') }", "is not a value")
refuses("return { (function() __alignment_ran = true end)() }", "unexpected")
refuses("return { a = loadstring('x')() }", "is not a value")
refuses("return setmetatable({}, {})", "has to be a table")
refuses("return { a = __alignment_ran }", "is not a value")
refuses("local x = 1 return { a = x }", "has to be a table")
refuses("return { function() end }", "is not a value")
refuses("return { a = math.huge }", "is not a value")
refuses("return { a = 1/0 }", "expected a ,")
T.eq(_G.__alignment_ran, false)
_G.__alignment_ran = nil

T.section("alignment: parser limits")
refuses(string.rep(" ", 300001) .. "return {}", "too big")
T.same(A.parse(string.rep(" ", 299000) .. "return {}"), {})
refuses("return {{{{{{{{{}}}}}}}}}", "nested too deep")
T.ok(A.parse("return {{{{{{{{}}}}}}}}") ~= nil, "eight levels are fine")
refuses("return {" .. string.rep("1,", 40001) .. "}", "too many values")
T.ok(A.parse("return {" .. string.rep("1,", 39000) .. "}") ~= nil, "a big list under the limit is fine")

T.section("alignment: ids")
T.eq(A.digits("123"), "123")
T.eq(A.digits("  123  "), "123")
T.eq(A.digits(123), "123")
T.eq(A.digits(0), "0")
T.eq(A.digits(13831073174), "13831073174")
T.eq(A.digits("12345678901234567890"), "12345678901234567890")
T.eq(A.digits("123456789012345678901"), nil, "more than 20 digits")
T.eq(A.digits(-5), nil)
T.eq(A.digits(1.5), nil)
T.eq(A.digits(0 / 0), nil)
T.eq(A.digits(1 / 0), nil)
T.eq(A.digits(2 ^ 53), nil)
T.eq(A.digits("12a"), nil)
T.eq(A.digits("1 2"), nil)
T.eq(A.digits(""), nil)
T.eq(A.digits({}), nil)
T.eq(A.digits(nil), nil)
T.eq(A.extractId("123"), "123")
T.eq(A.extractId(" 456 "), "456")
T.eq(A.extractId("rbxassetid://789"), "789")
T.eq(A.extractId("http://www.roblox.com/asset/?id=321"), "321")
T.eq(A.extractId("https://www.roblox.com/asset/?version=2&id=654"), "654")
T.eq(A.extractId("https://www.roblox.com/catalog/4506945409/Corrupt-Demonic-Greatsword"), "4506945409")
T.eq(A.extractId("https://www.roblox.com/library/1234/Name"), "1234")
T.eq(A.extractId("https://create.roblox.com/store/asset/987654/Some-Name"), "987654")
T.eq(A.extractId("hat"), nil)
T.eq(A.extractId(""), nil)
T.eq(A.extractId(nil), nil)
T.eq(A.extractId(99), "99")

T.section("alignment: a rig row")
local row = A.cleanRow({ part = "Left Arm", mesh = 13831073174, tex = " 456 ", acc = "  Accessory (autorig_LeftArm) ", align = { 1, 2, 3, 4, 5, 6 }, note = "a note", junk = "x", src = "user" }, "rig")
T.eq(row.part, "Left Arm")
T.eq(row.mesh, "13831073174")
T.eq(row.tex, "456")
T.eq(row.acc, "Accessory (autorig_LeftArm)")
T.same(row.align, { 1, 2, 3, 4, 5, 6 })
T.eq(row.note, "a note")
T.eq(row.junk, nil, "unknown fields are dropped")
T.eq(row.src, nil, "the source tag is not part of a row")
for _, limb in ipairs({ "Head", "Torso", "Left Arm", "Right Arm", "Left Leg", "Right Leg" }) do
	T.ok(A.cleanRow({ part = limb, mesh = "1" }, "rig") ~= nil, limb)
end
local bad, why = A.cleanRow({ part = "Tail", mesh = "1" }, "rig")
T.eq(bad, nil)
T.ok(string.find(why, "part has to be", 1, true) ~= nil)
T.eq((A.cleanRow({ part = "head", mesh = "1" }, "rig")), nil, "part is case sensitive")
T.eq((A.cleanRow({ mesh = "1" }, "rig")), nil)
bad, why = A.cleanRow({ part = "Head" }, "rig")
T.eq(bad, nil)
T.ok(string.find(why, "needs a hat id", 1, true) ~= nil)
T.eq((A.cleanRow({ part = "Head", align = { 0, 0, 0 } }, "rig")), nil, "an alignment alone does not name a hat")
T.eq((A.cleanRow({ part = "Head", name = "x", words = { "y" } }, "rig")), nil, "words alone do not name a rig hat")
T.eq(A.cleanRow({ part = "Head", hat = "55" }, "rig").hat, "55")
T.eq(A.cleanRow({ part = "Head", tex = "55" }, "rig").tex, "55")
T.eq(A.cleanRow({ part = "Head", acc = "Name" }, "rig").acc, "Name")
T.eq((A.cleanRow({ part = "Head", mesh = "abc" }, "rig")), nil, "a mesh id that is not a number is dropped, leaving nothing")
T.eq((A.cleanRow("text", "rig")), nil)
T.eq((A.cleanRow(nil, "rig")), nil)

T.section("alignment: a script row")
local srow = A.cleanRow({ slot = "gun", mesh = "10", tex = "11", align = { 1, 0, 0, 90, 0, 0 } }, "script")
T.eq(srow.slot, "gun")
T.eq(srow.mesh, "10")
T.eq((A.cleanRow({ mesh = "10" }, "script")), nil, "a slot is needed")
T.eq((A.cleanRow({ slot = "gun" }, "script")), nil, "a row has to say something about a hat")
T.eq(A.cleanRow({ slot = "gun", hat = "9" }, "script").hat, "9")
T.eq(A.cleanRow({ slot = "gun", name = "Gun" }, "script").name, "Gun")
T.same(A.cleanRow({ slot = "gun", words = { "Gun", "PISTOL" } }, "script").words, { "gun", "pistol" })
T.same(A.cleanRow({ slot = "gun", words = "Gun" }, "script").words, { "gun" })
T.eq(A.cleanRow({ slot = "sword", key = "corrupt" }, "script").key, "corrupt")
T.same(A.cleanRow({ slot = "base", key = "corrupt", align = { 0, 0, 90 } }, "script").align, { 0, 0, 90, 0, 0, 0 })
T.eq(A.cleanRow({ slot = "s", align = { 1, 2, 3 } }, "script").slot, "s")
T.eq(#A.cleanRow({ slot = string.rep("s", 60), hat = "1" }, "script").slot, 24)

T.section("alignment: row field limits")
T.eq(#A.cleanRow({ part = "Head", acc = string.rep("a", 200) }, "rig").acc, 80)
T.eq(#A.cleanRow({ part = "Head", mesh = "1", note = string.rep("n", 400) }, "rig").note, 120)
T.eq(A.cleanRow({ part = "Head", mesh = "1", note = "a\nb\tc" }, "rig").note, "a b c")
T.eq(A.cleanRow({ part = "Head", mesh = "1", note = "   " }, "rig").note, nil)
local manyWords = {}
for i = 1, 20 do
	manyWords[i] = "w" .. i
end
T.eq(#A.cleanRow({ slot = "gun", words = manyWords }, "script").words, 8)
T.eq(#A.cleanRow({ slot = "gun", words = { string.rep("x", 90) } }, "script").words[1], 24)
T.eq(A.cleanRow({ slot = "gun", words = { "", "  " } , hat = "1" }, "script").words, nil)
T.eq(A.cleanRow({ part = "Head", mesh = "1", count = 3 }, "rig").count, 3)
T.eq(A.cleanRow({ part = "Head", mesh = "1", count = 1 }, "rig").count, nil)
T.eq(A.cleanRow({ part = "Head", mesh = "1", count = 99 }, "rig").count, 8)
T.eq(A.cleanRow({ part = "Head", mesh = "1", count = 2.9 }, "rig").count, 2)
T.eq(A.cleanRow({ part = "Head", mesh = "1", count = "x" }, "rig").count, nil)

T.section("alignment: alignment numbers")
T.same(A.cleanRow({ part = "Head", mesh = "1", align = { 1, 2, 3 } }, "rig").align, { 1, 2, 3, 0, 0, 0 })
T.same(A.cleanRow({ part = "Head", mesh = "1", align = { 1, 2, 3, 4 } }, "rig").align, { 1, 2, 3, 4, 0, 0 })
T.same(A.cleanRow({ part = "Head", mesh = "1", align = { 1, 2, 3, 4, 5, 6, 7 } }, "rig").align, { 1, 2, 3, 4, 5, 6 }, "extra numbers are ignored")
T.eq(A.cleanRow({ part = "Head", mesh = "1", align = { 1, 2 } }, "rig").align, nil, "two numbers is not enough")
T.eq(A.cleanRow({ part = "Head", mesh = "1", align = {} }, "rig").align, nil)
T.eq(A.cleanRow({ part = "Head", mesh = "1", align = "1,2,3" }, "rig").align, nil)
T.eq(A.cleanRow({ part = "Head", mesh = "1", align = { 1, "2", 3 } }, "rig").align, nil, "text in a number slot refuses the whole alignment")
T.eq(A.cleanRow({ part = "Head", mesh = "1", align = { 1, 0 / 0, 3 } }, "rig").align, nil)
T.eq(A.cleanRow({ part = "Head", mesh = "1", align = { 1, 2, 1 / 0 } }, "rig").align, nil)
T.same(A.cleanRow({ part = "Head", mesh = "1", align = { 9999, -9999, 9999, 99999, -99999, 99999 } }, "rig").align, { 500, -500, 500, 1440, -1440, 1440 }, "far out numbers are clamped")
T.same(A.cleanRow({ part = "Head", mesh = "1", align = { 500, -500, 500, 1440, -1440, 1440 } }, "rig").align, { 500, -500, 500, 1440, -1440, 1440 }, "numbers on the limit are kept")
T.same(A.cleanRow({ part = "Head", mesh = "1", align = { 0.5, -0.25, 1, -85, 90, 126.6693 } }, "rig").align, { 0.5, -0.25, 1, -85, 90, 126.6693 })

T.section("alignment: clean a whole file")
local data, problems = A.clean({
	version = 7,
	help = { "one", "two", "  ", 5, string.rep("h", 400) },
	slots = { ["Script A"] = { gun = "the gun", [5] = "no", bad = 3 }, ["Script B"] = "nope", [3] = {} },
	rig = { { part = "Head", mesh = "1" }, { part = "Tail", mesh = "2" }, "text", { part = "Torso" } },
	scripts = { ["Script A"] = { { slot = "gun", mesh = "3" }, { mesh = "4" } }, ["Script C"] = "nope" },
})
T.eq(data.version, 1, "the version is the reader's own")
T.eq(#data.help, 3)
T.eq(#data.help[3], 300)
T.same(data.slots, { ["Script A"] = { gun = "the gun" } })
T.eq(#data.rig, 1)
T.eq(#data.scripts["Script A"], 1)
T.eq(data.scripts["Script C"], nil)
T.eq(#problems, 5)
T.ok(string.find(problems[1], "rig row 2", 1, true) ~= nil)
T.ok(string.find(problems[2], "rig row 3", 1, true) ~= nil)
T.ok(string.find(problems[3], "rig row 4", 1, true) ~= nil)
local longHelp = {}
for i = 1, 20 do
	longHelp[i] = "line " .. i
end
local capHelp = A.clean({ help = longHelp })
T.eq(#capHelp.help, 12, "only twelve help lines are kept")
T.eq(capHelp.help[12], "line 12")
local capSlots = A.clean({ slots = { [string.rep("n", 60)] = { [string.rep("s", 40)] = string.rep("d", 300) } } })
local capName = next(capSlots.slots)
T.eq(#capName, 40)
local capSlot, capText = next(capSlots.slots[capName])
T.eq(#capSlot, 24)
T.eq(#capText, 200)
local empty, emptyProblems = A.clean("text")
T.eq(#empty.rig, 0)
T.eq(#emptyProblems, 1)
local none, noneProblems = A.clean({})
T.eq(#none.rig, 0)
T.eq(#noneProblems, 0)
local flood = {}
for i = 1, 50 do
	flood[i] = { part = "Nope" }
end
local _, floodProblems = A.clean({ rig = flood })
T.eq(#floodProblems, 20, "the list of problems is capped")

T.section("alignment: the number of rows is capped")
local big = {}
for i = 1, 650 do
	big[i] = { part = "Head", mesh = tostring(i) }
end
local capped, cappedProblems = A.clean({ rig = big })
T.eq(#capped.rig, 600)
T.ok(#cappedProblems >= 1)
local bigScript = {}
for i = 1, 350 do
	bigScript[i] = { slot = "gun", mesh = tostring(i) }
end
local cappedScripts = A.clean({ scripts = { Big = bigScript } })
T.eq(#cappedScripts.scripts.Big, 300)
local manyScripts = {}
for i = 1, 60 do
	manyScripts["Script " .. i] = { { slot = "gun", mesh = "1" } }
end
local scriptCount = 0
for _ in pairs(A.clean({ scripts = manyScripts }).scripts) do
	scriptCount += 1
end
T.eq(scriptCount, 40)

T.section("alignment: user rows go first and are tagged")
local builtin = A.clean({
	help = { "help" },
	slots = { ["S"] = { gun = "the gun" } },
	rig = { { part = "Head", mesh = "1" }, { part = "Torso", mesh = "2" } },
	scripts = { S = { { slot = "gun", mesh = "3" } }, Only = { { slot = "x", hat = "4" } } },
})
local user = A.clean({
	slots = { ["S"] = { bullet = "the bullet" }, New = { x = "x" } },
	rig = { { part = "Left Arm", mesh = "9" } },
	scripts = { S = { { slot = "gun", mesh = "8" } }, Mine = { { slot = "y", hat = "7" } } },
})
local merged = A.merge(builtin, user)
T.eq(#merged.rig, 3)
T.eq(merged.rig[1].mesh, "9")
T.eq(merged.rig[1].src, "user")
T.eq(merged.rig[2].src, "built-in")
T.eq(merged.rig[3].src, "built-in")
T.eq(#merged.scripts.S, 2)
T.eq(merged.scripts.S[1].mesh, "8")
T.eq(merged.scripts.S[1].src, "user")
T.eq(merged.scripts.S[2].src, "built-in")
T.eq(#merged.scripts.Only, 1)
T.eq(#merged.scripts.Mine, 1)
T.same(merged.slots.S, { gun = "the gun", bullet = "the bullet" })
local over = A.merge(builtin, A.clean({ slots = { S = { gun = "my gun" } } }))
T.eq(over.slots.S.gun, "my gun", "your own words for a slot win")
T.same(merged.slots.New, { x = "x" })
T.same(merged.help, { "help" })
T.eq(builtin.rig[1].src, nil, "merging does not touch the inputs")
T.eq(#A.merge(nil, nil).rig, 0)
T.eq(#A.merge(builtin, nil).rig, 2)
T.eq(#A.merge(nil, user).rig, 1)

T.section("alignment: matching a worn hat")
local rowMesh = { mesh = "222" }
local rowBoth = { mesh = "222", tex = "333" }
local rowAcc = { acc = "Accessory (autorig_Head)" }
T.eq(A.matches(rowMesh, { mesh = "222", tex = "999", acc = "x" }), true)
T.eq(A.matches(rowMesh, { mesh = "1222" }), true, "the id is found inside the mesh text, like the reanimates do")
T.eq(A.matches(rowMesh, { mesh = "223" }), false)
T.eq(A.matches(rowMesh, { tex = "222" }), false)
T.eq(A.matches(rowMesh, {}), false)
T.eq(A.matches(rowBoth, { mesh = "222", tex = "333" }), true)
T.eq(A.matches(rowBoth, { mesh = "222" }), false)
T.eq(A.matches(rowBoth, { mesh = "222", tex = "334" }), false)
T.eq(A.matches(rowAcc, { acc = "Accessory (autorig_Head)" }), true)
T.eq(A.matches(rowAcc, { acc = "Other" }), false)
T.eq(A.matches(rowAcc, { mesh = "1" }), false)
T.eq(A.matches({ mesh = "222", acc = "A" }, { mesh = "222", acc = "A" }), true)
T.eq(A.matches({ mesh = "222", acc = "A" }, { mesh = "222", acc = "B" }), false)
T.eq(A.matches({ hat = "5" }, { mesh = "5" }), false, "a catalog id alone cannot be compared with a worn hat")
T.eq(A.matches({}, { mesh = "1" }), false)
T.eq(A.matches(nil, {}), false)
T.eq(A.matches(rowMesh, nil), false)

T.section("alignment: rows turned into reanimate entries")
local calls = {}
local function fake(...)
	calls[#calls + 1] = { ... }
	return { cf = { ... } }
end
local rigData = A.clean({
	rig = {
		{ part = "Head", mesh = "111", align = { 0, 0, 0, 0, 180, 0 } },
		{ part = "Left Arm", mesh = "222", tex = "333", align = { 1, 2, 3, 4, 5, 6 }, count = 2 },
		{ part = "Torso", acc = "Accessory (autorig_Torso)" },
		{ part = "Right Leg", hat = "4444" },
		{ part = "Right Arm", hat = "5555", mesh = "666" },
	},
})
local list, pending = A.entries(rigData, fake, {})
T.eq(#list, 4)
T.eq(pending, 1, "a hat id that is not looked up yet waits")
T.eq(list[1].PartName, "Head")
T.eq(list[1].meshid, "111")
T.eq(list[1].textureid, nil)
T.eq(list[1].AccessoryName, nil)
T.same(list[1].C0.cf, { 0, 0, 0, 0, 180, 0 })
T.eq(list[2].PartName, "Left Arm")
T.eq(list[2].textureid, "333")
T.eq(list[2].count, 2)
T.same(list[2].C0.cf, { 1, 2, 3, 4, 5, 6 })
T.eq(list[3].AccessoryName, "Accessory (autorig_Torso)")
T.eq(list[3].C0, nil, "no alignment means the reanimate keeps its own default")
T.eq(list[3].count, nil)
T.eq(list[4].meshid, "666", "a row with a mesh id does not wait for the hat id")
list, pending = A.entries(rigData, fake, { ["4444"] = { mesh = "777", tex = "888" } })
T.eq(#list, 5)
T.eq(pending, 0)
T.eq(list[4].PartName, "Right Leg")
T.eq(list[4].meshid, "777")
T.eq(list[4].textureid, "888")
list, pending = A.entries(rigData, nil, {})
T.eq(#list, 4)
T.eq(list[1].C0, nil, "without a way to make a CFrame the entries still come out")
local huge = { rig = {}, scripts = {}, slots = {}, help = {} }
for i = 1, 750 do
	huge.rig[i] = { part = "Head", mesh = tostring(i) }
end
T.eq(#(A.entries(huge, fake, {})), 700)

T.section("alignment: your row replaces the shipped row for the same hat and limb")
local shadowBuiltin = A.clean({
	rig = {
		{ part = "Head", mesh = "10", tex = "11", align = { 0, 0, 0, 0, 0, 0 } },
		{ part = "Torso", mesh = "10", tex = "11", align = { 1, 0, 0, 0, 0, 0 } },
		{ part = "Left Arm", acc = "Acc A" },
		{ part = "Right Arm", hat = "55" },
		{ part = "Left Leg", mesh = "10", tex = "12" },
	},
})
local shadowUser = A.clean({
	rig = {
		{ part = "Head", mesh = "10", tex = "11", align = { 0, 5, 0, 0, 0, 0 } },
		{ part = "Head", mesh = "10", tex = "11", align = { 0, 6, 0, 0, 0, 0 } },
		{ part = "Left Arm", acc = "Acc A", align = { 7, 0, 0, 0, 0, 0 } },
		{ part = "Right Arm", hat = "55", align = { 8, 0, 0, 0, 0, 0 } },
		{ part = "Left Leg", mesh = "10" },
	},
})
local shadowData = A.merge(shadowBuiltin, shadowUser)
calls = {}
local shadowList, shadowPending = A.entries(shadowData, fake, { ["55"] = { mesh = "77", tex = "78" } })
local shadowParts = {}
for index, entry in ipairs(shadowList) do
	shadowParts[index] = entry.PartName .. ":" .. tostring(entry.meshid)
end
T.same(shadowParts, { "Head:10", "Head:10", "Left Arm:nil", "Right Arm:77", "Left Leg:10", "Torso:10", "Left Leg:10" }, "your row for the same hat and limb takes the place of the shipped one")
T.eq(shadowPending, 0)
T.same(shadowList[1].C0.cf, { 0, 5, 0, 0, 0, 0 })
T.same(shadowList[2].C0.cf, { 0, 6, 0, 0, 0, 0 }, "two of your own rows for one hat both stay")
T.same(shadowList[3].C0.cf, { 7, 0, 0, 0, 0, 0 })
T.same(shadowList[4].C0.cf, { 8, 0, 0, 0, 0, 0 })
T.eq(shadowList[4].textureid, "78")
T.eq(shadowList[5].textureid, nil)
T.eq(shadowList[7].textureid, "12", "another texture is another hat, so the shipped row stays")
T.eq(shadowList[6].PartName, "Torso", "a shipped row for another limb stays")
shadowList, shadowPending = A.entries(shadowData, fake, {})
T.eq(#shadowList, 6, "a hat id that is not looked up yet cannot replace anything")
T.eq(shadowPending, 2)
local plainTwice = A.entries(A.clean({ rig = { { part = "Head", mesh = "10" }, { part = "Head", mesh = "10", align = { 1, 1, 1, 0, 0, 0 } } } }), fake, {})
T.eq(#plainTwice, 2, "rows with no source tag are never replaced")
local builtinTwice = A.entries(A.merge(A.clean({ rig = { { part = "Head", mesh = "10" }, { part = "Head", mesh = "10", align = { 1, 1, 1, 0, 0, 0 } } } }), nil), fake, {})
T.eq(#builtinTwice, 2, "two shipped rows for one hat both stay")

T.section("alignment: rows of a script")
local scriptData = A.clean({ scripts = { S = { { slot = "gun", mesh = "1" }, { slot = "bullet", mesh = "2" }, { slot = "gun", mesh = "3" } } } })
T.eq(#A.rows(scriptData, "S"), 3)
T.eq(#A.rows(scriptData, "S", "gun"), 2)
T.eq(#A.rows(scriptData, "S", "bullet"), 1)
T.eq(#A.rows(scriptData, "S", "none"), 0)
T.eq(#A.rows(scriptData, "Other"), 0)
T.eq(#A.rows(nil, "S"), 0)

T.section("alignment: writing rows as text")
T.eq(
	A.rowText({ part = "Left Arm", mesh = "13831073174", align = { 0.017, 0, -0.23, -85, -9, 126 }, note = "patchma gear arms" }),
	'{part = "Left Arm", mesh = "13831073174", align = {0.017, 0, -0.23, -85, -9, 126}, note = "patchma gear arms"}',
	"the same shape as the shipped file"
)
T.eq(
	A.rowText({ slot = "gun", mesh = "1", tex = "2", align = { 1, 0, -0.1, 90, 0, 126.6693 } }),
	'{slot = "gun", mesh = "1", tex = "2", align = {1, 0, -0.1, 90, 0, 126.6693}}'
)
T.eq(A.rowText({ slot = "gun", words = { "a", "b" }, count = 3 }), '{slot = "gun", words = {"a", "b"}, count = 3}')
T.eq(A.rowText({ part = "Head", hat = "5", acc = "Name", name = "N", key = "k" }), '{part = "Head", hat = "5", acc = "Name", name = "N", key = "k"}')
T.eq(A.rowText({ part = "Head", mesh = "1", align = { -0.00001, 1e-7, 114.5916, 5, -5, 0.1 + 0.2 } }), '{part = "Head", mesh = "1", align = {0, 0, 114.5916, 5, -5, 0.3}}')
T.eq(A.rowText({ part = "Head", mesh = "1", align = { 123456.789, 0, 0, 0, 0, 0 } }), '{part = "Head", mesh = "1", align = {123456.789, 0, 0, 0, 0, 0}}')
T.eq(A.rowText({ part = "Head", mesh = "1", align = { 100, 10, 1, 0, 0, 0 } }), '{part = "Head", mesh = "1", align = {100, 10, 1, 0, 0, 0}}')
local quoted = A.rowText({ slot = "gun", name = 'a "b" \\ c\n' })
T.eq(quoted, '{slot = "gun", name = "a \\"b\\" \\\\ c\\010"}')
T.eq(A.parse("return { " .. quoted .. " }")[1].name, 'a "b" \\ c\n', "text with quotes and breaks survives")

T.section("alignment: a whole file written and read back")
local out = A.serialize(A.clean({
	rig = { { part = "Head", mesh = "1", align = { 0, 0, 0, 0, 180, 0 } } },
	scripts = { Zed = { { slot = "z", hat = "2" } }, Alpha = { { slot = "a", hat = "3" } }, Empty = {} },
}))
T.eq(
	out,
	'return {\n\tversion = 1,\n\trig = {\n\t\t{part = "Head", mesh = "1", align = {0, 0, 0, 0, 180, 0}},\n\t},\n\tscripts = {\n\t\t["Alpha"] = {\n\t\t\t{slot = "a", hat = "3"},\n\t\t},\n\t\t["Zed"] = {\n\t\t\t{slot = "z", hat = "2"},\n\t\t},\n\t},\n}\n'
)
T.eq(A.serialize(A.empty()), "return {\n\tversion = 1,\n}\n")
local back = A.clean(A.parse(out))
T.eq(#back.rig, 1)
T.eq(back.scripts.Alpha[1].hat, "3")
T.eq(back.scripts.Empty, nil)

T.section("alignment: same row")
local base = { part = "Head", mesh = "1", align = { 1, 2, 3, 4, 5, 6 } }
T.eq(A.sameRow(base, { part = "Head", mesh = "1", align = { 1, 2, 3, 4, 5, 6 } }), true)
T.eq(A.sameRow(base, { part = "Head", mesh = "1", align = { 1, 2, 3, 4, 5, 6.00001 } }), true, "a tiny difference is the same row")
T.eq(A.sameRow(base, { part = "Head", mesh = "1", align = { 1, 2, 3, 4, 5, 6.1 } }), false)
T.eq(A.sameRow(base, { part = "Torso", mesh = "1", align = { 1, 2, 3, 4, 5, 6 } }), false)
T.eq(A.sameRow(base, { part = "Head", mesh = "2", align = { 1, 2, 3, 4, 5, 6 } }), false)
T.eq(A.sameRow(base, { part = "Head", mesh = "1" }), false)
T.eq(A.sameRow({ slot = "g", words = { "a" } }, { slot = "g", words = { "a" } }), true)
T.eq(A.sameRow({ slot = "g", words = { "a" } }, { slot = "g", words = { "b" } }), false)
T.eq(A.sameRow({ slot = "g", words = { "a" } }, { slot = "g" }), false)
T.eq(A.sameRow({ part = "Head", mesh = "1", note = "a" }, { part = "Head", mesh = "1", note = "b" }), true, "notes do not make a row different")
T.eq(A.sameRow(base, nil), false)

local BUILTIN_TEXT = [=====[
return {
	version = 1,
	help = { "line one" },
	slots = { ["Test Script"] = { gun = "the gun", bullet = "the bullet" } },
	rig = {
		{part = "Head", mesh = "111", align = {0, 0, 0, 0, 180, 0}, note = "a head"},
		{part = "Left Arm", mesh = "222", tex = "333", align = {1, 2, 3, 4, 5, 6}},
		{part = "Torso", acc = "Accessory (autorig_Torso)"},
	},
	scripts = {
		["Test Script"] = {
			{slot = "gun", mesh = "444", tex = "555", align = {1, 0, 0, 90, 0, 0}},
			{slot = "bullet", hat = "666"},
		},
	},
}
]=====]

local function newEnv()
	local env = { files = {}, fetches = 0, text = BUILTIN_TEXT, resolves = 0 }
	env.api = {
		fetch = function(rel)
			env.fetches += 1
			env.asked = rel
			if env.offline then
				return false, "offline"
			end
			if env.text then
				return true, env.text
			end
			return false, "HTTP 404"
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
			if env.failWrite then
				error("disk is full")
			end
			if env.refuseWrite then
				return false
			end
			env.files.user = text
			return true
		end,
		writeBackup = function(text)
			env.files.backup = text
			return true
		end,
		cframe = function(...)
			return { cf = { ... } }
		end,
		publish = function(list, info)
			env.published = list
			env.info = info
		end,
		resolveHat = function(id)
			env.resolves += 1
			if env.hats and env.hats[id] then
				return env.hats[id]
			end
			return nil, "no such hat"
		end,
	}
	return env
end

T.section("alignment: loading the shipped file")
local env = newEnv()
local svc = A.new(env.api)
T.eq(svc.loaded, false)
local ok, status = svc:load()
T.eq(ok, true)
T.eq(env.asked, "Alignment/alignment.lua")
T.eq(status.source, "net")
T.eq(status.err, nil)
T.eq(status.rigRows, 3)
T.eq(status.userRows, 0)
T.eq(status.published, 3)
T.eq(status.pending, 0)
T.eq(status.rev, 1)
T.eq(status.loaded, true)
T.eq(env.files.cache, BUILTIN_TEXT, "a copy is kept for when GitHub is out of reach")
T.eq(#env.published, 3)
T.eq(env.published[1].PartName, "Head")
T.same(env.published[1].C0.cf, { 0, 0, 0, 0, 180, 0 })
T.eq(env.info.rev, 1)
T.eq(type(env.info.cframe), "function")
T.eq(env.info.data.rig[1].src, "built-in")
T.eq(#env.info.rows("Test Script", "gun"), 1)
T.eq(env.info.rows("Test Script", "gun")[1].mesh, "444")
T.eq(env.info.match("Test Script", "gun", { mesh = "444", tex = "555" }).src, "built-in", "match sees the shipped rows too")
T.eq(env.info.match("Test Script", "gun", { mesh = "444", tex = "1" }), nil, "the texture has to fit as well")
T.eq(#env.info.mine("Test Script", "gun"), 0, "but mine has nothing until you add a row")
T.eq(#env.info.rows("Test Script"), 2)
T.eq(#env.info.rows("Nope"), 0)
T.eq(svc:data().slots["Test Script"].gun, "the gun")

T.section("alignment: loading twice")
env = newEnv()
env.text = 'return { rig = { {part = "Tail", mesh = "1"}, {part = "Head", mesh = "2"} } }'
svc = A.new(env.api)
ok, status = svc:load()
T.eq(#status.problems, 1)
ok, status = svc:load()
T.eq(#status.problems, 1, "loading again does not pile the old problems up")
T.eq(status.rev, 2)
T.eq(status.rigRows, 1)

T.section("alignment: when GitHub cannot be reached")
env = newEnv()
env.files.cache = BUILTIN_TEXT
env.offline = true
svc = A.new(env.api)
ok, status = svc:load()
T.eq(ok, true, "the saved copy is used")
T.eq(status.source, "cache")
T.eq(type(status.err), "string")
T.eq(status.rigRows, 3)
T.eq(#env.published, 3)
env = newEnv()
env.offline = true
svc = A.new(env.api)
ok, status = svc:load()
T.eq(ok, false)
T.eq(status.source, "none")
T.eq(status.rigRows, 0)
T.eq(#env.published, 0, "nothing built in, nothing published")
T.eq(status.loaded, true)
env = newEnv()
env.text = "return { rig = { "
env.files.cache = BUILTIN_TEXT
svc = A.new(env.api)
ok, status = svc:load()
T.eq(ok, true, "a broken file on GitHub falls back to the saved copy")
T.eq(status.source, "cache")
T.ok(string.find(status.err, "Alignment/alignment.lua", 1, true) ~= nil)
T.eq(env.files.cache, BUILTIN_TEXT, "a broken file never replaces the saved copy")
env = newEnv()
env.text = nil
svc = A.new(env.api)
ok, status = svc:load()
T.eq(ok, false)
T.eq(status.err, "couldn't get Alignment/alignment.lua")
env = newEnv()
env.api.readCache = nil
env.api.saveCache = nil
env.api.fetch = nil
svc = A.new(env.api)
ok, status = svc:load()
T.eq(ok, false)
T.eq(status.source, "none")
env = newEnv()
env.api.readCache = function()
	error("no disk")
end
env.offline = true
svc = A.new(env.api)
ok, status = svc:load()
T.eq(ok, false, "a failing cache read is not an error for the hub")

T.section("alignment: rows you added earlier")
env = newEnv()
env.files.user = 'return { rig = { {part = "Right Leg", mesh = "999", align = {0, 1, 0, 0, 0, 0}} }, scripts = { ["Test Script"] = { {slot = "gun", mesh = "777"} } } }'
svc = A.new(env.api)
ok, status = svc:load()
T.eq(status.userRows, 2)
T.eq(status.published, 4)
T.eq(env.published[1].PartName, "Right Leg", "your rows come first, so they win")
T.eq(env.published[1].meshid, "999")
T.eq(env.info.data.rig[1].src, "user")
T.eq(env.info.rows("Test Script", "gun")[1].mesh, "777")
T.eq(env.info.rows("Test Script", "gun")[2].mesh, "444")
T.eq(#svc:userRows("rig"), 1)
T.eq(#svc:userRows("scripts", "Test Script"), 1)
T.eq(#svc:userRows("scripts", "Other"), 0)
env = newEnv()
env.files.user = 'return { rig = { {part = "Tail", mesh = "9"}, {part = "Head", mesh = "8"} } }'
svc = A.new(env.api)
ok, status = svc:load()
T.eq(status.userRows, 1)
T.eq(#status.problems, 1)
T.ok(string.find(status.problems[1], "your file", 1, true) ~= nil)

T.section("alignment: a user file you broke while editing")
env = newEnv()
env.files.user = "return { rig = { {part = 'Head', mesh = "
svc = A.new(env.api)
ok, status = svc:load()
T.eq(ok, true, "the shipped file still loads")
T.eq(status.userRows, 0)
T.eq(type(status.userErr), "string")
local added, index, saved = svc:add("rig", nil, { part = "Head", mesh = "5", align = { 0, 0, 0, 0, 0, 0 } })
T.eq(added, true)
T.eq(index, 1)
T.eq(saved, true)
T.eq(env.files.backup, "return { rig = { {part = 'Head', mesh = ", "the file you broke is kept before it is replaced")
T.ok(string.find(env.files.user, 'mesh = "5"', 1, true) ~= nil)
T.eq(svc.userErr, nil)
env.files.backup = nil
svc:add("rig", nil, { part = "Torso", mesh = "6" })
T.eq(env.files.backup, nil, "the backup is only written once")

T.section("alignment: adding hats")
env = newEnv()
svc = A.new(env.api)
svc:load()
local rev0 = svc.rev
added, index, saved = svc:add("rig", nil, { part = "Left Leg", mesh = "13831073174", tex = "456", align = { 0, -0.62, 0, 90, 0, 0 }, note = "mine" })
T.eq(added, true)
T.eq(index, 1)
T.eq(saved, true)
T.eq(svc.rev, rev0 + 1, "every change publishes again")
T.eq(env.info.rev, rev0 + 1)
T.eq(#env.published, 4)
T.eq(env.published[1].PartName, "Left Leg")
T.eq(env.published[1].meshid, "13831073174")
T.same(env.published[1].C0.cf, { 0, -0.62, 0, 90, 0, 0 })
local sizeBefore = #env.published
added, index = svc:add("rig", nil, { part = "Head", mesh = "111", align = { 0, 9, 0, 0, 0, 0 } })
T.eq(added, true)
T.eq(#env.published, sizeBefore, "a row for a hat the shipped file already has replaces it")
local headCount = 0
for _, entry in ipairs(env.published) do
	if entry.PartName == "Head" and entry.meshid == "111" then
		headCount += 1
		T.same(entry.C0.cf, { 0, 9, 0, 0, 0, 0 })
	end
end
T.eq(headCount, 1)
svc:remove("rig", nil, 2)
T.eq(#env.published, sizeBefore, "taking your row away brings the shipped one back")
local headAgain
for _, entry in ipairs(env.published) do
	if entry.PartName == "Head" and entry.meshid == "111" then
		headAgain = entry
	end
end
T.same(headAgain.C0.cf, { 0, 0, 0, 0, 180, 0 })
local reread = A.clean(A.parse(env.files.user))
T.eq(#reread.rig, 1)
T.eq(reread.rig[1].note, "mine")
added, index = svc:add("rig", nil, { part = "Left Leg", mesh = "13831073174", tex = "456", align = { 0, -0.62, 0, 90, 0, 0 } })
T.eq(added, false)
T.eq(index, "that row is already there")
added, index = svc:add("rig", nil, { part = "Tail", mesh = "1" })
T.eq(added, false)
T.ok(string.find(index, "part has to be", 1, true) ~= nil)
added, index = svc:add("rig", nil, { part = "Head" })
T.eq(added, false)
added, index = svc:add("scripts", nil, { slot = "gun", mesh = "1" })
T.eq(added, false)
T.eq(index, "which script is it for?")
added, index = svc:add("scripts", "Test Script", { slot = "gun", mesh = "31337", align = { 1, 1, 1, 0, 0, 0 } })
T.eq(added, true)
T.eq(index, 1)
T.eq(env.info.rows("Test Script", "gun")[1].mesh, "31337", "script rows are published for the scripts to read")
T.eq(env.info.rows("Test Script", "gun")[1].src, "user")
T.eq(env.info.match("Test Script", "gun", { mesh = "31337" }).src, "user", "match finds your row by mesh")
T.eq(env.info.match("Test Script", "gun", { mesh = "999" }), nil, "a hat nobody listed matches nothing")
T.eq(env.info.match("Test Script", "bullet", { mesh = "31337" }), nil, "a row only counts for its own job")
T.eq(env.info.match("Other Script", "gun", { mesh = "31337" }), nil, "and only for its own script")
T.eq(#env.info.mine("Test Script", "gun"), 1, "mine has only the rows you added")
T.eq(env.info.mine("Test Script", "gun")[1].mesh, "31337")
T.eq(#env.info.mine("Test Script", "bullet"), 0)
T.same(env.info.offset(env.info.mine("Test Script", "gun")[1]).cf, { 1, 1, 1, 0, 0, 0 }, "offset turns align into a CFrame")
T.eq(env.info.offset({ slot = "gun" }), nil, "a row with no align has no offset")
T.eq(env.info.offset(nil), nil)
added, index = svc:add("scripts", "A New Script", { slot = "x", hat = "12" })
T.eq(added, true)
T.eq(#env.info.rows("A New Script"), 1)
local file = A.clean(A.parse(env.files.user))
T.eq(#file.rig, 1)
T.eq(#file.scripts["Test Script"], 1)
T.eq(#file.scripts["A New Script"], 1)
T.eq(svc:status().userRows, 3)

T.section("alignment: matching a hat to a job")
T.eq(A.squash("Sakura Futuristic-Sniper (Back)"), "sakurafuturisticsniperback")
T.eq(A.squash(nil), "")
T.ok(A.matchJob({ slot = "gun", mesh = "123" }, { mesh = "rbxassetid://123" }), "mesh is found inside the hat's mesh")
T.ok(not A.matchJob({ slot = "gun", mesh = "123" }, { mesh = "456" }))
T.ok(A.matchJob({ slot = "gun", mesh = "1", tex = "2" }, { mesh = "1", tex = "2" }))
T.ok(not A.matchJob({ slot = "gun", mesh = "1", tex = "2" }, { mesh = "1", tex = "3" }), "mesh and texture both have to fit")
T.ok(A.matchJob({ slot = "gun", acc = "MyGun" }, { name = "MyGun" }), "an accessory name is the hat's name")
T.ok(not A.matchJob({ slot = "gun", acc = "MyGun" }, { name = "Other" }))
T.ok(A.matchJob({ slot = "gun", words = { "sakura", "sniper" } }, { name = "Sakura Futuristic Sniper (Back)" }), "every word has to be in the name")
T.ok(not A.matchJob({ slot = "gun", words = { "sakura", "rifle" } }, { name = "Sakura Futuristic Sniper (Back)" }))
T.ok(not A.matchJob({ slot = "gun", words = { "" } }, { name = "Anything" }), "an empty word list matches nothing")
T.ok(A.matchJob({ slot = "gun", name = "Big Gun" }, { name = "big-gun" }), "a name matches with case and signs ignored")
T.ok(not A.matchJob({ slot = "gun", name = "Big Gun" }, { name = "" }))
T.ok(not A.matchJob({ slot = "gun", hat = "5" }, { mesh = "5", name = "x" }), "a hat id that was never looked up matches nothing by itself")
T.ok(not A.matchJob(nil, { mesh = "1" }))
T.ok(not A.matchJob({ slot = "gun", mesh = "1" }, nil))

T.section("alignment: the number of your own rows is capped")
env = newEnv()
svc = A.new(env.api)
svc:load()
local savedMax = A.MAX_USER_ROWS
A.MAX_USER_ROWS = 2
T.eq((svc:add("rig", nil, { part = "Head", mesh = "1" })), true)
T.eq((svc:add("rig", nil, { part = "Head", mesh = "2" })), true)
added, index = svc:add("rig", nil, { part = "Head", mesh = "3" })
T.eq(added, false)
T.eq(index, "you already have 2 rows here")
T.eq((svc:add("scripts", "S", { slot = "x", hat = "1" })), true, "each list has its own cap")
A.MAX_USER_ROWS = savedMax

T.section("alignment: changing and removing hats")
env = newEnv()
svc = A.new(env.api)
svc:load()
svc:add("rig", nil, { part = "Head", mesh = "1" })
svc:add("rig", nil, { part = "Torso", mesh = "2" })
svc:add("rig", nil, { part = "Left Arm", mesh = "3" })
local changed, where = svc:replace("rig", nil, 2, { part = "Torso", mesh = "22", align = { 0, 1, 0, 0, 0, 0 } })
T.eq(changed, true)
T.eq(where, 2)
T.eq(svc:userRows("rig")[2].mesh, "22")
T.eq(env.published[2].meshid, "22")
changed, where = svc:replace("rig", nil, 2, { part = "Torso", mesh = "3x" })
T.eq(changed, false)
changed, where = svc:replace("rig", nil, 9, { part = "Torso", mesh = "5" })
T.eq(changed, false)
T.eq(where, "that row is gone")
changed, where = svc:replace("rig", nil, 2, { part = "Head", mesh = "1" })
T.eq(changed, false, "a change cannot copy another row")
T.eq(where, "that row is already there")
local rev1 = svc.rev
changed = svc:remove("rig", nil, 1)
T.eq(changed, true)
T.eq(svc.rev, rev1 + 1)
T.eq(#svc:userRows("rig"), 2)
T.eq(svc:userRows("rig")[1].mesh, "22")
T.eq(env.published[1].meshid, "22")
T.eq(A.clean(A.parse(env.files.user)).rig[1].mesh, "22")
changed, where = svc:remove("rig", nil, 7)
T.eq(changed, false)
T.eq(where, "that row is gone")
svc:remove("rig", nil, 1)
svc:remove("rig", nil, 1)
T.eq(#svc:userRows("rig"), 0)
T.eq(env.files.user, "return {\n\tversion = 1,\n}\n")
T.eq(svc:remove("scripts", "Nothing", 1), false)

T.section("alignment: when saving does not work")
env = newEnv()
svc = A.new(env.api)
svc:load()
env.failWrite = true
added, index, saved = svc:add("rig", nil, { part = "Head", mesh = "1" })
T.eq(added, true, "the hat still works for this session")
T.eq(saved, false)
T.ok(string.find(select(4, svc:add("rig", nil, { part = "Torso", mesh = "2" })), "couldn't save", 1, true) ~= nil)
T.eq(env.published[2].PartName, "Torso")
env.failWrite = nil
env.refuseWrite = true
local _, _, savedFlag, note = svc:add("rig", nil, { part = "Head", mesh = "7" })
T.eq(savedFlag, false)
T.eq(note, "couldn't save your hats")
env = newEnv()
env.api.writeUser = nil
svc = A.new(env.api)
svc:load()
_, _, savedFlag, note = svc:add("rig", nil, { part = "Head", mesh = "1" })
T.eq(savedFlag, false)
T.ok(string.find(note, "can't save files", 1, true) ~= nil)
T.eq(#env.published, 4, "still published")

T.section("alignment: looking up a catalog hat")
env = newEnv()
env.hats = { ["123"] = { mesh = "rbxassetid://777", tex = "888", name = "Cool Hat" }, ["124"] = { mesh = "", tex = "" } }
svc = A.new(env.api)
svc:load()
svc:add("rig", nil, { part = "Torso", hat = "123" })
T.eq(svc.pending, 1, "the row waits until the hat is looked up")
T.eq(#env.published, 3)
local found = svc:resolve("123")
T.eq(found.mesh, "777")
T.eq(found.tex, "888")
T.eq(found.name, "Cool Hat")
T.eq(env.resolves, 1)
T.eq(svc.pending, 0)
T.eq(#env.published, 4, "the row is published once its mesh is known")
T.eq(env.published[1].PartName, "Torso")
T.eq(env.published[1].meshid, "777")
T.eq(env.published[1].textureid, "888")
T.eq(svc:resolve(123).mesh, "777")
T.eq(env.resolves, 1, "a hat is looked up once")
local missing, reason = svc:resolve("999")
T.eq(missing, nil)
T.eq(reason, "no such hat")
missing, reason = svc:resolve("124")
T.eq(missing, nil)
T.eq(reason, "that hat has no mesh to line up")
missing, reason = svc:resolve("abc")
T.eq(missing, nil)
T.eq(reason, "that is not a hat id")
env.api.resolveHat = function()
	error("the game said no")
end
missing, reason = svc:resolve("5")
T.eq(missing, nil)
T.ok(string.find(reason, "the game said no", 1, true) ~= nil)
env.api.resolveHat = nil
missing, reason = svc:resolve("6")
T.eq(missing, nil)
T.ok(string.find(reason, "can't look catalog hats up", 1, true) ~= nil)

T.section("alignment: filling in a row from its hat id")
env = newEnv()
env.hats = { ["123"] = { mesh = "777", tex = "888", name = "Cool Hat" } }
svc = A.new(env.api)
svc:load()
local filled = svc:fill({ part = "Head", hat = "123" })
T.eq(filled.mesh, "777")
T.eq(filled.tex, "888")
T.eq(filled.name, "Cool Hat")
T.eq(filled.hat, "123")
filled = svc:fill({ part = "Head", hat = "123", mesh = "5" })
T.eq(filled.mesh, "5")
T.eq(filled.tex, nil, "a row with its own mesh is left alone")
filled = svc:fill({ part = "Head", hat = "123", name = "Mine" })
T.eq(filled.name, "Mine")
local nothing, nothingWhy = svc:fill({ part = "Head", hat = "404" })
T.eq(nothing, nil)
T.eq(nothingWhy, "no such hat")
T.eq(svc:fill({ part = "Head", acc = "X" }).acc, "X")

T.section("alignment: which row covers a worn hat")
env = newEnv()
svc = A.new(env.api)
svc:load()
T.eq(svc:covering({ mesh = "222", tex = "333" }).part, "Left Arm")
T.eq(svc:covering({ mesh = "111" }).part, "Head")
T.eq(svc:covering({ acc = "Accessory (autorig_Torso)" }).part, "Torso")
T.eq(svc:covering({ mesh = "424242" }), nil)
svc:add("rig", nil, { part = "Right Arm", mesh = "424242" })
T.eq(svc:covering({ mesh = "424242" }).part, "Right Arm")
T.eq(svc:covering({ mesh = "424242" }).src, "user")

T.section("alignment: your rows as text")
T.same(A.parse(svc:userText()), { version = 1, rig = { { part = "Right Arm", mesh = "424242" } } })

T.section("alignment: nothing breaks without a way to publish")
env = newEnv()
env.api.publish = nil
svc = A.new(env.api)
ok = svc:load()
T.eq(ok, true)
env.api.publish = function()
	error("could not set the global")
end
T.ok(pcall(svc.add, svc, "rig", nil, { part = "Head", mesh = "1" }), "a failing publish does not break adding")
svc = A.new({})
ok = svc:load()
T.eq(ok, false, "a service with no environment still loads")
T.eq((svc:add("rig", nil, { part = "Head", mesh = "1" })), true)
T.eq(#svc.entries, 0 + 1)

T.section("alignment: the hub environment")
local files = {}
local urls = {}
local genv = {}
local hubCtx = {
	Net = {
		get = function(url)
			urls[#urls + 1] = url
			return true, "body"
		end,
	},
	Repo = {
		raw = function(rel)
			return "https://raw.example/" .. rel
		end,
	},
	HAS_FS = true,
	FS = {
		read = function(path)
			return files[path]
		end,
		write = function(path, text)
			files[path] = text
			return true
		end,
	},
	Origin = { root = nil },
	GENV = genv,
}
local hub = A.hubEnv(hubCtx)
local fetched, body = hub.fetch("Alignment/alignment.lua")
T.eq(fetched, true)
T.eq(body, "body")
T.ok(string.find(urls[1], "^https://raw%.example/Alignment/alignment%.lua%?t=%d+$") ~= nil, urls[1])
T.eq(hub.saveCache("x"), true)
T.eq(files["AtsukoHub/cache/alignment.lua"], "x")
T.eq(hub.readCache(), "x")
T.eq(hub.writeUser("y"), true)
T.eq(files["AtsukoHub/alignment_user.lua"], "y")
T.eq(hub.readUser(), "y")
T.eq(hub.writeBackup("z"), true)
T.eq(files["AtsukoHub/alignment_user_broken.lua"], "z")
hub.publish({ 1 }, { rev = 4 })
T.same(genv.AtsukoAligns, { 1 })
T.eq(genv.AtsukoAlignment.rev, 4)
hub.publish(nil, nil)
T.eq(genv.AtsukoAligns, nil)
T.eq(genv.AtsukoAlignment, nil)
hubCtx.Origin.root = "Atsuko Hub"
hub = A.hubEnv(hubCtx)
T.eq(hub.saveCache, nil, "from your own folder nothing is cached")
T.eq(hub.readCache, nil)
T.eq(type(hub.readUser), "function", "your own hats are still kept")
hubCtx.HAS_FS = false
hub = A.hubEnv(hubCtx)
T.eq(hub.readUser, nil)
T.eq(hub.writeUser, nil)
T.eq(type(hub.fetch), "function")

T.section("alignment: the default CFrame and the hat lookup")
local savedCFrame, savedGame = _G.CFrame, _G.game
local made = {}
local function product(label)
	return setmetatable({ label = label }, { __mul = function(a, b)
		return { mul = { a.label or a, b.label or b } }
	end })
end
_G.CFrame = {
	new = function(...)
		made.new = { ... }
		return product("new")
	end,
	Angles = function(...)
		made.angles = { ... }
		return product("angles")
	end,
}
hub = A.hubEnv({ Net = hubCtx.Net, Repo = hubCtx.Repo, GENV = {} })
local cf = hub.cframe(1, 2, 3, 90, 180, -90)
T.same(made.new, { 1, 2, 3 })
T.near(made.angles[1], math.pi / 2)
T.near(made.angles[2], math.pi)
T.near(made.angles[3], -math.pi / 2)
T.same(cf, { mul = { "new", "angles" } })

local function inst(class, props, children)
	local o = { ClassName = class, Name = props.Name or class, kids = children or {} }
	for key, value in pairs(props) do
		o[key] = value
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
	function o:FindFirstChildWhichIsA(c, deep)
		for _, kid in ipairs(self.kids) do
			if kid:IsA(c) then
				return kid
			end
			if deep then
				local inner = kid:FindFirstChildWhichIsA(c, true)
				if inner then
					return inner
				end
			end
		end
		return nil
	end
	function o:Destroy()
		self.destroyed = true
	end
	return o
end

local seenUrl = {}
local function lookup(objects, failing)
	_G.game = {
		GetObjects = function(_, url)
			seenUrl.url = url
			if failing then
				error("HttpGet is not allowed")
			end
			return objects
		end,
	}
	return hub.resolveHat("123")
end

local meshHandle = inst("MeshPart", { Name = "Handle", MeshId = "rbxassetid://111", TextureID = "rbxassetid://222" })
local accessory = inst("Accessory", { Name = "Cool Hat" }, { meshHandle })
local result = lookup({ accessory })
T.eq(seenUrl.url, "rbxassetid://123")
T.eq(result.mesh, "111")
T.eq(result.tex, "222")
T.eq(result.name, "Cool Hat")
T.eq(accessory.destroyed, true, "what was downloaded is cleaned up")

local special = inst("SpecialMesh", { MeshId = "http://www.roblox.com/asset/?id=333", TextureId = "" })
local partHandle = inst("Part", { Name = "Handle" }, { special })
accessory = inst("Accessory", { Name = "Old Hat" }, { partHandle })
result = lookup({ accessory })
T.eq(result.mesh, "333")
T.eq(result.tex, nil)

local inner = inst("Accessory", { Name = "Inner" }, { inst("MeshPart", { Name = "Handle", MeshId = "rbxassetid://444", TextureID = "" }) })
local model = inst("Model", { Name = "Wrapper" }, { inst("Folder", {}, { inner }) })
result = lookup({ model })
T.eq(result.mesh, "444")
T.eq(result.name, "Wrapper", "the name comes from what the game gave back")

local loose = inst("Part", { Name = "Handle" }, { inst("SpecialMesh", { MeshId = "rbxassetid://555", TextureId = "rbxassetid://556" }) })
result = lookup({ loose })
T.eq(result.mesh, "555", "a loose Handle part works too")
T.eq(result.tex, "556")
result = lookup({ inst("Part", { Name = "Other" }, { inst("SpecialMesh", { MeshId = "rbxassetid://1", TextureId = "" }) }) })
T.eq(result, nil, "a part that is not a Handle is not a hat")

local noMesh = inst("Accessory", { Name = "Bare" }, { inst("Part", { Name = "Handle" }) })
local noMeshResult, noMeshWhy = lookup({ noMesh })
T.eq(noMeshResult, nil)
T.eq(noMeshWhy, "that hat has no mesh to line up")
local noHandle = inst("Accessory", { Name = "Empty" })
local noHandleResult, noHandleWhy = lookup({ noHandle })
T.eq(noHandleResult, nil)
T.eq(noHandleWhy, "that hat could not be found")
local failed, failedWhy = lookup(nil, true)
T.eq(failed, nil)
T.eq(failedWhy, "this executor can't look catalog hats up")
failed, failedWhy = lookup("text")
T.eq(failed, nil)
_G.CFrame, _G.game = savedCFrame, savedGame

T.section("alignment: hats you wear")
T.same(A.wornHats(nil), {})
local body = inst("Model", { Name = "Character" }, {
	inst("Accessory", { Name = "Sword" }, { inst("MeshPart", { Name = "Handle", MeshId = "rbxassetid://11", TextureID = "rbxassetid://12" }) }),
	inst("Hat", { Name = "OldHat" }, { inst("Part", { Name = "Handle" }, { inst("SpecialMesh", { MeshId = "http://www.roblox.com/asset/?id=21", TextureId = "" }) }) }),
	inst("Part", { Name = "Torso" }),
	inst("Accessory", { Name = "Bare" }),
	inst("Accessory", { Name = "Plain" }, { inst("Part", { Name = "Handle" }) }),
})
local worn = A.wornHats(body)
T.eq(#worn, 4, "only hats are listed")
T.eq(worn[1].name, "Sword")
T.eq(worn[1].mesh, "11")
T.eq(worn[1].tex, "12")
T.eq(worn[2].name, "OldHat")
T.eq(worn[2].mesh, "21")
T.eq(worn[2].tex, nil)
T.eq(worn[3].name, "Bare")
T.eq(worn[3].mesh, nil, "a hat with no handle is listed but has no ids")
T.eq(worn[4].name, "Plain")
local crowd = {}
for i = 1, 60 do
	crowd[i] = inst("Accessory", { Name = "Hat" .. i }, { inst("MeshPart", { Name = "Handle", MeshId = "rbxassetid://" .. i, TextureID = "" }) })
end
local crowded = A.wornHats(inst("Model", { Name = "Crowd" }, crowd))
T.eq(#crowded, 40, "no more than forty hats are listed")
T.eq(crowded[40].name, "Hat40")

T.section("alignment: hat ids that are only looked up later")
local LATE = 'return { rig = { {part = "Torso", hat = "10"}, {part = "Head", hat = "20", align = {0, 1, 0}}, {part = "Left Leg", hat = "30"}, {part = "Left Arm", hat = "10"} }, scripts = { S = { {slot = "gun", hat = "20"}, {slot = "gun", hat = "10"} } } }'
env = newEnv()
env.text = LATE
env.hats = { ["10"] = { mesh = "rbxassetid://101", tex = "", name = "Ten" }, ["20"] = { mesh = "", tex = "202" } }
svc = A.new(env.api)
ok, status = svc:load()
T.eq(status.pending, 4)
T.eq(status.waiting, 3, "three different hats still have to be looked up")
T.eq(#env.published, 0)
T.eq(env.info.rows("S", "gun")[1].tex, nil, "a script row does not know its hat yet")
local quietRev = svc.rev
local quiet, quietWhy, fresh = svc:lookup("10")
T.eq(quiet.mesh, "101")
T.eq(quiet.name, "Ten")
T.eq(fresh, true)
T.eq(svc.rev, quietRev, "a quiet lookup publishes nothing")
quiet, quietWhy, fresh = svc:lookup(10)
T.eq(fresh, false, "a second look is answered from memory")
T.eq(env.resolves, 1)
T.eq(svc:status().waiting, 2, "a hat that is known is not waiting any more")
local resolvedBefore = svc.rev
local count, failures = svc:resolvePending()
T.eq(count, 1, "hat 10 was already known, so only hat 20 is new")
T.eq(#failures, 1)
T.eq(failures[1].id, "30")
T.eq(failures[1].why, "no such hat")
T.eq(svc.rev, resolvedBefore + 1, "one new list for the whole batch")
T.eq(#env.published, 3)
T.eq(svc.pending, 1)
T.eq(svc:status().lookupFailed, 1)
T.eq(svc:status().waiting, 0, "and a hat that was not found is not waiting either")
T.eq(env.resolves, 3, "every id is looked up once")
T.eq(env.info.rows("S", "gun")[1].tex, "202", "script rows now know their hat")
T.eq(env.info.rows("S", "gun")[1].mesh, nil)
T.eq(env.info.rows("S", "gun")[2].mesh, "101")
T.eq(env.info.rows("S", "gun")[2].hat, "10")
T.eq(svc.merged.scripts.S[2].mesh, nil, "the stored rows are not changed")
count, failures = svc:resolvePending()
T.eq(count, 0)
T.eq(#failures, 0, "a hat that was not found is not tried again by itself")
T.eq(env.resolves, 3)
env.hats["30"] = { mesh = "303", tex = "" }
local again = svc:resolve("30")
T.eq(again.mesh, "303", "asking for it yourself tries again")
T.eq(svc:status().lookupFailed, 0)
T.eq(svc.pending, 0)
T.eq(#env.published, 4)
ok, status = svc:load()
T.eq(status.lookupFailed, 0, "loading starts the memory over")
T.eq(status.waiting, 0)
count = svc:resolvePending()
T.eq(count, 0, "what was looked up stays known")
env = newEnv()
env.text = 'return { rig = { {part = "Head", mesh = "1"} }, scripts = { S = { {slot = "gun", hat = "77"} } } }'
svc = A.new(env.api)
ok, status = svc:load()
T.eq(status.pending, 0, "a script row does not hold back the published list")
T.eq(status.waiting, 1, "but its hat still has to be looked up")

T.section("alignment: looking up many hats")
local manyHats = {}
local manyRows = {}
for i = 1, 5 do
	manyHats[tostring(100 + i)] = { mesh = tostring(900 + i), tex = "" }
	manyRows[i] = '{part = "Head", hat = "' .. (100 + i) .. '"}'
end
env = newEnv()
env.text = "return { rig = { " .. table.concat(manyRows, ", ") .. " } }"
env.hats = manyHats
svc = A.new(env.api)
svc:load()
local savedLookups = A.MAX_LOOKUPS
A.MAX_LOOKUPS = 2
count = svc:resolvePending()
T.eq(count, 2, "only a few hats are looked up each time")
T.eq(env.resolves, 2)
count = svc:resolvePending()
T.eq(count, 2)
count = svc:resolvePending()
T.eq(count, 1)
T.eq(env.resolves, 5)
T.eq(#env.published, 5)
A.MAX_LOOKUPS = savedLookups
env = newEnv()
env.text = LATE
env.hats = manyHats
svc = A.new(env.api)
svc:load()
svc.dead = true
count, failures = svc:resolvePending()
T.eq(count, 0, "nothing is looked up once the hub is gone")
T.eq(env.resolves, 0)

T.section("alignment: the module as the hub loads it")
A.init(hubCtx)
T.ok(A.service ~= nil)
local liveService = A.service
liveService:load()
T.ok(genv.AtsukoAligns ~= nil or genv.AtsukoAlignment ~= nil, "the service publishes into the hub environment")
A.destroy()
T.eq(A.service, nil)
T.eq(genv.AtsukoAligns, nil, "leaving the hub takes the list away")
T.eq(genv.AtsukoAlignment, nil)
T.eq(liveService.dead, true)
local revBefore = liveService.rev
liveService:publish()
T.eq(liveService.rev, revBefore, "a service that was shut down does not publish again")
T.eq(genv.AtsukoAligns, nil, "even if a slow download finishes later")
A.destroy()

T.section("alignment: the shipped Alignment/alignment.lua")
local text = readsource("Alignment/alignment.lua")
local raw, parseWhy = A.parse(text)
T.ok(raw ~= nil, "it parses: " .. tostring(parseWhy))
local real, realProblems = A.clean(raw)
T.eq(#realProblems, 0, "every row is understood")
T.eq(#real.rig, 170, "71 before, plus every body part hat from Uhhhhhh's hat map that FDless doesn't know already")
T.eq(#real.help, 6)
T.eq(#real.shared.gun, 23, "every gun from Uhhhhhh's hat map is a gun for every script")
T.eq(#real.shared.sword, 20, "every sword from Uhhhhhh's hat map is a sword for every script")
T.eq(real.shared.gun[1].mesh, "77229698901212")
T.eq(real.shared.gun[1].mate, "76443789550926", "the two cannon halves know each other")
T.same(real.shared.gun[1].rel, { -5.31, -0.225, 0, 0, 0, 0 })
T.eq(real.shared.sword[2].mate, "17326555172")
local akGun = A.rows(A.merge(real, A.empty()), "The Hotline", "gun")
local seesCannon = false
for _, row in ipairs(akGun) do
	if row.mesh == "77229698901212" then
		seesCannon = row.src == "user" and row.shipped == true
	end
end
T.ok(seesCannon, "a ported script with a gun sees Uhhhhhh's guns too, and takes them like a gun you added for every script")
local swordRows = A.rows(A.merge(real, A.empty()), "Neptunian V", "sword")
local seesSword = false
for _, row in ipairs(swordRows) do
	if row.mesh == "4315410540" and row.src == "user" then
		seesSword = true
	end
end
T.ok(seesSword, "and a script with a sword sees Uhhhhhh's swords")
T.eq(#real.shared.bullet, 3, "Uhhhhhh's three bullets are shared too")
T.eq(#real.shared.aura, 2, "and its two auras")
local own = A.rows(A.merge(real, A.empty()), "The Hotline", "bullet")
local ownGolden, sharedBullet = nil, false
for _, row in ipairs(own) do
	if row.mesh == "4307568890" and not row.shipped then
		ownGolden = row.src
	end
	if row.mesh == "128216670" then
		sharedBullet = row.src == "user" and row.shipped == true
	end
end
T.eq(ownGolden, "built-in", "a script's own shipped rows stay a list to read")
T.ok(sharedBullet, "and every script that shoots takes Uhhhhhh's bullets")
T.eq(#A.rows(A.merge(real, A.empty()), "The Hotline", "gun") > 0, true)
T.eq(A.sharedKind("bullet"), nil, "a bullet is still not something you can add for every script")
local scriptNames = {}
local scriptRows = 0
for name, rows in pairs(real.scripts) do
	scriptNames[#scriptNames + 1] = name
	scriptRows += #rows
end
table.sort(scriptNames)
T.same(scriptNames, { "AK-47", "Addict", "Banisher", "Commander V2", "Dubstep Gun", "Gelatek", "InternalWar", "Last Star", "Linked Sword", "Master Chief", "Neptunian V", "Neptunian V Gun", "Snake Banisher V3", "Studio Dummy V4", "The Hotline", "The Sniper" })
T.eq(scriptRows, 166, "the guns, swords and bullets of AK-47, Banisher and Linked Sword moved to shared")
for name, rows in pairs(real.scripts) do
	T.ok(real.slots[name] ~= nil, name .. " explains its slots")
	for index, row in ipairs(rows) do
		T.ok(real.slots[name] and real.slots[name][row.slot] ~= nil, name .. " row " .. index .. " uses the slot " .. tostring(row.slot) .. " that is explained")
	end
end
for name in pairs(real.slots) do
	T.ok(real.scripts[name] ~= nil, name .. " has rows")
end
local seenLimb = {}
for index, row in ipairs(real.rig) do
	seenLimb[row.part] = true
	T.ok(row.mesh or row.tex or row.acc, "rig row " .. index .. " names its hat")
	T.ok(row.align ~= nil or row.acc ~= nil, "rig row " .. index .. " has an alignment")
end
for _, limb in ipairs(A.LIMBS) do
	T.ok(seenLimb[limb], limb .. " has at least one rig row")
end

T.section("alignment: writing the shipped file again loses nothing")
local rewritten = A.clean(A.parse(A.serialize(real)))
T.eq(#rewritten.rig, 170)
T.eq(#rewritten.shared.gun, 23)
T.eq(#rewritten.shared.sword, 20)
T.eq(#rewritten.shared.bullet, 3)
T.eq(#rewritten.shared.aura, 2)
for index, row in ipairs(real.rig) do
	T.ok(A.sameRow(row, rewritten.rig[index]), "rig row " .. index .. " came back the same")
end
for name, rows in pairs(real.scripts) do
	T.eq(#rewritten.scripts[name], #rows, name)
	for index, row in ipairs(rows) do
		T.ok(A.sameRow(row, rewritten.scripts[name][index]), name .. " row " .. index .. " came back the same")
	end
end

T.section("alignment: the rig rows give the same alignments as FDless itself")
local function matrix(r, p)
	return { r = r, p = p }
end
local function identity()
	return matrix({ 1, 0, 0, 0, 1, 0, 0, 0, 1 }, { 0, 0, 0 })
end
local MT = {}
MT.__mul = function(a, b)
	local ar, br = a.r, b.r
	local r = {}
	for i = 0, 2 do
		for j = 0, 2 do
			local s = 0
			for k = 0, 2 do
				s = s + ar[i * 3 + k + 1] * br[k * 3 + j + 1]
			end
			r[i * 3 + j + 1] = s
		end
	end
	local p = {}
	for i = 0, 2 do
		p[i + 1] = a.p[i + 1] + ar[i * 3 + 1] * b.p[1] + ar[i * 3 + 2] * b.p[2] + ar[i * 3 + 3] * b.p[3]
	end
	return setmetatable(matrix(r, p), MT)
end
local function cfNew(x, y, z)
	local m = identity()
	m.p = { x, y, z }
	return setmetatable(m, MT)
end
local function cfAngles(rx, ry, rz)
	local cx, sx, cy, sy, cz, sz = math.cos(rx), math.sin(rx), math.cos(ry), math.sin(ry), math.cos(rz), math.sin(rz)
	local mx = setmetatable(matrix({ 1, 0, 0, 0, cx, -sx, 0, sx, cx }, { 0, 0, 0 }), MT)
	local my = setmetatable(matrix({ cy, 0, sy, 0, 1, 0, -sy, 0, cy }, { 0, 0, 0 }), MT)
	local mz = setmetatable(matrix({ cz, -sz, 0, sz, cz, 0, 0, 0, 1 }, { 0, 0, 0 }), MT)
	return mx * my * mz
end
local function cfMake(x, y, z, rx, ry, rz)
	return cfNew(x, y, z) * cfAngles(math.rad(rx), math.rad(ry), math.rad(rz))
end

local fdSource = readsource("Reanimation/Hat/FDless.lua")
local first = string.find(fdSource, "local aligns={", 1, true)
local last = string.find(fdSource, "\n}\n", first, true)
T.ok(first ~= nil and last ~= nil, "the aligns table of FDless was found")
local block = string.sub(fdSource, first + #"local aligns=", last + 2)
local compiled, compileWhy = loadstring("local cf, angles, cfMul = ...\nreturn " .. block, "=fdless_aligns")
T.ok(compiled ~= nil, "the aligns table of FDless compiles: " .. tostring(compileWhy))
local native = compiled(cfNew, cfAngles, function(a, b)
	return a * b
end)
local published = A.entries(real, cfMake, {})
T.eq(#published, #native + 4 + 99, "as many entries as FDless has, plus the four fedoras of Master Chief's free rig and Uhhhhhh's body part hats")
local function same(a, b)
	a, b = a or identity(), b or identity()
	for i = 1, 9 do
		if math.abs(a.r[i] - b.r[i]) > 0.0005 then
			return false
		end
	end
	for i = 1, 3 do
		if math.abs(a.p[i] - b.p[i]) > 0.0005 then
			return false
		end
	end
	return true
end
for index, theirs in ipairs(native) do
	local mine = published[index]
	T.ok(mine ~= nil, "entry " .. index .. " exists")
	if mine then
		T.eq(mine.PartName, theirs.PartName, "entry " .. index .. " part")
		T.eq(mine.meshid, theirs.meshid, "entry " .. index .. " mesh")
		T.eq(mine.textureid, theirs.textureid, "entry " .. index .. " texture")
		T.eq(mine.AccessoryName, theirs.AccessoryName, "entry " .. index .. " accessory name")
		T.ok(same(mine.C0, theirs.C0), "entry " .. index .. " alignment")
	end
end
local function turned(m)
	local r = m.r
	return setmetatable(matrix({ r[1], r[4], r[7], r[2], r[5], r[8], r[3], r[6], r[9] }, { 0, 0, 0 }), MT)
end
local FEDORAS = {
	{ "Right Arm", "3033903209", -1.57, 0, -1.57 },
	{ "Left Arm", "3360978739", -1.57, 0, 1.57 },
	{ "Right Leg", "3033898741", -1.57, 0, -1.57 },
	{ "Left Leg", "3409604993", -1.57, 0, 1.57 },
}
local voidArms = 0
for i = #native + 5, #published do
	local e = published[i]
	if e.meshid == "17269487439" then
		voidArms += 1
		T.ok(same(e.C0, cfAngles(0, 0, math.pi / 2)), "the void arm sits like Uhhhhhh's hat map says on the " .. e.PartName)
	end
end
T.eq(voidArms, 4, "an arm or leg hat from Uhhhhhh can be any arm or leg")
for i, f in ipairs(FEDORAS) do
	local mine = published[#native + i]
	T.ok(mine ~= nil and mine.PartName == f[1] and mine.meshid == "3030546036" and mine.textureid == f[2], "fedora " .. i .. " is the " .. f[1])
	T.ok(mine and same(mine.C0, turned(cfAngles(f[3], f[4], f[5]))), "fedora " .. i .. " sits like it did in Master Chief's own reanimate")
end

T.section("alignment: sizes at the exact limits")
do
	local exact = "return {" .. string.rep(" ", 300000 - 9) .. "}"
	T.eq(#exact, 300000)
	T.same(A.parse(exact), {}, "a file of exactly the biggest size is read")
	refuses(exact .. " ", "the file is too big")
	refuses(exact .. "  ", "the file is too big")
	local function tables(n)
		local parts = {}
		for i = 1, n do
			parts[i] = "{}"
		end
		return "return { " .. table.concat(parts, ",") .. " }"
	end
	T.eq(type(A.parse(tables(40000))), "table", "forty thousand values are fine")
	refuses(tables(40001), "the file has too many values")
end

T.section("alignment: the line number in a message is the line of the mistake")
do
	refuses('return { a = "abc\n" }', "line 1: a string never ends")
	refuses('return {\n a = 1,\n b = "x\n" }', "line 3: a string never ends")
	refuses('return {\n\n\n a = "x\n" }', "line 4: a string never ends")
end

T.section("alignment: ids in links stop at twenty digits")
do
	local d20 = string.rep("7", 20)
	local d21 = string.rep("7", 21)
	T.eq(A.extractId("https://www.roblox.com/catalog/" .. d20 .. "/name"), d20)
	T.eq(A.extractId("https://www.roblox.com/catalog/" .. d21 .. "/name"), nil)
	T.eq(A.extractId("https://www.roblox.com/catalog/" .. d21), nil)
	T.eq(A.extractId("rbxassetid://" .. d20), d20)
	T.eq(A.extractId("rbxassetid://" .. d21), nil)
	T.eq(A.extractId("https://assets.example.com/?id=" .. d20), d20)
	T.eq(A.extractId("https://assets.example.com/?id=" .. d21), nil)
	T.eq(A.extractId("https://www.roblox.com/bundles/catalog/" .. d21), nil)
end

T.section("alignment: text fields are cut at their limits")
do
	local function rigRow(over)
		local row = { part = "Head", hat = "1" }
		for key, value in pairs(over) do
			row[key] = value
		end
		return A.cleanRow(row, "rig")
	end
	local long = rigRow({ name = string.rep("n", 81), acc = string.rep("a", 81), key = string.rep("k", 25), note = string.rep("z", 121) })
	T.eq(#long.name, 80, "name")
	T.eq(#long.acc, 80, "accessory")
	T.eq(#long.key, 24, "key")
	T.eq(#long.note, 120, "note")
	local fits = rigRow({ name = string.rep("n", 80), acc = string.rep("a", 80), key = string.rep("k", 24), note = string.rep("z", 120) })
	T.eq(#fits.name, 80)
	T.eq(#fits.acc, 80)
	T.eq(#fits.key, 24)
	T.eq(#fits.note, 120)
	local slot = A.cleanRow({ slot = string.rep("s", 25), hat = "1" }, "script")
	T.eq(#slot.slot, 24, "slot")
	local word = rigRow({ words = { string.rep("w", 25) } })
	T.eq(#word.words[1], 24, "a word")
	local eight = rigRow({ words = { "a", "b", "c", "d", "e", "f", "g", "h", "i", "j" } })
	T.eq(#eight.words, 8, "eight words at most")
	T.eq(eight.words[8], "h")
end

T.section("alignment: numbers are cut at their limits, halves included")
do
	local function alignOf(list)
		return A.cleanRow({ part = "Head", hat = "1", align = list }, "rig").align
	end
	T.same(alignOf({ 500.5, -500.5, 500, 1440.5, -1440.5, 1440 }), { 500, -500, 500, 1440, -1440, 1440 })
	T.same(alignOf({ 499.5, -499.5, 0, 1439.5, -1439.5, 0 }), { 499.5, -499.5, 0, 1439.5, -1439.5, 0 })
	T.same(alignOf({ 501, -501, 0, 1441, -1441, 0 }), { 500, -500, 0, 1440, -1440, 0 })
	T.same(alignOf({ 1, 2, 3 }), { 1, 2, 3, 0, 0, 0 })
	T.eq(alignOf({ 1, 2 }), nil, "fewer than three numbers say nothing")
end

T.section("alignment: how many copies a row asks for")
do
	local function countOf(value)
		return A.cleanRow({ part = "Head", hat = "1", count = value }, "rig").count
	end
	T.eq(countOf(math.huge), nil, "no end to it is not a count")
	T.eq(countOf(-math.huge), nil)
	T.eq(countOf(0 / 0), nil)
	T.eq(countOf("1e999"), nil)
	T.eq(countOf(1), nil)
	T.eq(countOf(2), 2)
	T.eq(countOf(2.9), 2)
	T.eq(countOf(8), 8)
	T.eq(countOf(9), 8)
	T.eq(countOf(1e9), 8)
	T.eq(countOf("3"), 3)
	T.eq(countOf("x"), nil)
	T.eq(countOf(true), nil)
end

T.section("alignment: messages that name the problem")
do
	local _, problems = A.clean({ scripts = { Bad = 5 } })
	T.same(problems, { "Bad: has to be a list of rows" })
	_, problems = A.clean({ scripts = { Bad = "text", Worse = true } })
	T.eq(#problems, 2)
end

T.section("alignment: two rows are the same only when everything says so")
do
	local base = { part = "Head", hat = "1", mesh = "2", tex = "3", acc = "Acc", name = "N", key = "k", count = 2, words = { "a" }, align = { 1, 2, 3, 4, 5, 6 } }
	local function with(key, value)
		local copy = {}
		for k, v in pairs(base) do
			copy[k] = v
		end
		copy[key] = value
		return copy
	end
	T.eq(A.sameRow(base, with("count", 2)), true)
	for _, case in ipairs({
		{ "part", "Torso" },
		{ "slot", "gun" },
		{ "hat", "9" },
		{ "mesh", "9" },
		{ "tex", "9" },
		{ "acc", "Other" },
		{ "name", "Other" },
		{ "key", "other" },
		{ "count", 3 },
		{ "count", nil },
		{ "words", { "a", "b" } },
		{ "words", { "b" } },
		{ "words", nil },
		{ "align", { 1, 2, 3, 4, 5, 7 } },
		{ "align", nil },
	}) do
		T.eq(A.sameRow(base, with(case[1], case[2])), false, "differs by " .. case[1])
	end
	T.eq(A.sameRow(with("words", { "a", "b" }), base), false, "the longer list first")
	T.eq(A.sameRow(base, with("words", { "a", "b" })), false, "the shorter list first")
	T.eq(A.sameRow(with("count", nil), with("count", nil)), true)
end

T.section("alignment: which rows become entries")
do
	local function entriesOf(rows, hats)
		local list, pending = A.entries({ rig = rows, scripts = {} }, nil, hats)
		return list, pending
	end
	local list, pending = entriesOf({ { part = "Head", tex = "55", src = "user" } })
	T.eq(#list, 1, "a texture alone is enough")
	T.eq(list[1].textureid, "55")
	T.eq(pending, 0)
	list, pending = entriesOf({ { part = "Head", acc = "Wings", src = "user" } })
	T.eq(#list, 1, "so is an accessory name")
	T.eq(pending, 0)
	list, pending = entriesOf({ { part = "Head", hat = "1", src = "user" } })
	T.eq(#list, 0, "a hat id alone waits for its mesh")
	T.eq(pending, 1)
	local hats = { ["1"] = { mesh = "9", tex = "8" } }
	list = entriesOf({ { part = "Head", hat = "1", src = "user" } }, hats)
	T.eq(list[1].meshid, "9", "a known hat id gives its mesh")
	T.eq(list[1].textureid, "8")
	list = entriesOf({ { part = "Head", hat = "1", mesh = "5", src = "user" } }, hats)
	T.eq(list[1].meshid, "5", "a mesh you gave is not replaced")
	T.eq(list[1].textureid, nil, "and the lookup does not add a texture")
	list = entriesOf({ { part = "Head", hat = "1", tex = "7", src = "user" } }, hats)
	T.eq(list[1].meshid, nil, "a texture you gave is not replaced either")
	T.eq(list[1].textureid, "7")
	list = entriesOf({ { part = "Head", mesh = "1", count = 1, src = "user" } })
	T.eq(list[1].count, nil, "one copy is not written down")
	list = entriesOf({ { part = "Head", mesh = "1", count = 2, src = "user" } })
	T.eq(list[1].count, 2)
	list = entriesOf({ { part = "Head", mesh = "1", src = "user" } })
	T.eq(list[1].count, nil)
end

T.section("alignment: a row is written out in full")
do
	local text = A.rowText({ part = "Head", hat = "1", align = { 1, 2, 3 }, count = 3, words = { "a" } })
	T.ok(string.find(text, "align = {1, 2, 3, 0, 0, 0}", 1, true) ~= nil, "short alignment lists are filled with zeros: " .. text)
	T.ok(string.find(text, "count = 3", 1, true) ~= nil, text)
	T.ok(string.find(text, 'words = {"a"}', 1, true) ~= nil, text)
end

T.section("alignment: the service keeps count of your rows")
do
	local e = newEnv()
	local s = A.new(e.api)
	s:load()
	for i = 1, 2 do
		s:add("rig", nil, { part = "Head", mesh = tostring(100 + i) })
	end
	for i = 1, 3 do
		s:add("scripts", "Test Script", { slot = "gun", mesh = tostring(200 + i) })
	end
	s:add("scripts", "Other Script", { slot = "gun", mesh = "300" })
	local status = s:status()
	T.eq(status.rigRows, 3, "the shipped rows are counted on their own")
	T.eq(status.userRows, 6, "every row of yours is counted, in every script")
	T.eq(#s.userData.scripts["Test Script"], 3, "adding to a script twice keeps both rows")
	T.eq(#s.userData.scripts["Other Script"], 1)
	T.eq(#s:userRows("scripts", "Test Script"), 3)
end

T.section("alignment: script names and the row limit")
do
	local e = newEnv()
	local s = A.new(e.api)
	s:load()
	local long = string.rep("s", 41)
	local ok = s:add("scripts", long, { slot = "gun", mesh = "1" })
	T.eq(ok, true)
	T.eq(s.userData.scripts[string.rep("s", 40)] ~= nil, true, "a script name is cut at forty characters")
	T.eq(s.userData.scripts[long], nil)
	e = newEnv()
	s = A.new(e.api)
	s:load()
	for i = 1, 300 do
		local added = s:add("rig", nil, { part = "Head", mesh = tostring(1000 + i) })
		if not added then
			T.fail("row " .. i .. " should have been added")
			break
		end
	end
	T.eq(#s.userData.rig, 300)
	local added, why = s:add("rig", nil, { part = "Head", mesh = "9999" })
	T.eq(added, false, "the three hundred and first is refused")
	T.eq(why, "you already have 300 rows here")
	T.eq(#s.userData.rig, 300)
	local removed = s:remove("rig", nil, 1)
	T.eq(removed, true)
	added = s:add("rig", nil, { part = "Head", mesh = "9999" })
	T.eq(added, true, "and there is room again after one is removed")
end

T.section("alignment: changing a row to what it already is")
do
	local e = newEnv()
	local s = A.new(e.api)
	s:load()
	s:add("rig", nil, { part = "Head", mesh = "1" })
	s:add("rig", nil, { part = "Torso", mesh = "2" })
	local ok = s:replace("rig", nil, 1, { part = "Head", mesh = "1" })
	T.eq(ok, true, "saving a row without changing it works")
	local changed, why = s:replace("rig", nil, 1, { part = "Torso", mesh = "2" })
	T.eq(changed, false, "but not into a copy of another row")
	T.eq(why, "that row is already there")
	T.eq(s.userData.rig[1].part, "Head")
end

T.section("alignment: what a failed save says")
do
	local e = newEnv()
	local s = A.new(e.api)
	s:load()
	e.failWrite = true
	local added, _, saved, note = s:add("rig", nil, { part = "Head", mesh = "1" })
	T.eq(added, true)
	T.eq(saved, false)
	T.ok(string.sub(note, 1, 15) == "couldn't save: ", "starts with the reason label: " .. tostring(note))
	T.ok(string.find(note, "disk is full", 1, true) ~= nil, "and says why: " .. tostring(note))
end

T.section("alignment: an empty file of yours is not a mistake")
do
	local e = newEnv()
	e.files.user = ""
	local s = A.new(e.api)
	local _, status = s:load()
	T.eq(status.userErr, nil)
	T.eq(status.userRows, 0)
	T.eq(s.broken, nil)
	e = newEnv()
	e.files.user = "   \n"
	s = A.new(e.api)
	_, status = s:load()
	T.eq(type(status.userErr), "string", "but a file with only spaces is not a table")
end

T.section("alignment: loading again forgets old problems and old lookup failures")
do
	local e = newEnv()
	e.text = 'return { rig = { {part = "Tail", mesh = "1"}, {part = "Head", hat = "55"} } }'
	local s = A.new(e.api)
	local _, status = s:load()
	T.eq(#status.problems, 1)
	local found, failedList = s:resolvePending()
	T.eq(found, 0, "no such hat")
	T.eq(#failedList, 1)
	T.eq(s:failedCount(), 1)
	e.text = 'return { rig = { {part = "Head", mesh = "1"} } }'
	_, status = s:load()
	T.eq(#status.problems, 0, "a clean file after a bad one leaves no problems")
	T.eq(s:failedCount(), 0, "lookups that failed are tried again after a reload")
end

T.section("alignment: a cached copy is only used when it can be read")
do
	local e = newEnv()
	e.offline = true
	e.files.cache = 5
	local s = A.new(e.api)
	local ok, status = s:load()
	T.eq(status.source, "none", "a cache that is not text is not a cache")
	e = newEnv()
	e.offline = true
	e.files.cache = BUILTIN_TEXT
	s = A.new(e.api)
	ok, status = s:load()
	T.eq(status.source, "cache")
	T.eq(status.rigRows, 3)
	e = newEnv()
	s = A.new(e.api)
	s:load()
	T.eq(e.files.cache, BUILTIN_TEXT, "the copy that is kept is the text that came from the net")
	T.eq(s.err, nil)
end

T.section("alignment: one gun hat and one sword hat for every script")
do
	T.eq(A.sharedKind("gun"), "gun")
	T.eq(A.sharedKind("gun1"), "gun", "the first gun of a script with two")
	T.eq(A.sharedKind("gun2"), nil, "the second keeps its own hats")
	T.eq(A.sharedKind("sword"), "sword")
	T.eq(A.sharedKind("bullet"), nil)
	T.eq(A.sharedKind(nil), nil)
	local e = newEnv()
	local s = A.new(e.api)
	s:load()
	local ok, count = s:add("shared", "gun", { mesh = "8888", align = { 0, 0, -1, 0, 90, 0 } })
	T.eq(ok, true)
	T.eq(count, 1)
	T.eq(s:userRows("shared", "gun")[1].slot, "gun", "the row knows it is a gun")
	T.eq(s:userCount(), 1)
	local bad, why = s:add("shared", "bullet", { mesh = "1" })
	T.eq(bad, false)
	T.eq(why, "a hat for every script is any weapon, a gun, a sword, a shotgun or a rifle")
	T.eq(s:add("shared", "gun", { mesh = "8888", align = { 0, 0, -1, 0, 90, 0 } }), false, "the same gun twice is refused")
	T.eq(select(2, s:add("shared", "gun", {})), "the row says nothing about a hat")
	T.eq(s:add("shared", "sword", { hat = "4506945409", mesh = "77" }), true)
	T.ok(string.find(e.files.user, "\tshared = {\n\t\tgun = {\n\t\t\t{mesh = \"8888\"", 1, true) ~= nil, "the file has a shared part: " .. e.files.user)
	T.eq(string.find(e.files.user, 'slot = "gun"', 1, true), nil, "without the slot, the list name says it")
	local back = A.clean((A.parse(e.files.user)))
	T.eq(#back.shared.gun, 1, "it reads back")
	T.eq(back.shared.gun[1].slot, "gun")
	T.eq(back.shared.gun[1].mesh, "8888")
	T.eq(#back.shared.sword, 1)
	T.eq(A.serialize(back), e.files.user, "and writes the same text again")
	local info = e.info
	local hit = info.match("The Hotline", "gun", { mesh = "8888" })
	T.ok(hit ~= nil and hit.src == "user", "a gun script finds it")
	T.same(info.offset(hit).cf, { 0, 0, -1, 0, 90, 0 }, "with its alignment")
	T.ok(info.match("Some New Script", "gun", { mesh = "8888" }) ~= nil, "even a script the file has never heard of")
	T.eq(info.match("The Hotline", "bullet", { mesh = "8888" }), nil)
	T.ok(info.match("Neptunian V", "sword", { mesh = "77" }) ~= nil, "a sword script finds the sword hat")
	T.eq(#info.mine("Snake Banisher V3", "gun1"), 1)
	T.eq(#info.mine("Snake Banisher V3", "gun2"), 0)
	s:add("scripts", "The Hotline", { slot = "gun", mesh = "5555" })
	local rows = info.rows("The Hotline", "gun")
	T.eq(rows[1].mesh, "5555", "a script's own hat for that job goes first")
	T.eq(rows[2].mesh, "8888", "then the one for every script")
	T.eq(s:replace("shared", "gun", 1, { mesh = "9999" }), true)
	T.eq(info.match("Addict", "gun", { mesh = "8888" }), nil, "a changed gun hat replaces the old one")
	T.ok(info.match("Addict", "gun", { mesh = "9999" }) ~= nil)
	T.eq(s:remove("shared", "gun", 1), true)
	T.eq(#s:userRows("shared", "gun"), 0)
	T.eq(info.match("Addict", "gun", { mesh = "9999" }), nil, "removed means no script uses it")
	T.eq(s:remove("shared", "gun", 1), false, "removing it again says it is gone")
	local messy = A.clean({ shared = { gun = { { mesh = "1", slot = "bullet" }, "nope" }, laser = { { mesh = "2" } } } })
	T.eq(#messy.shared.gun, 1, "the good row is kept")
	T.eq(messy.shared.gun[1].slot, "gun", "and it is a gun whatever it said")
	T.eq(messy.shared.laser, nil, "only gun, sword, shotgun and rifle exist")
	local _, problems = A.clean({ shared = { laser = {} } })
	T.eq(problems[1], "shared: laser is not gun, sword, shotgun, rifle or any")
	_, problems = A.clean({ shared = 5 })
	T.eq(problems[1], "shared: has to hold gun, sword, shotgun, rifle and any lists")
	_, problems = A.clean({ shared = { gun = 5 } })
	T.eq(problems[1], "shared gun: has to be a list of rows")
	T.eq(#A.clean({}).shared.gun, 0, "an old file without a shared part still loads")
	T.eq(A.merge(nil, nil).shared.sword[1], nil)
end

T.section("alignment: a shotgun hat and a rifle hat for every script")
do
	T.eq(A.sharedKind("shotgun"), "shotgun")
	T.eq(A.sharedKind("rifle"), "rifle")
	T.eq(A.sharedKind("gun"), "gun", "a gun is still a gun")
	local e = newEnv()
	local s = A.new(e.api)
	s:load()
	T.eq(s:add("shared", "shotgun", { mesh = "7001", align = { 0, 0.5, 0, 0, 90, 0 } }), true, "a shotgun hat for every script")
	T.eq(s:add("shared", "rifle", { mesh = "7002" }), true, "a rifle hat for every script")
	T.eq(s:userRows("shared", "shotgun")[1].slot, "shotgun")
	T.eq(s:userRows("shared", "rifle")[1].slot, "rifle")
	T.ok(string.find(e.files.user, "\t\tshotgun = {\n", 1, true) ~= nil, "the file has a shotgun list")
	T.ok(string.find(e.files.user, "\t\trifle = {\n", 1, true) ~= nil, "and a rifle list")
	local back = A.clean((A.parse(e.files.user)))
	T.eq(back.shared.shotgun[1].mesh, "7001", "the shotgun reads back")
	T.eq(back.shared.rifle[1].mesh, "7002", "the rifle reads back")
	T.eq(A.serialize(back), e.files.user, "and writes the same text again")
	local info = e.info
	T.ok(info.match("Master Chief", "shotgun", { mesh = "7001" }) ~= nil, "Master Chief finds the shotgun")
	T.ok(info.match("Master Chief", "rifle", { mesh = "7002" }) ~= nil, "and the rifle")
	T.eq(info.match("Master Chief", "rifle", { mesh = "7001" }), nil, "a shotgun hat is not a rifle")
	T.eq(info.match("Commander V2", "gun", { mesh = "7002" }), nil, "and a rifle hat is not a gun for the other scripts")
	T.same(info.offset(info.match("Master Chief", "shotgun", { mesh = "7001" })).cf, { 0, 0.5, 0, 0, 90, 0 }, "with its alignment")
	T.eq(s:remove("shared", "rifle", 1), true)
	T.eq(info.match("Master Chief", "rifle", { mesh = "7002" }), nil, "removed")
	T.eq(#A.clean({}).shared.shotgun, 0, "an old file without them still loads")
	T.eq(#A.clean({}).shared.rifle, 0)
end
