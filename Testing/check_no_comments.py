import argparse
import hashlib
import io
import json
import os
import sys
import tokenize

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "tools"))
import luau

DEFAULT_ROOT = os.path.dirname(HERE)
DEFAULT_BASELINE = os.path.join(HERE, "baseline_v1.3.0.txt")
SKIP_DIRS = ("__pycache__", ".git")
VERSION_FILE = "Hub/AtsukoHub.lua"
VERSION_OLD = "beta v1.3.0"
VERSION_NEW = "v1.6.1"
SHOW = 110


def clean(text):
    text = text.replace("\r\n", "\n").replace("\r", "\n")
    return "\n".join(line.strip() for line in text.split("\n")).strip()


def digest(text):
    return hashlib.sha1(text.encode("utf-8")).hexdigest()


def read(path):
    with open(path, "r", encoding="utf-8", errors="replace", newline="") as fh:
        return fh.read()


def lua_comments(text):
    found = []
    luau.lex(text, 1, found)
    return [(line, clean(body)) for line, _kind, body in found]


def py_comments(text):
    found = []
    for tok in tokenize.generate_tokens(io.StringIO(text).readline):
        if tok.type == tokenize.COMMENT:
            found.append((tok.start[0], clean(tok.string)))
    return found


def comments_of(name, text):
    if name.endswith(".py"):
        return py_comments(text)
    return lua_comments(text)


def walk(root, extensions):
    for base, dirs, files in os.walk(root):
        dirs[:] = sorted(d for d in dirs if d not in SKIP_DIRS)
        for name in sorted(files):
            if name.endswith(extensions):
                path = os.path.join(base, name)
                yield os.path.relpath(path, root).replace(os.sep, "/"), path


def short(text):
    one = text.replace("\n", " / ")
    if len(one) > SHOW:
        one = one[:SHOW] + "..."
    return one


def load_baseline(path):
    counts = {}
    with open(path, "r", encoding="utf-8") as fh:
        for raw in fh:
            raw = raw.strip()
            if raw:
                count, key = json.loads(raw)
                counts[key] = counts.get(key, 0) + count
    return counts


def save_baseline(path, counts):
    with open(path, "w", encoding="utf-8", newline="\n") as fh:
        for key in sorted(counts):
            fh.write(json.dumps([counts[key], key]) + "\n")


def build_baseline(v130, third, main):
    counts = {}
    problems = []

    def add(label, name, path):
        try:
            items = comments_of(name, read(path))
        except Exception as exc:
            problems.append("%s: %s" % (label, exc))
            return
        for _line, text in items:
            key = digest(text)
            counts[key] = counts.get(key, 0) + 1

    for rel, path in walk(v130, (".lua", ".py")):
        add("v1.3.0/" + rel, rel, path)
    for path in third:
        add(path, path + ".lua", path)
    for rel, path in walk(main, (".lua", ".txt")):
        add("Main Scripts/" + rel, rel + ".lua", path)
    return counts, problems


def derived_originals(root, rel, cache):
    if rel in cache:
        return cache[rel]
    found = []
    try:
        if HERE not in sys.path:
            sys.path.insert(0, HERE)
        import verify_patches as vp
        for spec in vp.SPECS:
            if spec["shipped"] != rel:
                continue
            patch = os.path.join(root, spec["patch"])
            shipped = os.path.join(root, rel)
            if os.path.isfile(patch) and os.path.isfile(shipped):
                hunks = vp.parse_patch(vp.read_text(patch))
                lines = vp.split_lines(vp.read_text(shipped))
                original = "".join(vp.apply_patch(lines, hunks, True))
                found = [body for _line, body in lua_comments(original.encode("latin-1").decode("utf-8", "replace"))]
    except Exception:
        found = []
    cache[rel] = found
    return found


def is_reduction(text, originals):
    wanted = text.split("\n")
    for original in originals:
        rest = iter(original.split("\n"))
        if all(any(line == other for other in rest) for line in wanted):
            return True
    return False


def check(root, counts):
    cache = {}
    seen = {}
    where = {}
    failures = []
    errors = []
    total = 0
    for rel, path in walk(root, (".lua", ".py")):
        try:
            items = comments_of(rel, read(path))
        except Exception as exc:
            errors.append("%s: could not be read (%s)" % (rel, exc))
            continue
        for line, text in items:
            total += 1
            if rel.startswith("Testing/") and rel.endswith(".py"):
                failures.append("%s:%d  a comment in a Testing python file: %s" % (rel, line, short(text)))
                continue
            if rel == VERSION_FILE:
                text = text.replace(VERSION_NEW, VERSION_OLD)
            seen[text] = seen.get(text, 0) + 1
            where.setdefault(text, []).append((rel, line))
    for text in sorted(seen):
        have = counts.get(digest(text), 0)
        if seen[text] > have:
            plain = [(rel, line) for rel, line in where[text] if not is_reduction(text, derived_originals(root, rel, cache))]
            for rel, line in plain[have:]:
                failures.append("%s:%d  not in the baseline (baseline %d, package %d): %s" % (rel, line, have, seen[text], short(text)))
    return total, failures, errors


def main(argv):
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", default=DEFAULT_ROOT)
    parser.add_argument("--baseline", default=DEFAULT_BASELINE)
    parser.add_argument("--build-baseline", action="store_true")
    parser.add_argument("--v130")
    parser.add_argument("--third", nargs="*", default=[])
    parser.add_argument("--main")
    args = parser.parse_args(argv)
    if args.build_baseline:
        if not args.v130 or not args.main:
            print("--build-baseline needs --v130 DIR, --third FILE... and --main DIR")
            return 2
        counts, problems = build_baseline(args.v130, args.third, args.main)
        for line in problems:
            print("baseline problem: " + line)
        if problems:
            return 1
        save_baseline(args.baseline, counts)
        print("baseline written: %d different comments, %d in all" % (len(counts), sum(counts.values())))
        return 0
    if not os.path.isfile(args.baseline):
        print("no-comments check: FAIL, the baseline file is missing: " + args.baseline)
        return 1
    counts = load_baseline(args.baseline)
    total, failures, errors = check(args.root, counts)
    for line in errors:
        print(line)
    for line in failures:
        print(line)
    if failures or errors:
        print("no-comments check: FAIL (%d new comments, %d unreadable files, %d comments seen)" % (len(failures), len(errors), total))
        return 1
    print("no-comments check: pass (%d comments seen, every one is in the v1.3.0 / third-party baseline)" % total)
    return 0


if __name__ == "__main__":
    sys.setrecursionlimit(20000)
    sys.exit(main(sys.argv[1:]))
