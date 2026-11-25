import json
import os
import re
import sys

KINDS = ("person", "team", "project", "service", "assistant")
STYLES = ("full", "roblox")
LINK_KEYS = ("github", "discord", "youtube", "website", "roblox")
TESTER_ID = "tester-11345577877"
TESTER_USER_ID = 11345577877
TESTER_SENTENCE = "Just a tester lol, he's a cool guy :3"
ID_PATTERN = re.compile(r"^[a-z0-9][a-z0-9-]*$")
NAME_PATTERN = re.compile(r"^[A-Za-z0-9_]{3,20}$")
FORBIDDEN = ("miyu", "onerui", "leaked by")
NOT_CREDITED = ("roblox",)
MAX_LINE = 400
PICTURE_FILE = re.compile(r"^Hub/credits/[A-Za-z0-9_-]+\.(png|jpg|jpeg|PNG|JPG|JPEG)$")
HANDLE_PATTERN = re.compile(r"^[A-Za-z0-9_.-]{2,32}$")


def picture_ok(value):
    value = value.strip()
    if re.match(r"^[0-9]+$", value) or re.match(r"^rbxassetid://[0-9]+$", value) or value.startswith("rbxthumb://"):
        return True
    if value.startswith("https://") and " " not in value:
        return True
    return bool(PICTURE_FILE.match(value))


def is_text(value):
    return isinstance(value, str)


def printable(text):
    return all(32 <= ord(ch) < 127 for ch in text)


def check_link(problems, where, key, value):
    if value == "":
        return
    if not is_text(value):
        problems.append(where + ": links." + key + " is not text")
        return
    if not value.startswith("https://"):
        problems.append(where + ": links." + key + " does not start with https://")
        return
    if " " in value:
        problems.append(where + ": links." + key + " has a space")
    if "?si=" in value:
        problems.append(where + ": links." + key + " carries a tracking tail (?si=)")
    if key == "roblox" and not value.startswith("https://www.roblox.com/"):
        problems.append(where + ": links.roblox does not start with https://www.roblox.com/")
    if key == "discord" and not (value.startswith("https://discord.gg/") or value.startswith("https://discord.com/invite/")):
        problems.append(where + ": links.discord is not a discord invite")
    if key == "github" and not value.startswith("https://github.com/"):
        problems.append(where + ": links.github is not on github.com")
    if key == "youtube" and not (value.startswith("https://youtube.com/") or value.startswith("https://www.youtube.com/")):
        problems.append(where + ": links.youtube is not on youtube.com")


