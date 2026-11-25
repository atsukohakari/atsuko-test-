import json
import math
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import luau

IDENT = ((1.0, 0.0, 0.0), (0.0, 1.0, 0.0), (0.0, 0.0, 1.0))
ZERO3 = (0.0, 0.0, 0.0)
KEY_ORDER = ("slot", "part", "key", "hat", "mesh", "tex", "acc", "name", "words", "align", "note")
SCRIPT_ORDER = (
    "Dubstep Gun",
    "The Hotline",
    "The Sniper",
    "Neptunian V",
    "Neptunian V Gun",
    "Last Star",
    "Snake Banisher V3",
    "Studio Dummy V4",
    "Gelatek",
)


HELP = (
    "Every row is one hat. Match it with hat (the catalog id), mesh and tex (the ids on its handle), name or words.",
    "align = {x, y, z, rx, ry, rz}: studs, then degrees. Leave it out and the script fits the hat by itself.",
    "rig rows turn a hat into a body part: part is Head, Torso, Left Arm, Right Arm, Left Leg or Right Leg. The first row that matches a hat wins.",
    "scripts rows belong to one script, and slot says which job the hat does there. Add your own rows at the end of a list.",
    "Rows you add in the hub are kept on your device in AtsukoHub/alignment_user.lua and win over these.",
    "More in Alignment/README.md.",
)

SLOTS = {
    "Dubstep Gun": (
        ("gun", "gun hats, lined up with the gun in your hand"),
        ("aura", "aura hats, lined up with the blast"),
        ("bullet", "the hat that flies as the shot"),
        ("extra", "catalog hats the script fits into your hand by itself"),
    ),
    "The Hotline": (
        ("gun", "the gun hat, found by catalog id, mesh id or the words in its name"),
        ("bullet", "the hat used as the bullet, it hides under the floor until you shoot"),
    ),
    "The Sniper": (
        ("gun", "the sniper hats, it holds the first one you wear"),
        ("bullet", "the hat used as the bullet, it hides under the floor until you shoot"),
    ),
    "Neptunian V": (
        ("sword", "the sword in your hand"),
        ("swordback", "the sword on your back"),
        ("base", "how the hat sits in the hand before sword is applied, rotation only"),
    ),
    "Neptunian V Gun": (
        ("sword", "sword hats for the right hand"),
        ("gun", "gun hats for the left hand"),
        ("slash", "the blade that flies out when you press C"),
        ("bullet", "the hat used as the bullet, it hides under the floor until you shoot"),
    ),
    "Last Star": (
        ("give", "catalog ids the game's -gh command is asked for"),
        ("wing1", "the sword that follows wing 1, found by tex. align is where it sits on the wing"),
        ("wing2", "the sword that follows wing 2"),
        ("wing3", "the sword that follows wing 3"),
        ("wing4", "the sword that follows wing 4"),
        ("wing5", "the sword that follows wing 5"),
        ("wing6", "the sword that follows wing 6"),
        ("backup", "a sword mesh that takes an empty wing when a texture is missing"),
    ),
    "Snake Banisher V3": (
        ("gun1", "LC Gun 1 hats, held in the right hand"),
        ("gun2", "LC Gun 2 hats, held in the right hand"),
        ("muzzle", "where the shot starts"),
    ),
    "Studio Dummy V4": (
        ("gun", "gun hats by mesh id"),
        ("gunitem", "gun hats by catalog id, the script looks the mesh up"),
        ("gunwords", "a hat whose name has one of these words is a gun"),
        ("screen", "the screen hat by mesh id"),
        ("screenwords", "words in the name of the screen hat"),
        ("screen2words", "words in the name of the second screen hat"),
        ("head", "the dummy head hat by mesh id"),
        ("headwords", "words in the name of the head hat"),
        ("bullet", "the bullet hat by mesh id"),
        ("bulletwords", "words in the name of the bullet hat"),
        ("grip", "where a gun sits in the hand"),
        ("muzzle", "where a gun shoots from"),
        ("fix", "an extra turn for guns that sit wrong"),
        ("tip", "the end of the barrel"),
    ),
    "Gelatek": (("bullet", "Bullet mode on R6: the hat lined up with the Left Arm"),),
}


class EvalError(Exception):
    pass


