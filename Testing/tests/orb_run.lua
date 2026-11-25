local World = loadmodule("Testing/mocks/rbx_world.lua")
local env = World.install({})
CFrame = loadmodule("Testing/mocks/cframe_math.lua").make(Vector3)
local makeApi = loadmodule("Testing/mocks/fake_fd.lua").make
local src = readsource("Scripts/Hat/FDless/RealityOrbGlitcher.lua")
math.acos = math.acos or function(x)
	x = math.max(-1, math.min(1, x))
	return math.atan2(math.sqrt(1 - x * x), x)
end
_G.delay = function(t, f)
	return task.delay(t, f)
end

local UTILITY = [[
return { Create = function(class)
	return function(props)
		local o = Instance.new(class)
		for k, v in pairs(props) do
			if k ~= "Parent" then
				o[k] = v
			end
		end
		if props.Parent then
			o.Parent = props.Parent
		end
		return o
	end
end }
]]
local fetched = {}
env.http = function(url)
	fetched[#fetched + 1] = tostring(url)
	if string.find(tostring(url), "RbxUtility", 1, true) then
		return UTILITY
	end
	return nil
end
local asked = {}
rawget(game, "_cm").GetObjects = function(_, id)
	asked[#asked + 1] = tostring(id)
	return {}
end

local function Sig()
	local s = { list = {} }
	function s:Connect(f)
		local c = { on = true }
		function c.Disconnect()
			c.on = false
		end
		self.list[#self.list + 1] = { f = f, c = c }
		return c
	end
	s.connect = s.Connect
	function s:Fire(...)
		for _, item in ipairs(self.list) do
			if item.c.on then
				task.spawn(item.f, ...)
			end
		end
	end
	return s
end
local mouse = { Hit = CFrame.new(5, 0, -20), Target = nil, Button1Down = Sig(), Button1Up = Sig(), KeyDown = Sig(), KeyUp = Sig(), Move = Sig() }
local lp = game:GetService("Players").LocalPlayer
rawget(lp, "_p").GetMouse = function()
	return mouse
end

local api, on, sawAligns = nil, false, nil
local hats = {}
local genv = env.genv
_G.GenesisFDless = {
	reanimate = function()
		on = true
		sawAligns = genv.AtsukoScriptAligns
		api = makeApi()
		for i, name in ipairs({ "Cool Hat", "Hair", "Wings" }) do
			local e, j = api.hat(name, tostring(9000 + i), tostring(9100 + i))
			j.C1 = CFrame.new(0, 0.6, 0)
			hats[#hats + 1] = { e = e, j = j }
		end
		local limbHat, limbJoint = api.hat("Arm Hat", "14255522247", "")
		limbJoint.Part1 = api.V["Right Arm"]
		hats.limb = { e = limbHat, j = limbJoint }
		return api
	end,
	stopreanimate = function()
		on = false
	end,
	isReanimated = function()
		return on
	end,
}
local toasts = {}
genv.AtsukoNotify = function(title, text, kind)
	toasts[#toasts + 1] = tostring(title) .. "|" .. tostring(text) .. "|" .. tostring(kind)
end

local function frames(n)
	for _ = 1, n do
		if api and api.modes.default then
			api.modes.default.idle()
		end
		env.frame()
	end
end

T.section("orb_run: the script runs on the hub's reanimation")
local ended = nil
do
	T.eq(string.find(src, "pepfre12", 1, true), nil, "it no longer downloads its own reanimate")
	T.ok(string.find(src, "script=reanimation.assets(106767142974276)", 1, true) ~= nil, "its effects load through the bridge")
	T.ok(string.find(src, "FDless.orbAt(sorb)", 1, true) ~= nil, "the bridge knows where the orb is")
	local fn, cerr = loadstring(src, "=RealityOrbGlitcher")
	T.ok(fn ~= nil, "the shipped script compiles: " .. tostring(cerr))
	task.spawn(function()
		local ok, e = pcall(fn)
		ended = { ok, e }
	end)
	env.run(2)
	T.eq(ended, nil, "it keeps running: " .. tostring(ended and ended[2]))
	T.ok(api ~= nil and api.modes.default ~= nil, "it reanimated and follows its body every frame")
	T.ok(type(sawAligns) == "table" and #sawAligns >= 20, "it handed the reanimation its own limb hats")
	T.eq(sawAligns and sawAligns[1].PartName, "Left Arm")
	T.eq(genv.AtsukoScriptAligns, nil, "and put the list back afterwards")
	T.ok(#asked >= 1 and string.find(asked[1], "106767142974276", 1, true) ~= nil, "it asked Roblox for its effects")
	local warned = false
	for _, t in ipairs(toasts) do
		if string.find(t, "plain ones", 1, true) then
			warned = true
		end
	end
	T.ok(warned, "and says so when they didn't load")
end

T.section("orb_run: its body moves the hats")
do
	local rig = nil
	for _, d in ipairs(workspace:GetChildren()) do
		if d.ClassName == "Model" and d:FindFirstChild("HumanoidRootPart") and d ~= lp.Character then
			rig = d
		end
	end
	T.ok(rig ~= nil, "it has a body to animate")
	T.eq(rig and rig:FindFirstChild("HumanoidRootPart").Anchored, true, "the body's root follows the reanimation")
	T.eq(rig and rig:FindFirstChild("Torso"):FindFirstChild("Right Shoulder").ClassName, "Weld", "the script swapped the shoulders for its own welds")
	local before = api.getJoint("Right Shoulder").C0
	api.vel = Vector3.new(0, 30, 0)
	frames(60)
	local after = api.getJoint("Right Shoulder").C0
	local rw = rig:FindFirstChild("Torso"):FindFirstChild("Right Shoulder")
	T.ok(rw.C0.UpVector:Dot(Vector3.new(0, 1, 0)) < 0.999, "jumping swings the script's arm")
	T.ok(after.UpVector:Dot(before.UpVector) < 0.999, "and the arm pose reaches the reanimation")
	api.vel = Vector3.new()
	api.cframes[api.V.HumanoidRootPart] = CFrame.new(10, 3, 0)
	frames(2)
	T.ok((rig:FindFirstChild("HumanoidRootPart").CFrame.Position - Vector3.new(10, 3, 0)).Magnitude < 0.01, "the body stands where the reanimation is")
	api.vel = Vector3.new(16, 0, 0)
	frames(2)
	T.ok((rig:FindFirstChild("HumanoidRootPart").Velocity - Vector3.new(16, 0, 0)).Magnitude < 0.01, "and moves as fast, so it walks")
	api.vel = Vector3.new()
	local moved = #api.moved
	rig:FindFirstChild("HumanoidRootPart").CFrame = CFrame.new(20, 3, 0)
	frames(1)
	T.ok(#api.moved > moved, "a dash from the script moves the reanimation")
	T.ok((api.cframes[api.V.HumanoidRootPart].Position - Vector3.new(20, 3, 0)).Magnitude < 0.01)
	rig:FindFirstChildOfClass("Humanoid").WalkSpeed = 0
	frames(1)
	T.eq(api.ws, 0, "standing still for an attack holds the reanimation too")
	rig:FindFirstChildOfClass("Humanoid").WalkSpeed = 16
	frames(1)
	T.eq(api.ws, 16)
end

T.section("orb_run: the orb is made of your hats")
do
	frames(40)
	local around = 0
	for _, h in ipairs(hats) do
		if h.j.Part1 == api.V.HumanoidRootPart then
			around += 1
		end
	end
	T.eq(around, #hats, "every hat you wear joins the orb")
	T.eq(hats.limb.j.Part1, api.V["Right Arm"], "a hat that is an arm stays an arm")
	local spots = {}
	for _, h in ipairs(hats) do
		local cf = api.cframes[api.V.HumanoidRootPart] * h.j.C1
		spots[#spots + 1] = cf.Position
	end
	T.ok((spots[1] - spots[2]).Magnitude > 0.5, "they spread around the orb instead of stacking")
	local was = hats[1].j.C1
	frames(5)
	T.ok(hats[1].j.C1 ~= was, "and keep spinning")
end

T.section("orb_run: the orb can be moved in the hub's alignment window")
do
	local AL = genv.AtsukoAlign
	T.ok(AL ~= nil and AL.title == "Reality Orb Glitcher", "it publishes an alignment adapter")
	T.same(AL.tabs, { "Orb" }, "with one tab for the orb")
	T.ok(string.find(AL.found(), "3 hats", 1, true) ~= nil, "it says how many hats make the orb: " .. AL.found())
	local function middle()
		local sum = Vector3.new()
		for _, h in ipairs(hats) do
			sum = sum + (api.cframes[api.V.HumanoidRootPart] * h.j.C1).Position
		end
		return sum / #hats
	end
	frames(2)
	local low = middle()
	T.eq(AL.set(1, 2, 3), 3, "moving it up")
	frames(2)
	T.ok(middle().Y - low.Y > 2, "lifts the whole ball of hats")
	AL.reset(1)
	frames(2)
	T.ok(math.abs(middle().Y - low.Y) < 1.5, "and reset puts it back")
	T.eq(AL.hat(1), nil, "no single hat to line up")
end

T.section("orb_run: stopping gives the hats back")
T.eq(ended, nil, "the script kept running the whole time: " .. tostring(ended and ended[2]))
do
	on = false
	frames(3)
	for _, h in ipairs(hats) do
		T.eq(h.j.Part1, api.V.Head, "each hat goes back on its head")
		T.eq(h.j.C1, CFrame.new(0, 0.6, 0))
	end
	T.eq(genv.AtsukoAlign, nil, "and the alignment window lets go of it")
end
