local Mock = loadmodule("Testing/mocks/roblox_mock.lua")

local function boot(opts)
	local env = Mock.install(opts)
	local mod = loadmodule("Hub/modules/island.lua")
	mod.init(env.ctx)
	return env, env.ctx.Island, env.ctx
end

local function stateOf(Island)
	return Island.stateName()
end

T.section("island_view: loads and starts closed")
local env, Island, ctx = boot()
T.ok(Island.available)
T.eq(stateOf(Island), "closed")
T.eq(Island.open, false)
T.eq(Island.frame.Visible, false)
T.eq(#ctx.NP.views, 1)

T.section("island_view: tap opens with a staged entrance")
local act = Island.tap()
T.eq(act, "open")
T.eq(stateOf(Island), "opening")
T.eq(Island.open, true)
T.eq(Island.frame.Visible, true)
T.eq(ctx.Pill.frame.ZIndex, 4000)
T.eq(Island.catcher.Visible, true)
env.advance(0.15)
T.eq(stateOf(Island), "opening")
env.advance(0.7)
T.eq(stateOf(Island), "open")
for name, s in pairs(Island.slots) do
	T.eq(s.frame.Visible, true, "slot visible " .. name)
	T.eq(s.frame.ClassName, "Frame", "slot " .. name .. " is a plain frame, no CanvasGroup to go blank on phones")
end
T.eq(Island.inner.Visible, true)
T.eq(Island.inner.ClassName, "Frame")
T.eq(Island.frame.ZIndex, 4001, "it sits above the top bar")
T.ok(type(Island.bottom()) == "number" and Island.bottom() > 26, "the bar says where its bottom edge is, so notifications show under it")

T.section("island_view: tap closes and restores the pill")
act = Island.tap()
T.eq(act, "close")
T.eq(Island.open, false)
env.advance(0.9)
T.eq(stateOf(Island), "closed")
T.eq(Island.frame.Visible, false)
T.eq(ctx.Pill.frame.ZIndex, 50)
T.eq(Island.catcher.Visible, false)
for name, s in pairs(Island.slots) do
	T.eq(s.frame.Visible, false, "slot reset " .. name)
end
T.eq(Island.bottom(), nil, "closed, it takes no room")

T.section("island_view: reopen works")
T.eq(Island.tap(), "open")
env.advance(0.9)
T.eq(stateOf(Island), "open")
Island.hide()
env.advance(0.9)
T.eq(stateOf(Island), "closed")

T.section("island_view: tap during opening reverses")
T.eq(Island.tap(), "open")
env.advance(0.1)
T.eq(Island.tap(), "close")
T.eq(stateOf(Island), "closing")
env.advance(1.5)
T.eq(stateOf(Island), "closed")
T.eq(Island.frame.Visible, false)
T.eq(ctx.Pill.frame.ZIndex, 50)

T.section("island_view: tap during closing reopens")
T.eq(Island.tap(), "open")
env.advance(0.9)
T.eq(Island.tap(), "close")
env.advance(0.1)
T.eq(Island.tap(), "open")
T.eq(stateOf(Island), "opening")
env.advance(1.5)
T.eq(stateOf(Island), "open")
T.eq(Island.frame.Visible, true)
Island.hide(true)
T.eq(stateOf(Island), "closed")

T.section("island_view: rapid taps settle without a stuck state")
for i = 1, 50 do
	Island.tap()
	env.advance(0.01)
end
env.advance(2)
T.eq(stateOf(Island), "closed")
T.eq(Island.frame.Visible, false)
T.eq(Island.open, false)
T.eq(ctx.Pill.frame.ZIndex, 50)
for i = 1, 11 do
	Island.tap()
	env.advance(0.013)
end
env.advance(2)
T.eq(stateOf(Island), "open")
Island.hide(true)

T.section("island_view: nothing playing opens home")
ctx.NP.track = false
T.eq(Island.tap(), "home")
T.eq(stateOf(Island), "closed")
T.eq(Island.frame.Visible, false)
ctx.NP.track = true

T.section("island_view: track change while open keeps it open")
Island.tap()
env.advance(0.9)
ctx.NP.key = "local:2"
for _, v in ipairs(ctx.NP.views) do
	ctx.NP.render(v)
end
T.eq(stateOf(Island), "open")
T.eq(Island.v.title.Text, "Song local:2")
env.advance(0.5)
T.eq(Island.slots.text.frame.Visible, true)

T.section("island_view: track lost while open closes it")
ctx.NP.track = false
Island.sync()
T.eq(stateOf(Island), "closing")
env.advance(1)
T.eq(stateOf(Island), "closed")
ctx.NP.track = true

T.section("island_view: hub hide while opening")
Island.tap()
env.advance(0.1)
ctx.Bus.fire("hubhide")
T.eq(stateOf(Island), "closed")
T.eq(Island.frame.Visible, false)
env.advance(2)
T.eq(stateOf(Island), "closed")
T.eq(Island.frame.Visible, false)

T.section("island_view: outside tap, escape and swipe")
Island.tap()
env.advance(0.9)
Island.catcher.Activated:Fire()
env.advance(0.9)
T.eq(stateOf(Island), "closed")
Island.tap()
env.advance(0.9)
ctx.UserInputService.InputBegan:Fire({ KeyCode = "KeyCode.Other" }, false)
T.eq(stateOf(Island), "open")
ctx.UserInputService.InputBegan:Fire({ KeyCode = "KeyCode.Escape" }, true)
T.eq(stateOf(Island), "closing")
env.advance(0.9)
Island.tap()
env.advance(0.9)
Island.frame.InputBegan:Fire({ UserInputType = "UserInputType.Touch", Position = { Y = 300 } })
ctx.UserInputService.InputChanged:Fire({ UserInputType = "UserInputType.Touch", Position = { Y = 290 } })
T.eq(stateOf(Island), "open")
ctx.UserInputService.InputChanged:Fire({ UserInputType = "UserInputType.Touch", Position = { Y = 260 } })
T.eq(stateOf(Island), "closing")
env.advance(0.9)
T.eq(stateOf(Island), "closed")

T.section("island_view: tapping the island surface toggles")
Island.tap()
env.advance(0.9)
T.eq(stateOf(Island), "open")
Island.bg.Activated:Fire()
T.eq(stateOf(Island), "closing")
env.advance(0.1)
Island.bg.Activated:Fire()
T.eq(stateOf(Island), "opening")
env.advance(1.5)
T.eq(stateOf(Island), "open")
Island.hide(true)

T.section("island_view: lyric block sizes to its content")
ctx.NP.lyric = { cur = "short", nxt = "next", status = "synced" }
Island.tap()
env.advance(0.9)
for _, v in ipairs(ctx.NP.views) do
	ctx.NP.render(v)
end
local shortH = Island.frame.Size.Y.Offset
env.advance(0.5)
shortH = Island.frame.Size.Y.Offset
ctx.NP.lyric = { cur = "this is a really long lyric line that has to wrap onto a second row for sure", nxt = "next", status = "synced" }
for _, v in ipairs(ctx.NP.views) do
	ctx.NP.render(v)
end
env.advance(0.5)
local longH = Island.frame.Size.Y.Offset
T.ok(longH > shortH, "taller for long lines: " .. tostring(shortH) .. " -> " .. tostring(longH))
ctx.NP.lyric = { cur = "", nxt = "", status = "none" }
for _, v in ipairs(ctx.NP.views) do
	ctx.NP.render(v)
end
env.advance(0.5)
T.eq(Island.frame.Size.Y.Offset, 170)
ctx.NP.lyric = { cur = "Looking for the words...", nxt = "", status = "loading", res = { status = "loading" } }
for _, v in ipairs(ctx.NP.views) do
	ctx.NP.render(v)
end
env.advance(0.5)
T.eq(Island.frame.Size.Y.Offset, 170)
ctx.NP.lyric = { cur = "x", nxt = "y", status = "plain", res = { status = "plain", lines = { { text = "first" }, { text = "" }, { text = "third" } } } }
for _, v in ipairs(ctx.NP.views) do
	ctx.NP.render(v)
end
env.advance(0.5)
T.eq(Island.v.lyCur.Text, "first")
T.eq(Island.v.lyNext.Text, "third")
Island.hide(true)

T.section("island_view: animations off is instant")
local env2, Island2, ctx2 = boot({ animations = false })
T.eq(Island2.tap(), "open")
T.eq(stateOf(Island2), "open")
T.eq(Island2.frame.Visible, true)
T.eq(Island2.inner.Visible, true)
T.eq(Island2.tap(), "close")
T.eq(stateOf(Island2), "closed")
T.eq(Island2.frame.Visible, false)
T.eq(ctx2.Pill.frame.ZIndex, 50)

T.section("island_view: from a bottom spot it opens upwards")
do
	local envB, IslandB, ctxB = boot()
	T.eq(IslandB.rect(), nil, "closed, it takes no room")
	ctxB.Core.barLow = function()
		return true
	end
	ctxB.Pill.frame.AnchorPoint = Vector2.new(0, 1)
	ctxB.Pill.frame.Position = UDim2.new(0, 12, 1, -6)
	T.eq(IslandB.tap(), "open")
	envB.advance(1)
	T.eq(IslandB.frame.AnchorPoint.Y, 1, "it grows up from the bar")
	local x, y, w, h = IslandB.rect()
	T.ok(x ~= nil and y + h <= 720 - 6 and y >= 8, "and stays on the screen: " .. tostring(y) .. " " .. tostring(h))
	T.ok(x >= 8, "pushed in from the left edge when the bar sits in the corner")
	T.eq(IslandB.bottom(), nil, "nothing below it to move")
	T.eq(IslandB.tap(), "close")
	envB.advance(1)
	ctxB.Core.barLow = function()
		return false
	end
	ctxB.Pill.frame.AnchorPoint = Vector2.new(1, 0)
	ctxB.Pill.frame.Position = UDim2.new(1, -12, 0, 6)
	T.eq(IslandB.tap(), "open")
	envB.advance(1)
	T.eq(IslandB.frame.AnchorPoint.Y, 0, "from the top right it drops down")
	local x2, y2, w2 = IslandB.rect()
	T.ok(x2 + w2 <= 1280 - 8, "and stays inside the right edge")
	T.eq(y2, 8, "right under the top of the screen")
end

T.section("island_view: destroy leaves nothing behind")
local env3, Island3, ctx3 = boot()
local mod3 = loadmodule("Hub/modules/island.lua")
T.ok(ctx3.UserInputService.InputBegan:Count() >= 1)
mod3.destroy()
T.eq(ctx3.UserInputService.InputBegan:Count(), 0)
T.eq(ctx3.UserInputService.InputChanged:Count(), 0)
T.eq(Island3.frame.Destroyed, true)
T.eq(Island3.catcher.Destroyed, true)
local env4, Island4 = boot()
T.eq(stateOf(Island4), "closed")
T.eq(Island4.tap(), "open")
