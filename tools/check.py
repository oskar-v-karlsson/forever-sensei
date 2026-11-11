#!/usr/bin/env python3
"""tools/check.py: offline checks for ForeverSensei (no game needed).

1. Loads the addon in real Lua 5.1 (lupa) with a fake client (tools/wow_stub.lua) and drives every window and
   action in Japanese and English (tools/scenarios.lua): skill cards, trainer list, guide tabs, talent hints,
   full layout apply + undo, targeting switch, place-one, combat queue, reports, /sensei commands.
2. Static checks: English and Japanese text for every id, Japanese style rules (tools/textrules.py), layout
   (unique slots, allowed keys only, every spell placed once), talent path rules, data sources and dates, spell
   ids/names/levels against the Forever client dump (research/*.tsv), report format round-trip.

Usage: python3 tools/check.py      (exit code 1 on any problem)
"""
import csv
import os
import re
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ADDON = os.path.join(ROOT, "ForeverSensei")
sys.path.insert(0, os.path.join(ROOT, "tools"))

import textrules  # noqa: E402

try:
    import lupa.lua51 as lupa_mod
except ImportError:  # pragma: no cover
    try:
        import lupa as lupa_mod
    except ImportError:
        sys.exit("needs lupa: python3 -m pip install --user lupa")

problems = []


def problem(msg):
    problems.append(msg)


def read(path):
    with open(path, encoding="utf-8") as f:
        return f.read()


def toc_files():
    files = []
    for line in read(os.path.join(ADDON, "ForeverSensei.toc")).splitlines():
        line = line.strip()
        if line and not line.startswith("#"):
            files.append(line.replace("\\", "/"))
    return files


def py(obj, depth=0):
    """Lua table → dict / list (1..n tables become lists)."""
    if depth > 12 or not hasattr(obj, "items") or type(obj).__name__ != "_LuaTable":
        return obj
    d = {k: py(v, depth + 1) for k, v in obj.items()}
    if d and all(isinstance(k, int) for k in d) and sorted(d) == list(range(1, len(d) + 1)):
        return [d[i] for i in range(1, len(d) + 1)]
    return d


def new_runtime():
    lua = lupa_mod.LuaRuntime(unpack_returned_tuples=True)
    lua.execute(read(os.path.join(ROOT, "tools", "wow_stub.lua")))
    loader = lua.eval(
        """function(path, src, ns)
          local f, err = loadstring(src, "@" .. path)
          if not f then error(err, 0) end
          f("ForeverSensei", ns)
        end"""
    )
    ns = lua.table()
    for rel in toc_files():
        if not rel.endswith(".lua"):
            continue
        try:
            loader(rel, read(os.path.join(ADDON, rel)), ns)
        except Exception as e:  # noqa: BLE001
            problem(f"load {rel}: {e}")
    return lua, ns


def rank_levels():
    """Data/Shaman/Ranks.lua → {key: [(id, level), ...]} (levels from the generated comments)."""
    out = {}
    for m in re.finditer(r"^R\.(\w+) = \{ ([\d, ]+) \} -- Lv ([\d ]+)$",
                         read(os.path.join(ADDON, "Data", "Shaman", "Ranks.lua")), re.M):
        ids = [int(x) for x in m.group(2).split(",")]
        lvls = [int(x) for x in m.group(3).split()]
        out[m.group(1)] = list(zip(ids, lvls))
    return out


def login(lua, ns, level=20):
    """Fake character: every rank the player can have at this level is known (the client gives ranks with the trainer)."""
    stub = lua.globals().STUB
    data = ns.ClassData.SHAMAN
    ranks = rank_levels()
    for e in data.spells.values():
        for r, (rid, lv) in enumerate(ranks.get(e.key, [(e.id, e.level)]), 1):
            stub.names[rid] = e.name
            stub.levels[rid] = lv
            if e.key in ranks:
                stub.subtext[rid] = f"Rank {r}"
            if lv <= level and not e.talent:
                stub.known[rid] = True
    for t in data.talents.list.values():
        stub.names[t.id] = t.name
    stub.names[99999] = "Convection"  # a talent off the planned path
    stub.level = level
    stub.fire("ADDON_LOADED", "ForeverSensei")
    stub.fire("PLAYER_LOGIN")
    stub.fire("PLAYER_ENTERING_WORLD", True, False)
    stub.fire("SPELLS_CHANGED")
    stub.runTimers()


