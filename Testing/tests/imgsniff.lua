local Sniff = loadmodule("Hub/modules/imgsniff.lua")
local F = loadmodule("Testing/mocks/image_fixtures.lua")

local function fromhex(h)
	local out = {}
	for i = 1, #h, 2 do
		out[#out + 1] = string.char(tonumber(string.sub(h, i, i + 1), 16))
	end
	return table.concat(out)
end

local function names(map)
	local list = {}
	for name in pairs(map) do
		list[#list + 1] = name
	end
	table.sort(list)
	return list
end

local MIME = {
	png = "image/png", jpeg = "image/jpeg", gif = "image/gif", bmp = "image/bmp", webp = "image/webp",
	ico = "image/x-icon", avif = "image/avif", heic = "image/heic", svg = "image/svg+xml", tga = "image/x-tga",
}
local EXT = { png = "png", jpeg = "jpg", gif = "gif", bmp = "bmp", webp = "webp", ico = "ico", avif = "avif", heic = "heic", svg = "svg", tga = "tga" }

local function fileNameFor(item)
	if item.format == "tga" then
		return "picture.tga"
	end
	return "picture.bin"
end

T.section("imgsniff: the formats it knows")
T.eq(#Sniff.FORMATS, 10)
for _, f in ipairs(Sniff.FORMATS) do
	T.eq(f.mime, MIME[f.format], f.format .. " mime")
	T.eq(f.ext, EXT[f.format], f.format .. " extension")
	T.eq(Sniff.formatInfo(f.format), f)
end
T.eq(Sniff.formatInfo("nope"), nil)

T.section("imgsniff: every real sample picture is recognised with its true size")
local count = 0
for _, name in ipairs(names(F.valid)) do
	local item = F.valid[name]
	local bytes = fromhex(item.hex)
	local info, why = Sniff.sniff(bytes, fileNameFor(item))
	T.ok(info ~= nil, name .. " is recognised: " .. tostring(why))
	if info then
		count = count + 1
		T.eq(info.format, item.format, name .. " format")
		T.eq(info.width, item.width, name .. " width")
		T.eq(info.height, item.height, name .. " height")
		T.eq(info.mime, MIME[item.format], name .. " mime")
		T.eq(info.ext, EXT[item.format], name .. " extension")
		T.eq(info.truncated, false, name .. " is whole")
		T.eq(info.size, #bytes, name .. " size")
	end
end
T.ok(count >= 36, "all " .. count .. " samples were checked")

T.section("imgsniff: the name never decides (scrambled, wrong or missing endings)")
do
	local png = fromhex(F.valid.png_rgb_3x2.hex)
	for _, name in ipairs({ "photo.jpg", "kxjqzpw", "kxjqzpw.png", "thing.webp", "", "a.b.c.d", "UPPER.JPG", "x.txt", "dir/file.bmp" }) do
		local info = Sniff.sniff(png, name)
		T.eq(info and info.format, "png", "a PNG called '" .. name .. "' is still a PNG")
		T.eq(info and info.width, 3)
	end
	local jpeg = fromhex(F.valid.jpeg_baseline_8x8.hex)
	T.eq(Sniff.sniff(jpeg, "me.png").format, "jpeg", "a JPEG saved as .png")
	local webp = fromhex(F.valid.webp_lossless_8x8.hex)
	T.eq(Sniff.sniff(webp, "me.jpg").format, "webp", "a WebP saved as .jpg")
	T.eq(Sniff.sniff(png).format, "png", "no name at all")
	T.eq(Sniff.sniff(png, nil).format, "png")
	T.eq(Sniff.sniff(png, 42).format, "png", "a name that is not text")
end

T.section("imgsniff: a TGA has no magic, so it needs a .tga name")
do
	local raw = fromhex(F.valid.tga_raw_4x3.hex)
	local rle = fromhex(F.valid.tga_rle_4x3.hex)
	T.eq(Sniff.sniff(raw, "pic.TGA").format, "tga", "capital letters in the ending are fine")
	T.eq(Sniff.sniff(rle, "pic.tga").format, "tga")
	T.eq(Sniff.sniff(raw, "pic.png"), nil, "the same bytes called .png are not taken for a TGA")
	T.eq(Sniff.sniff(raw), nil, "and with no name neither")
	T.eq(Sniff.sniff(raw, "kxjqzpw"), nil)
	local ok, why = Sniff.sniff(raw, "kxjqzpw")
	T.eq(ok, nil)
	T.ok(type(why) == "string" and #why > 0, "a reason is given")
	T.eq(Sniff.sniff(string.sub(raw, 1, 17), "pic.tga"), nil, "a header that is too short")
	local bad = string.sub(raw, 1, 2) .. "\7" .. string.sub(raw, 4)
	T.eq(Sniff.sniff(bad, "pic.tga"), nil, "an image type that does not exist")
	local zeroW = string.sub(raw, 1, 12) .. "\0\0" .. string.sub(raw, 15)
	T.eq(Sniff.sniff(zeroW, "pic.tga"), nil, "a width of zero")
	local depth = string.sub(raw, 1, 16) .. "\7" .. string.sub(raw, 18)
	T.eq(Sniff.sniff(depth, "pic.tga"), nil, "a pixel depth that does not exist")
	local cut = Sniff.sniff(string.sub(raw, 1, 30), "pic.tga")
	T.eq(cut and cut.truncated, true, "raw pixel data cut short is noticed")
	T.eq(cut and cut.width, 4)
end

T.section("imgsniff: mismatched names are noticed")
do
	local png = Sniff.sniff(fromhex(F.valid.png_rgb_3x2.hex))
	local jpg = Sniff.sniff(fromhex(F.valid.jpeg_baseline_8x8.hex))
	local a, said = Sniff.mismatch("photo.jpg", png)
	T.eq(a, true)
	T.eq(said, "jpeg")
	T.eq(Sniff.mismatch("photo.png", png), false)
	T.eq(Sniff.mismatch("photo.PNG", png), false)
	T.eq(Sniff.mismatch("photo.jpeg", jpg), false, "jpeg and jpg are the same")
	T.eq(Sniff.mismatch("photo.jfif", jpg), false)
	T.eq(Sniff.mismatch("photo.jpe", jpg), false)
	T.eq(Sniff.mismatch("kxjqzpw", png), false, "no ending says nothing")
	T.eq(Sniff.mismatch("notes.txt", png), false, "an ending that is not a picture says nothing")
	T.eq(Sniff.mismatch("pic.heif", Sniff.sniff(fromhex(F.valid.heic_like_64x48.hex))), false, "heif is heic")
	T.eq(Sniff.mismatch("pic.png", nil), false)
	T.eq(Sniff.nameFormat("a.JPG"), "jpeg")
	T.eq(Sniff.nameFormat("a.zip"), nil)
	T.eq(Sniff.nameFormat(nil), nil)
end

T.section("imgsniff: the ending of a name")
T.eq(Sniff.extOf("a.png"), "png")
T.eq(Sniff.extOf("A.PnG"), "png")
T.eq(Sniff.extOf("dir.v2/file"), "")
T.eq(Sniff.extOf("dir.v2/file.jpg"), "jpg")
T.eq(Sniff.extOf("C:\\pics\\a.BMP"), "bmp")
T.eq(Sniff.extOf("noending"), "")
T.eq(Sniff.extOf(".hidden"), "hidden")
T.eq(Sniff.extOf("a."), "")
T.eq(Sniff.extOf(""), "")
T.eq(Sniff.extOf(nil), "")
T.eq(Sniff.extOf(7), "")

T.section("imgsniff: files cut short")
do
	local png = fromhex(F.valid.png_wide_300x100.hex)
	local whole = Sniff.sniff(png)
	T.eq(whole.truncated, false)
	local cut40 = Sniff.sniff(string.sub(png, 1, 40))
	T.eq(cut40.format, "png")
	T.eq(cut40.truncated, true)
	T.eq(cut40.width, 300, "the size is still known when the header arrived")
	T.eq(cut40.height, 100)
	local cut10 = Sniff.sniff(string.sub(png, 1, 10))
	T.eq(cut10.format, "png")
	T.eq(cut10.truncated, true)
	T.eq(cut10.width, nil, "and unknown when it did not")
	local cut8 = Sniff.sniff(string.sub(png, 1, 8))
	T.eq(cut8.format, "png")
	T.eq(cut8.truncated, true)
	T.eq(Sniff.sniff(string.sub(png, 1, 7)), nil, "seven bytes is not enough to be sure")
	T.eq(Sniff.sniff(string.sub(png, 1, #png - 12)).truncated, true, "the end chunk is missing")
	local jpg = fromhex(F.valid.jpeg_progressive_16x16.hex)
	T.eq(Sniff.sniff(jpg).truncated, false)
	local j3 = Sniff.sniff("\255\216\255")
	T.eq(j3.format, "jpeg")
	T.eq(j3.truncated, true)
	T.eq(j3.width, nil)
	local jmid = Sniff.sniff(string.sub(jpg, 1, #jpg - 20))
	T.eq(jmid.truncated, true)
	T.eq(jmid.width, 16, "a JPEG cut in the middle of the picture still tells its size")
	T.eq(Sniff.sniff(string.sub(fromhex(F.valid.gif_static_5x4.hex), 1, 30)).truncated, true)
	T.eq(Sniff.sniff(string.sub(fromhex(F.valid.bmp_24_3x2.hex), 1, 40)).truncated, true)
	T.eq(Sniff.sniff(string.sub(fromhex(F.valid.bmp_24_3x2.hex), 1, 40)).width, 3)
	T.eq(Sniff.sniff(string.sub(fromhex(F.valid.webp_lossless_100x37.hex), 1, 30)).truncated, true)
	T.eq(Sniff.sniff(string.sub(fromhex(F.valid.webp_lossless_100x37.hex), 1, 30)).width, 100)
	T.eq(Sniff.sniff(string.sub(fromhex(F.valid.ico_48.hex), 1, 60)).truncated, true)
	T.eq(Sniff.sniff(string.sub(fromhex(F.valid.avif_8x8.hex), 1, 40)).truncated, true)
	T.eq(Sniff.sniff(string.sub(fromhex(F.valid.svg_wh.hex), 1, 70)).truncated, true)
end

T.section("imgsniff: cutting every sample at every length never fails and always says cut short")
do
	local checked, noticed = 0, 0
	for _, name in ipairs(names(F.valid)) do
		local item = F.valid[name]
		local bytes = fromhex(item.hex)
		local exempt = name == "tga_rle_4x3" or name == "svg_selfclosed"
		for len = 0, #bytes - 1 do
			local piece = string.sub(bytes, 1, len)
			local ok, info = pcall(Sniff.sniff, piece, fileNameFor(item))
			T.ok(ok, name .. " cut at " .. len .. " did not fail: " .. tostring(info))
			checked = checked + 1
			local margin = item.format == "tga" and 27 or 8
			if ok and info and len <= #bytes - margin and not exempt then
				noticed = noticed + 1
				if info.truncated ~= true then
					T.eq(info.truncated, true, name .. " cut at " .. len .. " of " .. #bytes .. " should be cut short")
				end
			end
		end
	end
	T.ok(checked > 8000, "many cuts were tried: " .. checked)
	T.ok(noticed > 2000, "and many were recognised and noticed: " .. noticed)
end

T.section("imgsniff: files that are not pictures")
do
	local want = {
		html_page = "web page",
		html_lower = "web page",
		json_error = "message",
		json_list = "message",
		empty = "empty",
		text = "text file",
		lua_source = "text file",
		zip = "zip",
		pdf = "PDF",
		ogg = "sound",
		mp3 = "sound",
		wav = "sound",
		mp4 = "video",
		bm_text = "text file",
		cur = "recognise",
		png_with_prefix = "recognise",
		random = "recognise",
		zero_run = "recognise",
	}
	for _, name in ipairs(names(F.not_images)) do
		local bytes = fromhex(F.not_images[name])
		local info, why = Sniff.sniff(bytes, "x.png")
		T.eq(info, nil, name .. " is not a picture")
		T.ok(type(why) == "string", name .. " says why")
		T.ok(want[name] ~= nil, name .. " has an expectation")
		if want[name] then
			T.ok(string.find(why, want[name], 1, true) ~= nil, name .. " says '" .. want[name] .. "', not '" .. tostring(why) .. "'")
		end
	end
	local a, why = Sniff.sniff(nil)
	T.eq(a, nil)
	T.ok(type(why) == "string")
	T.eq(Sniff.sniff(12), nil)
	T.eq(Sniff.sniff({}), nil)
	T.eq(Sniff.sniff(""), nil)
	local _, emptyWhy = Sniff.sniff("")
	T.ok(string.find(emptyWhy, "empty", 1, true) ~= nil)
	T.eq(Sniff.reasonFor(nil), "that file is empty")
end

T.section("imgsniff: short or odd starts do not fool it")
do
	T.eq(Sniff.sniff("BM"), nil, "two letters")
	T.eq(Sniff.sniff("BM" .. string.rep("\0", 30)), nil, "BM then nothing sensible")
	T.eq(Sniff.sniff("GIF"), nil)
	T.eq(Sniff.sniff("GIF89a").format, "gif")
	T.eq(Sniff.sniff("GIF87a").truncated, true)
	T.eq(Sniff.sniff("RIFF"), nil)
	T.eq(Sniff.sniff("RIFF\0\0\0\0WEBP").format, "webp")
	T.eq(Sniff.sniff("RIFF\0\0\0\0WEBP").truncated, false, "a size of 0 is not a cut")
	T.eq(Sniff.sniff("RIFF\200\0\0\0WEBP").truncated, true)
	T.eq(Sniff.sniff("RIFF\0\0\0\0WAVE"), nil)
	T.eq(Sniff.sniff("\255\216"), nil, "two bytes of a JPEG is not enough")
	T.eq(Sniff.sniff("<svg").format, "svg")
	T.eq(Sniff.sniff("<svg").truncated, true)
	T.eq(Sniff.sniff("<?xml version='1.0'?><html><svg width='5' height='5'></svg></html>"), nil, "a web page with a drawing inside")
	T.eq(Sniff.sniff("<!DOCTYPE html><svg></svg>"), nil)
	T.eq(Sniff.sniff("\0\0\1\0"), nil)
	T.eq(Sniff.sniff("\0\0\1\0\1\0"), nil, "an icon header with no entry")
	local fake = "\0\0\1\0\5\0" .. string.rep("\1", 40)
	T.eq(Sniff.sniff(fake), nil, "an icon header that makes no sense")
	local mp4ish = "\0\0\0\24ftypisom\0\0\2\0isomiso2"
	T.eq(Sniff.sniff(mp4ish), nil, "an mp4 is not a picture")
	T.eq(Sniff.sniff("\0\0\0\12ftypavif").format, "avif")
	T.eq(Sniff.sniff("\0\0\0\12ftypheic").format, "heic")
	T.eq(Sniff.sniff("\0\0\0\12ftypmif1").format, "heic")
	T.eq(Sniff.sniff("\0\0\0\28ftypmif1\0\0\0\0mif1avifmiaf").format, "avif", "a compatible brand named avif wins")
end

T.section("imgsniff: every first byte and a pile of odd data never fails")
do
	local seed = 12345
	local function nextByte()
		seed = (seed * 1103515245 + 12345) % 2147483648
		return (seed // 65536) % 256
	end
	local tried = 0
	for first = 0, 255 do
		for _, tail in ipairs({ 0, 1, 4, 11, 12, 25, 40, 120 }) do
			local parts = { string.char(first) }
			for _ = 1, tail do
				parts[#parts + 1] = string.char(nextByte())
			end
			local data = table.concat(parts)
			local ok, info, why = pcall(Sniff.sniff, data, "x.tga")
			T.ok(ok, "first byte " .. first .. " with " .. tail .. " more did not fail: " .. tostring(info))
			if ok then
				T.ok(info ~= nil or type(why) == "string", "either a picture or a reason")
			end
			tried = tried + 1
		end
	end
	T.eq(tried, 2048)
	for _, prefix in ipairs({ "\137PNG\r\n\26\n", "\255\216\255", "GIF89a", "RIFF", "BM", "\0\0\1\0", "<svg", "\0\0\0\24ftypavif" }) do
		for len = 0, 80 do
			local parts = { prefix }
			for _ = 1, len do
				parts[#parts + 1] = string.char(nextByte())
			end
			local ok, err = pcall(Sniff.sniff, table.concat(parts), "a.tga")
			T.ok(ok, "prefix of " .. #prefix .. " bytes plus " .. len .. " noise did not fail: " .. tostring(err))
		end
	end
	local big = "\137PNG\r\n\26\n\0\0\0\13IHDR\0\0\4\0\0\0\4\0" .. string.rep("\0", 100000)
	local info = Sniff.sniff(big)
	T.eq(info.width, 1024)
	T.eq(info.height, 1024)
	T.eq(info.truncated, true)
	T.eq(info.size, #big)
end

T.section("imgsniff: JPEG details")
do
	local exif = fromhex(F.valid.jpeg_exif_10x6.hex)
	T.eq(Sniff.sniff(exif).width, 10, "the size comes after an EXIF block")
	T.eq(Sniff.sniff(exif).height, 6)
	local com = fromhex(F.valid.jpeg_comment_12x9.hex)
	T.eq(Sniff.sniff(com).width, 12, "and after a long comment")
	local gray = fromhex(F.valid.jpeg_gray_5x7.hex)
	T.eq(Sniff.sniff(gray).height, 7)
	local filler = "\255\216\255\255\255\255\224\0\2" .. string.sub(fromhex(F.valid.jpeg_baseline_8x8.hex), 3)
	T.eq(Sniff.sniff(filler).format, "jpeg", "padding bytes between markers")
	local noScan = "\255\216\255\224\0\2\255\217"
	T.eq(Sniff.sniff(noScan).truncated, true, "no picture data at all")
end

T.section("imgsniff: other details")
do
	local top = Sniff.sniff(fromhex(F.valid.bmp_topdown_3x2.hex))
	T.eq(top.height, 2, "a BMP stored upside down still has a positive height")
	local os2 = Sniff.sniff(fromhex(F.valid.bmp_os2_2x2.hex))
	T.eq(os2.width, 2, "the old OS/2 header")
	local anim = Sniff.sniff(fromhex(F.valid.webp_anim_8x8.hex))
	T.eq(anim.width, 8, "an animated WebP")
	local multi = Sniff.sniff(fromhex(F.valid.ico_16_32.hex))
	T.eq(multi.width, 32, "an icon with two sizes gives the larger one")
	T.eq(Sniff.sniff(fromhex(F.valid.ico_256.hex)).width, 256, "a width byte of 0 means 256")
	local heic = Sniff.sniff(fromhex(F.valid.heic_like_64x48.hex))
	T.eq(heic.width, 64, "the larger of two sizes in a HEIC")
	T.eq(heic.height, 48)
	T.eq(Sniff.sniff(fromhex(F.valid.svg_stroke_width.hex)).width, 30, "stroke-width is not the width")
	T.eq(Sniff.sniff(fromhex(F.valid.svg_percent.hex)).width, 50, "a percentage falls back to the view box")
	T.eq(Sniff.sniff(fromhex(F.valid.svg_units.hex)).height, 32)
	T.eq(Sniff.sniff(fromhex(F.valid.svg_selfclosed.hex)).truncated, false)
end

T.section("imgsniff: the line shown under a preview")
do
	T.eq(Sniff.describe(Sniff.sniff(fromhex(F.valid.png_rgb_3x2.hex))), "PNG  ·  3 x 2")
	T.eq(Sniff.describe(Sniff.sniff(fromhex(F.valid.webp_lossless_100x37.hex))), "WebP  ·  100 x 37")
	T.eq(Sniff.describe(Sniff.sniff(string.sub(fromhex(F.valid.png_wide_300x100.hex), 1, 40))), "PNG  ·  300 x 100  ·  cut short")
	T.eq(Sniff.describe(Sniff.sniff(string.sub(fromhex(F.valid.png_wide_300x100.hex), 1, 10))), "PNG  ·  cut short")
	T.eq(Sniff.describe(nil), "")
	T.eq(Sniff.describe({ format = "xyz" }), "XYZ")
end

T.section("imgsniff: a text check")
T.eq(Sniff.looksLikeText("hello\nworld\t!"), true)
T.eq(Sniff.looksLikeText("caf\195\169"), true, "accents are text")
T.eq(Sniff.looksLikeText("a\0b"), false)
T.eq(Sniff.looksLikeText("a\1b"), false)
T.eq(Sniff.looksLikeText(""), true)

T.section("imgsniff: the module has no Roblox in it")
do
	local src = readsource("Hub/modules/imgsniff.lua")
	for _, word in ipairs({ "game", "Instance", "HttpService", "Enum", "UDim", "task", "getgenv", "AtsukoHub", "workspace" }) do
		T.eq(string.find(src, "%f[%w_]" .. word .. "%f[^%w_]"), nil, "no " .. word)
	end
end
