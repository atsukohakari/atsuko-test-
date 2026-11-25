local Module = {}

local IDS = { "profile", "nowplaying", "quick", "actions", "recent", "game", "server", "friends" }
local DEFS = {
	profile = { name = "Your profile", col = "A", noHead = true },
	nowplaying = { name = "Now playing", col = "A", icon = "music" },
	quick = { name = "Quick switches", col = "A" },
	actions = { name = "Quick actions", col = "A" },
	recent = { name = "Recent scripts", col = "A", icon = "history" },
	game = { name = "This game", col = "B", noHead = true },
	server = { name = "This server", col = "B", icon = "activity" },
	friends = { name = "Friends online", col = "B" },
}
local KINDS = { picture = "Picture", note = "Note", clock = "Clock" }
local KIND_ICONS = { picture = "image", note = "notebook-text", clock = "clock" }
local KIND_SET = { picture = true, note = true, clock = true }
local PIC_SIZES = { s = 110, m = 170, l = 240 }
local QUICK_MAX = 4
local RECENT_MAX = 3
local MAX_WIDGETS = 12

local M = { alive = false, bus = {}, cards = {}, clocks = {}, quickChips = {} }
local ctx, UI, T, S, Home, Layout

local function now()
	if type(time) == "function" then
		local ok, t = pcall(time)
		if ok and type(t) == "number" then
			return t
		end
	end
	return os.clock()
end

local function hourNow()
	local ok, h = pcall(os.date, "%H")
	return ok and tonumber(h) or 12
end

local function density()
	return Layout.density(S.homeDensity)
end

local function listen(name, fn)
	ctx.Bus.on(name, fn)
	M.bus[#M.bus + 1] = { name, fn }
end

local function alive(o)
	return o ~= nil and o.Parent ~= nil
end

local function setText(label, text)
	if alive(label) and label.Text ~= text then
		label.Text = text
	end
end

local function clearChildren(parent)
	for _, c in ipairs(parent:GetChildren()) do
		if c:IsA("GuiObject") then
			c:Destroy()
		end
	end
end

local function save()
	pcall(ctx.saveSettings)
end

local setCollapsed

local function newCard(id, title, icon, noHead, parent)
	local d = density()
	local holder = UI.new("Frame", {
		Name = "Holder_" .. id,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
	}, parent or Home.scrollA)
	local card = UI.new("CanvasGroup", {
		Name = "Card",
		BackgroundColor3 = T.panel or T.card,
		BackgroundTransparency = tonumber(S.opacity) or 0,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Position = UDim2.new(0, 0, 0, 0),
		GroupTransparency = 0,
	}, holder)
	local rec = { id = id, holder = holder, card = card, collapsed = false, tok = 0, tinted = false }
	rec.corner = UI.corner(card, d.corner)
	rec.stroke = UI.stroke(card, T.stroke, 1, 0.3)
	rec.pad = UI.pad(card, d.pad, d.pad, d.pad, d.pad)
	rec.list = UI.list(card, 6)
	if not noHead then
		local head = UI.button(card, { Name = "Head", BackgroundTransparency = 1, Text = "", Size = UDim2.new(1, 0, 0, d.header), LayoutOrder = 1 })
		rec.head = head
		rec.title = UI.label(head, {
			Name = "Title",
			Text = title,
			Font = ctx.FONT_B,
			TextSize = d.title,
			TextColor3 = T.text,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
			Size = UDim2.new(1, -40, 1, 0),
		})
		if icon then
			rec.icon = UI.icon(icon, 13, T.dim, head, { Name = "TitleIcon", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0) })
		end
		rec.chev = UI.icon("chevron-down", 12, T.dim, head, { Name = "Chev", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Rotation = 0, Visible = false })
		head.Activated:Connect(function()
			setCollapsed(rec, not rec.collapsed)
		end)
	end
	rec.body = UI.new("Frame", {
		Name = "Body",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = 2,
	}, card)
	rec.bodyList = UI.list(rec.body, 8)
	M.cards[#M.cards + 1] = rec
	return rec
end

local function dropCard(rec)
	for i = #M.cards, 1, -1 do
		if M.cards[i] == rec then
			table.remove(M.cards, i)
		end
	end
	if rec.holder then
		rec.holder:Destroy()
	end
end

local function guard(rec, prefix, fn)
	local ok, err = pcall(fn, rec)
	if ok then
		return true
	end
	ctx.Log.add("error", "Home", rec.id .. " card: " .. tostring(err))
	clearChildren(rec.body)
	rec.failed = true
	UI.label(rec.body, {
		Name = "Failed",
		Text = (prefix and (prefix .. " ") or "") .. Layout.failText(err),
		TextSize = 11,
		TextColor3 = T.yellow or T.sub,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		Size = UDim2.new(1, 0, 0, 30),
	})
	return false
end

setCollapsed = function(rec, want, instant)
	if not rec.head then
		return
	end
	rec.collapsed = want == true
	rec.tok += 1
	local my = rec.tok
	if type(S.homeCollapsed) ~= "table" then
		S.homeCollapsed = {}
	end
	if not instant then
		S.homeCollapsed[rec.id] = rec.collapsed or nil
		save()
	end
	local body = rec.body
	local animate = S.animations and not instant
	local t = Layout.COLLAPSE_TIME
	if rec.collapsed then
		local h = rec.bodyList.AbsoluteContentSize.Y
		body.AutomaticSize = Enum.AutomaticSize.None
		body.ClipsDescendants = true
		body.Size = UDim2.new(1, 0, 0, h)
		if animate then
			UI.tween(rec.chev, t, { Rotation = -90 })
			UI.done(UI.tween(body, t, { Size = UDim2.new(1, 0, 0, 0) }), function()
				if rec.tok == my and rec.collapsed then
					body.Visible = false
				end
			end)
		else
			UI.tween(rec.chev, 0, { Rotation = -90 })
			UI.tween(body, 0, { Size = UDim2.new(1, 0, 0, 0) })
			body.Visible = false
		end
		return
	end
	body.Visible = true
	local function release()
		if rec.tok == my and not rec.collapsed then
			body.AutomaticSize = Enum.AutomaticSize.Y
			body.Size = UDim2.new(1, 0, 0, 0)
			body.ClipsDescendants = false
		end
	end
	if animate then
		local h = rec.bodyList.AbsoluteContentSize.Y
		body.AutomaticSize = Enum.AutomaticSize.None
		body.ClipsDescendants = true
		UI.tween(rec.chev, t, { Rotation = 0 })
		UI.done(UI.tween(body, t, { Size = UDim2.new(1, 0, 0, h) }), release)
	else
		UI.tween(rec.chev, 0, { Rotation = 0 })
		UI.tween(body, 0, { Size = UDim2.new(1, 0, 0, 0) })
		release()
	end
end

local function statRow(parent, order)
	local row = UI.new("Frame", { Name = "Stats", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, density().stat), LayoutOrder = order }, parent)
	M.statRows[#M.statRows + 1] = row
	return row
end

local function stat(parent, label, i)
	local d = density()
	local f = UI.new("Frame", {
		Name = "Stat",
		BackgroundTransparency = 1,
		Size = UDim2.new(1 / 3, -4, 1, 0),
		Position = UDim2.new((i - 1) / 3, (i - 1) * 2, 0, 0),
		LayoutOrder = i,
	}, parent)
	local value = UI.label(f, { Name = "Value", Text = "-", Font = ctx.FONT_B, TextSize = d.big - 3, TextColor3 = T.text, Size = UDim2.new(1, 0, 0, d.big), TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd })
	UI.label(f, { Name = "Label", Text = string.upper(label), Font = ctx.FONT_B, TextSize = 8, TextColor3 = T.dim, Position = UDim2.fromOffset(0, d.big + 1), Size = UDim2.new(1, 0, 0, 11), TextXAlignment = Enum.TextXAlignment.Left })
	return value
end

local function pill(parent, name, icon, text, pos, size)
	local b = UI.button(parent, { Name = name, Text = "", BackgroundColor3 = T.card, Size = size, Position = pos })
	UI.corner(b, 13)
	local ic = UI.icon(icon, 13, T.text, b, { Name = "Icon", AnchorPoint = Vector2.new(0, 0.5) })
	local label = UI.label(b, { Name = "Label", Text = text, Font = ctx.FONT_B, TextSize = 11, TextColor3 = T.text, TextXAlignment = Enum.TextXAlignment.Left, AnchorPoint = Vector2.new(0, 0.5), Size = UDim2.new(1, -40, 0, 14) })
	local function place()
		local w = math.min(math.ceil(ctx.textWidth(label.Text, 11, ctx.FONT_B)), 200)
		local left = -math.floor((w + 19) / 2)
		ic.Position = UDim2.new(0.5, left, 0.5, 0)
		label.Position = UDim2.new(0.5, left + 19, 0.5, 0)
		label.Size = UDim2.fromOffset(w + 2, 14)
	end
	place()
	UI.onHover(b, function(on)
		UI.tween(b, 0.15, { BackgroundColor3 = on and (T.card2 or T.card) or T.card })
	end)
	return b, function(t, _, color)
		label.Text = t
		if color then
			label.TextColor3 = color
			ic.ImageColor3 = color
		end
		place()
	end
end

local function pillRow(parent, order, list)
	local row = UI.new("Frame", { Name = "Buttons", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 30), LayoutOrder = order }, parent)
	local out, sets = {}, {}
	local n = #list
	for i, it in ipairs(list) do
		out[i], sets[i] = pill(row, it[1], it[2], it[3], UDim2.new((i - 1) / n, (i - 1) * 6 / n, 0, 0), UDim2.new(1 / n, -(n - 1) * 6 / n, 1, 0))
	end
	return out, sets