class Tab(object):
    def __init__(self):
        self.arr = []
        self.map = {}
        self.lines = []

    def get(self, key, default=None):
        return self.map.get(key, default)


def mm(a, b):
    return tuple(tuple(sum(a[i][k] * b[k][j] for k in range(3)) for j in range(3)) for i in range(3))


def mv(a, v):
    return tuple(sum(a[i][k] * v[k] for k in range(3)) for i in range(3))


def rot_x(a):
    c, s = math.cos(a), math.sin(a)
    return ((1.0, 0.0, 0.0), (0.0, c, -s), (0.0, s, c))


def rot_y(a):
    c, s = math.cos(a), math.sin(a)
    return ((c, 0.0, s), (0.0, 1.0, 0.0), (-s, 0.0, c))


def rot_z(a):
    c, s = math.cos(a), math.sin(a)
    return ((c, -s, 0.0), (s, c, 0.0), (0.0, 0.0, 1.0))


def euler_matrix(a, b, c):
    return mm(mm(rot_x(a), rot_y(b)), rot_z(c))


def euler_from(r):
    sb = max(-1.0, min(1.0, r[0][2]))
    b = math.asin(sb)
    if abs(sb) < 0.9999999:
        a = math.atan2(-r[1][2], r[2][2])
        c = math.atan2(-r[0][1], r[0][0])
    else:
        c = 0.0
        if sb > 0:
            a = math.atan2(r[1][0], r[1][1])
        else:
            a = math.atan2(-r[1][0], r[1][1])
    return a, b, c


class CF(object):
    def __init__(self, p, r, pr=None):
        self.p = tuple(float(x) for x in p)
        self.r = r
        self.pr = pr

    def __mul__(self, other):
        if not isinstance(other, CF):
            raise EvalError("cframe times something else")
        r = mm(self.r, other.r)
        rp = mv(self.r, other.p)
        p = tuple(self.p[i] + rp[i] for i in range(3))
        pr = None
        if self.pr and other.pr and self.pr[1] == ZERO3:
            pr = (tuple(self.pr[0][i] + other.pr[0][i] for i in range(3)), other.pr[1])
        return CF(p, r, pr)


def cframe_new(*a):
    a = [float(x) for x in a]
    if len(a) == 0:
        return CF(ZERO3, IDENT, (ZERO3, ZERO3))
    if len(a) == 3:
        return CF(a, IDENT, (tuple(a), ZERO3))
    if len(a) == 12:
        r = ((a[3], a[4], a[5]), (a[6], a[7], a[8]), (a[9], a[10], a[11]))
        return CF(a[:3], r, None)
    raise EvalError("CFrame.new with %d arguments" % len(a))


def cframe_angles(a=0.0, b=0.0, c=0.0):
    a, b, c = float(a), float(b), float(c)
    return CF(ZERO3, euler_matrix(a, b, c), (ZERO3, (a, b, c)))


def vec3(*a):
    return tuple(float(x) for x in a)


def clean(v, digits, snap):
    v = round(v, digits)
    if abs(v) < snap:
        v = 0.0
    return v + 0.0


def to_align(cf):
    if cf.pr:
        pos, ang = cf.pr
    else:
        pos, ang = cf.p, euler_from(cf.r)
    out = [clean(x, 5, 1e-4) for x in pos]
    out += [clean(math.degrees(x), 4, 5e-4) for x in ang]
    return out


def from_align(a):
    a = list(a) + [0.0] * (6 - len(a))
    return cframe_new(a[0], a[1], a[2]) * cframe_angles(math.radians(a[3]), math.radians(a[4]), math.radians(a[5]))


def cf_close(a, b, pos_tol=3e-4, rot_tol=2e-5):
    if any(abs(a.p[i] - b.p[i]) > pos_tol for i in range(3)):
        return False
    return all(abs(a.r[i][j] - b.r[i][j]) <= rot_tol for i in range(3) for j in range(3))


