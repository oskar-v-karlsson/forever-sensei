-- ForeverSensei_Shaman/Data/Spells.lua: every Shaman spell a Restoration Shaman learns from level 1 to 60 in WoW: Forever.
-- Fields: key (text id stem), name (English client name, also used to resolve the highest rank), id (rank 1 spell id),
-- level (first available), role (heal | damage | support), use (group | solo | both), talent (learned through the
-- talent tree; level = when the Mobalytics leveling path takes it), passive, races (a racial: the race ids of its race
-- mask in the client dump; other races never see it, ns.BuildLayout L.gated), src (a key in P.sources or the core's
-- sources: wh_spell, wh_item, ui), verified.
-- What/when texts live in this pack's Locales as spell.<key>.what / spell.<key>.when.
local _, P = ...

-- Sources of this pack's data (the core merges them into its own list while the pack is active).
P.sources = {
  simc = "simc-forever SpellDataDump, client 1.60.1.70862 (github.com/simulationcraft/simc-forever, SpellDataDump/shaman.txt)",
  wh_abilities = "https://www.wowhead.com/forever/guide/classes/shaman/restoration/healer-abilities",
  wh_overview = "https://www.wowhead.com/forever/guide/classes/shaman/restoration/overview-pve-healer",
  wh_talents = "https://www.wowhead.com/forever/guide/classes/shaman/restoration/talent-builds-pve-healer",
  moba = "https://mobalytics.gg/wow-forever/classes/restoration-shaman-guide",
  simc_race = "simc-forever SpellDataDump, client 1.60.1.70938 (github.com/simulationcraft/simc-forever @1c895ad3, SpellDataDump/nonclass.txt: racials)",
}

local V = "2026-11-09"

local S = {}
P.spells = S

local function add(t)
  t.verified = t.verified or V
  table.insert(S, t)
end

