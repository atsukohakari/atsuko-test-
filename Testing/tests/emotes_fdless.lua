local World = loadmodule("Testing/mocks/rbx_world.lua")
local env = World.install({})
local E = loadmodule("Hub/Emotes.lua")
local Provider = loadmodule("Reanimation/providers/fdless.lua")

local function near(a, b, eps)
	return math.abs(a - b) <= (eps or 1e-3)
end

local function pose(torsoY, rightY, leftY)
	return {
		CFrame.new(0, torsoY, 0),
		CFrame.new(0, 1.5, 0),
		CFrame.new(1.5, 0, 0),
		CFrame.new(-1.5, 0, 0),
		CFrame.new(0.5, rightY or -2, 0),
		CFrame.new(-0.5, leftY or -2, 0),
	}
end

T.section("emotes_fdless: the feet stay on the ground")
do
	T.eq(E.version >= 2, true, "the emotes library is version 2 or newer")
	T.eq(E.feetLift(pose(0), 3), 0, "standing: nothing to fix")
	local p = pose(0)
	T.eq(E.feetDown(p, 3), 0, "standing: the pose is left alone")
	T.ok(near(p[1].Position.Y, 0), "standing: torso unchanged")

	local up = pose(0.4)
	T.ok(near(E.feetLift(up, 3), 0.4), "both feet 0.4 up is seen as a lift of 0.4")
	E.resetFeet()
	T.ok(near(E.feetDown(up, 3), 0.4), "feetDown pulls it down by 0.4")
	T.ok(near(up[1].Position.Y, 0), "and the feet touch the floor again")

	local kick = pose(0, -2, -1.2)
	T.eq(E.feetLift(kick, 3), 0, "one foot on the floor is fine, a kick is not pulled down")

	local crouch = pose(-1, -2, -2)
	T.eq(E.feetLift(crouch, 3), 0, "a crouch below the floor is never pushed up")
	E.resetFeet()
	E.feetDown(crouch, 3)
	T.ok(near(crouch[1].Position.Y, -1), "the crouch keeps its depth")

	local tall = pose(0)
	T.ok(near(E.feetLift(tall, 5), 2), "with a hip height of 5 the feet are 2 above the floor")
	E.resetFeet()
	E.feetDown(tall, 5)
	T.ok(near(tall[1].Position.Y, -2), "and they are put on the floor")

	T.eq(E.feetLift(pose(13), 3), nil, "a lift over 12 studs is a move of its own, not a float")
	T.eq(E.feetLift({ CFrame.new() }, 3), nil, "missing legs are skipped")
	T.eq(E.feetLift(nil, 3), nil, "no pose is skipped")

	E.resetFeet()
	local a = pose(0.4)
	E.feetDown(a, 3, 1 / 60)
	T.ok(near(a[1].Position.Y, 0), "first frame: pinned")
	local b = pose(20)
	local off = E.feetDown(b, 3, 1 / 60)
	T.ok(off > 0.25 and off < 0.4, "a jump the pin skips blends out instead of snapping (" .. tostring(off) .. ")")
	for _ = 1, 120 do
		E.feetDown(pose(20), 3, 1 / 60)
	end
	T.ok(E.feetDown(pose(20), 3, 1 / 60) < 1e-3, "after two seconds the pin is fully off")
end

local function fakeDance(name, update)
	local d = { Name = name, ModuleType = "DANCE", Assets = {} }
	d.Init = function() end
	d.Update = update
	d.Destroy = function() end
	return d
end

T.section("emotes_fdless: the shared step pins the feet when the host gives a hip height")
do
	local root = CFrame.new(10, 3, 20)
	local host = {
		name = "pin test",
		rootCF = function()
			return root
		end,
		moveRoot = function()
			return false
		end,
		canEmote = function()
			return true
		end,
		hipHeight = function()
			return 3
		end,
	}
	E.attach(host)
	local lifted = fakeDance("Lift", function(dt, fig)
		fig.HumanoidRootPart.RootJoint.Transform = CFrame.new(0, 0.5, 0)
	end)
	T.eq(E.play(lifted), true, "the dance starts")
	E.setGrounded(true)
	local got = E.step(1 / 30)
	T.ok(got ~= nil, "a pose comes back")
	T.ok(got and near(got[1].Position.Y, 0), "the half stud lift is taken out (" .. tostring(got and got[1].Position.Y) .. ")")
	E.setGrounded(false)
	got = E.step(1 / 30)
	T.ok(got and near(got[1].Position.Y, 0.5), "with the setting off the dance keeps its lift")
	E.setGrounded(true)
	host.hipHeight = nil
	got = E.step(1 / 30)
	T.ok(got and near(got[1].Position.Y, 0.5), "a host without a hip height is left as it was")
	E.stop()
	E.detach(host)
	T.eq(E.currentHost(), nil, "detached")
