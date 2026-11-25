local World = loadmodule("Testing/mocks/rbx_world.lua")
local env = World.install({})
local Exact = loadmodule("Testing/mocks/cframe_math.lua").make(Vector3)
CFrame = Exact
local makeApi = loadmodule("Testing/mocks/fake_fd.lua").make
local src = readsource("Scripts/Hat/FakeVR.lua")
local genv = env.genv

local now = 0
local realClock = os.clock
os.clock = function()
	return now
end
local DT = 1 / 60

local warned = {}
local oldWarn = warn
warn = function(...)
	local parts = {}
	for i = 1, select("#", ...) do
		parts[#parts + 1] = tostring((select(i, ...)))
	end
	warned[#warned + 1] = table.concat(parts, " ")
end
local toasts = {}
genv.AtsukoNotify = function(title, text)
	toasts[#toasts + 1] = tostring(title) .. "|" .. tostring(text)
end

local ws = game:GetService("Workspace")
local api, FV
ws.Raycast = function(_, origin, dir, params)
	if params and params.FilterType == Enum.RaycastFilterType.Include then
		local best, bestT = nil, math.huge
		local len = dir.Magnitude
		local u = dir / len
		for _, inst in ipairs(params.FilterDescendantsInstances or {}) do
			for _, it in ipairs(FV and FV.items or {}) do
				if it.handle == inst then
					local c = api.cframes[it.e]
					if c then
						local rel = c.Position - origin
						local t = rel:Dot(u)
						local miss = (rel - u * t).Magnitude
						if t > 0 and t < len and miss < 1 and t < bestT then
							best, bestT = it, t
						end
					end
				end
			end
		end
		if best then
			return { Instance = best.handle, Position = origin + u * bestT, Normal = -u, Distance = bestT }
		end
		return nil
	end
	if dir.Y < -1e-6 and origin.Y >= 0 then
		local t = origin.Y / -dir.Y
		if t <= 1 then
			local p = origin + dir * t
			return { Position = Vector3.new(p.X, 0, p.Z), Normal = Vector3.new(0, 1, 0), Distance = dir.Magnitude * t, Instance = ws }
		end
	end
	return nil
end

local cam = ws.CurrentCamera
local VW, VH = 1280, 720
local function screenRay(_, x, y)
	local tanY = math.tan(math.rad(70) / 2)
	local nx = (x / VW) * 2 - 1
	local ny = 1 - (y / VH) * 2
	local dirLocal = Vector3.new(nx * tanY * (VW / VH), ny * tanY, -1).Unit
	local cf = cam.CFrame
	return { Origin = cf.Position, Direction = cf:VectorToWorldSpace(dirLocal) }
end
cam.ScreenPointToRay = screenRay
cam.ViewportPointToRay = screenRay
game:GetService("UserInputService").GetMouseLocation = function()
	return Vector2.new(VW / 2, VH / 2)
end
local function look(yaw, pitch)
	local R = api and api.cframes[api.V.HumanoidRootPart] or CFrame.new(0, 3, 0)
	local p = R.Position + Vector3.new(0, 1.5, 0)
	cam.CFrame = CFrame.new(p) * CFrame.Angles(0, yaw or 0, 0) * CFrame.Angles(pitch or 0, 0, 0)
	cam.Focus = CFrame.new(p)
end
look(0, 0)

local function hat(a, name, limb, attachName, size)
	local acc = Instance.new("Accessory")
	acc.Name = name
	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = size or Vector3.new(1, 1, 1)
	handle.Parent = acc
	local at = Instance.new("Attachment")
	at.Name = attachName
	at.Parent = handle
	local e = { Name = "Handle", m = "rbxassetid://" .. tostring(#a.joints + 2000), t = "", p = handle }
	a.cframes[e] = CFrame.new(0, 4, 0)
	local j = { Part0 = e, Part1 = a.V[limb], C0 = CFrame.new(0, 0.5, 0), C1 = CFrame.new() }
	a.joints[#a.joints + 1] = j
	return { e = e, j = j, handle = handle }
end

local parts = {}
local on = false
genv.AtsukoHatFd = {
	reanimate = function()
		on = true
		api = makeApi()
		api.gravity, api.zoom, api.hip = 196.2, -10, 0
		function api.setGravity(n)
			api.gravity = n
		end
		function api.getCamZoom()
			return api.zoom
		end
		function api.setCamZoom(z)
			api.zoom = z
		end
		function api.isFirstPerson()
			return api.zoom == 0
		end
		function api.setHipHeight(n)
			api.hip = n
		end
		parts.rarm = hat(api, "Right fedora", "Right Arm", "HatAttachment")
		parts.larm = hat(api, "Left fedora", "Left Arm", "HatAttachment")
		parts.rleg = hat(api, "Right leg fedora", "Right Leg", "HatAttachment")
		parts.lleg = hat(api, "Left leg fedora", "Left Leg", "HatAttachment")
		parts.back = hat(api, "Sword Pack", "Torso", "BodyBackAttachment", Vector3.new(1, 3, 0.4))
		return api
	end,
	stopreanimate = function()
		on = false
	end,
	isReanimated = function()
		return on
	end,
}

local function finite(cf)
	for _, n in ipairs({ cf:GetComponents() }) do
		if n ~= n or n == math.huge or n == -math.huge then
			return false
		end
	end
	return true
end

local bad = {}
local rootPos = Vector3.new(0, 3, 0)
local physics = nil
local function frame(n, each)
	for i = 1, n do
		now += DT
		if each then
			each(i)
		end
		if physics then
			local rest = 3 + api.hip
			if rootPos.Y > rest + 0.01 then
				physics.vy -= 196.2 * DT
				rootPos = rootPos + Vector3.new(0, physics.vy * DT, 0)
				if rootPos.Y <= rest then
					rootPos = Vector3.new(rootPos.X, rest, rootPos.Z)
					physics.vy = 0
				end
				api.onground = rootPos.Y <= rest + 0.01
			else
				physics.vy = 0
				rootPos = Vector3.new(rootPos.X, rootPos.Y + (rest - rootPos.Y) * math.min(DT * 20, 1), rootPos.Z)
				api.onground = true
			end
			api.cframes[api.V.HumanoidRootPart] = CFrame.new(rootPos)
		else
			api.cframes[api.V.HumanoidRootPart] = CFrame.new(rootPos.X, rootPos.Y + api.hip, rootPos.Z)
		end
		api.modes.default.idle()
		env.frame()
		for _, j in ipairs(api.joints) do
			if j.C0 and not finite(j.C0) then
				bad[#bad + 1] = tostring(j.Name or "hat")
			end
		end
	end
end

local function torso()
	local R = api.cframes[api.V.HumanoidRootPart]
	local rj = api.getJoint("RootJoint")
	return R * rj.C0 * rj.C1:Inverse()
end

local function limb(joint)
	local j = api.getJoint(joint)
	local cf = torso() * j.C0 * j.C1:Inverse()
	return cf * Vector3.new(0, 1, 0), cf * Vector3.new(0, -1, 0), cf
end

local function near(a, b, e)
	return (a - b).Magnitude <= e
end

do
	local fn = loadstring(src, "=FakeVR")
	local ended
	task.spawn(function()
		ended = { pcall(fn) }
	end)
	env.run(1)
	T.ok(ended and ended[1] == true, "FakeVR starts: " .. tostring(ended and ended[2]))
	FV = genv.AtsukoFakeVR
	T.ok(FV ~= nil, "and publishes its handle")
	T.eq(FV.credit, nil, "the credits live on the hub's credits page, not in the script")
	T.eq(string.find(src, "--", 1, true), nil, "the script is only code, no comments")
	T.eq(FV.cfg.Legs, "arms", "the RERilla-style two-rig arms are the default")
	FV.cfg.Legs = "walk"
end

T.section("fakevr_math: standing still, the body stands on the floor")
do
	look(0, 0)
	frame(90)
	local Tc = torso()
	T.ok(Tc.UpVector.Y > 0.97, "the torso stands up: " .. tostring(Tc.UpVector))
	T.ok(math.abs(Tc.Y - 3) < 0.05, "at standing height: " .. Tc.Y)
	for _, side in ipairs({ "Right", "Left" }) do
		local s = side == "Right" and 1 or -1
		local top, bottom = limb(side .. " Hip")
		T.ok(near(top, Tc * Vector3.new(0.5 * s, -1, 0), 0.05), side .. " leg hangs from its hip")
		T.ok(math.abs(bottom.Y) < 0.06, side .. " foot is on the floor: " .. bottom.Y)
		T.eq(FV.feet[side].step, nil, side .. " foot stands still")
		local atop, abottom = limb(side .. " Shoulder")
		local h = FV.hands[side]
		local a = (h.pos - h.pivot).Unit
		T.ok(near(atop, h.pivot - a * 0.5, 0.06), side .. " arm sits on its shoulder")
		local lb = Tc:PointToObjectSpace(abottom)
		T.ok(math.abs(lb.Z) < 0.05 and lb.Y < -0.95 and math.abs(math.abs(lb.X) - 1.5) < 0.05, side .. " arm hangs straight down at its side: " .. tostring(lb))
	end
end

T.section("fakevr_math: a small look around keeps the feet planted, a big one makes them step")
do
	local fl, fr = FV.feet.Left.pos, FV.feet.Right.pos
	local yaw0 = FV.body.yaw
	frame(40, function()
		look(math.rad(30), 0)
	end)
	T.ok(math.abs(FV.body.yaw - yaw0) < 0.02, "looking 30 degrees to the side doesn't turn the body")
	T.ok(near(FV.feet.Left.pos, fl, 1e-6) and near(FV.feet.Right.pos, fr, 1e-6), "and the feet stay where they are")
	local stepped, both, below = 0, 0, 0
	frame(120, function()
		look(math.rad(110), 0)
		local a, b = FV.feet.Left.step, FV.feet.Right.step
		if a or b then
			stepped += 1
		end
		if a and b and a.t < 0.7 and b.t < 0.7 then
			both += 1
		end
		for _, side in ipairs({ "Right", "Left" }) do
			local _, bottom = limb(side .. " Hip")
			if bottom.Y < -0.06 then
				below += 1
			end
		end
	end)
	T.ok(math.abs(math.atan2(math.sin(FV.body.yaw - math.rad(110)), math.cos(FV.body.yaw - math.rad(110)))) < math.rad(8), "turning further turns the body: " .. math.deg(FV.body.yaw))
	T.ok(stepped > 0, "the feet step to follow")
	T.eq(both, 0, "one foot at a time")
	T.eq(below, 0, "and they never go through the floor")
	frame(120)
	T.eq(FV.feet.Left.step == nil and FV.feet.Right.step == nil, true, "then they settle")
end

T.section("fakevr_math: walking swings the legs, the arms stay steady")
do
	look(0, 0)
	frame(30)
	local below, detached = 0, 0
	local lo, hi
	frame(150, function()
		rootPos = rootPos + Vector3.new(0, 0, -16 * DT)
		look(0, 0)
	end)
	frame(120, function(i)
		rootPos = rootPos + Vector3.new(0, 0, -16 * DT)
		look(0, 0)
		local Tc = torso()
		local _, ra = limb("Right Shoulder")
		local la = Tc:PointToObjectSpace(ra)
		lo = lo and lo:Min(la) or la
		hi = hi and hi:Max(la) or la
		for _, side in ipairs({ "Right", "Left" }) do
			local s = side == "Right" and 1 or -1
			local top, bottom = limb(side .. " Hip")
			if bottom.Y < -0.06 then
				below += 1
			end
			if not near(top, Tc * Vector3.new(0.5 * s, -1, 0), 0.05) then
				detached += 1
			end
		end
	end)
	T.ok(FV.body.gait > 0.9, "walking fast uses the walk cycle: " .. FV.body.gait)
	local spread = hi - lo
	T.ok(math.max(spread.X, spread.Y, spread.Z) < 0.1, "the arms don't play a walking animation: " .. tostring(spread))
	T.eq(below, 0, "feet never sink into the floor while walking")
	T.eq(detached, 0, "legs stay on the hips")
	frame(120)
	T.ok(FV.body.gait < 0.05, "stopping leaves the walk cycle")
	frame(120)
	for _, side in ipairs({ "Right", "Left" }) do
		local _, bottom = limb(side .. " Hip")
		T.ok(math.abs(bottom.Y) < 0.06, side .. " foot comes back to the floor: " .. bottom.Y)
	end
end

T.section("fakevr_math: pointing keeps the arm on the shoulder")
do
	look(0, 0)
	frame(20)
	FV.grip("Right")
	local far = 0
	local worst = 0
	local flips, prevRight = 0, nil
	frame(160, function(i)
		look(math.sin(i * 0.11) * 1.2, math.cos(i * 0.07) * 0.9)
		local h = FV.hands.Right
		local d = (h.pos - h.pivot).Magnitude
		worst = math.max(worst, d)
		if d > 1.56 then
			far += 1
		end
		local _, _, cf = limb("Right Shoulder")
		local rv = cf.RightVector
		if prevRight and rv:Dot(prevRight) < 0.8 then
			flips += 1
		end
		prevRight = rv
	end)
	T.eq(far, 0, "the hand never leaves arm's length, furthest " .. string.format("%.2f", worst))
	T.eq(flips, 0, "the arm never flips its twist while you look around")
	look(0, 0)
	frame(40)
	local Tc = torso()
	local h = FV.hands.Right
	local top, bottom = limb("Right Shoulder")
	local a = (h.pos - h.pivot).Unit
	T.ok(near(top, h.pivot - a * 0.5, 0.12), "the top of the arm sits on the shoulder: " .. tostring((top - (h.pivot - a * 0.5)).Magnitude))
	T.ok(Tc:VectorToObjectSpace(bottom - top).Z < -1.5, "and it points where you look")
	FV.release("Right")
	frame(40)
	local _, b2 = limb("Right Shoulder")
	local lb = Tc:PointToObjectSpace(b2)
	T.ok(math.abs(lb.Z) < 0.05 and lb.Y < -0.95, "letting go lets the arm hang straight down again: " .. tostring(lb))
end

T.section("fakevr_math: on a phone the circles set where the arm points, never move the camera, and each finger keeps its arm")
do
	local UIS = game:GetService("UserInputService")
	local function finger(x, y)
		return { UserInputType = Enum.UserInputType.Touch, Position = Vector3.new(x, y, 0), KeyCode = Enum.KeyCode.Unknown }
	end
	local function moveTo(io, x, y)
		io.Position = Vector3.new(x, y, 0)
		UIS.TouchMoved:Fire(io, true)
	end
	local function armDir(side)
		local top, bottom = limb(side .. " Shoulder")
		return torso():VectorToObjectSpace((bottom - top).Unit)
	end
	local function worldArm(side)
		local top, bottom = limb(side .. " Shoulder")
		return (bottom - top).Unit
	end
	local pads = FV.pads()
	local R, L = pads.Right, pads.Left
	T.ok(math.abs(R.c.Y - VH / 2) < 1 and math.abs(L.c.Y - VH / 2) < 1, "both circles sit in the middle of the screen: " .. tostring(L.c) .. " " .. tostring(R.c))
	T.ok(L.c.X < VW * 0.25 and R.c.X > VW * 0.75, "one on the left, one on the right")
	look(0, 0)
	frame(30)
	local outside = finger(VW / 2, VH * 0.3)
	UIS.TouchStarted:Fire(outside, false)
	frame(10)
	T.eq(FV.hands.Right.grip or FV.hands.Left.grip, false, "a finger outside the circles doesn't move an arm")
	moveTo(outside, VW / 2 + 80, VH * 0.3)
	UIS.TouchEnded:Fire(outside, false)
	local r = finger(R.c.X, R.c.Y)
	UIS.TouchStarted:Fire(r, true)
	frame(40)
	T.eq(FV.hands.Right.grip, true, "a finger in the right circle lifts the right arm")
	T.eq(FV.hands.Left.grip, false, "and only that one")
	local mid = armDir("Right")
	T.ok(math.abs(mid.Y) < 0.15 and mid.Z < -0.9, "the middle of the circle points it straight ahead: " .. tostring(mid))
	moveTo(r, R.c.X, R.c.Y - R.r)
	frame(40)
	local high = armDir("Right")
	T.ok(high.Y > 0.85, "the top of the circle points it up: " .. tostring(high))
	moveTo(r, R.c.X, R.c.Y + R.r)
	frame(40)
	local low = armDir("Right")
	T.ok(low.Y < -0.85, "the bottom points it down: " .. tostring(low))
	moveTo(r, R.c.X, R.c.Y - R.r * 0.35)
	frame(40)
	local between = armDir("Right")
	T.ok(between.Y > 0.2 and between.Y < high.Y - 0.1, "and in between it's in between: " .. tostring(between))
	moveTo(r, R.c.X, R.c.Y)
	frame(20)
	local camBefore = cam.CFrame
	for _, spot in ipairs({ { 1, 0 }, { 1, -1 }, { -1, 1 }, { 0, -1 }, { -1, 0 } }) do
		moveTo(r, R.c.X + spot[1] * R.r, R.c.Y + spot[2] * R.r)
		frame(2)
	end
	T.ok((cam.CFrame.Position - camBefore.Position).Magnitude < 1e-9 and (cam.CFrame.LookVector - camBefore.LookVector).Magnitude < 1e-9, "moving the arm all around the circle never moves the camera")
	moveTo(r, R.c.X + R.r, R.c.Y)
	frame(40)
	local out = worldArm("Right")
	T.ok(out.X > 0.65 and out.X < 0.76 and math.abs(out.Y) < 0.1, "the right side of the circle swings it out by Sideways distance (45 degrees): " .. tostring(out))
	moveTo(r, 60, R.c.Y)
	frame(40)
	T.eq(FV.hands.Right.grip, true, "sliding the finger all the way to the left keeps the right arm")
	T.eq(FV.hands.Left.grip, false, "and never moves the left one")
	local across = worldArm("Right")
	T.ok(across.X < -0.33 and across.X > -0.43, "across the body it swings only half as far: " .. tostring(across))
	FV.cfg.ArmSide = 90
	moveTo(r, R.c.X + R.r, R.c.Y)
	frame(40)
	T.ok(worldArm("Right").X > 0.97, "a bigger Sideways distance swings it further: " .. tostring(worldArm("Right")))
	FV.cfg.ArmSide = 0
	frame(40)
	T.ok(math.abs(worldArm("Right").X) < 0.02, "and 0 keeps it pointing where you look: " .. tostring(worldArm("Right")))
	FV.cfg.ArmSide = 45
	moveTo(r, R.c.X, R.c.Y)
	local lo, hi
	frame(90, function(i)
		look(math.rad(i * 1.4), 0)
		local l = torso():PointToObjectSpace(FV.hands.Left.pos)
		lo = lo and lo:Min(l) or l
		hi = hi and hi:Max(l) or l
	end)
	local spread = hi - lo
	T.ok(math.abs(FV.body.yaw) > math.rad(40), "the body turned with the camera")
	T.ok(math.max(spread.X, spread.Y, spread.Z) < 0.05, "and the resting left arm turned with it without swaying: " .. tostring(spread))
	UIS.TouchEnded:Fire(r, true)
	look(0, 0)
	frame(120)
	FV.cfg.ArmUpDown = 39
	local t2 = finger(R.c.X, R.c.Y - R.r)
	UIS.TouchStarted:Fire(t2, true)
	frame(40)
	local half = armDir("Right")
	T.ok(half.Y > 0.55 and half.Y < 0.7, "a lower Up/down distance keeps it closer to straight ahead: " .. tostring(half))
	UIS.TouchEnded:Fire(t2, true)
	FV.cfg.ArmUpDown = 75
	local stick = finger(150, VH - 70)
	UIS.TouchStarted:Fire(stick, false)
	frame(10)
	T.eq(FV.hands.Left.grip, false, "the joystick under the left circle stays the joystick")
	UIS.TouchEnded:Fire(stick, false)
	local l2 = finger(L.c.X, L.c.Y + L.r)
	UIS.TouchStarted:Fire(l2, true)
	frame(40)
	T.eq(FV.hands.Left.grip, true, "the left circle works the same")
	T.ok(armDir("Left").Y < -0.85, "pointing the left arm down from the bottom of its circle")
	UIS.TouchEnded:Fire(l2, true)
	frame(40)
	T.eq(FV.hands.Left.grip, false, "lifting the finger lowers it")
end

T.section("fakevr_math: tapping an accessory on the screen pulls it into that hand")
do
	local UIS = game:GetService("UserInputService")
	local it
	for _, x in ipairs(FV.items) do
		if x.e == parts.back.e then
			it = x
		end
	end
	look(0, 0)
	frame(10)
	local Rr = api.cframes[api.V.HumanoidRootPart]
	local function park()
		it.state, it.pos, it.rot, it.vel, it.ang = "asleep", Rr.Position + Vector3.new(0, 1.5, -9), CFrame.new(), Vector3.new(), Vector3.new()
		parts.back.j.Part1 = nil
		api.cframes[it.e] = CFrame.new(it.pos)
	end
	park()
	frame(2)
	local drag = { UserInputType = Enum.UserInputType.Touch, Position = Vector3.new(VW / 2, VH / 2, 0), KeyCode = Enum.KeyCode.Unknown }
	UIS.TouchStarted:Fire(drag, false)
	now += 0.05
	drag.Position = Vector3.new(VW / 2 + 60, VH / 2, 0)
	UIS.TouchMoved:Fire(drag, false)
	UIS.TouchEnded:Fire(drag, false)
	T.eq(it.state, "asleep", "dragging over it only turns the camera")
	local tap = { UserInputType = Enum.UserInputType.Touch, Position = Vector3.new(VW / 2, VH / 2, 0), KeyCode = Enum.KeyCode.Unknown }
	UIS.TouchStarted:Fire(tap, false)
	now += 0.1
	UIS.TouchEnded:Fire(tap, false)
	T.eq(it.state, "summon", "a quick tap on it pulls it")
	frame(60)
	T.eq(it.state, "held", "into the right hand, the side you tapped on")
	T.ok(FV.hands.Right.held == it, "the right hand holds it")
	FV.recall()
	frame(60)
	T.eq(it.state, "home", "it goes home again")
end

T.section("fakevr_math: pointing at an accessory pulls it to the hand, then a swing throws it")
do
	local it
	for _, x in ipairs(FV.items) do
		if x.e == parts.back.e then
			it = x
		end
	end
	T.ok(it ~= nil and FV.throwable(it), "the back accessory can be thrown")
	look(0, 0)
	frame(10)
	local R = api.cframes[api.V.HumanoidRootPart]
	it.state, it.pos, it.rot, it.vel, it.ang = "asleep", R.Position + Vector3.new(0, 0.5 - 2.5 + 1.5, -9), CFrame.new(), Vector3.new(), Vector3.new()
	parts.back.j.Part1 = nil
	api.cframes[it.e] = CFrame.new(it.pos)
	local toItem = (it.pos - (R.Position + Vector3.new(0, 1.5, 0)))
	look(math.atan2(-toItem.X, -toItem.Z), math.atan2(toItem.Y, math.sqrt(toItem.X ^ 2 + toItem.Z ^ 2)))
	frame(2)
	FV.grip("Right")
	T.eq(it.state, "summon", "it flies to the hand")
	local maxReach = 0
	frame(60, function()
		local h = FV.hands.Right
		maxReach = math.max(maxReach, (h.pos - h.pivot).Magnitude)
	end)
	T.eq(it.state, "held", "and lands in it")
	T.ok(maxReach <= 1.56, "without the arm reaching out for it: " .. string.format("%.2f", maxReach))
	local yaw = 1.0
	look(yaw, 0)
	frame(20)
	frame(6, function()
		yaw -= 0.33
		look(yaw, 0)
	end)
	FV.release("Right")
	T.eq(it.state, "free", "letting go mid swing throws it")
	T.ok(it.vel.Magnitude > 12, "fast: " .. string.format("%.1f", it.vel.Magnitude))
	local Tc = torso()
	local side = Tc:VectorToObjectSpace(it.vel).X
	T.ok(side > 0, "the way the hand was swinging (to the right): " .. string.format("%.1f", side))
	frame(30)
	FV.recall()
	frame(60)
	T.eq(it.state, "home", "recall brings it home")
end

T.section("fakevr_math: crouching lowers the body and keeps the feet on the floor")
do
	FV.setCrouch(true)
	local below = 0
	frame(90, function()
		for _, side in ipairs({ "Right", "Left" }) do
			local _, bottom = limb(side .. " Hip")
			if bottom.Y < -0.06 then
				below += 1
			end
		end
	end)
	T.ok(api.hip < -0.95, "the reanimation's hip height goes down: " .. api.hip)
	T.eq(api.ws, 8, "and walking slows down")
	T.ok(torso().Y < 2.1, "the torso is lower: " .. torso().Y)
	T.eq(below, 0, "the legs never go through the floor")
	FV.setCrouch(false)
	frame(90)
	T.eq(api.hip, 0, "standing up puts it back")
	T.eq(api.ws, 16)
	FV.setSprint(true)
	T.eq(api.ws, 26, "sprinting")
	FV.setSprint(false)
	T.eq(api.ws, 16)
end

T.section("fakevr_math: crouching on a reanimation that drops the body with gravity")
do
	physics = { vy = 0 }
	frame(30)
	FV.setCrouch(true)
	local flicker, below = 0, 0
	frame(120, function()
		if FV.feet.Right.air or FV.feet.Left.air then
			flicker += 1
		end
		for _, side in ipairs({ "Right", "Left" }) do
			local _, bottom = limb(side .. " Hip")
			if bottom.Y < -0.06 then
				below += 1
			end
		end
	end)
	T.eq(flicker, 0, "the legs never think they are in the air")
	T.ok(api.hip < -0.95, "and it still crouches all the way: " .. api.hip)
	T.ok(rootPos.Y < 2.1, "the body really went down: " .. rootPos.Y)
	T.eq(below, 0, "feet stay on the floor")
	FV.setCrouch(false)
	frame(120, function()
		if FV.feet.Right.air or FV.feet.Left.air then
			flicker += 1
		end
	end)
	T.eq(flicker, 0, "standing up doesn't flicker either")
	T.ok(math.abs(rootPos.Y - 3) < 0.05, "and it stands back up: " .. rootPos.Y)
	physics = nil
	rootPos = Vector3.new(rootPos.X, 3, rootPos.Z)
	api.onground = true
end

T.section("fakevr_math: jumping and landing")
do
	api.onground = false
	local vy = 50
	local dipped, airLegs = false, 0
	frame(60, function()
		vy -= 196.2 * DT
		rootPos = rootPos + Vector3.new(0, vy * DT, 0)
		if rootPos.Y < 3 then
			rootPos = Vector3.new(rootPos.X, 3, rootPos.Z)
			api.onground = true
		end
		if FV.body.dip < -0.05 then
			dipped = true
		end
		if FV.feet.Right.air then
			airLegs += 1
		end
	end)
	api.onground = true
	rootPos = Vector3.new(rootPos.X, 3, rootPos.Z)
	T.ok(airLegs > 10, "the legs hang loose in the air")
	T.ok(dipped, "landing from a jump bends the body a little")
	frame(60)
	for _, side in ipairs({ "Right", "Left" }) do
		local _, bottom = limb(side .. " Hip")
		T.ok(math.abs(bottom.Y) < 0.06, side .. " foot lands on the floor: " .. bottom.Y)
	end
end

T.section("fakevr_math: flying")
do
	FV.setFly(true)
	frame(60, function()
		look(0, -0.2)
	end)
	local Tc = torso()
	for _, side in ipairs({ "Right", "Left" }) do
		local top, bottom = limb(side .. " Hip")
		T.ok(bottom.Y < top.Y, side .. " leg trails under the body")
	end
	T.ok(Tc.UpVector.Y > 0.5, "the body stays mostly upright")
	FV.setFly(false)
	frame(30)
end

T.section("fakevr_math: leg hats as upper arms bend at the elbow")
do
	FV.cfg.Legs = "arms"
	frame(30)
	FV.grip("Left")
	local apart = 0
	frame(60, function(i)
		look(math.sin(i * 0.1) * 0.8, 0.2)
		local uTop, uBottom = limb("Left Hip")
		local fTop = limb("Left Shoulder")
		if (uBottom - fTop).Magnitude > 0.06 then
			apart += 1
		end
	end)
	T.eq(apart, 0, "the forearm hangs from the elbow")
	local Tc = torso()
	local uTop = limb("Left Hip")
	T.ok(near(uTop, Tc * Vector3.new(-1.5, 1, 0), 0.06), "and the upper arm from the shoulder, like RERilla")
	look(0, 0)
	frame(40)
	local hl = FV.hands.Left
	local full = (hl.pos - hl.pivot).Magnitude
	T.ok(math.abs(full - 3.5) < 0.1, "pointing stretches it 3.5 out: " .. string.format("%.2f", full))
	FV.cfg.ArmReach = 0.6
	frame(40)
	local short = (hl.pos - hl.pivot).Magnitude
	T.ok(math.abs(short - 2.1) < 0.1, "a lower Arm reach keeps it closer: " .. string.format("%.2f", short))
	FV.cfg.ArmReach = 1
	frame(40)
	FV.release("Left")
	frame(40)
	do
		local Tr = torso()
		for _, side in ipairs({ "Left", "Right" }) do
			local ut, ub = limb(side .. " Hip")
			local ft, fb = limb(side .. " Shoulder")
			local up = Tr:VectorToObjectSpace((ub - ut).Unit)
			local fore = Tr:VectorToObjectSpace((fb - ft).Unit)
			T.ok(up.Y < -0.995 and fore.Y < -0.995, side .. " two-rig arm hangs straight down when you let go: " .. tostring(up) .. " " .. tostring(fore))
		end
	end
	local lo2, hi2, far2, apart2 = nil, nil, 0, 0
	frame(90, function()
		rootPos = rootPos + Vector3.new(0, 0, -16 * DT)
		look(0, 0)
	end)
	frame(90, function()
		rootPos = rootPos + Vector3.new(0, 0, -16 * DT)
		look(0, 0)
		local T2 = torso()
		for _, side in ipairs({ "Left", "Right" }) do
			local _, fb = limb(side .. " Shoulder")
			local _, ub = limb(side .. " Hip")
			local ft = limb(side .. " Shoulder")
			if (ub - ft).Magnitude > 0.06 then
				apart2 += 1
			end
			local h = FV.hands[side]
			if (h.pos - h.pivot).Magnitude > 4.001 then
				far2 += 1
			end
			if side == "Left" then
				local l = T2:PointToObjectSpace(fb)
				lo2 = lo2 and lo2:Min(l) or l
				hi2 = hi2 and hi2:Max(l) or l
			end
		end
	end)
	local spread2 = hi2 - lo2
	T.ok(math.max(spread2.X, spread2.Y, spread2.Z) < 0.1, "the two-rig arms don't copy the walking animation: " .. tostring(spread2))
	T.eq(apart2, 0, "and stay joined at the elbow")
	T.eq(far2, 0, "and never stretch past both segments")
	FV.cfg.Legs = "hide"
	frame(10)
	local _, _, legCF = limb("Right Hip")
	T.ok(near(legCF.Position, torso() * Vector3.new(0.5, 0, 0), 0.05), "hidden legs are tucked into the body")
	FV.cfg.Legs = "walk"
	frame(60)
	local _, bottom = limb("Right Hip")
	T.ok(math.abs(bottom.Y) < 0.06, "and come back to the floor when shown: " .. bottom.Y)
end

T.section("fakevr_math: third person")
do
	FV.cfg.FirstPerson = false
	frame(10)
	T.eq(api.zoom, -10, "the camera goes back out")
	frame(120, function()
		rootPos = rootPos + Vector3.new(16 * DT, 0, 0)
		look(0, 0)
	end)
	local want = math.atan2(-1, 0)
	local d = math.atan2(math.sin(FV.body.yaw - want), math.cos(FV.body.yaw - want))
	T.ok(math.abs(d) < math.rad(10), "walking sideways faces the way you walk: " .. math.deg(FV.body.yaw))
	FV.cfg.FirstPerson = true
	frame(5)
	T.eq(api.zoom, 0, "and first person comes back")
end

T.section("fakevr_math: nothing broke along the way")
do
	T.eq(#bad, 0, "every joint stayed a real number: " .. table.concat(bad, ", "))
	T.eq(#warned, 0, "no errors: " .. table.concat(warned, " | "))
	T.eq(#env.badProps, 0, "no bad properties: " .. table.concat(env.badProps, " | "))
	on = false
	env.run(1)
	T.eq(FV.alive(), false, "it stops with the reanimation")
	T.eq(api.hip, 0, "hip height is left at normal")
end

warn = oldWarn
os.clock = realClock