def base_env():
    cframe = {
        "new": cframe_new,
        "Angles": cframe_angles,
        "fromEulerAnglesXYZ": cframe_angles,
        "fromEulerAngles": cframe_angles,
        "identity": cframe_new(),
    }
    env = {
        "CFrame": cframe,
        "math": {
            "rad": math.radians,
            "deg": math.degrees,
            "pi": math.pi,
            "sin": math.sin,
            "cos": math.cos,
            "abs": abs,
            "sqrt": math.sqrt,
        },
        "Vector3": {"new": vec3},
        "table": {"freeze": lambda t: t},
        "cf": cframe_new,
        "CF": cframe_new,
        "CFn": cframe_new,
        "cn": cframe_new,
        "angles": cframe_angles,
        "ANG": cframe_angles,
        "cfMul": lambda a, b: a * b,
        "v3": vec3,
        "V3": vec3,
        "VT": vec3,
        "IDENT": cframe_new(),
        "ID": cframe_new(),
        "PI": math.pi,
        "HPI": math.pi / 2,
    }
    return env


def decode_str(raw):
    if raw.startswith("["):
        m = re.match(r"\[(=*)\[(.*)\]\1\]$", raw, re.S)
        body = m.group(2)
        if body.startswith("\n"):
            body = body[1:]
        return body
    body = raw[1:-1]
    table = {"n": "\n", "t": "\t", "r": "\r"}
    return re.sub(r"\\(.)", lambda m: table.get(m.group(1), m.group(1)), body)


class Parser(object):
    def __init__(self, toks, i, env, lenient=False):
        self.t = toks
        self.i = i
        self.env = env
        self.lenient = lenient

    def peek(self, k=0):
        return self.t[min(self.i + k, len(self.t) - 1)]

    def next(self):
        tok = self.t[self.i]
        self.i += 1
        return tok

    def at(self, v, k=0):
        tok = self.peek(k)
        return tok.k == "op" and tok.v == v

    def expect(self, v):
        if not self.at(v):
            raise EvalError("expected %s at line %d, got %r" % (v, self.peek().line, self.peek().v))
        self.i += 1

    def expr(self):
        v = self.mul()
        while self.peek().k == "op" and self.peek().v in ("+", "-"):
            op = self.next().v
            w = self.mul()
            v = v + w if op == "+" else v - w
        return v

    def mul(self):
        v = self.unary()
        while self.peek().k == "op" and self.peek().v in ("*", "/"):
            op = self.next().v
            w = self.unary()
            v = v * w if op == "*" else v / w
        return v

    def unary(self):
        if self.at("-"):
            self.i += 1
            return -self.unary()
        return self.postfix()

    def postfix(self):
        v = self.atom()
        while True:
            if self.at("."):
                self.i += 1
                name = self.next().v
                if isinstance(v, dict) and name in v:
                    v = v[name]
                else:
                    raise EvalError("no field %s at line %d" % (name, self.peek().line))
            elif self.at("("):
                self.i += 1
                args = []
                while not self.at(")"):
                    args.append(self.expr())
                    if self.at(","):
                        self.i += 1
                self.expect(")")
                if not callable(v):
                    raise EvalError("call of a non function at line %d" % self.peek().line)
                v = v(*args)
            else:
                return v

    def atom(self):
        tok = self.peek()
        if tok.k == "num":
            self.i += 1
            return float(tok.v.replace("_", ""))
        if tok.k == "str":
            self.i += 1
            return decode_str(tok.v)
        if tok.k == "kw" and tok.v in ("true", "false", "nil"):
            self.i += 1
            return {"true": True, "false": False, "nil": None}[tok.v]
        if tok.k == "name":
            self.i += 1
            if tok.v not in self.env:
                raise EvalError("unknown name %s at line %d" % (tok.v, tok.line))
            return self.env[tok.v]
        if self.at("{"):
            return self.table()
        if self.at("("):
            self.i += 1
            v = self.expr()
            self.expect(")")
            return v
        raise EvalError("cannot read %r at line %d" % (tok.v, tok.line))

    def skip_value(self):
        depth = 0
        while True:
            tok = self.peek()
            if tok.k == "eof":
                return
            if tok.k == "op":
                if tok.v in ("{", "(", "["):
                    depth += 1
                elif tok.v in ("}", ")", "]"):
                    if depth == 0:
                        return
                    depth -= 1
                elif tok.v in (",", ";") and depth == 0:
                    return
            self.i += 1

    def value(self):
        if not self.lenient:
            return self.expr()
        start = self.i
        try:
            return self.expr()
        except (EvalError, TypeError, ZeroDivisionError):
            self.i = start
            self.skip_value()
            return None

    def table(self):
        self.expect("{")
        t = Tab()
        while not self.at("}"):
            line = self.peek().line
            if self.at("["):
                self.i += 1
                key = self.expr()
                self.expect("]")
                self.expect("=")
                t.map[key] = self.value()
            elif self.peek().k == "name" and self.at("=", 1):
                key = self.next().v
                self.i += 1
                t.map[key] = self.value()
            else:
                t.arr.append(self.value())
                t.lines.append(line)
            if self.at(",") or self.at(";"):
                self.i += 1
        self.expect("}")
        return t


