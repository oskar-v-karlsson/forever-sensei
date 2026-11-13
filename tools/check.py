#!/usr/bin/env python3
"""tools/check.py: offline checks for ForeverSensei and its class packs (no game needed).

1. Loads the core addon (ForeverSensei/) in real Lua 5.1 (lupa) with a fake client (tools/wow_stub.lua). Class packs
   (every ForeverSensei_<Class>/ folder) load on demand through the fake C_AddOns.LoadAddOn, like in the game.
   - Shaman flow: drives every window and action in Japanese and English (tools/scenarios.lua): skill cards,
     trainer list, guide tabs, talent hints, full layout apply + undo, targeting switch, place-one, combat queue,
     reports, /sensei commands.
   - No pack for the class (a Warrior): one quiet note per character, the addon stays idle, /sensei still opens.
   - Pack for another API version: not loaded, one note.
2. Static checks: English and Japanese text for every id in every locale file (core and packs), Japanese style rules
   (tools/textrules.py), which file owns which text, pack TOCs, layout (unique slots, allowed keys only, every spell
   placed once), talent path rules, data sources and dates, and per-class checks (PACK_CHECKS; the Shaman one checks
   the approved key grid and the spell ids/names/levels against the Forever client dump in research/*.tsv), report
   format round-trip.

Usage: python3 tools/check.py      (exit code 1 on any problem)
"""
import csv
import os
import re
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CORE = "ForeverSensei"
ADDON = os.path.join(ROOT, CORE)
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


def toc(folder):
    """→ (metadata {field: value}, files [relative paths]) of <folder>/<folder>.toc."""
    meta, files = {}, []
    for line in read(os.path.join(ROOT, folder, folder + ".toc")).splitlines():
        line = line.strip()
        m = re.match(r"^## ([\w-]+): (.*)$", line)
        if m:
            meta[m.group(1)] = m.group(2).strip()
        elif line and not line.startswith("#"):
            files.append(line.replace("\\", "/"))
    return meta, files


def pack_folders():
    """Every class pack: a ForeverSensei_<Class>/ folder with its TOC."""
    return sorted(d for d in os.listdir(ROOT)
                  if d.startswith(CORE + "_") and os.path.isfile(os.path.join(ROOT, d, d + ".toc")))


def pack_class(folder):
    """ForeverSensei_Shaman → SHAMAN"""
    return folder[len(CORE) + 1:].upper()


def lua_files(folder, locales=True):
    for dirpath, _, files in os.walk(os.path.join(ROOT, folder)):
        for fn in sorted(files):
            if fn.endswith(".lua") and (locales or "Locales" not in dirpath):
                yield os.path.join(dirpath, fn)


def py(obj, depth=0):
    """Lua table → dict / list (1..n tables become lists)."""
    if depth > 12 or not hasattr(obj, "items") or type(obj).__name__ != "_LuaTable":
        return obj
    d = {k: py(v, depth + 1) for k, v in obj.items()}
    if d and all(isinstance(k, int) for k in d) and sorted(d) == list(range(1, len(d) + 1)):
        return [d[i] for i in range(1, len(d) + 1)]
    return d


LOADER = """
STUB.packFiles = {}
-- Loads a class pack's TOC files with the addon's own private table, like the client's LoadAddOn.
STUB.loadAddOn = function(name)
  local files = STUB.packFiles[name]
  if not files then return false, "MISSING" end
  local P = {}
  for _, f in ipairs(files) do
    local fn, err = loadstring(f[2], "@" .. name .. "/" .. f[1])
    if not fn then error(err, 0) end
    fn(name, P)
  end
  STUB.fire("ADDON_LOADED", name)
  return true
end
-- Saved variables as Lua source (to carry ForeverSenseiDB into the next fake session).
STUB.serialize = function(v)
  if type(v) == "table" then
    local parts = {}
    for k, x in pairs(v) do table.insert(parts, "[" .. STUB.serialize(k) .. "]=" .. STUB.serialize(x)) end
    return "{" .. table.concat(parts, ",") .. "}"
  elseif type(v) == "string" then
    return string.format("%q", v)
  end
  return tostring(v)
end
"""


def new_runtime(cls="SHAMAN", meta=None, db=None, skip=()):
    """A fresh fake client with the core loaded (not logged in). meta: {pack folder: {TOC field: value}} overrides.
    db: ForeverSenseiDB from an earlier session (Lua source). skip: pack folders not installed."""
    lua = lupa_mod.LuaRuntime(unpack_returned_tuples=True)
    lua.execute(read(os.path.join(ROOT, "tools", "wow_stub.lua")))
    lua.execute(LOADER)
    stub = lua.globals().STUB
    stub["class"] = cls
    loader = lua.eval(
        """function(path, src, ns)
          local f, err = loadstring(src, "@" .. path)
          if not f then error(err, 0) end
          f("ForeverSensei", ns)
        end"""
    )
    ns = lua.table()
    for rel in toc(CORE)[1]:
        if not rel.endswith(".lua"):
            continue
        try:
            loader(rel, read(os.path.join(ADDON, rel)), ns)
        except Exception as e:  # noqa: BLE001
            problem(f"load {CORE}/{rel}: {e}")
    for folder in pack_folders():
        if folder in skip:
            continue
        m, files = toc(folder)
        m.update((meta or {}).get(folder) or {})
        stub.addonMeta[folder] = lua.table_from(m)
        stub.packFiles[folder] = lua.table_from(
            [lua.table_from([rel, read(os.path.join(ROOT, folder, rel))]) for rel in files if rel.endswith(".lua")])
    if db:
        lua.execute("ForeverSenseiDB = " + db)
    return lua, ns


def rank_levels(folder):
    """<pack>/Data/Ranks.lua → {key: [(id, level), ...]} (levels from the generated comments)."""
    out = {}
    path = os.path.join(ROOT, folder, "Data", "Ranks.lua")
    if not os.path.exists(path):
        return out
    for m in re.finditer(r"^R\.(\w+) = \{ ([\d, ]+) \} -- Lv ([\d ]+)$", read(path), re.M):
        ids = [int(x) for x in m.group(2).split(",")]
        lvls = [int(x) for x in m.group(3).split()]
        out[m.group(1)] = list(zip(ids, lvls))
    return out


PACKS = {}  # class file → {"folder", "spells", "talents"} (from the static checks, for the fake characters)


def login(lua, ns, level=20):
    """Fake character of STUB.class: every rank the player can have at this level is known (the client gives ranks
    with the trainer). Then the login events, which load the class pack."""
    stub = lua.globals().STUB
    data = PACKS.get(stub["class"])
    if data:
        ranks = rank_levels(data["folder"])
        race_id = stub.race[3]
        for e in data["spells"]:
            if e.get("races") and race_id not in e["races"]:
                continue  # another race's racial: not in this character's spellbook
            for r, (rid, lv) in enumerate(ranks.get(e["key"], [(e["id"], e["level"])]), 1):
                stub.names[rid] = e["name"]
                stub.levels[rid] = lv
                if e["key"] in ranks:
                    stub.subtext[rid] = f"Rank {r}"
                if lv <= level and not e.get("talent"):
                    stub.known[rid] = True
        for t in data["talents"]:
            stub.names[t["id"]] = t["name"]
    stub.names[99999] = "Convection"  # a talent off the planned path
    stub.level = level
    stub.fire("ADDON_LOADED", "ForeverSensei")
    stub.fire("PLAYER_LOGIN")
    stub.fire("PLAYER_ENTERING_WORLD", True, False)
    stub.fire("SPELLS_CHANGED")
    stub.runTimers()


# ---------------------------------------------------------------------------------------------------------------
def check_shown(lua, lang):
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


def check_runtime():
    reports = []
    for lang in ("ja", "en"):
        # A player from before 0.5.1 (saved settings): no language window.
        lua, ns = new_runtime(db="{ settings = { language = %r } }" % lang)
        if problems:
            return reports
        stub = lua.globals().STUB
        login(lua, ns)
        if stub.loadCalls != 1 or not stub.loaded["ForeverSensei_Shaman"]:
            problem(f"runtime [{lang}] ForeverSensei_Shaman was not loaded once at login (LoadAddOn calls: {stub.loadCalls})")
        if ns.packNote is not None or ns.char.packNote is not None:
            problem(f"runtime [{lang}] a Shaman with the pack got a pack note")
        run = lua.execute(read(os.path.join(ROOT, "tools", "scenarios.lua")))
        out = py(run(ns, lang))
        for e in out.get("errors") or []:
            problem("runtime " + e)
        reports.append(out.get("report"))
        check_shown(lua, lang)
    for lang in ("ja", "en"):
        # Protection Paladin: the paladin pack loads, the shaman pack stays unloaded.
        lua, ns = new_runtime(cls="PALADIN", db="{ settings = { language = %r } }" % lang)
        stub = lua.globals().STUB
        login(lua, ns)
        if stub.loadCalls != 1 or not stub.loaded["ForeverSensei_Paladin"] or stub.loaded["ForeverSensei_Shaman"]:
            problem(f"runtime paladin [{lang}] ForeverSensei_Paladin was not the one pack loaded at login")
        if ns.packNote is not None:
            problem(f"runtime paladin [{lang}] a Paladin with the pack got a pack note")
        run = lua.execute(read(os.path.join(ROOT, "tools", "scenarios_paladin.lua")))
        out = py(run(ns, lang))
        for e in out.get("errors") or []:
            problem("runtime " + e)
        check_shown(lua, "paladin " + lang)
    for lang in ("ja", "en"):
        check_idle(lang)
        # A Paladin with only the Shaman pack installed: the same note, idle.
        check_idle(lang, "PALADIN", skip=("ForeverSensei_Paladin",))
        check_api_mismatch(lang)
        check_races(lang)
    check_language()
    return reports


