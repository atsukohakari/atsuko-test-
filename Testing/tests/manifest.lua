local Mod = loadmodule("Hub/modules/manifest.lua")

local REAL_PATH = "Scripts/Hat/NeptunianV.lua"

local function keys(tbl)
	local n = 0
	for _ in pairs(tbl) do
		n += 1
	end
	return n
end

T.section("manifest: item cleans one entry")
T.eq(Mod.item(nil), nil)
T.eq(Mod.item("text"), nil)
T.eq(Mod.item(7), nil)
T.eq(Mod.item({}), nil, "an empty entry gives nothing")
T.eq(Mod.item({ kind = "nope", needsfd = "yes", reanim = 5, credit = {}, name = "   ", desc = "" }), nil, "only bad fields gives nothing")
local full = Mod.item({ name = "  Neptunian V  ", kind = "hat", reanim = { "fdless", "atsuko" }, needsfd = true, credit = { "Tory", "NoobyGames12" }, desc = "A sword script" })
T.eq(full.name, "Neptunian V")
T.eq(full.kind, "hat")
T.same(full.reanim, { "fdless", "atsuko" })
T.eq(full.needsfd, true)
T.same(full.credit, { "Tory", "NoobyGames12" })
T.eq(full.desc, "A sword script")
T.eq(Mod.item({ kind = "limb" }).kind, "limb")
T.eq(Mod.item({ kind = "Hat" }), nil, "kind is case sensitive")
T.eq(Mod.item({ name = "x", needsfd = false }).needsfd, nil)
T.eq(Mod.item({ name = "x", needsfd = "true" }).needsfd, nil, "needsfd must be a real true")
T.eq(Mod.item({ name = "a\nb\tc" }).name, "a b c", "control characters become spaces")

