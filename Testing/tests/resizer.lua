local Resizer = loadmodule("Hub/modules/resizer.lua")

local DIRS = { "n", "s", "e", "w", "ne", "nw", "se", "sw" }

local function real(v)
	return type(v) == "number" and v == v and v ~= math.huge and v ~= -math.huge
end

local function sides(dir)
	return {
		east = dir == "e" or dir == "ne" or dir == "se",
		west = dir == "w" or dir == "nw" or dir == "sw",
		south = dir == "s" or dir == "se" or dir == "sw",
		north = dir == "n" or dir == "ne" or dir == "nw",
	}
end

local function rectIs(label, out, x, y, w, h)
	T.eq(out.x, x, label .. ": x")
	T.eq(out.y, y, label .. ": y")
	T.eq(out.w, w, label .. ": w")
	T.eq(out.h, h, label .. ": h")
end

local function holds(label, r0, dir, out, lim, vp, inside)
	for _, k in ipairs({ "x", "y", "w", "h" }) do
		T.ok(real(out[k]), label .. ": " .. k .. " is a real number")
	end
	T.ok(out.w >= 1 and out.h >= 1, label .. ": the size is positive")
	local s = sides(dir)
	if s.east or s.west then
		T.ok(out.w >= lim.minW and out.w <= lim.maxW, label .. ": width " .. out.w .. " is inside " .. lim.minW .. " to " .. lim.maxW)
	else
		T.eq(out.w, r0.w, label .. ": width untouched")
		T.eq(out.x, r0.x, label .. ": x untouched")
	end
	if s.south or s.north then
		T.ok(out.h >= lim.minH and out.h <= lim.maxH, label .. ": height " .. out.h .. " is inside " .. lim.minH .. " to " .. lim.maxH)
	else
		T.eq(out.h, r0.h, label .. ": height untouched")
		T.eq(out.y, r0.y, label .. ": y untouched")
	end
	if s.east then
		T.eq(out.x, r0.x, label .. ": the left edge stays")
	end
	if s.west then
		T.eq(out.x + out.w, r0.x + r0.w, label .. ": the right edge stays")
	end
	if s.south then
		T.eq(out.y, r0.y, label .. ": the top edge stays")
	end
	if s.north then
		T.eq(out.y + out.h, r0.y + r0.h, label .. ": the bottom edge stays")
	end
	if inside then
		T.ok(out.x >= 0 and out.y >= 0 and out.x + out.w <= vp.w and out.y + out.h <= vp.h, label .. ": inside the screen")
	end
end

local VP = { w = 1000, h = 700 }
local LIM = { minW = 200, minH = 150, maxW = 800, maxH = 600, margin = 40 }
local WIDE = { minW = 200, minH = 150, maxW = 2000, maxH = 2000, margin = 40 }
local START = { x = 100, y = 80, w = 400, h = 300 }

T.section("resizer: a normal drag from every side")
do
	local cases = {
		e = { 30, 0, 100, 80, 430, 300 },
		w = { 30, 0, 130, 80, 370, 300 },
		s = { 0, 20, 100, 80, 400, 320 },
		n = { 0, -20, 100, 60, 400, 320 },
		se = { 30, 20, 100, 80, 430, 320 },
		nw = { -30, -20, 70, 60, 430, 320 },
		ne = { 30, -20, 100, 60, 430, 320 },
		sw = { -30, 20, 70, 80, 430, 320 },
	}
	for _, dir in ipairs(DIRS) do
		local c = cases[dir]
		local out = Resizer.compute(START, dir, { x = c[1], y = c[2] }, LIM, VP)
		rectIs("normal " .. dir, out, c[3], c[4], c[5], c[6])
		holds("normal " .. dir, START, dir, out, LIM, VP, true)
	end
end

T.section("resizer: dragging the other way")
do
	local cases = {
		e = { -30, 0, 100, 80, 370, 300 },
		w = { -30, 0, 70, 80, 430, 300 },
		s = { 0, -20, 100, 80, 400, 280 },
		n = { 0, 20, 100, 100, 400, 280 },
		se = { -30, -20, 100, 80, 370, 280 },
		nw = { 30, 20, 130, 100, 370, 280 },
		ne = { -30, 20, 100, 100, 370, 280 },
		sw = { 30, -20, 130, 80, 370, 280 },
	}
	for _, dir in ipairs(DIRS) do
		local c = cases[dir]
		local out = Resizer.compute(START, dir, { x = c[1], y = c[2] }, LIM, VP)
		rectIs("back " .. dir, out, c[3], c[4], c[5], c[6])
		holds("back " .. dir, START, dir, out, LIM, VP, true)
	end
