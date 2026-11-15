# Downranked heals for Restoration (proposal, shaman pack)

Status: **proposal for approval**. Nothing here is built. Once Oskar approves it, a build task turns it into
Restoration layout 9 (`ForeverSensei_Shaman`). The Paladin and Warrior packs do not change.

## Why

Erika, via Oskar, verbatim: "For the restoration shaman profile, I think we need to consider lower ranks of the
healing spells. When playing in group it's important to also have lower ranks of heals to conserve mana."

Direction given by the coordinator (Oskar skipped the question, so this is a default he can override): the cheaper
rank goes on **Alt + the same heal key** (Alt+E Lesser Healing Wave, Alt+R Chain Heal, Alt+F Healing Wave). The plain
keys stay at the highest rank. Alt is not used anywhere in the layout today (Shift = Fire totems, Ctrl = Earth
totems, `research/keybind-layout-v4.md` S3).

Short answer, explained below:
- Forever **does** penalise ranks far below your level, but with a new rule, not the Classic one. A rank keeps its
  full Spell Healing bonus for 17 levels after you learn it, then loses 5% per level.
- The addon picks the cheap rank itself as she levels: **Healing Wave = highest known rank − 2**, one rank higher when
  that rank would keep less than 90% of its bonus. **Chain Heal = highest − 1**, from level 46. **Lesser Healing Wave
  and Riptide get none.**
- It is built as a `[mod:alt]` branch inside the existing `FS_HW` / `FS_CH` macros, with ALT-F / ALT-R bound
  explicitly to the same buttons (option a).

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
| `ui` | reckhou/WoWBlzCode @7245053, `Forever/BlizzardInterfaceCode/Interface/AddOns` | Self-cast on key presses, modified attributes on unit frames |
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

# Part 2: Which heals get a cheap rank, and the rule

## Decision per heal

| Heal | Plain key | Alt rank | Why |
|---|---|---|---|
| Healing Wave | F | **yes**: highest − 2, step up if < 90% | Her main heal; the biggest mana use; 38–83% of the top heal for much less mana |
| Chain Heal | R | **yes, from 46**: highest − 1 | Only 3 ranks. At 40–45 there is no lower rank. R2 vs R3: 86–90% of the heal for 78% of the mana |
| Lesser Healing Wave | E | **no** (open question 2) | It is the emergency heal: when she presses it, she needs the full amount. Highest − 1 is ~80% of the heal for ~77% of the mana, only about 5% better per mana |
| Riptide | Mouse4 | **no** | 12 s cooldown, so its mana is small; a cheap rank would waste the cooldown |

## The rule

A relative rule that follows her level and her **known** ranks (the addon checks each rank ID with
`C_SpellBook.IsSpellKnown`, `Spells.lua` `KnownRank`). Fixed ranks would go stale every few levels and would need a
table edit for every rank she skips at the trainer.

- **Healing Wave:** cheap = highest known rank − 2 (at least Rank 1, only when she knows 2 or more ranks). If that rank
  keeps **less than 90%** of its Spell Healing bonus at her level, use one rank higher.
- **Chain Heal:** cheap = highest known rank − 1 (from 46). With 3 ranks, a step-up never applies before 60.
- The cheap rank changes on level-up as well as on learning a rank, so the macros refresh on both (Part 3).

Why "− 2" and not "the most mana-efficient rank": the most efficient rank depends on her gear and on overheal, which
the addon cannot see in 12.x (secret values in combat). Two ranks below the top keeps the heal big enough to be useful
on a party member taking steady hits (38–83% of the top rank), and the 90% step-up keeps it inside the measured part
of the penalty curve. **Safety margin:** even if the real penalty were twice as steep as `fc` says, the chosen rank
would still keep at least 80%.

## Per-level table

Cell: `rank · mana · base heal at that level (no +healing) · heal per mana with the assumed Spell Healing`.
`(95%)` / `(90%)` = the share of the bonus the cheap rank keeps; no mark = 100%.

Assumptions:
- Spell Healing follows the ramp in `fc`: 100 at 20, 200 at 30, 860 at 60, linear in between, and 5 per level below
  20 (50 at 10). Her real number is on her character sheet.
- Base heal at level L = base + points per level × (min(L, rank max level) − T), from `simc`. The in-game tooltip
  rounds to a range and scales slightly differently (`wh_tt`: HW R3 547 shows 127–150 for 80 mana; `simc` base 131),
  so the numbers are for comparison, not exact.