end

local api = nil
local function makeApi()
	local a = { cframes = {}, joints = {}, modes = {}, characters = {}, hip = 0, refreshed = 0 }
	local rootPart = { Name = "HumanoidRootPart" }
	a.rootPart = rootPart
	a.cframes[rootPart] = CFrame.new(0, 3, 0)
	local REST = {
		RootJoint = { CFrame.new(), CFrame.new() },
		Neck = { CFrame.new(0, 1, 0), CFrame.new(0, -0.5, 0) },
		["Right Shoulder"] = { CFrame.new(1, 0.5, 0), CFrame.new(-0.5, 0.5, 0) },
		["Left Shoulder"] = { CFrame.new(-1, 0.5, 0), CFrame.new(0.5, 0.5, 0) },
		["Right Hip"] = { CFrame.new(1, -1, 0), CFrame.new(0.5, 1, 0) },
		["Left Hip"] = { CFrame.new(-1, -1, 0), CFrame.new(-0.5, 1, 0) },
	}
	for name, cc in pairs(REST) do
		a.joints[name] = { Name = name, C0 = cc[1], C1 = cc[2] }
	end
	a.addmode = function(key, mode)
		a.modes[key] = mode
	end
	a.getPart = function(name)
		for part in pairs(a.cframes) do
			if part.Name == name then
				return part
			end
		end
		return nil
	end
	a.getJoint = function(name)
		return a.joints[name] or { C0 = CFrame.new(), C1 = CFrame.new() }
	end
	a.forceMode = function(m)
		a.forced = m
	end
	a.releaseMode = function()
		a.forced = nil
	end
	a.isForced = function()
		return a.forced ~= nil
	end
	a.setCfr = function(cf)
		a.cframes[rootPart] = cf
	end
	a.setHipHeight = function(n)
		a.hip = n
	end
	a.refreshrayfilter = function()
		a.refreshed += 1
	end
	return a
end

local running = false
_G.FAKE_FD = {
	reanimate = function()
		running = true
		api = makeApi()
		return api
	end,
	stopreanimate = function()
		running = false
	end,
	isReanimated = function()
		return running
	end,
}
local fakeFile = "return _G.FAKE_FD\n" .. string.rep("-- padding so the provider takes it as a whole file\n", 6)

