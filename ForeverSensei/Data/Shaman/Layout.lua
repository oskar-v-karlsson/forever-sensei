-- Data/Shaman/Layout.lua: the fixed slot and key plan (layout version 4, ForeverSensei 0.4.1).
-- Spec: research/keybind-layout.md (approved). The level-60 dungeon-healer layout comes first; lower levels use a
-- subset of it, and a key never moves once its spell is learned (a reserved key stays empty until then).
-- Rules from the pull walkthroughs in the spec:
-- * The spells pressed in most level-60 pulls get the top keys (1-3, Q, E, R, F, Mouse4/5, Shift+Q/E/R/F).
-- * Every heal is a key without a modifier: F Healing Wave, E Lesser Healing Wave, R Chain Heal (40),
--   Mouse4 Riptide (40), Mouse5 Nature's Swiftness + Healing Wave in one press (30).
-- * A family (spells for the same job) shares one base key with plain, Shift and Ctrl variants; the most used member
--   gets the easiest variant. A rare spell never takes a plain top key.
--     1      moving totems: Totemic Call (every pull) / Call of the Elements (when the 5-minute totems run out,
--            after a wipe) / Totemic Recall (when leaving)
--     Q      stop an enemy: Earth Shock interrupt / Frost Shock (a runner) / Earthbind Totem (several)
--     Z      mana: Mana Potion / Mana Spring Totem / Mana Tide Totem
--     Mouse4 help the player under the cursor: Riptide / Cure Poison / Poison Cleansing Totem
--     Mouse5 the same: NS + Healing Wave / Cure Disease / Disease Cleansing Totem
--     E, F   Shift and Ctrl hold the totems against physical damage (Stoneskin, Stoneclaw) and against enemy spells
--            (Tremor, Grounding); Shift+E Stoneskin, Shift+R Searing and Shift+F Tremor are the player's habit.
--     2-4    the damage row, pressed left to right: Flame Shock, Lightning Bolt, Chain Lightning (32).
-- * X Water Shield (refreshed between pulls; Lightning Shield stands in on X until Water Shield at 20, then moves to
--   a clickable bar), C Healthstone else Healing Potion (FS_HEALTH, next to the Mana Potion), Shift+3 Purge,
--   Ctrl+C Ghost Wolf (the player's decision).
-- * 5, Shift+5 and Ctrl+5 belong to the player: never planned, never bound, never cleared.
-- * Spare: Shift+2, Shift+4, Shift+X, Shift+C (bound to their empty buttons). Ctrl+2-4, Ctrl+R, Ctrl+X and Ctrl+5
--   are not bound, so they keep their defaults (Ctrl+2-5 stance bar, Ctrl+R probably the framerate display).
-- Bars (Blizzard_ActionBar in the Forever UI code; slot = (page - 1) * 12 + button):
--   plain = main bar ACTIONBUTTON (1-12); Shift = Action Bar 2 MULTIACTIONBAR1BUTTON (page 6, 61-72);
--   Ctrl and mouse = Action Bar 5 MULTIACTIONBAR4BUTTON (MultiBarLeft, page 4, 37-48, at the right edge of the
--   screen): buttons 1-6 Ctrl+1, Ctrl+Q, Ctrl+E, Ctrl+F, Ctrl+Z, Ctrl+C; buttons 7-12 Mouse4, Mouse5, Shift+Mouse4,
--   Shift+Mouse5, Ctrl+Mouse4, Ctrl+Mouse5 (key strings BUTTON4/BUTTON5, Blizzard_FrameXML/BindingUtil). A key can be
--   bound to any button, so the 12 Ctrl and mouse spells share one bar that is shown anyway.
--   Layout 3 (0.4.0) used Action Bars 6 and 7 for them; those bars sat in the middle of the screen, so the player did
--   not want them. The addon never turns them on again: a full apply clears layout 3's spells there, hides both
--   bars and unbinds keys that still point at them (L.retired).
--   Action Bars 3 (page 5, 49-60) and 4 (page 3, 25-36) hold the clickable, unkeyed buttons: bar 3 weapon imbues,
--   long buffs and potions; bar 4 out-of-combat spells, situational totems and the extra Totem Bar presets.
--   Things moved out of a planned slot go to the spare buttons (bar 3, then bar 2) first.
-- Plan entries: a spell key; "@kind" an item macro (Data/Items.lua); "-" a spare button; "#" the player's own button.
local _, ns = ...

local L = {}
ns.ClassData.SHAMAN.layout = L

-- Display order (the guide's key page). keys: the key of each button, nil = no key.
local KEYS = { "1", "2", "3", "4", "5", "Q", "E", "R", "F", "Z", "X", "C" }
local function withMod(mod)
  local list = {}
  for i, k in ipairs(KEYS) do list[i] = mod .. k end
  return list
end
L.bars = {
  { id = "main", first = 1,   binding = "ACTIONBUTTON%d",          setting = nil,                      keys = KEYS },
  { id = "bar2", first = 61,  binding = "MULTIACTIONBAR1BUTTON%d", setting = "PROXY_SHOW_ACTIONBAR_2", keys = withMod("SHIFT-") },
  { id = "bar5", first = 37,  binding = "MULTIACTIONBAR4BUTTON%d", setting = "PROXY_SHOW_ACTIONBAR_5",
    keys = { "CTRL-1", "CTRL-Q", "CTRL-E", "CTRL-F", "CTRL-Z", "CTRL-C",
      "BUTTON4", "BUTTON5", "SHIFT-BUTTON4", "SHIFT-BUTTON5", "CTRL-BUTTON4", "CTRL-BUTTON5" } },
  { id = "bar3", first = 49,  binding = "MULTIACTIONBAR2BUTTON%d", setting = "PROXY_SHOW_ACTIONBAR_3" },
  { id = "bar4", first = 25,  binding = "MULTIACTIONBAR3BUTTON%d", setting = "PROXY_SHOW_ACTIONBAR_4" },
}

-- Bars the addon no longer uses (layout 3 put the Ctrl and mouse spells there). A full apply hides them, clears the
-- plan's spells from them and unbinds keys bound to their buttons; the clean-up button empties them. own: layout 3's
-- Ctrl+5 button (the player's), which a full apply leaves alone.
L.retired = {
  { id = "bar6", first = 145, binding = "MULTIACTIONBAR5BUTTON%d", setting = "PROXY_SHOW_ACTIONBAR_6", own = 5 },
  { id = "bar7", first = 157, binding = "MULTIACTIONBAR6BUTTON%d", setting = "PROXY_SHOW_ACTIONBAR_7" },
}

-- Bumped when slots or keys change: players who had the older layout get a one-time notice (Modules/Layout.lua).
L.version = 4

-- Every key the plan binds. Only planned buttons get a key.
L.allowedKeys = {
  "1", "2", "3", "4", "Q", "E", "R", "F", "Z", "X", "C",
  "SHIFT-1", "SHIFT-3", "SHIFT-Q", "SHIFT-E", "SHIFT-R", "SHIFT-F", "SHIFT-Z",
  "CTRL-1", "CTRL-Q", "CTRL-E", "CTRL-F", "CTRL-Z", "CTRL-C",
  "BUTTON4", "BUTTON5", "SHIFT-BUTTON4", "SHIFT-BUTTON5", "CTRL-BUTTON4", "CTRL-BUTTON5",
}

-- The player's own keys and buttons: the addon never binds these keys and never changes these slots.
L.ownKeys = { "5", "SHIFT-5", "CTRL-5" }

-- One row per bar, button 1..12 left to right.
local plan = {
  main = {
    "totemic_call", "flame_shock", "lightning_bolt", "chain_lightning", "#",
    "earth_shock", "lesser_healing_wave", "chain_heal", "healing_wave",
    "@mana", { "water_shield", standIn = "lightning_shield" }, "@health",
  },
  bar2 = {
    "call_of_the_elements", "-", "purge", "-", "#",
    "frost_shock", "stoneskin_totem", "searing_totem", "tremor_totem",
    "mana_spring_totem", "-", "-",
  },
  bar5 = {
    "totemic_recall", "earthbind_totem", "stoneclaw_totem", "grounding_totem", "mana_tide_totem", "ghost_wolf",
    "riptide", "natures_swiftness", "cure_poison", "cure_disease", "poison_cleansing_totem", "disease_cleansing_totem",
  },
  bar3 = {
    "rockbiter_weapon", "flametongue_weapon", "frostbrand_weapon", "windfury_weapon",
    "@elixir", "@healpot", "strength_of_earth_totem", "healing_stream_totem",
    { "lightning_shield", after = "water_shield" }, "fire_nova",
  },
  bar4 = {
    "ancestral_spirit", "astral_recall", "water_walking", "water_breathing", "far_sight", "windfury_totem",
    "grace_of_air_totem", "magma_totem", "call_of_the_ancestors", "call_of_the_spirits", "flametongue_totem",
    "sentry_totem",
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

-- Spells that become macros. In "click" targeting mode they are plain spells, except macroAlways ones.
L.macros = {
  healing_wave = "FS_HW",
  lesser_healing_wave = "FS_LHW",
  chain_heal = "FS_CH",
  riptide = "FS_RT",
  cure_poison = "FS_CP",
  cure_disease = "FS_CD",
  earth_shock = "FS_ES",
  purge = "FS_PURGE",
  natures_swiftness = "FS_NSHW",
}
-- Macro kind per spell (default "help").
L.macroKind = {
  earth_shock = "interrupt",
  purge = "harm",
  natures_swiftness = "nshw",
}
-- Always macros, also in click mode (then they use the "<kind>_click" body): Nature's Swiftness is the one-press
-- NS + Healing Wave macro, and Earth Shock stops your own cast first so the interrupt goes off at once.
L.macroAlways = { natures_swiftness = true, earth_shock = true }
-- {spell} = the spell (with a rank when needed), {heal} = Healing Wave as its own macro names it.
-- help: the Mobalytics guide's mouseover macro (mouseover friend, else friendly target, else yourself).
-- nshw: #showtooltip shows Nature's Swiftness, so the button shows its 3-minute cooldown. While it is on cooldown
-- the first /cast fails and the press casts a normal Healing Wave.
L.macroBodies = {
  help = "#showtooltip {spell}\n/cast [@mouseover,help,nodead][help,nodead][@player] {spell}",
  harm = "#showtooltip {spell}\n/cast [@mouseover,harm,nodead][] {spell}",
  interrupt = "#showtooltip {spell}\n/stopcasting\n/cast [@mouseover,harm,nodead][] {spell}",
  interrupt_click = "#showtooltip {spell}\n/stopcasting\n/cast {spell}",
  nshw = "#showtooltip {spell}\n/cast {spell}\n/cast [@mouseover,help,nodead][help,nodead][@player] {heal}",
  nshw_click = "#showtooltip {spell}\n/cast {spell}\n/cast [help,nodead][@player] {heal}",
}

-- Layout 2 (0.3.0) put these spells in buttons that are spare now. A full apply clears such a button when it still
-- holds that spell and the spell has its new place, so no duplicates are left (undoable like everything else).
-- The player's own buttons 5 and Shift+5 (Earth Shock and Earthbind Totem in layout 2) are left alone.
L.old = {
  [59] = "totemic_recall",
  [60] = "ghost_wolf",
  [62] = "cure_disease",
  [64] = "frost_shock",
  [71] = "mana_tide_totem",
  [72] = "call_of_the_elements",
}

-- Keys whose default binding the preview explains (expected defaults, research/keybind-layout.md Q4).
L.defaultWarn = {
  ["CTRL-1"] = "ui.preview.warn.stance",
  ["CTRL-2"] = "ui.preview.warn.stance",
  ["CTRL-R"] = "ui.preview.warn.fps",
}

L.slots = {}
L.bySpell = {}
L.byItem = {}
L.own = {}   -- slot → true
L.spare = {} -- unplanned buttons: first choice for things moved out of a planned slot (bar 3 first)
local spareByBar = {}
for _, bar in ipairs(L.bars) do
  spareByBar[bar.id] = {}
  for i = 1, 12 do
    local what = plan[bar.id][i] or "-"
    local slotNo = bar.first + i - 1
    if what == "#" then
      L.own[slotNo] = true
    elseif what == "-" then
      table.insert(spareByBar[bar.id], { bar = bar.id, button = i, slot = slotNo })
    else
      local opts = type(what) == "table" and what or {}
      if type(what) == "table" then what = what[1] end
      local key = bar.keys and bar.keys[i]
      local item = what:match("^@(%w+)$")
      local slot = {
        bar = bar.id,
        button = i,
        slot = slotNo,
        key = key,
        binding = key and string.format(bar.binding, i) or nil,
        spell = not item and what or nil,
        item = item,
        standIn = opts.standIn,
        after = opts.after,
      }
      table.insert(L.slots, slot)
      if item then L.byItem[item] = slot else L.bySpell[what] = slot end
    end
  end
end
for _, id in ipairs({ "bar3", "bar4", "bar5", "bar2" }) do
  for _, s in ipairs(spareByBar[id]) do table.insert(L.spare, s) end
end

-- "SHIFT-Q" → "Shift+Q", "CTRL-BUTTON4" → "Ctrl+Mouse 4"
function L.KeyLabel(key)
  if not key then return nil end
  local label = key:gsub("^SHIFT%-", "Shift+"):gsub("^CTRL%-", "Ctrl+")
  label = label:gsub("BUTTON(%d)$", function(n) return ns.T("ui.key.mouse", { n = n }) end)
  return label
end