end

T.section("resizer: at the smallest size")
do
	local small = { x = 100, y = 80, w = 200, h = 150 }
	for _, dir in ipairs(DIRS) do
		local out = Resizer.compute(small, dir, { x = -60, y = -60 }, LIM, VP)
		holds("min shrink " .. dir, small, dir, out, LIM, VP, true)
		local s = sides(dir)
		if s.east or s.west then
			local shrinking = s.east
			if shrinking then
				T.eq(out.w, 200, "min shrink " .. dir .. ": it stays at the smallest width")
			end
		end
		local out2 = Resizer.compute(small, dir, { x = 60, y = 60 }, LIM, VP)
		holds("min shrink the other way " .. dir, small, dir, out2, LIM, VP, true)
		if s.west then
			T.eq(out2.w, 200, "min shrink " .. dir .. ": pushing the left edge in stops at the smallest width")
			T.eq(out2.x, 100, "min shrink " .. dir .. ": and the window does not slide")
		end
		if s.north then
			T.eq(out2.h, 150, "min shrink " .. dir .. ": pushing the top edge down stops at the smallest height")
		end
	end
	rectIs("min e", Resizer.compute(small, "e", { x = -500, y = 0 }, LIM, VP), 100, 80, 200, 150)
	rectIs("min s", Resizer.compute(small, "s", { x = 0, y = -500 }, LIM, VP), 100, 80, 200, 150)
	rectIs("min w", Resizer.compute(small, "w", { x = 500, y = 0 }, LIM, VP), 100, 80, 200, 150)
	rectIs("min n", Resizer.compute(small, "n", { x = 0, y = 500 }, LIM, VP), 100, 80, 200, 150)
end

T.section("resizer: at the biggest size")
do
	local big = { x = 50, y = 40, w = 800, h = 600 }
	for _, dir in ipairs(DIRS) do
		local out = Resizer.compute(big, dir, { x = 100, y = 100 }, LIM, VP)
		holds("max grow " .. dir, big, dir, out, LIM, VP, true)
		local out2 = Resizer.compute(big, dir, { x = -100, y = -100 }, LIM, VP)
		holds("max grow the other way " .. dir, big, dir, out2, LIM, VP, true)
	end
	rectIs("max e", Resizer.compute(big, "e", { x = 100, y = 0 }, LIM, VP), 50, 40, 800, 600)
	rectIs("max s", Resizer.compute(big, "s", { x = 0, y = 100 }, LIM, VP), 50, 40, 800, 600)
	rectIs("max w", Resizer.compute(big, "w", { x = -100, y = 0 }, LIM, VP), 50, 40, 800, 600)
	rectIs("max n", Resizer.compute(big, "n", { x = 0, y = -100 }, LIM, VP), 50, 40, 800, 600)
	rectIs("max se", Resizer.compute(big, "se", { x = 100, y = 100 }, LIM, VP), 50, 40, 800, 600)
	rectIs("max nw", Resizer.compute(big, "nw", { x = -100, y = -100 }, LIM, VP), 50, 40, 800, 600)
end

T.section("resizer: a drag that goes past the edge of the screen")
do
	for _, dir in ipairs(DIRS) do
		local out = Resizer.compute(START, dir, { x = 5000, y = 5000 }, WIDE, VP)
		holds("past plus " .. dir, START, dir, out, WIDE, VP, true)
		local out2 = Resizer.compute(START, dir, { x = -5000, y = -5000 }, WIDE, VP)
		holds("past minus " .. dir, START, dir, out2, WIDE, VP, true)
	end
	rectIs("past e", Resizer.compute(START, "e", { x = 5000, y = 0 }, WIDE, VP), 100, 80, 900, 300)
	rectIs("past s", Resizer.compute(START, "s", { x = 0, y = 5000 }, WIDE, VP), 100, 80, 400, 620)
	rectIs("past w", Resizer.compute(START, "w", { x = -5000, y = 0 }, WIDE, VP), 0, 80, 500, 300)
	rectIs("past n", Resizer.compute(START, "n", { x = 0, y = -5000 }, WIDE, VP), 100, 0, 400, 380)
	rectIs("past se", Resizer.compute(START, "se", { x = 5000, y = 5000 }, WIDE, VP), 100, 80, 900, 620)
	rectIs("past nw", Resizer.compute(START, "nw", { x = -5000, y = -5000 }, WIDE, VP), 0, 0, 500, 380)
