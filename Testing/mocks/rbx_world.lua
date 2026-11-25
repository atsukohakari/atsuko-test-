local World = {}

local function round(n)
	return math.floor(n + 0.5)
end

function World.install(opts)
	opts = opts or {}
	local env = { missing = {}, warns = {}, files = {}, folders = {}, requests = {}, hooks = {}, badProps = {}, clipboard = nil, beats = 0 }
	local G = _G
	local genv = {}
	env.genv = genv

	local function note(kind, what)
		local key = kind .. ":" .. tostring(what)
		env.missing[key] = (env.missing[key] or 0) + 1
	end

	local rbxtypes = {}
	local function typeName(v)
		if type(v) == "table" then
			local mt = getmetatable(v)
			if mt and mt.__rbxtype then
				return mt.__rbxtype
			end
		end
		return type(v)
	end
	G.typeof = typeName

	local Signal = { __rbxtype = "RBXScriptSignal" }
	Signal.__index = Signal
	local Conn = { __rbxtype = "RBXScriptConnection" }
	Conn.__index = Conn

	function Conn.Disconnect(self)
		self.Connected = false
	end
	Conn.disconnect = Conn.Disconnect

	local function newSignal(name)
		return setmetatable({ name = name, list = {}, fires = 0, last = {} }, Signal)
	end

	function Signal.Connect(self, fn)
		if type(fn) ~= "function" then
			error("Attempt to connect failed: Passed value is not a function")
		end
		local conn = setmetatable({ Connected = true, fn = fn }, Conn)
		self.list[#self.list + 1] = conn
		return conn
	end
	Signal.connect = Signal.Connect
	Signal.ConnectParallel = Signal.Connect

	function Signal.Once(self, fn)
		local conn
		conn = self:Connect(function(...)
			conn:Disconnect()
			fn(...)
		end)
		return conn
	end

	function Signal.Fire(self, ...)
		self.fires = self.fires + 1
		self.last = { ... }
		local list = self.list
		local keep = {}
		for _, c in ipairs(list) do
			if c.Connected then
				keep[#keep + 1] = c
			end
		end
		self.list = keep
		for _, c in ipairs(keep) do
			if c.Connected then
				c.fn(...)
			end
		end
	end

	function Signal.Wait(self)
		local start = self.fires
		local guard = 0
		while self.fires == start and guard < 2000 do
			guard = guard + 1
			task.wait(0.03)
		end
		return table.unpack(self.last)
	end
	Signal.wait = Signal.Wait

	function Signal.Count(self)
		local n = 0
		for _, c in ipairs(self.list) do
			if c.Connected then
				n = n + 1
			end
		end
		return n
	end

	local function vec(name, comps)
		local V = { __rbxtype = name }
		local M = {}
		local function new(...)
			local a = { ... }
			local o = {}
			for i, c in ipairs(comps) do
				o[c] = tonumber(a[i]) or 0
			end
			return setmetatable(o, V)
		end
		V.__index = function(t, k)
			if k == "magnitude" then
				k = "Magnitude"
			elseif k == "unit" then
				k = "Unit"
			elseif k == "x" or k == "y" or k == "z" then
				local up = rawget(t, string.upper(k))
				if up ~= nil then
					return up
				end
			end
			if k == "Magnitude" then
				local s = 0
				for _, c in ipairs(comps) do
					s = s + t[c] * t[c]
				end
				return math.sqrt(s)
			end
			if k == "Unit" then
				local m = t.Magnitude
				if m == 0 then
					return new()
				end
				return t / m
			end
			return M[k]
		end
		local function zip(f)
			return function(a, b)
				local o = {}
				for _, c in ipairs(comps) do
					local x = type(a) == "number" and a or a[c]
					local y = type(b) == "number" and b or b[c]
					o[c] = f(x, y)
				end
				return setmetatable(o, V)
			end
		end
		V.__add = zip(function(x, y)
			return x + y
		end)
		V.__sub = zip(function(x, y)
			return x - y
		end)
		V.__mul = zip(function(x, y)
			return x * y
		end)
		V.__div = zip(function(x, y)
			return x / y
		end)
		V.__unm = function(a)
			local o = {}
			for _, c in ipairs(comps) do
				o[c] = -a[c]
			end
			return setmetatable(o, V)
		end
		V.__eq = function(a, b)
			for _, c in ipairs(comps) do
				if a[c] ~= b[c] then
					return false
				end
			end
			return true
		end
		V.__tostring = function(a)
			local parts = {}
			for i, c in ipairs(comps) do
				parts[i] = tostring(a[c])
			end
			return table.concat(parts, ", ")
		end
		function M.Lerp(a, b, t)
			return a + (b - a) * t
		end
		function M.Dot(a, b)
			local s = 0
			for _, c in ipairs(comps) do
				s = s + a[c] * b[c]
			end
			return s
		end
		function M.Cross(a, b)
			return new(a.Y * b.Z - a.Z * b.Y, a.Z * b.X - a.X * b.Z, a.X * b.Y - a.Y * b.X)
		end
		function M.Floor(a)
			local o = {}
			for _, c in ipairs(comps) do
				o[c] = math.floor(a[c])
			end
			return setmetatable(o, V)
		end
		function M.Abs(a)
			local o = {}
			for _, c in ipairs(comps) do
				o[c] = math.abs(a[c])
			end
			return setmetatable(o, V)
		end
		function M.Max(a, b)
			local o = {}
			for _, c in ipairs(comps) do
				o[c] = math.max(a[c], b[c])
			end
			return setmetatable(o, V)
		end
		function M.Min(a, b)
			local o = {}
			for _, c in ipairs(comps) do
				o[c] = math.min(a[c], b[c])
			end
			return setmetatable(o, V)
		end
		function M.FuzzyEq(a, b, e)
			return (a - b).Magnitude <= (e or 1e-5)
		end
		local lib = { new = new, zero = new(), one = new(1, 1, 1) }
		lib.xAxis, lib.yAxis, lib.zAxis = new(1, 0, 0), new(0, 1, 0), new(0, 0, 1)
		lib.one = (#comps == 2) and new(1, 1) or new(1, 1, 1)
		return lib
	end

	G.Vector2 = vec("Vector2", { "X", "Y" })
	G.Vector3 = vec("Vector3", { "X", "Y", "Z" })

	local UDim = { __rbxtype = "UDim" }
	UDim.__index = UDim
	local function udim(s, o)
		return setmetatable({ Scale = s or 0, Offset = o or 0 }, UDim)
	end
	UDim.__eq = function(a, b)
		return a.Scale == b.Scale and a.Offset == b.Offset
	end
	UDim.__add = function(a, b)
		return udim(a.Scale + b.Scale, a.Offset + b.Offset)
	end
	UDim.__sub = function(a, b)
		return udim(a.Scale - b.Scale, a.Offset - b.Offset)
	end
	G.UDim = { new = udim }

	local UDim2 = { __rbxtype = "UDim2" }
	UDim2.__index = UDim2
	local function udim2(xs, xo, ys, yo)
		return setmetatable({ X = udim(xs, xo), Y = udim(ys, yo), Width = udim(xs, xo), Height = udim(ys, yo) }, UDim2)
	end
	UDim2.__eq = function(a, b)
		return a.X == b.X and a.Y == b.Y
	end
	UDim2.__add = function(a, b)
		return udim2(a.X.Scale + b.X.Scale, a.X.Offset + b.X.Offset, a.Y.Scale + b.Y.Scale, a.Y.Offset + b.Y.Offset)
	end
	UDim2.__sub = function(a, b)
		return udim2(a.X.Scale - b.X.Scale, a.X.Offset - b.X.Offset, a.Y.Scale - b.Y.Scale, a.Y.Offset - b.Y.Offset)
	end
	UDim2.__tostring = function(a)
		return "{" .. a.X.Scale .. ", " .. a.X.Offset .. "}, {" .. a.Y.Scale .. ", " .. a.Y.Offset .. "}"
	end
	function UDim2.Lerp(a, b, t)
		return udim2(a.X.Scale + (b.X.Scale - a.X.Scale) * t, a.X.Offset + (b.X.Offset - a.X.Offset) * t, a.Y.Scale + (b.Y.Scale - a.Y.Scale) * t, a.Y.Offset + (b.Y.Offset - a.Y.Offset) * t)
	end
	G.UDim2 = {
		new = function(a, b, c, d)
			if type(a) == "table" then
				return udim2(a.Scale, a.Offset, b.Scale, b.Offset)
			end
			return udim2(a or 0, b or 0, c or 0, d or 0)
		end,
		fromOffset = function(x, y)
			return udim2(0, x or 0, 0, y or 0)
		end,
		fromScale = function(x, y)
			return udim2(x or 0, 0, y or 0, 0)
		end,
	}

	local Color3 = { __rbxtype = "Color3" }
	Color3.__index = function(t, k)
		return Color3[k]
	end
	local function color(r, g, b)
		return setmetatable({ R = r or 0, G = g or 0, B = b or 0 }, Color3)
	end
	Color3.__eq = function(a, b)
		return a.R == b.R and a.G == b.G and a.B == b.B
	end
	function Color3.Lerp(a, b, t)
		return color(a.R + (b.R - a.R) * t, a.G + (b.G - a.G) * t, a.B + (b.B - a.B) * t)
	end
	function Color3.ToHSV(a)
		return 0, 0, math.max(a.R, a.G, a.B)
	end
	function Color3.ToHex(a)
		return string.format("%02X%02X%02X", round(a.R * 255), round(a.G * 255), round(a.B * 255))
	end
	G.Color3 = {
		new = color,
		fromRGB = function(r, g, b)
			return color((r or 0) / 255, (g or 0) / 255, (b or 0) / 255)
		end,
		fromHSV = function(h, s, v)
			return color(v or 0, v or 0, v or 0)
		end,
		fromHex = function(h)
			local r, g, b = string.match(tostring(h), "(%x%x)(%x%x)(%x%x)")
			return color((tonumber(r, 16) or 0) / 255, (tonumber(g, 16) or 0) / 255, (tonumber(b, 16) or 0) / 255)
		end,
	}

	local CFrame = { __rbxtype = "CFrame" }
	CFrame.__index = function(t, k)
		if k == "X" or k == "x" then
			return t.Position.X
		elseif k == "Y" or k == "y" then
			return t.Position.Y
		elseif k == "Z" or k == "z" then
			return t.Position.Z
		elseif k == "p" then
			return t.Position
		elseif k == "LookVector" or k == "lookVector" then
			return G.Vector3.new(0, 0, -1)
		elseif k == "RightVector" or k == "rightVector" then
			return G.Vector3.new(1, 0, 0)
		elseif k == "UpVector" or k == "upVector" then
			return G.Vector3.new(0, 1, 0)
		elseif k == "Rotation" then
			return setmetatable({ Position = G.Vector3.new() }, CFrame)
		end
		return CFrame[k]
	end
	local function cframe(pos)
		return setmetatable({ Position = pos or G.Vector3.new() }, CFrame)
	end
	CFrame.__mul = function(a, b)
		if typeName(b) == "Vector3" then
			return a.Position + b
		end
		return cframe(a.Position + b.Position)
	end
	CFrame.__add = function(a, v)
		return cframe(a.Position + v)
	end
	CFrame.__sub = function(a, v)
		return cframe(a.Position - v)
	end
	CFrame.__eq = function(a, b)
		return a.Position == b.Position
	end
	function CFrame.Inverse(a)
		return cframe(-a.Position)
	end
	function CFrame.ToObjectSpace(a, b)
		return cframe(b.Position - a.Position)
	end
	function CFrame.ToWorldSpace(a, b)
		return cframe(a.Position + b.Position)
	end
	function CFrame.PointToWorldSpace(a, v)
		return a.Position + v
	end
	function CFrame.PointToObjectSpace(a, v)
		return v - a.Position
	end
	function CFrame.VectorToWorldSpace(a, v)
		return v
	end
	function CFrame.VectorToObjectSpace(a, v)
		return v
	end
	function CFrame.Lerp(a, b)
		return b
	end
	CFrame.lerp = CFrame.Lerp
	CFrame.inverse = CFrame.Inverse
	function CFrame.GetComponents(a)
		return a.Position.X, a.Position.Y, a.Position.Z, 1, 0, 0, 0, 1, 0, 0, 0, 1
	end
	CFrame.components = CFrame.GetComponents
	function CFrame.ToEulerAnglesXYZ()
		return 0, 0, 0
	end
	CFrame.ToOrientation = CFrame.ToEulerAnglesXYZ
	CFrame.ToEulerAnglesYXZ = CFrame.ToEulerAnglesXYZ
	G.CFrame = {
		new = function(a, b, c)
			if type(a) == "table" then
				return cframe(a)
			end
			return cframe(G.Vector3.new(a, b, c))
		end,
		Angles = function()
			return cframe()
		end,
		fromEulerAnglesXYZ = function()
			return cframe()
		end,
		fromOrientation = function()
			return cframe()
		end,
		lookAt = function(at)
			return cframe(at)
		end,
		fromMatrix = function(at)
			return cframe(at)
		end,
		identity = cframe(),
	}

	local function plain(name, fields)
		local mt = { __rbxtype = name }
		mt.__index = mt
		return function(...)
			local o = fields(...)
			return setmetatable(o, mt)
		end
	end
	G.Rect = { new = plain("Rect", function(a, b, c, d)
		return { Min = a, Max = b }
	end) }
	G.NumberRange = { new = plain("NumberRange", function(a, b)
		return { Min = a, Max = b or a }
	end) }
	G.NumberSequenceKeypoint = { new = plain("NumberSequenceKeypoint", function(t, v)
		return { Time = t, Value = v, Envelope = 0 }
	end) }
	G.NumberSequence = { new = plain("NumberSequence", function(a, b)
		local pts
		if type(a) == "table" then
			pts = a
		else
			pts = { { Time = 0, Value = a }, { Time = 1, Value = b or a } }
		end
		return { Keypoints = pts }
	end) }
	G.ColorSequenceKeypoint = { new = plain("ColorSequenceKeypoint", function(t, v)
		return { Time = t, Value = v }
	end) }
	G.ColorSequence = { new = plain("ColorSequence", function(a, b)
		local pts
		if type(a) == "table" and a.R == nil then
			pts = a
		else
			pts = { { Time = 0, Value = a }, { Time = 1, Value = b or a } }
		end
		return { Keypoints = pts }
	end) }
	G.TweenInfo = { new = plain("TweenInfo", function(t, style, dir, reps, rev, delay)
		return { Time = t or 1, EasingStyle = style, EasingDirection = dir, RepeatCount = reps or 0, Reverses = rev or false, DelayTime = delay or 0 }
	end) }
	G.BrickColor = {
		new = plain("BrickColor", function(n)
			return { Name = tostring(n), Color = color(0.5, 0.5, 0.5) }
		end),
		random = plain("BrickColor", function()
			return { Name = "Medium stone grey", Color = color(0.5, 0.5, 0.5) }
		end),
	}
	G.Font = {
		new = plain("Font", function(f, w, s)
			return { Family = f, Weight = w, Style = s }
		end),
		fromEnum = plain("Font", function(e)
			return { Family = tostring(e) }
		end),
	}
	G.RaycastParams = { new = plain("RaycastParams", function()
		return { FilterDescendantsInstances = {}, FilterType = "Exclude" }
	end) }
	G.OverlapParams = { new = plain("OverlapParams", function()
		return { FilterDescendantsInstances = {} }
	end) }
	G.Ray = { new = plain("Ray", function(o, d)
		return { Origin = o, Direction = d }
	end) }
	G.Region3 = { new = plain("Region3", function(a, b)
		return { Min = a, Max = b }
	end) }
	G.PhysicalProperties = { new = plain("PhysicalProperties", function()
		return {}
	end) }
	G.Axes = { new = plain("Axes", function()
		return {}
	end) }
	G.Faces = { new = plain("Faces", function()
		return {}
	end) }
	G.DateTime = {
		now = plain("DateTime", function()
			return { UnixTimestamp = os.time(), UnixTimestampMillis = os.time() * 1000 }
		end),
	}
	G.Random = { new = function(seed)
		local rng = setmetatable({}, { __rbxtype = "Random" })
		rng.NextNumber = function(self, a, b)
			if a == nil then
				return math.random()
			end
			return a + math.random() * ((b or 1) - a)
		end
		rng.NextInteger = function(self, a, b)
			return math.random(a, b)
		end
		rng.NextUnitVector = function()
			return G.Vector3.new(0, 1, 0)
		end
		rng.Shuffle = function() end
		rng.Clone = function(self)
			return self
		end
		return rng
	end }

	local enumCache = {}
	local EnumItem = { __rbxtype = "EnumItem" }
	EnumItem.__index = EnumItem
	EnumItem.__tostring = function(t)
		return "Enum." .. t.EnumType.Name .. "." .. t.Name
	end
	local function enumType(name)
		local et = enumCache[name]
		if et then
			return et
		end
		local items = {}
		et = setmetatable({ Name = name }, {
			__rbxtype = "Enum",
			__index = function(t, k)
				if k == "GetEnumItems" then
					return function()
						local out = {}
						for _, v in pairs(items) do
							out[#out + 1] = v
						end
						return out
					end
				end
				local item = items[k]
				if not item then
					item = setmetatable({ Name = k, Value = 0, EnumType = t }, EnumItem)
					local n = 0
					for _ in pairs(items) do
						n = n + 1
					end
					item.Value = n
					items[k] = item
				end
				return item
			end,
		})
		enumCache[name] = et
		return et
	end
	G.Enum = setmetatable({}, { __index = function(t, k)
		return enumType(k)
	end })

	local EVENTS = {}
	for _, n in ipairs({ "Activated", "MouseButton1Click", "MouseButton1Down", "MouseButton1Up", "MouseButton2Click", "MouseButton2Down", "MouseButton2Up", "MouseEnter", "MouseLeave", "MouseMoved", "MouseWheelForward", "MouseWheelBackward", "InputBegan", "InputChanged", "InputEnded", "FocusLost", "Focused", "ReturnPressedFromOnScreenKeyboard", "TouchTap", "TouchLongPress", "TouchPan", "TouchPinch", "TouchSwipe", "TouchRotate", "TouchStarted", "TouchMoved", "TouchEnded", "SelectionGained", "SelectionLost", "Changed", "ChildAdded", "ChildRemoved", "DescendantAdded", "DescendantRemoving", "AncestryChanged", "Destroying", "Completed", "Heartbeat", "RenderStepped", "Stepped", "PostSimulation", "PreSimulation", "PreRender", "PreAnimation", "PlayerAdded", "PlayerRemoving", "CharacterAdded", "CharacterRemoving", "CharacterAppearanceLoaded", "Chatted", "SendingMessage", "MessageReceived", "Died", "Seated", "Running", "Jumping", "StateChanged", "HealthChanged", "Touched", "Ended", "Played", "Paused", "Resumed", "Loaded", "DidLoop", "TextBoxFocused", "TextBoxFocusReleased", "LastInputTypeChanged", "WindowFocused", "WindowFocusReleased", "JumpRequest", "MenuOpened", "MenuClosed", "MessageOut", "TeleportInitFailed", "Triggered", "InputBegan", "DeviceOrientationChanged", "UserCFrameChanged", "GamepadConnected", "GamepadDisconnected", "ViewportSizeChanged", "SafeAreaChanged", "ItemChanged", "OnClientEvent", "OnServerEvent", "OnClientInvoke", "ChildrenChanged", "Error", "CoreGuiChangedSignal", "LocalPlayerChanged", "TextChanged", "Event" }) do
		EVENTS[n] = true
	end

	local CLASS_PARENT = {
		Frame = "GuiObject", TextLabel = "GuiObject", TextButton = "GuiButton", TextBox = "GuiObject", ImageLabel = "GuiObject",
		ImageButton = "GuiButton", ScrollingFrame = "GuiObject", ViewportFrame = "GuiObject", VideoFrame = "GuiObject", CanvasGroup = "GuiObject",
		GuiButton = "GuiObject", GuiObject = "GuiBase2d", ScreenGui = "LayerCollector", BillboardGui = "LayerCollector", SurfaceGui = "LayerCollector",
		LayerCollector = "GuiBase2d", GuiBase2d = "Instance", UIListLayout = "UILayout", UIGridLayout = "UILayout", UILayout = "UIComponent",
		UICorner = "UIComponent", UIStroke = "UIComponent", UIPadding = "UIComponent", UIScale = "UIComponent", UIGradient = "UIComponent",
		UISizeConstraint = "UIComponent", UIAspectRatioConstraint = "UIComponent", UITextSizeConstraint = "UIComponent", UIComponent = "Instance",
		Part = "BasePart", MeshPart = "BasePart", BasePart = "PVInstance", Model = "PVInstance", PVInstance = "Instance", Humanoid = "Instance",
		Sound = "Instance", Folder = "Instance", Tool = "Instance", Camera = "Instance", Workspace = "Instance", Player = "Instance",
		Motor6D = "JointInstance", Weld = "JointInstance", ManualWeld = "JointInstance", JointInstance = "Instance", WeldConstraint = "Instance",
		Accessory = "Accoutrement", Hat = "Accoutrement", Accoutrement = "Instance", SpecialMesh = "DataModelMesh", DataModelMesh = "Instance",
	}
	local function isA(class, want)
		local c = class
		local guard = 0
		while c and guard < 20 do
			if c == want then
				return true
			end
			c = CLASS_PARENT[c]
			guard = guard + 1
		end
		return want == "Instance"
	end

	local DEFAULTS = {}
	local function def(class, t)
		DEFAULTS[class] = t
	end
	local function guiDefaults()
		return { Visible = true, Size = G.UDim2.new(0, 0, 0, 0), Position = G.UDim2.new(0, 0, 0, 0), AnchorPoint = G.Vector2.new(0, 0), BackgroundTransparency = 0, BackgroundColor3 = G.Color3.new(1, 1, 1), BorderSizePixel = 1, ZIndex = 1, LayoutOrder = 0, ClipsDescendants = false, Active = false, Rotation = 0, AutomaticSize = G.Enum.AutomaticSize.None, SizeConstraint = G.Enum.SizeConstraint.RelativeXY }
	end
	local function textDefaults(t)
		t.Text = ""
		t.TextSize = 14
		t.TextColor3 = G.Color3.new(0, 0, 0)
		t.TextTransparency = 0
		t.TextWrapped = false
		t.RichText = false
		t.Font = G.Enum.Font.SourceSans
		t.TextXAlignment = G.Enum.TextXAlignment.Center
		t.TextYAlignment = G.Enum.TextYAlignment.Center
		return t
	end
	local function imageDefaults(t)
		t.Image = ""
		t.ImageTransparency = 0
		t.ImageColor3 = G.Color3.new(1, 1, 1)
		t.ScaleType = G.Enum.ScaleType.Stretch
		return t
	end

	local Inst = { __rbxtype = "Instance" }
	local services = {}
	local newInstance

	local function layoutSize(o)
		local parent = rawget(o, "_parent")
		local pw, ph = 0, 0
		if parent then
			local ps = parent.AbsoluteSize
			pw, ph = ps.X, ps.Y
		end
		local sz = o._p.Size
		if not sz then
			return G.Vector2.new(0, 0)
		end
		return G.Vector2.new(sz.X.Scale * pw + sz.X.Offset, sz.Y.Scale * ph + sz.Y.Offset)
	end

	local function layoutPos(o)
		local parent = rawget(o, "_parent")
		local px, py, pw, ph = 0, 0, 0, 0
		if parent then
			local pp, ps = parent.AbsolutePosition, parent.AbsoluteSize
			px, py, pw, ph = pp.X, pp.Y, ps.X, ps.Y
		end
		local pos = o._p.Position
		if not pos then
			return G.Vector2.new(px, py)
		end
		local size = o.AbsoluteSize
		local anchor = o._p.AnchorPoint or G.Vector2.new(0, 0)
		return G.Vector2.new(px + pos.X.Scale * pw + pos.X.Offset - anchor.X * size.X, py + pos.Y.Scale * ph + pos.Y.Offset - anchor.Y * size.Y)
	end

	local function fireChanged(o, k)
		local ps = rawget(o, "_psig")
		if ps and ps[k] then
			ps[k]:Fire()
		end
		local ch = rawget(o, "_sig")
		if ch and ch.Changed then
			ch.Changed:Fire(k)
		end
	end

	local function isDescendantOf(o, anc)
		local p = rawget(o, "_parent")
		local guard = 0
		while p and guard < 200 do
			if p == anc then
				return true
			end
			p = rawget(p, "_parent")
			guard = guard + 1
		end
		return false
	end

	local function sig(o, name)
		local s = rawget(o, "_sig")
		if not s then
			s = {}
			rawset(o, "_sig", s)
		end
		local x = s[name]
		if not x then
			x = newSignal(name)
			s[name] = x
		end
		return x
	end

	local function subtree(o)
		local out = { o }
		local function walk(x)
			for _, ch in ipairs(x._kids) do
				out[#out + 1] = ch
				walk(ch)
			end
		end
		walk(o)
		return out
	end
	local function setParent(o, v)
		local old = rawget(o, "_parent")
		if old == v then
			return
		end
		if old then
			local anc = old
			local guard = 0
			local gone = nil
			while anc and guard < 200 do
				local s = rawget(anc, "_sig")
				if s and s.DescendantRemoving then
					gone = gone or subtree(o)
					for _, d in ipairs(gone) do
						s.DescendantRemoving:Fire(d)
					end
				end
				anc = rawget(anc, "_parent")
				guard = guard + 1
			end
			for i, ch in ipairs(old._kids) do
				if ch == o then
					table.remove(old._kids, i)
					break
				end
			end
			sig(old, "ChildRemoved"):Fire(o)
		end
		rawset(o, "_parent", v)
		if v then
			v._kids[#v._kids + 1] = o
			sig(v, "ChildAdded"):Fire(o)
			local anc = v
			local guard = 0
			local added = nil
			while anc and guard < 200 do
				local s = rawget(anc, "_sig")
				if s and s.DescendantAdded then
					added = added or subtree(o)
					for _, d in ipairs(added) do
						s.DescendantAdded:Fire(d)
					end
				end
				anc = rawget(anc, "_parent")
				guard = guard + 1
			end
		end
		local s = rawget(o, "_sig")
		if s and s.AncestryChanged then
			s.AncestryChanged:Fire(o, v)
		end
		fireChanged(o, "Parent")
	end

	local methods = {}
	Inst.methods = methods

	function methods.IsA(self, c)
		return isA(self.ClassName, c)
	end
	function methods.GetChildren(self)
		local out = {}
		for i, ch in ipairs(self._kids) do
			out[i] = ch
		end
		return out
	end
	function methods.GetDescendants(self)
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
	function methods.FindFirstChild(self, name, recursive)
		for _, ch in ipairs(self._kids) do
			if ch.Name == name then
				return ch
			end
		end
		if recursive then
			for _, ch in ipairs(self._kids) do
				local f = ch:FindFirstChild(name, true)
				if f then
					return f
				end
			end
		end
		return nil
	end
	methods.findFirstChild = methods.FindFirstChild
	function methods.FindFirstChildOfClass(self, class)
		for _, ch in ipairs(self._kids) do
			if ch.ClassName == class then
				return ch
			end
		end
		return nil
	end
	function methods.FindFirstChildWhichIsA(self, class)
		for _, ch in ipairs(self._kids) do
			if isA(ch.ClassName, class) then
				return ch
			end
		end
		return nil
	end
	function methods.FindFirstAncestorOfClass(self, class)
		local p = rawget(self, "_parent")
		while p do
			if p.ClassName == class then
				return p
			end
			p = rawget(p, "_parent")
		end
		return nil
	end
	function methods.FindFirstAncestorWhichIsA(self, class)
		local p = rawget(self, "_parent")
		while p do
			if isA(p.ClassName, class) then
				return p
			end
			p = rawget(p, "_parent")
		end
		return nil
	end
	function methods.FindFirstAncestor(self, name)
		local p = rawget(self, "_parent")
		while p do
			if p.Name == name then
				return p
			end
			p = rawget(p, "_parent")
		end
		return nil
	end
	function methods.WaitForChild(self, name, timeout)
		local f = self:FindFirstChild(name)
		if f then
			return f
		end
		local waited = 0
		while waited < (timeout or 5) do
			task.wait(0.1)
			waited = waited + 0.1
			f = self:FindFirstChild(name)
			if f then
				return f
			end
		end
		return nil
	end
	function methods.IsDescendantOf(self, anc)
		return isDescendantOf(self, anc)
	end
	function methods.IsAncestorOf(self, o)
		return isDescendantOf(o, self)
	end
	function methods.Destroy(self)
		for _, ch in ipairs(methods.GetChildren(self)) do
			ch:Destroy()
		end
		setParent(self, nil)
		rawset(self, "_destroyed", true)
		local s = rawget(self, "_sig")
		if s and s.Destroying then
			s.Destroying:Fire()
		end
	end
	methods.Remove = methods.Destroy
	function methods.ClearAllChildren(self)
		for _, ch in ipairs(methods.GetChildren(self)) do
			ch:Destroy()
		end
	end
	function methods.Clone(self)
		local c = newInstance(self.ClassName)
		for k, v in pairs(self._p) do
			c._p[k] = v
		end
		for _, ch in ipairs(self._kids) do
			ch:Clone().Parent = c
		end
		return c
	end
	function methods.GetPropertyChangedSignal(self, prop)
		local ps = rawget(self, "_psig")
		if not ps then
			ps = {}
			rawset(self, "_psig", ps)
		end
		local s = ps[prop]
		if not s then
			s = newSignal(prop)
			ps[prop] = s
		end
		return s
	end
	function methods.GetFullName(self)
		local parts = {}
		local o = self
		while o do
			table.insert(parts, 1, o.Name)
			o = rawget(o, "_parent")
		end
		return table.concat(parts, ".")
	end
	function methods.SetAttribute(self, k, v)
		self._attr[k] = v
	end
	function methods.GetAttribute(self, k)
		return self._attr[k]
	end
	function methods.GetAttributes(self)
		return self._attr
	end
	function methods.GetAttributeChangedSignal(self, k)
		return newSignal(k)
	end
	function methods.GetActor()
		return nil
	end
	function methods.GetPivot(self)
		return G.CFrame.new()
	end
	function methods.PivotTo() end
	function methods.GetBoundingBox(self)
		return G.CFrame.new(), G.Vector3.new()
	end
	function methods.Play(self)
		self._p.Playing = true
	end
	function methods.Stop(self)
		self._p.Playing = false
	end
	function methods.Pause(self)
		self._p.Playing = false
	end
	function methods.Resume(self)
		self._p.Playing = true
	end
	function methods.GetPlayingAnimationTracks()
		return {}
	end
	function methods.CaptureFocus() end
	function methods.ReleaseFocus() end
	function methods.IsFocused()
		return false
	end
	function methods.TweenSize() end
	function methods.TweenPosition() end
	function methods.TweenSizeAndPosition() end
	function methods.GetNetworkOwner()
		return nil
	end
	function methods.SetNetworkOwner() end
	function methods.ApplyDescription() end
	function methods.GetMass()
		return 1
	end
	function methods.GetGuiInset()
		return G.Vector2.new(0, 36), G.Vector2.new(0, 0)
	end
	function methods.Fire(self, ...)
		sig(self, "Event"):Fire(...)
	end
	function methods.FireServer() end
	function methods.InvokeServer() end
	function methods.ChangeState() end
	function methods.TakeDamage() end
	function methods.MoveTo() end
	function methods.Move() end
	function methods.EquipTool() end
	function methods.UnequipTools() end
	function methods.GetState(self)
		return G.Enum.HumanoidStateType.Running
	end
	function methods.GetAccessories()
		return {}
	end
	function methods.GetPlayers(self)
		return self._kids
	end
	function methods.GetPlayerFromCharacter(self, char)
		if char == nil then
			return nil
		end
		for _, p in ipairs(self._kids or {}) do
			if p._p and p._p.Character == char then
				return p
			end
		end
		return nil
	end
	function methods.GetPlayerByUserId(self, id)
		for _, p in ipairs(self._kids) do
			if p._p.UserId == id then
				return p
			end
		end
		return nil
	end
	function methods.GetRankInGroup()
		return 0
	end
	function methods.IsFriendsWith()
		return false
	end
	function methods.GetFriendsOnline()
		return {}
	end
	function methods.GetUserThumbnailAsync(self, userId, thumbType, thumbSize)
		if env.rbxUsers == nil and not env.rbxOffline then
			return "rbxasset://thumb", true
		end
		env.thumbCalls = env.thumbCalls or {}
		env.thumbCalls[#env.thumbCalls + 1] = { userId = userId, kind = thumbType and thumbType.Name, size = thumbSize and thumbSize.Name }
		if env.rbxOffline or env.thumbFail or (env.rbxUsers and not env.rbxUsers[userId]) then
			error("HTTP 503 (pretend)")
		end
		return "rbxthumb://type=" .. tostring(thumbType and thumbType.Name) .. "&id=" .. tostring(userId), env.thumbNotReady ~= true
	end
	function methods.GetUserIdFromNameAsync(self, name)
		env.nameLookups = (env.nameLookups or 0) + 1
		if not env.rbxOffline then
			for id, user in pairs(env.rbxUsers or {}) do
				if user.name == name then
					return id
				end
			end
		end
		error("Players:GetUserIdFromNameAsync failed (pretend)")
	end
	function methods.GetNameFromUserIdAsync(self, userId)
		env.idLookups = (env.idLookups or 0) + 1
		local user = (env.rbxUsers or {})[userId]
		if env.rbxOffline or not user then
			error("Players:GetNameFromUserIdAsync failed (pretend)")
		end
		return user.name
	end
	function methods.GetUserInfosByUserIdsAsync(self, ids)
		env.infoLookups = (env.infoLookups or 0) + 1
		if env.rbxOffline or env.noUserService then
			error("UserService failed (pretend)")
		end
		local out = {}
		for _, id in ipairs(ids) do
			local user = (env.rbxUsers or {})[id]
			if user then
				out[#out + 1] = { Id = id, Username = user.name, DisplayName = user.display }
			end
		end
		return out
	end
	function methods.OpenBrowserWindow(self, url)
		if env.noBrowser then
			error("OpenBrowserWindow lacks capability (pretend)")
		end
		env.opened = env.opened or {}
		env.opened[#env.opened + 1] = url
	end
	function methods.IsStudio()
		return false
	end
	function methods.IsClient()
		return true
	end
	function methods.IsServer()
		return false
	end
	function methods.IsRunning()
		return true
	end
	function methods.IsRunMode()
		return false
	end
	function methods.IsEdit()
		return false
	end
	function methods.BindToRenderStep() end
	function methods.UnbindFromRenderStep() end
	function methods.GetCore()
		return nil
	end
	function methods.SetCore() end
	function methods.SetCoreGuiEnabled() end
	function methods.GetCoreGuiEnabled()
		return true
	end
	function methods.GetStringForKeyCode(self, kc)
		local map = { Semicolon = ";", Quote = "'", Comma = ",", Period = ".", Slash = "/", BackSlash = "\\", Minus = "-", Equals = "=", LeftBracket = "[", RightBracket = "]", Backquote = "`", One = "1", Two = "2", Three = "3", Four = "4", Five = "5", Six = "6", Seven = "7", Eight = "8", Nine = "9", Zero = "0" }
		local name = type(kc) == "table" and kc.Name or tostring(kc)
		return map[name] or string.lower(name)
	end
	function methods.IsKeyDown()
		return false
	end
	function methods.IsMouseButtonPressed()
		return false
	end
	function methods.GetMouseLocation()
		return G.Vector2.new(640, 360)
	end
	function methods.GetLastInputType()
		return G.Enum.UserInputType.Keyboard
	end
	function methods.GetFocusedTextBox()
		return nil
	end
	function methods.GetKeysPressed()
		return {}
	end
	function methods.GetConnectedGamepads()
		return {}
	end
	function methods.GetNavigationGamepads()
		return {}
	end
	function methods.GetPlatform()
		return G.Enum.Platform.Windows
	end
	function methods.GetTextSize(self, text, size, font, bounds)
		return G.Vector2.new(#tostring(text) * (size or 14) * 0.5, size or 14)
	end
	function methods.GetTextBoundsAsync(self, params)
		return G.Vector2.new(#tostring(params and params.Text or "") * ((params and params.Size) or 14) * 0.5, (params and params.Size) or 14)
	end
	function methods.JSONEncode(self, v)
		return jsonencode(v)
	end
	function methods.JSONDecode(self, s)
		local v = jsondecode(s)
		if v == nil then
			error("Can't parse JSON")
		end
		return v
	end
	function methods.GenerateGUID()
		return "00000000-0000-0000-0000-000000000000"
	end
	function methods.UrlEncode(self, s)
		return (string.gsub(tostring(s), "[^%w%-_%.~]", function(c)
			return string.format("%%%02X", string.byte(c))
		end))
	end
	function methods.GetAsync()
		error("HTTP requests are not enabled")
	end
	function methods.RequestAsync()
		error("HTTP requests are not enabled")
	end
	function methods.HttpGet(self, url)
		env.requests[#env.requests + 1] = { method = "GET", url = url }
		if type(env.http) == "function" then
			local body = env.http(url)
			if type(body) == "string" then
				return body
			end
		end
		error("HttpGet failed: offline")
	end
	methods.HttpGetAsync = methods.HttpGet
	function methods.GetProductInfo()
		return { Name = "Test Place", Creator = { Name = "Maker" } }
	end
	function methods.PromptPurchase() end
	function methods.Teleport() end
	function methods.TeleportAsync() end
	function methods.TeleportToPlaceInstance() end
	function methods.GetLogHistory()
		return {}
	end
	function methods.PreloadAsync(self, list, cb)
		if cb then
			for _, a in ipairs(list or {}) do
				cb(a, G.Enum.AssetFetchStatus.Success)
			end
		end
	end
	function methods.GetServerTimeNow()
		return os.time()
	end
	function methods.Raycast()
		return nil
	end
	function methods.FindPartOnRay(self, ray)
		local o = type(ray) == "table" and ray.Origin
		local d = type(ray) == "table" and ray.Direction
		if o and d then
			return nil, o + d, G.Vector3.new(0, 1, 0)
		end
		return nil
	end
	function methods.GetPartBoundsInBox()
		return {}
	end
	function methods.GetTotalMemoryUsageMb()
		return 100
	end
	function methods.GetAudioDeviceInfo()
		return {}
	end
	function methods.SetFocus() end
	function methods.SetPrimaryPartCFrame() end
	function methods.AddItem() end
	function methods.SetTopbarTransparency() end
	function methods.SetMasterVolume() end
	function methods.GetGameThumbnail() end
	function methods.GetRobuxBalance() end
	function methods.IsEnabled()
		return true
	end
	function methods.SetEnabled() end
	function methods.Preload() end
	function methods.Create(self, inst, info, props)
		local tween = newInstance("Tween")
		tween._p.PlaybackState = G.Enum.PlaybackState.Begin
		function tween.Play(t)
			t._p.PlaybackState = G.Enum.PlaybackState.Playing
			local dur = (info and info.Time or 0.2)
			task.delay(dur, function()
				if t._p.PlaybackState == G.Enum.PlaybackState.Playing then
					for k, v in pairs(props or {}) do
						pcall(function()
							inst[k] = v
						end)
					end
					t._p.PlaybackState = G.Enum.PlaybackState.Completed
					sig(t, "Completed"):Fire(G.Enum.PlaybackState.Completed)
				end
			end)
		end
		function tween.Cancel(t)
			t._p.PlaybackState = G.Enum.PlaybackState.Cancelled
		end
		tween.Pause = tween.Cancel
		return tween
	end

	local DYNAMIC = {
		AbsoluteSize = function(o)
			local explicit = rawget(o, "_abs")
			if explicit then
				return explicit
			end
			if opts.zeroLayout and o.ClassName ~= "ScreenGui" and env.beats <= (rawget(o, "_born") or 0) then
				return G.Vector2.new(0, 0)
			end
			if o.ClassName == "ScreenGui" then
				return G.Vector2.new(opts.viewW or 1280, opts.viewH or 720)
			end
			return layoutSize(o)
		end,
		AbsolutePosition = function(o)
			if o.ClassName == "ScreenGui" then
				return G.Vector2.new(0, 0)
			end
			if opts.zeroLayout and env.beats <= (rawget(o, "_born") or 0) then
				return G.Vector2.new(0, 0)
			end
			return layoutPos(o)
		end,
		AbsoluteContentSize = function(o)
			return G.Vector2.new(0, 0)
		end,
		TextBounds = function(o)
			local p = o._p
			if opts.zeroLayout and env.beats <= (rawget(o, "_born") or 0) then
				return G.Vector2.new(0, 0)
			end
			return G.Vector2.new(#tostring(p.Text or "") * (p.TextSize or 14) * 0.5, p.TextSize or 14)
		end,
		Parent = function(o)
			return rawget(o, "_parent")
		end,
		TextFits = function()
			return true
		end,
		AbsoluteCanvasSize = function(o)
			return G.Vector2.new(0, 0)
		end,
		AbsoluteWindowSize = function(o)
			return o.AbsoluteSize
		end,
		DistributedGameTime = function()
			return os.clock()
		end,
		PrimaryPart = function(o)
			return o._p.PrimaryPart
		end,
		Position = function(o)
			local v = o._p.Position
			if v == nil and isA(o.ClassName, "BasePart") then
				return G.Vector3.new()
			end
			return v
		end,
	}

	local mt = { __rbxtype = "Instance" }
	mt.__index = function(o, k)
		local d = DYNAMIC[k]
		if d then
			return d(o)
		end
		local p = rawget(o, "_p")
		local v = p[k]
		if v ~= nil then
			return v
		end
		local m = methods[k]
		if m then
			return m
		end
		if EVENTS[k] then
			for _, ch in ipairs(o._kids) do
				if ch.Name == k then
					return ch
				end
			end
			return sig(o, k)
		end
		local cm = rawget(o, "_cm")
		if cm and cm[k] then
			return cm[k]
		end
		local child
		for _, ch in ipairs(o._kids) do
			if ch.Name == k then
				child = ch
				break
			end
		end
		if child then
			return child
		end
		return nil
	end
	local function scanValue(v, depth)
		local t = type(v)
		if t == "number" then
			if v ~= v then
				return "NaN"
			end
			if v == math.huge or v == -math.huge then
				return "infinite"
			end
			return nil
		end
		if t == "table" and depth < 4 and getmetatable(v) ~= mt then
			for key, item in pairs(v) do
				if type(key) == "string" and type(item) ~= "function" and key:sub(1, 1) ~= "_" then
					local why = scanValue(item, depth + 1)
					if why then
						return why .. " in ." .. key
					end
				end
			end
		end
		return nil
	end
	local function ruleCheck(o, k, v)
		local class = rawget(o, "_p").ClassName
		if k == "TextSize" and type(v) == "number" and (v < 1 or v > 200) then
			return "TextSize " .. tostring(v)
		end
		if class == "UIScale" and k == "Scale" and (type(v) ~= "number" or v <= 0) then
			return "UIScale " .. tostring(v)
		end
		if class == "UIAspectRatioConstraint" and k == "AspectRatio" and (type(v) ~= "number" or v <= 0) then
			return "AspectRatio " .. tostring(v)
		end
		if k == "Thickness" and type(v) == "number" and v < 0 then
			return "Thickness " .. tostring(v)
		end
		if k == "ZIndex" and type(v) == "number" and v ~= math.floor(v) then
			return "ZIndex " .. tostring(v)
		end
		if (k == "Size" or k == "Position") and type(v) == "table" and type(v.X) == "table" and type(v.Y) == "table" and v.X.Scale ~= nil then
			if math.abs(v.X.Scale) > 1e4 or math.abs(v.Y.Scale) > 1e4 or math.abs(v.X.Offset) > 1e6 or math.abs(v.Y.Offset) > 1e6 then
				return k .. " is huge: " .. tostring(v)
			end
		end
		if k == "CanvasSize" and type(v) == "table" and v.Y and (math.abs(v.Y.Offset) > 1e7 or math.abs(v.X.Offset) > 1e7) then
			return "CanvasSize is huge: " .. tostring(v)
		end
		return nil
	end
	mt.__newindex = function(o, k, v)
		if k == "Parent" then
			setParent(o, v)
			return
		end
		local p = rawget(o, "_p")
		local bad = scanValue(v, 0) or ruleCheck(o, k, v)
		if bad then
			env.badProps[#env.badProps + 1] = p.ClassName .. "." .. tostring(k) .. ": " .. bad
		end
		if p[k] == v and type(v) ~= "table" then
			return
		end
		p[k] = v
		if k == "Name" then
			rawset(o, "_nameSet", true)
		end
		fireChanged(o, k)
	end
	mt.__tostring = function(o)
		return o._p.Name or o._p.ClassName
	end

	local CLASS_METHODS = {}

	function newInstance(class)
		local o = setmetatable({ _kids = {}, _attr = {}, _p = { ClassName = class, Name = class } }, mt)
		local p = o._p
		local d = {}
		if isA(class, "GuiObject") then
			d = guiDefaults()
		elseif class == "ScreenGui" then
			d = { Enabled = true, DisplayOrder = 0, ResetOnSpawn = true, IgnoreGuiInset = false }
		elseif class == "UIScale" then
			d = { Scale = 1 }
		elseif class == "UIStroke" then
			d = { Transparency = 0, Thickness = 1, Enabled = true, Color = G.Color3.new(0, 0, 0) }
		elseif class == "UICorner" then
			d = { CornerRadius = G.UDim.new(0, 8) }
		elseif class == "UIListLayout" then
			d = { Padding = G.UDim.new(0, 0), SortOrder = G.Enum.SortOrder.LayoutOrder }
		elseif class == "UIGridLayout" then
			d = { CellSize = G.UDim2.new(0, 100, 0, 100), CellPadding = G.UDim2.new(0, 5, 0, 5) }
		elseif class == "UIPadding" then
			d = { PaddingLeft = G.UDim.new(0, 0), PaddingRight = G.UDim.new(0, 0), PaddingTop = G.UDim.new(0, 0), PaddingBottom = G.UDim.new(0, 0) }
		elseif class == "Sound" then
			d = { Volume = 0.5, Playing = false, TimePosition = 0, TimeLength = 0, IsLoaded = false, Looped = false, PlaybackSpeed = 1, SoundId = "" }
		elseif class == "Humanoid" then
			d = { Health = 100, MaxHealth = 100, WalkSpeed = 16, JumpPower = 50, JumpHeight = 7.2, HipHeight = 2, UseJumpPower = true, MoveDirection = G.Vector3.new(), RigType = G.Enum.HumanoidRigType.R15, Sit = false, PlatformStand = false, AutoRotate = true, DisplayName = "", DisplayDistanceType = G.Enum.HumanoidDisplayDistanceType.Viewer, NameDisplayDistance = 100, HealthDisplayDistance = 100 }
		elseif class == "Camera" then
			d = { ViewportSize = G.Vector2.new(opts.viewW or 1280, opts.viewH or 720), FieldOfView = 70, CFrame = G.CFrame.new(), CameraType = G.Enum.CameraType.Custom, CameraSubject = nil, Focus = G.CFrame.new() }
		elseif isA(class, "BasePart") then
			d = { Position = G.Vector3.new(), CFrame = G.CFrame.new(), Size = G.Vector3.new(1, 1, 1), Anchored = false, CanCollide = true, Transparency = 0, Massless = false, Velocity = G.Vector3.new(), AssemblyLinearVelocity = G.Vector3.new() }
		elseif isA(class, "JointInstance") then
			d = { C0 = G.CFrame.new(), C1 = G.CFrame.new(), Enabled = true }
			if class == "Motor6D" then
				d.Transform = G.CFrame.new()
			end
		elseif class == "WeldConstraint" then
			d = { Enabled = true }
		end
		if class == "TextLabel" or class == "TextButton" or class == "TextBox" then
			d = textDefaults(d)
		end
		if class == "ImageLabel" or class == "ImageButton" then
			d = imageDefaults(d)
		end
		if class == "ScrollingFrame" then
			d.CanvasPosition = G.Vector2.new(0, 0)
			d.CanvasSize = G.UDim2.new(0, 0, 0, 0)
			d.ScrollBarThickness = 12
			d.ScrollingEnabled = true
			d.ScrollBarImageColor3 = G.Color3.new(0, 0, 0)
		end
		if class == "TextBox" then
			d.ClearTextOnFocus = true
			d.PlaceholderText = ""
			d.PlaceholderColor3 = G.Color3.fromRGB(178, 178, 178)
		end
		for k, v in pairs(d) do
			p[k] = v
		end
		rawset(o, "_cm", CLASS_METHODS[class])
		rawset(o, "_born", env.beats)
		return o
	end

	G.Instance = {
		new = function(class, parent)
			local o = newInstance(class)
			if parent then
				o.Parent = parent
			end
			return o
		end,
	}

	local function service(name)
		local s = services[name]
		if s then
			return s
		end
		s = newInstance(name)
		services[name] = s
		return s
	end

	CLASS_METHODS.ChatWindowConfiguration = {
		DeriveNewMessageProperties = function()
			return newInstance("ChatWindowMessageProperties")
		end,
	}
	CLASS_METHODS.BindableEvent = {
		Fire = function(self, ...)
			sig(self, "Event"):Fire(...)
		end,
	}
	CLASS_METHODS.DataModel = {
		IsLoaded = function()
			return true
		end,
		BindToClose = function() end,
		GetObjects = function()
			return {}
		end,
	}
	local game = newInstance("DataModel")
	game._p.Name = "Game"
	game._p.PlaceId = 456
	game._p.GameId = 123
	game._p.JobId = "job-1"
	game._p.CreatorId = 1
	function methods.GetService(self, name)
		return service(name)
	end
	methods.getService = methods.GetService
	methods.service = methods.GetService
	function methods.FindService(self, name)
		return services[name]
	end
	G.game = game

	local workspace = service("Workspace")
	G.workspace = workspace
	workspace._p.Gravity = 196.2
	workspace._p.CurrentCamera = newInstance("Camera")
	workspace._p.CurrentCamera.Parent = workspace
	workspace._p.Name = "Workspace"
	workspace._p.DistributedGameTime = 0

	local Players = service("Players")
	CLASS_METHODS.DataModel.Players = Players
	CLASS_METHODS.DataModel.Workspace = workspace
	local lp = newInstance("Player")
	lp._p.Name = "Tester"
	lp._p.DisplayName = "Tester"
	lp._p.UserId = 1
	lp._p.AccountAge = 400
	lp._p.Team = nil
	lp.Parent = Players
	Players._p.LocalPlayer = lp
	Players._p.MaxPlayers = 30
	local playerGui = newInstance("PlayerGui")
	playerGui._p.Name = "PlayerGui"
	playerGui.Parent = lp
	local backpack = newInstance("Backpack")
	backpack._p.Name = "Backpack"
	backpack.Parent = lp
	if opts.character ~= false then
		local char = newInstance("Model")
		char._p.Name = "Tester"
		local hum = newInstance("Humanoid")
		hum._p.Name = "Humanoid"
		hum.Parent = char
		for _, n in ipairs({ "HumanoidRootPart", "Head", "Torso" }) do
			local part = newInstance("Part")
			part._p.Name = n
			part.Parent = char
		end
		char._p.PrimaryPart = char:FindFirstChild("HumanoidRootPart")
		char.Parent = workspace
		lp._p.Character = char
	end

	local coreGui = service("CoreGui")
	local hui = newInstance("Folder")
	hui._p.Name = "HiddenUI"
	hui.Parent = coreGui

	local uis = service("UserInputService")
	uis._p.TouchEnabled = opts.touch == true
	uis._p.MouseEnabled = opts.touch ~= true
	uis._p.KeyboardEnabled = opts.touch ~= true
	uis._p.GamepadEnabled = false
	uis._p.MouseBehavior = G.Enum.MouseBehavior.Default
	uis._p.MouseIconEnabled = true

	local sg = service("StarterGui")
	local run = service("RunService")
	local lighting = service("Lighting")
	lighting._p.Brightness = 2
	lighting._p.ClockTime = 14
	lighting._p.Ambient = G.Color3.new(0.5, 0.5, 0.5)
	local stats = service("Stats")
	stats._p.PerformanceStats = nil
	service("HttpService")
	service("TweenService")
	service("TextService")
	service("GuiService")
	service("TextChatService")._p.ChatVersion = G.Enum.ChatVersion.LegacyChatService
	service("MarketplaceService")
	service("TeleportService")
	service("SoundService")
	service("LogService")
	service("ContentProvider")
	service("VirtualUser")
	service("ReplicatedStorage")
	service("Debris")
	service("CollectionService")
	service("ContextActionService")
	service("StarterPlayer")
	service("Teams")

	G.script = nil
	G.shared = {}
	G.warn = function(...)
		local parts = {}
		for i, v in ipairs({ ... }) do
			parts[i] = tostring(v)
		end
		env.warns[#env.warns + 1] = table.concat(parts, " ")
	end
	G.getgenv = function()
		return genv
	end
	G.getrenv = function()
		return G
	end
	G.getfenv = function()
		return G
	end
	G.setfenv = function(f)
		return f
	end
	G.identifyexecutor = function()
		return opts.executorName or "TestExec", "1.0"
	end

	local function vpath(p)
		p = string.gsub(tostring(p), "\\", "/")
		return p
	end
	local rootName = opts.rootName or "Atsuko Hub"
	local function hostRel(p)
		local prefix = rootName .. "/"
		if string.sub(p, 1, #prefix) == prefix then
			return string.sub(p, #prefix + 1)
		end
		return nil
	end
	G.isfile = function(p)
		p = vpath(p)
		if env.files[p] ~= nil then
			return true
		end
		local rel = hostRel(p)
		return rel ~= nil and hostisfile(rel)
	end
	G.isfolder = function(p)
		p = vpath(p)
		if env.folders[p] then
			return true
		end
		if p == rootName then
			return true
		end
		local rel = hostRel(p)
		return rel ~= nil and hostisfolder(rel)
	end
	G.readfile = function(p)
		p = vpath(p)
		local v = env.files[p]
		if v ~= nil then
			return v
		end
		local rel = hostRel(p)
		if rel and hostisfile(rel) then
			return readsource(rel)
		end
		error("readfile: no such file " .. p)
	end
	G.writefile = function(p, data)
		p = vpath(p)
		env.files[p] = tostring(data)
	end
	G.appendfile = function(p, data)
		p = vpath(p)
		env.files[p] = (env.files[p] or "") .. tostring(data)
	end
	G.makefolder = function(p)
		env.folders[vpath(p)] = true
	end
	G.delfile = function(p)
		env.files[vpath(p)] = nil
	end
	G.delfolder = function(p)
		env.folders[vpath(p)] = nil
	end
	G.listfiles = function(p)
		p = vpath(p)
		local out = {}
		local rel = (p == rootName) and "" or hostRel(p)
		if rel ~= nil then
			for _, name in ipairs(hostlist(rel)) do
				out[#out + 1] = p .. "/" .. name
			end
		end
		local prefix = p .. "/"
		for path in pairs(env.files) do
			if string.sub(path, 1, #prefix) == prefix and not string.find(string.sub(path, #prefix + 1), "/", 1, true) then
				out[#out + 1] = path
			end
		end
		return out
	end
	G.getcustomasset = function(p)
		return "rbxasset://" .. vpath(p)
	end
	G.setclipboard = function(text)
		env.clipboard = text
	end
	G.getclipboard = function()
		return env.clipboard
	end
	G.request = function(o)
		env.requests[#env.requests + 1] = { method = o.Method, url = o.Url }
		return { StatusCode = 0, Body = "", StatusMessage = "offline", Headers = {} }
	end
	G.http_request = G.request
	G.gethui = function()
		return hui
	end
	G.queue_on_teleport = function(src)
		env.queued = src
	end
	G.setfpscap = function() end
	G.firetouchinterest = function() end
	G.getconnections = function()
		return {}
	end
	G.isexecutorclosure = function()
		return false
	end
	G.checkcaller = function()
		return env.callerIsMine == true
	end
	G.newcclosure = function(f)
		return f
	end
	G.getnamecallmethod = function()
		return env.namecallMethod
	end
	G.setnamecallmethod = function(m)
		env.namecallMethod = m
	end
	G.getrawmetatable = function(o)
		return { __namecall = function() end, __index = function() end }
	end
	G.hookmetamethod = function(obj, name, fn)
		env.hooks[#env.hooks + 1] = { kind = "metamethod", name = name, obj = obj, fn = fn }
		return function() end
	end
	G.getcallbackvalue = function(obj, name)
		return obj[name]
	end
	G.hookfunction = function(target, fn)
		env.hooks[#env.hooks + 1] = { kind = "function", fn = fn }
		return function() end
	end
	G.debug = G.debug or {}
	if not G.debug.traceback then
		G.debug.traceback = function(m)
			return tostring(m or "")
		end
	end
	G.debug.info = nil
	G.utf8 = G.utf8 or {
		char = function(...)
			local out = {}
			for i, c in ipairs({ ... }) do
				out[i] = string.char(c % 256)
			end
			return table.concat(out)
		end,
		len = function(s)
			return #s
		end,
	}
	G.delay = nil

	for _, name in ipairs(opts.without or {}) do
		G[name] = nil
	end

	function env.frame(dt)
		dt = dt or (1 / 30)
		task.wait(dt)
		env.beats = env.beats + 1
		run.Heartbeat:Fire(dt)
		run.RenderStepped:Fire(dt)
		run.Stepped:Fire(os.clock(), dt)
	end

	function env.run(seconds)
		local frames = math.floor(seconds * 30)
		for _ = 1, frames do
			env.frame(1 / 30)
		end
	end

	env.game = game
	env.workspace = workspace
	env.lp = lp
	env.Players = Players
	env.uis = uis
	env.hui = hui
	env.coreGui = coreGui
	env.playerGui = playerGui
	env.run_service = run
	env.service = service
	env.newInstance = newInstance
	env.typeName = typeName
	return env
end

return World
