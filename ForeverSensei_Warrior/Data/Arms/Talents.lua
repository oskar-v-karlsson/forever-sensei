-- ForeverSensei_Warrior/Data/Arms/Talents.lua: talents used by the Arms build and the order to take them.
-- Forever uses one class tree: Arms columns 1-4, Fury 5-8, Protection 9-12 (simc dump: tree=class, row, col,
-- max_rank). Order: the Mobalytics Arms Warrior guide's leveling path, followed exactly as written (Ahlaundoh, updated
-- 2026-11-12; final 32/18/1, Enrage over Lingering Rage). Reasons are talent.<key>.why in this pack's Locales.
-- requires = the prerequisite arrow on Mobalytics' tree picture (the dump has no prerequisite field).
-- noRowGate: the path takes Deep Wounds (row 3) at level 18 with 8 points spent, so Forever's point gates are not
-- 5 per row; the dump lists req_points 0 for every talent here (research/warrior-arms.md 1.2). The tree's real gates
-- are an in-game check.
-- The core builds T.byKey and the expanded T.order (ns.BuildTalents in ForeverSensei/Core/Class.lua).
local _, P = ...
local V = "2026-11-14"
P.specs = P.specs or {}
P.specs.ARMS = P.specs.ARMS or {}
local spec = P.specs.ARMS

local T = {}
spec.talents = T

T.list = {
  { key = "improved_rend",              name = "Improved Rend",                    id = 12286,   tree = "Arms",       row = 1, col = 3, max = 3 },
  { key = "improved_heroic_strike",     name = "Improved Heroic Strike",           id = 12282,   tree = "Arms",       row = 1, col = 1, max = 3 },
  { key = "improved_overpower",         name = "Improved Overpower",               id = 12290,   tree = "Arms",       row = 2, col = 4, max = 2 },
  { key = "improved_tactical_mastery",  name = "Improved Tactical Mastery",        id = 12295,   tree = "Arms",       row = 2, col = 2, max = 3 },
  { key = "deep_wounds",                name = "Deep Wounds",                      id = 12834,   tree = "Arms",       row = 3, col = 3, max = 3, requires = "improved_rend" },
  { key = "impale",                     name = "Impale",                           id = 16493,   tree = "Arms",       row = 4, col = 3, max = 2, requires = "deep_wounds" },
  { key = "two_handed_specialization",  name = "Two-Handed Weapon Specialization", id = 12163,   tree = "Arms",       row = 4, col = 2, max = 3 },
  { key = "spearing_strike",            name = "Spearing Strike",                  id = 1310222, tree = "Arms",       row = 4, col = 1, max = 1 },
  { key = "sweeping_strikes",           name = "Sweeping Strikes",                 id = 12292,   tree = "Arms",       row = 5, col = 2, max = 1 },
  { key = "bloodthrill",                name = "Bloodthrill",                      id = 1289682, tree = "Arms",       row = 5, col = 1, max = 2 },
  { key = "weaponmaster",               name = "Weaponmaster",                     id = 1290261, tree = "Arms",       row = 5, col = 3, max = 5 },
  { key = "improved_slam",              name = "Improved Slam",                    id = 12862,   tree = "Arms",       row = 6, col = 1, max = 2 },
  { key = "mortal_strike",              name = "Mortal Strike",                    id = 12294,   tree = "Arms",       row = 7, col = 2, max = 1, requires = "sweeping_strikes" },
  { key = "anger_management",           name = "Anger Management",                 id = 12296,   tree = "Arms",       row = 3, col = 2, max = 1, requires = "improved_tactical_mastery" },
  { key = "cruelty",                    name = "Cruelty",                          id = 12320,   tree = "Fury",       row = 1, col = 7, max = 5 },
  { key = "unbridled_wrath",            name = "Unbridled Wrath",                  id = 12322,   tree = "Fury",       row = 2, col = 7, max = 5 },
  { key = "enrage",                     name = "Enrage",                           id = 12317,   tree = "Fury",       row = 3, col = 8, max = 5 },
  { key = "reckless_swings",            name = "Reckless Swings",                  id = 1329555, tree = "Fury",       row = 4, col = 6, max = 1 },
  { key = "improved_bloodrage",         name = "Improved Bloodrage",               id = 12301,   tree = "Protection", row = 1, col = 9, max = 2 },
  { key = "improved_execute",           name = "Improved Execute",                 id = 20502,   tree = "Fury",       row = 4, col = 8, max = 2 },
}
for _, t in ipairs(T.list) do
  t.src, t.verified = "simc", V
end

-- Mobalytics leveling path: { talent, first level, last level }. One point per level from 10 to 60.
T.path = {
  { "improved_rend",             10, 12 },
  { "improved_heroic_strike",    13, 14 },
  { "improved_overpower",        15, 16 },
  { "improved_tactical_mastery", 17, 17 },
  { "deep_wounds",               18, 20 },
  { "improved_tactical_mastery", 21, 22 },
  { "impale",                    23, 24 },
  { "two_handed_specialization", 25, 27 },
  { "spearing_strike",           28, 28 },
  { "sweeping_strikes",          29, 29 },
  { "bloodthrill",               30, 31 },
  { "weaponmaster",              32, 36 },
  { "improved_slam",             37, 38 },
  { "mortal_strike",             39, 39 },
  { "anger_management",          40, 40 },
  { "cruelty",                   41, 45 },
  { "unbridled_wrath",           46, 50 },
  { "enrage",                    51, 55 },
  { "reckless_swings",           56, 56 },
  { "improved_bloodrage",        57, 57 },
  { "improved_heroic_strike",    58, 58 },
  { "improved_execute",          59, 60 },
}
T.noRowGate = true
T.pathSource = { src = "moba", verified = V }
-- Shown under the talent order on the guide's Talents tab.
T.sources = { "moba", "simc" }
T.notes = { "talent.note.order", "talent.note.enrage" }
