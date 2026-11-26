import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import luau


def norm(value):
    if isinstance(value, list):
        return tuple(norm(item) for item in value)
    if isinstance(value, luau.Tok):
        return (value.k, norm(value.v))
    return value


def code_of(src):
    return [(tok.k, norm(tok.v)) for tok in luau.lex(src, 1, None)]


def is_directive(text):
    return text.startswith("--!")


def strip(src):
    spans = []
    luau.lex(src, 1, None, spans)
    kill = [s for s in spans if not is_directive(s[2])]
    parts, pos = [], 0
    for start, end, text in kill:
        parts.append(src[pos:start])
        parts.append("\0\n\0" if "\n" in text else "\0")
        pos = end
    parts.append(src[pos:])
    kept = []
    for line in "".join(parts).split("\n"):
        if "\0" not in line:
            kept.append(line)
            continue
        if line.replace("\0", "").strip() == "":
            continue
        line = re.sub(r"[ \t]*\0[ \t]*$", "", line)
        line = re.sub(r"(\S)[ \t]*\0[ \t]*(\S)", lambda m: m.group(1) + " " + m.group(2), line)
        line = line.replace("\0", "")
        kept.append(line.rstrip(" \t") if line.rstrip(" \t") != "" else line)
    text = "\n".join(kept)
    if src.endswith("\n") and not text.endswith("\n"):
        text += "\n"
    while "\n\n\n\n" in text:
        text = text.replace("\n\n\n\n", "\n\n\n")
    return text.lstrip("\n"), len(kill)


def main(argv):
    total = 0
    bad = 0
    for path in argv:
        with open(path, "rb") as handle:
            src = handle.read().decode("latin-1")
        new, count = strip(src)
        if count == 0:
            continue
        if code_of(src) != code_of(new):
            print("skipped, the code would change: " + path)
            bad += 1
            continue
        with open(path, "wb") as handle:
            handle.write(new.encode("latin-1"))
        total += count
        print("%5d comments taken out of %s" % (count, path))
    print("comments taken out: %d" % total)
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
