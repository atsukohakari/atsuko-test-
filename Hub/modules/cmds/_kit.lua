local Kit = {}

Kit.CHAT_GAP = 1.5

local function capitalise(id)
	return string.upper(string.sub(id, 1, 1)) .. string.sub(id, 2)
end

function Kit.parseNumbers(text, count)
	local out = {}
	for word in string.gmatch(tostring(text or ""), "[^%s,]+") do
		local n = tonumber(word)
		if n == nil then
			return nil
		end
		out[#out + 1] = n
	end
	if count and #out ~= count then
		return nil
	end
	return out
end

function Kit.clamp(n, lo, hi)
	if lo and n < lo then
		n = lo
	end
	if hi and n > hi then
		n = hi
	end
	return n
end

function Kit.number(text, default, lo, hi)
	local n = tonumber(text)
	if n == nil then
		n = default
	end
	if n == nil then
		return nil
	end
	return Kit.clamp(n, lo, hi)
end

function Kit.splitWord(text)
	local first, rest = string.match(tostring(text or ""), "^%s*(%S+)%s*(.-)%s*$")
	return first, rest or ""
end

function Kit.chatGate(now, last)
	if last ~= nil and now - last < Kit.CHAT_GAP then
		return false, Kit.CHAT_GAP - (now - last)
	end
	return true, 0
end

function Kit.mathValue(text)
	local src = tostring(text or "")
	if #src > 120 then
		return nil, "That sum is too long"
	end
	local pos = 1
	local function skip()
		pos = string.find(src, "%S", pos) or (#src + 1)
	end
	local parseSum
	local function parseAtom()
		skip()
		local c = string.sub(src, pos, pos)
		if c == "(" then
			pos += 1
			local v, err = parseSum()
			if v == nil then
				return nil, err
			end
			skip()
			if string.sub(src, pos, pos) ~= ")" then
				return nil, "A bracket was never closed"
			end
			pos += 1
			return v
		end
		if c == "-" then
			pos += 1
			local v, err = parseAtom()
			if v == nil then
				return nil, err
			end
			return -v
		end
		if c == "+" then
			pos += 1
			return parseAtom()
		end
		local num = string.match(src, "^%d+%.?%d*", pos) or string.match(src, "^%.%d+", pos)
		if not num then
			return nil, "I can't read that, try something like 12*(3+4)"
		end
		pos += #num
		return tonumber(num)
	end
	local function parsePower()
		local base, err = parseAtom()
		if base == nil then
			return nil, err
		end
		skip()
		if string.sub(src, pos, pos) == "^" then
			pos += 1
			local exp, err2 = parsePower()
			if exp == nil then
				return nil, err2
			end
			return base ^ exp
		end
		return base
	end
	local function parseProduct()
		local v, err = parsePower()
		if v == nil then
			return nil, err
		end
		while true do
			skip()
			local op = string.sub(src, pos, pos)
			if op ~= "*" and op ~= "/" and op ~= "%" then
				return v
			end
			pos += 1
			local rhs, err2 = parsePower()
			if rhs == nil then
				return nil, err2
			end
			if op == "*" then
				v = v * rhs
			elseif rhs == 0 then
				return nil, "Can't divide by zero"
			elseif op == "/" then
				v = v / rhs
			else
				v = v % rhs
			end
		end
	end
	parseSum = function()
		local v, err = parseProduct()
		if v == nil then
			return nil, err
		end
		while true do
			skip()
			local op = string.sub(src, pos, pos)
			if op ~= "+" and op ~= "-" then
				return v
			end
			pos += 1
			local rhs, err2 = parseProduct()
			if rhs == nil then
				return nil, err2
			end
			v = op == "+" and v + rhs or v - rhs
		end
	end
	skip()
	if pos > #src then
		return nil, "Type a sum, like 12*(3+4)"
	end
	local value, err = parseSum()
	if value == nil then
		return nil, err
	end
	skip()
	if pos <= #src then
		return nil, "I can't read that, try something like 12*(3+4)"
	end
	if value ~= value or value == math.huge or value == -math.huge then
		return nil, "That number is too big"
	end
	return value
end

function Kit.listText(items, cap)
	cap = cap or 6
	local out = {}
	for i = 1, math.min(#items, cap) do
		out[i] = tostring(items[i])
	end
	if #items > cap then
		out[#out + 1] = "and " .. (#items - cap) .. " more"
	end
	return table.concat(out, ", ")
end

function Kit.formatNumber(n)
	if n == math.floor(n) and math.abs(n) < 1e15 then
		return string.format("%d", n)
	end
	local s = string.format("%.6f", n)
	s = string.gsub(s, "0+$", "")
	s = string.gsub(s, "%.$", "")
	return s
end

function Kit.agoText(days)
	days = math.max(0, math.floor(days))
	if days < 31 then
		return days .. (days == 1 and " day" or " days")
	end
	local years = math.floor(days / 365)
	local months = math.floor((days - years * 365) / 30)
	if years == 0 then
		return months .. (months == 1 and " month" or " months") .. " (" .. days .. " days)"
	end
	local text = years .. (years == 1 and " year" or " years")
	if months > 0 then
		text = text .. " " .. months .. (months == 1 and " month" or " months")
	end
	return text .. " (" .. days .. " days)"
end

function Kit.build(ctx)
	local Cmd, Targets, S, Log, Players, LP, notify = ctx.Cmd, ctx.Targets, ctx.S, ctx.Log, ctx.Players, ctx.LP, ctx.notify
	local HUB = ctx.HUB
	local kit = { meta = {}, built = {}, failed = {}, lastChat = nil }
	kit.number, kit.numbers, kit.clamp, kit.splitWord = Kit.number, Kit.parseNumbers, Kit.clamp, Kit.splitWord

	for _, row in ipairs(ctx.meta or {}) do
		kit.meta[row.id] = row
	end

	function kit.define(id, behaviour)
		local row = kit.meta[id]
		if not row then
			kit.failed[id] = "not in the catalogue"
			Log.add("error", "Commands", "no catalogue entry for " .. tostring(id))
			return false
		end
		local def = {}
		for k, v in pairs(row) do
			def[k] = v
		end
		for k, v in pairs(behaviour) do
			def[k] = v
		end
		def.name = def.name or capitalise(id)
		def.icon = def.icon or "command"
		def.cat = def.cat or kit.packCat or "Utility"
		def.needs = nil
		def.aliases = def.aliases or {}
		local ok, added = pcall(Cmd.add, def)
		if ok and added then
			kit.built[#kit.built + 1] = id
			return true
		end
		kit.failed[id] = ok and "refused" or tostring(added)
		return false
	end

	function kit.alive()
		return HUB == nil or HUB.alive
	end

	function kit.say(title, text, kind)
		notify(title, text, kind or "ok", 2)
	end

	function kit.fail(title, text)
		notify(title, text, "error", 2.5)
		return false, text
	end

	function kit.hum()
		return Cmd.hum()
	end

	function kit.root()
		return Cmd.root()
	end

	function kit.rootOf(p)
		local c = p and p.Character
		if not c then
			return nil
		end
		return c:FindFirstChild("HumanoidRootPart") or c.PrimaryPart
	end

	function kit.humOf(p)
		local c = p and p.Character
		return c and c:FindFirstChildOfClass("Humanoid") or nil
	end

	function kit.exceptions()
		local list = Cmd.val("exceptions", "names", {})
		local set = {}
		if type(list) == "table" then
			for _, n in ipairs(list) do
				set[string.lower(tostring(n))] = true
			end
		end
		return set
	end

	function kit.targets(text, cap)
		local mine = kit.root()
		return Targets.resolve(text, {
			me = LP,
			players = Players:GetPlayers(),
			cap = cap,
			distance = function(p)
				local r = kit.rootOf(p)
				if mine and r then
					return (mine.Position - r.Position).Magnitude
				end
				return nil
			end,
			isFriend = function(p)
				local ok, yes = pcall(function()
					return LP:IsFriendsWith(p.UserId)
				end)
				return ok and yes == true
			end,
			except = kit.exceptions(),
			rand = function(n)
				return math.random(1, n)
			end,
		})
	end

	function kit.pick(title, text, default, quiet)
		local want = tostring(text or "")
		if string.find(want, "^%s*$") then
			want = default or ""
		end
		local res = kit.targets(want)
		if #res.players == 0 then
			local why = res.error or "Nobody to pick"
			if not quiet then
				notify(title, why, "error", 2.5)
			end
			return nil, why
		end
		return res.players, res
	end

	function kit.one(title, text, default, quiet)
		local list, info = kit.pick(title, text, default, quiet)
		if not list then
			return nil, info
		end
		return list[1], info
	end

	function kit.each(list, fn)
		for i, p in ipairs(list) do
			fn(p, i)
			if i % 5 == 0 then
				task.wait()
			end
		end
	end

	function kit.copy(text, what, quiet)
		return ctx.copyText(text, what, quiet) ~= false
	end

	function kit.bind(id, conn)
		return Cmd.bind(id, conn)
	end

	function kit.on(id, signal, fn)
		return Cmd.bind(id, signal:Connect(fn))
	end

	function kit.every(id, interval, fn)
		local live = true
		Cmd.bind(id, {
			Disconnect = function()
				live = false
			end,
		})
		task.spawn(function()
			while live and kit.alive() do
				local ok, e = pcall(fn)
				if not ok then
					live = false
					Log.add("error", "Commands", tostring(id) .. ": " .. tostring(e))
					break
				end
				task.wait(interval)
			end
		end)
	end

	function kit.later(seconds, fn)
		task.delay(seconds, function()
			if kit.alive() then
				fn()
			end
		end)
	end

	function kit.chat(text)
		text = tostring(text or "")
		if text == "" then
			return false, "Say something"
		end
		local now = os.clock()
		local open, wait = Kit.chatGate(now, kit.lastChat)
		if not open then
			return false, string.format("Slow down, one message every %.1f seconds", Kit.CHAT_GAP)
		end
		local sent = false
		pcall(function()
			local channels = game:GetService("TextChatService"):FindFirstChild("TextChannels")
			local general = channels and channels:FindFirstChild("RBXGeneral")
			if general then
				general:SendAsync(text)
				sent = true
			end
		end)
		if not sent then
			pcall(function()
				local events = game:GetService("ReplicatedStorage"):FindFirstChild("DefaultChatSystemChatEvents")
				local say = events and events:FindFirstChild("SayMessageRequest")
				if say then
					say:FireServer(text, "All")
					sent = true
				end
			end)
		end
		if sent then
			kit.lastChat = now
			return true
		end
		return false, "This game's chat didn't take the message"
	end

	return kit
end

return Kit
