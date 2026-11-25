local Boot = loadmodule("Testing/mocks/boot_runner.lua")
local makeApi = loadmodule("Testing/mocks/fake_fd.lua").make
local src = readsource("Scripts/Hat/FakeVR.lua")
local PATH = "Scripts/Hat/FakeVR.lua"

local env = Boot.boot({ touch = true, viewW = 1280, viewH = 720, seconds = 8 })
local hub, core = env.hub, env.core
local genv = env.genv
T.ok(env.mainOk == true, "the hub starts: " .. tostring(env.mainErr))
hub.Panel.hide()
env.run(1)

local now = 0
local realClock = os.clock
os.clock = function()
	return now
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

local api, on = nil, false
local back
local early, late

local function fdCamera()
	local st = { rotate = nil, zoom = nil, stick = nil, moves = 0 }
	local U = game:GetService("UserInputService")
	U.TouchStarted:Connect(function(io, gp)
		if api.blocker and api.blocker(io) then
			return
		end
		local p = io.Position
		if not st.stick and p.X < 1280 * 0.4 and p.Y > 720 * 0.333 then
			st.stick = io
		elseif gp then
			return
		elseif not st.rotate then
			st.rotate = io
		else
			st.zoom = io
		end
	end)
	U.TouchMoved:Connect(function(io)
		if io == st.rotate and not st.zoom then
			st.moves += 1
		end
	end)
	U.TouchEnded:Connect(function(io)
		if io == st.stick then
			st.stick = nil
		elseif io == st.rotate then
			st.rotate, st.zoom = nil, nil
		elseif io == st.zoom then
			st.zoom = nil
		end
	end)
	return st