local toasts = {}
Provider.init({
	G = _G,
	genv = _G,
	X = { loadstring = true },
	loadFile = function()
		return fakeFile
	end,
	loadstring = loadstring,
	notify = function(title, text)
		toasts[#toasts + 1] = title .. ": " .. text
	end,
	wait = task.wait,
	now = os.clock,
	spawn = task.spawn,
	delay = task.delay,
})
Provider.onChanged = function() end

local function opts()
	local out = {}
	for _, def in ipairs(Provider.settings) do
		out[def.key] = def.default
	end
	return out
end

T.section("emotes_fdless: FDless has an emote driver")
do
	T.eq(type(Provider.driver), "function", "the provider has a driver")
	T.eq(type(Provider.undrive), "function", "and a way to let go")
	local ok, why = Provider.driver(E)
	T.eq(ok, false, "no driver while FDless is not running")
	T.eq(why, "FDless is not running")
	T.eq(Provider.start({ options = opts(), notify = function() end }), true, "FDless starts")
	T.eq(Provider.isRunning(), true)
	T.eq(select(1, Provider.driver({})), false, "a table that is not the emotes library is refused")
	T.eq(Provider.driver(E), true, "the driver takes the emotes library")
	local host = Provider.emoteHost()
	T.ok(host ~= nil, "a host is made")
	T.eq(E.currentHost(), host, "the emotes library dances on FDless now")
	T.eq(E.hostName(), "FDless")
	T.eq(E.canEmote(), true, "and it may dance")
	T.eq(Provider.driver(E), true, "calling the driver again is fine")
	T.eq(E.currentHost(), host, "and keeps the same host")
	T.ok(near(host.rootCF().Position.Y, 3), "the host reads the FDless root")
	T.eq(host.hipHeight(), 3, "the normal hip height is 3")
	api.setHipHeight(2)
	T.eq(host.hipHeight(), 5, "a script that raises the hip height is followed")
	api.setHipHeight(0)
	T.eq(host.moveRoot(CFrame.new(4, 3, 0)), false, "no ground under the spot: the root stays")
	T.ok(near(api.cframes[api.rootPart].Position.X, 0), "the root did not move")
	local probe = Instance.new("Model")
	host.ignore(probe, true)
	local listed = false
	for _, v in pairs(api.characters) do
		if v == probe then
			listed = true
		end
	end
	T.eq(listed, true, "the dance figure is kept out of the FDless ground check")
	host.ignore(nil, false)
	listed = false
	for _, v in pairs(api.characters) do
		if v == probe then
			listed = true
		end
	end
	T.eq(listed, false, "and taken back out when the dance ends")
end

T.section("emotes_fdless: a dance takes over FDless and hands it back")
do
	local danced = 0
	local arm = fakeDance("Wave", function(dt, fig)
		danced += 1
		fig.Torso["Right Shoulder"].Transform = CFrame.new(0, 0.25, 0)
	end)
	T.eq(api.forced, nil, "nothing is forced before the dance")
	T.eq(E.play(arm), true, "the dance starts on FDless")
	T.ok(api.forced ~= nil, "FDless is taken over")
	local mode = api.forced
	T.ok(type(mode.idle) == "function" and type(mode.walk) == "function" and type(mode.jump) == "function" and type(mode.fall) == "function", "with all four poses")
	task.wait(1 / 30)
	mode.idle()
	T.ok(danced >= 1, "the FDless pose steps the dance")
	local c0 = api.joints["Right Shoulder"].C0.Position
	T.ok(near(c0.X, 1) and near(c0.Y, 0.75), "the arm joint gets the dance pose (" .. tostring(c0) .. ")")
	local hip = api.joints["Right Hip"].C0.Position
	T.ok(near(hip.X, 1) and near(hip.Y, -1), "the legs keep their rest pose")
	task.wait(1 / 30)
	mode.walk()
	task.wait(1 / 30)
	mode.jump()
	task.wait(1 / 30)
	mode.fall()
	T.ok(danced >= 4, "walking, jumping and falling keep the dance going")
	E.stop()
	T.eq(api.forced, nil, "stopping the dance hands FDless back")
end

T.section("emotes_fdless: the script that runs keeps going under the dance")
do
	local frames, glued = 0, nil
	local titanHat = { Name = "AccessoryWeld", C0 = CFrame.new(), C1 = CFrame.new() }
	local function scriptFrame()
		frames += 1
		api.joints["Right Shoulder"].C0 = CFrame.new(9, 9, 9)
		titanHat.C1 = CFrame.new(0, 20 + frames, 5)
		glued = titanHat.C1
	end
	api.addmode("default", { idle = scriptFrame, walk = scriptFrame, jump = scriptFrame, fall = scriptFrame })
	local wave = fakeDance("Wave again", function(dt, fig)
		fig.Torso["Right Shoulder"].Transform = CFrame.new(0, 0.25, 0)
	end)
	T.eq(E.play(wave), true)
	local mode = api.forced
	T.ok(mode ~= nil, "FDless is taken over")
	task.wait(1 / 30)
	mode.idle()
	task.wait(1 / 30)
	mode.walk()
	T.eq(frames, 2, "the script's own frame still runs every frame, so its watchdog never thinks FDless stopped")
	T.ok(glued ~= nil and near(glued.Position.Y, 22), "and what it moves that isn't your body (InternalWar's titan) keeps moving")
	local c0 = api.joints["Right Shoulder"].C0.Position
	T.ok(near(c0.X, 1) and near(c0.Y, 0.75), "while your body dances: the dance goes on top of the script's pose (" .. tostring(c0) .. ")")
	E.stop()
	T.eq(api.forced, nil, "handed back")
	api.addmode("default", nil)
end

T.section("emotes_fdless: a dance that floats is pinned on FDless too")
do
	local float = fakeDance("Float", function(dt, fig)
		fig.HumanoidRootPart.RootJoint.Transform = CFrame.new(0, 0.6, 0)
	end)
	E.setGrounded(true)
	T.eq(E.play(float), true)
	task.wait(1 / 30)
	api.forced.idle()
	local y = api.joints.RootJoint.C0.Position.Y
	T.ok(near(y, 0), "the root joint keeps the feet on the floor (" .. tostring(y) .. ")")
	api.setHipHeight(1)
	task.wait(1 / 30)
	api.forced.idle()
	y = api.joints.RootJoint.C0.Position.Y
	T.ok(near(y, -1), "with a raised hip height the body still reaches the floor (" .. tostring(y) .. ")")
	api.setHipHeight(0)
	E.stop()
end

T.section("emotes_fdless: scripts with their own dances keep them")
do
	local own = { name = "Own host", rootCF = function()
		return CFrame.new()
	end, canEmote = function()
		return true
	end }
	E.attach(own)
	T.eq(Provider.driver(E), true, "the driver does not fight a script's own host")
	T.eq(E.currentHost(), own, "the script's host stays")
	E.detach(own)
	T.eq(E.currentHost(), nil, "the script let go")
	env.run(1.5)
	T.eq(E.currentHost(), Provider.emoteHost(), "FDless picks the dances back up by itself")
end

T.section("emotes_fdless: while dancing the gun goes on the wrist and the sword on the back")
do
	local W = loadmodule("Hub/modules/emoteweapons.lua")
	local V = {}
	for _, n in ipairs({ "Torso", "Head", "Right Arm", "Left Arm" }) do
		V[n] = { Name = n }
		api.cframes[V[n]] = CFrame.new()
	end
	local function hat(name, mesh, size, part1, c1)
		local acc = Instance.new("Accessory")
		acc.Name = name
		local handle = Instance.new("Part")
		handle.Name = "Handle"
		handle.Size = size
		handle.Parent = acc
		local e = { m = "rbxassetid://" .. mesh, t = "", p = handle }
		api.cframes[e] = CFrame.new()
		local j = { Part0 = e, Part1 = part1, C0 = CFrame.new(0, 0.6, 0), C1 = c1 }
		e.j = j
		return e, j
	end
	local _, gunJ = hat("Blaster", "111", Vector3.new(0.4, 0.8, 2.4), V.Head, CFrame.new(0, 0.6, 0))
	local _, swordJ = hat("Katana", "222", Vector3.new(0.2, 4, 0.6), V.Head, CFrame.new(0, 0.6, 0))
	local _, armJ = hat("Arm", "333", Vector3.new(1, 2, 1), V["Right Arm"], CFrame.new())
	api.getPartJoint = function(e)
		return rawget(e, "j")
	end
	_G.AtsukoEmoteWeapons = {
		kind = function(_, _, name)
			if name == "Blaster" or name == "Arm" then
				return "gun"
			elseif name == "Katana" then
				return "sword"
			end
			return nil
		end,
		place = W.place,
	}
	local d = fakeDance("Guns out", function() end)
	T.eq(E.play(d), true)
	task.wait(1 / 30)
	api.forced.idle()
	T.eq(gunJ.Part1, V["Right Arm"], "the gun goes on the right arm")
	local _, gunCF = W.place("gun", Vector3.new(0.4, 0.8, 2.4))
	T.ok((gunJ.C1.Position - gunCF.Position).Magnitude < 1e-3, "at the wrist")
	T.eq(swordJ.Part1, V.Torso, "the sword goes on the torso")
	T.ok(swordJ.C1.Position.Z > 0.5, "on the back")
	T.eq(armJ.Part1, V["Right Arm"], "a hat that is an arm stays an arm")
	T.eq(armJ.C1, CFrame.new(), "and keeps its spot")
	gunJ.Part1 = V.Head
	task.wait(1 / 30)
	api.forced.walk()
	T.eq(gunJ.Part1, V["Right Arm"], "a script that moves the gun is overruled every frame of the dance")
	E.stop()
	T.eq(gunJ.Part1, V.Head, "stopping the dance puts the gun back")
	T.eq(gunJ.C1, CFrame.new(0, 0.6, 0))
	T.eq(swordJ.Part1, V.Head, "and the sword")
	_G.AtsukoEmoteWeapons = nil
	T.eq(E.play(d), true)
	task.wait(1 / 30)
	api.forced.idle()
	T.eq(swordJ.Part1, V.Head, "with no hub to say what a weapon is, nothing moves")
	E.stop()
	api.getPartJoint = nil
end

T.section("emotes_fdless: stopping FDless lets the dances go")
do
	local d = fakeDance("Spin", function() end)
	E.play(d)
	T.ok(api.forced ~= nil, "dancing")
	Provider.stop()
	T.eq(Provider.isRunning(), false, "FDless stopped")
	T.eq(E.currentHost(), nil, "the emotes library is back on Script Reanimate")
	T.eq((E.playing()), nil, "and the dance ended")
	T.eq(api.forced, nil, "FDless was handed back first")
	T.eq(select(1, E.canEmote()), false, "with nothing reanimated it can't dance")
	Provider.reset()
	T.eq(Provider.start({ options = opts(), notify = function() end }), true, "FDless starts again")
	T.eq(Provider.driver(E), true)
	T.eq(E.currentHost(), Provider.emoteHost(), "and dances again")
	_G.FAKE_FD.stopreanimate()
	running = false
	Provider.undrive(E)
	T.eq(E.currentHost(), nil, "undrive lets go")
	T.eq(Provider.undrive({}), false, "undrive with another library does nothing")
	Provider.reset()
end
