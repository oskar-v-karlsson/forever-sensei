# Keybind layout research: Protection Paladin, dungeon tank (proposal)

> **Superseded (0.7.0):** the current Protection layout (layout 2, "family blocks", auras on Action Bar 3) is in
> [keybind-layout-v4.md](keybind-layout-v4.md). This document keeps the pull walkthroughs, reach tiers and sources
> that v4 builds on; its grid, own-key rule and stance-bar aura plan are history.

Status: **proposal for approval**. Nothing here is built yet. Once Oskar approves the grid in section (a), a separate
task builds the `ForeverSensei_Paladin` pack (target: ForeverSensei 0.6.0). It follows the method of the shaman
layout (`research/keybind-layout.md`, layout v3 onwards).

Scope:
- Oskar tanks dungeons as Protection most of the time. Questing and solo come second.
- He moves with WASD, has **normal-sized hands** and two mouse side buttons.
- Allowed keys: 1-5, Q, E, R, F, Z, X, C and Mouse4/Mouse5, each plain, with Shift or with Ctrl.
- **5, Shift+5 and Ctrl+5 stay free in all variants** for Oskar's own use.
- The layout is planned for level 60, and keys never move while levelling. Spells learned later keep their key
  empty until they are learned.
- Shaman behaviour must stay identical. Every core change below is opt-in per spec.

## Sources

All checked on 2026-11-11 unless noted otherwise. Only World of Warcraft: Forever sources are used, never Classic
or Retail pages.

