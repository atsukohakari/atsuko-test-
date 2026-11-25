local Browser = {}

Browser.GAP = 6
Browser.MIN_CELL = 84
Browser.MAX_COLS = 8
Browser.WIDE = 520
Browser.PANE_W = 210
Browser.PANE_H = 172
Browser.TOP = 94
Browser.BATCH = 6
Browser.SEARCH_WAIT = 0.3
Browser.SLIDE = 28
Browser.BUILD_STEP = 50
Browser.BUILD_PAUSE = 80

local ctx = nil
local art = nil
local sniff = nil
local current = nil

local function trim(text)
	return (string.match(tostring(text or ""), "^%s*(.-)%s*$"))
end

local function capital(text)
	return (string.gsub(tostring(text or ""), "^%l", string.upper))
end

local function toast(title, text, kind, seconds)
	if ctx and ctx.notify then
		pcall(ctx.notify, title, text, kind, seconds)
	end
end

function Browser.columns(avail)
	avail = math.max(0, tonumber(avail) or 0)
	local cols = math.floor((avail + Browser.GAP) / (Browser.MIN_CELL + Browser.GAP))
	return math.max(3, math.min(Browser.MAX_COLS, cols))
end

function Browser.cellWidth(avail, cols)
	avail = tonumber(avail) or 0
	cols = math.max(1, tonumber(cols) or 1)
	return math.max(40, math.floor((avail - Browser.GAP * (cols - 1)) / cols))
end

function Browser.parent(dir)
	return string.match(tostring(dir or ""), "^(.*)/[^/]+$") or ""
end