class Source(object):
    def __init__(self, path):
        self.path = path
        with open(path, "r", encoding="utf-8", errors="replace") as fh:
            self.text = fh.read()
        self.comments = []
        self.toks = luau.lex(self.text, 1, comments=self.comments)

    def find(self, name, mode="direct", nth=0):
        toks = self.toks
        seen = 0
        for i in range(len(toks) - 2):
            if toks[i].k == "name" and toks[i].v == name and toks[i + 1].k == "op" and toks[i + 1].v == "=":
                j = i + 2
                if mode == "return":
                    while j < len(toks) - 1 and not (
                        toks[j].k == "kw" and toks[j].v == "return" and toks[j + 1].k == "op" and toks[j + 1].v == "{"
                    ):
                        j += 1
                    j += 1
                else:
                    while j < len(toks) and not (toks[j].k == "op" and toks[j].v == "{"):
                        if toks[j].k == "op" and toks[j].v in ("(", ".") or toks[j].k == "name":
                            j += 1
                        else:
                            break
                if j < len(toks) and toks[j].k == "op" and toks[j].v == "{":
                    if seen == nth:
                        return j
                    seen += 1
        raise EvalError("%s: table %s not found" % (os.path.basename(self.path), name))

    def table(self, name, env=None, mode="direct", nth=0, lenient=False):
        i = self.find(name, mode, nth)
        return Parser(self.toks, i, env or base_env(), lenient).table()

    def runs(self):
        out = []
        last = None
        for line, kind, text in self.comments:
            if kind != "line":
                last = None
                continue
            clean_text = re.sub(r"^-+\s*", "", text).strip()
            if last is not None and last[1] == line - 1:
                last[1] = line
            else:
                last = [line, line, clean_text]
                out.append(last)
        return out


def ids(value):
    return None if value in (None, "") else str(value)


def row(**kw):
    return {k: kw[k] for k in KEY_ORDER if k in kw and kw[k] is not None}


def rig_rows(path):
    src = Source(path)
    tab = src.table("aligns")
    runs = src.runs()
    out = []
    for item, line in zip(tab.arr, tab.lines):
        note = None
        for start, end, text in runs:
            if end < line:
                note = text
        c0 = item.get("C0")
        out.append(
            row(
                part=item.get("PartName"),
                mesh=ids(item.get("meshid")),
                tex=ids(item.get("textureid")),
                acc=item.get("AccessoryName"),
                align=to_align(c0) if c0 is not None else [0, 0, 0, 0, 0, 0],
                note=note,
            )
        )
    raw = [
        (
            item.get("PartName"),
            ids(item.get("meshid")),
            ids(item.get("textureid")),
            item.get("AccessoryName"),
            item.get("C0") if item.get("C0") is not None else cframe_new(),
        )
        for item in tab.arr
    ]
    return out, raw


def native_rig(path):
    src = Source(path)
    tab = src.table("ALIGNS", mode="return")
    return [
        (
            item.get("PartName"),
            ids(item.get("meshid")),
            ids(item.get("textureid")),
            item.get("AccessoryName"),
            item.get("C0") if item.get("C0") is not None else cframe_new(),
        )
        for item in tab.arr
    ]


def lumen_rig(path):
    env = base_env()
    env["P"] = lambda limb, mesh=None, tex=None, offset=None, acc=None: {
        "limb": limb,
        "mesh": mesh or "",
        "tex": tex or "",
        "offset": offset if offset is not None else cframe_new(),
    }
    src = Source(path)
    tab = src.table("PRESETS", env)
    return [(p["limb"], p["mesh"] or None, p["tex"] or None, None, p["offset"]) for p in tab.arr]


