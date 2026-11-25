local ChatHook = loadmodule("Hub/modules/chathook.lua")
local Dispatch = loadmodule("Hub/modules/dispatch.lua")
local Prefix = loadmodule("Hub/modules/prefix.lua")

local function makeDispatch(clock)
	local d = Dispatch.new({ clock = clock, parse = Prefix.parse, newGuard = Prefix.newGuard })
	local hits = {}
	d:register("hub", "hub", {
		{ id = "fly", name = "fly", kind = "toggle", run = function() hits[#hits + 1] = "fly" end },
		{ id = "speed", name = "speed", kind = "action", run = function(a) hits[#hits + 1] = "speed:" .. tostring(a) end },
	})
	d:register("sd", "script", { { id = "tp", name = "tp", kind = "action", run = function() hits[#hits + 1] = "tp" end } }, { legacyPrefixes = { "-" } })
	return d, hits
end

T.section("chathook: which messages are swallowed")
local d, hits = makeDispatch()
T.eq(ChatHook.shouldSwallow(d, ";fly"), true)
T.eq(ChatHook.shouldSwallow(d, ";speed 50"), true)
T.eq(ChatHook.shouldSwallow(d, "-tp"), true, "a legacy prefix command is swallowed too")
T.eq(ChatHook.shouldSwallow(d, "-reload"), true)
T.eq(ChatHook.shouldSwallow(d, ";)"), false)
T.eq(ChatHook.shouldSwallow(d, ";D"), false)
T.eq(ChatHook.shouldSwallow(d, "hello everyone"), false)
T.eq(ChatHook.shouldSwallow(d, "/e dance"), false)
T.eq(ChatHook.shouldSwallow(d, "/w bob hi"), false)
T.eq(ChatHook.shouldSwallow(d, ""), false)
T.eq(ChatHook.shouldSwallow(d, ";nonsense"), false)
T.eq(ChatHook.shouldSwallow(d, nil), false)
T.eq(ChatHook.shouldSwallow(d, 5), false)
T.eq(ChatHook.shouldSwallow(nil, ";fly"), false)
T.eq(ChatHook.shouldSwallow({ isCommand = function() error("x") end }, ";fly"), false)
T.eq(d:isCommand(";fly"), true)
T.eq(d:isCommand(nil), false)
T.eq(#hits, 0, "deciding never runs a command")

T.section("chathook: target matching")
T.eq(ChatHook.matchesTarget("SendAsync", { ClassName = "TextChannel", Name = "RBXGeneral" }), true)
T.eq(ChatHook.matchesTarget("SendAsync", { ClassName = "Part", Name = "x" }), false)
T.eq(ChatHook.matchesTarget("FireServer", { ClassName = "RemoteEvent", Name = "SayMessageRequest" }), true)
T.eq(ChatHook.matchesTarget("FireServer", { ClassName = "RemoteEvent", Name = "Jump" }), false)
T.eq(ChatHook.matchesTarget("Destroy", { ClassName = "TextChannel", Name = "x" }), false)
T.eq(ChatHook.matchesTarget("SendAsync", nil), false)
T.eq(ChatHook.matchesTarget("SendAsync", setmetatable({}, { __index = function() error("no access") end })), false)

local function setup(opts)
	opts = opts or {}
	local calls = { old = {}, deferred = {}, setNamecall = {} }
	local current = nil
	local hooked = nil
	local caller = opts.caller or false
	local X = {
		hookmetamethod = function(obj, name, fn)
			hooked = { obj = obj, name = name, fn = fn }
			return function(self, ...)
				calls.old[#calls.old + 1] = { self = self, args = { ... }, method = current }
				return "original-result"
			end
		end,
		getnamecallmethod = function()
			return current
		end,
		setnamecallmethod = function(m)
			calls.setNamecall[#calls.setNamecall + 1] = m
			current = m
		end,
		checkcaller = function()
			return caller
		end,
		newcclosure = function(f)
			return f
		end,
	}
	if opts.without then
		X[opts.without] = nil
	end
	local store = {}
	local d2, hits2 = makeDispatch(opts.clock)
	if opts.dispatch ~= nil then
		d2 = opts.dispatch or nil
	end
	local env = {
		X = X,
		store = store,
		root = { ClassName = "DataModel", Name = "Game" },
		dispatch = function()
			return d2
		end,
		defer = function(f)
			calls.deferred[#calls.deferred + 1] = f
		end,
	}
	local state = ChatHook.install(env)
	local api = {}
	function api.call(self, method, ...)
		current = method
		return hooked.fn(self, ...)
	end
	function api.setCaller(v)
		caller = v
	end
	function api.flush()
		local list = calls.deferred
		calls.deferred = {}
		for _, f in ipairs(list) do
			f()
		end
	end
	return state, api, calls, hits2, store, hooked, X, env
end

local channel = { ClassName = "TextChannel", Name = "RBXGeneral" }
local say = { ClassName = "RemoteEvent", Name = "SayMessageRequest" }

T.section("chathook: installed hook")
local state, api, calls, hits2, store, hooked = setup()
T.eq(state.active, true)
T.eq(hooked.name, "__namecall")
T.ok(store.__AtsukoSendHook ~= nil)
local res = api.call(channel, "SendAsync", ";fly")
T.eq(res, nil, "a command is not sent")
T.eq(#calls.old, 0)
T.eq(#calls.deferred, 1)
api.flush()
T.same(hits2, { "fly" })
res = api.call(channel, "SendAsync", "hello world")
T.eq(res, "original-result")
T.eq(#calls.old, 1)
T.same(calls.old[1].args, { "hello world" })
T.eq(calls.old[1].method, "SendAsync")
res = api.call(say, "FireServer", ";speed 80", "All")
T.eq(res, nil)
api.flush()
T.same(hits2, { "fly", "speed:80" })
res = api.call(say, "FireServer", "gg", "All")
T.eq(res, "original-result")
T.same(calls.old[#calls.old].args, { "gg", "All" })
res = api.call(channel, "SendAsync", ";)")
T.eq(res, "original-result")
res = api.call(channel, "SendAsync", "/e dance")
T.eq(res, "original-result")
res = api.call({ ClassName = "Part", Name = "p" }, "SendAsync", ";fly")
T.eq(res, "original-result", "another object with the same method name is left alone")
res = api.call({ ClassName = "RemoteEvent", Name = "Other" }, "FireServer", ";fly")
T.eq(res, "original-result")
res = api.call(channel, "Destroy")
T.eq(res, "original-result", "unrelated methods pass straight through")
T.ok(#calls.setNamecall >= 1, "the namecall method is restored before the original runs")

T.section("chathook: the hub's own messages go through")
state, api, calls, hits2 = setup({ caller = true })
res = api.call(channel, "SendAsync", ";fly")
T.eq(res, "original-result", "checkcaller true means the hub sent it")
T.eq(#calls.deferred, 0)

T.section("chathook: failures never reach the game")
local boomState, boomApi = setup({ dispatch = { isCommand = function() error("boom") end, handle = function() end } })
T.eq(boomState.active, true)
T.eq(boomApi.call(channel, "SendAsync", ";fly"), "original-result", "a dispatcher that raises lets the message through")
state, api, calls, hits2 = setup({ without = "checkcaller" })
T.eq(state.active, false)
state, api, calls, hits2 = setup({ without = "hookmetamethod" })
T.eq(state.active, false)
state, api, calls, hits2 = setup({ without = "getnamecallmethod" })
T.eq(state.active, false)
state, api, calls, hits2 = setup({ without = "newcclosure" })
T.eq(state.active, false)
local throwState, throwApi = setup({ dispatch = false })
T.eq(throwApi.call(channel, "SendAsync", ";fly"), "original-result", "a missing dispatcher lets the message through")

T.section("chathook: reload swaps the handler and never stacks another hook")
local hookCount = 0
local store2 = {}
local current2 = nil
local installed = nil
local X2 = {
	hookmetamethod = function(obj, name, fn)
		hookCount = hookCount + 1
		installed = fn
		return function()
			return "orig"
		end
	end,
	getnamecallmethod = function()
		return current2
	end,
	checkcaller = function()
		return false
	end,
	newcclosure = function(f)
		return f
	end,
}
local d3, hits3 = makeDispatch()
local function env3()
	return { X = X2, store = store2, root = {}, dispatch = function() return d3 end, defer = function(f) f() end }
end
local s1 = ChatHook.install(env3())
local s2 = ChatHook.install(env3())
T.eq(hookCount, 1, "one hook for the whole session")
T.eq(s1.active and s2.active, true)
current2 = "SendAsync"
T.eq(installed(channel, ";fly"), nil)
T.same(hits3, { "fly" })
s2.remove()
T.eq(s2.active, false)
T.eq(installed(channel, ";fly"), "orig", "after removal everything passes through")
local s3 = ChatHook.install(env3())
T.eq(hookCount, 1)
T.eq(installed(channel, ";speed 1"), nil)
s1.remove()
T.eq(installed(channel, ";speed 2"), "orig", "an old state cannot keep swallowing")

T.section("chathook: status text")
T.eq(select(1, ChatHook.status({ active = true })), "hooked")
T.eq(select(1, ChatHook.status({ active = false })), "off")
T.eq(select(1, ChatHook.status(nil)), "off")
