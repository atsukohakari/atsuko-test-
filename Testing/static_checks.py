import json
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import check_no_comments as cnc

ROOT = os.path.dirname(HERE)
LIMIT_LINES = 26602
TEXT_EXT = (".lua", ".md", ".json", ".txt", ".py", ".patch")
EMOJI = re.compile("[%s-%s%s-%s%s]" % tuple(chr(code) for code in (0x1F300, 0x1FAFF, 0x2600, 0x27BF, 0xFE0F)))
FOUR = ["atsuko", "fdless", "gelatek", "uhhhhhh"]
TEXT_STARS = (chr(0x2605), chr(0x2606))


def read(rel):
    with open(os.path.join(ROOT, rel), "r", encoding="utf-8", errors="replace", newline="") as fh:
        return fh.read()


def files(extensions):
    for rel, _path in cnc.walk(ROOT, extensions):
        yield rel


def rule_emoji():
    hits = []
    for rel in files(TEXT_EXT):
        for number, line in enumerate(read(rel).split("\n"), 1):
            for star in TEXT_STARS:
                line = line.replace(star, "")
            if EMOJI.search(line):
                hits.append("%s:%d" % (rel, number))
    return hits


def filter_line(rel, line):
    return rel == "Hub/modules/credits_ui.lua" and line.startswith("Mod.FORBIDDEN = ")


def rule_miyu():
    hits = []
    for rel in files(TEXT_EXT):
        if rel.startswith("Testing/"):
            continue
        for number, line in enumerate(read(rel).split("\n"), 1):
            if filter_line(rel, line):
                continue
            if re.search("miyu", line, re.I) and "the miyu model and its settings were removed" not in line:
                hits.append("%s:%d" % (rel, number))
    return hits


def rule_old_version():
    hits = []
    for rel in files(TEXT_EXT):
        if rel.startswith("Testing/"):
            continue
        for number, line in enumerate(read(rel).split("\n"), 1):
            if "1.3.0" not in line:
                continue
            if rel == "Hub/changelog.txt" and line.strip() == "Beta v1.3.0":
                continue
            if rel == "Hub/AtsukoHub.lua" and line.startswith('\t{ version = "1.3.0"'):
                continue
            hits.append("%s:%d" % (rel, number))
    return hits


def rule_versions():
    wanted = read("Hub/version.txt").strip()
    hub = read("Hub/AtsukoHub.lua")
    found = re.search(r'^local HUB_VERSION = "([^"]+)"', hub, re.M)
    top = re.search(r'^Core\.CHANGELOG = \{\n\t\{ version = "([^"]+)"', hub, re.M)
    log = re.match(r"(?:Beta )?v(\S+)\n", read("Hub/changelog.txt"))
    seen = {
        "version.txt": wanted,
        "HUB_VERSION": found and found.group(1),
        "Core.CHANGELOG": top and top.group(1),
        "changelog.txt": log and log.group(1),
    }
    if len(set(seen.values())) == 1:
        return []
    return ["%s=%s" % (key, seen[key]) for key in sorted(seen)]


def rule_lines():
    count = read("Hub/AtsukoHub.lua").count("\n") + 1
    return [] if count < LIMIT_LINES else ["AtsukoHub.lua has %d lines" % count]


def rule_modules():
    hits = []
    for rel in files((".lua",)):
        if not rel.startswith("Hub/modules/"):
            continue
        lines = [line for line in read(rel).split("\n") if line.strip()]
        if not lines or not lines[-1].startswith("return "):
            hits.append(rel + " does not end with a return")
    return hits


def rule_manifest():
    hits = []
    try:
        data = json.loads(read("Scripts/manifest.json"))
    except Exception as exc:
        return ["Scripts/manifest.json: " + str(exc)]
    for path in data.get("scripts", {}):
        if not os.path.isfile(os.path.join(ROOT, path)):
            hits.append(path + " does not exist")
    return hits


def rule_providers():
    hits = []
    text = read("Reanimation/providers/registry.lua")
    found = re.search(r"Registry\.IDS = \{([^}]*)\}", text)
    ids = re.findall(r'"([a-z]+)"', found.group(1)) if found else []
    if ids != FOUR:
        hits.append("registry ids are %s" % ids)
    for rel in files(TEXT_EXT):
        if rel.startswith("Testing/"):
            continue
        body = read(rel)
        if re.search("uhhhhhh_hat|uhhhhhh_limb", body):
            hits.append(rel + " names uhhhhhh_hat or uhhhhhh_limb")
        if "Hats Reanimator" in body and rel != "Reanimation/Limb/Uhhhhhh.lua":
            hits.append(rel + " has the string Hats Reanimator")
    return hits


