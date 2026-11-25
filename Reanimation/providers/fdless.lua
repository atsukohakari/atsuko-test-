local ctx = nil

local function toggle(key, label, desc, default, group)
	return { key = key, type = "toggle", label = label, desc = desc, default = default, group = group, applies = "next" }
end

local function choice(key, label, desc, options, labels, default, group, needs)
	return { key = key, type = "choice", label = label, desc = desc, options = options, labels = labels, default = default, group = group, optionNeeds = needs, applies = "next" }
end

local SETTINGS = {
	toggle("fling", "Fling", "Lets the reanimate fling other players", true, "Fling"),
	toggle("clickfling", "Click to fling", "Click a player to fling them. With Ctrl held a click teleports instead", false, "Fling"),
	choice("flingdirection", "Fling direction", "Which way the hats hit a target", { 0, 1, 2 }, { "Down", "Up", "Side" }, 0, "Fling"),
	choice("flingtargetting", "Fling targeting", "How a target is grabbed. It drops to what your executor supports by itself", { 0, 1, 2, 3 }, { "Basic", "Joints", "Script", "Best" }, 3, "Fling", { [3] = "sethiddenproperty", [2] = "setscriptable" }),
	toggle("highlightflingtargets", "Highlight targets", "A red outline around the players you fling", true, "Fling"),
	choice("flingchangestate", "Body while flinging", "How your real character is held while it flings", { 1, 2, 3 }, { "Light", "Ragdoll", "Standard" }, 3, "Fling"),
	toggle("ctrltp", "Ctrl + click teleport", "Hold Ctrl and click to teleport where you point", true, "Controls"),
	toggle("allowshiftlock", "Shift lock", "Shift toggles shift lock", true, "Controls"),
	toggle("placeholders", "Hat placeholders", "Leaves a see-through copy of each hat where it sits", true, "Body"),
	choice("respawntp", "Real body goes", "Where your real character waits while you are reanimated", { 0, 1, 2, 3 }, { "Same spot", "Nearby", "Beside", "Hidden" }, 3, "Body"),
	choice("breakjointsmethod", "Break joints", "How your real character's joints are broken. 4 needs replicatesignal", { 1, 2, 3, 4 }, { "1", "2", "3", "4" }, 1, "Body", { [4] = "replicatesignal" }),
	toggle("simrad", "Simulation radius", "Raises the simulation radius so your hats stay yours", true, "Body"),
	toggle("hidedeatheffect", "Hide health bar", "Hides Roblox's health bar while you are reanimated", true, "Body"),
	toggle("discharscripts", "Disable character scripts", "Turns off the scripts inside your character so they can't fight the reanimate", true, "Body"),
	toggle("disguiscripts", "Disable GUI scripts", "Turns off scripts that appear in your PlayerGui while reanimated", true, "Body"),
}

local Provider = {
	AtsukoReanimProvider = true,
	id = "fdless",
	kind = "hat",
	name = "FDless",
	credit = "MyWorld, rqz",
	caps = { fdApi = true, emotes = true, bodyCommands = false, fling = true, bullet = false, stoppable = true, respawnSafe = true, needsR6 = false },
	settings = SETTINGS,
	keep = { GenesisFDless = true, AtsukoHatFd = true, AtsukoScriptAligns = true },
	FILE = "Reanimation/Hat/FDless.lua",
	REST_JOINTS = { "RootJoint", "Neck", "Right Shoulder", "Left Shoulder", "Right Hip", "Left Hip" },
}

local state = {
	fd = nil,
	shared = nil,
	loadedOpts = nil,
	linked = false,
	prior = nil,
	api = nil,
	mode = nil,
	lastDefault = nil,
	takeover = false,
	best = false,
	hip = 0,
	wrapped = {},
	hooked = {},
}

local emo = { lib = nil, host = nil, mode = nil, conn = nil, last = 0, on = false, pose = nil, ignored = {} }

