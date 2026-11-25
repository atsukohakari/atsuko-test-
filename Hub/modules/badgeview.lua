local View = {}

View.GAP = 2
View.SCALE = 0.9
View.NAME_SCALE = 1.3

local ENTITIES = { lt = "<", gt = ">", amp = "&", quot = '"', apos = "'" }

function View.plain(rich)
	local out = string.gsub(tostring(rich or ""), "<[^<>]*>", "")
	out = string.gsub(out, "&(%a+);", function(name)
		return ENTITIES[name]
	end)
	return out
end

function View.bold(rich)
	local depth = 0
	for close, tag in string.gmatch(tostring(rich or ""), "<(/?)(%a+)[^<>]*>") do
		if string.lower(tag) == "b" then
			depth = depth + (close == "/" and -1 or 1)
		end
	end
	return depth > 0
end

function View.before(text, mark)
	if type(text) ~= "string" then
		return nil
	end
	local i = string.find(text, mark, 1, true)
	if not i then
		return nil
	end
	local head = string.sub(text, 1, i - 1)
	local lastBreak = 0
	local plain = View.plain(head)
	for j = 1, #plain do
		if string.sub(plain, j, j) == "\n" then
			lastBreak = j
		end
	end
	return string.sub(plain, lastBreak + 1), View.bold(head)
end

local function get(o, key, default)
	local ok, v = pcall(function()
		return o[key]
	end)
	if ok and v ~= nil then
		return v
	end
	return default
end

function View.padding(label)
	local l, t, r, bt = 0, 0, 0, 0
	local ok, pad = pcall(function()
		return label:FindFirstChildOfClass("UIPadding")
	end)
	if ok and pad then
		l = get(get(pad, "PaddingLeft", nil) or {}, "Offset", 0)
		t = get(get(pad, "PaddingTop", nil) or {}, "Offset", 0)
		r = get(get(pad, "PaddingRight", nil) or {}, "Offset", 0)
		bt = get(get(pad, "PaddingBottom", nil) or {}, "Offset", 0)
	end
	return l, t, r, bt
end

local LAYER = { ScreenGui = true, BillboardGui = true, SurfaceGui = true }

function View.scaleOf(label)
	local scale = 1
	local o = label
	for _ = 1, 40 do
		if not o then
			break
		end
		local ok, list = pcall(function()
			return o:GetChildren()
		end)
		if ok and type(list) == "table" then
			for _, c in ipairs(list) do
				if get(c, "ClassName", "") == "UIScale" then
					local v = tonumber(get(c, "Scale", 1))
					if v and v > 0 then
						scale = scale * v
					end
				end
			end
		end
		if LAYER[get(o, "ClassName", "")] then
			break
		end
		o = get(o, "Parent", nil)
	end
	return scale
end

function View.textBox(label, scale)
	local textSize = get(label, "TextSize", 14)
	local lineHeight = get(label, "LineHeight", 1)
	local scaled = get(label, "TextScaled", false) == true
	local bounds = get(label, "TextBounds", nil)
	local tw = bounds and get(bounds, "X", 0) or 0
	local th = bounds and get(bounds, "Y", 0) or 0
	local abs = get(label, "AbsoluteSize", nil)
	local w = abs and get(abs, "X", 0) or 0
	local h = abs and get(abs, "Y", 0) or 0
	local k = tonumber(scale) or View.scaleOf(label)
	if math.abs(k - 1) > 1e-3 then
		local plain = textSize * lineHeight
		if th > 0 and (scaled or math.abs(th - plain * k) < math.abs(th - plain)) then
			tw, th = tw / k, th / k
		end
		w, h = w / k, h / k
	end
	if scaled and th > 0 then
		textSize = th / lineHeight
	end
	local lineH = textSize * lineHeight
	if th <= 0 then
		th = lineH
	end
	local padL, padT, padR, padB = View.padding(label)
	local innerW, innerH = w - padL - padR, h - padT - padB
	local ax = tostring(get(label, "TextXAlignment", ""))
	local ay = tostring(get(label, "TextYAlignment", ""))
	local left, top = padL, padT
	if string.find(ax, "Center", 1, true) then
		left = padL + (innerW - tw) / 2
	elseif string.find(ax, "Right", 1, true) then
		left = padL + innerW - tw
	end
	if string.find(ay, "Center", 1, true) then
		top = padT + (innerH - th) / 2
	elseif string.find(ay, "Bottom", 1, true) then
		top = padT + innerH - th
	end
	if th < lineH * 1.5 then
		lineH = th
	end
	local seen = math.max(textSize, th / lineHeight)
	local auto = tostring(get(label, "AutomaticSize", ""))
	if innerH > 0 and (scaled or string.find(string.match(auto, "[^%.]+$") or "", "Y", 1, true)) then
		seen = math.max(seen, innerH / lineHeight * 0.92)
	end
	return left, top, tw, lineH, textSize, seen
