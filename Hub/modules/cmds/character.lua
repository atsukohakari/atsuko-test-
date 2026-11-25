local Pack = {}

local FORCE_CLASSES = { "BodyMover", "LinearVelocity", "AngularVelocity", "VectorForce", "Torque", "AlignPosition", "AlignOrientation", "LineForce" }

local function charParts(char)
	local out = {}
	if char then
		for _, d in ipairs(char:GetDescendants()) do
			if d:IsA("BasePart") then
				out[#out + 1] = d
			end
		end
	end
	return out
end

function Pack.init(ctx)
	local kit, Cmd, Kit, Players, LP = ctx.kit, ctx.Cmd, ctx.Kit, ctx.Players, ctx.LP
	local RunService = game:GetService("RunService")

	local function char()
		local h = kit.hum()
		return h and h.Parent or LP.Character
	end

	local function animator()
		local h = kit.hum()
		return h and (h:FindFirstChildOfClass("Animator") or h) or nil
	end

	local function tracks()
		local h = kit.hum()
		if not h then
			return {}
		end
		local ok, list = pcall(function()
			return h:GetPlayingAnimationTracks()
		end)
		return ok and list or {}
	end

	local function noHum()
		return false, "No character right now"
	end

	do
		local before
		local speed = 40
		kit.define("sprint", {
			char = true,
			usage = "sprint [speed]",
			start = function(arg)
				local h = kit.hum()
				if not h then
					return noHum()
				end
				speed = kit.number(arg, speed, 1, 500)
				before = before or h.WalkSpeed
				kit.on("sprint", RunService.Heartbeat, function()
					if h.WalkSpeed ~= speed then
						h.WalkSpeed = speed
					end
				end)
				return true
			end,
			update = function(arg)
				speed = kit.number(arg, speed, 1, 500)
			end,
			stop = function()
				local h = kit.hum()
				if h and before then
					h.WalkSpeed = before
				end
				before = nil
			end,
			label = function()
				return "On  -  speed " .. Kit.formatNumber(speed)
			end,
		})
	end

	kit.define("bunnyhop", {
		char = true,
		start = function()
			local h = kit.hum()
			if not h then
				return noHum()
			end
			kit.on("bunnyhop", RunService.Heartbeat, function()
				if h.MoveDirection.Magnitude > 0.1 and h.FloorMaterial ~= Enum.Material.Air then
					h.Jump = true
				end
			end)
			return true
		end,
		stop = function() end,
	})

	kit.define("autojump", {
		char = true,
		start = function()
			local h = kit.hum()
			if not h then
				return noHum()
			end
			local params = RaycastParams.new()
			params.FilterType = Enum.RaycastFilterType.Exclude
			kit.on("autojump", RunService.Heartbeat, function()
				local r = kit.root()
				local c = char()
				if not (r and c) or h.MoveDirection.Magnitude < 0.1 or h.FloorMaterial == Enum.Material.Air then
					return
				end
				params.FilterDescendantsInstances = { c }
				local origin = r.Position - Vector3.new(0, 1.5, 0)
				local hit = workspace:Raycast(origin, h.MoveDirection.Unit * 3, params)
				if hit and hit.Instance.CanCollide then
					h.Jump = true
				end
			end)
			return true
		end,
		stop = function() end,
	})

	kit.define("spasm", {
		char = true,
		start = function()
			if not kit.root() then
				return noHum()
			end
			kit.every("spasm", 0.05, function()
				local r = kit.root()
				if r then
					r.CFrame = r.CFrame * CFrame.Angles((math.random() - 0.5) * 0.6, (math.random() - 0.5) * 0.6, (math.random() - 0.5) * 0.6)
				end
			end)
			return true
		end,
		stop = function() end,
	})

	kit.define("trip", {
		run = function()
			local h = kit.hum()
			if not h then
				return noHum()
			end
			h:ChangeState(Enum.HumanoidStateType.FallingDown)
			return true
		end,
	})

	do
		local flipping = false
		kit.define("flip", {
			usage = "flip [front|back]",
			run = function(arg)
				local r = kit.root()
				if not r then
					return noHum()
				end
				if flipping then
					return false, "Wait for the flip to finish"
				end
				local dir = string.lower(tostring(arg or "")) == "front" and 1 or -1
				flipping = true
				r.AssemblyLinearVelocity = r.AssemblyLinearVelocity + Vector3.new(0, 38, 0)
				task.spawn(function()
					for _ = 1, 12 do
						local now = kit.root()
						if not now then
							break
						end
						now.CFrame = now.CFrame * CFrame.Angles(dir * math.pi / 6, 0, 0)
						task.wait(0.04)
					end
					flipping = false
				end)
				return true
			end,
		})
	end

	kit.define("launch", {
		usage = "launch [power]",
		run = function(arg)
			local r = kit.root()
			if not r then
				return noHum()
			end
			local power = kit.number(arg, 100, 10, 500)
			local v = r.AssemblyLinearVelocity
			r.AssemblyLinearVelocity = Vector3.new(v.X, power, v.Z)
			return true
		end,
	})

	kit.define("dash", {
		usage = "dash [power]",
		run = function(arg)
			local r = kit.root()
			if not r then
				return noHum()
			end
			local power = kit.number(arg, 80, 10, 300)
			local look = r.CFrame.LookVector
			local v = r.AssemblyLinearVelocity
			r.AssemblyLinearVelocity = Vector3.new(look.X * power, v.Y, look.Z * power)
			return true
		end,
	})

	kit.define("breakvelocity", {
		run = function()
			local c = char()
			if not c then
				return noHum()
			end
			for _, p in ipairs(charParts(c)) do
				p.AssemblyLinearVelocity = Vector3.zero
				p.AssemblyAngularVelocity = Vector3.zero
			end
			return true
		end,
	})

	do
		local before
		kit.define("platformstand", {
			char = true,
			start = function()
				local h = kit.hum()
				if not h then
					return noHum()
				end
				before = h.PlatformStand
				h.PlatformStand = true
				return true
			end,
			stop = function()
				local h = kit.hum()
				if h then
					h.PlatformStand = before == true
				end
				before = nil
			end,
		})
	end

	do
		local states = { Enum.HumanoidStateType.FallingDown, Enum.HumanoidStateType.Ragdoll, Enum.HumanoidStateType.Physics }
		kit.define("nostun", {
			char = true,
			start = function()
				local h = kit.hum()
				if not h then
					return noHum()
				end
				for _, s in ipairs(states) do
					pcall(function()
						h:SetStateEnabled(s, false)
					end)
				end
				kit.on("nostun", RunService.Heartbeat, function()
					if h.PlatformStand then
						h.PlatformStand = false
					end
				end)
				return true
			end,
			stop = function()
				local h = kit.hum()
				if h then
					for _, s in ipairs(states) do
						pcall(function()
							h:SetStateEnabled(s, true)
						end)
					end
				end
			end,
		})
	end

	do
		local before
		kit.define("norotate", {
			char = true,
			start = function()
				local h = kit.hum()
				if not h then
					return noHum()
				end
				before = h.AutoRotate
				h.AutoRotate = false
				return true
			end,
			stop = function()
				local h = kit.hum()
				if h then
					h.AutoRotate = before ~= false
				end
				before = nil
			end,
		})
	end

	local function density(id, default)
		local saved
		kit.define(id, {
			char = true,
			usage = id .. " [number]",
			start = function(arg)
				local c = char()
				if not c then
					return noHum()
				end
				local value = kit.number(arg, default, 0, 100)
				saved = {}
				for _, p in ipairs(charParts(c)) do
					saved[#saved + 1] = { p, p.CustomPhysicalProperties }
					p.CustomPhysicalProperties = PhysicalProperties.new(value, 0.3, 0.5)
				end
				return true
			end,
			stop = function()
				for _, item in ipairs(saved or {}) do
					pcall(function()
						item[1].CustomPhysicalProperties = item[2]
					end)
				end
				saved = nil
			end,
		})
	end
	density("strengthen", 100)
	density("weaken", 0.01)

	do
		local at
		kit.define("spawnpoint", {
			usage = "spawnpoint [delay]",
			start = function(arg)
				local r = kit.root()
				if not r then
					return noHum()
				end
				at = r.CFrame
				local delay = kit.number(arg, 0.4, 0, 5)
				kit.on("spawnpoint", LP.CharacterAdded, function(c)
					local root = c:WaitForChild("HumanoidRootPart", 5)
					if root and at then
						task.wait(delay)
						root.CFrame = at
					end
				end)
				return true
			end,
			stop = function()
				at = nil
			end,
		})
	end

	do
		local last
		kit.define("refreshdead", {
			start = function()
				local r = kit.root()
				if not r then
					return noHum()
				end
				last = r.CFrame
				kit.every("refreshdead", 0.25, function()
					local h, root = kit.hum(), kit.root()
					if h and root and h.Health > 0 then
						last = root.CFrame
					end
				end)
				kit.on("refreshdead", LP.CharacterAdded, function(c)
					local root = c:WaitForChild("HumanoidRootPart", 5)
					if root and last then
						task.wait(0.4)
						root.CFrame = last
					end
				end)
				return true
			end,
			stop = function()
				last = nil
			end,
		})
	end

	do
		local diedAt
		local function watch(c)
			local h = c:WaitForChild("Humanoid", 8)
			local root = c:WaitForChild("HumanoidRootPart", 8)
			if not (h and root) then
				return
			end
			local lastCf = root.CFrame
			local beat
			beat = RunService.Heartbeat:Connect(function()
				if root.Parent then
					lastCf = root.CFrame
				else
					beat:Disconnect()
				end
			end)
			h.Died:Connect(function()
				diedAt = lastCf
				beat:Disconnect()
			end)
		end
		if LP.Character then
			task.spawn(watch, LP.Character)
		end
		ctx.hubConn(LP.CharacterAdded:Connect(function(c)
			task.spawn(watch, c)
		end))
		kit.define("flashback", {
			run = function()
				local r = kit.root()
				if not r then
					return noHum()
				end
				if not diedAt then
					return false, "You haven't died since the hub started"
				end
				r.CFrame = diedAt
				return true, "Back where you died"
			end,
		})
	end

	do
		local saved
		kit.define("rainbow", {
			char = true,
			start = function()
				local c = char()
				local colors = c and c:FindFirstChildOfClass("BodyColors")
				if not colors then
					return false, "Your character has no body colours"
				end
				saved = {
					colors, colors.HeadColor3, colors.TorsoColor3, colors.LeftArmColor3, colors.RightArmColor3, colors.LeftLegColor3, colors.RightLegColor3,
				}
				local t = 0
				kit.on("rainbow", RunService.Heartbeat, function(dt)
					t += dt * 0.4
					local base = t % 1
					colors.HeadColor3 = Color3.fromHSV(base, 0.8, 1)
					colors.TorsoColor3 = Color3.fromHSV((base + 0.15) % 1, 0.8, 1)
					colors.LeftArmColor3 = Color3.fromHSV((base + 0.3) % 1, 0.8, 1)
					colors.RightArmColor3 = Color3.fromHSV((base + 0.45) % 1, 0.8, 1)
					colors.LeftLegColor3 = Color3.fromHSV((base + 0.6) % 1, 0.8, 1)
					colors.RightLegColor3 = Color3.fromHSV((base + 0.75) % 1, 0.8, 1)
				end)
				return true
			end,
			stop = function()
				if saved then
					pcall(function()
						local colors = saved[1]
						colors.HeadColor3, colors.TorsoColor3, colors.LeftArmColor3 = saved[2], saved[3], saved[4]
						colors.RightArmColor3, colors.LeftLegColor3, colors.RightLegColor3 = saved[5], saved[6], saved[7]
					end)
				end
				saved = nil
			end,
		})
	end

	do
		local hidden
		kit.define("nohats", {
			char = true,
			start = function()
				local c = char()
				if not c then
					return noHum()
				end
				hidden = {}
				local function hide(acc)
					local handle = acc:FindFirstChild("Handle")
					if handle and handle:IsA("BasePart") and handle.Transparency < 1 then
						hidden[#hidden + 1] = { handle, handle.Transparency }
						handle.Transparency = 1
					end
				end
				for _, acc in ipairs(c:GetChildren()) do
					if acc:IsA("Accessory") then
						hide(acc)
					end
				end
				kit.on("nohats", c.ChildAdded, function(acc)
					if acc:IsA("Accessory") then
						task.defer(hide, acc)
					end
				end)
				return true
			end,
			stop = function()
				for _, item in ipairs(hidden or {}) do
					pcall(function()
						item[1].Transparency = item[2]
					end)
				end
				hidden = nil
			end,
		})
	end

	local function wipe(title, classes, where)
		return function()
			local c = char()
			if not c then
				return noHum()
			end
			local n = 0
			for _, d in ipairs((where and where(c)) or c:GetDescendants()) do
				for _, class in ipairs(classes) do
					if d:IsA(class) then
						d:Destroy()
						n += 1
						break
					end
				end
			end
			return n > 0, n > 0 and (title .. " (" .. n .. ")") or "Nothing to remove"
		end
	end

	kit.define("naked", { run = wipe("Clothing removed", { "Shirt", "Pants", "ShirtGraphic" }) })
	kit.define("noface", {
		run = wipe("Face removed", { "Decal" }, function(c)
			local head = c:FindFirstChild("Head")
			return head and head:GetChildren() or {}
		end),
	})
	kit.define("blockhead", {
		run = wipe("Head is a block now", { "SpecialMesh" }, function(c)
			local head = c:FindFirstChild("Head")
			return head and head:GetChildren() or {}
		end),
	})
	kit.define("blockhats", {
		run = wipe("Hats are blocks now", { "SpecialMesh" }, function(c)
			local out = {}
			for _, acc in ipairs(c:GetChildren()) do
				local handle = acc:IsA("Accessory") and acc:FindFirstChild("Handle")
				if handle then
					for _, d in ipairs(handle:GetChildren()) do
						out[#out + 1] = d
					end
				end
			end
			return out
		end),
	})
	kit.define("clearappearance", {
		run = wipe("Appearance cleared", { "Accessory", "Shirt", "Pants", "ShirtGraphic", "CharacterMesh", "BodyColors" }, function(c)
			return c:GetChildren()
		end),
	})

	kit.define("deleteforces", {
		run = function()
			local c = char()
			if not c then
				return noHum()
			end
			local n = 0
			for _, d in ipairs(c:GetDescendants()) do
				if string.sub(d.Name, 1, 6) ~= "Atsuko" then
					for _, class in ipairs(FORCE_CLASSES) do
						if d:IsA(class) then
							d:Destroy()
							n += 1
							break
						end
					end
				end
			end
			return n > 0, n > 0 and (n .. " removed") or "No force objects found"
		end,
	})

	kit.define("stopanims", {
		run = function()
			local n = 0
			for _, t in ipairs(tracks()) do
				pcall(function()
					t:Stop(0)
				end)
				n += 1
			end
			return true, n .. " stopped"
		end,
	})

	kit.define("refreshanims", {
		run = function()
			local c = char()
			local animate = c and c:FindFirstChild("Animate")
			if not (animate and animate:IsA("LocalScript")) then
				return false, "Your character has no Animate script"
			end
			animate.Disabled = true
			task.wait(0.1)
			animate.Disabled = false
			return true, "Animations reloaded"
		end,
	})

	kit.define("animspeed", {
		run = function(arg)
			local n = kit.number(arg, nil, 0, 20)
			if not n then
				return false, "Give a speed, like 2 (1 is normal)"
			end
			local count = 0
			for _, t in ipairs(tracks()) do
				pcall(function()
					t:AdjustSpeed(n)
				end)
				count += 1
			end
			return count > 0, count > 0 and ("Speed " .. Kit.formatNumber(n) .. " on " .. count .. " animations") or "Nothing is animating"
		end,
	})

	do
		local playing
		kit.define("animation", {
			run = function(arg)
				local id, speed = string.match(tostring(arg or ""), "^%s*(%d+)%s*(%S*)")
				if not id then
					return false, "Give an animation id, like animation 507771019"
				end
				local a = animator()
				if not a then
					return noHum()
				end
				local anim = Instance.new("Animation")
				anim.AnimationId = "rbxassetid://" .. id
				local ok, track = pcall(function()
					return a:LoadAnimation(anim)
				end)
				if not ok or not track then
					return false, "That animation didn't load"
				end
				if playing then
					pcall(function()
						playing:Stop()
					end)
				end
				playing = track
				track:Play()
				local s = tonumber(speed)
				if s then
					track:AdjustSpeed(Kit.clamp(s, 0, 20))
				end
				return true
			end,
		})
	end

	kit.define("freezeanims", {
		char = true,
		start = function()
			if not kit.hum() then
				return noHum()
			end
			kit.every("freezeanims", 0.1, function()
				for _, t in ipairs(tracks()) do
					t:AdjustSpeed(0)
				end
			end)
			return true
		end,
		stop = function()
			for _, t in ipairs(tracks()) do
				pcall(function()
					t:AdjustSpeed(1)
				end)
			end
		end,
	})

	do
		local animate
		kit.define("noanim", {
			char = true,
			start = function()
				local c = char()
				animate = c and c:FindFirstChild("Animate")
				if not (animate and animate:IsA("LocalScript")) then
					animate = nil
					return false, "Your character has no Animate script"
				end
				animate.Disabled = true
				for _, t in ipairs(tracks()) do
					pcall(function()
						t:Stop(0)
					end)
				end
				return true
			end,
			stop = function()
				if animate then
					pcall(function()
						animate.Disabled = false
					end)
				end
				animate = nil
			end,
		})
	end

	do
		local hidden
		kit.define("nobillboardgui", {
			char = true,
			start = function()
				local c = char()
				if not c then
					return noHum()
				end
				hidden = {}
				for _, d in ipairs(c:GetDescendants()) do
					if (d:IsA("BillboardGui") or d:IsA("SurfaceGui")) and d.Enabled and string.sub(d.Name, 1, 6) ~= "Atsuko" then
						d.Enabled = false
						hidden[#hidden + 1] = d
					end
				end
				return true
			end,
			stop = function()
				for _, g in ipairs(hidden or {}) do
					pcall(function()
						g.Enabled = true
					end)
				end
				hidden = nil
			end,
		})
	end

	do
		local saved
		kit.define("notouch", {
			char = true,
			start = function()
				local c = char()
				if not c then
					return noHum()
				end
				saved = {}
				for _, p in ipairs(charParts(c)) do
					if p.CanTouch then
						p.CanTouch = false
						saved[#saved + 1] = p
					end
				end
				return true
			end,
			stop = function()
				for _, p in ipairs(saved or {}) do
					pcall(function()
						p.CanTouch = true
					end)
				end
				saved = nil
			end,
		})
	end

	do
		kit.define("ragdoll", {
			char = true,
			start = function()
				local h = kit.hum()
				if not h then
					return noHum()
				end
				h:ChangeState(Enum.HumanoidStateType.Ragdoll)
				kit.on("ragdoll", RunService.Heartbeat, function()
					if h:GetState() ~= Enum.HumanoidStateType.Ragdoll then
						h:ChangeState(Enum.HumanoidStateType.Ragdoll)
					end
				end)
				return true
			end,
			stop = function()
				local h = kit.hum()
				if h then
					h:ChangeState(Enum.HumanoidStateType.GettingUp)
				end
			end,
		})
	end
end

return Pack
