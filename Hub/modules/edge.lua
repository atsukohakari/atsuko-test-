local Module = {}

local M = { alive = false, conns = {}, tk = 0 }

Module.THICK = 38
Module.LONG = 66
Module.PEEK = 26
Module.GLIDE = 0.35
Module.FADE = 0.25

Module.CHEVRON = {
	left = { shown = "chevron-left", hidden = "chevron-right" },
	right = { shown = "chevron-right", hidden = "chevron-left" },
	top = { shown = "chevron-up", hidden = "chevron-down" },
	bottom = { shown = "chevron-down", hidden = "chevron-up" },
}

Module.ICON = {
	["chevron-left"] = { name = "chevron-left", rotation = 0 },
	["chevron-right"] = { name = "chevron-right", rotation = 0 },
	["chevron-down"] = { name = "chevron-down", rotation = 0 },
	["chevron-up"] = { name = "chevron-down", rotation = 180 },
}

Module.RESERVED = {
	top = { low = 110, high = 20 },
	bottom = { low = 170, high = 150 },
	left = { low = 70, high = 170 },
	right = { low = 20, high = 150 },
}

local VALID = { left = true, right = true, top = true, bottom = true }

function Module.edgeFor(layoutMode, dockPos)
	if layoutMode == "sidebar" then
		return "left"
	end
	if layoutMode == "window" then
		if dockPos == "left" then
			return "left"
		end
		return "right"
	end
	if VALID[dockPos] then
		return dockPos
	end
	return "bottom"
end

local function clamp(v, lo, hi)
	if hi < lo then
		return (lo + hi) / 2
	end
	return math.max(lo, math.min(hi, v))
end

Module.BAR_SIDE = {
	top = { "top", 0.5 },
	left = { "top", 0 },
	right = { "top", 1 },
	bottom = { "bottom", 0.5 },
	bottomleft = { "bottom", 0 },
	bottomright = { "bottom", 1 },
}

function Module.place(layoutMode, dockPos, barPos, hidden, viewport, safeInsets, opts)
	opts = opts or {}
	safeInsets = safeInsets or {}
	local W, H = viewport.w, viewport.h
	local edge = Module.edgeFor(layoutMode, dockPos)
	local vertical = edge == "left" or edge == "right"
	local w = vertical and Module.THICK or Module.LONG
	local h = vertical and Module.LONG or Module.THICK
	local res = Module.RESERVED[edge]
	local insetLow, insetHigh
	if vertical then
		insetLow, insetHigh = safeInsets.t or 0, safeInsets.b or 0
	else
		insetLow, insetHigh = safeInsets.l or 0, safeInsets.r or 0
	end
	local length = vertical and H or W
	local half = Module.LONG / 2
	local lo = math.max(insetLow, res.low) + half + 4
	local hi = length - math.max(insetHigh, res.high) - half - 4
	local along
	if opts.dock then
		if vertical then
			along = opts.dock.y + opts.dock.h / 2
		else
			along = opts.dock.x + opts.dock.w / 2
		end
	else
		along = length / 2
	end
	if vertical then
		along = along + (opts.along or 0)
	end
	local bar = Module.BAR_SIDE[barPos]
	if not vertical and bar and bar[1] == edge then
		local pw = opts.pillW or 340
		local p1 = (bar[2] == 0 and 12) or (bar[2] == 1 and W - 12 - pw) or (W / 2 - pw / 2)
		local p2 = p1 + pw
		if along + half + 8 > p1 and along - half - 8 < p2 then
			local right = p2 + half + 16
			local left = p1 - half - 16
			if right <= hi then
				along = right
			elseif left >= lo then
				along = left
			else
				along = right
			end
		end
	end
	along = clamp(along, lo, hi)
	local cx, cy, ox, oy, ix, iy
	local P = Module.PEEK
	if edge == "left" then
		cx, cy = P - w / 2, along
		ox, oy = -w / 2 - 12, along
		ix, iy = w - P / 2, h / 2
	elseif edge == "right" then
		cx, cy = W - P + w / 2, along
		ox, oy = W + w / 2 + 12, along
		ix, iy = P / 2, h / 2
	elseif edge == "top" then
		cx, cy = along, P - h / 2
		ox, oy = along, -h / 2 - 12
		ix, iy = w / 2, h - P / 2
	else
		cx, cy = along, H - P + h / 2
		ox, oy = along, H + h / 2 + 12
		ix, iy = w / 2, P / 2
	end
	local chevron = Module.CHEVRON[edge][hidden and "hidden" or "shown"]
	local icon = Module.ICON[chevron]
	return {
		edge = edge,
		anchor = { x = 0.5, y = 0.5 },
		position = { x = cx, y = cy },
		offPosition = { x = ox, y = oy },
		size = { w = w, h = h },
		chevron = chevron,
		icon = icon.name,
		rotation = icon.rotation,
		iconPosition = { x = ix, y = iy },
		along = along,
	}