def rule_hidden_top():
    return [] if re.search(r"Core\.HIDDEN_TOP = \{[^}]*reanimation = true", read("Hub/AtsukoHub.lua")) else ["reanimation is missing"]


def rule_comments():
    counts = cnc.load_baseline(cnc.DEFAULT_BASELINE)
    total, failures, errors = cnc.check(ROOT, counts)
    return [line[:160] for line in errors + failures]


SCRIPT_DIRS = ("Scripts/", "Reanimation/")
SCRIPT_FILES = ("Hub/Reanimate.lua", "Hub/Emotes.lua")
BUTTON_NAMES = re.compile(r"TouchButtons|DubGunButtons|NeptunianButtons|HotlineButtons|SniperButtons|AddictButtons|CommanderButtons|TitanAlign|SkillLabels|KeyButtons|Crosshair|NEP\.alignGui|NEP\.padGui|LCGunAlign(?!\.json)")
PHONE_CONTROLS = ("MobileAttacks", "MobileFormChange", "MobileSongMute")


def shipped_scripts():
    for rel in files((".lua",)):
        if rel.startswith("Scripts/patches/") or rel.startswith("Reanimation/patches/") or rel.startswith("Testing/"):
            continue
        if rel.startswith(SCRIPT_DIRS) or rel in SCRIPT_FILES:
            yield rel


def rule_notices():
    hits = []
    for rel in files(TEXT_EXT):
        if rel.startswith("Testing/") or rel.startswith("Scripts/patches/") or rel.startswith("Reanimation/patches/") or rel == "Hub/modules/notify_router.lua":
            continue
        for number, line in enumerate(read(rel).split("\n"), 1):
            if "SendNotification" in line:
                hits.append("%s:%d" % (rel, number))
    return hits


def rule_buttons():
    hits = []
    for rel in shipped_scripts():
        for number, line in enumerate(read(rel).split("\n"), 1):
            found = BUTTON_NAMES.search(line)
            if found:
                hits.append("%s:%d has %s" % (rel, number, found.group(0)))
    return hits


def rule_leak():
    hits = []
    for rel in files(TEXT_EXT):
        if rel.startswith("Testing/") or rel.startswith("Scripts/patches/") or rel.startswith("Reanimation/patches/"):
            continue
        for number, line in enumerate(read(rel).split("\n"), 1):
            if filter_line(rel, line):
                continue
            if re.search("leaked by", line, re.I):
                hits.append("%s:%d" % (rel, number))
    return hits


def rule_last_star():
    body = read("Scripts/Hat/LastStar.lua")
    return [name + " is missing from Last Star" for name in PHONE_CONTROLS if name not in body]


def rule_patched_scripts():
    hits = []
    scripts = json.loads(read("Scripts/manifest.json")).get("scripts", {})
    main = set(path for path, item in scripts.items() if item.get("needsfd") is True)
    for rel in shipped_scripts():
        if rel not in main and not rel.startswith("Scripts/_unlisted/"):
            continue
        body = read(rel)
        if rel.endswith("LastStar.lua"):
            continue
        if "genv.AtsukoAlign = AL" not in body:
            hits.append(rel + " does not publish an alignment adapter")
        if "function C.toggleAlign" not in body and "function NEP.toggleAlign" not in body and "function M.toggleAlign" not in body:
            hits.append(rel + " has no toggleAlign that forwards to the hub")
    return hits


def rule_page_name():
    hits = []
    pattern = re.compile(r"atsuko\s+script", re.I)
    for rel in files(TEXT_EXT):
        if rel.startswith("Testing/") or rel.startswith("Scripts/patches/") or rel.startswith("Reanimation/patches/"):
            continue
        history = False
        for number, line in enumerate(read(rel).split("\n"), 1):
            if rel == "Hub/changelog.txt":
                if re.match(r"(Beta )?v\d", line) and not line.startswith("v" + read("Hub/version.txt").strip()):
                    history = True
                if history:
                    continue
            if rel == "Hub/AtsukoHub.lua":
                found = re.match(r'\t\{ version = "([0-9.]+)"', line)
                if found and found.group(1) != read("Hub/version.txt").strip():
                    continue
            if pattern.search(line):
                hits.append("%s:%d" % (rel, number))
    return hits


