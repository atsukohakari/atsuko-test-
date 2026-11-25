local genv = (typeof(getgenv) == "function" and getgenv()) or _G
local Uhh = genv.AtsukoUhh
if type(Uhh) ~= "table" or (tonumber(Uhh.version) or 0) < 1 then
	local base = type(genv.AtsukoHubRaw) == "string" and genv.AtsukoHubRaw or "https://raw.githubusercontent.com/atsukohakari/Atsuko/main/"
	local ok, src = pcall(function()
		if type(genv.AtsukoHubRead) == "function" then
			local got = genv.AtsukoHubRead("Hub/UhhMoveset.lua")
			if got or genv.AtsukoHubLocal then
				return got
			end
		end
		return game:HttpGet(base .. "Hub/UhhMoveset.lua")
	end)
	local fn = ok and type(src) == "string" and loadstring(src, "=UhhMoveset")
	Uhh = fn and select(2, pcall(fn)) or nil
	if type(Uhh) ~= "table" then
		warn("[Linked Sword] couldn't load Hub/UhhMoveset.lua")
		return
	end
end

local U = Uhh.new({
	title = "Linked Sword",
	short = "ls",
	jobs = { { "sword", "Sword" }, { "gun", "Bazooka" }, { "bullet", "Bullet" } },
	groups = { Sword = "sword", Gun = "gun", Bullet = "bullet" },
	need = "sword",
	hint = "Sword moves the blade, Bazooka moves the rocket launcher, Bullet moves the hat that rides the rocket.",
	global = "AtsukoLinkedSword",
})
if not U then
	return
end

local cloneref = cloneref or function(o)
	return o
end
local Debris = cloneref(game:GetService("Debris"))
local Players = cloneref(game:GetService("Players"))
local UserInputService = cloneref(game:GetService("UserInputService"))

local Player = Players.LocalPlayer
local RandomString = U.RandomString
local Util_CreateSwitch = U.Util_CreateSwitch
local HatReanimator = U.HatReanimator
local ReanimateFling = U.ReanimateFling
local OnPlayerChatted = U.OnPlayerChatted
local ContextActions = U.ContextActions

local function SetC0C1Joint(j, c0, c1, scale)
	local t = c0 * c1:Inverse()
	t += t.Position * (scale - 1)
	t = j.C0:Inverse() * t * j.C1
	j.Transform = t
end

local function AddModule(m)
	U.add(m)
end
local flight, scale, freezemove

local LINKEDSWORD_HATMAP_BALL = table.concat({
	"6504654865, 6504654926, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1",
	"86886965670625, 135572356789218, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1",
	"",
}, "|")
local LINKEDSWORD_HATMAP_BOMB = table.concat({
	"15925622812, 15925622912, 0, -0.5, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1",
	"129579447344786, 107080893806835, 0, -0.225616, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1",
	"",
}, "|")

