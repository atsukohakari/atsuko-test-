local Edge = loadmodule("Hub/modules/edge.lua")

local layouts = { "original", "sidebar", "window" }
local spots = { "left", "right", "top", "bottom" }
local viewports = {
	{ name = "phone 360x640", w = 360, h = 640 },
	{ name = "phone 412x915", w = 412, h = 915 },
	{ name = "laptop 1280x720", w = 1280, h = 720 },
	{ name = "desktop 1920x1080", w = 1920, h = 1080 },
}

T.section("edge: chevron table, every cell")
T.eq(Edge.CHEVRON.left.shown, "chevron-left")
T.eq(Edge.CHEVRON.left.hidden, "chevron-right")
T.eq(Edge.CHEVRON.right.shown, "chevron-right")
T.eq(Edge.CHEVRON.right.hidden, "chevron-left")
T.eq(Edge.CHEVRON.top.shown, "chevron-up")
T.eq(Edge.CHEVRON.top.hidden, "chevron-down")
T.eq(Edge.CHEVRON.bottom.shown, "chevron-down")
T.eq(Edge.CHEVRON.bottom.hidden, "chevron-up")

T.section("edge: which screen edge the arrow sits on")
for _, dock in ipairs(spots) do
	T.eq(Edge.edgeFor("original", dock), dock, "original " .. dock)
	T.eq(Edge.edgeFor("sidebar", dock), "left", "sidebar " .. dock)
end
T.eq(Edge.edgeFor("window", "left"), "left")
T.eq(Edge.edgeFor("window", "right"), "right")
T.eq(Edge.edgeFor("window", "top"), "right")
T.eq(Edge.edgeFor("window", "bottom"), "right")
T.eq(Edge.edgeFor("original", nil), "bottom")
T.eq(Edge.edgeFor("original", "middle"), "bottom")

T.section("edge: place over 3 layouts x 4 docks x 4 bars x shown/hidden on 4 screens")
local cases = 0
for _, vp in ipairs(viewports) do
	for _, layout in ipairs(layouts) do
		for _, dock in ipairs(spots) do
			for _, bar in ipairs(spots) do
				for _, hidden in ipairs({ true, false }) do
					cases = cases + 1
					local label = vp.name .. " " .. layout .. " dock " .. dock .. " bar " .. bar .. (hidden and " hidden" or " shown")
					local r = Edge.place(layout, dock, bar, hidden, { w = vp.w, h = vp.h }, { l = 0, t = 0, r = 0, b = 0 }, { pillW = 340 })
					local edge = Edge.edgeFor(layout, dock)
					T.eq(r.edge, edge, label .. " edge")
					T.eq(r.chevron, Edge.CHEVRON[edge][hidden and "hidden" or "shown"], label .. " chevron")
					local vertical = edge == "left" or edge == "right"
					T.eq(r.size.w, vertical and 38 or 66, label .. " width")
					T.eq(r.size.h, vertical and 66 or 38, label .. " height")
					T.eq(r.anchor.x, 0.5, label .. " anchor")
					local left = r.position.x - r.size.w / 2
					local right = r.position.x + r.size.w / 2
					local top = r.position.y - r.size.h / 2
					local bottom = r.position.y + r.size.h / 2
					local visibleW = math.min(right, vp.w) - math.max(left, 0)
					local visibleH = math.min(bottom, vp.h) - math.max(top, 0)
					T.ok(visibleW > 0 and visibleH > 0, label .. " is on screen")
					if edge == "left" then
						T.eq(left, 26 - 38, label .. " peeks 26 from the left")
					elseif edge == "right" then
						T.eq(left, vp.w - 26, label .. " peeks 26 from the right")
					elseif edge == "top" then
						T.eq(top, 26 - 38, label .. " peeks 26 from the top")
					else
						T.eq(top, vp.h - 26, label .. " peeks 26 from the bottom")
					end
					local oLeft = r.offPosition.x - r.size.w / 2
					local oRight = r.offPosition.x + r.size.w / 2
					local oTop = r.offPosition.y - r.size.h / 2
					local oBottom = r.offPosition.y + r.size.h / 2
					T.ok(oRight <= 0 or oLeft >= vp.w or oBottom <= 0 or oTop >= vp.h, label .. " off position is fully off screen")
					if vertical then
						T.ok(r.position.y - 33 >= 70 and r.position.y + 33 <= vp.h - 150, label .. " clear of reserved corners")
					else
						T.ok(r.position.x - 33 >= 110 and r.position.x + 33 <= vp.w - 20, label .. " clear of reserved corners")
					end
					if not vertical and bar == edge then
						T.ok(math.abs(r.position.x - vp.w / 2) >= 170 + 33 or vp.w < 560, label .. " does not sit on the top bar")
					end
					T.ok(r.icon == "chevron-left" or r.icon == "chevron-right" or r.icon == "chevron-down", label .. " icon is a real icon")
				end
			end
		end
	end
