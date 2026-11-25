local World = loadmodule("Testing/mocks/rbx_world.lua")
local env = World.install({})
CFrame = loadmodule("Testing/mocks/cframe_math.lua").make(Vector3)
local Relay = loadmodule("Hub/modules/relay.lua")
local http = game:GetService("HttpService")

local function near(a, b, eps)
	return a ~= nil and b ~= nil and (a.Position - b.Position).Magnitude < (eps or 0.02)
end

local function sameRot(a, b, eps)
	eps = eps or 0.002
	local ca = { a:GetComponents() }
	local cb = { b:GetComponents() }
	for i = 4, 12 do
		if math.abs(ca[i] - cb[i]) > eps then
			return false
		end
	end
	return true
end

T.section("relay: positions and turns go over the wire small")
do
	local cfs = {
		CFrame.new(1, 2, 3),
		CFrame.new(-50.257, 13.5, 900.1) * CFrame.Angles(0.3, 1.2, -2.1),
		CFrame.new(0, 5, 0) * CFrame.Angles(math.pi, 0, 0),
		CFrame.new(0, 5, 0) * CFrame.Angles(0, math.pi, 0),
		CFrame.new(0, 5, 0) * CFrame.Angles(0, 0, math.pi),
		CFrame.new(10, 0, 0) * CFrame.Angles(math.pi / 2, math.pi / 2, 0),
	}
	for i, cf in ipairs(cfs) do
		local p = Relay.packCF(cf)
		T.eq(#p, 6, "six numbers")
		local back = Relay.unpackCF(p)
		T.ok(near(back, cf), "position comes back " .. i)
		T.ok(sameRot(back, cf), "and the turn " .. i)
	end
	T.eq(Relay.unpackCF({ 1, 2 }), nil, "too few numbers")
	T.eq(Relay.unpackCF({ 0 / 0, 0, 0, 0, 0, 0 }), nil, "not a number")
	T.eq(Relay.unpackCF({ 1e9, 0, 0, 0, 0, 0 }), nil, "too far away")
	T.ok(Relay.unpackCF({ 0, 0, 0, 3, 0, 0 }) ~= nil, "a turn that's too long is fixed, not trusted")
	T.eq(Relay.unpackCF("x"), nil)
end

T.section("relay: links, rooms and asset ids")
do
	T.eq(Relay.link("https://atsuko-relay.someone.workers.dev/"), "wss://atsuko-relay.someone.workers.dev", "an https link becomes wss")
	T.eq(Relay.link("  wss://x.dev  "), "wss://x.dev")
	T.eq(Relay.link(""), nil)
	T.eq(Relay.link("ftp://x"), nil)
	T.eq(Relay.link("wss://x.dev/<script>"), nil)
	T.eq(Relay.link(5), nil)
	T.eq(Relay.room(12345, "abc-DEF-123"), "12345-abc-DEF-123", "a room is the place and the server")
	T.eq(Relay.room(1, ""), "1-studio", "studio has no job id")
	T.eq(Relay.room(1, "a/b?c"), "1-abc", "nothing odd gets into the link")
	T.eq(Relay.asset("rbxassetid://123"), "rbxassetid://123")
	T.eq(Relay.asset("http://www.roblox.com/asset/?id=55"), "rbxassetid://55")
	T.eq(Relay.asset("777"), "rbxassetid://777")
	T.eq(Relay.asset("rbxasset://textures/particles/sparkles_main.dds"), "rbxasset://textures/particles/sparkles_main.dds")
	T.eq(Relay.asset("rbxasset://../../x"), nil)
	T.eq(Relay.asset("https://evil.example/x.png"), nil)
	T.eq(Relay.asset(""), "")
	T.eq(Relay.asset(nil), nil)
end

T.section("relay: values")
do
	local function round(v, key)
		return Relay.dec(http:JSONDecode(http:JSONEncode(Relay.enc(v, key))), key)
	end
	T.eq(round(0.12345), 0.123, "numbers are rounded")
	T.eq(round(true), true)
	T.eq(round("Neon"), "Neon")
	local c = round(Color3.fromRGB(255, 128, 0))
	T.ok(c ~= nil and math.abs(c.R - 1) < 0.01 and math.abs(c.G - 128 / 255) < 0.01, "colors")
	local v = round(Vector3.new(1.5, -2, 3.25))
	T.ok(v ~= nil and v.X == 1.5 and v.Y == -2 and v.Z == 3.25, "vectors")
	T.eq(Relay.enc(0 / 0), nil, "not a number is dropped")
	T.eq(Relay.enc(string.rep("a", 100)), nil, "long text is dropped")
	T.eq(Relay.enc("https://evil.example/x.png", "Texture"), nil, "a texture that isn't a Roblox asset is dropped")
	T.eq(Relay.enc("rbxassetid://9", "MeshId"), "rbxassetid://9")
	T.eq(Relay.dec({ "c", 999, -5, 10 }).R, 1, "colors are kept in range")
	T.eq(Relay.dec({ "zz", 1 }), nil, "unknown values are dropped")
	T.eq(Relay.dec({ "e", "Font", "Arial" }), nil, "only a few kinds of enum come in")
	local seq = Relay.dec({ "n", 0, 1, 0, 1, 0, 0 })
	T.ok(seq ~= nil, "number sequences")
	T.eq(Relay.dec({ "n", 0, "x", 0 }), nil)
	local cseq = Relay.dec({ "s", 0, 255, 0, 0, 1, 0, 0, 255 })
	T.ok(cseq ~= nil, "color sequences")
	T.ok(Relay.dec({ "f", 1, 2, 3, 0, 0, 0 }) ~= nil, "positions")
end

T.section("relay: smooth in between")
do
	local tr = Relay.track()
	T.eq(Relay.sample(tr, 1), nil, "nothing yet")
	Relay.push(tr, 1, CFrame.new(0, 0, 0))
	Relay.push(tr, 2, CFrame.new(10, 0, 0))
	T.ok(near(Relay.sample(tr, 1.5), CFrame.new(5, 0, 0)), "halfway is halfway")
	T.ok(near(Relay.sample(tr, 0), CFrame.new(0, 0, 0)), "before the first it waits there")
	T.ok(near(Relay.sample(tr, 9), CFrame.new(10, 0, 0)), "after the last it stays")
	Relay.push(tr, 1.5, CFrame.new(99, 0, 0))
	T.ok(near(Relay.sample(tr, 1.5), CFrame.new(5, 0, 0)), "a late frame doesn't jump back")
	for i = 3, 20 do
		Relay.push(tr, i, CFrame.new(i * 10, 0, 0))
	end
	T.eq(#tr.t, Relay.KEEP, "only the last few are kept")
end

local function makeWorld()
	local w = { sent = {}, t = 100 }
	return w
end

local function pair(opts)
	opts = opts or {}
	local clock = { t = 100 }
	local now = function()
		return clock.t
	end
	local wires = {}
	local function socket(me)
		local ws = { me = me, closed = false }
		ws.OnMessage = Instance.new("BindableEvent")
		ws.OnClose = Instance.new("BindableEvent")
		function ws.Send(self, text)
			for _, other in ipairs(wires) do
				if other ~= self and not other.closed then
					local data = http:JSONDecode(text)
					data.u = me
					other.OnMessage:Fire(http:JSONEncode(data))
				end
			end
		end
		function ws.Close(self)
			self.closed = true
		end
		wires[#wires + 1] = ws
		local h = ws.OnMessage
		ws.OnMessage = h.Event
		ws.fire = function(text)
			h:Fire(text)
		end
		local c = ws.OnClose
		ws.OnClose = c.Event
		return ws
	end
	local senderWorld = Instance.new("Folder")
	senderWorld.Name = "SenderWorld"
	senderWorld.Parent = workspace
	local viewerWorld = Instance.new("Folder")
	viewerWorld.Name = "ViewerWorld"
	viewerWorld.Parent = workspace
	local roots, body, sounds = {}, {}, {}
	local reanimated = opts.reanimated ~= false
	local S1 = { relayShare = true, relaySee = true, relayVolume = 0.5 }
	local S2 = { relayShare = true, relaySee = true, relayVolume = 0.5, relayHideReal = true }
	local realChar = Instance.new("Model")
	realChar.Name = "SenderRealBody"
	local realPart = Instance.new("Part")
	realPart.Name = "Torso"
	realPart.Parent = realChar
	realChar.Parent = workspace
	local blocked = {}
	local here = { [7] = true, [8] = true }
	local function ctxFor(me, S, world)
		return {
			S = S,
			me = me,
			now = now,
			world = workspace,
			mirrorParent = function()
				return world
			end,
			encode = function(v)
				return http:JSONEncode(v)
			end,
			decode = function(t)
				return http:JSONDecode(t)
			end,
			reanimated = function()
				return reanimated
			end,
			rigView = function()
				if me ~= 7 then
					return nil
				end
				return body
			end,
			roots = function()
				if me ~= 7 then
					return {}
				end
				return roots
			end,
			sounds = function()
				if me ~= 7 then
					return {}
				end
				return sounds
			end,
			characterOf = function(u)
				if u == 7 then
					return realChar
				end
				return nil
			end,
			inServer = function(u)
				return here[u] == true
			end,
			blocked = function(u)
				return blocked[u] == true
			end,
		}
	end
	local A = Relay.new(ctxFor(7, S1, senderWorld))
	local B = Relay.new(ctxFor(8, S2, viewerWorld))
	local wa, wb = socket(7), socket(8)
	A.attach(wa)
	B.attach(wb)
	local P = {
		A = A,
		B = B,
		wa = wa,
		wb = wb,
		clock = clock,
		roots = roots,
		body = body,
		sounds = sounds,
		S1 = S1,
		S2 = S2,
		realPart = realPart,
		realChar = realChar,
		blocked = blocked,
		here = here,
		viewerWorld = viewerWorld,
		setReanimated = function(x)
			reanimated = x
		end,
	}
	function P.run(seconds, step)
		step = step or (1 / 60)
		local n = math.floor(seconds / step + 0.5)
		for _ = 1, n do
			clock.t += step
			A.tick(step)
			B.tick(step)
		end
	end
	function P.mirrors()
		local p = B.peers[7]
		local out = {}
		if p then
			for id, obj in pairs(p.objs) do
				out[id] = obj
			end
		end
		return out, p
	end
	return P
end

local function part(name, size, cf, parent)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.Transparency = 0
	p.Color = Color3.fromRGB(255, 0, 0)
	p.Parent = parent or workspace
	return p
end

T.section("relay: your effects show up for another hub user")
local P = pair()
local fx = Instance.new("Folder")
fx.Name = "Effects"
fx.Parent = workspace
local bullet = part("Bullet", Vector3.new(1, 1, 4), CFrame.new(0, 5, 0), fx)
local mesh = Instance.new("SpecialMesh")
mesh.MeshType = Enum.MeshType.FileMesh
mesh.MeshId = "rbxassetid://4307568890"
mesh.Scale = Vector3.new(2, 2, 2)
mesh.Parent = bullet
local att0 = Instance.new("Attachment")
att0.Parent = bullet
local att1 = Instance.new("Attachment")
att1.Parent = bullet
local beam = Instance.new("Beam")
beam.Attachment0 = att0
beam.Attachment1 = att1
beam.Texture = "rbxassetid://123"
beam.Parent = bullet
local glow = Instance.new("ParticleEmitter")
glow.Texture = "rbxassetid://456"
glow.Rate = 9999
glow.Parent = att0
local ghost = part("Ghost", Vector3.new(1, 1, 1), CFrame.new(0, 0, 0), fx)
ghost.Transparency = 1
table.insert(P.roots, fx)
P.run(1)
local mirrors, peer = P.mirrors()
local count = 0
for _ in pairs(mirrors) do
	count += 1
end
T.eq(count, 1, "the bullet is mirrored, an invisible part with nothing on it isn't")
local m1 = nil
for _, obj in pairs(mirrors) do
	m1 = obj
end
T.ok(m1 ~= nil and m1.part.Parent == peer.folder and peer.folder.Parent == P.viewerWorld, "into its own folder")
T.eq(m1 and m1.part.Size, Vector3.new(1, 1, 4), "same size")
T.ok(m1 and m1.part.Anchored == true and m1.part.CanCollide == false and m1.part.CanQuery == false, "anchored and it can't be touched")
local mm = m1 and m1.part:FindFirstChildOfClass("SpecialMesh")
T.eq(mm and mm.MeshId, "rbxassetid://4307568890", "with its mesh")
local mb = m1 and m1.part:FindFirstChildOfClass("Beam")
T.ok(mb ~= nil and mb.Attachment0 ~= nil and mb.Attachment1 ~= nil and mb.Attachment0.Parent == m1.part, "its beam is tied to its own attachments")
local atts = m1 and {}
local pe = nil
for _, d in ipairs(m1 and m1.part:GetDescendants() or {}) do
	if d.ClassName == "ParticleEmitter" then
		pe = d
	end
end
T.ok(pe ~= nil and pe.Parent.ClassName == "Attachment", "its particles sit on the attachment like the original")
T.eq(pe and pe.Rate, 400, "with a rate that can't flood your screen")
T.ok(m1 and near(m1.part.CFrame, CFrame.new(0, 5, 0)), "in the same spot")
bullet.CFrame = CFrame.new(20, 5, 0)
P.run(0.5)
T.ok(m1 and near(m1.part.CFrame, CFrame.new(20, 5, 0), 0.05), "it follows when the bullet moves: " .. tostring(m1 and m1.part.CFrame.Position))
local seen = {}
bullet.CFrame = CFrame.new(20, 5, 0)
for i = 1, 10 do
	bullet.CFrame = CFrame.new(20 + i * 2, 5, 0)
	P.run(1 / 15)
	seen[#seen + 1] = m1.part.CFrame.Position.X
end
local smooth = true
for i = 2, #seen do
	if seen[i] < seen[i - 1] - 0.001 or seen[i] - seen[i - 1] > 6 then
		smooth = false
	end
end
T.ok(smooth, "and moves smoothly without going back: " .. table.concat(seen, ", "))
bullet.Color = Color3.fromRGB(0, 0, 255)
P.run(1)
T.ok(m1.part.Color.B > 0.9, "a color change shows up")
bullet:Destroy()
P.run(1)
mirrors = P.mirrors()
count = 0
for _ in pairs(mirrors) do
	count += 1
end
T.eq(count, 0, "a bullet that's gone is gone for them too")

T.section("relay: your fake body stays put through a respawn loop")
local hatA = part("HatA", Vector3.new(1, 1, 1), CFrame.new(0, 10, 0), workspace)
local hatB = part("HatB", Vector3.new(2, 1, 1), CFrame.new(1, 10, 0), workspace)
local keyA, keyB = {}, {}
P.body[1] = { k = keyA, cf = CFrame.new(0, 10, 0), h = hatA }
P.body[2] = { k = keyB, cf = CFrame.new(1, 10, 0), h = hatB }
P.run(1)
mirrors, peer = P.mirrors()
local bodyCount = 0
for _, obj in pairs(mirrors) do
	if obj.body then
		bodyCount += 1
	end
end
T.eq(bodyCount, 2, "both hats of the body are mirrored")
T.eq(P.realPart.LocalTransparencyModifier, 1, "and their real, respawning body is hidden on your screen")
P.body[1].cf = CFrame.new(5, 10, 0)
P.run(0.5)
local mA = peer.objs[P.A.ids[keyA]]
T.ok(mA and near(mA.part.CFrame, CFrame.new(5, 10, 0), 0.05), "the body moves with the fake body, not the real one")
hatA:Destroy()
hatB:Destroy()
P.body[1].h, P.body[2].h = nil, nil
P.body[1].cf = CFrame.new(8, 10, 0)
P.run(1)
mA = peer.objs[P.A.ids[keyA]]
T.ok(mA ~= nil and mA.part.Parent ~= nil, "while their hats are gone in a respawn the placeholder stays")
T.ok(mA and near(mA.part.CFrame, CFrame.new(8, 10, 0), 0.05), "and keeps moving")

T.section("relay: their sounds")
local snd = Instance.new("Sound")
snd.SoundId = "rbxassetid://9001"
snd.Volume = 1
snd.Playing = true
snd.Parent = workspace
table.insert(P.sounds, snd)
P.run(1)
local played = nil
for _, s in pairs(peer.sounds) do
	played = s
end
T.ok(played ~= nil and played.SoundId == "rbxassetid://9001", "a sound your script plays plays for them")
T.eq(played and played.Volume, 0.5, "at the volume they picked")
snd.Playing = false
P.run(1)
local left = 0
for _ in pairs(peer.sounds) do
	left += 1
end
T.eq(left, 0, "and stops when it stops")

T.section("relay: who gets seen")
P.blocked[7] = true
P.B.remove(7)
P.run(1)
T.eq(P.B.peers[7], nil, "someone you blocked in hub chat isn't shown")
P.blocked[7] = nil
P.here[7] = false
P.run(1)
T.eq(P.B.peers[7], nil, "nor someone who isn't in your server")
P.here[7] = true
P.S2.relaySee = false
P.run(1)
T.eq(P.B.peers[7], nil, "nor anyone when you turned it off")
P.S2.relaySee = true
P.A.fullAt = -1e9
P.run(1)
T.ok(P.B.peers[7] ~= nil, "turned on again they come back")

T.section("relay: deanimating takes it all away")
P.setReanimated(false)
table.clear(P.roots)
table.clear(P.body)
table.clear(P.sounds)
P.run(1)
T.eq(P.B.peers[7], nil, "their screen clears right away")
T.eq(P.realPart.LocalTransparencyModifier, 0, "and their real body shows again")
T.eq(P.A.sharing, false, "and nothing more is sent")

T.section("relay: a sender that goes quiet")
P.setReanimated(true)
table.insert(P.body, { k = {}, cf = CFrame.new(0, 3, 0), h = part("HatC", Vector3.new(1, 1, 1), CFrame.new(0, 3, 0), workspace) })
P.run(1)
T.ok(P.B.peers[7] ~= nil, "shown again")
P.wa.closed = true
for _ = 1, 60 * 5 do
	P.clock.t += 1 / 60
	P.B.tick(1 / 60)
end
T.eq(P.B.peers[7], nil, "nothing heard for a few seconds clears them")

T.section("relay: bad data never breaks the viewer")
local Q = pair()
Q.wa.closed = true
local evil = {
	"not json",
	http:JSONEncode({ k = "a", u = 7, o = { { i = 1, c = "Script", p = {} } } }),
	http:JSONEncode({ k = "a", u = 7, o = { { i = 2, c = "Part", p = { Size = { "v", 1e9, 1e9, 1e9 }, Transparency = 5 } } } }),
	http:JSONEncode({ k = "a", u = 7, o = { { i = 3, c = "Part", p = {}, d = { { c = "Script", p = {} }, { c = "Decal", p = { Texture = "https://evil.example/x.png" } } } } } }),
	http:JSONEncode({ k = "f", u = 7, t = "soon", o = { { 2, 1, 2, 3, 0, 0, 0 } } }),
	http:JSONEncode({ k = "f", u = 7, t = 50, o = { { 99, 1, 2, 3, 0, 0, 0 }, "x", { 2, 0 / 1, 1e12, 3, 0, 0, 0 } } }),
	http:JSONEncode({ k = "s", u = 7, o = { { 1, 0, "https://evil.example/a.mp3", 10, 1, false, 0 } } }),
	http:JSONEncode({ k = "zzz", u = 7 }),
	http:JSONEncode({ k = "a", u = 8, o = {} }),
}
for _, text in ipairs(evil) do
	local ok, err = pcall(Q.B.onMessage, text)
	T.ok(ok, "survives: " .. tostring(err))
end
Q.run(0.5)
local qp = Q.B.peers[7]
T.ok(qp ~= nil, "the good parts still come through")
local o2 = qp and qp.objs[2]
T.ok(o2 ~= nil and o2.part.Size.X <= Relay.MAX_SIZE and o2.part.Transparency <= 1, "a huge part is made smaller and see-through values stay in range")
T.eq(qp and qp.objs[1], nil, "only parts can be made")
local o3 = qp and qp.objs[3]
local d3 = o3 and o3.part:FindFirstChildOfClass("Decal")
T.ok(o3 ~= nil and o3.part:FindFirstChildOfClass("Script") == nil, "no scripts")
T.ok(d3 == nil or (d3.Texture or "") == "", "and no pictures from outside Roblox")
local sounds3 = 0
for _ in pairs(qp and qp.sounds or {}) do
	sounds3 += 1
end
T.eq(sounds3, 0, "nor sounds from outside Roblox")
T.eq(Q.B.peers[8], nil, "and your own messages are never mirrored")

T.section("relay: the hub's parts")
do
	local src = readsource("Hub/AtsukoHub.lua")
	T.ok(string.find(src, 'local mod = Core.loadModule("relay")', 1, true) ~= nil, "the hub starts it after loading")
	T.ok(string.find(src, 'section(v, "Live view", 14)', 1, true) ~= nil, "main scripts > setup has a live view section")
	T.ok(string.find(src, "\trelayShare = true,\n", 1, true) ~= nil and string.find(src, "\trelaySee = true,\n", 1, true) ~= nil, "both ways are on by default")
	local rean = readsource("Hub/Reanimate.lua")
	T.ok(string.find(rean, "env.AtsukoRigView = rigView", 1, true) ~= nil, "Script Reanimate shows its body to it")
	local fdl = readsource("Reanimation/Hat/FDless.lua")
	T.ok(string.find(fdl, "g.AtsukoRigView=rigView", 1, true) ~= nil, "so does FDless")
	local mv = readsource("Hub/Moveset.lua")
	T.ok(string.find(mv, "genv.AtsukoFx[fxFolder] = true", 1, true) ~= nil, "and the moveset host's effects folder is shared")
	local worker = readsource("Relay/worker.js")
	T.ok(string.find(worker, "acceptWebSocket", 1, true) ~= nil, "the relay server is in Relay/worker.js")
	T.ok(string.find(worker, "data.u = Number(a.u)", 1, true) ~= nil, "and it stamps who sent each message so nobody can pretend to be someone else's body")
end
