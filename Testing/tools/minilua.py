import importlib.util
import math
import os
import random
import sys
import threading
import time


def _lexer():
    here = os.path.dirname(os.path.abspath(__file__))
    spec = importlib.util.spec_from_file_location("luau_lexer", os.path.join(here, "luau.py"))
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


LX = _lexer()
LuauError = LX.LuauError


class LuaError(Exception):
    def __init__(self, value, trace=None):
        Exception.__init__(self, value if isinstance(value, str) else repr(value))
        self.value = value
        self.trace = trace or []


class KeyBool(object):
    def __init__(self, v):
        self.v = v


KTRUE = KeyBool(True)
KFALSE = KeyBool(False)


def nkey(k):
    if k is True:
        return KTRUE
    if k is False:
        return KFALSE
    if type(k) is int:
        return float(k)
    return k


def ukey(k):
    if k is KTRUE:
        return True
    if k is KFALSE:
        return False
    return k


class LuaTable(object):
    __slots__ = ("d", "meta", "border", "frozen")

    def __init__(self):
        self.d = {}
        self.meta = None
        self.border = 0
        self.frozen = False

    def get(self, k):
        return self.d.get(nkey(k))

    def set(self, k, v):
        k = nkey(k)
        if v is None:
            if k in self.d:
                del self.d[k]
                if type(k) is float and k <= self.border and k >= 1:
                    self.border = int(k) - 1
        else:
            self.d[k] = v

    def length(self):
        n = self.border
        d = self.d
        while (float(n + 1)) in d:
            n += 1
        while n > 0 and float(n) not in d:
            n -= 1
        self.border = n
        return n

    def append(self, v):
        if v is None:
            return
        n = self.length() + 1
        self.d[float(n)] = v
        self.border = n


class LuaFunction(object):
    __slots__ = ("params", "vararg", "body", "scope", "name", "interp")

    def __init__(self, params, vararg, body, scope, name, interp):
        self.params = params
        self.vararg = vararg
        self.body = body
        self.scope = scope
        self.name = name
        self.interp = interp


class Builtin(object):
    __slots__ = ("fn", "name")

    def __init__(self, fn, name):
        self.fn = fn
        self.name = name


class Scope(object):
    __slots__ = ("v", "p")

    def __init__(self, p=None):
        self.v = {}
        self.p = p


BRK = ("break",)
CNT = ("continue",)


def truthy(v):
    return v is not None and v is not False


def lua_type(v):
    if v is None:
        return "nil"
    if v is True or v is False:
        return "boolean"
    if type(v) is float or type(v) is int:
        return "number"
    if isinstance(v, str):
        return "string"
    if isinstance(v, LuaTable):
        return "table"
    if isinstance(v, (LuaFunction, Builtin)):
        return "function"
    if isinstance(v, Co):
        return "thread"
    return "userdata"


def fmt_num(n):
    if n != n:
        return "nan" if math.copysign(1, n) > 0 else "-nan"
    if n == math.inf:
        return "inf"
    if n == -math.inf:
        return "-inf"
    if n == int(n) and abs(n) < 1e15:
        return "%d" % int(n)
    s = "%.14g" % n
    return s


def to_num(v):
    if type(v) is float:
        return v
    if type(v) is int:
        return float(v)
    if isinstance(v, str):
        s = v.strip()
        if not s or "_" in s:
            return None
        try:
            if s[:2] in ("0x", "0X"):
                return float(int(s, 16))
            if s[:3] in ("-0x", "-0X"):
                return -float(int(s[1:], 16))
            if s.lower() in ("inf", "-inf", "nan", "+inf", "infinity", "-infinity"):
                return None
            return float(s)
        except ValueError:
            return None
    return None



L_ESC = "%"
SPECIALS = "^$*+?.([%-"
MAXCCALLS = 200


class MatchState(object):
    def __init__(self, src, pat):
        self.src = src
        self.pat = pat
        self.level = 0
        self.capture = []
        self.depth = 0


class PatErr(Exception):
    pass


def class_end(ms, p):
    pat = ms.pat
    if p >= len(pat):
        raise PatErr("malformed pattern (ends with '%')")
    c = pat[p]
    p += 1
    if c == L_ESC:
        if p >= len(pat):
            raise PatErr("malformed pattern (ends with '%')")
        return p + 1
    if c == "[":
        if p < len(pat) and pat[p] == "^":
            p += 1
        while True:
            if p >= len(pat):
                raise PatErr("malformed pattern (missing ']')")
            cc = pat[p]
            p += 1
            if cc == L_ESC:
                if p >= len(pat):
                    raise PatErr("malformed pattern (missing ']')")
                p += 1
            if p < len(pat) and pat[p] == "]":
                return p + 1
            if p >= len(pat):
                raise PatErr("malformed pattern (missing ']')")
    return p


def single_class(c, cl):
    lo = cl.lower()
    o = ord(c)
    if lo == "a":
        r = c.isalpha() and o < 128
    elif lo == "c":
        r = o < 32 or o == 127
    elif lo == "d":
        r = "0" <= c <= "9"
    elif lo == "g":
        r = 33 <= o <= 126
    elif lo == "l":
        r = "a" <= c <= "z"
    elif lo == "p":
        r = (33 <= o <= 47) or (58 <= o <= 64) or (91 <= o <= 96) or (123 <= o <= 126)
    elif lo == "s":
        r = c in " \t\n\r\f\v"
    elif lo == "u":
        r = "A" <= c <= "Z"
    elif lo == "w":
        r = (c.isalnum() and o < 128)
    elif lo == "x":
        r = c in "0123456789abcdefABCDEF"
    else:
        return cl == c
    if cl.isupper():
        return not r
    return r


def match_bracket(ms, c, p, ec):
    pat = ms.pat
    sig = True
    p += 1
    if pat[p] == "^":
        sig = False
        p += 1
    while p < ec:
        if pat[p] == L_ESC:
            p += 1
            if single_class(c, pat[p]):
                return sig
            p += 1
        elif p + 2 < ec and pat[p + 1] == "-":
            if pat[p] <= c <= pat[p + 2]:
                return sig
            p += 3
        else:
            if pat[p] == c:
                return sig
            p += 1
    return not sig


def single_match(ms, s, p, ep):
    if s >= len(ms.src):
        return False
    c = ms.src[s]
    pc = ms.pat[p]
    if pc == ".":
        return True
    if pc == L_ESC:
        return single_class(c, ms.pat[p + 1])
    if pc == "[":
        return match_bracket(ms, c, p, ep - 1)
    return pc == c


def match_balance(ms, s, p):
    pat = ms.pat
    if p + 1 >= len(pat):
        raise PatErr("malformed pattern (missing arguments to '%b')")
    if s >= len(ms.src) or ms.src[s] != pat[p]:
        return -1
    b = pat[p]
    e = pat[p + 1]
    cont = 1
    s += 1
    while s < len(ms.src):
        ch = ms.src[s]
        if ch == e:
            cont -= 1
            if cont == 0:
                return s + 1
        elif ch == b:
            cont += 1
        s += 1
    return -1


def max_expand(ms, s, p, ep):
    i = 0
    while single_match(ms, s + i, p, ep):
        i += 1
    while i >= 0:
        r = do_match(ms, s + i, ep + 1)
        if r != -1:
            return r
        i -= 1
    return -1


def min_expand(ms, s, p, ep):
    while True:
        r = do_match(ms, s, ep + 1)
        if r != -1:
            return r
        if single_match(ms, s, p, ep):
            s += 1
        else:
            return -1


def start_capture(ms, s, p, what):
    ms.capture.append([s, what])
    ms.level += 1
    r = do_match(ms, s, p)
    if r == -1:
        ms.level -= 1
        ms.capture.pop()
    return r


def end_capture(ms, s, p):
    l = -1
    for i in range(ms.level - 1, -1, -1):
        if ms.capture[i][1] == -1:
            l = i
            break
    if l < 0:
        raise PatErr("invalid pattern capture")
    ms.capture[l][1] = s - ms.capture[l][0]
    r = do_match(ms, s, p)
    if r == -1:
        ms.capture[l][1] = -1
    return r


def match_capture(ms, s, l):
    l = ord(l) - ord("1")
    if l < 0 or l >= ms.level or ms.capture[l][1] == -1:
        raise PatErr("invalid capture index")
    st, ln = ms.capture[l]
    cap = ms.src[st:st + ln]
    if ms.src[s:s + ln] == cap and s + ln <= len(ms.src):
        return s + ln
    return -1


def do_match(ms, s, p):
    ms.depth += 1
    if ms.depth > MAXCCALLS * 5:
        raise PatErr("pattern too complex")
    try:
        pat = ms.pat
        while True:
            if p >= len(pat):
                return s
            pc = pat[p]
            if pc == "(":
                if p + 1 < len(pat) and pat[p + 1] == ")":
                    return start_capture(ms, s, p + 2, -2)
                return start_capture(ms, s, p + 1, -1)
            if pc == ")":
                return end_capture(ms, s, p + 1)
            if pc == "$" and p + 1 == len(pat):
                return s if s == len(ms.src) else -1
            if pc == L_ESC and p + 1 < len(pat):
                nc = pat[p + 1]
                if nc == "b":
                    s = match_balance(ms, s, p + 2)
                    if s != -1:
                        p += 4
                        continue
                    return -1
                if nc == "f":
                    p += 2
                    if p >= len(pat) or pat[p] != "[":
                        raise PatErr("missing '[' after '%f' in pattern")
                    ep = class_end(ms, p)
                    prev = ms.src[s - 1] if s > 0 else "\0"
                    cur = ms.src[s] if s < len(ms.src) else "\0"
                    if (not match_bracket(ms, prev, p, ep - 1)) and match_bracket(ms, cur, p, ep - 1):
                        p = ep
                        continue
                    return -1
                if nc.isdigit():
                    s = match_capture(ms, s, nc)
                    if s != -1:
                        p += 2
                        continue
                    return -1
            ep = class_end(ms, p)
            epc = pat[ep] if ep < len(pat) else ""
            if epc == "?":
                if single_match(ms, s, p, ep):
                    r = do_match(ms, s + 1, ep + 1)
                    if r != -1:
                        return r
                p = ep + 1
                continue
            if epc == "+":
                return max_expand(ms, s + 1, p, ep) if single_match(ms, s, p, ep) else -1
            if epc == "*":
                return max_expand(ms, s, p, ep)
            if epc == "-":
                return min_expand(ms, s, p, ep)
            if not single_match(ms, s, p, ep):
                return -1
            s += 1
            p = ep
    finally:
        ms.depth -= 1


