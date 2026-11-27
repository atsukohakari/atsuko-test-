local TITLE = "Book Reader"
local BOOK_ID = "18701259915"
local genv = (typeof(getgenv) == "function" and getgenv()) or _G

local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local V3, CF, ANG = Vector3.new, CFrame.new, CFrame.Angles
local CFI = CFrame.identity
local ZERO = V3(0, 0, 0)
local rad, sin, cos, exp, abs = math.rad, math.sin, math.cos, math.exp, math.abs
local min, max, clamp = math.min, math.max, math.clamp

local function say(text, kind, secs)
	local h = genv.AtsukoHub
	if type(h) == "table" and type(h.Notify) == "function" and pcall(h.Notify, TITLE, text, kind or "info", secs or 3) then
		return
	end
	local f = genv.AtsukoNotify
	if type(f) == "function" and pcall(f, TITLE, text, kind or "info", secs or 3) then
		return
	end
	warn("[" .. TITLE .. "] " .. tostring(text))
end

local POSE = {
	read = { book = { 0, 0.73, 1.95 }, free = { 0, -0.5, -1.71 } },
	carry = { book = { 0.15, 0.1, 2.6 }, free = { 1.4, -0.2, -1.26 } },
	jump = { book = { -0.1, 0, 0.22 }, free = { 0.16, 0, -2.0 }, right = 0.6, left = 0.3, lean = -0.08 },
	fall = { book = { 0, 0, 0.12 }, free = { -1.0, 0, -0.94 }, right = 0.25, left = -0.15, lean = 0.05 },
	neck = { 0.14, 0, 0 },
	bookPos = { 0.15, 1.05, -1.6 },
	carryTilt = { 0.7, -0.3, -0.3 },
	walkRate = 8.5,
	smooth = 14,
}
local HAND = { side = "right" }

local function loadLumen()
	local R = genv.LumenReanim
	if type(R) == "table" and type(R.rig) == "function" then
		return R
	end
	local base = type(genv.AtsukoHubRaw) == "string" and genv.AtsukoHubRaw or "https://raw.githubusercontent.com/atsukohakari/atsuko-test-/main/"
	local ok, src = pcall(function()
		if type(genv.AtsukoHubRead) == "function" then
			local got = genv.AtsukoHubRead("Hub/Reanimate.lua")
			if got or genv.AtsukoHubLocal then
				return got
			end
		end
		return game:HttpGet(base .. "Hub/Reanimate.lua")
	end)
	local fn = ok and type(src) == "string" and loadstring(src, "=Reanimate")
	if fn then
		local ok2, r = pcall(fn)
		if ok2 and type(r) == "table" and type(r.rig) == "function" then
			return r
		end
	end
	return nil
end

local hubFd = genv.AtsukoHatFd
local onHub = type(hubFd) == "table" and type(hubFd.reanimate) == "function" and type(hubFd.stopreanimate) == "function"
local Lumen = nil
if not onHub then
	Lumen = loadLumen()
	if not Lumen then
		say("Pick a reanimation on the Hat tab first", "error", 5)
		return
	end
end

local rig
if onHub then
	rig = hubFd
else
	rig = Lumen.rig({ aligns = {} })
end

local okFd, fd = pcall(rig.reanimate)
if not okFd or type(fd) ~= "table" or type(fd.cframes) ~= "table" or type(fd.getJoint) ~= "function" or type(fd.addmode) ~= "function" then
	say("Couldn't reanimate: " .. tostring(okFd and "the reanimation gave no body" or fd), "error", 6)
	return
end

local live = (not onHub) and Lumen.current() or nil
local function reanimOn()
	if onHub then
		local ok, isOn = pcall(hubFd.isReanimated)
		return ok and isOn and true or false
	end
	return Lumen.current() == live and live ~= nil
end
do
	local deadline = os.clock() + 10
	while reanimOn() and live and type(live.isReady) == "function" and not live.isReady() and os.clock() < deadline do
		task.wait()
	end
	if not reanimOn() then
		say("The reanimation stopped", "error", 4)
		return
	end