def check_entry(problems, entry, index, sections):
    if not isinstance(entry, dict):
        problems.append("people[%d] is not an object" % index)
        return None
    pid = entry.get("id")
    where = "people[%d]" % index
    if is_text(pid) and pid != "":
        where = pid
    if not is_text(pid) or not ID_PATTERN.match(pid or ""):
        problems.append(where + ": id is missing or not lowercase letters, digits and dashes")
    name = entry.get("name")
    if not is_text(name) or name.strip() == "":
        problems.append(where + ": name is missing")
    if pid in NOT_CREDITED or (is_text(name) and name.strip().lower() in NOT_CREDITED):
        problems.append(where + ": the owner asked for this one not to be credited")
    verified = entry.get("verified", False)
    if not isinstance(verified, bool):
        problems.append(where + ": verified must be true or false")
    picture = entry.get("picture", "")
    if picture != "" and (not is_text(picture) or not picture_ok(picture)):
        problems.append(where + ": picture must be a Roblox image id, an https link or a .png or .jpg file in Hub/credits/")
    handle = entry.get("handle", "")
    if handle != "" and (not is_text(handle) or not HANDLE_PATTERN.match(handle)):
        problems.append(where + ": handle may only use letters, digits, _ . and - (2 to 32 of them)")
    if entry.get("kind") not in KINDS:
        problems.append(where + ": kind must be one of " + ", ".join(KINDS))
    style = entry.get("profileStyle", "full")
    if style not in STYLES:
        problems.append(where + ": profileStyle must be full or roblox")
    if entry.get("section") not in sections:
        problems.append(where + ": section is not one of the listed sections")
    roles = entry.get("roles")
    if not isinstance(roles, list) or len(roles) == 0 or not all(is_text(r) and r.strip() != "" for r in roles):
        problems.append(where + ": roles needs at least one text")
    used = entry.get("usedIn", [])
    if not isinstance(used, list) or not all(is_text(u) for u in used):
        problems.append(where + ": usedIn must be a list of text")
    source = entry.get("source")
    if not is_text(source) or source.strip() == "":
        problems.append(where + ": source is empty, say where the facts came from")
    links = entry.get("links", {})
    if not isinstance(links, dict):
        problems.append(where + ": links is not an object")
        links = {}
    for key in LINK_KEYS:
        check_link(problems, where, key, links.get(key, ""))
    other = links.get("other", [])
    if not isinstance(other, list):
        problems.append(where + ": links.other is not a list")
        other = []
    for item in other:
        if not is_text(item) or not item.startswith("https://") or " " in item:
            problems.append(where + ": links.other has an address that is not https://")
    rb = entry.get("roblox", {})
    if not isinstance(rb, dict):
        problems.append(where + ": roblox is not an object")
        rb = {}
    username = rb.get("username", "")
    user_id = rb.get("userId")
    if username != "" and (not is_text(username) or not NAME_PATTERN.match(username)):
        problems.append(where + ": roblox.username is not a valid username")
    if user_id is not None and (isinstance(user_id, bool) or not isinstance(user_id, int) or user_id <= 0):
        problems.append(where + ": roblox.userId must be a positive whole number or null")
    desc = entry.get("description")
    if not is_text(desc) or desc.strip() == "":
        if style == "roblox":
            problems.append(where + ": a roblox profile needs a description")
        else:
            problems.append(where + ": description is missing")
    if style == "roblox":
        if (username == "" or username is None) and user_id is None:
            problems.append(where + ": a roblox profile needs roblox.userId or roblox.username")
    for key in ("why", "did"):
        if key in entry:
            problems.append(where + ": " + key + " is not used anymore, put it in the description")
    if pid == TESTER_ID:
        if entry.get("description") != TESTER_SENTENCE:
            problems.append(where + ": the description is not the owner's sentence, byte for byte")
        if rb.get("userId") != TESTER_USER_ID:
            problems.append(where + ": roblox.userId is not 11345577877")
        if username != "":
            problems.append(where + ": the username must stay empty, it is read from Roblox at run time")
        if links.get("roblox") != "https://www.roblox.com/users/%d/profile" % TESTER_USER_ID:
            problems.append(where + ": links.roblox is not the profile address the owner gave")
        if entry.get("profileStyle") != "roblox":
            problems.append(where + ": the tester uses the roblox profile style")
    for key in ("name", "description", "license", "source"):
        value = entry.get(key, "")
        if value != "" and is_text(value):
            if not printable(value):
                problems.append(where + ": " + key + " has characters outside plain text")
            if len(value) > MAX_LINE:
                problems.append(where + ": " + key + " is longer than %d characters" % MAX_LINE)
            low = value.lower()
            for word in FORBIDDEN:
                if word in low:
                    problems.append(where + ": " + key + " mentions " + word)
    return pid


def validate(data):
    problems = []
    if not isinstance(data, dict):
        return ["the file is not an object"]
    if data.get("version") != 1:
        problems.append("version must be 1")
    sections = data.get("sections")
    if not isinstance(sections, list) or len(sections) == 0 or not all(is_text(s) and s != "" for s in sections):
        problems.append("sections must be a list of text")
        sections = []
    people = data.get("people")
    if not isinstance(people, list) or len(people) == 0:
        problems.append("people must be a list with entries")
        return problems
    seen = {}
    for index, entry in enumerate(people):
        pid = check_entry(problems, entry, index, sections)
        if pid is not None:
            if pid in seen:
                problems.append(str(pid) + ": the id is used twice")
            seen[pid] = True
    for section in sections:
        if not any(isinstance(p, dict) and p.get("section") == section for p in people):
            problems.append("section '" + section + "' has nobody in it")
    for required in ("atsuko", "claude", TESTER_ID, "tory"):
        if required not in seen:
            problems.append("the entry " + required + " is missing")
    return problems