function Browser.crumbs(dir)
	dir = tostring(dir or "")
	if dir == "" then
		return "workspace"
	end
	local parts = {}
	for part in string.gmatch(dir, "[^/]+") do
		parts[#parts + 1] = part
	end
	local shown = parts
	if #parts > 3 then
		shown = { "...", parts[#parts - 2], parts[#parts - 1], parts[#parts] }
	end
	return "workspace / " .. table.concat(shown, " / ")
end

function Browser.paneMode(width)
	if (tonumber(width) or 0) >= Browser.WIDE then
		return "side"
	end
	return "bottom"
end

function Browser.summary(view)
	local folders, pictures = 0, 0
	for _, entry in ipairs(view or {}) do
		if entry.folder then
			folders = folders + 1
		else
			pictures = pictures + 1
		end
	end
	local bits = {}
	if folders > 0 then
		bits[#bits + 1] = folders .. (folders == 1 and " folder" or " folders")
	end
	if pictures > 0 then
		bits[#bits + 1] = pictures .. (pictures == 1 and " picture" or " pictures")
	end
	return table.concat(bits, "  ·  ")
end

function Browser.emptyText(search, entryCount, allFiles)
	if search ~= "" then
		return 'Nothing here matches "' .. search .. '".'
	end
	if entryCount == 0 then
		return "This folder is empty."
	end
	if allFiles then
		return "This folder is empty."
	end
	return "No pictures in this folder. Tap All to show every file."
end

function Browser.paneNote(entry, state, meta)
	local note, warn, usable = "", false, true
	if state == "ok" then
		local says = sniff and sniff.nameFormat(entry.name)
		if meta.info and sniff.mismatch(entry.name, meta.info) then
			note = "The name says ." .. sniff.extOf(entry.name) .. " but it is really a " .. meta.info.label .. " picture, which is fine."
		elseif not says then
			note = "The name doesn't say what it is, so I looked inside."
		end
		if meta.info and meta.info.truncated then
			note = (note ~= "" and note .. " " or "") .. "It looks cut short, so it may show only part of the picture."
			warn = true
		end
	elseif state == "big" then
		if meta.size > art.MAX_BYTES then
			note = "That is over the " .. art.fmtBytes(art.MAX_BYTES) .. " limit, so it can't be used."
			warn = true
			usable = false
		else
			note = "Too big to preview here. You can still select it."
		end
	elseif state == "notimage" then
		note = capital(meta.why or "that is not a picture")
		warn = true
		usable = false
	elseif state == "unreadable" then
		note = "I couldn't read this file."
		warn = true
		usable = false
	elseif state == "asset" then
		note = "Your executor couldn't show this one here. It may still work if you select it."
		warn = true
	else
		note = "Your executor can't show pictures from files."
		warn = true
		usable = false
	end
	return note, warn, usable
end

function Browser.infoLine(state, meta)
	local bits = {}
	if meta and meta.size then
		bits[#bits + 1] = art.fmtBytes(meta.size)
	end
	if meta and meta.info then
		bits[#bits + 1] = sniff.describe(meta.info)
	end
	if state == "big" and meta and meta.size and meta.size <= art.MAX_BYTES then
		bits[#bits + 1] = "no preview"
	end
	return table.concat(bits, "  ·  ")
end

local function bodySize(s)
	local scale = math.max(0.01, ctx.L.scale or 1)
	local size = s.ui.body.AbsoluteSize
	local w = size and size.X / scale or 0
	local h = size and size.Y / scale or 0
	if w < 100 then
		w = s.width > 0 and s.width or 300
	end
	if h < 100 then
		h = s.height > 0 and s.height or 400
	end
	return w, h
end

local function setSelected(cell, on)
	if cell and cell.stroke then
		cell.stroke.Transparency = on and 0 or 1
	end
end

local function clearCells(s)
	for _, cell in ipairs(s.cells) do
		pcall(function()
			cell.btn:Destroy()
		end)
	end
	s.cells = {}
	s.queue = {}
	s.queued = {}
end

local function showMessage(s, text)
	local ui = s.ui
	ui.empty.Text = text or ""
	ui.empty.Visible = text ~= nil and text ~= ""
end

local function updateToolbar(s)
	local ui, T = s.ui, ctx.T
	ui.crumb.Text = Browser.crumbs(s.dir)
	local canGoUp = s.dir ~= "" and s.listing
	ui.backIcon.ImageColor3 = canGoUp and T.text or T.dim
	ui.sortSet("sliders-horizontal", s.sort == "size" and "Size" or "Name", T.text)
	ui.allBtn.BackgroundColor3 = s.allFiles and ctx.accentColor() or T.card
	ui.allLabel.TextColor3 = s.allFiles and T.ink or T.sub
end

local function updateInfo(s)
	local ui = s.ui
	if not s.listing then
		ui.info.Text = ""
		return
	end
	local text = Browser.summary(s.view)
	if s.sort == "size" and s.measured and s.measured >= art.MEASURE_MAX then
		text = text .. (text ~= "" and "  ·  " or "") .. "sizes for the first " .. art.MEASURE_MAX .. " files"
	end
	ui.info.Text = text
end

local function layoutPane(s, w, h, mode)
	local ui = s.ui
	local pane = ui.pane
	local PW, PH = Browser.PANE_W, Browser.PANE_H
	local top = Browser.TOP
	if mode == "side" then
		pane.AnchorPoint = Vector2.new(1, 0)
		pane.Size = UDim2.new(0, PW, 1, -top)
		s.paneHome = UDim2.new(1, 0, 0, top)
		s.paneAway = UDim2.new(1, PW + 8, 0, top)
		local square = PW - 16
		ui.holder.Position = UDim2.fromOffset(8, 8)
		ui.holder.Size = UDim2.fromOffset(square, square)
		ui.name.Position = UDim2.fromOffset(8, square + 14)
		ui.name.Size = UDim2.fromOffset(PW - 16, 48)
		ui.detail.Position = UDim2.fromOffset(8, square + 64)
		ui.detail.Size = UDim2.fromOffset(PW - 16, 28)
		ui.note.Position = UDim2.fromOffset(8, square + 94)
		ui.note.Size = UDim2.fromOffset(PW - 16, 52)
	else
		pane.AnchorPoint = Vector2.new(0, 1)
		pane.Size = UDim2.new(1, 0, 0, PH)
		s.paneHome = UDim2.new(0, 0, 1, 0)
		s.paneAway = UDim2.new(0, 0, 1, PH + 8)
		ui.holder.Position = UDim2.fromOffset(8, 8)
		ui.holder.Size = UDim2.fromOffset(96, 96)
		ui.name.Position = UDim2.fromOffset(112, 8)
		ui.name.Size = UDim2.new(1, -120, 0, 40)
		ui.detail.Position = UDim2.fromOffset(112, 50)
		ui.detail.Size = UDim2.new(1, -120, 0, 28)
		ui.note.Position = UDim2.fromOffset(112, 78)
		ui.note.Size = UDim2.new(1, -120, 0, 36)
	end
	ui.buttons.AnchorPoint = Vector2.new(0, 1)
	ui.buttons.Position = UDim2.new(0, 8, 1, -8)
	ui.buttons.Size = UDim2.new(1, -16, 0, 36)
	if s.paneOpen then
		pane.Position = s.paneHome
	else
		pane.Position = s.paneAway
	end
end

local function layoutAll(s)
	local ui = s.ui
	local w, h = bodySize(s)
	s.width, s.height = w, h
	local mode = Browser.paneMode(w)
	s.mode = mode
	local gridW = w
	local gridBottom = 0
	if s.paneOpen then
		if mode == "side" then
			gridW = w - Browser.PANE_W - 8
		else
			gridBottom = Browser.PANE_H + 8
		end
	end
	ui.grid.Size = UDim2.new(0, gridW, 1, -(Browser.TOP + gridBottom))
	local inner = gridW - 8
	local cols = Browser.columns(inner)
	local cellW = Browser.cellWidth(inner, cols)
	s.cols, s.cellW = cols, cellW
	ui.layout.CellSize = UDim2.fromOffset(cellW, cellW + 22)
	ui.layout.CellPadding = UDim2.fromOffset(Browser.GAP, Browser.GAP)
	layoutPane(s, w, h, mode)
end

local function visibleCells(s)
	local grid = s.ui.grid
	local height = grid.AbsoluteSize and grid.AbsoluteSize.Y or 0
	local base = grid.AbsolutePosition and grid.AbsolutePosition.Y or 0
	local out = {}
	local sized = false
	if height > 0 then
		local margin = height * 0.6
		for _, cell in ipairs(s.cells) do
			local pos, size = cell.btn.AbsolutePosition, cell.btn.AbsoluteSize
			if pos and size and size.Y > 0 then
				sized = true
				local top = pos.Y - base
				if top + size.Y >= -margin and top <= height + margin then
					out[#out + 1] = cell
				end
			end
		end
	end
	if not sized then
		for i = 1, math.min(#s.cells, (s.cols or 3) * 3) do
			out[#out + 1] = s.cells[i]
		end
	end
	return out
end

local function setCellPicture(s, cell, id, state, meta)
	local UI = ctx.UI
	cell.state = state
	cell.id = id
	cell.meta = meta
	if meta and meta.copy then
		s.copies[#s.copies + 1] = meta.copy
	end
	if state == "ok" then
		cell.thumb.Image = id
		cell.thumb.ImageTransparency = 1
		cell.thumb.Visible = true
		cell.icon.Visible = false
		UI.tween(cell.thumb, 0.2, { ImageTransparency = 0 })
	elseif state == "big" then
		UI.setIcon(cell.icon, "image")
		cell.badge.Text = art.fmtBytes(meta.size)
		cell.badge.Visible = true
	elseif state == "notimage" then
		UI.setIcon(cell.icon, "circle-alert")
	elseif state == "unreadable" then
		UI.setIcon(cell.icon, "triangle-alert")
	end
end

local function loadCell(s, cell)
	cell.state = "loading"
	local id, state, meta = art.thumbNow(cell.entry.path)
	if not s.alive or cell.nav ~= s.nav or not cell.btn.Parent then
		return
	end
	setCellPicture(s, cell, id, state, meta)
	if s.selected == cell then
		s.refreshPane(s)
	end
end

local function pump(s)
	if not s.alive then
		return
	end
	for _, cell in ipairs(visibleCells(s)) do
		if cell.state == "idle" and not s.queued[cell] and not cell.entry.folder then
			s.queued[cell] = true
			s.queue[#s.queue + 1] = cell
		end
	end
	if s.working or #s.queue == 0 then
		return
	end
	s.working = true
	task.spawn(function()
		local done = 0
		while s.alive and #s.queue > 0 do
			local cell = table.remove(s.queue, 1)
			s.queued[cell] = nil
			if cell.state == "idle" and cell.nav == s.nav and cell.btn.Parent then
				loadCell(s, cell)
				done = done + 1
				if done % Browser.BATCH == 0 then
					task.wait(0.03)
				end
			end
		end
		s.working = false
	end)
end

local function slide(s, direction)
	local ui = s.ui
	if direction ~= "in" and direction ~= "out" then
		return
	end
	local offset = (direction == "in" and 1 or -1) * Browser.SLIDE
	ui.grid.Position = UDim2.fromOffset(offset, Browser.TOP)
	ctx.UI.tween(ui.grid, 0.22, { Position = UDim2.fromOffset(0, Browser.TOP) })
end

local function hidePane(s, instant)
	local ui = s.ui
	if s.selected then
		setSelected(s.selected, false)
		s.selected = nil
	end
	s.paneToken = s.paneToken + 1
	if not s.paneOpen then
		return
	end
	s.paneOpen = false
	if instant then
		ui.pane.Position = s.paneAway
		ui.pane.Visible = false
	else
		local token = s.paneToken
		ctx.UI.tween(ui.pane, 0.22, { Position = s.paneAway })
		task.delay(0.25, function()
			if s.alive and s.paneToken == token and not s.paneOpen then
				ui.pane.Visible = false
			end
		end)
	end
	layoutAll(s)
	pump(s)
end

function Browser.refreshPane(s)
	local cell = s.selected
	if not (cell and s.alive) then
		return
	end
	local ui, T = s.ui, ctx.T
	local entry = cell.entry
	ui.name.Text = entry.name
	if cell.state == "idle" or cell.state == "loading" or cell.state == nil then
		ui.detail.Text = "Looking..."
		ui.note.Text = ""
		ui.preview.Visible = false
		s.usable = false
		ui.select.btn.BackgroundColor3 = T.card
		ui.select.set("check", "Select", T.dim)
		return
	end
	local note, warn, usable = Browser.paneNote(entry, cell.state, cell.meta or {})
	ui.detail.Text = Browser.infoLine(cell.state, cell.meta)
	ui.note.Text = note
	ui.note.TextColor3 = warn and T.yellow or T.dim
	if cell.state == "ok" and cell.id then
		ui.preview.Image = cell.id
		ui.preview.ImageTransparency = 1
		ui.preview.Visible = true
		ui.previewHint.Visible = false
		ctx.UI.tween(ui.preview, 0.2, { ImageTransparency = 0 })
	else
		ui.preview.Visible = false
		ui.previewHint.Visible = true
	end
	s.usable = usable
	ui.select.btn.BackgroundColor3 = usable and ctx.accentColor() or T.card
	ui.select.set("check", "Select", usable and T.ink or T.dim)
end

local function showPane(s, cell)
	local ui = s.ui
	s.paneToken = s.paneToken + 1
	local wasOpen = s.paneOpen
	s.paneOpen = true
	ui.pane.Visible = true
	layoutAll(s)
	if not wasOpen then
		ui.pane.Position = s.paneAway
		ctx.UI.tween(ui.pane, 0.25, { Position = s.paneHome }, Enum.EasingStyle.Quint)
	end
	Browser.refreshPane(s)
	if cell.state == "idle" then
		s.queued[cell] = true
		table.insert(s.queue, 1, cell)
		pump(s)
	end
end

local function chooseCell(s, cell)
	if s.selected and s.selected ~= cell then
		setSelected(s.selected, false)
	end
	s.selected = cell
	setSelected(cell, true)
	showPane(s, cell)
end

local function finish(s)
	local path = s.selected and s.selected.entry.path
	if not (path and s.usable) then
		return
	end
	local pick = s.opts.onSelect
	art.setLastFolder(s.dir)
	s.w:close()
	if pick then
		pcall(pick, path)
	end
end

local enter

local function tapCell(s, cell)
	if not s.alive then
		return
	end
	if cell.entry.folder then
		enter(s, cell.entry.path, "in")
	else
		chooseCell(s, cell)
	end
end

local function makeCell(s, entry, index)
	local UI, T = ctx.UI, ctx.T
	local btn = UI.button(s.ui.grid, { Name = "Cell", BackgroundColor3 = T.card, LayoutOrder = index })
	UI.corner(btn, 10)
	local cell = { entry = entry, btn = btn, state = "idle", nav = s.nav }
	cell.stroke = UI.stroke(btn, ctx.accentColor(), 2, 1)
	if entry.folder then
		cell.state = "folder"
		cell.icon = UI.icon("folder", 28, T.sub, btn, { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, -10) })
	else
		cell.holder = UI.new("Frame", { Name = "Thumb", BackgroundTransparency = 1, Position = UDim2.fromOffset(4, 4), Size = UDim2.new(1, -8, 1, -26), ClipsDescendants = true }, btn)
		cell.icon = UI.icon("image", 22, T.dim, cell.holder, { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5) })
		cell.thumb = UI.new("ImageLabel", {
			Name = "Picture",
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			ScaleType = Enum.ScaleType.Fit,
			Image = "",
			ImageTransparency = 1,
			Visible = false,
		}, cell.holder)
		cell.badge = UI.label(cell.holder, {
			Name = "Badge",
			Text = "",
			TextSize = 9,
			TextColor3 = T.dim,
			TextXAlignment = Enum.TextXAlignment.Center,
			AnchorPoint = Vector2.new(0.5, 1),
			Position = UDim2.new(0.5, 0, 1, -2),
			Size = UDim2.new(1, 0, 0, 12),
			Visible = false,
		})
	end
	cell.label = UI.label(btn, {
		Name = "Name",
		Text = entry.name,
		TextSize = 10,
		TextColor3 = T.sub,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextTruncate = Enum.TextTruncate.AtEnd,
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 4, 1, -4),
		Size = UDim2.new(1, -8, 0, 14),
	})
	UI.pressable(btn, 0.95)
	btn.Activated:Connect(function()
		tapCell(s, cell)
	end)
	return cell
end

local function buildCells(s)
	s.build = s.build + 1
	local token = s.build
	clearCells(s)
	local view = s.view
	local keep = s.keepPath
	s.keepPath = nil
	local match = nil
	for i, entry in ipairs(view) do
		if token ~= s.build or not s.alive then
			return
		end
		local cell = makeCell(s, entry, i)
		s.cells[i] = cell
		if keep and entry.path == keep then
			match = cell
		end
		if #view > Browser.BUILD_PAUSE and i % Browser.BUILD_STEP == 0 then
			task.wait(0.02)
		end
	end
	if token ~= s.build or not s.alive then
		return
	end
	if match then
		s.selected = match
		setSelected(match, true)
		Browser.refreshPane(s)
	elseif s.paneOpen then
		hidePane(s, true)
	end
	pump(s)
end

local function refresh(s)
	s.view = art.arrange(s.entries, { search = s.search, sort = s.sort, allFiles = s.allFiles })
	if s.selected then
		s.keepPath = s.selected.entry.path
		s.selected = nil
	end
	if #s.view == 0 then
		showMessage(s, Browser.emptyText(s.search, #s.entries, s.allFiles))
	else
		showMessage(s, nil)
	end
	updateInfo(s)
	updateToolbar(s)
	buildCells(s)
end

local function measure(s)
	if s.measuring then
		return
	end
	s.measuring = true
	local nav = s.nav
	local ui = s.ui
	task.spawn(function()
		local count = art.measure(s.entries, function(done, total)
			if s.alive and s.nav == nav then
				ui.info.Text = "Measuring... " .. done .. " of " .. total
			end
		end, function()
			return s.alive and s.nav == nav
		end)
		s.measuring = false
		if s.alive and s.nav == nav then
			s.measured = count
			refresh(s)
		end
	end)
end

local function setSort(s, sort)
	if s.sort == sort then
		return
	end
	s.sort = sort
	if sort == "size" and s.listing then
		measure(s)
	end
	if s.listing then
		refresh(s)
	else
		updateToolbar(s)
	end
end

local function setAll(s, on)
	if s.allFiles == on then
		return
	end
	s.allFiles = on
	if s.listing then
		refresh(s)
	else
		updateToolbar(s)
	end
end

local function setSearch(s, text)
	text = trim(text)
	if text == s.search then
		return
	end
	s.search = text
	if s.listing then
		refresh(s)
	end
end

function enter(s, dir, direction)
	dir = art.normalizePath(dir)
	local entries, why = art.listDir(dir)
	if not entries then
		if dir == "" or not s.listing then
			s.nav = s.nav + 1
			s.dir = dir
			s.entries = {}
			s.view = {}
			s.listing = false
			clearCells(s)
			hidePane(s, true)
			showMessage(s, capital(why or "I couldn't open that folder") .. ".")
			updateInfo(s)
			updateToolbar(s)
		else
			toast("Pictures", capital(why or "I couldn't open that folder"), "warn", 3)
		end
		return false
	end
	s.nav = s.nav + 1
	s.dir = dir
	s.entries = entries
	s.listing = true
	s.measured = nil
	art.setLastFolder(dir)
	if s.search ~= "" then
		s.search = ""
		s.ui.search.Text = ""
	end
	hidePane(s, true)
	refresh(s)
	slide(s, direction)
	if s.sort == "size" then
		measure(s)
	end
	return true
end

local function goUp(s)
	if s.listing and s.dir ~= "" then
		enter(s, Browser.parent(s.dir), "out")
	end
end

local function buildToolbar(s, body)
	local UI, T = ctx.UI, ctx.T
	local ui = s.ui
	local fontM = ctx.Core.FONT_M
	ui.back = UI.button(body, { Name = "Back", BackgroundColor3 = T.card, Size = UDim2.fromOffset(32, 32) })
	UI.corner(ui.back, 10)
	ui.backIcon = UI.icon("chevron-left", 15, T.text, ui.back, { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5) })
	UI.pressable(ui.back, 0.9)
	ui.back.Activated:Connect(function()
		goUp(s)
	end)
	ui.crumb = UI.label(body, {
		Name = "Crumb",
		Text = "workspace",
		TextSize = 11,
		TextColor3 = T.sub,
		Position = UDim2.fromOffset(40, 0),
		Size = UDim2.new(1, -40, 0, 32),
		TextTruncate = Enum.TextTruncate.AtEnd,
	})
	ui.search = UI.new("TextBox", {
		Name = "Search",
		BackgroundColor3 = T.card,
		Position = UDim2.fromOffset(0, 38),
		Size = UDim2.new(1, -122, 0, 30),
		Font = fontM,
		TextSize = 12,
		TextColor3 = T.text,
		PlaceholderText = "Search this folder",
		PlaceholderColor3 = T.dim,
		Text = "",
		ClearTextOnFocus = false,
		TextXAlignment = Enum.TextXAlignment.Left,
		ClipsDescendants = true,
	}, body)
	UI.corner(ui.search, 10)
	UI.pad(ui.search, 10, 8, 0, 0)
	ui.sort = UI.button(body, { Name = "Sort", BackgroundColor3 = T.card, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -50, 0, 38), Size = UDim2.fromOffset(64, 30) })
	UI.corner(ui.sort, 10)
	ui.sortSet = ctx.iconText(ui.sort, "sliders-horizontal", "Name", T.text, 10)
	UI.pressable(ui.sort, 0.94)
	ui.allBtn = UI.button(body, { Name = "All", BackgroundColor3 = T.card, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 38), Size = UDim2.fromOffset(44, 30) })
	UI.corner(ui.allBtn, 10)
	ui.allLabel = UI.label(ui.allBtn, { Name = "Words", Text = "All", TextSize = 11, TextColor3 = T.sub, TextXAlignment = Enum.TextXAlignment.Center, Size = UDim2.fromScale(1, 1) })
	UI.pressable(ui.allBtn, 0.94)
	ui.info = UI.label(body, { Name = "Info", Text = "", TextSize = 10, TextColor3 = T.dim, Position = UDim2.fromOffset(2, 72), Size = UDim2.new(1, -4, 0, 16) })
	ui.sort.Activated:Connect(function()
		setSort(s, s.sort == "name" and "size" or "name")
	end)
	ui.allBtn.Activated:Connect(function()
		setAll(s, not s.allFiles)
	end)
	ui.search.FocusLost:Connect(function()
		s.searchToken = s.searchToken + 1
		setSearch(s, ui.search.Text)
	end)
	pcall(function()
		ui.search:GetPropertyChangedSignal("Text"):Connect(function()
			s.searchToken = s.searchToken + 1
			local token = s.searchToken
			task.delay(Browser.SEARCH_WAIT, function()
				if s.alive and s.searchToken == token then
					setSearch(s, ui.search.Text)
				end
			end)
		end)
	end)
end

local function buildGrid(s, body)
	local UI, T = ctx.UI, ctx.T
	local ui = s.ui
	ui.grid = UI.new("ScrollingFrame", {
		Name = "Grid",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Position = UDim2.fromOffset(0, Browser.TOP),
		Size = UDim2.new(1, 0, 1, -Browser.TOP),
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 3,
		ScrollBarImageColor3 = T.dim,
		ScrollBarImageTransparency = 0.3,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar,
	}, body)
	ui.layout = UI.new("UIGridLayout", {
		CellSize = UDim2.fromOffset(90, 112),
		CellPadding = UDim2.fromOffset(Browser.GAP, Browser.GAP),
		SortOrder = Enum.SortOrder.LayoutOrder,
		HorizontalAlignment = Enum.HorizontalAlignment.Left,
	}, ui.grid)
	UI.pad(ui.grid, 0, 4, 2, 10)
	ui.empty = UI.label(body, {
		Name = "Empty",
		Text = "",
		TextSize = 12,
		TextColor3 = T.sub,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextYAlignment = Enum.TextYAlignment.Top,
		Position = UDim2.new(0, 16, 0, Browser.TOP + 26),
		Size = UDim2.new(1, -32, 0, 70),
		Visible = false,
	})
	pcall(function()
		s.w:conn(ui.grid:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
			pump(s)
		end))
	end)
end

local function buildPane(s, body)
	local UI, T = ctx.UI, ctx.T
	local ui = s.ui
	ui.pane = UI.new("Frame", { Name = "Pane", BackgroundColor3 = T.card, ZIndex = 5, Visible = false, ClipsDescendants = true }, body)
	UI.corner(ui.pane, 14)
	UI.stroke(ui.pane, T.stroke, 1, 0.3)
	ui.holder = UI.new("Frame", { Name = "Holder", BackgroundColor3 = T.card2, ZIndex = 6, ClipsDescendants = true }, ui.pane)
	UI.corner(ui.holder, 10)
	ui.previewHint = UI.icon("image", 26, T.dim, ui.holder, { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), ZIndex = 7 })
	ui.preview = UI.new("ImageLabel", {
		Name = "Picture",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		ScaleType = Enum.ScaleType.Fit,
		Image = "",
		ImageTransparency = 1,
		Visible = false,
		ZIndex = 8,
	}, ui.holder)
	ui.name = UI.label(ui.pane, {
		Name = "FileName",
		Text = "",
		Font = ctx.FONT_B,
		TextSize = 12,
		TextWrapped = true,
		TextYAlignment = Enum.TextYAlignment.Top,
		ZIndex = 6,
	})
	ui.detail = UI.label(ui.pane, {
		Name = "Detail",
		Text = "",
		TextSize = 11,
		TextColor3 = T.sub,
		TextWrapped = true,
		TextYAlignment = Enum.TextYAlignment.Top,
		ZIndex = 6,
	})
	ui.note = UI.label(ui.pane, {
		Name = "Note",
		Text = "",
		TextSize = 10,
		TextColor3 = T.dim,
		TextWrapped = true,
		TextYAlignment = Enum.TextYAlignment.Top,
		ZIndex = 6,
	})
	local out, holder = ctx.Ctl.buttons(ui.pane, 1, {
		{ "check", "Select", function()
			finish(s)
		end, T.dim },
		{ "x", "Cancel", function()
			hidePane(s)
		end },
	}, 36)
	ui.select = out[1]
	ui.cancel = out[2]
	ui.buttons = holder
	holder.ZIndex = 6
	for _, item in ipairs(out) do
		item.btn.ZIndex = 7
	end
end

local function build(s, w, body)
	s.ui.body = body
	buildToolbar(s, body)
	buildGrid(s, body)
	buildPane(s, body)
	s.refreshPane = Browser.refreshPane
	pcall(function()
		w:conn(body:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
			layoutAll(s)
			pump(s)
		end))
	end)
	layoutAll(s)
	updateToolbar(s)
	if not art.available().list then
		s.listing = false
		showMessage(s, "Your executor can't list the files in a folder, so there is nothing to browse here. Close this and type the picture's name instead.")
		return
	end
	local dir = s.opts.start
	if dir == nil then
		dir = art.lastFolder()
	end
	dir = art.normalizePath(dir)
	while dir ~= "" and not enter(s, dir, nil) do
		dir = Browser.parent(dir)
	end
	if dir == "" then
		enter(s, "", nil)
	end
end

local function closeState(s)
	if not s.alive then
		return
	end
	s.alive = false
	s.nav = s.nav + 1
	s.build = s.build + 1
	s.paneToken = s.paneToken + 1
	s.searchToken = s.searchToken + 1
	if current == s then
		current = nil
	end
	local copies = s.copies
	s.copies = {}
	if art and #copies > 0 then
		art.dropThumbs(copies)
	end
end

function Browser.open(artModule, opts)
	if not ctx then
		return false
	end
	art = artModule or art
	if not art then
		return false
	end
	sniff = ctx.Core.loadModule("imgsniff")
	if not sniff then
		toast("Pictures", "The picture checker didn't load. Reload the hub and try again.", "error", 4)
		return false
	end
	opts = opts or {}
	if current and current.alive then
		current.opts = opts
		ctx.Win.show("art_browser", current.def)
		return true
	end
	local s = {
		alive = true,
		dir = "",
		entries = {},
		view = {},
		cells = {},
		queue = {},
		queued = {},
		copies = {},
		search = "",
		sort = "name",
		allFiles = false,
		listing = false,
		paneOpen = false,
		paneToken = 0,
		searchToken = 0,
		nav = 0,
		build = 0,
		width = 0,
		height = 0,
		usable = false,
		opts = opts,
		ui = {},
	}
	s.def = {
		title = "Pick a picture",
		sub = "Workspace",
		icon = "folder-open",
		w = 330,
		h = 480,
		minW = 270,
		minH = 340,
		maxW = 600,
		maxH = 720,
		noScroll = true,
		build = function(w, body)
			s.w = w
			build(s, w, body)
		end,
		onClose = function()
			closeState(s)
		end,
	}
	current = s
	local w = ctx.Win.show("art_browser", s.def)
	s.w = s.w or w
	return true
end

function Browser.state()
	return current
end

function Browser.init(context)
	ctx = context
	art = nil
	sniff = nil
	current = nil
end

function Browser.destroy()
	local s = current
	current = nil
	if s then
		local w = s.w
		closeState(s)
		if w then
			pcall(w.close, w, true)
		end
	end
	ctx = nil
	art = nil
	sniff = nil
end

return Browser