end
genv.AtsukoHatFd = {
	reanimate = function()
		on = true
		api = makeApi()
		api.hip = 0
		function api.setHipHeight(n)
			api.hip = n
		end
		function api.setGravity() end
		function api.setInputBlocker(f)
			api.blocker = f
		end
		api.yaw = 0
		function api.rotateCam(y)
			api.yaw += y
		end
		early = fdCamera()
		local acc = Instance.new("Accessory")
		acc.Name = "Sword Pack"
		local handle = Instance.new("Part")
		handle.Name = "Handle"
		handle.Parent = acc
		local at = Instance.new("Attachment")
		at.Name = "BodyBackAttachment"
		at.Parent = handle
		local e = { Name = "Handle", m = "rbxassetid://777", t = "", p = handle }
		api.cframes[e] = CFrame.new(0, 3, 0.6)
		back = { e = e, j = { Part0 = e, Part1 = api.V.Torso, C0 = CFrame.new(), C1 = CFrame.new(0, 0, 0.6) } }
		api.joints[#api.joints + 1] = back.j
		return api
	end,
	stopreanimate = function()
		on = false
	end,
	isReanimated = function()
		return on
	end,
}

local function frames(n)
	for _ = 1, n do
		now += 1 / 60
		api.modes.default.idle()
		env.frame()
	end
end

local function screens()
	local list = {}
	for _, root in ipairs({ env.hui, env.coreGui, env.playerGui }) do
		if root then
			for _, d in ipairs(root:GetDescendants()) do
				if d:IsA("ScreenGui") then
					list[#list + 1] = d
				end
			end
		end
	end
	return list
end

local function find(root, name)
	for _, d in ipairs(root:GetDescendants()) do
		if d.Name == name then
			return d
		end
	end
	return nil
end

local function withText(root, text)
	for _, d in ipairs(root:GetDescendants()) do
		if d:IsA("TextButton") and d.Text == text then
			return d
		end
	end
	return nil
end

local function labelled(root, text)
	for _, d in ipairs(root:GetDescendants()) do
		if d:IsA("TextLabel") and d.Text == text then
			return d.Parent
		end
	end
	return nil
end

local UIS = game:GetService("UserInputService")
local function finger(x, y)
	return { UserInputType = Enum.UserInputType.Touch, Position = Vector3.new(x, y, 0), KeyCode = Enum.KeyCode.Unknown }
end
local function move(io, x, y)
	io.Position = Vector3.new(x, y, 0)
	UIS.TouchMoved:Fire(io, false)
end

local rec = { name = "FakeVR", path = PATH, threads = {}, conns = {}, insts = {}, instBorn = {}, cleanups = {}, stopping = false }
local scriptHub = core.makeEnv(rec).AtsukoHub
local layer
T.section("fakevr_phone: starts inside the hub and only uses the hub's ui")
local FV
do
	T.eq(type(scriptHub.UI), "table", "the hub hands scripts its ui")
	local before = #screens()
	local fn = loadstring(src, "=FakeVR")
	local ended
	AtsukoHub = scriptHub
	task.spawn(function()
		ended = { pcall(fn) }
	end)
	env.run(1)
	T.ok(ended and ended[1] == true, "FakeVR starts on a phone: " .. tostring(ended and ended[2]))
	FV = genv.AtsukoFakeVR
	T.eq(#screens(), before, "it makes no screen of its own")
	for _, g in ipairs(screens()) do
		T.ok(g.Name ~= "FakeVR", "no FakeVR screen")
	end
	layer = hub.Gui:FindFirstChild("ScriptLayer")
	T.ok(layer ~= nil, "its circles sit on a layer inside the hub's screen")
	T.eq(#rec.cleanups >= 2, true, "and the hub cleans up after it when the script stops")
	late = fdCamera()
	frames(20)
end

T.section("fakevr_phone: two arm circles in the middle of the screen, and nothing else in the way")
do
	local lpad, rpad = find(layer, "LeftPad"), find(layer, "RightPad")
	T.ok(lpad ~= nil and rpad ~= nil, "there is a circle for each arm")
	T.eq(lpad.Visible and rpad.Visible, true, "both show")
	local o = layer.AbsolutePosition
	T.ok(math.abs(lpad.Position.Y.Offset + o.Y - 360) < 1 and math.abs(rpad.Position.Y.Offset + o.Y - 360) < 1, "both sit in the middle of the screen, top to bottom")
	T.ok(lpad.Position.X.Offset < 320 and rpad.Position.X.Offset > 960, "the left one on the left side, the right one on the right side")
	T.eq(lpad.Size.X.Offset, lpad.Size.Y.Offset, "they are as wide as they are tall")
	local rc = lpad:FindFirstChildOfClass("UICorner")
	T.ok(rc ~= nil and rc.CornerRadius.Scale == 0.5, "and round")
	local pads = FV.pads()
	T.eq(lpad.Size.X.Offset, pads.Left.r * 2, "what you see is where you touch")
	local vp = workspace.CurrentCamera
	local real = vp.ViewportSize
	local clean = true
	local notes = {}
	for _, sz in ipairs({ { 1280, 720 }, { 812, 375 }, { 568, 320 }, { 667, 375 }, { 1024, 768 }, { 2048, 1536 }, { 390, 844 }, { 1920, 1080 } }) do
		local w, h = sz[1], sz[2]
		vp.ViewportSize = Vector2.new(w, h)
		for _, scale in ipairs({ 0.6, 1, 1.4 }) do
			FV.cfg.PadSize = scale
			local g = FV.pads()
			local L, R = g.Left, g.Right
			local small = math.min(w, h) <= 500
			local jx, jy, js = small and (w - 95) or (w - 170), small and (h - 90) or (h - 210), small and 70 or 120
			local function hitsBox(c, r, x0, y0, x1, y1)
				local px = math.clamp(c.X, x0, x1)
				local py = math.clamp(c.Y, y0, y1)
				return (Vector2.new(px, py) - c).Magnitude < r
			end
			local why
			if math.abs(L.c.Y - h / 2) > 0.5 or math.abs(R.c.Y - h / 2) > 0.5 then
				why = "not in the middle"
			elseif L.c.X - L.r < 0 or R.c.X + R.r > w or L.c.Y - L.r < 0 then
				why = "off the screen"
			elseif (R.c - L.c).Magnitude < L.r + R.r + 30 then
				why = "too close together"
			elseif L.c.X > w * 0.5 or R.c.X < w * 0.5 then
				why = "on the wrong side"
			elseif hitsBox(R.c, R.r, jx, jy, jx + js, jy + js) then
				why = "over the jump button"
			end
			if why then
				clean = false
				notes[#notes + 1] = w .. "x" .. h .. " at " .. scale .. ": " .. why
			end
		end
	end
	vp.ViewportSize = real
	FV.cfg.PadSize = 1
	T.ok(clean, "on every screen size and circle size they stay in the middle, apart, on the screen and clear of jump: " .. table.concat(notes, "; "))
	local big = 0
	for _, d in ipairs(layer:GetChildren()) do
		if d:IsA("GuiObject") and d.Visible then
			local sz = d.Size
			if sz and sz.X and sz.Y and sz.X.Scale >= 0.3 and sz.Y.Scale >= 0.3 then
				big += 1
			end
		end
	end
	T.eq(big, 0, "no big invisible frame steals touches")
	T.eq(type(api.blocker), "function", "FDless is told about the circles")
	T.eq(api.blocker(finger(pads.Right.c.X, pads.Right.c.Y)), true, "it leaves a finger in a circle to FakeVR")
	T.eq(api.blocker(finger(pads.Left.c.X, pads.Left.c.Y + pads.Left.r * 0.9)), true, "even the left circle, which is over the joystick area")
	T.eq(api.blocker(finger(150, 650)), false, "but never the joystick under it")
	T.eq(api.blocker(finger(640, 200)), false, "or the rest of the screen")
end

T.section("fakevr_phone: no buttons of its own, jump flies up")
do
	local buttons = {}
	for _, d in ipairs(layer:GetDescendants()) do
		if d:IsA("TextButton") and d.Name ~= "LeftPad" and d.Name ~= "RightPad" then
			buttons[#buttons + 1] = d.Name
		end
	end
	T.eq(#buttons, 0, "the circles are all it puts on the screen: " .. table.concat(buttons, ", "))
	FV.setFly(true)
	T.eq(FV.fly.on, true, "it flies")
	frames(10)
	local y0 = api.cframes[api.V.HumanoidRootPart].Position.Y
	for _ = 1, 20 do
		UIS.JumpRequest:Fire()
		frames(1)
	end
	local y1 = api.cframes[api.V.HumanoidRootPart].Position.Y
	T.ok(y1 > y0 + 0.5, "holding jump while flying goes up: " .. string.format("%.2f -> %.2f", y0, y1))
	FV.setFly(false)
	T.eq(FV.fly.on, false)
	FV.setSprint(true)
	T.eq(api.ws, 26, "sprint sprints")
	FV.setSprint(false)
	T.eq(api.ws, 16)
	frames(10)
end

T.section("fakevr_phone: a finger in a circle moves that arm and never the camera")
do
	local pads = FV.pads()
	local R, L = pads.Right, pads.Left
	api.yaw = 0
	local r = finger(R.c.X, R.c.Y)
	UIS.TouchStarted:Fire(r, true)
	T.eq(FV.hands.Right.grip, true, "a finger in the right circle lifts the right arm")
	T.eq(FV.hands.Left.grip, false, "and not the left one")
	T.eq(early.rotate, nil, "FDless doesn't take that finger for the camera when it hears it first")
	T.eq(late.rotate, nil, "or when FakeVR hears it first")
	T.eq(early.stick, nil, "and it isn't the joystick")
	frames(5)
	move(r, R.c.X + 40, R.c.Y + 20)
	T.eq(FV.hands.Right.screen.X, R.c.X + 40, "the arm follows the finger")
	move(r, R.c.X + 40, R.c.Y - 60)
	move(r, R.c.X - 30, R.c.Y + 50)
	move(r, R.c.X + 40, R.c.Y + 20)
	T.eq(api.yaw, 0, "sliding it around never turns the camera")
	T.eq(early.moves, 0, "and FDless never moves the camera for it")
	frames(1)
	local knob = find(find(layer, "RightPad"), "Knob")
	T.eq(knob.Visible, true, "a dot shows where the finger is")
	T.ok(knob.Position.X.Offset > 0 and knob.Position.Y.Offset > 0, "down and to the right, like the finger")
	local c = finger(640, 150)
	UIS.TouchStarted:Fire(c, false)
	T.eq(early.rotate, c, "a finger outside the circles turns the camera like always")
	T.eq(late.rotate, c)
	T.eq(FV.hands.Left.grip, false, "without moving an arm")
	move(c, 700, 160)
	T.ok(early.moves > 0 and late.moves > 0, "dragging it turns the camera")
	local stick = finger(150, 650)
	UIS.TouchStarted:Fire(stick, false)
	T.eq(early.stick, stick, "the joystick under the left circle still works")
	T.eq(late.stick, stick)
	T.eq(FV.hands.Left.grip, false, "and doesn't lift an arm")
	local l = finger(L.c.X, L.c.Y)
	UIS.TouchStarted:Fire(l, true)
	T.eq(FV.hands.Left.grip, true, "the left circle lifts the left arm")
	T.eq(early.stick, stick, "and is never the joystick")
	T.eq(early.zoom, nil, "nothing pinch zooms with both arms, the camera finger and the joystick down")
	T.eq(late.zoom, nil)
	local extra = finger(R.c.X + 10, R.c.Y)
	UIS.TouchStarted:Fire(extra, true)
	T.eq(FV.hands.Right.screen.X, R.c.X + 40, "a second finger on a busy circle does nothing")
	UIS.TouchEnded:Fire(extra, true)
	move(r, 200, R.c.Y)
	T.eq(FV.hands.Right.grip, true, "sliding the right finger all the way left keeps the right arm")
	T.eq(FV.hands.Left.screen.X, L.c.X, "and leaves the left arm to its own finger")
	UIS.TouchEnded:Fire(l, true)
	T.eq(FV.hands.Left.grip, false, "lifting a finger lowers its arm")
	UIS.TouchEnded:Fire(stick, false)
	UIS.TouchEnded:Fire(c, false)
	UIS.TouchEnded:Fire(r, true)
	T.eq(FV.hands.Right.grip, false)
	frames(1)
	T.eq(knob.Visible, false, "and the dot goes away")
	T.eq(api.yaw, 0, "the camera only ever turned from the finger outside the circles")
	frames(5)
end

T.section("fakevr_phone: throwing is lifting your finger, a flick throws harder")
do
	local R = FV.pads().Right
	local it
	for _, x in ipairs(FV.items) do
		if x.e == back.e then
			it = x
		end
	end
	T.ok(it ~= nil and FV.throwable(it), "the back accessory can be thrown")
	FV.summon(it, "Right")
	frames(60)
	T.eq(it.state, "held", "it is in the right hand")
	local r = finger(R.c.X, R.c.Y + 20)
	UIS.TouchStarted:Fire(r, true)
	frames(30)
	UIS.TouchEnded:Fire(r, true)
	T.eq(it.state, "free", "lifting the finger throws it")
	local slow = it.vel.Magnitude
	T.ok(slow > 15 and slow < 45, "a gentle toss when the finger wasn't moving: " .. string.format("%.1f", slow))
	FV.recall()
	frames(60)
	FV.summon(it, "Right")
	frames(60)
	T.eq(it.state, "held")
	local f = finger(R.c.X, R.c.Y + 50)
	UIS.TouchStarted:Fire(f, true)
	frames(20)
	now += 0.02
	move(f, R.c.X + 5, R.c.Y - 30)
	now += 0.02
	move(f, R.c.X + 10, R.c.Y - 140)
	now += 0.02
	UIS.TouchEnded:Fire(f, true)
	T.eq(it.state, "free", "a flick up throws it")
	T.ok(it.vel.Magnitude > 70, "much harder: " .. string.format("%.1f", it.vel.Magnitude))
	FV.recall()
	frames(60)
	T.eq(it.state, "home")
end

T.section("fakevr_phone: the menu is a hub window")
do
	local MENU = "smenu:" .. PATH
	local mb = hub.Scripts.menuBtn
	T.ok(mb ~= nil, "main scripts has a menu button")
	hub.Panel.show("scripts")
	env.run(0.5)
	T.eq(mb.btn.Visible, true, "it shows on main scripts while FakeVR runs")
	frames(1)
	T.eq(find(layer, "RightPad").Visible, false, "the circles step aside while the hub is open")
	mb.btn.Activated:Fire()
	env.run(0.5)
	local w = hub.Win.get(MENU)
	T.ok(w ~= nil, "it opens FakeVR's menu as a hub window")
	hub.Panel.hide()
	env.run(1)
	frames(1)
	T.eq(hub.Win.isOpen(MENU), true, "the window stays when the hub closes")
	T.eq(find(layer, "RightPad").Visible, false, "and the circles stay aside while it is open")
	T.eq(api.blocker(finger(FV.pads().Right.c.X, FV.pads().Right.c.Y)), false, "and don't take touches")
	local body = w.body
	local tabs = find(w.frame, "Tabs")
	T.ok(tabs ~= nil and withText(tabs, "Throw") ~= nil and withText(tabs, "Body") ~= nil, "two tabs: Throw and Body")
	local bringLabel = labelled(body, "Bring back")
	local bring = bringLabel and bringLabel.Parent
	T.ok(bring ~= nil and bring:IsA("TextButton"), "Throw has a bring back button")
	T.ok(labelled(body, "Head hats") ~= nil, "and the head hats switch")
	local row = labelled(body, "1.  Sword Pack")
	T.ok(row ~= nil, "and a row for the accessory you can throw")
	local it
	for _, x in ipairs(FV.items) do
		if x.e == back.e then
			it = x
		end
	end
	local rBtn = row and withText(row, "R")
	T.ok(rBtn ~= nil and withText(row, "L") ~= nil, "with L and R buttons")
	rBtn.Activated:Fire()
	env.run(0.2)
	frames(30)
	T.eq(it.hand, "Right", "R puts it in the right hand")
	FV.menu():refresh()
	T.eq(rBtn.BackgroundColor3 ~= withText(row, "L").BackgroundColor3, true, "and R lights up")
	bring.Activated:Fire()
	env.run(0.2)
	frames(60)
	T.eq(it.state, "home", "bring back puts it back")
	FV.menu():refresh()
	T.eq(rBtn.BackgroundColor3, withText(row, "L").BackgroundColor3, "and R goes dark again")
	withText(tabs, "Body").Activated:Fire()
	env.run(0.2)
	body = w.body
	T.eq(labelled(body, "1.  Sword Pack"), nil, "Body replaces the list")
	local legs = labelled(body, "Leg hats")
	T.ok(legs ~= nil, "Body has the leg hats")
	withText(legs, "Legs").Activated:Fire()
	T.eq(FV.cfg.Legs, "walk", "the leg hats can be legs")
	withText(legs, "Arms").Activated:Fire()
	T.eq(FV.cfg.Legs, "arms", "or two-rig arms again")
	local view = labelled(body, "View")
	withText(view, "Third").Activated:Fire()
	T.eq(FV.cfg.FirstPerson, false, "third person")
	withText(view, "First").Activated:Fire()
	T.eq(FV.cfg.FirstPerson, true, "first person")
	local flyRow = labelled(body, "Fly")
	T.ok(flyRow ~= nil and flyRow:IsA("TextButton"), "fly is a switch")
	flyRow.Activated:Fire()
	T.eq(FV.fly.on, true, "the switch flies")
	flyRow.Activated:Fire()
	T.eq(FV.fly.on, false, "and lands")
	for _, label in ipairs({ "Up/down distance", "Sideways distance", "Circle size", "Arm reach", "Throw power", "Smoothness", "Walk speed", "Sprint speed", "Fly speed" }) do
		local r = labelled(body, label)
		T.ok(r ~= nil and r.Name == "Slider", label .. " is a hub slider")
	end
	local ud = labelled(body, "Up/down distance")
	T.eq(find(ud, "Value").Text, "75°", "sliders show the value")
	FV.cfg.ArmUpDown = 60
	FV.menu():refresh()
	T.eq(find(ud, "Value").Text, "60°", "and follow it")
	FV.cfg.ArmUpDown = 75
	local circles = labelled(body, "Arm circles")
	T.ok(circles ~= nil, "the circles can be turned off")
	circles.Activated:Fire()
	T.eq(FV.cfg.TouchHands, false)
	w.closeBtn.Activated:Fire()
	env.run(0.5)
	frames(1)
	T.eq(hub.Win.isOpen(MENU), false, "the window's X closes it")
	local spot = FV.pads().Right.c
	local r = finger(spot.X, spot.Y)
	UIS.TouchStarted:Fire(r, false)
	T.eq(FV.hands.Right.grip, false, "with the circles off, touching there only turns the camera")
	UIS.TouchEnded:Fire(r, false)
	FV.cfg.TouchHands = true
	frames(1)
	T.eq(find(layer, "RightPad").Visible, true, "and the circles come back")
	T.ok(core.Dispatch ~= nil and core.Dispatch:has("vrhats"), "its commands are in the hub")
	core.Dispatch:run("vrhats", "", "ui")
	env.run(0.5)
	T.eq(hub.Win.isOpen(MENU), true, "vrhats opens the menu")
	core.Dispatch:run("vrhats", "", "ui")
	env.run(0.5)
	T.eq(hub.Win.isOpen(MENU), false, "and closes it")
end

T.section("fakevr_phone: stopping cleans up")
do
	frames(20)
	T.eq(#warned, 0, "no errors: " .. table.concat(warned, " | "))
	T.eq(#env.badProps, 0, "no bad properties: " .. table.concat(env.badProps, " | "))
	on = false
	env.run(1)
	T.eq(FV.alive(), false, "it stops with the reanimation")
	T.eq(layer.Parent, nil, "its circles go away")
	T.eq(core.topMenu(), nil, "and so does its menu")
	hub.Panel.show("scripts")
	env.run(0.5)
	T.eq(hub.Scripts.menuBtn.btn.Visible, false, "the menu button hides again")
	T.eq(api.blocker, nil, "and FDless gets its touches back")
	for i = #rec.cleanups, 1, -1 do
		pcall(rec.cleanups[i])
	end
	T.eq(#hub.Gui:GetChildren() > 0, true, "the hub's cleanup after a stopped script is harmless")
end

AtsukoHub = nil
warn = oldWarn
os.clock = realClock
