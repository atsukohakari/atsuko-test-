local Art = {}

Art.VERSION = 1
Art.DATA_FILE = "AtsukoHub/data/scriptart.json"
Art.BROKEN_FILE = "AtsukoHub/data/scriptart_broken.json"
Art.CACHE_DIR = "AtsukoHub/cache/art"
Art.THUMB_DIR = "AtsukoHub/cache/art_thumb"
Art.MAX_BYTES = 8 * 1024 * 1024
Art.WARN_BYTES = 2 * 1024 * 1024
Art.THUMB_MAX = 1536 * 1024
Art.TIMEOUT = 15
Art.PROBE_TIMEOUT = 4
Art.FADE = 0.25
Art.SHOW_WAIT = 1.5
Art.BROKEN_WAIT = 8
Art.PAD = 8
Art.LOGO = 72
Art.RATIO = 3
Art.KINDS = { logo = true, banner = true }
Art.IMAGE_EXTS = { png = true, jpg = true, jpeg = true, jpe = true, jfif = true, gif = true, bmp = true, dib = true, webp = true, ico = true, avif = true, heic = true, heif = true, svg = true, tga = true }
Art.DEFAULT_CONVERTER = {
	name = "images.weserv.nl",
	url = "https://images.weserv.nl/?url={url}&output=png",
	note = "Sends the picture link to images.weserv.nl, a free service that turns it into a PNG. It keeps logs for about a week and may keep the picture for up to a month. Only used when Roblox can't show the picture itself.",
}

local ctx = nil
local deps = nil
local store = nil
local converter = nil
local idCache = {}
local brokenWhy = {}
local restoring = {}
local saveWarned = false
local views = {}

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

function Art.fmtBytes(bytes)
	bytes = tonumber(bytes) or 0
	if bytes <= 0 then
		return ""
	end
	if bytes < 1024 then
		return bytes .. " B"
	end
	if bytes < 1048576 then
		return string.format("%.0f KB", bytes / 1024)
	end
	return string.format("%.1f MB", bytes / 1048576)
end

function Art.urlEncode(text)
	return (string.gsub(tostring(text), "[^%w%-%._~]", function(c)
		return string.format("%%%02X", string.byte(c))
	end))
end

function Art.converterUrl(template, link)
	if type(template) ~= "string" or type(link) ~= "string" then
		return nil
	end
	if string.sub(template, 1, 8) ~= "https://" or not string.find(template, "{url}", 1, true) then
		return nil
	end
	local encoded = Art.urlEncode(link)
	return (string.gsub(template, "{url}", function()
		return encoded
	end))
end

