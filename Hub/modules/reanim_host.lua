local Host = {}

Host.CONTROLLER = "reanim"
Host.SOURCE = "Reanimation"

local function firstLine(text)
	text = tostring(text)
	return (string.match(text, "^[^\r\n]*")) or text
end

local function recordOf(c, path)
	if type(path) ~= "string" then
		return nil
	end
	return c.SHARED.running[path]
end

function Host.world(c)
	local world = {}
	local function character()
		return c.LP and c.LP.Character or nil
	end
	local function service()
		return c.workspace or workspace
	end
	function world.character()
		return character()
	end
	function world.workspace()
		return service()
	end
	function world.isR15()
		local char = character()
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		return hum ~= nil and hum.RigType == Enum.HumanoidRigType.R15
	end
	function world.hasAccessory(name)
		local char = character()
		if not char then
			return false
		end
		for _, item in ipairs(char:GetChildren()) do
			if item:IsA("Accessory") and item.Name == name then
				return true
			end
		end
		return false
	end
	function world.restoreCamera()
		local cam = service().CurrentCamera
		local char = character()
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if cam and hum then
			cam.CameraSubject = hum
		end
	end
	function world.respawn()
		return c.Runner.respawn()
	end
	return world
end

function Host.providerCtx(c)
	local X = c.X or {}
	return {
		G = c.GENV,
		RG = c.RG or _G,
		genv = c.GENV,
		X = X,
		now = os.clock,
		wait = task.wait,
		spawn = task.spawn,
		delay = task.delay,
		notify = c.notify,
		vec3 = Vector3.new,
		world = Host.world(c),
		loadstring = function(source, name)
			if not X.loadstring then
				return nil, "your executor has no loadstring"
			end
			return X.loadstring(source, name)
		end,
		loadFile = function(rel)
			return c.Core.fileSource(rel)
		end,
		loadLib = function(name, key, need)
			return c.Core.loadLib(name, key, need)
		end,
	}
end

