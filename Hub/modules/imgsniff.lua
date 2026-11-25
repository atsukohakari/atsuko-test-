local Sniff = {}

Sniff.FORMATS = {
	{ format = "png", mime = "image/png", ext = "png", label = "PNG" },
	{ format = "jpeg", mime = "image/jpeg", ext = "jpg", label = "JPEG" },
	{ format = "gif", mime = "image/gif", ext = "gif", label = "GIF" },
	{ format = "bmp", mime = "image/bmp", ext = "bmp", label = "BMP" },
	{ format = "webp", mime = "image/webp", ext = "webp", label = "WebP" },
	{ format = "ico", mime = "image/x-icon", ext = "ico", label = "ICO" },
	{ format = "avif", mime = "image/avif", ext = "avif", label = "AVIF" },
	{ format = "heic", mime = "image/heic", ext = "heic", label = "HEIC" },
	{ format = "svg", mime = "image/svg+xml", ext = "svg", label = "SVG" },
	{ format = "tga", mime = "image/x-tga", ext = "tga", label = "TGA" },
}

local BY_FORMAT = {}
for _, f in ipairs(Sniff.FORMATS) do
	BY_FORMAT[f.format] = f
end

local EXT_FORMAT = {
	png = "png",
	jpg = "jpeg",
	jpeg = "jpeg",
	jpe = "jpeg",
	jfif = "jpeg",
	gif = "gif",
	bmp = "bmp",
	dib = "bmp",
	webp = "webp",
	ico = "ico",
	avif = "avif",
	heic = "heic",
	heif = "heic",
	svg = "svg",
	tga = "tga",
}

local PNG_SIGNATURE = "\137PNG\r\n\26\n"
local JPEG_SIGNATURE = "\255\216\255"
local VALID_DIB = { [12] = true, [40] = true, [52] = true, [56] = true, [64] = true, [108] = true, [124] = true }
local SOF_MARKERS = { [192] = true, [193] = true, [194] = true, [195] = true, [197] = true, [198] = true, [199] = true, [201] = true, [202] = true, [203] = true, [205] = true, [206] = true, [207] = true }
local TGA_TYPES = { [1] = true, [2] = true, [3] = true, [9] = true, [10] = true, [11] = true }
local TGA_DEPTHS = { [8] = true, [15] = true, [16] = true, [24] = true, [32] = true }
local ICO_BITS = { [0] = true, [1] = true, [2] = true, [4] = true, [8] = true, [15] = true, [16] = true, [24] = true, [32] = true }
local AVIF_BRANDS = { "avif", "avis" }
local HEIC_BRANDS = { "heic", "heix", "hevc", "hevx", "heim", "heis", "hevm", "hevs", "mif1", "msf1" }

local function byte(s, i)
	return string.byte(s, i) or 0
end

local function le16(s, i)
	return byte(s, i) + byte(s, i + 1) * 256
end

local function be16(s, i)
	return byte(s, i) * 256 + byte(s, i + 1)
end

local function le32(s, i)
	return byte(s, i) + byte(s, i + 1) * 256 + byte(s, i + 2) * 65536 + byte(s, i + 3) * 16777216
end

local function be32(s, i)
	return byte(s, i) * 16777216 + byte(s, i + 1) * 65536 + byte(s, i + 2) * 256 + byte(s, i + 3)
end

local function signed32(n)
	if n >= 2147483648 then
		return n - 4294967296
	end
	return n
end

local function make(format)
	local base = BY_FORMAT[format]
	return { format = format, mime = base.mime, ext = base.ext, label = base.label, truncated = false }
end

local function setSize(info, width, height)
	if width and height and width > 0 and height > 0 then
		info.width = width
		info.height = height
	end
end

local function hasAny(text, list)
	for _, item in ipairs(list) do
		if string.find(text, item, 1, true) then
			return true
		end
	end
	return false
end

