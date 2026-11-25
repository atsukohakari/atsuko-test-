local Relay = {}

Relay.VERSION = 1
Relay.RATE = 15
Relay.SCAN = 0.5
Relay.FULL = 6
Relay.KEY = 15
Relay.MAX_OBJ = 220
Relay.MAX_DECO = 16
Relay.MAX_SOUNDS = 8
Relay.MAX_SIZE = 600
Relay.MAX_PEERS = 10
Relay.MAX_FRAME = 40000
Relay.DELAY = 0.1
Relay.TIMEOUT = 4
Relay.KEEP = 8
Relay.LINK_FILE = "Hub/relay.txt"

Relay.PART_CLASSES = { Part = true, MeshPart = true, WedgePart = true, CornerWedgePart = true, TrussPart = true }
Relay.PART_PROPS = { "Size", "Color", "Material", "Transparency", "Reflectance", "CastShadow" }
Relay.SHAPE_PROPS = { Part = { "Shape" } }
Relay.DECO = {
	SpecialMesh = { "MeshType", "MeshId", "TextureId", "Scale", "Offset", "VertexColor" },
	BlockMesh = { "Scale", "Offset" },
	CylinderMesh = { "Scale", "Offset" },
	Decal = { "Texture", "Face", "Transparency", "Color3" },
	Texture = { "Texture", "Face", "Transparency", "Color3", "StudsPerTileU", "StudsPerTileV" },
	Attachment = { "CFrame" },
	ParticleEmitter = { "Texture", "Color", "Size", "Transparency", "Lifetime", "Rate", "Speed", "SpreadAngle", "Rotation", "RotSpeed", "LightEmission", "LightInfluence", "Acceleration", "Drag", "LockedToPart", "ZOffset", "Enabled", "EmissionDirection", "Orientation", "Squash", "Brightness", "TimeScale", "VelocityInheritance", "Shape", "ShapeStyle", "ShapeInOut", "FlipbookLayout", "FlipbookMode", "FlipbookFramerate" },
	Trail = { "Texture", "Color", "Transparency", "Lifetime", "MinLength", "MaxLength", "WidthScale", "LightEmission", "LightInfluence", "FaceCamera", "TextureLength", "TextureMode", "Enabled", "Brightness" },
	Beam = { "Texture", "Color", "Transparency", "Width0", "Width1", "CurveSize0", "CurveSize1", "Segments", "LightEmission", "LightInfluence", "FaceCamera", "TextureLength", "TextureMode", "TextureSpeed", "Enabled", "Brightness", "ZOffset" },
	PointLight = { "Brightness", "Color", "Range", "Shadows", "Enabled" },
	SpotLight = { "Brightness", "Color", "Range", "Shadows", "Enabled", "Angle", "Face" },
	SurfaceLight = { "Brightness", "Color", "Range", "Shadows", "Enabled", "Angle", "Face" },
	Fire = { "Color", "SecondaryColor", "Heat", "Size", "Enabled" },
	Smoke = { "Color", "Opacity", "RiseVelocity", "Size", "Enabled" },
	Sparkles = { "SparkleColor", "Enabled" },
}
Relay.LINKED = { Trail = true, Beam = true }
Relay.CONTENT = { MeshId = true, TextureId = true, TextureID = true, Texture = true, SoundId = true }
Relay.ENUMS = {
	Material = true,
	PartType = true,
	MeshType = true,
	NormalId = true,
	TextureMode = true,
	ParticleOrientation = true,
	ParticleFlipbookLayout = true,
	ParticleFlipbookMode = true,
	ParticleEmitterShape = true,
	ParticleEmitterShapeStyle = true,
	ParticleEmitterShapeInOut = true,
}

local function finite(n)
	return type(n) == "number" and n == n and n ~= math.huge and n ~= -math.huge
end

local function round(n, step)
	return math.floor(n / step + 0.5) * step
end

local function r3(n)
	return round(n, 0.001)
end

local function getProp(o, k)
	local ok, v = pcall(function()
		return o[k]
	end)
	if ok then
		return v
	end
	return nil
end

local function kindOf(v)
	local ok, t = pcall(typeof, v)
	if ok then
		return t
	end
	return type(v)
end

function Relay.asset(v)
	if type(v) ~= "string" then
		return nil
	end
	if v == "" then
		return ""
	end
	local id = string.match(v, "^rbxassetid://(%d+)$") or string.match(v, "^https?://www%.roblox%.com/asset/%?id=(%d+)$") or string.match(v, "^http://roblox%.com/asset/%?id=(%d+)$") or string.match(v, "^(%d+)$")
	if id and #id <= 20 then
		return "rbxassetid://" .. id
	end
	if #v <= 120 and string.match(v, "^rbxasset://[%w_/%.%-]+$") and not string.find(v, "..", 1, true) then
		return v
	end
	return nil
end

function Relay.enumParts(v)
	local text = tostring(v)
	local a, b = string.match(text, "^Enum%.(%w+)%.(%w+)$")
	if a then
		return a, b
	end
	local et = getProp(v, "EnumType")
	local name = getProp(v, "Name")
	local etName = type(et) == "table" and et.Name or (et ~= nil and string.match(tostring(et), "(%w+)$")) or nil
	return etName, name
end

