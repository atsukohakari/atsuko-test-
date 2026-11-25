local World = loadmodule("Testing/mocks/rbx_world.lua")
local env = World.install({})
local makeApi = loadmodule("Testing/mocks/fake_fd.lua").make
local src = readsource("Scripts/Hat/FakeVR.lua")
local genv = env.genv

local cfMeta = getmetatable(CFrame.new())
CFrame.fromAxisAngle = CFrame.fromAxisAngle or function()
	return CFrame.new()
end
cfMeta.ToAxisAngle = cfMeta.ToAxisAngle or function()
	return Vector3.xAxis, 0
end

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
genv.AtsukoNotify = function(title, text, kind)
	toasts[#toasts + 1] = tostring(title) .. "|" .. tostring(text) .. "|" .. tostring(kind)
end

local function hat(api, name, limb, attachName, size)
	local acc = Instance.new("Accessory")
	acc.Name = name
	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = size or Vector3.new(1, 1, 1)
	handle.Parent = acc
	if attachName then
		local at = Instance.new("Attachment")
		at.Name = attachName
		at.Parent = handle
	end
	local e = { Name = "Handle", m = "rbxassetid://" .. tostring(#api.joints + 1000), t = "", p = handle }
	api.cframes[e] = CFrame.new(0, 4, 0)
	local j = { Part0 = e, Part1 = api.V[limb], C0 = CFrame.new(0, 0.5, 0), C1 = CFrame.new() }
	api.joints[#api.joints + 1] = j
	return { e = e, j = j, handle = handle }
end

local function fullApi(api)
	api.gravity = 196.2
	api.zoom = -10
	api.hip = 0
	function api.setHipHeight(n)
		api.hip = n
	end
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
	return api
end

local function rigUp(api)
	local out = {}
	out.rarm = hat(api, "Right fedora", "Right Arm", "HatAttachment")
	out.larm = hat(api, "Left fedora", "Left Arm", "HatAttachment")
	out.rleg = hat(api, "Right leg fedora", "Right Leg", "HatAttachment")
	out.lleg = hat(api, "Left leg fedora", "Left Leg", "HatAttachment")
	out.hair = hat(api, "Cool Hair", "Head", "HairAttachment")
	out.cap = hat(api, "Baseball Cap", "Head", "HatAttachment")
	out.back = hat(api, "Sword Pack", "Torso", "BodyBackAttachment", Vector3.new(1, 3, 0.4))
	out.waist = hat(api, "Waist Bag", "Torso", "WaistFrontAttachment")
	return out
end

local function frames(api, n, each)
	for i = 1, n do
		if each then
			each(i)
		end
		if api.modes.default and api.modes.default.idle then
			api.modes.default.idle()
		end
		env.frame()
	end
end

local function itemFor(FV, h)
	for _, it in ipairs(FV.items) do
		if it.e == h.e then
			return it
		end
	end
	return nil
end

local UIT = Enum.UserInputType
local UIS = game:GetService("UserInputService")
local function input(kind, extra)
	local io = { UserInputType = kind, KeyCode = Enum.KeyCode.Unknown, Position = Vector3.new(), Delta = Vector3.new() }
	for k, v in pairs(extra or {}) do
		io[k] = v
	end
	return io
end

T.section("fakevr_run: starts on FDless (the hub's AtsukoHatFd)")
local api, on = nil, false
local parts
genv.AtsukoHatFd = {
	reanimate = function()
		on = true
		api = fullApi(makeApi())
		parts = rigUp(api)
		return api
	end,
	stopreanimate = function()
		on = false
	end,
	isReanimated = function()
		return on
	end,
}
local ended = nil
do
	local fn, cerr = loadstring(src, "=FakeVR")
	T.ok(fn ~= nil, "the script compiles: " .. tostring(cerr))
	task.spawn(function()
		local ok, e = pcall(fn)
		ended = { ok, e }
	end)
	env.run(1)
	T.ok(ended ~= nil and ended[1] == true, "the main chunk finishes without an error: " .. tostring(ended and ended[2]))
	T.ok(api ~= nil and api.modes.default ~= nil, "it reanimated and drives the default mode")
	T.eq(type(genv.AtsukoScriptAligns), "table", "its arm hats go to FDless in front of FDless's own list")
	T.eq(api.zoom, 0, "first person is on")
	T.eq(api.ws, 16, "it walks at the normal speed")
	local said = false
	for _, t in ipairs(toasts) do
		if string.find(t, "On FDless", 1, true) then
			said = true
		end
	end
	T.ok(said, "the start message says what it runs on: " .. table.concat(toasts, " / "))
	local credits = readsource("Hub/credits.json")
	T.ok(string.find(credits, "0866", 1, true) and string.find(credits, "Abacaxl", 1, true) and string.find(credits, "im_patrick", 1, true) and string.find(credits, "saucekid", 1, true), "its makers are on the hub's credits page")
end

local FV = genv.AtsukoFakeVR
T.ok(FV ~= nil and FV.onFdless == true, "the handle is published and knows it runs on FDless")

T.section("fakevr_run: every frame poses the body through the joints")
do
	local rj, neck, rs = api.getJoint("RootJoint"), api.getJoint("Neck"), api.getJoint("Right Shoulder")
	local before = { rj.C0, neck.C0, rs.C0 }
	frames(api, 30)
	T.eq(#warned, 0, "no errors while running: " .. table.concat(warned, " | "))
	T.ok(neck.C0 ~= before[2] or rs.C0 ~= before[3], "the neck and arms are moved by FakeVR")
	T.ok(FV.hands.Right.pos ~= nil and FV.hands.Left.pos ~= nil, "both hands have a position")
	T.eq(FV.cfg.Legs, "arms", "the two-rig arms are the default")
	FV.cfg.Legs = "walk"
	frames(api, 10)
	T.ok(FV.feet.Right.pos ~= nil and FV.feet.Left.pos ~= nil, "with legs on, both feet are planted")
	FV.cfg.Legs = "arms"
	frames(api, 5)
end

T.section("fakevr_run: which accessories can be thrown")
do
	local function kindOf(h)
		local it = itemFor(FV, h)
		return it and FV.throwable(it)
	end
	T.eq(#FV.items, 8, "every accessory is known")
	T.eq(kindOf(parts.rarm), false, "a rig hat on an arm is a hand, not a throwable")
	T.eq(kindOf(parts.rleg), false, "a rig hat on a leg stays a leg or an upper arm")
	T.eq(kindOf(parts.hair), false, "hair is never thrown")
	T.eq(kindOf(parts.cap), false, "a hat on the head is not thrown by default")
	T.eq(kindOf(parts.back), true, "a back accessory can be thrown")
	T.eq(kindOf(parts.waist), true, "a waist accessory can be thrown")
	FV.cfg.ThrowHeadHats = true
	T.eq(kindOf(parts.cap), true, "head hats can be turned on")
	T.eq(kindOf(parts.hair), false, "hair still can't")
	FV.cfg.ThrowHeadHats = false
	T.eq(#FV.throwables(), 2)
end

T.section("fakevr_run: summon, hold, throw and get it back")
do
	local it = itemFor(FV, parts.back)
	T.eq(FV.summon(it, "Right"), true, "a throwable accessory can be summoned")
	frames(api, 120)
	T.eq(it.state, "held", "it lands in the hand")
	T.eq(FV.hands.Right.held, it)
	T.eq(parts.back.j.Part1, api.V["Right Arm"], "its joint now hangs on the right arm")
	local cam = workspace.CurrentCamera
	UIS.InputBegan:Fire(input(UIT.MouseButton2), false)
	frames(api, 12, function(i)
		cam.CFrame = CFrame.new(i * 0.6, 4, -i * 0.4)
		api.cframes[api.V.HumanoidRootPart] = CFrame.new(0, 3, -i * 0.5)
	end)
	UIS.InputEnded:Fire(input(UIT.MouseButton2), false)
	T.eq(it.state, "free", "letting go throws it")
	T.ok(it.vel and it.vel.Magnitude > 5, "with the speed of the hand: " .. tostring(it.vel and it.vel.Magnitude))
	T.eq(parts.back.j.Part1, nil, "while it flies it hangs on nothing")
	local y0 = it.pos and it.pos.Y or 0
	frames(api, 20)
	T.ok(it.state ~= "free" or (it.pos and it.pos.Y < y0), "gravity pulls it down")
	FV.recall()
	frames(api, 120)
	T.eq(it.state, "home", "recall brings it back")
	T.eq(parts.back.j.Part1, api.V.Torso, "on its own joint again")
	T.eq(#warned, 0, "no errors: " .. table.concat(warned, " | "))
end

T.section("fakevr_run: a hair or a rig hat can't be summoned")
do
	T.eq(FV.summon(itemFor(FV, parts.hair), "Left"), false)
	T.eq(FV.summon(itemFor(FV, parts.larm), "Left"), false)
end

T.section("fakevr_run: flying moves the body itself and gives FDless's movement back after")
do
	local before = #api.moved
	FV.setFly(true)
	T.eq(api.ws, 0, "FDless's own walking is held")
	T.eq(api.gravity, 0, "and its gravity")
	frames(api, 20)
	T.ok(#api.moved > before, "the body is moved every frame")
	FV.setFly(false)
	T.eq(api.ws, 16, "walking comes back")
	T.ok(api.gravity > 100, "and gravity")
end

T.section("fakevr_run: the three leg modes run")
do
	for _, mode in ipairs({ "walk", "hide", "arms", "walk" }) do
		FV.cfg.Legs = mode
		frames(api, 10)
	end
	T.eq(#warned, 0, "no errors: " .. table.concat(warned, " | "))
end

T.section("fakevr_run: crouch and sprint")
do
	FV.setCrouch(true)
	frames(api, 60)
	T.ok(api.hip < -0.5, "crouching lowers the reanimation's hip height: " .. tostring(api.hip))
	T.eq(api.ws, 8, "and walks slower")
	FV.setCrouch(false)
	frames(api, 160)
	T.eq(api.hip, 0, "standing up puts it back")
	FV.setSprint(true)
	T.eq(api.ws, 26, "sprinting is faster")
	FV.setSprint(false)
	T.eq(api.ws, 16)
	T.eq(#warned, 0, "no errors: " .. table.concat(warned, " | "))
end

T.section("fakevr_run: the arms never stretch away from the body")
do
	FV.grip("Right")
	FV.grip("Left")
	local worst = 0
	frames(api, 40, function(i)
		workspace.CurrentCamera.CFrame = CFrame.new(i * 3, 4, -i * 2)
		for _, side in ipairs({ "Left", "Right" }) do
			local h = FV.hands[side]
			if h.pos and h.pivot then
				worst = math.max(worst, (h.pos - h.pivot).Magnitude - h.reachMax)
			end
		end
	end)
	FV.release("Right")
	FV.release("Left")
	T.ok(worst <= 0.06, "each hand stays within arm's length: " .. string.format("%.2f", worst))
end

T.section("fakevr_run: stopping the reanimation puts everything back")
do
	local it = itemFor(FV, parts.waist)
	FV.summon(it, "Left")
	frames(api, 5)
	on = false
	env.run(1)
	T.eq(FV.alive(), false, "FakeVR stops with the reanimation")
	T.eq(genv.AtsukoFakeVR, nil, "and lets go of its handle")
	T.eq(parts.waist.j.Part1, api.V.Torso, "accessories go back on their joints")
	T.eq(genv.AtsukoScriptAligns, nil, "and its hat list is taken back")
	T.eq(api.hip, 0, "the hip height is normal")
	T.eq(api.ws, 16, "and so is the walk speed")
end

T.section("fakevr_run: starts on Script Reanimate (LumenReanim.rig)")
do
	genv.AtsukoHatFd = nil
	warned = {}
	local api2, live = nil, nil
	local gotAligns = nil
	genv.LumenReanim = {
		rig = function(cfg)
			gotAligns = cfg and cfg.aligns
			return {
				reanimate = function()
					api2 = makeApi()
					rigUp(api2)
					api2.frozen = false
					function api2.setFrozen(b)
						api2.frozen = b
					end
					live = { isReady = function()
						return true
					end }
					return api2
				end,
				stopreanimate = function()
					live = nil
				end,
			}
		end,
		current = function()
			return live
		end,
	}
	ended = nil
	local fn = loadstring(src, "=FakeVR")
	task.spawn(function()
		local ok, e = pcall(fn)
		ended = { ok, e }
	end)
	env.run(1)
	T.ok(ended ~= nil and ended[1] == true, "the main chunk finishes: " .. tostring(ended and ended[2]))
	T.ok(type(gotAligns) == "table" and #gotAligns > 0, "its arm hats are handed to the rig")
	local FV2 = genv.AtsukoFakeVR
	T.ok(FV2 ~= nil and FV2.onFdless == false, "it knows it runs on Script Reanimate")
	frames(api2, 20)
	FV2.setFly(true)
	T.eq(api2.frozen, true, "flying holds Script Reanimate's own movement")
	frames(api2, 10)
	FV2.setFly(false)
	T.eq(api2.frozen, false)
	T.eq(#warned, 0, "no errors: " .. table.concat(warned, " | "))
	live = nil
	env.run(1)
	T.eq(FV2.alive(), false, "it stops with the reanimation")
	genv.LumenReanim = nil
end

warn = oldWarn
