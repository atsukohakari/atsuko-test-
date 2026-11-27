local Router = {}
Router.__index = Router

Router.RING = 50
Router.GUARD_TITLE = "FDLESS"
Router.GUARD_PREFIX = "Using FDless loaded by previously executed scripts"
Router.KEY = "SendNotification"

function Router.new(opts)
	opts = opts or {}
	local self = setmetatable({}, Router)
	self.now = opts.now or os.clock
	self.toast = opts.toast or function() end
	self.duration = opts.duration
	self.buttons = opts.buttons
	self.ring = {}
	self.armedUntil = -1e9
	self.general = opts.general == true
	return self
end

function Router:arm(seconds)
	self.armedUntil = self.now() + (tonumber(seconds) or 20)
end

function Router:disarm()
	self.armedUntil = -1e9
end

function Router:armed()
	return self.now() < self.armedUntil
end

function Router:setGeneral(on)
	self.general = on == true
end

function Router:record(title)
	local ring = self.ring
	ring[#ring + 1] = { title = tostring(title or ""), at = self.now() }
	while #ring > Router.RING do
		table.remove(ring, 1)
	end
end

function Router:seen()
	local out = {}
	for i, e in ipairs(self.ring) do
		out[i] = { title = e.title, at = e.at }
	end
	return out
end

function Router:clearSeen()
	self.ring = {}
end

function Router:classify(title, text)
	title = tostring(title or "")
	text = tostring(text or "")
	if self:armed() and title == Router.GUARD_TITLE and string.sub(text, 1, #Router.GUARD_PREFIX) == Router.GUARD_PREFIX then
		return "swallow"
	end
	if self.general then
		return "toast"
	end
	return "pass"
end

function Router:handle(key, value)
	if key ~= Router.KEY or type(value) ~= "table" then
		return "pass"
	end
	local okT, title = pcall(function()
		return value.Title
	end)
	local okX, text = pcall(function()
		return value.Text
	end)
	local okD, dur = pcall(function()
		return value.Duration
	end)
	title = okT and title or ""
	text = okX and text or ""
	self:record(title)
	local verdict = self:classify(title, text)
	if verdict == "toast" then
		local seconds = tonumber(okD and dur or nil)
		local list = self:buttonsOf(value)
		if list then
			local okB, can = pcall(function()
				return type(self.buttons) == "function" and self.buttons() == true
			end)
			if not (okB and can) then
				return "pass"
			end
			pcall(self.toast, tostring(title), tostring(text), "info", seconds, { buttons = list })
			return "swallow"
		end
		pcall(self.toast, tostring(title), tostring(text), "info", seconds)
		return "swallow"
	end
	if verdict == "pass" then
		self:retime(value)
	end
	return verdict
end

function Router:buttonsOf(value)
	local ok, b1, b2, cb = pcall(function()
		return value.Button1, value.Button2, value.Callback
	end)
	if not ok then
		return nil
	end
	local list = {}
	for _, label in ipairs({ b1 or false, b2 or false }) do
		if label ~= false and tostring(label) ~= "" then
			local text = tostring(label)
			list[#list + 1] = {
				text = text,
				fn = function()
					if cb ~= nil then
						pcall(function()
							cb:Invoke(text)
						end)
					end
				end,
			}
		end
	end
	if #list == 0 then
		return nil
	end
	return list
end

function Router:retime(value)
	if type(self.duration) ~= "function" then
		return false
	end
	local okW, waits = pcall(function()
		return value.Button1 ~= nil or value.Button2 ~= nil or value.Callback ~= nil
	end)
	if not okW or waits then
		return false
	end
	local okS, secs = pcall(self.duration)
	secs = okS and tonumber(secs) or nil
	if not secs or secs ~= secs or secs <= 0 then
		return false
	end
	return (pcall(function()
		value.Duration = secs
	end))
end

function Router.install(env, router)
	local X = env.X or {}
	local state = { active = false, mode = "off", removed = false }
	local store = env.store
	local hookState = store.__AtsukoNoticeHook
	local function attach(hs)
		hs.handler = function(self, key, value)
			if state.removed then
				return "pass"
			end
			local okC, class = pcall(function()
				return self.ClassName
			end)
			if not okC or class ~= "StarterGui" then
				return "pass"
			end
			return router:handle(key, value)
		end
	end
	if hookState then
		attach(hookState)
		state.active = true
		state.mode = hookState.mode
	elseif X.hookmetamethod and X.getnamecallmethod and X.newcclosure then
		hookState = { handler = nil, mode = "namecall" }
		local old
		local ok = pcall(function()
			old = X.hookmetamethod(env.root, "__namecall", X.newcclosure(function(self, ...)
				local handler = hookState.handler
				if handler then
					local method = X.getnamecallmethod()
					if method == "SetCore" then
						local verdict = "pass"
						local okH, res = pcall(handler, self, ...)
						if okH and res then
							verdict = res
						end
						if X.setnamecallmethod then
							pcall(X.setnamecallmethod, method)
						end
						if verdict == "swallow" then
							return nil
						end
					end
				end
				return old(self, ...)
			end))
		end)
		if ok then
			store.__AtsukoNoticeHook = hookState
			attach(hookState)
			state.active = true
			state.mode = "namecall"
		end
	elseif X.hookfunction and X.newcclosure and env.setCore then
		hookState = { handler = nil, mode = "function" }
		local old
		local ok = pcall(function()
			old = X.hookfunction(env.setCore, X.newcclosure(function(self, key, value, ...)
				local handler = hookState.handler
				if handler then
					local okH, res = pcall(handler, self, key, value)
					if okH and res == "swallow" then
						return nil
					end
				end
				return old(self, key, value, ...)
			end))
		end)
		if ok then
			store.__AtsukoNoticeHook = hookState
			attach(hookState)
			state.active = true
			state.mode = "function"
		end
	end
	function state.remove()
		state.removed = true
		state.active = false
		if hookState and hookState.handler then
			hookState.handler = nil
		end
	end
	return state
end

return Router
