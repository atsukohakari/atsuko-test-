local Runner = loadmodule("Testing/mocks/boot_runner.lua")
local boot, journal, logHas = Runner.boot, Runner.journal, Runner.logHas

local SCRIPT = "Scripts/Hat/StudioDummyV4-Test.lua"

local function settings(t)
	return { ["Atsuko Hub/settings.json"] = jsonencode(t) }
end

local function merge(a, b)
	local out = {}
	for k, v in pairs(a) do
		out[k] = v
	end
	for k, v in pairs(b) do
		out[k] = v
	end
	return out
end

local function okBoot(label, env)
	T.ok(env.mainOk, label .. ": the main chunk finished: " .. tostring(env.mainErr))
	local inst = env.genv.__AtsukoHubInstance
	T.ok(type(inst) == "table" and inst.ready == true, label .. ": the hub says it is ready")
	T.eq(#env.errors, 0, label .. ": no error lines in the log: " .. table.concat(env.errors, " | "))
end

T.section("journal: a normal first start installs no hooks at all")
do
	local env = boot({ seconds = 12 })
	okBoot("first", env)
	T.eq(#env.hooks, 0, "no engine hooks were installed while the hub started")
	T.eq(env.core.Boot.safe, false, "no previous note means a normal start")
	local j = journal(env)
	T.ok(j ~= nil, "the hub wrote Atsuko Hub/boot.json")
	T.eq(j and j.ok, true, "the note says the start finished")
	T.eq(j and j.stage, "ok", "the last stage is ok")
	T.eq(j and j.ver, "1.6.1", "the note names the version")
	T.eq(j and j.n, 0, "no failed starts in a row")
	T.eq(j and j.doing, nil, "nothing is marked as in progress")
	T.eq(env.hub.S.hookChat, false, "hiding commands from chat starts off")
	T.eq(env.hub.S.hookNotices, false, "catching other pop-ups starts off")
end

T.section("journal: the note walks through the stages while the hub starts")
do
	local stages = {}
	local env = boot({
		seconds = 12,
		before = function(e)
			local orig = _G.writefile
			_G.writefile = function(path, data)
				if path == "Atsuko Hub/boot.json" then
					local j = jsondecode(data)
					if j then
						stages[#stages + 1] = tostring(j.stage) .. ":" .. tostring(j.ok)
					end
				end
				return orig(path, data)
			end
		end,
	})
	okBoot("stages", env)
	local joined = table.concat(stages, " ")
	for _, want in ipairs({ "start:false", "settings:false", "commands:false", "gui:false", "bar:false", "repo:false", "ready:false", "ok:true" }) do
		T.ok(string.find(joined, want, 1, true) ~= nil, "the note passed through " .. want .. ": " .. joined)
	end
end

T.section("journal: a start that never finished comes back in safe mode")
do
	local files = merge(settings({ hookChat = true, hookNotices = true }), { ["Atsuko Hub/boot.json"] = '{"v":1,"ver":"1.6.1","stage":"commands","ok":false,"n":0}' })
	local env = boot({ seconds = 12, files = files })
	okBoot("died", env)
	local Boot = env.core.Boot
	T.eq(Boot.safe, true, "safe mode is on")
	T.eq(Boot.step, "commands", "it remembers where the last start stopped")
	T.eq(#env.hooks, 0, "no hooks even though both were switched on in the settings")
	T.eq(env.core.Reanim.reg, nil, "reanimation was left out")
	T.ok(string.find(tostring(env.core.Reanim.loadError), "Safe mode", 1, true) ~= nil, "the reanimation page says why")
	T.ok(logHas(env, "safe mode:"), "the Console says safe mode is on")
	local asked = 0
	for _, r in ipairs(env.requests) do
		if string.find(tostring(r.Url or r.url or ""), "ntfy", 1, true) then
			asked += 1
		end
	end
	T.eq(asked, 0, "chat did not connect")
	local j = journal(env)
	T.eq(j and j.ok, true, "a clean safe start clears the note")
	T.eq(j and j.n, 0, "and resets the count")
	T.eq(env.hub.S.hookChat, true, "the setting itself was not thrown away, it just waits")

	local again = boot({ seconds = 12, files = merge(settings({ hookChat = true, hookNotices = true }), { ["Atsuko Hub/boot.json"] = env.files["Atsuko Hub/boot.json"] }) })
	okBoot("after safe", again)
	T.eq(again.core.Boot.safe, false, "the start after a clean safe start is normal")
	T.eq(#again.hooks, 2, "and the two hooks the user asked for go in, one each")
end

T.section("journal: a start that died inside a hook switches that hook off")
do
	local files = merge(settings({ hookChat = true, hookNotices = true }), { ["Atsuko Hub/boot.json"] = '{"v":1,"stage":"ready","ok":false,"doing":"hook:chat","n":0}' })
	local env = boot({ seconds = 12, files = files })
	okBoot("chat died", env)
	T.eq(env.core.Boot.safe, true, "safe mode")
	T.eq(env.core.Boot.step, "hook:chat", "the step is the hook")
	T.eq(env.hub.S.hookChat, false, "hiding commands from chat is off now")
	T.eq(env.hub.S.hookNotices, true, "the other hook stays as the user left it")
	T.eq(#env.core.Boot.flipped, 1, "one switch was flipped")
	T.ok(string.find(env.files["Atsuko Hub/settings.json"] or "", '"hookChat":false', 1, true) ~= nil, "and it was saved")
	T.eq(#env.hooks, 0, "no hooks in safe mode")

	local files2 = merge(settings({ smartStop = true }), { ["Atsuko Hub/boot.json"] = '{"v":1,"stage":"ready","ok":false,"doing":"hook:conn","n":1}' })
	local env2 = boot({ seconds = 12, files = files2 })
	okBoot("conn died", env2)
	T.eq(env2.hub.S.smartStop, false, "Smart Stop is off after a start that died while it was hooking")

	local files3 = merge(settings({ hookNotices = true }), { ["Atsuko Hub/boot.json"] = '{"v":1,"stage":"ready","ok":false,"doing":"hook:notices","n":0}' })
	local env3 = boot({ seconds = 12, files = files3 })
	okBoot("notices died", env3)
	T.eq(env3.hub.S.hookNotices, false, "the pop-up hook is off after a start that died inside it")
end

T.section("journal: you can ask for safe mode yourself")
do
	local env = boot({
		seconds = 12,
		files = settings({ hookChat = true }),
		before = function(e)
			e.genv.AtsukoSafeMode = true
		end,
	})
	okBoot("forced", env)
	T.eq(env.core.Boot.safe, true, "safe mode")
	T.eq(env.core.Boot.forced, true, "and it says you asked")
	T.eq(#env.hooks, 0, "no hooks")
	T.eq(env.hub.S.hookChat, true, "nothing is switched off for you")
end

T.section("journal: a note that makes no sense does not trigger safe mode")
do
	for _, text in ipairs({ "{{{ not json", "[]", '{"ok":false}', '{"stage":5,"ok":false}', "" }) do
		local env = boot({ seconds = 8, files = { ["Atsuko Hub/boot.json"] = text } })
		okBoot("odd note", env)
		T.eq(env.core.Boot.safe, false, "normal start for note " .. string.format("%q", text))
	end
end

T.section("journal: opting in installs each hook once, after the hub is up, with the note written first")
do
	local seen = {}
	local env = boot({
		seconds = 12,
		files = settings({ hookChat = true, hookNotices = true }),
		before = function(e)
			local orig = _G.hookmetamethod
			_G.hookmetamethod = function(...)
				local j = jsondecode(e.files["Atsuko Hub/boot.json"] or "{}")
				seen[#seen + 1] = { doing = j.doing, ok = j.ok, ready = e.genv.__AtsukoHubInstance and e.genv.__AtsukoHubInstance.ready }
				return orig(...)
			end
		end,
	})
	okBoot("opt in", env)
	T.eq(env.core.Boot.safe, false, "normal start")
	T.eq(#seen, 2, "the engine was asked twice")
	T.eq(seen[1] and seen[1].doing, "hook:chat", "the note said hook:chat before the first call")
	T.eq(seen[1] and seen[1].ok, false, "and said the start was not finished")
	T.eq(seen[1] and seen[1].ready, true, "the hub was already up")
	T.eq(seen[2] and seen[2].doing, "hook:notices", "the note said hook:notices before the second call")
	T.eq(env.core.chatHook and env.core.chatHook.active, true, "chat hook is active")
	T.eq(env.core.noticeHook and env.core.noticeHook.active, true, "pop-up hook is active")
	local j = journal(env)
	T.eq(j and j.ok, true, "the note ends finished")
	T.eq(j and j.doing, nil, "and nothing is marked in progress")
end

T.section("journal: a hook that the executor refuses turns the setting off, quietly")
do
	local env = boot({
		seconds = 12,
		files = settings({ hookChat = true, hookNotices = true }),
		before = function()
			_G.hookmetamethod = function()
				error("not allowed")
			end
		end,
	})
	okBoot("refused", env)
	T.eq(env.core.chatHook and env.core.chatHook.active, false, "chat hook is not active")
	T.eq(env.hub.S.hookChat, false, "setting is off")
	T.eq(env.hub.S.hookNotices, false, "setting is off")
	T.eq(journal(env).ok, true, "the note is finished")
end

T.section("journal: switching a hook on later, and off again")
do
	local env = boot({ seconds = 12 })
	okBoot("later", env)
	local hub, core = env.hub, env.core
	hub.S.hookChat = true
	core.applyHooks(true, "chat")
	T.eq(#env.hooks, 1, "one hook went in")
	T.eq(core.chatHook.active, true, "active")
	T.eq(journal(env).ok, true, "the note is finished again")
	hub.S.hookChat = false
	core.applyHooks(true, "chat")
	T.eq(core.chatHook, nil, "removed")
	hub.S.hookChat = true
	core.applyHooks(true, "chat")
	T.eq(#env.hooks, 1, "switching it back on does not hook the engine a second time")
	T.eq(core.chatHook.active, true, "and it works again")
end

T.section("journal: in safe mode a switch is saved but not installed, and reanimation can be retried")
do
	local env = boot({ seconds = 12, files = { ["Atsuko Hub/boot.json"] = '{"v":1,"stage":"repo","ok":false,"n":0}' } })
	okBoot("safe switch", env)
	local hub, core = env.hub, env.core
	hub.S.hookNotices = true
	core.applyHooks(true, "notices")
	T.eq(#env.hooks, 0, "not installed")
	T.eq(hub.S.hookNotices, true, "but still wanted")
	core.Reanim.retry()
	env.run(3)
	T.ok(core.Reanim.reg ~= nil, "pressing Retry loads reanimation even in safe mode")
end

T.section("journal: a script that was starting when the game closed does not auto-run again")
do
	local files = merge(settings({ perScript = { [SCRIPT] = { autorun = true } } }), { ["Atsuko Hub/boot.json"] = '{"v":1,"stage":"ok","ok":true,"n":0,"script":"' .. SCRIPT .. '"}' })
	local env = boot({ seconds = 12, files = files })
	okBoot("marked", env)
	T.eq(env.core.Boot.safe, false, "that alone is not safe mode")
	T.eq(env.hub.S.perScript[SCRIPT].autorun, false, "auto-run is off for that script")
	T.ok(not env.hub.SHARED.running[SCRIPT], "it was not started")
	T.ok(logHas(env, "auto-run turned off"), "the Console says so")

	local control = boot({ seconds = 12, files = settings({ perScript = { [SCRIPT] = { autorun = true } } }) })
	T.ok(control.mainOk, "control: the main chunk finished")
	T.eq(control.hub.S.perScript[SCRIPT].autorun, true, "control: auto-run stays on")
	T.ok(control.hub.SHARED.running[SCRIPT] ~= nil or logHas(control, "started"), "control: the script was started")
	T.eq(journal(control).script, nil, "control: the script marker is gone five seconds later")
end

T.section("journal: closing the hub cleanly counts as finished")
do
	local env = boot({ seconds = 1 })
	T.ok(env.mainOk, "main chunk")
	local j = journal(env)
	T.eq(j and j.ok, false, "one second in, the start is not finished yet")
	env.genv.__AtsukoHubInstance.Destroy()
	j = journal(env)
	T.eq(j and j.ok, true, "closing it marks the note finished")
	T.eq(j and j.stage, "closed", "as closed")
end

T.section("journal: no file functions means no note and no trouble")
do
	local env = boot({ seconds = 8, without = { "writefile", "readfile", "isfile", "isfolder", "makefolder", "delfile", "listfiles", "appendfile", "delfolder" } })
	T.ok(env.mainOk, "main chunk")
	T.eq(env.genv.__AtsukoHubInstance and env.genv.__AtsukoHubInstance.ready, true, "ready")
	T.eq(env.files["Atsuko Hub/boot.json"], nil, "nothing written")
	T.eq(env.core.Boot.safe, false, "normal")
end

local function rowFor(env, title)
	for _, o in ipairs(env.hub.Gui:GetDescendants()) do
		if o.ClassName == "TextLabel" and o.Text == title then
			return o.Parent
		end
	end
	return nil
end

T.section("journal: the two switches in settings do what they say")
do
	local env = boot({ seconds = 6 })
	okBoot("switches", env)
	local chat = rowFor(env, "Hide my commands from chat")
	local pops = rowFor(env, "Catch other scripts' pop-ups")
	T.ok(chat ~= nil and pops ~= nil, "both switches are in settings")
	T.eq(#env.hooks, 0, "nothing is hooked before you touch them")
	chat.Activated:Fire()
	env.run(1)
	T.eq(env.hub.S.hookChat, true, "chat switch is on")
	T.eq(#env.hooks, 1, "and the game's chat was hooked once")
	T.eq(env.core.chatHook and env.core.chatHook.active, true, "the hook is active")
	chat.Activated:Fire()
	env.run(1)
	T.eq(env.hub.S.hookChat, false, "chat switch is off again")
	T.eq(env.core.chatHook, nil, "and the hook lets go")
	pops.Activated:Fire()
	env.run(1)
	T.eq(env.hub.S.hookNotices, true, "pop-up switch is on")
	T.eq(env.hub.S.noticeToasts, true, "and pop-ups become toasts")
	T.eq(#env.hooks, 2, "the game was hooked once more")
	T.eq(env.core.noticeHook and env.core.noticeHook.active, true, "the pop-up hook is active")
	T.eq(#env.errors, 0, "no errors: " .. table.concat(env.errors, " | "))
	T.eq(#env.badProps, 0, "no bad property values: " .. table.concat(env.badProps, " | "))
end

T.section("journal: in safe mode the switches are kept but nothing is hooked")
do
	local env = boot({ seconds = 6, files = { ["Atsuko Hub/boot.json"] = '{"v":1,"stage":"gui","ok":false,"n":0}' } })
	okBoot("safe switches", env)
	local chat = rowFor(env, "Hide my commands from chat")
	T.ok(chat ~= nil, "the switch is there")
	chat.Activated:Fire()
	env.run(1)
	T.eq(env.hub.S.hookChat, true, "the choice is kept")
	T.eq(#env.hooks, 0, "but the game is not hooked")
	T.ok(string.find(env.files["Atsuko Hub/settings.json"] or "", '"hookChat":true', 1, true) ~= nil, "and saved for the next normal start")
end

T.section("journal: a switch the executor can't honour goes back to off")
do
	local env = boot({ seconds = 6, without = { "hookmetamethod", "hookfunction" } })
	okBoot("no hooks", env)
	local chat = rowFor(env, "Hide my commands from chat")
	chat.Activated:Fire()
	env.run(1)
	T.eq(env.hub.S.hookChat, false, "the switch is off again")
	T.eq(#env.hooks, 0, "nothing was hooked")
end
