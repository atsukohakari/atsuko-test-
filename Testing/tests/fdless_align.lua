local A = loadmodule("Hub/modules/alignment.lua")
local shipped = readsource("Reanimation/Hat/FDless.lua")

local startMark = '\tpcall(function()\n\t\tlocal hub=((typeof(getgenv)=="function" and getgenv()) or _G).AtsukoAligns\n'
local stopMark = "\tlocal makePartCons=function(p,t)\n"
local first = string.find(shipped, startMark, 1, true)
T.ok(first ~= nil, "the alignment block is in the shipped FDless")
local last = first and string.find(shipped, stopMark, first, true)
T.ok(last ~= nil, "the block ends before makePartCons")
local block = string.sub(shipped, first, last - 1)
T.eq(select(2, string.gsub(block, "\n", "")) > 20, true)
T.eq(string.find(block, "--", 1, true), nil, "no comments inside the block")

local wrapper = table.concat({
	"local aligns, genv, getPart = ...",
	"local typeof = function(x) return type(x) end",
	"local getgenv = function() return genv end",
	"local tinsert = table.insert",
	"local tclear = function(t) for k in pairs(t) do t[k] = nil end end",
	"local clamp = function(v, lo, hi) if v < lo then return lo elseif v > hi then return hi end return v end",
}, "\n") .. "\n"

local runner, runWhy = loadstring(wrapper .. block, "=fdless_align_block")
T.ok(runner ~= nil, "the block compiles: " .. tostring(runWhy))

local PARTS = {}
for _, name in ipairs({ "Head", "Torso", "Left Arm", "Right Arm", "Left Leg", "Right Leg" }) do
	PARTS[name] = { Name = name }
end
local function getPart(name)
	return PARTS[name]
end

local function run(aligns, hub, mine)
	local genv = { AtsukoAligns = hub, AtsukoScriptAligns = mine }
	runner(aligns, genv, getPart)
	return aligns
end

local function natives()
	return {
		{ PartName = "Head", meshid = "100", textureid = "200", C0 = "head-c0" },
		{ PartName = "Left Arm", meshid = "300", textureid = "400", C0 = "arm-c0" },
		{ PartName = "Torso", meshid = "500", AccessoryName = "Acc", C0 = "torso-c0" },
		{ PartName = "Right Leg", meshid = "600", textureid = "700" },
	}
end

local function partNames(aligns)
	local out = {}
	for index, entry in ipairs(aligns) do
		out[index] = entry.PartName
	end
	return out
end

T.section("fdless align: nothing published")
local plain = run(natives(), nil)
T.same(partNames(plain), { "Head", "Left Arm", "Torso", "Right Leg" })
T.eq(plain[1].p, PARTS.Head)
T.eq(plain[3].p, PARTS.Torso)
T.eq(plain[1].meshid, "100")
T.eq(plain[3].textureid, "", "an entry without a texture gets the empty text, like before")
T.eq(plain[4].meshid, "600")
T.eq(plain[1].off, nil)
T.eq(plain[1].C0, "head-c0")
for _, bad in ipairs({ false, 5, "text", true }) do
	local kept = run(natives(), bad)
	T.same(partNames(kept), { "Head", "Left Arm", "Torso", "Right Leg" }, "a list that is not a table is ignored: " .. tostring(bad))
end
T.same(partNames(run(natives(), {})), { "Head", "Left Arm", "Torso", "Right Leg" }, "an empty list changes nothing")

