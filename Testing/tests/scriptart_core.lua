local W = loadmodule("Testing/mocks/art_world.lua")
local Art = loadmodule("Hub/modules/scriptart.lua")

local function boot(opts)
	local world = W.new(opts)
	Art.init(world.ctx)
	return world
end

T.section("scriptart: picture links")
do
	local p = Art.parseLink("12345")
	T.same(p, { src = "asset", value = "rbxassetid://12345" }, "a plain number is an asset id")
	T.same(Art.parseLink("  12345  "), { src = "asset", value = "rbxassetid://12345" }, "spaces around it are fine")
	T.same(Art.parseLink("RBXASSETID://99"), { src = "asset", value = "rbxassetid://99" }, "the scheme is not case sensitive")
	T.same(Art.parseLink("rbxassetid://7"), { src = "asset", value = "rbxassetid://7" })
	T.eq(Art.parseLink("rbxassetid://"), nil)
	T.eq(select(2, Art.parseLink("rbxassetid://")), "an asset id needs a number after rbxassetid://", "no digits is refused")
	T.eq(Art.parseLink("rbxassetid://12ab"), nil)
	T.eq(select(2, Art.parseLink("rbxassetid://12ab")), "an asset id needs a number after rbxassetid://")
	T.eq(Art.parseLink(string.rep("9", 20)), nil, "20 digits is too long")
	T.eq(Art.parseLink(string.rep("9", 19)).value, "rbxassetid://" .. string.rep("9", 19), "19 digits is the longest")
	T.eq(Art.parseLink("rbxassetid://" .. string.rep("9", 20)), nil)
	T.eq(Art.parseLink("rbxthumb://type=Asset&id=123&w=420&h=420").value, "rbxthumb://type=Asset&id=123&w=420&h=420")
	T.eq(Art.parseLink("RBXTHUMB://type=Asset&id=123").value, "rbxthumb://type=Asset&id=123", "only the scheme is lowered")
	T.eq(Art.parseLink("rbxthumb://type=Asset"), nil, "a thumbnail needs an id")
	T.eq(Art.parseLink("rbxthumb://id=5"), nil, "a thumbnail needs a type")
	T.eq(Art.parseLink("rbxthumb://type=Asset&id=x"), nil, "the id must be a number")
	local _, httpWhy = Art.parseLink("http://x.com/a.png")
	T.eq(httpWhy, "use a link that starts with https://")
	local _, ftpWhy = Art.parseLink("ftp://x.com/a")
	T.ok(string.find(ftpWhy, "ftp:", 1, true) ~= nil, "other schemes are named: " .. tostring(ftpWhy))
	T.ok(string.find(select(2, Art.parseLink("javascript:alert(1)")), "javascript:", 1, true) ~= nil)
	T.ok(string.find(select(2, Art.parseLink("data:image/png;base64,AAAA")), "data:", 1, true) ~= nil)
	T.ok(string.find(select(2, Art.parseLink("file:///c:/x.png")), "file:", 1, true) ~= nil)
	T.ok(string.find(select(2, Art.parseLink("rbxasset://textures/x.png")), "rbxasset:", 1, true) ~= nil, "Roblox's own content folder is not accepted")
	T.eq(select(2, Art.parseLink("example.com/a.png")), "add https:// in front of the link, or use an asset id")
	T.eq(select(2, Art.parseLink("")), "paste a picture link first")
	T.eq(select(2, Art.parseLink("   ")), "paste a picture link first")
	T.eq(select(2, Art.parseLink(nil)), "paste a picture link first")
	T.eq(select(2, Art.parseLink("https://")), "that link has no site name in it")
	T.eq(select(2, Art.parseLink("https:///a.png")), "that link has no site name in it")
	T.eq(select(2, Art.parseLink("https://pic/a.png")), "that link doesn't look complete")
	T.eq(select(2, Art.parseLink("https://.com/a.png")), "that link doesn't look complete")
	T.eq(select(2, Art.parseLink("https://site./a.png")), "that link doesn't look complete")
	T.eq(select(2, Art.parseLink("https://cdn.example.com/a b.png")), "a picture link can't have spaces in it")
	T.eq(select(2, Art.parseLink("https://cdn.example.com/" .. string.rep("a", 2000))), "that link is too long")
	local ok = Art.parseLink("https://cdn.example.com/" .. string.rep("a", 1970))
	T.eq(ok and ok.src, "url", "a link just under the limit is fine")
	local discord = Art.parseLink("https://cdn.discordapp.com/attachments/1/2/a.png?ex=1&is=2&hm=3&")
	T.eq(discord.src, "url")
	T.eq(discord.value, "https://cdn.discordapp.com/attachments/1/2/a.png?ex=1&is=2&hm=3&", "the link is kept exactly")
	T.eq(discord.host, "cdn.discordapp.com")
	T.eq(discord.rewritten, false)
	local upper = Art.parseLink("HTTPS://Example.COM/A.PNG")
	T.eq(upper.value, "https://Example.COM/A.PNG", "the path keeps its case")
	T.eq(upper.host, "example.com", "the host is lowered")
	local blob = Art.parseLink("https://github.com/someone/repo/blob/main/pics/a.png")
	T.eq(blob.value, "https://raw.githubusercontent.com/someone/repo/main/pics/a.png", "a GitHub page link becomes the raw file")
	T.eq(blob.rewritten, true)
	T.eq(Art.parseLink("https://GitHub.com/u/r/blob/dev/x.png?raw=true").value, "https://raw.githubusercontent.com/u/r/dev/x.png", "?raw=true is dropped")
	T.eq(Art.parseLink("https://raw.githubusercontent.com/u/r/main/x.png").rewritten, false, "raw links are left alone")
	T.eq(Art.parseLink("https://github.com/u/r").rewritten, false, "a repo page is not rewritten")
