local View = loadmodule("Hub/modules/badgeview.lua")
local V = loadmodule("Hub/modules/verified.lua")
local MARK = V.MARK

T.section("badgeview: reading a chat line")
T.eq(View.plain('<font color="#ff0000">Atsuko</font>'), "Atsuko", "tags are left out")
T.eq(View.plain("a &lt;3 &amp; b"), "a <3 & b", "escaped characters count as one letter")
T.eq(View.plain(nil), "")
T.eq(View.bold("<b>Atsuko"), true, "an open bold tag")
T.eq(View.bold("<b>VIP</b> Atsuko"), false, "a closed one")
T.eq(View.bold("<B>x"), true)
T.eq(View.bold("plain"), false)
local head, bold = View.before('<font color="#123456"><b>Atsuko' .. MARK .. ":</b></font> hello", V.MARK_OPEN)
T.eq(head, "Atsuko", "what comes before the badge")
T.eq(bold, true, "and that it is bold")
head, bold = View.before("[VIP] Atsuko" .. MARK .. ": hi", V.MARK_OPEN)
T.eq(head, "[VIP] Atsuko")
T.eq(bold, false)
T.eq(View.before("Bob: hi", V.MARK_OPEN), nil, "no mark, no badge")
T.eq(View.before(nil, V.MARK_OPEN), nil)
head = View.before("first line\nAtsuko" .. MARK .. ":", V.MARK_OPEN)
T.eq(head, "Atsuko", "only the line the badge is on")

T.section("badgeview: where the badge goes")
local function label(props)
	local o = { TextSize = 14, LineHeight = 1, Text = "", TextXAlignment = "Enum.TextXAlignment.Left", TextYAlignment = "Enum.TextYAlignment.Top" }
	for k, v in pairs(props or {}) do
		o[k] = v
	end
	function o:FindFirstChildOfClass(class)
		return class == "UIPadding" and o._pad or nil
	end
	return o
end
local x, y, s = View.chatSpot(label(), 50)
T.eq(s, 13, "a little smaller than the text")
T.eq(x, 52, "two pixels after the name")
T.eq(y, 1, "in the middle of the first line")
x, y = View.chatSpot(label({ _pad = { PaddingLeft = { Offset = 8 }, PaddingTop = { Offset = 4 } } }), 50)
T.eq(x, 60, "the line's padding counts")
T.eq(y, 5)
x, y = View.chatSpot(label({ TextBounds = { X = 300, Y = 56 }, TextSize = 14 }), 50)
T.eq(y, 1, "a message over several lines puts it on the first one")
x, y = View.chatSpot(label({ TextYAlignment = "Enum.TextYAlignment.Center", AbsoluteSize = { X = 300, Y = 40 }, TextBounds = { X = 100, Y = 14 } }), 50)
T.eq(y, 14, "text centered in a taller line, the badge follows it down")
x, y = View.chatSpot(label({ TextYAlignment = "Enum.TextYAlignment.Bottom", AbsoluteSize = { X = 300, Y = 40 }, TextBounds = { X = 100, Y = 14 } }), 50)
T.eq(y, 27, "text at the bottom of a line")
x, y, s = View.chatSpot(label({ TextSize = 20, LineHeight = 1.2 }), 0)
T.eq(s, 18)
T.eq(y, 3)
x, y, s = View.chatSpot(label({ TextSize = 4 }), 10)
T.eq(s, 8, "never tiny")
x, y, s = View.boardSpot(label({ TextBounds = { X = 60, Y = 14 }, AbsoluteSize = { X = 200, Y = 30 }, TextYAlignment = "Enum.TextYAlignment.Center" }))
T.eq(x, 64, "in a list row, right after the name")
T.eq(y, 6, "and level with it")
T.eq(s, 18, "next to a name it is bigger than the text, like Roblox's own")
x = View.boardSpot(label({ TextBounds = { X = 60, Y = 14 }, AbsoluteSize = { X = 200, Y = 14 }, TextXAlignment = "Enum.TextXAlignment.Center" }))
T.eq(x, 134, "a centered name")
x = View.boardSpot(label({ TextBounds = { X = 60, Y = 14 }, AbsoluteSize = { X = 200, Y = 14 }, TextXAlignment = "Enum.TextXAlignment.Right" }))
T.eq(x, 204, "a name on the right")
x, y = View.boardSpot(label({ TextBounds = { X = 60, Y = 18 }, AbsoluteSize = { X = 0, Y = 0 }, TextYAlignment = "Enum.TextYAlignment.Center" }))
T.eq(x, 64, "a label sized by its text")
T.eq(y, -11, "centered on its own line")
x = View.boardSpot(label({ TextBounds = { X = 60, Y = 14 }, AbsoluteSize = { X = 200, Y = 14 }, _pad = { PaddingLeft = { Offset = 6 }, PaddingRight = { Offset = 6 } } }))
T.eq(x, 70)

