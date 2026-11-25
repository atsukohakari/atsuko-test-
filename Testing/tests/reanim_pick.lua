local Runner = loadmodule("Testing/mocks/boot_runner.lua")

local function all(root, pred)
	local out = {}
	for _, d in ipairs(root:GetDescendants()) do
		if pred(d) then
			out[#out + 1] = d
		end
	end
	return out
end

local function named(root, name)
	return all(root, function(d)
		return d.Name == name
	end)
end

local function hasText(root, text)
	return #all(root, function(d)
		return (d:IsA("TextLabel") or d:IsA("TextButton")) and d.Text == text
	end) > 0
end

local function errorsOf(env)
	local out = {}
	for _, item in ipairs(env.hub.Log.items or {}) do
		if item.kind == "error" then
			out[#out + 1] = tostring(item.src) .. ": " .. tostring(item.msg)
		end
	end
	return out
end

local env = Runner.boot({ seconds = 8 })

local hub, core = env.hub, env.core
local S = hub.S
local R = core.Reanim
for _ = 1, 60 do
	if R.reg then
		break
	end
	env.run(0.5)
end

T.section("reanim_pick: a fresh start has no hat reanimation picked")
T.ok(R.reg ~= nil, "the reanimation registry loaded")
T.ok(R.reg:get("atsuko") ~= nil, "Script Reanimate loaded in the real boot: " .. tostring(R.reg.failed.atsuko))
T.ok(R.reg:get("fdless") ~= nil, "FDless loaded in the real boot: " .. tostring(R.reg.failed.fdless))
T.eq(S.hatReanim, "", "nothing is picked")
T.eq(S.reanimLimb, "gelatek", "the limb one keeps its default")
T.eq(R.reg:selected("hat"), nil)
T.eq(R.needsPick("hat"), true)
T.eq(type(core.askReanim), "function")

T.section("reanim_pick: the pick window")
do
	local after = 0
	local shown = core.askReanim("hat", function()
		after = after + 1
	end)
	env.run(0.5)
	T.eq(shown, true, "the window opens")
	T.eq(hub.Win.isOpen("reanimpick"), true)
	local root = hub.Root or hub.Gui
	local atsuko = named(root, "Pick_atsuko")[1]
	local fdless = named(root, "Pick_fdless")[1]
	T.ok(atsuko ~= nil and fdless ~= nil, "it has a card for each hat reanimation")
	T.eq(#named(root, "Pick_unified"), 0, "and none for the removed unified one")
	T.eq(#named(root, "Pick_gelatek"), 0, "and none for the limb ones")
	if atsuko and fdless then
		T.ok(hasText(atsuko, "Script Reanimate"), "the card says its name")
		T.ok(hasText(fdless, "FDless"), "the card says its name")
		fdless.Activated:Fire()
		env.run(0.5)
		T.eq(S.hatReanim, "fdless", "tapping a card is the pick")
		T.eq(hub.Win.isOpen("reanimpick"), false, "the window closes")
		T.eq(after, 1, "and what was waiting for the pick goes on")
		T.eq(R.reg:selected("hat").id, "fdless")
		T.eq(R.needsPick("hat"), false)
	end
end

T.section("reanim_pick: closing the window starts nothing")
do
	S.hatReanim = ""
	local after = 0
	core.askReanim("hat", function()
		after = after + 1
	end)
	env.run(0.3)
	T.eq(hub.Win.isOpen("reanimpick"), true)
	hub.Win.close("reanimpick")
	env.run(0.5)
	T.eq(after, 0, "nothing waiting runs")
	T.eq(core.pickAfter, nil, "and nothing is left over for the next window")
	T.eq(S.hatReanim, "", "and nothing was picked")
end

T.section("reanim_pick: starting a hat script asks first")
do
	S.hatReanim = ""
	local e = { path = "Scripts/Hat/Pretend.lua", name = "Pretend", category = "Hat", kind = "hat", size = 1, reanim = { "atsuko", "fdless" } }
	hub.Repo.byPath[e.path] = e
	R.start(e)
	env.run(0.5)
	T.eq(hub.Win.isOpen("reanimpick"), true, "the pick window opens instead of starting")
	T.eq(R.busy, nil, "nothing is starting")
	T.eq(S.reanimSel, e.path, "the script is selected for later")
	hub.Scripts.paintReanim()
	T.ok(string.find(hub.Scripts.rSub.Text, "pick a reanimation first", 1, true) ~= nil, "the Reanimate bar says why: " .. tostring(hub.Scripts.rSub.Text))
	hub.Win.close("reanimpick")
	env.run(0.3)
	S.reanimSel = ""
	hub.Repo.byPath[e.path] = nil
end

T.section("reanim_pick: the Reanimate button with no script asks too")
do
	S.hatReanim = ""
	S.reanimSel = ""
	R.toggle()
	env.run(0.5)
	T.eq(hub.Win.isOpen("reanimpick"), true)
	T.eq(R.reg:state(), "idle", "nothing started yet")
	hub.Win.close("reanimpick")
	env.run(0.3)
end

T.section("reanim_pick: the bar offers a switch while a script runs")
do
	local a = { path = "Scripts/Hat/Aaa.lua", name = "Aaa", category = "Hat", kind = "hat", size = 1 }
	local b = { path = "Scripts/Hat/Bbb.lua", name = "Bbb", category = "Hat", kind = "hat", size = 1 }
	hub.Repo.byPath[a.path] = a
	hub.Repo.byPath[b.path] = b
	local keepCur, keepCan = R.current, R.canSwitch
	R.current = function()
		return a.path
	end
	R.canSwitch = function(e)
		return e ~= nil and e.path == b.path
	end
	S.reanimSel = b.path
	hub.Scripts.paintReanim()
	T.eq(hub.Scripts.rText.Text, "* Switch *", "picking another script while reanimated offers a switch")
	T.ok(string.find(hub.Scripts.rSub.Text, "switches without deanimating", 1, true) ~= nil, hub.Scripts.rSub.Text)
	S.reanimSel = a.path
	hub.Scripts.paintReanim()
	T.eq(hub.Scripts.rText.Text, "* Deanimate *", "the running one still deanimates")
	R.canSwitch = function()
		return false
	end
	S.reanimSel = b.path
	hub.Scripts.paintReanim()
	T.eq(hub.Scripts.rText.Text, "* Deanimate *", "a script that can't switch asks to deanimate")
	T.ok(string.find(hub.Scripts.rSub.Text, "deanimate to switch", 1, true) ~= nil, hub.Scripts.rSub.Text)
	R.busy = "switching"
	hub.Scripts.paintReanim()
	T.eq(hub.Scripts.rText.Text, "Switching...")
	T.ok(string.find(hub.Scripts.rSub.Text, "you stay reanimated", 1, true) ~= nil, hub.Scripts.rSub.Text)
	R.busy = nil
	R.current, R.canSwitch = keepCur, keepCan
	S.reanimSel = ""
	hub.Repo.byPath[a.path] = nil
	hub.Repo.byPath[b.path] = nil
	hub.Scripts.paintReanim()
end

T.section("reanim_pick: no errors")
T.eq(#errorsOf(env), 0, "no errors: " .. table.concat(errorsOf(env), " | "))