local TITLE = "FakeVR"
local genv = (typeof(getgenv) == "function" and getgenv()) or _G
local HUB = (type(AtsukoHub) == "table" and AtsukoHub) or (type(genv.AtsukoHub) == "table" and genv.AtsukoHub) or nil

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local HttpService = game:GetService("HttpService")
local VRService = game:GetService("VRService")
local lp = Players.LocalPlayer

local V3, CF, ANG = Vector3.new, CFrame.new, CFrame.Angles
local ZERO, UP = Vector3.zero, Vector3.yAxis
local CFI = CFrame.identity
local PI = math.pi
local rad, exp, sqrt, sin, cos, abs = math.rad, math.exp, math.sqrt, math.sin, math.cos, math.abs
local min, max, clamp, floor = math.min, math.max, math.clamp, math.floor

local function say(text, kind, secs)
	local h = HUB
	if type(h) == "table" and type(h.Notify) == "function" and pcall(h.Notify, TITLE, text, kind or "info", secs or 3) then
		return
	end
	local f = genv.AtsukoNotify
	if type(f) == "function" and pcall(f, TITLE, text, kind or "info", secs or 3) then
		return
	end
	warn("[" .. TITLE .. "] " .. tostring(text))
end

local FILE = "FakeVR_Settings.json"
local CFG_VERSION = 3
local CFG = {
	Version = CFG_VERSION,
	Legs = "arms",
	FirstPerson = true,
	PullAssist = true,
	ThrowPower = 3,
	ThrowHeadHats = false,
	FlySpeed = 50,
	WalkSpeed = 16,
	SprintSpeed = 26,
	Smoothness = 0.5,
	ArmUpDown = 75,
	ArmSide = 45,
	ArmReach = 1,
	TouchHands = true,
	PadSize = 1,
	Markers = true,
}
local LIMITS = { ThrowPower = { 0.5, 6 }, FlySpeed = { 10, 200 }, WalkSpeed = { 4, 60 }, SprintSpeed = { 8, 100 }, Smoothness = { 0.1, 1 }, ArmUpDown = { 15, 90 }, ArmSide = { 0, 90 }, ArmReach = { 0.5, 1.1 }, PadSize = { 0.6, 1.4 } }
local LEG_MODES = { arms = "arms", walk = "legs", hide = "hidden" }
local LEG_ORDER = { "arms", "walk", "hide" }

local function cleanCfg()
	for key, range in pairs(LIMITS) do
		local n = tonumber(CFG[key])
		if not n or n ~= n then
			n = range[1]
		end
		CFG[key] = clamp(n, range[1], range[2])
	end
	if not LEG_MODES[CFG.Legs] then
		CFG.Legs = "arms"
	end
	CFG.Version = CFG_VERSION
end

local function loadCfg()
	if isfile and readfile then
		local ok, data = pcall(function()
			if isfile(FILE) then
				return HttpService:JSONDecode(readfile(FILE))
			end
			return nil
		end)
		if ok and type(data) == "table" and data.Version == CFG_VERSION then
			for key, value in pairs(data) do
				if CFG[key] ~= nil and type(value) == type(CFG[key]) then
					CFG[key] = value
				end
			end
		end
	end
	cleanCfg()
end

local function saveCfg()
	if writefile then
		pcall(writefile, FILE, HttpService:JSONEncode(CFG))
	end
end

loadCfg()

local ALIGNS = {
	{ PartName = "Left Arm", meshid = "90653511854016", textureid = "72193962238808", C0 = CFI },
	{ PartName = "Right Arm", meshid = "77814141389117", textureid = "86835481875891", C0 = CFI },
	{ PartName = "Left Arm", meshid = "137702817952968", textureid = "135650240593878", C0 = ANG(0, 0, rad(90)) },
	{ PartName = "Right Arm", meshid = "137702817952968", textureid = "135650240593878", C0 = ANG(0, 0, rad(90)) },
	{ PartName = "Left Arm", meshid = "137702817952968", textureid = "73798034827573", C0 = ANG(0, 0, rad(90)) },
	{ PartName = "Right Arm", meshid = "137702817952968", textureid = "73798034827573", C0 = ANG(0, 0, rad(90)) },
	{ PartName = "Right Arm", meshid = "3030546036", textureid = "3443321249", C0 = ANG(rad(45), rad(89.9355), rad(45)) },
	{ PartName = "Left Arm", meshid = "3030546036", textureid = "3360974849", C0 = ANG(rad(45), rad(-89.9355), rad(-45)) },
}

local function loadLumen()
	local R = genv.LumenReanim
	if type(R) == "table" and type(R.rig) == "function" then
		return R
	end
	local base = type(genv.AtsukoHubRaw) == "string" and genv.AtsukoHubRaw or "https://raw.githubusercontent.com/atsukohakari/atsuko-test-/main/"
	local ok, src = pcall(function()
		if type(genv.AtsukoHubRead) == "function" then
			local got = genv.AtsukoHubRead("Hub/Reanimate.lua")
			if got or genv.AtsukoHubLocal then
				return got
			end
		end
		return game:HttpGet(base .. "Hub/Reanimate.lua")
	end)
	local fn = ok and type(src) == "string" and loadstring(src, "=Reanimate")
	if fn then
		local ok2, r = pcall(fn)
		if ok2 and type(r) == "table" and type(r.rig) == "function" then
			return r
		end
	end
	return nil
end

local hubFd = genv.AtsukoHatFd
local onHub = type(hubFd) == "table" and type(hubFd.reanimate) == "function" and type(hubFd.stopreanimate) == "function"
local Lumen = nil
if not onHub then
	Lumen = loadLumen()
	if not Lumen then
		say("Pick Script Reanimate or FDless on the Hat tab first", "error", 5)
		return
	end
end

