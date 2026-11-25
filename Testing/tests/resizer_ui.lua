local Runner = loadmodule("Testing/mocks/boot_runner.lua")
local Resizer = loadmodule("Hub/modules/resizer.lua")

local DIRS = { "n", "s", "e", "w", "ne", "nw", "se", "sw" }

local DESK = Runner.boot({ seconds = 6 })
local BASE_W, BASE_H = DESK.hub.L.W, DESK.hub.L.H

local function fresh(env, hub)
	local old = hub.Win.get("editor")
	if old then
		old:close(true)
	end
	hub.Win.closeAll()
	hub.S.windows.editor = nil
	hub.S.editorPopped = false
	hub.L.W, hub.L.H = BASE_W, BASE_H
	hub.Ed.popOut()
	env.run(0.6)
	local w = hub.Win.get("editor")
	T.ok(w ~= nil, "the editor window opened")
	return w
end

local function openEditor(opts)
	if opts then
		local env = Runner.boot(opts)
		local hub = env.hub
		hub.Ed.popOut()
		env.run(1)
		local w = hub.Win.get("editor")
		T.ok(w ~= nil, "the editor window opened")
		return env, hub, w
	end
	local env, hub = DESK, DESK.hub
	return env, hub, fresh(env, hub)
end

local function limitsFor(hub)
	return { minW = 300, minH = 240, maxW = math.min(1600, hub.L.W - 8), maxH = math.min(1000, hub.L.H - 8), margin = 40 }
end

local function rectOf(w)
	return { x = w.x, y = w.y, w = w.w, h = w.h }
end

local function handle(w, dir)
	return w.frame:FindFirstChild("Resize_" .. dir)
end

local function uis()
	return game:GetService("UserInputService")
end

local function mouseDown(x, y)
	return { UserInputType = Enum.UserInputType.MouseButton1, Position = Vector3.new(x, y, 0) }
end

local function mouseTo(x, y)
	return { UserInputType = Enum.UserInputType.MouseMovement, Position = Vector3.new(x, y, 0) }
end

local function touchAt(x, y)
	return { UserInputType = Enum.UserInputType.Touch, Position = Vector3.new(x, y, 0) }
end

local function dragMouse(env, hub, w, dir, dxUnits, dyUnits, hold)
	local sc = hub.L.scale
	local down = mouseDown(500, 400)
	handle(w, dir).InputBegan:Fire(down)
	uis().InputChanged:Fire(mouseTo(500 + dxUnits * sc, 400 + dyUnits * sc))
	env.run(0.05)
	if not hold then
		uis().InputEnded:Fire(down)
		env.run(0.05)
	end
	return down
end

local function expectedFor(hub, start, dir, dx, dy)
	return Resizer.compute(start, dir, { x = dx, y = dy }, limitsFor(hub), { w = hub.L.W, h = hub.L.H })
end

local function sameRect(label, w, r)
	T.eq(w.x, r.x, label .. ": x")
	T.eq(w.y, r.y, label .. ": y")
	T.eq(w.w, r.w, label .. ": w")
	T.eq(w.h, r.h, label .. ": h")
	T.eq(w.frame.Size.X.Offset, r.w, label .. ": the frame is that wide")
	T.eq(w.frame.Size.Y.Offset, r.h, label .. ": the frame is that high")
	T.eq(w.frame.Position.X.Offset, r.x, label .. ": the frame is at that x")
	T.eq(w.frame.Position.Y.Offset, r.y, label .. ": the frame is at that y")
end

