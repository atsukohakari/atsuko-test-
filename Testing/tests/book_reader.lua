local World = loadmodule("Testing/mocks/rbx_world.lua")
local env = World.install({})
local Exact = loadmodule("Testing/mocks/cframe_math.lua").make(Vector3)
CFrame = Exact
local makeApi = loadmodule("Testing/mocks/fake_fd.lua").make
local A = loadmodule("Hub/modules/alignment.lua")
local genv = env.genv
local PATH = "Scripts/Hat/BookReader.lua"

local R6 = {
	["RootJoint"] = { CFrame.new(0, 0, 0, -1, 0, 0, 0, 0, 1, 0, 1, 0), CFrame.new(0, 0, 0, -1, 0, 0, 0, 0, 1, 0, 1, 0) },
	["Neck"] = { CFrame.new(0, 1, 0, -1, 0, 0, 0, 0, 1, 0, 1, 0), CFrame.new(0, -0.5, 0, -1, 0, 0, 0, 0, 1, 0, 1, 0) },
	["Right Shoulder"] = { CFrame.new(1, 0.5, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0), CFrame.new(-0.5, 0.5, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0) },
	["Left Shoulder"] = { CFrame.new(-1, 0.5, 0, 0, 0, -1, 0, 1, 0, 1, 0, 0), CFrame.new(0.5, 0.5, 0, 0, 0, -1, 0, 1, 0, 1, 0, 0) },
	["Right Hip"] = { CFrame.new(1, -1, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0), CFrame.new(0.5, 1, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0) },
	["Left Hip"] = { CFrame.new(-1, -1, 0, 0, 0, -1, 0, 1, 0, 1, 0, 0), CFrame.new(-0.5, 1, 0, 0, 0, -1, 0, 1, 0, 1, 0, 0) },
}

local function realApi()
	local api = makeApi()
	for _, j in ipairs(api.joints) do
		local r = R6[j.Name]
		if r then
			j.C0, j.C1 = r[1], r[2]
		end
	end
	return api
end

local function solve(api)
	local done = {}
	local cfs = {}
	local root = api.V.HumanoidRootPart
	cfs[root] = CFrame.new(0, 3, 0)
	done[root] = true
	local more = true
	while more do
		more = false
		for _, j in ipairs(api.joints) do
			local a, b = j.Part0, j.Part1
			if a and b and a ~= b then
				if done[b] and not done[a] then
					cfs[a] = cfs[b] * j.C1 * j.C0:Inverse()
					done[a] = true
					more = true
				elseif done[a] and not done[b] then
					cfs[b] = cfs[a] * j.C0 * j.C1:Inverse()
					done[b] = true
					more = true
				end
			end
		end
	end
	return cfs
end

local function near(a, b, eps)
	return math.abs(a - b) < (eps or 1e-3)
end

