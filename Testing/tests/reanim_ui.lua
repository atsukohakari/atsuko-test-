local G = loadmodule("Testing/mocks/gui_mock.lua")
local Registry = loadmodule("Reanimation/providers/registry.lua")
local UiMod = loadmodule("Hub/modules/reanim_ui.lua")

local FD_LABELS = {
	"Fling", "Click to fling", "Fling direction", "Fling targeting", "Highlight targets", "Body while flinging",
	"Ctrl + click teleport", "Shift lock", "Hat placeholders", "Real body goes", "Break joints", "Simulation radius",
	"Hide health bar", "Disable character scripts", "Disable GUI scripts",
}

local FD_KEYS = {
	"fling", "clickfling", "flingdirection", "flingtargetting", "highlightflingtargets", "flingchangestate",
	"ctrltp", "allowshiftlock", "placeholders", "respawntp", "breakjointsmethod", "simrad", "hidedeatheffect", "discharscripts", "disguiscripts",
}

local function fullX()
	local X = {}
	for _, name in ipairs({
		"loadstring", "request", "getcustomasset", "readfile", "writefile", "delfile", "isfile", "isfolder", "makefolder",
		"listfiles", "firetouchinterest", "sethiddenproperty", "setscriptable", "replicatesignal", "getobjects",
	}) do
		X[name] = true
	end
	return X
end

