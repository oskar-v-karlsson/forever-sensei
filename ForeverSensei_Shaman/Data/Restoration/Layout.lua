-- ForeverSensei_Shaman/Data/Restoration/Layout.lua: the fixed slot and key plan (layout version 8, since
-- ForeverSensei 0.8.1; "family blocks" since 0.7.0, layout 7). Spec: research/keybind-layout-v4.md (approved, commit 27b6754), which builds on
-- research/keybind-layout.md (pull walkthroughs, reach tiers for small hands). The level-60 dungeon-healer layout
-- comes first; lower levels use a subset of it, and a key never moves once its spell is learned (a reserved key stays
-- empty until then).
-- Rules (Oskar's decisions for v4):
-- * Each modifier row splits into three blocks of neighbouring keys: 1-5, Q/E/R/F and Z/X/C. A family (spells for
--   the same job) fills one block, so it sits together on the keyboard and, because button n is key n on bars 1-3,
--   on screen. Frequency only picks a family's row and block and its order inside the block.
-- * The plain row is the core rotation and stays usage-driven: 1-5 the enemy spells (Flame Shock, Lightning Bolt,
--   Chain Lightning, Purge, Frost Shock), Q Earth Shock (interrupt), E/R/F the heals (Lesser Healing Wave, Chain
--   Heal, Healing Wave), Z Mana Potion, X Water Shield (Lightning Shield stands in until 20, then moves to Action
--   Bar 4), C Healthstone else Healing Potion.
-- * Shift 1-5 totem calls (Totemic Call, Call of the Elements, Call of the Ancestors, Call of the Spirits, Totemic
--   Recall); Shift Q/E/R/F Fire (Flametongue Totem, Magma Totem, Searing Totem, Fire Nova: it only hits enemies near
--   the active Fire totem); Shift Z/X/C Water (Mana Spring, Mana Tide, Healing Stream).
-- * Ctrl 1-3 travel (Ghost Wolf, Water Walking, Water Breathing; Ctrl+4 and Ctrl+5 spare); Ctrl Q/E/R/F Earth
--   (Earthbind, Stoneclaw, Stoneskin, Tremor); Ctrl Z/X/C Air (Grounding, Windfury Totem, Grace of Air).
-- * Mouse pairs: Mouse4/5 Riptide and NS + Healing Wave; Shift the cures; Ctrl the cleansing totems.
-- * Layout 8 (0.8.1, Erika's request): the Skyborne racials. Walk on Air on the middle mouse button (BUTTON3, no
--   modifier; Shift and Ctrl+BUTTON3 stay unbound), Skysight clicked next to it. Both are race-gated (Data/Spells.lua
--   races): for other races their buttons are unbound spare buttons (ns.BuildLayout L.gated).
-- * No key is the player's own any more (5, Shift+5 and Ctrl+5 are planned like every other key). Spare keys (Ctrl+4,
--   Ctrl+5) are bound to their empty buttons, so every key of the three rows works the same way.
-- Bars (Blizzard_ActionBar in the Forever UI code; slot = (page - 1) * 12 + button):
--   plain = Action Bar 1 ACTIONBUTTON (1-12); Shift = Action Bar 2 MULTIACTIONBAR1BUTTON (61-72); Ctrl = Action Bar 3
--   MULTIACTIONBAR2BUTTON (49-60). All three sit at the bottom of the screen by default.
--   Action Bar 6 MULTIACTIONBAR5BUTTON (145-156, Bindings_Camelot.xml, MultiActionBars.xml) holds the six mouse keys
--   (buttons 1-6, pair by pair), the clicked spells used in combat (Strength of Earth, the healing potion) and the
--   Skyborne racials (button 9 Walk on Air on the middle mouse button, button 10 Skysight). It starts in the middle
--   of the screen; the guide tells the player to drag it down in Edit Mode.
--   Action Bar 4 MULTIACTIONBAR3BUTTON (25-36, right edge) holds only out-of-combat clicks: resurrection, Astral
--   Recall, weapon imbues, Lightning Shield, the elixir.
--   Action Bar 5 (37-48) left the plan in layout 7. Its visibility is left as the player has it; a full apply only
--   clears what earlier layouts put there (L.old) and the clean-up button empties the buttons layout 6 filled
--   (L.retired keepShown). Action Bar 7 (layout 3) stays retired: hidden and unbound.
--   Things moved out of a planned slot go to the spare buttons (bar 4, bar 6, then bar 3) first.
-- Plan entries: a spell key; "@kind" an item macro (ForeverSensei/Data/Items.lua); "-" a spare button. The core builds
-- L.slots, L.bySpell, L.byItem and L.spare from L.plan (ns.BuildLayout in ForeverSensei/Core/Class.lua).
local _, P = ...
P.specs = P.specs or {}
P.specs.RESTORATION = P.specs.RESTORATION or {}

