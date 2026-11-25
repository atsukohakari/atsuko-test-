local Resizer = {}

Resizer.DIRS = { "n", "s", "e", "w", "ne", "nw", "se", "sw" }

local function finite(v, fallback)
	if type(v) ~= "number" or v ~= v or v == math.huge or v == -math.huge then
		return fallback
	end
	return v
end

local function round(v)
	return math.floor(v + 0.5)
end

local function clamp(v, lo, hi)
	if v < lo then
		return lo
	end
	if v > hi then
		return hi
	end
	return v
end

local function limitsOf(limits, viewport)
	limits = type(limits) == "table" and limits or {}
	viewport = type(viewport) == "table" and viewport or {}
	local minW = math.max(1, round(finite(limits.minW, 1)))
	local minH = math.max(1, round(finite(limits.minH, 1)))
	local maxW = finite(limits.maxW, math.huge)
	local maxH = finite(limits.maxH, math.huge)
	if maxW ~= math.huge then
		maxW = round(maxW)
	end
	if maxH ~= math.huge then
		maxH = round(maxH)
	end
	if maxW < minW then
		maxW = minW
	end
	if maxH < minH then
		maxH = minH
	end
	local margin = math.max(0, round(finite(limits.margin, 40)))
	local vw = math.max(0, round(finite(viewport.w, 0)))
	local vh = math.max(0, round(finite(viewport.h, 0)))
	return minW, minH, maxW, maxH, margin, vw, vh
end

function Resizer.clean(rect, limits)
	rect = type(rect) == "table" and rect or {}
	local minW, minH = limitsOf(limits, nil)
	return {
		x = round(finite(rect.x, 0)),
		y = round(finite(rect.y, 0)),
		w = math.max(1, round(finite(rect.w, minW))),
		h = math.max(1, round(finite(rect.h, minH))),
	}
end

function Resizer.toUnits(pixels, scale)
	local s = finite(scale, 1)
	if s <= 0 then
		s = 1
	end
	return finite(pixels, 0) / s
end

function Resizer.compute(startRect, dir, delta, limits, viewport)
	local start = Resizer.clean(startRect, limits)
	local d = type(delta) == "table" and delta or {}
	local dx = finite(d.x, 0)
	local dy = finite(d.y, 0)
	local minW, minH, maxW, maxH, margin, vw, vh = limitsOf(limits, viewport)
	local inView = vw > 0 and vh > 0
	local left, top = start.x, start.y
	local right, bottom = start.x + start.w, start.y + start.h
	local east = dir == "e" or dir == "ne" or dir == "se"
	local west = dir == "w" or dir == "nw" or dir == "sw"
	local south = dir == "s" or dir == "se" or dir == "sw"
	local north = dir == "n" or dir == "ne" or dir == "nw"
	if east then
		local lo = left + minW
		local hi = left + maxW
		if inView then
			lo = math.max(lo, margin)
			hi = math.min(hi, math.max(vw, right))
		end
		if hi < lo then
			hi = lo
		end
		right = round(clamp(right + dx, lo, hi))
	elseif west then
		local hi = right - minW
		local lo = right - maxW
		if inView then
			hi = math.min(hi, vw - margin)
			lo = math.max(lo, math.min(0, left))
		end
		if lo > hi then
			lo = hi
		end
		left = round(clamp(left + dx, lo, hi))
	end
	if south then
		local lo = top + minH
		local hi = top + maxH
		if inView then
			hi = math.min(hi, math.max(vh, bottom))
		end
		if hi < lo then
			hi = lo
		end
		bottom = round(clamp(bottom + dy, lo, hi))
	elseif north then
		local hi = bottom - minH
		local lo = bottom - maxH
		if inView then
			hi = math.min(hi, vh - margin)
			lo = math.max(lo, math.min(0, top))
		end
		if lo > hi then
			lo = hi
		end
		top = round(clamp(top + dy, lo, hi))
	end
	local out = { x = left, y = top, w = right - left, h = bottom - top }
	if out.w < 1 or out.h < 1 or out.x ~= out.x or out.y ~= out.y then
		return start
	end
	return out
