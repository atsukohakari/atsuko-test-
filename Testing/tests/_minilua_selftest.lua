T.section("arithmetic and formatting")
T.eq(1 + 2 * 3, 7)
T.eq(7 // 2, 3)
T.eq(-7 // 2, -4)
T.eq(7 % 3, 1)
T.eq(-7 % 3, 2)
T.eq(2 ^ 10, 1024)
T.eq(tostring(3), "3")
T.eq(tostring(3.5), "3.5")
T.eq(tostring(1 / 0), "inf")
T.eq(tostring(10 / 4), "2.5")
T.eq("a" .. 1 .. 2, "a12")
T.eq(#"hello", 5)
T.eq(string.format("%d|%5.2f|%-4s|%03d|%x", 42, 3.14159, "ab", 7, 255), "42| 3.14|ab  |007|ff")
T.eq(tonumber("0x10"), 16)
T.eq(tonumber("  12  "), 12)
T.eq(tonumber("abc"), nil)
T.eq(tonumber("10", 2), 2)

T.section("closures and varargs")
local function counter()
	local n = 0
	return function()
		n += 1
		return n
	end
end
local c1, c2 = counter(), counter()
c1()
c1()
T.eq(c1(), 3)
T.eq(c2(), 1)
local function va(...)
	return select("#", ...), (select(2, ...))
end
local n, second = va(10, 20, 30)
T.eq(n, 3)
T.eq(second, 20)
local function pack2(...)
	return { ... }
end
T.eq(#pack2(1, 2, 3), 3)
local fns = {}
for i = 1, 3 do
	fns[i] = function()
		return i
	end
end
T.eq(fns[1]() + fns[2]() + fns[3](), 6)

T.section("control flow")
local sum = 0
for i = 10, 1, -3 do
	sum = sum + i
end
T.eq(sum, 10 + 7 + 4 + 1)
local k = 0
repeat
	local done = k >= 3
	k = k + 1
until done
T.eq(k, 4)
local out = {}
for i = 1, 6 do
	if i % 2 == 0 then
		continue
	end
	if i > 4 then
		break
	end
	out[#out + 1] = i
end
T.same(out, { 1, 3 })
local w = 0
while true do
	w = w + 1
	if w == 5 then
		break
	end
end
T.eq(w, 5)

T.section("tables")
local t = { 5, 3, 8, x = 1, ["y z"] = 2 }
T.eq(#t, 3)
table.insert(t, 9)
table.insert(t, 1, 0)
T.same(t, { 0, 5, 3, 8, 9, x = 1, ["y z"] = 2 })
T.eq(table.remove(t), 9)
T.eq(table.remove(t, 1), 0)
table.sort(t)
T.same(t, { 3, 5, 8, x = 1, ["y z"] = 2 })
table.sort(t, function(a, b)
	return a > b
end)
T.eq(t[1], 8)
T.eq(table.concat({ "a", "b", "c" }, "-"), "a-b-c")
T.eq(select("#", table.unpack({ 1, 2, 3 })), 3)
T.eq(table.find({ "a", "b" }, "b"), 2)
local cnt = 0
for _ in pairs({ a = 1, b = 2, c = 3 }) do
	cnt += 1
end
T.eq(cnt, 3)
local seq = {}
for i, v in ipairs({ "x", "y", "z" }) do
	seq[#seq + 1] = i .. v
end
T.eq(table.concat(seq, ","), "1x,2y,3z")
local nilmid = { 1, nil, 3 }
T.eq(nilmid[3], 3)
local a, b = (function()
	return 1, 2
end)()
T.eq(a + b, 3)

T.section("metatables")
local V = {}
V.__index = V
function V.new(x)
	return setmetatable({ x = x }, V)
end
function V:double()
	return self.x * 2
end
V.__add = function(p, q)
	return V.new(p.x + q.x)
end
V.__tostring = function(p)
	return "V(" .. p.x .. ")"
end
V.__eq = function(p, q)
	return p.x == q.x
end
V.__call = function(self, y)
	return self.x + y
end
V.__len = function()
	return 99
end
local v1, v2 = V.new(2), V.new(5)
T.eq((v1 + v2).x, 7)
T.eq(v1:double(), 4)
T.eq(tostring(v1), "V(2)")
T.ok(V.new(1) == V.new(1))
T.ok(V.new(1) ~= V.new(2))
T.eq(v1(10), 12)
T.eq(#v1, 99)
local prox = setmetatable({}, { __index = function(_, key)
	return key .. "!"
end })
T.eq(prox.hey, "hey!")
local log = {}
local watched = setmetatable({}, { __newindex = function(tb, key, val)
	rawset(tb, key, val)
	log[#log + 1] = key
end })
watched.a = 1
watched.a = 2
T.eq(#log, 1)

T.section("strings")
T.eq(("hello"):upper(), "HELLO")
T.eq(("hello"):sub(2, 4), "ell")
T.eq(("hello"):sub(-3), "llo")
T.eq(("a,b,c"):find(",", 1, true), 2)
T.eq(string.find("hello world", "o w"), 5)
local f1, f2, cap = string.find("key=value", "(%w+)=(%w+)")
T.eq(f1, 1)
T.eq(f2, 9)
T.eq(cap, "key")
T.eq(string.match("2024-05-06", "(%d+)-(%d+)-(%d+)"), "2024")
local y, m, d = string.match("2024-05-06", "(%d+)-(%d+)-(%d+)")
T.eq(m, "05")
T.eq(d, "06")
T.eq(string.gsub("hello world", "o", "0"), "hell0 w0rld")
T.eq(select(2, string.gsub("aaa", "a", "b")), 3)
T.eq(string.gsub("abc", "%w", "%0%0"), "aabbcc")
T.eq(string.gsub("hello", "l+", function(s)
	return "[" .. s .. "]"
end), "he[ll]o")
T.eq(string.gsub("$name is $age", "%$(%w+)", { name = "Bob", age = "5" }), "Bob is 5")
local words = {}
for wd in string.gmatch("one two  three", "%S+") do
	words[#words + 1] = wd
end
T.same(words, { "one", "two", "three" })
T.eq(string.match("  trim  ", "^%s*(.-)%s*$"), "trim")
T.eq(string.match("file.lua", "%.(%w+)$"), "lua")
T.eq(string.rep("ab", 3, "-"), "ab-ab-ab")
T.eq(string.byte("A"), 65)
T.eq(string.char(72, 105), "Hi")
T.eq(("x"):rep(0), "")
T.eq(string.match("f(a(b)c)d", "%b()"), "(a(b)c)")
T.eq(string.find("THE (quick) fox", "%((%a+)%)"), 5)
T.eq(string.match("abc123", "^%a+"), "abc")
T.eq(string.match("abc", "^(b)"), nil)
T.eq(("%d items"):format(3), "3 items")
T.eq(("a b"):split(" ")[2], "b")

T.section("errors")
local ok, err = pcall(function()
	error("boom")
end)
T.ok(not ok)
T.ok(string.find(err, "boom", 1, true) ~= nil)
local ok2, err2 = pcall(error, { code = 7 })
T.eq(err2.code, 7)
T.ok(not pcall(function()
	local z = nil
	return z.field
end))
T.ok(not pcall(function()
	return 1 < "x"
end))
T.eq(select("#", pcall(function()
	return 1, 2, 3
end)), 4)
local okA, errA = pcall(assert, false, "nope")
T.eq(errA, "nope")
T.ok(select(1, pcall(assert, 1)))

T.section("math")
T.eq(math.floor(-1.5), -2)
T.eq(math.ceil(1.2), 2)
T.eq(math.max(1, 9, 3), 9)
T.eq(math.min(4, 2), 2)
T.eq(math.clamp(15, 0, 10), 10)
T.eq(math.abs(-4), 4)
T.eq(math.huge > 1e300, true)
T.eq(math.round(2.5), 3)
T.eq(math.sign(-3), -1)
T.near(math.sqrt(2), 1.41421356, 1e-6)

T.section("scheduler")
local fired = {}
task.delay(0.5, function()
	fired[#fired + 1] = "b"
end)
task.delay(0.2, function()
	fired[#fired + 1] = "a"
end)
task.defer(function()
	fired[#fired + 1] = "d"
end)
task.wait(1)
T.eq(table.concat(fired, ""), "dab")

T.section("scheduler: spawned threads pause at a wait and the spawner carries on")
do
	local log = {}
	task.spawn(function()
		log[#log + 1] = "a1"
		task.wait(1)
		log[#log + 1] = "a2"
		task.wait(1)
		log[#log + 1] = "a3"
	end)
	log[#log + 1] = "main"
	T.eq(table.concat(log, ","), "a1,main", "the spawner continues at the first wait")
	task.wait(0.5)
	T.eq(table.concat(log, ","), "a1,main")
	task.wait(0.6)
	T.eq(table.concat(log, ","), "a1,main,a2")
	task.wait(1)
	T.eq(table.concat(log, ","), "a1,main,a2,a3")
end

T.section("scheduler: threads interleave in time order")
do
	local log = {}
	task.spawn(function()
		task.wait(0.3)
		log[#log + 1] = "slow"
	end)
	task.spawn(function()
		task.wait(0.1)
		log[#log + 1] = "fast"
		task.wait(0.4)
		log[#log + 1] = "fast2"
	end)
	task.delay(0.2, function()
		log[#log + 1] = "delayed"
		task.wait(0.05)
		log[#log + 1] = "delayed2"
	end)
	task.wait(1)
	T.eq(table.concat(log, ","), "fast,delayed,delayed2,slow,fast2")
end

T.section("scheduler: a thread can spawn another and share the clock")
do
	local log = {}
	task.spawn(function()
		task.spawn(function()
			log[#log + 1] = "inner start"
			task.wait(0.5)
			log[#log + 1] = "inner end " .. string.format("%.1f", time())
		end)
		log[#log + 1] = "outer"
		task.wait(1)
		log[#log + 1] = "outer end"
	end)
	local t0 = time()
	task.wait(2)
	T.eq(table.concat(log, ","), "inner start,outer,inner end " .. string.format("%.1f", t0 + 0.5) .. ",outer end")
end

T.section("scheduler: pcall around a wait inside a thread")
do
	local log = {}
	task.spawn(function()
		local ok, err = pcall(function()
			task.wait(0.2)
			error("after the wait", 0)
		end)
		log[#log + 1] = tostring(ok) .. ":" .. tostring(err)
	end)
	T.eq(#log, 0)
	task.wait(0.5)
	T.eq(log[1], "false:after the wait")
end

T.section("scheduler: state set by a paused thread is seen by the main chunk")
do
	local state = { busy = false }
	local function work()
		state.busy = true
		task.wait(1)
		state.busy = false
	end
	task.spawn(work)
	T.eq(state.busy, true, "visible while the thread is paused")
	task.wait(1.1)
	T.eq(state.busy, false)
end

T.section("minilua: nan is never equal to itself")
local nan = 0 / 0
T.ok(nan ~= nan)
T.ok(not (nan == nan))
local box = { v = nan }
T.ok(box.v ~= box.v)
T.ok(1 / 0 == math.huge)

T.section("coroutine: create, resume, yield and status")
do
	local co = coroutine.create(function(a, b)
		local c = coroutine.yield(a + b, "first")
		local d, e = coroutine.yield(c * 2)
		return "end", d, e
	end)
	T.eq(type(co), "thread")
	T.eq(coroutine.status(co), "suspended")
	local ok, x, y = coroutine.resume(co, 1, 2)
	T.eq(ok, true)
	T.eq(x, 3)
	T.eq(y, "first")
	T.eq(coroutine.status(co), "suspended")
	local ok2, z = coroutine.resume(co, 10)
	T.eq(ok2, true)
	T.eq(z, 20)
	local ok3, r1, r2, r3 = coroutine.resume(co, "p", "q")
	T.eq(ok3, true)
	T.eq(r1, "end")
	T.eq(r2, "p")
	T.eq(r3, "q")
	T.eq(coroutine.status(co), "dead")
	local ok4, why = coroutine.resume(co)
	T.eq(ok4, false)
	T.eq(why, "cannot resume dead coroutine")
end

T.section("coroutine: errors come back as a result")
do
	local co = coroutine.create(function()
		error("boom", 0)
	end)
	local ok, e = coroutine.resume(co)
	T.eq(ok, false)
	T.eq(e, "boom")
	T.eq(coroutine.status(co), "dead")
	local co2 = coroutine.create(function()
		local t = nil
		return t.x
	end)
	local ok2, e2 = coroutine.resume(co2)
	T.eq(ok2, false)
	T.ok(string.find(e2, "attempt to index", 1, true) ~= nil)
end

T.section("coroutine: wrap")
do
	local gen = coroutine.wrap(function(n)
		for i = 1, n do
			coroutine.yield(i)
		end
		return "done"
	end)
	T.eq(gen(3), 1)
	T.eq(gen(), 2)
	T.eq(gen(), 3)
	T.eq(gen(), "done")
	local ok, e = pcall(gen)
	T.eq(ok, false)
	T.ok(string.find(tostring(e), "dead coroutine", 1, true) ~= nil)
	local bad = coroutine.wrap(function()
		error("wrapped boom", 0)
	end)
	local ok2, e2 = pcall(bad)
	T.eq(ok2, false)
	T.eq(e2, "wrapped boom")
end

T.section("coroutine: yield outside a coroutine is an error")
do
	local ok, e = pcall(coroutine.yield, 1)
	T.eq(ok, false)
	T.ok(string.find(tostring(e), "outside a coroutine", 1, true) ~= nil)
	T.eq(coroutine.isyieldable(), false)
	local inside
	coroutine.wrap(function()
		inside = coroutine.isyieldable()
	end)()
	T.eq(inside, true)
end

T.section("coroutine: status while running")
do
	local seen
	local co
	co = coroutine.create(function()
		seen = coroutine.status(co)
	end)
	coroutine.resume(co)
	T.eq(seen, "running")
	T.eq(coroutine.status(co), "dead")
end

T.section("task: spawn, defer and delay hand back a thread")
do
	local log = {}
	local a = task.spawn(function(x)
		log[#log + 1] = "spawn " .. x
	end, 1)
	T.eq(type(a), "thread")
	T.eq(coroutine.status(a), "dead")
	T.same(log, { "spawn 1" })
	local b = task.defer(function()
		log[#log + 1] = "defer"
	end)
	T.eq(type(b), "thread")
	T.eq(coroutine.status(b), "suspended", "a deferred thread has not run yet")
	local c = task.delay(1, function(x)
		log[#log + 1] = "delay " .. x
	end, 7)
	T.eq(type(c), "thread")
	task.wait(0.5)
	T.same(log, { "spawn 1", "defer" })
	task.wait(1)
	T.same(log, { "spawn 1", "defer", "delay 7" })
	T.eq(coroutine.status(c), "dead")
end

T.section("minilua: jsonencode and jsondecode agree")
T.eq(jsonencode({ a = 1, b = { 1, 2, 3 }, c = "x", d = true, e = {} }), '{"a":1,"b":[1,2,3],"c":"x","d":true,"e":[]}')
T.eq(jsonencode({ version = 1, items = { ["Scripts/A.lua"] = { logo = { src = "url", w = 2.5 } } } }), '{"items":{"Scripts/A.lua":{"logo":{"src":"url","w":2.5}}},"version":1}')
T.eq(jsondecode(jsonencode({ x = { y = { 1, 2 } } })).x.y[2], 2)
T.eq(jsonencode(7), "7")
T.eq(jsonencode("a\"b"), '"a\\"b"')
