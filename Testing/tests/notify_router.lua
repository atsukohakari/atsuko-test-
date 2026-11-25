local Router = loadmodule("Hub/modules/notify_router.lua")

local function clockOf()
	local c = { t = 1000 }
	c.now = function()
		return c.t
	end
	return c
end

local GUARD_TEXT = "Using FDless loaded by previously executed scripts to prevent reanimate conflicts. Rejoin to update reanimate settings."

T.section("notify_router: the FDless guard rule")
local clock = clockOf()
local toasts = {}
local r = Router.new({ now = clock.now, toast = function(...)
	toasts[#toasts + 1] = { ... }
end })
T.eq(r:classify("FDLESS", GUARD_TEXT), "pass", "not armed: the notice is not touched")
r:arm(20)
T.eq(r:armed(), true)
T.eq(r:classify("FDLESS", GUARD_TEXT), "swallow")
T.eq(r:classify("FDLESS", GUARD_TEXT .. " extra"), "swallow")
T.eq(r:classify("FDLESS", "FDLESS SERVERBREAKJOINTS missing"), "pass")
T.eq(r:classify("Other", GUARD_TEXT), "pass", "title must match exactly")
T.eq(r:classify("fdless", GUARD_TEXT), "pass")
T.eq(r:classify("FDLESS", "Using FDless loaded by someone else"), "pass")
T.eq(r:classify(nil, nil), "pass")
T.eq(r:classify("FDLESS", nil), "pass")
clock.t = clock.t + 19.9
T.eq(r:classify("FDLESS", GUARD_TEXT), "swallow")
clock.t = clock.t + 0.2
T.eq(r:armed(), false, "the window closes by itself")
T.eq(r:classify("FDLESS", GUARD_TEXT), "pass")
r:arm(5)
r:disarm()
T.eq(r:armed(), false)
r:arm()
T.eq(r:armed(), true)

T.section("notify_router: general mode turns notices into toasts")
r = Router.new({ now = clock.now, toast = function(...)
	toasts[#toasts + 1] = { ... }
end })
T.eq(r:handle("SendNotification", { Title = "Hi", Text = "there", Duration = 4 }), "pass")
T.eq(#toasts, 0)
r:setGeneral(true)
T.eq(r:handle("SendNotification", { Title = "Hi", Text = "there", Duration = 4 }), "swallow")
T.eq(#toasts, 1)
T.same(toasts[1], { "Hi", "there", "info", 4 })
T.eq(r:handle("SendNotification", { Title = "Hi" }), "swallow")
T.same(toasts[2], { "Hi", "", "info", nil })
T.eq(r:handle("SendNotification", {}), "swallow")
T.eq(r:handle("SendNotification", "not a table"), "pass")
T.eq(r:handle("SendNotification", nil), "pass")
T.eq(r:handle("ChatActive", { Title = "x" }), "pass")
T.eq(r:handle("TopbarEnabled", false), "pass")
T.eq(r:handle(nil, nil), "pass")
r:setGeneral(false)
T.eq(r:handle("SendNotification", { Title = "Hi", Text = "x" }), "pass")
r:setGeneral(true)
r.toast = function()
	error("toast failed")
end
T.eq(r:handle("SendNotification", { Title = "Hi", Text = "x" }), "swallow", "a failing toast never throws into the game")

T.section("notify_router: pop-ups left in the corner stay as long as the hub's")
do
	local secs = 5.5
	local rr = Router.new({ now = clock.now, toast = function() end, duration = function()
		return secs
	end })
	local note = { Title = "Hi", Text = "there", Duration = 30 }
	T.eq(rr:handle("SendNotification", note), "pass", "it still shows where the script put it")
	T.eq(note.Duration, 5.5, "but for the hub's time")
	local plain = { Title = "Hi" }
	rr:handle("SendNotification", plain)
	T.eq(plain.Duration, 5.5, "also when the script gave no time")
	local ask = { Title = "Sure?", Text = "Load it?", Duration = 30, Button1 = "Yes", Button2 = "No" }
	rr:handle("SendNotification", ask)
	T.eq(ask.Duration, 30, "a pop-up with buttons keeps its own time so you can answer it")
	local call = { Title = "x", Duration = 12, Callback = {} }
	rr:handle("SendNotification", call)
	T.eq(call.Duration, 12, "and one with a callback")
	secs = 0 / 0
	local odd = { Title = "x", Duration = 9 }
	rr:handle("SendNotification", odd)
	T.eq(odd.Duration, 9, "a broken time changes nothing")
	local locked = setmetatable({}, { __index = function(_, k)
		if k == "Title" then
			return "x"
		end
		return nil
	end, __newindex = function()
		error("read only")
	end })
	secs = 3
	T.eq(rr:handle("SendNotification", locked), "pass", "a table that can't be changed is left alone")
	local plainR = Router.new({ now = clock.now })
	local keep = { Title = "Hi", Duration = 30 }
	plainR:handle("SendNotification", keep)
	T.eq(keep.Duration, 30, "without a time to use nothing changes")
end

T.section("notify_router: the guard rule still works with general mode on")
r = Router.new({ now = clock.now, toast = function(...)
	toasts[#toasts + 1] = { ... }
end, general = true })
local before = #toasts
r:arm(10)
T.eq(r:handle("SendNotification", { Title = "FDLESS", Text = GUARD_TEXT, Duration = 10 }), "swallow")
T.eq(#toasts, before, "the guard notice is dropped, not shown")
T.eq(r:handle("SendNotification", { Title = "FDLESS", Text = "something else" }), "swallow")
T.eq(#toasts, before + 1)

T.section("notify_router: what was seen")
r = Router.new({ now = clock.now })
for i = 1, 70 do
	clock.t = clock.t + 1
	r:handle("SendNotification", { Title = "n" .. i, Text = "x" })
end
local seen = r:seen()
T.eq(#seen, 50)
T.eq(seen[1].title, "n21")
T.eq(seen[50].title, "n70")
T.eq(type(seen[1].at), "number")
T.eq(seen[1].text, nil, "only the title and a time stamp are kept")
seen[1].title = "changed"
T.eq(r:seen()[1].title, "n21", "seen returns a copy")
r:clearSeen()
T.eq(#r:seen(), 0)
r:handle("SendNotification", { Text = "no title" })
T.eq(r:seen()[1].title, "")

local function setup(opts)
	opts = opts or {}
	local calls = { old = {}, toasts = {} }
	local current
	local hooked
	local hookCount = 0
	local X = {
		hookmetamethod = function(obj, name, fn)
			hookCount = hookCount + 1
			hooked = fn
			return function(self, ...)
				calls.old[#calls.old + 1] = { self = self, args = { ... }, method = current }
				return "orig"
			end
		end,
		getnamecallmethod = function()
			return current
		end,
		setnamecallmethod = function(m)
			current = m
		end,
		newcclosure = function(f)
			return f
		end,
	}
	if opts.without then
		X[opts.without] = nil
	end
	if opts.hookfunction then
		X.hookmetamethod = nil
		X.hookfunction = function(target, fn)
			hooked = fn
			return function()
				calls.old[#calls.old + 1] = { fn = true }
				return "orig-fn"
			end
		end
	end
	local router = Router.new({ now = opts.now, toast = function(...)
		calls.toasts[#calls.toasts + 1] = { ... }
	end, general = opts.general })
	local store = opts.store or {}
	local env = { X = X, store = store, root = {}, setCore = function() end }
	local state = Router.install(env, router)
	return state, router, calls, function(self, method, ...)
		current = method
		return hooked(self, ...)
	end, function()
		return hookCount
	end, store
end

local gui = { ClassName = "StarterGui" }

T.section("notify_router: installed hook")
clock = clockOf()
local state, router, calls, call, hookCount, store = setup({ now = clock.now, general = true })
T.eq(state.active, true)
T.eq(state.mode, "namecall")
T.eq(call(gui, "SetCore", "SendNotification", { Title = "A", Text = "b" }), nil)
T.same(calls.toasts[1], { "A", "b", "info", nil })
T.eq(#calls.old, 0)
T.eq(call(gui, "SetCore", "ChatActive", true), "orig")
T.eq(#calls.old, 1)
T.same(calls.old[1].args, { "ChatActive", true })
T.eq(call({ ClassName = "Workspace" }, "SetCore", "SendNotification", { Title = "A" }), "orig", "only StarterGui is touched")
T.eq(call(gui, "GetCore", "SendNotification"), "orig")
router:setGeneral(false)
T.eq(call(gui, "SetCore", "SendNotification", { Title = "Kept", Text = "x" }), "orig", "with general mode off the call reaches Roblox")
router:arm(10)
T.eq(call(gui, "SetCore", "SendNotification", { Title = "FDLESS", Text = GUARD_TEXT }), nil)
T.eq(router:seen()[#router:seen()].title, "FDLESS")
state.remove()
T.eq(state.active, false)
T.eq(call(gui, "SetCore", "SendNotification", { Title = "FDLESS", Text = GUARD_TEXT }), "orig", "after removal everything passes through")

T.section("notify_router: one hook per session")
local sharedStore = {}
local s1, r1, c1, call1, hc1 = setup({ now = clock.now, store = sharedStore, general = true })
T.eq(hc1(), 1)
local s2, r2, c2, call2, hc2 = setup({ now = clock.now, store = sharedStore, general = true })
T.eq(s2.active, true)
T.eq(hc2(), 0, "the second install reuses the first hook")
T.eq(call1(gui, "SetCore", "SendNotification", { Title = "Q", Text = "z" }), nil)
T.eq(#c1.toasts, 0)
T.eq(#c2.toasts, 1, "the newest router receives the notice")

T.section("notify_router: executors without hooks")
state = setup({ without = "hookmetamethod" })
T.eq(state.active, false)
T.eq(state.mode, "off")
state = setup({ without = "getnamecallmethod" })
T.eq(state.active, false)
state = setup({ without = "newcclosure" })
T.eq(state.active, false)
local fstate, frouter, fcalls, fcall = setup({ hookfunction = true, now = clock.now, general = true })
T.eq(fstate.active, true)
T.eq(fstate.mode, "function")
T.eq(fcall(gui, "SetCore", "SendNotification", { Title = "F", Text = "g" }), nil)
T.same(fcalls.toasts[1], { "F", "g", "info", nil })
T.eq(fcall(gui, "SetCore", "ChatActive", true), "orig-fn")