end

T.section("resizer: the hub at half, normal and one and a half size")
do
	for _, scale in ipairs({ 0.5, 1, 1.5 }) do
		local px = 60
		local units = Resizer.toUnits(px, scale)
		T.eq(units, px / scale, "scale " .. scale .. ": sixty pixels are " .. px / scale .. " units")
		for _, dir in ipairs(DIRS) do
			local out = Resizer.compute(START, dir, { x = units, y = units }, LIM, VP)
			holds("scale " .. scale .. " " .. dir, START, dir, out, LIM, VP, true)
		end
		local e = Resizer.compute(START, "e", { x = units, y = 0 }, LIM, VP)
		T.eq(e.w, math.floor(400 + units + 0.5), "scale " .. scale .. ": east grows by the scaled amount")
		local se = Resizer.compute(START, "se", { x = units, y = units }, LIM, VP)
		T.eq(se.w, math.floor(400 + units + 0.5), "scale " .. scale .. ": south east width")
		T.eq(se.h, math.floor(300 + units + 0.5), "scale " .. scale .. ": south east height")
	end
	T.eq(Resizer.toUnits(100, 0), 100, "a scale of zero counts as one")
	T.eq(Resizer.toUnits(100, -2), 100, "a negative scale counts as one")
	T.eq(Resizer.toUnits(100, nil), 100, "no scale counts as one")
	T.eq(Resizer.toUnits(0 / 0, 1), 0, "a pointer that is not a number counts as zero")
end

T.section("resizer: fingers move in fractions, the window moves in whole pixels")
do
	for _, scale in ipairs({ 0.5, 0.75, 1, 1.5, 1.37 }) do
		for _, dir in ipairs(DIRS) do
			local d = { x = Resizer.toUnits(50, scale) + 0.333, y = Resizer.toUnits(-37, scale) - 0.777 }
			local out = Resizer.compute(START, dir, d, LIM, VP)
			holds("fraction " .. scale .. " " .. dir, START, dir, out, LIM, VP, true)
			for _, k in ipairs({ "x", "y", "w", "h" }) do
				T.eq(out[k], math.floor(out[k]), "fraction " .. scale .. " " .. dir .. ": " .. k .. " is a whole number")
			end
		end
	end
	local odd = Resizer.compute({ x = 10.4, y = 20.6, w = 300.2, h = 200.5 }, "se", { x = 0.2, y = 0.2 }, LIM, VP)
	rectIs("a start that is not whole", odd, 10, 21, 300, 201)
end

T.section("resizer: no movement at all")
do
	for _, dir in ipairs(DIRS) do
		local out = Resizer.compute(START, dir, { x = 0, y = 0 }, LIM, VP)
		rectIs("zero " .. dir, out, 100, 80, 400, 300)
		local out2 = Resizer.compute(START, dir, nil, LIM, VP)
		rectIs("no delta " .. dir, out2, 100, 80, 400, 300)
	end
end