function Host.deps(c, Controller)
	local Runner = c.Runner
	local Repo = c.Repo
	local deps = {
		S = c.S,
		save = c.saveSettings,
		notify = c.notify,
		wait = task.wait,
		now = os.clock,
		spawn = task.spawn,
		lumen = function()
			return c.GENV.LumenReanim
		end,
		isNative = Controller.isNative,
	}
	function deps.rigSpot(mode)
		if mode == "drop" then
			Host.restoreWorld(Host.snap)
			Host.snap = nil
		elseif mode == "fresh" then
			Host.snap = Host.snapWorld()
			return
		end
		local g = c.GENV
		if type(g) ~= "table" then
			return
		end
		local t = g.AtsukoRigAt
		if type(t) ~= "table" then
			t = {}
			g.AtsukoRigAt = t
		end
		if mode == "keep" then
			t.keep = os.clock()
		else
			t.keep = nil
			t.t = 0
		end
	end
	function deps.pick(kind, after)
		local ask = c.Core.askReanim
		if type(ask) ~= "function" then
			return false
		end
		return ask(kind, after)
	end
	function deps.kindOf(entry)
		local kind = c.Core.entryKind(entry)
		return kind
	end
	function deps.fire(name, payload)
		c.Bus.fire(name, payload)
	end
	function deps.alive()
		return c.HUB.alive == true
	end
	function deps.log(kind, text)
		c.Log.add(kind, Host.SOURCE, text)
	end
	function deps.entryOf(path)
		if type(path) ~= "string" then
			return nil
		end
		return Repo.byPath[path] or Repo.remote[path]
	end
	function deps.nameOf(path)
		local rec = recordOf(c, path)
		return rec and rec.name or nil
	end
	function deps.scriptActive(path)
		return Runner.isActive(recordOf(c, path)) == true
	end
	function deps.scriptPending(path)
		return Runner.pending[path] ~= nil
	end
	function deps.scriptAlive(path)
		local rec = recordOf(c, path)
		return Runner.isActive(rec) == true and rec.status ~= "error"
	end
	function deps.scriptError(path)
		local failed = Runner.failed and Runner.failed[path]
		if failed then
			return failed
		end
		local rec = recordOf(c, path)
		if rec and rec.status == "error" then
			return rec.err or "the script reported an error"
		end
		return nil
	end
	function deps.runScript(entry)
		Runner.run(entry)
	end
	function deps.stopScript(path, keep)
		Runner.stop(path, true, keep == true)
	end
	function deps.activePaths()
		local list = {}
		for path, rec in pairs(c.SHARED.running) do
			if Repo.byPath[path] and Runner.isActive(rec) then
				list[#list + 1] = path
			end
		end
		table.sort(list)
		return list
	end
	return deps
end

Host.WORLD = {
	{ "camera", "FieldOfView" },
	{ "camera", "CameraType" },
	{ "input", "MouseIconEnabled" },
	{ "input", "MouseBehavior" },
	{ "world", "Gravity" },
}

function Host.places()
	local out = {}
	pcall(function()
		out.camera = workspace.CurrentCamera
	end)
	pcall(function()
		out.input = game:GetService("UserInputService")
	end)
	out.world = workspace
	return out
end

function Host.snapWorld(places)
	places = places or Host.places()
	local snap = {}
	for _, item in ipairs(Host.WORLD) do
		local obj = places[item[1]]
		if obj then
			local ok, v = pcall(function()
				return obj[item[2]]
			end)
			if ok and v ~= nil then
				snap[#snap + 1] = { obj = obj, key = item[2], value = v }
			end
		end
	end
	return snap
end

function Host.restoreWorld(snap)
	local changed = 0
	for _, s in ipairs(type(snap) == "table" and snap or {}) do
		local ok, now = pcall(function()
			return s.obj[s.key]
		end)
		if ok and now ~= s.value then
			if pcall(function()
				s.obj[s.key] = s.value
			end) then
				changed += 1
			end
		end
	end
	return changed
end

function Host.registryOptions(c)
	return {
		S = c.S,
		save = c.saveSettings,
		X = c.X,
		notify = c.notify,
		wait = task.wait,
		spawn = task.spawn,
		delay = task.delay,
		now = os.clock,
		log = function(kind, text)
			c.Log.add(kind, Host.SOURCE, text)
		end,
		fire = function(name, payload)
			c.Bus.fire(name, payload)
		end,
	}
end

function Host.install(c, R)
	local Controller, err = c.Core.loadModule(Host.CONTROLLER)
	if type(Controller) ~= "table" or type(Controller.attach) ~= "function" or type(Controller.boot) ~= "function" then
		R.loadError = firstLine(err or "couldn't load the reanimation controller")
		return false, R.loadError
	end
	local saved = {}
	for key, value in pairs(R) do
		saved[key] = value
	end
	Controller.attach(R, Host.deps(c, Controller))
	local listener = function(payload)
		if type(payload) == "table" then
			R.onEvent(payload)
		end
	end
	c.Bus.on("reanim", listener)
	R.hostListener = listener
	local called, ok, why = pcall(Controller.boot, R, {
		loadModule = function(name, context)
			return c.Core.loadModule(name, nil, context)
		end,
		registryOptions = Host.registryOptions(c),
		providerCtx = Host.providerCtx(c),
		log = function(kind, text)
			c.Log.add(kind, Host.SOURCE, text)
		end,
	})
	if called and ok then
		return true, why
	end
	local reason = firstLine(called and why or ok)
	c.Bus.off("reanim", listener)
	for key in pairs(R) do
		R[key] = nil
	end
	for key, value in pairs(saved) do
		R[key] = value
	end
	R.loadError = reason
	return false, reason
end

function Host.uninstall(c, R)
	if R.hostListener then
		c.Bus.off("reanim", R.hostListener)
		R.hostListener = nil
	end
	if type(R.shutdown) == "function" then
		pcall(R.shutdown)
	end
end

return Host
