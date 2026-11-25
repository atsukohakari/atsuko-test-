local hub = readsource("Hub/AtsukoHub.lua")
local Manifest = loadmodule("Hub/modules/manifest.lua")

local NAMES = { "Core", "Util", "Repo", "S", "Runner", "THEME", "UI", "FONT_B", "Enum", "UDim2", "Vector2", "accentColor", "Detail", "SHARED", "Log", "HUB", "Ctl", "section", "emptyState", "skeleton", "Panel", "Scripts" }
local saved = {}
for _, name in ipairs(NAMES) do
	saved[name] = _G[name]
end

local function slice(from, to)
	local first = string.find(hub, from, 1, true)
	T.ok(first ~= nil, "found in the hub: " .. from)
	if not first then
		return ""
	end
	local last = string.find(hub, to, first, true)
	T.ok(last ~= nil, "found in the hub: " .. to)
	if not last then
		return ""
	end
	return string.sub(hub, first, last - 1)
end

local function fn(header)
	local first = string.find(hub, "\n" .. header, 1, true)
	T.ok(first ~= nil, "found in the hub: " .. header)
	if not first then
		return ""
	end
	local last = string.find(hub, "\nend\n", first + 1, true)
	T.ok(last ~= nil, "found the end of: " .. header)
	if not last then
		return ""
	end
	return string.sub(hub, first + 1, last + 3)
end

local function theme(code)
	return (string.gsub(code, "([^%w_])T%.(%a+)", "%1THEME.%2"))
end

local function run(code, name)
	local f, err = loadstring(theme(code), "=" .. name)
	T.ok(f ~= nil, name .. " compiles: " .. tostring(err))
	if f then
		f()
	end
end