T.section("badgeview: a menu that Roblox scales up")
local function scaledIn(props, scales)
	local o = label(props)
	local top = { ClassName = "ScreenGui" }
	function top:GetChildren()
		return {}
	end
	local parent = top
	for _, k in ipairs(scales) do
		local frame = { ClassName = "Frame", Parent = parent }
		local list = { { ClassName = "UIScale", Scale = k } }
		function frame:GetChildren()
			return list
		end
		parent = frame
	end
	o.ClassName = "TextLabel"
	o.Parent = parent
	function o:GetChildren()
		return {}
	end
	return o
end
T.eq(View.scaleOf(scaledIn({}, { 1.5 })), 1.5, "a UIScale above the label is found")
T.eq(View.scaleOf(scaledIn({}, { 1.5, 2 })), 3, "and several multiply")
T.eq(View.scaleOf(label()), 1, "no UIScale is 1")
x, y, s = View.boardSpot(scaledIn({ TextBounds = { X = 60, Y = 14 }, AbsoluteSize = { X = 300, Y = 21 } }, { 1.5 }))
T.eq(x, 64, "the People menu card: right after the name, not out at the edge")
T.eq(s, 18, "and as big as next to any other name")
x = View.boardSpot(scaledIn({ TextBounds = { X = 90, Y = 21 }, AbsoluteSize = { X = 300, Y = 21 } }, { 1.5 }))
T.eq(x, 64, "the same when Roblox reports the text already scaled")
x = View.boardSpot(scaledIn({ TextBounds = { X = 60, Y = 14 }, AbsoluteSize = { X = 300, Y = 21 }, TextXAlignment = "Enum.TextXAlignment.Center" }, { 1.5 }))
T.eq(x, 134, "a centered name in a scaled card")
T.eq(View.measured({ AbsoluteSize = { X = 24, Y = 24 } }, 16), 1.5, "the badge's real size on screen tells the scale")
x, y, s = View.boardSpot(label({ TextSize = 14, TextBounds = { X = 60, Y = 14 }, AbsoluteSize = { X = 60, Y = 30 }, AutomaticSize = "Enum.AutomaticSize.XY", TextYAlignment = "Enum.TextYAlignment.Center" }))
T.eq(s, 36, "a name drawn bigger than its TextSize says (a label that grows to fit its text) gets a badge as big as what you see")
T.eq(x, 64)
local _, _, small = View.boardSpot(label({ TextSize = 14, TextBounds = { X = 60, Y = 14 }, AbsoluteSize = { X = 200, Y = 30 }, AutomaticSize = "Enum.AutomaticSize.X" }))
T.eq(small, 18, "a leaderboard name in a tall row doesn't grow with the row")
T.eq(View.measured({ AbsoluteSize = { X = 0, Y = 0 } }, 16), nil, "not before it is drawn")
x = View.boardSpot(label({ TextBounds = { X = 60, Y = 14 }, AbsoluteSize = { X = 300, Y = 21 } }), 1.5)
T.eq(x, 64, "a scale measured that way works without a UIScale")

