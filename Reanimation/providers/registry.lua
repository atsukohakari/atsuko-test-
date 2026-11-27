local Registry = {}
Registry.__index = Registry

Registry.version = 1
Registry.CAPS = { fdApi = true, emotes = true, bodyCommands = true, fling = true, bullet = true, stoppable = true, respawnSafe = true, needsR6 = true }
Registry.KINDS = { hat = true, limb = true }
Registry.IDS = { "atsuko", "fdless", "gelatek", "uhhhhhh" }
Registry.KIND_OF = { atsuko = "hat", fdless = "hat", gelatek = "limb", uhhhhhh = "limb" }
Registry.NAME_OF = { atsuko = "Script Reanimate", fdless = "FDless", gelatek = "Gelatek", uhhhhhh = "Uhhhhhh" }
Registry.DEFAULT_OF = { limb = "gelatek" }
Registry.SETTING_OF = { hat = "hatReanim", limb = "reanimLimb" }
Registry.MUST_PICK = { hat = true }
Registry.PICK_TEXT = { hat = "Pick a reanimation first, at the top of the Hat tab" }
Registry.OFF = { atsuko = true }
Registry.POLL = 1
Registry.START_LIMIT = 45
Registry.STOP_LIMIT = 12
Registry.SETTLE = 0.3
Registry.TRANSITIONS = {
	idle = { starting = true },
	starting = { running = true, idle = true, stopping = true },
	running = { stopping = true, idle = true, starting = true },
	stopping = { idle = true, running = true },
}
Registry.EVENT_OF = { idle = "stopped", starting = "starting", running = "running", stopping = "stopping" }
Registry.ASK_REASONS = { user = true, switch = true }

