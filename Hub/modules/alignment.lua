local Mod = {}

Mod.VERSION = 1
Mod.LIMBS = { "Head", "Torso", "Left Arm", "Right Arm", "Left Leg", "Right Leg" }
Mod.MAX_TEXT = 300000
Mod.MAX_DEPTH = 8
Mod.MAX_NODES = 40000
Mod.MAX_HELP = 12
Mod.MAX_RIG = 600
Mod.MAX_SCRIPTS = 40
Mod.MAX_SCRIPT_ROWS = 300
Mod.MAX_USER_ROWS = 300
Mod.MAX_PUBLISHED = 700
Mod.MAX_LOOKUPS = 40
Mod.MAX_WORN = 40
Mod.BUILTIN_PATH = "Alignment/alignment.lua"
Mod.CACHE_FILE = "Atsuko Hub/cache/alignment.lua"
Mod.USER_FILE = "Atsuko Hub/alignment_user.lua"
Mod.BROKEN_FILE = "Atsuko Hub/alignment_user_broken.lua"
Mod.SHARED = { "gun", "sword", "shotgun", "rifle", "any" }
Mod.SHARED_SLOTS = {
	gun = { gun = true, gun1 = true, rifle = true, shotgun = true },
	sword = { sword = true },
	shotgun = { shotgun = true },
	rifle = { rifle = true },
	any = { gun = true, gun1 = true, sword = true, shotgun = true, rifle = true },
}
Mod.LOOKUP = { "sword", "shotgun", "rifle", "gun", "any" }
Mod.SHIPPED = { bullet = { bullet = true }, aura = { aura = true } }
Mod.NO_HALVES = { rifle = true, shotgun = true }
Mod.WEAPON_OF = { gun = "gun", gun1 = "gun", gun2 = "gun", rifle = "gun", shotgun = "gun", sword = "sword" }
Mod.ANY_WORDS = { any = true, all = true, both = true, every = true, weapon = true, weapons = true, anyweapon = true, everyweapon = true }
Mod.PAIR_WORDS = { pair = true, lcgun = true, lcguns = true, twoguns = true }
Mod.PLURALS = { guns = "gun", swords = "sword", rifles = "rifle", shotguns = "shotgun", pairs = "pair" }
Mod.SWORD_WORDS = { "sword", "blade", "katana", "saber", "sabre", "scimitar", "rapier", "dagger", "knife", "machete", "cutlass", "claymore", "scythe", "glaive", "halberd", "axe", "darkheart", "illumina", "venomshank", "ghostwalker", "firebrand", "windforce" }
Mod.GUN_WORDS = { "gun", "pistol", "rifle", "shotgun", "revolver", "blaster", "sniper", "launcher", "carbine", "musket", "firearm", "smg", "uzi", "glock", "deagle", "rpg", "bazooka", "cannon" }
Mod.MAX_SPOTS = 400
Mod.KNOWN = {
	["97638566524944"] = { name = "LC Gun 1", tex = "128238174721913", half = 1, mate = "118424096643898", c1 = { 4.51, 1.525, 0.1, 0, -1, 0, 0, 0, 1, -1, 0, 0 }, tip = { 7.21, 1.425, -0.1 } },
	["118424096643898"] = { name = "LC Gun 2", tex = "128238174721913", half = 2, mate = "97638566524944", c1 = { -0.5, -1.3, -0.1, 0, -1, 0, 0, 0, -1, 1, 0, 0 }, tip = { 7.21, 1.425, -0.1 } },
}
Mod.TWO_PART_USE = "gun in every gun script with both halves joined, and Snake Banisher's gun 1 and gun 2"

local LIMB_SET = {}
for _, name in ipairs(Mod.LIMBS) do
	LIMB_SET[name] = true
end

