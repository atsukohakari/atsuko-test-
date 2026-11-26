local src = readsource("Hub/AtsukoHub.lua")

local first = string.find(src, "local Origin = {", 1, true)
local last = first and string.find(src, "\nOrigin.detect()\n", first, true)
T.section("origin: the hub runs from GitHub")
T.ok(first ~= nil and last ~= nil, "the origin block is found")
T.ok(string.find(src, 'local SRC = { owner = "atsukohakari", repo = "atsuko-test-", branch = "main" }', 1, true) ~= nil, "the hub's home is atsukohakari/atsuko-test-")
T.eq(string.find(src, "atsukohakari/Atsuko/", 1, true), nil, "nothing points at the old repository")

local block = string.sub(src, first, last)

local function detect(opts)
	local disk = opts.disk or {}
	HAS_FS = opts.fs ~= false
	HUB_DIR = "Hub"
	HUB_VERSION = "1.6.1"
	SRC = { owner = "atsukohakari", repo = "atsuko-test-", branch = "main" }
	HOME_REPO = "https://raw.githubusercontent.com/atsukohakari/atsuko-test-/main/"
	GENV = { AtsukoLocalRoot = opts.want }
	FS = {
		exists = function(p)
			return disk[p] ~= nil
		end,
		read = function(p)
			return disk[p]
		end,
	}
	local f, err = loadstring(block .. "\nreturn Origin", "=origin")
	T.ok(f ~= nil, "compiles: " .. tostring(err))
	local Origin = f()
	Origin.detect()
	return Origin
end

local FOLDER = { ["Atsuko Hub/Hub/AtsukoHub.lua"] = "x", ["Atsuko Hub/Hub/version.txt"] = "1.6.1" }

local o = detect({ disk = FOLDER })
T.eq(o.root, nil, "a matching Atsuko Hub folder in the workspace is not used by itself")
T.eq(o.where(), "GitHub", "it runs from GitHub")
T.eq(o.why, nil, "and there is nothing to warn about")
T.eq(o.loader(), 'loadstring(game:HttpGet("https://raw.githubusercontent.com/atsukohakari/atsuko-test-/main/Hub/AtsukoHub.lua"))()', "rejoins load it from GitHub too")

o = detect({ disk = {} })
T.eq(o.root, nil, "no folder, GitHub")
T.eq(o.where(), "GitHub")

o = detect({ disk = FOLDER, want = false })
T.eq(o.root, nil, "AtsukoLocalRoot = false is GitHub")

o = detect({ disk = FOLDER, want = "Atsuko Hub" })
T.eq(o.root, "Atsuko Hub", "a folder is only used when you name it")
T.eq(o.where(), "your folder")

o = detect({ disk = FOLDER, want = true })
T.eq(o.root, "Atsuko Hub", "or when you ask for it with true")

o = detect({ disk = {}, want = true })
T.eq(o.root, nil, "asking with no folder there stays on GitHub")
T.ok(type(o.why) == "string" and string.find(o.why, "Atsuko Hub", 1, true) ~= nil, "and says why: " .. tostring(o.why))

o = detect({ disk = {}, want = "Mine" })
T.eq(o.root, nil, "a named folder that isn't there stays on GitHub")
T.ok(type(o.why) == "string" and string.find(o.why, "Mine", 1, true) ~= nil, "and says why")

o = detect({ disk = FOLDER, want = "Atsuko Hub", fs = false })
T.eq(o.root, nil, "without file functions it can't use a folder")
T.eq(o.why, "this executor has no file functions")

T.section("origin: the scripts fall back to the same repository")
for _, path in ipairs({ "Scripts/Hat/BanHammer.lua", "Scripts/Hat/BookReader.lua", "Scripts/Hat/AK47.lua", "Scripts/Hat/FakeVR.lua", "Hub/Moveset.lua", "Hub/UhhMoveset.lua" }) do
	local text = readsource(path)
	T.ok(string.find(text, "https://raw.githubusercontent.com/atsukohakari/atsuko-test-/main/", 1, true) ~= nil, path .. " loads from atsuko-test-")
	T.eq(string.find(text, "atsukohakari/Atsuko/", 1, true), nil, path .. " has no old link")
end