local aligns = {}
for _, a in ipairs(ALIGNS) do
	aligns[#aligns + 1] = a
end
local rig
if onHub then
	genv.AtsukoScriptAligns = aligns
	rig = hubFd
else
	rig = Lumen.rig({ aligns = aligns })
end

local okFd, fd = pcall(rig.reanimate)
if not okFd or type(fd) ~= "table" or type(fd.cframes) ~= "table" or type(fd.getJoint) ~= "function" then
	say("Couldn't reanimate: " .. tostring(okFd and "the reanimation gave no body" or fd), "error", 6)
	return
end

local live = (not onHub) and Lumen.current() or nil
local function reanimOn()
	if onHub then
		local ok, isOn = pcall(hubFd.isReanimated)
		return ok and isOn and true or false
	end
	return Lumen.current() == live and live ~= nil
end
do
	local deadline = os.clock() + 10
	while reanimOn() and live and type(live.isReady) == "function" and not live.isReady() and os.clock() < deadline do
		task.wait()
	end
	if not reanimOn() then
		say("The reanimation stopped", "error", 4)
		return
	end
	if not onHub then
		live = Lumen.current() or live
	end
end

local alive = true
local conns = {}
local function on(signal, fn)
	local c = signal:Connect(fn)
	conns[#conns + 1] = c
	return c
end

local NAMES = { "HumanoidRootPart", "Torso", "Head", "Right Arm", "Left Arm", "Right Leg", "Left Leg" }
local JOINTS = { "RootJoint", "Neck", "Right Shoulder", "Left Shoulder", "Right Hip", "Left Hip" }
local vp, rigSet, nameOf = {}, {}, {}
local J, J0 = {}, {}

local function refreshParts()
	for _, n in ipairs(NAMES) do
		local p = fd.getPart(n)
		if type(p) == "table" then
			vp[n] = p
			rigSet[p] = true
			nameOf[p] = n
		end
	end
	for _, n in ipairs(JOINTS) do
		local j = fd.getJoint(n)
		if type(j) == "table" and J[n] ~= j then
			J[n] = j
			J0[n] = { C0 = rawget(j, "C0"), C1 = rawget(j, "C1") }
		end
	end
end
refreshParts()
if not vp.HumanoidRootPart or not vp.Torso then
	say("The reanimation has no body to move", "error", 5)
	return
end

local REGION = {
	HairAttachment = "Head", HatAttachment = "Head", FaceFrontAttachment = "Head", FaceCenterAttachment = "Head",
	NeckAttachment = "Torso", BodyFrontAttachment = "Torso", BodyBackAttachment = "Torso", LeftCollarAttachment = "Torso",
	RightCollarAttachment = "Torso", WaistFrontAttachment = "Torso", WaistCenterAttachment = "Torso", WaistBackAttachment = "Torso",
	RightShoulderAttachment = "Right Arm", RightGripAttachment = "Right Arm", LeftShoulderAttachment = "Left Arm", LeftGripAttachment = "Left Arm",
	RightFootAttachment = "Right Leg", LeftFootAttachment = "Left Leg",
}

local items, order = {}, {}
local hasHat = {}

local function alignMatch(limb, mesh, tex, accName)
	local function test(list)
		if type(list) ~= "table" then
			return false
		end
		for _, a in ipairs(list) do
			if type(a) == "table" and a.PartName == limb then
				local m, t, n = a.meshid, a.textureid, a.AccessoryName
				local any = (type(m) == "string" and m ~= "") or (type(t) == "string" and t ~= "") or (type(n) == "string" and n ~= "")
				if any then
					local okM = type(m) ~= "string" or m == "" or (type(mesh) == "string" and string.find(mesh, m, 1, true) ~= nil)
					local okT = type(t) ~= "string" or t == "" or (type(tex) == "string" and string.find(tex, t, 1, true) ~= nil)
					local okN = type(n) ~= "string" or n == "" or n == accName
					if okM and okT and okN then
						return true
					end
				end
			end
		end
		return false
	end
	return test(genv.AtsukoAligns) or test(ALIGNS)
end

local function classify(it)
	local h = it.handle
	if not h then
		return
	end
	local acc = h.Parent
	local attName = nil
	for _, c in ipairs(h:GetChildren()) do
		if c:IsA("Attachment") and REGION[c.Name] then
			attName = c.Name
			break
		end
	end
	local accType = nil
	pcall(function()
		if acc and acc:IsA("Accessory") then
			accType = acc.AccessoryType.Name
		end
	end)
	local mesh, tex = rawget(it.e, "m"), rawget(it.e, "t")
	local region = attName and REGION[attName] or nil
	it.name = acc and acc.Name or h.Name
	it.hair = accType == "Hair" or attName == "HairAttachment"
	it.headWear = region == "Head" or accType == "Hat" or accType == "Face"
	it.rig = (it.homeLimb ~= nil and region ~= nil and it.homeLimb ~= region) or alignMatch(it.homeLimb, mesh, tex, it.name)
	it.kind = accType or (region and (region .. " wear")) or "Accessory"
	local size = h.Size
	it.radius = clamp(min(size.X, size.Y, size.Z) * 0.5, 0.2, 1.2)
	it.classified = true
end

local function throwable(it)
	if not it.classified or it.rig or it.hair then
		return false
	end
	if it.headWear and not CFG.ThrowHeadHats then
		return false
	end
	return it.handle ~= nil
end

local function jointPart(j, key)
	local ok, v = pcall(rawget, j, key)
	if ok then
		return v
	end
	return nil
end

local function scan()
	refreshParts()
	local seen = {}
	for _, j in ipairs(fd.joints or {}) do
		if type(j) == "table" then
			local e = jointPart(j, "Part0")
			if type(e) == "table" and not rigSet[e] and (rawget(e, "m") ~= nil or rawget(e, "p") ~= nil) then
				seen[j] = true
				local it = items[j]
				if not it then
					local p1 = jointPart(j, "Part1")
					it = { j = j, e = e, state = "home", homeLimb = p1 and nameOf[p1] or nil, orig = { Part1 = p1, C0 = rawget(j, "C0"), C1 = rawget(j, "C1") } }
					items[j] = it
					order[#order + 1] = it
				end
				local h = rawget(e, "p")
				if typeof(h) ~= "Instance" or not h.Parent then
					h = nil
				end
				if h ~= it.handle then
					it.handle = h
					it.classified = false
				end
				if it.handle and not it.classified then
					pcall(classify, it)
				end
			end
		end
	end
	for i = #order, 1, -1 do
		local it = order[i]
		if not seen[it.j] then
			items[it.j] = nil
			table.remove(order, i)
		end
	end
	table.clear(hasHat)
	for _, it in ipairs(order) do
		if it.rig and it.handle and it.homeLimb then
			hasHat[it.homeLimb] = (hasHat[it.homeLimb] or 0) + 1
		end
	end
end

local function throwables()
	local out = {}
	for _, it in ipairs(order) do
		if throwable(it) then
			out[#out + 1] = it
		end
	end
	return out
end

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude
rayParams.RespectCanCollide = true
rayParams.IgnoreWater = true
local grabParams = RaycastParams.new()
grabParams.FilterType = Enum.RaycastFilterType.Include

local markerFolder = Instance.new("Folder")
markerFolder.Name = "FakeVRHands"

local function refreshFilters()
	local ex = { markerFolder }
	if lp.Character then
		ex[#ex + 1] = lp.Character
	end
	local cur = (not onHub) and Lumen.current() or nil
	if type(cur) == "table" and typeof(cur.rig) == "Instance" then
		ex[#ex + 1] = cur.rig
	end
	for _, it in ipairs(order) do
		if it.handle then
			ex[#ex + 1] = it.handle
		end
	end
	rayParams.FilterDescendantsInstances = ex
	local grabList = {}
	for _, it in ipairs(order) do
		if it.handle and throwable(it) then
			grabList[#grabList + 1] = it.handle
		end
	end
	grabParams.FilterDescendantsInstances = grabList
end

local function cast(origin, dir)
	if dir.Magnitude < 1e-4 then
		return nil
	end
	local ok, hit = pcall(Workspace.Raycast, Workspace, origin, dir, rayParams)
	return ok and hit or nil
end

local function sphereCast(origin, radius, dir)
	if dir.Magnitude < 1e-4 then
		return nil, 0
	end
	local ok, hit = pcall(function()
		return Workspace:Spherecast(origin, radius, dir, rayParams)
	end)
	if ok then
		if hit then
			return hit, hit.Distance
		end
		return nil, 0
	end
	local r = cast(origin, dir + dir.Unit * radius)
	if r then
		return r, max((r.Position - origin).Magnitude - radius, 0)
	end
	return nil, 0
end

local controls, controlsTried = nil, false
local function getControls()
	if not controlsTried then
		controlsTried = true
		pcall(function()
			local ps = lp:FindFirstChildOfClass("PlayerScripts")
			local pm = ps and ps:FindFirstChild("PlayerModule")
			if pm then
				controls = require(pm):GetControls()
			end
		end)
	end
	return controls
end

local function typing()
	local ok, box = pcall(UIS.GetFocusedTextBox, UIS)
	return ok and box ~= nil
end

local function moveVector()
	local v = ZERO
	local c = getControls()
	if c then
		local ok, got = pcall(function()
			return c:GetMoveVector()
		end)
		if ok and typeof(got) == "Vector3" then
			v = got
		end
	end
	if v.Magnitude < 0.01 and not typing() then
		local K = Enum.KeyCode
		local x = (UIS:IsKeyDown(K.D) and 1 or 0) - (UIS:IsKeyDown(K.A) and 1 or 0)
		local z = (UIS:IsKeyDown(K.S) and 1 or 0) - (UIS:IsKeyDown(K.W) and 1 or 0)
		v = V3(x, 0, z)
	end
	return v
end

local SIDES = { "Left", "Right" }
local GRIP = CF(0, -1.15, 0)
local D = { ARM_LEN = 2, LEG_LEN = 2, SHOULDER_DROP = 0.5, REACH_ONE = 1.5, REACH_TWO = 3.95, REACH_VR = 2.4, STANCE = 0.52, CROUCH_DEPTH = 1.05, GAIT_SPEED = 2.5, PULL_RANGE = 40 }

local function newHand(side)
	return {
		side = side,
		sign = side == "Right" and 1 or -1,
		limb = side .. " Arm",
		upper = side .. " Leg",
		grip = false,
		screen = nil,
		pos = nil,
		vel = ZERO,
		rot = CFI,
		hist = {},
		held = nil,
		forearm = CFI,
		pivot = nil,
		reachMax = D.REACH_ONE,
		aim = nil,
	}
end
local hands = { Left = newHand("Left"), Right = newHand("Right") }

local function newFoot(side)
	return { side = side, sign = side == "Right" and 1 or -1, pos = nil, ground = nil, lift = 0, yaw = nil, step = nil, idle = 0, air = true, dir = nil, home = nil, lastEnd = nil }
end
local feet = { Left = newFoot("Left"), Right = newFoot("Right") }
local legPend = { Left = { a = 0, w = 0 }, Right = { a = 0, w = 0 } }

local fly = { on = false, vel = ZERO, up = false, down = false, vrAxis = 0 }
local body = {
	yaw = nil,
	lastRoot = nil,
	vel = ZERO,
	lean = Vector2.zero,
	crouch = 0,
	crouchHold = false,
	crouchToggle = false,
	crouchWant = false,
	sprintHold = false,
	sprintToggle = false,
	sprint = false,
	dip = 0,
	dipVel = 0,
	wasGround = true,
	fallSpeed = 0,
	turning = false,
	gait = 0,
	phase = 0,
	speed = 0,
	onGround = true,
}
local applied = { speed = nil, hip = 0, hipSet = false, blocker = false }
local lastErr = nil
local scanClock, filterClock = 0, 0
local prevZoom = nil
local origCameraMode = lp.CameraMode
local firstPersonApplied = false
local syncUi = function() end

local function vrOn()
	local ok, v = pcall(function()
		return UIS.VREnabled
	end)
	return ok and v == true
end

local function isFirstPersonNow(cam)
	if vrOn() then
		return true
	end
	if onHub and type(fd.isFirstPerson) == "function" then
		local ok, v = pcall(fd.isFirstPerson)
		if ok then
			return v == true
		end
	end
	return (cam.CFrame.Position - cam.Focus.Position).Magnitude < 1.2
end

local function applyView()
	if vrOn() then
		return
	end
	if onHub and type(fd.setCamZoom) == "function" then
		if CFG.FirstPerson then
			if prevZoom == nil and type(fd.getCamZoom) == "function" then
				local ok, z = pcall(fd.getCamZoom)
				prevZoom = ok and tonumber(z) or -12
			end
			pcall(fd.setCamZoom, 0)
		else
			local z = prevZoom
			if z == nil or z > -2 then
				z = -12
			end
			pcall(fd.setCamZoom, z)
		end
	else
		pcall(function()
			if CFG.FirstPerson then
				lp.CameraMode = Enum.CameraMode.LockFirstPerson
			else
				lp.CameraMode = origCameraMode == Enum.CameraMode.LockFirstPerson and Enum.CameraMode.Classic or origCameraMode
				if type(fd.setCamZoom) == "function" then
					fd.setCamZoom(-12)
				end
			end
		end)
	end
	firstPersonApplied = CFG.FirstPerson
end

local function restoreView()
	if onHub and type(fd.setCamZoom) == "function" then
		if prevZoom ~= nil then
			pcall(fd.setCamZoom, prevZoom)
		end
	else
		pcall(function()
			lp.CameraMode = origCameraMode
		end)
	end
end

local function flatYaw(look)
	local f = V3(look.X, 0, look.Z)
	if f.Magnitude < 1e-3 then
		return nil
	end
	f = f.Unit
	return math.atan2(-f.X, -f.Z)
end

local function angleDiff(a, b)
	return (b - a + PI) % (2 * PI) - PI
end

local function limbBetween(top, bottom, forward)
	local up = top - bottom
	local len = up.Magnitude
	if len < 1e-3 then
		up = UP
	else
		up = up / len
	end
	local back = -forward
	back = back - up * back:Dot(up)
	if back.Magnitude < 1e-3 then
		back = up:Cross(Vector3.xAxis)
		if back.Magnitude < 1e-3 then
			back = up:Cross(Vector3.zAxis)
		end
	end
	back = back.Unit
	local right = up:Cross(back)
	return CFrame.fromMatrix((top + bottom) * 0.5, right, up, back)
end

local function facing(rot, axis)
	local f, u = rot.LookVector, rot.UpVector
	local len = axis.Magnitude
	if len < 1e-3 then
		return f
	end
	local w = clamp((abs(f:Dot(axis / len)) - 0.6) / 0.3, 0, 1)
	local v = f * (1 - w) + u * w
	return v.Magnitude > 1e-3 and v.Unit or f
end

local function setChild(name, parentCF, worldCF)
	local j = J[name]
	if not j then
		return
	end
	local c1 = rawget(j, "C1")
	if typeof(c1) ~= "CFrame" then
		c1 = CFI
	end
	local c0 = parentCF:Inverse() * worldCF * c1
	if c0 == c0 then
		j.C0 = c0
	end
end

local TK = {}

local function aimRay(cam, hand, point)
	if point then
		local ok, ray = pcall(cam.ScreenPointToRay, cam, point.X, point.Y)
		if ok and ray then
			return ray.Origin, ray.Direction
		end
	end
	if not hand.screen then
		local okLoc, loc = pcall(UIS.GetMouseLocation, UIS)
		if okLoc and loc then
			local ok, ray = pcall(cam.ViewportPointToRay, cam, loc.X, loc.Y)
			if ok and ray then
				return ray.Origin, ray.Direction
			end
		end
	end
	return cam.CFrame.Position, cam.CFrame.LookVector
end

local function itemCF(it)
	local c = fd.cframes[it.e]
	if typeof(c) == "CFrame" then
		return c
	end
	if it.handle then
		return it.handle.CFrame
	end
	return nil
end

local function homeCF(it)
	local p1 = it.orig.Part1
	local base = p1 and fd.cframes[p1]
	if typeof(base) ~= "CFrame" then
		return nil
	end
	local c0, c1 = it.orig.C0, it.orig.C1
	if typeof(c0) ~= "CFrame" or typeof(c1) ~= "CFrame" then
		return nil
	end
	return base * c1 * c0:Inverse()
end

local function detach(it)
	it.j.Part1 = nil
end

local function restore(it)
	local j = it.j
	j.Part1 = it.orig.Part1
	j.C0 = it.orig.C0
	j.C1 = it.orig.C1
	it.state = "home"
	it.hand = nil
	it.vel, it.ang = ZERO, ZERO
end

local function gripWorld(hand)
	return hand.forearm * GRIP
end

local function release(it)
	local hand = it.hand and hands[it.hand]
	if hand and hand.held == it then
		hand.held = nil
	end
	it.hand = nil
end

local function sendHome(it)
	release(it)
	it.state = "return"
	it.t, it.from = 0, itemCF(it)
end

local function grab(hand, it)
	if it.hand and hands[it.hand] and hands[it.hand] ~= hand then
		release(it)
	end
	if hand.held and hand.held ~= it then
		sendHome(hand.held)
	end
	local cf = itemCF(it) or gripWorld(hand)
	local rel = gripWorld(hand):ToObjectSpace(cf)
	it.hold = rel
	it.state = "held"
	it.hand = hand.side
	hand.held = it
	local j = it.j
	j.Part1 = vp[hand.limb]
	j.C1 = GRIP
	j.C0 = rel:Inverse()
end

local function summon(it, side)
	if not it or not throwable(it) then
		return false
	end
	local hand = hands[side or "Right"]
	if not hand then
		return false
	end
	if it.hand then
		release(it)
	end
	if hand.held and hand.held ~= it then
		sendHome(hand.held)
	end
	it.from = itemCF(it)
	it.t = 0
	it.state = "summon"
	it.hand = hand.side
	hand.held = it
	detach(it)
	return true
end

local function recallAll()
	local n = 0
	for _, it in ipairs(order) do
		if it.state ~= "home" then
			sendHome(it)
			n += 1
		end
	end
	return n
end

local function handVelocity(hand)
	local h = hand.hist
	if #h < 2 then
		return ZERO, ZERO
	end
	local newest = h[#h]
	local oldest = h[1]
	for i = #h - 1, 1, -1 do
		if newest.t - h[i].t >= 0.08 then
			oldest = h[i]
			break
		end
	end
	local dt = newest.t - oldest.t
	if dt < 1e-3 then
		return ZERO, ZERO
	end
	local v = (newest.p - oldest.p) / dt
	local dr = newest.r * oldest.r:Inverse()
	local axis, angle = dr:ToAxisAngle()
	local w = ZERO
	if angle == angle and axis.Magnitude > 0.5 then
		if angle > PI then
			angle -= 2 * PI
		end
		w = axis.Unit * (angle / dt)
	end
	return v, w
end

local function throwHeld(hand)
	local it = hand.held
	if not it then
		return
	end
	local cf = itemCF(it) or gripWorld(hand)
	local hv, w = handVelocity(hand)
	local carry = V3(body.vel.X, body.vel.Y * 0.5, body.vel.Z)
	local v = (hv - carry) * CFG.ThrowPower
	if hand.aim and v.Magnitude > 6 then
		local sp = v.Magnitude
		v = (v.Unit * 0.7 + hand.aim * 0.3).Unit * sp
	end
	v += carry
	if v.Magnitude > 280 then
		v = v.Unit * 280
	end
	local spin = w * 0.6
	if v.Magnitude > 8 then
		local tumble = v:Cross(UP)
		if tumble.Magnitude > 1e-3 then
			spin += tumble.Unit * min(v.Magnitude * 0.08, 14)
		end
	end
	release(it)
	detach(it)
	it.state = "free"
	it.pos = cf.Position
	it.rot = cf.Rotation
	it.vel = v
	it.ang = spin
	it.rest = 0
end

local function tossHeld(hand, flick)
	local it = hand.held
	if not it then
		return
	end
	local cf = itemCF(it) or gripWorld(hand)
	local dir = hand.aim
	if not dir or dir.Magnitude < 1e-3 then
		local cam = Workspace.CurrentCamera
		dir = cam and cam.CFrame.LookVector or V3(0, 0, -1)
	end
	dir = (dir.Unit + UP * 0.2).Unit
	local speed = (24 + 76 * clamp(flick / 1600, 0, 1)) * (CFG.ThrowPower / 3)
	local v = dir * speed + V3(body.vel.X, max(body.vel.Y, 0) * 0.5, body.vel.Z)
	release(it)
	detach(it)
	it.state = "free"
	it.pos = cf.Position
	it.rot = cf.Rotation
	it.vel = v
	local tumble = v:Cross(UP)
	it.ang = tumble.Magnitude > 1e-3 and tumble.Unit * min(speed * 0.08, 12) or ZERO
	it.rest = 0
end

local function nearestFor(hand, range)
	local gp = gripWorld(hand).Position
	local best, bestD = nil, range
	for _, it in ipairs(order) do
		if throwable(it) and it.state ~= "summon" and it.state ~= "home" and it.hand ~= hand.side then
			local cf = itemCF(it)
			if cf then
				local d = (cf.Position - gp).Magnitude - (it.radius or 0.5)
				if d < bestD then
					best, bestD = it, d
				end
			end
		end
	end
	return best
end

local function simulate(it, dt)
	if it.state == "asleep" then
		it.rest = (it.rest or 0) + dt
		if it.rest > 0.5 then
			it.rest = 0
			if not cast(it.pos, V3(0, -(it.radius + 0.35), 0)) then
				it.state = "free"
			end
		end
		fd.cframes[it.e] = CF(it.pos) * it.rot
		return
	end
	local g = tonumber(Workspace.Gravity) or 196.2
	it.vel = (it.vel + V3(0, -g * dt, 0)) * exp(-0.12 * dt)
	local move = it.vel * dt
	local r = it.radius or 0.5
	local hit, dist = sphereCast(it.pos, r, move)
	if hit then
		local n = hit.Normal
		it.pos = it.pos + move.Unit * max(dist - 0.02, 0) + n * 0.02
		local vn = n * it.vel:Dot(n)
		local vt = it.vel - vn
		if it.vel:Dot(n) < 0 then
			it.vel = vt * 0.72 - vn * 0.33
		end
		it.ang = it.ang * 0.55 + n:Cross(vt) / max(r, 0.25) * 0.2
		if it.vel.Magnitude < 2.5 and n.Y > 0.55 then
			it.state = "asleep"
			it.vel, it.ang = ZERO, ZERO
			it.rest = 0
		end
	else
		it.pos += move
	end
	local w = it.ang.Magnitude
	if w > 1e-3 then
		it.rot = CFrame.fromAxisAngle(it.ang / w, w * dt) * it.rot
		it.ang = it.ang * exp(-0.4 * dt)
	end
	fd.cframes[it.e] = CF(it.pos) * it.rot
end

local function ease(t)
	t = clamp(t, 0, 1)
	return 1 - (1 - t) ^ 3
end

local function stepItems(dt, rootPos)
	local fpdh = tonumber(Workspace.FallenPartsDestroyHeight) or -500
	for _, it in ipairs(order) do
		local st = it.state
		if st == "held" then
			local hand = hands[it.hand]
			if not hand or hand.held ~= it then
				it.state = "return"
				it.t, it.from = 0, itemCF(it)
			else
				local rel = it.hold or CFI
				local p = rel.Position
				local snug = p.Magnitude > 0.7 and p.Unit * 0.7 or p
				rel = CF(p:Lerp(snug, 1 - exp(-10 * dt))) * rel.Rotation
				it.hold = rel
				local j = it.j
				j.Part1 = vp[hand.limb]
				j.C1 = GRIP
				j.C0 = rel:Inverse()
			end
		elseif st == "summon" then
			local hand = hands[it.hand]
			it.t = (it.t or 0) + dt
			local to = hand and gripWorld(hand) or nil
			local from = it.from or to
			if not to or not from then
				it.state = "return"
				it.t = 0
			else
				local span = clamp((to.Position - from.Position).Magnitude / 60, 0.25, 0.6)
				local a = ease(it.t / span)
				fd.cframes[it.e] = from:Lerp(to, a)
				if a >= 1 then
					hand.held = nil
					grab(hand, it)
					it.hold = CFI
				end
			end
		elseif st == "free" or st == "asleep" then
			simulate(it, dt)
			local far = rootPos and (it.pos - rootPos).Magnitude > 350
			if far or it.pos.Y < fpdh + 25 then
				it.state = "return"
				it.t, it.from = 0, CF(it.pos) * it.rot
			end
		elseif st == "return" then
			it.t = (it.t or 0) + dt
			local to = homeCF(it)
			local from = it.from or to
			if not to or not from then
				restore(it)
			else
				local a = ease(it.t / 0.35)
				fd.cframes[it.e] = from:Lerp(to, a)
				if a >= 1 then
					restore(it)
				end
			end
		end
	end
end

local function stepHand(hand, target, targetRot, dt, stiff, frame)
	local P0 = hand.pivot or target
	local Rf = frame or CFI
	local goal = Rf:VectorToObjectSpace(target - P0)
	if not hand.off then
		hand.off = goal
		hand.vel = ZERO
		hand.rot = targetRot
	end
	local k = 260 * stiff
	local c = 2 * sqrt(k) * 0.9
	local steps = max(1, math.ceil(dt / (1 / 120)))
	local h = dt / steps
	local limit = hand.reachMax + 0.05
	for _ = 1, steps do
		local acc = (goal - hand.off) * k - hand.vel * c
		hand.vel += acc * h
		if hand.vel.Magnitude > 240 then
			hand.vel = hand.vel.Unit * 240
		end
		local nextOff = hand.off + hand.vel * h
		local from = P0 + Rf:VectorToWorldSpace(hand.off)
		local hit = cast(from, Rf:VectorToWorldSpace(nextOff - hand.off))
		if hit then
			nextOff = Rf:VectorToObjectSpace(hit.Position + hit.Normal * 0.2 - P0)
			local n = Rf:VectorToObjectSpace(hit.Normal)
			hand.vel = hand.vel - n * hand.vel:Dot(n)
		end
		if nextOff.Magnitude > limit then
			local out = nextOff.Unit
			nextOff = out * limit
			local vo = hand.vel:Dot(out)
			if vo > 0 then
				hand.vel -= out * vo
			end
		end
		hand.off = nextOff
	end
	hand.pos = P0 + Rf:VectorToWorldSpace(hand.off)
	hand.rot = hand.rot:Lerp(targetRot, 1 - exp(-16 * dt))
	local now = os.clock()
	local hist = hand.hist
	hist[#hist + 1] = { t = now, p = hand.pos, r = hand.rot }
	while #hist > 12 or (#hist > 2 and now - hist[1].t > 0.25) do
		table.remove(hist, 1)
	end
end

local function vrHand(cam, side)
	local ok, ucf = pcall(VRService.GetUserCFrame, VRService, side == "Right" and Enum.UserCFrame.RightHand or Enum.UserCFrame.LeftHand)
	if not ok or typeof(ucf) ~= "CFrame" then
		return nil
	end
	local scale = tonumber(cam.HeadScale) or 1
	return cam.CFrame * CF(ucf.Position * scale) * ucf.Rotation
end

local function wantSpeed()
	if fly.on then
		return 0
	end
	local s = body.sprint and CFG.SprintSpeed or CFG.WalkSpeed
	if body.crouchWant then
		s = min(s, CFG.WalkSpeed) * 0.5
	end
	return s
end

local function applySpeed(force)
	local s = wantSpeed()
	if (force or s ~= applied.speed) and type(fd.setWalkSpeed) == "function" then
		applied.speed = s
		pcall(fd.setWalkSpeed, s)
	end
end

local function applyHip(h)
	if type(fd.setHipHeight) ~= "function" then
		return
	end
	if abs(h - applied.hip) > 0.01 or (h == 0 and applied.hip ~= 0) then
		applied.hip = h
		applied.hipSet = true
		pcall(fd.setHipHeight, h)
	end
end

local function setCrouch(want)
	body.crouchToggle = want == true
	body.crouchWant = body.crouchToggle or body.crouchHold
	applySpeed()
	syncUi()
end

local function setSprint(want)
	body.sprintToggle = want == true
	body.sprint = body.sprintToggle or body.sprintHold
	applySpeed()
	syncUi()
end

local function stepFly(R, dt, cam)
	local ccf = cam.CFrame
	local mv = moveVector()
	local up = (fly.up and 1 or 0) - (fly.down and 1 or 0) + fly.vrAxis + ((os.clock() - (fly.jumpAt or -1) < 0.2) and 1 or 0)
	if not typing() then
		local K = Enum.KeyCode
		if UIS:IsKeyDown(K.Space) or UIS:IsKeyDown(K.E) then
			up += 1
		end
		if UIS:IsKeyDown(K.LeftControl) or UIS:IsKeyDown(K.Q) then
			up -= 1
		end
	end
	local wish = ccf.RightVector * mv.X - ccf.LookVector * mv.Z + UP * clamp(up, -1, 1)
	if wish.Magnitude > 1 then
		wish = wish.Unit
	end
	local rate = wish.Magnitude > 0.01 and 4.5 or 2.6
	local speed = CFG.FlySpeed * (body.sprint and 1.8 or 1)
	fly.vel = fly.vel:Lerp(wish * speed, 1 - exp(-rate * dt))
	local pos = R.Position
	local move = fly.vel * dt
	if move.Magnitude > 1e-4 then
		local hit, dist = sphereCast(pos, 1.4, move)
		if hit then
			local n = hit.Normal
			pos = pos + move.Unit * max(dist - 0.05, 0)
			fly.vel = fly.vel - n * min(fly.vel:Dot(n), 0)
			local rest = move * (1 - clamp(dist / move.Magnitude, 0, 1))
			rest = rest - n * rest:Dot(n)
			if not sphereCast(pos, 1.4, rest) then
				pos += rest
			end
		else
			pos += move
		end
	end
	local yaw = flatYaw(ccf.LookVector)
	local newCF = yaw and (CF(pos) * ANG(0, yaw, 0)) or (CF(pos) * R.Rotation)
	fd.cframes[vp.HumanoidRootPart] = newCF
	if type(fd.setCfr) == "function" then
		pcall(fd.setCfr, newCF)
	end
	return newCF
end

local function setFly(want)
	want = want == true
	if fly.on == want then
		return
	end
	fly.on = want
	fly.vel = ZERO
	if want then
		body.crouchToggle = false
		body.crouchWant = body.crouchHold
		if onHub then
			pcall(fd.setJumpPower, 0)
			pcall(fd.setGravity, 0)
			applySpeed(true)
		elseif type(fd.setFrozen) == "function" then
			pcall(fd.setFrozen, true, "fakevr")
		end
		say("Flying", "ok", 2)
	else
		if onHub then
			pcall(fd.setJumpPower, 50)
			pcall(fd.setGravity, tonumber(Workspace.Gravity) or 196.2)
			applySpeed(true)
		elseif type(fd.setFrozen) == "function" then
			pcall(fd.setFrozen, false, "fakevr")
		end
		say("Not flying", "info", 2)
	end
	syncUi()
end

local updateFeet, solveLegs
do
	local function groundAt(p, fromY, fallbackY)
		local depth = max(fromY - fallbackY, 0) + 3.5
		local hit = cast(V3(p.X, fromY, p.Z), V3(0, -depth, 0))
		if hit and hit.Normal.Y > 0.35 then
			return hit.Position.Y
		end
		return fallbackY
	end

	local function plant(f, p, yaw)
		f.pos = p
		f.ground = p.Y
		f.lift = 0
		f.step = nil
		f.idle = 0
		f.yaw = yaw
	end

	local function footBase(side, S)
		local s = side == "Right" and 1 or -1
		return CF(S.torsoPos) * ANG(0, S.yaw, 0) * V3(D.STANCE * s, 0, 0)
	end

	updateFeet = function(dt, S)
		if not S.onGround then
			for _, side in ipairs(SIDES) do
				local f = feet[side]
				f.air = true
				f.step = nil
				f.lift = 0
			end
			return
		end
		for _, side in ipairs(SIDES) do
			local f = feet[side]
			local b = footBase(side, S)
			f.home = V3(b.X, groundAt(b, S.fromY, S.floorY), b.Z)
			if f.air or not f.pos or S.gaitW > 0.5 then
				local from = f.lastEnd or f.home
				plant(f, V3(from.X, groundAt(from, S.fromY, S.floorY), from.Z), S.yaw)
				f.air = false
			end
			local off = V3(f.pos.X - f.home.X, 0, f.pos.Z - f.home.Z).Magnitude
			if off > 4 or abs(f.pos.Y - f.home.Y) > 3.5 then
				plant(f, f.home, S.yaw)
			end
		end
		if S.gaitW > 0.5 then
			return
		end
		for _, side in ipairs(SIDES) do
			local f = feet[side]
			local st = f.step
			if st then
				st.t += dt / st.dur
				st.yawTo = S.yaw
				st.to = st.to:Lerp(f.home + st.lead, 1 - exp(-10 * dt))
				if st.t >= 1 then
					plant(f, st.to, st.yawTo)
				else
					local e = st.t * st.t * (3 - 2 * st.t)
					f.pos = st.from:Lerp(st.to, e)
					f.ground = f.pos.Y
					f.lift = st.h * sin(PI * st.t)
					f.yaw = st.yawFrom + angleDiff(st.yawFrom, st.yawTo) * e
				end
			else
				f.idle += dt
			end
		end
		local thresh = 0.42 + S.speed * 0.12
		local best, bestScore = nil, 0
		for _, side in ipairs(SIDES) do
			local f = feet[side]
			if not f.step then
				local err = V3(f.pos.X - f.home.X, 0, f.pos.Z - f.home.Z).Magnitude
				local yawErr = abs(angleDiff(f.yaw or S.yaw, S.yaw))
				if err > thresh or yawErr > rad(38) or (f.idle > 1.6 and (err > 0.12 or yawErr > rad(8))) then
					local score = err + yawErr * 0.8
					if score > bestScore then
						best, bestScore = f, score
					end
				end
			end
		end
		if best then
			local other = feet[best.side == "Right" and "Left" or "Right"]
			if not other.step or other.step.t > 0.7 then
				local lead = V3(S.flat.X, 0, S.flat.Z) * 0.15
				best.step = { from = best.pos, to = best.home + lead, lead = lead, t = 0, dur = 0.24, h = 0.3, yawFrom = best.yaw or S.yaw, yawTo = S.yaw }
				best.idle = 0
			end
		end
	end

	local function airDir(side, S, dt)
		local L = legPend[side]
		local s = side == "Right" and 1 or -1
		local target
		if fly.on then
			target = -clamp(S.speed / 60, 0, 1) * 0.7 + sin(os.clock() * 2 + s) * 0.05
		else
			target = (s > 0 and 0.38 or -0.12) + clamp(-S.vy * 0.004, -0.15, 0.15)
		end
		L.w += (-55 * (L.a - target) - 10 * L.w) * dt
		L.a = clamp(L.a + L.w * dt, -1.3, 1.3)
		local T = S.T
		return (-T.UpVector * cos(L.a) + T.LookVector * sin(L.a) + T.RightVector * s * 0.08).Unit
	end

	local function toFloor(hip, dir, floorY, fallback)
		if hip.Y + dir.Y * D.LEG_LEN >= floorY then
			return dir
		end
		local vy = clamp((floorY - hip.Y) / D.LEG_LEN, -1, 0.35)
		local h = V3(dir.X, 0, dir.Z)
		local hm = h.Magnitude
		if hm < 0.05 then
			h, hm = fallback, 1
		end
		return (h / hm) * sqrt(max(1 - vy * vy, 0)) + UP * vy
	end

	solveLegs = function(dt, S)
		local mode = CFG.Legs
		local T = S.T
		for _, side in ipairs(SIDES) do
			local f = feet[side]
			local s = f.sign
			local name = side .. " Hip"
			if mode == "hide" or (mode == "arms" and not S.double[side]) then
				setChild(name, T, T * CF(0.5 * s, 0, 0))
				f.lastEnd = nil
			elseif mode == "walk" then
				local hip = (T * CF(0.5 * s, -1, 0)).Position
				local fallback = (S.fwd * 0.82 + S.right * s * 0.35).Unit
				local dir, floorY, rate
				if f.air or not f.pos then
					dir = airDir(side, S, dt)
					floorY = -math.huge
					rate = 14
				else
					legPend[side].a, legPend[side].w = 0, 0
					local target = f.pos + UP * (f.lift or 0)
					local d = target - hip
					dir = d.Magnitude > 1e-3 and d.Unit or -UP
					floorY = (f.ground or f.pos.Y) + (f.lift or 0)
					if S.gaitW > 0.001 then
						local m = S.moveDir
						local amp = clamp(0.25 + S.speed * 0.03, 0.25, 0.85) * (0.5 + 0.5 * abs(m:Dot(S.fwd)))
						local th = sin(body.phase + (s > 0 and 0 or PI)) * amp
						local g = -UP * cos(th) + m * sin(th)
						local mix = dir * (1 - S.gaitW) + g * S.gaitW
						dir = mix.Magnitude > 1e-3 and mix.Unit or -UP
						floorY = S.floorY
					end
					rate = 30
				end
				dir = toFloor(hip, dir, floorY, fallback)
				if f.dir then
					local m = f.dir:Lerp(dir, 1 - exp(-rate * dt))
					if m.Magnitude > 1e-3 then
						dir = toFloor(hip, m.Unit, floorY, fallback)
					end
				end
				f.dir = dir
				local bottom = hip + dir * D.LEG_LEN
				f.lastEnd = bottom
				local legRot = ANG(0, (f.air or not f.yaw) and S.yaw or f.yaw, 0)
				setChild(name, T, limbBetween(hip, bottom, facing(legRot, bottom - hip)))
			end
		end
	end
end

local function pivotOf(T, s, double)
	if double then
		return (T * CF(1.5 * s, 1, 0)).Position
	end
	return (T * CF(1.5 * s, 0.5, 0)).Position
end

local function restTarget(hand, S, double, P0)
	if double then
		return P0 - S.T.UpVector * 4
	end
	return P0 - S.T.UpVector * D.REACH_ONE
end

local function handTarget(hand, S, cam, vr)
	local double = S.double[hand.side]
	local P0 = pivotOf(S.T, hand.sign, double)
	local reach = double and D.REACH_TWO or D.REACH_ONE
	if vr then
		reach = max(reach, D.REACH_VR)
	end
	hand.pivot, hand.reachMax = P0, reach
	if vr then
		local cf = vrHand(cam, hand.side)
		if cf then
			hand.aim = cf.LookVector
			return cf.Position, cf.Rotation
		end
	end
	if hand.grip then
		local a
		if hand.screen then
			local look = cam.CFrame.LookVector
			local flat = V3(look.X, 0, look.Z)
			if flat.Magnitude < 0.05 then
				local u = cam.CFrame.UpVector
				flat = V3(u.X, 0, u.Z)
			end
			flat = flat.Magnitude > 0.05 and flat.Unit or S.fwd
			local fx, fy = TK.padFrac(hand)
			local outward = max(fx * hand.sign, -0.5)
			local lean = -outward * hand.sign * rad(CFG.ArmSide)
			local cl, sl = cos(lean), sin(lean)
			flat = V3(flat.X * cl + flat.Z * sl, 0, flat.Z * cl - flat.X * sl)
			local elev = -fy * rad(CFG.ArmUpDown)
			a = flat * cos(elev) + UP * sin(elev)
		else
			local origin, dir = aimRay(cam, hand)
			if dir.Magnitude < 1e-4 then
				dir = cam.CFrame.LookVector
			end
			dir = dir.Unit
			local hit = cast(origin, dir * 300)
			local aimPoint = hit and hit.Position or (origin + dir * 300)
			a = aimPoint - P0
			a = a.Magnitude > 1e-3 and a.Unit or dir
		end
		hand.aim = a
		local len = double and clamp(3.5 * CFG.ArmReach, 2, D.REACH_TWO) or reach
		local wall = cast(P0, a * (len + 0.25))
		if wall then
			len = clamp((wall.Position - P0).Magnitude - 0.25, 0.4, reach)
		end
		local roll = ANG(0, 0, -hand.sign * rad(15))
		return P0 + a * len, CFrame.lookAt(ZERO, a).Rotation * roll
	end
	hand.aim = nil
	return restTarget(hand, S, double, P0), S.T.Rotation
end

local function placeArm(hand, S)
	local s = hand.sign
	local T = S.T
	local P = hand.pos
	local rot = hand.rot
	local down = -T.UpVector
	if S.double[hand.side] then
		local Sh = hand.pivot
		local d = P - Sh
		local dist = d.Magnitude
		local dir = dist > 1e-3 and d / dist or down
		dist = clamp(dist, 0.4, 4)
		local along = dist * 0.5
		local h = sqrt(max(4 - along * along, 0))
		local pole = down * 0.8 + T.RightVector * s * 0.6 - T.LookVector * 0.35
		pole = pole - dir * pole:Dot(dir)
		if pole.Magnitude < 1e-3 then
			pole = T.RightVector * s
		end
		local E = Sh + dir * along + pole.Unit * h
		local Pc = Sh + dir * dist
		setChild(hand.side .. " Hip", T, limbBetween(Sh, E, facing(rot, E - Sh)))
		hand.forearm = limbBetween(E, Pc, facing(rot, Pc - E))
	else
		local P0 = hand.pivot
		local d = P - P0
		local dist = d.Magnitude
		local a = dist > 1e-3 and d / dist or down
		local G = P0 - a * D.SHOULDER_DROP
		if dist < D.REACH_ONE then
			local k = D.REACH_ONE - dist
			G = G + down * (k * 0.8) - T.LookVector * (k * 0.3) + T.RightVector * s * (k * 0.25)
		end
		local u = G - P
		if u.Magnitude < 1e-3 then
			u = -a
		end
		hand.forearm = limbBetween(P + u.Unit * D.ARM_LEN, P, facing(rot, -u))
	end
	setChild(hand.side .. " Shoulder", T, hand.forearm)
end

local function groundState()
	if fly.on then
		return false
	end
	if type(fd.isOnGround) == "function" then
		local ok, g = pcall(fd.isOnGround)
		return ok and g == true
	end
	return true
end

local function step(dt)
	local cam = Workspace.CurrentCamera
	if not cam then
		return
	end
	scanClock += dt
	if scanClock > 0.5 then
		scanClock = 0
		scan()
	end
	filterClock += dt
	if filterClock > 1 then
		filterClock = 0
		refreshFilters()
	end
	local vr = vrOn()
	if CFG.FirstPerson ~= firstPersonApplied then
		applyView()
	elseif CFG.FirstPerson and onHub and type(fd.getCamZoom) == "function" and not vr then
		local ok, z = pcall(fd.getCamZoom)
		if ok and z ~= 0 then
			pcall(fd.setCamZoom, 0)
		end
	end

	local R = fd.cframes[vp.HumanoidRootPart]
	if typeof(R) ~= "CFrame" then
		return
	end
	if fly.on then
		R = stepFly(R, dt, cam)
	end

	if body.lastRoot then
		local disp = R.Position - body.lastRoot
		if disp.Magnitude > 25 then
			body.vel = ZERO
			for _, f in pairs(feet) do
				f.air, f.step, f.lastEnd, f.dir = true, nil, nil, nil
			end
			for _, h in pairs(hands) do
				h.pos, h.off, h.vel = nil, nil, ZERO
				table.clear(h.hist)
			end
		else
			body.vel = body.vel:Lerp(disp / dt, 1 - exp(-14 * dt))
		end
	end
	body.lastRoot = R.Position

	local rawGround = groundState()
	if rawGround then
		body.airT = 0
	else
		body.airT = (body.airT or 0) + dt
	end
	local onGround = rawGround or (not fly.on and body.airT < 0.2 and body.vel.Y > -10 and body.vel.Y < 4)
	if onGround and not body.wasGround and body.fallSpeed > 12 then
		body.dipVel -= clamp(body.fallSpeed / 80, 0, 1) * 8
	end
	if not onGround then
		body.fallSpeed = max(-body.vel.Y, 0)
	else
		body.fallSpeed = 0
	end
	body.wasGround = onGround
	body.onGround = onGround
	do
		local n = max(1, math.ceil(dt / (1 / 120)))
		local h = dt / n
		for _ = 1, n do
			body.dipVel += (-140 * body.dip - 20 * body.dipVel) * h
			body.dip += body.dipVel * h
		end
		body.dip = clamp(body.dip, -0.7, 0.3)
	end

	local wantC = body.crouchWant and onGround and not vr
	body.crouch += ((wantC and 1 or 0) - body.crouch) * (1 - exp(-12 * dt))
	if not wantC and body.crouch < 0.003 then
		body.crouch = 0
	elseif wantC and body.crouch > 0.997 then
		body.crouch = 1
	end
	applyHip(-D.CROUCH_DEPTH * body.crouch)

	local fp = isFirstPersonNow(cam)
	local camCF = cam.CFrame
	if vr then
		local okR, rcf = pcall(cam.GetRenderCFrame, cam)
		if okR and typeof(rcf) == "CFrame" then
			camCF = rcf
		end
	end
	local look = camCF.LookVector
	local camYaw = flatYaw(look) or body.yaw or 0
	local pitch = math.atan2(look.Y, sqrt(look.X * look.X + look.Z * look.Z))
	local flat = V3(body.vel.X, 0, body.vel.Z)
	local speed = flat.Magnitude
	body.speed = speed
	local moveDir = speed > 0.05 and flat / speed or ZERO

	body.yaw = body.yaw or camYaw
	local targetYaw = camYaw
	if not fp and speed > 1.5 and not fly.on then
		targetYaw = flatYaw(flat) or camYaw
	end
	local diff = angleDiff(body.yaw, targetYaw)
	local rate = 0
	if fly.on or speed > 1.5 then
		rate = fp and 12 or 9
		body.turning = false
	elseif fp then
		if abs(diff) > rad(45) then
			body.turning = true
		end
		if body.turning then
			rate = 6
			if abs(diff) < rad(5) then
				body.turning = false
			end
		end
	end
	body.yaw += diff * (1 - exp(-rate * dt))

	local yawCF = ANG(0, body.yaw, 0)
	local lv = yawCF:VectorToObjectSpace(body.vel)
	local wantLean
	if fly.on then
		wantLean = Vector2.new(clamp(lv.Z * 0.012, -0.6, 0.6), clamp(-lv.X * 0.01, -0.45, 0.45))
	else
		wantLean = Vector2.new(clamp(lv.Z * 0.005, -0.16, 0.16) - body.crouch * 0.32, clamp(-lv.X * 0.004, -0.1, 0.1))
	end
	body.lean = body.lean:Lerp(wantLean, 1 - exp(-6 * dt))

	local headPos = vr and camCF.Position or (R.Position + UP * 1.5)
	local pitchLean = vr and 0 or clamp(pitch, -1.1, 1.1) * 0.12
	local torsoPos = headPos - UP * 1.5 + UP * body.dip - (vr and yawCF.LookVector * 0.12 or ZERO)
	local T = CF(torsoPos) * yawCF * ANG(body.lean.X + pitchLean, 0, body.lean.Y)
	setChild("RootJoint", R, T)

	local headRot
	if vr then
		headRot = camCF.Rotation
	else
		local relYaw = clamp(angleDiff(body.yaw, camYaw), -rad(80), rad(80))
		headRot = ANG(0, body.yaw + relYaw, 0) * ANG(clamp(pitch, -rad(80), rad(80)), 0, 0)
	end
	setChild("Neck", T, CF((T * CF(0, 1, 0)).Position) * headRot * CF(0, 0.5, 0))

	local wantGait = (onGround and speed > D.GAIT_SPEED) and 1 or 0
	body.gait += (wantGait - body.gait) * (1 - exp(-8 * dt))
	if body.gait < 0.002 then
		body.gait = 0
	end
	if speed > 0.3 and onGround then
		local freq = clamp(0.9 + speed * 0.07, 0.9, 2.6)
		body.phase = (body.phase + dt * 2 * PI * freq) % (2 * PI)
	end

	local legsAsArms = CFG.Legs == "arms"
	local S = {
		T = T,
		torsoPos = torsoPos,
		yaw = body.yaw,
		onGround = onGround,
		flat = flat,
		speed = speed,
		moveDir = moveDir,
		fwd = yawCF.LookVector,
		right = yawCF.RightVector,
		floorY = R.Y - (3 + applied.hip),
		fromY = torsoPos.Y + 0.5,
		vy = body.vel.Y,
		gaitW = body.gait,
		double = {
			Left = legsAsArms and (hasHat["Left Leg"] or 0) > 0,
			Right = legsAsArms and (hasHat["Right Leg"] or 0) > 0,
		},
	}

	if CFG.Legs == "walk" then
		updateFeet(dt, S)
	end

	local stiff = 0.35 + CFG.Smoothness * 1.65
	for _, side in ipairs(SIDES) do
		local hand = hands[side]
		local tpos, trot = handTarget(hand, S, cam, vr)
		stepHand(hand, tpos, trot, dt, vr and stiff * 3.5 or stiff, S.T.Rotation)
		placeArm(hand, S)
		if hand.grip and not hand.held then
			local it = nearestFor(hand, 1.4)
			if it then
				grab(hand, it)
			end
		end
	end

	solveLegs(dt, S)
	stepItems(dt, R.Position)
end

local lastClock = os.clock()
local function frame()
	if not alive then
		return
	end
	local now = os.clock()
	local dt = clamp(now - lastClock, 1 / 240, 1 / 15)
	lastClock = now
	local ok, err = pcall(step, dt)
	if not ok and err ~= lastErr then
		lastErr = err
		warn("[FakeVR] " .. tostring(err))
	end
end

local function pressGrip(side)
	local hand = hands[side]
	if not hand then
		return
	end
	hand.grip = true
	if hand.held or not hand.pos then
		return
	end
	local near = nearestFor(hand, 1.6)
	if near then
		grab(hand, near)
		return
	end
	if not CFG.PullAssist then
		return
	end
	local cam = Workspace.CurrentCamera
	if not cam then
		return
	end
	local origin, dir = aimRay(cam, hand)
	if dir.Magnitude < 1e-4 then
		return
	end
	local ok, hit = pcall(Workspace.Raycast, Workspace, origin, dir.Unit * D.PULL_RANGE, grabParams)
	if ok and hit and hit.Instance then
		for _, it in ipairs(order) do
			if it.handle == hit.Instance and it.state ~= "summon" and throwable(it) then
				summon(it, side)
				break
			end
		end
	end
end

local function releaseGrip(side, flick)
	local hand = hands[side]
	if not hand then
		return
	end
	hand.grip = false
	hand.screen = nil
	if hand.held and hand.held.state == "held" then
		if flick then
			tossHeld(hand, flick)
		else
			throwHeld(hand)
		end
	end
end

TK.screenSize = function()
	local w, h = nil, nil
	pcall(function()
		local m = lp:GetMouse()
		w, h = tonumber(m.ViewSizeX), tonumber(m.ViewSizeY)
	end)
	if not w or not h or w <= 0 or h <= 0 then
		local cam = Workspace.CurrentCamera
		local vs = cam and cam.ViewportSize or Vector2.new(1280, 720)
		w, h = vs.X, vs.Y
	end
	local inset = 0
	pcall(function()
		inset = game:GetService("GuiService").TopbarInset.Height
	end)
	return w, h, h + (tonumber(inset) or 0)
end

TK.reserved = function(p)
	local w, hRaw, h = TK.screenSize()
	if p.X < w * 0.4 and p.Y > h * 0.333 then
		return true
	end
	local small = min(w, hRaw) <= 500
	local jx, jy, js = small and (w - 95) or (w - 170), small and (h - 90) or (h - 210), small and 70 or 120
	return p.X > jx and p.X < jx + js and p.Y > jy and p.Y < jy + js
end

TK.taps = {}

TK.handsOn = function()
	return CFG.TouchHands and not vrOn()
end

TK.pads = function()
	local w, hRaw, h = TK.screenSize()
	local small = min(w, hRaw) <= 500
	local jumpTop = small and (h - 90) or (h - 210)
	local cy = hRaw * 0.5
	local col = 24 + 58 * clamp(hRaw / 560, 0.7, 1)
	local r = clamp(min(w, hRaw) * 0.16, 44, 100) * CFG.PadSize
	r = max(min(r, w * 0.15, jumpTop - cy - 8), 30)
	local lx = max(18, w * 0.035) + r
	local rx = w - col - r
	return { Left = { c = Vector2.new(lx, cy), r = r }, Right = { c = Vector2.new(rx, cy), r = r } }
end

TK.padsLive = function()
	return TK.handsOn() and not (TK.menuOpen and TK.menuOpen())
end

TK.padAt = function(at)
	if not TK.padsLive() then
		return nil
	end
	for side, pad in pairs(TK.pads()) do
		if (at - pad.c).Magnitude <= pad.r * 1.15 then
			return side
		end
	end
	return nil
end

TK.padFrac = function(hand)
	local pad = TK.pads()[hand.side]
	if not pad or not hand.screen then
		return 0, 0
	end
	local d = hand.screen - pad.c
	local span = pad.r * 0.85
	return clamp(d.X / span, -1, 1), clamp(d.Y / span, -1, 1)
end

TK.inset = function()
	local y = 0
	pcall(function()
		local a = game:GetService("GuiService"):GetGuiInset()
		y = a.Y
	end)
	return tonumber(y) or 0
end

TK.pullAt = function(at)
	if not CFG.PullAssist then
		return false
	end
	local cam = Workspace.CurrentCamera
	if not cam then
		return false
	end
	local origin, dir = aimRay(cam, {}, at)
	if dir.Magnitude < 1e-4 then
		return false
	end
	local ok, hit = pcall(Workspace.Raycast, Workspace, origin, dir.Unit * D.PULL_RANGE, grabParams)
	if not ok or not hit or not hit.Instance then
		return false
	end
	for _, it in ipairs(order) do
		if it.handle == hit.Instance and it.state ~= "summon" and it.state ~= "held" and throwable(it) then
			local side = at.X < TK.screenSize() * 0.5 and "Left" or "Right"
			local other = side == "Left" and "Right" or "Left"
			if hands[side].held and not hands[other].held then
				side = other
			end
			summon(it, side)
			return true
		end
	end
	return false
end

TK.speed = function(t)
	local hist = t.hist
	local newest = hist[#hist]
	if not newest then
		return 0
	end
	local oldest = hist[1]
	for i = #hist - 1, 1, -1 do
		if newest.t - hist[i].t >= 0.1 then
			oldest = hist[i]
			break
		end
	end
	local dt = newest.t - oldest.t
	if dt < 1e-3 then
		return 0
	end
	return (newest.p - oldest.p).Magnitude / dt
end

local function cycleLegs()
	local idx = 1
	for i, m in ipairs(LEG_ORDER) do
		if m == CFG.Legs then
			idx = i
		end
	end
	CFG.Legs = LEG_ORDER[idx % #LEG_ORDER + 1]
	saveCfg()
	say("Leg hats: " .. LEG_MODES[CFG.Legs], "info", 2)
	syncUi()
end

local function itemStatus(it)
	if it.state == "held" or it.state == "summon" then
		return "in your " .. string.lower(it.hand or "") .. " hand"
	elseif it.state == "free" then
		return "flying"
	elseif it.state == "asleep" then
		return "on the ground"
	elseif it.state == "return" then
		return "coming back"
	end
	return "on you"
end

local function make(class, props, parent)
	local o = Instance.new(class)
	for k, v in pairs(props or {}) do
		o[k] = v
	end
	if parent then
		o.Parent = parent
	end
	return o
end

local HUI = HUB and type(HUB.UI) == "table" and HUB.UI or nil
local DOT = { Right = Color3.fromRGB(124, 196, 255), Left = Color3.fromRGB(255, 152, 200) }
local ui = { menu = nil, layer = nil, pads = {}, touch = false, clock = 0 }
local touchFor = {}

TK.menuOpen = function()
	local m = ui.menu
	if m then
		local ok, v = pcall(m.isOpen, m)
		if ok and v then
			return true
		end
	end
	if HUI and type(HUI.busy) == "function" then
		local ok, v = pcall(HUI.busy)
		return ok and v == true
	end
	return false
end

syncUi = function()
	local m = ui.menu
	if m then
		pcall(m.refresh, m)
	end
end

local function setPanel(open)
	local m = ui.menu
	if not m then
		return false
	end
	if open == nil then
		local ok, v = pcall(m.isOpen, m)
		open = not (ok and v)
	end
	if open then
		scan()
		refreshFilters()
		pcall(m.open, m)
	else
		pcall(m.close, m)
	end
	return true
end

local function pct(v)
	return string.format("%.0f%%", v * 100)
end

local function deg(v)
	return string.format("%d°", floor(v + 0.5))
end

local function itemRows()
	local out = {}
	for i, it in ipairs(throwables()) do
		out[i] = {
			title = (i <= 9 and (i .. ".  ") or "") .. tostring(it.name or "Accessory"),
			sub = tostring(it.kind or "") .. "  ·  " .. itemStatus(it),
			picks = {
				{ "L", it.hand == "Left", function()
					summon(it, "Left")
				end },
				{ "R", it.hand == "Right", function()
					summon(it, "Right")
				end },
			},
		}
	end
	return out
end

local function number(m, title, key, step, fmt, after)
	local lim = LIMITS[key]
	m.slider(title, lim[1], lim[2], step, function()
		return CFG[key]
	end, function(v)
		CFG[key] = clamp(floor(v / step + 0.5) * step, lim[1], lim[2])
		saveCfg()
		if after then
			after()
		end
	end, fmt)
end

local function flag(m, title, key, after)
	m.toggle(title, nil, function()
		return CFG[key]
	end, function(v)
		CFG[key] = v == true
		saveCfg()
		if after then
			after()
		end
	end)
end

local function buildMenu(m, tab)
	if tab == 1 then
		m.buttons({
			{ "undo-2", "Bring back", function()
				recallAll()
			end },
		})
		flag(m, "Head hats", "ThrowHeadHats", refreshFilters)
		m.list(itemRows)
		return
	end
	m.choice("Leg hats", { { "arms", "Arms" }, { "walk", "Legs" }, { "hide", "Hide" } }, function()
		return CFG.Legs
	end, function(v)
		if LEG_MODES[v] then
			CFG.Legs = v
			saveCfg()
		end
	end)
	m.choice("View", { { true, "First" }, { false, "Third" } }, function()
		return CFG.FirstPerson
	end, function(v)
		CFG.FirstPerson = v == true
		saveCfg()
	end)
	m.toggle("Fly", nil, function()
		return fly.on
	end, setFly)
	m.toggle("Crouch", nil, function()
		return body.crouchWant
	end, setCrouch)
	m.toggle("Sprint", nil, function()
		return body.sprint
	end, setSprint)
	m.section("Hands")
	flag(m, "Pull to hand", "PullAssist")
	flag(m, "Hand dots", "Markers")
	if ui.touch then
		flag(m, "Arm circles", "TouchHands")
		number(m, "Up/down distance", "ArmUpDown", 5, deg)
		number(m, "Sideways distance", "ArmSide", 5, deg)
		number(m, "Circle size", "PadSize", 0.1, pct)
	end
	number(m, "Arm reach", "ArmReach", 0.1, pct)
	number(m, "Throw power", "ThrowPower", 0.5, function(v)
		return string.format("%.1fx", v)
	end)
	number(m, "Smoothness", "Smoothness", 0.1, function(v)
		return string.format("%.1f", v)
	end)
	m.section("Moving")
	number(m, "Walk speed", "WalkSpeed", 2, nil, function()
		applySpeed(true)
	end)
	number(m, "Sprint speed", "SprintSpeed", 2, nil, function()
		applySpeed(true)
	end)
	number(m, "Fly speed", "FlySpeed", 5)
end

local function circle(o)
	return HUI.new("UICorner", { CornerRadius = UDim.new(0.5, 0) }, o)
end

local function buildPads()
	if not (HUI and type(HUI.layer) == "function" and type(HUI.new) == "function") then
		return
	end
	local ok, layer = pcall(HUI.layer)
	if not ok or typeof(layer) ~= "Instance" then
		return
	end
	ui.layer = layer
	local accent = HUI.color("accent")
	local base = HUI.color("panel")
	for _, side in ipairs({ "Left", "Right" }) do
		local pad = HUI.new("TextButton", {
			Name = side .. "Pad",
			Text = "",
			AutoButtonColor = false,
			Selectable = false,
			BackgroundColor3 = base,
			BackgroundTransparency = 0.8,
			BorderSizePixel = 0,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Size = UDim2.fromOffset(160, 160),
			Visible = false,
		}, layer)
		circle(pad)
		local ring = HUI.stroke(pad, accent, 2, 0.55)
		HUI.new("Frame", { Name = "Middle", BackgroundColor3 = accent, BackgroundTransparency = 0.78, BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.new(0.5, 0, 0, 2) }, pad)
		local knob = HUI.new("Frame", {
			Name = "Knob",
			BackgroundColor3 = accent,
			BackgroundTransparency = 0.25,
			BorderSizePixel = 0,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(0.32, 0.32),
			Visible = false,
		}, pad)
		circle(knob)
		ui.pads[side] = { frame = pad, ring = ring, knob = knob }
	end
end

TK.origin = function()
	local ok, p = pcall(function()
		return ui.layer.AbsolutePosition
	end)
	if ok and typeof(p) == "Vector2" then
		return p
	end
	return Vector2.new(0, -TK.inset())
end

TK.drawPads = function()
	if not next(ui.pads) then
		return
	end
	local live = TK.padsLive()
	local geo = live and TK.pads() or nil
	local o = live and TK.origin() or nil
	for side, v in pairs(ui.pads) do
		v.frame.Visible = live
		if live then
			local g = geo[side]
			v.frame.Position = UDim2.fromOffset(g.c.X - o.X, g.c.Y - o.Y)
			v.frame.Size = UDim2.fromOffset(g.r * 2, g.r * 2)
			local hand = hands[side]
			if touchFor[side] and hand.screen then
				local rel = hand.screen - g.c
				if rel.Magnitude > g.r then
					rel = rel.Unit * g.r
				end
				v.knob.Position = UDim2.new(0.5, rel.X, 0.5, rel.Y)
				v.knob.Visible = true
				v.ring.Transparency = 0.15
				v.frame.BackgroundTransparency = 0.65
			else
				v.knob.Visible = false
				v.ring.Transparency = 0.55
				v.frame.BackgroundTransparency = 0.8
			end
		end
	end
end

local function buildGui()
	ui.touch = UIS.TouchEnabled == true and not vrOn()
	if HUI and type(HUI.menu) == "function" then
		local ok, m = pcall(HUI.menu, {
			title = TITLE,
			icon = "glasses",
			tabs = { "Throw", "Body" },
			build = buildMenu,
			opened = function()
				scan()
				refreshFilters()
			end,
		})
		if ok and type(m) == "table" then
			ui.menu = m
		end
	end
	if ui.touch then
		buildPads()
	end
end

local markers = {}
local function updateMarkers()
	for side, hand in pairs(hands) do
		local m = markers[side]
		local show = CFG.Markers and (hasHat[hand.limb] or 0) == 0 and hand.pos ~= nil
		if show and not m then
			m = make("Part", {
				Name = side,
				Shape = Enum.PartType.Ball,
				Size = V3(0.5, 0.5, 0.5),
				Anchored = true,
				CanCollide = false,
				CanQuery = false,
				CanTouch = false,
				CastShadow = false,
				Material = Enum.Material.Neon,
				Color = DOT[side],
				Transparency = 0.45,
			}, markerFolder)
			markers[side] = m
		end
		if m then
			m.Transparency = show and 0.45 or 1
			if show then
				m.CFrame = gripWorld(hand)
			end
		end
	end
	local cam = Workspace.CurrentCamera
	if cam and markerFolder.Parent ~= cam then
		markerFolder.Parent = cam
	end
end

local function localLook()
	local cam = Workspace.CurrentCamera
	if not cam then
		return
	end
	local fp = isFirstPersonNow(cam)
	for _, it in ipairs(order) do
		local h = it.handle
		if h and h.Parent then
			local want = (fp and it.homeLimb == "Head" and it.state == "home") and 1 or 0
			if h.LocalTransparencyModifier ~= want then
				h.LocalTransparencyModifier = want
			end
		end
	end
	updateMarkers()
end

local BIND = "FakeVR_" .. HttpService:GenerateGUID(false)

local function stop()
	if not alive then
		return
	end
	alive = false
	for _, c in ipairs(conns) do
		pcall(function()
			c:Disconnect()
		end)
	end
	table.clear(conns)
	pcall(RunService.UnbindFromRenderStep, RunService, BIND)
	if applied.blocker and type(fd.setInputBlocker) == "function" then
		pcall(fd.setInputBlocker, nil)
		applied.blocker = false
	end
	for side, t in pairs(touchFor) do
		if t then
			touchFor[side] = nil
		end
	end
	table.clear(TK.taps)
	if fly.on then
		pcall(setFly, false)
	end
	for _, it in ipairs(order) do
		pcall(restore, it)
		if it.handle then
			pcall(function()
				it.handle.LocalTransparencyModifier = 0
			end)
		end
	end
	for name, j in pairs(J) do
		local saved = J0[name]
		if saved and typeof(saved.C0) == "CFrame" then
			pcall(function()
				j.C0 = saved.C0
			end)
		end
	end
	if applied.hipSet and type(fd.setHipHeight) == "function" then
		pcall(fd.setHipHeight, 0)
	end
	if applied.speed ~= nil and type(fd.setWalkSpeed) == "function" then
		pcall(fd.setWalkSpeed, 16)
	end
	restoreView()
	if ui.menu then
		pcall(ui.menu.destroy, ui.menu)
		ui.menu = nil
	end
	if ui.layer then
		pcall(function()
			ui.layer:Destroy()
		end)
		ui.layer = nil
	end
	table.clear(ui.pads)
	pcall(function()
		markerFolder:Destroy()
	end)
	if genv.AtsukoScriptAligns == aligns then
		genv.AtsukoScriptAligns = nil
	end
	if genv.AtsukoFakeVR and genv.AtsukoFakeVR.stop == stop then
		genv.AtsukoFakeVR = nil
	end
end

genv.AtsukoFakeVR = {
	cfg = CFG,
	items = order,
	hands = hands,
	feet = feet,
	body = body,
	fly = fly,
	onFdless = onHub,
	stop = stop,
	summon = summon,
	recall = recallAll,
	setFly = setFly,
	setCrouch = setCrouch,
	setSprint = setSprint,
	throwables = throwables,
	throwable = throwable,
	grip = pressGrip,
	release = releaseGrip,
	openMenu = setPanel,
	menu = function()
		return ui.menu
	end,
	pads = function()
		return TK.pads()
	end,
	alive = function()
		return alive
	end,
}

scan()
refreshFilters()
applyView()
applySpeed(true)
buildGui()
fd.addmode("default", { idle = frame, walk = frame, jump = frame, fall = frame })
RunService:BindToRenderStep(BIND, Enum.RenderPriority.Camera.Value + 5, function()
	if alive then
		pcall(localLook)
	end
end)

do
	local DIGITS = { One = 1, Two = 2, Three = 3, Four = 4, Five = 5, Six = 6, Seven = 7, Eight = 8, Nine = 9 }

	on(UIS.InputBegan, function(io, processed)
		if not alive then
			return
		end
		local t = io.UserInputType
		if t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.MouseButton2 then
			if not processed then
				pressGrip(t == Enum.UserInputType.MouseButton1 and "Left" or "Right")
			end
			return
		end
		local K = io.KeyCode
		if K == Enum.KeyCode.ButtonR1 or K == Enum.KeyCode.ButtonR2 then
			pressGrip("Right")
			return
		elseif K == Enum.KeyCode.ButtonL1 or K == Enum.KeyCode.ButtonL2 then
			pressGrip("Left")
			return
		elseif K == Enum.KeyCode.ButtonY then
			setFly(not fly.on)
			return
		elseif K == Enum.KeyCode.ButtonX then
			recallAll()
			return
		elseif K == Enum.KeyCode.ButtonB and not vrOn() then
			setCrouch(not body.crouchToggle)
			return
		elseif K == Enum.KeyCode.ButtonL3 then
			setSprint(not body.sprintToggle)
			return
		end
		if typing() then
			return
		end
		if K == Enum.KeyCode.LeftShift then
			body.sprintHold = true
			body.sprint = true
			applySpeed()
			syncUi()
			return
		elseif K == Enum.KeyCode.LeftControl then
			if not fly.on then
				body.crouchHold = true
				body.crouchWant = true
				applySpeed()
				syncUi()
			end
			return
		end
		if processed then
			return
		end
		if K == Enum.KeyCode.C then
			setCrouch(not body.crouchToggle)
		elseif K == Enum.KeyCode.F then
			setFly(not fly.on)
		elseif K == Enum.KeyCode.R then
			local n = recallAll()
			if n > 0 then
				say("Bringing back " .. n, "info", 2)
			end
		elseif K == Enum.KeyCode.T then
			setPanel()
		elseif K == Enum.KeyCode.V then
			CFG.FirstPerson = not CFG.FirstPerson
			saveCfg()
			syncUi()
		elseif K == Enum.KeyCode.L then
			cycleLegs()
		else
			local n = DIGITS[K.Name]
			if n then
				local it = throwables()[n]
				if it then
					local left = UIS:IsKeyDown(Enum.KeyCode.LeftShift) or UIS:IsKeyDown(Enum.KeyCode.RightShift)
					summon(it, left and "Left" or "Right")
					syncUi()
				end
			end
		end
	end)

	on(UIS.InputEnded, function(io)
		local t = io.UserInputType
		if t == Enum.UserInputType.MouseButton1 then
			if hands.Left.grip and not touchFor.Left then
				releaseGrip("Left")
			end
			return
		elseif t == Enum.UserInputType.MouseButton2 then
			if hands.Right.grip and not touchFor.Right then
				releaseGrip("Right")
			end
			return
		end
		local K = io.KeyCode
		if K == Enum.KeyCode.ButtonR1 or K == Enum.KeyCode.ButtonR2 then
			releaseGrip("Right")
		elseif K == Enum.KeyCode.ButtonL1 or K == Enum.KeyCode.ButtonL2 then
			releaseGrip("Left")
		elseif K == Enum.KeyCode.LeftShift then
			body.sprintHold = false
			body.sprint = body.sprintToggle
			applySpeed()
			syncUi()
		elseif K == Enum.KeyCode.LeftControl then
			body.crouchHold = false
			body.crouchWant = body.crouchToggle
			applySpeed()
			syncUi()
		end
	end)

	pcall(on, UIS.JumpRequest, function()
		if alive and fly.on then
			fly.jumpAt = os.clock()
		end
	end)

	on(UIS.InputChanged, function(io)
		if io.KeyCode == Enum.KeyCode.Thumbstick2 then
			local y = io.Position.Y
			fly.vrAxis = abs(y) > 0.25 and y or 0
		end
	end)

	local function touchOf(io)
		for side, t in pairs(touchFor) do
			if t and t.io == io then
				return side, t
			end
		end
		return nil, nil
	end

	on(UIS.TouchStarted, function(io, processed)
		if not alive or typing() then
			return
		end
		local p = io.Position
		local at = Vector2.new(p.X, p.Y)
		local side = TK.padAt(at)
		if side then
			if touchFor[side] then
				return
			end
			touchFor[side] = { io = io, hist = { { t = os.clock(), p = at } } }
			hands[side].screen = at
			pressGrip(side)
			return
		end
		if processed or not TK.padsLive() or TK.reserved(p) then
			return
		end
		TK.taps[io] = { t = os.clock(), p = at }
	end)

	on(UIS.TouchMoved, function(io)
		local at = Vector2.new(io.Position.X, io.Position.Y)
		local side, t = touchOf(io)
		if not side then
			local tap = TK.taps[io]
			if tap and (at - tap.p).Magnitude > 14 then
				TK.taps[io] = nil
			end
			return
		end
		hands[side].screen = at
		local now = os.clock()
		t.hist[#t.hist + 1] = { t = now, p = at }
		while #t.hist > 2 and now - t.hist[1].t > 0.2 do
			table.remove(t.hist, 1)
		end
	end)

	on(UIS.TouchEnded, function(io)
		local at = Vector2.new(io.Position.X, io.Position.Y)
		local side, t = touchOf(io)
		if not side then
			local tap = TK.taps[io]
			TK.taps[io] = nil
			if tap and os.clock() - tap.t < 0.35 and (at - tap.p).Magnitude <= 14 then
				TK.pullAt(tap.p)
			end
			return
		end
		t.hist[#t.hist + 1] = { t = os.clock(), p = at }
		touchFor[side] = nil
		releaseGrip(side, TK.speed(t))
	end)

	on(UIS.WindowFocusReleased, function()
		table.clear(TK.taps)
		for side, t in pairs(touchFor) do
			if t then
				touchFor[side] = nil
				releaseGrip(side)
			end
		end
	end)

	if type(fd.setInputBlocker) == "function" then
		applied.blocker = pcall(fd.setInputBlocker, function(io)
			if not alive then
				return false
			end
			local okP, p = pcall(function()
				return io.Position
			end)
			if not okP or typeof(p) ~= "Vector3" then
				return false
			end
			return TK.padAt(Vector2.new(p.X, p.Y)) ~= nil
		end)
	end

	on(Players.PlayerRemoving, function(p)
		if p == lp then
			stop()
		end
	end)

	on(RunService.Heartbeat, function(dt)
		if not alive then
			return
		end
		if not reanimOn() then
			stop()
			return
		end
		pcall(TK.drawPads)
		if ui.menu then
			ui.clock += dt
			if ui.clock > 1 then
				ui.clock = 0
				syncUi()
			end
		end
	end)
end

do
	local h = HUB
	if type(h) == "table" and type(h.Commands) == "table" and type(h.Commands.register) == "function" then
		local function want(context, current)
			local v = context and context.state
			if v == nil then
				return not current
			end
			return v == true
		end
		pcall(h.Commands.register, {
			{
				id = "vrfly",
				name = "FakeVR fly",
				desc = "Fly where you look",
				usage = "vrfly [on|off|toggle]",
				kind = "toggle",
				run = function(_, context)
					setFly(want(context, fly.on))
				end,
			},
			{
				id = "vrcrouch",
				name = "FakeVR crouch",
				desc = "Crouch or stand up",
				usage = "vrcrouch [on|off|toggle]",
				kind = "toggle",
				run = function(_, context)
					setCrouch(want(context, body.crouchToggle))
				end,
			},
			{
				id = "vrsprint",
				name = "FakeVR sprint",
				desc = "Run at your sprint speed",
				usage = "vrsprint [on|off|toggle]",
				kind = "toggle",
				run = function(_, context)
					setSprint(want(context, body.sprintToggle))
				end,
			},
			{
				id = "vrrecall",
				name = "Recall accessories",
				desc = "Brings your accessories back",
				usage = "vrrecall",
				run = function()
					local n = recallAll()
					say(n > 0 and ("Bringing back " .. n) or "Nothing to bring back", "info", 2)
				end,
			},
			{
				id = "vrhats",
				name = "FakeVR menu",
				desc = "Opens the FakeVR menu",
				usage = "vrhats",
				run = function()
					setPanel()
				end,
			},
			{
				id = "vrview",
				name = "FakeVR first person",
				desc = "First or third person",
				usage = "vrview [on|off|toggle]",
				kind = "toggle",
				run = function(_, context)
					CFG.FirstPerson = want(context, CFG.FirstPerson)
					saveCfg()
					syncUi()
				end,
			},
			{
				id = "vrlegs",
				name = "FakeVR legs",
				desc = "arms, walk or hide",
				usage = "vrlegs <walk|arms|hide>",
				run = function(arg)
					local w = string.lower((string.gsub(tostring(arg or ""), "%s", "")))
					if LEG_MODES[w] then
						CFG.Legs = w
						saveCfg()
						say("Leg hats: " .. LEG_MODES[w], "info", 2)
						syncUi()
					else
						cycleLegs()
					end
				end,
			},
			{
				id = "vrthrow",
				name = "FakeVR throw power",
				desc = "0.5 to 6",
				usage = "vrthrow <power>",
				run = function(arg)
					local n = tonumber(arg)
					if n then
						CFG.ThrowPower = clamp(n, LIMITS.ThrowPower[1], LIMITS.ThrowPower[2])
						saveCfg()
						syncUi()
					end
					say("Throw power is " .. string.format("%.1f", CFG.ThrowPower), "info", 2)
				end,
			},
			{
				id = "vrheadhats",
				name = "Throw head hats",
				desc = "Throw the hats on your head too",
				usage = "vrheadhats [on|off|toggle]",
				kind = "toggle",
				run = function(_, context)
					CFG.ThrowHeadHats = want(context, CFG.ThrowHeadHats)
					saveCfg()
					refreshFilters()
					syncUi()
				end,
			},
		}, { short = "fakevr" })
	end
	if type(h) == "table" and type(h.OnStop) == "function" then
		h.OnStop(function()
			stop()
			pcall(function()
				if rig and rig.stopreanimate then
					rig.stopreanimate()
				end
			end)
		end)
	end
end

say("On " .. (onHub and "FDless" or "Script Reanimate") .. (vrOn() and ", VR" or ""), "ok", 3)