def get_capture(ms, i, s, e):
    if i >= ms.level:
        if i == 0:
            return ms.src[s:e]
        raise PatErr("invalid capture index")
    st, ln = ms.capture[i]
    if ln == -1:
        raise PatErr("unfinished capture")
    if ln == -2:
        return float(st + 1)
    return ms.src[st:st + ln]


def captures(ms, s, e, whole_if_none=True):
    n = ms.level if (ms.level != 0 or not whole_if_none) else 1
    return [get_capture(ms, i, s, e) for i in range(n)]


def str_find_aux(s, pat, init, plain, find):
    ls = len(s)
    if init is None:
        init = 1
    init = int(init)
    if init < 0:
        init = ls + init + 1
        if init < 1:
            init = 1
    elif init == 0:
        init = 1
    if init > ls + 1:
        return [None]
    if find and (plain or not any(c in SPECIALS for c in pat)):
        i = s.find(pat, init - 1)
        if i < 0:
            return [None]
        return [float(i + 1), float(i + len(pat))]
    anchor = pat.startswith("^")
    p0 = 1 if anchor else 0
    s1 = init - 1
    while True:
        ms = MatchState(s, pat)
        e = do_match(ms, s1, p0)
        if e != -1:
            if find:
                return [float(s1 + 1), float(e)] + captures(ms, s1, e, False)
            return captures(ms, s1, e)
        s1 += 1
        if anchor or s1 > ls:
            break
    return [None]



PRIO = {
    "or": (1, 1), "and": (2, 2),
    "<": (3, 3), ">": (3, 3), "<=": (3, 3), ">=": (3, 3), "~=": (3, 3), "==": (3, 3),
    "..": (9, 8), "+": (10, 10), "-": (10, 10),
    "*": (11, 11), "/": (11, 11), "//": (11, 11), "%": (11, 11),
    "^": (14, 13),
}
UNARY_PRIO = 12
COMPOUND = {"+=": "+", "-=": "-", "*=": "*", "/=": "/", "//=": "//", "%=": "%", "^=": "^", "..=": ".."}


def unescape(raw, line):
    if raw.startswith("["):
        i = raw.index("[", 1)
        eq = i - 1
        body = raw[i + 1:len(raw) - (eq + 2)]
        if body.startswith("\r\n"):
            body = body[2:]
        elif body.startswith("\n"):
            body = body[1:]
        return body
    q = raw[0]
    body = raw[1:-1]
    out = []
    i = 0
    n = len(body)
    while i < n:
        c = body[i]
        if c != "\\":
            out.append(c)
            i += 1
            continue
        i += 1
        if i >= n:
            break
        c = body[i]
        simple = {"n": "\n", "t": "\t", "r": "\r", "a": "\a", "b": "\b", "f": "\f", "v": "\v", "\\": "\\", '"': '"', "'": "'", "\n": "\n"}
        if c in simple:
            out.append(simple[c])
            i += 1
        elif c == "x":
            out.append(chr(int(body[i + 1:i + 3], 16)))
            i += 3
        elif c == "z":
            i += 1
            while i < n and body[i] in " \t\r\n\f\v":
                i += 1
        elif c == "u" and body[i + 1] == "{":
            j = body.index("}", i)
            out.append(chr(int(body[i + 2:j], 16)))
            i = j + 1
        elif c.isdigit():
            j = i
            while j < n and j < i + 3 and body[j].isdigit():
                j += 1
            out.append(chr(int(body[i:j])))
            i = j
        else:
            out.append(c)
            i += 1
    return "".join(out)


def parse_number(v):
    s = v.replace("_", "")
    if s[:2] in ("0x", "0X"):
        if "." in s or "p" in s.lower():
            return float.fromhex(s)
        return float(int(s, 16))
    if s[:2] in ("0b", "0B"):
        return float(int(s[2:], 2))
    return float(s)


class P(object):
    def __init__(self, src, chunk):
        self.toks = LX.lex(src)
        self.i = 0
        self.chunk = chunk

    def tok(self):
        return self.toks[self.i]

    def err(self, msg):
        t = self.tok()
        raise LuaError("%s:%d: %s near '%s'" % (self.chunk, t.line, msg, t.v if isinstance(t.v, str) else t.k))

    def isop(self, v):
        t = self.toks[self.i]
        return t.k == "op" and t.v == v

    def iskw(self, v):
        t = self.toks[self.i]
        return t.k == "kw" and t.v == v

    def accop(self, v):
        if self.isop(v):
            self.i += 1
            return True
        return False

    def acckw(self, v):
        if self.iskw(v):
            self.i += 1
            return True
        return False

    def expop(self, v):
        if not self.accop(v):
            self.err("expected '%s'" % v)

    def expkw(self, v):
        if not self.acckw(v):
            self.err("expected '%s'" % v)

    def name(self):
        t = self.tok()
        if t.k != "name":
            self.err("expected name")
        self.i += 1
        return t.v

    def chunk_body(self):
        b = self.block()
        if self.tok().k != "eof":
            self.err("unexpected symbol")
        return b

    def block_end(self):
        t = self.tok()
        if t.k == "eof":
            return True
        return t.k == "kw" and t.v in ("end", "else", "elseif", "until")

    def block(self):
        stmts = []
        while not self.block_end():
            if self.iskw("return"):
                line = self.tok().line
                self.i += 1
                exprs = []
                if not self.block_end() and not self.isop(";"):
                    exprs = self.exprlist()
                self.accop(";")
                stmts.append(("return", line, exprs))
                break
            s = self.statement()
            if s is not None:
                stmts.append(s)
        return stmts

    def statement(self):
        t = self.tok()
        line = t.line
        if t.k == "op" and t.v == ";":
            self.i += 1
            return None
        if t.k == "kw":
            v = t.v
            if v == "if":
                self.i += 1
                clauses = []
                cond = self.expr()
                self.expkw("then")
                clauses.append((cond, self.block()))
                els = None
                while True:
                    if self.acckw("elseif"):
                        c = self.expr()
                        self.expkw("then")
                        clauses.append((c, self.block()))
                    elif self.acckw("else"):
                        els = self.block()
                        self.expkw("end")
                        break
                    else:
                        self.expkw("end")
                        break
                return ("if", line, clauses, els)
            if v == "while":
                self.i += 1
                c = self.expr()
                self.expkw("do")
                b = self.block()
                self.expkw("end")
                return ("while", line, c, b)
            if v == "do":
                self.i += 1
                b = self.block()
                self.expkw("end")
                return ("do", line, b)
            if v == "for":
                self.i += 1
                n1 = self.name()
                if self.isop("="):
                    self.i += 1
                    a = self.expr()
                    self.expop(",")
                    b = self.expr()
                    c = None
                    if self.accop(","):
                        c = self.expr()
                    self.expkw("do")
                    body = self.block()
                    self.expkw("end")
                    return ("fornum", line, n1, a, b, c, body)
                names = [n1]
                while self.accop(","):
                    names.append(self.name())
                self.expkw("in")
                exprs = self.exprlist()
                self.expkw("do")
                body = self.block()
                self.expkw("end")
                return ("forin", line, names, exprs, body)
            if v == "repeat":
                self.i += 1
                b = self.block()
                self.expkw("until")
                c = self.expr()
                return ("repeat", line, b, c)
            if v == "function":
                self.i += 1
                n = self.name()
                target = ("name", n)
                full = n
                is_method = False
                while self.isop(".") or self.isop(":"):
                    sep = self.tok().v
                    self.i += 1
                    k = self.name()
                    full += sep + k
                    target = ("index", target, ("str", k))
                    if sep == ":":
                        is_method = True
                        break
                f = self.funcbody(full, is_method, line)
                return ("assign", line, [target], [f])
            if v == "local":
                self.i += 1
                if self.acckw("function"):
                    n = self.name()
                    f = self.funcbody(n, False, line)
                    return ("localfunc", line, n, f)
                names = []
                while True:
                    names.append(self.name())
                    if self.accop("<"):
                        self.name()
                        self.expop(">")
                    if not self.accop(","):
                        break
                exprs = []
                if self.accop("="):
                    exprs = self.exprlist()
                return ("local", line, names, exprs)
            if v == "return":
                self.err("unexpected return")
            if v == "break":
                self.i += 1
                return ("break", line)
        if t.k == "name" and t.v == "continue":
            nx = self.toks[self.i + 1]
            if not (nx.k == "op" and nx.v in ("=", ".", ":", "(", "[", ",", "+=", "-=")):
                self.i += 1
                return ("continue", line)
        e = self.suffixed()
        t = self.tok()
        if t.k == "op" and (t.v == "=" or t.v == ","):
            targets = [e]
            while self.accop(","):
                targets.append(self.suffixed())
            self.expop("=")
            exprs = self.exprlist()
            for tg in targets:
                if tg[0] not in ("name", "index"):
                    self.err("cannot assign")
            return ("assign", line, targets, exprs)
        if t.k == "op" and t.v in COMPOUND:
            self.i += 1
            rhs = self.expr()
            return ("compound", line, COMPOUND[t.v], e, rhs)
        if e[0] not in ("call", "method"):
            self.err("syntax error")
        return ("callstat", line, e)

    def funcbody(self, name, is_method, line):
        self.expop("(")
        params = ["self"] if is_method else []
        vararg = False
        if not self.isop(")"):
            while True:
                if self.accop("..."):
                    vararg = True
                    break
                params.append(self.name())
                if self.accop(":"):
                    self.err("type annotations are not supported")
                if not self.accop(","):
                    break
        self.expop(")")
        body = self.block()
        self.expkw("end")
        return ("func", line, params, vararg, body, name)

    def exprlist(self):
        es = [self.expr()]
        while self.accop(","):
            es.append(self.expr())
        return es

    def primary(self):
        t = self.tok()
        if t.k == "name":
            self.i += 1
            return ("name", t.v, t.line)
        if t.k == "op" and t.v == "(":
            self.i += 1
            e = self.expr()
            self.expop(")")
            return ("paren", e)
        self.err("unexpected symbol")

    def suffixed(self):
        e = self.primary()
        while True:
            t = self.tok()
            if t.k == "op":
                if t.v == ".":
                    self.i += 1
                    e = ("index", e, ("str", self.name()), t.line)
                    continue
                if t.v == "[":
                    self.i += 1
                    k = self.expr()
                    self.expop("]")
                    e = ("index", e, k, t.line)
                    continue
                if t.v == ":":
                    self.i += 1
                    n = self.name()
                    args = self.callargs()
                    e = ("method", e, n, args, t.line)
                    continue
                if t.v == "(" or t.v == "{":
                    args = self.callargs()
                    e = ("call", e, args, t.line)
                    continue
            elif t.k == "str":
                args = self.callargs()
                e = ("call", e, args, t.line)
                continue
            return e

    def callargs(self):
        t = self.tok()
        if t.k == "str":
            self.i += 1
            return [("str", unescape(t.v, t.line))]
        if t.k == "op" and t.v == "{":
            return [self.table()]
        self.expop("(")
        if self.accop(")"):
            return []
        args = self.exprlist()
        self.expop(")")
        return args

    def table(self):
        self.expop("{")
        items = []
        while not self.isop("}"):
            t = self.tok()
            if t.k == "op" and t.v == "[":
                self.i += 1
                k = self.expr()
                self.expop("]")
                self.expop("=")
                items.append(("kv", k, self.expr()))
            elif t.k == "name" and self.toks[self.i + 1].k == "op" and self.toks[self.i + 1].v == "=":
                self.i += 2
                items.append(("kv", ("str", t.v), self.expr()))
            else:
                items.append(("pos", self.expr()))
            if not (self.accop(",") or self.accop(";")):
                break
        self.expop("}")
        return ("table", items)

    def simple(self):
        t = self.tok()
        k = t.k
        if k == "num":
            self.i += 1
            return ("num", parse_number(t.v))
        if k == "str":
            self.i += 1
            return ("str", unescape(t.v, t.line))
        if k == "kw":
            if t.v == "nil":
                self.i += 1
                return ("nil",)
            if t.v == "true":
                self.i += 1
                return ("true",)
            if t.v == "false":
                self.i += 1
                return ("false",)
            if t.v == "function":
                self.i += 1
                return self.funcbody("anonymous", False, t.line)
            if t.v == "if":
                self.i += 1
                c = self.expr()
                self.expkw("then")
                a = self.expr()
                if self.iskw("elseif"):
                    self.toks[self.i] = LX.Tok("kw", "if", self.tok().line)
                    b = self.simple()
                else:
                    self.expkw("else")
                    b = self.expr()
                return ("ifexpr", c, a, b)
        if k == "op":
            if t.v == "...":
                self.i += 1
                return ("vararg",)
            if t.v == "{":
                return self.table()
        if k == "interp":
            self.err("interpolated strings are not supported by minilua")
        return self.suffixed()

    def expr(self, limit=0):
        t = self.tok()
        if (t.k == "kw" and t.v == "not") or (t.k == "op" and t.v in ("-", "#")):
            self.i += 1
            operand = self.expr(UNARY_PRIO)
            left = ("unop", t.v, operand, t.line)
        else:
            left = self.simple()
        while True:
            t = self.tok()
            op = t.v if (t.k == "op" or (t.k == "kw" and t.v in ("and", "or"))) else None
            if op is None or op not in PRIO:
                return left
            lp, rp = PRIO[op]
            if lp <= limit:
                return left
            self.i += 1
            right = self.expr(rp)
            if op == "and":
                left = ("and", left, right)
            elif op == "or":
                left = ("or", left, right)
            else:
                left = ("binop", op, left, right, t.line)



