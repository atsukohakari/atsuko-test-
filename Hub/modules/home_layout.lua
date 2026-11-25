local Layout = {}

Layout.DENSITY = {
	comfortable = {
		name = "comfortable",
		corner = 20,
		pad = 14,
		inner = 12,
		header = 36,
		title = 12,
		small = 11,
		body = 12,
		big = 20,
		stat = 34,
		pill = 42,
		chip = 44,
		row = 44,
		tile = 60,
		banner = 56,
		update = 56,
		avatar = 64,
		face = 30,
		gap = 10,
	},
	compact = {
		name = "compact",
		corner = 17,
		pad = 10,
		inner = 8,
		header = 30,
		title = 11,
		small = 10,
		body = 11,
		big = 18,
		stat = 28,
		pill = 36,
		chip = 38,
		row = 36,
		tile = 50,
		banner = 46,
		update = 48,
		avatar = 52,
		face = 26,
		gap = 7,
	},
}

Layout.COLLAPSE_TIME = 0.22
Layout.ENTER_TIME = 0.28
Layout.ENTER_RISE = 14
Layout.FRIENDS_TTL = 30

function Layout.density(name)
	if name == "compact" then
		return Layout.DENSITY.compact
	end
	return Layout.DENSITY.comfortable
end

function Layout.densityName(name)
	if name == "compact" then
		return "compact"
	end
	return "comfortable"
end

function Layout.stageWidths(w, mode)
	w = tonumber(w) or 0
	if w < 610 then
		return w, 0
	end
	local over = w - 610
	if mode == "window" then
		local a = math.min(400, 300 + math.floor(over * 100 / 390))
		local b = math.min(340, 270 + math.floor(over * 70 / 390))
		return a, b
	end
	local a = math.min(390, 300 + math.floor(over * 90 / 390))
	local b
	if w <= 1000 then
		b = 270 + math.floor(over * 60 / 390)
	else
		b = math.min(340, 330 + math.floor((w - 1000) * 10 / 920))
	end
	return a, b
end

function Layout.cellWidth(inner, cols, gap)
	if cols <= 1 then
		return inner
	end
	return math.floor((inner - gap * (cols - 1)) / cols)
end

function Layout.metrics(w, d)
	local inner = w - d.pad * 2
	return {
		inner = inner,
		tileCols = inner >= 400 and 4 or 2,
		chipCols = inner >= 240 and 2 or 1,
		faces = math.min(8, math.max(1, math.floor((inner + d.gap) / (d.face + d.gap)))),
	}
end

function Layout.faceOffset(i, d)
	return (i - 1) * (d.face + d.gap)
end

function Layout.greeting(hour)
	hour = tonumber(hour) or 12
	if hour >= 0 and hour <= 4 then
		return "Still up? Don't stay up too late"
	end
	if hour >= 5 and hour <= 11 then
		return "Good morning, have a lovely day"
	end
	if hour >= 12 and hour <= 17 then
		return "Good afternoon, what are we playing?"
	end
	if hour >= 18 and hour <= 21 then
		return "Good evening, enjoy your games"
	end
	return "It's getting late, play safe"
end

local PREFIXES = { '^%[string ".-"%]:%d+:%s*', "^[^:]+:%d+:%s*" }

function Layout.failReason(msg)
	local text = tostring(msg == nil and "" or msg)
	text = string.match(text, "^[^\r\n]*") or ""
	text = string.gsub(text, "%s+", " ")
	text = string.match(text, "^%s*(.-)%s*$") or ""
	for _ = 1, 3 do
		local cut = nil
		for _, pattern in ipairs(PREFIXES) do
			local s, e = string.find(text, pattern)
			if s then
				cut = e
				break
			end
		end
		if not cut then
			break
		end
		text = string.sub(text, cut + 1)
	end
	text = string.match(text, "^%s*(.-)%s*$") or ""
	if text == "" then
		return "unknown error"
	end
	text = string.gsub(text, "[\128-\255]", "?")
	if #text > 60 then
		text = string.sub(text, 1, 57) .. "..."
	end
	return text
end

function Layout.failText(err)
	return "this card failed: " .. Layout.failReason(err)