end

local BUILD = {}

function BUILD.profile(rec)
	local d = density()
	local LP = ctx.LP
	local top = UI.new("Frame", { Name = "Top", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, d.avatar), LayoutOrder = 1 }, rec.body)
	local ring = UI.new("Frame", { Name = "Ring", BackgroundColor3 = ctx.accentColor(), Size = UDim2.fromOffset(d.avatar, d.avatar) }, top)
	UI.corner(ring, math.floor(d.avatar / 2))
	UI.accent(ring, "BackgroundColor3")
	local inner = d.avatar - 6
	local av = UI.new("ImageLabel", {
		Name = "Avatar",
		BackgroundColor3 = T.card2 or T.card,
		Size = UDim2.fromOffset(inner, inner),
		Position = UDim2.fromOffset(3, 3),
		ScaleType = Enum.ScaleType.Crop,
		Image = "rbxthumb://type=AvatarHeadShot&id=" .. tostring(LP.UserId) .. "&w=150&h=150",
	}, ring)
	UI.corner(av, math.floor(inner / 2))
	if type(ctx.Core.myPicTargets) ~= "table" then
		ctx.Core.myPicTargets = {}
	end
	table.insert(ctx.Core.myPicTargets, av)
	Home.avatar = av
	local version = tostring(ctx.Core.VTAG or "v") .. tostring(ctx.HUB_VERSION)
	local chipW = math.ceil(ctx.textWidth(version, 10, ctx.FONT_B)) + 18
	local chip = UI.new("Frame", { Name = "Version", BackgroundColor3 = T.card2 or T.card, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 2), Size = UDim2.fromOffset(chipW, 20) }, top)
	UI.corner(chip, 10)
	local ver = UI.label(chip, { Name = "Text", Text = version, Font = ctx.FONT_B, TextSize = 10, TextColor3 = ctx.accentColor(), TextXAlignment = Enum.TextXAlignment.Center, Size = UDim2.fromScale(1, 1) })
	UI.accent(ver, "TextColor3")
	Home.version = ver
	local x = d.avatar + 12
	local nameSize = d.big - 4
	local nameY = math.max(0, math.floor((d.avatar - (nameSize + 4) - 18) / 2))
	local nameW = UDim2.new(1, -x - chipW - 8, 0, nameSize + 4)
	UI.label(top, { Name = "Display", Text = tostring(LP.DisplayName), Font = ctx.FONT_B, TextSize = nameSize, TextColor3 = T.text, Position = UDim2.fromOffset(x, nameY), Size = nameW, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd })
	if type(ctx.Core.userBadge) == "function" then
		local tw = math.min(math.ceil(ctx.textWidth(tostring(LP.DisplayName), nameSize, ctx.FONT_B)), 200)
		local bs = math.floor(nameSize * 0.9)
		local badge = ctx.Core.userBadge(top, bs, { Position = UDim2.fromOffset(x + tw + 5, nameY + math.floor((nameSize + 4 - bs) / 2)), Visible = S.verifiedBadge == true })
		listen("verifiedBadge", function()
			if alive(badge) then
				badge.Visible = S.verifiedBadge == true
			end
		end)
	end
	UI.label(top, { Name = "User", Text = "@" .. tostring(LP.Name), TextSize = d.small, TextColor3 = T.sub, Position = UDim2.fromOffset(x, nameY + nameSize + 6), Size = UDim2.new(1, -x, 0, 14), TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd })
	local row = statRow(rec.body, 2)
	Home.stats.friends = stat(row, "friends", 1)
	Home.stats.online = stat(row, "online", 2)
	Home.stats.days = stat(row, "days old", 3)
	local age = math.floor(tonumber(LP.AccountAge) or 0)
	Home.stats.days.Text = tostring(age)
	local okJ, joined = pcall(os.date, "%B %Y", os.time() - age * 86400)
	Home.joined = UI.label(rec.body, { Name = "Joined", Text = "On Roblox since " .. tostring(okJ and joined or "a while"), TextSize = 10, TextColor3 = T.dim, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, Size = UDim2.new(1, 0, 0, 13), LayoutOrder = 3 })
	task.spawn(function()
		local ok, count = pcall(function()
			local pages = ctx.Players:GetFriendsAsync(LP.UserId)
			local total = 0
			for _ = 1, 8 do
				total += #pages:GetCurrentPage()
				if pages.IsFinished then
					break
				end
				pages:AdvanceToNextPageAsync()
			end
			return total
		end)
		if ok and type(count) == "number" and M.alive then
			setText(Home.stats.friends, tostring(count))
		end
	end)
end

