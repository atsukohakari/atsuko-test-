local Runner = loadmodule("Testing/mocks/boot_runner.lua")
local Pure = loadmodule("Hub/modules/sounds.lua")
local SETTINGS = "AtsukoHub/settings.json"

local function voices(env)
	local out = {}
	for _, o in ipairs(game:GetService("SoundService"):GetChildren()) do
		if o.Name == "AtsukoLoginVoice" then
			out[#out + 1] = o
		end
	end
	return out
end

T.section("sounds: the files that ship")
do
	local list = Pure.parse(jsondecode(readsource("Hub/sounds/sounds.json")))
	T.ok(list ~= nil, "Hub/sounds/sounds.json reads")
	T.eq(#list.login, 12, "twelve login lines")
	local names = {}
	for _, e in ipairs(list.login) do
		T.eq(Pure.sniff(readsource("Hub/sounds/" .. e.file)), "mp3", e.file .. " is a real mp3")
		T.ok(e.seconds >= 1 and e.seconds <= 10, e.file .. " says how long it is: " .. e.seconds)
		T.ok(string.sub(e.file, 1, 6) == "login/", e.file .. " sits in the login folder")
		names[#names + 1] = e.name
	end
	T.same(names, { "Atsuko", "Atsuko (Swimsuit)", "Chihiro", "Fuyu", "Hare (Camping)", "Haruka (Dress)", "Haruka (Dress) 2", "Hiyori", "Hoshino (Swimsuit)", "Kokoro", "Mika (Swimsuit)", "Yuuka (Pajama)" }, "every line is listed by its character, in order")
	T.eq(Pure.sniff(readsource("Hub/sounds/" .. list.click)), "mp3", "the click is a real mp3")
	T.eq(Pure.sniff(readsource("Hub/sounds/" .. list.notify)), "mp3", "the notification sound is a real mp3")
	T.same(list, Pure.parse(Pure.DEFAULT), "the built-in list matches the file, so the hub works even if the list can't load")
end

T.section("sounds: checking a list")
do
	T.eq(Pure.parse(nil), nil, "nothing")
	T.eq(Pure.parse("x"), nil, "text")
	for _, bad in ipairs({ "../x.mp3", "/x.mp3", "x.wav", "a<b.mp3", "a?b.ogg", "login\\x.mp3", "x.mp3.txt", string.rep("a", 130) .. ".mp3", "", 5 }) do
		T.eq(Pure.safeFile(bad), nil, "turned down: " .. tostring(bad))
	end
	T.eq(Pure.safeFile("login/new_one.ogg"), "login/new_one.ogg", "ogg works too")
	local p = Pure.parse({ login = { { file = "login/a.mp3", seconds = 99 }, { file = "../b.mp3" }, "login/c.mp3", { file = "login/d.mp3", seconds = -1, name = "" } }, click = "../no.mp3" })
	T.eq(#p.login, 3, "bad lines are left out")
	T.eq(p.login[1].seconds, Pure.MAX_SECONDS, "a very long line is capped")
	T.eq(p.login[2].seconds, 6, "a line with no length gets six seconds")
	T.eq(p.login[3].name, "login/d.mp3", "a line with no name is called by its file")
	T.eq(p.click, Pure.DEFAULT.click, "a bad click file keeps the shipped click")
	local many = { login = {} }
	for i = 1, 60 do
		many.login[i] = "login/x" .. i .. ".mp3"
	end
	T.eq(#Pure.parse(many).login, Pure.MAX_LINES, "at most " .. Pure.MAX_LINES .. " lines")
	T.eq(Pure.sniff("OggS" .. string.rep("x", 40)), "ogg", "ogg is known by its start")
	T.eq(Pure.sniff("<html>" .. string.rep("x", 40)), nil, "a web page is not a sound")
end

T.section("sounds: a random line, never the same twice in a row")
do
	local list = Pure.parse(Pure.DEFAULT).login
	local seen, last, repeats = {}, nil, 0
	for _ = 1, 400 do
		local e = Pure.pick(list, last)
		if e.file == last then
			repeats += 1
		end
		seen[e.file] = true
		last = e.file
	end
	T.eq(repeats, 0, "the same line never plays twice in a row")
	local n = 0
	for _ in pairs(seen) do
		n += 1
	end
	T.eq(n, 12, "every line comes up")
	T.eq(Pure.chosen(list, "login/hiyori.mp3").name, "Hiyori", "a chosen line is found by its file")
	T.eq(Pure.chosen(list, ""), nil, "nothing chosen means random")
	T.eq(Pure.chosen(list, "login/gone.mp3"), nil, "a line that was taken out is random again")
	local e = Pure.pick(list, list[3].file, function()
		return 3
	end)
	T.eq(e.file, list[4].file, "a pick that lands on the last line moves to the next one")
	T.eq(Pure.pick({}, nil), nil, "an empty list picks nothing")
	T.eq(Pure.pick({ list[1] }, list[1].file).file, list[1].file, "one line can repeat, there is nothing else")
end

T.section("sounds: a new login file names itself")
do
	local originals = {
		{ "Atsuko_LogIn_2.ogg.mp3", "Atsuko" },
		{ "Atsuko_Swimsuit_LogIn_2.ogg.mp3", "Atsuko (Swimsuit)" },
		{ "Chihiro_LogIn_1.ogg.mp3", "Chihiro" },
		{ "Fuyu_LogIn_1.ogg.mp3", "Fuyu" },
		{ "Hare_Camping_LogIn_1.ogg.mp3", "Hare (Camping)" },
		{ "Haruka_Dress_LogIn_1_1.ogg.mp3", "Haruka (Dress)" },
		{ "Haruka_Dress_LogIn_2_1.ogg.mp3", "Haruka (Dress)" },
		{ "Hiyori_LogIn_1.ogg.mp3", "Hiyori" },
		{ "Hoshino_Swimsuit_EventLogin_2.ogg.mp3", "Hoshino (Swimsuit)" },
		{ "Kokoro_LogIn_1.ogg.mp3", "Kokoro" },
		{ "Mika_Swimsuit_LogIn_1.ogg.mp3", "Mika (Swimsuit)" },
		{ "Yuuka_Pajama_LogIn_2_1.ogg.mp3", "Yuuka (Pajama)" },
	}
	for _, o in ipairs(originals) do
		T.eq(Pure.safeFile("login/" .. o[1]), "login/" .. o[1], "a file named like the ones from the game is allowed: " .. o[1])
		T.eq(Pure.nameOf("login/" .. o[1]), o[2], o[1])
	end
	for _, e in ipairs(Pure.parse(Pure.DEFAULT).login) do
		T.eq(Pure.nameOf(e.file), (string.gsub(e.name, " 2$", "")), "the files that ship name themselves the same way: " .. e.file)
	end
	T.eq(Pure.nameOf("login/Shiroko_(Riding)_LogIn_1.ogg"), "Shiroko (Riding)", "brackets in the name")
	T.eq(Pure.nameOf("login/Hoshino_Battle_Tank_LogIn.mp3"), "Hoshino (Battle Tank)", "a long outfit name")
	T.eq(Pure.nameOf("login/Hina_Dress_Event_LogIn_1.mp3"), "Hina (Dress)", "the word event is left out")
	T.eq(Pure.nameOf("login/hina dress.mp3"), "Hina (Dress)", "spaces work like _")
	T.eq(Pure.nameOf("login/shiroko.OGG"), "Shiroko", "any case of the ending")
	T.eq(Pure.nameOf("login/LogIn_1.mp3"), "LogIn_1", "a file with no name keeps its own")
	T.eq(Pure.safeFile("login/Shiroko (Riding)_LogIn.ogg"), "login/Shiroko (Riding)_LogIn.ogg", "spaces and brackets are allowed")
end

T.section("sounds: found files join the list")
do
	local base = Pure.parse(Pure.DEFAULT)
	T.same(Pure.merge(Pure.parse(Pure.DEFAULT), nil), base, "nothing found keeps the list")
	T.same(Pure.merge(Pure.parse(Pure.DEFAULT), {}), base, "an empty folder keeps the list too")
	local files = {}
	for _, e in ipairs(base.login) do
		files[#files + 1] = e.file
	end
	T.same(Pure.merge(Pure.parse(Pure.DEFAULT), files), base, "the shipped files alone change nothing")
	files[#files + 1] = "login/Shiroko_LogIn_1.ogg.mp3"
	files[#files + 1] = "login/Atsuko_LogIn_2.ogg.mp3"
	files[#files + 1] = "login/../x.mp3"
	local got = Pure.merge(Pure.parse(Pure.DEFAULT), files).login
	T.eq(#got, 14, "two new lines, the bad one left out")
	local names = {}
	for _, e in ipairs(got) do
		names[#names + 1] = e.name
	end
	T.eq(names[1], "Atsuko", "still in order")
	T.eq(names[2], "Atsuko 2", "a second Atsuko gets a number, right after the first")
	T.eq(names[3], "Atsuko (Swimsuit)")
	T.eq(names[#names], "Yuuka (Pajama)")
	local shiroko = Pure.chosen(got, "login/Shiroko_LogIn_1.ogg.mp3")
	T.ok(shiroko ~= nil, "the new one can be picked")
	T.eq(shiroko and shiroko.name, "Shiroko")
	T.eq(shiroko and shiroko.guess, true, "its length is read from the sound itself")
	T.eq(Pure.chosen(got, "login/atsuko.mp3").guess, nil, "a listed line keeps the length it was given")
	local gone = Pure.merge(Pure.parse(Pure.DEFAULT), { "login/hiyori.mp3", "login/Shiroko_LogIn_1.ogg.mp3" }).login
	T.eq(#gone, 2, "a listed line whose file was taken out is left out")
	T.eq(gone[1].name, "Hiyori")
	T.eq(gone[1].seconds, 7.8, "with its own length")
	local lots = {}
	for i = 1, 90 do
		lots[i] = "login/Voice" .. i .. "_LogIn.mp3"
	end
	T.eq(#Pure.merge(Pure.parse(Pure.DEFAULT), lots).login, Pure.MAX_LINES, "still at most " .. Pure.MAX_LINES .. " lines")
end

local function boot(extra)
	extra = extra or {}
	return Runner.boot({
		seconds = 8,
		viewW = extra.viewW,
		viewH = extra.viewH,
		touch = extra.touch,
		files = { [SETTINGS] = extra.settings or "{\"lastVersion\":\"1.6.1\"}" },
		before = extra.before,
	})
end

local env = boot()
local hub, core = env.hub, env.core
local S = hub.S

T.section("sounds: the login voice waits until the hub has loaded")
local mod, st
do
	env.run(4)
	local slot = core.mods.sounds
	mod = slot and slot.mod
	T.ok(mod ~= nil, "the sounds module loaded")
	T.eq(mod and mod.loadedWhenReady, true, "only after the hub was ready, not while it was loading")
	T.eq(mod and mod.settled, true, "and after the frames settled")
	st = env.genv.__AtsukoLoginVoice
	T.ok(st ~= nil, "a login voice was started")
	T.eq(st and st.count, 1, "once")
	T.eq(st and st.hubReady, true, "with the hub ready")
	local v = voices(env)
	T.eq(#v, 1, "one voice is playing")
	T.ok(v[1] and string.find(v[1].SoundId, "Hub/sounds/login/", 1, true) ~= nil, "from Hub/sounds/login: " .. tostring(v[1] and v[1].SoundId))
	T.eq(v[1] and v[1].Playing, true, "and it plays")
	T.near(v[1] and v[1].Volume or 0, 0.7, 1e-6, "at the sound volume, a little louder for a voice")
	T.eq(S.loginLast, st and st.last, "the line is remembered so the next start picks another")
	T.eq(#env.errors, 0, "no errors: " .. table.concat(env.errors, " | "))
end

T.section("sounds: no overlapping and no spam")
do
	env.run(12)
	T.eq(#voices(env), 0, "the first voice cleans itself up when it's done")
	local first = st.last
	local ok1 = mod.playLogin()
	T.eq(ok1, true, "after it ends a new one can play")
	T.ok(st.last ~= first, "and it's a different line")
	local ok, why = mod.playLogin()
	T.eq(ok, false, "a second voice can't start over the first")
	T.eq(why, "playing", "because one is playing")
	T.eq(#voices(env), 1, "still one voice")
	T.eq(voices(env)[1].Playing, true, "and the first one keeps going")
	st.untilAt = 0
	local ok3, why3 = mod.playLogin()
	T.eq(ok3, false, "even when it has ended, not right after another one started")
	T.eq(why3, "cooldown", "there's a short wait between voices")
	env.run(12)
end

T.section("sounds: always on, and you can pick the voice")
do
	T.eq(S.loginSound, nil, "there is no switch to turn the voice off")
	T.eq(S.uiSounds, nil, "or the click")
	T.eq(S.toastSound, nil, "or the notification sound")
	local vol = S.sfxVolume
	S.sfxVolume = 0
	local ok2, why2 = mod.playLogin()
	T.eq(ok2, false, "nothing plays at zero volume")
	T.eq(why2, "muted")
	S.sfxVolume = vol
	hub.Panel.show("settings")
	env.run(1)
	hub.Panel.setTab(hub.Pages.settings, 1)
	env.run(2)
	local box
	for _, d in ipairs(hub.Root:GetDescendants()) do
		if d.Name == "LoginVoice" then
			box = d
		end
	end
	T.ok(box ~= nil, "Settings > General has a Login voice card")
	local grid = box and box:FindFirstChild("Voices")
	local names = {}
	for _, c in ipairs(grid and grid:GetChildren() or {}) do
		if c:IsA("TextButton") then
			names[#names + 1] = c.Text
		end
	end
	T.eq(#names, 13, "Random and the twelve characters: " .. table.concat(names, ", "))
	T.ok(table.find(names, "Hiyori") ~= nil and table.find(names, "Hare (Camping)") ~= nil, "listed by character name")
	for _, d in ipairs(hub.Root:GetDescendants()) do
		T.ok(not (d:IsA("TextLabel") and (d.Text == "Click sounds" or d.Text == "Notification sound")), "no click or notification switch: " .. tostring(d.Text))
	end
	local pickHiyori = grid and grid:FindFirstChild("Hiyori")
	local before = st.count
	pickHiyori.Activated:Fire()
	env.run(3)
	T.eq(S.loginPick, "login/hiyori.mp3", "tapping a character keeps that voice")
	T.eq(st.count, before + 1, "and plays it so you can hear it")
	T.eq(st.last, "login/hiyori.mp3")
	T.ok(string.find(env.files[SETTINGS] or "", "hiyori", 1, true) ~= nil, "it's saved for next time")
	env.run(12)
	st.untilAt, st.started = 0, 0
	mod.playLogin()
	T.eq(st.last, "login/hiyori.mp3", "the next login is Hiyori again")
	env.run(12)
	st.untilAt, st.started = 0, 0
	mod.playLogin()
	T.eq(st.last, "login/hiyori.mp3", "every time")
	env.run(12)
	grid:FindFirstChild("Random").Activated:Fire()
	env.run(3)
	T.eq(S.loginPick, "", "Random goes back to a different one each time")
	env.run(12)
end

T.section("sounds: the click and the notification")
do
	local sfx = core.Sfx
	T.ok(sfx.custom.click and string.find(sfx.custom.click, "Hub/sounds/click.mp3", 1, true) ~= nil, "the click is the Blue Archive click, loaded at start: " .. tostring(sfx.custom.click))
	T.ok(sfx.custom.ping and string.find(sfx.custom.ping, "Hub/sounds/notify.mp3", 1, true) ~= nil, "the notification is the Blue Archive sound: " .. tostring(sfx.custom.ping))
	sfx.play("click")
	core.ctx.notify("Test", "a notification", "info")
	env.run(0.5)
	T.eq(sfx.cache.click.SoundId, sfx.custom.click, "taps play it")
	T.eq(sfx.cache.ping.SoundId, sfx.custom.ping, "notifications play it")
	T.eq(sfx.cache.click.Playing, true)
	T.eq(sfx.STOCK, nil, "no Roblox stock click or ping is left")
	local keep = sfx.custom.click
	sfx.custom.click = nil
	sfx.cache.click.SoundId = ""
	sfx.play("click")
	T.eq(sfx.cache.click.SoundId, "", "if the file can't load, nothing else plays instead")
	sfx.custom.click = keep
	env.run(12)
	mod.playLogin({ preview = true })
	T.eq(#voices(env), 1, "a voice is talking")
	local pings = sfx.cache.ping
	pings.SoundId = ""
	sfx.play("ping")
	T.eq(pings.SoundId, "", "no notification sound talks over the login voice")
	env.run(12)
	sfx.play("ping")
	T.eq(pings.SoundId, sfx.custom.ping, "once it's done they ping again")
end

T.section("sounds: -reload")
do
	local LP = game:GetService("Players").LocalPlayer
	local before = st.count
	LP.Chatted:Fire("-reload")
	local waited = 0
	while st.count == before and waited < 25 do
		env.run(0.25)
		waited += 0.25
	end
	T.eq(env.genv.__AtsukoLoginVoice, st, "the voice state lives across the reload")
	T.eq(st.count, before + 1, "saying -reload brings the hub back with a login voice")
	T.ok(waited >= 1.5, "once the new hub has loaded and settled, not straight away: " .. waited .. "s")
	T.eq(st.hubReady, true, "the new hub was ready")
	T.eq(#voices(env), 1, "one voice")
	local playing = voices(env)[1]
	local ends = st.untilAt
	LP.Chatted:Fire("-reload")
	local most, cut = 0, false
	for _ = 1, 60 do
		env.run(0.25)
		most = math.max(most, #voices(env))
		if os.clock() < ends - 0.2 and playing.Parent == nil then
			cut = true
		end
	end
	T.eq(most, 1, "two voices never play at the same time, even when reloading while it talks")
	T.eq(cut, false, "the voice that was playing is never cut off by a reload")
	T.ok(st.count <= before + 2, "and reloading doesn't stack up voices")
	T.eq(#env.errors, 0, "no errors")
	env.run(12)
end

T.section("sounds: safe mode stays quiet")
do
	local e2 = boot({ before = function(e)
		e.genv.AtsukoSafeMode = true
	end })
	e2.run(6)
	T.eq(e2.genv.__AtsukoLoginVoice, nil, "no login voice in safe mode")
	T.eq(#e2.errors, 0, "no errors")
end

T.section("sounds: a file dropped in the login folder shows up")
do
	local e3 = boot()
	local h3, c3 = e3.hub, e3.core
	e3.run(14)
	local m3 = c3.mods.sounds and c3.mods.sounds.mod
	T.ok(m3 ~= nil, "the sounds module is up")
	T.ok(type(h3.Repo.loginFiles) == "table" and #h3.Repo.loginFiles == 12, "the hub read the login folder: " .. tostring(h3.Repo.loginFiles and #h3.Repo.loginFiles))
	e3.files["Atsuko Hub/Hub/sounds/login/Shiroko_LogIn_1.ogg.mp3"] = readsource("Hub/sounds/login/fuyu.mp3")
	h3.Panel.show("settings")
	e3.run(1)
	h3.Panel.setTab(h3.Pages.settings, 1)
	e3.run(2)
	h3.Repo.refresh(true)
	e3.run(3)
	T.eq(#h3.Repo.loginFiles, 13, "a new file is found when the list is loaded again")
	local found = m3.chosen(m3.list().login, "login/Shiroko_LogIn_1.ogg.mp3")
	T.eq(found and found.name, "Shiroko", "named from its file")
	local grid
	for _, d in ipairs(h3.Root:GetDescendants()) do
		if d.Name == "Voices" then
			grid = d
		end
	end
	local chip = grid and grid:FindFirstChild("Shiroko")
	T.ok(chip ~= nil, "the login voice card lists it without opening settings again")
	local n = 0
	for _, c in ipairs(grid and grid:GetChildren() or {}) do
		if c:IsA("TextButton") then
			n += 1
		end
	end
	T.eq(n, 14, "Random and thirteen characters, nothing twice")
	local st3 = e3.genv.__AtsukoLoginVoice
	st3.untilAt, st3.started = 0, 0
	chip.Activated:Fire()
	e3.run(4)
	T.eq(e3.hub.S.loginPick, "login/Shiroko_LogIn_1.ogg.mp3", "it can be picked")
	T.eq(st3.last, "login/Shiroko_LogIn_1.ogg.mp3", "and it plays")
	local list = jsondecode(e3.files["AtsukoHub/cache/list.json"] or "{}")
	T.ok(type(list.login) == "table" and table.find(list.login, "login/Shiroko_LogIn_1.ogg.mp3") ~= nil, "the files are saved with the script list for next time")
	T.eq(#e3.errors, 0, "no errors: " .. table.concat(e3.errors, " | "))
	e3.run(12)

	local origin = c3.ctx.Origin
	local root = origin.root
	origin.root = nil
	e3.http = function(url)
		if string.find(url, "api.github.com", 1, true) then
			return game:GetService("HttpService"):JSONEncode({ tree = {
				{ type = "blob", path = "Scripts/Hat/AK47.lua", size = 10 },
				{ type = "blob", path = "Hub/sounds/login/atsuko.mp3", size = 10 },
				{ type = "blob", path = "Hub/sounds/login/Mika_Swimsuit_LogIn_1.ogg.mp3", size = 10 },
				{ type = "blob", path = "Hub/sounds/login/Koharu (Swimsuit)_LogIn.ogg", size = 10 },
				{ type = "blob", path = "Hub/sounds/login/notes.txt", size = 10 },
				{ type = "blob", path = "Hub/sounds/login/old/x.mp3", size = 10 },
				{ type = "tree", path = "Hub/sounds/login", size = 0 },
			} })
		end
		local rel = string.match(url, "githubusercontent%.com/[^/]+/[^/]+/[^/]+/([^?]+)")
		if rel and string.find(rel, "Koharu", 1, true) then
			e3.asked = rel
			return readsource("Hub/sounds/login/kokoro.mp3")
		end
		return nil
	end
	local ok = h3.Repo.fetchList()
	T.eq(ok, true, "the list loads from github")
	T.same(h3.Repo.loginFiles, { "login/Koharu (Swimsuit)_LogIn.ogg", "login/Mika_Swimsuit_LogIn_1.ogg.mp3", "login/atsuko.mp3" }, "only sound files right inside the login folder count")
	local names = {}
	for _, e in ipairs(m3.list().login) do
		names[#names + 1] = e.name
	end
	T.same(names, { "Atsuko", "Koharu (Swimsuit)", "Mika (Swimsuit)" }, "github's files make the list")
	st3.untilAt, st3.started = 0, 0
	local played = m3.playLogin({ file = "login/Koharu (Swimsuit)_LogIn.ogg" })
	T.eq(played, true, "a file with a space in its name plays")
	T.eq(e3.asked, "Hub/sounds/login/Koharu%20%28Swimsuit%29_LogIn.ogg", "it was downloaded with its name made safe for a link")
	origin.root = root
	e3.http = nil
	T.eq(#e3.errors, 0, "no errors: " .. table.concat(e3.errors, " | "))
end