end
T.ok(cases == 4 * 96, "ran " .. cases .. " cases")

T.section("edge: icon registry only uses icons the hub has")
local allowed = { ["chevron-left"] = true, ["chevron-right"] = true, ["chevron-down"] = true }
for _, edge in ipairs(spots) do
	for _, key in ipairs({ "shown", "hidden" }) do
		local name = Edge.CHEVRON[edge][key]
		local ic = Edge.ICON[name]
		T.ok(ic ~= nil, name .. " has an icon entry")
		T.ok(allowed[ic.name], name .. " maps to an existing icon")
		T.ok(ic.rotation == 0 or ic.rotation == 180, name .. " rotation")
	end
end
T.eq(Edge.ICON["chevron-up"].name, "chevron-down")
T.eq(Edge.ICON["chevron-up"].rotation, 180)

T.section("edge: follows the dock and the move offset")
local vp = { w = 1280, h = 720 }
local r1 = Edge.place("original", "left", "top", true, vp, nil, { dock = { x = 12, y = 200, w = 52, h = 300 } })
T.eq(r1.position.y, 350)
local r2 = Edge.place("original", "left", "top", true, vp, nil, { dock = { x = 12, y = 100, w = 52, h = 200 }, along = 40 })
T.eq(r2.position.y, 240)
local r3 = Edge.place("original", "bottom", "top", true, vp, nil, { dock = { x = 300, y = 650, w = 400, h = 52 } })
T.eq(r3.position.x, 500)
local r4 = Edge.place("original", "left", "top", true, vp, nil, { along = 9000 })
T.ok(r4.position.y + 33 <= vp.h - 150, "move offset is clamped")
local r5 = Edge.place("original", "left", "top", true, vp, nil, { along = -9000 })
T.ok(r5.position.y - 33 >= 70, "move offset is clamped at the top")

T.section("edge: bottom dock with the bar at the bottom steps aside")
local b1 = Edge.place("original", "bottom", "bottom", true, { w = 1280, h = 720 }, nil, { pillW = 340 })
T.ok(math.abs(b1.position.x - 640) >= 170 + 33)
local b2 = Edge.place("original", "bottom", "top", true, { w = 1280, h = 720 }, nil, { pillW = 340 })
T.eq(b2.position.x, 640)

T.section("edge: a bar in a bottom corner is stepped around too")
do
	local c1 = Edge.place("original", "bottom", "bottomleft", true, { w = 800, h = 640 }, nil, { pillW = 340 })
	T.ok(c1.position.x - 33 >= 12 + 340 + 8, "the arrow moves right of a wide bar in the bottom left: " .. c1.position.x)
	local c2 = Edge.place("original", "bottom", "bottomright", true, { w = 1280, h = 720 }, nil, { pillW = 340 })
	T.eq(c2.position.x, 640, "on a wide screen the middle is already clear of the bottom right bar")
	local c3 = Edge.place("original", "bottom", "bottomright", true, { w = 700, h = 640 }, nil, { pillW = 340 })
	T.ok(c3.position.x + 33 <= 700 - 12 - 340 - 8, "and steps left of it when it reaches the middle: " .. c3.position.x)
	local c4 = Edge.place("original", "bottom", "left", true, { w = 480, h = 640 }, nil, { pillW = 340 })
	T.eq(c4.position.x, 240, "a bar at the top never moves a bottom arrow")
	local c5 = Edge.place("original", "bottom", "bottom", true, { w = 1280, h = 720 }, nil, { pillW = 340 })
	T.eq(c5.position.x, b1.position.x, "the bottom middle is stepped around the same as before")
end

T.section("edge: safe insets push the arrow in")
local s1 = Edge.place("original", "left", "top", true, { w = 1280, h = 720 }, { l = 0, t = 200, r = 0, b = 0 }, { along = -9000 })
T.ok(s1.position.y - 33 >= 200)
local s2 = Edge.place("original", "bottom", "top", true, { w = 1280, h = 720 }, { l = 0, t = 0, r = 400, b = 0 }, { along = 0, dock = { x = 1000, y = 600, w = 200, h = 50 } })
T.ok(s2.position.x + 33 <= 1280 - 400)

T.section("edge: tiny screens still give a position")
local t1 = Edge.place("original", "left", "top", true, { w = 200, h = 200 }, nil, nil)
T.ok(t1.position.y > 0 and t1.position.y < 200)
local t2 = Edge.place("original", "bottom", "bottom", false, { w = 200, h = 200 }, nil, nil)
T.ok(t2.position.x > 0 and t2.position.x < 200)

T.section("edge: roblox layer moves with the dock and hides on desktop")
local Mock = loadmodule("Testing/mocks/roblox_mock.lua")
local env = Mock.install({})
local ctx = env.ctx
ctx.Edge = Instance.new("TextButton")
ctx.EdgeIcon = Instance.new("ImageLabel")
ctx.UI.setIcon = function(img, name)
	img.icon = name
