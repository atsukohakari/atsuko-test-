import re
import sys

KEYWORDS = {
    "and", "break", "do", "else", "elseif", "end", "false", "for", "function", "if", "in",
    "local", "nil", "not", "or", "repeat", "return", "then", "true", "until", "while",
}

OPS3 = ("...", "..=", "//=")
OPS2 = ("==", "~=", "<=", ">=", "+=", "-=", "*=", "/=", "%=", "^=", "//", "..", "->", "::")
OPS1 = set("+-*/%^#<>=(){}[];:,.&|~?@")

NAME_RE = re.compile(r"[A-Za-z_][A-Za-z_0-9]*")
NUM_RE = re.compile(
    r"0[xX][0-9a-fA-F_]+(?:\.[0-9a-fA-F_]*)?(?:[pP][+-]?[0-9_]+)?"
    r"|0[bB][01_]+"
    r"|(?:[0-9][0-9_]*(?:\.[0-9_]*)?|\.[0-9][0-9_]*)(?:[eE][+-]?[0-9_]+)?"
)
LONG_OPEN_RE = re.compile(r"\[(=*)\[")

COMPOUND = {"+=", "-=", "*=", "/=", "//=", "%=", "^=", "..="}


class LuauError(Exception):
    def __init__(self, msg, line):
        Exception.__init__(self, "%s (line %d)" % (msg, line))
        self.msg = msg
        self.line = line


class Tok(object):
    __slots__ = ("k", "v", "line")

    def __init__(self, k, v, line):
        self.k = k
        self.v = v
        self.line = line

    def __repr__(self):
        return "Tok(%s,%r,%d)" % (self.k, self.v, self.line)


def lex(src, line0=1, comments=None, spans=None):
    toks = []
    i = 0
    n = len(src)
    line = line0
    if src.startswith("#!"):
        j = src.find("\n")
        i = n if j < 0 else j
    while i < n:
        c = src[i]
        if c == "\n":
            line += 1
            i += 1
            continue
        if c in " \t\r\f\v":
            i += 1
            continue
        if c == "-" and src.startswith("--", i):
            m = LONG_OPEN_RE.match(src, i + 2)
            if m:
                eq = m.group(1)
                close = "]" + eq + "]"
                j = src.find(close, m.end())
                if j < 0:
                    raise LuauError("unfinished long comment", line)
                text = src[i:j + len(close)]
                if comments is not None:
                    comments.append((line, "block", text))
                if spans is not None:
                    spans.append((i, j + len(close), text))
                line += text.count("\n")
                i = j + len(close)
            else:
                j = src.find("\n", i)
                if j < 0:
                    j = n
                if comments is not None:
                    comments.append((line, "line", src[i:j].rstrip("\r")))
                if spans is not None:
                    spans.append((i, j, src[i:j]))
                i = j
            continue
        if c.isalpha() or c == "_":
            m = NAME_RE.match(src, i)
            w = m.group(0)
            toks.append(Tok("kw" if w in KEYWORDS else "name", w, line))
            i = m.end()
            continue
        if c.isdigit() or (c == "." and i + 1 < n and src[i + 1].isdigit()):
            m = NUM_RE.match(src, i)
            toks.append(Tok("num", m.group(0), line))
            i = m.end()
            continue
        if c == '"' or c == "'":
            j = i + 1
            while True:
                if j >= n:
                    raise LuauError("unfinished string", line)
                d = src[j]
                if d == "\\":
                    if j + 1 < n and src[j + 1] == "\r" and j + 2 < n and src[j + 2] == "\n":
                        j += 3
                        line += 1
                        continue
                    if j + 1 < n and src[j + 1] == "\n":
                        line += 1
                    if j + 1 < n and src[j + 1] == "z":
                        k = j + 2
                        while k < n and src[k] in " \t\r\n\f\v":
                            if src[k] == "\n":
                                line += 1
                            k += 1
                        j = k
                        continue
                    j += 2
                    continue
                if d == c:
                    break
                if d == "\n":
                    raise LuauError("unfinished string", line)
                j += 1
            toks.append(Tok("str", src[i:j + 1], line))
            i = j + 1
            continue
        if c == "[":
            m = LONG_OPEN_RE.match(src, i)
            if m:
                eq = m.group(1)
                close = "]" + eq + "]"
                j = src.find(close, m.end())
                if j < 0:
                    raise LuauError("unfinished long string", line)
                text = src[i:j + len(close)]
                toks.append(Tok("str", text, line))
                line += text.count("\n")
                i = j + len(close)
                continue
        if c == "`":
            parts = []
            j = i + 1
            start_line = line
            while True:
                if j >= n:
                    raise LuauError("unfinished interpolated string", start_line)
                d = src[j]
                if d == "\\":
                    j += 2
                    continue
                if d == "`":
                    break
                if d == "\n":
                    line += 1
                    j += 1
                    continue
                if d == "{":
                    depth = 1
                    k = j + 1
                    sub_start = k
                    while k < n and depth > 0:
                        e = src[k]
                        if e in "\"'":
                            q = e
                            k += 1
                            while k < n and src[k] != q:
                                if src[k] == "\\":
                                    k += 1
                                k += 1
                            k += 1
                            continue
                        if e == "{":
                            depth += 1
                        elif e == "}":
                            depth -= 1
                            if depth == 0:
                                break
                        k += 1
                    if depth != 0:
                        raise LuauError("unfinished interpolation", line)
                    sub = src[sub_start:k]
                    parts.append(lex(sub, line, None))
                    line += sub.count("\n")
                    j = k + 1
                    continue
                j += 1
            toks.append(Tok("interp", parts, start_line))
            i = j + 1
            continue
        t3 = src[i:i + 3]
        if t3 in OPS3:
            toks.append(Tok("op", t3, line))
            i += 3
            continue
        t2 = src[i:i + 2]
        if t2 in OPS2:
            toks.append(Tok("op", t2, line))
            i += 2
            continue
        if c in OPS1:
            toks.append(Tok("op", c, line))
            i += 1
            continue
        raise LuauError("unexpected character %r" % c, line)
    toks.append(Tok("eof", "<eof>", line))
    return toks


