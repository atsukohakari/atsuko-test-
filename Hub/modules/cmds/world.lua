local Pack = {}

local LIGHT_KEYS = { "Ambient", "OutdoorAmbient", "Brightness", "ClockTime", "FogColor", "FogEnd", "FogStart", "GlobalShadows", "ExposureCompensation", "EnvironmentDiffuseScale", "EnvironmentSpecularScale" }

local EFFECT_CLASSES = { "BlurEffect", "BloomEffect", "ColorCorrectionEffect", "DepthOfFieldEffect", "SunRaysEffect" }

local CORE_ITEMS = {
	inventory = "Backpack", backpack = "Backpack", playerlist = "PlayerList", players = "PlayerList", chat = "Chat",
	emotes = "EmotesMenu", health = "Health", all = "All", captures = "Captures",
}

local function scanDescendants(root, cap, fn)
	local n = 0
	for _, inst in ipairs(root:GetDescendants()) do
		n += 1
		if n > cap then
			break
		end
		fn(inst)
		if n % 4000 == 0 then
			task.wait()
		end
	end
end

function Pack.init(ctx)
	local kit, Cmd, Kit, Players, LP, S, Log, Core = ctx.kit, ctx.Cmd, ctx.Kit, ctx.Players, ctx.LP, ctx.S, ctx.Log, ctx.Core
	local Lighting = game:GetService("Lighting")
	local StarterGui = game:GetService("StarterGui")
	local UserInputService = game:GetService("UserInputService")

	local snapshot = {}
	for _, key in ipairs(LIGHT_KEYS) do
		local ok, v = pcall(function()
			return Lighting[key]
		end)
		if ok then
			snapshot[key] = v
		end
	end

	local function setLight(key, value)
		pcall(function()
			Lighting[key] = value
		end)
	end

	local function color255(r, g, b)
		return Color3.fromRGB(Kit.clamp(math.floor(r), 0, 255), Kit.clamp(math.floor(g), 0, 255), Kit.clamp(math.floor(b), 0, 255))
	end

	kit.define("ambient", {
		run = function(arg)
			local n = kit.numbers(arg, 3)
			if not n then
				return false, "Give three numbers from 0 to 255, like ambient 120 120 160"
			end
			local c = color255(n[1], n[2], n[3])
			setLight("Ambient", c)
			setLight("OutdoorAmbient", c)
			return true, "Ambient light changed"
		end,
	})

	kit.define("brightness", {
		usage = "brightness <0-10>",
		run = function(arg)
			local n = kit.number(arg, nil, 0, 10)
			if not n then
				return false, "Give a number from 0 to 10"
			end
			setLight("Brightness", n)
			return true, "Brightness " .. Kit.formatNumber(n)
		end,
	})

	kit.define("restorelighting", {
		run = function()
			for key, value in pairs(snapshot) do
				setLight(key, value)
			end
			return true, "Lighting is back to how it was"
		end,
	})

	kit.define("destroyheight", {
		run = function(arg)
			local n = kit.number(arg, nil, -50000, 50000)
			if not n then
				return false, "Give a height, like -500"
			end
			workspace.FallenPartsDestroyHeight = n
			return true, "Fallen parts are removed below " .. Kit.formatNumber(n)
		end,
	})

	local function effectToggle(id, desc, apply)
		local saved
		kit.define(id, {
			desc = desc,
			start = function(arg)
				saved = {}
				apply(saved, arg)
				return true
			end,
			stop = function()
				for _, item in ipairs(saved or {}) do
					pcall(item)
				end
				saved = nil
			end,
		})
	end

	effectToggle("atmosphere", "Removes the thick air and haze of the Atmosphere. Turn it off to bring it back.", function(saved)
		local function flatten(a)
			local before = { Density = a.Density, Haze = a.Haze, Glare = a.Glare }
			a.Density, a.Haze, a.Glare = 0, 0, 0
			saved[#saved + 1] = function()
				a.Density, a.Haze, a.Glare = before.Density, before.Haze, before.Glare
			end
		end
		for _, a in ipairs(Lighting:GetChildren()) do
			if a:IsA("Atmosphere") then
				flatten(a)
			end
		end
		kit.on("atmosphere", Lighting.ChildAdded, function(a)
			if a:IsA("Atmosphere") then
				flatten(a)
			end
		end)
	end)

	effectToggle("shadows", "Turns shadows off, which can make busy games run better. Turn the command off to bring them back.", function(saved)
		local before = Lighting.GlobalShadows
		Lighting.GlobalShadows = false
		saved[#saved + 1] = function()
			Lighting.GlobalShadows = before
		end
	end)

	effectToggle("sky", "Hides the skybox. Turn the command off to bring it back.", function(saved)
		local function hide(s)
			local parent = s.Parent
			s.Parent = nil
			saved[#saved + 1] = function()
				s.Parent = parent
			end
		end
		for _, s in ipairs(Lighting:GetChildren()) do
			if s:IsA("Sky") then
				hide(s)
			end
		end
	end)

	effectToggle("noeffects", "Switches off blur, bloom, colour correction, depth of field and sun rays on your screen. Turn it off to bring them back.", function(saved)
		local function dim(e)
			if e.Enabled then
				e.Enabled = false
				saved[#saved + 1] = function()
					e.Enabled = true
				end
			end
		end
		local function isEffect(e)
			for _, class in ipairs(EFFECT_CLASSES) do
				if e:IsA(class) then
					return true
				end
			end
			return false
		end
		for _, e in ipairs(Lighting:GetChildren()) do
			if isEffect(e) then
				dim(e)
			end
		end
		local cam = workspace.CurrentCamera
		if cam then
			for _, e in ipairs(cam:GetChildren()) do
				if isEffect(e) then
					dim(e)
				end
			end
		end
		kit.on("noeffects", Lighting.ChildAdded, function(e)
			if isEffect(e) then
				task.defer(dim, e)
			end
		end)
	end)

	do
		local saved
		kit.define("nolights", {
			start = function()
				saved = {}
				local found = {}
				task.spawn(function()
					scanDescendants(workspace, 80000, function(inst)
						if (inst:IsA("PointLight") or inst:IsA("SpotLight") or inst:IsA("SurfaceLight")) and inst.Enabled then
							inst.Enabled = false
							found[#found + 1] = inst
						end
					end)
					if saved then
						saved.found = found
					else
						for _, l in ipairs(found) do
							pcall(function()
								l.Enabled = true
							end)
						end
					end
				end)
				return true
			end,
			stop = function()
				if saved and saved.found then
					for _, l in ipairs(saved.found) do
						pcall(function()
							l.Enabled = true
						end)
					end
				end
				saved = nil
			end,
		})
	end

	do
		local fx
		kit.define("depthoffield", {
			usage = "depthoffield [distance]",
			start = function(arg)
				local d = kit.number(arg, 20, 1, 1000)
				fx = Instance.new("DepthOfFieldEffect")
				fx.Name = "AtsukoDepthOfField"
				fx.FocusDistance = d
				fx.InFocusRadius = 20
				fx.NearIntensity = 0
				fx.FarIntensity = 0.75
				fx.Parent = Lighting
				return true
			end,
			update = function(arg)
				if fx then
					fx.FocusDistance = kit.number(arg, 20, 1, 1000)
				end
			end,
			stop = function()
				if fx then
					fx:Destroy()
					fx = nil
				end
			end,
		})
	end

	do
		local before
		kit.define("waves", {
			usage = "waves [size] [speed]",
			run = function(arg)
				local terrain = workspace:FindFirstChildOfClass("Terrain")
				if not terrain then
					return false, "This game has no terrain"
				end
				if not before then
					before = { size = terrain.WaterWaveSize, speed = terrain.WaterWaveSpeed }
				end
				local n = kit.numbers(arg)
				if arg ~= nil and arg ~= "" and not n then
					return false, "Give numbers, like waves 0.5 10, or waves 0 to calm the water"
				end
				local size = n and n[1] or 0
				local speed = n and n[2] or (size == 0 and 0 or before.speed)
				terrain.WaterWaveSize = Kit.clamp(size, 0, 1)
				terrain.WaterWaveSpeed = Kit.clamp(speed, 0, 100)
				return true, "Waves changed on your screen"
			end,
		})
	end

	local function gameSettings()
		local ok, gs = pcall(function()
			return UserSettings():GetService("UserGameSettings")
		end)
		return ok and gs or nil
	end

	kit.define("volume", {
		run = function(arg)
			local n = kit.number(arg, nil, 0, 10)
			if not n then
				return false, "Give a number from 0 to 10"
			end
			local gs = gameSettings()
			if not gs then
				return false, "Roblox won't let the hub change the volume here"
			end
			local ok = pcall(function()
				gs.MasterVolume = n / 10
			end)
			if not ok then
				return false, "Roblox won't let the hub change the volume here"
			end
			return true, "Volume " .. Kit.formatNumber(n) .. " of 10"
		end,
	})

	do
		local before
		kit.define("mute", {
			start = function()
				local gs = gameSettings()
				if not gs then
					return false, "Roblox won't let the hub change the volume here"
				end
				before = gs.MasterVolume
				gs.MasterVolume = 0
				return true
			end,
			stop = function()
				local gs = gameSettings()
				if gs and before then
					pcall(function()
						gs.MasterVolume = before
					end)
				end
				before = nil
			end,
		})
	end

	do
		local before
		kit.define("irltime", {
			start = function()
				before = Lighting.ClockTime
				local function sync()
					local t = os.date("*t")
					Lighting.ClockTime = t.hour + t.min / 60
				end
				sync()
				kit.every("irltime", 10, sync)
				return true
			end,
			stop = function()
				if before then
					setLight("ClockTime", before)
				end
				before = nil
			end,
		})
	end

	do
		local before
		kit.define("nomouse", {
			start = function()
				before = UserInputService.MouseIconEnabled
				UserInputService.MouseIconEnabled = false
				return true
			end,
			stop = function()
				UserInputService.MouseIconEnabled = before ~= false
				before = nil
			end,
		})
	end

	local trash = {}

	local function remove(list)
		local batch = {}
		for _, inst in ipairs(list) do
			if inst.Parent then
				batch[#batch + 1] = { inst = inst, parent = inst.Parent }
				inst.Parent = nil
			end
		end
		if #batch > 0 then
			trash[#trash + 1] = batch
			if #trash > 20 then
				table.remove(trash, 1)
			end
		end
		return #batch
	end

	kit.define("deletepart", {
		run = function(arg)
			local name = string.match(tostring(arg or ""), "^%s*(.-)%s*$")
			if name == "" then
				return false, "Say the name of the parts"
			end
			local found = {}
			scanDescendants(workspace, 120000, function(inst)
				if inst.Name == name and inst:IsA("BasePart") then
					found[#found + 1] = inst
				end
			end)
			local n = remove(found)
			return n > 0, n > 0 and (n .. " removed on your screen. undelete brings them back") or "No part has that name"
		end,
	})

	kit.define("deleteclass", {
		run = function(arg)
			local class = string.match(tostring(arg or ""), "^%s*(%S+)")
			if not class then
				return false, "Say a class, like Seat or SpawnLocation"
			end
			local found = {}
			scanDescendants(workspace, 120000, function(inst)
				local ok, is = pcall(inst.IsA, inst, class)
				if ok and is and inst:IsA("BasePart") and not inst:IsA("Terrain") then
					found[#found + 1] = inst
				end
			end)
			local n = remove(found)
			return n > 0, n > 0 and (n .. " removed on your screen. undelete brings them back") or "Nothing of that class"
		end,
	})

	kit.define("undelete", {
		run = function()
			local batch = table.remove(trash)
			if not batch then
				return false, "Nothing to bring back"
			end
			for _, item in ipairs(batch) do
				pcall(function()
					item.inst.Parent = item.parent
				end)
			end
			return true, #batch .. " brought back"
		end,
	})

	do
		local mouse
		kit.define("clickdelete", {
			start = function()
				local got, found = pcall(function()
					return LP:GetMouse()
				end)
				mouse = got and found or nil
				if not (mouse and mouse.Button1Down) then
					return false, "Your game has no mouse to click with"
				end
				kit.on("clickdelete", mouse.Button1Down, function()
					local target = mouse.Target
					if target and target:IsA("BasePart") and not target:IsA("Terrain") then
						local char = LP.Character
						if not (char and target:IsDescendantOf(char)) then
							remove({ target })
						end
					end
				end)
				return true
			end,
			stop = function() end,
		})
	end

	local function guiParent()
		return LP:FindFirstChildOfClass("PlayerGui")
	end

	local function isHubGui(sg)
		local root = ctx.Root
		return root ~= nil and root:IsDescendantOf(sg)
	end

	do
		local hidden
		kit.define("hidegui", {
			start = function()
				hidden = {}
				local pg = guiParent()
				if not pg then
					return false, "No screen to hide things on"
				end
				for _, sg in ipairs(pg:GetChildren()) do
					if sg:IsA("ScreenGui") and sg.Enabled and not isHubGui(sg) then
						sg.Enabled = false
						hidden[#hidden + 1] = sg
					end
				end
				return true
			end,
			stop = function()
				for _, sg in ipairs(hidden or {}) do
					pcall(function()
						sg.Enabled = true
					end)
				end
				hidden = nil
			end,
		})
	end

	do
		local shown
		kit.define("showguis", {
			start = function()
				shown = {}
				local pg = guiParent()
				if not pg then
					return false, "No screen to show things on"
				end
				for _, sg in ipairs(pg:GetChildren()) do
					if sg:IsA("ScreenGui") and not sg.Enabled then
						sg.Enabled = true
						shown[#shown + 1] = sg
					end
				end
				return true
			end,
			stop = function()
				for _, sg in ipairs(shown or {}) do
					pcall(function()
						sg.Enabled = false
					end)
				end
				shown = nil
			end,
		})
	end

	kit.define("coregui", {
		run = function(arg)
			local item, state = string.match(string.lower(tostring(arg or "")), "^%s*(%S+)%s*(%S*)")
			if not item then
				return false, "Say which one: inventory, playerlist, chat, emotes, health, reset or all"
			end
			local on
			if state == "on" then
				on = true
			elseif state == "off" then
				on = false
			elseif state ~= "" then
				return false, "End with on or off"
			end
			if item == "reset" then
				on = on == nil and false or on
				local ok = pcall(function()
					StarterGui:SetCore("ResetButtonCallback", on)
				end)
				return ok, ok and ("Reset button " .. (on and "on" or "off")) or "This game doesn't allow that"
			end
			local name = CORE_ITEMS[item]
			if not name or not Enum.CoreGuiType[name] then
				return false, "I don't know " .. item
			end
			if on == nil then
				on = false
			end
			local ok = pcall(function()
				StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType[name], on)
			end)
			return ok, ok and (item .. " " .. (on and "on" or "off")) or "This game doesn't allow that"
		end,
	})

	kit.define("graphics", {
		run = function(arg)
			local n = kit.number(arg, nil, 1, 10)
			if not n then
				return false, "Give a number from 1 to 10"
			end
			local level = 1 + math.floor((math.floor(n) - 1) * 20 / 9 + 0.5)
			local ok = pcall(function()
				settings().Rendering.QualityLevel = level
			end)
			return ok, ok and ("Graphics " .. math.floor(n) .. " of 10") or "Roblox won't let the hub change that here"
		end,
	})

	do
		local saved
		kit.define("truesight", {
			start = function()
				saved = {}
				local found = {}
				task.spawn(function()
					scanDescendants(workspace, 80000, function(inst)
						if inst:IsA("BasePart") and inst.Transparency >= 1 and not inst:IsA("Terrain") and not inst:IsDescendantOf(LP.Character or workspace) then
							inst.Transparency = 0.6
							found[#found + 1] = inst
						end
					end)
					if saved then
						saved.found = found
					else
						for _, p in ipairs(found) do
							pcall(function()
								p.Transparency = 1
							end)
						end
					end
				end)
				return true
			end,
			stop = function()
				if saved and saved.found then
					for _, p in ipairs(saved.found) do
						pcall(function()
							p.Transparency = 1
						end)
					end
				end
				saved = nil
			end,
		})
	end

	do
		local saved
		kit.define("removeseats", {
			start = function()
				saved = {}
				local found = {}
				task.spawn(function()
					scanDescendants(workspace, 80000, function(inst)
						if (inst:IsA("Seat") or inst:IsA("VehicleSeat")) and not inst.Disabled then
							inst.Disabled = true
							found[#found + 1] = inst
						end
					end)
					if saved then
						saved.found = found
					else
						for _, seat in ipairs(found) do
							pcall(function()
								seat.Disabled = false
							end)
						end
					end
				end)
				return true
			end,
			stop = function()
				if saved and saved.found then
					for _, seat in ipairs(saved.found) do
						pcall(function()
							seat.Disabled = false
						end)
					end
				end
				saved = nil
			end,
		})
	end
end

return Pack
