local Prefix = {}

Prefix.DEFAULT = ";"
Prefix.GUARD = 0.35
Prefix.ALLOWED = ";:!.,?-+=~^*$%&><|'\"[]{}()_@#"
Prefix.RELOAD = "-reload"

Prefix.KEY_CHARS = {
	Semicolon = ";", Quote = "'", Comma = ",", Period = ".", Slash = "/", BackSlash = "\\", Minus = "-", Equals = "=",
	LeftBracket = "[", RightBracket = "]", Backquote = "`",
	One = "1", Two = "2", Three = "3", Four = "4", Five = "5", Six = "6", Seven = "7", Eight = "8", Nine = "9", Zero = "0",
}

Prefix.SHIFTED = {
	Semicolon = ":", Quote = "\"", Comma = "<", Period = ">", Slash = "?", BackSlash = "|", Minus = "_", Equals = "+",
	LeftBracket = "{", RightBracket = "}", Backquote = "~",
	One = "!", Two = "@", Three = "#", Four = "$", Five = "%", Six = "^", Seven = "&", Eight = "*", Nine = "(", Zero = ")",
}

Prefix.MODS = { Ctrl = true, Alt = true, Shift = true }

local function trim(s)
	return (string.gsub(string.gsub(s, "^%s+", ""), "%s+$", ""))
end

function Prefix.allowed(ch)
	return type(ch) == "string" and #ch == 1 and string.find(Prefix.ALLOWED, ch, 1, true) ~= nil
end

function Prefix.validate(text)
	if type(text) ~= "string" then
		return false, "Type one symbol"
	end
	local s = trim(text)
	if s == "" then
		return false, "Type one symbol"
	end
	if #s > 1 then
		return false, "One symbol only"
	end
	if string.find(s, "^%a") or string.find(s, "^%d") then
		return false, "Pick a symbol, not a letter or a number"
	end
	if s == "/" then
		return false, "/ is Roblox's own command key"
	end
	if not Prefix.allowed(s) then
		return false, "That symbol can't be used"
	end
	return true, s
end

function Prefix.normalize(value)
	local ok, v = Prefix.validate(value)
	if ok then
		return v
	end
	return Prefix.DEFAULT
end

function Prefix.splitBind(bind)
	local mods = {}
	local key = tostring(bind or "")
	while true do
		local m, rest = string.match(key, "^(%a+)%+(.+)$")
		if not m or not Prefix.MODS[m] then
			break
		end
		mods[m] = true
		key = rest
	end
	return mods, key
end

function Prefix.typedChar(bind)
	if type(bind) ~= "string" or bind == "" then
		return nil
	end
	local mods, key = Prefix.splitBind(bind)
	if mods.Ctrl or mods.Alt then
		return nil
	end
	if mods.Shift then
		if Prefix.SHIFTED[key] then
			return Prefix.SHIFTED[key]
		end
		if #key == 1 and string.find(key, "%a") then
			return string.upper(key)
		end
		return nil
	end
	local sym = Prefix.KEY_CHARS[key]
	if sym then
		return sym
	end
	if #key == 1 and string.find(key, "%a") then
		return string.lower(key)
	end
	return nil
end

function Prefix.isCharKey(bind)
	return Prefix.typedChar(bind) ~= nil
end

function Prefix.migrate(saved)
	saved = type(saved) == "table" and saved or {}
	local out = { prefix = Prefix.DEFAULT, barKey = "", notice = nil, drop = { "chatCmds", "chatPrefix", "cmdKey" } }
	local oldChat = nil
	if type(saved.chatPrefix) == "string" then
		local first = string.sub(trim(saved.chatPrefix), 1, 1)
		if Prefix.allowed(first) then
			oldChat = first
		end
	end
	local oldKeyChar = nil
	local movedBar = ""
	local ck = saved.cmdKey
	if type(ck) == "string" and ck ~= "" and ck ~= "None" then
		oldKeyChar = Prefix.typedChar(ck)
		if oldKeyChar == nil or string.find(ck, "+", 1, true) then
			movedBar = ck
		end
	end
	if type(saved.prefix) == "string" and Prefix.allowed(saved.prefix) then
		out.prefix = saved.prefix
		if type(saved.barKey) == "string" then
			out.barKey = saved.barKey
		end
		out.drop = { "chatCmds", "chatPrefix", "cmdKey" }
		return out
	end
	out.prefix = oldChat or Prefix.DEFAULT
	out.barKey = movedBar
	if type(saved.barKey) == "string" and saved.barKey ~= "" then
		out.barKey = saved.barKey
	end
	if oldKeyChar and movedBar == "" and oldKeyChar ~= out.prefix then
		out.notice = "Your prefix is now " .. out.prefix .. ". It runs commands in chat and opens the command bar."
	end
	return out
