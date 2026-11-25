local Runner = loadmodule("Testing/mocks/boot_runner.lua")

local function uis()
	return game:GetService("UserInputService")
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

local function named(root, name)
	return all(root, function(d)
		return d.Name == name
	end)
end

local function first(root, name)
	return named(root, name)[1]
end

local function withText(root, text)
	return all(root, function(d)
		return (d:IsA("TextLabel") or d:IsA("TextButton") or d:IsA("TextBox")) and d.Text == text
	end)[1]
end

local function errorsOf(env)
	local out = {}
	for _, item in ipairs(env.hub.Log.items or {}) do
		if item.kind == "error" then
			out[#out + 1] = tostring(item.src) .. ": " .. tostring(item.msg)
		end
	end
	return out
end

local function key(c)
	return math.floor(c.R * 255 + 0.5) * 65536 + math.floor(c.G * 255 + 0.5) * 256 + math.floor(c.B * 255 + 0.5)
end

local function rgbKey(r, g, b)
	return r * 65536 + g * 256 + b
end

local function tap(btn)
	btn.Activated:Fire()
end

local function touch(x, y)
	return { UserInputType = Enum.UserInputType.Touch, Position = Vector3.new(x, y, 0) }
end

local function openThemes(env)
	env.hub.Panel.show("settings")
	env.run(1)
	env.hub.Panel.setTab(env.hub.Pages.settings, 2)
	env.run(3)
	return env.core.colorsBlock
end

local function palette(env)
	return env.core.ctx.T
end

local function drag(hit, track, fracs, pause)
	local ap, as = track.AbsolutePosition, track.AbsoluteSize
	local tch = touch(ap.X + fracs[1] * as.X, ap.Y + 3)
	hit.InputBegan:Fire(tch)
	for i = 2, #fracs do
		if pause then
			pause()
		end
		tch.Position = Vector3.new(ap.X + fracs[i] * as.X, ap.Y + 3, 0)
		uis().InputChanged:Fire(tch)
	end
	uis().InputEnded:Fire(tch)
end

local function slider(block, letter)
	local row = first(block.frame, "Slider_" .. letter)
	return row, first(row, "Hit"), first(row, "Track"), first(row, "Num")
end

local function dragChannel(env, block, letter, fracs)
	local _, hit, track = slider(block, letter)
	drag(hit, track, fracs, function()
		env.frame(0.06)
	end)
	env.run(0.4)
end

local function numbers(block)
	local _, _, _, r = slider(block, "R")
	local _, _, _, g = slider(block, "G")
	local _, _, _, b = slider(block, "B")
	return r.Text, g.Text, b.Text
end

local function rowOf(block, slot)
	return first(block.frame, "ColorRow_" .. slot)
end

local function valueOf(block, slot)
	return first(rowOf(block, slot), "Value").Text
end

local function toggleRow(block)
	for _, row in ipairs(named(block.frame, "Toggle")) do
		if withText(row, "Rainbow background") then
			return row
		end
	end
	return nil
end

local function speedRow(block)
	for _, row in ipairs(named(block.frame, "Slider")) do
		if withText(row, "One loop takes") then
			return row
		end
	end
	return nil
end

local env = Runner.boot({ seconds = 8 })
local hub = env.hub
local P = palette(env)
local startPanel = key(P.panel)

T.section("colors_ui: the block builds on the Themes tab")
local block = openThemes(env)
T.ok(block ~= nil and block.alive, "the colors block exists after opening Themes")
T.eq(#errorsOf(env), 0, "no hub errors: " .. table.concat(errorsOf(env), " | "))
T.ok(first(hub.Pages.settings.views[2], "ColorsHost") ~= nil, "it sits in the Themes view")
T.eq(first(hub.Pages.settings.views[2], "ColorsHost").LayoutOrder, 1, "right under the current theme card")
T.eq(first(hub.Pages.settings.views[2], "ThemeHero").LayoutOrder, 0, "which is the first thing")
T.ok(withText(block.frame, "Loading the color picker...") == nil, "the loading line is gone")
for _, slot in ipairs({ "bg", "card", "text", "accent" }) do
	T.ok(rowOf(block, slot) ~= nil, "a row for " .. slot)
	T.ok(rowOf(block, slot).Size.Y.Offset >= 44, "and it is at least 44 tall: " .. slot)
end
T.eq(valueOf(block, "bg"), "#101115", "the background row shows the Midnight background")
T.eq(valueOf(block, "card"), "#1C1D23", "the cards row")
T.eq(valueOf(block, "text"), "#F4F5F8", "the text row")
T.eq(valueOf(block, "accent"), "#C8A8FF", "the accent row")
T.eq(first(block.frame, "ColorPicker").Visible, false, "the picker is closed to begin with")
T.eq(env.core.ctx.S.rainbowBg, false, "the rainbow is off")
T.eq(env.core.ctx.S.rainbowBgPeriod, 90, "and its loop is 90 seconds")
T.ok(toggleRow(block) ~= nil, "the rainbow switch is there")
T.ok(speedRow(block) ~= nil, "and its speed")
T.ok(withText(block.frame, "Save as a new theme") ~= nil, "and the save-as-new action")
T.ok(startPanel ~= 0, "the hub starts on its Midnight surfaces")

T.section("colors_ui: picking the background by hex")
tap(rowOf(block, "bg"))
env.run(0.2)
local picker = first(block.frame, "ColorPicker")
T.eq(picker.Visible, true, "tapping a row opens the picker")
T.eq(first(picker, "PickTitle").Text, "Background", "titled after the row")
do
	local r, g, b = numbers(block)
	T.ok(r == "16" and g == "17" and b == "21", "the three boxes show 16, 17, 21 (" .. r .. ", " .. g .. ", " .. b .. ")")
end
T.eq(first(picker, "Hex").Text, "#101115", "and the hex box shows #101115")
T.eq(first(picker, "AutoBtn").Visible, false, "the background has no Auto button")
T.eq(first(picker, "Contrast").Visible, false, "and no contrast warning")
first(picker, "Hex").Text = "#336699"
env.run(0.3)
T.eq(key(P.panel), rgbKey(51, 102, 153), "typing a full hex recolours the hub: T.panel is #336699")
do
	local r, g, b = numbers(block)
	T.ok(r == "51" and g == "102" and b == "153", "the boxes follow: " .. r .. ", " .. g .. ", " .. b)
end
T.eq(key(first(rowOf(block, "bg"), "Swatch").BackgroundColor3), rgbKey(51, 102, 153), "so does the swatch")
T.eq(valueOf(block, "bg"), "#336699", "and the row text")
T.eq(block.dirty(), true, "the block knows it has unapplied colors")
T.eq(env.core.ctx.S.theme, "midnight", "the saved theme is still Midnight until Apply")
T.eq(env.core.ctx.S.bgTint, 0, "an exact color has no tint")
first(picker, "Hex").Text = "#12"
env.run(0.2)
T.eq(key(P.panel), rgbKey(51, 102, 153), "half a hex code changes nothing")
T.eq(first(picker, "Hex").TextColor3, P.text, "and is not shown as an error")
first(picker, "Hex").Text = "#12z"
env.run(0.2)
T.eq(key(P.panel), rgbKey(51, 102, 153), "a bad hex code changes nothing")
T.eq(first(picker, "Hex").TextColor3, P.red, "and shows red")
first(picker, "Hex").FocusLost:Fire(true)
env.run(0.2)
T.eq(first(picker, "Hex").Text, "#336699", "leaving the box puts the real color back")
first(picker, "Hex").Text = "#abcdef"
env.run(0.3)
T.eq(key(P.panel), rgbKey(171, 205, 239), "a second hex code works")
first(picker, "Hex").Text = "336699"
env.run(0.3)
T.eq(key(P.panel), rgbKey(51, 102, 153), "the hash is optional")

T.section("colors_ui: the R, G and B sliders")
dragChannel(env, block, "R", { 0.5, 0.5 })
T.eq(key(P.panel), rgbKey(128, 102, 153), "R halfway is 128")
dragChannel(env, block, "G", { 1, 1 })
T.eq(key(P.panel), rgbKey(128, 255, 153), "G at the far end is 255")
dragChannel(env, block, "B", { 0, 0 })
T.eq(key(P.panel), rgbKey(128, 255, 0), "B at the near end is 0")
dragChannel(env, block, "R", { 0.2, 5, 5 })
T.eq(key(P.panel), rgbKey(255, 255, 0), "dragging far past the right end stops at 255")
dragChannel(env, block, "R", { 0.2, -4, -4 })
T.eq(key(P.panel), rgbKey(0, 255, 0), "and far past the left end stops at 0")
do
	local r, g, b = numbers(block)
	T.ok(r == "0" and g == "255" and b == "0", "the boxes agree: " .. r .. ", " .. g .. ", " .. b)
	local _, _, track = slider(block, "G")
	local fill = first(track, "Fill")
	T.ok(math.abs(fill.Size.X.Scale - 1) < 0.001, "the G bar is full")
	local knob = first(track, "Knob")
	T.ok(math.abs(knob.Position.X.Scale - 1) < 0.001, "and its knob is at the end")
end
local _, _, _, rBox = slider(block, "R")
rBox.Text = "200"
env.run(0.3)
T.eq(key(P.panel), rgbKey(200, 255, 0), "typing 200 in the R box")
rBox.Text = "abc"
env.run(0.2)
T.eq(rBox.Text, "", "letters are thrown out as you type")
T.eq(key(P.panel), rgbKey(200, 255, 0), "and change nothing")
rBox.Text = "12345"
env.run(0.3)
T.eq(rBox.Text, "123", "three digits at most")
T.eq(key(P.panel), rgbKey(123, 255, 0), "and 123 is used")
rBox.Text = "999"
env.run(0.3)
T.eq(key(P.panel), rgbKey(255, 255, 0), "999 stops at 255")
rBox.Text = "7"
rBox.FocusLost:Fire(true)
env.run(0.3)
T.eq(key(P.panel), rgbKey(7, 255, 0), "leaving the box commits it")
T.eq(rBox.Text, "7", "and shows it")
rBox.Text = ""
rBox.FocusLost:Fire(true)
env.run(0.3)
T.eq(rBox.Text, "7", "an empty box goes back to the real value")

T.section("colors_ui: live preview is throttled to about 20 a second")
do
	local calls, finals = 0, 0
	local orig = env.core.applyThemeDef
	env.core.applyThemeDef = function(def, final)
		calls += 1
		if final then
			finals += 1
		end
		return orig(def, final)
	end
	local realClock = os.clock
	local fake = realClock()
	os.clock = function()
		return fake
	end
	local _, hit, track = slider(block, "B")
	local fracs = { 0.0 }
	for i = 1, 100 do
		fracs[#fracs + 1] = i / 100
	end
	drag(hit, track, fracs, function()
		fake += 0.01
		env.frame(0.01)
	end)
	for _ = 1, 12 do
		fake += 1 / 30
		env.frame(1 / 30)
	end
	os.clock = realClock
	env.core.applyThemeDef = orig
	T.ok(calls <= 26, "100 moves in a second made at most 26 recolours (" .. calls .. ")")
	T.ok(calls >= 8, "but it did keep up (" .. calls .. ")")
	T.eq(finals, 1, "and exactly one final one when the finger lifted")
	T.eq(key(P.panel), rgbKey(7, 255, 255), "the last position was applied, not a stale one")
end

T.section("colors_ui: the quick colors and the contrast guard")
do
	local quick = first(picker, "Quick7")
	tap(quick)
	env.run(0.3)
	T.eq(key(P.panel), rgbKey(234, 236, 242), "the seventh quick color for the background is the Cloud grey")
	T.eq(first(picker, "Contrast").Visible, true, "light text on a light background shows the warning")
	T.ok(string.find(first(picker, "Contrast").Text, "hard to read", 1, true) ~= nil, "in words")
	T.eq(first(picker, "FixText").Visible, true, "with a fix button")
	local ratio = tonumber(string.match(first(picker, "Contrast").Text, "%((%d+%.%d)"))
	T.ok(ratio ~= nil and ratio < 4.5, "and the ratio is under 4.5 (" .. tostring(ratio) .. ")")
	T.ok(key(P.panel) == rgbKey(234, 236, 242), "the warning did not stop the change")
	tap(first(picker, "FixText"))
	env.run(0.3)
	T.eq(first(picker, "Contrast").Visible, false, "Fix text colour makes the warning go")
	T.eq(first(picker, "FixText").Visible, false, "and the button")
	T.eq(key(P.text), rgbKey(0, 0, 0), "by taking black text")
	T.eq(valueOf(block, "text"), "#000000", "the text row says so")
	tap(rowOf(block, "text"))
	env.run(0.2)
	T.eq(first(picker, "PickTitle").Text, "Text", "the picker follows the row")
	T.eq(first(picker, "AutoBtn").Visible, true, "text has an Auto button")
	tap(first(picker, "AutoBtn"))
	env.run(0.3)
	T.eq(valueOf(block, "text"), "Auto", "Auto puts the row back to Auto")
	T.eq(first(picker, "Contrast").Visible, false, "auto text on a light background is dark, so no warning")
end

T.section("colors_ui: revert goes back with a tween")
do
	T.eq(block.dirty(), true, "there is something to revert")
	local seen = {}
	tap(first(picker, "Revert"))
	for _ = 1, 12 do
		env.frame(1 / 30)
		seen[key(P.panel)] = true
	end
	env.run(0.5)
	local n = 0
	for _ in pairs(seen) do
		n += 1
	end
	T.ok(n >= 3, "it passed through at least 3 different backgrounds on the way (" .. n .. ")")
	T.eq(key(P.panel), startPanel, "and ended on the Midnight background it started with")
	T.eq(block.dirty(), false, "nothing is left to revert")
	T.eq(env.core.ctx.S.theme, "midnight", "the theme never changed")
	T.eq(valueOf(block, "bg"), "#101115", "the background row says so")
	T.eq(valueOf(block, "card"), "#1C1D23", "the cards row")
	T.eq(valueOf(block, "text"), "#F4F5F8", "and the text row")
	local r, g, b = numbers(block)
	T.ok(r == "244" and g == "245" and b == "248", "and the boxes show the text color the picker is on (" .. r .. ", " .. g .. ", " .. b .. ")")
	tap(first(picker, "Revert"))
	env.run(0.3)
	T.eq(key(P.panel), startPanel, "reverting again with nothing changed does nothing")
end

T.section("colors_ui: apply saves a real theme")
do
	local S = env.core.ctx.S
	T.eq(#S.themes, 0, "no custom themes yet")
	tap(rowOf(block, "bg"))
	env.run(0.2)
	first(picker, "Hex").Text = "#223344"
	env.run(0.3)
	tap(first(picker, "Apply"))
	env.run(1)
	T.eq(#S.themes, 1, "Apply made a theme")
	local def = S.themes[1]
	T.eq(def.name, "My colors", "called My colors")
	T.eq(def.bg, "#223344", "with the background")
	T.eq(def.version, 2, "version 2")
	T.eq(def.rainbowBg, nil, "no rainbow flag")
	T.eq(S.theme, def.id, "and it is the theme now")
	T.eq(key(P.panel), rgbKey(34, 51, 68), "the hub shows it")
	T.ok(block.alive == false, "the page was drawn again, so there is a new block")
	local fresh = env.core.colorsBlock
	T.ok(fresh ~= nil and fresh ~= block and fresh.alive, "a fresh block took its place")
	block = fresh
	picker = first(block.frame, "ColorPicker")
	T.eq(valueOf(block, "bg"), "#223344", "its background row shows it")
	T.ok(withText(hub.Pages.settings.views[2], "My colors") ~= nil, "the theme card says My colors")
	local saved = env.files["AtsukoHub/settings.json"] or ""
	T.ok(string.find(saved, '"bg":"#223344"', 1, true) ~= nil, "and it was written to the settings file")
	T.ok(string.find(saved, '"version":2', 1, true) ~= nil, "with its version")
	tap(rowOf(block, "bg"))
	env.run(0.2)
	first(picker, "Hex").Text = "#334455"
	env.run(0.3)
	tap(first(picker, "Apply"))
	env.run(1)
	T.eq(#S.themes, 1, "applying again on your own theme changes it, it does not add one")
	T.eq(S.themes[1].bg, "#334455", "to the new color")
	block = env.core.colorsBlock
	picker = first(block.frame, "ColorPicker")
	tap(rowOf(block, "bg"))
	env.run(0.2)
	first(picker, "Hex").Text = "#445566"
	env.run(0.3)
	tap(withText(block.frame, "Save as a new theme").Parent)
	env.run(1)
	T.eq(#S.themes, 2, "Save as a new theme adds another")
	T.eq(S.themes[2].name, "My colors 2", "with the next name")
	T.eq(S.themes[1].bg, "#334455", "and leaves the first one alone")
	T.eq(S.theme, S.themes[2].id, "the new one is on")
	block = env.core.colorsBlock
	picker = first(block.frame, "ColorPicker")
end

T.section("colors_ui: leaving with unapplied colors puts everything back")
do
	local S = env.core.ctx.S
	tap(rowOf(block, "bg"))
	env.run(0.2)
	first(picker, "Hex").Text = "#aa0000"
	env.run(0.3)
	T.eq(key(P.panel), rgbKey(170, 0, 0), "a color is previewing")
	hub.Bus.fire("themes")
	env.run(1)
	T.eq(key(P.panel), rgbKey(68, 85, 102), "the page being drawn again undid the preview: your saved theme is back")
	T.eq(S.theme, S.themes[2].id, "and the theme did not change")
	block = env.core.colorsBlock
	T.ok(block ~= nil and block.alive and block.dirty() == false, "a clean block")
	picker = first(block.frame, "ColorPicker")
end

T.section("colors_ui: the accent")
do
	local S = env.core.ctx.S
	local before = S.accentHex
	tap(rowOf(block, "accent"))
	env.run(0.2)
	T.eq(first(picker, "PickTitle").Text, "Accent", "the accent row opens the picker")
	T.eq(first(picker, "AutoBtn").Visible, true, "with a Keep my accent button")
	first(picker, "Hex").Text = "#ff0000"
	env.run(0.3)
	T.eq(S.accent, "Custom", "a picked accent is a custom one")
	T.eq(S.accentHex, "#ff0000", "with the picked color")
	tap(first(picker, "AutoBtn"))
	env.run(0.3)
	T.eq(valueOf(block, "accent"), "Yours", "Keep my accent puts the row back")
	T.ok(S.accentHex == before, "and the accent you had before is back (" .. tostring(S.accentHex) .. ")")
	tap(first(picker, "Revert"))
	env.run(0.6)
	T.eq(block.dirty(), false, "reverted")
end

T.section("colors_ui: twenty themes is the limit")
do
	local S = env.core.ctx.S
	local keepName = S.themes[2].name
	local n = #S.themes
	for i = n + 1, 20 do
		S.themes[i] = { id = "c" .. (1000 + i) .. "_" .. i, name = "Filler " .. i, bg = "#101010", card = "", text = "", accent = "" }
	end
	tap(rowOf(block, "bg"))
	env.run(0.2)
	first(picker, "Hex").Text = "#202020"
	env.run(0.3)
	tap(withText(block.frame, "Save as a new theme").Parent)
	env.run(0.5)
	T.eq(#S.themes, 20, "still 20")
	T.eq(S.themes[2].name, keepName, "nothing was overwritten")
	T.eq(block.dirty(), true, "and your colors are still waiting")
	tap(first(picker, "Revert"))
	env.run(0.6)
	for i = #S.themes, n + 1, -1 do
		table.remove(S.themes, i)
	end
end

T.section("colors_ui: the rainbow background")
do
	local S = env.core.ctx.S
	local mod = env.core.mods.settings_colors.mod
	T.eq(mod.rainbowRunning(), false, "the rainbow is not running")
	local base = key(P.panel)
	tap(toggleRow(block))
	env.run(1.5)
	T.eq(S.rainbowBg, true, "the switch turns it on")
	T.eq(mod.rainbowRunning(), true, "and it runs")
	local a = key(P.panel)
	T.ok(a ~= base, "the background moved off the theme's color")
	local max = math.max(math.floor(a / 65536), math.floor(a / 256) % 256, a % 256)
	T.ok(max <= 52, "and it stays dark (brightest channel " .. max .. ")")
	T.eq(valueOf(block, "bg"), "Rainbow", "the row says Rainbow")
	T.eq(valueOf(block, "card"), "Rainbow", "the cards row")
	T.eq(valueOf(block, "text"), "Rainbow", "the text row")
	T.eq(valueOf(block, "accent"), "#C8A8FF", "the accent is yours")
	tap(rowOf(block, "bg"))
	env.run(0.3)
	T.eq(first(block.frame, "ColorPicker").Visible, false, "the background picker stays closed while it runs")
	env.run(20)
	local b = key(P.panel)
	T.ok(b ~= a, "20 seconds later the color has moved")
	local seen = {}
	for _ = 1, 12 do
		env.run(1)
		seen[key(P.panel)] = true
	end
	local n = 0
	for _ in pairs(seen) do
		n += 1
	end
	T.ok(n >= 3, "it changes smoothly, not in jumps (" .. n .. " different colors in 12 seconds)")
	local row = speedRow(block)
	local _, hit, track = (function()
		return row, first(row, "Hit"), first(row, "Track")
	end)()
	drag(hit, track, { 0, 0 }, function() end)
	env.run(0.5)
	T.eq(S.rainbowBgPeriod, 30, "the speed slider goes to 30 seconds at the left end")
	drag(hit, track, { 1, 1 }, function() end)
	env.run(0.5)
	T.eq(S.rainbowBgPeriod, 120, "and 120 at the right end")
	drag(hit, track, { 0.5, 0.5 }, function() end)
	env.run(0.5)
	T.ok(S.rainbowBgPeriod >= 70 and S.rainbowBgPeriod <= 80, "and about 75 in the middle (" .. S.rainbowBgPeriod .. ")")
	S.animations = false
	env.core.rainbowSync(true)
	env.run(2)
	T.eq(key(P.panel), base, "with Smooth animations off the background goes back to the theme's color")
	T.eq(mod.rainbowRunning(), true, "the loop is waiting")
	env.run(5)
	T.eq(key(P.panel), base, "and stays there")
	S.animations = true
	env.core.rainbowSync(true)
	env.run(3)
	T.ok(key(P.panel) ~= base, "turning the animations back on starts it again")
	tap(toggleRow(block))
	env.run(1.5)
	T.eq(S.rainbowBg, false, "the switch turns it off")
	T.eq(mod.rainbowRunning(), false, "the loop stops")
	T.eq(key(P.panel), base, "and the theme's own color is back")
	env.run(3)
	T.eq(key(P.panel), base, "and stays")
	T.eq(valueOf(block, "bg"), "#445566", "the background row shows the color again")
	tap(rowOf(block, "bg"))
	env.run(0.3)
	T.eq(first(block.frame, "ColorPicker").Visible, true, "and the picker opens again")
	tap(first(first(block.frame, "ColorPicker"), "Revert"))
	env.run(0.2)
end

T.section("colors_ui: a theme remembers the rainbow")
do
	local S = env.core.ctx.S
	local mod = env.core.mods.settings_colors.mod
	tap(toggleRow(block))
	env.run(1)
	T.eq(S.rainbowBg, true, "on")
	env.core.setTheme("ocean", true)
	env.run(1.5)
	T.eq(S.rainbowBg, false, "picking another theme turns the rainbow off, it was not part of that theme")
	T.eq(mod.rainbowRunning(), false, "the loop stopped")
	T.eq(key(P.panel), rgbKey(10, 17, 28), "and Ocean's own background is on")
	env.core.setTheme(S.themes[2].id, true)
	env.run(1)
	block = env.core.colorsBlock
	picker = first(block.frame, "ColorPicker")
	tap(toggleRow(block))
	env.run(1)
	tap(first(block.frame, "ColorRow_accent"))
	env.run(0.2)
	first(picker, "Hex").Text = "#44ccaa"
	env.run(0.3)
	T.eq(block.dirty(), true, "an accent change is waiting")
	tap(first(picker, "Apply"))
	env.run(1)
	T.eq(S.themes[2].rainbowBg, true, "applying while the rainbow runs saves the flag in the theme")
	block = env.core.colorsBlock
	env.core.setTheme("ocean", true)
	env.run(1)
	T.eq(S.rainbowBg, false, "Ocean has no rainbow")
	env.core.setTheme(S.themes[2].id, true)
	env.run(1.5)
	T.eq(S.rainbowBg, true, "and picking the saved theme brings it back")
	T.eq(mod.rainbowRunning(), true, "running again")
	env.core.setTheme("midnight", true)
	env.run(1)
	T.eq(mod.rainbowRunning(), false, "Midnight stops it")
end

T.section("colors_ui: the General tab points here")
do
	hub.Panel.setTab(hub.Pages.settings, 1)
	env.run(1)
	local look = withText(hub.Pages.settings.views[1], "Background, card, text and accent colors")
	T.ok(look ~= nil, "General > Look has a row for the colors")
	if look then
		tap(look.Parent)
		env.run(1)
		T.eq(hub.Pages.settings.tab, 2, "tapping it opens the Themes tab")
	end
end

T.section("colors_ui: nothing broke")
do
	local errs = errorsOf(env)
	T.eq(#errs, 0, "no errors in the log: " .. table.concat(errs, " | "))
end

T.section("colors_ui: the rainbow comes back after a reload")
do
	local e2 = Runner.boot({
		seconds = 8,
		files = { ["AtsukoHub/settings.json"] = jsonencode({ rainbowBg = true, rainbowBgPeriod = 45 }) },
	})
	local S2 = e2.core.ctx.S
	T.eq(S2.rainbowBg, true, "the setting is read")
	T.eq(S2.rainbowBgPeriod, 45, "with its speed")
	local slot = e2.core.mods.settings_colors
	T.ok(slot ~= nil and slot.mod ~= nil, "the module was loaded by itself a moment after the start")
	T.eq(slot and slot.mod and slot.mod.rainbowRunning(), true, "and it runs")
	local P2 = e2.core.ctx.T
	local k1 = key(P2.panel)
	e2.run(10)
	T.ok(key(P2.panel) ~= k1, "the color moves")
	T.eq(#errorsOf(e2), 0, "no errors")
	local e3 = Runner.boot({
		seconds = 8,
		files = {
			["AtsukoHub/settings.json"] = jsonencode({ rainbowBg = true }),
			["AtsukoHub/boot.json"] = '{"v":1,"ver":"1.6.1","stage":"commands","ok":false,"n":0}',
		},
	})
	T.eq(e3.core.mods.settings_colors, nil, "in safe mode the module is not even loaded at the start")
	local e4 = Runner.boot({
		seconds = 8,
		files = { ["AtsukoHub/settings.json"] = jsonencode({ rainbowBg = true, animations = false }) },
	})
	T.eq(e4.core.mods.settings_colors, nil, "with animations off at the start it is not loaded either")
	local e5 = Runner.boot({
		seconds = 8,
		files = { ["AtsukoHub/settings.json"] = jsonencode({ rainbowBgPeriod = 5000 }) },
	})
	T.eq(e5.core.ctx.S.rainbowBgPeriod, 120, "a loop longer than 120 is cut to 120")
	local e6 = Runner.boot({
		seconds = 8,
		files = { ["AtsukoHub/settings.json"] = jsonencode({ rainbowBgPeriod = 2 }) },
	})
	T.eq(e6.core.ctx.S.rainbowBgPeriod, 30, "and one shorter than 30 is raised to 30")
end

T.section("colors_ui: old themes load unchanged")
do
	local old = { id = "c1700000000_1", name = "Old one", bg = "#102030", card = "#203040", text = "#ffffff", accent = "#ff8800" }
	local fresh = { id = "c1700000000_2", name = "New one", bg = "#102031", card = "", text = "", accent = "", version = 2, rainbowBg = true }
	local odd = { id = "c1700000000_3", name = "Odd one", bg = "#102032", version = 9, rainbowBg = "yes" }
	local e7 = Runner.boot({
		seconds = 6,
		files = { ["AtsukoHub/settings.json"] = jsonencode({ themes = { old, fresh, odd } }) },
	})
	local list = e7.core.ctx.S.themes
	T.eq(#list, 3, "all three load")
	T.eq(list[1].bg, "#102030", "the old one keeps its colors")
	T.eq(list[1].accent, "#ff8800", "and its accent")
	T.eq(list[1].version, nil, "and stays without a version")
	T.eq(list[1].rainbowBg, nil, "and without a rainbow")
	T.eq(list[2].version, 2, "a version 2 theme keeps its version")
	T.eq(list[2].rainbowBg, true, "and its rainbow flag")
	T.eq(list[3].version, nil, "an unknown version is dropped")
	T.eq(list[3].rainbowBg, nil, "and a rainbow flag that is not a true is dropped")
end

T.section("colors_ui: the module is missing or broken")
do
	local e8 = Runner.boot({
		seconds = 6,
		files = { ["Atsuko Hub/Hub/modules/settings_colors.lua"] = "this is not lua code, but it is longer than forty bytes to pass the size check" },
	})
	local b8 = openThemes(e8)
	T.eq(b8, nil, "no block")
	local host = first(e8.hub.Pages.settings.views[2], "ColorsHost")
	T.ok(host ~= nil, "the host is there")
	T.ok(host and all(host, function(d)
		return d:IsA("TextLabel") and string.find(d.Text, "The color picker didn't load", 1, true) ~= nil
	end)[1] ~= nil, "and says so in a sentence")
	T.ok(first(e8.hub.Pages.settings.views[2], "ThemeHero") ~= nil, "the rest of the Themes tab is fine")
	T.ok(withText(e8.hub.Pages.settings.views[2], "Midnight") ~= nil, "the themes are still listed")
	local e9 = Runner.boot({ seconds = 6, files = { ["Atsuko Hub/Hub/modules/settings_colors.lua"] = false } })
	local b9 = openThemes(e9)
	T.eq(b9, nil, "a missing file gives no block")
	T.ok(first(e9.hub.Pages.settings.views[2], "ThemeHero") ~= nil, "and the tab still works")
	e9.core.ctx.S.rainbowBg = true
	e9.core.rainbowSync(true)
	e9.run(1)
	T.ok(true, "asking for the rainbow without the module does not throw")
end