def check_races(lang):
    """The Skyborne racials (layout 8) are race-gated: an Orc shaman gets no card, slot or BUTTON3 key for them, the
    Skyborne race without Skysight gets only Walk on Air, and a known racial always counts."""
    for label, race, known, want in (("Orc", ("Orc", "Orc", 2), (), set()),
                                     ("High Order", ("Skyborne", "Skyborne", 33), (), {"walk_on_air"}),
                                     ("unknown id", ("Skyborne", "Skyborne", 99), (1259416,), {"walk_on_air"})):
        label = f"runtime races {label} [{lang}]"
        lua, ns = new_runtime(db="{ settings = { language = %r } }" % lang)
        stub = lua.globals().STUB
        stub.race = lua.table_from(list(race))
        for sid in known:
            stub.known[sid] = True
        login(lua, ns, 60)
        listed = {e["key"] for e in (py(ns.Spells.List()) or [])}
        L = ns.spec.layout
        got = {k for k in ("walk_on_air", "skysight") if k in listed}
        if got != want:
            problem(f"{label}: racials {sorted(got)} in the skill list, expected {sorted(want)}")
        slots = {k for k in ("walk_on_air", "skysight") if L.bySpell[k] is not None}
        if slots != want:
            problem(f"{label}: racials {sorted(slots)} have a slot, expected {sorted(want)}")
        gated = {int(k) for k in (py(L.gatedSlots) or {})}
        want_gated = {n for k, n in (("walk_on_air", 153), ("skysight", 154)) if k not in want}
        if gated != want_gated:
            problem(f"{label}: gated slots {sorted(gated)}, expected {sorted(want_gated)}")
        ns.Layout.Execute(ns.Layout.BuildPlan())
        stub.runTimers()
        acts = py(stub.actions) or {}
        if ("walk_on_air" in want) != (stub.bindings["BUTTON3"] == "MULTIACTIONBAR5BUTTON9"):
            problem(f"{label}: BUTTON3 is {stub.bindings['BUTTON3']}")
        for slot in want_gated:
            if slot in acts:
                problem(f"{label}: gated slot {slot} was filled with {acts[slot]}")
        for tab in ("role", "skills", "layout"):
            ns.Guide.Open(tab)
        stub.runTimers()
        for e in unexpected_errors(ns):
            problem(f"{label}: ns.errors: {e}")


WINDOWS = ("ForeverSenseiCard", "ForeverSenseiTrainer", "ForeverSenseiTalentHint", "ForeverSenseiPreview",
           "ForeverSenseiGuide", "ForeverSenseiConfirm", "ForeverSenseiCopy")


def shown_windows(lua):
    g = lua.globals()
    return [w for w in WINDOWS if g[w] is not None and g[w].IsShown(g[w])]


def picker_shown(lua):
    g = lua.globals()
    return g.ForeverSenseiLanguage is not None and g.ForeverSenseiLanguage.IsShown(g.ForeverSenseiLanguage)


def check_language():
    """The language window: fresh install asks once, holds everything back, and the choice is kept."""
    label = "runtime language"
    # Fresh install (no ForeverSenseiDB): the window, nothing else.
    lua, ns = new_runtime()
    stub = lua.globals().STUB
    g = lua.globals()
    login(lua, ns)
    welcome = {ns.Raw("ui.welcome", "ja"), ns.Raw("ui.welcome", "en")}
    if not picker_shown(lua):
        problem(f"{label}: fresh install did not show the language window")
    if ns.settings.languageChosen:
        problem(f"{label}: fresh install counts as chosen")
    stub.level = 21
    for ev, args in (("PLAYER_LEVEL_UP", (21,)), ("SPELLS_CHANGED", ()), ("LEARNED_SPELL_IN_SKILL_LINE", (331, 0)),
                     ("BAG_UPDATE_DELAYED", ()), ("PLAYER_REGEN_ENABLED", ())):
        stub.fire(ev, *args)
    stub.runTimers()
    g.SlashCmdList.FOREVERSENSEI("")
    stub.runTimers()
    if shown_windows(lua) or welcome & set(py(stub.shown) or []):
        problem(f"{label}: before a choice something else was shown: {shown_windows(lua)}")
    if py(stub.actions) or py(stub.macros):
        problem(f"{label}: bars or macros changed before a choice")
    if not picker_shown(lua):
        problem(f"{label}: /sensei before a choice did not bring back the language window")
    # 「English」: applied at once, the modules start (welcome toast in English).
    win = g.ForeverSenseiLanguage
    if win.jaButton.GetText(win.jaButton) != "日本語" or win.enButton.GetText(win.enButton) != "English":
        problem(f"{label}: the buttons must read 日本語 and English")
    win.enButton.Click(win.enButton)
    stub.runTimers()
    if picker_shown(lua) or ns.settings.language != "en" or not ns.settings.languageChosen or not ns.ready:
        problem(f"{label}: choosing English did not apply (language {ns.settings.language}, ready {ns.ready})")
    if ns.Raw("ui.welcome", "en") not in (py(stub.shown) or []):
        problem(f"{label}: no English welcome after the choice")
    if stub.loadCalls != 1:
        problem(f"{label}: LoadAddOn calls {stub.loadCalls}, expected 1")
    for e in unexpected_errors(ns):
        problem(f"{label}: ns.errors: {e}")
    # Next session (an update): no window, still English.
    db = stub.serialize(g.ForeverSenseiDB)
    lua2, ns2 = new_runtime(db=db)
    login(lua2, ns2)
    if picker_shown(lua2) or ns2.settings.language != "en" or not ns2.ready:
        problem(f"{label}: the English choice was not kept after a reload")

    # Fresh install of a class without a pack: the pack note waits for the choice, then shows once.
    lua, ns = new_runtime(cls="WARRIOR")
    login(lua, ns)
    if note_count(lua, ns) != 0:
        problem(f"{label}: the pack note was shown before a choice")
    g = lua.globals()
    g.ForeverSenseiLanguage.jaButton.Click(g.ForeverSenseiLanguage.jaButton)
    lua.globals().STUB.runTimers()
    if ns.settings.language != "ja" or note_count(lua, ns) != 1:
        problem(f"{label}: choosing 日本語 did not show the pack note once")

    # 0.5.0 data (Erika): no window, Japanese kept, marked chosen.
    db050 = '{ settings = { language = "ja", showCards = true }, chars = { ["Erika-Forever"] = { lastLevel = 26 } }, reports = {} }'
    lua, ns = new_runtime(db=db050)
    stub = lua.globals().STUB
    g = lua.globals()
    login(lua, ns)
    if picker_shown(lua) or ns.settings.language != "ja" or ns.settings.languageChosen is not True or not ns.ready:
        problem(f"{label}: 0.5.0 data was asked again or lost its language ({ns.settings.language})")
    # /sensei en and ja still work, and open windows follow without /reload.
    g.SlashCmdList.FOREVERSENSEI("")
    entry = ns.Spells.List()[1]
    ns.NewSkill.ShowCard(entry)
    ns.Talents.ShowHint(True)
    stub.runTimers()
    g.SlashCmdList.FOREVERSENSEI("en")
    stub.runTimers()
    if ns.settings.language != "en" or not ns.settings.languageChosen:
        problem(f"{label}: /sensei en did not switch to English")
    for frame, text_id in (("ForeverSenseiGuide", "ui.guide.title"), ("ForeverSenseiCard", "ui.card.title"),
                           ("ForeverSenseiTalentHint", "ui.talent.title")):
        f = g[frame]
        if f is None or not f.IsShown(f) or f.title.GetText(f.title) != ns.Raw(text_id, "en"):
            problem(f"{label}: {frame} did not switch to English without /reload")
    if any("reload" in str(p) for p in py(stub.prints) or []):
        problem(f"{label}: /sensei en still asks for /reload")
    g.SlashCmdList.FOREVERSENSEI("ja")
    stub.runTimers()
    f = g.ForeverSenseiGuide
    if ns.settings.language != "ja" or f.title.GetText(f.title) != ns.Raw("ui.guide.title", "ja"):
        problem(f"{label}: /sensei ja did not switch back")
    for e in unexpected_errors(ns):
        problem(f"{label}: ns.errors: {e}")


def note_count(lua, ns):
    text = ns.PackNoteText()
    return sum(1 for t in py(lua.globals().STUB.shown) or [] if t == text)


def unexpected_errors(ns):
    return [e for e in py(ns.errors) or []
            if not re.search(r"\d (LoadAddOn ForeverSensei_\w+: MISSING|cannot register )", e)]