end

function Layout.friendsLine(total, here)
	if total == 0 then
		return "None of your friends are online"
	end
	if here == 0 then
		return "None of them are in this game"
	end
	if here == 1 then
		return "1 of them is in this game"
	end
	return here .. " of them are in this game"
end

function Layout.friendsDue(now, last, ttl)
	ttl = ttl or Layout.FRIENDS_TTL
	return now - last >= ttl
end

function Layout.recentSignature(paths, fn)
	local parts = {}
	for _, p in ipairs(paths) do
		parts[#parts + 1] = p .. ":" .. fn(p)
	end
	return table.concat(parts, "|")
end

function Layout.uptimeText(secs)
	secs = tonumber(secs) or 0
	if secs ~= secs or secs < 0 then
		secs = 0
	end
	secs = math.floor(secs)
	local h = math.floor(secs / 3600)
	local m = math.floor((secs % 3600) / 60)
	local s = secs % 60
	if h > 0 then
		return h .. "h " .. m .. "m " .. s .. "s"
	end
	if m > 0 then
		return m .. "m " .. s .. "s"
	end
	return s .. "s"
end

function Layout.playersText(count, max)
	count = tonumber(count) or 0
	if type(max) == "number" and max > 0 then
		return count .. "/" .. max
	end
	return tostring(count)
end

function Layout.pingText(ms)
	if type(ms) ~= "number" or ms ~= ms or ms < 0 or ms == math.huge then
		return "-"
	end
	return math.floor(ms + 0.5) .. "ms"
end

function Layout.stagger(i)
	i = tonumber(i) or 0
	if i <= 1 then
		return 0
	end
	if i >= 13 then
		return 0.48
	end
	return (i - 1) * 0.04
end

function Layout.sanitizeCollapsed(t)
	if type(t) ~= "table" then
		return {}
	end
	local out, n = {}, 0
	for k, v in pairs(t) do
		if type(k) == "string" and v == true then
			if n >= 60 then
				break
			end
			out[k] = true
			n += 1
		end
	end
	return out
end

local COLS = { A = true, B = true }

function Layout.normalizeConfig(saved, defs, order, kinds)
	local out = {}
	local seen = {}
	if type(saved) ~= "table" then
		saved = {}
	end
	for _, e in ipairs(saved) do
		if type(e) == "table" and type(e.id) == "string" and not seen[e.id] then
			local def = defs[e.id]
			if def then
				seen[e.id] = true
				out[#out + 1] = { id = e.id, col = COLS[e.col] and e.col or def.col, hidden = e.hidden == true }
			elseif type(e.kind) == "string" and kinds[e.kind] and type(e.data) == "table" then
				seen[e.id] = true
				out[#out + 1] = { id = e.id, kind = e.kind, col = COLS[e.col] and e.col or "A", hidden = e.hidden == true or nil, data = e.data }
			end
		end
	end
	for _, id in ipairs(order or {}) do
		local def = defs[id]
		if def and not seen[id] then
			seen[id] = true
			out[#out + 1] = { id = id, col = def.col, hidden = false }
		end
	end
	return out
end

function Layout.plan(stageW, items, opts)
	opts = opts or {}
	local narrow
	if opts.narrow ~= nil then
		narrow = opts.narrow == true
	else
		narrow = stageW < 610
	end
	local columns = { {}, {} }
	local hidden, order = {}, {}
	for _, e in ipairs(items or {}) do
		if e.hidden then
			hidden[#hidden + 1] = e.id
		else
			order[#order + 1] = e.id
			if narrow or e.col ~= "B" then
				table.insert(columns[1], e.id)
			else
				table.insert(columns[2], e.id)
			end
		end
	end
	local a, b
	if narrow then
		a, b = stageW, 0
	else
		a, b = Layout.stageWidths(stageW, opts.mode or "original")
		a = opts.leftW or a
		b = opts.rightW or b
	end
	return {
		columns = columns,
		hidden = hidden,
		order = order,
		narrow = narrow,
		widths = { a = a, b = b },
		side = not narrow and #columns[2] > 0,
	}
end

return Layout
