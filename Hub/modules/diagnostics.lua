local Mod = {}

Mod.MAX_ERRORS = 14
Mod.MAX_LINE = 240
Mod.CHECKED = { "writefile", "readfile", "isfile", "isfolder", "makefolder", "listfiles", "getcustomasset", "request", "setclipboard", "loadstring", "hookmetamethod", "getconnections", "gethui", "queueteleport", "identifyexecutor" }

local function cut(value, limit)
	local text = string.gsub(tostring(value == nil and "" or value), "[\r\n]+", " ")
	if #text > limit then
		return string.sub(text, 1, limit - 3) .. "..."
	end
	return text
end

local function sorted(list)
	local out = {}
	for _, v in ipairs(list or {}) do
		out[#out + 1] = tostring(v)
	end
	table.sort(out)
	return out
end

local function join(list, empty)
	if #list == 0 then
		return empty or "none"
	end
	return table.concat(list, ", ")
end

local function keysOf(map)
	local out = {}
	for k, v in pairs(map or {}) do
		if v then
			out[#out + 1] = tostring(k)
		end
	end
	table.sort(out)
	return out
end

function Mod.deviceText(device)
	device = type(device) == "table" and device or {}
	local parts = {}
	if device.touch then
		parts[#parts + 1] = "touch"
	end
	if device.keyboard then
		parts[#parts + 1] = "keyboard"
	end
	if device.gamepad then
		parts[#parts + 1] = "gamepad"
	end
	return join(parts, "unknown")
end

function Mod.missing(have)
	local out = {}
	for _, key in ipairs(Mod.CHECKED) do
		if not (type(have) == "table" and have[key]) then
			out[#out + 1] = key
		end
	end
	return out
end

function Mod.build(facts)
	facts = type(facts) == "table" and facts or {}
	local out = { "Atsuko Hub diagnostics" }
	local function add(label, value)
		out[#out + 1] = label .. ": " .. cut(value, Mod.MAX_LINE)
	end
	add("Version", facts.version or "?")
	add("Started from", facts.origin or "github")
	add("Executor", facts.executor or "unknown")
	add("Place", facts.placeId or "?")
	add("Device", Mod.deviceText(facts.device))
	add("Screen", facts.screen or "?")

	local boot = type(facts.boot) == "table" and facts.boot or {}
	add("Safe mode", boot.safe and ("on, the last start stopped at " .. tostring(boot.step or "?")) or "off")
	add("Turned off after a crash", join(sorted(boot.flipped)))

	local hooks = type(facts.hooks) == "table" and facts.hooks or {}
	add("Hooks switched on", join(keysOf(hooks)))

	local packs = type(facts.packs) == "table" and facts.packs or {}
	if packs.skipped then
		add("Command packs", "left out (safe mode)")
	else
		add("Command packs", join(sorted(packs.loaded), "none") .. "  (" .. tostring(packs.built or 0) .. " commands built)")
	end
	local failed = {}
	for name, why in pairs(packs.failed or {}) do
		failed[#failed + 1] = tostring(name) .. " (" .. cut(why, 80) .. ")"
	end
	table.sort(failed)
	add("Command packs that did not load", join(failed))

	local commands = type(facts.commands) == "table" and facts.commands or {}
	add("Commands", tostring(commands.total or 0) .. " in the list, " .. tostring(commands.conflicts or 0) .. " name clashes")
	add("Commands switched on", join(sorted(commands.active)))

	local modules = type(facts.modules) == "table" and facts.modules or {}
	add("Modules loaded", join(sorted(modules.ok)))
	local badModules = {}
	for name, why in pairs(modules.failed or {}) do
		badModules[#badModules + 1] = tostring(name) .. " (" .. cut(why, 80) .. ")"
	end
	table.sort(badModules)
	add("Modules that failed", join(badModules))

	add("Executor functions missing", join(Mod.missing(facts.have)))
	add("Last name badge", facts.badge or "none drawn yet")

	out[#out + 1] = "Recent problems, newest first:"
	local errors = type(facts.errors) == "table" and facts.errors or {}
	if #errors == 0 then
		out[#out + 1] = "  none"
	end
	for i = 1, math.min(#errors, Mod.MAX_ERRORS) do
		out[#out + 1] = "  " .. cut(errors[i], Mod.MAX_LINE)
	end
	return table.concat(out, "\n")
end

return Mod
