local Pack = {}

local SIDES = {
	behind = CFrame.new(0, 0, 3),
	infront = CFrame.new(0, 0, -3),
	left = CFrame.new(-3, 0, 0),
	right = CFrame.new(3, 0, 0),
	above = CFrame.new(0, 5, 0),
	under = CFrame.new(0, -5, 0),
}

local STUDS_PER_SECOND = 60

function Pack.init(ctx)
	local kit, Cmd, Kit, Players, LP = ctx.kit, ctx.Cmd, ctx.Kit, ctx.Players, ctx.LP
	local RunService = game:GetService("RunService")
	local TweenService = game:GetService("TweenService")
	local PathfindingService = game:GetService("PathfindingService")

	local function noBody()
		return false, "No character right now"
	end

	local function sideOffset()
		return SIDES[Cmd.val("gotoside", "side", "behind")] or SIDES.behind
	end

	local function landing(target)
		local tr = kit.rootOf(target)
		if not tr then
			return nil
		end
		return tr.CFrame * sideOffset()
	end

	local activeTween
	local function tweenTo(cf)
		local r = kit.root()
		if not r then
			return false
		end
		if activeTween then
			pcall(function()
				activeTween:Cancel()
			end)
		end
		local speed = Kit.clamp(Cmd.val("tweenspeed", "speed", 1), 0.1, 20)
		local seconds = Kit.clamp((r.Position - cf.Position).Magnitude / (STUDS_PER_SECOND * speed), 0.15, 8)
		activeTween = TweenService:Create(r, TweenInfo.new(seconds, Enum.EasingStyle.Linear), { CFrame = cf })
		activeTween:Play()
		return true, seconds
	end

	local function findParts(test, cap)
		local out = {}
		local n = 0
		for _, inst in ipairs(workspace:GetDescendants()) do
			n += 1
			if inst:IsA("BasePart") and test(inst) then
				out[#out + 1] = inst
				if #out >= (cap or 50) then
					break
				end
			end
			if n % 4000 == 0 then
				task.wait()
			end
			if n > 150000 then
				break
			end
		end
		return out
	end

	local function nearest(parts)
		local r = kit.root()
		if not r then
			return parts[1]
		end
		local best, bestD
		for _, p in ipairs(parts) do
			local d = (p.Position - r.Position).Magnitude
			if not bestD or d < bestD then
				best, bestD = p, d
			end
		end
		return best
	end

	local function named(name)
		return findParts(function(p)
			return p.Name == name
		end)
	end

	local function ofClass(class)
		return findParts(function(p)
			local ok, is = pcall(p.IsA, p, class)
			return ok and is and not p:IsA("Terrain")
		end)
	end

	local function above(part)
		return CFrame.new(part.Position + Vector3.new(0, part.Size.Y / 2 + 4, 0))
	end

	kit.define("gotoside", {
		desc = "Chooses where you land next to a player when you use tweengoto, loopgoto and pulsetp: behind, infront, left, right, above or under.",
		run = function(arg)
			local side = string.lower(string.match(tostring(arg or ""), "^%s*(%S+)") or "")
			if not SIDES[side] then
				return false, "Pick behind, infront, left, right, above or under"
			end
			Cmd.setVal("gotoside", "side", side)
			return true, "You will land " .. side
		end,
	})

	kit.define("tweenspeed", {
		run = function(arg)
			local n = kit.number(arg, nil, 0.1, 20)
			if not n then
				return false, "Give a number, like 2 for twice as fast (1 is normal)"
			end
			Cmd.setVal("tweenspeed", "speed", n)
			return true, "Tween speed " .. Kit.formatNumber(n)
		end,
	})

	kit.define("tweengoto", {
		selectors = true,
		run = function(arg)
			local p, why = kit.one("Tween goto", arg, nil, true)
			if not p then
				return false, why
			end
			local cf = landing(p)
			if not cf then
				return false, p.Name .. " has no character right now"
			end
			if not tweenTo(cf) then
				return noBody()
			end
			return true, "Gliding to " .. p.Name
		end,
	})

	kit.define("tweengotocam", {
		run = function()
			local cam = workspace.CurrentCamera
			if not cam then
				return false, "No camera right now"
			end
			if not tweenTo(CFrame.new(cam.CFrame.Position)) then
				return noBody()
			end
			return true
		end,
	})

	kit.define("tweengotopart", {
		run = function(arg)
			local name = string.match(tostring(arg or ""), "^%s*(.-)%s*$")
			if name == "" then
				return false, "Say the name of the part"
			end
			local part = nearest(named(name))
			if not part then
				return false, "No part has that name"
			end
			if not tweenTo(above(part)) then
				return noBody()
			end
			return true
		end,
	})

	kit.define("tweenoffset", {
		run = function(arg)
			local n = kit.numbers(arg, 3)
			local r = kit.root()
			if not n then
				return false, "Give x y z, like tweenoffset 0 20 0"
			end
			if not r then
				return noBody()
			end
			tweenTo(r.CFrame + Vector3.new(Kit.clamp(n[1], -5000, 5000), Kit.clamp(n[2], -5000, 5000), Kit.clamp(n[3], -5000, 5000)))
			return true
		end,
	})

	kit.define("tweentppos", {
		run = function(arg)
			local n = kit.numbers(arg, 3)
			if not n then
				return false, "Give x y z, like tweentppos 0 50 0"
			end
			if not tweenTo(CFrame.new(n[1], n[2], n[3])) then
				return noBody()
			end
			return true
		end,
	})

	kit.define("offset", {
		run = function(arg)
			local n = kit.numbers(arg, 3)
			local r = kit.root()
			if not n then
				return false, "Give x y z, like offset 0 20 0"
			end
			if not r then
				return noBody()
			end
			r.CFrame = r.CFrame + Vector3.new(Kit.clamp(n[1], -5000, 5000), Kit.clamp(n[2], -5000, 5000), Kit.clamp(n[3], -5000, 5000))
			return true
		end,
	})

	kit.define("gotopart", {
		run = function(arg)
			local name = string.match(tostring(arg or ""), "^%s*(.-)%s*$")
			if name == "" then
				return false, "Say the name of the part"
			end
			local r = kit.root()
			if not r then
				return noBody()
			end
			local part = nearest(named(name))
			if not part then
				return false, "No part has that name"
			end
			r.CFrame = above(part)
			return true
		end,
	})

	kit.define("gotopartclass", {
		run = function(arg)
			local class = string.match(tostring(arg or ""), "^%s*(%S+)")
			if not class then
				return false, "Say a class, like SpawnLocation"
			end
			local r = kit.root()
			if not r then
				return noBody()
			end
			local part = nearest(ofClass(class))
			if not part then
				return false, "Nothing of that class"
			end
			r.CFrame = above(part)
			return true
		end,
	})

	kit.define("gotomodel", {
		run = function(arg)
			local name = string.match(tostring(arg or ""), "^%s*(.-)%s*$")
			if name == "" then
				return false, "Say the name of the model"
			end
			local r = kit.root()
			if not r then
				return noBody()
			end
			local best, bestD
			for _, inst in ipairs(workspace:GetDescendants()) do
				if inst:IsA("Model") and inst.Name == name then
					local ok, cf = pcall(inst.GetPivot, inst)
					if ok then
						local d = (cf.Position - r.Position).Magnitude
						if not bestD or d < bestD then
							best, bestD = cf, d
						end
					end
				end
			end
			if not best then
				return false, "No model has that name"
			end
			r.CFrame = best + Vector3.new(0, 5, 0)
			return true
		end,
	})

	kit.define("gotospawn", {
		run = function()
			local r = kit.root()
			if not r then
				return noBody()
			end
			local spawn = LP.RespawnLocation
			if not spawn then
				spawn = nearest(findParts(function(p)
					return p:IsA("SpawnLocation")
				end))
			end
			if not spawn then
				return false, "This game has no spawn point"
			end
			r.CFrame = above(spawn)
			return true
		end,
	})

	do
		local walkToken = 0
		local function walkTo(position)
			local h = kit.hum()
			if not h then
				return noBody()
			end
			walkToken += 1
			local my = walkToken
			task.spawn(function()
				local waited = 0
				h:MoveTo(position)
				while walkToken == my and waited < 15 and kit.alive() do
					local r = kit.root()
					if not r or (Vector3.new(r.Position.X, 0, r.Position.Z) - Vector3.new(position.X, 0, position.Z)).Magnitude < 4 then
						break
					end
					if waited % 2 < 0.1 then
						h:MoveTo(position)
					end
					task.wait(0.1)
					waited += 0.1
				end
			end)
			return true
		end
		kit.define("walktopos", {
			run = function(arg)
				local n = kit.numbers(arg, 3)
				if not n then
					return false, "Give x y z, like walktopos 0 5 0"
				end
				return walkTo(Vector3.new(n[1], n[2], n[3]))
			end,
		})
		kit.define("walktopart", {
			run = function(arg)
				local name = string.match(tostring(arg or ""), "^%s*(.-)%s*$")
				if name == "" then
					return false, "Say the name of the part"
				end
				local part = nearest(named(name))
				if not part then
					return false, "No part has that name"
				end
				return walkTo(part.Position)
			end,
		})
		kit.define("walktoclass", {
			run = function(arg)
				local class = string.match(tostring(arg or ""), "^%s*(%S+)")
				if not class then
					return false, "Say a class, like SpawnLocation"
				end
				local part = nearest(ofClass(class))
				if not part then
					return false, "Nothing of that class"
				end
				return walkTo(part.Position)
			end,
		})
		kit.define("pathwalk", {
			run = function(arg)
				local h, r = kit.hum(), kit.root()
				if not (h and r) then
					return noBody()
				end
				local goal
				local n = kit.numbers(arg, 3)
				if n then
					goal = Vector3.new(n[1], n[2], n[3])
				else
					local p, why = kit.one("Pathwalk", arg, nil, true)
					if not p then
						return false, why
					end
					local tr = kit.rootOf(p)
					if not tr then
						return false, p.Name .. " has no character right now"
					end
					goal = tr.Position
				end
				walkToken += 1
				local my = walkToken
				task.spawn(function()
					local made, path = pcall(function()
						return PathfindingService:CreatePath({ AgentRadius = 2, AgentHeight = 5, AgentCanJump = true })
					end)
					local ok = made and path and pcall(function()
						path:ComputeAsync(r.Position, goal)
					end)
					if not ok or path.Status ~= Enum.PathStatus.Success then
						ctx.notify("Pathwalk", "No way there that I can find", "error", 2.5)
						return
					end
					for _, wp in ipairs(path:GetWaypoints()) do
						if walkToken ~= my or not kit.alive() then
							return
						end
						if wp.Action == Enum.PathWaypointAction.Jump then
							h.Jump = true
						end
						h:MoveTo(wp.Position)
						local done = h.MoveToFinished:Wait()
						if not done then
							break
						end
					end
				end)
				return true, "Walking there"
			end,
		})
	end

	kit.define("loopgoto", {
		selectors = true,
		start = function(arg)
			local list, why = kit.pick("Loop goto", arg, nil, true)
			if not list then
				return false, why
			end
			local who = list[1]
			kit.every("loopgoto", 0.1, function()
				local r, cf = kit.root(), landing(who)
				if r and cf then
					r.CFrame = cf
				end
			end)
			return true
		end,
		stop = function() end,
	})

	kit.define("pulsetp", {
		selectors = true,
		run = function(arg)
			local who, seconds = string.match(tostring(arg or ""), "^%s*(%S+)%s*(%S*)")
			local p, why = kit.one("Pulse teleport", who, nil, true)
			if not p then
				return false, why
			end
			local r = kit.root()
			if not r then
				return noBody()
			end
			local back = r.CFrame
			local stay = kit.number(seconds, 3, 0.5, 30)
			task.spawn(function()
				local waited = 0
				while waited < stay and kit.alive() do
					local root, cf = kit.root(), landing(p)
					if root and cf then
						root.CFrame = cf
					end
					task.wait(0.1)
					waited += 0.1
				end
				local root = kit.root()
				if root then
					root.CFrame = back
				end
			end)
			return true
		end,
	})

	do
		local before
		kit.define("lookat", {
			selectors = true,
			start = function(arg)
				local list, why = kit.pick("Look at", arg, nil, true)
				local h = kit.hum()
				if not list then
					return false, why
				end
				if not h then
					return noBody()
				end
				local who = list[1]
				before = h.AutoRotate
				h.AutoRotate = false
				kit.on("lookat", RunService.Heartbeat, function()
					local r, tr = kit.root(), kit.rootOf(who)
					if r and tr then
						local at = Vector3.new(tr.Position.X, r.Position.Y, tr.Position.Z)
						if (at - r.Position).Magnitude > 0.1 then
							r.CFrame = CFrame.lookAt(r.Position, at)
						end
					end
				end)
				return true
			end,
			stop = function()
				local h = kit.hum()
				if h and before ~= nil then
					h.AutoRotate = before
				end
				before = nil
			end,
		})
	end

	kit.define("piggyback", {
		selectors = true,
		start = function(arg)
			local list, why = kit.pick("Piggyback", arg, nil, true)
			if not list then
				return false, why
			end
			local who = list[1]
			kit.on("piggyback", RunService.Heartbeat, function()
				local r, tr = kit.root(), kit.rootOf(who)
				if r and tr then
					r.CFrame = tr.CFrame * CFrame.new(0, 1.6, 0.9)
					r.AssemblyLinearVelocity = Vector3.zero
				end
			end)
			return true
		end,
		stop = function() end,
	})

	do
		local hidden
		kit.define("hideplayer", {
			selectors = true,
			start = function(arg)
				local list, why = kit.pick("Hide player", arg, nil, true)
				if not list then
					return false, why
				end
				hidden = list
				local function apply(value)
					for _, p in ipairs(hidden or {}) do
						local c = p.Character
						if c then
							for _, d in ipairs(c:GetDescendants()) do
								if d:IsA("BasePart") or d:IsA("Decal") then
									pcall(function()
										d.LocalTransparencyModifier = value
									end)
								end
							end
						end
					end
				end
				apply(1)
				kit.every("hideplayer", 0.5, function()
					apply(1)
				end)
				return true
			end,
			stop = function()
				for _, p in ipairs(hidden or {}) do
					local c = p.Character
					if c then
						for _, d in ipairs(c:GetDescendants()) do
							if d:IsA("BasePart") then
								pcall(function()
									d.LocalTransparencyModifier = 0
								end)
							end
						end
					end
				end
				hidden = nil
			end,
		})
	end

	do
		local muted, previous, service
		kit.define("chatmute", {
			selectors = true,
			desc = "Hides what a player says on your screen. It works in games that use Roblox's newer chat.",
			start = function(arg)
				local list, why = kit.pick("Chat mute", arg, nil, true)
				if not list then
					return false, why
				end
				local ok, tcs = pcall(function()
					return game:GetService("TextChatService")
				end)
				if not ok then
					return false, "This game's chat can't be filtered"
				end
				service = tcs
				muted = {}
				for _, p in ipairs(list) do
					muted[p.UserId] = true
				end
				previous = tcs.OnIncomingMessage
				tcs.OnIncomingMessage = function(message)
					local source = message.TextSource
					if source and muted and muted[source.UserId] then
						local props = Instance.new("TextChatMessageProperties")
						props.Text = ""
						return props
					end
					if previous then
						return previous(message)
					end
					return nil
				end
				return true
			end,
			stop = function()
				if service then
					pcall(function()
						service.OnIncomingMessage = previous
					end)
				end
				muted, previous, service = nil, nil, nil
			end,
		})
	end

	local flingState = { token = 0 }

	local function flingBegin()
		local r = kit.root()
		local c = r and r.Parent
		if not c then
			return nil
		end
		local run = { root = r, char = c, home = r.CFrame, parts = {}, alive = true }
		for _, p in ipairs(c:GetDescendants()) do
			if p:IsA("BasePart") and p.CanCollide and p ~= r then
				run.parts[#run.parts + 1] = p
			end
		end
		local spin = Instance.new("BodyAngularVelocity")
		spin.Name = "AtsukoFling"
		spin.MaxTorque = Vector3.new(0, math.huge, 0)
		spin.P = math.huge
		spin.AngularVelocity = Vector3.new(0, 99999, 0)
		spin.Parent = r
		run.spin = spin
		return run
	end

	local function flingEnd(run)
		if not run or not run.alive then
			return
		end
		run.alive = false
		pcall(function()
			run.spin:Destroy()
		end)
		for _, p in ipairs(run.parts) do
			pcall(function()
				p.CanCollide = true
			end)
		end
		pcall(function()
			run.root.AssemblyLinearVelocity = Vector3.zero
			run.root.AssemblyAngularVelocity = Vector3.zero
			run.root.CFrame = run.home
		end)
	end

	local function flingOne(target, seconds, token)
		local run = flingBegin()
		if not run then
			return false
		end
		local waited = 0
		local ok = pcall(function()
			while waited < seconds and flingState.token == token and kit.alive() and run.alive do
				local tr = kit.rootOf(target)
				if not tr or not run.root.Parent then
					break
				end
				for _, p in ipairs(run.parts) do
					p.CanCollide = false
				end
				run.root.CFrame = tr.CFrame * CFrame.new(0, 0, (waited * 20) % 2 - 1)
				run.root.AssemblyLinearVelocity = Vector3.zero
				task.wait()
				waited += 1 / 60
			end
		end)
		flingEnd(run)
		return ok
	end

	kit.define("fling", {
		selectors = true,
		desc = "Spins into a player and launches them away, then puts you back where you were. It uses your own body, so it only works where the game lets players touch each other.",
		run = function(arg)
			local list, why = kit.pick("Fling", arg, nil, true)
			if not list then
				return false, why
			end
			flingState.token += 1
			local token = flingState.token
			task.spawn(function()
				for _, p in ipairs(list) do
					if flingState.token ~= token then
						break
					end
					if p ~= LP then
						flingOne(p, 1.4, token)
						task.wait(0.15)
					end
				end
			end)
			return true, "Flinging " .. #list .. (#list == 1 and " player" or " players")
		end,
	})

	kit.define("loopfling", {
		selectors = true,
		start = function(arg)
			local list, why = kit.pick("Loop fling", arg, nil, true)
			if not list then
				return false, why
			end
			local who = list[1]
			if who == LP then
				return false, "That would fling you"
			end
			flingState.token += 1
			local token = flingState.token
			task.spawn(function()
				while flingState.token == token and kit.alive() do
					if kit.rootOf(who) then
						flingOne(who, 1.2, token)
					end
					task.wait(0.4)
				end
			end)
			kit.bind("loopfling", {
				Disconnect = function()
					if flingState.token == token then
						flingState.token += 1
					end
				end,
			})
			return true
		end,
		stop = function() end,
	})

	do
		local lastVel
		kit.define("walkfling", {
			char = true,
			start = function()
				if not kit.root() then
					return noBody()
				end
				kit.on("walkfling", RunService.Heartbeat, function()
					local r = kit.root()
					if r then
						lastVel = r.AssemblyLinearVelocity
						r.AssemblyLinearVelocity = lastVel * 10000 + Vector3.new(0, 10000, 0)
					end
				end)
				kit.on("walkfling", RunService.RenderStepped, function()
					local r = kit.root()
					if r and lastVel then
						r.AssemblyLinearVelocity = lastVel
					end
				end)
				return true
			end,
			stop = function()
				local r = kit.root()
				if r and lastVel then
					r.AssemblyLinearVelocity = lastVel
				end
				lastVel = nil
			end,
		})
	end
end

return Pack
