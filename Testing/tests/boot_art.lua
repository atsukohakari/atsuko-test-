local Runner = loadmodule("Testing/mocks/boot_runner.lua")
local boot, logHas = Runner.boot, Runner.logHas

local function okBoot(label, env)
	T.ok(env.mainOk, label .. ": the main chunk finished: " .. tostring(env.mainErr))
	local inst = env.genv.__AtsukoHubInstance
	T.ok(type(inst) == "table" and inst.ready == true, label .. ": the hub says it is ready")
	T.eq(#env.errors, 0, label .. ": no error lines in the log: " .. table.concat(env.errors, " | "))
end

T.section("script pictures: the detail pane gets its banner and logo spots after the hub is up")
do
	local env = boot({ seconds = 6 })
	okBoot("art", env)
	local Detail = env.hub.Detail
	T.ok(Detail.art ~= nil, "the picture view was attached")
	T.eq(env.core.mods.scriptart and env.core.mods.scriptart.err, nil, "the module loaded without an error")
	local entry = env.hub.Repo.entries[1]
	T.ok(entry ~= nil, "there is a script to open")
	if entry then
		Detail.open(entry)
		env.run(2)
		T.eq(Detail.entry, entry, "the detail pane shows it")
		T.eq(Detail.art.path, entry.path, "and the picture view follows it")
		T.eq(#env.badProps, 0, "no bad property values were written: " .. table.concat(env.badProps, " | "))
		local other = env.hub.Repo.entries[2]
		if other then
			Detail.open(other)
			env.run(1)
			T.eq(Detail.art.path, other.path, "opening another script moves the picture view along")
		end
		Detail.close(true)
	end
	T.eq(#env.badProps, 0, "still no bad property values")
	T.eq(#env.errors, 0, "no errors afterwards")
end

T.section("script pictures: safe mode leaves them out and the pane still works")
do
	local env = boot({ seconds = 6, files = { ["AtsukoHub/boot.json"] = '{"v":1,"stage":"repo","ok":false,"n":0}' } })
	okBoot("safe art", env)
	local Detail = env.hub.Detail
	T.eq(Detail.art, nil, "no picture view in safe mode")
	local entry = env.hub.Repo.entries[1]
	if entry then
		Detail.open(entry)
		env.run(2)
		T.eq(Detail.entry, entry, "the pane opens without it")
		Detail.close(true)
	end
	T.eq(#env.errors, 0, "no errors")
end

T.section("script pictures: a module that fails to load is reported and nothing else breaks")
do
	local env = boot({
		seconds = 6,
		without = {},
		files = {},
		before = function(e)
			local orig = _G.readfile
			_G.readfile = function(path)
				if string.find(path, "Hub/modules/scriptart.lua", 1, true) then
					return "return {"
				end
				return orig(path)
			end
		end,
	})
	T.ok(env.mainOk, "main chunk")
	T.eq(env.genv.__AtsukoHubInstance and env.genv.__AtsukoHubInstance.ready, true, "ready")
	T.eq(env.hub.Detail.art, nil, "no picture view")
	T.ok(logHas(env, "script pictures:"), "the Console says why")
	local entry = env.hub.Repo.entries[1]
	if entry then
		env.hub.Detail.open(entry)
		env.run(2)
		T.eq(env.hub.Detail.entry, entry, "the pane still opens")
	end
end
