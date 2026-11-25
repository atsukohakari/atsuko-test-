local Mod = {}

local KINDS = { hat = true, limb = true }
local MAX_ENTRIES = 600
local MAX_BODY = 400000

local function clean(value, limit)
	if type(value) ~= "string" then
		return nil
	end
	value = string.gsub(value, "%c", " ")
	value = string.match(value, "^%s*(.-)%s*$")
	if value == "" then
		return nil
	end
	if #value > limit then
		value = string.sub(value, 1, limit)
	end
	return value
end

local function strings(value, count, limit)
	if type(value) == "string" then
		value = { value }
	end
	if type(value) ~= "table" then
		return nil
	end
	local out = {}
	for _, item in ipairs(value) do
		local text = clean(item, limit)
		if text then
			out[#out + 1] = text
			if #out >= count then
				break
			end
		end
	end
	if #out == 0 then
		return nil
	end
	return out
end

local function safePath(path)
	if type(path) ~= "string" or #path == 0 or #path > 200 then
		return false
	end
	if string.find(path, "^/") or string.find(path, "%.%.") or string.find(path, "[%c\\]") then
		return false
	end
	return string.find(path, "%.[%w]+$") ~= nil
end

function Mod.item(raw)
	if type(raw) ~= "table" then
		return nil
	end
	local item = {
		name = clean(raw.name, 60),
		kind = KINDS[raw.kind] and raw.kind or nil,
		reanim = strings(raw.reanim, 8, 24),
		needsfd = raw.needsfd == true or nil,
		credit = strings(raw.credit, 8, 60),
		desc = clean(raw.desc, 400),
	}
	if next(item) == nil then
		return nil
	end
	return item
end

function Mod.parse(body, decode)
	if type(body) ~= "string" or #body == 0 or #body > MAX_BODY then
		return nil, "the manifest is missing or too big"
	end
	local readable, data = pcall(decode, body)
	if not readable then
		return nil, "the manifest could not be read"
	end
	if type(data) ~= "table" or type(data.scripts) ~= "table" then
		return nil, "the manifest has no scripts table"
	end
	local out, count = {}, 0
	for path, raw in pairs(data.scripts) do
		if safePath(path) then
			local item = Mod.item(raw)
			if item then
				if count >= MAX_ENTRIES then
					break
				end
				out[path] = item
				count += 1
			end
		end
	end
	return out, count
end

function Mod.apply(entries, scripts)
	if type(entries) ~= "table" or type(scripts) ~= "table" then
		return 0
	end
	local changed = 0
	for _, entry in ipairs(entries) do
		local item = scripts[entry.path]
		if item then
			if item.name then
				entry.name = item.name
			end
			entry.kind = item.kind
			entry.reanim = item.reanim
			entry.needsfd = item.needsfd
			entry.credit = item.credit
			changed += 1
		end
	end
	return changed
end

function Mod.merge(meta, item)
	if type(meta) ~= "table" or type(item) ~= "table" then
		return meta
	end
	if meta.name == nil then
		meta.name = item.name
	end
	if meta.kind == nil then
		meta.kind = item.kind
	end
	if meta.needsfd == nil then
		meta.needsfd = item.needsfd
	end
	if meta.reanim == nil and item.reanim then
		meta.reanim = table.concat(item.reanim, ", ")
	end
	if (meta.author == nil or meta.author == "") and item.credit then
		meta.author = table.concat(item.credit, ", ")
	end
	if (meta.credit == nil or meta.credit == "") and item.credit then
		meta.credit = table.concat(item.credit, ", ")
	end
	if (meta.desc == nil or meta.desc == "") and item.desc then
		meta.about = item.desc
	end
	return meta
end

return Mod
