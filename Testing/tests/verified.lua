local V = loadmodule("Hub/modules/verified.lua")

local GLYPH = "\238\128\128"
local MARK = V.MARK

T.section("verified: the badge")
T.eq(V.DEFAULT, "0066ff", "the blue of the badge picture")
T.same({ V.rgb() }, { 0, 102, 255 })
T.eq(V.GLYPH, GLYPH, "Roblox's own verified badge character")
T.eq(V.SEAL_TURN, 15, "the square leans like the picture")
T.eq(V.newer(100, 50), true)
T.eq(V.newer(100, 100), true)
T.eq(V.newer(99, 100), false, "an older message never wins")
T.eq(V.newer(5, nil), true)
T.eq(V.newer(nil, 0), false)
T.eq(V.newer("x", 0), false)

T.section("verified: the space for the badge in Roblox chat")
T.eq(V.MARK_OPEN, '<font color="#010203">')
T.ok(string.find(MARK, "     ", 1, true) ~= nil, "the mark is a run of spaces the badge is drawn over")
T.eq(V.mark("Atsuko:"), "Atsuko" .. MARK .. ":", "right after the name, before the colon")
T.eq(V.mark("Atsuko: "), "Atsuko" .. MARK .. ": ", "the space after the colon stays")
T.eq(V.mark("Atsuko"), "Atsuko" .. MARK, "or at the end when there is no colon")
T.eq(V.mark("Atsuko :"), "Atsuko" .. MARK .. ":", "a space before the colon is taken out so the badge hugs the name")
T.eq(V.mark('<font color="#aabbcc">Atsuko:</font>'), '<font color="#aabbcc">Atsuko' .. MARK .. ":</font>", "inside the name's own color tag")
T.eq(V.mark("<b>Atsuko:</b>"), "<b>Atsuko" .. MARK .. ":</b>", "and inside bold")
T.eq(V.mark("[VIP] Atsuko:"), "[VIP] Atsuko" .. MARK .. ":", "a game's own tag stays")
local once = V.mark("Atsuko:")
T.eq(V.mark(once), once, "it is never added twice")
T.eq(V.mark("a:b:"), "a:b" .. MARK .. ":", "only the last colon counts")
T.eq(V.mark(""), "")
T.eq(V.mark(nil), nil)
local SUF = '<font color="#0066ff" family="rbxasset://fonts/families/BuilderSans.json">' .. GLYPH .. "</font>"
T.eq(V.suffix(), SUF, "the glyph in Roblox blue, in Roblox's own font whatever font the name is in")
T.eq(V.suffix("ff0000"), '<font color="#ff0000" family="rbxasset://fonts/families/BuilderSans.json">' .. GLYPH .. "</font>")
T.eq(V.glyph("Atsuko:"), "Atsuko" .. SUF .. ":", "the glyph goes right after the name, with no gap")
T.eq(V.glyph('<font color="#aabbcc">Atsuko :</font>'), '<font color="#aabbcc">Atsuko' .. SUF .. ":</font>")
T.eq(V.glyph("Atsuko" .. GLYPH .. ":"), "Atsuko" .. GLYPH .. ":", "never twice")

T.section("verified: which chat window lines change")
local on = { [77] = true, [78] = true }
local made = 0
local drawn = true
local white = { R = 0.95, G = 0.95, B = 0.95 }
local env = {
	has = function(id)
		return on[id] == true
	end,
	drawn = function()
		return drawn
	end,
	nameColor = function(id)
		return id == 77 and white or nil
	end,
	derive = function()
		made = made + 1
		return { PrefixText = "" }
	end,
}
local function msg(id, prefix)
	return { TextSource = { UserId = id }, PrefixText = prefix }
