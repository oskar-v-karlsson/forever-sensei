# Downranked heals for Restoration (proposal v2, shaman pack)

Status: **proposal for approval, revision 2**. Nothing here is built. Once Oskar approves it, a build task turns it
into Restoration layout 9 (`ForeverSensei_Shaman`). The Paladin and Warrior packs do not change.

## Why

Erika, via Oskar, verbatim: "For the restoration shaman profile, I think we need to consider lower ranks of the
healing spells. When playing in group it's important to also have lower ranks of heals to conserve mana."

Revision 1 (3defa9f) put the cheap rank on **Alt + the same heal key**. **Oskar rejected that.** His requirements for
this revision, relayed by the coordinator:
- Each heal's ranks sit on **neighbouring keys in the same row** (e.g. 1-2 or 1-3), like a family block. No modifier.
- The rank on each key **changes by itself** with her level and her highest known rank: a relative rule (max, max − 2,
  a third key only if justified), recomputed when she learns a rank. It reuses the rank-upgrade, keepRank and
  CheckMacroRank paths.
- Heals are her main job in groups, so the heal ranks get a strong block (plain 1-5 is the first candidate), and the
  damage spells move. A learned spell's key never moves, except in this one migration.

Short answer, explained below:
- Forever **does** penalise ranks far below your level, with a new rule: a rank keeps its full Spell Healing bonus for
  17 levels after you learn it, then loses 5% per level (Part 1, unchanged from revision 1).
- **Healing Wave gets 2 keys** (top rank, and "lower" = top − 2, one rank higher while that rank would keep < 90% of
  its bonus). **Chain Heal gets 2** (top, and top − 1 from level 46). **Lesser Healing Wave gets 1** (the emergency
  heal). A third Healing Wave key is **not** justified: from level 26 on, "top − 4" with the same 90% rule picks the
  same rank as "top − 2" at every level (Part 2).
- **Recommended grid (option 1):** plain **1 Healing Wave, 2 Healing Wave lower, 3 Chain Heal, 4 Chain Heal lower**;
  Q Earth Shock and E Lesser Healing Wave keep their keys; the damage spells take R / F (Flame Shock, Lightning Bolt)
  and the rare ones go to Ctrl+4 / Ctrl+5 (Purge, Chain Lightning), the only spare keys. Frost Shock keeps 5.
- Each lower-rank key is an **always-macro** (`FS_HW_LO`, `FS_CH_LO`) naming `Healing Wave(Rank N)`, in both targeting
  modes. 13 → 15 of the 30 character macros. Nature's Swiftness keeps the top rank. Portrait click-cast does not
  change.

## Sources

Checked on **2026-11-15**. Keys used below.

| Key | Source | Used for |
|---|---|---|
| `dev1001` | Blizzard, WoW Forever development notes, 2026-10-01, https://us.forums.blizzard.com/en/wow/t/2360696/4 ("User Interface") | Downranking penalty exists; the Spell Damage/Healing tooltip explains it; Rank 1 Frostbolt at 60 has 0% Frostbite chance; build 1.60.1.70291 |
| `dev1016` | Same thread, notes of 2026-10-16 (posts up to 2026-11-04 scanned, no later retune) | Touch of the Dead exempt from the "decreased multiplier"; the new mage spell "despite the penalization of down-ranking" |
| `fc` | foreverchanges.pro/downranking (Vektor, updated 2026-10-16) | The community formula, beta measurements (DoubleZug video 2026-10-03 and sheet, Whiteleaf, holypalaswe), `/cast Healing Wave(Rank 3)` works, "Show All Spell Ranks" |
| `rl` | realmlist.org Forever briefing, 2026-10-12 | Same formula, second write-up |
| `wiki` | warcraft.wiki.gg/wiki/Downranking | Classic, TBC 2.2 and WotLK rules, for comparison only |
| `simc` | simc-forever @3c1d319e `SpellDataDump/shaman.txt` (client 1.60.1.70862) and `research/shaman_simc_1.60.1.70862.tsv` | Rank levels, mana, base heal, points per level, coefficients, Healing Way |
| `wh_tt` | Wowhead Forever tooltips, `nether.wowhead.com/forever/tooltip/spell/<id>` | In-game tooltip numbers (HW R3 547, HW R8 10395, CH R1 1064) |
| `ui` | reckhou/WoWBlzCode @7245053, `Forever/BlizzardInterfaceCode/Interface/AddOns` | Self-cast on key presses (a note), macro limit, unit-frame click-cast |
| `f1393058` | us.forums.blizzard.com/en/wow/t/1393058 (Nov 2022, 10.0 client) | A Shift+1 binding makes macros see `[mod:shift]`; the Alt self-cast key breaks Alt-bound macros |
| `f2371681` | us.forums.blizzard.com/en/wow/t/2371681 | Heals on party members of a different level land under the tooltip since the Oct 1 build |

The coordinator's simc facts, re-checked against `simc`:

| Spell | Ranks | Learned at | Mana | Note |
|---|---|---|---|---|
| Healing Wave | 10 (331, 332, 547, 913, 939, 959, 8005, 10395, 10396, 25357) | 1, 6, 12, 18, 24, 32, 40, 48, 56, 60 | 25 → 620 | **confirmed** |
| Lesser Healing Wave | 6 (8004, 8008, 8010, 10466, 10467, 10468) | 20, 28, 36, 44, 52, 60 | 105 → 380 | **confirmed** |
| Chain Heal | 3 (1064, 10622, 10623) | 40, 46, 54 | 260 / 315 / 405 | **confirmed** |
| Riptide | 3 (408521, 1239242, 1239243) | 40, 50, 60 | 150 / 180 / 230 | **confirmed** (talent, 12 s cooldown) |

# Part 1: The downranking penalty in Forever

## What Blizzard says (`dev1001`, `dev1016`)

The 2026-10-01 notes add a line to the Spell Damage/Healing tooltip on the character sheet: spell ranks "vastly below
your current level" get less benefit from Spell Damage/Healing, and have a reduced chance to trigger class abilities
and talents. A developers' note gives one data point: Rank 1 Frostbolt at level 60 has a 0% chance to apply
Frostbite. It arrived in beta build 1.60.1.70291. The 10-16 notes confirm it is still live (Touch of the Dead was
exempted from "a decreased multiplier when a lower ranked spell is used"). **Blizzard gives no numbers.**

## The measured rule (`fc`, `rl`)

    share of the Spell Healing bonus = clamp(1 − (L − 17 − T) × 0.05, 0, 1)
    L = your level, T = the level the rank is learned at

