import argparse
import hashlib
import json
import os
import re
import sys
import zipfile

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "tools"))
import uncomment
from difflib import SequenceMatcher

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

HUNK_HEADER = re.compile(r"^@@ -(\d+)(?:,(\d+))? \+(\d+)(?:,(\d+))? @@")

SPECS = [
    {
        "name": "FDless",
        "group": "reanimation",
        "patch": "Reanimation/patches/FDless.patch",
        "shipped": "Reanimation/Hat/FDless.lua",
        "original": "FDless.txt",
        "sha256": "af870600b6dbc55d02b097a9440d1a19e50cac0e8f7204fb79958edefef32378",
    },
    {
        "name": "Gelatek",
        "group": "reanimation",
        "patch": "Reanimation/patches/Gelatek.patch",
        "shipped": "Reanimation/Limb/Gelatek.lua",
        "original": "Reanimation.lua.txt",
        "sha256": "453ebd169d90548a342f3d22fa1989460a6af40ede7888c55cc95c55fbfad2ff",
    },
    {
        "name": "Uhhhhhh",
        "group": "reanimation",
        "patch": "Reanimation/patches/Uhhhhhh.patch",
        "shipped": "Reanimation/Limb/Uhhhhhh.lua",
        "original": "betabetafork.txt",
        "sha256": "91d2873ca4f31254d8d620bc12df584b843021db5b1897b00417db5bebfe6670",
    },
    {
        "name": "DubstepGun",
        "group": "main",
        "patch": "Scripts/patches/DubstepGun.patch",
        "shipped": "Scripts/Hat/DubstepGunOriginal.lua",
        "original": "DubstepGun.lua",
        "sha256": "0f4e51b73acea05b2a6579768cafc4ebf4365b6f1cb1042b317c121ff8f4a3dc",
    },
    {
        "name": "LastStar",
        "group": "main",
        "patch": "Scripts/patches/LastStar.patch",
        "shipped": "Scripts/Hat/LastStar.lua",
        "original": "Last Star.lua",
        "sha256": "30fddb2452be48f4880a9d9d1332507af6abe5a71ba41cffe5a429f82ad39539",
    },
    {
        "name": "NeptunianV",
        "group": "main",
        "patch": "Scripts/patches/NeptunianV.patch",
        "shipped": "Scripts/Hat/NeptunianV.lua",
        "original": "Neptunian V.lua",
        "sha256": "3e6e8debe04e81aa86e6dcb7c2e94d67291cf1055a21cde0b35277ff86751acc",
    },
    {
        "name": "NeptunianVGun",
        "group": "main",
        "patch": "Scripts/patches/NeptunianVGun.patch",
        "shipped": "Scripts/Hat/NeptunianVGun.lua",
        "original": "Neptunian V Gun.lua",
        "sha256": "d5f616f3c5e7a10ba806aa3edf40411e4d4274f5bf19b55249eafd9de4fb3549",
    },
    {
        "name": "TheHotline",
        "group": "main",
        "patch": "Scripts/patches/TheHotline.patch",
        "shipped": "Scripts/Hat/TheHotline.lua",
        "original": "TheHotline.lua",
        "sha256": "a7c216defdf1077ae2a1a4715f62bcd1b5a5649847d6760f6a2ab638863c7791",
    },
    {
        "name": "TheSniper",
        "group": "main",
        "patch": "Scripts/patches/TheSniper.patch",
        "shipped": "Scripts/_unlisted/TheSniper.lua",
        "original": "TheSniper(Don't use this).lua",
        "sha256": "27fbe0792ce71e3d582336315c769b8398b0eb0cdbd534bc3c66a17c0d72b55f",
    },
    {
        "name": "Addict",
        "group": "main",
        "patch": "Scripts/patches/Addict.patch",
        "shipped": "Scripts/Hat/Addict.lua",
        "original": "Addict_1.lua",
        "sha256": "42bc6f408db036d2d042ff83c348bf3a2eae0abd9ff8ee45e61cfc1c26296c58",
    },
    {
        "name": "CommanderV2",
        "group": "main",
        "patch": "Scripts/patches/CommanderV2.patch",
        "shipped": "Scripts/Hat/CommanderV2.lua",
        "original": "CommanderV2_2.lua",
        "sha256": "655ae5c33ca5dbb6752131301381736684506f36f5c55e4d09424c6aa3eeb3ed",
    },
    {
        "name": "InternalWar",
        "group": "main",
        "patch": "Scripts/patches/InternalWar.patch",
        "shipped": "Scripts/Hat/InternalWar.lua",
        "original": "InternalWar_FDless.lua",
        "sha256": "1e88ec17ae80eba55ae2db996435fad7b9cefb5fb29e3c66ac99016eeaa12a1b",
    },
    {
        "name": "RealityOrbGlitcher",
        "group": "main",
        "patch": "Scripts/patches/RealityOrbGlitcher.patch",
        "shipped": "Scripts/Hat/RealityOrbGlitcher.lua",
        "original": "RealityOrbGlitcherConvert.lua.txt",
        "sha256": "16ffae87e30d5d6191ba3eb2953bfeba8f070614dce3e2799f46b9f39d22979d",
    },
    {
        "name": "MasterChief",
        "group": "main",
        "patch": "Scripts/patches/MasterChief.patch",
        "shipped": "Scripts/Hat/MasterChief.lua",
        "original": "fc693e30-MasterChief.txt.lua.txt",
        "sha256": "9237e078beeb029a713b6c5503d8b0c2d2ed18aa542d62bcab2aa2f3fd220444",
    },
]

