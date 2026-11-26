local W = loadmodule("Testing/mocks/art_world.lua")
local Art = loadmodule("Hub/modules/scriptart.lua")

local function boot(opts)
	local world = W.new(opts)
	Art.init(world.ctx)
	return world
end

local function names(list)
	local out = {}
	for i, item in ipairs(list) do
		out[i] = item.name
	end
	table.sort(out)
	return out
end

T.section("scriptart browse: listing a folder")
do
	local world = boot()
	world.put("top.png", "x")
	world.put("pics/a.png", "x")
	world.put("pics/b.jpg", "x")
	world.put("pics/cats/c.png", "x")
	world.put("pics/.hidden", "x")
	world.put("pics/NOEXT", "x")
	world.put("pics/Notes.TXT", "x")
	local root, why = Art.listDir("")
	T.eq(why, nil)
	T.same(names(root), { "pics", "top.png" })
	local pics = Art.listDir("pics")
	T.same(names(pics), { "NOEXT", "Notes.TXT", "a.png", "b.jpg", "cats" }, "the hidden file is left out")
	local byName = {}
	for _, item in ipairs(pics) do
		byName[item.name] = item
	end
	T.eq(byName.cats.folder, true)
	T.eq(byName["a.png"].folder, false)
	T.eq(byName["a.png"].path, "pics/a.png")
	T.eq(byName["a.png"].ext, "png")
	T.eq(byName["Notes.TXT"].ext, "txt", "endings are lowered")
	T.eq(byName.NOEXT.ext, "")
	T.eq(byName["a.png"].size, nil, "sizes are not known until asked for")
	T.same(names(Art.listDir("pics/cats")), { "c.png" })
	T.same(names(Art.listDir("pics\\cats\\")), { "c.png" }, "slashes are tidied")
	T.same(names(Art.listDir("./pics")), names(Art.listDir("pics")), "a leading ./ is ignored")
end

T.section("scriptart browse: executors that list differently")
do
	local world = boot()
	world.rootNeedsDot = true
	world.put("a.png", "x")
	world.put("sub/b.png", "x")
	T.same(names(Art.listDir("")), { "a.png", "sub" }, "the root is tried as a dot when an empty name fails")
	world.listBare = true
	T.same(names(Art.listDir("sub")), { "b.png" }, "bare names get their folder put back in front")
	T.eq(Art.listDir("sub")[1].path, "sub/b.png")
	world.listBroken = true
	local nothing, why = Art.listDir("sub")
	T.eq(nothing, nil)
	T.eq(why, "I couldn't open that folder")
	local none = boot({ has = { list = false } })
	local list, why2 = Art.listDir("")
	T.eq(list, nil)
	T.eq(why2, "your executor can't list folders, type the path instead")
end

T.section("scriptart browse: small pictures for the grid")
do
	local world = boot()
	local png = W.fixture("png_rgb_3x2")
	world.put("pics/a.png", png)
	local writes = world.writeCount
	local id, state, meta = Art.thumbNow("pics/a.png")
	T.eq(id, "rbxasset://pics/a.png", "a normally named picture is used where it is")
	T.eq(state, "ok")
	T.eq(meta.size, #png)
	T.eq(meta.info.format, "png")
	T.eq(world.writeCount, writes, "nothing is copied for it")
	world.put("pics/lie.png", W.fixture("jpeg_baseline_8x8"))
	local id2, state2, meta2 = Art.thumbNow("pics/lie.png")
	T.eq(state2, "ok")
	T.eq(meta2.info.format, "jpeg")
	T.ok(string.find(id2, "Atsuko Hub/cache/art_thumb/", 1, true) ~= nil, "a picture with the wrong ending is copied: " .. tostring(id2))
	T.eq(string.sub(id2, -4), ".jpg")
	T.eq(#world.cacheFiles(Art.CACHE_DIR), 0, "thumbnails never go in the picture cache")
	world.put("pics/scrambled", W.fixture("png_rgba_1x1"))
	local id3, state3 = Art.thumbNow("pics/scrambled")
	T.eq(state3, "ok")
	T.ok(string.find(id3, "art_thumb", 1, true) ~= nil, "no ending also means a copy")
	world.put("pics/note.png", "just words in here")
	local id4, state4, meta4 = Art.thumbNow("pics/note.png")
	T.eq(id4, nil)
	T.eq(state4, "notimage")
	T.eq(meta4.why, "that is a text file, not a picture")
	T.eq(meta4.size, 18)
	world.put("pics/big.png", W.fatPng(1572864))
	local id5, state5, meta5 = Art.thumbNow("pics/big.png")
	T.eq(state5, "big", "over 1.5 MB is too big for a thumbnail")
	T.eq(id5, nil)
	T.eq(meta5.size, #world.files["pics/big.png"])
	world.put("pics/edge.png", W.fatPng(1572864 - #W.fixture("png_solid_256")))
	T.eq(#world.files["pics/edge.png"], 1572864)
	T.eq(select(2, Art.thumbNow("pics/edge.png")), "ok", "exactly 1.5 MB is fine")
	local id6, state6 = Art.thumbNow("pics/missing.png")
	T.eq(id6, nil)
	T.eq(state6, "unreadable")
	world.noAssetFor["pics/a.png"] = true
	local _, state7, meta7 = Art.thumbNow("pics/a.png")
	T.eq(state7, "asset")
	T.eq(meta7.size, #png)
	world.has.assets = false
	T.eq(select(2, Art.thumbNow("pics/a.png")), "unsupported")
	world.has.assets = true
	world.has.files = false
	T.eq(select(2, Art.thumbNow("pics/a.png")), "unsupported")
end

T.section("scriptart browse: measuring a folder")
do
	local world = boot()
	world.put("d/a.png", string.rep("a", 10))
	world.put("d/b.png", string.rep("b", 300))
	world.folder("d/sub")
	local entries = Art.listDir("d")
	local seen = {}
	local count = Art.measure(entries, function(done, total)
		seen[#seen + 1] = done .. "/" .. total
	end)
	T.eq(count, 2, "folders are skipped")
	T.same(seen, { "1/2", "2/2" })
	local sizes = {}
	for _, item in ipairs(entries) do
		sizes[item.name] = item.size
	end
	T.eq(sizes["a.png"], 10)
	T.eq(sizes["b.png"], 300)
	T.eq(sizes.sub, nil)
	local reads = #world.reads
	T.eq(Art.measure(entries), 0, "already measured entries are not read again")
	T.eq(#world.reads, reads)
	local order = {}
	for i, item in ipairs(Art.arrange(entries, { sort = "size" })) do
		order[i] = item.name
	end
	T.same(order, { "sub", "b.png", "a.png" }, "biggest picture first after measuring")
	local world2 = boot()
	for i = 1, 450 do
		world2.put("many/f" .. i .. ".png", "x")
	end
	local big = Art.listDir("many")
	local started = time()
	T.eq(Art.measure(big), 400, "no more than 400 are measured")
	T.ok(time() - started > 0.5, "it paused now and then so the game keeps running")
	local measured = 0
	for _, item in ipairs(big) do
		if item.size then
			measured = measured + 1
		end
	end
	T.eq(measured, 400)
	local stop = false
	local list2 = Art.listDir("many")
	local n = Art.measure(list2, function(done)
		if done == 5 then
			stop = true
		end
	end, function()
		return not stop
	end)
	T.eq(n, 5, "measuring stops when the window closes")
	local empty = Art.measure(nil)
	T.eq(empty, 0)
end