end

function Module.init(ctx)
	if M.alive then
		Module.destroy()
	end
	M.alive = true
	M.ctx = ctx
	local Core, UI, S, L, Bus, Panel, HUB, Pill, Shell = ctx.Core, ctx.UI, ctx.S, ctx.L, ctx.Bus, ctx.Panel, ctx.HUB, ctx.Pill, ctx.Shell
	local Edge, EdgeIcon = ctx.Edge, ctx.EdgeIcon

	local function dockRect()
		local Dock = ctx.Dock
		if not Dock or not Dock.frame or not Dock.posOn then
			return nil
		end
		if S.layout == "window" then
			return nil
		end
		local sz, pos, ap = Dock.frame.Size, Dock.posOn, Dock.frame.AnchorPoint
		local w = sz.X.Offset + sz.X.Scale * L.W
		local h = sz.Y.Offset + sz.Y.Scale * L.H
		local x = pos.X.Scale * L.W + pos.X.Offset - ap.X * w
		local y = pos.Y.Scale * L.H + pos.Y.Offset - ap.Y * h
		return { x = x, y = y, w = w, h = h }
	end

	function Module.update(animate)
		if not M.alive then
			return
		end
		local touch = Core.mobile()
		local hubShown = Panel.mode ~= nil and Panel.mode ~= "closed"
		local mode = Shell.mode or S.layout
		local pillW = math.max(Pill.frame.Size.X.Offset, 340)
		local moved = Core.moved("edge")
		local res = Module.place(mode, S.dockPos, S.barPos, not hubShown, { w = L.W, h = L.H }, { l = 0, t = 0, r = 0, b = 0 }, {
			dock = dockRect(),
			pillW = pillW,
			along = moved.Y.Offset,
		})
		Shell.edgeRes = res
		local visible = touch and not HUB.hidden and not hubShown
		local goal = visible and res.position or res.offPosition
		local time = (animate and S.animations) and Module.GLIDE or 0
		if not visible then
			time = (animate and S.animations) and Module.FADE or 0
		end
		M.tk += 1
		local tk = M.tk
		Edge.AnchorPoint = Vector2.new(0.5, 0.5)
		if visible then
			Edge.Visible = true
		end
		UI.setIcon(EdgeIcon, res.icon)
		EdgeIcon.Rotation = res.rotation
		EdgeIcon.Position = UDim2.fromOffset(res.iconPosition.x, res.iconPosition.y)
		Shell.edgeOn = UDim2.fromOffset(res.position.x, res.position.y)
		Shell.edgeOff = UDim2.fromOffset(res.offPosition.x, res.offPosition.y)
		local tw = UI.tween(Edge, time, {
			Position = UDim2.fromOffset(goal.x, goal.y),
			Size = UDim2.fromOffset(res.size.w, res.size.h),
		}, Enum.EasingStyle.Quint)
		if not visible then
			UI.done(tw, function()
				if M.tk == tk then
					Edge.Visible = false
				end
			end)
		end
	end

	Core.edgeUpdate = Module.update

	local function onMode()
		Module.update(true)
	end
	Bus.on("inputmode", onMode)
	M.bus = onMode
	Module.update(false)
	return Module
end

function Module.destroy()
	if not M.alive then
		return
	end
	M.alive = false
	local ctx = M.ctx
	if ctx and ctx.Bus and M.bus then
		ctx.Bus.off("inputmode", M.bus)
	end
	if ctx and ctx.Core and ctx.Core.edgeUpdate == Module.update then
		ctx.Core.edgeUpdate = nil
	end
end

return Module
