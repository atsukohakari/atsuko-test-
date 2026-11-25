local Pack = {}

local ANSWERS = {
	"It is certain.", "Without a doubt.", "Yes, definitely.", "Most likely.", "Signs point to yes.",
	"Ask again later.", "I can't tell right now.", "Better not to say.",
	"Don't count on it.", "My answer is no.", "Very doubtful.", "Not a chance.",
}

local FACTS = {
	"Honey never spoils; edible honey has been found in ancient tombs.",
	"Octopuses have three hearts and blue blood.",
	"A day on Venus is longer than its year.",
	"Bananas are berries, but strawberries are not.",
	"Sharks have been around longer than trees.",
	"There are more stars in the universe than grains of sand on Earth.",
	"A group of flamingos is called a flamboyance.",
	"Wombat droppings are cube shaped.",
	"The Eiffel Tower grows a few centimetres taller in summer heat.",
	"Sound travels about four times faster in water than in air.",
	"Cleopatra lived closer in time to the Moon landing than to the building of the Great Pyramid.",
	"A bolt of lightning is hotter than the surface of the Sun.",
	"Butterflies taste with their feet.",
	"Your stomach gets a new lining every few days.",
	"The shortest war in history lasted under an hour.",
	"Some turtles can breathe through their rear ends.",
	"Humans share about sixty percent of their DNA with bananas.",
	"The inventor of the Pringles can is buried in one.",
	"A cloud can weigh more than a million kilograms.",
	"Cats can rotate their ears nearly 180 degrees.",
}

local ADMIN_MARKS = {
	{ "HD Admin", { "hdadmin", "hd_admin", "hdadminclient" } },
	{ "Adonis", { "adonis" } },
	{ "Kohl's Admin", { "kohl" } },
	{ "Basic Admin Essentials", { "basicadmin", "basic admin" } },
	{ "Cmdr", { "cmdr" } },
	{ "Person299's Admin", { "person299" } },
	{ "Simple Admin", { "simpleadmin", "simple admin" } },
	{ "Epix Admin", { "epix" } },
}

local ANTICHEAT_WORDS = { "anticheat", "anti-cheat", "anti_cheat", "anti cheat", "antiexploit", "anti-exploit", "anti_exploit", "exploitdetect", "cheatdetect" }

