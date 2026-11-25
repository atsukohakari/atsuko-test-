local Runner = loadmodule("Testing/mocks/boot_runner.lua")

local function all(root, pred)
	local out = {}
	for _, d in ipairs(root:GetDescendants()) do
		if pred(d) then
			out[#out + 1] = d
		end
	end
	return out
end

local function texts(root, text)
	return all(root, function(d)
		return (d:IsA("TextLabel") or d:IsA("TextButton")) and d.Text == text
	end)
end

local function rowOf(label)
	local node = label
	while node and not node:IsA("TextButton") do
		node = node.Parent
	end
	return node
end

local function errorsOf(env)
	local out = {}
	for _, item in ipairs(env.hub.Log.items or {}) do
		if item.kind == "error" then
			out[#out + 1] = tostring(item.src) .. ": " .. tostring(item.msg)
		end
	end
	return out
end

local env = Runner.boot({ seconds = 8 })
local hub = env.hub
local page = hub.Pages.scripts
local S = hub.S

T.section("scripts_setup: Main Scripts has a Setup tab")
T.eq(#page.tabs, 5, "five tabs")
T.eq(page.tabs[5], "Setup", "the last one is Setup")
T.eq(page.tabs[1], "Hat", "Hat stays first")
T.eq(#env.core.VIEW_TABS, 4, "the script lists are still the four tabs")
T.eq(#page.views, 5, "five views")
T.eq(page.views[5].Name, "Setup", "the fifth is the Setup view")
T.eq(page.views[5].Position.Y.Offset, 0, "it starts at the top, there is no search box above it")

T.section("scripts_setup: opening the Setup tab")
do
	hub.Panel.show("scripts")
	env.run(1)
	hub.Panel.setTab(page, 5)
	env.run(2)
	local v = page.views[5]
	T.eq(v.Visible, true, "the Setup view shows")
	T.eq(v.Position.Y.Offset, 0, "at the top")
	T.eq(page.views[1].Visible, false, "the Hat list is hidden")
	T.eq(hub.Scripts.searchBar.Visible, false, "the search box hides on Setup")
	for _, title in ipairs({ "REANIMATION", "RUN & STOP", "RIGHT NOW", "Respawn when stopped", "One script at a time", "Smart Stop", "Show script prints in Console", "Look for new scripts by itself", "Stop all scripts", "Respawn my character", "Clear the recent list", "Hat tab" }) do
		T.eq(#texts(v, title), 1, "Setup has " .. title)
	end
	T.ok(v:FindFirstChild("Hats") ~= nil, "Hats & alignment moved here too")
	T.eq(#errorsOf(env), 0, "no errors: " .. table.concat(errorsOf(env), " | "))
end

T.section("scripts_setup: the settings work from here")
do
	local v = page.views[5]
	local before = S.oneAtATime
	local row = rowOf(texts(v, "One script at a time")[1])
	T.ok(row ~= nil, "the toggle row")
	row.Activated:Fire()
	env.run(0.2)
	T.eq(S.oneAtATime, not before, "tapping it flips the setting")
	row.Activated:Fire()
	env.run(0.2)
	T.eq(S.oneAtATime, before, "and back")
	local smart = rowOf(texts(v, "Smart Stop")[1])
	local was = S.smartStop
	smart.Activated:Fire()
	env.run(0.2)
	T.eq(S.smartStop, not was, "Smart Stop flips")
	smart.Activated:Fire()
	env.run(0.2)
	S.recent = { "Scripts/Hat/x.lua" }
	rowOf(texts(v, "Clear the recent list")[1]).Activated:Fire()
	env.run(0.5)
	local confirm = texts(v, "Tap again to confirm")[1]
	if confirm then
		rowOf(confirm).Activated:Fire()
		env.run(0.5)
	end
	T.eq(#S.recent, 0, "Clear the recent list empties it")
end

T.section("scripts_setup: built once, and the tab buttons")
do
	hub.Panel.setTab(page, 1)
	env.run(1)
	T.eq(hub.Scripts.searchBar.Visible, true, "the search box is back on Hat")
	T.eq(page.views[1].Position.Y.Offset, 40, "the list sits under it")
	hub.Panel.setTab(page, 5)
	env.run(1)
	hub.Panel.setTab(page, 3)
	env.run(1)
	hub.Panel.setTab(page, 5)
	env.run(1)
	T.eq(#texts(page.views[5], "Respawn when stopped"), 1, "opening Setup again does not build it twice")
	T.eq(#all(page.views[5], function(d) return d.Name == "Hats" end), 1, "nor the hat list")
	T.eq(#texts(page.views[5], "Limb tab"), 0, "no Limb tab button while the tab is off")
	hub.Panel.setTab(page, 2)
	env.run(1)
	T.eq(page.tab, 5, "the Limb tab doesn't open")
	T.ok(#texts(hub.Gui, "Currently disabled for now, trying to add new methods..") >= 1, "it says why instead")
	hub.Panel.setTab(page, 5)
	env.run(1)
	rowOf(texts(page.views[5], "Hat tab")[1]).Activated:Fire()
	env.run(1)
	T.eq(page.tab, 1, "Hat tab jumps to the Hat list")
end

T.section("scripts_setup: Settings no longer has them")
do
	hub.Panel.show("settings")
	env.run(1)
	local settings = hub.Pages.settings
	T.eq(#settings.tabs, 5, "Settings has five tabs, the designs are gone")
	T.same(settings.tabs, { "General", "Themes", "AI", "Commands", "About" }, "General, Themes, AI, Commands, About")
	for i = 1, #settings.tabs do
		hub.Panel.setTab(settings, i)
		env.run(1)
	end
	for i, v in ipairs(settings.views) do
		T.eq(#texts(v, "Respawn when stopped"), 0, "tab " .. i .. " has no script settings")
		T.eq(#texts(v, "RUN & STOP"), 0, "tab " .. i .. " has no Run & Stop")
		T.eq(v:FindFirstChild("Hats"), nil, "tab " .. i .. " has no hat list")
	end
	T.eq(#texts(settings.views[4], "CHAT AND KEYBOARD"), 1, "Commands is the fourth tab")
	T.eq(#texts(settings.views[5], "ATSUKO HUB"), 1, "About is the fifth")
	T.eq(#errorsOf(env), 0, "no errors at the end: " .. table.concat(errorsOf(env), " | "))
	T.eq(#(env.badProps or {}), 0, "no bad GUI values: " .. table.concat(env.badProps or {}, " | "))
end