end

function Resizer.fit(rect, limits, viewport)
	local minW, minH, maxW, maxH, margin, vw, vh = limitsOf(limits, viewport)
	local r = Resizer.clean(rect, limits)
	local w = clamp(r.w, minW, maxW)
	local h = clamp(r.h, minH, maxH)
	local x, y = r.x, r.y
	if vw > 0 and vh > 0 then
		w = clamp(w, minW, math.max(minW, math.min(maxW, vw)))
		h = clamp(h, minH, math.max(minH, math.min(maxH, vh)))
		x = clamp(x, 0, math.max(0, vw - w))
		y = clamp(y, 0, math.max(0, vh - h))
	end
	return { x = x, y = y, w = w, h = h }
end

function Resizer.move(rect, delta, limits, viewport)
	local minW, minH, maxW, maxH, margin, vw, vh = limitsOf(limits, viewport)
	local r = Resizer.clean(rect, limits)
	local d = type(delta) == "table" and delta or {}
	local x = r.x + finite(d.x, 0)
	local y = r.y + finite(d.y, 0)
	if vw > 0 and vh > 0 then
		x = clamp(x, margin - r.w, vw - margin)
		y = clamp(y, 0, vh - margin)
	end
	return { x = round(x), y = round(y), w = r.w, h = r.h }
end

