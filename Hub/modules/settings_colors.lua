local Mod = {}

Mod.MIN_CONTRAST = 4.5
Mod.THROTTLE = 0.05
Mod.TWEEN = 0.25
Mod.RATE = 20
Mod.TICK = 0.25
Mod.PERIOD_MIN = 30
Mod.PERIOD_MAX = 120
Mod.PERIOD_DEFAULT = 90
Mod.SLOTS = { "bg", "card", "text", "accent" }
Mod.SLOT_NAMES = { bg = "Background", card = "Cards", text = "Text", accent = "Accent" }
Mod.SLOT_HINTS = {
	bg = "the color behind everything",
	card = "auto picks one from the background",
	text = "auto picks light or dark text",
	accent = "empty keeps your accent",
}
Mod.DARK_RANGE = { s = 0.42, v = 0.2 }
Mod.LIGHT_RANGE = { s = 0.12, v = 0.95 }
Mod.NAME = "My colors"
Mod.MAX_THEMES = 20
Mod.CHANNELS = { "R", "G", "B" }
Mod.CHANNEL_COLORS = { { 255, 96, 96 }, { 96, 214, 120 }, { 104, 160, 255 } }

local ctx = nil
local state = nil
local rain = { running = false, token = 0, light = false, applied = false }

local function clamp(n, lo, hi)
	if n < lo then
		return lo
	end
	if n > hi then
		return hi
	end
	return n
end

local function round(n)
	return math.floor(n + 0.5)
end

function Mod.channel(n)
	n = tonumber(n)
	if not n or n ~= n then
		return 0
	end
	return clamp(round(n), 0, 255)
end

function Mod.toHex(r, g, b)
	return string.format("#%02x%02x%02x", Mod.channel(r), Mod.channel(g), Mod.channel(b))
end

function Mod.parseHex(text)
	if type(text) ~= "string" then
		return nil
	end
	local body = string.match(text, "^%s*#?(%x%x%x%x%x%x)%s*$")
	if not body then
		return nil
	end
	return tonumber(string.sub(body, 1, 2), 16), tonumber(string.sub(body, 3, 4), 16), tonumber(string.sub(body, 5, 6), 16)
end

function Mod.typing(text)
	if type(text) ~= "string" then
		return "bad"
	end
	local body = string.match(text, "^%s*#?(%x*)%s*$")
	if not body then
		return "bad"
	end
	if #body == 6 then
		return "ok"
	end
	if #body < 6 then
		return "partial"
	end
	return "bad"
end

function Mod.cleanHex(value)
	if type(value) == "string" and string.match(value, "^#%x%x%x%x%x%x$") then
		return string.lower(value)
	end
	return ""
end

function Mod.cleanDigits(text)
	local digits = string.gsub(tostring(text or ""), "%D", "")
	return string.sub(digits, 1, 3)
end

function Mod.parseChannel(text)
	local digits = string.match(tostring(text or ""), "^%s*(%d+)%s*$")
	if not digits or #digits > 3 then
		return nil
	end
	return clamp(tonumber(digits), 0, 255)
end

function Mod.fraction(x, left, width)
	if type(x) ~= "number" or type(left) ~= "number" or type(width) ~= "number" or width <= 0 then
		return nil
	end
	return clamp((x - left) / width, 0, 1)
end

function Mod.valueAt(frac)
	return clamp(round(clamp(tonumber(frac) or 0, 0, 1) * 255), 0, 255)
end

local function linear(c)
	c = c / 255
	if c <= 0.04045 then
		return c / 12.92
	end
	return ((c + 0.055) / 1.055) ^ 2.4
end

function Mod.luminance(r, g, b)
	return 0.2126 * linear(r) + 0.7152 * linear(g) + 0.0722 * linear(b)
end

function Mod.contrast(a, b)
	local la = Mod.luminance(a[1], a[2], a[3])
	local lb = Mod.luminance(b[1], b[2], b[3])
	local hi, lo = math.max(la, lb), math.min(la, lb)
	return (hi + 0.05) / (lo + 0.05)
end

function Mod.worstContrast(text, bg, card)
	local worst = Mod.contrast(text, bg)
	if card then
		worst = math.min(worst, Mod.contrast(text, card))
	end
	return worst
