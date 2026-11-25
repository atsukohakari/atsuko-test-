local source = readsource("Hub/Reanimate.lua")

local function slice(from, to)
	local first = string.find(source, from, 1, true)
	T.ok(first ~= nil, "found in Reanimate.lua: " .. from)
	if not first then
		return ""
	end
	local last = string.find(source, to, first, true)
	T.ok(last ~= nil, "found in Reanimate.lua: " .. to)
	if not last then
		return ""
	end
	return string.sub(source, first, last - 1)
end

local chunk = slice("local ALIGN_COPIES = 8", "local module = {version = VERSION}")
local build, err = loadstring("local min, max = math.min, math.max\n" .. chunk .. "\nreturn mergeAligns", "=mergeAligns")
T.ok(build ~= nil, "the merge function compiles: " .. tostring(err))
local merge = build and build() or function()
	return {}
end

local function count(t)
	local n = 0
	for _ in pairs(t) do
		n += 1
	end
	return n
end

T.section("lumen align: nothing to merge")
T.eq(count(merge(nil, nil)), 0)
T.eq(count(merge("text", nil)), 0)
T.eq(count(merge(5, nil)), 0)
T.eq(count(merge({}, nil)), 0)
T.eq(count(merge({ {} }, nil)), 0, "a list with nothing usable gives nothing")
T.eq(count(merge(nil, "text")), 0)
T.eq(count(merge(nil, 5)), 0)
T.eq(count(merge(nil, {})), 0)
T.eq(type(merge(nil, nil)), "table", "there is always a list to read")