end
ctx.Panel.mode = "closed"
ctx.HUB = { hidden = false }
ctx.Shell = { mode = "original" }
ctx.Dock = nil
ctx.Core.mobile = function()
	return ctx.S.touch ~= false
end
ctx.Core.moved = function()
	return UDim2.fromOffset(0, 0)
end
ctx.S.layout = "original"
ctx.S.dockPos = "left"
ctx.S.barPos = "top"
Edge.init(ctx)
T.eq(ctx.Core.edgeUpdate, Edge.update)
T.eq(ctx.Edge.Visible, true)
T.eq(ctx.EdgeIcon.icon, "chevron-right")
local startX = ctx.Edge.Position.X.Offset
T.ok(startX < 30, "left edge")
ctx.S.dockPos = "right"
Edge.update(true)
env.advance(0.1)
T.ok(ctx.Edge.Position.X.Offset < 600, "still gliding, not teleported")
env.advance(0.5)
T.ok(ctx.Edge.Position.X.Offset > 1200, "arrived on the right")
T.eq(ctx.EdgeIcon.icon, "chevron-left")
ctx.Panel.mode = "bar"
Edge.update(true)
T.eq(ctx.Edge.Visible, true, "the arrow slides away when the hub opens")
env.advance(0.5)
T.eq(ctx.Edge.Visible, false, "and is gone while the hub is open")
T.ok(ctx.Edge.Position.X.Offset > 1280, "off the screen")
T.eq(ctx.EdgeIcon.icon, "chevron-right")
ctx.S.dockPos = "top"
Edge.update(true)
env.advance(0.5)
T.eq(ctx.Edge.Visible, false, "still gone after the dock moves")
T.eq(ctx.EdgeIcon.icon, "chevron-down")
T.eq(ctx.EdgeIcon.Rotation, 180)
T.eq(ctx.Edge.Size.X.Offset, 66)
ctx.Panel.mode = "closed"
Edge.update(true)
T.eq(ctx.Edge.Visible, true, "closing the hub brings the arrow back")
env.advance(0.5)
T.eq(ctx.Edge.Visible, true)
T.eq(ctx.EdgeIcon.icon, "chevron-down", "pointing in, to open the hub")
T.eq(ctx.EdgeIcon.Rotation, 0)
T.ok(ctx.Edge.Position.Y.Offset < 60, "on the screen at the top")
ctx.Panel.mode = nil
Edge.update(false)
T.eq(ctx.Edge.Visible, true, "before the hub was ever opened it shows too")
ctx.Panel.mode = "closed"
ctx.S.touch = false
Edge.update(true)
env.advance(0.5)
T.eq(ctx.Edge.Visible, false)
ctx.S.touch = true
Edge.update(true)
T.eq(ctx.Edge.Visible, true)
ctx.HUB.hidden = true
Edge.update(false)
T.eq(ctx.Edge.Visible, false)
ctx.HUB.hidden = false
Edge.update(false)
T.eq(ctx.Edge.Visible, true)
Edge.destroy()
T.eq(ctx.Core.edgeUpdate, nil)

T.section("edge: in the hub on a phone, the arrow is gone while the hub is open")
do
	local Runner = loadmodule("Testing/mocks/boot_runner.lua")
	local e = Runner.boot({ seconds = 8, viewW = 844, viewH = 390, touch = true })
	local hub = e.hub
	local arrow = hub.Root:FindFirstChild("Edge")
	T.ok(arrow ~= nil, "the arrow is there")
	hub.Panel.closeAll()
	e.run(1)
	T.eq(hub.Panel.mode, "closed")
	T.eq(arrow.Visible, true, "with the hub closed the arrow shows")
	arrow.Activated:Fire()
	e.run(1)
	T.eq(hub.Panel.mode, "bar", "tapping it opens the hub")
	T.eq(arrow.Visible, false, "and the arrow goes away")
	hub.Panel.closeAll()
	e.run(1)
	T.eq(arrow.Visible, true, "closing the hub brings it back")
	arrow.Activated:Fire()
	e.run(1)
	T.eq(arrow.Visible, false, "opening again hides it again")
	hub.Panel.toggleAll()
	e.run(1)
	T.eq(hub.Panel.mode, "closed", "closing another way")
	T.eq(arrow.Visible, true, "brings it back too")
	T.eq(#e.errors, 0, "no errors: " .. table.concat(e.errors, " | "))
end

T.section("edge: on a computer the arrow never shows")
do
	local Runner = loadmodule("Testing/mocks/boot_runner.lua")
	local e = Runner.boot({ seconds = 8 })
	local arrow = e.hub.Root:FindFirstChild("Edge")
	e.hub.Panel.closeAll()
	e.run(1)
	T.eq(arrow.Visible, false, "closed")
	e.hub.Panel.toggleAll()
	e.run(1)
	T.eq(arrow.Visible, false, "open")
end
