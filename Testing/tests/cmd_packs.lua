local Runner = loadmodule("Testing/mocks/boot_runner.lua")
local Kit = loadmodule("Hub/modules/cmds/_kit.lua")
local Meta = loadmodule("Hub/modules/cmds/_meta.lua")

local function lines(path)
	local out = {}
	for line in string.gmatch(readfile(path), "[^\r\n]+") do
		out[#out + 1] = line
	end
	return out
end

local function val(text)
	return (Kit.mathValue(text))
end

local function why(text)
	local _, e = Kit.mathValue(text)
	return e
end

T.section("kit: reading numbers")
T.same(Kit.parseNumbers("1 2 3", 3), { 1, 2, 3 }, "three numbers")
T.same(Kit.parseNumbers("1,2, 3", 3), { 1, 2, 3 }, "commas work too")
T.same(Kit.parseNumbers("-1.5 0 2e1"), { -1.5, 0, 20 }, "no count asked for")
T.eq(Kit.parseNumbers("1 x 3", 3), nil, "a word is not a number")
T.eq(Kit.parseNumbers("1 2", 3), nil, "wrong amount")
T.eq(Kit.parseNumbers("", 3), nil, "nothing given")
T.same(Kit.parseNumbers(""), {}, "empty list when no count is asked for")
T.eq(Kit.parseNumbers(nil, 1), nil, "nil is nothing")
T.eq(Kit.clamp(5, 1, 3), 3, "clamp high")
T.eq(Kit.clamp(-5, 1, 3), 1, "clamp low")
T.eq(Kit.clamp(2, 1, 3), 2, "clamp inside")
T.eq(Kit.clamp(9, nil, nil), 9, "no limits")
T.eq(Kit.number("7", 1, 0, 5), 5, "number is clamped")
T.eq(Kit.number("abc", 3, 0, 5), 3, "default when it is not a number")
T.eq(Kit.number("abc", nil, 0, 5), nil, "nothing when there is no default")
T.eq(Kit.number(nil, 2), 2, "nil takes the default")
local first, rest = Kit.splitWord("  hello   big world  ")
T.eq(first, "hello", "first word")
T.eq(rest, "big world", "the rest")
first, rest = Kit.splitWord("")
T.eq(first, nil, "no word in nothing")
T.eq(rest, "", "and no rest")

T.section("kit: chat rate limit")
do
	local open, wait = Kit.chatGate(10, nil)
	T.eq(open, true, "the first message goes")
	open, wait = Kit.chatGate(10.5, 10)
	T.eq(open, false, "too soon")
	T.near(wait, Kit.CHAT_GAP - 0.5, 0.0001, "and it says how long to wait")
	open = Kit.chatGate(11.6, 10)
	T.eq(open, true, "after the gap it goes")
end

T.section("kit: the calculator")
T.eq(val("12*(3+4)"), 84, "brackets")
T.eq(val("2 + 3 * 4"), 14, "multiplication first")
T.eq(val("2^10"), 1024, "power")
T.eq(val("2^3^2"), 512, "power goes right to left")
T.eq(val("10/4"), 2.5, "division")
T.eq(val("7%3"), 1, "remainder")
T.eq(val("-(2+3)"), -5, "minus in front of a bracket")
T.eq(val("  .5 + .25 "), 0.75, "decimals and spaces")
T.eq(val("1.5*4"), 6, "decimal times whole")
T.eq(val("((1))"), 1, "nested brackets")
T.eq(val("(1"), nil, "unclosed bracket")
T.ok(string.find(why("(1"), "bracket", 1, true) ~= nil, "and it says so")
T.eq(val("1/0"), nil, "divide by zero")
T.eq(why("1/0"), "Can't divide by zero", "with a clear message")
T.eq(val("5%0"), nil, "remainder of zero")
T.eq(val(""), nil, "nothing typed")
T.eq(val("abc"), nil, "words")
T.eq(val("2 3"), nil, "two numbers with nothing between")
T.eq(val("1+"), nil, "a sum that stops")
T.eq(val(string.rep("1+", 70) .. "1"), nil, "too long")
T.eq(why(string.rep("1+", 70) .. "1"), "That sum is too long", "and it says so")
T.eq(val("9^9^9^9"), nil, "too big")
T.eq(val(nil), nil, "nil")

T.section("kit: text helpers")
T.eq(Kit.listText({ "a", "b", "c" }), "a, b, c", "short list")
T.eq(Kit.listText({ "a", "b", "c", "d" }, 2), "a, b, and 2 more", "long list")
T.eq(Kit.listText({}), "", "empty list")
T.eq(Kit.formatNumber(3), "3", "whole number")
T.eq(Kit.formatNumber(2.5), "2.5", "one decimal")
T.eq(Kit.formatNumber(0.1 + 0.2), "0.3", "rounding noise is hidden")
T.eq(Kit.formatNumber(-4), "-4", "negative")
T.eq(Kit.agoText(1), "1 day", "one day")
T.eq(Kit.agoText(5), "5 days", "days")
T.eq(Kit.agoText(45), "1 month (45 days)", "months")
T.eq(Kit.agoText(400), "1 year 1 month (400 days)", "years and months")
T.eq(Kit.agoText(730), "2 years (730 days)", "whole years")
T.eq(Kit.agoText(-3), "0 days", "never negative")

T.section("catalogue: every row is well formed")
do
	local seen = {}
	for _, row in ipairs(Meta) do
		T.ok(type(row.id) == "string" and string.find(row.id, "^[a-z][a-z0-9]*$") ~= nil, "id looks right: " .. tostring(row.id))
		T.ok(not seen[row.id], "id is only listed once: " .. tostring(row.id))
		seen[row.id] = true
		T.ok(row.kind == "toggle" or row.kind == "action", row.id .. " has a kind")
		T.ok(type(row.desc) == "string" and #row.desc >= 10, row.id .. " has a description")
		T.ok(type(row.usage) == "string" and row.usage ~= "", row.id .. " has a usage line")
		T.ok(not string.find(row.desc .. row.usage, "[\128-\255]"), row.id .. " is plain text")
		T.ok(string.find(row.usage, "^" .. row.id) ~= nil, row.id .. " usage starts with its own name")
	end
end

T.section("packs: they load and register")
local env = Runner.boot({ seconds = 8 })
local core = env.core
local Cmd = core.ctx.Cmd
local S = env.hub.S
local Log = env.hub.Log
local packs = core.cmdPacks
T.ok(packs ~= nil, "the packs were started")
T.eq(packs and #packs.loaded, 8, "all eight packs loaded")
T.eq(packs and next(packs.failed), nil, "none failed")
T.eq(packs and packs.error, nil, "no loader error")
T.eq(packs and packs.skipped, false, "not skipped")
T.eq(#env.errors, 0, "no error lines: " .. table.concat(env.errors, " | "))
T.eq(#Cmd.check(), 0, "no two commands share a name")
local kit = packs.kit
T.eq(next(kit.failed), nil, "nothing was refused by the registry")
T.ok(#kit.built >= 170, "most of the catalogue is built: " .. #kit.built)

T.section("packs: the catalogue is accounted for")
do
	local built, pending, reasons = {}, {}, {}
	for _, id in ipairs(kit.built) do
		built[id] = true
	end
	for _, line in ipairs(lines("Atsuko Hub/Testing/catalogue_pending.txt")) do
		local id, reason = string.match(line, "^(%S+)%s+(%S+)$")
		T.ok(id ~= nil, "pending line is well formed: " .. line)
		if id then
			T.ok(not pending[id], id .. " is only listed once as pending")
			pending[id] = true
			reasons[reason] = (reasons[reason] or 0) + 1
			T.ok(reason == "hook" or reason == "ownership" or reason == "later", id .. " has a known reason")
		end
	end
	local inMeta = {}
	for _, row in ipairs(Meta) do
		inMeta[row.id] = true
	end
	local total, existing = 0, 0
	for _, id in ipairs(lines("Atsuko Hub/Testing/catalogue_ids.txt")) do
		total += 1
		if built[id] then
			T.ok(not pending[id], id .. " is built, so it is not pending")
		elseif pending[id] then
			T.ok(Cmd.by[id] == nil or inMeta[id], id .. " is pending")
		elseif not inMeta[id] then
			existing += 1
			T.ok(Cmd.by[id] ~= nil, id .. " is a command the hub already had")
		else
			T.ok(false, id .. " is neither built nor listed as pending")
		end
	end
	for id in pairs(pending) do
		T.ok(not built[id], id .. " is pending but built")
	end
	T.eq(total, 288, "the catalogue has 288 commands")
	T.eq(total, #kit.built + (function()
		local n = 0
		for _ in pairs(pending) do
			n += 1
		end
		return n
	end)() + existing, "built + pending + already there = the whole catalogue")
	T.ok(existing >= 2, "the hub's own maxzoom and shiftlock count")
end

T.section("packs: every command is described and runnable")
do
	for _, id in ipairs(kit.built) do
		local def = Cmd.by[id]
		T.ok(def ~= nil, id .. " is registered")
		if def then
			T.ok(type(def.desc) == "string" and #def.desc >= 10, id .. " has a description")
			T.ok(type(def.usage) == "string" and def.usage ~= "", id .. " has usage")
			T.ok(type(def.name) == "string" and def.name ~= "", id .. " has a name")
			if def.kind == "toggle" then
				T.eq(type(def.start), "function", id .. " has a start")
				T.eq(type(def.stop), "function", id .. " has a stop")
			else
				T.eq(type(def.run), "function", id .. " has a run")
			end
			T.ok(def.needs == nil, id .. " does not carry catalogue notes into the registry")
		end
	end
end

T.section("packs: server info tells how long the server has been up")
do
	local toasts = {}
	local stop = env.hub.Bus.on("notify", function(title, text)
		toasts[#toasts + 1] = tostring(title) .. ": " .. tostring(text)
	end)
	local ok, text = Cmd.by.serverinfo.run()
	T.eq(ok, true)
	text = tostring(text)
	T.ok(string.match(text, "Server up for %d+[hms]") ~= nil, "it says how long the server has been up: " .. text)
	T.ok(string.find(text, "counts from when you got here", 1, true) ~= nil, "and that Roblox keeps the real start hidden, so it is counted from when you got here")
	T.eq(string.find(text, "at least", 1, true), nil, "no at least anymore")
	T.eq(string.find(text, "You've been here", 1, true), nil, "your own time isn't said twice when it is the same")
	T.ok(string.find(text, "Job id copied", 1, true) ~= nil, "the job id is copied")
	T.eq(env.clipboard, "job-1")
	T.eq(#toasts, 0, "running it quietly shows nothing on its own")
	local rs = game:GetService("ReplicatedStorage")
	rs:SetAttribute("ServerStartTime", math.floor(workspace:GetServerTimeNow()) - 3725)
	core.serverClock.cache = nil
	toasts = {}
	Cmd.run("serverinfo")
	T.eq(#toasts, 1, "one notification, not one for the info and one for the copy: " .. table.concat(toasts, " | "))
	local one = toasts[1] or ""
	T.ok(string.match(one, "Server up for 1h 2m [56]s") ~= nil, "hours, minutes and seconds from the game's own start: " .. one)
	T.ok(string.find(one, "You've been here", 1, true) ~= nil, "with your own time on its own line")
	T.eq(string.find(one, "hidden", 1, true), nil, "and no note when the game says it")
	rs:SetAttribute("ServerStartTime", nil)
	core.serverClock.cache = nil
	T.ok(core.serverClock ~= nil, "the hub keeps the server clock from the start")
	local home = core.Home and core.Home.stats and core.Home.stats.uptime
	if home then
		T.ok(string.find(tostring(home.Text), "+", 1, true) ~= nil or home.Text == "-", "the home page's uptime shows it is counted: " .. tostring(home.Text))
	end
	if type(stop) == "function" then stop() end
end

T.section("packs: a chat command runs once")
do
	T.eq(core.heardTwice(";coinflip", "sending", 100), false, "the first time it's heard it runs")
	T.eq(core.heardTwice(";coinflip", "chatted", 101.5), true, "the same message coming back through the other chat event a moment later is the same message")
	T.eq(core.heardTwice(";coinflip", "chatted", 102), false, "saying it again runs again")
	T.eq(core.heardTwice(";coinflip", "chatted", 102.5), false, "also through the same event")
	T.eq(core.heardTwice(";coinflip", "sending", 120), false, "long after, it is a new message")
	T.eq(core.heardTwice(";roll", "chatted", 120.5), false, "another message always runs")
	local tcs = game:GetService("TextChatService")
	local LP = game:GetService("Players").LocalPlayer
	local toasts = {}
	local stop = env.hub.Bus.on("notify", function(title)
		toasts[#toasts + 1] = tostring(title)
	end)
	env.frame(1)
	tcs.SendingMessage:Fire({ Text = S.prefix .. "coinflip" })
	env.frame(1.2)
	LP.Chatted:Fire(S.prefix .. "coinflip")
	env.frame(0.5)
	local n = 0
	for _, t in ipairs(toasts) do
		if string.find(string.lower(t), "coin", 1, true) then
			n += 1
		end
	end
	T.eq(n, 1, "a command the new chat sends and then echoes a second later runs once: " .. table.concat(toasts, " | "))
	if type(stop) == "function" then stop() end
end

T.section("packs: every command survives odd input")
do
	local seen = #Log.items
	local function fresh()
		local out = {}
		for i = seen + 1, #Log.items do
			local e = Log.items[i]
			if e.kind == "error" then
				out[#out + 1] = tostring(e.src) .. ": " .. tostring(e.msg)
			end
		end
		seen = #Log.items
		return out
	end
	local args = { "", "1", "1 2 3", "me", "abc", "all", "5 me", "off" }
	local skip = { exit = true }
	local bad = 0
	for _, id in ipairs(kit.built) do
		local def = Cmd.by[id]
		if def and not skip[id] then
			for _, a in ipairs(args) do
				local ok, err = pcall(function()
					if def.kind == "toggle" then
						Cmd.set(id, true, a ~= "" and a or nil, true)
						env.frame(0.1)
						Cmd.set(id, false, nil, true)
					else
						Cmd.run(id, a ~= "" and a or nil, true)
					end
				end)
				if not ok then
					bad += 1
					T.ok(false, id .. " [" .. a .. "] threw: " .. tostring(err))
				end
				for _, e in ipairs(fresh()) do
					bad += 1
					T.ok(false, id .. " [" .. a .. "] logged: " .. e)
				end
			end
			if def.kind == "toggle" and Cmd.on[id] then
				T.ok(false, id .. " stays on after being turned off")
				Cmd.set(id, false, nil, true)
			end
		end
	end
	env.frame(1)
	T.eq(bad, 0, "no errors from any command")
	T.eq(Cmd.activeCount(), 0, "and every toggle is off again")
	Cmd.run("loop", "stop", true)
end

T.section("automation: aliases")
do
	T.eq(Cmd.run("alias", "", true), true, "listing with nothing saved is fine")
	T.ok(Cmd.run("alias", "hi prefix #", true), "a shortcut is made")
	T.ok(Cmd.by.hi ~= nil and Cmd.by.hi.userAlias == true, "and it is a real command")
	T.eq(Cmd.by.hi.kind, "action", "an action")
	T.eq(Cmd.tokens.hi, "hi", "its name is reserved")
	T.ok(string.find(Cmd.by.hi.desc, "prefix #", 1, true) ~= nil, "the description says what it runs")
	T.eq(Cmd.val("alias", "map").hi, "prefix #", "and it is saved")
	T.ok(Cmd.run("hi", nil, true), "it runs")
	T.eq(S.prefix, "#", "and did what it says")
	Cmd.run("prefix", ";", true)
	T.eq(S.prefix, ";", "prefix back")
	T.eq(Cmd.run("alias", "fly say no", true), false, "a name the hub uses is refused")
	T.eq(Cmd.run("alias", "cfly say no", true), false, "so is one of its short names")
	T.eq(Cmd.run("alias", "unfly say no", true), false, "and the off form of a toggle")
	T.eq(Cmd.run("alias", "9bad say no", true), false, "a name must start with a letter")
	T.eq(Cmd.run("alias", "bad-name say no", true), false, "and be letters and numbers")
	T.eq(Cmd.run("alias", string.rep("a", 21) .. " say no", true), false, "and not too long")
	T.eq(Cmd.run("alias", "list x", true), false, "list is a word the command uses")
	T.eq(Cmd.run("alias", "justname", true), false, "a command is needed")
	T.eq(Cmd.run("alias", "long " .. string.rep("x", 201), true), false, "and not too long")
	T.ok(Cmd.run("alias", "hi prefix !", true), "a shortcut can be redefined")
	T.ok(string.find(Cmd.by.hi.desc, "prefix !", 1, true) ~= nil, "to the new command")
	T.eq(#Cmd.check(), 0, "redefining makes no clash")
	T.ok(Cmd.run("alias", "hi2 prefix ;", true), "a second one")
	T.ok(Cmd.run("hi2", nil, true), "which runs")
	T.eq(S.prefix, ";", "prefix is the same")
	T.ok(Cmd.run("alias", "list", true), "the list")
	T.ok(Cmd.run("delalias", "hi", true), "it is deleted")
	T.eq(Cmd.by.hi, nil, "gone from the registry")
	T.eq(Cmd.tokens.hi, nil, "and the name is free")
	T.eq(Cmd.val("alias", "map").hi, nil, "and from the saved list")
	T.eq(Cmd.run("delalias", "hi", true), false, "twice fails")
	T.eq(Cmd.run("delalias", "", true), false, "nothing named")
	T.ok(Cmd.run("delalias", "hi2", true), "second deleted")
	T.eq(Cmd.remove("cfly"), false, "remove only takes real ids, not short names")
	T.ok(Cmd.by.cfly ~= nil, "cframefly is still reachable by its short name")
	T.eq(Cmd.remove("nothing_here"), false, "unknown id")
	T.eq(#Cmd.check(), 0, "no clashes at the end")
	for i = 1, 60 do
		Cmd.run("alias", "mine" .. string.rep("a", i % 5) .. i .. " prefix ;", true)
	end
	T.eq(Cmd.run("alias", "onemore prefix ;", true), false, "sixty is the most")
	for name in pairs(Cmd.val("alias", "map")) do
		Cmd.run("delalias", name, true)
	end
	T.eq(next(Cmd.val("alias", "map")), nil, "all removed")
end

T.section("automation: combos")
do
	T.ok(Cmd.run("combo", "list", true), "list when empty")
	T.ok(Cmd.run("combo", "new party prefix ! | prefix ;", true), "a combo is saved")
	T.same(Cmd.val("combo", "chains").party, { "prefix !", "prefix ;" }, "with its steps")
	T.eq(Cmd.run("combo", "new bad", true), false, "no steps")
	T.eq(Cmd.run("combo", "new list prefix !", true), false, "a reserved name")
	T.eq(Cmd.run("combo", "new 1bad prefix !", true), false, "a bad name")
	T.eq(Cmd.run("combo", "new many " .. string.rep("prefix ! | ", 13) .. "prefix !", true), false, "too many steps")
	T.eq(Cmd.run("combo", "new empty |  | ", true), false, "only separators")
	T.ok(Cmd.run("combo", "party", true), "it runs")
	env.frame(2)
	T.eq(S.prefix, ";", "and the steps ran in order")
	T.eq(Cmd.run("combo", "nope", true), false, "unknown combo")
	T.ok(Cmd.run("combo", "delete party", true), "deleted")
	T.eq(Cmd.run("combo", "delete party", true), false, "twice fails")
	T.ok(Cmd.run("combo", "new a prefix ;", true), "another")
	T.ok(Cmd.run("combo", "clear", true), "clear")
	T.eq(next(Cmd.val("combo", "chains")), nil, "nothing left")
end

T.section("automation: exceptions")
do
	T.ok(Cmd.run("exceptions", "", true), "list when empty")
	T.ok(Cmd.run("exceptions", "add Bob", true), "add a name")
	T.same(Cmd.val("exceptions", "names"), { "Bob" }, "it is saved")
	T.same(Cmd.val("exceptions", "names"), { "Bob" }, "still one")
	T.ok(Cmd.run("exceptions", "add bob", true), "adding again is fine")
	T.eq(#Cmd.val("exceptions", "names"), 1, "but not twice")
	T.eq(kit.exceptions().bob, true, "the targeting code sees it, lower case")
	T.eq(Cmd.run("exceptions", "remove nobody", true), false, "removing a stranger fails")
	T.eq(Cmd.run("exceptions", "add", true), false, "a name is needed")
	T.eq(Cmd.run("exceptions", "frob x", true), false, "unknown word")
	T.ok(Cmd.run("exceptions", "remove BOB", true), "remove ignores case")
	T.same(Cmd.val("exceptions", "names"), {}, "empty again")
	for i = 1, 50 do
		Cmd.run("exceptions", "add name" .. i, true)
	end
	T.eq(Cmd.run("exceptions", "add one_more", true), false, "fifty is the most")
	T.ok(Cmd.run("exceptions", "clear", true), "clear")
	T.same(Cmd.val("exceptions", "names"), {}, "nothing left")
end

T.section("automation: loop, runafter, lastcmd")
do
	T.eq(Cmd.run("loop", "abc prefix #", true), false, "the count must be a number")
	T.eq(Cmd.run("loop", "3", true), false, "a command is needed")
	T.eq(Cmd.run("loop", "stop", true), false, "nothing to stop")
	T.ok(Cmd.run("loop", "3 prefix #", true), "a loop starts")
	env.frame(3)
	T.eq(S.prefix, "#", "and ran")
	Cmd.run("prefix", ";", true)
	for _ = 1, 5 do
		T.ok(Cmd.run("loop", "100 prefix ;", true), "up to five at once")
	end
	T.eq(Cmd.run("loop", "100 prefix ;", true), false, "not a sixth")
	T.ok(Cmd.run("loop", "stop", true), "stop cancels them")
	env.frame(1)
	T.eq(Cmd.run("loop", "stop", true), false, "and nothing is left")
	T.eq(Cmd.run("runafter", "x prefix #", true), false, "seconds must be a number")
	T.eq(Cmd.run("runafter", "5", true), false, "a command is needed")
	T.ok(Cmd.run("runafter", "1 prefix #", true), "run later")
	T.eq(S.prefix, ";", "not yet")
	env.frame(2)
	T.eq(S.prefix, "#", "now")
	Cmd.run("prefix", ";", true)
	for _ = 1, 20 do
		Cmd.run("runafter", "600 prefix ;", true)
	end
	T.eq(Cmd.run("runafter", "600 prefix ;", true), false, "twenty waiting is the most")
	S.cmdHistory = {}
	T.eq(Cmd.run("lastcmd", nil, true), false, "no history")
	S.cmdHistory = { "lastcmd", "prefix #" }
	T.ok(Cmd.run("lastcmd", nil, true), "repeat skips itself")
	T.eq(S.prefix, "#", "and repeated the one before")
	Cmd.run("prefix", ";", true)
	S.cmdHistory = { "lastcmd" }
	T.eq(Cmd.run("lastcmd", nil, true), false, "only itself in the history")
end

T.section("automation: prefix and toggle")
do
	T.ok(Cmd.run("prefix", "!", true), "change the prefix")
	T.eq(S.prefix, "!", "it changed")
	T.eq(Cmd.run("prefix", "ab", true), false, "one symbol only")
	T.eq(Cmd.run("prefix", "a", true), false, "not a letter")
	T.eq(Cmd.run("prefix", "/", true), false, "not the Roblox key")
	T.eq(Cmd.run("prefix", "", true), false, "something is needed")
	T.eq(S.prefix, "!", "unchanged by the failures")
	T.ok(Cmd.run("prefix", ";", true), "and back")
	T.eq(Cmd.run("toggle", "", true), false, "toggle needs a command")
	T.eq(Cmd.run("toggle", "age", true), false, "an action has no switch")
	T.eq(Cmd.run("toggle", "nothing", true), false, "unknown")
	T.ok(Cmd.run("toggle", "bounce", true), "flip on")
	T.eq(Cmd.isOn("bounce"), true, "it is on")
	T.ok(Cmd.run("toggle", "bounce", true), "flip off")
	T.eq(Cmd.isOn("bounce"), false, "it is off")
end

T.section("automation: key binds")
do
	local uis = game:GetService("UserInputService")
	for key in pairs(Cmd.val("bind", "map", {})) do
		Cmd.run("unbind", key, true)
	end
	T.eq(next(Cmd.val("bind", "map", {})), nil, "nothing is bound to start with")
	T.ok(Cmd.run("bind", "list", true), "list when empty")
	T.ok(Cmd.run("bind", "f prefix #", true), "bind a key")
	T.eq(Cmd.val("bind", "map").F, "prefix #", "it is saved under the key's name")
	T.eq(Cmd.run("bind", "f", true), false, "a command is needed")
	T.eq(Cmd.run("bind", "Escape prefix #", true), false, "Roblox keeps Escape")
	T.eq(Cmd.run("bind", "Tab prefix #", true), false, "and Tab")
	T.ok(Cmd.run("bind", "7 prefix #", true), "digits work")
	T.eq(Cmd.val("bind", "map").Seven, "prefix #", "as their key name")
	local function press(name, processed)
		uis.InputBegan:Fire({ KeyCode = { Name = name }, UserInputType = Enum.UserInputType.Keyboard }, processed == true)
	end
	press("F", true)
	T.eq(S.prefix, ";", "a key the game used is ignored")
	press("G", false)
	T.eq(S.prefix, ";", "a key with no binding does nothing")
	press("F", false)
	T.eq(S.prefix, "#", "the bound key runs its command")
	Cmd.run("prefix", ";", true)
	T.ok(Cmd.run("unbind", "f", true), "unbind")
	T.eq(Cmd.run("unbind", "f", true), false, "twice fails")
	T.ok(Cmd.run("unbind", "7", true), "digit unbind")
	T.eq(next(Cmd.val("bind", "map")), nil, "nothing left")
end

T.section("automation: onjoin and onleave")
do
	local fake = { Name = "Zed", DisplayName = "Zed", UserId = 9001 }
	Cmd.setVal("onjoin", "text", "")
	Cmd.setVal("onleave", "text", "")
	T.eq(Cmd.set("onjoin", true, nil, true), false, "needs something to run")
	T.ok(Cmd.set("onjoin", true, "prefix #", true), "starts with a command")
	T.eq(Cmd.isOn("onjoin"), true, "on")
	env.core.ctx.Players.PlayerAdded:Fire(fake)
	T.eq(S.prefix, "#", "a join ran it")
	Cmd.run("prefix", ";", true)
	T.ok(Cmd.set("onjoin", false, nil, true), "off")
	env.core.ctx.Players.PlayerAdded:Fire({ Name = "Late", DisplayName = "Late", UserId = 9002 })
	T.eq(S.prefix, ";", "after it is off a join does nothing")
	T.ok(Cmd.set("onjoin", true, nil, true), "it remembers the last command")
	Cmd.set("onjoin", false, nil, true)
	T.ok(Cmd.set("onleave", true, "prefix !", true), "onleave starts")
	env.core.ctx.Players.PlayerRemoving:Fire(fake)
	T.eq(S.prefix, "!", "a leave ran it")
	Cmd.set("onleave", false, nil, true)
	Cmd.run("prefix", ";", true)
	T.eq(env.core.ctx.LP and S.prefix, ";", "prefix back")
end

T.section("automation: chat commands")
do
	local sent = {}
	local tcs = game:GetService("TextChatService")
	local channels = Instance.new("Folder")
	channels.Name = "TextChannels"
	local general = Instance.new("Folder")
	general.Name = "RBXGeneral"
	general.SendAsync = function(_, text)
		sent[#sent + 1] = text
	end
	general.Parent = channels
	channels.Parent = tcs
	kit.lastChat = nil
	T.eq(Cmd.run("say", "", true), false, "say needs words")
	T.ok(Cmd.run("say", "hello there", true), "say sends")
	T.eq(sent[#sent], "hello there", "the words went out")
	T.eq(Cmd.run("say", "again", true), false, "two in a row is too fast")
	T.eq(#sent, 1, "so only one went")
	env.frame(2)
	kit.lastChat = nil
	T.eq(Cmd.run("exit", "", true), false, "exit asks first")
	T.eq(Cmd.run("exit", "maybe", true), false, "and wants a clear yes")
	T.eq(Cmd.run("whisper", "", true), false, "whisper needs a name")
	T.eq(Cmd.run("whisper", "someone", true), false, "and words")
	T.ok(Cmd.set("spam", true, "buy now", true), "spam starts")
	T.eq(Cmd.run("spam", "x", true), true, "asking again just updates it")
	env.frame(6)
	T.ok(#sent >= 2, "and it keeps talking, slowly")
	Cmd.set("spam", false, nil, true)
	local count = #sent
	env.frame(12)
	T.eq(#sent, count, "off means silence")
	T.eq(Cmd.set("spam", true, "", true), true, "it remembers the last text")
	Cmd.set("spam", false, nil, true)
	channels:Destroy()
end

T.section("packs: a pack that closed the game is switched off")
do
	local files = {
		["Atsuko Hub/settings.json"] = '{"lastVersion":"1.6.1"}',
		["Atsuko Hub/boot.json"] = '{"v":1,"stage":"ready","ok":false,"doing":"pack:extras","n":0}',
	}
	local e1 = Runner.boot({ seconds = 8, files = files })
	T.eq(e1.core.Boot.safe, true, "the next start is a safe start")
	T.eq(e1.core.packBlamed, "extras", "the pack is blamed")
	T.eq(e1.hub.S.skipPacks.extras, true, "and written down")
	T.eq(e1.core.cmdPacks and e1.core.cmdPacks.skipped, true, "safe mode loads no packs")
	T.eq(e1.core.ctx.Cmd.by.bounce, nil, "so none of their commands exist")
	T.ok(e1.core.ctx.Cmd.by.fly ~= nil, "but the hub's own commands do")
	local e2 = Runner.boot({
		seconds = 8,
		files = {
			["Atsuko Hub/settings.json"] = e1.files["Atsuko Hub/settings.json"],
			["Atsuko Hub/boot.json"] = e1.files["Atsuko Hub/boot.json"],
		},
	})
	T.eq(e2.core.Boot.safe, false, "the start after that is normal")
	local p2 = e2.core.cmdPacks
	T.eq(p2 and #p2.loaded, 7, "seven packs load")
	T.ok(p2 and p2.failed.extras ~= nil, "and the blamed one is left out")
	T.eq(e2.core.ctx.Cmd.by.bounce, nil, "its commands are missing")
	T.ok(e2.core.ctx.Cmd.by.equiptools ~= nil, "the others are there")
	T.eq(#e2.core.ctx.Cmd.check(), 0, "no clashes")
	T.eq(#e2.errors, 0, "no errors: " .. table.concat(e2.errors, " | "))
	local e3 = Runner.boot({
		seconds = 8,
		files = {
			["Atsuko Hub/settings.json"] = string.gsub(e1.files["Atsuko Hub/settings.json"], '"lastVersion":"[^"]*"', '"lastVersion":"1.4.0"'),
			["Atsuko Hub/boot.json"] = e1.files["Atsuko Hub/boot.json"],
		},
	})
	T.eq(e3.hub.S.skipPacks.extras, nil, "a new version tries the pack again")
	T.eq(e3.core.cmdPacks and #e3.core.cmdPacks.loaded, 8, "all eight load")
end

T.section("packs: a pack that throws does not stop the others")
do
	local e = Runner.boot({
		seconds = 8,
		files = {
			["Atsuko Hub/Hub/modules/cmds/tools.lua"] = "local Pack = {}\nfunction Pack.init(ctx)\n\terror('boom')\nend\nreturn Pack\n",
		},
	})
	local p = e.core.cmdPacks
	T.ok(p and p.failed.tools ~= nil, "the broken pack is reported")
	T.eq(p and #p.loaded, 7, "the rest load")
	T.ok(e.core.ctx.Cmd.by.bounce ~= nil, "their commands work")
	T.eq(e.core.ctx.Cmd.by.equiptools, nil, "the broken pack's commands are missing")
	local logged = false
	for _, item in ipairs(e.hub.Log.items) do
		if item.kind == "error" and string.find(item.msg, "boom", 1, true) then
			logged = true
		end
	end
	T.ok(logged, "and the Console says why")
	T.eq(e.mainOk, true, "the hub itself started")
end