class Var(object):
    __slots__ = ("name", "line", "func", "uses", "writes", "id")

    def __init__(self, name, line, func, vid):
        self.name = name
        self.line = line
        self.func = func
        self.uses = 0
        self.writes = 0
        self.id = vid


class Func(object):
    __slots__ = ("parent", "active", "max_active", "upvals", "line", "name")

    def __init__(self, parent, line, name):
        self.parent = parent
        self.active = 0
        self.max_active = 0
        self.upvals = set()
        self.line = line
        self.name = name


BIN_PRI = {
    "or": (1, 1), "and": (2, 2),
    "<": (3, 3), ">": (3, 3), "<=": (3, 3), ">=": (3, 3), "~=": (3, 3), "==": (3, 3),
    "..": (5, 4), "+": (6, 6), "-": (6, 6), "*": (7, 7), "/": (7, 7), "//": (7, 7), "%": (7, 7),
    "^": (10, 9),
}
UNARY_PRI = 8
BLOCK_END = {"end", "else", "elseif", "until"}


class Parser(object):
    def __init__(self, src):
        self.comments = []
        self.toks = lex(src, 1, self.comments)
        self.p = 0
        self.scopes = []
        self.func = None
        self.vid = 0
        self.all_funcs = []
        self.global_reads = {}
        self.global_writes = {}
        self.locals_all = []
        self.top_decl = {}
        self.calls = 0

    @property
    def tok(self):
        return self.toks[self.p]

    def peek(self, k=1):
        i = self.p + k
        if i >= len(self.toks):
            return self.toks[-1]
        return self.toks[i]

    def err(self, msg, tok=None):
        t = tok or self.tok
        raise LuauError("%s near %r" % (msg, t.v if t.k != "interp" else "`"), t.line)

    def is_op(self, v):
        t = self.toks[self.p]
        return t.k == "op" and t.v == v

    def is_kw(self, v):
        t = self.toks[self.p]
        return t.k == "kw" and t.v == v

    def accept_op(self, v):
        t = self.toks[self.p]
        if t.k == "op" and t.v == v:
            self.p += 1
            return True
        return False

    def accept_kw(self, v):
        t = self.toks[self.p]
        if t.k == "kw" and t.v == v:
            self.p += 1
            return True
        return False

    def expect_op(self, v):
        t = self.toks[self.p]
        if t.k == "op" and t.v == v:
            self.p += 1
            return t
        self.err("expected %r" % v)

    def expect_kw(self, v):
        t = self.toks[self.p]
        if t.k == "kw" and t.v == v:
            self.p += 1
            return t
        self.err("expected %r" % v)

    def expect_name(self):
        t = self.toks[self.p]
        if t.k == "name":
            self.p += 1
            return t
        self.err("expected a name")

    def push_scope(self):
        self.scopes.append([])

    def pop_scope(self, extra=0):
        sc = self.scopes.pop()
        self.func.active -= len(sc) + extra

    def declare(self, name, line):
        self.vid += 1
        v = Var(name, line, self.func, self.vid)
        self.scopes[-1].append(v)
        self.locals_all.append(v)
        f = self.func
        f.active += 1
        if f.active > f.max_active:
            f.max_active = f.active
        if len(self.all_funcs) and f is self.all_funcs[0] and len(self.scopes) == 1:
            self.top_decl.setdefault(name, line)
        return v

    def find(self, name):
        for sc in reversed(self.scopes):
            for v in reversed(sc):
                if v.name == name:
                    return v
        return None

    def use(self, name, line, write=False):
        v = None
        for sc in reversed(self.scopes):
            for x in reversed(sc):
                if x.name == name:
                    v = x
                    break
            if v is not None:
                break
        if v is None:
            d = self.global_writes if write else self.global_reads
            if name not in d:
                d[name] = [line, 0]
            d[name][1] += 1
            return
        if write:
            v.writes += 1
        else:
            v.uses += 1
        f = self.func
        while f is not None and f is not v.func:
            f.upvals.add(v.id)
            f = f.parent

    def bump_active(self, k):
        f = self.func
        f.active += k
        if f.active > f.max_active:
            f.max_active = f.active

    def parse_chunk(self):
        f = Func(None, 1, "<main>")
        self.all_funcs.append(f)
        self.func = f
        self.push_scope()
        self.block()
        if self.tok.k != "eof":
            self.err("unexpected token")
        self.pop_scope()
        return self

    def block_follow(self):
        t = self.tok
        if t.k == "eof":
            return True
        return t.k == "kw" and t.v in BLOCK_END

    def block(self):
        while not self.block_follow():
            last = self.statement()
            self.accept_op(";")
            if last:
                break
        if not self.block_follow():
            self.err("expected end of block")

    def scoped_block(self, extra=0):
        self.push_scope()
        self.block()
        self.pop_scope(extra)

    def statement(self):
        t = self.tok
        if t.k == "kw":
            v = t.v
            if v == "if":
                self.p += 1
                self.expr()
                self.expect_kw("then")
                self.scoped_block()
                while self.is_kw("elseif"):
                    self.p += 1
                    self.expr()
                    self.expect_kw("then")
                    self.scoped_block()
                if self.accept_kw("else"):
                    self.scoped_block()
                self.expect_kw("end")
                return False
            if v == "while":
                self.p += 1
                self.expr()
                self.expect_kw("do")
                self.scoped_block()
                self.expect_kw("end")
                return False
            if v == "do":
                self.p += 1
                self.scoped_block()
                self.expect_kw("end")
                return False
            if v == "for":
                self.p += 1
                n1 = self.expect_name()
                if self.is_op("="):
                    self.p += 1
                    self.expr()
                    self.expect_op(",")
                    self.expr()
                    if self.accept_op(","):
                        self.expr()
                    self.expect_kw("do")
                    self.push_scope()
                    self.bump_active(3)
                    self.declare(n1.v, n1.line)
                    self.block()
                    self.expect_kw("end")
                    self.pop_scope(3)
                    return False
                names = [n1]
                if self.is_op(":"):
                    self.p += 1
                    self.skip_type()
                while self.accept_op(","):
                    names.append(self.expect_name())
                    if self.is_op(":"):
                        self.p += 1
                        self.skip_type()
                self.expect_kw("in")
                self.expr()
                while self.accept_op(","):
                    self.expr()
                self.expect_kw("do")
                self.push_scope()
                self.bump_active(3)
                for nm in names:
                    self.declare(nm.v, nm.line)
                self.block()
                self.expect_kw("end")
                self.pop_scope(3)
                return False
            if v == "repeat":
                self.p += 1
                self.push_scope()
                self.block()
                self.expect_kw("until")
                self.expr()
                self.pop_scope()
                return False
            if v == "function":
                self.p += 1
                n = self.expect_name()
                nm = n.v
                is_method = False
                self.use(n.v, n.line, write=(not self.is_op(".") and not self.is_op(":")))
                while self.is_op("."):
                    self.p += 1
                    nm += "." + self.expect_name().v
                if self.is_op(":"):
                    self.p += 1
                    nm += ":" + self.expect_name().v
                    is_method = True
                self.func_body(nm, n.line, is_method)
                return False
            if v == "local":
                self.p += 1
                if self.accept_kw("function"):
                    n = self.expect_name()
                    self.declare(n.v, n.line)
                    self.func_body(n.v, n.line, False)
                    return False
                names = []
                while True:
                    nm = self.expect_name()
                    names.append(nm)
                    if self.is_op(":"):
                        self.p += 1
                        self.skip_type()
                    if not self.accept_op(","):
                        break
                if self.accept_op("="):
                    self.expr()
                    while self.accept_op(","):
                        self.expr()
                for nm in names:
                    self.declare(nm.v, nm.line)
                return False
            if v == "return":
                self.p += 1
                if not self.block_follow() and not self.is_op(";"):
                    self.expr()
                    while self.accept_op(","):
                        self.expr()
                return True
            if v == "break":
                self.p += 1
                return True
            self.err("unexpected keyword")
        if t.k == "name":
            if t.v == "continue":
                nx = self.peek()
                if not (nx.k == "op" and nx.v in ("=", ".", ":", "(", "[", ",", "{") or nx.k == "op" and nx.v in COMPOUND):
                    if nx.k != "str":
                        self.p += 1
                        return True
            if t.v == "type" and self.peek().k == "name" and self.peek().line == t.line:
                self.p += 1
                self.skip_type_alias()
                return False
            if t.v == "export" and self.peek().k == "name" and self.peek().v == "type":
                self.p += 2
                self.skip_type_alias()
                return False
        return self.expr_statement()

    def skip_type_alias(self):
        self.expect_name()
        if self.is_op("<"):
            self.skip_generics()
        self.expect_op("=")
        self.skip_type()

    def skip_generics(self):
        depth = 0
        while True:
            t = self.tok
            if t.k == "eof":
                self.err("unfinished generics")
            if t.k == "op" and t.v == "<":
                depth += 1
            elif t.k == "op" and t.v == ">":
                depth -= 1
                if depth == 0:
                    self.p += 1
                    return
            self.p += 1

    def skip_type(self):
        self.skip_simple_type()
        while True:
            t = self.tok
            if t.k == "op" and t.v in ("|", "&"):
                self.p += 1
                self.skip_simple_type()
                continue
            if t.k == "op" and t.v == "?":
                self.p += 1
                continue
            break

    def skip_simple_type(self):
        t = self.tok
        if t.k == "op" and t.v == "(":
            depth = 0
            while True:
                x = self.tok
                if x.k == "eof":
                    self.err("unfinished type")
                if x.k == "op" and x.v == "(":
                    depth += 1
                elif x.k == "op" and x.v == ")":
                    depth -= 1
                    if depth == 0:
                        self.p += 1
                        break
                self.p += 1
            if self.accept_op("->"):
                self.skip_type()
            return
        if t.k == "op" and t.v == "{":
            depth = 0
            while True:
                x = self.tok
                if x.k == "eof":
                    self.err("unfinished type")
                if x.k == "op" and x.v == "{":
                    depth += 1
                elif x.k == "op" and x.v == "}":
                    depth -= 1
                    if depth == 0:
                        self.p += 1
                        break
                self.p += 1
            return
        if t.k in ("name", "kw", "str"):
            if t.k == "kw" and t.v not in ("nil", "true", "false"):
                self.err("bad type")
            self.p += 1
            if t.v == "typeof" and self.is_op("("):
                depth = 0
                while True:
                    x = self.tok
                    if x.k == "op" and x.v == "(":
                        depth += 1
                    elif x.k == "op" and x.v == ")":
                        depth -= 1
                        if depth == 0:
                            self.p += 1
                            break
                    self.p += 1
                return
            while self.is_op("."):
                self.p += 1
                self.expect_name()
            if self.is_op("<"):
                self.skip_generics()
            return
        self.err("bad type")

    def func_body(self, name, line, is_method):
        f = Func(self.func, line, name)
        self.all_funcs.append(f)
        self.func = f
        self.push_scope()
        if self.is_op("<"):
            self.skip_generics()
        if is_method:
            self.declare("self", line)
        self.expect_op("(")
        if not self.is_op(")"):
            while True:
                if self.is_op("..."):
                    self.p += 1
                    if self.accept_op(":"):
                        self.skip_type()
                    break
                n = self.expect_name()
                self.declare(n.v, n.line)
                if self.accept_op(":"):
                    self.skip_type()
                if not self.accept_op(","):
                    break
        self.expect_op(")")
        if self.accept_op(":"):
            self.skip_type()
        self.block()
        self.expect_kw("end")
        self.pop_scope()
        self.func = f.parent

    def expr_statement(self):
        start = self.tok
        kind, e = self.suffixed_expr()
        t = self.tok
        if t.k == "op" and (t.v == "=" or t.v == ","):
            targets = [(kind, e)]
            while self.accept_op(","):
                targets.append(self.suffixed_expr())
            self.expect_op("=")
            self.expr()
            while self.accept_op(","):
                self.expr()
            for kd, ee in targets:
                if kd == "name":
                    self.use(ee, start.line, write=True)
                elif kd != "index":
                    self.err("cannot assign to this expression", start)
            return False
        if t.k == "op" and t.v in COMPOUND:
            self.p += 1
            self.expr()
            if kind == "name":
                self.use(e, start.line)
                self.use(e, start.line, write=True)
            elif kind != "index":
                self.err("cannot assign to this expression", start)
            return False
        if kind != "call":
            self.err("syntax error: expression is not a statement", start)
        return False

    def suffixed_expr(self):
        t = self.tok
        if t.k == "name":
            self.p += 1
            kind = "name"
            val = t.v
            pending_name = t
        elif t.k == "op" and t.v == "(":
            self.p += 1
            self.expr()
            self.expect_op(")")
            kind = "paren"
            val = None
            pending_name = None
        else:
            self.err("unexpected symbol")
        while True:
            t = self.tok
            if t.k == "op":
                if t.v == ".":
                    if pending_name is not None:
                        self.use(pending_name.v, pending_name.line)
                        pending_name = None
                    self.p += 1
                    self.expect_name()
                    kind = "index"
                    continue
                if t.v == "[":
                    if pending_name is not None:
                        self.use(pending_name.v, pending_name.line)
                        pending_name = None
                    self.p += 1
                    self.expr()
                    self.expect_op("]")
                    kind = "index"
                    continue
                if t.v == ":":
                    if pending_name is not None:
                        self.use(pending_name.v, pending_name.line)
                        pending_name = None
                    self.p += 1
                    self.expect_name()
                    self.call_args()
                    kind = "call"
                    continue
                if t.v == "(":
                    if t.line != self.toks[self.p - 1].line and False:
                        pass
                    if pending_name is not None:
                        self.use(pending_name.v, pending_name.line)
                        pending_name = None
                    self.call_args()
                    kind = "call"
                    continue
                if t.v == "{":
                    if pending_name is not None:
                        self.use(pending_name.v, pending_name.line)
                        pending_name = None
                    self.table()
                    kind = "call"
                    continue
            elif t.k == "str" or t.k == "interp":
                if pending_name is not None:
                    self.use(pending_name.v, pending_name.line)
                    pending_name = None
                self.simple_string()
                kind = "call"
                continue
            break
        if pending_name is not None:
            return "name", pending_name.v
        return kind, val

    def call_args(self):
        t = self.tok
        self.calls += 1
        if t.k == "op" and t.v == "(":
            self.p += 1
            if not self.is_op(")"):
                self.expr()
                while self.accept_op(","):
                    self.expr()
            self.expect_op(")")
            return
        if t.k == "op" and t.v == "{":
            self.table()
            return
        if t.k == "str" or t.k == "interp":
            self.simple_string()
            return
        self.err("expected call arguments")

    def simple_string(self):
        t = self.tok
        self.p += 1
        if t.k == "interp":
            for part in t.v:
                saved_t, saved_p = self.toks, self.p
                self.toks, self.p = part, 0
                if part and part[0].k != "eof":
                    self.expr()
                    if self.tok.k != "eof":
                        self.err("bad interpolation")
                self.toks, self.p = saved_t, saved_p

    def table(self):
        self.expect_op("{")
        while not self.is_op("}"):
            t = self.tok
            if t.k == "op" and t.v == "[":
                self.p += 1
                self.expr()
                self.expect_op("]")
                self.expect_op("=")
                self.expr()
            elif t.k == "name" and self.peek().k == "op" and self.peek().v == "=":
                self.p += 2
                self.expr()
            else:
                self.expr()
            if not (self.accept_op(",") or self.accept_op(";")):
                break
        self.expect_op("}")

    def expr(self, limit=0):
        t = self.tok
        if t.k == "kw" and t.v == "not":
            self.p += 1
            self.expr(UNARY_PRI)
        elif t.k == "op" and t.v in ("-", "#"):
            self.p += 1
            self.expr(UNARY_PRI)
        elif t.k == "op" and t.v == "~" and False:
            pass
        else:
            self.simple_expr()
        while True:
            t = self.tok
            op = None
            if t.k == "op" and t.v in BIN_PRI:
                op = t.v
            elif t.k == "kw" and t.v in ("and", "or"):
                op = t.v
            if op is None:
                break
            lp, rp = BIN_PRI[op]
            if lp <= limit:
                break
            self.p += 1
            self.expr(rp)
        return

    def simple_expr(self):
        t = self.tok
        k = t.k
        if k == "num" or k == "str":
            self.p += 1
        elif k == "interp":
            self.simple_string()
        elif k == "kw":
            v = t.v
            if v in ("nil", "true", "false"):
                self.p += 1
            elif v == "function":
                self.p += 1
                self.func_body("<anon>", t.line, False)
            elif v == "if":
                self.p += 1
                self.expr()
                self.expect_kw("then")
                self.expr()
                while self.accept_kw("elseif"):
                    self.expr()
                    self.expect_kw("then")
                    self.expr()
                self.expect_kw("else")
                self.expr()
            else:
                self.err("unexpected keyword in expression")
        elif k == "op":
            if t.v == "...":
                self.p += 1
            elif t.v == "{":
                self.table()
            elif t.v == "(":
                kind, val = self.suffixed_expr()
                if kind == "name":
                    self.use(val, t.line)
            else:
                self.err("unexpected symbol in expression")
        elif k == "name":
            kind, val = self.suffixed_expr()
            if kind == "name":
                self.use(val, t.line)
        else:
            self.err("unexpected token in expression")
        while self.is_op("::"):
            self.p += 1
            self.skip_type()


