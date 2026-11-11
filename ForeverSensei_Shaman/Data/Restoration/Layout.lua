-- ForeverSensei_Shaman/Data/Restoration/Layout.lua: the fixed slot and key plan (layout version 5, since
-- ForeverSensei 0.4.3; unchanged in 0.5.0, when the Shaman data moved into this class pack).
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
-- * Spare keys: Shift+2, Shift+4, Shift+X, Shift+C, Ctrl+2, Ctrl+3, Ctrl+4, Ctrl+R and Ctrl+X. They are bound to
--   their empty buttons anyway, so every key of the Shift and Ctrl bars works the same way and the bars look alike
--   (the player's choice in 0.4.3). Ctrl+2-4 replace stance-bar buttons and Ctrl+R the framerate display; the
--   preview says so.
-- Bars (Blizzard_ActionBar in the Forever UI code; slot = (page - 1) * 12 + button):
--   plain = main bar ACTIONBUTTON (1-12); Shift = Action Bar 2 MULTIACTIONBAR1BUTTON (page 6, 61-72);
--   Ctrl = Action Bar 5 MULTIACTIONBAR4BUTTON (MultiBarLeft, page 4, 37-48, at the right edge of the screen). Bar 5
--   mirrors bar 2: button n has the Ctrl version of button n's key (Ctrl+1, 2, 3, 4, 5, Q, E, R, F, Z, X, C), so the
--   three keyed bars line up key by key.
--   Mouse = Action Bar 3 MULTIACTIONBAR2BUTTON (page 5, 49-60) buttons 7-12: Mouse4, Mouse5, Shift+Mouse4,
--   Shift+Mouse5, Ctrl+Mouse4, Ctrl+Mouse5 (key strings BUTTON4/BUTTON5, Blizzard_FrameXML/BindingUtil). A key can be
--   bound to any button; the six mouse spells sit together as one block on a bar that is shown anyway, and Riptide's
--   and Nature's Swiftness' cooldowns are visible there.
--   Layout 3 (0.4.0) used Action Bars 6 and 7 for the Ctrl and mouse spells; those bars sat in the middle of the
--   screen, so the player did not want them. The addon never turns them on again: a full apply clears layout 3's
--   spells there, hides both bars and unbinds keys that still point at them (L.retired).
--   Action Bar 3 buttons 1-6 hold the weapon imbues and long buffs with the potion and elixir macros; Action Bar 4
--   (page 3, 25-36) holds out-of-combat spells, situational totems and the extra Totem Bar presets. Both are clicked.
--   To make room for the mouse block (0.4.3), the rarest out-of-combat spells have no bar slot (L.noSlot "spellbook").
--   Things moved out of a planned slot go to the spare buttons (bar 3, bar 4, bar 5, then bar 2) first.
-- Plan entries: a spell key; "@kind" an item macro (ForeverSensei/Data/Items.lua); "-" a spare button; "#" the
-- player's own button. The core builds L.slots, L.bySpell, L.byItem, L.own and L.spare from L.plan
-- (ns.BuildLayout in ForeverSensei/Core/Class.lua).
local _, P = ...
P.specs = P.specs or {}
P.specs.RESTORATION = P.specs.RESTORATION or {}

local L = {}
P.specs.RESTORATION.layout = L

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
  { id = "bar5", first = 37,  binding = "MULTIACTIONBAR4BUTTON%d", setting = "PROXY_SHOW_ACTIONBAR_5", keys = withMod("CTRL-") },
  { id = "bar3", first = 49,  binding = "MULTIACTIONBAR2BUTTON%d", setting = "PROXY_SHOW_ACTIONBAR_3",
    keys = { false, false, false, false, false, false,
      "BUTTON4", "BUTTON5", "SHIFT-BUTTON4", "SHIFT-BUTTON5", "CTRL-BUTTON4", "CTRL-BUTTON5" } },
  { id = "bar4", first = 25,  binding = "MULTIACTIONBAR3BUTTON%d", setting = "PROXY_SHOW_ACTIONBAR_4" },
}

