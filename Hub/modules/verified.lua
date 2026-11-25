local Verified = {}

Verified.DEFAULT = "0066ff"
Verified.GLYPH = "\238\128\128"
Verified.MARK_OPEN = '<font color="#010203">'
Verified.MARK = Verified.MARK_OPEN .. "     </font>"
Verified.SEAL_SIZE = 0.816
Verified.SEAL_TURN = 15
Verified.FONT = "rbxasset://fonts/families/BuilderSans.json"

function Verified.suffix(hex)
	return '<font color="#' .. tostring(hex or Verified.DEFAULT) .. '" family="' .. Verified.FONT .. '">' .. Verified.GLYPH .. "</font>"
end

function Verified.tagFont()
	local ok, f = pcall(function()
		return Font.new(Verified.FONT, Enum.FontWeight.Bold)
	end)
	return ok and f or nil
end

function Verified.rgb()
	local hex = Verified.DEFAULT
	return tonumber(string.sub(hex, 1, 2), 16), tonumber(string.sub(hex, 3, 4), 16), tonumber(string.sub(hex, 5, 6), 16)
end

function Verified.newer(ts, last)
	ts = tonumber(ts)
	if not ts then
		return false
	end
	return ts >= (tonumber(last) or 0)
end

function Verified.mark(text)
	if type(text) ~= "string" or text == "" then
		return text
	end
	if string.find(text, Verified.MARK_OPEN, 1, true) then
		return text
	end
	local core, trail = string.match(text, "^(.-)(%s*)$")
	local head, tail = string.match(core, "^(.-)(:%s*</%w+>)$")
	if not head then
		head, tail = string.match(core, "^(.-)(:)$")
	end
	if not head then
		head, tail = core, ""
	end
	head = string.gsub(head, "%s+$", "")
	return head .. Verified.MARK .. tail .. trail
end

function Verified.glyph(text)
	if type(text) ~= "string" or text == "" or string.find(text, Verified.GLYPH, 1, true) then
		return text
	end
	local marked = Verified.mark(text)
	local i = string.find(marked, Verified.MARK, 1, true)
	return string.sub(marked, 1, i - 1) .. Verified.suffix() .. string.sub(marked, i + #Verified.MARK)
end

function Verified.window(env, message, props)
	local okSrc, src = pcall(function()
		return message.TextSource
	end)
	if not okSrc or not src then
		return props
	end
	local okId, id = pcall(function()
		return src.UserId
	end)
	if not okId or type(id) ~= "number" or not env.has(id) then
		return props
	end
	local base
	if props then
		local okP, prior = pcall(function()
			return props.PrefixText
		end)
		if okP and type(prior) == "string" and prior ~= "" then
			base = prior
		end
	end
	if not base then
		local okM, mine = pcall(function()
			return message.PrefixText
		end)
		if okM and type(mine) == "string" then
			base = mine
		end
	end
	if not base or base == "" then
		return props
	end
	local drawn = env.drawn and env.drawn()
	local text = drawn and Verified.mark(base) or Verified.glyph(base)
	if text == base then
		return props
	end
	local color = env.nameColor and env.nameColor(id) or nil
	if color and string.find(base, "<font", 1, true) then
		color = nil
	end
	if color and props then
		local okPP, pp = pcall(function()
			return props.PrefixTextProperties
		end)
		if okPP and pp then
			color = nil
		end
	end
	if not props then
		local okNew, made = pcall(env.derive)
		if not okNew or not made then
			return props
		end
		props = made
	end
	props.PrefixText = text
	if color then
		local okD, pp = pcall(env.derive)
		if okD and pp then
			pcall(function()
				pp.TextColor3 = color
				props.PrefixTextProperties = pp
			end)
		end
	end
	return props
end

function Verified.install(env)
	local state = { active = false, removed = false }
	local service = env.service
	if not service then
		state.reason = "noservice"
		return state
	end
	local old
	if type(env.getcallback) == "function" then
		local okGet, f = pcall(env.getcallback, service, "OnChatWindowAdded")
		if okGet then
			state.readable = true
			old = type(f) == "function" and f or nil
		end
	end
	local function handler(message)
		local props
		if old then
			local ok, res = pcall(old, message)
			if ok then
				props = res
			end
		end
		if state.removed then
			return props
		end
		local ok, out = pcall(Verified.window, env, message, props)
		if ok then
			return out
		end
		return props
	end
	local ok = pcall(function()
		service.OnChatWindowAdded = handler
	end)
	if not ok then
		state.reason = "locked"
		return state
	end
	state.active = true
	state.handler = handler
	function state.remove()
		if state.removed then
			return
		end
		state.removed = true
		state.active = false
		pcall(function()
			service.OnChatWindowAdded = old
		end)
	end
	return state
end

function Verified.draw(env, parent, size, color, props)
	local UI = env.UI
	local holder = UI.new("Frame", { Name = "VerifiedBadge", BackgroundTransparency = 1, Size = UDim2.fromOffset(size, size) })
	if props then
		for key, value in pairs(props) do
			holder[key] = value
		end
	end
	if env.glyph then
		local label = UI.new("TextLabel", {
			Name = "Glyph",
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			Text = Verified.GLYPH,
			TextColor3 = color,
			TextSize = size,
			TextXAlignment = Enum.TextXAlignment.Center,
			TextYAlignment = Enum.TextYAlignment.Center,
			ZIndex = 1,
		}, holder)
		pcall(function()
			label.FontFace = Font.new(Verified.FONT)
		end)
		holder.Parent = parent
		return holder, label
	end
	local seal
	if env.hasIcon("verified-seal") then
		seal = UI.icon("verified-seal", size, color, holder, { Name = "Seal", Size = UDim2.fromScale(1, 1), ZIndex = 1 })
	else
		seal = UI.new("Frame", {
			Name = "Seal",
			BackgroundColor3 = color,
			BorderSizePixel = 0,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(Verified.SEAL_SIZE, Verified.SEAL_SIZE),
			Rotation = Verified.SEAL_TURN,
			ZIndex = 1,
		}, holder)
	end
	UI.icon("verified-tick", size, Color3.new(1, 1, 1), holder, { Name = "Tick", Size = UDim2.fromScale(1, 1), ZIndex = 2 })
	holder.Parent = parent
	return holder, seal
end

return Verified