local function png(s)
	if string.sub(s, 1, 8) ~= PNG_SIGNATURE then
		return nil
	end
	local info = make("png")
	if #s >= 24 and string.sub(s, 13, 16) == "IHDR" then
		setSize(info, be32(s, 17), be32(s, 21))
	end
	local tail = string.sub(s, math.max(1, #s - 15))
	info.truncated = string.find(tail, "IEND", 1, true) == nil
	return info
end

local function jpeg(s)
	if string.sub(s, 1, 3) ~= JPEG_SIGNATURE then
		return nil
	end
	local info = make("jpeg")
	local n = #s
	local p = 3
	local scan = nil
	while p + 1 <= n do
		if byte(s, p) ~= 255 then
			break
		end
		while p + 1 <= n and byte(s, p + 1) == 255 do
			p = p + 1
		end
		local marker = byte(s, p + 1)
		if marker == 216 or marker == 1 or (marker >= 208 and marker <= 215) then
			p = p + 2
		elseif marker == 217 then
			break
		elseif marker == 218 then
			scan = p
			break
		else
			if p + 3 > n then
				break
			end
			local length = be16(s, p + 2)
			if SOF_MARKERS[marker] and p + 8 <= n then
				setSize(info, be16(s, p + 7), be16(s, p + 5))
			end
			if length < 2 then
				break
			end
			p = p + 2 + length
		end
	end
	if scan then
		info.truncated = string.find(s, "\255\217", scan, true) == nil
	else
		info.truncated = true
	end
	return info
end

local function gif(s)
	local head = string.sub(s, 1, 6)
	if head ~= "GIF87a" and head ~= "GIF89a" then
		return nil
	end
	local info = make("gif")
	if #s >= 10 then
		setSize(info, le16(s, 7), le16(s, 9))
	end
	local tail = string.sub(s, math.max(1, #s - 1))
	info.truncated = string.find(tail, ";", 1, true) == nil
	return info
end

local function bmp(s)
	if #s < 26 or string.sub(s, 1, 2) ~= "BM" then
		return nil
	end
	local dib = le32(s, 15)
	if not VALID_DIB[dib] or le32(s, 11) < 14 + dib then
		return nil
	end
	local info = make("bmp")
	if dib == 12 then
		setSize(info, le16(s, 19), le16(s, 21))
	else
		setSize(info, math.abs(signed32(le32(s, 19))), math.abs(signed32(le32(s, 23))))
	end
	local declared = le32(s, 3)
	info.truncated = declared > #s
	return info
end

local function webp(s)
	if #s < 12 or string.sub(s, 1, 4) ~= "RIFF" or string.sub(s, 9, 12) ~= "WEBP" then
		return nil
	end
	local info = make("webp")
	local chunk = string.sub(s, 13, 16)
	if chunk == "VP8X" and #s >= 30 then
		local w = byte(s, 25) + byte(s, 26) * 256 + byte(s, 27) * 65536 + 1
		local h = byte(s, 28) + byte(s, 29) * 256 + byte(s, 30) * 65536 + 1
		setSize(info, w, h)
	elseif chunk == "VP8L" and #s >= 25 and byte(s, 21) == 47 then
		local b1, b2, b3, b4 = byte(s, 22), byte(s, 23), byte(s, 24), byte(s, 25)
		setSize(info, 1 + b1 + (b2 % 64) * 256, 1 + (b2 // 64) + b3 * 4 + (b4 % 16) * 1024)
	elseif chunk == "VP8 " and #s >= 30 and string.sub(s, 24, 26) == "\157\1\42" then
		setSize(info, le16(s, 27) % 16384, le16(s, 29) % 16384)
	end
	info.truncated = le32(s, 5) + 8 > #s
	return info
end

local function ico(s)
	if #s < 22 or string.sub(s, 1, 4) ~= "\0\0\1\0" then
		return nil
	end
	local count = le16(s, 5)
	if count < 1 or count > 255 then
		return nil
	end
	local firstPlanes, firstBits = le16(s, 11), le16(s, 13)
	if (firstPlanes ~= 0 and firstPlanes ~= 1) or not ICO_BITS[firstBits] or byte(s, 10) ~= 0 then
		return nil
	end
	if le32(s, 19) < 6 + 16 * count then
		return nil
	end
	local info = make("ico")
	local bestArea = 0
	local last = 0
	for i = 0, count - 1 do
		local at = 7 + 16 * i
		if at + 15 > #s then
			info.truncated = true
			break
		end
		local w = byte(s, at)
		local h = byte(s, at + 1)
		if w == 0 then
			w = 256
		end
		if h == 0 then
			h = 256
		end
		if w * h > bestArea then
			bestArea = w * h
			setSize(info, w, h)
		end
		local finish = le32(s, at + 12) + le32(s, at + 8)
		if finish > last then
			last = finish
		end
	end
	if last > #s then
		info.truncated = true
	end
	return info
end

local function isobmff(s)
	if #s < 12 or string.sub(s, 5, 8) ~= "ftyp" then
		return nil
	end
	local brand = string.sub(s, 9, 12)
	local boxSize = be32(s, 1)
	local brands = brand .. string.sub(s, 17, math.max(16, math.min(boxSize, #s)))
	local format = nil
	if hasAny(brands, AVIF_BRANDS) then
		format = "avif"
	elseif hasAny(brands, HEIC_BRANDS) then
		format = "heic"
	end
	if not format then
		return nil
	end
	local info = make(format)
	local limit = math.min(#s, 65536)
	local head = string.sub(s, 1, limit)
	local from = 1
	local best = 0
	for _ = 1, 8 do
		local at = string.find(head, "ispe", from, true)
		if not at or at + 15 > limit then
			break
		end
		local w, h = be32(s, at + 8), be32(s, at + 12)
		if w > 0 and h > 0 and w <= 65535 and h <= 65535 and w * h > best then
			best = w * h
			setSize(info, w, h)
		end
		from = at + 4
	end
	local pos = 1
	local cut = false
	local sawMeta, sawData = false, false
	for _ = 1, 64 do
		if pos > #s then
			break
		end
		if pos + 7 > #s then
			cut = true
			break
		end
		local size = be32(s, pos)
		local kind = string.sub(s, pos + 4, pos + 7)
		if kind == "meta" then
			sawMeta = true
		elseif kind == "mdat" then
			sawData = true
		end
		if size < 8 then
			break
		end
		if pos + size - 1 > #s then
			cut = true
			break
		end
		pos = pos + size
	end
	info.truncated = cut or not (sawMeta and sawData)
	return info
end

local function numberFrom(tag, name)
	local value = string.match(tag, "[%s\"']" .. name .. "%s*=%s*[\"']%s*([%d%.]+)")
	if value then
		local n = tonumber(value)
		if n and n > 0 then
			return math.floor(n + 0.5)
		end
	end
	return nil
end

local function svg(s)
	local head = string.sub(s, 1, 2048)
	if string.sub(head, 1, 3) == "\239\187\191" then
		head = string.sub(head, 4)
	end
	head = string.gsub(head, "^%s+", "")
	local lower = string.lower(head)
	local first = string.sub(lower, 1, 4)
	local ok = false
	if first == "<svg" then
		ok = true
	elseif string.sub(lower, 1, 5) == "<?xml" and string.find(lower, "<svg", 1, true) and not string.find(lower, "<html", 1, true) then
		ok = true
	elseif string.sub(lower, 1, 13) == "<!doctype svg" and string.find(lower, "<svg", 1, true) then
		ok = true
	end
	if not ok then
		return nil
	end
	local info = make("svg")
	local open = string.find(lower, "<svg", 1, true)
	local close = open and string.find(head, ">", open, true) or nil
	local tag = open and string.sub(head, open, close or #head) or ""
	local w, h = numberFrom(tag, "width"), numberFrom(tag, "height")
	if string.find(tag, "width%s*=%s*[\"'][%d%.]+%%") then
		w = nil
	end
	if string.find(tag, "height%s*=%s*[\"'][%d%.]+%%") then
		h = nil
	end
	if not (w and h) then
		local a, b, c, d = string.match(tag, "viewBox%s*=%s*[\"']%s*([%-%d%.]+)[%s,]+([%-%d%.]+)[%s,]+([%d%.]+)[%s,]+([%d%.]+)")
		if c and d then
			w = w or math.floor((tonumber(c) or 0) + 0.5)
			h = h or math.floor((tonumber(d) or 0) + 0.5)
		end
	end
	setSize(info, w, h)
	local tail = string.lower(string.sub(s, math.max(1, #s - 512)))
	local selfClosed = close and string.sub(head, close - 1, close) == "/>"
	info.truncated = not (string.find(tail, "</svg", 1, true) or selfClosed)
	return info
end

local function tga(s, name)
	if Sniff.extOf(name) ~= "tga" or #s < 18 then
		return nil
	end
	local idLength, mapType, kind = byte(s, 1), byte(s, 2), byte(s, 3)
	if mapType > 1 or not TGA_TYPES[kind] then
		return nil
	end
	if (kind == 1 or kind == 9) and mapType ~= 1 then
		return nil
	end
	local width, height, depth = le16(s, 13), le16(s, 15), byte(s, 17)
	if width == 0 or height == 0 or not TGA_DEPTHS[depth] then
		return nil
	end
	local info = make("tga")
	setSize(info, width, height)
	if kind == 1 or kind == 2 or kind == 3 then
		local mapBytes = 0
		if mapType == 1 then
			mapBytes = le16(s, 6) * math.ceil(byte(s, 8) / 8)
		end
		local need = 18 + idLength + mapBytes + width * height * math.ceil(depth / 8)
		info.truncated = #s < need
	end
	return info
end

function Sniff.extOf(name)
	if type(name) ~= "string" then
		return ""
	end
	local base = string.match(name, "([^/\\]+)$") or name
	return string.lower(string.match(base, "%.([%w]+)$") or "")
end

function Sniff.sniff(bytes, name)
	if type(bytes) ~= "string" then
		return nil, "there is nothing to look at"
	end
	if #bytes == 0 then
		return nil, "that file is empty"
	end
	local info = png(bytes) or jpeg(bytes) or gif(bytes) or webp(bytes) or bmp(bytes) or ico(bytes) or isobmff(bytes) or svg(bytes) or tga(bytes, name)
	if info then
		info.size = #bytes
		return info
	end
	return nil, Sniff.reasonFor(bytes)
end

function Sniff.reasonFor(bytes)
	if type(bytes) ~= "string" or #bytes == 0 then
		return "that file is empty"
	end
	local head = string.sub(bytes, 1, 512)
	local lower = string.lower(head)
	if string.find(lower, "<!doctype html", 1, true) or string.find(lower, "<html", 1, true) or string.find(lower, "<head", 1, true) or string.find(lower, "<body", 1, true) then
		return "that link gave a web page, not a picture (the link may have expired)"
	end
	if string.sub(head, 1, 4) == "PK\3\4" then
		return "that is a zip archive, not a picture"
	end
	if string.sub(head, 1, 4) == "%PDF" then
		return "that is a PDF, not a picture"
	end
	if string.sub(head, 1, 4) == "OggS" or string.sub(head, 1, 3) == "ID3" or string.sub(head, 1, 4) == "fLaC" or (string.sub(head, 1, 4) == "RIFF" and string.sub(head, 9, 12) == "WAVE") then
		return "that is a sound, not a picture"
	end
	if string.sub(head, 5, 8) == "ftyp" or string.sub(head, 1, 4) == "\26E\223\163" then
		return "that is a video, not a picture"
	end
	local text = string.gsub(head, "^\239\187\191", "")
	local firstChar = string.match(text, "^%s*(.)")
	if firstChar == "{" or firstChar == "[" then
		return "that link gave a message, not a picture"
	end
	if Sniff.looksLikeText(head) then
		return "that is a text file, not a picture"
	end
	return "I don't recognise that picture format"
end

function Sniff.looksLikeText(head)
	for i = 1, math.min(#head, 256) do
		local b = byte(head, i)
		if b < 9 or (b > 13 and b < 32) or b == 127 then
			return false
		end
	end
	return true
end

function Sniff.describe(info)
	if type(info) ~= "table" then
		return ""
	end
	local text = info.label or string.upper(tostring(info.format))
	if info.width and info.height then
		text = text .. "  ·  " .. info.width .. " x " .. info.height
	end
	if info.truncated then
		text = text .. "  ·  cut short"
	end
	return text
end

function Sniff.nameFormat(name)
	return EXT_FORMAT[Sniff.extOf(name)]
end

function Sniff.mismatch(name, info)
	if type(info) ~= "table" then
		return false
	end
	local said = Sniff.nameFormat(name)
	if not said then
		return false
	end
	return said ~= info.format, said
end

function Sniff.formatInfo(format)
	return BY_FORMAT[format]
end

return Sniff