def rule_engine_hooks():
    hits = []
    text = read("Hub/AtsukoHub.lua")
    lines = text.split("\n")
    calls = [i for i, line in enumerate(lines) if re.search(r"\bX\.(hookmetamethod|hookfunction)\(", line)]
    if len(calls) != 1:
        hits.append("AtsukoHub.lua calls hookmetamethod or hookfunction in %d places, expected 1 (Core.installConnHook)" % len(calls))
    else:
        start = None
        for i in range(calls[0], -1, -1):
            if lines[i].startswith("function "):
                start = lines[i]
                break
        if start is None or not start.startswith("function Core.installConnHook"):
            hits.append("the engine hook in AtsukoHub.lua is not inside Core.installConnHook: %s" % start)
    body = text[text.index("function Core.installConnHook"):text.index("function Core.makeEnv")]
    for needle in ("Core.Boot.safe", 'Core.Boot.doing("hook:conn")', 'Core.Boot.done("hook:conn")'):
        if needle not in body:
            hits.append("Core.installConnHook is missing " + needle)
    for rel, key, label in (("Hub/modules/chathook.lua", "ChatHook.install", "chat"), ("Hub/modules/notify_router.lua", "Router.install", "notice")):
        if "hookmetamethod" not in read(rel):
            hits.append(rel + " no longer hooks, update this rule")
    for fn, label in (("function Core.setChatHook", "hook:chat"), ("function Core.setNoticeHook", "hook:notices")):
        at = text.find(fn)
        if at < 0:
            hits.append(fn + " is missing")
            continue
        chunk = text[at:at + 2600]
        for needle in ("Core.Boot.safe", 'Core.Boot.doing("%s")' % label, 'Core.Boot.done("%s")' % label):
            if needle not in chunk:
                hits.append("%s is missing %s" % (fn, needle))
    if text.count("NoticeMod.install") != 1:
        hits.append("NoticeMod.install appears %d times, expected 1 (inside Core.setNoticeHook)" % text.count("NoticeMod.install"))
    if "ChatHook.install" in text:
        hits.append("ChatHook.install is called straight from the hub, it must go through Core.setChatHook")
    return hits


def rule_boot_order():
    text = read("Hub/AtsukoHub.lua")
    hits = []
    boot = text.find("Core.Boot = {")
    first_use = text.find("Core.Boot.")
    if boot < 0 or first_use < boot:
        hits.append("Core.Boot has to be defined before its first use")
    for stage in ("settings", "commands", "gui", "bar", "repo", "ready"):
        if 'Core.Boot.mark("%s")' % stage not in text and 'B.mark("%s")' % stage not in text:
            hits.append("the boot note never marks the stage " + stage)
    if "Core.Boot.good()" not in text:
        hits.append("nothing ever marks the start as finished")
    if "Core.Boot.safe" not in text[text.index("function Core.autorun"):text.index("function Core.autorun") + 300]:
        hits.append("auto-run ignores safe mode")
    if text.find("Core.setChatHook(") < 0 or text.find("task.delay(3, function()\n\tif HUB.alive and not Core.Boot.safe and (S.hookChat or S.hookNotices)") < 0:
        hits.append("the opt-in hooks are not delayed until after the hub is up")
    return hits


def rule_script_art():
    hits = []
    text = read("Hub/AtsukoHub.lua")
    for needle in ("D.art.", "D.art ", "D.artLetter", "Logo.id or"):
        if needle in text:
            hits.append("the script detail pane still uses the hub logo: " + needle)
    if "Detail.art" not in text or "Core.attachScriptArt" not in text:
        hits.append("the script pictures are not attached to the detail pane")
    return hits


def rule_resizer():
    hits = []
    text = read("Hub/AtsukoHub.lua")
    mod = read("Hub/modules/resizer.lua")
    if "return Resizer" not in mod:
        hits.append("resizer.lua does not return Resizer")
    for needle in ("def.resizable", "pcall(attachResizer, w)", "if not w.resizer then", "self.resizer.destroy", "resizable = true", "step = RunService.RenderStepped"):
        if needle not in text:
            hits.append("the window system lost: " + needle)
    for needle in ("Drag.start", "ScrollingEnabled", "Resizer.compute", "env.step"):
        if needle not in mod:
            hits.append("resizer.lua lost: " + needle)
    for bad in ("UserInputService", "TweenService"):
        if bad in mod:
            hits.append("resizer.lua reaches for " + bad + " itself, it must use what the hub hands it")
    return hits