T.section("resizer: huge and broken movement")
do
	for _, dir in ipairs(DIRS) do
		for _, d in ipairs({
			{ x = 1e9, y = 1e9 },
			{ x = -1e9, y = -1e9 },
			{ x = math.huge, y = -math.huge },
			{ x = 0 / 0, y = 0 / 0 },
			{ x = "far", y = {} },
			{ x = 1e300, y = -1e300 },
		}) do
			local out = Resizer.compute(START, dir, d, LIM, VP)
			holds("huge " .. dir .. " " .. tostring(d.x), START, dir, out, LIM, VP, true)
		end
	end
	rectIs("nan east", Resizer.compute(START, "e", { x = 0 / 0, y = 0 }, LIM, VP), 100, 80, 400, 300)
	rectIs("inf east", Resizer.compute(START, "e", { x = math.huge, y = 0 }, LIM, VP), 100, 80, 400, 300)
	rectIs("1e9 east", Resizer.compute(START, "e", { x = 1e9, y = 0 }, LIM, VP), 100, 80, 800, 300)
	rectIs("-1e9 east", Resizer.compute(START, "e", { x = -1e9, y = 0 }, LIM, VP), 100, 80, 200, 300)
	rectIs("unknown side", Resizer.compute(START, "up", { x = 50, y = 50 }, LIM, VP), 100, 80, 400, 300)
	rectIs("no side", Resizer.compute(START, nil, { x = 50, y = 50 }, LIM, VP), 100, 80, 400, 300)
	rectIs("number as side", Resizer.compute(START, 5, { x = 50, y = 50 }, LIM, VP), 100, 80, 400, 300)
	rectIs("no start", Resizer.compute(nil, "se", { x = 50, y = 50 }, LIM, VP), 0, 0, 250, 200)
	rectIs("broken start", Resizer.compute({ x = 0 / 0, y = "a", w = -5, h = math.huge }, "se", { x = 0, y = 0 }, LIM, VP), 0, 0, 200, 150)
	local noLimits = Resizer.compute(START, "e", { x = -9999, y = 0 }, nil, VP)
	T.eq(noLimits.w, 1, "without limits the width stops at one")
	local noView = Resizer.compute(START, "se", { x = 5000, y = 5000 }, LIM, nil)
	T.eq(noView.w, 800, "without a screen size only the limits apply (width)")
	T.eq(noView.h, 600, "without a screen size only the limits apply (height)")
	local zeroView = Resizer.compute(START, "se", { x = 100, y = 100 }, LIM, { w = 0, h = 0 })
	T.eq(zeroView.w, 500, "a screen that is not measured yet is ignored")
	local backwards = Resizer.compute(START, "e", { x = 50, y = 0 }, { minW = 500, maxW = 300, minH = 100, maxH = 100 }, VP)
	T.ok(backwards.w >= 500, "a maximum below the minimum gives way to the minimum")
end

T.section("resizer: a window that is already partly off the screen")
do
	local right = { x = 900, y = 80, w = 400, h = 300 }
	local out = Resizer.compute(right, "w", { x = 5000, y = 0 }, LIM, VP)
	T.eq(out.x + out.w, 1300, "the right edge stays")
	T.ok(out.x <= VP.w - 40, "at least forty pixels of it stay on the screen")
	T.ok(out.w >= 200, "and it keeps its smallest width")
	local left = { x = -300, y = 80, w = 400, h = 300 }
	local out2 = Resizer.compute(left, "e", { x = -5000, y = 0 }, LIM, VP)
	T.eq(out2.x, -300, "the left edge stays")
	T.ok(out2.x + out2.w >= 40, "at least forty pixels of it stay on the screen")
	local low = { x = 100, y = 600, w = 400, h = 300 }
	local out3 = Resizer.compute(low, "n", { x = 0, y = 5000 }, LIM, VP)
	T.eq(out3.y + out3.h, 900, "the bottom edge stays")
	T.ok(out3.y <= VP.h - 40, "the top bar stays on the screen")
	local out4 = Resizer.compute(low, "s", { x = 0, y = -10 }, LIM, VP)
	T.ok(out4.h >= 150, "it can still be made smaller")
	T.ok(out4.y == 600, "and the top stays")
	local out5 = Resizer.compute(low, "s", { x = 0, y = 500 }, LIM, VP)
	T.eq(out5.h, 300, "it does not grow further off the screen")
end

T.section("resizer: a small screen")
do
	local vp = { w = 300, h = 200 }
	local lim = { minW = 200, minH = 140, maxW = 800, maxH = 600, margin = 40 }
	local full = { x = 0, y = 0, w = 300, h = 200 }
	for _, dir in ipairs(DIRS) do
		local out = Resizer.compute(full, dir, { x = 100, y = 100 }, lim, vp)
		holds("small plus " .. dir, full, dir, out, lim, vp, true)
		local out2 = Resizer.compute(full, dir, { x = -500, y = -500 }, lim, vp)
		holds("small minus " .. dir, full, dir, out2, lim, vp, true)
	end
	rectIs("small e", Resizer.compute(full, "e", { x = 100, y = 0 }, lim, vp), 0, 0, 300, 200)
	rectIs("small w", Resizer.compute(full, "w", { x = 500, y = 0 }, lim, vp), 100, 0, 200, 200)
	local tiny = Resizer.compute({ x = 0, y = 0, w = 200, h = 140 }, "se", { x = 500, y = 500 }, lim, { w = 150, h = 100 })
	T.ok(tiny.w >= 200 and tiny.h >= 140, "a screen smaller than the smallest window never shrinks it below that")