BLOCKS_FILE = os.path.join(ROOT, "Testing", "patch_blocks.json")


def sha256(data):
    return hashlib.sha256(data).hexdigest()


def split_lines(text):
    parts = text.split("\n")
    out = []
    for index, part in enumerate(parts):
        if index < len(parts) - 1:
            out.append(part + "\n")
        elif part != "":
            out.append(part)
    return out


def read_text(path):
    with open(path, "rb") as handle:
        return handle.read().decode("latin-1")


def parse_patch(text):
    hunks = []
    current = None
    for line in split_lines(text):
        header = HUNK_HEADER.match(line)
        if header:
            current = {
                "old_start": int(header.group(1)),
                "old_len": 1 if header.group(2) is None else int(header.group(2)),
                "new_start": int(header.group(3)),
                "new_len": 1 if header.group(4) is None else int(header.group(4)),
                "rows": [],
            }
            hunks.append(current)
            continue
        if current is None:
            continue
        if line.startswith("\\"):
            if current["rows"]:
                last = current["rows"][-1]
                if last["text"].endswith("\n"):
                    last["text"] = last["text"][:-1]
            continue
        if line[:1] in (" ", "+", "-"):
            current["rows"].append({"op": line[0], "text": line[1:]})
    for hunk in hunks:
        old_count = sum(1 for row in hunk["rows"] if row["op"] in (" ", "-"))
        new_count = sum(1 for row in hunk["rows"] if row["op"] in (" ", "+"))
        if old_count != hunk["old_len"] or new_count != hunk["new_len"]:
            raise ValueError("hunk at old line %d is corrupt (counts do not match its header)" % hunk["old_start"])
    return hunks


def side(hunk, ops):
    return [row["text"] for row in hunk["rows"] if row["op"] in ops]


def apply_patch(lines, hunks, reverse):
    src_ops = (" ", "+") if reverse else (" ", "-")
    dst_ops = (" ", "-") if reverse else (" ", "+")
    start_key = "new_start" if reverse else "old_start"
    len_key = "new_len" if reverse else "old_len"
    out = []
    pos = 0
    for hunk in hunks:
        count = hunk[len_key]
        index = hunk[start_key] if count == 0 else hunk[start_key] - 1
        if index < pos or index > len(lines):
            raise ValueError("hunk at line %d is out of order or out of range" % hunk[start_key])
        out.extend(lines[pos:index])
        expected = side(hunk, src_ops)
        found = lines[index:index + count]
        if found != expected:
            for offset, want in enumerate(expected):
                got = found[offset] if offset < len(found) else None
                if got != want:
                    raise ValueError("hunk at line %d does not match at its row %d" % (hunk[start_key], offset + 1))
            raise ValueError("hunk at line %d does not match" % hunk[start_key])
        out.extend(side(hunk, dst_ops))
        pos = index + count
    out.extend(lines[pos:])
    return out


