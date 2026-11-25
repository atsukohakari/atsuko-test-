local Mod = {}

Mod.PARTS = {
	{ "Head", "Head" },
	{ "Torso", "Torso" },
	{ "Left Arm", "L Arm" },
	{ "Right Arm", "R Arm" },
	{ "Left Leg", "L Leg" },
	{ "Right Leg", "R Leg" },
}
Mod.JOBS = {
	{ "AK-47", { "gun", "bullet" } },
	{ "Addict", { "gun", "bullet" } },
	{ "Banisher", { "gun", "bullet" } },
	{ "Book Reader", { "book" } },
	{ "Commander V2", { "gun", "bullet" } },
	{ "Dubstep Gun", { "gun", "aura" } },
	{ "InternalWar", { "head", "torso", "rarm", "larm", "rleg", "lleg" } },
	{ "Last Star", { "sword" } },
	{ "Linked Sword", { "sword", "gun", "bullet" } },
	{ "Master Chief", { "rifle", "shotgun", "bullet" } },
	{ "Neptunian V", { "sword" } },
	{ "Neptunian V Gun", { "sword", "gun", "slash", "bullet" } },
	{ "Snake Banisher V3", { "gun1", "gun2" } },
	{ "Studio Dummy V4", { "gun", "screen", "head", "bullet" } },
	{ "The Hotline", { "gun", "bullet" } },
	{ "The Sniper", { "gun", "bullet" } },
}
Mod.JOB_NAMES = {
	gun = "Gun",
	bullet = "Bullet",
	book = "Book",
	aura = "Aura",
	sword = "Sword",
	slash = "Slash",
	gun1 = "Gun 1",
	gun2 = "Gun 2",
	screen = "Screen",
	head = "Head",
	torso = "Torso",
	rarm = "Right arm",
	larm = "Left arm",
	rleg = "Right leg",
	lleg = "Left leg",
	rifle = "Rifle",
	shotgun = "Shotgun",
}
Mod.TARGETS = {
	{ "rig", "Rig" },
	{ "weapon", "Weapon" },
	{ "script", "One script" },
}
Mod.WEAPONS = {
	{ "any", "Any" },
	{ "gun", "Gun" },
	{ "sword", "Sword" },
	{ "shotgun", "Shotgun" },
	{ "rifle", "Rifle" },
}
Mod.SHARED = { "gun", "sword", "shotgun", "rifle", "any" }
Mod.SHARED_SLOTS = {
	gun = { gun = true, gun1 = true, rifle = true, shotgun = true },
	sword = { sword = true },
	shotgun = { shotgun = true },
	rifle = { rifle = true },
	any = { gun = true, gun1 = true, sword = true, shotgun = true, rifle = true },
}
Mod.MAX_DRAWN = 40
Mod.MAX_WORN = 12
Mod.MAX_COUNT = 8

local ctx = nil
local live = {}

local function trim(text)
	return (string.match(tostring(text or ""), "^%s*(.-)%s*$"))
end

local function toast(title, text, kind, seconds)
	if ctx then
		pcall(ctx.notify, title, text, kind, seconds)
	end
end

function Mod.init(context)
	ctx = context
end

function Mod.destroy()
	local list = live
	live = {}
	for _, block in ipairs(list) do
		pcall(block.destroy)
	end
	ctx = nil
end

Mod.ADD_REANIM = "Reanimate first, hats can only be added while you're reanimated"

function Mod.canAdd()
	if not ctx or type(ctx.reanimated) ~= "function" then
		return true
	end
	local ok, on = pcall(ctx.reanimated)
	return ok and on == true
end

function Mod.cap(text)
	text = tostring(text or "")
	return (string.gsub(text, "^%l", string.upper))
end

function Mod.newDraft()
	return { part = "Head", script = "", slot = "", hat = "", mesh = "", tex = "", acc = "", align = "", count = "1", note = "" }
end

function Mod.isShared(target)
	return type(target) == "string" and Mod.SHARED_SLOTS[target] ~= nil