def check_idle(lang, cls="WARRIOR", skip=()):
    """A class without an installed pack (a Warrior; a Paladin without ForeverSensei_Paladin). One note per character,
    then idle; /sensei still opens."""
    label = f"runtime idle {cls} [{lang}]"
    folder = "ForeverSensei_" + cls.capitalize()
    lua, ns = new_runtime(cls=cls, skip=skip)
    stub = lua.globals().STUB
    lua.execute("ForeverSenseiDB = { settings = { language = %r } }" % lang)
    login(lua, ns)
    if ns["class"] is not None:
        problem(f"{label}: a class pack is active for a Warrior")
    if ns.Active():
        problem(f"{label}: ns.Active() is true without a pack")
    if not ns.packNote or ns.packNote.id != "ui.pack.missing" or ns.packFolder != folder:
        problem(f"{label}: no 'ui.pack.missing' note for {folder}")
    if stub.loadCalls != 1 or any(py(stub.loaded) or {}):
        problem(f"{label}: LoadAddOn calls {stub.loadCalls}, expected 1 ({folder}, missing), loaded {py(stub.loaded)}")
    if note_count(lua, ns) != 1:
        problem(f"{label}: the note was shown {note_count(lua, ns)} times at the first login, expected 1")
    # Game events that drive cards, hints and the layout do nothing.
    stub.level = 21
    for ev, args in (("PLAYER_LEVEL_UP", (21,)), ("LEARNED_SPELL_IN_SKILL_LINE", (331, 0)),
                     ("SPELLS_CHANGED", ()), ("CHARACTER_POINTS_CHANGED", (1,)), ("PLAYER_REGEN_ENABLED", ()),
                     ("UPDATE_BINDINGS", ()), ("ACTIONBAR_SLOT_CHANGED", (1,)), ("BAG_UPDATE_DELAYED", ())):
        stub.fire(ev, *args)
    stub.runTimers()
    g = lua.globals()
    for frame in ("ForeverSenseiCard", "ForeverSenseiTrainer", "ForeverSenseiTalentHint", "ForeverSenseiPreview"):
        if g[frame] is not None and g[frame].IsShown(g[frame]):
            problem(f"{label}: {frame} shown without a pack")
    # /sensei opens with the translation check and settings; class commands only say there is no pack.
    for cmd in ("", "skills", "layout", "order", "talents", "apply", "clean", "undo", "verify", "card Healing Wave",
                "review", "settings", "report", "help", "nonsense"):
        g.SlashCmdList.FOREVERSENSEI(cmd)
        stub.runTimers()
    g.SlashCmdList.FOREVERSENSEI("settings")
    stub.runTimers()
    tabs = py(ns.Guide.Tabs())
    if tabs != ["review", "settings"]:
        problem(f"{label}: guide tabs {tabs}, expected review and settings")
    if g.ForeverSenseiGuide is None or not g.ForeverSenseiGuide.IsShown(g.ForeverSenseiGuide):
        problem(f"{label}: /sensei did not open the guide")
    for p in py(stub.prints) or []:
        if "error" in str(p):
            problem(f"{label}: {p}")
    if py(stub.actions) or py(stub.macros):
        problem(f"{label}: bars or macros changed without a pack")
    for e in unexpected_errors(ns):
        problem(f"{label}: ns.errors: {e}")
    check_shown(lua, "idle " + lang)
    # Next session: no second note.
    db = lua.globals().STUB.serialize(lua.globals().ForeverSenseiDB)
    lua2, ns2 = new_runtime(cls=cls, db=db, skip=skip)
    login(lua2, ns2)
    if not ns2.packNote or note_count(lua2, ns2) != 0:
        problem(f"{label}: the note came back at the second login")


def check_api_mismatch(lang):
    """A Shaman pack made for another API version: not loaded (its TOC says so), one note."""
    label = f"runtime api [{lang}]"
    lua, ns = new_runtime(meta={"ForeverSensei_Shaman": {"X-ForeverSensei-API": "2"}})
    stub = lua.globals().STUB
    lua.execute("ForeverSenseiDB = { settings = { language = %r } }" % lang)
    login(lua, ns)
    if ns.Active():
        problem(f"{label}: a pack with another API version was activated")
    if (stub.loadCalls or 0) != 0:
        problem(f"{label}: a pack with another API version was loaded")
    if not ns.packNote or ns.packNote.id != "ui.pack.api":
        problem(f"{label}: no 'ui.pack.api' note")
    if note_count(lua, ns) != 1:
        problem(f"{label}: the note was shown {note_count(lua, ns)} times, expected 1")
    # A pack that registers with another API version (TOC field missing) is refused too.
    g = lua.globals()
    if g.ForeverSensei.RegisterClass("PRIEST", lua.table_from({"api": 2})) or ns.packs.PRIEST is not None:
        problem(f"{label}: RegisterClass accepted a pack with API 2")
    for e in unexpected_errors(ns):
        if "refused" not in e:
            problem(f"{label}: ns.errors: {e}")
    check_shown(lua, "api " + lang)


# ---------------------------------------------------------------------------------------------------------------
NAMES = []
TEXT_ID = r'"((?:ui|spell|talent|guide)\.[a-z_0-9]+(?:\.[a-z_0-9]+)*)"'


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
    stub = lua.globals().STUB
    core_en = py(ns.Locales.en)
    core_ja = py(ns.Locales.ja)
    core_sources = py(ns.Sources)
    items = py(ns.ItemData)
    pack_texts = py(ns.PackTexts)
    for kind in items["kinds"].values():
        NAMES.extend([kind["label"], kind["macro"]] + [i["name"] for i in kind["list"]])

    # --- class packs ------------------------------------------------------------------------------------------
    packs = {}
    for folder in pack_folders():
        cls = pack_class(folder)
        before = set(py(ns.packs) or {})
        try:
            ok = stub.loadAddOn(folder)
            ok = ok[0] if isinstance(ok, tuple) else ok
        except Exception as e:  # noqa: BLE001
            problem(f"load {folder}: {e}")
            continue
        added = set(py(ns.packs) or {}) - before
        if not ok or added != {cls}:
            problem(f"{folder}: must register exactly class {cls} with ForeverSensei.RegisterClass, registered {sorted(added)}")
            continue
        pack = py(ns.packs[cls])
        pack["folder"] = folder
        packs[cls] = pack
        PACKS[cls] = {"folder": folder, "spells": pack["spells"],
                      "talents": [t for spec in pack["specs"].values() for t in (spec.get("talents") or {}).get("list", [])]}
        NAMES.extend(s["name"] for s in pack["spells"])
        NAMES.extend(t["name"] for t in PACKS[cls]["talents"])
        if pack.get("defaultSpec") not in pack["specs"]:
            problem(f"{folder}: defaultSpec {pack.get('defaultSpec')} is not one of its specs")
        if pack.get("name") != folder:
            problem(f"{folder}: pack name {pack.get('name')} is not its folder")
        for k in pack["sources"]:
            if k in core_sources:
                problem(f"{folder}: source {k} is also a core source")
    if "SHAMAN" not in packs:
        problem("ForeverSensei_Shaman did not load")
        return

    check_texts(ns, core_en, core_ja, pack_texts, packs)
    check_items(items, core_sources)
    for cls, pack in packs.items():
        sources = dict(core_sources, **pack["sources"])
        check_spells(pack, sources)
        for spec_id, spec in pack["specs"].items():
            if spec.get("layout"):
                check_layout(pack, spec["layout"])
            if spec.get("talents"):
                check_talents(spec["talents"])
            check_guide(spec.get("guide") or [], sources)
        extra = PACK_CHECKS.get(cls)
        if extra:
            extra(pack, sources)
    check_tocs(ns, packs)


