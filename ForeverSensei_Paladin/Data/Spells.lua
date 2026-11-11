-- ForeverSensei_Paladin/Data/Spells.lua: every Paladin spell a Protection Paladin learns from level 1 to 60 in WoW: Forever.
-- Fields: key (text id stem), name (English client name, also used to resolve the highest rank), id (rank 1 spell id),
-- level (first available), role (tank | heal | damage | support), use (group | solo | both), talent (learned through
-- the talent tree; level = when the Wowhead leveling path takes it), src (a key in P.sources or the core's sources:
-- wh_spell, wh_item, ui), verified.
-- What/when texts live in this pack's Locales as spell.<key>.what / spell.<key>.when.
-- Left out on purpose: Sense Undead (tracking, no verified level) and the spells research/keybind-layout-paladin.md
-- "Sources" could not verify as trainable in Forever (three blessings and a Protection hammer; see tools/check.py
-- PALADIN_EXCLUDED).
local _, P = ...

-- Sources of this pack's data (the core merges them into its own list while the pack is active).
P.sources = {
  simc = "simc-forever SpellDataDump, client 1.60.1.70862 (github.com/simulationcraft/simc-forever, SpellDataDump/paladin.txt)",
  wh_tt = "Wowhead Forever spell tooltips (nether.wowhead.com/forever/tooltip/spell/<id>)",
  wh_guide = "https://www.wowhead.com/forever/guide/classes/paladin/protection/tank-leveling-tips",
  moba = "https://mobalytics.gg/wow-forever/classes/protection-paladin-guide",
  wh_abil = "https://www.wowhead.com/forever/spells/abilities/paladin",
}

local V = "2026-11-11"

local S = {}
P.spells = S

local function add(t)
  t.verified = t.verified or V
  table.insert(S, t)
end