| Key | Source | Used for |
|---|---|---|
| `wh_guide` | [Wowhead: Protection Paladin Leveling Guide - WoW: Forever](https://www.wowhead.com/forever/guide/classes/paladin/protection/tank-leveling-tips), Riyani, updated 2026-11-06, read in the browser | **the talent path** (0/32/19 and its "Talent Order" for levels 10-60), the trainer spell list, mana tips, rotation priority |
| `moba` | [Mobalytics: Protection Paladin Guide](https://mobalytics.gg/wow-forever/classes/protection-paladin-guide), Subtle, updated 2026-11-11, read in the browser | gameplay: opener, pre-pull, single- and multi-target rotation, seals, auras, tips, macros; its 0/35/16 build only as an alternative |
| `simc` | simc-forever `SpellDataDump/paladin.txt` (commit `3c1d319e`, 2026-11-10), header "SimulationCraft 160-01 for World of Warcraft 1.60.1.70862 Live"; parsed into `research/paladin_simc_1.60.1.70862.tsv` by `tools/research/parse_simc.py` | levels, ranks, cast, cooldown, GCD, cost, duration, the "Use Shapeshift Bar" attribute |
| `wh_tt` | Wowhead Forever tooltips, `https://nether.wowhead.com/forever/tooltip/spell/<id>` (about 80 spells fetched) | current tooltip text: ranges, effects, "Does not consume the Seal", Forbearance |
| `wh_abil` | [Wowhead Forever: Paladin abilities](https://www.wowhead.com/forever/spells/abilities/paladin), read in the browser (251 entries) | which spells exist and are trainable; "New"/"Removed" tags |
| `wh_dng` | [Wowhead Forever: Dungeons](https://www.wowhead.com/forever/zones/instances/dungeons), as cited in `research/keybind-layout.md` | dungeon level ranges for the pull walkthroughs |
| `ui` | Forever UI code, `reckhou/WoWBlzCode` @ `7245053` (2026-10-28), `Forever/BlizzardInterfaceCode` | binding names (`Blizzard_FrameXML/Bindings_Camelot.xml`), the stance bar (`Blizzard_ActionBar/Shared/StanceBar.lua`, header "StanceBar (Shapsfit,Auras,Aspects)") |

### Where the sources disagree, or can't be verified

| Topic | What the sources say | Decision |
|---|---|---|
| Seal of Fury taunt duration | `moba` (and the task brief) say 4 s. `wh_tt` 1311649 and `simc` 20232 "Judgement of Fury" both say **3 s**. | Use 3 s in texts. Verify in game. |
| Blessing of Sanctuary "stacks with other blessings" | Not in `simc` (talents or spells) and not in `wh_abil`. `wh_guide` actually writes "(Spell #1038) now usable alongside your other blessings". 1038 is Blessing of Salvation in Classic, but its Forever tooltip is empty and it is absent from `simc` and `wh_abil`. `moba` macros still `/cancelaura` Salvation. | **Unverified.** Not in the layout, not in any text until checked in game. |
| Blessing of Light | `wh_guide` lists "(Spell #19977)" as an optional level-40 trainer spell. The Forever tooltip for 19977 is empty; not in `simc`. | **Unverified.** Not in the layout. |
| Hammer of the Righteous | `simc` 407632 lists it at level 40 in the Protection skill line, `wh_abil` tags it "New". It is **not** in `wh_guide`'s trainer list or in either rotation. | **Open question.** Ctrl+E is left spare so it can go there if it is trainable. |
| One-Handed Weapon Specialization | `wh_guide`: "now trainable" at 1. `wh_abil`: "Removed". | Passive, no key. Not needed for the layout. |
| Interrupt | Both guides: no interrupt for Protection. `wh_abil` lists Rebuke only as a Season of Discovery rune leftover (not trainable). | Verified: no interrupt. Hammer of Justice (3 s stun) is the substitute. |
| Taunt | No Hand of Reckoning or Righteous Defense (rune leftovers only in `wh_abil`). The taunt is **Judgement while Seal of Fury is active** (`wh_tt`). | Verified. |
| `moba` macros | The "Big Threat Opener" has `/start attack` (should be `/startattack`). Its "Holy Shield" and "Exorcism" macros cast Consecration (copy-paste error). | Our macros fix both. |
| Light's Vigil, Repentance | Holy and Retribution talents, not in the 0/32/19 build. | Not in the layout. |
| Seal of Command | `wh_tt` 20375 marks it "Talent"; the build doesn't take it. | Not in the layout. |

## Forever differences that matter for keys (verified)

| Difference | Fact | Source |
|---|---|---|
| Holy Strike (new) | Level 6, ranks to 60; melee; 10 s cooldown (6 s with Shieldsworn); on the GCD | `simc`, `wh_tt`, `wh_abil` |
| Seal of Fury (new) | Level 10 (rank 1 id 1311649, rank 7 at 58); lasts 30 s; melee hits add Holy damage; with a shield, each hit also gives an absorb worth 50% of that Holy damage; its Judgement deals Holy damage and **taunts for 3 s** | `wh_tt` 1311649, `simc` 20232 |
| Judgement | Level 4; 10 yd range; 10 s cooldown (8 s with Improved Judgement 2/2); **off the GCD**; **does not consume the seal** | `wh_tt` 20271 ("Does not consume the Seal"), `simc` (no GCD) |
| Swift Judgement (talent, 37) | A second Judgement button: 1 min cooldown, 10 yd, off the GCD, free, does **not** share Judgement's cooldown | `wh_tt` 1310994, `simc` |
| Templar's Bulwark (talent, 32) | Absorb equal to 100% of max health for 8 s; 5 min cooldown; applies Forbearance | `wh_tt` 1311015 |
| Shieldsworn (talent, 52) | Holy Strike cooldown −4 s; strikes with the shield, triggering Holy Shield and Shield Specialization without using their charges | `wh_tt`, `wh_guide` ("use Holy Shield before Holy Strike") |
| Iron Creed (talent, 48-50) | +30% Holy Strike threat; after Holy Strike while Righteous Fury is up, −15% damage taken for 6 s | `wh_tt` 1311034 + proc |
| Sacred Duty (talent, 51/60) | −60 s on Divine Shield, Divine Protection and Templar's Bulwark; shorter Forbearance | `wh_tt` |
| Sacred Arbiter (talent, 56) | Holy Strike +20% damage and refreshes all your Judgements on the target | `wh_tt` |
| Voice of Truth (new, 20) | 6 s immunity to Silence and Interrupt; 3 min cooldown; off the GCD | `wh_tt` 1310897, `simc` |
| Consecration | Baseline at 20; 8 s cooldown; the first 4 enemies take extra damage | `wh_tt` 26573 |
| Blessing of Kings | Baseline at 20 (+10% stats, 1 h). All blessings last 1 h. | `wh_tt` 20217, `simc` |
| Righteous Fury | Level 10 (earlier than Classic); 30 min; +33% threat, +90% Holy threat | `wh_tt` 25780 |
| Forbearance | Divine Protection, Divine Shield, Templar's Bulwark and Blessing of Protection all apply it; none of the first three can be used while it is up | `wh_tt` 498, 642, 1311015, 1022 |
| One blessing per paladin | Blessing of Protection, Freedom and Sacrifice replace the Kings you put on that player | `wh_tt` 1022, 1044, 6940 |
| Auras use the stance bar | All six auras (Devotion, Retribution, Concentration, Shadow/Frost/Fire Resistance) carry the "Use Shapeshift Bar" attribute | `simc` attributes, `ui` StanceBar.lua |
| Mount | Paladins get the 60% mount free (Tome of Nobility); Summon Warhorse 40, Summon Charger 60 | `wh_guide`, `wh_tt` 13819, 23214 |

## The talent path (`wh_guide`, THE path)

Build 0/32/19 (Protection 32, Retribution 19, 51 points). Level → talent:

| Levels | Talent | Levels | Talent |
|---|---|---|---|
| 10-14 | Benediction 1-5 | 41 | Toughness 3 |
| 15-17 | Sanctified Judgement 1-3 | 42 | **Holy Shield** (key 3) |
| 18-19 | Conviction 1-2 | 43-47 | Reckoning 1-5 |
| 20-21 | Pursuit of Justice 1-2 | 48-50 | Iron Creed 1-3 |
| 22-26 | Redoubt 1-5 | 51 | Sacred Duty 1 |
| 27-29 | Precision 1-3 | 52 | Shieldsworn |
| 30-31 | Guardian's Favor 1-2 | 53-54 | Improved Judgement 1-2 |
| 32 | **Templar's Bulwark** (key C) | 55 | Vindication 1 |
| 33-34 | Shield Specialization 1-2 | 56 | Sacred Arbiter |
| 35-36 | Toughness 1-2 | 57-58 | Vindication 2-3 |
| 37 | **Swift Judgement** (Shift+Q) | 59 | Conviction 3 |
| 38-40 | Improved Righteous Fury 1-3 | 60 | Sacred Duty 2 |

Bold talents give a button. The `moba` alternative (0/35/16) adds Anticipation 3/5 and moves Retribution points;
`moba` itself says the Anticipation points can go into Toughness or Guardian's Favor. It changes no button, so the
grid works for both builds.

Trainer spells `wh_guide` calls mandatory: Judgement 4, Holy Strike 6, Seal of Fury 10, Retribution Aura 16,
Consecration 20. Optional: Seal of Justice 22, the resistance auras 28/32/36.

## Reach ranking for normal hands, while moving with WASD

Hand position: pinky on Shift (Ctrl one row lower), ring on A, middle on W, index on D, thumb on Space or the mouse
side buttons. Compared with Erika's table, 4, Z, X and C are one tier easier: a normal hand reaches them without
leaving WASD for long. Ctrl+Z/X/C are the copy/paste chords every PC user already knows.

| Tier | Keys | Why |
|---|---|---|
| 1 | 1, 2, 3, Q, E, R, F, Mouse4, Mouse5 | next to WASD or under the thumb |
| 2 | 4, Z, X, C, Shift+1/2/3, Shift+Q/E/R/F, Shift+Mouse4/5 | a short reach, or the pinky already on Shift |
| 3 | Shift+4, Shift+Z/X/C, Ctrl+Q/E/R/F, Ctrl+Z/X/C, Ctrl+Mouse4/5 | the pinky moves down to Ctrl, or a longer reach with Shift |
| 4 (avoid in combat) | Ctrl+1-4 (stance bar, see below) | a stretch plus a modifier |
| own | 5, Shift+5, Ctrl+5 | Oskar's; the addon never binds them |

## Auras, the stance bar and Ctrl+1-4 (decided on purpose)

Facts:
- Paladin auras live on the stance bar (`simc` "Use Shapeshift Bar", `ui` StanceBar.lua).
- The stance bar buttons are `SHAPESHIFTBUTTON1-10` (`ui` `Bindings_Camelot.xml` lines 240-267). The game's
  default keys for them are Ctrl+1 to Ctrl+0 (as in the shaman doc; verify with the `/run` lines in its Q4).
- The shaman layout (0.4.3) binds the whole Ctrl row, including Ctrl+1-4, to Action Bar 5.

Options:
1. **Keep the game defaults (recommended).** Ctrl+1-4 stay on stance bar buttons 1-4. The addon doesn't bind them.
   Action Bar 5 buttons 1-4 stay empty and unbound for the paladin. The Ctrl row on letters (Ctrl+Q/E/R/F/Z/X/C) is
   bound as usual.
2. Bind Ctrl+1-4 to Action Bar 5 buttons 1-4 and put chosen auras there (for example Retribution, Devotion,
   Concentration and one resistance aura).

Why option 1:
- Auras are switched between pulls, rarely in combat, and Ctrl+digits are tier 4 anyway. Nothing frequent loses a key.
- Zero bindings are replaced, and the stance bar highlights the active aura.
- Six auras don't fit in four keys either way; the stance bar shows all six as buttons.
- It is still a family: "Ctrl + a digit = an aura".

Expected order (the stance bar lists forms in the order they are learned; **verify in game**): Ctrl+1 Devotion (1),
Ctrl+2 Retribution (16), Ctrl+3 Concentration (22), Ctrl+4 Shadow Resistance (28). Frost (32) and Fire (36)
Resistance sit on stance buttons 5 and 6: click them. Ctrl+5 is Oskar's (by default it would be stance button 5).
Retribution is the aura `wh_guide` and `moba` both use by default; Devotion only when another paladin runs
Retribution.

## Pull walkthroughs

Dungeons and level ranges from `wh_dng`. Keys refer to the grid in section (a).

### Level 60, trash pull (Stratholme 48-58 or Scholomance 55-60: mostly undead)

1. Between pulls: X Righteous Fury if it fell off (30 min, or after a death), Shift+X Blessing of Kings on whoever
   lost it, Ctrl+2 Retribution Aura if it isn't on.
2. Pre-pull (`moba`): F Seal of Fury, 3 Holy Shield, 2 Consecration where the mobs will stand.
3. Pull: R Exorcism from 30 yd on an undead, or walk in. Then **Ctrl+Q opener** (Judgement + Swift Judgement +
   Holy Strike in one press) when the first mob reaches 10 yd.
4. Multi-target (`moba`): 2 Consecration first, Q Judgement and Shift+Q Swift Judgement on **different** mobs, 1 Holy
   Strike on a third. Shift+R Holy Wrath when 3+ undead stack up.
5. Loop (6-10 s): 3 Holy Shield → 1 Holy Strike (Shieldsworn: Holy Shield first) → Q Judgement (off GCD, press it
   with Holy Strike) → 2 Consecration if mana allows → R Exorcism.
6. Reactions: E Hammer of Justice on a caster (mouseover), Mouse5 Cleanse a disease (Stratholme is full of them),
   Mouse4 Blessing of Protection on a healer who pulled a mob, C Templar's Bulwark on a big pull, Z Healthstone.
7. Seal of Fury runs out after 30 s: F again.

### Level 60, boss (a Stratholme or Scholomance boss)

1. Pre-pull (`wh_guide`, fights over 20-30 s): Ctrl+F Seal of the Crusader → Q Judgement (40 s debuff, refreshed
   by melee and by Holy Strike with Sacred Arbiter) → F Seal of Fury.
2. Loop as above. Shift+E Hammer of Wrath from 20% (1 s cast, 6 s cooldown).
3. Big hit coming: C Templar's Bulwark. Forbearance blocks Shift+C and Ctrl+C for a minute.
4. Silence or interrupt phase: Ctrl+Mouse5 Voice of Truth.
5. Healer in trouble: Shift+Mouse4 Lay on Hands (mouseover), or Ctrl+Mouse4 Blessing of Sacrifice.
6. Mana low: Shift+Z Mana Potion.
7. Wipe-saving: Q Judgement first (taunt), then Shift+C Divine Shield (`moba` tip: the taunt keeps the boss on you).

### Level 40, trash pull (Razorfen Downs 37-47: undead)

- Before 42 there is no Holy Shield (key 3 is empty), and before 44 no Hammer of Wrath.
- R Exorcism pull (undead), Ctrl+Q opener (37+), 2 Consecration, 1 Holy Strike + Q Judgement, Shift+Q Swift
  Judgement on a loose mob, Ctrl+R Turn Undead on a third undead, C Templar's Bulwark (32+).

### Level 20-26, trash pull (Shadowfang Keep 22-30 or Blackfathom Deeps 22-32)

- Available: 1 Holy Strike, 2 Consecration (20), Q Judgement, F Seal of Fury, E Hammer of Justice, R Exorcism (only
  undead/demons), X Righteous Fury, Ctrl+C Divine Protection, Mouse4 Blessing of Protection, Mouse5 Purify,
  4 Flash of Light.
- Loop: F Seal of Fury → walk in → Q Judgement (taunt) → 2 Consecration → 1 Holy Strike, Q on cooldown.
- Shift+4 Holy Light out of combat to top up while questing solo.

## Frequency × urgency (level 60)

Presses per typical trash pull (~45 s) and boss (~2-3 min). Urgency: **R** = reaction (seconds matter), **P** =
planned (rotation or pre-pull), **O** = out of combat.

| Spell | Trash | Boss | Urgency | Key (tier) |
|---|---|---|---|---|
| Holy Strike | 6-8 | 20+ | P | 1 (1) |
| Judgement | 4-6 | 15+ | P, R (taunt) | Q (1) |
| Holy Shield (42) | 4-5 | 12+ | P | 3 (1) |
| Consecration (20) | 3-5 | 5-15 (mana) | P | 2 (1) |
| Exorcism (20) | 2-3 vs undead | 8+ vs undead | P | R (1) |
| Hammer of Justice | 0-1 | 1-2 | **R** | E (1) |
| Blessing of Protection | 0-1 | 0-1 | **R** | Mouse4 (1) |
| Cleanse (42) | 0-3 (by dungeon) | 0-5 | R | Mouse5 (1) |
| Seal of Fury | 1-2 | 4-6 | P | F (1) |
| Swift Judgement (37) | 1 | 2-3 | P, R (loose mob) | Shift+Q (2) |
| Hammer of Wrath (44) | 0-2 | 3-5 | P | Shift+E (2) |
| Holy Wrath (50) | 0-1 vs undead | 1-2 | P | Shift+R (2) |
| Seal of Righteousness | 0 | 0-1 (no-taunt) | P | Shift+F (2) |
| Healthstone / Healing Potion | 0-1 | 0-1 | **R** | Z (2) |
| Templar's Bulwark (32) | 0-1 | 1 | **R** | C (2) |
| Flash of Light (20) | 0-1 | 0-1 | R | 4 (2) |
| Lay on Hands | rare | 0-1 | **R** | Shift+Mouse4 (2) |
| Blessing of Freedom (18) | 0-1 | 0-1 | R | Shift+Mouse5 (2) |
| Divine Shield (34) | rare | rare | **R** | Shift+C (3) |
| Mana Potion | 0 | 0-1 | R | Shift+Z (3) |
| Opener macro (37) | 1 | 1 | P | Ctrl+Q (3) |
| Seal of the Crusader | 0 | 1 | P | Ctrl+F (3) |
| Turn Undead (24) | 0-1 vs undead | 0 | P | Ctrl+R (3) |
| Divine Protection | rare | rare | R | Ctrl+C (3) |
| Blessing of Sacrifice (46) | rare | 0-1 | R | Ctrl+Mouse4 (3) |
| Voice of Truth (20) | 0 | 0-1 | R | Ctrl+Mouse5 (3) |
| Holy Light | 0 (solo: between fights) | 0 | O | Shift+4 (3) |
| Righteous Fury | between pulls | – | O | X (2) |
| Blessing of Kings (20) | between pulls | – | O | Shift+X (3) |
| Redemption (12) | after a death | – | O | Ctrl+X (3) |
| Auras | between pulls | – | O | Ctrl+1-4 (stance bar) |

## What goes on 1 and 2

1 and 2 must carry spells pressed in combat in most pulls (the rule from the shaman layout).

- **1 = Holy Strike (6).** The most pressed button at every level. 1 sits right above Q, so Holy Strike and
  Judgement (off the GCD) can be pressed together, as `wh_guide`'s mana tip asks.
- **2 = Consecration (20).** Every pull from 20, the AoE threat button, pre-pull too.
- Runner-up: 2 = Holy Shield and 3 = Consecration, which puts Holy Shield right next to Holy Strike for the
  Shieldsworn order. Rejected because key 2 would then be empty until level 42; with Consecration it works from 20.

## Families

Rule: a family is spells that handle the same concept. It sits on one base key, with plain, Shift and Ctrl. Frequency
and urgency decide the base key and which member gets the easiest variant. A family never pushes a rare spell onto a
top plain key. Digit keys have no Ctrl member here, because Ctrl+1-4 belong to the auras.

| Family | Base key | Plain | Shift | Ctrl | Reason |
|---|---|---|---|---|---|
| Judgement | Q | Judgement (4) | Swift Judgement (37) | Opener macro: Judgement + Swift Judgement + Holy Strike (37) | One concept: "judge the target" (and taunt under Seal of Fury). Judgement is pressed every cooldown, so it gets plain; Swift Judgement is the second taunt for a loose mob; the opener fires all three at the pull. Q sits under 1 (Holy Strike). |
| Hammers | E | Hammer of Justice, mouseover harm + `/stopcasting` (8) | Hammer of Wrath (44) | – (kept for Hammer of the Righteous if trainable) | Both are "throw a hammer". Hammer of Justice is the only interrupt (a stun) and is a pure reaction, so it gets plain E. Hammer of Wrath is planned (the 20% window is visible). |
| Against undead | R | Exorcism (20) | Holy Wrath (50) | Turn Undead (24) | All three only work on undead (Exorcism and Holy Wrath also on demons). Endgame dungeons (Razorfen Downs, Stratholme, Scholomance) are full of undead, so R is busy where it matters. Exorcism is a rotation spell there, Holy Wrath an AoE, Turn Undead a CC. |
| Seals | F | Seal of Fury (10) | Seal of Righteousness (1) | Seal of the Crusader (6) | Only one seal is active. Fury is the tank seal, refreshed every 30 s. Righteousness is for an off-tank or a tank swap (no taunt). Crusader is judged once before a long fight (`wh_guide`). |
| Potions | Z | Healthstone, else Healing Potion (`FS_HEALTH`) | Mana Potion (`FS_MANA`) | – | One concept: "drink something". A tank needs health more urgently than mana. |
| Between pulls | X | Righteous Fury (10) | Blessing of Kings (20) | Redemption (12) | The key pressed between pulls: threat buff (must never be missing; Iron Creed needs it), the default blessing (re-apply after Protection, Freedom or Sacrifice replaces it), and the resurrection. |
| Forbearance | C | Templar's Bulwark (32) | Divine Shield (34) | Divine Protection (6) | They share Forbearance, so only one per minute: one key teaches that. Bulwark keeps you tanking (plain); Divine Shield halves your damage (Shift); Divine Protection stops your attacks (Ctrl, last). |
| Save a party member | Mouse4 | Blessing of Protection, MO (10) | Lay on Hands, MO with self fallback (10) | Blessing of Sacrifice, MO (46) | All "keep someone alive". Blessing of Protection is used most (5 min, 3 with Guardian's Favor); Lay on Hands is a 20 min cooldown. The thumb button works while the cursor is on a party frame. |
| Free a party member | Mouse5 | Cleanse, MO with self fallback (42; Purify (8) until then) | Blessing of Freedom, MO with self fallback (18) | Voice of Truth (20) | All "remove or prevent a bad effect": debuffs, snares/roots, silences. Cleanse is the most frequent. |
| Heals | 4 | Flash of Light, MO with self fallback (20) | Holy Light, MO with self fallback (1) | – (stance bar) | Fast heal on plain, long heal (cast between fights while questing) on Shift. |
| Auras | Ctrl+1-4 | – | – | the stance bar (game default) | See the stance bar section. |

Not grouped, and why:
- **Holy Strike (1), Consecration (2), Holy Shield (3)** each stay on their own top key. They are the core loop and
  are pressed every few seconds. Grouping them under one key (Shift/Ctrl) would put a rotation spell on a modifier.
- **Holy Shield with Templar's Bulwark ("shields")**: tempting, but Bulwark belongs with the other Forbearance
  spells, and Holy Shield is a 10 s rotation button, not a cooldown.
- **Other seals** (Wisdom 38, Light 30, Justice 22): the seal family has three slots; Crusader wins Ctrl because the
  tank's threat is Holy damage. `moba` ranks Wisdom first in raids; in a 5-man dungeon Oskar is usually the only
  paladin. The others are clicked.
- **Blessings of Might and Wisdom, Greater Blessings**: 1 h buffs, clicked out of combat.

## (a) Proposed layout

Abbreviations: **MO** = mouseover macro; *(lvl)* = the level the spell becomes available; "–" = spare (bound,
empty).

### Grid

Bindings (the same bars as the shaman layout 5): plain = main bar (`ACTIONBUTTON1-12`); Shift = Action Bar 2
(`MULTIACTIONBAR1BUTTON1-12`); Ctrl = Action Bar 5 (`MULTIACTIONBAR4BUTTON6-12` for Q, E, R, F, Z, X, C, in the
same order as Shift); Mouse4/5 with and without modifiers = Action Bar 3 buttons 7-12 (`MULTIACTIONBAR2BUTTON7-12`).
Action Bar 5 buttons 1-5 are not bound (Ctrl+1-4 stay on the stance bar, Ctrl+5 is Oskar's). Bars 6 and 7 are never
used.

| Base key | Plain | Shift | Ctrl |
|---|---|---|---|
| 1 | Holy Strike *(6)* | – | Devotion Aura (stance bar 1, game default) |
| 2 | Consecration *(20)* | – | Retribution Aura (stance bar 2, game default) |
| 3 | Holy Shield *(42, talent)* | – | Concentration Aura (stance bar 3, game default) |
| 4 | Flash of Light, MO + self *(20)* | Holy Light, MO + self *(1)* | Shadow Resistance Aura (stance bar 4, game default) |
| 5 | Oskar's own | Oskar's own | Oskar's own |
| Q | Judgement *(4)* | Swift Judgement *(37, talent)* | Opener: Judgement + Swift Judgement + Holy Strike *(37)* |
| E | Hammer of Justice, `/stopcasting` + MO harm *(8)* | Hammer of Wrath *(44)* | – (Hammer of the Righteous if trainable) |
| R | Exorcism *(20)* | Holy Wrath *(50)* | Turn Undead *(24)* |
| F | Seal of Fury *(10)* | Seal of Righteousness *(1)* | Seal of the Crusader *(6)* |
| Z | Healthstone, else Healing Potion (`FS_HEALTH`) | Mana Potion (`FS_MANA`) | – |
| X | Righteous Fury *(10)* | Blessing of Kings *(20)* | Redemption *(12)* |
| C | Templar's Bulwark *(32, talent)* | Divine Shield *(34)* | Divine Protection *(6)* |
| Mouse4 | Blessing of Protection, MO *(10)* | Lay on Hands, MO + self *(10)* | Blessing of Sacrifice, MO *(46)* |
| Mouse5 | Cleanse, MO + self *(42)*; Purify *(8)* until then | Blessing of Freedom, MO + self *(18)* | Voice of Truth *(20)* |

Spares for later: Shift+1, Shift+2, Shift+3, Ctrl+E, Ctrl+Z.

### Reasons per key

- **1 Holy Strike, 2 Consecration, 3 Holy Shield**: the core loop on the three easiest digits; see "What goes on 1
  and 2". Key 3 is empty until 42 (talent), the price of planning for 60.
- **4 / Shift+4 heals**: tier 2 for normal hands. A tank heals himself rarely in a group but often while questing.
- **Q Judgement family**: Judgement is the second most pressed button and the taunt. Under 1, so it can be pressed
  with Holy Strike.
- **E Hammers**: Hammer of Justice is the only "stop that cast" button, so it gets a tier-1 key with a mouseover harm
  macro (stun a caster without changing target).
- **R Against undead**: tier 1, because the level-40 and level-60 dungeons are mostly undead.
- **F Seals**: Seal of Fury is pre-pull and every 30 s. Tier 1 was free after the families above.
- **Z Potions, X Between pulls, C Forbearance**: tier 2 for normal hands; reactions (potion, Bulwark) on plain.
- **Mouse4/Mouse5**: the thumb buttons for help spells. As a tank the cursor is often on a mob, so every help macro
  except Blessing of Protection and Sacrifice falls back to Oskar himself (Protection would stop his attacks and
  Sacrifice can't target yourself).

### Macros

- **Help, mouseover with self fallback** (Lay on Hands, Cleanse/Purify, Blessing of Freedom, Flash of Light, Holy
  Light): `#showtooltip` + `/cast [@mouseover,help,nodead][help,nodead][@player] <Spell>`.
- **Help, mouseover without self fallback** (Blessing of Protection, Blessing of Sacrifice): `#showtooltip` +
  `/cast [@mouseover,help,nodead][help,nodead] <Spell>`. This is the shaman form minus the empty `[]`, so a hostile
  target never turns it into a self-cast.
- **Hammer of Justice**: `#showtooltip` + `/stopcasting` + `/cast [@mouseover,harm,nodead][] Hammer of Justice`
  (the shaman Earth Shock form).
- **Opener** (`moba`'s "Big Threat Opener", fixed):

  ```
  #showtooltip Swift Judgement
  /startattack
  /cast Judgement
  /cast Swift Judgement
  /cast Holy Strike
  ```

  Judgement and Swift Judgement are off the GCD, so all three should fire from one press. **Verify in game.**
- **Items**: `FS_HEALTH` and `FS_MANA` from the core.
- The settings switch "click-target / mouseover" works as for the shaman: plain spells in click-target mode, the
  macros above in mouseover mode. The opener and the item macros are always macros.
- Count: 9 spell macros + 2 item macros, well within the per-character limit.

## (b) Unkeyed spells (spellbook or stance bar, clicked)

| Spell | Why no key |
|---|---|
| Frost Resistance Aura (32), Fire Resistance Aura (36) | stance bar buttons 5-6, chosen per boss, out of combat |
| Seal of Wisdom (38), Seal of Light (30), Seal of Justice (22) | the seal family has three slots; see "Not grouped" |
| Blessing of Might (4), Blessing of Wisdom (14) | 1 h, out of combat; Kings is the default |
| Greater Blessings (Might 52, Wisdom 54, Kings 60) | 1 h, need Symbol of Kings, out of combat |
| Divine Intervention (30) | 1 h cooldown, a raid wipe tool |
| Purify (8), from 42 | Cleanse replaces it on Mouse5 (the same stand-in rule as Lightning Shield → Water Shield) |
| Sense Undead | tracking, set once |
| Summon Warhorse (40), Summon Charger (60) | mounts are in the mount journal |
| Hammer of the Righteous (40?) | unverified; goes to Ctrl+E if it is trainable |
| Blessing of Salvation / Sanctuary / Light | unverified in Forever (see Sources) |

## (c) Default bindings that are replaced

The same as the shaman layout, minus the stance bar:
- Q/E strafe, R reply, F assist (verify), Z sheath, X sit/stand, C character window.
- Shift+1-4 bar paging (all four are bound; Shift+1-3 are bound but empty).
- Ctrl+Q, Ctrl+E, Ctrl+F, Ctrl+Z, Ctrl+X, Ctrl+C (no default expected) and **Ctrl+R** (probably the framerate
  display; the preview warns).
- Mouse4 and Mouse5, also with Shift and Ctrl (no default expected; the README says to keep them as Button 4/5 in
  mouse software).

Not touched:
- **Ctrl+1-4**: stay on stance bar buttons 1-4 (the auras). This differs from the shaman layout, which binds them to
  Action Bar 5.
- **5, Shift+5 and Ctrl+5**: Oskar's own.
- Ctrl+6-0 (the stance bar), Alt with any key.

## (d) Snapshots by level

"–" = reserved but still empty. Spares, Oskar's 5 and the stance bar are left out.

| Key | 10 | 20 | 30 | 40 | 50 | 60 |
|---|---|---|---|---|---|---|
| 1 | Holy Strike | Holy Strike | Holy Strike | Holy Strike | Holy Strike | Holy Strike |
| 2 | – | Consecration | Consecration | Consecration | Consecration | Consecration |
| 3 | – | – | – | – | Holy Shield | Holy Shield |
| 4 | – | Flash of Light | Flash of Light | Flash of Light | Flash of Light | Flash of Light |
| Shift+4 | Holy Light | Holy Light | Holy Light | Holy Light | Holy Light | Holy Light |
| Q | Judgement | Judgement | Judgement | Judgement | Judgement | Judgement |
| Shift+Q | – | – | – | Swift Judgement | Swift Judgement | Swift Judgement |
| Ctrl+Q | – | – | – | Opener | Opener | Opener |
| E | Hammer of Justice | Hammer of Justice | Hammer of Justice | Hammer of Justice | Hammer of Justice | Hammer of Justice |
| Shift+E | – | – | – | – | Hammer of Wrath | Hammer of Wrath |
| R | – | Exorcism | Exorcism | Exorcism | Exorcism | Exorcism |
| Shift+R | – | – | – | – | Holy Wrath | Holy Wrath |
| Ctrl+R | – | – | Turn Undead | Turn Undead | Turn Undead | Turn Undead |
| F | Seal of Fury | Seal of Fury | Seal of Fury | Seal of Fury | Seal of Fury | Seal of Fury |
| Shift+F | Seal of Righteousness | Seal of Righteousness | Seal of Righteousness | Seal of Righteousness | Seal of Righteousness | Seal of Righteousness |
| Ctrl+F | Seal of the Crusader | Seal of the Crusader | Seal of the Crusader | Seal of the Crusader | Seal of the Crusader | Seal of the Crusader |
| Z / Shift+Z | potions | potions | potions | potions | potions | potions |
| X | Righteous Fury | Righteous Fury | Righteous Fury | Righteous Fury | Righteous Fury | Righteous Fury |
| Shift+X | – | Blessing of Kings | Blessing of Kings | Blessing of Kings | Blessing of Kings | Blessing of Kings |
| Ctrl+X | – | Redemption | Redemption | Redemption | Redemption | Redemption |
| C | – | – | – | Templar's Bulwark | Templar's Bulwark | Templar's Bulwark |
| Shift+C | – | – | – | Divine Shield | Divine Shield | Divine Shield |
| Ctrl+C | Divine Protection | Divine Protection | Divine Protection | Divine Protection | Divine Protection | Divine Protection |
| Mouse4 | Blessing of Protection | Blessing of Protection | Blessing of Protection | Blessing of Protection | Blessing of Protection | Blessing of Protection |
| Shift+Mouse4 | Lay on Hands | Lay on Hands | Lay on Hands | Lay on Hands | Lay on Hands | Lay on Hands |
| Ctrl+Mouse4 | – | – | – | – | Blessing of Sacrifice | Blessing of Sacrifice |
| Mouse5 | Purify | Purify | Purify | Purify | Cleanse | Cleanse |
| Shift+Mouse5 | – | Blessing of Freedom | Blessing of Freedom | Blessing of Freedom | Blessing of Freedom | Blessing of Freedom |
| Ctrl+Mouse5 | – | Voice of Truth | Voice of Truth | Voice of Truth | Voice of Truth | Voice of Truth |

Main levelling gaps: key 3 until 42, C until 32, Shift+Q/Ctrl+Q until 37. Before 32 the only defensive is Ctrl+C.

## Planned guide tabs for Protection

Generic core tabs stay (skills, layout, talents, review, settings). The spec adds:

| Tab | Outline |
|---|---|
| Role and threat | The tank's job: hold every mob, face them away, pull at a pace the healer can follow. Threat comes from Holy damage: Righteous Fury (+90% Holy threat) must always be on. Judgement under Seal of Fury is the taunt (3 s). No interrupt: Hammer of Justice stuns. |
| Rotation | Pre-pull (Seal of Fury, Holy Shield, Consecration), the opener macro, the single-target loop (Holy Shield → Holy Strike + Judgement → Consecration → Exorcism → Hammer of Wrath under 20%), multi-target (Consecration first, Judgements on different mobs). Mana: press Judgement together with Holy Strike (5-second rule), Shield Specialization and Sanctified Judgement return mana. |
| Seals and judgements | Judgement doesn't use up the seal. Seal of Fury (tank), Righteousness (no taunt / off-tank), Crusader (judge once before a long fight), Wisdom/Light/Justice and when they help. One Judgement debuff per paladin. Swift Judgement as the second taunt. |
| Auras and blessings | Auras on Ctrl+1-4 (stance bar): Retribution by default, Devotion if another paladin has Retribution, Concentration for casting, resistance auras per boss. Blessings last 1 h; Kings by default; Protection/Freedom/Sacrifice replace your other blessing on that player, so re-bless after. |
| Cooldowns | The Forbearance key (C): Templar's Bulwark first, Divine Shield and Divine Protection drop threat (taunt with Judgement first). Lay on Hands drains your mana. Voice of Truth for silences. Sacred Duty shortens all three. |
| Manners | Mark targets and say the kill order, wait for the healer's mana, don't pull with Exorcism into extra packs, tell the group when Divine Shield is used, Cleanse diseases and poisons the healer can't, and Blessing of Protection on a healer who has aggro. |

Every fact in these tabs gets a `SOURCES.md` line, as for the shaman.

## Core changes the paladin needs (shaman stays identical)

1. **Per-spec "keep the game default" keys.** The paladin spec lists `CTRL-1`-`CTRL-4` as untouched. Apply, clean,
   the preview and check.py skip them, and Action Bar 5 buttons 1-4 are neither bound nor cleared. The shaman list is
   empty, so its full Ctrl row stays.
2. **Help macro with self fallback**: a new macro kind (or a `selfFallback` flag) for
   `[@mouseover,help,nodead][help,nodead][@player]`, and a "no fallback" kind for Protection/Sacrifice. The shaman
   macros keep their exact text.
3. **Multi-cast macro kind** for the opener, through the pack hooks (like the shaman's Nature's Swiftness + Healing
   Wave hook): a list of off-GCD spells + a final GCD spell, `/startattack`, a fixed `#showtooltip`, available when
   its last required spell is learned.
4. **Stand-in for Purify → Cleanse**: reuse the Lightning Shield → Water Shield mechanism.
5. **Talent-granted buttons** (Holy Shield, Templar's Bulwark, Swift Judgement): the shaman already has talent
   spells (Nature's Swiftness, Mana Tide Totem), so the learned-spell detection should already work. Verify Holy
   Shield's rank chain (talent rank 1 = 20925, trainer ranks at 40/50/60).
6. **Rank data**: `tools/research/gen_ranks.py` gets a class parameter (folder and simc label "Paladin Spells").
   Seal of Fury's rank 1 id (1311649) differs from the Classic-style ids of later ranks; the rank table must link
   them.
7. **check.py**: per-pack grid rules (the paladin grid above), and the Ctrl-mirror rule must accept the
   keep-default keys.
8. **Guide key page**: draw "Ctrl+1-4 = auras (stance bar)" for the paladin.
9. Texts in `ja` and `en` (the pack follows the language picker from 0.5.1).
10. A new pack folder `ForeverSensei_Paladin` with `## X-ForeverSensei-API: 1`, LoadOnDemand, the spec
    `PROTECTION` as default.

## Open questions for Oskar

1. Approve the grid, especially: auras staying on the stance bar defaults (Ctrl+1-4), Exorcism's family on R, and
   Consecration on 2 (runner-up: Holy Shield on 2).
2. Seal of the Crusader or Seal of Wisdom on Ctrl+F?
3. What is your race? A racial (e.g. Will of the Forsaken for Undead) could go on a spare (Ctrl+Z or Shift+1).
4. Do you want Blessing of Might or Wisdom on a spare key instead of clicking?
5. Mouseover help macros: is the self fallback (cast on yourself when there is no friendly mouseover or target) what
   you want?

## Verify in game

1. Stance bar order: Devotion, Retribution, Concentration, Shadow, Frost, Fire Resistance, and Ctrl+1-4 fire
   them (`/run print(GetBindingAction("CTRL-1"))`).
2. Hammer of the Righteous at the trainer (level 40).
3. Seal of Fury's Judgement taunt: 3 s or 4 s.
4. The opener macro casts Judgement, Swift Judgement and Holy Strike from one press.
5. Blessing of Salvation, Sanctuary and Light: trainable or not.
6. Judgement keeps the seal (tooltip says it does).
7. The self-fallback help macros self-cast when a hostile mob is targeted.
8. Default bindings on Q, E, R, F, Z, X, C, Ctrl+R and Mouse4/5 (the `/run` lines in `research/keybind-layout.md`
   Q4).
9. Holy Shield rank upgrades replace the talent rank on the bar.