function Resizer.handles(w, h, touch, header)
	w = math.max(1, round(finite(w, 1)))
	h = math.max(1, round(finite(h, 1)))
	local edge = touch and 32 or 24
	local corner = 36
	local band = math.max(6, math.min(edge, round(finite(header, 46) / 4)))
	edge = math.min(edge, math.floor(math.min(w, h) / 3))
	corner = math.min(corner, math.floor(math.min(w, h) / 2))
	local list = {}
	local function add(dir, x, y, bw, bh)
		list[#list + 1] = { dir = dir, x = x, y = y, w = math.max(1, bw), h = math.max(1, bh) }
	end
	add("n", corner, 0, w - corner * 2, band)
	add("s", corner, h - edge, w - corner * 2, edge)
	add("w", 0, corner, edge, h - corner - math.max(corner, edge))
	add("e", w - edge, corner, edge, h - corner - math.max(corner, edge))
	add("nw", 0, 0, corner, corner)
	add("ne", w - corner, 0, corner, corner)
	add("sw", 0, h - corner, corner, corner)
	add("se", w - corner, h - corner, corner, corner)
	return list
end

function Resizer.label(w, h)
	return round(finite(w, 0)) .. " x " .. round(finite(h, 0))
end

local MARKS = {
	n = { { 0.5, 0, 0, 2, 1, -16, 0, 2, 0.5, 0 } },
	s = { { 0.5, 0, 1, -2, 1, -16, 0, 2, 0.5, 1 } },
	w = { { 0, 2, 0.5, 0, 0, 2, 1, -16, 0, 0.5 } },
	e = { { 1, -2, 0.5, 0, 0, 2, 1, -16, 1, 0.5 } },
	nw = { { 0, 2, 0, 2, 0, 20, 0, 2, 0, 0 }, { 0, 2, 0, 2, 0, 2, 0, 20, 0, 0 } },
	ne = { { 1, -2, 0, 2, 0, 20, 0, 2, 1, 0 }, { 1, -2, 0, 2, 0, 2, 0, 20, 1, 0 } },
	sw = { { 0, 2, 1, -2, 0, 20, 0, 2, 0, 1 }, { 0, 2, 1, -2, 0, 2, 0, 20, 0, 1 } },
	se = { { 1, -2, 1, -2, 0, 20, 0, 2, 1, 1 }, { 1, -2, 1, -2, 0, 2, 0, 20, 1, 1 } },
}

local MOVES = { n = true, w = true, nw = true, ne = true, sw = true }

function Resizer.attach(w, env)
	local UI, T = env.UI, env.T
	local frame = w.frame
	local c = { mod = Resizer, handles = {}, marks = {}, alive = true, active = nil, maxed = false, restore = nil, animating = false }
	local pending = nil
	local badge = nil
	local badgeToken = 0
	local saved = {}

	local function viewport()
		return { w = env.W(), h = env.H() }
	end

	local function fade(dir, on)
		for _, m in ipairs(c.marks[dir] or {}) do
			UI.tween(m, 0.12, { BackgroundTransparency = on and 0.1 or 1 })
		end
	end

	local function showBadge(dir, rect)
		if not badge then
			badge = UI.new("TextLabel", {
				Name = "SizeBadge",
				BackgroundColor3 = T.card,
				BackgroundTransparency = 0.05,
				BorderSizePixel = 0,
				Font = env.font,
				TextSize = 11,
				TextColor3 = T.text,
				Size = UDim2.fromOffset(84, 22),
				ZIndex = 9,
				Visible = false,
			}, frame)
			UI.corner(badge, 8)
		end
		badgeToken += 1
		badge.Text = Resizer.label(rect.w, rect.h)
		badge.BackgroundTransparency = 0.05
		badge.TextTransparency = 0
		local east = dir == "e" or dir == "ne" or dir == "se"
		local west = dir == "w" or dir == "nw" or dir == "sw"
		local south = dir == "s" or dir == "se" or dir == "sw"
		local north = dir == "n" or dir == "ne" or dir == "nw"
		badge.AnchorPoint = Vector2.new(east and 1 or (west and 0 or 0.5), south and 1 or (north and 0 or 0.5))
		local px = east and rect.w - 14 or (west and 14 or rect.w / 2)
		local py = south and rect.h - 54 or (north and env.header + 8 or rect.h / 2)
		badge.Position = UDim2.fromOffset(px, py)
		badge.Visible = true
	end

	local function hideBadge(delay)
		if not badge then
			return
		end
		local mine = badgeToken
		task.delay(delay, function()
			if not c.alive or not badge or mine ~= badgeToken then
				return
			end
			local tw = UI.tween(badge, 0.25, { BackgroundTransparency = 1, TextTransparency = 1 })
			UI.done(tw, function()
				if c.alive and badge and mine == badgeToken then
					badge.Visible = false
				end
			end)
			if not tw then
				badge.Visible = false
			end
		end)
	end

	local function freezeScrolling()
		saved = {}
		for _, o in ipairs(frame:GetDescendants()) do
			if o:IsA("ScrollingFrame") then
				saved[#saved + 1] = { o, o.ScrollingEnabled }
				o.ScrollingEnabled = false
			end
		end
	end

	local function thawScrolling()
		for _, pair in ipairs(saved) do
			if pair[1].Parent then
				pair[1].ScrollingEnabled = pair[2]
			end
		end
		saved = {}
	end

	function c.layout()
		if not c.alive then
			return
		end
		for _, spec in ipairs(Resizer.handles(w.w, w.h, env.touch(), env.header)) do
			local b = c.handles[spec.dir]
			if b then
				b.Position = UDim2.fromOffset(spec.x, spec.y)
				b.Size = UDim2.fromOffset(spec.w, spec.h)
			end
		end
	end

	function c.show(on)
		for _, b in pairs(c.handles) do
			b.Visible = on
		end
	end

	local function finish(dir)
		if c.stepConn then
			pcall(function()
				c.stepConn:Disconnect()
			end)
			c.stepConn = nil
		end
		c.active = nil
		thawScrolling()
		fade(dir, false)
		if env.afterResize then
			pcall(env.afterResize, w)
		end
		hideBadge(0.6)
	end

	local function begin(dir, input)
		if not c.alive or not w.alive or w.minimized or c.animating then
			return
		end
		if input.UserInputType ~= env.MOUSE1 and input.UserInputType ~= env.TOUCH then
			return
		end
		if env.Drag.cur or c.active then
			return
		end
		if w.locked and MOVES[dir] then
			return
		end
		env.front(w)
		local startRect = { x = w.x, y = w.y, w = w.w, h = w.h }
		local limits = env.limits(w)
		c.active = { dir = dir, input = input }
		c.maxed = false
		fade(dir, true)
		freezeScrolling()
		pending = nil
		local function flush()
			if not pending or not w.alive then
				return
			end
			local d = pending
			pending = nil
			local out = Resizer.compute(startRect, dir, d, limits, viewport())
			env.apply(w, out)
			showBadge(dir, out)
		end
		c.stepConn = env.step:Connect(flush)
		env.Drag.start(input, function(_, delta)
			if not w.alive or not c.alive then
				return
			end
			pending = { x = Resizer.toUnits(delta.X, env.scale()), y = Resizer.toUnits(delta.Y, env.scale()) }
		end, function()
			flush()
			finish(dir)
			if w.alive then
				env.save(w)
			end
		end)
	end

	for _, spec in ipairs(Resizer.handles(w.w, w.h, env.touch(), env.header)) do
		local b
		if spec.dir == "se" and w.resize then
			b = w.resize
			for _, child in ipairs(b:GetChildren()) do
				child:Destroy()
			end
			b.AnchorPoint = Vector2.new(0, 0)
			b.Name = "Resize_se"
		else
			b = UI.button(frame, { Name = "Resize_" .. spec.dir, BackgroundTransparency = 1 })
		end
		b.BackgroundTransparency = 1
		b.Active = true
		b.ZIndex = 6
		b.Visible = not w.minimized
		b.Position = UDim2.fromOffset(spec.x, spec.y)
		b.Size = UDim2.fromOffset(spec.w, spec.h)
		c.handles[spec.dir] = b
		c.marks[spec.dir] = {}
		for _, m in ipairs(MARKS[spec.dir]) do
			local mark = UI.new("Frame", {
				Name = "Mark",
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				AnchorPoint = Vector2.new(m[9], m[10]),
				Position = UDim2.new(m[1], m[2], m[3], m[4]),
				Size = UDim2.new(m[5], m[6], m[7], m[8]),
				ZIndex = 7,
			}, b)
			UI.accent(mark, "BackgroundColor3")
			c.marks[spec.dir][#c.marks[spec.dir] + 1] = mark
		end
		UI.onHover(b, function(on)
			if not c.active then
				fade(spec.dir, on)
			end
		end)
		b.InputBegan:Connect(function(input)
			begin(spec.dir, input)
		end)
	end

	function c.toggleMax()
		if not c.alive or not w.alive or w.minimized or c.animating or c.active then
			return
		end
		local target
		if c.maxed and c.restore then
			target = Resizer.fit(c.restore, env.limits(w), viewport())
			c.maxed = false
		else
			c.restore = { x = w.x, y = w.y, w = w.w, h = w.h }
			local vp = viewport()
			target = Resizer.fit({ x = 4, y = 4, w = vp.w - 8, h = vp.h - 8 }, env.limits(w), vp)
			c.maxed = true
		end
		w.x, w.y, w.w, w.h = target.x, target.y, target.w, target.h
		c.animating = true
		local tw = UI.tween(frame, 0.25, { Size = UDim2.fromOffset(target.w, target.h), Position = UDim2.fromOffset(target.x, target.y) })
		local function landed()
			c.animating = false
			if c.alive and w.alive then
				c.layout()
				if env.afterResize then
					pcall(env.afterResize, w)
				end
				env.save(w)
			end
		end
		if tw then
			UI.done(tw, landed)
			task.delay(0.6, function()
				if c.animating then
					landed()
				end
			end)
		else
			landed()
		end
	end

	function c.destroy()
		c.alive = false
		if c.stepConn then
			pcall(function()
				c.stepConn:Disconnect()
			end)
			c.stepConn = nil
		end
		thawScrolling()
		if badge then
			badge:Destroy()
			badge = nil
		end
	end

	return c
end

return Resizer
