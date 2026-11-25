local Mod = loadmodule("Hub/modules/settings_colors.lua")

local seed = 20240611
local function rnd(n)
	seed = (seed * 1103515245 + 12345) % 2147483648
	return seed % n
end

local function near(a, b, eps)
	return math.abs(a - b) <= (eps or 1e-6)
end

local function same(a, b)
	return a[1] == b[1] and a[2] == b[2] and a[3] == b[3]
end

T.section("colors_pure: hex and RGB")
do
	T.eq(Mod.toHex(0, 0, 0), "#000000", "black")
	T.eq(Mod.toHex(255, 255, 255), "#ffffff", "white")
	T.eq(Mod.toHex(255, 0, 0), "#ff0000", "red")
	T.eq(Mod.toHex(0, 255, 0), "#00ff00", "green")
	T.eq(Mod.toHex(0, 0, 255), "#0000ff", "blue")
	T.eq(Mod.toHex(16, 17, 21), "#101115", "the Midnight background")
	T.eq(Mod.toHex(-5, 300, 12.6), "#00ff0d", "out of range numbers are clamped and rounded")
	T.eq(Mod.toHex(0 / 0, 1, 2), "#000102", "not-a-number counts as zero")
	T.eq(Mod.toHex("7", nil, 3), "#070003", "text and nil are tolerated")
	local r, g, b = Mod.parseHex("#FFAA00")
	T.ok(r == 255 and g == 170 and b == 0, "upper case digits")
	r, g, b = Mod.parseHex("ffaa00")
	T.ok(r == 255 and g == 170 and b == 0, "the # may be left out")
	r, g, b = Mod.parseHex("  #0a0b0c  ")
	T.ok(r == 10 and g == 11 and b == 12, "spaces around are fine")
	for _, bad in ipairs({ "#fff", "#gggggg", "#1234567", "", "   ", "#12345", "12 34 56", "#-12345" }) do
		T.eq(Mod.parseHex(bad), nil, "turned down: '" .. bad .. "'")
	end
	T.eq(Mod.parseHex(nil), nil, "nil")
	T.eq(Mod.parseHex(123456), nil, "a number")
	local bad = 0
	for _ = 1, 1000 do
		local cr, cg, cb = rnd(256), rnd(256), rnd(256)
		local hex = Mod.toHex(cr, cg, cb)
		local pr, pg, pb = Mod.parseHex(hex)
		if pr ~= cr or pg ~= cg or pb ~= cb or #hex ~= 7 or string.sub(hex, 1, 1) ~= "#" then
			bad += 1
		end
	end
	T.eq(bad, 0, "1000 random colors survive hex and back")
	local edges = { 0, 1, 15, 16, 127, 128, 254, 255 }
	local badEdge = 0
	for _, e1 in ipairs(edges) do
		for _, e2 in ipairs(edges) do
			for _, e3 in ipairs(edges) do
				local pr, pg, pb = Mod.parseHex(Mod.toHex(e1, e2, e3))
				if pr ~= e1 or pg ~= e2 or pb ~= e3 then
					badEdge += 1
				end
			end
		end
	end
	T.eq(badEdge, 0, "all 512 combinations of the edge values survive hex and back")
	T.eq(Mod.channel(255.4), 255, "channel rounds down")
	T.eq(Mod.channel(255.5), 255, "channel stops at 255")
	T.eq(Mod.channel(-0.4), 0, "channel stops at 0")
	T.eq(Mod.channel(127.5), 128, "channel rounds half up")
	T.eq(Mod.channel("x"), 0, "channel of text")
end

