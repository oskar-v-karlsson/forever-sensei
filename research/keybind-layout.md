# Keybind layout research: Restoration Shaman, dungeon healer (proposal)

> **Superseded (0.7.0):** the current Restoration layout (layout 7, "family blocks") is in
> [keybind-layout-v4.md](keybind-layout-v4.md). This document keeps the pull walkthroughs, reach tiers and sources
> that v4 builds on; its grids, own-key rule and Action Bar 5 plan are history.

Status: **proposal for approval**. Nothing here is implemented yet. The current layout (version 2,
ForeverSensei 0.3.0) is in `ForeverSensei/Data/Shaman/Layout.lua`. Once the player and Erika approve the
tables in section (a), a separate task implements them.

Scope:
- Erika heals dungeons in a group most of the time; questing and solo come second.
- She moves with WASD, has small hands and two mouse side buttons.
- Allowed keys are now 1-5, Q, E, R, F, Z, X and C, with no modifier, Shift or Ctrl, plus Button4 and Button5
  (also with modifiers).
- **5 stays free in all variants** (5, Shift+5, Ctrl+5) for Erika's own use (the player's decision).

## Sources

Game facts come only from World of Warcraft: Forever sources. Every source was checked on **2026-11-11** unless a
different date is given.

| Key | Source | Used for |
|---|---|---|
| `wh_tt` | Wowhead Forever tooltips, `https://nether.wowhead.com/forever/tooltip/spell/<id>` and `.../item/<id>` (the data behind `https://www.wowhead.com/forever/spell=<id>`), read in a browser | cast time, cooldown, cost, duration, totem element ("Tools:" line), item ranks |
| `wh_abil` | [Wowhead Forever: Restoration Shaman abilities](https://www.wowhead.com/forever/guide/classes/shaman/restoration/healer-abilities) (by Woah, updated 2026-11-05) | how each spell is used in a group |
| `moba` | [Mobalytics: WoW Forever Restoration Shaman guide](https://mobalytics.gg/wow-forever/classes/restoration-shaman-guide) (updated 2026-11-04) | Erika's guide: totem advice, Water Shield, mouseover macro format, talent path |
| `simc` | `research/shaman_simc_1.60.1.70862.tsv` (from simc-forever SpellDataDump, client 1.60.1.70862) | levels, cast, cooldown, cost, duration |
| `ui` | Blizzard UI code for Forever 1.60.1, [reckhou/WoWBlzCode](https://github.com/reckhou/WoWBlzCode) folder `Forever` (commit 7245053) | binding names, bar pages, the Totem Bar |
| `wh_dng` | [Wowhead Forever: Dungeons](https://www.wowhead.com/forever/zones/instances/dungeons), read in a browser | the level ranges of the dungeons in the pull walkthroughs |
| `wm` | [WarcraftMaps: WoW Forever keybinds guide](https://warcraftmaps.com/guides/keybinds) (says it was checked against client 1.60.1; updated 2026-11-07) | **ergonomics and keybinding practice only**, never spell facts |

Sources that disagree:
- **Totemic Call (437009).**
  - The Wowhead Forever tooltip, `simc` and `moba` all say: 30 s cooldown, 25% of base mana, "Relocates your
    active totems to your location".
  - The prose of `wh_abil` still says "a target location within 30 yards on a 1-minute cooldown".
  - The tooltip is the client data, so this proposal uses **30 s, at your own location**. `SOURCES.md` still
    lists this disagreement as unresolved; the implementation task should update that row.
- **Riptide (408521).** `simc` gives a 12 s cooldown; the prose of `wh_abil` says 6 s. Either way it is short,
  so the key choice is the same. This proposal uses the client data (12 s).
- **Not in this proposal:**
  - Tranquil Air Totem is named in `wh_abil`, but it is in neither the `simc` shaman dump nor a Wowhead
    Forever tooltip (spell 25908 returns empty).
  - Earth Shield (408514) exists in Forever but is learned through a rune-style spell (409947 "Gain the Earth
    Shield ability"). It is not in Erika's talent path, in `moba`, or in our data.
  - Both are flagged, not guessed. If Erika ever gets Earth Shield, it belongs next to Water Shield.

## Q1: How often each spell is used in a dungeon (levels 1-60)

Types:
- **React**: cast the moment something happens. It needs a fast key that works while moving.
- **Pull**: cast at every pull or every few pulls.
- **Set-up**: cast between pulls, about every 5 minutes (when the 5-minute totems run out), after a wipe, or once
  per dungeon.
- **Cast**: a spell with a cast time, used while standing still, so reach matters less.
- **OOC**: out of combat or travel.

Cast, cooldown and cost are rank 1, from `simc`, or from `wh_tt` for spells missing from the dump.

| Spell | Lvl | Cast / CD / cost / duration | Use in a dungeon | Type | Proposed key |
|---|---|---|---|---|---|
| Healing Wave | 1 | 1.5 s cast (longer at higher ranks) / – / 25 | constant: the main heal for expected damage on the tank | Cast | F |
| Lightning Bolt | 1 | 1.5 s / – / 15 | often, when healing need is light | Cast | 3 |
| Rockbiter Weapon | 1 | instant / – / 15 | before the dungeon, weapon buff | OOC | none |
| Earth Shock | 4 | instant / 6 s / 30, 2 s lockout | the interrupt for dangerous casts | React | Q |
| Stoneskin Totem | 4 | instant / – / 30, 5 min, Earth | every pull before 20 (Erika's habit); from 20 in the Call of the Elements set, and by hand after Tremor replaced it | Pull | Shift+E |
| Earthbind Totem | 6 | instant / 15 s / 6% base mana, 45 s, Earth | rare: runners, kiting | React | Ctrl+Q |
| Stoneclaw Totem | 8 | instant / 30 s / 15, 15 s, Earth | rare: enemies hitting the healer | React | Ctrl+E |
| Lightning Shield | 8 | instant / – / 45, 10 min | levels 8-19 only, replaced by Water Shield | Set-up | X until 20 |
| Flame Shock | 10 | instant / 6 s / 55, 12 s DoT | often when DPSing; instant, usable while moving | React/DPS | 2 |
| Searing Totem | 10 | instant / – / 25, **30 s** (55 s at the top rank), Fire | every pull (Erika's habit; it only lasts 30-55 s) | Pull | Shift+R |
| Flametongue Weapon | 10 | instant / – / 30 | before the dungeon | OOC | none |
| Strength of Earth Totem | 10 | instant / – / 25, 5 min, Earth | instead of Stoneskin for melee groups | Set-up | none (Totem Bar set) |
| Fire Nova | 12 | instant / 10 s / 65 | rare for a healer: AoE around the Fire totem | DPS | none (Ctrl+R from 0.6.1, Fire family) |
| Purge | 12 | instant / – / 10% base mana | sometimes: enemy buffs | React | Shift+3 |
| Ancestral Spirit | 12 | 10 s / – / 90% base mana | after a death or wipe | OOC | none |
| Cure Poison | 16 | instant / – / 9% base mana | often in poison dungeons | React | Shift+Mouse4 |
| Tremor Totem | 18 | instant / – / 60, 5 min, Earth | fear, charm and sleep fights (Erika uses it a lot) | React | Shift+F |
| Call of the Elements | 20 | 3 s / – / none / GCD | between pulls whenever the 5-minute totems run out (about every 5 minutes, i.e. every few pulls), and after a wipe | Set-up | Shift+1 |
| Frost Shock | 20 | instant / 6 s / 115, 8 s slow | rare: slow a runner or a chaser | React | Shift+Q |
| Totemic Recall | 20 | instant / – / returns 25% of the totems' mana | after the last pull, before a long run | OOC | Ctrl+1 |
| Frostbrand Weapon | 20 | instant / – / 60 | solo only | OOC | none |
| Ghost Wolf | 20 | 3 s / – / 100, outdoors only | none: Erika's talent path has no Improved Ghost Wolf, so it cannot be used indoors | OOC (questing) | Ctrl+C |
| Healing Stream Totem | 20 | instant / – / 40, 5 min, Water | part of the pull set; swap with Mana Spring | Set-up | none (in the Call of the Elements set) |
| Lesser Healing Wave | 20 | 1.5 s / – / 105 | the fast emergency heal | React (cast) | E |
| Water Shield | 20 (talent) | instant / – / none, 10 min, 3 globes | refresh between pulls or in gaps | Set-up | X |
| Totemic Call | 22 | instant / 30 s / 25% base mana | every pull: moves the totems to you | Pull | 1 |
| Water Breathing | 22 | – | never in a dungeon | OOC | none |
| Cure Disease | 22 | instant / – / 9% base mana | often in disease dungeons | React | Shift+Mouse5 |
| Poison Cleansing Totem | 22 | instant / – / 10% base mana, Water | poison-heavy fights | React | Ctrl+Mouse4 |
| Frost Resistance Totem | 24 | instant / – / 75, Fire | rare, boss-specific | Set-up | none (Totem Bar) |
| Mana Tide Totem | 25 (talent) | instant / 5 min / 10, 13 s, Water | long fights, low mana | React | Ctrl+Z |
| Magma Totem | 26 | instant / – / 230, 20 s, Fire | rare for a healer: big packs | DPS | none (Shift+4 from 0.6.1, Fire family) |
| Far Sight | 26 | 2 s / – / 80 | never | OOC | none |
| Mana Spring Totem | 26 | instant / – / 40, 5 min, Water | the default Water totem from 26 | Set-up | Shift+Z |
| Fire Resistance Totem | 28 | instant / – / 75, Water | rare, boss-specific | Set-up | none (Totem Bar) |
| Flametongue Totem | 28 | instant / – / 90, Fire | rare: caster-heavy groups | Set-up | none |
| Water Walking | 28 | – | never in a dungeon | OOC | none |
| Call of the Ancestors | 30 | 3 s / – / none | a second preset (e.g. the Tremor set) | Set-up | none (next to CotE) |
| Astral Recall | 30 | – | after the dungeon | OOC | none |
| Grounding Totem | 30 | instant / 15 s / 6% base mana, 45 s, Air | against dangerous single casts | React | Ctrl+F |
| Nature Resistance Totem | 30 | instant / – / 75, Air | rare, boss-specific | Set-up | none (Totem Bar) |
| Windfury Weapon | 30 | instant / – / 90 | solo only | OOC | none |
| Nature's Swiftness | 30 (talent) | instant / 3 min | emergency: NS + Healing Wave | React | Mouse5 (macro) |
| Reincarnation | 30 | passive / 60 min | self-resurrect after a wipe | – | none (passive) |
| Chain Lightning | 32 | 2.5 s / 6 s / 245 | AoE damage when healing is light | Cast/DPS | 4 |
| Windfury Totem | 32 | instant / – / 115, Air | melee groups, through the Totem Bar set | Set-up | none |
| Sentry Totem | 34 | instant / – / 65, Air | never | OOC | none |
| Windwall Totem | 36 | instant / – / 115, Air | rare, ranged-heavy fights | Set-up | none (Totem Bar) |
| Disease Cleansing Totem | 38 | instant / – / 10% base mana, Water | disease-heavy fights | React | Ctrl+Mouse5 |
| Call of the Spirits | 40 | 3 s / – / none | a third preset (boss set) | Set-up | none (next to CotE) |
| Chain Heal | 40 | 2.5 s / – / 260, 3 targets | constant from 40: the main group heal | Cast | R |
| Riptide | 40 (talent) | instant / 12 s / 150, 15 s HoT, +25% Chain Heal | on cooldown on the tank; usable while moving | React | Mouse4 |
| Grace of Air Totem | 42 | instant / – / 155, Air | melee groups, through the Totem Bar set | Set-up | none |

## Q2: Totem workflow in Forever

### The call spells (`wh_tt`, `simc`)

| Spell | Lvl | Cast | CD | Cost | What it does |
|---|---|---|---|---|---|
| Call of the Elements (66842) | 20 | 3 s | none (1.5 s GCD) | "None" in the tooltip (verify in game: may be the totems' own cost) | "Simultaneously places up to 4 totems specified in the Totem Bar" (set 1) |
| Call of the Ancestors (66843) | 30 | 3 s | none | as above | the same, with Totem Bar set 2 |
| Call of the Spirits (66844) | 40 | 3 s | none | as above | the same, with Totem Bar set 3 |
| Totemic Call (437009) | 22 | instant | **30 s** | 25% base mana, 30 yd | relocates your active totems to your location |
| Totemic Recall (36936) | 20 | instant | none | returns 25% of the mana of each totem it destroys | dismisses all your totems |

### Totem durations (`simc`, all ranks; checked 2026-11-11)

| Duration | Totems |
|---|---|
| 5 min (300 s) | Stoneskin, Strength of Earth, Tremor, Healing Stream, Mana Spring, Poison Cleansing, Disease Cleansing, Windfury, Grace of Air, Windwall, Sentry, Flametongue Totem, and the Frost, Fire and Nature Resistance totems |
| 30-55 s by rank (30, 35, 40, 45, 50, 55 s) | Searing |
| 45 s | Earthbind, Grounding |
| 20 s | Magma |
| 15 s | Stoneclaw |
| 13 s | Mana Tide |

So even the long totems run out about every 5 minutes. In a dungeon that is every few pulls, not once per run.
Totemic Call only moves totems that are still up; it does not renew them.

### One totem per element (`wh_tt` "Tools:" line)

- **Earth:** Stoneskin, Earthbind, Stoneclaw, Strength of Earth, Tremor.
  - **Tremor replaces Stoneskin**, because both are Earth totems.
- **Fire:** Searing, Magma, Flametongue Totem, Frost Resistance.
- **Water:** Healing Stream, Mana Spring, Poison Cleansing, Disease Cleansing, Mana Tide, Fire Resistance.
- **Air:** Grounding, Windfury, Grace of Air, Nature Resistance, Windwall, Sentry.

### What a resto healer does (from `moba` and `wh_abil`)

- Mobalytics: "Choose totems for the fight rather than spending mana on a full set for every easy pull".
- Save a practical Call of the Elements preset and adjust it.
- Use Totemic Call to move the set after moving to a safe spot.
- Use Totemic Recall when done.
- Searing Totem can break a careful pull or crowd control.
- Mana Spring and Healing Stream share the Water slot, so pick one.

### Recommended dungeon flow for Erika

1. **Before a pull, whenever the 5-minute totems have run out (about every 5 minutes, i.e. every few pulls), and
   after a wipe:** press **Call of the Elements** (Shift+1). The 3 s cast places the whole set again.
   - Watch the totem icons (Totem Bar or the totem timers by the player frame): when they are gone or almost
     gone, recast the set between pulls instead of Totemic Call.
   - Suggested set 1: Stoneskin + Searing + Healing Stream (Mana Spring from 26) + an Air totem
     (Windfury for a melee group from 32, otherwise Grace of Air from 42).
2. **Every pull in between:**
   - Press **Totemic Call** (1) where you will stand to heal. The 5-minute totems that are still up come with
     you at 25% base mana, which is cheaper and faster than recasting them (30 s cooldown).
   - Press **Searing Totem** (Shift+R). It only lasts 30-55 s, so it is gone by the next pull anyway.
3. **React:**
   - Tremor (Shift+F) against fear, charm and sleep. It replaces Stoneskin until you press Stoneskin (Shift+E)
     again.
   - Grounding (Ctrl+F) against a dangerous caster.
   - Poison or Disease Cleansing (Ctrl+Mouse4, Ctrl+Mouse5): for a poison- or disease-heavy dungeon, put it in the Water
     slot of the Totem Bar set (`wh_abil`: usually better than casting the cures). The keys are for swapping it in
     by hand. Cure Poison and Cure Disease (Shift+Mouse4, Shift+Mouse5) are for the player the totem misses.
   - Mana Tide (Ctrl+Z) when your mana is low in a long fight. It is a Water totem too, so press Mana Spring
     (Shift+Z) again when Mana Tide ends (13 s).
   - Frost Shock (Shift+Q) for one runner, Earthbind (Ctrl+Q) for several.
4. **Leaving:** press **Totemic Recall** (Ctrl+1) to get some mana back.

Before level 22 there is no Totemic Call. At those levels, cast Stoneskin and Searing by hand at each pull, as
Erika does now.

## Q3: The Totem Bar (`ui`: `Blizzard_ActionBar/Shared/MultiCastActionBarFrame.lua`)

- **Layout:** 3 pages × 4 slots, plus a summon button (66842, 66843 or 66844) and a recall button (36936).
  - Element order on a page: FIRE=1, EARTH=2, WATER=3, AIR=4.
  - The action number is `slot + (C_ActionBar.GetMultiCastBarIndex() - 1) * 12`.
- **No binding names.** `Blizzard_FrameXML/Bindings_Camelot.xml` declares no `MULTICAST*` binding, so the Totem
  Bar buttons cannot be bound in the Key Bindings window.
  - `SetBindingClick(key, "MultiCastActionButtonN")` might work. **Verify in game.**
  - This doesn't matter much: the three call spells are normal spells and go on normal action bars.
- **Setting the sets from an addon:**
  - Blizzard's own flyout calls `SetMultiCastSpell(action, spellId)` from a plain `OnClick`. `SecureTemplates.lua`
    also has a `multispell` secure action.
  - So an addon can probably fill the sets **out of combat**. This is not proven: **verify in game** with
    `/run SetMultiCastSpell(<action>, 8071)` and check the Totem Bar.
  - In combat, treat it as blocked, like all bar changes under the 12.x restrictions.
- **Recommendation: both.**
  - One key for Call of the Elements with a preset.
  - Separate keys for the totems she swaps by hand: Tremor, Grounding, Mana Tide, Mana Spring and the cleansing
    totems.
  - Separate keys for her two per-pull totems: Stoneskin and Searing.
  - A key for **Totemic Call**, the cheapest way to "bring the set along".
  - Optional for the implementation task: the addon offers to fill set 1 with the suggested totems (out of combat,
    with confirmation). If the in-game check fails, the card explains how to pick the totems with the flyout
    (click the arrow above each Totem Bar slot).

## Q4: Keys, ergonomics and the defaults they replace

### Reach ranking for small hands, while moving with WASD

Hand position: ring finger on A, middle on W, index on D, pinky on Shift (Ctrl is one row lower). Keys you can
press without lifting the movement fingers are best. Cast-time heals are cast standing still, so their reach
matters less than for instant reactions. This reasoning is in line with `wm` (easy: 1-4, Q, E, R, F; good: 5,
Z, X; side mouse buttons; Shift with any of these).

| Tier | Keys | Why |
|---|---|---|
| 1 | Mouse4, Mouse5, Q, E, R, F | thumb on the mouse (the cursor stays on the party frames); index or middle finger next to WASD |
| 2 | 1, 2, 3, Shift+Q/E/R/F, Shift+Mouse4/5 | a short reach up, or the pinky already resting on Shift |
| 3 | 4, Z, Shift+1/2/3, Ctrl+Q/E/R, Ctrl+Mouse4/5 | a longer reach, or the pinky moved down to Ctrl |
| 4 | X, C, 5, Shift+Z/X/C, Shift+4, Ctrl+Z/C/F | a stretch for a small hand; you stop moving to press it |
| 5 (avoid in combat) | Shift+5, Ctrl+X, Ctrl+1-5 | a stretch plus a modifier |

### Binding names (`ui`, verified)

- **No modifier:** `ACTIONBUTTON1-12` (main bar, slots 1-12).
- **Shift:** `MULTIACTIONBAR1BUTTON1-12`, which is Action Bar 2 (MultiBarBottomLeft, page 6, slots 61-72).
- **Ctrl (new):** `MULTIACTIONBAR5BUTTON1-12` is **Action Bar 6** (`MultiBar5`, page 13, slots 145-156, setting
  `PROXY_SHOW_ACTIONBAR_6`), and `MULTIACTIONBAR6BUTTON1-12` is Action Bar 7 (`MultiBar6`, slots 157-168).
  ForeverSensei 0.4.0 used them, but they show up in the middle of the screen, so from 0.4.1 they are retired.
- **As implemented (0.4.3, layout 5):**
  - Ctrl = `MULTIACTIONBAR4BUTTON1-12`, Action Bar 5 (MultiBarLeft, slots 37-48, shown at the right edge). It mirrors
    Action Bar 2: button i has Ctrl where Action Bar 2 has Shift (1, 2, 3, 4, 5, Q, E, R, F, Z, X, C).
  - Mouse buttons = `MULTIACTIONBAR2BUTTON7-12`, the right half of Action Bar 3 (MultiBarBottomRight, slots 55-60):
    Mouse4, Mouse5, Shift+Mouse4, Shift+Mouse5, Ctrl+Mouse4, Ctrl+Mouse5.
- **Key strings** (`Blizzard_FrameXML/BindingUtil.lua`):
  - The mouse buttons are `BUTTON4` and `BUTTON5`.
  - Chords are written ALT-CTRL-SHIFT-key, e.g. `CTRL-Q` and `SHIFT-BUTTON4`.
- **Related defaults:** `ModifiedClick` has SELFCAST=ALT, PICKUPACTION=SHIFT and STICKYCAMERA=CTRL. These only
  affect mouse clicks on buttons, not key bindings.
- **Verify in game:** a hidden action bar may not fire its key bindings, so the addon must turn on Action Bars 6
  and 7.

### Default bindings that are replaced

The client files list every binding name but not its default key (`wm` says the same), so the defaults below are
**expected and must be verified in game**. Verify with:

```
/run for _,k in ipairs({"Q","E","R","F","Z","X","C","SHIFT-1","SHIFT-5"}) do print(k,GetBindingAction(k)) end
/run for _,k in ipairs({"CTRL-1","CTRL-Q","CTRL-E","CTRL-F","CTRL-Z","CTRL-C","BUTTON4","BUTTON5","SHIFT-BUTTON4","SHIFT-BUTTON5","CTRL-BUTTON4","CTRL-BUTTON5"}) do print(k,GetBindingAction(k)) end
```

| Key | Expected default | Already replaced by layout v2? |
|---|---|---|
| 1-5 | ACTIONBUTTON1-5 | stays an action button |
| Q / E | STRAFELEFT / STRAFERIGHT (A/D turn) | yes |
| R | REPLY | yes |
| F | ASSISTTARGET (verify) | yes |
| Z | TOGGLESHEATH | yes |
| X | SITORSTAND | yes |
| C | TOGGLECHARACTER0 (character window) | yes; the C button on the micro menu still opens it |
| Shift+1-5 | ACTIONPAGE1-5 (bar paging) | yes |
| Shift+Q/E/R/F/Z/X/C | none expected | yes |
| **Ctrl+Q/E/F/Z/C** | none expected | **new** |
| Ctrl+R | TOGGLEFPS (framerate display), likely | from 0.4.3: empty Action Bar 5 button; from 0.6.1: Fire Nova |
| **Mouse4 / Mouse5, also with Shift and Ctrl** | none expected | **new** |
| **Ctrl+1** | SHAPESHIFTBUTTON1 (stance bar) | **new**: a shaman's only stance-bar spell is expected to be Ghost Wolf, which has Ctrl+C anyway (verify) |
| Ctrl+2-0 | SHAPESHIFTBUTTON2-10 | from 0.4.3: Ctrl+2-4 get empty Action Bar 5 buttons; Ctrl+5 is Erika's; Ctrl+6-0 not touched |

## Q5: Mouseover macros

The format is from `moba`: `/cast [@mouseover,help,nodead][help,nodead][@player] <Spell>`. The addon already
makes these in mouseover mode, using the highest rank.

| Spell | Macro? | Why |
|---|---|---|
| Healing Wave, Lesser Healing Wave, Chain Heal, Riptide | yes (already) | heal the party frame under the cursor |
| Cure Poison, Cure Disease (Shift+Mouse4/5) | yes (already) | cure the party member under the cursor without changing target; the thumb is already on the side buttons for the heals |
| Nature's Swiftness + Healing Wave (Mouse5) | yes (new) | `#showtooltip Healing Wave` / `/cast Nature's Swiftness` / `/cast [@mouseover,help,nodead][help,nodead][@player] Healing Wave` |
| Earth Shock (Q) | yes (new), harmful form | `/stopcasting` / `/cast [@mouseover,harm,nodead][] Earth Shock`. Interrupts the enemy under the cursor, or else your target, even mid-heal. |
| Purge (Shift+3) | yes (new), harmful form | `/cast [@mouseover,harm,nodead][] Purge` |
| Ancestral Spirit | optional, dead form | `/cast [@mouseover,help,dead][] Ancestral Spirit`, on a clickable bar |
| Totems, shields, damage spells | no | totems and shields have no target; damage uses the normal target |

**Verify in game:**
- Does `/stopcasting` still work in a 12.x macro? `STOPCASTING` exists as a binding name.
- Does the NS + Healing Wave macro cast both spells in one press?
  - Nature's Swiftness is off the GCD in `simc` (no cooldown category for the GCD), but the 12.x client may
    differ.
  - If NS is on cooldown, the macro casts a normal (slow) Healing Wave. The card should say so.

## Q6: Level progression and the shield key

- **The level-60 layout comes first.** Lower levels use a subset of it, and a key never moves after its spell is
  learned. The only planned exception is the **shield key X**:
  - Lightning Shield (8) is the only shield until **Water Shield** (talent, level 20).
  - They don't stack: only one elemental shield can be active (`moba`). Both last 10 minutes.
  - At 20 the new-skill card for Water Shield puts it on X, and Lightning Shield moves to a clickable bar.
    `moba` warns not to swap Water Shield for Lightning Shield out of habit, and the move supports that.
  - A one-key macro (`/cast Water Shield` then `/cast Lightning Shield`) was rejected:
    - Before 20 it prints an error for the unknown spell.
    - After 20 the second line fails on the GCD.
    - A `[known:]` condition is not verified in the Forever macro system.
- **Families** (see "Families" below) keep their base key at every level. A family member that comes later fills
  its own variant, and nothing else moves.
- **Empty top keys while levelling** (see "Top keys" below): R and Mouse4 wait for Chain Heal and Riptide (40),
  Mouse5 waits for Nature's Swiftness (30), and 1 waits for Totemic Call (22). Erika (26) already has Totemic
  Call.
- **Snapshots** are in section (d).

## Q7: Items

| Item | Key | Why |
|---|---|---|
| Mana Potion (`FS_MANA`, best in the bags) | **Z** | her most used consumable; stays where it is |
| Healthstone, else the best Healing Potion (one macro, e.g. `FS_HEALTH`) | **C** | Healthstones come from warlocks, 2 min cooldown (`wh_tt`): Minor 5512 (also 19004), Lesser 5511, Healthstone 5509, Greater 5510, Major 9421. The red potion alone is rare for Erika, but with a warlock's Healthstone this is her personal emergency button. It is rarely pressed, so it does not get a top key: C sits next to the Mana Potion on Z (the bottom row holds what keeps her going), and it has no modifier, which is harder to miss in a panic. C is a stretch, so she presses it standing still or with a short stop. **Verify in game** whether Healthstones and potions share a cooldown. |
| Healing Potion (`FS_HEALPOT`) | none, clickable | as now; C covers it when there is no Healthstone |
| Minor Arcane Elixir (`FS_ELIXIR`) | none, clickable | next to the weapon imbues and long buffs, as decided for 0.3.0 |
| Bandages (Linen 1251, Silk 6450, Heavy Mageweave 8545, Runecloth 14529, Heavy Runecloth 14530) | none | They need First Aid and are an 8 s channel that damage breaks. A healer heals herself with spells. Optional clickable slot for solo. |

## Pull walkthroughs

This is the basis for every key choice below. The level-60 layout was designed first; lower levels use a subset
of it.

How to read it:
- **Dungeons and level ranges:** from `wh_dng` (checked 2026-11-11).
- **What a spell does and how a resto shaman uses it:** from `wh_abil`, `moba` and `wh_tt`.
- **Press counts** are **judgment**: estimates for a typical group, not measured. A trash pull is assumed to last
  about 30-45 s; a boss about 2-3 minutes.

### Level 60, trash pull (Scholomance 55-60 or Stratholme 48-58, `wh_dng`)

A pack of 3-5 mobs, one or two of them casters.

| Phase | Spell (key): presses | Why |
|---|---|---|
| Between pulls | Water Shield (X): 1 every 1-2 pulls | globes are used when she is hit and when her spells crit; refresh in safe gaps (`wh_tt`, `moba`) |
| | Call of the Elements (Shift+1): 1 every 3-5 pulls | the 5-minute totems run out (`simc` durations); also after a wipe |
| | Mana Potion (Z): 0 | drinking between pulls is free |
| Pull start | Totemic Call (1): 1 | brings the 5-minute totems that are still up to where she stands (`wh_tt`), so she presses it once she has stopped at her healing spot |
| | Searing Totem (Shift+R): 1 | lasts 30-55 s, so it is gone by the next pull (`simc`) |
| | Riptide (Mouse4): 1 | on the tank as the pack arrives (`wh_abil`) |
| During | Chain Heal (R): 4-8 | the main group heal; several players take damage on trash (`wh_abil`, `moba`) |
| | Healing Wave (F): 2-4 | steady damage on the tank (`wh_abil`) |
| | Riptide (Mouse4): 1-2 more | 12 s cooldown; also boosts the next Chain Heal on that target by 25% (`wh_tt`) |
| | Lesser Healing Wave (E): 1-3 | a spike on someone (`wh_abil`) |
| | Earth Shock (Q): 1-2 | interrupt a caster's heal or big spell (`wh_tt`: interrupt + 2 s lockout) |
| | Flame Shock (2), Lightning Bolt (3): 0-3 together | when healing need is light (`moba`) |
| | Tremor (Shift+F), Purge (Shift+3), cures (Shift+Mouse4/5): 0-1 each | only in packs that fear, buff or poison |
| Emergency | Nature's Swiftness + Healing Wave (Mouse5): about 1 pull in 5 | 3 min cooldown (`wh_tt`) |
| | Healthstone / Healing Potion (C): rare | when she is the one about to die |
| | Mana Tide (Ctrl+Z), Mana Potion (Z): 0-1 | in long chains of pulls without a break |
| After | nothing, or Ancestral Spirit (clickable) after a death | Totemic Recall (Ctrl+1) only when leaving the dungeon |

### Level 60, boss (a Scholomance or Stratholme boss, judgment)

| Phase | Spell (key): presses | Why |
|---|---|---|
| Before | Call of the Elements (Shift+1) or a boss preset (Call of the Spirits, clickable): 1 | fresh totems for the whole fight |
| | Water Shield (X): 1 | start with all 3 globes |
| Pull | Riptide (Mouse4), Searing (Shift+R): 1 each | as on trash |
| During | Riptide (Mouse4): 10-15 | on cooldown on the tank: 12 s over 2-3 min |
| | Healing Wave (F): 10-15; Chain Heal (R): 5-15 | single target on the tank; Chain Heal when the boss hits the group |
| | Lesser Healing Wave (E): 2-5 | spikes |
| | Searing (Shift+R): 2-4 more | it runs out after 30-55 s |
| | Earth Shock (Q): 0-3 | only if the boss casts something interruptible |
| | Tremor (Shift+F): 0-1 | only if the boss fears, charms or sleeps |
| | Water Shield (X): 0-1 | if the globes are gone mid-fight |
| Emergency | Mana Tide (Ctrl+Z): 1; Mana Potion (Z): 1; NS + Healing Wave (Mouse5): 0-1 | a long fight costs more mana than trash |
| After | Ancestral Spirit (clickable) if someone died | out of combat |

### Level 40, trash pull (Razorfen Downs 37-47, `wh_dng`)

- **New since 26:** Chain Heal (R) and Riptide (Mouse4), from 40. Nature's Swiftness (Mouse5) from 30. Chain
  Lightning (4) from 32.
- **The pull already looks like the level-60 one:** Chain Heal 3-6, Healing Wave 2-4, Riptide 2, Lesser Healing
  Wave 1-2 and Earth Shock 1-2.
- **Totems:** Totemic Call and Searing every pull.
- **So the level-60 keys are all in use from 40.**

### Level 26, trash pull (Shadowfang Keep 22-30 or Blackfathom Deeps 22-32, `wh_dng`), Erika now

- **Pull start:** Totemic Call (1) 1 and Searing (Shift+R) 1.
  - Before 22, or when the set has run out: Call of the Elements (Shift+1), or Stoneskin (Shift+E) by hand.
- **During:**
  - Healing Wave (F) 3-5: the main heal; there is no Chain Heal yet.
  - Lesser Healing Wave (E) 1-2.
  - Earth Shock (Q) 0-2.
  - Flame Shock (2) and Lightning Bolt (3) 1-3 together.
- **Emergency:** Mana Tide (Ctrl+Z), Mana Potion (Z), Healthstone / Healing Potion (C).
- **Water Shield (X):** every 1-2 pulls.
- **The keys she uses now are F, E, Q, 1, 2, 3, Shift+R and X.** They are the same keys she will use at 60,
  so nothing has to be relearned when Chain Heal and Riptide arrive.

## Frequency × urgency (level 60, from the walkthroughs)

How the columns work:
- **Urgency:** *very high* means it must land within about a second; *high* means within a GCD or two; *low* means
  set-up or filler.
- **Most pulls:** pressed **in combat** in most level-60 trash pulls. This decides whether a spell may take a top
  key. Spells pressed only between pulls (Water Shield, Call of the Elements) don't count.
- **Top keys** are tiers 1 and 2 without the Shift+Mouse buttons: Mouse4/5, Q, E, R, F, 1, 2, 3 and
  Shift+Q/E/R/F (13 keys).
- Frequency and urgency decide which spell gets a top key, which family gets which base key, and which family
  member gets the easiest variant (plain, then Shift, then Ctrl). See "Families" below.

| Spell | Trash presses | Boss presses | Most pulls? | Urgency | Key (tier) |
|---|---|---|---|---|---|
| Chain Heal | 4-8 | 5-15 | yes | high | R (1) |
| Healing Wave | 2-4 | 10-15 | yes | high | F (1) |
| Riptide | 2-3 | 10-15 | yes | high, instant, while moving | Mouse4 (1) |
| Lesser Healing Wave | 1-3 | 2-5 | yes | very high | E (1) |
| Earth Shock (interrupt) | 1-2 | 0-3 | yes (caster packs) | very high | Q (1) |
| Searing Totem | 1 | 3-5 | yes | low-medium | Shift+R (2) |
| Totemic Call | 1 | 0 | yes, as the pack arrives | low; pressed standing at the healing spot | 1 (2) |
| Lightning Bolt | 0-3 | 0-3 | yes (most pulls have a quiet moment) | low | 3 (2) |
| Flame Shock | 0-2 | 0-2 | yes; instant, also while moving | low | 2 (2) |
| NS + Healing Wave | about 1 pull in 5 | 0-1 | **no** (3 min cooldown) | very high | Mouse5 (1), exception |
| Tremor Totem | 0-1 | 0-1 | **no** (only fear, charm or sleep packs) | high when needed | Shift+F (2), exception |
| Frost Shock | rare | 0 | **no** | high when needed: a runner brings the next pack | Shift+Q (2), exception |
| Stoneskin Totem | 0-1 | 0 | **no** (in the set; by hand after Tremor) | low | Shift+E (2), exception |
| Cure Poison, Cure Disease | 0-4 in some dungeons | 0-3 | no (dungeon-specific; the cleansing totem covers most of it, `wh_abil`) | medium | Shift+Mouse4, Shift+Mouse5 (2) |
| Water Shield | 1 per 1-2 pulls, **between pulls** | 0-1 | no (not in combat) | low | X (4) |
| Healthstone / Healing Potion | rare | 0-1 | no | very high, but rare | C (4) |
| Call of the Elements | 1 per 3-5 pulls, between pulls | 1 | no | low (3 s cast out of combat) | Shift+1 (3) |
| Mana Potion | 0-1 | 1 | no | medium | Z (3) |
| Mana Tide Totem | 0-1 | 1 | no | medium | Ctrl+Z (4) |
| Mana Spring Totem (by hand) | after each Mana Tide | 1 | no (in the set) | low | Shift+Z (4) |
| Purge | 0-1 | 0-1 | no | medium | Shift+3 (3) |
| Chain Lightning | 0-1 | 0 | no (2.5 s, expensive for a healer) | low | 4 (3) |
| Earthbind Totem | rare | 0 | no | medium | Ctrl+Q (3) |
| Stoneclaw Totem | rare | 0 | no | medium | Ctrl+E (3) |
| Poison, Disease Cleansing Totem (by hand) | rare (usually in the set) | 0-1 | no | low | Ctrl+Mouse4, Ctrl+Mouse5 (3) |
| Grounding Totem | rare | 0-1 | no | high when needed | Ctrl+F (4) |
| Totemic Recall | once per dungeon | 0 | no | low | Ctrl+1 (5) |
| Ghost Wolf | 0 (outdoors only) | 0 | no | low | Ctrl+C (4), the player's decision |
| Healing Stream Totem (by hand) | rare | 0 | no (in the set) | low | none |

## What goes on 1 and 2

The player's decision: plain 1 and plain 2 must hold spells she presses **in combat in most pulls**. Water Shield
(refreshed between pulls) and Healthstone (rare) leave them; 3 Lightning Bolt and 4 Chain Lightning stay; 5 stays
free in all variants for Erika.

Only nine spells are pressed in combat in most level-60 pulls (table above). Seven already sit on top keys that
should not change (R, F, Mouse4, E, Q, Shift+R, 3). The other two were **Totemic Call (X)** and **Flame Shock
(Shift+Q)**. So 1 and 2 can only be filled by moving something; these two cost the least.

| Option | 1 | 2 | Gain | Cost |
|---|---|---|---|---|
| **A (chosen)** | Totemic Call (family from X) | Flame Shock (from Shift+Q) | All nine most-pull spells on top keys. The moving-totems family stays together and every member gets an equal or easier key (X → 1: tier 4 → 2; Shift+X → Shift+1: 4 → 3; Ctrl+X → Ctrl+1: 5 → 5). 2-3-4 becomes a damage row. | Shift+Q must be refilled (Frost Shock); the shocks are no longer one family (see "Families"). |
| **B (runner-up, close)** | Totemic Call (family from X) | Searing Totem (from Shift+R) | Searing is pressed more than Flame Shock (1 per pull, 3-5 per boss). The pull opener becomes 1 then 2. | Breaks Erika's own Shift+R habit. Shift+R then needs a new spell, and Flame Shock stays on Shift+Q away from Lightning Bolt. |
| C | Earth Shock | Flame Shock | shocks on the number row | the interrupt loses its tier-1 key, and Q gets something rarer |
| D | a heal (e.g. Lesser Healing Wave) | a heal | – | moves a heal from a tier-1 key to a tier-2 key and leaves the tier-1 key for something rarer |
| E | Riptide or NS + Healing Wave from the mouse | – | – | the thumb buttons keep the cursor on the party frames; nothing is better there |

**Why A over B:** both fill 1 and 2 with spells from most pulls. A keeps all of Erika's Shift totem keys and
builds a clear damage row: when healing is quiet she presses 2 (Flame Shock, instant DoT), then 3 (Lightning
Bolt), and 4 (Chain Lightning) for a big pack. B's gain (a few more Searing presses on a plain key) is smaller
than the cost of changing a habit she asked for. If Erika prefers B: Searing moves to 2, Flame Shock goes back to
Shift+Q, Shift+R takes Frost Shock (the runner exception), and Earthbind stays on Ctrl+Q. Nothing else changes.

**Where the displaced spells go:**
- **Water Shield → X** (Lightning Shield on X at 8-19). It is refreshed every 1-2 pulls between pulls, standing
  still, so a stretch key costs nothing. It stays keyed rather than clickable because she presses it often. With
  Z (Mana Potion) and C (Healthstone) the bottom row holds what keeps her going.
- **Healthstone / Healing Potion → C** (the player's suggestion). Next to the Mana Potion on Z, with no modifier.
  It is rarely pressed, so it doesn't earn a top key. Alternative: Shift+2 (spare, tier 2) is faster to reach in
  a panic, but has no link to the other consumables.
- **Cures → Shift+Mouse4/5, cleansing totems → Ctrl+Mouse4/5.** With 1 and 2 holding unrelated spells, the
  poison and disease families no longer fit on 1 and 2. On the mouse buttons they do: Mouse4 is the poison column
  and Mouse5 the disease column. Plain heals the party member under the cursor, Shift cures that same player
  (mouseover), and Ctrl drops the totem that cures the whole group. Both cures gain reach (tier 3 → 2), and the
  totems too (tier 5 → 3).
  - Risk: if Shift is still held after a Shift totem, Mouse4 casts Cure Poison instead of Riptide. That wastes a
    press but does no harm.
  - Runner-up: a "dispel" family on X (X Cure Poison, Shift+X Cure Disease, Ctrl+X Purge) with Water Shield on
    Shift+C. It fits by concept, but the cures fall to tier 4-5.
- **Frost Shock → Shift+Q**, and **Earthbind → Ctrl+Q** (it had to leave Shift+5).

## Families

A **family** is a group of spells that handle the same concept. A family sits on **one base key**, with plain,
Shift and Ctrl variants. Then a key press is "what kind of thing" (the base key) plus "which one" (the modifier),
which is easier to find in a hurry than three unrelated keys.

Rules used:
- Frequency and urgency decide which family gets which base key, and which member gets the easiest variant
  (plain, then Shift, then Ctrl).
- **A rare family never takes the plain variant of a top key.**
- **The plain variant must fit the family** (the player's rule for 1 and 2). Where it doesn't, the family moves.

### Grouped

| Family | Base key | Plain | Shift | Ctrl | Reason |
|---|---|---|---|---|---|
| **Moving totems** | 1 | Totemic Call *(22)*: every pull | Call of the Elements *(20)*: every 3-5 pulls and after a wipe | Totemic Recall *(20)*: once, when leaving | All three put down, move or remove the whole set. Order by frequency. Moved from X to 1 so that plain 1 holds a most-pull spell; every member gets an equal or easier key. |
| **Stop an enemy** | Q | Earth Shock *(4)*: stop its cast | Frost Shock *(20)*: stop one runner | Earthbind Totem *(6)*: slow several | Order by urgency. The interrupt keeps the tier-1 key. A runner brings the next pack, so Frost Shock is the more urgent slow. |
| **Damage while healing is quiet** | 2, 3, 4 (plain neighbours) | 2 Flame Shock *(10)*, 3 Lightning Bolt *(1)*, 4 Chain Lightning *(32)* | – | – | Pressed left to right: the instant DoT first, then Lightning Bolt, and Chain Lightning for a big pack (`moba`). Like the heals, this family is a row of plain keys, not one base key. |
| **Mana** | Z | Mana Potion | Mana Spring Totem *(26)* | Mana Tide Totem *(25)* | Everything that gives mana back. Mana Tide is a Water totem, so it replaces Mana Spring, and Mana Spring is pressed again when Mana Tide ends (13 s). Unchanged. |
| **Help the player under the cursor: poison** | Mouse4 | Riptide *(40)*, MO | Cure Poison *(16)*, MO | Poison Cleansing Totem *(22)* | The thumb button acts on the party frame under the cursor: heal, cure that player, or cure the whole group. |
| **Help the player under the cursor: disease** | Mouse5 | NS + Healing Wave *(30)*, MO | Cure Disease *(22)*, MO | Disease Cleansing Totem *(38)* | As above. |
| **Totems against physical damage** | E | (Lesser Healing Wave) | Stoneskin Totem *(4)* | Stoneclaw Totem *(8)* | Unchanged. Stoneskin is Erika's habit. |
| **Totems against enemy spells** | F | (Healing Wave) | Tremor Totem *(18)* | Grounding Totem *(30)* | Unchanged. Tremor is Erika's habit. |
| **Fire totems** (0.6.1) | R, plus Shift+4 | (Chain Heal) | Searing Totem *(10)*: every pull; Shift+4 Magma Totem *(26)*: packs | Fire Nova *(12)*: after Searing or Magma, against a pack | Erika's request: they belong together. Fire Nova only hits enemies near the active Fire totem. R has one free variant (Ctrl), so Magma takes the key right above R on the same Shift row. |

On E and F the plain key is a heal, not part of the totem family. That is kept on purpose: E and F are the best
keys for heals, and the Shift variants are where Erika asked for her totems. On the mouse buttons the plain heal
does fit ("help this player").

### Not grouped

| Spells | Keys | Why |
|---|---|---|
| **Heals** | F, E, R, Mouse4, Mouse5 (all plain) | The five most-pressed and most urgent spells. On one base key, two of them would need Shift or Ctrl. Their shared rule instead: **every heal is a key without a modifier.** |
| **Shocks by name** | Earth Q, Frost Shift+Q, Flame 2 | Grouped by what they do instead: Flame Shock is damage and joins the damage row; Earth and Frost Shock stop an enemy. |
| **Purge** | Shift+3 | Unchanged since v2. It could join "stop an enemy", but Q has only three variants, and a runner (Frost Shock) is more urgent than an enemy buff. |
| **Shields** | X | Already one key: Lightning Shield until 20, then Water Shield. |
| **Healthstone** | C | Next to the Mana Potion on Z, but a different concept (health), so not in the mana family. |
| **Totem presets** | Call of the Ancestors, Call of the Spirits | 1 has only three variants. The two extra presets are clicked next to Call of the Elements. |

### Top keys

- **9 spells are pressed in combat in most level-60 pulls. All nine are on top keys.**
- **The 4 other top keys hold the most urgent of the rest** (exceptions):
  - **Mouse5, NS + Healing Wave:** about 1 pull in 5, but it is the "someone dies in the next second" button.
  - **Shift+F, Tremor:** only in some dungeons, but a feared tank is an emergency. Erika's habit.
  - **Shift+Q, Frost Shock:** rare, but a runner must be stopped before it reaches the next pack.
  - **Shift+E, Stoneskin:** the weakest top key. In the set from 20; by hand after Tremor (both are Earth
    totems), and at every pull before 20. Erika's habit.
- **Empty top keys while levelling (Erika is 26):**
  - **R and Mouse4 stay empty for 14 levels,** until Chain Heal and Riptide at 40. From 40 they are the
    most-pressed heals; anything put there now would have to move at 40, exactly when healing gets harder.
  - **Mouse5 stays empty for 4 levels,** until Nature's Swiftness at 30.
  - **1 is empty until 22** (Totemic Call). Erika already has it.

## (a) Proposed layout

Abbreviations: **MO** = mouseover macro; *(lvl)* = the level the spell becomes available; "–" = spare.

### Grid

Bindings (as implemented in 0.4.3): plain = main bar (`ACTIONBUTTON`); Shift = Action Bar 2 (`MULTIACTIONBAR1BUTTON`);
Ctrl = Action Bar 5 (`MULTIACTIONBAR4BUTTON`, same button order as Shift); Mouse4/5 with and without modifiers =
Action Bar 3 buttons 7-12 (`MULTIACTIONBAR2BUTTON7-12`). The proposal first used Action Bars 6 and 7; they are retired.

| Base key | Plain | Shift | Ctrl |
|---|---|---|---|
| 1 | Totemic Call *(22)* | Call of the Elements *(20)* | Totemic Recall *(20)* |
| 2 | Flame Shock *(10)* | – | – (stance bar default) |
| 3 | Lightning Bolt *(1)* | Purge, MO harm *(12)* | – (stance bar default) |
| 4 | Chain Lightning *(32)* | Magma Totem *(26)* | – (stance bar default) |
| 5 | Erika's own | Erika's own | Erika's own |
| Q | Earth Shock, `/stopcasting` + MO harm *(4)* | Frost Shock *(20)* | Earthbind Totem *(6)* |
| E | Lesser Healing Wave, MO *(20)* | Stoneskin Totem *(4)* | Stoneclaw Totem *(8)* |
| R | Chain Heal, MO *(40)* | Searing Totem *(10)* | Fire Nova *(12)* |
| F | Healing Wave, MO *(1)* | Tremor Totem *(18)* | Grounding Totem *(30)* |
| Z | Mana Potion (`FS_MANA`) | Mana Spring Totem *(26)* | Mana Tide Totem *(25)* |
| X | Water Shield *(20)* (Lightning Shield *(8)* until then) | – | – |
| C | Healthstone, else Healing Potion (`FS_HEALTH`) | – | Ghost Wolf *(20)* |
| Mouse4 | Riptide, MO *(40)* | Cure Poison, MO *(16)* | Poison Cleansing Totem *(22)* |
| Mouse5 | Nature's Swiftness + Healing Wave, MO *(30)* | Cure Disease, MO *(22)* | Disease Cleansing Totem *(38)* |

### Change in layout 6 (ForeverSensei 0.6.1, Erika's request)

Erika: her Fire totem, the Fire totem AoE spell and Magma Totem were not close together in keys or on the bars.
Searing Totem was on Shift+R, while Fire Nova (bar 4 button 5) and Magma Totem (bar 4 button 8) could only be
clicked. Fire Nova "instantly inflicts fire damage to enemies within … yd of your active Fire totem" (`simc`
408341: rank 1 at 12, 10 s cooldown), so it only works with Searing or Magma down: the three are one family.
Decided by the coordinator while the player was away:
- Shift+R Searing Totem stays (Erika's habit).
- **Ctrl+R Fire Nova** (Action Bar 5 button 8, an empty bound button until now): same base key as Searing.
- **Shift+4 Magma Totem** (Action Bar 2 button 4, an empty bound button until now): 4 sits right above R, on the
  Shift row that holds her totems. In the reach table Shift+4 is tier 4 for a small hand; Magma is placed for a
  pack before the damage starts, not as a reaction, so the stretch is acceptable.
- Action Bar 4 buttons 5 and 8 become spare; Flametongue Totem stays clicked on bar 4. Shift+4 and Ctrl+R leave
  the spare list.

A full apply from layout 5 clears Fire Nova and Magma Totem from their old bar 4 buttons (`L.old`), and the
one-time layout notice offers the preview; nothing moves by itself.

### Reason and source per key

| Key | Spell or item | v2 key | Reason | Source |
|---|---|---|---|---|
| F | Healing Wave | F | the tank heal in every pull; the main heal before 40 | `wh_abil` |
| R | Chain Heal | R | the most-pressed heal from 40 | `wh_abil`, `moba` |
| E | Lesser Healing Wave | C | the spike heal: most pulls, very urgent | `wh_abil`, `moba` |
| Mouse4 | Riptide | E | instant, 12 s cooldown: the thumb casts it on the cursor's frame while WASD keeps moving | `wh_tt`, `wh_abil` |
| Mouse5 | NS + Healing Wave | X (NS alone) | the one-press emergency heal (exception) | `wh_tt`, `moba` |
| Q | Earth Shock | 5 | the interrupt: most pulls, within a second | `wh_tt`, `moba`, `wm` |
| 1 | Totemic Call | (clickable) | most pulls, as the pack arrives; moving-totems family | `wh_tt`, `moba` |
| 2 | Flame Shock | 4 | damage row; filler in most pulls, instant | `simc`, `moba` |
| 3 | Lightning Bolt | 3 | damage row; filler in most pulls | `wh_abil`, `moba` |
| 4 | Chain Lightning | Q | damage row; rare for a healer | `simc` |
| Z | Mana Potion | Z | long chains of pulls and bosses | 0.3.0 |
| X | Water Shield | 1 | refreshed between pulls, standing still | `wh_tt`, `moba` |
| C | Healthstone / Healing Potion | (clickable) | the healer's own emergency; next to the Mana Potion | `wh_tt` items |
| Shift+1 | Call of the Elements | Shift+C | moving-totems family; every 3-5 pulls | `wh_tt`, `simc` durations |
| Ctrl+1 | Totemic Recall | (clickable) | moving-totems family; once per dungeon | `wh_tt`, `moba` |
| Shift+3 | Purge | Shift+3 | sometimes, on enemy buffs | `wh_abil`, `moba` |
| Shift+Q | Frost Shock | Shift+4 | stop-an-enemy family; runners (exception) | `wh_abil` |
| Ctrl+Q | Earthbind | Shift+5 | stop-an-enemy family; rare | `wh_abil` |
| Shift+E | Stoneskin | Shift+E | Erika's habit; by hand after Tremor (exception) | Erika, `wh_tt` |
| Ctrl+E | Stoneclaw | (clickable) | physical-protection family; rare | `wh_abil` |
| Shift+R | Searing | Shift+R | every pull, and 2-4 more times per boss (30-55 s) | Erika, `simc` |
| Ctrl+R | Fire Nova | (clickable) | Fire family: hits enemies near the active Fire totem (0.6.1, Erika's request) | Erika, `simc` 408341 |
| Shift+4 | Magma Totem | (clickable) | Fire family: packs, 20 s; right above R (0.6.1, Erika's request) | Erika, `simc` |
| Shift+F | Tremor | Shift+F | fear, charm and sleep (exception) | Erika, `wh_abil` |
| Ctrl+F | Grounding | (clickable) | enemy-spell family; rare | `wh_abil` |
| Shift+Z | Mana Spring | Shift+Z | mana family; pressed again after each Mana Tide | `moba`, `simc` |
| Ctrl+Z | Mana Tide | Shift+X | mana family; once per boss | `simc`, `moba` |
| Shift+Mouse4, Shift+Mouse5 | Cure Poison, Cure Disease | Shift+1, Shift+2 | cure the player under the cursor; dungeon-specific | `wh_abil` |
| Ctrl+Mouse4, Ctrl+Mouse5 | Poison, Disease Cleansing Totem | (clickable) | the group version of the cure; usually in the set | `wh_abil` |
| Ctrl+C | Ghost Wolf | (clickable) | the player's decision; outdoors only | user, `simc` 2645 |

**Spare:** Shift+2, Shift+X, Shift+C, Ctrl+2, Ctrl+3, Ctrl+4, Ctrl+X (Shift+4 and Ctrl+R hold the Fire family
from 0.6.1). From 0.4.3 they are bound to
their empty button, so the plain, Shift and Ctrl rows have all 12 keys (user decision, "Full Ctrl row that mirrors the
Shift bar"). **5, Shift+5 and Ctrl+5 are Erika's own**: the addon never binds them.

## Diff against layout v2 (ForeverSensei 0.3.0)

**Nine keys keep their spell:** 3, R, F, Z, Shift+3, Shift+E, Shift+R, Shift+F, Shift+Z.

**Moves:**

| Spell | v2 → new | Does Erika (26) feel it? | Reason |
|---|---|---|---|
| Water Shield | 1 → X | yes | 1 must hold a spell pressed in combat in most pulls (the player's decision) |
| Flame Shock | 4 → 2 | yes | damage row 2-3-4; a top key for filler in most pulls |
| Earth Shock | 5 → Q | yes | the interrupt must land within a second; 5 is now Erika's own |
| Lesser Healing Wave | C → E | yes | very urgent spike heal in most pulls; C is a stretch key |
| Call of the Elements | Shift+C → Shift+1 | yes | moving-totems family on 1 |
| Frost Shock | Shift+4 → Shift+Q | yes | stop-an-enemy family; better reach (tier 4 → 2) |
| Earthbind Totem | Shift+5 → Ctrl+Q | yes | 5 is now Erika's own; stop-an-enemy family |
| Cure Poison | Shift+1 → Shift+Mouse4 | yes | cure the player under the cursor; better reach (tier 3 → 2) |
| Cure Disease | Shift+2 → Shift+Mouse5 | yes | as above |
| Mana Tide Totem | Shift+X → Ctrl+Z | yes | mana family |
| Healing Stream Totem | Shift+Q → clickable | yes | in the Call of the Elements set from the day it is learned; rarely placed by hand |
| Lightning Shield | 2 → clickable after 20 (on X at 8-19) | no (unused since 20) | can't be active with Water Shield |
| Chain Lightning | Q → 4 | no (learned at 32) | damage row; rare for a healer |
| Riptide | E → Mouse4 | no (learned at 40) | instant, cast while moving, on the cursor's frame |
| Nature's Swiftness | X → Mouse5 (as NS + Healing Wave) | no (learned at 30) | one press instead of two in an emergency |

**New keys** (were clickable): Totemic Call 1, Totemic Recall Ctrl+1, Healthstone / Healing Potion C, Poison and
Disease Cleansing Totem Ctrl+Mouse4/5, Stoneclaw Ctrl+E, Grounding Ctrl+F, Ghost Wolf Ctrl+C.

For Erika (26), **eleven spells she already uses move.** That is more than in the previous proposal, because the
player's three decisions (1 and 2 for in-combat spells, 5 free, Water Shield and Healthstone off 1 and 2) touch
the keys of eight spells. The three heals and the interrupt that matter most (F, E, R, Q) and her Shift+E/R/F
totems stay put.

**Changed since the previous proposal (26ab460):**
- Moving-totems family X → 1 (Totemic Call 1, Call of the Elements Shift+1, Totemic Recall Ctrl+1).
- Flame Shock Shift+Q → 2; Frost Shock Ctrl+Q → Shift+Q; Earthbind Shift+5 → Ctrl+Q.
- Water Shield 1 → X; Healthstone 2 → C.
- Cure Poison and Cure Disease Shift+1/2 → Shift+Mouse4/5; cleansing totems Ctrl+1/2 → Ctrl+Mouse4/5.
- 5 in all variants is left for Erika.

## (b) Unkeyed, on clickable bars

| Spell or item | Reason |
|---|---|
| Rockbiter, Flametongue and Windfury Weapon | weapon buffs that last long; cast before the pull |
| Minor Arcane Elixir (`FS_ELIXIR`) | long buff, next to the weapon buffs (decided in 0.3.0) |
| Healing Potion (`FS_HEALPOT`) | C covers it when there is no Healthstone |
| Lightning Shield (after 20) | replaced by Water Shield on X |
| Healing Stream Totem | in the Call of the Elements set from the day it is learned; swap it in with a click between pulls |
| Strength of Earth Totem | a set-up choice instead of Stoneskin; put it in the Totem Bar set for melee groups |
| Windfury Totem, Grace of Air Totem | Air totems for melee groups; set up through the Totem Bar |
| Flametongue Totem | rare |
| Frost, Fire and Nature Resistance Totem, Windwall Totem | boss-specific; picked in a Totem Bar set |
| Sentry Totem, Far Sight | scouting; not used in dungeons. **Spellbook only** from 0.4.3 (no button) |
| Call of the Ancestors, Call of the Spirits | a second and third preset (e.g. a boss set), clicked next to Call of the Elements |
| Ancestral Spirit (optional MO dead macro) | 10 s cast, after a death; out of combat |
| Astral Recall | travel; out of combat |
| Water Walking, Water Breathing | travel; out of combat. **Spellbook only** from 0.4.3 (no button) |
| Frostbrand Weapon | solo imbue that slows runners; a healer uses Rockbiter or Flametongue. **Spellbook only** from 0.4.3 |
| Bandages (optional) | see Q7 |
| Reincarnation | passive; offered by the death dialog |

## (c) Default bindings that are replaced

Already replaced by layout v2 (no change):
- Q/E strafe, R reply, F assist (verify), Z sheath, X sit/stand, C character window.
- Shift+1-4 bar paging.

New in this proposal:
- Ctrl+Q, Ctrl+E, Ctrl+F, Ctrl+Z and Ctrl+C (no default expected).
- **Ctrl+1** (stance bar button 1). A shaman's only stance-bar spell is expected to be Ghost Wolf, which is on
  Ctrl+C anyway. **Verify in game.**
- Mouse4 and Mouse5, also with Shift and Ctrl (no default expected).

Not touched:
- **5, Shift+5 and Ctrl+5**: Erika's own. Layout v2 put Earthbind on Shift+5; the implementation must remove
  only that addon binding and leave anything Erika puts there.
- Ctrl+6-0 (the stance bar), Alt with any key.

Replaced from 0.4.3 (full Ctrl row, bound to empty Action Bar 5 buttons): Ctrl+2-4 (stance bar buttons 2-4), Ctrl+R
(probably the framerate display) and Ctrl+X. The preview warns about the stance and framerate keys. From 0.6.1
Ctrl+R holds Fire Nova instead of an empty button.

Verify all of these with the `/run` lines in Q4. Apply-layout already backs up and can undo bindings.

## (d) Snapshots by level

"–" means the key is reserved but still empty. Spare keys and Erika's 5 are left out.

| Key | 10 | 20 | 26 | 30 | 40 | 60 |
|---|---|---|---|---|---|---|
| 1 | – | – | Totemic Call | Totemic Call | Totemic Call | Totemic Call |
| 2 | Flame Shock | Flame Shock | Flame Shock | Flame Shock | Flame Shock | Flame Shock |
| 3 | Lightning Bolt | Lightning Bolt | Lightning Bolt | Lightning Bolt | Lightning Bolt | Lightning Bolt |
| 4 | – | – | – | – | Chain Lightning | Chain Lightning |
| Q | Earth Shock | Earth Shock | Earth Shock | Earth Shock | Earth Shock | Earth Shock |
| E | – | Lesser Healing Wave | Lesser Healing Wave | Lesser Healing Wave | Lesser Healing Wave | Lesser Healing Wave |
| R | – | – | – | – | Chain Heal | Chain Heal |
| F | Healing Wave | Healing Wave | Healing Wave | Healing Wave | Healing Wave | Healing Wave |
| Z | Mana Potion | Mana Potion | Mana Potion | Mana Potion | Mana Potion | Mana Potion |
| X | Lightning Shield | Water Shield | Water Shield | Water Shield | Water Shield | Water Shield |
| C | Healthstone / Healing Potion | Healthstone / Healing Potion | Healthstone / Healing Potion | Healthstone / Healing Potion | Healthstone / Healing Potion | Healthstone / Healing Potion |
| Mouse4 | – | – | – | – | Riptide | Riptide |
| Mouse5 | – | – | – | NS + Healing Wave | NS + Healing Wave | NS + Healing Wave |
| Shift+1 | – | Call of the Elements | Call of the Elements | Call of the Elements | Call of the Elements | Call of the Elements |
| Shift+3 | – | Purge | Purge | Purge | Purge | Purge |
| Shift+Q | – | Frost Shock | Frost Shock | Frost Shock | Frost Shock | Frost Shock |
| Shift+E | Stoneskin | Stoneskin | Stoneskin | Stoneskin | Stoneskin | Stoneskin |
| Shift+R | Searing | Searing | Searing | Searing | Searing | Searing |
| Shift+F | – | Tremor | Tremor | Tremor | Tremor | Tremor |
| Shift+4 | – | – | Magma | Magma | Magma | Magma |
| Shift+Z | – | – | Mana Spring | Mana Spring | Mana Spring | Mana Spring |
| Shift+Mouse4 | – | Cure Poison | Cure Poison | Cure Poison | Cure Poison | Cure Poison |
| Shift+Mouse5 | – | – | Cure Disease | Cure Disease | Cure Disease | Cure Disease |
| Ctrl+1 | – | Totemic Recall | Totemic Recall | Totemic Recall | Totemic Recall | Totemic Recall |
| Ctrl+Q | Earthbind | Earthbind | Earthbind | Earthbind | Earthbind | Earthbind |
| Ctrl+E | Stoneclaw | Stoneclaw | Stoneclaw | Stoneclaw | Stoneclaw | Stoneclaw |
| Ctrl+R | – | Fire Nova | Fire Nova | Fire Nova | Fire Nova | Fire Nova |
| Ctrl+F | – | – | – | Grounding | Grounding | Grounding |
| Ctrl+Z | – | – | Mana Tide | Mana Tide | Mana Tide | Mana Tide |
| Ctrl+C | – | Ghost Wolf | Ghost Wolf | Ghost Wolf | Ghost Wolf | Ghost Wolf |
| Ctrl+Mouse4 | – | – | Poison Cleansing | Poison Cleansing | Poison Cleansing | Poison Cleansing |
| Ctrl+Mouse5 | – | – | – | – | Disease Cleansing | Disease Cleansing |
| Keys in use | 11 | 20 | 26 | 28 | 32 | 32 |

Notes:
- Minor Healing Potion has no required level, and Minor Mana Potion needs level 5 (`Data/Items.lua`).
- Before a potion is in the bags, the macro shows its fallback icon.
- At 10 the unkeyed buttons are Rockbiter, Flametongue Weapon and Strength of Earth. Grace of Air (42) is the
  last unkeyed spell.
- Each family fills in as she levels and never moves: 1 gets Call of the Elements and Totemic Recall at 20 and
  Totemic Call at 22; Z gets Mana Tide at 25 and Mana Spring at 26; the mouse buttons get their cures at 16 and 22
  before their heals at 30 and 40.

## Where this overrides Erika's wishes

**Kept:**
- Healing Wave on F.
- Her pull totems on Shift+E (Stoneskin), Shift+R (Searing) and Shift+F (Tremor).
- Mana Potion on Z.
- Totemic Call, Totemic Recall and Call of the Elements all keyed, together on 1.
- Her Fire totems together (0.6.1, her request): Searing Shift+R, Fire Nova Ctrl+R, Magma Shift+4.
- Rare and out-of-combat spells unkeyed.

**Overridden, with the gameplay reason:**
1. **Heals on F/C/R/E/X → F, E, R and the mouse buttons.**
   - C and X are stretch keys (tier 4) for a small hand.
   - Lesser Healing Wave (very urgent) and Nature's Swiftness (the emergency) need the fastest keys, not the
     slowest.
2. **Shields on 1 and 2 → only Water Shield, on X.**
   - Lightning Shield can't be active together with Water Shield (`moba`), so after 20 its key was wasted.
   - Water Shield is refreshed between pulls, so 1 goes to a spell she presses in combat (the player's decision).
3. **Not every totem is on Shift:**
   - Totemic Call and Totemic Recall go to 1 and Ctrl+1, around Call of the Elements on Shift+1 (moving-totems
     family).
   - Mana Tide goes to Ctrl+Z (mana family), Stoneclaw to Ctrl+E, Grounding to Ctrl+F, Earthbind to Ctrl+Q, and
     the cleansing totems to Ctrl+Mouse4/5, each next to the spells that do the same job.
   - Healing Stream becomes clickable: it is in the Call of the Elements set and rarely placed by hand.

## Verify in game (for the implementation task)

1. The default actions of the replaced keys: the `/run` lines in Q4.
2. Action Bars 6 and 7 must be shown for their key bindings to fire, or check that hidden bars work.
3. Shift+Mouse4/5 and Ctrl+Mouse4/5 fire their buttons (`SHIFT-BUTTON4` etc.), and holding Shift for a Shift
   totem doesn't cause too many Cure Poison casts instead of Riptide.
4. `SetMultiCastSpell(<action>, <spellId>)` from an addon, out of combat.
5. `SetBindingClick` on `MultiCastActionButtonN` (only if needed).
6. The NS + Healing Wave macro casts both spells in one press. Does `/stopcasting` work in a macro?
7. Healthstone and potion: shared cooldown or not.
8. Does Ghost Wolf appear on the stance bar? If it does, Ctrl+1 loses nothing it needs (Ghost Wolf is on Ctrl+C);
   check that no other shaman spell sits on the stance bar.
9. The mana cost of Call of the Elements: does the tooltip's "None" really mean only the totems' own cost?

## (e) Erika へのまとめ（日本語）

レベル60でダンジョンを回復する時を基準に、キー配置を作り直した。実際の戦闘の流れ（戦闘の合間・戦闘開始・戦闘中・緊急時・戦闘の後）で、どの呪文を何回押すかを数えた。戦闘中によく押す呪文や急いで使う呪文ほど、押しやすいキーに置いた。同じ役目の呪文は1つのキーにまとめて、Shift と Ctrl で選ぶ。レベルが低い時は、この中で覚えた呪文だけを使う。一度覚えた呪文のキーは、レベルが上がっても変わらない。5 は Shift と Ctrl も含めて空けてあるので、好きな物を置いていい。

| キー | そのまま | Shift | Ctrl |
|---|---|---|---|
| 1 | Totemic Call | Call of the Elements | Totemic Recall |
| 2 | Flame Shock | – | – |
| 3 | Lightning Bolt | Purge | – |
| 4 | Chain Lightning（レベル32から） | Magma Totem（レベル26から） | – |
| 5 | 自由 | 自由 | 自由 |
| Q | Earth Shock | Frost Shock | Earthbind Totem |
| E | Lesser Healing Wave | Stoneskin Totem | Stoneclaw Totem |
| R | Chain Heal（レベル40から） | Searing Totem | Fire Nova |
| F | Healing Wave | Tremor Totem | Grounding Totem |
| Z | Mana Potion | Mana Spring Totem | Mana Tide Totem |
| X | Water Shield | – | – |
| C | Healthstone（なければHealing Potion） | – | Ghost Wolf |
| マウスのボタン4 | Riptide（レベル40から） | Cure Poison | Poison Cleansing Totem |
| マウスのボタン5 | Nature's Swiftness ＋ Healing Wave（レベル30から） | Cure Disease | Disease Cleansing Totem |

同じ役目でまとめたキー:
- **1＝トーテムを動かす。** 1 は Totemic Call（毎回の戦闘の始め）、Shift+1 は Call of the Elements（約5分ごと）、Ctrl+1 は Totemic Recall（ダンジョンを出る時）。
- **2・3・4＝回復が少ない時のダメージ。** 左から順に押す。まず Flame Shock（2）、次に Lightning Bolt（3）。敵が多い時は Chain Lightning（4）。
- **Q＝敵を止める。** Q は Earth Shock（敵の詠唱を中断する）、Shift+Q は Frost Shock（逃げる敵を1体遅くする）、Ctrl+Q は Earthbind Totem（近くの敵をまとめて遅くする）。
- **Z＝マナ。** Z は Mana Potion、Shift+Z は Mana Spring Totem、Ctrl+Z は Mana Tide Totem。Mana Tide Totem が消えたら（13秒）、Mana Spring Totem をもう一度置こう。
- **マウスのボタン＝カーソルの下の味方を助ける。** そのまま押すと回復、Shift で毒や病気を治す、Ctrl でパーティー全体を治すトーテムを置く。ボタン4は毒、ボタン5は病気。
- **E＝物理ダメージから守るトーテム、F＝敵の呪文に対抗するトーテム。** Shift+E Stoneskin と Shift+F Tremor は今まで通り。
- **R・4＝火のトーテム（0.6.1、Erika の希望）。** Shift+R は Searing Totem（今まで通り）、Ctrl+R は Fire Nova、Shift+4 は Magma Totem（R のすぐ上）。Fire Nova は今出している火のトーテムの近くの敵にだけ当たるので、敵が固まっている時は Searing か Magma を置いてから Ctrl+R を押そう。

主な理由:
- **1 と 2 には、戦闘中にほぼ毎回押す呪文を置いた。** Water Shield は戦闘の合間にかけ直すだけなので X に、Healthstone はたまにしか使わないので C に移した。
- **回復は全部、Shift なしのキー。** F・E・R・マウスのボタン4・5。一番よく押して、一番急ぐ呪文だから。レベル60の普通の戦闘では、Chain Heal（R）を4〜8回、Healing Wave（F）を2〜4回、Riptide（マウスのボタン4）を2〜3回使う。
- **Lesser Healing Wave を C から E に移した。** 急に大きなダメージを受けた味方を回復する呪文なので、WASD のすぐ隣の E がいい。C は小さな手には遠い。
- **Riptide はマウスのボタン4。** 詠唱がないので、歩きながら使える。親指で押すので、カーソルはパーティーの枠の上に置いたままでいい。
- **マウスのボタン5は緊急用のマクロ。** 1回押すだけで Nature's Swiftness と Healing Wave を続けて使う。クールダウンが3分なので毎回は使わないが、使う時は一番急ぐ。
- **Earth Shock を Q に移した。** ほぼ毎回の戦闘で使い、1秒も待てないので、一番押しやすいキーに置いた。回復の詠唱中でも、止めてすぐに使える。
- **Totemic Call（1）は、回復する場所に立ってから押す。** 今出しているトーテムを自分の場所に移す（クールダウンは30秒）。ただし、消えたトーテムは戻らない。
- **Call of the Elements（Shift+1）は約5分ごと。** 長く続くトーテムも5分で消える。数回の戦闘ごとと全滅の後に、戦闘の合間に使おう。
- **Searing Totem（Shift+R）は毎回置く。** 30〜55秒で消えるので、ボス戦では消えたらもう一度置こう。
- **Water Shield は X。** 玉は3つなので、1〜2回の戦闘ごとに、戦闘の合間にかけ直そう。Lightning Shield は Water Shield と同時に使えないので、レベル20からはキーから外す。
- **C は Healthstone（なければ Healing Potion）。** 自分が倒れそうな時の緊急用。Z の Mana Potion の隣なので、薬は下の段にまとまる。
- **Healing Stream Totem はキーなし。** Call of the Elements でまとめて置くので、手で置くことはあまりない。
- **Ctrl はあまり使わないもの用。** Ghost Wolf（Ctrl+C）は屋外でだけ使えるので、ダンジョンではほとんど使わない。
- **R とマウスのボタン4はレベル40まで空いている。** Chain Heal と Riptide を覚えたら、そこに置く。後でキーを変えなくていいように、先に場所を決めておく。
- **めったに使わない呪文はキーなし。** Ancestral Spirit・Astral Recall などは、クリック用のバーに置く。Far Sight・Sentry Totem・Water Breathing・Water Walking・Frostbrand Weapon はバーに置かず、呪文書から使う。
