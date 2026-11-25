local fd = readsource("Reanimation/Hat/FDless.lua")

local function cut(from, to)
	local a = string.find(fd, from, 1, true)
	T.ok(a ~= nil, "anchor found: " .. from)
	local b = a and string.find(fd, to, a, true)
	T.ok(b ~= nil, "anchor found: " .. to)
	if not (a and b) then
		return ""
	end
	return string.sub(fd, a, b - 1)
end

T.section("fd_mode_model: the code under test is cut out of the shipped FDless.lua")
local modePart = cut('local mode="default"', "\tlocal keyW=KeyCode.W")
local keyPart = cut("elseif modes[a] and not forced then", "\n\tend))")
T.ok(#modePart > 500, "mode section extracted")
T.ok(#keyPart > 200, "key branch extracted")
T.ok(string.find(modePart, "local forced=nil", 1, true) ~= nil, "forced state is inside the extracted section")

local source = table.concat({
	"local KeyCode, supper, ssub, type, next, emptyfunction = ...",
	modePart,
	"local function press(a)",
	"if false then",
	keyPart,
	"end",
	"return {",
	"addmode = addmode, forceMode = forceMode, releaseMode = releaseMode, isForced = isForced, press = press,",
	"lerps = function() return lerpsIdle, lerpsWalk, lerpsJump, lerpsFall end,",
	"mode = function() return mode end,",
	"defaultmode = function() return defaultmode end,",
	"modes = modes,",
	"}",
}, "\n")

local compiled, compileError = loadstring(source, "=fd_mode_model")
T.ok(compiled ~= nil, "extracted section compiles: " .. tostring(compileError))

local EMPTY = function() end
local KEYS = { Q = "KeyCode.Q", E = "KeyCode.E", R = "KeyCode.R" }

local function build()
	return compiled(KEYS, string.upper, string.sub, type, next, EMPTY)
end

local function newMode(name, log, only)
	local m = {}
	for _, k in ipairs({ "idle", "walk", "jump", "fall" }) do
		if not only or only[k] then
			m[k] = function()
				log[#log + 1] = name .. "." .. k
			end
		end
	end
	m.modeEntered = function()
		log[#log + 1] = name .. ".entered"
	end
	m.modeLeft = function()
		log[#log + 1] = name .. ".left"
	end
	return m
end

local function frame(inst, log)
	local idle, walk, jump, fall = inst.lerps()
	idle()
	walk()
	jump()
	fall()
	return log
end

local function flat(log)
	return table.concat(log, ",")
end

local function reset(log)
	for i = #log, 1, -1 do
		log[i] = nil
	end
end

T.section("fd_mode_model: behaviour when nobody forces anything")
do
	local log = {}
	local inst = build()
	T.eq(inst.isForced(), false, "not forced at start")
	local def = newMode("def", log)
	inst.addmode("default", def)
	T.eq(flat(log), "def.entered", "the default mode is entered once")
	local idle, walk, jump, fall = inst.lerps()
	T.ok(idle == def.idle and walk == def.walk and jump == def.jump and fall == def.fall, "lerps come from the default mode")
	local q = newMode("q", log)
	inst.addmode("q", q)
	reset(log)
	inst.press(KEYS.Q)
	T.eq(flat(log), "def.left,q.entered", "key switch leaves the old mode and enters the new one")
	T.eq(inst.mode(), KEYS.Q)
	inst.press(KEYS.Q)
	T.eq(inst.mode(), "default", "the same key again returns to default")
	reset(log)
	inst.press(KEYS.R)
	T.eq(flat(log), "", "a key with no mode does nothing")
	local partial = newMode("p", log, { idle = true })
	inst.addmode("e", partial)
	inst.press(KEYS.E)
	local i2, w2, j2, f2 = inst.lerps()
	T.ok(i2 == partial.idle and w2 == def.walk and j2 == def.jump and f2 == def.fall, "a key mode falls back to default for missing functions")
end

T.section("fd_mode_model: forceMode")
do
	local log = {}
	local inst = build()
	local def = newMode("def", log)
	inst.addmode("default", def)
	reset(log)
	local emote = newMode("emote", log, { idle = true, walk = true })
	inst.forceMode(emote)
	T.eq(inst.isForced(), true)
	T.eq(flat(log), "emote.entered", "modeEntered of the forced mode runs once")
	local idle, walk, jump, fall = inst.lerps()
	T.ok(idle == emote.idle and walk == emote.walk, "present functions come from the forced mode")
	T.ok(jump == EMPTY and fall == EMPTY, "missing functions become the empty function, not the default mode's")
	reset(log)
	frame(inst, log)
	T.eq(flat(log), "emote.idle,emote.walk", "a frame runs only the emote's own functions")
	local before1, before2 = inst.lerps()
	inst.forceMode(nil)
	inst.forceMode("x")
	inst.forceMode(5)
	local after1, after2 = inst.lerps()
	T.ok(before1 == after1 and before2 == after2, "a non-table argument changes nothing")
	T.eq(inst.isForced(), true, "and the forced state stays")
	local bad = { idle = true, walk = "no", jump = 3 }
	inst.forceMode(bad)
	local bi, bw, bj, bf = inst.lerps()
	T.ok(bi == EMPTY and bw == EMPTY and bj == EMPTY and bf == EMPTY, "entries that are not functions become the empty function")
end

T.section("fd_mode_model: key presses while forced")
do
	local log = {}
	local inst = build()
	local def = newMode("def", log)
	inst.addmode("default", def)
	local q = newMode("q", log)
	inst.addmode("q", q)
	local emote = newMode("emote", log)
	inst.forceMode(emote)
	reset(log)
	inst.press(KEYS.Q)
	inst.press(KEYS.E)
	inst.press(KEYS.Q)
	T.eq(flat(log), "", "no modeLeft and no modeEntered from a stray key")
	T.eq(inst.mode(), "default", "the mode did not change")
	local idle, walk, jump, fall = inst.lerps()
	T.ok(idle == emote.idle and walk == emote.walk and jump == emote.jump and fall == emote.fall, "the emote keeps all four functions")
	inst.releaseMode()
	reset(log)
	inst.press(KEYS.Q)
	T.eq(flat(log), "def.left,q.entered", "the key works again after release")
end

T.section("fd_mode_model: releaseMode")
do
	local log = {}
	local inst = build()
	local def = newMode("def", log)
	inst.addmode("default", def)
	local emote = newMode("emote", log)
	inst.forceMode(emote)
	reset(log)
	inst.releaseMode()
	T.eq(flat(log), "emote.left", "modeLeft of the forced mode runs once and nothing else")
	T.eq(inst.isForced(), false)
	local idle, walk, jump, fall = inst.lerps()
	T.ok(idle == def.idle and walk == def.walk and jump == def.jump and fall == def.fall, "the default mode's functions are back")
	reset(log)
	inst.releaseMode()
	inst.releaseMode()
	T.eq(flat(log), "", "releasing when nothing is forced does nothing")
	frame(inst, log)
	T.eq(flat(log), "def.idle,def.walk,def.jump,def.fall", "frames run the script's functions again")
end

T.section("fd_mode_model: release equals what the key handler would have chosen")
do
	local shapes = {
		{ idle = true },
		{ walk = true },
		{ jump = true, fall = true },
		{ idle = true, walk = true, jump = true, fall = true },
		{},
	}
	for index, shape in ipairs(shapes) do
		local logA = {}
		local forcedInst = build()
		local defA = newMode("def", logA, { idle = true, walk = true, jump = true, fall = true })
		forcedInst.addmode("default", defA)
		local modeA = newMode("k", logA, shape)
		forcedInst.addmode("q", modeA)
		forcedInst.press(KEYS.Q)
		local logB = {}
		local twin = build()
		local defB = newMode("def", logB, { idle = true, walk = true, jump = true, fall = true })
		twin.addmode("default", defB)
		local modeB = newMode("k", logB, shape)
		twin.addmode("q", modeB)
		twin.press(KEYS.Q)
		forcedInst.forceMode(newMode("emote", logA))
		reset(logA)
		forcedInst.releaseMode()
		local a1, a2, a3, a4 = forcedInst.lerps()
		local b1, b2, b3, b4 = twin.lerps()
		local sameShape = (a1 == modeA.idle or a1 == defA.idle) == (b1 == modeB.idle or b1 == defB.idle)
		reset(logA)
		reset(logB)
		frame(forcedInst, logA)
		frame(twin, logB)
		T.eq(flat(logA), flat(logB), "shape " .. index .. ": a frame after release equals a frame after the key switch")
		T.eq(forcedInst.mode(), twin.mode(), "shape " .. index .. ": the current mode is the same")
		T.ok(sameShape, "shape " .. index .. ": the chosen functions have the same origin")
	end
	local log = {}
	local inst = build()
	inst.addmode("default", newMode("def", log))
	local q = newMode("q", log)
	inst.addmode("q", q)
	inst.press(KEYS.Q)
	inst.forceMode(newMode("emote", log))
	reset(log)
	inst.releaseMode()
	T.eq(flat(log), "emote.left", "a key mode that was active is not left and not entered again")
	T.eq(inst.mode(), KEYS.Q)
end

T.section("fd_mode_model: forcing twice, re-entrancy and errors")
do
	local log = {}
	local inst = build()
	inst.addmode("default", newMode("def", log))
	local one = newMode("one", log)
	local two = newMode("two", log)
	inst.forceMode(one)
	reset(log)
	inst.forceMode(two)
	T.eq(flat(log), "one.left,two.entered", "forcing another mode ends the first one first")
	T.eq(inst.isForced(), true)
	reset(log)
	inst.forceMode(two)
	T.eq(flat(log), "two.left,two.entered", "forcing the same table again leaves and enters it")
	inst.releaseMode()

	local seen = 0
	local reentrant = newMode("re", log)
	reentrant.modeLeft = function()
		seen = seen + 1
		inst.releaseMode()
	end
	inst.forceMode(reentrant)
	inst.releaseMode()
	T.eq(seen, 1, "a modeLeft that calls releaseMode again runs exactly once")
	T.eq(inst.isForced(), false)

	local broken = newMode("broken", log)
	broken.modeLeft = function()
		error("cleanup failed")
	end
	inst.forceMode(broken)
	T.fails(function()
		inst.releaseMode()
	end, "an error in modeLeft reaches the caller")
	T.eq(inst.isForced(), false, "but the state is already consistent")
	reset(log)
	frame(inst, log)
	T.eq(flat(log), "def.idle,def.walk,def.jump,def.fall", "and the script's functions are running")
end

T.section("fd_mode_model: addmode default while forced")
do
	local log = {}
	local inst = build()
	inst.addmode("default", newMode("old", log))
	local emote = newMode("emote", log)
	inst.forceMode(emote)
	local fresh = newMode("fresh", log)
	inst.addmode("default", fresh)
	T.eq(inst.isForced(), true, "still marked as forced")
	inst.releaseMode()
	local idle, walk, jump, fall = inst.lerps()
	T.ok(idle == fresh.idle and walk == fresh.walk and jump == fresh.jump and fall == fresh.fall, "release uses the newest default mode")
end

T.section("fd_mode_model: the shipped file exports the three functions")
T.ok(string.find(fd, "addmode=addmode,\n\t\tforceMode=forceMode,\n\t\treleaseMode=releaseMode,\n\t\tisForced=isForced,\n", 1, true) ~= nil, "returned table lists forceMode, releaseMode and isForced after addmode")
T.ok(string.find(fd, "local forceMode=function(m)", 1, true) ~= nil)
T.ok(string.find(fd, "local releaseMode=function()", 1, true) ~= nil)
T.ok(string.find(fd, "local isForced=function()", 1, true) ~= nil)
T.eq(select(2, string.gsub(fd, "SendNotification", "")), 0, "no SendNotification call is left in the shipped FDless")
T.eq(select(2, string.gsub(fd, "hubNotify%(", "")), 2, "hubNotify is defined once and called once")

T.section("fd_mode_model: the functions from the newer FDless")
for _, name in ipairs({ "setShiftlock", "getShiftlock", "setInputBlocker", "setAntivoid", "getAntivoid", "setCamZoom", "getCamZoom", "setCamOverride" }) do
	T.ok(string.find(fd, "\t\t" .. name .. "=", 1, true) ~= nil, name .. " is in the table FDless returns")
end
T.ok(string.find(fd, "local antivoid=true", 1, true) ~= nil, "antivoid starts on, like the newer FDless")
T.ok(string.find(fd, "local camOverride=nil", 1, true) ~= nil)
T.ok(string.find(fd, "local ok,ncf=pcall(camOverride,camcf)", 1, true) ~= nil, "the camera override runs in a pcall")
T.ok(string.find(fd, "if inputBlocker and inputBlocker(inputObject) then", 1, true) ~= nil, "a blocked touch is ignored")
T.ok(string.find(fd, "if b or (inputBlocker and inputBlocker(a)) then return end", 1, true) ~= nil, "a blocked input does not move the camera")
T.ok(string.find(fd, "AtsukoScriptAligns", 1, true) ~= nil, "the running script's own hat list is read")
