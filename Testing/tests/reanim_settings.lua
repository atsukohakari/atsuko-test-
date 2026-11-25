local src = readsource("Hub/AtsukoHub.lua")

local function occurrences(text)
	local n, from = 0, 1
	while true do
		local a, b = string.find(src, text, from, true)
		if not a then
			return n
		end
		n += 1
		from = b + 1
	end
end

local first = string.find(src, "Core.REANIM_PICKS = {", 1, true)
local last = first and string.find(src, "function Core.normalizeSettings()", first, true)
T.section("reanim_settings: the cleaner is found in the hub")
T.ok(first ~= nil, "REANIM_PICKS present")
T.ok(last ~= nil, "normalizeSettings present after it")
local build, err = loadstring("local Core = {}\n" .. string.sub(src, first or 1, (last or 1) - 1) .. "\nreturn Core", "=cleanReanim")
T.ok(build ~= nil, "extracted block compiles: " .. tostring(err))
local Core = build and build() or { cleanReanim = function() end, REANIM_PICKS = {} }
local clean = Core.cleanReanim

local function count(t)
	local n = 0
	for _ in pairs(t) do
		n += 1
	end
	return n
end

local function cleaned(s)
	clean(s)
	return s
end

T.section("reanim_settings: nothing saved yet")
local fresh = cleaned({})
T.eq(fresh.hatReanim, "", "nothing is picked for the hat reanimation, the player picks it")
T.eq(fresh.reanimLimb, "gelatek")
T.eq(type(fresh.reanimOpts), "table")
T.eq(count(fresh.reanimOpts), 0)

T.section("reanim_settings: the four reanimations are the only ones kept")
local a = cleaned({ hatReanim = "fdless", reanimLimb = "uhhhhhh" })
T.eq(a.hatReanim, "fdless")
T.eq(a.reanimLimb, "uhhhhhh")
local b = cleaned({ hatReanim = "atsuko", reanimLimb = "gelatek" })
T.eq(b.hatReanim, "atsuko")
T.eq(b.reanimLimb, "gelatek")
local c = cleaned({ hatReanim = "unified", reanimLimb = "gelatek" })
T.eq(c.hatReanim, "", "the removed unified reanimation is no pick, the player picks again")
T.eq(c.reanimLimb, "gelatek")
T.eq(cleaned({ hatReanim = "gelatek" }).hatReanim, "", "a limb reanimation can't be the hat one")
T.eq(cleaned({ hatReanim = "uhhhhhh" }).hatReanim, "")
T.eq(cleaned({ reanimLimb = "fdless" }).reanimLimb, "gelatek", "a hat reanimation can't be the limb one")
T.eq(cleaned({ reanimLimb = "atsuko" }).reanimLimb, "gelatek")
for _, bad in ipairs({ "", "other", "FDless", "fdless ", "uhhhhhh_hat", "uhhhhhh_limb" }) do
	T.eq(cleaned({ hatReanim = bad }).hatReanim, "", "hat: " .. bad)
	T.eq(cleaned({ reanimLimb = bad }).reanimLimb, "gelatek", "limb: " .. bad)
end
for _, bad in ipairs({ 5, true, false, {}, 0 / 0 }) do
	T.eq(cleaned({ hatReanim = bad }).hatReanim, "", "hat not a string: " .. type(bad))
	T.eq(cleaned({ reanimLimb = bad }).reanimLimb, "gelatek", "limb not a string: " .. type(bad))
end
T.eq(Core.REANIM_PICKS.hatReanim.default, "")
T.eq(Core.REANIM_PICKS.hatReanim.ids[""], nil, "an empty pick is not an id")
T.eq(cleaned({ reanimHat = "fdless" }).hatReanim, "", "the old setting from before this update is not read")
T.eq(Core.REANIM_PICKS.reanimLimb.default, "gelatek")
T.eq(count(Core.REANIM_PICKS.hatReanim.ids), 2)
T.eq(count(Core.REANIM_PICKS.reanimLimb.ids), 2)

T.section("reanim_settings: options are kept for the four only")
local o = cleaned({
	reanimOpts = {
		fdless = { fling = true, power = 4.5, name = "x" },
		atsuko = { placeholders = false },
		gelatek = { speed = 2 },
		uhhhhhh = { mode = "calm" },
		hacker = { fling = true },
		[5] = { fling = true },
	},
})
T.eq(count(o.reanimOpts), 4)
T.eq(o.reanimOpts.fdless.fling, true)
T.eq(o.reanimOpts.fdless.power, 4.5)
T.eq(o.reanimOpts.fdless.name, "x")
T.eq(o.reanimOpts.atsuko.placeholders, false)
T.eq(o.reanimOpts.gelatek.speed, 2)
T.eq(o.reanimOpts.uhhhhhh.mode, "calm")
T.eq(o.reanimOpts.hacker, nil)
T.eq(o.reanimOpts[5], nil)
T.eq(count(cleaned({ reanimOpts = { fdless = 5, atsuko = "text", gelatek = true } }).reanimOpts), 0, "an id with something that is not a table is dropped")
T.eq(count(cleaned({ reanimOpts = "text" }).reanimOpts), 0)
T.eq(count(cleaned({ reanimOpts = 5 }).reanimOpts), 0)
T.eq(count(cleaned({ reanimOpts = true }).reanimOpts), 0)
T.eq(type(cleaned({ reanimOpts = "text" }).reanimOpts), "table")
T.eq(count(cleaned({ reanimOpts = { fdless = {} } }).reanimOpts.fdless), 0)
T.eq(type(cleaned({ reanimOpts = { fdless = {} } }).reanimOpts.fdless), "table", "an empty set stays as an empty set")

