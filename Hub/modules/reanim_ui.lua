local Mod = {}

Mod.SHOW_DESC = false

Mod.TITLES = { hat = "Hat Reanimate", limb = "Limb Reanimate" }
Mod.USED_BY = {
	hat = "Every script in the Hat tab runs on the one you pick here.",
	limb = "Runs the scripts in the Limb tab.",
}
Mod.CARD_H = 64
Mod.GAP = 8
Mod.STACK_BELOW = 300
Mod.OPEN_TIME = 0.25
Mod.PICK_TIME = 0.2
Mod.DRAG_TIME = 0.15

local ctx = nil
local Bus = nil
local live = {}

local function firstLine(text)
	text = tostring(text)
	return (string.match(text, "^[^\r\n]*")) or text
end

local function log(kind, text)
	if ctx and ctx.Log and type(ctx.Log.add) == "function" then
		pcall(ctx.Log.add, kind, "Hub", text)
	end
end

local function fontB()
	return (ctx.Core and ctx.Core.FONT_B) or ctx.FONT_B
end

local function toneColor(tone)
	local T = ctx.T
	if tone == "ok" then
		return T.green
	elseif tone == "warn" then
		return T.yellow
	elseif tone == "bad" then
		return T.red
	end
	return T.dim
end

function Mod.init(context)
	if ctx then
		Mod.destroy()
	end
	ctx = context
	Bus = ctx.Bus
	live = {}
end

function Mod.destroy()
	local list = live
	live = {}
	for _, block in ipairs(list) do
		pcall(block.destroy)
	end
	ctx = nil
end

function Mod.cap(text)
	text = tostring(text or "")
	return (string.gsub(text, "^%l", string.upper))
end

function Mod.stacked(width)
	width = tonumber(width) or 0
	return width > 0 and width < Mod.STACK_BELOW
end

