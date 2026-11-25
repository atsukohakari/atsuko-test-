local Pick = {}

local ctx = nil
local art = nil
local sessions = {}
local lastTab = "link"

local function trim(text)
	return (string.match(tostring(text or ""), "^%s*(.-)%s*$"))
end

local function firstLine(text)
	return (string.match(tostring(text or ""), "^[^\r\n]*"))
end

local function toast(title, text, kind, seconds)
	if ctx and ctx.notify then
		pcall(ctx.notify, title, text, kind, seconds)
	end
end

local function capital(text)
	return (string.gsub(tostring(text or ""), "^%l", string.upper))
end

local function parentOf(path)
	return string.match(tostring(path or ""), "^(.*)/[^/]+$") or ""
end

function Pick.previewSize(kind, avail)
	avail = math.max(60, tonumber(avail) or 0)
	if kind == "banner" then
		return avail, math.floor(avail / (art and art.RATIO or 3) + 0.5)
	end
	local side = math.min(avail, 112)
	return side, side
end

function Pick.hints(has)
	local file = "Type the name of a picture in your workspace folder."
	if has and has.list then
		file = "Type the name of a picture in your workspace folder, or tap Browse."
	end
	return {
		link = "Paste a picture link, or type a Roblox asset id.",
		file = file,
	}
end

local function setUsable(session, on)
	local ui = session.ui
	if not ui.use then
		return
	end
	local T = ctx.T
	session.usable = on == true
	ui.use.btn.BackgroundColor3 = on and ctx.accentColor() or T.card
	ui.use.set("check", "Use this", on and T.ink or T.dim)
end

local function showPreview(session, id)
	local ui = session.ui
	if not ui.pic then
		return
	end
	if id then
		ui.pic.Image = id
		ui.pic.ImageTransparency = 1
		ui.pic.Visible = true
		ui.hint.Visible = false
		ctx.UI.tween(ui.pic, art.FADE, { ImageTransparency = 0 })
	else
		ui.pic.Visible = false
		ui.pic.Image = ""
		ui.hint.Visible = true
	end
end

local function setStatus(session, mood, text, extra, extraMood)
	local ui, T = session.ui, ctx.T
	if not ui.status then
		return
	end
	local colors = { ok = T.green, bad = T.red, wait = T.sub, info = T.sub, warn = T.yellow }
	text = text or ""
	extra = extra or ""
	ui.status.Text = text
	ui.status.TextColor3 = colors[mood] or T.sub
	ui.status.Visible = text ~= ""
	ui.extra.Text = extra
	ui.extra.TextColor3 = extraMood == "warn" and T.yellow or T.dim
	ui.extra.Visible = extra ~= ""
end

local function discard(session)
	local result = session.result
	session.result = nil
	session.busy = false
	if result and result.ok and result.cached and art then
		art.release(result.cached)
	end
	setUsable(session, false)
end

local function layoutPreview(session)
	local ui = session.ui
	if not (ui.card and ctx) then
		return
	end
	local scale = math.max(0.01, ctx.L.scale or 1)
	local width = (ui.card.AbsoluteSize and ui.card.AbsoluteSize.X or 0) / scale
	if width < 60 then
		width = session.lastWidth or 270
	end
	session.lastWidth = width
	local pw, ph = Pick.previewSize(session.kind, width - 24)
	ui.holder.Size = UDim2.fromOffset(pw, ph)
	ui.holder.Position = UDim2.fromOffset(math.floor((width - pw) / 2), 12)
	ui.card.Size = UDim2.new(1, 0, 0, ph + 24)
	session.previewW, session.previewH = pw, ph
end

