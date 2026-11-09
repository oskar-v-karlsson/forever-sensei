#!/usr/bin/env python3
"""tools/reports.py: process translation reports pasted from the game (make reports).

She saves reports in-game and copies them from the 報告を送る box into a chat. Copy that text, then run
`make reports` (reads the clipboard with pbpaste) or `python3 tools/reports.py --file reports.txt`.

For every report:
- A suggestion (案) that passes the Japanese rules (tools/textrules.py) and was made against the current text
  (今) is written into ForeverSensei/Locales/ja.lua.
- Everything else (no suggestion, a suggestion that breaks a rule, text changed since, unknown id) goes to
  reports/open.md with the English source and current Japanese, for a person or agent to handle.
- Every report is appended to reports/log.md.
Then, when ja.lua changed, the patch version is bumped (TOC + Core/Init.lua) and dist/ForeverSensei-v<version>.zip
is built (also built with --zip when nothing changed).

Report format (Modules/Feedback.lua, Feedback.Format):
    [ForeverSensei v0.1.0 報告 2件]
    #1 spell.chain_heal.when | 不自然
    今: <current Japanese>
    案: <suggested Japanese>          (optional)
    メモ: <note>                      (optional)
Line breaks inside a field are written as the two characters \\n.
"""
import argparse
import datetime
import os
import re
import subprocess
import sys
import zipfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ADDON = os.path.join(ROOT, "ForeverSensei")
JA = os.path.join(ADDON, "Locales", "ja.lua")
EN = os.path.join(ADDON, "Locales", "en.lua")
TOC = os.path.join(ADDON, "ForeverSensei.toc")
INIT = os.path.join(ADDON, "Core", "Init.lua")
REPORTS_DIR = os.path.join(ROOT, "reports")
sys.path.insert(0, os.path.join(ROOT, "tools"))

import textrules  # noqa: E402

HEADER = re.compile(r"\[ForeverSensei v(\S+) 報告 (\d+)件\]")
ITEM = re.compile(r"^#(\d+)\s+(\S+)\s*\|\s*(.*?)\s*$")
FIELD = re.compile(r"^(今|案|メモ)\s*[:：]\s?(.*)$")
EN_LINE = re.compile(r'^L\["([^"]+)"\] = "((?:[^"\\]|\\.)*)"$')
JA_LINE = re.compile(r'^(  \["([^"]+)"\] = )"((?:[^"\\]|\\.)*)"(,)$')


def lua_unescape(s):
    return re.sub(r"\\(.)", lambda m: {"n": "\n", "t": "\t"}.get(m.group(1), m.group(1)), s)


def lua_escape(s):
    return s.replace("\\", "\\\\").replace('"', '\\"').replace("\n", "\\n")


def field_unescape(s):
    return s.replace("\\n", "\n").strip()


def parse(text):
    """Report text → {version, count, reports: [{n, id, reason, current, suggestion, note}]}. Chat apps may add
    names/timestamps around the paste or wrap it; lines that are not part of the format are ignored."""
    text = text.replace("\r\n", "\n").replace("\r", "\n").replace("\u3000", " ")
    out = {"version": None, "count": None, "reports": []}
    cur = None
    for raw in text.split("\n"):
        line = raw.strip()
        h = HEADER.search(line)
        if h:
            out["version"], out["count"] = h.group(1), int(h.group(2))
            continue
        m = ITEM.match(line)
        if m:
            cur = {"n": int(m.group(1)), "id": m.group(2), "reason": m.group(3), "current": None,
                   "suggestion": None, "note": None}
            out["reports"].append(cur)
            continue
        f = FIELD.match(line)
        if f and cur is not None:
            key = {"今": "current", "案": "suggestion", "メモ": "note"}[f.group(1)]
            cur[key] = field_unescape(f.group(2)) or None
    return out


def read_locales():
    en, ja = {}, {}
    with open(EN, encoding="utf-8") as fh:
        for line in fh:
            m = EN_LINE.match(line.rstrip("\n"))
            if m:
                en[m.group(1)] = lua_unescape(m.group(2))
    with open(JA, encoding="utf-8") as fh:
        for line in fh:
            m = JA_LINE.match(line.rstrip("\n"))
            if m:
                ja[m.group(2)] = lua_unescape(m.group(3))
    return en, ja


def names():
    out = []
    for rel in ("Data/Shaman/Spells.lua", "Data/Shaman/Talents.lua"):
        with open(os.path.join(ADDON, rel), encoding="utf-8") as fh:
            out += re.findall(r'name = "([^"]+)"', fh.read())
    return out


def write_ja(changes):
    with open(JA, encoding="utf-8") as fh:
        lines = fh.read().split("\n")
    for i, line in enumerate(lines):
        m = JA_LINE.match(line)
        if m and m.group(2) in changes:
            lines[i] = f'{m.group(1)}"{lua_escape(changes[m.group(2)])}"{m.group(4)}'
    with open(JA, "w", encoding="utf-8") as fh:
        fh.write("\n".join(lines))


def version():
    with open(TOC, encoding="utf-8") as fh:
        return re.search(r"^## Version: (\S+)", fh.read(), re.M).group(1)


