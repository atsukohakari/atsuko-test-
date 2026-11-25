local Runner = loadmodule("Testing/mocks/boot_runner.lua")
local Ui = loadmodule("Hub/modules/alignment_ui.lua")

T.section("add_reanim: the Hats page add button needs a reanimation")
do
	Ui.init({ reanimated = function()
		return false
	end })
	T.eq(Ui.canAdd(), false, "not reanimated, no adding")
	Ui.init({ reanimated = function()
		return true
	end })
	T.eq(Ui.canAdd(), true, "reanimated, adding is fine")
	Ui.init({ reanimated = function()
		error("broken")
	end })
	T.eq(Ui.canAdd(), false, "a check that breaks counts as not reanimated")
	Ui.init({})
	T.eq(Ui.canAdd(), true, "with no way to check it doesn't block")
	T.ok(string.find(Ui.ADD_REANIM, "Reanimate first", 1, true) == 1)
	Ui.destroy()
end

local env = Runner.boot({ seconds = 8 })
local core = env.core
local hub = env.hub
T.ok(core ~= nil and hub ~= nil, "the hub booted")
local Cmd = core.ctx.Cmd
local genv = env.genv

T.section("add_reanim: add only works while reanimated")
do
	T.eq(core.reanimated(), false, "nothing is reanimated after boot")
	local def = Cmd.by.add
	T.ok(def ~= nil, "add is a command")
	local ok, why = def.run("gun 4506945409")
	T.eq(ok, false, "add is refused")
	T.ok(string.find(tostring(why), "Reanimate first", 1, true) == 1, "with a reason: " .. tostring(why))
	T.ok(string.find(def.desc, "only that one", 1, true) ~= nil, "the help says it only goes on the running script")
	T.ok(string.find(def.usage, "add [gun|sword|", 1, true) == 1, "and shows the job first: " .. def.usage)
	T.eq(Cmd.run("add", "4506945409", true), false, "Cmd.run says no too")

	local live = true
	genv.AtsukoHatFd = { isReanimated = function()
		return live
	end }
	T.eq(core.reanimated(), true, "a hat reanimation counts")
	local slot = core.mods.alignment
	local svc = slot and slot.mod and slot.mod.service
	T.ok(svc ~= nil, "the hat list is loaded")
	if svc then
		svc.hats["4506945409"] = { mesh = "8880001", tex = "8880002", name = "Test Blaster" }
		svc.hats["4506945411"] = { mesh = "8880003", tex = "8880004", name = "Ice Katana" }
		svc.hats["4506945413"] = { mesh = "8880005", tex = "8880006", name = "Shiny Thing" }
	end
	local okN, whyN = def.run("gun 4506945409")
	T.eq(okN, false, "with no hat script running there's nothing to put it on")
	T.ok(string.find(tostring(whyN), "Start the hat script", 1, true) == 1, tostring(whyN))
	local realTarget = core.addTarget
	local running = { name = "Neptunian V Gun", shown = "Neptunian V Gun", slots = { "sword", "gun", "slash", "bullet" } }
	core.addTarget = function()
		return running
	end
	local ok2, msg = def.run("gun 4506945409")
	T.eq(ok2, true, "add goes ahead: " .. tostring(msg))
	T.ok(string.find(tostring(msg), "Adding 1 hat to Neptunian V Gun", 1, true) == 1, tostring(msg))
	env.run(2)
	if svc then
		local function has(section, target, mesh, want)
			for _, row in ipairs(svc:userRows(section, target)) do
				if row.mesh == mesh and (want == nil or row.slot == want) then
					return true
				end
			end
			return false
		end
		T.ok(has("script", "Neptunian V Gun", "8880001", "gun"), "the hat is the running script's gun")
		T.eq(has("shared", "gun", "8880001"), false, "and not every gun script's")
		T.eq((def.run("4506945411")), true, "add with no job")
		env.run(2)
		T.ok(has("script", "Neptunian V Gun", "8880003", "sword"), "Ice Katana is worked out to be its sword")
		T.eq(has("shared", "sword", "8880003"), false, "only there")
		running = { name = "The Hotline", shown = "The Hotline", slots = { "gun", "bullet" } }
		T.eq((def.run("4506945411")), true, "a sword on a script with only a gun")
		env.run(2)
		T.ok(has("script", "The Hotline", "8880003", "gun"), "becomes its gun, the only thing it can hold")
		running = { name = "Neptunian V", shown = "Neptunian V", slots = { "sword" } }
		T.eq((def.run("gun 4506945409")), true)
		env.run(2)
		T.eq(has("script", "Neptunian V", "8880001"), false, "asking for a gun on a script with only a sword adds nothing")
		running = { name = "Neptunian V Gun", shown = "Neptunian V Gun", slots = { "sword", "gun", "slash", "bullet" } }
		T.eq((def.run("4506945413")), true, "a hat it can't tell")
		env.run(2)
		T.ok(has("script", "Neptunian V Gun", "8880005", "gun"), "is the first weapon for now")
		T.eq((def.run("sword 4506945413")), true, "until you say")
		env.run(2)
		T.ok(has("script", "Neptunian V Gun", "8880005", "sword"), "then it's the sword")
		T.eq(has("script", "Neptunian V Gun", "8880005", "gun"), false, "and the guess goes")
		running = nil
		T.eq((def.run("rightarm 4506945413")), true, "a body part doesn't need a script")
		env.run(2)
		local rig = false
		for _, row in ipairs(svc:userRows("rig")) do
			if row.mesh == "8880005" then
				rig = true
			end
		end
		T.ok(rig, "it's on the rig")
	end
	core.addTarget = realTarget
	live = false
	T.eq(core.reanimated(), false, "after the reanimation ends")
	T.eq((def.run("sword 4506945409")), false, "add is refused again")
	genv.AtsukoHatFd = nil
	core.Reanim.busy = "stopping"
	T.eq(core.reanimated(), false, "while stopping it doesn't count")
	core.Reanim.busy = nil
	T.same(core.reanimHats(), core.reanimHats(), "reading the hats on the reanimation doesn't break")