end

local function badgeSize(textSize, scale)
	return math.max(8, math.floor(textSize * (scale or View.SCALE) + 0.5))
end

function View.measured(holder, size)
	local abs = get(holder, "AbsoluteSize", nil)
	local w = abs and get(abs, "X", 0) or 0
	if type(w) ~= "number" or w <= 0 or not size or size <= 0 then
		return nil
	end
	return w / size
end

function View.chatSpot(label, width)
	local left, top, _, lineH, textSize = View.textBox(label)
	local s = badgeSize(textSize)
	return math.floor(left + width + View.GAP + 0.5), math.floor(top + (lineH - s) / 2 + 0.5), s
end

function View.boardSpot(label, scale)
	local left, top, tw, lineH, textSize, seen = View.textBox(label, scale)
	local s = badgeSize(math.max(textSize, seen or 0), View.NAME_SCALE)
	local line = math.max(lineH, (seen or 0) * get(label, "LineHeight", 1))
	return math.floor(left + tw + View.GAP + 2 + 0.5), math.floor(top + (line - s) / 2 + 0.5), s
end

local function isLabel(o)
	local ok, yes = pcall(function()
		return o:IsA("TextLabel") or o:IsA("TextButton")
	end)
	return ok and yes
end

local ROW_IDS = { "^p_(%d+)$", "^player_(%d+)$", "^PlayerEntry_(%d+)$" }

function View.rowOwner(label, env)
	local p = get(label, "Parent", nil)
	local depth = 0
	while p and depth < 14 do
		local name = get(p, "Name", "")
		if type(name) == "string" then
			for _, pattern in ipairs(ROW_IDS) do
				local id = string.match(name, pattern)
				if id then
					return env.byId(tonumber(id))
				end
			end
			local who = string.match(name, "^PlayerLabel(.+)$")
			if who then
				return env.byName(who)
			end
		end
		p = get(p, "Parent", nil)
		depth = depth + 1
	end
	return nil
end

function View.billboard(label)
	local p = get(label, "Parent", nil)
	local depth = 0
	while p and depth < 12 do
		local class = get(p, "ClassName", "")
		if class == "BillboardGui" then
			return p
		end
		if class == "ScreenGui" or class == "SurfaceGui" or class == "PlayerGui" then
			return nil
		end
		p = get(p, "Parent", nil)
		depth = depth + 1
	end
	return nil
end

function View.tagOwner(label, env)
	local bb = View.billboard(label)
	if not bb or not env.ofCharacter then
		return nil
	end
	local starts = { bb }
	local adornee = get(bb, "Adornee", nil)
	if adornee then
		table.insert(starts, 1, adornee)
	end
	for _, start in ipairs(starts) do
		local node = start
		local depth = 0
		while node and depth < 8 do
			if get(node, "ClassName", "") == "Model" then
				local who = env.ofCharacter(node)
				if who then
					return who
				end
			end
			node = get(node, "Parent", nil)
			depth = depth + 1
		end
	end
	return nil
end

local LAYERS = { ScreenGui = true, BillboardGui = true, SurfaceGui = true, CoreGui = true }

function View.near(label, text)
	local p = get(label, "Parent", nil)
	for _ = 1, 2 do
		if not p or LAYERS[get(p, "ClassName", "")] then
			return false
		end
		local ok, list = pcall(function()
			return p:GetDescendants()
		end)
		if ok and type(list) == "table" and #list <= 40 then
			for _, o in ipairs(list) do
				if o ~= label and get(o, "Text", nil) == text then
					return true
				end
			end
		end
		p = get(p, "Parent", nil)
	end
	return false
end

function View.escape(text)
	return (string.gsub(string.gsub(string.gsub(tostring(text), "&", "&amp;"), "<", "&lt;"), ">", "&gt;"))
end

function View.kind(label, player, seen)
	local name = get(label, "Name", "")
	local text = seen or get(label, "Text", "")
	if text == "" then
		return nil
	end
	if name == "DisplayNameLabel" or name == "PlayerName" then
		return "name"
	end
	if string.sub(text, 1, 1) == "@" or name == "NameLabel" or name == "UsernameLabel" then
		return nil
	end
	if text == get(player, "DisplayName", nil) then
		return "name"
	end
	return nil