T.section("colors_pure: typing validation")
do
	T.eq(Mod.typing(""), "partial", "empty")
	T.eq(Mod.typing("#"), "partial", "just the hash")
	T.eq(Mod.typing("#a"), "partial", "one digit")
	T.eq(Mod.typing("#abcde"), "partial", "five digits")
	T.eq(Mod.typing("#abcdef"), "ok", "six digits")
	T.eq(Mod.typing("abcdef"), "ok", "six digits, no hash")
	T.eq(Mod.typing(" #ABCDEF "), "ok", "spaces and capitals")
	T.eq(Mod.typing("#abcdefa"), "bad", "seven digits")
	T.eq(Mod.typing("#xyz"), "bad", "letters that are not hex")
	T.eq(Mod.typing("#12g"), "bad", "a bad digit in the middle")
	T.eq(Mod.typing("# abc"), "bad", "a space inside")
	T.eq(Mod.typing(nil), "bad", "nil")
	T.eq(Mod.typing(5), "bad", "a number")
	T.eq(Mod.cleanHex("#ABCDEF"), "#abcdef", "cleanHex lower-cases")
	T.eq(Mod.cleanHex("abcdef"), "", "cleanHex wants the hash")
	T.eq(Mod.cleanHex("red"), "", "cleanHex turns down names")
	T.eq(Mod.cleanHex(nil), "", "cleanHex of nil")
	T.eq(Mod.cleanDigits("12a3"), "123", "digits only")
	T.eq(Mod.cleanDigits("1234"), "123", "three at most")
	T.eq(Mod.cleanDigits("abc"), "", "nothing left")
	T.eq(Mod.cleanDigits(nil), "", "nil")
	T.eq(Mod.cleanDigits("-5"), "5", "a minus sign goes")
	T.eq(Mod.parseChannel("0"), 0, "zero")
	T.eq(Mod.parseChannel("255"), 255, "255")
	T.eq(Mod.parseChannel("300"), 255, "300 stops at 255")
	T.eq(Mod.parseChannel(" 7 "), 7, "spaces")
	T.eq(Mod.parseChannel("007"), 7, "leading zeros")
	T.eq(Mod.parseChannel("1000"), nil, "four digits")
	T.eq(Mod.parseChannel(""), nil, "empty")
	T.eq(Mod.parseChannel("1a"), nil, "a letter")
	T.eq(Mod.parseChannel(nil), nil, "nil")
end

T.section("colors_pure: slider maths")
do
	T.eq(Mod.fraction(150, 100, 100), 0.5, "the middle")
	T.eq(Mod.fraction(50, 100, 100), 0, "left of the track")
	T.eq(Mod.fraction(500, 100, 100), 1, "right of the track")
	T.eq(Mod.fraction(100, 100, 100), 0, "the left end")
	T.eq(Mod.fraction(200, 100, 100), 1, "the right end")
	T.eq(Mod.fraction(150, 100, 0), nil, "a track with no width")
	T.eq(Mod.fraction(150, 100, -5), nil, "a track with a negative width")
	T.eq(Mod.fraction(nil, 100, 100), nil, "no position")
	T.eq(Mod.valueAt(0), 0, "0 is 0")
	T.eq(Mod.valueAt(1), 255, "1 is 255")
	T.eq(Mod.valueAt(0.5), 128, "half is 128")
	T.eq(Mod.valueAt(-3), 0, "below 0")
	T.eq(Mod.valueAt(7), 255, "above 1")
	T.eq(Mod.valueAt(nil), 0, "nil")
	local monotone = true
	local last = -1
	for i = 0, 1000 do
		local v = Mod.valueAt(i / 1000)
		if v < last or v < 0 or v > 255 then
			monotone = false
		end
		last = v
	end
	T.ok(monotone, "dragging right never lowers the value, always 0 to 255")
end