def selftest(data):
    import copy

    def person(d, pid):
        for entry in d["people"]:
            if entry["id"] == pid:
                return entry
        raise KeyError(pid)

    cases = [
        ("tory with why", lambda d: person(d, "tory").update(why="old text"), "why is not used anymore"),
        ("tory with did", lambda d: person(d, "tory").update(did=""), "did is not used anymore"),
        ("tester no description", lambda d: person(d, TESTER_ID).update(description=""), "needs a description"),
        ("tester no account", lambda d: person(d, TESTER_ID).update(roblox={"username": "", "userId": None}), "needs roblox.userId or roblox.username"),
        ("tester sentence altered", lambda d: person(d, TESTER_ID).update(description=TESTER_SENTENCE + " "), "owner's sentence"),
        ("tester roblox link off site", lambda d: person(d, TESTER_ID)["links"].update(roblox="https://example.com/x"), "links.roblox"),
        ("tester guessed username", lambda d: person(d, TESTER_ID)["roblox"].update(username="Somebody"), "username must stay empty"),
        ("plain http", lambda d: person(d, "tory")["links"].update(discord="http://discord.gg/a"), "links.discord"),
        ("not an invite", lambda d: person(d, "tory")["links"].update(discord="https://example.com/a"), "not a discord invite"),
        ("tracking tail", lambda d: person(d, "tory")["links"].update(youtube="https://youtube.com/@x?si=a"), "tracking tail"),
        ("space in link", lambda d: person(d, "tory")["links"].update(website="https://a b.com"), "has a space"),
        ("other not https", lambda d: person(d, "tory")["links"].update(other=["ftp://x.com"]), "links.other"),
        ("negative id", lambda d: person(d, "tory")["roblox"].update(userId=-4), "positive whole number"),
        ("bad username", lambda d: person(d, "tory")["roblox"].update(username="ab"), "valid username"),
        ("unknown kind", lambda d: person(d, "tory").update(kind="wizard"), "kind must be"),
        ("unknown style", lambda d: person(d, "tory").update(profileStyle="fancy"), "profileStyle"),
        ("unknown section", lambda d: person(d, "tory").update(section="Nowhere"), "section is not one"),
        ("no roles", lambda d: person(d, "tory").update(roles=[]), "roles needs"),
        ("no source", lambda d: person(d, "tory").update(source=""), "source is empty"),
        ("bad id", lambda d: person(d, "tory").update(id="Tory Two"), "id is missing"),
        ("non-ascii", lambda d: person(d, "tory").update(description="caf\u00e9"), "outside plain text"),
        ("miyu", lambda d: person(d, "tory").update(description="Thanks to Miyu"), "mentions miyu"),
        ("repeated id", lambda d: d["people"][1].update(id="atsuko"), "used twice"),
        ("version", lambda d: d.update(version=2), "version must be 1"),
        ("empty section", lambda d: d["sections"].append("Empty one"), "has nobody in it"),
        ("claude removed", lambda d: d["people"].pop(1), "claude is missing"),
        ("tory no description", lambda d: person(d, "tory").update(description=""), "description is missing"),
        ("verified as text", lambda d: person(d, "tory").update(verified="yes"), "verified must be"),
        ("picture outside Hub/credits", lambda d: person(d, "tory").update(picture="Hub/logo.png"), "picture must be"),
        ("picture over http", lambda d: person(d, "tory").update(picture="http://example.com/a.png"), "picture must be"),
        ("picture climbing out", lambda d: person(d, "tory").update(picture="Hub/credits/../AtsukoHub.lua"), "picture must be"),
        ("handle with a space", lambda d: person(d, "tory").update(handle="two words"), "handle may only"),
        ("roblox credited", lambda d: d["people"].append(dict(person(d, "tory"), id="roblox", name="Roblox")), "not to be credited"),
    ]
    missed = []
    for name, change, needle in cases:
        copy_of = copy.deepcopy(data)
        change(copy_of)
        found = validate(copy_of)
        if not any(needle in line for line in found):
            missed.append(name)
    return missed


def main(argv):
    args = [a for a in argv[1:] if not a.startswith("--")]
    root = args[0] if args else os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
    path = os.path.join(root, "Hub", "credits.json")
    try:
        with open(path, "r", encoding="utf-8") as handle:
            data = json.load(handle)
    except Exception as error:
        print("credits: could not read Hub/credits.json: " + str(error))
        return 1
    problems = validate(data)
    if "--selftest" in argv:
        for name in selftest(data):
            problems.append("the validator did not catch: " + name)
    for problem in problems:
        print("credits: " + problem)
    if problems:
        print("credits: %d problem(s)" % len(problems))
        return 1
    print("credits: ok, %d entries" % len(data["people"]))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