end

function Prefix.stripLeading(text, prefix)
	local s = tostring(text or "")
	if prefix ~= nil and prefix ~= "" and string.sub(s, 1, #prefix) == prefix then
		return string.sub(s, #prefix + 1)
	end
	return s
end

function Prefix.parse(text, source, prefix, lookup)
	if type(text) ~= "string" then
		return { kind = "none" }
	end
	prefix = Prefix.normalize(prefix)
	local s = trim(text)
	if string.lower(s) == Prefix.RELOAD then
		return { kind = "reload" }
	end
	local body
	if source == "bar" then
		body = trim(Prefix.stripLeading(s, prefix))
		if body == "" then
			return { kind = "none" }
		end
	else
		if string.sub(s, 1, #prefix) ~= prefix then
			return { kind = "none" }
		end
		body = string.sub(s, #prefix + 1)
		if body == "" or string.find(body, "^%s") then
			return { kind = "none" }
		end
	end
	local word, rest = string.match(body, "^(%S+)%s*(.-)%s*$")
	if not word then
		return { kind = "none" }
	end
	word = string.lower(word)
	local known = false
	if type(lookup) == "function" then
		local okL, res = pcall(lookup, word)
		known = okL and res == true
	end
	if known then
		return { kind = "command", word = word, rest = rest, text = word .. (rest ~= "" and (" " .. rest) or "") }
	end
	if source == "bar" then
		return { kind = "unknown", word = word, rest = rest }
	end
	return { kind = "none" }
end

local Guard = {}
Guard.__index = Guard

function Prefix.newGuard(window)
	return setmetatable({ window = window or Prefix.GUARD, text = nil, at = -1e9 }, Guard)
end

function Guard:pass(text, now)
	if text == self.text and now - self.at < self.window then
		return false
	end
	self.text = text
	self.at = now
	return true
end

function Guard:reset()
	self.text = nil
	self.at = -1e9
end

function Prefix.findKey(prefix, layout)
	if not Prefix.allowed(prefix) or type(layout) ~= "table" then
		return nil
	end
	local codes = layout.codes or {}
	if type(layout.typed) == "function" then
		for _, name in ipairs(codes) do
			if layout.typed(name) == prefix then
				return { key = name, shift = false }
			end
		end
	end
	if type(layout.shifted) == "function" then
		for _, name in ipairs(codes) do
			if layout.shifted(name) == prefix then
				return { key = name, shift = true }
			end
		end
	end
	return nil
end

function Prefix.bindOf(found)
	if not found then
		return nil
	end
	return (found.shift and "Shift+" or "") .. found.key
end

function Prefix.matches(found, name, held)
	if not found or found.key ~= name then
		return false
	end
	if held and (held.Ctrl or held.Alt) then
		return false
	end
	local shift = held and held.Shift or false
	return shift == (found.shift == true)
end

function Prefix.describe(prefix, hasKey)
	local p = Prefix.normalize(prefix)
	if hasKey then
		return "In chat: " .. p .. "fly   On the keyboard: press " .. p
	end
	return "In chat: " .. p .. "fly   This keyboard has no single key for " .. p .. ". Chat still works and the bar opens from the dock and the Home tile."
end

function Prefix.header(prefix)
	local p = Prefix.normalize(prefix)
	return "Type " .. p .. "fly in chat or press " .. p .. " to open the bar"
end

return Prefix