end

local JOINTS = { "RootJoint", "Neck", "Right Shoulder", "Left Shoulder", "Right Hip", "Left Hip" }
local J, REST = {}, {}
for _, name in ipairs(JOINTS) do
	local j = fd.getJoint(name)
	if type(j) == "table" and typeof(j.C0) == "CFrame" then
		J[name] = j
		REST[name] = { C0 = j.C0, C1 = typeof(j.C1) == "CFrame" and j.C1 or CFI }
	end
end
if not (J["Right Shoulder"] and J["Left Shoulder"]) then
	say("No arms to hold the book", "error", 4)
	return
end

local function part(name)
	local ok, p = pcall(fd.getPart, name)
	return ok and p or nil
end

local alive = true
local conns = {}

local FILE = "BookReaderAlign.json"
local TABS = { "Book", "Book arm", "Other arm" }
local VAL = { { 0, 0, 0, 0, 0, 0 }, { 0, 0, 0, 0, 0, 0 }, { 0, 0, 0, 0, 0, 0 } }
local OFF = { CFI, CFI, CFI }
local function rebuild(s)
	local v = VAL[s]
	OFF[s] = CF(v[1], v[2], v[3]) * ANG(rad(v[4]), rad(v[5]), rad(v[6]))
end
local function loadAlign()
	if not (isfile and readfile) then
		return false, "your executor can't read files"
	end
	local ok, has = pcall(isfile, FILE)
	if not ok or not has then
		return false, "no saved alignment yet"
	end
	local ok2, data = pcall(function()
		return HttpService:JSONDecode(readfile(FILE))
	end)
	if not ok2 or type(data) ~= "table" then
		return false, FILE .. " is damaged"
	end
	if data.hand == "left" or data.hand == "right" then
		HAND.side = data.hand
	end
	for s, key in ipairs({ "book", "bookArm", "otherArm" }) do
		local a = data[key]
		if a == nil and s > 1 then
			a = data[s == 2 and "right" or "left"]
		end
		if type(a) == "table" then
			for k = 1, 6 do
				local n = tonumber(a[k])
				if n and n == n and abs(n) < 1e5 then
					VAL[s][k] = n
				end
			end
		end
		rebuild(s)
	end
	return true
end
local function saveAlign()
	if not writefile then
		return false, "your executor can't save files"
	end
	local ok, e = pcall(writefile, FILE, HttpService:JSONEncode({ v = 2, book = VAL[1], bookArm = VAL[2], otherArm = VAL[3], hand = HAND.side }))
	if not ok then
		return false, tostring(e)
	end
	return true
end
loadAlign()

local BOOK = { e = nil, j = nil, home = nil, fit = CFI, height = 1.2, key = nil, name = nil, nextScan = 0, src = nil }
local defaultMesh = nil

local function digits(v)
	if type(v) ~= "string" then
		return nil
	end
	return string.match(v, "(%d+)%D*$")
end

local function accName(e)
	local ok, n = pcall(function()
		return rawget(e, "p").Parent.Name
	end)
	return ok and type(n) == "string" and n or ""
end

local function sizeOf(e)
	local s = V3(1, 1, 1)
	pcall(function()
		local p = rawget(e, "p")
		if typeof(p.Size) == "Vector3" then
			s = p.Size
		end
	end)
	return s
end

local function hubRow(e)
	local A = genv.AtsukoAlignment
	if type(A) ~= "table" or type(A.match) ~= "function" then
		return nil
	end
	local ok, row = pcall(A.match, TITLE, "book", { mesh = digits(rawget(e, "m")), tex = digits(rawget(e, "t")), name = accName(e) })
	if ok and type(row) == "table" and row.src == "user" then
		return row
	end
	return nil
end

local function hubOffset(row)
	local A = genv.AtsukoAlignment
	if not (row and row.align and type(A) == "table" and type(A.offset) == "function") then
		return nil
	end
	local ok, c = pcall(A.offset, row)
	if ok and typeof(c) == "CFrame" then
		return c
	end
	return nil
end