# --- texts ----------------------------------------------------------------------------------------------------
def check_texts(ns, core_en, core_ja, pack_texts, packs):
    files = [(CORE, core_en, core_ja)] + [(p["folder"], p["locales"].get("en") or {}, p["locales"].get("ja") or {})
                                          for p in packs.values()]
    for folder, en, ja in files:
        for k in en:
            if k not in ja:
                problem(f"text {k}: no Japanese ({folder}/Locales/ja.lua)")
        for k in ja:
            if k not in en:
                problem(f"text {k}: Japanese without English source ({folder}/Locales/en.lua)")
        for k, v in en.items():
            if k in ja:
                for p in textrules.ja_problems(k, ja[k], v, NAMES):
                    problem(f"ja {k}: {p}")
            if re.search(r"\.\.\.|  ", v):
                problem(f"en {k}: '...' or double space")
    # Each text has one owner; the pack's texts are looked up before the core's, so a copy would hide one.
    for p in packs.values():
        for k in p["locales"].get("en") or {}:
            if k in core_en:
                problem(f"text {k}: in both {CORE} and {p['folder']}")
        for k in pack_texts:
            if k not in (p["locales"].get("en") or {}):
                problem(f"text {k}: {p['folder']} must define it (ns.PackTexts)")
        if py(p.get("localeOrder")) and sorted(p["localeOrder"]) != sorted(p["locales"].get("en") or {}):
            problem(f"{p['folder']}: localeOrder does not match its English texts")
    for k in pack_texts:
        if k in core_en:
            problem(f"text {k}: a class text (ns.PackTexts) must live in the packs, not in {CORE}")
    # The core is class-neutral.
    for k, v in list(core_en.items()) + list(core_ja.items()):
        if re.search(r"Shaman|シャーマン|[Tt]otem|トーテム|Paladin|パラディン", v):
            problem(f"text {k}: class words in a core text (move it to the class pack)")

    # Every character of every text (and the UI symbols) must be in the bundled font.
    have = font_chars(os.path.join(ADDON, "Fonts", "ipagui.ttf"))
    code = "".join(read(p) for p in lua_files(CORE, locales=False))
    alltext = "".join("".join(en.values()) + "".join(ja.values()) for _, en, ja in files)
    used = set(alltext) | {c for c in code if ord(c) > 0x7F}
    missing = sorted(c for c in used if ord(c) >= 0x20 and ord(c) not in have)
    if missing:
        problem("font: no glyph for " + " ".join(f"{c!r} U+{ord(c):04X}" for c in missing))

    # Which texts are used: the core's code and tabs, and each pack's data and code.
    core_needed = set()
    for code_ in py(ns.Feedback.REASONS):
        core_needed.add(f"ui.reason.{code_}")
    guide_src = read(os.path.join(ADDON, "Modules", "Guide.lua"))
    for name in ("TABS", "IDLE_TABS"):
        tabs = re.search(r"local %s = \{([^}]*)\}" % name, guide_src).group(1)
        core_needed |= {f"ui.tab.{t}" for t in re.findall(r'"(\w+)"', tabs)}
    for path in lua_files(CORE, locales=False):
        core_needed |= set(re.findall(TEXT_ID, read(path)))
    for k in sorted(core_needed):
        if k not in core_en and k not in pack_texts:
            problem(f"text {k}: used by the core but not in {CORE}/Locales/en.lua (or ns.PackTexts)")
    all_needed = set(core_needed)
    for p in packs.values():
        en = p["locales"].get("en") or {}
        needed = set(pack_texts)
        for s in p["spells"]:
            needed |= {f"spell.{s['key']}.what", f"spell.{s['key']}.when"}
            needed |= {f"ui.role.{s['role']}", f"ui.use.{s['use']}"}
        for spec in p["specs"].values():
            for t in (spec.get("talents") or {}).get("list", []):
                needed.add(f"talent.{t['key']}.why")
            for tab in spec.get("tabs") or []:
                needed.add(f"ui.tab.{tab}")
                if not any(sec["id"] == tab for sec in spec.get("guide") or []):
                    problem(f"{p['folder']}: tab {tab} has no guide section")
            for sec in spec.get("guide") or []:
                if sec["id"] not in (spec.get("tabs") or []):
                    problem(f"{p['folder']}: guide section {sec['id']} is not in the spec's tabs")
                for i in range(1, len(sec["paragraphs"]) + 1):
                    needed.add(f"guide.{sec['id']}.p{i}")
                if f"guide.{sec['id']}.p{len(sec['paragraphs']) + 1}" in en:
                    problem(f"guide.{sec['id']}: more paragraphs in text than in {p['folder']}'s Guide.lua")
            layout = spec.get("layout")
            if layout:
                for bar in layout["bars"] + (layout.get("retired") or []):
                    needed.add(f"ui.bar.{bar['id']}")
                for kind in set(layout["noSlot"].values()):
                    needed.add(f"ui.where.{kind}")
        for path in lua_files(p["folder"], locales=False):
            needed |= set(re.findall(TEXT_ID, read(path)))
        for k in sorted(needed):
            if k not in en and k not in core_en:
                problem(f"text {k}: used by {p['folder']} but in no Locales/en.lua")
        for k in sorted(en):
            if k not in needed:
                problem(f"text {k}: not used anywhere ({p['folder']}; remove it or use it)")
        all_needed |= needed
    for k in sorted(core_en):
        if k not in all_needed:
            problem(f"text {k}: not used anywhere ({CORE}; remove it or use it)")


# --- spells, layout, talents, guide (every pack) --------------------------------------------------------------
def check_spells(pack, sources):
    spells = pack["spells"]
    # --- spells -----------------------------------------------------------------------------------------------
    keys = [s["key"] for s in spells]
    if len(set(keys)) != len(keys):
        problem("spells: duplicate key")
    for s in spells:
        for f in ("key", "name", "id", "level", "role", "use", "src", "verified"):
            if s.get(f) in (None, ""):
                problem(f"spell {s.get('key')}: missing {f}")
        if s.get("role") not in ("heal", "damage", "support", "tank"):
            problem(f"spell {s['key']}: bad role")
        if s.get("use") not in ("group", "solo", "both"):
            problem(f"spell {s['key']}: bad use")
        if s.get("src") not in sources:
            problem(f"spell {s['key']}: unknown source {s.get('src')}")
        if not re.fullmatch(r"\d{4}-\d\d-\d\d", str(s.get("verified"))):
            problem(f"spell {s['key']}: verified date must be YYYY-MM-DD")
        if not 1 <= int(s.get("level") or 0) <= 60:
            problem(f"spell {s['key']}: level out of range")
        if "races" in s:
            races = s["races"]
            if not isinstance(races, list) or not races or not all(isinstance(r, int) and r > 0 for r in races):
                problem(f"spell {s['key']}: races must be a list of race ids")
            if s.get("talent") or s.get("level") != 1:
                problem(f"spell {s['key']}: a racial is known from level 1 and is no talent")


def check_layout(pack, layout):
    keys = [s["key"] for s in pack["spells"]]
    pack_items = pack["items"]
    # --- layout -----------------------------------------------------------------------------------------------
    slots = layout["slots"]
    seen_slot, seen_key, seen_spell = {}, {}, {}
    allowed = set(layout["allowedKeys"])

    combos = layout.get("combos") or {}

    def what(s):
        if s.get("combo"):
            return "!" + s["combo"]
        return s.get("spell") or "@" + str(s.get("item"))

    for s in slots:
        if sum(bool(s.get(f)) for f in ("spell", "item", "combo")) != 1:
            problem(f"layout: slot {s['slot']} must hold exactly one spell, item or combo")
        if s.get("combo") and s["combo"] not in combos:
            problem(f"layout: slot {s['slot']} combo {s['combo']} is not in L.combos")
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
        if s.get("item") and s["item"] not in pack_items:
            problem(f"layout: item kind {s['item']} is not in the pack's items")
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
    for kind in pack_items:
        if "@" + kind not in seen_spell:
            problem(f"layout: item kind {kind} (pack items) has no slot")
    for k in keys:
        placed = k in seen_spell
        unslotted = k in layout["noSlot"]
        if placed == unslotted:
            problem(f"layout: spell {k} must be in exactly one of the plan or noSlot")
    stand_ins = {s["standIn"] for s in slots if s.get("standIn")}
    for k, m in layout["macros"].items():
        if k not in seen_spell and k not in stand_ins:
            problem(f"layout: macro for unplaced spell {k}")
        if len(m) > 16:
            problem(f"layout: macro name {m} too long")
    for var, k in (layout.get("macroVars") or {}).items():
        if k not in keys or var == "spell":
            problem(f"layout: macroVars {var} = {k} is not a spell")
    for line in layout.get("noSlotLines") or []:
        if line.get("kind") not in set(layout["noSlot"].values()):
            problem(f"layout: noSlotLines kind {line.get('kind')} has no spell")
    for cid, c in combos.items():
        if "!" + cid not in seen_spell:
            problem(f"layout: combo {cid} has no slot")
        if len(c.get("macro") or "") > 16 or not str(c.get("macro")).startswith("FS_"):
            problem(f"layout: combo {cid} bad macro name {c.get('macro')}")
        for var, k in (c.get("vars") or {}).items():
            if k not in keys:
                problem(f"layout: combo {cid} var {var} = {k} is not a spell")
            if "{" + var + "}" not in c.get("body", ""):
                problem(f"layout: combo {cid} var {var} is not used in its body")
        if re.search(r"\{(?!(%s)\})\w+\}" % "|".join(c.get("vars") or {"x": 1}), c.get("body", "")):
            problem(f"layout: combo {cid} body has an unknown placeholder")
        if c.get("needs") and c["needs"] not in keys:
            problem(f"layout: combo {cid} needs unknown spell {c['needs']}")
        if len(c.get("body", "")) > 255:
            problem(f"layout: combo {cid} body longer than 255 characters")
    # Character macros: Forever allows 30 (MAX_CHARACTER_MACROS); leave most of them to the player.
    n_macros = len(layout["macros"]) + len(pack_items) + len(combos)
    if n_macros > 15:
        problem(f"layout: {n_macros} addon macros (keep it at 15 or fewer of the 30 character macros)")
    if not isinstance(layout.get("version"), (int, float)) or layout["version"] < 1:
        problem("layout: version missing (bump it when slots or keys change)")

def check_talents(talents):
    # --- talents (generic) ----------------------------------------------------------------------------------------------
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
    return tree_points


