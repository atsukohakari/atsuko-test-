local function makeApi()
	local x = { cframes = {}, joints = {}, modes = {}, characters = {}, ws = nil, jp = nil, vel = Vector3.new(), onground = true, moved = {} }
	local V = {}
	for _, name in ipairs({ "HumanoidRootPart", "Torso", "Head", "Right Arm", "Left Arm", "Right Leg", "Left Leg" }) do
		V[name] = { Name = name }
	end
	x.V = V
	x.cframes[V.HumanoidRootPart] = CFrame.new(0, 3, 0)
	x.cframes[V.Torso] = CFrame.new(0, 3, 0)
	x.cframes[V.Head] = CFrame.new(0, 4.5, 0)
	x.cframes[V["Right Arm"]] = CFrame.new(1.5, 3, 0)
	x.cframes[V["Left Arm"]] = CFrame.new(-1.5, 3, 0)
	x.cframes[V["Right Leg"]] = CFrame.new(0.5, 1, 0)
	x.cframes[V["Left Leg"]] = CFrame.new(-0.5, 1, 0)
	local R6 = {
		{ "RootJoint", "HumanoidRootPart", "Torso", CFrame.new(), CFrame.new() },
		{ "Neck", "Torso", "Head", CFrame.new(0, 1, 0), CFrame.new(0, -0.5, 0) },
		{ "Right Shoulder", "Torso", "Right Arm", CFrame.new(1, 0.5, 0), CFrame.new(-0.5, 0.5, 0) },
		{ "Left Shoulder", "Torso", "Left Arm", CFrame.new(-1, 0.5, 0), CFrame.new(0.5, 0.5, 0) },
		{ "Right Hip", "Torso", "Right Leg", CFrame.new(1, -1, 0), CFrame.new(0.5, 1, 0) },
		{ "Left Hip", "Torso", "Left Leg", CFrame.new(-1, -1, 0), CFrame.new(-0.5, 1, 0) },
	}
	for _, r in ipairs(R6) do
		x.joints[#x.joints + 1] = { Name = r[1], Part0 = V[r[2]], Part1 = V[r[3]], C0 = r[4], C1 = r[5] }
	end
	function x.getPart(name)
		for p in pairs(x.cframes) do
			if p.Name == name then
				return p
			end
		end
		return nil
	end
	function x.getJoint(name)
		for _, j in ipairs(x.joints) do
			if j.Name == name then
				return j
			end
		end
		return { C0 = CFrame.new(), C1 = CFrame.new() }
	end
	function x.getPartJoint(e)
		for _, j in ipairs(x.joints) do
			if j.Part0 == e then
				return j
			end
		end
		return nil
	end
	function x.addmode(key, mode)
		x.modes[key] = mode
	end
	function x.setWalkSpeed(n)
		x.ws = n
	end
	function x.setJumpPower(n)
		x.jp = n
	end
	function x.getVel()
		return x.vel
	end
	function x.isOnGround()
		return x.onground
	end
	function x.setCfr(cf)
		x.moved[#x.moved + 1] = cf
		x.cframes[V.HumanoidRootPart] = cf
	end
	function x.refreshrayfilter() end
	function x.hat(name, mesh, tex, size)
		local acc = Instance.new("Accessory")
		acc.Name = name
		local handle = Instance.new("Part")
		handle.Name = "Handle"
		handle.Size = size or Vector3.new(1, 1, 1)
		handle.Parent = acc
		local e = { m = "rbxassetid://" .. mesh, t = tex and ("rbxassetid://" .. tex) or "", p = handle }
		x.cframes[e] = CFrame.new(0, 4, 0)
		local j = { Name = "AccessoryWeld", Part0 = e, Part1 = V.Head, C0 = CFrame.new(0, 0.6, 0), C1 = CFrame.new() }
		x.joints[#x.joints + 1] = j
		return e, j
	end
	return x
end

return { make = makeApi }
