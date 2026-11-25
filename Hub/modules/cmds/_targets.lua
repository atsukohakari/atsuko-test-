local Targets = {}

Targets.CAP = 30

local function lower(s)
	return string.lower(tostring(s or ""))
end

local function nameOf(p)
	return tostring(p and p.Name or "")
end

local function shownOf(p)
	local d = p and p.DisplayName
	if d == nil or d == "" then
		return nameOf(p)
	end
	return tostring(d)
end

local function teamOf(p)
	local t = p and p.Team
	if t == nil then
		return ""
	end
	if type(t) == "string" then
		return t
	end
	return tostring(t.Name or "")
end

function Targets.split(text)
	local out = {}
	for word in string.gmatch(tostring(text or ""), "%S+") do
		out[#out + 1] = word
	end
	return out
end

function Targets.tier(p, q)
	local n, d = lower(nameOf(p)), lower(shownOf(p))
	if n == q or d == q then
		return 1
	end
	if string.sub(n, 1, #q) == q or string.sub(d, 1, #q) == q then
		return 2
	end
	if string.find(n, q, 1, true) or string.find(d, q, 1, true) then
		return 3
	end
	return nil
end

function Targets.byName(q, players)
	q = lower(q)
	if q == "" then
		return nil, 0
	end
	local best, bestTier, count = nil, 99, 0
	for _, p in ipairs(players) do
		local t = Targets.tier(p, q)
		if t then
			count += 1
			local better = false
			if t < bestTier then
				better = true
			elseif t == bestTier and best then
				local a, b = #nameOf(p), #nameOf(best)
				better = a < b or (a == b and lower(nameOf(p)) < lower(nameOf(best)))
			end
			if better then
				best, bestTier = p, t
			end
		end
	end
	return best, count
end

local function same(a, b)
	if a == b then
		return true
	end
	if type(a) == "table" and type(b) == "table" and a.UserId ~= nil and a.UserId == b.UserId then
		return true
	end
	return false
end

local function contains(list, p)
	for _, q in ipairs(list) do
		if same(q, p) then
			return true
		end
	end
	return false
end

local function without(list, p)
	local out = {}
	for _, q in ipairs(list) do
		if not same(q, p) then
			out[#out + 1] = q
		end
	end
	return out
end

local function excluded(ctx, p)
	local set = ctx.except
	return type(set) == "table" and set[lower(nameOf(p))] == true
end

local function others(ctx)
	local out = {}
	for _, p in ipairs(ctx.players) do
		if not same(p, ctx.me) then
			out[#out + 1] = p
		end
	end
	return out
end

local function ranked(ctx, far)
	if type(ctx.distance) ~= "function" then
		return nil, "I can't tell how far players are right now"
	end
	local pick, pickD
	for _, p in ipairs(others(ctx)) do
		local d = ctx.distance(p)
		if type(d) == "number" and (pickD == nil or (far and d > pickD) or (not far and d < pickD)) then
			pick, pickD = p, d
		end
	end
	if not pick then
		return nil, "Nobody else is around"
	end
	return { pick }
end

function Targets.word(word, ctx, notes)
	local w = lower(word)
	local me = ctx.me
	if w == "me" or w == "self" then
		return me and { me } or {}
	end
	if w == "all" then
		local out = {}
		for _, p in ipairs(ctx.players) do
			if same(p, me) or not excluded(ctx, p) then
				out[#out + 1] = p
			end
		end
		return out
	end
	if w == "others" then
		local out = {}
		for _, p in ipairs(others(ctx)) do
			if not excluded(ctx, p) then
				out[#out + 1] = p
			end
		end
		return out
	end
	if w == "random" then
		local list = others(ctx)
		if #list == 0 then
			return {}
		end
		local pick = list[(ctx.rand or function() return 1 end)(#list)]
		return pick and { pick } or {}
	end
	if w == "nearest" or w == "farthest" then
		local list, why = ranked(ctx, w == "farthest")
		if not list then
			notes[#notes + 1] = why
			return {}
		end
		return list
	end
	if w == "friends" then
		local out = {}
		if type(ctx.isFriend) == "function" then
			for _, p in ipairs(others(ctx)) do
				if ctx.isFriend(p) then
					out[#out + 1] = p
				end
			end
		else
			notes[#notes + 1] = "I can't see your friends right now"
		end
		return out
	end
	local team = string.match(w, "^team:(.+)$")
	if team then
		local out = {}
		for _, p in ipairs(ctx.players) do
			local tn = lower(teamOf(p))
			if tn ~= "" and (tn == team or string.find(tn, team, 1, true)) then
				out[#out + 1] = p
			end
		end
		return out
	end
	local id = string.match(w, "^@(%d+)$")
	if id then
		local n = tonumber(id)
		for _, p in ipairs(ctx.players) do
			if p.UserId == n then
				return { p }
			end
		end
		return {}
	end
	local hit, count = Targets.byName(w, ctx.players)
	if hit then
		if count > 1 then
			notes[#notes + 1] = "Picked " .. nameOf(hit) .. " out of " .. count .. " matches"
		end
		return { hit }
	end
	return {}
end

function Targets.resolve(text, ctx)
	local res = { players = {}, notes = {}, missing = {}, truncated = false }
	ctx = ctx or {}
	ctx.players = ctx.players or {}
	local words = Targets.split(text)
	if #words == 0 then
		res.error = "Say who: a name, me, all, others, random, nearest, farthest, friends, team:name or @userid"
		return res
	end
	local set = {}
	local onlyMinus = true
	for _, w in ipairs(words) do
		if string.sub(w, 1, 1) ~= "-" or #w == 1 then
			onlyMinus = false
		end
	end
	if onlyMinus then
		set = Targets.word("all", ctx, res.notes)
	end
	for _, w in ipairs(words) do
		local neg = string.sub(w, 1, 1) == "-" and #w > 1
		local body = neg and string.sub(w, 2) or w
		local got = Targets.word(body, ctx, res.notes)
		if neg then
			for _, p in ipairs(got) do
				set = without(set, p)
			end
		elseif #got == 0 then
			res.missing[#res.missing + 1] = body
		else
			for _, p in ipairs(got) do
				if not contains(set, p) then
					set[#set + 1] = p
				end
			end
		end
	end
	local cap = ctx.cap or Targets.CAP
	if #set > cap then
		local cut = {}
		for i = 1, cap do
			cut[i] = set[i]
		end
		set = cut
		res.truncated = true
		res.notes[#res.notes + 1] = "Only the first " .. cap .. " players were used"
	end
	res.players = set
	if #set == 0 then
		if #res.missing > 0 then
			res.error = "No player matches " .. table.concat(res.missing, ", ")
		else
			res.error = "Nobody left after the exclusions"
		end
	end
	return res
end

function Targets.one(text, ctx)
	local res = Targets.resolve(text, ctx)
	return res.players[1], res
end

function Targets.names(list)
	local out = {}
	for _, p in ipairs(list) do
		out[#out + 1] = nameOf(p)
	end
	return table.concat(out, ", ")
end

return Targets
