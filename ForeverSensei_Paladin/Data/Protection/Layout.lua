-- ForeverSensei_Paladin/Data/Protection/Layout.lua: the fixed bar and key plan for a Protection Paladin (dungeon tank),
-- layout version 2 (since ForeverSensei 0.7.0: "family blocks"). Spec: research/keybind-layout-v4.md P1-P8 (approved,
-- commit 27b6754), which builds on research/keybind-layout-paladin.md (pull walkthroughs, reach tiers for normal
-- hands). Planned for level 60; keys never move while levelling, and a spell learned later keeps its slot empty until
-- it is learned.
--
-- Hands: normal-sized, WASD. Allowed keys: 1-5, Q, E, R, F, Z, X, C and the mouse side buttons, each plain, with
-- Shift or with Ctrl. No key is the player's own any more: 5, Shift+5 and Ctrl+5 are planned like the others.
-- Rules (Oskar's decisions for v4):
-- * Each modifier row splits into three blocks of neighbouring keys: 1-5, Q/E/R/F and Z/X/C. A family fills one
--   block, so it sits together on the keyboard and, because button n is key n on bars 1-3, on screen.
-- * Plain row = the core rotation: 1 Holy Strike, 2 Consecration, 3 Holy Shield, 4 Flash of Light, 5 Holy Light;
--   Q Judgement, E Swift Judgement, R the opener macro, F Hammer of Justice; Z health, X mana, C Righteous Fury.
-- * Shift 1-5 seals (Fury, Righteousness, Crusader, Wisdom, Light; Justice is clicked on Action Bar 6); Shift Q/E/R/F
--   conditional attacks (Exorcism, Hammer of Wrath, Holy Wrath, Turn Undead); Shift Z/X/C Forbearance (Templar's
--   Bulwark, Divine Shield, Divine Protection).
-- * Ctrl 1-5 auras on Action Bar 3 (Retribution, Devotion, Concentration, Shadow and Frost Resistance; Fire
--   Resistance is clicked on Action Bar 6). The stance bar still shows every aura as the game draws it; the addon
--   doesn't touch it. Ctrl Q/E/R/F spare (bound, empty); Ctrl Z/X/C blessings (Kings, Might, Wisdom).
-- * Mouse columns: Mouse4 saves a party member (Blessing of Protection / Lay on Hands / Blessing of Sacrifice),
--   Mouse5 frees one (Cleanse, Purify until 42 / Blessing of Freedom / Voice of Truth).
-- Bars: plain = Action Bar 1, Shift = Action Bar 2, Ctrl = Action Bar 3 (all at the bottom). Action Bar 6 holds the
-- mouse keys (buttons 1-6, column by column) and the clicked spells used in combat; it starts in the middle of the
-- screen and the guide tells the player to drag it down in Edit Mode. Action Bar 4 holds out-of-combat clicks
-- (Redemption, Greater Blessings). Action Bar 5 (the Ctrl bar of layout 1) left the plan: it stays as the player has
-- it, and a full apply only clears what layout 1 put there (L.old).
local _, P = ...
P.specs = P.specs or {}
P.specs.PROTECTION = P.specs.PROTECTION or {}

local L = {}
P.specs.PROTECTION.layout = L

local KEYS = { "1", "2", "3", "4", "5", "Q", "E", "R", "F", "Z", "X", "C" }
local function withMod(mod)
  local list = {}
  for i, k in ipairs(KEYS) do list[i] = mod .. k end
  return list
end
L.bars = {
  { id = "main", first = 1,   binding = "ACTIONBUTTON%d",          setting = nil,                      keys = KEYS },
  { id = "bar2", first = 61,  binding = "MULTIACTIONBAR1BUTTON%d", setting = "PROXY_SHOW_ACTIONBAR_2", keys = withMod("SHIFT-") },
  { id = "bar3", first = 49,  binding = "MULTIACTIONBAR2BUTTON%d", setting = "PROXY_SHOW_ACTIONBAR_3", keys = withMod("CTRL-") },
  -- editMode: the bar starts in the middle of the screen; the guide and the preview tell the player to move it.
  { id = "bar6", first = 145, binding = "MULTIACTIONBAR5BUTTON%d", setting = "PROXY_SHOW_ACTIONBAR_6", editMode = true,
    keys = { "BUTTON4", "SHIFT-BUTTON4", "CTRL-BUTTON4", "BUTTON5", "SHIFT-BUTTON5", "CTRL-BUTTON5",
      false, false, false, false, false, false } },
  { id = "bar4", first = 25,  binding = "MULTIACTIONBAR3BUTTON%d", setting = "PROXY_SHOW_ACTIONBAR_4" },
}

-- Bars the plan no longer uses. Action Bar 5 (the Ctrl bar of layout 1) stays as the player has it (keepShown); the
-- clean-up button empties only the buttons layout 1 filled there (assigned).
L.retired = {
  { id = "bar5", first = 37,  binding = "MULTIACTIONBAR4BUTTON%d", setting = "PROXY_SHOW_ACTIONBAR_5", keepShown = true,
    assigned = { 6, 8, 9, 11, 12 } },
}

-- Bump when slots or keys change (characters then get the one-time "apply all" notice).
L.version = 2

L.allowedKeys = {
  "1", "2", "3", "4", "5", "Q", "E", "R", "F", "Z", "X", "C",
  "SHIFT-1", "SHIFT-2", "SHIFT-3", "SHIFT-4", "SHIFT-5", "SHIFT-Q", "SHIFT-E", "SHIFT-R", "SHIFT-F", "SHIFT-Z",
  "SHIFT-X", "SHIFT-C",
  "CTRL-1", "CTRL-2", "CTRL-3", "CTRL-4", "CTRL-5", "CTRL-Q", "CTRL-E", "CTRL-R", "CTRL-F", "CTRL-Z", "CTRL-X", "CTRL-C",
  "BUTTON4", "BUTTON5", "SHIFT-BUTTON4", "SHIFT-BUTTON5", "CTRL-BUTTON4", "CTRL-BUTTON5",
}

L.plan = {
  main = {
    "holy_strike", "consecration", "holy_shield", "flash_of_light", "holy_light",
    "judgement", "swift_judgement", "!opener", "hammer_of_justice",
    "@health", "@mana", "righteous_fury",
  },
  bar2 = {
    "seal_of_fury", "seal_of_righteousness", "seal_of_the_crusader", "seal_of_wisdom", "seal_of_light",
    "exorcism", "hammer_of_wrath", "holy_wrath", "turn_undead",
    "templars_bulwark", "divine_shield", "divine_protection",
  },
  bar3 = {
    "retribution_aura", "devotion_aura", "concentration_aura", "shadow_resistance_aura", "frost_resistance_aura",
    "-", "-", "-", "-",
    "blessing_of_kings", "blessing_of_might", "blessing_of_wisdom",
  },
  bar6 = {
    "blessing_of_protection", "lay_on_hands", "blessing_of_sacrifice",
    { "cleanse", standIn = "purify" }, "blessing_of_freedom", "voice_of_truth",
    "seal_of_justice", "fire_resistance_aura", "divine_intervention", "-", "-", "-",
  },
  bar4 = {
    "redemption", "greater_blessing_of_kings", "greater_blessing_of_might", "greater_blessing_of_wisdom",
    "-", "-", "-", "-", "-", "-", "-", "-",
  },
}

-- Families (research/keybind-layout-v4.md P1/P2): each keyed family fills one block of one row, or one mouse column
-- (block "BUTTON4"/"BUTTON5": plain, Shift, Ctrl); spill-overs are clicked on Action Bar 6. tools/check.py checks the
-- plan against this list.
L.families = {
  { id = "judgement", block = "QERF", row = "", members = { "judgement", "swift_judgement", "!opener" } },
  { id = "seals", block = "1-5", row = "SHIFT-", spill = { "seal_of_justice" },
    members = { "seal_of_fury", "seal_of_righteousness", "seal_of_the_crusader", "seal_of_wisdom", "seal_of_light" } },
  { id = "conditional", block = "QERF", row = "SHIFT-", members = { "exorcism", "hammer_of_wrath", "holy_wrath", "turn_undead" } },
  { id = "forbearance", block = "ZXC", row = "SHIFT-", members = { "templars_bulwark", "divine_shield", "divine_protection" } },
  { id = "auras", block = "1-5", row = "CTRL-", spill = { "fire_resistance_aura" },
    members = { "retribution_aura", "devotion_aura", "concentration_aura", "shadow_resistance_aura", "frost_resistance_aura" } },
  { id = "blessings", block = "ZXC", row = "CTRL-", members = { "blessing_of_kings", "blessing_of_might", "blessing_of_wisdom" } },
  { id = "save", block = "BUTTON4", members = { "blessing_of_protection", "lay_on_hands", "blessing_of_sacrifice" } },
  { id = "free", block = "BUTTON5", members = { "cleanse", "blessing_of_freedom", "voice_of_truth" } },
}

-- Spells without a bar slot: Purify (replaced by Cleanse on Mouse5 at 42) and the mounts are used from the spellbook.
L.noSlot = {
  purify = "spellbook",
  summon_warhorse = "spellbook",
  summon_charger = "spellbook",
}
L.noSlotLines = {
  { kind = "spellbook", text = "ui.layout.nobook" },
}

-- Mouseover macros (mouseover targeting mode); in click-target mode the plain spell is placed instead, except
-- macroAlways. Purify uses its macro while it stands in on Cleanse's button.
L.macros = {
  flash_of_light = "FS_FOL",
  holy_light = "FS_HL",
  lay_on_hands = "FS_LOH",
  cleanse = "FS_CLEANSE",
  purify = "FS_PURIFY",
  blessing_of_freedom = "FS_BOF",
  blessing_of_protection = "FS_BOP",
  blessing_of_sacrifice = "FS_BOS",
  hammer_of_justice = "FS_HOJ",
}
L.macroKind = {
  blessing_of_protection = "help_nofb",
  blessing_of_sacrifice = "help_nofb",
  hammer_of_justice = "interrupt",
}
L.macroAlways = { hammer_of_justice = true }
-- help: a friendly mouseover, else a friendly target, else yourself. help_nofb: never yourself (Blessing of
-- Protection would stop your attacks; Blessing of Sacrifice can't target yourself). interrupt: Hammer of Justice
-- (a stun, the paladin has no interrupt) stops your own cast first.
L.macroBodies = {
  help = "#showtooltip {spell}\n/cast [@mouseover,help,nodead][help,nodead][@player] {spell}",
  help_nofb = "#showtooltip {spell}\n/cast [@mouseover,help,nodead][help,nodead] {spell}",
  interrupt = "#showtooltip {spell}\n/stopcasting\n/cast [@mouseover,harm,nodead][] {spell}",
  interrupt_click = "#showtooltip {spell}\n/stopcasting\n/cast {spell}",
}

-- Multi-spell macros ("!id" in the plan). The opener (Mobalytics "Big Threat Opener", fixed): Judgement and Swift
-- Judgement are off the global cooldown, so one press fires both and then Holy Strike. Placed once Swift Judgement
-- (talent, level 37) is known.
L.combos = {
  opener = {
    macro = "FS_OPEN",
    label = "ui.combo.opener",
    body = "#showtooltip {swift}\n/startattack\n/cast {judge}\n/cast {swift}\n/cast {strike}",
    vars = { swift = "swift_judgement", judge = "judgement", strike = "holy_strike" },
    needs = "swift_judgement",
  },
}

-- What layout 1 put on buttons that are now off the plan or spare (Action Bar 5, Action Bar 3 buttons 7-9). A full
-- apply clears such a button only while it still holds exactly that spell and the spell has a new home.
L.old = {
  [42] = "!opener", [44] = "turn_undead", [45] = "seal_of_the_crusader", [47] = "redemption", [48] = "divine_protection",
  [55] = "blessing_of_protection", [56] = { "cleanse", "purify" }, [57] = "lay_on_hands",
}

-- The preview warns when a key loses one of these game defaults (Ctrl+1-5: stance bar buttons; Ctrl+R: framerate).
L.defaultWarn = {
  ["CTRL-1"] = "ui.preview.warn.stance",
  ["CTRL-2"] = "ui.preview.warn.stance",
  ["CTRL-3"] = "ui.preview.warn.stance",
  ["CTRL-4"] = "ui.preview.warn.stance",
  ["CTRL-5"] = "ui.preview.warn.stance",
  ["CTRL-R"] = "ui.preview.warn.fps",
}

L.spareOrder = { "bar4", "bar6", "bar3" }