def rule_credits():
    hits = []
    import validate_credits
    data = json.loads(read("Hub/credits.json"))
    for line in validate_credits.validate(data):
        hits.append(line)
    for name in validate_credits.selftest(data):
        hits.append("validate_credits.py did not catch: " + name)
    text = read("Hub/AtsukoHub.lua")
    for gone in ("Core.CREDITS", "Core.creditRow"):
        if gone in text:
            hits.append("the old flat credits list is still in the hub: " + gone)
    for needle in ("function Core.buildCredits", "Core.loadModule(\"credits_ui\")", "Settings.onTab"):
        if needle not in text:
            hits.append("the hub does not load the credits page: " + needle)
    mod = read("Hub/modules/credits_ui.lua")
    if "return Mod" not in mod:
        hits.append("credits_ui.lua does not return Mod")
    return hits


def rule_colors():
    hits = []
    text = read("Hub/AtsukoHub.lua")
    mod = read("Hub/modules/settings_colors.lua")
    if "return Mod" not in mod:
        hits.append("settings_colors.lua does not return Mod")
    for needle in ("function Core.buildColors", 'Core.loadModule("settings_colors")', "function Core.rainbowSync", "function Core.renderControls", "rainbowBg = false,", "rainbowBgPeriod = 90,", "S.rainbowBg = def.rainbowBg == true", "Core.colorsHost = UI.new"):
        if needle not in text:
            hits.append("the hub lost: " + needle)
    for bad in ("GetService", "HttpGet", "loadstring", "game:"):
        if bad in mod:
            hits.append("settings_colors.lua reaches for " + bad + " itself, it must use what the hub hands it")
    for name, test in (("PERIOD_MIN", lambda n: n >= 30), ("PERIOD_MAX", lambda n: n <= 120), ("TICK", lambda n: n >= 0.2), ("THROTTLE", lambda n: n >= 0.05), ("MIN_CONTRAST", lambda n: n >= 4.5)):
        found = re.search(r"Mod\.%s = ([0-9.]+)" % name, mod)
        if not found:
            hits.append("settings_colors.lua lost Mod." + name)
        elif not test(float(found.group(1))):
            hits.append("Mod.%s = %s is outside what the rainbow and the picker promise" % (name, found.group(1)))
    return hits


def rule_cmd_packs():
    hits = []
    hub = read("Hub/AtsukoHub.lua")
    found = re.search(r"Core\.CMD_PACKS = \{([^}]*)\}", hub)
    names = re.findall(r'"([a-z_]+)"', found.group(1)) if found else []
    if not names:
        return ["Core.CMD_PACKS is missing"]
    on_disk = sorted(
        os.path.basename(rel)[:-4]
        for rel in files((".lua",))
        if rel.startswith("Hub/modules/cmds/") and not os.path.basename(rel).startswith("_")
    )
    for name in names:
        if name not in on_disk:
            hits.append("pack %s is listed but has no file" % name)
    for name in on_disk:
        if name not in names:
            hits.append("%s.lua is in cmds/ but not in Core.CMD_PACKS" % name)
    for helper in ("_kit", "_meta", "_targets"):
        if not os.path.exists(os.path.join(ROOT, "Hub/modules/cmds/%s.lua" % helper)):
            hits.append(helper + ".lua is missing")
    meta_ids = re.findall(r'id = "([a-z0-9]+)"', read("Hub/modules/cmds/_meta.lua"))
    catalogue = [line for line in read("Testing/catalogue_ids.txt").split("\n") if line]
    pending = [line.split()[0] for line in read("Testing/catalogue_pending.txt").split("\n") if line]
    if len(set(meta_ids)) != len(meta_ids):
        hits.append("_meta.lua lists an id twice")
    for cid in meta_ids:
        if cid not in catalogue:
            hits.append("_meta.lua has %s, which is not in the catalogue" % cid)
    for cid in pending:
        if cid not in meta_ids:
            hits.append("%s is pending but has no row in _meta.lua" % cid)
    if len(catalogue) != 288:
        hits.append("the catalogue has %d ids, not 288" % len(catalogue))
    forbidden = ("hookmetamethod", "hookfunction", "getrawmetatable", "setreadonly", "newcclosure", "checkcaller", "while true do", "getconnections", "debug.setupvalue")
    for name in on_disk:
        text = read("Hub/modules/cmds/%s.lua" % name)
        for bad in forbidden:
            if bad in text:
                hits.append("%s.lua uses %s, command packs may not hook or loop forever" % (name, bad))
        allowed = 1 if name == "automation" else 0
        if text.replace("pcall(Cmd.add", "").count("Cmd.add(") != allowed:
            hits.append("%s.lua adds commands without going through kit.define" % name)
        if not re.search(r"^return Pack$", text, re.M):
            hits.append("%s.lua does not return Pack" % name)
    for needle in ("function Core.loadCmdPacks", "Core.Boot.doing(\"pack:\" .. name)", "S.skipPacks[name] == true", "if Core.Boot.safe then", "task.delay(2.2", "function Cmd.remove"):
        if needle not in hub:
            hits.append("the hub lost: " + needle)
    return hits