T.section("reanim_settings: values")
local v = cleaned({
	reanimOpts = {
		fdless = {
			yes = true,
			no = false,
			int = 7,
			neg = -5,
			zero = 0,
			float = 0.25,
			nan = 0 / 0,
			inf = math.huge,
			ninf = -math.huge,
			big = 1e9,
			nbig = -1e9,
			edge = 999999999,
			nedge = -999999999,
			text = "hello",
			empty = "",
			tbl = { 1 },
			fn = function() end,
		},
	},
}).reanimOpts.fdless
T.eq(v.yes, true)
T.eq(v.no, false)
T.eq(v.int, 7)
T.eq(v.neg, -5)
T.eq(v.zero, 0)
T.eq(v.float, 0.25)
T.eq(v.nan, nil, "not a number is dropped")
T.eq(v.inf, nil)
T.eq(v.ninf, nil)
T.eq(v.big, nil, "a billion is too big")
T.eq(v.nbig, nil)
T.eq(v.edge, 999999999)
T.eq(v.nedge, -999999999)
T.eq(v.text, "hello")
T.eq(v.empty, "")
T.eq(v.tbl, nil, "tables are dropped")
T.eq(v.fn, nil, "functions are dropped")
local s80 = string.rep("a", 80)
local s81 = string.rep("a", 81)
local long = cleaned({ reanimOpts = { fdless = { ok = s80, bad = s81 } } }).reanimOpts.fdless
T.eq(long.ok, s80, "80 characters are kept")
T.eq(long.bad, nil, "81 characters are not")

T.section("reanim_settings: keys")
local k32 = string.rep("k", 32)
local k33 = string.rep("k", 33)
local keys = cleaned({ reanimOpts = { fdless = { [k32] = 1, [k33] = 2, [1] = 3, [true] = 4 } } }).reanimOpts.fdless
T.eq(keys[k32], 1, "32 characters are kept")
T.eq(keys[k33], nil, "33 characters are not")
T.eq(keys[1], nil, "a number is not a name")
T.eq(count(keys), 1)

T.section("reanim_settings: at most forty options for each")
local many = {}
for i = 1, 60 do
	many["opt" .. i] = i
end
T.eq(count(cleaned({ reanimOpts = { fdless = many } }).reanimOpts.fdless), 40)
local exactly = {}
for i = 1, 40 do
	exactly["opt" .. i] = i
end
T.eq(count(cleaned({ reanimOpts = { fdless = exactly } }).reanimOpts.fdless), 40)
local under = {}
for i = 1, 39 do
	under["opt" .. i] = i
end
T.eq(count(cleaned({ reanimOpts = { fdless = under } }).reanimOpts.fdless), 39)
local bad = {}
for i = 1, 45 do
	bad["opt" .. i] = i
end
for i = 1, 10 do
	bad["junk" .. i] = {}
end
T.eq(count(cleaned({ reanimOpts = { fdless = bad } }).reanimOpts.fdless), 40, "values that are dropped do not use up the forty")
local each = cleaned({ reanimOpts = { fdless = many, atsuko = many } }).reanimOpts
T.eq(count(each.fdless), 40)
T.eq(count(each.atsuko), 40, "the limit is for each reanimation")

T.section("reanim_settings: a clean copy")
local raw = { fdless = { fling = true } }
local holder = { reanimOpts = raw }
clean(holder)
T.eq(holder.reanimOpts ~= raw, true, "the saved table is replaced, not changed")
T.eq(holder.reanimOpts.fdless ~= raw.fdless, true)
T.eq(raw.fdless.fling, true)
local twice = cleaned({ hatReanim = "fdless", reanimLimb = "uhhhhhh", reanimOpts = { fdless = { fling = true, power = 3 } } })
local snapshot = { twice.hatReanim, twice.reanimLimb, twice.reanimOpts.fdless.fling, twice.reanimOpts.fdless.power, count(twice.reanimOpts) }
clean(twice)
T.eq(twice.hatReanim, snapshot[1])
T.eq(twice.reanimLimb, snapshot[2])
T.eq(twice.reanimOpts.fdless.fling, snapshot[3])
T.eq(twice.reanimOpts.fdless.power, snapshot[4])
T.eq(count(twice.reanimOpts), snapshot[5], "cleaning twice changes nothing")
local other = cleaned({ theme = "midnight", hatReanim = "fdless" })
T.eq(other.theme, "midnight", "other settings are not touched")