end

T.section("scriptart: workspace paths")
do
	T.same(Art.parseFile("pics/me.png"), { src = "file", value = "pics/me.png" })
	T.same(Art.parseFile("  pics\\me.png  "), { src = "file", value = "pics/me.png" }, "backslashes become slashes")
	T.same(Art.parseFile('"pics/me.png"'), { src = "file", value = "pics/me.png" }, "pasted quotes are dropped")
	T.same(Art.parseFile("'pics/me.png'"), { src = "file", value = "pics/me.png" })
	T.same(Art.parseFile("./pics//me.png"), { src = "file", value = "pics/me.png" }, "dots and doubled slashes are tidied")
	T.same(Art.parseFile("me.png"), { src = "file", value = "me.png" })
	T.same(Art.parseFile("kxjqzpw"), { src = "file", value = "kxjqzpw" }, "no ending is fine")
	T.same(Art.parseFile("a/./b.png"), { src = "file", value = "a/b.png" })
	T.same(Art.parseFile("trailing/"), { src = "file", value = "trailing" })
	T.eq(select(2, Art.parseFile("../x.png")), "a path can't go up a folder with ..")
	T.eq(select(2, Art.parseFile("pics/../x.png")), "a path can't go up a folder with ..")
	T.eq(select(2, Art.parseFile("..")), "a path can't go up a folder with ..")
	T.eq(select(2, Art.parseFile("/etc/x.png")), "use a path inside your executor's workspace folder, like pics/me.png")
	T.eq(select(2, Art.parseFile("C:\\Users\\me\\x.png")), "use a path inside your executor's workspace folder, like pics/me.png")
	T.eq(select(2, Art.parseFile("c:/x.png")), "use a path inside your executor's workspace folder, like pics/me.png")
	T.eq(select(2, Art.parseFile("~/x.png")), "use a path inside your executor's workspace folder, like pics/me.png")
	T.eq(select(2, Art.parseFile("https://a.com/x.png")), "that looks like a link, use the Link tab for links")
	T.eq(select(2, Art.parseFile("rbxassetid://5")), "that looks like a link, use the Link tab for links")
	T.eq(select(2, Art.parseFile("")), "type a file name or path first")
	T.eq(select(2, Art.parseFile("   ")), "type a file name or path first")
	T.eq(select(2, Art.parseFile(nil)), "type a file name or path first")
	T.eq(select(2, Art.parseFile(".")), "type a file name or path first")
	T.eq(select(2, Art.parseFile("./")), "type a file name or path first")
	T.eq(select(2, Art.parseFile("\"\"")), "type a file name or path first")
	T.eq(select(2, Art.parseFile("a\1b.png")), "that path has a character that can't be in a file name")
	T.eq(select(2, Art.parseFile("a\nb.png")), "that path has a character that can't be in a file name")
	T.eq(select(2, Art.parseFile(string.rep("a", 241))), "that path is too long")
	T.eq(Art.parseFile(string.rep("a", 240)).src, "file", "240 characters is the longest")
	T.eq(Art.withoutWorkspace("workspace/pics/a.png"), "pics/a.png")
	T.eq(Art.withoutWorkspace("Workspace/x"), "x")
	T.eq(Art.withoutWorkspace("WORKSPACE/x/y"), "x/y")
	T.eq(Art.withoutWorkspace("workspacex/y"), nil)
	T.eq(Art.withoutWorkspace("workspace"), nil)
	T.eq(Art.withoutWorkspace("workspace/"), nil)
	T.eq(Art.withoutWorkspace("pics/workspace/a.png"), nil)
end