T.section("resizer_ui: the editor window gets eight handles")
do
	local env, hub, w = openEditor()
	T.ok(w.resizer ~= nil, "the window has the resizer")
	T.eq(w.resize, handle(w, "se"), "w.resize is the south east corner")
	T.eq(w.resize.Name, "Resize_se", "and it carries its new name")
	local want = {}
	for _, spec in ipairs(Resizer.handles(w.w, w.h, false, 46)) do
		want[spec.dir] = spec
	end
	for _, dir in ipairs(DIRS) do
		local b = handle(w, dir)
		T.ok(b ~= nil, dir .. " exists")
		if b then
			T.eq(b.ClassName, "TextButton", dir .. " is a button")
			T.eq(b.Active, true, dir .. " takes the input")
			T.eq(b.BackgroundTransparency, 1, dir .. " is see-through")
			T.eq(b.Size.X.Offset, want[dir].w, dir .. " width")
			T.eq(b.Size.Y.Offset, want[dir].h, dir .. " height")
			T.eq(b.Position.X.Offset, want[dir].x, dir .. " x")
			T.eq(b.Position.Y.Offset, want[dir].y, dir .. " y")
			T.ok(b.Position.X.Offset >= 0 and b.Position.Y.Offset >= 0 and b.Position.X.Offset + b.Size.X.Offset <= w.w and b.Position.Y.Offset + b.Size.Y.Offset <= w.h, dir .. " is inside the window")
			T.ok(b.ZIndex > w.body.ZIndex, dir .. " sits above the body")
			T.ok(b.ZIndex < w.closeBtn.ZIndex and b.ZIndex < w.minBtn.ZIndex, dir .. " sits below the title buttons")
			local marks = 0
			for _, c in ipairs(b:GetChildren()) do
				if c.Name == "Mark" then
					marks += 1
					T.eq(c.BackgroundTransparency, 1, dir .. " mark starts hidden")
				end
			end
			T.eq(marks, (#dir == 2) and 2 or 1, dir .. " has its mark")
		end
	end
	T.eq(#env.errors, 0, "no errors: " .. table.concat(env.errors, " | "))
	T.eq(#env.badProps, 0, "no bad property values: " .. table.concat(env.badProps, " | "))
end

T.section("resizer_ui: a mouse drag from every side and corner")
do
	for _, dir in ipairs(DIRS) do
		local env, hub, w = openEditor()
		local start = rectOf(w)
		local dx, dy = 37, -23
		dragMouse(env, hub, w, dir, dx, dy)
		sameRect("mouse " .. dir, w, expectedFor(hub, start, dir, dx, dy))
		T.eq(hub.Drag.cur, nil, "mouse " .. dir .. ": the drag is over")
		local saved = hub.S.windows.editor
		T.ok(saved ~= nil and saved.w == w.w and saved.h == w.h, "mouse " .. dir .. ": the size is saved")
		T.eq(#env.errors, 0, "mouse " .. dir .. ": no errors: " .. table.concat(env.errors, " | "))
	end
end

T.section("resizer_ui: five moves in one frame are applied once, with the last one")
do
	local env, hub, w = openEditor()
	local start = rectOf(w)
	local down = mouseDown(500, 400)
	handle(w, "e").InputBegan:Fire(down)
	for i = 1, 5 do
		uis().InputChanged:Fire(mouseTo(500 + i * 10 * hub.L.scale, 400))
	end
	T.eq(w.w, start.w, "nothing is applied between frames")
	env.run(0.05)
	T.eq(w.w, expectedFor(hub, start, "e", 50, 0).w, "the last position wins")
	uis().InputEnded:Fire(down)
	env.run(0.05)
end

T.section("resizer_ui: scrolling is off during the drag and back after")
do
	local env, hub, w = openEditor()
	local frames = {}
	for _, o in ipairs(w.frame:GetDescendants()) do
		if o.ClassName == "ScrollingFrame" then
			frames[#frames + 1] = o
		end
	end
	T.ok(#frames >= 1, "there is a scrolling frame in the editor")
	for _, f in ipairs(frames) do
		T.eq(f.ScrollingEnabled, true, f.Name .. " scrolls before")
	end
	local down = dragMouse(env, hub, w, "se", 30, 30, true)
	for _, f in ipairs(frames) do
		T.eq(f.ScrollingEnabled, false, f.Name .. " does not scroll during the drag")
	end
	uis().InputEnded:Fire(down)
	env.run(0.05)
	for _, f in ipairs(frames) do
		T.eq(f.ScrollingEnabled, true, f.Name .. " scrolls again after")
	end
end

T.section("resizer_ui: the size badge")
do
	local env, hub, w = openEditor()
	T.eq(w.frame:FindFirstChild("SizeBadge"), nil, "no badge before a drag")
	local down = dragMouse(env, hub, w, "se", 40, 20, true)
	local badge = w.frame:FindFirstChild("SizeBadge")
	T.ok(badge ~= nil and badge.Visible, "the badge shows during the drag")
	T.eq(badge and badge.Text, Resizer.label(w.w, w.h), "it says the new size")
	T.ok(badge.Position.X.Offset <= w.w and badge.Position.Y.Offset <= w.h, "and sits inside the window")
	uis().InputEnded:Fire(down)
	env.run(0.3)
	T.ok(badge.Visible, "it is still there a moment after the release")
	env.run(1.2)
	T.eq(badge.Visible, false, "and gone about a second later")
end

T.section("resizer_ui: the marks fade in while dragging")
do
	local env, hub, w = openEditor()
	local b = handle(w, "se")
	local down = dragMouse(env, hub, w, "se", 10, 10, true)
	env.run(0.3)
	local shown = 0
	for _, c in ipairs(b:GetChildren()) do
		if c.Name == "Mark" and c.BackgroundTransparency < 0.5 then
			shown += 1
		end
	end
	T.eq(shown, 2, "both corner marks are showing")
	uis().InputEnded:Fire(down)
	env.run(0.4)
	local hidden = 0
	for _, c in ipairs(b:GetChildren()) do
		if c.Name == "Mark" and c.BackgroundTransparency >= 0.5 then
			hidden += 1
		end
	end
	T.eq(hidden, 2, "and they fade out again")
end

T.section("resizer_ui: a drag past the screen edge stays on the screen")
do
	for _, dir in ipairs(DIRS) do
		local env, hub, w = openEditor()
		dragMouse(env, hub, w, dir, 5000, 5000)
		T.ok(w.x >= 0 and w.y >= 0 and w.x + w.w <= hub.L.W + 1 and w.y + w.h <= hub.L.H + 1, dir .. " plus: inside the screen")
		local env2, hub2, w2 = openEditor()
		dragMouse(env2, hub2, w2, dir, -5000, -5000)
		T.ok(w2.x >= 0 and w2.y >= 0 and w2.x + w2.w <= hub2.L.W + 1 and w2.y + w2.h <= hub2.L.H + 1, dir .. " minus: inside the screen")
		T.ok(w2.w >= 300 and w2.h >= 240, dir .. " minus: not below the smallest size")
	end
end

T.section("resizer_ui: size and place come back when the window is opened again")
do
	local env, hub, w = openEditor()
	dragMouse(env, hub, w, "nw", -90, -40)
	local after = rectOf(w)
	w:close(true)
	env.run(0.5)
	T.eq(hub.Win.get("editor"), nil, "the window closed")
	hub.Ed.popOut()
	env.run(1)
	local again = hub.Win.get("editor")
	T.ok(again ~= nil, "it opened again")
	T.eq(again.w, after.w, "same width")
	T.eq(again.h, after.h, "same height")
	T.ok(math.abs(again.x - after.x) <= 1 and math.abs(again.y - after.y) <= 1, "same place")
end

T.section("resizer_ui: a smaller screen pulls the window back in")
do
	local env, hub, w = openEditor()
	dragMouse(env, hub, w, "se", 300, 200)
	hub.L.W, hub.L.H = 800, 450
	hub.Win.relayout()
	T.ok(w.x >= 0 and w.y >= 0, "the corner is on the screen")
	T.ok(w.x + w.w <= 800 and w.y + w.h <= 450, "the whole window is on the screen: " .. w.x .. "," .. w.y .. "," .. w.w .. "," .. w.h)
	T.ok(w.w >= 300 and w.h >= 240, "and it keeps its smallest size")
	hub.L.W, hub.L.H = 360, 640
	hub.Win.relayout()
	T.ok(w.x + w.w <= 360 and w.y + w.h <= 640, "a phone held upright fits too: " .. w.x .. "," .. w.y .. "," .. w.w .. "," .. w.h)
	sameRect("the frame follows", w, rectOf(w))
end

T.section("resizer_ui: minimize hides the handles")
do
	local env, hub, w = openEditor()
	w:setMin(true)
	env.run(0.5)
	for _, dir in ipairs(DIRS) do
		T.eq(handle(w, dir).Visible, false, dir .. " is hidden while minimized")
	end
	local down = mouseDown(500, 400)
	handle(w, "se").InputBegan:Fire(down)
	T.eq(hub.Drag.cur, nil, "and a minimized window cannot be resized")
	w:setMin(false)
	env.run(0.5)
	for _, dir in ipairs(DIRS) do
		T.eq(handle(w, dir).Visible, true, dir .. " is back")
	end
end

T.section("resizer_ui: a locked window can only grow from the east and south")
do
	for _, dir in ipairs(DIRS) do
		local env, hub, w = openEditor()
		w.locked = true
		local start = rectOf(w)
		dragMouse(env, hub, w, dir, 30, 30)
		local moves = dir == "n" or dir == "w" or dir == "nw" or dir == "ne" or dir == "sw"
		if moves then
			sameRect("locked " .. dir, w, start)
		else
			sameRect("locked " .. dir, w, expectedFor(hub, start, dir, 30, 30))
		end
	end
end

T.section("resizer_ui: closing the window in the middle of a drag")
do
	local env, hub, w = openEditor()
	local down = dragMouse(env, hub, w, "se", 20, 20, true)
	w:close(true)
	uis().InputChanged:Fire(mouseTo(700, 600))
	env.run(0.1)
	uis().InputEnded:Fire(down)
	env.run(0.1)
	T.eq(hub.Drag.cur, nil, "nothing is left dragging")
	T.eq(#env.errors, 0, "no errors: " .. table.concat(env.errors, " | "))
	hub.Ed.popOut()
	env.run(1)
	local again = hub.Win.get("editor")
	T.ok(again ~= nil and again.resizer ~= nil, "the next window works")
	local start = rectOf(again)
	dragMouse(env, hub, again, "e", 25, 0)
	sameRect("after the closed one", again, expectedFor(hub, start, "e", 25, 0))
end

T.section("resizer_ui: a double tap on the title maximizes and restores")
do
	local env, hub, w = openEditor()
	local start = rectOf(w)
	w.header.Activated:Fire()
	w.header.Activated:Fire()
	env.run(0.6)
	local lim = limitsFor(hub)
	T.ok(w.w > start.w and w.h > start.h, "it grew")
	T.ok(w.w <= lim.maxW + 1 and w.h <= lim.maxH + 1, "within its largest size")
	T.ok(w.x >= 0 and w.y >= 0 and w.x + w.w <= hub.L.W and w.y + w.h <= hub.L.H, "and fits the screen")
	sameRect("maximized", w, rectOf(w))
	T.eq(w.minimized, false, "it did not minimize")
	w.header.Activated:Fire()
	w.header.Activated:Fire()
	env.run(0.6)
	sameRect("restored", w, start)
end

T.section("resizer_ui: resizing by hand after a maximize forgets the old size")
do
	local env, hub, w = openEditor()
	local start = rectOf(w)
	w.header.Activated:Fire()
	w.header.Activated:Fire()
	env.run(0.6)
	local big = rectOf(w)
	dragMouse(env, hub, w, "e", -80, 0)
	T.eq(w.w, expectedFor(hub, big, "e", -80, 0).w, "the hand resize worked")
	w.header.Activated:Fire()
	w.header.Activated:Fire()
	env.run(0.6)
	T.ok(w.w > start.w and w.h > start.h, "the next double tap maximizes again instead of restoring")
end

T.section("resizer_ui: a window that is not resizable keeps its corner button")
do
	local env, hub = openEditor()
	local w2 = hub.Win.show("plain_probe", { title = "Plain", w = 300, h = 200, minW = 240, minH = 160, maxW = 600, maxH = 500, build = function() end })
	env.run(1)
	T.eq(w2.resizer, nil, "no resizer")
	T.eq(w2.resize.Name, "Resize", "the old corner button")
	T.eq(w2.frame:FindFirstChild("Resize_n"), nil, "no side handles")
	local start = rectOf(w2)
	local down = mouseDown(500, 400)
	w2.resize.InputBegan:Fire(down)
	uis().InputChanged:Fire(mouseTo(500 + 50 * hub.L.scale, 400 + 40 * hub.L.scale))
	uis().InputEnded:Fire(down)
	env.run(0.1)
	T.eq(w2.w, start.w + 50, "it still resizes the old way (width)")
	T.eq(w2.h, start.h + 40, "it still resizes the old way (height)")
	w2.header.Activated:Fire()
	w2.header.Activated:Fire()
	env.run(0.6)
	T.eq(w2.minimized, true, "a double tap still minimizes it")
	T.eq(#env.errors, 0, "no errors: " .. table.concat(env.errors, " | "))
end

T.section("resizer_ui: the editor's own controls follow the window width")
do
	local env, hub, w = openEditor()
	local Ed = hub.Ed
	T.eq(Ed.compact, false, "wide: the toolbar is full")
	T.eq(Ed.runBtn.Size.X.Offset, 76, "wide: Run has its label")
	dragMouse(env, hub, w, "e", -400, 0)
	env.run(0.4)
	T.eq(w.w, 300, "the window is at its smallest width")
	T.eq(Ed.compact, true, "narrow: the toolbar is compact")
	T.eq(Ed.runBtn.Size.X.Offset, 34, "narrow: Run is a square button")
	T.ok(Ed.nameBg.Size.X.Offset <= -(34 + 3 * 40 + 8), "narrow: the name box leaves room for the buttons")
	Ed.openFind()
	env.run(0.4)
	T.ok(Ed.findBar.Size.X.Offset >= 190 and Ed.findBar.Size.X.Offset <= Ed.area.AbsoluteSize.X, "narrow: the find bar fits inside the code area")
	T.eq(Ed.findCount.Visible, false, "narrow: the match count steps aside")
	Ed.closeFind()
	dragMouse(env, hub, w, "e", 500, 0)
	env.run(0.4)
	T.ok(w.w >= 800, "wide again")
	T.eq(Ed.compact, false, "wide again: full toolbar")
	T.eq(Ed.runBtn.Size.X.Offset, 76, "wide again: Run has its label")
	T.eq(Ed.openBtn.Visible, true, "wide again: the Open button is back")
	T.eq(#env.errors, 0, "no errors: " .. table.concat(env.errors, " | "))
	T.eq(#env.badProps, 0, "no bad property values: " .. table.concat(env.badProps, " | "))
end

T.section("resizer_ui: the text and the scroll spot are kept while resizing")
do
	local env, hub, w = openEditor()
	local Ed = hub.Ed
	local code = {}
	for i = 1, 80 do
		code[#code + 1] = "print(" .. i .. ") -- a line of code that is a bit long so that it needs sideways room too"
	end
	Ed.setText(table.concat(code, "\n"))
	env.run(0.5)
	Ed.scroll.CanvasPosition = Vector2.new(35, 210)
	local textBefore = Ed.box.Text
	dragMouse(env, hub, w, "se", 120, 60)
	env.run(0.5)
	T.eq(Ed.box.Text, textBefore, "the text is untouched")
	T.eq(Ed.scroll.CanvasPosition.Y, 210, "the vertical scroll spot is kept")
	T.eq(Ed.scroll.CanvasPosition.X, 35, "the sideways scroll spot is kept")
	dragMouse(env, hub, w, "w", 60, 0)
	env.run(0.5)
	T.eq(Ed.box.Text, textBefore, "the text is untouched after the west edge too")
	T.eq(Ed.scroll.CanvasPosition.Y, 210, "and the scroll spot is kept")
end

T.section("resizer_ui: the editor remembers it was popped out")
do
	local env, hub = DESK, DESK.hub
	hub.Win.closeAll()
	hub.S.windows.editor = nil
	hub.S.editorPopped = false
	T.eq(hub.S.editorPopped, false, "off for a new user")
	T.eq(hub.Ed.popBtn.Visible, false, "the pop out button waits for the page")
	hub.Ed.popOut()
	env.run(1)
	T.eq(hub.S.editorPopped, true, "popped out is remembered")
	hub.Ed.dock()
	env.run(0.5)
	T.eq(hub.S.editorPopped, false, "docking is remembered")
	hub.Ed.popOut()
	env.run(1)
	hub.Win.closeAll()
	env.run(0.5)
	T.eq(hub.S.editorPopped, true, "the hub closing its windows does not forget it")
	T.eq(hub.Ed.popped, false, "but the editor is back in its page")
	hub.Ed.page.onShow()
	env.run(1)
	T.ok(hub.Win.get("editor") ~= nil, "opening the editor page pops it out again")
	hub.Ed.dock()
	env.run(0.5)
	hub.Ed.page.onShow()
	env.run(0.5)
	T.eq(hub.Win.get("editor"), nil, "after docking it stays docked")
end

T.section("resizer_ui: the docked editor offers the pop out button")
do
	local env, hub = DESK, DESK.hub
	hub.Win.closeAll()
	env.run(0.3)
	hub.Ed.view.Parent = hub.Ed.page.frame
	hub.Ed.refresh()
	env.run(0.5)
	hub.Ed.view.Parent = hub.Ed.page.frame
	hub.Ed.refresh()
	T.eq(hub.Ed.popBtn.Name, "PopOut", "the button exists")
	local label
	for _, o in ipairs(hub.Ed.popBtn:GetDescendants()) do
		if o.ClassName == "TextLabel" and o.Text ~= "" then
			label = o.Text
		end
	end
	T.eq(label, "Pop out to move and resize", "it says what it does")
	hub.Ed.popBtn.Activated:Fire()
	env.run(1)
	T.ok(hub.Win.get("editor") ~= nil, "pressing it pops the editor out")
	T.eq(hub.Ed.popBtn.Visible, false, "and it is not shown inside the window")
end

T.section("resizer_ui: reset window sizes")
do
	local env, hub, w = openEditor()
	dragMouse(env, hub, w, "se", 150, 90)
	T.ok(w.w > 560 and w.h > 400, "the window is bigger now")
	T.ok(hub.S.windows.editor.w ~= nil, "and the size is saved")
	hub.Win.resetSizes()
	env.run(0.5)
	T.eq(w.w, 560, "back to the first width")
	T.eq(w.h, 400, "back to the first height")
	T.eq(hub.S.windows.editor.w, nil, "the saved size is gone")
	T.ok(hub.S.windows.editor.x ~= nil, "the saved place is kept")
	sameRect("frame", w, rectOf(w))
end

T.section("resizer_ui: the settings have the reset button")
do
	local env, hub = DESK, DESK.hub
	hub.Win.closeAll()
	hub.S.windows.editor = nil
	local row
	for _, o in ipairs(hub.Gui:GetDescendants()) do
		if o.ClassName == "TextLabel" and o.Text == "Reset window sizes" then
			row = o.Parent
		end
	end
	T.ok(row ~= nil, "the row exists")
	hub.Ed.popOut()
	env.run(1)
	local w = hub.Win.get("editor")
	dragMouse(env, hub, w, "se", 100, 100)
	T.ok(w.w > 560, "bigger")
	local target = row
	while target and target.ClassName ~= "TextButton" and target.Parent do
		target = target.Parent
	end
	if target and target.ClassName == "TextButton" then
		target.Activated:Fire()
		env.run(0.5)
		T.eq(w.w, 560, "pressing it puts the size back")
	end
end

T.section("resizer_ui: a finger drag, then a second finger")
do
	local env, hub, w = openEditor({ seconds = 6, touch = true, viewW = 800, viewH = 600 })
	local start = rectOf(w)
	local finger = touchAt(600, 400)
	handle(w, "se").InputBegan:Fire(finger)
	T.ok(hub.Drag.cur ~= nil, "the drag started")
	local second = touchAt(300, 300)
	handle(w, "w").InputBegan:Fire(second)
	finger.Position = Vector3.new(600 + 40 * hub.L.scale, 400 + 30 * hub.L.scale, 0)
	uis().InputChanged:Fire(finger)
	second.Position = Vector3.new(100, 100, 0)
	uis().InputChanged:Fire(second)
	T.eq(w.w, start.w, "nothing moves before the next frame (one change per frame)")
	env.run(0.05)
	local want = expectedFor(hub, start, "se", 40, 30)
	sameRect("first finger", w, want)
	uis().InputEnded:Fire(second)
	env.run(0.05)
	T.ok(hub.Drag.cur ~= nil, "the second finger lifting does not end the drag")
	finger.Position = Vector3.new(600 + 60 * hub.L.scale, 400 + 50 * hub.L.scale, 0)
	uis().InputChanged:Fire(finger)
	env.run(0.05)
	sameRect("first finger again", w, expectedFor(hub, start, "se", 60, 50))
	uis().InputEnded:Fire(finger)
	env.run(0.05)
	T.eq(hub.Drag.cur, nil, "the first finger lifting ends it")
	T.eq(w.x, start.x, "the second finger on the west edge never moved the window")
	T.eq(#env.errors, 0, "no errors: " .. table.concat(env.errors, " | "))
end

T.section("resizer_ui: if the resize file can't be loaded the corner button is used")
do
	local env = Runner.boot({ seconds = 6, files = { ["Atsuko Hub/Hub/modules/resizer.lua"] = "this is not lua (" } })
	local hub = env.hub
	hub.Ed.popOut()
	env.run(1)
	local w = hub.Win.get("editor")
	T.ok(w ~= nil, "the editor still opens")
	T.eq(w.resizer, nil, "without the resizer")
	T.eq(w.resize.Name, "Resize", "with the corner button")
	local start = rectOf(w)
	local down = mouseDown(500, 400)
	w.resize.InputBegan:Fire(down)
	uis().InputChanged:Fire(mouseTo(500 + 30 * hub.L.scale, 400 + 30 * hub.L.scale))
	uis().InputEnded:Fire(down)
	env.run(0.1)
	T.eq(w.w, start.w + 30, "which still resizes")
	local said = false
	for _, item in ipairs(hub.Log.items) do
		if string.find(item.msg, "resize handles didn't load", 1, true) then
			said = true
		end
	end
	T.ok(said, "and the log says why")
end
