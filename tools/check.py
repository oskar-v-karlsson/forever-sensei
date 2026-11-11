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
        for e in data["spells"]:
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
    check_language()
    return reports


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

    # --- layout -----------------------------------------------------------------------------------------------
    slots = layout["slots"]
    seen_slot = {s["slot"]: s for s in slots}
    allowed = set(layout["allowedKeys"])

    def what(s):
        return s.get("spell") or "@" + str(s.get("item"))

    for s in slots:
        if s.get("item") and s.get("key") not in (None, "Z", "C"):
            problem(f"layout: item @{s['item']} on key {s.get('key')} (only FS_MANA on Z and FS_HEALTH on C have keys)")
    if sorted(pack_items) != ["elixir", "healpot", "health", "mana"]:
        problem(f"shaman: items must be mana, health, healpot and elixir, are {sorted(pack_items)}")
    if layout.get("noSlotLines") != [{"kind": "totembar", "text": "ui.layout.nobar"},
                                     {"kind": "spellbook", "text": "ui.layout.nobook"}]:
        problem("layout: noSlotLines must list the Totem Bar and the spellbook")
    if spec.get("tabs") != ["role", "healing", "damage", "totems", "manners"]:
        problem(f"shaman: Restoration tabs must be role, healing, damage, totems, manners, are {spec.get('tabs')}")
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
    # Earlier layouts' leftovers are cleared only from buttons that are spare now.
    for slot_, key in (layout.get("old") or {}).items():
        if int(slot_) not in spare_slots or key not in keys:
            problem(f"layout: old slot {slot_} ({key}) must be spare now and a spell")
    # Own buttons an earlier layout filled: only Ctrl+5's button (Mana Tide Totem in layout 4).
    old_own = {int(k): v for k, v in (layout.get("oldOwn") or {}).items()}
    if old_own != {bars["bar5"]["first"] + 4: "mana_tide_totem"}:
        problem("layout: oldOwn must be exactly Ctrl+5's button with layout 4's Mana Tide Totem")
    for slot_ in old_own:
        if str(slot_) not in {str(x) for x in (layout.get("own") or {})}:
            problem(f"layout: oldOwn slot {slot_} is not an own button")
    # Layout 5 (0.4.3) is still the plan: 0.5.0 moved the data into the pack without changing slots or keys, so
    # characters get no new "apply all" notice.
    if layout.get("version") != 5:
        problem(f"layout: version must stay 5 while slots and keys are unchanged, is {layout.get('version')}")

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

    # --- layout: the approved grid (research/keybind-layout-paladin.md, commit 824c74c) -----------------------
    slots = layout["slots"]
    bars = {b["id"]: b for b in layout["bars"]}

    def what(s):
        return s.get("spell") or ("!" + s["combo"] if s.get("combo") else "@" + str(s.get("item")))

    grid = {
        "1": "holy_strike", "2": "consecration", "3": "holy_shield", "4": "flash_of_light",
        "Q": "judgement", "E": "hammer_of_justice", "R": "exorcism", "F": "seal_of_fury",
        "Z": "@health", "X": "righteous_fury", "C": "templars_bulwark",
        "SHIFT-4": "holy_light", "SHIFT-Q": "swift_judgement", "SHIFT-E": "hammer_of_wrath",
        "SHIFT-R": "holy_wrath", "SHIFT-F": "seal_of_righteousness", "SHIFT-Z": "@mana",
        "SHIFT-X": "blessing_of_kings", "SHIFT-C": "divine_shield",
        "CTRL-Q": "!opener", "CTRL-R": "turn_undead", "CTRL-F": "seal_of_the_crusader",
        "CTRL-X": "redemption", "CTRL-C": "divine_protection",
        "BUTTON4": "blessing_of_protection", "BUTTON5": "cleanse",
        "SHIFT-BUTTON4": "lay_on_hands", "SHIFT-BUTTON5": "blessing_of_freedom",
        "CTRL-BUTTON4": "blessing_of_sacrifice", "CTRL-BUTTON5": "voice_of_truth",
    }
    by_key = {s["key"]: what(s) for s in slots if s.get("key")}
    for k in sorted(set(grid) | set(by_key)):
        if by_key.get(k) != grid.get(k):
            problem(f"paladin layout: key {k} must be {grid.get(k)}, has {by_key.get(k)}")
    # Families: one base key, plain / Shift / Ctrl (what the grid above must keep together).
    families = {
        "Q": ("judgement", "swift_judgement", "!opener"), "E": ("hammer_of_justice", "hammer_of_wrath", None),
        "R": ("exorcism", "holy_wrath", "turn_undead"),
        "F": ("seal_of_fury", "seal_of_righteousness", "seal_of_the_crusader"), "Z": ("@health", "@mana", None),
        "X": ("righteous_fury", "blessing_of_kings", "redemption"),
        "C": ("templars_bulwark", "divine_shield", "divine_protection"), "4": ("flash_of_light", "holy_light", None),
        "BUTTON4": ("blessing_of_protection", "lay_on_hands", "blessing_of_sacrifice"),
        "BUTTON5": ("cleanse", "blessing_of_freedom", "voice_of_truth"),
    }
    for base, fam in families.items():
        got = tuple(by_key.get(m + base) for m in ("", "SHIFT-", "CTRL-"))
        if got != fam:
            problem(f"paladin layout: family on {base} must be {fam}, is {got}")
    spare_keys = {x["key"] for x in layout["spare"] if x.get("key")}
    if spare_keys != {"SHIFT-1", "SHIFT-2", "SHIFT-3", "CTRL-E", "CTRL-Z"}:
        problem(f"paladin layout: spare keys must be Shift+1/2/3, Ctrl+E and Ctrl+Z, are {sorted(spare_keys)}")
    allowed = set(layout["allowedKeys"])
    if allowed != set(grid) | spare_keys:
        problem(f"paladin layout: allowedKeys must be the grid's and spare keys (diff {sorted(allowed ^ (set(grid) | spare_keys))})")
    # 5, Shift+5, Ctrl+5 are his own; Ctrl+1-4 keep the stance bar (auras): never bound, filled or spare.
    if layout.get("ownKeys") != ["5", "SHIFT-5", "CTRL-5"]:
        problem("paladin layout: ownKeys must be 5, SHIFT-5 and CTRL-5")
    keep = layout.get("keepDefault") or []
    if keep != ["CTRL-1", "CTRL-2", "CTRL-3", "CTRL-4"]:
        problem("paladin layout: keepDefault must be Ctrl+1-4 (the stance bar, auras)")
    if (set(keep) | set(layout["ownKeys"])) & allowed:
        problem("paladin layout: an own or kept default key is in allowedKeys")
    b5 = bars.get("bar5", {})
    if (b5.get("first"), b5.get("binding")) != (37, "MULTIACTIONBAR4BUTTON%d") or \
            [k or None for k in b5.get("keys") or []] != [None] * 4 + ["CTRL-" + k for k in "5QERFZXC"]:
        problem("paladin layout: bar5 must be Action Bar 5 with Ctrl+5..C on buttons 5-12 and buttons 1-4 unbound")
    planned = {s["slot"] for s in slots} | {x["slot"] for x in layout["spare"]}
    for i in range(4):
        if b5.get("first", 37) + i in planned:
            problem(f"paladin layout: Action Bar 5 button {i + 1} (Ctrl+{i + 1}, stance bar) is planned or spare")
    b3keys = [k or None for k in (bars.get("bar3", {}).get("keys") or [])]
    if b3keys != [None] * 6 + ["BUTTON4", "BUTTON5", "SHIFT-BUTTON4", "SHIFT-BUTTON5", "CTRL-BUTTON4", "CTRL-BUTTON5"]:
        problem("paladin layout: bar3 buttons 7-12 must hold the mouse keys, 1-6 no key")
    for b in layout["bars"]:
        if b["first"] >= 145 or re.match(r"MULTIACTIONBAR[56]BUTTON", b.get("binding") or ""):
            problem(f"paladin layout: bar {b['id']} uses Action Bar 6 or 7")
    own_slots = sorted(int(x) for x in (layout.get("own") or {}))
    if own_slots != [5, 41, 65]:
        problem(f"paladin layout: own slots must be main 5, bar5 5 and bar2 5, are {own_slots}")
    if layout.get("old") or layout.get("oldOwn") or layout.get("retired"):
        problem("paladin layout: a first layout has no earlier layouts' leftovers")
    # Auras on the stance bar; Purify stands in on Cleanse's button until 42, then is in the spellbook.
    auras = [s["key"] for s in pack["spells"] if s["key"].endswith("_aura")]
    for k in auras:
        if layout["noSlot"].get(k) != "stancebar":
            problem(f"paladin layout: {k} must be on the stance bar (noSlot)")
    m5 = next((s for s in slots if s.get("key") == "BUTTON5"), {})
    if m5.get("standIn") != "purify" or layout["noSlot"].get("purify") != "spellbook":
        problem("paladin layout: Mouse5 must be Cleanse with Purify standing in until it is learned")
    clicked = {what(s) for s in slots if not s.get("key")}
    for k in ("blessing_of_might", "blessing_of_wisdom", "greater_blessing_of_kings", "greater_blessing_of_might",
              "greater_blessing_of_wisdom", "seal_of_wisdom", "seal_of_light", "seal_of_justice", "divine_intervention"):
        if k not in clicked:
            problem(f"paladin layout: {k} must be on a clicked button (no key)")
    # Macros: help with the self fallback, help_nofb (Blessing of Protection, Sacrifice) without, Hammer of Justice
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
            "blessing_of_protection": "help_nofb", "blessing_of_sacrifice": "help_nofb", "hammer_of_justice": "interrupt"}:
        problem("paladin layout: macroKind must be help_nofb for Protection and Sacrifice, interrupt for Hammer of Justice")
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
    if layout.get("defaultWarn", {}).get("CTRL-R") != "ui.preview.warn.fps":
        problem("paladin layout: the preview must warn that Ctrl+R loses its default")
    if layout.get("version") != 1:
        problem(f"paladin layout: version must be 1, is {layout.get('version')}")

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
