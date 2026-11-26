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
		warn("[R6] couldn't load Hub/UhhMoveset.lua")
		return
	end
end

local U = Uhh.new({
	title = "R6",
	short = "r6",
	global = "AtsukoR6",
})
if not U then
	return
end

local cloneref = cloneref or function(o)
	return o
end
local Players = cloneref(game:GetService("Players"))

local Player = Players.LocalPlayer

local function AddModule(m)
	U.add(m)
end
local hclim, toolAnim, toolAnimTime

AddModule(function()
	local m = {}
	m.ModuleType = "MOVESET"
	m.Name = "2015 Roblox"
	m.Description = "workspace." .. Player.Name .. ".Animate\n\"Ahh, the time when Roblox started using Motor6Ds for their animations.\"\n        - Li'l Programmer Timmy born in 2022"
	m.InternalName = "RETROSLOP2"
	m.Assets = {}

	m.Config = function(parent)
	end

	local hstatechange, hrun = nil
	local hum = nil
	local justdanced = false

	local lastpose = ""
	local pose = "Standing"
	local currentAnim = ""
	local currentAnimInstance = nil
	local currentAnimTrack = nil
	local currentAnimKeyframeHandler = nil
	local currentAnimSpeed = 1.0
	local toolAnimName = ""
	local toolAnimTrack = nil
	local toolAnimInstance = nil
	local currentToolAnimKeyframeHandler = nil
	local function resetAnimate()
		if currentAnimTrack then
			currentAnimTrack:Destroy()
		end
		if currentAnimKeyframeHandler then
			currentAnimKeyframeHandler:Disconnect()
		end
		if toolAnimTrack then
			toolAnimTrack:Destroy()
		end
		if currentToolAnimKeyframeHandler then
			currentToolAnimKeyframeHandler:Disconnect()
		end
		currentAnim = ""
		currentAnimInstance = nil
		currentAnimTrack = nil
		currentAnimKeyframeHandler = nil
		currentAnimSpeed = 1.0
		toolAnimName = ""
		toolAnimTrack = nil
		toolAnimInstance = nil
		currentToolAnimKeyframeHandler = nil
	end
	local animTable = {}
	local animNames = {
		idle = {
			{ id = "http://www.roblox.com/asset/?id=180435571", weight = 9 },
			{ id = "http://www.roblox.com/asset/?id=180435792", weight = 1 }
		},
		walk = {
			{ id = "http://www.roblox.com/asset/?id=180426354", weight = 10 }
		},
		run = {
			{ id = "http://www.roblox.com/asset/?id=180426354", weight = 10 }
		},
		jump = 	{
			{ id = "http://www.roblox.com/asset/?id=125750702", weight = 10 }
		},
		fall = 	{
			{ id = "http://www.roblox.com/asset/?id=180436148", weight = 10 }
		},
		climb = {
			{ id = "http://www.roblox.com/asset/?id=180436334", weight = 10 }
		},
		sit = 	{
			{ id = "http://www.roblox.com/asset/?id=178130996", weight = 10 }
		},
		toolnone = {
			{ id = "http://www.roblox.com/asset/?id=182393478", weight = 10 }
		},
		toolslash = {
			{ id = "http://www.roblox.com/asset/?id=129967390", weight = 10 }
		},
		toollunge = {
			{ id = "http://www.roblox.com/asset/?id=129967478", weight = 10 }
		},
		wave = {
			{ id = "http://www.roblox.com/asset/?id=128777973", weight = 10 }
		},
		point = {
			{ id = "http://www.roblox.com/asset/?id=128853357", weight = 10 }
		},
		dance1 = {
			{ id = "http://www.roblox.com/asset/?id=182435998", weight = 10 },
			{ id = "http://www.roblox.com/asset/?id=182491037", weight = 10 },
			{ id = "http://www.roblox.com/asset/?id=182491065", weight = 10 }
		},
		dance2 = {
			{ id = "http://www.roblox.com/asset/?id=182436842", weight = 10 },
			{ id = "http://www.roblox.com/asset/?id=182491248", weight = 10 },
			{ id = "http://www.roblox.com/asset/?id=182491277", weight = 10 }
		},
		dance3 = {
			{ id = "http://www.roblox.com/asset/?id=182436935", weight = 10 },
			{ id = "http://www.roblox.com/asset/?id=182491368", weight = 10 },
			{ id = "http://www.roblox.com/asset/?id=182491423", weight = 10 }
		},
		laugh = {
			{ id = "http://www.roblox.com/asset/?id=129423131", weight = 10 }
		},
		cheer = {
			{ id = "http://www.roblox.com/asset/?id=129423030", weight = 10 }
		},
	}
	local dances = {"dance1", "dance2", "dance3"}
	local emoteNames = { wave = false, point = false, dance1 = true, dance2 = true, dance3 = true, laugh = false, cheer = false}

	local function configureAnimationSet(name)
		local fileList = animNames[name]
		if animTable[name] ~= nil then
			for _, connection in animTable[name].connections do
				connection:Disconnect()
			end
		end
		animTable[name] = {}
		animTable[name].count = 0
		animTable[name].totalWeight = 0
		animTable[name].connections = {}
		for idx, anim in fileList do
			animTable[name][idx] = {}
			animTable[name][idx].anim = Instance.new("Animation")
			animTable[name][idx].anim.Name = name
			animTable[name][idx].anim.AnimationId = anim.id
			animTable[name][idx].weight = anim.weight
			animTable[name].count = animTable[name].count + 1
			animTable[name].totalWeight = animTable[name].totalWeight + anim.weight
		end
	end
	for name,_ in animNames do
		configureAnimationSet(name)
	end
	local function stopAllAnimations()
		local oldAnim = currentAnim
		if emoteNames[oldAnim] ~= nil and emoteNames[oldAnim] == false then
			oldAnim = "idle"
		end
		currentAnim = ""
		currentAnimInstance = nil
		if currentAnimKeyframeHandler ~= nil then
			currentAnimKeyframeHandler:Disconnect()
		end
		if currentAnimTrack ~= nil then
			currentAnimTrack:Stop()
			currentAnimTrack:Destroy()
			currentAnimTrack = nil
		end
		return oldAnim
	end
	local function setAnimationSpeed(speed)
		if speed ~= currentAnimSpeed then
			currentAnimSpeed = speed
			currentAnimTrack:AdjustSpeed(currentAnimSpeed)
		end
	end
	local playAnimation
	local function keyFrameReachedFunc(frameName)
		if frameName == "End" then
			local repeatAnim = currentAnim
			if emoteNames[repeatAnim] ~= nil and emoteNames[repeatAnim] == false then
				repeatAnim = "idle"
			end
			local animSpeed = currentAnimSpeed
			playAnimation(repeatAnim, 0.0, hum)
			setAnimationSpeed(animSpeed)
		end
	end
	playAnimation = function(animName, transitionTime, humanoid)
		if justdanced then return end
		if not animTable[animName] then return end
		local roll = math.random(1, animTable[animName].totalWeight)
		local origRoll = roll
		local idx = 1
		while roll > animTable[animName][idx].weight do
			roll = roll - animTable[animName][idx].weight
			idx = idx + 1
		end
		local anim = animTable[animName][idx].anim
		if anim ~= currentAnimInstance then
			if currentAnimTrack ~= nil then
				currentAnimTrack:Stop(transitionTime)
				currentAnimTrack:Destroy()
			end
			currentAnimSpeed = 1.0
			currentAnimTrack = humanoid:LoadAnimation(anim)
			currentAnimTrack.Priority = Enum.AnimationPriority.Core
			currentAnimTrack:Play(transitionTime)
			currentAnim = animName
			currentAnimInstance = anim
			if currentAnimKeyframeHandler ~= nil then
				currentAnimKeyframeHandler:Disconnect()
			end
			currentAnimKeyframeHandler = currentAnimTrack.KeyframeReached:connect(keyFrameReachedFunc)
		end
	end
	local playToolAnimation
	local function toolKeyFrameReachedFunc(frameName)
		if frameName == "End" then
			playToolAnimation(toolAnimName, 0.0, hum)
		end
	end
	playToolAnimation = function(animName, transitionTime, humanoid, priority)
		if justdanced then return end
		if not animTable[animName] then return end
		local roll = math.random(1, animTable[animName].totalWeight)
		local origRoll = roll
		local idx = 1
		while roll > animTable[animName][idx].weight do
			roll = roll - animTable[animName][idx].weight
			idx = idx + 1
		end
		local anim = animTable[animName][idx].anim
		if toolAnimInstance ~= anim then
			if toolAnimTrack ~= nil then
				toolAnimTrack:Stop()
				toolAnimTrack:Destroy()
				transitionTime = 0
			end
			toolAnimTrack = humanoid:LoadAnimation(anim)
			if priority then
				toolAnimTrack.Priority = priority
			end
			toolAnimTrack:Play(transitionTime)
			toolAnimName = animName
			toolAnimInstance = anim
			currentToolAnimKeyframeHandler = toolAnimTrack.KeyframeReached:connect(toolKeyFrameReachedFunc)
		end
	end
	local function stopToolAnimations()
		local oldAnim = toolAnimName
		if currentToolAnimKeyframeHandler ~= nil then
			currentToolAnimKeyframeHandler:Disconnect()
		end
		toolAnimName = ""
		toolAnimInstance = nil
		if toolAnimTrack ~= nil then
			toolAnimTrack:Stop()
			toolAnimTrack:Destroy()
			toolAnimTrack = nil
		end
		return oldAnim
	end
	local function map(x, inMin, inMax, outMin, outMax)
		return (x - inMin)*(outMax - outMin)/(inMax - inMin) + outMin
	end
	local sndpoint = nil

	m.Init = function(figure)
		hum = figure:FindFirstChild("Humanoid")
		hum.AutoRotate = true
		hum:ChangeState(Enum.HumanoidStateType.Freefall)
		resetAnimate()
		playAnimation("fall", 0.3, hum)
		sndpoint = Instance.new("Attachment")
		sndpoint.Name = "rbxcharactersounds"
		sndpoint.Parent = hum.Torso
		local function makesound(name, id)
			local sound = Instance.new("Sound")
			sound.SoundId = id
			sound.Parent = sndpoint
			sound.RollOffMinDistance = 5
			sound.RollOffMaxDistance = 150
			sound.Volume = 0.85
			sound.Name = name
			return sound
		end
		local run = makesound("Running", "rbxasset://sounds/action_footsteps_plastic.mp3")
		run.Looped = true
		run.PlaybackSpeed = 2
		run.Volume = 1
		local swim = makesound("Swimming", "rbxasset://sounds/action_swim.mp3")
		swim.Looped = true
		swim.PlaybackSpeed = 1.6
		local clim = makesound("Climbing", "rbxasset://sounds/action_footsteps_plastic.mp3")
		clim.Looped = true
		makesound("GettingUp", "rbxasset://sounds/action_get_up.mp3")
		makesound("FallingDown", "rbxasset://sounds/splat.wav")
		makesound("Jumping", "rbxasset://sounds/action_jump.mp3")
		makesound("Landing", "rbxasset://sounds/action_jump_land.mp3")
		makesound("Splash", "rbxasset://sounds/impact_water.mp3")
		hrun = hum.Running:Connect(function(speed)
			speed /= figure:GetScale()
			if speed > 0.01 then
				playAnimation("walk", 0.1, hum)
				setAnimationSpeed(speed / 14.5)
				pose = "Running"
			else
				if emoteNames[currentAnim] == nil then
					playAnimation("idle", 0.1, hum)
					pose = "Standing"
				end
			end
		end)
		hclim = hum.Climbing:Connect(function(speed)
			speed /= figure:GetScale()
			playAnimation("climb", 0.1, hum)
			setAnimationSpeed(speed / 12.0)
			pose = "Climbing"
		end)
		local stateid = 0
		hstatechange = hum.StateChanged:Connect(function(old, new)
			local verticalSpeed = math.abs(hum.RootPart.AssemblyLinearVelocity.Y)
			local state = new.Name
			local id = stateid
			if state ~= "Freefall" then
				id = math.random(-65536, 65536)
				stateid = id
			end
			run.Playing = false
			swim.Playing = false
			clim.Playing = false
			if state == "Jumping" then
				pose = "Jumping"
				playAnimation("jump", 0.1, hum)
				task.delay(0.3, function()
					if stateid == id then
						playAnimation("fall", 0.3, hum)
					end
				end)
				sndpoint.Jumping:Play()
			elseif state == "Seated" then
				pose = "Seated"
			elseif state == "Swimming" then
				if verticalSpeed > 0.1 then
					sndpoint.Splash.Volume = math.clamp(map(verticalSpeed, 100, 350, 0.28, 1), 0, 1)
					sndpoint.Splash:Play()
				end
				swim.Playing = true
				playAnimation("walk", 0.1, hum)
				pose = "Swimming"
			elseif state == "PlatformStand" then
				pose = "Standing"
			elseif state == "GettingUp" then
				pose = "GettingUp"
				sndpoint.GettingUp:Play()
			elseif state == "Ragdoll" then
				pose = "Running"
			elseif state == "FallingDown" then
				pose = "FallingDown"
			elseif state == "Freefall" then
				pose = "Freefall"
				if old.Name ~= "Jumping" then
					playAnimation("fall", 0.3, hum)
				end
			elseif state == "Landed" then
				if verticalSpeed > 75 then
					sndpoint.Landing.Volume = math.clamp(map(verticalSpeed, 50, 100, 0, 1), 0, 1)
					sndpoint.Landing:Play()
				end
				pose = "Landed"
			elseif state == "Running" then
				run.Playing = true
				pose = "Running"
			elseif state == "Climbing" then
				clim.Playing = verticalSpeed > 0.1
				pose = "Climbing"
			else
				pose = "Standing"
			end
		end)
	end
	m.Update = function(dt, figure)
		local t = os.clock()

		local scale = figure:GetScale()

		hum = figure:FindFirstChild("Humanoid")
		if not hum then return end
		local root = figure:FindFirstChild("HumanoidRootPart")
		if not root then return end
		local torso = figure:FindFirstChild("Torso")
		if not torso then return end

		if figure:GetAttribute("IsDancing") then
			for _,v in hum:GetPlayingAnimationTracks() do
				v:Stop(0)
				v:Destroy()
			end
			justdanced = true
			return
		end
		if justdanced then
			task.delay(0.1, function()
				playAnimation("idle", 0, hum)
			end)
			justdanced = false
		end

		local function getTool()
			for _, kid in figure:GetChildren() do
				if kid.className == "Tool" then
					return kid
				end
			end
			return nil
		end
		local function getToolAnim(tool)
			for _, c in tool:GetChildren() do
				if c.Name == "toolanim" and c.ClassName == "StringValue" then
					return c
				end
			end
			return nil
		end

		if pose == "Seated" then
			playAnimation("sit", 0.5, hum)
		else
			if pose == "Running" then
				sndpoint.Running.Playing = hum.MoveDirection.Magnitude > 0.5
			elseif pose == "Standing" then
				sndpoint.Running.Playing = false
			elseif pose == "Climbing" then
				sndpoint.Climbing.Playing = math.abs(hum.RootPart.AssemblyLinearVelocity.Y) > 0.1
			end
			local tool = getTool()
			if tool and tool.RequiresHandle then
				local msg = getToolAnim(tool)
				if msg then
					toolAnim = msg.Value
					msg:Destroy()
					toolAnimTime = t + 0.3
				end
				if t > toolAnimTime then
					toolAnimTime = 0
					toolAnim = "None"
				end
				if toolAnim == "None" then
					playToolAnimation("toolnone", 0.1, hum, Enum.AnimationPriority.Idle)
				end
				if toolAnim == "Slash" then
					playToolAnimation("toolslash", 0, hum, Enum.AnimationPriority.Action)
				end
				if toolAnim == "Lunge" then
					playToolAnimation("toollunge", 0, hum, Enum.AnimationPriority.Action)
				end
			else
				toolAnim = "None"
				toolAnimTime = 0
				stopToolAnimations()
			end
		end
	end
	m.Destroy = function(figure)
		hstatechange:Disconnect()
		hrun:Disconnect()
		hclim:Disconnect()
		sndpoint:Destroy()
	end
	return m
end)

U.run()