def check_guide(guide, sources):
    # --- guide ------------------------------------------------------------------------------------------------
    for sec in guide:
        for i, p in enumerate(sec["paragraphs"], 1):
            for src in p.get("src") or []:
                if src not in sources:
                    problem(f"guide.{sec['id']}.p{i}: unknown source {src}")
            if not p.get("src"):
                problem(f"guide.{sec['id']}.p{i}: no source")


def check_items(items, sources):
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


def check_client_dump(pack, cls, talents):
    """Spells, talents and Ranks.lua against the Forever client dump research/<cls>_simc_1.60.1.70862.tsv."""
    spells = pack["spells"]
    tsv = os.path.join(ROOT, "research", f"{cls}_simc_1.60.1.70862.tsv")
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
        gen = subprocess.run([sys.executable, os.path.join(ROOT, "tools", "research", "gen_ranks.py"), "--class", cls, "--check"],
                             capture_output=True, text=True)
        if gen.returncode != 0:
            problem(f"ranks [{cls}]: " + (gen.stdout + gen.stderr).strip())
        by_key = {s["key"]: s for s in spells}
        sys.path.insert(0, os.path.join(ROOT, "tools", "research"))
        import gen_ranks
        extra = {k: {(n, i) for n, i, _ in v} for k, v in gen_ranks.CLASSES[cls]["extra"].items()}
        for key, lst in rank_levels(pack["folder"]).items():
            if key not in by_key:
                problem(f"ranks: {key} is not a spell in Spells.lua")
                continue
            if lst[0][0] != int(by_key[key]["id"]):
                problem(f"ranks: {key} rank 1 is {lst[0][0]}, Spells.lua has {by_key[key]['id']}")
            for n, (rid, lv) in enumerate(lst, 1):
                if (n, rid) in extra.get(key, set()):
                    continue  # missing from the dump, verified on its Wowhead Forever tooltip (gen_ranks.py CLASSES)
                r = rows.get(rid)
                if not r or r["name"] != by_key[key]["name"] or r.get("rank") != f"Rank {n}":
                    problem(f"ranks: {key} rank {n} id {rid} does not match the client dump")
            if [lv for _, lv in lst] != sorted(lv for _, lv in lst):
                problem(f"ranks: {key} levels not ascending")
    else:
        problem("research TSV missing: cannot cross-check spells")


# --- Layout v4 (family blocks), shared by the packs ----------------------------------------------------------
# research/keybind-layout-v4.md (approved, commit 27b6754): plain = Action Bar 1, Shift = Action Bar 2, Ctrl = Action
# Bar 3, button n = key n; the six mouse keys and the clicked in-combat spells on Action Bar 6 (moved by the player in
# Edit Mode); out-of-combat clicks on Action Bar 4. Action Bars 5, 7 and 8 are never planned.
ROW_KEYS = ["1", "2", "3", "4", "5", "Q", "E", "R", "F", "Z", "X", "C"]
BLOCKS = {"1-5": ROW_KEYS[0:5], "QERF": ROW_KEYS[5:9], "ZXC": ROW_KEYS[9:12]}
MOUSE_KEYS = {"BUTTON4", "BUTTON5", "SHIFT-BUTTON4", "SHIFT-BUTTON5", "CTRL-BUTTON4", "CTRL-BUTTON5"}


def slot_what(s):
    return s.get("spell") or ("!" + s["combo"] if s.get("combo") else "@" + str(s.get("item")))


def check_blocks(layout, label, grid, clicks, mouse_order, ooc, bar6_more=(), raced=()):
    """The exact grid (key → entry), the clicked buttons ((bar, button) → entry), the bars and the block rule.
    bar6_more = Action Bar 6's keys after the six mouse pairs (buttons 7-12, the shaman's BUTTON3); raced = race-gated
    entries (spare for other races, so an L.old leftover may sit on their button)."""
    slots = layout["slots"]
    bar6_more = list(bar6_more) + [None] * (6 - len(bar6_more))
    bars = {b["id"]: b for b in layout["bars"]}
    want_bars = [
        ("main", 1, "ACTIONBUTTON%d", None, ROW_KEYS),
        ("bar2", 61, "MULTIACTIONBAR1BUTTON%d", "PROXY_SHOW_ACTIONBAR_2", ["SHIFT-" + k for k in ROW_KEYS]),
        ("bar3", 49, "MULTIACTIONBAR2BUTTON%d", "PROXY_SHOW_ACTIONBAR_3", ["CTRL-" + k for k in ROW_KEYS]),
        ("bar6", 145, "MULTIACTIONBAR5BUTTON%d", "PROXY_SHOW_ACTIONBAR_6", mouse_order + bar6_more),
        ("bar4", 25, "MULTIACTIONBAR3BUTTON%d", "PROXY_SHOW_ACTIONBAR_4", [None] * 12),
    ]
    if [b["id"] for b in layout["bars"]] != [w[0] for w in want_bars]:
        problem(f"{label}: bars must be main, bar2, bar3, bar6, bar4, are {[b['id'] for b in layout['bars']]}")
        return
    for bid, first, binding, setting, keys in want_bars:
        b = bars[bid]
        got = [k or None for k in (b.get("keys") or [])] or [None] * 12
        got += [None] * (12 - len(got))
        if (b["first"], b["binding"], b.get("setting"), got) != (first, binding, setting, keys):
            problem(f"{label}: {bid} must be first {first}, {binding}, {setting}, keys {keys}")
    if not bars["bar6"].get("editMode") or any(b.get("editMode") for b in layout["bars"] if b["id"] != "bar6"):
        problem(f"{label}: only bar6 is an Edit Mode bar (it starts in the middle of the screen)")
    if set(mouse_order) != MOUSE_KEYS:
        problem(f"{label}: bar6 buttons 1-6 must be the six mouse keys")
    for s in slots:
        b = bars[s["bar"]]
        want = ((b.get("keys") or [None] * 12) + [None] * 12)[s["button"] - 1] or None
        if (s.get("key") or None) != want:
            problem(f"{label}: slot {s['slot']} key {s.get('key')} is not its bar's key {want}")
    # Exact grid and clicked buttons.
    by_key = {s["key"]: slot_what(s) for s in slots if s.get("key")}
    for k in sorted(set(grid) | set(by_key)):
        if by_key.get(k) != grid.get(k):
            problem(f"{label}: key {k} must be {grid.get(k)}, has {by_key.get(k)}")
    by_click = {(s["bar"], s["button"]): slot_what(s) for s in slots if not s.get("key")}
    for k in sorted(set(clicks) | set(by_click)):
        if by_click.get(k) != clicks.get(k):
            problem(f"{label}: clicked {k[0]} button {k[1]} must be {clicks.get(k)}, has {by_click.get(k)}")
    for (bid, _), entry in clicks.items():
        if bid not in ("bar6", "bar4"):
            problem(f"{label}: clicked {entry} must be on Action Bar 6 (in combat) or 4 (out of combat)")
        if bid == "bar4" and entry not in ooc:
            problem(f"{label}: {entry} on Action Bar 4 is not an out-of-combat spell")
    # Spare: every keyed button without an entry is bound and empty; allowedKeys = grid + spare keys.
    spare_keys = {x["key"] for x in layout["spare"] if x.get("key")}
    for x in layout["spare"]:
        b = bars[x["bar"]]
        want = ((b.get("keys") or [None] * 12) + [None] * 12)[x["button"] - 1] or None
        if x.get("key") != want or (want and x.get("binding") != b["binding"] % x["button"]):
            problem(f"{label}: spare slot {x['slot']} key {x.get('key')} is not its bar's key {want}")
    allowed = set(layout["allowedKeys"])
    if allowed != set(grid) | spare_keys:
        problem(f"{label}: allowedKeys must be the grid's and spare keys (diff {sorted(allowed ^ (set(grid) | spare_keys))})")
    all_keys = {m + k for m in ("", "SHIFT-", "CTRL-") for k in ROW_KEYS} | MOUSE_KEYS | {k for k in bar6_more if k}
    if allowed != all_keys:
        problem(f"{label}: every allowed key must be bound (no own keys since layout v4): missing {sorted(all_keys - allowed)}")
    for k in ("ownKeys", "own", "oldOwn", "keepDefault", "keyNotes"):
        if layout.get(k):
            problem(f"{label}: {k} is gone since layout v4")
    # The block rule: each family fills one block of one row in member order (or one mouse pair/column); spill-overs
    # are clicked on Action Bar 6.
    where = {slot_what(s): s for s in slots}
    for f in layout.get("families") or []:
        block, row, members = f.get("block"), f.get("row") or "", f.get("members") or []
        if block in BLOCKS:
            want = [row + k for k in BLOCKS[block][:len(members)]]
            if len(members) > len(BLOCKS[block]):
                problem(f"{label}: family {f['id']} is bigger than its block")
        elif block == "mouse":
            # The mouse pairs in Action Bar 6 order, from the family's row on: Mouse4, Mouse5, Shift+Mouse4, ...
            pairs = [m + b for m in ("", "SHIFT-", "CTRL-") for b in ("BUTTON4", "BUTTON5")]
            start = pairs.index(row + "BUTTON4") if row + "BUTTON4" in pairs else 0
            want = pairs[start:start + len(members)]
            if len(members) > len(pairs) - start:
                problem(f"{label}: family {f['id']} is bigger than its mouse pairs")
        elif block in ("BUTTON4", "BUTTON5", "BUTTON3"):
            want = [m + block for m in ("", "SHIFT-", "CTRL-")][:len(members)]
        else:
            problem(f"{label}: family {f.get('id')} has an unknown block {block}")
            continue
        got = [(where.get(m) or {}).get("key") for m in members]
        if got != want:
            problem(f"{label}: family {f['id']} must sit on {want}, is on {got}")
        for m in f.get("spill") or []:
            s = where.get(m) or {}
            if s.get("bar") != "bar6" or s.get("key"):
                problem(f"{label}: {f['id']} spill-over {m} must be clicked on Action Bar 6")
    # Retired bars and leftovers: L.old slots are off the plan (spare or on a retired bar).
    planned = {s["slot"] for s in slots if slot_what(s) not in raced}
    ranges = [(b["first"], b["first"] + 11) for b in layout["bars"] + (layout.get("retired") or [])]
    for slot_, key in (layout.get("old") or {}).items():
        slot_ = int(slot_)
        if slot_ in planned or not any(a <= slot_ <= z for a, z in ranges):
            problem(f"{label}: old slot {slot_} ({key}) must be off the plan (or on a race-gated button), on a planned or retired bar")
    for r in layout.get("retired") or []:
        if r["first"] in (1, 61, 49, 145, 25):
            problem(f"{label}: retired bar {r['id']} is a planned bar")
    return by_key


