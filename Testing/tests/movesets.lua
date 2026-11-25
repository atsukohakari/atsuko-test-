local World = loadmodule("Testing/mocks/rbx_world.lua")
local env = World.install({})
CFrame = loadmodule("Testing/mocks/cframe_math.lua").make(Vector3)
local makeApi = loadmodule("Testing/mocks/fake_fd.lua").make
local genv = env.genv
local UIS = game:GetService("UserInputService")
local Players = game:GetService("Players")
os.clock = function()
	return time()
end

local warns = {}
warn = function(...)
	local parts = {}
	for i = 1, select("#", ...) do
		parts[#parts + 1] = tostring((select(i, ...)))
	end
	warns[#warns + 1] = table.concat(parts, " ")
end

local reads = {}
genv.AtsukoHubRead = function(path)
	reads[#reads + 1] = path
	return readsource(path)
end
genv.AtsukoHubLocal = true

local files = {}
isfile = function(p)
	return files[p] ~= nil
end
isfolder = function()
	return true
end
makefolder = function() end
writefile = function(p, d)
	files[p] = d
end
readfile = function(p)
	return files[p]
end
getcustomasset = function(p)
	return "rbxasset://custom/" .. p
end
env.http = function(url)
	if string.find(tostring(url), "BanisherTheme.mp3", 1, true) then
		return "ID3 song"
	end
	return nil
end

local tracks = {}
local function loadAnimation(_, anim)
	local t = { Animation = anim, id = anim.AnimationId, playing = false, speed = 1, Priority = nil }
	t.KeyframeReached = game:GetService("RunService").Heartbeat
	function t.Play(me)
		me.playing = true
	end
	function t.Stop(me)
		me.playing = false
	end
	function t.Destroy(me)
		me.playing = false
		me.gone = true
	end
	function t.AdjustSpeed(me, s)
		me.speed = s
	end
	tracks[#tracks + 1] = t
	return t
end
function methods_playing()
	local out = {}
	for _, t in ipairs(tracks) do
		if t.playing then
			out[#out + 1] = t
		end
	end
	return out
end
local function playingTracks()
	local out = {}
	for _, t in ipairs(tracks) do
		if t.playing then
			out[#out + 1] = t
		end
	end
	return out
end
local function grounded(self)
	return self.Anchored == true
end
local realNew = Instance.new
Instance.new = function(class, parent)
	local o = realNew(class, parent)
	if class == "Animator" or class == "Humanoid" then
		o.LoadAnimation = loadAnimation
		o.GetPlayingAnimationTracks = playingTracks
	elseif class == "Part" then
		o.IsGrounded = grounded
	end
	return o
end

local mouse = { UnitRay = { Origin = Vector3.new(0, 3, 5), Direction = Vector3.new(0, 0, -1) } }
Players.LocalPlayer.GetMouse = function()
	return mouse
end

local dummy = Instance.new("Model")
dummy.Name = "Dummy"
local dummyRoot = Instance.new("Part")
dummyRoot.Name = "HumanoidRootPart"
dummyRoot.Parent = dummy
local dummyHum = Instance.new("Humanoid")
dummyHum.RootPart = dummyRoot
dummyHum.Parent = dummy
dummy.Parent = workspace
local floor = Instance.new("Part")
floor.Name = "Floor"
floor.Parent = workspace

local DUMMY_AT, DUMMY_R = Vector3.new(0, 3, -10), 2.5
workspace.Raycast = function(_, origin, dir)
	local len = dir.Magnitude
	if len > 1e-6 then
		local u = dir / len
		local along = (DUMMY_AT - origin):Dot(u)
		if along > 0 and along < len then
			local closest = origin + u * along
			if (closest - DUMMY_AT).Magnitude < DUMMY_R then
				return { Position = closest, Normal = -u, Instance = dummyRoot, Distance = along }
			end
		end
	end
	if dir.Y < 0 and origin.Y >= 0 and origin.Y + dir.Y <= 0 then
		local t = origin.Y / -dir.Y
		return { Position = origin + dir * t, Normal = Vector3.new(0, 1, 0), Instance = floor, Distance = t * len }
	end
	return nil
end
workspace.GetPartBoundsInBox = function()
	return { dummyRoot }
end

genv.AtsukoEmoteWeapons = { kind = function(mesh)
	if mesh == "111" then
		return "gun"
	elseif mesh == "333" then
		return "sword"
	end
	return nil
end }

genv.AtsukoAlignment = {
	match = function()
		return nil
	end,
	rows = function(script, slot)
		if slot == "bulletwords" then
			return { { words = { "golden", "shoulder", "bullet" } } }
		end
		return {}
	end,
}

local toasts, cmds, stops, ready = {}, {}, {}, 0
genv.AtsukoHub = {
	Notify = function(title, text)
		toasts[#toasts + 1] = tostring(title) .. "|" .. tostring(text)
	end,
	Commands = { register = function(list, opts)
		cmds[opts.short] = list
	end },
	OnStop = function(f)
		stops[#stops + 1] = f
	end,
	AlignReady = function()
		ready += 1
	end,
}

local function toastHas(text)
	for _, t in ipairs(toasts) do
		if string.find(t, text, 1, true) then
			return true
		end
	end
	return false
end

local function start(path, extra)
	toasts, stops, warns, tracks = {}, {}, {}, {}
	local api = makeApi()
	local flung = {}
	api.fling = function(p)
		flung[#flung + 1] = p
		return true
	end
	local w = { api = api, flung = flung }
	w.gun = { api.hat("Rifle", "111", "222", Vector3.new(0.4, 0.9, 3.2)) }
	w.sword = { api.hat("Blade", "333", "444", Vector3.new(0.3, 4, 0.8)) }
	w.arm = { api.hat("Arm Hat", "555", "", Vector3.new(1, 2, 1)) }
	w.arm[2].Part1 = api.V["Right Arm"]
	w.arm[2].C0, w.arm[2].C1 = CFrame.new(), CFrame.new()
	w.hair = { api.hat("Hair", "777", "", Vector3.new(1, 1, 1)) }
	w.bullet = { api.hat("Golden Shoulder Bullet", "888", "", Vector3.new(0.4, 0.4, 0.8)) }
	local on = true
	w.stopped = 0
	genv.AtsukoHatFd = {
		reanimate = function()
			on = true
			return api
		end,
		stopreanimate = function()
			on = false
			w.stopped += 1
		end,
		isReanimated = function()
			return on
		end,
	}
	if extra then
		extra(w, api)
	end
	local fn, err = loadstring(readsource(path), "=" .. path)
	T.ok(fn ~= nil, path .. " compiles: " .. tostring(err))
	task.spawn(function()
		local ok, e = pcall(fn)
		w.ended = { ok, e }
	end)
	env.run(0.5)
	return w
end

local function frames(w, kind, n, vel)
	w.api.vel = vel or Vector3.new()
	for _ = 1, n do
		local m = w.api.modes.default
		if m then
			m[kind or "idle"]()
		end
		env.frame()
	end
end

local press = nil
local function click(down)
	if down then
		press = { UserInputType = Enum.UserInputType.MouseButton1, UserInputState = Enum.UserInputState.Begin }
		UIS.InputBegan:Fire(press, false)
	else
		press = press or { UserInputType = Enum.UserInputType.MouseButton1 }
		press.UserInputState = Enum.UserInputState.End
		UIS.InputEnded:Fire(press, false)
		press = nil
	end
end

local function key(code)
	UIS.InputBegan:Fire({ UserInputType = Enum.UserInputType.Keyboard, KeyCode = code, UserInputState = Enum.UserInputState.Begin }, false)
	UIS.InputEnded:Fire({ UserInputType = Enum.UserInputType.Keyboard, KeyCode = code, UserInputState = Enum.UserInputState.End }, false)
end

local function stopAll(w)
	for _, f in ipairs(stops) do
		pcall(f)
	end
	frames(w, "idle", 2)
end

local function noWarns(label)
	T.eq(#warns, 0, label .. " runs without an error: " .. tostring(warns[1]))
end

local function hatWorld(w, e)
	local j = w.api.getPartJoint(e)
	return w.api.cframes[j.Part1] * j.C1 * j.C0:Inverse(), j
end

local function restOK(w)
	for _, j in ipairs(w.api.joints) do
		if j.Name == "Right Shoulder" then
			return j.C0 == CFrame.new(1, 0.5, 0)
		end
	end
	return false
end

local function cmdOf(short, id)
	for _, c in ipairs(cmds[short] or {}) do
		if c.id == id then
			return c
		end
	end
	return nil
end

local function playing(id)
	for _, t in ipairs(tracks) do
		if t.playing and string.find(t.id, id, 1, true) then
			return t
		end
	end
	return nil
end

local function fdJoint(w, name)
	for _, j in ipairs(w.api.joints) do
		if j.Name == name then
			return j
		end
	end
	return nil
end

T.section("movesets: the host loads itself through the hub")
do
	T.eq(genv.AtsukoUhh, nil)
	local w = start("Scripts/Hat/AK47.lua")
	T.ok(table.find(reads, "Hub/UhhMoveset.lua") ~= nil, "the script asked the hub for Hub/UhhMoveset.lua")
	T.ok(table.find(reads, "Hub/Moveset.lua") ~= nil, "which asked for Hub/Moveset.lua")
	local Uhh = genv.AtsukoUhh
	T.ok(type(Uhh) == "table" and Uhh.version >= 1, "and kept it for the next script")
	T.eq(#Uhh.KNOWN, 52, "it carries Uhhhhhh's whole list of known accessories")
	T.eq(Uhh.known("4615369575", "4615393635").Group, "Gun", "a gun from it")
	T.eq(Uhh.known("4307568890", "").Group, "Bullet", "and the golden bullet")
	T.eq(Uhh.known("17326476901", "").Group, "Sword")
	T.eq(Uhh.known("123", ""), nil)
	T.eq(w.ended and w.ended[1], true, "AK-47 starts without an error: " .. tostring(w.ended and w.ended[2]))
	stopAll(w)
end

T.section("movesets: pose maths of the kit")
do
	local Kit = genv.AtsukoMoveset
	local rest = Kit.rest()
	T.ok((rest.rarm.Position - Vector3.new(1.5, 0, 0)).Magnitude < 1e-6, "the right arm rests beside the torso")
	T.ok((rest.neck.Position - Vector3.new(0, 1.5, 0)).Magnitude < 1e-6, "the head on top")
	local fit, long = Kit.fit(Vector3.new(0.3, 4, 0.8))
	T.eq(long, 4, "the longest side is the length")
	T.ok(((fit * Vector3.new(0, 1, 0)) - Vector3.new(0, 0, 1)).Magnitude < 1e-6, "and it is laid along the hold")
	local Uhh = genv.AtsukoUhh
	local c1 = Uhh.gripC1(Vector3.new(0.4, 0.9, 3.2), "Gun")
	local tip = c1:Inverse() * Vector3.new(0, 0, 1.6)
	T.ok(math.abs(math.abs(tip.Y) - (1.6 - 0.65 + 1.6)) < 1e-6 or math.abs(tip.Y - (1.6 - 0.65 - 1.6)) < 1e-6, "a gun Uhhhhhh doesn't know is laid along the barrel, held near its back")
	T.eq(Uhh.digits("rbxassetid://12345"), "12345")
	T.ok(Uhh.idMatch("rbxassetid://5", "") and Uhh.idMatch("http://x?id=5", "5") and not Uhh.idMatch("", "5"), "ids match like Uhhhhhh matches them")
end

T.section("movesets: AK-47 is Uhhhhhh's own")
do
	local w = start("Scripts/Hat/AK47.lua")
	local U = genv.AtsukoAK47
	local api = w.api
	frames(w, "idle", 30)
	noWarns("AK-47")
	T.ok(toastHas("what comes before 47?") and toastHas("M1 - Shoot"), "it shows Uhhhhhh's own description")
	T.eq(U.module().Name, "AK-47")
	T.eq(U.module().InternalName, "WHATCOMESBEFORE47")
	local gun, gj = hatWorld(w, w.gun[1])
	T.eq(gj.Part1, api.V.HumanoidRootPart, "the rifle is placed by the moveset")
	T.ok((gun.Position - U.world["Right Arm"].Position).Magnitude < 3, "in the right hand")
	T.eq(w.arm[2].Part1, api.V["Right Arm"], "an arm hat stays an arm")
	T.eq(w.arm[2].C1, CFrame.new(), "and is not moved")
	T.eq(w.hair[2].Part1, api.V.Head, "other hats stay put")
	T.eq(w.sword[2].Part1, api.V.Head, "a sword is left alone while Gun = Sword is off")
	T.ok(hatWorld(w, w.bullet[1]).Position.Y < -4, "the bullet hides under you like in Uhhhhhh")
	local shoulder = fdJoint(w, "Right Shoulder")
	T.ok(shoulder.C0 ~= CFrame.new(1, 0.5, 0), "the arms take Uhhhhhh's pose")
	local AL = genv.AtsukoAlign
	T.ok(AL ~= nil and AL.title == "AK-47", "it has an alignment window")
	T.same(AL and AL.tabs, { "Gun", "Aiming", "Bullet" }, "the rifle, the rifle while aiming, and the bullet")
	T.ok(string.find(AL.found(), "Rifle", 1, true) ~= nil, "which names the hat it found: " .. AL.found())
	local m1, m2, m3 = AL.hat(2)
	T.eq(m1, "111", "the Aiming tab is about the rifle too")
	T.eq(m3, "Rifle")
	T.ok(cmdOf("ak", "sounds") and cmdOf("ak", "gunsword") and cmdOf("ak", "bulletspersecond") and cmdOf("ak", "music"), "its settings are hub commands")
	T.eq(cmdOf("ak", "gunsword").name, "Gun = Sword", "with Uhhhhhh's own names")
	T.eq(cmdOf("ak", "gunsword").desc, "Use the sword instead of the gun!", "and its own text")
	T.eq(cmdOf("ak", "gunsword").kind, "toggle")
	cmdOf("ak", "bulletspersecond").run("30")
	T.eq(U.module().BooletsPerSec, 30, "the slider sets the bullets per second")
	env.run(0.1)
	local saved = files["AtsukoHub/movesets/WHATCOMESBEFORE47.json"]
	T.ok(saved ~= nil and string.find(saved, "30", 1, true) ~= nil, "and it is saved like Uhhhhhh saves it")
	click(true)
	frames(w, "idle", 20)
	T.ok(#w.flung > 0, "holding click shoots and flings what it hits")
	T.ok((hatWorld(w, w.bullet[1]).Position - DUMMY_AT).Magnitude < 3 or hatWorld(w, w.bullet[1]).Position.Z < -0.5, "and the bullet flies with the shots")
	local turns = #api.moved
	mouse.UnitRay = { Origin = Vector3.new(0, 3, 0), Direction = Vector3.new(1, 0, -1).Unit }
	frames(w, "idle", 5)
	T.ok(#api.moved > turns, "shooting to the side turns you toward it")
	local look = api.cframes[api.V.HumanoidRootPart].LookVector
	T.ok(look.X > 0.3, "the way Uhhhhhh's AK turns you")
	mouse.UnitRay = { Origin = Vector3.new(0, 3, 5), Direction = Vector3.new(0, 0, -1) }
	api.cframes[api.V.HumanoidRootPart] = CFrame.new(0, 3, 0)
	frames(w, "idle", 5)
	local plain = hatWorld(w, w.gun[1])
	T.eq(AL.set(2, 2, 1), 1, "the Aiming tab moves")
	frames(w, "idle", 30)
	local aimed = hatWorld(w, w.gun[1])
	T.ok((aimed.Position - plain.Position).Magnitude > 0.5, "the rifle while you shoot")
	click(false)
	frames(w, "idle", 30)
	local n = #w.flung
	frames(w, "idle", 10)
	T.eq(#w.flung, n, "letting go stops shooting")
	local idle = hatWorld(w, w.gun[1])
	AL.set(2, 2, 0)
	frames(w, "idle", 3)
	T.ok((hatWorld(w, w.gun[1]).Position - idle.Position).Magnitude < 0.05, "Aiming does nothing when you don't shoot")
	local realMatch = genv.AtsukoAlignment.match
	genv.AtsukoAlignment.match = function(script, slot, hat)
		if script == "AK-47" and slot == "gun" and hat.mesh == "777" then
			return { slot = "gun", mesh = "777", src = "user", align = { 0, 0, 0, 0, 0, 0 } }
		end
		return nil
	end
	genv.AtsukoAlignment.rev = 2
	frames(w, "idle", 40)
	T.eq(w.hair[2].Part1, api.V.HumanoidRootPart, "a hat you add as the gun while it runs is held too")
	genv.AtsukoAlignment.match = realMatch
	genv.AtsukoAlignment.rev = 3
	frames(w, "idle", 40)
	T.eq(w.hair[2].Part1, api.V.Head, "and let go when you take it out again")
	cmdOf("ak", "gunsword").run(nil, { state = true })
	frames(w, "idle", 5)
	T.eq(w.sword[2].Part1, api.V.HumanoidRootPart, "Gun = Sword holds the sword instead")
	T.eq(w.gun[2].Part1, api.V.Head, "and puts the rifle back")
	cmdOf("ak", "gunsword").run(nil, { state = false })
	genv.AtsukoEmotes = { playing = function()
		return "Dance"
	end }
	frames(w, "idle", 5)
	T.eq(w.gun[2].Part1, api.V.Head, "while dancing the gun goes back, so the dance can use it")
	genv.AtsukoEmotes = nil
	frames(w, "walk", 20, Vector3.new(0, 0, -16))
	noWarns("AK-47 walking")
	local doll = U.model
	stopAll(w)
	T.ok(restOK(w), "stopping puts the arms back")
	T.eq(w.gun[2].Part1, api.V.Head, "and the gun hat")
	T.eq(w.bullet[2].Part1, api.V.Head, "and the bullet")
	T.eq(doll.Parent, nil, "and removes the stand-in body")
	T.eq(genv.AtsukoAK47, nil)
	T.eq(genv.AtsukoAlign, nil, "and closes its alignment window")
	T.eq(w.stopped, 1, "the hub's stop ends the reanimation")
	noWarns("AK-47 stopping")
end

T.section("movesets: R6 is Uhhhhhh's 2015 Roblox")
do
	local w = start("Scripts/Hat/R6.lua")
	local U = genv.AtsukoR6
	frames(w, "idle", 10)
	noWarns("R6")
	T.eq(U.module().Name, "2015 Roblox", "it is the 2015 Roblox moveset")
	T.ok(toastHas("Li'l Programmer Timmy"), "with its own description")
	T.eq(genv.AtsukoAlign, nil, "it uses no hats, so no alignment window")
	T.eq(w.gun[2].Part1, w.api.V.Head, "and leaves every hat alone")
	T.ok(playing("180435571") or playing("180435792"), "it plays the 2015 idle animation")
	frames(w, "walk", 10, Vector3.new(0, 0, -16))
	local walk = playing("180426354")
	T.ok(walk ~= nil, "the 2015 walk")
	T.ok(walk and math.abs(walk.speed - 16 / 14.5) < 1e-6, "at the speed you walk")
	frames(w, "jump", 3, Vector3.new(0, 40, 0))
	T.ok(playing("125750702") ~= nil, "the jump")
	frames(w, "fall", 15, Vector3.new(0, -40, 0))
	T.ok(playing("180436148") ~= nil, "the fall")
	frames(w, "idle", 5)
	T.ok(playing("180435571") or playing("180435792"), "and back to idle when you land")
	local snd = U.parts.HumanoidRootPart:FindFirstChild("rbxcharactersounds")
	T.eq(snd and #snd:GetChildren(), 8, "with the old character sounds")
	local motor = U.parts.Torso:FindFirstChild("Right Shoulder")
	motor.Transform = CFrame.Angles(0, 0, 1)
	frames(w, "idle", 1)
	local want = motor.C0 * CFrame.Angles(0, 0, 1) * motor.C1:Inverse() * CFrame.new(-0.5, 0.5, 0)
	local got = fdJoint(w, "Right Shoulder").C0
	T.ok((got.Position - want.Position).Magnitude < 1e-6 and (got.LookVector - want.LookVector).Magnitude < 1e-6, "what the animation does to the stand-in body is what your body does")
	genv.AtsukoEmotes = { playing = function()
		return "Dance"
	end }
	frames(w, "idle", 2)
	T.eq(#methods_playing(), 0, "a hub emote stops its animations")
	genv.AtsukoEmotes = nil
	frames(w, "idle", 10)
	frames(w, "walk", 5, Vector3.new(0, 0, -16))
	T.ok(playing("180426354") ~= nil, "and they come back after")
	stopAll(w)
	T.ok(restOK(w))
	T.eq(genv.AtsukoR6, nil)
	noWarns("R6 stopping")
end

T.section("movesets: Linked Sword is Uhhhhhh's own")
do
	local w = start("Scripts/Hat/LinkedSword.lua")
	local U = genv.AtsukoLinkedSword
	local api = w.api
	frames(w, "idle", 30)
	noWarns("Linked Sword")
	T.ok(toastHas("He has been fighting since 2006!"), "it shows Uhhhhhh's own description")
	local sword, sj = hatWorld(w, w.sword[1])
	T.eq(sj.Part1, api.V.HumanoidRootPart, "the sword hat is in use")
	T.ok((sword.Position - U.world["Right Arm"].Position).Magnitude < 4, "in the right hand")
	T.eq(w.gun[2].Part1, api.V.Head, "the bazooka waits where you wear it")
	T.ok(hatWorld(w, w.bullet[1]).Position.Y < -10, "and the bullet hides under you")
	T.same(genv.AtsukoAlign.tabs, { "Sword", "Bazooka", "Bullet" })
	click(true)
	frames(w, "idle", 2)
	click(false)
	frames(w, "idle", 20)
	T.ok(#w.flung > 0, "a click slashes and flings who it hits")
	local n = #w.flung
	key(Enum.KeyCode.Z)
	frames(w, "idle", 30)
	T.ok(#w.flung > n, "Z throws the superball")
	key(Enum.KeyCode.X)
	frames(w, "idle", 15)
	local gun, gjn = hatWorld(w, w.gun[1])
	T.eq(gjn.Part1, api.V.HumanoidRootPart, "X takes out the bazooka")
	T.ok((gun.Position - U.world["Left Arm"].Position).Magnitude < 4, "on the left arm")
	frames(w, "idle", 90)
	T.eq(w.gun[2].Part1, api.V.Head, "and puts it back after the rocket")
	key(Enum.KeyCode.C)
	frames(w, "idle", 120)
	noWarns("Linked Sword skills")
	Players.LocalPlayer.Chatted:Fire("hello there")
	frames(w, "idle", 3)
	local dialog = U.parts.Torso:FindFirstChild("NOTIFICATION")
	T.ok(dialog ~= nil, "what you say shows over your head")
	frames(w, "idle", 30)
	T.eq(dialog and dialog:FindFirstChildOfClass("TextLabel").Text, "hello there", "letter by letter")
	T.ok(cmdOf("ls", "dialog") and cmdOf("ls", "nocooldown") and cmdOf("ls", "ignoredancing") and cmdOf("ls", "hitboxvisual"), "its switches are hub commands")
	T.ok(cmdOf("ls", "superball") and cmdOf("ls", "rocketlauncher") and cmdOf("ls", "timebomb"), "and so are its keys, named like Uhhhhhh names them")
	T.eq(cmdOf("ls", "superball").desc, "Z - Superball")
	T.eq(cmdOf("ls", "linkedsword"), nil, "the click is not a command, a tap does it")
	local before = #w.flung
	frames(w, "idle", 60)
	cmdOf("ls", "superball").run()
	frames(w, "idle", 30)
	T.ok(#w.flung > before, "the superball command throws it")
	frames(w, "idle", 60)
	before = #w.flung
	local touch = { UserInputType = Enum.UserInputType.Touch, UserInputState = Enum.UserInputState.Begin }
	UIS.InputBegan:Fire(touch, false)
	touch.UserInputState = Enum.UserInputState.End
	UIS.InputEnded:Fire(touch, false)
	frames(w, "idle", 20)
	T.ok(#w.flung > before, "a tap on a phone slashes")
	local pad = false
	for _, g in ipairs(game:GetService("CoreGui"):GetDescendants()) do
		if g:IsA("ImageButton") and g.Image == "https://www.roblox.com/asset/?id=97166444" then
			pad = true
		end
	end
	T.eq(pad, false, "no button pad shows up")
	stopAll(w)
	T.ok(restOK(w))
	T.eq(w.sword[2].Part1, api.V.Head)
	T.eq(genv.AtsukoLinkedSword, nil)
	noWarns("Linked Sword stopping")
end

T.section("movesets: Banisher is Uhhhhhh's own")
do
	local w = start("Scripts/Hat/Banisher.lua")
	local U = genv.AtsukoBanisher
	local api = w.api
	frames(w, "idle", 30)
	noWarns("Banisher")
	T.ok(toastHas("hes a very tuff CLANKER"), "it shows Uhhhhhh's own description")
	T.ok(files["UhhhhhhReanim/Content/Sounds/BanisherTheme.mp3"] ~= nil, "the theme is downloaded into the Uhhhhhh folder")
	local song = U.K.fxFolder:FindFirstChild("MovesetMusic")
	T.ok(song ~= nil and string.find(song.SoundId, "BanisherTheme.mp3", 1, true) ~= nil and song.Looped == true, "and plays on a loop")
	T.eq(w.gun[2].Part1, api.V.Head, "the gun waits where you wear it")
	click(true)
	frames(w, "idle", 2)
	click(false)
	frames(w, "idle", 30)
	T.ok(#w.flung > 0, "a click hits")
	key(Enum.KeyCode.F)
	frames(w, "idle", 30)
	local gun, gj = hatWorld(w, w.gun[1])
	T.eq(gj.Part1, api.V.HumanoidRootPart, "F takes the gun out")
	T.ok((gun.Position - U.world["Right Arm"].Position).Magnitude < 4, "into your hand")
	local n = #w.flung
	click(true)
	frames(w, "idle", 2)
	click(false)
	frames(w, "idle", 30)
	T.ok(#w.flung > n, "and a click shoots")
	key(Enum.KeyCode.LeftControl)
	frames(w, "walk", 5, Vector3.new(0, 0, -16))
	T.ok(api.ws ~= nil and api.ws > 16, "Left Ctrl runs")
	key(Enum.KeyCode.LeftControl)
	local moved = #api.moved
	UIS.IsKeyDown = function(_, k)
		return k == Enum.KeyCode.Space
	end
	frames(w, "fall", 40, Vector3.new(0, -5, 0))
	UIS.IsKeyDown = nil
	T.ok(#api.moved > moved and U.state.extra.Y > 0, "holding jump in the air flies with the rocket boots")
	frames(w, "idle", 5)
	T.eq(U.state.extra, Vector3.new(), "and landing ends it")
	cmdOf("ban", "music").run(nil, { state = false })
	T.ok(toastHas("Music off"), "the theme can be turned off")
	T.ok(cmdOf("ban", "tuff") and cmdOf("ban", "camerafly") and cmdOf("ban", "useswordinsteadofgun"), "its switches are hub commands")
	T.ok(cmdOf("ban", "secondaryattack") and cmdOf("ban", "holsterunholstergun") and cmdOf("ban", "run"), "and its keys")
	T.eq(cmdOf("ban", "run").desc, "Left Ctrl - Run")
	cmdOf("ban", "holsterunholstergun").run()
	frames(w, "idle", 30)
	T.eq(w.gun[2].Part1, api.V.Head, "holster puts the gun away")
	noWarns("Banisher skills")
	stopAll(w)
	T.ok(restOK(w))
	T.eq(w.gun[2].Part1, api.V.Head, "the gun goes back")
	T.eq(genv.AtsukoBanisher, nil)
	T.eq(song.Parent, nil, "and the theme stops with it")
	T.eq(api.ws, 16, "and you walk at the normal speed again")
	noWarns("Banisher stopping")
end

T.section("movesets: Uhhhhhh's accessories")
do
	local w = start("Scripts/Hat/AK47.lua")
	local api = w.api
	local cannon = { api.hat("VoidAlligatorJaw copy", "77229698901212", "128016353776496", Vector3.new(1, 1, 5)) }
	local rpg = { api.hat("VoidRPG copy", "76443789550926", "128016353776496", Vector3.new(1, 1, 3)) }
	local wing = { api.hat("Wing", "5486588848", "1", Vector3.new(1, 3, 3)) }
	local U = genv.AtsukoAK47
	U.rescan()
	frames(w, "idle", 10)
	T.eq(cannon[2].Part1, api.V.HumanoidRootPart, "a gun Uhhhhhh knows is held")
	T.eq(rpg[2].Part1, api.V.HumanoidRootPart, "with its other half")
	local a, b = hatWorld(w, cannon[1]), hatWorld(w, rpg[1])
	local data1, data2 = genv.AtsukoUhh.known("77229698901212", ""), genv.AtsukoUhh.known("76443789550926", "")
	local want = a * data1.C1 * data2.C1:Inverse()
	T.ok((want.Position - b.Position).Magnitude < 1e-4, "the two halves sit together like in Uhhhhhh")
	T.eq(w.gun[2].Part1, api.V.Head, "a gun only guessed from its name steps aside for one Uhhhhhh knows")
	local wingCF = hatWorld(w, wing[1])
	local data = genv.AtsukoUhh.known("5486588848", "")
	local wantWing = U.world.Torso * data.C0 * data.C1:Inverse()
	T.ok((wingCF.Position - wantWing.Position).Magnitude < 1e-4, "wings go on your back where Uhhhhhh puts them")
	stopAll(w)
	T.eq(cannon[2].Part1, api.V.Head)
	T.eq(wing[2].Part1, api.V.Head)
end

T.section("movesets: the hub knows their hats")
do
	local ui = loadmodule("Hub/modules/alignment_ui.lua")
	local jobs = {}
	for _, row in ipairs(ui.JOBS) do
		jobs[row[1]] = table.concat(row[2], ",")
	end
	T.eq(jobs["AK-47"], "gun,bullet")
	T.eq(jobs["Banisher"], "gun,bullet")
	T.eq(jobs["Linked Sword"], "sword,gun,bullet")
	local manifest = game:GetService("HttpService"):JSONDecode(readsource("Scripts/manifest.json"))
	for path, name in pairs({ ["Scripts/Hat/AK47.lua"] = "AK-47", ["Scripts/Hat/R6.lua"] = "R6", ["Scripts/Hat/LinkedSword.lua"] = "Linked Sword", ["Scripts/Hat/Banisher.lua"] = "Banisher" }) do
		local e = manifest.scripts[path]
		T.ok(e ~= nil and e.name == name, name .. " is listed")
		T.same(e and e.reanim, { "atsuko", "fdless" }, name .. " runs on both reanimations")
		T.same(e and e.credit, { "STEVETHEREALONE" }, name .. " credits Uhhhhhh's author")
	end
end

T.section("movesets: a body part is never taken as a gun")
do
	local head = nil
	local w = start("Scripts/Hat/AK47.lua", function(w0, api)
		head = { api.hat("Head Piece", "4615369575", "4615393635", Vector3.new(1, 1, 1)) }
		head[2].C0, head[2].C1 = CFrame.new(), CFrame.new()
		api.rigHat = function(e)
			if e == head[1] then
				return "Head"
			end
			return nil
		end
	end)
	frames(w, "idle", 8)
	T.eq(head[2].Part1, w.api.V.Head, "the rig's head stays the head even though Uhhhhhh knows it as a gun")
	T.eq(head[2].C0, CFrame.new(), "and doesn't move")
	T.ok(w.gun[2].Part1 ~= w.api.V.Head, "the gun is a hat that isn't a body part")
	noWarns("AK-47 with a head that looks like a gun")
	stopAll(w)
	local savedMatch, savedWeapon = genv.AtsukoAlignment.match, genv.AtsukoAlignment.weapon
	genv.AtsukoAlignment.weapon = function(hat)
		return hat.mesh == "4615369575"
	end
	genv.AtsukoAlignment.match = function(_, slot, hat)
		if slot == "gun" and hat.mesh == "4615369575" then
			return { src = "user", slot = "gun" }
		end
		return nil
	end
	local w2 = start("Scripts/Hat/AK47.lua", function(w0, api)
		head = { api.hat("Head Piece", "4615369575", "4615393635", Vector3.new(1, 1, 1)) }
		head[2].C0, head[2].C1 = CFrame.new(), CFrame.new()
		api.rigHat = function(e)
			if e == head[1] then
				return "Head"
			end
			return nil
		end
	end)
	frames(w2, "idle", 8)
	T.ok(head[2].Part1 ~= w2.api.V.Head, "a hat you added as the gun is the gun, even if the rig still had it")
	stopAll(w2)
	genv.AtsukoAlignment.match, genv.AtsukoAlignment.weapon = savedMatch, savedWeapon
	T.eq(head[2].Part1, w2.api.V.Head, "and goes back when the script stops")
end