local L = {}
P.specs.RESTORATION.layout = L

-- Display order (the guide's key page). keys: the key of each button, false/nil = no key.
local KEYS = { "1", "2", "3", "4", "5", "Q", "E", "R", "F", "Z", "X", "C" }
local function withMod(mod)
  local list = {}
  for i, k in ipairs(KEYS) do list[i] = mod .. k end
  return list
end
L.bars = {
  { id = "main", first = 1,   binding = "ACTIONBUTTON%d",          setting = nil,                      keys = KEYS },
  { id = "bar2", first = 61,  binding = "MULTIACTIONBAR1BUTTON%d", setting = "PROXY_SHOW_ACTIONBAR_2", keys = withMod("SHIFT-") },
  { id = "bar3", first = 49,  binding = "MULTIACTIONBAR2BUTTON%d", setting = "PROXY_SHOW_ACTIONBAR_3", keys = withMod("CTRL-") },
  -- editMode: the bar starts in the middle of the screen; the guide and the preview tell the player to move it.
  { id = "bar6", first = 145, binding = "MULTIACTIONBAR5BUTTON%d", setting = "PROXY_SHOW_ACTIONBAR_6", editMode = true,
    keys = { "BUTTON4", "BUTTON5", "SHIFT-BUTTON4", "SHIFT-BUTTON5", "CTRL-BUTTON4", "CTRL-BUTTON5",
      false, false, "BUTTON3", false, false, false } },
  { id = "bar4", first = 25,  binding = "MULTIACTIONBAR3BUTTON%d", setting = "PROXY_SHOW_ACTIONBAR_4" },
}

-- Bars the plan no longer uses. assigned: the buttons the last layout there filled, the only ones the clean-up
-- button empties. Action Bar 5 (layouts 4-6, the Ctrl bar until 0.6.1) stays as the player has it (keepShown); its
-- old spells are cleared through L.old. Action Bar 7 (layout 3, 0.4.0) is hidden by a full apply, which also clears
-- the plan's spells there and unbinds keys that still point at its buttons.
L.retired = {
  { id = "bar5", first = 37,  binding = "MULTIACTIONBAR4BUTTON%d", setting = "PROXY_SHOW_ACTIONBAR_5", keepShown = true,
    assigned = { 1, 6, 7, 8, 9, 10, 12 } },
  { id = "bar7", first = 157, binding = "MULTIACTIONBAR6BUTTON%d", setting = "PROXY_SHOW_ACTIONBAR_7",
    assigned = { 1, 2, 3, 4, 5, 6 } },
}

-- Bumped when slots or keys change: players who had the older layout get a one-time notice (Modules/Layout.lua).
L.version = 8

-- Every key the plan binds: the planned buttons' keys and the spare keyed buttons' keys.
L.allowedKeys = {
  "1", "2", "3", "4", "5", "Q", "E", "R", "F", "Z", "X", "C",
  "SHIFT-1", "SHIFT-2", "SHIFT-3", "SHIFT-4", "SHIFT-5", "SHIFT-Q", "SHIFT-E", "SHIFT-R", "SHIFT-F", "SHIFT-Z",
  "SHIFT-X", "SHIFT-C",
  "CTRL-1", "CTRL-2", "CTRL-3", "CTRL-4", "CTRL-5", "CTRL-Q", "CTRL-E", "CTRL-R", "CTRL-F", "CTRL-Z", "CTRL-X", "CTRL-C",
  "BUTTON4", "BUTTON5", "SHIFT-BUTTON4", "SHIFT-BUTTON5", "CTRL-BUTTON4", "CTRL-BUTTON5",
  "BUTTON3",
}

-- One row per bar, button 1..12 left to right (button n = key n on the keyed bars).
L.plan = {
  main = {
    "flame_shock", "lightning_bolt", "chain_lightning", "purge", "frost_shock",
    "earth_shock", "lesser_healing_wave", "chain_heal", "healing_wave",
    "@mana", { "water_shield", standIn = "lightning_shield" }, "@health",
  },
  bar2 = {
    "totemic_call", "call_of_the_elements", "call_of_the_ancestors", "call_of_the_spirits", "totemic_recall",
    "flametongue_totem", "magma_totem", "searing_totem", "fire_nova",
    "mana_spring_totem", "mana_tide_totem", "healing_stream_totem",
  },
  bar3 = {
    "ghost_wolf", "water_walking", "water_breathing", "-", "-",
    "earthbind_totem", "stoneclaw_totem", "stoneskin_totem", "tremor_totem",
    "grounding_totem", "windfury_totem", "grace_of_air_totem",
  },
  bar6 = {
    "riptide", "natures_swiftness", "cure_poison", "cure_disease", "poison_cleansing_totem", "disease_cleansing_totem",
    "strength_of_earth_totem", "@healpot", "walk_on_air", "skysight", "-", "-",
  },
  bar4 = {
    "ancestral_spirit", "astral_recall", "rockbiter_weapon", "flametongue_weapon", "frostbrand_weapon",
    "windfury_weapon", { "lightning_shield", after = "water_shield" }, "@elixir", "-", "-", "-", "-",
  },
}

-- Families (research/keybind-layout-v4.md S1/S2): each keyed family fills one block of one row, or one mouse pair;
-- spill-overs are clicked on Action Bar 6. tools/check.py checks the plan against this list.
L.families = {
  { id = "damage", block = "1-5", row = "", members = { "flame_shock", "lightning_bolt", "chain_lightning", "purge", "frost_shock" } },
  { id = "calls", block = "1-5", row = "SHIFT-",
    members = { "totemic_call", "call_of_the_elements", "call_of_the_ancestors", "call_of_the_spirits", "totemic_recall" } },
  { id = "fire", block = "QERF", row = "SHIFT-", members = { "flametongue_totem", "magma_totem", "searing_totem", "fire_nova" } },
  { id = "water", block = "ZXC", row = "SHIFT-", members = { "mana_spring_totem", "mana_tide_totem", "healing_stream_totem" } },
  { id = "travel", block = "1-5", row = "CTRL-", members = { "ghost_wolf", "water_walking", "water_breathing" } },
  { id = "earth", block = "QERF", row = "CTRL-", spill = { "strength_of_earth_totem" },
    members = { "earthbind_totem", "stoneclaw_totem", "stoneskin_totem", "tremor_totem" } },
  { id = "air", block = "ZXC", row = "CTRL-", members = { "grounding_totem", "windfury_totem", "grace_of_air_totem" } },
  { id = "cursorheals", block = "mouse", row = "", members = { "riptide", "natures_swiftness" } },
  { id = "cures", block = "mouse", row = "SHIFT-", members = { "cure_poison", "cure_disease" } },
  { id = "cleansing", block = "mouse", row = "CTRL-", members = { "poison_cleansing_totem", "disease_cleansing_totem" } },
  { id = "racial", block = "BUTTON3", row = "", spill = { "skysight" }, members = { "walk_on_air" } },
}

-- Spells without a bar slot: resistance totems and Windwall are situational (Totem Bar or spellbook); Far Sight
-- and Sentry Totem (scouting) are almost never cast by a dungeon healer (spellbook); Reincarnation is passive.
L.noSlot = {
  frost_resistance_totem = "totembar",
  fire_resistance_totem = "totembar",
  nature_resistance_totem = "totembar",
  windwall_totem = "totembar",
  far_sight = "spellbook",
  sentry_totem = "spellbook",
  reincarnation = "passive",
}
-- The key page lists the spells without a slot, one line per kind (Reincarnation is passive and not listed).
L.noSlotLines = {
  { kind = "totembar", text = "ui.layout.nobar" },
  { kind = "spellbook", text = "ui.layout.nobook" },
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
-- {spell} = the spell (with a rank when needed); L.macroVars names the other spells a body casts:
-- {heal} = Healing Wave as its own macro names it.
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
L.macroVars = { heal = "healing_wave" }

-- Earlier layouts put these spells in buttons the plan no longer fills (spare now, or on Action Bar 5, which left the
-- plan). A full apply clears such a button only while it still holds exactly that spell (or item macro) and it has
-- its new place or lives in the spellbook now, so no duplicates are left (undoable like everything else). Buttons the
-- plan fills now are not listed: the plan replaces what is there.
-- Action Bar 5 (37-48): layout 6 (0.6.1) Ctrl row, and layout 4 (0.4.1-0.4.2) on buttons that were spare in layouts
-- 5-6 (2, 3, 4, 11) and on button 5 (Mana Tide Totem on Ctrl+5's button).
-- Action Bar 6 (145-156): layout 3 (0.4.0) buttons 9, 10 and 12 (buttons 1-8 are planned again). Buttons 9 and 10
-- hold the Skyborne racials since layout 8; for other races they are spare, so these entries still clear them there.
-- Action Bar 4 buttons 9-12 and Action Bar 3 buttons 4-5: layout 6's clicked spells there (and layout 4's Sentry
-- Totem).
L.old = {
  [37] = "totemic_recall",
  [38] = "earthbind_totem",
  [39] = "stoneclaw_totem",
  [40] = "grounding_totem",
  [41] = "mana_tide_totem",
  [42] = "earthbind_totem",
  [43] = "stoneclaw_totem",
  [44] = "fire_nova",
  [45] = "grounding_totem",
  [46] = "mana_tide_totem",
  [47] = "poison_cleansing_totem",
  [48] = "ghost_wolf",
  [153] = "grounding_totem",
  [154] = "mana_tide_totem",
  [156] = "ghost_wolf",
  [33] = "call_of_the_ancestors",
  [34] = "call_of_the_spirits",
  [35] = "flametongue_totem",
  [36] = "sentry_totem",
  [52] = "windfury_weapon",
  [53] = "@elixir",
}

-- Keys whose default binding the preview explains (expected defaults, research/keybind-layout.md Q4).
L.defaultWarn = {
  ["CTRL-1"] = "ui.preview.warn.stance",
  ["CTRL-2"] = "ui.preview.warn.stance",
  ["CTRL-3"] = "ui.preview.warn.stance",
  ["CTRL-4"] = "ui.preview.warn.stance",
  ["CTRL-5"] = "ui.preview.warn.stance",
  ["CTRL-R"] = "ui.preview.warn.fps",
  -- The client files have no default keys; whatever the middle mouse button did is named in the key list and
  -- restored by Undo.
  BUTTON3 = "ui.preview.warn.middle",
}

-- Spare buttons in this bar order are the first choice for things moved out of a planned slot (clicked ones first).
L.spareOrder = { "bar4", "bar6", "bar3" }