end

T.section("resizer: fit puts a saved window back on the screen")
do
	local out = Resizer.fit({ x = 900, y = 600, w = 400, h = 300 }, LIM, VP)
	rectIs("fit off the corner", out, 600, 400, 400, 300)
	out = Resizer.fit({ x = -50, y = -50, w = 400, h = 300 }, LIM, VP)
	rectIs("fit off the top left", out, 0, 0, 400, 300)
	out = Resizer.fit({ x = 0, y = 0, w = 900, h = 700 }, { minW = 200, minH = 150, maxW = 2000, maxH = 2000 }, { w = 360, h = 640 })
	rectIs("fit after turning the phone", out, 0, 0, 360, 640)
	out = Resizer.fit({ x = 10, y = 10, w = 100, h = 100 }, LIM, VP)
	rectIs("fit a window that is too small", out, 10, 10, 200, 150)
	out = Resizer.fit({ x = 10, y = 10, w = 5000, h = 5000 }, LIM, VP)
	rectIs("fit a window that is too big", out, 10, 10, 800, 600)
	out = Resizer.fit({ x = 10, y = 10, w = 400, h = 300 }, LIM, { w = 150, h = 100 })
	T.ok(out.w >= 200 and out.h >= 150 and out.x == 0 and out.y == 0, "fit on a screen smaller than the window keeps the smallest size at the corner")
	out = Resizer.fit(nil, LIM, VP)
	rectIs("fit with nothing", out, 0, 0, 200, 150)
	out = Resizer.fit({ x = 0 / 0, y = math.huge, w = "x", h = {} }, LIM, VP)
	T.ok(real(out.x) and real(out.y) and real(out.w) and real(out.h), "fit with broken numbers still gives numbers")
	out = Resizer.fit({ x = 500, y = 500, w = 300, h = 200 }, LIM, nil)
	rectIs("fit without a screen size", out, 500, 500, 300, 200)
end

T.section("resizer: moving the whole window")
do
	local out = Resizer.move(START, { x = 50, y = 30 }, LIM, VP)
	rectIs("move", out, 150, 110, 400, 300)
	out = Resizer.move(START, { x = -5000, y = -5000 }, LIM, VP)
	rectIs("move to the top left", out, -360, 0, 400, 300)
	out = Resizer.move(START, { x = 5000, y = 5000 }, LIM, VP)
	rectIs("move to the bottom right", out, 960, 660, 400, 300)
	out = Resizer.move(START, nil, LIM, VP)
	rectIs("move nowhere", out, 100, 80, 400, 300)
	out = Resizer.move(START, { x = 0 / 0, y = math.huge }, LIM, VP)
	T.ok(real(out.x) and real(out.y), "move with broken numbers still gives numbers")
	out = Resizer.move(START, { x = 12.6, y = 7.4 }, LIM, nil)
	rectIs("move without a screen size rounds", out, 113, 87, 400, 300)
end

