# Sources

Every fact in ForeverSensei comes from a **World of Warcraft: Forever** source: the Forever client data, Forever guides, or the Forever UI code. Classic and Retail pages were never used, because Forever changed many spells and talents.

All entries were checked against client **1.60.1.70862**: the Shaman pack on **2026-11-09**, the Paladin pack on **2026-11-11**, the Warrior pack on **2026-11-14**. Each data entry in `ForeverSensei_<Class>/Data/**/*.lua` (the class packs) and `ForeverSensei/Data/Items.lua` has a `src` key, which points into the pack's `P.sources` in `ForeverSensei_<Class>/Data/Spells.lua` or the core's `ns.Sources` in `ForeverSensei/Core/Class.lua`, and a `verified` date. `make check` fails if any entry is missing them.

## Game data and guides (Shaman pack)

| Key | Source | Used for |
|---|---|---|
| `simc` | [simc-forever SpellDataDump/shaman.txt](https://github.com/simulationcraft/simc-forever/blob/HEAD/SpellDataDump/shaman.txt), header "World of Warcraft 1.60.1.70862 Live". Parsed copy: `research/shaman_simc_1.60.1.70862.tsv` (made by `tools/research/parse_simc.py`) | 46 of the 53 spells: ID, English name, level, cooldown and cast-time facts; every talent (ID, row, column, max rank). `make check` cross-checks the data against the TSV. |
| `simc_race` | [simc-forever SpellDataDump/nonclass.txt](https://github.com/simulationcraft/simc-forever/blob/1c895ad3/SpellDataDump/nonclass.txt) @ `1c895ad3` (client 1.60.1.70938), read 2026-11-13 | The two Skyborne racials (0.8.1). **Walk on Air** 1259416: Slow Fall aura, 10 s, 90 s cooldown, race mask `0x300000000` (race ids 33 and 34, both Skyborne races). **Skysight** 1259686: 0.5 s cast, 120 s cooldown, race mask `0x200000000` (race id 34); it triggers Elemental Blessing 1259688, +15% movement speed for 30 s, doubled while Charged. The race mask's bit n is race id n+1. |
| `simc` ranks | Same dump, through `tools/research/gen_ranks.py` → `ForeverSensei_Shaman/Data/Ranks.lua` (2026-11-09) | Every rank's spell ID and trainer level, used for automatic rank upgrades. `make check` fails if the file is out of date or a rank does not match the dump (name and "Rank N"). |
| `wh_spell` | `https://www.wowhead.com/forever/spell=<id>` | 7 spells missing from the simc dump (see below) |
| `wh_item` | `https://www.wowhead.com/forever/item=<id>` and the Forever potion and elixir lists ([potions](https://www.wowhead.com/forever/items/consumables/potions), [elixirs](https://www.wowhead.com/forever/items/consumables/elixirs)) | Potion and elixir IDs, names, required levels and icons in `Data/Items.lua` (see below) |
| `wh_abilities` | [Wowhead Forever: Restoration Shaman healer abilities](https://www.wowhead.com/forever/guide/classes/shaman/restoration/healer-abilities) | Ability use and priorities |
| `wh_overview` | [Wowhead Forever: Restoration Shaman overview](https://www.wowhead.com/forever/guide/classes/shaman/restoration/overview-pve-healer) | The healer role, strengths and weaknesses |
| `wh_talents` | [Wowhead Forever: Restoration Shaman talent builds](https://www.wowhead.com/forever/guide/classes/shaman/restoration/talent-builds-pve-healer) | Cross-check for the talent build |
| `moba` | [Mobalytics: WoW Forever Restoration Shaman guide](https://mobalytics.gg/wow-forever/classes/restoration-shaman-guide) (the guide this build follows) | Talent order (leveling path, final 0/5/46); healing, damage, totem and group tips |
| `ui` | Blizzard UI code for Forever 1.60.1 ([reckhou/WoWBlzCode](https://github.com/reckhou/WoWBlzCode), folder `Forever`) | Action bar slot numbers, binding names, the talent frame, events and API names. Action Bar 5 (MultiBarLeft) is page 4 (slots 37-48), binding `MULTIACTIONBAR4BUTTON<n>`, shown with `PROXY_SHOW_ACTIONBAR_5` (`Blizzard_ActionBar/Shared/MultiActionBars.xml`, checked 2026-11-10). |

Wowhead and Mobalytics pages block scripted downloads (HTTP 403), so they were read in a browser.

### Lower heal ranks (0.10.0)

Checked on **2026-11-15**. The full research, the per-level rank table and the decisions are in [research/shaman-downranking.md](research/shaman-downranking.md) (approved option 1).

| Key | Source | Used for |
|---|---|---|
| `dev1001` | Blizzard, WoW Forever development notes, 2026-10-01, [us.forums.blizzard.com/en/wow/t/2360696/4](https://us.forums.blizzard.com/en/wow/t/2360696/4) ("User Interface") | Forever has a downranking penalty, explained in the Spell Damage/Healing tooltip |
| `dev1016` | Same thread, notes of 2026-10-16 (posts up to 2026-11-04 scanned) | No later change to the penalty |
| `fc` | foreverchanges.pro/downranking (Vektor, updated 2026-10-16) | The measured rule (a rank keeps its full Spell Healing bonus for 17 levels after its trainer level, then loses 5% of the bonus per level; the base heal is not penalised); `/cast Healing Wave(Rank 3)` works in a macro |
| `rl` | realmlist.org Forever briefing, 2026-10-12 | The same rule, a second write-up |
| `f2371681` | [us.forums.blizzard.com/en/wow/t/2371681](https://us.forums.blizzard.com/en/wow/t/2371681) | Heals on party members of another level land under the tooltip |
| `wiki` | [warcraft.wiki.gg/wiki/Downranking](https://warcraft.wiki.gg/wiki/Downranking) | The Classic, TBC and WotLK rules, for comparison only |
| `simc` | The Shaman dump above | Rank levels, mana and base heals. Healing Way (29206) is a flat bonus to Healing Wave, so the Classic "rank 1 to keep Healing Way up" trick does not apply. |

## Spells verified only on Wowhead

These 7 are not in the simc dump. Their IDs and levels come from Wowhead Forever spell pages. `/sensei verify` checks them in the live client.

| Spell | ID | Level |
|---|---|---|
| Call of the Elements | 66842 | 20 |
| Totemic Recall | 36936 | 20 |
| Water Breathing | 131 | 22 |
| Water Walking | 546 | 28 |
| Call of the Ancestors | 66843 | 30 |
| Astral Recall | 556 | 30 |
| Call of the Spirits | 66844 | 40 |

## Game data and guides (Paladin pack, Protection)

All checked on **2026-11-11**. The research behind the key layout, the pull walkthroughs and every decision is in [research/keybind-layout-paladin.md](research/keybind-layout-paladin.md) (its "Sources" section has more detail).

| Key | Source | Used for |
|---|---|---|
| `simc` | [simc-forever SpellDataDump/paladin.txt](https://github.com/simulationcraft/simc-forever/blob/HEAD/SpellDataDump/paladin.txt) (commit `3c1d319e`), header "SimulationCraft 160-01 for World of Warcraft 1.60.1.70862 Live". Parsed copy: `research/paladin_simc_1.60.1.70862.tsv` (`tools/research/parse_simc.py`) | 42 of the 45 spells and every talent: ID, English name, level, cast, cooldown, GCD, cost, duration, the "Use Shapeshift Bar" attribute of the auras. `make check` cross-checks the data against the TSV. |
| `simc` ranks | Same dump, through `tools/research/gen_ranks.py --class paladin` → `ForeverSensei_Paladin/Data/Ranks.lua` | Every rank's spell ID and trainer level. Holy Light rank 1 ([635](https://www.wowhead.com/forever/spell=635), level 1) is missing from the dump and comes from its Wowhead Forever tooltip. |
| `wh_tt` | Wowhead Forever tooltips, `https://nether.wowhead.com/forever/tooltip/spell/<id>` | Current tooltip text (ranges, effects, Forbearance, "Does not consume the Seal"), and 3 spells whose ID the pack takes from a tooltip: Holy Light (635, rank 1, missing from the dump), Summon Warhorse (13819), Summon Charger (23214) |
| `wh_guide` | [Wowhead: Protection Paladin Leveling Guide - WoW: Forever](https://www.wowhead.com/forever/guide/classes/paladin/protection/tank-leveling-tips), Riyani, updated 2026-11-06 | **The talent path**: 0/32/19 with its "Talent Order", one point per level 10-60. The trainer spell list and mana tips. |
| `moba` | [Mobalytics: WoW Forever Protection Paladin guide](https://mobalytics.gg/wow-forever/classes/protection-paladin-guide), Subtle, updated 2026-11-11 | Gameplay: opener, pull, single- and multi-target rotation, seals, auras, blessings, tips, the "Big Threat Opener" macro. Its 0/35/16 build is only noted as an alternative. |
| `wh_abil` | [Wowhead Forever: Paladin abilities](https://www.wowhead.com/forever/spells/abilities/paladin) | Which spells exist and are trainable; "New" and "Removed" tags |
| `ui` | [reckhou/WoWBlzCode](https://github.com/reckhou/WoWBlzCode) @ `7245053`, folder `Forever` | Binding names (`Bindings_Camelot.xml`), the stance bar (`Blizzard_ActionBar/Shared/StanceBar.lua`) and the default Ctrl+1-4 stance bindings |

### Paladin: where sources disagree, or can't be verified

| Topic | Disagreement | Used |
|---|---|---|
| Seal of Fury Judgement taunt | `moba`: 4 s. `wh_tt` 1311649 and `simc` 20232 (Judgement of Fury): 3 s. | 3 s (client data). Verify in game. |
| Blessings of Salvation, Sanctuary and Light; Hammer of the Righteous | Named by a guide or listed in the dump, but not confirmed as trainable in Forever (empty tooltips, missing from `wh_abil` or from both guides). | Left out of every key, text and card until checked in game (`tools/check.py` `PALADIN_EXCLUDED`). Ctrl+E stays spare for Hammer of the Righteous. |
| `moba` opener macro | `/start attack` (a typo), and its Holy Shield and Exorcism macros cast Consecration. | Our `FS_OPEN` uses `/startattack` and casts Judgement, Swift Judgement and Holy Strike. |
| Level-60 build | `wh_guide`: 0/32/19. `moba`: 0/35/16. | `wh_guide`, as Oskar asked. |

## Game data and guides (Warrior pack, Arms)

All checked on **2026-11-14**. The research behind the spells, the stance pages, the stance macros and the key layout is in [research/warrior-arms.md](research/warrior-arms.md) (approved for 0.9.0; its "Sources" section and part 1 cite each fact by dump line).

| Key | Source | Used for |
|---|---|---|
| `simc` | [simc-forever SpellDataDump/warrior.txt](https://github.com/simulationcraft/simc-forever/blob/HEAD/SpellDataDump/warrior.txt) (commit `3c1d319e`), header "SimulationCraft 160-01 for World of Warcraft 1.60.1.70862 Live". Parsed copy: `research/warrior_simc_1.60.1.70862.tsv` (`tools/research/parse_simc.py`). The 70938 dump (`1c895ad3`) differs only in its header. | Every spell and talent: ID, English name, level, rage, cooldown, the stances each spell needs, talent rows, columns and max ranks. Forever-only spells and talents: Spearing Strike, Bloodthrill, Weaponmaster, Reckless Swings, Improved Slam, Improved Tactical Mastery. `make check` cross-checks the data against the TSV. |
| `simc` ranks | Same dump, through `tools/research/gen_ranks.py --class warrior` → `ForeverSensei_Warrior/Data/Ranks.lua` | Every rank's spell ID and trainer level |
| `simc_race` | The same commit's `SpellDataDump/nonclass.txt` | The Tauren racials War Stomp (20549) and Cultivation (20552), race mask 0x20 (Tauren only) |
| `moba` | [Mobalytics: WoW Forever Arms Warrior guide](https://mobalytics.gg/wow-forever/classes/arms-warrior-guide), Ahlaundoh, updated 2026-11-12. The site returns 403 to scripts; read in the in-app browser. | **The talent path**: 32/18/1, level by level, in the guide's order (Enrage over Lingering Rage). Gameplay: role, single- and multi-target rotation, stance use, rage, cooldowns, dungeon tips, the Tauren notes. |
| `ui` | [reckhou/WoWBlzCode](https://github.com/reckhou/WoWBlzCode) @ `7245053`, folder `Forever` | Stance paging of Action Bar 1 (`GetBonusBarOffset`: Battle slots 73-84, Defensive 85-96, Berserker 97-108), the stance bar and its default `Ctrl+1-3` bindings, binding names, the macro limit |

### Warrior: where sources disagree, or can't be verified

| Topic | Disagreement | Used |
|---|---|---|
| Mortal Strike | `moba`: the talent at level 39. `simc`: spell level 40. | Level 39 (the talent tier gives the button). Verify in game. |
| Talent order | `moba` takes Improved Heroic Strike at 13, 14 and 58, and Deep Wounds (row 3) at 18 with 8 points spent; the dump lists no point requirement. | The guide's order exactly as written (`noRowGate`). The game's real point gates are an in-game check. |
| Charge | Two spell sets: 100/6178/11578 (Battle Stance, out of combat) and 1240287-1240289 (usable in combat, from the Protection talent Vanguard). | 100/6178/11578: Arms doesn't take Vanguard. |
| Victory Rush, Commanding Shout | In the dump (402927, 403215), but only through Season of Discovery runes. | Left out (`tools/check.py` `WARRIOR_EXCLUDED`). Checklist: is either in the spellbook? |
| Slam | Classic: level 30, no cooldown. Forever (`simc`): level 20, 15 s cooldown. | Forever. |
| Talent trees | `moba` shows three trees; the client has one tree with 12 columns. | The advisor names the talent, not a tree. |

## Potions and elixirs

Checked on **2026-11-10** on Wowhead Forever item pages and tooltips. Listed best first, as in `ForeverSensei/Data/Items.lua`; "none" means the tooltip shows no required level. `/sensei verify` checks the names in the live client.

| Kind (macro) | Item | ID | Level |
|---|---|---|---|
| Mana (`FS_MANA`, key Z) | Major Mana Potion | [13444](https://www.wowhead.com/forever/item=13444) | 49 |
| | Superior Mana Potion | [13443](https://www.wowhead.com/forever/item=13443) | 41 |
| | Greater Mana Potion | [6149](https://www.wowhead.com/forever/item=6149) | 31 |
| | Mana Potion | [3827](https://www.wowhead.com/forever/item=3827) | 22 |
| | Lesser Mana Potion | [3385](https://www.wowhead.com/forever/item=3385) | 14 |
| | Lesser Mana Potion (Bind to Account) | [287969](https://www.wowhead.com/forever/item=287969) | none |
| | Minor Mana Potion | [2455](https://www.wowhead.com/forever/item=2455) | 5 |
| | Minor Mana Potion (Bind to Account) | [287968](https://www.wowhead.com/forever/item=287968) | none |
| Healing (`FS_HEALPOT`, bar 3) | Major Healing Potion | [13446](https://www.wowhead.com/forever/item=13446) | 45 |
| | Superior Healing Potion | [3928](https://www.wowhead.com/forever/item=3928) | 35 |
| | Greater Healing Potion | [1710](https://www.wowhead.com/forever/item=1710) | 21 |
| | Greater Healing Potion (Bind to Account) | [287977](https://www.wowhead.com/forever/item=287977) | none |
| | Healing Potion | [929](https://www.wowhead.com/forever/item=929) | 12 |
| | Perishable Healing Potion | [268883](https://www.wowhead.com/forever/item=268883) | 12 |
| | Lesser Healing Potion | [858](https://www.wowhead.com/forever/item=858) | 3 |
| | Lesser Healing Potion (Bind to Account) | [287967](https://www.wowhead.com/forever/item=287967) | none |
| | Perishable Lesser Healing Potion | [268882](https://www.wowhead.com/forever/item=268882) | 3 |
| | Minor Healing Potion | [118](https://www.wowhead.com/forever/item=118) | none |
| | Minor Healing Potion (Bind to Account) | [287966](https://www.wowhead.com/forever/item=287966) | none |
| | Perishable Minor Healing Potion | [268881](https://www.wowhead.com/forever/item=268881) | none |
| Arcane Elixir (`FS_ELIXIR`, bar 3) | Greater Arcane Elixir (+35 spell damage, 1 hour) | [13454](https://www.wowhead.com/forever/item=13454) | 47 |
| | Arcane Elixir (+20, 30 minutes) | [9155](https://www.wowhead.com/forever/item=9155) | 37 |
| | Lesser Arcane Elixir (+15, 30 minutes, new in Forever) | [250342](https://www.wowhead.com/forever/item=250342) | 25 |
| | Minor Arcane Elixir (+5, 30 minutes, new in Forever) | [247754](https://www.wowhead.com/forever/item=247754) | none |

Healthstones for `FS_HEALTH` (key C: a Healthstone first, else the best Healing Potion above) were checked on **2026-11-11** on Wowhead Forever item tooltips (`https://nether.wowhead.com/forever/tooltip/item/<id>`). All are Conjured, Unique, with a 2-minute cooldown. The two higher IDs of each size are the Improved Healthstone talent versions.

| Kind (macro) | Item | ID | Heals | Level |
|---|---|---|---|---|
| Health (`FS_HEALTH`, key C) | Major Healthstone | [9421](https://www.wowhead.com/forever/item=9421), [19013](https://www.wowhead.com/forever/item=19013) | 1440 | 48 |
| | Major Healthstone | [19012](https://www.wowhead.com/forever/item=19012) | 1320 | 48 |
| | Greater Healthstone | [5510](https://www.wowhead.com/forever/item=5510), [19011](https://www.wowhead.com/forever/item=19011) | 960 | 36 |
| | Greater Healthstone | [19010](https://www.wowhead.com/forever/item=19010) | 880 | 36 |
| | Healthstone | [5509](https://www.wowhead.com/forever/item=5509), [19009](https://www.wowhead.com/forever/item=19009) | 600 | 24 |
| | Healthstone | [19008](https://www.wowhead.com/forever/item=19008) | 550 | 24 |
| | Lesser Healthstone | [5511](https://www.wowhead.com/forever/item=5511), [19007](https://www.wowhead.com/forever/item=19007) | 300 | 12 |
| | Lesser Healthstone | [19006](https://www.wowhead.com/forever/item=19006) | 275 | 12 |
| | Minor Healthstone | [5512](https://www.wowhead.com/forever/item=5512), [19005](https://www.wowhead.com/forever/item=19005) | 120 | none |
| | Minor Healthstone | [19004](https://www.wowhead.com/forever/item=19004) | 110 | none |

Bandages for `FS_BANDAGE` (the Warrior's Shift+Mouse 5, used on yourself) were checked on **2026-11-14** on Wowhead Forever item tooltips (`https://nether.wowhead.com/forever/tooltip/item/<id>`). None has a required level; each needs First Aid skill, so the macro takes the best one the client says you can use (`C_Item.IsUsableItem`). Heals = total over 8 seconds.

| Kind (macro) | Item | ID | First Aid | Heals |
|---|---|---|---|---|
| Bandage (`FS_BANDAGE`) | Heavy Runecloth Bandage | [14530](https://www.wowhead.com/forever/item=14530) | 225 | 2000 |
| | Runecloth Bandage | [14529](https://www.wowhead.com/forever/item=14529) | 200 | 1360 |
| | Heavy Mageweave Bandage | [8545](https://www.wowhead.com/forever/item=8545) | 175 | 1104 |
| | Mageweave Bandage | [8544](https://www.wowhead.com/forever/item=8544) | 150 | 800 |
| | Heavy Silk Bandage | [6451](https://www.wowhead.com/forever/item=6451) | 125 | 640 |
| | Silk Bandage | [6450](https://www.wowhead.com/forever/item=6450) | 100 | 400 |
| | Heavy Wool Bandage | [3531](https://www.wowhead.com/forever/item=3531) | 75 | 301 |
| | Wool Bandage | [3530](https://www.wowhead.com/forever/item=3530) | 50 | 161 |
| | Heavy Linen Bandage | [2581](https://www.wowhead.com/forever/item=2581) | 20 | 114 |
| | Linen Bandage | [1251](https://www.wowhead.com/forever/item=1251) | 1 | 66 |

Left out on purpose: Discolored Healing Potions (they heal, then return 75% as poison or disease damage), the PvP Combat potions (18839, 18841, need a PvP rank), the Restored potions (282011, 282013) and draughts.

## Where sources disagree (Shaman pack)

| Topic | Disagreement | Used |
|---|---|---|
| Totemic Call | Wowhead: 1 min cooldown, placed at a target location. simc and Mobalytics: 30 s cooldown, at the shaman's own location. | simc (client data) |
| Riptide | Wowhead: an initial heal plus a heal over time, 6 s cooldown. simc and Mobalytics: heal over time only, 12 s cooldown. | simc. The texts say "heal over 15 seconds" and "12-second cooldown". |
| Purge | Wowhead: removes 2 effects. simc: the number varies. | The text says "removes magic effects" with no count. |
| Walk on Air ID | wow-forever.gg lists 1259416 (10 s, "High Order Skyborne and Windshaper Skyborne racial") and 1308663 (1 min, the ID the Icy Veins Skyborne guide links). 1308663 is not in the simc dump. | 1259416 (simc_race). `/sensei verify` prints whether the player knows it; checked in game. |
| Skysight duration | Icy Veins: +15% speed for 15 s. simc: Elemental Blessing (1259688) lasts 30 s. | simc. The card says 30 seconds. |
| Level-60 talent build | Wowhead: 0/17/34. Mobalytics: 0/5/46. | Mobalytics, as the user asked. It was cross-checked against simc rows, columns, max ranks and requirements. |

## Addon API research (Forever 12.x client)

Forever runs the modern 12.x UI ("Camelot", `## Interface: 16001`, `WOW_PROJECT_ID == 1`), not the Classic API.

- [warcraft.wiki.gg](https://warcraft.wiki.gg/): the API reference, including how secret values work in combat in 12.x.
- [realworldbuilder/wowwrapped docs/addon-api.md](https://github.com/realworldbuilder/wowwrapped/blob/main/docs/addon-api.md): notes on the Forever addon API.
- [reckhou/WoWBlzCode](https://github.com/reckhou/WoWBlzCode), `Forever`: the function and event lists, `Bindings.xml` (`MULTIACTIONBAR2BUTTON` for Action Bar 3, which holds the Ctrl keys since layout v4 (0.7.0), `MULTIACTIONBAR5/6/7BUTTON` for Action Bars 6-8 (slots 145-156, 157-168, 169-180), Action Bar 6 holding the mouse keys, and `MULTIACTIONBAR4BUTTON` for Action Bar 5, the old Ctrl bar), the Edit Mode default positions (`Blizzard_EditMode/Mainline/EditModePresetLayouts.lua`: bars 6-8 start in the middle of the screen), the MultiBar layout and pages, the `BUTTON4`/`BUTTON5` key names (`Blizzard_FrameXML/BindingUtil`), the talent tree code, and the macro icon picker. The macro limit, `MAX_CHARACTER_MACROS = 30` (and `MAX_ACCOUNT_MACROS = 120`), is in `Blizzard_APIDocumentationGenerated/MacroConstantsDocumentation.lua`; the addon uses at most 15 character macros for the Restoration Shaman (13 before 0.10.0), 12 for the Protection Paladin and 23 for the Arms Warrior (character macros are per character). Details and verification dates for the keys are in [research/keybind-layout-v4.md](research/keybind-layout-v4.md) (current, family blocks) and [research/keybind-layout.md](research/keybind-layout.md) (layout v3, pull walkthroughs).
- [zyaga/wow-forever-japanese](https://github.com/zyaga/wow-forever-japanese) (WFJ, GPLv2): the Japanese style guide and glossary (name policy, katakana terms), the bundled IPA font, the font-refusal fix (`docs/lessons/2026-09-14-bundled-font-refused-on-fresh-launch.md`), and the AddOns install path.

## Not verifiable offline: test in the game

These depend on the live Forever client. They are handled defensively in the code: calls are wrapped in pcall, and missing functions are skipped and reported. `/sensei verify` and `/sensei debug` print what the client actually does.

1. The legacy action and macro globals exist: `PickupSpell`, `PickupMacro`, `PlaceAction`, `GetActionInfo`, `GetActionText`, `CreateMacro`, `EditMacro`, `GetMacroIndexByName`.
2. The binding functions exist: `SetBinding`, `SaveBindings`, `GetBindingAction`, `GetCurrentBindingSet`. `SetBinding(key)` with no action unbinds the key.
3. Extra action bars turn on through `Settings.SetValue("PROXY_SHOW_ACTIONBAR_n")`. Since 0.7.0 the Ctrl keys fire from Action Bar 3 and the mouse buttons from Action Bar 6 once shown; `CTRL-1`-`CTRL-5` on Action Bar 3 take over from the stance bar. Applying the layout hides Action Bar 7 (`PROXY_SHOW_ACTIONBAR_7` false), leaves Action Bar 5 as it is, and **元に戻す** restores both.
4. Totem Bar behaviour: the resistance totems and Windwall are left there. The addon does not set the Totem Bar's totem sets (`SetMultiCastSpell` could not be verified offline), so the player sets them by hand.
5. **Verified in game (v0.1.0, 2026-11):** learning a new rank does **not** upgrade the bar button, so the addon does it (Layout.ApplyNewRanks). Still to check: `/cast <Name>` in a macro uses the highest rank. `/sensei verify` prints what each macro casts. If a macro casts a lower rank, the addon writes `Name(Rank N)` into it instead.
6. Talent reading through `C_Traits` (Forever's single class tree), opening the talent frame through `PlayerSpellsUtil`, and `IsSpellKnown` for talents with one rank.
7. `C_Spell.GetSpellLevelLearned` returns the trainer levels.
8. The `LEARNED_SPELL_IN_SKILL_LINE` event fires. The `SPELLS_CHANGED` spellbook diff is the fallback.
9. Font: the bundled IPA UI Gothic shows on a **fresh game launch**, not only after `/reload`. Every character the addon uses is checked offline against the font's glyph table (`make check`).
10. `math.atan2` is available for dragging the minimap button.
11. The 7 Wowhead-only spell IDs above.
12. *(0.8.1)* The Skyborne race id (`UnitRace` third value; expected 34 for a Windshaper, the Skysight race) and that the player knows Walk on Air 1259416. A known racial is planned even if the race id differs. `BUTTON3` has no default in `Bindings_Camelot.xml`; what it is bound to before the apply is checked with `GetBindingAction("BUTTON3")`.
12. Combat: cards hide, and bar or key changes wait until combat ends.
13. Potion macros (0.3.0): `/use item:<id>` in a character macro, `#showtooltip` picking up the item's icon, and the fixed icon (set by its file name, e.g. `INV_Potion_72`) when the bags have none. `C_Item.GetItemCount` and the required level from `C_Item.GetItemInfo`. `/sensei verify` prints each macro's body and the best item in the bags.
14. Layout v3 macros (0.4.0): `/stopcasting` in `FS_ES` lets Earth Shock interrupt at once; `FS_NSHW` casts Nature's Swiftness and Healing Wave in one press; `FS_HEALTH` uses a Healthstone else a Healing Potion. Whether Healthstones and potions share a cooldown, and the mana cost of Call of the Elements with a full set.
15. Paladin pack (0.6.0): the list in [research/keybind-layout-paladin.md](research/keybind-layout-paladin.md) "Verify in game" and the README checklist. Above all: the stance bar order and Ctrl+1-4 firing the auras, the 3 s taunt, `FS_OPEN` casting all three spells in one press, the help macros' self fallback, and the spells left out above.
16. Shaman Fire totems (0.6.1): Fire Nova (`simc` 408341: "enemies within … yd of your active Fire totem") hits the pack around a Searing or Magma Totem. Since 0.7.0 it is on Shift+F (Action Bar 2 button 9).
17. Layout v4 (0.7.0): the "Verify in game" list in [research/keybind-layout-v4.md](research/keybind-layout-v4.md) and README checklist items 43-48. Above all: Action Bar 6 shows and its mouse bindings fire (`PROXY_SHOW_ACTIONBAR_6`), Edit Mode keeps its position, Paladin auras cast from Action Bar 3 light up their button, the `CTRL-5` default, and **元に戻す** restoring Action Bar 6's visibility.
18. Paladin help macros and seals (0.7.1): README checklist items 49-50. Blessing of Protection now falls back to yourself (`simc` 1022: no attacks for its duration, Forbearance 25771 blocks Templar's Bulwark, Divine Shield and Divine Protection for 1 min). Seal of Justice is on Shift+4 (its Judgement stops fleeing for 10 s, `simc`/`wh_tt`); Seal of Light is clicked on Action Bar 6 (`moba`: "isn't usually necessary" for a tank). The client reports a macro button as `("macro", spellID, "spell")` (`Blizzard_ActionBar/Shared/ActionButton.lua`); the addon names it with `GetActionText`.
19. Save keys and Mouse 4/5 on unit frames (0.8.0): README checklist items 51-56. Lay on Hands, Blessing of Protection and Blessing of Sacrifice are on `Ctrl+Q/E/R`. The unit-frame fix rests on the Forever UI code (`reckhou/WoWBlzCode` @7245053): `PartyMemberFrame.lua`, `CompactUnitFrame.lua`, `PlayerFrame.lua` and `TargetFrame.lua` call `SecureUnitButton_OnLoad` without click arguments, so `SecureTemplates.lua` runs `RegisterForClicks("AnyUp")` and the frame takes Button4/5; `SecureUnitButton_OnClick` reads `SecureButton_GetModifiedAttribute(self, "type", button)` (suffix `4`/`5`, prefixes `shift-`/`ctrl-`), and `SECURE_ACTIONS.macro`/`spell` run the macro (with the hovered frame as `@mouseover`) or cast the spell on the frame's `unit`. Game Click Casting bindings come first (`C_ClickBindings`). To check in game: the portrait casts, left and right click unchanged, no blocked action in combat.
20. Arms Warrior (0.9.0): README checklist items 63-72 and [research/warrior-arms.md](research/warrior-arms.md) "In-game checks". Above all: `GetBonusBarOffset()` 1/2/3 in the three stances, with Action Bar 1 the same on every page after **すべて配置**; a stance macro from the wrong stance changes stance on the first press and casts on the second; `Ctrl+1-3` change stance from Action Bar 3; `FS_BANDAGE` picks a bandage you can use; Mortal Strike at 39; whether Victory Rush is in the spellbook; and **元に戻す** restoring every page.
21. Lower heal ranks (0.10.0): README checklist items 73-80 and [research/shaman-downranking.md](research/shaman-downranking.md) "Verify in game". Above all: `/cast Healing Wave(Rank N)` in `FS_HW_LO` casts that rank in both targeting modes, `#showtooltip` and `GetMacroSpell` show it, the macros are rewritten out of combat when a rank is learned or a level steps the lower rank up, and the tooltip heal of a lower rank matches the rule.
