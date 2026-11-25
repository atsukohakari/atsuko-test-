local IM = loadmodule("Hub/modules/inputmode.lua")

local function facts(t)
	return {
		touch = t.touch or false,
		keyboard = t.keyboard or false,
		mouse = t.mouse or false,
		gamepad = t.gamepad or false,
		tenFoot = t.tenFoot or false,
		lastInput = t.last,
		override = t.override or "auto",
	}
end

local rows = {
	{ "phone", { touch = true }, "touch" },
	{ "tablet", { touch = true }, "touch" },
	{ "phone with bluetooth keyboard", { touch = true, keyboard = true }, "touch" },
	{ "emulator that fakes a keyboard", { touch = true, keyboard = true }, "touch" },
	{ "emulator keyboard last input keyboard", { touch = true, keyboard = true, last = "keyboard" }, "touch" },
	{ "phone with keyboard, last input touch", { touch = true, keyboard = true, last = "touch" }, "touch" },
	{ "tablet with gamepad", { touch = true, gamepad = true }, "touch" },
	{ "touch laptop last touch", { touch = true, keyboard = true, mouse = true, last = "touch" }, "touch" },
	{ "touch laptop last keyboard", { touch = true, keyboard = true, mouse = true, last = "keyboard" }, "desktop" },
	{ "touch laptop last mouse", { touch = true, keyboard = true, mouse = true, last = "mouse" }, "desktop" },
	{ "touch laptop last gamepad", { touch = true, keyboard = true, mouse = true, last = "gamepad" }, "desktop" },
	{ "touch laptop unknown last input", { touch = true, keyboard = true, mouse = true }, "touch" },
	{ "tablet with mouse last mouse", { touch = true, mouse = true, last = "mouse" }, "desktop" },
	{ "tablet with mouse last touch", { touch = true, mouse = true, last = "touch" }, "touch" },
	{ "desktop", { keyboard = true, mouse = true }, "desktop" },
	{ "desktop last mouse", { keyboard = true, mouse = true, last = "mouse" }, "desktop" },
	{ "desktop last keyboard", { keyboard = true, mouse = true, last = "keyboard" }, "desktop" },
	{ "desktop with gamepad", { keyboard = true, mouse = true, gamepad = true }, "desktop" },
	{ "desktop with stray touch flag off", { keyboard = true }, "desktop" },
	{ "nothing detected", {}, "desktop" },
	{ "console", { gamepad = true, tenFoot = true }, "desktop" },
	{ "console with touch flag", { gamepad = true, tenFoot = true, touch = true }, "desktop" },
	{ "ten foot interface alone", { tenFoot = true }, "desktop" },
	{ "gamepad only", { gamepad = true }, "desktop" },
	{ "gamepad with keyboard", { gamepad = true, keyboard = true }, "desktop" },
	{ "always on desktop", { keyboard = true, mouse = true, override = "always" }, "touch" },
	{ "always on console", { gamepad = true, tenFoot = true, override = "always" }, "touch" },
	{ "always on phone", { touch = true, override = "always" }, "touch" },
	{ "never on phone", { touch = true, override = "never" }, "desktop" },
	{ "never on phone with keyboard", { touch = true, keyboard = true, override = "never" }, "desktop" },
	{ "never on tablet", { touch = true, last = "touch", override = "never" }, "desktop" },
	{ "never on desktop", { keyboard = true, mouse = true, override = "never" }, "desktop" },
	{ "auto spelled out", { touch = true, override = "auto" }, "touch" },
	{ "unknown override behaves like auto", { touch = true, override = "banana" }, "touch" },
}

