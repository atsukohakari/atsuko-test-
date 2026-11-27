local Mock = loadmodule("Testing/mocks/roblox_mock.lua")

local function boot(opts)
	local env = Mock.install(opts)
	local ctx = env.ctx
	ctx.T.green, ctx.T.red, ctx.T.yellow, ctx.T.ink, ctx.T.card2 = "green", "red", "yellow", "ink", "card2"
	ctx.Toast = { time = function()
		return 3
	end }
	env.pings = 0
	ctx.Sfx = { play = function()
		env.pings = env.pings + 1
	end }
	env.windows = {}
	ctx.Win = {
		show = function(id, def)
			local body = Instance.new("Frame")
			def.build(nil, body)
			env.windows[id] = { def = def, body = body }
		end,
		close = function(id)
			env.windows[id] = nil
		end,
	}
	local mod = loadmodule("Hub/modules/island_notify.lua")
	mod.init(ctx)
	return env, mod, ctx
end

local function tap(mod)
	mod.parts().hit.Activated:Fire()
end

local function P(mod)
	return mod.parts()
end

T.section("island_notify: one notification grows out of the top bar")
local env, N, ctx = boot()
local f = N.frame()
T.eq(f.Visible, false, "nothing shows at first")
T.eq(f.ZIndex, 4100, "it sits above the top bar and the island")
local item = N.push("Reanimated", "Ban Hammer is running on FDless", "ok")
T.ok(item ~= nil)
T.eq(N.current(), item, "it shows right away")
T.eq(f.Visible, true)
T.eq(f.Size.X.Offset, 150, "it starts at the top bar's size")
T.eq(f.Size.Y.Offset, 26)
env.advance(0.4)
T.eq(f.Size.X.Offset, 360, "then grows to a notification")
T.eq(f.Size.Y.Offset, 56)
T.eq(P(N).title.Text, "Reanimated")
T.eq(P(N).body.Text, "Ban Hammer is running on FDless")
T.eq(P(N).mark.BackgroundColor3, "green", "a done one is green")
T.eq(env.pings, 1, "with the notification sound")
env.advance(3.2)
T.eq(N.current(), nil, "after its time it folds away")
env.advance(0.4)
T.eq(f.Visible, false, "back into the top bar")

