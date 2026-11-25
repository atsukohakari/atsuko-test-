local Layout = loadmodule("Hub/modules/home_layout.lua")

local function ids(list)
	return table.concat(list, ",")
end

local function sampleCards()
	return {
		{ id = "profile", col = "A", hidden = false },
		{ id = "nowplaying", col = "A", hidden = false },
		{ id = "quick", col = "A", hidden = false },
		{ id = "actions", col = "A", hidden = false },
		{ id = "recent", col = "A", hidden = false },
		{ id = "game", col = "B", hidden = false },
		{ id = "server", col = "B", hidden = false },
		{ id = "friends", col = "B", hidden = false },
		{ id = "w1", col = "A", hidden = false },
		{ id = "w2", col = "B", hidden = true },
		{ id = "w3", col = "B", hidden = false },
	}
end

T.section("home_layout: density tables")
T.eq(Layout.densityName("compact"), "compact")
T.eq(Layout.densityName("comfortable"), "comfortable")
T.eq(Layout.densityName(nil), "comfortable")
T.eq(Layout.densityName(12), "comfortable")
T.eq(Layout.densityName("Compact"), "comfortable")
T.eq(Layout.density("compact").name, "compact")
T.eq(Layout.density("nonsense").name, "comfortable")
local comfy, tight = Layout.DENSITY.comfortable, Layout.DENSITY.compact
for k, v in pairs(comfy) do
	if type(v) == "number" then
		T.ok(type(tight[k]) == "number", "compact has " .. k)
		T.ok(v > 0 and tight[k] > 0, "positive " .. k)
		T.ok(tight[k] <= v, "compact is not bigger for " .. k)
	end
end
for k in pairs(tight) do
	T.ok(comfy[k] ~= nil, "comfortable has " .. k)
end
T.ok(comfy.row >= 44, "comfortable rows are touch sized")
T.ok(comfy.pill >= 36, "comfortable pills are touch sized")
T.ok(tight.title < comfy.title)
T.ok(tight.pad < comfy.pad)

T.section("home_layout: stage widths")
for w = 280, 609 do
	local a, b = Layout.stageWidths(w, "original")
	T.eq(a, w, "narrow a " .. w)
	T.eq(b, 0, "narrow b " .. w)
end
local lastA, lastB = 0, 0
for w = 610, 1920 do
	local a, b = Layout.stageWidths(w, "original")
	T.ok(a >= 300 and a <= 390, "left in range " .. w)
	T.ok(b >= 270 and b <= 340, "right in range " .. w)
	T.ok(a + b <= w, "both fit " .. w)
	T.ok(a >= lastA and b >= lastB, "monotonic " .. w)
	lastA, lastB = a, b
	local a2, b2 = Layout.stageWidths(w, "window")
	T.ok(a2 >= 300 and a2 <= 400, "window left " .. w)
	T.ok(b2 >= 270 and b2 <= 340, "window right " .. w)
	T.ok(a2 + b2 <= w, "window both fit " .. w)
end
T.same({ Layout.stageWidths(1000, "original") }, { 390, 330 })
T.same({ Layout.stageWidths(1920, "original") }, { 390, 340 })
T.same({ Layout.stageWidths(610, "original") }, { 300, 270 })
T.same({ Layout.stageWidths(1000, "window") }, { 400, 340 })

