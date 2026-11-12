# Keybind layout v4 research: family blocks (proposal, both packs)

Status: **proposal for approval**. Nothing here is built. Once Oskar approves the two grids, a build task turns them
into Restoration layout 7 (`ForeverSensei_Shaman`) and Protection layout 2 (`ForeverSensei_Paladin`).

This doc replaces the *placement method* of `research/keybind-layout.md` (shaman, layouts 3-6) and
`research/keybind-layout-paladin.md` (paladin, layout 1). The spell facts, frequencies and pull walkthroughs in
those docs still hold and are cited below, not repeated.

## Why a v4

Oskar, verbatim: "One thing I don't like is that some active skills that are used in combat end up on action bar 4
and 5 which sit on the right side of the screen. I think it is actually better that we use action bar 6-8 if
necessary. They can be moved to a nice position close to the bottom action bars easily anyway. One more thing I
don't like is the feeling of chaos in the placement of skills and bindings. On paladin for example all of the seals
are in different places. I understand that they are prioritised based on usage but I still think it's important
that they stay close together to make sense even though it might be suboptimal placement based on usage and
reaction time assessment. For example having the paladin seals on shift-1 shift-2 shift-3 shift-4 for example feels
pretty logical to me even though some of them aren't used very much when tanking. Might be similar issues on the
shaman side as well"

## The rules (Oskar's decisions)

1. **Block rule.** Each modifier row (Shift, Ctrl) splits into three blocks of neighbouring keys: **1-5**,
   **Q/E/R/F** and **Z/X/C**.
   - A whole family fills one block; a block holds one family or part of one. Unused keys in a block stay spare
     (bound, empty).
   - The **plain row stays the core rotation**: usage decides what goes there. It is still arranged in the same three
     blocks where that costs nothing.
   - **Button n on a bar is key n**, so a family also sits together on screen.
   - **Families beat frequency and urgency.** Frequency only picks the row and block of a family and the order inside
     the block.
   - A family bigger than its block spills over to neighbouring **click** buttons on Action Bar 6, never to a random
     key.
2. **Key 5 is no longer reserved** (5, Shift+5, Ctrl+5 are planned like any other key). Oskar: "Any user can move
   stuff around as they wish anyway."