function Pack.init(ctx)
	local kit, Cmd, Kit, Players, LP, S, Bus, Log, Core = ctx.kit, ctx.Cmd, ctx.Kit, ctx.Players, ctx.LP, ctx.S, ctx.Bus, ctx.Log, ctx.Core
	local notify = ctx.notify

	local function playerLine(list, fn)
		local lines = {}
		for _, p in ipairs(list) do
			lines[#lines + 1] = fn(p)
		end
		return Kit.listText(lines, 5)
	end

	kit.define("age", {
		run = function(arg)
			local list = kit.pick("Age", arg, "me")
			if not list then
				return true
			end
			return true, playerLine(list, function(p)
				return p.Name .. ": " .. Kit.agoText(p.AccountAge)
			end)
		end,
	})

	kit.define("joindate", {
		run = function(arg)
			local list = kit.pick("Join date", arg, "me")
			if not list then
				return true
			end
			return true, playerLine(list, function(p)
				local stamp = os.time() - math.floor(p.AccountAge) * 86400
				return p.Name .. ": about " .. os.date("!%Y-%m-%d", stamp)
			end)
		end,
	})

	kit.define("userid", {
		run = function(arg)
			local p = kit.one("User id", arg, "me")
			if p then
				kit.copy(tostring(p.UserId), p.Name .. "'s user id")
			end
			return true
		end,
	})

	kit.define("profile", {
		run = function(arg)
			local p = kit.one("Profile", arg, "me")
			if p then
				kit.copy("https://www.roblox.com/users/" .. p.UserId .. "/profile", p.Name .. "'s profile link")
			end
			return true
		end,
	})

	kit.define("copyname", {
		run = function(arg)
			local p = kit.one("Copy name", arg, "me")
			if p then
				kit.copy(p.Name, "Username " .. p.Name)
			end
			return true
		end,
	})

	kit.define("appearanceid", {
		run = function(arg)
			local p = kit.one("Appearance id", arg, "me")
			if not p then
				return true
			end
			local ok, id = pcall(function()
				return p.CharacterAppearanceId
			end)
			if not ok or type(id) ~= "number" then
				return false, "This game doesn't share that"
			end
			kit.copy(tostring(id), p.Name .. "'s appearance id")
			return true
		end,
	})

	kit.define("position", {
		run = function(arg)
			local p = kit.one("Position", arg, "me")
			if not p then
				return true
			end
			local r = kit.rootOf(p)
			if not r then
				return false, p.Name .. " has no character right now"
			end
			local v = r.Position
			local text = string.format("%d %d %d", math.floor(v.X + 0.5), math.floor(v.Y + 0.5), math.floor(v.Z + 0.5))
			kit.copy(text, p.Name .. " is at " .. text)
			return true
		end,
	})

	kit.define("placeid", {
		run = function()
			kit.copy(tostring(game.PlaceId), "Place id " .. tostring(game.PlaceId))
			return true
		end,
	})

	kit.define("creatorid", {
		run = function()
			local id = game.CreatorId
			if type(id) ~= "number" or id == 0 then
				return false, "This game doesn't say who made it"
			end
			local kind = "creator"
			pcall(function()
				kind = game.CreatorType == Enum.CreatorType.Group and "group" or "creator"
			end)
			kit.copy(tostring(id), "Id of the " .. kind .. " " .. tostring(id))
			return true
		end,
	})

	kit.define("memory", {
		run = function()
			local ok, mb = pcall(function()
				return game:GetService("Stats"):GetTotalMemoryUsageMb()
			end)
			if not ok or type(mb) ~= "number" then
				return false, "Roblox didn't say"
			end
			return true, string.format("The game is using %d MB", math.floor(mb + 0.5))
		end,
	})

	kit.define("robloxversion", {
		run = function()
			local ok, v = pcall(function()
				return version()
			end)
			if not ok then
				return false, "Roblox didn't say"
			end
			return true, "Roblox " .. tostring(v)
		end,
	})

	kit.define("clock", {
		usage = "clock [zone]",
		run = function(arg)
			local sign, h, m = string.match(string.lower(tostring(arg or "")), "(%+?%-?)(%d+):?(%d*)")
			local offset = 0
			local label = "UTC"
			if sign and h then
				offset = tonumber(h) + (tonumber(m) or 0) / 60
				if sign == "-" then
					offset = -offset
				end
				if offset > 14 or offset < -12 then
					return false, "That zone doesn't exist"
				end
				label = "UTC" .. (offset >= 0 and "+" or "-") .. Kit.formatNumber(math.abs(offset))
			end
			local stamp = os.time() + math.floor(offset * 3600)
			return true, os.date("!%H:%M:%S", stamp) .. " in " .. label
		end,
	})

	kit.define("instances", {
		usage = "instances [class]",
		run = function(arg)
			local class = tostring(arg or "")
			class = string.match(class, "^%s*(%S+)") or ""
			local all = game:GetDescendants()
			if class == "" then
				return true, #all .. " instances in the game"
			end
			local n = 0
			for i, inst in ipairs(all) do
				local ok, is = pcall(inst.IsA, inst, class)
				if ok and is then
					n += 1
				end
				if i % 20000 == 0 then
					task.wait()
				end
			end
			return true, n .. " of class " .. class
		end,
	})

	local function timeText(secs)
		local Time = ctx.ServerTime
		if Time then
			return Time.text(secs)
		end
		secs = math.max(0, math.floor(tonumber(secs) or 0))
		local h, m, s = math.floor(secs / 3600), math.floor((secs % 3600) / 60), secs % 60
		if h > 0 then
			return h .. "h " .. m .. "m " .. s .. "s"
		end
		return (m > 0 and (m .. "m ") or "") .. s .. "s"
	end

	kit.define("serverinfo", {
		run = function()
			local lines = { #Players:GetPlayers() .. " of " .. Players.MaxPlayers .. " players" }
			local clock = ctx.ServerClock
			local how = nil
			if clock then
				local age
				age, how = clock.age()
				lines[#lines + 1] = "Server up for " .. timeText(age)
				if how ~= "least" then
					lines[#lines + 1] = "You've been here " .. timeText(clock.here())
				end
				local newest = clock.newest(3)
				if #newest > 0 then
					local parts = {}
					for _, n in ipairs(newest) do
						parts[#parts + 1] = tostring(n.player.DisplayName) .. " " .. timeText(n.ago) .. " ago"
					end
					lines[#lines + 1] = "Newest: " .. table.concat(parts, ", ")
				end
			else
				local here = 0
				pcall(function()
					here = workspace.DistributedGameTime
				end)
				lines[#lines + 1] = "You've been here " .. timeText(here)
			end
			if how == "before" then
				lines[#lines + 1] = "Roblox keeps the real start hidden, so this counts from your first time in this server"
			elseif how == "least" then
				lines[#lines + 1] = "Roblox keeps the real start hidden, so this counts from when you got here"
			end
			if game.JobId ~= "" and kit.copy(game.JobId, nil, true) then
				lines[#lines + 1] = "Job id copied"
			end
			return true, table.concat(lines, "\n")
		end,
	})

	kit.define("coinflip", {
		run = function()
			return true, math.random(1, 2) == 1 and "Heads" or "Tails"
		end,
	})

	kit.define("roll", {
		usage = "roll [sides]",
		run = function(arg)
			local sides = math.floor(kit.number(arg, 6, 2, 1000000))
			return true, "You rolled " .. math.random(1, sides) .. " (1 to " .. sides .. ")"
		end,
	})

	kit.define("eightball", {
		run = function(arg)
			if string.find(tostring(arg or ""), "^%s*$") then
				return false, "Ask a question first"
			end
			return true, ANSWERS[math.random(1, #ANSWERS)]
		end,
	})

	kit.define("funfact", {
		run = function()
			return true, FACTS[math.random(1, #FACTS)]
		end,
	})

	kit.define("math", {
		run = function(arg)
			local value, why = Kit.mathValue(arg)
			if value == nil then
				return false, why
			end
			return true, tostring(arg) .. " = " .. Kit.formatNumber(value)
		end,
	})

	kit.define("notify", {
		run = function(arg)
			local text = string.match(tostring(arg or ""), "^%s*(.-)%s*$")
			if text == "" then
				return false, "Say what to show"
			end
			notify("Notice", string.sub(text, 1, 200), "info", 4)
			return true
		end,
	})

	kit.define("clear", {
		run = function()
			Log.clear()
			for _, name in ipairs({ "rconsoleclear", "clearconsole" }) do
				if Cmd.has(name) then
					pcall(function()
						(ctx.GENV[name] or _G[name])()
					end)
				end
			end
			return true, "Console cleared"
		end,
	})

	kit.define("cmds", {
		usage = "cmds [command]",
		run = function(arg)
			local word = string.lower(string.match(tostring(arg or ""), "^%s*(%S+)") or "")
			if word == "" then
				ctx.Panel.nav("commands")
				return true
			end
			local prefix = S.prefix or ";"
			if string.sub(word, 1, #prefix) == prefix then
				word = string.sub(word, #prefix + 1)
			end
			local def = Cmd.by[word] or Cmd.off[word]
			if not def then
				return false, "No command called " .. word
			end
			return true, prefix .. (def.usage or def.id) .. ": " .. tostring(def.desc or "")
		end,
	})

	kit.define("backpack", {
		run = function(arg)
			local list = kit.pick("Backpack", arg, "me")
			if not list then
				return true
			end
			return true, playerLine(list, function(p)
				local names = {}
				local pack = p:FindFirstChildOfClass("Backpack")
				for _, t in ipairs(pack and pack:GetChildren() or {}) do
					if t:IsA("Tool") then
						names[#names + 1] = t.Name
					end
				end
				local held = p.Character and p.Character:FindFirstChildOfClass("Tool")
				if held then
					names[#names + 1] = held.Name .. " (held)"
				end
				return p.Name .. ": " .. (#names > 0 and Kit.listText(names, 6) or "no tools")
			end)
		end,
	})

	kit.define("admindetect", {
		run = function()
			local found = {}
			local roots = { game:GetService("ReplicatedStorage"), workspace, game:GetService("Lighting"), game:GetService("StarterGui"), game:GetService("StarterPlayer") }
			local gui = LP:FindFirstChildOfClass("PlayerGui")
			if gui then
				roots[#roots + 1] = gui
			end
			for _, root in ipairs(roots) do
				for _, child in ipairs(root:GetChildren()) do
					local name = string.lower(child.Name)
					for _, mark in ipairs(ADMIN_MARKS) do
						for _, word in ipairs(mark[2]) do
							if string.find(name, word, 1, true) and not table.find(found, mark[1]) then
								found[#found + 1] = mark[1]
							end
						end
					end
				end
			end
			if #found == 0 then
				return true, "No known admin system found"
			end
			return true, "This game seems to use " .. Kit.listText(found, 4)
		end,
	})

	kit.define("anticheats", {
		run = function()
			local found = {}
			local seen = 0
			local roots = { game:GetService("ReplicatedStorage"), workspace, game:GetService("StarterPlayer"), game:GetService("StarterGui") }
			for _, root in ipairs(roots) do
				for _, inst in ipairs(root:GetDescendants()) do
					seen += 1
					if seen % 4000 == 0 then
						task.wait()
					end
					if #found < 8 and (inst:IsA("LocalScript") or inst:IsA("RemoteEvent") or inst:IsA("RemoteFunction") or inst:IsA("ModuleScript") or inst:IsA("Folder")) then
						local name = string.lower(inst.Name)
						for _, word in ipairs(ANTICHEAT_WORDS) do
							if string.find(name, word, 1, true) then
								found[#found + 1] = inst.Name
								break
							end
						end
					end
				end
			end
			if #found == 0 then
				return true, "Nothing that looks like an anti-cheat"
			end
			return true, "Found " .. Kit.listText(found, 6)
		end,
	})

	kit.define("playerlogs", {
		start = function()
			kit.on("playerlogs", Players.PlayerAdded, function(p)
				notify("Joined", p.DisplayName .. " (@" .. p.Name .. ")", "info", 3)
			end)
			kit.on("playerlogs", Players.PlayerRemoving, function(p)
				notify("Left", p.DisplayName .. " (@" .. p.Name .. ")", "info", 3)
			end)
			return true
		end,
		stop = function() end,
	})

	kit.define("chatlogs", {
		desc = "Writes what players say into the hub's console. Games with the newer chat may not share every message.",
		start = function()
			local function watch(p)
				kit.on("chatlogs", p.Chatted, function(msg)
					Log.add("info", "Chat", p.Name .. ": " .. tostring(msg))
				end)
			end
			for _, p in ipairs(Players:GetPlayers()) do
				watch(p)
			end
			kit.on("chatlogs", Players.PlayerAdded, watch)
			pcall(function()
				local service = game:GetService("TextChatService")
				kit.on("chatlogs", service.MessageReceived, function(m)
					local who = m.TextSource and m.TextSource.Name or "?"
					Log.add("info", "Chat", who .. ": " .. tostring(m.Text))
				end)
			end)
			return true
		end,
		stop = function() end,
	})
end

return Pack