local function signal()
	local s = { list = {} }
	function s:Connect(f)
		local c = { fn = f, on = true }
		function c:Disconnect()
			self.on = false
		end
		self.list[#self.list + 1] = c
		return c
	end
	function s:Fire(...)
		for _, c in ipairs(self.list) do
			if c.on then
				c.fn(...)
			end
		end
	end
	return s
end

local NOT_GUI = { UIListLayout = true, UIStroke = true, UICorner = true, UIPadding = true }

local function fake(class, props, parent)
	local o = { ClassName = class, Visible = true, Text = "", Name = class, kids = {}, destroyed = false }
	for k, v in pairs(props or {}) do
		o[k] = v
	end
	function o:IsA(c)
		return c == self.ClassName or (c == "GuiObject" and not NOT_GUI[self.ClassName])
	end
	function o:GetChildren()
		local out = {}
		for i, k in ipairs(self.kids) do
			out[i] = k
		end
		return out
	end
	function o:Destroy()
		self.destroyed = true
		local p = self.Parent
		if p then
			for i = #p.kids, 1, -1 do
				if p.kids[i] == self then
					table.remove(p.kids, i)
				end
			end
		end
		self.Parent = nil
	end
	o.Activated = signal()
	if parent then
		o.Parent = parent
		parent.kids[#parent.kids + 1] = o
	end
	return o
end

Enum = setmetatable({}, {
	__index = function(_, group)
		return setmetatable({}, {
			__index = function(_, item)
				return group .. "." .. item
			end,
		})
	end,
})
UDim2 = {
	new = function(...)
		return { ... }
	end,
	fromOffset = function(...)
		return { ... }
	end,
	fromScale = function(...)
		return { ... }
	end,
}
Vector2 = {
	new = function(...)
		return { ... }
	end,
}
FONT_B = "bold"
THEME = setmetatable({}, {
	__index = function(_, k)
		return "T." .. tostring(k)
	end,
})
accentColor = function()
	return "ACCENT"
end

local W = {}

local function reset()
	W = { sections = {}, empties = {}, skeletons = {}, notes = {}, actions = {}, tweens = 0, opened = {}, selected = {}, logs = {}, loads = 0, chooserCalls = {}, hovers = 0 }
end
reset()

UI = {}
function UI.new(class, props, parent)
	return fake(class, props, parent)
end
function UI.button(parent, props)
	return fake("TextButton", props, parent)
end
function UI.label(parent, props)
	return fake("TextLabel", props, parent)
end
function UI.icon(name, size, color, parent, props)
	local o = fake("ImageLabel", props, parent)
	o.Icon = name
	return o
end
function UI.stroke(parent, color, thickness, transparency)
	return fake("UIStroke", { Transparency = transparency }, parent)
end
function UI.corner() end
function UI.accent() end
function UI.pressable() end
function UI.onHover(obj, f)
	obj.hover = f
	W.hovers += 1
end
function UI.tween(obj, _, props)
	W.tweens += 1
	for k, v in pairs(props or {}) do
		obj[k] = v
	end
end
function UI.setIcon(obj, name)
	obj.Icon = name
end
function UI.list(parent)
	return fake("UIListLayout", {}, parent)
end

section = function(parent, text, order)
	local o = fake("Frame", { Name = "Section", LayoutOrder = order, Label = text }, parent)
	W.sections[#W.sections + 1] = { text = text, order = order }
	return o
end
emptyState = function(parent, icon, title, text, order, btnText, btnFn)
	local o = fake("Frame", { Name = "Empty", LayoutOrder = order }, parent)
	W.empties[#W.empties + 1] = { icon = icon, title = title, text = text, order = order, btn = btnText, fn = btnFn }
	return o
end
skeleton = function(parent, n, base)
	for i = 1, n do
		fake("Frame", { Name = "Skeleton", LayoutOrder = (base or 0) + i }, parent)
	end
	W.skeletons[#W.skeletons + 1] = { n = n, base = base }
end
Ctl = {}
function Ctl.note(parent, order, text)
	local o = fake("TextLabel", { Name = "Note", Text = text, LayoutOrder = order }, parent)
	W.notes[#W.notes + 1] = { order = order, text = text }
	return o
end
function Ctl.action(parent, order, text, icon, danger, f)
	local o = fake("TextButton", { Name = "Action", Text = text, LayoutOrder = order }, parent)
	W.actions[#W.actions + 1] = { order = order, text = text, fn = f }
	return o, fake("TextLabel")
end
Detail = {
	open = function(e)
		W.opened[#W.opened + 1] = e.path
	end,
}
Log = {
	add = function(kind, src, msg)
		W.logs[#W.logs + 1] = kind .. "|" .. src .. "|" .. msg
	end,
}
HUB = { alive = true }
SHARED = { running = {} }
Panel = { page = "scripts" }

Util = {}
Core = { SCRIPT_EXT = { lua = true, luau = true, txt = true }, mods = {}, ctx = {}, choosers = {} }
Repo = { entries = {}, byPath = {}, meta = {}, manifest = {}, state = "ready", sig = "" }
S = { favorites = {}, recent = {}, reanimSel = nil }
Runner = { pending = {}, failed = {} }
Scripts = { views = {}, refs = {}, infos = {}, dirty = { true, true, true, true }, tab = 1, query = "" }

run(fn("function Util.trim(s)"), "Util.trim")
run(fn("function Util.fmtSize(bytes)"), "Util.fmtSize")
run(fn("function Util.prettyName(path)"), "Util.prettyName")
run(fn("function Util.firstLine(s)"), "Util.firstLine")
run(fn("function Runner.isActive(rec)"), "Runner.isActive")
run(fn("function Core.makeEntry(path, size)"), "Core.makeEntry")
run(fn("function Repo.visible(e)"), "Repo.visible")
run(fn("function Repo.shown()"), "Repo.shown")
run(fn("function Core.sortEntries(list)"), "Core.sortEntries")
run(fn("function Repo.manifestModule()"), "Repo.manifestModule")
run(fn("function Repo.set(list)"), "Repo.set")
run(fn("function Repo.parseMeta(src)"), "Repo.parseMeta")
run(fn("function Core.entryKind(e)"), "Core.entryKind")
run(fn("function Core.entryCredit(e)"), "Core.entryCredit")
run(fn("function Core.scriptMatch(e, q)"), "Core.scriptMatch")
run(fn("function Core.scriptPlan(tab, query)"), "Core.scriptPlan")
run(fn("function Core.rowSub(e, viewIndex)"), "Core.rowSub")
run(fn("function Core.rowState(e, rec, pending)"), "Core.rowState")
run(fn("function Core.toneColor(tone)"), "Core.toneColor")
run("Core.VIEW_TABS = " .. string.match(slice("Core.VIEW_TABS =", "function Core.entryKind"), "Core.VIEW_TABS = (%b{})"), "Core.VIEW_TABS")
run(fn("function Core.scriptRow(sf, e, order, viewIndex)"), "Core.scriptRow")
run(fn("function Scripts.updateStatus()"), "Scripts.updateStatus")
run(fn("function Scripts.updateInfo()"), "Scripts.updateInfo")
run(fn("function Scripts.wipe(sf)"), "Scripts.wipe")
run(fn("function Core.mountChoosers()"), "Core.mountChoosers")
run(slice("Scripts.EMPTY = {", "\nfunction Scripts.render(i)"), "Scripts.EMPTY")
run(fn("function Scripts.render(i)"), "Scripts.render")
run(fn("function Scripts.invalidate()"), "Scripts.invalidate")
Core.mods.manifest = { mod = Manifest }

Core.Reanim = {
	select = function(path)
		W.selected[#W.selected + 1] = path
	end,
}

local function newViews()
	Scripts.views = {}
	for i = 1, 4 do
		local sf = fake("ScrollingFrame", { Name = "View" .. i })
		fake("UIListLayout", {}, sf)
		Scripts.views[i] = sf
	end
end

local function chooserModule()
	return {
		chooser = function(parent, order, kind, R)
			W.chooserCalls[#W.chooserCalls + 1] = kind .. "@" .. order
			local frame = fake("Frame", { Name = "Chooser_" .. kind, LayoutOrder = order }, parent)
			return {
				frame = frame,
				destroy = function()
					frame:Destroy()
					W.destroyedChooser = (W.destroyedChooser or 0) + 1
				end,
			}
		end,
	}
end

local function setup(opts)
	opts = opts or {}
	reset()
	newViews()
	Scripts.refs, Scripts.infos, Scripts.dirty, Scripts.tab, Scripts.query = {}, {}, { true, true, true, true }, 1, ""
	Repo.entries, Repo.byPath, Repo.meta, Repo.manifest = {}, {}, {}, {}
	Repo.state, Repo.err = "ready", nil
	S.favorites, S.recent, S.reanimSel = {}, {}, nil
	Runner.pending, SHARED.running = {}, {}
	Core.choosers, Core.chooserFailed, Core.chooserLoading = {}, nil, false
	if opts.noModule then
		Core.mods.reanim_ui = nil
	else
		Core.mods.reanim_ui = { mod = chooserModule() }
	end
	HUB.alive = true
	Panel.page = "scripts"
	Core.loadModule = opts.loadModule
	if opts.entries ~= false then
		local ok = Manifest.parse(readsource("Scripts/manifest.json"), jsondecode)
		Repo.manifest = ok or {}
		local list = {}
		for _, path in ipairs({
			"Scripts/Hat/DubstepGun.lua",
			"Scripts/Hat/SnakeBanisherV3.lua",
			"Scripts/Hat/StudioDummyV4-Test.lua",
			"Scripts/Hat/FDless/DubstepGun.lua",
			"Scripts/Hat/FDless/LastStar.lua",
			"Scripts/Hat/FDless/NeptunianV.lua",
			"Scripts/Hat/FDless/NeptunianVGun.lua",
			"Scripts/Hat/FDless/TheHotline.lua",
		}) do
			list[#list + 1] = Core.makeEntry(path, 1000)
		end
		Repo.set(list)
	end
end

local function orderOf(sf)
	local out = {}
	for _, k in ipairs(sf:GetChildren()) do
		if k.LayoutOrder then
			out[#out + 1] = { k.LayoutOrder, k.Name, k }
		end
	end
	table.sort(out, function(a, b)
		return a[1] < b[1]
	end)
	return out
end

local function labelsIn(row)
	local out = {}
	for _, k in ipairs(row.kids) do
		if k.ClassName == "TextLabel" then
			out[k.Name] = k
		end
	end
	return out
end

local function rowsOf(sf)
	local rows = {}
	for _, item in ipairs(orderOf(sf)) do
		if item[2] == "Row" then
			rows[#rows + 1] = item[3]
		end
	end
	return rows
end

T.section("scripts_page: the Hat tab")
do
	setup()
	Scripts.render(1)
	local sf = Scripts.views[1]
	T.eq(Scripts.dirty[1], false, "the tab is marked clean")
	T.same(W.chooserCalls, { "hat@1", "limb@1" }, "both card blocks are built, each first in its own tab")
	local items = orderOf(sf)
	local names = {}
	for _, it in ipairs(items) do
		names[#names + 1] = it[1] .. ":" .. it[2]
	end
	T.eq(names[1], "1:Chooser_hat")
	T.eq(#W.sections, 0, "one list, no group headings")
	local rows = rowsOf(sf)
	T.eq(#rows, 8, "eight scripts are listed")
	T.eq(rows[1].LayoutOrder, 11, "rows start right after the cards")
	T.eq(rows[4].LayoutOrder, 14)
	T.eq(rows[8].LayoutOrder, 18)
	local info = Scripts.infos[1]
	T.ok(info ~= nil, "the footer line exists")
	T.eq(info.LayoutOrder, 19, "the footer comes last")
	T.eq(info.Text, "8 scripts")
	local first = labelsIn(rows[1])
	T.eq(first.Sub.Text, "by Supr14", "a single credit shows as is")
	T.eq(first.State.Text, "", "the hub's own scripts show nothing while idle, they follow your pick")
	local fdless = labelsIn(rows[2])
	T.eq(fdless.Sub.Text, "by Supr14 +2", "the two Dubstep Guns sit next to each other")
	T.eq(fdless.State.Text, "", "a Main Script shows nothing while idle")
	local count = 0
	for path, list in pairs(Scripts.refs) do
		count += #list
		T.eq(#list, 1, path .. " is listed once")
	end
	T.eq(count, 8)
	local limbKids = {}
	for _, k in ipairs(Scripts.views[2]:GetChildren()) do
		limbKids[#limbKids + 1] = k.Name
	end
	T.same(limbKids, { "UIListLayout", "Chooser_limb" }, "the Limb tab only got its cards")
end

T.section("scripts_page: drawing again does not pile rows up")
do
	setup()
	Scripts.render(1)
	local before = #Scripts.views[1]:GetChildren()
	Scripts.render(1)
	Scripts.render(1)
	T.eq(#Scripts.views[1]:GetChildren(), before, "the same number of children after three draws")
	T.eq(#W.chooserCalls, 2, "the cards were built once and kept")
	T.eq(#rowsOf(Scripts.views[1]), 8)
	local n = 0
	for _, list in pairs(Scripts.refs) do
		n += #list
	end
	T.eq(n, 8, "the row list holds each row once")
	local chooserKids = 0
	for _, k in ipairs(Scripts.views[1]:GetChildren()) do
		if k.Name == "Chooser_hat" then
			chooserKids += 1
		end
	end
	T.eq(chooserKids, 1)
end

T.section("scripts_page: the Limb tab")
do
	setup()
	Scripts.render(2)
	T.same(W.chooserCalls, { "hat@1", "limb@1" })
	T.eq(#rowsOf(Scripts.views[2]), 0)
	T.eq(#W.empties, 1)
	T.eq(W.empties[1].title, "No limb scripts yet")
	T.eq(W.empties[1].order, 11, "the message sits under the cards")
	T.eq(Scripts.infos[2], nil, "no footer on an empty tab")
end

T.section("scripts_page: Favorites and Recent")
do
	setup()
	Scripts.render(3)
	T.eq(#W.chooserCalls, 0, "no reanimation cards on Favorites")
	T.eq(W.empties[1].title, "No favorites yet")
	T.eq(W.empties[1].order, 1)
	setup()
	S.favorites["Scripts/Hat/FDless/LastStar.lua"] = true
	S.favorites["Scripts/Hat/SnakeBanisherV3.lua"] = true
	Scripts.render(3)
	local rows = rowsOf(Scripts.views[3])
	T.eq(#rows, 2)
	T.eq(rows[1].LayoutOrder, 1)
	local sub = labelsIn(rows[1]).Sub.Text
	T.eq(sub, "Hat  ·  by MLG Super Killer +1", "Favorites say the kind and the credit")
	T.eq(Scripts.infos[3], nil)
	setup()
	S.recent = { "Scripts/Hat/FDless/TheHotline.lua", "Scripts/Hat/gone.lua" }
	Scripts.render(4)
	rows = rowsOf(Scripts.views[4])
	T.eq(#rows, 1, "a script that is gone is skipped")
	T.eq(labelsIn(rows[1]).Sub.Text, "Hat  ·  by Gelatek Hub +1")
	setup()
	Scripts.render(4)
	T.eq(W.empties[1].title, "Nothing here yet")
end

T.section("scripts_page: search")
do
	setup()
	Scripts.query = "hotline"
	Scripts.render(1)
	T.eq(#rowsOf(Scripts.views[1]), 1)
	T.eq(#W.sections, 0, "a search has no headings either")
	setup()
	Scripts.query = "zzzz"
	Scripts.render(1)
	T.eq(#W.empties, 1)
	T.eq(W.empties[1].title, "Nothing matches")
	T.eq(W.empties[1].order, 11)
	setup()
	Scripts.query = "hotline"
	Scripts.render(2)
	T.eq(W.empties[1].title, "No limb scripts yet", "a search does not hide that a tab has no scripts at all")
end

T.section("scripts_page: loading, error and an empty list")
do
	setup({ entries = false })
	Repo.state = "loading"
	Scripts.render(1)
	T.eq(#W.skeletons, 1)
	T.eq(W.skeletons[1].n, 4)
	T.eq(W.skeletons[1].base, 10, "the placeholders sit under the cards")
	T.eq(#W.chooserCalls, 2, "the cards show while the list loads")
	setup({ entries = false })
	Repo.state = "error"
	Repo.err = "HTTP 404\nmore text"
	Scripts.render(1)
	T.eq(W.empties[1].title, "Couldn't load your scripts")
	T.eq(W.empties[1].text, "HTTP 404", "only the first line of the error")
	T.eq(W.empties[1].btn, "Try again")
	T.eq(type(W.empties[1].fn), "function")
	setup({ entries = false })
	Repo.state = "ready"
	Scripts.render(1)
	T.eq(W.empties[1].title, "No scripts yet")
	setup({ entries = false })
	Repo.state = "idle"
	Scripts.render(1)
	T.eq(#W.skeletons, 1, "idle counts as still loading")
end

T.section("scripts_page: row states follow the run")
do
	setup()
	Scripts.render(1)
	local path = "Scripts/Hat/FDless/LastStar.lua"
	local rowOf = function(p)
		for _, row in ipairs(rowsOf(Scripts.views[1])) do
			if Scripts.refs[p] and Scripts.refs[p][1].e.name == labelsIn(row).Name then
				return row
			end
		end
		return nil
	end
	local ref = Scripts.refs[path][1]
	T.eq(ref.state.Text, "")
	T.eq(ref.dot.Visible, false)
	Runner.pending[path] = true
	Scripts.updateStatus()
	T.eq(ref.state.Text, "Starting")
	T.eq(ref.state.TextColor3, "T.yellow")
	T.eq(ref.dot.Visible, true)
	T.eq(ref.dot.BackgroundColor3, "T.yellow")
	Runner.pending[path] = nil
	SHARED.running[path] = { status = "running", kind = "script" }
	Scripts.updateStatus()
	T.eq(ref.state.Text, "Running")
	T.eq(ref.state.TextColor3, "T.green")
	T.eq(ref.dot.BackgroundColor3, "T.green")
	SHARED.running[path].status = "error"
	Scripts.updateStatus()
	T.eq(ref.state.Text, "Error")
	T.eq(ref.state.TextColor3, "T.red")
	T.eq(ref.dot.BackgroundColor3, "T.red")
	SHARED.running[path] = nil
	Scripts.updateStatus()
	T.eq(ref.state.Text, "")
	T.eq(ref.dot.Visible, false)
	S.favorites[path] = true
	Scripts.updateStatus()
	T.eq(ref.heart.Visible, true)
	S.favorites[path] = nil
	Scripts.updateStatus()
	T.eq(ref.heart.Visible, false)
	local native = Scripts.refs["Scripts/Hat/DubstepGun.lua"][1]
	SHARED.running["Scripts/Hat/DubstepGun.lua"] = { status = "running" }
	Scripts.updateStatus()
	T.eq(native.state.Text, "Running", "a running hub-native script says Running, not what it runs on")
	SHARED.running["Scripts/Hat/DubstepGun.lua"] = nil
	Scripts.updateStatus()
	T.eq(native.state.Text, "")
end

T.section("scripts_page: selecting a script")
do
	setup()
	Scripts.render(1)
	local path = "Scripts/Hat/FDless/NeptunianV.lua"
	local ref = Scripts.refs[path][1]
	local plain = ref.sub.Text
	T.eq(string.sub(plain, 1, 3), "by ")
	S.reanimSel = path
	Scripts.updateStatus()
	T.eq(ref.sub.Text, "Selected  ·  " .. plain)
	T.eq(ref.icon.Icon, "person-standing")
	S.reanimSel = nil
	Scripts.updateStatus()
	T.eq(ref.sub.Text, plain)
	T.eq(ref.icon.Icon, "file-code")
	S.reanimSel = path
	Scripts.render(1)
	local again = Scripts.refs[path][1]
	T.eq(again.sub.Text, "Selected  ·  " .. plain, "a row drawn while selected starts selected")
end

T.section("scripts_page: what a tap does")
do
	setup()
	Scripts.render(1)
	local path = "Scripts/Hat/FDless/TheHotline.lua"
	local ref = Scripts.refs[path][1]
	local row
	for _, r in ipairs(rowsOf(Scripts.views[1])) do
		if labelsIn(r).Sub and r.kids[#r.kids] and r.Activated then
			local label = nil
			for _, k in ipairs(r.kids) do
				if k.ClassName == "TextLabel" and k.Text == ref.e.name then
					label = k
				end
			end
			if label then
				row = r
			end
		end
	end
	T.ok(row ~= nil, "found the row")
	row.Activated:Fire()
	T.same(W.selected, { path }, "a first tap selects")
	T.same(W.opened, {})
	S.reanimSel = path
	row.Activated:Fire()
	T.same(W.opened, { path }, "a tap on the selected row opens its page")
	local info
	for _, k in ipairs(row.kids) do
		if k.Name == "Info" then
			info = k
		end
	end
	T.ok(info ~= nil, "the arrow button exists")
	info.Activated:Fire()
	T.same(W.opened, { path, path }, "the arrow always opens the page")
	T.ok(row.hover ~= nil, "the row reacts to hover")
	row.hover(true)
	row.hover(false)
end

T.section("scripts_page: the footer text")
do
	setup()
	Scripts.render(1)
	Scripts.render(2)
	Repo.state = "loading"
	Scripts.updateInfo()
	T.eq(Scripts.infos[1].Text, "Looking for new scripts...")
	T.eq(Scripts.infos[2], nil)
	Repo.state = "cached"
	Scripts.updateInfo()
	T.eq(Scripts.infos[1].Text, "Saved list  ·  offline")
	Repo.state = "ready"
	Scripts.updateInfo()
	T.eq(Scripts.infos[1].Text, "8 scripts")
	Repo.entries = { Repo.entries[1] }
	Scripts.updateInfo()
	T.eq(Scripts.infos[1].Text, "1 script")
	Scripts.infos[1]:Destroy()
	Scripts.updateInfo()
end

T.section("scripts_page: wiping a tab")
do
	setup()
	local sf = Scripts.views[1]
	fake("Frame", { Name = "Row" }, sf)
	fake("Frame", { Name = "Chooser_hat" }, sf)
	fake("TextLabel", { Name = "Info" }, sf)
	fake("UIPadding", {}, sf)
	Scripts.wipe(sf)
	local left = {}
	for _, k in ipairs(sf:GetChildren()) do
		left[#left + 1] = k.Name
	end
	T.same(left, { "UIListLayout", "Chooser_hat", "UIPadding" }, "only the cards and the layout objects stay")
end

T.section("scripts_page: the reanimation cards")
do
	setup({ noModule = true })
	local calls = {}
	Core.loadModule = function(name, retry)
		calls[#calls + 1] = name .. ":" .. tostring(retry)
		Core.mods.reanim_ui = { mod = chooserModule() }
		return Core.mods.reanim_ui.mod
	end
	Scripts.render(1)
	T.same(calls, { "reanim_ui:true" }, "the module is asked for once")
	T.eq(Core.chooserLoading, false)
	T.eq(#W.chooserCalls, 2, "both blocks are built once it arrives")
	T.eq(W.chooserCalls[1], "hat@1")
	T.eq(W.chooserCalls[2], "limb@1")
	T.ok(Core.choosers[1] ~= nil and Core.choosers[2] ~= nil)
	Scripts.render(1)
	Scripts.render(2)
	T.eq(#W.chooserCalls, 2, "kept across redraws")
	Core.choosers[1].frame:Destroy()
	Scripts.render(1)
	T.eq(#W.chooserCalls, 3, "a card block whose frame is gone is built again")
	T.eq(W.destroyedChooser, 1, "and the old one is cleaned up")
end

T.section("scripts_page: the cards fail to load")
do
	setup({ noModule = true })
	Core.loadModule = function(name)
		return nil, "download failed\nsecond line"
	end
	Scripts.render(1)
	T.eq(Core.chooserFailed, "download failed")
	T.eq(Core.chooserLoading, false)
	task.wait()
	T.eq(#W.notes, 1, "the page says why")
	T.eq(W.notes[1].text, "The reanimation cards didn't load: download failed")
	T.eq(W.notes[1].order, 1)
	T.eq(#W.actions, 1)
	T.eq(W.actions[1].text, "Try again")
	T.eq(W.actions[1].order, 2)
	T.eq(#rowsOf(Scripts.views[1]), 8, "the script list still shows, drawn once even though the failure came at once")
	local count = 0
	for _, list in pairs(Scripts.refs) do
		count += #list
	end
	T.eq(count, 8, "and the row list holds each row once")
	local attempts = 0
	Core.loadModule = function(name)
		attempts += 1
		Core.mods.reanim_ui = { mod = chooserModule() }
		return Core.mods.reanim_ui.mod
	end
	W.actions[1].fn()
	T.eq(Core.chooserFailed, nil, "Try again clears the failure")
	T.eq(attempts, 1)
	T.eq(#W.chooserCalls, 2, "and the cards come")
	local notesLeft = 0
	for _, k in ipairs(Scripts.views[1]:GetChildren()) do
		if k.Name == "Note" or k.Name == "Action" then
			notesLeft += 1
		end
	end
	T.eq(notesLeft, 0, "the failure note is gone")
end

T.section("scripts_page: a card block that errors does not break the page")
do
	setup()
	Core.mods.reanim_ui = {
		mod = {
			chooser = function(parent, order, kind)
				if kind == "hat" then
					error("boom\nmore", 0)
				end
				local frame = fake("Frame", { Name = "Chooser_" .. kind, LayoutOrder = order }, parent)
				return { frame = frame, destroy = function() end }
			end,
		},
	}
	Scripts.render(1)
	T.eq(#W.logs, 1)
	T.eq(W.logs[1], "error|Hub|reanimation cards: boom")
	T.eq(#rowsOf(Scripts.views[1]), 8, "the rows are there anyway")
	T.eq(Core.choosers[1], nil)
	T.ok(Core.choosers[2] ~= nil, "the other block still builds")
end

T.section("scripts_page: the hub closing while the cards load")
do
	setup({ noModule = true })
	local release
	Core.loadModule = function()
		HUB.alive = false
		return nil, "late"
	end
	Scripts.render(1)
	T.eq(Core.chooserFailed, nil, "nothing is shown after the hub closed")
	T.eq(Core.chooserLoading, false)
end

T.section("scripts_page: invalidate redraws only the open tab")
do
	setup()
	Scripts.render(1)
	Scripts.tab = 1
	W.chooserCalls = {}
	Scripts.invalidate()
	T.same(Scripts.dirty, { false, true, true, true }, "tab 1 was redrawn, the rest wait")
	Panel.page = "home"
	Scripts.invalidate()
	T.same(Scripts.dirty, { true, true, true, true }, "off the page nothing is drawn")
end

for _, name in ipairs(NAMES) do
	_G[name] = saved[name]
end