local function firstLine(text)
	text = tostring(text)
	return (string.match(text, "^[^\r\n]*")) or text
end

local function copy(t)
	local out = {}
	for k, v in pairs(t) do
		out[k] = v
	end
	return out
end

local function fire(what, detail)
	local f = Provider.onChanged
	if type(f) == "function" then
		pcall(f, what, detail)
	end
end

local function isOn(fd)
	if type(fd) ~= "table" or type(fd.isReanimated) ~= "function" then
		return false
	end
	local ok, value = pcall(fd.isReanimated)
	return ok and value and true or false
end

local function holders()
	local list = {}
	local first = ctx and ctx.RG
	local second = ctx and ctx.G
	if type(first) == "table" then
		list[1] = first
	end
	if type(second) == "table" and second ~= first then
		list[#list + 1] = second
	end
	return list
end

local function readFd()
	for _, t in ipairs(holders()) do
		local ok, v = pcall(function()
			return t.GenesisFDless
		end)
		if ok and type(v) == "table" then
			return v
		end
	end
	return nil
end

local function putFd(value)
	for _, t in ipairs(holders()) do
		pcall(function()
			t.GenesisFDless = value
		end)
	end
end

local function putHat(value)
	local env = ctx and ctx.genv
	for _, t in ipairs({ env, ctx and ctx.RG }) do
		if type(t) == "table" then
			pcall(function()
				t.AtsukoHatFd = value
				if value == nil then
					t.AtsukoScriptAligns = nil
					t.AtsukoRigHats = nil
					t.AtsukoFreeWeapons = nil
					t.AtsukoRigView = nil
				end
			end)
		end
	end
end

local function snapshotFd()
	local out = {}
	for _, t in ipairs(holders()) do
		local ok, v = pcall(function()
			return t.GenesisFDless
		end)
		out[#out + 1] = { t = t, v = ok and v or nil }
	end
	return out
end

local function restoreFd(snap)
	for _, item in ipairs(snap or {}) do
		pcall(function()
			item.t.GenesisFDless = item.v
		end)
	end
end

local function currentFd()
	local g = readFd()
	if g then
		return g
	end
	return state.fd
end

local function waitUntil(test, limit)
	local t0 = ctx.now()
	while ctx.now() - t0 < limit do
		if test() then
			return true
		end
		ctx.wait(0.1)
	end
	return test()
end

local function sameOpts(a, b)
	for _, def in ipairs(SETTINGS) do
		if a[def.key] ~= b[def.key] then
			return false
		end
	end
	return true
end

local function setGlobals(opts)
	local env = ctx.genv
	local saved = {}
	for _, def in ipairs(SETTINGS) do
		local key = def.key
		local ok, old = pcall(function()
			return env[key]
		end)
		saved[key] = { ok and old or nil }
		local value = opts[key]
		if value == nil then
			value = def.default
		end
		env[key] = value
	end
	return function()
		for key, box in pairs(saved) do
			env[key] = box[1]
		end
	end
end

local function hookApi(api)
	if state.hooked[api] or type(api.addmode) ~= "function" then
		return
	end
	state.hooked[api] = true
	local orig = api.addmode
	api.addmode = function(key, mode)
		if key == "default" and type(mode) == "table" and not state.takeover then
			state.lastDefault = mode
		end
		return orig(key, mode)
	end
	local origHip = api.setHipHeight
	if type(origHip) == "function" then
		api.setHipHeight = function(n, ...)
			state.hip = tonumber(n) or 0
			return origHip(n, ...)
		end
	end
end

local function wrap(fd)
	if state.wrapped[fd] then
		return
	end
	state.wrapped[fd] = true
	local origReanimate, origStop = fd.reanimate, fd.stopreanimate
	fd.reanimate = function(...)
		local api = origReanimate(...)
		if type(api) == "table" then
			state.api = api
			state.lastDefault = nil
			state.hip = 0
			hookApi(api)
			fire("running")
		end
		return api
	end
	fd.stopreanimate = function(...)
		pcall(Provider.undrive)
		local a, b = origStop(...)
		local had = state.api ~= nil
		state.api = nil
		state.best = false
		if had then
			fire("stopped")
		end
		return a, b
	end
end

local function stopForeign(run)
	local fd = readFd()
	if fd == nil or fd == state.shared or fd == state.fd then
		return true
	end
	if not isOn(fd) then
		return true
	end
	if type(fd.stopreanimate) ~= "function" then
		return false, "another FDless is running and can't be stopped from here"
	end
	pcall(fd.stopreanimate)
	if not waitUntil(function()
		return not isOn(fd)
	end, 4) then
		return false, "another FDless is still running, stop it first"
	end
	if run and run.notify then
		run.notify("FDless", "Stopped the FDless that was already running", "info", 3)
	end
	return true
end

local function loadShared(opts)
	if state.shared and state.loadedOpts and sameOpts(state.loadedOpts, opts) then
		state.fd = state.shared
		return state.shared
	end
	if state.shared and isOn(state.shared) then
		return nil, "FDless is running, options apply the next time you reanimate"
	end
	if state.shared and readFd() == state.shared then
		putFd(nil)
	end
	state.shared = nil
	state.fd = nil
	state.loadedOpts = nil

	local src, err = ctx.loadFile(Provider.FILE)
	if type(src) ~= "string" or #src < 200 then
		return nil, err or "couldn't read the FDless file"
	end

	local f, cerr = ctx.loadstring(src, "=FDless")
	if type(f) ~= "function" then
		return nil, firstLine(cerr or "FDless would not compile")
	end
	putFd(nil)
	local restore = setGlobals(opts)
	local ok, res = pcall(f)
	restore()
	if not ok then
		putFd(nil)
		return nil, firstLine(res)
	end
	local fd = res
	if type(fd) ~= "table" or type(fd.reanimate) ~= "function" or type(fd.stopreanimate) ~= "function" then
		fd = readFd()
	end
	if type(fd) ~= "table" or type(fd.reanimate) ~= "function" or type(fd.stopreanimate) ~= "function" then
		putFd(nil)
		return nil, "FDless did not give its API"
	end
	wrap(fd)
	state.fd = fd
	state.shared = fd
	state.loadedOpts = copy(opts)
	return fd
end

function Provider.init(context)
	ctx = context
	state.wrapped = setmetatable({}, { __mode = "k" })
	state.hooked = setmetatable({}, { __mode = "k" })
end

function Provider.available(X)
	if type(X) ~= "table" or not X.loadstring then
		return false, "your executor has no loadstring"
	end
	return true
end

function Provider.mode()
	return state.mode
end

function Provider.api()
	return state.api
end

function Provider.isForced()
	local api = state.api
	if not api then
		return false
	end
	if type(api.isForced) == "function" then
		local ok, value = pcall(api.isForced)
		return ok and value == true
	end
	return state.best == true
end

function Provider.hasForceMode()
	local api = state.api
	return api ~= nil and type(api.forceMode) == "function" and type(api.releaseMode) == "function"
end

function Provider.canEmote()
	if not state.api then
		return false, "FDless is not running"
	end
	if not currentFd() or not isOn(currentFd()) then
		return false, "FDless is not running"
	end
	if not Provider.hasForceMode() and type(state.api.addmode) ~= "function" then
		return false, "this FDless copy cannot take a pose"
	end
	return true
end

function Provider.takeover(mode)
	local api = state.api
	if not api then
		return false, "FDless is not running"
	end
	if type(mode) ~= "table" then
		return false, "no pose given"
	end
	if type(api.forceMode) == "function" then
		local ok, e = pcall(api.forceMode, mode)
		if not ok then
			return false, firstLine(e)
		end
		return true, "forced"
	end
	if type(api.addmode) ~= "function" then
		return false, "this FDless copy cannot take a pose"
	end
	state.takeover = true
	local ok, e = pcall(api.addmode, "default", mode)
	state.takeover = false
	if not ok then
		return false, firstLine(e)
	end
	state.best = true
	return true, "best effort"
end

function Provider.handback()
	local api = state.api
	if not api then
		state.best = false
		return false
	end
	if type(api.releaseMode) == "function" then
		local ok = pcall(api.releaseMode)
		state.best = false
		return ok
	end
	if state.best then
		state.best = false
		if state.lastDefault and type(api.addmode) == "function" then
			state.takeover = true
			local ok = pcall(api.addmode, "default", state.lastDefault)
			state.takeover = false
			return ok
		end
	end
	return false
end

function Provider.installDefaultMode(api)
	if type(api) ~= "table" or type(api.getJoint) ~= "function" or type(api.addmode) ~= "function" then
		return false
	end
	local joints, rest = {}, {}
	for _, name in ipairs(Provider.REST_JOINTS) do
		local joint = api.getJoint(name)
		if type(joint) ~= "table" then
			return false
		end
		joints[name] = joint
		rest[name] = joint.C0
	end
	local clock = ctx.now
	local last = clock()
	local function aim(name, offset, alpha)
		local joint = joints[name]
		local goal = rest[name]
		if offset ~= nil then
			goal = goal * offset
		end
		joint.C0 = joint.C0:Lerp(goal, alpha)
	end
	local function blend()
		local now = clock()
		local dt = math.min(now - last, 0.1)
		last = now
		return 1 - 0.002 ^ dt, now
	end
	local mode = {
		idle = function()
			local a = blend()
			for _, name in ipairs(Provider.REST_JOINTS) do
				aim(name, nil, a)
			end
		end,
		walk = function()
			local a, now = blend()
			local swing = math.sin(now * 9) * 0.85
			aim("RootJoint", nil, a)
			aim("Neck", nil, a)
			aim("Right Hip", CFrame.Angles(0, 0, swing), a)
			aim("Left Hip", CFrame.Angles(0, 0, swing), a)
			aim("Right Shoulder", CFrame.Angles(0, 0, -swing), a)
			aim("Left Shoulder", CFrame.Angles(0, 0, -swing), a)
		end,
		jump = function()
			local a = blend()
			aim("RootJoint", nil, a)
			aim("Neck", nil, a)
			aim("Right Hip", CFrame.Angles(0, 0, 0.25), a)
			aim("Left Hip", CFrame.Angles(0, 0, 0.25), a)
			aim("Right Shoulder", CFrame.Angles(0, 0, 2.4), a)
			aim("Left Shoulder", CFrame.Angles(0, 0, -2.4), a)
		end,
		fall = function()
			local a = blend()
			aim("RootJoint", nil, a)
			aim("Neck", nil, a)
			aim("Right Hip", CFrame.Angles(0, 0, -0.2), a)
			aim("Left Hip", CFrame.Angles(0, 0, -0.2), a)
			aim("Right Shoulder", CFrame.Angles(0, 0, 1.6), a)
			aim("Left Shoulder", CFrame.Angles(0, 0, -1.6), a)
		end,
	}
	state.takeover = true
	local ok = pcall(api.addmode, "default", mode)
	state.takeover = false
	return ok
end

local function rootOf(api)
	if type(api.getPart) ~= "function" or type(api.cframes) ~= "table" then
		return nil
	end
	local part = api.getPart("HumanoidRootPart")
	local cf = part and api.cframes[part]
	if typeof(cf) == "CFrame" then
		return cf
	end
	return nil
end

local rayP = nil
local function groundUnder(api, cf)
	local ok, hit = pcall(function()
		if not rayP then
			rayP = RaycastParams.new()
			rayP.FilterType = Enum.RaycastFilterType.Exclude
		end
		local list = {}
		if type(api.characters) == "table" then
			for _, v in pairs(api.characters) do
				if typeof(v) == "Instance" then
					list[#list + 1] = v
				end
			end
		end
		for _, plr in ipairs(game:GetService("Players"):GetPlayers()) do
			if plr.Character then
				list[#list + 1] = plr.Character
			end
		end
		rayP.FilterDescendantsInstances = list
		return workspace:Raycast(cf.Position + Vector3.new(0, 1, 0), Vector3.new(0, -40, 0), rayP)
	end)
	return ok and hit ~= nil
end

local function libHost(lib)
	if type(lib) ~= "table" or type(lib.currentHost) ~= "function" then
		return nil, false
	end
	local ok, h = pcall(lib.currentHost)
	if not ok then
		return nil, false
	end
	return h, true
end

local function stepLib()
	local lib = emo.lib
	if type(lib) ~= "table" or type(lib.step) ~= "function" then
		return nil
	end
	local now = ctx.now()
	local dt = math.clamp(now - emo.last, 0, 0.1)
	emo.last = now
	local h, known = libHost(lib)
	if known and h ~= emo.host then
		return nil
	end
	local ok, pose = pcall(lib.step, dt)
	if ok and type(pose) == "table" then
		emo.pose = pose
		return pose
	end
	emo.pose = nil
	return nil
end

local function poseJoints()
	local api = state.api
	if not api or type(api.getJoint) ~= "function" then
		return
	end
	local pose = stepLib()
	if not pose then
		return
	end
	local w = math.clamp(tonumber(pose.w) or 1, 0, 1)
	for i, name in ipairs(Provider.REST_JOINTS) do
		local joint = api.getJoint(name)
		local rel = pose[i]
		if type(joint) == "table" and typeof(rel) == "CFrame" and rel == rel and typeof(joint.C1) == "CFrame" then
			local goal = rel * joint.C1
			if w >= 1 or typeof(joint.C0) ~= "CFrame" then
				joint.C0 = goal
			else
				joint.C0 = joint.C0:Lerp(goal, w)
			end
		end
	end
end

local arms = { list = {}, ready = false }
local LIMBS = { Torso = true, Head = true, ["Right Arm"] = true, ["Left Arm"] = true, ["Right Leg"] = true, ["Left Leg"] = true }

local function armsKit()
	local g = ctx and ctx.genv
	local kit = type(g) == "table" and g.AtsukoEmoteWeapons or nil
	if type(kit) == "table" and type(kit.kind) == "function" and type(kit.place) == "function" then
		return kit
	end
	return nil
end

local function limbOf(api, name)
	for p in pairs(api.cframes) do
		if type(p) == "table" and rawget(p, "Name") == name and rawget(p, "m") == nil then
			return p
		end
	end
	return type(api.getPart) == "function" and api.getPart(name) or nil
end

function Provider.armsOn(api)
	if arms.ready or type(api) ~= "table" or type(api.cframes) ~= "table" or type(api.getPartJoint) ~= "function" then
		return
	end
	local kit = armsKit()
	if not kit then
		return
	end
	arms.ready = true
	local found = {}
	for e in pairs(api.cframes) do
		if type(e) == "table" and rawget(e, "m") ~= nil and rawget(e, "p") ~= nil then
			local j = api.getPartJoint(e)
			if type(j) == "table" and rawget(j, "Part0") == e then
				local p1, c1 = rawget(j, "Part1"), rawget(j, "C1")
				local limb = type(p1) == "table" and rawget(p1, "m") == nil and LIMBS[rawget(p1, "Name") or ""] and (typeof(c1) ~= "CFrame" or c1 == CFrame.identity)
				if not limb then
					found[#found + 1] = { e = e, j = j }
				end
			end
		end
	end
	local picked = {}
	for _, it in ipairs(found) do
		local name = nil
		pcall(function()
			name = rawget(it.e, "p").Parent.Name
		end)
		local ok, k = pcall(kit.kind, rawget(it.e, "m"), rawget(it.e, "t"), name)
		if ok and (k == "gun" or k == "sword") and not picked[k] then
			local size = Vector3.new(1, 1, 1)
			pcall(function()
				size = rawget(it.e, "p").Size
			end)
			local okP, limbName, cf = pcall(kit.place, k, size)
			local part = okP and limbName and limbOf(api, limbName) or nil
			if part and typeof(cf) == "CFrame" then
				it.home = { rawget(it.j, "Part1"), rawget(it.j, "C0"), rawget(it.j, "C1") }
				it.part, it.cf, it.kind = part, cf, k
				picked[k] = it
				arms.list[#arms.list + 1] = it
			end
		end
	end
end

function Provider.armsHold()
	for _, it in ipairs(arms.list) do
		it.j.Part1, it.j.C0, it.j.C1 = it.part, CFrame.identity, it.cf
	end
end

function Provider.armsOff()
	for _, it in ipairs(arms.list) do
		pcall(function()
			it.j.Part1, it.j.C0, it.j.C1 = it.home[1], it.home[2], it.home[3]
		end)
	end
	arms.list = {}
	arms.ready = false
end

function Provider.armed()
	return arms.list
end

local function underneath(which)
	return function(...)
		local m = state.lastDefault
		local f = type(m) == "table" and m[which] or nil
		if type(f) == "function" then
			local ok, e = pcall(f, ...)
			if not ok and emo.lastError ~= e then
				emo.lastError = e
				warn("[FDless emotes] " .. firstLine(e))
			end
		end
		poseJoints()
		if emo.on then
			Provider.armsOn(state.api)
			Provider.armsHold()
		end
	end
end

emo.mode = { idle = underneath("idle"), walk = underneath("walk"), jump = underneath("jump"), fall = underneath("fall") }

local function makeHost()
	local host = { name = "FDless" }
	host.note = function(text)
		local lib = emo.lib
		if type(lib) == "table" and type(lib.onNote) == "function" then
			pcall(lib.onNote, text)
		end
	end
	host.rootCF = function()
		local api = state.api
		return (api and rootOf(api)) or CFrame.new()
	end
	host.hipHeight = function()
		return 3 + (tonumber(state.hip) or 0)
	end
	host.canEmote = function()
		return Provider.canEmote()
	end
	host.moveRoot = function(cf)
		local api = state.api
		if not (api and type(api.setCfr) == "function") or typeof(cf) ~= "CFrame" then
			return false
		end
		if not groundUnder(api, cf) then
			return false
		end
		local ok = pcall(api.setCfr, cf)
		return ok
	end
	host.ignore = function(inst, on)
		local api = state.api
		local list = api and type(api.characters) == "table" and api.characters
		if not list then
			return
		end
		if on and typeof(inst) == "Instance" then
			local key = {}
			emo.ignored[key] = inst
			list[key] = inst
		else
			for key in pairs(emo.ignored) do
				list[key] = nil
			end
			table.clear(emo.ignored)
		end
		if type(api.refreshrayfilter) == "function" then
			pcall(api.refreshrayfilter)
		end
	end
	host.onEmote = function(on)
		if on then
			emo.last = ctx.now()
			emo.on = true
			local ok = Provider.takeover(emo.mode)
			if not ok then
				emo.on = false
			end
		else
			emo.on = false
			emo.pose = nil
			Provider.armsOff()
			Provider.handback()
		end
	end
	return host
end

local function tick()
	if emo.on then
		return
	end
	local lib = emo.lib
	if not lib then
		return
	end
	local now = ctx.now()
	if now - (emo.check or 0) > 1 then
		emo.check = now
		local h, known = libHost(lib)
		if known and h == nil and Provider.isRunning() then
			pcall(lib.attach, emo.host)
		end
	end
	stepLib()
end

function Provider.driver(lib)
	if type(lib) ~= "table" or type(lib.attach) ~= "function" or type(lib.step) ~= "function" then
		return false, "no emotes library"
	end
	if not Provider.isRunning() then
		return false, "FDless is not running"
	end
	if emo.lib and emo.lib ~= lib then
		Provider.undrive()
	end
	emo.lib = lib
	emo.host = emo.host or makeHost()
	local h, known = libHost(lib)
	if not known or h == nil then
		local ok, e = pcall(lib.attach, emo.host)
		if not ok then
			emo.lib = nil
			return false, firstLine(e)
		end
	end
	if not emo.conn then
		emo.last = ctx.now()
		local ok, conn = pcall(function()
			return game:GetService("RunService").Heartbeat:Connect(tick)
		end)
		if ok then
			emo.conn = conn
		end
	end
	return true
end

function Provider.undrive(lib)
	if lib ~= nil and lib ~= emo.lib then
		return false
	end
	local was = emo.lib
	if emo.conn then
		pcall(function()
			emo.conn:Disconnect()
		end)
		emo.conn = nil
	end
	if was and emo.host and type(was.detach) == "function" then
		pcall(was.detach, emo.host)
	end
	if emo.on then
		emo.on = false
		Provider.armsOff()
		pcall(Provider.handback)
	end
	emo.lib = nil
	emo.pose = nil
	return true
end

function Provider.emoteHost()
	return emo.host
end

function Provider.prepare(entry, run)
	local swap = run and run.swap and state.linked
	if swap then
		local fd = currentFd()
		if fd and isOn(fd) then
			pcall(fd.stopreanimate)
			waitUntil(function()
				return not isOn(fd)
			end, 4)
		end
	end
	state.mode = "shared"
	state.api = nil
	state.best = false
	local okStop, whyStop = stopForeign(run)
	if not okStop then
		state.linked = false
		return false, whyStop
	end
	if not swap then
		state.prior = snapshotFd()
	end
	state.linked = true
	local fd, err = loadShared((run and run.options) or {})
	if not fd then
		restoreFd(state.prior)
		state.linked = false
		return false, err
	end
	putFd(fd)
	putHat(fd)
	return true
end

function Provider.start(run)
	state.mode = "alone"
	state.api = nil
	state.best = false
	local okStop, whyStop = stopForeign(run)
	if not okStop then
		return false, whyStop
	end
	state.prior = snapshotFd()
	state.linked = true
	local fd, err = loadShared((run and run.options) or {})
	if not fd then
		restoreFd(state.prior)
		state.linked = false
		return false, err
	end
	putFd(fd)
	if isOn(fd) then
		pcall(fd.stopreanimate)
		if not waitUntil(function()
			return not isOn(fd)
		end, 4) then
			return false, "another FDless is still running"
		end
	end
	local api = fd.reanimate()
	if type(api) ~= "table" then
		return false, "FDless could not start"
	end
	state.api = api
	local okMode, errMode = pcall(Provider.installDefaultMode, api)
	if not okMode and run and run.notify then
		run.notify("FDless", "Couldn't set the walking pose: " .. firstLine(errMode), "warn", 4)
	end
	return true
end

function Provider.isRunning()
	local fd = currentFd()
	if fd and isOn(fd) then
		return state.api ~= nil
	end
	return false
end

function Provider.stop()
	pcall(Provider.undrive)
	if not state.linked then
		state.api = nil
		state.best = false
		return true
	end
	pcall(Provider.handback)
	local fd = currentFd()
	if fd and isOn(fd) then
		pcall(fd.stopreanimate)
		waitUntil(function()
			return not isOn(fd)
		end, 5)
	end
	state.api = nil
	state.best = false
	return true
end

function Provider.reset()
	pcall(Provider.undrive)
	if ctx and state.linked then
		restoreFd(state.prior)
	end
	if ctx then
		putHat(nil)
	end
	if state.fd ~= state.shared then
		state.fd = nil
	end
	state.linked = false
	state.prior = nil
	state.api = nil
	state.mode = nil
	state.best = false
	state.lastDefault = nil
	state.takeover = false
	state.hip = 0
end

function Provider.forget()
	Provider.reset()
	state.fd = nil
	state.shared = nil
	state.loadedOpts = nil
end

return Provider
