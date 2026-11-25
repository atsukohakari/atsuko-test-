local Dispatch = {}
Dispatch.__index = Dispatch

Dispatch.PRIORITY = { script = 300, reanim = 200, hub = 100 }

local function lower(s)
	return string.lower(tostring(s or ""))
end

local function trim(s)
	return (string.gsub(string.gsub(s, "^%s+", ""), "%s+$", ""))
end

function Dispatch.new(opts)
	opts = opts or {}
	local self = setmetatable({}, Dispatch)
	self.owners = {}
	self.seq = 0
	self.clock = opts.clock or os.clock
	self.prefix = opts.prefix or function()
		return ";"
	end
	self.parse = opts.parse
	self.newGuard = opts.newGuard
	self.guard = self.newGuard and self.newGuard() or nil
	self.log = opts.log or function() end
	self.onChange = opts.onChange
	return self
end

local function changed(self)
	self.version = (self.version or 0) + 1
	if self.onChange then
		pcall(self.onChange, self.version)
	end
end

local function ownerList(self)
	local list = {}
	for _, o in pairs(self.owners) do
		list[#list + 1] = o
	end
	table.sort(list, function(a, b)
		if a.priority ~= b.priority then
			return a.priority > b.priority
		end
		return a.seq > b.seq
	end)
	return list
end

local function tokensOf(def)
	local out = {}
	local seen = {}
	local function add(t, off)
		t = lower(t)
		if t ~= "" and not seen[t] then
			seen[t] = true
			out[#out + 1] = { token = t, off = off }
		end
	end
	add(def.id, false)
	add(def.name, false)
	for _, a in ipairs(def.aliases or {}) do
		add(a, false)
	end
	for _, a in ipairs(def.offNames or {}) do
		add(a, true)
	end
	return out
end

local function lookupIn(owner, token)
	if owner.declared[token] then
		return nil, false, true
	end
	if owner.resolver then
		local ok, def, off = pcall(owner.resolver, token)
		if ok and def then
			return def, off == true, false
		end
		return nil, false, false
	end
	local hit = owner.index[token]
	if hit then
		return hit.def, hit.off, false
	end
	if string.sub(token, 1, 2) == "un" then
		local base = owner.index[string.sub(token, 3)]
		if base and base.def.kind == "toggle" and not base.off then
			return base.def, true, false
		end
	end
	return nil, false, false
end

function Dispatch:register(ownerId, kind, cmds, opts)
	opts = opts or {}
	local priority = Dispatch.PRIORITY[kind]
	if not priority then
		return nil, "unknown owner kind"
	end
	ownerId = lower(ownerId)
	if ownerId == "" then
		return nil, "owner needs an id"
	end
	self.seq = self.seq + 1
	local owner = {
		id = ownerId,
		kind = kind,
		priority = priority,
		seq = self.seq,
		label = opts.label or ownerId,
		short = lower(opts.short),
		legacy = opts.legacyPrefixes or {},
		resolver = opts.resolver,
		runner = opts.runner,
		lister = opts.lister,
		cmds = cmds or {},
		index = {},
		declared = {},
	}
	for _, def in ipairs(owner.cmds) do
		for _, t in ipairs(tokensOf(def)) do
			if not owner.index[t.token] then
				owner.index[t.token] = { def = def, off = t.off }
			end
		end
	end
	self.owners[ownerId] = owner
	changed(self)
	local handle = { owner = ownerId }
	function handle.unregister()
		if self.owners[ownerId] == owner then
			self:unregister(ownerId)
		end
	end
	return handle
end

function Dispatch:declare(ownerId, kind, names, opts)
	opts = opts or {}
	ownerId = lower(ownerId)
	local owner = self.owners[ownerId]
	if not owner then
		local handle, err = self:register(ownerId, kind, {}, opts)
		if not handle then
			return nil, err
		end
		owner = self.owners[ownerId]
	end
	for _, n in ipairs(names or {}) do
		owner.declared[lower(n)] = true
	end
	changed(self)
	return { owner = ownerId }
end

function Dispatch:unregister(ownerId)
	ownerId = lower(ownerId)
	if self.owners[ownerId] then
		self.owners[ownerId] = nil
		changed(self)
		return true
	end
	return false
end

function Dispatch:has(word)
	local def = self:resolve(word)
	if def then
		return true
	end
	local token = lower(word)
	for _, owner in ipairs(ownerList(self)) do
		if owner.declared[token] then
			return true
		end
	end
	return false
end

function Dispatch:resolve(word)
	local token = lower(word)
	local addrOwner, addrToken = string.match(token, "^([%w_%-]+):(.+)$")
	if addrOwner then
		for _, owner in ipairs(ownerList(self)) do
			if owner.id == addrOwner or (owner.short ~= "" and owner.short == addrOwner) then
				local def, off, declared = lookupIn(owner, addrToken)
				if def or declared then
					return def, owner.id, {}, off, declared
				end
			end
		end
		return nil
	end
	local winner, winnerOwner, winnerOff, winnerDeclared
	local shadowed = {}
	for _, owner in ipairs(ownerList(self)) do
		local def, off, declared = lookupIn(owner, token)
		if def or declared then
			if not winnerOwner then
				winner, winnerOwner, winnerOff, winnerDeclared = def, owner.id, off, declared
			else
				shadowed[#shadowed + 1] = { owner = owner.id, def = def }
			end
		end
	end
	if not winnerOwner then
		return nil
	end
	return winner, winnerOwner, shadowed, winnerOff, winnerDeclared
end

local function execute(self, owner, def, off, rest, source)
	local arg = rest ~= "" and rest or nil
	local ctx = { owner = owner.id, source = source, off = off == true, state = nil }
	if def.kind == "toggle" then
		local la = arg and lower(arg)
		if off or la == "off" then
			ctx.state = false
			ctx.off = true
			arg = nil
		elseif la == "toggle" then
			ctx.state = nil
			arg = nil
		else
			ctx.state = true
			if la == "on" then
				arg = nil
			end
		end
	end
	if owner.runner then
		local ok, res = pcall(owner.runner, def, ctx, arg)
		if not ok then
			self.log("error", owner.id, tostring(res))
		end
		return true
	end
	if type(def.run) == "function" then
		local ok, res = pcall(def.run, arg, ctx)
		if not ok then
			self.log("error", owner.id .. ":" .. tostring(def.id), tostring(res))
		end
	end
	return true
end

function Dispatch:run(word, rest, source)
	local def, ownerId, _, off, declared = self:resolve(word)
	if declared then
		return true, "declared"
	end
	if not def then
		return false
	end
	local owner = self.owners[ownerId]
	if not owner then
		return false
	end
	execute(self, owner, def, off, rest or "", source or "ui")
	return true, ownerId
end

function Dispatch:legacyMatch(text)
	for _, owner in ipairs(ownerList(self)) do
		for _, p in ipairs(owner.legacy) do
			local head = string.sub(text, 1, #p)
			if lower(head) == lower(p) then
				local body = trim(string.sub(text, #p + 1))
				local word, rest = string.match(body, "^(%S+)%s*(.-)%s*$")
				if word then
					local token = lower(word)
					local def, off, declared = lookupIn(owner, token)
					if def or declared then
						return owner, def, off, rest, declared
					end
				end
			end
		end
	end
	return nil
end

function Dispatch:handle(text, source)
	if type(text) ~= "string" then
		return false
	end
	source = source or "chat"
	local s = trim(text)
	if s == "" then
		return false
	end
	if source == "chat" and self.guard and not self.guard:pass(s, self.clock()) then
		return true, { kind = "duplicate" }
	end
	if source == "chat" then
		local owner, def, off, rest, declared = self:legacyMatch(s)
		if owner then
			if declared then
				return true, { kind = "declared" }
			end
			execute(self, owner, def, off, rest, source)
			return true, { kind = "command", owner = owner.id }
		end
	end
	if not self.parse then
		return false
	end
	local info = self.parse(s, source == "chat" and "chat" or "bar", self.prefix(), function(word)
		return self:has(word)
	end)
	if info.kind == "command" then
		local done, who = self:run(info.word, info.rest, source)
		info.owner = who
		return done, info
	end
	return false, info
end

function Dispatch:isCommand(text)
	if type(text) ~= "string" then
		return false
	end
	local s = trim(text)
	if s == "" then
		return false
	end
	if self:legacyMatch(s) then
		return true
	end
	if not self.parse then
		return false
	end
	local info = self.parse(s, "chat", self.prefix(), function(word)
		return self:has(word)
	end)
	return info.kind == "command" or info.kind == "reload"
end

function Dispatch:list()
	local out = {}
	for _, owner in ipairs(ownerList(self)) do
		local defs = owner.cmds
		if owner.lister then
			local ok, res = pcall(owner.lister)
			defs = ok and type(res) == "table" and res or {}
		end
		for _, def in ipairs(defs) do
			out[#out + 1] = { def = def, owner = owner.id, label = owner.label, kind = owner.kind, priority = owner.priority }
		end
	end
	for _, row in ipairs(out) do
		local first = tokensOf(row.def)[1]
		if first then
			local _, ownerId = self:resolve(first.token)
			if ownerId and ownerId ~= row.owner then
				row.shadowedBy = ownerId
			end
		end
	end
	table.sort(out, function(a, b)
		local an, bn = lower(a.def.name or a.def.id), lower(b.def.name or b.def.id)
		if an ~= bn then
			return an < bn
		end
		return a.priority > b.priority
	end)
	return out
end

function Dispatch:ownerIds()
	local ids = {}
	for _, o in ipairs(ownerList(self)) do
		ids[#ids + 1] = o.id
	end
	return ids
end

function Dispatch:ownerOf(word)
	local _, ownerId, shadowed = self:resolve(word)
	return ownerId, shadowed
end

function Dispatch:clear()
	self.owners = {}
	changed(self)
end

return Dispatch