# --- Shaman ---------------------------------------------------------------------------------------------------
def check_shaman(pack, sources):
    spells = pack["spells"]
    keys = [s["key"] for s in spells]
    pack_items = pack["items"]
    spec = pack["specs"]["RESTORATION"]
    layout = spec["layout"]
    talents = spec["talents"]
    if pack.get("defaultSpec") != "RESTORATION" or set(pack["specs"]) != {"RESTORATION"}:
        problem("shaman: the pack must have the Restoration spec, the default")
    check_client_dump(pack, "shaman", talents)

    # --- layout: the approved grid (research/keybind-layout-v4.md S3, layout 7) ----------------------------------
    slots = layout["slots"]
    grid = {
        "1": "flame_shock", "2": "lightning_bolt", "3": "chain_lightning", "4": "purge", "5": "frost_shock",
        "Q": "earth_shock", "E": "lesser_healing_wave", "R": "chain_heal", "F": "healing_wave",
        "Z": "@mana", "X": "water_shield", "C": "@health",
        "SHIFT-1": "totemic_call", "SHIFT-2": "call_of_the_elements", "SHIFT-3": "call_of_the_ancestors",
        "SHIFT-4": "call_of_the_spirits", "SHIFT-5": "totemic_recall",
        "SHIFT-Q": "flametongue_totem", "SHIFT-E": "magma_totem", "SHIFT-R": "searing_totem", "SHIFT-F": "fire_nova",
        "SHIFT-Z": "mana_spring_totem", "SHIFT-X": "mana_tide_totem", "SHIFT-C": "healing_stream_totem",
        "CTRL-1": "ghost_wolf", "CTRL-2": "water_walking", "CTRL-3": "water_breathing",
        "CTRL-Q": "earthbind_totem", "CTRL-E": "stoneclaw_totem", "CTRL-R": "stoneskin_totem", "CTRL-F": "tremor_totem",
        "CTRL-Z": "grounding_totem", "CTRL-X": "windfury_totem", "CTRL-C": "grace_of_air_totem",
        "BUTTON4": "riptide", "BUTTON5": "natures_swiftness",
        "SHIFT-BUTTON4": "cure_poison", "SHIFT-BUTTON5": "cure_disease",
        "CTRL-BUTTON4": "poison_cleansing_totem", "CTRL-BUTTON5": "disease_cleansing_totem",
        "BUTTON3": "walk_on_air",
    }
    clicks = {
        ("bar6", 7): "strength_of_earth_totem", ("bar6", 8): "@healpot", ("bar6", 10): "skysight",
        ("bar4", 1): "ancestral_spirit", ("bar4", 2): "astral_recall", ("bar4", 3): "rockbiter_weapon",
        ("bar4", 4): "flametongue_weapon", ("bar4", 5): "frostbrand_weapon", ("bar4", 6): "windfury_weapon",
        ("bar4", 7): "lightning_shield", ("bar4", 8): "@elixir",
    }
    ooc = {"ancestral_spirit", "astral_recall", "rockbiter_weapon", "flametongue_weapon", "frostbrand_weapon",
           "windfury_weapon", "lightning_shield", "@elixir"}
    mouse = ["BUTTON4", "BUTTON5", "SHIFT-BUTTON4", "SHIFT-BUTTON5", "CTRL-BUTTON4", "CTRL-BUTTON5"]
    raced = {s["key"] for s in spells if s.get("races")}
    check_blocks(layout, "layout", grid, clicks, mouse, ooc, bar6_more=[None, None, "BUTTON3"], raced=raced)
    if [f["id"] for f in layout.get("families") or []] != [
            "damage", "calls", "fire", "water", "travel", "earth", "air", "cursorheals", "cures", "cleansing", "racial"]:
        problem("layout: families must be damage, calls, fire, water, travel, earth, air, the three mouse pairs and "
                "the racials (Walk on Air on the middle mouse button, Skysight clicked)")
    # Layout 8 (0.8.1, Erika's request): the Skyborne racials, gated on race (simc-forever nonclass.txt race masks).
    racials = {s["key"]: (s.get("id"), s.get("races"), s.get("src")) for s in spells if s.get("races")}
    if racials != {"walk_on_air": (1259416, [33, 34], "simc_race"), "skysight": (1259686, [34], "simc_race")}:
        problem(f"shaman: racials must be Walk on Air 1259416 (races 33, 34) and Skysight 1259686 (race 34), are {racials}")
    if sorted(pack_items) != ["elixir", "healpot", "health", "mana"]:
        problem(f"shaman: items must be mana, health, healpot and elixir, are {sorted(pack_items)}")
    if layout.get("noSlotLines") != [{"kind": "totembar", "text": "ui.layout.nobar"},
                                     {"kind": "spellbook", "text": "ui.layout.nobook"}]:
        problem("layout: noSlotLines must list the Totem Bar and the spellbook")
    if spec.get("tabs") != ["role", "healing", "damage", "totems", "manners"]:
        problem(f"shaman: Restoration tabs must be role, healing, damage, totems, manners, are {spec.get('tabs')}")
    spare_keys = {x["key"] for x in layout["spare"] if x.get("key")}
    if spare_keys != {"CTRL-4", "CTRL-5"}:
        problem(f"layout: spare keys must be Ctrl+4 and Ctrl+5, are {sorted(spare_keys)}")
    # Lightning Shield stands in on X until Water Shield is learned, then moves to its own clickable button.
    x = next((s for s in slots if s.get("key") == "X"), {})
    ls = next((s for s in slots if s.get("spell") == "lightning_shield"), {})
    if x.get("standIn") != "lightning_shield" or ls.get("after") != "water_shield" or ls.get("key"):
        problem("layout: X must be Water Shield with Lightning Shield standing in until it is learned")
    # Retired: Action Bar 5 (layouts 4-6) stays as the player has it; Action Bar 7 (layout 3) stays hidden.
    retired = [(r.get("id"), r.get("first"), r.get("binding"), r.get("setting"), bool(r.get("keepShown")),
                r.get("assigned")) for r in layout.get("retired") or []]
    if retired != [("bar5", 37, "MULTIACTIONBAR4BUTTON%d", "PROXY_SHOW_ACTIONBAR_5", True, [1, 6, 7, 8, 9, 10, 12]),
                   ("bar7", 157, "MULTIACTIONBAR6BUTTON%d", "PROXY_SHOW_ACTIONBAR_7", False, [1, 2, 3, 4, 5, 6])]:
        problem("layout: retired must be Action Bar 5 (keepShown, layout 6's buttons) and Action Bar 7 (layout 3's)")
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
        if base == "nshw" and ("{heal}" not in body or layout.get("macroVars") != {"heal": "healing_wave"}):
            problem(f"layout: macro body {kind} must cast {{heal}} (macroVars heal = healing_wave)")
        if base == "interrupt" and "/stopcasting" not in body:
            problem(f"layout: macro body {kind} must /stopcasting")
        if kind in ("help", "nshw") and "@mouseover,help" not in body:
            problem(f"layout: macro body {kind} must use the friendly mouseover")
        if kind in ("harm", "interrupt") and "@mouseover,harm" not in body:
            problem(f"layout: macro body {kind} must use the enemy mouseover")
    kinds_used = {layout["macroKind"].get(k, "help") for k in layout["macros"]}
    if {"interrupt", "harm", "nshw", "help"} - kinds_used:
        problem("layout: earth_shock interrupt, purge harm and the NS + Healing Wave macro are required")
    # Layout 8 (0.8.1) is the plan: characters with layout 7 or older get the one-time "apply all" notice. A full
    # apply clears layout 6's Action Bar 5 spells, layout 4's Mana Tide on Ctrl+5, layout 3's bar 6 spares (buttons 9
    # and 10 only while they are spare: another race's racial) and layout 5's bar 4 Fire spells while they still hold
    # exactly that spell.
    if layout.get("version") != 8:
        problem(f"layout: version must be 8 (Skyborne racials, 0.8.1), is {layout.get('version')}")
    old = {int(k): v for k, v in (layout.get("old") or {}).items()}
    for slot_, key in ((37, "totemic_recall"), (41, "mana_tide_totem"), (44, "fire_nova"), (48, "ghost_wolf"),
                       (153, "grounding_totem"), (154, "mana_tide_totem"), (156, "ghost_wolf")):
        if old.get(slot_) != key:
            problem(f"layout: old must list {key} on slot {slot_}")
    for v in old.values():
        for k in (v if isinstance(v, list) else [v]):
            if k not in keys and not k.startswith("@"):
                problem(f"layout: old entry {k} is not a spell")
    want_warn = {"CTRL-%d" % i: "ui.preview.warn.stance" for i in range(1, 6)}
    want_warn["CTRL-R"] = "ui.preview.warn.fps"
    want_warn["BUTTON3"] = "ui.preview.warn.middle"
    if layout.get("defaultWarn") != want_warn:
        problem("layout: defaultWarn must be Ctrl+1-5 (stance bar), Ctrl+R (framerate) and the middle mouse button")

    # --- talents ----------------------------------------------------------------------------------------------
    tree_points = check_talents_points(talents)
    if tree_points.get("Restoration") != 46 or tree_points.get("Enhancement") != 5:
        problem(f"talents: final build should be 0/5/46 (Mobalytics), is {tree_points}")