def parse(src):
    p = Parser(src)
    p.parse_chunk()
    return p


def read(path):
    with open(path, "rb") as fh:
        data = fh.read()
    try:
        return data.decode("utf-8")
    except UnicodeDecodeError:
        return data.decode("latin-1")


def check_file(path, verbose=True):
    try:
        src = read(path)
        p = parse(src)
    except LuauError as e:
        if verbose:
            print("FAIL %s: %s" % (path, e))
        return None
    except RecursionError:
        if verbose:
            print("FAIL %s: recursion too deep" % path)
        return None
    return p


def main(argv):
    if len(argv) < 2:
        print("usage: luau.py check|stats|globals|comments FILE...")
        return 2
    cmd = argv[1]
    files = argv[2:]
    rc = 0
    if cmd == "check":
        for f in files:
            p = check_file(f)
            if p is None:
                rc = 1
                continue
            worst = max(p.all_funcs, key=lambda x: x.max_active)
            worst_up = max(p.all_funcs, key=lambda x: len(x.upvals))
            print("ok   %s  funcs=%d locals=%d maxActiveLocals=%d(%s@%d) maxUpvals=%d(%s@%d)" % (
                f, len(p.all_funcs), len(p.locals_all), worst.max_active, worst.name, worst.line,
                len(worst_up.upvals), worst_up.name, worst_up.line))
    elif cmd == "globals":
        for f in files:
            p = check_file(f)
            if p is None:
                rc = 1
                continue
            names = {}
            for k, (ln, c) in p.global_reads.items():
                names[k] = [ln, c, 0]
            for k, (ln, c) in p.global_writes.items():
                if k in names:
                    names[k][2] = c
                else:
                    names[k] = [ln, 0, c]
            for k in sorted(names):
                print("%-32s firstLine=%-6d reads=%-5d writes=%d" % (k, names[k][0], names[k][1], names[k][2]))
    elif cmd == "comments":
        for f in files:
            p = check_file(f)
            if p is None:
                rc = 1
                continue
            for ln, kind, text in p.comments:
                print("%d\t%s\t%s" % (ln, kind, text.replace("\n", "\\n")))
    else:
        print("unknown command")
        return 2
    return rc


if __name__ == "__main__":
    sys.setrecursionlimit(20000)
    sys.exit(main(sys.argv))
