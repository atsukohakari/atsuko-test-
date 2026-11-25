local Mod = loadmodule("Hub/modules/credits_ui.lua")
local raw = readsource("Hub/credits.json")
local data = jsondecode(raw)

local SENTENCE = "Just a tester lol, he's a cool guy :3"

local function copy(value)
	if type(value) ~= "table" then
		return value
	end
	local out = {}
	for k, v in pairs(value) do
		out[k] = copy(v)
	end
	return out
end

local function find(list, id)
	for _, entry in ipairs(list) do
		if entry.id == id then
			return entry
		end
	end
	return nil
end

local function mutated(change)
	local d = copy(data)
	change(d)
	return Mod.validate(d)
end

local function mentions(problems, needle)
	for _, text in ipairs(problems) do
		if string.find(text, needle, 1, true) then
			return true
		end
	end
	return false
end

T.section("credits_schema: the shipped file")
do
	T.ok(type(data) == "table", "Hub/credits.json is valid JSON")
	local problems = Mod.validate(data)
	T.eq(#problems, 0, "no problems: " .. table.concat(problems, " | "))
	T.eq(data.version, 1, "version 1")
	T.ok(#data.people >= 40, "at least 40 people and projects are credited")
	T.eq(#data.sections, 7, "seven sections")
	local want = { "The hub", "Testers", "Reanimation", "Scripts", "Commands", "Music and services", "Libraries and assets" }
	for i, name in ipairs(want) do
		T.eq(data.sections[i], name, "section " .. i)
	end
	for _, id in ipairs({
		"atsuko", "claude", "tester-11345577877", "tory", "myworld-rqz", "stevetherealone", "boredgal", "awes955", "dubmood", "four-mat",
		"master-boot-record", "gelatek", "poncho", "gelatek-hub", "vulnerali-padero", "andrfix", "mlg-super-killer", "epic", "supr14",
		"bloxinstud10", "noobygames12", "gobl00x", "asarii-iv", "stratopsheric-aero", "gunsforgunskidd", "dangerredile", "infinite-yield",
		"cmd-x", "fates-admin", "scriptblox", "phineas-lanyard", "yt-dlp", "lrclib", "ntfy", "lucide",
		"booga", "melonscripter", "melon", "shackluster", "auxnos", "emper", "beezeldud",
	}) do
		T.ok(find(data.people, id) ~= nil, "credited: " .. id)
	end
	T.eq(string.find(string.lower(raw), "miyu", 1, true), nil, "no Miyu")
	T.eq(string.find(string.lower(raw), "onerui", 1, true), nil, "no Onerui")
	T.eq(string.find(raw, "?si=", 1, true), nil, "no tracking tail anywhere")
	T.eq(string.find(raw, "http://", 1, true), nil, "no plain http link")
	T.eq(string.find(raw, "[^\9\10\32-\126]"), nil, "plain text only, no emoji")
	for _, entry in ipairs(data.people) do
		T.ok(type(entry.source) == "string" and entry.source ~= "", entry.id .. " says where its facts came from")
		T.ok(type(entry.description) == "string" and #entry.description >= 20, entry.id .. " has a real description")
		T.ok(entry.id ~= "roblox" and entry.name ~= "Roblox", entry.id .. " is not Roblox")
	end
	T.eq(find(data.people, "roblox"), nil, "Roblox is not credited, the owner asked")
	local verified = {}
	for _, entry in ipairs(data.people) do
		if entry.verified then
			verified[#verified + 1] = entry.id
		end
	end
	T.same(verified, { "atsuko", "claude", "tester-11345577877", "bluearchive" }, "the four the owner gave a badge")
	for _, pair in ipairs({ { "booga", "Main Scripts / Addict" }, { "melonscripter", "Main Scripts / InternalWar" }, { "melon", "Main Scripts / Commander V2" }, { "shackluster", "Main Scripts / Commander V2" }, { "beezeldud", "Main Scripts / InternalWar" }, { "emper", "Main Scripts / Addict" }, { "stevetherealone", "Main Scripts / Addict" }, { "helkern", "Main Scripts / Master Chief" }, { "melonscripter", "Main Scripts / Master Chief" }, { "emper", "Main Scripts / Master Chief" } }) do
		local entry = find(data.people, pair[1])
		local used = false
		for _, u in ipairs(entry and entry.usedIn or {}) do
			if u == pair[2] then
				used = true
			end
		end
		T.ok(used, pair[1] .. " is used in " .. pair[2])
		T.eq(entry and entry.section, pair[1] == "stevetherealone" and "Reanimation" or "Scripts")
	end
	local melon = find(data.people, "melonscripter")
	T.eq(melon.links.youtube, "https://www.youtube.com/@MelonScripter", "the socials from the InternalWar header")
	T.same(melon.links.other, { "https://x.com/MelonScripter" })
end

T.section("credits_schema: Claude, Atsuko and Tory")
do
	local claude = find(data.people, "claude")
	T.eq(claude.kind, "assistant", "Claude is an assistant")
	T.eq(claude.links.website, "https://www.anthropic.com/claude", "Claude's site")
	T.eq(claude.links.other[1], "https://claude.ai", "Claude's second link")
	T.eq(claude.description, "AI by Anthropic. Helped write, fix and test the hub with Atsuko.", "Claude's short description")
	T.same(claude.roles, { "Bug fixes", "Code and testing" }, "and so are its roles")
	for _, person in ipairs(data.people) do
		T.eq(person.why, nil, person.id .. " has no why any more")
		T.eq(person.did, nil, person.id .. " has no did any more")
		T.ok(type(person.description) == "string" and #person.description >= 20, person.id .. " has one real description")
	end
	local atsuko = find(data.people, "atsuko")
	T.eq(atsuko.links.github, "https://github.com/atsukohakari/Atsuko", "the hub's repository")
	T.eq(atsuko.description, "he's a weird guy ngl, plus he's soooo lazy like very lazyy..... and he's a femboy so.. yeah :3", "Atsuko's description, byte for byte")
	T.eq(atsuko.picture, "Hub/credits/atsuko.png", "his picture")
	T.eq(atsuko.handle, "AtsukoHakariBA", "his handle is his Roblox username")
	T.eq(atsuko.roblox.username, "AtsukoHakariBA", "and the Roblox username is filled in")
	T.eq(atsuko.roblox.userId, nil, "no id is guessed")
	T.eq(Mod.pictureKind(atsuko.picture), "file", "a file in the package")
	local png = readsource("Hub/credits/atsuko.png")
	T.ok(type(png) == "string" and #png > 1000, "the picture file is shipped")
	T.eq(claude.name, "Claude", "Claude's name")
	T.eq(claude.verified, true, "Claude's badge")
	local tory = find(data.people, "tory")
	T.eq(tory.links.discord, "https://discord.gg/kMuXv6PuXp", "Tory's discord is the one the owner gave")
	T.eq(tory.links.youtube, "https://youtube.com/@jskfhggjxu", "Tory's youtube without the tracking tail")
	T.eq(tory.roblox.username, "YeImTory", "Tory's username comes from his own script")
	T.eq(tory.profileStyle, "full", "Tory has the full card")
	for _, id in ipairs({ "stevetherealone", "myworld-rqz", "infinite-yield", "scriptblox", "phineas-lanyard", "yt-dlp", "ntfy", "lucide" }) do
		T.ok(find(data.people, id).links.discord ~= "", id .. " keeps the discord the README had")
	end
	T.eq(find(data.people, "myworld-rqz").links.discord, "https://discord.com/invite/QMy5f6DrbH", "Patchma Hub")
	T.eq(find(data.people, "stevetherealone").links.discord, "https://discord.gg/NASNUKRBVM", "Uhhhhhh")
	T.eq(find(data.people, "cmd-x").links.discord, "https://discord.gg/JyzvQ6zdfg", "CMD-X's own invite")
	T.eq(find(data.people, "fates-admin").links.github, "https://github.com/fatesc/fates-admin", "Fates Admin's repository")
end

T.section("credits_schema: the tester")
do
	local tester = find(data.people, "tester-11345577877")
	T.eq(tester.description, SENTENCE, "the owner's sentence, byte for byte")
	T.eq(#tester.description, 37, "and the same length")
	T.eq(tester.roblox.userId, 11345577877, "his Roblox id")
	T.eq(tester.roblox.username, "", "no username in the file")
	T.eq(tester.profileStyle, "roblox", "the compact card")
	T.eq(tester.links.roblox, "https://www.roblox.com/users/11345577877/profile", "his profile link")
	T.eq(tester.links.github, "", "no github")
	T.eq(tester.links.discord, "", "no discord")
	T.eq(tester.name, "Tester", "the fallback name")
	T.eq(tester.roles[1], "Tester", "role")
	T.eq(tester.why, nil, "no why on the card")
	T.eq(tester.did, nil, "no did on the card")
	T.eq(Mod.profileUrl(tester), "https://www.roblox.com/users/11345577877/profile", "the button address")
	T.eq(Mod.TESTER_SENTENCE, SENTENCE, "the module knows the same sentence")
end

T.section("credits_schema: the validator turns bad entries down")
do
	local function tory(d)
		return find(d.people, "tory")
	end
	local function tester(d)
		return find(d.people, "tester-11345577877")
	end
	T.ok(mentions(mutated(function(d) tory(d).why = "old text" end), "why is not used anymore"), "an old why is pointed out")
	T.ok(mentions(mutated(function(d) tory(d).did = "" end), "did is not used anymore"), "an old did is pointed out")
	T.eq(#mutated(function(d) tory(d).description = "Made the Neptunian V remake." end), 0, "a description alone is enough")
	T.ok(mentions(mutated(function(d) tester(d).description = "" end), "needs a description"), "roblox profile without description")
	T.ok(mentions(mutated(function(d) tester(d).roblox = { username = "", userId = nil } end), "needs roblox.userId or roblox.username"), "roblox profile without any account")
	T.ok(mentions(mutated(function(d) tester(d).description = SENTENCE .. " " end), "owner's sentence"), "altered sentence, one more space")
	T.ok(mentions(mutated(function(d) tester(d).description = "Just a tester lol, he is a cool guy :3" end), "owner's sentence"), "altered sentence, reworded")
	T.ok(mentions(mutated(function(d) tester(d).links.roblox = "https://example.com/users/1/profile" end), "links.roblox"), "roblox link not on roblox.com")
	T.ok(mentions(mutated(function(d) tester(d).roblox.userId = 5 end), "11345577877"), "tester with another id")
	T.ok(mentions(mutated(function(d) tester(d).roblox.username = "Somebody" end), "username must stay empty"), "tester with a guessed username")
	T.ok(mentions(mutated(function(d) tester(d).why = "Why" end), "why is not used anymore"), "not on a roblox profile either")
	T.ok(mentions(mutated(function(d) tory(d).links.discord = "http://discord.gg/abc" end), "links.discord"), "plain http")
	T.ok(mentions(mutated(function(d) tory(d).links.discord = "https://example.com/abc" end), "not a discord invite"), "not an invite")
	T.ok(mentions(mutated(function(d) tory(d).links.youtube = "https://youtube.com/@x?si=abc" end), "tracking tail"), "tracking tail")
	T.ok(mentions(mutated(function(d) tory(d).links.youtube = "https://vimeo.com/x" end), "not on youtube.com"), "wrong video site")
	T.ok(mentions(mutated(function(d) tory(d).links.github = "https://gitlab.com/x" end), "not on github.com"), "wrong code site")
	T.ok(mentions(mutated(function(d) tory(d).links.website = "https://a b.com" end), "has a space"), "a space in a link")
	T.ok(mentions(mutated(function(d) tory(d).links.other = { "ftp://x.com" } end), "links.other"), "other link not https")
	T.ok(mentions(mutated(function(d) tory(d).links.website = 5 end), "is not text"), "a number as a link")
	T.ok(mentions(mutated(function(d) tory(d).roblox.userId = -4 end), "positive whole number"), "negative id")
	T.ok(mentions(mutated(function(d) tory(d).roblox.userId = 1.5 end), "positive whole number"), "fractional id")
	T.ok(mentions(mutated(function(d) tory(d).roblox.userId = "12" end), "positive whole number"), "id as text")
	T.ok(mentions(mutated(function(d) tory(d).roblox.username = "ab" end), "valid username"), "short username")
	T.ok(mentions(mutated(function(d) tory(d).roblox.username = "has space" end), "valid username"), "username with a space")
	T.ok(mentions(mutated(function(d) tory(d).kind = "wizard" end), "kind must be"), "unknown kind")
	T.ok(mentions(mutated(function(d) tory(d).profileStyle = "fancy" end), "profileStyle"), "unknown style")
	T.ok(mentions(mutated(function(d) tory(d).section = "Nowhere" end), "section is not one"), "unknown section")
	T.ok(mentions(mutated(function(d) tory(d).usedIn = "Dubstep Gun" end), "usedIn must be"), "usedIn as text")
	T.ok(mentions(mutated(function(d) tory(d).usedIn = { "Fine", 5 } end), "usedIn must be"), "usedIn with a number in it")
	T.eq(#mutated(function(d) tory(d).usedIn = nil end), 0, "usedIn may be left out")
	T.ok(mentions(mutated(function(d) tester(d).links.roblox = "https://www.roblox.com/users/5/profile" end), "profile address the owner gave"), "tester with another roblox profile address")
	T.ok(mentions(mutated(function(d) tester(d).links.roblox = "" end), "profile address the owner gave"), "tester without his profile address")
	T.ok(mentions(mutated(function(d) tester(d).profileStyle = "full" end), "tester uses the roblox profile style"), "tester on the full card")
	T.ok(mentions(mutated(function(d) tory(d).roles = {} end), "roles needs"), "no roles")
	T.ok(mentions(mutated(function(d) tory(d).roles = { "" } end), "roles needs"), "empty role")
	T.ok(mentions(mutated(function(d) tory(d).source = "" end), "source is empty"), "no source")
	T.ok(mentions(mutated(function(d) tory(d).id = "Tory Two" end), "id is missing"), "bad id")
	T.ok(mentions(mutated(function(d) tory(d).name = "" end), "name is missing"), "no name")
	T.ok(mentions(mutated(function(d) tory(d).description = "caf\195\169" end), "outside plain text"), "a non-ASCII letter")
	T.ok(mentions(mutated(function(d) tory(d).description = string.rep("x", 401) end), "longer than"), "an over-long text")
	T.ok(mentions(mutated(function(d) tory(d).description = "Thanks to Miyu" end), "mentions miyu"), "Miyu")
	T.ok(mentions(mutated(function(d) tory(d).description = "Leaked by someone" end), "mentions leaked by"), "leaked by")
	T.ok(mentions(mutated(function(d) d.people[2].id = "atsuko" end), "used twice"), "a repeated id")
	T.ok(mentions(mutated(function(d) d.version = 2 end), "version must be 1"), "version")
	T.ok(mentions(mutated(function(d) d.sections[#d.sections + 1] = "Empty one" end), "has nobody in it"), "a section nobody is in")
	T.ok(mentions(mutated(function(d) table.remove(d.people, 2) end), "claude is missing"), "Claude removed")
	T.ok(mentions(mutated(function(d) d.people = {} end), "people must be a list"), "no people")
	T.ok(mentions(Mod.validate("text"), "not an object"), "not an object")
	T.ok(mentions(Mod.validate({ version = 1, sections = {}, people = {} }), "sections must be"), "no sections")
	T.ok(mentions(mutated(function(d) tory(d).description = "" end), "description is missing"), "every card needs a description")
	T.ok(mentions(mutated(function(d) tory(d).verified = "yes" end), "verified must be"), "verified is true or false")
	T.eq(#mutated(function(d) tory(d).verified = nil end), 0, "verified may be left out")
	T.ok(mentions(mutated(function(d) tory(d).picture = "Hub/logo.png" end), "picture must be"), "a picture outside Hub/credits")
	T.ok(mentions(mutated(function(d) tory(d).picture = "Hub/credits/../AtsukoHub.lua" end), "picture must be"), "a picture that climbs out")
	T.ok(mentions(mutated(function(d) tory(d).picture = "http://example.com/a.png" end), "picture must be"), "a picture over plain http")
	T.ok(mentions(mutated(function(d) tory(d).picture = "Hub/credits/tory.gif" end), "picture must be"), "a gif")
	T.eq(#mutated(function(d) tory(d).picture = "Hub/credits/tory.jpg" end), 0, "a jpg in Hub/credits")
	T.eq(#mutated(function(d) tory(d).picture = "1234567" end), 0, "a Roblox image id")
	T.eq(#mutated(function(d) tory(d).picture = "rbxassetid://1234567" end), 0, "an rbxassetid")
	T.eq(#mutated(function(d) tory(d).picture = "https://example.com/tory.png" end), 0, "an https link")
	T.ok(mentions(mutated(function(d) tory(d).handle = "two words" end), "handle may only"), "a handle with a space")
	T.ok(mentions(mutated(function(d) tory(d).handle = "x" end), "handle may only"), "a one letter handle")
	T.eq(#mutated(function(d) tory(d).handle = "yeim.tory_2" end), 0, "a handle with dots and underscores")
	T.ok(mentions(mutated(function(d) d.people[#d.people + 1] = { id = "roblox", name = "Roblox", kind = "service", section = "Commands", roles = { "Platform" }, why = "w", did = "d", description = "the platform", source = "s" } end), "not to be credited"), "Roblox is refused")
	T.ok(mentions(mutated(function(d) tory(d).name = "roblox" end), "not to be credited"), "under any id")
end

T.section("credits_schema: links")
do
	T.eq(Mod.linkProblem("github", ""), nil, "empty is fine")
	T.eq(Mod.linkProblem("github", nil), nil, "missing is fine")
	T.eq(Mod.linkProblem("website", "https://example.com/a"), nil, "any https site for a website")
	T.eq(Mod.linkProblem("roblox", "https://www.roblox.com/users/1/profile"), nil, "roblox ok")
	T.ok(Mod.linkProblem("roblox", "https://roblox.com/users/1/profile") ~= nil, "roblox without www is not the address the owner gave")
	T.eq(Mod.linkProblem("youtube", "https://www.youtube.com/@x"), nil, "youtube with www")
	T.eq(Mod.linkProblem("youtube", "https://youtube.com/@jskfhggjxu"), nil, "youtube without www")
	T.eq(Mod.linkProblem("discord", "https://discord.com/invite/QMy5f6DrbH"), nil, "discord.com/invite")
	T.eq(Mod.linkProblem("discord", "https://discord.gg/78ZuWSq"), nil, "discord.gg")
	T.ok(Mod.linkProblem("website", "javascript:alert(1)") ~= nil, "javascript links are refused")
	T.ok(Mod.linkProblem("website", "//example.com") ~= nil, "protocol-relative links are refused")
end

T.section("credits_schema: the roblox profile address")
do
	T.eq(Mod.profileUrl({ links = { roblox = "https://www.roblox.com/users/5/profile" }, roblox = { userId = 9 } }), "https://www.roblox.com/users/5/profile", "links.roblox wins")
	T.eq(Mod.profileUrl({ links = { roblox = "" }, roblox = { userId = 9 } }), "https://www.roblox.com/users/9/profile", "built from the id")
	T.eq(Mod.profileUrl({ links = {}, roblox = { userId = 11345577877 } }), "https://www.roblox.com/users/11345577877/profile", "a big id has no exponent")
	T.eq(Mod.profileUrl({ links = { roblox = "https://evil.example/x" }, roblox = { userId = 9 } }), "https://www.roblox.com/users/9/profile", "a link off roblox.com is ignored")
	T.eq(Mod.profileUrl({ links = { roblox = "" }, roblox = { username = "Abc" } }), nil, "no id and no link means no button")
	T.eq(Mod.profileUrl({ roblox = { userId = 0 } }), nil, "zero is not an id")
	T.eq(Mod.profileUrl({ links = {}, roblox = { userId = 2.5 } }), nil, "a fraction is not an id")
	T.eq(Mod.profileUrl({}), nil, "an empty entry")
end

T.section("credits_schema: sanitising what the owner edits by hand")
do
	local messy = {
		version = 1,
		sections = { "A", "B", "" },
		people = {
			{ id = "one", name = "One", kind = "person", section = "A", roles = { "Maker" }, why = "w", did = "d", links = { github = "http://nope", discord = "https://discord.gg/x", website = "https://ok.example", other = { "https://a.example", "bad", 3 } }, roblox = { username = "ab", userId = -3 } },
			{ id = "one", name = "Again", kind = "person", section = "A", roles = { "x" } },
			{ id = "two", name = "", kind = "person", section = "A" },
			{ id = "three", name = "Three", kind = "robot", section = "A" },
			{ id = "four", name = "Four", kind = "service", section = "Zed" },
			{ id = "five", name = "Five", kind = "person", profileStyle = "roblox", description = "hello", section = "B", roles = { "T" }, roblox = { userId = 77 } },
			{ id = "six", name = "Six", kind = "person", profileStyle = "roblox", description = "hello", section = "B", roles = { "T" } },
			"not an entry",
		},
	}
	local clean = Mod.sanitize(messy)
	T.eq(#clean.people, 4, "four entries survive")
	T.eq(#clean.skipped, 4, "four are skipped: a repeat, no name, a wrong kind, not a table")
	local one = find(clean.people, "one")
	T.eq(one.links.github, "", "the plain http link is dropped")
	T.eq(one.links.discord, "https://discord.gg/x", "a good link stays")
	T.eq(#one.links.other, 1, "only the good extra link stays")
	T.eq(one.roblox.username, "", "a bad username is dropped")
	T.eq(one.roblox.userId, nil, "a bad id is dropped")
	T.eq(one.profileStyle, "full", "full by default")
	T.eq(find(clean.people, "four").section, "Zed", "an unknown section is kept")
	T.eq(clean.sections[#clean.sections], "Zed", "and added to the list")
	T.eq(find(clean.people, "four").roles[1], "Service", "no roles: the kind is shown")
	T.eq(find(clean.people, "five").profileStyle, "roblox", "a roblox profile with an id stays one")
	T.eq(find(clean.people, "six").profileStyle, "full", "a roblox profile with no account is shown as a normal card")
	local oddIds = Mod.sanitize({ sections = { "A" }, people = {
		{ id = "frac", name = "Frac", kind = "person", section = "A", roles = { "R" }, roblox = { userId = 12.5 } },
		{ id = "neg", name = "Neg", kind = "person", section = "A", roles = { "R" }, roblox = { userId = -3 } },
		{ id = "txt", name = "Txt", kind = "person", section = "A", roles = { "R" }, roblox = { userId = "12" } },
		{ id = "good", name = "Good", kind = "person", section = "A", roles = { "R" }, roblox = { userId = 12 } },
	} })
	T.eq(find(oddIds.people, "frac").roblox.userId, nil, "a fractional id is dropped")
	T.eq(find(oddIds.people, "neg").roblox.userId, nil, "a negative id is dropped")
	T.eq(find(oddIds.people, "txt").roblox.userId, nil, "an id written as text is dropped")
	T.eq(find(oddIds.people, "good").roblox.userId, 12, "a whole positive id stays")
	T.eq(#Mod.sanitize(nil).people, 0, "nothing at all")
	T.eq(#Mod.sanitize({ people = "x" }).people, 0, "people that is not a list")
	local real = Mod.sanitize(data)
	T.eq(#real.people, #data.people, "nothing is lost from the real file")
	T.eq(#real.skipped, 0, "and nothing is skipped")
end

T.section("credits_schema: rows, search and sections")
do
	local clean = Mod.sanitize(data)
	T.eq(Mod.monogram("Tory"), "T", "monogram")
	T.eq(Mod.monogram("  4mat"), "4", "a digit counts")
	T.eq(Mod.monogram("!!!"), "?", "nothing usable")
	T.eq(Mod.monogram(nil), "?", "nil")
	T.eq(Mod.monogram("gObl00x"), "G", "upper case")
	T.eq(Mod.rowRole({ roles = { "Music" } }), "Music", "one role")
	T.eq(Mod.rowRole({ roles = { "FDless reanimate", "Patchma Hub" } }), "FDless reanimate +1", "more roles")
	T.eq(Mod.rowRole({}), "", "none")
	local all = Mod.groups(clean, "")
	T.eq(#all, 7, "seven sections shown")
	T.eq(all[1].title, "The hub", "in the file's order")
	T.eq(#all[1].items, 2, "two people in the hub section")
	T.eq(all[2].title, "Testers", "testers second")
	T.eq(#all[2].items, 1, "one tester")
	local total = 0
	for _, g in ipairs(all) do
		total += #g.items
	end
	T.eq(total, #data.people, "everybody is in some section")
	local found = Mod.groups(clean, "tory")
	T.eq(#found, 1, "searching tory finds one section")
	T.eq(found[1].items[1].id, "tory", "and it is Tory")
	T.eq(#Mod.groups(clean, "TORY"), 1, "case does not matter")
	T.eq(#Mod.groups(clean, "  tory  "), 1, "spaces around are ignored")
	T.eq(#Mod.groups(clean, "zzzzqqqq"), 0, "nothing found")
	T.ok(#Mod.groups(clean, "music") >= 1, "searching a role works")
	local dubstep = 0
	for _, g in ipairs(Mod.groups(clean, "dubstep")) do
		dubstep += #g.items
	end
	T.ok(dubstep >= 2, "searching a script name finds the people around it")
	T.ok(#Mod.groups(clean, "yeimtory") == 1, "a roblox username can be searched")
	T.ok(Mod.matches(find(clean.people, "tory"), "neptunian remake"), "two words, both must be there")
	T.ok(not Mod.matches(find(clean.people, "tory"), "neptunian dubstep"), "and all of them")
	local sample = { name = "Sample", section = "Somewhere", kind = "project", roles = { "Maker" }, usedIn = { "Dubstep Gun", "Last Star" }, roblox = { username = "" }, links = { other = { "https://example.com/more" } } }
	T.ok(Mod.matches(sample, "dubstep"), "the scripts a person is used in can be searched")
	T.ok(Mod.matches(sample, "last star"), "and two words of one script")
	T.ok(Mod.matches(sample, "somewhere maker"), "section and role together")
	T.ok(not Mod.matches(sample, "elsewhere"), "something that is not there")
	local stray = { sections = { "A" }, people = { { name = "Stray", section = "Not listed", kind = "person", roles = { "R" }, usedIn = {}, roblox = { username = "" } } } }
	local okStray, shownStray = pcall(Mod.groups, stray, "")
	T.ok(okStray, "an entry in a section the list does not have does not break the groups")
	T.eq(okStray and #shownStray or -1, 0, "and it is simply not shown")
	local withOther = Mod.sanitize({ sections = { "A" }, people = {
		{ id = "more", name = "More", kind = "project", section = "A", roles = { "R" }, description = "Did it", links = { github = "https://github.com/x/y", other = { "https://example.com/one", "https://example.com/two" } } },
		{ id = "card", name = "Card", kind = "person", section = "A", roles = { "R" }, profileStyle = "roblox", description = "Short words", roblox = { userId = 5 } },
	} })
	T.eq(Mod.plainText(withOther), "More - Did it - https://github.com/x/y - https://example.com/one - https://example.com/two\nCard - Short words", "copy all: links in a fixed order, the extra links last, every card uses its description")
	local text = Mod.plainText(clean)
	T.ok(string.find(text, "Tory - Made the Neptunian V remake", 1, true) ~= nil, "copy all: Tory's line")
	T.ok(string.find(text, "https://discord.gg/kMuXv6PuXp", 1, true) ~= nil, "copy all: Tory's discord")
	T.ok(string.find(text, SENTENCE, 1, true) ~= nil, "copy all: the tester's sentence")
	local lines = 0
	for _ in string.gmatch(text, "[^\n]+") do
		lines += 1
	end
	T.eq(lines, #data.people, "one line each")
end

T.section("credits_schema: the window's geometry")
do
	local x, y, w, h, mode = Mod.windowRect(1365, 768)
	T.eq(mode, "window", "a computer screen gets a window")
	T.eq(w, 820, "it stops at 820 wide")
	T.eq(h, 660, "and 660 high")
	T.eq(x, math.floor((1365 - 820) / 2), "centred sideways")
	T.eq(y, math.floor((768 - 660) / 2), "and up and down")
	local _, _, w2, h2, mode2 = Mod.windowRect(900, 520)
	T.eq(mode2, "window", "a short computer screen still gets a window")
	T.eq(w2, 820, "as wide as it can")
	T.eq(h2, 456, "and as tall as the screen allows")
	local sx, sy, sw, sh, smode = Mod.windowRect(520, 1125)
	T.eq(smode, "sheet", "a phone gets a sheet")
	T.eq(sx, 8, "an 8 margin")
	T.eq(sw, 504, "nearly the whole width")
	T.eq(sy, 56, "below the top bar")
	T.eq(sh, 1125 - 56 - 8, "down to the bottom")
	local _, _, _, _, lmode = Mod.windowRect(1214, 420)
	T.eq(lmode, "sheet", "a very short screen gets a sheet too")
	for _, bad in ipairs({ 0 / 0, math.huge, -math.huge, "text", -50 }) do
		local a, b, c, d, m = Mod.windowRect(bad, bad)
		T.ok(a == a and b == b and c == c and d == d, "broken sizes give real numbers: " .. tostring(bad))
		T.ok(c > 0 and d > 0, "and a visible window")
		T.ok(m == "window" or m == "sheet", "and a mode")
	end
	local ix, iy, iw, ih, imode = Mod.windowRect(520, 1125, 78)
	T.eq(imode, "sheet", "a phone with the Roblox top bar")
	T.eq(iy, 86, "the sheet starts under the top bar")
	T.eq(ih, 1125 - 86 - 8, "and still reaches the bottom")
	T.eq(ix, 8, "same margin")
	local _, wy, _, wh = Mod.windowRect(1280, 640, 77)
	T.ok(wy >= 85, "a window stays under the top bar too: " .. wy)
	T.ok(wy + wh <= 640 - 8, "and on the screen: " .. (wy + wh))
	local _, cy = Mod.windowRect(520, 1125, 5000)
	T.ok(cy < 1125 * 0.3, "a silly inset is capped: " .. cy)
	local _, zy = Mod.windowRect(1365, 768, 0 / 0)
	T.eq(zy, math.floor((768 - 660) / 2), "a broken inset counts as none")
	local na, nb, nc, nd = Mod.windowRect(nil, nil)
	T.ok(nc > 0 and nd > 0 and na == na and nb == nb, "no sizes at all still gives a window")
	T.eq(Mod.columns(764), 3, "three columns on a wide window")
	T.eq(Mod.columns(468), 2, "two on a phone held upright")
	T.eq(Mod.columns(300), 1, "one on a tiny screen")
	T.eq(Mod.columns(0 / 0), 1, "one when the width is broken")
	T.eq(Mod.cellWidth(764, 3, 10), 248, "cards share the width")
	T.eq(Mod.cellWidth(468, 2, 10), 229, "two side by side")
	T.eq(Mod.cellWidth(10, 3, 10), 80, "never narrower than 80")
	T.eq(Mod.featuredColumns(764, 3), 3, "the spotlight side by side")
	T.eq(Mod.featuredColumns(764, 1), 1, "one person alone")
	T.eq(Mod.featuredColumns(468, 3), 2, "two on a phone")
	T.eq(Mod.featuredColumns(300, 3), 1, "one on a tiny screen")
	local labelW, used, cut = Mod.fitName(100, 300, 14)
	T.eq(labelW, 102, "a short name keeps its width")
	T.eq(used, 102 + 19, "and the badge sits after it")
	T.eq(cut, false, "nothing cut")
	labelW, used, cut = Mod.fitName(400, 200, 14)
	T.eq(labelW, 181, "a long name leaves room for the badge")
	T.eq(used, 200, "and fills the row")
	T.eq(cut, true, "it is cut")
	labelW = Mod.fitName(50, 200, nil)
	T.eq(labelW, 52, "no badge, no room kept")
	T.eq((Mod.fitName(0 / 0, 0 / 0, 14)), 0, "broken numbers give nothing")
	T.eq(Mod.heroHeight("window", 660), 112, "a tall header on a big window")
	T.eq(Mod.heroHeight("window", 550), 96, "a shorter one on a shorter window")
	T.eq(Mod.heroHeight("window", 456), 60, "and a slim one on a short window, so the cards get the room")
	T.eq(Mod.heroHeight("sheet", 1000), 96, "and on a phone held upright")
	local tall = Mod.chrome("window", 820, 660)
	T.eq(tall.compact, false, "a tall window keeps the big header")
	T.eq(tall.hero + tall.bar, 112 + 98)
	local short = Mod.chrome("window", 820, 497)
	T.eq(short.compact, true, "a phone on its side gets the slim header")
	T.eq(short.oneRow, true, "with the search and the chips on one line")
	T.eq(short.hero + short.bar, 60 + 52, "so the top takes 112 instead of 194")
	local narrow = Mod.chrome("sheet", 400, 430)
	T.eq(narrow.compact, true)
	T.eq(narrow.oneRow, false, "a narrow short screen puts the chips under the search")
	T.eq(narrow.bar, 86)
	T.eq(Mod.chrome("window", 0 / 0, 0 / 0).compact, true, "broken numbers still give a header")
	T.eq(Mod.searchWidth(820), 278, "the search takes about a third")
	T.eq(Mod.searchWidth(300), 200, "never under 200")
	T.eq(Mod.searchWidth(2000), 300, "never over 300")
	T.eq(Mod.wrapLines(100, 200), 1, "one line")
	T.eq(Mod.wrapLines(201, 200), 2, "two lines")
	T.eq(Mod.wrapLines(500, 0), 500, "a zero width does not divide by zero")
	local t1, s1 = Mod.thumbSpec("head")
	T.eq(t1, "HeadShot", "cards use the headshot")
	T.eq(s1, "Size100x100", "small")
	local t2, s2 = Mod.thumbSpec("bust")
	T.eq(t2, "AvatarBust", "pages use the bust")
	T.eq(s2, "Size150x150", "150")
	local t3, s3 = Mod.thumbSpec("big")
	T.eq(t3, "AvatarBust", "the tester's page uses the big bust")
	T.eq(s3, "Size420x420", "420")
end

T.section("credits_schema: pictures, handles, filters and the spotlight")
do
	T.eq(Mod.pictureKind("Hub/credits/atsuko.png"), "file", "a png in the package")
	T.eq(Mod.pictureKind("Hub/credits/me.JPG"), "file", "a jpg, any case")
	T.eq(Mod.pictureKind("Hub/credits/me.jpeg"), "file", "a jpeg")
	T.eq(Mod.pictureKind("Hub/credits/me.gif"), nil, "not a gif")
	T.eq(Mod.pictureKind("Hub/credits/sub/me.png"), nil, "no folders inside")
	T.eq(Mod.pictureKind("Hub/credits/../x.png"), nil, "no climbing out")
	T.eq(Mod.pictureKind("12345"), "asset", "a bare image id")
	T.eq(Mod.pictureKind("rbxassetid://12345"), "asset", "an rbxassetid")
	T.eq(Mod.pictureKind("rbxassetid://abc"), nil, "a broken rbxassetid")
	T.eq(Mod.pictureKind("https://example.com/a.png"), "web", "an https link")
	T.eq(Mod.pictureKind("https://example.com/a b.png"), nil, "a link with a space")
	T.eq(Mod.pictureKind("http://example.com/a.png"), nil, "plain http")
	T.eq(Mod.pictureKind(""), nil, "empty")
	T.eq(Mod.pictureKind(5), nil, "a number value")
	T.eq(Mod.sniff("\137PNG\r\n"), "png", "a png starts like this")
	T.eq(Mod.sniff("\255\216\255\224"), "jpg", "a jpg like this")
	T.eq(Mod.sniff("GIF89a"), nil, "anything else is not shown")
	T.eq(Mod.sniff(nil), nil, "nothing")
	T.eq(Mod.handleProblem("atsukohakari"), nil, "a plain handle")
	T.ok(Mod.handleProblem("a b") ~= nil, "a space")
	T.ok(Mod.handleProblem(string.rep("a", 33)) ~= nil, "too long")
	T.eq(Mod.handleText({ handle = "atsukohakari" }, nil), "@atsukohakari", "a handle from the file")
	T.eq(Mod.handleText({ handle = "atsukohakari" }, { username = "realname" }), "@realname", "a Roblox username wins")
	T.eq(Mod.handleText({ handle = "" }, {}), nil, "nothing to show")
	local clean = Mod.sanitize(data)
	local f = Mod.filters(clean)
	T.eq(f[1].title, "All", "All first")
	T.eq(f[1].count, #data.people, "with everyone")
	T.eq(#f, 8, "then the seven groups")
	T.eq(f[3].title, "Testers", "in the file's order")
	T.eq(f[3].count, 1, "with their counts")
	local spot = Mod.featured(clean)
	T.eq(#spot, 4, "four in the spotlight")
	T.eq(spot[1].id, "atsuko", "Atsuko first")
	T.eq(spot[2].id, "claude", "then Claude")
	T.eq(spot[3].id, "tester-11345577877", "then the tester")
	T.eq(Mod.stats(clean), #data.people .. " credited  ·  7 groups  ·  4 verified", "the numbers line")
	T.eq(#Mod.groups(clean, "", "Testers"), 1, "a group filter keeps one group")
	T.eq(Mod.groups(clean, "", "Testers")[1].title, "Testers", "the right one")
	T.eq(#Mod.groups(clean, "", "All"), 7, "All keeps them all")
	T.eq(#Mod.groups(clean, "tory", "Testers"), 0, "a search outside the group finds nothing")
	local verifiedOnly = 0
	for _, g in ipairs(Mod.groups(clean, "verified")) do
		verifiedOnly += #g.items
	end
	T.eq(verifiedOnly, 4, "searching verified finds the badges")
	T.eq(Mod.blurb({ description = "", did = "Did", why = "Why" }), "", "only the description is shown, old fields are not")
	T.eq(Mod.blurb({ description = "Desc", did = "Did" }), "Desc", "the description")
	T.eq(Mod.blurb({}), "", "nothing at all")
	T.eq(Mod.kindName({ kind = "assistant" }), "AI assistant", "kind names")
	T.eq(Mod.kindName({ kind = "wizard" }), "Credit", "an unknown kind")
	local real = find(clean.people, "atsuko")
	T.eq(real.verified, true, "the badge survives cleaning")
	T.eq(real.picture, "Hub/credits/atsuko.png", "and the picture")
	local messy = Mod.sanitize({ sections = { "A" }, people = {
		{ id = "p", name = "P", kind = "person", section = "A", roles = { "R" }, verified = "yes", picture = "C:/x.png", handle = "a b" },
		{ id = "roblox", name = "Roblox", kind = "service", section = "A", roles = { "R" } },
	} })
	T.eq(#messy.people, 1, "Roblox is dropped when the file is cleaned")
	T.eq(messy.people[1].verified, false, "only true is a badge")
	T.eq(messy.people[1].picture, "", "a bad picture is dropped")
	T.eq(messy.people[1].handle, "", "a bad handle is dropped")
end

T.section("credits_schema: the name cache")
do
	local text = Mod.cacheEncode({ ["11345577877"] = { username = "someone", display = "Some One" } }, { YeImTory = 55 }, jsonencode)
	T.ok(type(text) == "string", "it encodes")
	local back = Mod.cacheDecode(text, jsondecode)
	T.eq(back.names["11345577877"].username, "someone", "username comes back")
	T.eq(back.names["11345577877"].display, "Some One", "nickname comes back")
	T.eq(back.ids.YeImTory, 55, "ids come back")
	local junk = Mod.cacheDecode("not json", jsondecode)
	T.eq(next(junk.names), nil, "garbage gives nothing")
	local odd = Mod.cacheDecode(jsonencode({ names = { a = 5, b = { username = 3 }, c = { display = "ok" } }, ids = { x = "y", z = -1, w = 3 } }), jsondecode)
	T.eq(odd.names.a, nil, "a number is not a name")
	T.eq(odd.names.b, nil, "a number as a username is not kept")
	T.eq(odd.names.c.display, "ok", "a nickname alone is kept")
	T.eq(odd.ids.x, nil, "text is not an id")
	T.eq(odd.ids.z, nil, "a negative id is not kept")
	T.eq(odd.ids.w, 3, "a good id is kept")
	T.eq(Mod.displayName({ name = "Tester" }, nil), "Tester", "no names yet: the fallback")
	T.eq(Mod.displayName({ name = "Tester" }, { username = "u" }), "u", "only a username")
	T.eq(Mod.displayName({ name = "Tester" }, { username = "u", display = "D" }), "D", "the nickname wins")
	T.eq(Mod.displayName({ name = "Tester" }, { display = "" }), "Tester", "an empty nickname is ignored")
end
