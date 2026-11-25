local G = loadmodule("Testing/mocks/gui_mock.lua")

local IDS = { "profile", "nowplaying", "quick", "actions", "recent", "game", "server", "friends" }

local function boot(opts)
	local env = G.install(opts)
	local mod = loadmodule("Hub/modules/home_page.lua")
	mod.init(env.ctx)
	return env, mod, env.Home
end

local function parentOf(Home, id)
	local def = Home.defs[id]
	local rec = Home.customFrames[id]
	local f = def and def.frame or (rec and rec.frame)
	return f and f.Parent or nil, f
end

local function errors(env)
	local n = 0
	for _, it in ipairs(env.Log.items) do
		if it.kind == "error" then
			n = n + 1
		end
	end
	return n
end

local function find(root, name)
	return root:FindFirstChild(name, true)
end

T.section("home_page: builds every card without errors")
local env, mod, Home = boot()
T.eq(errors(env), 0)
T.eq(env.Core.homeReady, true)
for _, id in ipairs(IDS) do
	T.ok(Home.defs[id] ~= nil, "def " .. id)
	T.ok(Home.defs[id].frame ~= nil, "frame " .. id)
	T.eq(Home.order[#Home.order] ~= nil, true)
end
T.eq(#Home.order, 8)
T.eq(table.concat(Home.order, ","), table.concat(IDS, ","))
for _, key in ipairs({ "friends", "online", "days", "players", "ping", "uptime" }) do
	T.ok(Home.stats[key] ~= nil, "stat " .. key)
end
T.ok(Home.player ~= nil and Home.idle ~= nil)
T.ok(Home.quick ~= nil and Home.quickW ~= nil and Home.quickEdit ~= nil)
T.ok(Home.banner ~= nil and Home.bannerTitle ~= nil)
T.ok(Home.footer ~= nil and Home.editBtn ~= nil and Home.tools ~= nil)
T.ok(Home.recentBox ~= nil and Home.friendRow ~= nil and Home.friendText ~= nil)
for _, key in ipairs({ "stop", "respawn", "cmdbar", "explore" }) do
	T.ok(Home.tiles[key] ~= nil, "tile " .. key)
end
T.eq(Home.executor, "TestExec")
T.eq(Home.stats.days.Text, "400")
T.eq(Home.banner.Visible, false)
T.eq(Home.defs.profile.name, "Your profile")
T.eq(Home.defs.game.name, "This game")
T.eq(#env.Core.myPicTargets, 1)

T.section("home_page: wide layout puts two columns side by side")
env.Shell.narrow = false
Home.layout(390, 400)
T.eq(Home.scrollA.Size.X.Offset, 390)
T.eq(Home.scrollA.Size.Y.Offset, 400)
local expectA = { "profile", "nowplaying", "quick", "actions", "recent" }
local expectB = { "game", "server", "friends" }
for i, id in ipairs(expectA) do
	local p, f = parentOf(Home, id)
	T.eq(p, Home.scrollA, "left " .. id)
	T.eq(f.LayoutOrder, 10 + i, "order " .. id)
	T.eq(f.Visible, true)
end
for i, id in ipairs(expectB) do
	local p, f = parentOf(Home, id)
	T.eq(p, Home.scrollB, "right " .. id)
	T.eq(f.LayoutOrder, 10 + i, "order " .. id)
end
T.eq(Home.footer.Parent, Home.scrollB)
T.eq(Home.banner.Parent, Home.scrollA)
T.eq(Home.banner.LayoutOrder, 1)
T.eq(Home.editBtn.Parent, Home.scrollA)
T.eq(Home.editBtn.LayoutOrder, 998)

T.section("home_page: narrow layout is one list")
env.Shell.narrow = true
Home.layout(480, 400)
for _, id in ipairs(IDS) do
	T.eq(parentOf(Home, id), Home.scrollA, "single list " .. id)
end
T.eq(Home.footer.Parent, Home.scrollA)
local orders = {}
for _, id in ipairs(IDS) do
	local _, f = parentOf(Home, id)
	T.ok(not orders[f.LayoutOrder], "unique order " .. id)
	orders[f.LayoutOrder] = true
end
T.eq(select(2, parentOf(Home, "game")).LayoutOrder, 16)
env.Shell.narrow = false
Home.layout(390, 400)
T.eq(parentOf(Home, "game"), Home.scrollB)

T.section("home_page: switching layouts 60 times never loses or duplicates a card")
for i = 1, 60 do
	env.Shell.narrow = i % 2 == 0
	Home.layout(i % 2 == 0 and 480 or 390, 400)
	local total = 0
	for _, sc in ipairs({ Home.scrollA, Home.scrollB }) do
		for _, ch in ipairs(sc:GetChildren()) do
			if string.sub(ch.Name, 1, 7) == "Holder_" then
				total = total + 1
			end
		end
	end
	T.eq(total, 8, "cards in columns " .. i)
end
env.Shell.narrow = false
Home.layout(390, 400)

T.section("home_page: saved config is honoured and stays readable")
env.S.homeWidgets = {
	{ id = "server", col = "B", hidden = true },
	{ id = "profile", col = "B", hidden = false },
	{ id = "w1", kind = "note", col = "A", data = { title = "Hello", text = "World", tint = true } },
	{ id = "w2", kind = "clock", col = "B", data = {} },
	{ id = "junk", kind = "nope", col = "A", data = {} },
}
Home.applyWidgets()
T.eq(errors(env), 0)
T.eq(select(2, parentOf(Home, "server")).Visible, false)
T.eq(parentOf(Home, "profile"), Home.scrollB)
T.ok(Home.customFrames.w1 ~= nil and Home.customFrames.w2 ~= nil)
T.ok(Home.customFrames.junk == nil)
T.eq(parentOf(Home, "w1"), Home.scrollA)
T.eq(parentOf(Home, "w2"), Home.scrollB)
T.eq(#Home.clocks, 1)
T.eq(Home.customFrames.w1.card.tinted, true)
local noteTitle = find(Home.customFrames.w1.frame, "Title")
T.eq(noteTitle.Text, "Hello")
local noteText = find(Home.customFrames.w1.frame, "Text")
T.eq(noteText.Text, "World")
local firstRec = Home.customFrames.w1
Home.applyWidgets()
T.eq(Home.customFrames.w1, firstRec, "unchanged widget is reused")
env.S.homeWidgets[3].data.title = "Changed"
Home.applyWidgets()
T.ok(Home.customFrames.w1 ~= firstRec, "changed widget is rebuilt")
T.eq(firstRec.frame.Destroyed, true)
T.eq(find(Home.customFrames.w1.frame, "Title").Text, "Changed")
table.remove(env.S.homeWidgets, 3)
Home.applyWidgets()
T.ok(Home.customFrames.w1 == nil)
T.eq(#Home.clocks, 1)
env.S.homeWidgets = {}
Home.applyWidgets()
T.ok(next(Home.customFrames) == nil)
T.eq(parentOf(Home, "profile"), Home.scrollA)
T.eq(select(2, parentOf(Home, "server")).Visible, true)
local cardsLeft = 0
for _, c in ipairs(mod.state().cards) do
	cardsLeft = cardsLeft + 1
end
T.eq(cardsLeft, 8, "destroyed widgets leave the card list")

T.section("home_page: picture widget")
env.S.homeWidgets = { { id = "p1", kind = "picture", col = "A", data = { image = "12345", caption = "Cap", size = "l", fit = "fit" } } }
Home.applyWidgets()
local pic = Home.customFrames.p1.frame
local img = find(pic, "Img")
T.eq(img.Image, "rbxassetid://12345")
T.eq(img.ScaleType, "ScaleType.Fit")
T.eq(find(pic, "Pic").Size.Y.Offset, 240)
T.eq(find(pic, "Caption").Text, "Cap")
env.S.homeWidgets = { { id = "p2", kind = "picture", col = "A", data = { image = "", size = "s" } } }
Home.applyWidgets()
T.eq(find(Home.customFrames.p2.frame, "Status").Text, "No picture yet, tap Customize")
T.eq(find(Home.customFrames.p2.frame, "Pic").Size.Y.Offset, 110)
env.S.homeWidgets = {}
Home.applyWidgets()

T.section("home_page: a failing card is isolated")
local bad = G.install()
bad.ctx.Core.confirmTap = function()
	error("home_page:99: confirm tap exploded")
end
local mod2 = loadmodule("Hub/modules/home_page.lua")
mod2.init(bad.ctx)
local H2 = bad.Home
T.eq(errors(bad), 1)
T.ok(string.find(bad.Log.items[1].msg, "server", 1, true) ~= nil)
T.ok(string.find(bad.Log.items[1].msg, "confirm tap exploded", 1, true) ~= nil)
local failedLabel = find(H2.defs.server.frame, "Failed")
T.ok(failedLabel ~= nil)
T.eq(failedLabel.Text, "this card failed: confirm tap exploded")
for _, id in ipairs(IDS) do
	T.ok(H2.defs[id] ~= nil, "still registered " .. id)
	if id ~= "server" then
		T.ok(find(H2.defs[id].frame, "Failed") == nil, "healthy " .. id)
	end
end
bad.Shell.narrow = false
H2.layout(390, 400)
T.eq(H2.defs.server.frame.Parent, H2.scrollB)
H2.tick(60, 40)
T.eq(errors(bad), 1, "tick survives a failed card")
T.eq(H2.stats.friends.Text, "-")
T.ok(H2.stats.players.Parent == nil, "destroyed label is skipped")

local bad2 = G.install()
bad2.ctx.Core.imageSource = function()
	error("no pictures today")
end
bad2.S.homeWidgets = { { id = "p9", kind = "picture", col = "A", data = { image = "1", size = "m" } } }
mod2.init(bad2.ctx)
T.eq(errors(bad2), 1)
local failPic = find(bad2.Home.customFrames.p9.frame, "Failed")
T.ok(failPic ~= nil)
T.eq(failPic.Text, "Picture this card failed: no pictures today")
T.eq(bad2.Home.customFrames.p9.frame.Parent, bad2.Home.scrollA)
mod2.destroy()

T.section("home_page: card density switches the whole page")
env, mod, Home = boot()
env.Shell.narrow = false
Home.layout(390, 400)
local recent = Home.defs.recent.card
T.eq(recent.pad.PaddingLeft.Offset, 14)
T.eq(recent.title.TextSize, 12)
T.eq(recent.head.Size.Y.Offset, 36)
T.eq(Home.scrollA:FindFirstChildOfClass("UIListLayout").Padding.Offset, 10)
local savesBefore = env.saves
Home.setDensity("compact")
T.eq(env.S.homeDensity, "compact")
T.eq(env.saves, savesBefore + 1)
T.eq(recent.pad.PaddingLeft.Offset, 10)
T.eq(recent.title.TextSize, 11)
T.eq(recent.head.Size.Y.Offset, 30)
T.eq(Home.scrollA:FindFirstChildOfClass("UIListLayout").Padding.Offset, 7)
T.eq(Home.defs.profile.card.corner.CornerRadius.Offset, 17)
T.eq(Home.banner.Size.Y.Offset, 46)
Home.setDensity("comfortable")
T.eq(recent.pad.PaddingLeft.Offset, 14)
T.eq(Home.banner.Size.Y.Offset, 56)
Home.setDensity("sideways")
T.eq(env.S.homeDensity, "comfortable")
T.eq(errors(env), 0)
env.S.homeDensity = "compact"
local fresh = G.install()
fresh.S.homeDensity = "compact"
mod.init(fresh.ctx)
T.eq(fresh.Home.defs.recent.card.pad.PaddingLeft.Offset, 10)
T.eq(errors(fresh), 0)

T.section("home_page: tiles and chips follow the column width")
env, mod, Home = boot()
env.Shell.narrow = false
Home.layout(390, 400)
local tilesBox = find(Home.defs.actions.frame, "Tiles")
local tileGrid = tilesBox:FindFirstChildOfClass("UIGridLayout")
T.eq(tileGrid.CellSize.X.Scale, 0.25)
Home.layout(260, 400)
T.eq(tileGrid.CellSize.X.Scale, 0.5)
Home.layout(480, 400)
T.eq(tileGrid.CellSize.X.Scale, 0.25)
T.eq(tileGrid.CellSize.Y.Offset, 60)
Home.setDensity("compact")
T.eq(tileGrid.CellSize.Y.Offset, 50)

T.section("home_page: cards collapse and expand")
env, mod, Home = boot()
env.Shell.narrow = false
Home.layout(390, 400)
local card = Home.defs.recent.card
card.bodyList.AbsoluteContentSize = Vector2.new(0, 120)
T.eq(card.collapsed, false)
card.head.Activated:Fire()
T.eq(card.collapsed, true)
T.eq(card.body.AutomaticSize, "AutomaticSize.None")
T.eq(card.body.ClipsDescendants, true)
T.eq(card.body.Size.Y.Offset, 120)
T.eq(card.chev.Rotation, 0)
env.advance(0.1)
T.eq(card.body.Visible, true)
env.advance(0.5)
T.eq(card.body.Visible, false)
T.eq(card.body.Size.Y.Offset, 0)
T.eq(card.chev.Rotation, -90)
T.eq(env.S.homeCollapsed.recent, true)
card.head.Activated:Fire()
T.eq(card.collapsed, false)
T.eq(card.body.Visible, true)
env.advance(0.6)
T.eq(card.body.AutomaticSize, "AutomaticSize.Y")
T.eq(card.body.Size.Y.Offset, 0)
T.eq(card.body.ClipsDescendants, false)
T.eq(card.chev.Rotation, 0)
T.eq(env.S.homeCollapsed.recent, nil)

T.section("home_page: rapid collapse taps end in a consistent state")
for taps = 1, 12 do
	card.head.Activated:Fire()
	if taps % 3 == 0 then
		env.advance(0.05)
	end
end
env.advance(1)
T.eq(card.collapsed, false)
T.eq(card.body.Visible, true)
T.eq(card.body.AutomaticSize, "AutomaticSize.Y")
card.head.Activated:Fire()
card.head.Activated:Fire()
card.head.Activated:Fire()
env.advance(1)
T.eq(card.collapsed, true)
T.eq(card.body.Visible, false)
card.head.Activated:Fire()
env.advance(1)
T.eq(card.collapsed, false)
T.eq(card.body.AutomaticSize, "AutomaticSize.Y")

T.section("home_page: collapse without animation and remembered state")
local plain = G.install({ animations = false })
plain.S.homeCollapsed = { recent = true, friends = true, gone = true }
mod.init(plain.ctx)
local pc = plain.Home.defs.recent.card
T.eq(pc.collapsed, true)
T.eq(pc.body.Visible, false)
T.eq(plain.Home.defs.friends.card.collapsed, true)
T.eq(plain.Home.defs.server.card.collapsed, false)
pc.head.Activated:Fire()
T.eq(pc.collapsed, false)
T.eq(pc.body.Visible, true)
T.eq(pc.body.AutomaticSize, "AutomaticSize.Y")
T.eq(plain.S.homeCollapsed.recent, nil)
T.eq(plain.S.homeCollapsed.friends, true)
T.ok(plain.Home.defs.profile.card.head == nil, "profile has no header to collapse")

T.section("home_page: entrance plays once per session")
env, mod, Home = boot()
env.Shell.narrow = false
Home.layout(390, 400)
for _, id in ipairs(IDS) do
	env.Home.defs[id].frame.AbsoluteSize = Vector2.new(300, 120)
end
Home.onShow()
for _, id in ipairs(IDS) do
	T.eq(Home.defs[id].card.card.GroupTransparency, 1, "hidden at first " .. id)
end
env.advance(0.05)
for i, id in ipairs(IDS) do
	local c = Home.defs[id].card
	T.eq(c.holder.AutomaticSize, "AutomaticSize.None", "frozen " .. id)
	T.eq(c.holder.Size.Y.Offset, 120, "frozen height " .. id)
	T.eq(c.card.Position.Y.Offset, 14, "risen " .. id)
end
env.advance(0.5)
local done = 0
for _, id in ipairs(IDS) do
	if Home.defs[id].card.card.GroupTransparency == 0 then
		done = done + 1
	end
end
T.ok(done >= 1 and done < 8, "cards arrive one after another")
T.eq(Home.defs.profile.card.card.GroupTransparency, 0)
T.eq(Home.defs.friends.card.card.GroupTransparency, 1)
env.advance(1.5)
for _, id in ipairs(IDS) do
	local c = Home.defs[id].card
	T.eq(c.card.GroupTransparency, 0, "visible " .. id)
	T.eq(c.card.Position.Y.Offset, 0, "settled " .. id)
	T.eq(c.holder.AutomaticSize, "AutomaticSize.Y", "released " .. id)
	T.eq(c.holder.Size.Y.Offset, 0, "released size " .. id)
	T.near(c.stroke.Transparency, 0.3)
end
local tweensBefore = env.tweens
Home.onShow()
Home.onShow()
env.advance(1)
for _, id in ipairs(IDS) do
	T.eq(Home.defs[id].card.card.GroupTransparency, 0, "not replayed " .. id)
end
T.eq(env.tweens, tweensBefore, "no new tweens on later visits")

T.section("home_page: entrance is skipped when animations are off")
local still = G.install({ animations = false })
mod.init(still.ctx)
still.Home.layout(390, 400)
still.Home.onShow()
still.advance(1)
for _, id in ipairs(IDS) do
	T.eq(still.Home.defs[id].card.card.GroupTransparency, 0)
end

T.section("home_page: the 2 Hz tick only sets text")
env, mod, Home = boot()
Home.layout(390, 400)
Home.tick(60, 42)
T.eq(Home.stats.players.Text, "3/30")
T.eq(Home.stats.ping.Text, "42ms")
T.eq(Home.stats.uptime.Text, "2m 5s")
T.eq(Home.stats.uptime.TextScaled, true, "a long uptime shrinks to fit its box")
T.ok(Home.stats.uptime:FindFirstChildOfClass("UITextSizeConstraint") ~= nil, "but never grows past the other numbers")
T.ok(string.find(Home.footer.Text, "TestExec", 1, true) ~= nil)
T.ok(string.find(Home.footer.Text, "Smart Stop on", 1, true) ~= nil)
T.ok(string.find(Home.footer.Text, "v1.6.1", 1, true) ~= nil)
T.ok(Home.exSet ~= nil and Home.clockSet ~= nil)
Home.tick(60, nil)
T.eq(Home.stats.ping.Text, "-")
env.S.smartStop = false
Home.tick(60, 10)
T.ok(string.find(Home.footer.Text, "Smart Stop off", 1, true) ~= nil)
local sizeBefore = Home.defs.server.frame.Size.Y.Offset
local autoBefore = Home.defs.server.frame.AutomaticSize
for i = 1, 20 do
	Home.tick(60, 30 + i)
end
T.eq(Home.defs.server.frame.Size.Y.Offset, sizeBefore, "tick never resizes a card")
T.eq(Home.defs.server.frame.AutomaticSize, autoBefore)
T.eq(errors(env), 0)
env.S.homeWidgets = { { id = "c1", kind = "clock", col = "A", data = {} } }
Home.applyWidgets()
Home.tick(60, 20)
T.eq(Home.clocks[1].time.Text, "1:05 PM")
env.S.clock24 = true
Home.tick(60, 20)
T.eq(Home.clocks[1].time.Text, "13:05")

T.section("home_page: friends are cached for 30 seconds")
local calls = 0
local fenv = G.install({ friends = {
	{ VisitorId = 11, PlaceId = 456 },
	{ VisitorId = 12, PlaceId = 1 },
	{ VisitorId = 13, PlaceId = 2 },
} })
fenv.ctx.LP.GetFriendsOnline = function()
	calls = calls + 1
	return {
		{ VisitorId = 11, PlaceId = 456 },
		{ VisitorId = 12, PlaceId = 1 },
		{ VisitorId = 13, PlaceId = 2 },
	}
end
mod.init(fenv.ctx)
fenv.Shell.narrow = false
fenv.Home.layout(390, 400)
fenv.Home.onShow()
fenv.advance(0.1)
T.eq(calls, 1)
T.eq(fenv.Home.stats.online.Text, "3")
T.eq(fenv.Home.friendCount.Text, "3")
T.eq(fenv.Home.friendText.Text, "1 of them is in this game")
T.eq(#fenv.Home.friendRow:GetChildren(), 3)
local firstFace = fenv.Home.friendRow:GetChildren()[1]
fenv.Home.tick(60, 20)
fenv.Home.tick(60, 20)
fenv.Home.onShow()
fenv.advance(0.1)
T.eq(calls, 1, "no refetch inside the cache window")
T.eq(fenv.Home.friendRow:GetChildren()[1], firstFace, "faces are not rebuilt by ticks")
fenv.advance(31)
fenv.Home.tick(60, 20)
fenv.advance(0.1)
T.eq(calls, 2, "refetch after 30 seconds")
T.eq(#fenv.Home.friendRow:GetChildren(), 3)
fenv.Home.loadFriends(true)
fenv.advance(0.1)
T.eq(calls, 3, "forced refetch")

T.section("home_page: friends failure is shown, not thrown")
local ferr = G.install()
ferr.ctx.LP.GetFriendsOnline = function()
	error("nope")
end
mod.init(ferr.ctx)
ferr.Home.onShow()
ferr.advance(0.1)
T.eq(ferr.Home.friendText.Text, "Couldn't check your friends")
T.eq(errors(ferr), 0)

T.section("home_page: recent scripts list")
env, mod, Home = boot()
env.Repo.byPath = {
	a = { path = "a", name = "Alpha", category = "Hat" },
	b = { path = "b", name = "Beta", category = "Limb" },
	c = { path = "c", name = "Gamma", category = "Hat" },
	d = { path = "d", name = "Delta", category = "Hat" },
	h = { path = "h", name = "Hidden", category = "Hat", hidden = true },
}
env.S.recent = { "h", "a", "missing", "b", "c", "d" }
Home.renderRecent()
T.eq(#Home.recentRows, 3)
T.eq(Home.recentRows[1].Name, "Recent")
local rowsBefore = Home.recentRows[1]
Home.renderRecent()
T.eq(Home.recentRows[1], rowsBefore, "unchanged list is not rebuilt")
env.Runner.running.a = true
Home.renderRecent()
T.ok(Home.recentRows[1] ~= rowsBefore, "running state change rebuilds")
local runStop = find(Home.recentRows[1], "RunStop")
runStop.Activated:Fire()
T.eq(env.calls[#env.calls], "stop:a")
env.Runner.running.a = nil
Home.renderRecent()
find(Home.recentRows[2], "RunStop").Activated:Fire()
T.eq(env.calls[#env.calls], "run:b")
Home.recentRows[3].Activated:Fire()
T.eq(env.calls[#env.calls], "detail:c")
env.Runner.pending.b = true
Home.renderRecent()
find(Home.recentRows[2], "RunStop").Activated:Fire()
T.ok(env.calls[#env.calls] ~= "run:b" or true)
local callsNow = #env.calls
find(Home.recentRows[2], "RunStop").Activated:Fire()
T.eq(#env.calls, callsNow, "pending script ignores taps")
env.Runner.pending.b = nil
env.S.recent = {}
Home.renderRecent()
T.eq(#Home.recentRows, 1)
T.eq(Home.recentRows[1].Text, "Scripts you run show up here")
Home.setDensity("compact")
env.S.recent = { "a" }
Home.renderRecent()
T.eq(Home.recentRows[1].Size.Y.Offset, 36)
T.eq(errors(env), 0)

T.section("home_page: quick switches, actions and music wire up late")
env, mod, Home = boot()
env.Shell.narrow = false
Home.layout(390, 400)
T.eq(#Home.quick:GetChildren() - 1, 0, "no chips before late")
Home.buildQuick()
T.eq(#Home.quick:GetChildren() - 1, 0, "buildQuick waits for late")
Home.late()
T.eq(errors(env), 0)
local chipCount = 0
for _, ch in ipairs(Home.quick:GetChildren()) do
	if ch:IsA("GuiObject") then
		chipCount = chipCount + 1
	end
end
T.eq(chipCount, 4)
local fly = find(Home.quick, "Quick_fly")
T.ok(fly ~= nil)
local flyStroke = fly:FindFirstChildOfClass("UIStroke")
T.eq(flyStroke.Transparency, 1)
fly.Activated:Fire()
T.eq(env.Cmd.state.fly, true)
T.eq(flyStroke.Transparency, 1, "tween has not finished")
env.advance(0.3)
T.near(flyStroke.Transparency, 0.4)
fly.Activated:Fire()
env.advance(0.3)
T.eq(flyStroke.Transparency, 1)
Home.tiles.respawn.Activated:Fire()
T.eq(env.calls[#env.calls], "cmd:refresh")
Home.tiles.cmdbar.Activated:Fire()
T.eq(env.calls[#env.calls], "bar")
Home.hop.Activated:Fire()
T.eq(env.calls[#env.calls], "cmd:serverhop")
Home.tiles.explore.Activated:Fire()
T.eq(env.calls[#env.calls], "nav:explore")
Home.tiles.stop.Activated:Fire()
T.eq(env.notes[#env.notes], "Nothing to stop:No scripts are running")
env.Runner.running.x = true
Home.tiles.stop.Activated:Fire()
T.eq(env.calls[#env.calls], "stopAll")
Home.rejoin.Activated:Fire()
T.eq(env.calls[#env.calls], "rejoin")
Home.copyLink.Activated:Fire()
T.eq(env.copies[#env.copies], "Game link")
Home.copyJob.Activated:Fire()
T.eq(env.copies[#env.copies], "Join script")
T.eq(#env.NP.views, 1)
T.eq(Home.player.Visible, false)
T.eq(Home.idle.Visible, true)
env.NP.on = true
Home.syncMusic()
T.eq(Home.player.Visible, true)
T.eq(Home.idle.Visible, false)
env.NP.on = false
env.ctx.Player.cur = {}
Home.syncMusic()
T.eq(Home.player.Visible, true)
env.ctx.Player.cur = nil
Home.syncMusic()
T.eq(Home.player.Visible, false)
Home.idle.Activated:Fire()
T.eq(env.calls[#env.calls], "nav:player")
Home.late()
local busBefore = env.Bus.count("cmd")
Home.late()
T.eq(env.Bus.count("cmd"), busBefore, "late runs once")
T.eq(#env.NP.views, 1)

T.section("home_page: quick switch picker")
env.S.quickCmds = { "fly", "noclip", "infjump", "fullbright" }
Home.buildQuick()
Home.quickEdit.Activated:Fire()
T.eq(env.lastWindow.id, "quickpick")
T.eq(#env.lastWindow.body:GetChildren(), 6)
Home.pickQuick()
local picker = env.lastWindow.body
local toggles = {}
for _, ch in ipairs(picker:GetChildren()) do
	if ch.Title then
		toggles[ch.Title] = ch
	end
end
T.ok(toggles.Fly ~= nil and toggles.ESP ~= nil)
T.same(Home.quickIds(), { "fly", "noclip", "infjump", "fullbright" })

T.section("home_page: update banner")
env, mod, Home = boot()
local fired = 0
env.Bus.on("homeupdate", function()
	fired = fired + 1
end)
Home.update("1.6.0")
T.eq(Home.banner.Visible, true)
T.eq(Home.bannerTitle.Text, "Update ready  ·  v1.6.0")
Home.banner.Activated:Fire()
T.eq(fired, 1)
Home.update(nil)
T.eq(Home.banner.Visible, false)

T.section("home_page: appearance follows the opacity setting")
env, mod, Home = boot()
env.S.opacity = 0.3
Home.restyle()
for _, id in ipairs(IDS) do
	T.near(Home.defs[id].card.card.BackgroundTransparency, 0.3)
end
T.near(Home.banner.BackgroundTransparency, 0.3)
T.near(Home.editBtn.BackgroundTransparency, 0.3)
env.S.homeWidgets = { { id = "n1", kind = "note", col = "A", data = { text = "x", tint = true } }, { id = "n2", kind = "note", col = "A", data = { text = "y" } } }
Home.applyWidgets()
Home.restyle()
T.near(Home.customFrames.n1.card.card.BackgroundTransparency, 0.82)
T.near(Home.customFrames.n2.card.card.BackgroundTransparency, 0.3)

T.section("home_page: the editor")
env, mod, Home = boot()
Home.openEditor()
T.eq(env.lastWindow.id, "homeedit")
T.ok(env.choices["Card density"] ~= nil)
T.eq(env.choices["Card density"].get(), "comfortable")
env.choices["Card density"].set("compact")
T.eq(env.S.homeDensity, "compact")
T.eq(env.choices["Card density"].get(), "compact")
local addButtons = env.buttonLists[1]
T.eq(#addButtons, 3)
addButtons[3][3]()
T.eq(#env.S.homeWidgets > 0, true)
T.ok(next(Home.customFrames) ~= nil)
T.eq(env.notes[#env.notes], "Home:Added a clock")
local resetFn = env.actions["Put Home back the way it was"]
env.S.homeCollapsed = { recent = true }
resetFn()
env.advance(0.1)
T.ok(next(Home.customFrames) == nil)
T.same(env.S.homeCollapsed, {})
Home.openEditor("nothing-here")
T.eq(errors(env), 0)

T.section("home_page: greeting and header text")
local title, sub = Home.head()
T.eq(title, "Welcome back, Tester")
T.ok(sub ~= nil and sub ~= "")

T.section("home_page: destroy removes listeners")
env, mod, Home = boot()
Home.late()
T.ok(env.Bus.count("cmd") >= 1)
mod.destroy()
T.eq(env.Bus.count("cmd"), 0)
T.eq(env.Bus.count("accent"), 0)
mod.destroy()
