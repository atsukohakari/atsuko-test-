local Runner = loadmodule("Testing/mocks/boot_runner.lua")

local OLD, NEW = "AtsukoHub", "Atsuko Hub"
local PNG = "\137PNG\r\n\26\n" .. string.rep("p", 64)

local function folderTools(env)
	local function children(dir)
		local out, seen = {}, {}
		local prefix = dir .. "/"
		for path in pairs(env.files) do
			if string.sub(path, 1, #prefix) == prefix then
				local rest = string.sub(path, #prefix + 1)
				local head = string.match(rest, "^([^/]+)")
				if head and not seen[head] then
					seen[head] = true
					out[#out + 1] = prefix .. head
				end
			end
		end
		return out
	end
	local realList, realFolder = listfiles, isfolder
	listfiles = function(p)
		if p == OLD or string.sub(p, 1, #OLD + 1) == OLD .. "/" then
			return children(p)
		end
		return realList(p)
	end
	isfolder = function(p)
		if p == OLD or string.sub(p, 1, #OLD + 1) == OLD .. "/" then
			local prefix = p .. "/"
			for path in pairs(env.files) do
				if string.sub(path, 1, #prefix) == prefix then
					return true
				end
			end
			return false
		end
		return realFolder(p)
	end
end

local files = {
	[OLD .. "/settings.json"] = '{"theme":"midnight","favorites":{"Scripts/Hat/R6.lua":true}}',
	[OLD .. "/alignment_user.lua"] = "return { rows = {} }",
	[OLD .. "/boot.json"] = '{"step":"halfway","done":false}',
	[OLD .. "/owner.key"] = "secret-key-text",
	[OLD .. "/data/scriptart.json"] = '{"version":1,"items":{"Scripts/Hat/R6.lua":{"logo":{"src":"file","value":"me.png","cached":"AtsukoHub/cache/art/abc.png"}}}}',
	[OLD .. "/cache/art/abc.png"] = PNG,
	[OLD .. "/cache/list.json"] = '{"key":"old","list":[]}',
	[OLD .. "/cache/mod_home_page.lua"] = "return {}",
	[OLD .. "/myscripts/mine.lua"] = "print('mine')",
	[OLD .. "/music/song.mp3"] = string.rep("m", 200),
	[OLD .. "/emotes/pack.lua"] = "return {}",
	[NEW .. "/alignment_user.lua"] = "return { rows = { 'already here' } }",
}

T.section("save_folder: the hub saves in Atsuko Hub")
local src = readsource("Hub/AtsukoHub.lua")
T.ok(string.find(src, 'local LOCAL_DIR = "Atsuko Hub"', 1, true) ~= nil, "the save folder is Atsuko Hub, with a space")
for _, path in ipairs({ "Hub/modules/scriptart.lua", "Hub/modules/alignment.lua", "Hub/modules/credits_ui.lua", "Hub/Emotes.lua", "Hub/UhhMoveset.lua" }) do
	local text = readsource(path)
	T.eq(string.find(text, '"AtsukoHub/', 1, true), nil, path .. " saves nothing in the old folder")
	T.ok(string.find(text, '"Atsuko Hub/', 1, true) ~= nil, path .. " saves in Atsuko Hub")
end

local copy = {}
for k, v in pairs(files) do
	copy[k] = v
end
local env = Runner.boot({ seconds = 14, files = copy, before = folderTools })
T.ok(env.mainOk, "the hub starts: " .. tostring(env.mainErr))

T.section("save_folder: the old saves come along")
T.eq(env.files[NEW .. "/owner.key"], "secret-key-text", "files are copied as they are")
T.ok(type(env.files[NEW .. "/settings.json"]) == "string" and string.find(env.files[NEW .. "/settings.json"], "midnight", 1, true) ~= nil, "the settings came along and were used")
T.eq(env.core and env.core.movedNow ~= nil and env.core.movedNow > 0, true, "the copy ran before the settings were read")
T.eq(env.files[NEW .. "/myscripts/mine.lua"], "print('mine')", "your own scripts came along")
T.eq(env.files[NEW .. "/cache/art/abc.png"], PNG, "the pictures your logos use came along")
local art = env.files[NEW .. "/data/scriptart.json"] or ""
T.ok(string.find(art, '"Atsuko Hub/cache/art/abc.png"', 1, true) ~= nil, "and the logo now points at the new folder: " .. art)
T.eq(string.find(art, "AtsukoHub/", 1, true), nil, "nothing in it points at the old folder")

T.section("save_folder: nothing is overwritten")
T.eq(env.files[NEW .. "/alignment_user.lua"], "return { rows = { 'already here' } }", "a file already in Atsuko Hub is never replaced")
T.ok(env.files[NEW .. "/boot.json"] ~= '{"step":"halfway","done":false}', "the old start note isn't copied, so an old crash doesn't start the hub in safe mode")
T.eq(env.core and env.core.Boot and env.core.Boot.safe, false, "and it isn't in safe mode")
T.ok(env.files[NEW .. "/cache/list.json"] ~= files[OLD .. "/cache/list.json"], "caches the hub can download again are left behind")
do
	local wrong = {}
	for _, e in ipairs(env.hub and env.hub.Repo and env.hub.Repo.entries or {}) do
		local top = string.match(e.path, "^([^/]+)") or ""
		if e.path == "alignment_user.lua" or top == "myscripts" or top == "cache" or top == "emotes" or top == "data" then
			wrong[#wrong + 1] = e.path
		end
	end
	T.ok(env.hub and env.hub.Repo and #env.hub.Repo.entries > 10, "the script list is there")
	T.eq(table.concat(wrong, ", "), "", "the hub's own saves never show up as scripts, even when the script folder is Atsuko Hub too")
end
T.eq(env.files[NEW .. "/cache/mod_home_page.lua"], nil, "old module copies too, so nothing old is run")
for path, data in pairs(files) do
	if string.sub(path, 1, #OLD + 1) == OLD .. "/" then
		T.eq(env.files[path], data, "the old folder is left as it was: " .. path)
	end
end

T.section("save_folder: the big folders come a little later")
T.eq(env.files[NEW .. "/music/song.mp3"], string.rep("m", 200), "your music came along after the start")
T.eq(env.files[NEW .. "/emotes/pack.lua"], "return {}", "and the emotes")
T.ok(type(env.files[NEW .. "/moved.txt"]) == "string", "the copy is marked as done")

T.section("save_folder: it only happens once")
do
	local again = {}
	for k, v in pairs(env.files) do
		again[k] = v
	end
	again[NEW .. "/owner.key"] = nil
	local env2 = Runner.boot({ seconds = 10, files = again, before = folderTools })
	T.ok(env2.mainOk, "starts again")
	T.eq(env2.files[NEW .. "/owner.key"], nil, "a file you deleted from Atsuko Hub after the copy doesn't come back")
end

T.section("save_folder: without the old folder")
do
	local env3 = Runner.boot({ seconds = 8, files = {} })
	T.ok(env3.mainOk, "a first start with nothing saved works")
	T.eq(env3.core and env3.core.movedNow, 0, "nothing to copy")
	T.ok(env3.files[NEW .. "/boot.json"] ~= nil, "the hub writes its own saves in Atsuko Hub")
	local stray = nil
	for path in pairs(env3.files) do
		if string.sub(path, 1, #OLD + 1) == OLD .. "/" then
			stray = path
		end
	end
	T.eq(stray, nil, "and nothing in the old folder")
end
