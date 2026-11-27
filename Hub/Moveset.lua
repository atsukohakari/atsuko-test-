local Kit = { version = 1 }

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local Debris = game:GetService("Debris")

local V3, CF, ANG = Vector3.new, CFrame.new, CFrame.Angles
local CFI = CFrame.identity
local sin, cos, exp, abs, pi = math.sin, math.cos, math.exp, math.abs, math.pi
local min, max, clamp, rad = math.min, math.max, math.clamp, math.rad

Kit.CDN = "https://raw.githubusercontent.com/STEVE-916-create/Uhhhhhh/main/"
Kit.ROOT = "UhhhhhhReanim/Content/Sounds/"
Kit.JOINTS = { root = "RootJoint", neck = "Neck", rarm = "Right Shoulder", larm = "Left Shoulder", rleg = "Right Hip", lleg = "Left Hip" }
Kit.LIMBS = { rarm = "Right Arm", larm = "Left Arm", rleg = "Right Leg", lleg = "Left Leg", neck = "Head", root = "Torso" }
Kit.PIVOT = {
	root = { V3(0, -1, 0), V3(0, 1, 0) },
	neck = { V3(0, 1, 0), V3(0, 0.5, 0) },
	rarm = { V3(1.5, 0.5, 0), V3(0, -0.5, 0) },
	larm = { V3(-1.5, 0.5, 0), V3(0, -0.5, 0) },
	rleg = { V3(0.5, -1, 0), V3(0, -1, 0) },
	lleg = { V3(-0.5, -1, 0), V3(0, -1, 0) },
}
Kit.SIDE = { rarm = 1, rleg = 1, larm = -1, lleg = -1, root = 1, neck = 1 }

function Kit.rot(name, fwd, out, twist)
	local s = Kit.SIDE[name] or 1
	return ANG(fwd or 0, (twist or 0) * s, (out or 0) * s)
end

function Kit.pose(name, fwd, out, twist, nudge)
	local p = Kit.PIVOT[name]
	local cf = CF(p[1]) * Kit.rot(name, fwd, out, twist) * CF(p[2])
	if nudge then
		cf = CF(nudge) * cf
	end
	return cf
end

function Kit.aimRot(dir, roll)
	local d = dir.Unit
	local down = V3(0, -1, 0)
	local axis = down:Cross(d)
	local sn = axis.Magnitude
	local cs = down:Dot(d)
	local R
	if sn < 1e-6 then
		R = cs > 0 and CFI or ANG(pi, 0, 0)
	else
		R = CFrame.fromAxisAngle(axis / sn, math.atan2(sn, cs))
	end
	if roll and roll ~= 0 then
		R = R * ANG(0, roll, 0)
	end
	return R
end

function Kit.reach(name, dir, roll)
	local p = Kit.PIVOT[name]
	return CF(p[1]) * Kit.aimRot(dir, roll) * CF(p[2])
end

function Kit.rest()
	local out = {}
	for name in pairs(Kit.JOINTS) do
		out[name] = Kit.pose(name, 0, 0, 0)
	end
	return out
end

function Kit.fit(size)
	if typeof(size) ~= "Vector3" then
		return CFI, 1
	end
	local list = { { 1, size.X }, { 2, size.Y }, { 3, size.Z } }
	table.sort(list, function(a, b)
		return a[2] > b[2]
	end)
	local cols = { V3(), V3(), V3() }
	cols[list[1][1]] = V3(0, 0, 1)
	cols[list[2][1]] = V3(0, 1, 0)
	cols[list[3][1]] = V3(1, 0, 0)
	if cols[1]:Cross(cols[2]):Dot(cols[3]) < 0 then
		cols[list[3][1]] = V3(-1, 0, 0)
	end
	return CFrame.fromMatrix(V3(), cols[1], cols[2], cols[3]), list[1][2]
end

function Kit.digits(v)
	if type(v) ~= "string" then
		v = v ~= nil and tostring(v) or ""
	end
	return string.match(v, "(%d+)%D*$")
end

function Kit.toward(cur, goal, rate, dt)
	return cur + (goal - cur) * (1 - exp(-rate * dt))
end

function Kit.ease(t)
	t = clamp(t, 0, 1)
	return t * t * (3 - 2 * t)
end

local function genvOf()
	return (typeof(getgenv) == "function" and getgenv()) or _G
end

local function hubRead(genv, path)
	local base = type(genv.AtsukoHubRaw) == "string" and genv.AtsukoHubRaw or "https://raw.githubusercontent.com/atsukohakari/atsuko-test-/main/"
	local ok, src = pcall(function()
		if type(genv.AtsukoHubRead) == "function" then
			local got = genv.AtsukoHubRead(path)
			if got or genv.AtsukoHubLocal then
				return got
			end
		end
		return game:HttpGet(base .. path)
	end)
	return ok and type(src) == "string" and src or nil
end

function Kit.lib(path, key, need)
	local genv = genvOf()
	local have = genv[key]
	if type(have) == "table" and (tonumber(have.version) or 0) >= (need or 0) then
		return have
	end
	local src = hubRead(genv, path)
	local fn = src and loadstring(src, "=" .. key)
	if fn then
		local ok, r = pcall(fn)
		if ok and type(r) == "table" then
			genv[key] = r
			return r
		end
	end
	return nil
end

