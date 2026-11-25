local Sniff = loadmodule("Hub/modules/imgsniff.lua")
local F = loadmodule("Testing/mocks/image_fixtures.lua")

local W = {}

function W.fromhex(h)
	local out = {}
	for i = 1, #h, 2 do
		out[#out + 1] = string.char(tonumber(string.sub(h, i, i + 1), 16))
	end
	return table.concat(out)
end

function W.fixture(name)
	return W.fromhex(F.valid[name].hex)
end

function W.fatPng(extra)
	local png = W.fixture("png_solid_256")
	return string.sub(png, 1, #png - 12) .. string.rep("x", extra) .. string.sub(png, #png - 11)
end

local function djb2(text)
	local h = 5381
	for i = 1, #text do
		h = (h * 33 + string.byte(text, i)) % 4294967296
	end
	return string.format("%08x", h)
end

local function parentOf(path)
	return string.match(path, "^(.*)/[^/]+$")
end

function W.new(opts)
	opts = opts or {}
	local world = {
		files = {},
		folders = {},
		requests = {},
		routes = {},
		deleted = {},
		writeCount = 0,
		failWrites = false,
		assetStatus = {},
		badExts = {},
		badStatus = "failed",
		noAssetFor = {},
		probeCalls = {},
		reads = {},
		now = 1700000000,
		clipboard = opts.clipboard,
		configText = opts.configText,
		toasts = {},
		logs = {},
		fired = {},
		has = { files = true, assets = true, list = true, request = true, clipboard = opts.clipboard ~= nil },
	}
	for key, value in pairs(opts.has or {}) do
		world.has[key] = value
	end
	local function ensureFolders(path)
		local dir = parentOf(path)
		while dir do
			world.folders[dir] = true
			dir = parentOf(dir)
		end
	end
	local fs = {
		exists = function(path)
			return world.files[path] ~= nil
		end,
		read = function(path)
			world.reads[#world.reads + 1] = path
			return world.files[path]
		end,
		write = function(path, data)
			if world.failWrites then
				return false
			end
			ensureFolders(path)
			world.files[path] = data
			world.writeCount = world.writeCount + 1
			return true
		end,
		delete = function(path)
			if world.files[path] ~= nil then
				world.files[path] = nil
				world.deleted[#world.deleted + 1] = path
			end
		end,
		isfolder = function(path)
			return world.folders[path] == true
		end,
		list = function(dir)
			if world.listBroken then
				return nil
			end
			if dir == "" or dir == "." then
				if world.rootNeedsDot and dir == "" then
					return nil
				end
				dir = nil
			end
			local seen, out = {}, {}
			local function consider(path)
				if parentOf(path) == dir or (dir == nil and parentOf(path) == nil) then
					if not seen[path] then
						seen[path] = true
						out[#out + 1] = path
					end
				end
			end
			for path in pairs(world.files) do
				consider(path)
			end
			for path in pairs(world.folders) do
				consider(path)
			end
			table.sort(out)
			if world.listBare then
				for i, path in ipairs(out) do
					out[i] = string.match(path, "([^/]+)$")
				end
			end
			return out
		end,
	}
	local function request(method, url, headers)
		world.requests[#world.requests + 1] = { method = method, url = url, headers = headers }
		local route = world.routes[method .. " " .. url] or world.routes[url]
		if type(route) == "function" then
			route = route(method, url, headers)
		end
		if not route then
			if method == "HEAD" then
				return 405, "", {}
			end
			return 0, "no route for " .. url, {}
		end
		if route.delay then
			task.wait(route.delay)
		end
		return route.code or 200, route.body or "", route.headers or {}
	end
	world.deps = {
		has = world.has,
		fs = fs,
		sniff = Sniff,
		asset = function(path)
			if world.noAssetFor[path] or not world.has.assets then
				return nil
			end
			return "rbxasset://" .. path
		end,
		request = request,
		probe = function(id, host)
			world.probeCalls[#world.probeCalls + 1] = id
			if world.probeDelay then
				task.wait(world.probeDelay)
			end
			local status = world.assetStatus[id]
			if status then
				return status
			end
			local path = string.match(id, "^rbxasset://(.*)$")
			if path then
				local ext = string.match(path, "%.(%w+)$")
				if ext and world.badExts[ext] then
					return world.badStatus
				end
			end
			return "loaded"
		end,
		json = { encode = jsonencode, decode = jsondecode },
		hash = djb2,
		spawn = task.spawn,
		delay = task.delay,
		wait = task.wait,
		time = function()
			return world.now
		end,
		clipboard = function()
			return world.clipboard
		end,
		configText = function()
			return world.configText
		end,
	}
	local Bus = { map = {} }
	function Bus.on(name, fn)
		Bus.map[name] = Bus.map[name] or {}
		table.insert(Bus.map[name], fn)
	end
	function Bus.off(name, fn)
		local list = Bus.map[name] or {}
		for i = #list, 1, -1 do
			if list[i] == fn then
				table.remove(list, i)
			end
		end
	end
	function Bus.fire(name, ...)
		if name == "scriptart" then
			world.fired[#world.fired + 1] = { ... }
		end
		for _, fn in ipairs(Bus.map[name] or {}) do
			fn(...)
		end
	end
	world.Bus = Bus
	world.ctx = {
		artDeps = world.deps,
		Bus = Bus,
		notify = function(title, text, kind, seconds)
			world.toasts[#world.toasts + 1] = { title = title, text = text, kind = kind, seconds = seconds }
		end,
		Log = {
			add = function(kind, source, message)
				world.logs[#world.logs + 1] = { kind = kind, source = source, message = message }
			end,
		},
	}
	function world.put(path, data)
		ensureFolders(path)
		world.files[path] = data
	end
	function world.folder(path)
		world.folders[path] = true
		ensureFolders(path)
	end
	function world.route(method, url, response)
		world.routes[method .. " " .. url] = response
	end
	function world.count(method, url)
		local n = 0
		for _, r in ipairs(world.requests) do
			if (method == nil or r.method == method) and (url == nil or r.url == url) then
				n = n + 1
			end
		end
		return n
	end
	function world.cacheFiles(dir)
		local out = {}
		local prefix = dir .. "/"
		for path in pairs(world.files) do
			if string.sub(path, 1, #prefix) == prefix then
				out[#out + 1] = path
			end
		end
		table.sort(out)
		return out
	end
	return world
end

return W
