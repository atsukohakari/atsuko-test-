local Module = {}

Module.HEAD = 50
Module.TOP = 108
Module.OTHER = "Other"
Module.CAT_COLORS = {
	Movement = "green",
	Visual = "violet",
	Utility = "blue",
	World = "orange",
	Camera = "yellow",
	Character = "green",
	Players = "red",
	Tools = "orange",
	Automation = "violet",
	["Info & fun"] = "yellow",
	Extras = "blue",
}
Module.CYCLE = { "blue", "violet", "green", "orange", "yellow", "red" }
Module.CHUNK = 25
Module.OPEN_TIME = 0.25
Module.CLOSE_TIME = 0.18
Module.SLIDE = 6
Module.SEARCH_DELAY = 0.15

local M = { alive = false, rows = {}, byKey = {}, byId = {}, entries = {}, bus = {}, runButtons = {}, query = "", words = {}, onlyOn = false, cat = nil, catChips = {}, token = 0 }

local function lower(s)
	return string.lower(tostring(s or ""))
end

local function trim(s)
	return (string.gsub(string.gsub(tostring(s or ""), "^%s+", ""), "%s+$", ""))
end

function Module.nameOf(def)
	local n = def.name
	if type(n) == "string" and n ~= "" then
		return n
	end
	return tostring(def.id)
end

