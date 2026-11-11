# ForeverSensei

A class coach addon for **World of Warcraft: Forever**, in Japanese or English. It covers the **Restoration Shaman** healer (made for a Skyborne / Horde player) from level 1 to 60.

It comes as two addons, like the voice packs of WoW Forever Japanese:
- `ForeverSensei`: the core (windows, cards, layout engine, talent advisor, guide, translation reports, settings);
- `ForeverSensei_Shaman`: the Shaman class pack (skills, the Restoration key layout, talents and guide texts).

A class pack loads only on characters of its class. Turn off packs you don't play in the AddOns list. On a character whose class has no pack, ForeverSensei shows one short note and stays idle; `/sensei` still opens the translation check and settings.

- **Language (日本語 / English):** the first time the addon runs, a small window asks for the language with two buttons, **日本語** and **English**. Nothing else shows until you choose. The choice is saved for the whole account and kept through updates. Change it any time in the settings tab or with `/sensei ja` / `/sensei en`; open windows switch at once, no `/reload` needed. Players who used a version before 0.5.1 are not asked and keep their language.
- **New skill cards (新しいスキル):** when you learn a skill, a card explains in the chosen language what it does, when to use it, where it goes on your bars, and which key presses it. A **配置する** button puts it there. Hover the icon to see the game's own tooltip. Any card can be opened again from the skill list (**カード** button or the icon), learned or not, and shows whether the skill is already in its slot with its key.
- **Fixed bar layout and keys (キー配置):** every skill has a fixed slot and key, planned for a level-60 dungeon healer, so a key never moves as you level. Only keys near WASD are used: `1-4`, `Q E R F`, `Z X C`, the same keys with Shift or Ctrl, and the two mouse side buttons. The heals have keys without a modifier (`F`, `E`, `R`, Mouse 4, Mouse 5), and spells for the same job share one key with Shift and Ctrl (e.g. `1` / `Shift+1` / `Ctrl+1` move your totems). `5`, `Shift+5` and `Ctrl+5` are yours: the addon never touches them. Your current layout can be replaced in one step (**すべて配置**). You see a preview first, your old bars and keys are backed up, and **元に戻す** restores them. **バーを空にする** first empties only the buttons the layout uses, so the full layout starts clean; your other buttons stay.
- **New ranks:** the game does not put a new rank on the bars, so the addon upgrades bar buttons to the highest rank automatically (after combat if you are fighting), with a toast and **元に戻す** to keep the old rank. It can be turned off in the settings. Healing macros are checked to cast the highest rank too.
- **Healing targeting:** mouseover healing macros, or plain spells for click-target healing. One setting switches between them.
- **Talent advisor (タレント):** when you have an unspent point, it shows the next talent from the Mobalytics build with a short reason, plus the full order.
- **Guide (`/sensei`):** the healer role, healing tips, when to deal damage, totems, group manners, a skill list by level, the key layout, and the talent order.
- **Translation reports (翻訳の報告):** every Japanese line can be reported in-game. The player copies the reports into a chat message to the maintainer, and `make reports` applies them here.

All game facts come from World of Warcraft: Forever sources only (client spell data, Wowhead Forever, Mobalytics Forever), never Classic or Retail. See [SOURCES.md](SOURCES.md), which also lists what can only be checked in the game.