# ---------------------------------------------------------------------------------------------------------------
def check_runtime():
    reports = []
    for lang in ("ja", "en"):
        lua, ns = new_runtime()
        if problems:
            return reports
        login(lua, ns)
        run = lua.execute(read(os.path.join(ROOT, "tools", "scenarios.lua")))
        out = py(run(ns, lang))
        for e in out.get("errors") or []:
            problem("runtime " + e)
        reports.append(out.get("report"))
        shown = py(lua.globals().STUB.shown) or []
        bad_id = re.compile(r"\b(?:ui|spell|talent|guide)\.[a-z_]+\.[a-z_0-9.]+")
        for t in set(shown):
            if not isinstance(t, str):
                continue
            if re.search(r"\{\w+\}", t):
                problem(f"runtime [{lang}] unfilled placeholder shown: {t[:80]!r}")
            m = bad_id.search(t)
            # Intended: the report dialog shows the bare id, review rows show it in grey.
            if m and t.strip() != m.group(0) and ("|cffa6a6a6" + m.group(0)) not in t \
                    and not t.startswith("[ForeverSensei v"):
                problem(f"runtime [{lang}] raw text id shown: {m.group(0)}")
    return reports


# ---------------------------------------------------------------------------------------------------------------
NAMES = []


def font_chars(path):
    """Code points the TrueType font has glyphs for (cmap formats 4 and 12)."""
    import struct

    d = open(path, "rb").read()
    n = struct.unpack(">H", d[4:6])[0]
    tables = {}
    for i in range(n):
        tag, _, off, ln = struct.unpack(">4sIII", d[12 + 16 * i: 28 + 16 * i])
        tables[tag] = off
    base = tables[b"cmap"]
    count = struct.unpack(">H", d[base + 2: base + 4])[0]
    chars = set()
    for i in range(count):
        _, _, off = struct.unpack(">HHI", d[base + 4 + 8 * i: base + 12 + 8 * i])
        t = base + off
        fmt = struct.unpack(">H", d[t: t + 2])[0]
        if fmt == 4:
            segx2 = struct.unpack(">H", d[t + 6: t + 8])[0]
            seg = segx2 // 2
            ends = struct.unpack(f">{seg}H", d[t + 14: t + 14 + segx2])
            starts = struct.unpack(f">{seg}H", d[t + 16 + segx2: t + 16 + 2 * segx2])
            for s, e in zip(starts, ends):
                if s != 0xFFFF:
                    chars.update(range(s, e + 1))
        elif fmt == 12:
            ngroups = struct.unpack(">I", d[t + 12: t + 16])[0]
            for g in range(ngroups):
                s, e, _ = struct.unpack(">III", d[t + 16 + 12 * g: t + 28 + 12 * g])
                chars.update(range(s, e + 1))
    return chars