local toasts = {}
genv.AtsukoNotify = function(title, text, kind)
	toasts[#toasts + 1] = tostring(title) .. "|" .. tostring(text) .. "|" .. tostring(kind)
end
_G.delay = function(t, f)
	return task.delay(t, f)
end
local warned = {}
local oldWarn = warn
warn = function(...)
	warned[#warned + 1] = table.concat({ tostring((...)) }, " ")
end

local function run(opts)
	opts = opts or {}
	local S = { on = false }
	genv.AtsukoAlign = nil
	genv.AtsukoBookReader = nil
	local FD = {
		reanimate = function()
			S.on = true
			local api = realApi()
			S.api = api
			if not opts.noBook then
				S.book, S.bj = api.hat(opts.bookName or "How To Read Book", "777001", "777002", opts.size or Vector3.new(1.2, 1.6, 0.25))
			end
			S.cap, S.cj = api.hat("Cool Cap", "555", "556")
			return api
		end,
		stopreanimate = function()
			S.on = false
		end,
		isReanimated = function()
			return S.on
		end,
	}
	genv.AtsukoHatFd = FD
	local fn, err = loadstring(readsource(PATH), "=" .. PATH)
	S.compiled, S.err = fn ~= nil, err
	task.spawn(function()
		local ok, e = pcall(fn)
		S.ended = { ok, e }
	end)
	env.run(0.2)
	S.BR = genv.AtsukoBookReader
	S.AL = genv.AtsukoAlign
	function S.frames(n, kind)
		for _ = 1, n do
			local m = S.api and S.api.modes.default
			if m and m[kind or "idle"] then
				m[kind or "idle"]()
			end
			env.frame()
		end
	end
	return S
end

T.section("book_reader: the pose from the video, on real R6 joints")
do
	local function arm(name, angles)
		local r = R6[name]
		return r[1] * angles * r[2]:Inverse()
	end
	local right = arm("Right Shoulder", CFrame.Angles(0, 0.73, 1.95))
	local hand = right * Vector3.new(0, -1, 0)
	T.ok(hand.Z < -1.2, "the right hand is out in front: " .. tostring(hand))
	T.ok(hand.Y > 0.9 and hand.Y < 1.3, "up at the chin")
	T.ok(hand.X > 0.2 and hand.X < 0.7, "and just right of the middle, under the book")
	local left = arm("Left Shoulder", CFrame.Angles(0, -0.5, -1.71))
	local lhand = left * Vector3.new(0, -1, 0)
	T.ok(lhand.Z < -1.2 and lhand.Y > 0.5 and lhand.Y < 1, "the left hand is forward at the chest: " .. tostring(lhand))
	T.ok(lhand.X < 0, "on the left")
	local neck = R6.Neck[1] * CFrame.Angles(0.14, 0, 0) * R6.Neck[2]:Inverse()
	T.ok(neck.LookVector.Y < -0.1, "the head looks down a little, at the book")
end

T.section("book_reader: a book hat is stood up facing you, whatever way it was made")
do
	local S = run({ noBook = true })
	local fitOf = S.BR and S.BR.fitOf
	T.ok(type(fitOf) == "function", "the script runs and shows its helpers")
	if fitOf then
		for _, size in ipairs({ Vector3.new(1.2, 1.6, 0.25), Vector3.new(0.25, 1.6, 1.2), Vector3.new(1.6, 0.25, 1.2), Vector3.new(1.2, 0.25, 1.6) }) do
			local fit, h = fitOf(size)
			local up = fit:VectorToWorldSpace(Vector3.new(size.X, size.Y, size.Z))
			T.ok(near(math.abs(up.Y), 1.6), "the long side stands up for " .. tostring(size))
			T.ok(near(math.abs(up.Z), 0.25), "and the thin side faces you")
			T.ok(near(fit.RightVector:Cross(fit.UpVector):Dot(-fit.LookVector), 1), "without mirroring it")
			T.eq(h, 1.6)
		end
		local cube, hc = fitOf(Vector3.new(1, 1.1, 1))
		T.ok(near(cube.UpVector.Y, 1), "a hat that isn't book shaped is left as it is")
		T.eq(hc, 1.1)
	end
	if S.BR then
		S.BR.stop()
	end
	env.run(1)
end

T.section("book_reader: runs on FDless and reads the book")
local S = run()
T.ok(S.compiled, "compiles: " .. tostring(S.err))
T.ok(S.api ~= nil, "reanimated through the hub")
T.ok(S.BR ~= nil and S.BR.onFdless == true, "on FDless")
local started = false
for _, t in ipairs(toasts) do
	if string.find(t, "Reading How To Read Book", 1, true) then
		started = true
	end
end
T.ok(started, "the start notice names the book: " .. table.concat(toasts, " / "))
T.eq(string.find(readsource(PATH), "--", 1, true), nil, "the script is only code, no comments")
if S.api then
	local arm = S.api.V["Right Arm"]
	S.frames(120)
	T.eq(S.bj.Part1, arm, "the book is in the right hand")
	local cfs = solve(S.api)
	local root = cfs[S.api.V.HumanoidRootPart]
	local head = root:PointToObjectSpace(cfs[S.api.V.Head].Position)
	local book = cfs[S.book]
	local local_ = root:PointToObjectSpace(book.Position)
	T.ok(local_.Z < head.Z - 1.1, "the book is in front of the face: " .. tostring(local_))
	T.ok(math.abs(local_.Y - head.Y) < 0.5, "at face height")
	T.ok(math.abs(local_.X) < 0.6, "in the middle, not off to the side")
	local up = root:VectorToObjectSpace(book.UpVector)
	T.ok(up.Y > 0.9, "standing up: " .. tostring(up))
	local face = root:VectorToObjectSpace(book.LookVector)
	T.ok(math.abs(face.Z) > 0.9, "facing you, flat to your face")
	local rhand = root:PointToObjectSpace(cfs[S.api.V["Right Arm"]] * Vector3.new(0, -1, 0))
	local lhand = root:PointToObjectSpace(cfs[S.api.V["Left Arm"]] * Vector3.new(0, -1, 0))
	T.ok(rhand.Z < -1 and lhand.Z < -1, "both hands are up in front of you")
	T.ok((rhand - local_).Magnitude < 1.3, "the right hand is at the book")

	local last = {}
	for _, j in ipairs(S.api.joints) do
		last[j] = j.C0
	end
	local biggest = 0
	for i = 1, 90 do
		S.frames(1, "walk")
		for _, j in ipairs(S.api.joints) do
			if last[j] and j.Name and j.Name ~= "AccessoryWeld" then
				local d = (j.C0.Position - last[j].Position).Magnitude + (j.C0.LookVector - last[j].LookVector).Magnitude + (j.C0.UpVector - last[j].UpVector).Magnitude
				biggest = math.max(biggest, d)
				last[j] = j.C0
			end
		end
	end
	T.ok(biggest < 0.35, "walking moves every joint a little each frame, no snapping: " .. biggest)
	T.ok(S.BR.state.walk > 0.9, "after a while it is fully in the walk")
	local hipR, hipL
	for _, j in ipairs(S.api.joints) do
		if j.Name == "Right Hip" then
			hipR = j
		elseif j.Name == "Left Hip" then
			hipL = j
		end
	end
	local walkCfs = solve(S.api)
	local stride = 0
	for _ = 1, 24 do
		walkCfs = solve(S.api)
		local rl = root:PointToObjectSpace(walkCfs[S.api.V["Right Leg"]] * Vector3.new(0, -1, 0))
		local ll = root:PointToObjectSpace(walkCfs[S.api.V["Left Leg"]] * Vector3.new(0, -1, 0))
		stride = math.max(stride, math.abs(rl.Z - ll.Z))
		if stride > 0.3 then break end
		S.frames(1, "walk")
	end
	T.ok(stride > 0.3 or S.BR.state.walk < 0.5, "the legs step, one forward and one back: " .. tostring(stride))
	local torso = walkCfs[S.api.V.Torso]
	local wbook = torso:PointToObjectSpace(walkCfs[S.book].Position)
	local whand = torso:PointToObjectSpace(walkCfs[S.api.V["Right Arm"]] * Vector3.new(0, -1, 0))
	local whead = torso:PointToObjectSpace(walkCfs[S.api.V.Head].Position)
	T.ok(whand.Y > whead.Y and whand.X > 1.2, "walking, the book arm goes up beside your head like in the video: " .. tostring(whand))
	T.ok(wbook.Y > whand.Y and math.abs(wbook.X - whand.X) < 0.9, "with the book up on that hand: " .. tostring(wbook))
	T.ok((torso:PointToObjectSpace(walkCfs[S.book] * Vector3.new(0, -0.8, 0)) - whand).Magnitude < 0.6, "its bottom resting on the hand")
	local wl = torso:PointToObjectSpace(walkCfs[S.api.V["Left Arm"]] * Vector3.new(0, -1, 0))
	T.ok(wl.Z < -1.2 and wl.Y < 0.7 and wl.Y > -0.4, "and the other arm held forward across you: " .. tostring(wl))
	local spots = {}
	for i = 1, 24 do
		S.frames(1, "walk")
		local c = solve(S.api)
		local t = c[S.api.V.Torso]
		spots[#spots + 1] = t:PointToObjectSpace(c[S.book].Position).Y
	end
	local lo, hi = math.huge, -math.huge
	for _, y in ipairs(spots) do
		lo, hi = math.min(lo, y), math.max(hi, y)
	end
	T.ok(hi - lo > 0.02 and hi - lo < 0.5, "the book bobs a little with every step: " .. (hi - lo))
	T.ok(hipR ~= nil and hipL ~= nil)

	local function hipAngle(j)
		local _, _, z = (R6[j.Name][1]:Inverse() * j.C0):ToEulerAnglesXYZ()
		return z
	end
	local function watch(n, kind)
		local most = 0
		local prev = {}
		for _, j in ipairs(S.api.joints) do
			prev[j] = j.C0
		end
		for _ = 1, n do
			S.frames(1, kind)
			for _, j in ipairs(S.api.joints) do
				if prev[j] and j.Name and j.Name ~= "AccessoryWeld" then
					local d = (j.C0.Position - prev[j].Position).Magnitude + (j.C0.LookVector - prev[j].LookVector).Magnitude + (j.C0.UpVector - prev[j].UpVector).Magnitude
					most = math.max(most, d)
					prev[j] = j.C0
				end
			end
		end
		return most
	end
	local jumpMost = watch(12, "jump")
	T.ok(hipAngle(hipR) > 0.25, "jumping lifts the right leg: " .. hipAngle(hipR))
	T.ok(S.BR.state.air > 0.5 and S.BR.state.rise > 0.4, "it is in the jump pose")
	local jc = solve(S.api)
	local jt = jc[S.api.V.Torso]
	local jl = jt:PointToObjectSpace(jc[S.api.V["Left Arm"]] * Vector3.new(0, -1, 0))
	T.ok(jl.X < wl.X - 0.2, "the other arm swings out for balance: " .. tostring(jl))
	local fallMost = watch(14, "fall")
	T.ok(S.BR.state.rise < 0.5, "falling eases into the fall pose")
	T.eq(S.bj.Part1, arm, "jumping keeps the book in hand")
	local landMost = watch(4, "walk")
	T.ok(S.BR.state.dip < -0.02, "landing dips the body a little: " .. S.BR.state.dip)
	local settle = watch(40, "walk")
	T.ok(math.abs(S.BR.state.dip) < 0.05, "and it springs back")
	T.ok(math.max(jumpMost, fallMost, landMost, settle) < 0.45, "the jump, the fall and the landing never snap: " .. math.max(jumpMost, fallMost, landMost, settle))
	local stopMost = watch(90, "idle")
	T.ok(stopMost < 0.35, "stopping eases the book back down in front of your face: " .. stopMost)
	local back = solve(S.api)
	local rb = root:PointToObjectSpace(back[S.api.V["Right Leg"]] * Vector3.new(0, -1, 0))
	T.ok(math.abs(rb.Z) < 0.15, "standing still, the legs settle back under you")
	local bb = root:PointToObjectSpace(back[S.book].Position)
	T.ok(bb.Z < head.Z - 1.1 and math.abs(bb.X) < 0.6, "and the book is back in front of the face: " .. tostring(bb))

	local AL = S.AL
	T.ok(type(AL) == "table" and AL.title == "Book Reader", "the Alignment window can open for it")
	T.same(AL.tabs, { "Book", "Book arm", "Other arm" })
	local key, mesh, name = AL.hat(1)
	T.eq(key, "777001", "the Book tab is for this book, so its spot is saved for it only")
	T.eq(mesh, "777001")
	T.eq(name, "How To Read Book")
	T.eq(AL.hat(2), nil, "the arm tabs are not about a hat")
	T.same(AL.rows(2), { 4, 5, 6 }, "the arm tabs only turn")
	T.eq(AL.rows(1), nil, "the Book tab moves and turns")
	T.ok(string.find(AL.found(), "How To Read Book", 1, true) ~= nil, AL.found())
	local c1 = S.bj.C1
	AL.set(1, 2, 0.5)
	S.frames(2)
	T.ok((S.bj.C1.Position - c1.Position).Magnitude > 0.4, "moving the book in the window moves it")
	AL.setOpt("flip")
	T.eq(math.abs(AL.get(1)[5]), 180, "flip turns the book around")
	AL.put(1, { 0, 0, 0, 0, 0, 0 })
	AL.set(2, 4, 10)
	S.frames(60)
	local tweaked = solve(S.api)
	local hand2 = root:PointToObjectSpace(tweaked[S.api.V["Right Arm"]] * Vector3.new(0, -1, 0))
	T.ok((hand2 - rhand).Magnitude > 0.05, "turning the book arm moves it")
	T.eq(S.bj.Part1, S.api.V["Right Arm"], "the book stays in that hand")
	AL.reset(2)

	local handOpt = nil
	for _, o in ipairs(AL.optList) do
		if o[1] == "hand" then
			handOpt = o
		end
	end
	T.ok(handOpt ~= nil and handOpt[3] == "choice", "the Alignment window has a book hand choice")
	T.same(handOpt and handOpt[4], { { "right", "Right" }, { "left", "Left" } }, "right or left")
	T.eq(AL.opts().hand, "right", "the right hand by default")
	AL.setOpt("hand", "left")
	T.eq(AL.opts().hand, "left")
	S.frames(120, "idle")
	T.eq(S.bj.Part1, S.api.V["Left Arm"], "the book moves to the left hand")
	local lc = solve(S.api)
	local lb = root:PointToObjectSpace(lc[S.book].Position)
	T.ok(lb.Z < head.Z - 1.1 and lb.X < 0 and lb.X > -0.6, "still in front of your face, a little to the left: " .. tostring(lb))
	local llh = root:PointToObjectSpace(lc[S.api.V["Left Arm"]] * Vector3.new(0, -1, 0))
	T.ok((llh - lb).Magnitude < 1.3, "the left hand is at the book")
	S.frames(90, "walk")
	local lw = solve(S.api)
	local lt = lw[S.api.V.Torso]
	local lwh = lt:PointToObjectSpace(lw[S.api.V["Left Arm"]] * Vector3.new(0, -1, 0))
	T.ok(lwh.X < -1.2 and lwh.Y > 1, "walking, the left arm holds it up beside your head: " .. tostring(lwh))
	local rwh = lt:PointToObjectSpace(lw[S.api.V["Right Arm"]] * Vector3.new(0, -1, 0))
	T.ok(rwh.Z < -1.2 and rwh.Y < 0.7, "and the right arm is the one held forward: " .. tostring(rwh))
	T.ok(AL.save(), "the choice saves")
	local saved = jsondecode(env.files["BookReaderAlign.json"] or "{}")
	T.eq(saved.hand, "left", "the book hand is in the save file")
	AL.setOpt("hand", "right")
	T.eq(AL.load(), true, "and loads again")
	T.eq(AL.opts().hand, "left", "loading brings the left hand back")
	AL.setOpt("hand", "right")
	S.frames(120, "idle")
	T.eq(S.bj.Part1, S.api.V["Right Arm"], "back in the right hand")

	local svc = A.new({
		fetch = function()
			return true, "return { version = 1, help = {}, slots = {}, rig = {}, scripts = {} }"
		end,
		publish = function(list, info)
			genv.AtsukoAligns = list
			genv.AtsukoAlignment = info
		end,
	})
	svc:load()
	svc:addIds(A.parseAdd("book 555"), { { mesh = "555", tex = "556", name = "Cool Cap" } })
	T.eq(#svc:userRows("scripts", "Book Reader"), 1, "add book <id> gives Book Reader a book")
	S.BR.book.nextScan = 0
	S.BR.findBook()
	T.eq(S.BR.book.e, S.cap, "a book you added comes before one found by its name")
	T.eq(S.BR.book.src, "yours")
	S.frames(2)
	T.eq(S.cj.Part1, S.api.V["Right Arm"], "and goes in your hand")
	T.eq(S.bj.Part1, S.api.V.Head, "the other book goes back where you wear it")
	genv.AtsukoAlignment = nil

	S.BR.stop()
	T.eq(S.cj.Part1, S.api.V.Head, "stopping puts the book back")
	T.eq(genv.AtsukoAlign, nil, "and closes its alignment")
	for _, j in ipairs(S.api.joints) do
		local r = R6[j.Name]
		if r then
			T.ok((j.C0.Position - r[1].Position).Magnitude < 1e-6 and (j.C0.LookVector - r[1].LookVector).Magnitude < 1e-6, j.Name .. " is back at rest")
		end
	end
end
env.run(1)

T.section("book_reader: no book, it says what to wear")
do
	toasts = {}
	local N = run({ noBook = true })
	N.frames(30)
	env.run(5)
	N.frames(5)
	local told = false
	for _, t in ipairs(toasts) do
		if string.find(t, "add book", 1, true) then
			told = true
		end
	end
	T.ok(told, "it tells you to wear a book or add one: " .. table.concat(toasts, " / "))
	T.ok(string.find(N.AL.found(), "not found", 1, true) ~= nil)
	T.eq(N.AL.hat(1), nil)
	N.on = false
	env.run(0.5)
	T.eq(genv.AtsukoBookReader, nil, "when the reanimation ends the script stops by itself")
end

T.section("book_reader: add book and the hub")
do
	local p = A.parseAdd("book 18701259915")
	T.eq(p.use, "book")
	local section, target, _, slot = A.useOf(p.use, 1, 1)
	T.eq(section .. "/" .. target .. "/" .. slot, "script/Book Reader/book", "add book is Book Reader's book")
	T.eq(A.useText(section, target, nil, slot), "Book Reader's book")
	local svc = A.new({
		fetch = function()
			return true, "return { version = 1, help = {}, slots = {}, rig = {}, scripts = {} }"
		end,
		resolveHat = function(id)
			if id == "18701259915" then
				return { mesh = "rbxassetid://881", tex = "rbxassetid://882", name = "\240\159\147\150 How To Read Book" }
			end
			return nil, "no such hat"
		end,
	})
	svc:load()
	local r = svc:addIds(A.parseAdd("18701259915"), {})
	T.eq(r.added[1] and r.added[1].use, "Book Reader's book", "a hat named book goes to Book Reader by itself")
	T.eq(r.added[1] and r.added[1].how, "name")
	T.eq(#r.unsure, 0)
	local Ui = loadmodule("Hub/modules/alignment_ui.lua")
	T.same(Ui.jobsOf("Book Reader"), { "book" }, "the Hats page lists Book Reader")
	T.eq(Ui.jobName("book"), "Book")
	local manifest = jsondecode(readsource("Scripts/manifest.json"))
	local m = manifest.scripts[PATH]
	T.ok(m ~= nil, "Book Reader is in the script list")
	T.eq(m and m.kind, "hat")
	T.same(m and m.reanim, { "atsuko", "fdless" }, "it runs on both hat reanimations")
	T.ok(m and table.find(m.credit, "Dark Eccentric") ~= nil, "credited to Dark Eccentric")
	local credits = jsondecode(readsource("Hub/credits.json"))
	local de = nil
	for _, e in ipairs(credits.people) do
		if e.id == "dark-eccentric" then
			de = e
		end
	end
	T.ok(de ~= nil, "Dark Eccentric is on the credits page")
	T.eq(de and de.links.youtube, "https://www.youtube.com/@DarkEccentric", "with his YouTube channel")
	T.eq(de and de.links.other[1], "https://www.youtube.com/watch?v=221xjv9UYdo", "and the Book Reader video")
	T.same(de and de.usedIn, { "Scripts / Book Reader" })
end

T.section("book_reader: runs on Script Reanimate too")
do
	genv.AtsukoHatFd = nil
	genv.AtsukoAlign = nil
	genv.AtsukoBookReader = nil
	local api = realApi()
	local book, bj = api.hat("Spell Book", "990001", "990002", Vector3.new(1, 1.4, 0.2))
	local live = { isReady = function()
		return true
	end }
	local current = nil
	local stopped = false
	genv.LumenReanim = {
		rig = function()
			return {
				reanimate = function()
					current = live
					return api
				end,
				stopreanimate = function()
					stopped = true
					current = nil
				end,
			}
		end,
		current = function()
			return current
		end,
	}
	local fn = loadstring(readsource(PATH), "=" .. PATH)
	task.spawn(fn)
	env.run(0.2)
	local BR = genv.AtsukoBookReader
	T.ok(BR ~= nil and BR.onFdless == false, "it starts on Script Reanimate")
	for _ = 1, 60 do
		api.modes.default.idle()
		env.frame()
	end
	T.eq(bj.Part1, api.V["Right Arm"], "and a hat named book is in your hand")
	current = nil
	env.run(0.5)
	T.eq(genv.AtsukoBookReader, nil, "it stops when the reanimation ends")
	T.eq(bj.Part1, api.V.Head, "and gives the book back")
	T.eq(stopped, false, "without stopping a reanimation that already ended twice")
	genv.LumenReanim = nil
	T.ok(book ~= nil)
end

genv.AtsukoHatFd = nil
genv.AtsukoAlign = nil
_G.delay = nil
warn = oldWarn
