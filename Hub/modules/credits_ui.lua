local Mod = {}

Mod.CACHE = "Atsuko Hub/data/credits_cache.json"
Mod.ROBLOX_PREFIX = "https://www.roblox.com/"
Mod.KINDS = { person = true, team = true, project = true, service = true, assistant = true }
Mod.KIND_NAMES = { person = "Person", team = "Team", project = "Project", service = "Service", assistant = "AI assistant" }
Mod.STYLES = { full = true, roblox = true }
Mod.LINK_KEYS = { "github", "discord", "youtube", "website", "roblox" }
Mod.LINK_NAMES = { github = "GitHub", discord = "Discord", youtube = "YouTube", website = "Website", roblox = "Roblox", other = "Link" }
Mod.LINK_ICONS = { github = "code", discord = "message-circle", youtube = "video", website = "globe", roblox = "link", other = "link" }
Mod.FORBIDDEN = { "miyu", "onerui", "leaked by" }
Mod.NOT_CREDITED = { roblox = true }
Mod.MAX_TEXT = 400
Mod.TESTER_ID = "tester-11345577877"
Mod.TESTER_USER_ID = 11345577877
Mod.TESTER_SENTENCE = "Just a tester lol, he's a cool guy :3"
Mod.PICTURE_DIR = "Hub/credits/"
Mod.BADGE_FILE = "Hub/credits/verified.png"
Mod.PHONE_W = 600
Mod.WINDOW_MAX_W = 820
Mod.WINDOW_MAX_H = 660
Mod.CARD_H = 118
Mod.FEATURE_H = 176
Mod.GAP = 10
Mod.PAD = 16
Mod.SWIPE_CLOSE = 90
Mod.COMPACT_H = 540
Mod.ONE_ROW_W = 560
Mod.RADIUS = 24
Mod.BADGE_RGB = { 0, 162, 255 }

local ctx = nil
local state = nil

local function isText(value)
	return type(value) == "string"
end

local function trim(text)
	return (string.match(tostring(text or ""), "^%s*(.-)%s*$"))
end

