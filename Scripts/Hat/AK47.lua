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
		warn("[AK-47] couldn't load Hub/UhhMoveset.lua")
		return
	end
end

local U = Uhh.new({
	title = "AK-47",
	short = "ak",
	jobs = { { "gun", "Gun" }, { "aim", "Aiming" }, { "bullet", "Bullet" } },
	groups = { Gun = "gun", Sword = "gun", Bullet = "bullet" },
	aim = { job = "aim", base = "gun" },
	need = "gun",
	hint = "Gun moves the rifle, Aiming moves it while you shoot, Bullet moves the hat that flies with the shots.",
	global = "AtsukoAK47",
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
local Util_CreateText = U.Util_CreateText
local Util_CreateSwitch = U.Util_CreateSwitch
local Util_CreateSlider = U.Util_CreateSlider
local HatReanimator = U.HatReanimator
local ReanimateFling = U.ReanimateFling
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
local flight, isdancing, timingwalk1, timingwalk2

AddModule(function()
	local m = {}
	m.ModuleType = "MOVESET"
	m.Name = "AK-47"
	m.InternalName = "WHATCOMESBEFORE47"
	m.Description = "\"what comes before 47?\"\n\"AK.\"\nrecreation of genesis' AK-47. lerps made by @scripterguy_1000, reiterations by STEVE\nM1 - Shoot"
	m.Assets = {}

	m.Sounds = true
	m.UseSword = false
	m.BooletsPerSec = 10
	m.Config = function(parent)
		Util_CreateSwitch(parent, "Sounds", m.Sounds).Changed:Connect(function(val)
			m.Sounds = val
		end)
		Util_CreateText(parent, "Use the sword instead of the gun!", 12, Enum.TextXAlignment.Center)
		Util_CreateSwitch(parent, "Gun = Sword", m.UseSword).Changed:Connect(function(val)
			m.UseSword = val
		end)
		Util_CreateText(parent, "for optimisation reasons, you can only fire max 20 bullets in a frame", 12, Enum.TextXAlignment.Center)
		Util_CreateSlider(parent, "Bullets Per Second", m.BooletsPerSec, 5, 240, 1).Changed:Connect(function(val)
			m.BooletsPerSec = val
		end)
	end
	m.LoadConfig = function(save)
		m.Sounds = not save.Muted
		m.UseSword = not not save.UseSword
		m.BooletsPerSec = save.BooletsPerSec or m.BooletsPerSec
	end
	m.SaveConfig = function()
		return {
			Muted = not m.Sounds,
			UseSword = m.UseSword,
			BooletsPerSec = m.BooletsPerSec,
		}
	end

	local start = 0
	local hum, root, torso
	local scale = 1
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
	local mouselock = false
	local function MouseHit()
		local Camera = workspace.CurrentCamera
		local ray = mouse.UnitRay
		if mouselock and Camera then
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
		if typeof(id) == "Instance" then
			parent = id
			id, pitch = pitch, extra
		end
		pitch = pitch or 1
		local sound = Instance.new("Sound")
		sound.Name = tostring(id)
		sound.SoundId = "rbxassetid://" .. id
		sound.Volume = 1
		sound.Pitch = pitch
		sound.EmitterSize = 100
		sound.Parent = parent
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
	local chatconn
	local attacking = false
	local joints = {
		r = CFrame.identity,
		n = CFrame.identity,
		rs = CFrame.identity,
		ls = CFrame.identity,
		rh = CFrame.identity,
		lh = CFrame.identity,
		sw = CFrame.identity,
	}
	local gun = {}
	local bullet = {}
	local mousedown = false
	local uisbegin, uisend
	local state = 0
	local statetime = 0
	local timingwalk = 0
	local footsteps = nil

	m.Init = function(figure)
		start = os.clock()
		state = 0
		timingwalk1, timingwalk2 = 0, 0
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
		mousedown = false
		if uisbegin then
			uisbegin:Disconnect()
		end
		if uisend then
			uisend:Disconnect()
		end
		local currentclick = nil
		uisbegin = UserInputService.InputBegan:Connect(function(input, gpe)
			if gpe then return end
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				mousedown = true
				mouselock = false
				currentclick = input
			end
		end)
		ContextActions:BindAction("Uhhhhhh_AKShoot", function(_, state, input)
			if state == Enum.UserInputState.Begin then
				mousedown = true
				mouselock = true
				currentclick = input
			end
		end, true)
		ContextActions:SetTitle("Uhhhhhh_AKShoot", "M1")
		ContextActions:SetPosition("Uhhhhhh_AKShoot", UDim2.new(1, -130, 1, -130))
		uisend = UserInputService.InputEnded:Connect(function(input, gpe)
			if input == currentclick then
				mousedown = false
				currentclick = nil
			end
		end)
		hum.WalkSpeed = 16 * figure:GetScale()
		footsteps = Instance.new("Sound", root)
		footsteps.SoundId = "rbxassetid://4776173570"
		footsteps.Volume = 1
		footsteps.Pitch = 1.25
		footsteps.Looped = true
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

		local rt, nt, rst, lst, rht, lht = CFrame.identity, CFrame.identity, CFrame.identity, CFrame.identity, CFrame.identity, CFrame.identity
		local gunoff = CFrame.new(0, -1, 0.3) * CFrame.Angles(math.rad(190), math.rad(180), 0)

		local timingsine = t * 60
		local onground = hum:GetState() == Enum.HumanoidStateType.Running

		local torsovelocity = root.Velocity.Magnitude
		local torsovelocityy = root.Velocity.Y
		local animationspeed = 16
		local sin30 = math.sin(timingsine / 30)
		if onground then
			if torsovelocity < 1 then
				footsteps.Playing = false
				rt = CFrame.new(0, 0.05 * sin30, 0) * CFrame.Angles(-1.5707963267948966, 0, 3.141592653589793)
				nt = CFrame.new(0, 1, 0) * CFrame.Angles(-1.5707963267948966, 0, 3.141592653589793)
				rst = CFrame.new(0.6, 0.45 + 0.1 * sin30, 0.2) * CFrame.Angles(0, 2.356194490192345, 1.0471975511965976)
				lst = CFrame.new(-0.8, 0.45 + 0.1 * sin30, -0.3) * CFrame.Angles(0, -2.2689280275926285, -0.8726646259971648)
				rht = CFrame.new(1, -1 - 0.05 * sin30, 0.1) * CFrame.Angles(0, 1.3962634015954636, 0)
				lht = CFrame.new(-1, -1 - 0.05 * sin30, 0.1) * CFrame.Angles(0, -1.3089969389957472, 0)
			else
				footsteps.Playing = true
				local d = (hum:GetMoveVelocity().Magnitude / scale) / 16
				local rw = root.CFrame.RightVector:Dot(hum.MoveDirection) * d
				local lw = root.CFrame.LookVector:Dot(hum.MoveDirection) * d
				timingwalk += dt * d
				rt = CFrame.new(0, 0.05 * math.sin(timingwalk * 20), 0) * CFrame.Angles(math.rad(-90 - lw * 10), math.rad(rw * 10), math.rad(180))
				nt = CFrame.new(0, 1, 0) * CFrame.Angles(-1.5707963267948966, 0, 3.141592653589793)
				rst = CFrame.new(0.6, 0.45 + 0.05 * math.sin((timingwalk + 0.5) * 20), 0.2) * CFrame.Angles(0, 2.356194490192345, 1.0471975511965976)
				lst = CFrame.new(-0.8, 0.45 + 0.05 * math.sin((timingwalk + 0.5) * 20), -0.3) * CFrame.Angles(0, -2.2689280275926285, -0.8726646259971648)
				rht = CFrame.new(1 + 0.1 * math.sin((timingwalk - 0.5) * 10) * rw, -1 - 0.05 * math.sin(timingwalk * 20), 0.1 + 0.1 * math.sin((timingwalk - 0.5) * 10) * lw) * CFrame.Angles(0, 1.5707963267948966 - 0.2 * rw, -0.17453292519943295 + 1.0471975511965976 * math.sin((timingwalk + 1) * 10))
				lht = CFrame.new(-1 + 0.1 * math.sin((timingwalk - 0.5) * 10) * rw, -1 - 0.05 * math.sin(timingwalk * 20), 0.1 + 0.1 * math.sin((timingwalk - 0.5) * 10) * lw) * CFrame.Angles(0, -1.5707963267948966 - 0.2 * rw, 0.17453292519943295 + 1.0471975511965976 * math.sin((timingwalk + 1) * 10))
			end
		else
			footsteps.Playing = false
			rt = CFrame.Angles(-1.5707963267948966 + math.clamp(torsovelocityy, -50, 50) * 0.004, 0, 3.141592653589793)
			nt = CFrame.new(0, 1, 0) * CFrame.Angles(-1.6580627893946132, 0, 3.141592653589793)
			rst = CFrame.new(0.6, 0.5, -0.1) * CFrame.Angles(0.08, 0, 0) * CFrame.Angles(0, 2.356194490192345, 1.0471975511965976)
			lst = CFrame.new(-0.8, 0.5, -0.6) * CFrame.Angles(0.08, 0, 0) * CFrame.Angles(0, -2.2689280275926285, -0.8726646259971648)
			rht = CFrame.new(1.1, -0.9, -0.2) * CFrame.Angles(0, 1.5707963267948966, -0.3490658503988659)
			lht = CFrame.new(-1.1, -0.8, -1) * CFrame.Angles(0, -1.4835298641951802, 0.5235987755982988)
		end
		if state == 0 then
			bullet.CFrame = root.CFrame + Vector3.new(0, -8, 0) * scale
			if mousedown and not isdancing then
				state = 1
				statetime = os.clock()
			end
		elseif state == 1 then
			local hit = MouseHit()
			AimTowards(hit)
			footsteps.Playing = false
			rst = CFrame.new(0.6, 0.05 * sin30, 0.1) * CFrame.Angles(0, 1.7453292519943295, 1.7453292519943295)
			lst = CFrame.new(-0.4, 0.5 + 0.05 * sin30, -0.7) * CFrame.Angles(0, -2.6179938779914944, -1.3962634015954636)
			local hole = root.CFrame * CFrame.new(1.5, 0.2, -3)
			hole = HatReanimator.GetAttachmentCFrame(gun.Group .. "Attachment") or hole
			local dir = (hit - hole.Position).Unit
			if dir == dir then
				dir = dir.Unit
			else
				dir = Vector3.zAxis
			end
			local cast = ShootRaycast(hole.Position, dir * 4096)
			if cast then
				hit = cast.Position
				local part = cast.Instance
				if part and part.Parent and part.Parent.Parent then
					local hum = part.Parent:FindFirstChildOfClass("Humanoid") or part.Parent.Parent:FindFirstChildOfClass("Humanoid")
					if hum and hum.RootPart and not hum.RootPart:IsGrounded() then
						ReanimateFling(hum.Parent)
					end
				end
			else
				hit = hole.Position + dir * 4096
			end
			local shots = math.min((os.clock() - statetime) * m.BooletsPerSec, 24)
			while shots > 1 do
				shots -= 1
				local ti = TweenInfo.new(0.1, Enum.EasingStyle.Linear)
				local shootfx = Instance.new("Part", workspace)
				shootfx.Name = RandomString()
				shootfx.Anchored = true
				shootfx.CanCollide = false
				shootfx.CanTouch = false
				shootfx.CanQuery = false
				shootfx.Color = Color3.new(1, 1, 0)
				shootfx.CastShadow = false
				shootfx.Material = "Neon"
				shootfx.Size = Vector3.zero
				shootfx.Transparency = 0
				shootfx.CFrame = CFrame.Angles(math.random() * math.pi * 2, math.random() * math.pi * 2, math.random() * math.pi * 2) + hole.Position
				TweenService:Create(shootfx, ti, {Transparency = 1, Size = Vector3.new(2, 2, 2)}):Play()
				CreateSound(shootfx, 2476570846, 0.95 + math.random() * 0.1)
				Debris:AddItem(shootfx, 0.5)
				shootfx = Instance.new("Part", workspace)
				shootfx.Name = RandomString()
				shootfx.Anchored = true
				shootfx.CanCollide = false
				shootfx.CanTouch = false
				shootfx.CanQuery = false
				shootfx.Color = Color3.new(1, 1, 0)
				shootfx.CastShadow = false
				shootfx.Material = "Neon"
				shootfx.Size = Vector3.zero
				shootfx.Transparency = 0
				shootfx.CFrame = CFrame.Angles(math.random() * math.pi * 2, math.random() * math.pi * 2, math.random() * math.pi * 2) + hit
				TweenService:Create(shootfx, ti, {Transparency = 1, Size = Vector3.new(2, 2, 2)}):Play()
				CreateSound(shootfx, 4427231299, 0.9 + math.random() * 0.2)
				Debris:AddItem(shootfx, 0.5)
				local shootline = Instance.new("Part", workspace)
				shootline.Name = RandomString()
				shootline.Anchored = true
				shootline.CanCollide = false
				shootline.CanTouch = false
				shootline.CanQuery = false
				shootline.Color = Color3.new(1, 1, 0)
				shootline.CastShadow = false
				shootline.Material = "Neon"
				shootline.Size = Vector3.new(1, 1, 1)
				shootline.Transparency = 0
				shootline.CFrame = CFrame.lookAt(hole.Position:Lerp(hit, 0.5), hit)
				local shootlinem = Instance.new("SpecialMesh", shootline)
				shootlinem.MeshType = "Brick"
				shootlinem.Scale = Vector3.new(0.1, 0.1, (hit - hole.Position).Magnitude)
				TweenService:Create(shootline, ti, {Transparency = 1}):Play()
				TweenService:Create(shootlinem, ti, {Scale = Vector3.new(0.5, 0.5, (hit - hole.Position).Magnitude)}):Play()
				Debris:AddItem(shootline, 0.5)
				joints.rs += Vector3.new(0, 0, 0.1)
				joints.ls += Vector3.new(0, 0, 0.1)
			end
			local bulletstate = (os.clock() // 0.05) % 2
			if bulletstate == 0 then
				bullet.CFrame = hole
				bullet.LastHit = nil
			else
				if not bullet.LastHit then
					local dir = hit - hole.Position
					if dir.Magnitude > 256 then
						dir = dir.Unit * 256
					end
					bullet.LastHit = hole.Position + dir
				end
				bullet.CFrame = CFrame.new(bullet.LastHit) * CFrame.Angles(math.random() * math.pi * 2, math.random() * math.pi * 2, math.random() * math.pi * 2)
			end
			statetime = os.clock() - shots / m.BooletsPerSec
			if not mousedown or isdancing then
				state = 0
				hum.WalkSpeed = 16 * scale
			end
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
		joints.sw = gunoff:Lerp(joints.sw, alpha)

		SetC0C1Joint(rj, joints.r, CFrame.Angles(-1.57, 0, 3.14), scale)
		SetC0C1Joint(nj, joints.n, CFrame.new(0, -0.5, 0) * CFrame.Angles(math.rad(-90), 0, math.rad(180)), scale)
		SetC0C1Joint(rsj, joints.rs, CFrame.new(0.5, 0.5, 0, 0, 0, -1, 0, 1, 0, 1, 0, 0), scale)
		SetC0C1Joint(lsj, joints.ls, CFrame.new(-0.5, 0.5, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0), scale)
		SetC0C1Joint(rhj, joints.rh, CFrame.new(0.5, 1, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0), scale)
		SetC0C1Joint(lhj, joints.lh, CFrame.new(-0.5, 1, 0, 0, 0, -1, 0, 1, 0, 1, 0, 0), scale)

		if m.UseSword then
			gun.Group = "Sword"
		else
			gun.Group = "Gun"
		end
		gun.Offset = joints.sw
		gun.Disable = not not isdancing
	end
	m.Destroy = function(figure)
		ContextActions:UnbindAction("Uhhhhhh_AKShoot")
		if uisbegin then
			uisbegin:Disconnect()
			uisbegin = nil
		end
		if uisend then
			uisend:Disconnect()
			uisbegin = nil
		end
		root, torso, hum = nil, nil, nil
	end
	return m
end)

U.run()