3. **Bars.**
   - plain = Action Bar 1, Shift = Action Bar 2, Ctrl = **Action Bar 3**. All three sit at the bottom by default.
   - The mouse buttons (Mouse4/5, plain, Shift, Ctrl) and the click-only spells used **in combat** = **Action Bar 6**.
     Bars 7 and 8 only if bar 6 runs out of room (it doesn't, see below).
   - **Action Bars 4 and 5** (right edge) hold only **out-of-combat** utility: resurrection, Hearthstone or Astral
     Recall, long buffs, travel.
4. Habit keys may move. Oskar: "Everything is okay to move no need to worry about habits."
5. Allowed keys and modifiers are unchanged: 1-5, Q, E, R, F, Z, X, C and Mouse4/5; plain, Shift or Ctrl.

Shared by both grids (my own choices, within the rules):
- The mouse block counts as three pairs (plain, Shift, Ctrl), the same way the keyboard rows do. A pair holds one
  family, or one family runs down the Mouse4 and the Mouse5 column. Whichever fits the pack keeps its family together
  on bar 6 (the button order is per pack, see each bar 6 table).
- Mouseover macros, the self-fallback rule, `FS_NSHW`, `FS_ES`, `FS_HOJ`, `FS_OPEN`, `FS_HEALTH` and `FS_MANA` are
  unchanged. Only their buttons move.
- Spells learned later keep their slot empty until learned; keys never move between levels.

## Sources

Checked on **2026-11-12** unless noted. Same keys as the two existing docs.

| Key | Source | Used for |
|---|---|---|
| `ui` | Forever UI code, [reckhou/WoWBlzCode](https://github.com/reckhou/WoWBlzCode) @ `7245053`, folder `Forever/BlizzardInterfaceCode/Interface/AddOns` (sparse clone, read 2026-11-12) | bar pages and slots, binding names, default bar positions, the stance bar, the action button "checked" state |
| `simc` | `research/shaman_simc_1.60.1.70862.tsv`, `research/paladin_simc_1.60.1.70862.tsv` | levels, cooldowns, durations (all cited through the two docs' tables) |
| `wh_tt` | Wowhead Forever tooltips (`nether.wowhead.com/forever/tooltip/spell/<id>`) | effects (Fire Nova, Forbearance, Judgement) |
| `moba`, `wh_abil`, `wh_guide` | the guides listed in the two docs | how each spell is used; default aura and blessing |
| `shaman doc` | `research/keybind-layout.md`: Q1 table, totem durations, pull walkthroughs, reach table for small hands | Erika's frequencies and reach tiers |
| `paladin doc` | `research/keybind-layout-paladin.md`: frequency × urgency table, reach table for normal hands, Forever differences | Oskar's frequencies and reach tiers |

### Bars 6-8 (`ui`, verified)

| Bar (UI name) | Frame | Binding names | `actionpage` | Action slots | Shown by | Default position |
|---|---|---|---|---|---|---|
| Action Bar 1 | MainActionBar | `ACTIONBUTTON1-12` | 1 | 1-12 | always | bottom centre |
| Action Bar 2 | MultiBarBottomLeft | `MULTIACTIONBAR1BUTTON1-12` | 6 | 61-72 | `PROXY_SHOW_ACTIONBAR_2` | bottom, stacked above bar 1 |
| Action Bar 3 | MultiBarBottomRight | `MULTIACTIONBAR2BUTTON1-12` | 5 | 49-60 | `PROXY_SHOW_ACTIONBAR_3` | bottom, stacked |
| Action Bar 4 | MultiBarRight | `MULTIACTIONBAR3BUTTON1-12` | 3 | 25-36 | `PROXY_SHOW_ACTIONBAR_4` | right edge, vertical |
| Action Bar 5 | MultiBarLeft | `MULTIACTIONBAR4BUTTON1-12` | 4 | 37-48 | `PROXY_SHOW_ACTIONBAR_5` | right edge, vertical |
| **Action Bar 6** | MultiBar5 | `MULTIACTIONBAR5BUTTON1-12` | **13** | **145-156** | `PROXY_SHOW_ACTIONBAR_6` | TOP of the bar at the screen CENTER, y 0 |
| Action Bar 7 | MultiBar6 | `MULTIACTIONBAR6BUTTON1-12` | **14** | **157-168** | `PROXY_SHOW_ACTIONBAR_7` | CENTER, y −50 |
| Action Bar 8 | MultiBar7 | `MULTIACTIONBAR7BUTTON1-12` | **15** | **169-180** | `PROXY_SHOW_ACTIONBAR_8` | CENTER, y −100 |

Evidence:
- Pages: `Blizzard_ActionBar/Shared/MultiActionBars.lua` lines 1-8 (`MULTIBAR_5/6/7_ACTIONBAR_PAGE = 13/14/15`) and the
  `actionpage` attributes in `MultiActionBars.xml` (lines 179, 208, 237). Slot = (page − 1) × 12 + button, so the
  coordinator's ranges **145-156, 157-168 and 169-180 are confirmed**.
- Bindings: `Blizzard_FrameXML/Bindings_Camelot.xml` line 733 (`MULTIACTIONBAR5BUTTON1`, header `ACTIONBAR6`) to line
  980 (`MULTIACTIONBAR7BUTTON12`, header `ACTIONBAR8`).
- Visibility: `MultiActionBars.lua` lines 17-33 map bars 6/7/8 to `PROXY_SHOW_ACTIONBAR_6/7/8`; the frames are
  `hidden="true"` until then.
- Positions: `Blizzard_EditMode/Mainline/EditModePresetLayouts.lua` lines 121-176 (`ExtraBar1-3`, point TOP,
  relativePoint CENTER, y 0/−50/−100); bars 2 and 3 anchor BOTTOM, with their offsets set by
  `UpdateBottomActionBarPositions` (`Blizzard_EditMode/Camelot/EditModePresetLayoutConstants.lua` lines 15-22,
  `Blizzard_EditMode/Shared/EditModeManager.lua` line 71).
- So bar 6 starts **just below the middle of the screen, over the character**: the reason layout 3 (0.4.0) was
  dropped (`Layout.lua` header). The addon still doesn't move bars. The guide's key page and the one-time layout notice tell the player to
  open Edit Mode and drag Action Bar 6 down next to the bottom bars (Oskar: "They can be moved to a nice position
  close to the bottom action bars easily anyway").
- Neither layout needs bar 7 or 8 (bar 6 has room, see below), so they stay off.

---

# Part 1: Restoration Shaman (Erika, small hands)

Reach tiers are from the shaman doc (small hands, WASD): tier 1 Mouse4/5, Q, E, R, F; tier 2 1-3, Shift+Q/E/R/F,
Shift+Mouse; tier 3 4, Z, Shift+1-3, Ctrl+Q/E/R, Ctrl+Mouse; tier 4 X, C, 5, Shift+Z/X/C, Shift+4, Ctrl+Z/C/F;
tier 5 Shift+5, Ctrl+X, Ctrl+1-5.

## S1. Families

| Family | Members *(level)* | Size |
|---|---|---|
| Heals (plain, core) | Healing Wave *(1)*, Lesser Healing Wave *(20)*, Chain Heal *(40)* | 3 |
| Enemy spells (plain, core) | Flame Shock *(10)*, Lightning Bolt *(1)*, Chain Lightning *(32)*, Purge *(12)*, Frost Shock *(20)*; Earth Shock *(4)* is the interrupt | 6 |
| Consumables and shield (plain, core) | Mana Potion, Water Shield *(20)* / Lightning Shield *(8)*, Healthstone else Healing Potion | 3 |
| **Totem calls** | Totemic Call *(22)*, Call of the Elements *(20)*, Call of the Ancestors *(30)*, Call of the Spirits *(40)*, Totemic Recall *(20)* | 5 |
| **Fire** | Searing Totem *(10)*, Magma Totem *(26)*, Fire Nova *(12)*, Flametongue Totem *(28)*; (Frost Resistance Totem: Totem Bar) | 4 |
| **Earth** | Earthbind *(6)*, Stoneclaw *(8)*, Stoneskin *(4)*, Tremor *(18)*; Strength of Earth *(10)* | 5 |
| **Water (mana)** | Mana Spring *(26)*, Mana Tide *(25)*, Healing Stream *(20)*; (Fire Resistance Totem: Totem Bar) | 3 |
| **Air** | Grounding *(30)*, Windfury Totem *(32)*, Grace of Air *(42)*; (Windwall, Nature Resistance: Totem Bar; Sentry: spellbook) | 3 |
| **Travel** | Ghost Wolf *(20)*, Water Walking *(28)*, Water Breathing *(22)* | 3 |
| **Cursor heals** (mouse) | Riptide *(40)*, Nature's Swiftness + Healing Wave *(30)* | 2 |
| **Cures** (mouse) | Cure Poison *(16)*, Cure Disease *(22)* | 2 |
| **Cleansing totems** (mouse) | Poison Cleansing Totem *(22)*, Disease Cleansing Totem *(38)* | 2 |

Totems are grouped **by element**: the Totem Bar, Call of the Elements and the "one totem per element" rule (`wh_tt`
"Tools:" line, shaman doc Q2) all think in elements, so "which element?" is the question Erika already asks. Two
exceptions, by purpose:
- The **cleansing totems** (Water) stay with the cures on the mouse: "cure the poison/disease" is one decision,
  totem or spell. They were already there (Ctrl+Mouse4/5) and the pair keeps the poison/disease columns.
- **Fire Nova** is not a totem, but it only hits enemies near the active Fire totem (`simc` 408341, `wh_tt`), so it is
  part of Fire (Erika's 0.6.1 request).

## S2. Blocks and why

| Block | Family | Why this block |
|---|---|---|
| Plain 1-5 | Enemy spells, left to right: Flame Shock, Lightning Bolt, Chain Lightning, Purge, Frost Shock | The damage row she already presses left to right (DoT → bolt → chain), moved one key left because 1 is no longer Totemic Call. Purge and Frost Shock (rare) fill 4 and 5, the worst plain digits. |
| Plain Q/E/R/F | Q Earth Shock (interrupt) + E/R/F heals | Unchanged. The interrupt and the three heals are the most urgent presses (tier 1). The plain row is usage-driven, so the interrupt stays on Q instead of joining the damage block. |
| Plain Z/X/C | Mana Potion, Water Shield, Healthstone | Unchanged. |
| **Shift 1-5** | **Totem calls**: 1 Totemic Call, 2 Call of the Elements, 3 Call of the Ancestors, 4 Call of the Spirits, 5 Totemic Recall | Exactly five members, in the order of a dungeon: move the set, place set 1/2/3, take them away. Totemic Call is pressed every pull, so it gets Shift+1 (the easiest key of the block). |
| **Shift Q/E/R/F** | **Fire**: Q Flametongue Totem, E Magma, R Searing, F Fire Nova | The most frequent element (Searing every pull, Magma/Fire Nova on packs) gets the easiest modifier block (tier 2). Searing keeps Shift+R; its two pack spells sit on either side, Fire Nova right after Searing. Flametongue (rare) takes the end. |
| **Shift Z/X/C** | **Water**: Z Mana Spring, X Mana Tide, C Healing Stream | Mana family on Z (Mana Potion is plain Z). Mana Spring keeps Shift+Z; Mana Tide is the reaction after it. |
| **Ctrl 1-5** | **Travel**: 1 Ghost Wolf, 2 Water Walking, 3 Water Breathing; 4, 5 spare | Ctrl+digits are tier 5 ("avoid in combat"), so the out-of-combat family takes them. Brings Water Walking/Breathing back from the spellbook. |
| **Ctrl Q/E/R/F** | **Earth**: Q Earthbind, E Stoneclaw, R Stoneskin, F Tremor | Second most frequent element. Earthbind and Stoneclaw keep their keys; Stoneskin sits next to Tremor because Tremor replaces it (same element). Strength of Earth spills to bar 6. |
| **Ctrl Z/X/C** | **Air**: Z Grounding, X Windfury Totem, C Grace of Air | Grounding is the only reaction: Ctrl+Z (tier 4, the same tier as its old Ctrl+F). Windfury and Grace of Air become keys (were clicked). |
| Mouse plain pair | **Cursor heals**: Mouse4 Riptide, Mouse5 NS + Healing Wave | Unchanged. |
| Mouse Shift pair | **Cures**: Cure Poison, Cure Disease | Unchanged. |
| Mouse Ctrl pair | **Cleansing totems**: Poison, Disease | Unchanged. |

Runner-up (close): **Earth on Shift Q/E/R/F and Fire on Ctrl Q/E/R/F.** Tremor would keep Shift+F (tier 2) and
Stoneskin Shift+E, but Searing (every pull) would go to Ctrl+R (tier 3) and Fire Nova to Ctrl+F (tier 4). Fire is
pressed more often, and the rule is "frequency picks the block", so Fire wins Shift.

## S3. Grid (Restoration layout 7)

**MO** = mouseover macro, *(lvl)* = learned at, "–" = spare (bound, empty). Bar n button k = key k of that row.

| Key | Plain (Action Bar 1) | Shift (Action Bar 2) | Ctrl (Action Bar 3) |
|---|---|---|---|
| 1 | Flame Shock *(10)* | Totemic Call *(22)* | Ghost Wolf *(20)* |
| 2 | Lightning Bolt *(1)* | Call of the Elements *(20)* | Water Walking *(28)* |
| 3 | Chain Lightning *(32)* | Call of the Ancestors *(30)* | Water Breathing *(22)* |
| 4 | Purge, MO harm *(12)* | Call of the Spirits *(40)* | – |
| 5 | Frost Shock *(20)* | Totemic Recall *(20)* | – |
| Q | Earth Shock, `/stopcasting` + MO harm *(4)* | Flametongue Totem *(28)* | Earthbind Totem *(6)* |
| E | Lesser Healing Wave, MO *(20)* | Magma Totem *(26)* | Stoneclaw Totem *(8)* |
| R | Chain Heal, MO *(40)* | Searing Totem *(10)* | Stoneskin Totem *(4)* |
| F | Healing Wave, MO *(1)* | Fire Nova *(12)* | Tremor Totem *(18)* |
| Z | Mana Potion (`FS_MANA`) | Mana Spring Totem *(26)* | Grounding Totem *(30)* |
| X | Water Shield *(20)*; Lightning Shield *(8)* until then | Mana Tide Totem *(25)* | Windfury Totem *(32)* |
| C | Healthstone, else Healing Potion (`FS_HEALTH`) | Healing Stream Totem *(20)* | Grace of Air Totem *(42)* |
| Mouse4 | Riptide, MO *(40)* | Cure Poison, MO *(16)* | Poison Cleansing Totem *(22)* |
| Mouse5 | NS + Healing Wave, MO *(30)* | Cure Disease, MO *(22)* | Disease Cleansing Totem *(38)* |

Spare keys: Ctrl+4, Ctrl+5. 40 of 42 keys hold a spell at 60.

## S4. Action Bar 6 (mouse block + in-combat clicks)

Button order keeps each mouse pair together (the families are the pairs):

| Button | Key | Content |
|---|---|---|
| 1 | Mouse4 | Riptide |
| 2 | Mouse5 | NS + Healing Wave |
| 3 | Shift+Mouse4 | Cure Poison |
| 4 | Shift+Mouse5 | Cure Disease |
| 5 | Ctrl+Mouse4 | Poison Cleansing Totem |
| 6 | Ctrl+Mouse5 | Disease Cleansing Totem |
| 7 | – | Strength of Earth Totem (Earth spill-over; Ctrl+Q/E/R/F is full) |
| 8 | – | Healing Potion (`@healpot`, for when the Healthstone is on cooldown) |
| 9-12 | – | spare |

## S5. Action Bars 4 and 5 (out of combat, clicked)

| Bar 4 button | Content |
|---|---|
| 1 | Ancestral Spirit (resurrection) |
| 2 | Astral Recall |
| 3-6 | Rockbiter, Flametongue, Frostbrand (back from the spellbook), Windfury Weapon |
| 7 | Lightning Shield (after Water Shield at 20) |
| 8 | Elixir (`@elixir`) |
| 9-12 | spare |

Action Bar 5 is not used by the shaman any more (it was the Ctrl bar). A full apply clears what layout 6 put there.
No slot: Far Sight and Sentry Totem (spellbook, scouting), the resistance totems and Windwall (Totem Bar),
Reincarnation (passive).

## S6. What changes from layout 6 (0.6.1)

Same key: Earth Shock Q, the three heals E/R/F, Mana Potion Z, Water Shield X, Healthstone C, Searing Shift+R, Mana
Spring Shift+Z, Earthbind Ctrl+Q, Stoneclaw Ctrl+E, all six mouse spells.

| Spell | Layout 6 → 7 | Reach (small hands) |
|---|---|---|
| Totemic Call | 1 → Shift+1 | 2 → 3 (worse) |
| Call of the Elements | Shift+1 → Shift+2 | 3 → 3 |
| Totemic Recall | Ctrl+1 → Shift+5 | 5 → 5 |
| Call of the Ancestors, Call of the Spirits | bar 4 (clicked) → Shift+3, Shift+4 | new keys |
| Flame Shock / Lightning Bolt / Chain Lightning | 2 / 3 / 4 → 1 / 2 / 3 | each one key left, same or better |
| Purge | Shift+3 → 4 | 3 → 3 |
| Frost Shock | Shift+Q → 5 | 2 → 4 (worse; rare) |
| Magma Totem | Shift+4 → Shift+E | 4 → 2 (better) |
| Fire Nova | Ctrl+R → Shift+F | 3 → 2 (better) |
| Flametongue Totem | bar 4 (clicked) → Shift+Q | new key |
| Stoneskin Totem | Shift+E → Ctrl+R | 2 → 3 (worse) |
| Tremor Totem | Shift+F → Ctrl+F | 2 → 4 (**worse, a reaction**) |
| Strength of Earth | bar 4 → bar 6 button 7 | clicked either way |
| Grounding Totem | Ctrl+F → Ctrl+Z | 4 → 4 |
| Mana Tide Totem | Ctrl+Z → Shift+X | 4 → 4 |
| Healing Stream, Windfury Totem, Grace of Air | bar 4 (clicked) → Shift+C, Ctrl+X, Ctrl+C | new keys |
| Ghost Wolf | Ctrl+C → Ctrl+1 | 4 → 5 (out of combat) |
| Water Walking, Water Breathing | spellbook → Ctrl+2, Ctrl+3 | new keys |
| Mouse spells | Action Bar 3 buttons 7-12 → Action Bar 6 buttons 1-6 | keys unchanged |
| Imbues, Lightning Shield, elixir | Action Bar 3 buttons 1-5 → Action Bar 4 | clicked |
| Frostbrand Weapon | spellbook → bar 4 | clicked |
| Her own 5 / Shift+5 / Ctrl+5 | "#" → Frost Shock / Totemic Recall / spare | rule 2 |

## S7. Trade-offs (urgent spells that got a worse key)

1. **Tremor Totem: Shift+F → Ctrl+F (tier 2 → 4).** The biggest cost. Tremor is usually put down *before* the fear
   (fear fights are known), so the stretch is acceptable; the runner-up in S2 avoids it at the cost of Searing.
2. **Totemic Call: 1 → Shift+1 (tier 2 → 3)**, pressed every pull. It is planned (after positioning), not a
   reaction, and the block puts every totem call in one place.
3. **Stoneskin: Shift+E → Ctrl+R (tier 2 → 3).** Re-placed after Tremor, between pulls more often than in one.
4. **Frost Shock: Shift+Q → plain 5 (tier 2 → 4).** Rare (a runner).
5. Her old own keys: whatever Erika put on 5 or Shift+5 is moved to a spare button by a full apply (the existing
   "non-plan things go to spare buttons" rule), and the preview lists it. Nothing moves without すべて配置.

---

# Part 2: Protection Paladin (Oskar, normal hands)

Reach tiers are from the paladin doc (normal hands, WASD): tier 1 1-3, Q, E, R, F, Mouse4/5; tier 2 4, Z, X, C,
Shift+1-3, Shift+Q/E/R/F, Shift+Mouse; tier 3 Shift+4, Shift+Z/X/C, Ctrl+Q/E/R/F, Ctrl+Z/X/C, Ctrl+Mouse; tier 4
Ctrl+1-4. Now that 5 is planned: 5 is tier 2 (like 4), Shift+5 tier 3, Ctrl+5 tier 4.

## P1. Families

| Family | Members *(level)* | Size |
|---|---|---|
| Core loop (plain) | Holy Strike *(6)*, Consecration *(20)*, Holy Shield *(42, talent)* | 3 |
| Heals (plain) | Flash of Light *(20)*, Holy Light *(1)* | 2 |
| **Judgement** (plain) | Judgement *(4)*, Swift Judgement *(37, talent)*, opener macro *(37)* | 3 |
| Stun (plain) | Hammer of Justice *(8)*: the interrupt substitute | 1 |
| Potions and threat buff (plain) | Healthstone else Healing Potion, Mana Potion, Righteous Fury *(10)* | 3 |
| **Seals** | Fury *(10)*, Righteousness *(1)*, Crusader *(6)*, Wisdom *(38)*, Light *(30)*; Justice *(22)* | 6 |
| **Auras** | Retribution *(16)*, Devotion *(1)*, Concentration *(22)*, Shadow Res. *(28)*, Frost Res. *(32)*; Fire Res. *(36)* | 6 |
| **Conditional attacks** | Exorcism *(20)*, Hammer of Wrath *(44)*, Holy Wrath *(50)*, Turn Undead *(24)* | 4 |
| **Forbearance** | Templar's Bulwark *(32, talent)*, Divine Shield *(34)*, Divine Protection *(6)* | 3 |
| **Blessings** | Kings *(20)*, Might *(4)*, Wisdom *(14)*; the Greater Blessings *(52-60)* are 1 h out-of-combat buffs (bar 4) | 3 |
| **Save a party member** (Ctrl+Q/E/R since 0.8.0; Mouse4 before) | Lay on Hands *(10)*, Blessing of Protection *(10)*, Blessing of Sacrifice *(46)* | 3 |
| **Cleanse and free** (mouse buttons since 0.8.0; Mouse5 before) | Cleanse *(42)* / Purify *(8)*, Blessing of Freedom *(18)*, Voice of Truth *(20)* | 3 |

"Conditional attacks": each only works under one condition (Exorcism and Holy Wrath against undead or demons, Turn
Undead against undead, Hammer of Wrath on a target under 20%; `wh_tt`, paladin doc). It replaces the old "against undead" family and
pulls Hammer of Wrath in, so the hammers no longer need their own base key.

Seal of Command is a Retribution talent and stays out (`wh_tt` 20375 "Talent"). Blessing of Salvation, Sanctuary,
Light and Hammer of the Righteous stay out of every key and text (unverified, paladin doc).

## P2. Blocks and why

| Block | Family | Why this block |
|---|---|---|
| Plain 1-5 | 1 Holy Strike, 2 Consecration, 3 Holy Shield, 4 Flash of Light, 5 Holy Light | The core loop on the three easiest digits (unchanged); the heal pair fills 4 and 5. |
| Plain Q/E/R/F | Q Judgement, E Swift Judgement, R opener, F Hammer of Justice | The Judgement family together under 1-3 (Judgement is pressed with Holy Strike); the opener becomes a tier-1 key. Hammer of Justice, the only "stop that cast", keeps a tier-1 key. |
| Plain Z/X/C | Z Healthstone, X Mana Potion, C Righteous Fury | Both potions side by side (the mana potion was Shift+Z). Righteous Fury must never be missing (Iron Creed needs it), so it keeps a plain key. |
| **Shift 1-5** | **Seals**: 1 Fury, 2 Righteousness, 3 Crusader, 4 Justice, 5 Wisdom | Oskar's own example and order. Seal of Light spills to bar 6. *(0.7.1, at Oskar's request: was 4 Wisdom, 5 Light with Justice spilled; see "Changed in 0.7.1" below P7.)* |
| **Shift Q/E/R/F** | **Conditional attacks**: Q Exorcism, E Hammer of Wrath, R Holy Wrath, F Turn Undead | Order by frequency (Exorcism is a rotation spell on undead). Hammer of Wrath and Holy Wrath keep Shift+E and Shift+R. |
| **Shift Z/X/C** | **Forbearance**: Z Templar's Bulwark, X Divine Shield, C Divine Protection | The key teaches "one of these per minute". Same order as before (keep tanking → halve damage → stop attacking). |
| **Ctrl 1-5** | **Auras**: 1 Retribution, 2 Devotion, 3 Concentration, 4 Shadow Resistance, 5 Frost Resistance | See P3. Retribution first: the default aura in `wh_guide` and `moba`. Fire Resistance Aura spills to bar 6. |
| **Ctrl Q/E/R/F** | **Save** (0.8.0): Q Lay on Hands, E Blessing of Protection, R Blessing of Sacrifice; F spare | Long cooldowns that hurt when pressed by mistake, so on deliberate keys, not the mouse buttons (see "Changed in 0.8.0"). Spare until 0.7.1. |
| **Ctrl Z/X/C** | **Blessings**: Z Kings, X Might, C Wisdom | Out of combat, so the Ctrl block. Kings first (the default; re-apply after Protection/Freedom/Sacrifice replaced it). |
| Mouse pairs | **Cleanse and free** (0.8.0): Mouse4 Cleanse (Purify until 42), Mouse5 Blessing of Freedom, Shift+Mouse4 Voice of Truth; Shift+Mouse5 and Ctrl+Mouse4/5 spare | Only low-risk spells on the buttons that are easy to press by mistake. Until 0.7.1 the columns were Mouse4 "save" and Mouse5 "free". |

## P3. Auras: stance-bar defaults or Action Bar 3? (decided with evidence)

The question: do Ctrl+1-5 keep the game's stance-bar bindings (`SHAPESHIFTBUTTON1-5`), as layout 1 did for Ctrl+1-4,
or move to Action Bar 3 buttons 1-5 with the auras placed there?

Facts:
- All six auras carry "Use Shapeshift Bar" (`simc`) and show on the stance bar (`ui` `StanceBar.lua`, header
  "StanceBar (Shapsfit,Auras,Aspects)").
- The stance bar fills its buttons from `GetShapeshiftFormInfo(i)` for `i = 1..GetNumShapeshiftForms()`
  (`StanceBar.lua` lines 62-87). The order comes from the client, not from Lua, so **it can't be verified offline**,
  and it depends on which auras are trained. `wh_guide` calls the resistance auras **optional**: if Oskar skips Shadow
  Resistance (28), Frost moves to stance button 4 and Ctrl+4 changes meaning. That breaks "keys never move".
- An action button shows "checked" when `C_ActionBar.IsCurrentAction(action)` is true (`ActionButton.lua` line 717).
  For a stance-type spell this is the active-form check (as for warrior stances), so the active aura should light up
  on Action Bar 3 as well. **Verify in game.**
- The default key of each stance button is not in the client files (shaman doc Q4); Ctrl+1-0 is expected.
- The shaman layout has bound Ctrl+1-4 to an action bar since 0.4.3, and the preview's stance warning
  (`ui.preview.warn.stance`) already exists.

Layout 1's reasons for the stance bar, weighed again:

| Layout 1 reason | Still true in v4? |
|---|---|
| Zero bindings replaced | True, but the same preview warning already covers it for the shaman. |
| The stance bar highlights the active aura | The action button should too (above); the stance bar still shows it anyway. |
| Six auras don't fit in four keys | v4 has five keys (Ctrl+5 is planned now) plus a bar 6 click for the sixth. |
| Auras are switched between pulls; Ctrl+digits are tier 4 | Still true either way; the block rule puts them on Ctrl+1-5 in both options. |

**Decision: move them to Action Bar 3 buttons 1-5, bound to Ctrl+1-5.**
- Key n is always the same aura, whatever has been trained (the stance order is unverified and shifts).
- The Ctrl bar shows the Ctrl block on screen, button n = key n, like seals on bar 2. With the stance bar, Action Bar
  3 buttons 1-5 would be unbound gaps and the block would live on a different bar: the "chaos" Oskar asked to remove.
- The core's paladin-only "keep the game default" rule (`L.keepDefault`, `ui.layout.stancekeys`) is no longer needed.
- The stance bar stays as the game shows it (all six auras); Oskar can hide it in Edit Mode.

Runner-up: keep Ctrl+1-5 on the stance bar (no new bindings). Pick it if the in-game check shows that auras cast
from an action button don't light up.

## P4. Grid (Protection layout 4 since 0.8.0; layout 3 in 0.7.1, layout 2 in 0.7.0)

| Key | Plain (Action Bar 1) | Shift (Action Bar 2) | Ctrl (Action Bar 3) |
|---|---|---|---|
| 1 | Holy Strike *(6)* | Seal of Fury *(10)* | Retribution Aura *(16)* |
| 2 | Consecration *(20)* | Seal of Righteousness *(1)* | Devotion Aura *(1)* |
| 3 | Holy Shield *(42, talent)* | Seal of the Crusader *(6)* | Concentration Aura *(22)* |
| 4 | Flash of Light, MO + self *(20)* | Seal of Justice *(22)* | Shadow Resistance Aura *(28)* |
| 5 | Holy Light, MO + self *(1)* | Seal of Wisdom *(38)* | Frost Resistance Aura *(32)* |
| Q | Judgement *(4)* | Exorcism *(20)* | Lay on Hands, MO + self *(10)* |
| E | Swift Judgement *(37, talent)* | Hammer of Wrath *(44)* | Blessing of Protection, MO + self *(10)* |
| R | Opener: Judgement + Swift Judgement + Holy Strike (`FS_OPEN`) *(37)* | Holy Wrath *(50)* | Blessing of Sacrifice, MO *(46)* |
| F | Hammer of Justice, `/stopcasting` + MO harm *(8)* | Turn Undead *(24)* | – |
| Z | Healthstone, else Healing Potion (`FS_HEALTH`) | Templar's Bulwark *(32, talent)* | Blessing of Kings *(20)* |
| X | Mana Potion (`FS_MANA`) | Divine Shield *(34)* | Blessing of Might *(4)* |
| C | Righteous Fury *(10)* | Divine Protection *(6)* | Blessing of Wisdom *(14)* |
| Mouse4 | Cleanse, MO + self *(42)*; Purify *(8)* until then | Voice of Truth *(20)* | – |
| Mouse5 | Blessing of Freedom, MO + self *(18)* | – | – |

Spare keys: Ctrl+F, Shift+Mouse5, Ctrl+Mouse4, Ctrl+Mouse5. 38 of 42 keys hold a spell at 60. Ctrl+R still
replaces the framerate toggle (the preview warns).

## P5. Action Bar 6 (mouse block + in-combat clicks)

Button order is in pairs since 0.8.0, as for the Shaman: the plain pair, the Shift pair, the Ctrl pair (until 0.7.1
it was the Mouse4 column, then the Mouse5 column).

| Button | Key | Content |
|---|---|---|
| 1 | Mouse4 | Cleanse (Purify until 42) |
| 2 | Mouse5 | Blessing of Freedom |
| 3 | Shift+Mouse4 | Voice of Truth |
| 4 | Shift+Mouse5 | spare |
| 5 | Ctrl+Mouse4 | spare |
| 6 | Ctrl+Mouse5 | spare |
| 7 | – | Seal of Light (seal spill-over; Seal of Justice until 0.7.1) |
| 8 | – | Fire Resistance Aura (aura spill-over) |
| 9 | – | Divine Intervention (a wipe tool, used in combat) |
| 10-12 | – | spare |

## P6. Action Bars 4 and 5 (out of combat, clicked)

| Bar 4 button | Content |
|---|---|
| 1 | Redemption (resurrection) |
| 2-4 | Greater Blessing of Kings *(60)*, Might *(52)*, Wisdom *(54)* |
| 5-12 | spare |

Action Bar 5 is no longer used (it was the Ctrl bar); a full apply clears what layout 1 put there. No slot: Purify
after 42 (Cleanse replaces it), the mounts (Summon Warhorse, Summon Charger: spellbook).

## P7. What changes from layout 1 (0.6.0)

Same key: Holy Strike 1, Consecration 2, Holy Shield 3, Flash of Light 4, Judgement Q, Healthstone Z, Hammer of
Wrath Shift+E, Holy Wrath Shift+R, all six mouse spells.

| Spell | Layout 1 → 2 | Reach (normal hands) |
|---|---|---|
| Seal of Fury | F → Shift+1 | 1 → 2 |
| Seal of Righteousness | Shift+F → Shift+2 | 2 → 2 |
| Seal of the Crusader | Ctrl+F → Shift+3 | 3 → 2 (better) |
| Seal of Wisdom, Seal of Light | bar 3 (clicked) → Shift+4, Shift+5 | new keys |
| Seal of Justice | bar 3 → bar 6 | clicked |
| Auras | stance bar, Ctrl+1-4 default → Action Bar 3 buttons 1-5, Ctrl+1-5 | 4 → 4; fixed order; Frost Resistance gets a key |
| Fire Resistance Aura | stance bar → bar 6 (and still the stance bar) | clicked |
| Holy Light | Shift+4 → 5 | 3 → 2 (better) |
| Swift Judgement | Shift+Q → E | 2 → 1 (better) |
| Opener | Ctrl+Q → R | 3 → 1 (better) |
| Hammer of Justice | E → F | 1 → 1 |
| Exorcism | R → Shift+Q | 1 → 2 (worse) |
| Turn Undead | Ctrl+R → Shift+F | 3 → 2 (better) |
| Mana Potion | Shift+Z → X | 3 → 2 (better) |
| Righteous Fury | X → C | 2 → 2 |
| Templar's Bulwark | C → Shift+Z | 2 → 3 (**worse, a reaction**) |
| Divine Shield | Shift+C → Shift+X | 3 → 3 |
| Divine Protection | Ctrl+C → Shift+C | 3 → 3 |
| Blessing of Kings | Shift+X → Ctrl+Z | 3 → 3 |
| Blessings of Might, Wisdom | bar 3 (clicked) → Ctrl+X, Ctrl+C | new keys |
| Redemption | Ctrl+X → bar 4 | key → clicked (out of combat, rule 3) |
| Greater Blessings, Divine Intervention | bar 4 → bar 4 / bar 6 | clicked |
| Mouse spells | Action Bar 3 buttons 7-12 → Action Bar 6 buttons 1-6 | keys unchanged |

### Changed in 0.7.1 (layout 3), at Oskar's request

Oskar, in game: "why isn't seal of justice on shift 4 next to the otehr seals?" and "My mouse over macros for lay
on hands and blessing of protection etc. aren't casting properly on my self if I am not mousing over any party
member". Decided by the coordinator while Oskar was away:

| Change | Layout 2 → 3 | Why |
|---|---|---|
| Seal of Justice *(22)* | bar 6 button 7 (clicked) → Shift+4 | Stops fleeing humanoids (Judgement: no fleeing for 10 s, `simc`/`wh_tt`), which would pull more enemies. |
| Seal of Wisdom *(38)* | Shift+4 → Shift+5 | Order by level inside the block after Fury/Righteousness/Crusader. |
| Seal of Light *(30)* | Shift+5 → bar 6 button 7 (clicked) | `moba`: it "isn't usually necessary" for a tank. |
| Blessing of Protection (Mouse4) | `help_nofb` → `help` macro, MO + self | Oskar wants the self fallback. On yourself it stops your attacks for 6 s and applies Forbearance (`simc` 1022, 25771), which blocks Templar's Bulwark, Divine Shield and Divine Protection for 1 min. Blessing of Sacrifice stays without (it moves the target's damage to the caster). |

The keys don't change, only the spells on Action Bar 2 buttons 4-5 and Action Bar 6 button 7, so a full apply
replaces exactly those three buttons (no `L.old` entry needed). One-time layout notice, nothing moves by itself,
元に戻す restores.

### Changed in 0.8.0 (layout 4), at Oskar's request

Oskar, in game: "Having expensive/high risk spells on the mouse buttons are a bit risky since it is easy to misclick
them I think lay on hands, blessing of protection that have long cooldowns and are also dangerous when used in the
wrong circumstances should probably be somewhere else. Also the non shift mouse button should be placed paired next
to each other and the shift modified mouse buttons should be placed paired next to each other." Decided by the
coordinator while Oskar was away:

| Change | Layout 3 → 4 | Why |
|---|---|---|
| Lay on Hands *(10)* | Shift+Mouse4 (bar 6 button 2) → Ctrl+Q (bar 3 button 6) | 20 min cooldown (`simc`); a misclick wastes it. |
| Blessing of Protection *(10)* | Mouse4 (bar 6 button 1) → Ctrl+E (bar 3 button 7) | Stops the target's attacks and applies Forbearance (`simc` 1022, 25771); harmful on the wrong player. |
| Blessing of Sacrifice *(46)* | Ctrl+Mouse4 (bar 6 button 3) → Ctrl+R (bar 3 button 8) | Moves the target's damage to you; same family. Ctrl+R keeps the framerate warning. |
| Cleanse / Purify | Mouse5 (bar 6 button 4) → Mouse4 (bar 6 button 1) | Low-risk, the most used party spell, so the plain mouse key. |
| Blessing of Freedom *(18)* | Shift+Mouse5 (bar 6 button 5) → Mouse5 (bar 6 button 2) | Low-risk; the plain pair. |
| Voice of Truth *(20)* | Ctrl+Mouse5 (bar 6 button 6) → Shift+Mouse4 (bar 6 button 3) | Low-risk; the Shift pair. |
| Bar 6 key order | column order → pair order (`BUTTON4`, `BUTTON5`, `SHIFT-BUTTON4`, `SHIFT-BUTTON5`, `CTRL-BUTTON4`, `CTRL-BUTTON5`) | Oskar's pairing; the same as the Shaman. |

All three save spells keep their mouseover macros (`FS_LOH` and `FS_BOP` with the self fallback, `FS_BOS` without),
so a key pressed over a portrait still goes to that player. Divine Intervention stays clicked on bar 6 button 9 (a
misfire sacrifices you). Bar 6 buttons 7-9 are unchanged. Old slots in `L.old` so a full apply moves them; one-time
layout notice, nothing moves by itself, 元に戻す restores.

Oskar also reported "my mouse over purify doesn't seem to work on party portraits". Cause (Forever UI code,
`reckhou/WoWBlzCode` @7245053): `PartyMemberFrame.lua`, `CompactUnitFrame.lua`, `PlayerFrame.lua` and
`TargetFrame.lua` call `SecureUnitButton_OnLoad` without click arguments, which runs `RegisterForClicks("AnyUp")`
(`SecureTemplates.lua`), so the portrait takes Button4/5 as its own click and the `BUTTON4`/`BUTTON5` binding never
fires. Keyboard keys are not affected. Since 0.8.0 the core gives these frames click-cast attributes (`type4`,
`shift-type4`, `ctrl-type5`, ...) that do what the bar 6 button does: `macro` + the `FS_` macro name, or `spell` +
the spell ID in click mode. It only touches them out of combat, never overwrites another addon's attribute, stays
off with Clique or a game Click Casting binding on that button, and has a setting. This fixes Erika's Riptide,
Nature's Swiftness + Healing Wave and cures over portraits too.

## P8. Trade-offs (urgent spells that got a worse key)

1. **Templar's Bulwark: C → Shift+Z (tier 2 → 3).** The one reaction that got worse: the Forbearance family is one
   block. Runner-up: Forbearance on plain Z/X/C and the potions plus Righteous Fury on Shift+Z/X/C. Rejected: it puts
   two rare 5-minute cooldowns on plain keys and both potions on a modifier.
2. **Exorcism: R → Shift+Q (tier 1 → 2).** A rotation spell in undead dungeons. Swift Judgement and the opener get
   tier 1 in exchange.
3. **Seal of Fury: F → Shift+1 (tier 1 → 2).** Refreshed every 30 s, planned, never a reaction.
4. **Redemption loses its key** (rule 3: resurrection on the out-of-combat bars).
5. **The save block: Mouse → Ctrl+Q/E/R (tier 1-3 → tier 3), 0.8.0.** Slower on purpose: Lay on Hands and Blessing of
   Protection are rare, deliberate presses, and a misclick costs a 5-20 minute cooldown or a party member's attacks.

---

# Part 3: For the build task

## Core changes (both packs)

1. **Bars.** The plan's Ctrl bar becomes Action Bar 3 (`MULTIACTIONBAR2BUTTON1-12`, all 12 Ctrl keys). Bar 6
   (`MULTIACTIONBAR5BUTTON`, first slot 145, `PROXY_SHOW_ACTIONBAR_6`) holds the six mouse bindings (button order per
   pack) and the in-combat clicks. Bar 4 holds the out-of-combat clicks. Action Bar 5 leaves the plan.
2. **Showing bar 6 again.** 0.4.3 made "never turn on bars 6 or 7" a rule; Oskar has reversed it for bar 6. A full
   apply shows bar 6 (and bars 2, 3, 4), and **元に戻す** restores the old visibility. Bar 7 and 8 stay off, and the
   shaman's `L.retired` keeps bar 7 only.
3. **Edit Mode hint.** The guide key page, the one-time layout notice and the README tell the player to open Edit
   Mode and drag Action Bar 6 next to the bottom bars (it starts just below the screen centre).
4. **Own keys go.** `L.ownKeys` and the "#" entries are dropped in both packs. `L.oldOwn` (Mana Tide on bar 5 button 5)
   becomes a normal `L.old` entry. Things Erika or Oskar put on 5 / Shift+5 / Ctrl+5 are treated like any non-plan
   item: a full apply moves them to a spare button, and the preview lists them.
5. **Leftovers.** `L.old` lists what layout 6 (shaman) and layout 1 (paladin) put on Action Bar 5 and on Action Bar 3
   buttons that are now spare or different, so a full apply clears them only while they still hold that spell. The
   bar-6 buttons layout 3 filled (shaman, 0.4.0: `L.retired` assigned 1, 6, 7, 9, 10, 12) are now planned or spare:
   planned ones are replaced; spare ones (9, 10, 12) need `L.old` entries. Layout 3's own button (bar 6 button 5) is
   now planned (Poison Cleansing Totem), so whatever she kept there moves to a spare button like any non-plan item.
6. **Unbinding.** Keys that pointed at Action Bar 5 (`MULTIACTIONBAR4BUTTON*`) and Action Bar 3 buttons 7-12 (the old
   mouse buttons) are rebound by the plan; the clean-up and apply must not leave a stale binding on bar 5.
7. **Paladin.** Remove `L.keepDefault` and the `stancebar` noSlot for five auras; place them as normal spells. The
   key page note `ui.layout.stancekeys` goes. `L.defaultWarn` warns for `CTRL-1`…`CTRL-5` (stance) and `CTRL-R`
   (framerate) in both packs (`CTRL-5` is new).
8. **Layout versions:** Restoration 6 → 7, Protection 1 → 2, so both get the one-time すべて配置 notice; nothing
   moves by itself.
9. **check.py: the block rule.** Each pack declares its families and blocks; the check asserts each family's keyed
   members sit in one block (or the mouse pair/column), spill-overs are on bar 6, bars 4/5 hold only out-of-combat
   entries, button n of bars 1-3 has key n, and the exact grids above.
10. **Docs:** README grids and checklist, guide key pages and texts, both locales, the two older research docs get a
    pointer to this one.

## Verify in game

1. Action Bar 6 shows after the apply, its Mouse bindings fire, and Edit Mode keeps it where Oskar or Erika drags it.
2. Paladin: an aura cast from Action Bar 3 works and its button lights up while the aura is active.
3. Ctrl+5's default action (`/run print(GetBindingAction("CTRL-5"))`; expected `SHAPESHIFTBUTTON5`).
4. Hiding the stance bar in Edit Mode doesn't stop the auras from working from Action Bar 3.
5. 元に戻す after the apply restores bar 6's old visibility, bar 5's spells and the old keys.
6. *(0.8.0)* Mouse4/5 over a party, player or target portrait cast that button's spell on that unit; left and right
   click still target and open the menu; no blocked-action error when the group changes in combat.

## Open questions for Oskar

1. Approve both grids (S3, P4).
2. Shaman: Fire on Shift and Earth on Ctrl (proposed), or the runner-up (Earth on Shift: Tremor keeps Shift+F)?
3. Paladin: auras on Action Bar 3 (proposed) or kept on the stance-bar defaults?
4. Paladin: is Templar's Bulwark on Shift+Z acceptable, or do you prefer the runner-up in P8?
5. Should a full apply hide Action Bar 5 now that neither pack uses it, or leave it as the player has it (proposed:
   leave it)?

## (日本語) Erika へのまとめ

- 考え方が変わった：同じ仲間の呪文は、同じ列の隣り合うキーにまとめる。Shift の段と Ctrl の段は「1〜5」「Q・E・R・F」「Z・X・C」の3つに分かれる。
- 何も付けないキーは今まで通り、よく使う呪文。回復（E・R・F）と Earth Shock（Q）は同じ場所。
- **Shift+1〜5＝トーテムを呼ぶ呪文。** 1 Totemic Call、2 Call of the Elements、3 Call of the Ancestors、4 Call of the Spirits、5 Totemic Recall。
- **Shift+Q・E・R・F＝火のトーテム。** Q Flametongue Totem、E Magma Totem、R Searing Totem（今まで通り）、F Fire Nova。
- **Shift+Z・X・C＝水のトーテム。** Z Mana Spring、X Mana Tide、C Healing Stream。
- **Ctrl+Q・E・R・F＝土のトーテム。** Q Earthbind、E Stoneclaw、R Stoneskin、F Tremor。
- **Ctrl+Z・X・C＝風のトーテム。** Z Grounding、X Windfury Totem、C Grace of Air。
- **Ctrl+1〜3＝移動。** 1 Ghost Wolf、2 Water Walking、3 Water Breathing。
- 1〜5 はダメージの呪文：1 Flame Shock、2 Lightning Bolt、3 Chain Lightning、4 Purge、5 Frost Shock。5 も使うようになった。
- マウスのボタンは今まで通り。ただしバーは画面の真ん中に出る Action Bar 6 になるので、編集モードで下のバーの近くに動かそう。