T.section("colors_pure: contrast")
do
	local black, white = { 0, 0, 0 }, { 255, 255, 255 }
	T.ok(near(Mod.luminance(0, 0, 0), 0), "black has no light")
	T.ok(near(Mod.luminance(255, 255, 255), 1, 1e-9), "white has all of it")
	T.ok(near(Mod.contrast(black, white), 21, 1e-6), "black on white is 21 : 1")
	T.ok(near(Mod.contrast(white, black), 21, 1e-6), "and the other way round")
	T.ok(near(Mod.contrast(white, white), 1, 1e-9), "the same color is 1 : 1")
	T.ok(Mod.contrast({ 118, 118, 118 }, white) >= 4.5, "#767676 on white passes")
	T.ok(Mod.contrast({ 119, 119, 119 }, white) < 4.5, "#777777 on white does not")
	T.ok(near(Mod.contrast({ 118, 118, 118 }, white), 4.54, 0.01), "#767676 on white is about 4.54")
	T.ok(near(Mod.contrast({ 119, 119, 119 }, white), 4.48, 0.01), "#777777 on white is about 4.48")
	T.ok(Mod.readable(white, { 16, 17, 21 }, { 28, 29, 35 }), "white text on Midnight")
	T.ok(Mod.readable({ 26, 28, 36 }, { 234, 236, 242 }, { 250, 251, 253 }), "dark text on Cloud")
	T.ok(not Mod.readable({ 119, 119, 119 }, white, white), "grey on white is not enough")
	T.ok(not Mod.readable(white, white, white), "white on white")
	T.ok(not Mod.readable(white, black, white), "white text on a white card fails even if the background is fine")
	T.ok(near(Mod.worstContrast(white, black, white), 1, 1e-9), "the worst of the two is used")
	T.ok(near(Mod.worstContrast(white, black), 21, 1e-6), "no card: just the background")
	local symmetric, bounded, bad = 0, 0, 0
	for _ = 1, 1000 do
		local a = { rnd(256), rnd(256), rnd(256) }
		local b = { rnd(256), rnd(256), rnd(256) }
		local c1, c2 = Mod.contrast(a, b), Mod.contrast(b, a)
		if near(c1, c2, 1e-9) then
			symmetric += 1
		end
		if c1 >= 1 - 1e-9 and c1 <= 21 + 1e-6 then
			bounded += 1
		end
	end
	T.eq(symmetric, 1000, "1000 random pairs: the order does not matter")
	T.eq(bounded, 1000, "1000 random pairs: always between 1 and 21")
	T.eq(Mod.fixText(black, black), "#ffffff", "black everywhere gets white text")
	T.eq(Mod.fixText(white, white), "#000000", "white everywhere gets black text")
	T.eq(Mod.fixText({ 16, 17, 21 }, { 28, 29, 35 }), "#ffffff", "Midnight gets white text")
	T.eq(Mod.fixText({ 234, 236, 242 }, { 250, 251, 253 }), "#000000", "Cloud gets black text")
	T.eq(Mod.fixText({ 119, 119, 119 }, nil), "#000000", "mid grey leans to black")
	T.eq(Mod.fixText({ 118, 118, 118 }, nil), "#000000", "the grey just under it too")
	T.eq(Mod.fixText({ 128, 128, 128 }, { 128, 128, 128 }), "#000000", "50 percent grey is closer to black")
	local worse = 0
	for _ = 1, 1000 do
		local bg = { rnd(256), rnd(256), rnd(256) }
		local card = { rnd(256), rnd(256), rnd(256) }
		local pick = Mod.fixText(bg, card) == "#000000" and black or white
		local other = pick == black and white or black
		if Mod.worstContrast(pick, bg, card) + 1e-9 < Mod.worstContrast(other, bg, card) then
			worse += 1
		end
	end
	T.eq(worse, 0, "1000 random pairs: Fix text colour always takes the better of black and white")
end

