local Pack = {}

function Pack.init(ctx)
	local kit, Cmd, Kit, LP = ctx.kit, ctx.Cmd, ctx.Kit, ctx.LP

	local function character()
		local h = kit.hum()
		return h and h.Parent or LP.Character
	end

	local function backpack()
		return LP:FindFirstChildOfClass("Backpack")
	end

	local function allTools()
		local out = {}
		local pack, char = backpack(), character()
		for _, holder in ipairs({ pack, char }) do
			if holder then
				for _, t in ipairs(holder:GetChildren()) do
					if t:IsA("Tool") then
						out[#out + 1] = t
					end
				end
			end
		end
		return out
	end

	local function held()
		local char = character()
		return char and char:FindFirstChildOfClass("Tool") or nil
	end

	local function noBody()
		return false, "No character right now"
	end

	kit.define("equiptools", {
		run = function()
			local char = character()
			if not char then
				return noBody()
			end
			local pack, n = backpack(), 0
			for _, t in ipairs(pack and pack:GetChildren() or {}) do
				if t:IsA("Tool") then
					t.Parent = char
					n += 1
				end
			end
			return n > 0, n > 0 and (n .. " tools equipped") or "No tools in your backpack"
		end,
	})

	kit.define("unequiptools", {
		run = function()
			local h = kit.hum()
			if not h then
				return noBody()
			end
			h:UnequipTools()
			return true
		end,
	})

	kit.define("activatetools", {
		run = function()
			local h = kit.hum()
			if not h then
				return noBody()
			end
			local list = allTools()
			if #list == 0 then
				return false, "You have no tools"
			end
			for _, t in ipairs(list) do
				pcall(function()
					h:EquipTool(t)
					t:Activate()
				end)
				task.wait(0.05)
			end
			h:UnequipTools()
			return true, "Used " .. #list .. " tools"
		end,
	})

	kit.define("droppabletools", {
		run = function()
			local n = 0
			for _, t in ipairs(allTools()) do
				if not t.CanBeDropped then
					t.CanBeDropped = true
					n += 1
				end
			end
			return true, n .. " tools can be dropped now"
		end,
	})

	kit.define("droptools", {
		run = function()
			local list = allTools()
			if #list == 0 then
				return false, "You have no tools"
			end
			for _, t in ipairs(list) do
				pcall(function()
					t.CanBeDropped = true
					t.Parent = workspace
				end)
			end
			return true, #list .. " tools dropped"
		end,
	})

	kit.define("deletetool", {
		run = function()
			local t = held()
			if not t then
				return false, "You aren't holding a tool"
			end
			t:Destroy()
			return true
		end,
	})

	kit.define("notools", {
		run = function()
			local list = allTools()
			for _, t in ipairs(list) do
				t:Destroy()
			end
			return #list > 0, #list > 0 and (#list .. " tools removed") or "You have no tools"
		end,
	})

	do
		local saved = {}
		kit.define("savetools", {
			run = function()
				for _, t in ipairs(saved) do
					t:Destroy()
				end
				saved = {}
				for _, t in ipairs(allTools()) do
					local ok, copy = pcall(function()
						return t:Clone()
					end)
					if ok and copy then
						saved[#saved + 1] = copy
					end
				end
				return #saved > 0, #saved > 0 and (#saved .. " tools saved") or "You have no tools"
			end,
		})
		kit.define("loadtools", {
			run = function()
				local pack = backpack()
				if not pack then
					return noBody()
				end
				if #saved == 0 then
					return false, "Nothing saved yet, use savetools first"
				end
				for _, t in ipairs(saved) do
					local ok, copy = pcall(function()
						return t:Clone()
					end)
					if ok and copy then
						copy.Parent = pack
					end
				end
				return true, #saved .. " tools back"
			end,
		})
	end

	kit.define("grippos", {
		run = function(arg)
			local n = kit.numbers(arg, 3)
			if not n then
				return false, "Give x y z, like grippos 0 -1 0"
			end
			local t = held()
			if not t then
				return false, "You aren't holding a tool"
			end
			t.GripPos = Vector3.new(Kit.clamp(n[1], -50, 50), Kit.clamp(n[2], -50, 50), Kit.clamp(n[3], -50, 50))
			return true
		end,
	})

	kit.define("blocktool", {
		run = function()
			local t = held()
			local handle = t and t:FindFirstChild("Handle")
			if not handle then
				return false, "You aren't holding a tool with a handle"
			end
			local n = 0
			for _, d in ipairs(handle:GetChildren()) do
				if d:IsA("SpecialMesh") then
					d:Destroy()
					n += 1
				end
			end
			return n > 0, n > 0 and "The tool is a block now" or "That tool has no mesh to remove"
		end,
		desc = "Turns the tool you hold into a block, on your screen. It only works on tools built from a part with a mesh inside it.",
	})

	kit.define("grabtools", {
		requires = { funcs = { "firetouchinterest" } },
		run = function()
			local r = kit.root()
			if not r then
				return noBody()
			end
			local fire = ctx.GENV.firetouchinterest or firetouchinterest
			local n = 0
			for _, inst in ipairs(workspace:GetChildren()) do
				if inst:IsA("Tool") and inst:FindFirstChild("Handle") then
					pcall(function()
						fire(r, inst.Handle, 0)
						fire(r, inst.Handle, 1)
					end)
					n += 1
				end
			end
			return n > 0, n > 0 and (n .. " tools touched") or "No tools are lying around"
		end,
	})
end

return Pack