T.section("scriptart: sizes of the two spots")
do
	local m = Art.metrics(320)
	T.eq(m.width, 320)
	T.eq(m.pad, 8)
	T.eq(m.bannerW, 304)
	T.eq(m.bannerH, 101, "304 / 3 rounded")
	T.eq(m.logo, 72)
	T.eq(m.logoX, 18)
	T.eq(m.logoY, 73, "the logo hangs half over the banner's bottom edge")
	T.eq(m.textX, 102)
	T.eq(m.nameY, 117)
	T.eq(m.subY, 140)
	T.eq(m.heartY, 119)
	T.eq(m.chipX, 16)
	T.eq(m.chipY, 16)
	T.eq(m.height, 165)
	T.ok(m.logoY + m.logo <= m.height - 8, "the logo stays inside the card")
	T.ok(m.subY + 16 <= m.height - 8, "the words stay inside the card")
	T.ok(m.logoY < m.pad + m.bannerH and m.logoY + m.logo > m.pad + m.bannerH, "the logo overlaps the banner's bottom edge")
	for _, width in ipairs({ 120, 180, 240, 300, 333, 400, 520, 900 }) do
		local x = Art.metrics(width)
		T.eq(x.bannerW, width - 16, width .. " banner width")
		T.ok(math.abs(x.bannerW / x.bannerH - 3) < 0.05 * 3, width .. " banner is about 3:1")
		T.eq(x.height, 8 + x.bannerH + 56, width .. " height")
		T.ok(x.logoY + x.logo < x.height, width .. " logo fits")
	end
	T.eq(Art.metrics(100).width, 120, "very narrow is lifted to the smallest size")
	T.eq(Art.metrics(0).width, 120)
	T.eq(Art.metrics(nil).width, 120)
	T.eq(Art.metrics("300").width, 300, "a number given as text still works")
end

T.section("scriptart: sizes in words")
do
	T.eq(Art.fmtBytes(0), "")
	T.eq(Art.fmtBytes(nil), "")
	T.eq(Art.fmtBytes(-5), "")
	T.eq(Art.fmtBytes(1), "1 B")
	T.eq(Art.fmtBytes(1023), "1023 B")
	T.eq(Art.fmtBytes(1024), "1 KB")
	T.eq(Art.fmtBytes(2048), "2 KB")
	T.eq(Art.fmtBytes(348160), "340 KB")
	T.eq(Art.fmtBytes(1048575), "1024 KB")
	T.eq(Art.fmtBytes(1048576), "1.0 MB")
	T.eq(Art.fmtBytes(8388608), "8.0 MB")
	T.eq(Art.fmtBytes(9437184), "9.0 MB")
end

