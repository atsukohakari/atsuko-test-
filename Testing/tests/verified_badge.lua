local Runner = loadmodule("Testing/mocks/boot_runner.lua")
local V0 = loadmodule("Hub/modules/verified.lua")

local GLYPH = "\238\128\128"
local MARK = V0.MARK
local SUF = V0.suffix()

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

local function texts(root, text)
	return all(root, function(d)
		return (d:IsA("TextLabel") or d:IsA("TextButton")) and d.Text == text
	end)
end

local function errorsOf(env)
	local out = {}
	for _, item in ipairs(env.hub.Log.items or {}) do
		if item.kind == "error" then
			out[#out + 1] = tostring(item.src) .. ": " .. tostring(item.msg)
		end
	end
	return out
end

local function clean(env, what)
	T.eq(#errorsOf(env), 0, what .. ": no errors: " .. table.concat(errorsOf(env), " | "))
	T.eq(#(env.badProps or {}), 0, what .. ": no bad GUI values: " .. table.concat(env.badProps or {}, " | "))
end

local function rgb(c)
	return { math.floor(c.R * 255 + 0.5), math.floor(c.G * 255 + 0.5), math.floor(c.B * 255 + 0.5) }
end

local function sealColor(badge)
	local seal = badge:FindFirstChild("Seal")
	if seal:IsA("ImageLabel") then
		return rgb(seal.ImageColor3)
	end
	return rgb(seal.BackgroundColor3)
end

local function world(e)
	local cfg = e.newInstance("ChatWindowConfiguration")
	cfg.Name = "ChatWindowConfiguration"
	cfg.Parent = e.service("TextChatService")
	local chat = e.newInstance("ScreenGui")
	chat.Name = "ExperienceChat"
	chat.Parent = e.service("CoreGui")
	local list = e.newInstance("Frame")
	list.Name = "scrollingView"
	list.Parent = chat
	local board = e.newInstance("ScreenGui")
	board.Name = "PlayerList"
	board.Parent = e.service("CoreGui")
	local rows = e.newInstance("Frame")
	rows.Name = "OffsetUndoFrame"
	rows.Parent = board
	local rgui = e.newInstance("ScreenGui")
	rgui.Name = "RobloxGui"
	rgui.Parent = e.service("CoreGui")
	local page = e.newInstance("Frame")
	page.Name = "Players"
	page.Parent = rgui
	e.chatList, e.boardRows, e.menuPage = list, rows, page
end

local function boardRow(env, id, name)
	local row = env.newInstance("Frame")
	row.Name = "PlayerEntry_" .. tostring(id)
	row.Size = UDim2.fromOffset(200, 30)
	local wrap = env.newInstance("Frame")
	wrap.Name = "PlayerNameContainer"
	wrap.Size = UDim2.fromOffset(170, 14)
	env.newInstance("UIListLayout").Parent = wrap
	wrap.Parent = row
	local l = env.newInstance("TextLabel")
	l.Name = "PlayerName"
	l.Text = name
	l.TextSize = 14
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.Size = UDim2.fromOffset(150, 14)
	l.Parent = wrap
	row.Parent = env.boardRows
	return l
end

local function card(env, displayName, userName)
	local c = env.newInstance("Frame")
	c.Name = "Card"
	c.Size = UDim2.fromOffset(300, 60)
	local title = env.newInstance("TextLabel")
	title.Name = "Title"
	title.Text = displayName
	title.TextSize = 16
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Size = UDim2.fromOffset(200, 20)
	title.Parent = c
	local sub = env.newInstance("TextLabel")
	sub.Name = "Subtitle"
	sub.Text = "@" .. userName
	sub.TextSize = 12
	sub.TextXAlignment = Enum.TextXAlignment.Left
	sub.Size = UDim2.fromOffset(200, 16)
	sub.Parent = c
	c.Parent = env.menuPage
	return title, sub
end

local function menuRow(env, player)
	local frame = env.newInstance("ImageLabel")
	frame.Size = UDim2.fromOffset(400, 60)
	frame.Parent = env.menuPage
	local dn = env.newInstance("TextLabel")
	dn.Name = "DisplayNameLabel"
	dn.TextSize = 18
	dn.TextXAlignment = Enum.TextXAlignment.Left
	dn.TextYAlignment = Enum.TextYAlignment.Center
	dn.Parent = frame
	local un = env.newInstance("TextLabel")
	un.Name = "NameLabel"
	un.TextSize = 14
	un.TextXAlignment = Enum.TextXAlignment.Left
	un.Parent = frame
	frame.Name = "PlayerLabel" .. player.Name
	un.Text = "@" .. player.Name
	dn.Text = player.DisplayName
	return dn, un
end

local function say(env, id, prefix, text, layout)
	local svc = env.service("TextChatService")
	local props = svc.OnChatWindowAdded and svc.OnChatWindowAdded({ TextSource = { UserId = id }, PrefixText = prefix, Text = text }) or nil
	local shown = props and props.PrefixText ~= nil and props.PrefixText ~= "" and props.PrefixText or prefix
	local l = env.newInstance("TextLabel")
	l.Name = "TextMessage"
	l.RichText = true
	l.TextSize = 14
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.TextYAlignment = Enum.TextYAlignment.Top
	if layout then
		env.newInstance("UIListLayout").Parent = l
	end
	l.Text = shown .. " " .. text
	l.Parent = env.chatList
	return l, props
end

local function addPlayer(env, id, name)
	local pl = env.newInstance("Player")
	pl._p.Name = name
	pl._p.DisplayName = name
	pl._p.UserId = id
	pl._p.AccountAge = 10
	pl.Parent = env.Players
	env.Players.PlayerAdded:Fire(pl)
	return pl
end

local function msg(id, prefix)
	return { TextSource = { UserId = id }, PrefixText = prefix }
end

local function badgeOf(l)
	local t = l.Text
	if type(t) == "string" and string.find(t, SUF, 1, true) then
		return { text = t }
	end
	return nil
end

local function hello(env, id, name, on, ts)
	env.hub.Chat.receive({ a = "atsuko", v = 1, k = "hi", c = "s", t = "", u = tostring(id), n = name, d = name, ts = ts or os.time(), x = "h" .. tostring(ts or 0), vb = on and 1 or 0 }, "s")
end

T.section("verified_badge: off until you turn it on")
local env = Runner.boot({ seconds = 8, before = world })
local hub, core = env.hub, env.core
T.ok(hub ~= nil and core ~= nil, "the hub booted: " .. tostring(env.mainErr))
local S = hub.S
T.ok(core.Verified ~= nil and core.BadgeView ~= nil, "the badge modules loaded")
T.eq(S.verifiedBadge, false, "nobody has a badge to start with")
T.eq(core.hasBadge(1), false)
T.eq(core.chatStyle, nil, "Roblox chat is left alone")
T.eq(env.service("TextChatService").OnChatWindowAdded, nil)
T.eq(core.badgeView, nil, "and nothing is drawn into Roblox's screens")
hub.Panel.show("settings")
env.run(1)
local general = hub.Pages.settings.views[1]
T.eq(#texts(general, "Verified badge"), 1, "Settings > General has the Verified badge switch")
T.eq(#named(general, "OwnerBadgeBox"), 0, "no owner-only color box")
T.eq(#texts(general, "Purple"), 0, "and no colors to pick")
hub.Panel.show("home")
env.run(1)
local homeBadge = named(hub.Pages.home.scrollA, "VerifiedBadge")
T.eq(#homeBadge, 1, "Home has the badge ready")
T.eq(homeBadge[1].Visible, false, "but hidden")
clean(env, "off")

T.section("verified_badge: turning it on")
local me = env.lp
me._p.Team = env.newInstance("Team")
me._p.TeamColor = { Color = Color3.fromRGB(255, 140, 0) }
local myMenuName, myMenuUser = menuRow(env, me)
local myBoard = boardRow(env, 1, "Tester")
core.setVerifiedBadge(true)
env.run(2)
T.eq(S.verifiedBadge, true)
T.ok(string.find(env.files["AtsukoHub/settings.json"] or "", '"verifiedBadge":true', 1, true) ~= nil, "it is saved")
T.eq(homeBadge[1].Visible, true, "Home shows it next to your name")
T.ok(core.chatStyle ~= nil and core.chatStyle.active, "the chat window is styled")
T.ok(core.badgeView ~= nil and core.badgeView.chat(), "and the hub found Roblox's chat window")
local line, props = say(env, 1, "Tester:", "hello")
env.run(1)
T.eq(props.PrefixText, "Tester" .. SUF .. ":", "your name in chat gets Roblox's verified glyph right after it")
T.ok(string.find(SUF, GLYPH, 1, true) ~= nil and string.find(SUF, '<font color="#0066ff" family="rbxasset://fonts/families/BuilderSans.json">', 1, true) == 1, "the glyph is utf8.char(0xE000), in Roblox blue and Roblox's own font")
T.same(rgb(props.PrefixTextProperties.TextColor3), { 255, 140, 0 }, "and your nickname keeps its own color")
local cb = badgeOf(line)
T.ok(cb ~= nil, "the badge is right after your name")
T.eq(string.find(line.Text, "Tester" .. SUF .. ":", 1, true), 1, "with nothing between the name and it")
T.eq(line:FindFirstChild("AtsukoBadge"), nil, "and no picture is drawn on the line any more")
local listed = say(env, 1, "Tester:", "a line with its own layout", true)
env.run(1)
T.ok(badgeOf(listed) ~= nil, "a chat line with a list layout gets it too")
local late = env.newInstance("TextLabel")
late.TextSize = 14
late.Text = "nothing yet"
late.Parent = env.chatList
env.run(1)
T.eq(badgeOf(late), nil)
late.Text = "Tester" .. SUF .. ": filled in later"
env.run(1)
T.ok(badgeOf(late) ~= nil, "a line whose text arrives after it is made")
late.Text = "Bob: reused"
env.run(1)
T.eq(badgeOf(late), nil, "and goes when the line is reused for someone else")
env.run(1)
local mb = badgeOf(myMenuName)
T.ok(mb ~= nil, "the Roblox menu's people list shows it after your display name")
T.eq(badgeOf(myMenuUser), nil, "not after your @username")
T.eq(myMenuName.Text, "Tester" .. SUF, "the glyph goes straight after your display name, so it is as close and as big as the name")
T.eq(myMenuName.RichText, true)
T.eq(myMenuUser.Text, "@Tester", "the @username is left as it is")
T.eq(myMenuName:FindFirstChild("AtsukoBadge"), nil, "no picture")
local bb = badgeOf(myBoard)
T.ok(bb ~= nil, "the leaderboard too")
T.eq(myBoard.Text, "Tester" .. SUF, "right after your name there")
myBoard.Text = "Tester"
env.run(1)
T.eq(myBoard.Text, "Tester" .. SUF, "when Roblox writes your name again the glyph comes back")
local newTitle, newSub = card(env, "Tester", "Tester")
env.run(1)
T.ok(badgeOf(newTitle) ~= nil, "a newer menu card with your name and @username gets it on the name")
T.eq(badgeOf(newSub), nil, "but not on the @username")
local topbar = env.newInstance("Frame")
topbar.Name = "TopBar"
topbar.Parent = env.menuPage.Parent
local stray = env.newInstance("TextLabel")
stray.Text = "Tester"
stray.Parent = topbar
env.run(1)
T.ok(badgeOf(stray) ~= nil, "your display name anywhere else in Roblox's menus gets it too")
local strayUser = env.newInstance("TextLabel")
strayUser.Text = "@Tester"
strayUser.Parent = topbar
env.run(1)
T.eq(badgeOf(strayUser), nil, "an @username never does")
local tagFolder = env.newInstance("Folder")
tagFolder.Name = "Nametags"
local tagBoard = env.newInstance("BillboardGui")
tagBoard.Parent = tagFolder
local tagText = env.newInstance("TextLabel")
tagText.Text = "[Owner] Tester"
tagText.Parent = tagBoard
tagFolder.Parent = workspace
env.run(1)
T.eq(tagText.Text, "[Owner] Tester" .. SUF, "a game's own name tag kept anywhere in the world gets it right after the name")
local sign = env.newInstance("SurfaceGui")
local signText = env.newInstance("TextButton")
signText.Text = "Tester's shop"
signText.Parent = sign
sign.Parent = workspace
env.run(1)
T.eq(signText.Text, "Tester" .. SUF .. "'s shop", "and a button with your name on a sign")
T.eq(#all(hub.Gui, function(d)
	return (d:IsA("TextLabel") or d:IsA("TextButton")) and type(d.Text) == "string" and string.find(d.Text, SUF, 1, true) ~= nil
end), 0, "the hub's own screens are never touched by this")
hub.Panel.show("players")
env.run(2)
local rowMe = hub.Pages.players.frame:FindFirstChild("P_Tester", true)
T.eq(#named(rowMe, "VerifiedBadge"), 1, "and your row on the hub's Players page")
T.eq(env.Players.LocalPlayer.HasVerifiedBadge, nil, "Roblox's own badge is never turned on")
clean(env, "on")

T.section("verified_badge: other hub users see it")
local bob = addPlayer(env, 222, "Bob")
local tory = addPlayer(env, 333, "Tory")
env.run(1)
local bobMenu = menuRow(env, bob)
local toryMenu = menuRow(env, tory)
env.run(1)
T.eq(badgeOf(bobMenu), nil, "Bob has no badge until his hub says so")
hello(env, 222, "Bob", true, 1000)
env.run(1)
T.eq(core.hasBadge(222), true, "Bob's hub says his badge is on")
T.ok(badgeOf(bobMenu) ~= nil, "so his row in the Roblox menu gets it")
T.eq(badgeOf(toryMenu), nil, "Tory's doesn't")
local bobLine, bp = say(env, 222, "Bob:", "yo")
env.run(1)
T.eq(bp.PrefixText, "Bob" .. SUF .. ":")
T.ok(badgeOf(bobLine) ~= nil, "and his chat lines")
local toryLine, tp = say(env, 333, "Tory:", "hey")
env.run(1)
T.eq(tp, nil, "Tory's lines are left to Roblox")
T.eq(badgeOf(toryLine), nil)
hub.Panel.show("players")
env.run(2)
T.eq(#named(hub.Pages.players.frame:FindFirstChild("P_Bob", true), "VerifiedBadge"), 1, "Bob's row on the hub's Players page")
T.eq(#named(hub.Pages.players.frame:FindFirstChild("P_Tory", true), "VerifiedBadge"), 0)
hello(env, 222, "Bob", false, 900)
env.run(1)
T.eq(core.hasBadge(222), true, "an older message never turns it off")
hello(env, 222, "Bob", false, 1100)
env.run(1)
T.eq(core.hasBadge(222), false, "a newer one does")
T.eq(badgeOf(bobMenu), nil, "and his menu row loses it")
hub.Panel.show("players")
env.run(2)
T.eq(#named(hub.Pages.players.frame:FindFirstChild("P_Bob", true), "VerifiedBadge"), 0, "and his Players row")
hub.Chat.receive({ a = "atsuko", v = 1, k = "hi", c = "s", t = "", u = "333", n = "Tory", d = "Tory", ts = 2000, x = "z1", vb = "yes" }, "s")
T.eq(core.hasBadge(333), false, "a strange value is ignored")
hub.Chat.receive({ a = "atsuko", v = 1, k = "hi", c = "s", t = "", u = "1", n = "Tester", d = "Tester", ts = 3000, x = "z2", vb = 0 }, "s")
T.eq(core.hasBadge(1), true, "nobody else's message turns yours off")

T.section("verified_badge: the hub's own chat")
do
	local Chat = hub.Chat
	local p = Chat.payload("msg", "s", "hi")
	T.eq(p.vb, 1, "your messages say your badge is on")
	T.eq(Chat.valid(p, "s"), true, "and stay valid")
	Chat.open()
	env.run(2)
	local now = os.time()
	Chat.receive({ a = "atsuko", v = 1, k = "msg", c = Chat.tab, t = "from far away", u = "5555", n = "Faraway", d = "Far", ts = now, x = "m1", vb = 1 }, Chat.tab)
	Chat.receive({ a = "atsuko", v = 1, k = "msg", c = Chat.tab, t = "plain", u = "6666", n = "Plain", d = "Plain", ts = now + 1, x = "m2", vb = 0 }, Chat.tab)
	Chat.receive({ a = "atsuko", v = 1, k = "msg", c = Chat.tab, t = "old hub", u = "7777", n = "Old", d = "Old", ts = now + 2, x = "m3" }, Chat.tab)
	env.run(1)
	T.eq(#named(Chat.rows["5555:m1"].frame, "VerifiedBadge"), 1, "someone in another server with it on")
	T.eq(#named(Chat.rows["6666:m2"].frame, "VerifiedBadge"), 0, "someone with it off")
	T.eq(#named(Chat.rows["7777:m3"].frame, "VerifiedBadge"), 0, "someone on an older hub")
	local b = named(Chat.rows["5555:m1"].frame, "VerifiedBadge")[1]
	local head = b.Parent
	T.ok(head:FindFirstChild("Name").LayoutOrder < b.LayoutOrder, "after the name")
	T.ok(b.LayoutOrder < head.Time.LayoutOrder, "before the time")
	T.same(rgb(head:FindFirstChild("Name").TextColor3), rgb(core.ctx.T.text), "names are back to their normal color")
end

T.section("verified_badge: turning it off")
core.setVerifiedBadge(false)
env.run(2)
T.eq(S.verifiedBadge, false)
T.eq(homeBadge[1].Visible, false, "Home hides it")
T.eq(core.chatStyle, nil, "with nobody's badge on, the chat window is given back")
T.eq(env.service("TextChatService").OnChatWindowAdded, nil)
T.eq(core.badgeView, nil)
T.eq(myMenuName.Text, "Tester", "and every name gets its own text back")
T.eq(myMenuName.RichText, false)
T.eq(myBoard.Text, "Tester")
T.eq(hub.Chat.payload("hi", "s", "").vb, 0)
hello(env, 222, "Bob", true, 1200)
env.run(1)
T.ok(core.chatStyle ~= nil and core.badgeView ~= nil, "Bob turning his on brings it back for him")
T.ok(badgeOf(bobMenu) ~= nil)
bob.Parent = nil
env.Players.PlayerRemoving:Fire(bob)
env.run(1)
T.eq(core.hasBadge(222), false, "when Bob leaves he is forgotten")
T.eq(core.chatStyle, nil, "and nothing is styled any more")
clean(env, "off again")

T.section("verified_badge: a saved badge comes back")
do
	local e2 = Runner.boot({ seconds = 8, files = { ["AtsukoHub/settings.json"] = jsonencode({ verifiedBadge = true, vbStyle = "ff00aa", chatNameColors = true }) }, before = world })
	T.eq(e2.hub.S.verifiedBadge, true)
	T.eq(e2.hub.S.vbStyle, nil, "old color settings are dropped")
	T.eq(e2.hub.S.chatNameColors, nil)
	T.ok(e2.core.chatStyle ~= nil and e2.core.chatStyle.active, "chat is styled a few seconds in")
	local l = say(e2, 1, "Tester:", "back again")
	e2.run(1)
	T.ok(badgeOf(l) ~= nil)
	e2.genv.__AtsukoHubInstance.Destroy()
	e2.run(1)
	T.eq(e2.service("TextChatService").OnChatWindowAdded, nil, "closing the hub gives the chat window back")
	local e3 = Runner.boot({ seconds = 8, files = { ["AtsukoHub/settings.json"] = jsonencode({ verifiedBadge = "yes" }) } })
	T.eq(e3.hub.S.verifiedBadge, false, "junk is off")
end

T.section("verified_badge: waits until the hub has started")
do
	local e4 = Runner.boot({ seconds = 1, files = { ["AtsukoHub/settings.json"] = jsonencode({ verifiedBadge = true }) }, before = world })
	T.eq(e4.service("TextChatService").OnChatWindowAdded, nil, "nothing is touched in the first second")
	e4.run(4)
	T.eq(type(e4.service("TextChatService").OnChatWindowAdded), "function", "it goes on a few seconds in")
end

T.section("verified_badge: no chat window to draw in")
do
	local e8 = Runner.boot({ seconds = 8, files = { ["AtsukoHub/settings.json"] = jsonencode({ verifiedBadge = true }) }, before = function(e)
		local cfg = e.newInstance("ChatWindowConfiguration")
		cfg.Name = "ChatWindowConfiguration"
		cfg.Parent = e.service("TextChatService")
	end })
	T.eq(e8.core.badgeView.chat(), false, "the hub can't see Roblox's chat window")
	local out = e8.service("TextChatService").OnChatWindowAdded(msg(1, "Tester:"))
	T.eq(out.PrefixText, "Tester" .. SUF .. ":", "the glyph goes right after the name all the same")
end

T.section("verified_badge: safe mode")
do
	local e3 = Runner.boot({ seconds = 8, files = { ["AtsukoHub/settings.json"] = jsonencode({ verifiedBadge = true }), ["AtsukoHub/boot.json"] = '{"v":1,"stage":"ready","ok":false,"doing":"hook:chat","n":0}' }, before = world })
	T.eq(e3.core.Boot.safe, true, "this is a safe start")
	T.eq(e3.core.chatStyle, nil, "no chat callback")
	T.eq(e3.core.badgeView, nil, "nothing drawn into Roblox's screens")
	T.eq(e3.service("TextChatService").OnChatWindowAdded, nil)
end

T.section("verified_badge: an executor without getcallbackvalue")
do
	local e5 = Runner.boot({ seconds = 8, without = { "getcallbackvalue" }, files = { ["AtsukoHub/settings.json"] = jsonencode({ verifiedBadge = true }) }, before = world })
	T.ok(e5.core.chatStyle ~= nil and e5.core.chatStyle.active, "the badge still shows in chat")
	T.eq(e5.core.chatStyle.readable, nil)
	local said = false
	for _, item in ipairs(e5.hub.Log.items or {}) do
		if string.find(tostring(item.msg), "getcallbackvalue", 1, true) then
			said = true
		end
	end
	T.eq(said, true, "the console says what that means")
	T.eq(#errorsOf(e5), 0, "and nothing errors")
end

T.section("verified_badge: ESP names stay white")
do
	local e6 = Runner.boot({ seconds = 8 })
	local pl = addPlayer(e6, 222, "Bob")
	local char = e6.newInstance("Model")
	char.Name = "Bob"
	local head = e6.newInstance("Part")
	head.Name = "Head"
	head.Parent = char
	char.Parent = workspace
	pl._p.Character = char
	T.eq(e6.core.ctx.Cmd.run("esp", nil, true), true)
	e6.run(1)
	local found
	for _, d in ipairs(e6.hub.Gui.Parent:GetDescendants()) do
		if d.ClassName == "TextLabel" and d.Parent and d.Parent.ClassName == "BillboardGui" then
			found = d
		end
	end
	T.ok(found ~= nil)
	T.same(rgb(found.TextColor3), { 255, 255, 255 })
end

T.section("verified_badge: the name above their head")
do
	local e7 = Runner.boot({ seconds = 8, before = world })
	local function body(pl, name)
		local char = e7.newInstance("Model")
		char.Name = name
		local hum = e7.newInstance("Humanoid")
		hum.Name = "Humanoid"
		hum.Parent = char
		local head = e7.newInstance("Part")
		head.Name = "Head"
		head.Size = Vector3.new(2, 1, 1)
		head.Parent = char
		char.Parent = workspace
		pl._p.Character = char
		pl.CharacterAdded:Fire(char)
		return char, hum, head
	end
	local holder = e7.hub.Gui.Parent
	local function tagOf(head)
		for _, d in ipairs(holder:GetDescendants()) do
			if d.ClassName == "BillboardGui" and d.Name == "AtsukoNameTag" and d.Adornee == head then
				return d
			end
		end
		return nil
	end
	local function nameIn(tag)
		return tag:FindFirstChild("Row"):FindFirstChild("Name")
	end
	local bob = addPlayer(e7, 222, "Bob")
	local tory = addPlayer(e7, 333, "Tory")
	local _, bh, bhead = body(bob, "Bob")
	local _, th, thead = body(tory, "Tory")
	e7.run(1)
	T.eq(tagOf(bhead), nil, "no tag while nobody has a badge")
	hello(e7, 222, "Bob", true, 1000)
	e7.run(1)
	local tag = tagOf(bhead)
	T.ok(tag ~= nil, "Bob's badge shows above his head")
	T.eq(nameIn(tag).Text, "Bob" .. SUF, "with his name and the glyph right after it")
	T.eq(#named(tag, "VerifiedBadge"), 0, "no picture")
	T.eq(nameIn(tag).TextColor3, Color3.new(1, 1, 1), "white like Roblox's own name")
	local face = nameIn(tag).FontFace
	local fam = face and tostring(face.Family or face) or ""
	T.ok(nameIn(tag).Font == Enum.Font.BuilderSansBold or string.find(fam, "BuilderSans", 1, true) ~= nil, "in Roblox's own font, Builder Sans, never the hub's font: " .. fam)
	T.ok(e7.hub.S.font ~= "Builder", "even with the hub on another font: " .. tostring(e7.hub.S.font))
	T.eq(bh.NameDisplayDistance, 0, "Roblox's own name for him is hidden on your screen, so it isn't there twice")
	T.eq(bh.DisplayDistanceType, Enum.HumanoidDisplayDistanceType.Subject)
	T.eq(bh.HealthDisplayDistance, 100, "his health bar still shows")
	T.eq(tag.MaxDistance, 100, "it shows as far away as Roblox's name did")
	T.ok(math.abs(tag.StudsOffsetWorldSpace.Y - 1.6) < 0.001, "just above his head")
	T.eq(tagOf(thead), nil, "Tory has no badge")
	T.eq(th.NameDisplayDistance, 100, "so his name is left alone")
	bh.DisplayName = "Bobby"
	e7.run(1)
	T.eq(nameIn(tag).Text, "Bobby" .. SUF, "a game that renames him renames the tag")
	local game1 = e7.newInstance("BillboardGui")
	game1.Name = "Overhead"
	game1.Parent = bhead
	local own = e7.newInstance("TextLabel")
	own.Name = "PlayerName"
	own.Text = "Bob"
	own.TextScaled = true
	own.Size = UDim2.fromOffset(120, 30)
	own.Parent = game1
	e7.run(1)
	T.ok(badgeOf(own) ~= nil, "a game's own name tag over his head gets the badge too")
	local rank = e7.newInstance("TextLabel")
	rank.Text = "Owner"
	rank.Parent = game1
	e7.run(1)
	T.eq(badgeOf(rank), nil, "other lines on that tag don't")
	th.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	hello(e7, 333, "Tory", true, 1000)
	e7.run(1)
	T.eq(tagOf(thead), nil, "a game that hides names keeps Tory's hidden")
	T.eq(th.DisplayDistanceType, Enum.HumanoidDisplayDistanceType.None)
	local _, bh2, bhead2 = body(bob, "Bob")
	e7.run(1)
	T.eq(tagOf(bhead), nil, "when Bob respawns the old tag goes")
	T.ok(tagOf(bhead2) ~= nil, "and his new body gets one")
	T.eq(bh2.NameDisplayDistance, 0)
	bh2.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.Viewer
	e7.run(1)
	T.eq(bh2.NameDisplayDistance, 0, "the game turning names back on is followed")
	T.ok(tagOf(bhead2) ~= nil)
	hello(e7, 222, "Bob", false, 1100)
	e7.run(1)
	T.eq(tagOf(bhead2), nil, "Bob turning his badge off takes the tag away")
	T.eq(bh2.NameDisplayDistance, 100, "and Roblox's own name comes back")
	T.eq(bh2.DisplayDistanceType, Enum.HumanoidDisplayDistanceType.Viewer)
	e7.core.setVerifiedBadge(true)
	e7.run(1)
	local myHum = e7.lp.Character:FindFirstChildOfClass("Humanoid")
	T.eq(myHum.NameDisplayDistance, 100, "your own body is never touched, Roblox doesn't show you your own name")
	hello(e7, 222, "Bob", true, 1200)
	e7.run(1)
	T.ok(tagOf(bhead2) ~= nil)
	e7.genv.__AtsukoHubInstance.Destroy()
	e7.run(1)
	T.eq(tagOf(bhead2), nil, "closing the hub removes the tag")
	T.eq(bh2.NameDisplayDistance, 100, "and gives Roblox its name back")
	clean(e7, "name tags")
end
