local World = loadmodule("Testing/mocks/rbx_world.lua")
local env = World.install({})
local src = readsource("Scripts/Hat/MasterChief.lua")

local function near(a, b, eps)
	return math.abs(a - b) <= (eps or 1e-3)
end
local function at(cf, x, y, z)
	local p = cf.Position
	return near(p.X, x) and near(p.Y, y) and near(p.Z, z)
end

T.section("master_chief: the script runs on the hub's pick, not on its own reanimate")
do
	T.eq(string.find(src, "workspace.non", 1, true), nil, "nothing looks for workspace.non anymore")
	T.eq(string.find(src, "SendNotification", 1, true), nil, "no grey pop-ups")
	T.eq(string.find(src, "function Reanimate()", 1, true), nil, "the Emper reanimate is gone")
	T.eq(string.find(src, "CreateHumanoidModelFromUserId", 1, true), nil, "and so is its rig")
	T.ok(string.find(src, "character = MC.doll\n", 1, true) ~= nil, "the character is the doll")
	T.ok(string.find(src, "mouse = MC.mouse\n", 1, true) ~= nil, "the mouse comes from the adapter")
	T.ok(string.find(src, "local MOUSE = MC.mouse\n", 1, true) ~= nil, "both mice")
	T.ok(string.find(src, 'local script = MC.objects("rbxassetid://10170990440")', 1, true) ~= nil, "the guns model is loaded through the adapter")
	T.ok(string.find(src, "while MC.alive() do\n", 1, true) ~= nil, "the main loop ends with the script")
	T.ok(string.find(src, "MC.push(rootpart.CFrame.lookVector*235)", 1, true) ~= nil, "the dash moves the reanimation")
	local holds = 0
	for _ in string.gmatch(src, "MC%.hold%(") do
		holds += 1
	end
	T.eq(holds, 4, "the four anchor lines hold you in place instead")
	T.eq(string.find(src, "rootpart.Anchored", 1, true), nil, "nothing anchors the root")
	T.eq(string.find(src, "rootpart.Velocity", 1, true), nil, "nothing reads or sets the root's velocity")
	T.eq(string.find(src, "humanoid.MoveDirection", 1, true), nil, "the move direction comes from the reanimation")
	T.ok(string.find(src, "MC.arm({rifle = {part = riflez, frame = rifle.Handle, model = rifle}, shotgun = {part = shotgunz, frame = shg.shotgun, model = shg}, bullet = {part = Bullet}})", 1, true) ~= nil, "the hats go on the rifle, the shotgun and the bullet")
	T.ok(string.find(src, "MC.free(effects)", 1, true) ~= nil, "the effects stay physical")
	T.ok(table.find(jsondecode(readsource("Scripts/manifest.json")).scripts["Scripts/Hat/MasterChief.lua"].credit, "Helkern") ~= nil, "the original credits are in the manifest")
end