T.section("scriptart: the online converter address")
do
	T.eq(Art.urlEncode("https://a.com/x y.png?a=b&c=d"), "https%3A%2F%2Fa.com%2Fx%20y.png%3Fa%3Db%26c%3Dd")
	T.eq(Art.urlEncode("abc-DEF_1.2~3"), "abc-DEF_1.2~3", "unreserved characters stay")
	T.eq(Art.urlEncode("100%"), "100%25")
	T.eq(Art.urlEncode(""), "")
	local template = "https://images.weserv.nl/?url={url}&output=png"
	T.eq(Art.converterUrl(template, "https://a.com/x.webp"), "https://images.weserv.nl/?url=https%3A%2F%2Fa.com%2Fx.webp&output=png")
	T.eq(Art.converterUrl(template, "https://a.com/100%.webp"), "https://images.weserv.nl/?url=https%3A%2F%2Fa.com%2F100%25.webp&output=png", "a percent sign in the link is not read as a pattern")
	T.eq(Art.converterUrl("https://svc.example/convert", "https://a.com/x"), nil, "no {url} slot")
	T.eq(Art.converterUrl("http://svc.example/?u={url}", "https://a.com/x"), nil, "the service itself must be https")
	T.eq(Art.converterUrl(nil, "https://a.com/x"), nil)
	T.eq(Art.converterUrl(template, nil), nil)
	local d = Art.cleanConverter(nil)
	T.eq(d.name, "images.weserv.nl")
	T.eq(d.url, Art.DEFAULT_CONVERTER.url)
	T.ok(#d.note > 40, "the note explains the third party")
	T.ok(string.find(d.note, "images.weserv.nl", 1, true) ~= nil)
	local custom = Art.cleanConverter({ name = "My service", url = "https://svc.example/convert?u={url}", note = "my note" })
	T.same(custom, { name = "My service", url = "https://svc.example/convert?u={url}", note = "my note" })
	local badUrl = Art.cleanConverter({ name = "X", url = "http://bad/{url}", note = "n" })
	T.eq(badUrl.url, Art.DEFAULT_CONVERTER.url, "an http converter is replaced by the default")
	T.eq(badUrl.name, "X")
	T.eq(Art.cleanConverter({ url = "https://nope.example/no-slot" }).url, Art.DEFAULT_CONVERTER.url, "a converter without a slot is replaced")
	T.eq(Art.cleanConverter({ url = "https://has space.example/{url}" }).url, Art.DEFAULT_CONVERTER.url)
	T.eq(Art.cleanConverter({ url = "https://x.example/" .. string.rep("a", 300) .. "{url}" }).url, Art.DEFAULT_CONVERTER.url, "a very long address is replaced")
	local unnamed = Art.cleanConverter({ url = "https://svc.example/convert?u={url}" })
	T.eq(unnamed.name, "svc.example", "the name falls back to the host")
	T.ok(string.find(unnamed.note, "svc.example", 1, true) ~= nil, "the fallback note names the service")
	T.eq(Art.cleanConverter({ name = string.rep("n", 61), url = "https://svc.example/{url}" }).name, "svc.example")
	T.eq(Art.cleanConverter({ name = string.rep("n", 60), url = "https://svc.example/{url}" }).name, string.rep("n", 60))
	T.eq(#Art.cleanConverter({ note = string.rep("z", 401) }).note < 401, true, "a very long note is replaced")
	T.eq(Art.cleanConverter({ note = string.rep("z", 400) }).note, string.rep("z", 400))
	T.eq(Art.cleanConverter("text").url, Art.DEFAULT_CONVERTER.url)
	T.eq(Art.cleanConverter({ name = 5, url = 6, note = 7 }).name, "images.weserv.nl")
end

T.section("scriptart: why a download failed")
do
	T.eq(Art.httpWhy(0, "timeout reached\nmore"), "couldn't reach that link (timeout reached)")
	T.eq(Art.httpWhy(0, ""), "couldn't reach that link")
	T.eq(Art.httpWhy(0, nil), "couldn't reach that link")
	T.eq(Art.httpWhy(0, string.rep("x", 121)), "couldn't reach that link")
	T.eq(Art.httpWhy(0, string.rep("x", 120)), "couldn't reach that link (" .. string.rep("x", 120) .. ")")
	T.eq(Art.httpWhy(401), "that site won't let me download the picture (HTTP 401)")
	T.eq(Art.httpWhy(403), "that site won't let me download the picture (HTTP 403)")
	T.eq(Art.httpWhy(404), "nothing is at that link any more (HTTP 404)")
	T.eq(Art.httpWhy(410), "nothing is at that link any more (HTTP 410)")
	T.eq(Art.httpWhy(429), "that site says too many requests, wait a minute and try again")
	T.eq(Art.httpWhy(500), "that site had a problem (HTTP 500), try again later")
	T.eq(Art.httpWhy(503), "that site had a problem (HTTP 503), try again later")
	T.eq(Art.httpWhy(302), "that site answered HTTP 302")
	T.eq(Art.httpWhy(400), "that site answered HTTP 400")
	T.eq(Art.httpWhy("404"), "nothing is at that link any more (HTTP 404)", "a code given as text works")
	T.eq(Art.httpWhy(nil, "boom"), "couldn't reach that link (boom)")
end

T.section("scriptart: when Roblox can't show a picture")
do
	T.eq(Art.cantShow({ ext = "webp", format = "webp" }, "file"), "Roblox can't show .webp pictures. Convert it to PNG or JPG and pick it again.")
	T.eq(Art.cantShow({ ext = "avif", format = "avif" }, "file"), "Roblox can't show .avif pictures. Convert it to PNG or JPG and pick it again.")
	T.eq(Art.cantShow({ ext = "webp" }, "url"), "Roblox can't show .webp pictures. Turn on the online converter below, or use a PNG or JPG link.")
	T.eq(Art.cantShow({ format = "gif" }, "file"), "Roblox can't show .gif pictures. Convert it to PNG or JPG and pick it again.", "the format name is used when there is no ending")
	T.eq(Art.cantShow(nil, "file"), "Roblox can't show .this pictures. Convert it to PNG or JPG and pick it again.")
	local webp = { format = "webp", ext = "webp", label = "WebP" }
	local png = { format = "png", ext = "png", label = "PNG" }
	local jpeg = { format = "jpeg", ext = "jpg", label = "JPEG" }
	T.eq(Art.probeFailure("failed", webp, "file", false), Art.cantShow(webp, "file"))
	T.eq(Art.probeFailure("timeout", webp, "url", false), Art.cantShow(webp, "url"))
	T.eq(Art.probeFailure("failed", png, "file", true), "That picture looks cut off, so Roblox can't show it. Download it again and pick it again.", "a cut-off file is named as such")
	T.eq(Art.probeFailure("failed", webp, "file", true), "That picture looks cut off, so Roblox can't show it. Download it again and pick it again.")
	T.eq(Art.probeFailure("failed", png, "file", false), "Roblox couldn't show that picture even though it looks like a normal PNG. It may be damaged or too big, try another one.")
	T.eq(Art.probeFailure("failed", jpeg, "url", false), "Roblox couldn't show that picture even though it looks like a normal JPEG. It may be damaged or too big, try another one.")
	T.eq(Art.probeFailure("timeout", png, "file", false), "Roblox took too long to show that picture. It may be too big, try a smaller one.")
	T.eq(Art.probeFailure("failed", nil, "asset"), "Roblox couldn't load that asset. Check the number, and that it is a public image.")
	T.eq(Art.probeFailure("timeout", nil, "asset"), "Roblox took too long to load that. Check the number, or try again in a moment.")
	T.eq(Art.judge("loaded", "png", false), true)
	T.eq(Art.judge("loaded", "webp", false), true, "a picture Roblox says it loaded is fine whatever the format")
	T.eq(Art.judge("unchecked", "webp", false), true)
	T.eq(Art.judge("fetched", "png", false), true, "fetched PNG and JPEG are trusted")
	T.eq(Art.judge("fetched", "jpeg", false), true)
	T.eq(Art.judge("fetched", "webp", false), false, "fetched is not enough for other formats")
	T.eq(Art.judge("fetched", "gif", false), false)
	T.eq(Art.judge("fetched", nil, true), true, "a fetched asset id is trusted")
	T.eq(Art.judge("fetched", "webp", true), true)
	T.eq(Art.judge("failed", "png", false), false)
	T.eq(Art.judge("failed", nil, true), false)
	T.eq(Art.judge("timeout", "png", false), false)
	T.eq(Art.judge("timeout", nil, true), false)
	T.eq(Art.judge(nil, "png", false), false)
	T.eq(Art.judge("surprise", "png", false), false)
end

T.section("scriptart: describing a picture")
do
	T.eq(Art.describe({ src = "asset" }), "Roblox asset")
	T.eq(Art.describe({ src = "file", label = "PNG", w = 512, h = 256, size = 348160 }), "PNG  ·  512 x 256  ·  340 KB")
	T.eq(Art.describe({ src = "url", label = "JPEG", w = 8, h = 8 }), "JPEG  ·  8 x 8")
	T.eq(Art.describe({ src = "url", format = "webp", size = 2048 }), "WEBP  ·  2 KB", "the format name is used when there is no label")
	T.eq(Art.describe({ src = "url" }), "?")
	T.eq(Art.describe(nil), "")
	T.eq(Art.describe("x"), "")
end

T.section("scriptart: which cache names are safe")
do
	T.eq(Art.safeCache("AtsukoHub/cache/art/abc123.png"), true)
	T.eq(Art.safeCache("AtsukoHub/cache/art/0123456789abcdef.jpg"), true)
	T.eq(Art.safeCache("AtsukoHub/cache/art/../x.png"), false)
	T.eq(Art.safeCache("AtsukoHub/cache/art/.."), false)
	T.eq(Art.safeCache("AtsukoHub/cache/art/sub/x.png"), false)
	T.eq(Art.safeCache("AtsukoHub/cache/art/"), false)
	T.eq(Art.safeCache("AtsukoHub/cache/art"), false)
	T.eq(Art.safeCache("AtsukoHub/cache/other/x.png"), false)
	T.eq(Art.safeCache("AtsukoHub/cache/art_thumb/x.png"), false)
	T.eq(Art.safeCache("x.png"), false)
	T.eq(Art.safeCache("/AtsukoHub/cache/art/x.png"), false)
	T.eq(Art.safeCache(""), false)
	T.eq(Art.safeCache(nil), false)
	T.eq(Art.safeCache(5), false)
	T.eq(Art.safeCache("AtsukoHub/cache/art/a..b.png"), false, "two dots in a row are never allowed")
	T.eq(Art.safeCache("AtsukoHub/cache/art/a.b.png"), true, "single dots are fine")
end

T.section("scriptart: arranging a folder")
do
	local function entry(name, folder, size)
		local ext = string.lower(string.match(name, "%.(%w+)$") or "")
		return { name = name, path = "d/" .. name, folder = folder, ext = ext, size = size }
	end
	local list = {
		entry("b", true), entry("A", true), entry("10", true), entry("2", true),
		entry("img2.png", false, 100), entry("img10.png", false, 300), entry("Img1.PNG", false, 300),
		entry("notes.txt", false, 50), entry("noext", false, nil), entry("x.WEBP", false, 10), entry("song.mp3", false, 5), entry("pic.jfif", false, 1),
	}
	local function names(rows)
		local out = {}
		for i, row in ipairs(rows) do
			out[i] = row.name
		end
		return out
	end
	T.same(names(Art.arrange(list, {})), { "2", "10", "A", "b", "Img1.PNG", "img2.png", "img10.png", "noext", "pic.jfif", "x.WEBP" }, "folders first, numbers in order, other files hidden")
	T.same(names(Art.arrange(list, { allFiles = true })), { "2", "10", "A", "b", "Img1.PNG", "img2.png", "img10.png", "noext", "notes.txt", "pic.jfif", "song.mp3", "x.WEBP" }, "all files shows everything")
	T.same(names(Art.arrange(list, { search = "IMG" })), { "Img1.PNG", "img2.png", "img10.png" }, "search ignores case")
	T.same(names(Art.arrange(list, { search = "  img1 " })), { "Img1.PNG", "img10.png" }, "search is trimmed")
	T.same(names(Art.arrange(list, { search = "2" })), { "2", "img2.png" }, "folders match too")
	T.same(names(Art.arrange(list, { search = "zzz" })), {}, "nothing matches")
	T.same(names(Art.arrange(list, { search = "notes" })), {}, "a hidden file stays hidden when searched")
	T.same(names(Art.arrange(list, { search = "notes", allFiles = true })), { "notes.txt" })
	T.same(names(Art.arrange(list, { sort = "size" })), { "2", "10", "A", "b", "Img1.PNG", "img10.png", "img2.png", "x.WEBP", "pic.jfif", "noext" }, "biggest first, then unknown sizes last")
	T.same(names(Art.arrange(list, { sort = "bogus" })), names(Art.arrange(list, {})), "an unknown sort means name")
	T.same(names(Art.arrange({}, {})), {})
	T.same(names(Art.arrange(nil, nil)), {})
	T.eq(#list, 12, "the input list is not changed")
	T.eq(list[1].name, "b")
end

T.section("scriptart: remembering pictures")
do
	local world = boot()
	T.eq(Art.count(), 0)
	T.eq(Art.get("Scripts/A.lua", "logo"), nil)
	local ok, saved = Art.set("Scripts/A.lua", "logo", { ok = true, src = "asset", value = "rbxassetid://5" })
	T.eq(ok, true)
	T.eq(saved, true)
	local item = Art.get("Scripts/A.lua", "logo")
	T.eq(item.src, "asset")
	T.eq(item.value, "rbxassetid://5")
	T.eq(item.at, 1700000000)
	T.eq(Art.count(), 1)
	T.eq(Art.get("Scripts/A.lua", "banner"), nil, "the other spot is untouched")
	T.eq(Art.get("Scripts/B.lua", "logo"), nil, "other scripts are untouched")
	item.value = "changed"
	T.eq(Art.get("Scripts/A.lua", "logo").value, "rbxassetid://5", "get gives a copy")
	T.eq(#world.fired, 1)
	T.same(world.fired[1], { "Scripts/A.lua", "logo" }, "everyone is told")
	local saved1 = jsondecode(world.files[Art.DATA_FILE])
	T.eq(saved1.version, 1)
	T.eq(saved1.items["Scripts/A.lua"].logo.value, "rbxassetid://5")
	T.eq(saved1.items["Scripts/A.lua"].banner, nil)

	Art.set("Scripts/A.lua", "banner", { ok = true, src = "asset", value = "rbxthumb://type=Asset&id=9&w=420&h=420" })
	T.eq(Art.count(), 2)
	T.eq(Art.get("Scripts/A.lua", "logo").value, "rbxassetid://5", "setting the banner keeps the logo")

	local world2 = W.new()
	world2.put(Art.DATA_FILE, world.files[Art.DATA_FILE])
	Art.init(world2.ctx)
	T.eq(Art.count(), 2, "they come back after a reload")
	T.eq(Art.get("Scripts/A.lua", "banner").value, "rbxthumb://type=Asset&id=9&w=420&h=420")
	T.eq(Art.get("Scripts/B.lua", "banner"), nil, "and still do not leak to other scripts")

	T.eq(Art.clear("Scripts/A.lua", "logo"), true)
	T.eq(Art.get("Scripts/A.lua", "logo"), nil)
	T.eq(Art.get("Scripts/A.lua", "banner").value, "rbxthumb://type=Asset&id=9&w=420&h=420", "clearing one spot keeps the other")
	T.eq(Art.clear("Scripts/A.lua", "logo"), false, "clearing an empty spot says so")
	T.eq(Art.clear("Scripts/Z.lua", "logo"), false)
	T.eq(Art.clear("Scripts/A.lua", "banner"), true)
	T.eq(Art.count(), 0)
	local saved2 = jsondecode(world2.files[Art.DATA_FILE])
	T.eq(next(saved2.items), nil, "an empty script is dropped from the file")

	T.eq((Art.set("Scripts/A.lua", "icon", { ok = true, src = "asset", value = "5" })), false, "only the two spots exist")
	T.eq((Art.set("", "logo", { ok = true, src = "asset", value = "rbxassetid://5" })), false)
	T.eq((Art.set(nil, "logo", { ok = true, src = "asset", value = "rbxassetid://5" })), false)
	T.eq((Art.set(string.rep("p", 301), "logo", { ok = true, src = "asset", value = "rbxassetid://5" })), false)
	T.eq((Art.set(string.rep("p", 300), "logo", { ok = true, src = "asset", value = "rbxassetid://5" })), true)
	T.eq((Art.set("Scripts/A.lua", "logo", { ok = false, why = "x" })), false, "a failed picture is not saved")
	T.eq((Art.set("Scripts/A.lua", "logo", nil)), false)
	T.eq((Art.set("Scripts/A.lua", "logo", { ok = true, src = "asset", value = "https://not-an-asset" })), false, "an asset must be an asset")
	T.eq((Art.set("Scripts/A.lua", "logo", { ok = true, src = "file", value = "x.png", cached = "somewhere/else.png" })), false, "a copy outside the cache folder is refused")
	T.eq((Art.set("Scripts/A.lua", "logo", { ok = true, src = "file", value = "x.png" })), false, "a file picture needs its saved copy")
	T.eq((Art.set("Scripts/A.lua", "logo", { ok = true, src = "magic", value = "x" })), false)
end

T.section("scriptart: a damaged list file")
do
	local world = W.new()
	world.put(Art.DATA_FILE, "{this is not json")
	Art.init(world.ctx)
	T.eq(Art.count(), 0, "a broken file starts fresh")
	T.eq(world.files[Art.BROKEN_FILE], "{this is not json", "but the broken copy is kept")
	local world2 = W.new()
	world2.put(Art.DATA_FILE, '{"version":1}')
	Art.init(world2.ctx)
	T.eq(world2.files[Art.BROKEN_FILE], '{"version":1}', "a file with no list is kept as broken too")
	local world3 = W.new()
	world3.put(Art.DATA_FILE, "")
	Art.init(world3.ctx)
	T.eq(world3.files[Art.BROKEN_FILE], nil, "an empty file is not worth keeping")
	local world4 = W.new()
	Art.init(world4.ctx)
	T.eq(world4.files[Art.BROKEN_FILE], nil, "no file at all is normal")
	T.eq(Art.count(), 0)
end

T.section("scriptart: bad entries in the list file are dropped")
do
	local good = "AtsukoHub/cache/art/0123456789abcdef.png"
	local data = {
		version = 1,
		lastFolder = "pics/cats",
		items = {
			["Scripts/Good.lua"] = {
				logo = { src = "file", value = "pics/me.png", cached = good, format = "png", ext = "png", label = "PNG", w = 3, h = 2, size = 82, converted = true, at = 5 },
				banner = { src = "asset", value = "12345" },
			},
			["Scripts/Bad1.lua"] = { logo = { src = "magic", value = "x" } },
			["Scripts/Bad2.lua"] = { logo = { src = "file", value = "x.png", cached = "../../etc/passwd" } },
			["Scripts/Bad3.lua"] = { logo = { src = "asset", value = "https://x.com/a.png" } },
			["Scripts/Bad4.lua"] = { logo = { src = "url", value = "https://x.com/a.png" } },
			["Scripts/Bad5.lua"] = "text",
			["Scripts/Bad6.lua"] = { logo = 5, banner = {} },
			["Scripts/Bad7.lua"] = { logo = { src = "file", value = string.rep("v", 2001), cached = good } },
			["Scripts/Odd.lua"] = { logo = { src = "file", value = "a.png", cached = good, w = -4, h = 1e12, size = "big", format = string.rep("f", 13), ext = 5, label = "ok", converted = "yes", at = "now" } },
		},
	}
	local world = W.new()
	world.put(Art.DATA_FILE, jsonencode(data))
	Art.init(world.ctx)
	local logo = Art.get("Scripts/Good.lua", "logo")
	T.eq(logo.src, "file")
	T.eq(logo.cached, good)
	T.eq(logo.w, 3)
	T.eq(logo.size, 82)
	T.eq(logo.converted, true)
	T.eq(logo.at, 5)
	T.eq(Art.get("Scripts/Good.lua", "banner").value, "rbxassetid://12345", "a bare number in the file is read as an asset id")
	for i = 1, 7 do
		T.eq(Art.get("Scripts/Bad" .. i .. ".lua", "logo"), nil, "Bad" .. i .. " is dropped")
		T.eq(Art.get("Scripts/Bad" .. i .. ".lua", "banner"), nil)
	end
	local odd = Art.get("Scripts/Odd.lua", "logo")
	T.ok(odd ~= nil, "an odd entry keeps what is good")
	T.eq(odd.w, nil, "a negative size is dropped")
	T.eq(odd.h, nil, "an enormous size is dropped")
	T.eq(odd.size, nil, "a size that is text is dropped")
	T.eq(odd.format, nil, "a long format name is dropped")
	T.eq(odd.ext, nil)
	T.eq(odd.label, "ok")
	T.eq(odd.converted, nil, "converted must be a real true")
	T.eq(odd.at, nil)
	T.eq(Art.count(), 3)
	T.eq(Art.lastFolder(), "pics/cats")
end

T.section("scriptart: saving can fail")
do
	local world = boot()
	world.failWrites = true
	local ok, saved = Art.set("Scripts/A.lua", "logo", { ok = true, src = "asset", value = "rbxassetid://5" })
	T.eq(ok, true, "the picture still works this session")
	T.eq(saved, false, "but it is not on disk")
	T.eq(#world.toasts, 1)
	T.eq(world.toasts[1].title, "Pictures")
	T.eq(world.toasts[1].kind, "warn")
	Art.set("Scripts/A.lua", "banner", { ok = true, src = "asset", value = "rbxassetid://6" })
	T.eq(#world.toasts, 1, "the warning is only shown once")
	T.eq(Art.get("Scripts/A.lua", "banner").value, "rbxassetid://6")
end

T.section("scriptart: the copy of a picture is released when nobody uses it")
do
	local world = boot()
	local a = "AtsukoHub/cache/art/aaaaaaaaaaaaaaaa.png"
	local b = "AtsukoHub/cache/art/bbbbbbbbbbbbbbbb.png"
	world.put(a, "A")
	world.put(b, "B")
	local function result(path)
		return { ok = true, src = "file", value = "x.png", cached = path, format = "png", ext = "png" }
	end
	Art.set("Scripts/One.lua", "logo", result(a))
	Art.set("Scripts/Two.lua", "logo", result(a))
	T.eq(world.files[a], "A")
	Art.clear("Scripts/One.lua", "logo")
	T.eq(world.files[a], "A", "still used by another script, so it stays")
	Art.clear("Scripts/Two.lua", "logo")
	T.eq(world.files[a], nil, "nobody uses it now, so it is deleted")
	Art.set("Scripts/One.lua", "logo", result(a))
	world.put(a, "A")
	Art.set("Scripts/One.lua", "logo", result(b))
	T.eq(world.files[a], nil, "changing the picture deletes the old copy")
	T.eq(world.files[b], "B")
	Art.set("Scripts/One.lua", "logo", result(b))
	T.eq(world.files[b], "B", "setting the same picture again keeps it")
	T.eq(Art.release("AtsukoHub/cache/art/../../evil.txt"), false)
	world.put("AtsukoHub/other.txt", "keep")
	T.eq(Art.release("AtsukoHub/other.txt"), false, "files outside the cache are never touched")
	T.eq(world.files["AtsukoHub/other.txt"], "keep")
	T.eq(Art.release(b), false, "a copy in use is not released")
	T.eq(world.files[b], "B")
	Art.clear("Scripts/One.lua", "logo")
	T.eq(Art.release(a), true, "a lone copy can be released by hand")
end

T.section("scriptart: remembering the last folder")
do
	local world = boot()
	T.eq(Art.lastFolder(), "")
	local before = world.writeCount
	Art.setLastFolder("pics\\cats")
	T.eq(Art.lastFolder(), "pics/cats", "slashes are tidied")
	T.eq(world.writeCount, before + 1)
	Art.setLastFolder("pics/cats/")
	T.eq(world.writeCount, before + 1, "the same folder is not saved again")
	T.eq(jsondecode(world.files[Art.DATA_FILE]).lastFolder, "pics/cats")
	Art.setLastFolder("")
	T.eq(Art.lastFolder(), "")
end

T.section("scriptart: what the executor can do")
do
	boot()
	T.same(Art.available(), { files = true, list = true, request = true, clipboard = false })
	boot({ has = { assets = false } })
	T.eq(Art.available().files, false, "no getcustomasset means no pictures from files")
	boot({ has = { files = false } })
	T.eq(Art.available().files, false)
	boot({ has = { list = false, request = false }, clipboard = "x" })
	local a = Art.available()
	T.eq(a.list, false)
	T.eq(a.request, false)
	T.eq(a.clipboard, true)
	T.eq(Art.clipboard(), "x")
	boot()
	T.eq(Art.clipboard(), nil)
end

T.section("scriptart: the converter config file")
do
	local world = boot({ configText = '{"version":1,"converter":{"name":"Other","url":"https://other.example/png?u={url}","note":"a note"}}' })
	task.wait(0.1)
	T.same(Art.converter(), { name = "Other", url = "https://other.example/png?u={url}", note = "a note" })
	local world2 = boot({ configText = "{broken" })
	task.wait(0.1)
	T.eq(Art.converter().name, "images.weserv.nl", "a broken file keeps the default")
	boot({ configText = '{"converter":{"url":"http://insecure.example/{url}"}}' })
	task.wait(0.1)
	T.eq(Art.converter().url, Art.DEFAULT_CONVERTER.url, "an insecure converter is not used")
	boot()
	task.wait(0.1)
	T.eq(Art.converter().name, "images.weserv.nl", "no file means the default")
end

T.section("scriptart: pictures follow a script that moved")
do
	local good = "AtsukoHub/cache/art/abc.png"
	local data = {
		version = 1,
		items = {
			["Scripts/Hat/FDless/Addict.lua"] = { logo = { src = "file", value = "a.png", cached = good } },
			["Scripts/Hat/FDless/DubstepGun.lua"] = { banner = { src = "asset", value = "111" } },
			["Scripts/Hat/FDless/LastStar.lua"] = { logo = { src = "asset", value = "222" } },
			["Scripts/Hat/LastStar.lua"] = { logo = { src = "asset", value = "333" } },
			["Scripts/Hat/Other.lua"] = { logo = { src = "asset", value = "444" } },
		},
	}
	local moved = {
		["Scripts/Hat/FDless/Addict.lua"] = "Scripts/Hat/Addict.lua",
		["Scripts/Hat/FDless/DubstepGun.lua"] = "Scripts/Hat/DubstepGunOriginal.lua",
		["Scripts/Hat/FDless/LastStar.lua"] = "Scripts/Hat/LastStar.lua",
	}
	local world = W.new()
	world.deps.movedPath = function(path)
		return moved[path] or path
	end
	world.put(Art.DATA_FILE, jsonencode(data))
	Art.init(world.ctx)
	T.eq(Art.get("Scripts/Hat/Addict.lua", "logo").cached, good, "a logo moves to the new path")
	T.eq(Art.get("Scripts/Hat/FDless/Addict.lua", "logo"), nil, "and is gone from the old one")
	T.eq(Art.get("Scripts/Hat/DubstepGunOriginal.lua", "banner").value, "rbxassetid://111", "a renamed file keeps its banner")
	T.eq(Art.get("Scripts/Hat/LastStar.lua", "logo").value, "rbxassetid://333", "a picture already on the new path wins")
	T.eq(Art.get("Scripts/Hat/Other.lua", "logo").value, "rbxassetid://444", "other scripts are not touched")
	local world2 = W.new()
	world2.put(Art.DATA_FILE, jsonencode(data))
	Art.init(world2.ctx)
	T.eq(Art.get("Scripts/Hat/FDless/Addict.lua", "logo").cached, good, "without the helper nothing moves")
end