def cf_list(tab):
    out = []
    for item in tab.arr:
        out.append((ids(item.get("meshid")), ids(item.get("textureid")), item.get("cframe")))
    return out


def dubstep(main_path, native_path):
    main = Source(main_path)
    guns = cf_list(main.table("gunaccessories"))
    aura = cf_list(main.table("auraaccessories"))
    bullet = main.table("BULLET")
    config = main.table("DUBGUN", lenient=True)
    extra = [str(x) for x in config.get("ExtraGuns").arr]
    native = Source(native_path)
    native_guns = cf_list(native.table("gunaccessories"))
    native_aura = cf_list(native.table("auraaccessories"))
    same = (
        len(guns) == len(native_guns)
        and len(aura) == len(native_aura)
        and all(a[0] == b[0] and a[1] == b[1] and cf_close(a[2], b[2], 1e-9, 1e-9) for a, b in zip(guns + aura, native_guns + native_aura))
    )
    rows = []
    for mesh, tex, cf in guns:
        rows.append(row(slot="gun", mesh=mesh, tex=tex, align=to_align(cf)))
    for mesh, tex, cf in aura:
        rows.append(row(slot="aura", mesh=mesh, tex=tex, align=to_align(cf)))
    rows.append(
        row(
            slot="bullet",
            mesh=ids(bullet.get("meshid")),
            tex=ids(bullet.get("textureid")),
            name="Elemental Crystal Golem Shoulder Rock",
            align=[0, 0, 0, 0, 0, 0],
        )
    )
    for hat in extra:
        rows.append(row(slot="extra", hat=hat, note="a catalog hat the script fits into the hand by itself"))
    return rows, {"guns": guns, "aura": aura, "same_as_native": same}


GUN_NAMES = {
    "87566002870491": "Sakura Futuristic Sniper Back",
    "131577122939956": "Black Sci-Fi Blaster Rifle",
}


def lc_gun_rows(config, name_of):
    rows = []
    guns = config.get("Guns")
    gun_list = [str(x) for x in guns.arr] if guns else [str(config.get("Gun"))]
    words = config.get("GunWords")
    word_sets = [[str(w) for w in s.arr] for s in words.arr] if words and words.arr and isinstance(words.arr[0], Tab) else None
    for i, hat in enumerate(gun_list):
        entry = dict(slot="gun", hat=hat, name=name_of.get(hat))
        if word_sets and i < len(word_sets):
            entry["words"] = word_sets[i]
        rows.append(row(**entry))
    bullet = config.get("Bullet")
    if bullet:
        rows.append(
            row(slot="bullet", mesh=str(bullet), name="Elemental Crystal Golem Shoulder Rock", align=[0, 0, 0, 0, 0, 0])
        )
    return rows


def hotline(path):
    return lc_gun_rows(Source(path).table("HOTLINE", lenient=True), GUN_NAMES)


def sniper(path):
    return lc_gun_rows(Source(path).table("SNIPER", lenient=True), GUN_NAMES)


def words_of(tab):
    return [str(w) for w in tab.arr] if isinstance(tab, Tab) else None


def nep_gun(path):
    nep = Source(path).table("NEP", lenient=True)
    rows = []
    for slot, key, wordkey, name in (
        ("sword", "Sword", "SwordWords", "Corrupt Demonic Greatsword"),
        ("sword", "Scythe", "ScytheWords", "Pink Scythe"),
        ("gun", "Gun", "GunWords", "Kawaii Black Toy Gun 1.0"),
        ("gun", "Revolver", "RevolverWords", "Blue Cyber Heavy Revolver (Left)"),
        ("slash", "Slash", "SlashWords", "Nebula Blade"),
    ):
        rows.append(row(slot=slot, hat=str(nep.get(key)), name=name, words=words_of(nep.get(wordkey))))
    rows.append(
        row(
            slot="bullet",
            mesh=str(nep.get("Bullet")),
            name="Elemental Crystal Golem Shoulder Rock",
            align=[0, 0, 0, 0, 0, 0],
        )
    )
    return rows


