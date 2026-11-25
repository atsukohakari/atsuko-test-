local Controller = {}

Controller.SOLO = "@solo:"
Controller.ASK_SECONDS = 4
Controller.RUN_LIMIT = 40
Controller.STOP_WAIT = 6
Controller.NATIVE_PATTERN = "^[Ss]cripts/Hat/"
Controller.FDLESS_PATTERN = "^[Ss]cripts/Hat/[Ff][Dd][Ll][Ee][Ss][Ss]/"

local function firstLine(text)
	text = tostring(text)
	return (string.match(text, "^[^\r\n]*")) or text
end

function Controller.isSolo(path)
	return type(path) == "string" and string.sub(path, 1, #Controller.SOLO) == Controller.SOLO
end

function Controller.soloId(path)
	if Controller.isSolo(path) then
		return string.sub(path, #Controller.SOLO + 1)
	end
	return nil
end

function Controller.isNative(entry)
	if type(entry) ~= "table" or type(entry.path) ~= "string" then
		return false
	end
	if entry.native == true then
		return true
	end
	if string.find(entry.path, Controller.FDLESS_PATTERN) then
		return false
	end
	return string.find(entry.path, Controller.NATIVE_PATTERN) ~= nil
end

function Controller.attach(R, d)
	local SOLO = Controller.SOLO
	d.log = d.log or function() end
	R.path = nil
	R.busy = nil
	R.asking = nil
	R.run = nil
	R.starting = nil
	R.reg = nil
	R.loadError = nil

	local function waitFor(test, limit)
		local t0 = d.now()
		while d.alive() and d.now() - t0 < limit do
			if test() then
				return true
			end
			d.wait(0.1)
		end
		return false
	end

	local function say(title, text, kind, seconds)
		d.notify(title, text, kind or "info", seconds)
	end

	local function here(path)
		return d.scriptActive(path) or d.scriptPending(path)
	end

	function R.entry(path)
		if type(path) ~= "string" or path == "" or Controller.isSolo(path) then
			return nil
		end
		return d.entryOf(path)
	end

	function R.active(path)
		if path == nil then
			return false
		end
		if Controller.isSolo(path) then
			local p = R.reg and R.reg:active()
			return p ~= nil and path == SOLO .. p.id
		end
		return d.scriptActive(path) and not d.scriptPending(path)
	end

	function R.lumen()
		local L = d.lumen()
		if type(L) == "table" and type(L.isReanimated) == "function" then
			return L
		end
		return nil
	end

	function R.on()
		local L = R.lumen()
		if not L then
			return false
		end
		local ok, on = pcall(L.isReanimated)
		return ok and on == true
	end

	function R.provider()
		return R.reg and R.reg:activeProvider() or nil
	end

	function R.current()
		local run = R.run
		if run then
			local alive
			if Controller.isSolo(run.path) then
				local p = R.reg and R.reg:activeProvider()
				alive = p ~= nil and p.id == run.id
			else
				alive = here(run.path)
			end
			if alive then
				R.path = run.path
				return run.path
			end
			R.run = nil
		end
		if R.starting then
			R.path = R.starting
			return R.starting
		end
		if R.path and here(R.path) then
			return R.path
		end
		R.path = nil
		for _, path in ipairs(d.activePaths()) do
			R.path = path
			return path
		end
		return nil
	end

	function R.name(path)
		if Controller.isSolo(path) then
			local id = Controller.soloId(path)
			local p = R.reg and R.reg:get(id)
			return p and p.name or id
		end
		local e = R.entry(path)
		if e then
			return e.name
		end
		return d.nameOf(path) or "?"
	end

	function R.select(path)
		if Controller.isSolo(path) or d.S.reanimSel == path then
			return
		end
		d.S.reanimSel = path
		d.save()
		d.fire("reanim")
	end

	function R.setRegistry(registry)
		R.reg = registry
		R.loadError = nil
		if registry then
			registry.confirm = function(text, p)
				return R.ask(text, p)
			end
		end
		d.fire("reanim")
	end

	function R.ask(text, p)
		if R.asking then
			return false
		end
		local ask = { text = tostring(text), name = p and p.name or nil, answer = nil }
		local before = R.busy
		R.asking = ask
		R.busy = "asking"
		d.fire("reanim")
		waitFor(function()
			return ask.answer ~= nil
		end, Controller.ASK_SECONDS)
		R.asking = nil
		R.busy = before
		d.fire("reanim")
		return ask.answer == true
	end

	function R.stopNow(path, keep)
		if path == nil or Controller.isSolo(path) then
			return
		end
		d.stopScript(path, keep == true)
		waitFor(function()
			return not d.scriptActive(path)
		end, Controller.STOP_WAIT)
		if keep then
			return
		end
		local registry = R.reg
		if registry == nil or registry:state() == "idle" then
			if R.on() then
				waitFor(function()
					return not R.on()
				end, 2.5)
				local L = R.lumen()
				if L and R.on() then
					pcall(L.stopreanimate)
				end
			end
		end
	end

	local function recover(registry)
		if registry then
			pcall(registry.stop, registry, "error", true)
		end
	end

	local function kindOf(e)
		if type(e) == "table" and d.kindOf then
			local ok, kind = pcall(d.kindOf, e)
			if ok and kind == "limb" then
				return "limb"
			end
		end
		return "hat"
	end

	local function forcedFor(e, kind)
		kind = kind or "hat"
		local list = type(e) == "table" and e.reanim or nil
		local registry = R.reg
		if type(list) ~= "table" or #list == 0 or not registry then
			return nil
		end
		local known = {}
		for _, slot in ipairs(registry:slots(kind)) do
			known[slot.id] = true
		end
		local picked = registry:selected(kind)
		local ids = {}
		for _, id in ipairs(list) do
			if type(id) == "string" and known[id] then
				if picked and picked.id == id then
					return nil
				end
				ids[#ids + 1] = id
			end
		end
		if #ids == 1 or (picked and #ids > 0) then
			return ids[1]
		end
		return nil
	end

	function R.needsPick(kind, e)
		local registry = R.reg
		if not registry or type(registry.mustPick) ~= "function" then
			return false
		end
		if e ~= nil and forcedFor(e, kind) ~= nil then
			return false
		end
		return registry:mustPick(kind) == true
	end

	function R.askPick(kind, after)
		if type(d.pick) == "function" then
			local ok, shown = pcall(d.pick, kind, after)
			if ok and shown ~= false then
				return true
			end
		end
		local registry = R.reg
		local text = registry and registry.PICK_TEXT and registry.PICK_TEXT[kind] or "Pick a reanimation first"
		say("Reanimation", text, "info", 4)
		return false
	end

	local function launch(kind, e, swap)
		local registry = R.reg
		local ctl = {
			alive = nil,
			limit = Controller.RUN_LIMIT,
		}
		local info = nil
		if e then
			local native = kind == "hat" and d.isNative(e) or false
			info = {
				path = e.path,
				name = e.name,
				category = e.category,
				native = native,
				fdless = kind == "hat" and d.fdlessOf and d.fdlessOf(e) or nil,
				kind = kind,
			}
			ctl.force = forcedFor(e, kind)
			if ctl.force then
				local target = registry:get(ctl.force)
				say(e.name, "This script runs on " .. (target and target.name or ctl.force), "info", 3)
			end
			ctl.alive = function()
				return d.alive() and d.scriptAlive(e.path)
			end
			ctl.run = function()
				d.runScript(e)
				waitFor(function()
					return not d.scriptPending(e.path)
				end, Controller.RUN_LIMIT)
				local err = d.scriptError(e.path)
				if err then
					return false, "the script hit an error: " .. firstLine(err)
				end
				if not d.scriptActive(e.path) then
					return false, "the script did not start"
				end
				return true
			end
			ctl.stopScript = function()
				R.stopNow(e.path)
			end
			ctl.swapOut = function()
				R.stopNow(e.path, true)
			end
		else
			ctl.alive = nil
		end
		local ok, why
		if swap then
			ok, why = registry:swap(kind, info, ctl)
		else
			ok, why = registry:start(kind, info, ctl)
		end
		if ok then
			local p = registry:activeProvider()
			R.run = { path = e and e.path or (SOLO .. (p and p.id or "")), id = p and p.id or nil }
			R.path = R.run.path
		end
		return ok, why
	end

	function R.canSwitch(e)
		local registry = R.reg
		local cur = R.current()
		if not registry or type(registry.canSwap) ~= "function" or not e or not cur or cur == e.path then
			return false
		end
		if kindOf(e) ~= "hat" then
			return false
		end
		local ok, can = pcall(registry.canSwap, registry, "hat", e, forcedFor(e, "hat"))
		return ok and can == true
	end

	local function rigSpot(mode)
		if type(d.rigSpot) == "function" then
			pcall(d.rigSpot, mode)
		end
	end

	function R.switch(e)
		if R.asking or R.busy or not e or not R.canSwitch(e) then
			return false
		end
		local from = R.current()
		rigSpot("keep")
		R.select(e.path)
		R.busy = "switching"
		R.starting = e.path
		d.fire("reanim")
		d.spawn(function()
			local called, ok, why = pcall(launch, "hat", e, true)
			if not called then
				d.log("error", "switching to " .. tostring(e.name) .. " failed: " .. firstLine(ok))
				say("Reanimation", "Couldn't switch: " .. firstLine(ok), "error", 5)
				recover(R.reg)
				ok = false
			elseif ok then
				say(e.name, "Switched from " .. (from and R.name(from) or "the last script") .. ", still reanimated", "ok", 2.5)
			elseif why == "can't switch" then
				say("Reanimation", "Couldn't switch, deanimate first", "info", 3)
			end
			if not ok then
				R.run = nil
			end
			R.starting = nil
			R.busy = nil
			d.fire("reanim")
		end)
		return true
	end

	function R.start(e)
		if R.asking or R.busy or not e then
			return
		end
		if R.canSwitch(e) then
			R.switch(e)
			return
		end
		if not R.reg then
			say("Reanimation", R.loadError and ("Couldn't load: " .. R.loadError) or "Still getting ready, try again in a moment", R.loadError and "error" or "info", 4)
			return
		end
		if d.scriptActive(e.path) or d.scriptPending(e.path) then
			say(e.name, "Already running", "info", 2)
			return
		end
		R.select(e.path)
		if R.needsPick(kindOf(e), e) then
			R.askPick(kindOf(e), function()
				R.start(e)
			end)
			return
		end
		if R.current() or R.on() then
			rigSpot("keep")
		else
			rigSpot("fresh")
		end
		R.busy = "starting"
		R.starting = e.path
		d.fire("reanim")
		d.spawn(function()
			local called, ok, why = pcall(launch, kindOf(e), e)
			if not called then
				d.log("error", "starting " .. tostring(e.name) .. " failed: " .. firstLine(ok))
				say("Reanimation", "Couldn't start: " .. firstLine(ok), "error", 5)
				recover(R.reg)
				ok = false
			end
			if not ok then
				R.run = nil
			end
			R.starting = nil
			R.busy = nil
			d.fire("reanim")
		end)
	end

	function R.startSolo(kind)
		if R.asking or R.busy then
			return
		end
		kind = kind == "limb" and "limb" or "hat"
		local registry = R.reg
		if not registry then
			say("Reanimation", R.loadError and ("Couldn't load: " .. R.loadError) or "Still getting ready, try again in a moment", R.loadError and "error" or "info", 4)
			return
		end
		if R.needsPick(kind) then
			R.askPick(kind, function()
				R.startSolo(kind)
			end)
			return
		end
		local p = registry:selected(kind)
		if not p then
			say("Reanimation", "No " .. kind .. " reanimation is available", "error", 4)
			return
		end
		local cur = R.current()
		if cur then
			say("Reanimation", "Deanimate " .. R.name(cur) .. " first", "info", 2.5)
			return
		end
		rigSpot("fresh")
		R.busy = "starting"
		R.starting = SOLO .. p.id
		d.fire("reanim")
		d.spawn(function()
			local called, ok = pcall(launch, kind, nil)
			if not called then
				d.log("error", "starting " .. p.name .. " failed: " .. firstLine(ok))
				say("Reanimation", "Couldn't start: " .. firstLine(ok), "error", 5)
				recover(R.reg)
				ok = false
			end
			if not ok then
				R.run = nil
			end
			R.starting = nil
			R.busy = nil
			d.fire("reanim")
		end)
	end

	function R.stop(reason)
		if R.asking then
			R.asking.answer = true
			return
		end
		if R.busy then
			return
		end
		local registry = R.reg
		local path = R.current()
		if not path then
			local L = R.lumen()
			if L and R.on() then
				pcall(L.stopreanimate)
			end
			rigSpot("drop")
			d.fire("reanim")
			return
		end
		R.busy = "stopping"
		d.fire("reanim")
		d.spawn(function()
			local name = R.name(path)
			local ok = true
			local called, result = pcall(function()
				if registry and registry:state() ~= "idle" then
					return registry:stop(reason or "user")
				end
				R.stopNow(path)
				return true
			end)
			if not called then
				d.log("error", "stopping " .. tostring(name) .. " failed: " .. firstLine(result))
				say(name, "Couldn't stop it: " .. firstLine(result), "error", 5)
				ok = false
			else
				ok = result and true or false
			end
			if ok then
				d.wait(0.2)
				R.path = nil
				R.run = nil
				rigSpot("drop")
				say(name, "Deanimated", "info", 2)
			end
			R.busy = nil
			d.fire("reanim")
		end)
	end

	function R.toggle(e)
		if R.asking then
			R.asking.answer = true
			return
		end
		if R.busy then
			return
		end
		local cur = R.current()
		local want = e or R.entry(d.S.reanimSel)
		if cur and want and want.path ~= cur and R.canSwitch(want) then
			R.switch(want)
			return
		end
		if cur and (e == nil or cur == e.path) then
			R.stop()
			return
		end
		e = e or R.entry(d.S.reanimSel)
		if not e then
			if cur then
				say("Main Scripts", "Deanimate " .. R.name(cur) .. " first", "info", 2.5)
				return
			end
			R.startSolo("hat")
			return
		end
		if cur then
			say("Main Scripts", "Deanimate " .. R.name(cur) .. " first", "info", 2.5)
			return
		end
		R.start(e)
	end

	function R.onEvent(payload)
		if type(payload) ~= "table" or payload.state ~= "stopped" then
			return
		end
		if payload.option ~= nil or payload.selected ~= nil then
			return
		end
		if R.busy then
			return
		end
		R.run = nil
		R.path = nil
	end

	function R.shutdown()
		local registry = R.reg
		R.reg = nil
		R.asking = nil
		if registry then
			pcall(registry.destroy, registry)
		end
	end

	return R
end

function Controller.boot(R, b)
	local Registry, err = b.loadModule("@Reanimation/providers/registry")
	if type(Registry) ~= "table" or type(Registry.new) ~= "function" then
		R.loadError = firstLine(err or "couldn't load the reanimation files")
		if b.log then
			b.log("error", "reanimation: " .. R.loadError)
		end
		return false, R.loadError
	end
	local reg = Registry.new(b.registryOptions)
	local loaded = 0
	for _, id in ipairs(Registry.IDS) do
		local mod, e = b.loadModule("@Reanimation/providers/" .. id, b.providerCtx)
		if mod then
			local ok, why = reg:register(mod)
			if ok then
				loaded = loaded + 1
			else
				reg:markFailed(id, firstLine(why))
			end
		else
			reg:markFailed(id, firstLine(e or "couldn't load it"))
		end
	end
	R.setRegistry(reg)
	return true, loaded
end

return Controller