class Co(object):
    def __init__(self, interp, fn, args, protect=False):
        self.interp = interp
        self.fn = fn
        self.args = args
        self.thread = None
        self.go = threading.Event()
        self.back = threading.Event()
        self.done = False
        self.error = None
        self.protect = protect
        self.started = False
        self.transfer = []
        self.yielded = []

    def resume(self):
        if self.done:
            return
        interp = self.interp
        prev = interp.current_co
        interp.current_co = self
        self.back.clear()
        if self.thread is None:
            threading.stack_size(64 * 1024 * 1024)
            self.thread = threading.Thread(target=self.main, daemon=True)
            self.thread.start()
        else:
            self.go.set()
        self.back.wait()
        interp.current_co = prev

    def main(self):
        try:
            self.yielded = list(self.interp.call(self.fn, self.args))
        except BaseException as ex:
            self.error = ex
            if not self.protect:
                self.interp.thread_errors.append(ex)
        self.done = True
        self.back.set()

    def pause(self):
        self.go.clear()
        self.back.set()
        self.go.wait()


class Interp(object):
    def __init__(self, root="."):
        self.root = root
        self.G = LuaTable()
        self.out = []
        self.cur = ("?", 0)
        self.string_lib = LuaTable()
        self.string_meta = LuaTable()
        self.clock = 0.0
        self.queue = []
        self.seq = 0
        self.chunks = {}
        self.current_co = None
        self.thread_errors = []
        self.steps = 0
        self.step_limit = 10 ** 15
        self.max_segment = 0
        self.max_segment_at = None
        self.install()

    def err(self, msg, line=None):
        chunk, ln = self.cur
        raise LuaError("%s:%d: %s" % (chunk, line if line else ln, msg))

    def watchdog(self):
        self.steps = 0
        chunk, ln = self.cur
        raise LuaError("%s:%d: watchdog: more than %d steps without yielding" % (chunk, ln, self.step_limit))

    def segment_end(self):
        if self.steps > self.max_segment:
            self.max_segment = self.steps
            self.max_segment_at = self.cur
        self.steps = 0

    def index(self, o, k, line=0):
        if isinstance(o, LuaTable):
            v = o.d.get(nkey(k))
            if v is not None:
                return v
            m = o.meta
            if m is None:
                return None
            h = m.d.get("__index")
            if h is None:
                return None
            if isinstance(h, LuaTable):
                return self.index(h, k, line)
            return self.first(self.call(h, [o, k]))
        if isinstance(o, str):
            return self.string_lib.get(k)
        self.err("attempt to index %s value%s" % (lua_type(o) if o is not None else "nil", " (field '%s')" % k if isinstance(k, str) else ""), line)

    def setindex(self, o, k, v, line=0):
        if isinstance(o, LuaTable):
            if o.frozen:
                self.err("attempt to modify a readonly table", line)
            m = o.meta
            if m is not None and nkey(k) not in o.d:
                h = m.d.get("__newindex")
                if h is not None:
                    if isinstance(h, LuaTable):
                        return self.setindex(h, k, v, line)
                    self.call(h, [o, k, v])
                    return
            if k is None:
                self.err("table index is nil", line)
            if type(k) is float and k != k:
                self.err("table index is NaN", line)
            o.set(k, v)
            return
        self.err("attempt to index %s value" % lua_type(o), line)

    def first(self, r):
        return r[0] if r else None

    def call(self, f, args, line=0):
        self.steps += 1
        if self.steps > self.step_limit:
            self.watchdog()
        if isinstance(f, Builtin):
            r = f.fn(args)
            return r if r is not None else []
        if isinstance(f, LuaFunction):
            sc = Scope(f.scope)
            v = sc.v
            ps = f.params
            n = len(args)
            for i in range(len(ps)):
                v[ps[i]] = args[i] if i < n else None
            if f.vararg:
                v["..."] = args[len(ps):]
            saved = self.cur
            self.depth = getattr(self, "depth", 0) + 1
            if self.depth > 1000:
                self.depth -= 1
                self.err("stack overflow", line)
            try:
                sig = f.body(sc)
            finally:
                self.depth -= 1
                self.cur = saved
            if sig is not None and sig[0] == "ret":
                return sig[1]
            return []
        if isinstance(f, LuaTable) and f.meta is not None:
            h = f.meta.d.get("__call")
            if h is not None:
                return self.call(h, [f] + list(args), line)
        self.err("attempt to call a %s value" % lua_type(f), line)

    def meta_of(self, v):
        if isinstance(v, LuaTable):
            return v.meta
        if isinstance(v, str):
            return self.string_meta
        return None

    def tostr(self, v):
        if v is None:
            return "nil"
        if v is True:
            return "true"
        if v is False:
            return "false"
        if type(v) is float or type(v) is int:
            return fmt_num(float(v))
        if isinstance(v, str):
            return v
        if isinstance(v, LuaTable):
            if v.meta is not None:
                h = v.meta.d.get("__tostring")
                if h is not None:
                    return self.first(self.call(h, [v]))
            return "table: 0x%08x" % (id(v) & 0xffffffff)
        if isinstance(v, (LuaFunction, Builtin)):
            return "function: 0x%08x" % (id(v) & 0xffffffff)
        if isinstance(v, Co):
            return "thread: 0x%08x" % (id(v) & 0xffffffff)
        return str(v)

    def eq(self, a, b):
        if a is b:
            return not (type(a) is float and a != a)
        if a is None or b is None:
            return False
        if a is True or a is False or b is True or b is False:
            return False
        ta, tb = lua_type(a), lua_type(b)
        if ta != tb:
            return False
        if ta == "number" or ta == "string":
            return a == b
        if ta == "table":
            for t in (a, b):
                if t.meta is not None:
                    h = t.meta.d.get("__eq")
                    if h is not None:
                        return truthy(self.first(self.call(h, [a, b])))
        return False

    def arith(self, op, a, b, line):
        x = a if type(a) is float else to_num(a)
        y = b if type(b) is float else to_num(b)
        if x is None or y is None or isinstance(a, bool) or isinstance(b, bool):
            names = {"+": "__add", "-": "__sub", "*": "__mul", "/": "__div", "%": "__mod", "^": "__pow", "//": "__idiv"}
            for v in (a, b):
                m = self.meta_of(v) if isinstance(v, LuaTable) else None
                if m is not None:
                    h = m.d.get(names[op])
                    if h is not None:
                        return self.first(self.call(h, [a, b]))
            bad = a if (x is None or isinstance(a, bool)) else b
            self.err("attempt to perform arithmetic (%s) on %s" % (op, lua_type(bad)), line)
        if op == "+":
            return x + y
        if op == "-":
            return x - y
        if op == "*":
            return x * y
        if op == "/":
            if y == 0:
                if x == 0 or x != x:
                    return math.nan
                return math.inf if (x > 0) == (math.copysign(1, y) > 0) else -math.inf
            return x / y
        if op == "%":
            if y == 0:
                return math.nan
            if x != x or y != y or x in (math.inf, -math.inf):
                return math.nan
            return x % y
        if op == "//":
            if y == 0:
                if x == 0 or x != x:
                    return math.nan
                return math.inf if (x > 0) == (math.copysign(1, y) > 0) else -math.inf
            q = x / y
            if q != q or q in (math.inf, -math.inf):
                return q
            return float(math.floor(q))
        if op == "^":
            try:
                return math.pow(x, y)
            except (OverflowError, ValueError):
                return math.inf if x > 0 else math.nan
        raise AssertionError(op)

    def concat(self, a, b, line):
        if (isinstance(a, str) or type(a) is float) and (isinstance(b, str) or type(b) is float):
            return self.tostr(a) + self.tostr(b)
        for v in (a, b):
            if isinstance(v, LuaTable) and v.meta is not None:
                h = v.meta.d.get("__concat")
                if h is not None:
                    return self.first(self.call(h, [a, b]))
        bad = a if not (isinstance(a, str) or type(a) is float) else b
        self.err("attempt to concatenate a %s value" % lua_type(bad), line)

    def less(self, a, b, line, orequal=False):
        if type(a) is float and type(b) is float:
            return a <= b if orequal else a < b
        if isinstance(a, str) and isinstance(b, str):
            return a <= b if orequal else a < b
        name = "__le" if orequal else "__lt"
        for v in (a, b):
            if isinstance(v, LuaTable) and v.meta is not None:
                h = v.meta.d.get(name)
                if h is not None:
                    return truthy(self.first(self.call(h, [a, b])))
        self.err("attempt to compare %s with %s" % (lua_type(a), lua_type(b)), line)

    def length(self, v, line):
        if isinstance(v, str):
            return float(len(v))
        if isinstance(v, LuaTable):
            if v.meta is not None:
                h = v.meta.d.get("__len")
                if h is not None:
                    return self.first(self.call(h, [v]))
            return float(v.length())
        self.err("attempt to get length of a %s value" % lua_type(v), line)


    def compile_chunk(self, src, chunk):
        p = P(src, chunk)
        body = p.chunk_body()
        return self.c_block(body, chunk)

    def c_block(self, stmts, chunk):
        fns = [self.c_stmt(s, chunk) for s in stmts]
        n = len(fns)
        if n == 0:
            return lambda sc: None
        if n == 1:
            return fns[0]

        def run(sc):
            for f in fns:
                r = f(sc)
                if r is not None:
                    return r
            return None
        return run

    def c_multi(self, e, chunk):
        k = e[0]
        if k == "call":
            fe = self.c_expr(e[1], chunk)
            args = self.c_args(e[2], chunk)
            line = e[3]
            interp = self

            def call(sc):
                f = fe(sc)
                a = args(sc)
                interp.cur = (chunk, line)
                return interp.call(f, a, line)
            return call
        if k == "method":
            oe = self.c_expr(e[1], chunk)
            name = e[2]
            args = self.c_args(e[3], chunk)
            line = e[4]
            interp = self

            def mcall(sc):
                o = oe(sc)
                interp.cur = (chunk, line)
                f = interp.index(o, name, line)
                a = [o] + args(sc)
                interp.cur = (chunk, line)
                return interp.call(f, a, line)
            return mcall
        if k == "vararg":
            return lambda sc: list(self.find_vararg(sc))
        ce = self.c_expr(e, chunk)
        return lambda sc: [ce(sc)]

    def find_vararg(self, sc):
        s = sc
        while s is not None:
            if "..." in s.v:
                return s.v["..."]
            s = s.p
        return []

    def c_args(self, exprs, chunk):
        if not exprs:
            return lambda sc: []
        last = exprs[-1]
        multi = last[0] in ("call", "method", "vararg")
        firsts = [self.c_expr(e, chunk) for e in (exprs[:-1] if multi else exprs)]
        lastf = self.c_multi(last, chunk) if multi else None

        def args(sc):
            r = [f(sc) for f in firsts]
            if lastf is not None:
                r.extend(lastf(sc))
            return r
        return args

    def c_expr(self, e, chunk):
        k = e[0]
        interp = self
        if k == "nil":
            return lambda sc: None
        if k == "true":
            return lambda sc: True
        if k == "false":
            return lambda sc: False
        if k == "num" or k == "str":
            v = e[1]
            return lambda sc: v
        if k == "vararg":
            def va(sc):
                r = interp.find_vararg(sc)
                return r[0] if r else None
            return va
        if k == "name":
            name = e[1]

            def nm(sc):
                s = sc
                while s is not None:
                    d = s.v
                    if name in d:
                        return d[name]
                    s = s.p
                return interp.G.d.get(name)
            return nm
        if k == "paren":
            inner = self.c_expr(e[1], chunk)
            return inner
        if k == "index":
            oe = self.c_expr(e[1], chunk)
            ke = self.c_expr(e[2], chunk)
            line = e[3] if len(e) > 3 else 0

            def idx(sc):
                o = oe(sc)
                key = ke(sc)
                if isinstance(o, LuaTable):
                    v = o.d.get(nkey(key))
                    if v is not None or o.meta is None:
                        return v
                interp.cur = (chunk, line)
                return interp.index(o, key, line)
            return idx
        if k == "call" or k == "method":
            m = self.c_multi(e, chunk)

            def c1(sc):
                r = m(sc)
                return r[0] if r else None
            return c1
        if k == "func":
            return self.c_func(e, chunk)
        if k == "and":
            a = self.c_expr(e[1], chunk)
            b = self.c_expr(e[2], chunk)

            def andf(sc):
                v = a(sc)
                if v is None or v is False:
                    return v
                return b(sc)
            return andf
        if k == "or":
            a = self.c_expr(e[1], chunk)
            b = self.c_expr(e[2], chunk)

            def orf(sc):
                v = a(sc)
                if v is not None and v is not False:
                    return v
                return b(sc)
            return orf
        if k == "ifexpr":
            c = self.c_expr(e[1], chunk)
            a = self.c_expr(e[2], chunk)
            b = self.c_expr(e[3], chunk)
            return lambda sc: a(sc) if truthy(c(sc)) else b(sc)
        if k == "unop":
            op = e[1]
            a = self.c_expr(e[2], chunk)
            line = e[3]
            if op == "not":
                return lambda sc: not truthy(a(sc))
            if op == "-":
                def neg(sc):
                    v = a(sc)
                    if type(v) is float:
                        return -v
                    n = to_num(v) if not isinstance(v, bool) else None
                    if n is None:
                        if isinstance(v, LuaTable) and v.meta is not None:
                            h = v.meta.d.get("__unm")
                            if h is not None:
                                return interp.first(interp.call(h, [v, v]))
                        interp.err("attempt to perform arithmetic (unm) on %s" % lua_type(v), line)
                    return -n
                return neg
            if op == "#":
                def ln(sc):
                    interp.cur = (chunk, line)
                    return interp.length(a(sc), line)
                return ln
        if k == "binop":
            op, line = e[1], e[4]
            a = self.c_expr(e[2], chunk)
            b = self.c_expr(e[3], chunk)
            if op in ("+", "-", "*", "/", "%", "//", "^"):
                def ar(sc):
                    x = a(sc)
                    y = b(sc)
                    interp.cur = (chunk, line)
                    return interp.arith(op, x, y, line)
                return ar
            if op == "..":
                def cc(sc):
                    x = a(sc)
                    y = b(sc)
                    interp.cur = (chunk, line)
                    return interp.concat(x, y, line)
                return cc
            if op == "==":
                return lambda sc: interp.eq(a(sc), b(sc))
            if op == "~=":
                return lambda sc: not interp.eq(a(sc), b(sc))
            if op == "<":
                def lt(sc):
                    x = a(sc)
                    y = b(sc)
                    interp.cur = (chunk, line)
                    return interp.less(x, y, line)
                return lt
            if op == ">":
                def gt(sc):
                    x = a(sc)
                    y = b(sc)
                    interp.cur = (chunk, line)
                    return interp.less(y, x, line)
                return gt
            if op == "<=":
                def le(sc):
                    x = a(sc)
                    y = b(sc)
                    interp.cur = (chunk, line)
                    return interp.less(x, y, line, True)
                return le
            if op == ">=":
                def ge(sc):
                    x = a(sc)
                    y = b(sc)
                    interp.cur = (chunk, line)
                    return interp.less(y, x, line, True)
                return ge
        if k == "table":
            items = []
            for it in e[1]:
                if it[0] == "pos":
                    items.append(("pos", it[1][0] in ("call", "method", "vararg"), self.c_multi(it[1], chunk) if it[1][0] in ("call", "method", "vararg") else self.c_expr(it[1], chunk)))
                else:
                    items.append(("kv", self.c_expr(it[1], chunk), self.c_expr(it[2], chunk)))
            last_pos = max([i for i, it in enumerate(items) if it[0] == "pos"] or [-1])

            def tbl(sc):
                t = LuaTable()
                n = 0
                for i, it in enumerate(items):
                    if it[0] == "pos":
                        if it[1] and i == last_pos:
                            for v in it[2](sc):
                                n += 1
                                if v is not None:
                                    t.d[float(n)] = v
                        else:
                            v = it[2](sc)
                            if it[1]:
                                v = v[0] if v else None
                            n += 1
                            if v is not None:
                                t.d[float(n)] = v
                    else:
                        key = it[1](sc)
                        if key is None:
                            interp.err("table index is nil")
                        val = it[2](sc)
                        if val is not None:
                            t.d[nkey(key)] = val
                t.border = 0
                return t
            return tbl
        raise AssertionError("bad expr " + str(k))

    def c_func(self, e, chunk):
        params, vararg, body, name = e[2], e[3], e[4], e[5]
        bf = self.c_block(body, chunk)
        interp = self
        return lambda sc: LuaFunction(params, vararg, bf, sc, name, interp)

    def c_assign_target(self, t, chunk):
        interp = self
        if t[0] == "name":
            name = t[1]

            def setn(sc, v):
                s = sc
                while s is not None:
                    d = s.v
                    if name in d:
                        d[name] = v
                        return
                    s = s.p
                if v is None:
                    interp.G.d.pop(name, None)
                else:
                    interp.G.d[name] = v
            return setn
        oe = self.c_expr(t[1], chunk)
        ke = self.c_expr(t[2], chunk)
        line = t[3] if len(t) > 3 else 0

        def seti(sc, v, pre=None):
            o = oe(sc) if pre is None else pre[0]
            k = ke(sc) if pre is None else pre[1]
            interp.cur = (chunk, line)
            interp.setindex(o, k, v, line)
        seti.parts = (oe, ke)
        return seti

    def c_stmt(self, s, chunk):
        k = s[0]
        interp = self
        line = s[1]
        if k == "local":
            names = s[2]
            exprs = s[3]
            if len(names) == 1 and len(exprs) == 1:
                nm = names[0]
                ef = self.c_expr(exprs[0], chunk)

                def loc1(sc):
                    interp.cur = (chunk, line)
                    sc.v[nm] = ef(sc)
                return loc1
            ef = self.c_args(exprs, chunk)

            def loc(sc):
                interp.cur = (chunk, line)
                vals = ef(sc)
                for i, nm in enumerate(names):
                    sc.v[nm] = vals[i] if i < len(vals) else None
            return loc
        if k == "localfunc":
            nm = s[2]
            ff = self.c_func(s[3], chunk)

            def lf(sc):
                sc.v[nm] = None
                sc.v[nm] = ff(sc)
            return lf
        if k == "assign":
            targets = [self.c_assign_target(t, chunk) for t in s[2]]
            ef = self.c_args(s[3], chunk)
            if len(targets) == 1:
                tg = targets[0]

                def as1(sc):
                    interp.cur = (chunk, line)
                    vals = ef(sc)
                    tg(sc, vals[0] if vals else None)
                return as1

            def asn(sc):
                interp.cur = (chunk, line)
                vals = ef(sc)
                pres = []
                for tg in targets:
                    if hasattr(tg, "parts"):
                        pres.append((tg.parts[0](sc), tg.parts[1](sc)))
                    else:
                        pres.append(None)
                for i, tg in enumerate(targets):
                    v = vals[i] if i < len(vals) else None
                    if pres[i] is None:
                        tg(sc, v)
                    else:
                        tg(sc, v, pres[i])
            return asn
        if k == "compound":
            op = s[2]
            target = s[3]
            tf = self.c_assign_target(target, chunk)
            cur = self.c_expr(target, chunk)
            rf = self.c_expr(s[4], chunk)

            def comp(sc):
                interp.cur = (chunk, line)
                x = cur(sc)
                y = rf(sc)
                if op == "..":
                    r = interp.concat(x, y, line)
                else:
                    r = interp.arith(op, x, y, line)
                tf(sc, r)
            return comp
        if k == "callstat":
            m = self.c_multi(s[2], chunk)

            def cs(sc):
                m(sc)
            return cs
        if k == "do":
            b = self.c_block(s[2], chunk)
            return lambda sc: b(Scope(sc))
        if k == "while":
            cf = self.c_expr(s[2], chunk)
            b = self.c_block(s[3], chunk)

            def wh(sc):
                while truthy(cf(sc)):
                    interp.steps += 1
                    if interp.steps > interp.step_limit:
                        interp.watchdog()
                    r = b(Scope(sc))
                    if r is not None:
                        if r is BRK:
                            break
                        if r is CNT:
                            continue
                        return r
            return wh
        if k == "repeat":
            b = self.c_block(s[2], chunk)
            cf = self.c_expr(s[3], chunk)

            def rp(sc):
                while True:
                    interp.steps += 1
                    if interp.steps > interp.step_limit:
                        interp.watchdog()
                    inner = Scope(sc)
                    r = b(inner)
                    if r is not None:
                        if r is BRK:
                            break
                        if r is not CNT:
                            return r
                    if truthy(cf(inner)):
                        break
            return rp
        if k == "if":
            clauses = [(self.c_expr(c, chunk), self.c_block(b, chunk)) for c, b in s[2]]
            els = self.c_block(s[3], chunk) if s[3] is not None else None

            def iff(sc):
                for c, b in clauses:
                    if truthy(c(sc)):
                        return b(Scope(sc))
                if els is not None:
                    return els(Scope(sc))
                return None
            return iff
        if k == "fornum":
            var = s[2]
            a = self.c_expr(s[3], chunk)
            b = self.c_expr(s[4], chunk)
            c = self.c_expr(s[5], chunk) if s[5] is not None else (lambda sc: 1.0)
            body = self.c_block(s[6], chunk)

            def fn(sc):
                interp.cur = (chunk, line)
                x, y, z = a(sc), b(sc), c(sc)
                for v in (x, y, z):
                    if type(v) is not float:
                        interp.err("'for' initial value must be a number", line)
                if z == 0:
                    interp.err("'for' step is zero", line)
                i = x
                while (z > 0 and i <= y) or (z < 0 and i >= y):
                    interp.steps += 1
                    if interp.steps > interp.step_limit:
                        interp.watchdog()
                    inner = Scope(sc)
                    inner.v[var] = i
                    r = body(inner)
                    if r is not None:
                        if r is BRK:
                            break
                        if r is not CNT:
                            return r
                    i += z
            return fn
        if k == "forin":
            names = s[2]
            ef = self.c_args(s[3], chunk)
            body = self.c_block(s[4], chunk)

            def fi(sc):
                interp.cur = (chunk, line)
                vals = ef(sc)
                f = vals[0] if vals else None
                st = vals[1] if len(vals) > 1 else None
                ctl = vals[2] if len(vals) > 2 else None
                if isinstance(f, LuaTable):
                    f, st, ctl = interp.G.get("next"), f, None
                while True:
                    interp.cur = (chunk, line)
                    rs = interp.call(f, [st, ctl], line)
                    first = rs[0] if rs else None
                    if first is None:
                        break
                    ctl = first
                    inner = Scope(sc)
                    for i, nm in enumerate(names):
                        inner.v[nm] = rs[i] if i < len(rs) else None
                    r = body(inner)
                    if r is not None:
                        if r is BRK:
                            break
                        if r is not CNT:
                            return r
            return fi
        if k == "return":
            exprs = s[2]
            ef = self.c_args(exprs, chunk)

            def ret(sc):
                interp.cur = (chunk, line)
                return ("ret", ef(sc))
            return ret
        if k == "break":
            return lambda sc: BRK
        if k == "continue":
            return lambda sc: CNT
        raise AssertionError("bad stmt " + str(k))


    def reg(self, table, name, fn):
        table.set(name, Builtin(fn, name))

    def new_lib(self, name):
        t = LuaTable()
        self.G.set(name, t)
        return t

    def install(self):
        G = self.G
        interp = self
        reg = self.reg

        def a(args, i, default=None):
            return args[i] if i < len(args) else default

        def check_table(args, i, fname):
            t = a(args, i)
            if not isinstance(t, LuaTable):
                interp.err("bad argument #%d to '%s' (table expected, got %s)" % (i + 1, fname, "no value" if t is None else lua_type(t)))
            return t

        def check_num(args, i, fname, default=None):
            v = a(args, i)
            if v is None and default is not None:
                return default
            n = v if type(v) is float else to_num(v)
            if n is None or isinstance(v, bool):
                interp.err("bad argument #%d to '%s' (number expected, got %s)" % (i + 1, fname, "no value" if v is None else lua_type(v)))
            return n

        def check_str(args, i, fname):
            v = a(args, i)
            if isinstance(v, str):
                return v
            if type(v) is float:
                return fmt_num(v)
            interp.err("bad argument #%d to '%s' (string expected, got %s)" % (i + 1, fname, "no value" if v is None else lua_type(v)))

        G.set("_G", G)
        G.set("_VERSION", "Luau")

        def b_print(args):
            line = "\t".join(interp.tostr(x) for x in args)
            interp.out.append(line)
            sys.stdout.write(line + "\n")
            return []
        reg(G, "print", b_print)

        reg(G, "type", lambda args: [lua_type(a(args, 0))])
        reg(G, "typeof", lambda args: [lua_type(a(args, 0))])
        reg(G, "tostring", lambda args: [interp.tostr(a(args, 0))])

        def b_tonumber(args):
            v = a(args, 0)
            base = a(args, 1)
            if base is None:
                if type(v) is float:
                    return [v]
                return [to_num(v) if isinstance(v, str) else None]
            try:
                return [float(int(str(v).strip(), int(base)))]
            except ValueError:
                return [None]
        reg(G, "tonumber", b_tonumber)

        def b_next(args):
            t = check_table(args, 0, "next")
            k = a(args, 1)
            keys = list(t.d.keys())
            if k is None:
                i = 0
            else:
                try:
                    i = keys.index(nkey(k)) + 1
                except ValueError:
                    interp.err("invalid key to 'next'")
            if i >= len(keys):
                return [None]
            kk = keys[i]
            return [ukey(kk), t.d[kk]]
        reg(G, "next", b_next)

        def b_pairs(args):
            t = a(args, 0)
            if not isinstance(t, LuaTable):
                interp.err("bad argument #1 to 'pairs' (table expected, got %s)" % ("no value" if t is None else lua_type(t)))
            if t.meta is not None and t.meta.d.get("__pairs") is not None:
                return interp.call(t.meta.d["__pairs"], [t])[:3]
            keys = list(t.d.keys())
            state = {"i": 0}

            def it(_args):
                while state["i"] < len(keys):
                    kk = keys[state["i"]]
                    state["i"] += 1
                    if kk in t.d:
                        return [ukey(kk), t.d[kk]]
                return [None]
            return [Builtin(it, "pairs_iter"), t, None]
        reg(G, "pairs", b_pairs)

        def b_ipairs(args):
            t = a(args, 0)

            def it(iargs):
                i = iargs[1] + 1
                v = interp.index(iargs[0], i)
                if v is None:
                    return [None]
                return [i, v]
            return [Builtin(it, "ipairs_iter"), t, 0.0]
        reg(G, "ipairs", b_ipairs)

        def b_select(args):
            n = a(args, 0)
            if n == "#":
                return [float(len(args) - 1)]
            n = int(check_num(args, 0, "select"))
            if n < 0:
                n = len(args) + n
                if n < 1:
                    interp.err("bad argument #1 to 'select' (index out of range)")
                return args[n:]
            if n == 0:
                interp.err("bad argument #1 to 'select' (index out of range)")
            return args[n:]
        reg(G, "select", b_select)

        reg(G, "rawget", lambda args: [check_table(args, 0, "rawget").get(a(args, 1))])

        def b_rawset(args):
            check_table(args, 0, "rawset").set(a(args, 1), a(args, 2))
            return [a(args, 0)]
        reg(G, "rawset", b_rawset)
        reg(G, "rawequal", lambda args: [a(args, 0) is a(args, 1) or (not isinstance(a(args, 0), LuaTable) and interp.eq(a(args, 0), a(args, 1)))])
        reg(G, "rawlen", lambda args: [float(check_table(args, 0, "rawlen").length())])

        def b_setmt(args):
            t = check_table(args, 0, "setmetatable")
            m = a(args, 1)
            if t.frozen:
                interp.err("attempt to modify a readonly table")
            if m is not None and not isinstance(m, LuaTable):
                interp.err("bad argument #2 to 'setmetatable' (nil or table expected)")
            t.meta = m
            return [t]
        reg(G, "setmetatable", b_setmt)

        def b_getmt(args):
            v = a(args, 0)
            if isinstance(v, LuaTable):
                if v.meta is not None and v.meta.d.get("__metatable") is not None:
                    return [v.meta.d["__metatable"]]
                return [v.meta]
            if isinstance(v, str):
                return [interp.string_meta]
            return [None]
        reg(G, "getmetatable", b_getmt)

        def b_error(args):
            msg = a(args, 0)
            level = a(args, 1, 1.0)
            if isinstance(msg, str) and level and level > 0:
                chunk, ln = interp.cur
                msg = "%s:%d: %s" % (chunk, ln, msg)
            raise LuaError(msg)
        reg(G, "error", b_error)

        def b_assert(args):
            v = a(args, 0)
            if not truthy(v):
                msg = a(args, 1, "assertion failed!")
                raise LuaError(msg)
            return args
        reg(G, "assert", b_assert)

        def b_pcall(args):
            f = a(args, 0)
            saved_depth = getattr(interp, "depth", 0)
            saved = interp.cur
            try:
                return [True] + interp.call(f, args[1:])
            except LuaError as ex:
                interp.depth = saved_depth
                interp.cur = saved
                return [False, ex.value]
            except RecursionError:
                interp.depth = saved_depth
                interp.cur = saved
                return [False, "stack overflow"]
        reg(G, "pcall", b_pcall)

        def b_xpcall(args):
            f, h = a(args, 0), a(args, 1)
            saved_depth = getattr(interp, "depth", 0)
            try:
                return [True] + interp.call(f, args[2:])
            except LuaError as ex:
                interp.depth = saved_depth
                return [False] + interp.call(h, [ex.value])
        reg(G, "xpcall", b_xpcall)

        def b_loadstring(args):
            src = check_str(args, 0, "loadstring")
            name = a(args, 1, "=loadstring")
            chunk = str(name).lstrip("=@")
            try:
                body = interp.compile_chunk(src, chunk)
            except (LuaError, LuauError) as ex:
                return [None, str(ex)]
            sc = Scope(None)

            def run_loaded(cargs):
                scope = Scope(sc)
                scope.v["..."] = list(cargs)
                r = body(scope)
                return r[1] if r is not None and r[0] == "ret" else []

            return [Builtin(run_loaded, chunk)]
        reg(G, "loadstring", b_loadstring)
        reg(G, "load", b_loadstring)


        def b_unpack(args):
            t = check_table(args, 0, "unpack")
            i = int(a(args, 1, 1.0))
            j = a(args, 2)
            j = int(j) if j is not None else t.length()
            return [t.get(float(x)) for x in range(i, j + 1)]
        reg(G, "unpack", b_unpack)

        S = self.string_lib
        G.set("string", S)
        self.string_meta.set("__index", S)

        def s_len(args):
            return [float(len(check_str(args, 0, "len")))]
        reg(S, "len", s_len)
        reg(S, "upper", lambda args: [check_str(args, 0, "upper").upper()])
        reg(S, "lower", lambda args: [check_str(args, 0, "lower").lower()])
        reg(S, "reverse", lambda args: [check_str(args, 0, "reverse")[::-1]])

        def s_rep(args):
            s = check_str(args, 0, "rep")
            n = int(check_num(args, 1, "rep"))
            sep = a(args, 2, "")
            if n <= 0:
                return [""]
            return [sep.join([s] * n)]
        reg(S, "rep", s_rep)

        def s_sub(args):
            s = check_str(args, 0, "sub")
            i = int(check_num(args, 1, "sub", 1.0))
            j = a(args, 2)
            j = int(j) if j is not None else -1
            ls = len(s)
            if i < 0:
                i = max(ls + i + 1, 1)
            elif i == 0:
                i = 1
            if j < 0:
                j = ls + j + 1
            elif j > ls:
                j = ls
            if i > j:
                return [""]
            return [s[i - 1:j]]
        reg(S, "sub", s_sub)

        def s_byte(args):
            s = check_str(args, 0, "byte")
            i = int(check_num(args, 1, "byte", 1.0))
            j = a(args, 2)
            j = int(j) if j is not None else i
            ls = len(s)
            if i < 0:
                i = ls + i + 1
            if j < 0:
                j = ls + j + 1
            return [float(ord(c)) for c in s[max(i, 1) - 1:min(j, ls)]]
        reg(S, "byte", s_byte)
        reg(S, "char", lambda args: ["".join(chr(int(x)) for x in args)])

        def s_find(args):
            return str_find_aux(check_str(args, 0, "find"), check_str(args, 1, "find"), a(args, 2), truthy(a(args, 3)), True)
        reg(S, "find", s_find)

        def s_match(args):
            return str_find_aux(check_str(args, 0, "match"), check_str(args, 1, "match"), a(args, 2), False, False)
        reg(S, "match", s_match)

        def s_gmatch(args):
            s = check_str(args, 0, "gmatch")
            pat = check_str(args, 1, "gmatch")
            state = {"pos": 0, "last": -1}

            def it(_a):
                while state["pos"] <= len(s):
                    ms = MatchState(s, pat)
                    e = do_match(ms, state["pos"], 0)
                    if e != -1 and e != state["last"]:
                        st = state["pos"]
                        state["pos"] = state["last"] = e
                        if e == st:
                            state["pos"] = e
                        return captures(ms, st, e)
                    state["pos"] += 1
                return [None]
            return [Builtin(it, "gmatch_iter")]
        reg(S, "gmatch", s_gmatch)

        def s_gsub(args):
            s = check_str(args, 0, "gsub")
            pat = check_str(args, 1, "gsub")
            repl = a(args, 2)
            maxn = a(args, 3)
            anchor = pat.startswith("^")
            p0 = 1 if anchor else 0
            out = []
            pos = 0
            n = 0
            while maxn is None or n < maxn:
                ms = MatchState(s, pat)
                e = do_match(ms, pos, p0)
                if e != -1:
                    n += 1
                    whole = s[pos:e]
                    caps = captures(ms, pos, e)
                    if isinstance(repl, str):
                        r = []
                        i = 0
                        while i < len(repl):
                            c = repl[i]
                            if c == "%":
                                i += 1
                                d = repl[i] if i < len(repl) else ""
                                if d == "0":
                                    r.append(whole)
                                elif d.isdigit():
                                    idx = int(d) - 1
                                    r.append(interp.tostr(caps[idx] if idx < len(caps) else whole if idx == 0 else None))
                                elif d == "%":
                                    r.append("%")
                                else:
                                    interp.err("invalid use of '%' in replacement string")
                            else:
                                r.append(c)
                            i += 1
                        out.append("".join(r))
                    elif isinstance(repl, LuaTable):
                        v = interp.index(repl, caps[0])
                        out.append(whole if not truthy(v) else interp.tostr(v))
                    elif repl is not None:
                        v = interp.first(interp.call(repl, caps))
                        out.append(whole if not truthy(v) else interp.tostr(v))
                    else:
                        interp.err("bad argument #3 to 'gsub' (string/function/table expected)")
                if e != -1 and e > pos:
                    pos = e
                elif pos < len(s):
                    out.append(s[pos])
                    pos += 1
                else:
                    break
                if anchor:
                    break
            out.append(s[pos:])
            return ["".join(out), float(n)]
        reg(S, "gsub", s_gsub)

        def s_format(args):
            fmt = check_str(args, 0, "format")
            out = []
            i = 0
            argi = 1
            while i < len(fmt):
                c = fmt[i]
                if c != "%":
                    out.append(c)
                    i += 1
                    continue
                i += 1
                if i < len(fmt) and fmt[i] == "%":
                    out.append("%")
                    i += 1
                    continue
                j = i
                while j < len(fmt) and fmt[j] in "-+ #0123456789.":
                    j += 1
                spec = fmt[i:j]
                conv = fmt[j] if j < len(fmt) else ""
                i = j + 1
                v = args[argi] if argi < len(args) else None
                if argi >= len(args):
                    interp.err("bad argument #%d to 'format' (no value)" % (argi + 1))
                argi += 1
                if conv in "di":
                    n = v if type(v) is float else to_num(v)
                    if n is None:
                        interp.err("bad argument #%d to 'format' (number expected, got %s)" % (argi, lua_type(v)))
                    if n != int(n):
                        interp.err("bad argument #%d to 'format' (number has no integer representation)" % argi)
                    out.append(("%" + spec + "d") % int(n))
                elif conv in "uc":
                    out.append(chr(int(v)) if conv == "c" else ("%" + spec + "d") % int(v))
                elif conv in "xXo":
                    out.append(("%" + spec + conv) % int(v))
                elif conv in "eEfFgG":
                    n = v if type(v) is float else to_num(v)
                    if n is None:
                        interp.err("bad argument #%d to 'format' (number expected, got %s)" % (argi, lua_type(v)))
                    out.append(("%" + spec + conv) % n)
                elif conv == "s":
                    out.append(("%" + spec + "s") % interp.tostr(v))
                elif conv == "q":
                    sv = interp.tostr(v)
                    out.append('"' + sv.replace("\\", "\\\\").replace('"', '\\"').replace("\n", "\\n") + '"')
                else:
                    interp.err("invalid option '%%%s' to 'format'" % conv)
            return ["".join(out)]
        reg(S, "format", s_format)

        def s_split(args):
            s = check_str(args, 0, "split")
            sep = a(args, 1, ",")
            t = LuaTable()
            parts = s.split(sep) if sep != "" else list(s)
            for p in parts:
                t.append(p)
            return [t]
        reg(S, "split", s_split)

        TB = self.new_lib("table")

        def t_insert(args):
            t = check_table(args, 0, "insert")
            if t.frozen:
                interp.err("attempt to modify a readonly table")
            if len(args) == 2:
                t.append(args[1])
            elif len(args) == 3:
                pos = int(check_num(args, 1, "insert"))
                n = t.length()
                if pos < 1 or pos > n + 1:
                    interp.err("bad argument #2 to 'insert' (position out of bounds)")
                for i in range(n, pos - 1, -1):
                    t.d[float(i + 1)] = t.d[float(i)]
                t.d[float(pos)] = args[2]
                t.border = 0
            else:
                interp.err("wrong number of arguments to 'insert'")
            return []
        reg(TB, "insert", t_insert)

        def t_remove(args):
            t = check_table(args, 0, "remove")
            if t.frozen:
                interp.err("attempt to modify a readonly table")
            n = t.length()
            pos = a(args, 1)
            if pos is None:
                if n == 0:
                    return [None]
                v = t.d.pop(float(n), None)
                t.border = n - 1
                return [v]
            pos = int(pos)
            if n == 0 and pos in (0, n):
                return [t.get(float(pos))]
            if pos < 1 or pos > n + 1:
                interp.err("bad argument #2 to 'remove' (position out of bounds)")
            v = t.d.get(float(pos))
            for i in range(pos, n):
                nv = t.d.get(float(i + 1))
                if nv is None:
                    t.d.pop(float(i), None)
                else:
                    t.d[float(i)] = nv
            t.d.pop(float(n), None)
            t.border = 0
            return [v]
        reg(TB, "remove", t_remove)

        def t_concat(args):
            t = check_table(args, 0, "concat")
            sep = a(args, 1, "")
            i = int(a(args, 2, 1.0))
            j = a(args, 3)
            j = int(j) if j is not None else t.length()
            parts = []
            for x in range(i, j + 1):
                v = t.get(float(x))
                if not (isinstance(v, str) or type(v) is float):
                    interp.err("invalid value (at index %d) in table for 'concat'" % x)
                parts.append(interp.tostr(v))
            return [sep.join(parts)]
        reg(TB, "concat", t_concat)

        def t_sort(args):
            import functools
            t = check_table(args, 0, "sort")
            cmp = a(args, 1)
            n = t.length()
            vals = [t.d[float(i)] for i in range(1, n + 1)]
            if cmp is None:
                def key(x, y):
                    return -1 if interp.less(x, y, 0) else (1 if interp.less(y, x, 0) else 0)
            else:
                def key(x, y):
                    if truthy(interp.first(interp.call(cmp, [x, y]))):
                        return -1
                    if truthy(interp.first(interp.call(cmp, [y, x]))):
                        return 1
                    return 0
            vals.sort(key=functools.cmp_to_key(key))
            for i, v in enumerate(vals):
                t.d[float(i + 1)] = v
            return []
        reg(TB, "sort", t_sort)
        reg(TB, "unpack", b_unpack)

        def t_find(args):
            t = check_table(args, 0, "find")
            v = a(args, 1)
            init = int(a(args, 2, 1.0))
            for i in range(init, t.length() + 1):
                if interp.eq(t.get(float(i)), v):
                    return [float(i)]
            return [None]
        reg(TB, "find", t_find)

        def t_clear(args):
            t = check_table(args, 0, "clear")
            t.d.clear()
            t.border = 0
            return []
        reg(TB, "clear", t_clear)

        def t_pack(args):
            t = LuaTable()
            for v in args:
                t.append(v) if v is not None else None
            for i, v in enumerate(args):
                if v is not None:
                    t.d[float(i + 1)] = v
            t.d["n"] = float(len(args))
            return [t]
        reg(TB, "pack", t_pack)

        def t_create(args):
            t = LuaTable()
            n = int(check_num(args, 0, "create"))
            v = a(args, 1)
            if v is not None:
                for i in range(1, n + 1):
                    t.d[float(i)] = v
            return [t]
        reg(TB, "create", t_create)

        def t_clone(args):
            t = check_table(args, 0, "clone")
            n = LuaTable()
            n.d = dict(t.d)
            n.meta = t.meta
            return [n]
        reg(TB, "clone", t_clone)

        def t_freeze(args):
            t = check_table(args, 0, "freeze")
            t.frozen = True
            return [t]
        reg(TB, "freeze", t_freeze)
        reg(TB, "isfrozen", lambda args: [check_table(args, 0, "isfrozen").frozen])

        def t_move(args):
            a1 = check_table(args, 0, "move")
            f, e, t = int(args[1]), int(args[2]), int(args[3])
            a2 = args[4] if len(args) > 4 and args[4] is not None else a1
            if t > e or t <= f or a1 is not a2:
                for i in range(0, e - f + 1):
                    a2.set(float(t + i), a1.get(float(f + i)))
            else:
                for i in range(e - f, -1, -1):
                    a2.set(float(t + i), a1.get(float(f + i)))
            return [a2]
        reg(TB, "move", t_move)

        M = self.new_lib("math")
        M.set("pi", math.pi)
        M.set("huge", math.inf)
        reg(M, "floor", lambda args: [float(math.floor(check_num(args, 0, "floor")))] if math.isfinite(check_num(args, 0, "floor")) else [check_num(args, 0, "floor")])
        reg(M, "ceil", lambda args: [float(math.ceil(check_num(args, 0, "ceil")))] if math.isfinite(check_num(args, 0, "ceil")) else [check_num(args, 0, "ceil")])
        reg(M, "abs", lambda args: [abs(check_num(args, 0, "abs"))])
        reg(M, "sqrt", lambda args: [math.sqrt(check_num(args, 0, "sqrt")) if check_num(args, 0, "sqrt") >= 0 else math.nan])
        reg(M, "sin", lambda args: [math.sin(check_num(args, 0, "sin"))])
        reg(M, "cos", lambda args: [math.cos(check_num(args, 0, "cos"))])
        reg(M, "tan", lambda args: [math.tan(check_num(args, 0, "tan"))])
        reg(M, "atan", lambda args: [math.atan(check_num(args, 0, "atan"))])
        reg(M, "atan2", lambda args: [math.atan2(check_num(args, 0, "atan2"), check_num(args, 1, "atan2"))])
        reg(M, "exp", lambda args: [math.exp(check_num(args, 0, "exp"))])
        reg(M, "deg", lambda args: [math.degrees(check_num(args, 0, "deg"))])
        reg(M, "rad", lambda args: [math.radians(check_num(args, 0, "rad"))])
        reg(M, "fmod", lambda args: [math.fmod(check_num(args, 0, "fmod"), check_num(args, 1, "fmod"))])

        def m_log(args):
            x = check_num(args, 0, "log")
            b = a(args, 1)
            if x <= 0:
                return [-math.inf if x == 0 else math.nan]
            return [math.log(x) if b is None else math.log(x, b)]
        reg(M, "log", m_log)
        reg(M, "pow", lambda args: [math.pow(check_num(args, 0, "pow"), check_num(args, 1, "pow"))])

        def m_max(args):
            vals = [check_num(args, i, "max") for i in range(len(args))]
            if not vals:
                interp.err("bad argument #1 to 'max' (number expected, got no value)")
            return [max(vals)]
        reg(M, "max", m_max)

        def m_min(args):
            vals = [check_num(args, i, "min") for i in range(len(args))]
            if not vals:
                interp.err("bad argument #1 to 'min' (number expected, got no value)")
            return [min(vals)]
        reg(M, "min", m_min)

        def m_modf(args):
            x = check_num(args, 0, "modf")
            f, i = math.modf(x)
            return [i, f]
        reg(M, "modf", m_modf)

        def m_clamp(args):
            x, lo, hi = check_num(args, 0, "clamp"), check_num(args, 1, "clamp"), check_num(args, 2, "clamp")
            if lo > hi:
                interp.err("max must be greater than min")
            return [min(max(x, lo), hi)]
        reg(M, "clamp", m_clamp)
        reg(M, "sign", lambda args: [(1.0 if check_num(args, 0, "sign") > 0 else (-1.0 if check_num(args, 0, "sign") < 0 else 0.0))])

        def m_round(args):
            x = check_num(args, 0, "round")
            return [float(math.floor(x + 0.5)) if x >= 0 else -float(math.floor(-x + 0.5))]
        reg(M, "round", m_round)

        rng = random.Random(1234)

        def m_random(args):
            if not args:
                return [rng.random()]
            if len(args) == 1:
                return [float(rng.randint(1, int(args[0])))]
            return [float(rng.randint(int(args[0]), int(args[1])))]
        reg(M, "random", m_random)

        def m_seed(args):
            rng.seed(a(args, 0, 0))
            return []
        reg(M, "randomseed", m_seed)

        O = self.new_lib("os")
        reg(O, "time", lambda args: [float(int(time.time()))] if not args or args[0] is None else [float(int(time.mktime(time.struct_time((int(args[0].get("year")), int(args[0].get("month")), int(args[0].get("day")), int(args[0].get("hour") or 12), int(args[0].get("min") or 0), int(args[0].get("sec") or 0), 0, 0, -1)))))])
        reg(O, "clock", lambda args: [interp.clock + time.process_time()])

        def o_date(args):
            fmt = a(args, 0, "%c")
            t = a(args, 1)
            tt = time.gmtime(t) if t is not None else time.gmtime()
            if fmt.startswith("!"):
                fmt = fmt[1:]
            if fmt.startswith("*t"):
                r = LuaTable()
                for k, v in (("year", tt.tm_year), ("month", tt.tm_mon), ("day", tt.tm_mday), ("hour", tt.tm_hour), ("min", tt.tm_min), ("sec", tt.tm_sec), ("wday", (tt.tm_wday + 1) % 7 + 1), ("yday", tt.tm_yday)):
                    r.set(k, float(v))
                return [r]
            return [time.strftime(fmt, tt)]
        reg(O, "date", o_date)

        B = self.new_lib("bit32")
        M32 = 0xffffffff
        reg(B, "band", lambda args: [float(__import__("functools").reduce(lambda x, y: x & y, [int(v) & M32 for v in args], M32))])
        reg(B, "bor", lambda args: [float(__import__("functools").reduce(lambda x, y: x | y, [int(v) & M32 for v in args], 0))])
        reg(B, "bxor", lambda args: [float(__import__("functools").reduce(lambda x, y: x ^ y, [int(v) & M32 for v in args], 0))])
        reg(B, "bnot", lambda args: [float((~int(args[0])) & M32)])
        reg(B, "lshift", lambda args: [float((int(args[0]) << int(args[1])) & M32)])
        reg(B, "rshift", lambda args: [float((int(args[0]) & M32) >> int(args[1]))])

        def b_rot(args, left):
            x = int(args[0]) & M32
            n = int(args[1]) % 32
            if not left:
                n = (32 - n) % 32
            return [float(((x << n) | (x >> (32 - n))) & M32) if n else float(x)]
        reg(B, "lrotate", lambda args: b_rot(args, True))
        reg(B, "rrotate", lambda args: b_rot(args, False))

        def b_arshift(args):
            x = int(args[0]) & M32
            n = int(args[1])
            if x & 0x80000000:
                x = x - 0x100000000
            return [float((x >> n) & M32)] if n >= 0 else [float((x << -n) & M32)]
        reg(B, "arshift", b_arshift)
        reg(B, "btest", lambda args: [(__import__("functools").reduce(lambda x, y: x & y, [int(v) & M32 for v in args], M32)) != 0])

        def b_extract(args):
            n = int(args[0]) & M32
            f = int(args[1])
            w = int(args[2]) if len(args) > 2 and args[2] is not None else 1
            return [float((n >> f) & ((1 << w) - 1))]
        reg(B, "extract", b_extract)

        def b_replace(args):
            n = int(args[0]) & M32
            v = int(args[1])
            f = int(args[2])
            w = int(args[3]) if len(args) > 3 and args[3] is not None else 1
            mask = ((1 << w) - 1) << f
            return [float((n & ~mask & M32) | ((v << f) & mask))]
        reg(B, "replace", b_replace)

        def b_countlz(args):
            x = int(args[0]) & M32
            return [float(32 - x.bit_length())]
        reg(B, "countlz", b_countlz)

        def b_countrz(args):
            x = int(args[0]) & M32
            if x == 0:
                return [32.0]
            return [float((x & -x).bit_length() - 1)]
        reg(B, "countrz", b_countrz)
        reg(B, "byteswap", lambda args: [float(int.from_bytes((int(args[0]) & M32).to_bytes(4, "little"), "big"))])

        TK = self.new_lib("task")

        def push(delay, kind, payload, targs):
            interp.seq += 1
            interp.queue.append((interp.clock + delay, interp.seq, kind, payload, targs))
            interp.queue.sort(key=lambda x: (x[0], x[1]))

        def t_spawn(args):
            co = Co(interp, args[0], args[1:])
            co.started = True
            co.resume()
            return [co]
        reg(TK, "spawn", t_spawn)

        def t_defer(args):
            co = Co(interp, args[0], args[1:])
            co.started = True
            push(0.0, "resume", co, [])
            return [co]
        reg(TK, "defer", t_defer)

        def t_delay(args):
            co = Co(interp, args[1], args[2:])
            co.started = True
            push(float(args[0]), "resume", co, [])
            return [co]
        reg(TK, "delay", t_delay)

        CO = self.new_lib("coroutine")

        def co_arg(args, name):
            co = a(args, 0)
            if not isinstance(co, Co):
                interp.err("bad argument #1 to '%s' (coroutine expected)" % name)
            return co

        def co_create(args):
            f = a(args, 0)
            if not isinstance(f, (LuaFunction, Builtin)):
                interp.err("bad argument #1 to 'create' (function expected)")
            return [Co(interp, f, [], True)]
        reg(CO, "create", co_create)

        def co_resume(args):
            co = co_arg(args, "resume")
            if co.done:
                return [False, "cannot resume dead coroutine"]
            if co is interp.current_co:
                return [False, "cannot resume non-suspended coroutine"]
            if not co.started:
                co.started = True
                co.args = list(args[1:])
            else:
                co.transfer = list(args[1:])
            co.yielded = []
            co.resume()
            if co.done and co.error is not None:
                err = co.error
                return [False, err.value if isinstance(err, LuaError) else str(err)]
            return [True] + list(co.yielded)
        reg(CO, "resume", co_resume)

        def co_yield(args):
            co = interp.current_co
            if co is None or not co.protect:
                interp.err("attempt to yield from outside a coroutine")
            co.yielded = list(args)
            co.pause()
            return list(co.transfer)
        reg(CO, "yield", co_yield)

        def co_status(args):
            co = co_arg(args, "status")
            if co.done:
                return ["dead"]
            if co is interp.current_co:
                return ["running"]
            return ["suspended"]
        reg(CO, "status", co_status)

        def co_wrap(args):
            f = a(args, 0)
            if not isinstance(f, (LuaFunction, Builtin)):
                interp.err("bad argument #1 to 'wrap' (function expected)")
            co = Co(interp, f, [], True)

            def runner(call_args):
                res = co_resume([co] + list(call_args))
                if res[0] is False:
                    raise LuaError(res[1])
                return res[1:]
            return [Builtin(runner, "wrap")]
        reg(CO, "wrap", co_wrap)

        def co_running(args):
            co = interp.current_co
            return [co, False] if co is not None else [None, True]
        reg(CO, "running", co_running)

        def co_isyieldable(args):
            co = interp.current_co
            return [co is not None and co.protect]
        reg(CO, "isyieldable", co_isyieldable)

        def co_close(args):
            co = co_arg(args, "close")
            if co.done or not co.started:
                co.done = True
                return [True]
            return [False, "cannot close a running or suspended coroutine"]
        reg(CO, "close", co_close)

        def t_wait(args):
            dt = float(a(args, 0, 0.03))
            co = interp.current_co
            if co is None:
                interp.advance(dt)
            else:
                push(dt, "resume", co, [])
                co.pause()
            return [dt]
        reg(TK, "wait", t_wait)
        reg(G, "wait", t_wait)
        reg(G, "tick", lambda args: [interp.clock + 1700000000.0])
        reg(G, "time", lambda args: [interp.clock])

        def g_dofile(args):
            return [interp.load_module(check_str(args, 0, "loadmodule"))]
        reg(G, "loadmodule", g_dofile)

        def host_path(args, fname):
            rel = check_str(args, 0, fname)
            if ".." in rel.replace("\\", "/").split("/") or rel.startswith("/"):
                interp.err("bad path for " + fname)
            return os.path.join(interp.root, rel) if rel != "" else interp.root

        reg(G, "hostisfile", lambda args: [os.path.isfile(host_path(args, "hostisfile"))])
        reg(G, "hostisfolder", lambda args: [os.path.isdir(host_path(args, "hostisfolder"))])

        def g_hostlist(args):
            path = host_path(args, "hostlist")
            out = LuaTable()
            try:
                names = sorted(os.listdir(path))
            except OSError:
                names = []
            for nm in names:
                out.append(nm)
            return [out]
        reg(G, "hostlist", g_hostlist)

        def g_stepbudget(args):
            interp.step_limit = int(a(args, 0, 10 ** 15))
            interp.steps = 0
            return []
        reg(G, "stepbudget", g_stepbudget)

        def g_stepmax(args):
            interp.segment_end()
            at = interp.max_segment_at
            return [float(interp.max_segment), "%s:%d" % (at[0], at[1]) if at else ""]
        reg(G, "stepmax", g_stepmax)

        def g_readsource(args):
            rel = check_str(args, 0, "readsource")
            try:
                with open(os.path.join(interp.root, rel), "rb") as fh:
                    return [fh.read().decode("utf-8", "replace")]
            except OSError:
                raise LuaError("cannot read " + rel)
        reg(G, "readsource", g_readsource)

        def to_lua(value):
            if isinstance(value, dict):
                t = LuaTable()
                for k, v in value.items():
                    t.set(k, to_lua(v))
                return t
            if isinstance(value, list):
                t = LuaTable()
                for v in value:
                    t.append(to_lua(v))
                return t
            if isinstance(value, bool) or value is None or isinstance(value, str):
                return value
            return float(value)

        def g_jsondecode(args):
            import json as _json
            text = check_str(args, 0, "jsondecode")
            try:
                return [to_lua(_json.loads(text))]
            except ValueError:
                return [None]
        reg(G, "jsondecode", g_jsondecode)

        def from_lua(value):
            if isinstance(value, LuaTable):
                keys = list(value.d.keys())
                n = value.length()
                if not keys:
                    return []
                if n > 0 and len(keys) == n:
                    return [from_lua(value.d[float(i)]) for i in range(1, n + 1)]
                out = {}
                for k in keys:
                    if isinstance(k, float) and k == int(k):
                        name = str(int(k))
                    else:
                        name = str(k)
                    out[name] = from_lua(value.d[k])
                return out
            if isinstance(value, float) and value == value and abs(value) < 1e15 and value == int(value):
                return int(value)
            return value

        def g_jsonencode(args):
            import json as _json
            return [_json.dumps(from_lua(args[0] if args else None), sort_keys=True, separators=(",", ":"))]
        reg(G, "jsonencode", g_jsonencode)

    def fire(self, kind, payload, targs):
        if kind == "resume":
            payload.resume()
        else:
            Co(self, payload, targs).resume()

    def advance(self, dt):
        target = self.clock + dt
        self.segment_end()
        while self.queue and self.queue[0][0] <= target:
            when, _, kind, payload, targs = self.queue.pop(0)
            self.clock = max(self.clock, when)
            self.segment_end()
            self.fire(kind, payload, targs)
        self.segment_end()
        self.clock = target

    def drain(self):
        guard = 0
        while self.queue and guard < 10000:
            guard += 1
            when, _, kind, payload, targs = self.queue.pop(0)
            self.clock = max(self.clock, when)
            self.fire(kind, payload, targs)

    def load_module(self, rel):
        path = os.path.join(self.root, rel)
        if path in self.chunks:
            return self.chunks[path]
        with open(path, "rb") as fh:
            src = fh.read().decode("utf-8", "replace")
        body = self.compile_chunk(src, os.path.basename(rel))
        sig = body(Scope(None))
        val = sig[1][0] if sig is not None and sig[0] == "ret" and sig[1] else None
        self.chunks[path] = val
        return val

    def run_source(self, src, chunk):
        body = self.compile_chunk(src, chunk)
        sig = body(Scope(None))
        return sig[1] if sig is not None and sig[0] == "ret" else []


