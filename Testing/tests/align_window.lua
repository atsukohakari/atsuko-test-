local src = readsource("Hub/AtsukoHub.lua")
local from = string.find(src, "Core.Align = { cur = 1", 1, true)
T.ok(from ~= nil, "the Core.Align block starts where expected")
local to = from and string.find(src, '\nBus.on("align", function()', from, true)
T.ok(to ~= nil, "the Core.Align block ends where expected")
local block = (from and to) and string.sub(src, from, to) or ""
T.ok(#block > 5000, "the block was cut out of the shipped hub")

local prelude = "local GENV, Core, L, Bus, notify, T, Win, Enum, HUB, RunService, UserInputService, section, Ctl, UI, FONT_B, Vector2, copyText, MOUSE1, TOUCH, accentColor, UDim2, task = ...\n"
local compiled, why = loadstring(prelude .. block .. "\nreturn Core.Align", "=align_block")
T.ok(compiled ~= nil, "the block compiles: " .. tostring(why))

local EVENTS = { Focused = true, FocusLost = true, InputBegan = true, InputEnded = true, Activated = true, MouseEnter = true, MouseLeave = true, Heartbeat = true }

local function signal()
	local s = { list = {} }
	function s:Connect(fn)
		local c = { fn = fn, on = true }
		function c:Disconnect()
			self.on = false
		end
		self.list[#self.list + 1] = c
		return c
	end
	function s:Fire(...)
		for _, c in ipairs(self.list) do
			if c.on then
				c.fn(...)
			end
		end
	end
	return s
end

local function fake(class, props)
	local o = { ClassName = class, Visible = true, Text = "" }
	for k, v in pairs(props or {}) do
		o[k] = v
	end
	return setmetatable(o, {
		__index = function(t, k)
			if EVENTS[k] then
				local s = signal()
				rawset(t, k, s)
				return s
			end
			if k == "IsFocused" then
				return function()
					return false
				end
			end
			return nil
		end,
	})
end

local ENUM = setmetatable({}, {
	__index = function(_, group)
		return setmetatable({}, {
			__index = function(_, item)
				return group .. "." .. item
			end,
		})
	end,
})

local function world(opts)
	opts = opts or {}
	local W = { notes = {}, copies = {}, fired = {}, sections = {}, actions = {}, toggles = {}, choices = {}, buttonRows = {}, conns = {}, delays = {}, shown = nil, open = false, closed = 0 }
	local GENV = {}
	local Core = { mobile = function() return false end }
	local Bus = { fire = function(name) W.fired[#W.fired + 1] = name end, on = function() end }
	local T_ = setmetatable({}, { __index = function() return "color" end })
	local Win = {}
	function Win.show(id, def)
		W.shown = def
		W.open = true
		return { id = id }
	end
	function Win.isOpen()
		return W.open
	end
	function Win.close()
		if W.open then
			W.open = false
			W.closed += 1
			if W.shown and W.shown.onClose then
				W.shown.onClose()
			end
		end
	end
	local UI = {}
	function UI.new(class, props)
		return fake(class, props)
	end
	function UI.label(_, props)
		return fake("TextLabel", props)
	end
	function UI.button(_, props)
		return fake("TextButton", props)
	end
	function UI.corner() end
	function UI.stroke()
		return fake("UIStroke")
	end
	function UI.icon()
		return fake("ImageLabel")
	end
	function UI.pressable() end
	function UI.accent() end
	function UI.tween() end
	local Ctl = {}
	function Ctl.note(_, _, text)
		local n = fake("TextLabel", { Text = text })
		W.note = W.note or n
		W.notesList = W.notesList or {}
		W.notesList[#W.notesList + 1] = n
		return n
	end
	function Ctl.choice(_, order, title, options, get, set)
		local c = { order = order, title = title, options = options, get = get, set = set, render = function() end, row = fake("Frame") }
		W.choices[#W.choices + 1] = c
		return c
	end
	function Ctl.buttons(_, order, list)
		local out = {}
		for i, it in ipairs(list) do
			out[i] = { btn = fake("TextButton"), set = function(icon, text) out[i].last = text end, label = it[2], fn = it[3] }
		end
		W.buttonRows[#W.buttonRows + 1] = { order = order, list = list, out = out }
		return out, fake("Frame")
	end
	function Ctl.action(_, order, text, icon, danger, fn)
		W.actions[#W.actions + 1] = { order = order, text = text, icon = icon, fn = fn }
		return fake("TextButton"), fake("TextLabel")
	end
	function Ctl.toggle(_, order, title, _, get, set)
		local t = { order = order, title = title, get = get, set = set, render = function() end }
		W.toggles[#W.toggles + 1] = t
		return t
	end
	local function section(_, text, order)
		W.sections[#W.sections + 1] = { text = text, order = order }
	end
	local clock = { t = 0 }
	local task = {
		delay = function(t, fn, ...)
			W.delays[#W.delays + 1] = { at = clock.t + t, fn = fn, args = { ... } }
		end,
		defer = function(fn, ...)
			fn(...)
		end,
		wait = function() end,
		spawn = function(fn, ...)
			fn(...)
		end,
	}
	W.GENV = GENV
	W.Core = Core
	W.run = function(rec)
		for _, d in ipairs(W.delays) do
			if d.at <= rec then
				d.fn(table.unpack(d.args))
			end
		end
	end
	local RunService = { Heartbeat = signal() }
	local UserInputService = { InputEnded = signal() }
	W.RunService, W.UserInputService = RunService, UserInputService
	local A = compiled(GENV, Core, { H = 800 }, Bus, function(title, text, kind, dur)
		W.notes[#W.notes + 1] = title .. ": " .. text
	end, T_, Win, ENUM, { alive = true }, RunService, UserInputService, section, Ctl, UI, "font", { new = function(x, y) return { X = x, Y = y } end }, function(text, what)
		W.copies[#W.copies + 1] = text
	end, "M1", "TOUCH", function() return "accent" end, { new = function() return {} end, fromOffset = function() return {} end, fromScale = function() return {} end }, task)
	W.A = A
	return W
end

local NIL = {}

local function adapter(over)
	local a = { version = 1, title = "Test Sword", tabs = { "Hand", "Back", "Base" }, file = "t.json", dirty = false, open = false, key = "P" }
	local data = { { 1, 2, 3, 10, 20, 30 }, { 4, 5, 6, 40, 50, 60 }, { 0, 0, 0, 7, 8, 9 } }
	a.calls = {}
	a.focusSeen = {}
	function a.alive()
		return true
	end
	function a.focus(tab)
		a.focusSeen[#a.focusSeen + 1] = tab
		a.tab = tab
	end
	function a.rows(tab)
		if tab == 3 then
			return { 4, 5, 6 }
		end
		return nil
	end
	function a.get(tab)
		return data[tab] and table.clone(data[tab]) or nil
	end
	function a.set(tab, k, n)
		data[tab][k] = n
		a.dirty = true
		return n
	end
	function a.put(tab, values)
		a.calls[#a.calls + 1] = "put" .. tab
		for k = 1, 6 do
			data[tab][k] = values[k]
		end
	end
	function a.reset() end
	function a.save()
		a.dirty = false
		return true
	end
	function a.load()
		return true
	end
	function a.watch(fn)
		a.watcher = fn
		return function() a.watcher = nil end
	end
	function a.found()
		return "Test Sword | attached"
	end
	function a.press()
		a.pressed = (a.pressed or 0) + 1
	end
	a.optList = { { "equip", "Equip / Unequip", "button", "sword" }, { "roll", "Roll it", "button" }, { "shiny", "Shiny" }, { "ghost", "Ghost" } }
	a.optsSaved = false
	a.optTitle = "Sword"
	function a.opts()
		return { shiny = a.shiny == true }
	end
	function a.setOpt(name, v)
		a.calls[#a.calls + 1] = name .. ":" .. tostring(v)
		if name == "roll" then
			a.set(a.tab or 1, 4, data[a.tab or 1][4] + 180)
		elseif name == "shiny" then
			a.shiny = v
		elseif name == "boom" then
			error("it broke")
		end
	end
	for k, v in pairs(over or {}) do
		if v == NIL then
			a[k] = nil
		else
			a[k] = v
		end
	end
	a.data = data
	return a
end

local function open(W, a)
	W.GENV.AtsukoAlign = a
	local opened = W.A.open()
	T.ok(opened ~= nil, "the window opens")
	local w = { frame = fake("Frame"), alive = true }
	function w:conn(c)
		W.conns[#W.conns + 1] = c
		return c
	end
	function w:close()
		W.A.closing = true
		self.alive = false
		W.open = false
		if W.shown.onClose then
			W.shown.onClose()
		end
	end
	W.w = w
	W.shown.build(w, fake("Frame"))
	return w
end

T.section("align_window: nothing to line up")
do
	local W = world()
	T.eq(W.A.open(), nil)
	T.eq(W.notes[1], "Alignment: Start a script that has alignment first")
end

T.section("align_window: the window and its rows")
do
	local W = world()
	local a = adapter()
	local w = open(W, a)
	T.eq(W.shown.sub, "Test Sword")
	T.eq(a.focusSeen[1], 1, "the script is told which tab is showing")
	T.eq(W.sections[1].text, "Sword", "the adapter names its option section")
	T.eq(#W.actions, 2, "two button rows")
	T.eq(W.actions[1].text, "Equip / Unequip")
	T.eq(W.actions[1].icon, "sword")
	T.eq(W.actions[2].icon, "repeat", "a button without an icon gets the default one")
	T.eq(#W.toggles, 1, "one toggle row, an option the script does not report is not drawn")
	T.eq(W.toggles[1].title, "Shiny")
	local part = W.choices[1]
	T.eq(part.title, "What to line up")
	T.eq(#part.options, 3)
	part.set(3)
	T.eq(a.tab, 3, "switching the tab tells the script")
	T.eq(a.focusSeen[#a.focusSeen], 3)
	local rows = {}
	for _, c in ipairs(W.A.ui and {} or {}) do rows[#rows + 1] = c end
	local ui = W.A.ui
	T.ok(ui ~= nil, "the window state exists")
	for k = 1, 3 do
		T.eq(ui.rows[k].row.Visible, false, "row " .. k .. " is hidden on the Base tab")
	end
	for k = 4, 6 do
		T.eq(ui.rows[k].row.Visible, true, "row " .. k .. " stays on the Base tab")
	end
	T.eq(ui.rows[4].box.Text, "7.0", "values are still painted")
	part.set(1)
	for k = 1, 6 do
		T.eq(ui.rows[k].row.Visible, true, "row " .. k .. " is back on the Hand tab")
	end
end

T.section("align_window: button rows, undo and failures")
do
	local W = world()
	local a = adapter()
	open(W, a)
	local ui = W.A.ui
	local roll = W.actions[2]
	T.eq(#W.A.undo, 0)
	roll.fn()
	T.eq(a.calls[1], "roll:true", "the button reaches setOpt with true")
	T.eq(a.data[1][4], 190, "the script changed the value")
	T.eq(#W.A.undo, 1, "a button that changed values can be undone")
	T.eq(W.A.undo[1][1], 1)
	T.eq(W.A.undo[1][2][4], 10, "the undo entry holds the value from before")
	local undoRow = W.buttonRows[1]
	T.eq(undoRow.list[2][2], "Undo")
	undoRow.list[2][3]()
	T.eq(a.data[1][4], 10, "undo puts it back")
	T.eq(#W.A.undo, 0)
	W.actions[1].fn()
	T.eq(a.calls[#a.calls], "equip:true")
	T.eq(#W.A.undo, 0, "a button that changed nothing leaves no undo entry")
	a.setOpt = function(name)
		error("it broke")
	end
	W.actions[1].fn()
	T.ok(string.find(ui.status.Text, "That didn't work", 1, true) ~= nil, "a failing button says so")
	T.eq(#W.A.undo, 0)
end

T.section("align_window: undo goes back to the tab the change was on")
do
	local W = world()
	local a = adapter()
	open(W, a)
	W.actions[2].fn()
	T.eq(#W.A.undo, 1)
	W.choices[1].set(2)
	T.eq(a.tab, 2)
	W.buttonRows[1].list[2][3]()
	T.eq(a.tab, 1, "the script is told it is the first tab again")
	T.eq(W.A.cur, 1)
	T.eq(a.calls[#a.calls], "put1")
end

T.section("align_window: rows that are empty or broken show everything")
do
	local W = world()
	local a = adapter({ rows = function() return {} end })
	open(W, a)
	W.choices[1].set(3)
	for k = 1, 6 do
		T.eq(W.A.ui.rows[k].row.Visible, true, "an empty list shows row " .. k)
	end
	local W2 = world()
	local b = adapter({ rows = function() error("rows broke") end })
	open(W2, b)
	W2.choices[1].set(3)
	for k = 1, 6 do
		T.eq(W2.A.ui.rows[k].row.Visible, true, "a failing rows shows row " .. k)
	end
	local W3 = world()
	local c = adapter({ rows = NIL })
	open(W3, c)
	W3.choices[1].set(3)
	for k = 1, 6 do
		T.eq(W3.A.ui.rows[k].row.Visible, true, "no rows function shows row " .. k)
	end
end

T.section("align_window: toggles say saved only when they are")
do
	local W = world()
	local a = adapter()
	open(W, a)
	local ui = W.A.ui
	W.toggles[1].set(true)
	T.eq(a.shiny, true)
	T.eq(ui.status.Text, "Shiny on", "no saved note when the script does not save it")
	local W2 = world()
	local b = adapter({ optsSaved = NIL })
	open(W2, b)
	W2.toggles[1].set(true)
	T.eq(W2.A.ui.status.Text, "Shiny on (saved)", "the old wording stays for scripts that save it")
	local W3 = world()
	local c = adapter({ optTitle = NIL, speeds = { 1, 2 }, speedTitle = "Spin rate", setSpeed = function() end })
	c.opts = function()
		return { shiny = false, speed = 1 }
	end
	open(W3, c)
	T.eq(W3.sections[1].text, "Options", "the default section title")
	local found = false
	for _, ch in ipairs(W3.choices) do
		if ch.title == "Spin rate" then
			found = true
		end
	end
	T.ok(found, "the speed row uses the adapter's own title")
	local W4 = world()
	local d = adapter({ speeds = { 1, 2 }, setSpeed = function() end, speedTitle = NIL, optTitle = NIL })
	d.opts = function()
		return { shiny = false, speed = 1 }
	end
	open(W4, d)
	local plain = false
	for _, ch in ipairs(W4.choices) do
		if ch.title == "Spin speed" then
			plain = true
		end
	end
	T.ok(plain, "the speed row keeps the old default title")
end

T.section("align_window: a press inside the window reaches the script")
do
	local W = world()
	local a = adapter()
	local w = open(W, a)
	w.frame.InputBegan:Fire({ UserInputType = "M1" })
	T.eq(a.pressed, 1, "a mouse press")
	w.frame.InputBegan:Fire({ UserInputType = "TOUCH" })
	T.eq(a.pressed, 2, "a touch")
	w.frame.InputBegan:Fire({ UserInputType = "Keyboard" })
	T.eq(a.pressed, 2, "a key does not count")
	local W2 = world()
	local b = adapter({ press = NIL })
	local w2 = open(W2, b)
	w2.frame.InputBegan:Fire({ UserInputType = "M1" })
	T.eq(b.pressed, nil, "a script without press is fine")
end

T.section("align_window: copy only copies the rows that count")
do
	local W = world()
	local a = adapter()
	open(W, a)
	local copyBtn = W.buttonRows[2].list[2]
	T.eq(copyBtn[2], "Copy")
	copyBtn[3]()
	T.eq(W.copies[1], "Hand: move 1, 2, 3 / turn 10.0, 20.0, 30.0")
	W.choices[1].set(3)
	copyBtn[3]()
	T.eq(W.copies[2], "Base: turn 7.0, 8.0, 9.0", "the Base tab has no move rows to copy")
end

T.section("align_window: the script stopping closes the window")
do
	local W = world()
	local a = adapter()
	open(W, a)
	a.watcher("stop")
	T.eq(W.open, false, "the window is closed")
	T.eq(W.notes[#W.notes], "Alignment: Closed, the script stopped")
	T.eq(a.watcher, nil, "the watcher is removed when the window closes")
	T.eq(a.open, false)
end

T.section("align_window: other watch events")
do
	local W = world()
	local a = adapter()
	open(W, a)
	W.A.undo = { { 1, { 1, 2, 3, 4, 5, 6 } } }
	a.watcher("gun")
	T.eq(#W.A.undo, 1, "a change event without a gun name keeps the undo list")
	function a.gun()
		return "Other Sword"
	end
	a.watcher("gun")
	T.eq(#W.A.undo, 0, "a gun change clears undo")
	T.ok(string.find(W.A.ui.status.Text, "Other Sword", 1, true) ~= nil, "and says which gun it is now")
end

T.section("align_window: a script can offer a choice, like Book Reader's book hand")
do
	local W = world()
	local a = adapter({ optList = { { "hand", "Book hand", "choice", { { "right", "Right" }, { "left", "Left" } } } } })
	a.hand = "right"
	function a.opts()
		return { hand = a.hand }
	end
	function a.setOpt(name, v)
		a.calls[#a.calls + 1] = name .. ":" .. tostring(v)
		if name == "hand" then
			a.hand = v
		end
	end
	open(W, a)
	local c = nil
	for _, x in ipairs(W.choices) do
		if x.title == "Book hand" then
			c = x
		end
	end
	T.ok(c ~= nil, "the choice is drawn")
	T.same(c and c.options, { { "right", "Right" }, { "left", "Left" } }, "with its two sides")
	T.eq(c and c.get(), "right", "showing the side in use")
	T.eq(#W.toggles, 0, "a choice is not drawn as a switch")
	c.set("left")
	T.eq(a.hand, "left", "tapping Left tells the script")
	T.eq(a.calls[#a.calls], "hand:left")
	T.eq(c.get(), "left")
	local status = W.notesList[#W.notesList]
	T.ok(status and string.find(status.Text, "Book hand: Left", 1, true) ~= nil, "and the window says what changed: " .. tostring(status and status.Text))
end
