#!/usr/bin/env python3
"""Parse a SimulationCraft SpellDataDump class file (e.g. simc-forever shaman.txt or paladin.txt)
into a TSV used as research evidence for the class packs (ForeverSensei_<Class>/Data).

Usage: python3 tools/research/parse_simc.py <class.txt> [out.tsv]
Source: https://github.com/simulationcraft/simc-forever/tree/HEAD/SpellDataDump (one file per class)

The last columns were added for the paladin research (0.6.0): gcd (empty = off the global cooldown),
category cooldown, stacks and the buff tooltip. Columns are read by name, so older TSVs still work.
"""
import re
import sys

FIELDS = ["id", "name", "rank", "level", "passive", "talent", "cast", "cooldown",
          "resource", "range", "duration", "labels", "description",
          "gcd", "category_cooldown", "stacks", "tooltip"]


def parse(text):
    blocks = re.split(r"\n(?=Name\s+:)", text)
    for b in blocks:
        m = re.match(r"Name\s+:\s+(.+?)\s+\(id=(\d+)\)(.*)", b)
        if not m:
            continue
        head, sid, tags = m.group(1), m.group(2), m.group(3)
        rank = ""
        rm = re.search(r"\(desc=([^)]*)\)", head)
        if rm:
            rank = rm.group(1)
            head = head[: rm.start()].strip()

        def field(key):
            fm = re.search(r"^" + re.escape(key) + r"\s*:\s*(.*)$", b, re.M)
            return fm.group(1).strip() if fm else ""

        yield {
            "id": sid,
            "name": head,
            "rank": rank,
            "level": field("Spell Level"),
            "passive": "passive" if "[Passive]" in tags else "",
            "talent": field("Talent Entry"),
            "cast": field("Cast Time"),
            "cooldown": field("Cooldown"),
            "resource": field("Resource"),
            "range": field("Range"),
            "duration": field("Duration"),
            "labels": field("Labels"),
            "description": field("Description").replace("\t", " "),
            "gcd": field("GCD"),
            "category_cooldown": field("Category Cooldown"),
            "stacks": field("Stacks"),
            "tooltip": field("Tooltip").replace("\t", " "),
        }


def main():
    text = open(sys.argv[1], encoding="utf-8").read()
    out = open(sys.argv[2], "w", encoding="utf-8") if len(sys.argv) > 2 else sys.stdout
    out.write("\t".join(FIELDS) + "\n")
    for row in parse(text):
        out.write("\t".join(row[f] for f in FIELDS) + "\n")


if __name__ == "__main__":
    main()