function Art.cleanConverter(raw)
	local base = Art.DEFAULT_CONVERTER
	if type(raw) ~= "table" then
		return { name = base.name, url = base.url, note = base.note }
	end
	local url = type(raw.url) == "string" and raw.url or nil
	if not (url and string.sub(url, 1, 8) == "https://" and string.find(url, "{url}", 1, true) and #url <= 300 and not string.find(url, "%s")) then
		url = base.url
	end
	local name = type(raw.name) == "string" and trim(raw.name) or ""
	if name == "" or #name > 60 then
		name = string.match(url, "^https://([^/%?]+)") or base.name
	end
	local note = type(raw.note) == "string" and trim(raw.note) or ""
	if note == "" or #note > 400 then
		note = "Sends the picture link to " .. name .. ", a third party, to turn it into a PNG. Only used when Roblox can't show the picture itself."
	end
	return { name = name, url = url, note = note }
end

function Art.parseLink(text)
	text = trim(text)
	if text == "" then
		return nil, "paste a picture link first"
	end
	if #text > 2000 then
		return nil, "that link is too long"
	end
	if string.find(text, "%s") then
		return nil, "a picture link can't have spaces in it"
	end
	local digits = string.match(text, "^(%d+)$")
	if digits then
		if #digits > 19 then
			return nil, "that number is too long to be an asset id"
		end
		return { src = "asset", value = "rbxassetid://" .. digits }
	end
	local lower = string.lower(text)
	local assetId = string.match(lower, "^rbxassetid://(%d+)$")
	if assetId then
		if #assetId > 19 then
			return nil, "that number is too long to be an asset id"
		end
		return { src = "asset", value = "rbxassetid://" .. assetId }
	end
	if string.sub(lower, 1, 11) == "rbxthumb://" then
		if not (string.find(lower, "type=", 1, true) and string.find(lower, "id=%d")) then
			return nil, "that rbxthumb link needs a type= and an id= part"
		end
		return { src = "asset", value = "rbxthumb://" .. string.sub(text, 12) }
	end
	local scheme = string.match(lower, "^(%a[%w%+%.%-]*):")
	if scheme == "rbxassetid" then
		return nil, "an asset id needs a number after rbxassetid://"
	end
	if scheme == "http" then
		return nil, "use a link that starts with https://"
	end
	if scheme and scheme ~= "https" then
		return nil, "links that start with " .. scheme .. ": aren't supported, use https://, rbxassetid:// or an asset id"
	end
	if not scheme then
		return nil, "add https:// in front of the link, or use an asset id"
	end
	local rest = string.sub(text, 9)
	local host = string.match(rest, "^([^/%?#]+)")
	if not host or host == "" then
		return nil, "that link has no site name in it"
	end
	if not string.find(host, ".", 1, true) or string.sub(host, -1) == "." or string.sub(host, 1, 1) == "." then
		return nil, "that link doesn't look complete"
	end
	local value = "https://" .. rest
	local rewritten = false
	local owner, repo, tail = string.match(rest, "^[Gg][Ii][Tt][Hh][Uu][Bb]%.[Cc][Oo][Mm]/([^/]+)/([^/]+)/blob/(.+)$")
	if owner then
		tail = string.gsub(tail, "%?.*$", "")
		value = "https://raw.githubusercontent.com/" .. owner .. "/" .. repo .. "/" .. tail
		rewritten = true
	end
	return { src = "url", value = value, host = string.lower(host), rewritten = rewritten }
end

function Art.parseFile(text)
	text = trim(text)
	local quoted = string.match(text, '^"(.*)"$') or string.match(text, "^'(.*)'$")
	if quoted then
		text = trim(quoted)
	end
	if text == "" then
		return nil, "type a file name or path first"
	end
	if #text > 240 then
		return nil, "that path is too long"
	end
	if string.find(text, "://", 1, true) then
		return nil, "that looks like a link, use the Link tab for links"
	end
	for i = 1, #text do
		if string.byte(text, i) < 32 then
			return nil, "that path has a character that can't be in a file name"
		end
	end
	text = string.gsub(text, "\\", "/")
	if string.sub(text, 1, 1) == "/" or string.match(text, "^%a:") or string.sub(text, 1, 2) == "~/" then
		return nil, "use a path inside your executor's workspace folder, like pics/me.png"
	end
	local parts = {}
	for part in string.gmatch(text, "[^/]+") do
		if part == ".." then
			return nil, "a path can't go up a folder with .."
		end
		if part ~= "." then
			parts[#parts + 1] = part
		end
	end
	if #parts == 0 then
		return nil, "type a file name or path first"
	end
	return { src = "file", value = table.concat(parts, "/") }
end

function Art.withoutWorkspace(path)
	local rest = string.match(tostring(path), "^[Ww][Oo][Rr][Kk][Ss][Pp][Aa][Cc][Ee]/(.+)$")
	return rest
end

function Art.metrics(width)
	width = tonumber(width) or 0
	if width < 120 then
		width = 120
	end
	local pad = Art.PAD
	local bannerW = width - pad * 2
	local bannerH = math.floor(bannerW / Art.RATIO + 0.5)
	local logo = Art.LOGO
	local nameY = pad + bannerH + 8
	return {
		width = width,
		pad = pad,
		bannerW = bannerW,
		bannerH = bannerH,
		logo = logo,
		logoX = pad + 10,
		logoY = pad + bannerH - math.floor(logo / 2),
		textX = pad + 10 + logo + 12,
		nameY = nameY,
		subY = nameY + 23,
		heartY = nameY + 2,
		chipX = pad + 8,
		chipY = pad + 8,
		height = pad + bannerH + 56,
	}
end

function Art.httpWhy(code, body)
	code = tonumber(code) or 0
	if code == 0 then
		local why = firstLine(body)
		if why ~= "" and #why <= 120 then
			return "couldn't reach that link (" .. why .. ")"
		end
		return "couldn't reach that link"
	end
	if code == 401 or code == 403 then
		return "that site won't let me download the picture (HTTP " .. code .. ")"
	end
	if code == 404 or code == 410 then
		return "nothing is at that link any more (HTTP " .. code .. ")"
	end
	if code == 429 then
		return "that site says too many requests, wait a minute and try again"
	end
	if code >= 500 then
		return "that site had a problem (HTTP " .. code .. "), try again later"
	end
	return "that site answered HTTP " .. code
end

function Art.cantShow(info, source)
	local ext = info and (info.ext or info.format) or "this"
	if source == "file" then
		return "Roblox can't show ." .. ext .. " pictures. Convert it to PNG or JPG and pick it again."
	end
	return "Roblox can't show ." .. ext .. " pictures. Turn on the online converter below, or use a PNG or JPG link."
end

function Art.probeFailure(status, info, source, truncated)
	local format = info and info.format or nil
	if source == "asset" then
		if status == "timeout" then
			return "Roblox took too long to load that. Check the number, or try again in a moment."
		end
		return "Roblox couldn't load that asset. Check the number, and that it is a public image."
	end
	if truncated then
		return "That picture looks cut off, so Roblox can't show it. Download it again and pick it again."
	end
	if format == "png" or format == "jpeg" then
		if status == "timeout" then
			return "Roblox took too long to show that picture. It may be too big, try a smaller one."
		end
		return "Roblox couldn't show that picture even though it looks like a normal " .. info.label .. ". It may be damaged or too big, try another one."
	end
	return Art.cantShow(info, source)
end

function Art.judge(status, format, isAsset)
	if status == "loaded" or status == "unchecked" then
		return true
	end
	if status == "fetched" then
		return isAsset == true or format == "png" or format == "jpeg"
	end
	return false
end

function Art.describe(result)
	if type(result) ~= "table" then
		return ""
	end
	local bits = {}
	if result.src == "asset" then
		bits[1] = "Roblox asset"
	else
		local label = result.label or string.upper(tostring(result.format or "?"))
		if result.w and result.h then
			label = label .. "  ·  " .. result.w .. " x " .. result.h
		end
		bits[1] = label
		if result.size then
			bits[#bits + 1] = Art.fmtBytes(result.size)
		end
	end
	return table.concat(bits, "  ·  ")
end

function Art.safeCache(path)
	if type(path) ~= "string" then
		return false
	end
	local prefix = Art.CACHE_DIR .. "/"
	if string.sub(path, 1, #prefix) ~= prefix then
		return false
	end
	local name = string.sub(path, #prefix + 1)
	return name ~= "" and not string.find(name, "/", 1, true) and not string.find(name, "..", 1, true)
end

function Art.arrange(entries, opts)
	opts = opts or {}
	local search = string.lower(trim(opts.search or ""))
	local sort = opts.sort == "size" and "size" or "name"
	local folders, files = {}, {}
	local function key(name)
		return (string.gsub(string.lower(name), "%d+", function(digits)
			return string.rep("0", math.max(0, 12 - #digits)) .. digits
		end))
	end
	for _, entry in ipairs(entries or {}) do
		local keep = search == "" or string.find(string.lower(entry.name), search, 1, true) ~= nil
		if keep then
			if entry.folder then
				folders[#folders + 1] = entry
			else
				local ext = entry.ext or ""
				if opts.allFiles or ext == "" or Art.IMAGE_EXTS[ext] then
					files[#files + 1] = entry
				end
			end
		end
	end
	local function byName(a, b)
		local ka, kb = key(a.name), key(b.name)
		if ka ~= kb then
			return ka < kb
		end
		return a.name < b.name
	end
	table.sort(folders, byName)
	if sort == "size" then
		table.sort(files, function(a, b)
			local sa, sb = a.size or -1, b.size or -1
			if sa ~= sb then
				return sa > sb
			end
			return byName(a, b)
		end)
	else
		table.sort(files, byName)
	end
	local out = {}
	for _, entry in ipairs(folders) do
		out[#out + 1] = entry
	end
	for _, entry in ipairs(files) do
		out[#out + 1] = entry
	end
	return out
end

local SOURCES = { url = true, file = true, asset = true }

local function cap(text)
	return (string.gsub(tostring(text or ""), "^%l", string.upper))
end

local function normalizePath(path)
	path = string.gsub(tostring(path or ""), "\\", "/")
	path = string.gsub(path, "^%./+", "")
	path = string.gsub(path, "/+$", "")
	return path
end

local function baseName(path)
	return string.match(path, "([^/]+)$") or path
end

local function headerOf(headers, name)
	name = string.lower(name)
	if type(headers) == "table" then
		for key, value in pairs(headers) do
			if type(key) == "string" and string.lower(key) == name then
				return value
			end
		end
	end
	return nil
end

Art.normalizePath = normalizePath
Art.baseName = baseName
Art.cap = cap

local function cleanItem(raw)
	if type(raw) ~= "table" or not SOURCES[raw.src] then
		return nil
	end
	if type(raw.value) ~= "string" or raw.value == "" or #raw.value > 2000 then
		return nil
	end
	local item = { src = raw.src, value = raw.value }
	if raw.src == "asset" then
		local spec = Art.parseLink(raw.value)
		if not spec or spec.src ~= "asset" then
			return nil
		end
		item.value = spec.value
	else
		if not Art.safeCache(raw.cached) then
			return nil
		end
		item.cached = raw.cached
	end
	for _, key in ipairs({ "format", "ext", "label" }) do
		if type(raw[key]) == "string" and raw[key] ~= "" and #raw[key] <= 12 then
			item[key] = raw[key]
		end
	end
	for _, key in ipairs({ "w", "h", "size" }) do
		local number = raw[key]
		if type(number) == "number" and number == number and number >= 0 and number < 1e9 then
			item[key] = math.floor(number)
		end
	end
	if raw.converted == true then
		item.converted = true
	end
	if type(raw.at) == "number" and raw.at == raw.at then
		item.at = raw.at
	end
	return item
end

Art.cleanItem = cleanItem

local function fire(path, kind)
	if ctx and ctx.Bus then
		pcall(ctx.Bus.fire, "scriptart", path, kind)
	end
end

function Art.load()
	store = { version = Art.VERSION, items = {}, lastFolder = "" }
	idCache = {}
	local text = deps.fs.read(Art.DATA_FILE)
	if type(text) ~= "string" or text == "" then
		return true
	end
	local data = deps.json.decode(text)
	if type(data) ~= "table" or type(data.items) ~= "table" then
		deps.fs.write(Art.BROKEN_FILE, text)
		return false
	end
	for path, rec in pairs(data.items) do
		if type(path) == "string" and path ~= "" and #path <= 300 and type(rec) == "table" then
			local entry = {}
			for kind in pairs(Art.KINDS) do
				local item = cleanItem(rec[kind])
				if item then
					entry[kind] = item
				end
			end
			if entry.logo or entry.banner then
				store.items[path] = entry
			end
		end
	end
	if type(data.lastFolder) == "string" and #data.lastFolder <= 240 then
		store.lastFolder = data.lastFolder
	end
	return true
end

function Art.save()
	if not store then
		return false
	end
	local text = deps.json.encode({ version = Art.VERSION, items = store.items, lastFolder = store.lastFolder })
	local ok = type(text) == "string" and deps.fs.write(Art.DATA_FILE, text) == true
	if not ok and not saveWarned then
		saveWarned = true
		toast("Pictures", "Couldn't save your pictures list. They work until you close the hub.", "warn", 5)
	end
	return ok
end

function Art.get(path, kind)
	local rec = store and store.items[path]
	local item = rec and rec[kind]
	if not item then
		return nil
	end
	local copy = {}
	for key, value in pairs(item) do
		copy[key] = value
	end
	return copy
end

function Art.count()
	local n = 0
	for _, rec in pairs(store and store.items or {}) do
		for kind in pairs(Art.KINDS) do
			if rec[kind] then
				n = n + 1
			end
		end
	end
	return n
end

local function referenced(cached)
	for _, rec in pairs(store and store.items or {}) do
		for kind in pairs(Art.KINDS) do
			if rec[kind] and rec[kind].cached == cached then
				return true
			end
		end
	end
	return false
end

function Art.release(cached)
	if not Art.safeCache(cached) or referenced(cached) then
		return false
	end
	idCache[cached] = nil
	deps.fs.delete(cached)
	return true
end

function Art.set(path, kind, result)
	if not store then
		return false, "pictures aren't ready yet"
	end
	if type(path) ~= "string" or path == "" or #path > 300 or not Art.KINDS[kind] then
		return false, "that isn't a picture spot"
	end
	if type(result) ~= "table" or result.ok ~= true then
		return false, "there is no picture to use yet"
	end
	local item = cleanItem({
		src = result.src,
		value = result.value,
		cached = result.cached,
		format = result.format,
		ext = result.ext,
		label = result.label,
		w = result.w,
		h = result.h,
		size = result.size,
		converted = result.converted,
		at = deps.time(),
	})
	if not item then
		return false, "that picture can't be saved"
	end
	local rec = store.items[path] or {}
	local old = rec[kind]
	rec[kind] = item
	store.items[path] = rec
	brokenWhy[path .. "|" .. kind] = nil
	local saved = Art.save()
	if old and old.cached and old.cached ~= item.cached then
		Art.release(old.cached)
	end
	fire(path, kind)
	return true, saved
end

function Art.clear(path, kind)
	local rec = store and store.items[path]
	if not (rec and rec[kind]) then
		return false
	end
	local old = rec[kind]
	rec[kind] = nil
	if not rec.logo and not rec.banner then
		store.items[path] = nil
	end
	brokenWhy[path .. "|" .. kind] = nil
	Art.save()
	if old.cached then
		Art.release(old.cached)
	end
	fire(path, kind)
	return true
end

function Art.lastFolder()
	return store and store.lastFolder or ""
end

function Art.setLastFolder(dir)
	dir = normalizePath(dir)
	if store and store.lastFolder ~= dir then
		store.lastFolder = dir
		Art.save()
	end
end

function Art.imageFor(item)
	if type(item) ~= "table" then
		return nil, "none"
	end
	if item.src == "asset" then
		return item.value
	end
	local cached = item.cached
	if not cached then
		return nil, "missing"
	end
	local known = idCache[cached]
	if known then
		return known
	end
	if not deps.fs.exists(cached) then
		return nil, "missing"
	end
	local id = deps.asset(cached)
	if not id then
		return nil, "asset"
	end
	idCache[cached] = id
	return id
end

function Art.brokenReason(path, kind)
	return brokenWhy[path .. "|" .. kind]
end

function Art.converter()
	return converter or Art.cleanConverter(nil)
end

function Art.available()
	local has = deps and deps.has or {}
	return {
		files = has.files == true and has.assets == true,
		list = has.list == true,
		request = has.request == true,
		clipboard = has.clipboard == true,
	}
end

local function race(seconds, fn)
	local state = {}
	deps.spawn(function()
		local ok, a, b, c = pcall(fn)
		if state.late then
			return
		end
		state.done = true
		if ok then
			state.a, state.b, state.c = a, b, c
		else
			state.a, state.b = 0, firstLine(a)
		end
	end)
	local waited = 0
	while not state.done and waited < seconds do
		local dt = deps.wait(0.1)
		waited = waited + (tonumber(dt) or 0.1)
	end
	if not state.done then
		state.late = true
		return nil, nil, nil, true
	end
	return state.a, state.b, state.c, false
end

local function fail(stage, why, extra)
	local result = { ok = false, stage = stage, why = cap(why) }
	if extra then
		for key, value in pairs(extra) do
			result[key] = value
		end
	end
	return result
end

local function cancelledResult()
	return { ok = false, cancelled = true, stage = "cancelled", why = "" }
end

local function wasCancelled(opts)
	return opts.alive ~= nil and not opts.alive()
end

local ACCEPT = { Accept = "image/*,*/*;q=0.8" }
Art.HEAD_TIMEOUT = 6

local function fetchUrl(url, opts)
	local headCode, _, headHeaders, headLate = race(Art.HEAD_TIMEOUT, function()
		return deps.request("HEAD", url, ACCEPT)
	end)
	headCode = tonumber(headCode) or 0
	if not headLate and headCode >= 200 and headCode < 300 then
		local length = tonumber(headerOf(headHeaders, "content-length"))
		if length and length > Art.MAX_BYTES then
			return nil, "that picture is " .. Art.fmtBytes(length) .. ", the limit is " .. Art.fmtBytes(Art.MAX_BYTES)
		end
	end
	if wasCancelled(opts) then
		return nil, nil, true
	end
	local code, body, _, late = race(Art.TIMEOUT, function()
		return deps.request("GET", url, ACCEPT)
	end)
	if late then
		return nil, "that link took longer than " .. Art.TIMEOUT .. " seconds"
	end
	if wasCancelled(opts) then
		return nil, nil, true
	end
	code = tonumber(code) or 0
	if code < 200 or code >= 300 then
		return nil, Art.httpWhy(code, body)
	end
	if type(body) ~= "string" or body == "" then
		return nil, "that link gave nothing back"
	end
	return body
end

local function readFile(path)
	local candidates = { path }
	local stripped = Art.withoutWorkspace(path)
	if stripped then
		candidates[2] = stripped
	end
	for _, candidate in ipairs(candidates) do
		if deps.fs.exists(candidate) then
			local data = deps.fs.read(candidate)
			if type(data) ~= "string" then
				return nil, "I couldn't read that file"
			end
			return data, nil, candidate
		end
	end
	for _, candidate in ipairs(candidates) do
		if deps.fs.isfolder(candidate) then
			return nil, "that is a folder, pick a picture inside it"
		end
	end
	return nil, "there is no file called " .. path .. " in your workspace folder"
end

local function sampleKey(bytes, value)
	local n = #bytes
	local parts = { tostring(n), tostring(value or "") }
	local step = math.max(1, n // 64)
	local at = 1
	while at <= n and #parts < 70 do
		parts[#parts + 1] = string.sub(bytes, at, at + 15)
		at = at + step
	end
	parts[#parts + 1] = string.sub(bytes, -16)
	return table.concat(parts, "|")
end

function Art.cacheName(bytes, value, ext, dir)
	local key = sampleKey(bytes, value)
	return (dir or Art.CACHE_DIR) .. "/" .. deps.hash(key) .. deps.hash("art|" .. key) .. "." .. ext
end

local function writeCache(bytes, value, ext, dir)
	local path = Art.cacheName(bytes, value, ext, dir)
	if deps.fs.exists(path) then
		local old = deps.fs.read(path)
		if type(old) == "string" and #old == #bytes then
			return path
		end
	end
	if not deps.fs.write(path, bytes) then
		return nil, "I couldn't save a copy of the picture in your workspace folder"
	end
	return path
end

local function probe(id, opts)
	if not opts.host or not deps.probe then
		return "unchecked"
	end
	return deps.probe(id, opts.host) or "failed"
end

local function success(spec, info, size, cached, id, extra)
	local result = {
		ok = true,
		src = spec.src,
		value = spec.value,
		cached = cached,
		id = id,
		format = info.format,
		ext = info.ext,
		label = info.label,
		w = info.width,
		h = info.height,
		size = size,
		truncated = info.truncated or nil,
	}
	for key, value in pairs(extra or {}) do
		result[key] = value
	end
	return result
end

local function convertLink(spec, opts)
	local config = converter or Art.cleanConverter(nil)
	local api = Art.converterUrl(config.url, spec.value)
	if not api then
		return fail("convert", "The online converter isn't set up right.")
	end
	local code, body, _, late = race(Art.TIMEOUT, function()
		return deps.request("GET", api, ACCEPT)
	end)
	if late then
		return fail("convert", "The online converter took too long. Try again later, or use a PNG or JPG link.")
	end
	if wasCancelled(opts) then
		return cancelledResult()
	end
	code = tonumber(code) or 0
	if code < 200 or code >= 300 or type(body) ~= "string" or body == "" then
		return fail("convert", "The online converter couldn't turn that into a picture: " .. Art.httpWhy(code, body) .. ".")
	end
	if #body > Art.MAX_BYTES then
		return fail("convert", "The converted picture is " .. Art.fmtBytes(#body) .. ", the limit is " .. Art.fmtBytes(Art.MAX_BYTES) .. ".")
	end
	local info = deps.sniff.sniff(body, "converted.png")
	if not info or info.format ~= "png" then
		return fail("convert", "The online converter didn't send a PNG back.")
	end
	local cached, why = writeCache(body, spec.value .. "|png", "png")
	if not cached then
		return fail("cache", why)
	end
	local id = deps.asset(cached)
	if not id then
		Art.release(cached)
		return fail("asset", "Your executor couldn't load that picture from its workspace.")
	end
	local status = probe(id, opts)
	if wasCancelled(opts) then
		Art.release(cached)
		return cancelledResult()
	end
	if not Art.judge(status, "png", false) then
		Art.release(cached)
		return fail("probe", "Roblox couldn't show the converted picture either. Try another picture.")
	end
	idCache[cached] = id
	return success(spec, info, #body, cached, id, { converted = true, unchecked = status == "unchecked" or nil })
end

local function finishBytes(spec, bytes, opts, name)
	if #bytes > Art.MAX_BYTES then
		return fail("size", "that picture is " .. Art.fmtBytes(#bytes) .. ", the limit is " .. Art.fmtBytes(Art.MAX_BYTES))
	end
	local info, why = deps.sniff.sniff(bytes, name)
	if not info then
		return fail("sniff", why)
	end
	if not (deps.has.files and deps.has.assets) then
		return fail("setup", "Your executor can't show pictures from files or links (it has no getcustomasset). Asset ids still work.")
	end
	local warnings = {}
	if info.truncated then
		warnings[#warnings + 1] = "This picture looks cut short, it may show only part of the image."
	end
	if #bytes > Art.WARN_BYTES then
		warnings[#warnings + 1] = "This picture is " .. Art.fmtBytes(#bytes) .. ", it may load slowly."
	end
	local note = nil
	if deps.sniff.mismatch(name, info) then
		note = "The name says ." .. deps.sniff.extOf(name) .. " but it is really a " .. info.label .. " picture, which is fine."
	end
	local cached, cacheWhy = writeCache(bytes, spec.value, info.ext)
	if not cached then
		return fail("cache", cacheWhy)
	end
	local id = deps.asset(cached)
	if not id then
		Art.release(cached)
		return fail("asset", "Your executor couldn't load that picture from its workspace.")
	end
	local status = probe(id, opts)
	if wasCancelled(opts) then
		Art.release(cached)
		return cancelledResult()
	end
	if Art.judge(status, info.format, false) then
		idCache[cached] = id
		return success(spec, info, #bytes, cached, id, {
			warn = #warnings > 0 and table.concat(warnings, " ") or nil,
			note = note,
			name = spec.src == "file" and baseName(spec.value) or nil,
			unchecked = status == "unchecked" or nil,
		})
	end
	Art.release(cached)
	if spec.src == "url" and opts.convert then
		return convertLink(spec, opts)
	end
	return fail("probe", Art.probeFailure(status, info, spec.src, info.truncated), {
		needConvert = spec.src == "url" and not opts.convert or nil,
		status = status,
		format = info.format,
		ext = info.ext,
	})
end

local function resolveAsset(spec, opts)
	local status = probe(spec.value, opts)
	if wasCancelled(opts) then
		return cancelledResult()
	end
	if Art.judge(status, nil, true) then
		return { ok = true, src = "asset", value = spec.value, id = spec.value, unchecked = status == "unchecked" or nil }
	end
	return fail("probe", Art.probeFailure(status, nil, "asset"), { status = status })
end

function Art.resolveNow(spec, opts)
	opts = opts or {}
	if type(spec) ~= "table" or not SOURCES[spec.src] or type(spec.value) ~= "string" then
		return fail("parse", "There is nothing to load yet.")
	end
	if spec.src == "asset" then
		return resolveAsset(spec, opts)
	end
	if not (deps.has.files and deps.has.assets) then
		return fail("setup", "Your executor can't show pictures from files or links (it has no getcustomasset). Asset ids still work.")
	end
	if spec.src == "url" and not deps.has.request then
		return fail("setup", "Your executor can't download from links (it has no request function). Asset ids and workspace files still work.")
	end
	if spec.src == "url" and opts.forceConvert then
		return convertLink(spec, opts)
	end
	local bytes, why, extra, name
	if spec.src == "url" then
		bytes, why, extra = fetchUrl(spec.value, opts)
		name = spec.value
	else
		bytes, why, extra = readFile(spec.value)
		name = spec.value
		if bytes and type(extra) == "string" then
			spec = { src = "file", value = extra }
			name = extra
		end
	end
	if extra == true or wasCancelled(opts) then
		return cancelledResult()
	end
	if not bytes then
		return fail("fetch", why)
	end
	return finishBytes(spec, bytes, opts, name)
end

function Art.resolve(spec, opts, cb)
	deps.spawn(function()
		local ok, result = pcall(Art.resolveNow, spec, opts)
		if not ok then
			if ctx and ctx.Log then
				pcall(ctx.Log.add, "error", "Hub", "picture: " .. firstLine(result))
			end
			result = fail("crash", "Something went wrong while loading that picture.")
		end
		cb(result)
	end)
end

function Art.restore(path, kind)
	local key = path .. "|" .. kind
	local item = Art.get(path, kind)
	if restoring[key] or not item or item.src == "asset" then
		return false
	end
	restoring[key] = true
	deps.spawn(function()
		local ok, result = pcall(Art.resolveNow, { src = item.src, value = item.value }, { forceConvert = item.converted == true })
		restoring[key] = nil
		if not ctx then
			return
		end
		local now = Art.get(path, kind)
		if not ok then
			result = fail("crash", "Something went wrong while loading that picture.")
		end
		if not now or now.value ~= item.value then
			if result.ok then
				Art.release(result.cached)
			end
			return
		end
		if result.ok then
			brokenWhy[key] = nil
			Art.set(path, kind, result)
		else
			brokenWhy[key] = result.why
			fire(path, kind)
		end
	end)
	return true
end

function Art.listDir(dir)
	if not deps.has.list then
		return nil, "your executor can't list folders, type the path instead"
	end
	dir = normalizePath(dir)
	local raw = deps.fs.list(dir)
	if raw == nil and dir == "" then
		raw = deps.fs.list(".")
	end
	if type(raw) ~= "table" then
		return nil, "I couldn't open that folder"
	end
	local out = {}
	for _, item in ipairs(raw) do
		local path = normalizePath(item)
		if dir ~= "" and not string.find(path, "/", 1, true) then
			path = dir .. "/" .. path
		end
		local name = baseName(path)
		if name ~= "" and string.sub(name, 1, 1) ~= "." then
			out[#out + 1] = { path = path, name = name, folder = deps.fs.isfolder(path), ext = deps.sniff.extOf(name) }
		end
	end
	return out
end

function Art.thumbNow(path)
	if not (deps.has.files and deps.has.assets) then
		return nil, "unsupported"
	end
	local data = deps.fs.read(path)
	if type(data) ~= "string" then
		return nil, "unreadable"
	end
	local size = #data
	if size > Art.THUMB_MAX then
		return nil, "big", { size = size }
	end
	local info, why = deps.sniff.sniff(data, path)
	if not info then
		return nil, "notimage", { size = size, why = why }
	end
	local meta = { size = size, info = info }
	local id = nil
	if deps.sniff.nameFormat(path) and not deps.sniff.mismatch(path, info) then
		id = deps.asset(path)
	else
		local copy = writeCache(data, path, info.ext, Art.THUMB_DIR)
		id = copy and deps.asset(copy) or nil
		meta.copy = copy
	end
	if not id then
		return nil, "asset", meta
	end
	return id, "ok", meta
end

function Art.dropThumbs(list)
	local prefix = Art.THUMB_DIR .. "/"
	local removed = 0
	for _, path in ipairs(list or {}) do
		if type(path) == "string" and string.sub(path, 1, #prefix) == prefix then
			local name = string.sub(path, #prefix + 1)
			if name ~= "" and not string.find(name, "/", 1, true) and not string.find(name, "..", 1, true) then
				deps.fs.delete(path)
				removed = removed + 1
			end
		end
	end
	return removed
end

Art.MEASURE_MAX = 400

function Art.measure(entries, onProgress, isAlive)
	local list = {}
	for _, entry in ipairs(entries or {}) do
		if not entry.folder and entry.size == nil then
			list[#list + 1] = entry
		end
	end
	local total = math.min(#list, Art.MEASURE_MAX)
	for i = 1, total do
		if isAlive and not isAlive() then
			return i - 1
		end
		local data = deps.fs.read(list[i].path)
		list[i].size = type(data) == "string" and #data or 0
		if onProgress then
			onProgress(i, total)
		end
		if i % 6 == 0 then
			deps.wait(0.02)
		end
	end
	return total
end

function Art.sweep()
	if not deps.has.list then
		return 0
	end
	local removed = 0
	local function each(dir, test)
		local listed = deps.fs.list(dir)
		if type(listed) ~= "table" then
			return
		end
		for _, item in ipairs(listed) do
			local path = normalizePath(item)
			if not string.find(path, "/", 1, true) then
				path = dir .. "/" .. path
			end
			if test(path) then
				deps.fs.delete(path)
				removed = removed + 1
			end
		end
	end
	each(Art.CACHE_DIR, function(path)
		return Art.safeCache(path) and not referenced(path)
	end)
	local thumbPrefix = Art.THUMB_DIR .. "/"
	each(Art.THUMB_DIR, function(path)
		local name = string.sub(path, #thumbPrefix + 1)
		return string.sub(path, 1, #thumbPrefix) == thumbPrefix and name ~= "" and not string.find(name, "/", 1, true) and not string.find(name, "..", 1, true)
	end)
	return removed
end

local function defaultProbe(id, host)
	local made, label = pcall(function()
		local l = Instance.new("ImageLabel")
		l.Name = "ArtProbe"
		l.BackgroundTransparency = 1
		l.ImageTransparency = 0.98
		l.Size = UDim2.fromOffset(4, 4)
		l.Image = id
		l.Parent = host
		return l
	end)
	if not made then
		return "unchecked"
	end
	local reported = nil
	task.spawn(function()
		local ok = pcall(function()
			game:GetService("ContentProvider"):PreloadAsync({ label }, function(_, status)
				if status == Enum.AssetFetchStatus.Success then
					reported = reported or "fetched"
				else
					reported = "failed"
				end
			end)
		end)
		if not ok and not reported then
			reported = "failed"
		end
	end)
	local waited = 0
	local fetchedAt = nil
	local final = nil
	while waited < Art.PROBE_TIMEOUT and not final do
		local readable, loaded = pcall(function()
			return label.IsLoaded
		end)
		if readable and loaded == true then
			final = "loaded"
		elseif reported == "failed" then
			final = "failed"
		elseif reported == "fetched" then
			fetchedAt = fetchedAt or waited
			if waited - fetchedAt >= 0.6 then
				final = "fetched"
			end
		end
		if not final then
			task.wait(0.05)
			waited = waited + 0.05
		end
	end
	pcall(function()
		label:Destroy()
	end)
	return final or (reported == "fetched" and "fetched") or "timeout"
end

local function buildDeps(c)
	local X = c.X or {}
	local FS = c.FS
	local has = {
		files = c.HAS_FS == true,
		assets = X.getcustomasset ~= nil,
		list = X.listfiles ~= nil and X.isfolder ~= nil,
		request = X.request ~= nil,
		clipboard = X.getclipboard ~= nil,
	}
	return {
		has = has,
		fs = {
			exists = function(path)
				return FS.exists(path)
			end,
			read = function(path)
				return FS.read(path)
			end,
			write = function(path, data)
				return FS.write(path, data)
			end,
			delete = function(path)
				FS.delete(path)
			end,
			isfolder = function(path)
				if not X.isfolder then
					return false
				end
				local ok, result = pcall(X.isfolder, path)
				return ok and result == true
			end,
			list = function(dir)
				if not X.listfiles then
					return nil
				end
				local ok, result = pcall(X.listfiles, dir)
				if ok and type(result) == "table" then
					return result
				end
				return nil
			end,
		},
		sniff = c.Core.loadModule("imgsniff"),
		asset = function(path)
			if not X.getcustomasset then
				return nil
			end
			local ok, id = pcall(X.getcustomasset, path)
			if ok and type(id) == "string" and id ~= "" then
				return id
			end
			return nil
		end,
		request = function(method, url, headers)
			return c.Net.request(method, url, headers)
		end,
		probe = defaultProbe,
		json = { encode = c.jsonEncode, decode = c.jsonDecode },
		hash = c.Util.hash,
		spawn = task.spawn,
		delay = task.delay,
		wait = task.wait,
		time = os.time,
		clipboard = function()
			if not X.getclipboard then
				return nil
			end
			local ok, text = pcall(X.getclipboard)
			if ok and type(text) == "string" then
				return text
			end
			return nil
		end,
		configText = function()
			local src = c.Core.fileSource("Hub/art.json", false)
			return src
		end,
	}
end

function Art.init(context)
	ctx = context
	deps = context.artDeps or buildDeps(context)
	if not deps.sniff then
		error("the picture checker didn't load")
	end
	converter = Art.cleanConverter(nil)
	saveWarned = false
	idCache = {}
	brokenWhy = {}
	restoring = {}
	views = {}
	Art.load()
	Art.sweep()
	if deps.configText then
		deps.spawn(function()
			local text = deps.configText()
			local data = type(text) == "string" and deps.json.decode(text) or nil
			if ctx and type(data) == "table" then
				converter = Art.cleanConverter(data.converter)
			end
		end)
	end
end

function Art.destroy()
	local list = views
	views = {}
	for _, view in ipairs(list) do
		pcall(view.destroy)
	end
	ctx = nil
	store = nil
end

function Art.clipboard()
	return deps and deps.clipboard and deps.clipboard() or nil
end

function Art.retry(path, kind)
	local item = Art.get(path, kind)
	if not item then
		return false
	end
	if item.cached then
		idCache[item.cached] = nil
	end
	brokenWhy[path .. "|" .. kind] = nil
	if item.src ~= "asset" and not deps.fs.exists(item.cached or "") then
		return Art.restore(path, kind)
	end
	fire(path, kind)
	return true
end

function Art.openPicker(path, kind, name)
	if not ctx or not Art.KINDS[kind] or type(path) ~= "string" then
		return false
	end
	local picker = ctx.Core.loadModule("imagepicker")
	if not picker then
		toast("Pictures", "The picture picker didn't load. Reload the hub and try again.", "error", 4)
		return false
	end
	picker.open(Art, path, kind, name)
	return true
end

local function dashedOutline(parent)
	local UI, T = ctx.UI, ctx.T
	local stroke = UI.stroke(parent, T.dim, 1.5, 0.1)
	pcall(function()
		local keys = {}
		local count = 5
		local fill = 0.55
		local gap = 0.0004
		for i = 0, count - 1 do
			local a = i / count
			local b = a + fill / count
			local c = (i + 1) / count
			keys[#keys + 1] = NumberSequenceKeypoint.new(a, 0)
			keys[#keys + 1] = NumberSequenceKeypoint.new(b - gap, 0)
			keys[#keys + 1] = NumberSequenceKeypoint.new(b, 1)
			keys[#keys + 1] = NumberSequenceKeypoint.new(i == count - 1 and 1 or (c - gap), 1)
		end
		UI.new("UIGradient", { Rotation = 45, Transparency = NumberSequence.new(keys) }, stroke)
	end)
	return stroke
end

local function isLoaded(picture)
	local ok, loaded = pcall(function()
		return picture.IsLoaded
	end)
	return ok and loaded == true
end

local function dropConn(spot)
	if spot.conn then
		pcall(function()
			spot.conn:Disconnect()
		end)
		spot.conn = nil
	end
end

local function showHint(spot, state, iconName, text, color)
	local T = ctx.T
	spot.state = state
	spot.picture.Visible = false
	spot.picture.ImageTransparency = 1
	spot.hint.Visible = true
	spot.dash.Enabled = true
	spot.dash.Color = color or T.dim
	ctx.UI.setIcon(spot.icon, iconName)
	spot.icon.ImageColor3 = color or T.sub
	spot.label.Text = text
	spot.label.TextColor3 = color or T.sub
end

local function showPicture(spot, token)
	if spot.token ~= token then
		return
	end
	spot.hint.Visible = false
	spot.dash.Enabled = false
	spot.picture.Visible = true
	spot.state = "set"
	ctx.UI.tween(spot.picture, Art.FADE, { ImageTransparency = 0 })
end

local function renderSpot(view, spot)
	local T = ctx.T
	spot.token = spot.token + 1
	local token = spot.token
	dropConn(spot)
	local path = view.path
	local item = path and Art.get(path, spot.kind) or nil
	spot.isDefault = false
	if not item and spot.kind == "logo" and view.defaultLogo then
		item = { src = "asset", value = view.defaultLogo }
		spot.isDefault = true
	end
	spot.item = item
	if not item then
		showHint(spot, "empty", "plus", spot.addText)
		return
	end
	local id, why = Art.imageFor(item)
	if not id then
		local key = path .. "|" .. spot.kind
		if why == "missing" and restoring[key] then
			showHint(spot, "restoring", "rotate-ccw", "Restoring...")
			return
		end
		if why == "missing" and not brokenWhy[key] and Art.restore(path, spot.kind) then
			if spot.token == token then
				showHint(spot, "restoring", "rotate-ccw", "Restoring...")
			end
			return
		end
		showHint(spot, "broken", "triangle-alert", spot.kind == "logo" and "Tap to fix" or "Couldn't load this picture. Tap to fix", T.yellow)
		return
	end
	spot.picture.Image = id
	spot.picture.ImageTransparency = 1
	spot.picture.Visible = true
	spot.hint.Visible = false
	spot.dash.Enabled = false
	spot.state = "loading"
	if isLoaded(spot.picture) then
		showPicture(spot, token)
		return
	end
	pcall(function()
		spot.conn = spot.picture:GetPropertyChangedSignal("IsLoaded"):Connect(function()
			if spot.token == token and isLoaded(spot.picture) then
				showPicture(spot, token)
			end
		end)
	end)
	deps.delay(Art.SHOW_WAIT, function()
		if spot.token == token and spot.state == "loading" then
			spot.picture.ImageTransparency = 0
		end
	end)
	deps.delay(Art.BROKEN_WAIT, function()
		if spot.token == token and spot.state == "loading" and not isLoaded(spot.picture) then
			showHint(spot, "broken", "triangle-alert", spot.kind == "logo" and "Tap to fix" or "Couldn't load this picture. Tap to fix", T.yellow)
		end
	end)
end

local function closeMenu(view)
	local menu = view.menu
	view.menu = nil
	if menu then
		pcall(function()
			menu.catcher:Destroy()
		end)
		pcall(function()
			menu.frame:Destroy()
		end)
	end
end

local function openMenu(view, spot)
	local UI, T, L = ctx.UI, ctx.T, ctx.L
	closeMenu(view)
	local path, kind = view.path, spot.kind
	local rows = {}
	if spot.state == "broken" and not spot.isDefault then
		rows[#rows + 1] = {
			"rotate-ccw",
			"Try again",
			function()
				Art.retry(path, kind)
			end,
		}
	end
	rows[#rows + 1] = {
		"pencil",
		"Change",
		function()
			Art.openPicker(path, kind, view.entry and view.entry.name)
		end,
	}
	if not spot.isDefault then
		rows[#rows + 1] = {
			"trash-2",
			"Remove",
			function()
				if Art.clear(path, kind) then
					toast(Art.cap(kind), "Removed", "info", 1.5)
				end
			end,
			T.red,
		}
	end
	local overlay = view.overlay
	local catcher = UI.button(overlay, { Name = "ArtMenuCatcher", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 60 })
	local height = #rows * 34 + 8
	local frame = UI.new("Frame", { Name = "ArtMenu", BackgroundColor3 = T.card2, Size = UDim2.fromOffset(150, height), ZIndex = 61 }, overlay)
	UI.corner(frame, 12)
	UI.stroke(frame, T.stroke, 1, 0.3)
	local scale = math.max(0.01, L.scale or 1)
	local at = spot.btn.AbsolutePosition or { X = 0, Y = 0 }
	local base = overlay.AbsolutePosition or { X = 0, Y = 0 }
	local size = spot.btn.AbsoluteSize or { X = 0, Y = 0 }
	local room = overlay.AbsoluteSize or { X = 0, Y = 0 }
	local x = (at.X - base.X) / scale + 6
	local y = (at.Y - base.Y) / scale + size.Y / scale - 4
	if room.X > 0 then
		x = math.min(x, room.X / scale - 154)
	end
	x = math.max(4, x)
	if room.Y > 0 and y + height > room.Y / scale - 4 then
		y = (at.Y - base.Y) / scale - height + 4
	end
	y = math.max(4, y)
	frame.Position = UDim2.fromOffset(x, y)
	for i, row in ipairs(rows) do
		local button = UI.button(frame, {
			Name = "Row" .. i,
			BackgroundColor3 = T.card,
			BackgroundTransparency = 1,
			Size = UDim2.new(1, -8, 0, 34),
			Position = UDim2.fromOffset(4, 4 + (i - 1) * 34),
			ZIndex = 62,
		})
		UI.corner(button, 8)
		UI.icon(row[1], 14, row[4] or T.sub, button, { Position = UDim2.fromOffset(10, 10), ZIndex = 63 })
		UI.label(button, { Text = row[2], TextSize = 12, TextColor3 = row[4] or T.text, Position = UDim2.fromOffset(32, 0), Size = UDim2.new(1, -40, 1, 0), ZIndex = 63 })
		button.Activated:Connect(function()
			closeMenu(view)
			row[3]()
		end)
	end
	catcher.Activated:Connect(function()
		closeMenu(view)
	end)
	view.menu = { catcher = catcher, frame = frame, kind = kind }
	if spot.state == "broken" then
		local why = Art.brokenReason(path, kind)
		if why and why ~= "" then
			toast("Picture", why, "warn", 4)
		end
	end
end

local function tapSpot(view, spot)
	if not view.path then
		return
	end
	closeMenu(view)
	if spot.state == "empty" then
		Art.openPicker(view.path, spot.kind, view.entry and view.entry.name)
		return
	end
	openMenu(view, spot)
end

local function makeSpot(view, kind)
	local UI, T = ctx.UI, ctx.T
	local isLogo = kind == "logo"
	local radius = isLogo and 16 or 14
	local z = isLogo and 4 or 2
	local spot = { kind = kind, token = 0, state = "empty", addText = isLogo and "Add logo" or "Add banner" }
	spot.btn = UI.button(view.cover, {
		Name = isLogo and "LogoSpot" or "BannerSpot",
		BackgroundColor3 = isLogo and T.card or T.card2,
		BackgroundTransparency = isLogo and 0 or 0.3,
		ZIndex = z,
		Position = UDim2.fromOffset(Art.PAD, Art.PAD),
		Size = isLogo and UDim2.fromOffset(Art.LOGO, Art.LOGO) or UDim2.new(1, -Art.PAD * 2, 0, 90),
	})
	UI.corner(spot.btn, radius)
	spot.ring = UI.stroke(spot.btn, isLogo and T.card or T.text, isLogo and 3 or 1, isLogo and 0 or 0.9)
	spot.dash = dashedOutline(spot.btn)
	spot.picture = UI.new("ImageLabel", {
		Name = "Picture",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		ScaleType = Enum.ScaleType.Crop,
		Image = "",
		ImageTransparency = 1,
		Visible = false,
		ZIndex = z + 1,
	}, spot.btn)
	UI.corner(spot.picture, radius)
	spot.hint = UI.new("Frame", { Name = "Hint", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = z + 1 }, spot.btn)
	spot.icon = UI.icon("plus", isLogo and 16 or 20, T.sub, spot.hint, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, isLogo and -9 or -11),
		ZIndex = z + 2,
	})
	spot.label = UI.label(spot.hint, {
		Name = "Words",
		Text = spot.addText,
		TextSize = isLogo and 10 or 11,
		TextColor3 = T.sub,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextYAlignment = Enum.TextYAlignment.Top,
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0.5, isLogo and 3 or 5),
		Size = UDim2.new(1, -8, 0, isLogo and 26 or 16),
		ZIndex = z + 2,
	})
	UI.pressable(spot.btn, 0.97)
	spot.btn.Activated:Connect(function()
		tapSpot(view, spot)
	end)
	return spot
end

local function layoutView(view)
	local L = ctx.L
	local width = (view.cover.AbsoluteSize and view.cover.AbsoluteSize.X or 0) / math.max(0.01, L.scale or 1)
	if width < 60 then
		width = view.lastWidth or 320
	end
	if view.metrics and view.lastWidth == width then
		return view.metrics
	end
	view.lastWidth = width
	local m = Art.metrics(width)
	view.metrics = m
	view.cover.Size = UDim2.new(1, 0, 0, m.height)
	local banner, logo = view.spots.banner, view.spots.logo
	banner.btn.Position = UDim2.fromOffset(m.pad, m.pad)
	banner.btn.Size = UDim2.new(1, -m.pad * 2, 0, m.bannerH)
	logo.btn.Position = UDim2.fromOffset(m.logoX, m.logoY)
	logo.btn.Size = UDim2.fromOffset(m.logo, m.logo)
	local parts = view.parts
	if parts.name then
		parts.name.Position = UDim2.fromOffset(m.textX, m.nameY)
		parts.name.Size = UDim2.new(1, -(m.textX + 52), 0, 22)
	end
	if parts.sub then
		parts.sub.Position = UDim2.fromOffset(m.textX, m.subY)
		parts.sub.Size = UDim2.new(1, -(m.textX + 52), 0, 16)
	end
	if parts.heart then
		parts.heart.Position = UDim2.new(1, -48, 0, m.heartY)
	end
	if parts.chip then
		parts.chip.Position = UDim2.fromOffset(m.chipX, m.chipY)
	end
	return m
end

function Art.attach(parts)
	local view = { cover = parts.cover, overlay = parts.overlay or parts.cover, parts = parts, alive = true, conns = {}, spots = {} }
	view.spots.banner = makeSpot(view, "banner")
	view.spots.logo = makeSpot(view, "logo")
	if parts.chip then
		parts.chip.ZIndex = 6
	end
	local function renderBoth()
		renderSpot(view, view.spots.banner)
		renderSpot(view, view.spots.logo)
	end
	local function onChange(path, kind)
		if not view.alive or path ~= view.path then
			return
		end
		local spot = view.spots[kind]
		if spot then
			closeMenu(view)
			renderSpot(view, spot)
		end
	end
	ctx.Bus.on("scriptart", onChange)
	pcall(function()
		view.conns[#view.conns + 1] = view.cover:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
			if view.alive then
				layoutView(view)
			end
		end)
	end)
	function view.show(entry)
		view.entry = entry
		view.path = entry and entry.path or nil
		view.defaultLogo = nil
		closeMenu(view)
		layoutView(view)
		renderBoth()
	end
	function view.setIcon(icon)
		local spec = type(icon) == "string" and Art.parseLink(icon) or nil
		local want = spec and spec.src == "asset" and spec.value or nil
		if want ~= view.defaultLogo then
			view.defaultLogo = want
			if not Art.get(view.path or "", "logo") then
				renderSpot(view, view.spots.logo)
			end
		end
	end
	function view.layout()
		return layoutView(view)
	end
	function view.close()
		closeMenu(view)
	end
	function view.destroy()
		if not view.alive then
			return
		end
		view.alive = false
		closeMenu(view)
		pcall(ctx.Bus.off, "scriptart", onChange)
		for _, conn in ipairs(view.conns) do
			pcall(function()
				conn:Disconnect()
			end)
		end
		for _, spot in pairs(view.spots) do
			spot.token = spot.token + 1
			dropConn(spot)
			pcall(function()
				spot.btn:Destroy()
			end)
		end
	end
	layoutView(view)
	renderBoth()
	views[#views + 1] = view
	return view
end

return Art
