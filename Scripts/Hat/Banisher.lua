local genv = (typeof(getgenv) == "function" and getgenv()) or _G
local Uhh = genv.AtsukoUhh
if type(Uhh) ~= "table" or (tonumber(Uhh.version) or 0) < 1 then
	local base = type(genv.AtsukoHubRaw) == "string" and genv.AtsukoHubRaw or "https://raw.githubusercontent.com/atsukohakari/atsuko-test-/main/"
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
		warn("[Banisher] couldn't load Hub/UhhMoveset.lua")
		return
	end
end

local U = Uhh.new({
	title = "Banisher",
	short = "ban",
	jobs = { { "gun", "Gun" }, { "bullet", "Bullet" } },
	groups = { Gun = "gun", Sword = "gun", Bullet = "bullet" },
	need = "gun",
	hint = "Gun moves the gun in your hand, Bullet moves the hat that flies with your shots and bombs.",
	global = "AtsukoBanisher",
})
if not U then
	return
end

local cloneref = cloneref or function(o)
	return o
end
local Debris = cloneref(game:GetService("Debris"))
local Players = cloneref(game:GetService("Players"))
local TweenService = cloneref(game:GetService("TweenService"))
local UserInputService = cloneref(game:GetService("UserInputService"))

local Player = Players.LocalPlayer
local RandomString = U.RandomString
local Util_CreateSwitch = U.Util_CreateSwitch
local ReanimCamera = U.ReanimCamera
local HatReanimator = U.HatReanimator
local ReanimateFling = U.ReanimateFling
local SetOverrideMovesetMusic = U.SetOverrideMovesetMusic
local AssetGetContentId = U.AssetGetContentId
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
local flight, scale

