local hub = readsource("Hub/AtsukoHub.lua")

local REAL = "Scripts/Hat/FDless/NeptunianV.lua"
local SHIPPED = 0
for _ in pairs(jsondecode(readsource("Scripts/manifest.json")).scripts) do
	SHIPPED += 1
end
local NAMES = { "Core", "Repo", "Util", "Origin", "Net", "FS", "Log", "X", "jsonDecode", "SRC", "HOME_REPO", "LOCAL_DIR", "HUB_DIR" }

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

LOCAL_DIR = "AtsukoHub"
HUB_DIR = "Hub"
HOME_REPO = "https://raw.githubusercontent.com/atsukohakari/Atsuko/main/"
SRC = { owner = "atsukohakari", repo = "Atsuko", branch = "main" }
Core = { SCRIPT_EXT = { lua = true, luau = true, txt = true }, mods = {}, ctx = {} }
Util = {}
Origin = { root = nil }
X = { loadstring = loadstring }
Log = { items = {} }
function Log.add(kind, src, msg)
	Log.items[#Log.items + 1] = { kind = kind, src = src, msg = msg }
end
jsonDecode = function(text)
	if type(text) ~= "string" then
		return nil
	end
	return jsondecode(text)
end

local disk = {}
FS = {
	read = function(path)
		return disk[path]
	end,
	write = function(path, body)
		disk[path] = body
		return true
	end,
}

local served = {}
local net = { calls = {}, offline = false, override = {} }
Net = {
	get = function(url)
		net.calls[#net.calls + 1] = url
		if net.offline then
			return false, "no connection"
		end
		if string.sub(url, 1, #HOME_REPO) ~= HOME_REPO then
			return false, "not the repo"
		end
		local rel = string.gsub(string.sub(url, #HOME_REPO + 1), "%?.*$", "")
		if net.override[rel] ~= nil then
			if net.override[rel] == false then
				return false, "HTTP 404"
			end
			return true, net.override[rel]
		end
		local ok, body = pcall(readsource, rel)
		if ok then
			served[rel] = (served[rel] or 0) + 1
			return true, body
		end
		return false, "HTTP 404"
	end,
}

run(fn("function Util.trim(s)"), "Util.trim")
run(fn("function Util.urlPath(p)"), "Util.urlPath")
run(fn("function Util.prettyName(path)"), "Util.prettyName")
run(fn("function Util.firstLine(s)"), "Util.firstLine")
run(slice("Core.LIST_CACHE =", "local Repo = {"), "cache paths and hidden folders")
Repo = { entries = {}, byPath = {}, remote = {}, state = "idle", src = {}, meta = {}, manifest = {}, sourceSeq = 0, sig = "" }
for _, header in ipairs({
	"function Repo.key()",
	"function Repo.raw(path)",
	"function Repo.isScript(path)",
	"function Core.makeEntry(path, size)",
	"function Core.sortEntries(list)",
	"function Repo.manifestModule()",
	"function Repo.useManifest(body)",
	"function Repo.loadManifest(cacheOnly)",
	"function Repo.set(list)",
	"function Repo.loadCache()",
	"function Core.validSource(b)",
	"function Repo.parseMeta(src)",
	"function Repo.getMeta(path)",
	"function Core.isPage(src)",
	"function Core.fileSource(rel, needReturn)",
	"function Core.moduleSource(name)",
	"function Core.loadModule(name, retry, context)",
}) do
	run(fn(header), header)
end

local function fresh()
	disk = {}
	served = {}
	net.calls = {}
	net.offline = false
	net.override = {}
	Origin.root = nil
	Log.items = {}
	Core.mods = {}
	Repo.entries, Repo.byPath, Repo.src, Repo.meta, Repo.manifest = {}, {}, {}, {}, {}
end

local function errorsLogged()
	local n = 0
	for _, item in ipairs(Log.items) do
		if item.kind == "error" then
			n += 1
		end
	end
	return n
end

local function listOf(paths)
	local list = {}
	for _, path in ipairs(paths) do
		list[#list + 1] = Core.makeEntry(path, 100)
	end
	return list
end

T.section("repo_manifest: the shipped manifest")
T.ok(SHIPPED >= 6, "the Main Scripts are all listed: " .. tostring(SHIPPED))

T.section("repo_manifest: which files count as scripts")
for _, path in ipairs({
	REAL,
	"Scripts/Hat/DubstepGun.lua",
	"Scripts/Limb/Gelatek.lua",
	"Scripts/Tools/a.txt",
	"Scripts/Hat/FDless/DubstepGun.lua",
	"Scripts/Hat/FDless/LastStar.lua",
	"Scripts/Hat/FDless/NeptunianVGun.lua",
	"Scripts/Hat/FDless/TheHotline.lua",
}) do
	T.eq(Repo.isScript(path), true, path)
end
for _, path in ipairs({
	"Reanimation/Hat/FDless.lua",
	"Reanimation/Limb/Gelatek.lua",
	"Reanimation/providers/fdless.lua",
	"Alignment/alignment.lua",
	"Hub/AtsukoHub.lua",
	"Hub/modules/manifest.lua",
	"Testing/tests/manifest.lua",
	"Scripts/manifest.json",
	"Scripts/patches/NeptunianV.patch",
	"Scripts/_unlisted/TheSniper.lua",
	"Scripts/_TEMPLATE.lua",
	"Scripts/_TEMPLATE_HAT.lua",
	"Scripts/_TEMPLATE_LIMB.lua",
	"README.md",
	"Scripts/Hat/readme.txt",
}) do
	T.eq(Repo.isScript(path), false, path)
end
T.eq(Repo.isScript("reanimation/Hat/FDless.lua"), false, "folder names are matched without caring about capitals")
T.eq(Repo.isScript("ALIGNMENT/alignment.lua"), false)

T.section("repo_manifest: first run from GitHub with no cache")
fresh()
local ok, why = Repo.loadManifest(true)
T.eq(ok, false, "cache only and nothing cached")
T.eq(why, "no manifest yet")
T.eq(#net.calls, 0, "cache only never asks the network for the manifest")
T.eq(next(Repo.manifest), nil)
T.eq(errorsLogged(), 0, "nothing cached is not an error")
ok, why = Repo.loadManifest(false)
T.eq(ok, true)
T.eq(why, SHIPPED, "the number of scripts in the shipped manifest")
T.eq(Repo.manifest[REAL].name, "Neptunian V")
T.eq(disk["AtsukoHub/cache/manifest.json"], readsource("Scripts/manifest.json"), "the manifest is cached for the next start")
T.eq(disk["AtsukoHub/cache/mod_manifest.lua"], readsource("Hub/modules/manifest.lua"), "the module is cached too")
local asked = false
for _, url in ipairs(net.calls) do
	if string.find(url, HOME_REPO .. "Scripts/manifest.json?t=", 1, true) then
		asked = true
	end
end
T.ok(asked, "the manifest was asked for from the repo")

T.section("repo_manifest: names, order and credits on the list")
local list = listOf({ "Scripts/Hat/Zebra.lua", REAL, "Scripts/Hat/Apple.lua", "Scripts/Limb/Zed.lua" })
T.eq(list[2].name, "NeptunianV", "before the manifest the name is the file name")
Repo.set(list)
T.eq(Repo.byPath[REAL].name, "Neptunian V")
T.eq(Repo.byPath[REAL].category, "Hat / FDless")
T.eq(Repo.byPath[REAL].kind, "hat")
T.same(Repo.byPath[REAL].credit, { "Tory", "NoobyGames12", "MyWorld & rqz" })
T.same(Repo.byPath[REAL].reanim, { "atsuko", "fdless" }, "every hat script can run on either hat reanimation")
T.eq(Repo.byPath[REAL].needsfd, true)
T.eq(Repo.byPath["Scripts/Hat/Apple.lua"].name, "Apple", "scripts the manifest does not know are left alone")
T.eq(Repo.byPath["Scripts/Hat/Apple.lua"].credit, nil)
T.eq(#Repo.entries, 4)
local order = {}
for _, e in ipairs(Repo.entries) do
	order[#order + 1] = e.path
end
T.same(order, { "Scripts/Hat/Apple.lua", "Scripts/Hat/Zebra.lua", REAL, "Scripts/Limb/Zed.lua" })
T.ok(string.find(Repo.sig, REAL .. ":100", 1, true), "the list signature still follows path and size")

T.section("repo_manifest: the details of a script")
Repo.src[REAL] = readsource(REAL)
local meta = Repo.getMeta(REAL)
T.eq(meta.author, "Tory, NoobyGames12, MyWorld & rqz")
T.eq(meta.credit, "Tory, NoobyGames12, MyWorld & rqz")
T.eq(meta.name, "Neptunian V")
T.eq(meta.about, Repo.manifest[REAL].desc, "the manifest text beats the comment guessed from the header")
local _, newlines = string.gsub(Repo.src[REAL], "\n", "")
T.eq(meta.lines, newlines + 1, "the line count still comes from the script")
T.ok(meta.lines > 1000, "and it is a whole script, not a stub")
T.eq(Repo.getMeta(REAL), meta, "the details are kept after the first read")
Repo.src["Scripts/Hat/DubstepGun.lua"] = readsource("Scripts/Hat/DubstepGun.lua")
local dub = Repo.getMeta("Scripts/Hat/DubstepGun.lua")
T.eq(dub.author, "Supr14", "the script's own @author stays")
T.eq(dub.about, Repo.manifest["Scripts/Hat/DubstepGun.lua"].desc, "with no @desc in the file the manifest text is used")
T.ok(string.find(dub.about, "Dubstep Gun rebuilt for the hub", 1, true) == 1, "the short, formal text from the manifest")
T.eq(Repo.getMeta("Scripts/Hat/Nothing.lua"), nil, "a script whose source is not loaded has no details yet")

T.section("repo_manifest: second start from the cache while offline")
local cachedFiles = {}
for k, v in pairs(disk) do
	cachedFiles[k] = v
end
fresh()
for k, v in pairs(cachedFiles) do
	disk[k] = v
end
net.offline = true
ok = Repo.loadManifest(true)
T.eq(ok, true, "the cached manifest is used")
T.eq(Repo.manifest[REAL].name, "Neptunian V")
Repo.manifest = {}
ok = Repo.loadManifest(false)
T.eq(ok, true, "a failed download falls back to the cache")
T.eq(Repo.manifest[REAL].name, "Neptunian V")
T.eq(errorsLogged(), 0)

T.section("repo_manifest: the saved script list uses the manifest and drops the hidden folders")
fresh()
disk["AtsukoHub/cache/manifest.json"] = readsource("Scripts/manifest.json")
disk["AtsukoHub/cache/mod_manifest.lua"] = readsource("Hub/modules/manifest.lua")
disk[Core.LIST_CACHE] = '{"key":"atsukohakari/Atsuko@main","list":['
	.. '{"path":"Scripts/Hat/FDless/NeptunianV.lua","size":263512},'
	.. '{"path":"Reanimation/Hat/FDless.lua","size":900},'
	.. '{"path":"Alignment/alignment.lua","size":900},'
	.. '{"path":"Scripts/Hat/DubstepGun.lua","size":40}]}'
net.offline = true
T.eq(Repo.loadCache(), true)
T.eq(Repo.state, "cached")
T.eq(#Repo.entries, 2, "only the two real scripts are listed")
T.eq(Repo.byPath[REAL].name, "Neptunian V", "the first paint already has the manifest name")
T.eq(Repo.byPath["Reanimation/Hat/FDless.lua"], nil)
T.eq(Repo.byPath["Alignment/alignment.lua"], nil)
disk[Core.LIST_CACHE] = '{"key":"someone/else@main","list":[]}'
T.eq(Repo.loadCache(), false, "a list saved for another source is ignored")

T.section("repo_manifest: a bad manifest never breaks the list")
fresh()
ok = Repo.loadManifest(false)
T.eq(ok, true)
local good = Repo.manifest
net.override["Scripts/manifest.json"] = "this is not json at all"
ok, why = Repo.loadManifest(false)
T.eq(ok, false)
T.eq(Repo.manifest, good, "the last good manifest is kept")
T.eq(errorsLogged(), 1, "the problem is written to the log")
T.eq(disk["AtsukoHub/cache/manifest.json"], readsource("Scripts/manifest.json"), "a bad download does not replace the cache")
net.override["Scripts/manifest.json"] = "<!DOCTYPE html><html><body>Not Found</body></html>"
ok = Repo.loadManifest(false)
T.eq(ok, true, "an error page is not taken for the manifest")
T.eq(disk["AtsukoHub/cache/manifest.json"], readsource("Scripts/manifest.json"))
T.eq(errorsLogged(), 1, "an error page adds nothing to the log")
net.override["Scripts/manifest.json"] = false
ok = Repo.loadManifest(false)
T.eq(ok, true, "a missing file falls back to the cache")
net.override["Scripts/manifest.json"] = '{"scripts":{"../x.lua":{"name":"bad"},"/y.lua":{"name":"bad"},"Scripts/Hat/Ok.lua":{"name":"Fine","kind":"limb"}}}'
ok, why = Repo.loadManifest(false)
T.eq(ok, true)
T.eq(why, 1, "unsafe paths are dropped")
T.eq(Repo.manifest["../x.lua"], nil)
T.eq(Repo.manifest["Scripts/Hat/Ok.lua"].name, "Fine")
list = listOf({ "Scripts/Hat/Ok.lua", "Scripts/Hat/Other.lua" })
Repo.set(list)
T.eq(Repo.byPath["Scripts/Hat/Ok.lua"].name, "Fine")
T.eq(Repo.byPath["Scripts/Hat/Other.lua"].name, "Other")

T.section("repo_manifest: a new manifest replaces what was worked out from the old one")
fresh()
Repo.src[REAL] = readsource(REAL)
local before = Repo.getMeta(REAL)
T.eq(before.author, nil, "without a manifest the script has no author line")
ok = Repo.loadManifest(false)
T.eq(ok, true)
local after = Repo.getMeta(REAL)
T.eq(after.author, "Tory, NoobyGames12, MyWorld & rqz", "the details are worked out again after the manifest arrives")
T.ok(after ~= before)

T.section("repo_manifest: an unreadable cache file")
fresh()
disk["AtsukoHub/cache/manifest.json"] = false
ok, why = Repo.loadManifest(true)
T.eq(ok, false)
T.eq(why, "no manifest yet")
T.eq(errorsLogged(), 0)

T.section("repo_manifest: the list works without the manifest module")
fresh()
Repo.set(listOf({ REAL, "Scripts/Hat/DubstepGun.lua" }))
T.eq(Repo.byPath[REAL].name, "NeptunianV", "no manifest loaded, so the file name is shown")
T.eq(Repo.manifestModule(), nil)
Repo.src[REAL] = readsource(REAL)
T.ok(Repo.getMeta(REAL) ~= nil, "the details still work")
net.offline = true
Core.mods = {}
ok = Repo.useManifest(readsource("Scripts/manifest.json"))
T.eq(ok, false, "the module could not be fetched")
T.eq(errorsLogged() >= 1, true)
T.eq(next(Repo.manifest), nil)

T.section("repo_manifest: running from your own folder")
fresh()
Origin.root = "Atsuko Hub"
ok, why = Repo.loadManifest(true)
T.eq(ok, true, "your folder is read even when only the cache is asked for")
T.eq(why, SHIPPED, "the number of scripts in the shipped manifest")
T.eq(Repo.manifest[REAL].name, "Neptunian V")
T.eq(next(disk), nil, "nothing is cached while running from your folder")
net.override["Scripts/manifest.json"] = false
Repo.manifest = {}
ok, why = Repo.loadManifest(false)
T.eq(ok, false, "no manifest file in your folder")
T.eq(why, "no manifest yet")
T.eq(next(disk), nil)
T.eq(errorsLogged(), 0, "a missing manifest in your folder is not an error")
Repo.set(listOf({ REAL }))
T.eq(Repo.byPath[REAL].name, "NeptunianV", "the list still works without it")
disk["AtsukoHub/cache/manifest.json"] = readsource("Scripts/manifest.json")
disk["AtsukoHub/cache/mod_manifest.lua"] = readsource("Hub/modules/manifest.lua")
Core.mods = {}
Repo.manifest = {}
ok, why = Repo.loadManifest(false)
T.eq(ok, false, "an old GitHub cache is not used instead of your folder")
T.eq(next(Repo.manifest), nil)

T.section("repo_manifest: any file of the repo can be fetched and cached")
fresh()
local registryPath = "Reanimation/providers/registry.lua"
local registryCache = "AtsukoHub/cache/file_Reanimation_providers_registry.lua"
local got, problem = Core.fileSource(registryPath, true)
T.eq(got, readsource(registryPath))
T.eq(problem, nil)
T.eq(disk[registryCache], got, "it is cached for the next start")
net.offline = true
T.eq(Core.fileSource(registryPath, true), got, "offline the cache is used")
got, problem = Core.fileSource("Reanimation/providers/fdless.lua", true)
T.eq(got, nil, "offline and never cached")
T.eq(problem, "couldn't download Reanimation/providers/fdless.lua")
net.offline = false
for _, bad in ipairs({ "", "/etc/passwd", "../x.lua", "a/../b.lua", "a/..", "..", "a/b/../../../c.lua" }) do
	got, problem = Core.fileSource(bad, false)
	T.eq(got, nil, "not allowed: " .. bad)
	T.eq(problem, "that file name isn't allowed")
end
got, problem = Core.fileSource(5, false)
T.eq(got, nil)
T.eq(problem, "that file name isn't allowed")
got, problem = Core.fileSource(nil, false)
T.eq(got, nil)
T.eq(problem, "that file name isn't allowed")
T.eq(Core.fileSource("a..b.lua", false), nil, "two dots in a name are not a way up")
local through = false
for _, url in ipairs(net.calls) do
	if string.find(url, "a..b.lua", 1, true) then
		through = true
	end
end
T.ok(through, "that name was allowed through to the download")
fresh()
net.override["Reanimation/x.lua"] = string.rep("a", 60)
got, problem = Core.fileSource("Reanimation/x.lua", true)
T.eq(got, nil, "a module with no return is not taken")
T.eq(problem, "couldn't download Reanimation/x.lua")
T.eq(disk["AtsukoHub/cache/file_Reanimation_x.lua"], nil, "and it is not cached")
T.eq(Core.fileSource("Reanimation/x.lua", false), string.rep("a", 60), "a file with no return is fine when none is needed")
fresh()
net.override["Reanimation/x.lua"] = "short"
got = Core.fileSource("Reanimation/x.lua", false)
T.eq(got, nil, "a tiny answer is not taken for a file")
fresh()
net.override["Reanimation/x.lua"] = "<html>" .. string.rep("a", 60) .. "return"
got = Core.fileSource("Reanimation/x.lua", false)
T.eq(got, nil, "an error page is not taken for a file")
T.eq(disk["AtsukoHub/cache/file_Reanimation_x.lua"], nil, "nothing bad is cached")
fresh()
net.override["Reanimation/x.lua"] = "return " .. string.rep("a", 60)
Core.fileSource("Reanimation/x.lua", true)
net.override["Reanimation/x.lua"] = "<html>" .. string.rep("a", 60) .. "return"
T.eq(Core.fileSource("Reanimation/x.lua", true), "return " .. string.rep("a", 60), "a bad answer falls back to the good cache")

fresh()
net.offline = true
disk["AtsukoHub/cache/file_Reanimation_x.lua"] = "short"
got, problem = Core.fileSource("Reanimation/x.lua", false)
T.eq(got, nil, "a cache that is too small to be a file is not used")
T.eq(problem, "couldn't download Reanimation/x.lua")
disk["AtsukoHub/cache/file_Reanimation_x.lua"] = string.rep("a", 60)
T.eq(Core.fileSource("Reanimation/x.lua", false), string.rep("a", 60), "a cache of a fair size is")
fresh()
net.override["Reanimation/y.lua"] = string.rep("a", 60)
got, problem = Core.loadModule("@Reanimation/y")
T.eq(got, nil, "an @ module without a return is not taken")
T.eq(problem, "couldn't download Reanimation/y.lua")

T.section("repo_manifest: an error page is told apart from a module that only mentions html")
for _, page in ipairs({
	"<html><body>404</body></html>",
	"<!DOCTYPE html><html>x</html>",
	"<!doctype html>",
	"  \n\t<HTML lang='en'>",
	"\239\187\191<!DOCTYPE HTML PUBLIC>",
	"<?xml version='1.0'?><error/>",
	"\r\n\r\n<head><title>Blocked</title>",
}) do
	T.eq(Core.isPage(page), true, "a page: " .. string.sub(page, 1, 20))
end
for _, code in ipairs({
	"return {}",
	"local x = 1\nreturn x",
	"return { sniff = function(s) return string.find(s, \"<html\", 1, true) end }",
	"",
}) do
	T.eq(Core.isPage(code), false, "not a page: " .. string.sub(code, 1, 24))
end
local deep = "return {} -- " .. string.rep("a", 500) .. " <html <!doctype"
T.eq(Core.isPage(deep), false, "html far down a long module is not a page")
fresh()
Origin.root = nil
net.override["Hub/modules/mentions.lua"] = "local M = {}\n" .. string.rep("-", 420) .. "\nM.a = \"<html\"\nM.b = \"<!doctype\"\nreturn M"
got, problem = Core.moduleSource("mentions")
T.ok(type(got) == "string" and #got > 400, "a module that only mentions html is taken: " .. tostring(problem))
T.ok(disk["AtsukoHub/cache/mod_mentions.lua"] ~= nil, "and cached")
fresh()
net.override["Hub/modules/oops.lua"] = "<!DOCTYPE html><html><body>" .. string.rep("a", 60) .. "return</body></html>"
got, problem = Core.moduleSource("oops")
T.eq(got, nil, "an error page is not taken for a module")
T.eq(problem, "couldn't download oops")
T.eq(disk["AtsukoHub/cache/mod_oops.lua"], nil, "and not cached")

T.section("repo_manifest: your own folder is used for any file, and the cache is left alone")
fresh()
Origin.root = "Atsuko Hub"
got, problem = Core.fileSource(registryPath, true)
T.eq(got, readsource(registryPath))
T.eq(next(disk), nil, "nothing is cached")
disk[registryCache] = "return " .. string.rep("old", 30)
net.override[registryPath] = false
got, problem = Core.fileSource(registryPath, true)
T.eq(got, nil, "an old GitHub cache is not used instead of your folder")
T.eq(problem, "couldn't find " .. registryPath .. " inside Atsuko Hub")

T.section("repo_manifest: modules from the Reanimation folder and the context a module gets")
fresh()
local registry = Core.loadModule("@Reanimation/providers/registry")
T.eq(type(registry), "table", "an @ name is read from the repo root")
T.same(registry.IDS, { "atsuko", "fdless", "gelatek", "uhhhhhh" })
T.eq(disk[registryCache], readsource(registryPath), "it is cached like any file")
T.eq(disk["AtsukoHub/cache/mod_@Reanimation_providers_registry.lua"], nil, "an @ module is not cached as a hub module")
T.eq(Core.loadModule("@Reanimation/providers/registry"), registry, "the second time it is the same table")
T.eq(errorsLogged(), 0)
local PROBE = "local M = {} function M.init(c) M.got = c end return M"
fresh()
net.override["Hub/modules/probe.lua"] = PROBE
local marker = { marker = true }
local probe = Core.loadModule("probe", nil, marker)
T.eq(probe.got, marker, "a module can be given its own context")
fresh()
net.override["Hub/modules/probe.lua"] = PROBE
probe = Core.loadModule("probe")
T.eq(probe.got, Core.ctx, "without one it gets the hub's")
fresh()
net.override["Hub/modules/probe.lua"] = false
got, problem = Core.loadModule("probe")
T.eq(got, nil)
T.eq(problem, "couldn't download probe")
net.override["Hub/modules/probe.lua"] = PROBE
got, problem = Core.loadModule("probe")
T.eq(got, nil, "a failed module is not tried again by itself")
T.eq(problem, "couldn't download probe")
probe = Core.loadModule("probe", true)
T.eq(type(probe), "table", "unless it is asked to try again")
T.ok(errorsLogged() >= 1, "the failure was logged")
fresh()
net.override["Hub/modules/probe.lua"] = "local M = {} function M.init(c) error('boom') end return M"
got, problem = Core.loadModule("probe", nil, marker)
T.eq(got, nil, "a module whose init fails is not kept")
T.ok(string.find(tostring(problem), "boom", 1, true) ~= nil)

for _, name in ipairs(NAMES) do
	_G[name] = saved[name]
end