T.section("inputmode: decide truth table")
T.ok(#rows >= 30, "at least 30 rows")
for _, row in ipairs(rows) do
	T.eq(IM.decide(facts(row[2])), row[3], row[1])
end

T.section("inputmode: keyboard alone never hides the arrow")
for _, kb in ipairs({ true, false }) do
	for _, last in ipairs({ "touch", "keyboard", "mouse", "gamepad" }) do
		T.eq(IM.decide(facts({ touch = true, keyboard = kb, last = last })), "touch", "touch without mouse, keyboard " .. tostring(kb) .. ", last " .. last)
	end
end

T.section("inputmode: overrideOf")
T.eq(IM.overrideOf("always"), "always")
T.eq(IM.overrideOf("never"), "never")
T.eq(IM.overrideOf("auto"), "auto")
T.eq(IM.overrideOf(nil), "auto")
T.eq(IM.overrideOf(5), "auto")

T.section("inputmode: classify input types")
T.eq(IM.classify("UserInputType.Touch"), "touch")
T.eq(IM.classify("Enum.UserInputType.Touch"), "touch")
T.eq(IM.classify("Touch"), "touch")
T.eq(IM.classify("Keyboard"), "keyboard")
T.eq(IM.classify("MouseMovement"), "mouse")
T.eq(IM.classify("MouseButton1"), "mouse")
T.eq(IM.classify("MouseWheel"), "mouse")
T.eq(IM.classify("Gamepad1"), "gamepad")
T.eq(IM.classify("Gamepad8"), "gamepad")
T.eq(IM.classify("Focus"), nil)
T.eq(IM.classify("Accelerometer"), nil)
T.eq(IM.classify(nil), nil)

T.section("inputmode: hysteresis holds a flip for 2 seconds")
local st = { mode = nil, since = -100 }
local mode, changed = IM.settle(st, "touch", 0, 2)
T.eq(mode, "touch")
T.ok(changed)
mode, changed = IM.settle(st, "touch", 0.5, 2)
T.eq(mode, "touch")
T.ok(not changed)
mode, changed = IM.settle(st, "desktop", 1, 2)
T.eq(mode, "touch")
T.ok(not changed)
mode, changed = IM.settle(st, "desktop", 1.9, 2)
T.eq(mode, "touch")
T.ok(not changed)
mode, changed = IM.settle(st, "desktop", 2.1, 2)
T.eq(mode, "desktop")
T.ok(changed)
mode, changed = IM.settle(st, "touch", 3, 2)
T.eq(mode, "desktop")
T.ok(not changed)
mode, changed = IM.settle(st, "touch", 3, 2, true)
T.eq(mode, "touch")
T.ok(changed)

T.section("inputmode: flicker never changes the mode twice inside the hold")
st = { mode = nil, since = -100 }
IM.settle(st, "touch", 0, 2)
local flips = 0
for i = 1, 40 do
	local want = (i % 2 == 0) and "touch" or "desktop"
	local _, ch = IM.settle(st, want, 0.05 * i, 2)
	if ch then
		flips = flips + 1
	end
end
T.eq(flips, 0)

T.section("inputmode: roblox layer with a fake input service")
local Mock = loadmodule("Testing/mocks/roblox_mock.lua")
local env = Mock.install({})
local uis = {
	TouchEnabled = true,
	KeyboardEnabled = true,
	MouseEnabled = false,
	GamepadEnabled = false,
	LastInputTypeChanged = Mock.Signal.new(),
	GetLastInputType = function()
		return "UserInputType.Touch"
	end,
}
local fired = {}
env.ctx.Bus.on("inputmode", function(m)
	fired[#fired + 1] = m
end)
env.ctx.UserInputService = uis
env.ctx.S.edgeMode = "auto"
env.ctx.Core.InputMode = nil
IM.init(env.ctx)
T.eq(IM.get(), "touch")
T.eq(env.ctx.Core.InputMode, IM)
T.eq(fired[1], "touch")
uis.MouseEnabled = true
uis.LastInputTypeChanged:Fire("UserInputType.Keyboard")
T.eq(IM.get(), "touch")
env.advance(2.2)
T.eq(IM.get(), "desktop")
T.eq(fired[#fired], "desktop")
uis.LastInputTypeChanged:Fire("UserInputType.Touch")
env.advance(0.5)
T.eq(IM.get(), "desktop")
env.advance(2)
T.eq(IM.get(), "touch")
env.ctx.S.edgeMode = "never"
IM.refresh(true)
T.eq(IM.get(), "desktop")
env.ctx.S.edgeMode = "always"
IM.refresh(true)
T.eq(IM.get(), "touch")
IM.destroy()
T.eq(uis.LastInputTypeChanged:Count(), 0)
