local src = readsource("Hub/AtsukoHub.lua")
local from = string.find(src, "\tlocal function parts(v)", 1, true)
T.section("version_compare: the real helpers are found in the hub")
T.ok(from ~= nil, "parts helper present")
local _, upto = string.find(src, "\tfunction Ver%.cmp%(a, b%)\n.-\n\tend\n", from or 1)
T.ok(upto ~= nil, "Ver.cmp present")
local chunk = "local Ver = {}\ndo\n" .. string.sub(src, from, upto) .. "end\nreturn Ver"
local build = loadstring(chunk)
T.ok(type(build) == "function", "extracted block compiles")
local Ver = build()
local cmp = Ver.cmp

T.section("version_compare: ordering")
T.eq(cmp("1.5.0", "1.3.0"), 1)
T.eq(cmp("1.3.0", "1.2.9"), 1)
T.eq(cmp("1.5.0", "1.2.9"), 1)
T.eq(cmp("1.10.0", "1.9.0"), 1)
T.eq(cmp("1.9.0", "1.10.0"), -1)
T.eq(cmp("1.2.9", "1.5.0"), -1)
T.eq(cmp("1.3.0", "1.3.0"), 0)
T.eq(cmp("2.0.0", "1.99.99"), 1)
T.eq(cmp("1.99.99", "2.0.0"), -1)
T.eq(cmp("0.0.1", "0.0.0"), 1)
T.eq(cmp("1.5.10", "1.5.9"), 1)
T.eq(cmp("1.5.9", "1.5.10"), -1)
T.eq(cmp("10.0.0", "9.9.9"), 1)

T.section("version_compare: short, padded and messy input")
T.eq(cmp("1.3", "1.3.0"), 0)
T.eq(cmp("1.3.1", "1.3"), 1)
T.eq(cmp("1", "1.0.0"), 0)
T.eq(cmp("v1.5.0", "1.5.0"), 0)
T.eq(cmp("Beta v1.5.0", "1.4.9"), 1)
T.eq(cmp("1.5.0\n", "1.5.0"), 0)
T.eq(cmp("  1.5.0  ", "1.5.0"), 0)
T.eq(cmp("", "1.0.0"), -1)
T.eq(cmp(nil, "1.0.0"), -1)
T.eq(cmp("1.0.0", nil), 1)
T.eq(cmp(nil, nil), 0)
T.eq(cmp("001.005.000", "1.5.0"), 0)

T.section("version_compare: antisymmetry and transitivity over a grid")
local grid = {}
for a = 0, 3 do
	for b = 0, 12 do
		for c = 0, 11 do
			grid[#grid + 1] = a .. "." .. b .. "." .. c
		end
	end
end
local bad = 0
for i = 1, #grid, 7 do
	for j = 1, #grid, 11 do
		if cmp(grid[i], grid[j]) ~= -cmp(grid[j], grid[i]) then
			bad = bad + 1
		end
	end
end
T.eq(bad, 0)
local ordered = 0
for i = 2, #grid do
	if cmp(grid[i], grid[i - 1]) == 1 then
		ordered = ordered + 1
	end
end
T.eq(ordered, #grid - 1, "the grid is generated in ascending order")

T.section("version_compare: the shipped version lines agree")
local fileVersion = readsource("Hub/version.txt")
local hubVersion = string.match(src, 'local HUB_VERSION = "([%d%.]+)"')
local changelogTop = string.match(src, 'Core%.CHANGELOG = {%s*{ version = "([%d%.]+)"')
local txtTop = string.match(readsource("Hub/changelog.txt"), "^v([%d%.]+)\n")
T.eq(fileVersion, hubVersion, "version.txt matches HUB_VERSION exactly")
T.eq(changelogTop, hubVersion, "top Core.CHANGELOG entry matches")
T.eq(txtTop, hubVersion, "top changelog.txt block matches")
T.eq(string.match(src, "\n\tatsuko hub v([%d%.]+)\n"), hubVersion, "header comment matches")
T.eq(hubVersion, "1.6.1")
T.eq(cmp(hubVersion, "1.3.0"), 1)
