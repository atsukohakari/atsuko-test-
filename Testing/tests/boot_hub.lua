local Runner = loadmodule("Testing/mocks/boot_runner.lua")
local boot = Runner.boot

local function check(label, env, allowed)
	T.ok(env.mainOk, label .. ": the main chunk finished: " .. tostring(env.mainErr))
	local inst = env.genv.__AtsukoHubInstance
	T.ok(type(inst) == "table" and inst.ready == true, label .. ": the hub says it is ready")
	local bad = {}
	for _, line in ipairs(env.errors or {}) do
		local fine = false
		for _, pat in ipairs(allowed or {}) do
			if string.find(line, pat, 1, true) then
				fine = true
			end
		end
		if not fine then
			bad[#bad + 1] = line
		end
	end
	T.eq(#bad, 0, label .. ": no unexpected error lines: " .. table.concat(bad, " | "))
	local steps, where = stepmax()
	print(label .. ": longest stretch without a pause " .. steps .. " steps near " .. where .. ", warnings " .. #env.warns)
	for i, w in ipairs(env.warns) do
		if i <= 5 then
			print("  warn: " .. w)
		end
	end
end

T.section("boot: a desktop executor with every function")
check("desktop", boot({}))

T.section("boot: a phone")
check("phone", boot({ touch = true, viewW = 800, viewH = 360 }))

T.section("boot: an executor with no hooking functions")
check("nohooks", boot({ without = { "hookmetamethod", "hookfunction", "getnamecallmethod", "newcclosure", "checkcaller", "setnamecallmethod", "getrawmetatable", "getconnections", "isexecutorclosure" } }))

T.section("boot: an executor with no file functions (GitHub mode, offline)")
check("nofiles", boot({ without = { "writefile", "readfile", "isfile", "isfolder", "makefolder", "delfile", "listfiles", "appendfile", "delfolder" } }), { "" })

T.section("boot: an executor with files but no listfiles")
check("nolist", boot({ without = { "listfiles" } }), { "" })

T.section("boot: no character yet")
check("nochar", boot({ character = false }))

T.section("boot: a broken settings file and a broken hat file")
check("broken", boot({ files = { ["AtsukoHub/settings.json"] = "{not json at all", ["AtsukoHub/alignment_user.lua"] = "return { rows = ", ["AtsukoHub/cache/alignment.lua"] = "garbage(" } }))

T.section("boot: settings from an older hub")
check("older", boot({ files = { ["AtsukoHub/settings.json"] = '{"prefix":"/","theme":"dark","animations":true,"openOnLoad":true,"favorites":{"Scripts/Hat/x.lua":true},"recent":["Scripts/Hat/x.lua"]}' } }))
