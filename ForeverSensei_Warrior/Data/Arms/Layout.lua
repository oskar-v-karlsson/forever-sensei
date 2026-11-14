-- ForeverSensei_Warrior/Data/Arms/Layout.lua: the fixed bar and key plan for an Arms Warrior (melee DPS, levelling and
-- dungeons), layout version 1. Spec: research/warrior-arms.md part 4 (approved with commit b01744e's answers), with
-- the rules of research/keybind-layout-v4.md. Planned for level 60; keys never move while levelling, and a spell
-- learned later keeps its slot empty until it is learned.
--
-- Hands: normal-sized, WASD. Allowed keys: 1-5, Q, E, R, F, Z, X, C and the mouse side buttons, each plain, with
-- Shift or with Ctrl.
-- * Each modifier row splits into three blocks of neighbouring keys: 1-5, Q/E/R/F and Z/X/C. A family fills one
--   block, so it sits together on the keyboard and, because button n is key n on bars 1-3, on screen.
-- * Plain: 1-5 strikes (Rend, Overpower, Slam, Mortal Strike, Execute), Q/E/R/F other strikes (Heroic Strike, Sunder
--   Armor, Spearing Strike, Hamstring), Z/X/C rage tools (Bloodrage, Reckless Swings, Berserker Rage).
-- * Shift: 1-4 shouts (Battle, Demoralizing, Intimidating, Challenging), Q/E/R/F AoE (Sweeping Strikes, Whirlwind,
--   Cleave, Thunder Clap), Z/X/C cooldowns (Retaliation, Recklessness, Disarm).
-- * Ctrl: 1-3 stances on Action Bar 3 (like the paladin's auras; the stance bar still shows them), Q/E/R threat tools
--   for emergencies (Taunt, Mocking Blow, Revenge), Z/X/C shield tools (Shield Bash, Shield Block, Shield Wall).
-- * Mouse keys in pairs: Mouse4/5 stop a cast (Pummel, War Stomp), Shift+Mouse4/5 consumables (FS_HEALTH,
--   FS_BANDAGE), Ctrl+Mouse4/5 gap-closers (Charge, Intercept: the modifier keeps a misclick from pulling a pack).
-- Every stance gets the same Action Bar 1 (L.stancePages): the core writes the plain row to the Battle, Defensive and
-- Berserker pages too. A spell that some stances can't cast is a stance macro: the first press changes to its stance,
-- the second casts it (part 3).
-- Bars: plain = Action Bar 1, Shift = Action Bar 2, Ctrl = Action Bar 3 (all at the bottom). Action Bar 6 holds the
-- mouse keys (buttons 1-6 in pairs); it starts in the middle of the screen and the guide tells the player to drag it
-- down in Edit Mode. Action Bar 4 holds out-of-combat clicks (Cultivation). No Hearthstone (Oskar's answer 7).
local _, P = ...
P.specs = P.specs or {}
P.specs.ARMS = P.specs.ARMS or {}

local L = {}
P.specs.ARMS.layout = L

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
      false, false, false, false, false, false } },
  { id = "bar4", first = 25,  binding = "MULTIACTIONBAR3BUTTON%d", setting = "PROXY_SHOW_ACTIONBAR_4" },
}

-- Action Bar 1 shows another 12 slots in each stance (bonus bar pages 7-9; WoWBlzCode Forever @7245053,
-- ActionBarController.lua:159-171, SecureTemplates.lua:667-684). The core copies every planned Action Bar 1 slot to
-- each page; spell = the stance the page belongs to (for "Action Bar 1 (Battle Stance) button 3").
L.stancePages = {
  { first = 73, spell = "battle_stance" },
  { first = 85, spell = "defensive_stance" },
  { first = 97, spell = "berserker_stance" },
}

L.retired = {}

-- Bump when slots or keys change (characters then get the one-time "apply all" notice).
L.version = 1