def rule_removed_chat():
    hits = []
    for rel in files((".lua",)):
        if not rel.startswith("Hub/"):
            continue
        for number, line in enumerate(read(rel).split("\n"), 1):
            for bad in ("Chat.BAD", "Chat.filter", "chatFilter", "Hide bad words"):
                if bad in line:
                    hits.append("%s:%d %s" % (rel, number, bad))
    return hits


RULES = [
    ("no emoji in any file", rule_emoji),
    ("miyu appears only in the removal line and in the credits page word filter", rule_miyu),
    ("1.3.0 appears only in history", rule_old_version),
    ("version.txt, HUB_VERSION and both changelogs agree", rule_versions),
    ("AtsukoHub.lua is under %d lines" % LIMIT_LINES, rule_lines),
    ("every module file ends with a return", rule_modules),
    ("Scripts/manifest.json is valid and every path exists", rule_manifest),
    ("the registry has exactly the four providers", rule_providers),
    ("Core.HIDDEN_TOP hides reanimation", rule_hidden_top),
    ("no new comments (check_no_comments)", rule_comments),
    ("SendNotification appears only in Hub/modules/notify_router.lua", rule_notices),
    ("no touch-button pad, crosshair or in-script align panel in a shipped script", rule_buttons),
    ("no 'leaked by' text anywhere except the credits page word filter", rule_leak),
    ("Last Star keeps its three phone controls", rule_last_star),
    ("every patched Main Script publishes an alignment adapter", rule_patched_scripts),
    ("the page is called Main Scripts everywhere a player can read it (older changelog entries keep the old name)", rule_page_name),
    ("the engine is hooked only inside Core.installConnHook and the two opt-in hook functions, each journaled and safe-mode aware", rule_engine_hooks),
    ("the boot note exists before it is used, marks every stage, is finished by Core.Boot.good, and auto-run and the opt-in hooks respect it", rule_boot_order),
    ("the script detail pane uses no hub logo and has the picture view attached", rule_script_art),
    ("windows get the eight resize handles only when they ask for them, with the corner button as the fallback, and the module takes its tools from the hub", rule_resizer),
    ("credits.json validates, the validator catches its test mutations, and the hub loads the credits page from credits_ui", rule_credits),
    ("the color picker module is wired in, stays slow and soft, and takes its tools from the hub", rule_colors),
    ("command packs: files and Core.CMD_PACKS agree, the catalogue is accounted for, nothing hooks the engine, and the loader is journaled and skips in safe mode", rule_cmd_packs),
    ("the chat word filter and its settings are gone", rule_removed_chat),
]

LATER = [
    "AI rules (phase 10a)",
]


def main():
    failed = 0
    for title, rule in RULES:
        try:
            hits = rule()
        except Exception as exc:
            hits = ["the check itself broke: %s" % exc]
        if hits:
            failed += 1
            print("FAIL  " + title)
            for line in hits[:12]:
                print("        " + line)
            if len(hits) > 12:
                print("        and %d more" % (len(hits) - 12))
        else:
            print("pass  " + title)
    for title in LATER:
        print("later " + title)
    print("static checks: %d of %d failed, %d not checkable yet" % (failed, len(RULES), len(LATER)))
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