def nep_v(path):
    swords = Source(path).table("SWORDS")
    rows = []
    for s in swords.arr:
        hat = str(int(s.get("id")))
        common = dict(key=s.get("key"), hat=hat, name=s.get("name"), words=words_of(s.get("words")))
        align = s.get("align")
        for slot, vals in (("sword", align.get("sword")), ("swordback", align.get("swordback")), ("base", align.get("base"))):
            nums = [float(x) for x in vals.arr]
            if len(nums) == 3:
                nums = [0.0, 0.0, 0.0] + nums
            rows.append(row(slot=slot, align=[clean(x, 5, 1e-4) for x in nums], **common))
    return rows


def last_star(path):
    ls = Source(path).table("LS_SETTINGS", lenient=True)
    rows = []
    for hat in ls.get("SWORD_HATS").arr:
        rows.append(row(slot="give", hat=str(hat)))
    offset = to_align(ls.get("SWORD_OFFSET"))
    for i, tex in enumerate(ls.get("SWORD_TEXTURES").arr):
        rows.append(row(slot="wing%d" % (i + 1), tex=str(tex), align=offset))
    for mesh in ls.get("SWORD_MESHES").arr:
        rows.append(row(slot="backup", mesh=str(mesh), note="takes an empty wing when a texture is missing"))
    return rows, ls.get("SWORD_OFFSET")


SNAKE_NAMES = (("LC Gun 1", "VoidAlligatorJaw copy"), ("LC Gun 2", "VoidRPG copy"))


def snake(path):
    table = Source(path).table("GUN_IDS")
    rows = []
    for s, slot in enumerate(table.arr):
        for k, pair in enumerate(slot.arr):
            rows.append(
                row(
                    slot="gun%d" % (s + 1),
                    mesh=str(pair.arr[0]),
                    tex=str(pair.arr[1]),
                    name=SNAKE_NAMES[s][k],
                    align=[0, 0, 0, 0, 0, 0],
                )
            )
    rows.append(row(slot="muzzle", align=[0, 0, -4, 0, 0, 0], note="where the shot starts, studs and degrees from the gun"))
    return rows


def studio(path):
    src = Source(path)
    sd = src.table("SD", lenient=True)
    rows = []
    for mesh in sd.get("GunMeshes").arr:
        rows.append(row(slot="gun", mesh=str(mesh)))
    for hat in sd.get("GunItems").arr:
        rows.append(row(slot="gunitem", hat=str(hat), note="catalog id, the script looks its mesh up and remembers it"))
    rows.append(row(slot="gunwords", words=words_of(sd.get("GunWords")), note="a hat whose name has any of these words is a gun"))
    for slot, mkey, wkey in (
        ("screen", "ScreenMeshes", "ScreenWords"),
        ("screen2", "Screen2Meshes", "Screen2Words"),
        ("head", "HeadMeshes", "HeadWords"),
        ("bullet", "BulletMeshes", "BulletWords"),
    ):
        for mesh in sd.get(mkey).arr:
            rows.append(row(slot=slot, mesh=str(mesh)))
        rows.append(row(slot=slot + "words", words=words_of(sd.get(wkey))))
    gunmap = src.table("GUNMAP", lenient=True)
    maps = []
    for mesh, entry in gunmap.map.items():
        mesh = str(mesh)
        pair = entry.get("pair")
        for slot, key in (("grip", "c1"), ("muzzle", "muzzle"), ("fix", "fix")):
            cf = entry.get(key)
            if cf is not None:
                note = ("the other gun of the pair is " + str(pair)) if (pair and slot == "grip") else None
                rows.append(row(slot=slot, mesh=mesh, align=to_align(cf), note=note))
                maps.append((mesh, slot, cf))
        tip = entry.get("tip")
        if tip is not None:
            rows.append(row(slot="tip", mesh=mesh, align=[clean(x, 5, 1e-4) for x in tip] + [0, 0, 0]))
    return rows, maps


def gelatek():
    return [
        row(
            slot="bullet",
            name="Pal Hair",
            align=[0, 0, 0, 90, 0, 0],
            note="R6 Bullet mode: the hat is lined up with the Left Arm",
        )
    ]


def lua_str(s):
    return '"' + str(s).replace("\\", "\\\\").replace('"', '\\"') + '"'


def fmt_num(v):
    s = ("%.5f" % v).rstrip("0").rstrip(".")
    return "0" if s in ("", "-0") else s


