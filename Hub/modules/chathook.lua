local ChatHook = {}

ChatHook.METHODS = { SendAsync = "TextChannel", FireServer = "SayMessageRequest" }

function ChatHook.matchesTarget(method, target)
	local want = ChatHook.METHODS[method]
	if not want or target == nil then
		return false
	end
	local okClass, class = pcall(function()
		return target.ClassName
	end)
	local okName, name = pcall(function()
		return target.Name
	end)
	if method == "SendAsync" then
		return okClass and class == want
	end
	return okName and name == want
end

function ChatHook.shouldSwallow(dispatch, text)
	if type(text) ~= "string" or dispatch == nil then
		return false
	end
	local ok, res = pcall(dispatch.isCommand, dispatch, text)
	return ok and res == true
end

function ChatHook.status(state)
	if state and state.active then
		return "hooked", "commands typed in chat are not sent to the room"
	end
	return "off", "your executor can't hook chat, so commands show in the room but still run"
end

function ChatHook.install(env)
	local X = env.X or {}
	local state = { active = false, removed = false }
	if not (X.hookmetamethod and X.getnamecallmethod and X.checkcaller and X.newcclosure) then
		return state
	end
	local store = env.store
	local hookState = store.__AtsukoSendHook
	if not hookState then
		hookState = { handler = nil }
		local old
		local ok = pcall(function()
			old = X.hookmetamethod(env.root, "__namecall", X.newcclosure(function(self, ...)
				local handler = hookState.handler
				if handler then
					local method = X.getnamecallmethod()
					if ChatHook.METHODS[method] then
						local swallow = false
						local okH, res = pcall(handler, self, method, ...)
						if okH and res == true then
							swallow = true
						end
						if X.setnamecallmethod then
							pcall(X.setnamecallmethod, method)
						end
						if swallow then
							return nil
						end
					end
				end
				return old(self, ...)
			end))
		end)
		if not ok then
			return state
		end
		store.__AtsukoSendHook = hookState
	end
	hookState.handler = function(self, method, text)
		if state.removed then
			return false
		end
		if not ChatHook.matchesTarget(method, self) then
			return false
		end
		local okC, mine = pcall(X.checkcaller)
		if not okC or mine then
			return false
		end
		local dispatch = env.dispatch()
		if not ChatHook.shouldSwallow(dispatch, text) then
			return false
		end
		env.defer(function()
			pcall(dispatch.handle, dispatch, text, "chat")
		end)
		return true
	end
	state.active = true
	function state.remove()
		state.removed = true
		state.active = false
		if hookState.handler then
			hookState.handler = nil
		end
	end
	return state
end

return ChatHook