-- Bars the addon no longer uses (layout 3 put the Ctrl and mouse spells there). A full apply hides them, clears the
-- plan's spells from them and unbinds keys bound to their buttons. own: layout 3's Ctrl+5 button (the player's),
-- which a full apply leaves alone. assigned: the buttons layout 3 filled, the only ones the clean-up button empties.
L.retired = {
  { id = "bar6", first = 145, binding = "MULTIACTIONBAR5BUTTON%d", setting = "PROXY_SHOW_ACTIONBAR_6", own = 5,
    assigned = { 1, 6, 7, 9, 10, 12 } },
  { id = "bar7", first = 157, binding = "MULTIACTIONBAR6BUTTON%d", setting = "PROXY_SHOW_ACTIONBAR_7",
    assigned = { 1, 2, 3, 4, 5, 6 } },
}

-- Bumped when slots or keys change: players who had the older layout get a one-time notice (Modules/Layout.lua).
L.version = 5

-- Every key the plan binds: the planned buttons' keys and the spare keyed buttons' keys.
L.allowedKeys = {
  "1", "2", "3", "4", "Q", "E", "R", "F", "Z", "X", "C",
  "SHIFT-1", "SHIFT-2", "SHIFT-3", "SHIFT-4", "SHIFT-Q", "SHIFT-E", "SHIFT-R", "SHIFT-F", "SHIFT-Z", "SHIFT-X",
  "SHIFT-C",
  "CTRL-1", "CTRL-2", "CTRL-3", "CTRL-4", "CTRL-Q", "CTRL-E", "CTRL-R", "CTRL-F", "CTRL-Z", "CTRL-X", "CTRL-C",
  "BUTTON4", "BUTTON5", "SHIFT-BUTTON4", "SHIFT-BUTTON5", "CTRL-BUTTON4", "CTRL-BUTTON5",
}

-- The player's own keys and buttons: the addon never binds these keys and never changes these slots.
L.ownKeys = { "5", "SHIFT-5", "CTRL-5" }

-- One row per bar, button 1..12 left to right.
L.plan = {
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
    "totemic_recall", "-", "-", "-", "#",
    "earthbind_totem", "stoneclaw_totem", "-", "grounding_totem",
    "mana_tide_totem", "-", "ghost_wolf",
  },
  bar3 = {
    "rockbiter_weapon", "flametongue_weapon", { "lightning_shield", after = "water_shield" }, "windfury_weapon",
    "@elixir", "@healpot",
    "riptide", "natures_swiftness", "cure_poison", "cure_disease", "poison_cleansing_totem", "disease_cleansing_totem",
  },
  bar4 = {
    "ancestral_spirit", "astral_recall", "strength_of_earth_totem", "healing_stream_totem", "fire_nova",
    "windfury_totem", "grace_of_air_totem", "magma_totem", "call_of_the_ancestors", "call_of_the_spirits",
    "flametongue_totem", "-",
  },
}

-- Spells without a bar slot: resistance totems and Windwall are situational (Totem Bar or spellbook);
-- Reincarnation is passive. "spellbook" (0.4.3, to make room for the mouse block on Action Bar 3): spells a dungeon
-- healer almost never casts, all out of combat: Far Sight and Sentry Totem (scouting), Water Breathing and Water
-- Walking (travel; a few swims a week), Frostbrand Weapon (a solo imbue against runners; a healer uses Rockbiter,
-- Flametongue or Windfury).
L.noSlot = {
  frost_resistance_totem = "totembar",
  fire_resistance_totem = "totembar",
  nature_resistance_totem = "totembar",
  windwall_totem = "totembar",
  far_sight = "spellbook",
  sentry_totem = "spellbook",
  water_breathing = "spellbook",
  water_walking = "spellbook",
  frostbrand_weapon = "spellbook",
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

-- Earlier layouts put these spells in buttons that are spare now. A full apply clears such a button when it still
-- holds that spell and the spell has its new place (or now lives in the spellbook), so no duplicates are left
-- (undoable like everything else). Layout 2 (0.3.0): bar 2. Layout 4 (0.4.1-0.4.2): Action Bar 5 buttons that are
-- spare Ctrl keys now, and Sentry Totem's old button on bar 4. The player's own buttons 5 and Shift+5 are left alone,
-- also when layout 2 put a spell there. L.oldOwn: Ctrl+5's button (Action Bar 5 button 5) held Mana Tide Totem in
-- layout 4; it is the player's own now, so a full apply clears it only while it still holds exactly that spell.
L.oldOwn = {
  [41] = "mana_tide_totem",
}

L.old = {
  [62] = "cure_disease",
  [64] = "frost_shock",
  [71] = "mana_tide_totem",
  [72] = "call_of_the_elements",
  [38] = "earthbind_totem",
  [39] = "stoneclaw_totem",
  [40] = "grounding_totem",
  [44] = "natures_swiftness",
  [47] = "poison_cleansing_totem",
  [36] = "sentry_totem",
}

-- Keys whose default binding the preview explains (expected defaults, research/keybind-layout.md Q4).
L.defaultWarn = {
  ["CTRL-1"] = "ui.preview.warn.stance",
  ["CTRL-2"] = "ui.preview.warn.stance",
  ["CTRL-3"] = "ui.preview.warn.stance",
  ["CTRL-4"] = "ui.preview.warn.stance",
  ["CTRL-R"] = "ui.preview.warn.fps",
}

-- Spare buttons in this bar order are the first choice for things moved out of a planned slot.
L.spareOrder = { "bar3", "bar4", "bar5", "bar2" }
