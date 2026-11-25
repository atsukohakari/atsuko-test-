local Runner = loadmodule("Testing/mocks/boot_runner.lua")

local function dockItem(hub)
	for _, d in ipairs(hub.Gui:GetDescendants()) do
		if d.Name == "emotes" and d:IsA("TextButton") then
			return d
		end
	end
	return nil
end

local env = Runner.boot({ seconds = 8 })
local hub, core = env.hub, env.core

T.section("emotes_gate: hidden until a reanimation runs")
T.eq(core.emotesAvailable(), false, "nothing is reanimating at the start")
T.ok(dockItem(hub) ~= nil, "the dock still owns the item")
T.eq(dockItem(hub).Visible, false, "but it is hidden")
hub.Panel.show("emotes")
env.run(1)
T.ok(hub.Panel.page ~= "emotes", "Panel.show refuses the page")
hub.Panel.nav("emotes")
env.run(1)
T.ok(hub.Panel.page ~= "emotes", "Panel.nav refuses it too")
hub.Panel.go("emotes")
env.run(1)
T.ok(hub.Panel.page ~= "emotes", "and Panel.go")

T.section("emotes_gate: it appears with the owner's reanimate")
local realOn = core.Reanim.on
core.Reanim.on = function()
	return true
end
hub.Bus.fire("reanim")
env.run(1)
T.eq(core.emotesAvailable(), true, "available while reanimated")
T.eq(dockItem(hub).Visible, true, "the dock item shows")
hub.Panel.nav("emotes")
env.run(1)
T.eq(hub.Panel.page, "emotes", "the page opens")
core.Reanim.on = realOn
hub.Bus.fire("reanim")
env.run(1)
T.eq(dockItem(hub).Visible, false, "it hides again when the reanimation stops")
T.eq(hub.Panel.page, "home", "and the page goes home")

T.section("emotes_gate: any provider that is running counts")
local EP = core.EmotesPage
local fake = { id = "fdless", name = "FDless" }
core.Reanim.reg = {
	active = function()
		return fake
	end,
}
hub.Bus.fire("reanim")
env.run(1)
T.eq(core.emotesAvailable(), true, "a running provider makes it available")
T.eq(dockItem(hub).Visible, true, "the item shows")
T.eq(EP.noDriver(), fake, "a provider without a driver is named")
T.eq(EP.blocked(), true, "playing is declined with a reason, not hidden behind a block text")
fake.driver = function() end
T.eq(EP.noDriver(), nil, "a provider with a driver is fine")
T.eq(EP.blocked(), false, "and playing goes ahead")
core.Reanim.busy = "stopping"
T.eq(core.emotesAvailable(), false, "while stopping it is already gone")
core.Reanim.busy = nil
core.Reanim.reg = nil
hub.Bus.fire("reanim")
env.run(1)
T.eq(dockItem(hub).Visible, false, "with no registry it hides")
T.eq(#env.errors, 0, "no hub errors: " .. table.concat(env.errors, " | "))

T.section("emotes_gate: the page hands the dances to the provider's driver")
do
	local drives, lets, plays = {}, {}, {}
	local current = nil
	local prov = { id = "fdless", name = "FDless" }
	prov.driver = function(lib)
		drives[#drives + 1] = lib
		return true
	end
	prov.undrive = function(lib)
		lets[#lets + 1] = lib
	end
	local lib = {
		play = function(name)
			plays[#plays + 1] = name
			return true
		end,
		playing = function()
			return nil
		end,
		pendingInfo = function()
			return nil
		end,
		hostName = function()
			return nil
		end,
		ready = function()
			return true
		end,
		all = function()
			return {}
		end,
		random = function()
			plays[#plays + 1] = "random"
		end,
	}
	core.Reanim.reg = {
		active = function()
			return current
		end,
	}
	EP.lib = lib
	current = prov
	EP.useDriver()
	T.eq(#drives, 1, "the driver gets the emotes library")
	T.eq(drives[1], lib, "the right one")
	T.eq(EP.driven, prov, "the page remembers who dances")
	T.eq(EP.play("Rat Dance"), true, "playing goes through the page")
	T.eq(#drives, 2, "the driver is asked again first, so a host lost in between comes back")
	T.eq(plays[1], "Rat Dance", "then the dance plays")
	EP.random()
	T.eq(plays[2], "random", "random goes through the driver too")
	T.eq(#drives, 3)
	current = nil
	hub.Bus.fire("reanim")
	env.run(1)
	T.eq(#lets, 1, "when the provider stops the page lets go")
	T.eq(EP.driven, nil)
	current = prov
	core.Reanim.on = function()
		return true
	end
	local before = #drives
	EP.useDriver()
	T.eq(#drives, before, "with Script Reanimate on, its own poser dances and the driver is not used")
	core.Reanim.on = realOn
	local broken = { id = "fdless", name = "FDless", driver = function()
		error("boom")
	end }
	current = broken
	EP.useDriver()
	T.eq(EP.driven, nil, "a driver that throws is not remembered")
	lib.volume = 1
	lib.keysOn = false
	lib.grounded = true
	lib.keys = function()
		return {}
	end
	local setTo = nil
	lib.setGrounded = function(v)
		setTo = v
		lib.grounded = v
	end
	local sf = EP.views[3]
	EP.renderSetup(sf)
	local row = nil
	for _, d in ipairs(sf:GetDescendants()) do
		if d.Name == "Toggle" then
			for _, l in ipairs(d:GetDescendants()) do
				if l:IsA("TextLabel") and l.Text == "Keep feet on the ground" then
					row = d
				end
			end
		end
	end
	T.ok(row ~= nil, "setup has a Keep feet on the ground switch")
	if row then
		row.Activated:Fire()
		T.eq(setTo, false, "tapping it turns the pin off")
		row.Activated:Fire()
		T.eq(setTo, true, "and on again")
	end
	EP.lib = nil
	core.Reanim.reg = nil
	hub.Bus.fire("reanim")
	env.run(1)
	T.eq(#env.errors, 0, "no hub errors: " .. table.concat(env.errors, " | "))
end

T.section("emotes_gate: an old save that ended on the emotes page")
local e2 = Runner.boot({
	seconds = 6,
	files = { ["AtsukoHub/settings.json"] = jsonencode({ lastPage = "emotes" }) },
})
T.eq(e2.hub.S.lastPage, "home", "it starts on Home instead")
T.eq(#e2.errors, 0, "no errors")