function BUILD.nowplaying(rec)
	Home.player = UI.new("Frame", { Name = "Player", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 64), Visible = false, LayoutOrder = 1 }, rec.body)
	Home.idle = UI.button(rec.body, { Name = "Idle", Text = "", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 52), LayoutOrder = 2 })
	local art = UI.new("Frame", { Name = "Art", BackgroundColor3 = T.card2 or T.card, Size = UDim2.fromOffset(44, 44), Position = UDim2.fromOffset(0, 4) }, Home.idle)
	UI.corner(art, 10)
	UI.icon("music", 18, T.dim, art, { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5) })
	UI.label(Home.idle, { Name = "Title", Text = "Nothing playing", Font = ctx.FONT_B, TextSize = 12, TextColor3 = T.text, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, Position = UDim2.fromOffset(56, 8), Size = UDim2.new(1, -104, 0, 16) })
	UI.label(Home.idle, { Name = "Sub", Text = "Pick a song from your library", TextSize = 10, TextColor3 = T.sub, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, Position = UDim2.fromOffset(56, 26), Size = UDim2.new(1, -104, 0, 14) })
	local play = UI.button(Home.idle, { Name = "Open", Text = "", BackgroundColor3 = T.text, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -4, 0.5, 0), Size = UDim2.fromOffset(34, 34) })
	UI.corner(play, 17)
	UI.icon("play-fill", 14, T.ink, play, { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 1, 0.5, 0) })
	play.Activated:Connect(function()
		ctx.Panel.nav("player")
	end)
	Home.idle.Activated:Connect(function()
		ctx.Panel.nav("player")
	end)
end

function BUILD.quick(rec)
	local d = density()
	Home.quickW = rec.body
	Home.quick = UI.new("Frame", { Name = "Quick", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = 1 }, rec.body)
	M.quickGrid = UI.new("UIGridLayout", { CellSize = UDim2.new(0.5, -4, 0, d.pill), CellPadding = UDim2.fromOffset(8, 8), SortOrder = Enum.SortOrder.LayoutOrder }, Home.quick)
	Home.quickEdit = UI.button(rec.head, { Name = "Edit", Text = "", BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 6, 0.5, 0), Size = UDim2.fromOffset(28, 28) })
	UI.icon("layout-grid", 13, T.dim, Home.quickEdit, { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5) })
	Home.quickEdit.Activated:Connect(function()
		Module.pickQuick()
	end)
end

local function cmdRun(name)
	local Cmd = ctx.Cmd
	if Cmd then
		Cmd.run(name)
	end
end

function BUILD.actions(rec)
	local d = density()
	local tiles = UI.new("Frame", { Name = "Tiles", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = 1 }, rec.body)
	M.tileGrid = UI.new("UIGridLayout", { CellSize = UDim2.new(0.25, -6, 0, d.tile), CellPadding = UDim2.fromOffset(8, 8), SortOrder = Enum.SortOrder.LayoutOrder }, tiles)
	local list = {
		{ "stop", "square-fill", "Stop all", T.red },
		{ "respawn", "refresh-cw", "Respawn", T.blue },
		{ "cmdbar", "command", "Cmd bar", T.violet },
		{ "explore", "code", "Scripts", T.green },
	}
	for i, t in ipairs(list) do
		local color = t[4] or ctx.accentColor()
		local b = UI.button(tiles, { Name = "Tile_" .. t[1], Text = "", BackgroundColor3 = color, BackgroundTransparency = 0.84, LayoutOrder = i })
		UI.corner(b, 14)
		UI.stroke(b, color, 1, 0.7)
		UI.icon(t[2], 16, color, b, { Name = "Icon", Position = UDim2.fromOffset(10, 10) })
		UI.label(b, { Name = "Label", Text = t[3], Font = ctx.FONT_B, TextSize = d.small, TextColor3 = T.text, TextXAlignment = Enum.TextXAlignment.Left, AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 10, 1, -8), Size = UDim2.new(1, -14, 0, 14), TextTruncate = Enum.TextTruncate.AtEnd })
		UI.onHover(b, function(on)
			UI.tween(b, 0.15, { BackgroundTransparency = on and 0.74 or 0.84 })
		end)
		Home.tiles[t[1]] = b
	end
	Home.tiles.stop.Activated:Connect(function()
		if ctx.Runner.count() == 0 then
			ctx.notify("Nothing to stop", "No scripts are running")
		else
			ctx.Runner.stopAll()
		end
	end)
	Home.tiles.respawn.Activated:Connect(function()
		cmdRun("refresh")
	end)
	Home.tiles.cmdbar.Activated:Connect(function()
		if ctx.Cmd then
			ctx.Cmd.openBar(true)
		end
	end)
	Home.tiles.explore.Activated:Connect(function()
		ctx.Panel.nav("explore")
	end)
end

function BUILD.recent(rec)
	Home.recentBox = UI.new("Frame", { Name = "List", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = 1 }, rec.body)
	UI.list(Home.recentBox, 6)
end

function BUILD.game(rec)
	local d = density()
	local hero = UI.new("Frame", { Name = "Hero", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 148), LayoutOrder = 1 }, rec.body)
	local banner = UI.new("ImageLabel", {
		Name = "Banner",
		BackgroundColor3 = T.card2 or T.card,
		Size = UDim2.new(1, 0, 0, 92),
		ScaleType = Enum.ScaleType.Crop,
		Image = "rbxthumb://type=GameIcon&id=" .. tostring(game.GameId) .. "&w=512&h=512",
		ImageTransparency = 0.35,
	}, hero)
	UI.corner(banner, 14)
	local fade = UI.new("Frame", { Name = "Fade", BackgroundColor3 = T.panel or T.card, BorderSizePixel = 0, Size = UDim2.fromScale(1, 1) }, banner)
	UI.corner(fade, 14)
	pcall(function()
		UI.new("UIGradient", { Rotation = 90, Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.55, 0.75), NumberSequenceKeypoint.new(1, 0.05) }) }, fade)
	end)
	Home.gameBanner = banner
	local icon = UI.new("ImageLabel", { Name = "Icon", BackgroundColor3 = T.card2 or T.card, Position = UDim2.fromOffset(10, 60), Size = UDim2.fromOffset(46, 46), Image = "rbxthumb://type=GameIcon&id=" .. tostring(game.GameId) .. "&w=150&h=150" }, hero)
	UI.corner(icon, 12)
	UI.stroke(icon, T.panel or T.card, 2, 0)
	Home.gameName = UI.label(hero, { Name = "Name", Text = "This game", Font = ctx.FONT_B, TextSize = d.body + 2, TextColor3 = T.text, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, Position = UDim2.fromOffset(2, 112), Size = UDim2.new(1, -4, 0, 18) })
	Home.gameSub = UI.label(hero, { Name = "Sub", Text = "Place " .. tostring(game.PlaceId), TextSize = 10, TextColor3 = T.sub, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, Position = UDim2.fromOffset(2, 131), Size = UDim2.new(1, -4, 0, 14) })
	local b = pillRow(rec.body, 2, { { "CopyLink", "link", "Copy link" }, { "CopyJob", "copy", "Join script" } })
	Home.copyLink, Home.copyJob = b[1], b[2]
	Home.copyLink.Activated:Connect(function()
		ctx.copyText("https://www.roblox.com/games/" .. tostring(game.PlaceId), "Game link")
	end)
	Home.copyJob.Activated:Connect(function()
		ctx.copyText(string.format('game:GetService("TeleportService"):TeleportToPlaceInstance(%d, "%s", game:GetService("Players").LocalPlayer)', game.PlaceId, tostring(game.JobId)), "Join script")
	end)
	task.spawn(function()
		local ok, info = pcall(function()
			return game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId)
		end)
		if ok and type(info) == "table" and M.alive then
			setText(Home.gameName, tostring(info.Name or "This game"))
			local creator = type(info.Creator) == "table" and info.Creator.Name or nil
			if creator then
				setText(Home.gameSub, "By " .. tostring(creator) .. "  ·  Place " .. tostring(game.PlaceId))
			end
		end
	end)
