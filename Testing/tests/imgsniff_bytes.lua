local Sniff = loadmodule("Hub/modules/imgsniff.lua")

local function u16(n)
	return string.char(n % 256, (n // 256) % 256)
end

local function u24(n)
	return string.char(n % 256, (n // 256) % 256, (n // 65536) % 256)
end

local function u32(n)
	return string.char(n % 256, (n // 256) % 256, (n // 65536) % 256, (n // 16777216) % 256)
end

local function s32(n)
	if n < 0 then
		n = n + 4294967296
	end
	return u32(n)
end

local function b16(n)
	return string.char((n // 256) % 256, n % 256)
end

local function b32(n)
	return string.char((n // 16777216) % 256, (n // 65536) % 256, (n // 256) % 256, n % 256)
end

local function size(info, w, h, label)
	T.ok(info ~= nil, label .. " is recognised")
	if info then
		T.eq(info.width, w, label .. " width")
		T.eq(info.height, h, label .. " height")
	end
end

local function nosize(info, label)
	if info then
		T.eq(info.width, nil, label .. " has no width")
		T.eq(info.height, nil, label .. " has no height")
	else
		T.eq(info, nil, label .. " is not a picture")
	end
end

T.section("imgsniff bytes: GIF header and end mark")
do
	local head = "GIF89a" .. u16(1000) .. u16(513)
	local info = Sniff.sniff(head)
	size(info, 1000, 513, "ten bytes")
	T.eq(info.truncated, true)
	nosize(Sniff.sniff(string.sub(head, 1, 9)), "nine bytes")
	T.eq(Sniff.sniff(head .. ";").truncated, false)
	T.eq(Sniff.sniff(head .. ";\0").truncated, false, "one stray byte after the end mark")
	T.eq(Sniff.sniff(head .. ";\0\0").truncated, true)
end

T.section("imgsniff bytes: PNG header, byte order and end chunk")
do
	local sig = "\137PNG\r\n\26\n"
	local ihdr = sig .. b32(13) .. "IHDR" .. b32(16909060) .. b32(84281096)
	T.eq(#ihdr, 24)
	size(Sniff.sniff(ihdr), 16909060, 84281096, "exactly 24 bytes")
	nosize(Sniff.sniff(string.sub(ihdr, 1, 23)), "23 bytes")
	nosize(Sniff.sniff(sig .. b32(13) .. "IDAT" .. b32(5) .. b32(6)), "a first chunk that is not the header")
	nosize(Sniff.sniff(sig .. b32(13) .. "IHDR" .. b32(0) .. b32(6)), "a width of zero")
	nosize(Sniff.sniff(sig .. b32(13) .. "IHDR" .. b32(6) .. b32(0)), "a height of zero")
	local body = ihdr .. string.rep("x", 30)
	T.eq(Sniff.sniff(body .. "IEND" .. string.rep("z", 12)).truncated, false, "the end chunk starts in the last 16 bytes")
	T.eq(Sniff.sniff(body .. "IEND" .. string.rep("z", 13)).truncated, true, "and not 17 bytes from the end")
	T.eq(Sniff.sniff(body .. "IEND" .. string.rep("z", 8)).truncated, false)
end

T.section("imgsniff bytes: BMP header sizes, offsets and byte order")
do
	local function bmp(dib, w, h, offset, magic, declared)
		local headerLen = 14 + dib
		local dims
		if dib == 12 then
			dims = u16(w) .. u16(h) .. u16(1) .. u16(24)
		else
			dims = s32(w) .. s32(h) .. u16(1) .. u16(24)
		end
		local info = dims .. string.rep("\0", dib - 4 - #dims)
		return (magic or "BM") .. u32(declared or headerLen) .. "\0\0\0\0" .. u32(offset or headerLen) .. u32(dib) .. info
	end
	for _, dib in ipairs({ 12, 40, 52, 56, 64, 108, 124 }) do
		local info = Sniff.sniff(bmp(dib, 7, 5))
		size(info, 7, 5, "a header of " .. dib)
		if info then
			T.eq(info.format, "bmp")
			T.eq(info.truncated, false)
		end
	end
	for _, dib in ipairs({ 11, 13, 39, 41, 51, 53, 55, 57, 63, 65, 107, 109, 123, 125 }) do
		T.eq(Sniff.sniff(bmp(dib, 7, 5)), nil, "a header of " .. dib .. " is not a BMP")
	end
	size(Sniff.sniff(bmp(40, 16909060, -84281096)), 16909060, 84281096, "big numbers in every byte")
	size(Sniff.sniff(bmp(40, 5, 2147483647)), 5, 2147483647, "the biggest positive height")
	size(Sniff.sniff(bmp(40, 3, -2)), 3, 2, "a negative height is stored upside down")
	nosize(Sniff.sniff(bmp(40, 0, 5)), "a width of zero")
	nosize(Sniff.sniff(bmp(40, 5, 0)), "a height of zero")
	size(Sniff.sniff(bmp(12, 3, 2)), 3, 2, "26 bytes, the smallest BMP")
	T.eq(#bmp(12, 3, 2), 26)
	T.eq(Sniff.sniff(string.sub(bmp(12, 3, 2), 1, 25)), nil, "25 bytes is too short")
	T.eq(Sniff.sniff(bmp(40, 7, 5, nil, "XX")), nil, "the first two letters must be BM")
	size(Sniff.sniff(bmp(40, 7, 5, 54)), 7, 5, "the data starts right after the header")
	size(Sniff.sniff(bmp(40, 7, 5, 100)), 7, 5, "or later")
	T.eq(Sniff.sniff(bmp(40, 7, 5, 53)), nil, "one byte inside the header")
	T.eq(Sniff.sniff(bmp(40, 7, 5, 40)), nil, "well inside the header")
	T.eq(Sniff.sniff(bmp(40, 7, 5, 0)), nil, "at the very start")
	T.eq(Sniff.sniff(bmp(12, 3, 2, 25)), nil, "one byte inside an old OS/2 header")
	T.eq(Sniff.sniff(bmp(40, 7, 5, nil, nil, 100)).truncated, true, "the header promises more than there is")
end

T.section("imgsniff bytes: JPEG markers and the walk to the size")
do
	local SOI = "\255\216"
	local EOI = "\255\217"
	local function seg(marker, payload)
		return "\255" .. string.char(marker) .. b16(#payload + 2) .. payload
	end
	local function sofSeg(marker, w, h)
		return seg(marker, "\8" .. b16(h) .. b16(w) .. "\1\1\17\0")
	end
	local SOS = seg(218, "\1\1\0\0\63\0")
	local function tiny(marker, w, h)
		return SOI .. "\255" .. string.char(marker) .. b16(11) .. "\8" .. b16(h) .. b16(w)
	end
	T.eq(#tiny(192, 258, 772), 11)
	for _, marker in ipairs({ 192, 193, 194, 195, 197, 198, 199, 201, 202, 203, 205, 206, 207 }) do
		size(Sniff.sniff(tiny(marker, 258, 772)), 258, 772, "frame marker " .. marker)
	end
	for _, marker in ipairs({ 196, 200, 204, 224, 254, 219 }) do
		nosize(Sniff.sniff(tiny(marker, 258, 772)), "marker " .. marker .. " is not a frame header")
	end
	size(Sniff.sniff(tiny(192, 258, 772)), 258, 772, "the frame header is the last thing in the file")
	nosize(Sniff.sniff(string.sub(tiny(192, 258, 772), 1, 10)), "one byte short of the whole frame header")
	for _, marker in ipairs({ 196, 200, 204 }) do
		local info = Sniff.sniff(SOI .. sofSeg(192, 40, 30) .. seg(marker, "\8" .. b16(99) .. b16(88) .. "\1\1\17\0") .. SOS .. "data" .. EOI)
		size(info, 40, 30, "a table (" .. marker .. ") after the frame header is not a second frame")
	end
	local real = sofSeg(192, 321, 123)
	for _, stand in ipairs({ "\255\1", "\255\208", "\255\209", "\255\210", "\255\211", "\255\212", "\255\213", "\255\214", "\255\215", "\255\216" }) do
		local info = Sniff.sniff(SOI .. stand .. real .. SOS .. "data" .. EOI)
		size(info, 321, 123, "a marker without a length (" .. string.byte(stand, 2) .. ")")
		if info then
			T.eq(info.truncated, false)
		end
	end
	local early = Sniff.sniff(SOI .. sofSeg(192, 40, 30) .. EOI .. "\0\2" .. SOS .. EOI)
	size(early, 40, 30, "a picture that ends before its data")
	T.eq(early.truncated, true)
	local filler = "\255\216\255\255\255\255\224\0\2" .. seg(224, "JFIF\0\1\1\0\0\1\0\1\0\0") .. sofSeg(192, 8, 8) .. SOS .. "data" .. EOI
	local padded = Sniff.sniff(filler)
	size(padded, 8, 8, "padding bytes and an empty segment")
	T.eq(padded.truncated, false)
	local whole = Sniff.sniff(SOI .. seg(224, "JFIF\0") .. sofSeg(194, 17, 19) .. SOS .. "data" .. EOI)
	size(whole, 17, 19, "a normal order")
	T.eq(whole.truncated, false)
	T.eq(Sniff.sniff(SOI .. seg(224, "JFIF\0") .. sofSeg(194, 17, 19) .. SOS .. "data").truncated, true, "no end mark")
end

T.section("imgsniff bytes: WebP chunks, sizes and the promised length")
do
	local function riff(chunk, payload, declared)
		local body = "WEBP" .. chunk .. u32(#payload) .. payload
		return "RIFF" .. u32(declared or #body) .. body
	end
	local function vp8x(w, h)
		return riff("VP8X", "\0\0\0\0" .. u24(w - 1) .. u24(h - 1))
	end
	local function vp8l(w, h, alpha)
		local wm, hm = w - 1, h - 1
		local b1 = wm % 256
		local b2 = (wm // 256) % 64 + (hm % 4) * 64
		local b3 = (hm // 4) % 256
		local b4 = (hm // 1024) % 16 + (alpha and 16 or 0)
		return riff("VP8L", "\47" .. string.char(b1, b2, b3, b4) .. "\0")
	end
	local function vp8(w, h, wScale, hScale)
		return riff("VP8 ", "\0\0\0\157\1\42" .. u16(w + (wScale or 0) * 16384) .. u16(h + (hScale or 0) * 16384) .. "\0\0")
	end
	local x = vp8x(66052, 263431)
	T.eq(#x, 30)
	size(Sniff.sniff(x), 66052, 263431, "extended, every byte different")
	T.eq(Sniff.sniff(x).truncated, false)
	nosize(Sniff.sniff(string.sub(x, 1, 29)), "extended, 29 bytes")
	size(Sniff.sniff(vp8x(1, 1)), 1, 1, "extended 1 x 1")
	size(Sniff.sniff(vp8x(16777216, 16777216)), 16777216, 16777216, "extended, the biggest")
	local l = vp8l(10844, 4663, true)
	size(Sniff.sniff(l), 10844, 4663, "lossless, every field in use")
	size(Sniff.sniff(vp8l(10844, 4663, false)), 10844, 4663, "lossless without transparency")
	size(Sniff.sniff(vp8l(1, 1)), 1, 1, "lossless 1 x 1")
	size(Sniff.sniff(vp8l(16384, 16384, true)), 16384, 16384, "lossless, the biggest")
	size(Sniff.sniff(string.sub(l, 1, 25)), 10844, 4663, "lossless, exactly 25 bytes")
	nosize(Sniff.sniff(string.sub(l, 1, 24)), "lossless, 24 bytes")
	nosize(Sniff.sniff(riff("VP8L", "\46" .. string.char(1, 2, 3, 4) .. "\0")), "lossless with a wrong first byte")
	nosize(Sniff.sniff(riff("ABCD", "\47" .. string.char(1, 2, 3, 4) .. "\0")), "an unknown chunk that starts with the lossless byte")
	local y = vp8(5000, 3000, 2, 3)
	size(Sniff.sniff(y), 5000, 3000, "lossy with the scale bits set")
	size(Sniff.sniff(vp8(16383, 16383, 1, 1)), 16383, 16383, "lossy, the biggest")
	size(Sniff.sniff(vp8(1, 1)), 1, 1, "lossy 1 x 1")
	size(Sniff.sniff(string.sub(y, 1, 30)), 5000, 3000, "lossy, exactly 30 bytes")
	nosize(Sniff.sniff(string.sub(y, 1, 29)), "lossy, 29 bytes")
	nosize(Sniff.sniff(riff("VP8 ", "\0\0\0\157\1\43" .. u16(5) .. u16(6) .. "\0\0")), "lossy with a wrong start code")
	nosize(Sniff.sniff(riff("ABCD", "\0\0\0\157\1\42" .. u16(5) .. u16(6) .. "\0\0")), "an unknown chunk with the lossy start code")
	local whole = vp8x(20, 10)
	T.eq(Sniff.sniff(whole).truncated, false)
	T.eq(Sniff.sniff(whole .. "\0").truncated, false, "extra bytes at the end are not a cut")
	local longer = riff("VP8X", "\0\0\0\0" .. u24(19) .. u24(9) .. "\0\0")
	T.eq(#longer, 32)
	T.eq(Sniff.sniff(longer).truncated, false)
	local short = Sniff.sniff(string.sub(longer, 1, 31))
	T.eq(short.truncated, true, "one byte short of what the header promises")
	T.eq(short.width, 20)
	T.eq(Sniff.sniff(riff("VP8X", "\0\0\0\0" .. u24(19) .. u24(9), 22 + 1)).truncated, true)
	nosize(Sniff.sniff("XXXX" .. u32(22) .. "WEBPVP8X" .. u32(10) .. "\0\0\0\0" .. u24(19) .. u24(9)), "not a RIFF file")
	nosize(Sniff.sniff("RIFF" .. u32(22) .. "WEBQVP8X" .. u32(10) .. "\0\0\0\0" .. u24(19) .. u24(9)), "not a WEBP file")
end

T.section("imgsniff bytes: ICO entries, counts and offsets")
do
	local function entry(w, h, colors, planes, bits, bytes, offset, reserved)
		return string.char(w, h, colors or 0, reserved or 0) .. u16(planes or 1) .. u16(bits or 32) .. u32(bytes or 0) .. u32(offset)
	end
	local function ico(count, entries, data)
		return "\0\0\1\0" .. u16(count) .. table.concat(entries) .. (data or "")
	end
	local one = ico(1, { entry(16, 16, 0, 1, 32, 0, 22) })
	T.eq(#one, 22)
	local info = Sniff.sniff(one)
	size(info, 16, 16, "22 bytes, the smallest icon")
	T.eq(info.format, "ico")
	T.eq(info.truncated, false)
	T.eq(Sniff.sniff(string.sub(one, 1, 21)), nil, "21 bytes")
	size(Sniff.sniff(ico(1, { entry(1, 1, 0, 1, 32, 0, 22) })), 1, 1, "1 x 1")
	size(Sniff.sniff(ico(1, { entry(8, 0, 0, 1, 32, 0, 22) })), 8, 256, "a height byte of 0 means 256")
	T.eq(Sniff.sniff(ico(0, { entry(16, 16, 0, 1, 32, 0, 6) })), nil, "no pictures")
	local many = Sniff.sniff(ico(255, { entry(16, 16, 0, 1, 32, 0, 4086) }))
	T.ok(many ~= nil, "255 pictures are fine")
	if many then
		T.eq(many.truncated, true, "and the missing entries mean a cut")
	end
	T.ok(Sniff.sniff(ico(254, { entry(16, 16, 0, 1, 32, 0, 6 + 16 * 254) })) ~= nil)
	T.eq(Sniff.sniff(ico(256, { entry(16, 16, 0, 1, 32, 0, 6 + 16 * 256) })), nil, "256 pictures is too many")
	for _, bits in ipairs({ 0, 1, 2, 4, 8, 15, 16, 24, 32 }) do
		T.ok(Sniff.sniff(ico(1, { entry(16, 16, 0, 1, bits, 0, 22) })) ~= nil, "bit depth " .. bits .. " is fine")
	end
	for _, bits in ipairs({ 3, 5, 6, 7, 9, 14, 17, 23, 25, 31, 33, 48, 255 }) do
		T.eq(Sniff.sniff(ico(1, { entry(16, 16, 0, 1, bits, 0, 22) })), nil, "bit depth " .. bits .. " is not an icon")
	end
	T.ok(Sniff.sniff(ico(1, { entry(16, 16, 0, 0, 32, 0, 22) })) ~= nil, "0 planes")
	T.ok(Sniff.sniff(ico(1, { entry(16, 16, 0, 1, 32, 0, 22) })) ~= nil, "1 plane")
	T.eq(Sniff.sniff(ico(1, { entry(16, 16, 0, 2, 32, 0, 22) })), nil, "2 planes")
	T.eq(Sniff.sniff(ico(1, { entry(16, 16, 0, 7, 32, 0, 22) })), nil, "7 planes")
	T.ok(Sniff.sniff(ico(1, { entry(16, 16, 16, 1, 4, 0, 22) })) ~= nil, "a colour count of 16 with 1 plane")
	T.eq(Sniff.sniff(ico(1, { entry(16, 16, 0, 0, 32, 0, 22, 1) })), nil, "a reserved byte that is not zero")
	T.eq(Sniff.sniff(ico(1, { entry(16, 16, 0, 1, 32, 0, 22, 1) })), nil, "a reserved byte that is not zero, 1 plane")
	local pair = { entry(16, 16, 0, 1, 32, 0, 38), entry(32, 32, 0, 1, 32, 0, 38) }
	size(Sniff.sniff(ico(2, pair)), 32, 32, "two entries, 38 bytes")
	T.eq(Sniff.sniff(ico(2, pair)).truncated, false)
	local cut = Sniff.sniff(string.sub(ico(2, pair), 1, 37))
	size(cut, 16, 16, "two entries, the second one cut by a byte")
	T.eq(cut.truncated, true)
	local low = { entry(16, 16, 0, 1, 32, 0, 37), entry(32, 32, 0, 1, 32, 0, 37) }
	T.eq(Sniff.sniff(ico(2, low)), nil, "the first picture would start inside the entry list")
	local lower = { entry(16, 16, 0, 1, 32, 0, 6), entry(32, 32, 0, 1, 32, 0, 6) }
	T.eq(Sniff.sniff(ico(2, lower)), nil, "or at the start of the file")
	local tie = Sniff.sniff(ico(2, { entry(16, 32, 0, 1, 32, 0, 38), entry(32, 16, 0, 1, 32, 0, 38) }))
	size(tie, 16, 32, "two sizes with the same area, the first one stays")
	size(Sniff.sniff(ico(2, { entry(32, 32, 0, 1, 32, 0, 38), entry(20, 20, 0, 1, 32, 0, 38) })), 32, 32, "a smaller one after a bigger one")
	size(Sniff.sniff(ico(2, { entry(10, 10, 0, 1, 32, 0, 38), entry(64, 4, 0, 1, 32, 0, 38) })), 64, 4, "a wider one with the bigger area")
	size(Sniff.sniff(ico(2, { entry(40, 40, 0, 1, 32, 0, 38), entry(100, 2, 0, 1, 32, 0, 38) })), 40, 40, "a wide thin one with a smaller area")
	local fitting = ico(1, { entry(16, 16, 0, 1, 32, 100, 22) }, string.rep("x", 100))
	T.eq(Sniff.sniff(fitting).truncated, false)
	T.eq(Sniff.sniff(string.sub(fitting, 1, #fitting - 1)).truncated, true, "the picture data is one byte short")
	T.eq(Sniff.sniff(fitting .. "x").truncated, false)
end

T.section("imgsniff bytes: AVIF and HEIC brands, boxes and sizes")
do
	local function box(kind, payload)
		return b32(#payload + 8) .. kind .. payload
	end
	local function ispe(w, h)
		return box("ispe", "\0\0\0\0" .. b32(w) .. b32(h))
	end
	local function ftyp(major, compat)
		return box("ftyp", major .. "\0\0\0\0" .. (compat or ""))
	end
	local function whole(ispes, major, compat)
		return ftyp(major or "avif", compat or "mif1") .. box("meta", "\0\0\0\0" .. table.concat(ispes or {})) .. box("mdat", "pixels!")
	end
	for _, brand in ipairs({ "avif", "avis" }) do
		T.eq(Sniff.sniff(ftyp(brand)).format, "avif", brand)
	end
	for _, brand in ipairs({ "heic", "heix", "hevc", "hevx", "heim", "heis", "hevm", "hevs", "mif1", "msf1" }) do
		T.eq(Sniff.sniff(ftyp(brand)).format, "heic", brand)
		T.eq(Sniff.sniff(ftyp("isom", brand)).format, "heic", brand .. " as a compatible brand")
	end
	T.eq(Sniff.sniff(ftyp("mif1", "avif")).format, "avif", "the first compatible brand is read from its first letter")
	T.eq(Sniff.sniff(ftyp("isom", "avis")).format, "avif")
	T.eq(Sniff.sniff(ftyp("isom", "iso2")), nil, "a video brand")
	T.eq(Sniff.sniff(ftyp("mif1", "msf1") .. box("free", "avif")).format, "heic", "brands after the ftyp box are not read")
	T.eq(Sniff.sniff(b32(24) .. "XXXX" .. "avif" .. string.rep("\0", 12)), nil, "no ftyp mark")
	T.eq(Sniff.sniff(b32(16) .. "ftyp" .. "xhei" .. "c\0\0\0"), nil, "the main brand is exactly four letters")
	T.eq(Sniff.sniff(b32(20) .. "ftyp" .. "isom" .. "\0\0\0a" .. "vifX"), nil, "the version number is not part of the brands")
	T.eq(Sniff.sniff(b32(16) .. "ftyp" .. "xavi" .. "\0\0\0\0" .. "f"), nil, "and neither is anything after the ftyp box")
	T.eq(Sniff.sniff(whole()).truncated, false)
	T.eq(Sniff.sniff(whole()).format, "avif")
	size(Sniff.sniff(whole({ ispe(1, 1) })), 1, 1, "1 x 1")
	size(Sniff.sniff(whole({ ispe(65535, 65535) })), 65535, 65535, "the biggest")
	nosize(Sniff.sniff(whole({ ispe(0, 10) })), "a width of 0")
	nosize(Sniff.sniff(whole({ ispe(10, 0) })), "a height of 0")
	nosize(Sniff.sniff(whole({ ispe(65536, 5) })), "a width of 65536")
	nosize(Sniff.sniff(whole({ ispe(5, 65536) })), "a height of 65536")
	nosize(Sniff.sniff(whole({ ispe(65536, 65536) })), "both too big")
	size(Sniff.sniff(whole({ ispe(100, 50), ispe(50, 100) })), 100, 50, "the same area twice, the first stays")
	size(Sniff.sniff(whole({ ispe(100, 100), ispe(4000, 3) })), 4000, 3, "the bigger area wins")
	size(Sniff.sniff(whole({ ispe(100, 100), ispe(20, 20) })), 100, 100, "the smaller area loses")
	size(Sniff.sniff(whole({ ispe(300, 2), ispe(25, 25) })), 25, 25, "area, not width plus height")
	local nine = {}
	for i = 1, 9 do
		nine[i] = ispe(i * 10, i * 10)
	end
	size(Sniff.sniff(whole(nine)), 80, 80, "only the first eight sizes are looked at")
	local fits = ftyp("avif") .. ispe(30, 40)
	size(Sniff.sniff(fits), 30, 40, "a size box at the very end of the file")
	local partial = ftyp("avif") .. "ispe" .. "\0\0\0\0" .. b32(30) .. "\0\0\1"
	nosize(Sniff.sniff(partial), "a size box cut before its last byte")
	local pad = 65516 - #ftyp("avif")
	local inside = ftyp("avif") .. box("free", string.rep("\0", pad - 8)) .. ispe(77, 88)
	T.eq(#inside, 65536)
	size(Sniff.sniff(inside), 77, 88, "the size box ends exactly at the 64 KB mark")
	local outside = ftyp("avif") .. box("free", string.rep("\0", pad - 8 + 1)) .. ispe(77, 88)
	T.eq(#outside, 65537)
	nosize(Sniff.sniff(outside), "and one byte later it is not looked at")
	local count64 = ftyp("avif") .. string.rep(box("free", ""), 61) .. box("meta", "") .. box("mdat", "")
	T.eq(Sniff.sniff(count64).truncated, false, "64 boxes are walked")
	local count65 = ftyp("avif") .. string.rep(box("free", ""), 62) .. box("meta", "") .. box("mdat", "")
	T.eq(Sniff.sniff(count65).truncated, true, "the 65th box is not")
	T.eq(Sniff.sniff(whole() .. "x").truncated, true, "one stray byte after the last box")
	T.eq(Sniff.sniff(whole() .. "\0\0\0\0xyz").truncated, true, "seven stray bytes")
	T.eq(Sniff.sniff(whole() .. box("free", "")).truncated, false, "an empty box at the end")
	T.eq(Sniff.sniff(ftyp("avif") .. "\0\0\0\7fre" .. box("meta", "") .. box("mdat", "")).truncated, true, "a box that claims to be 7 bytes ends the walk")
	local tooLong = ftyp("avif") .. box("meta", "") .. b32(8 + 7 + 1) .. "mdat" .. "pixels!"
	T.eq(Sniff.sniff(tooLong).truncated, true, "the last box is one byte short")
	T.eq(Sniff.sniff(ftyp("avif") .. box("meta", "") .. b32(8 + 7) .. "mdat" .. "pixels!").truncated, false)
	T.eq(Sniff.sniff(ftyp("avif") .. box("mdat", "pixels!")).truncated, true, "no meta box")
	T.eq(Sniff.sniff(ftyp("avif") .. box("meta", "")).truncated, true, "no data box")
end

T.section("imgsniff bytes: SVG starts, windows and numbers")
do
	local function svg(text)
		return Sniff.sniff(text)
	end
	size(svg("\239\187\191<svg width='4' height='6'/>"), 4, 6, "a byte order mark")
	size(svg("\239\187\191  \n<svg width='4' height='6'/>"), 4, 6, "a byte order mark and blank space")
	T.eq(svg("\239\187\191<svg width='4' height='6'/>").truncated, false)
	size(svg('<?xml version="1.0" encoding="UTF-8"?>\n<svg xmlns="http://www.w3.org/2000/svg" width="10" height="20"></svg>'), 10, 20, "an xml start")
	size(svg('<?XML version="1.0"?><SVG width="10" height="20"></SVG>'), 10, 20, "capital letters")
	size(svg('<!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN" "x.dtd"><svg width="7" height="9"></svg>'), 7, 9, "a doctype start")
	T.eq(svg('<!DOCTYPE svg PUBLIC "x"><div></div>'), nil, "a doctype with no drawing")
	size(svg('<svg viewBox="0 0 50 40"><rect width="10" height="10"/></svg>'), 50, 40, "a width further in does not count")
	size(svg('<svg width="30" viewBox="0 0 50 40"></svg>'), 30, 40, "a width and a view box")
	size(svg('<svg height="30" viewBox="0 0 50 40"></svg>'), 50, 30, "a height and a view box")
	nosize(svg('<svg width="1.2.3" height="5"></svg>'), "a number that is not a number")
	size(svg('<svg width="0" height="10" viewBox="0 0 20 10"></svg>'), 20, 10, "a width of 0 falls back to the view box")
	size(svg('<svg width="1" height="1"></svg>'), 1, 1, "1 x 1")
	nosize(svg('<svg viewBox="0 0 1.2.3 7"></svg>'), "a view box width that is not a number")
	nosize(svg('<svg viewBox="0 0 5 1.2.3"></svg>'), "a view box height that is not a number")
	local opening = '<svg width="3" height="3">'
	T.eq(svg(opening .. "</svg" .. string.rep("x", 508)).truncated, false, "the closing tag starts 512 bytes from the end")
	T.eq(svg(opening .. "</svg" .. string.rep("x", 509)).truncated, true, "and 513 bytes from the end")
	T.eq(svg(opening .. "</svg>").truncated, false)
	T.eq(svg(opening).truncated, true)
	local prolog = '<?xml version="1.0"?>'
	local inside = prolog .. string.rep(" ", 2048 - 4 - #prolog) .. "<svg width='9'"
	T.eq(string.find(inside, "<svg", 1, true), 2045)
	T.eq(svg(inside).format, "svg", "the drawing tag ends at byte 2048")
	local outside = prolog .. string.rep(" ", 2049 - 4 - #prolog) .. "<svg width='9'"
	T.eq(string.find(outside, "<svg", 1, true), 2046)
	T.eq(svg(outside), nil, "and one byte later it is not seen")
end

T.section("imgsniff bytes: TGA headers")
do
	local function header(idLen, mapType, kind, mapLen, mapBits, w, h, depth)
		return string.char(idLen, mapType, kind) .. u16(0) .. u16(mapLen) .. string.char(mapBits) .. u16(0) .. u16(0) .. u16(w) .. u16(h) .. string.char(depth, 0)
	end
	local function tga(bytes)
		return Sniff.sniff(bytes, "picture.tga")
	end
	local only = header(0, 0, 2, 0, 0, 4, 3, 24)
	T.eq(#only, 18)
	local info = tga(only)
	size(info, 4, 3, "18 bytes, only the header")
	T.eq(info.format, "tga")
	T.eq(info.truncated, true)
	T.eq(tga(string.sub(only, 1, 17)), nil, "17 bytes")
	size(tga(header(0, 0, 2, 0, 0, 1, 1, 24)), 1, 1, "1 x 1")
	nosize(tga(header(0, 0, 2, 0, 0, 0, 3, 24)), "a width of 0")
	nosize(tga(header(0, 0, 2, 0, 0, 4, 0, 24)), "a height of 0")
	for _, kind in ipairs({ 2, 3, 10, 11 }) do
		size(tga(header(0, 0, kind, 0, 0, 4, 3, 24)), 4, 3, "type " .. kind)
	end
	for _, kind in ipairs({ 1, 9 }) do
		size(tga(header(0, 1, kind, 2, 24, 4, 3, 8)), 4, 3, "colour-mapped type " .. kind)
		T.eq(tga(header(0, 0, kind, 2, 24, 4, 3, 8)), nil, "type " .. kind .. " needs a colour map")
	end
	for _, kind in ipairs({ 0, 4, 5, 6, 7, 8, 12, 13, 32, 255 }) do
		T.eq(tga(header(0, 0, kind, 0, 0, 4, 3, 24)), nil, "type " .. kind .. " is not a picture")
	end
	size(tga(header(0, 1, 2, 2, 24, 4, 3, 24)), 4, 3, "a colour map next to true colour")
	T.eq(tga(header(0, 2, 2, 0, 0, 4, 3, 24)), nil, "a colour map flag of 2")
	T.eq(tga(header(0, 7, 2, 0, 0, 4, 3, 24)), nil, "a colour map flag of 7")
	for _, depth in ipairs({ 8, 15, 16, 24, 32 }) do
		size(tga(header(0, 0, 2, 0, 0, 4, 3, depth)), 4, 3, "depth " .. depth)
	end
	for _, depth in ipairs({ 0, 1, 4, 7, 9, 12, 14, 17, 23, 25, 31, 33, 48, 64 }) do
		T.eq(tga(header(0, 0, 2, 0, 0, 4, 3, depth)), nil, "depth " .. depth .. " is not a picture")
	end
	local function filled(idLen, mapType, kind, mapLen, mapBits, w, h, depth, bytes)
		return header(idLen, mapType, kind, mapLen, mapBits, w, h, depth) .. string.rep("i", idLen) .. string.rep("p", bytes)
	end
	local exact = filled(7, 0, 2, 0, 0, 4, 3, 24, 36)
	T.eq(#exact, 61)
	T.eq(tga(exact).truncated, false, "the right amount of data")
	T.eq(tga(string.sub(exact, 1, 60)).truncated, true, "one byte short")
	T.eq(tga(exact .. "x").truncated, false)
	T.eq(tga(filled(0, 0, 2, 0, 0, 4, 3, 8, 12)).truncated, false, "8 bits is one byte a pixel")
	T.eq(tga(filled(0, 0, 2, 0, 0, 4, 3, 8, 11)).truncated, true)
	T.eq(tga(filled(0, 0, 2, 0, 0, 4, 3, 15, 24)).truncated, false, "15 bits is two bytes a pixel")
	T.eq(tga(filled(0, 0, 2, 0, 0, 4, 3, 15, 23)).truncated, true)
	T.eq(tga(filled(0, 0, 2, 0, 0, 4, 3, 16, 24)).truncated, false)
	T.eq(tga(filled(0, 0, 2, 0, 0, 4, 3, 32, 48)).truncated, false, "32 bits is four bytes a pixel")
	T.eq(tga(filled(0, 0, 2, 0, 0, 4, 3, 32, 47)).truncated, true)
	T.eq(tga(filled(0, 0, 3, 0, 0, 4, 3, 8, 12)).truncated, false, "type 3, grey")
	T.eq(tga(filled(0, 0, 3, 0, 0, 4, 3, 8, 11)).truncated, true)
	local mapped = filled(0, 1, 1, 256, 24, 4, 3, 8, 768 + 12)
	T.eq(#mapped, 18 + 768 + 12)
	T.eq(tga(mapped).truncated, false, "a 256 entry colour map of 24 bits")
	T.eq(tga(string.sub(mapped, 1, #mapped - 1)).truncated, true)
	local small = filled(3, 1, 1, 5, 32, 2, 2, 8, 20 + 4)
	T.eq(tga(small).truncated, false, "a 5 entry colour map of 32 bits")
	T.eq(tga(string.sub(small, 1, #small - 1)).truncated, true)
	local sixteen = filled(0, 1, 1, 10, 15, 2, 2, 8, 20 + 4)
	T.eq(tga(sixteen).truncated, false, "15 bit entries take two bytes")
	T.eq(tga(string.sub(sixteen, 1, #sixteen - 1)).truncated, true)
	local trueMapped = filled(0, 1, 2, 4, 24, 2, 2, 24, 12 + 12)
	T.eq(tga(trueMapped).truncated, false, "a colour map next to true colour")
	T.eq(tga(string.sub(trueMapped, 1, #trueMapped - 1)).truncated, true)
	for _, kind in ipairs({ 9, 10, 11 }) do
		local info2 = tga(header(0, kind == 9 and 1 or 0, kind, 2, 24, 400, 300, 8))
		T.eq(info2.truncated, false, "compressed type " .. kind .. " cannot be judged by size")
	end
end

T.section("imgsniff bytes: why a file is not a picture")
do
	T.eq(Sniff.sniff("A"), nil)
	T.eq(select(2, Sniff.sniff("A")), "that is a text file, not a picture", "one letter is not an empty file")
	T.eq(Sniff.reasonFor("A"), "that is a text file, not a picture")
	T.eq(Sniff.reasonFor(""), "that file is empty")
	local page = "that link gave a web page, not a picture (the link may have expired)"
	for _, text in ipairs({ "<!DOCTYPE html>", "<html>", "<head>", "<body>", "<HTML>", "<BODY>" }) do
		T.eq(Sniff.reasonFor(text), page, text .. " alone")
		T.eq(Sniff.reasonFor("hello " .. text), page, text .. " after some words")
	end
	T.eq(Sniff.reasonFor(string.rep("a", 507) .. "<body>"), page, "a page tag ending at byte 512")
	T.eq(Sniff.reasonFor(string.rep("a", 508) .. "<body>"), "that is a text file, not a picture", "and one byte later")
	local sound = "that is a sound, not a picture"
	T.eq(Sniff.reasonFor("OggS\0\2\0\0"), sound)
	T.eq(Sniff.reasonFor("ID3\4\0\0\0\0"), sound)
	T.eq(Sniff.reasonFor("fLaC\0\0\0\34"), sound)
	T.eq(Sniff.reasonFor("RIFF\0\0\0\0WAVEfmt "), sound)
	T.eq(Sniff.reasonFor("RIFF\0\0\0\0AVI LIST"), "I don't recognise that picture format", "RIFF alone is not a sound")
	T.eq(Sniff.reasonFor("\0\0\0\0\0\0\0\0WAVEfmt "), "I don't recognise that picture format", "WAVE alone is not a sound")
	T.eq(Sniff.reasonFor("\0\0\0\24ftypisom\0\0\2\0"), "that is a video, not a picture")
	T.eq(Sniff.reasonFor("\26\69\223\163\1\0\0\0\0\0\0\31"), "that is a video, not a picture", "a webm or mkv start")
	T.eq(Sniff.reasonFor("PK\3\4\20\0"), "that is a zip archive, not a picture")
	T.eq(Sniff.reasonFor("%PDF-1.7"), "that is a PDF, not a picture")
	T.eq(Sniff.reasonFor("{\"a\":1}"), "that link gave a message, not a picture")
	T.eq(Sniff.reasonFor("\239\187\191[1,2]"), "that link gave a message, not a picture")
	T.eq(Sniff.reasonFor("  \n {\"a\":1}"), "that link gave a message, not a picture")
	T.eq(Sniff.reasonFor("\1\2\3\4\5\6\7\8"), "I don't recognise that picture format")
end

T.section("imgsniff bytes: the text check at every byte")
do
	for b = 0, 255 do
		local want = b == 9 or b == 10 or b == 11 or b == 12 or b == 13 or (b >= 32 and b ~= 127)
		T.eq(Sniff.looksLikeText("a" .. string.char(b) .. "a"), want, "byte " .. b)
		T.eq(Sniff.looksLikeText(string.char(b)), want, "byte " .. b .. " first")
	end
	T.eq(Sniff.looksLikeText(string.rep("a", 255) .. "\0"), false, "a control byte at 256")
	T.eq(Sniff.looksLikeText(string.rep("a", 256) .. "\0"), true, "and at 257")
end

T.section("imgsniff bytes: the line under a preview")
do
	T.eq(Sniff.describe({ format = "png", label = "PNG", width = 5 }), "PNG")
	T.eq(Sniff.describe({ format = "png", label = "PNG", height = 5 }), "PNG")
	T.eq(Sniff.describe({ format = "png", label = "PNG", width = 5, height = 6, truncated = true }), "PNG  ·  5 x 6  ·  cut short")
end
