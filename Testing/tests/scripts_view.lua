local hub = readsource("Hub/AtsukoHub.lua")
local Manifest = loadmodule("Hub/modules/manifest.lua")
local Controller = loadmodule("Hub/modules/reanim.lua")

local NAMES = { "Core", "Util", "Repo", "S", "Runner", "THEME" }
local saved = {}
for _, name in ipairs(NAMES) do
	saved[name] = _G[name]
end

local function slice(from, to)
	local first = string.find(hub, from, 1, true)
	T.ok(first ~= nil, "found in the hub: " .. from)
	if not first then
		return ""
	end
	local last = string.find(hub, to, first, true)
	T.ok(last ~= nil, "found in the hub: " .. to)
	if not last then
		return ""
	end
	return string.sub(hub, first, last - 1)
end

local function fn(header)
	local first = string.find(hub, "\n" .. header, 1, true)
	T.ok(first ~= nil, "found in the hub: " .. header)
	if not first then
		return ""
	end
	local last = string.find(hub, "\nend\n", first + 1, true)
	T.ok(last ~= nil, "found the end of: " .. header)
	if not last then
		return ""
	end
	return string.sub(hub, first + 1, last + 3)
end

local function run(code, name)
	local f, err = loadstring(code, "=" .. name)
	T.ok(f ~= nil, name .. " compiles: " .. tostring(err))
	if f then
		f()
	end
end

Util = {}
Core = { SCRIPT_EXT = { lua = true, luau = true, txt = true }, mods = {}, ctx = {} }
Repo = { entries = {}, byPath = {}, meta = {}, manifest = {}, state = "ready", sig = "" }
S = { favorites = {}, recent = {}, reanimSel = nil }
Runner = { pending = {}, failed = {} }
THEME = { green = "G", yellow = "Y", red = "R", dim = "D" }

run(fn("function Util.trim(s)"), "Util.trim")
run(fn("function Util.fmtSize(bytes)"), "Util.fmtSize")
run(fn("function Util.prettyName(path)"), "Util.prettyName")
run(fn("function Runner.isActive(rec)"), "Runner.isActive")
run(fn("function Core.makeEntry(path, size)"), "Core.makeEntry")
run(fn("function Repo.visible(e)"), "Repo.visible")
run(fn("function Repo.shown()"), "Repo.shown")
run(fn("function Core.sortEntries(list)"), "Core.sortEntries")
run(fn("function Repo.manifestModule()"), "Repo.manifestModule")
run(fn("function Repo.set(list)"), "Repo.set")
run(fn("function Repo.parseMeta(src)"), "Repo.parseMeta")
run(slice("Core.VIEW_TABS =", "function Repo.manifestModule") == "" and "" or "", "unused")
run(fn("function Core.entryKind(e)"), "Core.entryKind")
run(fn("function Core.entryCredit(e)"), "Core.entryCredit")
run(fn("function Core.scriptMatch(e, q)"), "Core.scriptMatch")
run(fn("function Core.scriptPlan(tab, query)"), "Core.scriptPlan")
run(fn("function Core.rowSub(e, viewIndex)"), "Core.rowSub")
run(fn("function Core.rowState(e, rec, pending)"), "Core.rowState")
run((string.gsub(fn("function Core.toneColor(tone)"), "T%.(%a+)", "THEME.%1")), "Core.toneColor")
run("Core.VIEW_TABS = " .. string.match(slice("Core.VIEW_TABS =", "function Core.entryKind"), "Core.VIEW_TABS = (%b{})"), "Core.VIEW_TABS")
Core.mods.manifest = { mod = Manifest }

local function reset()
	Repo.entries, Repo.byPath, Repo.meta, Repo.manifest = {}, {}, {}, {}
	Repo.state = "ready"
	S.favorites, S.recent, S.reanimSel = {}, {}, nil
	Runner.pending = {}
end

local function entryOf(path, size)
	return Core.makeEntry(path, size or 0)
end