- No talents (Improved Healing Wave, Tidal Focus, Healing Way and Purification change all ranks alike), no critical
  heals, no overheal. **With 0 Spell Healing every column is base heal ÷ mana, and the top rank is the most efficient
  per mana**; the cheap rank then helps only by overhealing less.
- All ranks trained. If she skips a rank, the rule uses the ranks she knows.

| Levels | HW plain (F) | HW Alt (Alt+F) | CH plain (R) | CH Alt (Alt+R) | LHW plain (E) |
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
- Levels 6–9 also get an Alt rank (R1, she knows R1 and R2). Open question 3: start at 6 or at 10.
- Up to level 23 the Alt Healing Wave is also **faster** (R1 1.5 s, R2 2 s), and at 24–31 R3 is 2.5 s against 3 s,
  because Forever ties low-rank coefficients to shorter casts. After Improved Healing Wave (her talents at 10–14) the
  top rank is shorter too.
- The cheap Healing Wave is 38% of the top rank at 60 and up to 83% earlier: on a tank taking big hits it is too
  small, which is what the coaching says (Part 4).
- The "−2" rank keeps 90–100% of the bonus at every level, so the measured part of the rule is all that matters.

# Part 3: How Alt is implemented

## A finding first: Alt is the self-cast key, also for key presses

`research/keybind-layout.md:244` says the self-cast modifier affects only mouse clicks. **That is wrong for the 12.x
client Forever runs.**
- `ui` `Blizzard_ActionBar/Shared/ActionButton.lua:462-464`: `ActionBarActionButtonMixin:OnLoad` sets
  `checkselfcast`, `checkfocuscast` and `checkmouseovercast` on every action button.
- Key presses go `ActionButtonDown/Up` (146–175) → `TryUseActionButton` (109) → `SecureActionButton_OnClick(self,
  "LeftButton", …, isKeyPress)`, the same path as a click.
- `ui` `Blizzard_FrameXML/SecureTemplates.lua:143-200` `SecureButton_GetModifiedUnit`: with `checkselfcast` and
  `IsModifiedClick("SELFCAST")` (Alt by default) the unit becomes `"player"` (190–191). `SECURE_ACTIONS.action` (341)
  then calls `UseAction(action, unit, button, isKeyPress)`.

So **Alt + a key that holds a plain spell casts that spell on yourself**, whatever you target. This decides Part 3:
any Alt heal must be a macro whose every branch names its unit (`@mouseover`, `@target`, `@player`), so the outcome
does not depend on whether the client applies `unit` to a macro (in-game check 3). `f1393058` also shows the
self-cast key can break Alt-bound macros; there the fix was Options → Combat → Self Cast Key = None (open question 5).

## Option (a): a `[mod:alt]` branch in the existing heal macros (recommended)

- `FS_HW` and `FS_CH` become **always macros** (`L.macroAlways`), also in click targeting mode. `FS_LHW` stays as it
  is.
- New macro kinds, used for `healing_wave` and `chain_heal`:

      help_alt       = "#showtooltip\n/cast [mod:alt,@mouseover,help,nodead][mod:alt,@target,help,nodead][mod:alt,@player] {cheap}; [@mouseover,help,nodead][help,nodead][@player] {spell}"
      help_alt_click = "#showtooltip\n/cast [mod:alt,@target,help,nodead][mod:alt,@player] {cheap}; {spell}"

  - `{cheap}` = `Healing Wave(Rank 5)` style (`fc`: the rank syntax works in `/cast`), computed by a new
    `Layout.CheapRank(entry)` from her level and known ranks. When there is no cheap rank (Chain Heal before 46,
    Healing Wave with one known rank), the body is the current `help` / plain body, unchanged.
  - The mouseover branches keep today's self-fallback rule. In click mode, Alt heals your friendly target, else you.
  - A **bare `#showtooltip`** makes the button's icon and tooltip follow the branch that is active, so holding Alt
    shows the cheap rank's tooltip with its mana cost and heal.
  - The longest body (Healing Wave, mouseover, both names with a two-digit rank) is 189 characters, under the 255
    limit.
- **Keys.** Bind `ALT-F` → `ACTIONBUTTON9` and `ALT-R` → `ACTIONBUTTON8` explicitly (the same buttons as F and R) and
  add them to `L.allowedKeys`. Do not rely on an unbound Alt+F falling through to F's binding: it is common lore but I
  found no source. `f1393058` shows an explicit modified binding makes the macro see the modifier. No Forever default
  binding uses `ALT-*` (`ui` Bindings, the camelot bindings file), so no `L.defaultWarn` entry is needed; the
  backup and **元に戻す** still save and restore ALT-F / ALT-R.
