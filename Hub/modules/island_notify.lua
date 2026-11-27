local Mod = {}

Mod.MAX_W = 360
Mod.H = 56
Mod.KEEP = 30
Mod.QUEUE = 20
Mod.ERROR_MAX = 30
Mod.BUTTON_MAX = 60
Mod.HOLD = 0.5
Mod.GROW = 0.32
Mod.FOLD = 0.26
Mod.ICONS = { ok = "check", error = "circle-x", warn = "triangle-alert", info = "info" }
Mod.GLYPHS = { ok = "\226\156\147", error = "!", warn = "!", info = "i" }

local M = { alive = false, conns = {} }

local function now()
	return os.clock()
end

local function plainOf(text)
	return (string.gsub(tostring(text or ""), "</?b>", ""))
end

function Mod.kindOf(kind)
	if kind == "ok" or kind == "error" or kind == "warn" then
		return kind
	end
	return "info"
end

function Mod.init(ctx)
	if M.alive then
		Mod.destroy()
	end
	Mod.ctx = ctx
	M = { alive = true, conns = {}, queue = {}, history = {}, cur = nil, seq = 0, downAt = nil }
	local UI, T, S, L, Root, Pill, Core = ctx.UI, ctx.T, ctx.S, ctx.L, ctx.Root, ctx.Pill, ctx.Core or {}
	local FONT_B, FONT_M = ctx.FONT_B, ctx.FONT_M
	local TextService = ctx.TextService
	local Island = ctx.Island
	local TOUCH, MOUSE1 = ctx.TOUCH, ctx.MOUSE1

	local function track(conn)
		M.conns[#M.conns + 1] = conn
		return conn
	end

	local function color(kind)
		if type(Core.kindColor) == "function" then
			local ok, c = pcall(Core.kindColor, kind)
			if ok and c then
				return c
			end
		end
		return (kind == "ok" and T.green) or (kind == "error" and T.red) or (kind == "warn" and T.yellow) or T.text
	end

	local f = UI.new("Frame", {
		Name = "IslandNotice",
		BackgroundColor3 = T.pillBg,
		BorderSizePixel = 0,
		Visible = false,
		ClipsDescendants = true,
		Active = true,
		ZIndex = 4100,
	}, Root)
	local corner = UI.corner(f, 28)
	local ring = UI.stroke(f, T.stroke, 1, 0.45)
	local hit = UI.button(f, { Name = "Hit", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 4101, Text = "" })
	local mark = UI.new("Frame", { Name = "Mark", BorderSizePixel = 0, Size = UDim2.fromOffset(36, 36), Position = UDim2.fromOffset(10, 10), ZIndex = 4102 }, f)
	UI.corner(mark, 18)
	local icon
	local glyph
	if type(UI.icon) == "function" then
		icon = UI.icon("info", 18, T.text, mark, { Name = "Icon", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), ZIndex = 4103 })
	else
		glyph = UI.label(mark, { Name = "Glyph", Font = FONT_B, TextSize = 15, Size = UDim2.fromScale(1, 1), TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 4103 })
	end
	local title = UI.label(f, {
		Name = "Title",
		Font = FONT_B,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Position = UDim2.fromOffset(56, 10),
		Size = UDim2.new(1, -110, 0, 18),
		ZIndex = 4102,
	})
	local body = UI.label(f, {
		Name = "Text",
		Font = FONT_M,
		TextSize = 11,
		TextColor3 = T.sub,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Position = UDim2.fromOffset(56, 29),
		Size = UDim2.new(1, -110, 0, 16),
		ZIndex = 4102,
	})
	local count = UI.label(f, {
		Name = "Count",
		Font = FONT_B,
		TextSize = 11,
		BackgroundColor3 = T.card2 or T.card,
		BackgroundTransparency = 0,
		TextXAlignment = Enum.TextXAlignment.Center,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -12, 0, 18),
		Size = UDim2.fromOffset(34, 20),
		Visible = false,
		ZIndex = 4102,
	})
	UI.corner(count, 10)
	local row = UI.new("Frame", { Name = "Buttons", BackgroundTransparency = 1, Visible = false, ZIndex = 4103 }, f)
	M.frame, M.title, M.body, M.count, M.row, M.ring, M.mark, M.hit = f, title, body, count, row, ring, mark, hit

	local function width()
		return math.max(200, math.min(Mod.MAX_W, (L.W or 800) - 16))
	end

	local function pillRect()
		local pf = Pill and Pill.frame
		if not pf then
			return (L.W or 800) / 2 - 75, 10, 150, 26
		end
		local pos, ap, sz = pf.Position, pf.AnchorPoint, pf.Size
		local w = sz.X.Offset + sz.X.Scale * L.W
		local h = sz.Y.Offset + sz.Y.Scale * L.H
		local x = pos.X.Scale * L.W + pos.X.Offset - ap.X * w
		local y = pos.Y.Scale * L.H + pos.Y.Offset - ap.Y * h
		return x, y, w, h
	end

	local function anchor(w)
		local px, py, pw, ph = pillRect()
		local down = not (type(Core.barLow) == "function" and Core.barLow())
		local cx = math.clamp(px + pw / 2, w / 2 + 8, L.W - w / 2 - 8)
		local edge = down and py or (py + ph)
		if Island and Island.open and type(Island.rect) == "function" then
			local ok, ix, iy, iw, ih = pcall(Island.rect)
			if ok and ix then
				edge = down and (iy + ih + 8) or (iy - 8)
			end
		end
		return cx, edge, down, px, py, pw, ph
	end
	M.anchor = anchor

	local function textH(text, w)
		if type(Core.wrapH) == "function" then
			local ok, h = pcall(Core.wrapH, text, 11, FONT_M, w)
			if ok and type(h) == "number" then
				return math.ceil(h)
			end
		end
		local ok, v = pcall(function()
			return TextService:GetTextSize(text, 11, FONT_M, Vector2.new(w, 10000)).Y
		end)
		if ok and type(v) == "number" then
			return math.ceil(v)
		end
		return 16
	end

	local function updateCount()
		local n = #M.queue
		count.Visible = n > 0 and M.cur ~= nil and not M.cur.expanded
		count.Text = "+" .. n
		title.Size = UDim2.new(1, count.Visible and -110 or -70, 0, 18)
		body.Size = UDim2.new(1, count.Visible and -110 or -70, 0, (M.cur and M.cur.expanded) and body.Size.Y.Offset or 16)
	end

	local function paint(item)
		local c = color(item.kind)
		mark.BackgroundColor3 = c
		mark.BackgroundTransparency = 0.82
		if icon then
			if type(UI.setIcon) == "function" then
				pcall(UI.setIcon, icon, Mod.ICONS[item.kind])
			end
			icon.ImageColor3 = c
		elseif glyph then
			glyph.Text = Mod.GLYPHS[item.kind]
			glyph.TextColor3 = c
		end
		ring.Color = item.kind == "error" and c or T.stroke
		ring.Transparency = item.kind == "error" and 0.25 or 0.45
		title.Text = item.title ~= "" and item.title or "Atsuko Hub"
		body.Text = item.rich and item.text or item.plain
		body.RichText = item.rich == true
		body.TextTruncate = Enum.TextTruncate.AtEnd
	end

	local made = {}
	M.made = function()
		return made
	end
	local function clearButtons()
		for _, b in ipairs(made) do
			pcall(function()
				b:Destroy()
			end)
		end
		made = {}
		row.Visible = false
	end

	local finish

	local function arm(item, seconds)
		item.seq = (item.seq or 0) + 1
		local my = item.seq
		item.untilAt = now() + seconds
		task.delay(seconds, function()
			if M.alive and M.cur == item and item.seq == my then
				finish(item)
			end
		end)
	end

	local function stayFor(item)
		if item.buttons then
			return Mod.BUTTON_MAX
		end
		if item.kind == "error" then
			return Mod.ERROR_MAX
		end
		return item.dur
	end

	local function show(item)
		M.cur = item
		item.expanded = false
		clearButtons()
		paint(item)
		local w = width()
		local cx, edge, down, px, _, pw, ph = anchor(w)
		f.AnchorPoint = Vector2.new(0.5, down and 0 or 1)
		f.Position = UDim2.fromOffset(px + pw / 2, edge)
		f.Size = UDim2.fromOffset(pw, ph)
		corner.CornerRadius = UDim.new(0, math.floor(ph / 2))
		f.Visible = true
		updateCount()
		UI.tween(f, Mod.GROW, { Position = UDim2.fromOffset(cx, edge), Size = UDim2.fromOffset(w, Mod.H) }, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
		UI.tween(corner, Mod.GROW, { CornerRadius = UDim.new(0, Mod.H / 2) })
		if ctx.Sfx and type(ctx.Sfx.play) == "function" then
			pcall(ctx.Sfx.play, "ping")
		end
		arm(item, stayFor(item))
	end

	local function nextOne()
		if not M.alive or M.cur then
			return
		end
		local item = table.remove(M.queue, 1)
		if item then
			show(item)
		else
			updateCount()
		end
	end

	finish = function(item)
		if not M.alive or M.cur ~= item then
			return
		end
		item.seq = (item.seq or 0) + 1
		item.done = true
		M.cur = nil
		M.seq += 1
		local mySeq = M.seq
		local _, edge, _, px, _, pw, ph = anchor(width())
		local tw = UI.tween(f, Mod.FOLD, { Position = UDim2.fromOffset(px + pw / 2, edge), Size = UDim2.fromOffset(pw, ph) }, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
		UI.tween(corner, Mod.FOLD, { CornerRadius = UDim.new(0, math.floor(ph / 2)) })
		UI.done(tw, function()
			if not M.alive or M.seq ~= mySeq then
				return
			end
			if M.cur == nil then
				f.Visible = false
				clearButtons()
			end
			nextOne()
		end)
	end

	local function expand(item)
		if item.expanded then
			return
		end
		item.expanded = true
		local w = width()
		local inner = w - 70
		local th = math.min(260, math.max(16, textH(item.plain, inner)))
		body.Size = UDim2.new(1, -70, 0, th)
		body.TextTruncate = Enum.TextTruncate.None
		title.Size = UDim2.new(1, -70, 0, 18)
		count.Visible = false
		local h = 29 + th + 14
		if item.buttons then
			clearButtons()
			row.Position = UDim2.fromOffset(12, h)
			row.Size = UDim2.new(1, -24, 0, 40)
			local n = #item.buttons
			for i, b in ipairs(item.buttons) do
				local primary = i == n
				local btn = UI.button(row, {
					Name = "Button" .. i,
					Text = tostring(b.text),
					Font = primary and FONT_B or FONT_M,
					TextSize = 13,
					TextColor3 = primary and T.ink or T.text,
					BackgroundColor3 = primary and color("info") or (T.card2 or T.card),
					AutoButtonColor = true,
					Size = UDim2.new(1 / n, i < n and -4 or 0, 1, 0),
					Position = UDim2.new((i - 1) / n, i > 1 and 4 or 0, 0, 0),
					ZIndex = 4104,
				})
				UI.corner(btn, 8)
				made[#made + 1] = btn
				track(btn.Activated:Connect(function()
					if M.cur ~= item then
						return
					end
					if type(b.fn) == "function" then
						pcall(b.fn)
					end
					finish(item)
				end))
			end
			row.Visible = true
			h += 40 + 12
		end
		local cx, edge = anchor(w)
		UI.tween(f, 0.3, { Position = UDim2.fromOffset(cx, edge), Size = UDim2.fromOffset(w, h) }, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
		UI.tween(corner, 0.3, { CornerRadius = UDim.new(0, 22) })
		if item.kind ~= "error" and not item.buttons then
			arm(item, math.max(item.dur, 6 + #item.plain / 30))
		end
	end
	M.expand = expand

	function Mod.tap()
		local item = M.cur
		if not item then
			return nil
		end
		if item.expandable and not item.expanded then
			expand(item)
			return "expand"
		end
		if item.buttons then
			return "wait"
		end
		finish(item)
		return "dismiss"
	end

	track(hit.InputBegan:Connect(function(input)
		if input.UserInputType == MOUSE1 or input.UserInputType == TOUCH then
			M.downAt = now()
		end
	end))
	track(hit.Activated:Connect(function()
		local held = M.downAt and (now() - M.downAt) >= Mod.HOLD
		M.downAt = nil
		if held then
			Mod.openHistory()
			return
		end
		Mod.tap()
	end))

	function Mod.push(t, text, kind, dur, opts)
		if not M.alive then
			return nil
		end
		opts = type(opts) == "table" and opts or {}
		t = tostring(t or "")
		text = tostring(text or "")
		kind = Mod.kindOf(kind)
		local plain = plainOf(text)
		local key = t .. "\0" .. text
		table.insert(M.history, 1, { title = t, text = plain, kind = kind, at = os.time() })
		while #M.history > Mod.KEEP do
			table.remove(M.history)
		end
		local buttons = nil
		if type(opts.buttons) == "table" then
			for _, b in ipairs(opts.buttons) do
				if type(b) == "table" and b.text ~= nil and tostring(b.text) ~= "" then
					buttons = buttons or {}
					if #buttons < 2 then
						buttons[#buttons + 1] = { text = tostring(b.text), fn = b.fn }
					end
				end
			end
		end
		local cur = M.cur
		if cur and cur.key == key and not buttons and not cur.buttons then
			if not cur.expanded then
				arm(cur, stayFor(cur))
			end
			return cur
		end
		for _, q in ipairs(M.queue) do
			if q.key == key and not buttons then
				return q
			end
		end
		local base = tonumber(dur)
		if not base then
			local okT, td = pcall(function()
				return ctx.Toast and ctx.Toast.time and ctx.Toast.time()
			end)
			base = okT and tonumber(td) or nil
		end
		base = math.clamp(base or 3.2, 1.5, 12)
		local long = textH(plain, width() - 110) > 18
		local item = {
			title = t,
			text = text,
			plain = plain,
			rich = text ~= plain,
			kind = kind,
			dur = base,
			key = key,
			buttons = buttons,
			expandable = long or buttons ~= nil,
		}
		if cur then
			M.queue[#M.queue + 1] = item
			while #M.queue > Mod.QUEUE do
				table.remove(M.queue, 1)
			end
			updateCount()
			return item
		end
		show(item)
		return item
	end

	function Mod.openHistory()
		local Win = ctx.Win
		if not (Win and type(Win.show) == "function") then
			return false
		end
		local list = Mod.history()
		local ok = pcall(Win.show, "notices", {
			title = "Recent notifications",
			icon = "bell",
			w = 320,
			h = 380,
			minW = 260,
			minH = 220,
			maxW = 460,
			maxH = 560,
			build = function(_, box)
				local clear = UI.button(box, {
					Name = "Clear",
					Text = "Clear",
					Font = FONT_B,
					TextSize = 12,
					TextColor3 = T.sub,
					BackgroundTransparency = 1,
					Size = UDim2.new(1, 0, 0, 28),
					TextXAlignment = Enum.TextXAlignment.Right,
					LayoutOrder = 0,
				})
				track(clear.Activated:Connect(function()
					Mod.clearHistory()
					pcall(Win.close, "notices")
				end))
				if #list == 0 then
					UI.label(box, { Name = "Empty", Text = "Nothing yet", TextSize = 12, TextColor3 = T.sub, Size = UDim2.new(1, 0, 0, 30), LayoutOrder = 1 })
					return
				end
				for i, e in ipairs(list) do
					local r = UI.new("Frame", { Name = "Notice" .. i, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 40), LayoutOrder = i }, box)
					local dot = UI.new("Frame", { Name = "Dot", BackgroundColor3 = color(e.kind), BorderSizePixel = 0, Size = UDim2.fromOffset(8, 8), Position = UDim2.fromOffset(2, 9) }, r)
					UI.corner(dot, 4)
					UI.label(r, { Name = "Title", Text = e.title ~= "" and e.title or "Atsuko Hub", Font = FONT_B, TextSize = 12, Position = UDim2.fromOffset(18, 2), Size = UDim2.new(1, -66, 0, 16), TextTruncate = Enum.TextTruncate.AtEnd })
					UI.label(r, { Name = "Text", Text = e.text, TextSize = 11, TextColor3 = T.sub, Position = UDim2.fromOffset(18, 19), Size = UDim2.new(1, -18, 0, 16), TextTruncate = Enum.TextTruncate.AtEnd })
					UI.label(r, { Name = "Ago", Text = Mod.ago(e.at), TextSize = 10, TextColor3 = T.sub, TextXAlignment = Enum.TextXAlignment.Right, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 3), Size = UDim2.fromOffset(46, 14) })
				end
			end,
		})
		return ok
	end

	function Mod.place()
		local item = M.cur
		if not item or not f.Visible then
			return
		end
		local w = width()
		local cx, edge, down = anchor(w)
		f.AnchorPoint = Vector2.new(0.5, down and 0 or 1)
		f.Position = UDim2.fromOffset(cx, edge)
		f.Size = UDim2.fromOffset(w, f.Size.Y.Offset)
	end
end

function Mod.ago(at)
	local d = math.max(0, os.time() - (tonumber(at) or os.time()))
	if d < 60 then
		return "now"
	elseif d < 3600 then
		return math.floor(d / 60) .. "m"
	elseif d < 86400 then
		return math.floor(d / 3600) .. "h"
	end
	return math.floor(d / 86400) .. "d"
end

function Mod.current()
	return M.cur
end

function Mod.queued()
	local out = {}
	for i, q in ipairs(M.queue or {}) do
		out[i] = q
	end
	return out
end

function Mod.history()
	local out = {}
	for i, e in ipairs(M.history or {}) do
		out[i] = { title = e.title, text = e.text, kind = e.kind, at = e.at }
	end
	return out
end

function Mod.clearHistory()
	M.history = {}
end

function Mod.frame()
	return M.frame
end

function Mod.parts()
	return { frame = M.frame, title = M.title, body = M.body, count = M.count, row = M.row, ring = M.ring, mark = M.mark, hit = M.hit, buttons = M.made and M.made() or {} }
end

function Mod.alive()
	return M.alive == true
end

function Mod.destroy()
	M.alive = false
	for _, c in ipairs(M.conns or {}) do
		pcall(function()
			c:Disconnect()
		end)
	end
	M.conns = {}
	if M.frame then
		pcall(function()
			M.frame:Destroy()
		end)
	end
	M.frame = nil
	M.cur = nil
	M.queue = {}
end

return Mod
