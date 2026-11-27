local Runner = loadmodule("Testing/mocks/boot_runner.lua")

local env = Runner.boot({ seconds = 8, viewW = 1280, viewH = 800 })
local hub, core = env.hub, env.core
T.ok(env.mainOk, "the hub starts: " .. tostring(env.mainErr))
local Panel, Pages = hub.Panel, hub.Pages
local MP = core.ctx.MP
local T_ = core.ctx.T

T.section("music_look: the music page opens clean")
local before = #env.errors
Panel.go("player")
env.run(1.5)
T.eq(Panel.page, "player", "the music page is open")
T.eq(#env.errors, before, "with no errors: " .. table.concat(env.errors, " / "))
local v = MP.nowV
T.ok(v ~= nil, "the now playing view is there")
T.eq(v.hero.BackgroundTransparency, 1, "no card behind the song, just the page")
T.eq(v.backdrop.Visible, false, "no blurred picture behind it")
T.eq(v.disc.Visible, false, "no spinning record")
T.eq(v.srcText.Visible, false, "no shouty label above the cover")
T.eq(v.title.TextSize, 18, "a clear title")
local art = v.art.frame
T.eq(art.Size.X.Offset, art.Size.Y.Offset, "the cover is square")
T.ok(art.Size.X.Offset >= 140, "and big: " .. tostring(art.Size.X.Offset))
local corner = art:FindFirstChildOfClass("UICorner")
T.ok(corner and corner.CornerRadius.Offset <= 6, "with small corners")

T.section("music_look: white play button, white progress")
local ctl = v.hero:FindFirstChild("Controls")
local play = ctl and ctl:FindFirstChild("play-fill")
T.ok(play ~= nil, "the play button is there")
T.eq(play and play.BackgroundColor3, T_.text, "it's white, not the accent")
T.eq(v.fill.BackgroundColor3, T_.text, "the progress is white too")

T.section("music_look: tabs are a thin underline")
local pg = Pages.player
T.eq(pg.tabBar.BackgroundTransparency, 1, "no box behind the tabs")
T.eq(pg.pill.Size.Y.Offset, 2, "the open tab has a 2px line under it")
T.ok(pg.tabBar:FindFirstChild("Line") ~= nil, "over a thin divider")
local u1 = pg.pill.Position.X.Offset
Panel.setTab(pg, 3)
env.run(0.6)
T.ok(pg.pill.Position.X.Offset > u1, "the line moves to the open tab")
T.ok(pg.pill.Size.X.Offset < pg.tabW[3], "and is only as wide as the word")
T.eq(#env.errors, before, "still no errors")

T.section("music_look: players are flat rows")
Panel.go("players")
env.run(1)
T.eq(#env.errors, before, "the players page opens clean: " .. table.concat(env.errors, " / "))
local PP = hub.Pages.players
local sf = PP.views and PP.views[1]
local me = sf and sf:FindFirstChild("P_" .. game:GetService("Players").LocalPlayer.Name)
T.ok(me ~= nil, "your own row is there")
if me then
	T.eq(me.BackgroundTransparency, 1, "rows have no card behind them")
	T.ok(me:FindFirstChild("Line") ~= nil, "just a thin line between them")
	T.eq(me:FindFirstChild("Right").Text, "You", "your row says You")
end

T.section("music_look: main scripts rows are flat too")
Panel.go("scripts")
env.run(1.5)
T.eq(#env.errors, before, "main scripts opens clean: " .. table.concat(env.errors, " / "))
local SP = hub.Scripts
local found = nil
for _, list in pairs(SP.refs or {}) do
	for _, r in ipairs(list) do
		found = found or r
	end
end
T.ok(found ~= nil, "there are script rows")
if found then
	T.eq(found.stroke.Transparency, 1, "no accent outline on the rows")
	T.eq(found.box.BackgroundColor3, T_.card2, "the tile behind the icon is neutral, not the accent")
	T.ok(found.row:FindFirstChild("Line") ~= nil, "rows sit on thin lines")
	core.Reanim.select(found.e.path)
	SP.updateStatus()
	env.run(0.4)
	T.eq(found.row.BackgroundTransparency, 0, "the picked one gets a soft background")
	T.eq(found.name.TextColor3, core.ctx.accentColor(), "and its name in the accent")
end
