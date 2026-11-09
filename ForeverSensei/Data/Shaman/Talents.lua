-- Data/Shaman/Talents.lua: talents used by the Restoration build and the order to take them.
-- Forever uses one class tree: Elemental columns 1-4, Enhancement 5-8, Restoration 9-12; row r needs 5*(r-1)
-- points spent (simc dump: tree=class, row, col, max_rank). Order: Mobalytics Restoration Shaman leveling path
-- (final 0/5/46). Reasons are talent.<key>.why in Locales.
local _, ns = ...
local V = "2026-11-09"

local T = {}
ns.ClassData.SHAMAN.talents = T

T.list = {
  { key = "improved_healing_wave", name = "Improved Healing Wave", id = 16182,   tree = "Restoration", row = 1, col = 10, max = 5 },
  { key = "tidal_focus",           name = "Tidal Focus",           id = 16179,   tree = "Restoration", row = 1, col = 11, max = 5 },
  { key = "mindfulness",           name = "Mindfulness",           id = 1223033, tree = "Restoration", row = 2, col = 9,  max = 3 },
  { key = "totemic_focus",         name = "Totemic Focus",         id = 16173,   tree = "Restoration", row = 2, col = 11, max = 5 },
  { key = "ancestral_healing",     name = "Ancestral Healing",     id = 16176,   tree = "Restoration", row = 3, col = 9,  max = 3 },
  { key = "healing_focus",         name = "Healing Focus",         id = 16181,   tree = "Restoration", row = 3, col = 10, max = 3 },
  { key = "water_shield",          name = "Water Shield",          id = 408510,  tree = "Restoration", row = 3, col = 11, max = 1 },
  { key = "tidal_mastery",         name = "Tidal Mastery",         id = 16194,   tree = "Restoration", row = 4, col = 9,  max = 5 },
  { key = "restorative_totems",    name = "Restorative Totems",    id = 16187,   tree = "Restoration", row = 4, col = 10, max = 5 },
  { key = "mana_tide_totem",       name = "Mana Tide Totem",       id = 16190,   tree = "Restoration", row = 4, col = 11, max = 1 },
  { key = "healing_way",           name = "Healing Way",           id = 29206,   tree = "Restoration", row = 5, col = 10, max = 3 },
  { key = "natures_swiftness",     name = "Nature's Swiftness",    id = 16188,   tree = "Restoration", row = 5, col = 11, max = 1 },
  { key = "purification",          name = "Purification",          id = 16178,   tree = "Restoration", row = 6, col = 11, max = 5 },
  { key = "riptide",               name = "Riptide",               id = 408521,  tree = "Restoration", row = 7, col = 10, max = 1, requires = "healing_way" },
  { key = "ancestral_knowledge",   name = "Ancestral Knowledge",   id = 17485,   tree = "Enhancement", row = 1, col = 7,  max = 5 },
}
T.byKey = {}
for _, t in ipairs(T.list) do
  t.src, t.verified = "simc", V
  T.byKey[t.key] = t
end

-- Mobalytics leveling path: { talent, first level, last level }. One point per level from 10 to 60.
T.path = {
  { "improved_healing_wave", 10, 14 },
  { "mindfulness",           15, 17 },
  { "tidal_focus",           18, 19 },
  { "water_shield",          20, 20 },
  { "tidal_focus",           21, 23 },
  { "ancestral_healing",     24, 24 },
  { "mana_tide_totem",       25, 25 },
  { "healing_focus",         26, 28 },
  { "ancestral_healing",     29, 29 },
  { "natures_swiftness",     30, 30 },
  { "healing_way",           31, 33 },
  { "ancestral_healing",     34, 34 },
  { "purification",          35, 39 },
  { "riptide",               40, 40 },
  { "tidal_mastery",         41, 45 },
  { "totemic_focus",         46, 50 },
  { "restorative_totems",    51, 55 },
  { "ancestral_knowledge",   56, 60 },
}
T.pathSource = { src = "moba", verified = V }

-- Expanded order: T.order[n] = { key, rank (after this point), level }
T.order = {}
do
  local ranks = {}
  for _, step in ipairs(T.path) do
    local key, first, last = step[1], step[2], step[3]
    for level = first, last do
      ranks[key] = (ranks[key] or 0) + 1
      table.insert(T.order, { key = key, rank = ranks[key], level = level })
    end
  end
end