def check_talents_points(talents):
    by = {t["key"]: t for t in talents["list"]}
    spent = {}
    for o in talents["order"]:
        spent[o["key"]] = spent.get(o["key"], 0) + 1
    tree_points = {}
    for k, n in spent.items():
        if k in by:
            tree_points[by[k]["tree"]] = tree_points.get(by[k]["tree"], 0) + n
    return tree_points


# --- Paladin --------------------------------------------------------------------------------------------------
# Spells the paladin research left unverified for Forever: kept out of every text, key and data file.
PALADIN_EXCLUDED = ("Blessing of Salvation", "Blessing of Sanctuary", "Blessing of Light", "Hammer of the Righteous")


def check_paladin(pack, sources):
    spec = (pack["specs"] or {}).get("PROTECTION") or {}
    layout = spec.get("layout") or {}
    talents = spec.get("talents") or {}
    if pack.get("defaultSpec") != "PROTECTION" or set(pack["specs"]) != {"PROTECTION"}:
        problem("paladin: the pack must have the Protection spec, the default")
        return
    check_client_dump(pack, "paladin", talents)
    if sorted(pack["items"]) != ["health", "mana"]:
        problem(f"paladin: items must be health and mana, are {sorted(pack['items'])}")
    if spec.get("tabs") != ["role", "rotation", "seals", "auras", "cooldowns", "manners"]:
        problem(f"paladin: Protection tabs must be role, rotation, seals, auras, cooldowns, manners, are {spec.get('tabs')}")

    # --- layout: the approved grid (research/keybind-layout-v4.md P4, layout 4: Justice on Shift+4 since 0.7.1, the save
    # block on Ctrl+Q/E/R and the mouse keys in pairs since 0.8.0) ------------------------------------------------
    slots = layout["slots"]
    grid = {
        "1": "holy_strike", "2": "consecration", "3": "holy_shield", "4": "flash_of_light", "5": "holy_light",
        "Q": "judgement", "E": "swift_judgement", "R": "!opener", "F": "hammer_of_justice",
        "Z": "@health", "X": "@mana", "C": "righteous_fury",
        "SHIFT-1": "seal_of_fury", "SHIFT-2": "seal_of_righteousness", "SHIFT-3": "seal_of_the_crusader",
        "SHIFT-4": "seal_of_justice", "SHIFT-5": "seal_of_wisdom",
        "SHIFT-Q": "exorcism", "SHIFT-E": "hammer_of_wrath", "SHIFT-R": "holy_wrath", "SHIFT-F": "turn_undead",
        "SHIFT-Z": "templars_bulwark", "SHIFT-X": "divine_shield", "SHIFT-C": "divine_protection",
        "CTRL-1": "retribution_aura", "CTRL-2": "devotion_aura", "CTRL-3": "concentration_aura",
        "CTRL-4": "shadow_resistance_aura", "CTRL-5": "frost_resistance_aura",
        "CTRL-Q": "lay_on_hands", "CTRL-E": "blessing_of_protection", "CTRL-R": "blessing_of_sacrifice",
        "CTRL-Z": "blessing_of_kings", "CTRL-X": "blessing_of_might", "CTRL-C": "blessing_of_wisdom",
        "BUTTON4": "cleanse", "BUTTON5": "blessing_of_freedom", "SHIFT-BUTTON4": "voice_of_truth",
    }
    clicks = {
        ("bar6", 7): "seal_of_light", ("bar6", 8): "fire_resistance_aura", ("bar6", 9): "divine_intervention",
        ("bar4", 1): "redemption", ("bar4", 2): "greater_blessing_of_kings", ("bar4", 3): "greater_blessing_of_might",
        ("bar4", 4): "greater_blessing_of_wisdom",
    }
    ooc = {"redemption", "greater_blessing_of_kings", "greater_blessing_of_might", "greater_blessing_of_wisdom"}
    mouse = ["BUTTON4", "BUTTON5", "SHIFT-BUTTON4", "SHIFT-BUTTON5", "CTRL-BUTTON4", "CTRL-BUTTON5"]
    check_blocks(layout, "paladin layout", grid, clicks, mouse, ooc)
    if [f["id"] for f in layout.get("families") or []] != [
            "judgement", "seals", "conditional", "forbearance", "auras", "save", "blessings", "free"]:
        problem("paladin layout: families must be judgement, seals, conditional, forbearance, auras, save, blessings, free")
    # 0.8.0 (Oskar): long cooldowns that are dangerous when misclicked stay off the mouse buttons.
    for k, v in grid.items():
        if "BUTTON" in k and v in ("lay_on_hands", "blessing_of_protection", "blessing_of_sacrifice", "divine_intervention"):
            problem(f"paladin layout: {v} must not be on a mouse button ({k})")
    seals = next((f for f in layout.get("families") or [] if f.get("id") == "seals"), {})
    if seals.get("members") != ["seal_of_fury", "seal_of_righteousness", "seal_of_the_crusader", "seal_of_justice",
                                "seal_of_wisdom"] or seals.get("spill") != ["seal_of_light"]:
        problem("paladin layout: seals must be Fury, Righteousness, Crusader, Justice, Wisdom on Shift+1-5, Light spilled")
    spare_keys = {x["key"] for x in layout["spare"] if x.get("key")}
    if spare_keys != {"CTRL-F", "SHIFT-BUTTON5", "CTRL-BUTTON4", "CTRL-BUTTON5"}:
        problem(f"paladin layout: spare keys must be Ctrl+F, Shift+Mouse5, Ctrl+Mouse4 and Ctrl+Mouse5, are {sorted(spare_keys)}")
    # Action Bar 5 (layout 1's Ctrl bar) stays as the player has it; L.old clears layout 1's spells there and on
    # Action Bar 3 buttons that are spare now, while they still hold exactly that spell.
    retired = [(r.get("id"), r.get("first"), r.get("binding"), r.get("setting"), bool(r.get("keepShown")),
                r.get("assigned")) for r in layout.get("retired") or []]
    if retired != [("bar5", 37, "MULTIACTIONBAR4BUTTON%d", "PROXY_SHOW_ACTIONBAR_5", True, [6, 8, 9, 11, 12])]:
        problem("paladin layout: retired must be Action Bar 5 only (keepShown, layout 1's buttons 6, 8, 9, 11, 12)")
    old = {int(k): v for k, v in (layout.get("old") or {}).items()}
    if old != {42: "!opener", 44: "turn_undead", 45: "seal_of_the_crusader", 47: "redemption",
               48: "divine_protection", 57: "lay_on_hands",
               148: ["cleanse", "purify"], 149: "blessing_of_freedom", 150: "voice_of_truth"}:
        problem(f"paladin layout: old must be layout 1's Action Bar 5 spells and Action Bar 3 button 9, and layout 3's "
                f"Action Bar 6 buttons 4-6, is {old}")
    # Auras are normal spells on Action Bar 3 since layout 2; Purify stands in on Cleanse's button until 42.
    if any(v == "stancebar" for v in layout["noSlot"].values()):
        problem("paladin layout: no spell is left on the stance bar (layout 2 places the auras)")
    if layout["noSlot"] != {"purify": "spellbook", "summon_warhorse": "spellbook", "summon_charger": "spellbook"}:
        problem("paladin layout: noSlot must be Purify and the two mounts (spellbook)")
    m4 = next((s for s in slots if s.get("key") == "BUTTON4"), {})
    if m4.get("standIn") != "purify":
        problem("paladin layout: Mouse4 must be Cleanse with Purify standing in until 42")
    # Macros: help with the self fallback (Blessing of Protection too, since 0.7.1), help_nofb (Sacrifice) without,
    # Hammer of Justice
    # stops the cast, the opener fires Judgement, Swift Judgement and Holy Strike once Swift Judgement is known.
    want = {"flash_of_light", "holy_light", "lay_on_hands", "cleanse", "purify", "blessing_of_freedom",
            "blessing_of_protection", "blessing_of_sacrifice", "hammer_of_justice"}
    if set(layout["macros"]) != want:
        problem(f"paladin layout: macros must be {sorted(want)}, are {sorted(layout['macros'])}")
    bodies = layout["macroBodies"]
    if "[@player]" not in bodies.get("help", "") or "@player" in bodies.get("help_nofb", "@player") \
            or "@mouseover,help" not in bodies.get("help_nofb", ""):
        problem("paladin layout: help must fall back to yourself, help_nofb must not")
    if {k: v for k, v in layout["macroKind"].items()} != {
            "blessing_of_sacrifice": "help_nofb", "hammer_of_justice": "interrupt"}:
        problem("paladin layout: macroKind must be help_nofb for Sacrifice only, interrupt for Hammer of Justice")
    if "/stopcasting" not in bodies.get("interrupt", "") or "@mouseover,harm" not in bodies.get("interrupt", ""):
        problem("paladin layout: the Hammer of Justice macro must /stopcasting and use the enemy mouseover")
    op = (layout.get("combos") or {}).get("opener") or {}
    lines = (op.get("body") or "").split("\n")
    if op.get("macro") != "FS_OPEN" or op.get("needs") != "swift_judgement" or \
            lines != ["#showtooltip {swift}", "/startattack", "/cast {judge}", "/cast {swift}", "/cast {strike}"] or \
            op.get("vars") != {"swift": "swift_judgement", "judge": "judgement", "strike": "holy_strike"}:
        problem("paladin layout: the opener must be FS_OPEN: Judgement, Swift Judgement, Holy Strike, needs Swift Judgement")
    names = set(layout["macros"].values()) | {"FS_OPEN", "FS_HEALTH", "FS_MANA"}
    if len(names) > 15:
        problem(f"paladin layout: {len(names)} macros, over the budget of 15")
    want_warn = {"CTRL-%d" % i: "ui.preview.warn.stance" for i in range(1, 6)}
    want_warn["CTRL-R"] = "ui.preview.warn.fps"
    if layout.get("defaultWarn") != want_warn:
        problem("paladin layout: defaultWarn must be Ctrl+1-5 (stance bar) and Ctrl+R (framerate)")
    if layout.get("version") != 4:
        problem(f"paladin layout: version must be 4 (the save block on Ctrl+Q/E/R, 0.8.0), is {layout.get('version')}")

    # --- talents: Wowhead 0/32/19, one point per level 10-60 ---------------------------------------------------
    tree_points = check_talents_points(talents)
    if tree_points != {"Protection": 32, "Retribution": 19}:
        problem(f"paladin talents: final build should be 0/32/19 (Wowhead), is {tree_points}")
    levels = [lv for _, a, b in talents["path"] for lv in range(a, b + 1)]
    if levels != list(range(10, 61)):
        problem("paladin talents: the path must give one point per level from 10 to 60")

    # --- unverified spells stay out --------------------------------------------------------------------------
    folder = os.path.join(ROOT, pack["folder"])
    for dirpath, _, files in os.walk(folder):
        for fn in files:
            if fn.endswith((".lua", ".toc")):
                text = read(os.path.join(dirpath, fn))
                for name in PALADIN_EXCLUDED:
                    if name in text:
                        problem(f"paladin: unverified {name} appears in {os.path.relpath(os.path.join(dirpath, fn), ROOT)}")