T.section("reanim_settings: how the hub uses it")
T.eq(occurrences("\thatReanim = \"\",\n"), 1, "no default hat reanimation")
T.eq(occurrences("\treanimHat = "), 0, "the old key is gone")
T.eq(occurrences("\treanimLimb = \"gelatek\",\n"), 1, "the default limb reanimation")
T.eq(occurrences("\treanimOpts = {},\n"), 1)
T.eq(occurrences("Core.cleanReanim(S)"), 1, "settings are cleaned when they load")
T.eq(occurrences("function Core.cleanReanim(s)"), 1)
local at = string.find(src, "Core.cleanReanim(S)", 1, true)
local norm = string.find(src, "function Core.normalizeSettings()", 1, true)
local nextFn = norm and string.find(src, "\nfunction ", norm + 10, true)
T.ok(at ~= nil and norm ~= nil and nextFn ~= nil and at > norm and at < nextFn, "the cleaning call is inside normalizeSettings")
T.eq(occurrences("Core.REANIM_NEED = 10\n"), 1)

T.section("reanim_settings: saved paths follow the scripts that left the FDless folder")
T.eq(Core.movedPath("Scripts/Hat/FDless/NeptunianV.lua"), "Scripts/Hat/NeptunianV.lua")
T.eq(Core.movedPath("Scripts/Hat/FDless/DubstepGun.lua"), "Scripts/Hat/DubstepGunOriginal.lua", "the original dubstep gun got a new name")
T.eq(Core.movedPath("Scripts/Hat/DubstepGun.lua"), "Scripts/Hat/DubstepGun.lua", "the hub's own dubstep gun stays")
T.eq(Core.movedPath("Scripts/Hat/FDless/Mine.lua"), "Scripts/Hat/FDless/Mine.lua", "a script that never moved stays")
T.eq(Core.movedPath(nil), nil)
T.eq(Core.movedPath(5), 5)
local moved = 0
for from, to in pairs(Core.MOVED_SCRIPTS) do
	moved += 1
	T.ok(string.find(from, "^Scripts/Hat/FDless/") ~= nil and string.find(to, "^Scripts/Hat/[^/]+%.lua$") ~= nil, from .. " -> " .. to)
end
T.eq(moved, 10, "ten scripts moved")
local s = {
	recent = { "Scripts/Hat/FDless/LastStar.lua", "Scripts/Hat/LastStar.lua", "Scripts/Hat/AK47.lua", "Scripts/Hat/FDless/DubstepGun.lua" },
	favorites = { ["Scripts/Hat/FDless/Addict.lua"] = true, ["Scripts/Hat/R6.lua"] = true },
	perScript = { ["Scripts/Hat/FDless/TheHotline.lua"] = { a = 1 }, ["Scripts/Hat/MasterChief.lua"] = { b = 2 }, ["Scripts/Hat/FDless/MasterChief.lua"] = { c = 3 } },
	reanimSel = "Scripts/Hat/FDless/RealityOrbGlitcher.lua",
	theme = "midnight",
}
Core.moveSaved(s)
T.eq(#s.recent, 3, "a script in the recent list twice is listed once")
T.eq(s.recent[1], "Scripts/Hat/LastStar.lua")
T.eq(s.recent[2], "Scripts/Hat/AK47.lua")
T.eq(s.recent[3], "Scripts/Hat/DubstepGunOriginal.lua")
T.eq(s.favorites["Scripts/Hat/Addict.lua"], true, "favorites move")
T.eq(s.favorites["Scripts/Hat/FDless/Addict.lua"], nil)
T.eq(s.favorites["Scripts/Hat/R6.lua"], true)
T.eq(s.perScript["Scripts/Hat/TheHotline.lua"].a, 1, "per-script settings move")
T.eq(s.perScript["Scripts/Hat/FDless/TheHotline.lua"], nil)
T.eq(s.perScript["Scripts/Hat/MasterChief.lua"].b, 2, "settings already on the new path win")
T.eq(s.reanimSel, "Scripts/Hat/RealityOrbGlitcher.lua", "the picked script moves")
T.eq(s.theme, "midnight", "other settings are not touched")
local broken = { recent = "x", favorites = 5 }
Core.moveSaved(broken)
T.eq(#broken.recent, 0, "a broken recent list becomes empty")
T.eq(next(broken.favorites), nil, "broken favorites become empty")
T.eq(next(broken.perScript), nil)
T.eq(broken.reanimSel, nil)
local once = { recent = { "Scripts/Hat/FDless/LastStar.lua" }, favorites = {}, perScript = {} }
Core.moveSaved(once)
Core.moveSaved(once)
T.eq(once.recent[1], "Scripts/Hat/LastStar.lua", "running it twice changes nothing more")
T.eq(occurrences("Core.moveSaved(S)"), 1, "saved paths are moved when settings load")
local mv = string.find(src, "Core.moveSaved(S)", 1, true)
T.ok(mv ~= nil and mv > norm and mv < nextFn, "inside normalizeSettings")
