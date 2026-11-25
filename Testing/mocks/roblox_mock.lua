local Mock = {}

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

Mock.Signal = Signal

local EVENTS = {
	Activated = true,
	InputBegan = true,
	InputChanged = true,
	InputEnded = true,
	Completed = true,
	Changed = true,
	ChildAdded = true,
	Destroying = true,
}

local Inst = {}
Inst.__index = function(t, k)
	if EVENTS[k] then
		local s = Signal.new()
		rawset(t, k, s)
		return s
	end
	return Inst[k]
end

function Inst.Destroy(self)
	rawset(self, "Destroyed", true)
	rawset(self, "Parent", nil)
end

function Inst.IsA(self, c)
	return self.ClassName == c
end

function Inst.GetPropertyChangedSignal(self, name)
	local s = Signal.new()
	return s
end

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

function Mock.install(opts)
	opts = opts or {}
	local env = {}
	Instance = {
		new = function(class)
			local o = setmetatable({ ClassName = class, Name = class, Visible = true, ZIndex = 1, Position = UDim2.new(0, 0, 0, 0), Size = UDim2.new(0, 0, 0, 0), AnchorPoint = Vector2.new(0, 0) }, Inst)
			return o
		end,
	}
	_G.UDim2 = UDim2
	_G.UDim = UDim
	_G.Vector2 = Vector2
	_G.Enum = enumTable()
	_G.TweenInfo = {
		new = function(...)
			return { ... }
		end,
	}
	_G.Instance = Instance

	local S = { animations = opts.animations ~= false, animSpeed = 1, barPos = "top" }
	local T = { pillBg = "pillBg", stroke = "stroke", dim = "dim", sub = "sub", text = "text", card = "card" }
	local L = { W = 1280, H = 720, scale = 1 }
	local Root = Instance.new("Frame")
	local Pill = { frame = Instance.new("Frame") }
	Pill.frame.Size = UDim2.fromOffset(150, 26)
	Pill.frame.Position = UDim2.new(0.5, 0, 0, 10)
	Pill.frame.AnchorPoint = Vector2.new(0.5, 0)
	Pill.frame.ZIndex = 50
	Pill.frame.Parent = Root

	local clockBase = 0
	local playing = setmetatable({}, { __mode = "k" })
	local UI = {}

	function UI.new(class, props, parent)
		local o = Instance.new(class)
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

	function UI.label(parent, props)
		local o = UI.new("TextLabel", { Text = "", TextTransparency = 0 })
		for k, v in pairs(props) do
			o[k] = v
		end
		o.Parent = parent
		return o
	end

	function UI.button(parent, props)
		local o = UI.new("TextButton", { Text = "" })
		for k, v in pairs(props) do
			o[k] = v
		end
		o.Parent = parent
		return o
	end

	function UI.tween(o, t, props, style, dir)
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
		Mock.tweenCount = (Mock.tweenCount or 0) + 1
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

	local TweenService = {}
	function TweenService:Create(o, info, props)
		local tw = { Completed = Signal.new(), props = props, started = false }
		function tw:Play()
			self.started = true
		end
		function tw:Cancel()
			self.cancelled = true
		end
		Mock.looping = Mock.looping or {}
		Mock.looping[#Mock.looping + 1] = tw
		return tw
	end

	local TextService = {}
	function TextService:GetTextSize(text, size, font, bound)
		local w = #text * size * 0.5
		local lines = 1
		if bound.X < 10000 and w > bound.X then
			lines = math.ceil(w / bound.X)
		end
		return Vector2.new(math.min(w, bound.X), lines * (size + 2))
	end

	local UIS = { InputBegan = Signal.new(), InputChanged = Signal.new(), InputEnded = Signal.new() }

	local calls = {}
	local function rec(name)
		return function(...)
			calls[#calls + 1] = name
		end
	end

	local NP = { views = {}, track = true, key = "local:1", lyric = { cur = "first line", nxt = "second line", status = "synced" }, renders = 0 }
	function NP.hasTrack()
		return NP.track
	end
	function NP.info()
		return { has = NP.track, key = NP.key, title = "Song " .. NP.key, artist = "Artist", pos = 10, len = 100, playing = true, src = "local" }
	end
	function NP.srcOf()
		return "local"
	end
	function NP.liveSource()
		return "local"
	end
	function NP.art(parent)
		local fr = Instance.new("Frame")
		fr.Parent = parent
		return { frame = fr, bars = {} }
	end
	function NP.button(parent)
		local b = Instance.new("TextButton")
		b.Parent = parent
		local ic = Instance.new("ImageLabel")
		return b, ic
	end
	function NP.bar(parent, v)
		local track = Instance.new("Frame")
		track.Parent = parent
		v.fill = Instance.new("Frame")
		v.knob = Instance.new("Frame")
		return track
	end
	function NP.render(v)
		NP.renders = NP.renders + 1
		local i = NP.info()
		v.title.Text = i.title
		v.artist.Text = i.artist
		if v.extra then
			v.extra(i, "local")
		end
		if v.setLines then
			local lr = NP.lyric
			v.setLines(lr.cur, lr.nxt, lr.status == "synced", lr.res)
		end
	end
	function NP.add(v)
		NP.views[#NP.views + 1] = v
		NP.render(v)
		return v
	end
	NP.toggle = rec("toggle")
	NP.next = rec("next")
	NP.prev = rec("prev")
	NP.openMini = rec("openMini")

	local Panel = { go = rec("go"), setTab = rec("setTab") }
	local Spot = { live = function()
		return false
	end, lastPoll = 0, poll = rec("poll") }

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

	local Core = {}
	function Core.loadModule(name)
		return loadmodule("Hub/modules/" .. name .. ".lua")
	end

	local Island = { open = false }
	local ctx = {
		Core = Core,
		UI = UI,
		T = T,
		S = S,
		L = L,
		Bus = Bus,
		NP = NP,
		Pill = Pill,
		Panel = Panel,
		MP = {},
		Root = Root,
		Spot = Spot,
		Drag = { cur = nil },
		Island = Island,
		FONT_B = "FONT_B",
		FONT_M = "FONT_M",
		TextService = TextService,
		TweenService = TweenService,
		UserInputService = UIS,
		TOUCH = "UserInputType.Touch",
		MOUSE1 = "UserInputType.MouseButton1",
	}
	env.ctx = ctx
	env.calls = calls
	env.Signal = Signal
	env.advance = function(sec)
		task.wait(sec)
	end
	return env
end

return Mock
