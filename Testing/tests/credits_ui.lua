local Runner = loadmodule("Testing/mocks/boot_runner.lua")
local Mod = loadmodule("Hub/modules/credits_ui.lua")

local SENTENCE = "Just a tester lol, he's a cool guy :3"
local ATSUKO = "he's a weird guy ngl, plus he's soooo lazy like very lazyy..... and he's a femboy so.. yeah :3"
local TESTER_ID = 11345577877
local TORY_ID = 4242
local PICTURE = "Atsuko Hub/Hub/credits/atsuko.png"
local BADGE = "Atsuko Hub/Hub/credits/verified.png"
local PNG = "\137PNG\r\n\26\n" .. string.rep("x", 80)
local TOTAL = 55

local USERS = {
	[TESTER_ID] = { name = "testerlogin", display = "Test Nick" },
	[TORY_ID] = { name = "YeImTory", display = "Tory Display" },
}

local function uis()
	return game:GetService("UserInputService")
end

local function all(root, pred)
	local out = {}
	for _, d in ipairs(root:GetDescendants()) do
		if pred(d) then
			out[#out + 1] = d
		end
	end
	return out
end

local function named(root, name)
	return all(root, function(d)
		return d.Name == name
	end)
end

local function first(root, name)
	return named(root, name)[1]
end

local function withText(root, text)
	return all(root, function(d)
		return (d:IsA("TextLabel") or d:IsA("TextButton") or d:IsA("TextBox")) and d.Text == text
	end)[1]
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

local function openAbout(env)
	env.hub.Panel.show("settings")
	env.run(1)
	env.hub.Panel.setTab(env.hub.Pages.settings, 5)
	env.run(3)
	return env.core.creditsBlock
end

local function dim(env)
	return env.hub.Root:FindFirstChild("CreditsDim")
end

local function win(env)
	local d = dim(env)
	return d and d:FindFirstChild("CreditsWindow") or nil
end

local function body(env)
	local w = win(env)
	return w and first(w, "Body") or nil
end

local function cards(env)
	local b = body(env)
	return b and named(b, "Card") or {}
end

local function featured(env)
	local b = body(env)
	return b and named(b, "Featured") or {}
end

local function cardFor(list, who)
	for _, c in ipairs(list) do
		local label = first(c, "Who")
		if label and label.Text == who then
			return c
		end
	end
	return nil
end

local function detail(env)
	local w = win(env)
	return w and w:FindFirstChild("Detail") or nil
end

local function tap(btn)
	btn.Activated:Fire()
end

local function chip(env, title)
	local w = win(env)
	for _, c in ipairs(named(w, "Chip")) do
		local label = first(c, "Label")
		if label and string.sub(label.Text, 1, #title + 2) == title .. "  " then
			return c
		end
	end
	return nil
end

local function boot(extra)
	extra = extra or {}
	local files = { [PICTURE] = PNG, [BADGE] = PNG }
	for k, v in pairs(extra.files or {}) do
		files[k] = v
	end
	return Runner.boot({
		seconds = 8,
		viewW = extra.viewW,
		viewH = extra.viewH,
		touch = extra.touch,
		files = files,
		before = function(e)
			e.rbxUsers = USERS
			e.rbxOffline = extra.offline
		end,
	})
end

local env = boot()
local hub = env.hub

T.section("credits_ui: About shows one Credits button")
local block = openAbout(env)
T.ok(block ~= nil and block.alive, "the credits block exists after opening About")
T.eq(#errorsOf(env), 0, "no hub errors: " .. table.concat(errorsOf(env), " | "))
T.ok(block.button ~= nil and block.button.Name == "CreditsCard", "the button")
T.ok(withText(block.button, "Credits") ~= nil, "it says Credits")
T.ok(withText(block.button, TOTAL .. " people and projects  ·  tap to meet them") ~= nil, "and how many people are in it")
T.eq(#named(first(block.button, "Faces"), "Avatar"), 3, "three faces on the button")
T.eq(#named(block.frame, "Card"), 0, "no list on the About page any more")
T.eq(dim(env), nil, "nothing is open yet")
T.eq(#hub.Pages.settings.tabs, 5, "Settings has five tabs")
T.eq(hub.Pages.settings.tabs[5], "About", "About is the fifth")
for _, name in ipairs(hub.Pages.settings.tabs) do
	T.ok(name ~= "Scripts", "no Scripts tab in Settings: " .. name)
end

T.section("credits_ui: the window opens big and centred")
do
	tap(block.button)
	env.run(0.05)
	T.ok(dim(env) ~= nil, "the screen dims")
	T.ok(win(env) ~= nil, "the window opens")
	env.run(1.5)
	local w = win(env)
	local x, y, ww, hh, mode = Mod.windowRect(hub.L.W, hub.L.H)
	T.eq(mode, "window", "a window on a computer screen")
	T.eq(w.Size.X.Offset, ww, "its width")
	T.eq(w.Size.Y.Offset, hh, "its height")
	T.eq(w.Position.X.Offset, x, "centred sideways")
	T.eq(w.Position.Y.Offset, y, "and up and down")
	T.ok(ww >= 700, "it is wide on a wide screen: " .. ww)
	T.eq(first(w, "Grip").Visible, false, "no grip on a computer")
	T.ok(withText(w, "Credits") ~= nil, "the title")
	T.ok(withText(w, "The people and projects behind Atsuko Hub") ~= nil, "the subtitle")
	T.eq(first(w, "Stats").Text, TOTAL .. " credited  ·  7 groups  ·  4 verified", "the numbers")
	T.eq(#named(w, "Chip"), 8, "All and seven groups as chips")
	T.ok(chip(env, "All") ~= nil, "the All chip")
	T.eq(chip(env, "All"):GetAttribute("Selected"), true, "All is picked")
	T.eq(#cards(env), TOTAL, "a card for everyone")
	T.eq(#featured(env), 4, "four in the spotlight, Blue Archive too")
	T.eq(cardFor(cards(env), "Roblox"), nil, "Roblox is not credited")
	local grid = first(first(body(env), "Group"), "UIGridLayout")
	local inner = ww - 32 - 4
	T.eq(grid.CellSize.X.Offset, Mod.cellWidth(inner, Mod.columns(inner), Mod.GAP), "three columns of cards")
	T.eq(Mod.columns(inner), 3, "three on this screen")
	T.eq(#errorsOf(env), 0, "still no errors")
	T.eq(#(env.badProps or {}), 0, "no bad GUI values: " .. table.concat(env.badProps or {}, " | "))
end

T.section("credits_ui: the spotlight, badges and pictures")
do
	local spot = featured(env)
	local atsuko = cardFor(spot, "Atsuko")
	local claude = cardFor(spot, "Claude")
	local tester = cardFor(spot, "Test Nick")
	T.ok(atsuko ~= nil, "Atsuko is in the spotlight")
	T.ok(claude ~= nil, "Claude is in the spotlight")
	T.ok(tester ~= nil, "the tester is in the spotlight with his Roblox nickname")
	for _, c in ipairs({ atsuko, claude, tester }) do
		local badge = c and first(first(c, "NameRow"), "Verified") or nil
		T.ok(badge ~= nil, "a badge after the name")
		local official = badge and first(badge, "Official") or nil
		T.ok(official ~= nil and official.Visible, "the badge is the official picture")
		T.eq(official and official.Image or "", "rbxasset://" .. BADGE, "from Hub/credits/verified.png")
		T.eq(badge and first(badge, "Seal").Visible, false, "the drawn one is hidden")
	end
	local photo = first(first(atsuko, "Avatar"), "Photo")
	T.eq(photo.Visible, true, "Atsuko's picture shows")
	T.eq(photo.Image, "rbxasset://" .. PICTURE, "the picture shipped in Hub/credits")
	T.eq(first(first(atsuko, "Avatar"), "Monogram").Visible, false, "the letter is hidden")
	T.eq(first(atsuko, "Handle").Text, "@AtsukoHakariBA", "his Roblox username")
	T.eq(first(first(atsuko, "HandleRow"), "Verified"), nil, "no badge after the @username, only after the nickname")
	T.eq(first(tester, "Handle").Text, "@testerlogin", "the tester's username")
	T.eq(first(first(tester, "HandleRow"), "Verified"), nil, "and no badge after it")
	T.eq(first(claude, "HandleRow").Visible, false, "Claude has no handle line")
	T.ok(withText(atsuko, ATSUKO) ~= nil, "Atsuko's own words on his card")
	T.ok(withText(tester, SENTENCE) ~= nil, "the tester's sentence on his card")
	local tory = cardFor(cards(env), "Tory")
	T.ok(tory ~= nil, "Tory has a card")
	T.eq(first(tory, "Verified"), nil, "no badge for someone not verified")
	T.eq(first(first(tory, "Avatar"), "Photo").Visible, true, "Tory's Roblox picture, found from his username")
	local dub = cardFor(cards(env), "Dubmood")
	T.eq(first(first(dub, "Avatar"), "Photo").Visible, false, "no picture for someone without one")
	T.eq(first(first(dub, "Avatar"), "Monogram").Text, "D", "a letter instead")
	T.ok(first(dub, "Blurb").Text ~= "", "every card has a few words")
	local seen = {}
	for _, call in ipairs(env.thumbCalls or {}) do
		seen[call.userId] = true
	end
	T.eq(seen[TESTER_ID], true, "the tester's picture was asked for")
	local cache = env.files["AtsukoHub/data/credits_cache.json"]
	T.ok(type(cache) == "string", "names are cached")
	local saved = jsondecode(cache or "{}")
	T.eq(saved.names[tostring(TESTER_ID)].display, "Test Nick", "the cached nickname")
end

T.section("credits_ui: a card opens the person's page")
do
	tap(cardFor(cards(env), "Tory"))
	env.run(1)
	local d = detail(env)
	T.ok(d ~= nil, "Tory's page")
	T.eq(first(d, "Name").Text, "Tory", "his name")
	T.eq(first(d, "Username").Text, "@YeImTory", "his Roblox name")
	T.eq(first(d, "HandleRow").Visible, true, "shown")
	T.ok(withText(d, "PERSON") ~= nil, "what he is")
	T.ok(withText(d, "Neptunian V remake author") ~= nil, "his role")
	T.ok(withText(d, "DESCRIPTION") ~= nil, "a Description heading")
	T.ok(withText(first(d, "Description"), "Made the Neptunian V remake ours is built on and hosts its music, and made the Exotic Ban Hammer.") ~= nil, "his description")
	T.eq(withText(d, "WHAT THEY DID"), nil, "no What they did any more")
	T.eq(withText(d, "WHY THEY ARE HERE"), nil, "and no Why they are here")
	T.eq(first(d, "Did"), nil)
	T.eq(first(d, "Why"), nil)
	T.ok(withText(d, "USED IN") ~= nil, "where his work is used")
	T.ok(withText(d, "LINKS") ~= nil, "his links")
	local copies = named(d, "Copy")
	T.eq(#copies, 3, "three links, three copy buttons")
	T.eq(#named(d, "Open"), 3, "three open buttons")
	tap(copies[2])
	env.run(0.05)
	T.eq(env.clipboard, "https://discord.gg/kMuXv6PuXp", "the discord invite is copied")
	T.ok(withText(copies[2], "Copied") ~= nil, "it says Copied")
	env.run(1.6)
	T.ok(withText(copies[2], "Copy") ~= nil, "then Copy again")
	tap(named(d, "Open")[3])
	env.run(0.05)
	T.eq(env.opened[#env.opened], "https://youtube.com/@jskfhggjxu", "Open sends his channel to the browser")
	env.run(1.6)
	for _ = 1, 5 do
		tap(cardFor(cards(env), "Dubmood"))
	end
	env.run(0.1)
	T.eq(#named(win(env), "Detail"), 1, "taps under an open page do nothing")
	tap(first(d, "Back"))
	env.run(1)
	T.eq(detail(env), nil, "Back goes back to everyone")
	T.ok(win(env) ~= nil, "and the window stays")
end

T.section("credits_ui: the tester's page")
do
	tap(cardFor(featured(env), "Test Nick"))
	env.run(1)
	local d = detail(env)
	T.ok(d ~= nil, "it opens from the spotlight")
	T.eq(first(d, "Nickname").Text, "Test Nick", "his nickname")
	T.eq(first(d, "Nickname").TextSize, 22, "big")
	T.ok(first(first(d, "NameRow"), "Verified") ~= nil, "a badge after his nickname")
	T.eq(first(d, "Username").Text, "@testerlogin", "his username")
	T.eq(first(first(d, "HandleRow"), "Verified"), nil, "but not after his username")
	T.ok(withText(first(d, "Description"), SENTENCE) ~= nil, "the owner's sentence")
	T.eq(#named(d, "Copy"), 0, "no copy buttons")
	local open = first(first(d, "Profile"), "Open")
	T.ok(open ~= nil, "an Open Roblox profile button")
	T.eq(open.Size.Y.Offset, 46, "a big one")
	T.ok(withText(open, "Open Roblox profile") ~= nil, "it says what it does")
	local before = #(env.opened or {})
	tap(open)
	env.run(0.05)
	T.eq(env.opened[#env.opened], "https://www.roblox.com/users/" .. TESTER_ID .. "/profile", "his profile")
	for _ = 1, 9 do
		tap(open)
	end
	env.run(0.05)
	T.eq(#env.opened, before + 1, "quick taps open it once")
	env.run(1.6)
	env.noBrowser = true
	tap(open)
	env.run(0.05)
	T.eq(env.clipboard, "https://www.roblox.com/users/" .. TESTER_ID .. "/profile", "no browser: the address is copied")
	env.noBrowser = nil
	env.run(1.6)
	uis().InputBegan:Fire({ UserInputType = Enum.UserInputType.Keyboard, KeyCode = Enum.KeyCode.Escape })
	env.run(1)
	T.eq(detail(env), nil, "Escape leaves his page first")
	T.ok(win(env) ~= nil, "but not the window")
end

T.section("credits_ui: Atsuko's and Claude's pages")
do
	tap(cardFor(featured(env), "Atsuko"))
	env.run(1)
	local d = detail(env)
	T.ok(withText(first(d, "Description"), ATSUKO) ~= nil, "Atsuko's description, as he wrote it")
	T.eq(first(first(d, "Avatar"), "Photo").Image, "rbxasset://" .. PICTURE, "his picture, big")
	T.ok(first(first(d, "NameRow"), "Verified") ~= nil, "his badge")
	T.eq(first(d, "Username").Text, "@AtsukoHakariBA", "his Roblox username")
	T.ok(withText(d, "Hub author") ~= nil, "his role")
	tap(first(d, "Back"))
	env.run(1)
	tap(cardFor(featured(env), "Claude"))
	env.run(1)
	local c = detail(env)
	T.eq(first(c, "Name").Text, "Claude", "Claude's page")
	T.ok(first(first(c, "NameRow"), "Verified") ~= nil, "with a badge")
	T.eq(#named(c, "Copy"), 2, "two links")
	T.ok(withText(c, "AI ASSISTANT") ~= nil, "what it is")
	T.ok(withText(c, "Bug fixes") ~= nil, "its formal role")
	T.ok(withText(first(c, "Description"), "AI by Anthropic. Helped write, fix and test the hub with Atsuko.") ~= nil, "its description")
	tap(first(c, "Back"))
	env.run(1)
end

T.section("credits_ui: search and the group chips")
do
	local w = win(env)
	local box = first(w, "Box")
	box.Text = "tory"
	env.run(0.5)
	T.eq(#cards(env), 1, "searching tory leaves one card")
	T.eq(#featured(env), 0, "and hides the spotlight")
	T.ok(cardFor(cards(env), "Tory") ~= nil, "it is Tory")
	box.Text = "zzzzzz"
	env.run(0.5)
	T.eq(#cards(env), 0, "nothing matches")
	T.ok(withText(body(env), "Nobody matches that.") ~= nil, "and it says so")
	box.Text = "verified"
	env.run(0.5)
	T.eq(#cards(env), 4, "verified finds the four badges")
	box.Text = "  Dubstep "
	env.run(0.5)
	T.ok(#cards(env) >= 2, "a script name finds the people around it")
	for i = 1, 8 do
		box.Text = string.sub("claude anthropic", 1, i)
	end
	env.run(0.5)
	T.ok(#cards(env) >= 1, "typing fast ends on the last word")
	box.Text = ""
	env.run(0.5)
	T.eq(#cards(env), TOTAL, "everyone again")
	T.eq(#featured(env), 4, "and the spotlight")
	tap(chip(env, "Testers"))
	env.run(0.5)
	T.eq(#cards(env), 1, "the Testers chip shows one card")
	T.eq(#featured(env), 0, "no spotlight in a group")
	T.eq(chip(env, "Testers"):GetAttribute("Selected"), true, "the chip is picked")
	T.eq(chip(env, "All"):GetAttribute("Selected"), false, "All is not")
	tap(chip(env, "Reanimation"))
	env.run(0.5)
	T.eq(#cards(env), 11, "the reanimation people")
	box.Text = "music"
	env.run(0.5)
	T.ok(#cards(env) >= 3 and #cards(env) < 11, "search inside a group")
	box.Text = ""
	tap(chip(env, "All"))
	env.run(0.5)
	T.eq(#cards(env), TOTAL, "All brings everyone back")
end

T.section("credits_ui: copy all and closing")
do
	tap(first(win(env), "CopyAll"))
	env.run(0.1)
	local lines = 0
	for _ in string.gmatch(env.clipboard or "", "[^\n]+") do
		lines += 1
	end
	T.eq(lines, TOTAL, "one line per person")
	T.ok(string.find(env.clipboard, SENTENCE, 1, true) ~= nil, "with the tester's sentence")
	uis().InputBegan:Fire({ UserInputType = Enum.UserInputType.Keyboard, KeyCode = Enum.KeyCode.Escape })
	env.run(0.1)
	T.ok(dim(env) ~= nil, "still there while it goes")
	env.run(1)
	T.eq(dim(env), nil, "Escape closes the window")
	tap(block.button)
	env.run(1.5)
	tap(dim(env))
	env.run(1)
	T.eq(dim(env), nil, "tapping outside closes it")
	tap(block.button)
	env.run(1.5)
	tap(first(first(win(env), "Hero"), "Close"))
	env.run(1)
	T.eq(dim(env), nil, "the close button closes it")
	for _ = 1, 10 do
		tap(block.button)
	end
	env.run(0.02)
	T.eq(#named(hub.Root, "CreditsDim"), 1, "ten quick taps open one window")
	env.run(1.5)
	for _ = 1, 10 do
		tap(dim(env))
	end
	env.run(0.02)
	for _ = 1, 10 do
		tap(block.button)
	end
	env.run(1.5)
	T.eq(#named(hub.Root, "CreditsWindow"), 0, "taps while it closes are ignored")
	for _ = 1, 10 do
		tap(block.button)
		env.run(0.02)
		if dim(env) then
			tap(dim(env))
		end
		env.run(0.02)
	end
	env.run(2)
	T.ok(#named(hub.Root, "CreditsWindow") <= 1, "never two windows")
	for _ = 1, 3 do
		if dim(env) then
			tap(dim(env))
			env.run(1)
		end
	end
	T.eq(dim(env), nil, "and it ends closed")
	local d2 = block.open("tory")
	env.run(1.5)
	T.ok(d2 ~= nil and detail(env) ~= nil, "open by id lands on that person")
	T.eq(first(detail(env), "Name").Text, "Tory", "Tory")
	T.eq(#errorsOf(env), 0, "no errors in the log")
end

T.section("credits_ui: it follows the screen size")
do
	local w = win(env)
	hub.L.W, hub.L.H = 520, 900
	block.relayout()
	env.run(0.1)
	local x, y, ww, hh, mode = Mod.windowRect(520, 900)
	T.eq(mode, "sheet", "a phone sized screen gets a sheet")
	T.eq(w.Size.X.Offset, ww, "almost the whole width")
	T.eq(w.Position.X.Offset, x, "with a small margin")
	T.eq(first(w, "Grip").Visible, true, "and a grip")
	hub.L.W, hub.L.H = 1280, 720
	block.relayout()
	env.run(0.1)
	local _, _, w2 = Mod.windowRect(1280, 720)
	T.eq(w.Size.X.Offset, w2, "the window width again")
	tap(dim(env))
	env.run(1)
	T.eq(dim(env), nil, "closed")
end

T.section("credits_ui: destroying the page with the window open")
do
	tap(block.button)
	env.run(1.5)
	T.ok(dim(env) ~= nil, "open")
	block.destroy()
	T.eq(dim(env), nil, "the window goes with it")
	T.eq(block.alive, false, "and the block is dead")
	T.eq(#errorsOf(env), 0, "still no errors")
end

T.section("credits_ui: on a phone")
do
	local e = boot({ viewW = 390, viewH = 844, touch = true })
	local b = openAbout(e)
	T.ok(b ~= nil and b.button ~= nil, "the button is there")
	tap(b.button)
	e.run(1.5)
	local w = win(e)
	local x, y, ww, hh, mode = Mod.windowRect(e.hub.L.W, e.hub.L.H)
	T.eq(mode, "sheet", "a sheet on a phone")
	T.eq(w.Size.X.Offset, ww, "full width minus a margin")
	T.eq(w.Position.Y.Offset, y, "slid up into place")
	T.eq(first(w, "Grip").Visible, true, "with a grip")
	local inner = ww - 32 - 4
	local grid = first(first(first(w, "Body"), "Group"), "UIGridLayout")
	T.eq(grid.CellSize.X.Offset, Mod.cellWidth(inner, Mod.columns(inner), Mod.GAP), "cards fit the narrow screen")
	T.ok(Mod.columns(inner) <= 2, "one or two columns")
	T.ok(first(first(w, "Hero"), "Close").Size.X.Offset >= 44, "a big enough close button")
	local startY = w.Position.Y.Offset
	local down = { UserInputType = Enum.UserInputType.Touch, Position = Vector3.new(100, w.AbsolutePosition.Y + 20, 0) }
	w.InputBegan:Fire(down)
	down.Position = Vector3.new(100, down.Position.Y + 30, 0)
	uis().InputChanged:Fire(down)
	e.run(0.05)
	T.ok(w.Position.Y.Offset > startY, "dragging the top down moves it")
	uis().InputEnded:Fire(down)
	e.run(0.6)
	T.ok(dim(e) ~= nil, "a short pull springs back")
	local y0 = win(e).AbsolutePosition.Y
	local down2 = { UserInputType = Enum.UserInputType.Touch, Position = Vector3.new(100, y0 + 20, 0) }
	win(e).InputBegan:Fire(down2)
	down2.Position = Vector3.new(100, y0 + 400, 0)
	uis().InputChanged:Fire(down2)
	e.run(0.05)
	uis().InputEnded:Fire(down2)
	e.run(1)
	T.eq(dim(e), nil, "a long swipe down closes it")
	T.eq(#errorsOf(e), 0, "no errors on a phone")
	T.eq(#(e.badProps or {}), 0, "no bad GUI values on a phone: " .. table.concat(e.badProps or {}, " | "))
end

T.section("credits_ui: a phone on its side gets a slim header and round corners")
do
	local e = boot({ viewW = 844, viewH = 390, touch = true })
	local b = openAbout(e)
	local glowCorner = first(first(b.button, "Glow"), "UICorner")
	T.ok(glowCorner ~= nil and glowCorner.CornerRadius.Offset == 18, "the glow on the About button follows its round corners")
	tap(b.button)
	e.run(1.5)
	local w = win(e)
	local _, _, ww, _, mode = Mod.windowRect(e.hub.L.W, e.hub.L.H)
	local hh = w.Size.Y.Offset
	T.eq(w.Size.X.Offset, ww)
	local look = Mod.chrome(mode, ww, hh)
	T.eq(look.compact, true, "this screen is short: " .. hh)
	local hero = first(w, "Hero")
	T.eq(hero.Size.Y.Offset, 60, "a slim header")
	T.eq(first(w, "Toolbar").Size.Y.Offset, 52, "and one line for the search and the chips")
	T.eq(first(w, "Toolbar").Position.Y.Offset, 60)
	T.eq(body(e).Position.Y.Offset, 112, "the cards start right under it")
	T.eq(body(e).Size.Y.Offset, -112)
	T.eq(first(hero, "Subtitle").Visible, false, "the subtitle makes room")
	T.eq(first(hero, "Stats").Visible, true, "the numbers stay")
	T.ok(first(hero, "Close").Size.X.Offset >= 40, "the close button is still easy to hit")
	local sw = Mod.searchWidth(ww)
	T.eq(first(w, "Search").Size.X.Offset, sw, "the search is a box on the left")
	T.eq(first(w, "Search").Size.X.Scale, 0)
	T.eq(first(w, "Chips").Position.X.Offset, 16 + sw + 8, "the chips sit next to it")
	T.eq(first(w, "Box").PlaceholderText, "Search", "with a short hint that fits")
	local heroGlow = first(hero, "Glow")
	local hc = first(heroGlow, "UICorner")
	T.ok(hc ~= nil and hc.CornerRadius.Offset == 24, "the header glow has the window's round corners")
	T.eq(heroGlow.Size.Y.Offset, 48, "and reaches past the header so only its top is round")
	local orb = first(hero, "Orb")
	T.ok(orb.Position.X.Scale == 1 and orb.Position.X.Offset + orb.Size.X.Offset / 2 <= -24, "the orb stays out of the top right corner")
	local cellW = first(first(body(e), "Spotlight"), "UIGridLayout").CellSize.X.Offset
	for _, c in ipairs(featured(e)) do
		local sc = first(first(c, "Shine"), "UICorner")
		T.ok(sc ~= nil and sc.CornerRadius.Offset == 18, "the spotlight shine is round like its card")
		local roles = first(c, "Roles")
		local used, shown = 0, 0
		for _, p in ipairs(named(roles, "Pill")) do
			if p.Visible then
				used += p.Size.X.Offset + (shown > 0 and 6 or 0)
				shown += 1
			end
		end
		local room = cellW - 100
		T.ok(shown == 1 or used <= room, "role chips are only shown when they fit: " .. used .. " in " .. room)
	end
	local claude = cardFor(featured(e), "Claude")
	local hidden = 0
	for _, p in ipairs(named(first(claude, "Roles"), "Pill")) do
		if not p.Visible then
			hidden += 1
		end
	end
	T.eq(hidden, 1, "Claude's second role does not fit here, so it is left out, not cut in half")
	b.open("atsuko")
	e.run(1.5)
	local d = detail(e)
	local dc = first(d, "UICorner")
	T.ok(dc ~= nil and dc.Parent == d and dc.CornerRadius.Offset == 24, "a person's page keeps the window's round corners")
	local band = first(d, "Band")
	local bg = first(band, "Glow")
	local bc = first(bg, "UICorner")
	T.ok(bc ~= nil and bc.CornerRadius.Offset == 20, "the banner glow is round like the banner")
	T.eq(bg.Size.Y.Offset, 40, "and only its top shows")
	tap(first(d, "Back"))
	e.run(1)
	e.hub.L.W, e.hub.L.H = 1536, 864
	b.relayout()
	e.run(0.1)
	local _, _, ww2, hh2, mode2 = Mod.windowRect(1536, 864)
	T.eq(Mod.chrome(mode2, ww2, hh2).compact, false)
	T.eq(hero.Size.Y.Offset, 112, "a big screen gets the big header back")
	T.eq(first(w, "Toolbar").Size.Y.Offset, 98)
	T.eq(body(e).Position.Y.Offset, 112 + 98)
	T.eq(first(hero, "Subtitle").Visible, true, "with the subtitle")
	T.eq(first(w, "Search").Size.X.Scale, 1, "and the search across the top")
	T.eq(first(w, "Chips").Position.X.Offset, 0)
	T.eq(first(w, "Box").PlaceholderText, "Search names, roles or scripts")
	T.eq(#named(first(claude, "Roles"), "Pill"), 2, "the roles are all still there")
	T.eq(#errorsOf(e), 0, "no errors: " .. table.concat(errorsOf(e), " | "))
	T.eq(#(e.badProps or {}), 0, "no bad GUI values: " .. table.concat(e.badProps or {}, " | "))
end

T.section("credits_ui: the data file is missing or broken")
do
	local e2 = boot({ files = { ["Atsuko Hub/Hub/credits.json"] = "not json at all, but longer than forty bytes to pass the size check" } })
	local b2 = openAbout(e2)
	T.ok(b2 ~= nil, "the page still builds")
	T.eq(b2.button, nil, "with no button")
	T.ok(withText(b2.frame, "The credits list didn't load. Reload the hub and look again.") ~= nil, "and a plain sentence")
	T.eq(b2.open("tory"), nil, "opening does nothing")
	local e3 = boot({ files = { ["Atsuko Hub/Hub/credits.json"] = false } })
	local b3 = openAbout(e3)
	T.ok(b3 == nil or b3.button == nil, "a missing file shows no button")
	T.eq(#errorsOf(e3) <= 1, true, "and at most one logged problem")
end

T.section("credits_ui: offline and without a picture")
do
	local e4 = boot({ offline = true, files = { [PICTURE] = "not a picture at all, just some text that is long enough" } })
	local b4 = openAbout(e4)
	tap(b4.button)
	e4.run(2)
	local tester = cardFor(featured(e4), "Tester")
	T.ok(tester ~= nil, "the tester shows the fallback name")
	T.eq(first(first(tester, "Avatar"), "Photo").Visible, false, "no picture")
	T.eq(first(first(tester, "Avatar"), "Monogram").Text, "T", "a letter")
	local atsuko = cardFor(featured(e4), "Atsuko")
	T.eq(first(first(atsuko, "Avatar"), "Photo").Visible, false, "a file that is not a picture is not shown")
	T.eq(first(first(atsuko, "Avatar"), "Monogram").Visible, true, "his letter instead")
	tap(tester)
	e4.run(1)
	local d = detail(e4)
	T.eq(first(d, "Nickname").Text, "Tester", "the fallback name on his page")
	T.eq(first(d, "HandleRow").Visible, false, "no username line")
	T.ok(withText(first(d, "Description"), SENTENCE) ~= nil, "the sentence still shows")
	T.eq(#errorsOf(e4), 0, "no error entries")
	tap(dim(e4))
	e4.run(1)
end

T.section("credits_ui: the drawn badge when the picture can't load")
do
	local e6 = boot({ files = { [BADGE] = "this is not a picture, so the drawn badge has to stay" } })
	local b6 = openAbout(e6)
	tap(b6.button)
	e6.run(2)
	local badge = first(first(cardFor(featured(e6), "Atsuko"), "NameRow"), "Verified")
	T.ok(badge ~= nil, "there is still a badge")
	T.eq(first(badge, "Official").Visible, false, "no picture")
	T.eq(#named(badge, "Seal"), 2, "the drawn seal")
	T.eq(first(badge, "Seal").Visible, true, "shows")
	T.ok(first(badge, "Tick") ~= nil, "with its tick")
	T.eq(#errorsOf(e6), 0, "and no errors")
end

T.section("credits_ui: animations off")
do
	local e5 = boot()
	e5.hub.S.animations = false
	local b5 = openAbout(e5)
	tap(b5.button)
	e5.run(0.05)
	T.ok(win(e5) ~= nil, "the window is there at once")
	T.eq(dim(e5).BackgroundTransparency, 0.4, "dimmed at once")
	T.eq(#named(win(e5), "Card"), TOTAL, "with every card")
	tap(cardFor(named(win(e5), "Card"), "Tory"))
	e5.run(0.05)
	T.ok(detail(e5) ~= nil, "a page opens at once")
	tap(first(detail(e5), "Back"))
	e5.run(0.05)
	T.eq(detail(e5), nil, "and closes at once")
	tap(dim(e5))
	e5.run(0.05)
	T.eq(dim(e5), nil, "the window closes at once")
end