end

function BUILD.server(rec)
	local row = statRow(rec.body, 1)
	Home.stats.players = stat(row, "players", 1)
	Home.stats.ping = stat(row, "ping", 2)
	Home.stats.uptime = stat(row, "uptime", 3)
	Home.stats.uptime.TextScaled = true
	UI.new("UITextSizeConstraint", { MaxTextSize = density().big - 3, MinTextSize = 8 }, Home.stats.uptime)
	local b, sets = pillRow(rec.body, 2, { { "Rejoin", "rotate-ccw", "Rejoin" }, { "Hop", "shuffle", "Server hop" } })
	Home.rejoin, Home.hop = b[1], b[2]
	local setRejoin = sets[1]
	Home.rejoin.Activated:Connect(ctx.Core.confirmTap(function(text, armed)
		setRejoin(armed and "Sure?" or text, nil, armed and T.yellow or T.text)
	end, "Rejoin", function()
		ctx.Core.rejoin()
	end))
	Home.hop.Activated:Connect(function()
		cmdRun("serverhop")
	end)
end

function BUILD.friends(rec)
	local d = density()
	Home.friendCount = UI.label(rec.head, { Name = "Count", Text = "", Font = ctx.FONT_B, TextSize = 12, TextColor3 = T.sub, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.fromOffset(40, 16), TextXAlignment = Enum.TextXAlignment.Right })
	Home.friendRow = UI.new("Frame", { Name = "Faces", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, d.face), LayoutOrder = 1 }, rec.body)
	Home.friendText = UI.label(rec.body, { Name = "Line", Text = "Checking your friends...", TextSize = 10, TextColor3 = T.sub, TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true, Size = UDim2.new(1, 0, 0, 16), LayoutOrder = 2 })
end

local function imageReady()
	return type(ctx.Core.imageSource) == "function"
end

local function widgetSig(e)
	return ctx.jsonEncode({ kind = e.kind, data = e.data, ready = e.kind == "picture" and imageReady() or nil })
end