T.section("colors_pure: the rainbow")
do
	T.eq(Mod.period(10), 30, "never faster than 30 seconds a loop")
	T.eq(Mod.period(500), 120, "never slower than 120")
	T.eq(Mod.period(nil), 90, "the default is 90")
	T.eq(Mod.period(61.4), 61, "whole seconds")
	T.eq(Mod.period("45"), 45, "text works")
	T.eq(Mod.period(0 / 0), 90, "not-a-number falls back")
	T.ok(near(Mod.hue(0, 90), 0), "start")
	T.ok(near(Mod.hue(45, 90), 0.5), "halfway")
	T.ok(near(Mod.hue(90, 90), 0), "a loop is exactly the period")
	T.ok(near(Mod.hue(135, 90), 0.5), "the second loop")
	T.ok(near(Mod.hue(1000, 30), (1000 % 30) / 30), "a large time")
	T.ok(near(Mod.hue(5, 10), 5 / 30), "a period below 30 counts as 30")
	local ar, ag, ab = Mod.rainbow(0, 60, false)
	local br, bg, bb = Mod.rainbow(60, 60, false)
	T.ok(same({ ar, ag, ab }, { br, bg, bb }), "after one period the color is the same again")
	local cr, cg, cb = Mod.rainbow(30, 60, false)
	T.ok(not same({ ar, ag, ab }, { cr, cg, cb }), "halfway round it is a different color")
	local darkBad, lightBad, darkMax, lightMin = 0, 0, 0, 255
	local darkText, lightText = { 244, 245, 248 }, { 26, 28, 36 }
	for i = 0, 359 do
		local t = i * 0.25
		local r, g, b = Mod.rainbow(t, 90, false)
		darkMax = math.max(darkMax, r, g, b)
		if Mod.worstContrast(darkText, { r, g, b }, nil) < 4.5 then
			darkBad += 1
		end
		r, g, b = Mod.rainbow(t, 90, true)
		lightMin = math.min(lightMin, r, g, b)
		if Mod.worstContrast(lightText, { r, g, b }, nil) < 4.5 then
			lightBad += 1
		end
	end
	T.eq(darkBad, 0, "dark rainbow: 360 hues, light text stays above 4.5 : 1")
	T.eq(lightBad, 0, "light rainbow: 360 hues, dark text stays above 4.5 : 1")
	T.ok(darkMax <= 52, "the dark rainbow stays dark (brightest channel " .. darkMax .. ")")
	T.ok(lightMin >= 205, "the light rainbow stays light (darkest channel " .. lightMin .. ")")
	local worst = 0
	local pr, pg, pb = Mod.rainbow(0, 30, true)
	local last = Mod.luminance(pr, pg, pb)
	for i = 1, 120 do
		local r, g, b = Mod.rainbow(i * 0.25, 30, true)
		local l = Mod.luminance(r, g, b)
		worst = math.max(worst, math.abs(l - last))
		last = l
	end
	T.ok(worst * 4 <= 0.05, "at the fastest speed the light never changes more than 5 percent a second (" .. string.format("%.4f", worst * 4) .. ")")
	worst = 0
	pr, pg, pb = Mod.rainbow(0, 30, false)
	last = Mod.luminance(pr, pg, pb)
	for i = 1, 120 do
		local r, g, b = Mod.rainbow(i * 0.25, 30, false)
		local l = Mod.luminance(r, g, b)
		worst = math.max(worst, math.abs(l - last))
		last = l
	end
	T.ok(worst * 4 <= 0.05, "and the dark one neither (" .. string.format("%.4f", worst * 4) .. ")")
	local steps = 0
	pr, pg, pb = Mod.rainbow(0, 30, false)
	for i = 1, 120 do
		local r, g, b = Mod.rainbow(i * 0.25, 30, false)
		steps = math.max(steps, math.abs(r - pr), math.abs(g - pg), math.abs(b - pb))
		pr, pg, pb = r, g, b
	end
	T.ok(steps <= 3, "a quarter second moves a channel by at most 3 steps (" .. steps .. ")")
end

T.section("colors_pure: hsv")
do
	local function hsv(h, s, v)
		local r, g, b = Mod.hsv(h, s, v)
		return { r, g, b }
	end
	T.ok(same(hsv(0, 1, 1), { 255, 0, 0 }), "red")
	T.ok(same(hsv(1 / 3, 1, 1), { 0, 255, 0 }), "green")
	T.ok(same(hsv(2 / 3, 1, 1), { 0, 0, 255 }), "blue")
	T.ok(same(hsv(0, 0, 1), { 255, 255, 255 }), "no saturation is white")
	T.ok(same(hsv(0.5, 1, 0), { 0, 0, 0 }), "no value is black")
	T.ok(same(hsv(1, 1, 1), { 255, 0, 0 }), "hue 1 wraps to red")
	T.ok(same(hsv(1 / 6, 1, 1), { 255, 255, 0 }), "yellow")
	T.ok(same(hsv(0.5, 1, 1), { 0, 255, 255 }), "cyan")
	T.ok(same(hsv(5 / 6, 1, 1), { 255, 0, 255 }), "magenta")
	local inRange = true
	for _ = 1, 1000 do
		local c = hsv(rnd(1000) / 1000, rnd(1001) / 1000, rnd(1001) / 1000)
		for i = 1, 3 do
			if c[i] < 0 or c[i] > 255 or c[i] % 1 ~= 0 then
				inRange = false
			end
		end
	end
	T.ok(inRange, "1000 random colors: whole numbers from 0 to 255")
end

