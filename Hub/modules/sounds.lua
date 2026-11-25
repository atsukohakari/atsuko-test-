local Mod = {}

Mod.DIR = "Hub/sounds/"
Mod.LIST = "Hub/sounds/sounds.json"
Mod.DEFAULT = {
	login = {
		{ file = "login/atsuko.mp3", name = "Atsuko", seconds = 1.9 },
		{ file = "login/atsuko_swimsuit.mp3", name = "Atsuko (Swimsuit)", seconds = 3.6 },
		{ file = "login/chihiro.mp3", name = "Chihiro", seconds = 4.3 },
		{ file = "login/fuyu.mp3", name = "Fuyu", seconds = 2.6 },
		{ file = "login/hare_camping.mp3", name = "Hare (Camping)", seconds = 9.1 },
		{ file = "login/haruka_dress.mp3", name = "Haruka (Dress)", seconds = 3.4 },
		{ file = "login/haruka_dress_2.mp3", name = "Haruka (Dress) 2", seconds = 3.4 },
		{ file = "login/hiyori.mp3", name = "Hiyori", seconds = 7.8 },
		{ file = "login/hoshino_swimsuit.mp3", name = "Hoshino (Swimsuit)", seconds = 7.1 },
		{ file = "login/kokoro.mp3", name = "Kokoro", seconds = 6.4 },
		{ file = "login/mika_swimsuit.mp3", name = "Mika (Swimsuit)", seconds = 8.5 },
		{ file = "login/yuuka_pajama.mp3", name = "Yuuka (Pajama)", seconds = 1.6 },
	},
	click = "click.mp3",
	notify = "notify.mp3",
}
Mod.GAIN = { click = 1, ping = 0.9, login = 1.4 }
Mod.COOLDOWN = 4
Mod.MAX_SECONDS = 20
Mod.MAX_LINES = 60
Mod.GUESS_SECONDS = 6
Mod.SETTLE = { after = 1, frames = 4, frameTime = 1 / 30, max = 4, readyWait = 40 }
Mod.ids = {}
Mod.log = {}

local ctx
local fallback = {}

function Mod.init(c)
	ctx = c
	Mod.ids = {}
	Mod.cache = nil
	Mod.loadedWhenReady = c.HUB ~= nil and c.HUB.ready == true
	if ctx.Core then
		ctx.Core.Sounds = Mod
	end
end

