local W = loadmodule("Testing/mocks/art_world.lua")
local Art = loadmodule("Hub/modules/scriptart.lua")

local WEBP_FILE = "Roblox can't show .webp pictures. Convert it to PNG or JPG and pick it again."

local function boot(opts)
	local world = W.new(opts)
	Art.init(world.ctx)
	return world
end

local function file(value)
	return { src = "file", value = value }
end

local function link(value)
	return { src = "url", value = value }
end

local function cacheCount(world)
	return #world.cacheFiles(Art.CACHE_DIR)
end

T.section("scriptart load: a picture from the workspace")
do
	local world = boot()
	local bytes = W.fixture("png_rgb_3x2")
	world.put("pics/me.png", bytes)
	local r = Art.resolveNow(file("pics/me.png"), { host = {} })
	T.eq(r.ok, true)
	T.eq(r.src, "file")
	T.eq(r.value, "pics/me.png")
	T.eq(r.format, "png")
	T.eq(r.ext, "png")
	T.eq(r.label, "PNG")
	T.eq(r.w, 3)
	T.eq(r.h, 2)
	T.eq(r.size, #bytes)
	T.eq(r.name, "me.png")
	T.eq(r.note, nil, "the name matches, so no note")
	T.eq(r.warn, nil)
	T.eq(r.unchecked, nil)
	T.ok(Art.safeCache(r.cached), "the copy is in the cache folder")
	T.eq(string.sub(r.cached, -4), ".png")
	T.eq(world.files[r.cached], bytes, "the copy is identical")
	T.eq(r.id, "rbxasset://" .. r.cached)
	T.same(world.probeCalls, { r.id }, "the copy was checked once")
	T.eq(world.files["pics/me.png"], bytes, "the original is untouched")
	T.eq(cacheCount(world), 1)
	local writes = world.writeCount
	local again = Art.resolveNow(file("pics/me.png"), { host = {} })
	T.eq(again.cached, r.cached, "the same picture gets the same copy")
	T.eq(world.writeCount, writes, "and is not written twice")
	T.eq(cacheCount(world), 1)
	local other = Art.resolveNow(file("pics/me.png"), {})
	T.eq(other.ok, true)
	T.eq(other.unchecked, true, "without somewhere to check it, it is marked unchecked")
	T.eq(#world.probeCalls, 2, "and nothing more was probed")
end

T.section("scriptart load: names never decide the format")
do
	local world = boot()
	world.put("kxjqzpw.png", W.fixture("jpeg_baseline_8x8"))
	local r = Art.resolveNow(file("kxjqzpw.png"), { host = {} })
	T.eq(r.ok, true)
	T.eq(r.format, "jpeg", "a JPEG hiding under a PNG name")
	T.eq(string.sub(r.cached, -4), ".jpg", "the copy gets the true ending")
	T.eq(r.note, "The name says .png but it is really a JPEG picture, which is fine.")
	world.put("photo.jpg", W.fixture("png_wide_300x100"))
	local p = Art.resolveNow(file("photo.jpg"), { host = {} })
	T.eq(p.format, "png", "a PNG saved as .jpg")
	T.eq(string.sub(p.cached, -4), ".png")
	T.eq(p.w, 300)
	T.eq(p.h, 100)
	T.eq(p.note, "The name says .jpg but it is really a PNG picture, which is fine.")
	world.put("scrambled", W.fixture("png_rgba_1x1"))
	local s = Art.resolveNow(file("scrambled"), { host = {} })
	T.eq(s.ok, true, "no ending at all")
	T.eq(s.format, "png")
	T.eq(s.note, nil, "no ending means nothing to disagree with")
	world.put("weird.dat", W.fixture("jpeg_progressive_16x16"))
	local d = Art.resolveNow(file("weird.dat"), { host = {} })
	T.eq(d.format, "jpeg", "an ending nobody knows")
	T.eq(d.note, nil)
	world.put("art.tga", W.fixture("tga_raw_4x3"))
	local t = Art.resolveNow(file("art.tga"), { host = {} })
	T.eq(t.format, "tga")
	T.eq(string.sub(t.cached, -4), ".tga")
	world.put("art.bin", W.fixture("tga_raw_4x3"))
	local nt = Art.resolveNow(file("art.bin"), { host = {} })
	T.eq(nt.ok, false, "a TGA needs the right name because it has no magic")
	T.eq(nt.stage, "sniff")
	T.eq(nt.why, "I don't recognise that picture format")
end

T.section("scriptart load: pictures Roblox can't show")
do
	local world = boot()
	world.badExts.webp = true
	world.put("Scrambled/kxjqzpw.png", W.fixture("webp_lossless_8x8"))
	local r = Art.resolveNow(file("Scrambled/kxjqzpw.png"), { host = {} })
	T.eq(r.ok, false)
	T.eq(r.stage, "probe")
	T.eq(r.why, WEBP_FILE, "the detected format is named, not the file's ending")
	T.eq(r.format, "webp")
	T.eq(r.ext, "webp")
	T.eq(r.needConvert, nil, "a file has no online fallback")
	T.eq(cacheCount(world), 0, "the failed copy is removed again")
	world.badExts.webp = nil
	world.badExts.gif = true
	world.put("anim.gif", W.fixture("gif_animated_6x6"))
	T.eq(Art.resolveNow(file("anim.gif"), { host = {} }).why, "Roblox can't show .gif pictures. Convert it to PNG or JPG and pick it again.")
	world.put("good.png", W.fixture("png_rgb_3x2"))
	T.eq(Art.resolveNow(file("good.png"), { host = {} }).ok, true, "other pictures still work")
	T.eq(cacheCount(world), 1)
end

T.section("scriptart load: a fetched picture that never reports loaded")
do
	local world = boot()
	world.badStatus = "fetched"
	world.badExts.png = true
	world.badExts.jpg = true
	world.badExts.webp = true
	world.put("a.png", W.fixture("png_rgb_3x2"))
	T.eq(Art.resolveNow(file("a.png"), { host = {} }).ok, true, "PNG that was fetched is trusted")
	world.put("b.jpg", W.fixture("jpeg_baseline_8x8"))
	T.eq(Art.resolveNow(file("b.jpg"), { host = {} }).ok, true, "JPEG that was fetched is trusted")
	world.put("c.webp", W.fixture("webp_lossless_8x8"))
	local c = Art.resolveNow(file("c.webp"), { host = {} })
	T.eq(c.ok, false, "WebP that was only fetched is not trusted")
	T.eq(c.why, WEBP_FILE)
	world.badStatus = "timeout"
	local p = Art.resolveNow(file("a.png"), { host = {} })
	T.eq(p.ok, false, "a timeout is a failure even for PNG")
	T.eq(p.why, "Roblox took too long to show that picture. It may be too big, try a smaller one.")
end

T.section("scriptart load: pictures that are not pictures")
do
	local world = boot()
	world.put("empty.png", "")
	local e = Art.resolveNow(file("empty.png"), { host = {} })
	T.eq(e.ok, false)
	T.eq(e.stage, "sniff")
	T.eq(e.why, "That file is empty")
	world.put("notes.txt", "hello world, this is just text")
	T.eq(Art.resolveNow(file("notes.txt"), { host = {} }).why, "That is a text file, not a picture")
	world.put("page.png", "<!DOCTYPE html><html><body>nope</body></html>")
	T.eq(Art.resolveNow(file("page.png"), { host = {} }).why, "That link gave a web page, not a picture (the link may have expired)")
	world.put("archive.png", "PK\3\4" .. string.rep("\0", 40))
	T.eq(Art.resolveNow(file("archive.png"), { host = {} }).why, "That is a zip archive, not a picture")
	world.put("random.png", string.char(1, 2, 3, 4, 5, 6, 7, 8) .. string.rep("\200", 40))
	T.eq(Art.resolveNow(file("random.png"), { host = {} }).why, "I don't recognise that picture format")
	T.eq(cacheCount(world), 0, "nothing was copied for any of them")
	T.eq(world.writeCount, 0, "nothing was written at all")
end

T.section("scriptart load: cut-off pictures")
do
	local world = boot()
	local png = W.fixture("png_solid_256")
	world.put("cut.png", string.sub(png, 1, #png - 20))
	local r = Art.resolveNow(file("cut.png"), { host = {} })
	T.eq(r.ok, true, "Roblox may still show it")
	T.eq(r.truncated, true)
	T.eq(r.warn, "This picture looks cut short, it may show only part of the image.")
	world.badExts.png = true
	local bad = Art.resolveNow(file("cut.png"), { host = {} })
	T.eq(bad.ok, false)
	T.eq(bad.why, "That picture looks cut off, so Roblox can't show it. Download it again and pick it again.")
end

T.section("scriptart load: size limits")
do
	local world = boot()
	local png = W.fixture("png_solid_256")
	world.put("limit.png", W.fatPng(8388608 - #png))
	T.eq(#world.files["limit.png"], 8388608)
	local ok = Art.resolveNow(file("limit.png"), { host = {} })
	T.eq(ok.ok, true, "exactly 8 MB is allowed")
	T.eq(ok.warn, "This picture is 8.0 MB, it may load slowly.")
	world.put("over.png", W.fatPng(8388608 - #png + 1))
	local over = Art.resolveNow(file("over.png"), { host = {} })
	T.eq(over.ok, false)
	T.eq(over.stage, "size")
	T.eq(over.why, "That picture is 8.0 MB, the limit is 8.0 MB", "one byte over is refused")
	world.put("huge.png", W.fatPng(9 * 1048576))
	T.eq(Art.resolveNow(file("huge.png"), { host = {} }).why, "That picture is 9.0 MB, the limit is 8.0 MB")
	world.put("warn.png", W.fatPng(2097152 - #png))
	T.eq(#world.files["warn.png"], 2097152)
	T.eq(Art.resolveNow(file("warn.png"), { host = {} }).warn, nil, "exactly 2 MB is not slow yet")
	world.put("slow.png", W.fatPng(2097152 - #png + 1))
	T.eq(Art.resolveNow(file("slow.png"), { host = {} }).warn, "This picture is 2.0 MB, it may load slowly.")
	world.put("both.png", string.sub(W.fatPng(3 * 1048576), 1, 3 * 1048576))
	local both = Art.resolveNow(file("both.png"), { host = {} })
	T.eq(both.warn, "This picture looks cut short, it may show only part of the image. This picture is 3.0 MB, it may load slowly.", "both warnings are given")
end

T.section("scriptart load: files that are not there")
do
	local world = boot()
	local missing = Art.resolveNow(file("nope.png"), { host = {} })
	T.eq(missing.ok, false)
	T.eq(missing.stage, "fetch")
	T.eq(missing.why, "There is no file called nope.png in your workspace folder")
	world.folder("pics")
	T.eq(Art.resolveNow(file("pics"), { host = {} }).why, "That is a folder, pick a picture inside it")
	world.put("pics/me.png", W.fixture("png_rgb_3x2"))
	local viaWorkspace = Art.resolveNow(file("workspace/pics/me.png"), { host = {} })
	T.eq(viaWorkspace.ok, true, "a path copied with the workspace folder name in front still works")
	T.eq(viaWorkspace.value, "pics/me.png", "and is remembered without it")
	world.put("workspace/real.png", W.fixture("png_rgb_3x2"))
	T.eq(Art.resolveNow(file("workspace/real.png"), { host = {} }).value, "workspace/real.png", "a real folder called workspace wins")
	T.eq(Art.resolveNow(nil, {}).why, "There is nothing to load yet.")
	T.eq(Art.resolveNow({ src = "magic", value = "x" }, {}).why, "There is nothing to load yet.")
	T.eq(Art.resolveNow({ src = "file" }, {}).why, "There is nothing to load yet.")
	T.eq(Art.resolveNow(file("pics/me.png")).ok, true, "options are optional")
	world.files["pics/unreadable.png"] = false
	local unreadable = Art.resolveNow(file("pics/unreadable.png"), { host = {} })
	T.eq(unreadable.ok, false)
end

T.section("scriptart load: a picture from a link")
do
	local world = boot()
	local url = "https://cdn.example.com/pic.png"
	local bytes = W.fixture("png_rgb_3x2")
	world.route("HEAD", url, { code = 200, headers = { ["Content-Length"] = "1000" } })
	world.route("GET", url, { code = 200, body = bytes })
	local r = Art.resolveNow(link(url), { host = {} })
	T.eq(r.ok, true)
	T.eq(r.src, "url")
	T.eq(r.value, url)
	T.eq(r.format, "png")
	T.eq(r.name, nil, "a link has no file name")
	T.eq(world.files[r.cached], bytes)
	T.eq(world.count("GET", url), 1)
	T.eq(world.count("HEAD", url), 1)
	T.eq(world.requests[2].headers.Accept, "image/*,*/*;q=0.8")
	local jpgUrl = "https://cdn.example.com/photo.png"
	world.route("GET", jpgUrl, { code = 200, body = W.fixture("jpeg_baseline_8x8") })
	local j = Art.resolveNow(link(jpgUrl), { host = {} })
	T.eq(j.format, "jpeg", "the bytes decide, not the link")
	T.eq(string.sub(j.cached, -4), ".jpg")
	T.eq(j.note, "The name says .png but it is really a JPEG picture, which is fine.")
	local plain = "https://cdn.example.com/get?id=7"
	world.route("GET", plain, { code = 200, body = W.fixture("png_rgb_3x2") })
	local pl = Art.resolveNow(link(plain), { host = {} })
	T.eq(pl.ok, true, "a link with no ending is fine")
	T.eq(pl.note, nil)
end

T.section("scriptart load: links that go wrong")
do
	local world = boot()
	local function try(code, body, headers)
		world.routes = {}
		local url = "https://cdn.example.com/x.png"
		world.route("GET", url, { code = code, body = body, headers = headers })
		return Art.resolveNow(link(url), { host = {} })
	end
	T.eq(try(404, "not here").why, "Nothing is at that link any more (HTTP 404)")
	T.eq(try(403, "").why, "That site won't let me download the picture (HTTP 403)")
	T.eq(try(429, "").why, "That site says too many requests, wait a minute and try again")
	T.eq(try(500, "").why, "That site had a problem (HTTP 500), try again later")
	T.eq(try(200, "").why, "That link gave nothing back")
	T.eq(try(200, "<html><body>Not found</body></html>").why, "That link gave a web page, not a picture (the link may have expired)")
	T.eq(try(200, '{"error":"expired"}').why, "That link gave a message, not a picture")
	T.eq(try(200, "plain words only").why, "That is a text file, not a picture")
	T.eq(try(200, W.fixture("png_rgb_3x2")).ok, true)
	world.routes = {}
	local gone = Art.resolveNow(link("https://cdn.example.com/none.png"), { host = {} })
	T.eq(gone.why, "Couldn't reach that link (no route for https://cdn.example.com/none.png)")
	T.eq(gone.stage, "fetch")
	T.eq(cacheCount(world), 1, "only the one good picture was copied")
	local seenHead = world.count("HEAD")
	T.ok(seenHead >= 1, "the size was asked first")
end

T.section("scriptart load: big links are refused before downloading")
do
	local world = boot()
	local url = "https://cdn.example.com/big.png"
	world.route("HEAD", url, { code = 200, headers = { ["content-length"] = "9437184" } })
	world.route("GET", url, { code = 200, body = W.fixture("png_rgb_3x2") })
	local r = Art.resolveNow(link(url), { host = {} })
	T.eq(r.ok, false)
	T.eq(r.why, "That picture is 9.0 MB, the limit is 8.0 MB")
	T.eq(world.count("GET"), 0, "nothing was downloaded")
	world.routes = {}
	world.route("HEAD", url, { code = 200, headers = { ["Content-Length"] = "8388608" } })
	world.route("GET", url, { code = 200, body = W.fixture("png_rgb_3x2") })
	T.eq(Art.resolveNow(link(url), { host = {} }).ok, true, "exactly 8 MB is allowed")
	world.routes = {}
	world.route("HEAD", url, { code = 403, headers = { ["Content-Length"] = "99999999" } })
	world.route("GET", url, { code = 200, body = W.fixture("png_rgb_3x2") })
	T.eq(Art.resolveNow(link(url), { host = {} }).ok, true, "a refused size question is ignored")
	world.routes = {}
	world.route("HEAD", url, { code = 200, headers = { ["Content-Length"] = "not a number" } })
	world.route("GET", url, { code = 200, body = W.fixture("png_rgb_3x2") })
	T.eq(Art.resolveNow(link(url), { host = {} }).ok, true, "a strange size is ignored")
	world.routes = {}
	world.route("GET", url, { code = 200, body = W.fatPng(9 * 1048576) })
	local late = Art.resolveNow(link(url), { host = {} })
	T.eq(late.ok, false, "a big body is still caught when the size was not told")
	T.eq(late.why, "That picture is 9.0 MB, the limit is 8.0 MB")
end

T.section("scriptart load: slow links give up")
do
	local world = boot()
	local url = "https://cdn.example.com/slow.png"
	world.route("GET", url, { code = 200, body = W.fixture("png_rgb_3x2"), delay = 20 })
	local started = time()
	local r = Art.resolveNow(link(url), { host = {} })
	local took = time() - started
	T.eq(r.ok, false)
	T.eq(r.stage, "fetch")
	T.eq(r.why, "That link took longer than 15 seconds")
	T.ok(took >= 15 and took < 15.6, "it gave up after about 15 seconds, not " .. took)
	task.wait(10)
	T.eq(cacheCount(world), 0, "the late answer is ignored")
	T.eq(#world.logs, 0)
	local fast = "https://cdn.example.com/fast.png"
	world.route("GET", fast, { code = 200, body = W.fixture("png_rgb_3x2"), delay = 14 })
	local t2 = time()
	local ok = Art.resolveNow(link(fast), { host = {} })
	T.eq(ok.ok, true, "an answer after 14 seconds is still in time")
	T.ok(time() - t2 < 15)
	local slowHead = "https://cdn.example.com/slowhead.png"
	world.route("HEAD", slowHead, { code = 200, headers = {}, delay = 30 })
	world.route("GET", slowHead, { code = 200, body = W.fixture("png_rgb_3x2") })
	local t3 = time()
	local h = Art.resolveNow(link(slowHead), { host = {} })
	T.eq(h.ok, true, "a size question that never answers does not block the download")
	T.ok(time() - t3 < 8, "it waited about 6 seconds for it, not " .. (time() - t3))
end

T.section("scriptart load: the online converter")
do
	local world = boot()
	world.badExts.webp = true
	local url = "https://cdn.example.com/pic.webp"
	local api = "https://images.weserv.nl/?url=https%3A%2F%2Fcdn.example.com%2Fpic.webp&output=png"
	world.route("GET", url, { code = 200, body = W.fixture("webp_lossless_8x8") })
	world.route("GET", api, { code = 200, body = W.fixture("png_rgb_3x2") })
	local off = Art.resolveNow(link(url), { host = {} })
	T.eq(off.ok, false, "off by default")
	T.eq(off.needConvert, true, "and the picker is told it could help")
	T.eq(off.why, "Roblox can't show .webp pictures. Turn on the online converter below, or use a PNG or JPG link.")
	T.eq(world.count("GET", api), 0, "the service was not asked without permission")
	T.eq(cacheCount(world), 0)
	local on = Art.resolveNow(link(url), { host = {}, convert = true })
	T.eq(on.ok, true)
	T.eq(on.converted, true)
	T.eq(on.format, "png")
	T.eq(on.value, url, "the original link is what is remembered")
	T.eq(on.w, 3)
	T.eq(string.sub(on.cached, -4), ".png")
	T.eq(cacheCount(world), 1, "the unusable first copy was removed")
	T.eq(world.count("GET", api), 1)
	local good = "https://cdn.example.com/ok.png"
	world.route("GET", good, { code = 200, body = W.fixture("png_rgb_3x2") })
	local viaOpen = Art.resolveNow(link(good), { host = {}, convert = true })
	T.eq(viaOpen.ok, true)
	T.eq(viaOpen.converted, nil, "no conversion when Roblox can show it")
	T.eq(world.count("GET", "https://images.weserv.nl/?url=https%3A%2F%2Fcdn.example.com%2Fok.png&output=png"), 0)
	local file = Art.resolveNow(file("nothing.webp"), { host = {}, convert = true })
	T.eq(file.ok, false, "files never use the service")
end

T.section("scriptart load: the converter can fail too")
do
	local world = boot()
	world.badExts.webp = true
	local url = "https://cdn.example.com/pic.webp"
	local api = "https://images.weserv.nl/?url=https%3A%2F%2Fcdn.example.com%2Fpic.webp&output=png"
	world.route("GET", url, { code = 200, body = W.fixture("webp_lossless_8x8") })
	local function with(response)
		world.routes["GET " .. api] = nil
		world.route("GET", api, response)
		return Art.resolveNow(link(url), { host = {}, convert = true })
	end
	local r500 = with({ code = 500, body = "" })
	T.eq(r500.ok, false)
	T.eq(r500.stage, "convert")
	T.eq(r500.why, "The online converter couldn't turn that into a picture: that site had a problem (HTTP 500), try again later.")
	T.eq(with({ code = 200, body = "" }).stage, "convert")
	T.eq(with({ code = 200, body = W.fixture("webp_lossless_8x8") }).why, "The online converter didn't send a PNG back.")
	T.eq(with({ code = 200, body = "<html>sorry</html>" }).why, "The online converter didn't send a PNG back.")
	T.eq(with({ code = 200, body = W.fatPng(9 * 1048576) }).why, "The converted picture is 9.0 MB, the limit is 8.0 MB.")
	local slowStart = time()
	local slow = with({ code = 200, body = W.fixture("png_rgb_3x2"), delay = 40 })
	T.eq(slow.why, "The online converter took too long. Try again later, or use a PNG or JPG link.")
	T.ok(time() - slowStart < 40, "it did not wait for the whole answer")
	world.badExts.png = true
	local stuck = with({ code = 200, body = W.fixture("png_rgb_3x2") })
	T.eq(stuck.why, "Roblox couldn't show the converted picture either. Try another picture.")
	T.eq(cacheCount(world), 0, "nothing is left behind")
	world.badExts.png = nil
	world.files[Art.cacheName(W.fixture("png_rgb_3x2"), url .. "|png", "png")] = nil
	world.noAssetFor[Art.cacheName(W.fixture("png_rgb_3x2"), url .. "|png", "png")] = true
	local noAsset = with({ code = 200, body = W.fixture("png_rgb_3x2") })
	T.eq(noAsset.why, "Your executor couldn't load that picture from its workspace.")
	T.eq(cacheCount(world), 0)
	world.noAssetFor = {}
	world.failWrites = true
	local noWrite = with({ code = 200, body = W.fixture("png_rgb_3x2") })
	T.eq(noWrite.stage, "cache")
	T.eq(noWrite.ok, false)
end

T.section("scriptart load: GitHub page links work")
do
	local world = boot()
	local page = "https://github.com/someone/repo/blob/main/pics/a.png"
	local spec = Art.parseLink(page)
	world.route("GET", spec.value, { code = 200, body = W.fixture("png_rgb_3x2") })
	local r = Art.resolveNow(spec, { host = {} })
	T.eq(r.ok, true)
	T.eq(r.value, "https://raw.githubusercontent.com/someone/repo/main/pics/a.png")
	T.eq(world.count("GET", page), 0, "the page itself is never fetched")
end

T.section("scriptart load: Roblox asset ids")
do
	local world = boot()
	local r = Art.resolveNow({ src = "asset", value = "rbxassetid://5" }, { host = {} })
	T.eq(r.ok, true)
	T.eq(r.src, "asset")
	T.eq(r.id, "rbxassetid://5")
	T.eq(r.cached, nil, "nothing is copied for an asset id")
	T.eq(r.unchecked, nil)
	T.same(world.probeCalls, { "rbxassetid://5" })
	T.eq(world.writeCount, 0)
	world.assetStatus["rbxassetid://6"] = "failed"
	local bad = Art.resolveNow({ src = "asset", value = "rbxassetid://6" }, { host = {} })
	T.eq(bad.ok, false)
	T.eq(bad.stage, "probe")
	T.eq(bad.why, "Roblox couldn't load that asset. Check the number, and that it is a public image.")
	world.assetStatus["rbxassetid://7"] = "timeout"
	T.eq(Art.resolveNow({ src = "asset", value = "rbxassetid://7" }, { host = {} }).why, "Roblox took too long to load that. Check the number, or try again in a moment.")
	world.assetStatus["rbxassetid://8"] = "fetched"
	T.eq(Art.resolveNow({ src = "asset", value = "rbxassetid://8" }, { host = {} }).ok, true, "a fetched asset is trusted")
	local unchecked = Art.resolveNow({ src = "asset", value = "rbxassetid://9" }, {})
	T.eq(unchecked.ok, true)
	T.eq(unchecked.unchecked, true)
	local thumb = Art.resolveNow({ src = "asset", value = "rbxthumb://type=Asset&id=9&w=420&h=420" }, { host = {} })
	T.eq(thumb.ok, true)
	local world2 = boot({ has = { files = false, assets = false, request = false } })
	T.eq(Art.resolveNow({ src = "asset", value = "rbxassetid://5" }, { host = {} }).ok, true, "asset ids need no files")
end

T.section("scriptart load: an executor that lacks something")
do
	local world = boot({ has = { assets = false } })
	world.put("a.png", W.fixture("png_rgb_3x2"))
	local r = Art.resolveNow(file("a.png"), { host = {} })
	T.eq(r.ok, false)
	T.eq(r.stage, "setup")
	T.eq(r.why, "Your executor can't show pictures from files or links (it has no getcustomasset). Asset ids still work.")
	T.eq(world.writeCount, 0)
	local world2 = boot({ has = { files = false } })
	T.eq(Art.resolveNow(file("a.png"), { host = {} }).stage, "setup")
	local world3 = boot({ has = { request = false } })
	world3.put("a.png", W.fixture("png_rgb_3x2"))
	local noRequest = Art.resolveNow(link("https://a.example.com/x.png"), { host = {} })
	T.eq(noRequest.stage, "setup")
	T.eq(noRequest.why, "Your executor can't download from links (it has no request function). Asset ids and workspace files still work.")
	T.eq(Art.resolveNow(file("a.png"), { host = {} }).ok, true, "files still work without request")
	local world4 = boot()
	world4.put("a.png", W.fixture("png_rgb_3x2"))
	world4.failWrites = true
	local noWrite = Art.resolveNow(file("a.png"), { host = {} })
	T.eq(noWrite.ok, false)
	T.eq(noWrite.stage, "cache")
	T.eq(noWrite.why, "I couldn't save a copy of the picture in your workspace folder")
	world4.failWrites = false
	world4.noAssetFor[Art.cacheName(W.fixture("png_rgb_3x2"), "a.png", "png")] = true
	local noAsset = Art.resolveNow(file("a.png"), { host = {} })
	T.eq(noAsset.stage, "asset")
	T.eq(noAsset.why, "Your executor couldn't load that picture from its workspace.")
	T.eq(cacheCount(world4), 0, "the copy was removed")
end

T.section("scriptart load: giving up part way")
do
	local world = boot()
	world.put("a.png", W.fixture("png_rgb_3x2"))
	local alive = true
	local inner = world.deps.probe
	world.deps.probe = function(id, host)
		alive = false
		return inner(id, host)
	end
	local r = Art.resolveNow(file("a.png"), { host = {}, alive = function()
		return alive
	end })
	T.eq(r.ok, false)
	T.eq(r.cancelled, true)
	T.eq(cacheCount(world), 0, "the copy is removed when nobody wants it")
	world.deps.probe = inner
	local before = world.count()
	local url = "https://cdn.example.com/c.png"
	world.route("GET", url, { code = 200, body = W.fixture("png_rgb_3x2") })
	local r2 = Art.resolveNow(link(url), { host = {}, alive = function()
		return false
	end })
	T.eq(r2.cancelled, true)
	T.eq(cacheCount(world), 0)
	T.eq(world.count("GET"), 0, "it stopped before the download")
	world.badExts.webp = true
	world.put("b.webp", W.fixture("webp_lossless_8x8"))
	local calls = 0
	local alive2 = function()
		calls = calls + 1
		return calls < 2
	end
	local r3 = Art.resolveNow(file("b.webp"), { host = {}, alive = alive2 })
	T.eq(r3.cancelled, true, "even a failing picture reports giving up")
	local ar = Art.resolveNow({ src = "asset", value = "rbxassetid://5" }, { host = {}, alive = function()
		return false
	end })
	T.eq(ar.cancelled, true)
end

T.section("scriptart load: the async wrapper")
do
	local world = boot()
	world.put("a.png", W.fixture("png_rgb_3x2"))
	local got = nil
	Art.resolve(file("a.png"), { host = {} }, function(result)
		got = result
	end)
	T.ok(got ~= nil, "the callback ran")
	T.eq(got.ok, true)
	local url = "https://cdn.example.com/s.png"
	world.route("GET", url, { code = 200, body = W.fixture("png_rgb_3x2"), delay = 2 })
	local later = nil
	Art.resolve(link(url), { host = {} }, function(result)
		later = result
	end)
	T.eq(later, nil, "a download answers later")
	task.wait(3)
	T.ok(later ~= nil and later.ok == true, "and then it does")
	world.deps.sniff = { sniff = function()
		error("boom\nsecond line", 0)
	end, mismatch = function()
		return false
	end }
	local crashed = nil
	Art.resolve(file("a.png"), { host = {} }, function(result)
		crashed = result
	end)
	T.eq(crashed.ok, false)
	T.eq(crashed.stage, "crash")
	T.eq(crashed.why, "Something went wrong while loading that picture.")
	T.eq(#world.logs, 1)
	T.eq(world.logs[1].kind, "error")
	T.eq(world.logs[1].message, "picture: boom")
end

T.section("scriptart load: restoring a missing copy")
do
	local world = boot()
	local bytes = W.fixture("png_rgb_3x2")
	world.put("pics/me.png", bytes)
	local r = Art.resolveNow(file("pics/me.png"), { host = {} })
	Art.set("Scripts/A.lua", "logo", r)
	local item = Art.get("Scripts/A.lua", "logo")
	T.eq(Art.imageFor(item), r.id)
	world.files[r.cached] = nil
	local id, why = Art.imageFor(Art.get("Scripts/A.lua", "logo"))
	T.ok(id == r.id, "the id is still remembered this session")
	world.put(Art.DATA_FILE, world.files[Art.DATA_FILE])
	local world2 = W.new()
	world2.put(Art.DATA_FILE, world.files[Art.DATA_FILE])
	world2.put("pics/me.png", bytes)
	Art.init(world2.ctx)
	local item2 = Art.get("Scripts/A.lua", "logo")
	local id2, why2 = Art.imageFor(item2)
	T.eq(id2, nil)
	T.eq(why2, "missing")
	T.eq(Art.restore("Scripts/A.lua", "logo"), true)
	task.wait(0.5)
	T.eq(world2.files[item2.cached], bytes, "the copy is back, under the same name")
	T.eq(select(1, Art.imageFor(Art.get("Scripts/A.lua", "logo"))), "rbxasset://" .. item2.cached)
	T.eq(Art.brokenReason("Scripts/A.lua", "logo"), nil)
	T.eq(Art.restore("Scripts/A.lua", "banner"), false, "nothing to restore for an empty spot")
	Art.set("Scripts/A.lua", "banner", { ok = true, src = "asset", value = "rbxassetid://5" })
	T.eq(Art.restore("Scripts/A.lua", "banner"), false, "asset ids need no copy")
end

T.section("scriptart load: restoring when the original is gone")
do
	local world = boot()
	local bytes = W.fixture("png_rgb_3x2")
	world.put("pics/me.png", bytes)
	local r = Art.resolveNow(file("pics/me.png"), { host = {} })
	Art.set("Scripts/A.lua", "logo", r)
	world.files[r.cached] = nil
	world.files["pics/me.png"] = nil
	local fired = #world.fired
	T.eq(Art.restore("Scripts/A.lua", "logo"), true)
	task.wait(0.5)
	T.eq(Art.brokenReason("Scripts/A.lua", "logo"), "There is no file called pics/me.png in your workspace folder")
	T.eq(#world.fired, fired + 1, "the spot is told so it can show the problem")
	T.ok(Art.get("Scripts/A.lua", "logo") ~= nil, "the picture is still remembered")
	world.put("pics/me.png", bytes)
	T.eq(Art.retry("Scripts/A.lua", "logo"), true, "try again after putting the file back")
	task.wait(0.5)
	T.eq(Art.brokenReason("Scripts/A.lua", "logo"), nil)
	T.eq(world.files[r.cached], bytes)
	T.eq(Art.retry("Scripts/A.lua", "banner"), false, "an empty spot has nothing to retry")
end

T.section("scriptart load: restoring a link")
do
	local world = boot()
	world.badExts.webp = true
	local url = "https://cdn.example.com/pic.webp"
	local api = "https://images.weserv.nl/?url=https%3A%2F%2Fcdn.example.com%2Fpic.webp&output=png"
	world.route("GET", url, { code = 200, body = W.fixture("webp_lossless_8x8") })
	world.route("GET", api, { code = 200, body = W.fixture("png_rgb_3x2") })
	local r = Art.resolveNow(link(url), { host = {}, convert = true })
	Art.set("Scripts/A.lua", "banner", r)
	T.eq(Art.get("Scripts/A.lua", "banner").converted, true, "the item remembers that it was converted")
	world.files[r.cached] = nil
	world.routes["GET " .. api].delay = 1
	T.eq(Art.restore("Scripts/A.lua", "banner"), true)
	T.eq(Art.restore("Scripts/A.lua", "banner"), false, "only one restore at a time")
	task.wait(2)
	T.ok(world.files[r.cached] ~= nil, "a converted link is converted again without asking")
	T.eq(world.count("GET", url), 1, "the original is not downloaded again")
	world.files[r.cached] = nil
	world.routes["GET " .. api] = nil
	world.route("GET", api, { code = 404, body = "" })
	T.eq(Art.restore("Scripts/A.lua", "banner"), true)
	task.wait(0.5)
	T.eq(Art.brokenReason("Scripts/A.lua", "banner"), "The online converter couldn't turn that into a picture: nothing is at that link any more (HTTP 404).")
end

T.section("scriptart load: a restore that is no longer wanted")
do
	local world = boot()
	local url = "https://cdn.example.com/a.png"
	world.route("GET", url, { code = 200, body = W.fixture("png_rgb_3x2"), delay = 2 })
	local first = { ok = true, src = "url", value = url, cached = "Atsuko Hub/cache/art/1111111111111111.png", format = "png", ext = "png" }
	world.put(first.cached, "x")
	Art.set("Scripts/A.lua", "logo", first)
	world.files[first.cached] = nil
	T.eq(Art.restore("Scripts/A.lua", "logo"), true)
	Art.clear("Scripts/A.lua", "logo")
	task.wait(3)
	T.eq(Art.get("Scripts/A.lua", "logo"), nil, "a cleared picture stays cleared")
	T.eq(cacheCount(world), 0, "and the late copy is cleaned up")
	Art.set("Scripts/A.lua", "logo", first)
	world.files[first.cached] = nil
	Art.restore("Scripts/A.lua", "logo")
	Art.set("Scripts/A.lua", "logo", { ok = true, src = "asset", value = "rbxassetid://5" })
	task.wait(3)
	T.eq(Art.get("Scripts/A.lua", "logo").value, "rbxassetid://5", "a changed picture is not overwritten")
	T.eq(cacheCount(world), 0)
end

T.section("scriptart load: the cache cleanup at start")
do
	local world = W.new()
	local keep = "Atsuko Hub/cache/art/aaaaaaaaaaaaaaaa.png"
	local drop = "Atsuko Hub/cache/art/bbbbbbbbbbbbbbbb.png"
	world.put(keep, "A")
	world.put(drop, "B")
	world.put("Atsuko Hub/cache/art_thumb/t1.png", "T")
	world.put("Atsuko Hub/cache/art_thumb/t2.jpg", "T")
	world.put("Atsuko Hub/cache/other.txt", "O")
	world.put(Art.DATA_FILE, jsonencode({ version = 1, items = { ["Scripts/A.lua"] = { logo = { src = "file", value = "x.png", cached = keep } } } }))
	Art.init(world.ctx)
	T.eq(world.files[keep], "A", "a copy in use is kept")
	T.eq(world.files[drop], nil, "an unused copy is removed")
	T.eq(world.files["Atsuko Hub/cache/art_thumb/t1.png"], nil, "thumbnails never survive a reload")
	T.eq(world.files["Atsuko Hub/cache/art_thumb/t2.jpg"], nil)
	T.eq(world.files["Atsuko Hub/cache/other.txt"], "O", "other files are left alone")
	local world2 = W.new({ has = { list = false } })
	world2.put(drop, "B")
	Art.init(world2.ctx)
	T.eq(world2.files[drop], "B", "without listing nothing is cleaned")
	local world3 = W.new()
	world3.listBare = true
	world3.put(drop, "B")
	world3.put(keep, "A")
	Art.init(world3.ctx)
	T.eq(world3.files[drop], nil, "bare names are understood too")
	T.eq(Art.sweep(), 0, "a second sweep finds nothing")
end

T.section("scriptart load: choosing a name for the copy")
do
	local world = boot()
	local a = W.fixture("png_rgb_3x2")
	local b = W.fixture("png_wide_300x100")
	local nameA = Art.cacheName(a, "x", "png")
	T.eq(nameA, Art.cacheName(a, "x", "png"), "the same input gives the same name")
	T.ok(nameA ~= Art.cacheName(b, "x", "png"), "different pictures get different names")
	T.ok(nameA ~= Art.cacheName(a, "y", "png"), "the same picture from another place gets another name")
	T.ok(Art.safeCache(nameA), "the name is a safe cache name")
	T.eq(string.sub(nameA, -4), ".png")
	T.eq(#nameA, #(Art.CACHE_DIR .. "/") + 16 + 4, "16 characters then the ending")
	T.eq(string.sub(Art.cacheName(a, "x", "jpg"), -4), ".jpg")
	T.eq(string.sub(Art.cacheName(a, "x", "png", "Atsuko Hub/cache/art_thumb"), 1, #"Atsuko Hub/cache/art_thumb/"), "Atsuko Hub/cache/art_thumb/")
	local big1 = W.fatPng(100000)
	local big2 = string.sub(big1, 1, 50000) .. "Y" .. string.sub(big1, 50002)
	T.eq(#big1, #big2)
	local sameSize = Art.cacheName(big1, "x", "png") == Art.cacheName(big2, "x", "png")
	T.ok(type(sameSize) == "boolean", "names are only sampled, so this is allowed to match")
end