PACK_CHECKS = {"SHAMAN": check_shaman, "PALADIN": check_paladin}


# --- TOCs -----------------------------------------------------------------------------------------------------
def check_tocs(ns, packs):
    meta, files = toc(CORE)
    for rel in files:
        if not os.path.exists(os.path.join(ADDON, rel)):
            problem(f"toc: missing file {CORE}/{rel}")
    if meta.get("Interface") != "16001":
        problem("toc: Interface must be 16001 (WoW: Forever 1.60.1)")
    if meta.get("SavedVariables") != "ForeverSenseiDB":
        problem("toc: SavedVariables ForeverSenseiDB missing")
    if meta.get("Version") != ns.VERSION:
        problem(f"toc: Version {meta.get('Version')} but Core/Init.lua has {ns.VERSION}")
    if meta.get("LoadOnDemand"):
        problem(f"toc: {CORE} must not be LoadOnDemand")
    for cls, p in packs.items():
        folder = p["folder"]
        m, files = toc(folder)
        for rel in files:
            if not os.path.exists(os.path.join(ROOT, folder, rel)):
                problem(f"toc: missing file {folder}/{rel}")
        if files[-1:] != ["Register.lua"]:
            problem(f"toc: {folder} must load Register.lua last")
        want = {"Interface": "16001", "Dependencies": CORE, "LoadOnDemand": "1",
                "X-ForeverSensei-API": str(ns.API_VERSION), "Version": meta.get("Version")}
        for field, v in want.items():
            if m.get(field) != v:
                problem(f"toc: {folder} {field} must be {v}, is {m.get(field)}")
        if "SavedVariables" in m or "SavedVariablesPerCharacter" in m:
            problem(f"toc: {folder} must not have its own saved variables (the core keeps ForeverSenseiDB)")
        if "Shaman" in (meta.get("Notes") or "") or "シャーマン" in (meta.get("Notes-jaJP") or ""):
            problem(f"toc: {CORE} Notes must be class-neutral")
        if p.get("api") != ns.API_VERSION:
            problem(f"{folder}: Register.lua api {p.get('api')} is not {ns.API_VERSION}")


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
            {"id": "spell.chain_heal.when", "reason": "不自然", "suggestion": "2人以上が傷ついている時に使おう。", "note": None,
             "pack": "ForeverSensei_Shaman"},
            {"id": "guide.healing.p3", "reason": "わかりにくい", "suggestion": None, "note": "line one\nline two | x",
             "pack": "ForeverSensei_Shaman"},
        ]
        got = [{k: r.get(k) for k in ("id", "reason", "suggestion", "note", "pack")} for r in parsed["reports"]]
        if got != want:
            problem(f"reports: round-trip mismatch\n{text}\n→ {got}")
        if not parsed.get("version"):
            problem("reports: version not parsed")
    en, ja, owners = reports.read_locales()
    if any(set(en[p]) != set(ja[p]) for p in en) or {i for p in ja for i in ja[p]} != set(owners):
        problem("reports.py: read_locales does not see the same ids in en and ja")
    # Packs share ids (guide.role.p1): a report names its pack; an old one without a pack must not guess.
    old = reports.parse("[ForeverSensei v0.5.1 報告 1件]\n#1 spell.chain_heal.when | 不自然\n今: x")["reports"][0]
    if old.get("pack") is not None or old["reason"] != "不自然":
        problem(f"reports.py: an old report line without a pack parses as {old}")
    for rid, pack, folder in (("spell.chain_heal.when", None, "ForeverSensei_Shaman"),
                              ("spell.chain_heal.when", "ForeverSensei_Shaman", "ForeverSensei_Shaman"),
                              ("guide.healing.p3", "ForeverSensei_Shaman", "ForeverSensei_Shaman"),
                              ("ui.pack.missing", None, CORE), ("ui.pack.missing", "ForeverSensei_Paladin", CORE),
                              ("spell.consecration.when", None, "ForeverSensei_Paladin"),
                              ("guide.seals.p1", "ForeverSensei_Paladin", "ForeverSensei_Paladin"),
                              ("ui.role.tank", "ForeverSensei_Paladin", "ForeverSensei_Paladin"),
                              ("ui.layout.intro", "ForeverSensei_Paladin", "ForeverSensei_Paladin"),
                              ("guide.role.p1", "ForeverSensei_Shaman", "ForeverSensei_Shaman"),
                              ("ui.layout.intro", None, None), ("spell.consecration.when", "ForeverSensei_Shaman", None)):
        path, why = reports.owner_of({"id": rid, "pack": pack}, owners)
        want = os.path.join(ROOT, folder, "Locales", "ja.lua") if folder else None
        if path != want:
            problem(f"reports.py: {rid} ({pack}) would be written to {path} ({why}), not {want}")
    if "Healing Wave" not in reports.names() or "Holy Strike" not in reports.names():
        problem("reports.py: names() misses a pack's spell names")
    check_zip(reports)


def check_zip(reports):
    """make zip: every addon folder at the top level of the zip (unzip straight into AddOns), each with its TOC."""
    import tempfile
    import zipfile
    want = {"ForeverSensei", "ForeverSensei_Paladin", "ForeverSensei_Shaman"}
    with tempfile.TemporaryDirectory() as tmp:
        with zipfile.ZipFile(reports.build_zip(tmp)) as z:
            names = z.namelist()
    tops = {n.split("/")[0] for n in names}
    if tops != want:
        problem(f"zip: top-level folders are {sorted(tops)}, not {sorted(want)}")
    for t in sorted(want):
        if f"{t}/{t}.toc" not in names:
            problem(f"zip: {t}/{t}.toc missing")


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