local function note(text)
	Mod.log[#Mod.log + 1] = text
	if #Mod.log > 30 then
		table.remove(Mod.log, 1)
	end
end

function Mod.sniff(data)
	if type(data) ~= "string" or #data < 16 then
		return nil
	end
	if string.sub(data, 1, 3) == "ID3" then
		return "mp3"
	end
	if string.sub(data, 1, 4) == "OggS" then
		return "ogg"
	end
	local a, b = string.byte(data, 1, 2)
	if a == 255 and b and b >= 224 then
		return "mp3"
	end
	return nil
end

local function safeFile(f)
	if type(f) ~= "string" or #f == 0 or #f > 120 then
		return nil
	end
	if string.find(f, "..", 1, true) or string.sub(f, 1, 1) == "/" or string.find(f, "[\\%c]") then
		return nil
	end
	local low = string.lower(f)
	if not (string.match(low, "%.mp3$") or string.match(low, "%.ogg$")) then
		return nil
	end
	if string.match(f, "^[%w_%-/%.%(%) ]+$") then
		return f
	end
	return nil
end
Mod.safeFile = safeFile

local function cap(w)
	return string.upper(string.sub(w, 1, 1)) .. string.sub(w, 2)
end

function Mod.nameOf(file)
	local base = string.match(tostring(file or ""), "([^/]+)$") or ""
	for _ = 1, 3 do
		local low = string.lower(base)
		if string.match(low, "%.mp3$") or string.match(low, "%.ogg$") or string.match(low, "%.wav$") then
			base = string.sub(base, 1, #base - 4)
		else
			break
		end
	end
	local words = {}
	for w in string.gmatch((string.gsub(base, "[%(%)]", " ")), "[^_%s]+") do
		words[#words + 1] = w
	end
	local stop = nil
	for i, w in ipairs(words) do
		if string.find(string.lower(w), "login", 1, true) then
			stop = i
			break
		end
	end
	local keep = {}
	for i = 1, stop and stop - 1 or #words do
		keep[#keep + 1] = words[i]
	end
	while #keep > 1 and (tonumber(keep[#keep]) or string.lower(keep[#keep]) == "event") do
		table.remove(keep)
	end
	if #keep == 0 then
		return base ~= "" and string.sub(base, 1, 40) or "Voice"
	end
	local name = cap(keep[1])
	if #keep > 1 then
		local rest = {}
		for i = 2, #keep do
			rest[#rest + 1] = cap(keep[i])
		end
		name = name .. " (" .. table.concat(rest, " ") .. ")"
	end
	return string.sub(name, 1, 40)
end

function Mod.merge(got, files)
	if type(got) ~= "table" or type(files) ~= "table" or #files == 0 then
		return got
	end
	local have = {}
	for _, f in ipairs(files) do
		local safe = safeFile(f)
		if safe then
			have[safe] = true
		end
	end
	if next(have) == nil then
		return got
	end
	local out, taken = {}, {}
	for _, e in ipairs(got.login) do
		if have[e.file] then
			out[#out + 1] = e
			taken[e.name] = true
			have[e.file] = false
		end
	end
	local extra = {}
	for f, fresh in pairs(have) do
		if fresh then
			extra[#extra + 1] = f
		end
	end
	table.sort(extra, function(a, b)
		local x, y = string.lower(a), string.lower(b)
		if x ~= y then
			return x < y
		end
		return a < b
	end)
	for _, f in ipairs(extra) do
		if #out >= Mod.MAX_LINES then
			break
		end
		local base = Mod.nameOf(f)
		local name, n = base, 1
		while taken[name] do
			n += 1
			name = base .. " " .. n
		end
		taken[name] = true
		out[#out + 1] = { file = f, name = name, seconds = Mod.GUESS_SECONDS, guess = true }
	end
	local function key(e)
		local base, n = string.match(e.name, "^(.-) (%d+)$")
		return string.lower(base or e.name), tonumber(n) or 1
	end
	table.sort(out, function(a, b)
		local x, nx = key(a)
		local y, ny = key(b)
		if x ~= y then
			return x < y
		end
		if nx ~= ny then
			return nx < ny
		end
		return a.file < b.file
	end)
	got.login = out
	return got
end

function Mod.parse(raw)
	if type(raw) ~= "table" then
		return nil
	end
	local out = { login = {}, click = safeFile(raw.click) or Mod.DEFAULT.click, notify = safeFile(raw.notify) or Mod.DEFAULT.notify }
	if type(raw.login) == "table" then
		for _, e in ipairs(raw.login) do
			if #out.login >= Mod.MAX_LINES then
				break
			end
			local f = type(e) == "table" and safeFile(e.file) or safeFile(e)
			if f then
				local secs = type(e) == "table" and tonumber(e.seconds) or nil
				if not secs or secs ~= secs or secs <= 0 then
					secs = 6
				end
				local name = type(e) == "table" and type(e.name) == "string" and e.name ~= "" and string.sub(e.name, 1, 40) or f
				out.login[#out.login + 1] = { file = f, name = name, seconds = math.min(secs, Mod.MAX_SECONDS) }
			end
		end
	end
	return out
end

function Mod.list()
	if Mod.cache then
		return Mod.cache
	end
	local got
	local Core = ctx and ctx.Core
	if Core and Core.fileSource then
		local ok, src = pcall(Core.fileSource, Mod.LIST)
		if ok and type(src) == "string" and ctx.jsonDecode then
			got = Mod.parse(ctx.jsonDecode(src))
		end
	end
	if not got then
		got = Mod.parse(Mod.DEFAULT)
		note("using the built-in list of sounds")
	end
	if ctx and type(ctx.loginFiles) == "function" then
		local ok, files = pcall(ctx.loginFiles)
		if ok and type(files) == "table" then
			got = Mod.merge(got, files)
		end
	end
	Mod.cache = got
	return got
end

function Mod.found()
	Mod.cache = nil
	local Bus = ctx and ctx.Bus
	if Bus and Bus.fire then
		pcall(Bus.fire, "sounds")
	end
end

function Mod.chosen(list, file)
	if type(file) ~= "string" or file == "" then
		return nil
	end
	for i, e in ipairs(list) do
		if e.file == file then
			return e, i
		end
	end
	return nil
end

function Mod.pick(list, last, rand)
	local n = #list
	if n == 0 then
		return nil
	end
	rand = rand or math.random
	local i = math.clamp(math.floor(tonumber(rand(1, n)) or 1), 1, n)
	if n > 1 and list[i].file == last then
		i = i % n + 1
	end
	return list[i], i
end

function Mod.asset(file)
	if Mod.ids[file] then
		return Mod.ids[file]
	end
	local X, FS = ctx.X, ctx.FS
	if not (ctx.HAS_FS and X and X.getcustomasset) then
		return nil, "this executor can't play sound files"
	end
	local rel = Mod.DIR .. file
	local path
	local origin = ctx.Origin
	if origin and origin.root then
		path = origin.root .. "/" .. rel
		if not Mod.sniff(FS.read(path)) then
			return nil, "couldn't find " .. rel
		end
	else
		local ok, data, err = pcall(ctx.Core.fileSource, rel)
		if not ok or not Mod.sniff(data) then
			return nil, tostring(err or ("couldn't download " .. rel))
		end
		path = (ctx.Core.LOCAL_DIR or "AtsukoHub") .. "/sounds/" .. string.gsub(file, "[^%w_%.%-]", "_")
		if FS.read(path) ~= data and not FS.write(path, data) then
			return nil, "couldn't save " .. file
		end
	end
	local ok, id = pcall(X.getcustomasset, path)
	if ok and type(id) == "string" and id ~= "" then
		Mod.ids[file] = id
		return id
	end
	return nil, "this executor couldn't open " .. file
end

function Mod.state()
	local G = ctx and ctx.GENV
	local st = G and G.__AtsukoLoginVoice or fallback.state
	if type(st) ~= "table" then
		st = { started = 0, untilAt = 0, count = 0, skipped = 0 }
		if G then
			G.__AtsukoLoginVoice = st
		else
			fallback.state = st
		end
	end
	return st
end

function Mod.busy()
	local st = Mod.state()
	if os.clock() >= (st.untilAt or 0) then
		return false
	end
	if st.loading then
		return true
	end
	local s = st.sound
	return s ~= nil and s.Parent ~= nil
end

function Mod.settle()
	local HUB, RS = ctx.HUB, ctx.RunService
	local t0 = os.clock()
	while HUB.alive and not HUB.ready and os.clock() - t0 < Mod.SETTLE.readyWait do
		task.wait(0.25)
	end
	if not (HUB.alive and HUB.ready) then
		return false
	end
	task.wait(Mod.SETTLE.after)
	local good, t1 = 0, os.clock()
	while HUB.alive and good < Mod.SETTLE.frames and os.clock() - t1 < Mod.SETTLE.max do
		local dt
		if RS and RS.Heartbeat then
			dt = RS.Heartbeat:Wait()
		else
			dt = task.wait()
		end
		if type(dt) == "number" and dt <= Mod.SETTLE.frameTime then
			good += 1
		else
			good = 0
		end
	end
	return HUB.alive == true
end

local function waitLoaded(s, limit)
	local ok, loaded = pcall(function()
		return s.IsLoaded
	end)
	if ok and loaded then
		return
	end
	local done = false
	local conn
	pcall(function()
		conn = s.Loaded:Connect(function()
			done = true
		end)
	end)
	local t0 = os.clock()
	while not done and s.Parent and os.clock() - t0 < limit do
		task.wait(0.05)
	end
	if conn then
		conn:Disconnect()
	end
end

function Mod.playLogin(opts)
	opts = opts or {}
	local S = ctx.S
	local st = Mod.state()
	local function skip(why)
		st.skipped = (st.skipped or 0) + 1
		st.lastSkip = why
		note("login voice skipped: " .. why)
		return false, why
	end
	if (tonumber(S.sfxVolume) or 0) <= 0 then
		return skip("muted")
	end
	if Mod.busy() and not opts.preview then
		return skip("playing")
	end
	local now = os.clock()
	if not opts.preview and (st.started or 0) > 0 and now - st.started < Mod.COOLDOWN then
		return skip("cooldown")
	end
	local list = Mod.list().login
	local entry = Mod.chosen(list, opts.file) or Mod.chosen(list, S.loginPick) or Mod.pick(list, st.last or S.loginLast)
	if not entry then
		return skip("none")
	end
	local old = st.sound
	if old and old.Parent then
		pcall(function()
			old:Destroy()
		end)
	end
	st.started = now
	st.untilAt = now + entry.seconds + 10
	st.loading = true
	local id, err = Mod.asset(entry.file)
	if not id then
		st.loading = false
		st.untilAt = 0
		return skip(tostring(err))
	end
	local s = Instance.new("Sound")
	s.Name = "AtsukoLoginVoice"
	s.SoundId = id
	s.Volume = math.clamp((tonumber(S.sfxVolume) or 0.5) * Mod.GAIN.login, 0, 3)
	s.Parent = ctx.Core.SoundService
	if ctx.Core.OWN_SOUNDS then
		ctx.Core.OWN_SOUNDS[s] = true
	end
	st.sound = s
	st.untilAt = now + entry.seconds + 6
	waitLoaded(s, 3)
	st.loading = false
	if not s.Parent then
		st.untilAt = 0
		return skip("gone")
	end
	local t = os.clock()
	local length = entry.seconds
	pcall(function()
		local real = tonumber(s.TimeLength)
		if real and real > 0 and real < Mod.MAX_SECONDS then
			length = entry.guess and real or math.max(length, real)
		end
	end)
	st.started = t
	st.untilAt = t + length + 0.3
	st.count = (st.count or 0) + 1
	st.last = entry.file
	st.name = entry.name
	st.hubReady = ctx.HUB.ready == true
	S.loginLast = entry.file
	pcall(ctx.saveSettings)
	pcall(function()
		s:Play()
	end)
	note("login voice: " .. entry.name)
	pcall(function()
		s.Ended:Connect(function()
			if st.sound == s then
				st.untilAt = 0
			end
			task.delay(0.1, function()
				pcall(function()
					s:Destroy()
				end)
			end)
		end)
	end)
	task.delay(length + 2, function()
		if s.Parent then
			pcall(function()
				s:Destroy()
			end)
		end
	end)
	return true, entry
end

function Mod.preloadEffects()
	local sfx = ctx.Core.Sfx
	if not sfx then
		return false
	end
	local list = Mod.list()
	local all = true
	for kind, file in pairs({ click = list.click, ping = list.notify }) do
		if not sfx.custom[kind] then
			local id, err = Mod.asset(file)
			if id then
				sfx.custom[kind] = id
				sfx.gain[kind] = Mod.GAIN[kind]
			else
				all = false
				note(kind .. " sound: " .. tostring(err))
			end
		end
	end
	return all
end

function Mod.start()
	if Mod.started then
		return false
	end
	Mod.started = true
	task.spawn(function()
		pcall(Mod.preloadEffects)
	end)
	task.spawn(function()
		if not Mod.settle() then
			return
		end
		Mod.settled = true
		pcall(Mod.playLogin)
	end)
	return true
end

function Mod.destroy()
	Mod.started = false
end

return Mod