def footprints(hunks, old_lines):
    result = []
    for hunk in hunks:
        old_line = hunk["old_start"] if hunk["old_len"] else hunk["old_start"] + 1
        rows = hunk["rows"]
        index = 0
        while index < len(rows):
            if rows[index]["op"] == " ":
                old_line += 1
                index += 1
                continue
            point = old_line
            removed = []
            inserted = []
            while index < len(rows) and rows[index]["op"] != " ":
                if rows[index]["op"] == "-":
                    removed.append(old_line)
                    old_line += 1
                else:
                    inserted.append(rows[index]["text"])
                index += 1
            if removed:
                result.append((removed[0], removed[-1], "replace"))
                continue
            low = point
            block = list(inserted)
            while low > 1 and block and old_lines[low - 2] == block[-1]:
                block = [block[-1]] + block[:-1]
                low -= 1
            high = point
            block = list(inserted)
            while high <= len(old_lines) and block and old_lines[high - 1] == block[0]:
                block = block[1:] + [block[0]]
                high += 1
            result.append((low, high, "insert"))
    return result


def real_changes(restored_text, shipped_text):
    original = split_lines(restored_text)
    bare = split_lines(uncomment.strip(restored_text)[0])
    shipped = split_lines(shipped_text)
    back = {}
    for tag, i1, i2, j1, j2 in SequenceMatcher(None, original, bare, autojunk=False).get_opcodes():
        for k in range(j1, j2):
            back[k] = (i1 + (k - j1) if tag == "equal" else min(i1 + (k - j1), max(i1, i2 - 1))) + 1
    back[len(bare)] = len(original) + 1
    result = []
    for tag, i1, i2, j1, j2 in SequenceMatcher(None, bare, shipped, autojunk=False).get_opcodes():
        if tag == "equal":
            continue
        if "".join(bare[i1:i2]).strip() == "" and "".join(shipped[j1:j2]).strip() == "":
            continue
        if tag == "delete":
            low, high = i1, i2
            while low > 0 and bare[low - 1] == bare[high - 1]:
                low -= 1
                high -= 1
            places = []
            while True:
                places.append((back[low], back[high - 1]))
                if high >= len(bare) or bare[low] != bare[high]:
                    break
                low += 1
                high += 1
            result.append((places, None, "slide"))
        elif i2 > i1:
            result.append((back[i1], back[i2 - 1], "replace"))
        else:
            point = back.get(i1, len(original) + 1)
            result.append((point - 1, point, "insert"))
    return result


def load_blocks():
    if not os.path.isfile(BLOCKS_FILE):
        return {}
    with open(BLOCKS_FILE, "r", encoding="utf-8") as handle:
        return json.load(handle)


def find_original(spec, roots, zips):
    for root in roots:
        if os.path.isdir(root):
            for dirpath, _dirs, files in os.walk(root):
                for name in files:
                    if name == spec["original"] or name.endswith("-" + spec["original"]):
                        with open(os.path.join(dirpath, name), "rb") as handle:
                            return handle.read(), os.path.join(dirpath, name)
    for archive in zips:
        try:
            with zipfile.ZipFile(archive) as bundle:
                for member in bundle.namelist():
                    base = member.rsplit("/", 1)[-1]
                    if base == spec["original"]:
                        return bundle.read(member), archive + "!" + member
        except (OSError, zipfile.BadZipFile):
            continue
    return None, None