add { key = "devotion_aura",              name = "Devotion Aura",              id = 465,     level = 1,  role = "support", use = "both",  src = "simc" }
add { key = "seal_of_righteousness",      name = "Seal of Righteousness",      id = 20154,   level = 1,  role = "damage",  use = "both",  src = "simc" }
add { key = "holy_light",                 name = "Holy Light",                 id = 635,     level = 1,  role = "heal",    use = "both",  src = "wh_tt" }
add { key = "blessing_of_might",          name = "Blessing of Might",          id = 19740,   level = 4,  role = "support", use = "both",  src = "simc" }
add { key = "judgement",                  name = "Judgement",                  id = 20271,   level = 4,  role = "tank",    use = "both",  src = "simc" }
add { key = "divine_protection",          name = "Divine Protection",          id = 498,     level = 6,  role = "tank",    use = "both",  src = "simc" }
add { key = "holy_strike",                name = "Holy Strike",                id = 679,     level = 6,  role = "damage",  use = "both",  src = "simc" }
add { key = "seal_of_the_crusader",       name = "Seal of the Crusader",       id = 21082,   level = 6,  role = "damage",  use = "both",  src = "simc" }
add { key = "hammer_of_justice",          name = "Hammer of Justice",          id = 853,     level = 8,  role = "support", use = "both",  src = "simc" }
add { key = "purify",                     name = "Purify",                     id = 1152,    level = 8,  role = "support", use = "both",  src = "simc" }
add { key = "lay_on_hands",               name = "Lay on Hands",               id = 633,     level = 10, role = "heal",    use = "both",  src = "simc" }
add { key = "blessing_of_protection",     name = "Blessing of Protection",     id = 1022,    level = 10, role = "support", use = "group", src = "simc" }
add { key = "seal_of_fury",               name = "Seal of Fury",               id = 1311649, level = 10, role = "tank",    use = "both",  src = "simc" }
add { key = "righteous_fury",             name = "Righteous Fury",             id = 25780,   level = 10, role = "tank",    use = "group", src = "simc" }
add { key = "redemption",                 name = "Redemption",                 id = 7328,    level = 12, role = "support", use = "group", src = "simc" }
add { key = "blessing_of_wisdom",         name = "Blessing of Wisdom",         id = 19742,   level = 14, role = "support", use = "both",  src = "simc" }
add { key = "retribution_aura",           name = "Retribution Aura",           id = 7294,    level = 16, role = "damage",  use = "both",  src = "simc" }
add { key = "blessing_of_freedom",        name = "Blessing of Freedom",        id = 1044,    level = 18, role = "support", use = "both",  src = "simc" }
add { key = "exorcism",                   name = "Exorcism",                   id = 879,     level = 20, role = "damage",  use = "both",  src = "simc" }
add { key = "flash_of_light",             name = "Flash of Light",             id = 19750,   level = 20, role = "heal",    use = "both",  src = "simc" }
add { key = "consecration",               name = "Consecration",               id = 26573,   level = 20, role = "tank",    use = "both",  src = "simc" }
add { key = "blessing_of_kings",          name = "Blessing of Kings",          id = 20217,   level = 20, role = "support", use = "both",  src = "simc" }
add { key = "voice_of_truth",             name = "Voice of Truth",             id = 1310897, level = 20, role = "support", use = "both",  src = "simc" }
add { key = "concentration_aura",         name = "Concentration Aura",         id = 19746,   level = 22, role = "support", use = "group", src = "simc" }
add { key = "seal_of_justice",            name = "Seal of Justice",            id = 20164,   level = 22, role = "support", use = "solo",  src = "simc" }
add { key = "turn_undead",                name = "Turn Undead",                id = 2878,    level = 24, role = "support", use = "both",  src = "simc" }
add { key = "shadow_resistance_aura",     name = "Shadow Resistance Aura",     id = 19876,   level = 28, role = "support", use = "group", src = "simc" }
add { key = "divine_intervention",        name = "Divine Intervention",        id = 19752,   level = 30, role = "support", use = "group", src = "simc" }
add { key = "seal_of_light",              name = "Seal of Light",              id = 20165,   level = 30, role = "heal",    use = "solo",  src = "simc" }
add { key = "templars_bulwark",           name = "Templar's Bulwark",          id = 1311015, level = 32, role = "tank",    use = "both",  src = "simc", talent = true }
add { key = "frost_resistance_aura",      name = "Frost Resistance Aura",      id = 19888,   level = 32, role = "support", use = "group", src = "simc" }
add { key = "divine_shield",              name = "Divine Shield",              id = 642,     level = 34, role = "tank",    use = "both",  src = "simc" }
add { key = "fire_resistance_aura",       name = "Fire Resistance Aura",       id = 19891,   level = 36, role = "support", use = "group", src = "simc" }
add { key = "swift_judgement",            name = "Swift Judgement",            id = 1310994, level = 37, role = "tank",    use = "both",  src = "simc", talent = true }
add { key = "seal_of_wisdom",             name = "Seal of Wisdom",             id = 20166,   level = 38, role = "support", use = "both",  src = "simc" }
add { key = "summon_warhorse",            name = "Summon Warhorse",            id = 13819,   level = 40, role = "support", use = "both",  src = "wh_tt" }
add { key = "holy_shield",                name = "Holy Shield",                id = 20925,   level = 42, role = "tank",    use = "group", src = "simc", talent = true }
add { key = "cleanse",                    name = "Cleanse",                    id = 4987,    level = 42, role = "support", use = "both",  src = "simc" }
add { key = "hammer_of_wrath",            name = "Hammer of Wrath",            id = 24275,   level = 44, role = "damage",  use = "both",  src = "simc" }
add { key = "blessing_of_sacrifice",      name = "Blessing of Sacrifice",      id = 6940,    level = 46, role = "support", use = "group", src = "simc" }
add { key = "holy_wrath",                 name = "Holy Wrath",                 id = 2812,    level = 50, role = "damage",  use = "both",  src = "simc" }
add { key = "greater_blessing_of_might",  name = "Greater Blessing of Might",  id = 25782,   level = 52, role = "support", use = "group", src = "simc" }
add { key = "greater_blessing_of_wisdom", name = "Greater Blessing of Wisdom", id = 25894,   level = 54, role = "support", use = "group", src = "simc" }
add { key = "greater_blessing_of_kings",  name = "Greater Blessing of Kings",  id = 25898,   level = 60, role = "support", use = "group", src = "simc" }
add { key = "summon_charger",             name = "Summon Charger",             id = 23214,   level = 60, role = "support", use = "both",  src = "wh_tt" }