- **Rank code** (`ForeverSensei/Modules/Layout.lua`):
  - `CheckMacroRank` (968) uses `GetMacroSpell`, which reports the branch for the *current* modifier state. Out of
    combat with no Alt held that is the plain branch, so it keeps checking the top rank as today. It must skip the
    check while `IsAltKeyDown()`.
  - `OutdatedRanks` / `UpgradeRanks` (922–955) and `Matches` keepRank (139) only touch plain-spell buttons; the
    macros are untouched, so the cheap rank is never "upgraded" by mistake.
  - `RefreshMacros` (213) rewrites the bodies. Call it on `PLAYER_LEVEL_UP` too (the cheap rank can change with no
    new rank learned, e.g. at 31 → 32), queued until `PLAYER_REGEN_ENABLED` when in combat, like today.
  - `MacroBody` (161) gets `{cheap}` next to `{spell}`.
- **verify / clean / undo:** no new slots. Verify adds the two Alt bindings and checks the macro bodies (it already
  compares macro bodies).
- **Portrait click-cast** (`ForeverSensei/Modules/UnitFrames.lua`): nothing to add. The prefixes are `""`,
  `"shift-"`, `"ctrl-"` (line 14), and `SecureButton_GetModifiedAttribute` (`ui` `SecureTemplates.lua:119`) looks up
  `alt-type4`, `*type4`, `alt-type*`, `*type*` in turn, so the plain `type4` we set is not used with Alt held:
  **Alt+Mouse4/5 on a portrait does nothing**, as the coordinator suggested. The heals are not on mouse buttons
  anyway.

Pros: no new bar or screen space, the icon and tooltip show the rank that will be cast, one button per heal, ranks
follow her level by themselves. Cons: in click mode Healing Wave and Chain Heal stop being plain spells (a full apply
replaces them; the preview shows it).

## Option (b): ALT-E/R/F on a new bar holding the ranked spell or macro

- Needs a shown bar. Bar 7 (157–168) is retired for the shaman (`L.retired`, hidden by a full apply) and bar 8
  (169–180) is unused; both are more screen space, and the earlier docs say a hidden bar may not fire its bindings.
- A plain ranked spell there **self-casts with Alt** (finding above), so it would heal Erika instead of her target in
  click mode; it would have to be a macro anyway.
- A plain ranked spell is exactly what `OutdatedRanks` / `UpgradeRanks` "fix" on the next rank learn; keepRank and the
  rank toast would need an exemption list.
- Three more slots for verify, clean and undo, and the slot would have to be re-placed on every level-up.

**Recommendation: option (a).**

# Part 4: Coaching text and toasts

New locale keys (one entry per line, `ja` 常体, names in English letters, 体力 not ヘルス):

| Key | ja | en |
|---|---|---|
| `spell.healing_wave.alt` | Alt を押しながら F を押すと、低いランクの Healing Wave を使う。回復量は少ないが、マナがずっと少なくて済む。 | Hold Alt and press F for a lower rank of Healing Wave. It heals less but costs much less mana. |
| `spell.chain_heal.alt` | Alt を押しながら R を押すと、低いランクの Chain Heal を使う（レベル46から）。 | Hold Alt and press R for a lower rank of Chain Heal (from level 46). |
| `guide.heal.cheap` | 少しのダメージを回復する時、体力を満タンに戻す時、マナが減ってきた時、長い戦いでは Alt を押しながら回復しよう。 | Hold Alt for small damage, for topping someone off, when your mana runs low and in long fights. |
| `guide.heal.max` | タンクが大きなダメージを受けている時や危ない時は、Alt なしで一番高いランクを使おう。Nature's Swiftness では、いつも一番高いランクを使う。 | When the tank takes big hits or someone is in danger, use the top rank (no Alt). Nature's Swiftness always casts the top rank. |
| `guide.heal.rankauto` | どのランクを使うかはアドオンが選ぶ。レベルよりずっと低いランクは装備の回復ボーナスが減るので、レベルが上がると Alt のランクも上がる。 | The addon picks the rank. Ranks far below your level lose part of your gear's healing bonus, so the Alt rank goes up as you level. |
| `guide.heal.test` | 回復量は自分にかけて試そう。レベルの違うパーティーメンバーへの回復は、説明より少なくなることがある。 | Test a heal on yourself. Heals on a party member of a different level can heal less than the tooltip says. |
| `ui.rank.alt` | Alt+{key} の {name} は Rank {n} になった。 | Alt+{key} now casts {name} Rank {n}. |

