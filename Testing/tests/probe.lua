local World = loadmodule("Testing/mocks/rbx_world.lua")

local OUT = "AtsukoHub_probe.txt"
local REAL_LOADSTRING = loadstring

local function runProbe(opts, setup)
	opts = opts or {}
	_G.loadstring = REAL_LOADSTRING
	local env = World.install(opts)
	if setup then
		setup(env)
	end
	stepbudget(90000000)
	local f, err = REAL_LOADSTRING(readsource("Hub/Probe.lua"), "=probe")
	T.ok(f ~= nil, "the probe compiles: " .. tostring(err))
	if not f then
		return env, false, err
	end
	if opts.hideLoadstring then
		_G.loadstring = nil
	end
	local done, failed = false, nil
	task.spawn(function()
		local ok, e = pcall(f)
		done = true
		if not ok then
			failed = e
		end
	end)
	env.run(opts.seconds or 14)
	return env, done, failed
end

local function indexOf(text, needle)
	local at = string.find(text, needle, 1, true)
	return at
end

local function moduleCount()
	local n = 0
	for _, name in ipairs(hostlist("Hub/modules")) do
		if string.sub(string.lower(name), -4) == ".lua" then
			n += 1
		end
	end
	return n
end

T.section("probe: a normal run writes every step and runs nothing")
do
	local env, done, failed = runProbe({})
	T.ok(done, "the probe finished")
	T.eq(failed, nil, "and did not stop with an error")
	local text = env.files[OUT]
	T.ok(type(text) == "string", "the steps are in a file")
	text = text or ""
	for _, needle in ipairs({
		"probe started",
		"executor: TestExec 1.0",
		"has: ",
		"missing: ",
		"reading Atsuko Hub/Hub/AtsukoHub.lua",
		"compiling the hub, nothing runs yet",
		"compiled fine, memory +",
		"all modules compile",
		"done: everything compiled and nothing was run",
		"AtsukoProbeRun = true",
	}) do
		T.ok(indexOf(text, needle) ~= nil, "it says: " .. needle)
	end
	local a = indexOf(text, "compiling the hub")
	local b = indexOf(text, "compiled fine")
	T.ok(a ~= nil and b ~= nil and a < b, "'compiling' is written before the compile starts, 'compiled' after")
	local checks = 0
	for _ in string.gmatch(text, "checking [^\n]+") do
		checks += 1
	end
	T.eq(checks, moduleCount(), "every module file was checked once")
	T.ok(string.find(text, "read %d+ bytes, %d+ lines") ~= nil, "the size is written")
	T.eq(env.genv.__AtsukoHubInstance, nil, "the hub itself was not started")
	T.eq(env.files["AtsukoHub/boot.json"], nil, "and no boot note was written")
	T.eq(#env.hooks, 0, "nothing in the game was hooked")
end

T.section("probe: a module that does not compile is named")
do
	local env, done, failed = runProbe({}, function(e)
		e.files["Atsuko Hub/Hub/modules/zzbad.lua"] = "local x ="
	end)
	T.ok(done and failed == nil, "the probe still finished")
	local text = env.files[OUT] or ""
	T.ok(indexOf(text, "zzbad.lua") ~= nil, "the broken file is named")
	T.ok(indexOf(text, "BAD: ") ~= nil, "and marked bad")
	T.ok(indexOf(text, "1 module(s) did not compile") ~= nil, "with a count")
	T.ok(indexOf(text, "done: everything compiled") ~= nil, "the rest still ran")
end

T.section("probe: a folder with another name")
do
	local env, done, failed = runProbe({}, function(e)
		e.genv.AtsukoLocalRoot = "Atsuko Hub"
	end)
	T.ok(done and failed == nil, "finished")
	T.ok(indexOf(env.files[OUT] or "", "done: everything compiled") ~= nil, "a named folder is found")
	local env2, done2, failed2 = runProbe({ rootName = "Somewhere Else" })
	T.ok(done2 and failed2 == nil, "finished with the folder missing")
	local text = env2.files[OUT] or ""
	T.ok(indexOf(text, "couldn't find Hub/AtsukoHub.lua inside: Atsuko Hub, Atsuko") ~= nil, "it says where it looked")
	T.eq(indexOf(text, "compiling the hub"), nil, "and it does not go on")
end

T.section("probe: an executor missing things")
do
	local env, done, failed = runProbe({ without = { "writefile" } })
	T.ok(done and failed == nil, "no writefile: finished")
	T.eq(env.files[OUT], nil, "no writefile: nothing could be written")
	env, done, failed = runProbe({ without = { "listfiles" } })
	T.ok(done and failed == nil, "no listfiles: finished")
	local text = env.files[OUT] or ""
	T.ok(indexOf(text, "no listfiles, so the modules were not checked") ~= nil, "no listfiles: said so")
	T.ok(indexOf(text, "done: everything compiled") ~= nil, "no listfiles: the hub file still compiled")
	env, done, failed = runProbe({ without = { "identifyexecutor", "isfile", "readfile" } })
	T.ok(done and failed == nil, "no isfile: finished")
	T.ok(indexOf(env.files[OUT] or "", "executor: unknown") ~= nil, "no identifyexecutor: unknown")
	env, done, failed = runProbe({ hideLoadstring = true })
	T.ok(done and failed == nil, "no loadstring: finished")
	T.ok(indexOf(env.files[OUT] or "", "no loadstring") ~= nil, "no loadstring: said so")
	T.eq(indexOf(env.files[OUT] or "", "reading "), nil, "no loadstring: did not go on")
end

T.section("probe: running the hub from the probe uses safe mode")
do
	local env, done, failed = runProbe({ seconds = 20 }, function(e)
		e.genv.AtsukoProbeRun = true
	end)
	T.ok(done, "finished")
	T.eq(failed, nil, "no error")
	local text = env.files[OUT] or ""
	for _, needle in ipairs({
		"running the hub in safe mode",
		"the main part finished",
		"still alive 8 seconds later",
	}) do
		T.ok(indexOf(text, needle) ~= nil, "it says: " .. needle)
	end
	local inst = env.genv.__AtsukoHubInstance
	T.ok(type(inst) == "table" and inst.ready == true, "the hub came up")
	T.eq(#env.hooks, 0, "and nothing in the game was hooked")
	T.ok(type(env.files["AtsukoHub/boot.json"]) == "string", "the hub wrote its own boot note")
end
