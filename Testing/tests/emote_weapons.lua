local World = loadmodule("Testing/mocks/rbx_world.lua")
World.install({})
CFrame = loadmodule("Testing/mocks/cframe_math.lua").make(Vector3)
local W = loadmodule("Hub/modules/emoteweapons.lua")

local function near(a, b, eps)
	return math.abs(a - b) <= (eps or 1e-3)
end

T.section("emote_weapons: where the gun and the sword go")
do
	local limb, cf = W.place("gun", Vector3.new(0.4, 0.8, 2.4))
	T.eq(limb, "Right Arm", "the gun sits on the right arm")
	T.ok(near(cf.Position.X, 0.9) and near(cf.Position.Y, -0.35) and near(cf.Position.Z, 0), "on the outside of the forearm, near the wrist (" .. tostring(cf.Position) .. ")")
	T.ok(near(cf.ZVector.Y, -1), "its long side runs down the arm to the hand")
	T.ok(near(math.abs(cf.YVector.X), 1), "and its height points away from the arm")
	limb, cf = W.place("sword", Vector3.new(0.2, 4, 0.6))
	T.eq(limb, "Torso", "the sword goes on the torso")
	T.ok(cf.Position.Z > 0.5, "behind it, on the back (" .. tostring(cf.Position) .. ")")
	T.ok(near(cf.YVector.X, 0.6) and near(cf.YVector.Y, -0.8), "crossing the back from the shoulder to the hip")
	T.ok(near(math.abs(cf.XVector.Z), 1), "its thin side faces away from the back")
	T.eq(W.place("book", Vector3.new(1, 1, 1)), nil, "nothing else gets a spot")
	limb, cf = W.place("gun", nil)
	T.eq(limb, "Right Arm", "a hat with no size still gets a spot")
end

T.section("emote_weapons: which hats are weapons")
do
	local svc = {
		rows = { gun = { { mesh = "500" } }, sword = { { hat = "777" } } },
	}
	function svc:userRows(section, kind)
		return section == "shared" and self.rows[kind] or {}
	end
	function svc:detect(row)
		if row.mesh == "600" then
			return "sword", "list"
		end
		if row.mesh == "650" then
			return "book", "name"
		end
		return nil
	end
	local mod = {
		kindFromName = function(name)
			return name == "Laser Pistol" and "gun" or nil
		end,
	}
	W.forget()
	T.eq(W.kind(svc, mod, "rbxassetid://500", "", "x"), "gun", "a gun you added is a gun")
	T.eq(W.kind(svc, mod, "1", "rbxassetid://777", "y"), "sword", "a sword you added by its hat id")
	T.eq(W.kind(svc, mod, "600", "", "z"), "sword", "a sword on the hat list")
	T.eq(W.kind(svc, mod, "650", "", "Old Book"), nil, "a book is not a weapon")
	T.eq(W.kind(svc, mod, "900", "", "Laser Pistol"), "gun", "a name that says pistol")
	T.eq(W.kind(svc, mod, "901", "", "Party Hat"), nil, "a plain hat")
	svc.rows.gun = {}
	T.eq(W.kind(svc, mod, "rbxassetid://500", "", "x"), "gun", "answers are remembered")
	W.forget()
	T.eq(W.kind(svc, mod, "rbxassetid://500", "", "x"), nil, "until they are forgotten")
	T.eq(W.kind(nil, nil, "1", "2", "3"), nil, "no hat list, no guess")
end

T.section("emote_weapons: one gun and one sword")
do
	local list = { { n = "a", k = "hat" }, { n = "b", k = "gun" }, { n = "c", k = "gun" }, { n = "d", k = "sword" } }
	local got = W.pick(list, function(item)
		return item.k
	end)
	T.eq(got.gun and got.gun.n, "b", "the first gun")
	T.eq(got.sword and got.sword.n, "d", "the first sword")
	T.same(W.pick({}, function() end), {}, "nothing to pick")
end
