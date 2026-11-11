-- ForeverSensei_Paladin/Data/Protection/Talents.lua: talents used by the Protection build and the order to take them.
-- Forever uses one class tree: Holy columns 1-4, Protection 5-8, Retribution 9-12; row r needs 5*(r-1) points spent
-- (simc dump: tree=class, row, col, max_rank). Order: the Wowhead Forever Protection Paladin leveling guide's
-- "Talent Order" (Riyani, updated 2026-11-06; final 0/32/19). Reasons are talent.<key>.why in this pack's Locales.
-- The core builds T.byKey and the expanded T.order (ns.BuildTalents in ForeverSensei/Core/Class.lua).
local _, P = ...
local V = "2026-11-11"
P.specs = P.specs or {}
P.specs.PROTECTION = P.specs.PROTECTION or {}
local spec = P.specs.PROTECTION

local T = {}
spec.talents = T

T.list = {
  { key = "benediction",             name = "Benediction",             id = 20101,   tree = "Retribution", row = 1, col = 11, max = 5 },
  { key = "sanctified_judgement",    name = "Sanctified Judgement",    id = 1311074, tree = "Retribution", row = 2, col = 11, max = 3 },
  { key = "conviction",              name = "Conviction",              id = 20117,   tree = "Retribution", row = 2, col = 10, max = 3 },
  { key = "pursuit_of_justice",      name = "Pursuit of Justice",      id = 26022,   tree = "Retribution", row = 3, col = 12, max = 2 },
  { key = "redoubt",                 name = "Redoubt",                 id = 20127,   tree = "Protection",  row = 1, col = 7,  max = 5 },
  { key = "precision",               name = "Precision",               id = 20189,   tree = "Protection",  row = 2, col = 5,  max = 3 },
  { key = "guardians_favor",         name = "Guardian's Favor",        id = 20174,   tree = "Protection",  row = 2, col = 6,  max = 2 },
  { key = "templars_bulwark",        name = "Templar's Bulwark",       id = 1311015, tree = "Protection",  row = 3, col = 5,  max = 1 },
  { key = "shield_specialization",   name = "Shield Specialization",   id = 20150,   tree = "Protection",  row = 3, col = 7,  max = 2 },
  { key = "toughness",               name = "Toughness",               id = 20143,   tree = "Protection",  row = 3, col = 8,  max = 5 },
  { key = "swift_judgement",         name = "Swift Judgement",         id = 1310994, tree = "Protection",  row = 4, col = 5,  max = 1 },
  { key = "improved_righteous_fury", name = "Improved Righteous Fury", id = 20468,   tree = "Protection",  row = 4, col = 6,  max = 3 },
  { key = "holy_shield",             name = "Holy Shield",             id = 20925,   tree = "Protection",  row = 5, col = 6,  max = 1 },
  { key = "reckoning",               name = "Reckoning",               id = 20177,   tree = "Protection",  row = 5, col = 7,  max = 5 },
  { key = "iron_creed",              name = "Iron Creed",              id = 1311034, tree = "Protection",  row = 6, col = 7,  max = 3 },
  { key = "sacred_duty",             name = "Sacred Duty",             id = 1224697, tree = "Protection",  row = 2, col = 8,  max = 2 },
  { key = "shieldsworn",             name = "Shieldsworn",             id = 1328544, tree = "Protection",  row = 7, col = 6,  max = 1 },
  { key = "improved_judgement",      name = "Improved Judgement",      id = 25956,   tree = "Retribution", row = 2, col = 9,  max = 2 },
  { key = "vindication",             name = "Vindication",             id = 9452,    tree = "Retribution", row = 3, col = 9,  max = 3 },
  { key = "sacred_arbiter",          name = "Sacred Arbiter",          id = 1311087, tree = "Retribution", row = 4, col = 10, max = 1 },
}
for _, t in ipairs(T.list) do
  t.src, t.verified = "simc", V
end

-- Wowhead leveling path: { talent, first level, last level }. One point per level from 10 to 60.
T.path = {
  { "benediction",             10, 14 },
  { "sanctified_judgement",    15, 17 },
  { "conviction",              18, 19 },
  { "pursuit_of_justice",      20, 21 },
  { "redoubt",                 22, 26 },
  { "precision",               27, 29 },
  { "guardians_favor",         30, 31 },
  { "templars_bulwark",        32, 32 },
  { "shield_specialization",   33, 34 },
  { "toughness",               35, 36 },
  { "swift_judgement",         37, 37 },
  { "improved_righteous_fury", 38, 40 },
  { "toughness",               41, 41 },
  { "holy_shield",             42, 42 },
  { "reckoning",               43, 47 },
  { "iron_creed",              48, 50 },
  { "sacred_duty",             51, 51 },
  { "shieldsworn",             52, 52 },
  { "improved_judgement",      53, 54 },
  { "vindication",             55, 55 },
  { "sacred_arbiter",          56, 56 },
  { "vindication",             57, 58 },
  { "conviction",              59, 59 },
  { "sacred_duty",             60, 60 },
}
T.pathSource = { src = "wh_guide", verified = V }
-- Shown under the talent order on the guide's Talents tab.
T.sources = { "wh_guide", "moba", "simc" }
T.notes = { "talent.note.order", "talent.note.moba" }
