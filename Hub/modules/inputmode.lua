local Module = {}

local M = { mode = "desktop", since = -100, last = nil, conns = {}, alive = false }

Module.HOLD = 2

local MOUSE_TYPES = {
	MouseButton1 = true,
	MouseButton2 = true,
	MouseButton3 = true,
	MouseMovement = true,
	MouseWheel = true,
}

function Module.classify(name)
	if name == nil then
		return nil
	end
	local n = tostring(name)
	n = string.gsub(n, "^Enum%.UserInputType%.", "")
	n = string.gsub(n, "^UserInputType%.", "")
	if n == "Touch" then
		return "touch"
	end
	if n == "Keyboard" or n == "TextInput" then
		return "keyboard"
	end
	if MOUSE_TYPES[n] then
		return "mouse"
	end
	if string.sub(n, 1, 7) == "Gamepad" then
		return "gamepad"
	end
	return nil
end

function Module.decide(facts)
	local override = facts.override
	if override == "always" then
		return "touch"
	end
	if override == "never" then
		return "desktop"
	end
	if facts.tenFoot then
		return "desktop"
	end
	if facts.gamepad and not facts.touch then
		return "desktop"
	end
	if not facts.touch then
		return "desktop"
	end
	if not facts.mouse then
		return "touch"
	end
	local last = facts.lastInput
	if last == "touch" or last == nil then
		return "touch"
	end
	return "desktop"
end

function Module.settle(state, want, now, hold, immediate)
	if state.mode == nil or immediate then
		state.mode = want
		state.since = now
		return state.mode, true
	end
	if want == state.mode then
		return state.mode, false
	end
	if now - state.since < (hold or Module.HOLD) then
		return state.mode, false
	end
	state.mode = want
	state.since = now
	return state.mode, true
end

function Module.overrideOf(setting)
	if setting == "always" then
		return "always"
	end
	if setting == "never" then
		return "never"
	end
	return "auto"
end

function Module.get()
	return M.mode or "desktop"
end

function Module.facts()
	local ctx = M.ctx
	local UIS = ctx.UserInputService
	local ten = false
	if ctx.GuiService then
		local ok, v = pcall(function()
			return ctx.GuiService:IsTenFootInterface()
		end)
		ten = ok and v == true
	end
	return {
		touch = UIS.TouchEnabled == true,
		keyboard = UIS.KeyboardEnabled == true,
		mouse = UIS.MouseEnabled == true,
		gamepad = UIS.GamepadEnabled == true,
		tenFoot = ten,
		lastInput = M.last,
		override = Module.overrideOf(ctx.S.edgeMode),
	}
end

function Module.refresh(immediate)
	if not M.alive then
		return M.mode
	end
	local ctx = M.ctx
	local facts = Module.facts()
	local want = Module.decide(facts)
	local forced = immediate or facts.override ~= "auto" or M.forceNext
	M.forceNext = false
	local mode, changed = Module.settle(M, want, os.clock(), Module.HOLD, forced)
	if changed then
		ctx.Bus.fire("inputmode", mode)
	end
	if mode ~= want then
		local wait = Module.HOLD - (os.clock() - M.since) + 0.05
		task.delay(math.max(0.05, wait), function()
			if M.alive then
				Module.refresh(false)
			end
		end)
	end
	return mode
end

function Module.init(ctx)
	if M.alive then
		Module.destroy()
	end
	M.ctx = ctx
	M.alive = true
	M.mode = nil
	M.since = -100
	M.last = nil
	M.forceNext = true
	local UIS = ctx.UserInputService
	local ok, cur = pcall(function()
		return UIS:GetLastInputType()
	end)
	if ok then
		M.last = Module.classify(cur)
	end
	M.conns[#M.conns + 1] = UIS.LastInputTypeChanged:Connect(function(t)
		local c = Module.classify(t)
		if c then
			M.last = c
			Module.refresh(false)
		end
	end)
	Module.refresh(true)
	ctx.Core.InputMode = Module
	return Module
end

function Module.destroy()
	M.alive = false
	for _, c in ipairs(M.conns) do
		pcall(function()
			c:Disconnect()
		end)
	end
	M.conns = {}
end

return Module
