local Pack = {}

local COLOURS = {
	white = Color3.fromRGB(255, 255, 255),
	red = Color3.fromRGB(255, 70, 70),
	green = Color3.fromRGB(80, 230, 110),
	blue = Color3.fromRGB(80, 150, 255),
	yellow = Color3.fromRGB(255, 225, 80),
	cyan = Color3.fromRGB(80, 230, 230),
	pink = Color3.fromRGB(255, 130, 200),
	orange = Color3.fromRGB(255, 160, 60),
}

local WAYPOINT_CAP = 50
local SCAN_CAP = 120000

function Pack.init(ctx)
	local kit, Cmd, Kit, LP, Players = ctx.kit, ctx.Cmd, ctx.Kit, ctx.LP, ctx.Players
	local RunService = game:GetService("RunService")

	local function trim(text)
		return (string.gsub(string.gsub(tostring(text or ""), "^%s+", ""), "%s+$", ""))
	end

	local function noBody()
		return false, "No character right now"
	end

	local function mouse()
		local ok, m = pcall(function()
			return LP:GetMouse()
		end)
		return ok and m or nil
	end

	local function scan(classes, fn, cancelled)
		local n = 0
		for _, inst in ipairs(workspace:GetDescendants()) do
			n += 1
			for _, class in ipairs(classes) do
				if inst:IsA(class) then
					fn(inst)
					break
				end
			end
			if n % 3000 == 0 then
				task.wait()
				if cancelled and cancelled() then
					return
				end
			end
			if n > SCAN_CAP then
				return
			end
		end
	end

	local function store()
		local all = Cmd.val("waypoint", "all", nil)
		if type(all) ~= "table" then
			all = {}
		end
		local key = tostring(game.PlaceId)
		local list = all[key]
		if type(list) ~= "table" then
			list = {}
		end
		return list, all, key
	end

	local function find(name)
		name = string.lower(trim(name))
		if name == "" then
			return nil
		end
		local list = store()
		for _, w in ipairs(list) do
			if type(w) == "table" and string.lower(tostring(w.n)) == name then
				return w
			end
		end
		for _, w in ipairs(list) do
			if type(w) == "table" and string.sub(string.lower(tostring(w.n)), 1, #name) == name then
				return w
			end
		end
		return nil
	end

	local function describe(w)
		return string.format("%.1f %.1f %.1f", w.x, w.y, w.z)
	end

	kit.define("wpat", {
		run = function(arg)
			local name, rest = string.match(tostring(arg or ""), "^%s*(%S+)%s+(.+)$")
			local n = name and kit.numbers(rest, 3)
			if not n then
				return false, "Give a name and three numbers, like: wpat base 0 50 0"
			end
			local list, all, key = store()
			for i = #list, 1, -1 do
				if type(list[i]) == "table" and string.lower(tostring(list[i].n)) == string.lower(name) then
					table.remove(list, i)
				end
			end
			if #list >= WAYPOINT_CAP then
				return false, "That is " .. WAYPOINT_CAP .. " already, delete some with delwp"
			end
			list[#list + 1] = { n = string.sub(name, 1, 30), x = n[1], y = n[2], z = n[3] }
			all[key] = list
			Cmd.setVal("waypoint", "all", all)
			return true, "Saved " .. name
		end,
	})

	kit.define("walkwp", {
		run = function(arg)
			local w = find(arg)
			if not w then
				return false, "No waypoint called " .. trim(arg) .. ", try waypoints"
			end
			return Cmd.run("walktopos", describe(w), true), nil
		end,
	})

	kit.define("tweenwp", {
		run = function(arg)
			local w = find(arg)
			if not w then
				return false, "No waypoint called " .. trim(arg) .. ", try waypoints"
			end
			return Cmd.run("tweentppos", describe(w), true), nil
		end,
	})

	kit.define("clearwp", {
		run = function(arg)
			local list, all, key = store()
			if string.lower(trim(arg)) == "game" then
				all[key] = nil
				Cmd.setVal("waypoint", "all", all)
				return true, #list .. " waypoints of this game deleted"
			end
			Cmd.setVal("waypoint", "all", {})
			return true, "Every waypoint deleted"
		end,
	})

	do
		local folder
		local function draw()
			if folder then
				folder:Destroy()
			end
			folder = Instance.new("Folder")
			folder.Name = "AtsukoWaypoints"
			for _, w in ipairs((store())) do
				if type(w) == "table" and type(w.x) == "number" then
					local part = Instance.new("Part")
					part.Anchored = true
					part.CanCollide = false
					part.CanQuery = false
					part.CanTouch = false
					part.Transparency = 1
					part.Size = Vector3.new(1, 1, 1)
					part.Position = Vector3.new(w.x, w.y + 3, w.z)
					local gui = Instance.new("BillboardGui")
					gui.AlwaysOnTop = true
					gui.Size = UDim2.fromOffset(140, 26)
					gui.Adornee = part
					local label = Instance.new("TextLabel")
					label.BackgroundTransparency = 1
					label.Size = UDim2.fromScale(1, 1)
					label.Text = tostring(w.n)
					label.TextColor3 = Color3.fromRGB(255, 225, 80)
					label.TextStrokeTransparency = 0.4
					label.TextSize = 14
					label.Font = Enum.Font.GothamBold
					label.Parent = gui
					gui.Parent = part
					part.Parent = folder
				end
			end
			folder.Parent = workspace
		end
		kit.define("showwp", {
			start = function()
				draw()
				kit.every("showwp", 3, draw)
				return true
			end,
			stop = function()
				if folder then
					pcall(function()
						folder:Destroy()
					end)
					folder = nil
				end
			end,
		})
	end

	do
		local frame
		local function draw(arg)
			if frame then
				frame:Destroy()
				frame = nil
			end
			local sizeWord, colourWord = string.match(trim(arg), "^(%S*)%s*(%S*)")
			local size = Kit.number(sizeWord, 12, 4, 80)
			local colour = COLOURS[string.lower(colourWord or "")] or COLOURS.white
			frame = Instance.new("Frame")
			frame.Name = "AtsukoCrosshair"
			frame.BackgroundTransparency = 1
			frame.AnchorPoint = Vector2.new(0.5, 0.5)
			frame.Position = UDim2.fromScale(0.5, 0.5)
			frame.Size = UDim2.fromOffset(size * 2 + 4, size * 2 + 4)
			frame.ZIndex = 80
			local function bar(w, h)
				local b = Instance.new("Frame")
				b.BorderSizePixel = 0
				b.BackgroundColor3 = colour
				b.AnchorPoint = Vector2.new(0.5, 0.5)
				b.Position = UDim2.fromScale(0.5, 0.5)
				b.Size = UDim2.fromOffset(w, h)
				b.ZIndex = 80
				b.Parent = frame
			end
			bar(size * 2, 2)
			bar(2, size * 2)
			frame.Parent = ctx.Root
		end
		kit.define("crosshair", {
			start = function(arg)
				if not ctx.Root then
					return false, "There is no screen to draw on"
				end
				draw(arg)
				return true
			end,
			update = function(arg)
				draw(arg)
			end,
			stop = function()
				if frame then
					pcall(function()
						frame:Destroy()
					end)
					frame = nil
				end
			end,
		})
	end

	do
		local config, before
		kit.define("bubblechat", {
			start = function()
				local ok, found = pcall(function()
					return game:GetService("TextChatService"):FindFirstChildOfClass("BubbleChatConfiguration")
				end)
				config = ok and found or nil
				if not config then
					return false, "This game doesn't use the newer chat, so bubbles can't be turned on"
				end
				before = config.Enabled
				config.Enabled = true
				return true
			end,
			stop = function()
				if config and before ~= nil then
					pcall(function()
						config.Enabled = before
					end)
				end
				config, before = nil, nil
			end,
		})
	end

	local function renamer(id, namer)
		local saved, names = {}, {}
		local function apply(p)
			local h = kit.humOf(p)
			if not h then
				return
			end
			if saved[h] == nil then
				saved[h] = h.DisplayName
			end
			names[p] = names[p] or namer(p)
			h.DisplayName = names[p]
		end
		local function hook(p)
			kit.on(id, p.CharacterAdded, function()
				task.wait(0.3)
				apply(p)
			end)
			apply(p)
		end
		kit.define(id, {
			start = function()
				saved, names = {}, {}
				for _, p in ipairs(Players:GetPlayers()) do
					hook(p)
				end
				kit.on(id, Players.PlayerAdded, hook)
				return true
			end,
			stop = function()
				for h, name in pairs(saved) do
					pcall(function()
						h.DisplayName = name
					end)
				end
				saved, names = {}, {}
			end,
		})
	end
	renamer("nonick", function(p)
		return p.Name
	end)
	renamer("streamermode", function()
		return "Player" .. math.random(1000, 9999)
	end)

	local function tags(id, build)
		local made = {}
		local function attach(p)
			if p == LP then
				return
			end
			local function make(c)
				local head = c and (c:FindFirstChild("Head") or c:FindFirstChild("HumanoidRootPart"))
				if not head then
					return
				end
				if made[p] then
					pcall(function()
						made[p]:Destroy()
					end)
				end
				made[p] = build(p, head, c)
			end
			make(p.Character)
			kit.on(id, p.CharacterAdded, function(c)
				task.wait(0.5)
				make(c)
			end)
		end
		kit.define(id, {
			start = function()
				made = {}
				for _, p in ipairs(Players:GetPlayers()) do
					attach(p)
				end
				kit.on(id, Players.PlayerAdded, attach)
				kit.on(id, Players.PlayerRemoving, function(p)
					if made[p] then
						pcall(function()
							made[p]:Destroy()
						end)
						made[p] = nil
					end
				end)
				return true
			end,
			stop = function()
				for _, g in pairs(made) do
					pcall(function()
						g:Destroy()
					end)
				end
				made = {}
			end,
		})
	end

	local function billboard(head, width, height, offset)
		local gui = Instance.new("BillboardGui")
		gui.AlwaysOnTop = true
		gui.Size = UDim2.fromOffset(width, height)
		gui.StudsOffset = Vector3.new(0, offset, 0)
		gui.Adornee = head
		gui.Parent = head
		return gui
	end

	tags("nameesp", function(p, head)
		local gui = billboard(head, 140, 22, 2.6)
		local label = Instance.new("TextLabel")
		label.BackgroundTransparency = 1
		label.Size = UDim2.fromScale(1, 1)
		label.Text = p.DisplayName
		label.TextColor3 = COLOURS.white
		label.TextStrokeTransparency = 0.3
		label.TextSize = 14
		label.Font = Enum.Font.GothamBold
		label.Parent = gui
		return gui
	end)

	tags("healthbars", function(p, head, character)
		local gui = billboard(head, 70, 8, 2.1)
		local back = Instance.new("Frame")
		back.BackgroundColor3 = Color3.fromRGB(40, 20, 20)
		back.BorderSizePixel = 0
		back.Size = UDim2.fromScale(1, 1)
		back.Parent = gui
		local fill = Instance.new("Frame")
		fill.BackgroundColor3 = COLOURS.green
		fill.BorderSizePixel = 0
		fill.Size = UDim2.fromScale(1, 1)
		fill.Parent = back
		local h = character:FindFirstChildOfClass("Humanoid")
		local function paint()
			if h and h.MaxHealth > 0 then
				local f = math.clamp(h.Health / h.MaxHealth, 0, 1)
				fill.Size = UDim2.fromScale(f, 1)
				fill.BackgroundColor3 = f > 0.5 and COLOURS.green or (f > 0.25 and COLOURS.yellow or COLOURS.red)
			end
		end
		paint()
		if h then
			kit.on("healthbars", h.HealthChanged, paint)
		end
		return gui
	end)

	kit.define("flyjump", {
		start = function()
			kit.on("flyjump", RunService.Heartbeat, function()
				local h, r = kit.hum(), kit.root()
				if h and r and h.Jump and h.FloorMaterial == Enum.Material.Air then
					local v = r.AssemblyLinearVelocity
					r.AssemblyLinearVelocity = Vector3.new(v.X, 45, v.Z)
				end
			end)
			return true
		end,
		stop = function() end,
	})

	do
		local speed = 50
		kit.define("cframefly", {
			start = function(arg)
				speed = Kit.number(arg, 50, 5, 500)
				if not kit.root() then
					return noBody()
				end
				kit.on("cframefly", RunService.RenderStepped, function(dt)
					local h, r, cam = kit.hum(), kit.root(), workspace.CurrentCamera
					if not (h and r and cam) then
						return
					end
					local move = h.MoveDirection
					local look = cam.CFrame.LookVector
					local flat = Vector3.new(look.X, 0, look.Z)
					local push = Vector3.new(0, 0, 0)
					if move.Magnitude > 0.05 and flat.Magnitude > 0.01 then
						flat = flat.Unit
						local side = Vector3.new(-flat.Z, 0, flat.X)
						push = look * move:Dot(flat) + cam.CFrame.RightVector * move:Dot(side)
					end
					if h.Jump then
						push = push + Vector3.new(0, 1, 0)
					end
					if push.Magnitude > 1 then
						push = push.Unit
					end
					r.AssemblyLinearVelocity = Vector3.zero
					if push.Magnitude > 0.01 then
						r.CFrame = r.CFrame + push * speed * dt
					end
				end)
				return true
			end,
			update = function(arg)
				speed = Kit.number(arg, speed, 5, 500)
			end,
			stop = function() end,
		})
		for _, other in ipairs({ "fly", "smoothfly" }) do
			local def = Cmd.by[other]
			if def then
				def.excl = def.excl or {}
				def.excl[#def.excl + 1] = "cframefly"
			end
		end
	end

	kit.define("maxslope", {
		run = function(arg)
			local n = kit.number(arg, nil, 0, 89)
			if not n then
				return false, "Give degrees from 0 to 89, like 70"
			end
			local h = kit.hum()
			if not h then
				return noBody()
			end
			h.MaxSlopeAngle = n
			return true, "You can climb slopes up to " .. Kit.formatNumber(n) .. " degrees"
		end,
	})

	do
		local function stateOf(text)
			local want = string.lower(trim(text))
			if want == "" then
				return nil
			end
			for _, item in ipairs(Enum.HumanoidStateType:GetEnumItems()) do
				if string.lower(item.Name) == want then
					return item
				end
			end
			return nil
		end
		local function stateCommand(id, enabled)
			kit.define(id, {
				run = function(arg)
					local state = stateOf(arg)
					local h = kit.hum()
					if not state then
						return false, "Name a state, like Climbing, Jumping or Freefall"
					end
					if not h then
						return noBody()
					end
					h:SetStateEnabled(state, enabled)
					return true, state.Name .. (enabled and " is on" or " is off")
				end,
			})
		end
		stateCommand("disablestate", false)
		stateCommand("enablestate", true)
	end

	do
		local last = 0
		kit.define("bounce", {
			start = function()
				kit.on("bounce", RunService.Heartbeat, function()
					local h, r = kit.hum(), kit.root()
					if h and r and h.FloorMaterial ~= Enum.Material.Air and os.clock() - last > 0.3 then
						last = os.clock()
						local v = r.AssemblyLinearVelocity
						r.AssemblyLinearVelocity = Vector3.new(v.X, 55, v.Z)
					end
				end)
				return true
			end,
			stop = function() end,
		})
	end

	do
		local before
		kit.define("cambobble", {
			start = function()
				local h = kit.hum()
				if not h then
					return noBody()
				end
				before = h.CameraOffset
				kit.on("cambobble", RunService.RenderStepped, function()
					local hum = kit.hum()
					if hum then
						local walking = hum.MoveDirection.Magnitude > 0.1
						hum.CameraOffset = Vector3.new(0, walking and math.sin(os.clock() * 11) * 0.12 or 0, 0)
					end
				end)
				return true
			end,
			stop = function()
				local h = kit.hum()
				if h and before then
					h.CameraOffset = before
				end
				before = nil
			end,
		})
	end

	kit.define("clearhats", {
		run = function()
			local n = 0
			for _, inst in ipairs(workspace:GetChildren()) do
				if inst:IsA("Accoutrement") then
					inst:Destroy()
					n += 1
				end
			end
			return n > 0, n > 0 and (n .. " hats cleared") or "No hats are lying around"
		end,
	})

	kit.define("listparts", {
		run = function(arg)
			local name = string.lower(trim(arg))
			if name == "" then
				return false, "Say the name of the part"
			end
			local r = kit.root()
			local found = {}
			for _, inst in ipairs(workspace:GetDescendants()) do
				if inst:IsA("BasePart") and string.lower(inst.Name) == name then
					found[#found + 1] = inst
					if #found >= 200 then
						break
					end
				end
			end
			if #found == 0 then
				return false, "No part has that name"
			end
			if r then
				table.sort(found, function(a, b)
					return (a.Position - r.Position).Magnitude < (b.Position - r.Position).Magnitude
				end)
			end
			local lines = {}
			for i = 1, math.min(5, #found) do
				local d = r and math.floor((found[i].Position - r.Position).Magnitude) or 0
				lines[i] = d .. " studs"
			end
			return true, #found .. " found. Nearest: " .. table.concat(lines, ", ") .. ". gotopart " .. trim(arg) .. " takes you to the nearest"
		end,
	})

	kit.define("listunanchored", {
		run = function()
			local r = kit.root()
			if not r then
				return noBody()
			end
			local counts, total = {}, 0
			for _, inst in ipairs(workspace:GetDescendants()) do
				if inst:IsA("BasePart") and not inst.Anchored and not inst:IsDescendantOf(LP.Character) then
					if (inst.Position - r.Position).Magnitude <= 100 then
						counts[inst.Name] = (counts[inst.Name] or 0) + 1
						total += 1
					end
				end
			end
			if total == 0 then
				return false, "No loose parts within 100 studs"
			end
			local names = {}
			for name, n in pairs(counts) do
				names[#names + 1] = { name = name, n = n }
			end
			table.sort(names, function(a, b)
				return a.n > b.n
			end)
			local out = {}
			for i = 1, math.min(6, #names) do
				out[i] = names[i].name .. " x" .. names[i].n
			end
			return true, total .. " loose parts: " .. table.concat(out, ", ")
		end,
	})

	kit.define("partname", {
		run = function()
			local m = mouse()
			if not (m and m.Button1Down) then
				return false, "No mouse to click with"
			end
			local conn
			conn = m.Button1Down:Connect(function()
				pcall(function()
					conn:Disconnect()
				end)
				local target = m.Target
				if target then
					local path = target:GetFullName()
					local copied = kit.copy(path, nil, true)
					ctx.notify(target.Name, path .. (copied and "\nCopied" or ""), "info")
				else
					ctx.notify("Nothing there", "You clicked the sky", "info", 2)
				end
			end)
			kit.later(20, function()
				pcall(function()
					conn:Disconnect()
				end)
			end)
			return true, "Click a part now"
		end,
	})

	kit.define("followedinto", {
		selectors = true,
		run = function(arg)
			local p, why = kit.one("Followed into", arg, nil, true)
			if not p then
				return false, why
			end
			local id = p.FollowUserId
			if type(id) ~= "number" or id == 0 then
				return true, p.DisplayName .. " did not follow anyone in"
			end
			local ok, name = pcall(function()
				return Players:GetNameFromUserIdAsync(id)
			end)
			return true, p.DisplayName .. " followed " .. (ok and name or ("user " .. id)) .. " in"
		end,
	})

	kit.define("inspect", {
		selectors = true,
		run = function(arg)
			local p, why = kit.one("Inspect", arg, nil, true)
			if not p then
				return false, why
			end
			local ok = pcall(function()
				game:GetService("GuiService"):InspectPlayerFromUserId(p.UserId)
			end)
			if not ok then
				return false, "Roblox wouldn't open the inspect window"
			end
			return true
		end,
	})

	kit.define("removeterrain", {
		run = function()
			local ok = pcall(function()
				workspace.Terrain:Clear()
			end)
			return ok, ok and "Terrain removed on your screen" or "The terrain wouldn't clear"
		end,
	})

	local function reach(id, class, label)
		kit.define(id, {
			run = function()
				local n = 0
				task.spawn(function()
					scan({ class }, function(inst)
						pcall(function()
							inst.MaxActivationDistance = 1e6
						end)
						n += 1
					end, function()
						return not kit.alive()
					end)
					ctx.notify(label, n .. " changed", "ok", 2)
				end)
				return true, "Working on it"
			end,
		})
	end
	reach("nocdlimits", "ClickDetector", "Click detectors")
	reach("nopplimits", "ProximityPrompt", "Prompts")

	do
		local function guiTool(id, classes, property, value, text)
			local saved, token = {}, 0
			kit.define(id, {
				start = function(arg)
					saved, token = {}, token + 1
					local my = token
					local wanted = value
					if id == "billboardrange" then
						wanted = Kit.number(arg, math.huge, 10, 1e9)
					end
					task.spawn(function()
						scan(classes, function(inst)
							local ok, old = pcall(function()
								return inst[property]
							end)
							if ok then
								saved[inst] = old
								pcall(function()
									inst[property] = wanted
								end)
							end
						end, function()
							return token ~= my or not kit.alive()
						end)
					end)
					return true, text
				end,
				stop = function()
					token += 1
					for inst, old in pairs(saved) do
						pcall(function()
							inst[property] = old
						end)
					end
					saved = {}
				end,
			})
		end
		guiTool("billboardsight", { "BillboardGui", "SurfaceGui" }, "AlwaysOnTop", true)
		guiTool("billboardrange", { "BillboardGui" }, "MaxDistance", math.huge)
	end
end

return Pack