L.allowedKeys = {
  "1", "2", "3", "4", "5", "Q", "E", "R", "F", "Z", "X", "C",
  "SHIFT-1", "SHIFT-2", "SHIFT-3", "SHIFT-4", "SHIFT-5", "SHIFT-Q", "SHIFT-E", "SHIFT-R", "SHIFT-F", "SHIFT-Z",
  "SHIFT-X", "SHIFT-C",
  "CTRL-1", "CTRL-2", "CTRL-3", "CTRL-4", "CTRL-5", "CTRL-Q", "CTRL-E", "CTRL-R", "CTRL-F", "CTRL-Z", "CTRL-X", "CTRL-C",
  "BUTTON4", "BUTTON5", "SHIFT-BUTTON4", "SHIFT-BUTTON5", "CTRL-BUTTON4", "CTRL-BUTTON5",
}

L.plan = {
  main = {
    "rend", "overpower", "slam", "mortal_strike", "execute",
    "heroic_strike", "sunder_armor", "spearing_strike", "hamstring",
    "bloodrage", "reckless_swings", "berserker_rage",
  },
  bar2 = {
    "battle_shout", "demoralizing_shout", "intimidating_shout", "challenging_shout", "-",
    "sweeping_strikes", "whirlwind", "cleave", "thunder_clap",
    "retaliation", "recklessness", "disarm",
  },
  bar3 = {
    "battle_stance", "defensive_stance", "berserker_stance", "-", "-",
    "taunt", "mocking_blow", "revenge", "-",
    "shield_bash", "shield_block", "shield_wall",
  },
  bar6 = {
    "pummel", "war_stomp", "@health", "@bandage", "charge", "intercept",
    "-", "-", "-", "-", "-", "-",
  },
  bar4 = {
    "cultivation", "-", "-", "-", "-", "-", "-", "-", "-", "-", "-", "-",
  },
}

