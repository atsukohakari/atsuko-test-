local saved = { AtsukoHub = AtsukoHub, warn = warn }

local function newHub(over)
	local hub = { notices = {}, registered = {}, stops = 0, reanimStops = 0, onStop = {} }
	hub.Notify = function(title, text, kind, dur)
		hub.notices[#hub.notices + 1] = table.concat({ tostring(title), tostring(text), tostring(kind), tostring(dur) }, "|")
	end
	hub.Commands = {
		register = function(list, opts)
			hub.registered[#hub.registered + 1] = { list = list, opts = opts }
			return {}
		end,
	}
	hub.OnStop = function(f)
		hub.onStop[#hub.onStop + 1] = f
	end
	hub.Stop = function()
		hub.stops += 1
	end
	hub.Reanim = {
		Kind = "hat",
		Provider = "atsuko",
		Stop = function()
			hub.reanimStops += 1
		end,
	}
	for k, v in pairs(over or {}) do
		hub[k] = v
	end
	return hub
end

local function start(path, hub)
	AtsukoHub = hub
	local f, err = loadstring(readsource(path), "=" .. path)
	T.ok(f ~= nil, path .. " compiles: " .. tostring(err))
	if f then
		f()
	end
end

local function command(hub, id)
	for _, def in ipairs(hub.registered[1].list) do
		if def.id == id then
			return def
		end
	end
	return nil
end

local function stop(hub)
	for _, f in ipairs(hub.onStop) do
		f()
	end
end

for _, case in ipairs({
	{ path = "Scripts/_TEMPLATE_HAT.lua", title = "Hat template", short = "hat", ids = { "hello", "loud", "quit" } },
	{ path = "Scripts/_TEMPLATE_LIMB.lua", title = "Limb template", short = "limb", ids = { "hello", "loud", "where", "quit" } },
}) do
	T.section("script_templates: " .. case.path .. " inside the hub")
	local hub = newHub()
	start(case.path, hub)
	T.eq(#hub.notices, 1, "one notice at the start")
	T.eq(hub.notices[1], case.title .. "|Running on atsuko|ok|3", "four arguments: title, text, kind, seconds")
	T.eq(#hub.registered, 1, "one set of commands")
	T.eq(hub.registered[1].opts.short, case.short)
	local ids = {}
	for _, def in ipairs(hub.registered[1].list) do
		ids[#ids + 1] = def.id
		T.eq(type(def.id), "string")
		T.eq(type(def.name), "string")
		T.eq(type(def.desc), "string")
		T.eq(type(def.usage), "string")
		T.eq(type(def.run), "function")
	end
	T.same(ids, case.ids)
	T.eq(#hub.onStop, 1, "one stop hook")
	command(hub, "hello").run(nil, { source = "ui" })
	T.eq(hub.notices[2], case.title .. "|Hello (1)|ok|3")
	command(hub, "hello").run("Hi there", { source = "chat" })
	T.eq(hub.notices[3], case.title .. "|Hi there (2)|ok|3")
	command(hub, "loud").run(nil, { state = true })
	T.eq(hub.notices[4], case.title .. "|Ticking is on|info|2")
	task.wait(10.5)
	T.eq(hub.notices[5], case.title .. "|Still here (3)|info|2", "ticks while loud is on")
	task.wait(10)
	T.eq(#hub.notices, 6)
	command(hub, "loud").run(nil, { state = false })
	T.eq(hub.notices[7], case.title .. "|Ticking is off|info|2")
	task.wait(30)
	T.eq(#hub.notices, 7, "and stays quiet when it is off")
	command(hub, "loud").run("toggle", { state = nil })
	T.eq(hub.notices[8], case.title .. "|Ticking is on|info|2", "a toggle with no state flips it on")
	command(hub, "loud").run("toggle", { state = nil })
	T.eq(hub.notices[9], case.title .. "|Ticking is off|info|2", "and flips it off again")
	task.wait(30)
	T.eq(#hub.notices, 9, "and it is quiet once more")
	T.eq(command(hub, "loud").kind, "toggle")
	T.eq(command(hub, "loud").usage, "loud [on|off|toggle]")
	if command(hub, "where") then
		command(hub, "where").run()
		T.eq(hub.notices[10], case.title .. "|Running on atsuko|info|3")
	end
	local before = #hub.notices
	command(hub, "quit").run()
	if case.short == "hat" then
		T.eq(hub.stops, 1, "quit stops the script")
		T.eq(hub.reanimStops, 0)
	else
		T.eq(hub.reanimStops, 1, "quit stops the limb reanimation")
		T.eq(hub.stops, 0)
	end
	stop(hub)
	T.eq(hub.notices[#hub.notices], case.title .. "|Stopped|info|2", "the stop hook says goodbye")
	local after = #hub.notices
	command(hub, "loud").run(nil, { state = true })
	task.wait(40)
	T.eq(#hub.notices, after + 1, "nothing ticks after the script stopped (only the toggle's own notice)")
end

T.section("script_templates: the limb template names the clone when there is one")
do
	local hub = newHub({
		Reanim = {
			Kind = "limb",
			Provider = "gelatek",
			Clone = { Name = "TalentlessDumbass" },
			Stop = function() end,
		},
	})
	start("Scripts/_TEMPLATE_LIMB.lua", hub)
	T.eq(hub.notices[1], "Limb template|Running on gelatek, clone TalentlessDumbass|ok|3")
	stop(hub)
	hub = newHub({ Reanim = { Kind = "limb", Provider = "uhhhhhh", Stop = function() end } })
	start("Scripts/_TEMPLATE_LIMB.lua", hub)
	T.eq(hub.notices[1], "Limb template|Running on uhhhhhh|ok|3", "no clone is fine")
	stop(hub)
end

T.section("script_templates: outside the hub they still run")
do
	for _, path in ipairs({ "Scripts/_TEMPLATE_HAT.lua", "Scripts/_TEMPLATE_LIMB.lua" }) do
		local lines = {}
		warn = function(...)
			lines[#lines + 1] = table.concat({ ... }, " ")
		end
		AtsukoHub = nil
		local f = loadstring(readsource(path), "=" .. path)
		local ok, e = pcall(f)
		T.eq(ok, true, path .. " runs without the hub: " .. tostring(e))
		T.eq(#lines, 1)
		T.ok(string.find(lines[1], "Running on no reanimation", 1, true) ~= nil, lines[1])
		task.wait(1)
	end
	warn = saved.warn
end

T.section("script_templates: a hub without Reanim or Commands is tolerated")
do
	local hub = newHub({ Reanim = false, Commands = false })
	start("Scripts/_TEMPLATE_HAT.lua", hub)
	T.eq(hub.notices[1], "Hat template|Running on no reanimation|ok|3")
	T.eq(#hub.registered, 0)
	stop(hub)
	hub = newHub({ Reanim = false, Commands = false })
	start("Scripts/_TEMPLATE_LIMB.lua", hub)
	T.eq(hub.notices[1], "Limb template|Running on no reanimation|ok|3")
	stop(hub)
end

T.section("script_templates: a hub without OnStop is tolerated")
do
	for _, path in ipairs({ "Scripts/_TEMPLATE_HAT.lua", "Scripts/_TEMPLATE_LIMB.lua" }) do
		local hub = newHub({ OnStop = false })
		AtsukoHub = hub
		local f = loadstring(readsource(path), "=" .. path)
		local ok, e = pcall(f)
		T.eq(ok, true, path .. " runs without OnStop: " .. tostring(e))
		T.eq(#hub.notices, 1)
		task.wait(1)
	end
end

AtsukoHub = saved.AtsukoHub
warn = saved.warn