def check_static():
    lua, ns = new_runtime()
    if problems:
        return
    data = py(ns.ClassData.SHAMAN)
    en = py(ns.Locales.en)
    ja = py(ns.Locales.ja)
    sources = py(ns.Sources)
    spells = data["spells"]
    layout = data["layout"]
    talents = data["talents"]
    guide = data["guide"]

    items = py(ns.ItemData)
    NAMES.extend(s["name"] for s in spells)
    NAMES.extend(t["name"] for t in talents["list"])
    for kind in items["kinds"].values():
        NAMES.extend([kind["label"], kind["macro"]] + [i["name"] for i in kind["list"]])

    # --- texts ------------------------------------------------------------------------------------------------
    for k in en:
        if k not in ja:
            problem(f"text {k}: no Japanese")
    for k in ja:
        if k not in en:
            problem(f"text {k}: Japanese without English source")
    for k, v in en.items():
        if k in ja:
            for p in textrules.ja_problems(k, ja[k], v, NAMES):
                problem(f"ja {k}: {p}")
        if re.search(r"\.\.\.|  ", v):
            problem(f"en {k}: '...' or double space")

    # Every character of every text (and the UI symbols) must be in the bundled font.
    have = font_chars(os.path.join(ADDON, "Fonts", "ipagui.ttf"))
    code = "".join(read(os.path.join(dp, f)) for dp, _, fs in os.walk(os.path.join(ADDON, "Modules")) for f in fs)
    used = set("".join(ja.values()) + "".join(en.values())) | {c for c in code if ord(c) > 0x7F}
    missing = sorted(c for c in used if ord(c) >= 0x20 and ord(c) not in have)
    if missing:
        problem("font: no glyph for " + " ".join(f"{c!r} U+{ord(c):04X}" for c in missing))

    needed = set()
    for s in spells:
        needed |= {f"spell.{s['key']}.what", f"spell.{s['key']}.when"}
        needed |= {f"ui.role.{s['role']}", f"ui.use.{s['use']}"}
    for t in talents["list"]:
        needed.add(f"talent.{t['key']}.why")
    for sec in guide:
        needed.add(f"ui.tab.{sec['id']}")
        for i in range(1, len(sec["paragraphs"]) + 1):
            needed.add(f"guide.{sec['id']}.p{i}")
        if f"guide.{sec['id']}.p{len(sec['paragraphs']) + 1}" in en:
            problem(f"guide.{sec['id']}: more paragraphs in text than in Data/Shaman/Guide.lua")
    for bar in layout["bars"]:
        needed.add(f"ui.bar.{bar['id']}")
    for bar in layout.get("retired") or []:
        needed.add(f"ui.bar.{bar['id']}")
    for kind in set(layout["noSlot"].values()):
        needed.add(f"ui.where.{kind}")
    for code in py(ns.Feedback.REASONS):
        needed.add(f"ui.reason.{code}")
    guide_src = read(os.path.join(ADDON, "Modules", "Guide.lua"))
    tabs = re.search(r"local TABS = \{([^}]*)\}", guide_src).group(1)
    needed |= {f"ui.tab.{t}" for t in re.findall(r'"(\w+)"', tabs)}
    # Literal ids in code.
    for dirpath, _, files in os.walk(ADDON):
        for fn in files:
            if fn.endswith(".lua") and "Locales" not in dirpath:
                src = read(os.path.join(dirpath, fn))
                needed |= set(re.findall(r'"((?:ui|spell|talent|guide)\.[a-z_0-9]+(?:\.[a-z_0-9]+)*)"', src))
    for k in sorted(needed):
        if k not in en:
            problem(f"text {k}: used but not in Locales/en.lua")
    unused = sorted(k for k in en if k not in needed)
    for k in unused:
        problem(f"text {k}: not used anywhere (remove it or use it)")

    # --- spells -----------------------------------------------------------------------------------------------
    keys = [s["key"] for s in spells]
    if len(set(keys)) != len(keys):
        problem("spells: duplicate key")
    for s in spells:
        for f in ("key", "name", "id", "level", "role", "use", "src", "verified"):
            if s.get(f) in (None, ""):
                problem(f"spell {s.get('key')}: missing {f}")
        if s.get("role") not in ("heal", "damage", "support"):
            problem(f"spell {s['key']}: bad role")
        if s.get("use") not in ("group", "solo", "both"):
            problem(f"spell {s['key']}: bad use")
        if s.get("src") not in sources:
            problem(f"spell {s['key']}: unknown source {s.get('src')}")
        if not re.fullmatch(r"\d{4}-\d\d-\d\d", str(s.get("verified"))):
            problem(f"spell {s['key']}: verified date must be YYYY-MM-DD")
        if not 1 <= int(s.get("level") or 0) <= 60:
            problem(f"spell {s['key']}: level out of range")

    tsv = os.path.join(ROOT, "research", "shaman_simc_1.60.1.70862.tsv")
    if os.path.exists(tsv):
        with open(tsv, encoding="utf-8") as f:
            rows = {int(r["id"]): r for r in csv.DictReader(f, delimiter="\t")}
        for s in spells:
            if s.get("src") != "simc":
                continue  # sourced from a Wowhead Forever page; /sensei verify checks it in-game
            r = rows.get(int(s["id"]))
            if not r:
                problem(f"spell {s['key']}: id {s['id']} not in the Forever client dump")
                continue
            if r["name"] != s["name"]:
                problem(f"spell {s['key']}: name {s['name']!r} but client has {r['name']!r}")
            lvl = re.match(r"\d+", str(r.get("level") or ""))
            if not s.get("talent") and lvl and int(lvl.group(0)) not in (0, int(s["level"])):
                problem(f"spell {s['key']}: level {s['level']} but client has {r['level']}")
        for t in talents["list"]:
            r = rows.get(int(t["id"]))
            if not r:
                problem(f"talent {t['key']}: id {t['id']} not in the Forever client dump")
            elif r["name"] != t["name"]:
                problem(f"talent {t['key']}: name {t['name']!r} but client has {r['name']!r}")
        # Ranks.lua is generated from the same dump: it must be up to date, and every rank id must be in the dump
        # with the spell's name and "Rank N".
        gen = subprocess.run([sys.executable, os.path.join(ROOT, "tools", "research", "gen_ranks.py"), "--check"],
                             capture_output=True, text=True)
        if gen.returncode != 0:
            problem("ranks: " + (gen.stdout + gen.stderr).strip())
        by_key = {s["key"]: s for s in spells}
        for key, lst in rank_levels().items():
            if key not in by_key:
                problem(f"ranks: {key} is not a spell in Spells.lua")
                continue
            if lst[0][0] != int(by_key[key]["id"]):
                problem(f"ranks: {key} rank 1 is {lst[0][0]}, Spells.lua has {by_key[key]['id']}")
            for n, (rid, lv) in enumerate(lst, 1):
                r = rows.get(rid)
                if not r or r["name"] != by_key[key]["name"] or r.get("rank") != f"Rank {n}":
                    problem(f"ranks: {key} rank {n} id {rid} does not match the client dump")
            if [lv for _, lv in lst] != sorted(lv for _, lv in lst):
                problem(f"ranks: {key} levels not ascending")
    else:
        problem("research TSV missing: cannot cross-check spells")

    # --- layout -----------------------------------------------------------------------------------------------
    slots = layout["slots"]
    seen_slot, seen_key, seen_spell = {}, {}, {}
    allowed = set(layout["allowedKeys"])

    def what(s):
        return s.get("spell") or "@" + str(s.get("item"))

    for s in slots:
        if bool(s.get("spell")) == bool(s.get("item")):
            problem(f"layout: slot {s['slot']} must hold exactly one spell or item")
        for kind, seen, val in (("slot", seen_slot, s["slot"]), ("key", seen_key, s.get("key")), ("entry", seen_spell, what(s))):
            if val is None:
                continue
            if val in seen:
                problem(f"layout: {kind} {val} used twice ({seen[val]} and {what(s)})")
            seen[val] = what(s)
        if s.get("key") and s["key"] not in allowed:
            problem(f"layout: key {s['key']} not allowed")
        if s.get("spell") and s["spell"] not in keys:
            problem(f"layout: unknown spell {s['spell']}")
        if s.get("item") and s["item"] not in items["kinds"]:
            problem(f"layout: unknown item kind {s['item']}")
        if s.get("item") and s.get("key") not in (None, "Z", "C"):
            problem(f"layout: item @{s['item']} on key {s.get('key')} (only FS_MANA on Z and FS_HEALTH on C have keys)")
        for opt in ("standIn", "after"):
            if s.get(opt) and s[opt] not in keys:
                problem(f"layout: slot {s['slot']} {opt} {s[opt]} is not a spell")
    for slot_ in layout["spare"]:
        if slot_["slot"] in seen_slot:
            problem(f"layout: spare slot {slot_['slot']} is also planned")
    bar_slots = {}
    for bar in layout["bars"]:
        r = set(range(bar["first"], bar["first"] + 12))
        if any(r & other for other in bar_slots.values()):
            problem(f"layout: bar {bar['id']} overlaps another bar's slots")
        bar_slots[bar["id"]] = r
    for kind in items["kinds"]:
        if "@" + kind not in seen_spell:
            problem(f"layout: item kind {kind} has no slot")
    for k in keys:
        placed = k in seen_spell
        unslotted = k in layout["noSlot"]
        if placed == unslotted:
            problem(f"layout: spell {k} must be in exactly one of the plan or noSlot")
    for k, m in layout["macros"].items():
        if k not in seen_spell:
            problem(f"layout: macro for unplaced spell {k}")
        if len(m) > 16:
            problem(f"layout: macro name {m} too long")
    # The approved grid (research/keybind-layout.md (a) at ecf40ec; layout 5 keeps the keys, makes Action Bar 5 the
    # Ctrl mirror of Action Bar 2 and moves the mouse buttons to Action Bar 3 7-12): every key holds exactly this.
    grid = {
        "1": "totemic_call", "2": "flame_shock", "3": "lightning_bolt", "4": "chain_lightning",
        "Q": "earth_shock", "E": "lesser_healing_wave", "R": "chain_heal", "F": "healing_wave",
        "Z": "@mana", "X": "water_shield", "C": "@health",
        "SHIFT-1": "call_of_the_elements", "SHIFT-3": "purge", "SHIFT-Q": "frost_shock",
        "SHIFT-E": "stoneskin_totem", "SHIFT-R": "searing_totem", "SHIFT-F": "tremor_totem",
        "SHIFT-Z": "mana_spring_totem",
        "CTRL-1": "totemic_recall", "CTRL-Q": "earthbind_totem", "CTRL-E": "stoneclaw_totem",
        "CTRL-F": "grounding_totem", "CTRL-Z": "mana_tide_totem", "CTRL-C": "ghost_wolf",
        "BUTTON4": "riptide", "BUTTON5": "natures_swiftness",
        "SHIFT-BUTTON4": "cure_poison", "SHIFT-BUTTON5": "cure_disease",
        "CTRL-BUTTON4": "poison_cleansing_totem", "CTRL-BUTTON5": "disease_cleansing_totem",
    }
    by_key = {s["key"]: what(s) for s in slots if s.get("key")}
    for k in sorted(set(grid) | set(by_key)):
        if by_key.get(k) != grid.get(k):
            problem(f"layout: key {k} must be {grid.get(k)}, has {by_key.get(k)}")
    # Keyed bars bind every button, also those without a skill (spare keys), so the plain, Shift and Ctrl rows match.
    spare_keys = {x["key"] for x in layout["spare"] if x.get("key")}
    if spare_keys & set(grid):
        problem(f"layout: spare key also in the grid {sorted(spare_keys & set(grid))}")
    for x in layout["spare"]:
        b = next(b for b in layout["bars"] if b["id"] == x["bar"])
        want = (b.get("keys") or [None] * 12)[x["button"] - 1] or None
        if x.get("key") != want or (want and x.get("binding") != b["binding"] % x["button"]):
            problem(f"layout: spare slot {x['slot']} key {x.get('key')} is not its bar's key {want}")
    if allowed != set(grid) | spare_keys:
        problem(f"layout: allowedKeys must be exactly the grid's and spare keys (diff {sorted(allowed ^ (set(grid) | spare_keys))})")
    # Lightning Shield stands in on X until Water Shield is learned, then moves to its own clickable button.
    x = next((s for s in slots if s.get("key") == "X"), {})
    ls = next((s for s in slots if s.get("spell") == "lightning_shield"), {})
    if x.get("standIn") != "lightning_shield" or ls.get("after") != "water_shield" or ls.get("key"):
        problem("layout: X must be Water Shield with Lightning Shield standing in until it is learned")
    # 5, Shift+5 and Ctrl+5 are the player's own: never bound, never planned, never spare.
    if layout.get("ownKeys") != ["5", "SHIFT-5", "CTRL-5"]:
        problem("layout: ownKeys must be 5, SHIFT-5 and CTRL-5")
    if set(layout.get("ownKeys") or []) & allowed:
        problem("layout: an own key is in allowedKeys")
    bars = {b["id"]: b for b in layout["bars"]}
    spare_slots = {x["slot"] for x in layout["spare"]}
    for bid in ("main", "bar2", "bar5"):
        own = bars[bid]["first"] + 4
        if own in seen_slot or own in spare_slots:
            problem(f"layout: own button {own} ({bid} 5) is planned or spare")
        if bars[bid]["keys"][4] not in layout["ownKeys"]:
            problem(f"layout: {bid} button 5 key must be an own key")
    if sorted(int(x) for x in (layout.get("own") or {})) != sorted(bars[b]["first"] + 4 for b in ("main", "bar2", "bar5")):
        problem("layout: own slots must be exactly main 5, bar2 5 and bar5 5 (5, Shift+5 and Ctrl+5)")
    for b in layout["bars"]:
        mine = {"main": {"5"}, "bar2": {"SHIFT-5"}, "bar5": {"CTRL-5"}}.get(b["id"], set())
        if (set(layout["ownKeys"]) - mine) & set(b.get("keys") or []):
            problem(f"layout: bar {b['id']} lists another bar's own key")
    # Action Bar 5 (MultiBarLeft, shown at the right edge) is the Ctrl mirror of Action Bar 2: button i has Ctrl where
    # bar 2 has Shift. The mouse buttons use Action Bar 3 7-12. Action Bars 6 and 7 (layout 3) showed up in the middle
    # of the screen: they are retired, never used or shown again.
    b5 = bars.get("bar5", {})
    want_keys = [k.replace("SHIFT-", "CTRL-") for k in bars["bar2"]["keys"]]
    if not all(k.startswith("SHIFT-") for k in bars["bar2"]["keys"]) or len(want_keys) != 12:
        problem("layout: bar2 must have 12 Shift keys")
    if (b5.get("first"), b5.get("binding"), b5.get("setting"), b5.get("keys")) != (
            37, "MULTIACTIONBAR4BUTTON%d", "PROXY_SHOW_ACTIONBAR_5", want_keys):
        problem("layout: bar5 must be first 37, MULTIACTIONBAR4BUTTON%d, PROXY_SHOW_ACTIONBAR_5 with bar2's keys as Ctrl")
    mouse = ["BUTTON4", "BUTTON5", "SHIFT-BUTTON4", "SHIFT-BUTTON5", "CTRL-BUTTON4", "CTRL-BUTTON5"]
    b3keys = [k or None for k in (bars.get("bar3", {}).get("keys") or [])]
    if b3keys != [None] * 6 + mouse or bars.get("bar3", {}).get("binding") != "MULTIACTIONBAR2BUTTON%d":
        problem("layout: bar3 buttons 7-12 must hold the mouse keys (MULTIACTIONBAR2BUTTON), 1-6 no key")
    retired = {(r.get("id"), r.get("first"), r.get("binding"), r.get("setting"), r.get("own"))
               for r in layout.get("retired") or []}
    if retired != {("bar6", 145, "MULTIACTIONBAR5BUTTON%d", "PROXY_SHOW_ACTIONBAR_6", 5),
                   ("bar7", 157, "MULTIACTIONBAR6BUTTON%d", "PROXY_SHOW_ACTIONBAR_7", None)}:
        problem("layout: retired must be exactly Action Bars 6 and 7")
    assigned = {r.get("id"): r.get("assigned") for r in layout.get("retired") or []}
    if assigned.get("bar6") != [1, 6, 7, 9, 10, 12] or assigned.get("bar7") != [1, 2, 3, 4, 5, 6]:
        problem("layout: retired assigned must be layout 3's buttons (bar6 1,6,7,9,10,12; bar7 1-6)")
    for b in layout["bars"]:
        if b["first"] >= 145 or b.get("setting") in ("PROXY_SHOW_ACTIONBAR_6", "PROXY_SHOW_ACTIONBAR_7") \
                or re.match(r"MULTIACTIONBAR[56]BUTTON", b.get("binding") or ""):
            problem(f"layout: bar {b['id']} uses retired Action Bar 6 or 7")
    for s in slots:
        if s["slot"] >= 145:
            problem(f"layout: slot {s['slot']} is on retired Action Bar 6 or 7")
    for s in slots:
        b = bars[s["bar"]]
        want = (b.get("keys") or [None] * 12)[s["button"] - 1] if s["button"] <= len(b.get("keys") or []) else None
        if s.get("key") and s["key"] != want:
            problem(f"layout: slot {s['slot']} key {s['key']} is not its bar's key {want}")
    # Macros: the kinds exist, mouseover heals and cures, interrupt with /stopcasting, NS + Healing Wave.
    bodies = layout["macroBodies"]
    want_macros = {"healing_wave", "lesser_healing_wave", "chain_heal", "riptide", "cure_poison", "cure_disease",
                   "earth_shock", "purge", "natures_swiftness"}
    if set(layout["macros"]) != want_macros:
        problem(f"layout: macros must be {sorted(want_macros)}")
    for k, kind in layout["macroKind"].items():
        if k not in layout["macros"] or kind not in bodies:
            problem(f"layout: macroKind {k} = {kind} has no macro or body")
    for k in layout["macroAlways"]:
        if k not in layout["macros"]:
            problem(f"layout: macroAlways {k} is not a macro")
    for kind, body in bodies.items():
        if "{spell}" not in body or not body.startswith("#showtooltip"):
            problem(f"layout: macro body {kind} must start with #showtooltip and use {{spell}}")
        base = kind.removesuffix("_click")
        if base != kind and base not in bodies:
            problem(f"layout: macro body {kind} has no {base}")
        if base == "nshw" and "{heal}" not in body:
            problem(f"layout: macro body {kind} must cast {{heal}}")
        if base == "interrupt" and "/stopcasting" not in body:
            problem(f"layout: macro body {kind} must /stopcasting")
        if kind in ("help", "nshw") and "@mouseover,help" not in body:
            problem(f"layout: macro body {kind} must use the friendly mouseover")
        if kind in ("harm", "interrupt") and "@mouseover,harm" not in body:
            problem(f"layout: macro body {kind} must use the enemy mouseover")
    kinds_used = {layout["macroKind"].get(k, "help") for k in layout["macros"]}
    if {"interrupt", "harm", "nshw", "help"} - kinds_used:
        problem("layout: earth_shock interrupt, purge harm and the NS + Healing Wave macro are required")
    # Character macros: Forever allows 30 (MAX_CHARACTER_MACROS); leave most of them to the player.
    n_macros = len(layout["macros"]) + len(items["kinds"])
    if n_macros > 15:
        problem(f"layout: {n_macros} addon macros (keep it at 15 or fewer of the 30 character macros)")
    # Earlier layouts' leftovers are cleared only from buttons that are spare now.
    for slot_, key in (layout.get("old") or {}).items():
        if int(slot_) not in spare_slots or key not in keys:
            problem(f"layout: old slot {slot_} ({key}) must be spare now and a spell")
    if not isinstance(layout.get("version"), (int, float)) or layout["version"] < 5:
        problem("layout: version missing (bump it when slots or keys change)")

    # --- items ------------------------------------------------------------------------------------------------
    if items.get("src") not in sources:
        problem(f"items: unknown source {items.get('src')}")
    if not re.fullmatch(r"\d{4}-\d\d-\d\d", str(items.get("verified"))):
        problem("items: verified date must be YYYY-MM-DD")
    seen_ids = set()
    for kind, d in items["kinds"].items():
        if len(d["macro"]) > 16 or not d["macro"].startswith("FS_"):
            problem(f"items {kind}: bad macro name {d['macro']}")
        if not re.fullmatch(r"INV_\w+", d["icon"]):
            problem(f"items {kind}: bad icon {d['icon']}")
        last = 99
        for i in d["list"]:
            if not isinstance(i.get("id"), (int, float)) or not i.get("name"):
                problem(f"items {kind}: entry without id or name")
                continue
            if i["id"] in seen_ids:
                problem(f"items {kind}: id {i['id']} listed twice")
            seen_ids.add(i["id"])
            lv = i.get("level") or 0
            if lv > last:
                problem(f"items {kind}: {i['name']} ({i['id']}) is listed after a lower-level item (best first)")
            last = lv if lv else last
        if d["list"] and d["list"][-1].get("level"):
            problem(f"items {kind}: the last item should need no level (macro fallback for low levels)")

    # --- talents ----------------------------------------------------------------------------------------------
    by = {t["key"]: t for t in talents["list"]}
    order = talents["order"]
    levels = [o["level"] for o in order]
    if levels != list(range(10, 61)):
        problem("talents: path must give exactly one point per level 10-60")
    spent = {}
    total = 0
    for o in order:
        t = by.get(o["key"])
        if not t:
            problem(f"talents: unknown talent {o['key']}")
            continue
        if total < 5 * (t["row"] - 1):
            problem(f"talents: {o['key']} (row {t['row']}) at level {o['level']} needs {5 * (t['row'] - 1)} points, has {total}")
        if t.get("requires") and spent.get(t["requires"], 0) < by[t["requires"]]["max"]:
            problem(f"talents: {o['key']} needs {t['requires']} maxed first")
        spent[o["key"]] = spent.get(o["key"], 0) + 1
        if spent[o["key"]] > t["max"]:
            problem(f"talents: {o['key']} above max rank")
        total += 1
    for t in talents["list"]:
        if t["key"] not in spent:
            problem(f"talents: {t['key']} listed but never taken")
    tree_points = {}
    for k, n in spent.items():
        tree_points[by[k]["tree"]] = tree_points.get(by[k]["tree"], 0) + n
    if tree_points.get("Restoration") != 46 or tree_points.get("Enhancement") != 5:
        problem(f"talents: final build should be 0/5/46 (Mobalytics), is {tree_points}")

    # --- guide ------------------------------------------------------------------------------------------------
    for sec in guide:
        for i, p in enumerate(sec["paragraphs"], 1):
            for src in p.get("src") or []:
                if src not in sources:
                    problem(f"guide.{sec['id']}.p{i}: unknown source {src}")
            if not p.get("src"):
                problem(f"guide.{sec['id']}.p{i}: no source")

    # --- TOC --------------------------------------------------------------------------------------------------
    toc = read(os.path.join(ADDON, "ForeverSensei.toc"))
    for rel in toc_files():
        if not os.path.exists(os.path.join(ADDON, rel)):
            problem(f"toc: missing file {rel}")
    if "## Interface: 16001" not in toc:
        problem("toc: Interface must be 16001 (WoW: Forever 1.60.1)")
    if "## SavedVariables: ForeverSenseiDB" not in toc:
        problem("toc: SavedVariables ForeverSenseiDB missing")


def check_reports(texts):
    try:
        import reports
    except ImportError as e:
        problem(f"reports.py: {e}")
        return
    for text in texts:
        if not text:
            problem("reports: nothing formatted")
            continue
        parsed = reports.parse(text)
        want = [
            {"id": "spell.chain_heal.when", "reason": "不自然", "suggestion": "2人以上が傷ついている時に使おう。", "note": None},
            {"id": "guide.healing.p3", "reason": "わかりにくい", "suggestion": None, "note": "line one\nline two | x"},
        ]
        got = [{k: r.get(k) for k in ("id", "reason", "suggestion", "note")} for r in parsed["reports"]]
        if got != want:
            problem(f"reports: round-trip mismatch\n{text}\n→ {got}")
        if not parsed.get("version"):
            problem("reports: version not parsed")


def main():
    check_static()
    if not problems:
        texts = check_runtime()
        check_reports(texts)
    for p in problems:
        print("FAIL", p)
    if problems:
        print(f"\n{len(problems)} problem(s)")
        sys.exit(1)
    print("all checks passed")


if __name__ == "__main__":
    main()