def run_tests(root, files, extra_globals=None):
    total_fail = 0
    for f in files:
        it = Interp(root)
        harness = os.path.join(root, "Testing", "run_tests.lua")
        try:
            with open(harness, "rb") as fh:
                it.run_source(fh.read().decode("utf-8"), "run_tests.lua")
            with open(f, "rb") as fh:
                src = fh.read().decode("utf-8")
            it.run_source(src, os.path.basename(f))
            it.drain()
            summary = it.G.get("__summary")
            res = it.call(summary, []) if summary is not None else []
            total_fail += int(res[0]) if res else 0
            for ex in it.thread_errors:
                msg = ex.value if isinstance(ex, LuaError) else repr(ex)
                print("FAIL %s: error in a spawned thread: %s" % (f, msg))
                total_fail += 1
        except LuaError as ex:
            print("FAIL %s: runtime error: %s" % (f, ex.value))
            total_fail += 1
        except LuauError as ex:
            print("FAIL %s: syntax error: %s" % (f, ex))
            total_fail += 1
    return total_fail


def main(argv):
    sys.setrecursionlimit(100000)
    if len(argv) >= 4 and argv[1] == "run":
        root = os.path.abspath(argv[2])
        files = argv[3:]
        fails = run_tests(root, files)
        print("TOTAL FAILURES: %d" % fails)
        return 1 if fails else 0
    if len(argv) >= 3 and argv[1] == "eval":
        it = Interp(os.getcwd())
        with open(argv[2], "rb") as fh:
            it.run_source(fh.read().decode("utf-8"), os.path.basename(argv[2]))
        it.drain()
        return 0
    print("usage: minilua.py run ROOT TESTFILE...  |  minilua.py eval FILE")
    return 2


if __name__ == "__main__":
    threading.stack_size(64 * 1024 * 1024)
    result = []
    th = threading.Thread(target=lambda: result.append(main(sys.argv)))
    th.start()
    th.join()
    sys.exit(result[0] if result else 1)