local function starts(text, prefix)
	return string.sub(text, 1, #prefix) == prefix
end

local function textList(list)
	local out = {}
	if type(list) == "table" then
		for _, value in ipairs(list) do
			if isText(value) and trim(value) ~= "" then
				out[#out + 1] = value
			end
		end
	end
	return out
end

local function finite(value, fallback)
	value = tonumber(value)
	if value == nil or value ~= value or value == math.huge or value == -math.huge then
		return fallback
	end
	return value
end

function Mod.linkProblem(key, value)
	if value == nil or value == "" then
		return nil
	end
	if not isText(value) then
		return "is not text"
	end
	if not starts(value, "https://") then
		return "does not start with https://"
	end
	if string.find(value, "%s") then
		return "has a space"
	end
	if string.find(value, "?si=", 1, true) then
		return "carries a tracking tail"
	end
	if key == "roblox" and not starts(value, Mod.ROBLOX_PREFIX) then
		return "is not on www.roblox.com"
	end
	if key == "discord" and not (starts(value, "https://discord.gg/") or starts(value, "https://discord.com/invite/")) then
		return "is not a discord invite"
	end
	if key == "github" and not starts(value, "https://github.com/") then
		return "is not on github.com"
	end
	if key == "youtube" and not (starts(value, "https://youtube.com/") or starts(value, "https://www.youtube.com/")) then
		return "is not on youtube.com"
	end
	return nil
end

function Mod.pictureKind(src)
	if not isText(src) then
		return nil
	end
	src = trim(src)
	if src == "" then
		return nil
	end
	if string.find(src, "^%d+$") or string.find(src, "^rbxassetid://%d+$") or string.find(src, "^rbxthumb://") then
		return "asset"
	end
	if string.find(src, "^https://[^%s]+$") then
		return "web"
	end
	local name = string.match(src, "^Hub/credits/([%w_%-]+)%.%a+$")
	local ext = string.lower(string.match(src, "%.(%a+)$") or "")
	if name and (ext == "png" or ext == "jpg" or ext == "jpeg") then
		return "file"
	end
	return nil
end

function Mod.handleProblem(value)
	if value == nil or value == "" then
		return nil
	end
	if not isText(value) or not string.find(value, "^[%w_%.%-]+$") or #value < 2 or #value > 32 then
		return "handle may only use letters, digits, _ . and - (2 to 32 of them)"
	end
	return nil
end

local function plainOnly(text)
	return string.find(text, "[^\32-\126]") == nil
end

function Mod.entryProblems(entry, index, sections)
	local problems = {}
	if type(entry) ~= "table" then
		return { "people[" .. index .. "] is not an object" }
	end
	local where = isText(entry.id) and entry.id ~= "" and entry.id or ("people[" .. index .. "]")
	local function add(text)
		problems[#problems + 1] = where .. ": " .. text
	end
	if not isText(entry.id) or not string.find(entry.id, "^[a-z0-9][a-z0-9%-]*$") then
		add("id is missing or not lowercase letters, digits and dashes")
	end
	if not isText(entry.name) or trim(entry.name) == "" then
		add("name is missing")
	end
	if Mod.NOT_CREDITED[entry.id] or (isText(entry.name) and Mod.NOT_CREDITED[string.lower(trim(entry.name))]) then
		add("the owner asked for this one not to be credited")
	end
	if not Mod.KINDS[entry.kind] then
		add("kind must be person, team, project, service or assistant")
	end
	local style = entry.profileStyle
	if style == nil then
		style = "full"
	end
	if not Mod.STYLES[style] then
		add("profileStyle must be full or roblox")
	end
	local known = false
	for _, name in ipairs(sections) do
		if name == entry.section then
			known = true
		end
	end
	if not known then
		add("section is not one of the listed sections")
	end
	local roles = entry.roles
	local rolesOk = type(roles) == "table" and #roles > 0
	if rolesOk then
		for _, role in ipairs(roles) do
			if not isText(role) or trim(role) == "" then
				rolesOk = false
			end
		end
	end
	if not rolesOk then
		add("roles needs at least one text")
	end
	if entry.usedIn ~= nil then
		local usedOk = type(entry.usedIn) == "table"
		if usedOk then
			for _, value in ipairs(entry.usedIn) do
				if not isText(value) then
					usedOk = false
				end
			end
		end
		if not usedOk then
			add("usedIn must be a list of text")
		end
	end
	if not isText(entry.source) or trim(entry.source) == "" then
		add("source is empty, say where the facts came from")
	end
	if entry.verified ~= nil and type(entry.verified) ~= "boolean" then
		add("verified must be true or false")
	end
	if entry.picture ~= nil and entry.picture ~= "" and not Mod.pictureKind(entry.picture) then
		add("picture must be a Roblox image id, an https link or a .png or .jpg file in Hub/credits/")
	end
	local handleWhy = Mod.handleProblem(entry.handle)
	if handleWhy then
		add(handleWhy)
	end
	local links = entry.links
	if links == nil then
		links = {}
	end
	if type(links) ~= "table" then
		add("links is not an object")
		links = {}
	end
	for _, key in ipairs(Mod.LINK_KEYS) do
		local why = Mod.linkProblem(key, links[key])
		if why then
			add("links." .. key .. " " .. why)
		end
	end
	if links.other ~= nil then
		if type(links.other) ~= "table" then
			add("links.other is not a list")
		else
			for _, item in ipairs(links.other) do
				if not isText(item) or not starts(item, "https://") or string.find(item, "%s") then
					add("links.other has an address that is not https://")
				end
			end
		end
	end
	local rb = entry.roblox
	if rb == nil then
		rb = {}
	end
	if type(rb) ~= "table" then
		add("roblox is not an object")
		rb = {}
	end
	local username = rb.username
	if username == nil then
		username = ""
	end
	local userId = rb.userId
	if username ~= "" and (not isText(username) or not string.find(username, "^[%w_]+$") or #username < 3 or #username > 20) then
		add("roblox.username is not a valid username")
	end
	if userId ~= nil and (type(userId) ~= "number" or userId <= 0 or userId % 1 ~= 0) then
		add("roblox.userId must be a positive whole number or null")
	end
	if not isText(entry.description) or trim(entry.description) == "" then
		if style == "roblox" then
			add("a roblox profile needs a description")
		else
			add("description is missing")
		end
	end
	if style == "roblox" then
		if username == "" and userId == nil then
			add("a roblox profile needs roblox.userId or roblox.username")
		end
	end
	for _, key in ipairs({ "why", "did" }) do
		if entry[key] ~= nil then
			add(key .. " is not used anymore, put it in the description")
		end
	end
	if entry.id == Mod.TESTER_ID then
		if entry.description ~= Mod.TESTER_SENTENCE then
			add("the description is not the owner's sentence, byte for byte")
		end
		if userId ~= Mod.TESTER_USER_ID then
			add("roblox.userId is not " .. Mod.TESTER_USER_ID)
		end
		if username ~= "" then
			add("the username must stay empty, it is read from Roblox at run time")
		end
		if links.roblox ~= "https://www.roblox.com/users/" .. Mod.TESTER_USER_ID .. "/profile" then
			add("links.roblox is not the profile address the owner gave")
		end
		if entry.profileStyle ~= "roblox" then
			add("the tester uses the roblox profile style")
		end
	end
	for _, key in ipairs({ "name", "description", "license", "source" }) do
		local value = entry[key]
		if isText(value) and value ~= "" then
			if not plainOnly(value) then
				add(key .. " has characters outside plain text")
			end
			if #value > Mod.MAX_TEXT then
				add(key .. " is longer than " .. Mod.MAX_TEXT .. " characters")
			end
			local low = string.lower(value)
			for _, word in ipairs(Mod.FORBIDDEN) do
				if string.find(low, word, 1, true) then
					add(key .. " mentions " .. word)
				end
			end
		end
	end
	return problems
end

function Mod.validate(data)
	if type(data) ~= "table" then
		return { "the file is not an object" }
	end
	local problems = {}
	if data.version ~= 1 then
		problems[#problems + 1] = "version must be 1"
	end
	local sections = {}
	if type(data.sections) == "table" then
		for _, name in ipairs(data.sections) do
			if isText(name) and name ~= "" then
				sections[#sections + 1] = name
			end
		end
	end
	if #sections == 0 then
		problems[#problems + 1] = "sections must be a list of text"
	end
	if type(data.people) ~= "table" or #data.people == 0 then
		problems[#problems + 1] = "people must be a list with entries"
		return problems
	end
	local seen = {}
	for index, entry in ipairs(data.people) do
		for _, text in ipairs(Mod.entryProblems(entry, index, sections)) do
			problems[#problems + 1] = text
		end
		if type(entry) == "table" and isText(entry.id) then
			if seen[entry.id] then
				problems[#problems + 1] = entry.id .. ": the id is used twice"
			end
			seen[entry.id] = true
		end
	end
	for _, name in ipairs(sections) do
		local any = false
		for _, entry in ipairs(data.people) do
			if type(entry) == "table" and entry.section == name then
				any = true
			end
		end
		if not any then
			problems[#problems + 1] = "section '" .. name .. "' has nobody in it"
		end
	end
	for _, id in ipairs({ "atsuko", "claude", "tester-11345577877", "tory" }) do
		if not seen[id] then
			problems[#problems + 1] = "the entry " .. id .. " is missing"
		end
	end
	return problems
end

function Mod.cleanEntry(entry, sections)
	local links = type(entry.links) == "table" and entry.links or {}
	local cleanLinks = { other = {} }
	for _, key in ipairs(Mod.LINK_KEYS) do
		local value = links[key]
		cleanLinks[key] = (isText(value) and not Mod.linkProblem(key, value)) and value or ""
	end
	for _, item in ipairs(textList(links.other)) do
		if starts(item, "https://") and not string.find(item, "%s") then
			cleanLinks.other[#cleanLinks.other + 1] = item
		end
	end
	local rb = type(entry.roblox) == "table" and entry.roblox or {}
	local username = isText(rb.username) and string.find(rb.username, "^[%w_]+$") and #rb.username >= 3 and #rb.username <= 20 and rb.username or ""
	local userId = type(rb.userId) == "number" and rb.userId > 0 and rb.userId % 1 == 0 and rb.userId or nil
	local style = entry.profileStyle == "roblox" and (username ~= "" or userId ~= nil) and "roblox" or "full"
	local section = isText(entry.section) and entry.section or "Other"
	local known = false
	for _, name in ipairs(sections) do
		if name == section then
			known = true
		end
	end
	if not known then
		sections[#sections + 1] = section
	end
	local roles = textList(entry.roles)
	local picture = isText(entry.picture) and Mod.pictureKind(entry.picture) and trim(entry.picture) or ""
	return {
		id = entry.id,
		name = entry.name,
		kind = entry.kind,
		section = section,
		roles = #roles > 0 and roles or { string.upper(string.sub(entry.kind, 1, 1)) .. string.sub(entry.kind, 2) },
		usedIn = textList(entry.usedIn),
		links = cleanLinks,
		roblox = { username = username, userId = userId },
		profileStyle = style,
		description = isText(entry.description) and entry.description or "",
		license = isText(entry.license) and entry.license or "",
		verified = entry.verified == true,
		picture = picture,
		handle = (isText(entry.handle) and not Mod.handleProblem(entry.handle)) and entry.handle or "",
	}
end

function Mod.sanitize(data)
	local out = { sections = {}, people = {}, skipped = {} }
	if type(data) ~= "table" or type(data.people) ~= "table" then
		return out
	end
	out.sections = textList(data.sections)
	local seen = {}
	for index, entry in ipairs(data.people) do
		local good = type(entry) == "table" and isText(entry.id) and entry.id ~= "" and isText(entry.name) and trim(entry.name) ~= ""
			and Mod.KINDS[entry.kind] == true and not seen[entry.id] and not Mod.NOT_CREDITED[entry.id]
		if good then
			seen[entry.id] = true
			out.people[#out.people + 1] = Mod.cleanEntry(entry, out.sections)
		else
			out.skipped[#out.skipped + 1] = index
		end
	end
	return out
end

function Mod.profileUrl(entry)
	local links = type(entry.links) == "table" and entry.links or {}
	local direct = links.roblox
	if isText(direct) and starts(direct, Mod.ROBLOX_PREFIX) then
		return direct
	end
	local rb = type(entry.roblox) == "table" and entry.roblox or {}
	local id = rb.userId
	if type(id) == "number" and id > 0 and id % 1 == 0 then
		return string.format("https://www.roblox.com/users/%d/profile", id)
	end
	return nil
end

function Mod.monogram(name)
	local letter = string.match(tostring(name or ""), "%w")
	if letter then
		return string.upper(letter)
	end
	return "?"
end

function Mod.rowRole(entry)
	local roles = entry.roles or {}
	local first = roles[1] or ""
	if #roles > 1 then
		return first .. " +" .. (#roles - 1)
	end
	return first
end

function Mod.blurb(entry)
	local value = entry.description
	if isText(value) and trim(value) ~= "" then
		return value
	end
	return ""
end

function Mod.kindName(entry)
	return Mod.KIND_NAMES[entry.kind] or "Credit"
end

function Mod.haystack(entry)
	local parts = { entry.name, entry.section, entry.kind }
	for _, role in ipairs(entry.roles or {}) do
		parts[#parts + 1] = role
	end
	for _, used in ipairs(entry.usedIn or {}) do
		parts[#parts + 1] = used
	end
	if type(entry.roblox) == "table" and isText(entry.roblox.username) then
		parts[#parts + 1] = entry.roblox.username
	end
	if isText(entry.handle) then
		parts[#parts + 1] = entry.handle
	end
	if entry.verified == true then
		parts[#parts + 1] = "verified"
	end
	return string.lower(table.concat(parts, " "))
end

function Mod.matches(entry, query)
	query = string.lower(trim(query))
	if query == "" then
		return true
	end
	local hay = Mod.haystack(entry)
	for word in string.gmatch(query, "%S+") do
		if not string.find(hay, word, 1, true) then
			return false
		end
	end
	return true
end

function Mod.groups(clean, query, filter)
	local out, byName = {}, {}
	for _, name in ipairs(clean.sections) do
		local group = { title = name, items = {} }
		out[#out + 1] = group
		byName[name] = group
	end
	for _, entry in ipairs(clean.people) do
		if Mod.matches(entry, query) and byName[entry.section] then
			table.insert(byName[entry.section].items, entry)
		end
	end
	local shown = {}
	for _, group in ipairs(out) do
		if #group.items > 0 and (filter == nil or filter == "" or filter == "All" or filter == group.title) then
			shown[#shown + 1] = group
		end
	end
	return shown
end

function Mod.filters(clean)
	local out = { { title = "All", count = #clean.people } }
	for _, name in ipairs(clean.sections) do
		local n = 0
		for _, entry in ipairs(clean.people) do
			if entry.section == name then
				n += 1
			end
		end
		if n > 0 then
			out[#out + 1] = { title = name, count = n }
		end
	end
	return out
end

function Mod.featured(clean)
	local out = {}
	for _, entry in ipairs(clean.people) do
		if entry.verified and #out < 6 then
			out[#out + 1] = entry
		end
	end
	return out
end

function Mod.stats(clean)
	local groups, verified = 0, 0
	for _, f in ipairs(Mod.filters(clean)) do
		if f.title ~= "All" then
			groups += 1
		end
	end
	for _, entry in ipairs(clean.people) do
		if entry.verified then
			verified += 1
		end
	end
	local n = #clean.people
	local parts = { n .. " credited", groups .. (groups == 1 and " group" or " groups") }
	if verified > 0 then
		parts[#parts + 1] = verified .. " verified"
	end
	return table.concat(parts, "  ·  ")
end

function Mod.plainText(clean)
	local lines = {}
	for _, entry in ipairs(clean.people) do
		local line = entry.name .. " - " .. entry.description
		local ordered = {}
		for _, key in ipairs(Mod.LINK_KEYS) do
			if entry.links[key] ~= "" then
				ordered[#ordered + 1] = entry.links[key]
			end
		end
		for _, item in ipairs(entry.links.other) do
			ordered[#ordered + 1] = item
		end
		if #ordered > 0 then
			line = line .. " - " .. table.concat(ordered, " - ")
		end
		lines[#lines + 1] = line
	end
	return table.concat(lines, "\n")
end

function Mod.wrapLines(width, available)
	return math.max(1, math.ceil(width / math.max(1, available)))
end

function Mod.windowRect(viewW, viewH, inset)
	viewW = math.max(160, finite(viewW, 1280))
	viewH = math.max(200, finite(viewH, 720))
	inset = math.max(0, math.min(finite(inset, 0), viewH * 0.25))
	if viewW < Mod.PHONE_W or viewH < 460 then
		local top = math.floor(math.max(math.min(56, math.max(8, viewH * 0.05)), inset + 8))
		local w = math.floor(viewW - 16)
		local h = math.floor(viewH - top - 8)
		return 8, top, w, h, "sheet"
	end
	local w = math.floor(math.min(Mod.WINDOW_MAX_W, viewW - 80))
	local h = math.floor(math.min(Mod.WINDOW_MAX_H, viewH - 64, viewH - inset - 16))
	local y = math.max(math.floor((viewH - h) / 2), math.floor(inset + 8))
	return math.floor((viewW - w) / 2), y, w, h, "window"
end

function Mod.columns(width)
	width = finite(width, 0)
	if width >= 600 then
		return 3
	end
	if width >= 340 then
		return 2
	end
	return 1
end

function Mod.featuredColumns(width, count)
	count = math.max(1, finite(count, 1))
	if finite(width, 0) >= 600 then
		return math.min(3, count)
	end
	if finite(width, 0) >= 440 then
		return math.min(2, count)
	end
	return 1
end

function Mod.cellWidth(width, cols, gap)
	cols = math.max(1, math.floor(finite(cols, 1)))
	gap = finite(gap, Mod.GAP)
	return math.max(80, math.floor((finite(width, 0) - gap * (cols - 1)) / cols))
end

function Mod.fitName(textW, maxW, badge)
	textW = math.max(0, finite(textW, 0))
	maxW = math.max(0, finite(maxW, 0))
	local room = badge and (maxW - badge - 5) or maxW
	local labelW = math.max(0, math.min(math.ceil(textW) + 2, room))
	local used = labelW + (badge and (badge + 5) or 0)
	return labelW, used, labelW < math.ceil(textW) + 2
end

function Mod.cacheDecode(text, decode)
	local data = decode(text)
	local out = { names = {}, ids = {} }
	if type(data) ~= "table" then
		return out
	end
	if type(data.names) == "table" then
		for key, value in pairs(data.names) do
			if isText(key) and type(value) == "table" and (isText(value.username) or isText(value.display)) then
				out.names[key] = { username = isText(value.username) and value.username or nil, display = isText(value.display) and value.display or nil }
			end
		end
	end
	if type(data.ids) == "table" then
		for key, value in pairs(data.ids) do
			if isText(key) and type(value) == "number" and value > 0 then
				out.ids[key] = value
			end
		end
	end
	return out
end

function Mod.cacheEncode(names, ids, encode)
	return encode({ version = 1, names = names, ids = ids })
end

function Mod.displayName(entry, identity)
	local found = identity and (identity.display or identity.username)
	if found and found ~= "" then
		return found
	end
	return entry.name
end

function Mod.handleText(entry, identity)
	local user = identity and identity.username
	if isText(user) and user ~= "" then
		return "@" .. user
	end
	if isText(entry.handle) and entry.handle ~= "" then
		return "@" .. entry.handle
	end
	return nil
end

function Mod.thumbSpec(kind)
	if kind == "head" then
		return "HeadShot", "Size100x100"
	end
	if kind == "big" then
		return "AvatarBust", "Size420x420"
	end
	return "AvatarBust", "Size150x150"
end

function Mod.sniff(data)
	if not isText(data) then
		return nil
	end
	if string.sub(data, 1, 4) == "\137PNG" then
		return "png"
	end
	if string.sub(data, 1, 3) == "\255\216\255" then
		return "jpg"
	end
	return nil
end

function Mod.init(context)
	ctx = context
end

local function alive()
	return ctx ~= nil and state ~= nil and state.alive
end

local function connect(signal, fn)
	local conn = signal:Connect(fn)
	if state then
		state.conns[#state.conns + 1] = conn
	end
	return conn
end

local function spawnLater(delay, fn)
	task.delay(delay, function()
		if alive() then
			fn()
		end
	end)
end

local function tapKind(input)
	local kind = input.UserInputType
	return kind == Enum.UserInputType.MouseButton1 or kind == Enum.UserInputType.Touch
end

local function rectOf(gui)
	local ok, x, y, w, h = pcall(function()
		return gui.AbsolutePosition.X, gui.AbsolutePosition.Y, gui.AbsoluteSize.X, gui.AbsoluteSize.Y
	end)
	if ok and type(w) == "number" and w > 0 and type(h) == "number" and h > 0 then
		return x, y, w, h
	end
	return nil
end

local function badgeColor()
	return Color3.fromRGB(Mod.BADGE_RGB[1], Mod.BADGE_RGB[2], Mod.BADGE_RGB[3])
end

function Mod.badge(parent, size, props)
	local ui = ctx.UI
	local holder = ui.new("Frame", { Name = "Verified", BackgroundTransparency = 1, Size = UDim2.fromOffset(size, size) }, parent)
	local drawn = {}
	for _, turn in ipairs({ 0, 45 }) do
		local seal = ui.new("Frame", {
			Name = "Seal",
			BackgroundColor3 = badgeColor(),
			BorderSizePixel = 0,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(0.74, 0.74),
			Rotation = turn,
		}, holder)
		ui.corner(seal, math.max(1, math.floor(size * 0.16)))
		drawn[#drawn + 1] = seal
	end
	drawn[#drawn + 1] = ui.icon("check", math.max(6, math.floor(size * 0.6 + 0.5)), Color3.new(1, 1, 1), holder, { Name = "Tick", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5) })
	local official = ui.new("ImageLabel", { Name = "Official", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ScaleType = Enum.ScaleType.Fit, Visible = false }, holder)
	if props then
		for key, value in pairs(props) do
			holder[key] = value
		end
	end
	if Mod.loadBadge then
		Mod.loadBadge(function(id)
			if id and holder.Parent then
				official.Image = id
				official.Visible = true
				for _, piece in ipairs(drawn) do
					piece.Visible = false
				end
			end
		end)
	end
	return holder
end

local function nameRow(parent, text, size, font, color, badgeSize, maxW, centered, props)
	local ui = ctx.UI
	local h = size + 6
	local row = ui.new("Frame", { Name = "NameRow", BackgroundTransparency = 1, Size = UDim2.fromOffset(maxW, h) }, parent)
	local label = ui.label(row, {
		Name = "Who",
		Text = text,
		Font = font,
		TextSize = size,
		TextColor3 = color,
		Size = UDim2.fromOffset(10, h),
		TextTruncate = Enum.TextTruncate.AtEnd,
	})
	local badge = badgeSize and Mod.badge(row, badgeSize, { AnchorPoint = Vector2.new(0, 0.5) }) or nil
	local fit = { row = row, label = label, badge = badge, max = maxW }
	function fit.set(newText, newMax)
		if newText ~= nil then
			label.Text = newText
		end
		if newMax ~= nil then
			fit.max = newMax
		end
		local labelW, used = Mod.fitName(ctx.textWidth(label.Text, size, font), fit.max, badgeSize)
		label.Size = UDim2.fromOffset(labelW, h)
		if badge then
			badge.Position = UDim2.new(0, labelW + 5, 0.5, 0)
		end
		if centered then
			row.Size = UDim2.fromOffset(used, h)
		else
			row.Size = UDim2.fromOffset(fit.max, h)
		end
	end
	if props then
		for key, value in pairs(props) do
			row[key] = value
		end
	end
	fit.set()
	return fit
end

local function hasRobloxAccount(entry)
	return entry.roblox.userId ~= nil or entry.roblox.username ~= ""
end

local function identityOf(entry)
	local rb = entry.roblox
	local userId = rb.userId
	if userId == nil and rb.username ~= "" then
		userId = state.ids[rb.username]
	end
	local names = userId and state.names[tostring(userId)] or nil
	local username = rb.username ~= "" and rb.username or (names and names.username) or nil
	return { userId = userId, username = username, display = names and names.display or nil }
end

local function saveCache()
	if state.saving then
		return
	end
	state.saving = true
	spawnLater(1, function()
		state.saving = false
		local text = Mod.cacheEncode(state.names, state.ids, ctx.jsonEncode)
		if text then
			pcall(ctx.FS.write, Mod.CACHE, text)
		end
	end)
end

local function fetchIdentity(entry)
	local rb = entry.roblox
	local players = ctx.Players
	local userId = rb.userId
	if userId == nil and rb.username ~= "" then
		userId = state.ids[rb.username]
		if userId == nil then
			local ok, found = pcall(function()
				return players:GetUserIdFromNameAsync(rb.username)
			end)
			if ok and type(found) == "number" and found > 0 then
				userId = found
				state.ids[rb.username] = found
				saveCache()
			end
		end
	end
	if userId == nil then
		return nil
	end
	local key = tostring(userId)
	if not state.refreshed[key] then
		state.refreshed[key] = true
		local names = state.names[key] or {}
		local okName, name = pcall(function()
			return players:GetNameFromUserIdAsync(userId)
		end)
		if okName and isText(name) and name ~= "" then
			names.username = name
		end
		local okInfo, infos = pcall(function()
			local service = ctx.UserService or game:GetService("UserService")
			return service:GetUserInfosByUserIdsAsync({ userId })
		end)
		if okInfo and type(infos) == "table" and type(infos[1]) == "table" and isText(infos[1].DisplayName) and infos[1].DisplayName ~= "" then
			names.display = infos[1].DisplayName
		elseif names.username and not names.display then
			names.display = names.username
		end
		if names.username or names.display then
			state.names[key] = names
			saveCache()
		end
	end
	return userId
end

local function fetchThumb(userId, kind)
	local key = kind .. "|" .. tostring(userId)
	local have = state.thumbs[key]
	if have ~= nil then
		return have
	end
	local typeName, sizeName = Mod.thumbSpec(kind)
	local ok, image, ready = pcall(function()
		return ctx.Players:GetUserThumbnailAsync(userId, Enum.ThumbnailType[typeName], Enum.ThumbnailSize[sizeName])
	end)
	if ok and isText(image) and image ~= "" and ready == true then
		state.thumbs[key] = image
		return image
	end
	state.thumbs[key] = false
	return false
end

local function showPhoto(slot, image)
	if not slot.holder.Parent then
		return
	end
	slot.image.Image = image
	slot.image.Visible = true
	slot.mono.Visible = false
end

local function applyAvatar(slot)
	if not slot.holder.Parent then
		return
	end
	local identity = identityOf(slot.entry)
	if slot.onIdentity then
		pcall(slot.onIdentity, identity)
	end
	if slot.picture then
		return
	end
	if identity.userId then
		local image = state.thumbs[slot.kind .. "|" .. tostring(identity.userId)]
		if image then
			showPhoto(slot, image)
		end
	end
end

local function pulse(slot)
	task.spawn(function()
		local dim = true
		local guard = 0
		while alive() and slot.loading and slot.holder.Parent and guard < 40 do
			guard += 1
			ctx.UI.tween(slot.holder, 0.6, { BackgroundTransparency = dim and 0.55 or 0 }, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
			dim = not dim
			task.wait(0.6)
		end
		if slot.holder.Parent then
			slot.holder.BackgroundTransparency = 0
		end
	end)
end

local function pump()
	if state.pumping then
		return
	end
	state.pumping = true
	local mine = state
	task.spawn(function()
		task.wait()
		while mine.alive and #mine.queue > 0 do
			local slot = table.remove(mine.queue, 1)
			if slot.holder.Parent then
				local userId = fetchIdentity(slot.entry)
				if userId then
					fetchThumb(userId, slot.kind)
				end
			end
			slot.loading = false
			if mine.alive then
				applyAvatar(slot)
			end
			task.wait(0.05)
		end
		mine.pumping = false
	end)
end

local function packagePicture(rel)
	local X, FS = ctx.X, ctx.FS
	if not (ctx.HAS_FS and X.getcustomasset) then
		return nil
	end
	local origin = ctx.Origin
	if origin and origin.root then
		local path = origin.root .. "/" .. rel
		local data = FS.read(path)
		if not Mod.sniff(data) then
			return nil
		end
		local ok, id = pcall(X.getcustomasset, path)
		if ok and isText(id) and id ~= "" then
			return id
		end
		return nil
	end
	local data = ctx.Core.fileSource(rel)
	local ext = Mod.sniff(data)
	if not ext then
		return nil
	end
	local dir = ctx.Core.IMG_DIR or "Atsuko Hub/images"
	local path = dir .. "/credit_" .. ctx.Util.hash(rel) .. "_" .. #data .. "." .. ext
	if not FS.exists(path) and not FS.write(path, data) then
		return nil
	end
	local ok, id = pcall(X.getcustomasset, path)
	if ok and isText(id) and id ~= "" then
		return id
	end
	return nil
end

local function webPicture(src)
	local imageSource = ctx.Core.imageSource
	if type(imageSource) ~= "function" then
		return nil
	end
	local done, got = false, nil
	local id = imageSource(src, function(result)
		got = result
		done = true
	end)
	if id then
		return id
	end
	local waited = 0
	while not done and waited < 15 and alive() do
		task.wait(0.1)
		waited += 0.1
	end
	return got
end

local function resolvePicture(src)
	local kind = Mod.pictureKind(src)
	if kind == "file" then
		return packagePicture(src)
	end
	if kind == "asset" then
		if string.find(src, "^%d+$") then
			return "rbxassetid://" .. src
		end
		return src
	end
	if kind == "web" then
		return webPicture(src)
	end
	return nil
end

local function loadPicture(src, done)
	local have = state.pics[src]
	if have ~= nil then
		done(have or nil)
		return
	end
	local waiting = state.picWait[src]
	if waiting then
		waiting[#waiting + 1] = done
		return
	end
	state.picWait[src] = { done }
	local mine = state
	task.spawn(function()
		local ok, id = pcall(resolvePicture, src)
		if not ok then
			id = nil
			ctx.Log.add("warn", "Hub", "credits picture " .. src .. ": " .. tostring(id))
		end
		mine.pics[src] = id or false
		local list = mine.picWait[src] or {}
		mine.picWait[src] = nil
		if mine.alive then
			for _, fn in ipairs(list) do
				pcall(fn, id)
			end
		end
	end)
end

function Mod.loadBadge(done)
	if state then
		loadPicture(Mod.BADGE_FILE, done)
	end
end

local function makeAvatar(parent, entry, size, kind, props)
	local ui, T = ctx.UI, ctx.T
	local holder = ui.new("Frame", { Name = "Avatar", BackgroundColor3 = T.card2, BorderSizePixel = 0, Size = UDim2.fromOffset(size, size) }, parent)
	if props then
		for key, value in pairs(props) do
			holder[key] = value
		end
	end
	ui.corner(holder, math.floor(size / 2))
	ui.accent(holder, "BackgroundColor3")
	if entry.verified then
		local ring = ui.stroke(holder, badgeColor(), size >= 60 and 3 or 2, 0)
		ring.Name = "Ring"
	end
	local mono = ui.label(holder, {
		Name = "Monogram",
		Text = Mod.monogram(entry.name),
		Font = ctx.FONT_B,
		TextSize = math.max(8, math.floor(size * 0.42)),
		TextColor3 = T.ink,
		TextXAlignment = Enum.TextXAlignment.Center,
		Size = UDim2.fromScale(1, 1),
	})
	local image = ui.new("ImageLabel", { Name = "Photo", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ScaleType = Enum.ScaleType.Crop, Visible = false }, holder)
	ui.corner(image, math.floor(size / 2))
	local slot = { holder = holder, mono = mono, image = image, entry = entry, kind = kind, loading = false, picture = nil }
	local function roblox()
		if hasRobloxAccount(entry) then
			slot.loading = true
			state.queue[#state.queue + 1] = slot
			pulse(slot)
			pump()
		end
	end
	if entry.picture ~= "" then
		slot.loading = true
		pulse(slot)
		loadPicture(entry.picture, function(id)
			if id then
				slot.picture = id
				slot.loading = false
				showPhoto(slot, id)
				applyAvatar(slot)
			else
				slot.loading = false
				roblox()
			end
		end)
	else
		roblox()
	end
	return holder, slot
end

function Mod.openLink(url)
	local gui = ctx.GuiService
	if gui then
		local ok = pcall(function()
			gui:OpenBrowserWindow(url)
		end)
		if ok then
			return "opened"
		end
	end
	if ctx.X.setclipboard and pcall(ctx.X.setclipboard, url) then
		return "copied"
	end
	return "none"
end

local function pressedButton(button, idle, onTap)
	local busy = false
	button.Activated:Connect(function()
		if busy then
			return
		end
		busy = true
		local hold = onTap()
		spawnLater(hold or 1.5, function()
			busy = false
			if button.Parent then
				idle()
			end
		end)
	end)
end

local function copyButton(parent, url, label)
	local ui, T = ctx.UI, ctx.T
	local button = ui.button(parent, { Name = "Copy", BackgroundColor3 = T.card2, Size = UDim2.fromOffset(72, 36) })
	ui.corner(button, 18)
	local set = ctx.iconText(button, "copy", "Copy", T.text, 10)
	ui.pressable(button, 0.92)
	pressedButton(button, function()
		set("copy", "Copy", T.text)
	end, function()
		ctx.copyText(url, label)
		set("check", "Copied", T.green)
	end)
	return button
end

local function showAddress(holder, url)
	if holder:FindFirstChild("Address") then
		return
	end
	local ui, T = ctx.UI, ctx.T
	local box = ui.new("TextBox", {
		Name = "Address",
		BackgroundColor3 = T.card2,
		Size = UDim2.new(1, 0, 0, 30),
		Font = ctx.FONT_M,
		TextSize = 10,
		TextColor3 = T.text,
		Text = url,
		ClearTextOnFocus = false,
		TextEditable = false,
		TextXAlignment = Enum.TextXAlignment.Left,
		ClipsDescendants = true,
		LayoutOrder = 99,
	}, holder)
	ui.corner(box, 8)
	ui.pad(box, 8, 8, 0, 0)
end

local function openButton(parent, url, size, text, holder)
	local ui, T = ctx.UI, ctx.T
	local button = ui.button(parent, { Name = "Open", BackgroundColor3 = T.card2, Size = size })
	ui.corner(button, math.floor(size.Y.Offset / 2))
	local fontSize = size.Y.Offset >= 40 and 12 or 10
	local set = ctx.iconText(button, "link", text, T.text, fontSize)
	ui.pressable(button, 0.94)
	pressedButton(button, function()
		set("link", text, T.text)
	end, function()
		local result = Mod.openLink(url)
		if result == "opened" then
			set("check", "Done", T.green)
		elseif result == "copied" then
			set("check", "Copied", T.green)
			ctx.notify("Link copied", "Open it in your browser", "ok", 3)
		else
			set("x", "Can't open", T.yellow)
			showAddress(holder, url)
		end
	end)
	return button
end

local function glow(parent, name, rotation, from, to, radius, overhang)
	local ui = ctx.UI
	local frame = ui.new("Frame", { Name = name, BorderSizePixel = 0, Size = UDim2.new(1, 0, 1, overhang or 0), ZIndex = 0 }, parent)
	if radius then
		ui.corner(frame, radius)
	end
	ui.accent(frame, "BackgroundColor3")
	ui.new("UIGradient", {
		Rotation = rotation,
		Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, from), NumberSequenceKeypoint.new(1, to) }),
	}, frame)
	return frame
end

local function pill(parent, text, order, accent)
	local ui, T = ctx.UI, ctx.T
	local width = math.ceil(ctx.textWidth(text, 10, ctx.FONT_B)) + 18
	local chip = ui.new("Frame", { Name = "Pill", BackgroundColor3 = T.card2, BackgroundTransparency = 0.15, Size = UDim2.fromOffset(width, 22), LayoutOrder = order }, parent)
	ui.corner(chip, 11)
	if accent then
		ui.accent(chip, "BackgroundColor3")
		chip.BackgroundTransparency = 0.78
	end
	ui.label(chip, { Name = "Label", Text = text, Font = ctx.FONT_B, TextSize = 10, TextColor3 = T.text, TextXAlignment = Enum.TextXAlignment.Center, Size = UDim2.fromScale(1, 1) })
	return chip, width
end

local function fitPills(set, room)
	local used = 0
	for i, item in ipairs(set) do
		local add = item.width + (used > 0 and 6 or 0)
		local show = i == 1 or used + add <= room
		item.chip.Visible = show
		if show then
			used += add
		end
	end
	return used
end

local function horizontal(parent, name, height, gap, centered, order)
	local ui = ctx.UI
	local row = ui.new("Frame", { Name = name, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, height), LayoutOrder = order or 0 }, parent)
	local layout = ui.list(row, gap or 6, Enum.FillDirection.Horizontal, centered and Enum.HorizontalAlignment.Center or Enum.HorizontalAlignment.Left)
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	return row
end

local function wrapped(parent, name, text, size, color, order, centered)
	return ctx.UI.label(parent, {
		Name = name,
		Text = text,
		TextSize = size,
		TextColor3 = color,
		TextWrapped = true,
		TextXAlignment = centered and Enum.TextXAlignment.Center or Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = order,
	})
end

local function heading(parent, text, order)
	return ctx.UI.label(parent, {
		Name = "Heading",
		Text = string.upper(text),
		Font = ctx.FONT_B,
		TextSize = 10,
		TextColor3 = ctx.T.dim,
		Size = UDim2.new(1, 0, 0, 16),
		LayoutOrder = order,
	})
end

local function windowWidth(win)
	return math.max(120, win.w - Mod.PAD * 2 - 4)
end

local function relayoutBody(win)
	local inner = windowWidth(win)
	local cols = Mod.columns(inner)
	local cellW = Mod.cellWidth(inner, cols, Mod.GAP)
	for _, grid in ipairs(win.grids) do
		if grid.Parent then
			grid.CellSize = UDim2.fromOffset(cellW, Mod.CARD_H)
		end
	end
	for _, fit in ipairs(win.cardNames) do
		if fit.row.Parent then
			fit.set(nil, cellW - 76)
		end
	end
	if win.spotGrid and win.spotGrid.Parent then
		local fcols = Mod.featuredColumns(inner, win.spotCount)
		local fw = Mod.cellWidth(inner, fcols, Mod.GAP)
		win.spotGrid.CellSize = UDim2.fromOffset(fw, Mod.FEATURE_H)
		for _, fit in ipairs(win.spotNames) do
			if fit.row.Parent then
				fit.set(nil, fw - 96)
			end
		end
		for _, set in ipairs(win.spotPills) do
			fitPills(set, fw - 100)
		end
	end
	for _, fit in ipairs(win.detailNames) do
		if fit.row.Parent then
			fit.set(nil, win.w - 64)
		end
	end
	win.cols = cols
end

local closeWindow
local showDetail

local function cardEnter(win, inner, index)
	if not ctx.S.animations or index > 18 then
		return
	end
	inner.Position = UDim2.fromOffset(0, 14)
	inner.BackgroundTransparency = 1
	spawnLater(0.12 + 0.025 * index, function()
		if inner.Parent and not win.closing then
			ctx.UI.tween(inner, 0.35, { Position = UDim2.fromOffset(0, 0), BackgroundTransparency = 0 })
		end
	end)
end

local function hoverable(button, normal, over)
	ctx.UI.onHover(button, function(on)
		if button.Parent then
			ctx.UI.tween(button, 0.15, { BackgroundColor3 = on and over or normal })
		end
	end)
end

local function makeCard(win, parent, entry, order, index)
	local ui, T = ctx.UI, ctx.T
	local cell = ui.new("Frame", { Name = "Cell", BackgroundTransparency = 1, LayoutOrder = order }, parent)
	local card = ui.button(cell, { Name = "Card", BackgroundColor3 = T.card, Size = UDim2.fromScale(1, 1) })
	ui.corner(card, 16)
	local stroke = ui.stroke(card, entry.verified and badgeColor() or T.stroke, 1, entry.verified and 0.55 or 0.75)
	stroke.Name = "Edge"
	local _, slot = makeAvatar(card, entry, 42, "head", { Position = UDim2.fromOffset(12, 12) })
	local cellW = Mod.cellWidth(windowWidth(win), Mod.columns(windowWidth(win)), Mod.GAP)
	local fit = nameRow(card, entry.name, 13, ctx.FONT_B, T.text, entry.verified and 14 or nil, cellW - 76, false, { Position = UDim2.fromOffset(64, 12) })
	win.cardNames[#win.cardNames + 1] = fit
	ui.label(card, {
		Name = "Role",
		Text = Mod.rowRole(entry),
		TextSize = 11,
		TextColor3 = T.sub,
		Position = UDim2.fromOffset(64, 33),
		Size = UDim2.new(1, -76, 0, 14),
		TextTruncate = Enum.TextTruncate.AtEnd,
	})
	ui.label(card, {
		Name = "Blurb",
		Text = Mod.blurb(entry),
		TextSize = 11,
		TextColor3 = T.sub,
		TextWrapped = true,
		TextYAlignment = Enum.TextYAlignment.Top,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Position = UDim2.fromOffset(12, 64),
		Size = UDim2.new(1, -24, 0, 44),
	})
	if entry.profileStyle == "roblox" then
		slot.onIdentity = function(identity)
			fit.set(Mod.displayName(entry, identity))
		end
	end
	ui.pressable(card, 0.97)
	hoverable(card, T.card, T.card2)
	card.Activated:Connect(function()
		showDetail(entry)
	end)
	applyAvatar(slot)
	cardEnter(win, card, index)
	return card
end

local function makeFeatured(win, parent, entry, order, index, width)
	local ui, T = ctx.UI, ctx.T
	local cell = ui.new("Frame", { Name = "FeatureCell", BackgroundTransparency = 1, LayoutOrder = order }, parent)
	local card = ui.button(cell, { Name = "Featured", BackgroundColor3 = T.card, Size = UDim2.fromScale(1, 1), ClipsDescendants = true })
	ui.corner(card, 18)
	local edge = ui.stroke(card, badgeColor(), 1.5, 0.45)
	edge.Name = "Edge"
	glow(card, "Shine", 120, 0.72, 1, 18)
	local _, slot = makeAvatar(card, entry, 60, "bust", { Position = UDim2.fromOffset(16, 16) })
	local fit = nameRow(card, entry.name, 16, ctx.FONT_B, T.text, entry.verified and 17 or nil, width - 96, false, { Position = UDim2.fromOffset(88, 18) })
	win.spotNames[#win.spotNames + 1] = fit
	local handle = ui.new("Frame", { Name = "HandleRow", BackgroundTransparency = 1, Position = UDim2.fromOffset(88, 42), Size = UDim2.new(1, -100, 0, 16) }, card)
	local handleLabel = ui.label(handle, { Name = "Handle", Text = "", TextSize = 11, TextColor3 = T.sub, Size = UDim2.fromOffset(10, 16), TextTruncate = Enum.TextTruncate.AtEnd })
	local function setHandle(identity)
		local text = Mod.handleText(entry, identity)
		handle.Visible = text ~= nil
		if not text then
			return
		end
		handleLabel.Text = text
		local w = math.min(math.ceil(ctx.textWidth(text, 11, ctx.FONT_M)) + 2, math.max(20, width - 120))
		handleLabel.Size = UDim2.fromOffset(w, 16)
	end
	setHandle(identityOf(entry))
	local chips = horizontal(card, "Roles", 22, 6, false)
	chips.Position = UDim2.fromOffset(88, 60)
	chips.Size = UDim2.new(1, -100, 0, 22)
	chips.ClipsDescendants = true
	local pills = {}
	for i, role in ipairs(entry.roles) do
		if i <= 3 then
			local chip, pw = pill(chips, role, i, i == 1)
			pills[#pills + 1] = { chip = chip, width = pw }
		end
	end
	fitPills(pills, width - 100)
	win.spotPills[#win.spotPills + 1] = pills
	ui.label(card, {
		Name = "Blurb",
		Text = Mod.blurb(entry),
		TextSize = 12,
		TextColor3 = T.text,
		TextWrapped = true,
		TextYAlignment = Enum.TextYAlignment.Top,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Position = UDim2.fromOffset(16, 94),
		Size = UDim2.new(1, -32, 1, -108),
	})
	slot.onIdentity = function(identity)
		if entry.profileStyle == "roblox" then
			fit.set(Mod.displayName(entry, identity))
		end
		setHandle(identity)
	end
	ui.pressable(card, 0.97)
	hoverable(card, T.card, T.card2)
	card.Activated:Connect(function()
		showDetail(entry)
	end)
	applyAvatar(slot)
	cardEnter(win, card, index)
	return card
end

local function groupHeader(parent, title, count, order)
	local ui, T = ctx.UI, ctx.T
	local row = ui.new("Frame", { Name = "GroupHeader", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 26), LayoutOrder = order }, parent)
	local tw = math.ceil(ctx.textWidth(title, 14, ctx.FONT_B)) + 2
	ui.label(row, { Name = "GroupTitle", Text = title, Font = ctx.FONT_B, TextSize = 14, Size = UDim2.fromOffset(tw, 26) })
	local countText = tostring(count)
	local cw = math.ceil(ctx.textWidth(countText, 10, ctx.FONT_B)) + 14
	local badge = ui.new("Frame", { Name = "Count", BackgroundColor3 = T.card2, Position = UDim2.new(0, tw + 8, 0.5, -9), Size = UDim2.fromOffset(cw, 18) }, row)
	ui.corner(badge, 9)
	ui.label(badge, { Text = countText, Font = ctx.FONT_B, TextSize = 10, TextColor3 = T.sub, TextXAlignment = Enum.TextXAlignment.Center, Size = UDim2.fromScale(1, 1) })
	ui.new("Frame", { Name = "Line", BackgroundColor3 = T.line, BorderSizePixel = 0, AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, tw + cw + 18, 0.5, 0), Size = UDim2.new(1, -(tw + cw + 18), 0, 1) }, row)
	return row
end

local function clearBody(win)
	for _, child in ipairs(win.list:GetChildren()) do
		if child:IsA("GuiObject") and child.Name ~= "Footer" then
			child:Destroy()
		end
	end
	win.grids, win.cardNames, win.spotNames, win.spotGrid, win.spotPills = {}, {}, {}, nil, {}
end

local function rebuildBody(win)
	local ui, T = ctx.UI, ctx.T
	clearBody(win)
	local clean = state.clean
	local inner = windowWidth(win)
	local order = 0
	local index = 0
	local query = state.query
	local filter = state.filter
	if query == "" and filter == "All" then
		local featured = Mod.featured(clean)
		if #featured > 0 then
			order += 1
			groupHeader(win.list, "Spotlight", #featured, order)
			order += 1
			local spot = ui.new("Frame", { Name = "Spotlight", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = order }, win.list)
			local fcols = Mod.featuredColumns(inner, #featured)
			local fw = Mod.cellWidth(inner, fcols, Mod.GAP)
			win.spotGrid = ui.new("UIGridLayout", {
				CellSize = UDim2.fromOffset(fw, Mod.FEATURE_H),
				CellPadding = UDim2.fromOffset(Mod.GAP, Mod.GAP),
				SortOrder = Enum.SortOrder.LayoutOrder,
			}, spot)
			win.spotCount = #featured
			for i, entry in ipairs(featured) do
				index += 1
				makeFeatured(win, spot, entry, i, index, fw)
			end
		end
	end
	local groups = Mod.groups(clean, query, filter)
	if #groups == 0 then
		order += 1
		local empty = ui.new("Frame", { Name = "Empty", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 120), LayoutOrder = order }, win.list)
		ui.icon("search", 26, T.dim, empty, { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 20) })
		ui.label(empty, { Name = "EmptyTitle", Text = "Nobody matches that.", Font = ctx.FONT_B, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Center, Position = UDim2.fromOffset(0, 56), Size = UDim2.new(1, 0, 0, 18) })
		ui.label(empty, { Text = "Try a name, a role or a script.", TextSize = 11, TextColor3 = T.sub, TextXAlignment = Enum.TextXAlignment.Center, Position = UDim2.fromOffset(0, 76), Size = UDim2.new(1, 0, 0, 16) })
	end
	local cols = Mod.columns(inner)
	local cellW = Mod.cellWidth(inner, cols, Mod.GAP)
	for _, group in ipairs(groups) do
		order += 1
		groupHeader(win.list, group.title, #group.items, order)
		order += 1
		local holder = ui.new("Frame", { Name = "Group", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = order }, win.list)
		local grid = ui.new("UIGridLayout", {
			CellSize = UDim2.fromOffset(cellW, Mod.CARD_H),
			CellPadding = UDim2.fromOffset(Mod.GAP, Mod.GAP),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}, holder)
		win.grids[#win.grids + 1] = grid
		for i, entry in ipairs(group.items) do
			index += 1
			makeCard(win, holder, entry, i, index)
		end
	end
	win.cols = cols
	win.shown = index
	win.body.CanvasPosition = Vector2.new(0, 0)
end

local function paintChips(win)
	local ui, T = ctx.UI, ctx.T
	for _, chip in ipairs(win.chips) do
		local on = chip.title == state.filter
		ui.tween(chip.button, 0.2, { BackgroundColor3 = on and ctx.accentColor() or T.card, BackgroundTransparency = 0 })
		ui.tween(chip.label, 0.2, { TextColor3 = on and T.ink or T.sub })
		chip.button:SetAttribute("Selected", on)
	end
end

local function buildChips(win)
	local ui, T = ctx.UI, ctx.T
	win.chips = {}
	for i, f in ipairs(Mod.filters(state.clean)) do
		local text = f.title .. "  " .. f.count
		local width = math.ceil(ctx.textWidth(text, 11, ctx.FONT_B)) + 26
		local button = ui.button(win.chipRow, { Name = "Chip", BackgroundColor3 = T.card, Size = UDim2.fromOffset(width, 32), LayoutOrder = i })
		ui.corner(button, 16)
		local label = ui.label(button, { Name = "Label", Text = text, Font = ctx.FONT_B, TextSize = 11, TextColor3 = T.sub, TextXAlignment = Enum.TextXAlignment.Center, Size = UDim2.fromScale(1, 1) })
		ui.pressable(button, 0.94)
		local chip = { title = f.title, button = button, label = label }
		win.chips[#win.chips + 1] = chip
		button.Activated:Connect(function()
			if win.closing or state.filter == f.title then
				return
			end
			state.filter = f.title
			paintChips(win)
			rebuildBody(win)
		end)
	end
	paintChips(win)
end

local function closeDetail(instant)
	local win = state and state.win
	local detail = win and win.detail
	if not detail or detail.closing then
		return
	end
	detail.closing = true
	local function finish()
		if detail.frame.Parent then
			detail.frame:Destroy()
		end
		if win.detail == detail then
			win.detail = nil
			win.detailNames = {}
		end
	end
	if instant or not ctx.S.animations then
		finish()
		return
	end
	local tw = ctx.UI.tween(detail.frame, 0.28, { Position = UDim2.new(1, 0, 0, 0) }, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
	ctx.UI.done(tw, finish)
	spawnLater(0.6, finish)
end

local function linkRows(scroll, entry, order)
	local ui, T = ctx.UI, ctx.T
	local list = {}
	for _, key in ipairs(Mod.LINK_KEYS) do
		if entry.links[key] ~= "" and not (key == "roblox" and entry.profileStyle == "roblox") then
			list[#list + 1] = { key, entry.links[key] }
		end
	end
	for _, url in ipairs(entry.links.other) do
		list[#list + 1] = { "other", url }
	end
	if #list == 0 then
		return order
	end
	order += 1
	heading(scroll, "Links", order)
	for _, item in ipairs(list) do
		local key, url = item[1], item[2]
		order += 1
		local block = ui.new("Frame", { Name = "Link", BackgroundColor3 = T.card, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = order }, scroll)
		ui.corner(block, 14)
		ui.pad(block, 12, 8, 6, 6)
		ui.list(block, 6)
		local row = ui.new("Frame", { Name = "Row", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 40), LayoutOrder = 1 }, block)
		ui.icon(Mod.LINK_ICONS[key], 15, T.sub, row, { Position = UDim2.fromOffset(0, 12) })
		ui.label(row, { Name = "LinkName", Text = Mod.LINK_NAMES[key], Font = ctx.FONT_B, TextSize = 12, Position = UDim2.fromOffset(24, 0), Size = UDim2.new(1, -184, 1, 0), TextTruncate = Enum.TextTruncate.AtEnd })
		local copy = copyButton(row, url, Mod.LINK_NAMES[key] .. " link")
		copy.AnchorPoint = Vector2.new(1, 0.5)
		copy.Position = UDim2.new(1, -78, 0.5, 0)
		local open = openButton(row, url, UDim2.fromOffset(72, 36), "Open", block)
		open.AnchorPoint = Vector2.new(1, 0.5)
		open.Position = UDim2.new(1, 0, 0.5, 0)
	end
	return order
end

function showDetail(entry)
	local win = state and state.win
	if not win or win.closing or win.detail then
		return nil
	end
	local ui, T = ctx.UI, ctx.T
	local detail = { entry = entry, closing = false }
	win.detail = detail
	win.detailNames = {}
	local frame = ui.new("Frame", { Name = "Detail", BackgroundColor3 = T.panel, BorderSizePixel = 0, Size = UDim2.fromScale(1, 1), Active = true, ZIndex = 5 }, win.frame)
	ui.corner(frame, Mod.RADIUS)
	detail.frame = frame
	local top = ui.new("Frame", { Name = "TopBar", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 56), ZIndex = 6 }, frame)
	local back = ui.button(top, { Name = "Back", BackgroundColor3 = T.card, Position = UDim2.fromOffset(12, 8), Size = UDim2.fromOffset(112, 40) })
	ui.corner(back, 20)
	ctx.iconText(back, "chevron-left", "All credits", T.text, 11)
	ui.pressable(back, 0.94)
	back.Activated:Connect(function()
		closeDetail(false)
	end)
	local close = ui.button(top, { Name = "Close", BackgroundColor3 = T.card, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 0, 8), Size = UDim2.fromOffset(40, 40) })
	ui.corner(close, 20)
	ui.icon("x", 14, T.sub, close, { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5) })
	ui.pressable(close, 0.9)
	close.Activated:Connect(function()
		closeWindow(false)
	end)
	local scroll = ui.new("ScrollingFrame", {
		Name = "DetailScroll",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Position = UDim2.fromOffset(0, 56),
		Size = UDim2.new(1, 0, 1, -56),
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 3,
		ScrollBarImageColor3 = T.dim,
		ScrollingDirection = Enum.ScrollingDirection.Y,
	}, frame)
	ui.pad(scroll, Mod.PAD, Mod.PAD, 4, 24)
	ui.list(scroll, 10, nil, Enum.HorizontalAlignment.Center)
	detail.scroll = scroll
	local banner = ui.new("Frame", { Name = "Banner", BackgroundColor3 = T.card, Size = UDim2.new(1, 0, 0, 150), LayoutOrder = 1, ClipsDescendants = false }, scroll)
	ui.corner(banner, 20)
	local band = ui.new("Frame", { Name = "Band", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 84), ClipsDescendants = true }, banner)
	ui.corner(band, 20)
	glow(band, "Glow", 25, 0.35, 0.85, 20, 40)
	local avatarSize = 96
	local kind = entry.profileStyle == "roblox" and "big" or "bust"
	local _, slot = makeAvatar(banner, entry, avatarSize, kind, { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 36) })
	if not entry.verified then
		local ring = ui.stroke(slot.holder, T.panel, 4, 0)
		ring.Name = "Gap"
	end
	local fit = nameRow(scroll, entry.name, 22, ctx.FONT_B, T.text, entry.verified and 20 or nil, win.w - 64, true, { Name = "NameRow", LayoutOrder = 2 })
	fit.label.Name = entry.profileStyle == "roblox" and "Nickname" or "Name"
	win.detailNames[#win.detailNames + 1] = fit
	local handleRow = ui.new("Frame", { Name = "HandleRow", BackgroundTransparency = 1, Size = UDim2.fromOffset(10, 18), LayoutOrder = 3, Visible = false }, scroll)
	local handleLabel = ui.label(handleRow, { Name = "Username", Text = "", TextSize = 12, TextColor3 = T.sub, Size = UDim2.fromOffset(10, 18) })
	local function setHandle(identity)
		local text = Mod.handleText(entry, identity)
		handleRow.Visible = text ~= nil
		handleLabel.Visible = text ~= nil
		if not text then
			return
		end
		handleLabel.Text = text
		local w = math.min(math.ceil(ctx.textWidth(text, 12, ctx.FONT_M)) + 2, win.w - 80)
		handleLabel.Size = UDim2.fromOffset(w, 18)
		handleRow.Size = UDim2.fromOffset(w, 18)
	end
	setHandle(identityOf(entry))
	slot.onIdentity = function(identity)
		if entry.profileStyle == "roblox" then
			fit.set(Mod.displayName(entry, identity))
		end
		setHandle(identity)
	end
	applyAvatar(slot)
	local chips = horizontal(scroll, "Roles", 24, 6, true, 4)
	local _, room = pill(chips, string.upper(Mod.kindName(entry)), 0, false)
	for i, role in ipairs(entry.roles) do
		local width = math.ceil(ctx.textWidth(role, 10, ctx.FONT_B)) + 18
		if i <= 3 and room + 6 + width <= win.w - 40 then
			pill(chips, role, i, i == 1)
			room += 6 + width
		end
	end
	local order = 4
	if entry.description ~= "" then
		order += 1
		heading(scroll, "Description", order)
		order += 1
		local quote = ui.new("Frame", { Name = "Description", BackgroundColor3 = T.card, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = order }, scroll)
		ui.corner(quote, 16)
		ui.pad(quote, 18, 16, 14, 14)
		local bar = ui.new("Frame", { Name = "Bar", BorderSizePixel = 0, Position = UDim2.new(0, -10, 0, 0), Size = UDim2.new(0, 3, 1, 0) }, quote)
		ui.corner(bar, 2)
		ui.accent(bar, "BackgroundColor3")
		wrapped(quote, "Text", entry.description, 13, T.text, 1)
	end
	if #entry.usedIn > 0 then
		order += 1
		heading(scroll, "Used in", order)
		order += 1
		wrapped(scroll, "UsedIn", table.concat(entry.usedIn, "  ·  "), 12, T.sub, order)
	end
	order = linkRows(scroll, entry, order)
	if entry.license ~= "" then
		order += 1
		heading(scroll, "Licence", order)
		order += 1
		wrapped(scroll, "Licence", entry.license, 11, T.sub, order)
	end
	local url = entry.profileStyle == "roblox" and Mod.profileUrl(entry) or nil
	if url then
		order += 1
		local holder = ui.new("Frame", { Name = "Profile", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = order }, scroll)
		ui.list(holder, 6)
		local button = openButton(holder, url, UDim2.new(1, 0, 0, 46), "Open Roblox profile", holder)
		button.LayoutOrder = 1
		ui.accent(button, "BackgroundColor3")
	end
	if ctx.S.animations then
		frame.Position = UDim2.new(1, 0, 0, 0)
		ui.tween(frame, 0.32, { Position = UDim2.new(0, 0, 0, 0) }, Enum.EasingStyle.Quint)
	end
	return detail
end

function Mod.chrome(mode, w, h)
	w, h = finite(w, 0), finite(h, 0)
	if h >= Mod.COMPACT_H then
		return { hero = (mode == "sheet" or h < 560) and 96 or 112, bar = 98, compact = false, oneRow = false }
	end
	local oneRow = w >= Mod.ONE_ROW_W
	return { hero = 60, bar = oneRow and 52 or 86, compact = true, oneRow = oneRow }
end

function Mod.heroHeight(mode, h)
	return Mod.chrome(mode, Mod.WINDOW_MAX_W, h).hero
end

function Mod.searchWidth(w)
	return math.floor(math.max(200, math.min(300, finite(w, 0) * 0.34)))
end

local function placeToolbar(win, look)
	local search, chips = win.search, win.chipRow
	if not (search and chips) then
		return
	end
	win.toolbar.Size = UDim2.new(1, 0, 0, look.bar)
	if win.box then
		win.box.PlaceholderText = look.oneRow and "Search" or "Search names, roles or scripts"
	end
	if not look.compact then
		search.Position = UDim2.fromOffset(Mod.PAD, 12)
		search.Size = UDim2.new(1, -Mod.PAD * 2, 0, 42)
		chips.Position = UDim2.fromOffset(0, 62)
		chips.Size = UDim2.new(1, 0, 0, 34)
		win.chipPad.PaddingLeft = UDim.new(0, Mod.PAD)
		return
	end
	if look.oneRow then
		local sw = Mod.searchWidth(win.w)
		search.Position = UDim2.fromOffset(Mod.PAD, 8)
		search.Size = UDim2.fromOffset(sw, 36)
		chips.Position = UDim2.fromOffset(Mod.PAD + sw + 8, 9)
		chips.Size = UDim2.new(1, -(Mod.PAD + sw + 8), 0, 34)
		win.chipPad.PaddingLeft = UDim.new(0, 0)
		return
	end
	search.Position = UDim2.fromOffset(Mod.PAD, 8)
	search.Size = UDim2.new(1, -Mod.PAD * 2, 0, 36)
	chips.Position = UDim2.fromOffset(0, 50)
	chips.Size = UDim2.new(1, 0, 0, 34)
	win.chipPad.PaddingLeft = UDim.new(0, Mod.PAD)
end

local function placeChrome(win)
	local look = Mod.chrome(win.mode, win.w, win.h)
	local heroH = look.hero
	win.look = look
	win.heroH = heroH
	win.barH = look.bar
	win.hero.Size = UDim2.new(1, 0, 0, heroH)
	if look.compact then
		local left = Mod.PAD + 48
		win.heroIcon.Size = UDim2.fromOffset(36, 36)
		win.heroIcon.Position = UDim2.fromOffset(Mod.PAD, 12)
		win.heroTitle.Position = UDim2.fromOffset(left, 11)
		win.heroTitle.Size = UDim2.new(1, -(left + 60), 0, 22)
		win.heroTitle.TextSize = 20
		win.heroSub.Visible = false
		win.heroStats.Position = UDim2.fromOffset(left, 34)
		win.heroStats.Size = UDim2.new(1, -(left + 60), 0, 14)
		win.heroClose.Size = UDim2.fromOffset(40, 40)
		win.heroClose.Position = UDim2.new(1, -12, 0, 10)
		win.grip.Position = UDim2.new(0.5, 0, 0, 5)
	else
		local mid = math.floor(heroH / 2)
		local left = Mod.PAD + 62
		win.heroIcon.Size = UDim2.fromOffset(44, 44)
		win.heroIcon.Position = UDim2.fromOffset(Mod.PAD, mid - 22)
		win.heroTitle.Position = UDim2.fromOffset(left, mid - 30)
		win.heroTitle.Size = UDim2.new(1, -(left + 60), 0, 30)
		win.heroTitle.TextSize = win.mode == "sheet" and 22 or 26
		win.heroSub.Visible = true
		win.heroSub.Position = UDim2.fromOffset(left, mid)
		win.heroStats.Position = UDim2.fromOffset(left, mid + 19)
		win.heroStats.Size = UDim2.new(1, -(left + 20), 0, 14)
		win.heroClose.Size = UDim2.fromOffset(44, 44)
		win.heroClose.Position = UDim2.new(1, -12, 0, 12)
		win.grip.Position = UDim2.new(0.5, 0, 0, 8)
	end
	if win.toolbar then
		win.toolbar.Position = UDim2.fromOffset(0, heroH)
		placeToolbar(win, look)
	end
	if win.body then
		win.body.Position = UDim2.fromOffset(0, heroH + look.bar)
		win.body.Size = UDim2.new(1, 0, 1, -(heroH + look.bar))
	end
end

local function topInset()
	local ok, top = pcall(function()
		return ctx.GuiService:GetGuiInset().Y
	end)
	if ok and type(top) == "number" and top > 0 then
		return top / math.max(0.01, ctx.L.scale or 1)
	end
	return 0
end

local function applyRect(win)
	local x, y, w, h, mode = Mod.windowRect(ctx.L.W, ctx.L.H, topInset())
	win.x, win.y, win.w, win.h, win.mode = x, y, w, h, mode
	win.frame.Size = UDim2.fromOffset(w, h)
	if not win.dragging then
		win.frame.Position = UDim2.fromOffset(x, y)
	end
	win.grip.Visible = mode == "sheet"
	placeChrome(win)
	return x, y, w, h, mode
end

local function relayout()
	local win = state and state.win
	if not win or win.closing then
		return
	end
	applyRect(win)
	relayoutBody(win)
end

local function dropWindow(win)
	win.closing = true
	for _, conn in ipairs(win.conns) do
		pcall(function()
			conn:Disconnect()
		end)
	end
	win.conns = {}
	if win.dim.Parent then
		win.dim:Destroy()
	end
	if state and state.win == win then
		state.win = nil
	end
end

function closeWindow(instant)
	local win = state and state.win
	if not win or win.closing then
		return
	end
	if instant or not ctx.S.animations then
		dropWindow(win)
		return
	end
	win.closing = true
	for _, conn in ipairs(win.conns) do
		pcall(function()
			conn:Disconnect()
		end)
	end
	win.conns = {}
	local ui = ctx.UI
	local function finish()
		dropWindow(win)
	end
	ui.tween(win.dim, 0.28, { BackgroundTransparency = 1 })
	local tw
	if win.mode == "sheet" then
		tw = ui.tween(win.frame, 0.3, { Position = UDim2.fromOffset(win.x, ctx.L.H + 20) }, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
	else
		ui.tween(win.scale, 0.25, { Scale = 0.94 }, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
		tw = ui.tween(win.frame, 0.25, { Position = UDim2.fromOffset(win.x, win.y + 24) }, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
	end
	ui.done(tw, finish)
	spawnLater(0.7, finish)
end

local function buildHero(win)
	local ui, T = ctx.UI, ctx.T
	local hero = ui.new("Frame", { Name = "Hero", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 112), ClipsDescendants = true }, win.frame)
	win.hero = hero
	glow(hero, "Glow", 20, 0.55, 1, Mod.RADIUS, Mod.RADIUS * 2)
	local orb = ui.new("Frame", { Name = "Orb", BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(1, -150, 0, 6), Size = UDim2.fromOffset(220, 220), BackgroundTransparency = 0.86 }, hero)
	ui.corner(orb, 110)
	ui.accent(orb, "BackgroundColor3")
	local icon = ui.new("Frame", { Name = "Mark", BackgroundColor3 = T.card, Position = UDim2.fromOffset(Mod.PAD, 30), Size = UDim2.fromOffset(44, 44) }, hero)
	win.heroIcon = icon
	ui.corner(icon, 16)
	ui.accent(icon, "BackgroundColor3")
	icon.BackgroundTransparency = 0.7
	local glyph = ui.icon("heart-handshake", 22, T.text, icon, { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5) })
	ui.accent(glyph, "ImageColor3")
	win.heroTitle = ui.label(hero, { Name = "Title", Text = "Credits", Font = ctx.FONT_B, TextSize = 26, Position = UDim2.fromOffset(Mod.PAD + 62, 26), Size = UDim2.new(1, -(Mod.PAD + 62 + 60), 0, 30) })
	win.heroSub = ui.label(hero, { Name = "Subtitle", Text = "The people and projects behind Atsuko Hub", TextSize = 12, TextColor3 = T.sub, Position = UDim2.fromOffset(Mod.PAD + 62, 56), Size = UDim2.new(1, -(Mod.PAD + 62 + 60), 0, 16), TextTruncate = Enum.TextTruncate.AtEnd })
	win.heroStats = ui.label(hero, { Name = "Stats", Text = Mod.stats(state.clean), Font = ctx.FONT_B, TextSize = 10, TextColor3 = T.dim, Position = UDim2.fromOffset(Mod.PAD + 62, 76), Size = UDim2.new(1, -(Mod.PAD + 62 + 20), 0, 14), TextTruncate = Enum.TextTruncate.AtEnd })
	local close = ui.button(hero, { Name = "Close", BackgroundColor3 = T.card, BackgroundTransparency = 0.2, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 0, 12), Size = UDim2.fromOffset(44, 44) })
	win.heroClose = close
	local round = ui.corner(close, 22)
	round.CornerRadius = UDim.new(0.5, 0)
	ui.icon("x", 15, T.text, close, { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5) })
	ui.pressable(close, 0.9)
	close.Activated:Connect(function()
		closeWindow(false)
	end)
	win.grip = ui.new("Frame", { Name = "Grip", BackgroundColor3 = T.dim, BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 8), Size = UDim2.fromOffset(40, 4) }, hero)
	ui.corner(win.grip, 2)
	ui.new("Frame", { Name = "Line", BackgroundColor3 = T.line, BorderSizePixel = 0, AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.new(1, 0, 0, 1) }, hero)
end

local function buildToolbar(win)
	local ui, T = ctx.UI, ctx.T
	local bar = ui.new("Frame", { Name = "Toolbar", BackgroundTransparency = 1, Position = UDim2.fromOffset(0, win.heroH or 112), Size = UDim2.new(1, 0, 0, win.barH or 98) }, win.frame)
	win.toolbar = bar
	local search = ui.new("Frame", { Name = "Search", BackgroundColor3 = T.card, Position = UDim2.fromOffset(Mod.PAD, 12), Size = UDim2.new(1, -Mod.PAD * 2, 0, 42) }, bar)
	win.search = search
	ui.corner(search, 14)
	local edge = ui.stroke(search, T.stroke, 1, 1)
	ui.icon("search", 15, T.dim, search, { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 14, 0.5, 0) })
	win.box = ui.new("TextBox", {
		Name = "Box",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(40, 0),
		Size = UDim2.new(1, -86, 1, 0),
		Font = ctx.FONT_M,
		TextSize = 13,
		TextColor3 = T.text,
		PlaceholderText = "Search names, roles or scripts",
		PlaceholderColor3 = T.dim,
		Text = state.query,
		ClearTextOnFocus = false,
		TextXAlignment = Enum.TextXAlignment.Left,
		ClipsDescendants = true,
	}, search)
	local clear = ui.button(search, { Name = "Clear", BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -4, 0.5, 0), Size = UDim2.fromOffset(40, 40), Visible = state.query ~= "" })
	ui.icon("x", 13, T.sub, clear, { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5) })
	clear.Activated:Connect(function()
		win.box.Text = ""
	end)
	win.box.Focused:Connect(function()
		ui.tween(edge, 0.2, { Transparency = 0.2 })
	end)
	win.box.FocusLost:Connect(function()
		ui.tween(edge, 0.2, { Transparency = 1 })
	end)
	win.box:GetPropertyChangedSignal("Text"):Connect(function()
		clear.Visible = win.box.Text ~= ""
		state.token += 1
		local mine = state.token
		spawnLater(0.15, function()
			if mine == state.token and state.win == win and not win.closing then
				state.query = trim(win.box.Text)
				rebuildBody(win)
			end
		end)
	end)
	win.chipRow = ui.new("ScrollingFrame", {
		Name = "Chips",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Position = UDim2.fromOffset(0, 62),
		Size = UDim2.new(1, 0, 0, 34),
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.X,
		ScrollBarThickness = 0,
		ScrollingDirection = Enum.ScrollingDirection.X,
	}, bar)
	win.chipPad = ui.pad(win.chipRow, Mod.PAD, Mod.PAD, 1, 1)
	ui.list(win.chipRow, 8, Enum.FillDirection.Horizontal)
	buildChips(win)
	if win.look then
		placeToolbar(win, win.look)
	end
end

local function buildBody(win)
	local ui, T = ctx.UI, ctx.T
	win.body = ui.new("ScrollingFrame", {
		Name = "Body",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Position = UDim2.fromOffset(0, (win.heroH or 112) + (win.barH or 98)),
		Size = UDim2.new(1, 0, 1, -((win.heroH or 112) + (win.barH or 98))),
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 3,
		ScrollBarImageColor3 = T.dim,
		ScrollingDirection = Enum.ScrollingDirection.Y,
	}, win.frame)
	ui.pad(win.body, Mod.PAD, Mod.PAD, 4, 24)
	win.list = ui.new("Frame", { Name = "List", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y }, win.body)
	ui.list(win.list, 12)
	local footer = ui.new("Frame", { Name = "Footer", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = 100000 }, win.list)
	ui.list(footer, 8)
	local copyAll = ui.button(footer, { Name = "CopyAll", BackgroundColor3 = T.card, Size = UDim2.new(1, 0, 0, 46), LayoutOrder = 1 })
	ui.corner(copyAll, 23)
	ctx.iconText(copyAll, "copy", "Copy all the credits", T.text, 12)
	ui.pressable(copyAll, 0.96)
	copyAll.Activated:Connect(function()
		ctx.copyText(Mod.plainText(state.clean), "Credits")
	end)
	win.copyAll = copyAll
	ui.label(footer, { Name = "Thanks", Text = "Thank you, all of you. The hub would not exist without you.", TextSize = 11, TextColor3 = T.dim, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Center, Size = UDim2.new(1, 0, 0, 30), LayoutOrder = 2 })
end

local function dragSheet(win, input)
	if win.mode ~= "sheet" or win.closing or win.detail or not tapKind(input) then
		return
	end
	local L = ctx.L
	local _, top = rectOf(win.frame)
	if top and input.Position.Y - top > 72 * math.max(0.01, L.scale) then
		return
	end
	win.dragging = true
	ctx.Drag.start(input, function(_, delta)
		local pull = math.max(0, delta.Y / math.max(0.01, L.scale))
		win.pull = pull
		win.frame.Position = UDim2.fromOffset(win.x, win.y + pull)
		win.dim.BackgroundTransparency = 0.4 + math.min(0.5, pull / 400)
	end, function()
		win.dragging = false
		local pulled = win.pull or 0
		win.pull = 0
		if pulled >= Mod.SWIPE_CLOSE then
			closeWindow(false)
		else
			ctx.UI.tween(win.frame, 0.25, { Position = UDim2.fromOffset(win.x, win.y) })
			ctx.UI.tween(win.dim, 0.25, { BackgroundTransparency = 0.4 })
		end
	end)
end

local function openWindow(focusId)
	if not alive() then
		return nil
	end
	if state.win then
		if focusId and not state.win.closing then
			for _, entry in ipairs(state.clean.people) do
				if entry.id == focusId then
					showDetail(entry)
				end
			end
		end
		return state.win
	end
	local ui, T = ctx.UI, ctx.T
	local win = { closing = false, conns = {}, grids = {}, cardNames = {}, spotNames = {}, spotPills = {}, detailNames = {}, chips = {} }
	state.win = win
	state.filter = "All"
	state.query = ""
	win.dim = ui.new("TextButton", {
		Name = "CreditsDim",
		AutoButtonColor = false,
		Text = "",
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 9000,
		Active = true,
	}, ctx.Root)
	win.frame = ui.new("Frame", { Name = "CreditsWindow", BackgroundColor3 = T.panel, BorderSizePixel = 0, ClipsDescendants = true, ZIndex = 9001, Active = true }, win.dim)
	ui.corner(win.frame, Mod.RADIUS)
	ui.stroke(win.frame, T.stroke, 1, 0.25)
	win.scale = ui.new("UIScale", { Scale = 1 }, win.frame)
	buildHero(win)
	applyRect(win)
	buildToolbar(win)
	buildBody(win)
	rebuildBody(win)
	win.dim.Activated:Connect(function()
		closeWindow(false)
	end)
	win.conns[#win.conns + 1] = ctx.UserInputService.InputBegan:Connect(function(input)
		if input.KeyCode == Enum.KeyCode.Escape or input.KeyCode == Enum.KeyCode.ButtonB then
			if win.detail and not win.detail.closing then
				closeDetail(false)
			else
				closeWindow(false)
			end
		end
	end)
	win.conns[#win.conns + 1] = ctx.Root:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		if win.relayoutQueued then
			return
		end
		win.relayoutQueued = true
		task.defer(function()
			win.relayoutQueued = false
			if alive() and state.win == win then
				relayout()
			end
		end)
	end)
	win.frame.InputBegan:Connect(function(input)
		dragSheet(win, input)
	end)
	if ctx.S.animations then
		ui.tween(win.dim, 0.25, { BackgroundTransparency = 0.4 })
		if win.mode == "sheet" then
			win.frame.Position = UDim2.fromOffset(win.x, ctx.L.H + 20)
			ui.tween(win.frame, 0.42, { Position = UDim2.fromOffset(win.x, win.y) }, Enum.EasingStyle.Quint)
		else
			win.scale.Scale = 0.92
			win.frame.Position = UDim2.fromOffset(win.x, win.y + 18)
			ui.tween(win.scale, 0.38, { Scale = 1 }, Enum.EasingStyle.Back)
			ui.tween(win.frame, 0.32, { Position = UDim2.fromOffset(win.x, win.y) }, Enum.EasingStyle.Quint)
		end
	else
		win.dim.BackgroundTransparency = 0.4
	end
	if focusId then
		for _, entry in ipairs(state.clean.people) do
			if entry.id == focusId then
				showDetail(entry)
			end
		end
	end
	return win
end

local function teardown()
	if state then
		if state.win then
			dropWindow(state.win)
		end
		state.alive = false
		for _, conn in ipairs(state.conns) do
			pcall(function()
				conn:Disconnect()
			end)
		end
		state = nil
	end
end

local function buildEntryCard(block)
	local ui, T = ctx.UI, ctx.T
	local clean = state.clean
	local card = ui.button(block.frame, { Name = "CreditsCard", BackgroundColor3 = T.card, Size = UDim2.new(1, 0, 0, 84), LayoutOrder = 1, ClipsDescendants = true })
	ui.corner(card, 18)
	local edge = ui.stroke(card, T.stroke, 1, 0.5)
	ui.accent(edge, "Color")
	glow(card, "Glow", 0, 0.78, 1, 18)
	local featured = Mod.featured(clean)
	local stack = ui.new("Frame", { Name = "Faces", BackgroundTransparency = 1, Position = UDim2.fromOffset(14, 21), Size = UDim2.fromOffset(42 + math.max(0, math.min(3, #featured) - 1) * 24, 42) }, card)
	local shown = math.min(3, #featured)
	for i = 1, shown do
		local entry = featured[i]
		local _, slot = makeAvatar(stack, entry, 40, "head", { Position = UDim2.fromOffset((i - 1) * 24, 1), ZIndex = 10 - i })
		if not entry.verified then
			local gap = ui.stroke(slot.holder, T.card, 2, 0)
			gap.Name = "Gap"
		end
		applyAvatar(slot)
	end
	if shown == 0 then
		local only = ui.new("Frame", { Name = "Icon", BackgroundColor3 = T.card2, Size = UDim2.fromOffset(42, 42) }, stack)
		ui.corner(only, 21)
		ui.icon("heart-handshake", 20, T.text, only, { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5) })
	end
	local left = 14 + stack.Size.X.Offset + 14
	ui.label(card, { Name = "Title", Text = "Credits", Font = ctx.FONT_B, TextSize = 15, Position = UDim2.fromOffset(left, 20), Size = UDim2.new(1, -(left + 44), 0, 20) })
	ui.label(card, {
		Name = "Sub",
		Text = #clean.people .. " people and projects  ·  tap to meet them",
		TextSize = 11,
		TextColor3 = T.sub,
		Position = UDim2.fromOffset(left, 42),
		Size = UDim2.new(1, -(left + 44), 0, 16),
		TextTruncate = Enum.TextTruncate.AtEnd,
	})
	local arrow = ui.new("Frame", { Name = "Go", BackgroundColor3 = T.card2, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -14, 0.5, 0), Size = UDim2.fromOffset(32, 32) }, card)
	ui.corner(arrow, 16)
	ui.icon("chevron-right", 14, T.text, arrow, { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5) })
	ui.pressable(card, 0.97)
	hoverable(card, T.card, T.card2)
	card.Activated:Connect(function()
		openWindow(nil)
	end)
	return card
end

function Mod.build(parent, order)
	local ui = ctx.UI
	teardown()
	state = {
		alive = true, conns = {}, query = "", filter = "All", names = {}, ids = {}, thumbs = {}, refreshed = {}, queue = {},
		pics = {}, picWait = {}, win = nil, saving = false, pumping = false, token = 0,
	}
	local saved = ctx.FS.read(Mod.CACHE)
	if isText(saved) then
		local loaded = Mod.cacheDecode(saved, ctx.jsonDecode)
		state.names, state.ids = loaded.names, loaded.ids
	end
	local block = { alive = true }
	block.frame = ui.new("Frame", { Name = "CreditsBlock", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = order or 1 }, parent)
	ui.list(block.frame, 6)
	function block.destroy()
		block.alive = false
		if state and state.block == block then
			teardown()
		end
		block.frame:Destroy()
	end
	function block.close()
		closeWindow(false)
	end
	function block.window()
		return state and state.block == block and state.win or nil
	end
	local src, err = ctx.Core.fileSource("Hub/credits.json")
	block.clean = Mod.sanitize(src and ctx.jsonDecode(src) or nil)
	state.clean = block.clean
	state.block = block
	if #block.clean.people == 0 then
		ctx.Ctl.note(block.frame, 1, "The credits list didn't load" .. (err and (": " .. tostring(err)) or "") .. ". Reload the hub and look again.")
		function block.open()
			return nil
		end
		return block
	end
	if #block.clean.skipped > 0 then
		ctx.Log.add("warn", "Hub", "credits: " .. #block.clean.skipped .. " entries were skipped, run Testing/validate_credits.py")
	end
	block.button = buildEntryCard(block)
	function block.open(id)
		if not (state and state.block == block) then
			return nil
		end
		local win = openWindow(id)
		if win and id then
			return win.detail
		end
		return win
	end
	function block.copy()
		ctx.copyText(Mod.plainText(block.clean), "Credits")
	end
	function block.relayout()
		relayout()
	end
	return block
end

function Mod.destroy()
	teardown()
	ctx = nil
end

return Mod