local function describeExtra(session, spec, result)
	local bits = {}
	local warn = false
	if result.warn then
		bits[#bits + 1] = result.warn
		warn = true
	end
	if spec and spec.rewritten then
		bits[#bits + 1] = "That GitHub page link was changed into the direct picture link."
	end
	if result.converted then
		bits[#bits + 1] = "Turned into a PNG by " .. art.converter().name .. "."
	end
	if result.note then
		bits[#bits + 1] = result.note
	end
	if result.unchecked then
		bits[#bits + 1] = "I couldn't test this in Roblox here, so the preview may stay empty if Roblox can't show it."
		warn = true
	end
	return table.concat(bits, " "), warn and "warn" or "info"
end

local function activeText(session)
	if session.tab == "link" then
		return session.link
	end
	return session.file
end

local function runCheck(session, force)
	if not (session.alive and ctx and art) then
		return
	end
	local text = activeText(session)
	if text == "" then
		session.token = session.token + 1
		session.key = nil
		discard(session)
		showPreview(session, nil)
		setStatus(session, "info", Pick.hints(session.has)[session.tab])
		return
	end
	local spec, why
	if session.tab == "link" then
		spec, why = art.parseLink(text)
	else
		spec, why = art.parseFile(text)
	end
	if not spec then
		session.token = session.token + 1
		session.key = nil
		discard(session)
		showPreview(session, nil)
		setStatus(session, "bad", capital(why))
		return
	end
	local key = session.tab .. "|" .. spec.value .. "|" .. tostring(session.convert and spec.src == "url")
	if not force and key == session.key then
		return
	end
	session.key = key
	session.token = session.token + 1
	local token = session.token
	discard(session)
	showPreview(session, nil)
	local waiting = "Reading the file..."
	if spec.src == "url" then
		waiting = "Downloading..."
	elseif spec.src == "asset" then
		waiting = "Asking Roblox for that picture..."
	end
	setStatus(session, "wait", waiting)
	session.busy = true
	art.resolve(spec, {
		host = session.ui.holder,
		convert = session.convert,
		alive = function()
			return session.alive and session.token == token
		end,
	}, function(result)
		if not (session.alive and session.token == token) then
			if type(result) == "table" and result.ok and result.cached and art then
				art.release(result.cached)
			end
			return
		end
		session.busy = false
		if result.cancelled then
			return
		end
		if result.ok then
			session.result = result
			session.spec = spec
			local extra, mood = describeExtra(session, spec, result)
			setStatus(session, "ok", "Ready  ·  " .. art.describe(result), extra, mood)
			showPreview(session, result.id)
			setUsable(session, true)
		else
			setStatus(session, "bad", result.why or "That picture can't be used.")
			showPreview(session, nil)
		end
	end)
end

local function applyTab(session, recheck)
	local ui = session.ui
	local link = session.tab == "link"
	ui.linkInput.row.Visible = link
	ui.fileInput.row.Visible = not link
	ui.linkButtons.Visible = link
	ui.fileButtons.Visible = not link
	if ui.convert then
		ui.convert.row.Visible = link
	end
	if ui.tabs then
		ui.tabs.render(recheck == true)
	end
	if recheck then
		session.key = nil
		runCheck(session)
	end
end

local function closeBrowserOf(session)
	if Pick.browserOwner == session then
		Pick.browserOwner = nil
		if ctx and ctx.Win and ctx.Win.close then
			pcall(ctx.Win.close, "art_browser")
		end
	end
end

local function closeSession(session)
	if not session.alive then
		return
	end
	session.alive = false
	session.token = session.token + 1
	if sessions[session.id] == session then
		sessions[session.id] = nil
	end
	closeBrowserOf(session)
	if not session.committed then
		discard(session)
	end
end

local function commit(session)
	local result = session.result
	if not result then
		toast(capital(session.kind), "Load a picture first", "info", 2)
		return
	end
	local ok, why = art.set(session.path, session.kind, result)
	if not ok then
		toast(capital(session.kind), capital(tostring(why)), "error", 3)
		return
	end
	session.committed = true
	session.result = nil
	toast(capital(session.kind), "Saved", "ok", 1.5)
	if session.w then
		session.w:close()
	end
end

local function remove(session)
	if art.clear(session.path, session.kind) then
		toast(capital(session.kind), "Removed", "info", 1.5)
	end
	if session.w then
		session.w:close()
	end
end

local function paste(session)
	local text = art.clipboard()
	text = text and trim(firstLine(trim(text))) or ""
	if text == "" then
		toast("Pictures", "Your clipboard is empty", "info", 2)
		return
	end
	session.link = text
	session.ui.linkInput.render()
	runCheck(session, true)
end

local function openBrowser(session)
	local browser = ctx.Core.loadModule("imagebrowser")
	if not browser then
		toast("Pictures", "The folder browser didn't load. Reload the hub and try again.", "error", 4)
		return
	end
	Pick.browserOwner = session
	browser.open(art, {
		start = session.file ~= "" and parentOf(session.file) or nil,
		kind = session.kind,
		onSelect = function(path)
			if not session.alive then
				return
			end
			session.tab = "file"
			lastTab = "file"
			session.file = path
			session.ui.fileInput.render()
			applyTab(session, false)
			session.key = nil
			runCheck(session, true)
		end,
	})
end

local function preselect(session)
	local item = art.get(session.path, session.kind)
	session.current = item
	if not item then
		return
	end
	if item.src == "file" then
		session.tab = "file"
		session.file = item.value
	elseif item.src == "url" then
		session.tab = "link"
		session.link = item.value
	else
		session.tab = "link"
		session.link = string.match(item.value, "^rbxassetid://(%d+)$") or item.value
	end
end

local function buildPreview(session, body)
	local UI, T = ctx.UI, ctx.T
	local ui = session.ui
	local radius = session.kind == "logo" and 16 or 14
	ui.card = UI.new("Frame", { Name = "Preview", BackgroundColor3 = T.card, BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 100), LayoutOrder = 5 }, body)
	UI.corner(ui.card, 12)
	ui.holder = UI.new("Frame", { Name = "Holder", BackgroundColor3 = T.card2, Position = UDim2.fromOffset(12, 12), Size = UDim2.fromOffset(100, 100), ClipsDescendants = true }, ui.card)
	UI.corner(ui.holder, radius)
	UI.stroke(ui.holder, T.stroke, 1, 0.4)
	ui.pic = UI.new("ImageLabel", {
		Name = "Picture",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		ScaleType = Enum.ScaleType.Crop,
		Image = "",
		ImageTransparency = 1,
		Visible = false,
	}, ui.holder)
	UI.corner(ui.pic, radius)
	ui.hint = UI.new("Frame", { Name = "Hint", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1) }, ui.holder)
	UI.icon("image", 22, T.dim, ui.hint, { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5) })
end

local function buildLabels(session, body)
	local UI, T = ctx.UI, ctx.T
	local ui = session.ui
	ui.status = UI.label(body, {
		Name = "Status",
		Text = "",
		TextSize = 11,
		TextColor3 = T.sub,
		TextWrapped = true,
		TextYAlignment = Enum.TextYAlignment.Top,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = 6,
		Visible = false,
	})
	UI.pad(ui.status, 4, 4, 0, 0)
	ui.extra = UI.label(body, {
		Name = "Extra",
		Text = "",
		TextSize = 10,
		TextColor3 = T.dim,
		TextWrapped = true,
		TextYAlignment = Enum.TextYAlignment.Top,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = 7,
		Visible = false,
	})
	UI.pad(ui.extra, 4, 4, 0, 0)
end

local function buildPicker(session, w, body)
	local Ctl, T = ctx.Ctl, ctx.T
	local ui = session.ui
	local has = session.has
	if has.files then
		ui.tabs = Ctl.choice(body, 1, "Where is the picture?", { { "link", "Link" }, { "file", "Workspace" } }, function()
			return session.tab
		end, function(value)
			session.tab = value
			lastTab = value
			applyTab(session, true)
		end)
	end
	ui.linkInput = Ctl.input(body, 2, "Picture link", "https://... or an asset id", function()
		return session.link
	end, function(text)
		session.link = text
		runCheck(session)
	end)
	ui.fileInput = Ctl.input(body, 2, "Picture in your workspace folder", "pics/me.png", function()
		return session.file
	end, function(text)
		session.file = text
		runCheck(session)
	end)
	local linkList = {}
	if has.clipboard then
		linkList[#linkList + 1] = { "link", "Paste", function()
			paste(session)
		end }
	end
	linkList[#linkList + 1] = { "image", "Load", function()
		runCheck(session, true)
	end }
	local _, linkHolder = Ctl.buttons(body, 3, linkList)
	ui.linkButtons = linkHolder
	local fileList = {}
	if has.list then
		fileList[#fileList + 1] = { "folder-open", "Browse", function()
			openBrowser(session)
		end }
	end
	fileList[#fileList + 1] = { "image", "Load", function()
		runCheck(session, true)
	end }
	local _, fileHolder = Ctl.buttons(body, 3, fileList)
	ui.fileButtons = fileHolder
	if has.request then
		ui.convert = Ctl.toggle(body, 4, "Convert with an online service", art.converter().note, function()
			return session.convert
		end, function(value)
			session.convert = value
			runCheck(session)
		end)
	end
	buildPreview(session, body)
	buildLabels(session, body)
	local actions = {}
	actions[#actions + 1] = { "check", "Use this", function()
		if session.usable then
			commit(session)
		elseif session.busy then
			toast(capital(session.kind), "Still checking that picture", "info", 2)
		else
			toast(capital(session.kind), "Load a picture first", "info", 2)
		end
	end, T.dim }
	actions[#actions + 1] = { "x", "Cancel", function()
		w:close()
	end }
	if session.current then
		actions[#actions + 1] = { "trash-2", "Remove", function()
			remove(session)
		end, T.red }
	end
	local out = Ctl.buttons(body, 8, actions)
	ui.use = out[1]
	pcall(function()
		w:conn(body:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
			layoutPreview(session)
		end))
		w:conn(ui.card:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
			layoutPreview(session)
		end))
	end)
	layoutPreview(session)
	applyTab(session, false)
	setUsable(session, false)
	if session.current then
		local id = art.imageFor(session.current)
		if id then
			showPreview(session, id)
		end
		setStatus(session, "info", "This is the picture you use now  ·  " .. art.describe(session.current))
	else
		setStatus(session, "info", Pick.hints(session.has)[session.tab])
	end
	if activeText(session) ~= "" and session.current then
		session.key = session.tab .. "|" .. activeText(session) .. "|false"
	end