T.section("manifest: item limits")
T.eq(#Mod.item({ name = string.rep("n", 90) }).name, 60)
T.eq(#Mod.item({ name = string.rep("n", 60) }).name, 60)
T.eq(#Mod.item({ name = string.rep("n", 61) }).name, 60, "one over the limit is cut")
T.eq(#Mod.item({ desc = string.rep("d", 401) }).desc, 400)
T.eq(#Mod.item({ desc = string.rep("d", 400) }).desc, 400)
T.eq(#Mod.item({ desc = string.rep("d", 900) }).desc, 400)
T.same(Mod.item({ reanim = "fdless" }).reanim, { "fdless" }, "a string becomes a list")
local many = {}
for i = 1, 12 do
	many[i] = "r" .. i
end
T.eq(#Mod.item({ reanim = many }).reanim, 8)
T.eq(#Mod.item({ credit = many }).credit, 8)
T.eq(#Mod.item({ reanim = { string.rep("z", 40) } }).reanim[1], 24)
T.eq(#Mod.item({ credit = { string.rep("z", 100) } }).credit[1], 60)
T.same(Mod.item({ credit = { "", "  ", "Tory", 5, "NoobyGames12" } }).credit, { "Tory", "NoobyGames12" }, "blank and non-text entries are skipped")
T.eq(Mod.item({ credit = { "", "  " } }), nil)

T.section("manifest: parse refuses a bad manifest")
local nothing, why = Mod.parse(nil, jsondecode)
T.eq(nothing, nil)
T.eq(type(why), "string")
T.eq((Mod.parse("", jsondecode)), nil)
T.eq((Mod.parse(string.rep("x", 400001), jsondecode)), nil, "a huge body is refused")
local shell = '{"scripts":{},"pad":"'
local atLimit = shell .. string.rep("p", 400000 - #shell - 2) .. '"}'
T.eq(#atLimit, 400000)
T.eq(type((Mod.parse(atLimit, jsondecode))), "table", "a body of exactly 400000 characters is read")
T.eq((Mod.parse(atLimit .. " ", jsondecode)), nil, "one character more is refused")
T.eq((Mod.parse("this is not json", jsondecode)), nil)
T.eq((Mod.parse('{"version":1}', jsondecode)), nil, "no scripts table")
T.eq((Mod.parse('{"scripts":"nope"}', jsondecode)), nil)
local listy, listyCount = Mod.parse('{"scripts":[1,2,3]}', jsondecode)
T.eq(listyCount, 0, "a list of numbers gives no entries")
T.eq(keys(listy), 0)
local blown, blownWhy = Mod.parse("{}", function()
	error("decoder blew up")
end)
T.eq(blown, nil, "a decoder that errors is turned into a refusal")
T.eq(blownWhy, "the manifest could not be read")

T.section("manifest: parse keeps good entries")
local good, goodCount = Mod.parse('{"version":1,"scripts":{"Scripts/Hat/A.lua":{"name":"A","kind":"hat"},"Scripts/Limb/B.luau":{"name":"B","credit":["X"]},"Scripts/C.txt":{"desc":"only text"}}}', jsondecode)
T.eq(goodCount, 3)
T.eq(good["Scripts/Hat/A.lua"].name, "A")
T.same(good["Scripts/Limb/B.luau"].credit, { "X" })
T.eq(good["Scripts/C.txt"].desc, "only text")
local skipped, skippedCount = Mod.parse('{"scripts":{"Scripts/Hat/A.lua":{"name":"A"},"Scripts/Hat/B.lua":{},"Scripts/Hat/C.lua":"text","Scripts/Hat/D.lua":{"kind":"zzz"}}}', jsondecode)
T.eq(skippedCount, 1, "entries with nothing usable are dropped")
T.eq(keys(skipped), 1)

T.section("manifest: parse path safety")
local unsafe = '{"scripts":{'
	.. '"Scripts/Hat/ok.lua":{"name":"ok"},'
	.. '"../Scripts/Hat/up.lua":{"name":"up"},'
	.. '"Scripts/../Hat/mid.lua":{"name":"mid"},'
	.. '"/Scripts/Hat/abs.lua":{"name":"abs"},'
	.. '"Scripts\\\\Hat\\\\back.lua":{"name":"back"},'
	.. '"Scripts/Hat/noext":{"name":"noext"},'
	.. '"Scripts/Hat/tab\\tname.lua":{"name":"tab"},'
	.. '"Scripts/Hat/dot.":{"name":"dot"},'
	.. '"":{"name":"empty"}'
	.. "}}"
local safe, safeCount = Mod.parse(unsafe, jsondecode)
T.eq(safeCount, 1, "only the clean path survives")
T.eq(safe["Scripts/Hat/ok.lua"].name, "ok")
T.eq(keys(safe), 1)
local longPath = "Scripts/Hat/" .. string.rep("p", 190) .. ".lua"
local longOut, longCount = Mod.parse('{"scripts":{"' .. longPath .. '":{"name":"long"},"Scripts/Hat/short.lua":{"name":"short"}}}', jsondecode)
T.eq(longCount, 1, "a path over 200 characters is dropped")
T.eq(longOut["Scripts/Hat/short.lua"].name, "short")

T.section("manifest: parse caps the number of entries")
local parts = {}
for i = 1, 700 do
	parts[i] = string.format('"Scripts/Hat/s%d.lua":{"name":"s%d"}', i, i)
end
local capped, cappedCount = Mod.parse('{"scripts":{' .. table.concat(parts, ",") .. "}}", jsondecode)
T.eq(cappedCount, 600)
T.eq(keys(capped), 600)

T.section("manifest: apply writes names and facts onto the list")
local scripts = Mod.parse('{"scripts":{"' .. REAL_PATH .. '":{"name":"Neptunian V","kind":"hat","reanim":["fdless"],"needsfd":true,"credit":["Tory","NoobyGames12","MyWorld & rqz"]},"Scripts/Hat/OnlyKind.lua":{"kind":"limb"}}}', jsondecode)
local entries = {
	{ path = REAL_PATH, name = "NeptunianV", category = "Hat / FDless" },
	{ path = "Scripts/Hat/Other.lua", name = "Other", category = "Hat" },
	{ path = "Scripts/Hat/OnlyKind.lua", name = "OnlyKind", category = "Hat" },
}
T.eq(Mod.apply(entries, scripts), 2)
T.eq(entries[1].name, "Neptunian V")
T.eq(entries[1].category, "Hat / FDless", "the category is not touched")
T.eq(entries[1].kind, "hat")
T.same(entries[1].reanim, { "fdless" })
T.eq(entries[1].needsfd, true)
T.same(entries[1].credit, { "Tory", "NoobyGames12", "MyWorld & rqz" })
T.eq(entries[2].name, "Other", "a script the manifest does not know stays as it was")
T.eq(entries[2].kind, nil)
T.eq(entries[2].credit, nil)
T.eq(entries[3].name, "OnlyKind", "no name in the manifest keeps the file name")
T.eq(entries[3].kind, "limb")
local later = Mod.parse('{"scripts":{"' .. REAL_PATH .. '":{"name":"Neptunian V!"}}}', jsondecode)
T.eq(Mod.apply(entries, later), 1)
T.eq(entries[1].name, "Neptunian V!")
T.eq(entries[1].kind, nil, "a newer manifest replaces the old facts")
T.eq(entries[1].credit, nil)
T.eq(Mod.apply(nil, later), 0)
T.eq(Mod.apply(entries, nil), 0)
T.eq(Mod.apply({}, later), 0)

T.section("manifest: merge never beats the script's own header")
local own = { name = "Header Name", kind = "limb", needsfd = "false", reanim = "any", author = "Header Author", credit = "Header Credit", desc = "own words", about = "own words" }
local item = Mod.item({ name = "Manifest Name", kind = "hat", needsfd = true, reanim = { "fdless", "atsuko" }, credit = { "X", "Y" }, desc = "manifest words" })
Mod.merge(own, item)
T.eq(own.name, "Header Name")
T.eq(own.kind, "limb")
T.eq(own.needsfd, "false")
T.eq(own.reanim, "any")
T.eq(own.author, "Header Author")
T.eq(own.credit, "Header Credit")
T.eq(own.about, "own words", "an @desc line in the script wins")

T.section("manifest: merge fills what the header leaves out")
local bare = { lines = 10 }
Mod.merge(bare, item)
T.eq(bare.name, "Manifest Name")
T.eq(bare.kind, "hat")
T.eq(bare.needsfd, true)
T.eq(bare.reanim, "fdless, atsuko")
T.eq(bare.author, "X, Y")
T.eq(bare.credit, "X, Y")
T.eq(bare.about, "manifest words")
T.eq(bare.lines, 10)
local blankAuthor = { author = "", credit = "" }
Mod.merge(blankAuthor, item)
T.eq(blankAuthor.author, "X, Y", "an empty author line counts as missing")
T.eq(blankAuthor.credit, "X, Y")
local guessed = { about = "the first lines of the header comment" }
Mod.merge(guessed, item)
T.eq(guessed.about, "manifest words", "the manifest beats a description guessed from a comment")
local noDesc = Mod.item({ name = "N" })
local keepAbout = { about = "guessed text" }
Mod.merge(keepAbout, noDesc)
T.eq(keepAbout.about, "guessed text", "no manifest description keeps the guessed one")
T.eq(keepAbout.author, nil)
local same = { name = "x" }
T.eq(Mod.merge(same, nil), same)
T.eq(Mod.merge(nil, item), nil)
T.eq(Mod.merge(same, "text"), same)

T.section("manifest: the real Scripts/manifest.json")
local realText = readsource("Scripts/manifest.json")
local real = jsondecode(realText)
T.eq(type(real), "table")
T.eq(real.version, 1)
local realScripts, realCount = Mod.parse(realText, jsondecode)
T.eq(type(realScripts), "table", "the real manifest passes the parser")
local listed = 0
for path in pairs(real.scripts) do
	listed += 1
	T.ok(pcall(readsource, path), "the manifest names a file that exists: " .. path)
	T.ok(realScripts[path] ~= nil, "the parser keeps " .. path)
end
T.eq(realCount, listed, "no entry of the real manifest is dropped")
local nep = realScripts[REAL_PATH]
T.eq(nep.name, "Neptunian V")
T.eq(nep.kind, "hat")
T.eq(nep.needsfd, true)
T.same(nep.credit, { "Tory", "NoobyGames12", "MyWorld & rqz" })
T.eq(nep.desc, nil, "Neptunian V has no description, Main Scripts shows none")
for path, item in pairs(realScripts) do
	T.eq(item.desc, nil, path .. " has no description")
end

T.section("manifest: Neptunian V is in the hub with its credits")
local nepSource = readsource(REAL_PATH)
T.ok(string.find(nepSource, 'ned.Text = "Yeh! Im Tory"', 1, true), "Tory's on-screen label is back")
T.ok(not string.find(nepSource, 'ned.Text = "Neptunian"', 1, true), "the zip's label is gone")
local hub = readsource("Hub/AtsukoHub.lua")
local creditsText = readsource("Hub/credits.json")
local credits = jsondecode(creditsText)
local function creditOf(id)
	for _, entry in ipairs(credits.people) do
		if entry.id == id then
			return entry
		end
	end
	return nil
end
local toryCredit = creditOf("tory")
T.ok(toryCredit ~= nil and toryCredit.links.discord == "https://discord.gg/kMuXv6PuXp", "Tory's Discord is in the credits")
T.ok(toryCredit ~= nil and toryCredit.links.youtube == "https://youtube.com/@jskfhggjxu", "Tory's YouTube is in the credits")
T.ok(not string.find(hub, "si=nFcGXXbQmPEqKB1e", 1, true) and not string.find(creditsText, "si=nFcGXXbQmPEqKB1e", 1, true), "the share tag is not kept")
local noobyCredit = creditOf("noobygames12")
T.ok(noobyCredit ~= nil and noobyCredit.roles[1] == "Neptunian V author", "NoobyGames12 is in the credits")
T.ok(string.find(hub, "reanimation = true", 1, true), "the Reanimation folder stays out of the script list")
T.ok(string.find(hub, "alignment = true", 1, true), "the Alignment folder stays out of the script list")
T.ok(string.find(hub, 'Core.MANIFEST_PATH = "Scripts/manifest.json"', 1, true), "the hub reads the manifest")
