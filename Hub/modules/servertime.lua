local Time = {}

Time.KEEP = 100
Time.FORGET = 30 * 86400
Time.LONGEST = 90 * 86400
Time.AGE_WORDS = { "serverage", "serveruptime", "uptime", "serverlifetime", "serverlife", "serverruntime" }
Time.START_WORDS = { "serverstart", "serverstarttime", "serverstarted", "serverstartedat", "servercreated", "servercreatedat", "servercreation", "serverborn", "serverbirth", "starttime", "startedat" }
Time.FOLDERS = { Folder = true, Configuration = true }
Time.RESCAN = 30

local AGE, START = {}, {}
for _, w in ipairs(Time.AGE_WORDS) do
	AGE[w] = true
end
for _, w in ipairs(Time.START_WORDS) do
	START[w] = true
end

local function get(o, key)
	local ok, v = pcall(function()
		return o[key]
	end)
	if ok then
		return v
	end
	return nil
end

function Time.text(secs)
	secs = tonumber(secs) or 0
	if secs ~= secs or secs < 0 then
		secs = 0
	end
	secs = math.floor(secs)
	local d = math.floor(secs / 86400)
	local h = math.floor((secs % 86400) / 3600)
	local m = math.floor((secs % 3600) / 60)
	local s = secs % 60
	if d > 0 then
		return d .. "d " .. h .. "h " .. m .. "m " .. s .. "s"
	end
	if h > 0 then
		return h .. "h " .. m .. "m " .. s .. "s"
	end
	if m > 0 then
		return m .. "m " .. s .. "s"
	end
	return s .. "s"
end

function Time.key(name)
	return string.lower((string.gsub(tostring(name or ""), "[^%w]", "")))
end

function Time.number(v)
	if type(v) == "number" then
		return v
	end
	if type(v) == "string" then
		return tonumber((string.match(v, "^%s*(.-)%s*$")))
	end
	return nil
end

function Time.read(name, value, now)
	local key = Time.key(name)
	local n = Time.number(value)
	if not n or n ~= n then
		return nil
	end
	local secs
	if AGE[key] then
		secs = n
	elseif START[key] then
		if n > 1e11 then
			n = n / 1000
		end
		if n < 1e9 then
			return nil
		end
		secs = now - n
	else
		return nil
	end
	if secs < 0 or secs > Time.LONGEST then
		return nil
	end
	return secs
end

local function scan(o, now, depth, found)
	local attrs = nil
	pcall(function()
		attrs = o:GetAttributes()
	end)
	if type(attrs) == "table" then
		for name, value in pairs(attrs) do
			local secs = Time.read(name, value, now)
			if secs then
				found[#found + 1] = { secs = secs, from = tostring(get(o, "Name") or "?") .. "." .. tostring(name) }
			end
		end
	end
	if depth <= 0 then
		return
	end
	local kids = nil
	pcall(function()
		kids = o:GetChildren()
	end)
	if type(kids) ~= "table" then
		return
	end
	for _, c in ipairs(kids) do
		local class = tostring(get(c, "ClassName") or "")
		if string.find(class, "Value$") then
			local secs = Time.read(get(c, "Name"), get(c, "Value"), now)
			if secs then
				found[#found + 1] = { secs = secs, from = tostring(get(c, "Name")) }
			end
		elseif Time.FOLDERS[class] then
			scan(c, now, depth - 1, found)
		end
	end
end

function Time.published(roots, now)
	local found = {}
	for _, root in ipairs(roots or {}) do
		if root then
			scan(root, now, 2, found)
		end
	end
	local best = nil
	for _, f in ipairs(found) do
		if not best or f.secs > best.secs then
			best = f
		end
	end
	if best then
		return best.secs, best.from
	end
	return nil
end

function Time.remember(saved, jobId, joined, now)
	local book = {}
	if type(saved) == "table" then
		for id, at in pairs(saved) do
			at = tonumber(at)
			if type(id) == "string" and at and now - at <= Time.FORGET then
				book[id] = at
			end
		end
	end
	local first = joined
	if type(jobId) == "string" and jobId ~= "" then
		local before = book[jobId]
		if before and before < first then
			first = before
		end
		book[jobId] = first
	end
	local ids = {}
	for id in pairs(book) do
		ids[#ids + 1] = id
	end
	if #ids > Time.KEEP then
		table.sort(ids, function(a, b)
			return book[a] > book[b]
		end)
		for i = Time.KEEP + 1, #ids do
			if ids[i] ~= jobId then
				book[ids[i]] = nil
			end
		end
	end
	return first, book
end

function Time.new(env)
	local T = { conns = {}, joins = {} }
	local function now()
		local ok, t = pcall(env.now)
		if ok and type(t) == "number" and t > 1e9 then
			return t
		end
		return os.time()
	end
	local function here()
		local ok, t = pcall(env.here)
		if ok and type(t) == "number" and t == t and t >= 0 then
			return t
		end
		return 0
	end
	local t0 = now()
	T.joined = t0 - here()
	T.started = t0
	local saved = nil
	if type(env.load) == "function" then
		local ok, got = pcall(env.load)
		if ok then
			saved = got
		end
	end
	local book
	T.first, book = Time.remember(saved, env.jobId, T.joined, t0)
	T.before = T.first < T.joined - 1
	if type(env.save) == "function" then
		pcall(env.save, book)
	end
	local players = env.players
	if players then
		pcall(function()
			T.conns[#T.conns + 1] = players.PlayerAdded:Connect(function(p)
				T.joins[#T.joins + 1] = { player = p, at = now() }
			end)
		end)
	end
	function T.now()
		return now()
	end
	function T.here()
		return math.max(0, now() - T.joined)
	end
	function T.age()
		local t = now()
		local cache = T.cache
		if not cache or t - cache.at >= Time.RESCAN or t < cache.at then
			local roots = {}
			if type(env.roots) == "function" then
				local ok, list = pcall(env.roots)
				if ok and type(list) == "table" then
					roots = list
				end
			end
			local secs, from = Time.published(roots, t)
			cache = { at = t, secs = secs, from = from }
			T.cache = cache
		end
		if cache.secs then
			return cache.secs + (t - cache.at), "game", cache.from
		end
		return math.max(0, t - T.first), T.before and "before" or "least"
	end
	function T.newest(limit)
		local t = now()
		local out = {}
		for i = #T.joins, 1, -1 do
			local j = T.joins[i]
			local inGame = get(j.player, "Parent") ~= nil
			if inGame then
				local seen = false
				for _, o in ipairs(out) do
					if o.player == j.player then
						seen = true
					end
				end
				if not seen then
					out[#out + 1] = { player = j.player, ago = math.max(0, t - j.at) }
				end
			end
			if limit and #out >= limit then
				break
			end
		end
		return out
	end
	function T.stop()
		for _, c in ipairs(T.conns) do
			pcall(function()
				c:Disconnect()
			end)
		end
		T.conns = {}
	end
	return T
end

return Time