end

function Pick.open(artModule, path, kind, name)
	if not ctx or type(path) ~= "string" or (kind ~= "logo" and kind ~= "banner") then
		return false
	end
	art = artModule or art
	if not art then
		return false
	end
	local id = "art_" .. kind
	local existing = sessions[id]
	if existing and existing.alive then
		if existing.path == path then
			ctx.Win.show(id, existing.def)
			return true
		end
		if existing.w then
			existing.w:close(true)
		end
		closeSession(existing)
	end
	local session = {
		id = id,
		path = path,
		kind = kind,
		name = name,
		alive = true,
		tab = lastTab,
		link = "",
		file = "",
		convert = false,
		token = 0,
		usable = false,
		ui = {},
		has = art.available(),
	}
	preselect(session)
	if not session.has.files then
		session.tab = "link"
	end
	session.def = {
		title = capital(kind),
		sub = name or "Script",
		icon = "image",
		w = 300,
		h = 520,
		minW = 260,
		minH = 340,
		maxW = 420,
		maxH = 700,
		build = function(w, body)
			session.w = w
			buildPicker(session, w, body)
		end,
		onClose = function()
			closeSession(session)
		end,
	}
	sessions[id] = session
	local w = ctx.Win.show(id, session.def)
	session.w = session.w or w
	return true
end

function Pick.sessionFor(kind)
	return sessions["art_" .. kind]
end

function Pick.init(context)
	ctx = context
	art = nil
	sessions = {}
	Pick.browserOwner = nil
end

function Pick.destroy()
	local list = {}
	for _, session in pairs(sessions) do
		list[#list + 1] = session
	end
	for _, session in ipairs(list) do
		local w = session.w
		closeSession(session)
		if w then
			pcall(w.close, w, true)
		end
	end
	sessions = {}
	Pick.browserOwner = nil
	ctx = nil
	art = nil
end

return Pick
