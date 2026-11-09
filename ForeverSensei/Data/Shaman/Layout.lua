-- Data/Shaman/Layout.lua: the fixed slot and key plan.
-- Keys are limited to 1-5, Q, E, R, F, Z, X, C and their Shift variants (small hands, WASD movement).
-- Main bar (no modifier): healing on 1-5, damage on Q E R F, shield/totem/call on Z X C.
-- Action bar 2 sits right above the main bar and uses Shift + the same key in the same column.
-- Action bars 3 and 4 hold clickable, unkeyed spells (weapon imbues, situational totems, out-of-combat spells).
-- Slot numbers: slot = (page - 1) * 12 + button; pages from Blizzard_ActionBar MultiActionBars.xml (Forever 1.60.1):
-- MultiBarBottomLeft page 6 (61-72), MultiBarBottomRight page 5 (49-60), MultiBarRight page 3 (25-36).
local _, ns = ...

local L = {}
ns.ClassData.SHAMAN.layout = L

L.bars = {
  { id = "main", first = 1,  binding = "ACTIONBUTTON%d",          setting = nil },
  { id = "bar2", first = 61, binding = "MULTIACTIONBAR1BUTTON%d", setting = "PROXY_SHOW_ACTIONBAR_2" },
  { id = "bar3", first = 49, binding = "MULTIACTIONBAR2BUTTON%d", setting = "PROXY_SHOW_ACTIONBAR_3" },
  { id = "bar4", first = 25, binding = "MULTIACTIONBAR3BUTTON%d", setting = "PROXY_SHOW_ACTIONBAR_4" },
}

L.allowedKeys = {
  "1", "2", "3", "4", "5", "Q", "E", "R", "F", "Z", "X", "C",
  "SHIFT-1", "SHIFT-2", "SHIFT-3", "SHIFT-4", "SHIFT-5",
  "SHIFT-Q", "SHIFT-E", "SHIFT-R", "SHIFT-F", "SHIFT-Z", "SHIFT-X", "SHIFT-C",
}

local KEYS = { "1", "2", "3", "4", "5", "Q", "E", "R", "F", "Z", "X", "C" }

-- One row of 12 per bar, button 1..12 left to right.
local plan = {
  main = {
    "healing_wave", "lesser_healing_wave", "chain_heal", "riptide", "natures_swiftness",
    "lightning_bolt", "earth_shock", "flame_shock", "chain_lightning",
    "water_shield", "healing_stream_totem", "call_of_the_elements",
  },
  bar2 = {
    "cure_poison", "cure_disease", "purge", "mana_tide_totem", "mana_spring_totem",
    "frost_shock", "searing_totem", "fire_nova", "earthbind_totem",
    "lightning_shield", "strength_of_earth_totem", "ghost_wolf",
  },
  bar3 = {
    "rockbiter_weapon", "flametongue_weapon", "frostbrand_weapon", "windfury_weapon",
    "stoneskin_totem", "stoneclaw_totem", "tremor_totem", "grounding_totem",
    "totemic_recall", "totemic_call", "call_of_the_ancestors", "call_of_the_spirits",
  },
  bar4 = {
    "ancestral_spirit", "astral_recall", "water_walking", "water_breathing", "far_sight", "windfury_totem",
    "grace_of_air_totem", "magma_totem", "poison_cleansing_totem", "disease_cleansing_totem",
    "flametongue_totem", "sentry_totem",
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
for _, bar in ipairs(L.bars) do
  for i, spell in ipairs(plan[bar.id]) do
    local key
    if bar.id == "main" then key = KEYS[i] elseif bar.id == "bar2" then key = "SHIFT-" .. KEYS[i] end
    local slot = {
      bar = bar.id,
      button = i,
      slot = bar.first + i - 1,
      key = key,
      binding = key and string.format(bar.binding, i) or nil,
      spell = spell,
    }
    table.insert(L.slots, slot)
    L.bySpell[spell] = slot
  end
end

-- "SHIFT-Q" → "Shift+Q"
function L.KeyLabel(key)
  if not key then return nil end
  return (key:gsub("^SHIFT%-", "Shift+"))
end