T.section("island_notify: many at once wait in line")
N.push("One", "first", "info")
N.push("Two", "second", "info")
N.push("Three", "third", "warn")
T.eq(N.current().title, "One", "the first shows")
T.eq(#N.queued(), 2, "the rest wait")
T.eq(P(N).count.Visible, true, "a count says how many")
T.eq(P(N).count.Text, "+2")
N.push("One", "first", "info")
T.eq(#N.queued(), 2, "the same one again doesn't queue twice")
tap(N)
env.advance(0.4)
T.eq(N.current().title, "Two", "a tap moves on to the next")
T.eq(P(N).count.Text, "+1")
env.advance(3.5)
T.eq(N.current().title, "Three", "and the next comes by itself")
T.eq(P(N).count.Visible, false, "no count once the line is empty")
env.advance(3.5)
T.eq(N.current(), nil)

T.section("island_notify: errors stay until you see them")
N.push("Last Star", "The script hit an error", "error")
local err = N.current()
T.eq(P(N).mark.BackgroundColor3, "red", "an error is red")
T.eq(P(N).ring.Color, "red", "with a red ring")
env.advance(10)
T.eq(N.current(), err, "it's still there after ten seconds")
tap(N)
env.advance(0.4)
T.eq(N.current(), nil, "a tap clears it")

T.section("island_notify: long ones open with a tap")
local long = string.rep("This is a long notification that keeps going. ", 4)
N.push("Saved", long, "info")
local li = N.current()
T.eq(li.expandable, true, "a long text can open")
T.eq(P(N).body.TextTruncate, Enum.TextTruncate.AtEnd, "it's cut short at first")
T.eq(tap(N), nil)
env.advance(0.4)
T.eq(li.expanded, true, "a tap opens the whole text")
T.ok(f.Size.Y.Offset > 56, "the island grows to fit it: " .. tostring(f.Size.Y.Offset))
T.eq(P(N).body.TextTruncate, Enum.TextTruncate.None)
tap(N)
env.advance(0.4)
T.eq(N.current(), nil, "a second tap closes it")

T.section("island_notify: buttons work inside the island")
local picked = nil
N.push("Gelatek", "Stopping respawns you. Continue?", "info", nil, { buttons = { { text = "Cancel", fn = function()
	picked = "Cancel"
end }, { text = "Continue", fn = function()
	picked = "Continue"
end } } })
local bi = N.current()
T.eq(bi.expandable, true, "a notification with buttons opens")
env.advance(20)
T.eq(N.current(), bi, "and waits for an answer")
tap(N)
env.advance(0.4)
T.eq(bi.expanded, true)
T.eq(P(N).row.Visible, true, "the buttons show")
T.eq(P(N).buttons[1].Text, "Cancel")
T.eq(P(N).buttons[2].Text, "Continue")
tap(N)
T.eq(N.current(), bi, "tapping the island doesn't skip the question")
P(N).buttons[2].Activated:Fire()
T.eq(picked, "Continue", "the button's answer goes back to the script")
env.advance(0.4)
T.eq(N.current(), nil, "and the island folds away")

T.section("island_notify: the history keeps the last ones")
local h = N.history()
T.ok(#h >= 8, "everything shown is in the history: " .. #h)
T.eq(h[1].title, "Gelatek", "newest first")
for i = 1, 40 do
	N.push("Spam " .. i, "x", "info")
end
T.eq(#N.history(), N.KEEP, "only the last " .. N.KEEP .. " are kept")
T.ok(#N.queued() <= N.QUEUE, "the line never grows past " .. N.QUEUE)
N.openHistory()
local win = env.windows.notices
T.ok(win ~= nil, "the history opens in a window")
T.eq(win and win.def.title, "Recent notifications")
T.ok(win ~= nil, "with a row for each one")
N.clearHistory()
T.eq(#N.history(), 0, "and it can be cleared")
N.destroy()
T.eq(N.alive(), false)
T.eq(N.push("x", "y"), nil, "a stopped module ignores new ones")

T.section("island_notify: a bottom bar grows upwards")
do
	local env2, N2, ctx2 = boot()
	ctx2.Core.barLow = function()
		return true
	end
	ctx2.Pill.frame.Position = UDim2.new(0.5, 0, 1, -36)
	N2.push("Hi", "there")
	env2.advance(0.4)
	T.eq(N2.frame().AnchorPoint.Y, 1, "it hangs up from the bar")
	N2.destroy()
end

T.section("island_notify: the router hands over buttons")
do
	local Router = loadmodule("Hub/modules/notify_router.lua")
	local got = {}
	local island = true
	local r = Router.new({ general = true, toast = function(t, x, k, d, o)
		got[#got + 1] = { t, x, o }
	end, buttons = function()
		return island
	end })
	local invoked = nil
	local value = { Title = "Gelatek", Text = "Continue?", Button1 = "No", Button2 = "Yes", Callback = { Invoke = function(_, label)
		invoked = label
	end } }
	T.eq(r:handle("SendNotification", value), "swallow", "with the island on, a pop-up with buttons goes to the island")
	local opts = got[1] and got[1][3]
	T.ok(opts and #opts.buttons == 2, "with both buttons")
	if opts then
		opts.buttons[2].fn()
	end
	T.eq(invoked, "Yes", "pressing one answers the script that asked")
	island = false
	T.eq(r:handle("SendNotification", value), "pass", "in classic mode Roblox shows it, so its buttons still work")
	T.eq(r:handle("SendNotification", { Title = "Plain", Text = "no buttons" }), "swallow", "a plain one is still caught")
	T.eq(got[#got][3], nil)
end