- Full bonus for 17 levels after the rank's learn level, −5% per level from the 18th, nothing after 37 levels.
- **No Classic sub-level-20 cut.** In Forever every rank's coefficient is cast time / 3.5. `simc` agrees: Healing Wave
  R1 has coefficient 0.429 (1.5 s cast), R2 0.571 (2 s), R3 0.714 (2.5 s), R4 and up 0.857 (3 s); Lesser Healing
  Wave 0.429 (1.5 s); Chain Heal 0.714 (2.5 s).
- Base healing is **not** penalised. Only the Spell Healing part shrinks.

How sure we are:
- **Confirmed:** that a penalty exists, and that it depends on how far the rank is below your level (`dev1001`).
- **Measured, medium confidence:** the 17-level grace and −5% per level, from beta tests between levels 18 and 30
  only (DoubleZug, Whiteleaf, holypalaswe in `fc`). Above 30 it is extrapolated.
- **Known stray:** Healing Wave R1 kept 100% at level 20, then lost 6–8 points per level in the tests. Our rule never
  picks R1 above level 17, so this does not matter for the table.
- The proposal is built so a wrong guess costs little (Part 2, "safety margin"), and an in-game check settles it.

## How it compares (`wiki`)

| Version | Rule | Forever? |
|---|---|---|
| Classic | Ranks learned below 20: coefficient × (1 − (20 − T) × 0.0375) | **no**, not in Forever |
| TBC 2.2 | × (rank's max level + 6) / your level | no |
| WotLK | × (22 + rank's max level − L) / 20 | no |
| **Forever** | 17-level grace, then −5% per level (`fc`) | **yes** |

The closest is WotLK. A rule that "uses the highest rank whose max level is close to yours" works the same way here.

## Healing Way (29206)

`simc`: "Increases the amount healed by your Healing Wave spell by $m1%", Add Percent Modifier on all ten Healing
Wave ranks, 8 / 17 / 25% for 1 / 2 / 3 points (class tree, row 5, column 10). Her talent plan takes it at 31–33
(`Data/Restoration/Talents.lua:26,48`).

It is a **flat bonus with no stacks**. In Classic, Healing Way was a stacking buff on the target, which made "Rank 1
Healing Wave to keep the stacks up" worth doing. **That trick does not apply in Forever.** The doc and the guide must
not suggest it.

## One more Forever fact that matters

Base heal per mana **rises** with rank in Forever (Forever lowered most low ranks' base values). With no +healing
gear, Healing Wave R1 heals 1.56 per mana and R10 2.60. So a low rank only saves mana in two ways:
1. it **overheals less** when the target is missing only a little, which is the main reason in a group;
2. its share of **Spell Healing** is bigger compared to its cost. This grows as she finds +healing gear.

`fc`: at level 30 with 200 Spell Healing, Healing Wave R3 heals 30% more per mana than R5. At level 60 a top-rank-only
healer loses about 2% HPS in DoubleZug's sim; in his Chain Heal spam sim R2 gave 955 HPS against 932 for the top
rank. Water Shield returning 2% of maximum mana on a critical heal slightly favours cheap, frequent casts.


# Part 2: Which heals get several keys, and the rule

## Keys per heal

| Heal | Keys | Rule | Why |
|---|---|---|---|
| Healing Wave | **2**: top, lower | top = highest known rank; lower = top − 2, stepped up while < 90% | Her main heal and her biggest mana use. The lower rank is 38–83% of the top heal for much less mana |
| Chain Heal | **2**: top, lower (from 46) | lower = top − 1 | Only 3 ranks. At 40–45 there is no lower rank. R2 vs R3: 86–90% of the heal for 78% of the mana |
| Lesser Healing Wave | **1** | top | The emergency heal: when she presses it she needs the full amount. Top − 1 is ~80% of the heal for ~77% of the mana, about 5% better per mana (open question 4) |
| Riptide | 1 (Mouse4, unchanged) | top | 12 s cooldown, so its mana is small; a cheap rank would waste the cooldown |

### Why not a third Healing Wave key

With the 90% rule, only the ranks learned in the last ~19 levels are worth casting, and Healing Wave gets a new rank
every 6–8 levels, so at most levels only **three** ranks qualify: top, top − 1 and top − 2. A third key ("low" =
top − 4, stepped up the same way) lands on the same rank as "lower":

| Level | Ranks keeping ≥ 90% | top − 2 (stepped up) | top − 4 (stepped up) |
|---|---|---|---|
| 18–20 | R1–R4 | R2 | R1 |
| 21–23 | R2–R4 | R2 | R2 |
| 24–25 | R2–R5 | R3 | R2 |
| **26–60** | 2 or 3 ranks | R3 … R8 | **same as top − 2 at every level** |

So a third key would be a duplicate of key 2 for Erika (level 26) from now on. Two keys per heal it is. Allowing a
deeper penalty (e.g. 75%) for a third key would cast ranks that lose a quarter of her gear's healing, which is the part
of the curve nobody measured above level 30 (Part 1).

## The rule

A relative rule that follows her level and her **known** ranks (`C_SpellBook.IsSpellKnown` per rank ID, `Spells.lua`
`KnownRank`). Fixed ranks would go stale every few levels and would need a data edit for every rank she skips at the
trainer.

- **Top key:** the highest known rank. Exactly today's behaviour (the mouseover macro names the plain spell, the client
  casts the highest rank; in click mode the plain spell is upgraded by `UpgradeRanks`).
- **Lower key:** take her known ranks in order, go `offset` steps down from the top (2 for Healing Wave, 1 for Chain
  Heal, never below the first known rank). While that rank keeps **less than 90%** of its Spell Healing bonus at her
  level, go one rank up. If that ends on the top rank, the lower key has nothing to cast (Part 3, "empty lower key").
- Counting in **known** ranks means a skipped trainer rank does not leave a gap: knowing R1–R5 and R7 at 40, top = R7,
  two down = R4, R4 keeps 75% → R5.
- Healing Wave's lower key starts at level **10** (open question 5): at 6–9 the only lower rank is R1, which saves 20
  mana a cast.
- The lower rank changes in two ways: **when she learns a rank** (it moves up one, like the top key) and **on a level-up
  alone**, when the 90% step-up kicks in (e.g. 37 → 38: R4 → R5). So the refresh runs on both (Part 3).

Why "top − 2" and not "the most mana-efficient rank": the most efficient rank depends on her gear and on overheal,
which the addon cannot see in 12.x (secret values in combat). Two ranks below the top keeps the heal big enough to be
useful on a party member taking steady hits (38–83% of the top rank), and the 90% step-up keeps it inside the measured
part of the penalty curve. **Safety margin:** even if the real penalty were twice as steep as `fc` says, the chosen rank
would still keep at least 80%.

## Per-level table

Cell: `rank · mana · base heal at that level (no +healing) · heal per mana with the assumed Spell Healing`.
`(95%)` / `(90%)` = the share of the bonus the lower rank keeps; no mark = 100%. Keys are those of the recommended grid
(option 1, Part 3).

Assumptions:
- Spell Healing follows the ramp in `fc`: 100 at 20, 200 at 30, 860 at 60, linear in between, and 5 per level below
  20 (50 at 10). Her real number is on her character sheet.
- Base heal at level L = base + points per level × (min(L, rank max level) − T), from `simc`. The in-game tooltip
  rounds to a range and scales slightly differently (`wh_tt`: HW R3 547 shows 127–150 for 80 mana; `simc` base 131),
  so the numbers are for comparison, not exact.
- No talents (Improved Healing Wave, Tidal Focus, Healing Way and Purification change all ranks alike), no critical
  heals, no overheal. **With 0 Spell Healing every column is base heal ÷ mana, and the top rank is the most efficient
  per mana**; the lower rank then helps only by overhealing less.
- All ranks trained. If she skips a rank, the rule uses the ranks she knows.

| Levels | HW top (1) | HW lower (2) | CH top (3) | CH lower (4) | LHW (E) |
|---|---|---|---|---|---|
| 10–11 | R2 · 45 · 75 · 2.30 | R1 · 25 · 42 · 2.53 | – | – | – |
| 12–17 | R3 · 80 · 131 · 2.17 | R1 · 25 · 42 · 2.70 | – | – | – |
| 18–19 | R4 · 155 · 256 · 2.15 | R2 · 45 · 76 · 2.83 | – | – | – |
| 20–23 | R4 · 155 · 261 · 2.23 | R2 · 45 · 76 · 2.96 | – | – | R1 · 105 · 153 · 1.87 |
| 24–27 | R5 · 200 · 342 · 2.31 | R3 · 80 · 138 · 2.98 | – | – | R1 · 105 · 160 · 2.09 |
| 28–29 | R5 · 200 · 353 · 2.54 | R3 · 80 · 138 · 3.34 | – | – | R2 · 145 · 224 · 2.08 |
| 30 | R5 · 200 · 356 · 2.63 | R3 · 80 · 138 · 3.43 (95%) | – | – | R2 · 145 · 228 · 2.17 |
| 31 | R5 · 200 · 356 · 2.73 | R3 · 80 · 138 · 3.51 (90%) | – | – | R2 · 145 · 230 · 2.25 |
| 32–35 | R6 · 265 · 484 · 2.62 | R4 · 155 · 268 · 3.07 | – | – | R2 · 145 · 232 · 2.32 |
| 36 | R6 · 265 · 497 · 2.95 | R4 · 155 · 268 · 3.47 (95%) | – | – | R3 · 185 · 304 · 2.41 |
| 37 | R6 · 265 · 500 · 3.03 | R4 · 155 · 268 · 3.49 (90%) | – | – | R3 · 185 · 306 · 2.48 |
| 38–39 | R6 · 265 · 500 · 3.10 | R5 · 200 · 356 · 3.39 | – | – | R3 · 185 · 309 · 2.54 |
| 40–41 | R7 · 340 · 685 · 3.07 | R5 · 200 · 356 · 3.58 | R1 · 260 · 251 · 2.12 | – | R3 · 185 · 314 · 2.67 |
| 42 | R7 · 340 · 693 · 3.21 | R5 · 200 · 356 · 3.67 (95%) | R1 · 260 · 256 · 2.26 | – | R3 · 185 · 316 · 2.79 |
| 43 | R7 · 340 · 697 · 3.27 | R5 · 200 · 356 · 3.65 (90%) | R1 · 260 · 258 · 2.33 | – | R3 · 185 · 316 · 2.84 |
| 44–45 | R7 · 340 · 701 · 3.34 | R6 · 265 · 500 · 3.53 | R1 · 260 · 261 · 2.40 | – | R4 · 235 · 426 · 2.74 |
| 46–47 | R7 · 340 · 704 · 3.46 | R6 · 265 · 500 · 3.67 | R2 · 315 · 335 · 2.31 | R1 · 260 · 264 · 2.53 | R4 · 235 · 432 · 2.85 |
| 48–49 | R8 · 440 · 972 · 3.37 | R6 · 265 · 500 · 3.82 | R2 · 315 · 341 · 2.43 | R1 · 260 · 264 · 2.65 | R4 · 235 · 438 · 2.95 |
| 50 | R8 · 440 · 981 · 3.48 | R6 · 265 · 500 · 3.85 (95%) | R2 · 315 · 346 · 2.55 | R1 · 260 · 264 · 2.77 | R4 · 235 · 441 · 3.04 |
| 51 | R8 · 440 · 986 · 3.53 | R6 · 265 · 500 · 3.82 (90%) | R2 · 315 · 349 · 2.61 | R1 · 260 · 264 · 2.83 | R4 · 235 · 441 · 3.09 |
| 52–53 | R8 · 440 · 991 · 3.58 | R7 · 340 · 704 · 3.80 | R2 · 315 · 349 · 2.66 | R1 · 260 · 264 · 2.89 | R5 · 305 · 608 · 2.96 |
| 54–55 | R8 · 440 · 996 · 3.68 | R7 · 340 · 704 · 3.91 | R3 · 405 · 490 · 2.49 | R2 · 315 · 349 · 2.76 | R5 · 305 · 615 · 3.04 |
| 56–57 | R9 · 560 · 1344 · 3.58 | R7 · 340 · 704 · 4.02 | R3 · 405 · 497 · 2.59 | R2 · 315 · 349 · 2.86 | R5 · 305 · 622 · 3.13 |
| 58 | R9 · 560 · 1355 · 3.67 | R7 · 340 · 704 · 4.03 (95%) | R3 · 405 · 503 · 2.68 | R2 · 315 · 349 · 2.96 | R5 · 305 · 626 · 3.20 |
| 59 | R9 · 560 · 1360 · 3.71 | R7 · 340 · 704 · 3.97 (90%) | R3 · 405 · 506 · 2.73 | R2 · 315 · 349 · 3.01 | R5 · 305 · 626 · 3.23 |
| 60 | R10 · 620 · 1615 · 3.79 | R8 · 440 · 996 · 3.94 | R3 · 405 · 506 · 2.77 | R2 · 315 · 349 · 3.06 | R6 · 380 · 820 · 3.13 |

Notes:
- Up to level 23 the lower Healing Wave is also **faster** (R1 1.5 s, R2 2 s), and at 24–31 R3 is 2.5 s against 3 s,
  because Forever ties low-rank coefficients to shorter casts. After Improved Healing Wave (her talents at 10–14) the
  top rank is shorter too.
- The lower Healing Wave is 38% of the top rank at 60 and up to 83% earlier: on a tank taking big hits it is too small,
  which is what the coaching says (Part 5).
- The "− 2" rank keeps 90–100% of the bonus at every level, so the measured part of the rule is all that matters.

## How a lower key moves as she levels

Erika is level 26. All ranks trained on time; option 1 keys.

| Event | 1 HW top | 2 HW lower | 3 CH top | 4 CH lower | Toast (one Undo button for the whole toast) |
|---|---|---|---|---|---|
| Level 26 (today, after the migration) | R5 | R3 | – *(40)* | – *(46)* | – |
| 32: learns HW R6 | R6 | R3 → **R4** | – | – | "Healing Wave (Rank 6) を覚えた。" + "2: Healing Wave Rank 3 → Rank 4" |
| 38: level-up only | R6 | R4 → **R5** (R4 would keep 85%) | – | – | "2: Healing Wave Rank 4 → Rank 5" |
| 40: learns HW R7 and Chain Heal | R7 | R5 (top − 2 = R5, no change) | **R1** (new-skill card, as today) | – (one rank) | "Healing Wave (Rank 7) を覚えた。" |
| 44: level-up only | R7 | R5 → **R6** | R1 | – | "2: Healing Wave Rank 5 → Rank 6" |
| 46: learns CH R2 | R7 | R6 | R2 | **R1**: a card with 配置する for key 4 (first time) | "Chain Heal (Rank 2) を覚えた。" |
| 48: learns HW R8 | R8 | R6 (no change) | R2 | R1 | "Healing Wave (Rank 8) を覚えた。" |
| 52: level-up only | R8 | R6 → **R7** | R2 | R1 | "2: Healing Wave Rank 6 → Rank 7" |
| 54: learns CH R3 | R8 | R7 | R3 | R1 → **R2** | "Chain Heal (Rank 3) を覚えた。" + "4: Chain Heal Rank 1 → Rank 2" |
| 56: learns HW R9 | R9 | R7 (no change) | R3 | R2 | "Healing Wave (Rank 9) を覚えた。" |
| 60: learns HW R10 | R10 | R7 → **R8** | R3 | R2 | "Healing Wave (Rank 10) を覚えた。" + "2: Healing Wave Rank 7 → Rank 8" |

- The **key never moves**; only the rank behind key 2 or key 4 changes, and the toast says so.
- **Undo** on the toast restores the top key as today (click mode: the old plain rank, kept by `keepRank`) and **pins**
  the lower key to its old rank. The pin holds through level-up step-ups. It ends when she learns that heal's next
  rank (the rule runs again and the toast offers Undo again) or presses すべて配置. The guide's key page and verify show
  "(kept)" next to a pinned rank.
- The first time a lower key has something to cast (Healing Wave at 10, Chain Heal at 46), it is **not placed
  silently**: a new-skill card ("Healing Wave の低いランク", key 2 / key 4) offers 配置する, like any new spell. Erika
  is past 10, so the migration places key 2 directly.

# Part 3: The grid

Reach tiers are from the shaman doc (small hands, WASD): tier 1 Mouse4/5, Q, E, R, F; tier 2 1-3, Shift+Q/E/R/F,
Shift+Mouse; tier 3 4, Z, Shift+1-3, Ctrl+Q/E/R, Ctrl+Mouse; tier 4 X, C, 5, Shift+Z/X/C, Shift+4, Ctrl+Z/C/F;
tier 5 Shift+5, Ctrl+X, Ctrl+1-5. Heals are cast standing still, so their reach matters less than an instant's
(`research/keybind-layout.md:56,217`).

## The constraint

The plain row has 12 keys (1-5, Q, E, R, F, Z, X, C) and all 12 are used in layout 8. The two new lower keys need two
more plain keys, so two plain spells must leave the row. Shift and Ctrl Q/E/R/F and Z/X/C are full (element blocks,
`research/keybind-layout-v4.md` S2); the only spare keys anywhere are **Ctrl+4 and Ctrl+5** (tier 5, next to the
travel family). The two rarest plain spells are Chain Lightning (no in most pulls; 2.5 s and expensive for a healer)
and Purge (0-1 a pull, medium urgency) (`research/keybind-layout.md` frequency table). Every option below sends those
two to Ctrl+4 / Ctrl+5.

## Option 1 (recommended): heal ranks on 1-4, Q/E keep the emergency pair

| Key | Plain | Change |
|---|---|---|
| 1 | Healing Wave (top) | was F |
| 2 | Healing Wave (lower) | new |
| 3 | Chain Heal (top) | was R |
| 4 | Chain Heal (lower) | new |
| 5 | Frost Shock | unchanged |
| Q | Earth Shock | unchanged |
| E | Lesser Healing Wave | unchanged |
| R | Flame Shock | was 1 |
| F | Lightning Bolt | was 2 |
| Ctrl+4 / Ctrl+5 | Purge / Chain Lightning | were 4 / 3 |

- The two **rank pairs** sit on neighbouring digits, top rank on the left: 1-2 Healing Wave, 3-4 Chain Heal.
- **The emergency keys do not change.** Q (interrupt) and E (Lesser Healing Wave) are the two "very high" urgency
  presses; she keeps them exactly where her fingers know them.
- Every spell pressed in most pulls keeps a top key (tiers 1-2), except Chain Heal lower (4, tier 3).
- Flame Shock (instant, also while moving) and Lightning Bolt get tier 1; they are the damage she weaves in when healing
  is light.

## Option 2: all heals on 1-5, damage on Q/E/R/F

1 Healing Wave, 2 Healing Wave lower, 3 Lesser Healing Wave, 4 Chain Heal, 5 Chain Heal lower; Q Earth Shock,
E Flame Shock, R Lightning Bolt, F Frost Shock; Ctrl+4 Purge, Ctrl+5 Chain Lightning.

- The cleanest rule to teach: **digits heal, letters hurt** (the interrupt is a letter too).
- But Chain Heal, her most pressed heal at 60 (4-8 a trash pull), drops to 4 / 5 (tiers 3 / 4), and Lesser Healing
  Wave, the emergency heal, leaves E for 3 (tier 2). 8 spells move.

## Option 3: Healing Wave ranks on E-R, Lesser Healing Wave on F, Chain Heal on 1-2

Q Earth Shock, E Healing Wave, R Healing Wave lower, F Lesser Healing Wave; 1 Chain Heal, 2 Chain Heal lower,
3 Flame Shock, 4 Lightning Bolt, 5 Frost Shock; Ctrl+4 Purge, Ctrl+5 Chain Lightning.

- The best heal reach: every heal key is tier 1 or 2.
- But it **swaps E and F**. Her habit "E = emergency heal" would cast a 3 s Healing Wave (2.5 s with talents) in the
  moment she needs 1.5 s; that is the dangerous direction for a muscle-memory mistake. Keys 1-2 stay empty until 40.

## Reach compared (spells pressed in combat)

| Spell | Layout 8 | Option 1 | Option 2 | Option 3 |
|---|---|---|---|---|
| Healing Wave top | F (1) | 1 (2) | 1 (2) | E (1) |
| Healing Wave lower | – | 2 (2) | 2 (2) | R (1) |
| Chain Heal top | R (1) | 3 (2) | 4 (3) | 1 (2) |
| Chain Heal lower | – | 4 (3) | 5 (4) | 2 (2) |
| Lesser Healing Wave | E (1) | **E (1)** | 3 (2) | F (1), **swapped** |
| Earth Shock | Q (1) | Q (1) | Q (1) | Q (1) |
| Flame Shock | 1 (2) | R (1) | E (1) | 3 (2) |
| Lightning Bolt | 2 (2) | F (1) | R (1) | 4 (3) |
| Frost Shock | 5 (4) | 5 (4) | F (1) | 5 (4) |
| Purge | 4 (3) | Ctrl+4 (5) | Ctrl+4 (5) | Ctrl+4 (5) |
| Chain Lightning | 3 (2) | Ctrl+5 (5) | Ctrl+5 (5) | Ctrl+5 (5) |
| **Spells that move** | | **6** | 8 | 7 |

**Recommendation: option 1.** It keeps the two emergency keys, keeps every "most pulls" spell but one on a top key,
moves the fewest spells, and her level-26 heals (Healing Wave top and lower) take keys 1-2, the easiest digits, now.
Runner-up: option 3, if Oskar values heal reach above the E/F swap.

## S1. Families (layout 9, option 1)

Changes from `research/keybind-layout-v4.md` S1 only:

| Family | Members *(level)* | Keys |
|---|---|---|
| **Heal ranks** (plain, core) | Healing Wave *(1)* + lower *(10)*, Chain Heal *(40)* + lower *(46)* | 1-2, 3-4 |
| Emergency pair (plain, core) | Earth Shock *(4)* (interrupt), Lesser Healing Wave *(20)* | Q, E |
| Enemy spells (plain, core) | Flame Shock *(10)*, Lightning Bolt *(1)*, Frost Shock *(20)*; spill-over Purge *(12)*, Chain Lightning *(32)* | R, F, 5; Ctrl+4, Ctrl+5 |

The spill-over works like Strength of Earth's (bar 6): the block is full, so the rarest members take the nearest spare
keys. Ctrl+4 / Ctrl+5 already carry the stance-bar warning in the preview (`L.defaultWarn`).

## S3. Grid at level 60 (Restoration layout 9)

**MO** = mouseover macro, **always-macro** = a macro in both targeting modes, *(lvl)* = learned at, **bold** = new or
moved in layout 9. Bar n button k = key k of that row.

| Key | Plain (Action Bar 1) | Shift (Action Bar 2) | Ctrl (Action Bar 3) |
|---|---|---|---|
| 1 | **Healing Wave R10**, MO *(1)* | Totemic Call *(22)* | Ghost Wolf *(20)* |
| 2 | **Healing Wave R8 (lower)**, always-macro `FS_HW_LO` *(10)* | Call of the Elements *(20)* | Water Walking *(28)* |
| 3 | **Chain Heal R3**, MO *(40)* | Call of the Ancestors *(30)* | Water Breathing *(22)* |
| 4 | **Chain Heal R2 (lower)**, always-macro `FS_CH_LO` *(46)* | Call of the Spirits *(40)* | **Purge**, MO harm *(12)* |
| 5 | Frost Shock *(20)* | Totemic Recall *(20)* | **Chain Lightning** *(32)* |
| Q | Earth Shock, `/stopcasting` + MO harm *(4)* | Flametongue Totem *(28)* | Earthbind Totem *(6)* |
| E | Lesser Healing Wave R6, MO *(20)* | Magma Totem *(26)* | Stoneclaw Totem *(8)* |
| R | **Flame Shock** *(10)* | Searing Totem *(10)* | Stoneskin Totem *(4)* |
| F | **Lightning Bolt** *(1)* | Fire Nova *(12)* | Tremor Totem *(18)* |
| Z | Mana Potion (`FS_MANA`) | Mana Spring Totem *(26)* | Grounding Totem *(30)* |
| X | Water Shield *(20)*; Lightning Shield *(8)* until then | Mana Tide Totem *(25)* | Windfury Totem *(32)* |
| C | Healthstone, else Healing Potion (`FS_HEALTH`) | Healing Stream Totem *(20)* | Grace of Air Totem *(42)* |
| Mouse4 | Riptide, MO *(40)* | Cure Poison, MO *(16)* | Poison Cleansing Totem *(22)* |
| Mouse5 | NS + Healing Wave (top rank), MO *(30)* | Cure Disease, MO *(22)* | Disease Cleansing Totem *(38)* |
| Mouse3 (middle) | Walk on Air *(Skyborne racial)* | – (unbound) | – (unbound) |

Spare keys: none. 42 of 42 keys hold a spell at 60, plus `BUTTON3` for a Skyborne. Action Bars 4, 5 and 6 are unchanged
from layout 8 (v4 S4/S5).

## S3a. Grid at level 26 (Erika now)

· = reserved, empty until the level in brackets (bound, nothing on it).

| Key | Plain (Action Bar 1) | Shift (Action Bar 2) | Ctrl (Action Bar 3) |
|---|---|---|---|
| 1 | **Healing Wave R5**, MO | Totemic Call | Ghost Wolf |
| 2 | **Healing Wave R3 (lower)**, `FS_HW_LO` | Call of the Elements | · *(Water Walking, 28)* |
| 3 | · *(Chain Heal, 40)* | · *(Call of the Ancestors, 30)* | Water Breathing |
| 4 | · *(Chain Heal lower, 46)* | · *(Call of the Spirits, 40)* | **Purge**, MO harm |
| 5 | Frost Shock | Totemic Recall | · *(Chain Lightning, 32)* |
| Q | Earth Shock | · *(Flametongue Totem, 28)* | Earthbind Totem |
| E | Lesser Healing Wave R1, MO | Magma Totem | Stoneclaw Totem |
| R | **Flame Shock** | Searing Totem | Stoneskin Totem |
| F | **Lightning Bolt** | Fire Nova | Tremor Totem |
| Z | Mana Potion | Mana Spring Totem | · *(Grounding Totem, 30)* |
| X | Water Shield | Mana Tide Totem | · *(Windfury Totem, 32)* |
| C | Healthstone / Healing Potion | Healing Stream Totem | · *(Grace of Air Totem, 42)* |
| Mouse4 | · *(Riptide, 40)* | Cure Poison | Poison Cleansing Totem |
| Mouse5 | · *(NS + Healing Wave, 30)* | Cure Disease | · *(Disease Cleansing Totem, 38)* |
| Mouse3 | Walk on Air | – | – |

## The plain row as she levels

| Level | 1 | 2 | 3 | 4 | 5 | Q | E | R | F |
|---|---|---|---|---|---|---|---|---|---|
| 26 | HW R5 | HW R3 | · | · | Frost Shock | Earth Shock | LHW R1 | Flame Shock | Lightning Bolt |
| 32 | HW R6 | HW R4 | · | · | Frost Shock | Earth Shock | LHW R2 | Flame Shock | Lightning Bolt |
| 40 | HW R7 | HW R5 | CH R1 | · | Frost Shock | Earth Shock | LHW R3 | Flame Shock | Lightning Bolt |
| 46 | HW R7 | HW R6 | CH R2 | CH R1 | Frost Shock | Earth Shock | LHW R4 | Flame Shock | Lightning Bolt |
| 60 | HW R10 | HW R8 | CH R3 | CH R2 | Frost Shock | Earth Shock | LHW R6 | Flame Shock | Lightning Bolt |

## S6. What changes from layout 8

Same key: everything on Shift, Ctrl 1-3, Ctrl Q/E/R/F and Z/X/C, all mouse keys, Q, E, 5, Z, X, C, and Action Bars 4-6.

| Spell | Layout 8 → 9 | Reach (small hands) |
|---|---|---|
| Healing Wave | F → 1 | 1 → 2 (worse; cast standing still) |
| Healing Wave lower | new → 2 | new key, tier 2 |
| Chain Heal | R → 3 | 1 → 2 (worse; cast standing still) |
| Chain Heal lower | new → 4 | new key, tier 3 |
| Flame Shock | 1 → R | 2 → 1 (better) |
| Lightning Bolt | 2 → F | 2 → 1 (better) |
| Purge | 4 → Ctrl+4 | 3 → 5 (worse; 0-1 a pull) |
| Chain Lightning | 3 → Ctrl+5 | 2 → 5 (worse; rare for a healer) |

## S7. Trade-offs

1. **Healing Wave and Chain Heal leave tier 1 (F, R) for tier 2 (1, 3).** The cost of putting every rank of a heal next
   to each other. Heals are cast standing still, and Erika's damage weaving (Flame Shock while moving) gains the keys.
2. **The old F habit.** For 26 levels F was Healing Wave; now it is Lightning Bolt. Pressing F out of habit casts a bolt
   at her target instead of a heal. The migration notice and the key page say it, and the new-skill card for Healing
   Wave's lower rank shows the new heal row. Option 3 avoids this only by swapping E/F, which is worse (above).
3. **Purge and Chain Lightning on Ctrl+4 / Ctrl+5 (tier 5).** Both are "no" in most pulls. Purge stays a mouseover harm
   macro, so she can Purge a mob under the cursor.
4. **No spare key is left.** A future spell needs a bar 6 click slot (11-12 spare) or bar 4.

# Part 4: How the rank keys are built

## A note kept from revision 1: Alt is the self-cast key, also for key presses

Not used any more (no Alt in this design), but it corrects an older doc. `research/keybind-layout.md:244` says the
self-cast modifier affects only mouse clicks. **That is wrong for the 12.x client Forever runs:**
`Blizzard_ActionBar/Shared/ActionButton.lua:462-464` sets `checkselfcast` on every action button, key presses take the
same `SecureActionButton_OnClick` path as clicks (146–175, 109), and `Blizzard_FrameXML/SecureTemplates.lua:190-191`
turns the unit into `"player"` while `IsModifiedClick("SELFCAST")` (Alt by default) is down (`ui`). So Alt + any key
holding a plain spell casts it on yourself. Any future Alt binding must use macros that name every unit; `f1393058`
shows Alt-bound macros can also clash with the Self Cast Key. The build task fixes line 244.

## Macros

Each lower key is an **always-macro** (a macro in both targeting modes) that names the rank:

| Key | Macro | Mouseover body | Click body |
|---|---|---|---|
| 2 | `FS_HW_LO` | `#showtooltip Healing Wave(Rank 3)`<br>`/cast [@mouseover,help,nodead][help,nodead][@player] Healing Wave(Rank 3)` | `#showtooltip Healing Wave(Rank 3)`<br>`/cast Healing Wave(Rank 3)` |
| 4 | `FS_CH_LO` | `#showtooltip Chain Heal(Rank 1)`<br>`/cast [@mouseover,help,nodead][help,nodead][@player] Chain Heal(Rank 1)` | `#showtooltip Chain Heal(Rank 1)`<br>`/cast Chain Heal(Rank 1)` |

- The mouseover body is today's `help` kind with `{spell}` = `Name(Rank N)`, so the self-fallback works as on the top
  keys. The click body is a new `help_click` kind (`#showtooltip {spell}\n/cast {spell}`) with no conditions, so it
  targets exactly like a plain spell (her target, else the client's Auto Self Cast). Only always-macros use a
  `_click` body, so the other `help` spells are not affected. The longest body (mouseover, `Healing Wave(Rank 10)`)
  is 109 characters, under 255.
- `#showtooltip` names the ranked spell, so the icon and tooltip show that rank's mana and heal (in-game check 2).
- `/cast Healing Wave(Rank 3)` casts that rank (`fc`; in-game check 1).
- **Top keys stay as they are:** `FS_HW` / `FS_CH` name the plain spell (the client casts the highest rank;
  `CheckMacroRank` already switches to `Name(Rank N)` if the client does not), and in click mode they are plain spells
  upgraded by `UpgradeRanks`. Open question 8 asks whether the top key should also name its rank.
- **Nature's Swiftness + Healing Wave** (`FS_NSHW`, Mouse5) keeps the top rank: `L.macroVars` `{heal}` stays
  `MacroSpellName(healing_wave)`, never the lower rank. NS makes the cast instant, so the biggest heal is the point.
- **Macro count:** today the shaman uses 13 character macros (9 spell: `FS_HW`, `FS_LHW`, `FS_CH`, `FS_RT`, `FS_CP`,
  `FS_CD`, `FS_ES`, `FS_PURGE`, `FS_NSHW`; 4 item: `FS_MANA`, `FS_HEALTH`, `FS_HEALPOT`, `FS_ELIXIR`). Layout 9 adds 2:
  **15 of 30** (`MAX_CHARACTER_MACROS` = 30, `ui` `Blizzard_APIDocumentationGenerated/MacroConstantsDocumentation.lua:11`).
  Her own macros count too; verify already prints "character macros: X of 30" (`Verify.lua:185`).

### Why always-macros in click mode, not plain ranked spells

A plain ranked spell on key 2 would fight the rank code: `OutdatedRanks` / `UpgradeRanks`
(`ForeverSensei/Modules/Layout.lua:922-955`) "fix" any slot holding a lower rank than the best known, so key 2 would be
upgraded to the top rank on the next rank learn, and `keepRank` would have to become a per-slot rank offset. Placing a
lower rank by its ID is also unverified with "Show All Spell Ranks" off, and the client may change a spell button itself
when a rank is learned. A macro button is untouched by both: only its body changes, and the addon writes the body.

## Core changes (for the build task)

| Where | Change |
|---|---|
| Pack data `Data/Restoration/Layout.lua` | `L.lower = { healing_wave = { macro = "FS_HW_LO", offset = 2, minLevel = 10 }, chain_heal = { macro = "FS_CH_LO", offset = 1 } }`; plan entries `{ "healing_wave", lower = true }` on main 2 and `{ "chain_heal", lower = true }` on main 4; `L.version = 9`; `L.macroBodies.help_click`; no `L.old` entries (below) |
| Pack data `Data/Restoration/Spells.lua` | Each ranked heal gets `levels` (learn level per rank ID), from the `simc` dump; today the levels are only comments |
| `Core/Class.lua` `BuildLayout` (53-126) | `L.bySpell` keeps pointing at the **top** slot (one slot per spell, as now); lower entries go to a new `L.lowerSlots[slot] = key` |
| `Modules/Layout.lua` new `Layout.LowerRank(key)` | The Part 2 rule → rank index and ID, or nil (fewer than 2 known ranks, below `minLevel`, or the step-up reaches the top). Honours `ns.char.rankPin` |
| `Desired` / `DesiredFor` (105-136) | A lower slot desires `{ kind = "macro", macro = FS_HW_LO, lower = key, id = <rank ID> }`, or nil (empty lower key, like an unlearned spell) |
| `Matches` (139) | Unchanged: a macro matches by name |
| `MacroBody` (161) | For a lower macro, `{spell}` = `Name(Rank N)` of `LowerRank`; kind `help` (mouseover) or the pack's new `help_click` body (click) |
| `RefreshMacros` (213) | Also refreshes every `L.lower` macro that exists |
| `CheckMacroRank` / `macroCasts` (958-993) | For a lower macro, checks `GetMacroSpell` = the lower rank's ID. No fallback name (the rank name is the only form); a mismatch is reported by verify |
| `OutdatedRanks` / `UpgradeRanks` (922-955), `keepRank` | Unchanged (they touch plain spells only) |
| `ApplyNewRanks` (996) | Before refreshing, remember each lower key's rank; after, add one `ui.rank.lower` line per changed key. The backup record gets `lower = { [key] = oldRankID }`. Also runs on **`PLAYER_LEVEL_UP`** (pcall-registered, queued until out of combat) |
| `Undo` (619) | For a `ranks` record with `lower`, set `ns.char.rankPin[key] = { id = old, top = <top ID now> }` and refresh the macros. A pin whose `top` differs from the current top is dropped |
| New-skill module | The first time `LowerRank` is non-nil and the lower slot is empty, a card "<Name> の低いランク" with 配置する for its key |
| Verify | One line per lower key: key, macro, rank it casts, "ok / kept / wrong rank / empty until level N" |
| clean | Lower slots are planned slots (not leftovers) |
| `Modules/UnitFrames.lua` | **No change** (below) |

## Portrait click-cast

**Nothing changes.** `UnitFrames` sets attributes only for the planned mouse keys on bar 6 (prefixes `""`, `"shift-"`,
`"ctrl-"`, `ForeverSensei/Modules/UnitFrames.lua:14`), and the mouse keys keep Riptide, NS + Healing Wave, the cures and
the cleansing totems. The heal ranks are keyboard keys, which already work over portraits (only Mouse4/5 needed the
click-cast fix in 0.8.0). Mouse5's NS + Healing Wave keeps the top rank, so its portrait attribute is unchanged.

# Part 5: Coaching text and toasts

New and changed locale keys (one entry per line, `ja` 常体, names in English letters, 体力 not ヘルス). `{key}` is the
key label from the layout, so the text follows the grid.

| Key | ja | en |
|---|---|---|
| `spell.healing_wave.lower` | {key} は低いランクの Healing Wave。回復量は少ないが、マナがずっと少なくて済む。 | {key} is a lower rank of Healing Wave. It heals less but costs much less mana. |
| `spell.chain_heal.lower` | {key} は低いランクの Chain Heal（レベル46から）。 | {key} is a lower rank of Chain Heal (from level 46). |
| `guide.heal.cheap` | 少しのダメージを回復する時、体力を満タンに戻す時、マナが減ってきた時、長い戦いでは、低いランクのキー（{lowkeys}）を使おう。 | For small damage, topping someone off, when your mana runs low and in long fights, use the lower-rank keys ({lowkeys}). |
| `guide.heal.max` | タンクが大きなダメージを受けている時や危ない時は、一番高いランクのキー（{topkeys}）を使おう。Nature's Swiftness では、いつも一番高いランクを使う。 | When the tank takes big hits or someone is in danger, use the top-rank keys ({topkeys}). Nature's Swiftness always casts the top rank. |
| `guide.heal.rankauto` | どのランクを使うかはアドオンが選ぶ。新しいランクを覚えると、低いランクのキーも1つ上がる。レベルよりずっと低いランクは装備の回復ボーナスが減るので、レベルが上がっただけで上がることもある。 | The addon picks the ranks. When you learn a new rank, the lower-rank key goes up one too. Ranks far below your level lose part of your gear's healing bonus, so it can also go up on a level-up alone. |
| `guide.heal.test` | 回復量は自分にかけて試そう。レベルの違うパーティーメンバーへの回復は、説明より少なくなることがある。 | Test a heal on yourself. Heals on a party member of a different level can heal less than the tooltip says. |
| `ui.rank.lower` | {key}: {name} は Rank {old} から Rank {new} になった。 | {key}: {name} Rank {old} → Rank {new}. |
| `ui.rank.kept` | {key}: {name} は Rank {n} のままにする。 | {key}: {name} stays at Rank {n}. |
| `ui.lower.card` | {name} の低いランク | Lower rank of {name} |

- **Toast:** the existing rank toast (`ApplyNewRanks`) adds one `ui.rank.lower` line per lower key that changed, with
  the same 15 s 元に戻す button; a level-up with only a step-up shows a toast with just that line. After Undo,
  `ui.rank.kept` confirms the pin.
- **New-skill cards** for Healing Wave and Chain Heal get the `.lower` line once a lower rank exists; the Chain Heal card
  at 40 says "from level 46". The one-time lower-key card uses `ui.lower.card` + the `.lower` line.
- **Guide:** the 回復のコツ tab gets the four `guide.heal.*` lines (no Alt any more); the key page shows the current rank
  under keys 1-4 and E.
- `guide.heal.test` cites `f2371681` (duo with Oskar when their levels differ).
- The Healing Way note from Part 1 goes into the guide's source notes only: no "Rank 1 to keep stacks" advice.

# Part 6: Migration and proof

- **Restoration layout 8 → 9.** One-time すべて配置 notice; **nothing moves by itself**. The notice names the six moves
  (S6) and the old-F warning (S7.2). A full apply creates `FS_HW_LO` / `FS_CH_LO`, places them, moves the six spells,
  and backs up every slot it touches. **元に戻す** restores the old buttons; the two new macros stay in her macro list,
  unused (as earlier layouts' macros did), and a later すべて配置 reuses them.
- **No `L.old` entries.** `L.old` lists only buttons the plan no longer fills (`Data/Restoration/Layout.lua` comment
  above `L.old`); layout 9 refills all six old buttons (1-4, R, F), and the full apply's move list carries each spell
  from where it is to its new key, so the preview shows each move.
- The rule "a learned spell's key never moves" holds after the migration: the lower keys are fixed (2 and 4); only
  their rank changes.
- **check.py:** the exact layout-9 grid and families (heal ranks 1-4, emergency pair Q/E, enemy spells R/F/5 with the
  Ctrl+4/5 spill-over); layout version 9; `L.lower` only for `healing_wave` / `chain_heal`, each on the plain key right
  after its top key; every lower body ≤ 255 characters; `levels` per rank matches `simc` (`research/shaman_simc_1.60.1.70862.tsv`).
- **Scenario (`scenarios.lua`):** levels 10, 26, 31 → 32, 37 → 38, 40, 46 and 60 in both targeting modes: the lower
  bodies and ranks of this doc's tables; the toast lines; Undo → pin → the pin survives a level-up and ends on the next
  rank; the 8 → 9 migration and its undo; NS + Healing Wave still top rank; unit-frame attributes unchanged; a skipped
  trainer rank picks the right lower rank; the key-4 card at 46; 15 macros.
- **Byte-identical proof:** the same dump as in 0.8.1 and 0.9.0 (every level 1–60 × mouseover/click × ja/en: grid,
  macro bodies, bindings, guide text), run on the build and on a worktree at a096c05 for `ForeverSensei_Paladin` and
  `ForeverSensei_Warrior`; the diff must be empty. The core changes are inert without `L.lower` (no lower slots, no
  pins, the level-up refresh rewrites nothing).
- TOCs to the next version; `make check` and `make zip`.

# Verify in game

1. `/cast Healing Wave(Rank 3)` in a macro casts Rank 3, in the mouseover and in the click body (`fc` says yes).
2. `#showtooltip` on `FS_HW_LO` shows Rank 3's tooltip (its mana cost and heal).
3. `GetMacroSpell` on `FS_HW_LO` returns Rank 3's ID (547), so `CheckMacroRank` can check the lower rank.
4. Learning a rank does not change a macro button by itself, and the lower body is rewritten once out of combat.
5. A level-up with only a step-up (e.g. 37 → 38) rewrites key 2 and shows the toast.
6. The penalty: at a known level, the lower rank's tooltip heal matches Part 2's share (e.g. at 31 Healing Wave R3 with
   90%).
7. `C_SpellBook.IsSpellKnown` is true for each lower rank she trained.
8. Ctrl+4 casts Purge on the mouseover mob and Ctrl+5 casts Chain Lightning (the stance-bar default is replaced, as the
   preview warned).
9. Mouse4/5 over a portrait still cast Riptide / NS + Healing Wave; left and right click are unchanged.

# Open questions for Oskar

1. The grid: **option 1** (proposed: heal ranks on 1-4, Q/E unchanged, damage on R/F), option 2 (all heals on 1-5) or
   option 3 (Healing Wave on E-R, the E/F swap)?
2. **Two keys for Healing Wave** (proposed; a third would repeat the second from level 26 on), or three anyway?
3. The rule: **top − 2 with the 90% step-up** for Healing Wave and **top − 1** for Chain Heal (proposed), the most
   mana-efficient rank, or fixed ranks?
4. Lesser Healing Wave: **one key** (proposed), or a lower key too (it would need another plain key)?
5. Healing Wave's lower key from level **10** (proposed) or 6? (Erika is past both; it matters for the data.)
6. Purge and Chain Lightning on **Ctrl+4 / Ctrl+5** (proposed), or click slots on bar 6 (11-12)?
7. Undo on a rank toast **pins** the lower key until the next rank of that heal (proposed), or only until the next
   level-up?
8. The top keys keep naming the plain spell (proposed, today's tested path), or name their rank too?

# (日本語) Erika へのまとめ

- 回復のキーが数字に移る。1 は Healing Wave、2 は低いランクの Healing Wave、3 は Chain Heal、4 は低いランクの Chain Heal（レベル46から）。
- Q（Earth Shock）と E（Lesser Healing Wave）は今まで通り。R は Flame Shock、F は Lightning Bolt になる。F は回復ではなくなるので気をつけよう。
- Purge は Ctrl+4、Chain Lightning は Ctrl+5 に移る。
- 低いランクは回復量が少ないが、マナがずっと少なくて済む。少しのダメージや、満タンに戻す時に使おう。タンクが危ない時は 1 と 3 を使おう。
- どのランクにするかはアドオンが選ぶ。新しいランクを覚えると、2 と 4 のランクも上がる。
- キーが変わるのは「すべて配置」を押した時だけ。元に戻すこともできる。