-- Families (research/warrior-arms.md 4.1): each keyed family fills one block of one row, or the mouse pairs in order
-- (block "mouse": from the family's row on). tools/check.py checks the plan against this list.
L.families = {
  { id = "strikes", block = "1-5", row = "", members = { "rend", "overpower", "slam", "mortal_strike", "execute" } },
  { id = "other", block = "QERF", row = "", members = { "heroic_strike", "sunder_armor", "spearing_strike", "hamstring" } },
  { id = "rage", block = "ZXC", row = "", members = { "bloodrage", "reckless_swings", "berserker_rage" } },
  { id = "shouts", block = "1-5", row = "SHIFT-",
    members = { "battle_shout", "demoralizing_shout", "intimidating_shout", "challenging_shout" } },
  { id = "aoe", block = "QERF", row = "SHIFT-", members = { "sweeping_strikes", "whirlwind", "cleave", "thunder_clap" } },
  { id = "cooldowns", block = "ZXC", row = "SHIFT-", members = { "retaliation", "recklessness", "disarm" } },
  { id = "stances", block = "1-5", row = "CTRL-", members = { "battle_stance", "defensive_stance", "berserker_stance" } },
  { id = "threat", block = "QERF", row = "CTRL-", members = { "taunt", "mocking_blow", "revenge" } },
  { id = "shield", block = "ZXC", row = "CTRL-", members = { "shield_bash", "shield_block", "shield_wall" } },
  { id = "stop", block = "mouse", row = "", members = { "pummel", "war_stomp" } },
  { id = "consumables", block = "mouse", row = "SHIFT-", members = { "@health", "@bandage" } },
  { id = "gapclosers", block = "mouse", row = "CTRL-", members = { "charge", "intercept" } },
}

L.noSlot = {}
L.noSlotLines = {}

-- Stance macros (research/warrior-arms.md part 3). Each casts the spell in a stance that allows it, else changes to
-- the spell's home stance (one press changes the stance, the next casts). Stance indices follow the stance bar:
-- 1 Battle, 2 Defensive, 3 Berserker. They are used in both targeting modes (macroAlways); Charge, Intercept and
-- Pummel also aim at the enemy under the mouse in mouseover mode (the _click bodies drop that).
L.macros = {
  charge = "FS_CHARGE",
  overpower = "FS_OP",
  mocking_blow = "FS_MOCK",
  retaliation = "FS_RETAL",
  spearing_strike = "FS_SPEAR",
  sweeping_strikes = "FS_SWEEP",
  rend = "FS_REND",
  thunder_clap = "FS_TCLAP",
  shield_bash = "FS_SBASH",
  hamstring = "FS_HAMS",
  execute = "FS_EXEC",
  taunt = "FS_TAUNT",
  revenge = "FS_REV",
  shield_block = "FS_SBLOCK",
  disarm = "FS_DISARM",
  shield_wall = "FS_SWALL",
  intercept = "FS_INTER",
  berserker_rage = "FS_BRAGE",
  whirlwind = "FS_WW",
  pummel = "FS_PUMMEL",
  recklessness = "FS_RECK",
}
L.macroKind = {
  charge = "harm_b",
  overpower = "stance_b", mocking_blow = "stance_b", retaliation = "stance_b",
  spearing_strike = "stance_b", sweeping_strikes = "stance_b",
  rend = "stance_bd", thunder_clap = "stance_bd", shield_bash = "stance_bd",
  hamstring = "stance_bz", execute = "stance_bz",
  taunt = "stance_d", revenge = "stance_d", shield_block = "stance_d", disarm = "stance_d", shield_wall = "stance_d",
  intercept = "harm_z",
  berserker_rage = "stance_z", whirlwind = "stance_z", recklessness = "stance_z",
  pummel = "kick_z",
}
L.macroAlways = {}
for key in pairs(L.macros) do L.macroAlways[key] = true end
L.macroVars = { battle = "battle_stance", defensive = "defensive_stance", berserker = "berserker_stance" }
-- stance_b: Battle only. stance_d: Defensive only. stance_z: Berserker only. stance_bd: Battle or Defensive (changes
-- to Battle from Berserker). stance_bz: Battle or Berserker (changes to Battle from Defensive). harm_*: also the enemy
-- under the mouse. kick_z: Pummel stops your own cast (a Slam) first.
L.macroBodies = {
  stance_b = "#showtooltip {spell}\n/cast [nostance:1] {battle}; {spell}",
  stance_d = "#showtooltip {spell}\n/cast [nostance:2] {defensive}; {spell}",
  stance_z = "#showtooltip {spell}\n/cast [nostance:3] {berserker}; {spell}",
  stance_bd = "#showtooltip {spell}\n/cast [stance:3] {battle}; {spell}",
  stance_bz = "#showtooltip {spell}\n/cast [stance:2] {battle}; {spell}",
  harm_b = "#showtooltip {spell}\n/cast [nostance:1] {battle}; [@mouseover,harm,nodead][] {spell}",
  harm_b_click = "#showtooltip {spell}\n/cast [nostance:1] {battle}; {spell}",
  harm_z = "#showtooltip {spell}\n/cast [nostance:3] {berserker}; [@mouseover,harm,nodead][] {spell}",
  harm_z_click = "#showtooltip {spell}\n/cast [nostance:3] {berserker}; {spell}",
  kick_z = "#showtooltip {spell}\n/stopcasting\n/cast [nostance:3] {berserker}; [@mouseover,harm,nodead][] {spell}",
  kick_z_click = "#showtooltip {spell}\n/stopcasting\n/cast [nostance:3] {berserker}; {spell}",
}
-- 21 stance macros + FS_HEALTH + FS_BANDAGE = 23 per-character macros at 60 (MAX_CHARACTER_MACROS = 30).
L.macroBudget = 25

L.combos = {}
L.old = {}

-- The preview warns when a key loses one of these game defaults (Ctrl+1-3: stance bar buttons; Ctrl+R: framerate).
-- Ctrl+4 and Ctrl+5 are spare (bound, empty): a warrior's stance bar has three buttons, so their defaults do nothing.
L.defaultWarn = {
  ["CTRL-1"] = "ui.preview.warn.stance",
  ["CTRL-2"] = "ui.preview.warn.stance",
  ["CTRL-3"] = "ui.preview.warn.stance",
  ["CTRL-R"] = "ui.preview.warn.fps",
}

L.spareOrder = { "bar4", "bar6", "bar3", "bar2" }
