local Runner = loadmodule("Testing/mocks/boot_runner.lua")

local env = Runner.boot({ seconds = 8, viewW = 1600, viewH = 900 })
local hub, core = env.hub, env.core
local S, L = hub.S, hub.L
local Toast, Pill, Dock, Shell = core.ctx.Toast, core.ctx.Pill, core.ctx.Dock, core.ctx.Shell
env.run(6)

local function ud(u)
	return string.format("%g,%g,%g,%g", u.X.Scale, u.X.Offset, u.Y.Scale, u.Y.Offset)
end

local function v2(v)
	return string.format("%g,%g", v.X, v.Y)
end

local function box()
	local p = core.ToastBox.Position
	return p.X.Offset, p.Y.Offset
end

local function place(spot)
	S.toastPos = spot
	core.toastSpot = nil
	Toast.place(true)
	env.run(0.5)
	return box()
end

local function shown()
	local n = 0
	for _, t in ipairs(Toast.list) do
		if not t.gone then
			n += 1
		end
	end
	return n
end

local function clear()
	for _, t in ipairs(table.clone(Toast.list)) do
		Toast.dismiss(t)
	end
	env.run(0.6)
end

T.section("toasts: six spots")
T.eq(#core.TOAST_SPOTS, 6, "six spots for notifications")
T.same((function()
	local out = {}
	for _, o in ipairs(core.TOAST_SPOTS) do
		out[#out + 1] = o[2]
	end
	return out
end)(), { "Top left", "Top middle", "Top right", "Bottom left", "Bottom middle", "Bottom right" }, "named by where they sit")
T.eq(core.spotOf(core.TOAST_SPOTS, "top")[2], "Top middle", "the old top is the top middle")
T.eq(core.spotOf(core.TOAST_SPOTS, "bottom")[2], "Bottom middle", "the old bottom is the bottom middle")
S.toastPos = "middle"
core.normalizeSettings()
T.eq(S.toastPos, "top", "a spot that doesn't exist goes back to the top middle")
S.toastPos = "bottomright"
core.normalizeSettings()
T.eq(S.toastPos, "bottomright", "a corner is kept")

T.section("toasts: where the box sits")
S.statsBar = false
Pill.frame.Visible = false
Dock.shown = false
local W, H = L.W, L.H
local x, y = place("topleft")
T.eq(x, 8, "top left hugs the left edge")
T.eq(y, 8, "and the top")
T.eq(core.toastList.VerticalAlignment, Enum.VerticalAlignment.Top, "and stacks downwards")
x, y = place("top")
T.eq(x, W / 2 - 130, "top middle is centered")
T.eq(y, 8)
x, y = place("topright")
T.eq(x, W - 8 - 260, "top right hugs the right edge")
T.eq(y, 8)
x, y = place("bottomleft")
T.eq(x, 8, "bottom left")
T.eq(y, H - 8 - 180, "sits on the bottom")
T.eq(core.toastList.VerticalAlignment, Enum.VerticalAlignment.Bottom, "and stacks upwards")
x, y = place("bottom")
T.eq(x, W / 2 - 130, "bottom middle")
T.eq(y, H - 8 - 180)
x, y = place("bottomright")
T.eq(x, W - 8 - 260, "bottom right")
T.eq(y, H - 8 - 180)

T.section("toasts: they keep clear of the top bar, the island and the dock")
S.statsBar = true
Pill.frame.Visible = true
S.barPos = "top"
Shell.layout()
env.run(0.5)
local px, py, pw, ph = core.rectOf(Pill.frame)
x, y = place("top")
T.eq(y, py + ph + 6, "under the top bar when both are in the middle")
x, y = place("topleft")
T.eq(y, 8, "a corner away from the bar stays at the top")
S.barPos = "left"
Shell.layout()
env.run(0.5)
px, py, pw, ph = core.rectOf(Pill.frame)
x, y = place("topleft")
T.eq(y, py + ph + 6, "under the bar when the bar sits in the same corner")
x, y = place("topright")
T.eq(y, 8, "the other corner is free")
S.barPos = "bottomright"
Shell.layout()
env.run(0.5)
px, py, pw, ph = core.rectOf(Pill.frame)
x, y = place("bottomright")
T.eq(y + 180, py - 6, "above the bar when the bar sits in that bottom corner")
x, y = place("bottomleft")
T.eq(y, H - 8 - 180, "the other bottom corner is free")
S.barPos = "top"
Shell.layout()
env.run(0.5)
local isl = core.island
local realRect = isl.rect
T.eq(isl.rect(), nil, "a closed island takes no room")
isl.rect = function()
	return W / 2 - 155, 6, 310, 200
end
x, y = place("top")
T.eq(y, 6 + 200 + 8, "notifications move under an open island")
x, y = place("topright")
T.eq(y, 8, "unless they sit in a corner it doesn't reach")
isl.rect = realRect
Dock.shown = true
Dock.frame.Visible = true
S.dockPos = "bottom"
Shell.layout()
env.run(0.5)
local dx, dy = core.rectOf(Dock.frame, Dock.posOn)
x, y = place("bottom")
T.ok(y + 180 <= dy - 10, "above the dock in the bottom middle: " .. (y + 180) .. " vs " .. dy)
S.dockPos = "left"
Shell.layout()
env.run(0.5)
local lx, ly, lw, lh = core.rectOf(Dock.frame, Dock.posOn)
x, y = place("bottomleft")
local hits = x < lx + lw and lx < x + 260 and y < ly + lh and ly < y + 180
T.eq(hits, false, "a corner next to a side dock moves out of its way")
S.dockPos = "bottom"
Shell.layout()
env.run(0.5)

T.section("toasts: they slide in from their side")
S.toastPos = "topleft"
T.eq(ud(Toast.from()), "0,-300,0,0", "left corners come in from the left")
S.toastPos = "bottomright"
T.eq(ud(Toast.from()), "0,300,0,0", "right corners from the right")
S.toastPos = "top"
T.eq(ud(Toast.from()), "0,0,0,-72", "the top middle drops down")
S.toastPos = "bottom"
T.eq(ud(Toast.from()), "0,0,0,72", "the bottom middle rises up")
place("topright")
clear()
hub.Bus.fire("notify", "Slide", "in", "info")
local t = Toast.list[#Toast.list]
T.eq(t and ud(t.from), "0,300,0,0", "a new one starts off to the side")
env.run(1)
T.eq(t and ud(t.card.Position), "0,0,0,0", "and slides into place")
clear()

T.section("toasts: how long they stay counts for all of them")
S.toastTime = 5
hub.Bus.fire("notify", "Short", "asked for 1.5 seconds", "ok", 1.5)
env.run(3)
T.eq(shown(), 1, "a notification that asked for a short time stays for the time you picked")
env.run(2.6)
T.eq(shown(), 0, "and goes when that time is up")
S.toastTime = 2
hub.Bus.fire("notify", "Long", "asked for 10 seconds", "info", 10)
env.run(2.6)
T.eq(shown(), 0, "a long one goes after your time too")
hub.Bus.fire("notify", "Plain", "no time given", "info")
env.run(1)
T.eq(shown(), 1)
env.run(1.6)
T.eq(shown(), 0, "and so does one with no time of its own")
S.toastTime = 99
T.eq(Toast.time(), 8, "the time is kept between 1.5 and 8 seconds")
S.toastTime = 3.2

T.section("toasts: the settings cards")
hub.Panel.show("settings")
env.run(1)
hub.Panel.setTab(hub.Pages.settings, 1)
env.run(2)
local cards = {}
for _, d in ipairs(hub.Root:GetDescendants()) do
	if d.Name == "Spot" then
		local title
		for _, c in ipairs(d:GetChildren()) do
			if c:IsA("TextLabel") then
				title = c.Text
			end
		end
		cards[tostring(title)] = d
	end
end
local where = cards["Where they show up"]
T.ok(where ~= nil, "Settings > General has where they show up")
local names = {}
local grid = where and where:FindFirstChild("Spots")
for _, c in ipairs(grid and grid:GetChildren() or {}) do
	if c:IsA("TextButton") then
		names[#names + 1] = c.Name
	end
end
table.sort(names)
T.same(names, { "bottom", "bottomleft", "bottomright", "top", "topleft", "topright" }, "with six spots to tap")
local label = grid and grid:FindFirstChild("bottomleft") and grid:FindFirstChild("bottomleft"):FindFirstChild("Label")
T.eq(label and label.Text, "Bottom left")
S.toastPos = "top"
grid:FindFirstChild("bottomleft").Activated:Fire()
env.run(1.5)
T.eq(S.toastPos, "bottomleft", "tapping a spot moves them there")
T.ok(string.find(env.files["Atsuko Hub/settings.json"] or "", "bottomleft", 1, true) ~= nil, "and it is saved")
local bx, by = box()
T.eq(bx, 8, "the box moved to the bottom left")
local said = false
for _, tt in ipairs(Toast.list) do
	if tt.key == "Notifications\0They show up here now" then
		said = true
	end
end
T.ok(said, "a notification shows where they are now")
local bar = cards["Top bar and dynamic island spot"]
T.ok(bar ~= nil, "the top bar and dynamic island get the same six spots")
local bnames = {}
local bgrid = bar and bar:FindFirstChild("Spots")
for _, c in ipairs(bgrid and bgrid:GetChildren() or {}) do
	if c:IsA("TextButton") then
		bnames[#bnames + 1] = c:FindFirstChild("Label") and c:FindFirstChild("Label").Text
	end
end
table.sort(bnames)
T.same(bnames, { "Bottom left", "Bottom middle", "Bottom right", "Top left", "Top middle", "Top right" })
bgrid:FindFirstChild("bottomright").Activated:Fire()
env.run(1)
T.eq(S.barPos, "bottomright", "tapping one moves the bar")
T.eq(v2(Pill.frame.AnchorPoint), "1,1", "into the bottom right corner")
S.toastPos = "top"
S.barPos = "top"
Shell.layout()

T.section("toasts: the top bar and island spots")
local want = {
	left = { 0, 0, UDim2.new(0, 12, 0, 6) },
	top = { 0.5, 0, UDim2.new(0.5, 0, 0, 6) },
	right = { 1, 0, UDim2.new(1, -12, 0, 6) },
	bottomleft = { 0, 1, UDim2.new(0, 12, 1, -6) },
	bottom = { 0.5, 1, UDim2.new(0.5, 0, 1, -6) },
	bottomright = { 1, 1, UDim2.new(1, -12, 1, -6) },
}
for _, o in ipairs(core.BAR_SPOTS) do
	local w = want[o[1]]
	S.barPos = o[1]
	Shell.layout()
	T.eq(v2(Pill.frame.AnchorPoint), v2(Vector2.new(w[1], w[2])), o[2] .. " anchor")
	T.eq(ud(Pill.frame.Position), ud(w[3] + core.moved("bar")), o[2] .. " spot")
	T.eq(core.barLow(), w[2] == 1, o[2] .. (w[2] == 1 and " is on the bottom" or " is on the top"))
end
S.barPos = "weird"
core.normalizeSettings()
T.eq(S.barPos, "top", "a spot that doesn't exist goes back to the top middle")
S.barPos = "bottomleft"
core.normalizeSettings()
T.eq(S.barPos, "bottomleft", "the new corners are kept")
S.barPos = "top"
Shell.layout()
env.run(1)

T.eq(#env.errors, 0, "no errors: " .. table.concat(env.errors, " | "))
