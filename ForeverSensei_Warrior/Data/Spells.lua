-- ForeverSensei_Warrior/Data/Spells.lua: every Warrior spell an Arms Warrior learns from level 1 to 60 in WoW: Forever.
-- Fields: key (text id stem), name (English client name, also used to resolve the highest rank), id (rank 1 spell id),
-- level (first available), role (tank | heal | damage | support), use (group | solo | both), talent (learned through
-- the talent tree; level = when the Mobalytics leveling path takes it), races (a racial: the race ids of its race
-- mask in the client dump; other races never see it, ns.BuildLayout L.gated), src (a key in P.sources or the core's
-- sources), verified.
-- What/when texts live in this pack's Locales as spell.<key>.what / spell.<key>.when (English only).
-- Spec: research/warrior-arms.md part 1 (approved with commit b01744e's answers). Left out on purpose: Victory Rush
-- 402927 and Commanding Shout 403215 (in the dump, but only from a Season of Discovery rune; part 1.5), the Vanguard
-- Charge 1240287 (a Protection talent override), and the talent buttons the Arms path doesn't take.
local _, P = ...

-- Sources of this pack's data (the core merges them into its own list while the pack is active).
P.sources = {
  simc = "simc-forever SpellDataDump, client 1.60.1.70862 (github.com/simulationcraft/simc-forever @3c1d319e, SpellDataDump/warrior.txt)",
  simc_race = "simc-forever SpellDataDump, client 1.60.1.70862 (github.com/simulationcraft/simc-forever @3c1d319e, SpellDataDump/nonclass.txt: racials)",
  moba = "https://mobalytics.gg/wow-forever/classes/arms-warrior-guide",
}

local V = "2026-11-14"

local S = {}
P.spells = S

local function add(t)
  t.verified = t.verified or V
  table.insert(S, t)
end

add { key = "battle_stance",      name = "Battle Stance",      id = 2457,    level = 1,  role = "damage",  use = "both",  src = "simc" }
add { key = "heroic_strike",      name = "Heroic Strike",      id = 78,      level = 1,  role = "damage",  use = "both",  src = "simc" }
add { key = "battle_shout",       name = "Battle Shout",       id = 6673,    level = 1,  role = "support", use = "both",  src = "simc" }
add { key = "charge",             name = "Charge",             id = 100,     level = 4,  role = "damage",  use = "both",  src = "simc" }
add { key = "rend",               name = "Rend",               id = 772,     level = 4,  role = "damage",  use = "both",  src = "simc" }
add { key = "thunder_clap",       name = "Thunder Clap",       id = 6343,    level = 6,  role = "support", use = "group", src = "simc" }
add { key = "hamstring",          name = "Hamstring",          id = 1715,    level = 8,  role = "damage",  use = "both",  src = "simc" }
add { key = "defensive_stance",   name = "Defensive Stance",   id = 71,      level = 10, role = "tank",    use = "both",  src = "simc" }
add { key = "bloodrage",          name = "Bloodrage",          id = 2687,    level = 10, role = "damage",  use = "both",  src = "simc" }
add { key = "sunder_armor",       name = "Sunder Armor",       id = 7386,    level = 10, role = "damage",  use = "both",  src = "simc" }
add { key = "taunt",              name = "Taunt",              id = 355,     level = 10, role = "tank",    use = "group", src = "simc" }
add { key = "overpower",          name = "Overpower",          id = 7384,    level = 12, role = "damage",  use = "both",  src = "simc" }
add { key = "shield_bash",        name = "Shield Bash",        id = 72,      level = 12, role = "support", use = "both",  src = "simc" }
add { key = "demoralizing_shout", name = "Demoralizing Shout", id = 1160,    level = 14, role = "support", use = "group", src = "simc" }
add { key = "revenge",            name = "Revenge",            id = 6572,    level = 14, role = "tank",    use = "group", src = "simc" }
add { key = "shield_block",       name = "Shield Block",       id = 2565,    level = 16, role = "tank",    use = "both",  src = "simc" }
add { key = "mocking_blow",       name = "Mocking Blow",       id = 694,     level = 16, role = "tank",    use = "group", src = "simc" }
add { key = "disarm",             name = "Disarm",             id = 676,     level = 18, role = "support", use = "both",  src = "simc" }
add { key = "cleave",             name = "Cleave",             id = 845,     level = 20, role = "damage",  use = "both",  src = "simc" }
add { key = "retaliation",        name = "Retaliation",        id = 20230,   level = 20, role = "damage",  use = "both",  src = "simc" }
add { key = "slam",               name = "Slam",               id = 1240193, level = 20, role = "damage",  use = "both",  src = "simc" }
add { key = "intimidating_shout", name = "Intimidating Shout", id = 5246,    level = 22, role = "support", use = "solo",  src = "simc" }
add { key = "execute",            name = "Execute",            id = 5308,    level = 24, role = "damage",  use = "both",  src = "simc" }
add { key = "challenging_shout",  name = "Challenging Shout",  id = 1161,    level = 26, role = "tank",    use = "group", src = "simc" }
add { key = "shield_wall",        name = "Shield Wall",        id = 871,     level = 28, role = "tank",    use = "both",  src = "simc" }
add { key = "spearing_strike",    name = "Spearing Strike",    id = 1310222, level = 28, role = "damage",  use = "both",  src = "simc", talent = true }
add { key = "sweeping_strikes",   name = "Sweeping Strikes",   id = 12292,   level = 29, role = "damage",  use = "both",  src = "simc", talent = true }
add { key = "berserker_stance",   name = "Berserker Stance",   id = 2458,    level = 30, role = "damage",  use = "both",  src = "simc" }
add { key = "berserker_rage",     name = "Berserker Rage",     id = 18499,   level = 30, role = "damage",  use = "both",  src = "simc" }
add { key = "intercept",          name = "Intercept",          id = 20252,   level = 30, role = "damage",  use = "both",  src = "simc" }
add { key = "whirlwind",          name = "Whirlwind",          id = 1680,    level = 36, role = "damage",  use = "both",  src = "simc" }
add { key = "pummel",             name = "Pummel",             id = 6552,    level = 38, role = "support", use = "both",  src = "simc" }
add { key = "mortal_strike",      name = "Mortal Strike",      id = 12294,   level = 39, role = "damage",  use = "both",  src = "simc", talent = true }
add { key = "recklessness",       name = "Recklessness",       id = 1719,    level = 50, role = "damage",  use = "both",  src = "simc" }
add { key = "reckless_swings",    name = "Reckless Swings",    id = 1329555, level = 56, role = "damage",  use = "both",  src = "simc", talent = true }

-- Tauren racials (simc_race, nonclass.txt): the race mask's bit n is race id n + 1; Tauren is race id 6 (0x20). Known
-- from level 1, not from the trainer. Endurance and Plainsrunning are passive (a guide line only).
add { key = "war_stomp",          name = "War Stomp",          id = 20549,   level = 1,  role = "support", use = "both",  src = "simc_race", races = { 6 } }
add { key = "cultivation",        name = "Cultivation",        id = 20552,   level = 1,  role = "support", use = "both",  src = "simc_race", races = { 6 } }