T.section("resizer: the eight handles")
do
	local function overlap(a, b)
		return a.x < b.x + b.w and b.x < a.x + a.w and a.y < b.y + b.h and b.y < a.y + a.h
	end
	for _, size in ipairs({ { 560, 400 }, { 300, 240 }, { 200, 140 }, { 1000, 700 }, { 420, 300 } }) do
		for _, touch in ipairs({ true, false }) do
			local label = size[1] .. "x" .. size[2] .. (touch and " touch" or " mouse")
			local list = Resizer.handles(size[1], size[2], touch, 46)
			T.eq(#list, 8, label .. ": eight handles")
			local seen = {}
			for _, hd in ipairs(list) do
				seen[hd.dir] = (seen[hd.dir] or 0) + 1
				T.ok(hd.x >= 0 and hd.y >= 0 and hd.x + hd.w <= size[1] and hd.y + hd.h <= size[2], label .. ": " .. hd.dir .. " is inside the window")
				T.ok(hd.w >= 1 and hd.h >= 1, label .. ": " .. hd.dir .. " has a size")
			end
			for _, dir in ipairs(DIRS) do
				T.eq(seen[dir], 1, label .. ": " .. dir .. " once")
			end
			local clash = {}
			for i = 1, #list do
				for j = i + 1, #list do
					if overlap(list[i], list[j]) then
						clash[#clash + 1] = list[i].dir .. "/" .. list[j].dir
					end
				end
			end
			T.eq(#clash, 0, label .. ": no two handles overlap " .. table.concat(clash, ","))
		end
	end
	local by = {}
	for _, hd in ipairs(Resizer.handles(560, 400, true, 46)) do
		by[hd.dir] = hd
	end
	T.eq(by.e.w, 32, "touch edges are 32 wide")
	T.eq(by.w.w, 32, "touch edges are 32 wide (west)")
	T.eq(by.s.h, 32, "touch edges are 32 high (south)")
	T.eq(by.se.w, 36, "corners are 36 wide")
	T.eq(by.se.h, 36, "corners are 36 high")
	T.eq(by.se.x, 560 - 36, "the south east corner sits in the corner (x)")
	T.eq(by.se.y, 400 - 36, "the south east corner sits in the corner (y)")
	T.ok(by.n.h <= 12, "the top edge is a thin band, so the title bar buttons stay free")
	T.eq(by.n.y, 0, "and it sits at the very top")
	local desk = {}
	for _, hd in ipairs(Resizer.handles(560, 400, false, 46)) do
		desk[hd.dir] = hd
	end
	T.eq(desk.e.w, 24, "desktop edges are 24 wide")
	T.eq(desk.s.h, 24, "desktop edges are 24 high")
	T.eq(desk.nw.w, 36, "desktop corners are 36 wide")
	local odd = Resizer.handles(0 / 0, "x", true, nil)
	T.eq(#odd, 8, "broken sizes still give eight handles")
end

T.section("resizer: the size badge text")
do
	T.eq(Resizer.label(560, 400), "560 x 400", "the badge text")
	T.eq(Resizer.label(560.4, 400.6), "560 x 401", "the badge rounds")
	T.eq(Resizer.label(0 / 0, nil), "0 x 0", "the badge copes with nothing")
end

T.section("resizer: a long run of random drags never breaks a rule")
do
	local seed = 12345
	local function rnd()
		seed = (seed * 1103515245 + 12345) % 2147483648
		return seed / 2147483648
	end
	local bad = 0
	local runs = 0
	for _ = 1, 1500 do
		local vp = { w = 300 + math.floor(rnd() * 1700), h = 200 + math.floor(rnd() * 900) }
		local lim = { minW = 100 + math.floor(rnd() * 200), minH = 80 + math.floor(rnd() * 120), maxW = 400 + math.floor(rnd() * 1500), maxH = 300 + math.floor(rnd() * 900), margin = 40 }
		lim.minW = math.min(lim.minW, vp.w)
		lim.minH = math.min(lim.minH, vp.h)
		local start = Resizer.fit({ x = math.floor(rnd() * vp.w), y = math.floor(rnd() * vp.h), w = lim.minW + math.floor(rnd() * 600), h = lim.minH + math.floor(rnd() * 500) }, lim, vp)
		local dir = DIRS[1 + math.floor(rnd() * 8)]
		local d = { x = (rnd() - 0.5) * 4000, y = (rnd() - 0.5) * 3000 }
		local out = Resizer.compute(start, dir, d, lim, vp)
		runs += 1
		local s = sides(dir)
		local ok = real(out.x) and real(out.y) and real(out.w) and real(out.h)
		ok = ok and out.x >= 0 and out.y >= 0 and out.x + out.w <= vp.w and out.y + out.h <= vp.h
		if s.east or s.west then
			ok = ok and out.w >= lim.minW and out.w <= math.max(lim.minW, lim.maxW)
		end
		if s.south or s.north then
			ok = ok and out.h >= lim.minH and out.h <= math.max(lim.minH, lim.maxH)
		end
		if s.east then
			ok = ok and out.x == start.x
		end
		if s.west then
			ok = ok and out.x + out.w == start.x + start.w
		end
		if s.south then
			ok = ok and out.y == start.y
		end
		if s.north then
			ok = ok and out.y + out.h == start.y + start.h
		end
		if not ok then
			bad += 1
			if bad <= 3 then
				print("  broke: " .. dir .. " start " .. start.x .. "," .. start.y .. "," .. start.w .. "," .. start.h .. " d " .. d.x .. "," .. d.y .. " -> " .. out.x .. "," .. out.y .. "," .. out.w .. "," .. out.h .. " vp " .. vp.w .. "x" .. vp.h)
			end
		end
	end
	T.eq(runs, 1500, "all the random runs happened")
	T.eq(bad, 0, "no random drag broke a rule")
end