function Mod.groupsOf(defs)
	local out = {}
	local by = {}
	for _, def in ipairs(defs) do
		local name = def.group or "Options"
		local group = by[name]
		if not group then
			group = { name = name, defs = {} }
			by[name] = group
			out[#out + 1] = group
		end
		group.defs[#group.defs + 1] = def
	end
	return out
end

function Mod.choiceList(def)
	local list = {}
	for i, option in ipairs(def.options or {}) do
		local label = def.labels and def.labels[i]
		if label == nil then
			label = option
		end
		list[i] = { option, tostring(label) }
	end
	return list
end

function Mod.stepOf(def)
	if def.step then
		return def.step
	end
	if def.integer then
		return 1
	end
	local span = (def.max or 1) - (def.min or 0)
	if span <= 1 then
		return 0.01
	elseif span <= 10 then
		return 0.1
	end
	return 1
end

function Mod.numberText(def, value)
	local step = Mod.stepOf(def)
	local text
	if def.integer or step >= 1 then
		text = string.format("%d", math.floor(value + 0.5))
	elseif step >= 0.1 then
		text = string.format("%.1f", value)
	else
		text = string.format("%.2f", value)
	end
	if def.unit then
		text = text .. def.unit
	end
	return text
end

function Mod.stateOf(slot, reg)
	local p = slot.provider
	if not p then
		return "Couldn't load: " .. firstLine(slot.failed or "unknown"), "bad"
	end
	local active = reg:activeProvider()
	if active and active.id == p.id then
		local now = reg:state()
		if now == "running" then
			return "Running", "ok"
		elseif now == "starting" then
			return "Starting...", "warn"
		elseif now == "stopping" then
			return "Stopping...", "warn"
		end
	end
	if type(reg.isOff) == "function" and reg.isOff(p.id) then
		return "Off for now", "bad"
	end
	local okA, avail, reason = pcall(p.available, reg.X)
	if not okA then
		return "Not available: " .. firstLine(avail), "bad"
	end
	if avail == false then
		return Mod.cap(reason or "not available here"), "bad"
	end
	return "Ready", "dim"
end

function Mod.soloText(kind, reg, R)
	if R.asking then
		return Mod.cap(R.asking.text) .. " Tap again."
	end
	if R.busy == "starting" then
		return "Starting..."
	elseif R.busy == "stopping" then
		return "Stopping..."
	end
	local active = reg:activeProvider()
	if active and active.kind == kind then
		return "Deanimate " .. active.name
	end
	local sel = reg:selected(kind)
	if not sel then
		return "Pick one above to reanimate"
	end
	return "Reanimate with " .. sel.name
end

function Mod.options(parent, order, id, R)
	R = R or ctx.Core.Reanim
	local out = { rows = {}, last = order }
	local reg = R and R.reg
	local p = reg and reg:get(id)
	if not p then
		return out
	end
	local Ctl = ctx.Ctl
	local n = order
	local defs = reg:optionDefs(id)

	local function put(control)
		out.rows[#out.rows + 1] = control
		return control
	end

	local function value(def)
		return reg:optionsOf(id)[def.key]
	end

	local function apply(def, v)
		local ok, clean, later = reg:setOption(id, def.key, v)
		if not ok then
			ctx.notify(p.name, Mod.cap(clean), "info", 3)
			return false
		end
		if later then
			pcall(ctx.notify, p.name, Mod.cap(later), "info", 2.5)
		end
		return true
	end

	local function describe(def)
		if def.desc and Mod.SHOW_DESC then
			Ctl.note(parent, n, def.desc)
			n = n + 1
		end
	end

	if #defs == 0 then
		Ctl.note(parent, n, p.name .. " has no options")
		out.last = n
		return out
	end
	local later = false
	for _, def in ipairs(defs) do
		if def.applies ~= "now" then
			later = true
		end
	end
	if Mod.SHOW_DESC then
		Ctl.note(parent, n, p.name .. " options" .. (later and ". Changes apply the next time you reanimate." or ""))
		n = n + 1
	end
	for _, group in ipairs(Mod.groupsOf(defs)) do
		ctx.section(parent, group.name, n)
		n = n + 1
		for _, def in ipairs(group.defs) do
			local label = def.label or def.key
			if def.type == "toggle" then
				put(Ctl.toggle(parent, n, label, Mod.SHOW_DESC and def.desc or nil, function()
					return value(def) == true
				end, function(v)
					apply(def, v)
				end))
				n = n + 1
			elseif def.type == "choice" then
				local locked = nil
				if type(def.optionNeeds) == "table" and next(def.optionNeeds) ~= nil then
					locked = function(option)
						local ok, why = reg:optionAvailable(id, def.key, option)
						if ok then
							return nil
						end
						return Mod.cap(why)
					end
				end
				put(Ctl.choice(parent, n, label, Mod.choiceList(def), function()
					return value(def)
				end, function(v)
					apply(def, v)
				end, locked))
				n = n + 1
				local why = locked and locked(value(def)) or nil
				if (def.desc and Mod.SHOW_DESC) or why then
					local text = Mod.SHOW_DESC and def.desc or nil
					if why then
						text = (text and (text .. ". ") or "") .. why .. ", so it falls back by itself."
					end
					Ctl.note(parent, n, text)
					n = n + 1
				end
			elseif def.type == "number" and def.min ~= nil and def.max ~= nil then
				put(Ctl.slider(parent, n, label, def.min, def.max, Mod.stepOf(def), function()
					return value(def)
				end, function(v, final)
					if final ~= false then
						apply(def, v)
					end
				end, function(v)
					return Mod.numberText(def, v)
				end, false))
				n = n + 1
				describe(def)
			elseif def.type == "number" then
				put(Ctl.input(parent, n, label, tostring(def.default), function()
					return tostring(value(def))
				end, function(text)
					local num = tonumber(text)
					if num ~= nil then
						apply(def, num)
					end
				end))
				n = n + 1
				describe(def)
			else
				put(Ctl.input(parent, n, label, tostring(def.default or ""), function()
					return tostring(value(def) or "")
				end, function(text)
					if text == "" then
						text = def.default
					end
					apply(def, text)
				end))
				n = n + 1
				describe(def)
			end
		end
	end
	out.last = n - 1
	return out
end

function Mod.chooser(parent, order, kind, R)
	R = R or ctx.Core.Reanim
	local UI, T = ctx.UI, ctx.T
	local block = { kind = kind, cards = {}, reg = nil, optionId = nil, opts = nil }

	local frame = UI.new("Frame", {
		Name = "Chooser_" .. kind,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = order,
	}, parent)
	UI.list(frame, 6)
	ctx.section(frame, Mod.TITLES[kind], 1)
	if Mod.SHOW_DESC then
		ctx.Ctl.note(frame, 2, Mod.USED_BY[kind])
	end
	local body = UI.new("Frame", {
		Name = "Body",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = 3,
	}, frame)
	UI.list(body, 6)
	block.frame = frame
	block.body = body

	local build
	local refresh

	local function wipe(root)
		for _, child in ipairs(root:GetChildren()) do
			if not child:IsA("UIListLayout") then
				child:Destroy()
			end
		end
	end

	local function slotOf(id)
		local reg = R.reg
		if not reg then
			return nil
		end
		for _, slot in ipairs(reg:slots(kind)) do
			if slot.id == id then
				return slot
			end
		end
		return nil
	end

	local function choose(id)
		local reg = R.reg
		if not reg then
			return
		end
		local current = reg:selected(kind)
		if current and current.id == id then
			return
		end
		local ok, note = reg:select(kind, id)
		local slot = slotOf(id)
		local name = slot and slot.name or "Reanimation"
		if not ok then
			ctx.notify(name, Mod.cap(note), "info", 3)
		elseif note then
			ctx.notify(name, Mod.cap(note), "info", 2.5)
		end
	end

	local function fit(animate)
		local inner = block.inner
		local holder = block.holder
		if not inner or not holder then
			return
		end
		local abs = inner.AbsoluteSize
		local scale = math.max(0.01, (ctx.L and ctx.L.scale) or 1)
		local h = math.ceil(((abs and abs.Y) or 0) / scale)
		if holder.Size.Y.Offset ~= h then
			UI.tween(holder, animate and Mod.OPEN_TIME or 0, { Size = UDim2.new(1, 0, 0, h) })
		end
	end

	local function layoutCards()
		local row = block.cardsRow
		if not row then
			return
		end
		local abs = row.AbsoluteSize
		local scale = math.max(0.01, (ctx.L and ctx.L.scale) or 1)
		local width = ((abs and abs.X) or 0) / scale
		local stacked = Mod.stacked(width)
		block.stacked = stacked
		local h = Mod.CARD_H
		local count = #block.cards
		row.Size = UDim2.new(1, 0, 0, stacked and (count * h + (count - 1) * Mod.GAP) or h)
		for i, card in ipairs(block.cards) do
			if stacked then
				card.btn.Position = UDim2.fromOffset(0, (i - 1) * (h + Mod.GAP))
				card.btn.Size = UDim2.new(1, 0, 0, h)
			else
				card.btn.Position = UDim2.new((i - 1) / count, (i - 1) * Mod.GAP / count, 0, 0)
				card.btn.Size = UDim2.new(1 / count, -(count - 1) * Mod.GAP / count, 0, h)
			end
		end
	end

	local function paintCard(card, slot, selected, animate)
		local reg = R.reg
		local t = animate and Mod.PICK_TIME or 0
		card.name.Text = slot.name
		local text, tone = Mod.stateOf(slot, reg)
		card.state.Text = text
		card.state.TextColor3 = toneColor(tone)
		card.selected = selected
		UI.tween(card.stroke, t, { Transparency = selected and 0.15 or 1 })
		UI.tween(card.mark, t, { BackgroundTransparency = selected and 0.35 or 0.9 })
		UI.tween(card.tick, t, { ImageTransparency = selected and 0 or 1 })
	end

	local function showOptions(id, animate)
		if not block.inner then
			return
		end
		wipe(block.inner)
		block.optionId = id
		block.opts = id and Mod.options(block.inner, 1, id, R) or nil
		fit(animate)
	end

	local function paintSolo()
		local reg = R.reg
		if not reg or not block.soloLabel then
			return
		end
		block.soloLabel.Text = Mod.soloText(kind, reg, R)
	end

	build = function()
		wipe(body)
		block.cards = {}
		block.opts = nil
		block.optionId = nil
		block.cardsRow, block.holder, block.inner, block.soloLabel = nil, nil, nil, nil
		local reg = R.reg
		block.reg = reg
		if reg then
			local slots = reg:slots(kind)
			for i, slot in ipairs(slots) do
			end
		end
		if not reg then
			local text = R.loadError and ("Couldn't load: " .. firstLine(R.loadError)) or "Reanimation is getting ready..."
			UI.label(body, {
				Name = "Waiting",
				Text = text,
				TextSize = 11,
				TextColor3 = R.loadError and T.red or T.sub,
				TextWrapped = true,
				Size = UDim2.new(1, 0, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				LayoutOrder = 1,
			})
			if R.loadError and type(R.retry) == "function" then
				ctx.Ctl.action(body, 2, "Try again", "rotate-ccw", false, function()
					R.retry()
				end)
			end
			return
		end
		local row = UI.new("Frame", {
			Name = "Cards",
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, Mod.CARD_H),
			LayoutOrder = 1,
		}, body)
		block.cardsRow = row
		for _, slot in ipairs(reg:slots(kind)) do
			local card = { id = slot.id }
			local btn = UI.button(row, { Name = "Card_" .. slot.id, BackgroundColor3 = T.card, Size = UDim2.new(0.5, -4, 0, Mod.CARD_H) })
			UI.corner(btn, 14)
			card.btn = btn
			card.stroke = UI.stroke(btn, ctx.accentColor(), 1.5, 1)
			UI.accent(card.stroke, "Color")
			card.mark = UI.new("Frame", {
				Name = "Mark",
				BackgroundTransparency = 0.9,
				AnchorPoint = Vector2.new(1, 0),
				Position = UDim2.new(1, -10, 0, 10),
				Size = UDim2.fromOffset(20, 20),
			}, btn)
			UI.corner(card.mark, 10)
			UI.accent(card.mark, "BackgroundColor3")
			card.tick = UI.icon("check", 12, T.text, card.mark, { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), ImageTransparency = 1 })
			card.name = UI.label(btn, { Name = "Name", Font = fontB(), TextSize = 13, Position = UDim2.fromOffset(12, 10), Size = UDim2.new(1, -44, 0, 18), TextTruncate = Enum.TextTruncate.AtEnd })
			card.state = UI.label(btn, { Name = "State", Font = fontB(), TextSize = 10, Position = UDim2.fromOffset(12, 34), Size = UDim2.new(1, -24, 0, 16), TextTruncate = Enum.TextTruncate.AtEnd })
			UI.pressable(btn, 0.97)
			btn.Activated:Connect(function()
				choose(slot.id)
			end)
			block.cards[#block.cards + 1] = card
		end
		row:GetPropertyChangedSignal("AbsoluteSize"):Connect(layoutCards)
		layoutCards()
		block.holder = UI.new("Frame", {
			Name = "Options",
			BackgroundTransparency = 1,
			ClipsDescendants = true,
			Size = UDim2.new(1, 0, 0, 0),
			LayoutOrder = 2,
		}, body)
		block.inner = UI.new("Frame", {
			Name = "Inner",
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
		}, block.holder)
		UI.list(block.inner, 6)
		block.inner:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
			fit(true)
		end)
		local _, label = ctx.Ctl.action(body, 3, Mod.soloText(kind, reg, R), "person-standing", false, function()
			local now = R.reg
			if not now then
				return
			end
			local active = now:activeProvider()
			if R.asking or (active and active.kind == kind) then
				R.stop()
			else
				R.startSolo(kind)
			end
		end)
		block.soloLabel = label
		refresh(false)
	end

	refresh = function(animate)
		if block.dead or not frame.Parent then
			return
		end
		local reg = R.reg
		if reg ~= block.reg or (reg and not block.cardsRow) then
			build()
			return
		end
		if not reg then
			return
		end
		local picked = reg:selected(kind)
		local selId = picked and picked.id or nil
		local slots = reg:slots(kind)
		for i, card in ipairs(block.cards) do
			local slot = slots[i]
			if slot and slot.id == card.id then
				paintCard(card, slot, slot.id == selId, animate)
			end
		end
		if selId ~= block.optionId then
			showOptions(selId, animate)
		else
			for _, control in ipairs(block.opts and block.opts.rows or {}) do
				local box = control.box
				local typing = box and type(box.IsFocused) == "function" and box:IsFocused()
				if control.render and not typing then
					pcall(control.render, false)
				end
			end
		end
		paintSolo()
	end

	block.render = function()
		refresh(false)
	end

	local handler = function()
		if block.dead or not block.frame.Parent then
			return
		end
		local ok, e = pcall(refresh, true)
		if not ok then
			log("error", "reanimation chooser: " .. firstLine(e))
		end
	end
	block.handler = handler
	block.Bus = Bus
	Bus.on("reanim", handler)

	block.destroy = function()
		if block.dead then
			return
		end
		block.dead = true
		block.Bus.off("reanim", handler)
		for i = #live, 1, -1 do
			if live[i] == block then
				table.remove(live, i)
			end
		end
		pcall(function()
			frame:Destroy()
		end)
	end

	live[#live + 1] = block
	build()
	return block
end

function Mod.section(parent, order, R)
	R = R or ctx.Core.Reanim
	local group = {}
	ctx.section(parent, "Reanimation", order)
	if Mod.SHOW_DESC then
		ctx.Ctl.note(parent, order + 1, "Choose which reanimate runs your scripts. Tap one to select it, then change its options below it.")
	end
	group.hat = Mod.chooser(parent, order + 2, "hat", R)
	group.limb = Mod.chooser(parent, order + 3, "limb", R)
	group.render = function()
		group.hat.render()
		group.limb.render()
	end
	group.destroy = function()
		group.hat.destroy()
		group.limb.destroy()
	end
	return group
end

return Mod