local W = {}

W.SPOTS = {
	gun = { limb = "Right Arm", pos = Vector3.new(0.5, -0.35, 0), dir = Vector3.new(0, -1, 0), up = Vector3.new(1, 0, 0), push = "up" },
	sword = { limb = "Torso", pos = Vector3.new(0, 0.15, 0.5), dir = Vector3.new(0.6, -0.8, 0), up = Vector3.new(0.8, 0.6, 0), push = "side" },
}
W.MAX_CACHE = 200

local cache = {}
local cached = 0

local function digits(value)
	if type(value) ~= "string" then
		value = value ~= nil and tostring(value) or ""
	end
	return string.match(value, "(%d+)%D*$")
end
W.digits = digits

function W.axes(size)
	local list = {
		{ Vector3.new(1, 0, 0), size.X },
		{ Vector3.new(0, 1, 0), size.Y },
		{ Vector3.new(0, 0, 1), size.Z },
	}
	table.sort(list, function(a, b)
		return a[2] > b[2]
	end)
	return list[1][1], list[2][1], list[1][2], list[2][2], list[3][2]
end

function W.place(kind, size)
	local spot = W.SPOTS[kind]
	if not spot then
		return nil
	end
	if typeof(size) ~= "Vector3" then
		size = Vector3.new(1, 1, 1)
	end
	local a1, a2, _, mid, thin = W.axes(size)
	local a3 = a1:Cross(a2)
	local dir = spot.dir.Unit
	local up = spot.up - dir * spot.up:Dot(dir)
	up = up.Unit
	local side = dir:Cross(up)
	local function col(x)
		return dir * a1:Dot(x) + up * a2:Dot(x) + side * a3:Dot(x)
	end
	local pos = spot.pos
	if spot.push == "up" then
		pos = pos + up * (mid / 2)
	elseif spot.push == "side" then
		pos = pos + side * (thin / 2)
	end
	return spot.limb, CFrame.fromMatrix(pos, col(Vector3.new(1, 0, 0)), col(Vector3.new(0, 1, 0)), col(Vector3.new(0, 0, 1)))
end

local function rowHit(row, mesh, tex)
	if type(row) ~= "table" then
		return false
	end
	if row.mesh and mesh and row.mesh == mesh then
		return true
	end
	if row.hat and (row.hat == mesh or row.hat == tex) then
		return true
	end
	return false
end

function W.kind(svc, mod, mesh, tex, name)
	local m, t = digits(mesh), digits(tex)
	local key = tostring(m) .. "|" .. tostring(t) .. "|" .. tostring(name)
	local hit = cache[key]
	if hit ~= nil then
		return hit or nil
	end
	local found = false
	if type(svc) == "table" then
		for _, kind in ipairs({ "sword", "gun", "rifle", "shotgun" }) do
			if not found then
				local ok, rows = pcall(function()
					return svc:userRows("shared", kind)
				end)
				for _, row in ipairs(ok and type(rows) == "table" and rows or {}) do
					if rowHit(row, m, t) then
						found = kind == "sword" and "sword" or "gun"
						break
					end
				end
			end
		end
		if not found and type(svc.detect) == "function" then
			local ok, guess = pcall(svc.detect, svc, { mesh = m, tex = t, name = name })
			if ok and (guess == "gun" or guess == "sword") then
				found = guess
			end
		end
	end
	if not found and type(mod) == "table" and type(mod.kindFromName) == "function" then
		local ok, guess = pcall(mod.kindFromName, name)
		if ok and (guess == "gun" or guess == "sword") then
			found = guess
		end
	end
	if cached < W.MAX_CACHE then
		cache[key] = found
		cached += 1
	end
	return found or nil
end

function W.forget()
	table.clear(cache)
	cached = 0
end

function W.pick(list, kindOf)
	local out = {}
	for _, item in ipairs(type(list) == "table" and list or {}) do
		local k = kindOf(item)
		if (k == "gun" or k == "sword") and not out[k] then
			out[k] = item
		end
		if out.gun and out.sword then
			break
		end
	end
	return out
end

return W