local function httpBody(url)
	local req = (syn and syn.request) or (http and http.request) or http_request or request
	if type(req) == "function" then
		local ok, res = pcall(req, { Url = url, Method = "GET" })
		if ok and type(res) == "table" and res.StatusCode == 200 and type(res.Body) == "string" then
			return res.Body
		end
	end
	local ok, body = pcall(function()
		return game:HttpGet(url)
	end)
	if ok and type(body) == "string" and #body > 0 then
		return body
	end
	return nil
end

function Kit.asset(file)
	if not (writefile and isfile and getcustomasset) then
		return nil, "your executor can't play files"
	end
	local path = Kit.ROOT .. file
	local okH, has = pcall(isfile, path)
	if not (okH and has) then
		local body = httpBody(Kit.CDN .. "content/" .. file)
		if not body then
			return nil, "couldn't download " .. file
		end
		local at = ""
		for part in path:gmatch("([^/]+)/") do
			at = at .. part
			pcall(function()
				if not isfolder(at) then
					makefolder(at)
				end
			end)
			at = at .. "/"
		end
		if not pcall(writefile, path, body) then
			return nil, "couldn't save " .. file
		end
	end
	local ok, id = pcall(getcustomasset, path)
	if ok and type(id) == "string" and id ~= "" then
		return id
	end
	return nil, "couldn't load " .. file
end

