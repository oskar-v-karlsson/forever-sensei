# ForeverSensei

A class coach addon for **World of Warcraft: Forever**, in Japanese or English. It covers the **Restoration Shaman** healer (made for a Skyborne / Horde player) and the **Protection Paladin** tank, from level 1 to 60.

It comes as one core addon plus a pack per class, like the voice packs of WoW Forever Japanese:
- `ForeverSensei`: the core (windows, cards, layout engine, talent advisor, guide, translation reports, settings);
- `ForeverSensei_Shaman`: the Shaman class pack (skills, the Restoration key layout, talents and guide texts);
- `ForeverSensei_Paladin`: the Paladin class pack (skills, the Protection key layout, talents and guide texts).

A class pack loads only on characters of its class. Turn off packs you don't play in the AddOns list. On a character whose class has no pack, ForeverSensei shows one short note and stays idle; `/sensei` still opens the translation check and settings.

- **Language (日本語 / English):** the first time the addon runs, a small window asks for the language with two buttons, **日本語** and **English**. Nothing else shows until you choose. The choice is saved for the whole account and kept through updates. Change it any time in the settings tab or with `/sensei ja` / `/sensei en`; open windows switch at once, no `/reload` needed. Players who used a version before 0.5.1 are not asked and keep their language.
- **New skill cards (新しいスキル):** when you learn a skill, a card explains in the chosen language what it does, when to use it, where it goes on your bars, and which key presses it. A **配置する** button puts it there. Hover the icon to see the game's own tooltip. Any card can be opened again from the skill list (**カード** button or the icon), learned or not, and shows whether the skill is already in its slot with its key.
- **Fixed bar layout and keys (キー配置):** every skill has a fixed slot and key, planned for a level-60 dungeon healer (Shaman) or tank (Paladin), so a key never moves as you level. The Shaman examples below; the Paladin grid is in [Key layout: Protection Paladin](#key-layout-protection-paladin). Only keys near WASD are used: `1-5`, `Q E R F`, `Z X C`, the same keys with Shift or Ctrl, and the two mouse side buttons. The heals have keys without a modifier (`E`, `R`, `F`, Mouse 4, Mouse 5), and spells of one family sit together in one block of keys and buttons (e.g. the Fire totems on `Shift+Q/E/R/F`, the Paladin seals on `Shift+1-5`). Plain, Shift and Ctrl are Action Bars 1, 2 and 3 at the bottom of the screen; the mouse buttons are Action Bar 6. Your current layout can be replaced in one step (**すべて配置**). You see a preview first, your old bars and keys are backed up, and **元に戻す** restores them. **バーを空にする** first empties only the buttons the layout uses, so the full layout starts clean; your other buttons stay.
- **New ranks:** the game does not put a new rank on the bars, so the addon upgrades bar buttons to the highest rank automatically (after combat if you are fighting), with a toast and **元に戻す** to keep the old rank. It can be turned off in the settings. Healing macros are checked to cast the highest rank too.
- **Healing targeting:** mouseover healing macros, or plain spells for click-target healing. One setting switches between them.
- **Talent advisor (タレント):** when you have an unspent point, it shows the next talent with a short reason, plus the full order: the Mobalytics build for the Restoration Shaman, the Wowhead leveling path (0/32/19) for the Protection Paladin.
- **Guide (`/sensei`):** for the Shaman: the healer role, healing tips, when to deal damage, totems and group manners. For the Paladin: the tank role and threat, the rotation, seals and Judgement, auras and blessings, cooldowns and group manners. Both: a skill list by level, the key layout, and the talent order.
- **Translation reports (翻訳の報告):** every Japanese line can be reported in-game. The player copies the reports into a chat message to the maintainer, and `make reports` applies them here.

All game facts come from World of Warcraft: Forever sources only (client spell data, Wowhead Forever, Mobalytics Forever), never Classic or Retail. See [SOURCES.md](SOURCES.md), which also lists what can only be checked in the game.

Japanese style follows the [WoW Forever Japanese](https://github.com/zyaga/wow-forever-japanese) addon (WFJ):
- spell, item, talent, place and person names stay in English letters (Chain Heal, Orgrimmar);
- class and race words use the WFJ glossary katakana (シャーマン, トレーナー);
- the tone is friendly plain form (常体).

ForeverSensei works with or without WFJ installed. Without it, ForeverSensei uses its own bundled Japanese font.

## Releases

Download the newest zip from [Releases](https://github.com/oskar-v-karlsson/forever-sensei/releases/latest) (the asset `ForeverSensei-v<version>-<commit>.zip`). It holds every addon folder (`ForeverSensei/`, `ForeverSensei_Paladin/` and `ForeverSensei_Shaman/`) at its top level. Every push to `main` makes a release automatically (`.github/workflows/release.yml`). The workflow runs `make check`, builds the zip and publishes it, tagged `v<version>-<short commit>`, e.g. `v0.2.0-5f1a87c`. The newest release is marked **Latest**. If the checks fail, no release is made.

## Install on Windows

1. Get the addon:
   - **Release:** download the zip from [the latest release](https://github.com/oskar-v-karlsson/forever-sensei/releases/latest). On Windows, right-click it → **Extract All**.
   - **Zip:** or run `make zip` and use `dist/ForeverSensei-v<version>.zip`.
   - **Copy:** or copy the `ForeverSensei`, `ForeverSensei_Paladin` and `ForeverSensei_Shaman` folders from this repo.
2. In the **Battle.net** app, choose **World of Warcraft**, then the **Forever** version in the version drop-down. Click the gear next to Play → **Show in Explorer**.
3. Open the Forever game folder, `_forever_`, then `Interface\AddOns`. If `AddOns` (or `Interface`) is missing, create it.
4. Put all three folders, `ForeverSensei`, `ForeverSensei_Paladin` and `ForeverSensei_Shaman`, there. The result must be `...\Interface\AddOns\ForeverSensei\ForeverSensei.toc`, `...\Interface\AddOns\ForeverSensei_Paladin\ForeverSensei_Paladin.toc` and `...\Interface\AddOns\ForeverSensei_Shaman\ForeverSensei_Shaman.toc`. The folders must keep exactly these names and not be nested twice (`ForeverSensei\ForeverSensei\...`), which happens easily with Extract All.
5. Start the game. At character select, open **AddOns** (bottom left), make sure **ForeverSensei** and the pack for your class (**ForeverSensei - Shaman** or **ForeverSensei - Paladin**) are ticked, and turn on **Load out of date AddOns** if the game asks. A pack you don't play can be unticked, or its folder left out.

To update, delete the old `ForeverSensei`, `ForeverSensei_Paladin` and `ForeverSensei_Shaman` folders and put the new ones in their place. Your settings and saved reports are kept, because they are stored in `_forever_\WTF\Account\...\SavedVariables\ForeverSensei.lua`.

## First steps in the game

1. On the very first login, choose **日本語** or **English** in the language window.
2. Type `/sensei`, or click the minimap button, or use the addon compartment (the AddOns button at the minimap). The guide opens.
3. Open **キー配置** (layout), choose how to pick a healing target (**マウスオーバーで回復** or **ターゲットを回復**), then press **すべて配置** to see the preview.
4. The preview lists every slot and key that changes. Press **適用** to apply. `/sensei undo` or the **元に戻す** button restores the old bars and keys.
   To start from empty bars, press **バーを空にする** first (`/sensei clean`). It asks first and empties only the buttons the addon configures: every planned slot (spells, item macros, and slots kept free for spells you haven't learned yet), the buttons 0.4.1-0.6.1 used on Action Bar 5 and the buttons 0.4.0 used on Action Bar 7. Spare buttons and every other button stay. It saves the bars first, so **元に戻す** puts them back.

   Note: the full layout binds every key of the three rows, including `Q`/`E` (strafe by default), `Shift+1-4` (bar paging by default), `Ctrl+1-5` (stance-bar buttons: Ghost Wolf, the Paladin auras), `Ctrl+R` (framerate display) and the mouse side buttons. The preview warns about this.
5. **Move Action Bar 6.** The layout uses Action Bar 6 for the mouse buttons and the spells you click in combat. The game puts it in the middle of the screen: press `Esc`, open **Edit Mode** and drag it next to your bottom bars. The game remembers where you put it.
6. Play. New skills show a card out of combat. Cards wait until combat ends, and bar or key changes started in combat are applied when it ends.

The game's 12.x API hides health, cooldowns and auras from addons in combat, so ForeverSensei only coaches outside combat. It has no rotation helper.

### Commands

| Command | What it does |
|---|---|
| `/sensei` | Open the guide (`/foreversensei` also works) |
| `/sensei skills` | Skill list by level: learned, not learned, and slot. **カード** opens the skill's card. |
| `/sensei layout` | Key layout tab |
| `/sensei apply` / `/sensei undo` | Apply the full layout (with preview) / restore the backup |
| `/sensei clean` | Empty only the buttons the full layout uses (asks first; **元に戻す** restores) |
| `/sensei talents` | Talent advice; `/sensei order` shows the full order |
| `/sensei trainer` | Skills available at the trainer for your level |
| `/sensei card <Spell>` | Show the card for a spell (English name, e.g. `/sensei card Chain Heal`) |
| `/sensei review` | Translation check tab (mark each text OK or report it) |
| `/sensei report` | Send translation reports (copy box) |
| `/sensei settings` | Settings |
| `/sensei verify` | Check every spell and talent in the data against the live client |
| `/sensei en` / `/sensei ja` | Interface language (also in the settings tab); open windows switch at once |
| `/sensei debug` | Toggle debug output |

### Key layout: Restoration Shaman

The plan is in [research/keybind-layout-v4.md](research/keybind-layout-v4.md) (layout 7, "family blocks", 0.7.0), which builds on [research/keybind-layout.md](research/keybind-layout.md) (pull walkthroughs, reach for small hands, sources). *(n)* is the level the spell becomes available; MO = mouseover macro.

| Key | Plain (Action Bar 1) | Shift (Action Bar 2) | Ctrl (Action Bar 3) |
|---|---|---|---|
| 1 | Flame Shock *(10)* | Totemic Call *(22)* | Ghost Wolf *(20)* |
| 2 | Lightning Bolt *(1)* | Call of the Elements *(20)* | Water Walking *(28)* |
| 3 | Chain Lightning *(32)* | Call of the Ancestors *(30)* | Water Breathing *(22)* |
| 4 | Purge, MO enemy *(12)* | Call of the Spirits *(40)* | – |
| 5 | Frost Shock *(20)* | Totemic Recall *(20)* | – |
| Q | Earth Shock (interrupt) *(4)* | Flametongue Totem *(28)* | Earthbind Totem *(6)* |
| E | Lesser Healing Wave, MO *(20)* | Magma Totem *(26)* | Stoneclaw Totem *(8)* |
| R | Chain Heal, MO *(40)* | Searing Totem *(10)* | Stoneskin Totem *(4)* |
| F | Healing Wave, MO *(1)* | Fire Nova *(12)* | Tremor Totem *(18)* |
| Z | Mana Potion | Mana Spring Totem *(26)* | Grounding Totem *(30)* |
| X | Water Shield *(20)*; Lightning Shield *(8)* until then | Mana Tide Totem *(25)* | Windfury Totem *(32)* |
| C | Healthstone, else Healing Potion | Healing Stream Totem *(20)* | Grace of Air Totem *(42)* |
| Mouse 4 | Riptide, MO *(40)* | Cure Poison, MO *(16)* | Poison Cleansing Totem *(22)* |
| Mouse 5 | Nature's Swiftness + Healing Wave *(30)* | Cure Disease, MO *(22)* | Disease Cleansing Totem *(38)* |

- **Blocks:** each row splits into `1-5`, `Q E R F` and `Z X C`, and one family fills one block. Plain: damage on `1-5`, the interrupt and heals on `Q-F`, potions and the shield on `Z-C`. Shift: the totem calls on `1-5`, Fire totems on `Q-F`, Water totems on `Z-C`. Ctrl: travel on `1-3`, Earth totems on `Q-F`, Air totems on `Z-C`. The mouse buttons are three pairs: heals, cures, cleansing totems.
- **Bars:** plain keys are Action Bar 1, Shift Action Bar 2 and Ctrl Action Bar 3, all at the bottom of the screen. Button n of a bar is key n of its row (`1`, `2`, `3`, `4`, `5`, `Q`, `E`, `R`, `F`, `Z`, `X`, `C`), so a family also sits together on screen. Action Bar 6 buttons 1-6 are `Mouse 4`, `Mouse 5`, `Shift+Mouse 4/5`, `Ctrl+Mouse 4/5`. **すべて配置** turns on Action Bars 2, 3, 4 and 6, because a hidden bar may not react to its keys. Move Action Bar 6 down in Edit Mode (see First steps).
- **Fire totems** (Erika's request in 0.6.1, kept together): Flametongue, Magma, Searing and Fire Nova on `Shift+Q/E/R/F`. Fire Nova only hits enemies near your active Fire totem, so against a pack place Searing or Magma first, then press `Shift+F`.
- Totem flow in a dungeon: `Shift+1` Totemic Call at every pull brings your totems along; `Shift+2` Call of the Elements when the 5-minute totems run out (about every few pulls) and after a wipe; `Shift+R` Searing at every pull (it lasts 30-55 s); `Shift+5` Totemic Recall when you leave. Before level 22 (no Totemic Call yet), put down Stoneskin (`Ctrl+R`) and Searing by hand.
- A key whose spell you learn later (e.g. Chain Heal and Riptide at 40) stays empty until then. Keys never move while levelling.
- `Ctrl+4` and `Ctrl+5` have no skill. They are still bound to their (empty) button, so every row has all 12 keys. You can put your own things there; **すべて配置** only binds the key and leaves the button alone. No key is reserved any more: `5`, `Shift+5` and `Ctrl+5` are planned like the others, and anything you had there moves to a spare button.
- **Mouse side buttons:** leave them as the default Button 4 and Button 5 in your mouse software (no "back/forward" or other remapping), so the game sees `BUTTON4` and `BUTTON5`.
- **Mouse 4/5 over portraits (0.8.0):** the game's player, target and party frames take the mouse side buttons for themselves, so a `Mouse 4/5` key does nothing while the mouse is over a portrait. ForeverSensei gives those frames the same action as the Action Bar 6 button (e.g. Riptide on `Mouse 4` goes to the party member under the mouse). It only does this out of combat (frames that appear in combat follow after the fight), never replaces what another addon set there, stays off with Clique or with a mouse button bound in the game's Click Casting, and can be turned off in the settings. Left and right click keep targeting and the menu. The Paladin gets the same.

The other buttons have no keys. They are for clicking:
- Action Bar 6, buttons 7-8 (used in combat): Strength of Earth Totem (the Earth block is full) and the Healing Potion button (`FS_HEALPOT`). Buttons 9-12 are spare.
- Action Bar 4 (right edge, out of combat only): Ancestral Spirit, Astral Recall, Rockbiter, Flametongue, Frostbrand and Windfury Weapon, Lightning Shield (after Water Shield), the Arcane Elixir button (`FS_ELIXIR`). Buttons 9-12 are spare.
- Only in the spellbook (no button, rarely needed): Far Sight and Sentry Totem (scouting).
- Action Bar 5 is no longer used. **すべて配置** clears the spells 0.4.1-0.6.1 put there (only while a button still holds exactly that spell) and leaves the bar and anything else on it as you have it. Action Bar 7 (0.4.0) stays hidden.

Anything that was on a planned slot moves to the spare buttons first (Action Bar 4, then Action Bar 6, then Action Bar 3).

The item buttons are character macros the addon keeps up to date: `FS_MANA` (Mana Potion), `FS_HEALTH` (Healthstone, else Healing Potion), `FS_HEALPOT` (Healing Potion) and `FS_ELIXIR` (Arcane Elixir, e.g. Minor Arcane Elixir). Each uses the best one of its kind in your bags that your level allows. They are only changed out of combat (after looting, or when combat ends). With none in the bags, the button keeps a fixed icon. The items are listed in `ForeverSensei/Data/Items.lua`.

Players who applied an older layout get a one-time message after updating, with a **すべて配置** button that opens the usual preview. Nothing moves by itself, and **元に戻す** restores the old bars, keys and bar visibility.

The resistance totems and Windwall Totem are used from the Totem Bar or spellbook. Reincarnation is passive. The source of truth is `ForeverSensei_Shaman/Data/Restoration/Layout.lua`.

These buttons are character macros (13 addon macros in total, of 30 per character):
- `FS_HW`, `FS_LHW`, `FS_CH`, `FS_RT`: Healing Wave, Lesser Healing Wave, Chain Heal and Riptide (mouseover mode only);
- `FS_CP`, `FS_CD`: Cure Poison and Cure Disease (mouseover mode only);
- `FS_PURGE`: Purge on the enemy under the mouse, else your target (mouseover mode only);
- `FS_ES`: Earth Shock, always a macro. `/stopcasting` stops your own cast first, so the interrupt goes off at once;
- `FS_NSHW`: Nature's Swiftness, then Healing Wave, in one press (always a macro). While Nature's Swiftness is on cooldown, it casts a normal Healing Wave.

A healing macro is:
```
#showtooltip <Spell>
/cast [@mouseover,help,nodead][help,nodead][@player] <Spell>
```
It heals the friend under the mouse, otherwise the friendly target, otherwise you.

### Key layout: Protection Paladin

The plan is in [research/keybind-layout-v4.md](research/keybind-layout-v4.md) (layout 4: "family blocks" since 0.7.0, Seal of Justice on `Shift+4` since 0.7.1, the save block on `Ctrl+Q/E/R` and paired mouse keys since 0.8.0), which builds on [research/keybind-layout-paladin.md](research/keybind-layout-paladin.md) (pull walkthroughs at levels 20, 40 and 60, reach for normal hands, sources). It uses the same allowed keys and bars as the Shaman layout. *(n)* is the level the spell becomes available; MO = mouseover macro.

| Key | Plain (Action Bar 1) | Shift (Action Bar 2) | Ctrl (Action Bar 3) |
|---|---|---|---|
| 1 | Holy Strike *(6)* | Seal of Fury *(10)* | Retribution Aura *(16)* |
| 2 | Consecration *(20)* | Seal of Righteousness *(1)* | Devotion Aura *(1)* |
| 3 | Holy Shield *(42, talent)* | Seal of the Crusader *(6)* | Concentration Aura *(22)* |
| 4 | Flash of Light, MO + self *(20)* | Seal of Justice *(22)* | Shadow Resistance Aura *(28)* |
| 5 | Holy Light, MO + self *(1)* | Seal of Wisdom *(38)* | Frost Resistance Aura *(32)* |
| Q | Judgement *(4)* | Exorcism *(20)* | Lay on Hands, MO + self *(10)* |
| E | Swift Judgement *(37, talent)* | Hammer of Wrath *(44)* | Blessing of Protection, MO + self *(10)* |
| R | Opener: Judgement + Swift Judgement + Holy Strike *(37)* | Holy Wrath *(50)* | Blessing of Sacrifice, MO *(46)* |
| F | Hammer of Justice, MO enemy *(8)* | Turn Undead *(24)* | – |
| Z | Healthstone, else Healing Potion | Templar's Bulwark *(32, talent)* | Blessing of Kings *(20)* |
| X | Mana Potion | Divine Shield *(34)* | Blessing of Might *(4)* |
| C | Righteous Fury *(10)* | Divine Protection *(6)* | Blessing of Wisdom *(14)* |
| Mouse 4 | Cleanse, MO + self *(42)*; Purify *(8)* until then | Voice of Truth *(20)* | – |
| Mouse 5 | Blessing of Freedom, MO + self *(18)* | – | – |

- **Blocks:** plain `1-3` the core loop (Holy Strike, Consecration, Holy Shield), `4-5` the heals, `Q-R` the Judgement family, `F` Hammer of Justice, `Z-C` potions and Righteous Fury. Shift: seals on `1-5` (Fury, Righteousness, Crusader, Justice, Wisdom; Seal of Light, which a tank rarely needs, is clicked on Action Bar 6), the conditional attacks (undead, low health) on `Q-F`, the Forbearance cooldowns on `Z-C` (Bulwark, Divine Shield and Divine Protection share Forbearance). Ctrl: auras on `1-5`, the save block on `Q-R` (Lay on Hands, Blessing of Protection, Blessing of Sacrifice: long cooldowns, and harmful on the wrong player, so they are on keys and not on the easily pressed mouse buttons), blessings on `Z-C`. The mouse buttons hold only low-risk spells: Mouse 4 cleanses, Mouse 5 frees, Shift+Mouse 4 is Voice of Truth.
- **Bars:** as for the Shaman. Plain keys are Action Bar 1, Shift Action Bar 2, Ctrl Action Bar 3, the mouse keys Action Bar 6 buttons 1-6 in pairs, as for the Shaman (`Mouse 4`, `Mouse 5`, `Shift+Mouse 4`, `Shift+Mouse 5`, `Ctrl+Mouse 4`, `Ctrl+Mouse 5`). Move Action Bar 6 down in Edit Mode.
- **Auras:** the auras are on Action Bar 3 buttons 1-5 with `Ctrl+1-5`, next to the seals on `Shift+1-5`. `Ctrl+1-5` no longer press the stance bar (the preview says so); the stance bar still shows your auras. Fire Resistance Aura is clicked on Action Bar 6 (button 8). If an aura button on Action Bar 3 does not light up while the aura is on (checklist), the fallback is the stance bar's own `Ctrl+1-5`.
- **Taunt:** the Paladin has no taunt button. Judgement (`Q`) while Seal of Fury is active taunts for 3 seconds. There is no interrupt either: `F` Hammer of Justice stuns (the macro stops your own cast first and stuns the enemy under the mouse, else your target).
- **Help macros:** with **マウスオーバーで回復**, Flash of Light, Holy Light, Lay on Hands, Cleanse, Purify, Blessing of Freedom and (since 0.7.1) Blessing of Protection go to the friend under the mouse, else a friendly target, else you. On yourself Blessing of Protection stops your attacks for 6 seconds and gives Forbearance (no Templar's Bulwark, Divine Shield or Divine Protection for 1 minute). Blessing of Sacrifice never falls back to you (it moves the target's damage to the caster). If a help key casts only on a mouseover or target, run `/sensei verify`: a `plain spell ..., not macro FS_...` line means that button holds the plain spell; **すべて配置** puts the macro back. With **ターゲットを回復**, plain spells.
- **Opener** (`R`, macro `FS_OPEN`, from level 37): `/startattack`, Judgement, Swift Judgement and Holy Strike in one press. Judgement and Swift Judgement are off the global cooldown. Its button stays empty until Swift Judgement is learned.
- **Purify → Cleanse:** Purify stands in on `Mouse 4` until Cleanse at 42. Then Cleanse takes the button and Purify stays in the spellbook.
- Spare keys, bound to empty buttons for your own use: `Ctrl+F`, `Shift+Mouse 5`, `Ctrl+Mouse 4`, `Ctrl+Mouse 5`. No key is reserved any more: `5`, `Shift+5` and `Ctrl+5` are planned, and anything you had there moves to a spare button.
- Clicked, no key: Action Bar 6 buttons 7-9 (in combat) hold Seal of Light, Fire Resistance Aura and Divine Intervention; Action Bar 4 (out of combat) holds Redemption and Greater Blessing of Kings, Might and Wisdom. Summon Warhorse and Summon Charger stay in the spellbook (mount journal). Action Bar 5 is no longer used; **すべて配置** clears what 0.6.x put there and leaves the bar as you have it.
- Character macros: `FS_FOL`, `FS_HL`, `FS_LOH`, `FS_CLEANSE` (`FS_PURIFY` before 42), `FS_BOF`, `FS_BOP`, `FS_BOS` (mouseover mode only), `FS_HOJ` and `FS_OPEN` (always), `FS_HEALTH` and `FS_MANA`: at most 12 of 30.
- The source of truth is `ForeverSensei_Paladin/Data/Protection/Layout.lua`.

## In-game test checklist

These cannot be tested outside the game. Please go through them once, then paste the chat output of step 1 back to the repo owner.

1. [ ] `/sensei verify` opens a window that starts with `problems: <n>`. Press Ctrl+C in the window and send the text.
2. [ ] **Font, fresh launch:** fully quit the game and start it again (not `/reload`). Japanese shows in the guide and cards, with no boxes or `?`. Test once with WFJ enabled and once without.
3. [ ] Learning a skill at the trainer (or a level-up skill) shows a card out of combat. Hovering the icon shows the game tooltip.
4. [ ] **配置する** on a card puts the skill in its slot and binds the key, and asks first if the slot is used.
5. [ ] **すべて配置:** the preview is shown, **適用** changes the bars and keys, Action Bars 2, 3, 4 and 6 become visible (Action Bar 5 stays as it was, 7 stays hidden), and `/reload` keeps everything.
6. [ ] **元に戻す** / `/sensei undo` restores the old bars and keys.
7. [ ] Mouseover mode: hovering a party frame and pressing `F` (or Mouse 4 for Riptide) heals that player. With no mouseover, it heals the target. With no friendly target, it heals you.
8. [ ] Switching to **ターゲットを回復** replaces the macros with plain spells in the same slots, and back again.
9. [ ] Learning a higher rank (out of combat, or right after combat) changes the bar buttons to it and shows a toast. **元に戻す** on the toast puts the old rank back and keeps it. A mouseover macro (e.g. Healing Wave on `F`) casts the new rank: in `/sensei verify`, the macro lines under [Layout] show the same id after `casts` and `highest known`, and there is no `macro does not cast the highest rank` line. The game itself does not upgrade bar buttons (seen in game, v0.1.0).
10. [ ] Long texts (talent hint, cards, trainer list, report window) stay inside their windows, and the skill list's **カード** button opens the card with a working **配置する**.
11. [ ] At level 10 and later, an unspent talent point shows the next talent hint. **タレントを開く** opens the talent window, and the advice matches what is already spent.
12. [ ] Entering combat hides an open skill card, trainer list and talent hint. They come back after combat. A layout change started in combat is applied after combat.
13. [ ] Translation report flow (below) works: save, send, copy, mark as sent.
14. [ ] The minimap button can be dragged and hidden in settings, and the addon compartment entry works.
15. [ ] **Login, no old cards:** close a skill card with **あとで**, then place that skill (**配置する** in the skill list, or **すべて配置**). `/reload`: no card opens. A skill left on **あとで** and not placed does not open a card either; a small message with **見る** shows it instead.
16. [ ] **Layout notice (update from 0.3.0 or older):** with the old layout on the bars, the first login after updating shows the message about the new layout once. **すべて配置** opens the preview, and nothing changes until **適用**. The message does not come back after `/reload`.
17. [ ] After **すべて配置**: `Shift+1` Totemic Call, `Shift+2` Call of the Elements and `Shift+5` Totemic Recall work; `Ctrl+R` Stoneskin, `Shift+R` Searing and `Ctrl+F` Tremor put down their totems; `Shift+E` puts down Magma Totem, and `Shift+F` casts Fire Nova next to the Fire totem (and does nothing useful without one). Note the mana cost of Call of the Elements with a full set.
18. [ ] **Potions:** `Z` drinks the best mana potion in the bags. Loot or buy a better one: the button changes to it after combat (or right away out of combat). The healing potion (Action Bar 6) and Arcane Elixir (Action Bar 4) buttons work by clicking. With none in the bags, the buttons show a potion icon (no question mark). `/sensei verify` lists `FS_MANA`, `FS_HEALTH`, `FS_HEALPOT` and `FS_ELIXIR` under [Layout] with no `bad` lines.
19. [ ] **Ctrl and mouse keys:** after **すべて配置**, Action Bar 3 at the bottom has the Ctrl keys in the same order as Action Bar 2 (Ctrl+1 Ghost Wolf on button 1, Ctrl+C Grace of Air Totem on button 12), and Action Bar 6 buttons 1-6 hold the mouse spells. Every Ctrl key and `Mouse 4`, `Mouse 5`, `Shift+Mouse 4/5`, `Ctrl+Mouse 4/5` cast their spells. `Ctrl+4` and `Ctrl+5` press their empty Action Bar 3 button (put a skill there to test). `Ctrl+R` casts Stoneskin Totem and no longer toggles the framerate. The mouse side buttons are set to the default Button 4/5 in the mouse software. `/sensei verify` shows the bindings of `CTRL-4`, `CTRL-R`, `SHIFT-BUTTON4`, `CTRL-BUTTON4` and of `5`, `SHIFT-5`, `CTRL-5`.
20. [ ] **Ctrl+1 is Ghost Wolf:** `Ctrl+1` casts Ghost Wolf from Action Bar 3 (not the stance bar), and the button lights up while you are a wolf.
21. [ ] **Macros:** `Q` (FS_ES) during your own cast stops it and interrupts at once. `Mouse 5` (FS_NSHW) casts an instant Healing Wave in one press, and a normal one while Nature's Swiftness is on cooldown. `Shift+3` (FS_PURGE) purges the enemy under the mouse.
22. [ ] **Healthstone:** `C` uses a Healthstone if you have one, else the best Healing Potion. Check whether the Healthstone and potions share a cooldown.
23. [ ] **Levelling:** below level 20, `X` holds Lightning Shield; after learning Water Shield and **配置する**, `X` holds Water Shield and Lightning Shield moves to Action Bar 4. A key whose spell is not learned yet stays empty.
24. [ ] **Totem Bar:** the addon does not set up the Totem Bar (3 pages of 4 totems for Call of the Elements/Ancestors/Spirits). Set it up by hand and check that Call of the Elements puts down that set.
25. [ ] **Update from 0.4.0:** with the 0.4.0 layout applied (Action Bars 6 and 7 in the middle of the screen), the first login shows the layout message once. **すべて配置** lists Action Bar 7 under the bars to hide; after **適用** it is gone, the mouse keys work from Action Bar 6 and the Ctrl keys from Action Bar 3. **元に戻す** brings everything back as it was.
26. [ ] **Update from 0.4.2:** the first login shows the layout message once. Action Bar 5 button 5 is cleared if it still holds the Mana Tide Totem that 0.4.2 put there (Mana Tide is now on `Shift+X`); anything else you put there stays. **元に戻す** restores it all.
27. [ ] **バーを空にする:** put a few things of your own on planned buttons, on spare buttons (e.g. Action Bar 4 buttons 9-12) and on unused Action Bar 5 buttons. The button asks first; after confirming, only the planned buttons are empty, and the spare buttons and the other buttons are unchanged. **元に戻す** puts everything back. Out of combat only: in combat it says to try again after the fight.
28. [ ] **Class pack (0.5.0):** the AddOns list shows **ForeverSensei** and **ForeverSensei - Shaman**. On the Shaman, everything works as in 0.4.3: cards, layout, talents, guide tabs, no new layout message, review progress and saved reports kept, Totem Bar unchanged. `/sensei verify` has no `bad` lines.
29. [ ] **No pack:** turn off **ForeverSensei - Shaman** (or log in on a character of another class). The first login shows one short note that the class pack is missing, and `/reload` does not show it again. `/sensei` opens with only the translation check and settings tabs; no cards, toasts or layout messages appear. Turn the pack back on afterwards.
30. [ ] **Language window (0.5.1):** on a test account (or after renaming `ForeverSensei.lua` in `_forever_\WTF\Account\...\SavedVariables`), the first login shows only the language window: no skill card, welcome message, layout message or pack note. **English** switches everything to English at once and the welcome message follows; after `/reload` and after an update the window does not come back. Erika's account (data from 0.5.0) is not asked and stays Japanese. With the guide and a skill card open, `/sensei en` and `/sensei ja` switch their texts without `/reload`.

**Protection Paladin (0.6.0).** On a paladin, with **ForeverSensei - Paladin** ticked:

31. [ ] **Pack:** the AddOns list shows **ForeverSensei - Paladin**. On the paladin, no "pack missing" note; on the Shaman, everything is as before (the Paladin pack is not loaded there).
32. [ ] **Auras on Ctrl+1-5 (0.7.0):** see items 43-47 below.
33. [ ] **Preview warnings:** the preview warns about `Ctrl+1-5` (stance bar), `Ctrl+R` (framerate display), the mouse side buttons and moving Action Bar 6 in Edit Mode.
34. [ ] **Taunt:** with Seal of Fury active, `Q` Judgement taunts. Note whether the taunt lasts 3 or 4 seconds, and whether Judgement keeps the seal.
35. [ ] **Opener:** from 37, `R` (FS_OPEN) casts Judgement, Swift Judgement and Holy Strike from one press and starts auto attack.
36. [ ] **Help macros:** with a hostile target and nothing under the mouse, `4`, `5`, `Ctrl+Q` (Lay on Hands), `Ctrl+E` (Blessing of Protection), `Mouse 4` (Cleanse or Purify) and `Mouse 5` (Blessing of Freedom) cast on you. `Ctrl+R` (Blessing of Sacrifice) does not. Over a party frame, all of them go to that player. *(Keys as of 0.8.0.)*
37. [ ] **Hammer of Justice:** `F` during your own cast stops it and stuns the enemy under the mouse at once, else your target.
38. [ ] **Purify → Cleanse:** before 42, `Mouse 4` holds Purify. After learning Cleanse and **配置する**, `Mouse 4` holds Cleanse and Purify is gone from the bars.
39. [ ] **Ranks:** learning a new rank of Holy Strike, Seal of Fury or Holy Shield upgrades its button with a toast. `/sensei verify` has no `bad` lines (it checks every rank ID against the client, including Seal of Fury and Holy Light rank 1).
40. [ ] **Talents:** from 10, the talent hint follows the Wowhead leveling path: Templar's Bulwark at 32, Swift Judgement at 37, Holy Shield at 42.
41. [ ] **Trainer:** tell the repo owner whether Blessing of Salvation, Blessing of Sanctuary, Blessing of Light or Hammer of the Righteous are offered at the trainer. They are left out until confirmed.

**Restoration Shaman, Fire totems (0.6.1).** On the Shaman, after updating from 0.6.0:

42. [ ] *(Superseded by 0.7.0: the Fire totems are now on `Shift+Q/E/R/F`, see below.)*

**Layout v4, family blocks (0.7.0).** On both characters, after updating from 0.6.1 (Shaman layout 6, Paladin layout 1):

43. [ ] **Layout message:** the first login shows the layout message once, and nothing moves by itself. The **すべて配置** preview lists Action Bar 6 under the bars to show, the moves to Action Bars 3 and 6, the old Action Bar 5 spells being cleared, and the notes about `Ctrl+1-5`, `Ctrl+R`, the mouse buttons and Edit Mode.
44. [ ] **Action Bar 6:** after **適用**, Action Bar 6 is shown (in the middle of the screen). Its mouse bindings fire (`Mouse 4`, `Mouse 5`, `Shift+` and `Ctrl+Mouse 4/5`). Drag it next to the bottom bars in Edit Mode; after `/reload` and a relog it stays where you put it.
45. [ ] **Paladin auras on Action Bar 3:** `Ctrl+1-5` cast Retribution, Devotion, Concentration, Shadow and Frost Resistance Aura, and the aura's button on Action Bar 3 lights up while it is active. If it does not light up, tell the repo owner: the fallback is to keep the auras on the stance bar's own `Ctrl+1-5`.
46. [ ] **Ctrl+5 default:** before **適用**, `/run print(GetBindingAction("CTRL-5"))` prints the game default (expected `SHAPESHIFTBUTTON5`). After **適用** it prints `MULTIACTIONBAR2BUTTON5`.
47. [ ] **Hidden stance bar:** hide the stance bar in Edit Mode. The Paladin auras still work from `Ctrl+1-5`, and the Shaman's Ghost Wolf from `Ctrl+1`.
48. [ ] **元に戻す:** after **適用**, **元に戻す** restores the old keys, the spells layout 6 (or the Paladin's layout 1) had on Action Bar 5, and Action Bar 6's visibility from before.

**Paladin help macros and seals (0.7.1).** On the Paladin, after updating from 0.7.0 (layout 2):

49. [ ] **Self fallback:** with **マウスオーバーで回復**, no friend under the mouse and a hostile or no target, `Ctrl+Q` (Lay on Hands), `Ctrl+E` (Blessing of Protection), `4`, `5`, `Mouse 4` and `Mouse 5` cast on you. `Ctrl+R` (Blessing of Sacrifice) does not. *(Keys as of 0.8.0; in 0.7.1 these were mouse buttons.)* If one doesn't, run `/sensei verify` and send the `plain spell ..., not macro` and `character macros` lines; then **すべて配置** and try again.
50. [ ] **Seals:** the layout message shows once and nothing moves by itself. After **すべて配置** → **適用**, `Shift+1-5` are Seal of Fury, Righteousness, the Crusader, Justice and Wisdom, and Seal of Light is on Action Bar 6 button 7. **元に戻す** puts Wisdom, Light and Justice back where they were.

**Save keys and Mouse 4/5 on unit frames (0.8.0).** On the Paladin after updating from 0.7.1 (layout 3), and on the Shaman:

51. [ ] **Paladin save block:** the layout message shows once and nothing moves by itself. After **すべて配置** → **適用**, `Ctrl+Q` is Lay on Hands, `Ctrl+E` Blessing of Protection and `Ctrl+R` Blessing of Sacrifice (Action Bar 3 buttons 6-8; the preview still warns that `Ctrl+R` no longer toggles the framerate). Action Bar 6 buttons 1-3 are Cleanse (or Purify), Blessing of Freedom and Voice of Truth (`Mouse 4`, `Mouse 5`, `Shift+Mouse 4`), buttons 4-6 are empty, and buttons 7-9 Seal of Light, Fire Resistance Aura and Divine Intervention. **元に戻す** puts everything back.
52. [ ] **Mouse 4/5 over a portrait:** hover a party member's portrait (the party frame, and the raid-style party frames if you use them) and press `Mouse 4`: on the Paladin, Cleanse (Purify before 42) goes to that member; `Mouse 5` casts Blessing of Freedom and `Shift+Mouse 4` Voice of Truth. Repeat over your own portrait and the target portrait.
53. [ ] **Shaman portraits:** over a party portrait, `Mouse 4` casts Riptide on that member, `Mouse 5` the Nature's Swiftness + Healing Wave macro, `Shift+Mouse 4/5` Cure Poison and Cure Disease.
54. [ ] **Clicks unchanged:** left click on a portrait still targets, right click still opens its menu. `Mouse 4/5` away from the portraits (over the world) still work as before.
55. [ ] **Combat:** join a group or change the group while in combat: no `ADDON_ACTION_BLOCKED` or "interface action failed" message; the new portraits get `Mouse 4/5` after the fight. `/sensei verify` has a `unit frames (Mouse 4/5)` line under [Layout] that lists the frames covered and anything skipped (and why).
56. [ ] **Setting and other addons:** turning off the setting about Mouse 4 and Mouse 5 over party and player frames makes the portraits ignore `Mouse 4/5` again (as before 0.8.0). With Clique installed the addon leaves the portraits alone, and so it does for a mouse button you bound in the game's own Click Casting.

## Translation reports

### For the player (日本語)

1. 変な日本語や、わかりにくい文を見つけたら、その文の横の **報告** ボタンを押す。
2. どこがおかしいかを選ぶ（意味が違う／不自然／誤字／わかりにくい／その他）。よりよい日本語やメモは、書いても書かなくてもいい。**保存** を押す。
3. いくつか保存したら、ミニマップボタンを右クリック（または `/sensei report`）。**報告を送る** の画面が開く。
4. 文はもう選択されている。**Ctrl+C** でコピーして、チャットに貼り付けて送る。
5. **送信済みにする** を押すと、送った報告が一覧から消える。

**翻訳チェック** のタブでは、すべての文を順番に見て、OKか報告かを決められる。

### For the repo owner

1. Copy the player's whole chat message, including the `[ForeverSensei v… 報告 N件]` header. Chat names and timestamps around it are ignored.
2. Run `make reports`. It reads the clipboard (`pbpaste`). You can also run `python3 tools/reports.py --file paste.txt`, or `make reports-dry` to only preview. For each report, it:
   - applies the player's suggested Japanese (案) if the ID exists, the "今" text still matches, and the suggestion passes the text rules;
   - writes everything else to `reports/open.md`, with the English source, the current Japanese and the player's note;
   - logs every report to `reports/log.md`.

   `reports/` is in `.gitignore`: these files hold the player's own comments and stay local. Never commit them.

   It writes each suggestion into the `ja.lua` that owns the ID (core or class pack). If anything changed, it also bumps the patch version (every TOC and `Core/Init.lua`), runs `make check`, and builds `dist/ForeverSensei-v<version>.zip`.
3. Handle `reports/open.md` (or ask an agent to, see below). Then commit the changed addon files (not `reports/`) and send the player the new zip.

### For agents: processing translation reports

When the user pastes a report block (starting `[ForeverSensei v`) or asks you to handle `reports/open.md`:

1. If it was pasted in chat, save it to a temporary file and run `python3 tools/reports.py --file <file>`. This applies valid suggestions and adds the rest to `reports/open.md`.
2. For each entry in `reports/open.md`, write a better Japanese line in the `ja.lua` that owns the ID. Skill (`spell.*`), talent (`talent.*`), guide (`guide.*`) and class-specific `ui.*` texts are in the class pack (`ForeverSensei_<Class>/Locales/ja.lua`); all other `ui.*` texts are in the core (`ForeverSensei/Locales/ja.lua`). Packs can share an ID (e.g. `guide.role.p1` is in both packs), so a report line names its pack at the end (`#1 guide.role.p1 | 不自然 | ForeverSensei_Paladin`) and `reports/open.md` shows it in the heading. Edit the `ja.lua` of that pack. `grep -rn '"<id>"' ForeverSensei*/Locales/ja.lua` finds the candidates; `reports.py` routes suggestions the same way, and keeps a report open if its ID is in several packs and it names none.
   - **Keep the format.** Edit only that ID's line. Keep one entry per line: `  ["id"] = "...",`.
   - **Read the sources.** Use the English source in the `Locales/en.lua` next to it; it is the fact source. Do not add facts that are not in the English text. If the English is wrong, fix it too, from a Forever source (see SOURCES.md).
   - **Names stay in English letters,** exactly as in the English text: spells, talents, items, places, people.
   - **Glossary katakana for game words:** シャーマン, トレーナー, トーテム, タレント, アクションバー, マウスオーバー, クエスト. Follow the WFJ glossary (`docs/glossary.md`, `pipeline/translation_glossary.tsv`) and style guide (`docs/content/translation-style-guide.md`) in [zyaga/wow-forever-japanese](https://github.com/zyaga/wow-forever-japanese).
   - **Avoid** ヘルス (use 体力), 知性 (use 知力) and 役割 (use ロール).
   - **Plain form (常体):** facts end like `回復する。`, advice ends like `使おう。` No です/ます, no slang.
   - **Punctuation:** use 、 and 。 No `/` (except in `/sensei` commands) and no `...`. Use `〜` for ranges (`1〜5`) and `・` between key names (`Q・E・R・F`).
   - **Placeholders:** keep every `{placeholder}` from the English text.
   - **Length:** keep it about as short as the current text. Card texts must fit the card.
   - **The player's note** says what was wrong; fix exactly that.
3. Run `make check`. It checks the text rules, font glyphs, placeholders and length, and runs every screen in a fake client. Fix anything it reports.
4. Delete the handled entries from `reports/open.md`. Bump the patch version in every TOC (`ForeverSensei/ForeverSensei.toc`, `ForeverSensei_Paladin/ForeverSensei_Paladin.toc`, `ForeverSensei_Shaman/ForeverSensei_Shaman.toc`; `## Version`) and `ForeverSensei/Core/Init.lua` (`ns.VERSION`) if `reports.py` has not already done so. The core and the packs share one version. Run `make zip`.
5. Commit the addon changes, with no `Co-authored-by` trailer. Do not commit `reports/` (it is gitignored and stays local). Tell the user which zip to send.

## Development

- `make check` runs all offline checks. It needs Python 3 and `pip install --user lupa`, which provides a real Lua 5.1. It loads the core and every class pack in a fake WoW client (`tools/wow_stub.lua`, packs loaded on demand like the game does) and drives every screen, button and command in Japanese and English (`tools/scenarios.lua` for the Shaman, `tools/scenarios_paladin.lua` for the Paladin). It also checks:
  - **texts:** both languages of every locale file have every ID; each ID lives in one file; the core's texts are class-neutral; Japanese rules; font glyphs; placeholders; no raw IDs on screen;
  - **packs:** each pack registers exactly its class with the core's API version; TOC fields; a character without a pack (one note, idle) and a pack with another API version (refused, one note);
  - **data:** spell and talent IDs, names and levels against the Forever client dump in `research/`;
  - **layout:** unique slots and keys, allowed keys only, the exact approved key grid of each pack, every key of the three rows and the mouse bound, each family in its block (`1-5`, `Q-F`, `Z-C` or a mouse pair) with spill-overs on Action Bar 6, Action Bar 4 out-of-combat only, bar fields (only Action Bar 6 in Edit Mode), old-layout leftovers, macro kinds and bodies, macro count, item slots;
  - **items:** potion and elixir data (sources, ids, best-first order);
  - **talents:** one point per level, row requirements, max ranks, final 0/5/46 (Shaman) and 0/32/19 (Paladin);
  - **scenarios:** layout apply → undo round-trip, potion and Healthstone macros, the Lightning Shield stand-in, clearing old-layout leftovers, the update from layout 6 to 7 (notice, apply, undo with bar settings), the login card fix and the one-time layout notice;
  - **Paladin:** the Protection grid and families, the auras on Action Bar 3, the updates from layout 1 to 2 and 2 to 3 (notice, apply, undo), the help macros with and without the self fallback (each help button holds its macro, `/sensei verify` flags a plain spell there), the opener, the Purify stand-in, level 30 and 42 snapshots, and that unverified spells appear nowhere;
  - **reports:** round-trip of the report format (with the pack name), that each ID is written to the file of the pack the report names, and that the zip holds every addon folder at its top level.
- `make zip` builds `dist/ForeverSensei-v<version>.zip` with every addon folder at its top level (unzip straight into `AddOns`).
- Layout of the core (`ForeverSensei/`):
  - `Core/`: init, events, font, settings, UI helpers, locale lookup, class packs (`Class.lua`);
  - `Data/Items.lua`: potions, Healthstones and elixirs every class can use;
  - `Locales/`: `en.lua` is the source, `ja.lua` the translation (class-neutral texts only);
  - `Modules/`: cards, layout, talents, guide, feedback, verify, minimap.
- Layout of a class pack (`ForeverSensei_Shaman/`, `ForeverSensei_Paladin/`):
  - `Data/Spells.lua`, `Data/Ranks.lua`: the class's spells and every rank, each with source and verified date;
  - `Data/<Spec>/`: one folder per spec (`Restoration/`, `Protection/`: key layout, talents, guide);
  - `Locales/`: the pack's own texts (skills, talents, guide, class-specific interface lines);
  - `Register.lua`: hands everything to the core.
- The client is the 12.x API ("Camelot", `## Interface: 16001`). Use `C_*` namespaces and pcall-wrap anything that may not exist. Never touch bars or bindings in combat.

### Adding a class pack

A class pack is a separate addon folder, `ForeverSensei_<Class>`, named from the class file with only the first letter upper case (`WARRIOR` → `ForeverSensei_Warrior`). The core loads it at login with `C_AddOns.LoadAddOn` only on characters of that class. Copy `ForeverSensei_Shaman/` as the starting point.

1. **TOC** (`ForeverSensei_<Class>.toc`): `## Interface: 16001`, `## Version:` the same as the core, `## Dependencies: ForeverSensei`, `## LoadOnDemand: 1`, `## X-ForeverSensei-API: 1` (the core's `ns.API_VERSION`; the core does not load a pack with another value and shows a note), Title, Notes and Notes-jaJP. List the files in this order: `Locales\en.lua`, `Locales\ja.lua`, `Data\*.lua`, `Data\<Spec>\*.lua`, `Register.lua`.
2. **Data** (in the addon's private table, `local _, P = ...`):
   - `P.sources`: source keys for the `src` fields (Forever sources only), added to the core's `wh_spell`, `wh_item`, `ui`;
   - `P.spells`: every class spell with `key`, `id`, `name`, `level`, `role`, `use`, `src` and `verified` (a date); `P.ranks` (generate it from the client dump with `tools/research/gen_ranks.py --class <class>`, after adding the class to its `CLASSES`) and `P.ranksSource`;
   - `P.specs.<SPEC>`: `layout` (bars, `plan`, `families`, allowed keys, `version`, macros, `noSlot`, `spareOrder`, `retired` bars, `old` leftovers; the core builds the slots with `ns.BuildLayout`), `talents` (path; the core builds the order with `ns.BuildTalents`), `guide` and `tabs` (the spec's own guide tabs, shown before the generic ones).
   - Class-specific behaviour goes in the layout data, not in the core: macro kinds and bodies (`macroKind`, `macroBodies`, `macroVars`, e.g. the Shaman's Nature's Swiftness + Healing Wave macro, the Paladin's `help_nofb`), multi-spell macros (`combos`, `"!id"` in the plan, e.g. the Paladin opener), stand-ins (`{ "cleanse", standIn = "purify" }`), spells kept off the bars (`noSlot`, `noSlotLines`, e.g. the Totem Bar or the spellbook), `"x"` for a button the layout never uses, a bar that starts in the middle of the screen (`editMode`), preview warnings (`defaultWarn`), bars an older layout used (`retired`, with `assigned` buttons and `keepShown`), and spells an older layout put in buttons the plan no longer fills (`old`).
3. **Texts:** `Locales/en.lua` and `Locales/ja.lua` with every `spell.<key>.*`, `talent.<key>.*`, `guide.*` and `ui.tab.<tab>` text the pack uses, plus every ID in `ns.PackTexts` (`Core/Class.lua`): interface lines whose wording depends on the class. An ID must not also be in the core. The Japanese follows the rules in "For agents: processing translation reports".
4. **Register.lua:** `ForeverSensei.RegisterClass("<CLASSFILE>", { api = 1, name = "ForeverSensei_<Class>", spells, ranks, ranksSource, sources, items = { ...item macro kinds from Data/Items.lua the layouts use }, locales, localeOrder, defaultSpec = "<SPEC>", specs })`. `defaultSpec` is the spec the core uses; there is no spec picker yet.
5. **Checks:** add the pack's class-specific checks to `PACK_CHECKS` in `tools/check.py` (see `check_shaman` and `check_paladin`: client-dump ranks through `check_client_dump`, the approved key grid, macros), a runtime scenario like `tools/scenarios_paladin.lua` run from `check_runtime`, and its research sources to SOURCES.md. `make check` already loads every `ForeverSensei_*` folder, runs the generic text, data, layout, talent and guide checks on it, and checks its TOC. `make zip` adds it to the release zip.
- The client is the 12.x API ("Camelot", `## Interface: 16001`). Use `C_*` namespaces and pcall-wrap anything that may not exist. Never touch bars or bindings in combat.

## Licence

The code is GPL-2.0-or-later (see [LICENSE](LICENSE)). The bundled font `ForeverSensei/Fonts/ipagui.ttf` (IPA UI Gothic) is under the IPA Font License v1.0 (see `ForeverSensei/Fonts/`).