T.section("colors_pure: updates and tweens")
do
	T.ok(Mod.allow(5, nil), "the first update goes through")
	T.ok(not Mod.allow(0.04, 0), "40 ms after the last one waits")
	T.ok(Mod.allow(0.05, 0), "50 ms is allowed")
	T.ok(Mod.allow(1, 0.9), "100 ms is allowed")
	local last, allowed = nil, 0
	for i = 0, 999 do
		local now = i * 0.001
		if Mod.allow(now, last) then
			last = now
			allowed += 1
		end
	end
	T.ok(allowed <= 21 and allowed >= 19, "a thousand tries in one second give about 20 updates (" .. allowed .. ")")
	T.eq(Mod.steps(0.25, 20), 5, "a quarter second at 20 a second is 5 steps")
	T.eq(Mod.steps(0, 20), 1, "never less than one step")
	T.eq(Mod.steps(1, 20), 20, "a second is 20 steps")
	T.eq(Mod.steps(), 5, "the defaults")
	T.eq(Mod.ease(0), 0, "ease starts at 0")
	T.eq(Mod.ease(1), 1, "and ends at 1")
	T.eq(Mod.ease(-3), 0, "below 0")
	T.eq(Mod.ease(9), 1, "above 1")
	local rising, last2 = true, -1
	for i = 0, 100 do
		local v = Mod.ease(i / 100)
		if v < last2 then
			rising = false
		end
		last2 = v
	end
	T.ok(rising, "ease never goes backwards")
	T.ok(Mod.ease(0.5) > 0.5, "ease starts fast")
	T.ok(same(Mod.mix({ 0, 0, 0 }, { 255, 255, 255 }, 0), { 0, 0, 0 }), "mix at 0")
	T.ok(same(Mod.mix({ 0, 0, 0 }, { 255, 255, 255 }, 1), { 255, 255, 255 }), "mix at 1")
	T.ok(same(Mod.mix({ 0, 0, 0 }, { 255, 255, 255 }, 0.5), { 128, 128, 128 }), "mix halfway")
	T.ok(same(Mod.mix({ 255, 0, 10 }, { 0, 255, 10 }, 0.5), { 128, 128, 10 }), "mix per channel")
	local frames = Mod.frames({ bg = { 0, 0, 0 }, text = { 10, 10, 10 } }, { bg = { 255, 255, 255 }, text = { 200, 200, 200 } }, 5)
	T.eq(#frames, 5, "five frames")
	T.eq(frames[5].bg, "#ffffff", "the last frame is the goal")
	T.eq(frames[5].text, "#c8c8c8", "for every color")
	T.eq(frames[1].card, nil, "colors that are not given stay out")
	local go = true
	for i = 2, 5 do
		local a, b = Mod.parseHex(frames[i - 1].bg), Mod.parseHex(frames[i].bg)
		if b < a then
			go = false
		end
	end
	T.ok(go, "the background only goes toward the goal")
	T.ok(Mod.parseHex(frames[1].bg) > 0, "and the first frame has already moved")
	T.eq(#Mod.frames({ bg = { 1, 2, 3 } }, { bg = { 1, 2, 3 } }, 3), 3, "a tween to the same color still has its frames")
end

T.section("colors_pure: row text, names and theme fields")
do
	T.eq(Mod.rowText("bg", "#101115", false), "#101115", "a color is shown upper case")
	T.eq(Mod.rowText("card", "", false), "Auto", "cards on auto")
	T.eq(Mod.rowText("text", nil, false), "Auto", "text on auto")
	T.eq(Mod.rowText("accent", "", false), "Yours", "the accent left alone")
	T.eq(Mod.rowText("accent", "#c8a8ff", false), "#C8A8FF", "an accent that was picked")
	T.eq(Mod.rowText("bg", "#101115", true), "Rainbow", "the background with the rainbow on")
	T.eq(Mod.rowText("card", "#ffffff", true), "Rainbow", "cards with the rainbow on")
	T.eq(Mod.rowText("accent", "", true), "Yours", "the accent is not part of the rainbow")
	T.eq(Mod.nextName({}), "My colors", "the first name")
	T.eq(Mod.nextName({ "My colors" }), "My colors 2", "the second")
	T.eq(Mod.nextName({ "my colors", "My colors 2" }), "My colors 3", "case does not matter")
	T.eq(Mod.nextName({ "Ocean" }), "My colors", "other names do not count")
	local f = Mod.themeFields({ bg = "#ABCDEF", card = "", text = "nope", accent = "#112233" }, false)
	T.eq(f.bg, "#abcdef", "bg is lower-cased")
	T.eq(f.card, "", "empty stays empty")
	T.eq(f.text, "", "a bad color becomes empty")
	T.eq(f.accent, "#112233", "accent")
	T.eq(f.version, 2, "new themes are version 2")
	T.eq(f.rainbowBg, nil, "no rainbow flag when it is off")
	T.eq(Mod.themeFields({ bg = "#000000" }, true).rainbowBg, true, "the rainbow flag when it is on")
	T.eq(Mod.themeFields({}, false).bg, "", "a missing background")
end
