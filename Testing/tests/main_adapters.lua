local function jsonEncode(v)
	local t = type(v)
	if t == "number" then
		return tostring(v)
	elseif t == "boolean" then
		return tostring(v)
	elseif t == "string" then
		return '"' .. v .. '"'
	elseif t == "table" then
		if #v > 0 or next(v) == nil then
			local parts = {}
			for i = 1, #v do
				parts[#parts + 1] = jsonEncode(v[i])
			end
			return "[" .. table.concat(parts, ",") .. "]"
		end
		local keys = {}
		for k in pairs(v) do
			keys[#keys + 1] = k
		end
		table.sort(keys)
		local parts = {}
		for _, k in ipairs(keys) do
			parts[#parts + 1] = '"' .. k .. '":' .. jsonEncode(v[k])
		end
		return "{" .. table.concat(parts, ",") .. "}"
	end
	return "null"
end

local function jsonDecode(s)
	local pos = 1
	local function ws()
		pos = string.find(s, "[^ \n\r\t]", pos) or (#s + 1)
	end
	local value
	local function str()
		local close = string.find(s, '"', pos + 1, true)
		local out = string.sub(s, pos + 1, close - 1)
		pos = close + 1
		return out
	end
	function value()
		ws()
		local c = string.sub(s, pos, pos)
		if c == "{" then
			pos = pos + 1
			local out = {}
			ws()
			if string.sub(s, pos, pos) == "}" then
				pos = pos + 1
				return out
			end
			while true do
				ws()
				local k = str()
				ws()
				pos = pos + 1
				out[k] = value()
				ws()
				local d = string.sub(s, pos, pos)
				pos = pos + 1
				if d == "}" then
					return out
				end
			end
		elseif c == "[" then
			pos = pos + 1
			local out = {}
			ws()
			if string.sub(s, pos, pos) == "]" then
				pos = pos + 1
				return out
			end
			while true do
				out[#out + 1] = value()
				ws()
				local d = string.sub(s, pos, pos)
				pos = pos + 1
				if d == "]" then
					return out
				end
			end
		elseif c == '"' then
			return str()
		elseif string.sub(s, pos, pos + 3) == "true" then
			pos = pos + 4
			return true
		elseif string.sub(s, pos, pos + 4) == "false" then
			pos = pos + 5
			return false
		elseif string.sub(s, pos, pos + 3) == "null" then
			pos = pos + 4
			return nil
		end
		local num = string.match(s, "^-?[%d%.eE%+%-]+", pos)
		if not num then
			error("bad json at " .. pos)
		end
		pos = pos + #num
		return tonumber(num)
	end
	local out = value()
	ws()
	if pos <= #s then
		error("trailing json")
	end
	return out
end

local ENUM = setmetatable({}, {
	__index = function(_, group)
		return setmetatable({}, {
			__index = function(_, item)
				return group .. "." .. item
			end,
		})
	end,
})

local CF = setmetatable({}, {
	__mul = function(a)
		return a
	end,
})

local function world(extra)
	local W = { files = {}, delays = {}, stops = {}, notes = {}, genv = {}, writes = 0 }
	W.HttpService = {
		JSONEncode = function(_, v)
			return jsonEncode(v)
		end,
		JSONDecode = function(_, s)
			return jsonDecode(s)
		end,
	}
	W.isfile = function(name)
		return W.files[name] ~= nil
	end
	W.readfile = function(name)
		return W.files[name]
	end
	W.writefile = function(name, text)
		W.files[name] = text
		W.writes = W.writes + 1
	end
	W.now = 0
	W.task = {
		delay = function(t, fn, ...)
			W.delays[#W.delays + 1] = { at = W.now + t, fn = fn, args = { ... } }
		end,
		spawn = function(fn, ...)
			fn(...)
		end,
		defer = function(fn, ...)
			fn(...)
		end,
		wait = function() end,
	}
	W.advance = function(dt)
		W.now = W.now + dt
		table.sort(W.delays, function(a, b)
			return a.at < b.at
		end)
		local due, later = {}, {}
		for _, d in ipairs(W.delays) do
			if d.at <= W.now + 1e-9 then
				due[#due + 1] = d
			else
				later[#later + 1] = d
			end
		end
		W.delays = later
		for _, d in ipairs(due) do
			d.fn(table.unpack(d.args))
		end
	end
	W.runDelays = function()
		local list = W.delays
		W.delays = {}
		for _, d in ipairs(list) do
			d.fn(table.unpack(d.args))
		end
	end
	W.C = {
		alive = true,
		notify = function(title, text, dur)
			W.notes[#W.notes + 1] = title .. ": " .. text
		end,
		onStop = function(fn)
			W.stops[#W.stops + 1] = fn
		end,
		newPart = function(props)
			return props
		end,
		foundText = function()
			return "found something"
		end,
		hatOn = function()
			return true
		end,
		toggleHat = function() end,
	}
	W.CFG = { alignFile = "Test.json", alignKey = "j" }
	W.getgenv = function()
		return W.genv
	end
	W.hubCalls = { align = 0, ready = 0 }
	W.hub = {
		Align = function()
			W.hubCalls.align = W.hubCalls.align + 1
		end,
		AlignReady = function()
			W.hubCalls.ready = W.hubCalls.ready + 1
		end,
	}
	for k, v in pairs(extra or {}) do
		W[k] = v
	end
	return W
end

local FAMILY = {
	{ file = "Scripts/Hat/DubstepGunOriginal.lua", title = "Dubstep Gun", tabs = 6, roll = true },
	{ file = "Scripts/Hat/NeptunianVGun.lua", title = "Neptunian V", tabs = 4, roll = true, hats = true },
	{ file = "Scripts/Hat/TheHotline.lua", title = "The Hotline", tabs = 2 },
	{ file = "Scripts/_unlisted/TheSniper.lua", title = "The Sniper", tabs = 3, roll = true },
	{ file = "Scripts/Hat/Addict.lua", title = "Addict", tabs = 6, roll = true, gunHat = true },
	{ file = "Scripts/Hat/CommanderV2.lua", title = "Commander V2", tabs = 2, roll = true, gunHat = true },
}

local PRELUDE = table.concat({
	"local C, CFG, HttpService, isfile, readfile, writefile, getgenv, task, Enum, CFn, ANG, rad, V3, C3, typeof = ...",
	"local pcall, type, tonumber, tostring, ipairs, pairs, table, math, string, os = pcall, type, tonumber, tostring, ipairs, pairs, table, math, string, os",
	"local osclock = os.clock",
	"local unpackFn = table.unpack",
}, "\n") .. "\n"

local function slices(path)
	local src = readsource(path)
	local s1 = string.find(src, "\tlocal DEFAULT = {", 1, true)
	T.ok(s1 ~= nil, path .. ": storage starts")
	local e1 = s1 and string.find(src, "\n\tloadAlign()\n", s1, true)
	T.ok(e1 ~= nil, path .. ": storage ends")
	local s2 = e1 and string.find(src, "\tlocal TAB = {", e1, true)
	T.ok(s2 ~= nil, path .. ": adapter starts")
	local e2 = s2 and string.find(src, "\tfunction C.alignFrame()", s2, true)
	T.ok(e2 ~= nil, path .. ": adapter ends")
	if not (s1 and e1 and s2 and e2) then
		return nil
	end
	local storage = string.sub(src, s1, e1 + #"\n\tloadAlign()")
	local adapter = string.sub(src, s2, e2 - 1)
	return storage, adapter
end

local function load(path, W)
	local storage, adapter = slices(path)
	if not storage then
		return nil
	end
	local code = PRELUDE .. storage .. "\n" .. adapter .. "\nreturn AL, VAL, DEFAULT, TAB, FILE"
	local chunk, why = loadstring(code, "=" .. path)
	T.ok(chunk ~= nil, path .. " compiles: " .. tostring(why))
	if not chunk then
		return nil
	end
	W.genv.AtsukoHub = W.hub
	return chunk(W.C, W.CFG, W.HttpService, W.isfile, W.readfile, W.writefile, W.getgenv, W.task, ENUM, function()
		return CF
	end, function()
		return CF
	end, math.rad, function()
		return CF
	end, function()
		return CF
	end, type)
end

local function same(a, b)
	if #a ~= #b then
		return false
	end
	for i = 1, #a do
		if a[i] ~= b[i] then
			return false
		end
	end
	return true
end

for _, spec in ipairs(FAMILY) do
	T.section("main_adapters: " .. spec.title .. " (" .. spec.file .. ")")
	local W = world()
	local AL, VAL, DEFAULT, TAB, FILE = load(spec.file, W)
	if AL then
		T.ok(W.genv.AtsukoAlign == AL, "the adapter is published in getgenv().AtsukoAlign")
		T.eq(AL.title, spec.title)
		T.eq(#AL.tabs, spec.tabs)
		T.eq(AL.file, "Test.json", "the file name comes from the script's own setting")
		T.eq(AL.version, 1)
		T.eq(AL.dirty, false)
		T.eq(AL.open, false)
		T.eq(AL.key, "J", "the old key letter is still shown")
		for _, name in ipairs({ "alive", "focus", "get", "set", "put", "reset", "save", "later", "load", "watch", "found" }) do
			T.eq(type(AL[name]), "function", "method " .. name)
		end
		if spec.roll then
			T.eq(type(AL.opts), "function", "opts")
			T.eq(type(AL.setOpt), "function", "setOpt")
		else
			T.eq(AL.optList, nil, "this script has no extra buttons")
		end
		T.eq(AL.alive(), true)
		W.C.alive = false
		T.eq(AL.alive(), false, "alive follows the script")
		W.C.alive = true
		T.eq(W.hubCalls.ready, 1, "the hub was told the adapter is there")
		T.eq(AL.found(), "found something")

		local v = AL.get(1)
		T.eq(#v, 6)
		v[1] = 99
		T.eq(AL.get(1)[1], 0, "get returns a copy")
		T.eq(AL.get(#AL.tabs + 20), nil, "an unknown tab has no values")

		T.eq(AL.set(1, 1, 0.12345), 0.123, "moves round to 0.001")
		T.eq(AL.set(1, 2, -0.0004), 0, "tiny moves round to zero")
		T.eq(AL.set(1, 4, 190), -170, "turns wrap into -180..180")
		T.eq(AL.set(1, 5, 360), 0)
		T.eq(AL.set(1, 6, 12.34), 12.3, "turns round to 0.1")
		T.eq(AL.set(1, 1, 1e6), nil, "a huge value is refused")
		T.eq(AL.set(1, 1, "abc"), nil)
		T.eq(AL.set(1, 1, 0 / 0), nil, "nan is refused")
		T.eq(AL.set(1, 1, 1 / 0), nil, "infinity is refused")
		T.eq(AL.set(1, 1, "2.5"), 2.5, "a number in a string is fine")
		T.eq(AL.set(250, 1, 1), nil, "an unknown tab is refused")
		T.eq(AL.get(1)[1], 2.5)
		T.eq(AL.dirty, true, "a change marks it unsaved")

		local before = W.writes
		W.advance(1.4)
		T.eq(W.writes, before, "it waits for a moment before saving")
		W.advance(0.2)
		T.eq(W.writes, before + 1, "it saves by itself after a moment")
		T.eq(AL.dirty, false)
		local events = {}
		local unwatch = AL.watch(function(what)
			events[#events + 1] = what
		end)
		AL.set(1, 1, 3)
		W.advance(0.2)
		AL.set(1, 1, 4)
		W.advance(1.4)
		T.eq(W.writes, before + 1, "no save while changes keep coming")
		W.advance(0.3)
		T.eq(W.writes, before + 2, "two quick changes make one save")
		T.same(events, { "saved" })
		unwatch()
		AL.set(1, 1, 5)
		W.advance(2)
		T.eq(W.writes, before + 3)
		T.same(events, { "saved" }, "after unwatch nothing arrives")

		AL.put(1, { 1, 2, 3, 4, 5, 6 })
		T.same(AL.get(1), { 1, 2, 3, 4, 5, 6 })
		AL.put(1, { 7, 8 })
		T.same(AL.get(1), { 7, 8, 0, 0, 0, 0 }, "missing entries become zero")
		AL.put(1, "nope")
		T.same(AL.get(1), { 7, 8, 0, 0, 0, 0 }, "a bad value is ignored")
		AL.put(250, { 1, 2, 3, 4, 5, 6 })

		AL.put(1, { 1, 2, 3, 4, 5, 6 })
		AL.reset(1)
		T.same(AL.get(1), DEFAULT[1], "reset goes back to the script's default")

		AL.put(1, { 1.5, 2.5, 3.5, 40, 50, 60 })
		local ok = AL.save()
		T.eq(ok, true)
		local saved = jsonDecode(W.files["Test.json"])
		T.eq(saved.v, 1, "the file keeps its version number")
		local slots = 0
		for k, val in pairs(saved) do
			if k ~= "v" then
				slots = slots + 1
				T.eq(#val, 6, "slot " .. k .. " has six numbers")
			end
		end
		T.ok(slots >= #AL.tabs, "every tab has a slot in the file")
		AL.put(1, { 9, 9, 9, 9, 9, 9 })
		T.eq(AL.dirty, true)
		local loaded = AL.load()
		T.eq(loaded, true)
		T.same(AL.get(1), { 1.5, 2.5, 3.5, 40, 50, 60 }, "load brings back what save wrote")
		T.eq(AL.dirty, false, "loading clears the unsaved mark")

		W.files["Test.json"] = "this is not json"
		local ok2, why2 = AL.load()
		T.eq(ok2, false)
		T.eq(why2, "Test.json is damaged")
		T.same(AL.get(1), { 1.5, 2.5, 3.5, 40, 50, 60 }, "a damaged file changes nothing")
		W.files["Test.json"] = nil
		local ok3, why3 = AL.load()
		T.eq(ok3, false)
		T.eq(why3, "no saved alignment yet")
		W.files["Test.json"] = jsonEncode({ v = 1, gun1 = { 1, 2, "x", 4, 1e9, 6 } })
		AL.put(1, { 5, 5, 5, 5, 5, 5 })
		AL.load()
		local got = AL.get(1)
		T.ok(got[1] == 1 and got[2] == 2 and got[4] == 4 and got[6] == 6, "good numbers from the file are used")

		AL.focus(2)
		if spec.roll then
			local roll = nil
			for _, o in ipairs(AL.optList) do
				if o[1] == "roll" then
					roll = o
				end
			end
			T.ok(roll ~= nil, "the roll button is listed")
			T.eq(roll[3], "button")
			AL.put(2, { 0, 0, 0, 10, 0, 0 })
			AL.setOpt("roll", true)
			T.eq(AL.get(2)[4], -170, "roll turns the current tab by 180 and wraps")
			AL.setOpt("roll", true)
			T.eq(AL.get(2)[4], 10)
			T.eq(AL.get(1)[4], 4, "and leaves the other tabs alone")
		end
		AL.focus(250)
		if spec.roll then
			AL.setOpt("roll", true)
			T.eq(AL.get(2)[4], -170, "an unknown tab does not take the focus away")
			AL.setOpt("roll", true)
			T.eq(type(AL.opts()), "table")
			T.eq(AL.optsSaved, false, "options are not saved to the file")
		end
		if spec.hats then
			local names = {}
			for _, o in ipairs(AL.optList) do
				names[#names + 1] = o[1]
			end
			T.same(names, { "hatsword", "hatgun", "roll" })
			local flipped = {}
			W.C.toggleHat = function(k)
				flipped[#flipped + 1] = k
			end
			W.C.hatOn = function()
				return true
			end
			AL.setOpt("hatsword", false)
			AL.setOpt("hatgun", true)
			T.same(flipped, { "sword" }, "a hat switch only flips when it has to")
			T.eq(AL.opts().hatsword, true)
			W.C.hatOn = function(k)
				return k ~= "gun"
			end
			T.eq(AL.opts().hatgun, false, "the gun hat switch reports its own state")
			T.eq(AL.opts().hatsword, true)
		end
		if spec.gunHat then
			local names = {}
			for _, o in ipairs(AL.optList) do
				names[#names + 1] = o[1]
			end
			T.same(names, { "hatgun", "roll" }, "one gun hat switch and the roll button")
			local flipped = {}
			W.C.toggleHat = function(k)
				flipped[#flipped + 1] = k
			end
			local on = true
			W.C.hatOn = function(k)
				return k == "gun" and on
			end
			AL.setOpt("hatgun", true)
			T.same(flipped, {}, "it is on already, nothing flips")
			AL.setOpt("hatgun", false)
			T.same(flipped, { "gun" }, "turning it off flips the gun hat")
			on = false
			T.eq(AL.opts().hatgun, false)
			T.eq(AL.opts().hatsword, nil, "there is no sword switch here")
			AL.setOpt("hatsword", true)
			T.same(flipped, { "gun" }, "an unknown switch does nothing")
		end

		T.eq(type(W.C.toggleAlign), "function")
		W.C.toggleAlign()
		T.eq(W.hubCalls.align, 1, "the key forwards to the hub window")
		W.genv.AtsukoHub = nil
		W.C.toggleAlign()
		T.eq(W.notes[#W.notes], spec.title .. ": Open Atsuko Hub to line things up, the alignment lives there now")
		W.genv.AtsukoHub = W.hub
		T.eq(W.C.alignOpen(), false)
		AL.open = true
		T.eq(W.C.alignOpen(), true, "the muzzle marker follows the window being open")

		T.eq(#W.stops, 1, "one stop handler")
		local stopEvents = {}
		AL.watch(function(what)
			stopEvents[#stopEvents + 1] = what
		end)
		AL.set(1, 1, 8)
		local readyBefore = W.hubCalls.ready
		local writesBefore = W.writes
		W.stops[1]()
		T.eq(W.writes, writesBefore + 1, "stopping saves what was not saved")
		T.eq(W.genv.AtsukoAlign, nil, "stopping removes the adapter")
		T.same(stopEvents, { "stop" })
		T.eq(AL.open, false)
		T.eq(W.hubCalls.ready, readyBefore + 1, "the hub is told it went away")
		local other = { mine = false }
		W.genv.AtsukoAlign = other
		W.stops[1]()
		T.eq(W.genv.AtsukoAlign, other, "a newer script's adapter is left alone")
	end
end

T.section("main_adapters: Neptunian V")
do
	local path = "Scripts/Hat/NeptunianV.lua"
	local src = readsource(path)
	local startMark = '\tlocal HttpService = game:GetService("HttpService")\n\tlocal FILE = CONFIG.AlignFile\n'
	local s = string.find(src, startMark, 1, true)
	T.ok(s ~= nil, "the alignment block starts where expected")
	local e = s and string.find(src, "\n\ttrack(UserInputService.InputBegan:Connect(function(io, gp)\n", s, true)
	T.ok(e ~= nil, "the alignment block ends where expected")
	local block = (s and e) and string.sub(src, s, e) or ""

	local prelude = table.concat({
		"local game, CONFIG, PROFILES, DEFS, getgenv, typeof, NEP, notify, task, isfile, readfile, writefile, hooks = ...",
		"local activeKey = hooks.activeKey",
		"local swordJoint, chosen, attack = hooks.swordJoint, hooks.chosen, hooks.attack",
		"local function applyActive() hooks.applied = (hooks.applied or 0) + 1 end",
		"local function handleKey(k) hooks.keys[#hooks.keys + 1] = k end",
		"local function NEP_findSword(force) hooks.finds = (hooks.finds or 0) + 1 end",
		"local function NEP_cycleSword() hooks.cycles = (hooks.cycles or 0) + 1 end",
		"hooks.setKey = function(k) activeKey = k end",
	}, "\n") .. "\n"
	local chunk, why = loadstring(prelude .. block .. "\nreturn AL, function() return VAL end, FILE, TAB", "=NeptunianV")
	T.ok(chunk ~= nil, "the block compiles: " .. tostring(why))
	if chunk then
		local W = world()
		local DEFSET = {
			corrupt = { key = "corrupt", name = "Corrupt Demonic Greatsword", align = { sword = { 0, 0, 0, 0, 0, 0 }, swordback = { 1, 1, 1, 10, 20, 30 }, base = { 5, 6, 7 } } },
			venom = { key = "venom", name = "Hacklords Venom Greatsword", align = { sword = { 2, 2, 2, 20, 20, 20 }, swordback = { 0, 0, 0, 0, 0, 0 }, base = { 0, 0, 0 } } },
		}
		local PROF = {}
		for key, def in pairs(DEFSET) do
			PROF[key] = { table.clone(def.align.sword), table.clone(def.align.swordback), { 0, 0, 0, def.align.base[1], def.align.base[2], def.align.base[3] } }
		end
		local nep = { alive = true }
		local hooks = { activeKey = "corrupt", keys = {}, swordJoint = nil, chosen = nil, attack = false }
		local files = W.files
		local game = {
			GetService = function(_, name)
				return W.HttpService
			end,
		}
		local AL, getVal, FILE, TAB = chunk(game, { AlignFile = "NeptunianFDlessAlign.json" }, PROF, DEFSET, W.getgenv, type, nep, function(text, dur)
			W.notes[#W.notes + 1] = text
		end, W.task, W.isfile, W.readfile, W.writefile, hooks)
		T.eq(FILE, "NeptunianFDlessAlign.json", "the file name did not change")
		T.same(TAB, { "Hand", "Back", "Base" })
		T.ok(W.genv.AtsukoAlign == AL, "published")
		T.eq(AL.title, "Neptunian V")
		T.eq(AL.key, "P")
		T.eq(AL.marker, false, "no marker ball for a sword")
		T.eq(AL.optsSaved, false)
		T.eq(AL.gun(), "Corrupt Demonic Greatsword")
		T.same(AL.rows(3), { 4, 5, 6 }, "the Base tab only shows the three Turn rows")
		T.eq(AL.rows(1), nil)
		T.eq(AL.rows(2), nil)
		T.eq(AL.found(), "Corrupt Demonic Greatsword  |  no sword found - wear one, then tap Find sword")
		hooks.chosen = nil
		T.eq(AL.alive(), true)
		nep.alive = false
		T.eq(AL.alive(), false)
		nep.alive = true

		T.same(AL.get(2), { 1, 1, 1, 10, 20, 30 }, "the Back tab starts from the sword's own spot")
		T.same(AL.get(3), { 0, 0, 0, 5, 6, 7 })
		local applied = hooks.applied or 0
		T.eq(AL.set(2, 1, 0.5555), 0.556)
		T.eq(AL.set(2, 4, 200), -160)
		T.eq(AL.set(3, 6, 90.04), 90)
		T.ok((hooks.applied or 0) > applied, "the sword is moved right away")
		T.eq(AL.dirty, true)
		T.eq(AL.set(2, 1, 1e7), nil)
		AL.reset(2)
		T.same(AL.get(2), { 1, 1, 1, 10, 20, 30 }, "reset uses the sword's own default")
		AL.reset(3)
		T.same(AL.get(3), { 0, 0, 0, 5, 6, 7 }, "the Base default keeps three zero moves")

		AL.put(1, { 1, 2, 3, 4, 5, 6 })
		AL.put(3, { 9, 9, 9, 15, 25, 35 })
		T.eq(AL.save(), true)
		local data = jsonDecode(W.files["NeptunianFDlessAlign.json"])
		T.eq(data.v, 2)
		T.same(data.profiles.corrupt.sword, { 1, 2, 3, 4, 5, 6 })
		T.same(data.profiles.corrupt.base, { 15, 25, 35 }, "the base is saved as three turns")
		T.same(data.profiles.venom.sword, { 2, 2, 2, 20, 20, 20 }, "the other sword is saved too")
		AL.put(1, { 0, 0, 0, 0, 0, 0 })
		T.eq(AL.load(), true)
		T.same(AL.get(1), { 1, 2, 3, 4, 5, 6 })
		T.same(AL.get(3), { 9, 9, 9, 15, 25, 35 }, "only the three turns of the Base tab come from the file")
		T.eq(AL.dirty, false)

		W.files["NeptunianFDlessAlign.json"] = jsonEncode({ sword = { 7, 7, 7, 7, 7, 7 }, swordback = { 1, 1, 1, 1, 1, 1 }, base = { 1, 2, 3 } })
		AL.load()
		T.same(AL.get(1), { 7, 7, 7, 7, 7, 7 }, "a file from the old one-sword version still loads")

		local events = {}
		AL.watch(function(what)
			events[#events + 1] = what
		end)
		nep.onProfileChanged()
		T.same(events, { "gun" })
		hooks.setKey("venom")
		nep.onProfileChanged()
		T.same(events, { "gun", "gun" })
		T.eq(AL.gun(), "Hacklords Venom Greatsword")
		T.same(AL.get(1), { 2, 2, 2, 20, 20, 20 }, "after a sword switch the tabs show the other sword")

		AL.focus(2)
		AL.put(2, { 0, 0, 0, 100, 0, 0 })
		AL.focus(250)
		AL.setOpt("roll")
		T.eq(AL.get(2)[4], -80, "roll turns the tab you are on, an unknown tab does not take the focus")
		AL.setOpt("equip")
		T.same(hooks.keys, { "f" }, "equip presses F")
		hooks.keys = {}
		AL.setOpt("find")
		T.eq(hooks.finds, 1)
		AL.setOpt("sword")
		T.eq(hooks.cycles, 1)
		local labels = {}
		for _, o in ipairs(AL.optList) do
			labels[#labels + 1] = o[1] .. ":" .. o[3]
		end
		T.same(labels, { "equip:button", "find:button", "sword:button", "roll:button" })
		T.eq(AL.opts().anything, nil)

		T.eq(nep.guiPress, nil)
		AL.press()
		T.eq(type(nep.guiPress), "number", "a press in the hub window counts as a GUI press")

		W.genv.AtsukoHub = W.hub
		nep.toggleAlign()
		T.eq(W.hubCalls.align, 1)
		W.genv.AtsukoHub = nil
		nep.toggleAlign()
		T.eq(W.notes[#W.notes], "Open Atsuko Hub to line things up, the alignment lives there now")

		AL.set(1, 1, 3)
		local writes = W.writes
		local readyBefore = W.hubCalls.ready
		W.genv.AtsukoHub = W.hub
		nep.alignStop()
		T.eq(W.writes, writes + 1, "stopping saves what was not saved")
		T.eq(W.genv.AtsukoAlign, nil)
		T.eq(events[#events], "stop")
		T.eq(W.hubCalls.ready, readyBefore + 1)
		local other = { mine = false }
		W.genv.AtsukoAlign = other
		nep.alignStop()
		T.eq(W.genv.AtsukoAlign, other, "a newer script's adapter is left alone")
	end
end

T.section("main_adapters: InternalWar")
do
	local path = "Scripts/Hat/InternalWar.lua"
	local src = readsource(path)
	local s1 = string.find(src, "local ALTAB = {", 1, true)
	local e1 = s1 and string.find(src, "C.connect(UIS.InputBegan, function(io, gp)", s1, true)
	T.ok(s1 ~= nil and e1 ~= nil, "the adapter is found in InternalWar")
	if s1 and e1 then
		local body = string.sub(src, s1, e1 - 1)
		local prelude = table.concat({
			"local C, IW, ALIGN, ALIGN2, ALIGNFILE, saveAlign, loadAlign, hatCount, note, getgenv, task = ...",
			"local typeof = type",
		}, "\n") .. "\n"
		local chunk, why = loadstring(prelude .. body .. "\nreturn AL", "=" .. path)
		T.ok(chunk ~= nil, "it compiles: " .. tostring(why))
		local W = world()
		W.genv.AtsukoHub = W.hub
		local ALIGN = { { 0, 0, 0, 0, 0, 0 }, { 0, 0, 0, 0, 0, 0 }, { 0, 0, 0, 0, 0, 0 }, { 0, 0, 0, 0, 0, 0 } }
		local ALIGN2 = { { 0, 0, 0, 0, 0, 0 }, { 0, 0, 0, 0, 0, 0 }, { 0, 0, 0, 0, 0, 0 }, { 0, 0, 0, 0, 0, 0 }, { 0, 0, 0, 0, 0, 0 } }
		local saves, loads, sizes = 0, 0, 0
		local saveOk = true
		W.C.toggleSize = function()
			sizes = sizes + 1
		end
		local AL = chunk(W.C, { AlignKey = "p" }, ALIGN, ALIGN2, "InternalWarAlign.json", function()
			saves = saves + 1
			return saveOk
		end, function()
			loads = loads + 1
		end, function()
			return 5, 2
		end, function(text)
			W.notes[#W.notes + 1] = "Internal War: " .. text
		end, W.getgenv, W.task)
		T.ok(W.genv.AtsukoAlign == AL, "the adapter is published")
		T.eq(AL.title, "InternalWar")
		T.same(AL.tabs, { "Head", "Torso", "Arms", "Legs", "UGC Torso", "UGC R Arm", "UGC L Arm", "UGC R Leg", "UGC L Leg" })
		T.eq(AL.file, "InternalWarAlign.json")
		T.eq(AL.key, "P")
		T.eq(W.hubCalls.ready, 1, "the hub is told the adapter is there")
		T.eq(AL.set(2, 1, 1.23456), 1.235, "moves are rounded to a thousandth")
		T.eq(ALIGN[2][1], 1.235, "the Void tabs write the script's own numbers")
		T.eq(AL.set(6, 6, 190), -170, "turns wrap")
		T.eq(ALIGN2[2][6], -170, "tab 6 is the second UGC piece")
		T.eq(AL.set(10, 1, 1), nil, "a tab past the last does nothing")
		T.eq(AL.set(1, 1, 0 / 0), nil)
		T.eq(AL.set(1, 1, 1e6), nil)
		T.eq(AL.dirty, true)
		W.advance(2)
		T.eq(saves, 1, "it saves by itself a moment later")
		T.eq(AL.dirty, false)
		AL.put(3, { 1, 2, 3, 4, 5, 6 })
		T.same(AL.get(3), { 1, 2, 3, 4, 5, 6 })
		T.ok(AL.get(3) ~= ALIGN[3], "get hands out a copy")
		AL.reset(3)
		T.same(ALIGN[3], { 0, 0, 0, 0, 0, 0 })
		saveOk = false
		local ok, why2 = AL.save()
		T.eq(ok, false)
		T.eq(why2, "couldn't write InternalWarAlign.json")
		saveOk = true
		local events = {}
		local unwatch = AL.watch(function(what)
			events[#events + 1] = what
		end)
		AL.load()
		T.eq(loads, 1)
		T.eq(events[1], "load")
		unwatch()
		AL.load()
		T.eq(#events, 1, "a watcher that left hears nothing")
		T.eq(AL.found(), "Void hats: 3 of 6  ·  UGC limbs: 2 of 5")
		T.same(AL.optList, { { "size", "Titan size", "button" } })
		AL.setOpt("size")
		T.eq(sizes, 1, "the Titan size button opens the Titan Scale panel")
		AL.setOpt("other")
		T.eq(sizes, 1)
		W.C.toggleAlign()
		T.eq(W.hubCalls.align, 1, "P and -align forward to the hub window")
		W.genv.AtsukoHub = nil
		W.C.toggleAlign()
		T.eq(W.notes[#W.notes], "Internal War: Open Atsuko Hub to line the Titan hats up, the alignment lives there now")
		W.genv.AtsukoHub = W.hub
		T.eq(#W.stops, 1, "one stop handler")
		AL.set(1, 2, 2)
		local before = saves
		W.stops[1]()
		T.eq(saves, before + 1, "stopping saves what was not saved")
		T.eq(W.genv.AtsukoAlign, nil, "and takes the adapter down")
	end
end