function Kit.start(cfg)
	cfg = type(cfg) == "table" and cfg or {}
	local genv = genvOf()
	local TITLE = tostring(cfg.title or "Moveset")
	local K = { title = TITLE, genv = genv, rate = cfg.rate or 14, conns = {}, stops = {} }

	function K.say(text, kind, secs)
		local h = genv.AtsukoHub
		if type(h) == "table" and type(h.Notify) == "function" and pcall(h.Notify, TITLE, text, kind or "info", secs or 3) then
			return
		end
		local f = genv.AtsukoNotify
		if type(f) == "function" and pcall(f, TITLE, text, kind or "info", secs or 3) then
			return
		end
		warn("[" .. TITLE .. "] " .. tostring(text))
	end

	local hubFd = genv.AtsukoHatFd
	local onHub = type(hubFd) == "table" and type(hubFd.reanimate) == "function" and type(hubFd.stopreanimate) == "function"
	local Lumen = nil
	if not onHub then
		Lumen = Kit.lib("Hub/Reanimate.lua", "LumenReanim", 10)
		if not (Lumen and type(Lumen.rig) == "function") then
			K.say("Pick a reanimation on the Hat tab first", "error", 5)
			return nil
		end
	end
	if onHub then
		genv.AtsukoScriptAligns = cfg.aligns
	end
	local rig = onHub and hubFd or Lumen.rig({ aligns = cfg.aligns or {} })
	local okFd, fd = pcall(rig.reanimate)
	if not okFd or type(fd) ~= "table" or type(fd.cframes) ~= "table" or type(fd.getJoint) ~= "function" or type(fd.addmode) ~= "function" then
		K.say("Couldn't reanimate: " .. tostring(okFd and "the reanimation gave no body" or fd), "error", 6)
		return nil
	end
	local live = (not onHub) and Lumen.current() or nil
	local function reanimOn()
		if onHub then
			local ok, isOn = pcall(hubFd.isReanimated)
			return ok and isOn and true or false
		end
		return live ~= nil and Lumen.current() == live
	end
	local deadline = os.clock() + 10
	while reanimOn() and live and type(live.isReady) == "function" and not live.isReady() and os.clock() < deadline do
		task.wait()
	end
	if not reanimOn() then
		K.say("The reanimation stopped", "error", 4)
		return nil
	end
	K.fd, K.rig, K.onHub, K.reanimOn = fd, rig, onHub, reanimOn

	local J, REST = {}, {}
	for key, name in pairs(Kit.JOINTS) do
		local j = fd.getJoint(name)
		if type(j) == "table" and typeof(j.C0) == "CFrame" then
			J[key] = j
			REST[key] = { C0 = j.C0, C1 = typeof(j.C1) == "CFrame" and j.C1 or CFI }
		end
	end
	K.J, K.REST = J, REST
	K.cur, K.goal = Kit.rest(), Kit.rest()
	K.rates = {}

	function K.part(name)
		local ok, p = pcall(fd.getPart, name)
		return ok and p or nil
	end
	function K.cf(name)
		local p = K.part(name)
		local c = p and fd.cframes[p]
		return typeof(c) == "CFrame" and c or nil
	end
	function K.rootCF()
		return K.cf("HumanoidRootPart") or K.cf("Torso") or CFI
	end
	function K.vel()
		if type(fd.getVel) ~= "function" then
			return V3()
		end
		local ok, v = pcall(fd.getVel)
		return ok and typeof(v) == "Vector3" and v or V3()
	end
	function K.walkSpeed(n)
		if type(fd.setWalkSpeed) == "function" then
			pcall(fd.setWalkSpeed, n)
		end
	end
	function K.face(target)
		local root = K.rootCF()
		local flat = V3(target.X, root.Position.Y, target.Z)
		if (flat - root.Position).Magnitude < 0.05 or type(fd.setCfr) ~= "function" then
			return
		end
		pcall(fd.setCfr, CFrame.lookAt(root.Position, flat))
	end
	function K.dancing()
		local E = genv.AtsukoEmotes
		if type(E) == "table" and type(E.playing) == "function" then
			local ok, name = pcall(E.playing)
			return ok and name ~= nil
		end
		return false
	end

	function K.set(name, cf)
		K.goal[name] = cf
	end
	function K.limb(name, fwd, out, twist, nudge)
		K.goal[name] = Kit.pose(name, fwd, out, twist, nudge)
	end
	function K.reachTo(name, point, roll)
		local root = K.goal.root
		local pivot = root * Kit.PIVOT[name][1]
		local dir = root:VectorToObjectSpace(point - pivot)
		if dir.Magnitude > 1e-3 then
			K.goal[name] = Kit.reach(name, dir, roll)
		end
	end
	function K.apply(dt)
		for name, j in pairs(J) do
			local rate = K.rates[name] or K.rate
			K.cur[name] = K.cur[name]:Lerp(K.goal[name], 1 - exp(-rate * dt))
			j.C0 = K.cur[name] * REST[name].C1
		end
	end
	function K.snap()
		for name in pairs(J) do
			K.cur[name] = K.goal[name]
		end
	end

	local fxFolder = Instance.new("Folder")
	fxFolder.Name = "AtsukoMoveset"
	fxFolder.Parent = workspace
	K.fxFolder = fxFolder
	pcall(function()
		genv.AtsukoFx = type(genv.AtsukoFx) == "table" and genv.AtsukoFx or {}
		genv.AtsukoFx[fxFolder] = true
	end)
	local mouse = nil
	pcall(function()
		mouse = Players.LocalPlayer:GetMouse()
	end)
	local rp = RaycastParams.new()
	rp.FilterType = Enum.RaycastFilterType.Exclude
	rp.IgnoreWater = true
	function K.ray(origin, dir, solid)
		local skip = { fxFolder }
		local ch = Players.LocalPlayer.Character
		if ch then
			skip[#skip + 1] = ch
		end
		local list = cfg.ignore and cfg.ignore() or nil
		for _, o in ipairs(list or {}) do
			skip[#skip + 1] = o
		end
		rp.FilterDescendantsInstances = skip
		rp.RespectCanCollide = solid == true
		local ok, hit = pcall(workspace.Raycast, workspace, origin, dir, rp)
		return ok and hit or nil
	end
	function K.mouseHit(range)
		range = range or 2000
		local ray = nil
		pcall(function()
			ray = mouse.UnitRay
		end)
		if not ray then
			local root = K.rootCF()
			ray = Ray.new(root.Position, root.LookVector)
		end
		local hit = K.ray(ray.Origin, ray.Direction * range)
		if hit then
			return hit.Position, hit.Instance
		end
		return ray.Origin + ray.Direction * range, nil
	end
	function K.ground(pos, depth)
		local hit = K.ray(pos, V3(0, -(depth or 50), 0), true)
		return hit and hit.Position or nil
	end

	K.sounds = cfg.sounds ~= false
	function K.sound(id, at, vol, pitch)
		if not K.sounds then
			return nil
		end
		local s = Instance.new("Sound")
		local text = tostring(id)
		s.SoundId = string.find(text, "://", 1, true) and text or ("rbxassetid://" .. text)
		s.Volume = vol or 1
		s.PlaybackSpeed = pitch or 1
		local holder = at
		if typeof(at) ~= "Instance" then
			holder = Instance.new("Part")
			holder.Anchored, holder.CanCollide, holder.CanQuery, holder.CanTouch, holder.Transparency = true, false, false, false, 1
			holder.Size = V3(0.1, 0.1, 0.1)
			holder.CFrame = CF(typeof(at) == "Vector3" and at or K.rootCF().Position)
			holder.Parent = fxFolder
			Debris:AddItem(holder, 8)
		end
		s.Parent = holder
		s:Play()
		s.Ended:Connect(function()
			s:Destroy()
		end)
		Debris:AddItem(s, 10)
		return s
	end

	local ear = nil
	function K.loop(id, vol, pitch)
		if not ear then
			ear = Instance.new("Part")
			ear.Anchored, ear.CanCollide, ear.CanQuery, ear.CanTouch, ear.Transparency = true, false, false, false, 1
			ear.Size = V3(0.1, 0.1, 0.1)
			ear.CFrame = K.rootCF()
			ear.Parent = fxFolder
		end
		local s = Instance.new("Sound")
		local text = tostring(id)
		s.SoundId = string.find(text, "://", 1, true) and text or ("rbxassetid://" .. text)
		s.Volume = vol or 1
		s.PlaybackSpeed = pitch or 1
		s.Looped = true
		s.Parent = ear
		return s
	end

	function K.part3(cf, size, color, mat, transp)
		local p = Instance.new("Part")
		p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = true, false, false, false, false
		p.Material = mat or Enum.Material.Neon
		p.Color = color or Color3.new(1, 1, 1)
		p.Transparency = transp or 0
		p.Size = size
		p.CFrame = cf
		p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
		p.Parent = fxFolder
		return p
	end
	local fades = {}
	function K.fx(o)
		local shape = o.shape or "ball"
		local p = K.part3(o.cf, V3(0.2, 0.2, 0.2), o.color, o.mat, o.from or 0)
		local m = Instance.new("SpecialMesh")
		if shape == "ring" then
			m.MeshType = Enum.MeshType.FileMesh
			m.MeshId = "rbxassetid://3270017"
		elseif shape == "block" then
			m.MeshType = Enum.MeshType.Brick
		elseif shape == "spike" then
			m.MeshType = Enum.MeshType.FileMesh
			m.MeshId = "rbxassetid://1033714"
		else
			m.MeshType = Enum.MeshType.Sphere
		end
		m.Scale = o.size or V3(1, 1, 1)
		m.Parent = p
		fades[#fades + 1] = { p = p, m = m, t = 0, time = o.time or 0.4, s0 = o.size or V3(1, 1, 1), s1 = o.size2 or o.size or V3(1, 1, 1), a0 = o.from or 0, a1 = o.to or 1, cf = o.cf, move = o.move, spin = o.spin }
		return p
	end
	function K.line(a, b, color, width, time)
		local d = (b - a).Magnitude
		if d < 1e-3 then
			return
		end
		K.fx({ shape = "block", cf = CFrame.lookAt(a:Lerp(b, 0.5), b), size = V3(width or 0.15, width or 0.15, d), size2 = V3((width or 0.15) * 3, (width or 0.15) * 3, d), color = color, time = time or 0.15 })
	end
	local function tickFx(dt)
		for i = #fades, 1, -1 do
			local f = fades[i]
			f.t = f.t + dt
			local k = clamp(f.t / f.time, 0, 1)
			if k >= 1 or not f.p.Parent then
				pcall(function()
					f.p:Destroy()
				end)
				table.remove(fades, i)
			else
				f.m.Scale = f.s0:Lerp(f.s1, k)
				f.p.Transparency = f.a0 + (f.a1 - f.a0) * k
				if f.move or f.spin then
					f.cf = (f.move and (f.cf + f.move * dt) or f.cf) * (f.spin and ANG(f.spin.X * dt, f.spin.Y * dt, f.spin.Z * dt) or CFI)
					f.p.CFrame = f.cf
				end
			end
		end
	end

	function K.fling(target)
		if typeof(target) ~= "Instance" or type(fd.fling) ~= "function" then
			return false
		end
		local model = target:FindFirstAncestorOfClass("Model")
		local hum = model and model:FindFirstChildOfClass("Humanoid")
		if not hum or model == Players.LocalPlayer.Character then
			return false
		end
		local root = hum.RootPart or model:FindFirstChild("HumanoidRootPart")
		if not root then
			return false
		end
		local ok, r = pcall(fd.fling, root)
		return ok and r ~= false
	end
	function K.hitbox(cf, size)
		local list = {}
		local ok, parts = pcall(function()
			local op = OverlapParams.new()
			op.FilterType = Enum.RaycastFilterType.Exclude
			local skip = { fxFolder }
			local ch = Players.LocalPlayer.Character
			if ch then
				skip[#skip + 1] = ch
			end
			op.FilterDescendantsInstances = skip
			return workspace:GetPartBoundsInBox(cf, size, op)
		end)
		local seen = {}
		for _, p in ipairs(ok and parts or {}) do
			local model = p:FindFirstAncestorOfClass("Model")
			if model and not seen[model] and model:FindFirstChildOfClass("Humanoid") then
				seen[model] = true
				list[#list + 1] = model
			end
		end
		return list
	end

	local shots = {}
	function K.projectile(o)
		o.t = 0
		shots[#shots + 1] = o
		return o
	end
	local function tickShots(dt)
		for i = #shots, 1, -1 do
			local o = shots[i]
			o.t = o.t + dt
			local done = o.dead or o.t >= (o.life or 5)
			if not done then
				o.vel = o.vel - V3(0, (o.gravity or 0) * dt, 0)
				local move = o.vel * dt
				local r = o.radius or 0.5
				local cast = move.Magnitude > 1e-4 and K.ray(o.pos, move + move.Unit * r) or nil
				if cast then
					local stop = o.hit and o.hit(cast, o)
					if stop or not o.bounce or (o.bounces or 0) >= (o.maxBounces or 6) then
						o.pos = cast.Position
						done = true
					else
						local n = cast.Normal
						o.vel = (o.vel - 2 * o.vel:Dot(n) * n) * o.bounce
						o.pos = cast.Position + n * r
						o.bounces = (o.bounces or 0) + 1
						if o.onBounce then
							pcall(o.onBounce, o, cast)
						end
					end
				else
					o.pos = o.pos + move
				end
				if o.part then
					local look = o.vel.Magnitude > 1e-3 and o.vel or V3(0, 0, -1)
					o.part.CFrame = CFrame.lookAt(o.pos, o.pos + look) * (o.spin and ANG(0, 0, o.t * o.spin) or CFI)
				end
				if o.step then
					pcall(o.step, o, dt)
				end
			end
			if done then
				table.remove(shots, i)
				if o.done then
					pcall(o.done, o)
				end
				if o.part and not o.keep then
					pcall(function()
						o.part:Destroy()
					end)
				end
			end
		end
	end
	function K.lob(from, target, speed, gravity)
		local aim = target - from
		local xz = V3(aim.X, 0, aim.Z)
		local x, y = xz.Magnitude, aim.Y
		if x < 1e-3 then
			return V3(0, speed, 0)
		end
		local v2 = speed * speed
		local root = v2 * v2 - gravity * (gravity * x * x + 2 * y * v2)
		local angle = rad(45)
		if root > 0 then
			angle = min(math.atan((v2 - math.sqrt(root)) / (gravity * x)), rad(45))
		end
		return (V3(0, sin(angle), 0) + xz.Unit * cos(angle)) * speed
	end
	function K.explode(pos, radius, color)
		color = color or Color3.fromRGB(255, 170, 70)
		K.fx({ cf = CF(pos), size = V3(1, 1, 1) * radius * 0.4, size2 = V3(1, 1, 1) * radius * 2.2, color = color, time = 0.45 })
		K.fx({ cf = CF(pos), size = V3(1, 1, 1) * radius * 1.4, size2 = V3(1, 1, 1) * radius * 0.2, color = Color3.fromRGB(255, 240, 200), time = 0.3 })
		K.fx({ shape = "ring", cf = CF(pos) * ANG(pi / 2, 0, 0), size = V3(radius, radius, 1), size2 = V3(radius * 5, radius * 5, 0.2), color = color, time = 0.5 })
		for _ = 1, 6 do
			local d = ANG(math.random() * 6.3, math.random() * 6.3, 0).LookVector
			K.fx({ cf = CFrame.lookAt(pos, pos + d), size = V3(0.6, 0.6, radius), size2 = V3(0.1, 0.1, radius * 2.5), color = color, time = 0.35, move = d * radius * 3 })
		end
		K.sound(169628396, pos, 1, 0.9 + math.random() * 0.2)
		for _, model in ipairs(K.hitbox(CF(pos), V3(1, 1, 1) * radius * 2)) do
			K.fling(model:FindFirstChildWhichIsA("BasePart"))
		end
	end
	local cools = {}
	function K.ready(name, secs)
		local now = os.clock()
		if (cools[name] or 0) > now then
			return false
		end
		cools[name] = now + (secs or 0)
		return true
	end
	K.act = nil
	function K.doing(name, dur, events)
		K.act = { name = name, t0 = os.clock(), dur = dur, events = events or {}, fired = {} }
		return K.act
	end
	function K.progress()
		local a = K.act
		if not a then
			return nil, 0
		end
		return a.name, clamp((os.clock() - a.t0) / a.dur, 0, 1)
	end
	local function tickAct()
		local a = K.act
		if not a then
			return
		end
		local p = clamp((os.clock() - a.t0) / a.dur, 0, 1)
		for i, ev in ipairs(a.events) do
			if not a.fired[i] and p >= ev[1] then
				a.fired[i] = true
				local ok, err = pcall(ev[2])
				if not ok then
					warn("[" .. TITLE .. "] " .. tostring(err))
				end
			end
		end
		if p >= 1 and K.act == a then
			K.act = nil
		end
	end

	local talkGui, talkPart = nil, nil
	K.talks = cfg.talks ~= false
	function K.talk(text, color, secs)
		if not K.talks then
			return
		end
		if not talkPart then
			talkPart = K.part3(K.rootCF(), V3(0.2, 0.2, 0.2), nil, nil, 1)
			talkGui = Instance.new("BillboardGui")
			talkGui.Size = UDim2.fromOffset(360, 60)
			talkGui.StudsOffsetWorldSpace = V3(0, 2.6, 0)
			talkGui.MaxDistance = 120
			talkGui.LightInfluence = 0
			talkGui.Adornee = talkPart
			local label = Instance.new("TextLabel")
			label.Name = "Line"
			label.BackgroundTransparency = 1
			label.Size = UDim2.fromScale(1, 1)
			label.Font = Enum.Font.GothamBold
			label.TextScaled = true
			label.TextStrokeTransparency = 0.4
			label.Parent = talkGui
			local guiParent = nil
			pcall(function()
				guiParent = (gethui and gethui()) or game:GetService("CoreGui")
			end)
			talkGui.Parent = guiParent or Players.LocalPlayer:FindFirstChildOfClass("PlayerGui")
		end
		local label = talkGui:FindFirstChild("Line")
		label.Text = tostring(text)
		label.TextColor3 = color or Color3.new(1, 1, 1)
		label.TextTransparency = 0
		label.TextStrokeTransparency = 0.4
		K.talkUntil = os.clock() + (secs or 2.5)
	end

	local HATS = {}
	K.HATS = HATS
	local function accName(e)
		local ok, n = pcall(function()
			return rawget(e, "p").Parent.Name
		end)
		return ok and type(n) == "string" and n or ""
	end
	local function sizeOf(e)
		local ok, s = pcall(function()
			return rawget(e, "p").Size
		end)
		return ok and typeof(s) == "Vector3" and s or V3(1, 1, 1)
	end
	function K.hats()
		local out = {}
		for e in pairs(fd.cframes) do
			if type(e) == "table" and rawget(e, "m") ~= nil then
				out[#out + 1] = e
			end
		end
		table.sort(out, function(a, b)
			return tostring(rawget(a, "m")) .. accName(a) < tostring(rawget(b, "m")) .. accName(b)
		end)
		return out
	end
	local function info(e)
		return { mesh = Kit.digits(rawget(e, "m")), tex = Kit.digits(rawget(e, "t")), name = accName(e) }
	end
	local function aligned(e)
		if type(fd.rigHat) == "function" then
			local okR, r = pcall(fd.rigHat, e)
			if okR then
				return r ~= nil
			end
		end
		local ok, j = pcall(fd.getPartJoint, e)
		if not ok or type(j) ~= "table" then
			return true
		end
		local p1 = j.Part1
		for _, limb in pairs(Kit.LIMBS) do
			if p1 == K.part(limb) and limb ~= "Head" and (typeof(j.C1) ~= "CFrame" or j.C1 == CFI) then
				return true
			end
		end
		return false
	end
	local function claimed(e, job)
		for k, h in pairs(HATS) do
			if k ~= job and h.e == e then
				return true
			end
		end
		local ok, j = pcall(fd.getPartJoint, e)
		local p1 = ok and type(j) == "table" and j.Part1 or nil
		if type(p1) == "table" and rawget(p1, "m") ~= nil then
			return true
		end
		return false
	end
	local function wordsHit(A, job, name)
		if type(A) ~= "table" or type(A.rows) ~= "function" or name == "" then
			return false
		end
		local ok, list = pcall(A.rows, TITLE, job .. "words")
		if not ok or type(list) ~= "table" then
			return false
		end
		local low = string.lower(name)
		for _, row in ipairs(list) do
			for _, w in ipairs(type(row) == "table" and type(row.words) == "table" and row.words or {}) do
				if type(w) == "string" and w ~= "" and string.find(low, string.lower(w), 1, true) then
					return true
				end
			end
		end
		return false
	end
	local function find(job, kind)
		local A = genv.AtsukoAlignment
		local W = genv.AtsukoEmoteWeapons
		local best, rank, row = nil, math.huge, nil
		for _, e in ipairs(K.hats()) do
			if not claimed(e, job) then
				local hi = info(e)
				local score, r = nil, nil
				if type(A) == "table" and type(A.match) == "function" then
					local ok, m = pcall(A.match, TITLE, job, hi, e)
					if ok and type(m) == "table" then
						score, r = (m.src == "user" and not m.shipped) and 1 or 2, m
					end
				end
				if not score and not aligned(e) and wordsHit(A, job, hi.name) then
					score = 2.5
				end
				if not score and kind and type(W) == "table" and type(W.kind) == "function" and not aligned(e) then
					local ok, k = pcall(W.kind, hi.mesh, hi.tex, hi.name)
					if ok and k == kind then
						score = 3
					end
				end
				if score and score < rank then
					best, rank, row = e, score, r
				end
			end
		end
		return best, row
	end
	function K.want(job, kind)
		HATS[job] = HATS[job] or { job = job, kind = kind, next = 0 }
		return HATS[job]
	end
	local function release(h)
		if h.unjoin then
			pcall(h.unjoin)
			h.unjoin = nil
		end
		if h.j and h.home then
			pcall(function()
				h.j.Part1, h.j.C0, h.j.C1 = h.home[1], h.home[2], h.home[3]
			end)
		end
		h.e, h.j, h.home, h.row, h.fitCF, h.mate = nil, nil, nil, nil, nil, nil
	end
	local function refresh(h, now)
		if h.e and fd.cframes[h.e] ~= nil then
			return true
		end
		if now < h.next then
			return h.e ~= nil
		end
		h.next = now + 1
		release(h)
		local e, row = find(h.job, h.kind)
		if not e then
			return false
		end
		local ok, j = pcall(fd.getPartJoint, e)
		if not ok or type(j) ~= "table" then
			return false
		end
		h.e, h.j, h.row = e, j, row
		h.home = { j.Part1, j.C0, j.C1 }
		h.fitCF, h.long = Kit.fit(sizeOf(e))
		h.extra = nil
		local A = genv.AtsukoAlignment
		if h.kind and type(A) == "table" and type(A.join) == "function" then
			local okJ, undo, other = pcall(A.join, fd, e)
			if okJ and type(undo) == "function" then
				h.unjoin, h.mate = undo, other
			end
		end
		if row and type(A) == "table" and type(A.offset) == "function" then
			local okO, c = pcall(A.offset, row)
			if okO and typeof(c) == "CFrame" then
				h.extra = c
			end
		end
		return true
	end
	function K.has(job)
		local h = HATS[job]
		return h ~= nil and h.e ~= nil
	end
	function K.hold(job, limb, cf)
		local h = HATS[job]
		if not h then
			return false
		end
		h.mode, h.limb, h.at = "hold", limb, cf
		return h.e ~= nil
	end
	function K.grip(job, key, rootCF)
		local h = HATS[job]
		if not h then
			return false
		end
		h.mode, h.limb = "hold", Kit.LIMBS[key]
		h.at = function()
			return (K.cur.root * K.cur[key]):Inverse() * rootCF
		end
		return h.e ~= nil
	end
	function K.put(job, world)
		local h = HATS[job]
		if not h then
			return false
		end
		h.mode, h.world = "world", world
		return h.e ~= nil
	end
	function K.home(job)
		local h = HATS[job]
		if h then
			h.mode = "home"
		end
	end
	function K.tail(h)
		local t = h.fitCF or CFI
		if h.extra then
			t = t * h.extra
		end
		if h.offset then
			t = t * h.offset
		end
		return t
	end
	function K.hatWorld(job)
		local h = HATS[job]
		if not (h and h.e) then
			return nil
		end
		local c = fd.cframes[h.e]
		return typeof(c) == "CFrame" and c or nil
	end
	local function driveHats(now)
		local root = K.part("HumanoidRootPart")
		local rootCF = K.rootCF()
		for _, h in pairs(HATS) do
			if refresh(h, now) and h.j then
				if h.mode == "hold" and h.limb then
					local limb = K.part(h.limb)
					if limb then
						local at = type(h.at) == "function" and h.at() or h.at
						h.j.Part1, h.j.C0, h.j.C1 = limb, CFI, at * K.tail(h)
					end
				elseif h.mode == "world" and h.world and root then
					h.j.Part1, h.j.C0, h.j.C1 = root, CFI, rootCF:Inverse() * h.world * K.tail(h)
				elseif h.home then
					h.j.Part1, h.j.C0, h.j.C1 = h.home[1], h.home[2], h.home[3]
				end
			end
		end
	end

	local keys, clicks = {}, {}
	function K.key(code, down, up)
		keys[code] = { down = down, up = up }
	end
	function K.click(down, up)
		clicks[#clicks + 1] = { down = down, up = up }
	end
	K.held = {}
	local function onInput(input, gpe, began)
		if not K.alive then
			return
		end
		local t = input.UserInputType
		if t == Enum.UserInputType.MouseButton1 or (t == Enum.UserInputType.Touch and not gpe) then
			if gpe and began then
				return
			end
			K.held.click = began
			for _, c in ipairs(clicks) do
				local f = began and c.down or c.up
				if f then
					task.spawn(f)
				end
			end
		elseif t == Enum.UserInputType.Keyboard and not gpe then
			local k = keys[input.KeyCode]
			K.held[input.KeyCode] = began
			if k then
				local f = began and k.down or k.up
				if f then
					task.spawn(f)
				end
			end
		end
	end
	K.conns[#K.conns + 1] = UserInputService.InputBegan:Connect(function(i, g)
		onInput(i, g, true)
	end)
	K.conns[#K.conns + 1] = UserInputService.InputEnded:Connect(function(i, g)
		onInput(i, g, false)
	end)

	local cmds = {}
	function K.command(def)
		cmds[#cmds + 1] = def
	end

	local music = nil
	K.musicOn = cfg.music ~= false
	function K.music(file, vol)
		task.spawn(function()
			local id, why = Kit.asset(file)
			if not K.alive then
				return
			end
			if not id then
				K.say("No music: " .. tostring(why), "info", 3)
				return
			end
			music = Instance.new("Sound")
			music.Name = "Music"
			music.SoundId = id
			music.Looped = true
			music.Volume = vol or 1.5
			music.Parent = fxFolder
			if K.musicOn then
				music:Play()
			end
		end)
	end
	function K.setMusic(on)
		K.musicOn = on
		if music then
			if on then
				music:Resume()
				if not music.IsPlaying then
					music:Play()
				end
			else
				music:Pause()
			end
		end
	end
	function K.song()
		return music
	end

	local FILE = TITLE:gsub("[^%w]", "") .. "Align.json"
	local TABS, JOBS, VAL, HATOF = {}, {}, {}, {}
	K.offsets = {}
	for _, j in ipairs(cfg.jobs or {}) do
		TABS[#TABS + 1] = j[2]
		JOBS[#JOBS + 1] = j[1]
		HATOF[#HATOF + 1] = j[3] or j[1]
		VAL[#VAL + 1] = { 0, 0, 0, 0, 0, 0 }
	end
	local function rebuild(s)
		local v = VAL[s]
		local c = CF(v[1], v[2], v[3]) * ANG(rad(v[4]), rad(v[5]), rad(v[6]))
		K.offsets[JOBS[s]] = c
		local h = HATS[JOBS[s]]
		if h then
			h.offset = c
		end
	end
	function K.offset(key)
		return K.offsets[key] or CFI
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
			return HttpService:JSONDecode(readfile(FILE))
		end)
		if not ok2 or type(data) ~= "table" then
			return false, FILE .. " is damaged"
		end
		for s, job in ipairs(JOBS) do
			local a = data[job]
			if type(a) == "table" then
				for k = 1, 6 do
					local n = tonumber(a[k])
					if n and n == n and abs(n) < 1e5 then
						VAL[s][k] = n
					end
				end
			end
			rebuild(s)
		end
		return true
	end
	local function saveAlign()
		if not writefile then
			return false, "your executor can't save files"
		end
		local data = { v = 1 }
		for s, job in ipairs(JOBS) do
			data[job] = VAL[s]
		end
		local ok, e = pcall(writefile, FILE, HttpService:JSONEncode(data))
		return ok, not ok and tostring(e) or nil
	end
	local watchers = {}
	local function fire(what)
		for _, f in ipairs(table.clone(watchers)) do
			pcall(f, what)
		end
	end
	local AL = { version = 1, title = TITLE, tabs = TABS, file = FILE, dirty = false, open = false, marker = false, hint = cfg.alignHint }
	K.AL = AL
	function AL.alive()
		return K.alive
	end
	function AL.focus() end
	function AL.get(s)
		return VAL[s] and table.clone(VAL[s]) or nil
	end
	function AL.later()
		AL.tok = (AL.tok or 0) + 1
		local my = AL.tok
		task.delay(1.5, function()
			if my == AL.tok and AL.dirty and K.alive and AL.save() then
				fire("saved")
			end
		end)
	end
	function AL.set(s, k, n)
		local v = VAL[s]
		n = tonumber(n)
		if not v or not n or n ~= n or abs(n) >= 1e5 then
			return nil
		end
		if k > 3 then
			n = ((n + 180) % 360) - 180
			n = math.floor(n * 10 + 0.5) / 10
		else
			n = math.floor(n * 1000 + 0.5) / 1000
		end
		v[k] = n
		rebuild(s)
		AL.dirty = true
		AL.later()
		return n
	end
	function AL.put(s, vals)
		if not VAL[s] or type(vals) ~= "table" then
			return
		end
		for k = 1, 6 do
			VAL[s][k] = tonumber(vals[k]) or 0
		end
		rebuild(s)
		AL.dirty = true
		AL.later()
	end
	function AL.reset(s)
		AL.put(s, { 0, 0, 0, 0, 0, 0 })
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
		local parts = {}
		for s, job in ipairs(JOBS) do
			if HATOF[s] == job then
				local h = HATS[job]
				parts[#parts + 1] = TABS[s] .. ": " .. ((h and h.e) and (accName(h.e) ~= "" and accName(h.e) or "found") or "not found")
			end
		end
		return table.concat(parts, "  ·  ")
	end
	function AL.hat(s)
		local h = HATS[HATOF[s]]
		if not (h and h.e) then
			return nil
		end
		local hi = info(h.e)
		return hi.mesh, hi.tex, hi.name ~= "" and hi.name or nil
	end

	K.alive = true
	local frameFn = nil
	K.state = { t = 0, phase = 0, air = 0, walk = 0, last = os.clock(), kind = "idle" }
	function K.frame(fn)
		frameFn = fn
	end
	local lastErr = nil
	local function step(kind)
		if not K.alive then
			return
		end
		local st = K.state
		local now = os.clock()
		local dt = clamp(now - st.last, 1 / 240, 1 / 15)
		st.last, st.dt, st.kind = now, dt, kind
		st.t = st.t + dt
		local v = K.vel()
		st.vel = v
		st.speed = V3(v.X, 0, v.Z).Magnitude
		local airborne = kind == "jump" or kind == "fall"
		st.air = Kit.toward(st.air, airborne and 1 or 0, 10, dt)
		st.walk = Kit.toward(st.walk, (kind == "walk" and st.speed > 0.5) and 1 or 0, 8, dt)
		if kind == "walk" then
			st.phase = (st.phase + dt * clamp(st.speed, 6, 40) * 0.5) % (2 * pi)
		end
		tickAct()
		local ok, err = pcall(frameFn or function() end, K, st)
		if not ok and err ~= lastErr then
			lastErr = err
			warn("[" .. TITLE .. "] " .. tostring(err))
		end
		K.apply(dt)
		tickShots(dt)
		driveHats(now)
		tickFx(dt)
		if talkPart then
			local head = K.cf("Head") or K.rootCF()
			talkPart.CFrame = head
			local label = talkGui:FindFirstChild("Line")
			local left = (K.talkUntil or 0) - now
			label.TextTransparency = left > 0.4 and 0 or clamp(1 - left / 0.4, 0, 1)
			label.TextStrokeTransparency = 0.4 + label.TextTransparency * 0.6
		end
		if ear then
			ear.CFrame = K.rootCF()
		end
	end
	local function mode(kind)
		return function()
			step(kind)
		end
	end

	function K.onStop(f)
		K.stops[#K.stops + 1] = f
	end
	function K.stop()
		if not K.alive then
			return
		end
		K.alive = false
		for _, f in ipairs(K.stops) do
			pcall(f)
		end
		for _, c in ipairs(K.conns) do
			pcall(function()
				c:Disconnect()
			end)
		end
		table.clear(K.conns)
		if AL.dirty then
			pcall(saveAlign)
			AL.dirty = false
		end
		for _, h in pairs(HATS) do
			release(h)
		end
		for name, j in pairs(J) do
			pcall(function()
				j.C0 = REST[name].C0
			end)
		end
		if music then
			pcall(function()
				music:Stop()
			end)
		end
		if talkGui then
			pcall(function()
				talkGui:Destroy()
			end)
		end
		pcall(function()
			genv.AtsukoFx[fxFolder] = nil
		end)
		pcall(function()
			fxFolder:Destroy()
		end)
		AL.open = false
		if genv.AtsukoAlign == AL then
			genv.AtsukoAlign = nil
		end
		fire("stop")
		local h = genv.AtsukoHub
		if type(h) == "table" and type(h.AlignReady) == "function" then
			pcall(h.AlignReady)
		end
		if onHub and genv.AtsukoScriptAligns == cfg.aligns then
			genv.AtsukoScriptAligns = nil
		end
	end

	function K.run()
		loadAlign()
		for s in ipairs(JOBS) do
			rebuild(s)
		end
		fd.addmode("default", { idle = mode("idle"), walk = mode("walk"), jump = mode("jump"), fall = mode("fall") })
		if #TABS > 0 then
			genv.AtsukoAlign = AL
		end
		local h = genv.AtsukoHub
		if type(h) == "table" then
			if type(h.AlignReady) == "function" then
				pcall(h.AlignReady)
			end
			if #cmds > 0 and type(h.Commands) == "table" and type(h.Commands.register) == "function" then
				pcall(h.Commands.register, cmds, { short = cfg.short or string.lower(TITLE:gsub("[^%w]", "")) })
			end
			if type(h.OnStop) == "function" then
				h.OnStop(function()
					K.stop()
					pcall(function()
						if rig and rig.stopreanimate then
							rig.stopreanimate()
						end
					end)
				end)
			end
		end
		K.conns[#K.conns + 1] = RunService.Heartbeat:Connect(function()
			if K.alive and not reanimOn() then
				K.stop()
			end
		end)
	end

	return K
end

local env = genvOf()
env.AtsukoMoveset = Kit
return Kit