Japanese style follows the [WoW Forever Japanese](https://github.com/zyaga/wow-forever-japanese) addon (WFJ):
- spell, item, talent, place and person names stay in English letters (Chain Heal, Orgrimmar);
- class and race words use the WFJ glossary katakana (シャーマン, トレーナー);
- the tone is friendly plain form (常体).

ForeverSensei works with or without WFJ installed. Without it, ForeverSensei uses its own bundled Japanese font.

## Releases

Download the newest zip from [Releases](https://github.com/oskar-v-karlsson/forever-sensei/releases/latest) (the asset `ForeverSensei-v<version>-<commit>.zip`). It holds every addon folder (`ForeverSensei/` and `ForeverSensei_Shaman/`) at its top level. Every push to `main` makes a release automatically (`.github/workflows/release.yml`). The workflow runs `make check`, builds the zip and publishes it, tagged `v<version>-<short commit>`, e.g. `v0.2.0-5f1a87c`. The newest release is marked **Latest**. If the checks fail, no release is made.

## Install on Windows

1. Get the addon:
   - **Release:** download the zip from [the latest release](https://github.com/oskar-v-karlsson/forever-sensei/releases/latest). On Windows, right-click it → **Extract All**.
   - **Zip:** or run `make zip` and use `dist/ForeverSensei-v<version>.zip`.
   - **Copy:** or copy the `ForeverSensei` and `ForeverSensei_Shaman` folders from this repo.
2. In the **Battle.net** app, choose **World of Warcraft**, then the **Forever** version in the version drop-down. Click the gear next to Play → **Show in Explorer**.
3. Open the game folder for Forever (most likely `_classic_beta_`), then `Interface\AddOns`. If `AddOns` (or `Interface`) is missing, create it.
4. Put both folders, `ForeverSensei` and `ForeverSensei_Shaman`, there. The result must be `...\Interface\AddOns\ForeverSensei\ForeverSensei.toc` and `...\Interface\AddOns\ForeverSensei_Shaman\ForeverSensei_Shaman.toc`. The folders must keep exactly these names and not be nested twice (`ForeverSensei\ForeverSensei\...`), which happens easily with Extract All.
5. Start the game. At character select, open **AddOns** (bottom left), make sure **ForeverSensei** and **ForeverSensei - Shaman** are ticked, and turn on **Load out of date AddOns** if the game asks.

To update, delete the old `ForeverSensei` and `ForeverSensei_Shaman` folders and put the new ones in their place. Your settings and saved reports are kept, because they are stored in `WTF\Account\...\SavedVariables\ForeverSensei.lua`.

## First steps in the game

1. On the very first login, choose **日本語** or **English** in the language window.
2. Type `/sensei`, or click the minimap button, or use the addon compartment (the AddOns button at the minimap). The guide opens.
3. Open **キー配置** (layout), choose how to pick a healing target (**マウスオーバーで回復** or **ターゲットを回復**), then press **すべて配置** to see the preview.
4. The preview lists every slot and key that changes. Press **適用** to apply. `/sensei undo` or the **元に戻す** button restores the old bars and keys.
   To start from empty bars, press **バーを空にする** first (`/sensei clean`). It asks first and empties only the buttons the addon configures: every planned slot (spells, item macros, and slots kept free for spells you haven't learned yet) and the buttons 0.4.0 used on Action Bars 6 and 7. Spare buttons, `5`, `Shift+5` and every other button stay. It saves the bars first, so **元に戻す** puts them back.

   Note: the full layout binds `Q`/`E` (strafe by default), `Shift+1-4` (bar paging by default), `Ctrl+1-4` (stance-bar buttons, e.g. Ghost Wolf), `Ctrl+R` (framerate display) and the mouse side buttons. The preview warns about this.
5. Play. New skills show a card out of combat. Cards wait until combat ends, and bar or key changes started in combat are applied when it ends.

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

### Key layout

The plan is in [research/keybind-layout.md](research/keybind-layout.md) (pull walkthroughs, key families, sources). Each row is one base key; Shift and Ctrl press the same key with a modifier.

| Key | Plain | Shift | Ctrl |
|---|---|---|---|
| 1 | Totemic Call | Call of the Elements | Totemic Recall |
| 2 | Flame Shock | – | – |
| 3 | Lightning Bolt | Purge | – |
| 4 | Chain Lightning | – | – |
| 5 | yours | yours | yours |
| Q | Earth Shock (interrupt) | Frost Shock | Earthbind Totem |
| E | Lesser Healing Wave | Stoneskin Totem | Stoneclaw Totem |
| R | Chain Heal | Searing Totem | – |
| F | Healing Wave | Tremor Totem | Grounding Totem |
| Z | Mana Potion | Mana Spring Totem | Mana Tide Totem |
| X | Water Shield (Lightning Shield before level 20) | – | – |
| C | Healthstone, else Healing Potion | – | Ghost Wolf |
| Mouse 4 | Riptide | Cure Poison | Poison Cleansing Totem |
| Mouse 5 | Nature's Swiftness + Healing Wave | Cure Disease | Disease Cleansing Totem |

- Plain keys are the main bar, Shift keys Action Bar 2 and Ctrl keys Action Bar 5 (at the right edge of the screen). The three rows use the same order: buttons 1-12 are `1`, `2`, `3`, `4`, `5`, `Q`, `E`, `R`, `F`, `Z`, `X`, `C`, plain, with Shift or with Ctrl. The mouse buttons use the right half of Action Bar 3: buttons 7-12 are `Mouse 4`, `Mouse 5`, `Shift+Mouse 4/5`, `Ctrl+Mouse 4/5`. **すべて配置** turns on Action Bars 2-5, because a hidden bar may not react to its keys.
- Action Bars 6 and 7 are not used. Version 0.4.0 put the Ctrl and mouse spells there, in the middle of the screen. **すべて配置** now clears those spells from them, hides both bars and removes keys that still point at their buttons (not your `Ctrl+5`).
- A key whose spell you learn later (e.g. Chain Heal and Riptide at 40) stays empty until then. Keys never move.
- The keys with `–` have no skill. They are still bound to their (empty) button, so every row has all 12 keys: `Shift+2`, `Shift+4`, `Shift+X`, `Shift+C`, `Ctrl+2`, `Ctrl+3`, `Ctrl+4`, `Ctrl+R` and `Ctrl+X`. You can put your own things there; **すべて配置** only binds the key and leaves the button alone.
- **Mouse side buttons:** leave them as the default Button 4 and Button 5 in your mouse software (no "back/forward" or other remapping), so the game sees `BUTTON4` and `BUTTON5`.
- Totem flow in a dungeon: `1` Totemic Call at every pull brings your totems along; `Shift+1` Call of the Elements when the 5-minute totems run out (about every few pulls) and after a wipe; `Shift+R` Searing at every pull (it lasts 30-55 s); `Ctrl+1` Totemic Recall when you leave. Before level 22 (no Call of the Elements yet), put down Stoneskin and Searing by hand.

The other buttons have no keys. They are for clicking:
- bar 3, buttons 1-6: Rockbiter, Flametongue and Windfury Weapon, Lightning Shield (after Water Shield), the Arcane Elixir and Healing Potion buttons;
- bar 4: Ancestral Spirit, Astral Recall, Strength of Earth, Healing Stream Totem, Fire Nova, Windfury, Grace of Air, Magma and Flametongue Totem, the Call of the Ancestors and Call of the Spirits totem sets, and one spare button.
- Only in the spellbook (no button, rarely needed): Far Sight and Sentry Totem (scouting), Water Breathing and Water Walking (travel), Frostbrand Weapon (a solo imbue that slows runners; a healer uses Rockbiter or Flametongue).

Anything that was on a planned slot moves to the spare buttons first (bar 3, then the free Shift buttons of Action Bar 2).

The item buttons are character macros the addon keeps up to date: `FS_MANA` (Mana Potion), `FS_HEALTH` (Healthstone, else Healing Potion), `FS_HEALPOT` (Healing Potion) and `FS_ELIXIR` (Arcane Elixir, e.g. Minor Arcane Elixir). Each uses the best one of its kind in your bags that your level allows. They are only changed out of combat (after looting, or when combat ends). With none in the bags, the button keeps a fixed icon. The items are listed in `ForeverSensei/Data/Items.lua`.

Players who applied an older layout get a one-time message after updating, with a **すべて配置** button that opens the usual preview. Nothing moves by itself.

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

## In-game test checklist

These cannot be tested outside the game. Please go through them once, then paste the chat output of step 1 back to the repo owner.

1. [ ] `/sensei verify` opens a window that starts with `problems: <n>`. Press Ctrl+C in the window and send the text.
2. [ ] **Font, fresh launch:** fully quit the game and start it again (not `/reload`). Japanese shows in the guide and cards, with no boxes or `?`. Test once with WFJ enabled and once without.
3. [ ] Learning a skill at the trainer (or a level-up skill) shows a card out of combat. Hovering the icon shows the game tooltip.
4. [ ] **配置する** on a card puts the skill in its slot and binds the key, and asks first if the slot is used.
5. [ ] **すべて配置:** the preview is shown, **適用** changes the bars and keys, Action Bars 2-5 become visible (6 and 7 stay hidden), and `/reload` keeps everything. `5`, `Shift+5` and `Ctrl+5` and their buttons are unchanged.
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
17. [ ] After **すべて配置**: `1` Totemic Call, `Shift+1` Call of the Elements and `Ctrl+1` Totemic Recall work; `Shift+E`, `Shift+R`, `Shift+F` put down Stoneskin, Searing and Tremor. Note the mana cost of Call of the Elements with a full set.
18. [ ] **Potions:** `Z` drinks the best mana potion in the bags. Loot or buy a better one: the button changes to it after combat (or right away out of combat). The healing potion and Arcane Elixir buttons on bar 3 work by clicking. With none in the bags, the buttons show a potion icon (no question mark). `/sensei verify` lists `FS_MANA`, `FS_HEALTH`, `FS_HEALPOT` and `FS_ELIXIR` under [Layout] with no `bad` lines.
19. [ ] **Ctrl and mouse keys:** after **すべて配置**, Action Bar 5 at the right edge has the Ctrl keys in the same order as Action Bar 2 (Ctrl+1 Totemic Recall on button 1, Ctrl+C Ghost Wolf on button 12), and the right half of Action Bar 3 holds the mouse spells (buttons 7-12). Every Ctrl key and `Mouse 4`, `Mouse 5`, `Shift+Mouse 4/5`, `Ctrl+Mouse 4/5` cast their spells. `Ctrl+2`, `Ctrl+3`, `Ctrl+4`, `Ctrl+R` and `Ctrl+X` press their empty Action Bar 5 button (put a skill there to test; the framerate no longer toggles on `Ctrl+R`). The mouse side buttons are set to the default Button 4/5 in the mouse software. `/sensei verify` shows the bindings of `CTRL-2`, `CTRL-R`, `CTRL-X`, `SHIFT-BUTTON4`, `CTRL-BUTTON4` and of `5`, `SHIFT-5`, `CTRL-5`.
20. [ ] **Ctrl+1 over the stance bar:** with Ghost Wolf on the stance bar, `Ctrl+1` casts Totemic Recall (not Ghost Wolf), and `Ctrl+C` casts Ghost Wolf.
21. [ ] **Macros:** `Q` (FS_ES) during your own cast stops it and interrupts at once. `Mouse 5` (FS_NSHW) casts an instant Healing Wave in one press, and a normal one while Nature's Swiftness is on cooldown. `Shift+3` (FS_PURGE) purges the enemy under the mouse.
22. [ ] **Healthstone:** `C` uses a Healthstone if you have one, else the best Healing Potion. Check whether the Healthstone and potions share a cooldown.
23. [ ] **Levelling:** below level 20, `X` holds Lightning Shield; after learning Water Shield and **配置する**, `X` holds Water Shield and Lightning Shield moves to bar 3. A key whose spell is not learned yet stays empty.
24. [ ] **Totem Bar:** the addon does not set up the Totem Bar (3 pages of 4 totems for Call of the Elements/Ancestors/Spirits). Set it up by hand and check that Call of the Elements puts down that set.
25. [ ] **Update from 0.4.0:** with the 0.4.0 layout applied (Action Bars 6 and 7 in the middle of the screen), the first login shows the layout message once. **すべて配置** lists Action Bars 6 and 7 under the bars to hide; after **適用** they are gone, the Ctrl and mouse keys work from Action Bar 5, and nothing is left over the character. **元に戻す** brings bars 6 and 7 back as they were.
26. [ ] **Update from 0.4.2:** the first login shows the layout message once. The preview lists the Ctrl spells moving to their new Action Bar 5 buttons, the mouse spells moving to Action Bar 3, the new empty-button keys, and Far Sight, Sentry Totem, Water Breathing, Water Walking and Frostbrand Weapon leaving the bars (they stay in the spellbook). The `Ctrl+5` button is cleared if it still holds the Mana Tide Totem that 0.4.2 put there (Mana Tide is now on `Ctrl+Z`); anything else you put there stays. **元に戻す** restores it all.
27. [ ] **バーを空にする:** put a few things of your own on planned buttons, on spare buttons (e.g. the free buttons of Action Bar 3) and on `5` and `Shift+5`. The button asks first; after confirming, only the planned buttons are empty, and the spare buttons, `5`, `Shift+5` and the other bars are unchanged. **元に戻す** puts everything back. Out of combat only: in combat it says to try again after the fight.
28. [ ] **Class pack (0.5.0):** the AddOns list shows **ForeverSensei** and **ForeverSensei - Shaman**. On the Shaman, everything works as in 0.4.3: cards, layout, talents, guide tabs, no new layout message, review progress and saved reports kept, Totem Bar unchanged. `/sensei verify` has no `bad` lines.
29. [ ] **No pack:** turn off **ForeverSensei - Shaman** (or log in on a character of another class). The first login shows one short note that the class pack is missing, and `/reload` does not show it again. `/sensei` opens with only the translation check and settings tabs; no cards, toasts or layout messages appear. Turn the pack back on afterwards.
30. [ ] **Language window (0.5.1):** on a test account (or after renaming `ForeverSensei.lua` in `WTF\Account\...\SavedVariables`), the first login shows only the language window: no skill card, welcome message, layout message or pack note. **English** switches everything to English at once and the welcome message follows; after `/reload` and after an update the window does not come back. Erika's account (data from 0.5.0) is not asked and stays Japanese. With the guide and a skill card open, `/sensei en` and `/sensei ja` switch their texts without `/reload`.

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
2. For each entry in `reports/open.md`, write a better Japanese line in the `ja.lua` that owns the ID. Each ID lives in exactly one file: skill (`spell.*`), talent (`talent.*`), guide (`guide.*`) and class-specific `ui.*` texts are in the class pack (`ForeverSensei_Shaman/Locales/ja.lua`); all other `ui.*` texts are in the core (`ForeverSensei/Locales/ja.lua`). `grep -rn '"<id>"' ForeverSensei*/Locales/ja.lua` finds it; `reports.py` routes suggestions the same way.
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
4. Delete the handled entries from `reports/open.md`. Bump the patch version in every TOC (`ForeverSensei/ForeverSensei.toc`, `ForeverSensei_Shaman/ForeverSensei_Shaman.toc`; `## Version`) and `ForeverSensei/Core/Init.lua` (`ns.VERSION`) if `reports.py` has not already done so. The core and the packs share one version. Run `make zip`.
5. Commit the addon changes, with no `Co-authored-by` trailer. Do not commit `reports/` (it is gitignored and stays local). Tell the user which zip to send.

## Development

- `make check` runs all offline checks. It needs Python 3 and `pip install --user lupa`, which provides a real Lua 5.1. It loads the core and every class pack in a fake WoW client (`tools/wow_stub.lua`, packs loaded on demand like the game does) and drives every screen, button and command in Japanese and English (`tools/scenarios.lua`). It also checks:
  - **texts:** both languages of every locale file have every ID; each ID lives in one file; the core's texts are class-neutral; Japanese rules; font glyphs; placeholders; no raw IDs on screen;
  - **packs:** each pack registers exactly its class with the core's API version; TOC fields; a character without a pack (one note, idle) and a pack with another API version (refused, one note);
  - **data:** spell and talent IDs, names and levels against the Forever client dump in `research/`;
  - **layout:** unique slots and keys, allowed keys only, the exact approved key grid, key families, the player's own keys (`5`, `Shift+5`, `Ctrl+5`) never used, Ctrl/mouse bar fields, macro kinds and bodies, macro count, item slots;
  - **items:** potion and elixir data (sources, ids, best-first order);
  - **talents:** one point per level, row requirements, max ranks, final 0/5/46;
  - **scenarios:** layout apply → undo round-trip, potion and Healthstone macros, the Lightning Shield stand-in, clearing layout-2 leftovers, the login card fix and the one-time layout notice;
  - **reports:** round-trip of the report format, and that each ID is written to the file that owns it.
- `make zip` builds `dist/ForeverSensei-v<version>.zip` with every addon folder at its top level (unzip straight into `AddOns`).
- Layout of the core (`ForeverSensei/`):
  - `Core/`: init, events, font, settings, UI helpers, locale lookup, class packs (`Class.lua`);
  - `Data/Items.lua`: potions, Healthstones and elixirs every class can use;
  - `Locales/`: `en.lua` is the source, `ja.lua` the translation (class-neutral texts only);
  - `Modules/`: cards, layout, talents, guide, feedback, verify, minimap.
- Layout of a class pack (`ForeverSensei_Shaman/`):
  - `Data/Spells.lua`, `Data/Ranks.lua`: the class's spells and every rank, each with source and verified date;
  - `Data/<Spec>/`: one folder per spec (`Restoration/`: key layout, talents, guide);
  - `Locales/`: the pack's own texts (skills, talents, guide, class-specific interface lines);
  - `Register.lua`: hands everything to the core.
- The client is the 12.x API ("Camelot", `## Interface: 16001`). Use `C_*` namespaces and pcall-wrap anything that may not exist. Never touch bars or bindings in combat.

### Adding a class pack

A class pack is a separate addon folder, `ForeverSensei_<Class>`, named from the class file with only the first letter upper case (`WARRIOR` → `ForeverSensei_Warrior`). The core loads it at login with `C_AddOns.LoadAddOn` only on characters of that class. Copy `ForeverSensei_Shaman/` as the starting point.

1. **TOC** (`ForeverSensei_<Class>.toc`): `## Interface: 16001`, `## Version:` the same as the core, `## Dependencies: ForeverSensei`, `## LoadOnDemand: 1`, `## X-ForeverSensei-API: 1` (the core's `ns.API_VERSION`; the core does not load a pack with another value and shows a note), Title, Notes and Notes-jaJP. List the files in this order: `Locales\en.lua`, `Locales\ja.lua`, `Data\*.lua`, `Data\<Spec>\*.lua`, `Register.lua`.
2. **Data** (in the addon's private table, `local _, P = ...`):
   - `P.sources`: source keys for the `src` fields (Forever sources only), added to the core's `wh_spell`, `wh_item`, `ui`;
   - `P.spells`: every class spell with `key`, `id`, `name`, `level`, `role`, `use`, `src` and `verified` (a date); `P.ranks` (generate it from the client dump like `tools/research/gen_ranks.py`) and `P.ranksSource`;
   - `P.specs.<SPEC>`: `layout` (bars, `plan`, allowed and own keys, `version`, macros, `noSlot`, `spareOrder`; the core builds the slots with `ns.BuildLayout`), `talents` (path; the core builds the order with `ns.BuildTalents`), `guide` and `tabs` (the spec's own guide tabs, shown before the generic ones).
   - Class-specific behaviour goes in the layout data, not in the core: macro kinds and bodies (`macroKind`, `macroBodies`, `macroVars`, e.g. the Shaman's Nature's Swiftness + Healing Wave macro), spells kept off the bars (`noSlot`, `noSlotLines`, e.g. the Totem Bar), and buttons an older layout version put on the player's own keys (`oldOwn`).
3. **Texts:** `Locales/en.lua` and `Locales/ja.lua` with every `spell.<key>.*`, `talent.<key>.*`, `guide.*` and `ui.tab.<tab>` text the pack uses, plus every ID in `ns.PackTexts` (`Core/Class.lua`): interface lines whose wording depends on the class. An ID must not also be in the core. The Japanese follows the rules in "For agents: processing translation reports".
4. **Register.lua:** `ForeverSensei.RegisterClass("<CLASSFILE>", { api = 1, name = "ForeverSensei_<Class>", spells, ranks, ranksSource, sources, items = { ...item macro kinds from Data/Items.lua the layouts use }, locales, localeOrder, defaultSpec = "<SPEC>", specs })`. `defaultSpec` is the spec the core uses; there is no spec picker yet.
5. **Checks:** add the pack's class-specific checks to `PACK_CHECKS` in `tools/check.py` (see `check_shaman`: client-dump ranks, the approved key grid, macros) and its research sources to SOURCES.md. `make check` already loads every `ForeverSensei_*` folder, runs the generic text, data, layout, talent and guide checks on it, and checks its TOC. `make zip` adds it to the release zip.
- The client is the 12.x API ("Camelot", `## Interface: 16001`). Use `C_*` namespaces and pcall-wrap anything that may not exist. Never touch bars or bindings in combat.

## Licence

The code is GPL-2.0-or-later (see [LICENSE](LICENSE)). The bundled font `ForeverSensei/Fonts/ipagui.ttf` (IPA UI Gothic) is under the IPA Font License v1.0 (see `ForeverSensei/Fonts/`).