AddModule(function()
	local m = {}
	m.ModuleType = "MOVESET"
	m.Name = "Linked Sword"
	m.InternalName = "SORETROGUY"
	m.Description = "He has been fighting since 2006!\nM1 - Linked Sword\nZ - Superball\nX - Rocket Launcher\nC - Timebomb"
	m.Assets = {}

	m.Notifications = true
	m.Sounds = true
	m.NoCooldown = false
	m.IgnoreDancing = false
	m.HitboxDebug = false
	m.Config = function(parent)
		Util_CreateSwitch(parent, "Dialog", m.Notifications).Changed:Connect(function(val)
			m.Notifications = val
		end)
		Util_CreateSwitch(parent, "Sounds", m.Sounds).Changed:Connect(function(val)
			m.Sounds = val
		end)
		Util_CreateSwitch(parent, "No Cooldown", m.NoCooldown).Changed:Connect(function(val)
			m.NoCooldown = val
		end)
		Util_CreateSwitch(parent, "Ignore Dancing", m.IgnoreDancing).Changed:Connect(function(val)
			m.IgnoreDancing = val
		end)
		Util_CreateSwitch(parent, "Hitbox Visual", m.HitboxDebug).Changed:Connect(function(val)
			m.HitboxDebug = val
		end)
	end
	m.LoadConfig = function(save)
		m.Notifications = not save.Blind
		m.Sounds = not save.Muted
		m.NoCooldown = not not save.NoCooldown
		m.IgnoreDancing = not not save.IgnoreDancing
		m.HitboxDebug = not not save.HitboxDebug
	end
	m.SaveConfig = function()
		return {
			Blind = not m.Notifications,
			Muted = not m.Sounds,
			NoCooldown = m.NoCooldown,
			IgnoreDancing = m.IgnoreDancing,
			HitboxDebug = m.HitboxDebug,
		}
	end

	local start = 0
	local hum, root, torso
	local isdancing = false
	local rcp = RaycastParams.new()
	rcp.FilterType = Enum.RaycastFilterType.Exclude
	rcp.IgnoreWater = true
	local function PhysicsRaycast(origin, direction)
		rcp.RespectCanCollide = true
		return workspace:Raycast(origin, direction, rcp)
	end
	local function ShootRaycast(origin, direction)
		rcp.RespectCanCollide = false
		return workspace:Raycast(origin, direction, rcp)
	end
	local mouse = Player:GetMouse()
	local function MouseHit()
		local Camera = workspace.CurrentCamera
		local ray = mouse.UnitRay
		if UserInputService.TouchEnabled and Camera then
			local pos = Camera.ViewportSize * Vector2.new(0.5, 0.3)
			ray = Camera:ViewportPointToRay(pos.X, pos.Y, 1e-6)
		end
		local dist = 2000
		local raycast = ShootRaycast(ray.Origin, ray.Direction * dist)
		if raycast then
			return raycast.Position
		end
		return ray.Origin + ray.Direction * dist
	end
	local function CreateSound(id, pitch, extra)
		if not m.Sounds then return end
		if not torso then return end
		local parent = torso
		local volume = extra or 1
		if typeof(id) == "Instance" then
			parent = id
			id, pitch = pitch, extra
			volume = 1
		end
		pitch = pitch or 1
		local sound = Instance.new("Sound")
		sound.Name = tostring(id)
		sound.SoundId = id:find("://") and id or "rbxassetid://" .. id
		sound.Volume = volume
		sound.Pitch = pitch
		sound.Parent = parent
		sound.EmitterSize = 300
		sound:Play()
		sound.Ended:Connect(function()
			sound:Destroy()
		end)
	end
	local function AimTowards(target)
		if not root then return end
		if flight then return end
		local tcf = CFrame.lookAt(root.Position, target)
		local _,off,_ = root.CFrame:ToObjectSpace(tcf):ToEulerAngles(Enum.RotationOrder.YXZ)
		root.AssemblyAngularVelocity = Vector3.new(0, off, 0) * 60
	end
	local function Attack(cf, size)
		if m.HitboxDebug then
			local hitvis = Instance.new("Part")
			hitvis.Name = RandomString()
			hitvis.CastShadow = false
			hitvis.Material = Enum.Material.ForceField
			hitvis.Anchored = true
			hitvis.CanCollide = false
			hitvis.CanTouch = false
			hitvis.CanQuery = false
			hitvis.Shape = Enum.PartType.Block
			hitvis.Color = Color3.new(0, 0, 0)
			hitvis.Size = size
			hitvis.CFrame = cf
			hitvis.Parent = workspace
			Debris:AddItem(hitvis, 1)
		end
		local hashmap = {}
		local parts = workspace:GetPartBoundsInBox(cf, size)
		for _,part in parts do
			if part.Parent then
				local hum = part.Parent:FindFirstChildOfClass("Humanoid")
				if hum and hum.RootPart and not hum.RootPart:IsGrounded() then
					if ReanimateFling(part.Parent) then
						hashmap[hum.RootPart] = true
					end
				end
			end
		end
		local hitstuff = {}
		for k,_ in hashmap do
			table.insert(hitstuff, k)
		end
		return hitstuff
	end
	local function notify(message)
		if not m.Notifications then return end
		if not root or not torso then return end
		local dialog = torso:FindFirstChild("NOTIFICATION")
		if dialog then
			dialog:Destroy()
		end
		dialog = Instance.new("BillboardGui", torso)
		dialog.Size = UDim2.new(50 * scale, 0, 2 * scale, 0)
		dialog.StudsOffset = Vector3.new(0, 5 * scale, 0)
		dialog.Adornee = torso
		dialog.Name = "NOTIFICATION"
		local text = Instance.new("TextLabel", dialog)
		text.BackgroundTransparency = 1
		text.BorderSizePixel = 0
		text.Text = ""
		text.Font = "Cartoon"
		text.TextScaled = true
		text.TextStrokeTransparency = 0
		text.TextStrokeColor3 = Color3.new(0, 0, 0)
		text.Size = UDim2.new(1, 0, 1, 0)
		text.ZIndex = 0
		text.TextColor3 = Color3.new(1, 1, 1)
		task.spawn(function()
			local cps = 20
			local t = os.clock()
			local ll = 0
			repeat
				task.wait()
				local l = math.floor((os.clock() - t) * cps)
				if l > ll then
					ll = l
					if math.random(3) == 1 then
						CreateSound("rbxasset://sounds/plasticplastic.ogg")
					else
						CreateSound("rbxasset://sounds/plasticplastic" .. math.random(2, 3) .. ".ogg")
					end
				end
				text.Text = string.sub(message, 1, l)
			until ll >= #message or dialog.Parent ~= torso
			text.Text = message
			t = os.clock()
			repeat
				task.wait()
			until os.clock() - t > 2
			t = os.clock()
			repeat
				task.wait()
				local a = os.clock() - t
				text.TextTransparency = a
				text.TextStrokeTransparency = a
			until os.clock() - t > 1
			dialog:Destroy()
		end)
	end
	local function randomdialog(arr)
		notify(arr[math.random(1, #arr)])
	end
	local chatconn
	local joints = {
		r = CFrame.identity,
		n = CFrame.identity,
		rs = CFrame.identity,
		ls = CFrame.identity,
		rh = CFrame.identity,
		lh = CFrame.identity,
		sw = CFrame.identity,
	}
	local sword = {}
	local rocket = {}
	local superball = {}
	local timebomb = {}
	local bullet = {}
	local attacking = false
	local timingsine = 0
	local animationOverride = nil
	local swordoff = CFrame.new(0, 1, 0) * CFrame.Angles(0, math.rad(90), 0)
	local lerps = {
		idle = function(timingsine, rt, nt, rst, lst, rht, lht)
			rt = CFrame.new(-0.014, 0.023, 0.020, 0.866, 0, -0.5, 0, 1, 0, 0.5, 0, 0.866) * CFrame.new(0, 0.05 * math.cos(timingsine / 25), 0)
			nt = CFrame.new(0, 1.499, 0, 0.886, 0, 0.462, 0, 1, 0, -0.462, 0, 0.886) * CFrame.Angles(0.08 * math.cos(timingsine / 25), 0, 0)
			rst = CFrame.new(1.7, 0.169, 0.31, 0.827, -0.251, -0.501, 0.215, 0.967, -0.13, 0.517, 0, 0.855) * CFrame.Angles(math.rad(2 * math.cos(timingsine / 25)), 0, 0)
			lst = CFrame.new(-1.619, 0.059, 0, 0.981, 0.191, 0, -0.191, 0.981, 0, 0, 0, 1) * CFrame.Angles(0, 0, math.rad(-2 * math.cos(timingsine / 25)))
			rht = CFrame.new(0.649, -1.999, 0, 0.989, -0.143, 0, 0.143, 0.989, 0, 0, 0, 1) * CFrame.new(0, -0.08 * math.cos(timingsine / 25), 0) * CFrame.Angles(0, 0, 0.01 * math.cos(timingsine / 25))
			lht = CFrame.new(-0.5, -2, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) * CFrame.new(0, -0.08 * math.cos(timingsine / 25), 0)
			return rt, nt, rst, lst, rht, lht, 16
		end,
		walk = function(timingsine, rt, nt, rst, lst, rht, lht)
			rt = CFrame.new(-0.014, 0.023, 0.020, 1, 0, 0, 0, 1, 0, 0, 0, 1) * CFrame.Angles(-0.2, math.rad(-10 * math.cos(timingsine / 6)/2), 0)
			nt = CFrame.new(0, 1.499, 0, 0.999, 0, -0.042, 0, 1, 0, 0.042, 0, 0.999)
			rst = CFrame.new(1.668, 0.125, 0.167, 0.975, -0.217, -0.034, 0.22, 0.967, 0.121, 0.006, -0.125, 0.992) * CFrame.new(0, 0, 0.2 * math.cos(timingsine / 6)/2) * CFrame.Angles(math.rad(-30 * math.cos(timingsine / 6)/2), 0, 0)
			lst = CFrame.new(-1.589, 0.026, -0.146, 0.986, 0.166, -0.008, -0.166, 0.981, -0.095, -0.008, 0.095, 0.995) * CFrame.new(0, 0, -0.3 * math.cos(timingsine / 6)/2) * CFrame.Angles(math.rad(30 * math.cos(timingsine / 6)/2), 0, 0)
			rht = CFrame.new(0.5, -1.64 - 0.8 * math.cos(timingsine / 6) / 2, 2 * math.sin(timingsine / 6) / 3) * CFrame.Angles(math.rad(-50 * math.sin(timingsine / 6)), math.rad(-3), 0)
			lht = CFrame.new(-0.5, -1.64 + 0.8 * math.cos(timingsine / 6) / 2, - 2 * math.sin(timingsine / 6) / 3) * CFrame.Angles(math.rad(50 * math.sin(timingsine / 6)), math.rad(3), 0)
			return rt, nt, rst, lst, rht, lht, 16
		end,
		jump = function(timingsine, rt, nt, rst, lst, rht, lht)
			rt = CFrame.new(-0.014, 0.023, 0.020, 1, 0, 0, 0, 0.965, 0.258, 0, -0.258, 0.965)
			nt = CFrame.new(0.017, 1.545, -0.003, 0.999, 0.007, -0.042, -0.011, 0.996, -0.086, 0.041, 0.087, 0.995)
			rst = CFrame.new(1.54, 0.254, -0.521, 0.89, -0.152, -0.429, -0.327, 0.44, -0.835, 0.317, 0.884, 0.341)
			lst = CFrame.new(-1.557, 0.112, 0.343, 0.986, 0.113, 0.122, -0.158, 0.861, 0.481, -0.050, -0.494, 0.867)
			rht = CFrame.new(0.566, -1.597, -0.481, 0.999, -0.038, -0.009, 0.039, 0.943, 0.328, -0.003, -0.328, 0.944)
			lht = CFrame.new(-0.433, -1.959, 0.005, 1, 0, 0, 0, 0.965, 0.258, 0, -0.258, 0.965)
			return rt, nt, rst, lst, rht, lht, 16
		end,
		fall = function(timingsine, rt, nt, rst, lst, rht, lht)
			rt = CFrame.new(-0.014, 0.023, 0.020, 1, 0, 0, 0, 0.984, 0.173, 0, -0.173, 0.984)
			nt = CFrame.new(0.015, 1.552, -0.091, 0.999, 0.018, -0.038, -0.007, 0.965, 0.258, 0.042, -0.258, 0.965)
			rst = CFrame.new(1.44, 0.051, -0.418, 0.89, -0.076, -0.449, -0.298, 0.647, -0.701, 0.344, 0.758, 0.553)
			lst = CFrame.new(-1.557, 0.141, 0.332, 0.986, 0.113, 0.122, -0.162, 0.815, 0.555, -0.036, -0.567, 0.822)
			rht = CFrame.new(0.573, -1.805, -0.374, 0.999, -0.037, 0.013, 0.039, 0.981, -0.187, -0.006, 0.188, 0.982)
			lht = CFrame.new(-0.433, -1.951, 0.175, 1, 0, 0, 0, 0.984, 0.173, 0, -0.173, 0.984)
			return rt, nt, rst, lst, rht, lht, 16
		end,
		sword1 = function(timingsine, rt, nt, rst, lst, rht, lht)
			rt = CFrame.new(-0.014, 0.023, 0.020, 0, 0, 1, 0, 1, 0, -1, 0, 0)
			nt = CFrame.new(0, 1.499, 0, 0.462, 0, -0.886, 0, 1, 0, 0.886, 0, 0.462)
			rst = CFrame.new(1.599, 0.488, -0.46, 0.695, -0.716, 0.044, 0.047, -0.016, -0.998, 0.716, 0.696, 0.022)
			lst = CFrame.new(-1.804, 0.308, 0.006, 0.864, 0.492, 0.101, -0.498, 0.865, 0.047, -0.064, -0.091, 0.993)
			rht = CFrame.new(0.45, -1.874, 0.242, 0.938, 0.182, -0.292, -0.024, 0.881, 0.471, 0.343, -0.434, 0.832)
			lht = CFrame.new(-0.463, -2, -0.403, 0.766, 0, -0.642, 0, 1, 0, 0.642, 0, 0.766)
			return rt, nt, rst, lst, rht, lht, 16
		end,
		sword2 = function(timingsine, rt, nt, rst, lst, rht, lht)
			rt = CFrame.new(-0.014, 0.023, 0.020, 0, 0, 1, 0, 1, 0, -1, 0, 0)
			nt = CFrame.new(0, 1.499, 0, 0.462, 0, -0.886, 0, 1, 0, 0.886, 0, 0.462)
			rst = CFrame.new(1.599, 0.488, -0.46, 0.695, -0.716, 0.044, 0.047, -0.016, -0.998, 0.716, 0.696, 0.022)
			lst = CFrame.new(-1.804, 0.308, 0.006, 0.864, 0.492, 0.101, -0.498, 0.865, 0.047, -0.064, -0.091, 0.993)
			rht = CFrame.new(0.45, -1.874, 0.242, 0.938, 0.182, -0.292, -0.024, 0.881, 0.471, 0.343, -0.434, 0.832)
			lht = CFrame.new(-0.463, -2, -0.403, 0.766, 0, -0.642, 0, 1, 0, 0.642, 0, 0.766)
			return rt, nt, rst, lst, rht, lht, 16
		end,
		sword3 = function(timingsine, rt, nt, rst, lst, rht, lht)
			rt = CFrame.new(0.199, 0, -0.062, 0.5, 0, 0.866, 0, 1, 0, -0.866, 0, 0.5)
			nt = CFrame.new(0, 1.499, 0, 0.866, 0, -0.499, 0, 1, 0, 0.499, 0, 0.866)
			rst = CFrame.new(0.93, 0.25, -1.281, -0.038, 0.569, -0.821, -0.998, 0.006, 0.051, 0.034, 0.822, 0.568)
			lst = CFrame.new(-1.602, 0.027, -0.076, 0.014, 0.129, 0.991, 0.224, 0.965, -0.129, -0.974, 0.224, -0.014)
			rht = CFrame.new(0.624, -1.999, -0.012, 0.707, 0, -0.707, 0, 1, 0, 0.707, 0, 0.707)
			lht = CFrame.new(-0.482, -1.999, -0.129, 0.707, 0, 0.707, 0, 1, 0, -0.707, 0, 0.707)
			return rt, nt, rst, lst, rht, lht, 16
		end,
		sword4 = function(timingsine, rt, nt, rst, lst, rht, lht)
			rt = CFrame.new(0.366, 0, -0.414, 0.258, 0, 0.965, 0, 1, 0, -0.965, 0, 0.258)
			nt = CFrame.new(0, 1.499, 0, 0.342, 0, -0.939, 0, 1, 0, 0.939, 0, 0.342)
			rst = CFrame.new(0.055, 1.357, -1.17, 0.785, 0.559, 0.265, 0.545, -0.827, 0.13, 0.293, 0.042, -0.955)
			lst = CFrame.new(-1.602, 0.027, -0.076, 0.014, 0.129, 0.991, 0.224, 0.965, -0.129, -0.974, 0.224, -0.014)
			rht = CFrame.new(0.624, -1.999, -0.012, 0.707, 0, -0.707, 0, 1, 0, 0.707, 0, 0.707)
			lht = CFrame.new(-0.482, -1.999, -0.129, 0.707, 0, 0.707, 0, 1, 0, -0.707, 0, 0.707)
			return rt, nt, rst, lst, rht, lht, 16
		end,
		sword5 = function(timingsine, rt, nt, rst, lst, rht, lht)
			rt = CFrame.new(0.366, -0.2, -0.414, 0.582, 0.271, 0.766, -0.422, 0.906, 0, -0.694, -0.323, 0.642)
			nt = CFrame.new(-0.231, 1.547, -0.051, 0.851, -0.422, -0.309, 0.397, 0.906, -0.144, 0.342, 0, 0.939)
			rst = CFrame.new(-0.090, 1.165, -1.088, -0.077, 0.583, 0.808, 0.727, -0.521, 0.446, 0.681, 0.622, -0.384)
			lst = CFrame.new(-1.612, 0.036, 0.314, -0.455, 0.169, 0.873, 0.034, 0.984, -0.172, -0.889, -0.048, -0.454)
			rht = CFrame.new(1.211, -1.348, -0.183, 0.851, -0.252, -0.459, 0.397, 0.882, 0.252, 0.342, -0.397, 0.851)
			lht = CFrame.new(0.058, -1.958, 0.369, 0.64, -0.422, 0.64, 0.298, 0.906, 0.298, -0.707, 0, 0.707)
			return rt, nt, rst, lst, rht, lht, 16
		end,
		sword6 = function(timingsine, rt, nt, rst, lst, rht, lht)
			rt = CFrame.new(0.366, -1.199, -0.414, 0.582, -0.412, 0.7, -0.422, 0.582, 0.694, -0.694, -0.7, 0.165)
			nt = CFrame.new(0.112, 1.566, 0.254, 0.577, 0.099, -0.81, -0.213, 0.976, -0.031, 0.787, 0.191, 0.585)
			rst = CFrame.new(1.968, 0.746, -0.185, 0.076, -0.997, 0.006, 0.879, 0.064, -0.47, 0.469, 0.041, 0.882)
			lst = CFrame.new(-1.881, 0.136, 0.177, -0.455, 0.778, 0.432, 0.703, 0.612, -0.36, -0.545, 0.139, -0.826)
			rht = CFrame.new(0.901, -1.146, -0.653, 0.851, 0.19, -0.488, -0.006, 0.935, 0.352, 0.524, -0.296, 0.798)
			lht = CFrame.new(-0.83, -2.071, -0.233, 0.784, 0.075, -0.615, -0.147, 0.986, -0.067, 0.601, 0.143, 0.785)
			return rt, nt, rst, lst, rht, lht, 16
		end,
		sword7 = function(timingsine, rt, nt, rst, lst, rht, lht)
			rt = CFrame.new(-0.014, 0.023, 0.020, 0.573, 0, -0.819, 0, 1, 0, 0.819, 0, 0.573)
			nt = CFrame.new(0, 1.499, 0, 0.608, -0.069, 0.79, 0, 0.996, 0.087, -0.793, -0.052, 0.605)
			rst = CFrame.new(2.056, 0.769, 0.067, -0.311, -0.945, -0.092, 0.945, -0.298, -0.13, 0.095, -0.128, 0.987)
			lst = CFrame.new(-0.411, 0.158, -0.878, 0.25, -0.87, 0.422, 0.96, 0.276, 0, -0.116, 0.406, 0.906)
			rht = CFrame.new(0.657, -1.999, -0.128, 0.896, -0.092, 0.432, 0.143, 0.985, -0.086, -0.418, 0.139, 0.897)
			lht = CFrame.new(-0.494, -2.064, 0.151, 0.924, -0.032, 0.38, -0.003, 0.995, 0.093, -0.381, -0.087, 0.92)
			return rt, nt, rst, lst, rht, lht, 16
		end,
		sword8 = function(timingsine, rt, nt, rst, lst, rht, lht)
			rt = CFrame.new(-0.014, 0.023, 0.020, 0.642, 0, 0.766, 0, 1, 0, -0.766, 0, 0.642)
			nt = CFrame.new(0, 1.499, 0, 0.609, 0, -0.792, 0, 1, 0, 0.792, 0, 0.609)
			rst = CFrame.new(1.735, 0.521, -0.798, 0.809, -0.584, 0.048, 0.032, -0.038, -0.998, 0.585, 0.81, -0.011)
			lst = CFrame.new(-1.859, 0.325, -0.117, 0.896, 0.442, 0.032, -0.407, 0.849, -0.333, -0.175, 0.285, 0.942)
			rht = CFrame.new(0.425, -2.070, 0.092, 0.94, -0.024, 0.34, -0.024, 0.989, 0.141, -0.34, -0.141, 0.929)
			lht = CFrame.new(-0.614, -2, -0.011, 1, 0, 0, 0, 1, 0, 0, 0, 1)
			return rt, nt, rst, lst, rht, lht, 16
		end,
		superball1 = function(timingsine, rt, nt, rst, lst, rht, lht)
			AimTowards(MouseHit())
			rt = CFrame.new(-0.014, 0.023, 0.020, 0.642, 0, 0.766, 0, 1, 0, -0.766, 0, 0.642)
			nt = CFrame.new(0, 1.499, 0, 0.609, 0, -0.792, 0, 1, 0, 0.792, 0, 0.609)
			rst = CFrame.new(1.7, 0.078, 0.291, 0.98, -0.19, -0.036, 0.192, 0.924, 0.329, -0.029, -0.33, 0.943)
			lst = CFrame.new(-1.939, 0.331, -0.314, 0.117, 0.856, -0.502, -0.987, 0.048, -0.147, -0.101, 0.513, 0.851)
			rht = CFrame.new(0.596, -2.044, 0.245, 0.999, 0.005, -0.003, -0.004, 0.951, 0.308, 0.005, -0.308, 0.951)
			lht = CFrame.new(-0.699, -2, 0.021, 0.984, 0, 0.173, 0, 1, 0, -0.173, 0, 0.984)
			return rt, nt, rst, lst, rht, lht, 16
		end,
		superball2 = function(timingsine, rt, nt, rst, lst, rht, lht)
			AimTowards(MouseHit())
			rt = CFrame.new(-0.014, 0.023, 0.020, 0.642, 0, -0.766, 0, 1, 0, 0.766, 0, 0.642)
			nt = CFrame.new(0, 1.499, 0, 0.674, 0, 0.737, 0, 1, 0, -0.737, 0, 0.674)
			rst = CFrame.new(1.674, 0.116, -0.235, 0.935, -0.291, 0.198, 0.329, 0.924, -0.192, -0.127, 0.245, 0.96)
			lst = CFrame.new(-1.586, 0.765, -0.846, -0.12, 0.321, -0.939, -0.987, -0.131, 0.081, -0.097, 0.937, 0.333)
			rht = CFrame.new(0.766, -1.96, -0.107, 0.976, -0.137, 0.168, 0.138, 0.99, 0.004, -0.167, 0.018, 0.985)
			lht = CFrame.new(-0.403, -1.999, -0.061, 0.984, 0, 0.173, 0, 1, 0, -0.173, 0, 0.984)
			return rt, nt, rst, lst, rht, lht, 16
		end,
		rocket1 = function(timingsine, rt, nt, rst, lst, rht, lht)
			rt = CFrame.new(-0.014, 0.023, 0.020, 1, 0, 0, 0, 0.984, 0.173, 0, -0.173, 0.984)
			nt = CFrame.new(0.015, 1.552, -0.091, 0.999, 0.018, -0.038, -0.007, 0.965, 0.258, 0.042, -0.258, 0.965)
			rst = CFrame.new(1.287, 0.004, -0.065, 0.89, 0.23, -0.393, -0.298, 0.946, -0.12, 0.344, 0.225, 0.911)
			lst = CFrame.new(-1.595, 0.053, -0.298, 0.986, 0.153, -0.064, -0.162, 0.801, -0.576, -0.036, 0.578, 0.814)
			rht = CFrame.new(0.573, -1.805, -0.374, 0.999, -0.037, 0.013, 0.039, 0.981, -0.187, -0.006, 0.188, 0.982)
			lht = CFrame.new(-0.433, -1.951, 0.175, 1, 0, 0, 0, 0.984, 0.173, 0, -0.173, 0.984)
			return rt, nt, rst, lst, rht, lht, 16
		end,
		rocket2 = function(timingsine, rt, nt, rst, lst, rht, lht)
			AimTowards(MouseHit())
			rt = CFrame.new(-0.014, -1.088, 0.020, 1, 0, 0, 0, 0.984, 0.173, 0, -0.173, 0.984)
			nt = CFrame.new(0.015, 1.552, -0.091, 0.999, 0.018, -0.038, -0.007, 0.965, 0.258, 0.042, -0.258, 0.965)
			rst = CFrame.new(0.428, 0.573, -1.086, 0.629, 0.736, -0.245, -0.133, -0.208, -0.968, -0.765, 0.642, -0.033)
			lst = CFrame.new(-1.24, 0.563, -0.472, 0.974, -0.15, -0.165, -0.176, -0.068, -0.981, 0.136, 0.986, -0.093)
			rht = CFrame.new(0.542, -1.055, -0.494, 0.999, -0.039, 0.007, 0.039, 0.999, -0.014, -0.006, 0.014, 0.999)
			lht = CFrame.new(-0.433, -1.479, 0.259, 1, 0, 0, 0, 0.173, 0.984, 0, -0.984, 0.173)
			return rt, nt, rst, lst, rht, lht, 16
		end,
		rocket3 = function(timingsine, rt, nt, rst, lst, rht, lht)
			AimTowards(MouseHit())
			rt = CFrame.new(-0.014, -1.088, 0.020, 1, 0, 0, 0, 0.984, -0.173, 0, 0.173, 0.984)
			nt = CFrame.new(-0.015, 1.613, 0.079, 0.999, -0.011, -0.041, 0.007, 0.996, -0.087, 0.042, 0.086, 0.995)
			rst = CFrame.new(0.489, 0.316, -1.246, 0.629, 0.683, -0.369, -0.387, -0.136, -0.911, -0.673, 0.717, 0.178)
			lst = CFrame.new(-1.24, 0.367, -0.636, 0.974, -0.198, -0.103, -0.119, -0.070, -0.99, 0.188, 0.977, -0.092)
			rht = CFrame.new(0.542, -1.161, -0.103, 0.999, -0.039, 0.007, 0.034, 0.943, 0.328, -0.019, -0.327, 0.944)
			lht = CFrame.new(-0.433, -1.302, 0.749, 1, 0, 0, 0, -0.173, 0.984, 0, -0.984, -0.173)
			return rt, nt, rst, lst, rht, lht, 16
		end,
		timebomb1 = function(timingsine, rt, nt, rst, lst, rht, lht)
			rt = CFrame.new(-0.014, 0.023, 0.020, 0.642, 0, 0.766, 0, 1, 0, -0.766, 0, 0.642)
			nt = CFrame.new(0, 1.499, 0, 0.609, 0, -0.792, 0, 1, 0, 0.792, 0, 0.609)
			rst = CFrame.new(1.7, 0.078, 0.291, 0.98, -0.19, -0.036, 0.192, 0.924, 0.329, -0.029, -0.33, 0.943)
			lst = CFrame.new(-1.668, 0.166, -0.183, 0.845, 0.182, -0.502, -0.291, 0.945, -0.147, 0.447, 0.27, 0.851)
			rht = CFrame.new(0.596, -2.044, 0.245, 0.999, 0.005, -0.003, -0.004, 0.951, 0.308, 0.005, -0.308, 0.951)
			lht = CFrame.new(-0.699, -2, 0.021, 0.984, 0, 0.173, 0, 1, 0, -0.173, 0, 0.984)
			return rt, nt, rst, lst, rht, lht, 16
		end,
		timebomb2 = function(timingsine, rt, nt, rst, lst, rht, lht)
			rt = CFrame.new(-0.014, 0.023, 0.020, 0.642, 0, -0.766, 0, 1, 0, 0.766, 0, 0.642)
			nt = CFrame.new(0, 1.499, 0, 0.674, 0, 0.737, 0, 1, 0, -0.737, 0, 0.674)
			rst = CFrame.new(1.674, 0.116, -0.235, 0.935, -0.291, 0.198, 0.329, 0.924, -0.192, -0.127, 0.245, 0.96)
			lst = CFrame.new(-1.53, 0.231, -0.558, 0.939, 0.343, -0.002, -0.081, 0.213, -0.973, -0.333, 0.914, 0.228)
			rht = CFrame.new(0.766, -1.96, -0.107, 0.976, -0.137, 0.168, 0.138, 0.99, 0.004, -0.167, 0.018, 0.985)
			lht = CFrame.new(-0.403, -1.999, -0.061, 0.984, 0, 0.173, 0, 1, 0, -0.173, 0, 0.984)
			return rt, nt, rst, lst, rht, lht, 16
		end,
	}
	local function createhatmap(mlist, tbl)
		table.clear(tbl)
		for _,v in string.split(mlist, "|") do
			if #v > 0 then
				local w = string.split(v, ",")
				if #w == 14 then
					local ref = {
						MeshId = w[1]:gsub("^%s*(.-)%s*$", "%1"), TextureId = w[2]:gsub("^%s*(.-)%s*$", "%1"),
						C0 = CFrame.identity,
						C1 = CFrame.new(
							tonumber(w[3]),
							tonumber(w[4]),
							tonumber(w[5]),
							tonumber(w[6]),
							tonumber(w[7]),
							tonumber(w[8]),
							tonumber(w[9]),
							tonumber(w[10]),
							tonumber(w[11]),
							tonumber(w[12]),
							tonumber(w[13]),
							tonumber(w[14])
						),
					}
					table.insert(HatReanimator.HatCFrameOverride, ref)
					table.insert(tbl, ref)
				end
			end
		end
	end
	local function sethatmaplimbname(tbl, limbname)
		for _,v in tbl do
			v.Limb = limbname
		end
	end
	local function sethatmapcframe(tbl, cf)
		for _,v in tbl do
			v.C0 = cf
		end
	end
	local function CreatePart(cf, size, color, material, transp, reflec)
		local rng = Instance.new("Part", workspace)
		rng.Anchored = true
		rng.CanCollide = false
		rng.CanTouch = false
		rng.CanQuery = false
		rng.CastShadow = false
		rng.Name = RandomString()
		rng.Material = material or "Neon"
		rng.Color = color or Color3.new(1, 0, 0)
		rng.Size = size
		rng.Transparency = transp or 0
		rng.Reflectance = reflec or 0
		rng.TopSurface = 0
		rng.BottomSurface = 0
		rng.CFrame = cf
		return rng
	end
	local function MagicSphere(size, ticks, cf, color, grow, move, transp)
		grow = grow or Vector3.zero
		move = move or Vector3.zero
		transp = transp or 0
		local part = CreatePart(cf, Vector3.one, color, nil, transp)
		local mesh = Instance.new("SpecialMesh", part)
		mesh.MeshType = "Sphere"
		mesh.Scale = size
		mesh.Offset = Vector3.zero
		task.spawn(function()
			local elapsed = 0
			local lifetime = ticks / 60
			while elapsed < lifetime do
				local dt = task.wait()
				elapsed += dt
				mesh.Scale = size + grow * elapsed * 60
				mesh.Offset = move * elapsed * 60
				part.Transparency = (1 - transp) * (elapsed / lifetime) + transp
			end
			part:Destroy()
		end)
		return part
	end
	local function Explosion(position, radius)
		radius = radius or 14
		local radius2 = radius * (8 / 14)
		local base = MagicSphere(Vector3.zero, 300, CFrame.new(position), Color3.new(1, 0, 0), Vector3.zero, Vector3.zero, 1)
		MagicSphere(Vector3.one * radius2, 30, CFrame.new(position), Color3.new(1, 0, 0), Vector3.zero)
		MagicSphere(Vector3.one * radius2, 5, CFrame.new(position), Color3.new(1, 0, 0), Vector3.one * radius2 / 4)
		CreateSound(base, "169628396")
		Attack(CFrame.new(position), Vector3.one * radius)
	end
	local function SliceEffect(targets)
		for _,v in targets do
			CreateSound(v, "851453784")
			for _=1, 5 do
				MagicSphere(Vector3.new(1, 0, 0.1), 10, v.CFrame * CFrame.Angles(math.random() * math.pi * 2, math.random() * math.pi * 2, math.random() * math.pi * 2), Color3.new(1, 1, 1), Vector3.new(2, 0.01, 0.1))
			end
		end
	end
	local function BonkedEffect(targets)
		for _,v in targets do
			CreateSound(v, "140626490819228", 1, 2)
			MagicSphere(Vector3.one, 30, v.CFrame, Color3.new(1, 1, 1), Vector3.one * 0.15)
		end
	end
	local function MeleeHitbox(part, dur, cf, size)
		task.spawn(function()
			local s = os.clock()
			repeat task.wait()
				SliceEffect(Attack(part.CFrame * cf, size))
			until os.clock() - s > dur
		end)
	end
	local function CreateForce(part, vel, dur)
		task.spawn(function()
			local s = os.clock()
			repeat
				local dt = task.wait()
				part.Position += vel * dt
			until os.clock() - s > dur
		end)
	end
	local LinkedSword_index = 1
	local BulletReference = nil
	local SuperballReference = nil
	local TimebombReference = nil
	local function LinkedSword()
		if not m.IgnoreDancing then
			if isdancing then return end
		end
		if attacking and not m.NoCooldown then return end
		if not root or not hum or not torso then return end
		local rootu = root
		attacking = true
		local lol = LinkedSword_index
		LinkedSword_index = (LinkedSword_index + 1) % 3
		task.spawn(function()
			if lol == 0 then
				CreateSound("12222216", 1, 2)
				animationOverride = lerps.sword1
				task.wait(0.16)
				if not rootu:IsDescendantOf(workspace) then
					return
				end
				MeleeHitbox(rootu, 0.08, CFrame.new(1 * scale, 0, -3 * scale), Vector3.new(7, 5, 6) * scale)
				animationOverride = lerps.sword2
				swordoff = CFrame.new(0.5, 0.5, 0) * CFrame.Angles(math.rad(-5), 0, math.rad(-90))
				task.wait(0.08)
				if not rootu:IsDescendantOf(workspace) then
					return
				end
				swordoff = CFrame.new(0, 0.5, 0) * CFrame.Angles(0, math.rad(30), 0)
				task.wait(0.08)
				if not rootu:IsDescendantOf(workspace) then
					return
				end
			end
			if lol == 1 then
				CreateSound("12222216", 1, 2)
				animationOverride = lerps.sword3
				task.wait(0.08)
				if not rootu:IsDescendantOf(workspace) then
					return
				end
				animationOverride = lerps.sword4
				task.wait(0.08)
				if not rootu:IsDescendantOf(workspace) then
					return
				end
				MeleeHitbox(rootu, 0.08, CFrame.new(-1 * scale, 0, -3 * scale), Vector3.new(7, 5, 6) * scale)
				animationOverride = lerps.sword5
				task.wait(0.08)
				if not rootu:IsDescendantOf(workspace) then
					return
				end
				animationOverride = lerps.sword6
				task.wait(0.08)
				if not rootu:IsDescendantOf(workspace) then
					return
				end
			end
			if lol == 2 then
				animationOverride = lerps.sword7
				task.wait(0.16)
				if not rootu:IsDescendantOf(workspace) then
					return
				end
				CreateSound("12222208", 1, 2)
				MeleeHitbox(rootu, 0.2, CFrame.new(0, 0, -4 * scale), Vector3.new(5, 5, 8) * scale)
				CreateForce(rootu, rootu.CFrame.LookVector * 24, 0.2)
				animationOverride = lerps.sword8
				swordoff = CFrame.new(0.5, 0.5, 0) * CFrame.Angles(math.rad(-5), 0, math.rad(-90))
				task.wait(0.2)
				if not rootu:IsDescendantOf(workspace) then
					return
				end
			end
			animationOverride = nil
			attacking = false
		end)
	end
	local function Superball()
		if not m.IgnoreDancing then
			if isdancing then return end
		end
		if attacking and not m.NoCooldown then return end
		if not root or not hum or not torso then return end
		local rootu = root
		local larm = rootu.Parent:FindFirstChild("Left Arm")
		if not larm then return end
		attacking = true
		task.spawn(function()
			animationOverride = lerps.superball1
			local proj = CreatePart(CFrame.identity, Vector3.one * 2, Color3.new(1, 0, 0), "Plastic", 0, 0.4)
			proj.Shape = "Ball"
			SuperballReference = proj
			local s = os.clock()
			repeat
				proj.CFrame = larm.CFrame * CFrame.new(0, -1 * scale - 1, 0)
				task.wait()
				if not rootu:IsDescendantOf(workspace) then
					proj:Destroy()
					return
				end
			until os.clock() - s >= 0.3
			CreateSound("12222124")
			local target = MouseHit()
			local speed = 200
			local aim = target - proj.Position
			proj.Velocity = aim.Unit * speed
			task.spawn(function()
				local s = os.clock()
				local oldpos = proj.Position
				repeat
					local dt = task.wait()
					local raycast = PhysicsRaycast(proj.Position, proj.Velocity * dt)
					if raycast then
						CreateSound(proj, "112503990")
						proj.Position = raycast.Position
						proj.Velocity += raycast.Normal * raycast.Normal:Dot(-proj.Velocity) * 2
					else
						proj.Position += proj.Velocity * dt
					end
					BonkedEffect(Attack(CFrame.lookAt((proj.Position + oldpos) / 2, proj.Position), Vector3.new(3, 3, (proj.Position - oldpos).Magnitude)))
					oldpos = proj.Position
				until os.clock() - s > 2 or not rootu:IsDescendantOf(workspace)
				proj:Destroy()
			end)
			animationOverride = lerps.superball2
			task.wait(0.16)
			if not rootu:IsDescendantOf(workspace) then
				return
			end
			animationOverride = nil
			attacking = false
		end)
	end
	local function RocketLauncher()
		if not m.IgnoreDancing then
			if isdancing then return end
		end
		if attacking and not m.NoCooldown then return end
		if not root or not hum or not torso then return end
		local rootu = root
		local larm = rootu.Parent:FindFirstChild("Left Arm")
		if not larm then return end
		attacking = true
		freezemove = true
		task.spawn(function()
			rocket.Disable = false
			animationOverride = lerps.rocket1
			task.wait(0.16)
			if not rootu:IsDescendantOf(workspace) then
				return
			end
			animationOverride = lerps.rocket2
			task.wait(0.5)
			if not rootu:IsDescendantOf(workspace) then
				return
			end
			CreateForce(rootu, rootu.CFrame.LookVector * -20, 0.25)
			local proj = CreatePart(CFrame.lookAt(rootu.CFrame * Vector3.new(0, 0, -6), MouseHit()), Vector3.new(1, 1, 4), Color3.new(0.05, 0.41, 0.67), "Plastic", 0, 0)
			BulletReference = proj
			CreateSound(proj, "31761785")
			proj.Velocity = proj.CFrame.LookVector * 100
			task.spawn(function()
				local s = os.clock()
				local oldpos = proj.Position
				repeat
					local dt = task.wait()
					local raycast = PhysicsRaycast(proj.Position, proj.Velocity * dt)
					if raycast then
						Explosion(proj.Position, 14)
						break
					end
					proj.Position += proj.Velocity * dt
					local hits = Attack(CFrame.lookAt((proj.Position + oldpos) / 2, proj.Position), Vector3.new(1, 1, (proj.Position - oldpos).Magnitude + 4))
					if #hits > 0 then
						Explosion(proj.Position, 14)
						break
					end
					oldpos = proj.Position
				until os.clock() - s > 2 or not rootu:IsDescendantOf(workspace)
				proj:Destroy()
			end)
			animationOverride = lerps.rocket3
			task.wait(0.3)
			if not rootu:IsDescendantOf(workspace) then
				return
			end
			rocket.Disable = true
			animationOverride = nil
			attacking = false
			freezemove = false
		end)
	end
	local function Timebomb()
		if not m.IgnoreDancing then
			if isdancing then return end
		end
		if attacking and not m.NoCooldown then return end
		if not root or not hum or not torso then return end
		local rootu = root
		local larm = rootu.Parent:FindFirstChild("Left Arm")
		if not larm then return end
		attacking = true
		task.spawn(function()
			animationOverride = lerps.timebomb1
			local proj = CreatePart(CFrame.identity, Vector3.one, Color3.new(0.1, 0.16, 0.2), "Plastic", 0, 0)
			CreateSound(proj, "11565378")
			local mesh = Instance.new("SpecialMesh", proj)
			mesh.MeshType = "FileMesh"
			mesh.MeshId = "rbxasset://fonts/timebomb.mesh"
			mesh.TextureId = "rbxasset://textures/bombtex.png"
			TimebombReference = proj
			local s = os.clock()
			repeat
				proj.CFrame = larm.CFrame * CFrame.new(0, -1 * scale - 1, 0)
				task.wait()
				if not rootu:IsDescendantOf(workspace) then
					proj:Destroy()
					return
				end
			until os.clock() - s >= 0.3
			animationOverride = lerps.timebomb2
			local s = os.clock()
			repeat
				proj.CFrame = larm.CFrame * CFrame.new(0, -1 * scale - 1, 0)
				task.wait()
				if not rootu:IsDescendantOf(workspace) then
					proj:Destroy()
					return
				end
			until os.clock() - s >= 0.08
			proj.CFrame = rootu.CFrame * CFrame.new(0, 0, -3)
			proj.Anchored = false
			proj.CanCollide = true
			proj.Velocity = rootu.CFrame.LookVector * 50
			task.spawn(function()
				local s = os.clock()
				repeat task.wait()
					if not rootu:IsDescendantOf(workspace) then
						proj:Destroy()
						return
					end
				until os.clock() - s > 4
				Explosion(proj.Position, 30)
				proj:Destroy()
			end)
			task.wait(0.08)
			if not rootu:IsDescendantOf(workspace) then
				return
			end
			animationOverride = nil
			attacking = false
		end)
	end
	m.Init = function(figure)
		start = os.clock()
		timingsine = 0
		attacking = false
		freezemove = false
		animationOverride = nil
		BulletReference = nil
		SuperballReference = nil
		TimebombReference = nil
		hum = figure:FindFirstChild("Humanoid")
		root = figure:FindFirstChild("HumanoidRootPart")
		torso = figure:FindFirstChild("Torso")
		if not hum then return end
		if not root then return end
		if not torso then return end
		sword = {
			Group = "Sword",
			Limb = "Right Arm",
			Offset = CFrame.identity
		}
		rocket = {
			Group = "Gun",
			Limb = "Left Arm",
			Offset = CFrame.new(0, -0.7, -0.4) * CFrame.Angles(3.14, 0, 0),
			Disable = true
		}
		bullet = {
			Group = "Bullet",
			CFrame = CFrame.identity
		}
		table.insert(HatReanimator.HatCFrameOverride, sword)
		table.insert(HatReanimator.HatCFrameOverride, rocket)
		table.insert(HatReanimator.HatCFrameOverride, bullet)
		createhatmap(LINKEDSWORD_HATMAP_BALL, superball)
		createhatmap(LINKEDSWORD_HATMAP_BOMB, timebomb)
		ContextActions:BindAction("Uhhhhhh_LSSword", function(_, state, _)
			if state == Enum.UserInputState.Begin then
				LinkedSword()
			end
		end, true, Enum.UserInputType.MouseButton1)
		ContextActions:SetTitle("Uhhhhhh_LSSword", "M1")
		ContextActions:SetPosition("Uhhhhhh_LSSword", UDim2.new(1, -130, 1, -130))
		ContextActions:BindAction("Uhhhhhh_LSBall", function(_, state, _)
			if state == Enum.UserInputState.Begin then
				Superball()
			end
		end, true, Enum.KeyCode.Z)
		ContextActions:SetTitle("Uhhhhhh_LSBall", "Z")
		ContextActions:SetPosition("Uhhhhhh_LSBall", UDim2.new(1, -180, 1, -130))
		ContextActions:BindAction("Uhhhhhh_LSRocket", function(_, state, _)
			if state == Enum.UserInputState.Begin then
				RocketLauncher()
			end
		end, true, Enum.KeyCode.X)
		ContextActions:SetTitle("Uhhhhhh_LSRocket", "X")
		ContextActions:SetPosition("Uhhhhhh_LSRocket", UDim2.new(1, -230, 1, -130))
		ContextActions:BindAction("Uhhhhhh_LSBomb", function(_, state, _)
			if state == Enum.UserInputState.Begin then
				Timebomb()
			end
		end, true, Enum.KeyCode.C)
		ContextActions:SetTitle("Uhhhhhh_LSBomb", "C")
		ContextActions:SetPosition("Uhhhhhh_LSBomb", UDim2.new(1, -280, 1, -130))
		if chatconn then
			chatconn:Disconnect()
		end
		chatconn = OnPlayerChatted.Event:Connect(function(plr, msg)
			if plr == Player then
				notify(msg)
			end
		end)
	end
	m.Update = function(dt, figure)
		local t = os.clock() - start
		scale = figure:GetScale()
		isdancing = not not figure:GetAttribute("IsDancing")
		rcp.FilterDescendantsInstances = {U.real(figure), Player.Character}

		hum = figure:FindFirstChild("Humanoid")
		root = figure:FindFirstChild("HumanoidRootPart")
		torso = figure:FindFirstChild("Torso")
		if not hum then return end
		if not root then return end
		if not torso then return end

		local onground = hum:GetState() == Enum.HumanoidStateType.Running
		if freezemove then
			hum.WalkSpeed = 0
			hum.JumpPower = 0
		else
			hum.WalkSpeed = 13 * scale
			hum.JumpPower = 60 * scale
		end

		timingsine += dt * 60
		local torsovelocity = root.Velocity.Magnitude / scale
		local torsovelocityy = root.Velocity.Y / scale
		local animationFunc = nil
		if animationOverride then
			animationFunc = animationOverride
		else
			swordoff = CFrame.new(0, 1, 0) * CFrame.Angles(0, math.rad(90), 0)
			if onground then
				if torsovelocity > 1 then
					animationFunc = lerps.walk
				else
					animationFunc = lerps.idle
				end
			else
				if torsovelocityy < -1 then
					animationFunc = lerps.fall
				else
					animationFunc = lerps.jump
				end
			end
		end
		local rt, nt, rst, lst, rht, lht, animationspeed = animationFunc(timingsine)

		local rj = root:FindFirstChild("RootJoint")
		local nj = torso:FindFirstChild("Neck")
		local rsj = torso:FindFirstChild("Right Shoulder")
		local lsj = torso:FindFirstChild("Left Shoulder")
		local rhj = torso:FindFirstChild("Right Hip")
		local lhj = torso:FindFirstChild("Left Hip")

		local alpha = math.exp(-animationspeed * dt)
		joints.r = rt:Lerp(joints.r, alpha)
		joints.n = nt:Lerp(joints.n, alpha)
		joints.rs = rst:Lerp(joints.rs, alpha)
		joints.ls = lst:Lerp(joints.ls, alpha)
		joints.rh = rht:Lerp(joints.rh, alpha)
		joints.lh = lht:Lerp(joints.lh, alpha)
		joints.sw = swordoff:Lerp(joints.sw, alpha)

		SetC0C1Joint(rj, joints.r, CFrame.identity, scale)
		SetC0C1Joint(nj, joints.n, CFrame.identity, scale)
		SetC0C1Joint(rsj, joints.rs, CFrame.identity, scale)
		SetC0C1Joint(lsj, joints.ls, CFrame.identity, scale)
		SetC0C1Joint(rhj, joints.rh, CFrame.identity, scale)
		SetC0C1Joint(lhj, joints.lh, CFrame.identity, scale)

		sword.Offset = joints.sw:Inverse() * CFrame.Angles(1.57, 0, 1.57)
		sword.Disable = not not isdancing or freezemove

		if SuperballReference and not SuperballReference:IsDescendantOf(workspace) then
			SuperballReference = nil
		end
		if SuperballReference then
			sethatmaplimbname(superball, nil)
			sethatmapcframe(superball, SuperballReference.CFrame)
		else
			sethatmaplimbname(superball, "Torso")
			sethatmapcframe(superball, CFrame.new(-1, -1, 0.5))
		end

		if BulletReference and not BulletReference:IsDescendantOf(workspace) then
			BulletReference = nil
		end
		if BulletReference then
			bullet.CFrame = BulletReference.CFrame
		else
			bullet.CFrame = root.CFrame + Vector3.new(0, -18, 0)
		end

		if TimebombReference and not TimebombReference:IsDescendantOf(workspace) then
			TimebombReference = nil
		end
		if TimebombReference then
			sethatmaplimbname(timebomb, nil)
			sethatmapcframe(timebomb, TimebombReference.CFrame)
		else
			sethatmaplimbname(timebomb, "Torso")
			sethatmapcframe(timebomb, CFrame.new(-1, -1, -0.5))
		end
	end
	m.Destroy = function(figure)
		ContextActions:UnbindAction("Uhhhhhh_LSSword")
		ContextActions:UnbindAction("Uhhhhhh_LSBall")
		ContextActions:UnbindAction("Uhhhhhh_LSRocket")
		ContextActions:UnbindAction("Uhhhhhh_LSBomb")
		root, torso, hum = nil, nil, nil
	end
	return m
end)

U.run()
