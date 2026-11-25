local G = loadmodule("Testing/mocks/gui_mock.lua")
local W = loadmodule("Testing/mocks/art_world.lua")
local Art = loadmodule("Hub/modules/scriptart.lua")

local function setup(opts)
	opts = opts or {}
	local env = G.install({ animations = opts.animations })
	local world = W.new(opts.world)
	local ctx = env.ctx
	ctx.artDeps = world.deps
	local opened = {}
	ctx.Core.loadModule = function(name)
		if name == "imagepicker" and not opts.noPicker then
			return {
				open = function(art, path, kind, scriptName)
					opened[#opened + 1] = { art = art, path = path, kind = kind, name = scriptName }
				end,
			}
		end
		return nil
	end
	Art.init(ctx)
	local UI = ctx.UI
	local parts = {
		cover = UI.new("Frame", { Name = "Cover" }),
		overlay = UI.new("Frame", { Name = "Box" }),
		name = UI.label(nil, { Text = "Name" }),
		sub = UI.label(nil, { Text = "Sub" }),
		heart = UI.button(nil, { Name = "Heart" }),
		chip = UI.new("Frame", { Name = "Chip" }),
	}
	local view = Art.attach(parts)
	return { env = env, world = world, ctx = ctx, parts = parts, view = view, opened = opened, Bus = env.Bus }
end

local function logo(h)
	return h.view.spots.logo
end

local function banner(h)
	return h.view.spots.banner
end

local function entry(path, name)
	return { path = path, name = name or "Script" }
end

local function tap(button)
	button.Activated:Fire()
end

local function loaded(spot)
	spot.picture.IsLoaded = true
	spot.picture:GetPropertyChangedSignal("IsLoaded"):Fire()
end

local function assetResult(id)
	return { ok = true, src = "asset", value = "rbxassetid://" .. id }
end

local function kids(frame, name)
	local out = {}
	for _, child in ipairs(frame:GetChildren()) do
		if child.Name == name then
			out[#out + 1] = child
		end
	end
	return out
end

T.section("scriptart view: the two empty spots")
do
	local h = setup()
	local cover = h.parts.cover
	local b, l = banner(h), logo(h)
	T.eq(b.btn.Name, "BannerSpot")
	T.eq(l.btn.Name, "LogoSpot")
	T.eq(b.btn.Parent, cover)
	T.eq(l.btn.Parent, cover)
	T.eq(b.state, "empty")
	T.eq(l.state, "empty")
	T.eq(b.label.Text, "Add banner")
	T.eq(l.label.Text, "Add logo")
	T.eq(b.icon.IconName, "plus")
	T.eq(l.icon.IconName, "plus")
	T.eq(b.hint.Visible, true)
	T.eq(b.picture.Visible, false)
	T.eq(b.picture.ImageTransparency, 1)
	T.eq(b.dash.Enabled, true, "the dashed outline is on while empty")
	T.eq(l.dash.Enabled, true)
	T.eq(b.btn.ZIndex, 2)
	T.eq(l.btn.ZIndex, 4, "the logo sits above the banner")
	T.eq(h.parts.chip.ZIndex, 6, "the status chip sits above both")
	T.eq(#kids(b.btn, "Picture"), 1)
	T.eq(#b.dash:GetChildren() >= 0, true)
	local gradient = b.dash:FindFirstChildOfClass("UIGradient")
	T.ok(gradient ~= nil, "the outline has its stripes")
	T.eq(#gradient.Transparency.Keypoints, 20, "twenty stripes points, the most Roblox allows")
	local last = gradient.Transparency.Keypoints[20]
	T.eq(gradient.Transparency.Keypoints[1].Time, 0)
	T.eq(last.Time, 1)
	for i = 2, 20 do
		T.ok(gradient.Transparency.Keypoints[i].Time > gradient.Transparency.Keypoints[i - 1].Time, "stripe point " .. i .. " comes after the one before")
	end
	T.eq(h.view.path, nil)
	T.eq(h.view.metrics.height, 165, "laid out at the default width")
end

T.section("scriptart view: sizes follow the card's width")
do
	local h = setup()
	local cover = h.parts.cover
	local m = Art.metrics(320)
	T.eq(cover.Size.Y.Offset, m.height)
	T.eq(cover.Size.X.Scale, 1)
	local b, l = banner(h), logo(h)
	T.eq(b.btn.Position.X.Offset, m.pad)
	T.eq(b.btn.Position.Y.Offset, m.pad)
	T.eq(b.btn.Size.X.Scale, 1)
	T.eq(b.btn.Size.X.Offset, -m.pad * 2)
	T.eq(b.btn.Size.Y.Offset, m.bannerH)
	T.eq(l.btn.Position.X.Offset, m.logoX)
	T.eq(l.btn.Position.Y.Offset, m.logoY)
	T.eq(l.btn.Size.X.Offset, 72)
	T.eq(l.btn.Size.Y.Offset, 72)
	T.eq(h.parts.name.Position.X.Offset, m.textX)
	T.eq(h.parts.name.Position.Y.Offset, m.nameY)
	T.eq(h.parts.name.Size.X.Offset, -(m.textX + 52))
	T.eq(h.parts.sub.Position.Y.Offset, m.subY)
	T.eq(h.parts.heart.Position.X.Offset, -48)
	T.eq(h.parts.heart.Position.Y.Offset, m.heartY)
	T.eq(h.parts.chip.Position.X.Offset, m.chipX)
	cover:TestResize(400, 200)
	local wide = Art.metrics(400)
	T.eq(cover.Size.Y.Offset, wide.height, "the card grows with its width")
	T.eq(b.btn.Size.Y.Offset, wide.bannerH)
	T.eq(l.btn.Position.Y.Offset, wide.logoY)
	T.eq(h.view.lastWidth, 400)
	local sentinel = UDim2.new(1, 0, 0, 999)
	cover.Size = sentinel
	cover:TestResize(400, 999)
	T.eq(cover.Size, sentinel, "the same width does not lay out again")
	cover:TestResize(0, 0)
	T.eq(cover.Size, sentinel, "a card that is not on screen yet is ignored")
	cover:TestResize(240, 100)
	T.eq(cover.Size.Y.Offset, Art.metrics(240).height)
	h.env.ctx.L.scale = 2
	cover:TestResize(480, 100)
	T.eq(cover.Size.Y.Offset, Art.metrics(240).height, "a scaled screen is measured in the hub's own units")
	T.eq(h.view.layout().width, 240, "layout can be asked for by hand")
	h.env.ctx.L.scale = 1
end

T.section("scriptart view: showing a script")
do
	local h = setup()
	h.view.show(entry("Scripts/A.lua", "Alpha"))
	T.eq(h.view.path, "Scripts/A.lua")
	T.eq(h.view.entry.name, "Alpha")
	T.eq(banner(h).state, "empty")
	T.eq(logo(h).state, "empty")
	Art.set("Scripts/A.lua", "logo", assetResult(5))
	local l = logo(h)
	T.eq(l.picture.Image, "rbxassetid://5", "setting a picture shows it")
	T.eq(l.picture.Visible, true)
	T.eq(l.hint.Visible, false)
	T.eq(l.dash.Enabled, false)
	T.eq(l.picture.ImageTransparency, 1, "it starts see-through")
	T.eq(l.state, "loading", "and waits for Roblox to say it loaded")
	T.eq(banner(h).state, "empty", "the banner is untouched")
	loaded(l)
	T.eq(l.state, "set")
	task.wait(0.1)
	T.ok(l.picture.ImageTransparency > 0 and l.picture.ImageTransparency <= 1, "it is fading in")
	task.wait(0.3)
	T.eq(l.picture.ImageTransparency, 0, "and fully shown after the fade")
	Art.set("Scripts/B.lua", "logo", assetResult(6))
	T.eq(l.picture.Image, "rbxassetid://5", "another script's picture is not shown here")
	l.picture.IsLoaded = false
	h.view.show(entry("Scripts/B.lua", "Beta"))
	T.eq(l.picture.Image, "rbxassetid://6", "switching script switches picture")
	T.eq(l.state, "loading")
	h.view.show(entry("Scripts/C.lua", "Gamma"))
	T.eq(l.state, "empty", "a script without one shows the empty spot")
	T.eq(l.picture.Visible, false)
	T.eq(l.hint.Visible, true)
	T.eq(l.label.Text, "Add logo")
	h.view.show(nil)
	T.eq(h.view.path, nil)
	T.eq(l.state, "empty")
	tap(l.btn)
	T.eq(#h.opened, 0, "with no script, tapping does nothing")
end

T.section("scriptart view: already loaded pictures appear at once")
do
	local h = setup()
	h.view.show(entry("Scripts/A.lua"))
	local l = logo(h)
	l.picture.IsLoaded = true
	Art.set("Scripts/A.lua", "logo", assetResult(5))
	T.eq(l.state, "set")
	task.wait(0.4)
	T.eq(l.picture.ImageTransparency, 0)
end

T.section("scriptart view: pictures that are slow or never load")
do
	local h = setup()
	h.view.show(entry("Scripts/A.lua"))
	local l = logo(h)
	Art.set("Scripts/A.lua", "logo", assetResult(5))
	T.eq(l.state, "loading")
	task.wait(1.4)
	T.eq(l.picture.ImageTransparency, 1, "still waiting")
	task.wait(0.2)
	T.eq(l.picture.ImageTransparency, 0, "after a moment it is shown anyway")
	T.eq(l.state, "loading")
	task.wait(6.5)
	T.eq(l.state, "broken", "after eight seconds it is called broken")
	T.eq(l.picture.Visible, false)
	T.eq(l.hint.Visible, true)
	T.eq(l.icon.IconName, "triangle-alert")
	T.eq(l.label.Text, "Tap to fix")
	T.eq(l.dash.Enabled, true)
	T.eq(l.dash.Color, h.env.ctx.T.yellow)
	loaded(l)
	T.eq(l.state, "set", "a picture that loads late is shown after all")
	T.eq(l.picture.Visible, true)
	T.eq(l.hint.Visible, false)
	T.eq(l.dash.Enabled, false)
	local h2 = setup()
	h2.view.show(entry("Scripts/A.lua"))
	Art.set("Scripts/A.lua", "banner", assetResult(5))
	task.wait(9)
	T.eq(banner(h2).state, "broken")
	T.eq(banner(h2).label.Text, "Couldn't load this picture. Tap to fix")
end

T.section("scriptart view: old timers do nothing to a new script")
do
	local h = setup()
	h.view.show(entry("Scripts/A.lua"))
	Art.set("Scripts/A.lua", "logo", assetResult(5))
	task.wait(1)
	h.view.show(entry("Scripts/B.lua"))
	task.wait(10)
	T.eq(logo(h).state, "empty", "the earlier script's timers were cancelled")
	T.eq(logo(h).label.Text, "Add logo")
	Art.set("Scripts/B.lua", "logo", assetResult(6))
	task.wait(0.5)
	Art.set("Scripts/B.lua", "logo", assetResult(7))
	task.wait(7.6)
	T.eq(logo(h).state, "loading", "setting again restarts the wait, so it is not broken yet")
	task.wait(1)
	T.eq(logo(h).state, "broken")
end

T.section("scriptart view: tapping an empty spot opens the picker")
do
	local h = setup()
	h.view.show(entry("Scripts/A.lua", "Alpha"))
	tap(banner(h).btn)
	T.eq(#h.opened, 1)
	T.eq(h.opened[1].path, "Scripts/A.lua")
	T.eq(h.opened[1].kind, "banner")
	T.eq(h.opened[1].name, "Alpha")
	T.eq(h.opened[1].art, Art, "the picker is given the picture store")
	tap(logo(h).btn)
	T.eq(#h.opened, 2)
	T.eq(h.opened[2].kind, "logo")
	T.eq(h.view.menu, nil, "no menu for an empty spot")
	local h2 = setup({ noPicker = true })
	h2.view.show(entry("Scripts/A.lua"))
	tap(logo(h2).btn)
	T.eq(#h2.env.notes, 1, "a picker that didn't load is explained")
	T.ok(string.find(h2.env.notes[1], "Pictures", 1, true) == 1)
end

T.section("scriptart view: tapping a picture opens a small menu")
do
	local h = setup()
	h.view.show(entry("Scripts/A.lua", "Alpha"))
	Art.set("Scripts/A.lua", "logo", assetResult(5))
	loaded(logo(h))
	tap(logo(h).btn)
	local overlay = h.parts.overlay
	T.eq(#kids(overlay, "ArtMenu"), 1)
	T.eq(#kids(overlay, "ArtMenuCatcher"), 1)
	local menu = kids(overlay, "ArtMenu")[1]
	T.eq(#menu:GetChildren() >= 2, true)
	local rows = {}
	for _, child in ipairs(menu:GetChildren()) do
		if string.sub(child.Name, 1, 3) == "Row" then
			rows[#rows + 1] = child
		end
	end
	T.eq(#rows, 2)
	T.eq(rows[1]:FindFirstChildOfClass("TextLabel").Text, "Change")
	T.eq(rows[2]:FindFirstChildOfClass("TextLabel").Text, "Remove")
	T.eq(menu.Size.Y.Offset, 2 * 34 + 8)
	T.eq(menu.ZIndex > overlay.ZIndex, true)
	tap(logo(h).btn)
	T.eq(#kids(overlay, "ArtMenu"), 1, "tapping again replaces the menu, it does not stack")
	T.eq(#kids(overlay, "ArtMenuCatcher"), 1)
	tap(kids(overlay, "ArtMenuCatcher")[1])
	T.eq(#kids(overlay, "ArtMenu"), 0, "tapping outside closes it")
	T.eq(#kids(overlay, "ArtMenuCatcher"), 0)
	T.eq(h.view.menu, nil)
	tap(logo(h).btn)
	local change = kids(overlay, "ArtMenu")[1]:FindFirstChild("Row1")
	tap(change)
	T.eq(#h.opened, 1, "Change opens the picker")
	T.eq(h.opened[1].kind, "logo")
	T.eq(h.opened[1].name, "Alpha")
	T.eq(#kids(overlay, "ArtMenu"), 0, "and closes the menu")
	T.ok(Art.get("Scripts/A.lua", "logo") ~= nil, "the old picture stays until a new one is used")
	tap(logo(h).btn)
	tap(kids(overlay, "ArtMenu")[1]:FindFirstChild("Row2"))
	T.eq(Art.get("Scripts/A.lua", "logo"), nil, "Remove removes it")
	T.eq(logo(h).state, "empty", "and the spot is empty again")
	T.eq(#kids(overlay, "ArtMenu"), 0)
	T.eq(#h.env.notes, 1)
	T.eq(h.env.notes[1], "Logo:Removed")
	T.eq(Art.get("Scripts/B.lua", "logo"), nil)
end

T.section("scriptart view: the menu stays on screen")
do
	local h = setup()
	h.view.show(entry("Scripts/A.lua"))
	Art.set("Scripts/A.lua", "banner", assetResult(5))
	local overlay = h.parts.overlay
	overlay.AbsolutePosition = { X = 100, Y = 50 }
	overlay.AbsoluteSize = { X = 400, Y = 600 }
	local b = banner(h)
	b.btn.AbsolutePosition = { X = 110, Y = 100 }
	b.btn.AbsoluteSize = { X = 380, Y = 100 }
	tap(b.btn)
	local menu = kids(overlay, "ArtMenu")[1]
	T.eq(menu.Position.X.Offset, 16, "just inside the spot's left edge")
	T.eq(menu.Position.Y.Offset, 146, "just under the spot")
	tap(kids(overlay, "ArtMenuCatcher")[1])
	b.btn.AbsolutePosition = { X = 450, Y = 100 }
	tap(b.btn)
	menu = kids(overlay, "ArtMenu")[1]
	T.eq(menu.Position.X.Offset, 400 - 154, "pushed back in from the right edge")
	tap(kids(overlay, "ArtMenuCatcher")[1])
	b.btn.AbsolutePosition = { X = 110, Y = 600 }
	b.btn.AbsoluteSize = { X = 380, Y = 100 }
	tap(b.btn)
	menu = kids(overlay, "ArtMenu")[1]
	T.eq(menu.Position.Y.Offset, 550 - 76 + 4, "opens upward when there is no room below")
	tap(kids(overlay, "ArtMenuCatcher")[1])
	b.btn.AbsolutePosition = { X = 0, Y = 0 }
	b.btn.AbsoluteSize = { X = 10, Y = 10 }
	overlay.AbsolutePosition = { X = 100, Y = 50 }
	tap(b.btn)
	menu = kids(overlay, "ArtMenu")[1]
	T.eq(menu.Position.X.Offset, 4, "never past the left edge")
	T.eq(menu.Position.Y.Offset, 4, "never past the top edge")
end

T.section("scriptart view: a broken picture")
do
	local h = setup()
	h.view.show(entry("Scripts/A.lua", "Alpha"))
	Art.set("Scripts/A.lua", "logo", assetResult(5))
	task.wait(9)
	T.eq(logo(h).state, "broken")
	tap(logo(h).btn)
	local overlay = h.parts.overlay
	local menu = kids(overlay, "ArtMenu")[1]
	local labels = {}
	for _, row in ipairs(menu:GetChildren()) do
		if string.sub(row.Name, 1, 3) == "Row" then
			labels[#labels + 1] = row:FindFirstChildOfClass("TextLabel").Text
		end
	end
	T.same(labels, { "Try again", "Change", "Remove" })
	local token = logo(h).token
	logo(h).picture.IsLoaded = false
	tap(menu:FindFirstChild("Row1"))
	T.eq(logo(h).token, token + 1, "Try again asks the spot to look again")
	T.eq(logo(h).state, "loading", "and it waits again")
end

T.section("scriptart view: a picture file that went missing")
do
	local h = setup()
	local bytes = W.fixture("png_rgb_3x2")
	h.world.put("pics/me.png", bytes)
	local r = Art.resolveNow({ src = "file", value = "pics/me.png" }, { host = {} })
	Art.set("Scripts/A.lua", "logo", r)
	h.world.files[r.cached] = nil
	local h2 = setup()
	h2.world.put("pics/me.png", bytes)
	h2.world.put(Art.DATA_FILE, h.world.files[Art.DATA_FILE])
	Art.init(h2.ctx)
	h2.view.show(entry("Scripts/A.lua"))
	task.wait(0.5)
	local l = logo(h2)
	T.ok(l.state == "loading" or l.state == "set", "the copy was made again and shown: " .. tostring(l.state))
	T.eq(l.picture.Image, "rbxasset://" .. r.cached)
	local h3 = setup()
	h3.world.put(Art.DATA_FILE, h.world.files[Art.DATA_FILE])
	Art.init(h3.ctx)
	h3.view.show(entry("Scripts/A.lua"))
	task.wait(0.5)
	local l3 = logo(h3)
	T.eq(l3.state, "broken", "with the original gone too, it says so")
	T.eq(Art.brokenReason("Scripts/A.lua", "logo"), "There is no file called pics/me.png in your workspace folder")
	local requestsBefore = #h3.world.reads
	h3.view.show(entry("Scripts/A.lua"))
	T.eq(logo(h3).state, "broken", "showing it again does not start another restore")
	T.eq(#h3.world.reads, requestsBefore, "no more reading was done")
	tap(logo(h3).btn)
	local notes = #h3.env.notes
	T.ok(notes >= 1, "the reason is told when the menu opens")
	T.ok(string.find(h3.env.notes[notes], "There is no file called", 1, true) ~= nil)
end

T.section("scriptart view: restoring is shown while it happens")
do
	local h = setup()
	local url = "https://cdn.example.com/a.png"
	h.world.route("GET", url, { code = 200, body = W.fixture("png_rgb_3x2"), delay = 2 })
	local cached = "AtsukoHub/cache/art/1111111111111111.png"
	h.world.put(cached, "x")
	Art.set("Scripts/A.lua", "banner", { ok = true, src = "url", value = url, cached = cached, format = "png", ext = "png" })
	h.world.files[cached] = nil
	h.view.show(entry("Scripts/A.lua"))
	local b = banner(h)
	T.eq(b.state, "restoring")
	T.eq(b.label.Text, "Restoring...")
	T.eq(b.icon.IconName, "rotate-ccw")
	task.wait(3)
	T.ok(b.state == "loading" or b.state == "set", "the picture appears when it is back: " .. b.state)
	T.eq(b.picture.Image, "rbxasset://" .. Art.get("Scripts/A.lua", "banner").cached)
end

T.section("scriptart view: the script's own icon is the starting logo")
do
	local h = setup()
	h.view.show(entry("Scripts/A.lua"))
	h.view.setIcon("12345")
	local l = logo(h)
	T.eq(l.picture.Image, "rbxassetid://12345")
	T.eq(l.state, "loading")
	T.eq(l.isDefault, true)
	loaded(l)
	tap(l.btn)
	local overlay = h.parts.overlay
	local menu = kids(overlay, "ArtMenu")[1]
	local labels = {}
	for _, row in ipairs(menu:GetChildren()) do
		if string.sub(row.Name, 1, 3) == "Row" then
			labels[#labels + 1] = row:FindFirstChildOfClass("TextLabel").Text
		end
	end
	T.same(labels, { "Change" }, "the script's own icon can be changed but not removed")
	tap(kids(overlay, "ArtMenuCatcher")[1])
	Art.set("Scripts/A.lua", "logo", assetResult(77))
	T.eq(l.picture.Image, "rbxassetid://77", "your own logo wins")
	T.eq(l.isDefault, false)
	Art.clear("Scripts/A.lua", "logo")
	T.eq(l.picture.Image, "rbxassetid://12345", "and the script's icon returns when you remove yours")
	T.eq(l.isDefault, true)
	h.view.setIcon(nil)
	T.eq(l.state, "empty", "no icon, no default")
	h.view.setIcon("https://cdn.example.com/x.png")
	T.eq(l.state, "empty", "a web link in the header is not used as an icon")
	h.view.setIcon("rbxassetid://5")
	T.eq(l.picture.Image, "rbxassetid://5")
	h.view.show(entry("Scripts/B.lua"))
	T.eq(l.state, "empty", "the icon belongs to the script it came from")
	T.eq(banner(h).state, "empty", "icons never fill the banner")
end

T.section("scriptart view: other scripts and closing")
do
	local h = setup()
	h.view.show(entry("Scripts/A.lua"))
	local before = logo(h).token
	Art.set("Scripts/Other.lua", "logo", assetResult(5))
	T.eq(logo(h).token, before, "another script's change is ignored")
	T.eq(h.Bus.count("scriptart"), 1)
	Art.set("Scripts/A.lua", "logo", assetResult(5))
	tap(logo(h).btn)
	T.eq(#kids(h.parts.overlay, "ArtMenu"), 1)
	h.view.close()
	T.eq(#kids(h.parts.overlay, "ArtMenu"), 0)
	tap(logo(h).btn)
	Art.set("Scripts/A.lua", "banner", assetResult(6))
	T.eq(#kids(h.parts.overlay, "ArtMenu"), 0, "a change closes an open menu")
	tap(logo(h).btn)
	h.view.show(entry("Scripts/B.lua"))
	T.eq(#kids(h.parts.overlay, "ArtMenu"), 0, "switching script closes it too")
	h.view.destroy()
	T.eq(h.Bus.count("scriptart"), 0, "closing the view stops listening")
	T.eq(#kids(h.parts.cover, "BannerSpot"), 0, "and removes the spots")
	T.eq(#kids(h.parts.cover, "LogoSpot"), 0)
	h.view.destroy()
	Art.set("Scripts/B.lua", "logo", assetResult(8))
	task.wait(10)
	T.eq(#h.world.toasts, 0)
end

T.section("scriptart view: the module cleans up after itself")
do
	local h = setup()
	h.view.show(entry("Scripts/A.lua"))
	Art.destroy()
	T.eq(h.Bus.count("scriptart"), 0, "the view stopped listening")
	T.eq(#kids(h.parts.cover, "LogoSpot"), 0)
	T.eq(Art.count(), 0)
	task.wait(10)
end

T.section("scriptart view: no animation setting")
do
	local h = setup({ animations = false })
	h.view.show(entry("Scripts/A.lua"))
	Art.set("Scripts/A.lua", "logo", assetResult(5))
	loaded(logo(h))
	T.eq(logo(h).picture.ImageTransparency, 0, "with animations off it simply appears")
end
