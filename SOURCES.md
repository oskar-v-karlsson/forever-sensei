# Sources

Every fact in ForeverSensei comes from a **World of Warcraft: Forever** source: the Forever client data, Forever guides, or the Forever UI code. Classic and Retail pages were never used, because Forever changed many spells and talents.

All entries were checked on **2026-11-09** against client **1.60.1.70862**. Each data entry in `ForeverSensei/Data/Shaman/*.lua` has a `src` key, which points into `ns.Sources` in `Data/Shaman/Spells.lua`, and a `verified` date. `make check` fails if any entry is missing them.

## Game data and guides

| Key | Source | Used for |
|---|---|---|
| `simc` | [simc-forever SpellDataDump/shaman.txt](https://github.com/simulationcraft/simc-forever/blob/HEAD/SpellDataDump/shaman.txt), header "World of Warcraft 1.60.1.70862 Live". Parsed copy: `research/shaman_simc_1.60.1.70862.tsv` (made by `tools/research/parse_simc.py`) | 46 of the 53 spells: ID, English name, level, cooldown and cast-time facts; every talent (ID, row, column, max rank). `make check` cross-checks the data against the TSV. |
| `simc` ranks | Same dump, through `tools/research/gen_ranks.py` → `Data/Shaman/Ranks.lua` (2026-11-09) | Every rank's spell ID and trainer level, used for automatic rank upgrades. `make check` fails if the file is out of date or a rank does not match the dump (name and "Rank N"). |
| `wh_spell` | `https://www.wowhead.com/forever/spell=<id>` | 7 spells missing from the simc dump (see below) |
| `wh_item` | `https://www.wowhead.com/forever/item=<id>` and the Forever potion and elixir lists ([potions](https://www.wowhead.com/forever/items/consumables/potions), [elixirs](https://www.wowhead.com/forever/items/consumables/elixirs)) | Potion and elixir IDs, names, required levels and icons in `Data/Items.lua` (see below) |
| `wh_abilities` | [Wowhead Forever: Restoration Shaman healer abilities](https://www.wowhead.com/forever/guide/classes/shaman/restoration/healer-abilities) | Ability use and priorities |
| `wh_overview` | [Wowhead Forever: Restoration Shaman overview](https://www.wowhead.com/forever/guide/classes/shaman/restoration/overview-pve-healer) | The healer role, strengths and weaknesses |
| `wh_talents` | [Wowhead Forever: Restoration Shaman talent builds](https://www.wowhead.com/forever/guide/classes/shaman/restoration/talent-builds-pve-healer) | Cross-check for the talent build |
| `moba` | [Mobalytics: WoW Forever Restoration Shaman guide](https://mobalytics.gg/wow-forever/classes/restoration-shaman-guide) (the guide this build follows) | Talent order (leveling path, final 0/5/46); healing, damage, totem and group tips |
| `ui` | Blizzard UI code for Forever 1.60.1 ([reckhou/WoWBlzCode](https://github.com/reckhou/WoWBlzCode), folder `Forever`) | Action bar slot numbers, binding names, the talent frame, events and API names. Action Bar 5 (MultiBarLeft) is page 4 (slots 37-48), binding `MULTIACTIONBAR4BUTTON<n>`, shown with `PROXY_SHOW_ACTIONBAR_5` (`Blizzard_ActionBar/Shared/MultiActionBars.xml`, checked 2026-11-10). |

Wowhead and Mobalytics pages block scripted downloads (HTTP 403), so they were read in a browser.

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

Left out on purpose: Discolored Healing Potions (they heal, then return 75% as poison or disease damage), the PvP Combat potions (18839, 18841, need a PvP rank), the Restored potions (282011, 282013) and draughts.

## Where sources disagree

| Topic | Disagreement | Used |
|---|---|---|
| Totemic Call | Wowhead: 1 min cooldown, placed at a target location. simc and Mobalytics: 30 s cooldown, at the shaman's own location. | simc (client data) |
| Riptide | Wowhead: an initial heal plus a heal over time, 6 s cooldown. simc and Mobalytics: heal over time only, 12 s cooldown. | simc. The texts say "heal over 15 seconds" and "12-second cooldown". |
| Purge | Wowhead: removes 2 effects. simc: the number varies. | The text says "removes magic effects" with no count. |
| Level-60 talent build | Wowhead: 0/17/34. Mobalytics: 0/5/46. | Mobalytics, as the user asked. It was cross-checked against simc rows, columns, max ranks and requirements. |

## Addon API research (Forever 12.x client)

Forever runs the modern 12.x UI ("Camelot", `## Interface: 16001`, `WOW_PROJECT_ID == 1`), not the Classic API.

- [warcraft.wiki.gg](https://warcraft.wiki.gg/): the API reference, including how secret values work in combat in 12.x.
- [realworldbuilder/wowwrapped docs/addon-api.md](https://github.com/realworldbuilder/wowwrapped/blob/main/docs/addon-api.md): notes on the Forever addon API.
- [reckhou/WoWBlzCode](https://github.com/reckhou/WoWBlzCode), `Forever`: the function and event lists, `Bindings.xml` (including `MULTIACTIONBAR4BUTTON` for Action Bar 5, which holds the Ctrl and mouse keys, and `MULTIACTIONBAR5BUTTON`/`MULTIACTIONBAR6BUTTON` for Action Bars 6 and 7, which layout 3 used and 0.4.1 hides), the MultiBar layout and pages, the `BUTTON4`/`BUTTON5` key names (`Blizzard_FrameXML/BindingUtil`), the talent tree code, and the macro icon picker. The macro limit, `MAX_CHARACTER_MACROS = 30` (and `MAX_ACCOUNT_MACROS = 120`), is in `Blizzard_APIDocumentationGenerated/MacroConstantsDocumentation.lua`; the addon uses 13 character macros. Details and verification dates for the layout v3 keys are in [research/keybind-layout.md](research/keybind-layout.md).
- [zyaga/wow-forever-japanese](https://github.com/zyaga/wow-forever-japanese) (WFJ, GPLv2): the Japanese style guide and glossary (name policy, katakana terms), the bundled IPA font, the font-refusal fix (`docs/lessons/2026-09-14-bundled-font-refused-on-fresh-launch.md`), and the AddOns install path.

## Not verifiable offline: test in the game

These depend on the live Forever client. They are handled defensively in the code: calls are wrapped in pcall, and missing functions are skipped and reported. `/sensei verify` and `/sensei debug` print what the client actually does.

1. The legacy action and macro globals exist: `PickupSpell`, `PickupMacro`, `PlaceAction`, `GetActionInfo`, `GetActionText`, `CreateMacro`, `EditMacro`, `GetMacroIndexByName`.
2. The binding functions exist: `SetBinding`, `SaveBindings`, `GetBindingAction`, `GetCurrentBindingSet`. `SetBinding(key)` with no action unbinds the key.
3. Extra action bars turn on through `Settings.SetValue("PROXY_SHOW_ACTIONBAR_2..5")`, and the Ctrl keys and mouse buttons fire from Action Bar 5 once it is shown. `CTRL-1` on Action Bar 5 takes over from the stance bar's first button. Applying the layout hides Action Bars 6 and 7 (`PROXY_SHOW_ACTIONBAR_6/7` false), and **元に戻す** shows them again.
4. Totem Bar behaviour: the resistance totems and Windwall are left there. The addon does not set the Totem Bar's totem sets (`SetMultiCastSpell` could not be verified offline), so the player sets them by hand.
5. **Verified in game (v0.1.0, 2026-11):** learning a new rank does **not** upgrade the bar button, so the addon does it (Layout.ApplyNewRanks). Still to check: `/cast <Name>` in a macro uses the highest rank. `/sensei verify` prints what each macro casts. If a macro casts a lower rank, the addon writes `Name(Rank N)` into it instead.
6. Talent reading through `C_Traits` (Forever's single class tree), opening the talent frame through `PlayerSpellsUtil`, and `IsSpellKnown` for talents with one rank.
7. `C_Spell.GetSpellLevelLearned` returns the trainer levels.
8. The `LEARNED_SPELL_IN_SKILL_LINE` event fires. The `SPELLS_CHANGED` spellbook diff is the fallback.
9. Font: the bundled IPA UI Gothic shows on a **fresh game launch**, not only after `/reload`. Every character the addon uses is checked offline against the font's glyph table (`make check`).
10. `math.atan2` is available for dragging the minimap button.
11. The 7 Wowhead-only spell IDs above.
12. Combat: cards hide, and bar or key changes wait until combat ends.
13. Potion macros (0.3.0): `/use item:<id>` in a character macro, `#showtooltip` picking up the item's icon, and the fixed icon (set by its file name, e.g. `INV_Potion_72`) when the bags have none. `C_Item.GetItemCount` and the required level from `C_Item.GetItemInfo`. `/sensei verify` prints each macro's body and the best item in the bags.
14. Layout v3 macros (0.4.0): `/stopcasting` in `FS_ES` lets Earth Shock interrupt at once; `FS_NSHW` casts Nature's Swiftness and Healing Wave in one press; `FS_HEALTH` uses a Healthstone else a Healing Potion. Whether Healthstones and potions share a cooldown, and the mana cost of Call of the Elements with a full set.