def fmt_value(key, value):
    if key == "align":
        return "{" + ", ".join(fmt_num(x) for x in value) + "}"
    if key == "words":
        return "{" + ", ".join(lua_str(w) for w in value) + "}"
    return lua_str(value)


def fmt_row(r):
    return "{" + ", ".join("%s = %s" % (k, fmt_value(k, r[k])) for k in KEY_ORDER if k in r) + "}"


def emit(data):
    lines = ["return {", "\tversion = 1,", "\thelp = {"]
    for line in HELP:
        lines.append("\t\t" + lua_str(line) + ",")
    lines.append("\t},")
    lines.append("\tslots = {")
    for name in SCRIPT_ORDER:
        lines.append("\t\t[%s] = {" % lua_str(name))
        for slot, text in SLOTS[name]:
            lines.append("\t\t\t%s = %s," % (slot, lua_str(text)))
        lines.append("\t\t},")
    lines.append("\t},")
    lines.append("\trig = {")
    for r in data["rig"]:
        lines.append("\t\t" + fmt_row(r) + ",")
    lines.append("\t},")
    lines.append("\tscripts = {")
    for name in SCRIPT_ORDER:
        lines.append("\t\t[%s] = {" % lua_str(name))
        for r in data["scripts"][name]:
            lines.append("\t\t\t" + fmt_row(r) + ",")
        lines.append("\t\t},")
    lines.append("\t},")
    lines.append("}")
    return "\n".join(lines) + "\n"


def collect(main_dir, pkg_dir):
    mp = lambda name: os.path.join(main_dir, name)
    hat = lambda name: os.path.join(pkg_dir, "Scripts", "Hat", name)
    report = {}
    rig, raw = rig_rows(os.path.join(pkg_dir, "Reanimation", "Hat", "FDless.lua"))
    report["rig_raw"] = raw
    report["native_rigs"] = {
        "Dubstep (hub)": native_rig(hat("DubstepGun.lua")),
        "Snake Banisher (hub)": native_rig(hat("SnakeBanisherV3.lua")),
        "Studio Dummy (hub)": native_rig(hat("StudioDummyV4-Test.lua")),
    }
    report["lumen_rig"] = lumen_rig(os.path.join(pkg_dir, "Hub", "Reanimate.lua"))
    dub_rows, dub = dubstep(mp("DubstepGun.lua"), hat("DubstepGun.lua"))
    report["dubstep"] = dub
    ls_rows, ls_offset = last_star(mp("Last Star.lua"))
    report["last_star_offset"] = ls_offset
    studio_rows, studio_maps = studio(hat("StudioDummyV4-Test.lua"))
    report["studio_maps"] = studio_maps
    scripts = {
        "Dubstep Gun": dub_rows,
        "The Hotline": hotline(mp("TheHotline.lua")),
        "The Sniper": sniper(mp("TheSniper(Don't use this).lua")),
        "Neptunian V": nep_v(mp("Neptunian V.lua")),
        "Neptunian V Gun": nep_gun(mp("Neptunian V Gun.lua")),
        "Last Star": ls_rows,
        "Snake Banisher V3": snake(hat("SnakeBanisherV3.lua")),
        "Studio Dummy V4": studio_rows,
        "Gelatek": gelatek(),
    }
    return {"version": 1, "rig": rig, "scripts": scripts}, report


def same_entry(x, y):
    return x[0] == y[0] and x[1] == y[1] and x[2] == y[2] and (x[3] or None) == (y[3] or None) and cf_close(x[4], y[4], 1e-9, 1e-9)


def same_rig(a, b, label, problems):
    if len(a) != len(b):
        problems.append("%s: %d entries against %d" % (label, len(b), len(a)))
        return
    for i, (x, y) in enumerate(zip(a, b)):
        if not same_entry(x, y):
            problems.append("%s: entry %d differs: %r %r" % (label, i + 1, x[:4], y[:4]))


def subset_rig(part, whole, label, problems):
    left = list(whole)
    for i, x in enumerate(part):
        for j, y in enumerate(left):
            if same_entry(x, y):
                del left[j]
                break
        else:
            problems.append("%s: entry %d is not in the FDless list: %r" % (label, i + 1, x[:4]))
    return left


