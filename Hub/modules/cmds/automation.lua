local Pack = {}

local COMPLIMENTS = {
	"you have a really good eye for this game.",
	"thanks for being friendly today.",
	"your avatar looks great.",
	"you play really well.",
	"you make this server nicer.",
	"that was a smart move.",
	"you have good taste.",
	"nice to have you here.",
	"you are good at this.",
	"your style is cool.",
	"you made me smile.",
	"you are a good sport.",
}

local RESERVED = { list = true, new = true, delete = true, clear = true, stop = true, add = true, remove = true }
local MAX_ALIASES = 60
local MAX_COMBOS = 30
local MAX_STEPS = 12
local MAX_BINDS = 40
local MAX_PENDING = 20
local MAX_LOOPS = 5
local MAX_SPAM = 20
local SPAM_GAP = 5
local MAX_DEPTH = 4

function Pack.init(ctx)
	local kit, Cmd, Kit, S, Log, Players, LP, Core = ctx.kit, ctx.Cmd, ctx.Kit, ctx.S, ctx.Log, ctx.Players, ctx.LP, ctx.Core
	local UserInputService = game:GetService("UserInputService")
	local notify = ctx.notify

	local function trim(text)
		return (string.gsub(string.gsub(tostring(text or ""), "^%s+", ""), "%s+$", ""))
	end

	local depth = 0
	local function runText(text)
		if depth >= MAX_DEPTH then
			return false, "Commands are calling each other too deep"
		end
		depth += 1
		local ok, err = pcall(Cmd.exec, text)
		depth -= 1
		if not ok then
			Log.add("error", "Commands", tostring(err))
			return false, "That command failed"
		end
		return true
	end

	local function loadMap(id)
		local raw = Cmd.val(id, "map", {})
		local out = {}
		if type(raw) == "table" then
			for k, v in pairs(raw) do
				if type(k) == "string" and type(v) == "string" then
					out[k] = v
				end
			end
		end
		return out
	end

	local function count(map)
		local n = 0
		for _ in pairs(map) do
			n += 1
		end
		return n
	end

	local function sortedKeys(map)
		local keys = {}
		for k in pairs(map) do
			keys[#keys + 1] = k
		end
		table.sort(keys)
		return keys
	end

	local function nameOk(name)
		return type(name) == "string" and #name >= 1 and #name <= 20 and string.find(name, "^%a[%w_]*$") ~= nil
	end

	local aliasIds = {}

	local function taken(name)
		if Cmd.tokens[name] and not aliasIds[name] then
			return true
		end
		if string.sub(name, 1, 2) == "un" then
			local base = Cmd.by[string.sub(name, 3)]
			if base and base.kind == "toggle" then
				return true
			end
		end
		local D = Core.Dispatch
		if D and not aliasIds[name] then
			local ok, has = pcall(D.has, D, name)
			if ok and has then
				return true
			end
		end
		return false
	end

	local function registerAlias(name, text)
		local def = {
			id = name,
			name = name,
			kind = "action",
			icon = "command",
			cat = "Mine",
			usage = name .. " [more]",
			desc = "Your own shortcut. It runs: " .. text,
			userAlias = true,
			run = function(arg)
				local line = text
				local extra = trim(arg)
				if extra ~= "" then
					line = line .. " " .. extra
				end
				local ok, why = runText(line)
				if not ok then
					return false, why
				end
				return true
			end,
		}
		if Cmd.add(def) then
			aliasIds[name] = true
			return true
		end
		return false
	end

	kit.define("alias", {
		run = function(arg)
			local text = trim(arg)
			if text == "" or string.lower(text) == "list" then
				local map = loadMap("alias")
				local keys = sortedKeys(map)
				if #keys == 0 then
					return true, "No shortcuts yet. Try: alias hi say hello"
				end
				return true, Kit.listText(keys, 12)
			end
			local name, rest = string.match(text, "^(%S+)%s+(.+)$")
			if not name then
				return false, "Give a name and a command, like: alias hi say hello"
			end
			name = string.lower(name)
			rest = trim(rest)
			if not nameOk(name) or RESERVED[name] then
				return false, "A name is letters and numbers, up to 20, starting with a letter"
			end
			if taken(name) then
				return false, name .. " is already a command"
			end
			if #rest > 200 then
				return false, "That command is too long"
			end
			local map = loadMap("alias")
			if not map[name] and count(map) >= MAX_ALIASES then
				return false, "That is the most shortcuts you can keep (" .. MAX_ALIASES .. ")"
			end
			if aliasIds[name] then
				Cmd.remove(name)
				aliasIds[name] = nil
			end
			if not registerAlias(name, rest) then
				return false, "Couldn't make that shortcut"
			end
			map[name] = rest
			Cmd.setVal("alias", "map", map)
			return true, name .. " now runs " .. rest
		end,
	})

	kit.define("delalias", {
		run = function(arg)
			local name = string.lower(trim(arg))
			local map = loadMap("alias")
			if name == "" then
				return false, "Say which shortcut, like: delalias hi"
			end
			if not map[name] then
				return false, "You have no shortcut called " .. name
			end
			map[name] = nil
			Cmd.setVal("alias", "map", map)
			if aliasIds[name] then
				Cmd.remove(name)
				aliasIds[name] = nil
			end
			return true, name .. " is gone"
		end,
	})

	do
		local saved = loadMap("alias")
		local added = 0
		for _, name in ipairs(sortedKeys(saved)) do
			if added < MAX_ALIASES and nameOk(name) and not RESERVED[name] and not taken(name) then
				if registerAlias(name, saved[name]) then
					added += 1
				end
			end
		end
	end

	kit.define("toggle", {
		run = function(arg)
			local word = string.lower(string.match(tostring(arg or ""), "^%s*(%S+)") or "")
			if word == "" then
				return false, "Say which command, like: toggle fly"
			end
			local def = Cmd.by[word]
			if not def or def.kind ~= "toggle" then
				return false, word .. " isn't a command with an on and off switch"
			end
			Cmd.toggle(def.id)
			return true
		end,
	})

	do
		local loops = {}
		local function stopLoops()
			local n = 0
			for run in pairs(loops) do
				run.live = false
				n += 1
			end
			loops = {}
			return n
		end
		kit.define("loop", {
			desc = "Repeats a command a number of times, a little apart. Say loop stop to cancel the repeats that are running.",
			run = function(arg)
				local text = trim(arg)
				if string.lower(text) == "stop" then
					local n = stopLoops()
					return n > 0, n > 0 and "Repeats stopped" or "Nothing is repeating"
				end
				local times, rest = string.match(text, "^(%S+)%s+(.+)$")
				local n = times and Kit.number(times, nil, 1, 100)
				if not n then
					return false, "Give a number and a command, like: loop 5 say hello"
				end
				n = math.floor(n)
				local active = 0
				for _ in pairs(loops) do
					active += 1
				end
				if active >= MAX_LOOPS then
					return false, "Too many repeats at once. loop stop cancels them"
				end
				local run = { live = true }
				loops[run] = true
				task.spawn(function()
					local fails = 0
					for _ = 1, n do
						if not run.live or not kit.alive() then
							break
						end
						local ok = runText(rest)
						fails = ok and 0 or fails + 1
						if fails >= 2 then
							break
						end
						task.wait(0.25)
					end
					loops[run] = nil
				end)
				kit.bind("loop", { Disconnect = function() end })
				return true, "Repeating " .. n .. " times. loop stop cancels it"
			end,
		})
		Cmd.loopStop = stopLoops
	end

	do
		local pending = 0
		kit.define("runafter", {
			run = function(arg)
				local secs, rest = string.match(tostring(arg or ""), "^%s*(%S+)%s+(.+)$")
				local n = secs and Kit.number(secs, nil, 0, 3600)
				if not n then
					return false, "Give seconds and a command, like: runafter 10 fly"
				end
				if pending >= MAX_PENDING then
					return false, "Too many commands waiting"
				end
				pending += 1
				kit.later(n, function()
					pending = math.max(0, pending - 1)
					runText(trim(rest))
				end)
				return true, "Will run in " .. Kit.formatNumber(n) .. " seconds"
			end,
		})
	end

	kit.define("lastcmd", {
		run = function()
			for _, line in ipairs(S.cmdHistory or {}) do
				local word = string.lower(string.match(tostring(line), "^%s*(%S+)") or "")
				if word ~= "lastcmd" and word ~= "" then
					local ok, why = runText(line)
					if not ok then
						return false, why
					end
					return true, "Ran " .. line
				end
			end
			return false, "No earlier command to repeat"
		end,
	})

	do
		local function chains()
			local raw = Cmd.val("combo", "chains", {})
			local out = {}
			if type(raw) == "table" then
				for name, steps in pairs(raw) do
					if type(name) == "string" and type(steps) == "table" then
						local list = {}
						for _, step in ipairs(steps) do
							if type(step) == "string" then
								list[#list + 1] = step
							end
						end
						if #list > 0 then
							out[name] = list
						end
					end
				end
			end
			return out
		end

		local running = 0
		kit.define("combo", {
			run = function(arg)
				local text = trim(arg)
				local word, rest = string.match(text, "^(%S+)%s*(.-)$")
				word = string.lower(word or "")
				local all = chains()
				if word == "" or word == "list" then
					local keys = sortedKeys(all)
					if #keys == 0 then
						return true, "No combos yet. Try: combo new party fly | spin"
					end
					return true, Kit.listText(keys, 12)
				end
				if word == "clear" then
					Cmd.setVal("combo", "chains", {})
					return true, "All combos removed"
				end
				if word == "delete" then
					local name = string.lower(trim(rest))
					if not all[name] then
						return false, "You have no combo called " .. name
					end
					all[name] = nil
					Cmd.setVal("combo", "chains", all)
					return true, name .. " removed"
				end
				if word == "new" then
					local name, body = string.match(rest, "^(%S+)%s+(.+)$")
					if not name then
						return false, "Give a name and commands split by |, like: combo new party fly | spin"
					end
					name = string.lower(name)
					if not nameOk(name) or RESERVED[name] then
						return false, "A name is letters and numbers, up to 20, starting with a letter"
					end
					if not all[name] and count(all) >= MAX_COMBOS then
						return false, "That is the most combos you can keep (" .. MAX_COMBOS .. ")"
					end
					local steps = {}
					for piece in string.gmatch(body, "[^|]+") do
						piece = trim(piece)
						if piece ~= "" then
							steps[#steps + 1] = string.sub(piece, 1, 200)
						end
					end
					if #steps == 0 then
						return false, "Add at least one command"
					end
					if #steps > MAX_STEPS then
						return false, "A combo can have " .. MAX_STEPS .. " commands at most"
					end
					all[name] = steps
					Cmd.setVal("combo", "chains", all)
					return true, name .. " saved with " .. #steps .. (#steps == 1 and " command" or " commands")
				end
				local steps = all[word]
				if not steps then
					return false, "You have no combo called " .. word
				end
				if running >= 3 then
					return false, "Wait for the other combos to finish"
				end
				running += 1
				task.spawn(function()
					for _, step in ipairs(steps) do
						if not kit.alive() then
							break
						end
						runText(step)
						task.wait(0.2)
					end
					running = math.max(0, running - 1)
				end)
				return true
			end,
		})
	end

	kit.define("exceptions", {
		run = function(arg)
			local word, rest = string.match(trim(arg), "^(%S+)%s*(.-)$")
			word = string.lower(word or "")
			local list = Cmd.val("exceptions", "names", {})
			local names = {}
			if type(list) == "table" then
				for _, n in ipairs(list) do
					if type(n) == "string" then
						names[#names + 1] = n
					end
				end
			end
			local function find(name)
				for i, n in ipairs(names) do
					if string.lower(n) == string.lower(name) then
						return i
					end
				end
				return nil
			end
			if word == "" or word == "list" then
				if #names == 0 then
					return true, "Nobody is on the list. exceptions add <name>"
				end
				return true, Kit.listText(names, 12)
			end
			if word == "clear" then
				Cmd.setVal("exceptions", "names", {})
				return true, "The list is empty now"
			end
			rest = trim(rest)
			if rest == "" then
				return false, "Say a player name"
			end
			local who = Cmd.findPlayer(rest)
			local name = who and who.Name or string.sub(rest, 1, 30)
			if word == "add" then
				if find(name) then
					return true, name .. " is already on the list"
				end
				if #names >= 50 then
					return false, "The list is full (50)"
				end
				names[#names + 1] = name
				Cmd.setVal("exceptions", "names", names)
				return true, name .. " is safe from all and others"
			end
			if word == "remove" then
				local i = find(name)
				if not i then
					return false, name .. " is not on the list"
				end
				table.remove(names, i)
				Cmd.setVal("exceptions", "names", names)
				return true, name .. " removed"
			end
			return false, "Use add, remove, list or clear"
		end,
	})

	local function watcher(id, signalName, verb, example)
		local last = 0
		kit.define(id, {
			start = function(arg)
				local text = trim(arg)
				if text == "" then
					text = Cmd.val(id, "text", "")
				end
				if text == "" then
					return false, "Say what to run, like: " .. example
				end
				Cmd.setVal(id, "text", string.sub(text, 1, 200))
				kit.on(id, Players[signalName], function(p)
					if p == LP then
						return
					end
					local now = os.clock()
					if now - last < 1 then
						return
					end
					last = now
					local line = string.gsub(Cmd.val(id, "text", ""), "{player}", p.Name)
					runText(line)
				end)
				return true
			end,
			update = function(arg)
				local text = trim(arg)
				if text ~= "" then
					Cmd.setVal(id, "text", string.sub(text, 1, 200))
				end
			end,
			stop = function() end,
			label = function()
				return "Runs when someone " .. verb
			end,
		})
	end
	watcher("onjoin", "PlayerAdded", "joins", "onjoin say welcome {player}")
	watcher("onleave", "PlayerRemoving", "leaves", "onleave say bye {player}")

	kit.define("prefix", {
		run = function(arg)
			local P = Core.Prefix
			if not P then
				return false, "The prefix tools didn't load"
			end
			local ok, value = P.validate(arg)
			if not ok then
				return false, value
			end
			S.prefix = value
			ctx.saveSettings()
			ctx.Bus.fire("prefix")
			return true, "The prefix is " .. value .. " now"
		end,
	})

	kit.define("say", {
		run = function(arg)
			return kit.chat(trim(arg))
		end,
	})

	kit.define("whisper", {
		selectors = true,
		run = function(arg)
			local who, text = string.match(tostring(arg or ""), "^%s*(%S+)%s+(.+)$")
			if not who then
				return false, "Give a player and a message, like: whisper bob hello"
			end
			local p, why = kit.one("Whisper", who, nil, true)
			if not p then
				return false, why
			end
			if p == LP then
				return false, "Pick someone else"
			end
			return kit.chat("/w " .. p.Name .. " " .. trim(text))
		end,
	})

	kit.define("compliment", {
		selectors = true,
		run = function(arg)
			local p, why = kit.one("Compliment", arg, nil, true)
			if not p then
				return false, why
			end
			local line = COMPLIMENTS[math.random(1, #COMPLIMENTS)]
			return kit.chat(p.DisplayName .. ", " .. line)
		end,
	})

	do
		local sent = 0
		kit.define("spam", {
			desc = "Repeats a chat message every " .. SPAM_GAP .. " seconds, up to " .. MAX_SPAM .. " times, then stops by itself. Roblox can mute or remove players who spam, so use it sparingly.",
			start = function(arg)
				local text = trim(arg)
				if text == "" then
					text = Cmd.val("spam", "text", "")
				end
				if text == "" then
					return false, "Say what to repeat, like: spam hello"
				end
				Cmd.setVal("spam", "text", string.sub(text, 1, 100))
				sent = 0
				kit.every("spam", SPAM_GAP, function()
					local ok = kit.chat(Cmd.val("spam", "text", ""))
					if ok then
						sent += 1
					end
					if sent >= MAX_SPAM then
						task.defer(Cmd.set, "spam", false, nil, true)
					end
				end)
				return true
			end,
			update = function(arg)
				local text = trim(arg)
				if text ~= "" then
					Cmd.setVal("spam", "text", string.sub(text, 1, 100))
				end
			end,
			stop = function() end,
		})
	end

	kit.define("exit", {
		run = function(arg)
			if string.lower(trim(arg)) ~= "yes" then
				return false, "This closes Roblox. Type exit yes if you really want that"
			end
			notify("Exit", "Closing Roblox", "info", 1.5)
			task.delay(0.8, function()
				pcall(function()
					game:Shutdown()
				end)
			end)
			return true
		end,
	})

	do
		local binds = loadMap("bind")
		local listener

		local function codeOf(text)
			local name = trim(text)
			if name == "" then
				return nil
			end
			local digits = { ["0"] = "Zero", ["1"] = "One", ["2"] = "Two", ["3"] = "Three", ["4"] = "Four", ["5"] = "Five", ["6"] = "Six", ["7"] = "Seven", ["8"] = "Eight", ["9"] = "Nine" }
			if digits[name] then
				name = digits[name]
			elseif #name == 1 then
				name = string.upper(name)
			end
			local ok, code = pcall(function()
				return Enum.KeyCode[name]
			end)
			if ok and code and code ~= Enum.KeyCode.Unknown then
				return code, name
			end
			return nil
		end

		local lastHit = 0
		local function ensureListener()
			if listener or count(binds) == 0 then
				return
			end
			listener = ctx.hubConn(UserInputService.InputBegan:Connect(function(input, processed)
				if processed or not kit.alive() then
					return
				end
				local ok, name = pcall(function()
					return input.KeyCode.Name
				end)
				local text = ok and binds[name]
				if not text then
					return
				end
				if UserInputService:GetFocusedTextBox() then
					return
				end
				local now = os.clock()
				if now - lastHit < 0.25 then
					return
				end
				lastHit = now
				runText(text)
			end))
		end

		kit.define("bind", {
			run = function(arg)
				local text = trim(arg)
				if text == "" or string.lower(text) == "list" then
					local keys = sortedKeys(binds)
					if #keys == 0 then
						return true, "No keys bound. Try: bind f fly"
					end
					local out = {}
					for i, k in ipairs(keys) do
						out[i] = k .. " = " .. binds[k]
					end
					return true, Kit.listText(out, 8)
				end
				local key, rest = string.match(text, "^(%S+)%s+(.+)$")
				if not key then
					return false, "Give a key and a command, like: bind f fly"
				end
				local code, name = codeOf(key)
				if not code then
					return false, key .. " isn't a key I know. Try a letter, a number or a name like LeftShift"
				end
				if code == Enum.KeyCode.Escape or code == Enum.KeyCode.Tab or code == Enum.KeyCode.Slash then
					return false, name .. " is used by Roblox itself"
				end
				if Core.barKeyHit and Core.barKeyHit(name) then
					return false, name .. " opens the command bar"
				end
				if not binds[name] and count(binds) >= MAX_BINDS then
					return false, "That is the most keys you can bind (" .. MAX_BINDS .. ")"
				end
				binds[name] = string.sub(trim(rest), 1, 200)
				Cmd.setVal("bind", "map", binds)
				ensureListener()
				return true, name .. " runs " .. binds[name]
			end,
		})

		kit.define("unbind", {
			run = function(arg)
				local code, name = codeOf(arg)
				if not code or not binds[name] then
					return false, "That key has no binding"
				end
				binds[name] = nil
				Cmd.setVal("bind", "map", binds)
				return true, name .. " is free again"
			end,
		})

		ensureListener()
	end
end

return Pack