end

function View.inTag(text, pos)
	local lt, gt = 0, 0
	local i = 0
	while true do
		i = string.find(text, "[<>]", i + 1)
		if not i or i >= pos then
			break
		end
		if string.sub(text, i, i) == "<" then
			lt = i
		else
			gt = i
		end
	end
	return lt > gt
end

function View.wordAt(text, name, from)
	local i = from or 1
	while true do
		local a, b = string.find(text, name, i, true)
		if not a then
			return nil
		end
		local before = a > 1 and string.sub(text, a - 1, a - 1) or ""
		local after = string.sub(text, b + 1, b + 1)
		if not string.find(before, "^[%w_@]$") and not string.find(after, "^[%w_]$") and not View.inTag(text, a) then
			return a, b
		end
		i = a + 1
	end
end

function View.cutoff(text)
	local i = 0
	while true do
		i = string.find(text, ":", i + 1, true)
		if not i then
			return nil
		end
		if not View.inTag(text, i) then
			return i
		end
	end
end

function View.badged(text, pos, glyph)
	local rest = string.sub(text, pos + 1, pos + 200)
	rest = string.gsub(rest, "^%s*</[^<>]*>", "")
	rest = string.gsub(rest, "^%s*<font[^<>]*>", "")
	return string.sub(rest, 1, #glyph) == glyph
end

function View.decorate(text, names, suffix, glyph, chat)
	if type(text) ~= "string" or text == "" or #names == 0 then
		return nil
	end
	local stop = chat and View.cutoff(text) or nil
	local cuts = {}
	for _, name in ipairs(names) do
		local from = 1
		while true do
			local a, b = View.wordAt(text, name, from)
			if not a or (stop and a > stop) then
				break
			end
			local free = not View.badged(text, b, glyph)
			for _, c in ipairs(cuts) do
				if a <= c.b and b >= c.a then
					free = false
				end
			end
			if free then
				cuts[#cuts + 1] = { a = a, b = b }
			end
			from = b + 1
		end
	end
	if #cuts == 0 then
		return nil
	end
	table.sort(cuts, function(x, y)
		return x.b > y.b
	end)
	for _, c in ipairs(cuts) do
		text = string.sub(text, 1, c.b) .. suffix .. string.sub(text, c.b + 1)
	end
	return text
end

function View.nicknames(env, rich)
	local out, seen = {}, {}
	for _, p in ipairs(env.users()) do
		local nick = get(p, "DisplayName", nil)
		if type(nick) == "string" and nick ~= "" and not seen[nick] then
			seen[nick] = true
			out[#out + 1] = rich and nick or View.escape(nick)
			if rich and View.escape(nick) ~= nick then
				out[#out + 1] = View.escape(nick)
			end
		end
	end
	table.sort(out, function(a, b)
		return #a > #b
	end)
	return out
end

function View.match(label, env, root, seen)
	if root == "tag" then
		local owner = View.tagOwner(label, env)
		if owner and View.kind(label, owner, seen) then
			return owner, "tag"
		end
		return nil
	end
	local text = seen or get(label, "Text", "")
	if root == "game" then
		if type(text) ~= "string" or text == "" then
			return nil
		end
		for _, p in ipairs(env.users()) do
			if text == get(p, "DisplayName", nil) then
				return p, "game"
			end
		end
		return nil
	end
	local player = View.rowOwner(label, env)
	if player then
		local kind = View.kind(label, player, seen)
		if kind then
			return player, kind
		end
		return nil
	end
	if type(text) ~= "string" or text == "" then
		return nil
	end
	if string.sub(text, 1, 1) == "@" then
		return nil
	end
	for _, p in ipairs(env.users()) do
		if text == get(p, "DisplayName", nil) and View.near(label, "@" .. tostring(get(p, "Name", ""))) then
			return p, "name"
		end
	end
	return nil
end

function View.watch(env)
	local st = { alive = true, conns = {}, seen = setmetatable({}, { __mode = "k" }), marks = setmetatable({}, { __mode = "k" }), hooked = setmetatable({}, { __mode = "k" }), roots = setmetatable({}, { __mode = "k" }), texts = setmetatable({}, { __mode = "k" }), orig = setmetatable({}, { __mode = "k" }) }
	local suffix = type(env.suffix) == "string" and env.suffix ~= "" and env.suffix or nil
	local function plain(label)
		local t = st.texts[label]
		local cur = get(label, "Text", "")
		if t and cur == t.shown then
			return t.base, t
		end
		return cur, nil
	end
	local function unglyph(label)
		local t = st.texts[label]
		st.texts[label] = nil
		local rich = st.orig[label]
		st.orig[label] = nil
		pcall(function()
			if t and get(label, "Text", "") == t.shown then
				label.Text = t.base
			end
			if rich ~= nil then
				label.RichText = rich
			end
		end)
	end
	local glyphChar = suffix and View.plain(suffix) or ""
	local function richOf(label)
		local rich = st.orig[label]
		if rich == nil then
			rich = get(label, "RichText", false) == true
		end
		return rich
	end
	local function glyph(label, kind, base, shown)
		local t = st.texts[label]
		if t and t.base == base and t.shown == shown and get(label, "Text", "") == shown then
			return t
		end
		if st.orig[label] == nil then
			st.orig[label] = get(label, "RichText", false) == true
		end
		t = { base = base, rich = st.orig[label], shown = shown, kind = kind }
		st.texts[label] = t
		local ok = pcall(function()
			label.RichText = true
			label.Text = shown
		end)
		if not ok then
			st.texts[label] = nil
			return nil
		end
		return t
	end
	local function hold(c)
		if c then
			st.conns[#st.conns + 1] = c
		end
	end
	local function drop(label)
		local mark = st.marks[label]
		st.marks[label] = nil
		if mark then
			pcall(function()
				mark.box:Destroy()
			end)
		end
	end
	local function fade(label)
		local mark = st.marks[label]
		if mark then
			env.fade(mark.holder, get(label, "TextTransparency", 0))
		end
	end
	local check
	local function listen(label, prop, fn)
		local ok, sig = pcall(function()
			return label:GetPropertyChangedSignal(prop)
		end)
		if ok and sig then
			hold(sig:Connect(fn))
		end
	end
	local function deepen(label, root)
		if st.hooked[label] then
			return
		end
		st.hooked[label] = true
		listen(label, "TextSize", function()
			check(label, root)
		end)
		listen(label, "AbsoluteSize", function()
			check(label, root)
		end)
		listen(label, "TextTransparency", function()
			fade(label)
		end)
	end
	local function put(label, root, kind, x, y, s)
		local mark = st.marks[label]
		if mark and (mark.kind ~= kind or mark.size ~= s or not mark.box.Parent) then
			drop(label)
			mark = nil
		end
		if not mark then
			local box = Instance.new("Folder")
			box.Name = "AtsukoBadge"
			local holder = env.draw(label, s, box)
			box.Parent = label
			mark = { box = box, holder = holder, kind = kind, size = s }
			st.marks[label] = mark
		end
		mark.holder.Position = UDim2.fromOffset(x, y)
		deepen(label, root)
		fade(label)
		return mark
	end
	check = function(label, root)
		if not st.alive then
			return
		end
		if suffix then
			local base = plain(label)
			local name = get(label, "Name", "")
			if name ~= "UsernameLabel" and type(base) == "string" and base ~= "" then
				local rich = richOf(label)
				local text = rich and base or View.escape(base)
				local shown = View.decorate(text, View.nicknames(env, rich), suffix, glyphChar, root == "chat")
				if shown then
					local t = glyph(label, root == "chat" and "chat" or "name", base, shown)
					if t then
						st.last = string.format("%s %q with the glyph, TextSize %s", tostring(t.kind), tostring(t.base), tostring(get(label, "TextSize", "?")))
					end
					return
				end
			end
			unglyph(label)
			return
		end
		if root == "chat" then
			local head, bold = View.before(get(label, "Text", ""), env.markOpen)
			if head then
				local width = env.measure(head, label, bold)
				if st.alive then
					local x, y, s = View.chatSpot(label, width)
					put(label, root, "chat", x, y, s)
				end
				return
			end
		else
			local player, kind = View.match(label, env, root)
			if player and env.has(get(player, "UserId", 0)) then
				local k = View.scaleOf(label)
				local x, y, s = View.boardSpot(label)
				local mark = put(label, root, kind, x, y, s)
				local real = mark and View.measured(mark.holder, s)
				if real and math.abs(real - k) > 0.05 then
					x, y, s = View.boardSpot(label, real)
					mark = put(label, root, kind, x, y, s)
				end
				if mark then
					local tb = get(label, "TextBounds", nil)
					local ab = get(label, "AbsoluteSize", nil)
					st.last = string.format("%s TextSize %s, TextBounds %sx%s, label %sx%s, scaled %s, auto %s, UIScale %.2f, real %s, badge %d", tostring(kind), tostring(get(label, "TextSize", "?")), tostring(tb and get(tb, "X", "?")), tostring(tb and get(tb, "Y", "?")), tostring(ab and get(ab, "X", "?")), tostring(ab and get(ab, "Y", "?")), tostring(get(label, "TextScaled", "?")), tostring(get(label, "AutomaticSize", "?")), k, real and string.format("%.2f", real) or "not drawn yet", s)
				end
				if mark and not real and not mark.later then
					mark.later = true
					task.delay(0.15, function()
						if st.alive and st.marks[label] == mark then
							check(label, root)
						end
					end)
				end
				return
			end
		end
		drop(label)
	end
	local function consider(o, root)
		if not st.alive or st.seen[o] or not isLabel(o) then
			return
		end
		if get(o, "Name", "") == "Glyph" then
			return
		end
		if env.mine and env.mine(o) then
			return
		end
		if root == "tag" and not View.billboard(o) then
			if not suffix then
				return
			end
			root = "game"
		end
		st.seen[o] = root
		check(o, root)
		listen(o, "Text", function()
			check(o, root)
		end)
		listen(o, "TextBounds", function()
			if st.marks[o] or root == "chat" then
				check(o, root)
			end
		end)
	end
	local function attach(root, kind, slow)
		if st.roots[root] then
			return
		end
		st.roots[root] = kind
		local okC, conn = pcall(function()
			return root.DescendantAdded:Connect(function(o)
				consider(o, kind)
			end)
		end)
		if okC then
			hold(conn)
		end
		local ok, list = pcall(function()
			return root:GetDescendants()
		end)
		if ok and type(list) == "table" then
			for i, o in ipairs(list) do
				consider(o, kind)
				if slow and i % 3000 == 0 then
					task.wait()
					if not st.alive then
						return
					end
				end
			end
		end
	end
	local function found(child)
		local name = get(child, "Name", "")
		if name == "ExperienceChat" then
			attach(child, "chat")
		elseif name == "PlayerList" then
			attach(child, "board")
		elseif not (env.skip and env.skip(child)) then
			attach(child, "menu")
		end
	end
	local core = env.coreGui
	if core then
		local ok, kids = pcall(function()
			return core:GetChildren()
		end)
		if ok and type(kids) == "table" then
			for _, c in ipairs(kids) do
				found(c)
			end
		end
		local okA, conn = pcall(function()
			return core.ChildAdded:Connect(found)
		end)
		if okA then
			hold(conn)
		end
	end
	local players = env.players
	if players then
		local function track(p)
			local okC, char = pcall(function()
				return p.Character
			end)
			if okC and char then
				attach(char, "tag")
			end
			local okS, conn = pcall(function()
				return p.CharacterAdded:Connect(function(c)
					attach(c, "tag")
				end)
			end)
			if okS then
				hold(conn)
			end
		end
		local okP, list = pcall(function()
			return players:GetPlayers()
		end)
		if okP and type(list) == "table" then
			for _, p in ipairs(list) do
				track(p)
			end
		end
		local okA, conn = pcall(function()
			return players.PlayerAdded:Connect(track)
		end)
		if okA then
			hold(conn)
		end
	end
	if env.playerGui then
		attach(env.playerGui, "tag")
	end
	if suffix and env.world then
		task.spawn(attach, env.world, "tag", true)
	end
	function st.chat()
		for _, kind in pairs(st.roots) do
			if kind == "chat" then
				return true
			end
		end
		return false
	end
	function st.refresh()
		for label, root in pairs(st.seen) do
			if root ~= "chat" then
				check(label, root)
			end
		end
	end
	function st.count(kind)
		local n = 0
		for _, mark in pairs(st.marks) do
			if not kind or mark.kind == kind then
				n = n + 1
			end
		end
		for _, t in pairs(st.texts) do
			if not kind or t.kind == kind then
				n = n + 1
			end
		end
		return n
	end
	function st.stop()
		st.alive = false
		for _, c in ipairs(st.conns) do
			pcall(function()
				c:Disconnect()
			end)
		end
		st.conns = {}
		for label in pairs(st.marks) do
			drop(label)
		end
		for label in pairs(st.texts) do
			unglyph(label)
		end
	end
	function st.describe()
		return st.last
	end
	return st
end

return View