local function nameIsBook(name)
	local text = string.lower(tostring(name or ""))
	return string.find(text, "book", 1, true) ~= nil
end

local function fitOf(size)
	local list = { { 1, size.X }, { 2, size.Y }, { 3, size.Z } }
	table.sort(list, function(a, b)
		return a[2] > b[2]
	end)
	local long, mid, thin = list[1], list[2], list[3]
	if long[2] < thin[2] * 1.25 then
		return CFI, clamp(long[2], 0.6, 3)
	end
	local cols = { V3(), V3(), V3() }
	cols[long[1]] = V3(0, 1, 0)
	cols[mid[1]] = V3(1, 0, 0)
	cols[thin[1]] = V3(0, 0, 1)
	if cols[1]:Cross(cols[2]):Dot(cols[3]) < 0 then
		cols[thin[1]] = V3(0, 0, -1)
	end
	return CFrame.fromMatrix(V3(), cols[1], cols[2], cols[3]), clamp(long[2], 0.6, 3)
end

local function hatEntries()
	local out = {}
	for e in pairs(fd.cframes) do
		if type(e) == "table" and rawget(e, "m") ~= nil then
			out[#out + 1] = e
		end
	end
	return out
end

local function releaseBook()
	local j, home = BOOK.j, BOOK.home
	if j and home then
		pcall(function()
			j.Part1, j.C0, j.C1 = home[1], home[2], home[3]
		end)
	end
	BOOK.e, BOOK.j, BOOK.home, BOOK.key, BOOK.name, BOOK.row = nil, nil, nil, nil, nil, nil
end

local function findBook()
	local best, rank, row = nil, math.huge, nil
	for _, e in ipairs(hatEntries()) do
		local r = hubRow(e)
		local score = nil
		if r then
			score = 1
		elseif defaultMesh and digits(rawget(e, "m")) == defaultMesh then
			score = 2
		elseif nameIsBook(accName(e)) then
			score = 3
		end
		if score and score < rank then
			best, rank, row = e, score, r
		end
	end
	if best == BOOK.e then
		return BOOK.e ~= nil
	end
	releaseBook()
	if not best then
		return false
	end
	local ok, j = pcall(fd.getPartJoint, best)
	if not ok or type(j) ~= "table" then
		return false
	end
	BOOK.e, BOOK.j = best, j
	BOOK.home = { j.Part1, j.C0, j.C1 }
	BOOK.key = digits(rawget(best, "m")) or digits(rawget(best, "t"))
	BOOK.name = accName(best)
	BOOK.row = row
	BOOK.fit, BOOK.height = fitOf(sizeOf(best))
	BOOK.src = rank == 1 and "yours" or (rank == 2 and "the How To Read Book" or "found by its name")
	return true
end

task.spawn(function()
	local cached = genv.AtsukoBookMesh
	if type(cached) == "string" then
		defaultMesh = cached
		return
	end
	local ok, objects = pcall(function()
		return game:GetObjects("rbxassetid://" .. BOOK_ID)
	end)
	if not ok or type(objects) ~= "table" then
		return
	end
	for _, item in ipairs(objects) do
		pcall(function()
			local handle = item:IsA("Accessory") and item:FindFirstChild("Handle") or item:FindFirstChild("Handle", true)
			if handle and not defaultMesh then
				local mesh = nil
				if handle:IsA("MeshPart") then
					mesh = handle.MeshId
				else
					local special = handle:FindFirstChildOfClass("SpecialMesh")
					mesh = special and special.MeshId
				end
				defaultMesh = digits(mesh)
			end
		end)
		pcall(function()
			item:Destroy()
		end)
	end
	if defaultMesh then
		genv.AtsukoBookMesh = defaultMesh
		BOOK.nextScan = 0
	end
end)

local function armCF(name, rotation)
	local rest = REST[name]
	return rest.C0 * rotation * rest.C1:Inverse()
end

local function side(v)
	if HAND.side == "left" then
		return ANG(v[1], -v[2], -v[3])
	end
	return ANG(v[1], v[2], v[3])
end

local function sideX(x)
	return HAND.side == "left" and -x or x
end

local function joints()
	if HAND.side == "left" then
		return "Left Shoulder", "Right Shoulder", "Left Arm"
	end
	return "Right Shoulder", "Left Shoulder", "Right Arm"
end

local function offsetRot(s)
	return side({ rad(VAL[s][4]), rad(VAL[s][5]), rad(VAL[s][6]) })
end

local function readRot(which)
	return side(POSE.read[which]) * offsetRot(which == "book" and 2 or 3)
end

local function carryRot(which)
	return side(POSE.carry[which])
end

local function bookTarget(carry)
	local fit = BOOK.fit
	local extra = hubOffset(BOOK.row)
	local tail = fit
	if extra then
		tail = tail * extra
	end
	tail = tail * OFF[1]
	if not carry then
		local p = POSE.bookPos
		return CF(sideX(p[1]), p[2] + BOOK.height * 0.5, p[3]) * tail
	end
	local bookJoint = joints()
	local hand = armCF(bookJoint, carryRot("book")) * V3(0, -1, 0)
	return CF(hand) * side(POSE.carryTilt) * CF(0, BOOK.height * 0.5 + 0.05, 0) * tail
end

local function bookCF(blend)
	local bookJoint = joints()
	local read = armCF(bookJoint, readRot("book")):Inverse() * bookTarget(false)
	if not blend or blend <= 0 then
		return read
	end
	local carry = armCF(bookJoint, carryRot("book")):Inverse() * bookTarget(true)
	return read:Lerp(carry, blend)
end

local state = { walk = 0, air = 0, rise = 0, reach = 0, phase = 0, last = os.clock(), breath = 0, dip = 0, dipV = 0, wasAir = false, moving = false, warned = false }

local function vel()
	if type(fd.getVel) ~= "function" then
		return ZERO
	end
	local ok, v = pcall(fd.getVel)
	if not ok or typeof(v) ~= "Vector3" then
		return ZERO
	end
	return v
end

local function ease(t)
	t = clamp(t, 0, 1)
	return t * t * (3 - 2 * t)
end

local function toward(cur, goal, rate, dt)
	return cur + (goal - cur) * (1 - exp(-rate * dt))
end

local function aim(name, offset, a)
	local j, rest = J[name], REST[name]
	if not (j and rest) then
		return
	end
	j.C0 = j.C0:Lerp(rest.C0 * offset, a)
end

local function step(kind)
	local now = os.clock()
	local dt = clamp(now - state.last, 1 / 240, 1 / 15)
	state.last = now
	local a = 1 - exp(-POSE.smooth * dt)
	local v = vel()
	local speed = V3(v.X, 0, v.Z).Magnitude
	local airborne = kind == "jump" or kind == "fall"
	if not airborne then
		state.moving = kind == "walk"
	end
	if state.wasAir and not airborne and state.air > 0.35 then
		state.dipV = state.dipV - clamp(-v.Y / 45, 0.6, 1) * 6
	end
	state.wasAir = airborne
	state.walk = toward(state.walk, state.moving and 1 or 0, 6, dt)
	state.air = toward(state.air, airborne and 1 or 0, 9, dt)
	state.rise = toward(state.rise, kind == "jump" and 1 or 0, 7, dt)
	state.reach = toward(state.reach, state.air, 5, dt)
	state.dipV = state.dipV + (-140 * state.dip - 15 * state.dipV) * dt
	state.dip = clamp(state.dip + state.dipV * dt, -0.6, 0.3)
	if kind == "walk" then
		local rate = POSE.walkRate * clamp((speed > 0.5 and speed or 16) / 16, 0.6, 1.7)
		state.phase = (state.phase + dt * rate) % (math.pi * 2)
	end
	state.breath = (state.breath + dt * 1.6) % (math.pi * 2)

	local w = ease(state.walk)
	local ground = 1 - state.air
	local gait = state.walk * ground
	local s, s2 = sin(state.phase), sin(state.phase * 2)
	local hs = HAND.side == "left" and -s or s
	local breathe = sin(state.breath) * 0.02 * (1 - state.walk)
	local r = state.rise
	local J1 = POSE.jump
	local F = POSE.fall
	local function airMix(key)
		return (J1[key] * r + F[key] * (1 - r)) * state.air
	end
	local function airRot(which)
		local jv, fv = J1[which], F[which]
		return side({ (jv[1] * r + fv[1] * (1 - r)) * state.air, (jv[2] * r + fv[2] * (1 - r)) * state.air, (jv[3] * r + fv[3] * (1 - r)) * state.air })
	end

	local amp = clamp(0.45 + speed * 0.02, 0.45, 0.85) * gait
	local swing = s * amp
	local dip = state.dip
	aim("Right Hip", ANG(0, 0, swing + airMix("right") + dip * 0.6), a)
	aim("Left Hip", ANG(0, 0, swing + airMix("left") - dip * 0.6), a)

	local lean = 0.06 * gait + airMix("lean") - dip * 0.8
	local twist = 0.07 * s * gait
	local roll = 0.025 * s * gait
	local bob = -0.09 * s * s * gait + dip * 0.6
	aim("RootJoint", CF(0, 0, bob) * ANG(lean, roll, twist), a)

	local look = POSE.neck[1] * (1 - w * 0.6) + breathe * 0.6 - 0.05 * s2 * gait - airMix("lean") * 0.8 + dip * 0.5
	aim("Neck", ANG(look, 0, -twist * 0.7), a)

	local bookJoint, freeJoint = joints()
	local bookRot = readRot("book"):Lerp(carryRot("book"), w)
	local freeAir = side(POSE.jump.free):Lerp(side(POSE.fall.free), 1 - r)
	local freeRot = readRot("free"):Lerp(carryRot("free"), w):Lerp(freeAir, ease(state.reach) * 0.8)
	local bookGait = side({ 0, 0, 0.07 * s2 * gait + dip * 0.5 + breathe })
	local freeGait = side({ 0, 0, -0.14 * hs * gait - dip * 0.5 - breathe })
	aim(bookJoint, bookGait * airRot("book") * bookRot, a)
	aim(freeJoint, freeGait * freeRot, a)

	if now >= BOOK.nextScan then
		BOOK.nextScan = now + 1
		if not BOOK.e or fd.cframes[BOOK.e] == nil then
			findBook()
		end
		if not BOOK.e and not state.warned and now - state.start > 4 then
			state.warned = true
			say("Wear a book hat or say add book <hat id>", "info", 5)
		end
	end
	local j = BOOK.j
	if j then
		local _, _, armName = joints()
		local arm = part(armName)
		if arm then
			j.Part1 = arm
			j.C0 = CFI
			j.C1 = bookCF(w)
		end
	end
end
state.start = os.clock()

local function frame(kind)
	return function()
		if not alive then
			return
		end
		local ok, err = pcall(step, kind)
		if not ok and err ~= state.err then
			state.err = err
			warn("[" .. TITLE .. "] " .. tostring(err))
		end
	end
end

local watchers = {}
local function fire(what)
	for _, f in ipairs(table.clone(watchers)) do
		pcall(f, what)
	end
end

local AL = { version = 1, title = TITLE, tabs = TABS, file = FILE, dirty = false, open = false, marker = false, hint = "Book moves the book, the arm tabs turn the arms." }
local cur = 1
function AL.alive()
	return alive
end
function AL.focus(s)
	if VAL[s] then
		cur = s
	end
end
function AL.rows(s)
	if s == 2 or s == 3 then
		return { 4, 5, 6 }
	end
	return nil
end
function AL.get(s)
	return VAL[s] and table.clone(VAL[s]) or nil
end
function AL.later()
	AL.tok = (AL.tok or 0) + 1
	local my = AL.tok
	task.delay(1.5, function()
		if my == AL.tok and AL.dirty and alive and AL.save() then
			fire("saved")
		end
	end)
end
function AL.set(s, k, n)
	local v = VAL[s]
	n = tonumber(n)
	if not v or not n or n ~= n or abs(n) >= 1e5 then
		return nil
	end
	if k > 3 then
		n = ((n + 180) % 360) - 180
		n = math.floor(n * 10 + 0.5) / 10
	else
		n = math.floor(n * 1000 + 0.5) / 1000
	end
	v[k] = n
	rebuild(s)
	AL.dirty = true
	AL.later()
	return n
end
function AL.put(s, vals)
	if not VAL[s] or type(vals) ~= "table" then
		return
	end
	for k = 1, 6 do
		VAL[s][k] = tonumber(vals[k]) or 0
	end
	rebuild(s)
	AL.dirty = true
	AL.later()
end
function AL.reset(s)
	AL.put(s, { 0, 0, 0, 0, 0, 0 })
end
function AL.save()
	AL.tok = (AL.tok or 0) + 1
	local ok, e = saveAlign()
	if ok then
		AL.dirty = false
	end
	return ok, e
end
function AL.load()
	local ok, e = loadAlign()
	if ok then
		AL.dirty = false
	end
	fire("load")
	return ok, e
end
function AL.watch(f)
	watchers[#watchers + 1] = f
	return function()
		local i = table.find(watchers, f)
		if i then
			table.remove(watchers, i)
		end
	end
end
function AL.found()
	if BOOK.e then
		return "Book: " .. (BOOK.name ~= "" and BOOK.name or "found")
	end
	return "Book: not found"
end
function AL.hat(s)
	if s ~= 1 or not BOOK.key then
		return nil
	end
	return BOOK.key, BOOK.key, BOOK.name ~= "" and BOOK.name or nil
end
AL.optList = { { "hand", "Book hand", "choice", { { "right", "Right" }, { "left", "Left" } } }, { "flip", "Flip the book", "button", "repeat" } }
function AL.opts()
	return { hand = HAND.side }
end
function AL.setOpt(name, value)
	if name == "flip" then
		AL.set(1, 5, VAL[1][5] + 180)
	elseif name == "hand" and (value == "left" or value == "right") and value ~= HAND.side then
		HAND.side = value
		AL.dirty = true
		AL.later()
		fire("hand")
	end
end

local function stop()
	if not alive then
		return
	end
	alive = false
	for _, c in ipairs(conns) do
		pcall(function()
			c:Disconnect()
		end)
	end
	table.clear(conns)
	if AL.dirty then
		pcall(saveAlign)
		AL.dirty = false
	end
	releaseBook()
	for name, j in pairs(J) do
		pcall(function()
			j.C0 = REST[name].C0
		end)
	end
	AL.open = false
	if genv.AtsukoAlign == AL then
		genv.AtsukoAlign = nil
	end
	fire("stop")
	local h = genv.AtsukoHub
	if type(h) == "table" and type(h.AlignReady) == "function" then
		pcall(h.AlignReady)
	end
	if genv.AtsukoBookReader and genv.AtsukoBookReader.stop == stop then
		genv.AtsukoBookReader = nil
	end
end

genv.AtsukoBookReader = {
	pose = POSE,
	hand = HAND,
	book = BOOK,
	state = state,
	onFdless = onHub,
	findBook = findBook,
	bookCF = bookCF,
	fitOf = fitOf,
	stop = stop,
	alive = function()
		return alive
	end,
}

fd.addmode("default", { idle = frame("idle"), walk = frame("walk"), jump = frame("jump"), fall = frame("fall") })
genv.AtsukoAlign = AL
do
	local h = genv.AtsukoHub
	if type(h) == "table" and type(h.AlignReady) == "function" then
		pcall(h.AlignReady)
	end
	if type(h) == "table" and type(h.OnStop) == "function" then
		h.OnStop(function()
			stop()
			pcall(function()
				if rig and rig.stopreanimate then
					rig.stopreanimate()
				end
			end)
		end)
	end
end

conns[#conns + 1] = RunService.Heartbeat:Connect(function()
	if alive and not reanimOn() then
		stop()
	end
end)

findBook()
say(BOOK.e and ("Reading " .. (BOOK.name ~= "" and BOOK.name or "your book")) or "On", "ok", 3)