AddModule(function()
	local m = {}
	m.ModuleType = "MOVESET"
	m.Name = "Banisher"
	m.InternalName = "FIGHTERGUY"
	m.Description = "hes a very tuff CLANKER\nM1 - Primary Attack\nR - Secondary Attack\nF - Holster/Unholster Gun\nLeft Ctrl - Run"
	m.Assets = {"BanisherTheme.mp3"}

	m.Notifications = true
	m.Sounds = true
	m.NoCooldown = false
	m.IgnoreDancing = false
	m.HitboxDebug = false
	m.ParkourAnims = true
	m.UseSword = false
	m.CameraFly = false
	m.Config = function(parent)
		Util_CreateSwitch(parent, "Tuff", m.Notifications).Changed:Connect(function(val)
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
		Util_CreateSwitch(parent, "Fall Parkour Anim", m.ParkourAnims).Changed:Connect(function(val)
			m.ParkourAnims = val
		end)
		Util_CreateSwitch(parent, "Camera Fly", m.CameraFly).Changed:Connect(function(val)
			m.CameraFly = val
		end)
		Util_CreateSwitch(parent, "Use Sword instead of Gun", m.UseSword).Changed:Connect(function(val)
			m.UseSword = val
		end)
	end
	m.LoadConfig = function(save)
		m.Notifications = not save.Blind
		m.Sounds = not save.Muted
		m.NoCooldown = not not save.NoCooldown
		m.IgnoreDancing = not not save.IgnoreDancing
		m.HitboxDebug = not not save.HitboxDebug
		m.ParkourAnims = not save.MoreTuff
		m.UseSword = not not save.UseSword
		m.CameraFly = not not save.CameraFly
	end
	m.SaveConfig = function()
		return {
			Blind = not m.Notifications,
			Muted = not m.Sounds,
			NoCooldown = m.NoCooldown,
			IgnoreDancing = m.IgnoreDancing,
			HitboxDebug = m.HitboxDebug,
			MoreTuff = not m.ParkourAnims,
			UseSword = m.UseSword,
			CameraFly = m.CameraFly,
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
		sound.SoundId = "rbxassetid://" .. id
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
		text.Font = "Antique"
		text.TextScaled = true
		text.TextStrokeTransparency = 0
		text.TextStrokeColor3 = Color3.new(0, 0, 0)
		text.Size = UDim2.new(1, 0, 1, 0)
		text.ZIndex = 0
		text.TextColor3 = Color3.new(1, 1, 1)
		task.spawn(function()
			local function update()
				text.TextColor3 = Color3.new(0.5 + (math.random() ^ 3) * 0.5, 0, 0)
			end
			local cps = 20
			local t = os.clock()
			local ll = 0
			repeat
				task.wait()
				local l = math.floor((os.clock() - t) * cps)
				if l > ll then
					ll = l
					CreateSound("7175909725")
				end
				update()
				text.Text = string.sub(message, 1, l)
			until ll >= #message or dialog.Parent ~= torso
			text.Text = message
			t = os.clock()
			repeat
				task.wait()
				update()
			until os.clock() - t > 2
			t = os.clock()
			repeat
				task.wait()
				update()
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
	}
	local gun = {}
	local bullet = {}
	local bulletstate = {Vector3.zero, Vector3.zero, 0}
	local function SetBulletState(hole, target)
		local dist = (target - hole).Magnitude
		bulletstate[1] = hole
		if dist > 256 then
			bulletstate[2] = hole + (target - hole).Unit * 256
		else
			bulletstate[2] = target
		end
		bulletstate[3] = os.clock()
	end
	local attacking = false
	local timingsine = 0
	local walkspeed = 0
	local walktime = 0
	local falltime = 0
	local hasgun = false
	local gunspin = false
	local lastfly = false
	local mustfly = 0
	local animationOverride = nil
	local flysound = nil
	local ROOTC0 = CFrame.Angles(-1.57, 0, 3.14)
	local NECKC0 = CFrame.new(0, 1, 0, -1, 0, 0, 0, 0, 1, 0, 1, 0)
	local RIGHTSHOULDERC0 = CFrame.new(-0.5, 0, 0) * CFrame.Angles(0, math.rad(90), 0)
	local LEFTSHOULDERC0 = CFrame.new(0.5, 0, 0) * CFrame.Angles(0, math.rad(-90), 0)
	local lerps = {
		idle = function(timingsine, rt, nt, rst, lst, rht, lht)
			rt = CFrame.new(0, -0.1 + 0.1 * math.sin((timingsine + 1.6) * 1), 0.1 * math.sin(timingsine * 1)) * CFrame.fromEulerAngles(-1.484 + 0.035 * math.sin(timingsine * 1), 0, 2.793)
			nt = CFrame.new(0, 1.02 + 0.05 * math.sin(timingsine * 1), 0) * CFrame.fromEulerAngles(-1.658 + 0.035 * math.sin(timingsine * 1), 0, 3.491)
			rst = CFrame.new(1, 0.1 * math.sin(timingsine * 1), 0) * CFrame.fromEulerAngles(0, 2.269, 2.269 - 0.035 * math.sin((timingsine + 1.6) * 1))
			lst = CFrame.new(-1, 0.1 * math.sin(timingsine * 1), 0) * CFrame.fromEulerAngles(0, -1.92, -2.269 - 0.035 * math.sin((timingsine + 1.6) * 1))
			rht = CFrame.new(1.1, -1 - 0.08 * math.sin((timingsine + 1.6) * 1), -0.05 * math.sin(timingsine * 1)) * CFrame.fromEulerAngles(0.175 - 0.017 * math.sin(timingsine * 1), 1.745, -0.524)
			lht = CFrame.new(-1.1, -1.1 - 0.08 * math.sin((timingsine + 1.6) * 1), -0.05 * math.sin(timingsine * 1)) * CFrame.fromEulerAngles(-0.017 * math.sin(timingsine * 1), -1.047, -0.349)
			return rt, nt, rst, lst, rht, lht, 16
		end,
		walk = function(timingsine, rt, nt, rst, lst, rht, lht)
			lht = CFrame.new(-1, -0.95 - 0.05 * math.sin((timingsine + 0.5) * 4), 0.1 * math.sin((timingsine + 0.2) * 4)) * CFrame.fromEulerAngles(-0.349 * math.sin((timingsine + 0.3) * 4), -1.571, 0)
			nt = CFrame.new(-0.05 * math.sin(timingsine * 4), 1, 0) * CFrame.fromEulerAngles(-1.658, -0.035 * math.sin((timingsine - 0.5) * 4), 3.142 - 0.087 * math.sin(timingsine * 4))
			rst = CFrame.new(1, 0.01 * math.sin(timingsine * 4), 0) * CFrame.fromEulerAngles(0, 2.094, 2.269 - 0.035 * math.sin((timingsine + 0.4) * 4))
			rt = CFrame.new(0, -0.1 + 0.05 * math.sin(timingsine * 8), 0) * CFrame.fromEulerAngles(-1.571, 0.017 * math.sin((timingsine + 0.5) * 4), 3.142 + 0.087 * math.sin(timingsine * 4))
			rht = CFrame.new(1, -0.95 + 0.05 * math.sin((timingsine + 0.5) * 4), -0.1 * math.sin((timingsine + 0.2) * 4)) * CFrame.fromEulerAngles(0.349 * math.sin((timingsine + 0.3) * 4), 1.571, 0)
			lst = CFrame.new(-1, 0.01 * math.sin(timingsine * 4), 0) * CFrame.fromEulerAngles(0, -2.094, -2.269 - 0.035 * math.sin((timingsine + 0.4) * 4))
			return rt, nt, rst, lst, rht, lht, 16
		end,
		run = function(timingsine, rt, nt, rst, lst, rht, lht)
			lht = CFrame.new(-1, -0.95 - 0.05 * math.sin((timingsine + 0.5) * 4), 0.1 * math.sin((timingsine + 0.2) * 4)) * CFrame.fromEulerAngles(-1.047 * math.sin((timingsine + 0.3) * 4), -1.571, 0)
			nt = CFrame.new(-0.05 * math.sin(timingsine * 4), 1, -0.05) * CFrame.fromEulerAngles(-1.658, -0.035 * math.sin((timingsine - 0.5) * 4), 3.142 - 0.087 * math.sin(timingsine * 4))
			rst = CFrame.new(1, 0.4 - 0.05 * math.sin((timingsine + 0.25) * 8), 0.5) * CFrame.fromEulerAngles(0, 2.094 - 0.087 * math.sin(timingsine * 4), -1.047 + 0.087 * math.sin((timingsine + 0.25) * 8))
			rt = CFrame.new(0, -0.1 + 0.1 * math.sin(timingsine * 8), 0) * CFrame.fromEulerAngles(-1.571, 0.017 * math.sin((timingsine + 0.5) * 4), 3.142 + 0.087 * math.sin(timingsine * 4))
			rht = CFrame.new(1, -0.95 + 0.05 * math.sin((timingsine + 0.5) * 4), -0.1 * math.sin((timingsine + 0.2) * 4)) * CFrame.fromEulerAngles(1.047 * math.sin((timingsine + 0.3) * 4), 1.571, 0)
			lst = CFrame.new(-1, 0.4 - 0.05 * math.sin((timingsine + 0.25) * 8), 0.5) * CFrame.fromEulerAngles(0, -2.094 - 0.087 * math.sin(timingsine * 4), 1.047 - 0.087 * math.sin((timingsine + 0.25) * 8))
			return rt, nt, rst, lst, rht, lht, 16
		end,
		punch = function(timingsine, rt, nt, rst, lst, rht, lht)
			timingsine -= math.pi / 2
			rst = CFrame.new(1, 0.25 + 0.25 * math.sin((timingsine - 0.5) * 1), -0.1 - 0.5 * math.sin((timingsine - 0.5) * 1)) * CFrame.fromEulerAngles(0, 1.571 + 0.524 * math.sin((timingsine - 0.5) * 1), 1.571 + 0.349 * math.sin((timingsine - 0.5) * 1))
			lst = CFrame.new(-0.7 - 0.3 * math.sin((timingsine - 0.5) * 1), 0.7, -0.2 + 0.5 * math.sin((timingsine - 0.5) * 1)) * CFrame.fromEulerAngles(0, -1.571 + 0.785 * math.sin((timingsine - 0.5) * 1), -1.571)
			nt = CFrame.new(0, 1, 0) * CFrame.fromEulerAngles(-1.571 - 0.262 * math.sin(timingsine * 1), 0, 2.793 - 0.96 * math.sin(timingsine * 1))
			rt = CFrame.fromEulerAngles(-1.658 + 0.175 * math.sin(timingsine * 1), 0, 3.491 + 0.96 * math.sin(timingsine * 1))
			return rt, nt, rst, lst, rht, lht, 16
		end,
		kick = function(timingsine, rt, nt, rst, lst, rht, lht)
			timingsine -= math.pi / 2
			rht = CFrame.new(1, -1, -0.2 * math.sin((timingsine + 0.8) * 1)) * CFrame.fromEulerAngles(0.175 * math.sin(timingsine * 1), 1.222 + 0.175 * math.sin(timingsine * 1), 1.571 * math.sin((timingsine + 0.8) * 1))
			rst = CFrame.new(1, 0, 0.2) * CFrame.fromEulerAngles(-1.571 - 0.175 * math.sin((timingsine - 0.4) * 1), 0.785, 1.571 + 0.349 * math.sin((timingsine - 0.4) * 1))
			rt = CFrame.fromEulerAngles(-1.396 + 0.175 * math.sin(timingsine * 1), 0, 3.142 + 1.047 * math.sin(timingsine * 1))
			lst = CFrame.new(-1, 0, -0.2 - 0.4 * math.sin((timingsine - 0.4) * 1)) * CFrame.fromEulerAngles(-1.571 - 0.524 * math.sin((timingsine - 0.4) * 1), -0.785, -2.094 - 0.698 * math.sin((timingsine - 0.4) * 1))
			lht = CFrame.new(-1 - 0.05 * math.sin(timingsine * 2), -1.1 + 0.1 * math.sin(timingsine * 1), -0.5 * math.sin(timingsine * 1)) * CFrame.fromEulerAngles(-0.175 * math.sin(timingsine * 1), -1.396 - 0.524 * math.sin(timingsine * 1), 0)
			nt = CFrame.new(0, 1, 0) * CFrame.fromEulerAngles(-1.745 - 0.175 * math.sin(timingsine * 1), 0, 3.142 - 1.047 * math.sin(timingsine * 1))
			return rt, nt, rst, lst, rht, lht, 16
		end,
		gidle = function(timingsine, rt, nt, rst, lst, rht, lht)
			lht = CFrame.new(-1.1, -1.1 - 0.08 * math.sin((timingsine + 1.6) * 1), -0.05 * math.sin(timingsine * 1)) * CFrame.fromEulerAngles(-0.017 * math.sin(timingsine * 1), -1.047, -0.349)
			nt = CFrame.new(0, 1.02 + 0.05 * math.sin(timingsine * 1), 0) * CFrame.fromEulerAngles(-1.658 + 0.035 * math.sin(timingsine * 1), 0, 3.491)
			rst = CFrame.new(1, 0.1 * math.sin(timingsine * 1), 0) * CFrame.fromEulerAngles(1.745, 1.396, 0.873 - 0.035 * math.sin((timingsine + 1.6) * 1))
			rt = CFrame.new(0, -0.1 + 0.1 * math.sin((timingsine + 1.6) * 1), 0.1 * math.sin(timingsine * 1)) * CFrame.fromEulerAngles(-1.484 + 0.035 * math.sin(timingsine * 1), 0, 2.793)
			rht = CFrame.new(1.1, -1 - 0.08 * math.sin((timingsine + 1.6) * 1), -0.05 * math.sin(timingsine * 1)) * CFrame.fromEulerAngles(0.175 - 0.017 * math.sin(timingsine * 1), 1.745, -0.524)
			lst = CFrame.new(-1, 0.3 + 0.1 * math.sin(timingsine * 1), 0.5) * CFrame.fromEulerAngles(-0.087 * math.sin(timingsine * 1), -2.094, 0.785 - 0.087 * math.sin((timingsine + 1.6) * 1))
			return rt, nt, rst, lst, rht, lht, 16
		end,
		gwalk = function(timingsine, rt, nt, rst, lst, rht, lht)
			lst = CFrame.new(-1, 0.3 + 0.01 * math.sin(timingsine * 8), 0.5 + 0.1 * math.sin(timingsine * 4)) * CFrame.fromEulerAngles(-0.087 * math.sin(timingsine * 1), -2.094, 0.785 - 0.035 * math.sin((timingsine - 0.5) * 8))
			lht = CFrame.new(-1, -0.95 - 0.05 * math.sin((timingsine + 0.5) * 4), 0.1 * math.sin((timingsine + 0.2) * 4)) * CFrame.fromEulerAngles(-0.349 * math.sin((timingsine + 0.3) * 4), -1.571, 0)
			rht = CFrame.new(1, -0.95 + 0.05 * math.sin((timingsine + 0.5) * 4), -0.1 * math.sin((timingsine + 0.2) * 4)) * CFrame.fromEulerAngles(0.349 * math.sin((timingsine + 0.3) * 4), 1.571, 0)
			nt = CFrame.new(-0.05 * math.sin(timingsine * 4), 1, 0) * CFrame.fromEulerAngles(-1.658, -0.035 * math.sin((timingsine - 0.5) * 4), 3.142 - 0.087 * math.sin(timingsine * 4))
			rst = CFrame.new(1, 0.1 * math.sin(timingsine * 1), 0) * CFrame.fromEulerAngles(1.745, 1.396 + 0.035 * math.sin(timingsine * 4), 0.873 - 0.035 * math.sin((timingsine + 0.5) * 4))
			rt = CFrame.new(0, -0.1 + 0.05 * math.sin(timingsine * 8), 0) * CFrame.fromEulerAngles(-1.571, 0.017 * math.sin((timingsine + 0.5) * 4), 3.142 + 0.087 * math.sin(timingsine * 4))
			return rt, nt, rst, lst, rht, lht, 16
		end,
		holster = function(timingsine, rt, nt, rst, lst, rht, lht)
			lst = CFrame.new(-1, 0.3, 0.5) * CFrame.fromEulerAngles(0, -1.745, -0.785)
			nt = CFrame.new(0, 1, 0) * CFrame.fromEulerAngles(-1.658, 0, 3.491)
			rst = CFrame.new(1.1, 0.5, 0) * CFrame.fromEulerAngles(-0.95, 2.1, 1.1)
			return rt, nt, rst, lst, rht, lht, 16
		end,
		unholster = function(timingsine, rt, nt, rst, lst, rht, lht)
			lst = CFrame.new(-1, 0.3, 0.5) * CFrame.fromEulerAngles(0, -1.745, -0.785)
			nt = CFrame.new(0, 1, 0) * CFrame.fromEulerAngles(-1.658, 0, 3.491)
			rst = CFrame.new(1, 0.5, -0.5) * CFrame.fromEulerAngles(0, 1.9, 1.5)
			return rt, nt, rst, lst, rht, lht, 16
		end,
		shoot = function(timingsine, rt, nt, rst, lst, rht, lht)
			rt = CFrame.fromEulerAngles(-1.571, 0, 3.578 + 0.087 * math.sin(timingsine * 1))
			rst = CFrame.new(1, 0.45 + 0.05 * math.sin(timingsine * 1), -0.3 - 0.1 * math.sin(timingsine * 1)) * CFrame.fromEulerAngles(0, 1.222 - 0.175 * math.sin(timingsine * 1), 1.658 - 0.087 * math.sin(timingsine * 1))
			lst = CFrame.new(-1, 0.5, 0) * CFrame.fromEulerAngles(0, -1.571, 0)
			nt = CFrame.new(0, 1, 0) * CFrame.fromEulerAngles(-1.571, 0, 2.705 - 0.087 * math.sin(timingsine * 1))
			return rt, nt, rst, lst, rht, lht, 16
		end,
		fly = function(timingsine, rt, nt, rst, lst, rht, lht)
			nt = CFrame.new(0, 1, 0) * CFrame.fromEulerAngles(-1.571, 0, 3.142)
			rht = CFrame.new(1, -1, 0.1) * CFrame.fromEulerAngles(0.175, 1.396, -0.175)
			lst = CFrame.new(-1, 0.4, 0) * CFrame.fromEulerAngles(0.175, -1.222, 0.524)
			lht = CFrame.new(-1, -1, 0.1) * CFrame.fromEulerAngles(0.175, -1.396, 0.175)
			rst = CFrame.new(1, 0.4, 0) * CFrame.fromEulerAngles(0.175, 1.222, -0.524)
			rt = CFrame.fromEulerAngles(-1.571, 0, 3.142)
			return rt, nt, rst, lst, rht, lht, 16
		end,
		fall = function(timingsine, rt, nt, rst, lst, rht, lht)
			if m.ParkourAnims then
				nt = CFrame.new(0, 1, 0) * CFrame.fromEulerAngles(-1.92, 0, 3.142 - 0.175 * math.sin(timingsine * 8))
				rht = CFrame.new(1, -1, 0.2) * CFrame.fromEulerAngles(0.349 * math.sin(timingsine * 8), 1.222 + 0.349 * math.sin((timingsine - 1) * 8), 0.175 + 0.349 * math.sin(timingsine * 8))
				lst = CFrame.new(-1, 0.4, 0) * CFrame.fromEulerAngles(0, -0.785 + 0.698 * math.sin(timingsine * 8), -1.571 + 0.698 * math.sin((timingsine + 0.125) * 8))
				lht = CFrame.new(-1, -1, 0.2) * CFrame.fromEulerAngles(-0.349 * math.sin(timingsine * 8), -1.222 + 0.349 * math.sin((timingsine - 1) * 8), -0.175 + 0.349 * math.sin(timingsine * 8))
				rst = CFrame.new(1, 0.4, 0) * CFrame.fromEulerAngles(0, 0.785 + 0.698 * math.sin(timingsine * 8), 1.571 + 0.698 * math.sin((timingsine + 0.125) * 8))
				rt = CFrame.fromEulerAngles(-1.396, 0.052 * math.sin(timingsine * 8), 3.142 + 0.175 * math.sin(timingsine * 8))
			else
				rt = CFrame.new(0, 0, 0, -1, 0, 0, 0, 0, 1, 0, 1, 0) * CFrame.new(0, 0, -0.1 + 0.1 * math.cos(timingsine * 3)) * CFrame.Angles(math.rad(24), 0, 0)
				nt = CFrame.new(0, 1, 0, -1, 0, 0, 0, 0, 1, 0, 1, 0) * CFrame.Angles(math.rad(12.5 * math.cos(timingsine * 2)), 0, 0)
				rht = CFrame.new(1, -1 - 0.1 * math.cos(timingsine * 3), -0.3) * CFrame.Angles(0, 1.6, 0) * CFrame.Angles(math.rad(-3.5), 0, 0)
				lht = CFrame.new(-1, -0.8 - 0.1 * math.cos(timingsine * 3), -0.3) * CFrame.Angles(0, -1.6, 0) * CFrame.Angles(math.rad(-3.5), 0, 0)
				rst = CFrame.new(1.5, 0.5 + 0.02 * math.sin(timingsine * 3), 0) * CFrame.Angles(math.rad(65), math.rad(-0.6), math.rad(45 + 4.5 * math.sin(timingsine * 3)))
				lst = CFrame.new(-1.5, 0.5 + 0.02 * math.sin(timingsine * 3), 0) * CFrame.Angles(math.rad(55), math.rad(-0.6), math.rad(-45 - 4.5 * math.sin(timingsine * 3)))
			end
			return rt, nt, rst, lst, rht, lht, 16
		end,
		flamethrow = function(timingsine, rt, nt, rst, lst, rht, lht)
			rt = CFrame.Angles(-1.483, 0, 3.141)
			nt = CFrame.new(0, 1, 0.1) * CFrame.Angles(-1.658, 0, 3.141)
			rst = CFrame.new(1, 0.5 + 0.1 * math.sin(timingsine * 1.5), -0.2) * CFrame.Angles(1.832 + 0.087 * math.sin(timingsine * 9 + 1.349), 1.221 + 0.087 * math.sin(timingsine * 4 + 1.2), -0.349 + 0.087 * math.sin(timingsine * 16))
			lst = CFrame.new(-1, 0.5 + 0.1 * math.sin(timingsine * 1.5), -0.2) * CFrame.fromEulerAnglesXYZ(1.832 + 0.087 * math.sin(timingsine * 9), -1.221 + 0.087 * math.sin(timingsine * 4 + 1.2), 0.349 + 0.087 * math.sin(timingsine * 16 + 2.4))
			return rt, nt, rst, lst, rht, lht, 12
		end,
		bombthrow = function(timingsine, rt, nt, rst, lst, rht, lht)
			rt = CFrame.Angles(-1.57, 0, 3.141 + -0.087 * math.sin(timingsine))
			lst = CFrame.new(-1, 0.5 + 0.2 * math.sin(timingsine), 0.2 * math.sin(timingsine + 4.883)) * CFrame.fromEulerAnglesXYZ(0.349 + 1.57 * math.sin(timingsine), -1.57 + 0.349 * math.sin(timingsine + 4.883), 0)
			return rt, nt, rst, lst, rht, lht, 20
		end,
	}
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
	end
	local function MeleeEffect(targets)
		for _,v in targets do
			CreateSound(v, "140626490819228", 1, 2)
			MagicSphere(Vector3.one, 30, v.CFrame, Color3.new(1, 0, 0), Vector3.one * 0.15)
		end
	end
	local function BootsEffect(part, typ, thic, leng)
		thic = thic or 1
		leng = leng or 8
		local COL = Color3.new(1, 0.5, 0)
		local inf = part.CFrame:VectorToObjectSpace(part.Velocity / 60) * 0.9
		local ground = PhysicsRaycast(part.CFrame * Vector3.new(0, -0.9 * scale, 0), part.CFrame.UpVector * -(8 + leng) * scale)
		local dist = ground and math.min(ground.Distance / leng, 1) or 1
		if inf.Y < -50 then
			dist *= -50 / inf.Y
		end
		if typ == "IGNITION" then
			MagicSphere(
				Vector3.zero, 5, part.CFrame * CFrame.new(0, -1 * scale, 0), COL,
				Vector3.new(2, 0.1, 2):Lerp(Vector3.new(2, 0.05 * leng, 2), dist) * scale,
				Vector3.new(0, 0, 0):Lerp(Vector3.new(0, -0.05 * leng, 0), dist) * scale + inf
			)
		end
		if typ == "THRUST" then
			MagicSphere(
				Vector3.one * scale, 10, part.CFrame * CFrame.new(0, -1 * scale, 0), COL,
				Vector3.new(0.5 * thic, 0.1, 0.5 * thic):Lerp(Vector3.new(thic - 1.1, 0.025 * leng, thic - 1.1), dist) * scale,
				Vector3.new(0, 0, 0):Lerp(Vector3.new(0, -0.05 * leng, 0), dist) * scale + inf
			)
		end
		if typ == "IGNITION_" then
			MagicSphere(
				Vector3.zero, 5, part.CFrame * CFrame.new(0, -1 * scale, 0), COL,
				Vector3.new(2, 0.1, 2):Lerp(Vector3.new(2, 0.05 * leng, 2), dist) * scale,
				Vector3.new(0, 0, 0):Lerp(Vector3.new(0, -0.05 * leng, 0), dist) * scale
			)
		end
		if typ == "THRUST_" then
			MagicSphere(
				Vector3.one * scale, 10, part.CFrame * CFrame.new(0, -1 * scale, 0), COL,
				Vector3.new(0.5 * thic, 0.1, 0.5 * thic):Lerp(Vector3.new(thic - 1.1, 0.025 * leng, thic - 1.1), dist) * scale,
				Vector3.new(0, 0, 0):Lerp(Vector3.new(0, -0.05 * leng, 0), dist) * scale
			)
		end
		if ground then
			local dist = ground.Distance / 16
			MagicSphere(
				Vector3.new(0, 0, 0.05) * scale, 20, CFrame.lookAlong(ground.Position, ground.Normal), Color3.new(1, 1, 1),
				Vector3.new(1, 1, 0):Lerp(Vector3.new(0.2, 0.2, 0), math.pow(dist, 3)) * scale,
				Vector3.new(0, 0, 0), dist * 0.05 + 0.95
			)
		end
	end
	local PrimaryMelee_index = 1
	local PrimaryMelee_lastatk = 0
	local function PrimaryMelee()
		if not m.IgnoreDancing then
			if isdancing then return end
		end
		if attacking and not m.NoCooldown then return end
		if not root or not hum or not torso then return end
		local rootu = root
		attacking = true
		if os.clock() - PrimaryMelee_lastatk > 1 then
			PrimaryMelee_index = 0
			randomdialog({
				"Neutralizing Threat...",
				"Eliminating Target...",
				"Target Locking On...",
				"Executing Melee Protocol...",
				"Close Combat In Progress...",
			})
		end
		PrimaryMelee_lastatk = os.clock()
		local lol = PrimaryMelee_index
		PrimaryMelee_index = (PrimaryMelee_index + 1) % 3
		task.spawn(function()
			if lol == 0 then
				CreateSound("133409185965864", 1, 2)
				animationOverride = function(timingsine, rt, nt, rst, lst, rht, lht)
					rt, nt, rst, lst, rht, lht = lerps.punch(0, rt, nt, rst, lst, rht, lht)
					return rt, nt, rst, lst, rht, lht, 30
				end
				task.wait(0.1)
				if not rootu:IsDescendantOf(workspace) then
					return
				end
				CreateSound("140309071002261", 1, 2)
				local start = timingsine
				local seconds = 0.2
				animationOverride = function(timingsine, rt, nt, rst, lst, rht, lht)
					local c = (1 - ((1 - math.min((timingsine - start) / seconds, 1)) ^ 2)) * math.pi
					rt, nt, rst, lst, rht, lht = lerps.punch(c, rt, nt, rst, lst, rht, lht)
					return rt, nt, rst, lst, rht, lht, 30
				end
				task.wait(seconds / 2)
				if not rootu:IsDescendantOf(workspace) then
					return
				end
				MeleeEffect(Attack(rootu.CFrame * CFrame.new(-0.5 * scale, 0, -3 * scale), Vector3.new(4, 4, 5) * scale))
				task.wait(seconds / 2 + 0.1)
				if not rootu:IsDescendantOf(workspace) then
					return
				end
			end
			if lol == 1 then
				CreateSound("127208366965459", 1, 2)
				animationOverride = function(timingsine, rt, nt, rst, lst, rht, lht)
					rt, nt, rst, lst, rht, lht = lerps.punch(math.pi, rt, nt, rst, lst, rht, lht)
					return rt, nt, rst, lst, rht, lht, 30
				end
				task.wait(0.1)
				if not rootu:IsDescendantOf(workspace) then
					return
				end
				CreateSound("140309071002261", 1, 2)
				local start = timingsine
				local seconds = 0.2
				animationOverride = function(timingsine, rt, nt, rst, lst, rht, lht)
					local c = (1 - ((1 - math.min((timingsine - start) / seconds, 1)) ^ 2)) * math.pi + math.pi
					rt, nt, rst, lst, rht, lht = lerps.punch(c, rt, nt, rst, lst, rht, lht)
					return rt, nt, rst, lst, rht, lht, 30
				end
				task.wait(seconds / 2)
				if not rootu:IsDescendantOf(workspace) then
					return
				end
				MeleeEffect(Attack(rootu.CFrame * CFrame.new(0.5 * scale, 0, -3 * scale), Vector3.new(4, 4, 5) * scale))
				task.wait(seconds / 2 + 0.1)
				if not rootu:IsDescendantOf(workspace) then
					return
				end
			end
			if lol == 2 then
				animationOverride = function(timingsine, rt, nt, rst, lst, rht, lht)
					rt, nt, rst, lst, rht, lht = lerps.kick(0, rt, nt, rst, lst, rht, lht)
					return rt, nt, rst, lst, rht, lht, 30
				end
				task.wait(0.1)
				if not rootu:IsDescendantOf(workspace) then
					return
				end
				CreateSound("137298186656357", 0.7, 2)
				local start = timingsine
				local seconds = 0.2
				animationOverride = function(timingsine, rt, nt, rst, lst, rht, lht)
					local c = math.min((timingsine - start) / seconds, 1) * math.pi
					rt, nt, rst, lst, rht, lht = lerps.kick(c, rt, nt, rst, lst, rht, lht)
					return rt, nt, rst, lst, rht, lht, 20
				end
				task.wait(seconds / 2)
				if not rootu:IsDescendantOf(workspace) then
					return
				end
				MeleeEffect(Attack(rootu.CFrame * CFrame.new(0, 0, -3 * scale), Vector3.new(6, 5, 5) * scale))
				task.wait(seconds / 2 + 0.2)
				if not rootu:IsDescendantOf(workspace) then
					return
				end
			end
			animationOverride = nil
			attacking = false
		end)
	end
	local function PrimaryRanged()
		if not m.IgnoreDancing then
			if isdancing then return end
		end
		if attacking and not m.NoCooldown then return end
		if not root or not hum or not torso then return end
		local rootu = root
		attacking = true
		PrimaryMelee_index = 0
		if os.clock() - PrimaryMelee_lastatk > 1 then
			randomdialog({
				"Suppressing Threat...",
				"Eliminating Target...",
				"Target Locking On...",
				"Executing Ranged Protocol...",
				"Distanced Combat In Progress...",
				"Shot Fired"
			})
		end
		PrimaryMelee_lastatk = os.clock()
		task.spawn(function()
			animationOverride = function(timingsine, rt, nt, rst, lst, rht, lht)
				rt, nt, rst, lst, rht, lht = lerps.shoot(math.pi / 2, rt, nt, rst, lst, rht, lht)
				AimTowards(MouseHit())
				return rt, nt, rst, lst, rht, lht, 20
			end
			task.wait(0.1)
			if not rootu:IsDescendantOf(workspace) then
				return
			end
			CreateSound("156572165", 1, 2)
			CreateSound("130679953063646", 1, 2)
			local target = MouseHit()
			local hole = root.CFrame * CFrame.new(Vector3.new(1, 0.5, -5) * scale)
			hole = HatReanimator.GetAttachmentCFrame(gun.Group .. "Attachment") or hole
			local raycast = PhysicsRaycast(hole.Position, target - hole.Position)
			if raycast then
				target = raycast.Position
			end
			SetBulletState(hole.Position, target)
			Attack(CFrame.lookAt((hole.Position + target) / 2, target), Vector3.new(3, 3, (target - hole.Position).Magnitude))
			MagicSphere(Vector3.zero, 20, hole, Color3.new(1, 1, 0), Vector3.one * 0.3)
			MagicSphere(Vector3.zero, 20, CFrame.new(target), Color3.new(1, 1, 0), Vector3.one * 0.3)
			MagicSphere(Vector3.new(0, 0, (target - hole.Position).Magnitude), 10, CFrame.lookAt((hole.Position + target) / 2, target), Color3.new(1, 1, 0), Vector3.new(0.2, 0.2, 0))
			animationOverride = function(timingsine, rt, nt, rst, lst, rht, lht)
				rt, nt, rst, lst, rht, lht = lerps.shoot(-math.pi / 2, rt, nt, rst, lst, rht, lht)
				AimTowards(target)
				return rt, nt, rst, lst, rht, lht, 20
			end
			task.wait(0.1)
			if not rootu:IsDescendantOf(workspace) then
				return
			end
			animationOverride = nil
			attacking = false
		end)
	end
	local SecondaryMelee_isrunning = false
	local function SecondaryMelee()
		if SecondaryMelee_isrunning then
			SecondaryMelee_isrunning = false
			return
		end
		if not m.IgnoreDancing then
			if isdancing then return end
		end
		if attacking and not m.NoCooldown then return end
		if not root or not hum or not torso then return end
		local rootu = root
		local larm, rarm = rootu.Parent:FindFirstChild("Left Arm"), rootu.Parent:FindFirstChild("Right Arm")
		attacking = true
		PrimaryMelee_index = 0
		if os.clock() - PrimaryMelee_lastatk > 1 then
			randomdialog({
				"Incinerating Threat...",
				"Burning Target...",
				"Target Locking On...",
				"Executing Burn Protocol...",
				"Close Combat In Progress...",
			})
		end
		PrimaryMelee_lastatk = os.clock()
		SecondaryMelee_isrunning = true
		task.spawn(function()
			animationOverride = function(timingsine, rt, nt, rst, lst, rht, lht)
				rt, nt, rst, lst, rht, lht = lerps.flamethrow(timingsine, rt, nt, rst, lst, rht, lht)
				return rt, nt, rst, lst, rht, lht, 4
			end
			local sound = Instance.new("Sound", rootu)
			sound.SoundId = "rbxassetid://118325610335607"
			sound.Volume = 2
			sound.EmitterSize = 300
			sound:Play()
			local s = os.clock()
			repeat
				task.wait()
				if not rootu:IsDescendantOf(workspace) then
					SecondaryMelee_isrunning = false
					return
				end
			until not SecondaryMelee_isrunning or os.clock() - s >= 0.75
			if not SecondaryMelee_isrunning then
				TweenService:Create(sound, TweenInfo.new(0.2, Enum.EasingStyle.Linear), {Volume = 0}):Play()
				Debris:AddItem(sound, 0.2)
				animationOverride = nil
				attacking = false
			end
			animationOverride = function(timingsine, rt, nt, rst, lst, rht, lht)
				rt, nt, rst, lst, rht, lht = lerps.flamethrow(timingsine, rt, nt, rst, lst, rht, lht)
				return rt, nt, rst, lst, rht, lht, 30
			end
			if larm and rarm then
				BootsEffect(larm, "IGNITION_", 1.3, 16)
				BootsEffect(rarm, "IGNITION_", 1.3, 16)
			end
			s = os.clock()
			repeat
				if larm and rarm then
					BootsEffect(larm, "THRUST_", 1.3, 16)
					BootsEffect(rarm, "THRUST_", 1.3, 16)
				end
				if os.clock() % 1 < 0.5 then
					SetBulletState(larm.CFrame * Vector3.new(0, -1 * scale, 0), larm.CFrame * Vector3.new(0, -8 * scale, 0))
				else
					SetBulletState(rarm.CFrame * Vector3.new(0, -1 * scale, 0), rarm.CFrame * Vector3.new(0, -8 * scale, 0))
				end
				Attack(rootu.CFrame * CFrame.new(0, 0.5, -5 * scale), Vector3.new(6, 3, 8) * scale)
				task.wait()
				if not rootu:IsDescendantOf(workspace) then
					SecondaryMelee_isrunning = false
					return
				end
			until not SecondaryMelee_isrunning or os.clock() - s >= 5
			if not SecondaryMelee_isrunning then
				TweenService:Create(sound, TweenInfo.new(0.2, Enum.EasingStyle.Linear), {Volume = 0}):Play()
				Debris:AddItem(sound, 0.2)
				animationOverride = nil
				attacking = false
			end
			animationOverride = nil
			attacking = false
		end)
	end
	local BomboReference = nil
	local function SecondaryRanged()
		if not m.IgnoreDancing then
			if isdancing then return end
		end
		if attacking and not m.NoCooldown then return end
		if not root or not hum or not torso then return end
		local rootu = root
		local larm = rootu.Parent:FindFirstChild("Left Arm")
		if not larm then return end
		attacking = true
		PrimaryMelee_index = 0
		if os.clock() - PrimaryMelee_lastatk > 1 then
			randomdialog({
				"Suppressing Threat...",
				"Eliminating Target...",
				"Target Locking On...",
				"Executing Explosion Protocol...",
				"Distanced Combat In Progress...",
				"Bomb Thrown"
			})
		end
		PrimaryMelee_lastatk = os.clock()
		task.spawn(function()
			local start = timingsine
			animationOverride = function(timingsine, rt, nt, rst, lst, rht, lht)
				rt, nt, rst, lst, rht, lht = lerps.bombthrow(((timingsine - start) / 0.5 + 1) * math.pi, rt, nt, rst, lst, rht, lht)
				AimTowards(MouseHit())
				return rt, nt, rst, lst, rht, lht, 20
			end
			CreateSound("122106682283174", 1, 0.5)
			CreateSound("137298186656357", 0.7, 2)
			task.wait(0.3)
			if not rootu:IsDescendantOf(workspace) then
				return
			end
			local bombo = CreatePart(CFrame.identity, Vector3.one, Color3.new(1, 0, 0), "Plastic", 0, 0)
			BomboReference = bombo
			local s = os.clock()
			repeat
				bombo.CFrame = larm.CFrame * CFrame.new(0, -1.5, 0)
				task.wait()
				if not rootu:IsDescendantOf(workspace) then
					bombo:Destroy()
					return
				end
			until os.clock() - s >= 0.3
			local target = MouseHit()
			local speed = 35 * scale
			local aim = target - bombo.Position
			do
				local gravity = workspace.Gravity
				local xz = Vector3.new(aim.X, 0, aim.Z)
				local x = xz.Magnitude
				local y = aim.Y
				local v2 = speed * speed
				local v4 = v2 * v2
				local root = v4 - gravity * (gravity * x * x + 2 * y * v2)
				local angle = math.rad(45)
				if root > 0 then
					angle = math.min(math.atan((v2 - math.sqrt(root)) / (gravity * x)), math.rad(45))
				end
				aim = Vector3.new(0, math.sin(angle), 0) + xz.Unit * math.cos(angle)
			end
			bombo.CanCollide = true
			bombo.Anchored = false
			bombo.Velocity = aim.Unit * speed
			task.spawn(function()
				for _=1, 3 do
					CreateSound(bombo, "107785733040651")
					task.wait(0.5)
				end
				bombo.Material = "Neon"
				for _=1, 5 do
					CreateSound(bombo, "107785733040651")
					task.wait(0.1)
				end
				bombo.CanCollide = false
				bombo.Anchored = true
				bombo.Transparency = 1
				Attack(bombo.CFrame, Vector3.one * 20)
				for _=1, 20 do
					local randomdir = CFrame.Angles(
						math.random() * math.pi * 2,
						math.random() * math.pi * 2,
						math.random() * math.pi * 2
					).LookVector
					MagicSphere(Vector3.new(4, 4, 12), 10, CFrame.lookAlong(bombo.Position, randomdir), Color3.new(1, 1, 0.7), Vector3.one * -0.8, Vector3.new(0, 0, -2))
				end
				MagicSphere(Vector3.one * 12, 10, bombo.CFrame, Color3.new(1, 0.8, 0.5), Vector3.one * -1.2, Vector3.zero, 0)
				MagicSphere(Vector3.one * 4, 15, bombo.CFrame, Color3.new(1, 0.8, 0.5), Vector3.one * 2.4, Vector3.zero, 0.5)
				MagicSphere(Vector3.one * 4, 15, CFrame.new(bombo.Position), Color3.new(1, 0.8, 0.5), Vector3.new(3.2, 0.2, 3.2), Vector3.zero, 0.5)
				CreateSound(bombo, "102645835886909")
				task.wait(0.5)
				if BomboReference == bombo then BomboReference = nil end
				Debris:AddItem(bombo, 5)
			end)
			task.wait(0.2)
			if not rootu:IsDescendantOf(workspace) then
				return
			end
			animationOverride = nil
			attacking = false
		end)
	end
	local function SwitchMode()
		if not m.IgnoreDancing then
			if isdancing then return end
		end
		if attacking and not m.NoCooldown then return end
		if not root or not hum or not torso then return end
		local rootu = root
		PrimaryMelee_lastatk = 0
		task.spawn(function()
			if hasgun then
				randomdialog({
					"Close Combat Online",
					"The Banisher Has Been Disarmed",
					"Ranged Protocol Disabled",
					"Optimising For Close Combat...",
				})
				CreateSound("83796427261186", 1, 5)
				animationOverride = function(timingsine, rt, nt, rst, lst, rht, lht)
					rt, nt, rst, lst, rht, lht = lerps.holster(0, rt, nt, rst, lst, rht, lht)
					return rt, nt, rst, lst, rht, lht, 16
				end
				task.wait(0.2)
				if not rootu:IsDescendantOf(workspace) then
					return
				end
				hasgun = false
			else
				CreateSound("83796427261186", 1, 5)
				animationOverride = function(timingsine, rt, nt, rst, lst, rht, lht)
					rt, nt, rst, lst, rht, lht = lerps.holster(0, rt, nt, rst, lst, rht, lht)
					return rt, nt, rst, lst, rht, lht, 16
				end
				task.wait(0.2)
				if not rootu:IsDescendantOf(workspace) then
					return
				end
				randomdialog({
					"Distanced Combat Online",
					"The Banisher Has Been Armed",
					"Ranged Protocol Prepared",
					"Ready To Fire",
				})
				hasgun = true
				gunspin = true
				CreateSound("129433638565138", 1, 5)
				animationOverride = function(timingsine, rt, nt, rst, lst, rht, lht)
					rt, nt, rst, lst, rht, lht = lerps.unholster(0, rt, nt, rst, lst, rht, lht)
					return rt, nt, rst, lst, rht, lht, 6
				end
				task.wait(0.6)
				if not rootu:IsDescendantOf(workspace) then
					return
				end
				gunspin = false
			end
			animationOverride = nil
		end)
	end
	m.Init = function(figure)
		start = os.clock()
		timingsine = 0
		walkspeed = 16
		attacking = false
		hasgun = false
		lastfly = false
		PrimaryMelee_index = 0
		BomboReference = nil
		animationOverride = nil
		SetOverrideMovesetMusic(AssetGetContentId("BanisherTheme.mp3"), "DM DOKURO - GUARDIAN OF THE FORMER SEAS", 1)
		hum = figure:FindFirstChild("Humanoid")
		root = figure:FindFirstChild("HumanoidRootPart")
		torso = figure:FindFirstChild("Torso")
		if not hum then return end
		if not root then return end
		if not torso then return end
		gun = {
			Group = "Gun",
			Limb = "Right Arm",
			Offset = CFrame.identity
		}
		bullet = {
			Group = "Bullet",
			CFrame = CFrame.identity
		}
		table.insert(HatReanimator.HatCFrameOverride, gun)
		table.insert(HatReanimator.HatCFrameOverride, bullet)
		ContextActions:BindAction("Uhhhhhh_BSPrime", function(_, state, _)
			if state == Enum.UserInputState.Begin then
				if hasgun then
					PrimaryRanged()
				else
					PrimaryMelee()
				end
			end
		end, true, Enum.UserInputType.MouseButton1)
		ContextActions:SetTitle("Uhhhhhh_BSPrime", "M1")
		ContextActions:SetPosition("Uhhhhhh_BSPrime", UDim2.new(1, -130, 1, -130))
		ContextActions:BindAction("Uhhhhhh_BSSecon", function(_, state, _)
			if state == Enum.UserInputState.Begin then
				if hasgun then
					SecondaryRanged()
				else
					SecondaryMelee()
				end
			end
		end, true, Enum.KeyCode.R)
		ContextActions:SetTitle("Uhhhhhh_BSSecon", "R")
		ContextActions:SetPosition("Uhhhhhh_BSSecon", UDim2.new(1, -180, 1, -130))
		ContextActions:BindAction("Uhhhhhh_BSHolst", function(_, state, _)
			if state == Enum.UserInputState.Begin then
				SwitchMode()
			end
		end, true, Enum.KeyCode.F)
		ContextActions:SetTitle("Uhhhhhh_BSHolst", "F")
		ContextActions:SetPosition("Uhhhhhh_BSHolst", UDim2.new(1, -130, 1, -180))
		ContextActions:BindAction("Uhhhhhh_BSRun", function(_, state, _)
			if state == Enum.UserInputState.Begin then
				if walkspeed == 16 then
					randomdialog({
						"Running Protocol Engaged",
						"Movement Speed Increased",
						"I Must Catch Up",
						"Optimising For Higher Ground Speed...",
					})
					walkspeed = 28
				else
					randomdialog({
						"Running Protocol Disengaged",
						"Accuracy Increased",
						"Improving Terrestrial Movement",
						"Optimising For Preciseness...",
					})
					walkspeed = 16
				end
			end
		end, true, Enum.KeyCode.LeftControl)
		ContextActions:SetTitle("Uhhhhhh_BSRun", "Run")
		ContextActions:SetPosition("Uhhhhhh_BSRun", UDim2.new(1, -180, 1, -180))
		task.delay(0.2, randomdialog, {
			"Kernel BANISHER.BIN Loaded",
			"Your Time-To-Live is about to reach 0.",
			"Combat Protocol Engaged",
			"Deployment Successful",
			"Boot Sequence Complete",
		})
		if chatconn then
			chatconn:Disconnect()
		end
		chatconn = OnPlayerChatted.Event:Connect(function(plr, msg)
			if plr == Player then
				notify(msg)
			end
		end)
		flysound = Instance.new("Sound", torso)
		flysound.SoundId = "rbxassetid://128719938523077"
		flysound.Looped = true
		flysound.Pitch = 1
		flysound.Volume = 0
		flysound.EmitterSize = 300
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
		local torsooff = CFrame.identity

		local gofly = false
		if attacking then
			hum.WalkSpeed = 8 * scale
			hum.JumpPower = 0
		else
			hum.WalkSpeed = walkspeed * scale
			if onground then
				hum.JumpPower = 50 * scale
			else
				hum.JumpPower = 0
			end
		end
		if onground then
			mustfly = 0.2
		else
			mustfly = math.max(0, mustfly - dt)
		end
		local larm, rarm = figure:FindFirstChild("Left Leg"), figure:FindFirstChild("Right Leg")
		if larm and rarm then
			gofly = mustfly <= 0 and hum.Jump
			if lastfly ~= gofly then
				lastfly = gofly
				if lastfly then
					randomdialog({
						"Rocket Boots Active",
						"Executing Flight Protocol...",
						"Lifting Off Ground...",
						"Flight Achieved",
					})
					CreateSound("123619882242196", 1, 0.5)
					BootsEffect(larm, "IGNITION")
					BootsEffect(rarm, "IGNITION")
					root.Velocity += Vector3.new(0, 50, 0)
				else
					CreateSound("128788885488982", 1, 0.5)
				end
				hum.PlatformStand = false
			end
			if gofly then
				flysound.Volume = math.min(2, flysound.Volume + dt * 8)
				if m.CameraFly then
					local dir = (ReanimCamera.CFrame.LookVector * 2 + hum.MoveDirection).Unit
					hum.WalkSpeed = 0.001
					hum.PlatformStand = true
					local vel = root.Velocity
					vel += (dir * Vector3.new(112, 49, 112) + Vector3.new(0, workspace.Gravity + 1, 0)) * dt
					local xz = vel * Vector3.new(1, 0, 1)
					if xz.Magnitude > 112 * scale then
						xz = xz.Unit * 112 * scale
					end
					root.Velocity = xz + Vector3.new(0, vel.Y, 0)
					root.RotVelocity = Vector3.zero
					local cf = CFrame.lookAlong(Vector3.zero, dir) * CFrame.Angles(-1.5, 0, 0)
					torsooff = root.CFrame.Rotation:ToObjectSpace(cf)
					if hum.EvaluateStateMachine then
						root.CFrame = CFrame.lookAlong(Vector3.zero, cf.UpVector * Vector3.new(1, 0.001, 1)) + root.CFrame.Position
					end
				else
					hum.WalkSpeed = 112 * scale
					root.Velocity += Vector3.new(0, workspace.Gravity + 50, 0) * dt
				end
				BootsEffect(larm, "THRUST")
				BootsEffect(rarm, "THRUST")
			else
				flysound.Volume = math.max(0, flysound.Volume - dt * 8)
			end
			flysound.Playing = flysound.Volume > 0.05
		end

		local rt, nt, rst, lst, rht, lht = CFrame.identity, CFrame.identity, CFrame.identity, CFrame.identity, CFrame.identity, CFrame.identity
		timingsine += dt

		local torsovelocity = root.Velocity.Magnitude / scale
		local torsovelocityy = root.Velocity.Y / scale
		local torsorvelocityy = root.RotVelocity.Y
		local animationspeed = 8
		local walkval = torsovelocity / 10
		walktime += dt * walkval
		walktime %= 2 * math.pi
		local fallval = math.min(math.abs(torsovelocityy) / 50, 1.3)
		falltime += dt * fallval
		falltime %= 2 * math.pi
		local rw = root.CFrame.RightVector:Dot(root.Velocity) / scale
		local lw = root.CFrame.LookVector:Dot(root.Velocity) / scale
		if onground then
			if torsovelocity < 1 then
				if hasgun then
					rt, nt, rst, lst, rht, lht, animationspeed = lerps.gidle(timingsine, rt, nt, rst, lst, rht, lht)
				else
					rt, nt, rst, lst, rht, lht, animationspeed = lerps.idle(timingsine, rt, nt, rst, lst, rht, lht)
				end
			elseif torsovelocity < 20 then
				if hasgun then
					rt, nt, rst, lst, rht, lht, animationspeed = lerps.gwalk(walktime, rt, nt, rst, lst, rht, lht)
				else
					rt, nt, rst, lst, rht, lht, animationspeed = lerps.walk(walktime, rt, nt, rst, lst, rht, lht)
				end
			else
				rt, nt, rst, lst, rht, lht, animationspeed = lerps.run(walktime, rt, nt, rst, lst, rht, lht)
			end
		else
			if hum.Jump then
				rt, nt, rst, lst, rht, lht, animationspeed = lerps.fly(timingsine, rt, nt, rst, lst, rht, lht)
			else
				rt, nt, rst, lst, rht, lht, animationspeed = lerps.fall(falltime, rt, nt, rst, lst, rht, lht)
				rt = CFrame.lookAt(Vector3.zero, Vector3.new(0, torsovelocityy, -100)) * rt
			end
		end
		if not lastfly or not m.CameraFly then
			torsooff *= CFrame.Angles(lw * -0.01, 0, rw * -0.01)
		end
		rt = torsooff * rt
		if animationOverride then
			rt, nt, rst, lst, rht, lht, animationspeed = animationOverride(timingsine, rt, nt, rst, lst, rht, lht)
		end

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

		SetC0C1Joint(rj, joints.r, CFrame.new(0, 0, 0, -1, 0, 0, 0, 0, 1, 0, 1, 0), scale)
		SetC0C1Joint(nj, joints.n, CFrame.new(0, -0.5, 0, -1, 0, 0, 0, 0, 1, 0, 1, 0), scale)
		SetC0C1Joint(rsj, joints.rs, CFrame.new(-0.5, 0.5, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0), scale)
		SetC0C1Joint(lsj, joints.ls, CFrame.new(0.5, 0.5, 0, 0, 0, -1, 0, 1, 0, 1, 0, 0), scale)
		SetC0C1Joint(rhj, joints.rh, CFrame.new(0.5, 1, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0), scale)
		SetC0C1Joint(lhj, joints.lh, CFrame.new(-0.5, 1, 0, 0, 0, -1, 0, 1, 0, 1, 0, 0), scale)

		if m.UseSword then
			gun.Group = "Sword"
		else
			gun.Group = "Gun"
		end
		if gunspin then
			gun.Offset = CFrame.new(0, -1, -0.5) * CFrame.Angles(0.8, math.pi / 2, 0) * CFrame.Angles((t * 50) % (2 * math.pi), 0, 0) * CFrame.Angles(math.rad(180), math.rad(180), 0)
		else
			gun.Offset = CFrame.new(0, -1, -0.5) * CFrame.Angles(math.rad(180), 0, 0)
		end
		gun.Disable = (not not isdancing) or not hasgun

		if BomboReference then
			if not BomboReference:IsDescendantOf(workspace) then
				BomboReference = nil
			end
		end

		if bulletstate[3] < os.clock() - 0.5 then
			if BomboReference then
				bullet.CFrame = BomboReference.CFrame
			elseif gofly then
				bullet.CFrame = torso.CFrame * CFrame.new(math.random() * 2 - 1, -3, math.random() - 0.5)
			else
				bullet.CFrame = root.CFrame + Vector3.new(math.sin(t), -2, math.cos(t)) * scale * 6
			end
		else
			local pos = (os.clock() // 0.05) % 2
			if pos == 0 then
				bullet.CFrame = CFrame.Angles(math.random() * math.pi * 2, math.random() * math.pi * 2, math.random() * math.pi * 2) + bulletstate[1]
			else
				bullet.CFrame = CFrame.Angles(math.random() * math.pi * 2, math.random() * math.pi * 2, math.random() * math.pi * 2) + bulletstate[2]
			end
		end
	end
	m.Destroy = function(figure)
		ContextActions:UnbindAction("Uhhhhhh_BSPrime")
		ContextActions:UnbindAction("Uhhhhhh_BSSecon")
		ContextActions:UnbindAction("Uhhhhhh_BSHolst")
		ContextActions:UnbindAction("Uhhhhhh_BSRun")
		root, torso, hum = nil, nil, nil
	end
	return m
end)

U.run()
