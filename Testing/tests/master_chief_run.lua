local World = loadmodule("Testing/mocks/rbx_world.lua")
local env = World.install({})
local makeApi = loadmodule("Testing/mocks/fake_fd.lua").make
local src = readsource("Scripts/Hat/MasterChief.lua")
_G.delay = function(t, f)
	return task.delay(t, f)
end

local function part(name, parent)
	local p = Instance.new("Part")
	p.Name = name
	p.Parent = parent
	return p
end
local function weld(a, b, parent)
	local w = Instance.new("Weld")
	w.Part0 = a
	w.Part1 = b
	w.Parent = parent
	return w
end
local function gun(name, bodyName)
	local m = Instance.new("Model")
	m.Name = name
	local body = part(bodyName, m)
	local eqp = part("eqp", m)
	local uneqp = part("uneqp", m)
	local hole = part("Hole", m)
	hole.Position = Vector3.new(0, 0, -3)
	local j2 = part("joint2", m)
	weld(j2, body, j2)
	weld(eqp, j2, eqp)
	weld(uneqp, j2, uneqp)
	weld(body, hole, body)
	return m
end
local pack = Instance.new("Model")
gun("rifle", "Handle").Parent = pack
gun("shotgun", "shotgun").Parent = pack
local shirt = Instance.new("Shirt")
shirt.Name = "s"
shirt.Parent = pack
local pants = Instance.new("Pants")
pants.Name = "p"
pants.Parent = pack
part("gren", pack)
local asked = {}
rawget(game, "_cm").GetObjects = function(_, id)
	asked[#asked + 1] = tostring(id)
	if string.find(tostring(id), "10170990440", 1, true) then
		return { pack }
	end
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
local mouse = { Hit = CFrame.new(5, 0, -20), Button1Down = Sig(), Button1Up = Sig(), KeyDown = Sig(), KeyUp = Sig() }
local lp = game:GetService("Players").LocalPlayer
rawget(lp, "_p").GetMouse = function()
	return mouse
end

local api, on = nil, false
local railgun, plunger, rock
_G.GenesisFDless = {
	reanimate = function()
		on = true
		api = makeApi()
		railgun = api.hat("Tactical Cyberpunk Railgun", "6774735978", "6774736019")
		plunger = api.hat("24k Gold Plunger", "15172160708", "15172162617")
		rock = api.hat("Elemental Crystal Golem Shoulder Rock", "4307568890", "4307568951")
		return api
	end,
	stopreanimate = function()
		on = false
	end,
	isReanimated = function()
		return on
	end,
}
local genv = env.genv
local toasts = {}
genv.AtsukoNotify = function(title, text, kind)
	toasts[#toasts + 1] = tostring(title) .. "|" .. tostring(text) .. "|" .. tostring(kind)
end

local function frames(n, watch)
	local seen = false
	for _ = 1, n do
		if api and api.modes.default then
			api.modes.default.idle()
		end
		env.frame()
		if watch and watch() then
			seen = true
		end
	end
	return seen
end
local function held()
	return api.ws == 0
end

T.section("master_chief_run: the whole script runs on the hub's reanimation")
local ended = nil
do
	local fn, cerr = loadstring(src, "=MasterChief")
	T.ok(fn ~= nil, "the shipped script compiles: " .. tostring(cerr))
	task.spawn(function()
		local ok, e = pcall(fn)
		ended = { ok, e }
	end)
	env.run(2)
	T.eq(ended, nil, "it keeps running")
	T.ok(api ~= nil and api.modes.default ~= nil, "it reanimated and follows the doll")
	frames(10)
	local MC = genv.AtsukoMasterChief
	T.ok(MC ~= nil, "the adapter is there")
	T.eq(MC.slots.rifle and MC.slots.rifle.e, railgun, "the railgun hat is the rifle")
	T.eq(MC.slots.shotgun and MC.slots.shotgun.e, plunger, "the gold plunger is the shotgun")
	T.eq(MC.slots.bullet and MC.slots.bullet.e, rock, "the rock is the bullet")
	T.ok(table.find(asked, "rbxassetid://10170990440") ~= nil, "the guns model was loaded")
	T.eq(asked[1], "rbxassetid://10170990440", "the guns model is the first thing asked for")
	T.eq(#asked, 1, "and the catalog guns are not looked up, the worn ones are known")
	local doll = MC.doll
	T.eq(doll:FindFirstChild("Animate"), nil, "the script took Animate away like before")
	T.eq(doll:FindFirstChildOfClass("Humanoid"):FindFirstChild("Animator"), nil, "and the Animator")
	T.ok(doll.Torso:FindFirstChild("ra") ~= nil and doll.Torso:FindFirstChild("la") ~= nil, "its arm welds are in the doll")
	T.ok(doll:FindFirstChild("rifle") ~= nil and doll:FindFirstChild("shotgun") ~= nil, "and both guns")
	T.ok(doll:FindFirstChild("effects lol") ~= nil, "and its effects folder")
	env.run(3)
	local said = table.concat(toasts, "\n")
	T.ok(string.find(said, "Master Chief|Master Chief by Helkern, converted by MelonScripter|info", 1, true) ~= nil, "the credit toast")
	T.ok(string.find(said, "Master Chief|Rifle: Tactical Cyberpunk Railgun  ·  Shotgun: 24k Gold Plunger|info", 1, true) ~= nil, "and which guns it found: " .. said)
end

T.section("master_chief_run: shooting, switching, the grenade, the dash and running")
do
	local MC = genv.AtsukoMasterChief
	mouse.Button1Down:Fire()
	T.ok(frames(40, held), "you stand still while the rifle shoots")
	mouse.Button1Up:Fire()
	frames(60)
	T.eq(api.ws, 16, "and walk again after")
	mouse.KeyDown:Fire("q")
	frames(40)
	mouse.Button1Down:Fire()
	T.ok(frames(60, held), "the shotgun holds you too")
	mouse.Button1Up:Fire()
	frames(90)
	mouse.KeyDown:Fire("z")
	frames(60)
	local before = #api.moved
	mouse.KeyDown:Fire("x")
	frames(30)
	T.ok(#api.moved > before, "X dashes forward through the reanimation")
	mouse.KeyDown:Fire("2")
	frames(5)
	T.eq(api.ws, 35, "2 runs")
	mouse.KeyDown:Fire("2")
	frames(5)
	T.eq(api.ws, 16, "and walks again")
	T.eq(ended, nil, "nothing broke the main loop")
	T.ok(MC.alive(), "still alive")
end

T.section("master_chief_run: stopping the reanimation ends the script")
do
	on = false
	env.run(1.5)
	T.ok(ended ~= nil and ended[1] == true, "the main loop ends on its own: " .. tostring(ended and ended[2]))
	T.eq(genv.AtsukoAlign, nil, "the alignment window lets go")
	T.eq(genv.AtsukoMasterChief.alive(), false)
end

T.section("master_chief_run: when Roblox sends no guns model, the stand-in is used and everything still works")
do
	rawget(game, "_cm").GetObjects = function(_, id)
		asked[#asked + 1] = tostring(id)
		return {}
	end
	toasts = {}
	ended = nil
	local fn = loadstring(src, "=MasterChief")
	task.spawn(function()
		local ok, e = pcall(fn)
		ended = { ok, e }
	end)
	env.run(9)
	T.eq(ended, nil, "it keeps running")
	local MC = genv.AtsukoMasterChief
	T.eq(MC.standIn, true, "on the stand-in")
	frames(10)
	T.eq(MC.slots.rifle and MC.slots.rifle.e, railgun, "the railgun is still the rifle")
	T.eq(MC.slots.shotgun and MC.slots.shotgun.e, plunger, "and the plunger the shotgun")
	local said = table.concat(toasts, "\n")
	T.ok(string.find(said, "Roblox didn't send the gun models (nothing came back)", 1, true) ~= nil, "the toast says why: " .. said)
	T.eq(string.find(said, "GetObjects didn't work", 1, true), nil, "and doesn't blame the executor")
	mouse.Button1Down:Fire()
	T.ok(frames(40, held), "the rifle shoots")
	mouse.Button1Up:Fire()
	frames(60)
	mouse.KeyDown:Fire("q")
	frames(40)
	mouse.Button1Down:Fire()
	T.ok(frames(60, held), "the shotgun shoots")
	mouse.Button1Up:Fire()
	frames(90)
	mouse.KeyDown:Fire("z")
	frames(60)
	T.eq(ended, nil, "nothing broke")
	on = false
	env.run(1.5)
	T.ok(ended ~= nil and ended[1] == true, "and it ends cleanly")
	_G.GenesisFDless = nil
	_G.delay = nil
end