local function namesOf(rows)
	local out = {}
	for _, item in ipairs(rows) do
		out[#out + 1] = item.group and ("[" .. item.group .. "]") or item.e.name
	end
	return out
end

local REAL = {
	"Scripts/Hat/DubstepGun.lua",
	"Scripts/Hat/SnakeBanisherV3.lua",
	"Scripts/Hat/StudioDummyV4-Test.lua",
	"Scripts/Hat/DubstepGunOriginal.lua",
	"Scripts/Hat/LastStar.lua",
	"Scripts/Hat/NeptunianV.lua",
	"Scripts/Hat/NeptunianVGun.lua",
	"Scripts/Hat/TheHotline.lua",
	"Scripts/Hat/Addict.lua",
	"Scripts/Hat/CommanderV2.lua",
	"Scripts/Hat/InternalWar.lua",
	"Scripts/Hat/MasterChief.lua",
}

local function loadReal(extra)
	reset()
	local ok, scripts = Manifest.parse(readsource("Scripts/manifest.json"), jsondecode)
	T.ok(ok ~= nil, "the real manifest reads")
	Repo.manifest = ok or {}
	local list = {}
	for _, path in ipairs(REAL) do
		list[#list + 1] = entryOf(path, 1000)
	end
	for _, path in ipairs(extra or {}) do
		list[#list + 1] = entryOf(path, 500)
	end
	Repo.set(list)
	return list
end

T.section("scripts_view: the four tabs")
T.same(Core.VIEW_TABS, { "Hat", "Limb", "Favorites", "Recent" })

T.section("scripts_view: names never show an extension")
local pretty = {
	["Scripts/Hat/NeptunianV.lua"] = "NeptunianV",
	["Neptunian V.lua"] = "Neptunian V",
	["x.lua.txt"] = "x",
	["Fly.LUA"] = "Fly",
	["my_script.luau"] = "my script",
	["01_Fly.lua"] = "Fly",
	["10 - Fast Fly.lua"] = "Fast Fly",
	["1. Fly.lua"] = "Fly",
	["1.5x Speed.lua"] = "1.5x Speed",
	["007.lua"] = "007",
	["2048_game.lua"] = "game",
	["fly_lua.txt"] = "fly",
	["script.json"] = "script",
	["weird.name.lua"] = "weird.name",
	["a.txt.lua"] = "a",
	["Noextension"] = "Noextension",
	["Scripts/deep/path/Name_With_Underscores.lua"] = "Name With Underscores",
	["__x__.lua"] = "x",
}
for path, want in pairs(pretty) do
	T.eq(Util.prettyName(path), want, path)
end
for path in pairs(pretty) do
	local name = Util.prettyName(path)
	T.ok(not string.find(name, "%.lua$") and not string.find(name, "%.txt$") and not string.find(name, "%.json$"), "no extension left in " .. name)
end

T.section("scripts_view: the new header keys")
local meta = Repo.parseMeta("-- @kind Limb\n-- @needsfd\n-- @reanim fdless, atsuko\n-- @credit A, B\n-- @name My Name\nprint(1)\n")
T.eq(meta.kind, "limb", "kind is lower-cased")
T.eq(meta.needsfd, true, "a bare flag means yes")
T.eq(meta.reanim, "fdless, atsuko")
T.eq(meta.credit, "A, B")
T.eq(meta.name, "My Name")
T.eq(Repo.parseMeta("-- @kind banana\n").kind, nil, "an unknown kind is dropped")
T.eq(Repo.parseMeta("-- @kind HAT\n").kind, "hat")
T.eq(Repo.parseMeta("-- @needsfd false\n").needsfd, false)
T.eq(Repo.parseMeta("-- @needsfd no\n").needsfd, false)
T.eq(Repo.parseMeta("-- @needsfd 1\n").needsfd, true)
T.eq(Repo.parseMeta("-- @needsfd true\n").needsfd, true)
T.eq(Repo.parseMeta("print(1)\n").kind, nil)
T.eq(Repo.parseMeta("print(1)\n").needsfd, nil)

T.section("scripts_view: hat or limb")
reset()
local function kindOf(path, patch)
	local e = entryOf(path)
	for k, v in pairs(patch or {}) do
		e[k] = v
	end
	return Core.entryKind(e)
end
local k, why = kindOf("Scripts/Hat/FDless/X.lua")
T.eq(k, "hat")
T.eq(why, "folder")
k, why = kindOf("Scripts/Hat/X.lua")
T.eq(k, "hat")
T.eq(why, "folder")
k, why = kindOf("Scripts/Limb/Y.lua")
T.eq(k, "limb")
T.eq(why, "folder")
k, why = kindOf("Scripts/Limb/Gelatek/Y.lua")
T.eq(k, "limb")
T.eq(why, "folder")
k, why = kindOf("Scripts/Other/Z.lua")
T.eq(k, "hat", "neither folder nor header means hat")
T.eq(why, "default")
k, why = kindOf("Scripts/Z.lua")
T.eq(k, "hat")
T.eq(why, "default")
k, why = kindOf("Scripts/Hat/X.lua", { kind = "limb" })
T.eq(k, "limb", "the manifest beats the folder")
T.eq(why, "manifest")
local over = entryOf("Scripts/Hat/X.lua")
over.kind = "limb"
Repo.meta[over.path] = { kind = "hat" }
k, why = Core.entryKind(over)
T.eq(k, "hat", "the script's own header beats the manifest")
T.eq(why, "header")
Repo.meta[over.path] = { kind = "banana" }
k, why = Core.entryKind(over)
T.eq(k, "limb", "an unusable header value is ignored")
T.eq(why, "manifest")
T.eq(Core.entryKind(nil), "hat")
T.eq(Core.entryKind({ path = "x.lua" }), "hat", "an entry with no category")

T.section("scripts_view: no group helpers are left")
T.ok(not string.find(hub, "function Core.entryGroup", 1, true), "the group headings are gone, and so is their helper")
T.ok(not string.find(hub, "function Core.isNativeEntry", 1, true), "and nothing tells hub scripts apart in the list anymore")

T.section("scripts_view: credit line")
T.eq(Core.entryCredit({}), nil)
T.eq(Core.entryCredit({ credit = {} }), nil)
T.eq(Core.entryCredit({ credit = "text" }), nil)
T.eq(Core.entryCredit({ credit = { "Tory" } }), "Tory")
T.eq(Core.entryCredit({ credit = { "Supr14", "MyWorld & rqz", "BloxinStud10" } }), "Supr14 +2")

T.section("scripts_view: search")
local sample = { name = "Neptunian V", category = "Hat / FDless", credit = { "Tory", "NoobyGames12" } }
T.eq(Core.scriptMatch(sample, ""), true)
T.eq(Core.scriptMatch(sample, "neptun"), true)
T.eq(Core.scriptMatch(sample, "fdless"), true, "the folder counts")
T.eq(Core.scriptMatch(sample, "tory"), true, "an author counts")
T.eq(Core.scriptMatch(sample, "noobygames12"), true)
T.eq(Core.scriptMatch(sample, "zzz"), false)
T.eq(Core.scriptMatch({ name = "A", category = "B" }, "c"), false, "no credit list is fine")
T.eq(Core.scriptMatch({ name = "A.b", category = "B" }, "."), true, "a dot is not a pattern")
T.eq(Core.scriptMatch({ name = "A(b", category = "B" }, "(b"), true, "a bracket is not a pattern")

T.section("scripts_view: the Hat tab with the real scripts")
loadReal()
local rows, why2, count = Core.scriptPlan(1, "")
T.eq(why2, nil)
T.eq(count, 12)
T.same(namesOf(rows), {
	"Addict",
	"Commander V2",
	"Dubstep Gun (Hub)",
	"Dubstep Gun (Original)",
	"InternalWar",
	"Last Star",
	"Master Chief",
	"Neptunian V",
	"Neptunian V Gun",
	"Snake Banisher V3",
	"Studio Dummy V4",
	"The Hotline",
}, "one list sorted by name, with no headings")
for _, item in ipairs(rows) do
	T.eq(item.group, nil, "no group rows")
end
T.ok(not string.find(table.concat(namesOf(rows), "|"), "Sniper"), "The Sniper is hidden, so it is not here")
for _, item in ipairs(rows) do
	if item.e then
		T.eq(Core.entryKind(item.e), "hat", item.e.name)
		T.eq(item.e.kind, "hat", item.e.name .. " has its kind from the manifest")
	end
end

T.section("scripts_view: the Limb tab")
rows, why2, count = Core.scriptPlan(2, "")
T.eq(why2, "nolimb", "no limb scripts ship, so there is a friendly empty state")
T.eq(count, 0)
T.same(rows, {})
loadReal({ "Scripts/Limb/Zed.lua" })
rows, why2, count = Core.scriptPlan(2, "")
T.eq(why2, nil)
T.same(namesOf(rows), { "Zed" })
rows = Core.scriptPlan(1, "")
T.eq(#rows, 12, "the Hat tab does not change when a limb script appears")
loadReal({ "Scripts/Limb/Zed.lua", "Scripts/Limb/Gelatek/Alpha.lua" })
rows = Core.scriptPlan(2, "")
T.same(namesOf(rows), { "Alpha", "Zed" }, "a folder below Limb makes no heading, the list is sorted by name")
loadReal({ "Scripts/Hat/Mine/Zeta.lua", "Scripts/Hat/Aaa.lua", "Scripts/Hat/Mine/aab.lua" })
rows = Core.scriptPlan(1, "")
T.eq(namesOf(rows)[1], "Aaa")
T.eq(namesOf(rows)[2], "aab", "capitals don't change the order")
T.eq(namesOf(rows)[#rows], "Zeta", "folders don't change it either")

T.section("scripts_view: search inside a tab")
loadReal()
rows, why2, count = Core.scriptPlan(1, "supr14")
T.same(namesOf(rows), { "Dubstep Gun (Hub)", "Dubstep Gun (Original)" }, "the author is searched too")
rows, why2, count = Core.scriptPlan(1, "neptunian")
T.same(namesOf(rows), { "Neptunian V", "Neptunian V Gun" })
rows = Core.scriptPlan(1, "melon")
T.same(namesOf(rows), { "Addict", "Commander V2", "InternalWar", "Master Chief" }, "the new scripts are found by who made them")
rows = Core.scriptPlan(1, "helkern")
T.same(namesOf(rows), { "Master Chief" }, "Master Chief is found by its creator")
rows, why2, count = Core.scriptPlan(1, "nothing like this")
T.eq(why2, "search")
T.eq(count, 0)
rows, why2 = Core.scriptPlan(2, "anything")
T.eq(why2, "nolimb", "no limb scripts at all is not the same as no match")
rows = Core.scriptPlan(1, "LAST")
T.same(namesOf(rows), { "Last Star" }, "search ignores capitals")

T.section("scripts_view: Favorites and Recent")
loadReal()
rows, why2 = Core.scriptPlan(3, "")
T.eq(why2, "nofavorites")
rows, why2 = Core.scriptPlan(4, "")
T.eq(why2, "norecent")
S.favorites["Scripts/Hat/LastStar.lua"] = true
S.favorites["Scripts/Hat/DubstepGun.lua"] = true
S.favorites["Scripts/Hat/Gone.lua"] = true
rows, why2, count = Core.scriptPlan(3, "")
T.same(namesOf(rows), { "Dubstep Gun (Hub)", "Last Star" }, "favorites follow the list order, a missing script is skipped")
T.eq(count, 2)
rows, why2 = Core.scriptPlan(3, "zzz")
T.eq(why2, "search")
S.recent = { "Scripts/Hat/TheHotline.lua", "Scripts/Hat/Gone.lua", "Scripts/Hat/StudioDummyV4-Test.lua", "Scripts/Hat/TheHotline.lua" }
rows, why2, count = Core.scriptPlan(4, "")
T.eq(namesOf(rows)[1], "The Hotline", "recent keeps the order it was saved in")
T.eq(namesOf(rows)[2], "Studio Dummy V4", "a script that is no longer there is skipped")
rows, why2 = Core.scriptPlan(4, "studio")
T.same(namesOf(rows), { "Studio Dummy V4" })
for tab = 3, 4 do
	rows = Core.scriptPlan(tab, "")
	for _, item in ipairs(rows) do
		T.eq(item.group, nil, "no group headers on tab " .. tab)
	end
end

T.section("scripts_view: loading, error and empty list")
reset()
Repo.state = "loading"
rows, why2 = Core.scriptPlan(1, "")
T.eq(why2, "loading")
Repo.state = "idle"
rows, why2 = Core.scriptPlan(2, "")
T.eq(why2, "loading")
Repo.state = "error"
rows, why2 = Core.scriptPlan(1, "")
T.eq(why2, "error")
Repo.state = "ready"
rows, why2 = Core.scriptPlan(1, "")
T.eq(why2, "none")
Repo.state = "cached"
rows, why2 = Core.scriptPlan(1, "")
T.eq(why2, "none")
rows, why2 = Core.scriptPlan(3, "")
T.eq(why2, "nofavorites", "favorites do not wait for the list")
rows, why2 = Core.scriptPlan(4, "")
T.eq(why2, "norecent")
rows, why2, count = Core.scriptPlan(1, nil)
T.eq(count, 0, "no search text at all is fine")

T.section("scripts_view: the line under a name")
loadReal()
local dub = Repo.byPath["Scripts/Hat/DubstepGunOriginal.lua"]
T.eq(Core.rowSub(dub, 1), "by Supr14 +2")
T.eq(Core.rowSub(dub, 2), "by Supr14 +2")
T.eq(Core.rowSub(dub, 3), "Hat  ·  by Supr14 +2")
T.eq(Core.rowSub(dub, 4), "Hat  ·  by Supr14 +2")
local native = Repo.byPath["Scripts/Hat/SnakeBanisherV3.lua"]
T.eq(Core.rowSub(native, 4), "Hat  ·  by MLG Super Killer +1", "no group on Favorites and Recent either")
T.eq(Core.rowSub(native, 1), "by MLG Super Killer +1")
local plain = entryOf("Scripts/Hat/Plain.lua", 2048)
T.eq(Core.rowSub(plain, 1), Util.fmtSize(2048), "no credit means the size")
T.eq(Core.rowSub(entryOf("Scripts/Hat/Empty.lua", 0), 1), "", "no credit and no size means nothing")
T.eq(Core.rowSub(entryOf("Scripts/Limb/Zed.lua", 10), 3), "Limb", "no credit means just the kind")

T.section("scripts_view: the small label on the right")
local label, tone = Core.rowState(native, nil, nil)
T.eq(label, "", "the hub's own scripts follow your pick too, so they have no label")
T.eq(tone, "dim")
label, tone = Core.rowState(dub, nil, nil)
T.eq(label, "", "a script that follows your pick has no label")
T.eq(tone, "dim")
label, tone = Core.rowState(native, { kind = "script", status = "running" }, nil)
T.eq(label, "Running")
T.eq(tone, "ok")
label, tone = Core.rowState(dub, { kind = "script", status = "error" }, nil)
T.eq(label, "Error")
T.eq(tone, "bad")
label, tone = Core.rowState(dub, nil, true)
T.eq(label, "Starting")
T.eq(tone, "warn")
label, tone = Core.rowState(native, { kind = "commands", active = false }, nil)
T.eq(label, "", "a stopped command script is not running")
label = Core.rowState(native, { kind = "commands", active = true }, nil)
T.eq(label, "Running")
local keepReanim = Core.Reanim
Core.Reanim = { current = function() return native.path end }
label, tone = Core.rowState(native, { kind = "script", status = "running" }, nil)
T.eq(label, "Active", "the script you are reanimated with says Active")
T.eq(tone, "ok")
label = Core.rowState(dub, { kind = "script", status = "running" }, nil)
T.eq(label, "Running", "others still say Running")
label = Core.rowState(native, { kind = "script", status = "error" }, nil)
T.eq(label, "Error", "an error still shows over Active")
Core.Reanim = keepReanim
T.eq(Core.toneColor("ok"), "G")
T.eq(Core.toneColor("warn"), "Y")
T.eq(Core.toneColor("bad"), "R")
T.eq(Core.toneColor("dim"), "D")
T.eq(Core.toneColor("anything"), "D")
T.eq(Core.toneColor(nil), "D")

T.section("scripts_view: every shipped script lands in the right place")
local seen = 0
for path, item in pairs(Repo.manifest) do
	local e = Repo.byPath[path]
	if e then
		seen += 1
		T.eq(Core.entryKind(e), item.kind, path)
		T.same(item.reanim, { "atsuko", "fdless" }, path .. " runs on either hat reanimation")
		T.ok(e.name ~= "" and not string.find(e.name, "%.lua"), path .. " has a clean name: " .. e.name)
	end
end
T.eq(seen, 12, "the twelve listed scripts are all in the manifest")

for _, name in ipairs(NAMES) do
	_G[name] = saved[name]
end
