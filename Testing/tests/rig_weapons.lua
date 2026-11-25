local A = loadmodule("Hub/modules/alignment.lua")

local BUILTIN = [=====[
return {
	version = 1,
	help = {},
	rig = {
		{part = "Head", mesh = "111"},
	},
	shared = {
		gun = {
			{slot = "gun", mesh = "777", note = "a gun everyone knows"},
		},
	},
	scripts = {
		["AK-47"] = {
			{slot = "bulletwords", words = {"bullet"}},
		},
	},
}
]=====]

local function service(rigged)
	local env = { files = {}, freed = 0 }
	env.api = {
		fetch = function()
			return true, BUILTIN
		end,
		readUser = function()
			return env.files.user
		end,
		writeUser = function(text)
			env.files.user = text
			return true
		end,
		cframe = function(...)
			return { ... }
		end,
		publish = function(list, info)
			env.info = info
			env.published = list
		end,
		rigged = rigged,
		freeWeapons = function()
			env.freed += 1
			return 0
		end,
	}
	local svc = A.new(env.api)
	svc:load()
	return svc, env
end

T.section("rig_weapons: a hat everyone knows never takes a body part")
do
	local svc, env = service(function(hat, e)
		if e ~= nil then
			return e == "head hat"
		end
		return hat.mesh == "777"
	end)
	local info = env.info
	T.ok(type(info) == "table" and type(info.match) == "function", "the hat list is published")
	T.eq(info.match("AK-47", "gun", { mesh = "777" }, "head hat"), nil, "a shipped gun row can't take the hat the rig uses as its head")
	T.ok(info.match("AK-47", "gun", { mesh = "777" }, "loose hat") ~= nil, "it still takes the same hat when nothing else uses it")
	T.eq(info.match("AK-47", "gun", { mesh = "777" }), nil, "a script that can't say which hat asks by its ids, and the rig still wins")
	T.eq(info.weapon({ mesh = "777" }), false, "a shipped row doesn't make a hat yours")
	T.eq(#info.mine("AK-47", "gun"), 0, "scripts that read the list themselves don't get a shipped gun only the rig has")
	local before = env.freed
	local ok = svc:add("script", "AK-47", { slot = "gun", mesh = "777" })
	T.eq(ok, true, "you add that hat as the gun")
	T.ok(env.freed > before, "the reanimation is told to let your weapons go")
	local row = info.match("AK-47", "gun", { mesh = "777" }, "head hat")
	T.ok(row ~= nil and row.src == "user" and not row.shipped, "your own row takes it even off the rig")
	T.eq(env.info.weapon({ mesh = "777" }), true, "and it counts as your weapon")
	T.eq(#env.info.mine("AK-47", "gun"), 1, "and they get your own row")
	T.eq(env.info.weapon({ mesh = "778" }), false)
	T.eq(env.info.weapon({ mesh = "111" }), false, "the head stays a head")
	T.eq(env.info.weapon("nope"), false)
end

T.section("rig_weapons: the last add wins between a body part and a weapon")
do
	local svc, env = service(nil)
	svc.hats["4001"] = { mesh = "901", tex = "902", name = "Iron Arm" }
	local r1 = svc:addIds({ ids = { "4001" }, use = "rightarm" }, {}, nil)
	T.eq(#r1.added, 1, "added as a right arm")
	T.eq(#svc:userRows("rig"), 1)
	local only = { name = "AK-47", shown = "AK-47", slots = { "gun", "bullet" } }
	local r2 = svc:addIds({ ids = { "4001" }, use = "gun" }, {}, only)
	T.eq(#r2.added, 1, "then as AK-47's gun")
	T.eq(#svc:userRows("rig"), 0, "it isn't a right arm anymore")
	T.eq(#svc:userRows("script", "AK-47"), 1)
	T.eq(env.info.weapon({ mesh = "901" }), true)
	local r3 = svc:addIds({ ids = { "4001" }, use = "rightarm" }, {}, nil)
	T.eq(#r3.added, 1, "and back to a right arm")
	T.eq(#svc:userRows("script", "AK-47"), 0, "the gun row goes")
	T.eq(#svc:userRows("rig"), 1)
	T.eq(env.info.weapon({ mesh = "901" }), false)
end

T.section("rig_weapons: Script Reanimate knows its body parts and lets your weapons go")
do
	local World = loadmodule("Testing/mocks/rbx_world.lua")
	local env = World.install({})
	local G = (typeof(getgenv) == "function" and getgenv()) or _G
	local Players = game:GetService("Players")
	local lp = Players.LocalPlayer
	local char = lp.Character
	workspace.FallenPartsDestroyHeight = -500
	local realNew = Instance.new
	local function shim(o)
		local noop = function() end
		for _, k in ipairs({ "SetStateEnabled", "ChangeState", "BreakJoints", "Move" }) do
			local okK, v = pcall(function()
				return o[k]
			end)
			if not okK or v == nil then
				pcall(function()
					o[k] = noop
				end)
			end
		end
		local okJ, gj = pcall(function()
			return o.GetJoints
		end)
		if not okJ or gj == nil then
			pcall(function()
				o.GetJoints = function()
					return {}
				end
			end)
		end
		return o
	end
	Instance.new = function(c, parent)
		return shim(realNew(c, parent))
	end
	for _, n in ipairs({ "Left Arm", "Right Arm", "Left Leg", "Right Leg" }) do
		local p = Instance.new("Part")
		p.Name = n
		p.Parent = char
	end
	shim(char)
	for _, d in ipairs(char:GetDescendants()) do
		shim(d)
	end
	local UIS = game:GetService("UserInputService")
	for _, k in ipairs({ "JumpRequest", "WindowFocusReleased", "TouchStarted", "TouchMoved", "TouchEnded", "InputBegan", "InputEnded", "InputChanged" }) do
		local okS, v = pcall(function()
			return UIS[k]
		end)
		if not okS or v == nil then
			pcall(function()
				UIS[k] = Instance.new("BindableEvent").Event
			end)
		end
	end
	lp.GetMouse = function()
		local function sig()
			return Instance.new("BindableEvent").Event
		end
		return { TargetFilter = nil, Hit = CFrame.new(), X = 0, Y = 0, Button1Down = sig(), Button1Up = sig(), Button2Down = sig(), Button2Up = sig(), KeyDown = sig(), Move = sig() }
	end
	lp.HasAppearanceLoaded = function()
		return true
	end
	local function hat(name, mesh, att)
		local acc = Instance.new("Accessory")
		acc.Name = name
		local h = Instance.new("MeshPart")
		h.Name = "Handle"
		h.MeshId = "rbxassetid://" .. mesh
		h.TextureID = "rbxassetid://9" .. mesh
		local a = Instance.new("Attachment")
		a.Name = att
		a.Parent = h
		h.Parent = acc
		acc.Parent = char
		return acc
	end
	hat("Head Hat", "1110", "HatAttachment")
	hat("Pistol", "5551", "RightGripAttachment")
	hat("Arm A", "7771", "LeftShoulderAttachment")
	hat("Arm B", "7771", "LeftShoulderAttachment")
	hat("Saved Gun", "6661", "LeftShoulderAttachment")
	G.AtsukoAligns = {
		{ PartName = "Head", meshid = "1110" },
		{ PartName = "Left Arm", meshid = "7771" },
		{ PartName = "Right Arm", meshid = "6661" },
	}
	local mine = { ["6661"] = true }
	G.AtsukoAlignment = { weapon = function(h)
		for id in pairs(mine) do
			if type(h.mesh) == "string" and string.find(h.mesh, id, 1, true) then
				return true
			end
		end
		return false
	end }
	local okL, L = pcall(function()
		return loadstring(readsource("Hub/Reanimate.lua"), "=Reanimate")()
	end)
	T.ok(okL and type(L) == "table", "Script Reanimate loads: " .. tostring(L))
	local fd = nil
	if okL and type(L) == "table" then
		local okR, got = pcall(L.rig({}).reanimate)
		T.ok(okR and type(got) == "table", "it reanimates: " .. tostring(got))
		fd = okR and got or nil
	end
	env.run(6)
	if fd then
		local by = {}
		for e in pairs(fd.cframes) do
			if type(e) == "table" and rawget(e, "m") then
				local key = string.match(rawget(e, "m"), "%d+$")
				by[key] = by[key] or {}
				table.insert(by[key], e)
			end
		end
		local function limbOf(e)
			local j = fd.getPartJoint(e)
			return j and rawget(j.Part1, "Name")
		end
		T.eq(fd.rigHat(by["1110"][1]), "Head", "the head hat is a body part")
		T.eq(fd.rigHat(by["5551"][1]), nil, "the pistol isn't")
		T.eq(limbOf(by["5551"][1]), "Right Arm", "it hangs where it's worn")
		local arms = 0
		for _, e in ipairs(by["7771"]) do
			if fd.rigHat(e) == "Left Arm" then
				arms += 1
			end
		end
		T.eq(arms, 1, "one of the two arm hats is the left arm")
		T.eq(fd.rigHat(by["6661"][1]), nil, "a hat you added as a weapon never becomes a body part, even with a rig row for it")
		T.eq(limbOf(by["6661"][1]), "Left Arm", "it stays where it's worn for the script to take")
		T.eq(G.AtsukoRigHats({ mesh = "1110" }), true, "asking by ids: the head hat is the rig's")
		T.eq(G.AtsukoRigHats({ mesh = "5551" }), false)
		T.eq(G.AtsukoRigHats({ mesh = "7771" }), false, "an arm hat with a spare copy free isn't only the rig's")
		T.eq(G.AtsukoRigHats({}), false)
		T.eq(G.AtsukoRigHats(by["1110"][1] and nil, by["1110"][1]), true, "asking by the hat itself")

		local armRig, armFree
		for _, e in ipairs(by["7771"]) do
			if fd.rigHat(e) then
				armRig = e
			else
				armFree = e
			end
		end
		local accOf = function(e)
			local okA, n = pcall(function()
				return rawget(e, "p").Parent.Name
			end)
			return okA and n or ""
		end
		local takenName = accOf(armRig)
		G.AtsukoAlignment = { weapon = function(h)
			return h.acc == takenName or (type(h.mesh) == "string" and string.find(h.mesh, "6661", 1, true) ~= nil)
		end }
		T.eq(G.AtsukoFreeWeapons(), 1, "adding the arm hat as a weapon lets it go right away")
		T.eq(fd.rigHat(armRig), nil, "it isn't the left arm anymore")
		T.eq(limbOf(armRig), "Left Arm", "it went back to where it's worn")
		T.eq(fd.rigHat(armFree), "Left Arm", "and the spare copy took its place")
		T.eq(G.AtsukoFreeWeapons(), 0, "doing it again changes nothing")
		G.AtsukoAlignment = { weapon = function(h)
			return h.mesh ~= nil and string.find(h.mesh, "1110", 1, true) ~= nil
		end }
		T.eq(G.AtsukoFreeWeapons(), 1, "the head hat as a weapon")
		T.eq(fd.rigHat(by["1110"][1]), nil, "leaves the head")
		T.eq(G.AtsukoRigHats({ mesh = "1110" }), false)
		pcall(L.stopreanimate)
		env.run(1)
		T.eq(G.AtsukoRigHats, nil, "stopping takes the checks away")
		T.eq(G.AtsukoFreeWeapons, nil)
	end
end

T.section("rig_weapons: a switched script starts on the fake body")
do
	local G = (typeof(getgenv) == "function" and getgenv()) or _G
	local L = G.LumenReanim
	T.ok(type(L) == "table", "Script Reanimate is still loaded")
	if type(L) == "table" then
		local function startAt()
			local okR = pcall(L.rig({}).reanimate)
			T.ok(okR, "it reanimates")
			local cf = L.rootCF()
			pcall(L.stopreanimate)
			return cf
		end
		G.AtsukoRigAt = { cf = CFrame.new(300, 60, -40), t = os.clock() }
		local cf = startAt()
		T.ok(cf ~= nil and (cf.Position - Vector3.new(300, 60, -40)).Magnitude < 0.01, "right after another reanimation it starts where that body was: " .. tostring(cf and cf.Position))
		G.AtsukoRigAt = { cf = CFrame.new(300, 60, -40), t = os.clock() - 60, keep = os.clock() }
		cf = startAt()
		T.ok(cf ~= nil and (cf.Position - Vector3.new(300, 60, -40)).Magnitude < 0.01, "a switch that took a while still starts there")
		T.eq(G.AtsukoRigAt.keep, nil, "and uses the spot only once")
		G.AtsukoRigAt = { cf = CFrame.new(300, 60, -40), t = 0 }
		cf = startAt()
		T.ok(cf ~= nil and (cf.Position - Vector3.new(300, 60, -40)).Magnitude > 1, "after a deanimate it starts at your own body again")
		G.AtsukoRigAt = { cf = CFrame.new(300, 60, -40), t = os.clock() - 60, keep = os.clock() - 60 }
		cf = startAt()
		T.ok(cf ~= nil and (cf.Position - Vector3.new(300, 60, -40)).Magnitude > 1, "an old spot is ignored")
	end
	local R = { }
	local Controller = loadmodule("Hub/modules/reanim.lua")
	local spots = {}
	local d = {
		notify = function() end,
		fire = function() end,
		spawn = function(f)
			f()
		end,
		wait = function() end,
		now = os.clock,
		alive = function()
			return true
		end,
		log = function() end,
		scriptActive = function()
			return false
		end,
		scriptPending = function()
			return false
		end,
		stopScript = function() end,
		lumen = function()
			return nil
		end,
		activePaths = function()
			return {}
		end,
		rigSpot = function(mode)
			spots[#spots + 1] = mode
		end,
	}
	Controller.attach(R, d)
	R.stop()
	T.same(spots, { "drop" }, "deanimating forgets the spot")
	local host = readsource("Hub/modules/reanim_host.lua")
	T.ok(string.find(host, "function deps.rigSpot(mode)", 1, true) ~= nil, "the hub keeps the spot in AtsukoRigAt")
	local ctl = readsource("Hub/modules/reanim.lua")
	T.ok(string.find(ctl, "rigSpot(\"keep\")", 1, true) ~= nil, "a switch keeps it")
	local fdl = readsource("Reanimation/Hat/FDless.lua")
	T.ok(string.find(fdl, "rigAt.cf=cfr", 1, true) ~= nil and string.find(fdl, "cfr=cfl(pos,pos+cfGet(rigAt.cf,\"LookVector\")*v3_101)", 1, true) ~= nil, "FDless starts there too")
end

T.section("rig_weapons: deanimating puts the camera, mouse and gravity back")
do
	local Host = loadmodule("Hub/modules/reanim_host.lua")
	local cam = { FieldOfView = 70, CameraType = "Custom" }
	local input = { MouseIconEnabled = true, MouseBehavior = "Default" }
	local world = { Gravity = 196.2 }
	local snap = Host.snapWorld({ camera = cam, input = input, world = world })
	T.eq(#snap, 5, "five things are remembered when a reanimation starts")
	cam.FieldOfView, cam.CameraType = 40, "Scriptable"
	input.MouseIconEnabled = false
	world.Gravity = 50
	T.eq(Host.restoreWorld(snap), 4, "what a script changed goes back")
	T.eq(cam.FieldOfView, 70)
	T.eq(cam.CameraType, "Custom")
	T.eq(input.MouseIconEnabled, true)
	T.eq(world.Gravity, 196.2)
	T.eq(Host.restoreWorld(snap), 0, "nothing else is touched")
	T.eq(Host.restoreWorld(nil), 0)
	local locked = setmetatable({}, { __index = function()
		return 1
	end, __newindex = function()
		error("locked")
	end })
	T.eq(Host.restoreWorld({ { obj = locked, key = "FieldOfView", value = 70 } }), 0, "a value that can't be set is skipped")
	T.eq(#Host.snapWorld({}), 0)
end

T.section("rig_weapons: FDless gets the same rules")
do
	local src = readsource("Reanimation/Hat/FDless.lua")
	local function has(text)
		return string.find(src, text, 1, true) ~= nil
	end
	T.ok(has("local wpn=hubWeapon(meshid,textureid,n)"), "it asks the hub before it makes a hat a body part")
	T.ok(has("if (not wpn) and l.p and sfind(meshid,l.meshid)"), "and skips the rig rows for your weapons")
	T.ok(has("rigOf[t]={l=l,lp=l.p,j=jt,att={v1[1],insGet(v,\"CFrame\"),v1[2]}}"), "it remembers which hats are body parts")
	T.ok(has("rigHat=rigHat,") and has("freeWeapons=freeWeapons,"), "and hands that to the scripts")
	T.ok(has("g.AtsukoRigHats=rigged") and has("g.AtsukoFreeWeapons=freeWeapons"), "and to the hub")
	local prov = readsource("Reanimation/providers/fdless.lua")
	T.ok(string.find(prov, "t.AtsukoRigHats = nil", 1, true) ~= nil, "stopping FDless takes them away")
end

T.section("rig_weapons: the scripts ask for the hat itself")
do
	local mv = readsource("Hub/Moveset.lua")
	local uhh = readsource("Hub/UhhMoveset.lua")
	T.ok(string.find(mv, "pcall(A.match, TITLE, job, hi, e)", 1, true) ~= nil, "the hub's own scripts")
	T.ok(string.find(uhh, "pcall(A.match, TITLE, slot, hi, e)", 1, true) ~= nil, "Uhhhhhh's scripts")
	T.ok(string.find(uhh, "local data = not limbOf(e) and Uhh.known(hi.mesh, hi.tex) or nil", 1, true) ~= nil, "Uhhhhhh's own list of hats never takes a body part")
end
