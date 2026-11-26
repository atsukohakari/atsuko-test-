local function hubNotify(title, text, kind, dur)
	local env = (typeof(getgenv) == "function" and getgenv()) or _G
	local f = env.AtsukoNotify
	if type(f) == "function" then
		return pcall(f, title, text, kind, dur)
	end
	return pcall(warn, "[" .. tostring(title) .. "] " .. tostring(text))
end
hubNotify("Master Chief", "Master Chief by Helkern, converted by MelonScripter", "info", 5)

local MC = (function()
	local genv = (typeof(getgenv) == "function" and getgenv()) or _G
	local Players = game:GetService("Players")
	local RunService = game:GetService("RunService")
	local HS = game:GetService("HttpService")
	local lp = Players.LocalPlayer
	local CFI = CFrame.identity
	local CF, ANG, VT = CFrame.new, CFrame.Angles, Vector3.new
	local NAME = "Master Chief"
	local M = {conns = {}, held = false, pushes = 0, slots = {}, parts = {}, dead = false}
	M.free = setmetatable({}, {__call = function(self, folder)
		if typeof(folder) == "Instance" then
			rawset(self, folder, true)
		end
	end})
	local function keep(c)
		M.conns[#M.conns + 1] = c
		return c
	end
	M.keep = keep
	local ALIGNS = {
		{PartName = "Torso", meshid = "4819720316", textureid = "4819722776", C0 = ANG(0, 0, -0.25):Inverse()},
		{PartName = "Right Arm", meshid = "3030546036", textureid = "3033903209", C0 = ANG(-1.57, 0, -1.57):Inverse()},
		{PartName = "Left Arm", meshid = "3030546036", textureid = "3360978739", C0 = ANG(-1.57, 0, 1.57):Inverse()},
		{PartName = "Right Leg", meshid = "3030546036", textureid = "3033898741", C0 = ANG(-1.57, 0, -1.57):Inverse()},
		{PartName = "Left Leg", meshid = "3030546036", textureid = "3409604993", C0 = ANG(-1.57, 0, 1.57):Inverse()},
		{PartName = "Right Arm", meshid = "12344206657", textureid = "12344206675", C0 = (CF(-0.095, 0, 0) * ANG(-2, 0, 0)):Inverse()},
		{PartName = "Left Arm", meshid = "12344207333", textureid = "12344207341", C0 = (CF(0.095, 0, 0) * ANG(-2, 0, 0)):Inverse()},
		{PartName = "Right Leg", meshid = "11263221350", textureid = "11263219250", C0 = ANG(1.57, -1.57, 0):Inverse()},
		{PartName = "Left Leg", meshid = "11159370334", textureid = "11159284657", C0 = ANG(1.57, 1.57, 0):Inverse()},
		{PartName = "Torso", meshid = "14241018198", textureid = "14251599953", C0 = CFI},
		{PartName = "Right Arm", meshid = "14255522247", textureid = "14255543546", C0 = ANG(0, 1.57, 1.57):Inverse()},
		{PartName = "Left Arm", meshid = "14255522247", textureid = "14255543546", C0 = ANG(0, 1.57, 1.57):Inverse()},
		{PartName = "Right Leg", meshid = "17374767929", textureid = "17374768001", C0 = ANG(0, 1.57, 1.57):Inverse()},
		{PartName = "Left Leg", meshid = "17374767929", textureid = "17374768001", C0 = ANG(0, 1.57, 1.57):Inverse()},
		{PartName = "Left Leg", meshid = "14768684979", textureid = "14768683674", C0 = ANG(0, 1.57, 1.57):Inverse()},
		{PartName = "Right Leg", meshid = "14768684979", textureid = "14768683674", C0 = ANG(0, 1.57, 1.57):Inverse()},
	}
	local GUNS = {
		rifle = {
			{mesh = "6774735978", tex = "6774736019", cf = CF(-0.10, 0.55, -0.35) * ANG(3.15, 3, 3), name = "Tactical Cyberpunk Railgun"},
			{mesh = "5548423017", tex = "5548423938", cf = CF(-0.35, -0.15, 0.35) * ANG(0.45, -1.45, -0.55), name = "Kinetic Staff"},
			{hat = "117510548336968", name = "Full Stop Rifle"},
			{hat = "131577122939956", name = "Black Sci-Fi Blaster Rifle"},
			{hat = "87566002870491", name = "Sakura Futuristic Sniper (Back)"},
		},
		shotgun = {
			{mesh = "4998540026", tex = "4998565223", cf = CF(0, -0.05, 0.55) * ANG(1.65, 3, 0), name = "Type-12 Scattershot"},
			{mesh = "15172160708", tex = "15172162617", cf = CF(0.25, 0.15, 0.15) * ANG(0, 1.45, -0.65), name = "24k Gold Plunger"},
			{hat = "71041506045232", name = "Hoshino's Eye of Horus"},
			{hat = "133919187138329", name = "Rebecca Carnage Shotgun"},
		},
		bullet = {
			{mesh = "4307568890", tex = "4307568951", cf = CF(0, 0.15, 0.55) * ANG(1.45, -3.15, -3.15), name = "Elemental Crystal Golem Shoulder Rock"},
		},
	}
	M.GUNS = GUNS
	local TAB = {rifle = 1, shotgun = 2}
	local function idOf(s)
		return type(s) == "string" and (s:match("%d+") or "") or ""
	end
	M.idOf = idOf
	local function firstLine(text)
		text = tostring(text)
		return (text:match("^[^\r\n]*") or text):sub(1, 120)
	end
	local LOADERS = {
		function(id)
			return game:GetObjects(id)
		end,
		function(id)
			return game:GetObjectsAsync(id)
		end,
		function(id)
			local f = rawget(genv, "getobjects") or getobjects
			if type(f) == "function" then
				return f(id)
			end
			return nil
		end,
		function(id)
			return game:GetService("InsertService"):LoadLocalAsset(id)
		end,
	}
	local function getObjects(id)
		local why = nil
		for i, load in ipairs(LOADERS) do
			local ok, r = pcall(load, id)
			if ok and typeof(r) == "Instance" then
				return {r}
			elseif ok and type(r) == "table" and typeof(r[1]) == "Instance" then
				return r
			elseif i == 1 then
				why = ok and "nothing came back" or firstLine(r)
			end
		end
		return nil, why
	end
	M.getObjects = getObjects
	local function lookup(g)
		if not g.hat or g.done then
			return
		end
		g.asked = true
		local list = getObjects("rbxassetid://" .. g.hat)
		for _, item in ipairs(list or {}) do
			pcall(function()
				local hd = item:IsA("BasePart") and item or item:FindFirstChild("Handle") or item:FindFirstChildWhichIsA("BasePart", true)
				if hd and not g.mesh then
					if hd:IsA("MeshPart") then
						g.mesh = idOf(hd.MeshId)
					else
						local sm = hd:FindFirstChildOfClass("SpecialMesh")
						if sm then
							g.mesh = idOf(sm.MeshId)
						end
					end
				end
			end)
			pcall(function()
				item:Destroy()
			end)
		end
		if g.mesh == "" then
			g.mesh = nil
		end
		g.done = true
	end
	M.lookup = lookup
	local FDL = rawget(_G, "GenesisFDless")
	if type(FDL) ~= "table" then
		FDL = genv.GenesisFDless
	end
	if type(FDL) ~= "table" or type(FDL.reanimate) ~= "function" or type(FDL.stopreanimate) ~= "function" then
		FDL = nil
		local R = genv.LumenReanim
		if type(R) ~= "table" or type(R.rig) ~= "function" then
			local base = type(genv.AtsukoHubRaw) == "string" and genv.AtsukoHubRaw or "https://raw.githubusercontent.com/atsukohakari/Atsuko/main/"
			local ok, src = pcall(function()
				if type(genv.AtsukoHubRead) == "function" then
					local body = genv.AtsukoHubRead("Hub/Reanimate.lua")
					if body or genv.AtsukoHubLocal then
						return body
					end
				end
				return game:HttpGet(base .. "Hub/Reanimate.lua")
			end)
			local fn = ok and type(src) == "string" and loadstring(src, "=Reanimate")
			if fn then
				local ok2, r = pcall(fn)
				if ok2 and type(r) == "table" then
					R = r
				end
			end
		end
		if type(R) ~= "table" or type(R.rig) ~= "function" then
			error("couldn't load a reanimate for Master Chief", 0)
		end
		local list = table.clone(ALIGNS)
		for _, a in ipairs(type(R.presets) == "table" and R.presets or {}) do
			list[#list + 1] = a
		end
		FDL = R.rig({aligns = list})
	end
	local priorAligns = genv.AtsukoScriptAligns
	genv.AtsukoScriptAligns = ALIGNS
	local okRe, fd = pcall(FDL.reanimate)
	genv.AtsukoScriptAligns = priorAligns
	if not okRe then
		error(fd, 0)
	end
	if type(fd) ~= "table" or type(fd.cframes) ~= "table" then
		error("couldn't reanimate for Master Chief", 0)
	end
	M.fd = fd
	local live = nil
	pcall(function()
		local L = genv.LumenReanim
		local l = type(L) == "table" and type(L.current) == "function" and L.current()
		if type(l) == "table" and l.fd == fd then
			live = l
		end
	end)
	local function still()
		local ok, on = pcall(FDL.isReanimated)
		return ok and on and true or false
	end
	local deadline = os.clock() + 8
	while still() and live and type(live.isReady) == "function" and not live.isReady() and os.clock() < deadline do
		task.wait()
	end
	if not still() then
		error("the reanimate stopped while Master Chief was starting", 0)
	end
	local BODY = {HumanoidRootPart = VT(2, 2, 1), Torso = VT(2, 2, 1), Head = VT(2, 1, 1), ["Right Arm"] = VT(1, 2, 1), ["Left Arm"] = VT(1, 2, 1), ["Right Leg"] = VT(1, 2, 1), ["Left Leg"] = VT(1, 2, 1)}
	local REST = {Head = CF(0, 1.5, 0), ["Right Arm"] = CF(1.5, 0, 0), ["Left Arm"] = CF(-1.5, 0, 0), ["Right Leg"] = CF(0.5, -2, 0), ["Left Leg"] = CF(-0.5, -2, 0)}
	local LIMB = {Head = "Neck", ["Right Arm"] = "Right Shoulder", ["Left Arm"] = "Left Shoulder", ["Right Leg"] = "Right Hip", ["Left Leg"] = "Left Hip"}
	local R6 = {
		{"RootJoint", "HumanoidRootPart", "Torso", CF(0, 0, 0, -1, 0, 0, 0, 0, 1, 0, 1, 0), CF(0, 0, 0, -1, 0, 0, 0, 0, 1, 0, 1, 0)},
		{"Neck", "Torso", "Head", CF(0, 1, 0, -1, 0, 0, 0, 0, 1, 0, 1, 0), CF(0, -0.5, 0, -1, 0, 0, 0, 0, 1, 0, 1, 0)},
		{"Right Shoulder", "Torso", "Right Arm", CF(1, 0.5, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0), CF(-0.5, 0.5, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0)},
		{"Left Shoulder", "Torso", "Left Arm", CF(-1, 0.5, 0, 0, 0, -1, 0, 1, 0, 1, 0, 0), CF(0.5, 0.5, 0, 0, 0, -1, 0, 1, 0, 1, 0, 0)},
		{"Right Hip", "Torso", "Right Leg", CF(1, -1, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0), CF(0.5, 1, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0)},
		{"Left Hip", "Torso", "Left Leg", CF(-1, -1, 0, 0, 0, -1, 0, 1, 0, 1, 0, 0), CF(-0.5, 1, 0, 0, 0, -1, 0, 1, 0, 1, 0, 0)},
	}
	local doll = Instance.new("Model")
	doll.Name = lp.Name
	local dp, isBody, vp = {}, {}, {}
	for name, size in pairs(BODY) do
		local p = Instance.new("Part")
		p.Name = name
		p.Size = size
		p.Transparency = 1
		p.Anchored = true
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.CastShadow = false
		p.CFrame = REST[name] or CFI
		p.Parent = doll
		dp[name] = p
		isBody[p] = true
		vp[p] = fd.getPart(name)
	end
	for _, r in ipairs(R6) do
		local m = Instance.new("Motor6D")
		m.Name = r[1]
		m.Part0 = dp[r[2]]
		m.Part1 = dp[r[3]]
		m.C0 = r[4]
		m.C1 = r[5]
		m.Parent = dp[r[2]]
	end
	local hum = Instance.new("Humanoid")
	pcall(function()
		hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
		hum.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
		hum.RequiresNeck = false
		hum.BreakJointsOnDeath = false
		hum.EvaluateStateMachine = false
	end)
	hum.Parent = doll
	local animator = Instance.new("Animator")
	animator.Parent = hum
	local animate = Instance.new("Folder")
	animate.Name = "Animate"
	animate.Parent = doll
	doll.PrimaryPart = dp.HumanoidRootPart
	local js, wcOff, order = {}, {}, 0
	local function freed(d)
		for f in pairs(M.free) do
			if d == f or d:IsDescendantOf(f) then
				return true
			end
		end
		return false
	end
	local function watch(d)
		if freed(d) then
			return
		end
		if d:IsA("JointInstance") then
			order += 1
			js[d] = order
			pcall(function()
				d.Enabled = false
			end)
		elseif d:IsA("WeldConstraint") then
			pcall(function()
				if d.Part0 and d.Part1 then
					wcOff[d] = d.Part0.CFrame:ToObjectSpace(d.Part1.CFrame)
					order += 1
					js[d] = order
				end
				d.Enabled = false
			end)
		elseif d:IsA("BasePart") then
			pcall(function()
				d.Anchored = true
				d.CanCollide = false
				d.CanQuery = false
				d.CanTouch = false
			end)
		end
	end
	for _, d in ipairs(doll:GetDescendants()) do
		watch(d)
	end
	keep(doll.DescendantAdded:Connect(watch))
	keep(doll.DescendantRemoving:Connect(function(d)
		js[d] = nil
		wcOff[d] = nil
	end))
	doll.Parent = workspace
	M.doll = doll
	local function ends(j)
		local w = wcOff[j]
		if w then
			return w, CFI
		end
		local c0, c1 = j.C0, j.C1
		if j:IsA("Motor6D") then
			c0 = c0 * j.Transform
		end
		return c0, c1
	end
	local function rel(x, parent, fallback)
		local best, bestN = nil, -1
		for j, n in pairs(js) do
			if n > bestN then
				local a, b = j.Part0, j.Part1
				if (a == x and b == parent) or (a == parent and b == x) then
					best, bestN = j, n
				end
			end
		end
		if not best then
			return fallback
		end
		local c0, c1 = ends(best)
		if best.Part0 == x then
			return c1 * c0:Inverse()
		end
		return c0 * c1:Inverse()
	end
	M.rel = rel
	local function v(p)
		local x = vp[p]
		if not x then
			x = {Name = p.Name}
			vp[p] = x
			fd.cframes[x] = p.CFrame
		end
		return x
	end
	local mirror = {}
	local fj = {}
	for _, r in ipairs(R6) do
		fj[r[1]] = fd.getJoint(r[1])
	end
	local FILE = "MasterChiefAlign.json"
	local KEYS = {"rifle", "shotgun"}
	local VAL = {{0, 0, 0, 0, 0, 0}, {0, 0, 0, 0, 0, 0}}
	local OFF = {CFI, CFI}
	local function rebuild(i)
		local x = VAL[i]
		OFF[i] = CF(x[1], x[2], x[3]) * ANG(math.rad(x[4]), math.rad(x[5]), math.rad(x[6]))
	end
	local function loadAlign()
		if not (isfile and readfile) then
			return false, "your executor can't read files"
		end
		local ok, has = pcall(isfile, FILE)
		if not ok or not has then
			return false, "no saved alignment yet"
		end
		local ok2, data = pcall(function()
			return HS:JSONDecode(readfile(FILE))
		end)
		if not ok2 or type(data) ~= "table" then
			return false, FILE .. " is damaged"
		end
		for i, k in ipairs(KEYS) do
			local t = data[k]
			if type(t) == "table" then
				for n = 1, 6 do
					local x = tonumber(t[n])
					if x and x == x and math.abs(x) < 1e5 then
						VAL[i][n] = x
					end
				end
			end
			rebuild(i)
		end
		return true
	end
	local function saveAlign()
		if not writefile then
			return false, "your executor can't save files"
		end
		local ok, e = pcall(writefile, FILE, HS:JSONEncode({rifle = VAL[1], shotgun = VAL[2]}))
		if not ok then
			return false, tostring(e)
		end
		return true
	end
	loadAlign()
	local function rootCF()
		local rp = fd.getPart("HumanoidRootPart")
		local c = rp and fd.cframes[rp]
		if typeof(c) == "CFrame" then
			return c
		end
		return dp.HumanoidRootPart.CFrame
	end
	local function accName(e)
		local ok, n = pcall(function()
			return rawget(e, "p").Parent.Name
		end)
		return ok and type(n) == "string" and n or ""
	end
	local function hubRow(slot, hat)
		local A = genv.AtsukoAlignment
		if type(A) ~= "table" or type(A.match) ~= "function" then
			return nil
		end
		local ok, row = pcall(A.match, NAME, slot, hat)
		if ok and type(row) == "table" and row.src == "user" then
			return row
		end
		return nil
	end
	local function hubOffset(row)
		local A = genv.AtsukoAlignment
		if not (row.align and type(A) == "table" and type(A.offset) == "function") then
			return nil
		end
		local ok, c = pcall(A.offset, row)
		if ok and typeof(c) == "CFrame" then
			return c
		end
		return nil
	end
	local function axes(size)
		local list = {{VT(1, 0, 0), size.X}, {VT(0, 1, 0), size.Y}, {VT(0, 0, 1), size.Z}}
		table.sort(list, function(a, b)
			return a[2] > b[2]
		end)
		return list[1][1], list[2][1], list[1][2]
	end
	function M.fit(size, info)
		local tip = info and info.tip
		if typeof(tip) ~= "Vector3" or tip.Magnitude < 0.05 then
			return CFI
		end
		local fwd = tip.Unit
		local up = typeof(info.up) == "Vector3" and info.up or VT(0, 1, 0)
		up = up - fwd * up:Dot(fwd)
		if up.Magnitude < 0.05 then
			up = math.abs(fwd.Y) < 0.9 and VT(0, 1, 0) or VT(1, 0, 0)
			up = up - fwd * up:Dot(fwd)
		end
		up = up.Unit
		local side = fwd:Cross(up)
		local a1, a2, long = axes(size)
		local a3 = a1:Cross(a2)
		local function col(x)
			return fwd * a1:Dot(x) + up * a2:Dot(x) + side * a3:Dot(x)
		end
		return CFrame.fromMatrix(tip - fwd * (long / 2), col(VT(1, 0, 0)), col(VT(0, 1, 0)), col(VT(0, 0, 1)))
	end
	local function sizeOf(e)
		local s = VT(1, 1, 1)
		pcall(function()
			s = rawget(e, "p").Size
		end)
		return s
	end
	function M.choose(slot, hats)
		local best, rank, c0, label, row = nil, math.huge, nil, nil, nil
		for _, h in ipairs(hats) do
			local mine = hubRow(slot, h.hat)
			if mine then
				if rank > 0 then
					best, rank, label, row = h, 0, h.hat.name, mine
					c0 = hubOffset(mine)
				end
			elseif h.hat.mesh ~= "" then
				for i, g in ipairs(GUNS[slot] or {}) do
					if i < rank and g.mesh and h.hat.mesh == g.mesh and (not g.tex or h.hat.tex == "" or h.hat.tex == g.tex) then
						best, rank, label, row = h, i, g.name, nil
						c0 = (g.cf and not M.standIn) and g.cf:Inverse() or nil
					end
				end
			end
		end
		return best, c0, label, row
	end
	local taken = {}
	local function worn()
		local out = {}
		for e in pairs(fd.cframes) do
			if type(e) == "table" and not taken[e] and rawget(e, "m") ~= nil then
				out[#out + 1] = {e = e, hat = {mesh = idOf(rawget(e, "m")), tex = idOf(rawget(e, "t")), name = accName(e)}}
			end
		end
		return out
	end
	local waiting = false
	function M.scan()
		if M.dead then
			return
		end
		local hats = nil
		local pending = false
		for _, slot in ipairs({"rifle", "shotgun", "bullet"}) do
			local info = M.parts[slot]
			if info and not M.slots[slot] then
				hats = hats or worn()
				local h, c0, label = M.choose(slot, hats)
				local j = h and fd.getPartJoint(h.e)
				if j then
					taken[h.e] = true
					for i, other in ipairs(hats) do
						if other == h then
							table.remove(hats, i)
							break
						end
					end
					M.slots[slot] = {j = j, e = h.e, tab = TAB[slot], home = {j.Part1, j.C0, j.C1}, name = label ~= "" and label or h.hat.name}
					j.Part1 = v(info.part)
					j.C0 = c0 or M.fit(sizeOf(h.e), info):Inverse()
					j.C1 = OFF[TAB[slot]] or CFI
				else
					for _, g in ipairs(GUNS[slot] or {}) do
						if g.hat and not g.done then
							pending = true
						end
					end
				end
			end
		end
		waiting = pending
	end
	local function report()
		if M.dead or M.told then
			return
		end
		M.told = true
		local bits = {}
		for _, slot in ipairs({"rifle", "shotgun"}) do
			local r = M.slots[slot]
			bits[#bits + 1] = (slot == "rifle" and "Rifle: " or "Shotgun: ") .. (r and r.name or "none")
		end
		local missing = not (M.slots.rifle and M.slots.shotgun)
		hubNotify(NAME, table.concat(bits, "  ·  ") .. (missing and ". Wear one from the list or pick yours in Main Scripts > Setup > Hats & alignment" or ""), missing and "warn" or "info", missing and 8 or 5)
	end
	function M.arm(list)
		M.armed = os.clock()
		for slot, info in pairs(list) do
			pcall(function()
				local frameP = info.frame or info.part
				local pcf = frameP.CFrame
				local hole = info.model and info.model:FindFirstChild("Hole", true)
				if hole and hole:IsA("BasePart") then
					info.tip = pcf:PointToObjectSpace(hole.Position)
				end
				info.up = pcf:VectorToObjectSpace(VT(0, 1, 0))
			end)
			M.parts[slot] = info
		end
		M.scan()
		task.spawn(function()
			for _, slot in ipairs({"rifle", "shotgun"}) do
				for _, g in ipairs(GUNS[slot]) do
					if M.dead then
						return
					end
					if not M.slots[slot] and g.hat and not g.done then
						task.wait(M.lookupGap or 1)
						if M.dead then
							return
						end
						lookup(g)
						M.scan()
					end
				end
			end
			waiting = false
			report()
		end)
	end
	local function frame()
		if not doll or M.dead then
			return
		end
		local now = os.clock()
		local dt = math.min(now - (M.t or now), 0.1)
		M.t = now
		for _, r in pairs(M.slots) do
			r.j.C1 = OFF[r.tab] or CFI
		end
		fj.RootJoint.C0 = rel(dp.Torso, dp.HumanoidRootPart, CFI) * fj.RootJoint.C1
		for name, mn in pairs(LIMB) do
			local j = fj[mn]
			j.C0 = rel(dp[name], dp.Torso, REST[name]) * j.C1
		end
		local at = {}
		for _, p in pairs(dp) do
			local c = fd.cframes[vp[p]]
			if typeof(c) == "CFrame" then
				at[p] = c
			end
		end
		for _ = 1, 16 do
			local grew = false
			for j in pairs(js) do
				local a, b = j.Part0, j.Part1
				if a and b and a ~= b and not (isBody[a] and isBody[b]) then
					if at[b] and not at[a] then
						local c0, c1 = ends(j)
						at[a] = at[b] * c1 * c0:Inverse()
						grew = true
					elseif at[a] and not at[b] then
						local c0, c1 = ends(j)
						at[b] = at[a] * c0 * c1:Inverse()
						grew = true
					end
				end
			end
			if not grew then
				break
			end
		end
		for p, c in pairs(at) do
			if p.Parent then
				p.CFrame = c
			end
		end
		for j, m in pairs(mirror) do
			if not js[j] then
				m.Part0 = nil
			end
		end
		for j in pairs(js) do
			local a, b = j.Part0, j.Part1
			local m = mirror[j]
			if a and b and a ~= b and at[a] and at[b] and not (isBody[a] and isBody[b]) then
				if not m then
					m = {Name = j.Name}
					mirror[j] = m
					fd.joints[#fd.joints + 1] = m
				end
				local c0, c1 = ends(j)
				if isBody[a] then
					m.Part0, m.Part1, m.C0, m.C1 = v(b), v(a), c1, c0
				else
					m.Part0, m.Part1, m.C0, m.C1 = v(a), v(b), c0, c1
				end
			elseif m then
				m.Part0 = nil
			end
		end
		for p, x in pairs(vp) do
			if not isBody[p] and not at[p] and p.Parent then
				fd.cframes[x] = p.CFrame
			end
		end
		local ws = M.held and 0 or (tonumber(hum.WalkSpeed) or 16)
		if ws ~= M.ws and type(fd.setWalkSpeed) == "function" then
			M.ws = ws
			pcall(fd.setWalkSpeed, ws)
		end
		local jp = M.held and 0 or 50
		if jp ~= M.jp and type(fd.setJumpPower) == "function" then
			M.jp = jp
			pcall(fd.setJumpPower, jp)
		end
		if waiting then
			M.retry = (M.retry or 0) + dt
			if M.retry >= 1 then
				M.retry = 0
				M.scan()
			end
		end
	end
	M.frame = frame
	fd.addmode("default", {idle = frame, walk = frame, jump = frame, fall = frame})
	local rayP = RaycastParams.new()
	rayP.FilterType = Enum.RaycastFilterType.Exclude
	pcall(function()
		rayP.RespectCanCollide = true
	end)
	local function refreshRay()
		local list = {doll}
		for _, plr in ipairs(Players:GetPlayers()) do
			if plr.Character then
				list[#list + 1] = plr.Character
			end
		end
		if live and live.rig then
			list[#list + 1] = live.rig
		end
		if type(fd.characters) == "table" then
			for _, c in pairs(fd.characters) do
				if typeof(c) == "Instance" then
					list[#list + 1] = c
				end
			end
		end
		rayP.FilterDescendantsInstances = list
	end
	function M.vel()
		if type(fd.getVel) == "function" then
			local ok, v3 = pcall(fd.getVel)
			if ok and typeof(v3) == "Vector3" then
				return v3
			end
		end
		return Vector3.zero
	end
	function M.moveDir()
		if type(fd.getMoveDirection) == "function" then
			local ok, d = pcall(fd.getMoveDirection)
			if ok and typeof(d) == "Vector3" then
				return d
			end
		end
		local h = M.vel() * VT(1, 0, 1)
		return h.Magnitude > 0.05 and h.Unit or Vector3.zero
	end
	function M.ground()
		if type(fd.isOnGround) == "function" then
			local ok, on = pcall(fd.isOnGround)
			return ok and on == true
		end
		return true
	end
	function M.hold(on)
		M.held = on == true
	end
	function M.push(vel)
		if typeof(vel) ~= "Vector3" or type(fd.setCfr) ~= "function" then
			return
		end
		local flat = VT(vel.X, 0, vel.Z)
		if flat.Magnitude < 1 then
			return
		end
		M.pushes += 1
		local my = M.pushes
		refreshRay()
		task.spawn(function()
			local speed = flat
			local t0 = os.clock()
			local last = t0
			while not M.dead and my == M.pushes and speed.Magnitude > 2 and os.clock() - t0 < 0.6 do
				RunService.Heartbeat:Wait()
				local now = os.clock()
				local dt = math.min(now - last, 0.05)
				last = now
				local cf = rootCF()
				local step = speed * dt
				if step.Magnitude > 1e-3 then
					local hit = workspace:Raycast(cf.Position, step + step.Unit * 1.5, rayP)
					if hit then
						break
					end
					pcall(fd.setCfr, cf + step)
				end
				speed = speed * math.exp(-dt * 12)
			end
		end)
	end
	function M.alive()
		return not M.dead and doll ~= nil and doll.Parent ~= nil
	end
	function M.standInModel()
		local pack = Instance.new("Model")
		pack.Name = "MasterChiefGuns"
		local function part(name, parent, size, cf)
			local p = Instance.new("Part")
			p.Name = name
			p.Size = size
			p.CFrame = cf
			p.Transparency = 1
			p.CanCollide = false
			local mesh = Instance.new("BlockMesh")
			mesh.Scale = VT(0, 0, 0)
			mesh.Parent = p
			p.Parent = parent
			return p
		end
		local function weld(p0, p1, c0, c1, parent)
			local w = Instance.new("Weld")
			w.Part0 = p0
			w.Part1 = p1
			w.C0 = c0 or CFI
			w.C1 = c1 or CFI
			w.Parent = parent
			return w
		end
		local function gun(name, bodyName, length, back)
			local m = Instance.new("Model")
			m.Name = name
			local grip = ANG(-math.pi / 2, 0, 0) * CF(0, 0.2, 0.4 - length / 2)
			local body = part(bodyName, m, VT(0.3, 0.5, length), CFI)
			local joint2 = part("joint2", m, VT(0.2, 0.2, 0.2), grip:Inverse())
			local hole = part("Hole", m, VT(0.2, 0.2, 0.2), CF(0, 0, -length / 2))
			local eqp = part("eqp", m, VT(0.2, 0.2, 0.2), grip:Inverse() * CF(0, 1, 0))
			local uneqp = part("uneqp", m, VT(0.2, 0.2, 0.2), grip:Inverse() * back:Inverse())
			weld(joint2, body, CFI, grip:Inverse(), joint2)
			weld(eqp, joint2, CF(0, -1, 0), CFI, eqp)
			weld(uneqp, joint2, back, CFI, uneqp)
			weld(body, hole, CF(0, 0, -length / 2), CFI, body)
			m.Parent = pack
			return m
		end
		gun("rifle", "Handle", 3.2, CF(0.2, 0, 0.75) * ANG(0, 0, math.rad(140)))
		gun("shotgun", "shotgun", 2.6, CF(-0.2, 0, 0.75) * ANG(0, 0, math.rad(-140)))
		local shirt = Instance.new("Shirt")
		shirt.Name = "s"
		shirt.Parent = pack
		local pants = Instance.new("Pants")
		pants.Name = "p"
		pants.Parent = pack
		local gren = Instance.new("Part")
		gren.Name = "gren"
		gren.Shape = Enum.PartType.Ball
		gren.Size = VT(0.7, 0.7, 0.7)
		gren.Color = Color3.fromRGB(70, 80, 50)
		gren.Material = Enum.Material.Metal
		gren.CanCollide = false
		gren.Parent = pack
		return pack
	end
	function M.objects(id)
		local list, why = nil, nil
		for attempt = 1, 3 do
			list, why = getObjects(id)
			if list or M.dead then
				break
			end
			task.wait(attempt)
		end
		local found = list and list[1]
		if found and found:FindFirstChild("rifle") and found:FindFirstChild("shotgun") and found:FindFirstChild("gren") then
			return found
		end
		M.standIn = true
		M.loadWhy = found and "the model came back without its guns" or why
		hubNotify(NAME, "Roblox didn't send the gun models (" .. tostring(M.loadWhy) .. "), so Master Chief uses its own. Your gun hats still work and are fitted by their size", "warn", 8)
		return M.standInModel()
	end
	local realMouse = lp:GetMouse()
	local signals = {}
	M.mouse = setmetatable({}, {__index = function(_, k)
		if k == "Button1Down" or k == "Button1Up" or k == "KeyDown" or k == "KeyUp" or k == "Move" or k == "Button2Down" or k == "Button2Up" then
			local s = signals[k]
			if not s then
				local real = realMouse[k]
				s = {}
				s.Connect = function(_, f)
					return keep(real:Connect(f))
				end
				s.connect = s.Connect
				s.Wait = function()
					return real:Wait()
				end
				signals[k] = s
			end
			return s
		end
		local x = realMouse[k]
		if type(x) == "function" then
			return function(_, ...)
				return x(realMouse, ...)
			end
		end
		return x
	end})
	local alignStop = nil
	local function finish()
		if M.dead then
			return
		end
		M.dead = true
		local conns = M.conns
		M.conns = {}
		task.delay(0.3, function()
			for _, c in ipairs(conns) do
				pcall(function()
					c:Disconnect()
				end)
			end
			for _, c in ipairs(M.conns) do
				pcall(function()
					c:Disconnect()
				end)
			end
			table.clear(M.conns)
		end)
		for _, r in pairs(M.slots) do
			pcall(function()
				r.j.Part1, r.j.C0, r.j.C1 = r.home[1], r.home[2], r.home[3]
			end)
		end
		table.clear(M.slots)
		for _, m in pairs(mirror) do
			m.Part0 = nil
		end
		if alignStop then
			local f = alignStop
			alignStop = nil
			pcall(f)
		end
		local d = doll
		doll = nil
		if d then
			pcall(function()
				d:FindFirstChildOfClass("Humanoid").Health = 0
			end)
			task.delay(0.5, function()
				pcall(function()
					d:Destroy()
				end)
			end)
		end
	end
	M.stop = finish
	keep(RunService.Heartbeat:Connect(function()
		if M.dead then
			return
		end
		if not still() or not (doll and doll.Parent) then
			finish()
		end
	end))
	local watchers = {}
	local function fire(what)
		for _, f in ipairs(table.clone(watchers)) do
			pcall(f, what)
		end
	end
	local AL = {version = 1, title = NAME, tabs = {"Rifle", "Shotgun"}, file = FILE, dirty = false, open = false, marker = false, hint = "Rifle moves the rifle hat and Shotgun the shotgun hat. A gun the script doesn't know is fitted by its size, so if one points the wrong way turn it 180 here. Tap Alignment on the Main Scripts bar to open it again."}
	M.AL = AL
	function AL.alive()
		return doll ~= nil and not M.dead
	end
	function AL.get(i)
		return VAL[i] and table.clone(VAL[i]) or nil
	end
	function AL.later()
		AL.tok = (AL.tok or 0) + 1
		local my = AL.tok
		task.delay(1.5, function()
			if my == AL.tok and AL.dirty and doll and AL.save() then
				fire("saved")
			end
		end)
	end
	function AL.set(i, k, n)
		local x = VAL[i]
		n = tonumber(n)
		if not x or not n or n ~= n or math.abs(n) >= 1e5 then
			return nil
		end
		if k > 3 then
			n = ((n + 180) % 360) - 180
			n = math.floor(n * 10 + 0.5) / 10
		else
			n = math.floor(n * 1000 + 0.5) / 1000
		end
		x[k] = n
		rebuild(i)
		AL.dirty = true
		AL.later()
		return n
	end
	function AL.put(i, vals)
		if not VAL[i] or type(vals) ~= "table" then
			return
		end
		for k = 1, 6 do
			VAL[i][k] = tonumber(vals[k]) or 0
		end
		rebuild(i)
		AL.dirty = true
		AL.later()
	end
	function AL.reset(i)
		AL.put(i, {0, 0, 0, 0, 0, 0})
	end
	function AL.save()
		AL.tok = (AL.tok or 0) + 1
		local ok, e = saveAlign()
		if ok then
			AL.dirty = false
		end
		return ok, e
	end
	function AL.load()
		local ok, e = loadAlign()
		if ok then
			AL.dirty = false
		end
		fire("load")
		return ok, e
	end
	function AL.watch(f)
		watchers[#watchers + 1] = f
		return function()
			local i = table.find(watchers, f)
			if i then
				table.remove(watchers, i)
			end
		end
	end
	function AL.found()
		local r, s = M.slots.rifle, M.slots.shotgun
		return "Rifle: " .. (r and r.name or "none") .. "   |   Shotgun: " .. (s and s.name or "none")
	end
	function AL.hat(i)
		local r = M.slots[i == 1 and "rifle" or i == 2 and "shotgun" or ""]
		local e = r and r.e
		if type(e) ~= "table" then
			return nil
		end
		local m, t = rawget(e, "m"), rawget(e, "t")
		local id = (type(m) == "string" and string.match(m, "(%d+)%D*$")) or (type(t) == "string" and string.match(t, "(%d+)%D*$")) or nil
		if not id then
			return nil
		end
		local name = nil
		pcall(function()
			name = rawget(e, "p").Parent.Name
		end)
		return id, id, type(name) == "string" and name or r.name
	end
	alignStop = function()
		if AL.dirty then
			pcall(saveAlign)
			AL.dirty = false
		end
		AL.open = false
		if genv.AtsukoAlign == AL then
			genv.AtsukoAlign = nil
		end
		fire("stop")
		local h = genv.AtsukoHub
		if type(h) == "table" and type(h.AlignReady) == "function" then
			pcall(h.AlignReady)
		end
	end
	function M.toggleAlign()
		local h = genv.AtsukoHub
		if type(h) == "table" and type(h.Align) == "function" then
			pcall(h.Align)
		else
			hubNotify(NAME, "Open Atsuko Hub to line the guns up, the alignment lives there", "info", 5)
		end
	end
	genv.AtsukoAlign = AL
	do
		local h = genv.AtsukoHub
		if type(h) == "table" and type(h.AlignReady) == "function" then
			pcall(h.AlignReady)
		end
	end
	genv.AtsukoMasterChief = M
	return M
end)()

local script = MC.objects("rbxassetid://10170990440")
	local AHB = Instance.new("BindableEvent")
	
	local FPS = 30
	
	local TimeFrame = 0
	
	local LastFrame = tick()
	local Frame = 1/FPS
	
	MC.keep(game:service'RunService'.Heartbeat:connect(function(s,p)
		TimeFrame = TimeFrame + s
		if(TimeFrame >= Frame)then
			for i = 1,math.floor(TimeFrame/Frame) do
				AHB:Fire()
			end
			LastFrame=tick()
			TimeFrame=TimeFrame-Frame*math.floor(TimeFrame/Frame)
		end
	end))


	function swait(dur)
		if(dur == 0 or typeof(dur) ~= 'number')then
			AHB.Event:wait()
		else
			for i = 1, dur*FPS do
				AHB.Event:wait()
			end
		end
	end

wait(1/60)	
player = game:GetService("Players").LocalPlayer
mouse = MC.mouse
character = MC.doll
playergui = player.PlayerGui
humanoid = character.Humanoid
rootpart = character.HumanoidRootPart
head = character.Head
torso = character.Torso
rightarm = character["Right Arm"]
leftarm = character["Left Arm"]
rightleg = character["Right Leg"]
leftleg = character["Left Leg"]
rootjoint = rootpart.RootJoint
neck = torso.Neck
rightshoulder = torso["Right Shoulder"]
leftshoulder = torso["Left Shoulder"]
righthip = torso["Right Hip"]
lefthip = torso["Left Hip"]


song = Instance.new("Sound",torso)

cf = CFrame.new
d = cf(0,0,0)
vt = Vector3.new
random = math.random
cos = math.cos
sin = math.sin
rad = math.rad
angles = CFrame.Angles

tweenservice = game:GetService("TweenService")
debris = game:GetService("Debris")

sine = 0
mousehold,keyhold = false,false
rooted = false
attack = false
rootc0 = cf(0, 0, 0) * angles(rad(-90), rad(0), rad(180))
neckc0 = cf(0, 1, 0) * angles(rad(-90), rad(0), rad(180))
change = 1
effects = Instance.new("Folder",character)
effects.Name = "effects lol"
MC.free(effects)
if humanoid.Animator then humanoid.Animator:Destroy() end
anim = "idle"

ArtificialHB = Instance.new("BindableEvent", script)
ArtificialHB.Name = "ArtificialHB"
script:WaitForChild("ArtificialHB")
frame = 1/60
tf = 0
allowframeloss = false
tossremainder = false
lastframe = tick()
script.ArtificialHB:Fire()
MC.keep(game:GetService("RunService").Heartbeat:connect(function(s, p)
	tf = tf + s
	if tf >= frame then
		if allowframeloss then
			script.ArtificialHB:Fire()
			lastframe = tick()
		else
			for i = 1, math.floor(tf / frame) do
				script.ArtificialHB:Fire()
			end
		lastframe = tick()
		end
		if tossremainder then
			tf = 0
		else
			tf = tf - frame * math.floor(tf / frame)
		end
	end
end))


function Swait(n)
	if n == 0 or n == nil then
		ArtificialHB.Event:wait()
	else
		for i = 1, n do
			ArtificialHB.Event:wait()
		end
	end
end

function part(parent, mat, transp, color, size, anchored, shape)
	local p = Instance.new("Part")
	p.Transparency = transp
	p.CanCollide = false
	p.Locked = true
	if not type(anchored) == "boolean" then
	p.Anchored = true	
	end
	p.Anchored = anchored
	p.Color = color
	p.Size = size
	p.Position = rootpart.Position
	p.Material = mat
	p.Parent = parent
	if shape then
	if shape == "ball" then
	local m = Instance.new("SpecialMesh",p)
	m.MeshType = "Sphere"	
	end	
	end
	return p
end

function weldBetween(a, b)
	    local weldd = Instance.new("ManualWeld")
	    weldd.Part0 = a
	    weldd.Part1 = b
	    weldd.C0 = CFrame.new()
	    weldd.C1 = b.CFrame:inverse() * a.CFrame
	    weldd.Parent = a
	    return weldd
end

function weld(parent, part0, part1, c0, c1)
	local w = Instance.new("Weld")
	w.Part0 = part0
	w.Part1 = part1
	w.C0 = c0
	w.C1 = c1
	w.Parent = parent
	return w
end

function sound(id, parent, vol, pitch)
		local so = Instance.new("Sound")
		so.EmitterSize = 5*vol
		so.Parent = parent
		so.Volume = vol
		so.Pitch = pitch
		so.SoundId = "rbxassetid://"..id
		so:Play()
	return so
end

function Tween(obj,prop,easing,easingdir,timer)
local easin = Enum.EasingStyle[easing]
local easindir = Enum.EasingDirection[easingdir]
local tweeninf = TweenInfo.new(
	timer/1,	
	easin,
	easindir,
	0,
	false,
	0
)
local props = prop
local tweenanim = tweenservice:Create(obj,tweeninf,props)
tweenanim:Play()
end

function raycast(pos, dir, range, ignore)
	return workspace:FindPartOnRay(Ray.new(pos, dir.unit * range), ignore)
end

function castray(start, endp, dist, ignore)
	local dir = cf(start,endp).lookVector
	return raycast(start, dir, dist, ignore)
end

function Effect(tblee)
	coroutine.resume(coroutine.create(function()
		local origpos = (tblee.cf or nil)
		local moveto = (tblee.moveto or nil)
		local color = (tblee.clr or Color3.new(0,0,0))
		local color2 = (tblee.clr2 or nil)
		local defaultsize = (tblee.size or vt(2,2,2))
		local material = (tblee.mat or "Neon")
		local locker = (tblee.lock or false)
		local rotateX = (tblee.radX or 0)
		local rotateY = (tblee.radY or 0)
		local rotateZ = (tblee.radZ or 0)
		local secondsize = (tblee.size2 or vt(4,4,4))
		local acttime = (tblee.waits or 100)
		local transpar = (tblee.tran or 0)
		local transpar2 = (tblee.tran2 or 1)
		local typeofmesh = (tblee.mtype or "S")
		local movingspeed = nil
		local mesh = nil
		if typeof(origpos) == "Vector3"then origpos=cf(origpos) end 
		if typeof(moveto) == "CFrame"then moveto=moveto.p end 
		if typeof(color) == "BrickColor"then color=color.Color end 
		if typeof(color2) == "BrickColor"then color2=color2.Color end
		if origpos then
		local p=Instance.new("Part",effects)p.Anchored=true p.CanCollide=false p.Color=color p.CFrame=origpos p.Material=material p.Size=Vector3.new(1,1,1)p.CanCollide=false p.Transparency=transpar p.CastShadow=false p.Locked=true
		if typeofmesh == "Box" or typeofmesh == "B" or typeofmesh == "1" then
			mesh=Instance.new("BlockMesh",p)mesh.Scale=defaultsize
		elseif typeofmesh == "Sphere" or typeofmesh == "S" or typeofmesh == "2" then
			mesh=Instance.new("SpecialMesh",p)mesh.MeshType="Sphere"mesh.Scale=defaultsize
		elseif typeofmesh == "Cylinder" or typeofmesh == "C" or typeofmesh == "3" then
			mesh=Instance.new("SpecialMesh",p)mesh.MeshType="Cylinder"mesh.Scale=defaultsize
		elseif typeofmesh == "Slash" or typeofmesh == "SL" or typeofmesh == "4" then
			mesh=Instance.new("SpecialMesh",p)mesh.MeshType="FileMesh"mesh.MeshId="rbxassetid://662585058"mesh.Scale = vt(defaultsize.X/10,0,defaultsize.X/10)
		elseif typeofmesh == "Wave" or typeofmesh == "W" or typeofmesh == "5" then
			mesh=Instance.new("SpecialMesh",p)mesh.MeshType="FileMesh"mesh.MeshId="rbxassetid://20329976"mesh.Scale = vt(0,0,-defaultsize.X/8)
		end
		if locker == true then
			p.Position = origpos.p
			if typeofmesh == "Cylinder" or typeofmesh == "C" or typeofmesh == "3" then 
				p.CFrame = cf(p.Position,moveto)*cf(0,0,-(p.Size.Z/1.5))*angles(0,rad(90),0)
			else
				p.CFrame = cf(p.Position,moveto)*cf(0,0,-(p.Size.Z/1.5))
			end
		else
			if typeofmesh == "Cylinder" or typeofmesh == "C" or typeofmesh == "3" then 
				p.CFrame = origpos*CFrame.Angles(0,math.rad(90),0)
			else
				p.CFrame = origpos
			end
		end
		if color2 then
		Tween(p,{Color = color2},"Linear","In",acttime/60)
		end	
		if mesh then
			if  moveto then
				movingspeed=(origpos.p - moveto).Magnitude/acttime
			end
			local endsize=(defaultsize - secondsize)
			local endtranpar=transpar-transpar2
			for i = 1, acttime+1 do Swait()
				mesh.Scale=mesh.Scale-endsize/acttime
				p.Transparency = p.Transparency - endtranpar/acttime
				p.CFrame=p.CFrame*CFrame.Angles(math.rad(rotateX),math.rad(rotateY),math.rad(rotateZ))
				if moveto ~= nil then
					local a = p.Orientation
					if typeofmesh == "Cylinder" or typeofmesh == "C" or typeofmesh == "3" then 
						p.CFrame = CFrame.new(p.Position,moveto)*CFrame.new(0,0,-movingspeed)*CFrame.Angles(0,math.rad(90),0)
					else
						p.CFrame = CFrame.new(p.Position,moveto)*CFrame.new(0,0,-movingspeed)
					end
					p.Orientation = a
				end
			end
			p:Destroy()
		end
		elseif origpos == nil then
		warn("Origpos is nil!")
		end
	end))
end

function attcf(p)
	return p.Parent.CFrame*cf(p.Position)
end

function unanchor(what)
	if typeof(what) == "Instance" then
	for _,v in pairs(what:GetDescendants()) do
		if v:IsA("BasePart") then
			v.Anchored = false
		end
	end
	else
	warn("not an instance")
	end
end

function randomangle()
	return angles(rad(random(1,360)),rad(random(1,360)),rad(random(1,360)))
end

function randompos(num,typ)
	if typ == "vt" or not typ then
		return vt(random(-num,num),random(-num,num),random(-num,num))
	elseif typ == "cf" then
		return cf(random(-num,num),random(-num,num),random(-num,num))
	end
end

function deathfunction(model)
	model:BreakJoints()
	for _, c in pairs(model:GetChildren()) do
		if c:IsA("BasePart") and c.Name ~= "HumanoidRootPart" then
			if c.Name == "Head" then
				
				elseif c.Name ~= "HumanoidRootPart" then
					
			end
		end
	end
	debris:AddItem(model,6)
end

function applydamage(humanoid,damage)
end

function aoe(pos,range,min,max,fling,instakill,knock)
end

function agyro()
	local g = Instance.new("BodyGyro",rootpart)
	g.D = 25
	g.P = 20000
	g.MaxTorque = vt(0,4000000,0)
	g.CFrame = cf(rootpart.Position,mouse.Hit.p)
	coroutine.wrap(function()
		repeat
			Swait()
			g.CFrame = cf(rootpart.Position,mouse.Hit.p)
		until not attack
		g:Destroy()
	end)()
end


songid = 0
speed = 16
riflequipped = true

for _,v in next, humanoid:GetPlayingAnimationTracks() do
	 v:Stop();
end
character.Animate.Parent = nil

local la = Instance.new("Weld")
local ra = Instance.new("Weld")

ra.Name = "ra"
ra.Part0 = torso 
ra.C0 = cf(1.5, 0.5, 0)
ra.C1 = cf(0, 0.5, 0)
ra.Part1 = rightarm
ra.Parent = torso  

la.Name = "la"
la.Part0 = torso 
la.C0 = cf(-1.5, 0.5, 0)
la.C1 = cf(0, 0.5, 0) 
la.Part1 = leftarm
la.Parent = torso

local lh = weld(leftleg,torso,leftleg,cf(-.5,-1,0),d)
lh.C1 = cf(0,1,0)
local rh = weld(rightleg,torso,rightleg,cf(.5,-1,0),d)
rh.C1 = cf(0,1,0)

rifle = script.rifle
riflez = Instance.new("Part")
riflez.Name = "Rifle"
riflez.Transparency = 1
riflez.Parent = character
riflez.CanCollide = false

local rifleweldz = Instance.new("Weld")
rifleweldz.Part0 = rifle.Handle
rifleweldz.Part1 = riflez
rifleweldz.Parent = character

for _,v in pairs(rifle:GetChildren()) do
if v:IsA("BasePart") and v.Name ~= "Hole" and v.Name ~= "uneqp" and v.Name ~= "eqp" then
Tween(v,{Transparency = 1},"Linear","In",.5)
end
end

shirt = script.s
shirt.Parent = character
pants = script.p
pants.Parent = character
head.Transparency = 1
eqpweld = weld(rifle,rifle.eqp,rightarm,d,d)
uneqpweld = weld(rifle,rifle.uneqp,torso,d,d)
uneqpweld.Parent = nil
unanchor(rifle)
rifle.Parent = character
riflejoint = rifle.joint2.Weld
shg = script.shotgun
shg.shotgun.Transparency = 0.65
shotgunz = Instance.new("Part")
shotgunz.Name = "Shotgun"
shotgunz.Transparency = 1
shotgunz.Parent = character
shotgunz.CanCollide = false

local shotgunweldz = Instance.new("Weld")
shotgunweldz.Part0 = shg.shotgun
shotgunweldz.Part1 = shotgunz
shotgunweldz.Parent = character

local PLAYER = game.Players.LocalPlayer
local MOUSE = MC.mouse

local Bullet = Instance.new("Part")
Bullet.Name = "Bullet"
Bullet.Size = Vector3.new(1, 1, 1)
Bullet.Transparency = 0.95
Bullet.CanCollide = false
Bullet.Parent = character

local BulletWeld = Instance.new("Weld")
BulletWeld.Part0 = character["Rifle"]
BulletWeld.Part1 = Bullet
MC.arm({rifle = {part = riflez, frame = rifle.Handle, model = rifle}, shotgun = {part = shotgunz, frame = shg.shotgun, model = shg}, bullet = {part = Bullet}})

local SHOOTING = false


function makeafuckingtween(fuckingposition)
    local fuckingtween = game:GetService("TweenService"):Create(Bullet, TweenInfo.new(0.001, Enum.EasingStyle.Cubic, Enum.EasingDirection.In), {Position = fuckingposition})
    fuckingtween:Play()
end

MOUSE.Button1Down:Connect(function()
    SHOOTING = true
    repeat
    task.wait()
    makeafuckingtween(MOUSE.Hit.Position)
    task.wait(0.225)
    makeafuckingtween(character["Right Arm"].Position)
    task.wait()
    until SHOOTING == false or not MC.alive()
end)

MOUSE.Button1Up:Connect(function()
    SHOOTING = false
    repeat task.wait()
    makeafuckingtween(character["Right Arm"].Position)
    until SHOOTING == true or not MC.alive()
end)

seqw = weld(shg,shg.eqp,rightarm,d,d)
seqw.Parent = nil
suneq = weld(shg,shg.uneqp,torso,d,d)
unanchor(shg)
shg.Parent = character
weap = "rifle"
shotgunjoint = shg.joint2.Weld
changin = false
gren = script.gren
gren.Parent = nil

function switch()
	if not attack and weap == "rifle" then
			changin = true
		for _,v in pairs(rifle:GetChildren()) do
			if v:IsA("BasePart") and v.Name ~= "Hole" and v.Name ~= "uneqp" and v.Name ~= "eqp" then
				Tween(v,{Transparency = 1},"Linear","In",.5)
			end
		end
		Tween(shg.shotgun,{Transparency = 1},"Linear","In",.5)
		delay(.5,function()
		eqpweld.Parent = nil
		uneqpweld.Parent = rifle
		seqw.Parent = shg
		suneq.Parent = nil
		for _,v in pairs(rifle:GetChildren()) do
			if v:IsA("BasePart") and v.Name ~= "Hole" and v.Name ~= "uneqp" and v.Name ~= "eqp" then
				Tween(v,{Transparency = 1},"Linear","In",.5)
			end
		end	
		Tween(shg.shotgun,{Transparency = 1},"Linear","In",.5)
		weap = "shotgun"
		changin = false
		end)
	elseif not attack and weap == "shotgun" then
		for _,v in pairs(rifle:GetChildren()) do
			if v:IsA("BasePart") and v.Name ~= "Hole" and v.Name ~= "uneqp" and v.Name ~= "eqp" then
				Tween(v,{Transparency = 1},"Linear","In",.5)
			end
		end
		Tween(shg.shotgun,{Transparency = 1},"Linear","In",.5)
		delay(.5,function()
		eqpweld.Parent = rifle
		uneqpweld.Parent = nil
		seqw.Parent = nil
		suneq.Parent = shg
		for _,v in pairs(rifle:GetChildren()) do
			if v:IsA("BasePart") and v.Name ~= "Hole" and v.Name ~= "uneqp" and v.Name ~= "eqp" then
				Tween(v,{Transparency = 1},"Linear","In",.5)
			end
		end	
		Tween(shg.shotgun,{Transparency = 1},"Linear","In",.5)
				weap = "rifle"
				changin = false
		end)
	end
end


function cs()
	if songid == 0 then
		songid = 1
	elseif song == 1 then
		songid = 2
	end
end

function shoot()
	attack = true
	  	local Time,Easing,Direction = .35,'Quad','Out'
  Tween(rootjoint,{C0 = cf(-0.1,-0.4,0)*angles(rad(0),rad(20.4),rad(0))*rootc0},Easing,Direction,Time)
  Tween(lh,{C0 = cf(-0.5,-0.7,-0.4)*angles(rad(-18.9),rad(6.8),rad(-10.1))},Easing,Direction,Time)
  Tween(rh,{C0 = cf(0.6,-0.6,-0.7)*angles(rad(-7.2),rad(-9.8),rad(3.4))},Easing,Direction,Time)
  Tween(la,{C0 = cf(-0.9,0.1,-0.8)*angles(rad(117.8),rad(5.9),rad(40.5))},Easing,Direction,Time)
  Tween(ra,{C0 = cf(1.4,0.5,-0.7)*angles(rad(93.6),rad(8.2),rad(-23))},Easing,Direction,Time)
  Tween(neck,{C0 = neckc0*cf(0,0,0)*angles(rad(0),rad(0),rad(-20.4))},Easing,Direction,Time)
  Tween(riflejoint,{C0 = cf(-0.3,0,0.1)*angles(rad(-7.6),rad(-46.2),rad(-10.4))},Easing,Direction,Time)
  swait(Time)
	repeat
		MC.hold(true)
		swait(.02)
		sound(1044434118,rifle.Hole,3,random(8,12)/10)
		  	local Time,Easing,Direction = .075,'Linear','Out'
  Tween(rootjoint,{C0 = cf(-0.1,-0.4,0+.15)*angles(rad(0),rad(20.4),rad(0))*rootc0},Easing,Direction,Time)
  Tween(lh,{C0 = cf(-0.5,-0.7,-0.4-.15)*angles(rad(-18.9),rad(6.8),rad(-10.1))},Easing,Direction,Time)
  Tween(rh,{C0 = cf(0.6,-0.6,-0.7-.15)*angles(rad(-7.2),rad(-9.8),rad(3.4))},Easing,Direction,Time)
  Tween(la,{C0 = cf(-0.9,0.1,-0.8+.3)*angles(rad(117.8),rad(5.9),rad(40.5))},Easing,Direction,Time)
  Tween(ra,{C0 = cf(1.4,0.5,-0.7+.3)*angles(rad(93.6),rad(8.2),rad(-23))},Easing,Direction,Time)
  Tween(neck,{C0 = neckc0*cf(0,0,0)*angles(rad(0),rad(0),rad(-20.4))},Easing,Direction,Time)
  Tween(riflejoint,{C0 = cf(-0.3,0,0.1)*angles(rad(-7.6),rad(-46.2),rad(-10.4))},Easing,Direction,Time)
  swait(Time)
local h,p = castray(rifle.Hole.Position,mouse.Hit.p, 500,character)
local di = (p - rifle.Hole.Position).Magnitude
Effect({cf=cf(rifle.Hole.Position,p)*cf(0,0,-di/2),moveto=nil,clr=Color3.new(1,1,0),clr2=Color3.new(.9,.9,0),mtype="Box",waits=10,size=Vector3.new(.05,.05,di),size2=Vector3.new(.1,.1,di),radX=0,radY=0,radZ=0,mat="Neon",lock=false,tran=0,tran2=1})
Effect({cf=rifle.Hole.Position,moveto=nil,clr=Color3.new(1,1,0),clr2=Color3.new(.9,.9,0),mtype="Box",waits=15,size=Vector3.new(.1,.1,.1),size2=Vector3.new(.3,.3,.3),radX=random(-8,8),radY=random(-8,8),radZ=random(-8,8),mat="Neon",lock=false,tran=0,tran2=1})
if h then
	if h.Parent:FindFirstChildOfClass("Humanoid") then
		applydamage(h.Parent:FindFirstChildOfClass("Humanoid"),random(30,35))
		local bl = part(h.Parent,"Granite",0,BrickColor.new("Crimson").Color,vt(.2,.2,.2),false,"ball")
		bl.Position = p
		weldBetween(bl,h)
		Tween(bl,{Transparency = 1},"Linear","In",1)
		debris:AddItem(bl,1.01)
		sound(1565725028,bl,6,random(9,12)/10)
	end
end
	  	local Time,Easing,Direction = .075,'Linear','Out'
  Tween(rootjoint,{C0 = cf(-0.1,-0.4,0)*angles(rad(0),rad(20.4),rad(0))*rootc0},Easing,Direction,Time)
  Tween(lh,{C0 = cf(-0.5,-0.7,-0.4)*angles(rad(-18.9),rad(6.8),rad(-10.1))},Easing,Direction,Time)
  Tween(rh,{C0 = cf(0.6,-0.6,-0.7)*angles(rad(-7.2),rad(-9.8),rad(3.4))},Easing,Direction,Time)
  Tween(la,{C0 = cf(-0.9,0.1,-0.8)*angles(rad(117.8),rad(5.9),rad(40.5))},Easing,Direction,Time)
  Tween(ra,{C0 = cf(1.4,0.5,-0.7)*angles(rad(93.6),rad(8.2),rad(-23))},Easing,Direction,Time)
  Tween(neck,{C0 = neckc0*cf(0,0,0)*angles(rad(0),rad(0),rad(-20.4))},Easing,Direction,Time)
  Tween(riflejoint,{C0 = cf(-0.3,0,0.1)*angles(rad(-7.6),rad(-46.2),rad(-10.4))},Easing,Direction,Time)
  swait(Time)
	until mousehold == false
	MC.hold(false)
	attack = false
end

function shoot2()
	attack = true
	  	local Time,Easing,Direction = .35,'Quad','Out'
  Tween(rootjoint,{C0 = cf(-0.1,-0.4,0)*angles(rad(0),rad(20.4),rad(0))*rootc0},Easing,Direction,Time)
  Tween(lh,{C0 = cf(-0.5,-0.7,-0.4)*angles(rad(-18.9),rad(6.8),rad(-10.1))},Easing,Direction,Time)
  Tween(rh,{C0 = cf(0.6,-0.6,-0.7)*angles(rad(-7.2),rad(-9.8),rad(3.4))},Easing,Direction,Time)
  Tween(la,{C0 = cf(-0.9,0.1,-0.8)*angles(rad(117.8),rad(5.9),rad(40.5))},Easing,Direction,Time)
  Tween(ra,{C0 = cf(1.4,0.5,-0.7)*angles(rad(93.6),rad(8.2),rad(-23))},Easing,Direction,Time)
  Tween(neck,{C0 = neckc0*cf(0,0,0)*angles(rad(0),rad(0),rad(-20.4))},Easing,Direction,Time)
  Tween(shotgunjoint,{C0 = cf(-0.3,0,0.1)*angles(rad(-7.6),rad(-46.2),rad(-10.4))},Easing,Direction,Time)
  swait(Time)
		MC.hold(true)
		sound(2001619675,shg.Hole,3,random(8,12)/10)
		  	local Time,Easing,Direction = .2,'Back','Out'
  Tween(rootjoint,{C0 = cf(-0.1,-0.4,0)*angles(rad(5.9),rad(20.4),rad(0))*rootc0},Easing,Direction,Time)
  Tween(lh,{C0 = cf(-0.6,-0.7,-0.3)*angles(rad(-24.2),rad(7.5),rad(-12.1))},Easing,Direction,Time)
  Tween(rh,{C0 = cf(0.6,-0.7,-0.6)*angles(rad(-13.1),rad(-9.5),rad(1.3))},Easing,Direction,Time)
  Tween(la,{C0 = cf(-1.1,0.1,-0.3)*angles(rad(125.8),rad(8.4),rad(39))},Easing,Direction,Time)
  Tween(ra,{C0 = cf(1.2,0.6,-0.1)*angles(rad(101.5),rad(11.1),rad(-23.4))},Easing,Direction,Time)
  Tween(neck,{C0 = neckc0*cf(0,0,0)*angles(rad(7.7),rad(0),rad(-20.3))},Easing,Direction,Time)
  Tween(shotgunjoint,{C0 = cf(-0.3,0,0.1)*angles(rad(-7.6),rad(-46.2),rad(-10.4))},Easing,Direction,Time)
for i = 1,6 do
local h,p = castray(shg.Hole.Position,mouse.Hit*randompos(1,"cf").p, 500,character)
local di = (p - shg.Hole.Position).Magnitude
local ab
if not h then ab = randompos(12) else ab = vt(0,0,0) end
Effect({cf=cf(shg.Hole.Position,p+ab)*cf(0,0,-di/2),moveto=nil,clr=Color3.new(1,1,0),clr2=Color3.new(.9,.9,0),mtype="Box",waits=10,size=Vector3.new(.05,.05,di),size2=Vector3.new(.1,.1,di),radX=0,radY=0,radZ=0,mat="Neon",lock=false,tran=0,tran2=1})
Effect({cf=shg.Hole.Position,moveto=nil,clr=Color3.new(1,1,0),clr2=Color3.new(.9,.9,0),mtype="Box",waits=15,size=Vector3.new(.1,.1,.1),size2=Vector3.new(.3,.3,.3),radX=random(-8,8),radY=random(-8,8),radZ=random(-8,8),mat="Neon",lock=false,tran=0,tran2=1})
if h then
	if h.Parent:FindFirstChildOfClass("Humanoid") then
		applydamage(h.Parent:FindFirstChildOfClass("Humanoid"),random(20,25))
		local bl = part(h.Parent,"Granite",0,BrickColor.new("Crimson").Color,vt(.2,.2,.2),false,"ball")
		bl.Position = p
		weldBetween(bl,h)
		Tween(bl,{Transparency = 1},"Linear","In",1)
		debris:AddItem(bl,1.01)
		sound(1565725028,bl,6,random(9,12)/10)
	end
end
end
  swait(Time)
	  	local Time,Easing,Direction = .15,'Linear','Out'
  Tween(rootjoint,{C0 = cf(-0.1,-0.4,0)*angles(rad(0),rad(20.4),rad(0))*rootc0},Easing,Direction,Time)
  Tween(lh,{C0 = cf(-0.5,-0.7,-0.4)*angles(rad(-18.9),rad(6.8),rad(-10.1))},Easing,Direction,Time)
  Tween(rh,{C0 = cf(0.6,-0.6,-0.7)*angles(rad(-7.2),rad(-9.8),rad(3.4))},Easing,Direction,Time)
  Tween(la,{C0 = cf(-0.9,0.1,-0.8)*angles(rad(117.8),rad(5.9),rad(40.5))},Easing,Direction,Time)
  Tween(ra,{C0 = cf(1.4,0.5,-0.7)*angles(rad(93.6),rad(8.2),rad(-23))},Easing,Direction,Time)
  Tween(neck,{C0 = neckc0*cf(0,0,0)*angles(rad(0),rad(0),rad(-20.4))},Easing,Direction,Time)
  Tween(shotgunjoint,{C0 = cf(-0.3,0,0.1)*angles(rad(-7.6),rad(-46.2),rad(-10.4))},Easing,Direction,Time)
  swait(Time)
  	local Time,Easing,Direction = .2,'Quad','InOut'
  Tween(rootjoint,{C0 = cf(-0.1,-0.4,-0.1)*angles(rad(6.6),rad(32.4),rad(-1.5))*rootc0},Easing,Direction,Time)
  Tween(lh,{C0 = cf(-0.6,-0.7,-0.3)*angles(rad(-24.2),rad(7.5),rad(-12.1))},Easing,Direction,Time)
  Tween(rh,{C0 = cf(0.6,-0.7,-0.6)*angles(rad(-13.1),rad(-9.5),rad(1.3))},Easing,Direction,Time)
  Tween(la,{C0 = cf(-1.6,0.7,-0.3)*angles(rad(127),rad(-1),rad(-22.6))},Easing,Direction,Time)
  Tween(ra,{C0 = cf(0.9,0.5,-0.9)*angles(rad(105.8),rad(0.4),rad(-53.5))},Easing,Direction,Time)
  Tween(neck,{C0 = neckc0*cf(0.1,0,0)*angles(rad(0.1),rad(0),rad(5.7))},Easing,Direction,Time)
  Tween(shotgunjoint,{C0 = cf(0.3,-0.1,0)*angles(rad(23),rad(42),rad(-18.1))},Easing,Direction,Time)
  swait(Time)
sound(3299747822,shg.Hole,4,1)
  	local Time,Easing,Direction = .2,'Back','Out'
  Tween(rootjoint,{C0 = cf(-0.1,-0.4,0)*angles(rad(6.2),rad(26.8),rad(-0.7))*rootc0},Easing,Direction,Time)
  Tween(lh,{C0 = cf(-0.6,-0.7,-0.3)*angles(rad(-24.2),rad(7.5),rad(-12.1))},Easing,Direction,Time)
  Tween(rh,{C0 = cf(0.6,-0.7,-0.6)*angles(rad(-13.1),rad(-9.5),rad(1.3))},Easing,Direction,Time)
  Tween(la,{C0 = cf(-1.6,0.3,-0.5)*angles(rad(127),rad(-1),rad(19.5))},Easing,Direction,Time)
  Tween(ra,{C0 = cf(0.9,0.5,-0.9)*angles(rad(105.8),rad(0.4),rad(-53.5))},Easing,Direction,Time)
  Tween(neck,{C0 = neckc0*cf(0.1,0,0)*angles(rad(0.4),rad(0),rad(11.4))},Easing,Direction,Time)
  Tween(shotgunjoint,{C0 = cf(0.3,-0.1,0)*angles(rad(23),rad(42),rad(-18.1))},Easing,Direction,Time)
  swait(Time)
	MC.hold(false)
	attack = false
end

function grenade()
	attack = true
	  	local Time,Easing,Direction = .45,'Quad','InOut'
  Tween(rootjoint,{C0 = cf(0,0,0)*angles(rad(0),rad(52.9),rad(0))*rootc0},Easing,Direction,Time)
  Tween(lh,{C0 = cf(-0.5,-1,-0.1)*angles(rad(1.4),rad(5.6),rad(-2.4))},Easing,Direction,Time)
  Tween(rh,{C0 = cf(0.5,-1,-0.2)*angles(rad(-0.9),rad(-9.7),rad(3))},Easing,Direction,Time)
  Tween(la,{C0 = cf(-1.4,0.5,0)*angles(rad(14.2),rad(14.4),rad(1.2))},Easing,Direction,Time)
  Tween(ra,{C0 = cf(1.6,0.5,0)*angles(rad(117.8),rad(25.4),rad(26.7))},Easing,Direction,Time)
  Tween(neck,{C0 = neckc0*cf(0,0,0)*angles(rad(0),rad(0),rad(-52.9))},Easing,Direction,Time)
  swait(Time)
  	local Time,Easing,Direction = .3,'Quad','InOut'
  Tween(rootjoint,{C0 = cf(0,0,0)*angles(rad(0),rad(43),rad(0))*rootc0},Easing,Direction,Time)
  Tween(lh,{C0 = cf(-0.5,-1,-0.1)*angles(rad(1.4),rad(5.6),rad(-2.4))},Easing,Direction,Time)
  Tween(rh,{C0 = cf(0.5,-1,-0.2)*angles(rad(-0.9),rad(-9.7),rad(3))},Easing,Direction,Time)
  Tween(la,{C0 = cf(-1.4,0.7,0.1)*angles(rad(-162.6),rad(-15),rad(-10.9))},Easing,Direction,Time)
  Tween(ra,{C0 = cf(1.2,0.8,0.5)*angles(rad(-103.3),rad(0.5),rad(-36.2))},Easing,Direction,Time)
  Tween(neck,{C0 = neckc0*cf(0,0,0)*angles(rad(0),rad(0),rad(-43))},Easing,Direction,Time)
local gren2 = gren:Clone()
gren2.Anchored = false
gren2.Parent = effects
gren2.CFrame = leftarm.CFrame
local grenw = weld(gren2,gren2,leftarm,d*angles(rad(90),0,0)*cf(0,1,0),d)
  swait(Time)
  	local Time,Easing,Direction = .3,'Quint','Out'
  Tween(rootjoint,{C0 = cf(0,0,0)*angles(rad(-9.2),rad(-18.5),rad(0))*rootc0},Easing,Direction,Time)
  Tween(lh,{C0 = cf(-0.6,-0.9,-0.4)*angles(rad(11.4),rad(15.8),rad(-5.5))},Easing,Direction,Time)
  Tween(rh,{C0 = cf(0.4,-1,-0.2)*angles(rad(7.4),rad(-9.8),rad(0))},Easing,Direction,Time)
  Tween(la,{C0 = cf(-0.4,0.5,-1.2)*angles(rad(37.1),rad(8.9),rad(61.6))},Easing,Direction,Time)
  Tween(ra,{C0 = cf(1.2,0.8,0.5)*angles(rad(-103.3),rad(0.5),rad(-36.2))},Easing,Direction,Time)
  Tween(neck,{C0 = neckc0*cf(-0,0,-0)*angles(rad(-7.9),rad(0),rad(18.4))},Easing,Direction,Time)
local proj = gren:Clone()
sound(4847394559,leftarm,4,1)
proj.Anchored = false
proj.Parent = effects
proj.Position = gren2.Position
proj.CFrame = cf(proj.Position,mouse.Hit.p)*cf(0,0,-4)
gren2:Destroy()
proj.Velocity = proj.CFrame.lookVector*125
proj.CanCollide = true
delay(1,function()
aoe(proj.Position,20,0,0,200,true)
local s = sound(2814354338,proj,2,1)
s.PlayOnRemove = true
Effect({cf=proj.Position,moveto=nil,clr=Color3.fromRGB(255,150,0),clr2=Color3.fromRGB(255,100,0),mtype="S",waits=60/1.5,size=Vector3.new(1,1,1),size2=Vector3.new(40,40,40),radX=0,radY=0,radZ=0,mat="Neon",lock=false,tran=0,tran2=1})
Effect({cf=proj.Position,moveto=nil,clr=Color3.fromRGB(255,100,0),clr2=Color3.fromRGB(255,150,0),mtype="S",waits=60/1.5,size=Vector3.new(1,1,1),size2=Vector3.new(30,30,30),radX=0,radY=0,radZ=0,mat="Neon",lock=false,tran=0,tran2=1})
for i = 1,3 do
Effect({cf=proj.CFrame*randomangle(),moveto=nil,clr=Color3.new(1,1,1),clr2=Color3.new(1,1,1),mtype="Wave",waits=75/1.5,size=Vector3.new(1,.1,3),size2=Vector3.new(45,.2,45),radX=0,radY=random(-4,4),radZ=0,mat="Neon",lock=false,tran=0,tran2=1})
end
proj:Destroy()	
end)
  swait(Time)

attack = false
end

run = false

function trip()
	attack = true
	Swait()
	local Time,Easing,Direction = .3,'Quart','Out'
  Tween(rootjoint,{C0 = cf(0,-0.3,0.1)*angles(rad(-12.9),rad(73.3),rad(0))*rootc0},Easing,Direction,Time)
  Tween(lh,{C0 = cf(-0.5,-0.8,-0.1)*angles(rad(3.8),rad(6.1),rad(3.9))},Easing,Direction,Time)
  Tween(rh,{C0 = cf(0.5,-0.8,-0.4)*angles(rad(-12),rad(8.2),rad(57.6))},Easing,Direction,Time)
  Tween(la,{C0 = cf(-1.5,0.5,0.1)*angles(rad(7.5),rad(17.6),rad(-21.2))},Easing,Direction,Time)
  Tween(ra,{C0 = cf(0.9,0.5,-0.9)*angles(rad(93.5),rad(7.9),rad(-58.5))},Easing,Direction,Time)
  Tween(neck,{C0 = neckc0*cf(0,0,0)*angles(rad(0),rad(0),rad(-73.3))},Easing,Direction,Time)
	MC.push(rootpart.CFrame.lookVector*235)
	aoe(rightleg.Position,3,10,17,0,false,true)
  swait(Time)
aoe(rightleg.Position,7,10,17,0,false,true)
	attack = false
end

mouse.Button1Down:Connect(function()
	mousehold = true
	if attack == false and weap == "rifle" and not changin then
		shoot()
	elseif not attack and weap == "shotgun" and not changin then
		shoot2()
	end
end)

mouse.Button1Up:Connect(function()
	mousehold = false
end)

mouse.KeyDown:Connect(function(k)
	keyhold = true
	if k == "z" and attack == false then
		grenade()
	end
	
	if k == "x" and attack == false then
		trip()
	end
	if k == "c" and attack == false then
		
	end
	
	if k == "v" and attack == false then
		
	end
	
	if k == "b" and attack == false then
		
	end
	
	if k == "2" and run == false then run = true elseif k == "2" and run == true then run = false end
	
	if k == "q" and not attack and not changin then
		switch()
	end
	
	if k == "m" and attack == false then cs() end
end)

mouse.KeyUp:Connect(function(k)
	keyhold = false
end)

while MC.alive() do
	Swait()
	sine = sine + change
	local torsoverticalvel = MC.vel().Y
	local torsovel = (MC.vel() * vt(1, 0, 1)).Magnitude
	local hitfloor = MC.ground()
	local speedval = 10/(humanoid.WalkSpeed/16)
	local Walking = MC.moveDir().magnitude>0
	local FwdDir = (Walking and MC.moveDir()*rootpart.CFrame.lookVector or vt())
	local RigDir = (Walking and MC.moveDir()*rootpart.CFrame.rightVector or vt())
	local Vec = {
		X=RigDir.X+RigDir.Z,
		Z=FwdDir.X+FwdDir.Z
	};
	local Divide = 1
	if(Vec.Z<0)then
		Divide=math.clamp(-(1.25*Vec.Z),1,2)
	end
	Vec.Z = Vec.Z/Divide
	Vec.X = Vec.X/Divide
	if torsoverticalvel > 1 and not hitfloor then
		anim = "jump"
		if attack == false then
		local Alpha = .2
  		rootjoint.C0 = rootjoint.C0:lerp(cf(0,0,0)*angles(rad(15.2),rad(0),rad(0))*rootc0,Alpha)
  		lh.C0 = lh.C0:lerp(cf(-0.5,-1.1,0)*angles(rad(-21),rad(0),rad(0)),Alpha)
 		rh.C0 = rh.C0:lerp(cf(0.5,-0.4,-1)*angles(rad(-18.6),rad(0),rad(0)),Alpha)
  		la.C0 = la.C0:lerp(cf(-1.5,0.5,0.2)*angles(rad(-9.7),rad(8.3),rad(-8.1)),Alpha)
  		ra.C0 = ra.C0:lerp(cf(1.5,0.5,0.2)*angles(rad(-9.7),rad(-8.3),rad(8.1)),Alpha)
  		neck.C0 = neck.C0:lerp(neckc0*cf(0,0,0)*angles(rad(-9.6),rad(0),rad(0)),Alpha)
		end
	elseif torsoverticalvel < -1 and not hitfloor then
		anim = "fall"
		local Alpha = .2
		if attack == false then
 		rootjoint.C0 = rootjoint.C0:lerp(cf(0,0,-0)*angles(rad(-16.1),rad(0),rad(0))*rootc0,Alpha)
  		lh.C0 = lh.C0:lerp(cf(-0.5,-1,-0.3)*angles(rad(-12.5),rad(0),rad(0)),Alpha)
  		rh.C0 = rh.C0:lerp(cf(0.5,-0.2,-1.1)*angles(rad(-16),rad(0),rad(0)),Alpha)
		la.C0 = la.C0:lerp(cf(-1.6,0.1+.085*sin(sine/35),-0.4)*angles(rad(72.3),rad(1.5),rad(-18.9)),Alpha)
  		ra.C0 = ra.C0:lerp(cf(1.3,0.4+.085*sin(sine/35),-0.9)*angles(rad(71.8),rad(14.3),rad(-66.2)),Alpha)
  		neck.C0 = neck.C0:lerp(neckc0*cf(0,0,0)*angles(rad(-5),rad(0),rad(0)),Alpha)
		end
	elseif torsovel < 1 and hitfloor then
		anim = "idle"
		local Alpha = .1
		if attack == false then
 		rootjoint.C0 = rootjoint.C0:lerp(cf(0,0+.07*cos(sine/27),0)*angles(rad(0),rad(45.5+1*cos(sine/(27*2))),rad(0))*rootc0,Alpha)
  		lh.C0 = lh.C0:lerp(cf(-0.5,-1-.07*cos(sine/27),-0.1)*angles(rad(1.4),rad(5.6-1*cos(sine/(27*2))),rad(-2.4)),Alpha)
 		rh.C0 = rh.C0:lerp(cf(0.5,-1-.07*cos(sine/27),-0.2)*angles(rad(-0.9),rad(-9.7-1*cos(sine/(27*2))),rad(3)),Alpha)
  		la.C0 = la.C0:lerp(cf(-1.3,0.1+.085*sin(sine/27),-0.4)*angles(rad(75.1),rad(28.8),rad(-25.2)),Alpha)
  		ra.C0 = ra.C0:lerp(cf(1.1,0.3+.085*sin(sine/27),-0.8)*angles(rad(95.2),rad(17.7),rad(-57.2)),Alpha)
 		neck.C0 = neck.C0:lerp(neckc0*cf(0,0,0)*angles(rad(2.75*sin(sine/27)),rad(-3*cos(sine/(27*2))),rad(-45.5)),Alpha)
		end
	elseif torsovel > 1 and torsovel < 22 and hitfloor then
		anim = "walk"
		local Alpha = .1
		rootjoint.C0 = rootjoint.C0:lerp(cf(0,.14-.07*cos(sine/speedval*2),0)*angles(rad(-15*Vec.Z),rad(5*cos(sine/speedval)),rad(-12.5*Vec.X))*rootc0,Alpha)
  		lh.C0 = lh.C0:lerp(cf(-0.5,-1+.18*sin(sine/speedval),-.1+.12*sin(sine/speedval)*Vec.Z)*angles(rad(-40*cos(sine/speedval)*Vec.Z),rad(2*cos(sine/speedval)),rad(-20*cos(sine/speedval)*Vec.X)),Alpha)
  		rh.C0 = rh.C0:lerp(cf(0.5,-1-.18*sin(sine/speedval),-.1-.12*sin(sine/speedval)*Vec.Z)*angles(rad(40*cos(sine/speedval)*Vec.Z),rad(-2*cos(sine/speedval)),rad(20*cos(sine/speedval)*Vec.X)),Alpha)
   		neck.C0 = neck.C0:lerp(neckc0*cf(0,0,0)*angles(rad(-2),rad(0),rad(-5*cos(sine/speedval)-26*Vec.X)),Alpha)
		la.C0 = la.C0:lerp(cf(-1.3,0.1,-0.4)*angles(rad(75.1),rad(28.8),rad(-25.2)),Alpha)
  		ra.C0 = ra.C0:lerp(cf(1.1,0.3,-0.8)*angles(rad(95.2),rad(17.7),rad(-57.2)),Alpha)
	elseif torsovel >= 22 and hitfloor then
		anim = "run"
		runval = 6
		local Alpha = .1
		rootjoint.C0 = rootjoint.C0:lerp(cf(0,.2-.15*cos(sine/runval*2),0)*angles(rad(-15*Vec.Z),rad(5*sin(sine/runval)),rad(-12.5*Vec.X))*rootc0,Alpha)
  		lh.C0 = lh.C0:lerp(cf(-0.5,-1+.45*sin(sine/runval),-.1+.2*sin(sine/runval)*Vec.Z)*angles(rad(-60*cos(sine/runval)*Vec.Z),rad(4*cos(sine/runval)),rad(-40*cos(sine/runval)*Vec.X)),Alpha)
  		rh.C0 = rh.C0:lerp(cf(0.5,-1-.45*sin(sine/runval),-.1-.2*sin(sine/runval)*Vec.Z)*angles(rad(60*cos(sine/runval)*Vec.Z),rad(-4*cos(sine/runval)),rad(40*cos(sine/runval)*Vec.X)),Alpha)
  		la.C0 = la.C0:lerp(cf(-1.3,0.1,-0.4)*angles(rad(75.1),rad(28.8),rad(-25.2)),Alpha)
  		ra.C0 = ra.C0:lerp(cf(1.1,0.3,-0.8)*angles(rad(95.2),rad(17.7),rad(-57.2)),Alpha)
  		neck.C0 = neck.C0:lerp(neckc0*cf(0,0,0)*angles(rad(0),rad(0),rad(-5*sin(sine/runval)-26*Vec.X)),Alpha)
	end
	if attack == false and weap == "rifle" then
		riflejoint.C0 = riflejoint.C0:lerp(cf(0,0,0)*angles(rad(0.3),rad(25.4),rad(-3.7)),.1)
		shotgunjoint.C0 = shotgunjoint.C0:lerp(d,.1)
	elseif not attack and weap == "shotgun" then
		riflejoint.C0 = riflejoint.C0:lerp(d,.1)
		shotgunjoint.C0 = shotgunjoint.C0:lerp(cf(0,0,0)*angles(rad(0.3),rad(25.4),rad(-3.7)),.1)
	end
	if run == false then
		speed = 16
	elseif run == true then
		speed = 35
	end
	song.SoundId,song.Looped,song.Pitch,song.Volume,song.Playing = "rbxassetid://"..songid,true,1,3,true
	humanoid.Health,humanoid.MaxHealth,humanoid.WalkSpeed = 9e9,9e9,speed
end