function Module.words(query, prefix)
	local q = lower(trim(query))
	if type(prefix) == "string" and prefix ~= "" and string.sub(q, 1, #prefix) == lower(prefix) then
		q = string.sub(q, #prefix + 1)
	end
	local out = {}
	for w in string.gmatch(q, "%S+") do
		out[#out + 1] = w
	end
	return out
end

function Module.haystack(entry)
	if entry.hay then
		return entry.hay
	end
	local def = entry.def
	local parts = { lower(Module.nameOf(def)), lower(def.id) }
	for _, a in ipairs(def.aliases or {}) do
		parts[#parts + 1] = lower(a)
	end
	for _, a in ipairs(def.offNames or {}) do
		parts[#parts + 1] = lower(a)
	end
	parts[#parts + 1] = lower(def.desc)
	entry.hay = table.concat(parts, "\n")
	return entry.hay
end

function Module.matches(entry, words)
	if #words == 0 then
		return true
	end
	local hay = Module.haystack(entry)
	for _, w in ipairs(words) do
		if not string.find(hay, w, 1, true) then
			return false
		end
	end
	return true
end

function Module.sortEntries(list)
	table.sort(list, function(a, b)
		local an, bn = lower(Module.nameOf(a.def)), lower(Module.nameOf(b.def))
		if an ~= bn then
			return an < bn
		end
		if a.owner ~= b.owner then
			return tostring(a.owner) < tostring(b.owner)
		end
		return tostring(a.def.id) < tostring(b.def.id)
	end)
	return list
end

function Module.collect(Cmd, Dispatch)
	local out = {}
	local rows
	if Dispatch and type(Dispatch.list) == "function" then
		local ok, res = pcall(Dispatch.list, Dispatch)
		if ok and type(res) == "table" then
			rows = res
		end
	end
	if rows then
		for _, e in ipairs(rows) do
			if type(e) == "table" and type(e.def) == "table" and e.def.id ~= nil and not e.def.hidden then
				local owner = tostring(e.owner or "hub")
				out[#out + 1] = { def = e.def, owner = owner, label = e.label, shadowedBy = e.shadowedBy, key = owner .. ":" .. tostring(e.def.id) }
			end
		end
	else
		for _, def in ipairs(Cmd.list) do
			if not def.hidden then
				out[#out + 1] = { def = def, owner = "hub", label = "Atsuko Hub", key = "hub:" .. tostring(def.id) }
			end
		end
	end
	return Module.sortEntries(out)
end

function Module.catOf(entry)
	local cat = entry.def.cat
	if type(cat) == "string" and cat ~= "" then
		return cat
	end
	if entry.owner ~= "hub" and type(entry.label) == "string" and entry.label ~= "" then
		return entry.label
	end
	return Module.OTHER
end

function Module.categories(entries)
	local count, out = {}, {}
	for _, e in ipairs(entries) do
		local cat = Module.catOf(e)
		if not count[cat] then
			count[cat] = 0
			out[#out + 1] = cat
		end
		count[cat] += 1
	end
	table.sort(out, function(a, b)
		if count[a] ~= count[b] then
			return count[a] > count[b]
		end
		return a < b
	end)
	local list = {}
	for i, cat in ipairs(out) do
		list[i] = { name = cat, count = count[cat] }
	end
	return list
end

function Module.colorKey(cat)
	local key = Module.CAT_COLORS[cat]
	if key then
		return key
	end
	local sum = 0
	for i = 1, #tostring(cat) do
		sum += string.byte(tostring(cat), i)
	end
	return Module.CYCLE[sum % #Module.CYCLE + 1]
end

function Module.signature(entries)
	local keys = {}
	for i, e in ipairs(entries) do
		keys[i] = e.key
	end
	return table.concat(keys, "|")
end

function Module.countText(shown, total, searching)
	if searching then
		return shown .. " of " .. total
	end
	return total .. (total == 1 and " command" or " commands")
end

function Module.inputKind(def)
	if def.needsPlayer then
		return "player"
	end
	local usage = def.usage
	if type(usage) == "string" and string.find(usage, "<", 1, true) then
		return "text"
	end
	return nil
end

function Module.usageText(def, prefix)
	return tostring(prefix or ";") .. tostring(def.usage or def.id)
end

function Module.details(entry, prefix, helpers)
	helpers = helpers or {}
	local def = entry.def
	local out = {}
	out[#out + 1] = { key = "usage", text = "Usage: " .. Module.usageText(def, prefix) }
	local also = {}
	for _, a in ipairs(def.aliases or {}) do
		also[#also + 1] = a
	end
	if #also > 0 then
		out[#out + 1] = { key = "also", text = "Also: " .. table.concat(also, ", ") }
	end
	local offs = def.offNames
	if def.kind == "toggle" and type(offs) == "table" and #offs > 0 then
		out[#out + 1] = { key = "off", text = "Turn off: " .. table.concat(offs, ", ") }
	end
	if entry.owner ~= "hub" then
		out[#out + 1] = { key = "owner", text = "From " .. tostring(entry.label or entry.owner) }
		if type(helpers.hubHas) == "function" and helpers.hubHas(tostring(def.id)) then
			out[#out + 1] = { key = "shadow", text = "Also in the hub: " .. tostring(def.id) }
		end
	elseif entry.shadowedBy then
		local who = type(helpers.ownerLabel) == "function" and helpers.ownerLabel(entry.shadowedBy) or nil
		out[#out + 1] = { key = "shadow", text = "Typing it runs " .. tostring(who or entry.shadowedBy) .. " instead" }
	end
	return out
end

function Module.state()
	return M
end

function Module.destroy()
	if not M.alive then
		return
	end
	M.alive = false
	M.token += 1
	local ctx = M.ctx
	if ctx and ctx.Bus then
		for _, b in ipairs(M.bus) do
			ctx.Bus.off(b[1], b[2])
		end
	end
	M.bus = {}
	if M.openRow then
		M.teardown(M.openRow)
		M.openRow = nil
	end
	M.rows, M.byKey, M.byId, M.runButtons = {}, {}, {}, {}
end

function Module.init(ctx)
	if M.alive then
		Module.destroy()
	end
	local Core, UI, T, S, L, Bus, Log, Ctl, Cmd = ctx.Core, ctx.UI, ctx.T, ctx.S, ctx.L, ctx.Bus, ctx.Log, ctx.Ctl, ctx.Cmd
	local FONT_B, accentColor = ctx.FONT_B, ctx.accentColor
	local page = ctx.page
	if not (page and page.frame) then
		error("the commands page has no frame")
	end

	M.alive = true
	M.ctx = ctx
	M.rows, M.byKey, M.byId, M.entries, M.runButtons, M.bus = {}, {}, {}, {}, {}, {}
	M.query, M.words, M.onlyOn, M.openRow, M.built, M.building, M.stale, M.sig = "", {}, false, nil, false, false, false, nil
	M.token += 1
	local HEAD = Module.HEAD

	local function scale()
		return math.max(0.01, (L and L.scale) or 1)
	end

	local function logError(where, err)
		Log.add("error", "Hub", "commands list " .. where .. ": " .. tostring(err))
	end

	local function safe(where, fn)
		return function(...)
			local ok, e = pcall(fn, ...)
			if not ok then
				logError(where, e)
			end
		end
	end

	local function onBus(name, fn)
		Bus.on(name, fn)
		M.bus[#M.bus + 1] = { name, fn }
	end

	local function prefix()
		return S.prefix or ";"
	end

	local function dispatcher()
		return Core.Dispatch
	end

	local frame = page.frame
	local CODE = Enum.Font.Code

	local function width(text, size)
		if type(ctx.textWidth) == "function" then
			local ok, w = pcall(ctx.textWidth, text, size, FONT_B)
			if ok and type(w) == "number" then
				return w
			end
		end
		return #tostring(text) * size * 0.6
	end

	local function catColor(cat)
		return T[Module.colorKey(cat)] or accentColor()
	end

	M.bar = UI.new("Frame", { Name = "SearchBar", BackgroundColor3 = T.head or T.card, BackgroundTransparency = 0.15, Size = UDim2.new(1, 0, 0, 42) }, frame)
	UI.corner(M.bar, 14)
	local barStroke = UI.stroke(M.bar, accentColor(), 1.5, 0.85)
	UI.accent(barStroke, "Color")
	M.prefixBox = UI.new("Frame", { Name = "Prefix", BackgroundColor3 = accentColor(), BackgroundTransparency = 0.8, AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 7, 0.5, 0), Size = UDim2.fromOffset(28, 28) }, M.bar)
	UI.corner(M.prefixBox, 9)
	UI.accent(M.prefixBox, "BackgroundColor3")
	M.prefixLabel = UI.label(M.prefixBox, { Name = "Text", Text = prefix(), Font = CODE, TextSize = 15, TextColor3 = accentColor(), TextXAlignment = Enum.TextXAlignment.Center, Size = UDim2.fromScale(1, 1) })
	UI.accent(M.prefixLabel, "TextColor3")
	local box = UI.new("TextBox", {
		Name = "Box",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(44, 0),
		Size = UDim2.new(1, -118, 1, 0),
		Font = ctx.FONT_M,
		TextSize = 12,
		TextColor3 = T.text,
		PlaceholderText = "Search, or type a command and press Enter",
		PlaceholderColor3 = T.dim,
		Text = "",
		ClearTextOnFocus = false,
		TextXAlignment = Enum.TextXAlignment.Left,
		ClipsDescendants = true,
		TextTruncate = Enum.TextTruncate.AtEnd,
	}, M.bar)
	M.box = box
	M.enter = UI.button(M.bar, { Name = "Enter", BackgroundColor3 = T.card, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -7, 0.5, 0), Size = UDim2.fromOffset(62, 26) })
	UI.corner(M.enter, 8)
	M.enterStroke = UI.stroke(M.enter, T.stroke, 1, 0.4)
	M.enterText = UI.label(M.enter, { Name = "Text", Text = "Enter", Font = CODE, TextSize = 11, TextColor3 = T.dim, TextXAlignment = Enum.TextXAlignment.Center, Size = UDim2.fromScale(1, 1) })

	M.chipBar = UI.new("ScrollingFrame", {
		Name = "Chips",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Position = UDim2.fromOffset(0, 50),
		Size = UDim2.new(1, 0, 0, 28),
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.X,
		ScrollBarThickness = 0,
		ScrollingDirection = Enum.ScrollingDirection.X,
	}, frame)
	UI.list(M.chipBar, 6, Enum.FillDirection.Horizontal)

	local function newChip(name, text, order, dotColor)
		local b = UI.button(M.chipBar, { Name = name, BackgroundColor3 = T.card, Size = UDim2.fromOffset(40, 26), LayoutOrder = order })
		UI.corner(b, 13)
		local dot
		local left = 11
		if dotColor then
			dot = UI.new("Frame", { Name = "Dot", BackgroundColor3 = dotColor, AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 10, 0.5, 0), Size = UDim2.fromOffset(6, 6) }, b)
			UI.corner(dot, 3)
			left = 21
		end
		local label = UI.label(b, { Name = "Text", Text = text, Font = FONT_B, TextSize = 10, TextColor3 = T.sub, TextXAlignment = Enum.TextXAlignment.Left, Position = UDim2.fromOffset(left, 0), Size = UDim2.new(1, -left, 1, 0) })
		local chip = { btn = b, text = label, dot = dot, left = left }
		function chip.set(t)
			label.Text = t
			b.Size = UDim2.fromOffset(math.ceil(width(t, 10)) + left + 11, 26)
		end
		chip.set(text)
		return chip
	end

	local allChip = newChip("AllChip", "All", 1)
	M.allChip = allChip
	local onChip = newChip("OnChip", "On", 2)
	M.chip = onChip.btn
	M.chipText = onChip.text
	M.onChip = onChip

	M.countRow = UI.new("Frame", { Name = "CountRow", BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 84), Size = UDim2.new(1, 0, 0, 18) }, frame)
	M.count = UI.label(M.countRow, { Name = "Count", Text = "", Font = FONT_B, TextSize = 10, TextColor3 = T.dim, Position = UDim2.fromOffset(4, 0), Size = UDim2.new(0.5, -4, 1, 0) })
	M.hint = UI.label(M.countRow, { Name = "Hint", Text = "Tap one to see how it works", TextSize = 10, TextColor3 = T.dim, TextXAlignment = Enum.TextXAlignment.Right, Position = UDim2.new(0.5, 0, 0, 0), Size = UDim2.new(0.5, -4, 1, 0), TextTruncate = Enum.TextTruncate.AtEnd })

	M.list = UI.new("ScrollingFrame", {
		Name = "List",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Position = UDim2.fromOffset(0, Module.TOP),
		Size = UDim2.new(1, 0, 1, -Module.TOP),
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 3,
		ScrollBarImageColor3 = T.dim,
		ScrollBarImageTransparency = 0.3,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar,
	}, frame)
	UI.list(M.list, 6)
	UI.pad(M.list, 0, 0, 0, 10)

	M.empty = UI.label(frame, { Name = "Empty", Text = "Nothing matches", Font = FONT_B, TextSize = 12, TextColor3 = T.dim, TextXAlignment = Enum.TextXAlignment.Center, Position = UDim2.fromOffset(0, Module.TOP + 30), Size = UDim2.new(1, 0, 0, 30), Visible = false })

	local function paintOne(chip, on, color)
		chip.btn.BackgroundColor3 = on and (color or accentColor()) or T.card
		chip.btn.BackgroundTransparency = on and (color and 0.75 or 0) or 0
		chip.text.TextColor3 = on and (color and T.text or T.ink) or T.sub
	end

	local function paintChip()
		paintOne(M.onChip, M.onlyOn)
		paintOne(M.allChip, not M.onlyOn and M.cat == nil)
		for cat, chip in pairs(M.catChips) do
			paintOne(chip, M.cat == cat, catColor(cat))
		end
	end

	local function isOn(row)
		return row.hub and row.def.kind == "toggle" and Cmd.isOn(row.def.id)
	end

	local function fits(row)
		return Module.matches(row.entry, M.words) and (not M.onlyOn or isOn(row)) and (M.cat == nil or Module.catOf(row.entry) == M.cat)
	end

	function M.applyFilter()
		local shown, on = 0, 0
		for _, row in ipairs(M.rows) do
			if isOn(row) then
				on += 1
			end
			local show = fits(row)
			if row.frame.Visible ~= show then
				row.frame.Visible = show
			end
			if show then
				shown += 1
			elseif row.open then
				M.collapse(row, true)
			end
		end
		local total = #M.entries
		M.count.Text = Module.countText(shown, total, #M.words > 0 or M.onlyOn or M.cat ~= nil)
		M.empty.Visible = M.built and shown == 0
		if shown == 0 then
			M.empty.Text = M.onlyOn and "Nothing is on right now" or "Nothing matches"
		end
		M.shown = shown
		M.onChip.set(on > 0 and ("On  " .. on) or "On")
		M.allChip.set("All  " .. total)
		paintChip()
		M.paintEnter()
	end

	function M.paintEnter()
		local word = Module.words(box.Text, prefix())[1] or ""
		local D = dispatcher()
		local known = word ~= "" and (Cmd.by[word] ~= nil or Cmd.off[word] ~= nil or (D and type(D.has) == "function" and D:has(word)))
		M.enterReady = known == true
		M.enter.BackgroundColor3 = known and accentColor() or T.card
		M.enterText.TextColor3 = known and T.ink or T.dim
		M.enterText.Text = known and "Run" or "Enter"
		M.enterStroke.Transparency = known and 1 or 0.4
	end

	function M.setCat(cat)
		M.cat = cat
		M.onlyOn = false
		M.applyFilter()
	end

	function M.buildCats()
		for _, chip in pairs(M.catChips) do
			chip.btn:Destroy()
		end
		M.catChips = {}
		for i, item in ipairs(Module.categories(M.entries)) do
			local cat = item.name
			local chip = newChip("Cat_" .. cat, cat .. "  " .. item.count, 10 + i, catColor(cat))
			chip.btn.Activated:Connect(function()
				M.setCat(M.cat ~= cat and cat or nil)
			end)
			M.catChips[cat] = chip
		end
		if M.cat and not M.catChips[M.cat] then
			M.cat = nil
		end
	end

	function M.setQuery(text)
		M.query = tostring(text or "")
		M.words = Module.words(M.query, prefix())
		M.applyFilter()
	end

	function M.setOnly(on)
		M.onlyOn = on == true
		M.applyFilter()
	end

	M.chip.Activated:Connect(function()
		M.cat = nil
		M.setOnly(not M.onlyOn)
	end)
	M.allChip.btn.Activated:Connect(function()
		M.cat = nil
		M.setOnly(false)
	end)

	local function submit()
		local text = trim(box.Text)
		if text == "" then
			return
		end
		local word = Module.words(text, prefix())[1] or ""
		local D = dispatcher()
		local known = word ~= "" and (Cmd.by[word] ~= nil or Cmd.off[word] ~= nil or (D and type(D.has) == "function" and D:has(word)))
		if known then
			if Cmd.exec(text) then
				box.Text = ""
			end
		end
	end

	box.Focused:Connect(function()
		UI.tween(barStroke, 0.2, { Transparency = 0.2 })
	end)
	box.FocusLost:Connect(function(enter)
		UI.tween(barStroke, 0.2, { Transparency = 0.85 })
		if enter then
			submit()
		end
	end)
	M.enter.Activated:Connect(function()
		if M.enterReady then
			submit()
		else
			box:CaptureFocus()
		end
	end)
	local seq = 0
	box:GetPropertyChangedSignal("Text"):Connect(function()
		M.paintEnter()
		seq += 1
		local my = seq
		task.delay(Module.SEARCH_DELAY, function()
			if my ~= seq or not M.alive then
				return
			end
			M.setQuery(box.Text)
		end)
	end)

	local function newShim()
		local w = { alive = true, listeners = {}, conns = {} }
		function w:on(name, fn)
			Bus.on(name, fn)
			self.listeners[#self.listeners + 1] = { name, fn }
		end
		function w:conn(c)
			self.conns[#self.conns + 1] = c
			return c
		end
		function w:setTitle() end
		function w:close() end
		function w:destroy()
			if not self.alive then
				return
			end
			self.alive = false
			for _, l in ipairs(self.listeners) do
				Bus.off(l[1], l[2])
			end
			for _, c in ipairs(self.conns) do
				pcall(function()
					c:Disconnect()
				end)
			end
			self.listeners, self.conns = {}, {}
		end
		return w
	end

	local function runForeign(row, text)
		local D = dispatcher()
		if not (D and type(D.run) == "function") then
			return false
		end
		local ok, res = pcall(D.run, D, tostring(row.def.id), text or "", "ui")
		if not ok then
			logError("run", res)
			return false
		end
		return res == true
	end

	function M.run(row, text)
		if row.hub then
			Cmd.run(row.def.id, (text and text ~= "") and text or nil)
		else
			runForeign(row, text)
		end
	end

	function M.go(row)
		local text = trim(row.typed or "")
		M.run(row, text)
	end

	local function renderRow(row, anim)
		local def = row.def
		local on = isOn(row)
		if row.draw then
			row.draw(on, anim)
		end
		local t = anim and 0.2 or 0
		row.name.TextColor3 = on and accentColor() or (row.reason and T.dim or T.text)
		if on then
			row.sub.Text = def.label and def.label() or "On"
			row.sub.TextColor3 = accentColor()
		else
			row.sub.Text = Module.usageText(def, prefix())
			row.sub.TextColor3 = T.sub
		end
		if row.stroke then
			UI.tween(row.stroke, t, { Transparency = on and 0.45 or 1 })
		end
		if row.stripe then
			UI.tween(row.stripe, t, { BackgroundColor3 = on and accentColor() or row.color, BackgroundTransparency = on and 0 or 0.35 })
		end
		if row.glow then
			UI.tween(row.glow, t, { BackgroundTransparency = on and 0.9 or 1 })
		end
		if row.stateLabel then
			if on then
				row.stateLabel.Text = "Now: " .. tostring(def.label and def.label() or "On")
				row.stateLabel.Visible = true
			else
				row.stateLabel.Visible = false
			end
		end
	end

	local function fadeTo(row, value, t)
		for _, lbl in ipairs(row.fades) do
			if lbl.Parent then
				UI.tween(lbl, t, { TextTransparency = value }, Enum.EasingStyle.Quint)
			end
		end
	end

	local function setFade(row, value)
		for _, lbl in ipairs(row.fades) do
			lbl.TextTransparency = value
		end
	end

	local function measure(row)
		if not row.inner then
			return 0
		end
		local ok, h = pcall(function()
			return row.inner.AbsoluteSize.Y
		end)
		if not ok or type(h) ~= "number" then
			return 0
		end
		return math.ceil(h / scale())
	end

	local function helpers()
		return {
			hubHas = function(word)
				return Cmd.by[word] ~= nil
			end,
			ownerLabel = function(id)
				local D = dispatcher()
				local o = D and D.owners and D.owners[id]
				return o and o.label or nil
			end,
		}
	end

	local function textLine(row, text, order, color, size, code)
		local l = UI.label(row.inner, {
			Name = "Line",
			Text = text,
			TextSize = size or 10,
			TextColor3 = color or T.dim,
			TextWrapped = true,
			TextYAlignment = Enum.TextYAlignment.Top,
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			LayoutOrder = order,
		})
		if code then
			l.Font = CODE
			l.BackgroundColor3 = T.head or T.card2
			l.BackgroundTransparency = 0.2
			UI.corner(l, 8)
			UI.pad(l, 10, 10, 7, 7)
		end
		row.fades[#row.fades + 1] = l
		return l
	end

	local SELECTORS = { "me", "others", "random", "nearest" }

	local function buildBody(row)
		local def, entry = row.def, row.entry
		row.fades = {}
		row.inner = UI.new("Frame", { Name = "Inner", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y }, row.body)
		UI.pad(row.inner, 16, 12, 2, 12)
		UI.list(row.inner, 6)
		row.shim = newShim()
		textLine(row, (type(def.desc) == "string" and def.desc ~= "") and def.desc or "No description yet.", 1, T.sub, 11)
		if row.reason then
			textLine(row, row.reason, 2, T.yellow, 11)
		end
		for i, d in ipairs(Module.details(entry, prefix(), helpers())) do
			if d.key == "usage" then
				textLine(row, d.text, 2 + i, T.text, 11, true)
			else
				textLine(row, d.text, 2 + i, T.dim, 10)
			end
		end
		local kind = Module.inputKind(def)
		if kind and not row.reason then
			local title = kind == "player" and "Player" or "Arguments"
			local hint = kind == "player" and "name, me, all, others, random..." or (def.usage and ("e.g. " .. def.usage) or "type here")
			local input = Ctl.input(row.inner, 20, title, hint, function()
				return row.typed or ""
			end, function(v, enter)
				row.typed = v
				if enter and v ~= "" then
					M.go(row)
				end
			end)
			if def.selectors then
				local list = {}
				for i, word in ipairs(SELECTORS) do
					list[i] = {
						nil,
						word,
						function()
							row.typed = word
							input.box.Text = word
						end,
					}
				end
				Ctl.buttons(row.inner, 21, list, 30)
			end
			Ctl.buttons(row.inner, 22, { { nil, def.kind == "toggle" and "Turn on" or "Go", function() M.go(row) end } })
		end
		row.stateLabel = textLine(row, "", 23, accentColor(), 11)
		row.stateLabel.Visible = false
		if row.hub and not row.reason and type(def.opts) == "function" then
			local ok, e = pcall(def.opts, row.shim, row.inner, 30)
			if not ok then
				logError("options of " .. tostring(def.id), e)
			end
		end
		renderRow(row, false)
	end

	function M.teardown(row)
		if row.shim then
			row.shim:destroy()
			row.shim = nil
		end
		if row.hub and type(row.def.onWinClose) == "function" then
			pcall(row.def.onWinClose)
		end
		if row.inner then
			row.inner:Destroy()
			row.inner = nil
		end
		row.fades = {}
		row.stateLabel = nil
		row.body.Visible = false
		row.body.AutomaticSize = Enum.AutomaticSize.None
		row.body.Size = UDim2.new(1, 0, 0, 0)
	end

	local function settle(row)
		if not row.inner then
			return
		end
		row.body.AutomaticSize = Enum.AutomaticSize.Y
		row.body.Size = UDim2.new(1, 0, 0, 0)
		row.body.ClipsDescendants = false
		row.inner.Position = UDim2.fromOffset(0, 0)
		setFade(row, 0)
	end

	local function scrollInto(row, h, t)
		local list = M.list
		local ok, top = pcall(function()
			return row.frame.AbsolutePosition.Y - list.AbsolutePosition.Y + list.CanvasPosition.Y
		end)
		if not ok then
			return
		end
		local sc = scale()
		local view = list.AbsoluteSize.Y
		local bottom = top + (HEAD + h) * sc
		if view > 0 and bottom > list.CanvasPosition.Y + view - 4 then
			local target = math.max(0, math.min(top - 4, bottom - view + 8))
			UI.tween(list, t, { CanvasPosition = Vector2.new(0, target) }, Enum.EasingStyle.Quint)
		end
	end

	function M.expand(row)
		if row.open then
			return
		end
		row.open = true
		row.token += 1
		local tk = row.token
		M.openRow = row
		buildBody(row)
		row.body.Visible = true
		row.body.ClipsDescendants = true
		row.body.AutomaticSize = Enum.AutomaticSize.None
		row.body.Size = UDim2.new(1, 0, 0, 0)
		local t = S.animations and Module.OPEN_TIME or 0
		if t > 0 then
			row.inner.Position = UDim2.fromOffset(0, -Module.SLIDE)
			setFade(row, 1)
		end
		task.spawn(function()
			if t <= 0 then
				settle(row)
				return
			end
			task.wait()
			if row.token ~= tk or not row.open or not M.alive then
				return
			end
			local h = measure(row)
			if h <= 0 then
				task.wait()
				if row.token ~= tk or not row.open or not M.alive then
					return
				end
				h = measure(row)
			end
			if h <= 0 then
				settle(row)
				return
			end
			local tw = UI.tween(row.body, t, { Size = UDim2.new(1, 0, 0, h) }, Enum.EasingStyle.Quint)
			UI.tween(row.inner, t, { Position = UDim2.fromOffset(0, 0) }, Enum.EasingStyle.Quint)
			fadeTo(row, 0, t)
			scrollInto(row, h, t)
			UI.done(tw, function()
				if row.token == tk and row.open then
					settle(row)
				end
			end)
			task.delay(t / math.max(0.5, S.animSpeed or 1) + 0.4, function()
				if row.token == tk and row.open then
					settle(row)
				end
			end)
		end)
	end

	function M.collapse(row, instant)
		if not row.open then
			return
		end
		row.open = false
		row.token += 1
		local tk = row.token
		if M.openRow == row then
			M.openRow = nil
		end
		local t = (not instant and S.animations) and Module.CLOSE_TIME or 0
		local h = 0
		if t > 0 and row.inner then
			local ok, abs = pcall(function()
				return row.body.AbsoluteSize.Y
			end)
			h = ok and type(abs) == "number" and math.ceil(abs / scale()) or 0
		end
		local function finish()
			if row.token == tk and not row.open then
				M.teardown(row)
			end
		end
		if t > 0 and h > 0 then
			row.body.AutomaticSize = Enum.AutomaticSize.None
			row.body.ClipsDescendants = true
			row.body.Size = UDim2.new(1, 0, 0, h)
			fadeTo(row, 1, t)
			UI.tween(row.inner, t, { Position = UDim2.fromOffset(0, -Module.SLIDE) }, Enum.EasingStyle.Quint)
			local tw = UI.tween(row.body, t, { Size = UDim2.new(1, 0, 0, 0) }, Enum.EasingStyle.Quint)
			UI.done(tw, finish)
			task.delay(t / math.max(0.5, S.animSpeed or 1) + 0.4, finish)
		else
			finish()
		end
	end

	function M.toggleRow(row)
		if row.open then
			M.collapse(row)
			return
		end
		local prev = M.openRow
		if prev and prev ~= row then
			M.collapse(prev)
		end
		M.expand(row)
	end

	local function buildRow(entry, order)
		local def = entry.def
		local hub = entry.owner == "hub"
		local row = { entry = entry, def = def, hub = hub, open = false, token = 0, fades = {}, typed = "" }
		row.color = catColor(Module.catOf(entry))
		row.frame = UI.new("Frame", {
			Name = "Cmd_" .. tostring(def.id),
			BackgroundColor3 = T.card,
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 0, HEAD),
			AutomaticSize = Enum.AutomaticSize.Y,
			LayoutOrder = order,
		}, M.list)
		UI.corner(row.frame, 12)
		row.stroke = UI.stroke(row.frame, accentColor(), 1, 1)
		UI.list(row.frame, 0)
		row.head = UI.button(row.frame, { Name = "Head", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, HEAD), LayoutOrder = 1 })
		row.body = UI.new("Frame", { Name = "Body", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), ClipsDescendants = true, Visible = false, LayoutOrder = 2 }, row.frame)
		row.glow = UI.new("Frame", { Name = "Glow", BackgroundColor3 = accentColor(), BackgroundTransparency = 1, BorderSizePixel = 0, Size = UDim2.fromScale(1, 1) }, row.head)
		UI.corner(row.glow, 12)
		row.stripe = UI.new("Frame", { Name = "Stripe", BackgroundColor3 = row.color, BackgroundTransparency = 0.35, BorderSizePixel = 0, AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 7, 0.5, 0), Size = UDim2.fromOffset(3, HEAD - 22) }, row.head)
		UI.corner(row.stripe, 2)
		row.name = UI.label(row.head, { Name = "Name", Text = Module.nameOf(def), Font = FONT_B, TextSize = 13, Position = UDim2.fromOffset(18, 8), Size = UDim2.new(1, -96, 0, 17), TextTruncate = Enum.TextTruncate.AtEnd })
		row.sub = UI.label(row.head, { Name = "Sub", Text = Module.usageText(def, prefix()), Font = CODE, TextSize = 11, TextColor3 = T.sub, Position = UDim2.fromOffset(18, 27), Size = UDim2.new(1, -96, 0, 14), TextTruncate = Enum.TextTruncate.AtEnd })
		row.reason = hub and Cmd.reason(def) or nil
		if row.reason then
			row.name.TextColor3 = T.dim
			UI.label(row.head, { Name = "Unavailable", Text = "Unavailable", Font = FONT_B, TextSize = 10, TextColor3 = T.dim, TextXAlignment = Enum.TextXAlignment.Right, Position = UDim2.new(1, -86, 0, 0), Size = UDim2.fromOffset(74, HEAD) })
		elseif hub and def.kind == "toggle" then
			local hit = UI.button(row.head, { Name = "Switch", BackgroundTransparency = 1, Size = UDim2.fromOffset(60, HEAD), Position = UDim2.new(1, -62, 0, 0) })
			row.draw = Ctl.switch(hit, UDim2.fromOffset(12, math.floor((HEAD - 20) / 2)))
			hit.Activated:Connect(function()
				Cmd.toggle(def.id)
			end)
		else
			local kind = Module.inputKind(def)
			local b = UI.button(row.head, { Name = "Run", BackgroundColor3 = accentColor(), BackgroundTransparency = 0.8, Size = UDim2.fromOffset(58, 28), Position = UDim2.new(1, -68, 0.5, -14) })
			UI.corner(b, 14)
			UI.label(b, { Name = "Text", Text = kind == "player" and "Pick" or (kind == "text" and "Type" or "Run"), Font = FONT_B, TextSize = 11, TextColor3 = accentColor(), TextXAlignment = Enum.TextXAlignment.Center, Size = UDim2.fromScale(1, 1) })
			UI.onHover(b, function(over)
				UI.tween(b, 0.15, { BackgroundTransparency = over and 0.6 or 0.8 })
			end)
			b.Activated:Connect(function()
				if kind then
					M.toggleRow(row)
				else
					M.run(row)
				end
			end)
			M.runButtons[#M.runButtons + 1] = b
		end
		row.head.Activated:Connect(function()
			M.toggleRow(row)
		end)
		UI.onHover(row.head, function(over)
			UI.tween(row.frame, 0.15, { BackgroundColor3 = over and T.card2 or T.card })
		end)
		row.render = function(anim)
			renderRow(row, anim)
		end
		renderRow(row, false)
		return row
	end

	local function clearRows()
		if M.openRow then
			M.collapse(M.openRow, true)
			M.openRow = nil
		end
		for _, c in ipairs(M.list:GetChildren()) do
			if c:IsA("GuiObject") then
				c:Destroy()
			end
		end
		M.rows, M.byKey, M.byId, M.runButtons = {}, {}, {}, {}
	end

	local function step(token, cursor)
		if token ~= M.token or not M.alive then
			return
		end
		local n = 0
		local entries = M.entries
		while cursor <= #entries and n < Module.CHUNK do
			local entry = entries[cursor]
			local ok, row = pcall(buildRow, entry, cursor)
			if ok then
				M.rows[#M.rows + 1] = row
				M.byKey[entry.key] = row
				if row.hub then
					M.byId[tostring(entry.def.id)] = row
				end
				row.frame.Visible = fits(row)
			else
				logError("row " .. tostring(entry.def.id), row)
			end
			cursor += 1
			n += 1
		end
		M.applyFilter()
		if cursor <= #entries then
			task.defer(step, token, cursor)
		else
			M.building = false
			M.built = true
			M.applyFilter()
		end
	end

	function M.rebuild()
		M.token += 1
		local token = M.token
		M.entries = Module.collect(Cmd, dispatcher())
		M.sig = Module.signature(M.entries)
		M.stale = false
		clearRows()
		M.buildCats()
		M.built = false
		M.building = true
		M.shownPrefix = prefix()
		M.applyFilter()
		step(token, 1)
	end

	function M.refreshPrefix()
		if M.shownPrefix == prefix() then
			return
		end
		M.shownPrefix = prefix()
		M.words = Module.words(M.query, prefix())
		M.prefixLabel.Text = prefix()
		for _, row in ipairs(M.rows) do
			renderRow(row, false)
			if row.open and row.inner then
				for _, c in ipairs(row.inner:GetChildren()) do
					if c.Name == "Line" and string.sub(c.Text, 1, 6) == "Usage:" then
						c.Text = "Usage: " .. Module.usageText(row.def, prefix())
					end
				end
			end
		end
		M.applyFilter()
	end

	function M.show()
		if not M.alive then
			return
		end
		M.visible = true
		local sig = Module.signature(Module.collect(Cmd, dispatcher()))
		if M.stale or sig ~= M.sig then
			M.rebuild()
		else
			M.refreshPrefix()
		end
	end

	function M.hide()
		M.visible = false
	end

	onBus("cmd", safe("update", function(id)
		local row = id ~= nil and M.byId[tostring(id)] or nil
		if row then
			if row.frame.Parent then
				row.render(true)
			end
		else
			for _, r in ipairs(M.rows) do
				if r.frame.Parent then
					r.render(true)
				end
			end
		end
		if M.onlyOn then
			M.applyFilter()
		else
			local on = 0
			for _, r in ipairs(M.rows) do
				if isOn(r) then
					on += 1
				end
			end
			M.onChip.set(on > 0 and ("On  " .. on) or "On")
		end
	end))
	onBus("dispatch", safe("registry", function()
		M.stale = true
		if M.visible then
			task.delay(0.3, function()
				if M.alive and M.visible and M.stale then
					M.rebuild()
				end
			end)
		end
	end))
	onBus("prefix", safe("prefix", function()
		M.refreshPrefix()
	end))
	onBus("accent", safe("accent", function()
		local keep = {}
		for _, b in ipairs(M.runButtons) do
			if b.Parent then
				b.BackgroundColor3 = accentColor()
				local label = b:FindFirstChild("Text")
				if label then
					label.TextColor3 = accentColor()
				end
				keep[#keep + 1] = b
			end
		end
		M.runButtons = keep
		for _, row in ipairs(M.rows) do
			if row.frame.Parent then
				row.stroke.Color = accentColor()
				row.glow.BackgroundColor3 = accentColor()
				renderRow(row, false)
			end
		end
		paintChip()
		M.paintEnter()
	end))

	M.count.Text = ""
	paintChip()
end

function Module.show()
	if M.alive then
		M.show()
	end
end

function Module.hide()
	if M.alive and M.hide then
		M.hide()
	end
end

return Module
