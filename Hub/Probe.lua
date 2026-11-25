local GENV = (getgenv and getgenv()) or _G
local OUT = "AtsukoHub_probe.txt"
local WANT = {
	"readfile", "writefile", "appendfile", "isfile", "isfolder", "listfiles", "makefolder", "delfile",
	"loadstring", "getgenv", "identifyexecutor", "hookmetamethod", "hookfunction", "getrawmetatable",
	"setreadonly", "newcclosure", "checkcaller", "getnamecallmethod", "getconnections", "getcustomasset",
	"gethui", "request", "http_request", "setclipboard", "getclipboard", "queue_on_teleport",
	"setsimulationradius", "sethiddenproperty", "gethiddenproperty", "firesignal", "Drawing",
}
local rows = {}
local t0 = os.clock()

local function save()
	if type(writefile) == "function" then
		pcall(writefile, OUT, table.concat(rows, "\n") .. "\n")
	end
end

local function note(text)
	rows[#rows + 1] = string.format("%7.2f  %s", os.clock() - t0, tostring(text))
	save()
	pcall(print, "[Atsuko probe] " .. tostring(text))
end

local function mem()
	local ok, kb = pcall(collectgarbage, "count")
	if ok and type(kb) == "number" then
		return kb
	end
	return 0
end

local function look(name)
	local ok, v = pcall(function()
		return GENV[name]
	end)
	if ok and v ~= nil then
		return v
	end
	return _G[name]
end

local function describe()
	local ok, name, ver = pcall(function()
		if type(identifyexecutor) == "function" then
			return identifyexecutor()
		end
		return nil
	end)
	note("executor: " .. tostring(ok and name or "unknown") .. " " .. tostring(ok and ver or ""))
	local have, miss = {}, {}
	for _, n in ipairs(WANT) do
		if look(n) ~= nil then
			have[#have + 1] = n
		else
			miss[#miss + 1] = n
		end
	end
	note("has: " .. table.concat(have, " "))
	note("missing: " .. (#miss > 0 and table.concat(miss, " ") or "nothing"))
	local okI, touch, keys = pcall(function()
		local u = game:GetService("UserInputService")
		return u.TouchEnabled, u.KeyboardEnabled
	end)
	if okI then
		note("device: touch=" .. tostring(touch) .. " keyboard=" .. tostring(keys))
	end
end

local function findRoot()
	local roots = {}
	if type(GENV.AtsukoLocalRoot) == "string" and GENV.AtsukoLocalRoot ~= "" then
		roots[#roots + 1] = GENV.AtsukoLocalRoot
	end
	roots[#roots + 1] = "Atsuko Hub"
	roots[#roots + 1] = "Atsuko"
	for _, r in ipairs(roots) do
		local ok, found = pcall(isfile, r .. "/Hub/AtsukoHub.lua")
		if ok and found then
			return r
		end
	end
	note("couldn't find Hub/AtsukoHub.lua inside: " .. table.concat(roots, ", "))
	return nil
end

local function checkModules(root)
	if type(listfiles) ~= "function" then
		note("this executor has no listfiles, so the modules were not checked")
		return
	end
	local ok, files = pcall(listfiles, root .. "/Hub/modules")
	if not ok or type(files) ~= "table" then
		note("couldn't list the modules folder")
		return
	end
	table.sort(files)
	local bad = 0
	for _, path in ipairs(files) do
		if string.sub(string.lower(path), -4) == ".lua" then
			note("checking " .. path)
			local okF, body = pcall(readfile, path)
			if okF and type(body) == "string" then
				local g, e = loadstring(body, "=module")
				if type(g) == "function" then
					note("ok, " .. #body .. " bytes")
				else
					bad += 1
					note("BAD: " .. tostring(e))
				end
			else
				bad += 1
				note("BAD: couldn't read it")
			end
		end
	end
	note(bad == 0 and "all modules compile" or (bad .. " module(s) did not compile"))
end

local function main()
	note("probe started")
	if type(loadstring) ~= "function" then
		note("this executor has no loadstring, the hub cannot run here")
		return
	end
	describe()
	local root = findRoot()
	if not root then
		return
	end
	note("reading " .. root .. "/Hub/AtsukoHub.lua")
	local okR, src = pcall(readfile, root .. "/Hub/AtsukoHub.lua")
	if not okR or type(src) ~= "string" then
		note("couldn't read it: " .. tostring(src))
		return
	end
	local _, breaks = string.gsub(src, "\n", "\n")
	note("read " .. #src .. " bytes, " .. (breaks + 1) .. " lines")
	local before = mem()
	note("compiling the hub, nothing runs yet")
	local f, err = loadstring(src, "=AtsukoHub")
	if type(f) ~= "function" then
		note("compile failed: " .. tostring(err))
		return
	end
	note("compiled fine, memory +" .. math.floor(mem() - before) .. " KB")
	src = nil
	checkModules(root)
	if GENV.AtsukoProbeRun ~= true then
		note("done: everything compiled and nothing was run")
		note("next: put getgenv().AtsukoProbeRun = true above the loadstring line and run this again")
		return
	end
	GENV.AtsukoSafeMode = true
	GENV.AtsukoLocalRoot = root
	note("running the hub in safe mode")
	local okRun, runErr = pcall(f)
	note(okRun and "the main part finished" or ("the hub stopped with: " .. tostring(runErr)))
	pcall(task.wait, 8)
	note("still alive 8 seconds later")
end

local okMain, mainErr = pcall(main)
if not okMain then
	note("the probe itself stopped: " .. tostring(mainErr))
end
pcall(print, "[Atsuko probe] the steps are in the file " .. OUT .. " inside your executor's workspace folder")
