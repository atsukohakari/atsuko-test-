local Tag = {}

Tag.TEXT_SIZE = 18
Tag.BADGE = 16
Tag.LIFT = 1.1
Tag.DISTANCE = 100

local function get(o, key, default)
	local ok, v = pcall(function()
		return o[key]
	end)
	if ok and v ~= nil then
		return v
	end
	return default
end

local function set(o, key, value)
	return (pcall(function()
		o[key] = value
	end))
end

function Tag.enumName(v)
	local s = tostring(v or "")
	return string.match(s, "([%w_]+)$") or s
end

function Tag.read(hum)
	return { mode = get(hum, "DisplayDistanceType", nil), name = get(hum, "NameDisplayDistance", nil), health = get(hum, "HealthDisplayDistance", nil) }
end

function Tag.reach(saved, viewer)
	local mode = Tag.enumName(saved.mode or "Viewer")
	if mode == "None" then
		return nil
	end
	local name, health
	if mode == "Subject" then
		name, health = tonumber(saved.name), tonumber(saved.health)
	elseif viewer then
		name, health = tonumber(get(viewer, "NameDisplayDistance", nil)), tonumber(get(viewer, "HealthDisplayDistance", nil))
	end
	name = name or Tag.DISTANCE
	health = health or Tag.DISTANCE
	if name <= 0 then
		return nil
	end
	return name, health
end

function Tag.text(hum, player)
	local shown = get(hum, "DisplayName", "")
	if type(shown) ~= "string" or shown == "" then
		shown = get(player, "DisplayName", "")
	end
	if type(shown) ~= "string" or shown == "" then
		shown = get(player, "Name", "")
	end
	return tostring(shown)
end

function Tag.escape(text)
	return (string.gsub(string.gsub(string.gsub(tostring(text), "&", "&amp;"), "<", "&lt;"), ">", "&gt;"))
end

function Tag.show(env, label, text)
	if type(env.suffix) == "string" and env.suffix ~= "" then
		label.RichText = true
		label.Text = Tag.escape(text) .. env.suffix
	else
		label.Text = text
	end
end

function Tag.build(env, head, distance, text)
	local bb = Instance.new("BillboardGui")
	bb.Name = "AtsukoNameTag"
	bb.Adornee = head
	bb.Size = UDim2.fromOffset(320, 28)
	local size = get(head, "Size", nil)
	local half = size and (get(size, "Y", 1) / 2) or 0.5
	bb.StudsOffsetWorldSpace = Vector3.new(0, half + Tag.LIFT, 0)
	bb.MaxDistance = distance
	bb.LightInfluence = 0
	bb.AlwaysOnTop = false
	local row = Instance.new("Frame")
	row.Name = "Row"
	row.BackgroundTransparency = 1
	row.Size = UDim2.fromScale(1, 1)
	row.Parent = bb
	local list = Instance.new("UIListLayout")
	list.FillDirection = Enum.FillDirection.Horizontal
	list.HorizontalAlignment = Enum.HorizontalAlignment.Center
	list.VerticalAlignment = Enum.VerticalAlignment.Center
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Padding = UDim.new(0, 4)
	list.Parent = row
	local label = Instance.new("TextLabel")
	label.Name = "Name"
	label.BackgroundTransparency = 1
	label.AutomaticSize = Enum.AutomaticSize.X
	label.Size = UDim2.new(0, 0, 1, 0)
	if env.fontFace then
		pcall(function()
			label.FontFace = env.fontFace
		end)
	elseif env.font then
		label.Font = env.font
	end
	label.TextSize = Tag.TEXT_SIZE
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextStrokeColor3 = Color3.new(0, 0, 0)
	label.TextStrokeTransparency = 0.7
	Tag.show(env, label, text)
	label.LayoutOrder = 1
	label.Parent = row
	if not (type(env.suffix) == "string" and env.suffix ~= "") then
		local spot = Instance.new("Frame")
		spot.Name = "Badge"
		spot.BackgroundTransparency = 1
		spot.Size = UDim2.fromOffset(Tag.BADGE, Tag.BADGE)
		spot.LayoutOrder = 2
		spot.Parent = row
		if env.draw then
			pcall(env.draw, spot, Tag.BADGE)
		end
	end
	return bb, label
end