function Mod.sharedKinds(slot)
	local out = {}
	for _, kind in ipairs(Mod.LOOKUP) do
		if Mod.SHARED_SLOTS[kind][slot] then
			out[#out + 1] = kind
		end
	end
	return out
end

function Mod.sharedKind(slot)
	return Mod.sharedKinds(slot)[1]
end

function Mod.normWord(word)
	word = string.lower((string.gsub(tostring(word or ""), "[%s%-_]", "")))
	return Mod.PLURALS[word] or word
end

function Mod.nameTokens(name)
	local text = tostring(name or "")
	text = string.gsub(text, "(%l)(%u)", "%1 %2")
	text = string.gsub(text, "(%a)(%d)", "%1 %2")
	text = string.gsub(text, "(%d)(%a)", "%1 %2")
	local out = {}
	for token in string.gmatch(string.lower(text), "%a+") do
		out[#out + 1] = token
		if #out >= 24 then
			break
		end
	end
	return out
end

local function tokenHas(token, word)
	if token == word then
		return true
	end
	if #token > #word and string.sub(token, -#word) == word then
		return true
	end
	return #word >= 5 and #token > #word and string.sub(token, 1, #word) == word
end

function Mod.kindFromName(name)
	local sword, gun = false, false
	for _, token in ipairs(Mod.nameTokens(name)) do
		for _, word in ipairs(Mod.SWORD_WORDS) do
			if tokenHas(token, word) then
				sword = true
			end
		end
		for _, word in ipairs(Mod.GUN_WORDS) do
			if tokenHas(token, word) then
				gun = true
			end
		end
	end
	if sword and not gun then
		return "sword"
	end
	if gun and not sword then
		return "gun"
	end
	return nil
end

local ESCAPES = { n = "\n", t = "\t", r = "\r", ["\\"] = "\\", ['"'] = '"', ["'"] = "'" }

local ctx = nil
local current = nil

local function firstLine(text)
	text = tostring(text)
	return (string.match(text, "^[^\r\n]*")) or text
end

local function finite(value)
	return type(value) == "number" and value == value and value ~= math.huge and value ~= -math.huge
end

local function lineOf(text, pos)
	local line = 1
	local from = 1
	while true do
		local at = string.find(text, "\n", from, true)
		if not at or at >= pos then
			return line
		end
		line += 1
		from = at + 1
	end
end

function Mod.parse(text)
	if type(text) ~= "string" or text == "" then
		return nil, "the file is empty"
	end
	if #text > Mod.MAX_TEXT then
		return nil, "the file is too big"
	end
	local pos = 1
	local nodes = 0
	local readValue

	local function bad(message)
		error({ message = message, pos = pos }, 0)
	end

	local function skip()
		while pos <= #text do
			local _, spaceEnd = string.find(text, "^%s+", pos)
			if spaceEnd then
				pos = spaceEnd + 1
			elseif string.sub(text, pos, pos + 1) == "--" then
				local level = string.match(text, "^%-%-%[(=*)%[", pos)
				if level then
					local _, closeEnd = string.find(text, "]" .. level .. "]", pos, true)
					if not closeEnd then
						bad("a comment never ends")
					end
					pos = closeEnd + 1
				else
					local newline = string.find(text, "\n", pos, true)
					pos = newline and newline + 1 or #text + 1
				end
			else
				return
			end
		end
	end

	local function readShortString()
		local quote = string.sub(text, pos, pos)
		local stop = quote == '"' and '[\\\n"]' or "[\\\n']"
		pos += 1
		local parts = {}
		while true do
			local at = string.find(text, stop, pos)
			if not at then
				bad("a string never ends")
			end
			parts[#parts + 1] = string.sub(text, pos, at - 1)
			local ch = string.sub(text, at, at)
			if ch == quote then
				pos = at + 1
				return table.concat(parts)
			elseif ch == "\n" then
				pos = at
				bad("a string never ends")
			end
			local nextChar = string.sub(text, at + 1, at + 1)
			if ESCAPES[nextChar] then
				parts[#parts + 1] = ESCAPES[nextChar]
				pos = at + 2
			elseif nextChar == "\n" then
				parts[#parts + 1] = "\n"
				pos = at + 2
			elseif string.find(nextChar, "^%d") then
				local digits = string.match(text, "^%d%d?%d?", at + 1)
				local code = tonumber(digits)
				if code > 255 then
					pos = at
					bad("a character code is too big")
				end
				parts[#parts + 1] = string.char(code)
				pos = at + 1 + #digits
			elseif nextChar == "x" then
				local hex = string.match(text, "^%x%x", at + 2)
				if not hex then
					pos = at
					bad("a character code is not valid")
				end
				parts[#parts + 1] = string.char(tonumber(hex, 16))
				pos = at + 4
			else
				pos = at
				bad("a string has an escape that is not allowed")
			end
		end
	end

	local function readLongString()
		local level = string.match(text, "^%[(=*)%[", pos)
		local open = #level + 2
		local _, closeEnd = string.find(text, "]" .. level .. "]", pos + open, true)
		if not closeEnd then
			bad("a string never ends")
		end
		local body = string.sub(text, pos + open, closeEnd - #level - 2)
		pos = closeEnd + 1
		return (string.gsub(body, "^\r?\n", ""))
	end

	local function readNumber()
		local literal = string.match(text, "^%-?%d+%.?%d*[eE][%+%-]?%d+", pos)
			or string.match(text, "^%-?%.%d+[eE][%+%-]?%d+", pos)
			or string.match(text, "^%-?%d+%.?%d*", pos)
			or string.match(text, "^%-?%.%d+", pos)
		if not literal then
			bad("a number is not valid")
		end
		if string.find(text, "^[%w_%.]", pos + #literal) then
			bad("a number is not valid")
		end
		local value = tonumber(literal)
		if not finite(value) then
			bad("a number is not valid")
		end
		pos += #literal
		return value
	end

	local function readTable(depth)
		if depth > Mod.MAX_DEPTH then
			bad("tables are nested too deep")
		end
		pos += 1
		local out = {}
		local count = 0
		while true do
			skip()
			local ch = string.sub(text, pos, pos)
			if ch == "" then
				bad("a table never ends")
			end
			if ch == "}" then
				pos += 1
				return out
			end
			nodes += 1
			if nodes > Mod.MAX_NODES then
				bad("the file has too many values")
			end
			local key = nil
			if ch == "[" and not string.find(text, "^%[=*%[", pos) then
				pos += 1
				key = readValue(depth + 1)
				if type(key) ~= "string" and type(key) ~= "number" then
					bad("a key has to be text or a number")
				end
				skip()
				if string.sub(text, pos, pos) ~= "]" then
					bad("a key is missing its ]")
				end
				pos += 1
				skip()
				if string.sub(text, pos, pos) ~= "=" then
					bad("a key is missing its =")
				end
				pos += 1
			else
				local name = string.match(text, "^[%a_][%w_]*", pos)
				if name then
					local saved = pos
					pos += #name
					skip()
					if string.sub(text, pos, pos) == "=" and string.sub(text, pos + 1, pos + 1) ~= "=" then
						key = name
						pos += 1
					else
						pos = saved
					end
				end
			end
			local value = readValue(depth + 1)
			if key ~= nil then
				out[key] = value
			elseif value ~= nil then
				count += 1
				out[count] = value
			end
			skip()
			local sep = string.sub(text, pos, pos)
			if sep == "," or sep == ";" then
				pos += 1
			elseif sep == "" then
				bad("a table never ends")
			elseif sep ~= "}" then
				bad("expected a , or a }")
			end
		end
	end

	function readValue(depth)
		skip()
		local ch = string.sub(text, pos, pos)
		if ch == "{" then
			return readTable(depth)
		elseif ch == '"' or ch == "'" then
			return readShortString()
		elseif ch == "[" and string.find(text, "^%[=*%[", pos) then
			return readLongString()
		elseif ch == "-" or ch == "." or string.find(ch, "^%d") then
			return readNumber()
		end
		local word = string.match(text, "^[%a_][%w_]*", pos)
		if word == "true" then
			pos += 4
			return true
		elseif word == "false" then
			pos += 5
			return false
		elseif word == "nil" then
			pos += 3
			return nil
		end
		if word then
			bad("\"" .. word .. "\" is not a value, only text, numbers, true, false and tables are allowed")
		end
		if ch == "" then
			bad("the file ends too early")
		end
		bad("unexpected \"" .. ch .. "\"")
	end

	local function readFile()
		skip()
		if string.sub(text, pos, pos + 5) == "return" and not string.find(string.sub(text, pos + 6, pos + 6), "^[%w_]") then
			pos += 6
			skip()
		end
		if string.sub(text, pos, pos) ~= "{" then
			bad("the file has to be a table, like  return { ... }")
		end
		local value = readTable(1)
		skip()
		if string.sub(text, pos, pos) == ";" then
			pos += 1
			skip()
		end
		if pos <= #text then
			bad("there is something after the table")
		end
		return value
	end

	local ok, result = pcall(readFile)
	if ok then
		return result
	end
	if type(result) == "table" and result.message then
		return nil, "line " .. lineOf(text, result.pos) .. ": " .. result.message
	end
	return nil, "the file could not be read"
end

function Mod.digits(value)
	if type(value) == "number" then
		if finite(value) and value >= 0 and value < 9007199254740992 and value % 1 == 0 then
			return string.format("%d", value)
		end
		return nil
	end
	if type(value) == "string" then
		local digits = string.match(value, "^%s*(%d+)%s*$")
		if digits and #digits <= 20 then
			return digits
		end
	end
	return nil
end

function Mod.extractId(value)
	if type(value) == "number" then
		return Mod.digits(value)
	end
	if type(value) ~= "string" then
		return nil
	end
	local plain = Mod.digits(value)
	if plain then
		return plain
	end
	local found = string.match(value, "rbxassetid://(%d+)")
		or string.match(value, "[%?&]id=(%d+)")
		or string.match(value, "roblox%.com/[%a%-]+/(%d+)")
		or string.match(value, "roblox%.com/[%a%-]+/[%a%-]+/(%d+)")
	if found and #found <= 20 then
		return found
	end
	return nil
end

function Mod.assetId(value)
	local id = Mod.extractId(value)
	if id then
		return id
	end
	if type(value) == "string" then
		local tail = string.match(value, "(%d+)%D*$")
		if tail and #tail <= 20 then
			return tail
		end
	end
	return nil
end

function Mod.known(hat)
	if type(hat) ~= "table" then
		return nil
	end
	local mesh = Mod.assetId(hat.mesh)
	local entry = mesh and Mod.KNOWN[mesh]
	if not entry then
		return nil
	end
	return entry, mesh
end

local function rowCF(list)
	return CFrame.new(list[1], list[2], list[3], list[4], list[5], list[6], list[7], list[8], list[9], list[10], list[11], list[12])
end

function Mod.holdOf(hat)
	local entry, mesh = Mod.known(hat)
	if not entry or CFrame == nil or Vector3 == nil then
		return nil
	end
	local c1 = rowCF(entry.c1)
	local frame = c1 * CFrame.fromMatrix(Vector3.new(0, 0, 0), Vector3.new(0, 1, 0), Vector3.new(0, 0, -1), Vector3.new(-1, 0, 0))
	local tip = Vector3.new(entry.tip[1], entry.tip[2], entry.tip[3])
	local out = {
		mesh = mesh,
		name = entry.name,
		half = entry.half,
		arm = CFrame.new(0.05, -1, 0.15) * CFrame.Angles(math.pi, math.pi, 0) * c1:Inverse(),
		fit = frame:Inverse(),
		tip = tip,
		hatTip = frame * tip,
		hatFwd = frame:VectorToWorldSpace(Vector3.new(1, 0, 0)),
		hatUp = frame:VectorToWorldSpace(Vector3.new(0, 1, 0)),
	}
	local other = Mod.KNOWN[entry.mate]
	if other then
		out.mate = { mesh = entry.mate, tex = other.tex, name = other.name, rel = c1 * rowCF(other.c1):Inverse() }
	end
	return out
end

Mod.R6_ATT = {
	HatAttachment = { "Head", 0, 0.6, 0 },
	HairAttachment = { "Head", 0, 0.6, 0 },
	FaceFrontAttachment = { "Head", 0, 0, -0.6 },
	FaceCenterAttachment = { "Head", 0, 0, 0 },
	NeckAttachment = { "Torso", 0, 1, 0 },
	BodyFrontAttachment = { "Torso", 0, 0, -0.5 },
	BodyBackAttachment = { "Torso", 0, 0, 0.5 },
	LeftCollarAttachment = { "Torso", -1, 1, 0 },
	RightCollarAttachment = { "Torso", 1, 1, 0 },
	WaistFrontAttachment = { "Torso", 0, -1, -0.5 },
	WaistCenterAttachment = { "Torso", 0, -1, 0 },
	WaistBackAttachment = { "Torso", 0, -1, 0.5 },
	LeftShoulderAttachment = { "Left Arm", 0, 1, 0 },
	RightShoulderAttachment = { "Right Arm", 0, 1, 0 },
	LeftFootAttachment = { "Left Leg", 0, -1, 0 },
	RightFootAttachment = { "Right Leg", 0, -1, 0 },
}
Mod.R6_LIMB = { Head = { 0, 1.5, 0 }, Torso = { 0, 0, 0 }, ["Left Arm"] = { -1.5, 0, 0 }, ["Right Arm"] = { 1.5, 0, 0 }, ["Left Leg"] = { -0.5, -2, 0 }, ["Right Leg"] = { 0.5, -2, 0 } }
Mod.PIECE_WORDS = { part = true, pt = true, half = true, piece = true, pc = true, top = true, bottom = true, upper = true, lower = true, front = true, back = true, of = true, ["and"] = true, i = true, ii = true }

function Mod.cleanAtt(att)
	if type(att) ~= "table" or type(att.name) ~= "string" or not Mod.R6_ATT[att.name] or type(att.cf) ~= "table" then
		return nil
	end
	local cf = {}
	for i = 1, 12 do
		local n = tonumber(att.cf[i])
		if not finite(n) then
			return nil
		end
		cf[i] = n
	end
	return { name = att.name, cf = cf }
end

function Mod.attachOf(handle)
	if not handle then
		return nil
	end
	local ok, kids = pcall(function()
		return handle:GetChildren()
	end)
	for _, c in ipairs(ok and kids or {}) do
		local isAtt = pcall(function()
			assert(c:IsA("Attachment"))
		end)
		if isAtt and Mod.R6_ATT[c.Name] then
			return Mod.cleanAtt({ name = c.Name, cf = { c.CFrame:GetComponents() } })
		end
	end
	return nil
end

function Mod.wornCF(att)
	att = Mod.cleanAtt(att)
	if not att or CFrame == nil then
		return nil
	end
	local spot = Mod.R6_ATT[att.name]
	local limb = Mod.R6_LIMB[spot[1]]
	return CFrame.new(limb[1], limb[2], limb[3]) * CFrame.new(spot[2], spot[3], spot[4]) * CFrame.new(table.unpack(att.cf)):Inverse()
end

local function round(n, step)
	return math.floor(n / step + 0.5) * step
end

function Mod.pairRel(a, b)
	local ca, cb = Mod.wornCF(a), Mod.wornCF(b)
	if not ca or not cb then
		return nil
	end
	local rel = ca:Inverse() * cb
	local rx, ry, rz = rel:ToEulerAnglesXYZ()
	local p = rel.Position
	return { round(p.X, 0.001), round(p.Y, 0.001), round(p.Z, 0.001), round(math.deg(rx), 0.01), round(math.deg(ry), 0.01), round(math.deg(rz), 0.01) }
end

function Mod.stem(name)
	if type(name) ~= "string" then
		return nil
	end
	local words = {}
	for w in string.gmatch(string.lower(name), "[%a]+") do
		if not Mod.PIECE_WORDS[w] then
			words[#words + 1] = w
		end
	end
	local out = table.concat(words, " ")
	if #out < 3 then
		return nil
	end
	return out
end

function Mod.partsOf(a, b)
	if type(a) ~= "string" or type(b) ~= "string" or a == b then
		return false
	end
	local sa, sb = Mod.stem(a), Mod.stem(b)
	return sa ~= nil and sa == sb
end

local function relCF(rel)
	return CFrame.new(rel[1], rel[2], rel[3]) * CFrame.Angles(math.rad(rel[4]), math.rad(rel[5]), math.rad(rel[6]))
end

local function rowsOf(data)
	local out = {}
	if type(data) ~= "table" then
		return out
	end
	for _, list in pairs(type(data.shared) == "table" and data.shared or {}) do
		for _, row in ipairs(list) do
			out[#out + 1] = row
		end
	end
	for _, list in pairs(type(data.scripts) == "table" and data.scripts or {}) do
		for _, row in ipairs(list) do
			out[#out + 1] = row
		end
	end
	return out
end

function Mod.mateOf(data, mesh)
	mesh = Mod.assetId(mesh)
	if not mesh then
		return nil
	end
	for _, row in ipairs(rowsOf(data)) do
		if type(row) == "table" and row.mesh == mesh and row.mate and type(row.rel) == "table" then
			return { mesh = row.mate, rel = relCF(row.rel) }
		end
	end
	return nil
end

Mod.joined = setmetatable({}, { __mode = "k" })

function Mod.join(fd, e, data)
	if type(fd) ~= "table" or type(e) ~= "table" or type(fd.cframes) ~= "table" or type(fd.getPartJoint) ~= "function" then
		return nil
	end
	local hold = Mod.holdOf({ mesh = rawget(e, "m"), tex = rawget(e, "t") })
	local mate = hold and hold.mate or Mod.mateOf(data, rawget(e, "m"))
	if not mate then
		return nil
	end
	local other = nil
	for x in pairs(fd.cframes) do
		if type(x) == "table" and x ~= e and rawget(x, "p") ~= nil and Mod.assetId(rawget(x, "m")) == mate.mesh then
			other = x
			break
		end
	end
	if not other then
		return nil
	end
	local ok, j = pcall(fd.getPartJoint, other)
	if not ok or type(j) ~= "table" then
		return nil
	end
	local before = Mod.joined[j]
	local mine = { home = before and before.home or { j.Part1, j.C0, j.C1 } }
	Mod.joined[j] = mine
	j.Part1, j.C0, j.C1 = e, CFrame.new(), mate.rel
	return function()
		if Mod.joined[j] ~= mine then
			return
		end
		Mod.joined[j] = nil
		if j.Part1 == e then
			local home = mine.home
			j.Part1, j.C0, j.C1 = home[1], home[2], home[3]
		end
	end, other
end

local function clean(value, limit)
	if type(value) ~= "string" then
		return nil
	end
	value = string.gsub(value, "%c", " ")
	value = string.match(value, "^%s*(.-)%s*$")
	if value == "" then
		return nil
	end
	if #value > limit then
		value = string.sub(value, 1, limit)
	end
	return value
end

local function wordList(value)
	if type(value) == "string" then
		value = { value }
	end
	if type(value) ~= "table" then
		return nil
	end
	local out = {}
	for _, item in ipairs(value) do
		local word = clean(item, 24)
		if word then
			out[#out + 1] = string.lower(word)
			if #out >= 8 then
				break
			end
		end
	end
	if #out == 0 then
		return nil
	end
	return out
end

local function alignList(value)
	if type(value) ~= "table" then
		return nil
	end
	local count = 0
	for i = 1, 6 do
		if value[i] ~= nil then
			count = i
		end
	end
	if count < 3 then
		return nil
	end
	local out = {}
	for i = 1, 6 do
		local number = value[i]
		if number == nil then
			number = 0
		end
		if not finite(number) then
			return nil
		end
		local limit = i <= 3 and 500 or 1440
		if number > limit then
			number = limit
		elseif number < -limit then
			number = -limit
		end
		out[i] = number
	end
	return out
end

function Mod.empty()
	return { version = Mod.VERSION, help = {}, slots = {}, rig = {}, scripts = {}, shared = { gun = {}, sword = {}, shotgun = {}, rifle = {}, any = {}, bullet = {}, aura = {} }, spots = {} }
end

function Mod.spotList(value)
	if type(value) ~= "table" then
		return nil
	end
	local out = {}
	for i = 1, 6 do
		local number = value[i]
		if number == nil then
			number = 0
		end
		if type(number) ~= "number" or not finite(number) or math.abs(number) >= 1e5 then
			return nil
		end
		out[i] = number
	end
	return out
end

function Mod.cleanSpots(raw, problem)
	local out = {}
	if type(raw) ~= "table" then
		return out, 0
	end
	local count = 0
	for script, tabs in pairs(raw) do
		local name = clean(script, 40)
		if name and type(tabs) == "table" then
			for tab, hats in pairs(tabs) do
				local tabName = clean(tab, 24)
				if tabName and type(hats) == "table" then
					for key, vals in pairs(hats) do
						local hat = clean(type(key) == "number" and tostring(key) or key, 60)
						local list = Mod.spotList(vals)
						if hat and list then
							if count >= Mod.MAX_SPOTS then
								if problem then
									problem("spots: too many, the rest are ignored")
								end
								return out, count
							end
							out[name] = out[name] or {}
							out[name][tabName] = out[name][tabName] or {}
							out[name][tabName][hat] = list
							count += 1
						end
					end
				end
			end
		end
	end
	return out, count
end

function Mod.cleanRow(row, kind)
	if type(row) ~= "table" then
		return nil, "a row has to be a table"
	end
	local out = {}
	if kind == "rig" then
		if not LIMB_SET[row.part] then
			return nil, "part has to be Head, Torso, Left Arm, Right Arm, Left Leg or Right Leg"
		end
		out.part = row.part
	else
		local slot = clean(row.slot, 24)
		if not slot then
			return nil, "slot is missing"
		end
		out.slot = slot
	end
	out.hat = Mod.digits(row.hat)
	out.mesh = Mod.digits(row.mesh)
	out.tex = Mod.digits(row.tex)
	out.acc = clean(row.acc, 80)
	out.name = clean(row.name, 80)
	out.words = wordList(row.words)
	out.key = clean(row.key, 24)
	local count = tonumber(row.count)
	if count and finite(count) and count >= 2 then
		out.count = math.min(8, math.floor(count))
	end
	out.align = alignList(row.align)
	out.mate = Mod.assetId(row.mate)
	out.rel = out.mate and alignList(row.rel) or nil
	if not out.rel then
		out.mate = nil
	end
	out.note = clean(row.note, 120)
	if kind == "rig" then
		if not (out.hat or out.mesh or out.tex or out.acc) then
			return nil, "a rig row needs a hat id, mesh id, texture id or accessory name"
		end
	elseif not (out.hat or out.mesh or out.tex or out.acc or out.name or out.words or out.key or out.align) then
		return nil, "the row says nothing about a hat"
	end
	return out
end

function Mod.clean(raw)
	local data = Mod.empty()
	local problems = {}
	local function problem(text)
		if #problems < 20 then
			problems[#problems + 1] = text
		end
	end
	if type(raw) ~= "table" then
		problem("the file does not hold a table")
		return data, problems
	end
	if type(raw.help) == "table" then
		for _, line in ipairs(raw.help) do
			local text = clean(line, 300)
			if text and #data.help < Mod.MAX_HELP then
				data.help[#data.help + 1] = text
			end
		end
	end
	if type(raw.slots) == "table" then
		local count = 0
		for script, slots in pairs(raw.slots) do
			local name = clean(script, 40)
			if name and type(slots) == "table" and count < Mod.MAX_SCRIPTS then
				local map = {}
				local any = false
				for slot, description in pairs(slots) do
					local key, text = clean(slot, 24), clean(description, 200)
					if key and text then
						map[key] = text
						any = true
					end
				end
				if any then
					data.slots[name] = map
					count += 1
				end
			end
		end
	end
	if type(raw.rig) == "table" then
		for index, row in ipairs(raw.rig) do
			if #data.rig >= Mod.MAX_RIG then
				problem("rig: too many rows, the rest are ignored")
				break
			end
			local out, why = Mod.cleanRow(row, "rig")
			if out then
				data.rig[#data.rig + 1] = out
			else
				problem("rig row " .. index .. ": " .. why)
			end
		end
	end
	if type(raw.scripts) == "table" then
		local count = 0
		for script, rows in pairs(raw.scripts) do
			local name = clean(script, 40)
			if name and type(rows) ~= "table" then
				problem(name .. ": has to be a list of rows")
			elseif name then
				count += 1
				if count > Mod.MAX_SCRIPTS then
					problem("scripts: too many scripts, the rest are ignored")
					break
				end
				local list = {}
				for index, row in ipairs(rows) do
					if #list >= Mod.MAX_SCRIPT_ROWS then
						problem(name .. ": too many rows, the rest are ignored")
						break
					end
					local out, why = Mod.cleanRow(row, "script")
					if out then
						list[#list + 1] = out
					else
						problem(name .. " row " .. index .. ": " .. why)
					end
				end
				data.scripts[name] = list
			end
		end
	end
	if raw.shared ~= nil and type(raw.shared) ~= "table" then
		problem("shared: has to hold gun, sword, shotgun, rifle and any lists")
	elseif type(raw.shared) == "table" then
		for key, rows in pairs(raw.shared) do
			local list = (Mod.SHARED_SLOTS[key] or Mod.SHIPPED[key]) and data.shared[key] or nil
			if not list then
				problem("shared: " .. tostring(clean(key, 24) or "?") .. " is not gun, sword, shotgun, rifle or any")
			elseif type(rows) ~= "table" then
				problem("shared " .. key .. ": has to be a list of rows")
			else
				for index, row in ipairs(rows) do
					if #list >= Mod.MAX_SCRIPT_ROWS then
						problem("shared " .. key .. ": too many rows, the rest are ignored")
						break
					end
					local copy = {}
					if type(row) == "table" then
						for k, v in pairs(row) do
							copy[k] = v
						end
					end
					copy.slot = key
					local out, why = Mod.cleanRow(type(row) == "table" and copy or row, "script")
					if out then
						list[#list + 1] = out
					else
						problem("shared " .. key .. " row " .. index .. ": " .. why)
					end
				end
			end
		end
	end
	if raw.spots ~= nil and type(raw.spots) ~= "table" then
		problem("spots: has to be a table of scripts")
	else
		data.spots = Mod.cleanSpots(raw.spots, problem)
	end
	return data, problems
end

local function tagged(row, src)
	local copy = {}
	for key, value in pairs(row) do
		copy[key] = value
	end
	copy.src = src
	return copy
end

function Mod.merge(builtin, user)
	builtin = builtin or Mod.empty()
	user = user or Mod.empty()
	local data = { version = Mod.VERSION, help = builtin.help, slots = {}, rig = {}, scripts = {}, shared = {} }
	local kinds = table.clone(Mod.SHARED)
	for kind in pairs(Mod.SHIPPED) do
		kinds[#kinds + 1] = kind
	end
	for _, kind in ipairs(kinds) do
		local list = {}
		for _, row in ipairs((user.shared or {})[kind] or {}) do
			list[#list + 1] = tagged(row, "user")
		end
		for _, row in ipairs((builtin.shared or {})[kind] or {}) do
			local copy = tagged(row, "user")
			copy.shipped = true
			list[#list + 1] = copy
		end
		data.shared[kind] = list
	end
	for script, map in pairs(builtin.slots) do
		data.slots[script] = map
	end
	for script, map in pairs(user.slots) do
		local merged = {}
		for key, text in pairs(data.slots[script] or {}) do
			merged[key] = text
		end
		for key, text in pairs(map) do
			merged[key] = text
		end
		data.slots[script] = merged
	end
	for _, row in ipairs(user.rig) do
		data.rig[#data.rig + 1] = tagged(row, "user")
	end
	for _, row in ipairs(builtin.rig) do
		data.rig[#data.rig + 1] = tagged(row, "built-in")
	end
	local names = {}
	for name in pairs(builtin.scripts) do
		names[name] = true
	end
	for name in pairs(user.scripts) do
		names[name] = true
	end
	for name in pairs(names) do
		local list = {}
		for _, row in ipairs(user.scripts[name] or {}) do
			list[#list + 1] = tagged(row, "user")
		end
		for _, row in ipairs(builtin.scripts[name] or {}) do
			list[#list + 1] = tagged(row, "built-in")
		end
		data.scripts[name] = list
	end
	return data
end

local ROW_KEYS = { "part", "slot", "hat", "mesh", "tex", "acc", "name", "words", "key", "count", "align", "mate", "rel", "note" }

local function sameAlign(a, b)
	if a == nil or b == nil then
		return a == b
	end
	for i = 1, 6 do
		if math.abs((a[i] or 0) - (b[i] or 0)) > 0.00005 then
			return false
		end
	end
	return true
end

local function sameWords(a, b)
	if a == nil or b == nil then
		return a == b
	end
	if #a ~= #b then
		return false
	end
	for i = 1, #a do
		if a[i] ~= b[i] then
			return false
		end
	end
	return true
end

function Mod.sameRow(a, b)
	if type(a) ~= "table" or type(b) ~= "table" then
		return false
	end
	for _, key in ipairs({ "part", "slot", "hat", "mesh", "tex", "acc", "name", "key", "count" }) do
		if a[key] ~= b[key] then
			return false
		end
	end
	return sameWords(a.words, b.words) and sameAlign(a.align, b.align)
end

function Mod.matches(row, hat)
	if type(row) ~= "table" or type(hat) ~= "table" then
		return false
	end
	if not (row.mesh or row.tex or row.acc) then
		return false
	end
	if row.mesh and not (hat.mesh and string.find(hat.mesh, row.mesh, 1, true)) then
		return false
	end
	if row.tex and not (hat.tex and string.find(hat.tex, row.tex, 1, true)) then
		return false
	end
	if row.acc and row.acc ~= hat.acc then
		return false
	end
	return true
end

function Mod.mine(row)
	return type(row) == "table" and row.src == "user" and not row.shipped
end

function Mod.weaponOf(data, hat, known)
	if type(data) ~= "table" or type(hat) ~= "table" then
		return false
	end
	local probe = { mesh = hat.mesh, tex = hat.tex, acc = hat.acc or hat.name, name = hat.name or hat.acc }
	local function check(list)
		for _, row in ipairs(type(list) == "table" and list or {}) do
			if Mod.mine(row) then
				local r = row
				local found = row.hat and not row.mesh and not row.tex and type(known) == "table" and known[row.hat] or nil
				if found then
					r = { mesh = found.mesh, tex = found.tex, acc = row.acc }
				end
				if (r.mesh or r.tex or r.acc) and (Mod.matchJob(r, probe) or Mod.matchJob(r, probe, true)) then
					return true
				end
			end
		end
		return false
	end
	for _, list in pairs(type(data.scripts) == "table" and data.scripts or {}) do
		if check(list) then
			return true
		end
	end
	for _, list in pairs(type(data.shared) == "table" and data.shared or {}) do
		if check(list) then
			return true
		end
	end
	return false
end

function Mod.squash(text)
	return (string.gsub(string.lower(tostring(text or "")), "[^%w]", ""))
end

function Mod.matchJob(row, hat, loose)
	if type(row) ~= "table" or type(hat) ~= "table" then
		return false
	end
	if row.mesh or row.tex or row.acc then
		local probe = { mesh = hat.mesh, tex = hat.tex, acc = hat.acc or hat.name }
		if row.mesh and row.tex and (loose or probe.tex == nil or probe.tex == "") then
			return Mod.matches({ mesh = row.mesh, acc = row.acc }, probe)
		end
		if loose then
			return false
		end
		return Mod.matches(row, probe)
	end
	if loose then
		return false
	end
	local name = Mod.squash(hat.name or hat.acc)
	if name == "" then
		return false
	end
	if type(row.words) == "table" and #row.words > 0 then
		local any = false
		for _, word in ipairs(row.words) do
			local w = Mod.squash(word)
			if w ~= "" then
				if not string.find(name, w, 1, true) then
					return false
				end
				any = true
			end
		end
		return any
	end
	if type(row.name) == "string" and row.name ~= "" then
		return Mod.squash(row.name) == name
	end
	return false
end

function Mod.entries(data, cframe, hats)
	local list = {}
	local pending = 0
	local claimed = {}
	for _, row in ipairs(data.rig) do
		local mesh, tex = row.mesh, row.tex
		if row.hat and not mesh and not tex then
			local known = hats and hats[row.hat]
			if known then
				mesh, tex = known.mesh, known.tex
			end
		end
		if mesh or tex or row.acc then
			local key = row.part .. "|" .. (mesh or "") .. "|" .. (tex or "") .. "|" .. (row.acc or "")
			if not (row.src == "built-in" and claimed[key]) then
				if row.src == "user" then
					claimed[key] = true
				end
				local entry = { PartName = row.part, meshid = mesh, textureid = tex, AccessoryName = row.acc }
				local align = row.align
				if align and cframe then
					entry.C0 = cframe(align[1], align[2], align[3], align[4], align[5], align[6])
				end
				if row.count and row.count > 1 then
					entry.count = row.count
				end
				list[#list + 1] = entry
				if #list >= Mod.MAX_PUBLISHED then
					break
				end
			end
		else
			pending += 1
		end
	end
	return list, pending
end

function Mod.rows(data, script, slot)
	local out = {}
	local list = data and data.scripts and data.scripts[script]
	local sharedLists = {}
	if slot ~= nil and data and data.shared then
		for _, kind in ipairs(Mod.sharedKinds(slot)) do
			sharedLists[#sharedLists + 1] = { data.shared[kind], kind ~= slot and Mod.NO_HALVES[slot] == true }
		end
		for kind, slots in pairs(Mod.SHIPPED) do
			if slots[slot] then
				sharedLists[#sharedLists + 1] = { data.shared[kind], false }
			end
		end
	end
	local rest = {}
	for _, row in ipairs(type(list) == "table" and list or {}) do
		if slot == nil or row.slot == slot then
			if row.src == "user" then
				out[#out + 1] = row
			else
				rest[#rest + 1] = row
			end
		end
	end
	for _, pair in ipairs(sharedLists) do
		local shared, noHalves = pair[1], pair[2]
		if type(shared) == "table" then
			for _, row in ipairs(shared) do
				if not (noHalves and Mod.known(row)) then
					if row.src == "user" then
						out[#out + 1] = row
					else
						rest[#rest + 1] = row
					end
				end
			end
		end
	end
	for _, row in ipairs(rest) do
		out[#out + 1] = row
	end
	return out
end

local function number(value)
	local text = string.format("%.4f", value)
	text = string.gsub(text, "0+$", "")
	text = string.gsub(text, "%.$", "")
	if text == "-0" or text == "" or text == "-" then
		return "0"
	end
	return text
end

local function quote(value)
	local body = string.gsub(value, '[%c"\\]', function(char)
		if char == '"' then
			return '\\"'
		elseif char == "\\" then
			return "\\\\"
		end
		return string.format("\\%03d", string.byte(char))
	end)
	return '"' .. body .. '"'
end

function Mod.rowText(row)
	local parts = {}
	for _, key in ipairs(ROW_KEYS) do
		local value = row[key]
		if value ~= nil then
			if key == "align" or key == "rel" then
				local numbers = {}
				for i = 1, 6 do
					numbers[i] = number(value[i] or 0)
				end
				parts[#parts + 1] = key .. " = {" .. table.concat(numbers, ", ") .. "}"
			elseif key == "words" then
				local items = {}
				for _, word in ipairs(value) do
					items[#items + 1] = quote(word)
				end
				parts[#parts + 1] = "words = {" .. table.concat(items, ", ") .. "}"
			elseif key == "count" then
				parts[#parts + 1] = "count = " .. string.format("%d", value)
			else
				parts[#parts + 1] = key .. " = " .. quote(value)
			end
		end
	end
	return "{" .. table.concat(parts, ", ") .. "}"
end

local function sortedKeys(map)
	local keys = {}
	for key in pairs(map) do
		keys[#keys + 1] = key
	end
	table.sort(keys)
	return keys
end

function Mod.spotsText(spots)
	local out = {}
	if type(spots) ~= "table" then
		return out
	end
	local body = {}
	for _, script in ipairs(sortedKeys(spots)) do
		local tabs = spots[script]
		local tabLines = {}
		for _, tab in ipairs(sortedKeys(tabs)) do
			local hats = tabs[tab]
			local hatLines = {}
			for _, key in ipairs(sortedKeys(hats)) do
				local numbers = {}
				for i = 1, 6 do
					numbers[i] = number(hats[key][i] or 0)
				end
				hatLines[#hatLines + 1] = "\t\t\t\t[" .. quote(key) .. "] = {" .. table.concat(numbers, ", ") .. "},"
			end
			if #hatLines > 0 then
				tabLines[#tabLines + 1] = "\t\t\t[" .. quote(tab) .. "] = {"
				for _, line in ipairs(hatLines) do
					tabLines[#tabLines + 1] = line
				end
				tabLines[#tabLines + 1] = "\t\t\t},"
			end
		end
		if #tabLines > 0 then
			body[#body + 1] = "\t\t[" .. quote(script) .. "] = {"
			for _, line in ipairs(tabLines) do
				body[#body + 1] = line
			end
			body[#body + 1] = "\t\t},"
		end
	end
	if #body > 0 then
		out[1] = "\tspots = {"
		for _, line in ipairs(body) do
			out[#out + 1] = line
		end
		out[#out + 1] = "\t},"
	end
	return out
end

function Mod.serialize(data)
	local out = { "return {", "\tversion = " .. Mod.VERSION .. "," }
	if #data.rig > 0 then
		out[#out + 1] = "\trig = {"
		for _, row in ipairs(data.rig) do
			out[#out + 1] = "\t\t" .. Mod.rowText(row) .. ","
		end
		out[#out + 1] = "\t},"
	end
	local names = {}
	for name, list in pairs(data.scripts) do
		if #list > 0 then
			names[#names + 1] = name
		end
	end
	table.sort(names)
	if #names > 0 then
		out[#out + 1] = "\tscripts = {"
		for _, name in ipairs(names) do
			out[#out + 1] = "\t\t[" .. quote(name) .. "] = {"
			for _, row in ipairs(data.scripts[name]) do
				out[#out + 1] = "\t\t\t" .. Mod.rowText(row) .. ","
			end
			out[#out + 1] = "\t\t},"
		end
		out[#out + 1] = "\t},"
	end
	local shared = data.shared or {}
	local any = false
	local kinds = table.clone(Mod.SHARED)
	for kind in pairs(Mod.SHIPPED) do
		kinds[#kinds + 1] = kind
	end
	for _, kind in ipairs(kinds) do
		if #(shared[kind] or {}) > 0 then
			any = true
		end
	end
	if any then
		out[#out + 1] = "\tshared = {"
		for _, kind in ipairs(kinds) do
			local list = shared[kind] or {}
			if #list > 0 then
				out[#out + 1] = "\t\t" .. kind .. " = {"
				for _, row in ipairs(list) do
					local copy = {}
					for k, v in pairs(row) do
						copy[k] = v
					end
					copy.slot = nil
					out[#out + 1] = "\t\t\t" .. Mod.rowText(copy) .. ","
				end
				out[#out + 1] = "\t\t},"
			end
		end
		out[#out + 1] = "\t},"
	end
	for _, line in ipairs(Mod.spotsText(data.spots)) do
		out[#out + 1] = line
	end
	out[#out + 1] = "}"
	return table.concat(out, "\n") .. "\n"
end

local Service = {}
Service.__index = Service

function Mod.new(env)
	local self = setmetatable({}, Service)
	self.env = env or {}
	self.builtin = Mod.empty()
	self.userData = Mod.empty()
	self.merged = Mod.merge(self.builtin, self.userData)
	self.hats = {}
	self.failed = {}
	self.entries = {}
	self.pending = 0
	self.rev = 0
	self.source = "none"
	self.err = nil
	self.userErr = nil
	self.broken = nil
	self.problems = {}
	self.loaded = false
	return self
end

function Service:publish()
	if self.dead then
		return self.rev
	end
	self.merged = Mod.merge(self.builtin, self.userData)
	local list, pending = Mod.entries(self.merged, self.env.cframe, self.hats)
	self.entries = list
	self.pending = pending
	self.rev += 1
	if type(self.env.publish) == "function" then
		local me = self
		local info = {
			rev = self.rev,
			data = self.merged,
			cframe = self.env.cframe,
		}
		info.rows = function(script, slot)
			local out = {}
			for _, row in ipairs(Mod.rows(me.merged, script, slot)) do
				local known = row.hat and not row.mesh and not row.tex and me.hats[row.hat]
				if known then
					local copy = {}
					for key, value in pairs(row) do
						copy[key] = value
					end
					copy.mesh, copy.tex = known.mesh, known.tex
					out[#out + 1] = copy
				else
					out[#out + 1] = row
				end
			end
			return out
		end
		info.rigged = function(hat, e)
			if type(me.env.rigged) ~= "function" then
				return false
			end
			local ok, r = pcall(me.env.rigged, hat, e)
			return ok and r == true
		end
		info.match = function(script, slot, hat, e)
			local list = info.rows(script, slot)
			local rigged = nil
			local function allowed(row)
				if Mod.mine(row) then
					return true
				end
				if rigged == nil then
					rigged = info.rigged(hat, e)
				end
				return not rigged
			end
			for _, row in ipairs(list) do
				if Mod.matchJob(row, hat) and allowed(row) then
					return row
				end
			end
			for _, row in ipairs(list) do
				if row.src == "user" and Mod.matchJob(row, hat, true) and allowed(row) then
					return row
				end
			end
			return nil
		end
		info.weapon = function(hat)
			local ok, yes = pcall(Mod.weaponOf, me.merged, hat, me.hats)
			return ok and yes == true
		end
		info.mine = function(script, slot)
			local out = {}
			for _, row in ipairs(info.rows(script, slot)) do
				if row.src == "user" and (Mod.mine(row) or not ((row.mesh or row.tex) and info.rigged({ mesh = row.mesh, tex = row.tex }))) then
					out[#out + 1] = row
				end
			end
			return out
		end
		info.offset = function(row)
			local a = type(row) == "table" and row.align or nil
			if type(a) ~= "table" or type(me.env.cframe) ~= "function" then
				return nil
			end
			local ok, value = pcall(me.env.cframe, a[1] or 0, a[2] or 0, a[3] or 0, a[4] or 0, a[5] or 0, a[6] or 0)
			return ok and value or nil
		end
		info.hold = function(hat)
			local ok, out = pcall(Mod.holdOf, hat)
			return ok and out or nil
		end
		info.mate = function(hat)
			local ok, m = pcall(Mod.mateOf, me.merged, type(hat) == "table" and hat.mesh or nil)
			return ok and m or nil
		end
		info.join = function(fd, e)
			local ok, undo, other = pcall(Mod.join, fd, e, me.merged)
			if ok and type(undo) == "function" then
				return undo, other
			end
			return nil
		end
		pcall(self.env.publish, list, info)
		if type(self.env.freeWeapons) == "function" then
			pcall(self.env.freeWeapons)
		end
	end
	return self.rev
end

function Service:fetchBuiltin()
	local env = self.env
	if type(env.fetch) == "function" then
		local ok, body = env.fetch(Mod.BUILTIN_PATH)
		if ok and type(body) == "string" then
			local raw, why = Mod.parse(body)
			if raw then
				if type(env.saveCache) == "function" then
					pcall(env.saveCache, body)
				end
				self.err = nil
				return raw, "net"
			end
			self.err = "Alignment/alignment.lua: " .. tostring(why)
		else
			self.err = "couldn't get Alignment/alignment.lua"
		end
	else
		self.err = "no way to get Alignment/alignment.lua"
	end
	if type(env.readCache) == "function" then
		local ok, old = pcall(env.readCache)
		if ok and type(old) == "string" then
			local raw = Mod.parse(old)
			if raw then
				return raw, "cache"
			end
		end
	end
	return nil, "none"
end

function Service:readUser()
	local env = self.env
	self.userErr = nil
	self.broken = nil
	if type(env.readUser) ~= "function" then
		return Mod.empty()
	end
	local ok, body = pcall(env.readUser)
	if not ok or type(body) ~= "string" or body == "" then
		return Mod.empty()
	end
	local raw, why = Mod.parse(body)
	if not raw then
		self.userErr = tostring(why)
		self.broken = body
		return Mod.empty()
	end
	local data, problems = Mod.clean(raw)
	for _, text in ipairs(problems) do
		if #self.problems < 20 then
			self.problems[#self.problems + 1] = "your file, " .. text
		end
	end
	return data
end

function Service:load()
	self.problems = {}
	self.failed = {}
	local raw, source = self:fetchBuiltin()
	self.source = source
	if raw then
		local data, problems = Mod.clean(raw)
		self.builtin = data
		for _, text in ipairs(problems) do
			if #self.problems < 20 then
				self.problems[#self.problems + 1] = text
			end
		end
	else
		self.builtin = Mod.empty()
	end
	self.userData = self:readUser()
	self.loaded = true
	self:publish()
	return raw ~= nil, self:status()
end

function Service:status()
	return {
		rev = self.rev,
		source = self.source,
		err = self.err,
		userErr = self.userErr,
		rigRows = #self.builtin.rig,
		userRows = self:userCount(),
		published = #self.entries,
		pending = self.pending,
		waiting = #self:pendingIds(),
		lookupFailed = self:failedCount(),
		problems = self.problems,
		loaded = self.loaded,
	}
end

function Service:userCount()
	local total = #self.userData.rig
	for _, list in pairs(self.userData.scripts) do
		total += #list
	end
	for _, list in pairs(self.userData.shared or {}) do
		total += #list
	end
	return total
end

function Service:data()
	return self.merged
end

function Service:userRows(section, script)
	if section == "rig" then
		return self.userData.rig
	end
	if section == "shared" then
		return (self.userData.shared or {})[script] or {}
	end
	return self.userData.scripts[script] or {}
end

function Service:save()
	local env = self.env
	if type(env.writeUser) ~= "function" then
		return false, "this executor can't save files, so your hats stay only until you leave"
	end
	if self.broken then
		if type(env.writeBackup) == "function" then
			pcall(env.writeBackup, self.broken)
		end
		self.broken = nil
		self.userErr = nil
	end
	local ok, result = pcall(env.writeUser, Mod.serialize(self.userData))
	if not ok then
		return false, "couldn't save: " .. firstLine(result)
	end
	if result == false then
		return false, "couldn't save your hats"
	end
	return true
end

function Service:listFor(section, script, create)
	if section == "rig" then
		return self.userData.rig
	end
	if section == "shared" then
		if not Mod.SHARED_SLOTS[script] then
			return nil
		end
		self.userData.shared = self.userData.shared or {}
		local list = self.userData.shared[script]
		if not list then
			list = {}
			self.userData.shared[script] = list
		end
		return list
	end
	script = clean(script, 40)
	if not script then
		return nil
	end
	local list = self.userData.scripts[script]
	if not list and create then
		list = {}
		self.userData.scripts[script] = list
	end
	return list
end

function Service:add(section, script, row)
	local kind = section == "rig" and "rig" or "script"
	if section == "shared" then
		if not Mod.SHARED_SLOTS[script] then
			return false, "a hat for every script is any weapon, a gun, a sword, a shotgun or a rifle"
		end
		local copy = {}
		for k, v in pairs(type(row) == "table" and row or {}) do
			copy[k] = v
		end
		copy.slot = script
		row = copy
	end
	local cleaned, why = Mod.cleanRow(row, kind)
	if not cleaned then
		return false, why
	end
	local list = self:listFor(section, script, true)
	if not list then
		return false, "which script is it for?"
	end
	if #list >= Mod.MAX_USER_ROWS then
		return false, "you already have " .. Mod.MAX_USER_ROWS .. " rows here"
	end
	for _, existing in ipairs(list) do
		if Mod.sameRow(existing, cleaned) then
			return false, Mod.ALREADY
		end
	end
	list[#list + 1] = cleaned
	local saved, note = self:save()
	self:publish()
	return true, #list, saved, note
end

function Service:replace(section, script, index, row)
	local kind = section == "rig" and "rig" or "script"
	if section == "shared" then
		if not Mod.SHARED_SLOTS[script] then
			return false, "a hat for every script is any weapon, a gun, a sword, a shotgun or a rifle"
		end
		local copy = {}
		for k, v in pairs(type(row) == "table" and row or {}) do
			copy[k] = v
		end
		copy.slot = script
		row = copy
	end
	local cleaned, why = Mod.cleanRow(row, kind)
	if not cleaned then
		return false, why
	end
	local list = self:listFor(section, script, false)
	if not list or not list[index] then
		return false, "that row is gone"
	end
	for position, existing in ipairs(list) do
		if position ~= index and Mod.sameRow(existing, cleaned) then
			return false, Mod.ALREADY
		end
	end
	list[index] = cleaned
	local saved, note = self:save()
	self:publish()
	return true, index, saved, note
end

function Service:remove(section, script, index)
	local list = self:listFor(section, script, false)
	if not list or not list[index] then
		return false, "that row is gone"
	end
	table.remove(list, index)
	local saved, note = self:save()
	self:publish()
	return true, nil, saved, note
end

function Service:lookup(id)
	id = Mod.digits(id)
	if not id then
		return nil, "that is not a hat id"
	end
	local known = self.hats[id]
	if known then
		return known, nil, false
	end
	if type(self.env.resolveHat) ~= "function" then
		return nil, "this executor can't look catalog hats up, type the mesh id instead"
	end
	local ok, info, why = pcall(self.env.resolveHat, id)
	if not ok then
		return nil, firstLine(info)
	end
	if type(info) ~= "table" then
		return nil, why and firstLine(why) or "that hat could not be found"
	end
	local found = { mesh = Mod.extractId(info.mesh), tex = Mod.extractId(info.tex), name = clean(info.name, 80), att = Mod.cleanAtt(info.att) }
	if not found.mesh and not found.tex then
		return nil, "that hat has no mesh to line up"
	end
	self.hats[id] = found
	self.failed[id] = nil
	return found, nil, true
end

function Service:resolve(id)
	local found, why, fresh = self:lookup(id)
	if found and fresh then
		self:publish()
	end
	return found, why
end

function Service:failedCount()
	local total = 0
	for _ in pairs(self.failed) do
		total += 1
	end
	return total
end

function Service:pendingIds()
	local ids = {}
	local seen = {}
	local function consider(row)
		local id = row.hat
		if id and not row.mesh and not row.tex and not self.hats[id] and not self.failed[id] and not seen[id] then
			seen[id] = true
			ids[#ids + 1] = id
		end
	end
	for _, row in ipairs(self.merged.rig) do
		consider(row)
	end
	for _, rows in pairs(self.merged.scripts) do
		for _, row in ipairs(rows) do
			consider(row)
		end
	end
	return ids
end

function Service:resolvePending()
	local ids = self:pendingIds()
	local found = 0
	local failed = {}
	for index, id in ipairs(ids) do
		if self.dead or index > Mod.MAX_LOOKUPS then
			break
		end
		local info, why = self:lookup(id)
		if info then
			found += 1
		else
			self.failed[id] = why
			failed[#failed + 1] = { id = id, why = why }
		end
	end
	if found > 0 then
		self:publish()
	end
	return found, failed
end

function Service:fill(row)
	local out = {}
	for key, value in pairs(row) do
		out[key] = value
	end
	if out.hat and not out.mesh and not out.tex then
		local found, why = self:resolve(out.hat)
		if not found then
			return nil, why
		end
		out.mesh, out.tex = found.mesh, found.tex
		if not out.name then
			out.name = found.name
		end
	end
	return out
end

function Service:userText()
	return Mod.serialize(self.userData)
end

function Service:covering(hat)
	for _, row in ipairs(self.merged.rig) do
		if Mod.matches(row, hat) then
			return row
		end
	end
	return nil
end

function Service:spot(script, tab, key)
	local spots = self.userData.spots
	local one = spots and spots[script] and spots[script][tab] and spots[script][tab][key]
	if type(one) ~= "table" then
		return nil
	end
	return { one[1], one[2], one[3], one[4], one[5], one[6] }
end

function Service:spotCount(script, tab)
	local total = 0
	local spots = self.userData.spots or {}
	for name, tabs in pairs(spots) do
		if script == nil or name == script then
			for tabName, hats in pairs(tabs) do
				if tab == nil or tabName == tab then
					for _ in pairs(hats) do
						total += 1
					end
				end
			end
		end
	end
	return total
end

function Service:setSpot(script, tab, key, vals)
	script, tab = clean(script, 40), clean(tab, 24)
	key = clean(type(key) == "number" and tostring(key) or key, 60)
	local list = Mod.spotList(vals)
	if not (script and tab and key and list) then
		return false, "that spot can't be saved"
	end
	self.userData.spots = self.userData.spots or {}
	local spots = self.userData.spots
	local fresh = not (spots[script] and spots[script][tab] and spots[script][tab][key])
	if fresh and self:spotCount() >= Mod.MAX_SPOTS then
		return false, "you already have " .. Mod.MAX_SPOTS .. " saved hat spots"
	end
	spots[script] = spots[script] or {}
	spots[script][tab] = spots[script][tab] or {}
	spots[script][tab][key] = list
	return true
end

function Service:dropSpot(script, tab, key)
	local spots = self.userData.spots
	local hats = spots and spots[script] and spots[script][tab]
	if not (hats and hats[key]) then
		return false
	end
	hats[key] = nil
	if next(hats) == nil then
		spots[script][tab] = nil
		if next(spots[script]) == nil then
			spots[script] = nil
		end
	end
	return true
end

function Service:isUserHat(id)
	id = Mod.assetId(id)
	if not id then
		return false
	end
	local hats = self.hats
	local function hit(row)
		if type(row) ~= "table" then
			return false
		end
		if row.mesh == id or row.tex == id or row.hat == id then
			return true
		end
		local known = row.hat and hats[row.hat]
		return known ~= nil and (known.mesh == id or known.tex == id)
	end
	for _, row in ipairs(self.userData.rig or {}) do
		if hit(row) then
			return true
		end
	end
	for _, list in pairs(self.userData.scripts or {}) do
		for _, row in ipairs(list) do
			if hit(row) then
				return true
			end
		end
	end
	for _, list in pairs(self.userData.shared or {}) do
		for _, row in ipairs(list) do
			if hit(row) then
				return true
			end
		end
	end
	return false
end

function Service:detect(row)
	if type(row) ~= "table" then
		return nil
	end
	if Mod.known(row) then
		return "gun", "known"
	end
	local probe = { mesh = row.mesh, tex = row.tex }
	local kinds = {}
	if probe.mesh or probe.tex then
		local function look(list, slot)
			for _, r in ipairs(type(list) == "table" and list or {}) do
				local kind = Mod.WEAPON_OF[slot or r.slot]
				if kind and (r.mesh or r.tex) and not r.acc and Mod.matches(r, probe) then
					kinds[kind] = true
				end
			end
		end
		for _, list in pairs(self.builtin.scripts or {}) do
			look(list)
		end
		for kind, list in pairs(self.builtin.shared or {}) do
			if kind ~= "any" then
				look(list, kind)
			end
		end
	end
	if kinds.gun and not kinds.sword then
		return "gun", "list"
	end
	if kinds.sword and not kinds.gun then
		return "sword", "list"
	end
	local byName = Mod.kindFromName(row.name)
	if byName then
		return byName, "name"
	end
	for _, token in ipairs(Mod.nameTokens(row.name)) do
		if token == "book" or token == "books" then
			return "book", "name"
		end
	end
	return nil
end

local Tracker = {}
Tracker.__index = Tracker

local function sameSpot(a, b)
	if type(a) ~= "table" or type(b) ~= "table" then
		return a == b
	end
	for i = 1, 6 do
		if math.abs((tonumber(a[i]) or 0) - (tonumber(b[i]) or 0)) > 0.00001 then
			return false
		end
	end
	return true
end

function Mod.tracker(svc, a, hooks)
	if type(svc) ~= "table" or type(a) ~= "table" or type(a.hat) ~= "function" or type(a.get) ~= "function" or type(a.put) ~= "function" then
		return nil
	end
	local tabs = type(a.tabs) == "table" and a.tabs or {}
	local t = setmetatable({
		svc = svc,
		a = a,
		hooks = type(hooks) == "table" and hooks or {},
		title = clean(tostring(a.title or ""), 40) or "Script",
		tabs = tabs,
		last = {},
		vals = {},
		base = {},
		names = {},
		how = {},
		dirty = false,
	}, Tracker)
	for s = 1, #tabs do
		local ok, v = pcall(a.get, s)
		t.base[s] = ok and Mod.spotList(v) or nil
	end
	return t
end

function Tracker:tabName(s)
	return clean(tostring(self.tabs[s] or s), 24) or tostring(s)
end

function Tracker:read(s)
	local ok, v = pcall(self.a.get, s)
	return ok and Mod.spotList(v) or nil
end

function Tracker:held(s)
	local ok, key, mesh, name, keep = pcall(self.a.hat, s)
	if not ok then
		return nil
	end
	if type(key) == "number" then
		key = tostring(key)
	end
	key = clean(key, 60)
	return key, mesh, name, keep
end

function Tracker:keyOf(s)
	return self.last[s]
end

function Tracker:nameOf(s)
	return self.names[s] or self.last[s]
end

function Tracker:fire(name, ...)
	local f = self.hooks[name]
	if type(f) == "function" then
		pcall(f, ...)
	end
end

function Tracker:defaultSpot(s)
	if type(self.a.reset) == "function" then
		pcall(self.a.reset, s)
	else
		pcall(self.a.put, s, { 0, 0, 0, 0, 0, 0 })
	end
end

function Tracker:switch(s, key, mesh, name, keep)
	self.last[s] = key
	self.names[s] = type(name) == "string" and name ~= "" and name or nil
	if not key then
		self.vals[s] = nil
		self.how[s] = nil
		self:fire("switch", s, nil, nil, nil)
		return nil
	end
	local tab = self:tabName(s)
	local saved = self.svc:spot(self.title, tab, key)
	local how
	if saved then
		pcall(self.a.put, s, saved)
		how = "saved"
	elseif self.svc:isUserHat(mesh or key) then
		self:defaultSpot(s)
		how = "new"
	elseif self.svc:spotCount(self.title, tab) == 0 then
		local start = keep and self:read(s) or self.base[s]
		if start then
			if not keep then
				pcall(self.a.put, s, start)
			end
			if self.svc:setSpot(self.title, tab, key, start) then
				self.dirty = true
				self:fire("changed")
			end
			how = "kept"
		else
			self:defaultSpot(s)
			how = "new"
		end
	else
		self:defaultSpot(s)
		how = "new"
	end
	self.vals[s] = self:read(s)
	self.how[s] = how
	self:fire("switch", s, key, how, self.names[s])
	return how
end

function Tracker:record(s, vals)
	local key = self.last[s]
	if not key or not vals then
		return false
	end
	self.vals[s] = vals
	if self.svc:setSpot(self.title, self:tabName(s), key, vals) then
		self.dirty = true
		self:fire("changed")
		return true
	end
	return false
end

function Tracker:tick()
	for s = 1, #self.tabs do
		local key, mesh, name, keep = self:held(s)
		if key ~= self.last[s] then
			self:switch(s, key, mesh, name, keep)
		elseif key then
			local now = self:read(s)
			if now and not sameSpot(now, self.vals[s]) then
				self:record(s, now)
			end
		end
	end
end

function Tracker:reload(s)
	local key = self.last[s]
	if not key then
		return nil
	end
	local saved = self.svc:spot(self.title, self:tabName(s), key)
	if saved then
		pcall(self.a.put, s, saved)
	else
		self:defaultSpot(s)
	end
	self.vals[s] = self:read(s)
	return saved and "saved" or "new"
end

function Tracker:forget(s)
	local key = self.last[s]
	if not key then
		return false
	end
	local dropped = self.svc:dropSpot(self.title, self:tabName(s), key)
	self:defaultSpot(s)
	self.vals[s] = self:read(s)
	if dropped then
		self.dirty = true
		self:fire("changed")
	end
	return dropped
end

local function handleOf(item)
	if item:IsA("Accessory") then
		return item:FindFirstChild("Handle")
	end
	if item:IsA("BasePart") and item.Name == "Handle" then
		return item
	end
	local accessory = item:FindFirstChildWhichIsA("Accessory", true)
	if accessory then
		return accessory:FindFirstChild("Handle")
	end
	return nil
end

function Mod.handleInfo(handle)
	if not handle then
		return nil
	end
	local mesh, tex
	if handle:IsA("MeshPart") then
		mesh, tex = handle.MeshId, handle.TextureID
	else
		local special = handle:FindFirstChildOfClass("SpecialMesh")
		if special then
			mesh, tex = special.MeshId, special.TextureId
		end
	end
	return Mod.extractId(mesh), Mod.extractId(tex)
end

function Mod.wornHats(character)
	local list = {}
	if not character then
		return list
	end
	for _, item in ipairs(character:GetChildren()) do
		if item:IsA("Accoutrement") then
			local handle = item:FindFirstChild("Handle")
			local mesh, tex = Mod.handleInfo(handle)
			list[#list + 1] = { name = item.Name, mesh = mesh, tex = tex, att = Mod.attachOf(handle) }
			if #list >= Mod.MAX_WORN then
				break
			end
		end
	end
	return list
end

function Mod.hubEnv(c)
	local env = {}
	local localRoot = c.Origin and c.Origin.root
	env.fetch = function(rel)
		return c.Net.get(c.Repo.raw(rel) .. "?t=" .. os.time())
	end
	if c.HAS_FS and c.FS then
		if not localRoot then
			env.saveCache = function(body)
				return c.FS.write(Mod.CACHE_FILE, body)
			end
			env.readCache = function()
				return c.FS.read(Mod.CACHE_FILE)
			end
		end
		env.readUser = function()
			return c.FS.read(Mod.USER_FILE)
		end
		env.writeUser = function(text)
			return c.FS.write(Mod.USER_FILE, text)
		end
		env.writeBackup = function(text)
			return c.FS.write(Mod.BROKEN_FILE, text)
		end
	end
	env.cframe = c.cframe or function(x, y, z, rx, ry, rz)
		return CFrame.new(x, y, z) * CFrame.Angles(math.rad(rx), math.rad(ry), math.rad(rz))
	end
	env.resolveHat = c.resolveHat or function(id)
		local ok, objects = pcall(function()
			return game:GetObjects("rbxassetid://" .. id)
		end)
		if not ok or type(objects) ~= "table" then
			return nil, "this executor can't look catalog hats up"
		end
		local result, why = nil, "that hat could not be found"
		for _, item in ipairs(objects) do
			if not result then
				local handle = handleOf(item)
				if handle then
					local mesh, tex = Mod.handleInfo(handle)
					if mesh or tex then
						result = { mesh = mesh, tex = tex, name = item.Name, att = Mod.attachOf(handle) }
					else
						why = "that hat has no mesh to line up"
					end
				end
			end
		end
		for _, item in ipairs(objects) do
			pcall(function()
				item:Destroy()
			end)
		end
		return result, why
	end
	local function genvOf()
		local genv = c.GENV
		if not genv then
			genv = (typeof(getgenv) == "function" and getgenv()) or _G
		end
		return genv
	end
	env.publish = function(list, info)
		local genv = genvOf()
		genv.AtsukoAligns = list
		genv.AtsukoAlignment = info
	end
	env.rigged = function(hat, e)
		local f = genvOf().AtsukoRigHats
		if type(f) ~= "function" then
			return false
		end
		return f(hat, e) == true
	end
	env.freeWeapons = function()
		local f = genvOf().AtsukoFreeWeapons
		if type(f) == "function" then
			return f()
		end
		return 0
	end
	return env
end

function Mod.init(context)
	ctx = context
	current = Mod.new(Mod.hubEnv(context))
	Mod.service = current
end

Mod.PART_WORDS = {
	head = "Head",
	torso = "Torso",
	leftarm = "Left Arm",
	larm = "Left Arm",
	rightarm = "Right Arm",
	rarm = "Right Arm",
	leftleg = "Left Leg",
	lleg = "Left Leg",
	rightleg = "Right Leg",
	rleg = "Right Leg",
}
Mod.TWO_GUNS = "Snake Banisher V3"
Mod.SCRIPT_WORDS = { book = { "Book Reader", "book" }, books = { "Book Reader", "book" } }
Mod.USE_WORDS = { gun1 = "gun1", gun2 = "gun2", firstgun = "gun1", secondgun = "gun2", lcgun1 = "gun1", lcgun2 = "gun2" }
Mod.MAX_ADD = 8

function Mod.useOf(word, index, count)
	if word == nil then
		return "shared", "any"
	end
	word = Mod.normWord(word)
	if word == "" then
		return nil
	end
	if Mod.ANY_WORDS[word] then
		return "shared", "any"
	end
	if Mod.PAIR_WORDS[word] then
		return "script", Mod.TWO_GUNS, nil, (index or 1) == 1 and "gun1" or "gun2"
	end
	local part = Mod.PART_WORDS[word]
	if part then
		return "rig", nil, part
	end
	local two = Mod.USE_WORDS[word]
	if two then
		return "script", Mod.TWO_GUNS, nil, two
	end
	local own = Mod.SCRIPT_WORDS[word]
	if own then
		return "script", own[1], nil, own[2]
	end
	if Mod.SHARED_SLOTS[word] then
		return "shared", word
	end
	return nil
end

function Mod.useText(section, target, part, slot)
	if section == "rig" then
		return part
	end
	if section == "script" then
		if target ~= Mod.TWO_GUNS then
			return target .. "'s " .. tostring(slot)
		end
		return target .. " " .. (slot == "gun2" and "gun 2" or "gun 1")
	end
	if target == "any" then
		return "gun and sword in every script"
	end
	return tostring(target) .. " in every script with a " .. tostring(target)
end

Mod.GUESS_NOTE = "add picked this job from the hat"
Mod.ALREADY = "that row is already there"
Mod.JOB_LIST = "any, gun, sword, shotgun, rifle, book, pair, gun1, gun2, head, torso, leftarm, rightarm, leftleg or rightleg"
Mod.MAX_AT = 1440

function Mod.parseAdd(text)
	local words = {}
	for word in string.gmatch(tostring(text or ""), "%S+") do
		words[#words + 1] = word
	end
	local out = { ids = {}, use = nil, align = nil, aligns = {} }
	local waiting = nil
	local function setUse(word)
		if out.use ~= nil and Mod.normWord(out.use) ~= Mod.normWord(word) then
			return false
		end
		out.use = string.lower(word)
		return true
	end
	local function twoWord(i)
		local a = words[i] and string.lower(words[i]) or nil
		local b = words[i + 1] and string.lower(words[i + 1]) or nil
		if (a == "left" or a == "right") and (b == "arm" or b == "leg") then
			return a .. b
		end
		return nil
	end
	local i = 1
	while i <= #words do
		local low = string.lower(words[i])
		if low == "as" or low == "for" then
			if words[i + 1] == nil then
				return nil, "say what the hats are for, like add sword 4506945409 or add 4506945409 as gun"
			end
			local word = twoWord(i + 1)
			local used = word and 3 or 2
			word = word or string.lower(words[i + 1])
			if not Mod.useOf(word, 1, 1) then
				return nil, word .. " is not something a hat can be. Use " .. Mod.JOB_LIST
			end
			if not setUse(word) then
				return nil, "one job per add, like add sword 4506945409 or add gun 4506945409"
			end
			i += used
		elseif low == "at" then
			local nums = {}
			local j = i + 1
			while j <= #words and #nums < 6 do
				local n = tonumber(words[j])
				if not n or not finite(n) or math.abs(n) > Mod.MAX_AT then
					break
				end
				nums[#nums + 1] = n
				j += 1
			end
			if #nums < 3 then
				return nil, "at needs x y z, and rx ry rz if you want to turn it"
			end
			if #out.ids > 0 then
				if out.aligns[#out.ids] then
					return nil, "one at per hat, put it right after the id it moves"
				end
				out.aligns[#out.ids] = nums
			elseif waiting then
				return nil, "one at per hat, put it right after the id it moves"
			else
				waiting = nums
			end
			i = j
		elseif twoWord(i) then
			if not setUse(twoWord(i)) then
				return nil, "one job per add, like add sword 4506945409 or add gun 4506945409"
			end
			i += 2
		else
			local id = Mod.extractId(words[i])
			if id then
				out.ids[#out.ids + 1] = id
				if waiting then
					out.aligns[#out.ids] = waiting
					waiting = nil
				end
			elseif Mod.useOf(words[i], 1, 1) then
				if not setUse(words[i]) then
					return nil, "one job per add, like add sword 4506945409 or add gun 4506945409"
				end
			else
				return nil, words[i] .. " is not a hat id, a mesh id, a hat link or a job. Jobs are " .. Mod.JOB_LIST
			end
			i += 1
		end
	end
	if #out.ids == 0 then
		return nil, "give a hat id, like add 4506945409 or add sword 4506945409"
	end
	if waiting then
		return nil, "at goes right after the id it moves, like add 4506945409 at 0 1 0"
	end
	if #out.ids > Mod.MAX_ADD then
		return nil, "add " .. Mod.MAX_ADD .. " hats at most at once"
	end
	out.align = out.aligns[1]
	return out
end

Mod.JOIN_WORDS = { gun = true, sword = true, rifle = true, shotgun = true }

function Mod.pairIn(items, use)
	local word = use and Mod.normWord(use) or nil
	local mode
	if word == nil or Mod.ANY_WORDS[word] or word == "gun" then
		mode = "all"
	elseif Mod.PAIR_WORDS[word] then
		mode = "pair"
	elseif not Mod.JOIN_WORDS[word] then
		return nil
	end
	if mode then
		for _, a in ipairs(items) do
			local first = not a.why and Mod.known(a.row)
			if first and first.half == 1 then
				for _, b in ipairs(items) do
					local second = b ~= a and not b.why and Mod.known(b.row)
					if second and second.half == 2 and Mod.assetId(b.row.mesh) == first.mate then
						return a, b, mode
					end
				end
			end
		end
	end
	if mode == "pair" or #items ~= 2 then
		return nil
	end
	local a, b = items[1], items[2]
	if a.why or b.why or a.later or b.later or not a.row.mesh or not b.row.mesh or a.row.mesh == b.row.mesh then
		return nil
	end
	if not Mod.partsOf(a.row.name, b.row.name) then
		return nil
	end
	local na = tonumber(string.match(a.row.name, "(%d+)"))
	local nb = tonumber(string.match(b.row.name, "(%d+)"))
	if na and nb and nb < na then
		a, b = b, a
	end
	return a, b, "joined"
end

function Service:addJoined(lead, mate, parsed, report, only)
	local rel = Mod.pairRel(lead.att, mate.att)
	local nameA = lead.row.name or lead.id
	local nameB = mate.row.name or mate.id
	if not rel then
		report.note = "couldn't tell how " .. nameA .. " and " .. nameB .. " fit together, so they were added as two hats"
		return
	end
	lead.done, mate.done = true, true
	local word = parsed.use and Mod.normWord(parsed.use) or nil
	local want = word and Mod.JOIN_WORDS[word] and word or nil
	if not want then
		want = self:detect(lead.row) or self:detect(mate.row)
	end
	if not want then
		local k = Mod.kindFromName(lead.row.name) or Mod.kindFromName(mate.row.name)
		if k == "gun" or k == "sword" then
			want = k
		end
	end
	local section, target, slot
	if only then
		slot = Mod.slotIn(only.slots, want)
		if not slot and not word then
			slot = Mod.slotIn(only.slots, nil)
		end
		if not slot then
			report.failed[#report.failed + 1] = lead.id .. " + " .. mate.id .. ": " .. only.name .. " has no " .. tostring(want or "gun or sword") .. " to put it on"
			return
		end
		section, target = "script", only.name
	else
		if not (want and Mod.SHARED_SLOTS[want]) then
			report.failed[#report.failed + 1] = lead.id .. " + " .. mate.id .. ": say add gun or add sword with both ids"
			return
		end
		section, target, slot = "shared", want, want
	end
	local row = lead.row
	local ok, result, saved, note = self:add(section, target, { slot = slot, hat = row.hat, mesh = row.mesh, tex = row.tex, name = row.name, align = row.align, mate = mate.row.mesh, rel = rel })
	if not ok and result ~= Mod.ALREADY then
		report.failed[#report.failed + 1] = lead.id .. " + " .. mate.id .. ": " .. tostring(result)
		return
	end
	if saved == false and note then
		report.note = note
	end
	local use = (section == "script" and (target .. "'s " .. slot) or ("every script's " .. slot)) .. ", with both parts joined"
	report.added[#report.added + 1] = { id = lead.id .. " + " .. mate.id, name = nameA .. " + " .. nameB, use = use, section = section, target = target, pair = true, joined = true, replaced = 0, already = not ok }
end

function Service:dropHats(meshes, ids)
	local function hit(row)
		return type(row) == "table" and ((row.mesh and meshes[row.mesh]) or (row.hat and ids[row.hat])) and not row.align
	end
	local dropped = 0
	local function sweep(list, slots)
		if type(list) ~= "table" then
			return
		end
		for i = #list, 1, -1 do
			if (not slots or slots[list[i].slot]) and hit(list[i]) then
				table.remove(list, i)
				dropped += 1
			end
		end
	end
	for _, list in pairs(self.userData.shared or {}) do
		sweep(list)
	end
	sweep(self.userData.scripts[Mod.TWO_GUNS], { gun1 = true, gun2 = true })
	return dropped
end

function Service:addPair(lead, mate, parsed, report, mode)
	local function base(item, slot)
		local row = item.row
		return { slot = slot, hat = row.hat, mesh = row.mesh, tex = row.tex, name = row.name, align = row.align }
	end
	local meshes = { [Mod.assetId(lead.row.mesh)] = true, [Mod.assetId(mate.row.mesh)] = true }
	local ids = {}
	for _, item in ipairs({ lead, mate }) do
		if item.row.hat then
			ids[item.row.hat] = true
		end
	end
	local dropped = mode == "all" and self:dropHats(meshes, ids) or 0
	local jobs = {}
	if mode == "all" then
		jobs[#jobs + 1] = { "shared", "gun", base(lead) }
	end
	jobs[#jobs + 1] = { "script", Mod.TWO_GUNS, base(lead, "gun1") }
	jobs[#jobs + 1] = { "script", Mod.TWO_GUNS, base(mate, "gun2") }
	local fails = {}
	local any = false
	local already = true
	for _, job in ipairs(jobs) do
		local ok, result, saved, note = self:add(job[1], job[2], job[3])
		if ok then
			any = true
			already = false
			if saved == false and note then
				report.note = note
			end
		elseif result ~= Mod.ALREADY then
			already = false
			fails[#fails + 1] = tostring(result)
		end
	end
	if dropped > 0 and not any then
		local saved, note = self:save()
		self:publish()
		if saved == false and note then
			report.note = note
		end
	end
	local nameA = lead.row.name or Mod.KNOWN[Mod.assetId(lead.row.mesh)].name
	local nameB = mate.row.name or Mod.KNOWN[Mod.assetId(mate.row.mesh)].name
	if #fails > 0 and not any then
		report.failed[#report.failed + 1] = lead.id .. " + " .. mate.id .. ": " .. fails[1]
	else
		local use = mode == "all" and Mod.TWO_PART_USE or (Mod.TWO_GUNS .. " gun 1 and gun 2")
		report.added[#report.added + 1] = { id = lead.id .. " + " .. mate.id, name = nameA .. " + " .. nameB, use = use, section = mode == "all" and "shared" or "script", target = mode == "all" and "gun" or Mod.TWO_GUNS, pair = true, replaced = dropped, already = already and not any and dropped == 0 }
	end
	lead.done, mate.done = true, true
end

Mod.WEAPON_SLOTS = { "gun", "sword", "rifle", "shotgun", "gun1", "book" }

local function slotSet(slots)
	local has = {}
	for _, slot in ipairs(type(slots) == "table" and slots or {}) do
		has[slot] = true
	end
	return has
end

function Mod.weaponCount(slots)
	local has, n = slotSet(slots), 0
	for _, slot in ipairs(Mod.WEAPON_SLOTS) do
		if has[slot] then
			n += 1
		end
	end
	return n
end

function Mod.slotIn(slots, want)
	local has = slotSet(slots)
	if want == nil or want == "any" then
		for _, slot in ipairs(Mod.WEAPON_SLOTS) do
			if has[slot] then
				return slot
			end
		end
		return nil
	end
	if has[want] then
		return want
	end
	if want == "gun" then
		for _, slot in ipairs({ "gun1", "rifle", "shotgun" }) do
			if has[slot] then
				return slot
			end
		end
	elseif want == "rifle" or want == "shotgun" then
		if has.gun then
			return "gun"
		end
		local other = want == "rifle" and "shotgun" or "rifle"
		if has[other] then
			return other
		end
	end
	return nil
end

function Service:dropOther(row, rig)
	if type(row) ~= "table" or not (row.mesh or row.hat) then
		return 0
	end
	local dropped = 0
	local function sweep(list)
		if type(list) ~= "table" then
			return
		end
		for i = #list, 1, -1 do
			local r = list[i]
			if type(r) == "table" and ((row.mesh and r.mesh == row.mesh) or (row.hat and r.hat == row.hat)) then
				table.remove(list, i)
				dropped += 1
			end
		end
	end
	if rig then
		for _, list in pairs(self.userData.scripts or {}) do
			sweep(list)
		end
		for _, list in pairs(self.userData.shared or {}) do
			sweep(list)
		end
	else
		sweep(self.userData.rig)
	end
	return dropped
end

function Service:dropScriptGuesses(script, row, keep)
	local list = self.userData.scripts and self.userData.scripts[script]
	local dropped = 0
	if type(list) ~= "table" then
		return 0
	end
	for i = #list, 1, -1 do
		local r = list[i]
		local same = (row.mesh and r.mesh == row.mesh) or (row.hat and r.hat == row.hat)
		if same and r.slot ~= keep and r.note == Mod.GUESS_NOTE then
			table.remove(list, i)
			dropped += 1
		end
	end
	return dropped
end

function Service:addPairTo(lead, mate, report, only)
	local has = slotSet(only.slots)
	local jobs
	if has.gun1 and has.gun2 then
		jobs = { { lead, "gun1" }, { mate, "gun2" } }
	else
		local slot = Mod.slotIn(only.slots, "gun")
		if slot and not Mod.NO_HALVES[slot] then
			jobs = { { lead, slot } }
		end
	end
	lead.done, mate.done = true, true
	if not jobs then
		report.failed[#report.failed + 1] = lead.id .. " + " .. mate.id .. ": " .. only.name .. " can't hold a two part gun"
		return
	end
	local fails, any = {}, false
	for _, job in ipairs(jobs) do
		local row = job[1].row
		local ok, result, saved, note = self:add("script", only.name, { slot = job[2], hat = row.hat, mesh = row.mesh, tex = row.tex, name = row.name, align = row.align })
		if ok then
			any = true
			if saved == false and note then
				report.note = note
			end
		elseif result ~= Mod.ALREADY then
			fails[#fails + 1] = tostring(result)
		end
	end
	if #fails > 0 and not any then
		report.failed[#report.failed + 1] = lead.id .. " + " .. mate.id .. ": " .. fails[1]
		return
	end
	local nameA = lead.row.name or Mod.KNOWN[Mod.assetId(lead.row.mesh)].name
	local nameB = mate.row.name or Mod.KNOWN[Mod.assetId(mate.row.mesh)].name
	local use = #jobs == 2 and (only.name .. " gun 1 and gun 2") or (only.name .. "'s gun, with both halves joined")
	report.added[#report.added + 1] = { id = lead.id .. " + " .. mate.id, name = nameA .. " + " .. nameB, use = use, section = "script", target = only.name, pair = true, replaced = 0, already = not any }
end

function Service:addIds(parsed, worn, only)
	if type(parsed) ~= "table" or type(parsed.ids) ~= "table" or #parsed.ids == 0 then
		return nil, "no hat ids"
	end
	if only ~= nil and (type(only) ~= "table" or type(only.name) ~= "string" or only.name == "") then
		only = nil
	end
	if not Mod.useOf(parsed.use, 1, #parsed.ids) then
		return nil, tostring(parsed.use) .. " is not something a hat can be"
	end
	local report = { added = {}, failed = {}, unsure = {}, note = nil, later = 0 }
	local items = {}
	for index, id in ipairs(parsed.ids) do
		local align = nil
		if type(parsed.aligns) == "table" then
			align = parsed.aligns[index]
		elseif index == 1 or #parsed.ids == 1 then
			align = parsed.align
		end
		local row = { align = align }
		local item = { id = id, index = index, row = row }
		local hit = nil
		for _, hat in ipairs(type(worn) == "table" and worn or {}) do
			if hat.mesh == id or hat.tex == id or (hat.hat ~= nil and hat.hat == id) then
				hit = hat
				break
			end
		end
		if hit then
			row.mesh, row.tex, row.name = hit.mesh, hit.tex, hit.name
			item.att = Mod.cleanAtt(hit.att)
		else
			local found, reason = self:lookup(id)
			if found then
				row.hat, row.mesh, row.tex, row.name = id, found.mesh, found.tex, found.name
				item.att = found.att
			elseif type(self.env.resolveHat) ~= "function" or (reason and string.find(reason, "can't look", 1, true)) then
				row.hat = id
				item.later = true
			else
				item.why = reason or "that hat could not be found"
			end
		end
		items[#items + 1] = item
	end
	local lead, mate, mode = Mod.pairIn(items, parsed.use)
	if lead and mode == "joined" then
		self:addJoined(lead, mate, parsed, report, only)
	elseif lead and only then
		self:addPairTo(lead, mate, report, only)
	elseif lead then
		self:addPair(lead, mate, parsed, report, mode)
	end
	for _, item in ipairs(items) do
		if not item.done then
			local id, row = item.id, item.row
			local use, guess, how = parsed.use, nil, nil
			if use == nil and not item.why then
				guess, how = self:detect(row)
				use = guess or "any"
			end
			local section, target, part, slot = Mod.useOf(use, item.index, #parsed.ids)
			local refused = nil
			local unsure = false
			if only and section ~= "rig" and not item.why then
				local want = section == "shared" and target or slot
				local fits = (section == "shared" or target == only.name) and Mod.slotIn(only.slots, want) or nil
				if not fits and parsed.use == nil then
					fits = Mod.slotIn(only.slots, nil)
				end
				if not fits then
					refused = section == "script" and target ~= only.name and (tostring(use) .. " is for " .. target .. ", start it to add one") or (only.name .. " has no " .. (want == "any" and "gun or sword" or tostring(want)) .. " to put it on")
				else
					unsure = parsed.use == nil and guess == nil and Mod.weaponCount(only.slots) > 1
					section, target, slot = "script", only.name, fits
				end
			end
			row.part, row.slot = part, slot
			if item.later then
				report.later += 1
			end
			if item.why or refused then
				report.failed[#report.failed + 1] = id .. ": " .. (item.why or refused)
			elseif only and section == "script" then
				if guess or unsure then
					row.note = Mod.GUESS_NOTE
				end
				local dropped = self:dropScriptGuesses(target, row, slot) + self:dropOther(row, false)
				local ok, result, saved, note = self:add(section, target, row)
				local entry = { id = id, name = row.name, use = Mod.useText(section, target, part, slot), section = section, target = target, slot = slot, guess = guess, how = how, replaced = dropped }
				if ok then
					report.added[#report.added + 1] = entry
					if saved == false and note then
						report.note = note
					end
				else
					if dropped > 0 then
						local savedNow, noteNow = self:save()
						self:publish()
						if savedNow == false and noteNow then
							report.note = noteNow
						end
					end
					if result == Mod.ALREADY then
						entry.already = dropped == 0
						report.added[#report.added + 1] = entry
					else
						report.failed[#report.failed + 1] = id .. ": " .. tostring(result)
					end
				end
				if unsure and (ok or dropped > 0) then
					report.unsure[#report.unsure + 1] = { id = id, name = row.name, script = target }
				end
			else
				local dropped, oldAlign = 0, nil
				if guess then
					row.note = Mod.GUESS_NOTE
				end
				if section == "shared" then
					dropped, oldAlign = self:dropGuesses(row, target)
					if row.align == nil and oldAlign then
						row.align = oldAlign
					end
				end
				dropped += self:dropOther(row, section == "rig")
				local ok, result, saved, note = self:add(section, target, row)
				local entry = { id = id, name = row.name, use = Mod.useText(section, target, part, slot), section = section, target = target, slot = slot, guess = guess, how = how, replaced = dropped }
				if ok then
					report.added[#report.added + 1] = entry
					if saved == false and note then
						report.note = note
					end
				elseif dropped > 0 then
					local savedNow, noteNow = self:save()
					self:publish()
					if result == Mod.ALREADY then
						report.added[#report.added + 1] = entry
					else
						report.failed[#report.failed + 1] = id .. ": " .. tostring(result)
					end
					if savedNow == false and noteNow then
						report.note = noteNow
					end
				elseif result == Mod.ALREADY then
					entry.already = true
					report.added[#report.added + 1] = entry
				else
					report.failed[#report.failed + 1] = id .. ": " .. tostring(result)
				end
				if (ok or dropped > 0) and parsed.use == nil and guess == nil and section == "shared" then
					report.unsure[#report.unsure + 1] = { id = id, name = row.name }
				end
			end
		end
	end
	return report
end

function Service:dropGuesses(row, keep)
	if type(row) ~= "table" then
		return 0, nil
	end
	local dropped, align = 0, nil
	for _, kind in ipairs(Mod.SHARED) do
		local list = kind ~= keep and self.userData.shared and self.userData.shared[kind] or nil
		if type(list) == "table" then
			for i = #list, 1, -1 do
				local r = list[i]
				local same = (row.mesh and r.mesh == row.mesh) or (row.hat and r.hat == row.hat)
				if same and (kind == "any" or r.note == Mod.GUESS_NOTE) then
					align = align or r.align
					table.remove(list, i)
					dropped += 1
				end
			end
		end
	end
	return dropped, align
end

function Mod.fdHats(api)
	local list = {}
	local frames = nil
	if type(api) == "table" then
		local ok, found = pcall(function()
			return api.cframes
		end)
		frames = ok and found or nil
	end
	if type(frames) ~= "table" then
		return list
	end
	for e in pairs(frames) do
		if type(e) == "table" then
			local m = rawget(e, "m")
			local mesh = m ~= nil and Mod.assetId(tostring(m)) or nil
			if mesh then
				local name = nil
				pcall(function()
					name = rawget(e, "p").Parent.Name
				end)
				local t = rawget(e, "t")
				list[#list + 1] = { mesh = mesh, tex = t ~= nil and Mod.assetId(tostring(t)) or nil, name = type(name) == "string" and name or nil }
				if #list >= Mod.MAX_WORN then
					break
				end
			end
		end
	end
	return list
end

function Mod.joinWorn(...)
	local out, seen = {}, {}
	for i = 1, select("#", ...) do
		local list = select(i, ...)
		for _, hat in ipairs(type(list) == "table" and list or {}) do
			local key = tostring(hat.mesh or "") .. "|" .. tostring(hat.tex or "")
			if (hat.mesh or hat.tex) and not seen[key] then
				seen[key] = true
				out[#out + 1] = hat
			elseif seen[key] and hat.name then
				for _, old in ipairs(out) do
					if tostring(old.mesh or "") .. "|" .. tostring(old.tex or "") == key and not old.name then
						old.name = hat.name
					end
				end
			end
		end
	end
	return out
end

function Mod.destroy()
	if current then
		current.dead = true
		if current.env and type(current.env.publish) == "function" then
			pcall(current.env.publish, nil, nil)
		end
	end
	current = nil
	Mod.service = nil
	ctx = nil
end

return Mod