local function buildWidget(entry)
	local data = entry.data or {}
	local kind = entry.kind
	local title = KINDS[kind]
	if kind == "note" and type(data.title) == "string" and data.title ~= "" then
		title = data.title
	end
	local rec = newCard(entry.id, title, KIND_ICONS[kind])
	rec.kind = kind
	rec.custom = true
	rec.tinted = kind == "note" and data.tint == true
	guard(rec, KINDS[kind], function()
		local d = density()
		if kind == "note" then
			UI.label(rec.body, { Name = "Text", Text = tostring(data.text or ""), TextSize = d.body, TextColor3 = T.text, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = 1 })
		elseif kind == "clock" then
			local label = UI.label(rec.body, { Name = "Time", Text = ctx.Util.shortTime(S.clock24), Font = ctx.FONT_B, TextSize = d.big + 8, TextColor3 = T.text, TextXAlignment = Enum.TextXAlignment.Center, Size = UDim2.new(1, 0, 0, d.big + 14), LayoutOrder = 1 })
			M.clocks[#M.clocks + 1] = { time = label, id = entry.id }
		elseif kind == "picture" then
			local d2 = density()
			local box = UI.new("Frame", { Name = "Pic", BackgroundColor3 = T.card2 or T.card, Size = UDim2.new(1, 0, 0, PIC_SIZES[data.size] or PIC_SIZES.m), ClipsDescendants = true, LayoutOrder = 1 }, rec.body)
			UI.corner(box, 12)
			local raw = type(data.image) == "string" and data.image or ""
			local src, status = nil, "No picture yet, tap Customize"
			if raw ~= "" then
				if imageReady() then
					src = ctx.Core.imageSource(raw)
					status = "That picture can't be shown here, try a Roblox image ID"
				else
					status = "Loading picture..."
				end
			end
			local img = UI.new("ImageLabel", {
				Name = "Img",
				BackgroundTransparency = 1,
				Size = UDim2.fromScale(1, 1),
				ScaleType = data.fit == "fit" and Enum.ScaleType.Fit or Enum.ScaleType.Crop,
				Image = src or "",
				Visible = src ~= nil,
			}, box)
			UI.corner(img, 12)
			if not src then
				UI.label(box, { Name = "Status", Text = status, TextSize = d2.small, TextColor3 = T.sub, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Center, Size = UDim2.fromScale(1, 1) })
			end
			if type(data.caption) == "string" and data.caption ~= "" then
				UI.label(rec.body, { Name = "Caption", Text = data.caption, TextSize = d2.small, TextColor3 = T.sub, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.new(1, 0, 0, 16), LayoutOrder = 2 })
			end
		end
	end)
	return rec
end

local function frameOf(id)
	local def = Home.defs[id]
	if def then
		return def.frame
	end
	local custom = Home.customFrames[id]
	return custom and custom.frame or nil
end

local function applyDensity()
	local d = density()
	for _, rec in ipairs(M.cards) do
		if rec.pad then
			rec.pad.PaddingLeft = UDim.new(0, d.pad)
			rec.pad.PaddingRight = UDim.new(0, d.pad)
			rec.pad.PaddingTop = UDim.new(0, d.pad)
			rec.pad.PaddingBottom = UDim.new(0, d.pad)
		end
		if rec.corner then
			rec.corner.CornerRadius = UDim.new(0, d.corner)
		end
		if rec.head then
			rec.head.Size = UDim2.new(1, 0, 0, d.header)
		end
		if rec.title then
			rec.title.TextSize = d.title
		end
	end
	for _, sc in ipairs({ Home.scrollA, Home.scrollB }) do
		local list = sc and sc:FindFirstChildOfClass("UIListLayout")
		if list then
			list.Padding = UDim.new(0, d.gap)
		end
	end
	for _, row in ipairs(M.statRows) do
		if alive(row) then
			row.Size = UDim2.new(1, 0, 0, d.stat)
		end
	end
	for _, row in ipairs(M.rows) do
		if alive(row) then
			row.Size = UDim2.new(1, 0, 0, d.row)
		end
	end
	if M.tileGrid then
		local cs = M.tileGrid.CellSize
		M.tileGrid.CellSize = UDim2.new(cs.X.Scale, cs.X.Offset, 0, d.tile)
	end
	if M.quickGrid then
		local cs = M.quickGrid.CellSize
		M.quickGrid.CellSize = UDim2.new(cs.X.Scale, cs.X.Offset, 0, d.pill)
	end
	if alive(Home.friendRow) then
		Home.friendRow.Size = UDim2.new(1, 0, 0, d.face)
	end
	if Home.banner then
		Home.banner.Size = UDim2.new(1, 0, 0, d.banner)
	end
end

local function layoutColumns()
	local narrow = ctx.Shell.narrow == true
	local plan = Layout.plan(M.w or 0, M.config or {}, { narrow = narrow })
	for ci, list in ipairs(plan.columns) do
		local parent = (ci == 1 or narrow) and Home.scrollA or Home.scrollB
		for i, id in ipairs(list) do
			local f = frameOf(id)
			if f then
				if f.Parent ~= parent then
					f.Parent = parent
				end
				f.LayoutOrder = 10 + i
				f.Visible = true
			end
		end
	end
	for _, id in ipairs(plan.hidden) do
		local f = frameOf(id)
		if f then
			f.Visible = false
		end
	end
	if Home.footer then
		Home.footer.Parent = narrow and Home.scrollA or Home.scrollB
	end
	if Home.banner then
		Home.banner.Parent = Home.scrollA
	end
	if Home.editBtn then
		Home.editBtn.Parent = Home.scrollA
	end
	M.plan = plan
end

local function layoutInner(w)
	if not w then
		return
	end
	local d = density()
	if M.tileGrid then
		local cols = w >= 300 and 4 or 2
		M.tileGrid.CellSize = UDim2.new(1 / cols, -8 * (cols - 1) / cols, 0, d.tile)
	end
	local m = Layout.metrics(w, d)
	if M.quickGrid then
		local cols = m.chipCols
		M.quickGrid.CellSize = UDim2.new(1 / cols, -8 * (cols - 1) / cols, 0, d.pill)
	end
	local sideW = (not ctx.Shell.narrow and tonumber(ctx.Shell.rightW)) or w
	M.faces = Layout.metrics(sideW, d).faces
end

local function drawFaces(list)
	local row = Home.friendRow
	if not alive(row) then
		return
	end
	clearChildren(row)
	local d = density()
	for i = 1, math.min(#list, M.faces or 8) do
		local f = list[i]
		local face = UI.new("ImageLabel", {
			Name = "Face",
			BackgroundColor3 = T.card2 or T.card,
			Size = UDim2.fromOffset(d.face, d.face),
			Position = UDim2.fromOffset(Layout.faceOffset(i, d), 0),
			Image = "rbxthumb://type=AvatarHeadShot&id=" .. tostring(f.VisitorId or 0) .. "&w=60&h=60",
		}, row)
		UI.corner(face, math.floor(d.face / 2))
	end
end

local function friendsKey(list)
	local parts = {}
	for i, f in ipairs(list) do
		parts[i] = tostring(f.VisitorId) .. "@" .. tostring(f.PlaceId)
	end
	return table.concat(parts, ",")
end

function Module.loadFriends(force)
	if not M.alive or M.friendsBusy then
		return
	end
	local t = now()
	if not force and not Layout.friendsDue(t, M.friendsAt) then
		return
	end
	M.friendsAt = t
	M.friendsBusy = true
	local mine = M
	task.spawn(function()
		local LP = ctx.LP
		local ok, list = pcall(function()
			return LP:GetFriendsOnline()
		end)
		mine.friendsBusy = false
		if not mine.alive then
			return
		end
		if not ok or type(list) ~= "table" then
			setText(Home.friendText, "Couldn't check your friends")
			return
		end
		local clean, here = {}, 0
		for _, f in ipairs(list) do
			if type(f) == "table" then
				clean[#clean + 1] = f
				if f.PlaceId == game.PlaceId then
					here += 1
				end
			end
		end
		setText(Home.stats.online, tostring(#clean))
		setText(Home.friendCount, tostring(#clean))
		setText(Home.friendText, Layout.friendsLine(#clean, here))
		local key = friendsKey(clean) .. "#" .. tostring(M.faces) .. density().name
		if key ~= mine.friendsKey then
			mine.friendsKey = key
			drawFaces(clean)
		end
	end)
end

local function stateOf(path)
	local R = ctx.Runner
	if R.pending and R.pending[path] then
		return "p"
	end
	if R.isRunning(path) then
		return "r"
	end
	return "i"
end

function Module.renderRecent()
	local box = Home.recentBox
	if not alive(box) then
		return
	end
	local paths = {}
	for _, path in ipairs(type(S.recent) == "table" and S.recent or {}) do
		local e = ctx.Repo.byPath[path]
		if e and ctx.Repo.visible(e) then
			paths[#paths + 1] = path
			if #paths >= RECENT_MAX then
				break
			end
		end
	end
	local d = density()
	local sig = Layout.recentSignature(paths, stateOf) .. "#" .. d.name
	if sig == M.recentSig and #Home.recentRows > 0 then
		return
	end
	M.recentSig = sig
	clearChildren(box)
	Home.recentRows = {}
	if #paths == 0 then
		Home.recentRows[1] = UI.label(box, { Name = "Empty", Text = "Scripts you run show up here", TextSize = d.body, TextColor3 = T.sub, TextXAlignment = Enum.TextXAlignment.Center, Size = UDim2.new(1, 0, 0, d.row) })
		return
	end
	for i, path in ipairs(paths) do
		local e = ctx.Repo.byPath[path]
		local st = stateOf(path)
		local row = UI.button(box, { Name = "Recent", Text = "", BackgroundColor3 = T.card2 or T.card, BackgroundTransparency = 0.3, Size = UDim2.new(1, 0, 0, d.row), LayoutOrder = i })
		UI.corner(row, 12)
		UI.label(row, { Name = "Name", Text = tostring(e.name or path), Font = ctx.FONT_B, TextSize = d.body, TextColor3 = T.text, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, Position = UDim2.fromOffset(12, 0), Size = UDim2.new(1, -72, 1, 0) })
		local rs = UI.button(row, {
			Name = "RunStop",
			Text = st == "r" and "Stop" or (st == "p" and "..." or "Run"),
			Font = ctx.FONT_B,
			TextSize = d.small,
			TextColor3 = st == "r" and (T.red or T.text) or T.text,
			BackgroundColor3 = T.card,
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -8, 0.5, 0),
			Size = UDim2.fromOffset(50, d.row - 14),
		})
		UI.corner(rs, 8)
		rs.Activated:Connect(function()
			local cur = stateOf(path)
			if cur == "p" then
				return
			end
			if cur == "r" then
				ctx.Runner.stop(path)
			else
				ctx.Runner.run(e)
			end
		end)
		row.Activated:Connect(function()
			ctx.Detail.open(e)
		end)
		Home.recentRows[i] = row
	end
end

function Module.quickIds()
	local list = type(S.quickCmds) == "table" and S.quickCmds or {}
	if #list == 0 then
		list = ctx.Core.QUICK_DEFAULT or {}
	end
	local out = {}
	local Cmd = ctx.Cmd
	for _, id in ipairs(list) do
		if type(id) == "string" then
			local def = Cmd and Cmd.by[id]
			local real = def and def.id or id
			if (not Cmd or def) and not table.find(out, real) then
				out[#out + 1] = real
				if #out >= QUICK_MAX then
					break
				end
			end
		end
	end
	return out
end

local function paintQuick(animate)
	local Cmd = ctx.Cmd
	if not Cmd then
		return
	end
	for id, chip in pairs(M.quickChips) do
		if alive(chip.btn) then
			local on = Cmd.isOn(id)
			UI.tween(chip.stroke, animate and 0.2 or 0, { Transparency = on and 0.4 or 1 })
			if chip.dot then
				UI.tween(chip.dot, animate and 0.2 or 0, { BackgroundColor3 = on and ctx.accentColor() or T.dim })
			end
		end
	end
end

function Module.buildQuick()
	if not M.lateDone or not alive(Home.quick) or not ctx.Cmd then
		return
	end
	local Cmd = ctx.Cmd
	clearChildren(Home.quick)
	M.quickChips = {}
	local d = density()
	for i, id in ipairs(Module.quickIds()) do
		local def = Cmd.by[id]
		local b = UI.button(Home.quick, { Name = "Quick_" .. id, Text = "", BackgroundColor3 = T.card, LayoutOrder = i })
		UI.corner(b, 13)
		local stroke = UI.stroke(b, ctx.accentColor(), 1.5, 1)
		UI.icon(def.icon or "zap", 14, T.sub, b, { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 11, 0.5, 0) })
		UI.label(b, { Name = "Name", Text = tostring(def.name or id), Font = ctx.FONT_B, TextSize = d.small, TextColor3 = T.text, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, Position = UDim2.fromOffset(32, 0), Size = UDim2.new(1, -54, 1, 0) })
		local dot = UI.new("Frame", { Name = "Dot", BackgroundColor3 = T.dim, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0), Size = UDim2.fromOffset(7, 7) }, b)
		UI.corner(dot, 4)
		M.quickChips[id] = { btn = b, stroke = stroke, dot = dot }
		b.Activated:Connect(function()
			Cmd.toggle(id)
		end)
	end
	paintQuick(false)
end

function Module.pickQuick()
	local Cmd = ctx.Cmd
	if not Cmd then
		return
	end
	ctx.Win.show("quickpick", {
		title = "Quick switches",
		sub = "Home",
		icon = "layout-grid",
		w = 300,
		h = 420,
		build = function(_, body)
			ctx.Ctl.note(body, 0, "Pick up to " .. QUICK_MAX .. " switches for the Quick switches card on Home.")
			local n = 0
			for _, def in ipairs(Cmd.list) do
				if def.kind == "toggle" and not def.hidden then
					n += 1
					local id = def.id
					ctx.Ctl.toggle(body, n, tostring(def.name or id), tostring(def.desc or ""), function()
						return table.find(Module.quickIds(), id) ~= nil
					end, function(on)
						local cur = Module.quickIds()
						local at = table.find(cur, id)
						if on and not at then
							if #cur >= QUICK_MAX then
								ctx.notify("Quick switches", "Home has room for " .. QUICK_MAX .. ", turn one off first")
								return
							end
							cur[#cur + 1] = id
						elseif not on and at then
							table.remove(cur, at)
						end
						S.quickCmds = cur
						save()
						Module.buildQuick()
					end)
				end
			end
		end,
	})
end

function Module.syncMusic()
	if not alive(Home.player) then
		return
	end
	local NP = ctx.NP
	local on = false
	if NP and NP.active then
		local ok, res = pcall(NP.active)
		on = ok and res == true
	end
	if not on and ctx.Player and ctx.Player.cur ~= nil then
		on = true
	end
	Home.player.Visible = on
	if alive(Home.idle) then
		Home.idle.Visible = not on
	end
end

local function buildPlayerView()
	local NP = ctx.NP
	if not NP or M.npView or not alive(Home.player) then
		return
	end
	local p = Home.player
	local v = { root = p }
	local okArt, art = pcall(NP.art, p, 56, 12, UDim2.fromOffset(0, 4), 22, 4)
	if okArt then
		v.art = art
	end
	v.title = UI.label(p, { Name = "Song", Text = "", Font = ctx.FONT_B, TextSize = 13, TextColor3 = T.text, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, Position = UDim2.fromOffset(66, 6), Size = UDim2.new(1, -150, 0, 18) })
	v.artist = UI.label(p, { Name = "Artist", Text = "", TextSize = 11, TextColor3 = T.sub, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, Position = UDim2.fromOffset(66, 24), Size = UDim2.new(1, -150, 0, 14) })
	local okPlay, playBtn, playIcon = pcall(NP.button, p, "play-fill", 36, 16, UDim2.new(1, -62, 0, 26), true)
	if okPlay and playBtn then
		v.playIcon = playIcon
		playBtn.Activated:Connect(function()
			pcall(NP.toggle)
		end)
	end
	local okNext, nextBtn = pcall(NP.button, p, "skip-forward", 32, 16, UDim2.new(1, -18, 0, 26), false)
	if okNext and nextBtn then
		nextBtn.Activated:Connect(function()
			pcall(NP.next)
		end)
	end
	pcall(NP.bar, p, v, { Position = UDim2.fromOffset(66, 50), Size = UDim2.new(1, -66, 0, 4) }, false)
	M.npView = v
	pcall(NP.add, v)
end

function Module.late()
	if M.lateDone or not M.alive then
		return
	end
	M.lateDone = true
	listen("cmd", function()
		paintQuick(true)
	end)
	listen("accent", function()
		local acc = ctx.accentColor()
		for _, chip in pairs(M.quickChips) do
			if alive(chip.stroke) then
				chip.stroke.Color = acc
			end
		end
		Module.restyle()
	end)
	buildPlayerView()
	Module.buildQuick()
	Module.syncMusic()
	Module.renderRecent()
	Module.applyWidgets()
end

function Module.update(version)
	if not Home.banner then
		return
	end
	if version then
		Home.banner.Visible = true
		Home.bannerTitle.Text = "Update ready  ·  v" .. tostring(version)
	else
		Home.banner.Visible = false
	end
end

function Module.restyle()
	local op = tonumber(S.opacity) or 0
	for _, rec in ipairs(M.cards) do
		if alive(rec.card) then
			if rec.tinted then
				rec.card.BackgroundColor3 = ctx.accentColor()
				rec.card.BackgroundTransparency = 0.82
			else
				rec.card.BackgroundColor3 = T.panel or T.card
				rec.card.BackgroundTransparency = op
			end
		end
	end
	for _, o in ipairs({ Home.banner, Home.editBtn }) do
		if alive(o) then
			o.BackgroundTransparency = op
		end
	end
end

function Module.tick(_, ping)
	if not M.alive then
		return
	end
	local players = 0
	pcall(function()
		players = #ctx.Players:GetPlayers()
	end)
	setText(Home.stats.players, Layout.playersText(players, ctx.Players.MaxPlayers))
	setText(Home.stats.ping, Layout.pingText(ping))
	local clock = ctx.ServerClock
	if clock then
		local okA, age, how = pcall(clock.age)
		if okA then
			setText(Home.stats.uptime, Layout.uptimeText(age) .. (how == "game" and "" or "+"))
		end
	else
		setText(Home.stats.uptime, Layout.uptimeText(workspace.DistributedGameTime))
	end
	local clock = ctx.Util.shortTime(S.clock24)
	if Home.clockSet then
		pcall(Home.clockSet, clock)
	end
	for _, c in ipairs(M.clocks) do
		setText(c.time, clock)
	end
	setText(Home.footer, tostring(Home.executor or "unknown") .. "  ·  Smart Stop " .. (S.smartStop and "on" or "off") .. "  ·  " .. tostring(ctx.Core.VTAG or "v") .. tostring(ctx.HUB_VERSION))
	if Layout.friendsDue(now(), M.friendsAt) then
		Module.loadFriends(false)
	end
end

function Module.applyWidgets()
	if not M.alive then
		return
	end
	local defs = {}
	for id, def in pairs(DEFS) do
		defs[id] = { col = def.col }
	end
	M.config = Layout.normalizeConfig(S.homeWidgets, defs, IDS, KIND_SET)
	local want = {}
	for _, e in ipairs(M.config) do
		if e.kind then
			want[e.id] = e
		end
	end
	local stale = {}
	for id, slot in pairs(Home.customFrames) do
		local e = want[id]
		if not e or widgetSig(e) ~= slot.sig then
			stale[#stale + 1] = id
		end
	end
	for _, id in ipairs(stale) do
		dropCard(Home.customFrames[id].card)
		Home.customFrames[id] = nil
	end
	for _, e in ipairs(M.config) do
		if e.kind and not Home.customFrames[e.id] then
			local rec = buildWidget(e)
			Home.customFrames[e.id] = { frame = rec.holder, card = rec, sig = widgetSig(e) }
		end
	end
	local clocks = {}
	for _, c in ipairs(M.clocks) do
		if alive(c.time) and Home.customFrames[c.id] then
			clocks[#clocks + 1] = c
		end
	end
	M.clocks = clocks
	Home.clocks = clocks
	applyDensity()
	Module.restyle()
	layoutColumns()
	layoutInner(M.w)
end

function Module.setDensity(name)
	S.homeDensity = Layout.densityName(name)
	save()
	applyDensity()
	layoutInner(M.w)
	M.recentSig = nil
	Module.renderRecent()
end

function Module.layout(w, h)
	M.w, M.h = w, h
	Home.scrollA.Size = UDim2.fromOffset(w, h)
	layoutColumns()
	layoutInner(w)
end

function Module.onShow()
	if not M.alive then
		return
	end
	Module.loadFriends(false)
	Module.renderRecent()
	Module.syncMusic()
	if M.entered then
		return
	end
	M.entered = true
	if not S.animations then
		return
	end
	local order = {}
	for _, id in ipairs(M.plan and M.plan.order or IDS) do
		local def = Home.defs[id]
		local rec = def and def.card or (Home.customFrames[id] and Home.customFrames[id].card)
		if rec and alive(rec.holder) then
			order[#order + 1] = rec
		end
	end
	for _, rec in ipairs(order) do
		local h = rec.holder.AbsoluteSize.Y
		rec.holder.AutomaticSize = Enum.AutomaticSize.None
		rec.holder.Size = UDim2.new(1, 0, 0, h)
		rec.card.GroupTransparency = 1
		rec.card.Position = UDim2.new(0, 0, 0, Layout.ENTER_RISE)
	end
	local mine = M
	for i, rec in ipairs(order) do
		task.delay(Layout.stagger(i), function()
			if not mine.alive or not alive(rec.card) then
				return
			end
			UI.tween(rec.card, Layout.ENTER_TIME, { Position = UDim2.new(0, 0, 0, 0) })
			UI.done(UI.tween(rec.card, Layout.ENTER_TIME, { GroupTransparency = 0 }), function()
				if alive(rec.holder) then
					rec.holder.AutomaticSize = Enum.AutomaticSize.Y
					rec.holder.Size = UDim2.new(1, 0, 0, 0)
				end
			end)
		end)
	end
end

local function addWidget(kind, data)
	if type(S.homeWidgets) ~= "table" then
		S.homeWidgets = {}
	end
	local count, taken = 0, {}
	for _, e in ipairs(S.homeWidgets) do
		if type(e) == "table" then
			taken[tostring(e.id)] = true
			if e.kind then
				count += 1
			end
		end
	end
	if count >= MAX_WIDGETS then
		ctx.notify("Home", "Home has room for " .. MAX_WIDGETS .. " of your own cards")
		return
	end
	local n = 1
	while taken["w" .. n] do
		n += 1
	end
	table.insert(S.homeWidgets, { id = "w" .. n, kind = kind, col = "A", data = data })
	save()
	Module.applyWidgets()
	ctx.notify("Home", "Added a " .. string.lower(KINDS[kind]))
end

local function editWidget(entry, key, value)
	entry.data[key] = value
	save()
	Module.applyWidgets()
end

local function removeWidget(entry)
	for i, x in ipairs(S.homeWidgets) do
		if x == entry then
			table.remove(S.homeWidgets, i)
			break
		end
	end
	save()
	Module.applyWidgets()
end

function Module.openEditor()
	local Ctl = ctx.Ctl
	ctx.Win.show("homeedit", {
		title = "Customize Home",
		sub = "Home",
		icon = "layout-dashboard",
		w = 320,
		h = 460,
		build = function(_, body)
			Ctl.choice(body, 1, "Card density", { { "comfortable", "Comfortable" }, { "compact", "Compact" } }, function()
				return Layout.densityName(S.homeDensity)
			end, function(v)
				Module.setDensity(v)
			end)
			Ctl.note(body, 2, "Add your own cards. Pictures take a Roblox image ID or a picture link, notes take a few words. Close and open this window to edit a card you just added.")
			Ctl.buttons(body, 3, {
				{ "image", "Picture", function()
					addWidget("picture", { image = "", size = "m", fit = "crop" })
				end },
				{ "notebook-text", "Note", function()
					addWidget("note", { title = "Note", text = "Tap Customize to change me" })
				end },
				{ "clock", "Clock", function()
					addWidget("clock", {})
				end },
			})
			local order = 10
			for _, e in ipairs(type(S.homeWidgets) == "table" and S.homeWidgets or {}) do
				if type(e) == "table" and KIND_SET[e.kind] and type(e.data) == "table" then
					local entry = e
					local label = KINDS[entry.kind] .. " " .. tostring(entry.id)
					if entry.kind == "picture" then
						Ctl.input(body, order, label, "Roblox image ID or picture link", function()
							return tostring(entry.data.image or "")
						end, function(text)
							editWidget(entry, "image", ctx.Util.trim(tostring(text or "")))
						end)
						Ctl.input(body, order + 1, label .. " caption", "a few words under it", function()
							return tostring(entry.data.caption or "")
						end, function(text)
							editWidget(entry, "caption", tostring(text or ""))
						end)
					elseif entry.kind == "note" then
						Ctl.input(body, order, label .. " title", "a title", function()
							return tostring(entry.data.title or "")
						end, function(text)
							editWidget(entry, "title", tostring(text or ""))
						end)
						Ctl.input(body, order + 1, label .. " text", "your words", function()
							return tostring(entry.data.text or "")
						end, function(text)
							editWidget(entry, "text", tostring(text or ""))
						end, { raw = true, lines = 3 })
					end
					Ctl.action(body, order + 2, "Remove " .. string.lower(label), "trash-2", true, function()
						removeWidget(entry)
					end)
					order += 3
				end
			end
			Ctl.action(body, 900, "Put Home back the way it was", "rotate-ccw", true, function()
				S.homeWidgets = {}
				for _, rec in ipairs(M.cards) do
					if rec.collapsed then
						setCollapsed(rec, false, true)
					end
				end
				S.homeCollapsed = {}
				Module.applyWidgets()
				Module.setDensity("comfortable")
			end)
		end,
	})
end

function Module.head()
	local name = ctx.LP and ctx.LP.DisplayName or "you"
	return "Welcome back, " .. tostring(name), Layout.greeting(hourNow())
end

function Module.init(context)
	if M.alive then
		Module.destroy()
	end
	ctx = context
	UI, T, S, Home = ctx.UI, ctx.T, ctx.S, ctx.Home
	Layout = ctx.Core.loadModule("home_layout")
	if type(Layout) ~= "table" or type(Layout.plan) ~= "function" then
		error("home_layout didn't load", 0)
	end
	M = {
		alive = true,
		bus = {},
		cards = {},
		clocks = {},
		quickChips = {},
		statRows = {},
		rows = {},
		entered = false,
		lateDone = false,
		friendsAt = -1e9,
		friendsBusy = false,
	}
	Home.defs = {}
	Home.customFrames = {}
	Home.stats = {}
	Home.tiles = {}
	Home.recentRows = {}
	Home.clocks = M.clocks
	Home.order = {}
	local okEx, ex = pcall(function()
		return ctx.X.identifyexecutor and ctx.X.identifyexecutor()
	end)
	if okEx and ex then
		Home.executor = tostring(ex)
	end

	local d = density()
	Home.banner = UI.button(Home.scrollA, { Name = "Banner", Text = "", BackgroundColor3 = T.panel or T.card, BackgroundTransparency = tonumber(S.opacity) or 0, Visible = false, LayoutOrder = 1, Size = UDim2.new(1, 0, 0, d.banner) })
	UI.corner(Home.banner, 18)
	local bstroke = UI.stroke(Home.banner, ctx.accentColor(), 1, 0.5)
	UI.accent(bstroke, "Color")
	local bic = UI.new("Frame", { Name = "Dot", BackgroundColor3 = ctx.accentColor(), BackgroundTransparency = 0.82, AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 11, 0.5, 0), Size = UDim2.fromOffset(30, 30) }, Home.banner)
	UI.corner(bic, 15)
	UI.accent(bic, "BackgroundColor3")
	UI.accent(UI.icon("download", 15, ctx.accentColor(), bic, { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5) }), "ImageColor3")
	Home.bannerTitle = UI.label(Home.banner, { Name = "Title", Text = "Update ready", Font = ctx.FONT_B, TextSize = 12, TextColor3 = T.text, TextXAlignment = Enum.TextXAlignment.Left, AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 51, 0.5, 1), Size = UDim2.new(1, -60, 0, 16) })
	UI.label(Home.banner, { Name = "Sub", Text = "Tap to update, your scripts keep running", TextSize = 10, TextColor3 = T.sub, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, Position = UDim2.new(0, 51, 0.5, 2), Size = UDim2.new(1, -60, 0, 14) })
	Home.banner.Activated:Connect(function()
		ctx.Bus.fire("homeupdate")
	end)

	for _, id in ipairs(IDS) do
		local def = DEFS[id]
		local rec = newCard(id, def.name, def.icon, def.noHead, def.col == "B" and Home.scrollB or Home.scrollA)
		Home.defs[id] = { id = id, name = def.name, col = def.col, frame = rec.holder, card = rec }
		Home.order[#Home.order + 1] = id
		guard(rec, nil, BUILD[id])
	end

	Home.editBtn = UI.button(Home.scrollA, { Name = "Customize", Text = "", BackgroundColor3 = T.panel or T.card, BackgroundTransparency = tonumber(S.opacity) or 0, LayoutOrder = 998, Size = UDim2.new(1, 0, 0, 38) })
	UI.corner(Home.editBtn, 19)
	UI.stroke(Home.editBtn, T.stroke, 1, 0.3)
	local editIcon = UI.icon("layout-dashboard", 13, T.sub, Home.editBtn, { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, -50, 0.5, 0) })
	editIcon.Name = "Icon"
	UI.label(Home.editBtn, { Name = "Label", Text = "Customize Home", TextSize = 11, TextColor3 = T.sub, TextXAlignment = Enum.TextXAlignment.Left, AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0.5, -38, 0.5, 0), Size = UDim2.fromOffset(100, 14) })
	Home.editBtn.Activated:Connect(function()
		Module.openEditor()
	end)
	Home.footer = UI.label(Home.scrollB, { Name = "Footer", Text = "", TextSize = 10, TextColor3 = T.dim, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Center, LayoutOrder = 999, Size = UDim2.new(1, 0, 0, 28) })

	local toolsParent = ctx.Tools and ctx.Tools.frame
	local tools = UI.new("Frame", { Name = "Tools_home", BackgroundTransparency = 1, Size = UDim2.fromOffset(10, 36), AutomaticSize = Enum.AutomaticSize.X, Visible = false, LayoutOrder = 1 }, toolsParent or Home.scrollA)
	local tl = UI.list(tools, 8, Enum.FillDirection.Horizontal, Enum.HorizontalAlignment.Right)
	tl.VerticalAlignment = Enum.VerticalAlignment.Center
	Home.tools = tools
	Home.exSet = ctx.Tools.chip(tools, "zap", tostring(Home.executor or "unknown"), 1)
	Home.clockSet = ctx.Tools.chip(tools, "clock", ctx.Util.shortTime(S.clock24), 2)
	local _, editChip = ctx.Tools.chip(tools, "layout-dashboard", "Customize", 3)
	local editHit = UI.button(editChip, { Name = "Hit", Text = "", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 3 })
	editHit.Activated:Connect(function()
		Module.openEditor()
	end)

	local collapsed = Layout.sanitizeCollapsed(S.homeCollapsed)
	S.homeCollapsed = collapsed
	for _, rec in ipairs(M.cards) do
		if collapsed[rec.id] and rec.head then
			setCollapsed(rec, true, true)
		end
	end

	Home.layout = Module.layout
	Home.tick = Module.tick
	Home.renderRecent = Module.renderRecent
	Home.syncMusic = Module.syncMusic
	Home.restyle = Module.restyle
	Home.buildQuick = Module.buildQuick
	Home.pickQuick = Module.pickQuick
	Home.update = Module.update
	Home.late = Module.late
	Home.head = Module.head
	Home.onShow = Module.onShow
	Home.applyWidgets = Module.applyWidgets
	Home.setDensity = Module.setDensity
	Home.openEditor = Module.openEditor
	Home.loadFriends = Module.loadFriends
	Home.quickIds = Module.quickIds

	Module.applyWidgets()
	ctx.Core.homeReady = true
end

function Module.destroy()
	if not M.alive then
		return
	end
	M.alive = false
	if ctx and ctx.Bus then
		for _, b in ipairs(M.bus) do
			ctx.Bus.off(b[1], b[2])
		end
	end
	M.bus = {}
	if Home and Home.tools and Home.tools.Parent then
		pcall(function()
			Home.tools:Destroy()
		end)
	end
end

function Module.state()
	return M
end

return Module
