local World = loadmodule("Testing/mocks/rbx_world.lua")

local Boot = {}

Boot.TAIL = "\nGENV.__TestCore = Core\nGENV.__TestHub = { Log = Log, Panel = Panel, S = S, Runner = Runner, Repo = Repo, Scripts = Scripts, UI = UI, Win = Win, Bus = Bus, Pages = Pages, Chat = Chat, SHARED = SHARED, Detail = Detail, Gui = Gui, Ed = Ed, L = L, Z = Z, Drag = Drag, Root = Root }\n"

local source = nil

function Boot.source()
	if not source then
		source = readsource("Hub/AtsukoHub.lua") .. Boot.TAIL
	end
	return source
end

function Boot.boot(opts)
	opts = opts or {}
	local env = World.install(opts)
	for path, data in pairs(opts.files or {}) do
		env.files[path] = data
	end
	if opts.before then
		opts.before(env)
	end
	stepbudget(60000000)
	local f, err = loadstring(Boot.source(), "=AtsukoHub")
	T.ok(f ~= nil, "the hub compiles: " .. tostring(err))
	if not f then
		return env
	end
	if opts.hideLoadstring then
		_G.loadstring = nil
	end
	local ok, e = pcall(f)
	env.mainOk = ok
	env.mainErr = e
	if ok then
		env.run(opts.seconds or 20)
	end
	local th = env.genv.__TestHub
	env.hub = th
	env.core = env.genv.__TestCore
	env.errors = {}
	if th and th.Log and th.Log.items then
		for _, item in ipairs(th.Log.items) do
			if item.kind == "error" then
				env.errors[#env.errors + 1] = tostring(item.src) .. ": " .. tostring(item.msg)
			end
		end
	end
	return env
end

function Boot.journal(env)
	local text = env.files["Atsuko Hub/boot.json"]
	if type(text) ~= "string" then
		return nil
	end
	return jsondecode(text)
end

function Boot.logHas(env, needle)
	local th = env.hub
	if not (th and th.Log and th.Log.items) then
		return false
	end
	for _, item in ipairs(th.Log.items) do
		if string.find(tostring(item.msg), needle, 1, true) then
			return true
		end
	end
	return false
end

return Boot
