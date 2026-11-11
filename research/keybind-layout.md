# Keybind layout research: Restoration Shaman, dungeon healer (proposal)

Status: **proposal for approval**. Nothing here is implemented yet. The current layout (version 2,
ForeverSensei 0.3.0) is in `ForeverSensei/Data/Shaman/Layout.lua`. Once the player and Erika approve the
tables in section (a), a separate task implements them.

Scope:
- Erika heals dungeons in a group most of the time; questing and solo come second.
- She moves with WASD, has small hands and two mouse side buttons.
- Allowed keys are now 1-5, Q, E, R, F, Z, X and C, with no modifier, Shift or Ctrl, plus Button4 and Button5
  (also with modifiers).

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
| Earthbind Totem | 6 | instant / 15 s / 6% base mana, 45 s, Earth | rare: runners, kiting | React | Shift+5 |
| Stoneclaw Totem | 8 | instant / 30 s / 15, 15 s, Earth | rare: enemies hitting the healer | React | Ctrl+E |
| Lightning Shield | 8 | instant / – / 45, 10 min | levels 8-19 only, replaced by Water Shield | Set-up | 1 until 20 |
| Flame Shock | 10 | instant / 6 s / 55, 12 s DoT | often when DPSing; instant, usable while moving | React/DPS | 2 |
| Searing Totem | 10 | instant / – / 25, **30 s** (55 s at the top rank), Fire | every pull (Erika's habit; it only lasts 30-55 s) | Pull | Shift+R |
| Flametongue Weapon | 10 | instant / – / 30 | before the dungeon | OOC | none |
| Strength of Earth Totem | 10 | instant / – / 25, 5 min, Earth | instead of Stoneskin for melee groups | Set-up | none (Totem Bar set) |
| Fire Nova | 12 | instant / 10 s / 65 | rare for a healer: AoE around the Fire totem | DPS | none |
| Purge | 12 | instant / – / 10% base mana | sometimes: enemy buffs | React | Shift+3 |
| Ancestral Spirit | 12 | 10 s / – / 90% base mana | after a death or wipe | OOC | none |
| Cure Poison | 16 | instant / – / 9% base mana | often in poison dungeons | React | Shift+1 |
| Tremor Totem | 18 | instant / – / 60, 5 min, Earth | fear, charm and sleep fights (Erika uses it a lot) | React | Shift+F |
| Call of the Elements | 20 | 3 s / – / none / GCD | between pulls whenever the 5-minute totems run out (about every 5 minutes, i.e. every few pulls), and after a wipe | Set-up | Shift+C |
| Frost Shock | 20 | instant / 6 s / 115, 8 s slow | rare: slow a runner or a chaser | React | Shift+4 |
| Totemic Recall | 20 | instant / – / returns 25% of the totems' mana | after the last pull, before a long run | OOC | Ctrl+X |
| Frostbrand Weapon | 20 | instant / – / 60 | solo only | OOC | none |
| Ghost Wolf | 20 | 3 s / – / 100, outdoors only | none: Erika's talent path has no Improved Ghost Wolf, so it cannot be used indoors | OOC (questing) | Ctrl+C |
| Healing Stream Totem | 20 | instant / – / 40, 5 min, Water | part of the pull set; swap with Mana Spring | Set-up | Ctrl+Z |
| Lesser Healing Wave | 20 | 1.5 s / – / 105 | the fast emergency heal | React (cast) | E |
| Water Shield | 20 (talent) | instant / – / none, 10 min, 3 globes | refresh between pulls or in gaps | Set-up | 1 |
| Totemic Call | 22 | instant / 30 s / 25% base mana | every pull: moves the totems to you | Pull | Shift+Q |
| Water Breathing | 22 | – | never in a dungeon | OOC | none |
| Cure Disease | 22 | instant / – / 9% base mana | often in disease dungeons | React | Shift+2 |
| Poison Cleansing Totem | 22 | instant / – / 10% base mana, Water | poison-heavy fights | React | none (Totem Bar set) |
| Frost Resistance Totem | 24 | instant / – / 75, Fire | rare, boss-specific | Set-up | none (Totem Bar) |
| Mana Tide Totem | 25 (talent) | instant / 5 min / 10, 13 s, Water | long fights, low mana | React | Shift+X |
| Magma Totem | 26 | instant / – / 230, 20 s, Fire | rare for a healer: big packs | DPS | none |
| Far Sight | 26 | 2 s / – / 80 | never | OOC | none |
| Mana Spring Totem | 26 | instant / – / 40, 5 min, Water | the default Water totem from 26 | Set-up | Shift+Z |
| Fire Resistance Totem | 28 | instant / – / 75, Water | rare, boss-specific | Set-up | none (Totem Bar) |
| Flametongue Totem | 28 | instant / – / 90, Fire | rare: caster-heavy groups | Set-up | none |
| Water Walking | 28 | – | never in a dungeon | OOC | none |
| Call of the Ancestors | 30 | 3 s / – / none | a second preset (e.g. the Tremor set) | Set-up | none (next to CotE) |
| Astral Recall | 30 | – | after the dungeon | OOC | none |
| Grounding Totem | 30 | instant / 15 s / 6% base mana, 45 s, Air | against dangerous single casts | React | Ctrl+Q |
| Nature Resistance Totem | 30 | instant / – / 75, Air | rare, boss-specific | Set-up | none (Totem Bar) |
| Windfury Weapon | 30 | instant / – / 90 | solo only | OOC | none |
| Nature's Swiftness | 30 (talent) | instant / 3 min | emergency: NS + Healing Wave | React | Mouse5 (macro) |
| Reincarnation | 30 | passive / 60 min | self-resurrect after a wipe | – | none (passive) |
| Chain Lightning | 32 | 2.5 s / 6 s / 245 | AoE damage when healing is light | Cast/DPS | 4 |
| Windfury Totem | 32 | instant / – / 115, Air | melee groups, through the Totem Bar set | Set-up | none |
| Sentry Totem | 34 | instant / – / 65, Air | never | OOC | none |
| Windwall Totem | 36 | instant / – / 115, Air | rare, ranged-heavy fights | Set-up | none (Totem Bar) |
| Disease Cleansing Totem | 38 | instant / – / 10% base mana, Water | disease-heavy fights | React | none (Totem Bar set) |
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
   after a wipe:** press **Call of the Elements** (Shift+C). The 3 s cast places the whole set again.
   - Watch the totem icons (Totem Bar or the totem timers by the player frame): when they are gone or almost
     gone, recast the set between pulls instead of Totemic Call.
   - Suggested set 1: Stoneskin + Searing + Healing Stream (Mana Spring from 26) + an Air totem
     (Windfury for a melee group from 32, otherwise Grace of Air from 42).
2. **Every pull in between:**
   - Press **Totemic Call** (Shift+Q) where the group fights. The 5-minute totems that are still up come with
     you at 25% base mana, which is cheaper and faster than recasting them (30 s cooldown).
   - Press **Searing Totem** (Shift+R). It only lasts 30-55 s, so it is gone by the next pull anyway.
3. **React:**
   - Tremor (Shift+F) against fear, charm and sleep. It replaces Stoneskin until you press Stoneskin (Shift+E)
     again.
   - Grounding (Ctrl+Q) against a dangerous caster.
   - Poison or Disease Cleansing: put it in the Water slot of the Totem Bar set for a poison- or disease-heavy
     dungeon (`wh_abil`: usually better than casting the cures). Cure Poison and Cure Disease (Shift+1, Shift+2)
     are for the player the totem misses.
   - Mana Tide (Shift+X) when your mana is low in a long fight.
   - Earthbind (Shift+5) for runners.
4. **Leaving:** press **Totemic Recall** (Ctrl+X) to get some mana back.

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
  - Separate keys for the totems she swaps by hand: Tremor, Grounding, Mana Tide. The cleansing totems go into
    the set for the dungeons that need them.
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
- **Ctrl (new):** `MULTIACTIONBAR5BUTTON1-12`, which is **Action Bar 6** (`MultiBar5`, page 13, slots
  145-156, shown with the setting `PROXY_SHOW_ACTIONBAR_6`).
  - Use the same column order as the main bar, so Ctrl+Q sits under Q.
- **Mouse buttons (new):** `MULTIACTIONBAR6BUTTON1-12`, which is Action Bar 7 (`MultiBar6`, page 14, slots
  157-168).
  - Button 1 is Mouse4 and button 2 is Mouse5. Buttons 3-6 are kept for Shift+ and Ctrl+Mouse4/5 (spare).
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
/run for _,k in ipairs({"CTRL-Q","CTRL-E","CTRL-Z","CTRL-X","CTRL-C","BUTTON4","BUTTON5"}) do print(k,GetBindingAction(k)) end
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
| **Ctrl+Q/E/Z/X/C** | none expected | **new** |
| Ctrl+R | TOGGLEFPS (framerate display), likely | not touched |
| **Mouse4 / Mouse5** | none expected | **new** |
| Ctrl+1-0 | SHAPESHIFTBUTTON1-10 (stance bar) | **not touched**; Ghost Wolf may live there (verify) |
| Ctrl+F | none expected | not touched (spare) |

## Q5: Mouseover macros

The format is from `moba`: `/cast [@mouseover,help,nodead][help,nodead][@player] <Spell>`. The addon already
makes these in mouseover mode, using the highest rank.

| Spell | Macro? | Why |
|---|---|---|
| Healing Wave, Lesser Healing Wave, Chain Heal, Riptide | yes (already) | heal the party frame under the cursor |
| Cure Poison, Cure Disease | yes (already) | cure the party member under the cursor without changing target |
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
  learned. The only planned exception is the **shield key 1**:
  - Lightning Shield (8) is the only shield until **Water Shield** (talent, level 20).
  - They don't stack: only one elemental shield can be active (`moba`). Both last 10 minutes.
  - At 20 the new-skill card for Water Shield puts it on 1, and Lightning Shield moves to a clickable bar.
    `moba` warns not to swap Water Shield for Lightning Shield out of habit, and the move supports that.
  - A one-key macro (`/cast Water Shield` then `/cast Lightning Shield`) was rejected:
    - Before 20 it prints an error for the unknown spell.
    - After 20 the second line fails on the GCD.
    - A `[known:]` condition is not verified in the Forever macro system.
- **Empty top keys while levelling** (see "Top keys" below): R and Mouse4 wait for Chain Heal and Riptide (40),
  and Mouse5 waits for Nature's Swiftness (30).
- **Snapshots** are in section (d).

## Q7: Items

| Item | Key | Why |
|---|---|---|
| Mana Potion (`FS_MANA`, best in the bags) | **Z** | her most used consumable; stays where it is |
| Healthstone, else the best Healing Potion (one macro, e.g. `FS_HEALTH`) | **C** | Healthstones come from warlocks, 2 min cooldown (`wh_tt`): Minor 5512 (also 19004), Lesser 5511, Healthstone 5509, Greater 5510, Major 9421. Next to the Mana Potion on Z: the bottom row holds the consumables (Z mana, C health). The red potion alone is rare for Erika, but with a warlock's Healthstone this is her personal emergency button, and in a panic a key without a modifier is faster and harder to miss. **Verify in game** whether Healthstones and potions share a cooldown. |
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
| Between pulls | Water Shield (1): 1 every 1-2 pulls | globes are used when she is hit and when her spells crit; refresh in safe gaps (`wh_tt`, `moba`) |
| | Call of the Elements (Shift+C): 1 every 3-5 pulls | the 5-minute totems run out (`simc` durations); also after a wipe |
| | Mana Potion (Z): 0 | drinking between pulls is free |
| Pull start | Totemic Call (Shift+Q): 1 | brings the 5-minute totems that are still up to the new pack (`wh_tt`) |
| | Searing Totem (Shift+R): 1 | lasts 30-55 s, so it is gone by the next pull (`simc`) |
| | Riptide (Mouse4): 1 | on the tank as the pack arrives (`wh_abil`) |
| During | Chain Heal (R): 4-8 | the main group heal; several players take damage on trash (`wh_abil`, `moba`) |
| | Healing Wave (F): 2-4 | steady damage on the tank (`wh_abil`) |
| | Riptide (Mouse4): 1-2 more | 12 s cooldown; also boosts the next Chain Heal on that target by 25% (`wh_tt`) |
| | Lesser Healing Wave (E): 1-3 | a spike on someone (`wh_abil`) |
| | Earth Shock (Q): 1-2 | interrupt a caster's heal or big spell (`wh_tt`: interrupt + 2 s lockout) |
| | Flame Shock (2), Lightning Bolt (3): 0-3 together | when healing need is light (`moba`) |
| | Tremor (Shift+F), Purge (Shift+3), cures (Shift+1/2): 0-1 each | only in packs that fear, buff or poison |
| Emergency | Nature's Swiftness + Healing Wave (Mouse5): about 1 pull in 5 | 3 min cooldown (`wh_tt`) |
| | Healthstone / Healing Potion (C): rare | when she is the one about to die |
| | Mana Tide (Shift+X), Mana Potion (Z): 0-1 | in long chains of pulls without a break |
| After | nothing, or Ancestral Spirit (clickable) after a death | Totemic Recall (Ctrl+X) only when leaving the dungeon |

### Level 60, boss (a Scholomance or Stratholme boss, judgment)

| Phase | Spell (key): presses | Why |
|---|---|---|
| Before | Call of the Elements (Shift+C) or a boss preset (Call of the Spirits, clickable): 1 | fresh totems for the whole fight |
| | Water Shield (1): 1 | start with all 3 globes |
| Pull | Riptide (Mouse4), Searing (Shift+R): 1 each | as on trash |
| During | Riptide (Mouse4): 10-15 | on cooldown on the tank: 12 s over 2-3 min |
| | Healing Wave (F): 10-15; Chain Heal (R): 5-15 | single target on the tank; Chain Heal when the boss hits the group |
| | Lesser Healing Wave (E): 2-5 | spikes |
| | Searing (Shift+R): 2-4 more | it runs out after 30-55 s |
| | Earth Shock (Q): 0-3 | only if the boss casts something interruptible |
| | Tremor (Shift+F): 0-1 | only if the boss fears, charms or sleeps |
| | Water Shield (1): 0-1 | if the globes are gone mid-fight |
| Emergency | Mana Tide (Shift+X): 1; Mana Potion (Z): 1; NS + Healing Wave (Mouse5): 0-1 | a long fight costs more mana than trash |
| After | Ancestral Spirit (clickable) if someone died | out of combat |

### Level 40, trash pull (Razorfen Downs 37-47, `wh_dng`)

- **New since 26:** Chain Heal (R) and Riptide (Mouse4), from 40. Nature's Swiftness (Mouse5) from 30. Chain
  Lightning (4) from 32.
- **The pull already looks like the level-60 one:** Chain Heal 3-6, Healing Wave 2-4, Riptide 2, Lesser Healing
  Wave 1-2 and Earth Shock 1-2.
- **Totems:** Totemic Call and Searing every pull.
- **So the level-60 keys are all in use from 40.**

### Level 26, trash pull (Shadowfang Keep 22-30 or Blackfathom Deeps 22-32, `wh_dng`), Erika now

- **Pull start:** Totemic Call (Shift+Q) 1 and Searing (Shift+R) 1.
  - Before 22, or when the set has run out: Call of the Elements (Shift+C), or Stoneskin (Shift+E) by hand.
- **During:**
  - Healing Wave (F) 3-5: the main heal; there is no Chain Heal yet.
  - Lesser Healing Wave (E) 1-2.
  - Earth Shock (Q) 0-2.
  - Flame Shock (2) and Lightning Bolt (3) 1-3 together.
- **Emergency:** Mana Tide (Shift+X), Mana Potion (Z), Healthstone / Healing Potion (C).
- **Water Shield (1):** every 1-2 pulls.
- **The keys she uses now are F, E, Q, 1, 2, 3, Shift+Q and Shift+R.** They are the same keys she will use at 60,
  so nothing has to be relearned when Chain Heal and Riptide arrive.

## Frequency × urgency (level 60, from the walkthroughs)

How the columns work:
- **Urgency:** *very high* means it must land within about a second; *high* means within a GCD or two; *low* means
  set-up or filler.
- **Most pulls:** pressed in most level-60 trash pulls. This decides whether a spell may take a top key.
- **Top keys** are tiers 1 and 2: Mouse4/5, Q, E, R, F, 1, 2, 3 and Shift+Q/E/R/F (13 keys).
- Mnemonic columns and tidy groups were **not** used to give out good keys.

| Spell | Trash presses | Boss presses | Most pulls? | Urgency | Key (tier) |
|---|---|---|---|---|---|
| Chain Heal | 4-8 | 5-15 | yes | high | R (1) |
| Healing Wave | 2-4 | 10-15 | yes | high | F (1) |
| Riptide | 2-3 | 10-15 | yes | high, instant, while moving | Mouse4 (1) |
| Lesser Healing Wave | 1-3 | 2-5 | yes | very high | E (1) |
| Earth Shock (interrupt) | 1-2 | 0-3 | yes (caster packs) | very high | Q (1) |
| Searing Totem | 1 | 3-5 | yes | low-medium | Shift+R (2) |
| Totemic Call | 1 | 0 | yes | low | Shift+Q (2) |
| Lightning Bolt | 0-3 | 0-3 | yes (most pulls have a quiet moment) | low | 3 (2) |
| Flame Shock | 0-2 | 0-2 | yes; instant, also while moving | low | 2 (2) |
| Water Shield | 1 per 1-2 pulls | 1-2 | yes | low | 1 (2) |
| NS + Healing Wave | about 1 pull in 5 | 0-1 | **no** (3 min cooldown) | very high | Mouse5 (1), exception |
| Tremor Totem | 0-1 | 0-1 | **no** (only fear, charm or sleep packs) | high when needed | Shift+F (2), exception |
| Stoneskin Totem | 0-1 | 0 | **no** (in the set; by hand after Tremor) | low | Shift+E (2), exception |
| Call of the Elements | 1 per 3-5 pulls | 1 | no | low (3 s cast out of combat) | Shift+C (4) |
| Mana Potion | 0-1 | 1 | no | medium | Z (3) |
| Healthstone / Healing Potion | rare | 0-1 | no | very high | C (4) |
| Mana Tide Totem | 0-1 | 1 | no | medium | Shift+X (4) |
| Cure Poison, Cure Disease | 0-4 in some dungeons | 0-3 | no (dungeon-specific; the cleansing totem covers most of it, `wh_abil`) | medium | Shift+1, Shift+2 (3) |
| Purge | 0-1 | 0-1 | no | medium | Shift+3 (3) |
| Chain Lightning | 0-1 | 0 | no (2.5 s, expensive for a healer) | low | 4 (3) |
| Mana Spring Totem (by hand) | rare | 0 | no (in the set) | low | Shift+Z (4) |
| Grounding Totem | rare | 0-1 | no | high when needed | Ctrl+Q (3) |
| Stoneclaw Totem | rare | 0 | no | medium | Ctrl+E (3) |
| Frost Shock, Earthbind Totem | rare | 0 | no | medium | Shift+4, Shift+5 (4-5) |
| Healing Stream Totem (by hand) | rare | 0 | no (in the set) | low | Ctrl+Z (4) |
| Totemic Recall | once per dungeon | 0 | no | low | Ctrl+X (5) |
| Ghost Wolf | 0 (outdoors only) | 0 | no | low | Ctrl+C (4), the player's decision |

### Top keys

- **10 spells are pressed in most level-60 pulls, and there are 13 top keys.** The 10 take the best keys:
  - the heals and the interrupt on the tier-1 keys;
  - the totems on the easiest Shift keys;
  - the filler damage and Water Shield on 1-3.
- **The other 3 top keys are exceptions,** filled with the most urgent spells of the rest:
  - **Mouse5, NS + Healing Wave:** used in only about 1 pull in 5, but it is the "someone dies in the next
    second" button, and it is a mouseover on the frame under the cursor. The thumb is the fastest place for it.
  - **Shift+F, Tremor:** only in some dungeons, but a feared tank is an emergency. It is also Erika's habit, and
    she uses it a lot.
  - **Shift+E, Stoneskin:** the weakest top key. From 20 it is in the Call of the Elements set. She presses it
    by hand after Tremor has replaced it (both are Earth totems), and before 20 at every pull. It is Erika's
    habit, and no more frequent spell is left to take the key.
- **Empty top keys while levelling (at 26, Erika now):**
  - **R and Mouse4 stay empty for 14 levels,** until Chain Heal and Riptide at 40.
    - From 40 they are the most-pressed and the most urgent heals.
    - Anything put there now would have to move at 40, exactly when healing gets harder.
    - She has never pressed E for Riptide, so moving Riptide from E to Mouse4 costs her nothing.
  - **Mouse5 stays empty for 4 levels,** until Nature's Swiftness at 30.
- **E is filled now, and stays filled.**
  - Lesser Healing Wave moves from C to E. It is pressed in most pulls from 20 and needs a very fast key.
  - In layout v2 E waited for Riptide (40), which put the more urgent heal on a stretch key for 20 levels.

## (a) Proposed layout

Abbreviations:
- **MO:** mouseover macro.
- *(lvl)*: the level the spell becomes available.
- **Tier:** the reach tier from Q4.
- **v2:** the key the spell has in the current layout (0.3.0).

### No modifier (main bar, `ACTIONBUTTON`)

| Key | Spell or item | v2 | Reason (from the walkthroughs) | Source |
|---|---|---|---|---|
| 1 | Lightning Shield *(8)*, then Water Shield *(20)* | 1 | refreshed every 1-2 pulls, in a safe gap; low urgency, so tier 2 is enough | `wh_tt`, `moba` |
| 2 | Flame Shock *(10)* | 4 | filler damage in most pulls; instant, so also while moving. Lightning Shield's old key is free after 20 | `simc`, `moba` |
| 3 | Lightning Bolt *(1)* | 3 | filler damage in most pulls; a cast, so a short reach is fine | `wh_abil`, `moba` |
| 4 | Chain Lightning *(32)* | Q | rare for a healer (2.5 s, expensive); not worth a tier-1 key | `simc` |
| 5 | – (spare) | Earth Shock | free for Erika's own choice | – |
| Q | Earth Shock, `/stopcasting` + MO harm *(4)* | 5 | the interrupt: most pulls, must land within a second | `wh_tt`, `moba`, `wm` |
| E | Lesser Healing Wave, MO *(20)* | C | the spike heal: most pulls, very urgent | `wh_abil`, `moba` |
| R | Chain Heal, MO *(40)* | R | the most-pressed heal from 40 | `wh_abil`, `moba` |
| F | Healing Wave, MO *(1)* | F | the tank heal in every pull; the main heal before 40 | `wh_abil` |
| Z | Mana Potion (`FS_MANA`) | Z | long chains of pulls and bosses | 0.3.0, `wh_tt` items |
| X | – (spare) | Nature's Swiftness | free for Erika's own choice | – |
| C | Healthstone, else Healing Potion (`FS_HEALTH`) | Lesser Healing Wave | rare but very urgent; no modifier to miss in a panic | `wh_tt` items |

### Mouse side buttons (Action Bar 7, `MULTIACTIONBAR6BUTTON`)

| Key | Spell | v2 | Reason | Source |
|---|---|---|---|---|
| Mouse4 | Riptide, MO *(40)* | E | 2-3 per trash pull, 10-15 per boss; instant, so the thumb casts it while the cursor is on the frame and WASD keeps moving | `wh_tt`, `wh_abil` |
| Mouse5 | Nature's Swiftness + Healing Wave, MO *(30)* | X (NS alone) | the emergency button: one press, on the frame under the cursor (exception, see "Top keys") | `wh_tt`, `moba` |
| Shift/Ctrl+Mouse4/5 | – (spare) | – | free for later | – |

### Shift (Action Bar 2, `MULTIACTIONBAR1BUTTON`)

| Key | Spell | v2 | Reason | Source |
|---|---|---|---|---|
| Shift+1 | Cure Poison, MO *(16)* | Shift+1 | dungeon-specific; tier 3 fits | `wh_abil` |
| Shift+2 | Cure Disease, MO *(22)* | Shift+2 | as above | `wh_abil` |
| Shift+3 | Purge *(12)* | Shift+3 | sometimes, on enemy buffs | `wh_abil`, `moba` |
| Shift+4 | Frost Shock *(20)* | Shift+4 | rare: a runner or a chaser | `wh_abil` |
| Shift+5 | Earthbind Totem *(6)* | Shift+5 | rare: runners | `wh_abil` |
| Shift+Q | **Totemic Call** *(22)* | (clickable) | pressed in most pulls: brings the 5-minute totems along | `wh_tt`, `moba` |
| Shift+E | Stoneskin Totem *(4)* | Shift+E | Erika's habit; by hand after Tremor (exception, see "Top keys") | Erika, `wh_tt` |
| Shift+R | Searing Totem *(10)* | Shift+R | every pull, and 2-4 more times per boss (30-55 s) | Erika, `simc` |
| Shift+F | Tremor Totem *(18)* | Shift+F | fear, charm and sleep: urgent when it happens (exception) | Erika, `wh_abil` |
| Shift+Z | Mana Spring Totem *(26)* | Shift+Z | in the set; by hand only to swap the Water totem | `moba` |
| Shift+X | Mana Tide Totem *(25)* | Shift+X | once per boss, sometimes on trash | `simc`, `moba` |
| Shift+C | Call of the Elements *(20)* | Shift+C | every 3-5 pulls and before a boss: a 3 s cast out of combat, so a stretch key is fine | `wh_tt`, `simc` durations |

### Ctrl (Action Bar 6, `MULTIACTIONBAR5BUTTON`)

| Key | Spell | v2 | Reason | Source |
|---|---|---|---|---|
| Ctrl+Q | Grounding Totem *(30)* | (clickable) | rare, but it must go down before a dangerous cast lands | `wh_abil` |
| Ctrl+E | Stoneclaw Totem *(8)* | (clickable) | rare: enemies hitting the healer | `wh_abil` |
| Ctrl+Z | Healing Stream Totem *(20)* | Shift+Q | in the Call of the Elements set, so it is rarely placed by hand; gives Shift+Q to Totemic Call | `moba` |
| Ctrl+X | Totemic Recall *(20)* | (clickable) | once, when leaving the dungeon | `wh_tt`, `moba` |
| Ctrl+C | Ghost Wolf *(20)* | (clickable) | the player's decision; outdoors only, for questing | user, `simc` 2645 |
| Ctrl+R, Ctrl+F, Ctrl+1-5 | – (spare) | – | Ctrl+R keeps its default; Ctrl+1-0 is the stance bar | – |

## Diff against layout v2 (ForeverSensei 0.3.0)

Sixteen keys keep their spell: 1, 3, R, F, Z, Shift+1-5, Shift+E/R/F/Z/X/C. The moves:

| Spell | v2 → new | Does Erika (26) feel it? | Reason |
|---|---|---|---|
| Earth Shock | 5 → Q | yes | the interrupt is used in most pulls and must land within a second; 5 is the hardest number |
| Chain Lightning | Q → 4 | no (learned at 32) | rare for a healer; it was blocking Q |
| Flame Shock | 4 → 2 | yes | filler in most pulls; 2 is easier than 4 |
| Lightning Shield | 2 → clickable | yes (unused since 20) | it can't be used together with Water Shield; a top key was wasted |
| Lesser Healing Wave | C → E | yes | very urgent spike heal in most pulls; C is a stretch key |
| Riptide | E → Mouse4 | no (learned at 40) | instant, cast while moving, on the cursor's frame |
| Nature's Swiftness | X → Mouse5 (as NS + Healing Wave) | no (learned at 30) | one press instead of two in an emergency |
| Healing Stream Totem | Shift+Q → Ctrl+Z | yes | rarely placed by hand once Call of the Elements places it |
| Totemic Call | clickable → Shift+Q | new key | most pulls |
| Healthstone / Healing Potion | clickable → C | new key | rare but very urgent |
| Grounding, Stoneclaw, Totemic Recall, Ghost Wolf | clickable → Ctrl+Q/E/X/C | new keys | rare reactions, the leave button, and the player's Ghost Wolf decision |

- **For Erika (26), five spells she already uses move:** Earth Shock, Flame Shock, Lightning Shield, Lesser
  Healing Wave and Healing Stream. Riptide, Nature's Swiftness and Chain Lightning move before she learns them.
- **Freed:** 5 and X stay spare. Leaving them empty is cheaper than moving more spells to fill tier-4 keys.

## (b) Unkeyed, on clickable bars

| Spell or item | Reason |
|---|---|
| Rockbiter, Flametongue, Frostbrand and Windfury Weapon | weapon buffs that last long; cast before the pull |
| Minor Arcane Elixir (`FS_ELIXIR`) | long buff, next to the weapon buffs (decided in 0.3.0) |
| Healing Potion (`FS_HEALPOT`) | C covers it when there is no Healthstone |
| Lightning Shield (after 20) | replaced by Water Shield on 1 |
| Strength of Earth Totem | a set-up choice instead of Stoneskin; put it in the Totem Bar set for melee groups |
| Windfury Totem, Grace of Air Totem | Air totems for melee groups; set up through the Totem Bar |
| Poison Cleansing, Disease Cleansing Totem | put in the set's Water slot for a poison- or disease-heavy dungeon (`wh_abil`) |
| Magma Totem, Fire Nova | AoE damage; rare for a healer |
| Flametongue Totem | rare |
| Frost, Fire and Nature Resistance Totem, Windwall Totem | boss-specific; picked in a Totem Bar set |
| Sentry Totem, Far Sight | scouting; not used in dungeons |
| Call of the Ancestors, Call of the Spirits | a second and third preset (e.g. a boss set), clicked next to Call of the Elements |
| Ancestral Spirit (optional MO dead macro) | 10 s cast, after a death; out of combat |
| Astral Recall, Water Walking, Water Breathing | travel; out of combat |
| Bandages (optional) | see Q7 |
| Reincarnation | passive; offered by the death dialog |

## (c) Default bindings that are replaced

Already replaced by layout v2 (no change):
- Q/E strafe, R reply, F assist (verify), Z sheath, X sit/stand, C character window.
- Shift+1-5 bar paging.

New in this proposal:
- Ctrl+Q, Ctrl+E, Ctrl+Z, Ctrl+X and Ctrl+C (no default expected).
- Mouse4 and Mouse5 (no default expected).

Not touched:
- Ctrl+R (probably the framerate display), Ctrl+F, Ctrl+1-0 (the stance bar).
- Alt with any key.

Verify all of these with the `/run` lines in Q4. Apply-layout already backs up and can undo bindings.

## (d) Snapshots by level

"–" means the key is reserved but still empty. Spare keys (5, X, Shift/Ctrl+Mouse) are left out.

| Key | 10 | 20 | 26 | 30 | 40 | 60 |
|---|---|---|---|---|---|---|
| 1 | Lightning Shield | Water Shield | Water Shield | Water Shield | Water Shield | Water Shield |
| 2 | Flame Shock | Flame Shock | Flame Shock | Flame Shock | Flame Shock | Flame Shock |
| 3 | Lightning Bolt | Lightning Bolt | Lightning Bolt | Lightning Bolt | Lightning Bolt | Lightning Bolt |
| 4 | – | – | – | – | Chain Lightning | Chain Lightning |
| Q | Earth Shock | Earth Shock | Earth Shock | Earth Shock | Earth Shock | Earth Shock |
| E | – | Lesser Healing Wave | Lesser Healing Wave | Lesser Healing Wave | Lesser Healing Wave | Lesser Healing Wave |
| R | – | – | – | – | Chain Heal | Chain Heal |
| F | Healing Wave | Healing Wave | Healing Wave | Healing Wave | Healing Wave | Healing Wave |
| Z | Mana Potion | Mana Potion | Mana Potion | Mana Potion | Mana Potion | Mana Potion |
| C | Healthstone / Healing Potion | Healthstone / Healing Potion | Healthstone / Healing Potion | Healthstone / Healing Potion | Healthstone / Healing Potion | Healthstone / Healing Potion |
| Mouse4 | – | – | – | – | Riptide | Riptide |
| Mouse5 | – | – | – | NS + Healing Wave | NS + Healing Wave | NS + Healing Wave |
| Shift+1 | – | Cure Poison | Cure Poison | Cure Poison | Cure Poison | Cure Poison |
| Shift+2 | – | – | Cure Disease | Cure Disease | Cure Disease | Cure Disease |
| Shift+3 | – | Purge | Purge | Purge | Purge | Purge |
| Shift+4 | – | Frost Shock | Frost Shock | Frost Shock | Frost Shock | Frost Shock |
| Shift+5 | Earthbind | Earthbind | Earthbind | Earthbind | Earthbind | Earthbind |
| Shift+Q | – | – | Totemic Call | Totemic Call | Totemic Call | Totemic Call |
| Shift+E | Stoneskin | Stoneskin | Stoneskin | Stoneskin | Stoneskin | Stoneskin |
| Shift+R | Searing | Searing | Searing | Searing | Searing | Searing |
| Shift+F | – | Tremor | Tremor | Tremor | Tremor | Tremor |
| Shift+Z | – | – | Mana Spring | Mana Spring | Mana Spring | Mana Spring |
| Shift+X | – | – | Mana Tide | Mana Tide | Mana Tide | Mana Tide |
| Shift+C | – | Call of the Elements | Call of the Elements | Call of the Elements | Call of the Elements | Call of the Elements |
| Ctrl+Q | – | – | – | Grounding | Grounding | Grounding |
| Ctrl+E | Stoneclaw | Stoneclaw | Stoneclaw | Stoneclaw | Stoneclaw | Stoneclaw |
| Ctrl+Z | – | Healing Stream | Healing Stream | Healing Stream | Healing Stream | Healing Stream |
| Ctrl+X | – | Totemic Recall | Totemic Recall | Totemic Recall | Totemic Recall | Totemic Recall |
| Ctrl+C | – | Ghost Wolf | Ghost Wolf | Ghost Wolf | Ghost Wolf | Ghost Wolf |
| Keys in use | 11 | 20 | 24 | 26 | 29 | 29 |

Notes:
- Minor Healing Potion has no required level, and Minor Mana Potion needs level 5 (`Data/Items.lua`).
- Before a potion is in the bags, the macro shows its fallback icon.
- At 10 the unkeyed buttons are Rockbiter, Flametongue Weapon and Strength of Earth. Grace of Air (42) is the
  last unkeyed spell.

## Where this overrides Erika's wishes

**Kept:**
- Healing Wave on F.
- Totems on Shift, with her pull totems on Shift+E (Stoneskin), Shift+R (Searing) and Shift+F (Tremor).
- Mana Potion on Z.
- Totemic Call, Totemic Recall and Call of the Elements all keyed.
- Rare and out-of-combat spells unkeyed.

**Overridden, with the gameplay reason:**
1. **Heals on F/C/R/E/X → F, E, R and the mouse buttons.**
   - C and X are stretch keys (tier 4) for a small hand.
   - Lesser Healing Wave (very urgent) and Nature's Swiftness (the emergency) need the fastest keys, not the
     slowest.
2. **Shields on 1 and 2 → only Water Shield on 1.**
   - Lightning Shield can't be active together with Water Shield (`moba`), so after 20 its key was wasted.
3. **One totem leaves Shift:** Healing Stream goes to Ctrl+Z.
   - Shift+Q is needed for Totemic Call, which is pressed in most pulls.
   - Healing Stream is placed by Call of the Elements and rarely by hand.

## Verify in game (for the implementation task)

1. The default actions of the replaced keys: the `/run` lines in Q4.
2. Action Bars 6 and 7 must be shown for their key bindings to fire, or check that hidden bars work.
3. `SetMultiCastSpell(<action>, <spellId>)` from an addon, out of combat.
4. `SetBindingClick` on `MultiCastActionButtonN` (only if needed).
5. The NS + Healing Wave macro casts both spells in one press. Does `/stopcasting` work in a macro?
6. Healthstone and potion: shared cooldown or not.
7. Does Ghost Wolf appear on the stance bar (Ctrl+1)?
8. The mana cost of Call of the Elements: does the tooltip's "None" really mean only the totems' own cost?

## (e) Erika へのまとめ（日本語）

レベル60でダンジョンを回復する時を基準に、キー配置を作り直した。実際の戦闘の流れ（戦闘の合間・戦闘開始・戦闘中・緊急時・戦闘の後）で、どの呪文を何回押すかを数えた。よく押す呪文や急いで使う呪文ほど、押しやすいキーに置いた。レベルが低い時は、この中で覚えた呪文だけを使う。一度覚えた呪文のキーは、レベルが上がっても変わらない。

| キー | 中身 |
|---|---|
| F | Healing Wave（今まで通り） |
| R | Chain Heal（レベル40から、今まで通り） |
| E | Lesser Healing Wave（Cから移動） |
| Q | Earth Shock（5から移動。敵の詠唱を中断する） |
| マウスのボタン4 | Riptide（レベル40から） |
| マウスのボタン5 | Nature's Swiftness ＋ Healing Wave（1回押すだけ。レベル30から） |
| 1 | Water Shield（今まで通り） |
| 2 | Flame Shock（4から移動） |
| 3 | Lightning Bolt（今まで通り） |
| 4 | Chain Lightning（レベル32から） |
| Z | Mana Potion（今まで通り） |
| C | Healthstone（なければHealing Potion） |
| Shift+Q | Totemic Call |
| Shift+E・Shift+R・Shift+F | Stoneskin Totem・Searing Totem・Tremor Totem（今まで通り） |
| Shift+C | Call of the Elements（今まで通り） |
| Shift+Z・Shift+X | Mana Spring Totem・Mana Tide Totem（今まで通り） |
| Shift+1・Shift+2・Shift+3 | Cure Poison・Cure Disease・Purge（今まで通り） |
| Shift+4・Shift+5 | Frost Shock・Earthbind Totem（今まで通り） |
| Ctrl+Q・Ctrl+E | Grounding Totem・Stoneclaw Totem |
| Ctrl+Z | Healing Stream Totem（Shift+Qから移動） |
| Ctrl+X | Totemic Recall |
| Ctrl+C | Ghost Wolf |

主な理由:
- **よく使う回復を一番押しやすいキーに置いた。** レベル60の普通の戦闘では、Chain Heal（R）を4〜8回、Healing Wave（F）を2〜4回、Riptide（マウスのボタン4）を2〜3回使う。
- **Lesser Healing WaveをCからEに移した。** 急に大きなダメージを受けた味方を回復する呪文なので、WASDのすぐ隣のEがいい。Cは小さな手には遠い。
- **Riptideはマウスのボタン4。** 詠唱がないので、歩きながら使える。親指で押すので、カーソルはパーティーの枠の上に置いたままでいい。
- **Nature's Swiftnessはマウスのボタン5。** 1回押すだけでNature's SwiftnessとHealing Waveを続けて使う、緊急用のマクロにする。クールダウンが3分なので毎回は使わないが、使う時は一番急ぐ。
- **Earth ShockをQに移した。** 敵の詠唱を中断する呪文。ほぼ毎回の戦闘で使い、1秒も待てないので、一番押しやすいキーに置いた。回復の詠唱中でも、止めてすぐに使える。
- **回復が少ない時のダメージは2と3。** Flame Shock（2）とLightning Bolt（3）。Lightning ShieldはWater Shieldと同時に使えないので、キーから外した。Chain Lightningは回復役にはマナが重いので、4に置いた。
- **Water Shieldは1のまま。** 攻撃を受けた時や、自分の呪文がクリティカルになった時に、玉を1つ使ってマナが戻る。玉は3つなので、1〜2回の戦闘ごとに、戦闘の合間にかけ直そう。
- **Totemic CallをShift+Qに置いた。** ほぼ毎回の戦闘で使う。今出しているトーテムを自分の場所に移す（クールダウンは30秒）。ただし、消えたトーテムは戻らない。
- **Searing Totem（Shift+R）は毎回置く。** 30〜55秒で消えるので、ボス戦では消えたらもう一度置こう。
- **Call of the Elements（Shift+C）は約5分ごと。** 長く続くトーテムも5分で消える。数回の戦闘ごとと全滅の後に、戦闘の合間に使おう。
- **Healing Stream TotemはCtrl+Zに移した。** Call of the Elementsでまとめて置くので、手で置くことはあまりない。Shift+QはTotemic Callに使う。
- **CureとPurgeはShift+1・2・3のまま。** 毒や病気が多いダンジョンでだけよく使う。そういうダンジョンでは、Poison Cleansing TotemかDisease Cleansing TotemをCall of the Elementsのセットに入れよう。
- **CはHealthstone（なければHealing Potion）。** 自分が倒れそうな時の緊急用。あわてている時でも、Shiftなしで押せる。
- **Ctrlはあまり使わないもの用。** Ghost Wolfは屋外でだけ使えるので、ダンジョンではほとんど使わない。
- **Rとマウスのボタン4はレベル40まで空いている。** Chain HealとRiptideを覚えたら、そこに置く。後でキーを変えなくていいように、先に場所を決めておく。
- **5とXは空けておく。** 好きな物を置いていい。
- **めったに使わない呪文はキーなし。** Ancestral Spirit・Astral Recall・Water Walkingなどは、クリック用のバーに置く。