local function sortedKeys(t)
	local keys = {}
	for k in pairs(t) do
		keys[#keys + 1] = k
	end
	table.sort(keys, function(a, b)
		return tostring(a) < tostring(b)
	end)
	return keys
end

local function firstLine(text)
	text = tostring(text)
	return (string.match(text, "^[^\r\n]*")) or text
end

function Registry.clampOption(def, value)
	if type(def) ~= "table" then
		return nil
	end
	local kind = def.type
	if kind == "toggle" then
		if type(value) == "boolean" then
			return value
		end
		return def.default == true
	elseif kind == "choice" then
		local options = def.options or {}
		for _, option in ipairs(options) do
			if option == value then
				return value
			end
		end
		if type(value) == "string" then
			local lowered = string.lower(value)
			for _, option in ipairs(options) do
				if string.lower(tostring(option)) == lowered then
					return option
				end
			end
		end
		return def.default
	elseif kind == "number" then
		local n = tonumber(value)
		if n == nil or n ~= n or n == math.huge or n == -math.huge then
			return def.default
		end
		if def.min and n < def.min then
			n = def.min
		end
		if def.max and n > def.max then
			n = def.max
		end
		if def.integer then
			n = math.floor(n + 0.5)
		end
		return n
	elseif kind == "text" then
		if type(value) == "string" then
			return string.sub(value, 1, def.max or 64)
		end
		return def.default
	end
	return def.default
end

function Registry.validate(p)
	local problems = {}
	if type(p) ~= "table" then
		return { "provider is not a table" }
	end
	if p.AtsukoReanimProvider ~= true then
		problems[#problems + 1] = "missing AtsukoReanimProvider marker"
	end
	if type(p.id) ~= "string" or p.id == "" or string.lower(p.id) ~= p.id or string.find(p.id, "[^%l%d_]") then
		problems[#problems + 1] = "id must be a lower-case word"
	end
	if not Registry.KINDS[p.kind] then
		problems[#problems + 1] = "kind must be hat or limb"
	end
	if type(p.name) ~= "string" or p.name == "" then
		problems[#problems + 1] = "name is missing"
	elseif string.find(p.name, "%.lua$") or p.name == p.id then
		problems[#problems + 1] = "name must be a readable name, not a file name or an id"
	end
	if type(p.credit) ~= "string" or p.credit == "" then
		problems[#problems + 1] = "credit is missing"
	end
	if p.blurb ~= nil and (type(p.blurb) ~= "string" or p.blurb == "") then
		problems[#problems + 1] = "blurb must be text"
	end
	if type(p.caps) ~= "table" then
		problems[#problems + 1] = "caps is missing"
	else
		for k, v in pairs(p.caps) do
			if not Registry.CAPS[k] then
				problems[#problems + 1] = "unknown capability " .. tostring(k)
			elseif type(v) ~= "boolean" then
				problems[#problems + 1] = "capability " .. tostring(k) .. " must be true or false"
			end
		end
		for k in pairs(Registry.CAPS) do
			if p.caps[k] == nil then
				problems[#problems + 1] = "capability " .. k .. " is not stated"
			end
		end
		if p.kind == "limb" and p.caps.fdApi == true then
			problems[#problems + 1] = "a limb provider cannot claim the FDless API"
		end
	end
	for _, fname in ipairs({ "available", "start", "stop", "isRunning", "reset" }) do
		if type(p[fname]) ~= "function" then
			problems[#problems + 1] = fname .. " must be a function"
		end
	end
	if p.settings ~= nil then
		if type(p.settings) ~= "table" then
			problems[#problems + 1] = "settings must be a list"
		else
			local seen = {}
			for i, def in ipairs(p.settings) do
				if type(def) ~= "table" or type(def.key) ~= "string" or def.key == "" then
					problems[#problems + 1] = "setting " .. i .. " has no key"
				elseif seen[def.key] then
					problems[#problems + 1] = "setting " .. def.key .. " is listed twice"
				else
					seen[def.key] = true
					if def.type ~= "toggle" and def.type ~= "choice" and def.type ~= "number" and def.type ~= "text" then
						problems[#problems + 1] = "setting " .. def.key .. " has an unknown type"
					end
					if def.default == nil then
						problems[#problems + 1] = "setting " .. def.key .. " has no default"
					end
					if def.type == "choice" and (type(def.options) ~= "table" or #def.options == 0) then
						problems[#problems + 1] = "setting " .. def.key .. " has no options"
					end
					if def.labels ~= nil and (type(def.labels) ~= "table" or type(def.options) ~= "table" or #def.labels ~= #def.options) then
						problems[#problems + 1] = "setting " .. def.key .. " needs one label for each option"
					end
					if def.optionNeeds ~= nil and type(def.optionNeeds) ~= "table" then
						problems[#problems + 1] = "setting " .. def.key .. " has a broken optionNeeds"
					end
					if def.applies ~= nil and def.applies ~= "now" and def.applies ~= "next" then
						problems[#problems + 1] = "setting " .. def.key .. " applies must be now or next"
					end
					if def.label ~= nil and type(def.label) ~= "string" then
						problems[#problems + 1] = "setting " .. def.key .. " has a label that is not text"
					end
				end
			end
		end
	end
	if p.commands ~= nil and type(p.commands) ~= "table" and type(p.commands) ~= "function" then
		problems[#problems + 1] = "commands must be a list or a function"
	end
	if p.driver ~= nil and type(p.driver) ~= "function" then
		problems[#problems + 1] = "driver must be a function"
	end
	if p.prepare ~= nil and type(p.prepare) ~= "function" then
		problems[#problems + 1] = "prepare must be a function"
	end
	if p.forget ~= nil and type(p.forget) ~= "function" then
		problems[#problems + 1] = "forget must be a function"
	end
	if p.stopWarning ~= nil and (type(p.stopWarning) ~= "string" or p.stopWarning == "") then
		problems[#problems + 1] = "stopWarning must be text"
	end
	return problems
end

function Registry.compare(before, after, keep)
	local out = {}
	before = before or {}
	after = after or {}
	keep = keep or {}
	local function kept(key)
		key = tostring(key)
		if keep[key] == true then
			return true
		end
		for _, pattern in ipairs(keep) do
			if string.find(key, pattern) then
				return true
			end
		end
		return false
	end
	local bv, av = before.values or {}, after.values or {}
	local all = {}
	for k in pairs(bv) do
		all[k] = true
	end
	for k in pairs(av) do
		all[k] = true
	end
	for _, k in ipairs(sortedKeys(all)) do
		if bv[k] ~= av[k] and not kept(k) then
			out[#out + 1] = tostring(k) .. " changed: " .. tostring(bv[k]) .. " -> " .. tostring(av[k])
		end
	end
	local bs, as = before.sets or {}, after.sets or {}
	for _, name in ipairs(sortedKeys(as)) do
		local b = bs[name] or {}
		for _, key in ipairs(sortedKeys(as[name])) do
			if not b[key] and not kept(key) then
				out[#out + 1] = tostring(name) .. " left behind: " .. tostring(key)
			end
		end
	end
	local bc, ac = before.counts or {}, after.counts or {}
	for _, k in ipairs(sortedKeys(ac)) do
		if (tonumber(ac[k]) or 0) > (tonumber(bc[k]) or 0) and not kept(k) then
			out[#out + 1] = tostring(k) .. " grew: " .. tostring(bc[k] or 0) .. " -> " .. tostring(ac[k])
		end
	end
	return out
end

function Registry.new(opts)
	opts = opts or {}
	local self = setmetatable({}, Registry)
	self.S = opts.S or {}
	self.save = opts.save or function() end
	self.fire = opts.fire or function() end
	self.notify = opts.notify or function() end
	self.wait = opts.wait or (task and task.wait) or function() end
	self.spawn = opts.spawn or (task and task.spawn) or function(f, ...)
		return f(...)
	end
	self.delay = opts.delay or (task and task.delay) or function() end
	self.pollEvery = opts.pollEvery or Registry.POLL
	self.now = opts.now or os.clock
	self.probe = opts.probe
	self.X = opts.X or {}
	self.log = opts.log or function() end
	self.allowed = opts.allowed
	self.confirm = opts.confirm
	self.startLimit = opts.startLimit or Registry.START_LIMIT
	self.stopLimit = opts.stopLimit or Registry.STOP_LIMIT
	self.settle = opts.settle or Registry.SETTLE
	self.providers = {}
	self.order = {}
	self.failed = {}
	self.cur = "idle"
	self.activeId = nil
	self.ctl = nil
	self.before = nil
	self.lastLeak = nil
	self.lastFailure = nil
	self.token = 0
	self.alive = true
	if type(self.S.reanimOpts) ~= "table" then
		self.S.reanimOpts = {}
	end
	return self
end

function Registry:say(title, text, kind, dur)
	local ok, e = pcall(self.notify, title, text, kind or "info", dur)
	if not ok then
		self.log("warn", "reanimation toast failed: " .. firstLine(e))
	end
end

function Registry:askStop(p, reason)
	if not p or not self.confirm then
		return true
	end
	if type(p.stopWarning) ~= "string" or p.stopWarning == "" then
		return true
	end
	if reason ~= nil and not Registry.ASK_REASONS[reason] then
		return true
	end
	local ok, answer = pcall(self.confirm, p.stopWarning, p)
	if not ok then
		self.log("warn", "confirm failed: " .. firstLine(answer))
		return false
	end
	return answer == true
end

function Registry:register(p)
	local problems = Registry.validate(p)
	if #problems > 0 then
		local why = table.concat(problems, "; ")
		self.log("error", "provider " .. tostring(type(p) == "table" and p.id or "?") .. " rejected: " .. why)
		return false, why
	end
	if self.allowed and not self.allowed[p.id] then
		return false, "provider " .. p.id .. " is not one of the allowed providers"
	end
	if Registry.KIND_OF[p.id] and Registry.KIND_OF[p.id] ~= p.kind then
		return false, "provider " .. p.id .. " has the wrong kind"
	end
	if self.providers[p.id] then
		return false, "provider " .. p.id .. " is already registered"
	end
	self.providers[p.id] = p
	self.order[#self.order + 1] = p.id
	self.failed[p.id] = nil
	p.onChanged = function(what, detail)
		self:external(p.id, what, detail)
	end
	return true
end

function Registry:markFailed(id, reason)
	if self.providers[id] then
		self.providers[id] = nil
		for i, oid in ipairs(self.order) do
			if oid == id then
				table.remove(self.order, i)
				break
			end
		end
	end
	self.failed[id] = tostring(reason or "unknown")
end

function Registry:get(id)
	return self.providers[id]
end

function Registry:list(kind)
	local out = {}
	for _, id in ipairs(self.order) do
		local p = self.providers[id]
		if p and (kind == nil or p.kind == kind) then
			out[#out + 1] = p
		end
	end
	return out
end

function Registry:slots(kind)
	local out = {}
	for _, id in ipairs(Registry.IDS) do
		if kind == nil or Registry.KIND_OF[id] == kind then
			local p = self.providers[id]
			out[#out + 1] = {
				id = id,
				kind = Registry.KIND_OF[id],
				name = p and p.name or Registry.NAME_OF[id],
				provider = p,
				failed = (not p) and (self.failed[id] or "not loaded yet") or nil,
			}
		end
	end
	return out
end

function Registry.isOff(id)
	return Registry.OFF[id] == true
end

function Registry.offText(id)
	return (Registry.NAME_OF[id] or tostring(id)) .. " is off for now"
end

function Registry:firstOn(kind)
	for _, candidate in ipairs(self:list(kind)) do
		if not Registry.OFF[candidate.id] then
			return candidate
		end
	end
	return nil
end

function Registry:selected(kind)
	local key = Registry.SETTING_OF[kind]
	if not key then
		return nil
	end
	local want = self.S[key]
	local p = type(want) == "string" and self.providers[want] or nil
	if p and p.kind == kind and Registry.OFF[p.id] then
		return self:firstOn(kind)
	end
	if p and p.kind == kind then
		return p
	end
	if Registry.MUST_PICK[kind] then
		return nil
	end
	p = self.providers[Registry.DEFAULT_OF[kind]]
	if p and p.kind == kind then
		return p
	end
	return self:firstOn(kind)
end

function Registry:mustPick(kind)
	return Registry.MUST_PICK[kind] == true and self:selected(kind) == nil
end

function Registry:select(kind, id)
	local key = Registry.SETTING_OF[kind]
	if not key then
		return false, "unknown kind"
	end
	local p = self.providers[id]
	if not p then
		if self.failed[id] then
			return false, "couldn't load " .. (Registry.NAME_OF[id] or tostring(id)) .. ": " .. self.failed[id]
		end
		return false, "unknown reanimation"
	end
	if p.kind ~= kind then
		return false, p.name .. " is not a " .. kind .. " reanimation"
	end
	if Registry.OFF[id] then
		return false, Registry.offText(id)
	end
	local changed = self.S[key] ~= id
	self.S[key] = id
	if changed then
		self.save()
		self.fire("reanim", { state = self.cur == "idle" and "stopped" or Registry.EVENT_OF[self.cur], provider = self.activeId, selected = id, kind = kind })
	end
	local pending = self.cur ~= "idle" and self.activeId ~= id and self.providers[self.activeId] and self.providers[self.activeId].kind == kind
	return true, pending and "applies the next time you reanimate" or nil
end

function Registry:optionDefs(id)
	local p = self.providers[id]
	return p and type(p.settings) == "table" and p.settings or {}
end

function Registry:optionsOf(id)
	local saved = type(self.S.reanimOpts) == "table" and self.S.reanimOpts[id] or nil
	local out = {}
	for _, def in ipairs(self:optionDefs(id)) do
		local value = nil
		if type(saved) == "table" then
			value = saved[def.key]
		end
		if value == nil then
			value = def.default
		end
		out[def.key] = Registry.clampOption(def, value)
	end
	return out
end

function Registry:optionAvailable(id, key, value)
	for _, d in ipairs(self:optionDefs(id)) do
		if d.key == key then
			local need = type(d.optionNeeds) == "table" and d.optionNeeds[value] or nil
			if need and not self.X[need] then
				return false, "your executor has no " .. need
			end
			return true
		end
	end
	return false, "unknown option"
end

function Registry:setOption(id, key, value)
	local def
	for _, d in ipairs(self:optionDefs(id)) do
		if d.key == key then
			def = d
		end
	end
	if not def then
		return false, "unknown option"
	end
	local allowed, why = self:optionAvailable(id, key, Registry.clampOption(def, value))
	if not allowed then
		return false, why
	end
	if type(self.S.reanimOpts) ~= "table" then
		self.S.reanimOpts = {}
	end
	if type(self.S.reanimOpts[id]) ~= "table" then
		self.S.reanimOpts[id] = {}
	end
	local clean = Registry.clampOption(def, value)
	self.S.reanimOpts[id][key] = clean
	self.save()
	local later = self.cur ~= "idle" and self.activeId == id and def.applies ~= "now"
	self.fire("reanim", { state = self.cur == "idle" and "stopped" or Registry.EVENT_OF[self.cur], provider = self.activeId, option = key })
	return true, clean, later and "applies the next time you reanimate" or nil
end

function Registry:state()
	return self.cur
end

function Registry:activeProvider()
	if self.cur == "idle" then
		return nil
	end
	return self.providers[self.activeId]
end

function Registry:active()
	if self.cur ~= "running" then
		return nil
	end
	return self.providers[self.activeId]
end

function Registry:set(to, p, extra)
	local from = self.cur
	if from == to then
		return false
	end
	if not Registry.TRANSITIONS[from][to] then
		self.log("error", "reanimation state " .. from .. " -> " .. to .. " refused")
		return false
	end
	self.cur = to
	if to == "idle" then
		self.activeId = nil
	elseif p then
		self.activeId = p.id
	end
	local payload = { state = Registry.EVENT_OF[to], provider = (p and p.id) or self.activeId }
	if extra then
		for k, v in pairs(extra) do
			payload[k] = v
		end
	end
	self.fire("reanim", payload)
	return true
end

function Registry:snapshot()
	if type(self.probe) ~= "function" then
		return nil
	end
	local ok, snap = pcall(self.probe)
	if ok and type(snap) == "table" then
		return snap
	end
	return nil
end

function Registry:finishLeak(p)
	if not self.before then
		self.lastLeak = nil
		return nil
	end
	if self.settle > 0 then
		self.wait(self.settle)
	end
	local after = self:snapshot()
	if not after then
		self.lastLeak = nil
		return nil
	end
	self.lastLeak = Registry.compare(self.before, after, p and p.keep)
	self.before = nil
	return self.lastLeak
end

function Registry:leakReport()
	return self.lastLeak
end

function Registry:cleanup(p, ctl)
	if ctl and ctl.stopScript then
		local ok, e = pcall(ctl.stopScript)
		if not ok then
			self.log("warn", "stopping the script failed: " .. firstLine(e))
		end
	end
	local ok, e = pcall(p.stop)
	if not ok then
		self.log("warn", p.name .. " stop failed: " .. firstLine(e))
	end
	local okR, eR = pcall(p.reset)
	if not okR then
		self.log("warn", p.name .. " reset failed: " .. firstLine(eR))
	end
end

function Registry:fail(p, ctl, why)
	why = firstLine(why or "unknown")
	self:cleanup(p, ctl)
	self.lastFailure = why
	self.ctl = nil
	self:set("idle", p, { failed = true, reason = why })
	self:finishLeak(p)
	self:say(p.name, "Couldn't start: " .. why, "error", 5)
	return false, why
end

function Registry:waitRunning(p, ctl, limit)
	local t0 = self.now()
	local token = self.token
	while self.now() - t0 < limit do
		if not self.alive or self.token ~= token then
			return false, "cancelled"
		end
		local okR, running = pcall(p.isRunning)
		if okR and running then
			return true
		end
		if ctl.alive and self.now() - t0 > 1.5 then
			local okA, up = pcall(ctl.alive)
			if okA and not up then
				return false, "the script stopped before it reanimated"
			end
		end
		self.wait(0.1)
	end
	return false, "timed out"
end

function Registry:start(kind, entry, ctl)
	ctl = ctl or {}
	if not self.alive then
		return false, "the hub is closing"
	end
	if self.cur == "starting" or self.cur == "stopping" then
		self:say("Reanimation", "Hold on, " .. (self.cur == "starting" and "it is still starting" or "it is still stopping"), "info", 2.5)
		return false, "busy"
	end
	local p = ctl.force and self.providers[ctl.force] or nil
	if ctl.force and not p and Registry.KIND_OF[ctl.force] == kind then
		local why = self.failed[ctl.force] and ("couldn't load " .. (Registry.NAME_OF[ctl.force] or ctl.force) .. ": " .. self.failed[ctl.force]) or ((Registry.NAME_OF[ctl.force] or ctl.force) .. " is not available")
		self:say("Reanimation", why, "error", 5)
		return false, why
	end
	if not p or p.kind ~= kind then
		p = self:selected(kind)
	end
	if p and Registry.OFF[p.id] then
		local why = Registry.offText(p.id)
		self:say(p.name, why, "info", 4)
		return false, why
	end
	if not p and not ctl.force and Registry.MUST_PICK[kind] then
		local want = self.S[Registry.SETTING_OF[kind]]
		if type(want) == "string" and self.failed[want] and Registry.KIND_OF[want] == kind then
			local why = "couldn't load " .. (Registry.NAME_OF[want] or want) .. ": " .. self.failed[want]
			self:say("Reanimation", why, "error", 5)
			return false, why
		end
		local why = Registry.PICK_TEXT[kind] or "pick a reanimation first"
		self:say("Reanimation", why, "info", 4)
		return false, why
	end
	if not p then
		local slot = ctl.force or Registry.DEFAULT_OF[kind]
		local why = self.failed[slot] and ("couldn't load " .. (Registry.NAME_OF[slot] or slot) .. ": " .. self.failed[slot]) or "no reanimation is available"
		self:say("Reanimation", why, "error", 5)
		return false, why
	end
	local okA, avail, reason = pcall(p.available, self.X)
	if not okA then
		avail, reason = false, firstLine(avail)
	end
	if avail == false then
		local why = tostring(reason or "not available here")
		self:say(p.name, why, "error", 5)
		return false, why
	end
	if self.cur == "running" then
		local prev = self.providers[self.activeId]
		if prev and prev.id == p.id and entry == nil then
			self:say(p.name, "Already running", "info", 2.5)
			return false, "already running"
		end
		if prev and not self:askStop(prev, "switch") then
			return false, "declined"
		end
		if not self.alive then
			return false, "the hub is closing"
		end
		if self.cur == "running" and prev and self.activeId == prev.id then
			self:say("Reanimation", "Stopping " .. prev.name .. " first", "info", 2.5)
			local okStop, whyStop = self:stop("switch", false, true)
			if not okStop then
				return false, whyStop
			end
		elseif self.cur ~= "idle" then
			return false, "busy"
		end
	end
	self.token = self.token + 1
	self.ctl = ctl
	self.lastFailure = nil
	self.before = self:snapshot()
	self:set("starting", p)
	local run = {
		entry = entry,
		options = self:optionsOf(p.id),
		notify = function(title, text, k, d)
			self:say(title, text, k, d)
		end,
		wait = self.wait,
		alive = ctl.alive,
		X = self.X,
	}
	local ok, a, b
	if entry ~= nil and p.kind == "hat" then
		if p.prepare then
			ok, a, b = pcall(p.prepare, entry, run)
			if not ok then
				return self:fail(p, ctl, a)
			end
			if a == false then
				return self:fail(p, ctl, b)
			end
		end
		if ctl.run then
			ok, a, b = pcall(ctl.run)
			if not ok then
				return self:fail(p, ctl, a)
			end
			if a == false then
				return self:fail(p, ctl, b or "the script did not start")
			end
		end
		local okW, whyW = self:waitRunning(p, ctl, ctl.limit or self.startLimit)
		if not okW then
			if whyW == "cancelled" then
				return false, "cancelled"
			end
			return self:fail(p, ctl, whyW)
		end
	else
		ok, a, b = pcall(p.start, run)
		if not ok then
			return self:fail(p, ctl, a)
		end
		if a == false then
			return self:fail(p, ctl, b or "it did not start")
		end
		if entry ~= nil and ctl.run then
			ok, a, b = pcall(ctl.run)
			if not ok then
				return self:fail(p, ctl, a)
			end
			if a == false then
				return self:fail(p, ctl, b or "the script did not start")
			end
		end
	end
	if self.cur ~= "starting" then
		return false, "cancelled"
	end
	self:set("running", p)
	self:watch(p)
	return true
end

function Registry:canSwap(kind, entry, force)
	if self.cur ~= "running" or kind ~= "hat" or entry == nil then
		return false
	end
	local p = self.providers[self.activeId]
	if not p or p.kind ~= kind then
		return false
	end
	if force and force ~= p.id then
		return false
	end
	if Registry.OFF[p.id] then
		return false
	end
	local okA, avail = pcall(p.available, self.X)
	if okA and avail == false then
		return false
	end
	return true, p
end

function Registry:swap(kind, entry, ctl)
	self.swapping = true
	local ok, a, b = pcall(self.swapRun, self, kind, entry, ctl)
	self.swapping = false
	if not ok then
		return false, firstLine(a)
	end
	return a, b
end

function Registry:swapRun(kind, entry, ctl)
	ctl = ctl or {}
	if not self.alive then
		return false, "the hub is closing"
	end
	local can, p = self:canSwap(kind, entry, ctl.force)
	if not can then
		return false, "can't switch"
	end
	local old = self.ctl
	self.token = self.token + 1
	self:set("starting", p, { swap = true })
	if old and old.swapOut then
		if type(p.hold) == "function" then
			pcall(p.hold, true)
		end
		local okS, e = pcall(old.swapOut)
		if type(p.hold) == "function" then
			pcall(p.hold, false)
		end
		if not okS then
			self.log("warn", "stopping the old script failed: " .. firstLine(e))
		end
	end
	self.ctl = ctl
	self.lastFailure = nil
	local run = {
		entry = entry,
		options = self:optionsOf(p.id),
		notify = function(title, text, k, d)
			self:say(title, text, k, d)
		end,
		wait = self.wait,
		alive = ctl.alive,
		X = self.X,
		swap = true,
	}
	if p.prepare then
		local ok, a, b = pcall(p.prepare, entry, run)
		if not ok then
			return self:fail(p, ctl, a)
		end
		if a == false then
			return self:fail(p, ctl, b)
		end
	end
	if ctl.run then
		local ok, a, b = pcall(ctl.run)
		if not ok then
			return self:fail(p, ctl, a)
		end
		if a == false then
			return self:fail(p, ctl, b or "the script did not start")
		end
	end
	local okW, whyW = self:waitRunning(p, ctl, ctl.limit or self.startLimit)
	if not okW then
		if whyW == "cancelled" then
			return false, "cancelled"
		end
		return self:fail(p, ctl, whyW)
	end
	if self.cur ~= "starting" then
		return false, "cancelled"
	end
	self:set("running", p, { swap = true })
	self:watch(p)
	return true
end

function Registry:watch(p)
	local token = self.token
	local misses = 0
	local function tick()
		if not (self.alive and self.token == token and self.cur == "running" and self.activeId == p.id) then
			return
		end
		local ok, running = pcall(p.isRunning)
		if ok and running then
			misses = 0
		else
			misses = misses + 1
		end
		if misses >= 2 then
			self:external(p.id, "stopped", "Stopped on its own")
			return
		end
		self.delay(self.pollEvery, tick)
	end
	self.delay(self.pollEvery, tick)
end

function Registry:stop(reason, force, asked)
	if self.cur == "idle" then
		return true
	end
	if self.cur == "stopping" then
		return false, "busy"
	end
	if self.cur == "starting" and not force then
		self:say("Reanimation", "Hold on, it is still starting", "info", 2.5)
		return false, "busy"
	end
	local p = self.providers[self.activeId]
	if p and not asked and not force then
		local id = p.id
		if not self:askStop(p, reason) then
			return false, "declined"
		end
		if not self.alive then
			return false, "the hub is closing"
		end
		if self.activeId ~= id then
			if self.cur == "idle" then
				return true
			end
			return false, "busy"
		end
		return self:stop(reason, force, true)
	end
	local ctl = self.ctl
	if not p then
		self.cur = "idle"
		self.activeId = nil
		return true
	end
	self.token = self.token + 1
	self:set("stopping", p, { reason = reason })
	if ctl and ctl.stopScript then
		local ok, e = pcall(ctl.stopScript)
		if not ok then
			self.log("warn", "stopping the script failed: " .. firstLine(e))
		end
	end
	local ok, e = pcall(p.stop)
	if not ok then
		self.log("warn", p.name .. " stop failed: " .. firstLine(e))
	end
	local t0 = self.now()
	local still = true
	while self.now() - t0 < self.stopLimit do
		local okR, running = pcall(p.isRunning)
		if okR and not running then
			still = false
			break
		end
		self.wait(0.1)
	end
	if still then
		self:set("running", p, { failed = true, reason = "stop timed out" })
		self:say(p.name, "Couldn't stop it in time, it is still running", "error", 5)
		return false, "stop timed out"
	end
	local okReset, eReset = pcall(p.reset)
	if not okReset then
		self.log("warn", p.name .. " reset failed: " .. firstLine(eReset))
	end
	self.ctl = nil
	self:set("idle", p, { reason = reason })
	self:finishLeak(p)
	return true
end

function Registry:external(id, what, detail)
	if not self.alive then
		return
	end
	local p = self.providers[id]
	if not p or self.activeId ~= id then
		return
	end
	if what == "running" then
		return
	end
	if what == "stopped" and self.swapping then
		return
	end
	if what == "stopped" and (self.cur == "running" or self.cur == "starting") then
		local ctl = self.ctl
		self.token = self.token + 1
		self.spawn(function()
			if self.activeId ~= id or (self.cur ~= "running" and self.cur ~= "starting") then
				return
			end
			self:set("stopping", p, { reason = detail })
			if ctl and ctl.stopScript then
				pcall(ctl.stopScript)
			end
			pcall(p.stop)
			pcall(p.reset)
			self.ctl = nil
			self:set("idle", p, { reason = detail })
			self:finishLeak(p)
			if detail then
				self:say(p.name, tostring(detail), "info", 3)
			end
		end)
	end
end

function Registry:destroy()
	self.alive = false
	local p = self.providers[self.activeId]
	if p and self.cur ~= "idle" then
		pcall(p.stop)
	end
	for _, id in ipairs(self.order) do
		local provider = self.providers[id]
		if provider then
			if type(provider.forget) == "function" then
				pcall(provider.forget)
			else
				pcall(provider.reset)
			end
		end
	end
	self.cur = "idle"
	self.activeId = nil
	self.ctl = nil
end

return Registry