add { key = "healing_wave",            name = "Healing Wave",            id = 331,    level = 1,  role = "heal",    use = "both",  src = "simc" }
add { key = "lightning_bolt",          name = "Lightning Bolt",          id = 403,    level = 1,  role = "damage",  use = "both",  src = "simc" }
add { key = "rockbiter_weapon",        name = "Rockbiter Weapon",        id = 8017,   level = 1,  role = "support", use = "solo",  src = "simc" }
add { key = "earth_shock",             name = "Earth Shock",             id = 8042,   level = 4,  role = "damage",  use = "both",  src = "simc" }
add { key = "stoneskin_totem",         name = "Stoneskin Totem",         id = 8071,   level = 4,  role = "support", use = "group", src = "simc" }
add { key = "earthbind_totem",         name = "Earthbind Totem",         id = 2484,   level = 6,  role = "support", use = "both",  src = "simc" }
add { key = "stoneclaw_totem",         name = "Stoneclaw Totem",         id = 5730,   level = 8,  role = "support", use = "solo",  src = "simc" }
add { key = "lightning_shield",        name = "Lightning Shield",        id = 324,    level = 8,  role = "support", use = "solo",  src = "simc" }
add { key = "flame_shock",             name = "Flame Shock",             id = 8050,   level = 10, role = "damage",  use = "both",  src = "simc" }
add { key = "searing_totem",           name = "Searing Totem",           id = 3599,   level = 10, role = "damage",  use = "both",  src = "simc" }
add { key = "flametongue_weapon",      name = "Flametongue Weapon",      id = 8024,   level = 10, role = "support", use = "solo",  src = "simc" }
add { key = "strength_of_earth_totem", name = "Strength of Earth Totem", id = 8075,   level = 10, role = "support", use = "group", src = "simc" }
add { key = "fire_nova",               name = "Fire Nova",               id = 408341, level = 12, role = "damage",  use = "both",  src = "simc" }
add { key = "purge",                   name = "Purge",                   id = 370,    level = 12, role = "support", use = "both",  src = "simc" }
add { key = "ancestral_spirit",        name = "Ancestral Spirit",        id = 2008,   level = 12, role = "support",    use = "group", src = "simc" }
add { key = "cure_poison",             name = "Cure Poison",             id = 526,    level = 16, role = "support",    use = "both",  src = "simc" }
add { key = "tremor_totem",            name = "Tremor Totem",            id = 8143,   level = 18, role = "support", use = "group", src = "simc" }
add { key = "call_of_the_elements",    name = "Call of the Elements",    id = 66842,  level = 20, role = "support", use = "both",  src = "wh_spell" }
add { key = "frost_shock",             name = "Frost Shock",             id = 8056,   level = 20, role = "damage",  use = "solo",  src = "simc" }
add { key = "totemic_recall",          name = "Totemic Recall",          id = 36936,  level = 20, role = "support", use = "both",  src = "wh_spell" }
add { key = "frostbrand_weapon",       name = "Frostbrand Weapon",       id = 8033,   level = 20, role = "support", use = "solo",  src = "simc" }
add { key = "ghost_wolf",              name = "Ghost Wolf",              id = 2645,   level = 20, role = "support", use = "both",  src = "simc" }
add { key = "healing_stream_totem",    name = "Healing Stream Totem",    id = 5394,   level = 20, role = "heal",    use = "group", src = "simc" }
add { key = "lesser_healing_wave",     name = "Lesser Healing Wave",     id = 8004,   level = 20, role = "heal",    use = "both",  src = "simc" }
add { key = "water_shield",            name = "Water Shield",            id = 408510, level = 20, role = "support", use = "both",  src = "simc", talent = true }
add { key = "totemic_call",            name = "Totemic Call",            id = 437009, level = 22, role = "support", use = "both",  src = "simc" }
add { key = "water_breathing",         name = "Water Breathing",         id = 131,    level = 22, role = "support", use = "both",  src = "wh_spell" }
add { key = "cure_disease",            name = "Cure Disease",            id = 2870,   level = 22, role = "support",    use = "both",  src = "simc" }
add { key = "poison_cleansing_totem",  name = "Poison Cleansing Totem",  id = 8166,   level = 22, role = "support", use = "group", src = "simc" }
add { key = "frost_resistance_totem",  name = "Frost Resistance Totem",  id = 8181,   level = 24, role = "support", use = "group", src = "simc" }
add { key = "mana_tide_totem",         name = "Mana Tide Totem",         id = 16190,  level = 25, role = "support",    use = "group", src = "simc", talent = true }
add { key = "magma_totem",             name = "Magma Totem",             id = 8190,   level = 26, role = "damage",  use = "both",  src = "simc" }
add { key = "far_sight",               name = "Far Sight",               id = 6196,   level = 26, role = "support", use = "solo",  src = "simc" }
add { key = "mana_spring_totem",       name = "Mana Spring Totem",       id = 5675,   level = 26, role = "support",    use = "group", src = "simc" }
add { key = "fire_resistance_totem",   name = "Fire Resistance Totem",   id = 8184,   level = 28, role = "support", use = "group", src = "simc" }
add { key = "flametongue_totem",       name = "Flametongue Totem",       id = 8227,   level = 28, role = "support", use = "group", src = "simc" }
add { key = "water_walking",           name = "Water Walking",           id = 546,    level = 28, role = "support", use = "both",  src = "wh_spell" }
add { key = "call_of_the_ancestors",   name = "Call of the Ancestors",   id = 66843,  level = 30, role = "support", use = "both",  src = "wh_spell" }
add { key = "astral_recall",           name = "Astral Recall",           id = 556,    level = 30, role = "support", use = "both",  src = "wh_spell" }
add { key = "grounding_totem",         name = "Grounding Totem",         id = 8177,   level = 30, role = "support", use = "group", src = "simc" }
add { key = "nature_resistance_totem", name = "Nature Resistance Totem", id = 10595,  level = 30, role = "support", use = "group", src = "simc" }
add { key = "windfury_weapon",         name = "Windfury Weapon",         id = 8232,   level = 30, role = "support", use = "solo",  src = "simc" }
add { key = "natures_swiftness",       name = "Nature's Swiftness",      id = 16188,  level = 30, role = "heal",    use = "both",  src = "simc", talent = true }
add { key = "reincarnation",           name = "Reincarnation",           id = 20608,  level = 30, role = "support", use = "both",  src = "simc", passive = true }
add { key = "chain_lightning",         name = "Chain Lightning",         id = 421,    level = 32, role = "damage",  use = "both",  src = "simc" }
add { key = "windfury_totem",          name = "Windfury Totem",          id = 8512,   level = 32, role = "support", use = "group", src = "simc" }
add { key = "sentry_totem",            name = "Sentry Totem",            id = 6495,   level = 34, role = "support", use = "solo",  src = "simc" }
add { key = "windwall_totem",          name = "Windwall Totem",          id = 15107,  level = 36, role = "support", use = "group", src = "simc" }
add { key = "disease_cleansing_totem", name = "Disease Cleansing Totem", id = 8170,   level = 38, role = "support", use = "group", src = "simc" }
add { key = "call_of_the_spirits",     name = "Call of the Spirits",     id = 66844,  level = 40, role = "support", use = "both",  src = "wh_spell" }
add { key = "chain_heal",              name = "Chain Heal",              id = 1064,   level = 40, role = "heal",    use = "group", src = "simc" }
add { key = "riptide",                 name = "Riptide",                 id = 408521, level = 40, role = "heal",    use = "both",  src = "simc", talent = true }
add { key = "grace_of_air_totem",      name = "Grace of Air Totem",      id = 8835,   level = 42, role = "support", use = "group", src = "simc" }

-- Skyborne racials (simc_race, nonclass.txt): the race mask's bit n is race id n + 1 (Human 0x1, Dwarf 0x4). Walk on
-- Air 0x300000000 = race ids 33 and 34 (both Skyborne races), Skysight 0x200000000 = race id 34 (the other Skyborne
-- race gets Read Leyline, 0x100000000). Known from level 1, not from the trainer.
add { key = "walk_on_air",             name = "Walk on Air",             id = 1259416, level = 1, role = "support", use = "both", src = "simc_race", races = { 33, 34 }, verified = "2026-11-13" }
add { key = "skysight",                name = "Skysight",                id = 1259686, level = 1, role = "support", use = "both", src = "simc_race", races = { 34 }, verified = "2026-11-13" }