function Relay.packCF(cf)
	local x, y, z, r00, r01, r02, r10, r11, r12, r20, r21, r22 = cf:GetComponents()
	local qw, qx, qy, qz
	local tr = r00 + r11 + r22
	if tr > 0 then
		local s = math.sqrt(tr + 1) * 2
		qw, qx, qy, qz = 0.25 * s, (r21 - r12) / s, (r02 - r20) / s, (r10 - r01) / s
	elseif r00 > r11 and r00 > r22 then
		local s = math.sqrt(1 + r00 - r11 - r22) * 2
		qw, qx, qy, qz = (r21 - r12) / s, 0.25 * s, (r01 + r10) / s, (r02 + r20) / s
	elseif r11 > r22 then
		local s = math.sqrt(1 + r11 - r00 - r22) * 2
		qw, qx, qy, qz = (r02 - r20) / s, (r01 + r10) / s, 0.25 * s, (r12 + r21) / s
	else
		local s = math.sqrt(1 + r22 - r00 - r11) * 2
		qw, qx, qy, qz = (r10 - r01) / s, (r02 + r20) / s, (r12 + r21) / s, 0.25 * s
	end
	if qw < 0 then
		qx, qy, qz = -qx, -qy, -qz
	end
	return { round(x, 0.01), round(y, 0.01), round(z, 0.01), round(qx, 0.0001), round(qy, 0.0001), round(qz, 0.0001) }
end

function Relay.unpackCF(t, i)
	i = i or 1
	if type(t) ~= "table" then
		return nil
	end
	local x, y, z, qx, qy, qz = t[i], t[i + 1], t[i + 2], t[i + 3], t[i + 4], t[i + 5]
	if not (finite(x) and finite(y) and finite(z) and finite(qx) and finite(qy) and finite(qz)) then
		return nil
	end
	if math.abs(x) > 1e6 or math.abs(y) > 1e6 or math.abs(z) > 1e6 then
		return nil
	end
	local s = qx * qx + qy * qy + qz * qz
	local qw = 0
	if s > 1 then
		local m = math.sqrt(s)
		qx, qy, qz = qx / m, qy / m, qz / m
	else
		qw = math.sqrt(1 - s)
	end
	return CFrame.new(x, y, z,
		1 - 2 * (qy * qy + qz * qz), 2 * (qx * qy - qz * qw), 2 * (qx * qz + qy * qw),
		2 * (qx * qy + qz * qw), 1 - 2 * (qx * qx + qz * qz), 2 * (qy * qz - qx * qw),
		2 * (qx * qz - qy * qw), 2 * (qy * qz + qx * qw), 1 - 2 * (qx * qx + qy * qy))
end