end
local out = V.window(env, msg(77, "Atsuko:"), nil)
T.eq(out.PrefixText, "Atsuko" .. MARK .. ":", "someone with the badge on gets the space for it")
T.eq(out.PrefixTextProperties.TextColor3, white, "and keeps the name color Roblox gives them, so it doesn't change")
T.eq(made, 2)
out = V.window(env, msg(78, "Bob:"), nil)
T.eq(out.PrefixText, "Bob" .. MARK .. ":", "anyone can have it")
T.eq(out.PrefixTextProperties, nil, "no color to keep, none set")
drawn = false
T.eq(V.window(env, msg(77, "Atsuko:"), nil).PrefixText, "Atsuko" .. SUF .. ":", "when the badge can't be drawn, the glyph goes right after the name")
drawn = true
T.eq(V.window(env, msg(6, "Tory:"), nil), nil, "someone without it is left to Roblox")
T.eq(V.window(env, { PrefixText = "System:" }, nil), nil, "not a line without a sender")
T.eq(V.window(env, { TextSource = { UserId = "x" }, PrefixText = "x:" }, nil), nil)
T.eq(V.window(env, msg(77, ""), nil), nil, "nothing to put it on")
local prior = { PrefixText = "[Dev] Atsuko:" }
out = V.window(env, msg(77, "Atsuko:"), prior)
T.eq(out, prior, "what the game already made is kept")
T.eq(out.PrefixText, "[Dev] Atsuko" .. MARK .. ":")
local styled = { PrefixText = "", PrefixTextProperties = { TextColor3 = "game" } }
out = V.window(env, msg(77, "Atsuko:"), styled)
T.eq(out.PrefixTextProperties.TextColor3, "game", "a color the game set wins")
out = V.window(env, msg(77, '<font color="#123456">Atsuko:</font>'), nil)
T.eq(out.PrefixTextProperties, nil, "a name the game colored with rich text keeps that color")
env.derive = function()
	error("no")
end
T.eq(V.window(env, msg(77, "Atsuko:"), nil), nil, "it gives up quietly when it can't make the result")

T.section("verified: the chat window callback")
local service = {}
local gameCalls = 0
local gameFn = function(message)
	gameCalls = gameCalls + 1
	return { PrefixText = "[VIP] " .. message.PrefixText }
end
service.OnChatWindowAdded = gameFn
env = {
	service = service,
	has = function(id)
		return on[id] == true
	end,
	drawn = function()
		return true
	end,
	derive = function()
		return { PrefixText = "" }
	end,
	getcallback = function(o, name)
		T.eq(o, service)
		T.eq(name, "OnChatWindowAdded")
		return o[name]
	end,
}
local state = V.install(env)
T.eq(state.active, true)
T.eq(state.readable, true)
T.ok(service.OnChatWindowAdded ~= gameFn, "ours is on top")
T.eq(service.OnChatWindowAdded(msg(77, "Atsuko:")).PrefixText, "[VIP] Atsuko" .. MARK .. ":", "the game's own callback still runs first")
T.eq(gameCalls, 1)
T.eq(service.OnChatWindowAdded(msg(6, "Tory:")).PrefixText, "[VIP] Tory:", "other players keep what the game gave them")
local handler = service.OnChatWindowAdded
state.remove()
T.eq(state.active, false)
T.eq(service.OnChatWindowAdded, gameFn, "removing gives the game its callback back")
T.eq(handler(msg(77, "Atsuko:")).PrefixText, "[VIP] Atsuko:", "a stale callback only passes the game's result on")
state.remove()

T.section("verified: an executor that can't read callbacks")
do
	local svc = {}
	local st = V.install({ service = svc, has = function() return true end, derive = function() return { PrefixText = "" } end, drawn = function() return true end })
	T.eq(st.active, true, "it still works")
	T.eq(st.readable, nil, "and says it couldn't read the old one")
	T.eq(svc.OnChatWindowAdded(msg(77, "Atsuko:")).PrefixText, "Atsuko" .. MARK .. ":")
	st.remove()
	T.eq(svc.OnChatWindowAdded, nil)
	local st2 = V.install({ service = svc, has = function() return true end, getcallback = function() error("can't read") end, derive = function() return {} end })
	T.eq(st2.active, true)
	T.eq(st2.readable, nil)
	st2.remove()
	T.eq(V.install({}).active, false, "no chat service")
	T.eq(V.install({}).reason, "noservice")
	local locked = setmetatable({}, { __newindex = function() error("read only") end })
	local st3 = V.install({ service = locked, getcallback = function() return nil end })
	T.eq(st3.active, false, "a service that refuses is left alone")
	T.eq(st3.reason, "locked")
	local throws = {}
	local st4 = V.install({ service = throws, has = function() return true end, derive = function() return { PrefixText = "" } end, drawn = function() return true end, getcallback = function()
		return function()
			error("game bug")
		end
	end })
	T.eq(throws.OnChatWindowAdded(msg(77, "Atsuko:")).PrefixText, "Atsuko" .. MARK .. ":", "a game callback that errors doesn't stop ours")
	st4.remove()
end
