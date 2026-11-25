local Targets = loadmodule("Hub/modules/cmds/_targets.lua")

local function player(name, display, id, team, x)
	return { Name = name, DisplayName = display, UserId = id, Team = team and { Name = team } or nil, x = x or 0 }
end

local me = player("Atsuko", "Atsuko", 1, "Red", 0)
local john = player("john_doe", "Johnny", 2, "Red", 10)
local johan = player("Johan99", "Johan", 3, "Blue", 25)
local bob = player("BobTheBuilder", "Bob", 4, "Blue", 5)
local zed = player("zed", "Zed", 5, nil, 90)
local list = { me, john, johan, bob, zed }

local friends = { [2] = true, [4] = true }

local function ctx(extra)
	local c = {
		me = me,
		players = list,
		distance = function(p)
			return math.abs(p.x - me.x)
		end,
		isFriend = function(p)
			return friends[p.UserId] == true
		end,
		rand = function(n)
			return 1
		end,
	}
	for k, v in pairs(extra or {}) do
		c[k] = v
	end
	return c
end

local function names(res)
	return Targets.names(res.players)
end

T.section("targets: split")
T.same(Targets.split("all -me  -john"), { "all", "-me", "-john" })
T.same(Targets.split(""), {})
T.same(Targets.split(nil), {})
T.same(Targets.split("  one  "), { "one" })

T.section("targets: single names")
T.eq(names(Targets.resolve("zed", ctx())), "zed", "exact name")
T.eq(names(Targets.resolve("ZED", ctx())), "zed", "case does not matter")
T.eq(names(Targets.resolve("Johnny", ctx())), "john_doe", "display name")
T.eq(names(Targets.resolve("bob", ctx())), "BobTheBuilder", "partial name")
T.eq(names(Targets.resolve("uild", ctx())), "BobTheBuilder", "middle of a name")
T.eq(names(Targets.resolve("joh", ctx())), "Johan99", "closest of several: the shorter name wins")
T.ok(#Targets.resolve("joh", ctx()).notes == 1, "and it says it picked")
T.ok(string.find(Targets.resolve("joh", ctx()).notes[1], "2 matches", 1, true) ~= nil, "with the number of matches")
T.eq(names(Targets.resolve("johan", ctx())), "Johan99", "a name that is also a prefix of another picks the exact display")
T.eq(Targets.resolve("nobody", ctx()).error, "No player matches nobody", "no match")
T.eq(#Targets.resolve("nobody", ctx()).missing, 1)

T.section("targets: keywords")
T.eq(names(Targets.resolve("me", ctx())), "Atsuko")
T.eq(names(Targets.resolve("self", ctx())), "Atsuko")
T.eq(#Targets.resolve("all", ctx()).players, 5, "all includes you")
T.eq(#Targets.resolve("others", ctx()).players, 4, "others leaves you out")
T.eq(names(Targets.resolve("random", ctx())), "john_doe", "random uses the roller")
T.eq(names(Targets.resolve("random", ctx({ rand = function(n) return n end }))), "zed", "random can pick the last")
T.eq(names(Targets.resolve("nearest", ctx())), "BobTheBuilder", "nearest")
T.eq(names(Targets.resolve("farthest", ctx())), "zed", "farthest")
T.eq(names(Targets.resolve("friends", ctx())), "john_doe, BobTheBuilder", "friends")
T.eq(names(Targets.resolve("team:blue", ctx())), "Johan99, BobTheBuilder", "team by name")
T.eq(names(Targets.resolve("team:re", ctx())), "Atsuko, john_doe", "team by part of its name")
T.eq(names(Targets.resolve("@3", ctx())), "Johan99", "by user id")
T.eq(Targets.resolve("@999", ctx()).error, "No player matches @999", "unknown user id")
T.eq(Targets.resolve("team:green", ctx()).error, "No player matches team:green", "unknown team")

T.section("targets: without distance or friend info")
local bare = ctx({ distance = false, isFriend = false })
T.eq(Targets.resolve("nearest", bare).error, "No player matches nearest")
T.ok(#Targets.resolve("nearest", bare).notes == 1, "it explains why")
T.eq(#Targets.resolve("friends", bare).players, 0)
T.ok(#Targets.resolve("friends", bare).notes == 1)
local alone = ctx({ players = { me } })
T.eq(Targets.resolve("random", alone).error, "No player matches random", "nobody else to pick")
T.eq(Targets.resolve("nearest", alone).error, "No player matches nearest")

T.section("targets: exclusions")
T.eq(names(Targets.resolve("all -me", ctx())), "john_doe, Johan99, BobTheBuilder, zed")
T.eq(names(Targets.resolve("all -me -john", ctx())), "Johan99, BobTheBuilder, zed", "the closest match is dropped")
T.eq(names(Targets.resolve("-me", ctx())), "john_doe, Johan99, BobTheBuilder, zed", "only exclusions start from everyone")
T.eq(names(Targets.resolve("-zed -bob", ctx())), "Atsuko, john_doe, Johan99")
T.eq(names(Targets.resolve("others -friends", ctx())), "Johan99, zed")
T.eq(names(Targets.resolve("others -team:blue", ctx())), "john_doe, zed")
T.eq(Targets.resolve("all -all", ctx()).error, "Nobody left after the exclusions")
T.eq(names(Targets.resolve("zed -", ctx())), "zed", "a lone dash is not an exclusion")
T.eq(#Targets.resolve("me me zed zed", ctx()).players, 2, "no duplicates")

T.section("targets: exceptions")
local ex = ctx({ except = { john_doe = true, zed = true } })
T.eq(names(Targets.resolve("others", ex)), "Johan99, BobTheBuilder", "others skips the exceptions")
T.eq(names(Targets.resolve("all", ex)), "Atsuko, Johan99, BobTheBuilder", "all skips them too, but never you")
T.eq(names(Targets.resolve("zed", ex)), "zed", "a name you typed is still honoured")

T.section("targets: the cap")
local crowd = { me }
for i = 1, 70 do
	crowd[#crowd + 1] = player("p" .. i, "P" .. i, 100 + i, nil, i)
end
local big = Targets.resolve("others", ctx({ players = crowd }))
T.eq(#big.players, 30, "default cap is 30")
T.eq(big.truncated, true)
T.ok(#big.notes >= 1, "it says so")
T.eq(#Targets.resolve("others", ctx({ players = crowd, cap = 5 })).players, 5, "custom cap")
T.eq(Targets.resolve("others", ctx({ players = crowd, cap = 500 })).truncated, false, "a high cap keeps everyone")

T.section("targets: empty and odd input")
T.ok(Targets.resolve("", ctx()).error ~= nil, "empty text asks who")
T.ok(Targets.resolve("   ", ctx()).error ~= nil)
T.ok(Targets.resolve(nil, ctx()).error ~= nil)
T.eq(#Targets.resolve("all", { me = me, players = {} }).players, 0, "no players at all")
T.eq(#Targets.resolve("zed", { players = list }).players, 1, "works without 'me'")
T.eq(#Targets.resolve("me", { players = list }).players, 0, "me without a local player")
local one, res = Targets.one("bob zed", ctx())
T.eq(one.Name, "BobTheBuilder", "one() takes the first")
T.eq(#res.players, 2)
T.eq(Targets.one("zzz", ctx()), nil)
T.eq(Targets.names({}), "")

T.section("targets: same player twice through different tokens")
T.eq(#Targets.resolve("john @2 johnny", ctx()).players, 1)