function Relay.enc(v, key)
	local t = kindOf(v)
	if t == "number" then
		if not finite(v) then
			return nil
		end
		return r3(v)
	elseif t == "boolean" then
		return v
	elseif t == "string" then
		if key and Relay.CONTENT[key] then
			return Relay.asset(v)
		end
		if #v > 60 then
			return nil
		end
		return v
	elseif t == "Color3" then
		return { "c", math.floor(v.R * 255 + 0.5), math.floor(v.G * 255 + 0.5), math.floor(v.B * 255 + 0.5) }
	elseif t == "Vector3" then
		return { "v", r3(v.X), r3(v.Y), r3(v.Z) }
	elseif t == "Vector2" then
		return { "w", r3(v.X), r3(v.Y) }
	elseif t == "NumberRange" then
		return { "r", r3(v.Min), r3(v.Max) }
	elseif t == "NumberSequence" then
		local out = { "n" }
		for i, k in ipairs(v.Keypoints) do
			if i > 20 then
				break
			end
			out[#out + 1] = r3(k.Time)
			out[#out + 1] = r3(k.Value)
			out[#out + 1] = r3(k.Envelope or 0)
		end
		return out
	elseif t == "ColorSequence" then
		local out = { "s" }
		for i, k in ipairs(v.Keypoints) do
			if i > 20 then
				break
			end
			local c = k.Value
			out[#out + 1] = r3(k.Time)
			out[#out + 1] = math.floor(c.R * 255 + 0.5)
			out[#out + 1] = math.floor(c.G * 255 + 0.5)
			out[#out + 1] = math.floor(c.B * 255 + 0.5)
		end
		return out
	elseif t == "EnumItem" then
		local a, b = Relay.enumParts(v)
		if a and b and Relay.ENUMS[a] then
			return { "e", a, b }
		end
		return nil
	elseif t == "CFrame" then
		local p = Relay.packCF(v)
		return { "f", p[1], p[2], p[3], p[4], p[5], p[6] }
	end
	return nil
end

local function num(x, lo, hi)
	if not finite(x) then
		return nil
	end
	if lo and x < lo then
		x = lo
	end
	if hi and x > hi then
		x = hi
	end
	return x
end

local function byte(x)
	return num(x, 0, 255)
end

function Relay.dec(x, key)
	local t = type(x)
	if t == "number" then
		return num(x, -1e6, 1e6)
	elseif t == "boolean" then
		return x
	elseif t == "string" then
		if key and Relay.CONTENT[key] then
			return Relay.asset(x)
		end
		if #x > 60 then
			return nil
		end
		return x
	elseif t ~= "table" then
		return nil
	end
	local tag = x[1]
	if tag == "c" then
		local r, g, b = byte(x[2]), byte(x[3]), byte(x[4])
		if r and g and b then
			return Color3.fromRGB(r, g, b)
		end
	elseif tag == "v" then
		local a, b, c = num(x[2], -1e5, 1e5), num(x[3], -1e5, 1e5), num(x[4], -1e5, 1e5)
		if a and b and c then
			return Vector3.new(a, b, c)
		end
	elseif tag == "w" then
		local a, b = num(x[2], -1e5, 1e5), num(x[3], -1e5, 1e5)
		if a and b then
			return Vector2.new(a, b)
		end
	elseif tag == "r" then
		local a, b = num(x[2], -1e5, 1e5), num(x[3], -1e5, 1e5)
		if a and b then
			local ok, v = pcall(NumberRange.new, math.min(a, b), math.max(a, b))
			if ok then
				return v
			end
		end
	elseif tag == "n" then
		local keys = {}
		local i = 2
		while i + 2 <= #x and #keys < 20 do
			local tm, v, e = num(x[i], 0, 1), num(x[i + 1], -1e4, 1e4), num(x[i + 2], 0, 1e4)
			if not (tm and v and e) then
				return nil
			end
			keys[#keys + 1] = { tm, v, e }
			i += 3
		end
		local ok, seq = pcall(function()
			local list = {}
			for _, k in ipairs(keys) do
				list[#list + 1] = NumberSequenceKeypoint.new(k[1], k[2], k[3])
			end
			return NumberSequence.new(list)
		end)
		if ok then
			return seq
		end
	elseif tag == "s" then
		local keys = {}
		local i = 2
		while i + 3 <= #x and #keys < 20 do
			local tm, r, g, b = num(x[i], 0, 1), byte(x[i + 1]), byte(x[i + 2]), byte(x[i + 3])
			if not (tm and r and g and b) then
				return nil
			end
			keys[#keys + 1] = { tm, r, g, b }
			i += 4
		end
		local ok, seq = pcall(function()
			local list = {}
			for _, k in ipairs(keys) do
				list[#list + 1] = ColorSequenceKeypoint.new(k[1], Color3.fromRGB(k[2], k[3], k[4]))
			end
			return ColorSequence.new(list)
		end)
		if ok then
			return seq
		end
	elseif tag == "e" then
		if type(x[2]) == "string" and type(x[3]) == "string" and Relay.ENUMS[x[2]] then
			local ok, item = pcall(function()
				return Enum[x[2]][x[3]]
			end)
			if ok then
				return item
			end
		end
	elseif tag == "f" then
		return Relay.unpackCF(x, 2)
	end
	return nil
end

function Relay.visible(p)
	local tr = getProp(p, "Transparency")
	if type(tr) == "number" and tr < 1 then
		return true
	end
	local ok, kids = pcall(function()
		return p:GetDescendants()
	end)
	if ok and type(kids) == "table" then
		for i, d in ipairs(kids) do
			if i > 60 then
				break
			end
			local c = getProp(d, "ClassName")
			if c and Relay.DECO[c] and c ~= "Attachment" and c ~= "SpecialMesh" and c ~= "BlockMesh" and c ~= "CylinderMesh" then
				return true
			end
		end
	end
	return false
end

function Relay.props(o, list)
	local out = {}
	for _, k in ipairs(list) do
		local v = getProp(o, k)
		if v ~= nil then
			local e = Relay.enc(v, k)
			if e ~= nil then
				out[k] = e
			end
		end
	end
	return out
end

function Relay.look(p, ref)
	local class = getProp(p, "ClassName")
	if not Relay.PART_CLASSES[class] then
		return nil
	end
	local o = { c = class, p = Relay.props(p, Relay.PART_PROPS) }
	if Relay.SHAPE_PROPS[class] then
		for k, v in pairs(Relay.props(p, Relay.SHAPE_PROPS[class])) do
			o.p[k] = v
		end
	end
	if class == "MeshPart" then
		o.m = Relay.asset(getProp(p, "MeshId")) or ""
		o.x = Relay.asset(getProp(p, "TextureID")) or ""
		local ms = getProp(p, "MeshSize")
		o.ms = kindOf(ms) == "Vector3" and Relay.enc(ms) or nil
	end
	local deco = {}
	local atts = {}
	local function add(d, parentIndex)
		if #deco >= Relay.MAX_DECO then
			return nil
		end
		local c = getProp(d, "ClassName")
		local list = c and Relay.DECO[c]
		if not list then
			return nil
		end
		local item = { c = c, p = Relay.props(d, list), a = parentIndex }
		deco[#deco + 1] = item
		if c == "Attachment" then
			atts[d] = #deco
		end
		return #deco
	end
	local okK, kids = pcall(function()
		return p:GetChildren()
	end)
	local later = {}
	for _, d in ipairs(okK and kids or {}) do
		local c = getProp(d, "ClassName")
		if c == "Attachment" then
			local idx = add(d, nil)
			if idx then
				local okA, sub = pcall(function()
					return d:GetChildren()
				end)
				for _, s in ipairs(okA and sub or {}) do
					local sc = getProp(s, "ClassName")
					if Relay.LINKED[sc] then
						later[#later + 1] = s
					else
						add(s, idx)
					end
				end
			end
		elseif Relay.LINKED[c] then
			later[#later + 1] = d
		else
			add(d, nil)
		end
	end
	for _, d in ipairs(later) do
		local idx = add(d, nil)
		if idx then
			local item = deco[idx]
			for _, k in ipairs({ "Attachment0", "Attachment1" }) do
				local att = getProp(d, k)
				if att ~= nil then
					local local1 = atts[att]
					if local1 then
						item[k] = { 0, local1 }
					elseif ref then
						local where = ref(att)
						if where then
							item[k] = where
						end
					end
				end
			end
		end
	end
	if #deco > 0 then
		o.d = deco
	end
	return o
end

function Relay.track()
	return { t = {}, cf = {} }
end

function Relay.push(tr, t, cf)
	local n = #tr.t
	if n > 0 and t <= tr.t[n] then
		if t == tr.t[n] then
			tr.cf[n] = cf
		end
		return
	end
	tr.t[n + 1] = t
	tr.cf[n + 1] = cf
	if n + 1 > Relay.KEEP then
		table.remove(tr.t, 1)
		table.remove(tr.cf, 1)
	end
end

function Relay.sample(tr, t)
	local n = #tr.t
	if n == 0 then
		return nil
	end
	if t <= tr.t[1] then
		return tr.cf[1]
	end
	if t >= tr.t[n] then
		return tr.cf[n]
	end
	for i = n - 1, 1, -1 do
		local a = tr.t[i]
		if t >= a then
			local b = tr.t[i + 1]
			local f = (t - a) / (b - a)
			return tr.cf[i]:Lerp(tr.cf[i + 1], f)
		end
	end
	return tr.cf[n]
end

function Relay.link(text)
	if type(text) ~= "string" then
		return nil
	end
	text = string.match(text, "^%s*(.-)%s*$")
	if text == "" then
		return nil
	end
	text = string.gsub(text, "^https://", "wss://")
	text = string.gsub(text, "^http://", "ws://")
	text = string.gsub(text, "/+$", "")
	if not string.match(text, "^wss?://[%w%.%-]+[%w%.%-:/]*$") or #text > 200 then
		return nil
	end
	return text
end

function Relay.room(placeId, jobId)
	local job = string.gsub(tostring(jobId or ""), "[^%w%-]", "")
	if job == "" then
		job = "studio"
	end
	local place = string.gsub(tostring(placeId or "0"), "[^%d]", "")
	return string.sub((place ~= "" and place or "0") .. "-" .. job, 1, 90)
end

function Relay.new(ctx)
	local self = {
		ctx = ctx,
		state = "off",
		err = nil,
		ids = setmetatable({}, { __mode = "k" }),
		nextId = 0,
		sentLook = {},
		sentCF = {},
		live = {},
		peers = {},
		sounds = {},
		soundIds = setmetatable({}, { __mode = "k" }),
		nextSound = 0,
		frame = 0,
		acc = 0,
		scanAt = -1e9,
		fullAt = -1e9,
		sharing = false,
		objects = {},
		conns = {},
		alive = true,
		heard = 0,
	}
	local now = ctx.now or os.clock

	local function S()
		return ctx.S or {}
	end

	function self.send(msg)
		local ws = self.ws
		if not ws then
			return false
		end
		local ok, text = pcall(ctx.encode, msg)
		if not ok or type(text) ~= "string" or #text > Relay.MAX_FRAME then
			return false
		end
		local sent = pcall(function()
			ws:Send(text)
		end)
		return sent
	end

	function self.idOf(key)
		local id = self.ids[key]
		if not id then
			self.nextId += 1
			id = self.nextId
			self.ids[key] = id
		end
		return id
	end

	local function inWorld(p)
		local ok, yes = pcall(function()
			return p:IsDescendantOf(ctx.world)
		end)
		return ok and yes == true
	end

	local function consider(list, seen, o, depth)
		if #list >= Relay.MAX_OBJ or seen[o] then
			return
		end
		local c = getProp(o, "ClassName")
		if c == nil then
			return
		end
		if Relay.PART_CLASSES[c] then
			seen[o] = true
			if inWorld(o) and Relay.visible(o) then
				list[#list + 1] = { key = o, part = o }
			end
			return
		end
		if depth > 0 and (c == "Model" or c == "Folder" or c == "Tool" or c == "Accessory") and inWorld(o) then
			seen[o] = true
			local ok, kids = pcall(function()
				return o:GetDescendants()
			end)
			for _, d in ipairs(ok and kids or {}) do
				if #list >= Relay.MAX_OBJ then
					break
				end
				if Relay.PART_CLASSES[getProp(d, "ClassName")] then
					consider(list, seen, d, 0)
				end
			end
		end
	end

	function self.collect()
		local list, seen = {}, {}
		local okV, view = pcall(ctx.rigView)
		if okV and type(view) == "table" then
			for _, it in ipairs(view) do
				if #list >= Relay.MAX_OBJ then
					break
				end
				if type(it) == "table" and it.k ~= nil and kindOf(it.cf) == "CFrame" then
					list[#list + 1] = { key = it.k, part = it.h, cf = it.cf, body = true }
					if it.h then
						seen[it.h] = true
					end
				end
			end
		end
		local okR, roots = pcall(ctx.roots)
		for _, o in ipairs(okR and type(roots) == "table" and roots or {}) do
			consider(list, seen, o, 1)
		end
		return list
	end

	function self.shareWanted()
		if S().relayShare == false then
			return false
		end
		local okR, on = pcall(ctx.reanimated)
		if okR and on then
			return true
		end
		return #self.objects > 0
	end

	local function partRef(att)
		local parent = getProp(att, "Parent")
		if parent == nil then
			return nil
		end
		local id = self.ids[parent]
		if not id then
			return nil
		end
		local ok, kids = pcall(function()
			return parent:GetChildren()
		end)
		local n = 0
		for _, d in ipairs(ok and kids or {}) do
			if getProp(d, "ClassName") == "Attachment" then
				n += 1
				if d == att then
					return { id, n }
				end
			end
		end
		return nil
	end

	function self.scan(t)
		self.scanAt = t
		local list = self.collect()
		local looks = {}
		local live = {}
		for _, it in ipairs(list) do
			local id = self.idOf(it.key)
			it.id = id
			live[id] = it
		end
		for _, it in ipairs(list) do
			if it.part then
				local look = Relay.look(it.part, partRef)
				if look then
					look.i = it.id
					look.b = it.body and 1 or nil
					local okE, key = pcall(ctx.encode, look)
					if okE and (self.sentLook[it.id] ~= key or t - self.fullAt >= Relay.FULL) then
						self.sentLook[it.id] = key
						looks[#looks + 1] = look
					end
				end
			end
		end
		local gone = {}
		for id in pairs(self.live) do
			if not live[id] then
				gone[#gone + 1] = id
				self.sentLook[id] = nil
				self.sentCF[id] = nil
			end
		end
		self.live = live
		self.objects = list
		if t - self.fullAt >= Relay.FULL then
			self.fullAt = t
		end
		if self.sharing then
			local batch = {}
			for _, look in ipairs(looks) do
				batch[#batch + 1] = look
				if #batch >= 20 then
					self.send({ k = "a", v = Relay.VERSION, o = batch })
					batch = {}
				end
			end
			if #batch > 0 then
				self.send({ k = "a", v = Relay.VERSION, o = batch })
			end
			if #gone > 0 then
				self.send({ k = "g", o = gone })
			end
		end
		self.scanSounds()
	end

	function self.scanSounds()
		local okS, list = pcall(ctx.sounds)
		if not okS or type(list) ~= "table" then
			return
		end
		local started, stopped = {}, {}
		for _, s in ipairs(list) do
			local playing = getProp(s, "IsPlaying") == true or getProp(s, "Playing") == true
			local sid = self.soundIds[s]
			if playing and not sid and #started < Relay.MAX_SOUNDS then
				self.nextSound += 1
				sid = self.nextSound
				self.soundIds[s] = sid
				local parent = getProp(s, "Parent")
				local on = parent and self.ids[parent] or 0
				local pos = nil
				if on == 0 and parent and Relay.PART_CLASSES[getProp(parent, "ClassName")] then
					local cf = getProp(parent, "CFrame")
					if kindOf(cf) == "CFrame" then
						pos = Relay.packCF(cf)
					end
				end
				started[#started + 1] = { sid, on, Relay.asset(getProp(s, "SoundId")) or "", r3(num(getProp(s, "Volume"), 0, 10) or 0.5), r3(num(getProp(s, "PlaybackSpeed"), 0.01, 20) or 1), getProp(s, "Looped") == true, r3(num(getProp(s, "TimePosition"), 0, 3600) or 0), pos and pos[1] or nil, pos and pos[2] or nil, pos and pos[3] or nil }
			elseif not playing and sid then
				self.soundIds[s] = nil
				stopped[#stopped + 1] = sid
			end
		end
		if self.sharing then
			if #started > 0 then
				self.send({ k = "s", o = started })
			end
			if #stopped > 0 then
				self.send({ k = "q", o = stopped })
			end
		end
	end

	function self.tick(dt)
		if not self.alive then
			return
		end
		self.refreshBody()
		local t = now()
		local want = self.ws ~= nil and self.shareWanted()
		if want ~= self.sharing then
			self.sharing = want
			if want then
				self.fullAt = -1e9
				table.clear(self.sentLook)
				table.clear(self.sentCF)
				self.scan(t)
			else
				self.send({ k = "bye" })
				table.clear(self.sentLook)
				table.clear(self.sentCF)
			end
		end
		if t - self.scanAt >= Relay.SCAN then
			self.scan(t)
		end
		self.acc += dt
		if self.sharing and self.acc >= 1 / Relay.RATE then
			self.acc = 0
			self.frame += 1
			local key = self.frame % Relay.KEY == 0
			local rows = {}
			for _, it in ipairs(self.objects) do
				local cf = it.cf
				if not it.body then
					cf = getProp(it.part, "CFrame")
				end
				if kindOf(cf) == "CFrame" then
					local p = Relay.packCF(cf)
					local last = self.sentCF[it.id]
					local changed = key or not last
					if not changed then
						for i = 1, 6 do
							if last[i] ~= p[i] then
								changed = true
								break
							end
						end
					end
					if changed then
						self.sentCF[it.id] = p
						rows[#rows + 1] = { it.id, p[1], p[2], p[3], p[4], p[5], p[6] }
					end
				end
			end
			if #rows > 0 or key then
				self.send({ k = "f", t = r3(t), o = rows })
			end
		end
		self.render(t)
	end

	function self.refreshBody()
		local okV, view = pcall(ctx.rigView)
		if not okV or type(view) ~= "table" then
			return
		end
		local byKey = {}
		for _, it in ipairs(view) do
			if type(it) == "table" and it.k ~= nil then
				byKey[it.k] = it
			end
		end
		for _, it in ipairs(self.objects) do
			if it.body then
				local now1 = byKey[it.key]
				if now1 and kindOf(now1.cf) == "CFrame" then
					it.cf = now1.cf
				end
			end
		end
	end

	function self.peer(u)
		local p = self.peers[u]
		if p then
			return p
		end
		local count = 0
		for _ in pairs(self.peers) do
			count += 1
		end
		if count >= Relay.MAX_PEERS then
			return nil
		end
		local folder = Instance.new("Folder")
		folder.Name = "AtsukoRelay" .. tostring(u)
		p = { u = u, folder = folder, objs = {}, off = nil, last = now(), hidden = {}, sounds = {}, body = 0, hideAt = -1e9 }
		self.peers[u] = p
		pcall(function()
			folder.Parent = ctx.mirrorParent and ctx.mirrorParent() or ctx.world
		end)
		return p
	end

	local function setProps(o, props, list)
		if type(props) ~= "table" then
			return
		end
		for _, k in ipairs(list) do
			local raw = props[k]
			if raw ~= nil then
				local v = Relay.dec(raw, k)
				if v ~= nil then
					if k == "Size" and kindOf(v) == "Vector3" then
						v = Vector3.new(math.clamp(v.X, 0.001, Relay.MAX_SIZE), math.clamp(v.Y, 0.001, Relay.MAX_SIZE), math.clamp(v.Z, 0.001, Relay.MAX_SIZE))
					elseif (k == "Transparency" or k == "Reflectance") and type(v) == "number" then
						v = math.clamp(v, 0, 1)
					elseif k == "Rate" and type(v) == "number" then
						v = math.clamp(v, 0, 400)
					elseif k == "Range" and type(v) == "number" then
						v = math.clamp(v, 0, 60)
					elseif k == "Brightness" and type(v) == "number" then
						v = math.clamp(v, 0, 40)
					end
					pcall(function()
						o[k] = v
					end)
				end
			end
		end
	end

	function self.build(p, look)
		if type(look) ~= "table" or not finite(look.i) or not Relay.PART_CLASSES[look.c] then
			return
		end
		local id = look.i
		local obj = p.objs[id]
		local class = look.c == "MeshPart" and "Part" or look.c
		if obj and obj.class ~= class then
			pcall(function()
				obj.part:Destroy()
			end)
			obj = nil
		end
		if not obj then
			local count = 0
			for _ in pairs(p.objs) do
				count += 1
			end
			if count >= Relay.MAX_OBJ then
				return
			end
			local ok, part = pcall(Instance.new, class)
			if not ok or not part then
				return
			end
			pcall(function()
				part.Name = "Mirror"
				part.Anchored = true
				part.CanCollide = false
				part.CanTouch = false
				part.CanQuery = false
				part.Locked = true
			end)
			obj = { part = part, class = class, track = Relay.track(), body = false }
			p.objs[id] = obj
		end
		local part = obj.part
		pcall(function()
			for _, d in ipairs(part:GetChildren()) do
				d:Destroy()
			end
		end)
		setProps(part, look.p, Relay.PART_PROPS)
		if look.c == "Part" then
			setProps(part, look.p, Relay.SHAPE_PROPS.Part)
		end
		if look.c == "MeshPart" then
			local okM, mesh = pcall(Instance.new, "SpecialMesh")
			if okM and mesh then
				pcall(function()
					mesh.MeshType = Enum.MeshType.FileMesh
					mesh.MeshId = Relay.asset(look.m) or ""
					mesh.TextureId = Relay.asset(look.x) or ""
					local ms = Relay.dec(look.ms)
					if kindOf(ms) == "Vector3" and ms.X > 0 and ms.Y > 0 and ms.Z > 0 then
						local sz = part.Size
						mesh.Scale = Vector3.new(sz.X / ms.X, sz.Y / ms.Y, sz.Z / ms.Z)
					end
					mesh.Parent = part
				end)
			end
		end
		local made = {}
		local linkLater = {}
		for i, d in ipairs(type(look.d) == "table" and look.d or {}) do
			if i > Relay.MAX_DECO then
				break
			end
			local list = type(d) == "table" and Relay.DECO[d.c]
			if list then
				local okD, inst = pcall(Instance.new, d.c)
				if okD and inst then
					setProps(inst, d.p, list)
					made[i] = inst
					local parent = part
					if finite(d.a) and made[d.a] and d.c ~= "Attachment" then
						parent = made[d.a]
					end
					pcall(function()
						inst.Parent = parent
					end)
					if Relay.LINKED[d.c] then
						linkLater[#linkLater + 1] = { inst, d }
					end
				end
			end
		end
		obj.links = {}
		for _, pair in ipairs(linkLater) do
			local inst, d = pair[1], pair[2]
			for _, k in ipairs({ "Attachment0", "Attachment1" }) do
				local ref = d[k]
				if type(ref) == "table" and finite(ref[1]) and finite(ref[2]) then
					if ref[1] == 0 then
						local att = made[ref[2]]
						if att then
							pcall(function()
								inst[k] = att
							end)
						end
					else
						obj.links[#obj.links + 1] = { inst, k, ref[1], ref[2] }
					end
				end
			end
		end
		obj.body = look.b == 1
		obj.look = look
		pcall(function()
			part.Parent = p.folder
		end)
		self.relink(p)
	end

	function self.relink(p)
		for _, obj in pairs(p.objs) do
			for _, l in ipairs(obj.links or {}) do
				local other = p.objs[l[3]]
				if other then
					local n = 0
					pcall(function()
						for _, d in ipairs(other.part:GetChildren()) do
							if d.ClassName == "Attachment" then
								n += 1
								if n == l[4] then
									l[1][l[2]] = d
								end
							end
						end
					end)
				end
			end
		end
	end

	function self.drop(p, id)
		local obj = p.objs[id]
		if obj then
			p.objs[id] = nil
			pcall(function()
				obj.part:Destroy()
			end)
		end
	end

	function self.showReal(p)
		for part, was in pairs(p.hidden) do
			pcall(function()
				part.LocalTransparencyModifier = was
			end)
		end
		table.clear(p.hidden)
	end

	function self.remove(u)
		local p = self.peers[u]
		if not p then
			return
		end
		self.peers[u] = nil
		self.showReal(p)
		for _, s in pairs(p.sounds) do
			pcall(function()
				s:Destroy()
			end)
		end
		pcall(function()
			p.folder:Destroy()
		end)
	end

	function self.hideReal(p, t)
		if t - p.hideAt < 0.25 then
			return
		end
		p.hideAt = t
		local body = 0
		for _, obj in pairs(p.objs) do
			if obj.body then
				body += 1
			end
		end
		p.body = body
		if body == 0 or S().relayHideReal == false then
			self.showReal(p)
			return
		end
		local okC, char = pcall(ctx.characterOf, p.u)
		if not okC or char == nil then
			return
		end
		local ok, list = pcall(function()
			return char:GetDescendants()
		end)
		for _, d in ipairs(ok and list or {}) do
			local c = getProp(d, "ClassName")
			if Relay.PART_CLASSES[c] or c == "Decal" then
				if p.hidden[d] == nil then
					local was = getProp(d, "LocalTransparencyModifier")
					p.hidden[d] = type(was) == "number" and was or 0
				end
				pcall(function()
					d.LocalTransparencyModifier = 1
				end)
			end
		end
	end

	function self.playSound(p, row)
		if type(row) ~= "table" or not finite(row[1]) then
			return
		end
		local count = 0
		for _ in pairs(p.sounds) do
			count += 1
		end
		if count >= Relay.MAX_SOUNDS then
			return
		end
		local id = Relay.asset(row[3])
		if not id or id == "" then
			return
		end
		local vol = (num(row[4], 0, 10) or 0.5) * (num(S().relayVolume, 0, 1) or 0.6)
		if vol <= 0 then
			return
		end
		local okS, s = pcall(Instance.new, "Sound")
		if not okS or not s then
			return
		end
		local holder = nil
		local on = p.objs[row[2]]
		if on then
			holder = on.part
		elseif finite(row[8]) and finite(row[9]) and finite(row[10]) then
			local okP, part = pcall(Instance.new, "Part")
			if okP and part then
				pcall(function()
					part.Name = "MirrorSound"
					part.Anchored = true
					part.CanCollide = false
					part.CanQuery = false
					part.CanTouch = false
					part.Transparency = 1
					part.Size = Vector3.new(0.2, 0.2, 0.2)
					part.CFrame = CFrame.new(row[8], row[9], row[10])
					part.Parent = p.folder
				end)
				holder = part
				s.Destroying:Connect(function()
					pcall(function()
						part:Destroy()
					end)
				end)
			end
		end
		pcall(function()
			s.SoundId = id
			s.Volume = math.min(vol, 2)
			s.PlaybackSpeed = num(row[5], 0.01, 20) or 1
			s.Looped = row[6] == true
			s.Parent = holder or p.folder
			s.TimePosition = num(row[7], 0, 3600) or 0
			s:Play()
		end)
		p.sounds[row[1]] = s
		if row[6] ~= true then
			task.delay(30, function()
				if p.sounds[row[1]] == s then
					p.sounds[row[1]] = nil
				end
				pcall(function()
					s:Destroy()
				end)
			end)
		end
	end

	function self.stopSound(p, sid)
		local s = p.sounds[sid]
		if s then
			p.sounds[sid] = nil
			pcall(function()
				s:Destroy()
			end)
		end
	end

	function self.onMessage(text)
		local ok, msg = pcall(ctx.decode, text)
		if not ok or type(msg) ~= "table" or type(msg.k) ~= "string" then
			return
		end
		self.heard = now()
		local u = tonumber(msg.u)
		if msg.k == "pong" then
			self.room = tonumber(msg.n) or self.room
			return
		end
		if not u or u == ctx.me then
			return
		end
		if msg.k == "join" then
			self.fullAt = -1e9
			return
		end
		if msg.k == "bye" then
			self.remove(u)
			return
		end
		if S().relaySee == false then
			return
		end
		local okB, blocked = pcall(ctx.blocked, u)
		if okB and blocked then
			return
		end
		local okH, here = pcall(ctx.inServer, u)
		if okH and here == false then
			return
		end
		local p = self.peer(u)
		if not p then
			return
		end
		p.last = now()
		if msg.k == "a" and type(msg.o) == "table" then
			for i, look in ipairs(msg.o) do
				if i > 40 then
					break
				end
				pcall(self.build, p, look)
			end
		elseif msg.k == "f" and type(msg.o) == "table" and finite(msg.t) then
			local recv = now()
			local off = recv - msg.t
			if p.off == nil or off < p.off then
				p.off = off
			else
				p.off = p.off + (off - p.off) * 0.02
			end
			for i, row in ipairs(msg.o) do
				if i > Relay.MAX_OBJ then
					break
				end
				if type(row) == "table" then
					local obj = p.objs[row[1]]
					local cf = obj and Relay.unpackCF(row, 2)
					if cf then
						Relay.push(obj.track, msg.t, cf)
					end
				end
			end
		elseif msg.k == "g" and type(msg.o) == "table" then
			for i, id in ipairs(msg.o) do
				if i > Relay.MAX_OBJ then
					break
				end
				self.drop(p, id)
			end
		elseif msg.k == "s" and type(msg.o) == "table" then
			for i, row in ipairs(msg.o) do
				if i > Relay.MAX_SOUNDS then
					break
				end
				pcall(self.playSound, p, row)
			end
		elseif msg.k == "q" and type(msg.o) == "table" then
			for i, sid in ipairs(msg.o) do
				if i > Relay.MAX_SOUNDS * 4 then
					break
				end
				self.stopSound(p, sid)
			end
		end
	end

	function self.render(t)
		for u, p in pairs(self.peers) do
			if t - p.last > Relay.TIMEOUT then
				self.remove(u)
			else
				if p.off then
					local rt = t - p.off - Relay.DELAY
					for _, obj in pairs(p.objs) do
						local cf = Relay.sample(obj.track, rt)
						if cf then
							pcall(function()
								obj.part.CFrame = cf
							end)
						end
					end
				end
				self.hideReal(p, t)
			end
		end
	end

	function self.peerCount()
		local n = 0
		for _ in pairs(self.peers) do
			n += 1
		end
		return n
	end

	function self.attach(ws)
		self.ws = ws
		self.state = "live"
		self.err = nil
		self.sharing = false
		pcall(function()
			self.conns[#self.conns + 1] = ws.OnMessage:Connect(function(text)
				self.onMessage(text)
			end)
		end)
		pcall(function()
			self.conns[#self.conns + 1] = ws.OnClose:Connect(function()
				if self.ws == ws then
					self.ws = nil
					self.sharing = false
					self.state = "closed"
				end
			end)
		end)
		self.send({ k = "ping" })
	end

	function self.detach()
		local ws = self.ws
		if ws and self.sharing then
			self.send({ k = "bye" })
		end
		self.ws = nil
		self.sharing = false
		for _, c in ipairs(self.conns) do
			pcall(function()
				c:Disconnect()
			end)
		end
		table.clear(self.conns)
		if ws then
			pcall(function()
				ws:Close()
			end)
		end
	end

	function self.destroy()
		self.alive = false
		self.detach()
		for u in pairs(self.peers) do
			self.remove(u)
		end
	end

	return self
end

local ctx = nil
local live = nil

function Relay.hubCtx(c)
	local Players = c.Players
	local LP = c.LP
	local http = game:GetService("HttpService")
	local out = {
		S = c.S,
		me = LP and LP.UserId or 0,
		world = workspace,
		encode = function(v)
			return http:JSONEncode(v)
		end,
		decode = function(text)
			return http:JSONDecode(text)
		end,
		reanimated = c.reanimated,
		rigView = function()
			local f = c.GENV and c.GENV.AtsukoRigView
			if type(f) == "function" then
				return f()
			end
			return nil
		end,
		roots = function()
			local list = {}
			for _, rec in pairs(c.SHARED and c.SHARED.running or {}) do
				if type(rec) == "table" and rec.active ~= false and type(rec.insts) == "table" then
					for _, o in ipairs(rec.insts) do
						list[#list + 1] = o
						if #list > 3000 then
							break
						end
					end
				end
			end
			local fx = c.GENV and c.GENV.AtsukoFx
			if type(fx) == "table" then
				for o in pairs(fx) do
					list[#list + 1] = o
				end
			end
			return list
		end,
		sounds = function()
			local list = {}
			for _, rec in pairs(c.SHARED and c.SHARED.running or {}) do
				if type(rec) == "table" and type(rec.insts) == "table" then
					for _, o in ipairs(rec.insts) do
						local okC, cls = pcall(function()
							return o.ClassName
						end)
						if okC and cls == "Sound" then
							list[#list + 1] = o
							if #list > 60 then
								return list
							end
						end
					end
				end
			end
			return list
		end,
		characterOf = function(u)
			local p = Players:GetPlayerByUserId(u)
			return p and p.Character or nil
		end,
		inServer = function(u)
			return Players:GetPlayerByUserId(u) ~= nil
		end,
		blocked = function(u)
			local b = c.S and c.S.chatBlocked
			return type(b) == "table" and b[tostring(u)] ~= nil
		end,
	}
	return out
end

function Relay.init(context)
	ctx = context
	Relay.state = "off"
end

function Relay.url()
	local own = Relay.link(ctx and ctx.S and ctx.S.relayUrl)
	if own then
		return own, "yours"
	end
	return Relay.shared, Relay.shared and "hub" or nil
end

function Relay.fetchShared()
	if not ctx or not ctx.Net or not ctx.Repo or type(ctx.Repo.raw) ~= "function" then
		return nil
	end
	local ok, body = ctx.Net.get(ctx.Repo.raw(Relay.LINK_FILE) .. "?t=" .. os.time())
	if ok and type(body) == "string" and #body < 400 then
		Relay.shared = Relay.link(string.match(body, "[^\r\n]*"))
	end
	return Relay.shared
end

function Relay.start()
	if Relay.running or not ctx then
		return
	end
	Relay.running = true
	Relay.gen = (Relay.gen or 0) + 1
	local gen = Relay.gen
	live = Relay.new(Relay.hubCtx(ctx))
	Relay.live = live
	local conn = game:GetService("RunService").Heartbeat:Connect(function(dt)
		if live then
			pcall(live.tick, dt)
		end
	end)
	Relay.conn = conn
	task.spawn(function()
		pcall(Relay.fetchShared)
		local wait = 2
		while Relay.running and Relay.gen == gen and ctx.HUB.alive do
			local S = ctx.S
			local url = Relay.url()
			local want = S.relayShare ~= false or S.relaySee ~= false
			if not want then
				Relay.state = "off"
				live.detach()
				task.wait(2)
			elseif not url then
				Relay.state = "no link"
				task.wait(10)
				pcall(Relay.fetchShared)
			elseif not (ctx.X and ctx.X.wsConnect) then
				Relay.state = "no websocket"
				task.wait(30)
			elseif not live.ws then
				Relay.state = "connecting"
				local room = Relay.room(game.PlaceId, game.JobId)
				local ok, ws = pcall(ctx.X.wsConnect, url .. "/room/" .. room .. "?u=" .. tostring(ctx.LP.UserId))
				if ok and ws then
					live.attach(ws)
					Relay.state = "live"
					wait = 2
				else
					Relay.state = "retrying"
					Relay.err = ok and "no answer" or tostring(ws)
					task.wait(wait)
					wait = math.min(wait * 2, 60)
				end
				pcall(ctx.Bus.fire, "relay")
			else
				Relay.state = "live"
				if os.clock() - (Relay.pingAt or 0) > 20 then
					Relay.pingAt = os.clock()
					live.send({ k = "ping" })
				end
				task.wait(1)
			end
		end
	end)
end

function Relay.stop()
	Relay.running = false
	if Relay.conn then
		pcall(function()
			Relay.conn:Disconnect()
		end)
		Relay.conn = nil
	end
	if live then
		live.destroy()
		live = nil
	end
	Relay.live = nil
	Relay.state = "off"
end

function Relay.restart()
	Relay.stop()
	Relay.start()
end

function Relay.status()
	local st = Relay.state or "off"
	local others = live and live.peerCount() or 0
	if st == "live" then
		return "Connected" .. (others > 0 and (", showing " .. others .. (others == 1 and " hub user" or " hub users")) or ""), true
	elseif st == "no link" then
		return "No relay yet: put its link in Hub/relay.txt or below", false
	elseif st == "no websocket" then
		return "Your executor has no WebSocket, so this can't connect", false
	elseif st == "connecting" then
		return "Connecting...", false
	elseif st == "retrying" then
		return "Couldn't reach the relay, trying again", false
	end
	return "Off", false
end

function Relay.destroy()
	Relay.stop()
end

return Relay