local function fakeCtl()
	local C = { made = {} }
	local function make(kind, parent, order, fields)
		local row = Instance.new("Frame")
		row.Name = kind
		row.LayoutOrder = order
		row.Parent = parent
		local rec = { kind = kind, row = row, order = order, parent = parent, rendered = 0 }
		for k, v in pairs(fields) do
			rec[k] = v
		end
		rec.render = function()
			rec.rendered = rec.rendered + 1
		end
		C.made[#C.made + 1] = rec
		return rec
	end
	function C.toggle(parent, order, title, desc, get, set)
		return make("toggle", parent, order, { title = title, desc = desc, get = get, set = set })
	end
	function C.choice(parent, order, title, options, get, set, locked)
		return make("choice", parent, order, { title = title, options = options, get = get, set = set, locked = locked })
	end
	function C.slider(parent, order, title, min, max, step, get, set, fmt, live)
		return make("slider", parent, order, { title = title, min = min, max = max, step = step, get = get, set = set, fmt = fmt, live = live })
	end
	function C.input(parent, order, title, placeholder, get, set)
		local rec = make("input", parent, order, { title = title, placeholder = placeholder, get = get, set = set })
		rec.box = Instance.new("TextBox")
		return rec
	end
	function C.note(parent, order, text)
		local rec = make("note", parent, order, { text = text })
		local label = Instance.new("TextLabel")
		label.Text = text
		label.LayoutOrder = order
		rec.row.Parent = nil
		label.Parent = parent
		rec.row = label
		return label
	end
	function C.action(parent, order, text, icon, danger, fn)
		local rec = make("action", parent, order, { title = text, icon = icon, fn = fn })
		local label = Instance.new("TextLabel")
		label.Text = text
		rec.label = label
		return rec.row, label
	end
	function C.live(kind)
		local out = {}
		for _, rec in ipairs(C.made) do
			if rec.row.Parent ~= nil and (kind == nil or rec.kind == kind) then
				out[#out + 1] = rec
			end
		end
		return out
	end
	function C.find(kind, title)
		for _, rec in ipairs(C.live(kind)) do
			if rec.title == title then
				return rec
			end
		end
		return nil
	end
	return C
end

local function newWorld(opts)
	opts = opts or {}
	local env = G.install({ animations = opts.animations == true })
	local ctx = env.ctx
	local C = fakeCtl()
	ctx.Ctl = C
	local w = { env = env, ctx = ctx, C = C, toasts = {}, calls = {}, saves = 0, S = env.S }
	ctx.notify = function(title, text, _type, _duration)
		w.toasts[#w.toasts + 1] = title .. "|" .. text
	end
	if opts.picked ~= false then
		env.S.hatReanim = "atsuko"
	end
	if opts.S then
		for k, v in pairs(opts.S) do
			env.S[k] = v
		end
	end
	local reg = Registry.new({
		S = env.S,
		save = function()
			w.saves = w.saves + 1
		end,
		fire = function(name, payload)
			env.Bus.fire(name, payload)
		end,
		notify = function() end,
		X = opts.X or fullX(),
		now = time,
		wait = task.wait,
		spawn = task.spawn,
		delay = task.delay,
	})
	for _, id in ipairs(Registry.IDS) do
		if opts.fail and opts.fail[id] then
			reg:markFailed(id, opts.fail[id])
		else
			local mod = loadmodule("Reanimation/providers/" .. id .. ".lua")
			local ok, err = reg:register(mod)
			assert(ok, err)
		end
	end
	w.reg = reg
	w.R = {
		reg = reg,
		busy = nil,
		asking = nil,
		loadError = opts.loadError,
		startSolo = function(kind)
			w.calls[#w.calls + 1] = "solo:" .. kind
		end,
		stop = function()
			w.calls[#w.calls + 1] = "stop"
		end,
	}
	if opts.noReg then
		w.R.reg = nil
	end
	if opts.retry then
		w.R.retry = function()
			w.calls[#w.calls + 1] = "retry"
		end
	end
	ctx.Core.Reanim = w.R
	UiMod.init(ctx)
	w.parent = Instance.new("Frame")
	return w
end

local function saved(w, id, key)
	local all = w.S.reanimOpts
	local mine = all and all[id]
	return mine and mine[key] or nil
end

local function running(w, id)
	w.reg.cur = "running"
	w.reg.activeId = id
end

local function childrenOf(parent)
	local out = {}
	for _, ch in ipairs(parent:GetChildren()) do
		if ch:IsA("GuiObject") then
			out[#out + 1] = ch
		end
	end
	return out
end

local function parts(w, kind)
	local frame = w.parent:FindFirstChild("Chooser_" .. kind)
	local body = frame and frame:FindFirstChild("Body")
	return {
		frame = frame,
		body = body,
		row = body and body:FindFirstChild("Cards"),
		holder = body and body:FindFirstChild("Options"),
		inner = body and body:FindFirstChild("Options") and body:FindFirstChild("Options"):FindFirstChild("Inner"),
	}
end

local function card(w, kind, id)
	local p = parts(w, kind)
	return p.row and p.row:FindFirstChild("Card_" .. id) or nil
end

local function textOf(c, name)
	local label = c:FindFirstChild(name)
	return label and label.Text or nil
end

local function strokeOf(c)
	return c:FindFirstChildOfClass("UIStroke")
end

T.section("reanim_ui: small helpers")
T.eq(UiMod.cap("applies later"), "Applies later")
T.eq(UiMod.cap("Already"), "Already")
T.eq(UiMod.cap(nil), "")
T.eq(UiMod.cap(""), "")
T.eq(UiMod.stacked(0), false, "unknown width counts as wide")
T.eq(UiMod.stacked(nil), false)
T.eq(UiMod.stacked(299), true)
T.eq(UiMod.stacked(300), false)
T.eq(UiMod.stacked(640), false)
T.eq(UiMod.stepOf({ step = 5 }), 5)
T.eq(UiMod.stepOf({ integer = true, min = 0, max = 100 }), 1)
T.eq(UiMod.stepOf({ min = 0, max = 1 }), 0.01)
T.eq(UiMod.stepOf({ min = 0, max = 10 }), 0.1)
T.eq(UiMod.stepOf({ min = 0, max = 200 }), 1)
T.eq(UiMod.numberText({ integer = true }, 34.6), "35")
T.eq(UiMod.numberText({ min = 0, max = 1 }, 0.5), "0.50")
T.eq(UiMod.numberText({ min = 0, max = 10 }, 2.25), "2.2")
T.eq(UiMod.numberText({ min = 0, max = 100 }, 12), "12")
T.eq(UiMod.numberText({ min = 0, max = 100, unit = " studs" }, 12), "12 studs")

local groups = UiMod.groupsOf({
	{ key = "a", group = "One" }, { key = "b", group = "Two" }, { key = "c", group = "One" }, { key = "d" },
})
T.eq(#groups, 3)
T.eq(groups[1].name, "One")
T.eq(#groups[1].defs, 2)
T.eq(groups[2].name, "Two")
T.eq(groups[3].name, "Options", "options with no group still show")
T.eq(groups[3].defs[1].key, "d")

local list = UiMod.choiceList({ options = { 0, 1 }, labels = { "Down", "Up" } })
T.same(list, { { 0, "Down" }, { 1, "Up" } })
T.same(UiMod.choiceList({ options = { "Simple", "Fling" } }), { { "Simple", "Simple" }, { "Fling", "Fling" } })
T.same(UiMod.choiceList({}), {})

T.section("reanim_ui: every FDless option gets a control")
do
	local w = newWorld()
	local out = UiMod.options(w.parent, 1, "fdless", w.R)
	local C = w.C
	T.eq(#out.rows, 15, "one control for each of the 15 options")
	T.eq(#C.live("toggle"), 10)
	T.eq(#C.live("choice"), 5)
	T.eq(#C.live("slider"), 0)
	T.eq(#C.live("input"), 0)
	for _, label in ipairs(FD_LABELS) do
		local found = 0
		for _, rec in ipairs(C.live()) do
			if rec.title == label then
				found = found + 1
			end
		end
		T.eq(found, 1, "label " .. label)
	end
	local titles = {}
	for _, rec in ipairs(C.live()) do
		if rec.kind == "toggle" or rec.kind == "choice" then
			titles[#titles + 1] = rec.title
		end
	end
	T.eq(table.concat(titles, ","), table.concat(FD_LABELS, ","), "the same order as the provider lists them")

	T.section("reanim_ui: FDless layout orders are whole, unique and rising")
	local kids = childrenOf(w.parent)
	T.eq(#kids, 24, "intro note + group headings + controls + descriptions")
	T.eq(out.last, 24)
	local previous = 0
	for i, kid in ipairs(kids) do
		T.eq(math.floor(kid.LayoutOrder), kid.LayoutOrder, "whole number " .. i)
		T.ok(kid.LayoutOrder > previous, "rising " .. i)
		previous = kid.LayoutOrder
	end
	T.eq(kids[1].Text, "FDless options. Changes apply the next time you reanimate.")
	T.eq(kids[2].Text, "Fling")

	T.section("reanim_ui: FDless defaults show as the provider says")
	local want = {
		fling = true, clickfling = false, highlightflingtargets = true, ctrltp = true, allowshiftlock = true,
		placeholders = true, simrad = true, hidedeatheffect = true, discharscripts = true, disguiscripts = true,
	}
	for _, rec in ipairs(C.live("toggle")) do
		local key
		for i, label in ipairs(FD_LABELS) do
			if label == rec.title then
				key = FD_KEYS[i]
			end
		end
		if want[key] ~= nil then
			T.eq(rec.get(), want[key], "default of " .. tostring(key))
		end
	end
	T.eq(C.find("choice", "Fling direction").get(), 0)
	T.eq(C.find("choice", "Fling targeting").get(), 3)
	T.eq(C.find("choice", "Body while flinging").get(), 3)
	T.eq(C.find("choice", "Real body goes").get(), 3)
	T.eq(C.find("choice", "Break joints").get(), 1)
	T.same(C.find("choice", "Fling direction").options, { { 0, "Down" }, { 1, "Up" }, { 2, "Side" } })
	T.same(C.find("choice", "Fling targeting").options, { { 0, "Basic" }, { 1, "Joints" }, { 2, "Script" }, { 3, "Best" } })
	T.same(C.find("choice", "Body while flinging").options, { { 1, "Light" }, { 2, "Ragdoll" }, { 3, "Standard" } })
	T.same(C.find("choice", "Real body goes").options, { { 0, "Same spot" }, { 1, "Nearby" }, { 2, "Beside" }, { 3, "Hidden" } })
	T.same(C.find("choice", "Break joints").options, { { 1, "1" }, { 2, "2" }, { 3, "3" }, { 4, "4" } })
	T.eq(C.find("toggle", "Fling").desc, "Lets the reanimate fling other players", "toggles carry their own description")
	T.eq(C.find("toggle", "Click to fling").desc, "Click a player to fling them. With Ctrl held a click teleports instead")

	T.section("reanim_ui: choices get their description as a note under them")
	local flingDir = C.find("choice", "Fling direction")
	local noteAfter
	for _, kid in ipairs(kids) do
		if kid.LayoutOrder == flingDir.order + 1 then
			noteAfter = kid
		end
	end
	T.ok(noteAfter ~= nil)
	T.eq(noteAfter.Text, "Which way the hats hit a target")
	local breakJoints = C.find("choice", "Break joints")
	for _, kid in ipairs(kids) do
		if kid.LayoutOrder == breakJoints.order + 1 then
			noteAfter = kid
		end
	end
	T.eq(noteAfter.Text, "How your real character's joints are broken. 4 needs replicatesignal")
end

T.section("reanim_ui: changing an FDless option saves it")
do
	local w = newWorld()
	UiMod.options(w.parent, 1, "fdless", w.R)
	local C = w.C
	local fling = C.find("toggle", "Fling")
	T.eq(fling.get(), true)
	fling.set(false)
	T.eq(w.S.reanimOpts.fdless.fling, false, "stored under the provider")
	T.eq(fling.get(), false)
	T.eq(w.saves, 1)
	T.eq(#w.toasts, 0, "nothing to announce while it is not running")
	fling.set(true)
	T.eq(w.S.reanimOpts.fdless.fling, true)
	T.eq(C.find("toggle", "Click to fling").get(), false)
	C.find("toggle", "Click to fling").set(true)
	T.eq(C.find("toggle", "Click to fling").get(), true)
	T.eq(w.S.reanimOpts.fdless.clickfling, true)
	T.eq(C.find("toggle", "Fling").get(), true, "the others are untouched")

	local dir = C.find("choice", "Fling direction")
	dir.set(2)
	T.eq(w.S.reanimOpts.fdless.flingdirection, 2)
	T.eq(dir.get(), 2)
	local state = C.find("choice", "Body while flinging")
	state.set(1)
	T.eq(w.S.reanimOpts.fdless.flingchangestate, 1)
	C.find("choice", "Real body goes").set(0)
	T.eq(w.S.reanimOpts.fdless.respawntp, 0)
	T.eq(w.reg:optionsOf("fdless").respawntp, 0, "the registry hands it to the provider as saved")
	T.eq(w.reg:optionsOf("fdless").flingdirection, 2)
	T.eq(w.reg:optionsOf("fdless").fling, true)
end

T.section("reanim_ui: options the executor can't do are locked and refused")
do
	local X = fullX()
	X.sethiddenproperty = nil
	X.replicatesignal = nil
	local w = newWorld({ X = X })
	UiMod.options(w.parent, 1, "fdless", w.R)
	local C = w.C
	local target = C.find("choice", "Fling targeting")
	T.eq(type(target.locked), "function")
	T.eq(target.locked(3), "Your executor has no sethiddenproperty")
	T.eq(target.locked(2), nil, "Script needs setscriptable, which it has")
	T.eq(target.locked(0), nil)
	T.eq(target.locked(1), nil)
	local joints = C.find("choice", "Break joints")
	T.eq(joints.locked(4), "Your executor has no replicatesignal")
	T.eq(joints.locked(1), nil)
	T.eq(C.find("choice", "Fling direction").locked, nil, "choices with no needs have no lock")
	target.set(3)
	T.eq(saved(w, "fdless", "flingtargetting"), nil, "a refused value is never saved")
	T.eq(w.toasts[#w.toasts], "FDless|Your executor has no sethiddenproperty")
	joints.set(4)
	T.eq(w.toasts[#w.toasts], "FDless|Your executor has no replicatesignal")
	T.eq(saved(w, "fdless", "breakjointsmethod"), nil)
	target.set(1)
	T.eq(w.S.reanimOpts.fdless.flingtargetting, 1, "the other values still work")
	local noteText
	for _, rec in ipairs(C.live("note")) do
		if string.find(rec.text, "How a target is grabbed", 1, true) then
			noteText = rec.text
		end
	end
	T.ok(noteText ~= nil)
	local w2 = newWorld({ X = X })
	UiMod.options(w2.parent, 1, "fdless", w2.R)
	for _, rec in ipairs(w2.C.live("note")) do
		if string.find(rec.text, "How a target is grabbed", 1, true) then
			noteText = rec.text
		end
	end
	T.ok(string.find(noteText, "Your executor has no sethiddenproperty, so it falls back by itself.", 1, true) ~= nil, "the default is locked here so the note says so: " .. tostring(noteText))
end

T.section("reanim_ui: a full executor leaves nothing locked and no extra note")
do
	local w = newWorld()
	UiMod.options(w.parent, 1, "fdless", w.R)
	local target = w.C.find("choice", "Fling targeting")
	T.eq(target.locked(3), nil)
	T.eq(target.locked(2), nil)
	for _, rec in ipairs(w.C.live("note")) do
		T.ok(not string.find(rec.text, "falls back", 1, true), "no fallback line")
	end
	target.set(3)
	T.eq(w.S.reanimOpts.fdless.flingtargetting, 3)
end

T.section("reanim_ui: a running provider says changes wait for the next start")
do
	local w = newWorld()
	UiMod.options(w.parent, 1, "fdless", w.R)
	running(w, "fdless")
	w.C.find("toggle", "Fling").set(false)
	T.eq(w.toasts[#w.toasts], "FDless|Applies the next time you reanimate")
	T.eq(w.S.reanimOpts.fdless.fling, false, "it is still saved")
	local before = #w.toasts
	running(w, "atsuko")
	w.C.find("toggle", "Fling").set(true)
	T.eq(#w.toasts, before, "another provider running says nothing about FDless")
	w.reg.cur = "idle"
	w.reg.activeId = nil
	w.C.find("toggle", "Fling").set(false)
	T.eq(#w.toasts, before, "idle says nothing")
end

T.section("reanim_ui: Gelatek has sliders, text boxes and choices")
do
	local w = newWorld()
	UiMod.options(w.parent, 1, "gelatek", w.R)
	local C = w.C
	T.eq(#C.live("slider"), 1)
	T.eq(#C.live("input"), 1)
	T.eq(#C.live("choice"), 2)
	T.eq(#C.live("toggle"), 2)
	local vel = C.find("slider", "Velocity")
	T.eq(vel.min, 0)
	T.eq(vel.max, 200)
	T.eq(vel.step, 1)
	T.eq(vel.live, false)
	T.eq(vel.get(), 35)
	T.eq(vel.fmt(35), "35")
	vel.set(60, false)
	T.eq(saved(w, "gelatek", "Velocity"), nil, "dragging does not save yet")
	T.eq(w.reg:optionsOf("gelatek").Velocity, 35)
	vel.set(60, true)
	T.eq(w.reg:optionsOf("gelatek").Velocity, 60)
	vel.set(70)
	T.eq(w.reg:optionsOf("gelatek").Velocity, 70, "releasing the knob saves")
	local name = C.find("input", "Clone name")
	T.eq(name.get(), "TalentlessDumbass")
	T.eq(name.placeholder, "TalentlessDumbass")
	name.set("Cloney")
	T.eq(w.reg:optionsOf("gelatek").CloneName, "Cloney")
	T.eq(name.get(), "Cloney")
	name.set("")
	T.eq(w.reg:optionsOf("gelatek").CloneName, "TalentlessDumbass", "an empty name goes back to the default")
	local mode = C.find("choice", "Mode")
	T.same(mode.options, { { "Simple", "Simple" }, { "Fling", "Fling" }, { "Bullet", "Bullet" } })
	mode.set("Bullet")
	T.eq(w.reg:optionsOf("gelatek").Reanimation, "Bullet")
	local noteTexts = {}
	for _, rec in ipairs(C.live("note")) do
		noteTexts[rec.text] = true
	end
	T.ok(noteTexts["How hard your limbs push other players in Fling and Bullet"], "the slider has its description")
	T.ok(noteTexts["What the clone is called in the game"], "the text box has its description")
end

T.section("reanim_ui: Atsuko's fade slider counts in hundredths")
do
	local w = newWorld()
	UiMod.options(w.parent, 1, "atsuko", w.R)
	local fade = w.C.find("slider", "Placeholder fade")
	T.eq(fade.min, 0)
	T.eq(fade.max, 1)
	T.eq(fade.step, 0.01)
	T.eq(fade.get(), 0.5)
	T.eq(fade.fmt(0.5), "0.50")
	fade.set(0.25, true)
	T.near(w.reg:optionsOf("atsuko").ghostTransparency, 0.25, 1e-9)
	fade.set(5, true)
	T.eq(w.reg:optionsOf("atsuko").ghostTransparency, 1, "never past its limit")
end

T.section("reanim_ui: Uhhhhhh offers five root parts")
do
	local w = newWorld()
	UiMod.options(w.parent, 1, "uhhhhhh", w.R)
	local root = w.C.find("choice", "Root part")
	T.eq(#root.options, 5)
	T.eq(root.options[1][2], "Far void")
	T.eq(root.options[5][2], "Torso")
	T.eq(root.get(), 0)
	root.set(4)
	T.eq(w.reg:optionsOf("uhhhhhh").Mode, 4)
	T.eq(#w.C.live("toggle"), 5)
end

T.section("reanim_ui: numbers with no limits fall back to a text box")
do
	local w = newWorld()
	local p = w.reg:get("atsuko")
	local original = p.settings
	p.settings = { { key = "mass", type = "number", label = "Mass", desc = "How heavy", default = 3, group = "Body", applies = "next" } }
	UiMod.options(w.parent, 1, "atsuko", w.R)
	local box = w.C.find("input", "Mass")
	T.ok(box ~= nil, "a number without min and max is typed in")
	T.eq(box.get(), "3")
	box.set("7.5")
	T.eq(w.reg:optionsOf("atsuko").mass, 7.5)
	box.set("seven")
	T.eq(w.reg:optionsOf("atsuko").mass, 7.5, "text that isn't a number is ignored")
	p.settings = original
end

T.section("reanim_ui: options for something unknown or without settings")
do
	local w = newWorld()
	local out = UiMod.options(w.parent, 5, "nothing", w.R)
	T.eq(#out.rows, 0)
	T.eq(out.last, 5)
	T.eq(#childrenOf(w.parent), 0)
	local p = w.reg:get("atsuko")
	local original = p.settings
	p.settings = nil
	out = UiMod.options(w.parent, 5, "atsuko", w.R)
	T.eq(#out.rows, 0)
	T.eq(#childrenOf(w.parent), 1)
	T.eq(childrenOf(w.parent)[1].Text, "Script Reanimate has no options")
	T.eq(childrenOf(w.parent)[1].LayoutOrder, 5)
	p.settings = original
	local none = newWorld({ noReg = true })
	local empty = UiMod.options(none.parent, 1, "fdless", none.R)
	T.eq(#empty.rows, 0, "no registry yet means no rows and no error")
end

T.section("reanim_ui: settings that apply at once do not claim to wait")
do
	local w = newWorld()
	local p = w.reg:get("atsuko")
	local original = p.settings
	p.settings = { { key = "live", type = "toggle", label = "Live", default = true, group = "Body", applies = "now" } }
	UiMod.options(w.parent, 1, "atsuko", w.R)
	T.eq(childrenOf(w.parent)[1].Text, "Script Reanimate options")
	running(w, "atsuko")
	w.C.find("toggle", "Live").set(false)
	T.eq(#w.toasts, 0, "an option that applies now does not say it waits")
	p.settings = original
end

T.section("reanim_ui: the hat chooser shows exactly Script Reanimate and FDless")
do
	local w = newWorld()
	local block = UiMod.chooser(w.parent, 10, "hat", w.R)
	local p = parts(w, "hat")
	T.ok(p.frame ~= nil and p.body ~= nil and p.row ~= nil and p.holder ~= nil and p.inner ~= nil)
	T.eq(p.frame.LayoutOrder, 10)
	local cards = childrenOf(p.row)
	T.eq(#cards, 2)
	T.eq(cards[1].Name, "Card_atsuko")
	T.eq(cards[2].Name, "Card_fdless")
	T.eq(textOf(cards[1], "Name"), "Script Reanimate")
	T.eq(textOf(cards[2], "Name"), "FDless")
	T.eq(cards[1]:FindFirstChild("Credit"), nil, "no credit line on the card")
	T.eq(cards[2]:FindFirstChild("Blurb"), nil, "and no description")
	T.eq(textOf(cards[1], "State"), "Ready")
	T.eq(textOf(cards[2], "State"), "Ready")
	T.ok(not p.row:FindFirstChild("Card_unified"), "the removed unified reanimation has no card")
	T.ok(not p.row:FindFirstChild("Card_gelatek") and not p.row:FindFirstChild("Card_uhhhhhh"), "no limb reanimate under Hat")
	T.eq(w.reg:selected("hat").id, "atsuko", "the stored pick is used")
	T.eq(strokeOf(cards[1]).Transparency, 0.15, "the picked one is outlined")
	T.eq(strokeOf(cards[2]).Transparency, 1)
	T.eq(cards[1]:FindFirstChild("Mark").BackgroundTransparency, 0.35)
	T.eq(cards[2]:FindFirstChild("Mark").BackgroundTransparency, 0.9)
	T.eq(cards[1]:FindFirstChild("Mark"):FindFirstChildOfClass("ImageLabel").ImageTransparency, 0, "its tick is visible")
	T.eq(cards[2]:FindFirstChild("Mark"):FindFirstChildOfClass("ImageLabel").ImageTransparency, 1)
	T.eq(#w.C.live("action"), 1, "and one button to reanimate without a script")
	T.eq(w.C.live("action")[1].title, "Reanimate with Script Reanimate")
	local headings = {}
	for _, ch in ipairs(childrenOf(p.frame)) do
		headings[#headings + 1] = ch.Text
	end
	T.eq(headings[1], "Hat Reanimate")
	T.eq(headings[2], "Every script in the Hat tab runs on the one you pick here.")
	block.destroy()
end

T.section("reanim_ui: the limb chooser shows exactly Gelatek and Uhhhhhh")
do
	local w = newWorld()
	UiMod.chooser(w.parent, 11, "limb", w.R)
	local p = parts(w, "limb")
	local cards = childrenOf(p.row)
	T.eq(#cards, 2)
	T.eq(cards[1].Name, "Card_gelatek")
	T.eq(cards[2].Name, "Card_uhhhhhh")
	T.eq(strokeOf(cards[1]).Transparency, 0.15, "Gelatek is the default")
	T.eq(w.C.live("action")[1].title, "Reanimate with Gelatek")
	T.eq(textOf(p.frame, "Runs the scripts in the Limb tab") == nil, true)
	T.eq(childrenOf(p.frame)[1].Text, "Limb Reanimate")
	T.eq(#w.C.live("slider"), 1, "Gelatek's velocity slider")
end

T.section("reanim_ui: tapping a card selects it and swaps the options")
do
	local w = newWorld()
	UiMod.chooser(w.parent, 10, "hat", w.R)
	local p = parts(w, "hat")
	local atsuko, fd = card(w, "hat", "atsuko"), card(w, "hat", "fdless")
	local old = w.C.live("toggle")
	T.eq(#old, 4, "Script Reanimate's four switches show first")
	fd.Activated:Fire()
	T.eq(w.S.hatReanim, "fdless", "the choice is saved in the settings")
	T.eq(w.saves, 1)
	T.eq(strokeOf(fd).Transparency, 0.15)
	T.eq(strokeOf(atsuko).Transparency, 1)
	T.eq(fd:FindFirstChild("Mark").BackgroundTransparency, 0.35)
	T.eq(atsuko:FindFirstChild("Mark").BackgroundTransparency, 0.9)
	T.eq(fd:FindFirstChild("Mark"):FindFirstChildOfClass("ImageLabel").ImageTransparency, 0)
	T.eq(atsuko:FindFirstChild("Mark"):FindFirstChildOfClass("ImageLabel").ImageTransparency, 1)
	T.eq(#w.C.live("toggle"), 10, "FDless's ten switches are now showing")
	T.eq(#w.C.live("choice"), 5, "and its five choices")
	T.eq(#w.C.live("slider"), 0, "Atsuko's slider is gone")
	for _, rec in ipairs(old) do
		T.eq(rec.row.Parent, nil, "the old rows were removed")
	end
	T.eq(#w.toasts, 0, "nothing is running so nothing to announce")
	atsuko.Activated:Fire()
	T.eq(w.S.hatReanim, "atsuko")
	T.eq(#w.C.live("toggle"), 4)
	T.eq(w.C.live("action")[1].label.Text, "Reanimate with Script Reanimate")
	fd.Activated:Fire()
	T.eq(w.C.live("action")[1].label.Text, "Reanimate with FDless", "the button names the selected one")
	local again = w.saves
	fd.Activated:Fire()
	T.eq(w.saves, again, "tapping the selected card changes nothing")
	T.eq(#w.C.live("toggle"), 10)
	T.eq(#w.C.live("action"), 1, "still only one button")
end

T.section("reanim_ui: before the first pick no hat card is selected")
do
	local w = newWorld({ picked = false })
	w.S.hatReanim = ""
	UiMod.chooser(w.parent, 10, "hat", w.R)
	local atsuko, fd = card(w, "hat", "atsuko"), card(w, "hat", "fdless")
	T.eq(w.reg:selected("hat"), nil)
	T.eq(strokeOf(atsuko).Transparency, 1, "neither card is outlined")
	T.eq(strokeOf(fd).Transparency, 1)
	T.eq(#w.C.live("toggle"), 0, "no options show without a pick")
	T.eq(w.C.live("action")[1].label.Text, "Pick one above to reanimate", "the button asks for the pick")
	fd.Activated:Fire()
	T.eq(w.S.hatReanim, "fdless", "tapping a card is the pick")
	T.eq(strokeOf(fd).Transparency, 0.15)
	T.eq(#w.C.live("toggle"), 10, "and its options open")
	T.eq(w.C.live("action")[1].label.Text, "Reanimate with FDless")
end

T.section("reanim_ui: selecting while another one runs says it waits")
do
	local w = newWorld()
	UiMod.chooser(w.parent, 10, "hat", w.R)
	running(w, "atsuko")
	card(w, "hat", "fdless").Activated:Fire()
	T.eq(w.toasts[#w.toasts], "FDless|Applies the next time you reanimate")
	T.eq(w.S.hatReanim, "fdless")
	T.eq(textOf(card(w, "hat", "atsuko"), "State"), "Running")
	T.eq(textOf(card(w, "hat", "fdless"), "State"), "Ready")
	T.eq(w.C.live("action")[1].label.Text, "Deanimate Script Reanimate")
	local n = #w.toasts
	card(w, "hat", "fdless").Activated:Fire()
	T.eq(#w.toasts, n, "no second toast for the same choice")
end

T.section("reanim_ui: state lines follow the registry")
do
	local w = newWorld()
	UiMod.chooser(w.parent, 10, "hat", w.R)
	local atsuko = card(w, "hat", "atsuko")
	local state = atsuko:FindFirstChild("State")
	w.reg.cur = "starting"
	w.reg.activeId = "atsuko"
	w.env.Bus.fire("reanim")
	T.eq(state.Text, "Starting...")
	T.eq(state.TextColor3, w.ctx.T.yellow)
	w.reg.cur = "running"
	w.env.Bus.fire("reanim")
	T.eq(state.Text, "Running")
	T.eq(state.TextColor3, w.ctx.T.green)
	w.reg.cur = "stopping"
	w.env.Bus.fire("reanim")
	T.eq(state.Text, "Stopping...")
	w.reg.cur = "idle"
	w.reg.activeId = nil
	w.env.Bus.fire("reanim")
	T.eq(state.Text, "Ready")
	T.eq(state.TextColor3, w.ctx.T.dim)
end

T.section("reanim_ui: a reanimate that can't run says why in red")
do
	local X = fullX()
	X.loadstring = nil
	local w = newWorld({ X = X })
	UiMod.chooser(w.parent, 10, "hat", w.R)
	UiMod.chooser(w.parent, 11, "limb", w.R)
	for _, id in ipairs({ "atsuko", "fdless" }) do
		local c = card(w, "hat", id)
		T.eq(textOf(c, "State"), "Your executor has no loadstring")
		T.eq(c:FindFirstChild("State").TextColor3, w.ctx.T.red)
	end
	T.eq(textOf(card(w, "limb", "uhhhhhh"), "State"), "Your executor has no loadstring, which Uhhhhhh needs")
	local X2 = fullX()
	X2.listfiles = nil
	local w2 = newWorld({ X = X2 })
	UiMod.chooser(w2.parent, 11, "limb", w2.R)
	T.eq(textOf(card(w2, "limb", "uhhhhhh"), "State"), "Your executor has no listfiles, which Uhhhhhh needs")
	T.eq(textOf(card(w2, "limb", "gelatek"), "State"), "Ready")
	card(w2, "limb", "uhhhhhh").Activated:Fire()
	T.eq(w2.S.reanimLimb, "uhhhhhh", "an unavailable one can still be selected, nothing is hidden")
end

T.section("reanim_ui: a reanimate that did not load still has a card")
do
	local w = newWorld({ fail = { gelatek = "download failed" } })
	UiMod.chooser(w.parent, 11, "limb", w.R)
	local p = parts(w, "limb")
	local cards = childrenOf(p.row)
	T.eq(#cards, 2, "the failed one is not hidden")
	T.eq(textOf(card(w, "limb", "gelatek"), "State"), "Couldn't load: download failed")
	T.eq(card(w, "limb", "gelatek"):FindFirstChild("State").TextColor3, w.ctx.T.red)
	T.eq(textOf(card(w, "limb", "gelatek"), "Name"), "Gelatek")
	card(w, "limb", "gelatek").Activated:Fire()
	T.eq(w.toasts[#w.toasts], "Gelatek|Couldn't load Gelatek: download failed")
	T.eq(w.S.reanimLimb, nil, "it was not selected")
	T.eq(strokeOf(card(w, "limb", "uhhhhhh")).Transparency, 0.15, "the one that loaded is the selected one")
	T.eq(#w.C.live("choice"), 3, "Uhhhhhh's options are showing")
	T.eq(w.C.live("action")[1].label.Text, "Reanimate with Uhhhhhh")
end

T.section("reanim_ui: the button under the cards starts and stops without a script")
do
	local w = newWorld()
	UiMod.chooser(w.parent, 10, "hat", w.R)
	UiMod.chooser(w.parent, 11, "limb", w.R)
	local hatBtn, limbBtn
	for _, rec in ipairs(w.C.live("action")) do
		if string.find(rec.title, "Script Reanimate", 1, true) then
			hatBtn = rec
		elseif string.find(rec.title, "Gelatek", 1, true) then
			limbBtn = rec
		end
	end
	T.ok(hatBtn ~= nil and limbBtn ~= nil, "found hatBtn=" .. tostring(hatBtn and hatBtn.title) .. " limbBtn=" .. tostring(limbBtn and limbBtn.title))
	T.eq(hatBtn.icon, "person-standing")
	hatBtn.fn()
	limbBtn.fn()
	T.eq(table.concat(w.calls, ","), "solo:hat,solo:limb")
	w.calls = {}
	running(w, "gelatek")
	w.env.Bus.fire("reanim")
	T.eq(limbBtn.label.Text, "Deanimate Gelatek")
	T.eq(hatBtn.label.Text, "Reanimate with Script Reanimate", "the hat button is not about the limb one")
	limbBtn.fn()
	T.eq(table.concat(w.calls, ","), "stop")
	w.calls = {}
	hatBtn.fn()
	T.eq(table.concat(w.calls, ","), "solo:hat", "the controller decides what to say when the other kind is running")
	w.calls = {}
	w.R.busy = "starting"
	w.env.Bus.fire("reanim")
	T.eq(limbBtn.label.Text, "Starting...")
	T.eq(hatBtn.label.Text, "Starting...")
	w.R.busy = "stopping"
	w.env.Bus.fire("reanim")
	T.eq(limbBtn.label.Text, "Stopping...")
	w.R.busy = nil
	w.R.asking = { text = "stopping respawns you. Continue?" }
	w.env.Bus.fire("reanim")
	T.eq(limbBtn.label.Text, "Stopping respawns you. Continue? Tap again.")
	limbBtn.fn()
	T.eq(table.concat(w.calls, ","), "stop", "the second tap answers the question")
	w.R.asking = nil
	w.reg.cur = "idle"
	w.reg.activeId = nil
	w.env.Bus.fire("reanim")
	T.eq(limbBtn.label.Text, "Reanimate with Gelatek")
end

T.section("reanim_ui: while the registry loads or failed")
do
	local w = newWorld({ noReg = true })
	UiMod.chooser(w.parent, 10, "hat", w.R)
	local p = parts(w, "hat")
	T.eq(p.row, nil, "no cards yet")
	T.eq(p.body:FindFirstChild("Waiting").Text, "Reanimation is getting ready...")
	T.eq(p.body:FindFirstChild("Waiting").TextColor3, w.ctx.T.sub)
	T.eq(#w.C.live("action"), 0)
	w.R.reg = w.reg
	w.env.Bus.fire("reanim")
	p = parts(w, "hat")
	T.ok(p.row ~= nil, "the cards appear when the registry arrives")
	T.eq(#childrenOf(p.row), 2)
	T.eq(p.body:FindFirstChild("Waiting"), nil)
	T.eq(#w.C.live("action"), 1)

	local bad = newWorld({ noReg = true, loadError = "couldn't find Reanimation/providers/registry.lua", retry = true })
	UiMod.chooser(bad.parent, 10, "hat", bad.R)
	local bp = parts(bad, "hat")
	T.eq(bp.body:FindFirstChild("Waiting").Text, "Couldn't load: couldn't find Reanimation/providers/registry.lua")
	T.eq(bp.body:FindFirstChild("Waiting").TextColor3, bad.ctx.T.red)
	local retry = bad.C.live("action")[1]
	T.eq(retry.title, "Try again")
	retry.fn()
	T.eq(table.concat(bad.calls, ","), "retry")

	local noRetry = newWorld({ noReg = true, loadError = "oops" })
	UiMod.chooser(noRetry.parent, 10, "hat", noRetry.R)
	T.eq(#noRetry.C.live("action"), 0, "no button when the hub can't try again")
end

T.section("reanim_ui: a new registry rebuilds the cards")
do
	local w = newWorld()
	UiMod.chooser(w.parent, 10, "hat", w.R)
	local first = card(w, "hat", "fdless")
	local second = Registry.new({ S = w.env.S, X = fullX(), now = time, wait = task.wait, spawn = task.spawn, delay = task.delay })
	for _, id in ipairs(Registry.IDS) do
		assert(second:register(loadmodule("Reanimation/providers/" .. id .. ".lua")))
	end
	w.R.reg = second
	w.env.Bus.fire("reanim")
	local now = card(w, "hat", "fdless")
	T.ok(now ~= nil and now ~= first, "fresh cards")
	T.eq(first.Parent, nil, "the old ones are gone")
	T.eq(#childrenOf(parts(w, "hat").row), 2)
	T.eq(#w.C.live("action"), 1)
end

T.section("reanim_ui: cards sit side by side, or stack when narrow")
do
	local w = newWorld()
	UiMod.chooser(w.parent, 10, "hat", w.R)
	local p = parts(w, "hat")
	local a, b = card(w, "hat", "atsuko"), card(w, "hat", "fdless")
	p.row:TestResize(380, 64)
	T.eq(p.row.Size.Y.Offset, 64)
	T.eq(a.Position.X.Scale, 0)
	T.eq(a.Position.Y.Offset, 0)
	T.eq(a.Size.X.Scale, 1/2)
	T.eq(a.Size.X.Offset, -4)
	T.eq(a.Size.Y.Offset, 64)
	T.eq(b.Position.X.Scale, 1/2)
	T.eq(b.Position.X.Offset, 4)
	T.eq(b.Size.X.Scale, 1/2)
	p.row:TestResize(280, 136)
	T.eq(p.row.Size.Y.Offset, 136, "two cards and the gap")
	T.eq(a.Position.Y.Offset, 0)
	T.eq(b.Position.Y.Offset, 72)
	T.eq(a.Size.X.Scale, 1)
	T.eq(a.Size.X.Offset, 0)
	T.eq(b.Size.X.Scale, 1)
	T.eq(b.Position.X.Scale, 0)
	T.eq(b.Position.X.Offset, 0)
	p.row:TestResize(300, 64)
	T.eq(p.row.Size.Y.Offset, 64, "300 is wide enough for two")
	T.eq(b.Position.X.Scale, 1/2)
	w.ctx.L.scale = 2
	p.row:TestResize(560, 64)
	T.eq(p.row.Size.Y.Offset, 136, "the hub's own scale is taken out of the width")
end

T.section("reanim_ui: the options area follows the height of what is inside")
do
	local w = newWorld()
	UiMod.chooser(w.parent, 10, "hat", w.R)
	local p = parts(w, "hat")
	T.eq(p.holder.ClipsDescendants, true)
	T.eq(p.holder.Size.Y.Offset, 0)
	p.inner:TestResize(380, 340)
	T.eq(p.holder.Size.Y.Offset, 340, "no animation means it jumps there")
	p.inner:TestResize(380, 340.4)
	T.eq(p.holder.Size.Y.Offset, 341, "rounded up so nothing is cut")
	w.ctx.L.scale = 2
	p.inner:TestResize(380, 340)
	T.eq(p.holder.Size.Y.Offset, 170)
	local lively = newWorld({ animations = true })
	UiMod.chooser(lively.parent, 10, "hat", lively.R)
	local lp = parts(lively, "hat")
	lp.inner:TestResize(380, 400)
	T.ok(lp.holder.Size.Y.Offset ~= 400, "it is sliding, not there yet")
	lively.env.advance(0.4)
	T.eq(lp.holder.Size.Y.Offset, 400, "and it arrives")
	local count = lively.env.tweens
	lp.inner:TestResize(380, 400)
	T.eq(lively.env.tweens, count, "the same height starts no new tween")
	card(lively, "hat", "fdless").Activated:Fire()
	T.ok(lively.env.tweens > count, "picking a card animates the outline")
	lively.env.advance(0.4)
	T.eq(strokeOf(card(lively, "hat", "fdless")).Transparency, 0.15)
	T.eq(strokeOf(card(lively, "hat", "atsuko")).Transparency, 1)
end

T.section("reanim_ui: refreshing puts the saved values back into the controls")
do
	local w = newWorld()
	UiMod.chooser(w.parent, 10, "hat", w.R)
	card(w, "hat", "fdless").Activated:Fire()
	local fling = w.C.find("toggle", "Fling")
	local before = fling.rendered
	w.env.Bus.fire("reanim")
	T.ok(fling.rendered > before, "the switch is drawn again")
	local all = w.C.live()
	for _, rec in ipairs(all) do
		if rec.kind ~= "note" and rec.kind ~= "action" then
			T.ok(rec.rendered >= 1, "rendered " .. tostring(rec.title))
		end
	end
	local typing = newWorld()
	local limbChooser = UiMod.chooser(typing.parent, 11, "limb", typing.R)
	local box = typing.C.find("input", "Clone name")
	box.box.IsFocused = function()
		return true
	end
	local seen = box.rendered
	typing.env.Bus.fire("reanim")
	T.eq(box.rendered, seen, "a box being typed in is left alone")
	box.box.IsFocused = function()
		return false
	end
	typing.env.Bus.fire("reanim")
	T.ok(box.rendered > seen)
	limbChooser.destroy()
	local group = UiMod.section(Instance.new("Frame"), 40, typing.R)
	local sliders = typing.C.live("slider")
	local slider = sliders[#sliders]
	T.eq(slider.title, "Velocity")
	local rendered = slider.rendered
	group.render()
	T.ok(slider.rendered > rendered, "render redraws both choosers")
	group.destroy()
end

T.section("reanim_ui: the section puts the heading, the note and both choosers in order")
do
	local w = newWorld()
	local group = UiMod.section(w.parent, 20, w.R)
	local kids = childrenOf(w.parent)
	T.eq(#kids, 4)
	T.eq(kids[1].Text, "Reanimation")
	T.eq(kids[1].LayoutOrder, 20)
	T.eq(kids[2].LayoutOrder, 21)
	T.eq(kids[2].Text, "Choose which reanimate runs your scripts. Tap one to select it, then change its options below it.")
	T.eq(kids[3].Name, "Chooser_hat")
	T.eq(kids[3].LayoutOrder, 22)
	T.eq(kids[4].Name, "Chooser_limb")
	T.eq(kids[4].LayoutOrder, 23)
	T.ok(group.hat ~= nil and group.limb ~= nil)
	T.eq(type(group.render), "function")
	T.eq(type(group.destroy), "function")
	T.eq(w.env.Bus.count("reanim"), 2)
	group.destroy()
	T.eq(w.env.Bus.count("reanim"), 0)
	T.eq(w.parent:FindFirstChild("Chooser_hat"), nil)
	T.eq(w.parent:FindFirstChild("Chooser_limb"), nil)
end

T.section("reanim_ui: taking it down leaves nothing behind")
do
	local w = newWorld()
	local one = UiMod.chooser(w.parent, 10, "hat", w.R)
	local two = UiMod.chooser(w.parent, 11, "limb", w.R)
	T.eq(w.env.Bus.count("reanim"), 2)
	one.destroy()
	T.eq(w.env.Bus.count("reanim"), 1)
	T.eq(w.parent:FindFirstChild("Chooser_hat"), nil)
	w.env.Bus.fire("reanim")
	UiMod.destroy()
	T.eq(w.env.Bus.count("reanim"), 0, "module destroy removes the rest")
	T.eq(w.parent:FindFirstChild("Chooser_limb"), nil)
	two.destroy()
	UiMod.destroy()
end

T.section("reanim_ui: a failure while redrawing is logged and never thrown")
do
	local w = newWorld()
	UiMod.chooser(w.parent, 10, "hat", w.R)
	w.reg.slots = function()
		error("boom", 0)
	end
	w.env.Bus.fire("reanim")
	local logged = 0
	for _, item in ipairs(w.env.Log.items) do
		if item.kind == "error" and item.msg == "reanimation chooser: boom" then
			logged = logged + 1
		end
	end
	T.eq(logged, 1)
end

T.section("reanim_ui: nothing is shown after the frame is gone")
do
	local w = newWorld()
	local block = UiMod.chooser(w.parent, 10, "hat", w.R)
	block.frame.Parent = nil
	local before = #w.C.made
	w.env.Bus.fire("reanim")
	T.eq(#w.C.made, before, "a detached chooser does not rebuild")
end
