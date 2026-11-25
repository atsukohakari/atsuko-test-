local World = loadmodule("Testing/mocks/rbx_world.lua")
local env = World.install({})
local Time = loadmodule("Hub/modules/servertime.lua")
local Players = game:GetService("Players")

T.section("servertime: how a time reads")
T.eq(Time.text(0), "0s")
T.eq(Time.text(59.9), "59s")
T.eq(Time.text(60), "1m 0s")
T.eq(Time.text(3599), "59m 59s")
T.eq(Time.text(3600), "1h 0m 0s")
T.eq(Time.text(7380 + 45), "2h 3m 45s", "hours, minutes and seconds")
T.eq(Time.text(86400 + 3 * 3600 + 59), "1d 3h 0m 59s", "a server up for days")
T.eq(Time.text(-4), "0s")
T.eq(Time.text(0 / 0), "0s")
T.eq(Time.text("90"), "1m 30s")

T.section("servertime: a time the game itself keeps")
local NOW = 1800000000
T.eq(Time.read("ServerAge", 125, NOW), 125, "an age in seconds")
T.eq(Time.read("server_uptime", "300", NOW), 300, "written as text, any spelling")
T.eq(Time.read("ServerStartTime", NOW - 4000, NOW), 4000, "a start time")
T.eq(Time.read("StartTime", (NOW - 60) * 1000, NOW), 60, "a start time in milliseconds")
T.eq(Time.read("StartTime", 512, NOW), nil, "a start time that is not a date")
T.eq(Time.read("ServerStart", NOW + 50, NOW), nil, "a start in the future")
T.eq(Time.read("ServerAge", 200 * 86400, NOW), nil, "an age too long to be real")
T.eq(Time.read("Coins", 4000, NOW), nil, "any other number")
T.eq(Time.read("ServerAge", "soon", NOW), nil, "words")

local rs = Instance.new("Folder")
rs.Name = "ReplicatedStorage"
T.eq(Time.published({ rs }, NOW), nil, "nothing kept")
rs:SetAttribute("Coins", 5)
T.eq(Time.published({ rs }, NOW), nil)
local stats = Instance.new("Folder")
stats.Name = "ServerStats"
stats.Parent = rs
local uptime = Instance.new("IntValue")
uptime.Name = "Uptime"
uptime.Value = 900
uptime.Parent = stats
local secs, from = Time.published({ rs }, NOW)
T.eq(secs, 900, "a value in a folder")
T.eq(from, "Uptime", "and where it came from")
rs:SetAttribute("ServerStarted", NOW - 1200)
secs, from = Time.published({ rs }, NOW)
T.eq(secs, 1200, "the oldest of what it finds")
T.eq(from, "ReplicatedStorage.ServerStarted")
local deep = Instance.new("Folder")
deep.Parent = stats
local inner = Instance.new("Folder")
inner.Parent = deep
local far = Instance.new("NumberValue")
far.Name = "ServerAge"
far.Value = 99999
far.Parent = inner
T.eq((Time.published({ rs }, NOW)), 1200, "it doesn't dig forever")
T.eq(Time.published({ false, rs }, NOW), 1200, "a missing place is skipped")

T.section("servertime: remembering servers you were in")
local first, book = Time.remember(nil, "job-a", NOW - 30, NOW)
T.eq(first, NOW - 30, "a new server starts when you joined")
T.eq(book["job-a"], NOW - 30)
first, book = Time.remember({ ["job-a"] = NOW - 5000, ["job-b"] = NOW - 40 * 86400, ["job-c"] = "x" }, "job-a", NOW - 30, NOW)
T.eq(first, NOW - 5000, "a rejoin knows you were first here earlier")
T.eq(book["job-b"], nil, "a month old server is forgotten")
T.eq(book["job-c"], nil, "junk is dropped")
local big = {}
for i = 1, 150 do
	big["old" .. i] = NOW - i
end
first, book = Time.remember(big, "job-z", NOW, NOW)
local n = 0
for _ in pairs(book) do
	n += 1
end
T.eq(n, Time.KEEP, "only the newest hundred are kept")
T.eq(book["job-z"], NOW, "this one always stays")
T.eq(book["old1"], NOW - 1, "the newest of the old ones stay")
T.eq(book["old150"], nil, "the oldest go")
first = Time.remember({}, "", NOW - 10, NOW)
T.eq(first, NOW - 10, "studio has no job id")

T.section("servertime: the clock")
local now = NOW
local saved, wrote = { ["job-1"] = NOW - 7200 }, nil
local roots = {}
local function make(job)
	return Time.new({
		players = Players,
		jobId = job,
		now = function()
			return now
		end,
		here = function()
			return 600
		end,
		load = function()
			return saved
		end,
		save = function(b)
			wrote = b
		end,
		roots = function()
			return roots
		end,
	})
end
local clock = make("job-2")
T.eq(clock.joined, NOW - 600, "you joined ten minutes ago, by the server's clock")
T.eq(wrote["job-2"], NOW - 600, "it is written down")
T.eq(wrote["job-1"], NOW - 7200, "with the others kept")
local age, how = clock.age()
T.eq(age, 600, "a server you just found is at least as old as your time in it")
T.eq(how, "least")
T.eq(clock.here(), 600)
now = NOW + 60
age, how = clock.age()
T.eq(age, 660, "it keeps counting")
T.eq(clock.here(), 660)
clock.stop()
now = NOW
local again = make("job-1")
age, how = again.age()
T.eq(age, 7200, "back in a server you were in before")
T.eq(how, "before")
local holder = Instance.new("Folder")
holder:SetAttribute("ServerStartTime", NOW - 50000)
roots = { holder }
again.cache = nil
age, how = again.age()
T.eq(age, 50000, "the game's own start time beats a guess")
T.eq(how, "game")
holder:SetAttribute("ServerStartTime", NOW - 1)
now = NOW + 10
age = again.age()
T.eq(age, 50010, "it is looked up again only every so often")
now = NOW + 10 + Time.RESCAN
age = again.age()
T.eq(age, 41, "and then it reads the new value")
roots = {}
again.cache = nil
local p1 = Instance.new("Player")
p1.Name = "ann"
p1.DisplayName = "Ann"
now = NOW + 100
p1.Parent = Players
Players.PlayerAdded:Fire(p1)
env.run(0.1)
local p2 = Instance.new("Player")
p2.Name = "bob"
p2.DisplayName = "Bob"
now = NOW + 160
p2.Parent = Players
Players.PlayerAdded:Fire(p2)
env.run(0.1)
now = NOW + 220
local list = again.newest(3)
T.eq(#list, 2, "people who came in while it ran")
T.eq(list[1].player, p2, "newest first")
T.eq(list[1].ago, 60)
T.eq(list[2].ago, 120)
p2.Parent = nil
list = again.newest(3)
T.eq(#list, 1, "someone who left is not listed")
T.eq(#again.newest(), 1, "with no limit too")
again.stop()
local p3 = Instance.new("Player")
p3.Parent = Players
Players.PlayerAdded:Fire(p3)
env.run(0.1)
T.eq(#again.newest(5), 1, "stopping stops watching")

T.section("servertime: a broken clock")
local odd = Time.new({
	now = function()
		error("no")
	end,
	here = function()
		return 0 / 0
	end,
	jobId = "x",
})
T.ok(odd.joined > 1e9, "falls back to the computer's clock")
T.eq(odd.here() >= 0, true)
local a2, h2 = odd.age()
T.ok(a2 >= 0 and h2 == "least", "and still answers")