end

function Mod.groupOf(target)
	if Mod.isShared(target) then
		return "weapon"
	end
	return target
end

function Mod.targetOf(draft)
	local t = draft and draft.target
	if t == "weapon" then
		return "gun"
	end
	if t == "rig" or t == "script" or Mod.isShared(t) then
		return t
	end
	if draft and type(draft.script) == "string" and draft.script ~= "" then
		return "script"
	end
	return "rig"
end

function Mod.usersOf(kind)
	local out = {}
	local slots = Mod.SHARED_SLOTS[kind]
	if not slots then
		return out
	end
	for _, item in ipairs(Mod.JOBS) do
		for _, slot in ipairs(item[2]) do
			if slots[slot] then
				out[#out + 1] = item[1]
				break
			end
		end
	end
	return out
end

function Mod.uses(script, item)
	if type(script) ~= "string" or type(item) ~= "table" then
		return false
	end
	if item.section == "rig" then
		return true
	end
	if item.section == "script" then
		return item.target == script
	end
	for _, name in ipairs(Mod.usersOf(item.target)) do
		if name == script then
			return true
		end
	end
	return false
end

function Mod.kindText(kind)
	if kind == "any" then
		return "weapon"
	end
	return tostring(kind)
end

function Mod.whoText(target)
	if Mod.isShared(target) then
		local users = Mod.usersOf(target)
		local lead = target == "any" and "Every script with a gun, a sword, a shotgun or a rifle uses it as that weapon, the next time it starts: " or ("Every script with a " .. target .. " uses it, the next time it starts: ")
		return lead .. table.concat(users, ", ") .. ". Wear the hat and the script picks it up."
	end
	if target == "script" then
		return "Only the script you pick uses it, for the job you pick: a bullet, an aura, a part of InternalWar's titan."
	end
	return "It goes on that body part on every reanimation (Script Reanimate and FDless), for every hat script, the next time you reanimate."
end

function Mod.scriptKey(name)
	if type(name) ~= "string" or name == "" then
		return nil
	end
	for _, item in ipairs(Mod.JOBS) do
		if item[1] == name then
			return name
		end
	end
	local base = string.match(name, "^(.-)%s*%b()$")
	if base and base ~= "" then
		for _, item in ipairs(Mod.JOBS) do
			if item[1] == base then
				return base
			end
		end
	end
	return nil
end

function Mod.jobsOf(script)
	for _, item in ipairs(Mod.JOBS) do
		if item[1] == script then
			return item[2]
		end
	end
	return {}
end

function Mod.jobName(slot)
	slot = tostring(slot or "")
	return Mod.JOB_NAMES[slot] or Mod.cap(slot)
end

function Mod.targetText(draft)
	local target = Mod.targetOf(draft)
	if Mod.isShared(target) then
		return "Used by: every script with a " .. Mod.kindText(target)
	elseif target == "rig" then
		return "Used by: every reanimation, as a body part"
	end
	if not draft.script or draft.script == "" then
		return "Used by: pick a script"
	end
	return "Used by: " .. draft.script .. "  ·  " .. Mod.jobName(draft.slot)
end

function Mod.numberText(value)
	local text = string.format("%.4f", value)
	text = string.gsub(text, "0+$", "")
	text = string.gsub(text, "%.$", "")
	if text == "-0" then
		return "0"
	end
	return text
end

function Mod.alignText(align)
	local parts = {}
	for i = 1, 6 do
		parts[i] = Mod.numberText(align[i] or 0)
	end
	return table.concat(parts, " ")
end

function Mod.parseAlign(text)
	text = trim(text)
	if text == "" then
		return nil
	end
	local numbers = {}
	for token in string.gmatch((string.gsub(text, "[,;]", " ")), "%S+") do
		local value = tonumber(token)
		if value == nil or value ~= value or value == math.huge or value == -math.huge then
			return nil, "\"" .. string.sub(token, 1, 20) .. "\" is not a number"
		end
		if #numbers >= 6 then
			return nil, "that is more than six numbers"
		end
		numbers[#numbers + 1] = value
	end
	if #numbers < 3 then
		return nil, "give at least three numbers (x y z), or leave it empty"
	end
	return numbers
end

function Mod.parseCount(text)
	text = trim(text)
	if text == "" then
		return 1
	end
	local value = tonumber(text)
	if value == nil or value ~= value then
		return nil, "how many has to be a number from 1 to " .. Mod.MAX_COUNT
	end
	value = math.floor(value)
	if value < 1 or value > Mod.MAX_COUNT then
		return nil, "how many has to be a number from 1 to " .. Mod.MAX_COUNT
	end
	return value
end

function Mod.rowFromDraft(draft, A)
	local target = Mod.targetOf(draft)
	local forScript = target == "script"
	if forScript and not (type(draft.script) == "string" and draft.script ~= "") then
		return nil, "pick the script it is for"
	end
	local shared = Mod.isShared(target)
	local row = (forScript or shared) and {} or { part = draft.part }
	if shared then
		row.slot = target
	end
	if forScript then
		local known = false
		for _, slot in ipairs(Mod.jobsOf(draft.script)) do
			if slot == draft.slot then
				known = true
			end
		end
		if not known then
			return nil, "pick what the hat does in " .. draft.script
		end
		row.slot = draft.slot
	end
	for _, pair in ipairs({ { "hat", "hat id" }, { "mesh", "mesh id" }, { "tex", "texture id" } }) do
		local text = trim(draft[pair[1]])
		if text ~= "" then
			local id = A.extractId(text)
			if not id then
				return nil, "the " .. pair[2] .. " doesn't look right, use the number or the link"
			end
			row[pair[1]] = id
		end
	end
	local acc = trim(draft.acc)
	if acc ~= "" then
		row.acc = acc
	end
	if not (row.hat or row.mesh or row.tex or row.acc) then
		return nil, "tell me which hat: a hat id, a mesh id, a texture id or the hat's name"
	end
	local align, alignWhy = Mod.parseAlign(draft.align)
	if alignWhy then
		return nil, alignWhy
	end
	row.align = align
	if target == "rig" then
		local count, countWhy = Mod.parseCount(draft.count)
		if not count then
			return nil, countWhy
		end
		if count > 1 then
			row.count = count
		end
	end
	local note = trim(draft.note)
	if note ~= "" then
		row.note = note
	end
	return row
end

function Mod.draftFromRow(row, index, script, target)
	local draft = Mod.newDraft()
	draft.target = target or (script and "script" or "rig")
	draft.part = row.part or "Head"
	draft.script = draft.target == "script" and script or ""
	draft.slot = draft.target == "script" and row.slot or ""
	draft.hat = row.hat or ""
	draft.mesh = row.mesh or ""
	draft.tex = row.tex or ""
	draft.acc = row.acc or ""
	draft.align = row.align and Mod.alignText(row.align) or ""
	draft.count = tostring(row.count or 1)
	draft.note = row.note or ""
	draft.editing = index
	return draft
end

function Mod.rowSummary(row)
	local bits = {}
	if row.mesh then
		bits[#bits + 1] = "mesh " .. row.mesh
	end
	if row.tex then
		bits[#bits + 1] = "tex " .. row.tex
	end
	if row.hat and not row.mesh and not row.tex then
		bits[#bits + 1] = "hat " .. row.hat
	end
	if row.acc then
		bits[#bits + 1] = row.acc
	end
	if row.count and row.count > 1 then
		bits[#bits + 1] = "x" .. row.count
	end
	if #bits == 0 then
		return "no ids"
	end
	return table.concat(bits, "  ·  ")
end

function Mod.statusText(status, where)
	if type(status) ~= "table" then
		return "not loaded yet"
	end
	local text = status.rigRows .. " shipped, " .. status.userRows .. " yours"
	if status.source == "net" then
		text = text .. "  ·  " .. tostring(where or "GitHub")
	elseif status.source == "cache" then
		text = text .. "  ·  saved copy"
	else
		text = text .. "  ·  file not found"
	end
	if (status.waiting or 0) > 0 then
		text = text .. ", " .. status.waiting .. " waiting for a lookup"
	end
	if (status.lookupFailed or 0) > 0 then
		text = text .. ", " .. status.lookupFailed .. " not found"
	end
	return text
end

function Mod.rowsText(rows, A)
	local lines = {}
	for _, row in ipairs(rows) do
		lines[#lines + 1] = "\t\t" .. A.rowText(row) .. ","
	end
	return table.concat(lines, "\n")
end

local function wipe(root)
	for _, child in ipairs(root:GetChildren()) do
		if not child:IsA("UIListLayout") then
			child:Destroy()
		end
	end
end

function Mod.build(parent, order)
	local Ctl, UI, T = ctx.Ctl, ctx.UI, ctx.T
	local A = ctx.Core.loadModule("alignment")
	local svc = ctx.Core.alignment and ctx.Core.alignment() or nil
	local block = { alive = true, draft = Mod.newDraft(), busy = false, controls = {} }
	local frame = UI.new("Frame", {
		Name = "Hats",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = order,
	}, parent)
	UI.list(frame, 6)
	block.frame = frame
	ctx.section(frame, "Hats & alignment", 1)
	live[#live + 1] = block
	block.destroy = function()
		block.alive = false
		frame:Destroy()
	end
	if not (A and svc) then
		Ctl.note(frame, 2, "The hat part didn't load, so this stays empty. Reload the hub and look again.")
		return block
	end

	local function where()
		local origin = ctx.Origin
		return origin and origin.where and origin.where() or "GitHub"
	end

	local function holder(name, at)
		local box = UI.new("Frame", {
			Name = name,
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			LayoutOrder = at,
		}, frame)
		UI.list(box, 6)
		return box
	end

	block.status = Ctl.info(frame, 2, "Alignment file", Mod.statusText(svc:status(), where()))
	Ctl.note(frame, 3, "Set your hats once: the rig hats go on your body parts on every reanimation. A weapon hat is used by every script with that weapon: the gun hat by every script that has a gun (Master Chief's rifle and shotgun too), the sword hat by every script that has a sword, and the shotgun and rifle hats by the scripts that have those. Any is all of them at once: the gun in the gun scripts and the sword in the sword scripts. One script gives a hat a job in a single script only. Limb reanimates don't use hats for their body. New hats can only be added while you're reanimated.")

	local applyTarget

	local function renderAll()
		for _, control in pairs(block.controls) do
			control.render()
		end
		if block.add then
			block.add.set("plus", block.draft.editing and "Save changes" or "Add hat")
		end
		if applyTarget then
			applyTarget()
		end
	end

	local pickOpen = nil
	local function closePicker()
		pickOpen = nil
		if block.picker then
			wipe(block.picker)
		end
	end
	local openPicker
	function openPicker(kind)
		if pickOpen == kind then
			closePicker()
			return
		end
		closePicker()
		pickOpen = kind
		if kind == "target" then
			for i, item in ipairs(Mod.JOBS) do
				Ctl.action(block.picker, i, item[1], "file-code", false, function()
					block.draft.script = item[1]
					block.draft.slot = item[2][1] or ""
					closePicker()
					applyTarget()
					openPicker("job")
				end)
			end
			return
		end
		local data = svc:data()
		local docs = data and data.slots and data.slots[block.draft.script] or {}
		for i, slot in ipairs(Mod.jobsOf(block.draft.script)) do
			local desc = docs[slot]
			Ctl.action(block.picker, i, Mod.jobName(slot) .. (desc and ("  ·  " .. desc) or ""), "crosshair", false, function()
				block.draft.slot = slot
				closePicker()
				applyTarget()
			end)
		end
	end
	block.weapon = "gun"
	block.controls.target = Ctl.choice(frame, 4, "Used for", Mod.TARGETS, function()
		return Mod.groupOf(Mod.targetOf(block.draft))
	end, function(value)
		if value == "weapon" then
			value = Mod.isShared(block.weapon) and block.weapon or "gun"
		end
		block.draft.target = value
		if value == "script" and (block.draft.script or "") == "" then
			local first = Mod.JOBS[1]
			block.draft.script = first[1]
			block.draft.slot = first[2][1] or ""
		end
		closePicker()
		renderAll()
	end)
	block.controls.weapon = Ctl.choice(frame, 5, "Weapon", Mod.WEAPONS, function()
		local t = Mod.targetOf(block.draft)
		return Mod.isShared(t) and t or block.weapon
	end, function(value)
		block.weapon = value
		block.draft.target = value
		closePicker()
		applyTarget()
	end)
	block.who = Ctl.note(frame, 6, Mod.whoText(Mod.targetOf(block.draft)))
	local targetBtn, targetLabel = Ctl.action(frame, 7, Mod.targetText(block.draft), "users", false, function()
		openPicker("target")
	end)
	local jobBtn, jobLabel = Ctl.action(frame, 8, "", "crosshair", false, function()
		openPicker("job")
	end)
	block.targetLabel, block.jobBtn, block.targetBtn = targetLabel, jobBtn, targetBtn
	block.picker = holder("Picker", 9)
	targetBtn.Name = "Target"
	jobBtn.Name = "Job"

	local partOptions = {}
	for i, pair in ipairs(Mod.PARTS) do
		partOptions[i] = { pair[1], pair[2] }
	end
	block.controls.part = Ctl.choice(frame, 10, "Body part", partOptions, function()
		return block.draft.part
	end, function(value)
		block.draft.part = value
	end)
	local function field(at, key, title, placeholder)
		block.controls[key] = Ctl.input(frame, at, title, placeholder, function()
			return block.draft[key]
		end, function(text)
			block.draft[key] = text
		end)
	end
	field(11, "hat", "Hat id or catalog link", "optional, like 4506945409")
	field(12, "mesh", "Mesh id", "optional, when you have it")
	field(13, "tex", "Texture id", "optional")
	field(14, "acc", "Hat name on your character", "optional")
	field(15, "align", "Alignment: x y z rx ry rz", "0 0 0 0 0 0")
	Ctl.note(frame, 16, "Studs for x y z, degrees for the three turns. Leave it empty to keep the reanimate's own default.")
	field(17, "count", "How many of this hat", "1")

	function applyTarget()
		local target = Mod.targetOf(block.draft)
		local body = target == "rig"
		local one = target == "script"
		if Mod.isShared(target) then
			block.weapon = target
		end
		block.controls.weapon.row.Visible = Mod.isShared(target)
		block.controls.part.row.Visible = body
		block.controls.count.row.Visible = body
		targetLabel.Text = Mod.targetText(block.draft)
		targetBtn.Visible = one
		jobBtn.Visible = one
		jobLabel.Text = "What it does: " .. Mod.jobName(block.draft.slot)
		block.who.Text = Mod.whoText(target)
	end
	applyTarget()

	local function refreshStatus()
		block.status.Text = Mod.statusText(svc:status(), where())
	end

	local function syncDraft()
		for key, control in pairs(block.controls) do
			if control.box then
				block.draft[key] = control.box.Text
			end
		end
	end

	local drawYours

	local function clearDraft()
		block.draft = Mod.newDraft()
		renderAll()
	end

	local function sectionOf(target, script)
		if Mod.isShared(target) then
			return "shared", target
		end
		if target == "script" and script and script ~= "" then
			return "scripts", script
		end
		return "rig", nil
	end

	local function sameList(target, script)
		local mine = Mod.targetOf(block.draft)
		if mine ~= target then
			return false
		end
		return target ~= "script" or (block.draft.script or "") == (script or "")
	end

	local function edit(index, target, script)
		local section, name = sectionOf(target, script)
		local row = svc:userRows(section, name)[index]
		if not row then
			return
		end
		closePicker()
		block.draft = Mod.draftFromRow(row, index, target == "script" and name or nil, target)
		renderAll()
		toast("Editing", Mod.rowSummary(row), "info", 2)
	end

	local function remove(index, target, script)
		local section, name = sectionOf(target, script)
		local ok, why, saved, note = svc:remove(section, name, index)
		if not ok then
			toast("Hats", Mod.cap(why), "info", 3)
			return
		end
		local same = sameList(target, script)
		if same and block.draft.editing == index then
			clearDraft()
		elseif same and block.draft.editing and block.draft.editing > index then
			block.draft.editing = block.draft.editing - 1
		end
		if saved == false then
			toast("Removed, but not saved", Mod.cap(note or ""), "info", 4)
		else
			toast("Hat removed", "", "ok", 1.5)
		end
		drawYours()
		refreshStatus()
	end

	function drawYours()
		wipe(block.yours)
		local lists = { { "rig", nil, svc:userRows("rig") } }
		for _, kind in ipairs(Mod.SHARED) do
			lists[#lists + 1] = { kind, nil, svc:userRows("shared", kind) }
		end
		for _, item in ipairs(Mod.JOBS) do
			local rows = svc:userRows("scripts", item[1])
			if #rows > 0 then
				lists[#lists + 1] = { "script", item[1], rows }
			end
		end
		local order, drawn, extra = 0, 0, 0
		for _, set in ipairs(lists) do
			local target, script, rows = set[1], set[2], set[3]
			for i, row in ipairs(rows) do
				if drawn >= Mod.MAX_DRAWN then
					extra += 1
				else
					drawn += 1
					local title = row.part
					if Mod.isShared(target) then
						title = (target == "any" and "Any weapon" or Mod.cap(target)) .. "  ·  every script with a " .. Mod.kindText(target)
					elseif target == "script" then
						title = script .. "  ·  " .. Mod.jobName(row.slot)
					end
					order += 1
					Ctl.info(block.yours, order, title, Mod.rowSummary(row))
					order += 1
					Ctl.buttons(block.yours, order, {
						{ "pencil", "Edit", function()
							edit(i, target, script)
						end },
						{ "trash-2", "Remove", function()
							remove(i, target, script)
						end, T.red },
					}, 32)
				end
			end
		end
		if drawn == 0 then
			Ctl.note(block.yours, 1, "You haven't added any hats yet")
			return
		end
		if extra > 0 then
			Ctl.note(block.yours, order + 1, "and " .. extra .. " more, " .. (extra == 1 and "it still works" or "they all still work"))
		end
	end

	local function submit()
		if block.busy then
			return
		end
		syncDraft()
		if not block.draft.editing and not Mod.canAdd() then
			toast("Hats", Mod.ADD_REANIM, "info", 3.5)
			return
		end
		local row, why = Mod.rowFromDraft(block.draft, A)
		if not row then
			toast("Hats", Mod.cap(why), "info", 3.5)
			return
		end
		block.busy = true
		task.spawn(function()
			local final, reason = svc:fill(row)
			if not final then
				block.busy = false
				toast("Couldn't look that hat up", Mod.cap(reason), "error", 5)
				return
			end
			local editing = block.draft.editing
			local target = Mod.targetOf(block.draft)
			local section, name = sectionOf(target, block.draft.script)
			local ok, result, saved, note
			if editing then
				ok, result, saved, note = svc:replace(section, name, editing, final)
			else
				ok, result, saved, note = svc:add(section, name, final)
			end
			block.busy = false
			if not block.alive then
				return
			end
			if not ok then
				toast("Hats", Mod.cap(result), "info", 3.5)
				return
			end
			local when = "Used the next time you reanimate"
			if section == "shared" then
				when = "Every script with a " .. Mod.kindText(name) .. " uses it the next time it starts"
			elseif section == "scripts" then
				when = "Used the next time you start " .. name
			end
			toast(editing and "Hat saved" or "Hat added", when, "ok", 2.5)
			if saved == false then
				toast("Not saved to a file", Mod.cap(note or ""), "info", 5)
			end
			local keepScript, keepSlot = block.draft.script, block.draft.slot
			clearDraft()
			block.draft.target = target
			block.draft.script, block.draft.slot = keepScript, keepSlot
			renderAll()
			drawYours()
			refreshStatus()
		end)
	end

	local buttons = Ctl.buttons(frame, 18, {
		{ "plus", "Add hat", submit },
		{ "x", "Clear", function()
			closePicker()
			clearDraft()
		end },
	}, 38)
	block.add = buttons[1]

	ctx.section(frame, "Hats you wear", 20)
	block.worn = holder("Worn", 22)
	local function useWorn(hat)
		syncDraft()
		block.draft.hat = ""
		block.draft.mesh = hat.mesh or ""
		block.draft.tex = hat.tex or ""
		block.draft.acc = hat.name or ""
		renderAll()
		toast("Filled in", tostring(hat.name or ("mesh " .. tostring(hat.mesh or "?"))), "ok", 1.5)
	end
	local function readWorn()
		wipe(block.worn)
		local character = ctx.LP and ctx.LP.Character
		local list = nil
		if type(ctx.reanimHats) == "function" then
			local ok, found = pcall(ctx.reanimHats)
			if ok and type(found) == "table" and #found > 0 then
				list = found
			end
		end
		list = list or A.wornHats(character)
		if #list == 0 then
			Ctl.note(block.worn, 1, "No hats found on your character right now")
			return
		end
		for i = 1, math.min(#list, Mod.MAX_WORN) do
			local hat = list[i]
			local text = tostring(hat.name or "Hat") .. (hat.mesh and ("  ·  mesh " .. hat.mesh) or "  ·  no mesh found")
			Ctl.action(block.worn, i, text, "plus", false, function()
				useWorn(hat)
			end)
		end
		if #list > Mod.MAX_WORN then
			local extra = #list - Mod.MAX_WORN
			Ctl.note(block.worn, Mod.MAX_WORN + 1, "and " .. extra .. (extra == 1 and " more hat" or " more hats"))
		end
	end
	Ctl.action(frame, 21, "Read the hats I'm wearing", "glasses", false, readWorn)

	ctx.section(frame, "Your hats", 30)
	block.yours = holder("Yours", 32)
	drawYours()

	local function reload()
		if block.busy then
			return
		end
		block.busy = true
		task.spawn(function()
			local ok, status = svc:load()
			local found, failed = svc:resolvePending()
			block.busy = false
			if not block.alive then
				return
			end
			drawYours()
			refreshStatus()
			if not ok then
				toast("Hats", Mod.cap(status.err), "error", 4)
			elseif #failed > 0 then
				toast("Reloaded", "Couldn't look up " .. #failed .. (#failed == 1 and " hat" or " hats") .. ": " .. Mod.cap(failed[1].why), "info", 5)
			else
				local ready = svc:status().published
				toast("Reloaded", ready .. (ready == 1 and " hat" or " hats") .. " ready" .. (found > 0 and (", looked up " .. found) or ""), "ok", 2.5)
			end
		end)
	end

	Ctl.buttons(frame, 40, {
		{ "copy", "Copy rows", function()
			local text = Mod.rowsText(svc:userRows("rig"), A)
			if text == "" then
				toast("Nothing to copy", "Add a body part hat first, Copy file has the script ones", "info", 3)
				return
			end
			ctx.copyText(text, "your rows, paste them inside rig = { } in Alignment/alignment.lua")
		end },
		{ "file-code", "Copy file", function()
			ctx.copyText(svc:userText(), "your whole hat file")
		end },
		{ "refresh-cw", "Reload", reload },
	}, 38)
	Ctl.note(frame, 41, "Your hats are saved in AtsukoHub/alignment_user.lua and go first, before the shipped ones. When you line a hat up with Alignment, the spot is saved there too, for that hat only.")

	return block
end

return Mod
