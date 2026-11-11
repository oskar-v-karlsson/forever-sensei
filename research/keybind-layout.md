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
- **Set-up**: cast once per dungeon, per wipe, or per ~5 minutes.
- **Cast**: a spell with a cast time, used while standing still, so reach matters less.
- **OOC**: out of combat or travel.

Cast, cooldown and cost are rank 1, from `simc`, or from `wh_tt` for spells missing from the dump.

| Spell | Lvl | Cast / CD / cost / duration | Use in a dungeon | Type | Proposed key |
|---|---|---|---|---|---|
| Healing Wave | 1 | 1.5 s cast (longer at higher ranks) / – / 25 | constant: the main heal for expected damage on the tank | Cast | F |
| Lightning Bolt | 1 | 1.5 s / – / 15 | often, when healing need is light | Cast | 3 |
| Rockbiter Weapon | 1 | instant / – / 15 | before the dungeon, weapon buff | OOC | none |
| Earth Shock | 4 | instant / 6 s / 30, 2 s lockout | the interrupt for dangerous casts | React | Q |
| Stoneskin Totem | 4 | instant / – / 30, 5 min, Earth | every pull (Erika's habit) | Pull | Shift+E |
| Earthbind Totem | 6 | instant / 15 s / 6% base mana, 45 s, Earth | rare: runners, kiting | React | Shift+5 |
| Stoneclaw Totem | 8 | instant / 30 s / 15, 15 s, Earth | rare: enemies hitting the healer | React | Ctrl+E |
| Lightning Shield | 8 | instant / – / 45, 10 min | levels 8-19 only, replaced by Water Shield | Set-up | X until 20 |
| Flame Shock | 10 | instant / 6 s / 55, 12 s DoT | often when DPSing; instant, usable while moving | React/DPS | 4 |
| Searing Totem | 10 | instant / – / 25, **30 s**, Fire | every pull (Erika's habit; it only lasts 30 s) | Pull | Shift+R |
| Flametongue Weapon | 10 | instant / – / 30 | before the dungeon | OOC | none |
| Strength of Earth Totem | 10 | instant / – / 25, 5 min, Earth | instead of Stoneskin for melee groups | Set-up | none (Totem Bar set) |
| Fire Nova | 12 | instant / 10 s / 65 | rare for a healer: AoE around the Fire totem | DPS | none |
| Purge | 12 | instant / – / 10% base mana | sometimes: enemy buffs | React | 5 |
| Ancestral Spirit | 12 | 10 s / – / 90% base mana | after a death or wipe | OOC | none |
| Cure Poison | 16 | instant / – / 9% base mana | often in poison dungeons | React | 1 |
| Tremor Totem | 18 | instant / – / 60, 5 min, Earth | fear, charm and sleep fights (Erika uses it a lot) | React | Shift+F |
| Call of the Elements | 20 | 3 s / – / none / GCD | start of the dungeon and after a wipe | Set-up | Shift+C |
| Frost Shock | 20 | instant / 6 s / 115, 8 s slow | rare: slow a runner or a chaser | React | Ctrl+Q |
| Totemic Recall | 20 | instant / – / returns 25% of the totems' mana | after the last pull, before a long run | OOC | Ctrl+C |
| Frostbrand Weapon | 20 | instant / – / 60 | solo only | OOC | none |
| Ghost Wolf | 20 | 3 s / – / 100, outdoors only | none: Erika's talent path has no Improved Ghost Wolf, so it cannot be used indoors | OOC (questing) | C |
| Healing Stream Totem | 20 | instant / – / 40, 5 min, Water | part of the pull set; swap with Mana Spring | Set-up | Shift+3 |
| Lesser Healing Wave | 20 | 1.5 s / – / 105 | the fast emergency heal | React (cast) | E |
| Water Shield | 20 (talent) | instant / – / none, 10 min, 3 globes | refresh between pulls or in gaps | Set-up | X |
| Totemic Call | 22 | instant / 30 s / 25% base mana | every pull: moves the totems to you | Pull | Shift+Q |
| Water Breathing | 22 | – | never in a dungeon | OOC | none |
| Cure Disease | 22 | instant / – / 9% base mana | often in disease dungeons | React | 2 |
| Poison Cleansing Totem | 22 | instant / – / 10% base mana, Water | poison-heavy fights | React | Shift+1 |
| Frost Resistance Totem | 24 | instant / – / 75, Fire | rare, boss-specific | Set-up | none (Totem Bar) |
| Mana Tide Totem | 25 (talent) | instant / 5 min / 10, 13 s, Water | long fights, low mana | React | Shift+Z |
| Magma Totem | 26 | instant / – / 230, 20 s, Fire | rare for a healer: big packs | DPS | none |
| Far Sight | 26 | 2 s / – / 80 | never | OOC | none |
| Mana Spring Totem | 26 | instant / – / 40, 5 min, Water | the default Water totem from 26 | Set-up | Shift+4 |
| Fire Resistance Totem | 28 | instant / – / 75, Water | rare, boss-specific | Set-up | none (Totem Bar) |
| Flametongue Totem | 28 | instant / – / 90, Fire | rare: caster-heavy groups | Set-up | none |
| Water Walking | 28 | – | never in a dungeon | OOC | none |
| Call of the Ancestors | 30 | 3 s / – / none | a second preset (e.g. the Tremor set) | Set-up | none (next to CotE) |
| Astral Recall | 30 | – | after the dungeon | OOC | none |
| Grounding Totem | 30 | instant / 15 s / 6% base mana, 45 s, Air | against dangerous single casts | React | Shift+X |
| Nature Resistance Totem | 30 | instant / – / 75, Air | rare, boss-specific | Set-up | none (Totem Bar) |
| Windfury Weapon | 30 | instant / – / 90 | solo only | OOC | none |
| Nature's Swiftness | 30 (talent) | instant / 3 min | emergency: NS + Healing Wave | React | Mouse4 (macro) |
| Reincarnation | 30 | passive / 60 min | self-resurrect after a wipe | – | none (passive) |
| Chain Lightning | 32 | 2.5 s / 6 s / 245 | AoE damage when healing is light | Cast/DPS | Ctrl+R |
| Windfury Totem | 32 | instant / – / 115, Air | melee groups, through the Totem Bar set | Set-up | none |
| Sentry Totem | 34 | instant / – / 65, Air | never | OOC | none |
| Windwall Totem | 36 | instant / – / 115, Air | rare, ranged-heavy fights | Set-up | none (Totem Bar) |
| Disease Cleansing Totem | 38 | instant / – / 10% base mana, Water | disease-heavy fights | React | Shift+2 |
| Call of the Spirits | 40 | 3 s / – / none | a third preset (boss set) | Set-up | none (next to CotE) |
| Chain Heal | 40 | 2.5 s / – / 260, 3 targets | constant from 40: the main group heal | Cast | R |
| Riptide | 40 (talent) | instant / 12 s / 150, 15 s HoT, +25% Chain Heal | on cooldown on the tank; usable while moving | React | Mouse5 |
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

1. **Start of the dungeon, or after a wipe:** press **Call of the Elements** (Shift+C) once. The 3 s cast places
   the whole set.
   - Suggested set 1: Stoneskin + Searing + Healing Stream (Mana Spring from 26) + an Air totem
     (Windfury for a melee group from 32, otherwise Grace of Air from 42).
2. **Every pull:**
   - Press **Totemic Call** (Shift+Q) where the group fights. The 5-minute totems come with you at 25% base
     mana, which is cheaper and faster than recasting them.
   - Press **Searing Totem** (Shift+R). It only lasts 30 s, so it is gone by the next pull anyway.
3. **React:**
   - Tremor (Shift+F) against fear, charm and sleep. It replaces Stoneskin until you press Stoneskin (Shift+E)
     again.
   - Grounding (Shift+X) against a dangerous caster.
   - Poison or Disease Cleansing (Shift+1 or Shift+2).
   - Mana Tide (Shift+Z) when your mana is low in a long fight.
   - Earthbind (Shift+5) for runners.
4. **Leaving:** press **Totemic Recall** (Ctrl+C) to get some mana back.

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
  - Separate keys for the totems she swaps by hand: Tremor, Grounding, the cleansing totems, Mana Tide.
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
  - Button 1 is Mouse4 and button 2 is Mouse5. Buttons 3-6 are reserved for Shift+ and Ctrl+Mouse4/5.
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
/run for _,k in ipairs({"CTRL-Q","CTRL-E","CTRL-R","CTRL-C","CTRL-Z","BUTTON4","BUTTON5"}) do print(k,GetBindingAction(k)) end
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
| **Ctrl+Q/E/C/Z** | none expected | **new** |
| **Ctrl+R** | TOGGLEFPS (framerate display), likely | **new**: only a debug display is lost |
| **Mouse4 / Mouse5** | none expected | **new** |
| Ctrl+1-0 | SHAPESHIFTBUTTON1-10 (stance bar) | **not touched**; Ghost Wolf may live there (verify) |
| Ctrl+F, Ctrl+X | none expected | not touched (spare) |

## Q5: Mouseover macros

The format is from `moba`: `/cast [@mouseover,help,nodead][help,nodead][@player] <Spell>`. The addon already
makes these in mouseover mode, using the highest rank.

| Spell | Macro? | Why |
|---|---|---|
| Healing Wave, Lesser Healing Wave, Chain Heal, Riptide | yes (already) | heal the party frame under the cursor |
| Cure Poison, Cure Disease | yes (already) | cure the party member under the cursor without changing target |
| Nature's Swiftness + Healing Wave (Mouse4) | yes (new) | `#showtooltip Healing Wave` / `/cast Nature's Swiftness` / `/cast [@mouseover,help,nodead][help,nodead][@player] Healing Wave` |
| Earth Shock (Q) | yes (new), harmful form | `/stopcasting` / `/cast [@mouseover,harm,nodead][] Earth Shock`. Interrupts the enemy under the cursor, or else your target, even mid-heal. |
| Purge (5) | yes (new), harmful form | `/cast [@mouseover,harm,nodead][] Purge` |
| Ancestral Spirit | optional, dead form | `/cast [@mouseover,help,dead][] Ancestral Spirit`, on a clickable bar |
| Totems, shields, damage spells | no | totems and shields have no target; damage uses the normal target |

**Verify in game:**
- Does `/stopcasting` still work in a 12.x macro? `STOPCASTING` exists as a binding name.
- Does the NS + Healing Wave macro cast both spells in one press?
  - Nature's Swiftness is off the GCD in `simc` (no cooldown category for the GCD), but the 12.x client may
    differ.
  - If NS is on cooldown, the macro casts a normal (slow) Healing Wave. The card should say so.

## Q6: Level progression and the shield key

- **Keys never move after a spell is learned.** Every key in section (a) is reserved for exactly one spell or
  item, with one planned exception: the **shield key X**.
  - Lightning Shield (8) is the only shield until **Water Shield** (talent, level 20).
  - They don't stack: only one elemental shield can be active (`moba`). Both last 10 minutes.
  - At 20 the new-skill card for Water Shield puts it on X, and Lightning Shield moves to a clickable bar.
    `moba` warns not to swap Water Shield for Lightning Shield out of habit, and the move supports that.
  - A one-key macro (`/cast Water Shield` then `/cast Lightning Shield`) was rejected:
    - Before 20 it prints an error for the unknown spell.
    - After 20 the second line fails on the GCD.
    - A `[known:]` condition is not verified in the Forever macro system.
- **The important keys fill early:**
  - F, Q, 3 and 4 are used from level 1-10.
  - Shift+E and Shift+R (her pull totems) from 4 and 10.
  - E and the rest of the Shift row by 20-26.
  - R (Chain Heal) and Mouse5 (Riptide) stay empty until 40. Those spells only come at 40, and they are the best
    healer keys once learned. Giving R to something else now would mean moving it at 40.
- **Snapshots** are in section (d).

## Q7: Items

| Item | Key | Why |
|---|---|---|
| Mana Potion (`FS_MANA`, best in the bags) | **Z** | her most used consumable; stays where it is |
| Healthstone, else the best Healing Potion (one macro, e.g. `FS_HEALTH`) | **Ctrl+Z** | Healthstones come from warlocks, 2 min cooldown (`wh_tt`): Minor 5512 (also 19004), Lesser 5511, Healthstone 5509, Greater 5510, Major 9421. Under the Mana Potion (the Z column is items). Erika rarely uses the red potion, so it takes the cheaper Ctrl key. **Verify in game** whether Healthstones and potions share a cooldown. |
| Healing Potion (`FS_HEALPOT`) | none, clickable | as now; Ctrl+Z covers it when there is no Healthstone |
| Minor Arcane Elixir (`FS_ELIXIR`) | none, clickable | next to the weapon imbues and long buffs, as decided for 0.3.0 |
| Bandages (Linen 1251, Silk 6450, Heavy Mageweave 8545, Runecloth 14529, Heavy Runecloth 14530) | none | They need First Aid and are an 8 s channel that damage breaks. A healer heals herself with spells. Optional clickable slot for solo. |

## (a) Proposed layout

Abbreviations: **MO** = mouseover macro; *(lvl)* = the level it becomes available.

### No modifier (main bar, `ACTIONBUTTON`)

| Key | Spell or item | Reason | Source |
|---|---|---|---|
| 1 | Cure Poison, MO *(16)* | instant reaction on a party frame; the 1 column is "poison" | `simc`, `wh_abil` |
| 2 | Cure Disease, MO *(22)* | the same; the 2 column is "disease" | `simc`, `wh_abil` |
| 3 | Lightning Bolt *(1)* | the main damage filler when healing is light; a cast, so a short reach is fine | `wh_abil` |
| 4 | Flame Shock *(10)* | instant damage, also while moving | `simc` |
| 5 | Purge, MO harm *(12)* | situational: enemy buffs | `wh_abil`, `moba` |
| Q | Earth Shock, `/stopcasting` + MO harm *(4)* | the interrupt has to be the fastest key | `simc`, `moba`, `wm` |
| E | Lesser Healing Wave, MO *(20)* | the fast emergency heal, on a top key | `moba` |
| R | Chain Heal, MO *(40)* | the main group heal from 40 (empty before) | `wh_abil`, `moba` |
| F | Healing Wave, MO *(1)* | the main heal, as Erika asked | `wh_abil` |
| Z | Mana Potion (`FS_MANA`) | her most used potion, as now | 0.3.0, `wh_tt` items |
| X | Shield: Lightning Shield *(8)*, then Water Shield *(20)* | one key, because they don't stack and last 10 min | `simc`, `moba` |
| C | Ghost Wolf *(20)* | travel while questing; 3 s cast, outdoors only (no Improved Ghost Wolf in her talent path) | `simc` 2645 |

### Shift (Action Bar 2, `MULTIACTIONBAR1BUTTON`): totems

| Key | Totem or spell | Reason | Source |
|---|---|---|---|
| Shift+1 | Poison Cleansing Totem *(22)* | the poison column, above Cure Poison | `wh_abil` |
| Shift+2 | Disease Cleansing Totem *(38)* | the disease column, above Cure Disease | `wh_abil` |
| Shift+3 | Healing Stream Totem *(20)* | the Water totem of the pull set; swap it with Mana Spring | `wh_abil`, `moba` |
| Shift+4 | Mana Spring Totem *(26)* | the default Water totem from 26 | `moba` |
| Shift+5 | Earthbind Totem *(6)* | rare: runners | `wh_abil` |
| Shift+Q | **Totemic Call** *(22)* | used at every pull, so it gets the easiest Shift key | `wh_tt`, `moba` |
| Shift+E | Stoneskin Totem *(4)* | her pull totem, kept | Erika, `wh_abil` |
| Shift+R | Searing Totem *(10)* | her pull totem (30 s), kept | Erika, `wh_tt` |
| Shift+F | Tremor Totem *(18)* | fear, charm and sleep; she uses it a lot; kept | Erika, `wh_abil` |
| Shift+Z | Mana Tide Totem *(25)* | above the Mana Potion: the mana column | `simc`, `moba` |
| Shift+X | Grounding Totem *(30)* | above the shield: the protection column | `wh_abil` |
| Shift+C | Call of the Elements *(20)* | a 3 s set-up cast, once per dungeon or wipe, so a stretch key is fine | `wh_tt`, `moba` |

### Ctrl (Action Bar 6, `MULTIACTIONBAR5BUTTON`): rare but keyed

| Key | Spell or item | Reason | Source |
|---|---|---|---|
| Ctrl+Q | Frost Shock *(20)* | the Q column holds the shocks; a rare slow | `wh_abil` |
| Ctrl+E | Stoneclaw Totem *(8)* | an Earth totem next to Stoneskin; for enemies hitting you | `wh_abil` |
| Ctrl+R | Chain Lightning *(32)* | the R column is "chain"; AoE damage when healing is light | `wh_abil` |
| Ctrl+C | **Totemic Recall** *(20)* | the C column is "the whole totem set", under Call of the Elements | `wh_tt`, `moba` |
| Ctrl+Z | Healthstone, else Healing Potion (one macro) | the Z column is items | `wh_tt` items |
| Ctrl+F, Ctrl+X, Ctrl+1-5 | – (spare) | Ctrl+1-0 is the stance bar default; F and X are left free for later | – |

### Mouse side buttons (Action Bar 7, `MULTIACTIONBAR6BUTTON`)

| Key | Spell | Reason | Source |
|---|---|---|---|
| Mouse4 | Nature's Swiftness + Healing Wave, MO *(30)* | a one-press emergency heal on the frame under the cursor | `moba`, `wm` |
| Mouse5 | Riptide, MO *(40)* | an instant on a 12 s cooldown, used constantly on the tank, also while moving | `simc`, `wh_abil` |
| Shift/Ctrl+Mouse4/5 | – (spare) | kept free for Erika's own choices later | – |

## (b) Unkeyed, on clickable bars

| Spell or item | Reason |
|---|---|
| Rockbiter, Flametongue, Frostbrand and Windfury Weapon | weapon buffs that last long; cast before the pull |
| Minor Arcane Elixir (`FS_ELIXIR`) | long buff, next to the weapon buffs (decided in 0.3.0) |
| Healing Potion (`FS_HEALPOT`) | rarely used; Ctrl+Z covers it when there is no Healthstone |
| Lightning Shield (after 20) | replaced by Water Shield on X |
| Strength of Earth Totem | a set-up choice instead of Stoneskin; put it in the Totem Bar set for melee groups |
| Windfury Totem, Grace of Air Totem | Air totems for melee groups; set up through the Totem Bar |
| Magma Totem, Fire Nova | AoE damage; rare for a healer with a 3-person DPS team |
| Flametongue Totem | rare |
| Frost, Fire and Nature Resistance Totem, Windwall Totem | boss-specific; picked in a Totem Bar set (as now) |
| Sentry Totem, Far Sight | scouting; not used in dungeons |
| Call of the Ancestors, Call of the Spirits | set-up; a second and third preset, clicked next to Call of the Elements |
| Ancestral Spirit (optional MO dead macro) | 10 s cast, after a death; out of combat |
| Astral Recall, Water Walking, Water Breathing | travel; out of combat |
| Bandages (optional) | see Q7 |
| Reincarnation | passive; offered by the death dialog |

## (c) Default bindings that are replaced

Already replaced by layout v2 (no change):
- Q/E strafe, R reply, F assist (verify), Z sheath, X sit/stand, C character window.
- Shift+1-5 bar paging.

New in this proposal:
- **Ctrl+R** (probably TOGGLEFPS, the framerate display).
- Ctrl+Q, Ctrl+E, Ctrl+C and Ctrl+Z (none expected).
- Mouse4 and Mouse5 (none expected).

Not touched: Ctrl+1-0 (stance bar), Ctrl+F, Ctrl+X, Alt+anything.

Verify all of these with the `/run` lines in Q4. Apply-layout already backs up and can undo bindings.

## (d) Snapshots by level

"–" means the key is reserved but still empty.

| Key | 10 | 20 | 30 | 40 | 60 |
|---|---|---|---|---|---|
| 1 | – | Cure Poison | Cure Poison | Cure Poison | Cure Poison |
| 2 | – | – | Cure Disease | Cure Disease | Cure Disease |
| 3 | Lightning Bolt | Lightning Bolt | Lightning Bolt | Lightning Bolt | Lightning Bolt |
| 4 | Flame Shock | Flame Shock | Flame Shock | Flame Shock | Flame Shock |
| 5 | – | Purge | Purge | Purge | Purge |
| Q | Earth Shock | Earth Shock | Earth Shock | Earth Shock | Earth Shock |
| E | – | Lesser Healing Wave | Lesser Healing Wave | Lesser Healing Wave | Lesser Healing Wave |
| R | – | – | – | Chain Heal | Chain Heal |
| F | Healing Wave | Healing Wave | Healing Wave | Healing Wave | Healing Wave |
| Z | Mana Potion | Mana Potion | Mana Potion | Mana Potion | Mana Potion |
| X | Lightning Shield | Water Shield | Water Shield | Water Shield | Water Shield |
| C | – | Ghost Wolf | Ghost Wolf | Ghost Wolf | Ghost Wolf |
| Shift+1 | – | – | Poison Cleansing | Poison Cleansing | Poison Cleansing |
| Shift+2 | – | – | – | Disease Cleansing | Disease Cleansing |
| Shift+3 | – | Healing Stream | Healing Stream | Healing Stream | Healing Stream |
| Shift+4 | – | – | Mana Spring | Mana Spring | Mana Spring |
| Shift+5 | Earthbind | Earthbind | Earthbind | Earthbind | Earthbind |
| Shift+Q | – | – | Totemic Call | Totemic Call | Totemic Call |
| Shift+E | Stoneskin | Stoneskin | Stoneskin | Stoneskin | Stoneskin |
| Shift+R | Searing | Searing | Searing | Searing | Searing |
| Shift+F | – | Tremor | Tremor | Tremor | Tremor |
| Shift+Z | – | – | Mana Tide | Mana Tide | Mana Tide |
| Shift+X | – | – | Grounding | Grounding | Grounding |
| Shift+C | – | Call of the Elements | Call of the Elements | Call of the Elements | Call of the Elements |
| Ctrl+Q | – | Frost Shock | Frost Shock | Frost Shock | Frost Shock |
| Ctrl+E | Stoneclaw | Stoneclaw | Stoneclaw | Stoneclaw | Stoneclaw |
| Ctrl+R | – | – | – | Chain Lightning | Chain Lightning |
| Ctrl+C | – | Totemic Recall | Totemic Recall | Totemic Recall | Totemic Recall |
| Ctrl+Z | Healthstone / Healing Potion | same | same | same | same |
| Mouse4 | – | – | NS + Healing Wave | NS + Healing Wave | NS + Healing Wave |
| Mouse5 | – | – | – | Riptide | Riptide |
| Keys in use | 11 | 20 | 27 | 31 | 31 |

Notes:
- Minor Healing Potion has no required level, and Minor Mana Potion needs level 5 (`Data/Items.lua`).
- Before a potion is in the bags, the macro shows its fallback icon.
- At 10 the unkeyed buttons are Rockbiter, Flametongue Weapon and Strength of Earth. Grace of Air (42) is the
  last unkeyed spell.

## Pushback on the current layout (v2, Erika's wishes)

**Keep (her ideas are good):**
- Healing Wave on F; Chain Heal on R.
- All totems on Shift.
- Her pull totems on Shift+E (Stoneskin), Shift+R (Searing) and Shift+F (Tremor).
- Mana Potion on Z.
- Call of the Elements stays on Shift+C. The player's example ("Call of the Elements is on C") refers to this
  key. It is a 3 s set-up cast used once per dungeon or wipe, not per pull, so a stretch key is right for it.
  What was wrong was that **Totemic Call** and **Totemic Recall** had no key. They now get Shift+Q (every pull)
  and Ctrl+C.

**Change:**
1. **Shields on 1 and 2 → one shield key on X.**
   - The two shields don't stack, last 10 minutes and are refreshed between pulls.
   - Lightning Shield is not used after 20.
   - Two easy number keys are wasted on them. 1 and 2 now hold the cures, the reactive party spells.
2. **Lesser Healing Wave C → E.**
   - It is the "heal now" spell, so it should be on the easiest top key, not a stretch key.
   - E was Riptide, which moves to the thumb.
3. **Riptide E → Mouse5; Nature's Swiftness X → Mouse4 (one-press NS + Healing Wave).**
   - Instant heals belong on the thumb buttons: the cursor is already on the party frame you heal, and the WASD
     hand keeps moving.
   - A separate NS key needs two presses in an emergency.
4. **Earth Shock 5 → Q, as an interrupt macro with `/stopcasting`.**
   - Interrupting is time-critical, and 5 is the hardest number to reach.
   - Chain Lightning (a 2.5 s cast, rare for a healer) leaves Q for Ctrl+R.
5. **Cures and Purge Shift+1/2/3 → 1, 2, 5.**
   - They are reactions on party frames (mouseover), so they should not need a modifier.
6. **Totem-only Shift bar.** Frost Shock leaves Shift+4 for Ctrl+Q. The Shift bar now holds only totems and the
   totem calls, so "Shift = totem" has no exceptions.

**Caveat:** R and Mouse5 stay empty until 40, by design: keys must not move once a spell is learned.

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

新しいキー配置の案。ダンジョンで回復することを一番に考えた。

| キー | 中身 |
|---|---|
| F | Healing Wave |
| E | Lesser Healing Wave |
| R | Chain Heal（レベル40から） |
| マウスのボタン4 | Nature's Swiftness ＋ Healing Wave（1回押すだけ） |
| マウスのボタン5 | Riptide（レベル40から） |
| 1・2 | Cure Poison・Cure Disease |
| 3・4・5 | Lightning Bolt・Flame Shock・Purge |
| Q | Earth Shock（敵の詠唱を中断する） |
| X | シールド（レベル20からWater Shield） |
| Z | Mana Potion |
| C | Ghost Wolf |
| Shift+E・Shift+R・Shift+F | Stoneskin Totem・Searing Totem・Tremor Totem（今まで通り） |
| Shift+Q | Totemic Call |
| Shift+C | Call of the Elements（今まで通り） |
| Shift+1・Shift+2 | Poison Cleansing Totem・Disease Cleansing Totem |
| Shift+3・Shift+4 | Healing Stream Totem・Mana Spring Totem |
| Shift+5 | Earthbind Totem |
| Shift+Z・Shift+X | Mana Tide Totem・Grounding Totem |
| Ctrl+Q・Ctrl+E・Ctrl+R | Frost Shock・Stoneclaw Totem・Chain Lightning |
| Ctrl+C | Totemic Recall |
| Ctrl+Z | Healthstone（なければHealing Potion） |

主な理由:
- **回復はF・E・R・マウスのサイドボタンに置いた。** サイドボタンは、パーティーの枠にカーソルを置いたまま親指で押せる。歩きながらでも使えるので、すぐに使う回復に一番向いている。
- **Lesser Healing WaveをCからEに移した。** 急いで回復したい時に使う呪文なので、押しやすいキーがいい。
- **シールドは1つのキー（X）にまとめた。** Water ShieldとLightning Shieldは同時に使えないし、どちらも10分続く。2つのキーを使うのはもったいない。レベル20からXはWater Shieldになる。
- **Nature's Swiftnessはマウスのボタン4に移した。** 1回押すだけでNature's SwiftnessとHealing Waveを続けて使う、緊急用のマクロにする。
- **Earth ShockをQに移した。** 敵の詠唱の中断は急ぐので、一番押しやすいキーに置いた。回復の詠唱中でも、止めてすぐに使える。
- **トーテムは今まで通りShiftにまとめた。** 毎回置くStoneskin Totem・Searing Totem・Tremor Totemのキーは変わらない。
- **Totemic CallをShift+Qに置いた。** 今出しているトーテムを自分の場所に移す呪文で、クールダウンは30秒。次の敵の所に進むたびに使おう。トーテムを全部置き直すより、マナも時間もかからない。Searing Totemは30秒で消えるので、毎回置き直そう。
- **Call of the ElementsはShift+Cのまま。** 3秒の詠唱で最大4つのトーテムを一度に置く。ダンジョンの最初と全滅の後に1回使えば十分。
- **Totemic RecallはCtrl+C（Call of the Elementsの下）。** ダンジョンを出る時にトーテムを消して、マナを少し取り戻す。
- **同じ列には同じ種類を置いた。** 1の列は毒、2の列は病気、Zの列はポーションなどのアイテム、Xの列は守り。
- **Ctrlのキーはあまり使わない呪文用。**
- **Rとマウスのボタン5はレベル40まで空いている。** Chain HealとRiptideを覚えたらそこに置く。一度置いたキーは後で変わらない。
- **めったに使わない呪文はキーなしでクリック用のバーに置く。** Ancestral Spirit・Astral Recall・Water Walkingなど。