T.section("badgeview: whose row a name is in")
local players = { [10] = { Name = "atsukohakari", DisplayName = "Atsuko", UserId = 10 }, [20] = { Name = "bob", DisplayName = "Bobby", UserId = 20 } }
local env = {
	byId = function(id)
		return players[id]
	end,
	byName = function(n)
		for _, p in pairs(players) do
			if p.Name == n then
				return p
			end
		end
	end,
	users = function()
		return { players[10] }
	end,
}
local function chain(names, leaf)
	local node = nil
	for _, n in ipairs(names) do
		node = { Name = n, Parent = node }
	end
	leaf.Parent = node
	return leaf
end
T.eq(View.rowOwner(chain({ "RobloxGui", "Players", "PlayerLabelatsukohakari" }, { Name = "DisplayNameLabel" }), env), players[10], "the Roblox menu's row, by username")
T.eq(View.rowOwner(chain({ "InGameMenu", "List", "player_20", "Frame" }, { Name = "DisplayNameLabel" }), env), players[20], "the older in-game menu's row, by id")
T.eq(View.rowOwner(chain({ "PlayerList", "TeamList_1", "PlayerEntry_10", "ChildrenFrame", "NameFrame", "BGFrame", "OverlayFrame", "PlayerName", "PlayerNameContainer" }, { Name = "PlayerName" }), env), players[10], "the leaderboard's row")
T.eq(View.rowOwner(chain({ "PlayerList", "p_20", "Name" }, { Name = "PlayerName" }), env), players[20], "an older leaderboard row")
T.eq(View.rowOwner(chain({ "RobloxGui", "Topbar" }, { Name = "Label" }), env), nil, "anything else is nobody's")
T.eq(View.rowOwner(chain({ "PlayerLabelnobody" }, { Name = "x" }), env), nil, "a player who left")

T.section("badgeview: name or username")
T.eq(View.kind({ Name = "DisplayNameLabel", Text = "whatever alias" }, players[10]), "name", "the display name label, even with a nickname you gave them")
T.eq(View.kind({ Name = "PlayerName", Text = "Atsuko" }, players[10]), "name", "the leaderboard's name")
T.eq(View.kind({ Name = "NameLabel", Text = "@atsukohakari" }, players[10]), nil, "never the @username line")
T.eq(View.kind({ Name = "NameLabel", Text = "@atsukoh..." }, players[10]), nil, "even when it is cut short")
T.eq(View.kind({ Name = "X", Text = "@atsukohakari" }, players[10]), nil)
T.eq(View.kind({ Name = "UsernameLabel", Text = "atsukohakari" }, players[10]), nil)
T.eq(View.kind({ Name = "NameLabel", Text = "Atsuko" }, players[10]), nil)
T.eq(View.kind({ Name = "X", Text = "Atsuko" }, players[10]), "name")
T.eq(View.kind({ Name = "X", Text = "Score" }, players[10]), nil)
T.eq(View.kind({ Name = "DisplayNameLabel", Text = "" }, players[10]), nil, "an empty label waits for its text")

