-- Data/Shaman/Layout.lua: the fixed slot and key plan (layout version 2, ForeverSensei 0.3.0).
-- Keys are limited to 1-5, Q, E, R, F, Z, X, C and their Shift variants (small hands, WASD movement).
-- Healing first, from the player's feedback: the heals sit on the keys that are easiest to reach next to WASD.
-- Main bar (no modifier):
--   heals   F Healing Wave, C Lesser Healing Wave, R Chain Heal, E Riptide, X Nature's Swiftness
--   shields 1 Water Shield, 2 Lightning Shield
--   damage  3 Lightning Bolt, 4 Flame Shock, 5 Earth Shock, Q Chain Lightning
--   Z       the best Mana Potion in the bags (item macro FS_MANA)
-- Action Bar 2 sits right above the main bar and uses Shift + the same key in the same column. Every keyed totem is
-- here. The totems placed at every pull get the easiest Shift keys: Shift+E Stoneskin (less physical damage for the
-- party), Shift+R Searing, Shift+F Tremor (removes Sleep, Fear and Charm), Shift+C Call of the Elements.
--   Shift+Q Healing Stream (the Water totem for a pull, next to Stoneskin and Searing)
--   Shift+Z Mana Spring and Shift+X Mana Tide: the mana totems, Shift+Z above the Mana Potion on Z
--   Shift+1 Cure Poison, Shift+2 Cure Disease, Shift+3 Purge: dispels on the number row, above the shields
--   Shift+4 Frost Shock (above Flame Shock), Shift+5 Earthbind: the slows, used when an enemy runs or chases
-- Moved to clickable bars because 12 Shift keys are not enough: Strength of Earth (an Earth totem like Stoneskin;
-- only one Earth totem can be down, and the player puts Stoneskin down), Fire Nova (area damage, rare for a healer)
-- and Ghost Wolf (travel, out of combat, no hurry).
-- Action Bars 3, 4 and 5 hold clickable, unkeyed buttons. Bar 3: weapon imbues, then the long buffs and potions
-- (Arcane Elixir, Healing Potion macros) and the combat extras. Bar 4: out-of-combat spells and situational totems.
-- Bar 5: the 3-second multi-totem calls and spare buttons (things that were on a planned slot move there first).
-- Slot numbers: slot = (page - 1) * 12 + button; pages from Blizzard_ActionBar MultiActionBars.xml (Forever 1.60.1):
-- MultiBarBottomLeft page 6 (61-72), MultiBarBottomRight page 5 (49-60), MultiBarRight page 3 (25-36),
-- MultiBarLeft page 4 (37-48, shown with the setting PROXY_SHOW_ACTIONBAR_5).
-- Plan entries starting with "@" are item macros (Data/Items.lua kinds), not spells.
local _, ns = ...

local L = {}
ns.ClassData.SHAMAN.layout = L

L.bars = {
  { id = "main", first = 1,  binding = "ACTIONBUTTON%d",          setting = nil },
  { id = "bar2", first = 61, binding = "MULTIACTIONBAR1BUTTON%d", setting = "PROXY_SHOW_ACTIONBAR_2" },
  { id = "bar3", first = 49, binding = "MULTIACTIONBAR2BUTTON%d", setting = "PROXY_SHOW_ACTIONBAR_3" },
  { id = "bar4", first = 25, binding = "MULTIACTIONBAR3BUTTON%d", setting = "PROXY_SHOW_ACTIONBAR_4" },
  { id = "bar5", first = 37, binding = "MULTIACTIONBAR4BUTTON%d", setting = "PROXY_SHOW_ACTIONBAR_5" },
}

-- Bumped when slots or keys change: players who had the older layout get a one-time notice (Modules/Layout.lua).
L.version = 2

L.allowedKeys = {
  "1", "2", "3", "4", "5", "Q", "E", "R", "F", "Z", "X", "C",
  "SHIFT-1", "SHIFT-2", "SHIFT-3", "SHIFT-4", "SHIFT-5",
  "SHIFT-Q", "SHIFT-E", "SHIFT-R", "SHIFT-F", "SHIFT-Z", "SHIFT-X", "SHIFT-C",
}

local KEYS = { "1", "2", "3", "4", "5", "Q", "E", "R", "F", "Z", "X", "C" }

-- One row of 12 per bar, button 1..12 left to right.
local plan = {
  main = {
    "water_shield", "lightning_shield", "lightning_bolt", "flame_shock", "earth_shock",
    "chain_lightning", "riptide", "chain_heal", "healing_wave",
    "@mana", "natures_swiftness", "lesser_healing_wave",
  },
  bar2 = {
    "cure_poison", "cure_disease", "purge", "frost_shock", "earthbind_totem",
    "healing_stream_totem", "stoneskin_totem", "searing_totem", "tremor_totem",
    "mana_spring_totem", "mana_tide_totem", "call_of_the_elements",
  },
  bar3 = {
    "rockbiter_weapon", "flametongue_weapon", "frostbrand_weapon", "windfury_weapon",
    "@elixir", "@healpot", "strength_of_earth_totem", "stoneclaw_totem",
    "grounding_totem", "fire_nova", "totemic_recall", "ghost_wolf",
  },
  bar4 = {
    "ancestral_spirit", "astral_recall", "water_walking", "water_breathing", "far_sight", "windfury_totem",
    "grace_of_air_totem", "magma_totem", "poison_cleansing_totem", "disease_cleansing_totem",
    "flametongue_totem", "sentry_totem",
  },
  bar5 = {
    "totemic_call", "call_of_the_ancestors", "call_of_the_spirits",
  },
}

-- Spells without a bar slot: resistance totems and Windwall are situational (Totem Bar or spellbook);
-- Reincarnation is passive.
L.noSlot = {
  frost_resistance_totem = "totembar",
  fire_resistance_totem = "totembar",
  nature_resistance_totem = "totembar",
  windwall_totem = "totembar",
  reincarnation = "passive",
}

-- Helpful spells that become mouseover macros in "mouseover" targeting mode.
L.macros = {
  healing_wave = "FS_HW",
  lesser_healing_wave = "FS_LHW",
  chain_heal = "FS_CH",
  riptide = "FS_RT",
  cure_poison = "FS_CP",
  cure_disease = "FS_CD",
}
-- Format from the Mobalytics guide's mouseover macro: mouseover friend, else friendly target, else yourself.
L.macroBody = "#showtooltip {spell}\n/cast [@mouseover,help,nodead][help,nodead][@player] {spell}"

L.slots = {}
L.bySpell = {}
L.byItem = {}
L.spare = {} -- unplanned buttons on the planned bars: first choice for things moved out of a planned slot
for _, bar in ipairs(L.bars) do
  for i, what in ipairs(plan[bar.id]) do
    local key
    if bar.id == "main" then key = KEYS[i] elseif bar.id == "bar2" then key = "SHIFT-" .. KEYS[i] end
    local item = what:match("^@(%w+)$")
    local slot = {
      bar = bar.id,
      button = i,
      slot = bar.first + i - 1,
      key = key,
      binding = key and string.format(bar.binding, i) or nil,
      spell = not item and what or nil,
      item = item,
    }
    table.insert(L.slots, slot)
    if item then L.byItem[item] = slot else L.bySpell[what] = slot end
  end
  for i = #plan[bar.id] + 1, 12 do
    table.insert(L.spare, { bar = bar.id, button = i, slot = bar.first + i - 1 })
  end
end

-- "SHIFT-Q" → "Shift+Q"
function L.KeyLabel(key)
  if not key then return nil end
  return (key:gsub("^SHIFT%-", "Shift+"))
end
