local G = {}

local Signal = {}
Signal.__index = Signal

function Signal.new()
	return setmetatable({ list = {} }, Signal)
end

function Signal:Connect(fn)
	local conn = { fn = fn, on = true }
	function conn:Disconnect()
		self.on = false
	end
	self.list[#self.list + 1] = conn
	return conn
end

function Signal:Fire(...)
	for _, c in ipairs(self.list) do
		if c.on then
			c.fn(...)
		end
	end
end

function Signal:Count()
	local n = 0
	for _, c in ipairs(self.list) do
		if c.on then
			n = n + 1
		end
	end
	return n
end

G.Signal = Signal

local PARENT_OF = {
	Frame = "GuiObject",
	CanvasGroup = "GuiObject",
	ScrollingFrame = "GuiObject",
	ImageLabel = "GuiObject",
	TextLabel = "GuiObject",
	TextBox = "GuiObject",
	TextButton = "GuiButton",
	ImageButton = "GuiButton",
	GuiButton = "GuiObject",
	GuiObject = "Instance",
	UIListLayout = "UILayout",
	UIGridLayout = "UILayout",
	UILayout = "Instance",
	UICorner = "Instance",
	UIStroke = "Instance",
	UIPadding = "Instance",
	UIScale = "Instance",
	UIGradient = "Instance",
	ScreenGui = "Instance",
}

local EVENTS = {
	Activated = true,
	InputBegan = true,
	InputEnded = true,
	InputChanged = true,
	MouseEnter = true,
	MouseLeave = true,
	Completed = true,
}

local UDim = {}
UDim.__index = UDim
function UDim.new(s, o)
	return setmetatable({ Scale = s or 0, Offset = o or 0 }, UDim)
end

local UDim2 = {}
UDim2.__index = UDim2
UDim2.__add = function(a, b)
	return UDim2.new(a.X.Scale + b.X.Scale, a.X.Offset + b.X.Offset, a.Y.Scale + b.Y.Scale, a.Y.Offset + b.Y.Offset)
end
function UDim2.new(xs, xo, ys, yo)
	return setmetatable({ X = UDim.new(xs, xo), Y = UDim.new(ys, yo) }, UDim2)
end
function UDim2.fromOffset(x, y)
	return UDim2.new(0, x, 0, y)
end
function UDim2.fromScale(x, y)
	return UDim2.new(x, 0, y, 0)
end

local Vector2 = {}
Vector2.__index = Vector2
function Vector2.new(x, y)
	return setmetatable({ X = x or 0, Y = y or 0 }, Vector2)
end

local Vector3 = {}
Vector3.__index = Vector3
function Vector3.new(x, y, z)
	return setmetatable({ X = x or 0, Y = y or 0, Z = z or 0 }, Vector3)
end
Vector3.zero = Vector3.new(0, 0, 0)
Vector3.one = Vector3.new(1, 1, 1)
Vector3.xAxis = Vector3.new(1, 0, 0)
Vector3.yAxis = Vector3.new(0, 1, 0)
Vector3.zAxis = Vector3.new(0, 0, 1)

local CFrame = {}
CFrame.__index = CFrame
function CFrame.new(...)
	local args = { ... }
	if #args == 0 then
		return setmetatable({ Position = Vector3.zero, Rotation = Vector3.zero }, CFrame)
	end
	return setmetatable({ Position = Vector3.zero, Rotation = Vector3.zero }, CFrame)
end
CFrame.identity = CFrame.new()
CFrame.fromMatrix = function(pos, right, up, back)
	return CFrame.new()
end
CFrame.Angles = function()
	return CFrame.new()
end
CFrame.lookAt = function()
	return CFrame.new()
end

local Color3 = {}
Color3.__index = Color3
function Color3.new(r, g, b)
	return setmetatable({ R = r or 0, G = g or 0, B = b or 0 }, Color3)
end

local function enumTable()
	return setmetatable({}, {
		__index = function(t, k)
			local sub = setmetatable({}, {
				__index = function(_, v)
					return k .. "." .. v
				end,
			})
			rawset(t, k, sub)
			return sub
		end,
	})
end

local function isA(class, want)
	local c = class
	while c do
		if c == want then
			return true
		end
		c = PARENT_OF[c]
	end
	return false
end

local Inst = {}

local function detach(o)
	local p = rawget(o, "_parent")
	if p then
		for i, ch in ipairs(p._kids) do
			if ch == o then
				table.remove(p._kids, i)
				break
			end
		end
	end
	rawset(o, "_parent", nil)
end

Inst.__index = function(t, k)
	if k == "Parent" then
		return rawget(t, "_parent")
	end
	if EVENTS[k] then
		local s = Signal.new()
		rawset(t, k, s)
		return s
	end
	return Inst[k]
end

Inst.__newindex = function(t, k, v)
	if k == "Parent" then
		detach(t)
		if v ~= nil then
			rawset(t, "_parent", v)
			v._kids[#v._kids + 1] = t
		end
		return
	end
	rawset(t, k, v)
end

function Inst.IsA(self, class)
	return isA(self.ClassName, class)
end

function Inst.GetChildren(self)
	local out = {}
	for i, ch in ipairs(self._kids) do
		out[i] = ch
	end
	return out
end

function Inst.GetDescendants(self)
	local out = {}
	local function walk(o)
		for _, ch in ipairs(o._kids) do
			out[#out + 1] = ch
			walk(ch)
		end
	end
	walk(self)
	return out
end

function Inst.FindFirstChild(self, name, recursive)
	for _, ch in ipairs(self._kids) do
		if ch.Name == name then
			return ch
		end
	end
	if recursive then
		for _, ch in ipairs(self._kids) do
			local found = ch:FindFirstChild(name, true)
			if found then
				return found
			end
		end
	end
	return nil
end

function Inst.FindFirstChildOfClass(self, class)
	for _, ch in ipairs(self._kids) do
		if ch.ClassName == class then
			return ch
		end
	end
	return nil
end

function Inst.Destroy(self)
	for _, ch in ipairs(self:GetChildren()) do
		ch:Destroy()
	end
	detach(self)
	rawset(self, "Destroyed", true)
end

function Inst.GetPropertyChangedSignal(self, prop)
	local store = rawget(self, "_propSignals")
	if not store then
		store = {}
		rawset(self, "_propSignals", store)
	end
	local sig = store[prop]
	if not sig then
		sig = Signal.new()
		store[prop] = sig
	end
	return sig
end

function Inst.TestResize(self, x, y)
	self.AbsoluteSize = Vector2.new(x, y)
	self:GetPropertyChangedSignal("AbsoluteSize"):Fire()
end

local DEFAULTS = {
	Name = nil,
}

local function newInstance(class)
	local o = setmetatable({ ClassName = class, Name = class, _kids = {} }, Inst)
	if isA(class, "GuiObject") then
		o.Visible = true
		o.ZIndex = 1
		o.LayoutOrder = 0
		o.Position = UDim2.new(0, 0, 0, 0)
		o.Size = UDim2.new(0, 0, 0, 0)
		o.AnchorPoint = Vector2.new(0, 0)
		o.BackgroundTransparency = 0
		o.BackgroundColor3 = Color3.new(1, 1, 1)
		o.AutomaticSize = "AutomaticSize.None"
		o.AbsoluteSize = Vector2.new(0, 0)
		o.Rotation = 0
		o.ClipsDescendants = false
	end
	if class == "CanvasGroup" then
		o.GroupTransparency = 0
	end
	if class == "TextLabel" or class == "TextButton" or class == "TextBox" then
		o.Text = ""
		o.TextSize = 14
		o.TextTransparency = 0
	end
	if class == "ImageLabel" or class == "ImageButton" then
		o.Image = ""
		o.ImageTransparency = 0
	end
	if class == "UIListLayout" then
		o.Padding = UDim.new(0, 0)
		o.AbsoluteContentSize = Vector2.new(0, 0)
	end
	if class == "UIGridLayout" then
		o.CellSize = UDim2.new(0, 100, 0, 100)
		o.CellPadding = UDim2.new(0, 5, 0, 5)
	end
	if class == "UIPadding" then
		o.PaddingLeft, o.PaddingRight, o.PaddingTop, o.PaddingBottom = UDim.new(0, 0), UDim.new(0, 0), UDim.new(0, 0),
UDim.new(0, 0)
	end
	if class == "UIStroke" then
		o.Transparency = 0
		o.Thickness = 1
	end
	if class == "UICorner" then
		o.CornerRadius = UDim.new(0, 0)
	end
	if class == "UIScale" then
		o.Scale = 1
	end
	return o
end

function G.install(opts)
	opts = opts or {}
	_G.UDim = UDim
	_G.UDim2 = UDim2
	_G.Vector2 = Vector2
	_G.Vector3 = Vector3
	_G.CFrame = CFrame
	_G.Color3 = Color3
	_G.Enum = enumTable()
	_G.NumberSequenceKeypoint = {
		new = function(t, v)
			return { Time = t, Value = v }
		end,
	}
	_G.NumberSequence = {
		new = function(list)
			return { Keypoints = list }
		end,
	}
	_G.Instance = {
		new = function(class)
			return newInstance(class)
		end,
	}

	_G.workspace = { DistributedGameTime = 125 }
	_G.game = {
		GameId = 123,
		PlaceId = 456,
		JobId = "job-1",
		GetService = function(_, name)
			if name == "MarketplaceService" then
				return {
					GetProductInfo = function()
						return { Name = "Test Place", Creator = { Name = "Maker" } }
					end,
				}
			end
			return {}
		end,
	}

	local env = { logs = {}, saves = 0, notes = {}, copies = {}, windows = {}, calls = {} }

	local S = {
		animations = opts.animations ~= false,
		animSpeed = 1,
		opacity = 0,
		homeWidgets = {},
		homeDensity = "comfortable",
		homeCollapsed = {},
		recent = {},
		quickCmds = {},
		clock24 = false,
		smartStop = true,
		layout = "original",
	}
	local T = {}
	for _, k in ipairs({ "panel", "stroke", "card", "card2", "dim", "sub", "text", "ink", "red", "green", "blue",
"violet", "yellow", "side", "tabSel", "tabBg" }) do
		T[k] = Color3.new(0.5, 0.5, 0.5)
	end
	local L = { scale = 1, W = 1280, H = 720 }

	local Bus = { map = {} }
	function Bus.on(name, f)
		Bus.map[name] = Bus.map[name] or {}
		table.insert(Bus.map[name], f)
	end
	function Bus.off(name, f)
		local l = Bus.map[name]
		if not l then
			return
		end
		for i = #l, 1, -1 do
			if l[i] == f then
				table.remove(l, i)
			end
		end
	end
	function Bus.fire(name, ...)
		for _, f in ipairs(Bus.map[name] or {}) do
			f(...)
		end
	end
	function Bus.count(name)
		return #(Bus.map[name] or {})
	end

	local playing = setmetatable({}, { __mode = "k" })
	local UI = {}
	function UI.new(class, props, parent)
		local o = newInstance(class)
		if props then
			for k, v in pairs(props) do
				o[k] = v
			end
		end
		if parent then
			o.Parent = parent
		end
		return o
	end
	function UI.corner(o, r)
		return UI.new("UICorner", { CornerRadius = UDim.new(0, r) }, o)
	end
	function UI.stroke(o, color, thickness, transparency)
		return UI.new("UIStroke", { Color = color, Thickness = thickness or 1, Transparency = transparency or 0 }, o)
	end
	function UI.pad(o, l, r, t, b)
		return UI.new("UIPadding", { PaddingLeft = UDim.new(0, l), PaddingRight = UDim.new(0, r), PaddingTop = UDim.new(0,
t), PaddingBottom = UDim.new(0, b) }, o)
	end
	function UI.list(o, gap, dir, halign)
		return UI.new("UIListLayout", { Padding = UDim.new(0, gap or 6), FillDirection = dir, HorizontalAlignment = halign
}, o)
	end
	function UI.label(parent, props)
		local o = UI.new("TextLabel", { BackgroundTransparency = 1, TextSize = 13, Text = "" })
		for k, v in pairs(props) do
			o[k] = v
		end
		o.Parent = parent
		return o
	end
	function UI.button(parent, props)
		local o = UI.new("TextButton", { Text = "", BackgroundColor3 = T.card })
		for k, v in pairs(props) do
			o[k] = v
		end
		o.Parent = parent
		return o
	end
	function UI.icon(name, size, color, parent, props)
		local img = UI.new("ImageLabel", { Name = "Icon", Size = UDim2.fromOffset(size, size), ImageColor3 = color, IconName
= name })
		if props then
			for k, v in pairs(props) do
				img[k] = v
			end
		end
		img.Parent = parent
		return img
	end
	function UI.setIcon(img, name)
		img.IconName = name
	end
	function UI.tint(img, color)
		img.ImageColor3 = color
	end
	function UI.pressable(btn)
		return UI.new("UIScale", {}, btn)
	end
	function UI.onHover(btn, f)
		btn.HoverFn = f
	end
	function UI.accent(o, prop)
		o[prop] = Color3.new(0.1, 0.2, 0.3)
		return o
	end
	function UI.tween(o, t, props)
		if not S.animations or not t or t <= 0 then
			for k, v in pairs(props) do
				o[k] = v
			end
			return nil
		end
		local reg = playing[o]
		if not reg then
			reg = {}
			playing[o] = reg
		end
		local tw = { Completed = Signal.new(), cancelled = false }
		function tw:Cancel()
			self.cancelled = true
		end
		for k in pairs(props) do
			if reg[k] then
				reg[k].cancelled = true
			end
			reg[k] = tw
		end
		env.tweens = (env.tweens or 0) + 1
		task.delay(t / S.animSpeed, function()
			if tw.cancelled then
				return
			end
			for k, v in pairs(props) do
				o[k] = v
				if reg[k] == tw then
					reg[k] = nil
				end
			end
			tw.Completed:Fire("PlaybackState.Completed")
		end)
		return tw
	end
	function UI.done(tw, f)
		if tw then
			tw.Completed:Connect(function(st)
				if st == "PlaybackState.Completed" then
					f()
				end
			end)
		else
			f()
		end
	end

	local Ctl = {}
	function Ctl.hoverable(row)
		UI.pressable(row)
		row.Hoverable = true
	end
	function Ctl.note(parent, order, text)
		return UI.new("TextLabel", { LayoutOrder = order, Text = text or "", TextSize = 10, TextColor3 = T.dim, TextWrapped = true, TextYAlignment = Enum.TextYAlignment.Top, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y }, parent)
	end
	function Ctl.toggle(parent, order, title, desc, get, set)
		local row = UI.new("Frame", { LayoutOrder = order, Title = title }, parent)
		return { row = row, render = function() end, get = get, set = set }
	end
	function Ctl.choice(parent, order, title, options, get, set)
		local row = UI.new("Frame", { LayoutOrder = order, Title = title }, parent)
		env.choices = env.choices or {}
		env.choices[title] = { options = options, get = get, set = set }
		return { row = row, render = function() end }
	end
	function Ctl.buttons(parent, order, list)
		local row = UI.new("Frame", { LayoutOrder = order }, parent)
		env.buttonLists = env.buttonLists or {}
		env.buttonLists[#env.buttonLists + 1] = list
		return row
	end
	function Ctl.action(parent, order, text, icon, danger, fn)
		local row = UI.new("Frame", { LayoutOrder = order, Title = text }, parent)
		env.actions = env.actions or {}
		env.actions[text] = fn
		return row
	end
	function Ctl.input(parent, order, title)
		return UI.new("Frame", { LayoutOrder = order, Title = title }, parent)
	end

	local Tools = { frame = UI.new("Frame", { Name = "Tools" }) }
	function Tools.chip(parent, icon, text, order)
		local f = UI.new("Frame", { Name = "Chip", LayoutOrder = order }, parent)
		local l = UI.label(f, { Text = text })
		local function set(txt)
			l.Text = txt
		end
		return set, f, l
	end

	local Win = { open = {} }
	function Win.show(id, def)
		env.windows[#env.windows + 1] = { id = id, def = def }
		local w = { alive = true }
		local body = UI.new("Frame", { Name = "WinBody" })
		if def.build then
			def.build(w, body)
		end
		env.lastWindow = { id = id, w = w, body = body }
		return w
	end
	function Win.close()
	end

	local Panel = { open = true, page = "home", mode = "bar" }
	function Panel.nav(id)
		env.calls[#env.calls + 1] = "nav:" .. id
	end
	function Panel.go(id)
		env.calls[#env.calls + 1] = "go:" .. id
	end

	local Shell = { narrow = false, stage = { x = 12, y = 84, w = 1000, h = 400 }, leftW = 390, rightW = 330, mode =
"original" }

	local Runner = { pending = {}, running = {} }
	function Runner.count()
		local n = 0
		for _ in pairs(Runner.running) do
			n = n + 1
		end
		return n
	end
	function Runner.isRunning(path)
		return Runner.running[path] == true
	end
	function Runner.stop(path)
		Runner.running[path] = nil
		env.calls[#env.calls + 1] = "stop:" .. path
	end
	function Runner.run(e)
		env.calls[#env.calls + 1] = "run:" .. e.path
	end
	function Runner.stopAll()
		Runner.running = {}
		env.calls[#env.calls + 1] = "stopAll"
	end

	local Repo = { byPath = {} }
	function Repo.visible(e)
		return e ~= nil and e.hidden ~= true
	end

	local Detail = {}
	function Detail.open(e)
		env.calls[#env.calls + 1] = "detail:" .. e.path
	end

	local Log = { items = {} }
	function Log.add(kind, src, msg)
		Log.items[#Log.items + 1] = { kind = kind, src = src, msg = msg }
	end

	local Util = {}
	function Util.shortTime(h24)
		return h24 and "13:05" or "1:05 PM"
	end
	function Util.trim(s)
		return (string.gsub(string.gsub(s, "^%s+", ""), "%s+$", ""))
	end

	local Net = {}
	function Net.get(url)
		if opts.net then
			return opts.net(url)
		end
		return false, "offline"
	end

	local Core = {
		VTAG = "v",
		QUICK_DEFAULT = { "fly", "noclip", "infjump", "fullbright" },
		myPicTargets = {},
		IMG_DIR = "AtsukoHub/images",
		FONT_B = "FONT_B",
		FONT_M = "FONT_M",
		mods = {},
	}
	function Core.loadModule(name)
		local slot = Core.mods[name]
		if slot then
			return slot
		end
		local mod = loadmodule("Hub/modules/" .. name .. ".lua")
		if type(mod.init) == "function" then
			mod.init(Core.ctx)
		end
		Core.mods[name] = mod
		return mod
	end
	function Core.imageSource(src)
		if src == "12345" then
			return "rbxassetid://12345"
		end
		return nil
	end
	function Core.confirmTap(setText, normalText, action)
		return function()
			action()
		end
	end
	function Core.rejoin()
		env.calls[#env.calls + 1] = "rejoin"
	end

	local function newScroll(parent)
		local sf = UI.new("ScrollingFrame", { Size = UDim2.new(1, 0, 1, 0) }, parent)
		UI.list(sf, 6)
		UI.pad(sf, 0, 0, 0, 10)
		return sf
	end

	local rootFrame = UI.new("Frame", { Name = "Root" })
	local side = UI.new("Frame", { Name = "SideCard" })
	local Home = { frame = UI.new("Frame", { Name = "Body" }, rootFrame) }
	Home.scrollA = newScroll(Home.frame)
	Home.scrollA.Name = "ColA"
	Home.scrollB = newScroll(side)
	Home.scrollB.Name = "ColB"
	Home.executor = "unknown"

	local NP = { views = {} }
	function NP.active()
		return NP.on == true
	end
	function NP.art(parent)
		local fr = UI.new("Frame", {}, parent)
		return { frame = fr }
	end
	function NP.button(parent)
		local b = UI.button(parent, {})
		return b, UI.new("ImageLabel", {})
	end
	function NP.bar(parent, v)
		v.fill = UI.new("Frame", {})
		return UI.new("Frame", {}, parent)
	end
	function NP.add(v)
		NP.views[#NP.views + 1] = v
	end
	function NP.toggle()
		env.calls[#env.calls + 1] = "np:toggle"
	end
	function NP.next()
		env.calls[#env.calls + 1] = "np:next"
	end

	local Cmd = { list = {}, by = {}, state = {} }
	local function addCmd(id, name, icon)
		local def = { id = id, name = name, icon = icon, kind = "toggle" }
		Cmd.list[#Cmd.list + 1] = def
		Cmd.by[id] = def
	end
	addCmd("fly", "Fly", "plane")
	addCmd("noclip", "Noclip", "ghost")
	addCmd("infjump", "Infinite jump", "arrow-up")
	addCmd("fullbright", "Fullbright", "sun")
	addCmd("esp", "ESP", "eye")
	function Cmd.isOn(id)
		return Cmd.state[id] == true
	end
	function Cmd.toggle(id)
		Cmd.state[id] = not Cmd.state[id]
		Bus.fire("cmd", id)
	end
	function Cmd.run(name)
		env.calls[#env.calls + 1] = "cmd:" .. name
	end
	function Cmd.openBar()
		env.calls[#env.calls + 1] = "bar"
	end

	local function iconText(btn, icon, text, color, size)
		local lab = UI.label(btn, { Text = text })
		local ic = UI.new("ImageLabel", {}, btn)
		return function(newIcon, newText)
			lab.Text = newText
		end, ic, lab
	end

	local ctx = {
		Core = Core,
		UI = UI,
		T = T,
		S = S,
		L = L,
		Bus = Bus,
		Log = Log,
		Util = Util,
		Net = Net,
		X = { identifyexecutor = function()
			return "TestExec"
		end },
		HUB = { alive = true },
		Panel = Panel,
		Shell = Shell,
		Runner = Runner,
		Repo = Repo,
		Detail = Detail,
		Ctl = Ctl,
		Win = Win,
		Tools = Tools,
		Spot = { setImage = function(img, url)
			img.Image = url
		end },
		Home = Home,
		LP = {
			UserId = 1,
			DisplayName = "Tester",
			Name = "tester",
			AccountAge = 400,
			GetFriendsOnline = function()
				return opts.friends or {}
			end,
		},
		Players = {
			GetPlayers = function()
				return { 1, 2, 3 }
			end,
			MaxPlayers = 30,
		},
		SHARED = { hooked = true },
		HAS_FS = false,
		HUB_VERSION = "1.6.1",
		FONT_B = "FONT_B",
		iconText = iconText,
		section = function(parent, text, order)
			return UI.new("TextLabel", { Text = text, LayoutOrder = order }, parent)
		end,
		clearList = function(sf)
			for _, c in ipairs(sf:GetChildren()) do
				if c:IsA("GuiObject") then
					c:Destroy()
				end
			end
		end,
		notify = function(title, text)
			env.notes[#env.notes + 1] = title .. ":" .. text
		end,
		copyText = function(text, what)
			env.copies[#env.copies + 1] = what
		end,
		saveSettings = function()
			env.saves = env.saves + 1
		end,
		textWidth = function(text, size)
			return #text * size * 0.5
		end,
		accentColor = function()
			return Color3.new(0.1, 0.2, 0.3)
		end,
		jsonEncode = function(v)
			local function enc(x)
				if type(x) ~= "table" then
					return tostring(x)
				end
				local keys = {}
				for k in pairs(x) do
					keys[#keys + 1] = tostring(k)
				end
				table.sort(keys)
				local parts = {}
				for _, k in ipairs(keys) do
					parts[#parts + 1] = k .. "=" .. enc(x[k] ~= nil and x[k] or x[tonumber(k)])
				end
				return "{" .. table.concat(parts, ",") .. "}"
			end
			return enc(v)
		end,
		jsonDecode = function()
			return nil
		end,
		NP = NP,
		Player = { cur = nil },
		Cmd = Cmd,
	}
	Core.ctx = ctx
	env.ctx = ctx
	env.Home = Home
	env.Bus = Bus
	env.S = S
	env.Shell = Shell
	env.Log = Log
	env.Runner = Runner
	env.Repo = Repo
	env.Cmd = Cmd
	env.NP = NP
	env.Panel = Panel
	env.Core = Core
	env.advance = function(sec)
		task.wait(sec)
	end
	return env
end

return G