end

function Mod.readable(text, bg, card)
	return Mod.worstContrast(text, bg, card) >= Mod.MIN_CONTRAST
end

function Mod.fixText(bg, card)
	local white, black = { 255, 255, 255 }, { 0, 0, 0 }
	if Mod.worstContrast(black, bg, card) > Mod.worstContrast(white, bg, card) then
		return "#000000"
	end
	return "#ffffff"
end

function Mod.hsv(h, s, v)
	h = (h % 1) * 6
	local i = math.floor(h)
	local f = h - i
	local p = v * (1 - s)
	local q = v * (1 - s * f)
	local t = v * (1 - s * (1 - f))
	local r, g, b
	i = i % 6
	if i == 0 then
		r, g, b = v, t, p
	elseif i == 1 then
		r, g, b = q, v, p
	elseif i == 2 then
		r, g, b = p, v, t
	elseif i == 3 then
		r, g, b = p, q, v
	elseif i == 4 then
		r, g, b = t, p, v
	else
		r, g, b = v, p, q
	end
	return Mod.channel(r * 255), Mod.channel(g * 255), Mod.channel(b * 255)
end

function Mod.period(value)
	local n = tonumber(value)
	if not n or n ~= n then
		n = Mod.PERIOD_DEFAULT
	end
	return clamp(round(n), Mod.PERIOD_MIN, Mod.PERIOD_MAX)
end

function Mod.hue(now, period)
	period = Mod.period(period)
	return ((tonumber(now) or 0) % period) / period
end

function Mod.rainbow(now, period, light)
	local range = light and Mod.LIGHT_RANGE or Mod.DARK_RANGE
	return Mod.hsv(Mod.hue(now, period), range.s, range.v)
end

function Mod.allow(now, last)
	return last == nil or now - last >= Mod.THROTTLE - 1e-9
end

function Mod.steps(duration, rate)
	return math.max(1, round((duration or Mod.TWEEN) * (rate or Mod.RATE)))
end

function Mod.ease(t)
	t = clamp(tonumber(t) or 0, 0, 1)
	return 1 - (1 - t) * (1 - t)
end

function Mod.mix(a, b, t)
	return { round(a[1] + (b[1] - a[1]) * t), round(a[2] + (b[2] - a[2]) * t), round(a[3] + (b[3] - a[3]) * t) }
end

function Mod.frames(from, to, count)
	local out = {}
	for i = 1, count do
		local t = Mod.ease(i / count)
		local frame = {}
		for _, key in ipairs({ "bg", "card", "text", "accent" }) do
			if from[key] and to[key] then
				local c = Mod.mix(from[key], to[key], t)
				frame[key] = Mod.toHex(c[1], c[2], c[3])
			end
		end
		out[i] = frame
	end
	return out
end

function Mod.rowText(slot, value, rainbowOn)
	if rainbowOn and slot ~= "accent" then
		return "Rainbow"
	end
	if value == "" or value == nil then
		return slot == "accent" and "Yours" or "Auto"
	end
	return string.upper(value)
end

function Mod.nextName(names)
	local taken = {}
	for _, name in ipairs(names) do
		taken[string.lower(tostring(name))] = true
	end
	if not taken[string.lower(Mod.NAME)] then
		return Mod.NAME
	end
	for n = 2, 99 do
		local name = Mod.NAME .. " " .. n
		if not taken[string.lower(name)] then
			return name
		end
	end
	return Mod.NAME .. " " .. tostring(os.time() % 1000)
end

function Mod.themeFields(draft, rainbowOn)
	local out = {
		bg = Mod.cleanHex(draft.bg),
		card = Mod.cleanHex(draft.card),
		text = Mod.cleanHex(draft.text),
		accent = Mod.cleanHex(draft.accent),
		version = 2,
	}
	if rainbowOn then
		out.rainbowBg = true
	end
	return out
end

function Mod.init(context)
	ctx = context
end