def verify(data, report, text):
    problems = []
    raw = report["rig_raw"]
    for label, other in report["native_rigs"].items():
        if label.startswith("Dubstep"):
            subset_rig(other, raw, label, problems)
        else:
            same_rig(raw, other, label, problems)
    lumen = [(p[0], p[1], p[2], None, p[4]) for p in report["lumen_rig"]]
    left = subset_rig(lumen, [r for r in raw if r[3] is None], "Reanimate.lua presets", problems)
    report["lumen_missing"] = [r[:3] for r in left]
    if not report["dubstep"]["same_as_native"]:
        problems.append("Dubstep Gun: the hub copy and the Main Scripts copy have different hat tables")
    again = parse_emitted(text)
    if len(again["rig"]) != len(raw):
        problems.append("rig: %d rows written, %d read back" % (len(raw), len(again["rig"])))
    else:
        for i, (r, src) in enumerate(zip(again["rig"], raw)):
            if r.get("part") != src[0] or r.get("mesh") != src[1] or r.get("tex") != src[2] or r.get("acc") != src[3]:
                problems.append("rig row %d: identity changed" % (i + 1))
            elif not cf_close(from_align(r["align"]), src[4]):
                problems.append("rig row %d: alignment moved" % (i + 1))
    dub = report["dubstep"]
    written = [r for r in again["scripts"]["Dubstep Gun"] if r.get("slot") in ("gun", "aura")]
    source = dub["guns"] + dub["aura"]
    if len(written) != len(source):
        problems.append("Dubstep Gun: %d hat rows written, %d in the script" % (len(written), len(source)))
    else:
        for i, (r, src) in enumerate(zip(written, source)):
            if r.get("mesh") != src[0] or r.get("tex") != src[1] or not cf_close(from_align(r["align"]), src[2]):
                problems.append("Dubstep Gun row %d does not match the script" % (i + 1))
    ls = [r for r in again["scripts"]["Last Star"] if r["slot"].startswith("wing")]
    for r in ls:
        want = report["last_star_offset"]
        if not cf_close(from_align(r["align"]), want):
            problems.append("Last Star %s: the sword offset moved" % r["slot"])
    gm = report["studio_maps"]
    seen = [(r.get("mesh"), r["slot"], r) for r in again["scripts"]["Studio Dummy V4"] if r["slot"] in ("grip", "muzzle", "fix")]
    if len(seen) != len(gm):
        problems.append("Studio Dummy V4: %d gun maps written, %d in the script" % (len(seen), len(gm)))
    else:
        for (mesh, slot, r), (m2, s2, cf) in zip(seen, gm):
            if mesh != m2 or slot != s2 or not cf_close(from_align(r["align"]), cf):
                problems.append("Studio Dummy V4 %s %s: alignment moved" % (mesh, slot))
    return problems


def parse_emitted(text):
    toks = luau.lex(text, 1)
    i = 0
    while not (toks[i].k == "kw" and toks[i].v == "return"):
        i += 1
    tab = Parser(toks, i + 1, {}).table()

    def plain(t):
        if isinstance(t, Tab):
            if t.map and not t.arr:
                return {k: plain(v) for k, v in t.map.items()}
            return [plain(v) for v in t.arr] if not t.map else {**{k: plain(v) for k, v in t.map.items()}}
        return t

    return plain(tab)


def main(argv):
    if len(argv) < 4:
        sys.stderr.write("usage: build_alignment.py <Main Scripts dir> <package dir> <output alignment.lua>\n")
        return 2
    main_dir, pkg_dir, out = argv[1], argv[2], argv[3]
    data, report = collect(main_dir, pkg_dir)
    text = emit(data)
    problems = verify(data, report, text)
    counts = {"rig": len(data["rig"])}
    for name in SCRIPT_ORDER:
        counts[name] = len(data["scripts"][name])
    print(json.dumps(counts, indent=1))
    for m in report.get("lumen_missing", []):
        print("note: Reanimate.lua presets do not have the FDless entry", m)
    if problems:
        for p in problems:
            print("PROBLEM", p)
        return 1
    with open(out, "w", encoding="utf-8", newline="\n") as fh:
        fh.write(text)
    print("wrote", out, len(text), "bytes, verified against the sources")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