- **Toast:** when the cheap rank changes (level-up or a new rank), the existing rank toast (`ApplyNewRanks` 996) adds
  one `ui.rank.alt` line per heal. No new-skill card: the cheap rank is not a new spell.
- **New-skill cards** for Healing Wave (level 1) and Chain Heal (level 40) get the `.alt` line once a cheap rank
  exists; the Chain Heal card at 40 says "from level 46".
- **Guide:** the 回復のコツ tab gets the four `guide.heal.*` lines; the key page shows Alt+F / Alt+R under F / R with the
  current cheap rank.
- `guide.heal.test` cites `f2371681` (duo with Oskar when their levels differ).
- Nature's Swiftness (`FS_NSHW`, `{heal}` = Healing Wave) keeps casting the top rank; `L.macroVars` must keep using
  `MacroSpellName`, not `{cheap}`.

# Part 5: Migration and proof

- **Restoration layout 8 → 9.** One-time すべて配置 notice; nothing moves by itself. A full apply rewrites `FS_HW` /
  `FS_CH`, places them as macros in click mode, binds ALT-F / ALT-R, and backs everything up. **元に戻す** restores the
  old macros, buttons and the two Alt bindings (unbound before).
- **check.py:** the Alt keys are allowed only as `ALT-R` / `ALT-F` on bar 1 buttons 8 / 9 (a second binding on the
  plain key's button, outside the block rule); layout version 9; every `help_alt` body ≤ 255 characters; the rank
  table per level from `simc` matches Part 2 (a generated `rankLevels` table in `Data/Ranks.lua`, from
  `tools/research/gen_ranks.py`; today the learn levels are only comments).
- **Scenario:** levels 10, 31, 32, 46 and 60 in both targeting modes: body text, Alt bindings, toast on 31 → 32,
  8 → 9 migration and undo, Nature's Swiftness still top rank, no `alt-` attributes on unit frames, a skipped trainer
  rank picks the right cheap rank.
- **Byte-identical proof:** the same dump as in 0.8.1 and 0.9.0 (every level 1–60 × mouseover/click × ja/en: grid,
  macro bodies, bindings, guide text) run on the build and on a worktree at a096c05 for `ForeverSensei_Paladin` and
  `ForeverSensei_Warrior`; the diff must be empty.
- TOCs to the next version; `make check` and `make zip`.

# Verify in game

1. `/cast Healing Wave(Rank 5)` in a macro casts Rank 5 (`fc` says yes).
2. ALT-F fires action button 9 and the macro's `[mod:alt]` branch runs.
3. With the default Self Cast Key (Alt), Alt+F on a party member's mouseover heals that member, not Erika.
4. Holding Alt changes the button's icon tooltip to the cheap rank (bare `#showtooltip`).
5. `GetMacroSpell` with no Alt held returns the top rank (so `CheckMacroRank` keeps working).
6. Alt+Mouse4/5 over a portrait does nothing; left and right click are unchanged.
7. The penalty: at a known level, the cheap rank's tooltip heal matches Part 2's share (e.g. at 31 Healing Wave R3
   with 90%).
8. `C_SpellBook.IsSpellKnown` is true for each lower rank she trained.

# Open questions for Oskar

1. The rule: **highest − 2 with the 90% step-up** (proposed), the most mana-efficient rank, or fixed ranks?
2. Lesser Healing Wave: **no cheap rank** (proposed)? And should Alt+E be bound to button 7 so it casts the normal
   Lesser Healing Wave, or stay unbound?
3. Start the Alt Healing Wave at level **10** (proposed: at 6–9, R1 saves only 20 mana per cast) or at 6, when she learns Rank 2?
4. Chain Heal Alt rank from 46 (proposed), or none?
5. Self Cast Key: leave it on Alt (proposed; the macros name every unit), or tell her to set it to None?
6. Option **(a)** (proposed) or (b)?
7. Show the current Alt rank on the key page (proposed: yes)?

# (日本語) Erika へのまとめ

- Alt を押しながら F を押すと、低いランクの Healing Wave を使う。Alt を押しながら R は低いランクの Chain Heal（レベル46から）。
- 低いランクは回復量が少ないが、マナがずっと少なくて済む。少しのダメージや、満タンに戻す時に使おう。
- タンクが危ない時は、今まで通り Alt なしで一番高いランクを使おう。
- どのランクにするかはアドオンが選ぶ。レベルが上がると、Alt のランクも上がる。
- E（Lesser Healing Wave）と Riptide は今まで通り。