end

T.section("add_reanim: the hub keeps each hat's spot while a script runs")
do
	local slot = core.mods.alignment
	local svc = slot and slot.mod and slot.mod.service
	local AL = { title = "Test Gun", tabs = { "Gun", "Muzzle" }, vals = { { 3, 0, 0, 0, 0, 0 }, { 0, 0, 0, 0, 0, 0 } }, held = {}, alive = function()
		return true
	end }
	function AL.get(s)
		local v = AL.vals[s]
		return v and { v[1], v[2], v[3], v[4], v[5], v[6] } or nil
	end
	function AL.set(s, k, n)
		AL.vals[s][k] = n
		return n
	end
	function AL.put(s, v)
		for k = 1, 6 do
			AL.vals[s][k] = tonumber(v[k]) or 0
		end
	end
	function AL.reset(s)
		AL.put(s, { 0, 0, 0, 0, 0, 0 })
	end
	function AL.save()
		return true
	end
	function AL.load()
		return true
	end
	function AL.hat(s)
		local h = AL.held[s]
		if h then
			return h[1], h[2], h[3]
		end
		return nil
	end
	genv.AtsukoAlign = AL
	hub.Bus.fire("align")
	env.run(0.3)
	local K = core.AlignTrack
	T.ok(K ~= nil and K.tr ~= nil, "a tracker starts for the script")
	T.eq(K.tr and K.tr.a, AL)
	AL.held[1] = { "7777", "7777", "Built-in Gun" }
	env.run(0.3)
	T.eq(K.hat(1), "Built-in Gun", "the hub knows which hat is on the Gun tab")
	T.same(svc and svc:spot("Test Gun", "Gun", "7777"), { 3, 0, 0, 0, 0, 0 }, "the script's own gun keeps its old spot")
	AL.set(1, 2, 1.5)
	env.run(0.3)
	T.same(svc and svc:spot("Test Gun", "Gun", "7777"), { 3, 1.5, 0, 0, 0, 0 }, "a nudge is saved for it")
	svc:addIds(slot.mod.parseAdd("gun 5550001"), { { mesh = "5550001", tex = "5550002", name = "Blaster" } })
	AL.held[1] = { "5550001", "5550001", "Blaster" }
	env.run(0.3)
	T.same(AL.vals[1], { 0, 0, 0, 0, 0, 0 }, "the next gun you added starts from the default, not the last one")
	env.run(2)
	local file = env.files["AtsukoHub/alignment_user.lua"]
	T.ok(type(file) == "string" and string.find(file, '["Test Gun"]', 1, true) ~= nil, "the spots are written to your hat file a moment later")
	genv.AtsukoAlign = nil
	hub.Bus.fire("align")
	env.run(0.3)
	T.eq(K.tr, nil, "when the script stops the tracker stops")
	T.eq(K.hat(1), nil)
end

T.section("add_reanim: adding a hat the running script uses restarts it so it picks the hat up")
do
	local R = core.Reanim
	local live = true
	genv.AtsukoHatFd = { isReanimated = function()
		return live
	end }
	local slot = core.mods.alignment
	local svc = slot and slot.mod and slot.mod.service
	if svc then
		svc.hats["4506945420"] = { mesh = "8880020", tex = "8880021", name = "Night Blade" }
		svc.hats["4506945421"] = { mesh = "8880022", tex = "8880023", name = "Space Pistol" }
	end
	local realCurrent, realName, realRestart = R.current, R.name, R.restart
	local restarts = 0
	R.current = function()
		return "Scripts/Hat/FDless/NeptunianV.lua"
	end
	R.name = function()
		return "Neptunian V"
	end
	R.restart = function()
		restarts += 1
		return true
	end
	local def = Cmd.by.add
	T.eq((def.run("sword 4506945420")), true, "add sword while Neptunian V runs")
	env.run(2)
	T.eq(restarts, 1, "Neptunian V restarts so it holds the new sword")
	T.ok(genv.AtsukoAlignment and genv.AtsukoAlignment.match("Neptunian V", "sword", { mesh = "8880020", name = "Night Blade" }) ~= nil, "and the sword is there for it, even asked without a texture")
	T.eq((def.run("sword 4506945420")), true, "adding it again")
	env.run(2)
	T.eq(restarts, 2, "restarts it again instead of only saying it is already there")
	T.eq((def.run("gun 4506945421")), true, "add a gun")
	env.run(2)
	T.eq(restarts, 2, "Neptunian V has no gun, so it keeps running")
	R.current, R.name, R.restart = realCurrent, realName, realRestart
	live = false
	genv.AtsukoHatFd = nil
end

T.eq(#env.errors, 0, "no error lines: " .. table.concat(env.errors, " | "))
