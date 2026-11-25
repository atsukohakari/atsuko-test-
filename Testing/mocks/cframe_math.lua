local Lib = {}

function Lib.make(V3)
	local CF = { __rbxtype = "CFrame" }
	local api = {}

	local function raw(px, py, pz, a, b, c, d, e, f, g, h, i)
		return setmetatable({ px, py, pz, a, b, c, d, e, f, g, h, i }, CF)
	end

	local function vec(x, y, z)
		return V3.new(x, y, z)
	end

	local function acos(x)
		x = math.max(-1, math.min(1, x))
		return math.atan2(math.sqrt(1 - x * x), x)
	end

	local function asin(x)
		x = math.max(-1, math.min(1, x))
		return math.atan2(x, math.sqrt(1 - x * x))
	end

	local function rot(t)
		return t[4], t[5], t[6], t[7], t[8], t[9], t[10], t[11], t[12]
	end

	local function mulRot(a, b)
		local a1, a2, a3, a4, a5, a6, a7, a8, a9 = rot(a)
		local b1, b2, b3, b4, b5, b6, b7, b8, b9 = rot(b)
		return a1 * b1 + a2 * b4 + a3 * b7, a1 * b2 + a2 * b5 + a3 * b8, a1 * b3 + a2 * b6 + a3 * b9,
			a4 * b1 + a5 * b4 + a6 * b7, a4 * b2 + a5 * b5 + a6 * b8, a4 * b3 + a5 * b6 + a6 * b9,
			a7 * b1 + a8 * b4 + a9 * b7, a7 * b2 + a8 * b5 + a9 * b8, a7 * b3 + a8 * b6 + a9 * b9
	end

	local function applyRot(t, x, y, z)
		return t[4] * x + t[5] * y + t[6] * z, t[7] * x + t[8] * y + t[9] * z, t[10] * x + t[11] * y + t[12] * z
	end

	local function applyRotT(t, x, y, z)
		return t[4] * x + t[7] * y + t[10] * z, t[5] * x + t[8] * y + t[11] * z, t[6] * x + t[9] * y + t[12] * z
	end

	local function inverse(t)
		local x, y, z = applyRotT(t, t[1], t[2], t[3])
		return raw(-x, -y, -z, t[4], t[7], t[10], t[5], t[8], t[11], t[6], t[9], t[12])
	end

	local function toQuat(t)
		local m00, m01, m02, m10, m11, m12, m20, m21, m22 = rot(t)
		local tr = m00 + m11 + m22
		local w, x, y, z
		if tr > 0 then
			local s = math.sqrt(tr + 1) * 2
			w = 0.25 * s
			x = (m21 - m12) / s
			y = (m02 - m20) / s
			z = (m10 - m01) / s
		elseif m00 > m11 and m00 > m22 then
			local s = math.sqrt(1 + m00 - m11 - m22) * 2
			w = (m21 - m12) / s
			x = 0.25 * s
			y = (m01 + m10) / s
			z = (m02 + m20) / s
		elseif m11 > m22 then
			local s = math.sqrt(1 + m11 - m00 - m22) * 2
			w = (m02 - m20) / s
			x = (m01 + m10) / s
			y = 0.25 * s
			z = (m12 + m21) / s
		else
			local s = math.sqrt(1 + m22 - m00 - m11) * 2
			w = (m10 - m01) / s
			x = (m02 + m20) / s
			y = (m12 + m21) / s
			z = 0.25 * s
		end
		local n = math.sqrt(w * w + x * x + y * y + z * z)
		return w / n, x / n, y / n, z / n
	end

	local function fromQuat(px, py, pz, w, x, y, z)
		return raw(px, py, pz,
			1 - 2 * (y * y + z * z), 2 * (x * y - z * w), 2 * (x * z + y * w),
			2 * (x * y + z * w), 1 - 2 * (x * x + z * z), 2 * (y * z - x * w),
			2 * (x * z - y * w), 2 * (y * z + x * w), 1 - 2 * (x * x + y * y))
	end

	CF.__index = function(t, k)
		if k == "Position" or k == "p" then
			return vec(t[1], t[2], t[3])
		elseif k == "X" or k == "x" then
			return t[1]
		elseif k == "Y" or k == "y" then
			return t[2]
		elseif k == "Z" or k == "z" then
			return t[3]
		elseif k == "LookVector" or k == "lookVector" then
			return vec(-t[6], -t[9], -t[12])
		elseif k == "RightVector" or k == "rightVector" or k == "XVector" then
			return vec(t[4], t[7], t[10])
		elseif k == "UpVector" or k == "upVector" or k == "YVector" then
			return vec(t[5], t[8], t[11])
		elseif k == "ZVector" then
			return vec(t[6], t[9], t[12])
		elseif k == "Rotation" then
			return raw(0, 0, 0, rot(t))
		end
		return CF[k]
	end

	CF.__mul = function(a, b)
		if getmetatable(b) == CF then
			local x, y, z = applyRot(a, b[1], b[2], b[3])
			return raw(a[1] + x, a[2] + y, a[3] + z, mulRot(a, b))
		end
		local x, y, z = applyRot(a, b.X, b.Y, b.Z)
		return vec(a[1] + x, a[2] + y, a[3] + z)
	end

	CF.__add = function(a, v)
		return raw(a[1] + v.X, a[2] + v.Y, a[3] + v.Z, rot(a))
	end

	CF.__sub = function(a, v)
		return raw(a[1] - v.X, a[2] - v.Y, a[3] - v.Z, rot(a))
	end

	CF.__eq = function(a, b)
		for i = 1, 12 do
			if a[i] ~= b[i] then
				return false
			end
		end
		return true
	end

	CF.__tostring = function(a)
		return string.format("%.3f, %.3f, %.3f", a[1], a[2], a[3])
	end

	function CF.Inverse(a)
		return inverse(a)
	end
	CF.inverse = CF.Inverse

	function CF.ToObjectSpace(a, b)
		return inverse(a) * b
	end

	function CF.ToWorldSpace(a, b)
		return a * b
	end

	function CF.PointToWorldSpace(a, v)
		return a * v
	end

	function CF.PointToObjectSpace(a, v)
		return inverse(a) * v
	end

	function CF.VectorToWorldSpace(a, v)
		return vec(applyRot(a, v.X, v.Y, v.Z))
	end

	function CF.VectorToObjectSpace(a, v)
		return vec(applyRotT(a, v.X, v.Y, v.Z))
	end

	function CF.GetComponents(a)
		return a[1], a[2], a[3], rot(a)
	end
	CF.components = CF.GetComponents

	function CF.Lerp(a, b, t)
		local aw, ax, ay, az = toQuat(a)
		local bw, bx, by, bz = toQuat(b)
		local d = aw * bw + ax * bx + ay * by + az * bz
		if d < 0 then
			bw, bx, by, bz, d = -bw, -bx, -by, -bz, -d
		end
		local w, x, y, z
		if d > 0.9995 then
			w, x, y, z = aw + (bw - aw) * t, ax + (bx - ax) * t, ay + (by - ay) * t, az + (bz - az) * t
		else
			local th = acos(math.min(d, 1))
			local s = math.sin(th)
			local wa, wb = math.sin((1 - t) * th) / s, math.sin(t * th) / s
			w, x, y, z = aw * wa + bw * wb, ax * wa + bx * wb, ay * wa + by * wb, az * wa + bz * wb
		end
		local n = math.sqrt(w * w + x * x + y * y + z * z)
		return fromQuat(a[1] + (b[1] - a[1]) * t, a[2] + (b[2] - a[2]) * t, a[3] + (b[3] - a[3]) * t, w / n, x / n, y / n, z / n)
	end
	CF.lerp = CF.Lerp

	function CF.ToAxisAngle(a)
		local w, x, y, z = toQuat(a)
		w = math.max(-1, math.min(1, w))
		local angle = 2 * acos(w)
		local s = math.sqrt(math.max(1 - w * w, 0))
		if s < 1e-6 then
			return vec(1, 0, 0), 0
		end
		return vec(x / s, y / s, z / s), angle
	end

	function CF.ToEulerAnglesXYZ(a)
		local m00, m01, m02, m10, m11, m12, m20, m21, m22 = rot(a)
		local y = asin(math.max(-1, math.min(1, m02)))
		local x = math.atan2(-m12, m22)
		local z = math.atan2(-m01, m00)
		return x, y, z
	end

	function CF.ToEulerAnglesYXZ(a)
		local m00, m01, m02, m10, m11, m12, m20, m21, m22 = rot(a)
		local x = asin(math.max(-1, math.min(1, -m12)))
		local y = math.atan2(m02, m22)
		local z = math.atan2(m10, m11)
		return x, y, z
	end

	function CF.ToEulerAngles(a, order)
		if order ~= nil and tostring(order):find("YXZ", 1, true) then
			return CF.ToEulerAnglesYXZ(a)
		end
		return CF.ToEulerAnglesXYZ(a)
	end

	function CF.Orthonormalize(a)
		local r = vec(a[4], a[7], a[10]).Unit
		local u = vec(a[5], a[8], a[11])
		u = (u - r * u:Dot(r)).Unit
		local b = r:Cross(u)
		return raw(a[1], a[2], a[3], r.X, u.X, b.X, r.Y, u.Y, b.Y, r.Z, u.Z, b.Z)
	end

	local function rx(t)
		local c, s = math.cos(t), math.sin(t)
		return raw(0, 0, 0, 1, 0, 0, 0, c, -s, 0, s, c)
	end
	local function ry(t)
		local c, s = math.cos(t), math.sin(t)
		return raw(0, 0, 0, c, 0, s, 0, 1, 0, -s, 0, c)
	end
	local function rz(t)
		local c, s = math.cos(t), math.sin(t)
		return raw(0, 0, 0, c, -s, 0, s, c, 0, 0, 0, 1)
	end

	local function fromMatrix(p, vx, vy, vz)
		vz = vz or vx:Cross(vy)
		return raw(p.X, p.Y, p.Z, vx.X, vy.X, vz.X, vx.Y, vy.Y, vz.Y, vx.Z, vy.Z, vz.Z)
	end

	local function lookAt(at, target, up)
		up = up or vec(0, 1, 0)
		local look = target - at
		if look.Magnitude < 1e-9 then
			return raw(at.X, at.Y, at.Z, 1, 0, 0, 0, 1, 0, 0, 0, 1)
		end
		look = look.Unit
		local right = look:Cross(up)
		if right.Magnitude < 1e-6 then
			right = look:Cross(vec(0, 0, 1))
			if right.Magnitude < 1e-6 then
				right = look:Cross(vec(1, 0, 0))
			end
		end
		right = right.Unit
		local up2 = right:Cross(look)
		return fromMatrix(at, right, up2, -look)
	end

	function api.new(...)
		local n = select("#", ...)
		local a = { ... }
		if n == 0 then
			return raw(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1)
		end
		if type(a[1]) == "table" then
			if n >= 2 and type(a[2]) == "table" then
				return lookAt(a[1], a[2])
			end
			return raw(a[1].X, a[1].Y, a[1].Z, 1, 0, 0, 0, 1, 0, 0, 0, 1)
		end
		if n >= 12 then
			return raw(a[1], a[2], a[3], a[4], a[5], a[6], a[7], a[8], a[9], a[10], a[11], a[12])
		end
		if n == 7 then
			return fromQuat(a[1], a[2], a[3], a[7], a[4], a[5], a[6])
		end
		return raw(tonumber(a[1]) or 0, tonumber(a[2]) or 0, tonumber(a[3]) or 0, 1, 0, 0, 0, 1, 0, 0, 0, 1)
	end

	function api.Angles(x, y, z)
		return rx(x or 0) * ry(y or 0) * rz(z or 0)
	end
	api.fromEulerAnglesXYZ = api.Angles

	function api.fromEulerAnglesYXZ(x, y, z)
		return ry(y or 0) * rx(x or 0) * rz(z or 0)
	end
	api.fromOrientation = api.fromEulerAnglesYXZ

	api.fromMatrix = fromMatrix
	api.lookAt = lookAt

	function api.lookAlong(at, dir, up)
		return lookAt(at, at + dir, up)
	end

	function api.fromEulerAngles(x, y, z, order)
		if order ~= nil and tostring(order):find("YXZ", 1, true) then
			return api.fromEulerAnglesYXZ(x, y, z)
		end
		return api.Angles(x, y, z)
	end

	function api.fromAxisAngle(axis, angle)
		local u = axis.Unit
		local h = angle * 0.5
		local s = math.sin(h)
		return fromQuat(0, 0, 0, math.cos(h), u.X * s, u.Y * s, u.Z * s)
	end

	api.identity = api.new()
	api.meta = CF
	return api
end

return Lib
