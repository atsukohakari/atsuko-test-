local Runner = loadmodule("Testing/mocks/boot_runner.lua")
local Diag = loadmodule("Hub/modules/diagnostics.lua")

local function has(text, needle)
	return string.find(text, needle, 1, true) ~= nil
end

local function all(root, pred)
	local out = {}
	for _, d in ipairs(root:GetDescendants()) do
		if pred(d) then
			out[#out + 1] = d
		end
	end
	return out
end

T.section("diagnostics: the text builder")
do
	local plain = Diag.build({})
	T.ok(has(plain, "Atsuko Hub diagnostics"), "it has a title")
	T.ok(has(plain, "Executor: unknown"), "missing facts are filled with plain words")
	T.ok(has(plain, "Recent problems, newest first:\n  none"), "no problems says none")
	T.eq(Diag.build(nil), plain, "nil is the same as nothing")
	T.eq(Diag.build("text"), plain, "so is a wrong type")

	local text = Diag.build({
		version = "Beta v1.5.0",
		origin = "Atsuko Hub",
		executor = "Test Executor",
		placeId = 123,
		device = { touch = true, keyboard = false, gamepad = true },
		screen = "1280 x 720",
		boot = { safe = true, step = "pack:extras", flipped = { "Smart Stop", "Catch other scripts' pop-ups" } },
		hooks = { chat = true, notices = false, smartStop = true },
		packs = { loaded = { "world", "info" }, failed = { extras = "turned off after a crash" }, skipped = false, built = 179 },
		commands = { total = 245, active = { "fly", "bounce" }, conflicts = 0 },
		modules = { ok = { "prefix", "dispatch" }, failed = { credits_ui = "boom" } },
		have = { writefile = true, readfile = true },
		errors = { "error  Commands: one", "warn  Hub: two" },
	})
	T.ok(has(text, "Version: Beta v1.5.0"), "version")
	T.ok(has(text, "Started from: Atsuko Hub"), "where it started")
	T.ok(has(text, "Executor: Test Executor"), "executor")
	T.ok(has(text, "Place: 123"), "place")
	T.ok(has(text, "Device: touch, gamepad"), "device")
	T.ok(has(text, "Screen: 1280 x 720"), "screen")
	T.ok(has(text, "Safe mode: on, the last start stopped at pack:extras"), "safe mode and where")
	T.ok(has(text, "Turned off after a crash: Catch other scripts' pop-ups, Smart Stop"), "what was switched off, sorted")
	T.ok(has(text, "Hooks switched on: chat, smartStop"), "only the hooks that are on")
	T.ok(has(text, "Command packs: info, world  (179 commands built)"), "packs sorted with the count")
	T.ok(has(text, "Command packs that did not load: extras (turned off after a crash)"), "failed packs and why")
	T.ok(has(text, "Commands: 245 in the list, 0 name clashes"), "command counts")
	T.ok(has(text, "Commands switched on: bounce, fly"), "active commands sorted")
	T.ok(has(text, "Modules loaded: dispatch, prefix"), "modules")
	T.ok(has(text, "Modules that failed: credits_ui (boom)"), "failed module and why")
	T.ok(has(text, "Executor functions missing: isfile"), "missing functions start at the first one not present")
	T.ok(has(text, "Last name badge: none drawn yet"), "it says when no name badge has been drawn")
	T.ok(has(Diag.build({ badge = "name TextSize 18, badge 23" }), "Last name badge: name TextSize 18, badge 23"), "and the sizes of the last one when there is one")
	T.ok(has(text, "  error  Commands: one\n  warn  Hub: two"), "the problems, in the order given")

	local skipped = Diag.build({ packs = { skipped = true } })
	T.ok(has(skipped, "Command packs: left out (safe mode)"), "safe mode skips packs and says so")

	local many = {}
	for i = 1, 40 do
		many[i] = "error  X: " .. i
	end
	local capped = Diag.build({ errors = many })
	local count = select(2, string.gsub(capped, "\n  error  X:", ""))
	T.eq(count, Diag.MAX_ERRORS, "only the newest problems are listed")

	local long = Diag.build({ errors = { string.rep("y", 1000) }, executor = string.rep("z", 1000) .. "\nsecond line" })
	for line in string.gmatch(long, "[^\n]+") do
		T.ok(#line <= Diag.MAX_LINE + 40, "no line is huge: " .. #line)
	end
	T.ok(not has(long, "second line"), "a newline inside a fact cannot make a fake line")
end

T.section("diagnostics: missing executor functions")
do
	T.same(Diag.missing({}), Diag.CHECKED, "everything is missing from an empty list")
	local have = {}
	for _, key in ipairs(Diag.CHECKED) do
		have[key] = true
	end
	T.same(Diag.missing(have), {}, "nothing is missing from a full list")
	have.request = false
	T.same(Diag.missing(have), { "request" }, "false counts as missing")
	T.same(Diag.missing(nil), Diag.CHECKED, "nil counts as everything missing")
	T.eq(Diag.deviceText({}), "unknown", "no device known")
	T.eq(Diag.deviceText(nil), "unknown", "no device table")
end

T.section("diagnostics: inside the running hub")
do
	local env = Runner.boot({ seconds = 8 })
	local core = env.core
	local text, why = core.diagnostics()
	T.ok(text ~= nil, "the hub can build it: " .. tostring(why))
	text = text or ""
	T.ok(has(text, "Version: v1.6.1"), "it names the version")
	T.ok(has(text, "Command packs: "), "it lists the command packs")
	T.ok(has(text, "(179 commands built)"), "and how many commands they built")
	T.ok(has(text, "Safe mode: off"), "safe mode is off on a normal start")
	T.ok(has(text, "0 name clashes"), "no name clashes")
	T.ok(has(text, "Executor functions missing:"), "it lists missing executor functions")
	for _, secret in ipairs({ "OWNER", "owner.key", "token", "Token", "password", "Password", "cookie", "ROBLOSECURITY", "key =" }) do
		T.ok(not has(text, secret), "no sign of " .. secret)
	end
	T.ok(#text < 6000, "it is short enough to paste: " .. #text)

	env.hub.Log.add("error", "Test", "something broke")
	local again = core.diagnostics()
	T.ok(has(again, "error  Test: something broke"), "a new error shows up")

	env.hub.Panel.show("settings")
	env.run(1)
	env.hub.Panel.setTab(env.hub.Pages.settings, 5)
	env.run(3)
	local labels = all(env.hub.Gui, function(d)
		return d:IsA("TextLabel") and d.Text == "Copy diagnostics"
	end)
	T.eq(#labels, 1, "the About page has a Copy diagnostics row")
	local row = labels[1]
	local button
	local node = row
	while node and not button do
		if node:IsA("TextButton") or node:IsA("ImageButton") then
			button = node
		end
		node = node.Parent
	end
	T.ok(button ~= nil, "and it is a button")
	if button then
		env.clipboard = nil
		button.Activated:Fire()
		env.run(0.3)
		T.ok(env.clipboard ~= nil and has(env.clipboard, "Atsuko Hub diagnostics"), "tapping it copies the text")
	end

	local broken = Runner.boot({
		seconds = 8,
		files = { ["Atsuko Hub/Hub/modules/diagnostics.lua"] = "this is not lua" },
	})
	local bad, reason = broken.core.diagnostics()
	T.eq(bad, nil, "a broken module gives no text")
	T.ok(type(reason) == "string" and reason ~= "", "and a reason")
	T.eq(broken.mainOk, true, "and the hub still starts")
end