T.section("home_layout: plan is a partition for every width")
local cards = sampleCards()
for w = 280, 1920, 5 do
	local p = Layout.plan(w, cards)
	T.eq(p.narrow, w < 610, "narrow flag " .. w)
	T.eq(#p.columns, 2, "two column slots " .. w)
	T.eq(#p.order, 10, "ten visible cards " .. w)
	T.same(p.hidden, { "w2" }, "hidden list " .. w)
	local seen, total = {}, 0
	for ci = 1, 2 do
		for _, id in ipairs(p.columns[ci]) do
			T.ok(not seen[id], "once " .. id .. " " .. w)
			seen[id] = ci
			total = total + 1
		end
	end
	T.eq(total, 10, "all placed " .. w)
	T.ok(seen.w2 == nil, "hidden never placed " .. w)
	if p.narrow then
		T.eq(#p.columns[2], 0, "narrow has one list " .. w)
		T.eq(ids(p.columns[1]), "profile,nowplaying,quick,actions,recent,game,server,friends,w1,w3", "narrow keeps config order " .. w)
		T.eq(p.widths.a, w, "narrow width " .. w)
		T.eq(p.widths.b, 0, "narrow side width " .. w)
		T.eq(p.side, false, "narrow has no side " .. w)
	else
		T.eq(ids(p.columns[1]), "profile,nowplaying,quick,actions,recent,w1", "left column " .. w)
		T.eq(ids(p.columns[2]), "game,server,friends,w3", "right column " .. w)
		T.ok(p.widths.a >= 300 and p.widths.b >= 270, "wide widths " .. w)
		T.eq(p.side, true, "side shown " .. w)
	end
	T.eq(ids(p.order), ids(Layout.plan(w, cards).order), "deterministic " .. w)
end

T.section("home_layout: plan edge cases")
T.eq(Layout.plan(609, cards).narrow, true)
T.eq(Layout.plan(610, cards).narrow, false)
T.eq(Layout.plan(900, cards, { narrow = true }).narrow, true)
T.eq(#Layout.plan(900, cards, { narrow = true }).columns[2], 0)
T.eq(Layout.plan(300, cards, { narrow = false }).narrow, false)
local empty = Layout.plan(1000, {})
T.eq(#empty.order, 0)
T.eq(empty.side, false)
local onlyA = {}
for i = 1, 5 do
	onlyA[i] = { id = "a" .. i, col = "A", hidden = false }
end
local pa = Layout.plan(1000, onlyA)
T.eq(pa.side, false)
T.eq(#pa.columns[2], 0)
T.eq(#pa.columns[1], 5)
local allHidden = {}
for i = 1, 4 do
	allHidden[i] = { id = "h" .. i, col = i % 2 == 0 and "B" or "A", hidden = true }
end
local ph = Layout.plan(1000, allHidden)
T.eq(#ph.order, 0)
T.eq(#ph.hidden, 4)
local one = Layout.plan(700, { { id = "x", col = "B", hidden = false } })
T.eq(one.side, true)
T.eq(ids(one.columns[2]), "x")
local forced = Layout.plan(1000, cards, { leftW = 333, rightW = 281 })
T.eq(forced.widths.a, 333)
T.eq(forced.widths.b, 281)
local win = Layout.plan(1000, cards, { mode = "window" })
T.same({ win.widths.a, win.widths.b }, { 400, 340 })

T.section("home_layout: metrics fit the column")
for _, d in ipairs({ comfy, tight }) do
	local lastTiles, lastChips, lastFaces = 0, 0, 0
	for w = 250, 1920, 10 do
		local m = Layout.metrics(w, d)
		T.ok(m.inner >= 120, "inner " .. w)
		T.ok(m.tileCols == 2 or m.tileCols == 4, "tile cols " .. w)
		T.ok(m.chipCols == 1 or m.chipCols == 2, "chip cols " .. w)
		T.ok(m.faces >= 1 and m.faces <= 8, "faces " .. w)
		T.ok(m.tileCols >= lastTiles and m.chipCols >= lastChips and m.faces >= lastFaces, "monotonic " .. w)
		lastTiles, lastChips, lastFaces = m.tileCols, m.chipCols, m.faces
		local cw = Layout.cellWidth(m.inner, m.tileCols, 8)
		T.ok(cw * m.tileCols + 8 * (m.tileCols - 1) <= m.inner, "tiles fit " .. w)
		T.ok(cw >= 60, "tile wide enough " .. w)
		local cc = Layout.cellWidth(m.inner, m.chipCols, 6)
		T.ok(cc * m.chipCols + 6 * (m.chipCols - 1) <= m.inner, "chips fit " .. w)
		T.ok(cc >= 90, "chip wide enough " .. w)
		local lastFace = Layout.faceOffset(m.faces, d) + d.face
		T.ok(lastFace <= m.inner or m.faces == 1, "faces fit " .. w)
	end
end
T.eq(Layout.metrics(480, comfy).tileCols, 4)
T.eq(Layout.metrics(300, comfy).tileCols, 2)
T.eq(Layout.metrics(240, comfy).chipCols, 1)
T.eq(Layout.metrics(300, comfy).chipCols, 2)
T.eq(Layout.cellWidth(100, 0, 8), 100)

T.section("home_layout: saved config stays readable")
local defs = { profile = { col = "A" }, game = { col = "B" }, recent = { col = "A" }, friends = { col = "B" } }
local order = { "profile", "recent", "game", "friends" }
local kinds = { picture = true, note = true, clock = true }
local fresh = Layout.normalizeConfig({}, defs, order, kinds)
T.eq(#fresh, 4)
T.eq(fresh[3].id, "game")
T.eq(fresh[3].col, "B")
T.eq(fresh[3].hidden, false)
T.eq(#Layout.normalizeConfig(nil, defs, order, kinds), 4)
T.eq(#Layout.normalizeConfig("junk", defs, order, kinds), 4)
local saved = {
	{ id = "game", col = "A", hidden = true },
	{ id = "w1", kind = "note", col = "B", data = { title = "hi" } },
	{ id = "w2", kind = "note", col = "B" },
	{ id = "w3", kind = "weird", col = "A", data = {} },
	{ id = "game", col = "B" },
	{ id = 5, col = "A" },
	"text",
	{ id = "w4", kind = "clock", col = "Z", data = {} },
	{ id = "gone", col = "A" },
	{ id = "recent", col = "B", hidden = false },
}
local out = Layout.normalizeConfig(saved, defs, order, kinds)
local got = {}
for i, e in ipairs(out) do
	got[i] = e.id .. ":" .. e.col .. ":" .. tostring(e.hidden)
end
T.eq(table.concat(got, ","), "game:A:true,w1:B:nil,w4:A:nil,recent:B:false,profile:A:false,friends:B:false")
T.eq(saved[1].hidden, true)
local again = Layout.normalizeConfig(out, defs, order, kinds)
T.eq(#again, #out)
local colSet = {}
for _, e in ipairs(again) do
	colSet[e.col] = true
end
T.ok(colSet.A and colSet.B)

T.section("home_layout: collapsed cards")
T.same(Layout.sanitizeCollapsed(nil), {})
T.same(Layout.sanitizeCollapsed("x"), {})
T.same(Layout.sanitizeCollapsed({ recent = true, game = false, [3] = true, friends = "yes" }), { recent = true })
local big = {}
for i = 1, 200 do
	big["c" .. i] = true
end
local n = 0
for _ in pairs(Layout.sanitizeCollapsed(big)) do
	n = n + 1
end
T.eq(n, 60)

T.section("home_layout: greeting")
T.eq(Layout.greeting(0), "Still up? Don't stay up too late")
T.eq(Layout.greeting(4), "Still up? Don't stay up too late")
T.eq(Layout.greeting(5), "Good morning, have a lovely day")
T.eq(Layout.greeting(11), "Good morning, have a lovely day")
T.eq(Layout.greeting(12), "Good afternoon, what are we playing?")
T.eq(Layout.greeting(17), "Good afternoon, what are we playing?")
T.eq(Layout.greeting(18), "Good evening, enjoy your games")
T.eq(Layout.greeting(21), "Good evening, enjoy your games")
T.eq(Layout.greeting(22), "It's getting late, play safe")
T.eq(Layout.greeting(23), "It's getting late, play safe")
T.eq(Layout.greeting(nil), "Good afternoon, what are we playing?")
T.eq(Layout.greeting("7"), "Good morning, have a lovely day")

T.section("home_layout: live text")
T.eq(Layout.uptimeText(0), "0s")
T.eq(Layout.uptimeText(59), "59s")
T.eq(Layout.uptimeText(59.9), "59s")
T.eq(Layout.uptimeText(60), "1m 0s")
T.eq(Layout.uptimeText(3599), "59m 59s")
T.eq(Layout.uptimeText(3600), "1h 0m 0s")
T.eq(Layout.uptimeText(3661), "1h 1m 1s", "hours, minutes and seconds")
T.eq(Layout.uptimeText(90061), "25h 1m 1s")
T.eq(Layout.uptimeText(-5), "0s")
T.eq(Layout.uptimeText(nil), "0s")
T.eq(Layout.uptimeText(0 / 0), "0s")
T.eq(Layout.uptimeText("70"), "1m 10s")
T.eq(Layout.playersText(7, 50), "7/50")
T.eq(Layout.playersText(7, 0), "7")
T.eq(Layout.playersText(7, nil), "7")
T.eq(Layout.playersText(nil, 12), "0/12")
T.eq(Layout.pingText(42), "42ms")
T.eq(Layout.pingText(42.6), "43ms")
T.eq(Layout.pingText(nil), "-")
T.eq(Layout.pingText(-1), "-")
T.eq(Layout.pingText(0 / 0), "-")
T.eq(Layout.pingText("12"), "-")

T.section("home_layout: friends cache")
T.ok(Layout.friendsDue(100, -1000))
T.ok(Layout.friendsDue(130, 100))
T.ok(not Layout.friendsDue(129.9, 100))
T.ok(Layout.friendsDue(500, 100, 60))
T.ok(not Layout.friendsDue(150, 100, 60))
T.eq(Layout.FRIENDS_TTL, 30)
T.eq(Layout.friendsLine(0, 0), "None of your friends are online")
T.eq(Layout.friendsLine(3, 0), "None of them are in this game")
T.eq(Layout.friendsLine(3, 1), "1 of them is in this game")
T.eq(Layout.friendsLine(3, 2), "2 of them are in this game")

T.section("home_layout: failure card text")
T.eq(Layout.failReason("home_page:123: attempt to index nil"), "attempt to index nil")
T.eq(Layout.failReason("Atsuko Hub/modules/x.lua:50: boom"), "boom")
T.eq(Layout.failReason("plain message"), "plain message")
T.eq(Layout.failReason("first line\nsecond line"), "first line")
T.eq(Layout.failReason("  spaced    out   text  "), "spaced out text")
T.eq(Layout.failReason(nil), "unknown error")
T.eq(Layout.failReason(""), "unknown error")
T.eq(Layout.failReason("x:1:"), "unknown error")
T.eq(Layout.failReason('[string "return x"]:12: boom'), "boom")
T.eq(Layout.failReason("(loadstring):3: boom"), "boom")
T.eq(Layout.failReason("home_page:50: home_page:99: boom"), "boom")
T.eq(Layout.failReason("a:1: b:2: c:3: d:4: boom"), "d:4: boom")
T.eq(Layout.failReason("Atsuko/Foo:12: bar: baz"), "bar: baz")
T.eq(Layout.failReason("status 404: not found"), "status 404: not found")
T.eq(Layout.failReason("Failed: 404: not found"), "Failed: 404: not found")
T.eq(Layout.failReason("Players.Me.PlayerGui.Script:7: attempt to call a nil value"), "attempt to call a nil value")
T.eq(Layout.failReason(42), "42")
T.eq(Layout.failReason({}) ~= "", true)
local longMsg = Layout.failReason(string.rep("abcdefghij", 20))
T.eq(#longMsg, 60)
T.eq(string.sub(longMsg, -3), "...")
T.eq(Layout.failReason("bad \226\156\147 mark"), "bad ??? mark")
T.eq(Layout.failText("m:1: oops"), "this card failed: oops")

T.section("home_layout: entrance stagger")
T.eq(Layout.stagger(1), 0)
T.near(Layout.stagger(2), 0.04)
T.near(Layout.stagger(5), 0.16)
T.near(Layout.stagger(13), 0.48)
T.near(Layout.stagger(100), 0.48)
T.eq(Layout.stagger(0), 0)
T.eq(Layout.stagger(nil), 0)
for i = 2, 13 do
	T.near(Layout.stagger(i) - Layout.stagger(i - 1), 0.04, 1e-9, "40 ms gap " .. i)
end

T.section("home_layout: recent list signature")
local function state(p)
	if p == "b" then
		return "r"
	end
	return "i"
end
T.eq(Layout.recentSignature({}, state), "")
T.eq(Layout.recentSignature({ "a", "b" }, state), "a:i|b:r")
T.ok(Layout.recentSignature({ "a", "b" }, state) ~= Layout.recentSignature({ "b", "a" }, state))