T.section("badgeview: cards it has never seen")
local function node(name, text, parent)
	local o = { Name = name, Text = text, Parent = parent, kids = {} }
	if parent then
		parent.kids[#parent.kids + 1] = o
	end
	function o:GetDescendants()
		local out = {}
		local function walk(n)
			for _, k in ipairs(n.kids) do
				out[#out + 1] = k
				walk(k)
			end
		end
		walk(o)
		return out
	end
	return o
end
local page = node("PeoplePage")
local card = node("Card", nil, page)
local nameLine = node("Title", "Atsuko", card)
local info = node("Info", nil, card)
local userLine = node("Subtitle", "@atsukohakari", info)
local who, kind = View.match(nameLine, env)
T.eq(who, players[10], "a name with the matching @username next to it")
T.eq(kind, "name")
T.eq(View.match(userLine, env), nil, "but not the @username under it")
local lonely = node("Label", "Atsuko", node("Topbar"))
T.eq(View.match(lonely, env), nil, "the same name with no @username near it is left alone")
local other = node("Card2", nil, page)
local bobby = node("Title", "Bobby", other)
node("Subtitle", "@bob", other)
T.eq(View.match(bobby, env), nil, "someone without a badge isn't matched by name")
T.eq(View.match(node("X", "@nobody", page), env), nil, "a username of nobody here")
T.eq(View.match(node("X", "", page), env), nil)
T.eq(View.near(nameLine, "@atsukohakari"), true)
T.eq(View.near(lonely, "@atsukohakari"), false)

T.section("badgeview: name tags above heads")
do
	local function node(class, name, parent)
		return { ClassName = class, Name = name, Parent = parent }
	end
	local bobP = { Name = "bob", DisplayName = "Bobby", UserId = 20 }
	local char = node("Model", "bob", nil)
	local head = node("Part", "Head", char)
	local bb = node("BillboardGui", "Overhead", head)
	local frame = node("Frame", "Holder", bb)
	local nameLabel = node("TextLabel", "Title", frame)
	nameLabel.Text = "Bobby"
	local tagEnv = {
		ofCharacter = function(m)
			return m == char and bobP or nil
		end,
	}
	T.eq(View.billboard(nameLabel), bb, "the billboard a label sits in")
	T.eq(View.tagOwner(nameLabel, tagEnv), bobP, "the player whose body holds it")
	T.same({ View.match(nameLabel, tagEnv, "tag") }, { bobP, "tag" }, "his display name on it")
	local loose = node("BillboardGui", "Loose", nil)
	loose.Adornee = head
	local adorned = node("TextLabel", "N", loose)
	adorned.Text = "bob"
	T.eq(View.tagOwner(adorned, tagEnv), bobP, "a billboard kept elsewhere but pointed at his head")
	T.eq(View.match(adorned, tagEnv, "tag"), nil, "his username doesn't count, only his display name")
	adorned.Text = "Bobby"
	T.same({ View.match(adorned, tagEnv, "tag") }, { bobP, "tag" }, "his display name on a billboard kept elsewhere")
	local other = node("TextLabel", "Rank", frame)
	other.Text = "Owner"
	T.eq(View.match(other, tagEnv, "tag"), nil, "a rank line is left alone")
	local at = node("TextLabel", "User", frame)
	at.Text = "@bob"
	T.eq(View.match(at, tagEnv, "tag"), nil, "and so is an @username")
	local screen = node("ScreenGui", "Hud", nil)
	local flat = node("TextLabel", "N", screen)
	flat.Text = "Bobby"
	T.eq(View.billboard(flat), nil, "a label on the screen isn't a name tag")
	local npc = node("Model", "Dummy", nil)
	local npcBoard = node("BillboardGui", "Tag", npc)
	local npcLabel = node("TextLabel", "N", npcBoard)
	npcLabel.Text = "Bobby"
	T.eq(View.match(npcLabel, tagEnv, "tag"), nil, "a dummy that shares his name isn't him")
	local scaled = label({ TextScaled = true, TextSize = 8, TextBounds = { X = 80, Y = 24 }, AbsoluteSize = { X = 200, Y = 24 } })
	local _, _, s = View.boardSpot(scaled)
	T.eq(s, 31, "text that scales itself is measured by how big it really is")
end

T.section("badgeview: the glyph goes into the name itself")
do
	local World = loadmodule("Testing/mocks/rbx_world.lua")
	local wenv = World.install({})
	local SUF = V.suffix()
	local Players = game:GetService("Players")
	local lp = Players.LocalPlayer
	local pg = Instance.new("Folder")
	pg.Name = "PlayerGui"
	local function screen(name)
		local g = Instance.new("ScreenGui")
		g.Name = name
		g.Parent = pg
		return g
	end
	local board = screen("Leaderboard")
	local function row(text, rich)
		local l = Instance.new("TextLabel")
		l.Text = text
		l.RichText = rich == true
		l.Parent = board
		return l
	end
	local mine = screen("AtsukoHubGui")
	local on = true
	local wv = View.watch({
		suffix = SUF,
		has = function(id)
			return on and id == lp.UserId
		end,
		users = function()
			return on and { lp } or {}
		end,
		playerGui = pg,
		mine = function(o)
			return o:IsDescendantOf(mine)
		end,
		byId = function()
			return nil
		end,
		byName = function()
			return nil
		end,
	})
	local name = lp.DisplayName
	local a = row(name)
	local b = row(lp.Name)
	local c = row(name .. "'s house")
	local d = row("Guards")
	local e = row("@" .. lp.Name)
	local f = row(name .. "Fan")
	local g = row("[VIP] " .. name .. " (Lv 9)")
	local h = row("<b>" .. name .. "</b>", true)
	local own = Instance.new("TextLabel")
	own.Text = name
	own.Parent = mine
	wenv.run(0.2)
	T.eq(a.Text, View.escape(name) .. SUF, "a game's own leaderboard gets the glyph right after the name")
	T.eq(a.RichText, true, "with rich text on, so it can be blue")
	T.eq(b.Text, lp.Name .. SUF, "a username on its own counts too")
	T.eq(c.Text, View.escape(name) .. SUF .. "'s house", "a name inside other text gets it right after the name")
	T.eq(d.Text, "Guards")
	T.eq(e.Text, "@" .. lp.Name, "an @username never does")
	T.eq(f.Text, name .. "Fan", "nor a longer word that only starts with the name")
	T.eq(g.Text, "[VIP] " .. View.escape(name) .. SUF .. " (Lv 9)", "a tag around the name keeps its place")
	T.eq(h.Text, "<b>" .. name .. SUF .. "</b>", "rich text stays rich")
	T.eq(own.Text, name, "the hub's own screens are never touched")
	a.Text = name
	wenv.run(0.1)
	T.eq(a.Text, View.escape(name) .. SUF, "the game writing the name again gets it back")
	a.Text = "Sapphire"
	wenv.run(0.1)
	T.eq(a.Text, "Sapphire", "a row reused for someone else loses it")
	a.Text = name
	wenv.run(0.1)
	T.eq(wv.count("name"), 5)
	on = false
	wv.refresh()
	T.eq(a.Text, name, "turning it off gives the name its own text back")
	T.eq(a.RichText, false, "and its rich text setting")
	on = true
	wv.refresh()
	T.eq(a.Text, View.escape(name) .. SUF)
	wv.stop()
	T.eq(a.Text, name, "stopping cleans up too")
	T.eq(b.Text, lp.Name)
	T.eq(View.escape("a<b & c>"), "a&lt;b &amp; c&gt;", "names are escaped before rich text goes on")
end

T.section("badgeview: every nickname, never a username")
do
	local SUF = V.suffix()
	local GL = V.GLYPH
	local function deco(text, names, chat)
		return View.decorate(text, names, SUF, GL, chat)
	end
	T.eq(deco("Bobby", { "Bobby" }), "Bobby" .. SUF)
	T.eq(deco("bob", { "Bobby" }), nil, "a username that isn't the display name is left alone")
	T.eq(deco("@Bobby", { "Bobby" }), nil, "an @ in front means a username")
	T.eq(deco("Bobby and Sam", { "Bobby", "Sam" }), "Bobby" .. SUF .. " and Sam" .. SUF, "two badged people in one line both get it")
	T.eq(deco("Bobby_2", { "Bobby" }), nil, "a different name that starts the same is left alone")
	T.eq(deco("Bobby" .. SUF, { "Bobby" }), nil, "a name that already has it doesn't get a second one")
	T.eq(deco('<font color="#ff0000">Bobby</font>' .. SUF, { "Bobby" }), nil, "even with a color tag between them")
	T.eq(deco('<font face="Bobby">Hi</font>', { "Bobby" }), nil, "nothing inside a rich text tag")
	T.eq(deco("Bobby: hi Sam", { "Sam", "Bobby" }, true), "Bobby" .. SUF .. ": hi Sam", "in chat only the sender's name, not a name in the message")
	T.eq(deco("Bobby joined", { "Bobby" }, true), "Bobby" .. SUF .. " joined", "a chat line with no message part still counts")
	T.eq(deco("Bobby Bob", { "Bob", "Bobby" }), "Bobby" .. SUF .. " Bob" .. SUF, "a longer name is not cut by a shorter one")
	local names = View.nicknames({ users = function()
		return { { DisplayName = "Bobby", Name = "bob" }, { DisplayName = "A&B", Name = "ab" } }
	end }, false)
	T.same(names, { "A&amp;B", "Bobby" }, "only display names, escaped for plain labels, longest first")
end
