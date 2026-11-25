local Runner = loadmodule("Testing/mocks/boot_runner.lua")
local Page = loadmodule("Hub/modules/commands_page.lua")

local function all(root, pred)
	local out = {}
	for _, d in ipairs(root:GetDescendants()) do
		if pred(d) then
			out[#out + 1] = d
		end
	end
	return out
end

local function named(root, name)
	return all(root, function(d)
		return d.Name == name
	end)
end

local function first(root, name)
	return named(root, name)[1]
end

local function tap(btn)
	btn.Activated:Fire()
end

local function def(id, name, aliases, desc, extra)
	local d = { id = id, name = name or id, aliases = aliases or {}, desc = desc or "" }
	for k, v in pairs(extra or {}) do
		d[k] = v
	end
	return d
end

T.section("commands_page: words and matching")
T.same(Page.words("  Fly  Fast ", ";"), { "fly", "fast" })
T.same(Page.words(";fly", ";"), { "fly" }, "one leading prefix is dropped")
T.same(Page.words(";;fly", ";"), { ";fly" }, "only one")
T.same(Page.words("!fly", ";"), { "!fly" }, "another symbol is kept")
T.same(Page.words("", ";"), {})
T.same(Page.words(nil, ";"), {})
local fly = { def = def("fly", "Fly", { "f", "soar" }, "Fly where you look", { offNames = { "unfly" } }) }
T.eq(Page.matches(fly, {}), true, "no words matches everything")
T.eq(Page.matches(fly, { "fly" }), true, "name")
T.eq(Page.matches(fly, { "soar" }), true, "alias")
T.eq(Page.matches(fly, { "unfly" }), true, "off name")
T.eq(Page.matches(fly, { "where", "look" }), true, "words from the description, in any order")
T.eq(Page.matches(fly, { "look", "where" }), true)
T.eq(Page.matches(fly, { "fly", "swim" }), false, "every word has to match")
T.eq(Page.matches(fly, { "ZZZ" }), false)
T.eq(Page.matches({ def = def("x", nil, nil, nil) }, { "x" }), true, "a command with no description still matches by id")
T.eq(Page.nameOf({ id = "abc" }), "abc", "no name falls back to the id")

T.section("commands_page: sorting, counts and kinds")
local list = {
	{ def = def("b", "banana"), owner = "hub" },
	{ def = def("a", "Apple"), owner = "hub" },
	{ def = def("c", "cherry"), owner = "hub" },
	{ def = def("a2", "apple"), owner = "zz" },
	{ def = def("a1", "apple"), owner = "hub" },
}
Page.sortEntries(list)
local order = {}
for _, e in ipairs(list) do
	order[#order + 1] = e.def.id
end
T.same(order, { "a", "a1", "a2", "b", "c" }, "case does not matter; same names order by owner then id")
T.eq(Page.countText(142, 142, false), "142 commands")
T.eq(Page.countText(1, 1, false), "1 command")
T.eq(Page.countText(3, 142, true), "3 of 142")
T.eq(Page.countText(0, 142, true), "0 of 142")
T.eq(Page.inputKind({ needsPlayer = true }), "player")
T.eq(Page.inputKind({ usage = "say <text>" }), "text")
T.eq(Page.inputKind({ usage = "fly [speed]" }), nil)
T.eq(Page.inputKind({ usage = "reset" }), nil)
T.eq(Page.inputKind({}), nil)
T.eq(Page.usageText({ id = "fly", usage = "fly [speed]" }, ";"), ";fly [speed]")
T.eq(Page.usageText({ id = "fly" }, "!"), "!fly", "no usage falls back to the id")

T.section("commands_page: the lines under a command")
local lines = Page.details({ def = def("fling", "Fling", { "yeet" }, "x", { usage = "fling <player>", kind = "action" }), owner = "hub" }, ";")
T.eq(lines[1].text, "Usage: ;fling <player>")
T.eq(lines[2].text, "Also: yeet")
T.eq(#lines, 2)
lines = Page.details({ def = def("noclip", "Noclip", {}, "x", { kind = "toggle", offNames = { "clip", "unnoclip" } }), owner = "hub" }, ";")
T.eq(lines[2].text, "Turn off: clip, unnoclip", "toggles list their off names")
lines = Page.details({ def = def("dance", "Dance", {}, "x", { kind = "action" }), owner = "studio", label = "Studio Dummy" }, ";", { hubHas = function(w) return w == "dance" end })
T.eq(lines[2].text, "From Studio Dummy", "the owner line")
T.eq(lines[3].text, "Also in the hub: dance", "and the shadow note")
lines = Page.details({ def = def("tp", "Tp", {}, "x", { kind = "action" }), owner = "hub", shadowedBy = "studio" }, ";", { ownerLabel = function(id) return "Studio Dummy" end })
T.eq(lines[2].text, "Typing it runs Studio Dummy instead", "a hub command another owner took over")
lines = Page.details({ def = def("tp", "Tp", {}, "x", { kind = "action" }), owner = "hub" }, ";")
T.eq(#lines, 1, "a plain hub action has just the usage")

T.section("commands_page: collecting and the signature")
local fakeCmd = { list = { def("zeta", "Zeta"), def("alpha", "Alpha"), def("hid", "Hid", nil, nil, { hidden = true }) } }
local got = Page.collect(fakeCmd, nil)
T.eq(#got, 2, "hidden commands are left out")
T.eq(got[1].def.id, "alpha", "sorted")
T.eq(got[1].owner, "hub")
T.eq(got[1].key, "hub:alpha")
local fakeDispatch = {
	list = function()
		return {
			{ def = def("one", "One"), owner = "hub", label = "Atsuko Hub" },
			{ def = def("two", "Two"), owner = "dummy", label = "Studio Dummy", shadowedBy = "hub" },
			{ def = nil, owner = "bad" },
			"junk",
			{ def = def("three", "Three", nil, nil, { hidden = true }), owner = "hub" },
		}
	end,
}
got = Page.collect(fakeCmd, fakeDispatch)
T.eq(#got, 2, "the dispatcher list wins and bad rows are skipped")
T.eq(got[2].key, "dummy:two")
T.eq(got[2].shadowedBy, "hub")
T.eq(Page.signature(got), "hub:one|dummy:two")
local boom = { list = function() error("boom") end }
T.eq(#Page.collect(fakeCmd, boom), 2, "a broken dispatcher falls back to the hub list")

local env = Runner.boot({ seconds = 6 })
local hub, core = env.hub, env.core
local Cmd = core.ctx.Cmd
local baseCount = 0
for _, d in ipairs(Cmd.list) do
	if not d.hidden then
		baseCount += 1
	end
end

T.section("commands_page: the registry check")
T.eq(#Cmd.check(), 0, "the hub's own commands have no clashes")
T.eq(Cmd.by.fly.id, "fly")

hub.Panel.nav("commands")
env.run(2)
local mod = core.mods.commands_page and core.mods.commands_page.mod
T.ok(mod ~= nil, "the module loaded")
local st = mod.state()

T.section("commands_page: the list")
T.eq(hub.Pages.commands.tabBar, nil, "no category tabs")
T.eq(hub.Pages.commands.tabButtons, nil, "and no tab buttons")
T.eq(st.built, true, "built")
T.eq(#st.rows, baseCount, "one row for every command")
T.eq(st.count.Text, baseCount .. " commands", "the count")
local prevName = ""
local sorted = true
for _, row in ipairs(st.rows) do
	local n = string.lower(row.name.Text)
	if n < prevName then
		sorted = false
	end
	prevName = n
end
T.eq(sorted, true, "alphabetical from top to bottom")
T.eq(#all(st.list, function(d) return d:IsA("ImageLabel") or d:IsA("ImageButton") end), 0, "no icons anywhere in the list")
T.eq(#named(st.list, "IconBox"), 0, "no icon boxes")
local flyRow = st.byId.fly
T.ok(flyRow ~= nil, "the fly row")
T.eq(flyRow.name.Text, "Fly")
T.eq(flyRow.sub.Text, ";fly [speed]", "usage with the prefix")
T.ok(first(flyRow.head, "Switch") ~= nil, "toggles have a switch")
T.eq(first(flyRow.head, "Run"), nil, "and no Run button")
local refreshRow = st.byId.refresh
T.ok(first(refreshRow.head, "Run") ~= nil, "actions have a Run button")
T.eq(first(refreshRow.head, "Switch"), nil)
T.eq(st.empty.Visible, false, "no empty text")
T.eq(#env.errors, 0, "no errors so far")

T.section("commands_page: search")
local function search(text)
	st.box.Text = text
	env.run(0.4)
end
local function visible()
	local out = {}
	for _, row in ipairs(st.rows) do
		if row.frame.Visible then
			out[#out + 1] = row
		end
	end
	return out
end
search("fly")
local v = visible()
T.ok(#v >= 4, "fly finds several")
T.eq(st.count.Text, #v .. " of " .. baseCount, "the count follows")
local allMatch = true
for _, row in ipairs(v) do
	if not Page.matches(row.entry, { "fly" }) then
		allMatch = false
	end
end
T.eq(allMatch, true, "every visible row matches")
search(";fly")
T.eq(#visible(), #v, "a leading prefix is ignored")
search("FLY")
T.eq(#visible(), #v, "case does not matter")
local aliasOf = Cmd.by.noclip.aliases[1]
if aliasOf then
	search(aliasOf)
	local found = false
	for _, row in ipairs(visible()) do
		if row.def.id == "noclip" then
			found = true
		end
	end
	T.eq(found, true, "an alias finds its command")
end
search("zzzzqq")
T.eq(#visible(), 0, "nothing matches")
T.eq(st.empty.Visible, true, "the empty text shows")
T.eq(st.empty.Text, "Nothing matches")
T.eq(st.count.Text, "0 of " .. baseCount)
search("")
T.eq(#visible(), baseCount, "clearing the box brings everything back")
T.eq(st.count.Text, baseCount .. " commands")
T.eq(st.empty.Visible, false)

T.section("commands_page: the On chip")
Cmd.set("noclip", true, nil, true)
env.run(0.3)
tap(st.chip)
env.run(0.2)
v = visible()
T.eq(#v, 1, "only what is on")
T.eq(v[1].def.id, "noclip")
T.eq(st.count.Text, "1 of " .. baseCount)
Cmd.set("noclip", false, nil, true)
env.run(0.3)
T.eq(#visible(), 0, "turning it off removes it from the On list")
T.eq(st.empty.Text, "Nothing is on right now")
tap(st.chip)
env.run(0.2)
T.eq(#visible(), baseCount, "the chip turns the filter off again")

T.section("commands_page: category chips")
do
	T.ok(st.catChips.Movement ~= nil, "a chip for each kind of command")
	T.ok(st.catChips.World ~= nil and st.catChips.Camera ~= nil, "pack commands sort into their own kinds")
	local total = 0
	for _, item in ipairs(Page.categories(st.entries)) do
		total += item.count
	end
	T.eq(total, baseCount, "every command is in one kind")
	tap(st.catChips.Movement.btn)
	env.run(0.2)
	v = visible()
	T.ok(#v > 0, "tapping Movement shows only movement")
	local only = true
	for _, row in ipairs(v) do
		if Page.catOf(row.entry) ~= "Movement" then
			only = false
		end
	end
	T.eq(only, true)
	T.eq(st.count.Text, #v .. " of " .. baseCount)
	tap(st.catChips.Movement.btn)
	env.run(0.2)
	T.eq(#visible(), baseCount, "tapping it again shows everything")
	tap(st.catChips.World.btn)
	env.run(0.2)
	tap(st.allChip.btn)
	env.run(0.2)
	T.eq(#visible(), baseCount, "All clears the kind")
	T.ok(string.find(st.allChip.text.Text, tostring(baseCount), 1, true) ~= nil, "All shows the total")
	T.eq(Page.catOf({ def = { id = "x" }, owner = "FakeVR", label = "FakeVR" }), "FakeVR", "commands from a script sit under its name")
	T.eq(Page.catOf({ def = { id = "x" }, owner = "hub" }), "Other")
	T.eq(Page.colorKey("Movement"), "green")
	T.ok(Page.colorKey("Something new") ~= nil, "an unknown kind still gets a color")
end

T.section("commands_page: the command line")
do
	T.eq(st.prefixLabel.Text, ";", "the prefix sits in front of the box")
	st.box.Text = "fly"
	env.run(0.3)
	T.eq(st.enterText.Text, "Run", "a command you can run lights up the Run key")
	st.box.Text = "flyy"
	env.run(0.3)
	T.eq(st.enterText.Text, "Enter", "a search doesn't")
	st.box.Text = ""
	env.run(0.4)
end

T.section("commands_page: a row opens in place")
local function bodyOf(row)
	return row.body
end
tap(flyRow.head)
env.run(1)
T.eq(flyRow.open, true, "open")
T.eq(bodyOf(flyRow).Visible, true, "the body shows")
T.eq(bodyOf(flyRow).AutomaticSize, Enum.AutomaticSize.Y, "and sizes itself once the animation is done")
local texts = {}
for _, d in ipairs(flyRow.inner:GetDescendants()) do
	if d:IsA("TextLabel") then
		texts[#texts + 1] = d.Text
	end
end
local joined = table.concat(texts, "\n")
T.ok(string.find(joined, Cmd.by.fly.desc, 1, true) ~= nil, "the description")
T.ok(string.find(joined, "Usage: ;fly [speed]", 1, true) ~= nil, "the usage line")
T.ok(string.find(joined, "Turn off: ", 1, true) ~= nil, "the off names")
T.eq(st.openRow, flyRow)

local noclipRow = st.byId.noclip
tap(noclipRow.head)
env.run(1)
T.eq(noclipRow.open, true, "a second row opens")
T.eq(#all(noclipRow.inner, function(d) return d:IsA("ImageLabel") end), 0, "no icons inside an open row")
T.eq(flyRow.open, false, "and the first one closes (accordion)")
T.eq(flyRow.body.Visible, false)
T.eq(flyRow.inner, nil, "its content is gone")
T.eq(st.openRow, noclipRow)
tap(noclipRow.head)
env.run(1)
T.eq(noclipRow.open, false, "tapping again closes it")
T.eq(st.openRow, nil)

T.section("commands_page: the switch and Run do not open the row")
tap(first(noclipRow.head, "Switch"))
env.run(0.5)
T.eq(Cmd.isOn("noclip"), true, "the switch turns it on")
T.eq(noclipRow.open, false, "without opening the row")
T.eq(noclipRow.sub.TextColor3 ~= nil, true)
tap(first(noclipRow.head, "Switch"))
env.run(0.5)
T.eq(Cmd.isOn("noclip"), false, "and off again")

local ran, got1, sawAlive, fired, closed = 0, nil, nil, 0, 0
Cmd.add({
	id = "zzaction", name = "Zz action", icon = "command", cat = "Utility", kind = "action", usage = "zzaction", desc = "A test action.",
	run = function()
		ran += 1
	end,
})
Cmd.add({
	id = "zzplayer", name = "Zz player", icon = "command", cat = "Utility", kind = "action", usage = "zzplayer <player>", desc = "A test with a player.", needsPlayer = true, selectors = true,
	run = function(arg)
		got1 = arg
	end,
})
Cmd.add({
	id = "zztext", name = "Zz text", icon = "command", cat = "Utility", kind = "action", usage = "zztext <words>", desc = "A test with words.",
	run = function(arg)
		got1 = "text:" .. tostring(arg)
	end,
})
Cmd.add({
	id = "zzopts", name = "Zz options", icon = "command", cat = "Utility", kind = "toggle", usage = "zzopts", desc = "A test with options.",
	start = function()
		return true
	end,
	stop = function() end,
	opts = function(w, body, order)
		sawAlive = w.alive
		w:on("zzevent", function()
			fired += 1
		end)
		local note = Instance.new("TextLabel")
		note.Name = "OptsMarker"
		note.Text = "from opts"
		note.LayoutOrder = order
		note.Parent = body
	end,
	onWinClose = function()
		closed += 1
	end,
})
Cmd.add({
	id = "zzneeds", name = "Zz needs", icon = "command", cat = "Utility", kind = "toggle", usage = "zzneeds", desc = "Needs something your executor lacks.",
	requires = { funcs = { "zzMissingFunction" } },
	start = function()
		ran += 100
		return true
	end,
	stop = function() end,
})
Cmd.add({
	id = "zzneedsrun", name = "Zz needs run", icon = "command", cat = "Utility", kind = "action", usage = "zzneedsrun", desc = "Needs something too.",
	requires = { funcs = { "zzMissingFunction" } },
	run = function()
		ran += 1000
	end,
})
core.Dispatch:register("studiodummy", "script", { def("zzforeign", "Zz foreign", { "zzf" }, "From another script.", { kind = "action", run = function() ran += 10 end }) }, { label = "Studio Dummy" })
env.run(1.2)

T.section("commands_page: new commands appear")
T.eq(#st.entries, baseCount + 7, "the list grew by what was added (six hub commands and one from another script)")
T.eq(#st.rows, baseCount + 7)
T.eq(st.count.Text, (baseCount + 7) .. " commands")
local actionRow, playerRow, textRow, optsRow, needsRow, needsRunRow = st.byId.zzaction, st.byId.zzplayer, st.byId.zztext, st.byId.zzopts, st.byId.zzneeds, st.byId.zzneedsrun
local foreignRow = st.byKey["studiodummy:zzforeign"]
T.ok(actionRow and playerRow and textRow and optsRow and needsRow and needsRunRow and foreignRow, "all rows exist")

T.section("commands_page: Run, Pick and Type")
tap(first(actionRow.head, "Run"))
env.run(0.3)
T.eq(ran, 1, "Run runs it")
T.eq(actionRow.open, false, "without opening")
T.eq(first(first(playerRow.head, "Run"), "Text").Text, "Pick", "a player command says Pick")
T.eq(first(first(textRow.head, "Run"), "Text").Text, "Type", "a command with words says Type")
T.eq(first(first(actionRow.head, "Run"), "Text").Text, "Run")
tap(first(playerRow.head, "Run"))
env.run(1)
T.eq(playerRow.open, true, "Pick opens the row")
T.eq(got1, nil, "and runs nothing yet")
local box = first(playerRow.inner, "Box")
T.ok(box ~= nil, "there is a player box")
box.Text = "bob"
box.FocusLost:Fire(true)
env.run(0.3)
T.eq(got1, "bob", "Enter runs it with what was typed")
got1 = nil
box.Text = "all -me"
box.FocusLost:Fire(false)
env.run(0.3)
T.eq(got1, nil, "leaving the box without Enter does not run it")
local goButtons = all(playerRow.inner, function(d)
	return d:IsA("TextButton") and d.Name == "B1"
end)
T.ok(#goButtons >= 1, "there is a Go button")
local chips = all(playerRow.inner, function(d)
	return d:IsA("TextButton") and d.Name:match("^B%d$") ~= nil
end)
T.eq(#chips, 5, "four selector chips and Go")
tap(chips[3])
env.run(0.2)
T.eq(first(playerRow.inner, "Box").Text, "random", "a chip fills the box")
tap(chips[#chips])
env.run(0.3)
T.eq(got1, "random", "Go runs what is in the box")
tap(playerRow.head)
env.run(1)
tap(first(textRow.head, "Run"))
env.run(1)
box = first(textRow.inner, "Box")
box.Text = "hello there"
box.FocusLost:Fire(true)
env.run(0.3)
T.eq(got1, "text:hello there", "words go through as typed")
T.eq(#all(textRow.inner, function(d) return d:IsA("TextButton") and d.Name:match("^B%d$") ~= nil end), 1, "only Go, no selector chips")
tap(textRow.head)
env.run(1)

T.section("commands_page: options inside the row")
tap(optsRow.head)
env.run(1)
T.eq(sawAlive, true, "opts gets a live window object")
T.ok(first(optsRow.inner, "OptsMarker") ~= nil, "its controls land inside the row")
hub.Bus.fire("zzevent")
T.eq(fired, 1, "w:on works")
tap(optsRow.head)
env.run(1)
T.eq(closed, 1, "onWinClose runs when the row closes")
hub.Bus.fire("zzevent")
T.eq(fired, 1, "and the listener is gone")
tap(optsRow.head)
env.run(1)
T.eq(sawAlive, true)
hub.Bus.fire("zzevent")
T.eq(fired, 2, "opening it again listens again")
tap(noclipRow.head)
env.run(1)
T.eq(optsRow.open, false, "opening another row closes it")
hub.Bus.fire("zzevent")
T.eq(fired, 2, "so nothing leaks")
T.eq(closed, 2)
tap(noclipRow.head)
env.run(1)

T.section("commands_page: rows the executor cannot run")
T.ok(first(needsRow.head, "Unavailable") ~= nil, "the row says Unavailable")
T.eq(first(needsRow.head, "Switch"), nil, "and has no switch")
T.eq(first(needsRunRow.head, "Run"), nil, "or Run button")
tap(needsRow.head)
env.run(1)
local seen = false
for _, d in ipairs(needsRow.inner:GetDescendants()) do
	if d:IsA("TextLabel") and d.Text == "Your executor has no zzMissingFunction" then
		seen = true
	end
end
T.eq(seen, true, "the reason is in the expanded text")
tap(needsRow.head)
env.run(1)
T.eq(Cmd.set("zzneeds", true), false, "turning it on is declined")
T.eq(Cmd.isOn("zzneeds"), false)
T.eq(Cmd.run("zzneedsrun"), false, "so is running it")
T.eq(ran, 1, "and nothing ran")
T.eq(Cmd.reason(Cmd.by.fly), nil, "a normal command has no reason")
T.eq(Cmd.reason({ requires = { check = function() return "Sit in a seat first" end } }), "Sit in a seat first", "custom checks give reasons")
T.eq(Cmd.reason({ requires = { check = function() error("x") end } }), nil, "a broken check never errors")
T.eq(Cmd.has("print"), true, "global functions count")
T.eq(Cmd.has("zzMissingFunction"), false)

T.section("commands_page: commands from other scripts")
tap(foreignRow.head)
env.run(1)
seen = false
for _, d in ipairs(foreignRow.inner:GetDescendants()) do
	if d:IsA("TextLabel") and d.Text == "From Studio Dummy" then
		seen = true
	end
end
T.eq(seen, true, "the owner line")
tap(foreignRow.head)
env.run(1)
tap(first(foreignRow.head, "Run"))
env.run(0.3)
T.eq(ran, 11, "Run goes through the dispatcher")

T.section("commands_page: duplicates are refused")
local before = #Cmd.list
T.eq(Cmd.add({ id = "fly", name = "Another fly", kind = "action", usage = "fly", desc = "x", run = function() end }), false, "an existing id is not taken over")
T.eq(#Cmd.list, before)
T.eq(Cmd.by.fly.name, "Fly")
T.eq(Cmd.add({ id = "zzunique", name = "Zz unique", kind = "action", usage = "zzunique", desc = "x", aliases = { "zzu", "noclip" }, offNames = { "zzoff", "fly" }, run = function() end }), true, "a new id with two bad words is still added")
T.eq(Cmd.by.zzunique.id, "zzunique")
T.same(Cmd.by.zzunique.aliases, { "zzu" }, "the clashing alias is skipped")
T.same(Cmd.by.zzunique.offNames, { "zzoff" }, "and the clashing off name")
T.eq(Cmd.by.noclip.id, "noclip", "the original still owns the word")
T.eq(Cmd.by.fly.id, "fly")
T.eq(Cmd.off.fly, nil)
T.eq(#Cmd.check(), 3, "all three are reported")
T.eq(Cmd.check()[1].kind, "id")
T.ok(string.find(Cmd.check()[1].text, "already used by fly", 1, true) ~= nil, "with both owners named")
Cmd.strict = true
local okStrict, errStrict = pcall(Cmd.add, { id = "zzstrict", name = "x", kind = "action", usage = "x", desc = "x", aliases = { "fly" }, run = function() end })
Cmd.strict = false
T.eq(okStrict, false, "strict mode throws")
T.ok(string.find(tostring(errStrict), "command conflict", 1, true) ~= nil)
T.eq(Cmd.add("nope"), false, "a bad definition is refused")
T.eq(Cmd.add({ id = "" }), false)
T.eq(Cmd.add({}), false)
local up = Cmd.add({ id = "ZZUpper", name = "Zz upper", kind = "action", usage = "zzupper", desc = "x", aliases = { "ZZUP" }, run = function() end })
T.eq(up, true)
T.ok(Cmd.by.zzupper ~= nil and Cmd.by.zzup ~= nil, "ids and aliases are lower-cased")

T.section("commands_page: the prefix is shown everywhere")
flyRow, noclipRow = st.byId.fly, st.byId.noclip
hub.S.prefix = "!"
hub.Bus.fire("prefix")
env.run(0.4)
T.eq(flyRow.sub.Text, "!fly [speed]", "the row follows the prefix")
tap(flyRow.head)
env.run(1)
seen = false
for _, d in ipairs(flyRow.inner:GetDescendants()) do
	if d:IsA("TextLabel") and d.Text == "Usage: !fly [speed]" then
		seen = true
	end
end
T.eq(seen, true, "and so does the open one")
tap(flyRow.head)
env.run(1)
hub.S.prefix = ";"
hub.Bus.fire("prefix")
env.run(0.4)
T.eq(flyRow.sub.Text, ";fly [speed]")

T.section("commands_page: a toggle shows its state in the row")
Cmd.set("fly", true, nil, true)
env.run(0.4)
T.ok(string.find(flyRow.sub.Text, "On", 1, true) ~= nil, "the usage line becomes the state")
tap(flyRow.head)
env.run(1)
T.eq(flyRow.stateLabel.Visible, true, "the open row shows the state too")
Cmd.set("fly", false, nil, true)
env.run(0.4)
T.eq(flyRow.stateLabel.Visible, false, "and hides it again")
T.eq(flyRow.sub.Text, ";fly [speed]")
tap(flyRow.head)
env.run(1)

T.section("commands_page: the search box runs a command on Enter")
local ranBox = 0
Cmd.add({ id = "zzbox", name = "Zz box", kind = "action", usage = "zzbox", desc = "x", run = function() ranBox += 1 end })
env.run(1.2)
st.box.Text = "zzbox"
st.box.FocusLost:Fire(true)
env.run(0.6)
T.eq(ranBox, 1, "a known command runs")
T.eq(st.box.Text, "", "and the box clears")
st.box.Text = "justsearching"
st.box.FocusLost:Fire(true)
env.run(0.6)
T.eq(st.box.Text, "justsearching", "other text is only a search: no toast, nothing cleared")
st.box.Text = ""
env.run(0.4)

T.section("commands_page: no errors")
T.eq(#env.errors, 0, "no hub errors: " .. table.concat(env.errors, " | "))
local errs = {}
for _, item in ipairs(hub.Log.items) do
	if item.kind == "error" then
		errs[#errs + 1] = item.src .. ": " .. item.msg
	end
end
T.eq(#errs, 0, "nothing in the log: " .. table.concat(errs, " | "))

T.section("commands_page: the list did not load")
do
	local e2 = Runner.boot({
		seconds = 6,
		files = { ["Atsuko Hub/Hub/modules/commands_page.lua"] = "this is not lua code, but it is longer than forty bytes to pass the size check" },
	})
	e2.hub.Panel.nav("commands")
	e2.run(2)
	local frame = e2.hub.Pages.commands.frame
	T.ok(first(frame, "Failed") ~= nil, "a message shows")
	T.ok(first(frame, "Retry") ~= nil, "with a way to try again")
	T.eq(#named(frame, "List"), 0, "and no half-built list")
	T.eq(e2.hub.Pages.commands.head ~= nil, true)
	e2.hub.Panel.nav("home")
	e2.run(1)
	e2.hub.Panel.nav("commands")
	e2.run(1)
	T.eq(#named(frame, "Failed"), 1, "coming back does not stack messages")
end

T.section("commands_page: the page is gone when the hub closes")
do
	Page.destroy()
	T.eq(Page.state().alive, false)
	Page.show()
	Page.hide()
	T.eq(#Page.state().rows, 0)
end
