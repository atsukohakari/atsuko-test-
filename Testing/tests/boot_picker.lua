local Runner = loadmodule("Testing/mocks/boot_runner.lua")
local boot, logHas = Runner.boot, Runner.logHas

local function findAll(root, pred)
	local out = {}
	for _, o in ipairs(root:GetDescendants()) do
		if pred(o) then
			out[#out + 1] = o
		end
	end
	return out
end

local function byText(root, text)
	return findAll(root, function(o)
		return (o.ClassName == "TextLabel" or o.ClassName == "TextButton") and o.Text == text
	end)
end

local function box(root, placeholder)
	return findAll(root, function(o)
		return o.ClassName == "TextBox" and o.PlaceholderText == placeholder
	end)[1]
end

local function press(o)
	local node = o
	for _ = 1, 6 do
		if node and node.ClassName == "TextButton" or node and node.ClassName == "ImageButton" then
			node.Activated:Fire()
			return true
		end
		node = node and node.Parent
	end
	return false
end

local function okBoot(label, env)
	T.ok(env.mainOk, label .. ": the main chunk finished: " .. tostring(env.mainErr))
	T.eq(#env.errors, 0, label .. ": no error lines in the log: " .. table.concat(env.errors, " | "))
end

T.section("picker: tapping the logo spot opens the picker, and it builds")
local env = boot({ seconds = 6 })
okBoot("picker", env)
local hub, core = env.hub, env.core
local Detail = hub.Detail
T.ok(Detail.art ~= nil, "the picture view is attached")
local entry = hub.Repo.entries[1]
Detail.open(entry)
env.run(1)
local logoSpot = Detail.art.spots.logo
T.ok(logoSpot and logoSpot.btn, "the logo spot exists")
logoSpot.btn.Activated:Fire()
env.run(1)
local Pick = core.loadModule("imagepicker")
T.ok(Pick ~= nil, "the picker module loaded: " .. tostring(core.mods.imagepicker and core.mods.imagepicker.err))
local session = Pick and Pick.sessionFor("logo")
T.ok(session ~= nil and session.alive, "a picker session is open for the logo")
T.eq(session and session.path, entry.path, "and it belongs to this script")
T.eq(session and session.has and session.has.files, true, "it knows this executor can save files")
local gui = hub.Gui
T.ok(#byText(gui, "Logo") >= 1, "the window is titled Logo")
local linkBox = box(gui, "https://... or an asset id")
T.ok(linkBox ~= nil, "the link box is there")
T.eq(#env.errors, 0, "no errors after opening: " .. table.concat(env.errors, " | "))
T.eq(#env.badProps, 0, "no bad property values: " .. table.concat(env.badProps, " | "))
T.ok(#byText(gui, "Link") >= 1 and #byText(gui, "Workspace") >= 1, "both tabs are there")

T.section("picker: a typed link is checked and says what it found")
if linkBox then
	linkBox.Text = "https://example.com/pic.webp"
	linkBox.FocusLost:Fire(true)
	env.run(3)
	T.eq(#env.errors, 0, "no errors after a link: " .. table.concat(env.errors, " | "))
	T.eq(#env.badProps, 0, "no bad property values after a link: " .. table.concat(env.badProps, " | "))
	T.eq(session.link, "https://example.com/pic.webp", "the picker keeps the typed link")
end

T.section("picker: the workspace tab and the folder browser")
local ws = byText(gui, "Workspace")[1]
if ws then
	press(ws)
	env.run(1)
	T.eq(session.tab, "file", "the workspace tab is selected")
end
local browse = byText(gui, "Browse")[1]
T.ok(browse ~= nil, "the Browse button is there (listfiles exists)")
if browse then
	press(browse)
	env.run(3)
	T.eq(#env.errors, 0, "no errors after Browse: " .. table.concat(env.errors, " | "))
	T.eq(#env.badProps, 0, "no bad property values after Browse: " .. table.concat(env.badProps, " | "))
	T.ok(#byText(gui, "Pick a picture") >= 1, "the browser window opened")
end

T.section("picker: a scrambled file name, found in the folder browser, selected and used")
do
	local Fix = loadmodule("Testing/mocks/image_fixtures.lua")
	local function bytes(hex)
		return (string.gsub(hex, "%x%x", function(h)
			return string.char(tonumber(h, 16))
		end))
	end
	local png = bytes(Fix.valid.png_wide_300x100.hex)
	env.files["Atsuko Hub/pics/kxjqzpw.png"] = png
	env.files["Atsuko Hub/pics/notes.txt"] = "hello"
	env.folders["Atsuko Hub/pics"] = true
	hub.Win.close("art_browser")
	env.run(1)
	T.ok(core.loadModule("imagebrowser").state() == nil, "the first browser is gone")
	local ws2 = byText(gui, "Workspace")[1]
	if ws2 then
		press(ws2)
		env.run(1)
	end
	local fileBox = box(gui, "pics/me.png")
	T.ok(fileBox ~= nil, "the workspace box is there")
	local Browser = core.loadModule("imagebrowser")
	core.scriptArt().setLastFolder("Atsuko Hub/pics")
	local browseButton = byText(gui, "Browse")[1]
	T.ok(browseButton ~= nil, "Browse is there")
	press(browseButton)
	env.run(2)
	local st = Browser.state()
	T.ok(st ~= nil and st.alive, "a browser is open")
	T.eq(st and st.dir, "Atsuko Hub/pics", "it opens in the folder you used last")
	local names = {}
	for _, e in ipairs(st and st.view or {}) do
		names[#names + 1] = tostring(e.name)
	end
	table.sort(names)
	T.eq(table.concat(names, ","), "kxjqzpw.png", "it lists the picture and hides the text file")
	local cell = nil
	for i, e in ipairs(st and st.view or {}) do
		if e.name == "kxjqzpw.png" then
			cell = st.cells[i]
		end
	end
	if not cell then
		hub.Win.close("art_browser")
		env.run(1)
		fileBox.Text = "Atsuko Hub/pics/kxjqzpw.png"
		fileBox.FocusLost:Fire(true)
		env.run(1)
	else
		cell.btn.Activated:Fire()
		env.run(2)
		T.ok(st.paneOpen == true, "the preview pane slid in")
		T.ok(#byText(gui, "kxjqzpw.png") >= 1, "the pane shows the file name exactly as it is")
		local selectButton = byText(gui, "Select")[1]
		T.ok(selectButton ~= nil, "Select is there")
		if selectButton then
			press(selectButton)
			env.run(3)
		end
	end
	T.ok(Browser.state() == nil, "the browser closed itself")
	T.eq(session.file, "Atsuko Hub/pics/kxjqzpw.png", "the picker took the path")
	T.eq(#env.errors, 0, "no errors while picking: " .. table.concat(env.errors, " | "))
	T.eq(#env.badProps, 0, "no bad property values while picking: " .. table.concat(env.badProps, " | "))
	env.run(5)
	T.eq(session.usable, true, "the picture checked out")
	local use = byText(gui, "Use this")[1]
	T.ok(use ~= nil, "Use this is there")
	if use and session.usable then
		press(use)
		env.run(3)
		local item = core.scriptArt().get(entry.path, "logo")
		T.ok(item ~= nil, "the logo is stored for this script")
		T.eq(item and item.src, "file", "as a file")
		local cached = false
		for path in pairs(env.files) do
			if string.sub(path, 1, #"Atsuko Hub/cache/art/") == "Atsuko Hub/cache/art/" and string.sub(path, -4) == ".png" then
				cached = true
			end
		end
		T.ok(cached, "a copy with the right ending is kept in the cache")
		local other = hub.Repo.entries[2]
		T.ok(other == nil or core.scriptArt().get(other.path, "logo") == nil, "it does not leak to another script")
	end
	T.eq(#env.errors, 0, "no errors at the end: " .. table.concat(env.errors, " | "))
end

T.section("picker: closing everything leaves nothing behind")
Pick.destroy()
env.run(1)
T.eq(#env.errors, 0, "no errors after closing: " .. table.concat(env.errors, " | "))