local function connect(signal, fn)
	local conn = signal:Connect(fn)
	if state then
		state.conns[#state.conns + 1] = conn
	end
	return conn
end

local function triple(color)
	return { Mod.channel(color.R * 255), Mod.channel(color.G * 255), Mod.channel(color.B * 255) }
end

local function themeOf(id)
	local th = ctx.Core.Theme
	return th.find(id) or ctx.Core.THEMES[1]
end

local function lightBase()
	local th = ctx.Core.Theme
	return th.light(th.colors(themeOf(ctx.S.theme)).panel)
end

local function restoreBase()
	local th = ctx.Core.Theme
	th.setBase(themeOf(ctx.S.theme))
	ctx.UI.applyAccent(true)
	th.apply(true)
end

function Mod.rainbowRunning()
	return rain.running
end

function Mod.rainbowStop()
	local was = rain.running or rain.applied
	rain.running = false
	rain.token += 1
	rain.applied = false
	if was and ctx and ctx.HUB.alive then
		restoreBase()
	end
end

function Mod.rainbowStart()
	if not ctx or rain.running then
		return
	end
	rain.running = true
	rain.token += 1
	rain.light = lightBase()
	local mine = rain.token
	task.spawn(function()
		while rain.running and rain.token == mine and ctx and ctx.HUB.alive do
			local busy = ctx.Win.get("thememaker") ~= nil or (state ~= nil and state.dirty)
			if ctx.S.rainbowBg and ctx.S.animations then
				if not busy then
					local r, g, b = Mod.rainbow(os.clock(), ctx.S.rainbowBgPeriod, rain.light)
					rain.applied = true
					local th = ctx.Core.Theme
					th.setBase({ id = "__rainbow", bg = Mod.toHex(r, g, b), card = "", text = "" })
					th.apply(false)
				end
			elseif rain.applied then
				rain.applied = false
				restoreBase()
			end
			task.wait(Mod.TICK)
		end
	end)
end

function Mod.rainbowSync()
	if not ctx then
		return
	end
	if ctx.S.rainbowBg == true then
		if rain.running then
			rain.light = lightBase()
		else
			Mod.rainbowStart()
		end
	elseif rain.running then
		Mod.rainbowStop()
	end
end

local function teardown()
	if state then
		state.alive = false
		for _, conn in ipairs(state.conns) do
			pcall(function()
				conn:Disconnect()
			end)
		end
		state = nil
	end
end

local function draftOf(def)
	return { bg = def.bg or "", card = def.card or "", text = def.text or "", accent = def.accent or "" }
end

local function defOf(draft)
	return { id = "__draft", bg = draft.bg, card = draft.card, text = draft.text, accent = draft.accent, tint = 0 }
end

local function snapshot()
	local S = ctx.S
	return {
		theme = S.theme,
		accent = S.accent,
		accentHex = S.accentHex,
		rainbow = S.rainbow,
		tint = S.bgTint,
		draft = draftOf(themeOf(S.theme)),
	}
end

local function colorsOf(draft)
	local core = ctx.Core
	local cols = core.Theme.colors(defOf(draft))
	return {
		bg = triple(cols.panel),
		card = triple(cols.card),
		text = triple(cols.text),
		accent = triple(core.hexColor(draft.accent) or core.baseAccent()),
	}
end

local function restoreState(before)
	local S, core = ctx.S, ctx.Core
	S.theme = before.theme
	S.accent, S.accentHex, S.rainbow, S.bgTint = before.accent, before.accentHex, before.rainbow, before.tint
	restoreBase()
	core.renderControls()
end

function Mod.build(parent, order)
	local ui, T, S, core, Ctl = ctx.UI, ctx.T, ctx.S, ctx.Core, ctx.Ctl
	teardown()
	state = {
		alive = true,
		conns = {},
		slot = nil,
		draft = nil,
		before = nil,
		cur = { 0, 0, 0 },
		dirty = false,
		setting = false,
		last = nil,
		queued = false,
		tweenToken = 0,
		rows = {},
		sliders = {},
	}
	local st = state
	local block = { alive = true }
	block.frame = ui.new("Frame", {
		Name = "ColorsBlock",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = order or 1,
	}, parent)
	ui.list(block.frame, 6)
	ctx.section(block.frame, "Colors", 1)
	Ctl.note(block.frame, 2, "Tap one to change it. The whole hub follows as you drag, and Revert puts it back.")

	local function rainbowOn()
		return S.rainbowBg == true
	end

	local function ensureDraft()
		if not st.draft then
			st.before = snapshot()
			st.draft = draftOf(st.before.draft)
		end
	end

	local picker = ui.new("Frame", {
		Name = "ColorPicker",
		BackgroundColor3 = T.card,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = 7,
		Visible = false,
	}, block.frame)
	ui.corner(picker, 12)
	ui.pad(picker, 0, 0, 8, 10)
	ui.list(picker, 4)

	local head = ui.new("Frame", { Name = "PickerHead", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 36), LayoutOrder = 1 }, picker)
	local pickSwatch = ui.new("Frame", { Name = "PickSwatch", Position = UDim2.fromOffset(12, 4), Size = UDim2.fromOffset(28, 28) }, head)
	ui.corner(pickSwatch, 8)
	ui.stroke(pickSwatch, T.stroke, 1, 0.2)
	core.Theme.fixed[pickSwatch] = true
	local pickTitle = ui.label(head, { Name = "PickTitle", Text = "", Font = ctx.FONT_B, TextSize = 13, Position = UDim2.fromOffset(50, 0), Size = UDim2.new(1, -62, 1, 0) })

	local redraw
	local function live()
		return ctx ~= nil and state == st and st.alive
	end

	local function applyNow(final)
		st.last = os.clock()
		st.queued = false
		if st.draft.accent == "" then
			S.accent, S.accentHex, S.rainbow = st.before.accent, st.before.accentHex, st.before.rainbow
		end
		core.applyThemeDef(defOf(st.draft), final)
	end

	local function queue(final)
		if final then
			applyNow(true)
			return
		end
		local now = os.clock()
		if Mod.allow(now, st.last) then
			applyNow(false)
			return
		end
		if st.queued then
			return
		end
		st.queued = true
		task.delay(Mod.THROTTLE, function()
			if live() and st.queued then
				applyNow(false)
			end
		end)
	end

	local function setSlot(slot, hex, final)
		ensureDraft()
		st.draft[slot] = hex
		st.dirty = true
		redraw()
		queue(final)
	end

	local function setChannel(index, value, final)
		local cur = { st.cur[1], st.cur[2], st.cur[3] }
		cur[index] = Mod.channel(value)
		st.cur = cur
		setSlot(st.slot, Mod.toHex(cur[1], cur[2], cur[3]), final)
	end

	local sliders = {}
	for index, letter in ipairs(Mod.CHANNELS) do
		local row = ui.new("Frame", { Name = "Slider_" .. letter, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 44), LayoutOrder = 1 + index }, picker)
		ui.label(row, { Text = letter, Font = ctx.FONT_B, TextSize = 12, TextColor3 = T.sub, Position = UDim2.fromOffset(14, 0), Size = UDim2.fromOffset(16, 44) })
		local track = ui.new("Frame", { Name = "Track", BackgroundColor3 = T.card2, Position = UDim2.new(0, 38, 0.5, -3), Size = UDim2.new(1, -112, 0, 6) }, row)
		ui.corner(track, 3)
		local fill = ui.new("Frame", { Name = "Fill", BackgroundColor3 = Color3.fromRGB(Mod.CHANNEL_COLORS[index][1], Mod.CHANNEL_COLORS[index][2], Mod.CHANNEL_COLORS[index][3]), BorderSizePixel = 0, Size = UDim2.fromScale(0, 1) }, track)
		ui.corner(fill, 3)
		local knob = ui.new("Frame", { Name = "Knob", BackgroundColor3 = Color3.new(1, 1, 1), AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(16, 16), Position = UDim2.fromScale(0, 0.5) }, track)
		ui.corner(knob, 8)
		core.Theme.fixed[fill] = true
		core.Theme.fixed[knob] = true
		local hit = ui.button(row, { Name = "Hit", BackgroundTransparency = 1, Position = UDim2.fromOffset(30, 0), Size = UDim2.new(1, -88, 1, 0) })
		local num = ui.new("TextBox", {
			Name = "Num",
			BackgroundColor3 = T.card2,
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -12, 0.5, 0),
			Size = UDim2.fromOffset(48, 30),
			Font = Enum.Font.Code,
			TextSize = 12,
			TextColor3 = T.text,
			Text = "0",
			ClearTextOnFocus = false,
		}, row)
		ui.corner(num, 8)
		sliders[index] = { row = row, track = track, fill = fill, knob = knob, hit = hit, num = num }
		hit.InputBegan:Connect(function(input)
			if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then
				return
			end
			if ctx.Drag.cur or not st.slot or not live() then
				return
			end
			if rainbowOn() and st.slot ~= "accent" then
				return
			end
			local scroller = hit:FindFirstAncestorOfClass("ScrollingFrame")
			if scroller then
				scroller.ScrollingEnabled = false
			end
			local function update(pos, final)
				local frac = Mod.fraction(pos.X, track.AbsolutePosition.X, track.AbsoluteSize.X)
				if frac then
					setChannel(index, Mod.valueAt(frac), final)
				end
			end
			update(input.Position, false)
			ctx.Drag.start(input, function(pos)
				update(pos, false)
			end, function()
				if scroller and scroller.Parent then
					scroller.ScrollingEnabled = true
				end
				if st.dirty then
					queue(true)
				end
			end)
		end)
		connect(num:GetPropertyChangedSignal("Text"), function()
			if st.setting or not st.slot then
				return
			end
			local clean = Mod.cleanDigits(num.Text)
			if clean ~= num.Text then
				st.setting = true
				num.Text = clean
				st.setting = false
			end
			local value = Mod.parseChannel(clean)
			if value and not (rainbowOn() and st.slot ~= "accent") then
				setChannel(index, value, false)
			end
		end)
		num.FocusLost:Connect(function()
			if not st.slot then
				return
			end
			local value = Mod.parseChannel(num.Text)
			if value and not (rainbowOn() and st.slot ~= "accent") then
				setChannel(index, value, true)
			end
			redraw()
		end)
	end

	local hexRow = ui.new("Frame", { Name = "HexRow", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 40), LayoutOrder = 5 }, picker)
	local hexBox = ui.new("TextBox", {
		Name = "Hex",
		BackgroundColor3 = T.card2,
		Position = UDim2.fromOffset(12, 5),
		Size = UDim2.new(0.5, -18, 0, 30),
		Font = Enum.Font.Code,
		TextSize = 12,
		TextColor3 = T.text,
		PlaceholderText = "#101115",
		PlaceholderColor3 = T.dim,
		Text = "",
		ClearTextOnFocus = false,
	}, hexRow)
	ui.corner(hexBox, 8)
	local autoBtn = ui.button(hexRow, { Name = "AutoBtn", BackgroundColor3 = T.card2, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 0, 5), Size = UDim2.new(0.5, -18, 0, 30) })
	ui.corner(autoBtn, 8)
	local autoSet = ctx.iconText(autoBtn, "rotate-ccw", "Use auto", T.text, 10)
	ui.pressable(autoBtn, 0.94)

	local quickRow = ui.new("Frame", { Name = "Quick", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 34), LayoutOrder = 6 }, picker)
	local quick = {}
	for i = 1, 8 do
		local q = ui.button(quickRow, { Name = "Quick" .. i, Position = UDim2.new((i - 1) / 8, 8, 0, 2), Size = UDim2.new(1 / 8, -4, 0, 30) })
		ui.corner(q, 8)
		ui.stroke(q, T.stroke, 1, 0.2)
		core.Theme.fixed[q] = true
		ui.pressable(q, 0.85)
		q.Activated:Connect(function()
			if not st.slot or (rainbowOn() and st.slot ~= "accent") then
				return
			end
			local hex = core.QUICK_COLORS[st.slot][i]
			local r, g, b = Mod.parseHex(hex)
			if r then
				st.cur = { r, g, b }
				setSlot(st.slot, Mod.toHex(r, g, b), true)
			end
		end)
		quick[i] = q
	end

	local warn = ui.label(picker, {
		Name = "Contrast",
		Text = "",
		TextSize = 10,
		TextColor3 = T.yellow,
		TextWrapped = true,
		TextYAlignment = Enum.TextYAlignment.Top,
		Size = UDim2.new(1, -24, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = 7,
		Visible = false,
	})
	ui.pad(warn, 12, 0, 0, 0)
	local fixBtn = ui.button(picker, { Name = "FixText", BackgroundColor3 = T.card2, Size = UDim2.new(1, -24, 0, 34), LayoutOrder = 8, Visible = false })
	ui.corner(fixBtn, 10)
	ctx.iconText(fixBtn, "type", "Fix text colour", T.text, 11)
	ui.pressable(fixBtn, 0.96)

	local actions = ui.new("Frame", { Name = "PickerActions", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 40), LayoutOrder = 9 }, picker)
	local applyBtn = ui.button(actions, { Name = "Apply", BackgroundColor3 = T.card2, Position = UDim2.fromOffset(12, 3), Size = UDim2.new(0.5, -18, 0, 34) })
	ui.corner(applyBtn, 10)
	ui.accent(applyBtn, "BackgroundColor3")
	ctx.iconText(applyBtn, "check", "Apply", T.ink, 11)
	ui.pressable(applyBtn, 0.96)
	local revertBtn = ui.button(actions, { Name = "Revert", BackgroundColor3 = T.card2, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 0, 3), Size = UDim2.new(0.5, -18, 0, 34) })
	ui.corner(revertBtn, 10)
	ctx.iconText(revertBtn, "undo-2", "Revert", T.text, 11)
	ui.pressable(revertBtn, 0.96)

	local function rowFor(slot, rowOrder)
		local b = ui.button(block.frame, { Name = "ColorRow_" .. slot, BackgroundColor3 = T.card, Size = UDim2.new(1, 0, 0, 46), LayoutOrder = rowOrder })
		ui.corner(b, 12)
		local stroke = ui.stroke(b, ctx.accentColor(), 1.5, 1)
		ui.accent(stroke, "Color")
		local sw = ui.new("Frame", { Name = "Swatch", Position = UDim2.fromOffset(10, 9), Size = UDim2.fromOffset(28, 28) }, b)
		ui.corner(sw, 8)
		ui.stroke(sw, T.stroke, 1, 0.2)
		core.Theme.fixed[sw] = true
		ui.label(b, { Text = Mod.SLOT_NAMES[slot], TextSize = 12, Position = UDim2.fromOffset(48, 7), Size = UDim2.new(1, -140, 0, 16), TextTruncate = Enum.TextTruncate.AtEnd })
		ui.label(b, { Text = Mod.SLOT_HINTS[slot], TextSize = 9, TextColor3 = T.dim, Position = UDim2.fromOffset(48, 24), Size = UDim2.new(1, -140, 0, 13), TextTruncate = Enum.TextTruncate.AtEnd })
		local value = ui.label(b, {
			Name = "Value",
			Text = "",
			Font = Enum.Font.Code,
			TextSize = 11,
			TextColor3 = T.sub,
			TextXAlignment = Enum.TextXAlignment.Right,
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, -12, 0, 0),
			Size = UDim2.fromOffset(84, 46),
		})
		st.rows[slot] = { button = b, swatch = sw, value = value, stroke = stroke }
		b.Activated:Connect(function()
			block.open(slot)
		end)
		return b
	end

	for i, slot in ipairs(Mod.SLOTS) do
		rowFor(slot, 2 + i)
	end

	redraw = function()
		if not live() then
			return
		end
		local draft = st.draft
		local shown = draft or draftOf(themeOf(S.theme))
		local cols = colorsOf(shown)
		local on = rainbowOn()
		for slot, row in pairs(st.rows) do
			local c = cols[slot]
			row.swatch.BackgroundColor3 = Color3.fromRGB(c[1], c[2], c[3])
			if slot == "bg" then
				row.value.Text = on and "Rainbow" or string.upper(Mod.toHex(c[1], c[2], c[3]))
			else
				row.value.Text = Mod.rowText(slot, shown[slot], on)
			end
			row.stroke.Transparency = (st.slot == slot) and 0 or 1
		end
		picker.Visible = st.slot ~= nil
		if not st.slot then
			return
		end
		local c = cols[st.slot]
		st.cur = { c[1], c[2], c[3] }
		pickTitle.Text = Mod.SLOT_NAMES[st.slot]
		pickSwatch.BackgroundColor3 = Color3.fromRGB(c[1], c[2], c[3])
		st.setting = true
		for index, s in ipairs(sliders) do
			local frac = c[index] / 255
			s.fill.Size = UDim2.fromScale(frac, 1)
			s.knob.Position = UDim2.fromScale(frac, 0.5)
			if ctx.UserInputService:GetFocusedTextBox() ~= s.num then
				s.num.Text = tostring(c[index])
			end
		end
		if ctx.UserInputService:GetFocusedTextBox() ~= hexBox then
			hexBox.Text = Mod.toHex(c[1], c[2], c[3])
			hexBox.TextColor3 = T.text
		end
		st.setting = false
		for i, q in ipairs(quick) do
			local qr, qg, qb = Mod.parseHex(core.QUICK_COLORS[st.slot][i])
			q.BackgroundColor3 = Color3.fromRGB(qr or 0, qg or 0, qb or 0)
		end
		autoBtn.Visible = st.slot ~= "bg"
		autoSet(nil, st.slot == "accent" and "Keep my accent" or "Use auto", T.text)
		local ratio = Mod.worstContrast(cols.text, cols.bg, cols.card)
		if ratio < Mod.MIN_CONTRAST then
			warn.Text = string.format("The text is hard to read on this (%.1f : 1, aim for 4.5 or more).", ratio)
			warn.Visible = true
			fixBtn.Visible = true
		else
			warn.Visible = false
			fixBtn.Visible = false
		end
	end

	connect(hexBox:GetPropertyChangedSignal("Text"), function()
		if st.setting or not st.slot then
			return
		end
		local verdict = Mod.typing(hexBox.Text)
		hexBox.TextColor3 = verdict == "bad" and T.red or T.text
		if verdict == "ok" and not (rainbowOn() and st.slot ~= "accent") then
			local r, g, b = Mod.parseHex(hexBox.Text)
			st.cur = { r, g, b }
			setSlot(st.slot, Mod.toHex(r, g, b), false)
		end
	end)
	hexBox.FocusLost:Connect(function()
		if st.slot and Mod.typing(hexBox.Text) == "ok" and not (rainbowOn() and st.slot ~= "accent") then
			local r, g, b = Mod.parseHex(hexBox.Text)
			setSlot(st.slot, Mod.toHex(r, g, b), true)
		end
		redraw()
	end)

	autoBtn.Activated:Connect(function()
		if not st.slot or st.slot == "bg" or (rainbowOn() and st.slot ~= "accent") then
			return
		end
		setSlot(st.slot, "", true)
	end)

	fixBtn.Activated:Connect(function()
		if not st.slot then
			return
		end
		local cols = colorsOf(st.draft)
		local hex = Mod.fixText(cols.bg, cols.card)
		local r, g, b = Mod.parseHex(hex)
		if st.draft.card ~= "" and not Mod.readable({ r, g, b }, cols.bg, cols.card) then
			st.draft.card = ""
			cols = colorsOf(st.draft)
			hex = Mod.fixText(cols.bg, cols.card)
			ctx.notify("Colors", "Cards went back to auto so the text can be read", "info", 2.5)
		end
		setSlot("text", hex, true)
	end)

	local function tweenTo(before)
		st.tweenToken += 1
		local mine = st.tweenToken
		local from = colorsOf(st.draft)
		local goal = colorsOf(before.draft)
		local function finish()
			if not live() or st.tweenToken ~= mine then
				return
			end
			st.dirty = false
			st.draft = draftOf(before.draft)
			restoreState(before)
			redraw()
		end
		if not S.animations then
			finish()
			return
		end
		local frames = Mod.frames(from, goal, Mod.steps(Mod.TWEEN, Mod.RATE))
		task.spawn(function()
			for i, frame in ipairs(frames) do
				if not live() or st.tweenToken ~= mine then
					return
				end
				if i == #frames then
					break
				end
				core.applyThemeDef({ id = "__draft", bg = frame.bg, card = frame.card, text = frame.text, accent = (before.draft.accent ~= "") and frame.accent or "", tint = 0 }, false)
				task.wait(Mod.TWEEN / #frames)
			end
			finish()
		end)
	end

	revertBtn.Activated:Connect(function()
		if not st.before or not st.dirty then
			ctx.notify("Colors", "Nothing to revert", "info", 1.5)
			return
		end
		tweenTo(st.before)
	end)

	local function saveTheme(asNew)
		if not st.draft then
			ctx.notify("Colors", "Nothing to apply yet, pick a color first", "info", 2)
			return
		end
		st.tweenToken += 1
		local def = nil
		if not asNew then
			for _, d in ipairs(S.themes) do
				if d.id == S.theme then
					def = d
				end
			end
		end
		if not def then
			if #S.themes >= Mod.MAX_THEMES then
				ctx.notify("Colors", "You have 20 themes already, delete one first", "error", 3)
				return
			end
			local names = {}
			for _, d in ipairs(S.themes) do
				names[#names + 1] = d.name
			end
			def = { id = "c" .. tostring(os.time()) .. "_" .. tostring(math.random(100, 999)), name = Mod.nextName(names) }
			S.themes[#S.themes + 1] = def
		end
		local fields = Mod.themeFields(st.draft, rainbowOn())
		def.bg, def.card, def.text, def.accent, def.version, def.rainbowBg = fields.bg, fields.card, fields.text, fields.accent, fields.version, fields.rainbowBg
		local id, name = def.id, def.name
		core.normalizeThemes()
		st.dirty = false
		core.setTheme(id, true)
		st.before = snapshot()
		st.draft = draftOf(st.before.draft)
		ctx.notify("Colors saved", name .. " is on now", "ok", 2)
		redraw()
	end

	applyBtn.Activated:Connect(function()
		saveTheme(false)
	end)

	function block.open(slot)
		if not live() or not Mod.SLOT_NAMES[slot] then
			return
		end
		if rainbowOn() and slot ~= "accent" then
			ctx.notify("Rainbow background", "Turn it off below to pick this color yourself", "info", 2.5)
			return
		end
		ensureDraft()
		st.slot = slot
		redraw()
	end

	function block.close()
		if live() then
			st.slot = nil
			redraw()
		end
	end

	function block.apply()
		saveTheme(false)
	end

	function block.revert()
		if st.before and st.dirty then
			tweenTo(st.before)
		end
	end

	function block.draft()
		return st.draft
	end

	function block.dirty()
		return st.dirty
	end

	function block.destroy()
		if block.alive then
			block.alive = false
			if state == st then
				if st.dirty and st.before then
					st.tweenToken += 1
					st.dirty = false
					restoreState(st.before)
				end
				teardown()
			end
			block.frame:Destroy()
		end
	end

	local toggle = Ctl.toggle(block.frame, 8, "Rainbow background", "A slow color cycle behind the hub. It stays off while Smooth animations is off.", function()
		return rainbowOn()
	end, function(x)
		if x and st.dirty then
			ctx.notify("Colors", "Apply or revert your colors first", "info", 2.5)
			return
		end
		S.rainbowBg = x
		ctx.saveSettings()
		Mod.rainbowSync()
		if x then
			st.slot = (st.slot == "accent") and "accent" or nil
		end
		redraw()
	end)
	block.toggle = toggle
	local speed = Ctl.slider(block.frame, 9, "One loop takes", Mod.PERIOD_MIN, Mod.PERIOD_MAX, 5, function()
		return Mod.period(S.rainbowBgPeriod)
	end, function(x, final)
		S.rainbowBgPeriod = Mod.period(x)
		if final then
			ctx.saveSettings()
		end
	end, function(x)
		return tostring(Mod.period(x)) .. " s"
	end, true)
	block.speed = speed
	Ctl.action(block.frame, 10, "Save as a new theme", "plus", false, function()
		saveTheme(true)
	end)
	Ctl.note(block.frame, 11, "The rainbow is slow on purpose (30 to 120 seconds a loop) and keeps its colors soft so the text stays readable. Apply saves your colors as a theme you can pick again later.")

	st.block = block
	redraw()
	return block
end

function Mod.destroy()
	Mod.rainbowStop()
	teardown()
	ctx = nil
end

return Mod
