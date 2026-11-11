-- ForeverSensei_Paladin/Data/Protection/Layout.lua: the fixed bar and key plan for a Protection Paladin (dungeon tank).
-- The spec is research/keybind-layout-paladin.md (approved grid, commit 824c74c). Planned for level 60; keys never
-- move while levelling, and a spell learned later keeps its slot empty until it is learned.
--
-- Hands: normal-sized, WASD. Allowed keys: 1-5, Q, E, R, F, Z, X, C and the mouse side buttons, each plain, with
-- Shift or with Ctrl. 5, Shift+5 and Ctrl+5 are the player's own (never bound or filled).
-- - Top keys hold what is pressed in combat in most pulls: 1 Holy Strike, 2 Consecration, 3 Holy Shield, Q Judgement.
-- - Families share one base key with plain, Shift and Ctrl (frequency and urgency pick the variant):
--   Q Judgement / Swift Judgement / the opener macro; E Hammer of Justice / Hammer of Wrath; R Exorcism / Holy Wrath /
--   Turn Undead (against undead); F Seal of Fury / Seal of Righteousness / Seal of the Crusader; Z health / mana
--   potion; X Righteous Fury / Blessing of Kings / Redemption (between pulls); C Templar's Bulwark / Divine Shield /
--   Divine Protection (Forbearance); 4 Flash of Light / Holy Light; Mouse4 Blessing of Protection / Lay on Hands /
--   Blessing of Sacrifice (save a party member); Mouse5 Cleanse (Purify until 42) / Blessing of Freedom / Voice of
--   Truth (free a party member).
-- - Auras use the stance bar. Ctrl+1-4 stay on their game default (stance bar buttons 1-4), so Action Bar 5 buttons
--   1-4 are neither bound nor filled. Frost and Fire Resistance Aura (stance buttons 5 and 6) are clicked.
-- - Bars: plain = Action Bar 1, Shift = Action Bar 2, Ctrl = Action Bar 5 (the right edge, Q-C in the same order as
--   Shift), mouse = Action Bar 3 buttons 7-12. Action Bar 3 buttons 1-6 and Action Bar 4 are clicked. Action Bars 6
--   and 7 are never used.
-- - Spares (bound, empty): Shift+1, Shift+2, Shift+3, Ctrl+E and Ctrl+Z.
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
  -- Ctrl+1-4: false = not bound by the addon, the key keeps its game default (the auras on the stance bar).
  { id = "bar5", first = 37,  binding = "MULTIACTIONBAR4BUTTON%d", setting = "PROXY_SHOW_ACTIONBAR_5",
    keys = { false, false, false, false, "CTRL-5", "CTRL-Q", "CTRL-E", "CTRL-R", "CTRL-F", "CTRL-Z", "CTRL-X", "CTRL-C" } },
  { id = "bar3", first = 49,  binding = "MULTIACTIONBAR2BUTTON%d", setting = "PROXY_SHOW_ACTIONBAR_3",
    keys = { false, false, false, false, false, false,
      "BUTTON4", "BUTTON5", "SHIFT-BUTTON4", "SHIFT-BUTTON5", "CTRL-BUTTON4", "CTRL-BUTTON5" } },
  { id = "bar4", first = 25,  binding = "MULTIACTIONBAR3BUTTON%d", setting = "PROXY_SHOW_ACTIONBAR_4" },
}

-- Bump when slots or keys change (characters then get the one-time "apply all" notice).
L.version = 1

L.allowedKeys = {
  "1", "2", "3", "4", "Q", "E", "R", "F", "Z", "X", "C",
  "SHIFT-1", "SHIFT-2", "SHIFT-3", "SHIFT-4", "SHIFT-Q", "SHIFT-E", "SHIFT-R", "SHIFT-F", "SHIFT-Z", "SHIFT-X",
  "SHIFT-C",
  "CTRL-Q", "CTRL-E", "CTRL-R", "CTRL-F", "CTRL-Z", "CTRL-X", "CTRL-C",
  "BUTTON4", "BUTTON5", "SHIFT-BUTTON4", "SHIFT-BUTTON5", "CTRL-BUTTON4", "CTRL-BUTTON5",
}

L.ownKeys = { "5", "SHIFT-5", "CTRL-5" }

-- Keys the addon never binds: they keep their game default (stance bar buttons 1-4 = the auras).
L.keepDefault = { "CTRL-1", "CTRL-2", "CTRL-3", "CTRL-4" }
-- Shown under the bars on the guide's key page.
L.keyNotes = { "ui.layout.stancekeys" }

L.plan = {
  main = {
    "holy_strike", "consecration", "holy_shield", "flash_of_light", "#",
    "judgement", "hammer_of_justice", "exorcism", "seal_of_fury",
    "@health", "righteous_fury", "templars_bulwark",
  },
  bar2 = {
    "-", "-", "-", "holy_light", "#",
    "swift_judgement", "hammer_of_wrath", "holy_wrath", "seal_of_righteousness",
    "@mana", "blessing_of_kings", "divine_shield",
  },
  bar5 = {
    "x", "x", "x", "x", "#",
    "!opener", "-", "turn_undead", "seal_of_the_crusader",
    "-", "redemption", "divine_protection",
  },
  bar3 = {
    "seal_of_wisdom", "seal_of_light", "seal_of_justice", "blessing_of_might", "blessing_of_wisdom", "-",
    "blessing_of_protection", { "cleanse", standIn = "purify" }, "lay_on_hands", "blessing_of_freedom",
    "blessing_of_sacrifice", "voice_of_truth",
  },
  bar4 = {
    "greater_blessing_of_kings", "greater_blessing_of_might", "greater_blessing_of_wisdom", "divine_intervention",
    "-", "-", "-", "-", "-", "-", "-", "-",
  },
}

-- Spells without a bar slot: the auras are on the stance bar; Purify (replaced by Cleanse on Mouse5 at 42) and the
-- mounts are used from the spellbook.
L.noSlot = {
  devotion_aura = "stancebar",
  retribution_aura = "stancebar",
  concentration_aura = "stancebar",
  shadow_resistance_aura = "stancebar",
  frost_resistance_aura = "stancebar",
  fire_resistance_aura = "stancebar",
  purify = "spellbook",
  summon_warhorse = "spellbook",
  summon_charger = "spellbook",
}
L.noSlotLines = {
  { kind = "stancebar", text = "ui.layout.nostance" },
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

-- The preview warns when a key loses one of these game defaults.
L.defaultWarn = {
  ["CTRL-R"] = "ui.preview.warn.fps",
}

L.spareOrder = { "bar4", "bar3", "bar2", "bar5" }