T.section("lumen align: entries are copied")
local c0 = { opaque = true }
local shared = {
	{ PartName = "Head", meshid = "11", textureid = "22", AccessoryName = "Acc", C0 = c0, extra = "dropped", hub = true },
	{ PartName = "Torso", meshid = "33" },
	{ PartName = "Left Arm", textureid = "44" },
	{ PartName = "Right Arm", AccessoryName = "Wings" },
}
local list = merge(shared, nil)
T.eq(#list, 4)
T.eq(list[1].PartName, "Head")
T.eq(list[1].meshid, "11")
T.eq(list[1].textureid, "22")
T.eq(list[1].AccessoryName, "Acc")
T.eq(list[1].C0, c0, "the alignment value itself is passed through")
T.eq(list[1].extra, nil, "only the fields a reanimate reads are copied")
T.eq(list[1].hub, nil)
T.eq(list[1] ~= shared[1], true, "every entry is a fresh table")
T.eq(list[2].C0, nil)
T.eq(list[3].textureid, "44")
T.eq(list[4].AccessoryName, "Wings")
T.eq(shared[1].extra, "dropped", "the published list is not changed")
T.eq(#shared, 4)

T.section("lumen align: entries that are not used")
local mixed = merge({
	"text",
	5,
	false,
	{},
	{ PartName = "Head" },
	{ PartName = "Head", meshid = "" },
	{ PartName = "Head", meshid = "", textureid = "", AccessoryName = "" },
	{ PartName = "Head", meshid = 5 },
	{ PartName = "Head", meshid = {} },
	{ PartName = 7, meshid = "1" },
	{ meshid = "1" },
	{ PartName = "Left Leg", meshid = "9" },
}, nil)
T.eq(#mixed, 1)
T.eq(mixed[1].PartName, "Left Leg")

T.section("lumen align: several hats for one entry")
local function copies(n)
	return #merge({ { PartName = "Head", meshid = "1", count = n } }, nil)
end
T.eq(copies(nil), 1)
T.eq(copies(1), 1)
T.eq(copies(2), 2)
T.eq(copies(3), 3)
T.eq(copies(8), 8)
T.eq(copies(9), 8)
T.eq(copies(99), 8)
T.eq(copies(0), 1)
T.eq(copies(-4), 1)
T.eq(copies(2.9), 2)
T.eq(copies(0 / 0), 1)
T.eq(copies("3"), 1)
T.eq(copies(true), 1)
local expanded = merge({ { PartName = "Head", meshid = "1", count = 2, C0 = c0 } }, nil)
T.eq(expanded[1] ~= expanded[2], true, "copies are separate tables")
T.eq(expanded[2].C0, c0)

T.section("lumen align: the size is limited")
local big = {}
for i = 1, 800 do
	big[i] = { PartName = "Head", meshid = tostring(i) }
end
T.eq(#merge(big, nil), 700)
local counted = {}
for i = 1, 100 do
	counted[i] = { PartName = "Head", meshid = tostring(i), count = 8 }
end
T.eq(#merge(counted, nil), 700)
local exact = {}
for i = 1, 700 do
	exact[i] = { PartName = "Head", meshid = tostring(i) }
end
T.eq(#merge(exact, nil), 700)
local oneLess = {}
for i = 1, 699 do
	oneLess[i] = { PartName = "Head", meshid = tostring(i) }
end
T.eq(#merge(oneLess, nil), 699)
local oneMore = {}
for i = 1, 701 do
	oneMore[i] = { PartName = "Head", meshid = tostring(i) }
end
T.eq(#merge(oneMore, nil), 700)
local lastCopies = {}
for i = 1, 699 do
	lastCopies[i] = { PartName = "Head", meshid = tostring(i) }
end
lastCopies[700] = { PartName = "Head", meshid = "x", count = 8 }
T.eq(#merge(lastCopies, nil), 700, "the copies of the last entry stop at the limit")

T.section("lumen align: the script's own list goes after yours")
local own = { { PartName = "Torso", meshid = "own1" }, { PartName = "Head", mesh = "own2" } }
local both = merge({ { PartName = "Head", meshid = "mine", count = 2 } }, own)
T.eq(#both, 4)
T.eq(both[1].meshid, "mine")
T.eq(both[2].meshid, "mine")
T.eq(both[3], own[1], "the script's entries are handed on as they are")
T.eq(both[4], own[2])
T.eq(#own, 2)
local onlyOwn = merge(nil, own)
T.eq(#onlyOwn, 2)
T.eq(onlyOwn[1], own[1])
local full = merge(big, own)
T.eq(#full, 702, "the script's own entries are not cut by the limit")
T.eq(full[701], own[1])
local odd = merge(nil, { "text", 5, false })
T.eq(#odd, 3, "odd entries are left for the reader to skip")

T.section("lumen align: how Reanimate uses it")
local function occurrences(text)
	local n, from = 0, 1
	while true do
		local a, b = string.find(source, text, from, true)
		if not a then
			return n
		end
		n += 1
		from = b + 1
	end
end
T.eq(occurrences("local VERSION = 10\n"), 1, "this is version 10: it knows which hats are body parts and lets a hat you added as a weapon go, on top of version 9")
T.eq(occurrences("		touch = settings.touch == true,\n"), 1, "the FDless style touch stick and jump spot are off unless a caller asks for them")
T.eq(occurrences("	if opt.touch then\n		on(UserInputService.TouchStarted"), 1, "and the touch handlers only exist when asked for")
T.ok(occurrences("return c:GetMoveVector()") == 1 and occurrences("local t = c.touchJumpController") == 1, "so walking and jumping on a phone come from Roblox's own thumbstick and jump button, like Uhhhhhh")
T.eq(occurrences("settings.aligns"), 2, "the script's own list is read when a body is made and when one is handed over")
T.eq(occurrences("local alignList = mergeAligns(env.AtsukoAligns, settings.aligns)"), 1)
T.eq(occurrences("pcall(live.handoff, settings.aligns)"), 1)
T.eq(occurrences("ipairs(alignList)"), 1, "the preset way reads the merged list")
T.eq(occurrences("addAligns(alignList)"), 1, "and the FDless way reads it through addAligns")
T.eq(occurrences("addAligns(mergeAligns(env.AtsukoAligns, own))"), 1, "a hand over builds the same merged list")
T.eq(occurrences("mergeAligns("), 3)

T.section("lumen align: switching scripts keeps the same body")
T.eq(occurrences("module.hold = function(on)"), 1, "the hub can hold the body while one script lets go")
T.eq(occurrences("if not active or held then\n\t\t\treturn false"), 1, "a stop while held does nothing")
local handAt = string.find(source, "local function handoff(own)", 1, true)
T.ok(handAt ~= nil, "there is a hand over")
local handBody = handAt and string.sub(source, handAt, (string.find(source, "\n\tlive = {", handAt, true) or handAt)) or ""
T.ok(string.find(handBody, "table.clear(modes)", 1, true) ~= nil, "the old script's modes are dropped")
T.ok(string.find(handBody, "defaultMode = {}", 1, true) ~= nil, "and its default mode")
T.ok(string.find(handBody, "local d = compatJoint(e, h, acc)", 1, true) ~= nil, "every hat goes back to where the new list puts it")
T.eq(occurrences("\t\thandoff = handoff,\n"), 1, "the body carries it")
local reAt = string.find(source, "local function reanimate(settings)", 1, true)
local freshAt = reAt and string.find(source, "if fresh then", reAt, true)
local returnAt = reAt and string.find(source, "return live", reAt, true)
T.ok(freshAt ~= nil and returnAt ~= nil and freshAt < returnAt, "the next script to ask gets the standing body with its own hats")
T.eq(occurrences("if not opt.compat then\n\t\tfor _, a in ipairs(alignList) do"), 1, "the preset reader only runs when the FDless way is off")

T.section("lumen align: weapons while you dance")
T.eq(occurrences("local function armsOn()"), 1, "Script Reanimate picks a gun and a sword when a dance starts")
T.eq(occurrences("\t\t\tarmsOn()\n\t\telse\n\t\t\tarmsOff()\n"), 1, "and lets them go when it ends")
T.eq(occurrences("local kit = env.AtsukoEmoteWeapons"), 1, "it asks the hub what a weapon is and where it goes")
local slotAt = string.find(source, "\n\tfunction slotTarget(s)", 1, true)
local weaponAt = slotAt and string.find(source, "local w = s.weapon", slotAt, true)
local entryAt = slotAt and string.find(source, "if s.entry then", slotAt, true)
T.ok(weaponAt ~= nil and entryAt ~= nil and weaponAt < entryAt, "a weapon's spot wins over everything else while dancing")
T.eq(occurrences("if not s.limbName and s.part and not s.weapon then"), 1, "only loose hats, never a body part")

T.section("lumen align: the provider adds nothing")
local Atsuko = loadmodule("Reanimation/providers/atsuko.lua")
T.eq(Atsuko.aligns, nil, "the provider no longer copies the list")
T.eq(Atsuko.NEED, 10, "it asks for version 10, so an older copy left in memory is replaced")
Atsuko.init({ G = { AtsukoAligns = { { PartName = "Head", meshid = "5" } } }, genv = {} })
local cfg = Atsuko.config({ placeholders = false, aligns = { { PartName = "Torso", meshid = "6" } } })
T.eq(cfg.aligns, nil, "nothing is passed on, so the list is not counted twice")
T.eq(cfg.placeholders, false)
T.eq(count(cfg), 5, "the five settings and nothing else")
T.eq(count(Atsuko.config(nil)), 5)
Atsuko.init(nil)
T.eq(count(Atsuko.config({})), 5, "without a context the settings still come out")

T.section("lumen align: the rig has what the newer scripts call")
for _, name in ipairs({ "setCamOverride", "setCamZoom", "getCamZoom", "getAntivoid", "setAntivoid", "setInputBlocker", "setShiftlock", "getShiftlock" }) do
	T.ok(string.find(source, "\t\t\t" .. name .. " = function(", 1, true) ~= nil, name .. " is on the rig")
end
T.ok(string.find(source, "Enum.RenderPriority.Camera.Value - 1", 1, true) ~= nil, "the camera is put back before Roblox moves it, so an override never adds up")
T.ok(string.find(source, "Enum.RenderPriority.Camera.Value + 2", 1, true) ~= nil, "and the override runs after it")
T.ok(string.find(source, "pcall(RunService.UnbindFromRenderStep, RunService, camOver.post)", 1, true) ~= nil, "it is unbound again")

T.section("lumen align: the camera stays on the rig when the real body respawns")
local guardAt = string.find(source, "RunService:BindToRenderStep(camOver.guard, Enum.RenderPriority.Camera.Value - 2, function()", 1, true)
T.ok(guardAt ~= nil, "a check runs every frame before Roblox moves the camera")
T.ok(string.find(source, "pre = randomName(), post = randomName(), guard = randomName(), keep = randomName(), hold = 0, look = nil }", 1, true) ~= nil, "the checks have their own random names")
T.eq(occurrences("pcall(RunService.UnbindFromRenderStep, RunService, camOver.guard)"), 1, "it is unbound when the reanimation stops")
local stopAt = string.find(source, "pcall(RunService.UnbindFromRenderStep, RunService, camOver.guard)", 1, true)
local giveBack = string.find(source, "cam.CameraSubject = realHum", 1, true)
T.ok(stopAt ~= nil and giveBack ~= nil and stopAt < giveBack, "before the camera is given back to the real body")
T.eq(occurrences("if ownSubject(s) then"), 1, "the property signal uses the same check")
T.eq(occurrences("if active and c and c.CameraSubject ~= hum and ownSubject(c.CameraSubject) then"), 1)
T.eq(occurrences("if opt.hideHealthGui and healthWas ~= nil then\n\t\t\tpcall(StarterGui.SetCoreGuiEnabled, StarterGui, Enum.CoreGuiType.Health, false)"), 1, "each new body hides the health bar again, so its red hurt flash never shows")

T.ok(string.find(source, "on(Workspace.ChildAdded, function(c)\n\t\tif active and c ~= rig and c.Name == lp.Name and c:IsA(\"Model\") then", 1, true) ~= nil, "a new body is noticed the moment it appears, before Roblox calls it your character")
T.eq(occurrences("refreshFilter(c)"), 1, "and the rig's feet stop seeing it at once")
T.ok(string.find(source, "RunService:BindToRenderStep(camOver.keep, Enum.RenderPriority.Camera.Value + 1, function()", 1, true) ~= nil, "the camera direction is checked right after Roblox moves the camera")
T.eq(occurrences("pcall(RunService.UnbindFromRenderStep, RunService, camOver.keep)"), 1, "and unbound on stop")
T.eq(occurrences("camOver.hold = clock() + 1.5"), 2, "a respawn opens a short window, from the new body and from the character change")

local function inst(name, class, parent)
	local o = { Name = name, ClassName = class, Parent = parent, kind = "Instance", kids = {} }
	if parent then
		parent.kids[#parent.kids + 1] = o
	end
	function o:IsA(c)
		return self.ClassName == c
	end
	function o:FindFirstAncestorOfClass(c)
		local p = self.Parent
		while p do
			if p.ClassName == c then
				return p
			end
			p = p.Parent
		end
		return nil
	end
	function o:FindFirstChildOfClass(c)
		for _, k in ipairs(self.kids) do
			if k.ClassName == c then
				return k
			end
		end
		return nil
	end
	return o
end
local function kind(v)
	return type(v) == "table" and v.kind or type(v)
end

local subjectSrc = slice("\tlocal function bodyModel(m)", "\tlocal function watchCamera()")
local makeOwn, ownErr = loadstring("local rig, lp, seenChars, typeof = ...\n" .. subjectSrc .. "\nreturn ownSubject", "=ownSubject")
T.ok(makeOwn ~= nil, "the check compiles: " .. tostring(ownErr))
if makeOwn then
	local rigModel = inst("Rig7f2", "Model")
	inst("Humanoid", "Humanoid", rigModel)
	local rigHead = inst("Head", "Part", rigModel)
	local oldBody = inst("Atsuko", "Model")
	local oldHum = inst("Humanoid", "Humanoid", oldBody)
	local current = inst("Atsuko", "Model")
	local currentHum = inst("Humanoid", "Humanoid", current)
	local hat = inst("Hat", "Accessory", current)
	local handle = inst("Handle", "Part", hat)
	local fresh = inst("Atsuko", "Model")
	local freshHum = inst("Humanoid", "Humanoid", fresh)
	local freshHead = inst("Head", "Part", fresh)
	local other = inst("Someone", "Model")
	inst("Humanoid", "Humanoid", other)
	local otherHead = inst("Head", "Part", other)
	local prop = inst("Atsuko", "Model")
	local propPart = inst("Part", "Part", prop)
	local lpFake = { Name = "Atsuko", Character = current }
	local seen = { [oldBody] = true, [current] = true }
	local own = makeOwn(rigModel, lpFake, seen, kind)
	T.eq(own(nil), true, "no subject goes back to the rig")
	T.eq(own(rigModel), true)
	T.eq(own(currentHum), true, "your current body goes back to the rig")
	T.eq(own(current), true)
	T.eq(own(handle), true, "so does a hat on it")
	T.eq(own(oldHum), true, "and an old body")
	T.eq(own(freshHum), true, "a body that just spawned goes back too, even before Roblox calls it your character (this was the jump)")
	T.eq(own(freshHead), true)
	T.eq(own(fresh), true)
	T.eq(own(otherHead), false, "someone else is left alone, so spectating works")
	T.eq(own(rigHead), false, "a script looking at a rig part is left alone")
	T.eq(own(propPart), false, "a model with your name but no humanoid is left alone")
	T.eq(own(inst("Loose", "Part")), false)
	T.eq(own("text"), false, "odd values are left alone")
end

local function vec(x, y, z)
	local v = { X = x, Y = y, Z = z }
	return setmetatable(v, {
		__add = function(a, b)
			return vec(a.X + b.X, a.Y + b.Y, a.Z + b.Z)
		end,
		__sub = function(a, b)
			return vec(a.X - b.X, a.Y - b.Y, a.Z - b.Z)
		end,
		__mul = function(a, b)
			if type(a) == "number" then
				return vec(b.X * a, b.Y * a, b.Z * a)
			end
			return vec(a.X * b, a.Y * b, a.Z * b)
		end,
		__index = function(t, k)
			if k == "Magnitude" then
				return math.sqrt(t.X * t.X + t.Y * t.Y + t.Z * t.Z)
			elseif k == "Dot" then
				return function(a, b)
					return a.X * b.X + a.Y * b.Y + a.Z * b.Z
				end
			end
			return nil
		end,
	})
end
local function unit(v)
	local m = v.Magnitude
	return vec(v.X / m, v.Y / m, v.Z / m)
end
local FakeCF = {}
function FakeCF.lookAt(from, to)
	return { Position = from, LookVector = unit(to - from) }
end
local keepSrc = slice("\tlocal function keepLook(c, now)", "\tlocal function settle()")
local makeKeep, keepErr = loadstring("local camOver, hum, CFrame = ...\n" .. keepSrc .. "\nreturn keepLook", "=keepLook")
T.ok(makeKeep ~= nil, "the direction keeper compiles: " .. tostring(keepErr))
if makeKeep then
	local rigHum = { kind = "Humanoid" }
	local over = { hold = 0, look = nil }
	local keep = makeKeep(over, rigHum, FakeCF)
	local focus = vec(0, 5, 0)
	local cam = { CameraSubject = rigHum, Focus = { Position = focus }, CFrame = FakeCF.lookAt(vec(0, 5, 10), focus) }
	T.eq(keep(cam, 1), false, "a normal frame is only remembered")
	T.ok(over.look ~= nil and math.abs(over.look.Z + 1) < 1e-6, "the direction is kept")
	cam.CFrame = FakeCF.lookAt(vec(10, 5, 0), focus)
	T.eq(keep(cam, 2), false, "outside a respawn the player turning the camera is never undone")
	T.ok(math.abs(over.look.X + 1) < 1e-6)
	over.hold = 10
	cam.CFrame = FakeCF.lookAt(vec(9.9, 6, 1), focus)
	T.eq(keep(cam, 3), false, "a small turn inside the window is fine")
	local before = over.look
	cam.CFrame = FakeCF.lookAt(vec(0, 0.2, 0), vec(0, -10, 0.01))
	T.eq(keep(cam, 4), true, "inside the window a big snap (Roblox turning the camera to the new body) is undone")
	T.ok(math.abs(cam.CFrame.LookVector.X - before.X) < 1e-6 and math.abs(cam.CFrame.LookVector.Z - before.Z) < 1e-6, "back to the direction from the frame before")
	local dist = (cam.CFrame.Position - focus).Magnitude
	T.ok(dist > 0.05, "the distance stays (third person)")
	cam.CameraSubject = { kind = "Humanoid" }
	cam.CFrame = FakeCF.lookAt(vec(-10, 5, 0), focus)
	T.eq(keep(cam, 5), false, "when the camera is on something else (spectating) it is left alone")
	cam.CameraSubject = rigHum
	over.look = vec(0, 0, -1)
	cam.Focus = { Position = vec(0, 5, 0) }
	cam.CFrame = FakeCF.lookAt(vec(0, 5, 0.01), vec(-1, 5, 0.01))
	T.eq(keep(cam, 6), true, "first person is undone too")
	T.ok(cam.CFrame.Position.X == cam.CFrame.Position.X, "with real numbers")
	cam.CFrame = FakeCF.lookAt(vec(10, 5, 0), focus)
	T.eq(keep(cam, 20), false, "after the window nothing is undone")
	T.ok(math.abs(cam.CFrame.LookVector.X + 1) < 1e-6, "and the camera keeps the new direction")
end