def check_one(spec, roots, zips, blocks):
    result = {"name": spec["name"], "status": "PASS", "notes": []}
    patch_path = os.path.join(ROOT, spec["patch"])
    shipped_path = os.path.join(ROOT, spec["shipped"])
    if not os.path.isfile(patch_path) or not os.path.isfile(shipped_path):
        result["status"] = "MISSING"
        result["notes"].append("patch or shipped file not found (%s, %s)" % (spec["patch"], spec["shipped"]))
        return result
    try:
        hunks = parse_patch(read_text(patch_path))
    except ValueError as err:
        result["status"] = "FAIL"
        result["notes"].append(str(err))
        return result
    added = sum(1 for h in hunks for r in h["rows"] if r["op"] == "+")
    removed = sum(1 for h in hunks for r in h["rows"] if r["op"] == "-")
    result["hunks"] = len(hunks)
    result["added"] = added
    result["removed"] = removed
    shipped_bytes = open(shipped_path, "rb").read()
    shipped_lines = split_lines(shipped_bytes.decode("latin-1"))
    try:
        restored = "".join(apply_patch(shipped_lines, hunks, True)).encode("latin-1")
    except ValueError as err:
        result["status"] = "FAIL"
        result["notes"].append("reverse: " + str(err))
        return result
    digest = sha256(restored)
    if digest != spec["sha256"]:
        result["status"] = "FAIL"
        result["notes"].append("reverse: result hash %s is not the recorded original %s" % (digest[:12], spec["sha256"][:12]))
    else:
        result["notes"].append("reverse gives the original, sha256 %s" % digest[:12])
    original, where = find_original(spec, roots, zips)
    if original is None:
        result["notes"].append("original file not supplied, compared by recorded hash only")
    else:
        if original != restored:
            result["status"] = "FAIL"
            result["notes"].append("reverse result differs from %s" % where)
        else:
            result["notes"].append("byte for byte equal to %s" % where)
        try:
            forward = "".join(apply_patch(split_lines(original.decode("latin-1")), hunks, False)).encode("latin-1")
            if forward != shipped_bytes:
                result["status"] = "FAIL"
                result["notes"].append("forward apply does not give the shipped file")
            else:
                result["notes"].append("forward apply gives the shipped file")
        except ValueError as err:
            result["status"] = "FAIL"
            result["notes"].append("forward: " + str(err))
    ranges = blocks.get(spec["name"])
    if ranges is None:
        result["notes"].append("no block list recorded, hunk placement not checked")
    else:
        outside = []
        for first, last, kind in real_changes(restored.decode("latin-1"), shipped_bytes.decode("latin-1")):
            if kind == "slide":
                inside = any(low <= a and b <= high for a, b in first for low, high, _why in ranges)
                if not inside:
                    first, last = first[0]
            elif kind == "replace":
                inside = any(low <= first and last <= high for low, high, _why in ranges)
            else:
                inside = any(not (last < low or first > high) for low, high, _why in ranges)
            if not inside:
                outside.append("%d-%d" % (first, last))
        if outside:
            result["status"] = "FAIL"
            result["notes"].append("apart from taking the comments out, changes outside the named blocks at original lines " + ", ".join(outside))
        else:
            result["notes"].append("apart from taking the comments out, every change lies inside a named block (%d blocks)" % len(ranges))
    return result


def main(argv=None):
    parser = argparse.ArgumentParser()
    parser.add_argument("--originals", action="append", default=[])
    parser.add_argument("--zip", action="append", default=[])
    parser.add_argument("--only", choices=["reanimation", "main"])
    parser.add_argument("--allow-missing", action="store_true")
    args = parser.parse_args(argv)
    roots = list(args.originals)
    env_root = os.environ.get("ATSUKO_ORIGINALS")
    if env_root:
        roots.append(env_root)
    roots.append(os.path.join(ROOT, "Testing", "originals"))
    zips = list(args.zip)
    for root in roots:
        if os.path.isdir(root):
            for name in os.listdir(root):
                if name.lower().endswith(".zip"):
                    zips.append(os.path.join(root, name))
    blocks = load_blocks()
    failed = 0
    missing = 0
    for spec in SPECS:
        if args.only and spec["group"] != args.only:
            continue
        result = check_one(spec, roots, zips, blocks)
        extra = ""
        if "hunks" in result:
            extra = "  %d hunks, +%d -%d" % (result["hunks"], result["added"], result["removed"])
        print("%-8s %-14s%s" % (result["status"], result["name"], extra))
        for note in result["notes"]:
            print("           " + note)
        if result["status"] == "FAIL":
            failed += 1
        if result["status"] == "MISSING":
            missing += 1
    print("failed: %d, missing: %d" % (failed, missing))
    if failed:
        return 1
    if missing and not args.allow_missing:
        return 2
    return 0


if __name__ == "__main__":
    sys.exit(main())