def bump_version():
    old = version()
    parts = [int(x) for x in old.split(".")]
    parts[-1] += 1
    new = ".".join(str(x) for x in parts)
    for path, pattern, repl in (
        (TOC, r"^## Version: \S+", f"## Version: {new}"),
        (INIT, r'^ns\.VERSION = "[^"]+"', f'ns.VERSION = "{new}"'),
    ):
        with open(path, encoding="utf-8") as fh:
            src = fh.read()
        src, n = re.subn(pattern, repl, src, count=1, flags=re.M)
        if n != 1:
            sys.exit(f"could not bump version in {path}")
        with open(path, "w", encoding="utf-8") as fh:
            fh.write(src)
    return old, new


def build_zip():
    v = version()
    dist = os.path.join(ROOT, "dist")
    os.makedirs(dist, exist_ok=True)
    path = os.path.join(dist, f"ForeverSensei-v{v}.zip")
    with zipfile.ZipFile(path, "w", zipfile.ZIP_DEFLATED) as z:
        for dirpath, _, files in os.walk(ADDON):
            for fn in sorted(files):
                if fn.startswith("."):
                    continue
                full = os.path.join(dirpath, fn)
                z.write(full, os.path.relpath(full, ROOT))
    return path


def md_block(s):
    return "\n".join("    " + x for x in (s or "").split("\n"))


def process(text, dry_run=False):
    parsed = parse(text)
    if not parsed["reports"]:
        sys.exit("no reports found in the input (expected a line like '[ForeverSensei v0.1.0 報告 2件]')")
    if parsed["count"] is not None and parsed["count"] != len(parsed["reports"]):
        print(f"warning: header says {parsed['count']} reports, found {len(parsed['reports'])} (paste cut off?)")
    en, ja = read_locales()
    all_names = names()
    changes, open_items, log = {}, [], []
    for r in parsed["reports"]:
        rid = r["id"]
        status, why = "open", []
        if rid not in en:
            why.append("unknown id (renamed or removed?)")
        elif r["suggestion"]:
            if r["current"] and r["current"] != ja.get(rid):
                why.append("the Japanese changed since she reported it; compare by hand")
            probs = textrules.ja_problems(rid, r["suggestion"], en[rid], all_names)
            if probs:
                why.append("suggestion breaks rules: " + "; ".join(probs))
            if r["suggestion"] == ja.get(rid):
                status, why = "same", []
            elif not why:
                changes[rid] = r["suggestion"]
                status = "applied"
        else:
            why.append("no suggestion: needs a new Japanese text")
        log.append((r, status))
        if status == "open":
            open_items.append((r, why, en.get(rid), ja.get(rid)))

    today = datetime.date.today().isoformat()
    print(f"{len(parsed['reports'])} report(s) from v{parsed['version']}: "
          f"{len(changes)} applied, {len(open_items)} open")
    for rid, s in changes.items():
        print(f"  applied {rid}: {s}")
    for r, why, _, _ in open_items:
        print(f"  open    {r['id']} ({r['reason']}): {'; '.join(why)}")
    if dry_run:
        return parsed, changes, open_items

    os.makedirs(REPORTS_DIR, exist_ok=True)
    if open_items:
        path = os.path.join(REPORTS_DIR, "open.md")
        new = not os.path.exists(path)
        with open(path, "a", encoding="utf-8") as fh:
            if new:
                fh.write("# Open translation reports\n\nReports from the game that need a person or agent: write a "
                         "better Japanese text in ForeverSensei/Locales/ja.lua (follow README 'Processing translation "
                         "reports'), run make check, then delete the entry here.\n")
            for r, why, en_text, ja_text in open_items:
                fh.write(f"\n## {r['id']} ({r['reason']}, {today}, v{parsed['version']})\n\n")
                fh.write(f"- Why open: {'; '.join(why)}\n")
                if r["note"]:
                    fh.write(f"- Her note: {r['note']}\n")
                fh.write(f"- English source:\n\n{md_block(en_text)}\n\n- Japanese now:\n\n{md_block(ja_text)}\n")
                if r["current"] and r["current"] != ja_text:
                    fh.write(f"\n- Japanese she saw:\n\n{md_block(r['current'])}\n")
                if r["suggestion"]:
                    fh.write(f"\n- Her suggestion:\n\n{md_block(r['suggestion'])}\n")
    with open(os.path.join(REPORTS_DIR, "log.md"), "a", encoding="utf-8") as fh:
        for r, status in log:
            extra = "".join(f" | {k}: {r[k]}" for k in ("suggestion", "note") if r[k])
            fh.write(f"- {today} v{parsed['version']} {r['id']} | {r['reason']} | {status}{extra}\n".replace("\n|", " |"))
    if changes:
        write_ja(changes)
        old, new = bump_version()
        print(f"version {old} -> {new}")
    return parsed, changes, open_items


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--file", help="read the reports from this file instead of the clipboard")
    ap.add_argument("--dry-run", action="store_true", help="only show what would happen")
    ap.add_argument("--zip", action="store_true", help="build the zip even when nothing changed")
    args = ap.parse_args()
    if args.file:
        with open(args.file, encoding="utf-8") as fh:
            text = fh.read()
    else:
        try:
            text = subprocess.run(["pbpaste"], capture_output=True, check=True).stdout.decode("utf-8")
        except (OSError, subprocess.CalledProcessError):
            sys.exit("cannot read the clipboard (pbpaste); use --file")
    _, changes, _ = process(text, dry_run=args.dry_run)
    if args.dry_run:
        return
    if changes:
        check = subprocess.run([sys.executable, os.path.join(ROOT, "tools", "check.py")])
        if check.returncode != 0:
            sys.exit("make check failed after applying the reports: fix the problems above, then run make zip")
    if changes or args.zip:
        print("built", build_zip())


if __name__ == "__main__":
    main()
