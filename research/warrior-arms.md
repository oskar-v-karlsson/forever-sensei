# Warrior (Arms) research: spells, stance pages, grid proposal

Status: **approved as proposed** (commit `b01744e`; approved for Oskar while he was away), with the answers to the
open questions in part 6. Built in **0.9.0** as the third class pack, `ForeverSensei_Warrior` (Arms, layout 1), plus
the core changes in part 2 (`L.stancePages`) and the `FS_BANDAGE` item macro. The source of truth for the grid is now
`ForeverSensei_Warrior/Data/Arms/Layout.lua`; the README has the grid and the in-game checklist.

The player (Oskar's friend): a **Tauren warrior, level 23**, levelling and running dungeons as **melee DPS**, following
the Mobalytics Arms guide. Confirmed by Oskar:
- The pack's language is **English**. The language picker stays; Japanese falls back to English (part 5.2).
- **Every stance gets the same bars.** A spell that only works in some stances gets a **stance macro** that switches
  stance first, e.g. `/cast [nostance:3] Berserker Stance; Whirlwind` (part 3).
- **Racials are gated by race** (War Stomp for Tauren), with the 0.8.1 mechanism (`races = {...}` on the spell entry,
  `applyRaces` in `ForeverSensei/Core/Class.lua`).
- The v4 rules of `research/keybind-layout-v4.md` apply (family blocks 1-5 / QERF / ZXC, button n = key n, bar 1 plain,
  bar 2 Shift, bar 3 Ctrl, bar 6 mouse and in-combat clicks, bars 4/5 out of combat only; keys 1-5, Q, E, R, F, Z, X,
  C, Mouse4/5 with plain, Shift or Ctrl).

## Sources

Checked on **2026-11-14** unless noted.

| Key | Source | Used for |
|---|---|---|
| `wsimc` | [simc-forever](https://github.com/simulationcraft/simc-forever) SpellDataDump `warrior.txt`, build **1.60.1.70862** (commit `3c1d319e`), cited as `warrior.txt:<line>`; the parsed copy is `research/warrior_simc_1.60.1.70862.tsv` (by `tools/research/parse_simc.py`, unchanged). The later 70938 dump (`1c895ad3`) differs only in its header. | IDs, levels, ranks, rage, cooldowns, stance masks, talent rows/columns/max ranks |
| `nsimc` | the same commit's `nonclass.txt` (70862: lines 27843, 27861, 27872, 61727) | Tauren racials |
| `ui` | Forever UI code, [reckhou/WoWBlzCode](https://github.com/reckhou/WoWBlzCode) @ `7245053`, folder `Forever/BlizzardInterfaceCode/Interface/AddOns` (sparse clone) | stance paging, binding names, macro limit |
| `moba` | Mobalytics, [Arms Warrior guide](https://mobalytics.gg/wow-forever/classes/arms-warrior-guide), by Ahlaundoh ("Verified"), updated 2026-11-12. The site returns 403 to scripts, so it was read in the in-app browser on 2026-11-14. | talent path, rotation, stance use, racial notes, tips |
| `v4` | `research/keybind-layout-v4.md`, `research/keybind-layout-paladin.md` | rules, reach tiers, the stance-bar decision (P3), `defaultWarn` precedent |

Classic and Retail pages are not used. Forever changed several warrior spells (Slam at 20 with a cooldown, Charge out
of combat only, new talents), so only the 70862 dump and the Forever guide count.

---

# Part 1. Spells and talents

## 1.1 Trainable warrior spells, level 1-60 (`wsimc`)

Stance column: **B** Battle (mask `0x10000`), **D** Defensive (`0x20000`), **Z** Berserker (`0x40000`); "any" = no
stance mask. "next swing" = no GCD, the attack replaces the next white swing. Level 23 = what the player has now.

| Spell | Ranks: ID @ level | Rage | Cooldown | Stance | Known at 23 |
|---|---|---|---|---|---|
| Battle Stance | 2457 @ 1 (`warrior.txt:493`) | 0 | 1 s (category 47, shared) | – | yes |
| Heroic Strike | 78 @ 1, 284 @ 8, 285 @ 16, 1608 @ 24, 11564 @ 32, 11565 @ 40, 11566 @ 48, 11567 @ 56, 25286 @ 60 | 15 | next swing | any | rank 3 |
| Battle Shout | 6673 @ 1, 5242 @ 12, 6192 @ 22, 11549 @ 32, 11550 @ 42, 11551 @ 52, 25289 @ 60 | 10 | – | any | rank 3 |
| Charge | 100 @ 4, 6178 @ 26, 11578 @ 46 (`warrior.txt:67`) | 0 (gives rage) | 15 s, 8-25 yd, **not in combat** | B | rank 1 |
| Rend | 772 @ 4, 6546 @ 10, 6547 @ 20, 6548 @ 30, 11572 @ 40, 11573 @ 50, 11574 @ 60 | 10 | – (9 s bleed) | B, D | rank 3 |
| Thunder Clap | 6343 @ 6, 8198 @ 18, 8204 @ 28, 8205 @ 38, 11580 @ 48, 11581 @ 58 | 20 | 6 s | B, D | rank 2 |
| Hamstring | 1715 @ 8, 7372 @ 32, 7373 @ 54 | 10 | – | B, Z | rank 1 |
| Defensive Stance | 71 @ 10 (`warrior.txt:2`) | 0 | 1 s (category 47) | – | yes |
| Bloodrage | 2687 @ 10 | 20% health (gives rage) | 60 s | any | yes |
| Sunder Armor | 7386 @ 10, 7405 @ 22, 8380 @ 34, 11596 @ 46, 11597 @ 58 | 15 | – | any | rank 2 |
| Taunt | 355 @ 10 | 0 | 8 s | D | yes |
| Overpower | 7384 @ 12, 7887 @ 28, 11584 @ 44, 11585 @ 60 | 5 | 5 s, after a dodge | B | rank 1 |
| Shield Bash | 72 @ 12, 1671 @ 32, 1672 @ 52 | 10 | 12 s, needs a shield | B, D | rank 1 |
| Demoralizing Shout | 1160 @ 14, 6190 @ 24, 11554 @ 34, 11555 @ 44, 11556 @ 54 | 10 | – | any | rank 1 |
| Revenge | 6572 @ 14, 6574 @ 24, 7379 @ 34, 11600 @ 44, 11601 @ 54, 25288 @ 60 | 5 | 5 s | D | rank 1 |
| Shield Block | 2565 @ 16 | 10 | 5 s, needs a shield | D | yes |
| Mocking Blow | 694 @ 16, 7400 @ 26, 7402 @ 36, 20559 @ 46, 20560 @ 56 | 10 | 120 s | B | rank 1 |
| Disarm | 676 @ 18 | 20 | 60 s | D | yes |
| Cleave | 845 @ 20, 7369 @ 30, 11608 @ 40, 11609 @ 50, 20569 @ 60 | 20 | next swing | any | rank 1 |
| Retaliation | 20230 @ 20 (`warrior.txt:3305`) | 0 | 900 s | B | yes |
| **Slam** | 1240193 @ 20, 1464 @ 30, 8820 @ 38, 11604 @ 46, 11605 @ 54 (`warrior.txt:6218`) | 15 | **15 s**, 1.5 s cast | any | rank 1 |
| Intimidating Shout | 5246 @ 22 | 25 | 180 s | any | yes |
| Execute | 5308 @ 24, 20658 @ 32, 20660 @ 40, 20661 @ 48, 20662 @ 56 | 15 (+ extra rage) | – | B, Z | at 24 |
| Challenging Shout | 1161 @ 26 | 5 | 600 s | any | at 26 |
| Shield Wall | 871 @ 28 | 0 | 900 s, needs a shield | D | at 28 |
| Berserker Stance | 2458 @ 30 (`warrior.txt:514`) | 0 | 1 s (category 47) | – | at 30 |
| Intercept | 20252 @ 30, 20616 @ 42, 20617 @ 52 (`warrior.txt:3344`) | 10 | 30 s, 8-25 yd, stuns 3 s | Z | at 30 |
| Berserker Rage | 18499 @ 30 (`warrior.txt:3242`) | 0 | 30 s | Z | at 30 |
| Whirlwind | 1680 @ 36 (`warrior.txt:422`) | 25 | 10 s | Z | at 36 |
| Pummel | 6552 @ 38, 6554 @ 58 (`warrior.txt:885`) | 10 | 10 s, interrupt | Z | at 38 |
| Recklessness | 1719 @ 50 (`warrior.txt:467`) | 0 | 1800 s | Z | at 50 |

Passives worth a line in the guide: **Tactical Mastery** 1310185 @ 14 (`warrior.txt:6379`, baseline in Forever:
"You retain up to 10 Rage when you change Stances").

Talent spells on the path (part 1.2) that are **buttons**: Spearing Strike 1310222 (28), Sweeping Strikes 12292 (29),
Mortal Strike 12294 (39; ranks 21551 @ 48, 21552 @ 54, 21553 @ 60), Reckless Swings 1329555 (56).

| Talent button | Rage / cost | Cooldown | Stance | Source |
|---|---|---|---|---|
| Spearing Strike | 15 | 20 s | B | `warrior.txt:6501` |
| Sweeping Strikes | 30 | 30 s (20 s duration) | B | `warrior.txt:2181` |
| Mortal Strike | 30 | 6 s | any | `warrior.txt:2204` |
| Reckless Swings | 25% health | 15 s (8 s duration, 1 s GCD) | any | `warrior.txt:6707` |

Not on the path, so not planned (talent buttons): Death Wish, Piercing Howl, Last Stand, Bloodthirst, Shield Slam,
Concussion Blow.

## 1.2 Talent path (`moba`) cross-checked with `wsimc`

Forever has **one combined class tree** (`tree=class`, rows 1-7, columns 1-12 in `wsimc`'s "Talent Entry"). Columns
1-4 hold the Arms talents, 5-8 Fury, 9-12 Protection; Mobalytics still draws the old three trees. The dump has a
point requirement only for Flurry (25), Improved Whirlwind (25) and Bloodthirst (30); every talent below says
`req_points=0`. The tier gates are data-driven on the client side (nothing in `ui`), so they are an in-game check.

| Level(s) | Talent (`moba`) | ID | Row/col | Max | Prerequisite (`moba` arrows) |
|---|---|---|---|---|---|
| 10-12 | Improved Rend | 12286 | 1/3 | 3 | – |
| 13-14 | Improved Heroic Strike | 12282 | 1/1 | 3 | – |
| 15-16 | Improved Overpower | 12290 | 2/4 | 2 | – |
| 17 | Improved Tactical Mastery | 12295 (`:2231`) | 2/2 | 3 | – |
| 18-20 | Deep Wounds | 12834 | 3/3 | 3 | Improved Rend |
| 21-22 | Improved Tactical Mastery | 12295 | 2/2 | 3 | – |
| 23-24 | Impale | 16493 | 4/3 | 2 | Deep Wounds |
| 25-27 | Two-Handed Weapon Specialization | 12163 | 4/2 | 3 | – |
| 28 | **Spearing Strike** | 1310222 (`:6501`) | 4/1 | 1 | – |
| 29 | Sweeping Strikes | 12292 (`:2181`) | 5/2 | 1 | – |
| 30-31 | **Bloodthrill** | 1289682 (`:6332`) | 5/1 | 2 | – |
| 32-36 | **Weaponmaster** | 1290261 (`:6348`) | 5/3 | 5 | – |
| 37-38 | **Improved Slam** | 12862 (`:2851`) | 6/1 | 2 | – |
| 39 | Mortal Strike | 12294 (`:2204`) | 7/2 | 1 | Sweeping Strikes |
| 40 | Anger Management | 12296 (`:2245`) | 3/2 | 1 | Improved Tactical Mastery |
| 41-45 | Cruelty | 12320 | 1/7 | 5 | – |
| 46-50 | Unbridled Wrath | 12322 | 2/7 | 5 | – |
| 51-55 | Enrage | 12317 (`:2423`) | 3/8 | 5 | – |
| 56 | **Reckless Swings** | 1329555 (`:6707`) | 4/6 | 1 | – |
| 57 | Improved Bloodrage | 12301 | 1/9 | 2 | – |
| 58 | Improved Heroic Strike | 12282 | 1/1 | 3 | – |
| 59-60 | Improved Execute | 20502 | 4/8 | 2 | – |

Totals: **Arms 32** (IHS 3, Improved Rend 3, ITM 3, Improved Overpower 2, Anger Management 1, Deep Wounds 3,
Spearing Strike 1, 2H Spec 3, Impale 2, Bloodthrill 2, Sweeping Strikes 1, Weaponmaster 5, Improved Slam 2, Mortal
Strike 1), **Fury 18** (Cruelty 5, Unbridled Wrath 5, Enrage 5, Reckless Swings 1, Improved Execute 2), **Protection 1**
(Improved Bloodrage 1/2). 51 points = levels 10-60. Every rank fits its max rank in `wsimc`.

At level 23 the player should have: Improved Rend 3/3, Improved Heroic Strike 2/3, Improved Overpower 2/2, ITM 3/3,
Deep Wounds 3/3, Impale 1/2 (14 points).

**Enrage over Lingering Rage** (`moba`): Enrage 12317 (3/8, max 5, a 30% chance when hit to raise Physical damage) is
"much better" outdoors and in dungeons than Lingering Rage 1323964 (2/6, max 5, rage starts to decay later after combat). The
advisor recommends Enrage and names Lingering Rage only as the alternative.

The prerequisite arrows are read off Mobalytics' tree pictures (Arms: rows 2→4 col 2, 1→4 col 3, 3→5 col 3, 5→8
col 2; Fury 3→6 col 3, 5→8 col 2; Prot 1→4 col 2, 5→8 col 2, in Mobalytics' own grid). `wsimc` has no prerequisite
field, so the table marks them "per Mobalytics arrows" and the build adds an in-game check.

## 1.3 Forever-only spells and talents, verified (`wsimc`)

| Name | ID | What it does (dump description, short) |
|---|---|---|
| Spearing Strike | 1310222 | 15 rage, 20 s cooldown, Battle Stance. 75% weapon damage, more against Giants, Dragonkin and mounted targets, and dismounts. |
| Bloodthrill | 1289682 | Main-hand attacks against a target with your Rend have a 15% chance (at 2/2) to let you use Overpower. |
| Weaponmaster | 1290261 | One talent, effect by weapon: Swords 12281 an extra-attack chance; Maces and Staves 12284 ignore 15% armour; Axes and Polearms 12700 +1% crit per rank. |
| Reckless Swings | 1329555 (+ 1329554) | Costs 25% health, 15 s cooldown, 8 s. Your melee attacks give 5 extra rage (1329554, energize 50). 1 s GCD. |
| Improved Slam | 12862 | Slam's cooldown −5 s per rank (and cast −0.5 s); it swaps Slam to the override IDs 1310196-1310200 (`warrior.txt:6391`). The macro names "Slam", so the override follows. |
| Improved Tactical Mastery | 12295 | Keep 5/10/15 more rage on a stance change, on top of the baseline Tactical Mastery (10): **25 rage at 3/3**. |

## 1.4 Tauren racials (`nsimc`, identical in 70862 and 70938)

| Racial | ID | Facts | Plan |
|---|---|---|---|
| War Stomp | 20549 | 0.5 s cast, stuns up to 5 enemies within 8 yd for 2 s, 90 s cooldown | a button, `races = { 6 }` |
| Endurance | 20550 | passive, +5% health | guide line only |
| Cultivation | 20552 | 15 min cooldown, grows a copy of a nearby herb that anyone can pick, once per herb | bar 4 click, Tauren only |
| Plainsrunning | 1259918 | passive, +2% speed per second of moving, up to 60% (Forever-only) | guide line only |

`moba`: War Stomp is a strong on-demand interrupt; Endurance helps tanking; Plainsrunning is quality of life until the
mount at 40; Cultivation is "mostly useless"; Tauren is the weakest DPS race.

## 1.5 Disagreements and oddities

1. **Mortal Strike: level 39 (`moba`) vs spell level 40 (`wsimc`).** Talent spells carry the talent tier's level; the
   point at 39 should still give the button. In-game check.
2. **Improved Heroic Strike** appears three times in the path (13, 14, 58) and Anger Management once (40). That is
   3/3 and 1/1, consistent with the max ranks, just not in tree order.
3. **Two Charge spell sets.** 100/6178/11578 are Battle-only and "Cannot be used in combat". 1240287-1240289 (Battle or
   Defensive, usable in combat) are overrides from the Protection talent **Vanguard** 1310317 (4/10,
   `warrior.txt:6561`, Override Action Spell, base 1240287 misc 100). Arms doesn't take Vanguard, so the plan uses
   100/6178/11578.
4. **Victory Rush 402927** is in the dump at level 20 (`warrior.txt:4271`), but its only source is the rune
   "Engrave Gloves - Victory Rush" 403470 (`:4482`), a Season of Discovery leftover. Same for Commanding Shout 403215
   (`:4324`). Neither is planned; open question 6.
5. **Slam** is a level-20 spell with a 15 s cooldown in Forever (base 1240193), not the level-30 spell of Classic.
6. Mobalytics shows three trees; the client has one tree with 12 columns. The advisor names the talent, not a tree.

---

# Part 2. Stance pages (`ui`)

## 2.1 What Action Bar 1 shows in each stance

- Action Bar 1 (`MainActionBar`, keys `ACTIONBUTTON1-12`) uses its parent's `actionpage` attribute
  (`Blizzard_ActionBar/Shared/ActionButton.lua:466`, `useparent-actionpage`); `UpdateAction` calls `CalculateAction`
  (`:539-540`), which gives `action = id + (page − 1) × 12` (`Blizzard_FrameXML/SecureTemplates.lua:667-684`).
- `ActionBarController_UpdateAll` sets that page: with a bonus bar and page 1 selected it sets
  `MainActionBar:SetAttribute("actionpage", C_ActionBar.GetBonusBarIndex())`, otherwise `GetActionBarPage()`
  (`Blizzard_ActionBarController/ActionBarController.lua:159-171`, bonus case `:167-168`). It runs on `UPDATE_BONUS_ACTIONBAR`, "used for
  shapeshifts/stances" (`:14-15`), and on `UPDATE_SHAPESHIFT_FORM(S)` (`:27-28`).
- `ActionButtonUtil.lua:192-240` treats a slot whose `GetBonusBarIndexForSlot` differs from the current
  `GetBonusBarIndex` as inactive: "Mismatched bonus bar indices likely means we're in a different stance" (`:237`).
  `IconIntroAnimation.lua:33-40` uses the bonus index as the current page in the same way.
- The API (`Blizzard_APIDocumentationGenerated/ActionBarFrameDocumentation.lua`): `GetBonusBarIndex` (`:303`, a lua
  index), `GetBonusBarIndexForSlot` (`:312`), `GetBonusBarOffset` (`:327`), `HasBonusActionBar` (`:499`).
- The three stances are shapeshifts: Apply Aura Shapeshift, form 17 Battle (`warrior.txt` effect 681082), 18
  Defensive (678972), 19 Berserker (682035).

Pages: 1-2 are the main pages, 3-6 bars 2-5, 13-15 bars 6-8 (`MultiActionBars.xml:179/208/237`), 12 slots each
(`ActionButtonUtil.lua:2-3`). Pages 7-12 are left for bonus and override bars. The client fills in the numbers, so
the expected mapping (bonus offset 1/2/3 → page 7/8/9) is an in-game check:

| Stance | Bonus offset | Bonus page | Slots Action Bar 1 shows |
|---|---|---|---|
| none (never for a warrior once Battle Stance is learned) | 0 | 1 | 1-12 |
| Battle | 1 | 7 | 73-84 |
| Defensive | 2 | 8 | 85-96 |
| Berserker | 3 | 9 | 97-108 |

Bars 2, 3 and 6 have fixed `actionpage` attributes in `MultiActionBars.xml` (6, 5 and 13), so **only Action Bar 1
pages**. The Shift, Ctrl and mouse bars need nothing new.

## 2.2 Writing the same row to every page

Yes, the core can do it: `PickupSpell`/`PickupMacro` + `PlaceAction(slot)` work on any slot 1-120, including a
stance's page while you're in another stance (the client stores all pages; addons like Bartender do this). The
Berserker page can be written before level 30 too. Both are in-game checks (part 6, checks 1-2).

Proposal for the core (built only when the pack asks, so the other packs don't change):
- The layout data gets `L.stancePages = { 73, 85, 97 }` (first slot of each bonus page). `ns.BuildLayout` gives each
  bar-1 slot `mirrors = { slot + 72, slot + 84, slot + 96 }`.
- **BuildPlan / Execute / PlaceOne**: place the desired action in the bar-1 slot and every mirror. A mirror that
  differs is one more plan step, shown as "Action Bar 1 (Defensive) button n".
- **Verify** (`Layout.Current`, `Matches`, `/sensei verify`): a bar-1 entry is placed only when slot and all mirrors
  match; the report names the stance page that differs.
- **Backup and 元に戻す / Undo**: the backup records every written slot, mirrors included, and undo restores each.
  Bindings don't change: `ACTIONBUTTON1-12` follow the page by themselves.
- **Clean**: `L.old` and `L.retired` entries on bar 1 also check the mirrors.
- **RefreshMacros**: unchanged. A macro is one macro however many slots hold it; the stance macro kind only adds
  bodies (part 3).
- **Ranks** (`OutdatedRanks`, `UpgradeRanks`, `ApplyNewRanks`): check and upgrade the mirrors of plain-spell slots.
- **Unit-frame click-cast** (0.8.0): unchanged; it reads bar 6, which doesn't page.

**Paladin and Shaman stay byte-identical.** Neither layout sets `L.stancePages`, so no mirrors exist and every code
path is the old one. The facts behind it:
- Paladin auras have **no** Shapeshift aura effect (`paladin.txt`, 0 "Shapeshift (36)" effects); they only carry
  "Use Shapeshift Bar", which fills the stance bar, not a bonus bar. Oskar has played on bar 1 in every aura since 0.6.
- Ghost Wolf is a shapeshift (form 16, `shaman.txt:461`). Whether form 16 has a bonus bar lives in client data, not in
  `ui`. Erika's bar 1 has worked in Ghost Wolf since 0.1 (no report of an empty bar), and the shaman pack won't set
  `L.stancePages`, so nothing changes for her either way. In-game check 3 confirms it.
- The build proves it the way 0.8.0 did: the shaman and paladin scenario outputs before and after are compared byte
  for byte.

---

# Part 3. The stance macro kind

## 3.1 Body

The stance indices follow the stance bar order, which for a warrior is the learning order: **1 Battle, 2 Defensive,
3 Berserker** (`[stance:n]` = `GetShapeshiftForm()`; in-game check 4). Each macro switches to the spell's **home
stance** only when the current stance can't cast it:

| Allowed in (`wsimc` mask) | Home | Body |
|---|---|---|
| Battle only | Battle | `#showtooltip {spell}` / `/cast [nostance:1] Battle Stance; {spell}` |
| Defensive only | Defensive | `… /cast [nostance:2] Defensive Stance; {spell}` |
| Berserker only | Berserker | `… /cast [nostance:3] Berserker Stance; {spell}` |
| Battle or Defensive | Battle | `… /cast [stance:3] Battle Stance; {spell}` |
| Battle or Berserker | Battle | `… /cast [stance:2] Battle Stance; {spell}` |

Variants: `stance_harm` adds `[@mouseover,harm,nodead][]` before `{spell}` (Pummel also gets `/stopcasting` first, to
cut a Slam cast). In click-target mode the `_click` body drops the mouseover part, as the paladin's `interrupt_click`
does. The pack's data gives each spell its allowed stances and home; the core writes the conditional.

## 3.2 How it behaves

- **Two presses.** The stances share a 1 s category cooldown (category 47, `warrior.txt:493/2/514`) and list no GCD.
  The first press swaps stance, the second casts the spell. One press can't do both: the server must confirm the
  stance first. The guide says "press twice".
- **In combat.** `/cast` with `[stance]` conditions is secure and works in combat; the addon writes nothing then.
- **Rage.** A stance change keeps at most **10 rage** (Tactical Mastery 1310185) or **25 with Improved Tactical
  Mastery 3/3** (12295, level 22 on the path); the rest is lost. That matches `moba`'s multi-target advice: "dump rage
  to ~25 before swapping to Berserker, swap back to Battle at ~25".
- **`#showtooltip {spell}`** shows the spell's icon and cooldown in every stance, not the stance's.
- **Ranks**: `{spell}` is `Layout.MacroSpellName`, so `CheckMacroRank` works unchanged (it adds `(Rank N)` only if
  the client casts a lower rank). Slam keeps the name "Slam"; the Improved Slam override follows.
- **Not learned yet**: every Berserker-only spell (Intercept 30, Berserker Rage 30, Whirlwind 36, Pummel 38,
  Recklessness 50) comes at or after Berserker Stance (30), and every Defensive-only spell (Taunt 10, Revenge 14,
  Shield Block 16, Disarm 18, Shield Wall 28) at or after Defensive Stance (10). The spell's slot stays empty until
  it is learned, as now.
- **Macro count**: `MAX_CHARACTER_MACROS` = 30 (`Blizzard_APIDocumentationGenerated/MacroConstantsDocumentation.lua:11`).
  The grid below needs 21 stance macros + `FS_HEALTH` + `FS_BANDAGE` = 23 per-character macros at 60 (fewer at 23,
  where only learned spells get one).

## 3.3 Which spells need it

| Spell | Allowed | Home | Needs it from level |
|---|---|---|---|
| Charge, Overpower, Mocking Blow, Retaliation | B | Battle | 4, 12, 16, 20 (only matters once Defensive exists, 10) |
| Spearing Strike, Sweeping Strikes | B | Battle | 28, 29 |
| Rend, Thunder Clap, Shield Bash | B, D | Battle | 30 (only Berserker can't cast them) |
| Hamstring, Execute | B, Z | Battle | 10 / 24 (Defensive can't) |
| Taunt, Revenge, Shield Block, Disarm, Shield Wall | D | Defensive | 10, 14, 16, 18, 28 |
| Intercept, Berserker Rage, Whirlwind, Pummel, Recklessness | Z | Berserker | 30, 30, 36, 38, 50 |

Plain spells (any stance): Heroic Strike, Cleave, Sunder Armor, Slam, Mortal Strike, Bloodrage, Reckless Swings, the
four shouts, War Stomp.

**At level 23** there is no Berserker Stance, so the macros matter only between Battle and Defensive: Overpower,
Charge, Hamstring, Retaliation and Mocking Blow from Defensive; Taunt, Revenge, Shield Block and Disarm from Battle.
`moba` keeps Arms in Battle Stance almost always, so in practice the Defensive tools are the ones that swap.

Charge: it can't be used in combat, so its macro only swaps when he is out of combat in Defensive; with no rage there
is nothing to lose.

---

# Part 4. The grid (Arms layout 1)

## 4.1 Families

| Family | Members (level) | Why together |
|---|---|---|
| Strikes | Rend 4, Overpower 12, Slam 20, Mortal Strike 39, Execute 24 | the single-target priority (`moba`) |
| Other strikes | Heroic Strike 1, Sunder Armor 10, Spearing Strike 28, Hamstring 8 | the rest of `moba`'s single-target list (Sunder to 5 on bosses, Spearing vs Dragonkin/Giants, Hamstring with Windfury Totem, Heroic Strike as a 90+ rage dump) |
| Rage tools | Bloodrage 10, Reckless Swings 56, Berserker Rage 30 | buttons that give rage |
| Shouts | Battle Shout 1, Demoralizing Shout 14, Intimidating Shout 22, Challenging Shout 26 | all shouts |
| AoE | Sweeping Strikes 29, Whirlwind 36, Cleave 20, Thunder Clap 6 | `moba`'s multi-target list, in its order |
| Cooldowns and defensives | Retaliation 20, Recklessness 50, Disarm 18 | long cooldowns, pressed once in a hard fight |
| Stances | Battle 1, Defensive 10, Berserker 30 | stances |
| Threat (off-tank) | Taunt 10, Mocking Blow 16, Revenge 14 | for when the tank loses a mob or he tanks while levelling |
| With a shield | Shield Bash 12, Shield Block 16, Shield Wall 28 | need a shield (open question 4) |
| Stop that cast | Pummel 38, War Stomp (Tauren) | interrupts |
| Consumables | Healthstone else Healing Potion (`FS_HEALTH`), bandage (`FS_BANDAGE`, new) | survive |
| Gap-closers | Charge 4, Intercept 30 | get to the target |

## 4.2 Reach tiers (normal hands, WASD)

From `research/keybind-layout-paladin.md` ("Reach ranking for normal hands"), with key 5 added now that v4 plans it
(my judgment: one key past 4).

| Tier | Keys |
|---|---|
| 1 | 1, 2, 3, Q, E, R, F, Mouse4, Mouse5 |
| 2 | 4, Z, X, C, Shift+1/2/3, Shift+Q/E/R/F, Shift+Mouse4/5 |
| 3 | 5, Shift+4/5, Shift+Z/X/C, Ctrl+Q/E/R/F, Ctrl+Z/X/C, Ctrl+Mouse4/5 |
| 4 (avoid in combat) | Ctrl+1-5 |

## 4.3 Blocks and why

- **Plain 1-5, strikes**, in `moba`'s priority (Rend → Overpower → Mortal Strike → Slam → Execute), with Slam and
  Mortal Strike swapped so that keys 1-3 are all useful at 23 (Mortal Strike comes at 39). Both are 6 s / 5 s
  cooldown buttons at 60 (Slam with Improved Slam 2/2), so the swap costs nothing then.
- **Plain QERF, other strikes.** Heroic Strike on Q: at 23 it is the main rage dump.
- **Plain ZXC, rage tools.** Bloodrage "as often as possible" and Reckless Swings "on cooldown" (`moba`) are frequent
  at 56+; tier 2.
- **Shift 1-5, shouts.** Battle Shout before every pull on Shift+1 (tier 2). Intimidating Shout fears several mobs
  (risky in dungeons), so it gets a modifier, not a mouse button.
- **Shift QERF, AoE**, in `moba`'s multi-target order: Sweeping Strikes → Whirlwind → Cleave, then Thunder Clap
  (applied when the group asks).
- **Shift ZXC, cooldowns.** Rare, deliberate presses.
- **Ctrl 1-3, stances** on Action Bar 3 buttons 1-3, as the paladin's auras (v4 P3): button n = key n on screen, and the
  action button lights up in the active stance. This replaces the game's `SHAPESHIFTBUTTON1-3` on Ctrl+1-3; the
  preview warns (`L.defaultWarn`, as for the paladin) and undo restores. The stance bar still shows them.
  Runner-up: keep the game's defaults; for a warrior they already are Battle/Defensive/Berserker on Ctrl+1/2/3.
- **Ctrl QERF, threat; Ctrl ZXC, shield.** Tank tools for an Arms DPS: rare, tier 3. Ctrl+R replaces the framerate
  toggle (`TOGGLEFPS`); the preview warns, as now.
- **Mouse, three pairs** (bar 6 order B4, B5, S-B4, S-B5, C-B4, C-B5, as both packs):
  - **Mouse4/5, stop that cast: Pummel and War Stomp.** He has no friendly heals, so the plain pair gets the most
    urgent reaction: an interrupt. Pummel is a mouseover-harm stance macro (kick the caster you point at, with
    `/stopcasting` to cut a Slam). Both are low-risk misclicks: 10 rage, or a 90 s cooldown that stuns what is
    already around him.
  - **Shift+Mouse4/5, consumables:** `FS_HEALTH`, then a bandage on himself. Tier 2 for the potion.
  - **Ctrl+Mouse4/5, gap-closers: Charge and Intercept**, mouseover-harm stance macros. Charge is pressed before the
    pull, with no time pressure, and the modifier stops a misclick from pulling a pack (Oskar's 0.8.0 concern about
    risky mouse buttons). Runner-up: open question 1.

## 4.4 Grid at level 60

| Key | Plain (Action Bar 1, every stance) | Shift (Action Bar 2) | Ctrl (Action Bar 3) |
|---|---|---|---|
| 1 | Rend *(4, stance)* | Battle Shout *(1)* | Battle Stance *(1)* |
| 2 | Overpower *(12, stance)* | Demoralizing Shout *(14)* | Defensive Stance *(10)* |
| 3 | Slam *(20)* | Intimidating Shout *(22)* | Berserker Stance *(30)* |
| 4 | Mortal Strike *(39, talent)* | Challenging Shout *(26)* | – |
| 5 | Execute *(24, stance)* | – | – |
| Q | Heroic Strike *(1)* | Sweeping Strikes *(29, talent, stance)* | Taunt *(10, stance)* |
| E | Sunder Armor *(10)* | Whirlwind *(36, stance)* | Mocking Blow *(16, stance)* |
| R | Spearing Strike *(28, talent, stance)* | Cleave *(20)* | Revenge *(14, stance)* |
| F | Hamstring *(8, stance)* | Thunder Clap *(6, stance)* | – |
| Z | Bloodrage *(10)* | Retaliation *(20, stance)* | Shield Bash *(12, stance)* |
| X | Reckless Swings *(56, talent)* | Recklessness *(50, stance)* | Shield Block *(16, stance)* |
| C | Berserker Rage *(30, stance)* | Disarm *(18, stance)* | Shield Wall *(28, stance)* |
| Mouse4 | Pummel, MO harm *(38, stance)* | Healthstone else Healing Potion (`FS_HEALTH`) | Charge, MO harm *(4, stance)* |
| Mouse5 | War Stomp *(Tauren only)* | Bandage on yourself (`FS_BANDAGE`) | Intercept, MO harm *(30, stance)* |

"stance" = a stance macro (part 3). Spare keys: Shift+5, Ctrl+4, Ctrl+5, Ctrl+F. 38 of 42 keys hold something at 60
(37 for a non-Tauren warrior: Mouse5 stays empty, the 0.8.1 race gate).

## 4.5 Grid at level 23 (what he sees now)

Same keys; a spell not learned yet keeps its slot empty (*italic* = empty, with its level).

| Key | Plain | Shift | Ctrl |
|---|---|---|---|
| 1 | Rend | Battle Shout | Battle Stance |
| 2 | Overpower | Demoralizing Shout | Defensive Stance |
| 3 | Slam | Intimidating Shout | *Berserker Stance (30)* |
| 4 | *Mortal Strike (39)* | *Challenging Shout (26)* | – |
| 5 | *Execute (24)* | – | – |
| Q | Heroic Strike | *Sweeping Strikes (29)* | Taunt |
| E | Sunder Armor | *Whirlwind (36)* | Mocking Blow |
| R | *Spearing Strike (28)* | Cleave | Revenge |
| F | Hamstring | Thunder Clap | – |
| Z | Bloodrage | Retaliation | Shield Bash |
| X | *Reckless Swings (56)* | *Recklessness (50)* | Shield Block |
| C | *Berserker Rage (30)* | Disarm | *Shield Wall (28)* |
| Mouse4 | *Pummel (38)* | `FS_HEALTH` | Charge |
| Mouse5 | War Stomp | `FS_BANDAGE` | *Intercept (30)* |

At 23 every tier-1 key but R and Mouse4 is filled; both fill by 38.

## 4.6 Action Bar 6 (mouse block + in-combat clicks)

| Button | Key | Content |
|---|---|---|
| 1 | Mouse4 | Pummel |
| 2 | Mouse5 | War Stomp (Tauren only) |
| 3 | Shift+Mouse4 | `FS_HEALTH` |
| 4 | Shift+Mouse5 | `FS_BANDAGE` |
| 5 | Ctrl+Mouse4 | Charge |
| 6 | Ctrl+Mouse5 | Intercept |
| 7-12 | – | spare (no family spills over) |

## 4.7 Action Bar 4 (out of combat, clicked)

| Button | Content |
|---|---|
| 1 | Cultivation (Tauren only) |
| 2-12 | spare |

Action Bar 5 isn't used. A Hearthstone button is not planned (no pack places one today); open question 7.

## 4.8 Trade-offs and runner-ups

1. **Execute on 5 (tier 3).** It is spammed below 20% health. Runner-up: swap Rend and Execute (Execute on 1, Rend
   on 5); rejected because Rend starts every fight and keys 1-5 then no longer read like the priority list.
2. **Mortal Strike on 4 (tier 2)**, not 3, so that key 3 isn't empty for 16 levels.
3. **Charge on Ctrl+Mouse4 (tier 3).** The most iconic warrior button, but used before the pull. Runner-up: Charge on
   plain F and Hamstring to a free key; open question 1.
4. **Whirlwind on Shift+E (tier 2)** and Sweeping Strikes on Shift+Q: the AoE block is one family on Shift; dungeons
   use it a lot. Runner-up: AoE on plain QERF and "other strikes" on Shift; rejected because Heroic Strike and Sunder
   are the levelling bread and butter.
5. **Berserker Rage on plain C (tier 2)** for a spell Arms seldom uses, because the rage-tools family is one block.
6. **Hamstring** sits with the strikes (it is on `moba`'s single-target list), not with the interrupts.

---

# Part 5. Guide and language

## 5.1 Guide tabs (English, from `moba`)

| Tab | Content |
|---|---|
| Role | Melee DPS. Strong two-target cleave; leans on a shaman's Windfury Totem; no DPS cooldown besides Recklessness (30 min); weaker single target than Fury. Tauren: War Stomp is an on-demand interrupt, Endurance +5% health, Plainsrunning until the mount at 40. |
| Rotation | Single target: Battle Shout before the pull → Charge → Reckless Swings on cooldown → Bloodrage often (keep one for a boss below 20%) → Sunder Armor to 5 on bosses → Rend if missing and the mob lives 9 s → Overpower → Spearing Strike (Dragonkin/Giants) → Mortal Strike → Slam → Execute → refresh Rend under 3 s → Spearing Strike → Hamstring (with Windfury) → Heroic Strike at 90+ rage. Execute phase: nothing below Execute. Several mobs: Sweeping Strikes (no Hamstring or Spearing Strike during it) → Rend the main target → Overpower → Whirlwind → Rend others → Mortal Strike, Slam, Execute → Cleave at 75+ rage. |
| Stances | Arms lives in Battle Stance. Berserker only for Whirlwind (36), Pummel, Intercept. The stance macros swap for you: press twice. |
| Rage | You keep 10 rage on a stance change, 25 with Improved Tactical Mastery 3/3; dump to ~25 before swapping, swap back at ~25. Pool rage before a boss. |
| Cooldowns | Recklessness (30 min) and Retaliation (15 min) for the boss; Reckless Swings every 15 s; Bloodrage every minute. |
| Dungeon manners | Let the tank pull; the group may ask for Demoralizing Shout and Thunder Clap; Sunder Armor is up to 30% of the physical DPS on a boss; Cleave triggers Sweeping Strikes; Sweeping Strikes and Whirlwind reach from your own character (jump to reach further with Whirlwind); interrupt with Pummel or War Stomp. |

Card texts (what / when / where) follow the same sources, one line each, in English.

## 5.2 Japanese fallback

`ns.Raw` already falls back: pack ja → core ja → pack en → core en (`ForeverSensei/Core/Locale.lua:18-29`). So a
warrior pack with only `Locales/en.lua` works today: with Japanese chosen, the core UI stays Japanese and the warrior
texts show in English. Proposal for the build:
- The pack ships `Locales/en.lua` only and declares `## X-FS-Languages: en` in its TOC.
- `tools/check.py` (`check_texts`, line 609: "no Japanese") skips the ja rule for a pack that declares English only.
- When the player picks Japanese with an English-only pack loaded, one toast says (in Japanese) that this class
  pack is English only. The ✎ report button stays; reports work in either language.

---

# Part 6. Open questions for Oskar

**Answered (approval of `b01744e`, built in 0.9.0):**
1. Charge stays on **Ctrl+Mouse4** (mouseover stance macro); plain F keeps Hamstring.
2. **Pummel and War Stomp** stay on Mouse4/5.
3. Stances on **Action Bar 3, Ctrl+1-3**, like the paladin's auras, with the stance-bar preview warning.
4. **Keep the shield family**; its cards say it needs a shield equipped, which Arms rarely has.
5. **Keep the threat tools** (Taunt, Mocking Blow, Revenge); their cards call them emergency tools to save the healer.
6. **Victory Rush stays out** (and Commanding Shout); the README checklist asks whether it is in his spellbook.
7. **No Hearthstone.**
8. **Yes to `FS_BANDAGE`.**
9. Follow the guide's **talent order exactly as written** (`T.noRowGate`: the path takes Deep Wounds, row 3, at
   level 18 with 8 points spent, so Forever's point gates are not 5 per row and `tools/check.py` skips that rule for
   this path; the game's real gates are an in-game check).
10. Language: **English only**, `## X-FS-Languages: en` with the `ns.Raw` fallback of 5.2.

The questions as asked:

1. **Charge**: Ctrl+Mouse4 (proposed, misclick-safe) or plain F (one press, tier 1; Hamstring would move to the
   spare Ctrl+F or Shift+5)?
2. **Mouse4/5**: Pummel + War Stomp (proposed), or the gap-closers on the plain mouse pair?
3. **Stances on Action Bar 3** (proposed, like the paladin's auras) or keep the game's stance-bar Ctrl+1-3?
4. **The shield family** (Shield Bash, Shield Block, Shield Wall): Arms uses a two-hander. Keep them on Ctrl+Z/X/C for
   when he tanks with a shield, or leave those keys spare?
5. **Threat tools** (Taunt, Mocking Blow, Revenge): keep them for off-tanking, or leave Ctrl+QERF spare?
6. **Victory Rush and Commanding Shout**: does his level-23 spellbook show either? The dump says Season of Discovery
   rune only, so the plan leaves them out.
7. **Hearthstone** on Action Bar 4: wanted? (A new item kind.)
8. **Bandage**: a new `FS_BANDAGE` item macro (`/use [@player] <best bandage>`; the bandage item IDs get verified in
   the build). Wanted, or keep the potion alone?
9. **Improved Heroic Strike before Anger Management**: the guide's order; follow it as written?

## In-game checks (for the build's README checklist)

1. `/run print(GetBonusBarOffset(), C_ActionBar.GetBonusBarIndex())` in each stance: expected 1/7, 2/8, 3/9.
2. After a full apply, Action Bar 1 shows the same buttons in Battle, Defensive and (from 30) Berserker Stance.
3. Shaman in Ghost Wolf and paladin with any aura: `GetBonusBarOffset()` prints 0 and bar 1 is unchanged.
4. `/run for i=1,GetNumShapeshiftForms() do print(i, select(4, GetShapeshiftFormInfo(i))) end`: 1 = 2457, 2 = 71,
   3 = 2458.
5. A stance macro from the wrong stance: first press swaps, second casts; rage left = 25 with ITM 3/3.
6. Mortal Strike is on the talent row at level 39; the tree's point gates match the path.
7. `FS_HEALTH` and `FS_BANDAGE` use the best item in the bags.
