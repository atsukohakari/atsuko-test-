local World = loadmodule("Testing/mocks/rbx_world.lua")
local env = World.install({})
CFrame = loadmodule("Testing/mocks/cframe_math.lua").make(Vector3)
local makeApi = loadmodule("Testing/mocks/fake_fd.lua").make
local genv = env.genv
local PATH = "Scripts/Hat/BanHammer.lua"
local SRC = readsource(PATH)
local MESH, TEX = "14463205245", "14463205530"

local toasts = {}
genv.AtsukoNotify = function(title, text, kind)
	toasts[#toasts + 1] = tostring(title) .. "|" .. tostring(text) .. "|" .. tostring(kind)
end
_G.delay = function(t, f)
	return task.delay(t, f)
end

local function toastWith(text)
	for _, t in ipairs(toasts) do
		if string.find(t, text, 1, true) then
			return t
		end
	end
	return nil
end

local function withMesh(api)
	function api.getPartFromMesh(m, t)
		for e in pairs(api.cframes) do
			if type(e) == "table" and rawget(e, "m") and string.find(e.m, tostring(m), 1, true) and string.find(e.t, tostring(t), 1, true) then
				return e
			end
		end
		local e = { m = tostring(m), t = tostring(t) }
		e.j = { C0 = CFrame.new(), C1 = CFrame.new(), Part0 = e }
		api.cframes[e] = CFrame.new()
		api.joints[#api.joints + 1] = e.j
		return e
	end
	local old = api.getPartJoint
	function api.getPartJoint(e)
		if type(e) == "table" and rawget(e, "j") then
			return e.j
		end
		return old(e)
	end
	return api
end

local function near(a, b, eps)
	return math.abs(a - b) < (eps or 1e-4)
end

local function sameCF(a, b, eps)
	local pa, pb = a.Position, b.Position
	if not (near(pa.X, pb.X, eps) and near(pa.Y, pb.Y, eps) and near(pa.Z, pb.Z, eps)) then
		return false
	end
	local la, lb = a.LookVector, b.LookVector
	local ua, ub = a.UpVector, b.UpVector
	return near(la.X, lb.X, eps) and near(la.Y, lb.Y, eps) and near(la.Z, lb.Z, eps) and near(ua.X, ub.X, eps) and near(ua.Y, ub.Y, eps) and near(ua.Z, ub.Z, eps)
end

local function run(opts)
	opts = opts or {}
	local S = { on = false }
	genv.AtsukoBanHammer = nil
	genv.AtsukoHatFd = nil
	genv.LumenReanim = nil
	local function reanimate()
		S.on = true
		local api = withMesh(makeApi())
		S.api = api
		if not opts.noHammer then
			S.hammer, S.weld = api.hat("Ban Hammer", MESH, TEX)
		end
		return api
	end
	if opts.standalone then
		local current = {}
		genv.LumenReanim = {
			rig = function()
				return {
					reanimate = function()
						current.on = true
						return reanimate()
					end,
					stopreanimate = function()
						S.on = false
					end,
				}
			end,
			current = function()
				return S.on and current or nil
			end,
		}
	else
		genv.AtsukoHatFd = {
			reanimate = reanimate,
			stopreanimate = function()
				S.on = false
			end,
			isReanimated = function()
				return S.on
			end,
		}
	end
	local fn, err = loadstring(SRC, "=" .. PATH)
	S.compiled, S.err = fn ~= nil, err
	task.spawn(function()
		local ok, e = pcall(fn)
		S.ended = { ok, e }
	end)
	env.run(opts.wait or 0.2)
	S.BH = genv.AtsukoBanHammer
	function S.frames(n, mode, state)
		for _ = 1, n do
			local m = S.api and S.api.modes[mode or "default"]
			if m and m[state or "idle"] then
				m[state or "idle"]()
			end
			env.frame()
		end
	end
	return S
end

local function sounds()
	local list = {}
	for _, d in ipairs(env.workspace:GetChildren()) do
		if d:IsA("Sound") then
			list[#list + 1] = d
		end
	end
	return list
end

local function guiNamed(name)
	for _, d in ipairs(env.hui:GetChildren()) do
		if d.Name == name then
			return d
		end
	end
	return nil
end

T.section("ban_hammer: the file")
T.ok(loadstring(SRC, "=" .. PATH) ~= nil, "compiles")
T.eq(string.find(SRC, "--", 1, true), nil, "the script is only code, no comments")
T.eq(string.find(SRC, "01_server", 1, true) ~= nil, true, "it still knows the game's hat command")
T.eq(string.find(SRC, "GelatekReanimate", 1, true), nil, "the built-in Gelatek reanimate is gone")
T.eq(string.find(SRC, "replicatesignal", 1, true), nil, "and nothing of it is left")
T.eq(string.find(SRC, "SendNotification", 1, true), nil, "no grey Roblox pop-ups")

T.section("ban_hammer: runs on the hub's reanimation")
local S = run()
T.ok(S.compiled, "compiles: " .. tostring(S.err))
T.ok(S.api ~= nil, "reanimated through the hub")
T.ok(S.BH ~= nil and S.BH.onHub == true, "on the hub's body")
T.eq(S.ended and S.ended[1], true, "the start finished without an error: " .. tostring(S.ended and S.ended[2]))
for _, key in ipairs({ "default", "r", "e", "q" }) do
	local m = S.api and S.api.modes[key]
	T.ok(m ~= nil, "mode " .. key .. " is added")
	if m then
		for _, state in ipairs({ "idle", "walk", "jump", "fall", "modeEntered" }) do
			T.eq(type(m[state]), "function", key .. " has " .. state)
		end
	end
end
env.run(3.5)
T.ok(toastWith("Click to swing") ~= nil, "the start notice says how to play: " .. table.concat(toasts, " / "))
T.eq(toastWith("Wear the Ban Hammer"), nil, "and doesn't ask for the hat it already has")

T.section("ban_hammer: the poses are Tory's numbers")
do
	local P = S.BH.poses
	local sine = 1.25
	local idle = P.default.idle.pose(sine)
	local want = CFrame.new(0, -0.15 + (0.2 * math.sin(sine * 2)), 0) * CFrame.Angles(-1.3962634015954636 + (0.08726646259971647 * math.sin((sine + 0.75) * -2)), 0, 3.141592653589793)
	T.ok(sameCF(idle.RootJoint, want), "default idle root, straight from the original")
	local walk = P.default.walk.pose(sine)
	local lh = CFrame.new(-1.075 + (0.5 * math.sin((sine + 0.275) * -14)), -0.95 + (1 * math.sin((sine + 0.075) * -14)), -0.25 + (1 * math.sin((sine + 0.275) * -14))) * CFrame.Angles(0, -1.2217304763960306 + (0.2181661564992912 * math.sin((sine + 0.1) * -14)), 2.0943951023931953 * math.sin((sine - 0.025) * 14))
	T.ok(sameCF(walk["Left Hip"], lh), "default walk left leg")
	local ridle = P.r.idle.pose(sine)
	T.ok(sameCF(ridle.RootJoint, CFrame.new(0.2 * math.sin((sine + 1.5) * 2), 2.5 + (0.4 * math.sin(sine * 2)), 0.5 * math.sin((sine + 0.5) * 2)) * CFrame.Angles(-1.7453292519943295 + (0.08726646259971647 * math.sin(sine * 2)), 0.08726646259971647 + (0.08726646259971647 * math.sin((sine + 0.5) * 2)), 2.9670597283903604)), "r mode floats")
	for _, mode in ipairs({ "default", "r", "e", "q" }) do
		for _, state in ipairs({ "idle", "walk", "jump", "fall" }) do
			local pose = P[mode][state].pose(0.5)
			local n = 0
			for _, name in ipairs({ "RootJoint", "Neck", "Right Shoulder", "Left Shoulder", "Right Hip", "Left Hip", "Hammer" }) do
				if typeof(pose[name]) == "CFrame" then
					n += 1
				end
			end
			T.eq(n, 7, mode .. " " .. state .. " moves all seven joints")
		end
	end
	T.eq(#S.BH.attacks.light, 2, "the light swing has two steps")
	T.eq(#S.BH.attacks.heavy, 2, "and so does the heavy one")
	T.eq(S.BH.attacks.light[1].hold + S.BH.attacks.light[2].hold, 0.5, "the light swing takes half a second")
	T.eq(S.BH.attacks.heavy[1].hold + S.BH.attacks.heavy[2].hold, 0.7, "the heavy one 0.7")
end

T.section("ban_hammer: speeds and joints")
do
	S.frames(1, "default", "idle")
	T.eq(S.api.ws, 16, "default idle walks at 16")
	T.eq(S.api.jp, 0, "and doesn't jump")
	S.frames(1, "default", "walk")
	T.eq(S.api.ws, 45, "default walk runs at 45")
	S.frames(1, "r", "walk")
	T.eq(S.api.ws, 135, "r runs at 135")
	S.frames(1, "e", "idle")
	T.eq(S.api.ws, 24, "e walks at 24")
	T.eq(S.api.jp, 125, "and jumps at 125")
	S.frames(1, "q", "fall")
	T.eq(S.api.ws, 16, "q at 16")
	T.eq(S.api.jp, 50, "jumping 50")
	S.frames(90, "default", "idle")
	local root = S.api.getJoint("RootJoint")
	local goal = S.BH.poses.default.idle.pose(os.clock())
	T.ok(sameCF(root.C0, goal.RootJoint, 0.05), "after a few seconds the body sits in the idle pose")
	T.ok(sameCF(S.weld.C0, goal.Hammer, 0.05), "and the hammer is held where Tory put it")
end

T.section("ban_hammer: clicking swings")
do
	S.api.modes.default.modeEntered()
	T.eq(S.BH.isHeavy(), false, "default mode swings light")
	local before = #sounds()
	env.uis.InputBegan:Fire({ UserInputType = Enum.UserInputType.MouseButton1 }, true)
	env.frame()
	T.eq(S.BH.attacking(), nil, "a click on a button doesn't swing")
	env.uis.InputBegan:Fire({ UserInputType = Enum.UserInputType.MouseButton1 }, false)
	env.frame()
	T.ok(S.BH.attacking() == S.BH.attacks.light[1], "a click swings")
	T.eq(#sounds(), before + 1, "with its sound")
	S.frames(8, "default", "idle")
	T.ok(S.BH.attacking() == S.BH.attacks.light[2], "then the second step")
	S.frames(12, "default", "idle")
	T.eq(S.BH.attacking(), nil, "and it's over after half a second")
	env.run(2.5)
	T.eq(#sounds(), before, "the swing sound is cleaned up")
	S.api.modes.q.modeEntered()
	T.eq(S.BH.isHeavy(), true, "q swings heavy")
	S.api.ws = 0
	env.uis.InputBegan:Fire({ UserInputType = Enum.UserInputType.Touch }, false)
	env.frame()
	T.ok(S.BH.attacking() == S.BH.attacks.heavy[1], "a tap swings too")
	S.frames(2, "q", "walk")
	T.eq(S.api.ws, 16, "a heavy swing slows you to 16")
	S.frames(30, "q", "walk")
	T.eq(S.BH.attacking(), nil, "and ends")
	S.api.modes.default.modeEntered()
end

T.section("ban_hammer: the name tag and the theme")
do
	local tag = guiNamed("BanHammerTag")
	T.ok(tag ~= nil, "the name tag is up")
	T.eq(tag and tag:FindFirstChildOfClass("TextLabel").Text, "Exotic Ban Hammer Modded By Tory", "and says who made it")
	S.frames(1, "default", "idle")
	local head = S.api.cframes[S.api.getPart("Head")]
	T.ok(tag and sameCF(CFrame.new(tag.StudsOffsetWorldSpace), CFrame.new(head.Position)), "it follows the head")
	local music = nil
	for _, s in ipairs(sounds()) do
		if s.SoundId == "rbxassetid://15689446096" then
			music = s
		end
	end
	T.ok(music ~= nil and music.Looped == true and music.Playing == true, "the theme plays on a loop")
	T.ok(guiNamed("BanHammerUI") ~= nil, "the little text box is there")
end

T.section("ban_hammer: stopping cleans everything up")
do
	local root = S.api.getJoint("RootJoint")
	S.on = false
	env.run(0.2)
	T.eq(S.BH.alive(), false, "it stops when the reanimation stops")
	T.eq(genv.AtsukoBanHammer, nil, "and lets go of its handle")
	T.eq(#sounds(), 0, "the theme stops")
	T.eq(guiNamed("BanHammerTag"), nil, "the name tag goes")
	T.eq(guiNamed("BanHammerUI"), nil, "and the text box")
	T.ok(sameCF(root.C0, CFrame.new()), "the joints go back")
	local ws = S.api.ws
	S.frames(3, "r", "walk")
	T.eq(S.api.ws, ws, "a stopped hammer doesn't move anything")
	env.uis.InputBegan:Fire({ UserInputType = Enum.UserInputType.MouseButton1 }, false)
	env.frame()
	T.eq(S.BH.attacking(), nil, "or swing")
end

T.section("ban_hammer: without the hat")
do
	toasts = {}
	local N = run({ noHammer = true })
	T.ok(N.BH ~= nil, "it still runs")
	env.run(3.5)
	T.ok(toastWith("Wear the Ban Hammer (catalog 14464140694)") ~= nil, "and says which hat to wear: " .. table.concat(toasts, " / "))
	N.frames(5, "default", "walk")
	T.eq(N.api.ws, 45, "the body still moves")
	N.BH.stop()
	env.run(0.2)
end

T.section("ban_hammer: on its own, without the hub")
do
	toasts = {}
	local L = run({ standalone = true, wait = 0.5 })
	T.ok(L.api ~= nil, "it reanimates with Script Reanimate itself")
	T.ok(L.BH ~= nil and L.BH.onHub == false, "not on the hub")
	T.eq(L.ended and L.ended[1], true, "started fine: " .. tostring(L.ended and L.ended[2]))
	L.frames(3, "default", "idle")
	T.eq(L.api.ws, 16, "and moves")
	L.BH.stop()
	env.run(0.2)
	T.eq(#sounds(), 0, "stop cleans up there too")
end

T.section("ban_hammer: the game's hat command")
do
	local rs = game:GetService("ReplicatedStorage")
	local remote = env.newInstance("RemoteEvent")
	remote.Name = "01_server"
	remote.Parent = rs
	local sent = {}
	remote.FireServer = function(_, kind, text)
		sent[#sent + 1] = tostring(kind) .. " " .. tostring(text)
		if text == "-gh 14464140694" then
			local acc = Instance.new("Accessory")
			acc.Name = "Ban Hammer"
			acc.Parent = env.lp.Character
		end
	end
	local H = run()
	T.eq(#sent, 0, "on the hub it never sends the game a command, the hub already reanimated")
	H.BH.stop()
	env.run(0.2)
	local L = run({ standalone = true, wait = 10 })
	T.eq(sent[1], "cmd -r6", "on its own it asks the game for R6 first, like the original")
	T.eq(sent[2], "cmd -gh 14464140694", "then for the Ban Hammer")
	T.eq(#sent, 2, "and nothing else")
	T.ok(L.api ~= nil, "then it reanimates")
	if L.BH then
		L.BH.stop()
	end
	env.run(0.2)
	remote.Parent = nil
end

T.section("ban_hammer: in the manifest and the credits")
do
	local manifest = jsondecode(readsource("Scripts/manifest.json"))
	local m = manifest.scripts[PATH]
	T.ok(m ~= nil, "listed in the manifest")
	T.eq(m and m.name, "Ban Hammer")
	T.eq(m and m.kind, "hat")
	T.same(m and m.reanim, { "atsuko", "fdless" }, "runs on Script Reanimate and FDless")
	T.same(m and m.credit, { "Tory" }, "made by Tory")
	T.eq(m and m.needsfd, nil, "it uses the hub's body, no FDless copy of its own")
	local credits = jsondecode(readsource("Hub/credits.json"))
	local tory = nil
	for _, p in ipairs(credits.people) do
		if p.id == "tory" then
			tory = p
		end
	end
	T.ok(tory ~= nil and table.find(tory.usedIn, "Hat / Ban Hammer") ~= nil, "Tory's credits list the Ban Hammer")
	T.ok(tory ~= nil and table.find(tory.roles, "Exotic Ban Hammer author") ~= nil, "as its author")
end

genv.AtsukoHatFd = nil
genv.LumenReanim = nil
genv.AtsukoBanHammer = nil