local a = string.find(src, "local function hubNotify(", 1, true)
local b = string.find(src, "\nend)()\n", a, true)
T.ok(a ~= nil and b ~= nil, "the adapter block is found")
local block = string.sub(src, a, b + #"\nend)()\n" - 1) .. "\nreturn MC\n"

local function Sig()
	local s = { list = {} }
	function s:Connect(f)
		local c = { on = true }
		function c.Disconnect()
			c.on = false
		end
		self.list[#self.list + 1] = { f = f, c = c }
		return c
	end
	s.connect = s.Connect
	function s:Fire(...)
		for _, item in ipairs(self.list) do
			if item.c.on then
				item.f(...)
			end
		end
	end
	function s:Wait() end
	return s
end
local mouse = { Hit = CFrame.new(5, 0, 5), Button1Down = Sig(), Button1Up = Sig(), KeyDown = Sig(), KeyUp = Sig(), Move = Sig() }
local lp = game:GetService("Players").LocalPlayer
rawget(lp, "_p").GetMouse = function()
	return mouse
end

local api, on, sawAligns = nil, false, nil
local makeApi = loadmodule("Testing/mocks/fake_fd.lua").make
local genv = env.genv
_G.GenesisFDless = {
	reanimate = function()
		on = true
		sawAligns = genv.AtsukoScriptAligns
		api = makeApi()
		return api
	end,
	stopreanimate = function()
		on = false
	end,
	isReanimated = function()
		return on
	end,
}
local toasts = {}
genv.AtsukoNotify = function(title, text, kind)
	toasts[#toasts + 1] = tostring(title) .. "|" .. tostring(text) .. "|" .. tostring(kind)
end
genv.AtsukoScriptAligns = "before"
local readyCalls = 0
genv.AtsukoHub = { AlignReady = function()
	readyCalls += 1
end }

local fn, cerr = loadstring(block, "=MasterChief")
T.ok(fn ~= nil, "the adapter compiles: " .. tostring(cerr))
local okRun, MC = pcall(fn)
T.ok(okRun, "the adapter starts: " .. tostring(not okRun and MC or ""))

T.section("master_chief: the doll takes the place of workspace.non")
do
	T.eq(toasts[1], "Master Chief|Master Chief by Helkern, converted by MelonScripter|info", "one hub toast instead of two pop-ups")
	T.eq(on, true, "it reanimated on the hub's pick")
	T.ok(type(sawAligns) == "table" and #sawAligns == 16, "FDless saw the script's own rig hats while it started")
	T.eq(sawAligns[2].meshid, "3030546036", "the free fedora rig is in there")
	T.eq(genv.AtsukoScriptAligns, "before", "and the old value is put back afterwards")
	local doll = MC.doll
	T.ok(doll ~= nil and doll.Parent == workspace, "the doll is in the workspace")
	T.eq(doll.Name, lp.Name, "named after you, so Script Reanimate treats it as your body")
	for _, name in ipairs({ "HumanoidRootPart", "Torso", "Head", "Right Arm", "Left Arm", "Right Leg", "Left Leg" }) do
		local p = doll:FindFirstChild(name)
		T.ok(p ~= nil and p.Anchored == true and p.CanQuery == false and p.CanCollide == false, name .. " is an anchored, ghosted part")
	end
	T.ok(doll.HumanoidRootPart:FindFirstChild("RootJoint") ~= nil, "rootpart.RootJoint exists")
	for _, name in ipairs({ "Neck", "Right Shoulder", "Left Shoulder", "Right Hip", "Left Hip" }) do
		local m = doll.Torso:FindFirstChild(name)
		T.ok(m ~= nil and m.ClassName == "Motor6D" and m.Enabled == false, "torso[" .. name .. "] exists and is driven by the adapter")
	end
	local hum = doll:FindFirstChildOfClass("Humanoid")
	T.ok(hum ~= nil and hum:FindFirstChild("Animator") ~= nil, "humanoid.Animator exists for the script to destroy")
	T.ok(doll:FindFirstChild("Animate") ~= nil, "character.Animate exists for the script to remove")
	local mode = api.modes.default
	T.ok(mode and mode.idle == MC.frame and mode.walk == MC.frame and mode.jump == MC.frame and mode.fall == MC.frame, "the doll is followed in every pose")
	T.eq(genv.AtsukoAlign, MC.AL, "the alignment window adapter is published")
	T.ok(readyCalls >= 1, "and the hub is told")
	T.same(MC.AL.tabs, { "Rifle", "Shotgun" }, "two guns, two tabs")
end

T.section("master_chief: the script's joints drive the reanimation")
do
	local doll = MC.doll
	local torso, rarm = doll.Torso, doll["Right Arm"]
	local ra = Instance.new("Weld")
	ra.Name = "ra"
	ra.Part0 = torso
	ra.Part1 = rarm
	ra.C0 = CFrame.new(1.5, 0.7, 0)
	ra.C1 = CFrame.new(0, 0.5, 0)
	ra.Parent = torso
	T.eq(ra.Enabled, false, "a weld the script adds is taken over")
	doll.HumanoidRootPart.RootJoint.C0 = CFrame.new(0, 0.3, 0)
	MC.frame()
	local sh = api.getJoint("Right Shoulder")
	T.ok(at(sh.C0, 1, 0.7, 0), "the script's weld wins over the old Motor6D (" .. tostring(sh.C0.Position) .. ")")
	T.ok(at(api.getJoint("RootJoint").C0, 0, 0.3, 0), "rootjoint.C0 reaches the reanimation")
	T.ok(at(api.getJoint("Left Shoulder").C0, -1, 0.5, 0), "an untouched limb keeps its rest pose")
	T.ok(at(doll.HumanoidRootPart.CFrame, 0, 3, 0), "the doll's root sits on the reanimation's root")
	T.ok(at(doll["Left Arm"].CFrame, -1.5, 3, 0), "and every body part on the reanimation's parts")
end

local rifle, riflez, shg, shotgunz, bullet, eqpweld
T.section("master_chief: the rifle, the shotgun and the bullet get their hats")
do
	local doll = MC.doll
	rifle = Instance.new("Model")
	rifle.Name = "rifle"
	local eqp = Instance.new("Part")
	eqp.Name = "eqp"
	eqp.Parent = rifle
	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Parent = rifle
	local hole = Instance.new("Part")
	hole.Name = "Hole"
	hole.Position = Vector3.new(0, 0, -3)
	hole.Parent = rifle
	eqpweld = Instance.new("Weld")
	eqpweld.Part0 = eqp
	eqpweld.Part1 = doll["Right Arm"]
	eqpweld.Parent = rifle
	local w2 = Instance.new("Weld")
	w2.Part0 = eqp
	w2.Part1 = handle
	w2.C1 = CFrame.new(0, -1, 0)
	w2.Parent = rifle
	rifle.Parent = doll
	riflez = Instance.new("Part")
	riflez.Name = "Rifle"
	riflez.Parent = doll
	local rw = Instance.new("Weld")
	rw.Part0 = handle
	rw.Part1 = riflez
	rw.Parent = doll
	shg = Instance.new("Model")
	shg.Name = "shotgun"
	local body = Instance.new("Part")
	body.Name = "shotgun"
	body.Parent = shg
	local sh = Instance.new("Part")
	sh.Name = "Hole"
	sh.Position = Vector3.new(0, 0, -3)
	sh.Parent = shg
	shotgunz = Instance.new("Part")
	shotgunz.Name = "Shotgun"
	shotgunz.Parent = doll
	bullet = Instance.new("Part")
	bullet.Name = "Bullet"
	bullet.Parent = doll
	T.eq(handle.Anchored, true, "the gun model is anchored in the doll")
	T.eq(eqpweld.Enabled, false, "and its welds are taken over")
	local railgun, j1 = api.hat("Railgun", "6774735978", "6774736019")
	local horus, j2 = api.hat("Hoshino's Eye of Horus", "999", nil, Vector3.new(4, 1, 0.5))
	local rock, j3 = api.hat("Rock", "555", nil)
	local spare, j4 = api.hat("Kinetic Staff", "5548423017", "5548423938")
	genv.AtsukoAlignment = {
		match = function(script, slot, hat)
			if script == "Master Chief" and slot == "bullet" and hat.mesh == "555" then
				return { src = "user", slot = "bullet", mesh = "555", align = { 0, 1, 0, 0, 0, 0 } }
			end
			return nil
		end,
		offset = function(row)
			return CFrame.new(row.align[1], row.align[2], row.align[3])
		end,
	}
	MC.arm({ rifle = { part = riflez, frame = handle, model = rifle }, shotgun = { part = shotgunz, frame = body, model = shg }, bullet = { part = bullet } })
	T.eq(MC.slots.rifle and MC.slots.rifle.e, railgun, "the railgun is the rifle, it comes first in the list")
	T.eq(j1.Part1 and j1.Part1.Name, "Rifle", "it is joined to the rifle part")
	T.ok(at(j1.C0, 0.1, -0.55, 0.35), "with the original script's alignment (" .. tostring(j1.C0.Position) .. ")")
	T.eq(j4.Part1, api.V.Head, "the second rifle hat stays where it was")
	T.eq(MC.slots.shotgun, nil, "no shotgun yet: the catalog gun's mesh is not known")
	T.eq(MC.slots.bullet and MC.slots.bullet.e, rock, "the bullet hat you picked in Hats & alignment is used")
	T.ok(at(j3.C0, 0, 1, 0), "with your alignment")
	MC.GUNS.shotgun[3].mesh = "999"
	MC.scan()
	T.eq(MC.slots.shotgun and MC.slots.shotgun.e, horus, "once its mesh is known, Hoshino's Eye of Horus is the shotgun")
	T.eq(MC.slots.shotgun.name, "Hoshino's Eye of Horus")
	T.eq(j2.Part1 and j2.Part1.Name, "Shotgun")
	T.ok(at(j2.C0, 0, 0, 1), "a gun the script doesn't know is fitted by its size, with its front at the muzzle (" .. tostring(j2.C0.Position) .. ")")
	T.eq(MC.AL.found(), "Rifle: Tactical Cyberpunk Railgun   |   Shotgun: Hoshino's Eye of Horus")
end

T.section("master_chief: the hats follow the gun models")
do
	MC.frame()
	local doll = MC.doll
	local handle = rifle.Handle
	T.ok(at(rifle.eqp.CFrame, 1.5, 3, 0), "the gun follows the right arm")
	T.ok(at(handle.CFrame, 1.5, 4, 0), "through the gun's own welds")
	T.ok(at(riflez.CFrame, 1.5, 4, 0), "all the way to the rifle part")
	local linked = false
	local vr = MC.slots.rifle.j.Part1
	for _, j in ipairs(api.joints) do
		if (j.Part0 == vr or j.Part1 == vr) and j.Name ~= "AccessoryWeld" then
			linked = true
		end
	end
	T.ok(linked, "the reanimation gets the chain too, so the rifle hat moves with the arm in the same frame")
	MC.AL.set(1, 2, 0.5)
	MC.frame()
	T.ok(at(MC.slots.rifle.j.C1, 0, 0.5, 0), "the Rifle tab moves the rifle hat")
	T.ok(at(MC.slots.shotgun.j.C1, 0, 0, 0), "and leaves the shotgun alone")
	MC.AL.set(2, 1, -0.25)
	MC.frame()
	T.ok(at(MC.slots.shotgun.j.C1, -0.25, 0, 0), "the Shotgun tab moves the shotgun hat")
	local mirrored = nil
	for _, j in ipairs(api.joints) do
		if j.Name == eqpweld.Name and j.Part0 ~= nil and j.Part1 ~= nil and j.Part1 == api.V["Right Arm"] then
			mirrored = j
		end
	end
	T.ok(mirrored ~= nil, "the weld to the arm is mirrored")
	eqpweld.Parent = nil
	MC.frame()
	T.eq(mirrored.Part0, nil, "a weld the script takes away is taken out of the reanimation too")
	eqpweld.Parent = rifle
	MC.frame()
	T.ok(mirrored.Part0 ~= nil, "and put back when it comes back")
	local effects = Instance.new("Folder")
	effects.Parent = doll
	MC.free(effects)
	local fx = Instance.new("Part")
	fx.Parent = effects
	T.eq(fx.Anchored, false, "effects stay physical, so the grenade still flies")
end

T.section("master_chief: walking, running, shooting and the dash")
do
	local hum = MC.doll:FindFirstChildOfClass("Humanoid")
	MC.frame()
	T.eq(api.ws, 16, "the walk speed reaches the reanimation")
	hum.WalkSpeed = 35
	MC.frame()
	T.eq(api.ws, 35, "and running")
	MC.hold(true)
	MC.frame()
	T.eq(api.ws, 0, "while shooting you stand still, like the anchored root did")
	T.eq(api.jp, 0, "and can't jump")
	MC.hold(false)
	MC.frame()
	T.eq(api.ws, 35, "then you can move again")
	T.eq(api.jp, 50)
	api.vel = Vector3.new(10, 2, 0)
	T.ok(MC.vel() == Vector3.new(10, 2, 0), "the velocity is the reanimation's")
	local d = MC.moveDir()
	T.ok(near(d.X, 1) and near(d.Y, 0) and near(d.Z, 0), "the move direction comes from it too")
	api.onground = false
	T.eq(MC.ground(), false, "so does the ground")
	api.onground = true
	T.eq(MC.ground(), true)
	api.vel = Vector3.new()
	MC.push(Vector3.new(0, 0, -235))
	env.run(0.4)
	T.ok(#api.moved > 0, "the dash moves the root")
	local z = api.cframes[api.V.HumanoidRootPart].Position.Z
	T.ok(z < -5 and z > -25, "forward by about twenty studs (" .. tostring(z) .. ")")
	env.run(0.5)
	MC.push(Vector3.new(0, 50, 0))
	local before = #api.moved
	env.run(0.1)
	T.eq(#api.moved, before, "a push straight up does nothing")
end

T.section("master_chief: when the reanimation stops, everything goes back")
do
	local clicks = 0
	MC.mouse.Button1Down:Connect(function()
		clicks += 1
	end)
	mouse.Button1Down:Fire()
	T.eq(clicks, 1, "the mouse works through the adapter")
	T.ok(MC.mouse.Hit == mouse.Hit, "Hit is the real mouse's")
	local j1 = MC.slots.rifle.j
	local doll = MC.doll
	on = false
	env.run(0.2)
	T.eq(MC.alive(), false, "the script sees it is over")
	T.eq(j1.Part1, api.V.Head, "the rifle hat goes back on its accessory")
	T.ok(at(j1.C0, 0, 0.6, 0), "where it was")
	T.eq(genv.AtsukoAlign, nil, "the alignment window lets go")
	env.run(1)
	mouse.Button1Down:Fire()
	T.eq(clicks, 1, "the mouse connections are cut a moment later, once the loops have seen it")
	T.eq(doll.Parent, nil, "the doll is gone")
end

T.section("master_chief: the guns model loads even when GetObjects is picky")
do
	on = false
	local fn2 = loadstring(block, "=MasterChief")
	local ok2, MC2 = pcall(fn2)
	T.ok(ok2, "a second start works")
	local cm = rawget(game, "_cm")
	local realGet = cm.GetObjects
	local model = Instance.new("Model")
	for _, n in ipairs({ "rifle", "shotgun", "gren" }) do
		local c = Instance.new("Model")
		c.Name = n
		c.Parent = model
	end
	local calls = 0
	cm.GetObjects = function()
		calls += 1
		error("HTTP 429 (Too Many Requests)")
	end
	local insert = game:GetService("InsertService")
	rawget(insert, "_p").LoadLocalAsset = function(_, id)
		return model
	end
	local got = MC2.objects("rbxassetid://10170990440")
	T.eq(got, model, "when GetObjects throws, InsertService:LoadLocalAsset is tried next")
	T.ok(calls >= 1, "GetObjects was tried first")
	T.eq(MC2.standIn, nil, "the real model is used")
	rawget(insert, "_p").LoadLocalAsset = nil
	cm.GetObjects = function()
		return { model }
	end
	T.eq(MC2.objects("rbxassetid://10170990440"), model, "GetObjects itself works like in the other scripts")
	cm.GetObjects = function()
		return {}
	end
	local toastsBefore = #toasts
	local t0 = os.clock()
	local pack = MC2.objects("rbxassetid://10170990440")
	T.ok(os.clock() - t0 >= 2.5, "it asks Roblox three times before it gives up")
	T.eq(MC2.standIn, true, "then it builds its own stand-in")
	T.ok(MC2.alive(), "and keeps running instead of stopping")
	T.ok(string.find(toasts[toastsBefore + 1] or "", "Master Chief|Roblox didn't send the gun models (nothing came back), so Master Chief uses its own", 1, true) == 1, "the toast says what happened: " .. tostring(toasts[toastsBefore + 1]))
	for _, name in ipairs({ "rifle", "shotgun", "s", "p", "gren" }) do
		T.ok(pack:FindFirstChild(name) ~= nil, "the stand-in has " .. name)
	end
	T.ok(pack.rifle:FindFirstChild("Handle") and pack.rifle:FindFirstChild("Hole") and pack.rifle:FindFirstChild("eqp") and pack.rifle:FindFirstChild("uneqp"), "the rifle has the parts the script uses")
	T.ok(pack.rifle.joint2:FindFirstChild("Weld") ~= nil, "and rifle.joint2.Weld")
	T.ok(pack.shotgun:FindFirstChild("shotgun") and pack.shotgun.joint2:FindFirstChild("Weld"), "the shotgun too")
	T.eq(pack.gren.ClassName, "Part", "the grenade is a part")
	local railgunHat = { hat = { mesh = "6774735978", tex = "6774736019", name = "Railgun" } }
	local _, c0 = MC2.choose("rifle", { railgunHat })
	T.eq(c0, nil, "with the stand-in the railgun is fitted by its size, the script's numbers were for the real model")
	MC2.standIn = nil
	cm.GetObjects = realGet
	on = false
	env.run(1)
end

T.section("master_chief: catalog guns are looked up one at a time, and only when needed")
do
	local cm = rawget(game, "_cm")
	local realGet = cm.GetObjects
	local inFlight, most, asked = 0, 0, {}
	cm.GetObjects = function(_, id)
		asked[#asked + 1] = tostring(id)
		inFlight += 1
		most = math.max(most, inFlight)
		task.wait(0.05)
		inFlight -= 1
		return {}
	end
	local fn3 = loadstring(block, "=MasterChief")
	local ok3, MC3 = pcall(fn3)
	T.ok(ok3, "a third start works")
	T.eq(#asked, 0, "nothing is looked up while the reanimation starts")
	MC3.lookupGap = 0
	local railgun = api.hat("Railgun", "6774735978", "6774736019")
	local doll = MC3.doll
	local function slotPart(name)
		local p = Instance.new("Part")
		p.Name = name
		p.Parent = doll
		return p
	end
	MC3.arm({ rifle = { part = slotPart("Rifle") }, shotgun = { part = slotPart("Shotgun") }, bullet = { part = slotPart("Bullet") } })
	env.run(1)
	T.eq(MC3.slots.rifle and MC3.slots.rifle.e, railgun, "the worn railgun is the rifle")
	local rifleAsked = 0
	for _, id in ipairs(asked) do
		for _, g in ipairs(MC3.GUNS.rifle) do
			if g.hat and id == "rbxassetid://" .. g.hat then
				rifleAsked += 1
			end
		end
	end
	T.eq(rifleAsked, 0, "so no rifle is looked up")
	T.eq(#asked, 2, "only the two catalog shotguns are, since no shotgun is worn")
	T.eq(most, 1, "and never two at the same time")
	cm.GetObjects = realGet
	on = false
	env.run(1)
	_G.GenesisFDless = nil
	genv.AtsukoAlignment = nil
end

T.section("master_chief: the list in Alignment/alignment.lua agrees with the script")
do
	local A = loadmodule("Hub/modules/alignment.lua")
	local data = A.clean((A.parse(readsource("Alignment/alignment.lua"))))
	local rows = data.scripts["Master Chief"]
	T.ok(type(rows) == "table" and #rows == 10, "ten rows for Master Chief")
	T.ok(data.slots["Master Chief"].rifle ~= nil and data.slots["Master Chief"].shotgun ~= nil and data.slots["Master Chief"].bullet ~= nil, "its three jobs are explained")
	local function mul(a, b)
		local r = {}
		for i = 0, 2 do
			for j = 0, 2 do
				local s = 0
				for k = 0, 2 do
					s += a[i * 3 + k + 1] * b[k * 3 + j + 1]
				end
				r[i * 3 + j + 1] = s
			end
		end
		return r
	end
	local function rot(x, y, z)
		local cx, sx, cy, sy, cz, sz = math.cos(x), math.sin(x), math.cos(y), math.sin(y), math.cos(z), math.sin(z)
		return mul(mul({ 1, 0, 0, 0, cx, -sx, 0, sx, cx }, { cy, 0, sy, 0, 1, 0, -sy, 0, cy }), { cz, -sz, 0, sz, cz, 0, 0, 0, 1 })
	end
	local presets = {}
	for mesh, x, y, z, rx, ry, rz in string.gmatch(src, '{mesh = "(%d+)", tex = "%d+", cf = CF%(([%-%d%.]+), ([%-%d%.]+), ([%-%d%.]+)%) %* ANG%(([%-%d%.]+), ([%-%d%.]+), ([%-%d%.]+)%)') do
		presets[mesh] = { tonumber(x), tonumber(y), tonumber(z), rot(tonumber(rx), tonumber(ry), tonumber(rz)) }
	end
	local count = 0
	for _, row in ipairs(rows) do
		local p = row.mesh and presets[row.mesh]
		if p then
			count += 1
			local r = p[4]
			local t = { r[1], r[4], r[7], r[2], r[5], r[8], r[3], r[6], r[9] }
			local ix = -(t[1] * p[1] + t[2] * p[2] + t[3] * p[3])
			local iy = -(t[4] * p[1] + t[5] * p[2] + t[6] * p[3])
			local iz = -(t[7] * p[1] + t[8] * p[2] + t[9] * p[3])
			local a = row.align
			local mine = rot(math.rad(a[4]), math.rad(a[5]), math.rad(a[6]))
			local same = math.abs(a[1] - ix) < 1e-3 and math.abs(a[2] - iy) < 1e-3 and math.abs(a[3] - iz) < 1e-3
			for i = 1, 9 do
				if math.abs(mine[i] - t[i]) > 1e-3 then
					same = false
				end
			end
			T.ok(same, "the " .. tostring(row.name) .. " row is the script's own alignment, written the hub's way")
		end
	end
	T.eq(count, 5, "every built-in gun of the script has its row")
	local hats = {}
	for _, row in ipairs(rows) do
		if row.hat then
			hats[#hats + 1] = row.slot .. ":" .. row.hat
		end
	end
	table.sort(hats)
	T.same(hats, { "rifle:117510548336968", "rifle:131577122939956", "rifle:87566002870491", "shotgun:133919187138329", "shotgun:71041506045232" }, "the five catalog guns you asked for")
end
