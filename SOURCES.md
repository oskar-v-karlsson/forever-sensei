# Sources

Every fact in ForeverSensei comes from a **World of Warcraft: Forever** source: the Forever client data, Forever guides, or the Forever UI code. Classic and Retail pages were never used, because Forever changed many spells and talents.

All entries were checked on **2026-11-09** against client **1.60.1.70862**. Each data entry in `ForeverSensei/Data/Shaman/*.lua` has a `src` key, which points into `ns.Sources` in `Data/Shaman/Spells.lua`, and a `verified` date. `make check` fails if any entry is missing them.

## Game data and guides

| Key | Source | Used for |
|---|---|---|
| `simc` | [simc-forever SpellDataDump/shaman.txt](https://github.com/simulationcraft/simc-forever/blob/HEAD/SpellDataDump/shaman.txt), header "World of Warcraft 1.60.1.70862 Live". Parsed copy: `research/shaman_simc_1.60.1.70862.tsv` (made by `tools/research/parse_simc.py`) | 46 of the 53 spells: ID, English name, level, cooldown and cast-time facts; every talent (ID, row, column, max rank). `make check` cross-checks the data against the TSV. |
| `simc` ranks | Same dump, through `tools/research/gen_ranks.py` → `Data/Shaman/Ranks.lua` (2026-11-09) | Every rank's spell ID and trainer level, used for automatic rank upgrades. `make check` fails if the file is out of date or a rank does not match the dump (name and "Rank N"). |
| `wh_spell` | `https://www.wowhead.com/forever/spell=<id>` | 7 spells missing from the simc dump (see below) |
| `wh_abilities` | [Wowhead Forever: Restoration Shaman healer abilities](https://www.wowhead.com/forever/guide/classes/shaman/restoration/healer-abilities) | Ability use and priorities |
| `wh_overview` | [Wowhead Forever: Restoration Shaman overview](https://www.wowhead.com/forever/guide/classes/shaman/restoration/overview-pve-healer) | The healer role, strengths and weaknesses |
| `wh_talents` | [Wowhead Forever: Restoration Shaman talent builds](https://www.wowhead.com/forever/guide/classes/shaman/restoration/talent-builds-pve-healer) | Cross-check for the talent build |
| `moba` | [Mobalytics: WoW Forever Restoration Shaman guide](https://mobalytics.gg/wow-forever/classes/restoration-shaman-guide) (her guide) | Talent order (leveling path, final 0/5/46); healing, damage, totem and group tips |
| `ui` | Blizzard UI code for Forever 1.60.1 ([reckhou/WoWBlzCode](https://github.com/reckhou/WoWBlzCode), folder `Forever`) | Action bar slot numbers, binding names, the talent frame, events and API names |

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
- [reckhou/WoWBlzCode](https://github.com/reckhou/WoWBlzCode), `Forever`: the function and event lists, `Bindings.xml`, the MultiBar layout, the talent tree code, and the macro icon picker.
- [zyaga/wow-forever-japanese](https://github.com/zyaga/wow-forever-japanese) (WFJ, GPLv2): the Japanese style guide and glossary (name policy, katakana terms), the bundled IPA font, the font-refusal fix (`docs/lessons/2026-09-14-bundled-font-refused-on-fresh-launch.md`), and the AddOns install path.

## Not verifiable offline: test in the game

These depend on the live Forever client. They are handled defensively in the code: calls are wrapped in pcall, and missing functions are skipped and reported. `/sensei verify` and `/sensei debug` print what the client actually does.

1. The legacy action and macro globals exist: `PickupSpell`, `PickupMacro`, `PlaceAction`, `GetActionInfo`, `GetActionText`, `CreateMacro`, `EditMacro`, `GetMacroIndexByName`.
2. The binding functions exist: `SetBinding`, `SaveBindings`, `GetBindingAction`, `GetCurrentBindingSet`. `SetBinding(key)` with no action unbinds the key.
3. Extra action bars turn on through `Settings.SetValue("PROXY_SHOW_ACTIONBAR_2..4")`.
4. Totem Bar behaviour: the resistance totems and Windwall are left there.
5. **Verified in game (v0.1.0, 2026-11):** learning a new rank does **not** upgrade the bar button, so the addon does it (Layout.ApplyNewRanks). Still to check: `/cast <Name>` in a macro uses the highest rank. `/sensei verify` prints what each macro casts. If a macro casts a lower rank, the addon writes `Name(Rank N)` into it instead.
6. Talent reading through `C_Traits` (Forever's single class tree), opening the talent frame through `PlayerSpellsUtil`, and `IsSpellKnown` for talents with one rank.
7. `C_Spell.GetSpellLevelLearned` returns the trainer levels.
8. The `LEARNED_SPELL_IN_SKILL_LINE` event fires. The `SPELLS_CHANGED` spellbook diff is the fallback.
9. Font: the bundled IPA UI Gothic shows on a **fresh game launch**, not only after `/reload`. Every character the addon uses is checked offline against the font's glyph table (`make check`).
10. `math.atan2` is available for dragging the minimap button.
11. The 7 Wowhead-only spell IDs above.
12. Combat: cards hide, and bar or key changes wait until combat ends.
