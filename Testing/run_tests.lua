local state = { passed = 0, failed = 0, section = "start", lines = {} }

T = {}

local function show(v, depth)
	depth = depth or 0
	if type(v) == "string" then
		return string.format("%q", v)
	end
	if type(v) ~= "table" then
		return tostring(v)
	end
	if depth > 3 then
		return "{...}"
	end
	local keys = {}
	for k in pairs(v) do
		keys[#keys + 1] = k
	end
	table.sort(keys, function(a, b)
		return tostring(a) < tostring(b)
	end)
	local parts = {}
	for _, k in ipairs(keys) do
		parts[#parts + 1] = tostring(k) .. "=" .. show(v[k], depth + 1)
	end
	return "{" .. table.concat(parts, ", ") .. "}"
end

local function same(a, b)
	if type(a) ~= type(b) then
		return false
	end
	if type(a) ~= "table" then
		return a == b
	end
	for k, v in pairs(a) do
		if not same(v, b[k]) then
			return false
		end
	end
	for k in pairs(b) do
		if a[k] == nil then
			return false
		end
	end
	return true
end

local function record(ok, msg, detail)
	if ok then
		state.passed = state.passed + 1
	else
		state.failed = state.failed + 1
		state.lines[#state.lines + 1] = "  FAIL [" .. state.section .. "] " .. tostring(msg or "") .. (detail and (" :: " .. detail) or "")
	end
end

function T.section(name)
	state.section = name
end

function T.ok(cond, msg)
	record(cond and true or false, msg)
end

function T.eq(got, want, msg)
	record(got == want, msg, "got " .. show(got) .. ", want " .. show(want))
end

function T.same(got, want, msg)
	record(same(got, want), msg, "got " .. show(got) .. ", want " .. show(want))
end

function T.fails(f, msg, ...)
	local ok, err = pcall(f, ...)
	record(not ok, msg, "expected an error but it returned")
	return err
end

function T.near(got, want, eps, msg)
	record(type(got) == "number" and math.abs(got - want) <= (eps or 1e-6), msg, "got " .. show(got) .. ", want " .. show(want))
end

function T.count()
	return state.passed, state.failed
end

function __summary()
	for _, l in ipairs(state.lines) do
		print(l)
	end
	print(string.format("  %d passed, %d failed", state.passed, state.failed))
	return state.failed
end
