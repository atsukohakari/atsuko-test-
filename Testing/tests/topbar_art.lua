local src = readsource("Hub/AtsukoHub.lua")

local function cut(from, to)
	local a = string.find(src, from, 1, true)
	local b = a and string.find(src, to, a + #from, true)
	T.ok(a ~= nil and b ~= nil, "found " .. from)
	return a and b and string.sub(src, a, b - 1) or ""
end

local setArt = cut("function Pill.setArt(id)", "function Pill.update(")
local barText = cut("function NP.barText()", "\nfunction NP.loadQueue(")

T.section("topbar_art: the top bar shows the song's cover")
Pill = { logo = { Image = "rbxasset://logo.png" } }
Logo = { id = "rbxasset://logo.png" }
local f, err = loadstring(setArt, "=setArt")
T.ok(f ~= nil, "compiles: " .. tostring(err))
f()
Pill.setArt("rbxasset://spotify_cover.jpg")
T.eq(Pill.logo.Image, "rbxasset://spotify_cover.jpg", "while a Spotify song plays, its cover takes the logo's place")
Pill.logo.Image = Logo.id
Pill.setArt("rbxasset://spotify_cover.jpg")
T.eq(Pill.logo.Image, "rbxasset://spotify_cover.jpg", "and comes back if the logo was put over it")
Pill.setArt(nil)
T.eq(Pill.logo.Image, "rbxasset://logo.png", "when the song stops the hub's logo is back")
Logo.id = nil
Pill.setArt(nil)
T.eq(Pill.logo.Image, "", "with no logo either, it's empty")
Pill.logo = nil
Pill.setArt("x")
T.ok(true, "no top bar, nothing breaks")

T.section("topbar_art: the bar text hands the cover over")
S = { musicBar = true }
local info = {}
NP = {
	active = function()
		return true
	end,
	info = function()
		return info
	end,
}
local g, err2 = loadstring(barText, "=barText")
T.ok(g ~= nil, "compiles: " .. tostring(err2))
g()
info = { has = true, title = "Song", artist = "Singer, Other", playing = true, art = "rbxasset://cover.jpg" }
local text, playing, art = NP.barText()
T.ok(type(text) == "string" and string.find(text, "Song", 1, true) == 1 and string.find(text, "Singer", 1, true) ~= nil, "the song and its first artist: " .. tostring(text))
T.eq(playing, true)
T.eq(art, "rbxasset://cover.jpg", "with its cover")
info = { has = true, title = "Roblox song", artist = "", playing = false }
text, playing, art = NP.barText()
T.eq(art, nil, "a song with no cover gives none, so the logo stays")
info = { has = true, title = "Song", artist = "", playing = true, art = "" }
text, playing, art = NP.barText()
T.eq(art, nil, "an empty cover counts as none")
info = { has = false }
text, playing, art = NP.barText()
T.eq(text, nil, "nothing playing, no text")
T.eq(art, nil)
S.musicBar = false
info = { has = true, title = "Song", art = "rbxasset://cover.jpg" }
text, playing, art = NP.barText()
T.eq(text, nil, "the song on the top bar can be turned off")
T.eq(art, nil, "and then the cover isn't used either")

T.section("topbar_art: the hub calls it every half second")
T.ok(string.find(src, "local song, playing, art = NP.barText()", 1, true) ~= nil, "the tick reads the cover")
T.ok(string.find(src, "Pill.setArt(song and art or nil)", 1, true) ~= nil, "and puts it on the bar")
Pill, Logo, S, NP = nil, nil, nil, nil