T.section("fdless align: published rows go first")
local list = {
	{ PartName = "Right Arm", meshid = "900", C0 = "mine-1" },
	{ PartName = "Torso", meshid = "800", textureid = "801", AccessoryName = "Named", C0 = "mine-2" },
}
local mixed = run(natives(), list)
T.same(partNames(mixed), { "Right Arm", "Torso", "Head", "Left Arm", "Torso", "Right Leg" })
T.eq(mixed[1].hub, true)
T.eq(mixed[2].hub, true)
T.eq(mixed[3].hub, nil)
T.eq(mixed[1].C0, "mine-1")
T.eq(mixed[1].p, PARTS["Right Arm"])
T.eq(mixed[1].meshid, "900")
T.eq(mixed[1].textureid, "", "a published row without a texture matches any texture")
T.eq(mixed[2].AccessoryName, "Named")
T.eq(mixed[3].p, PARTS.Head, "entries nobody covers keep working")
T.eq(mixed[3].off, nil)
T.eq(list[1].hub, nil, "the published list itself is not changed")
T.eq(list[1].p, nil)
T.eq(#list, 2)

T.section("fdless align: the running script's own list")
do
	local mine = {
		{ PartName = "Right Arm", meshid = "900", C0 = "script-c0" },
		{ PartName = "Head", meshid = "100", textureid = "200", C0 = "script-head" },
		{ PartName = "Left Leg", AccessoryName = "Wing", C0 = "not a cframe" },
		{ PartName = "Torso" },
		"junk",
	}
	local out = run(natives(), { { PartName = "Head", meshid = "100", textureid = "200", C0 = "yours" } }, mine)
	T.same(partNames(out), { "Head", "Right Arm", "Left Leg", "Head", "Left Arm", "Torso", "Right Leg" }, "yours first, then the script's, then FDless's own")
	T.eq(out[1].C0, "yours", "your row wins over the script's row for the same hat")
	T.eq(out[2].C0, "script-c0", "the script's own hat keeps its alignment")
	T.eq(out[3].C0, "not a cframe", "the C0 is passed on as the script gave it")
	T.eq(out[3].AccessoryName, "Wing")
	T.eq(out[4].off, true, "FDless's own entry for that hat is switched off")
	T.eq(out[4].p, nil)
	T.eq(out[2].p, PARTS["Right Arm"])
	local alone = run(natives(), nil, { { PartName = "Head", meshid = "100", textureid = "200", C0 = "script-head" } })
	T.same(partNames(alone), { "Head", "Head", "Left Arm", "Torso", "Right Leg" })
	T.eq(alone[1].C0, "script-head")
	T.eq(alone[2].off, true, "and the entry it covers is off")
	local none = run(natives(), nil, "not a list")
	T.same(partNames(none), { "Head", "Left Arm", "Torso", "Right Leg" }, "a list that is not a table is ignored")
end

T.section("fdless align: an entry is not used twice")
local twice = run(natives(), {
	{ PartName = "Head", meshid = "100", textureid = "200", C0 = "mine" },
})
T.same(partNames(twice), { "Head", "Head", "Left Arm", "Torso", "Right Leg" })
T.eq(twice[1].hub, true)
T.eq(twice[2].off, true, "the original entry for the same hat is switched off")
T.eq(twice[2].p, nil, "so it can not take a second copy of the hat")
T.eq(twice[3].off, nil)
local other = run(natives(), {
	{ PartName = "Torso", meshid = "100", textureid = "200", C0 = "mine" },
})
T.eq(other[1].PartName, "Torso")
T.eq(other[2].off, nil, "a row for another limb does not switch the original off")
T.eq(other[2].p, PARTS.Head)
local acc = run(natives(), {
	{ PartName = "Torso", meshid = "500", C0 = "mine" },
})
T.eq(acc[4].PartName, "Torso")
T.eq(acc[4].off, nil, "same hat but another accessory name is not the same entry")
local acc2 = run(natives(), {
	{ PartName = "Torso", meshid = "500", AccessoryName = "Acc", C0 = "mine" },
})
T.eq(acc2[4].PartName, "Torso")
T.eq(acc2[4].off, true)
local tex = run(natives(), {
	{ PartName = "Head", meshid = "100", textureid = "201", C0 = "mine" },
})
T.eq(tex[2].off, nil, "same mesh but another texture is not the same entry")
local nomesh = run(natives(), {
	{ PartName = "Right Leg", meshid = "600", C0 = "mine" },
})
T.eq(nomesh[#nomesh].off, nil, "an entry with a texture is not the same as one without")

T.section("fdless align: what counts as naming a hat")
local onlyTexture = run(natives(), { { PartName = "Left Leg", textureid = "31", C0 = "t" } })
T.eq(#onlyTexture, 5, "a texture id alone names a hat")
T.eq(onlyTexture[1].meshid, "")
T.eq(onlyTexture[1].textureid, "31")
local onlyName = run(natives(), { { PartName = "Left Leg", AccessoryName = "Wings", C0 = "n" } })
T.eq(#onlyName, 5, "an accessory name alone names a hat")
T.eq(onlyName[1].AccessoryName, "Wings")
T.eq(onlyName[1].meshid, "")
local glued = run({ { PartName = "Head", meshid = "12", textureid = "3" } }, { { PartName = "Head", meshid = "1", textureid = "23" } })
T.eq(glued[2].off, nil, "12 and 3 are not the same hat as 1 and 23")
local glued2 = run({ { PartName = "Head", meshid = "1", textureid = "23" } }, { { PartName = "Head", meshid = "12", textureid = "3" } })
T.eq(glued2[2].off, nil)
local glued3 = run({ { PartName = "Head", meshid = "1", AccessoryName = "2" } }, { { PartName = "Head", meshid = "1", textureid = "2" } })
T.eq(glued3[2].off, nil, "a texture id is not an accessory name")

T.section("fdless align: several hats for one row")
local counted = run(natives(), {
	{ PartName = "Left Leg", meshid = "1", count = 3, C0 = "c" },
	{ PartName = "Left Leg", meshid = "2", count = 1, C0 = "c" },
	{ PartName = "Left Leg", meshid = "3", count = 99, C0 = "c" },
	{ PartName = "Left Leg", meshid = "4", count = 0, C0 = "c" },
	{ PartName = "Left Leg", meshid = "5", count = "x", C0 = "c" },
	{ PartName = "Left Leg", meshid = "6", count = -4, C0 = "c" },
})
local perMesh = {}
for _, entry in ipairs(counted) do
	if entry.hub then
		perMesh[entry.meshid] = (perMesh[entry.meshid] or 0) + 1
	end
end
T.same(perMesh, { ["1"] = 3, ["2"] = 1, ["3"] = 8, ["4"] = 1, ["5"] = 1, ["6"] = 1 })
local distinct = {}
for _, entry in ipairs(counted) do
	if entry.hub then
		T.eq(distinct[entry], nil, "every copy is its own table")
		distinct[entry] = true
	end
end

T.section("fdless align: running again")
local table1 = natives()
run(table1, { { PartName = "Right Arm", meshid = "900", C0 = "a" }, { PartName = "Head", meshid = "100", textureid = "200" } })
T.eq(#table1, 6)
T.eq(table1[3].off, true)
run(table1, { { PartName = "Right Arm", meshid = "901", C0 = "b" } })
T.same(partNames(table1), { "Right Arm", "Head", "Left Arm", "Torso", "Right Leg" }, "the old published rows are gone, not stacked")
T.eq(table1[1].meshid, "901")
T.eq(table1[2].off, nil, "the original entry works again once nothing covers it")
T.eq(table1[2].p, PARTS.Head)
run(table1, nil)
T.same(partNames(table1), { "Head", "Left Arm", "Torso", "Right Leg" }, "no list brings the table back")
run(table1, { { PartName = "Right Arm", meshid = "901", C0 = "b" } })
run(table1, { { PartName = "Right Arm", meshid = "901", C0 = "b" } })
run(table1, { { PartName = "Right Arm", meshid = "901", C0 = "b" } })
T.eq(#table1, 5, "running three times with the same list adds nothing more")

T.section("fdless align: rows that must not be used")
local rejected = run(natives(), {
	"text",
	5,
	false,
	{},
	{ PartName = "Head" },
	{ PartName = 7, meshid = "1" },
	{ meshid = "1" },
	{ PartName = "Head", meshid = "", textureid = nil, AccessoryName = nil },
	{ PartName = "Left Leg", meshid = "55", C0 = "kept" },
})
T.eq(#rejected, 5, "only the row that names a hat is added")
T.eq(rejected[1].meshid, "55")
T.eq(rejected[1].hub, true)
for _, entry in ipairs(rejected) do
	T.ok(entry.hub or entry.off == nil)
end
local blank = run(natives(), { { PartName = "Head", meshid = "", textureid = "", AccessoryName = nil } })
T.eq(#blank, 4, "an empty id is not an id, or it would match every hat")
local numbers = run(natives(), { { PartName = "Head", meshid = 5 }, { PartName = "Head", textureid = {} } })
T.eq(#numbers, 4, "ids have to be text")

T.section("fdless align: a broken list never breaks FDless")
local breaking = natives()
local result = run(breaking, { { PartName = "Head", meshid = "5", textureid = {}, C0 = "x" } })
T.eq(#result, 4, "the table is left alone when the block fails")
T.eq(result[1].hub, nil)
T.same(partNames(result), { "Head", "Left Arm", "Torso", "Right Leg" })
local weird = natives()
local ok = pcall(runner, weird, setmetatable({}, { __index = function() error("blocked") end }), getPart)
T.eq(ok, true, "an error while reading the list is caught")
T.same(partNames(weird), { "Head", "Left Arm", "Torso", "Right Leg" })
T.eq(weird[1].p, PARTS.Head, "and the original table is still set up as usual")

T.section("fdless align: how an accessory is matched")
local function take(aligns, meshid, textureid, name)
	for _, l in next, aligns do
		if l.p and string.find(meshid, l.meshid) and string.find(textureid, l.textureid) and ((not l.AccessoryName) or (l.AccessoryName == name)) then
			l.p = nil
			return l
		end
	end
	return nil
end
local probe = run(natives(), {
	{ PartName = "Right Arm", meshid = "100", C0 = "mine" },
})
local one = take(probe, "100", "200", "Anything")
T.eq(one.PartName, "Right Arm", "your row is checked before the originals")
T.eq(one.C0, "mine")
local two = take(probe, "100", "200", "Anything")
T.eq(two.PartName, "Head", "a second copy of the hat falls through to the original")
T.eq(take(probe, "100", "200", "Anything"), nil, "and a third copy finds nothing")
local named = run(natives(), {})
T.eq(take(named, "500", "", "Other"), nil)
T.eq(take(named, "500", "", "Acc").PartName, "Torso")

local function matrix(r, p)
	return { r = r, p = p }
end
local function identity()
	return matrix({ 1, 0, 0, 0, 1, 0, 0, 0, 1 }, { 0, 0, 0 })
end
local MT = {}
MT.__mul = function(a, b)
	local ar, br = a.r, b.r
	local r = {}
	for i = 0, 2 do
		for j = 0, 2 do
			local s = 0
			for k = 0, 2 do
				s = s + ar[i * 3 + k + 1] * br[k * 3 + j + 1]
			end
			r[i * 3 + j + 1] = s
		end
	end
	local p = {}
	for i = 0, 2 do
		p[i + 1] = a.p[i + 1] + ar[i * 3 + 1] * b.p[1] + ar[i * 3 + 2] * b.p[2] + ar[i * 3 + 3] * b.p[3]
	end
	return setmetatable(matrix(r, p), MT)
end
local function cfNew(x, y, z)
	local m = identity()
	m.p = { x, y, z }
	return setmetatable(m, MT)
end
local function cfAngles(rx, ry, rz)
	local cx, sx, cy, sy, cz, sz = math.cos(rx), math.sin(rx), math.cos(ry), math.sin(ry), math.cos(rz), math.sin(rz)
	local mx = setmetatable(matrix({ 1, 0, 0, 0, cx, -sx, 0, sx, cx }, { 0, 0, 0 }), MT)
	local my = setmetatable(matrix({ cy, 0, sy, 0, 1, 0, -sy, 0, cy }, { 0, 0, 0 }), MT)
	local mz = setmetatable(matrix({ cz, -sz, 0, sz, cz, 0, 0, 0, 1 }, { 0, 0, 0 }), MT)
	return mx * my * mz
end
local function cfMake(x, y, z, rx, ry, rz)
	return cfNew(x, y, z) * cfAngles(math.rad(rx), math.rad(ry), math.rad(rz))
end
local function sameMatrix(a, b)
	a, b = a or identity(), b or identity()
	for i = 1, 9 do
		if math.abs(a.r[i] - b.r[i]) > 0.0005 then
			return false
		end
	end
	for i = 1, 3 do
		if math.abs(a.p[i] - b.p[i]) > 0.0005 then
			return false
		end
	end
	return true
end

local startAligns = string.find(shipped, "local aligns={", 1, true)
local endAligns = string.find(shipped, "\n}\n", startAligns, true)
local aligns = string.sub(shipped, startAligns + #"local aligns=", endAligns + 2)
local compiled, compileWhy = loadstring("local cf, angles, cfMul = ...\nreturn " .. aligns, "=fdless_native")
T.ok(compiled ~= nil, "the original table compiles: " .. tostring(compileWhy))
local function nativeTable()
	return compiled(cfNew, cfAngles, function(a, b)
		return a * b
	end)
end
local nativeCount = #nativeTable()
T.eq(nativeCount, 67)

local real = A.clean(A.parse(readsource("Alignment/alignment.lua")))
local published = A.entries(real, cfMake, {})
T.eq(#published, nativeCount + 4 + 99, "FDless's own entries plus the four fedoras of Master Chief's free rig and the hats from Uhhhhhh's hat map FDless doesn't know")

T.section("fdless align: the shipped alignment file changes nothing for the original hats")
local plainTable = nativeTable()
run(plainTable, nil)
local seenTotal = 0
for index, entry in ipairs(nativeTable()) do
	local mesh, tex, name = entry.meshid or "", entry.textureid or "", entry.AccessoryName or "AnyName"
	local before = run(nativeTable(), nil)
	local after = run(nativeTable(), published)
	T.eq(#after, #before + #published, "native entry " .. index .. ": the table grew by the published rows")
	for copy = 1, 3 do
		local a, b = take(before, mesh, tex, name), take(after, mesh, tex, name)
		seenTotal += 1
		T.eq(b ~= nil, a ~= nil, "entry " .. index .. " copy " .. copy .. ": found or not found")
		if a and b then
			T.eq(b.PartName, a.PartName, "entry " .. index .. " copy " .. copy .. ": limb")
			T.ok(sameMatrix(a.C0, b.C0), "entry " .. index .. " copy " .. copy .. ": alignment")
		end
	end
end
T.eq(seenTotal, nativeCount * 3)

T.section("fdless align: your own rows on top of the shipped file")
local env = {
	published = nil,
	api = {},
}
env.api.fetch = function()
	return true, readsource("Alignment/alignment.lua")
end
env.api.cframe = cfMake
env.api.publish = function(list)
	env.published = list
end
local svc = A.new(env.api)
svc:load()
T.eq(#env.published, nativeCount + 4 + 99, "FDless's own hats, Master Chief's fedoras and the hats from Uhhhhhh's hat map FDless doesn't know")
local firstNative = nativeTable()[1]
local firstMesh, firstTex = firstNative.meshid, firstNative.textureid
local probeTex = firstTex or ""
local moved = svc:add("rig", nil, { part = "Right Leg", mesh = firstMesh, tex = firstTex, align = { 0, 1, 0, 0, 0, 0 } })
T.eq(moved, true)
local withMine = run(nativeTable(), env.published)
T.eq(withMine[1].PartName, "Right Leg", "your row is first")
local got1 = take(withMine, firstMesh, probeTex, "x")
T.eq(got1.PartName, "Right Leg")
local got2 = take(withMine, firstMesh, probeTex, "x")
T.eq(got2.PartName, firstNative.PartName, "the second copy of the hat goes where it always went")
local got3 = take(withMine, firstMesh, probeTex, "x")
T.eq(got3, nil)

local sameLimb = svc:add("rig", nil, { part = firstNative.PartName, mesh = firstMesh, tex = firstTex, align = { 0, 2, 0, 0, 0, 0 } })
T.eq(sameLimb, true)
local withSame = run(nativeTable(), env.published)
local s1 = take(withSame, firstMesh, probeTex, "x")
T.eq(s1.PartName, "Right Leg", "your rows are used in the order you added them")
local s2 = take(withSame, firstMesh, probeTex, "x")
T.eq(s2.PartName, firstNative.PartName)
T.ok(sameMatrix(s2.C0, cfMake(0, 2, 0, 0, 0, 0)), "your row for the same limb replaces the original alignment")
T.eq(take(withSame, firstMesh, probeTex, "x"), nil, "and the original entry is not used as well")

T.section("fdless align: a brand new hat from a hat id")
local env2 = { hats = { ["777"] = { mesh = "rbxassetid://424242", tex = "rbxassetid://434343", name = "New Sword" } } }
env2.api = {
	cframe = cfMake,
	publish = function(list)
		env2.published = list
	end,
	resolveHat = function(id)
		return env2.hats[id]
	end,
}
local svc2 = A.new(env2.api)
svc2:load()
T.eq(#env2.published, 0, "no shipped file and nothing of yours yet")
svc2:add("rig", nil, { part = "Left Arm", hat = "777", align = { 1, 2, 3, 0, 90, 0 } })
T.eq(#env2.published, 0, "a hat id waits until the game has looked it up")
local looked = svc2:resolve("777")
T.eq(looked.mesh, "424242")
T.eq(#env2.published, 1)
local fresh = run(nativeTable(), env2.published)
local newHat = take(fresh, "http://www.roblox.com/asset/?id=424242", "http://www.roblox.com/asset/?id=434343", "Any")
T.ok(newHat ~= nil, "FDless matches the hat by the digits inside its mesh text")
T.eq(newHat.PartName, "Left Arm")
T.ok(sameMatrix(newHat.C0, cfMake(1, 2, 3, 0, 90, 0)))