function Tag.watch(env)
	local st = { alive = true, conns = {}, tags = {}, players = {}, base = setmetatable({}, { __mode = "k" }) }
	local function hold(list, c)
		if c then
			list[#list + 1] = c
		end
	end
	local function cut(list)
		for _, c in ipairs(list) do
			pcall(function()
				c:Disconnect()
			end)
		end
	end
	local function release(p, keep)
		local t = st.tags[p]
		if not t then
			return
		end
		st.tags[p] = nil
		cut(t.conns)
		if t.bb then
			pcall(function()
				t.bb:Destroy()
			end)
		end
		if t.saved and not keep then
			t.busy = true
			set(t.hum, "DisplayDistanceType", t.saved.mode)
			set(t.hum, "NameDisplayDistance", t.saved.name)
			set(t.hum, "HealthDisplayDistance", t.saved.health)
		end
	end
	local apply
	local function wants(p)
		return st.alive and p ~= env.lp and env.has(get(p, "UserId", 0)) == true
	end
	apply = function(p)
		if not st.alive then
			return
		end
		local char = get(p, "Character", nil)
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		local head = char and char:FindFirstChild("Head")
		local cur = st.tags[p]
		if not wants(p) or not hum or not head then
			release(p)
			return
		end
		if cur and (cur.hum ~= hum or cur.head ~= head or not cur.bb.Parent) then
			release(p)
			cur = nil
		end
		if cur then
			Tag.show(env, cur.label, Tag.text(hum, p))
			return
		end
		local saved = st.base[hum] or Tag.read(hum)
		st.base[hum] = nil
		local name, health = Tag.reach(saved, env.viewer and env.viewer() or nil)
		if not name then
			return
		end
		local parent = env.holder and env.holder()
		if not parent then
			return
		end
		local t = { hum = hum, head = head, conns = {}, saved = saved }
		t.busy = true
		set(hum, "DisplayDistanceType", Enum.HumanoidDisplayDistanceType.Subject)
		set(hum, "HealthDisplayDistance", health)
		set(hum, "NameDisplayDistance", 0)
		t.busy = false
		local ok, bb, label = pcall(Tag.build, env, head, name, Tag.text(hum, p))
		if not ok then
			t.busy = true
			set(hum, "DisplayDistanceType", t.saved.mode)
			set(hum, "NameDisplayDistance", t.saved.name)
			set(hum, "HealthDisplayDistance", t.saved.health)
			return
		end
		t.bb, t.label = bb, label
		bb.Parent = parent
		st.tags[p] = t
		local function changed(prop)
			if t.busy or st.tags[p] ~= t then
				return
			end
			local now = Tag.read(hum)
			st.base[hum] = { mode = now.mode, name = prop == "NameDisplayDistance" and now.name or saved.name, health = saved.health }
			release(p, true)
			task.defer(apply, p)
		end
		for _, prop in ipairs({ "DisplayDistanceType", "NameDisplayDistance" }) do
			local okS, sig = pcall(function()
				return hum:GetPropertyChangedSignal(prop)
			end)
			if okS and sig then
				hold(t.conns, sig:Connect(function()
					changed(prop)
				end))
			end
		end
		local okN, sigN = pcall(function()
			return hum:GetPropertyChangedSignal("DisplayName")
		end)
		if okN and sigN then
			hold(t.conns, sigN:Connect(function()
				if st.tags[p] == t then
					Tag.show(env, t.label, Tag.text(hum, p))
				end
			end))
		end
		local okA, sigA = pcall(function()
			return hum.AncestryChanged
		end)
		if okA and sigA then
			hold(t.conns, sigA:Connect(function()
				if st.tags[p] == t and not hum:IsDescendantOf(game) then
					release(p, true)
				end
			end))
		end
	end
	local function track(p)
		if st.players[p] or p == env.lp then
			return
		end
		local conns = {}
		st.players[p] = conns
		local function onChar(char)
			if not char then
				return
			end
			hold(conns, char.ChildAdded:Connect(function(c)
				local n = get(c, "Name", "")
				if n == "Head" or n == "Humanoid" or get(c, "ClassName", "") == "Humanoid" then
					task.defer(apply, p)
				end
			end))
			task.defer(apply, p)
		end
		hold(conns, p.CharacterAdded:Connect(onChar))
		local okR, sigR = pcall(function()
			return p.CharacterRemoving
		end)
		if okR and sigR then
			hold(conns, sigR:Connect(function()
				release(p, true)
			end))
		end
		onChar(get(p, "Character", nil))
	end
	local function untrack(p)
		release(p, true)
		local conns = st.players[p]
		st.players[p] = nil
		if conns then
			cut(conns)
		end
	end
	local players = env.players
	if players then
		for _, p in ipairs(players:GetPlayers()) do
			track(p)
		end
		hold(st.conns, players.PlayerAdded:Connect(track))
		hold(st.conns, players.PlayerRemoving:Connect(untrack))
	end
	function st.refresh()
		for p in pairs(st.players) do
			apply(p)
		end
	end
	function st.count()
		local n = 0
		for _ in pairs(st.tags) do
			n = n + 1
		end
		return n
	end
	function st.stop()
		st.alive = false
		cut(st.conns)
		st.conns = {}
		for p in pairs(st.players) do
			release(p)
			cut(st.players[p])
		end
		st.players = {}
	end
	return st
end

return Tag
