# ForeverSensei

A Japanese class coach addon for **World of Warcraft: Forever**. Version 1 covers the **Restoration Shaman** healer (made for a Skyborne / Horde player) from level 1 to 60.

- **New skill cards (新しいスキル):** when you learn a skill, a card explains in Japanese what it does, when to use it, where it goes on your bars, and which key presses it. A **配置する** button puts it there. Hover the icon to see the game's own tooltip. Any card can be opened again from the skill list (**カード** button or the icon), learned or not, and shows whether the skill is already in its slot with its key.
- **Fixed bar layout and keys (キー配置):** every skill has a fixed slot, and only small-hand keys are used: `1-5`, `Q E R F`, `Z X C` and the same keys with Shift. Your current layout can be replaced in one step (**すべて配置**). You see a preview first, your old bars and keys are backed up, and **元に戻す** restores them.
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

Download the newest zip from [Releases](https://github.com/oskar-v-karlsson/forever-sensei/releases/latest) (the asset `ForeverSensei-v<version>-<commit>.zip`). Every push to `main` makes a release automatically (`.github/workflows/release.yml`). The workflow runs `make check`, builds the zip and publishes it, tagged `v<version>-<short commit>`, e.g. `v0.2.0-5f1a87c`. The newest release is marked **Latest**. If the checks fail, no release is made.

## Install on Windows

1. Get the addon:
   - **Release:** download the zip from [the latest release](https://github.com/oskar-v-karlsson/forever-sensei/releases/latest). On Windows, right-click it → **Extract All**.
   - **Zip:** or run `make zip` and use `dist/ForeverSensei-v<version>.zip`.
   - **Copy:** or copy the `ForeverSensei` folder from this repo.
2. In the **Battle.net** app, choose **World of Warcraft**, then the **Forever** version in the version drop-down. Click the gear next to Play → **Show in Explorer**.
3. Open the game folder for Forever (most likely `_classic_beta_`), then `Interface\AddOns`. If `AddOns` (or `Interface`) is missing, create it.
4. Put the `ForeverSensei` folder there. The result must be `...\Interface\AddOns\ForeverSensei\ForeverSensei.toc`. The folder must be named exactly `ForeverSensei`, and not nested twice (`ForeverSensei\ForeverSensei\...`), which happens easily with Extract All.
5. Start the game. At character select, open **AddOns** (bottom left), make sure **ForeverSensei** is ticked, and turn on **Load out of date AddOns** if the game asks.

To update, delete the old `ForeverSensei` folder and put the new one in its place. Your settings and saved reports are kept, because they are stored in `WTF\Account\...\SavedVariables\ForeverSensei.lua`.

## First steps in the game

1. Type `/sensei`, or click the minimap button, or use the addon compartment (the AddOns button at the minimap). The guide opens.
2. Open **キー配置** (layout), choose how to pick a healing target (**マウスオーバーで回復** or **ターゲットを回復**), then press **すべて配置** to see the preview.
3. The preview lists every slot and key that changes. Press **適用** to apply. `/sensei undo` or the **元に戻す** button restores the old bars and keys.

   Note: the full layout binds `Q`/`E` (strafe by default) and `Shift+1-5` (bar paging by default). The preview warns about this.
4. Play. New skills show a card out of combat. Cards wait until combat ends, and bar or key changes started in combat are applied when it ends.

The game's 12.x API hides health, cooldowns and auras from addons in combat, so ForeverSensei only coaches outside combat. It has no rotation helper.

### Commands

| Command | What it does |
|---|---|
| `/sensei` | Open the guide (`/foreversensei` also works) |
| `/sensei skills` | Skill list by level: learned, not learned, and slot. **カード** opens the skill's card. |
| `/sensei layout` | Key layout tab |
| `/sensei apply` / `/sensei undo` | Apply the full layout (with preview) / restore the backup |
| `/sensei talents` | Talent advice; `/sensei order` shows the full order |
| `/sensei trainer` | Skills available at the trainer for your level |
| `/sensei card <Spell>` | Show the card for a spell (English name, e.g. `/sensei card Chain Heal`) |
| `/sensei review` | Translation check tab (mark each text OK or report it) |
| `/sensei report` | Send translation reports (copy box) |
| `/sensei settings` | Settings |
| `/sensei verify` | Check every spell and talent in the data against the live client |
| `/sensei en` / `/sensei ja` | Interface language (English is for testing) |
| `/sensei debug` | Toggle debug output |

### Key layout

The **Main** bar (row 1) has no modifier. **Bar 2** (row 2) uses Shift plus the same key.

| Key | 1 | 2 | 3 | 4 | 5 | Q | E | R | F | Z | X | C |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Main | Healing Wave | Lesser Healing Wave | Chain Heal | Riptide | Nature's Swiftness | Lightning Bolt | Earth Shock | Flame Shock | Chain Lightning | Water Shield | Healing Stream Totem | Call of the Elements |
| Shift + (bar 2) | Cure Poison | Cure Disease | Purge | Mana Tide Totem | Mana Spring Totem | Frost Shock | Searing Totem | Fire Nova | Earthbind Totem | Lightning Shield | Strength of Earth Totem | Ghost Wolf |

Bars 3 and 4 have no keys. They hold click-only skills:
- weapon imbues;
- situational totems;
- Totemic Recall and Totemic Call;
- the Call of the Ancestors and Call of the Spirits totem sets;
- Ancestral Spirit, Astral Recall, Water Walking, Water Breathing and Far Sight.

The resistance totems and Windwall Totem are used from the Totem Bar or spellbook. Reincarnation is passive. The source of truth is `ForeverSensei/Data/Shaman/Layout.lua`.

In mouseover mode, these buttons become account macros named `FS_HW`, `FS_LHW`, `FS_CH`, `FS_RT`, `FS_CP` and `FS_CD`:
- Healing Wave, Lesser Healing Wave, Chain Heal and Riptide;
- Cure Poison and Cure Disease.

Each macro is:
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
5. [ ] **すべて配置:** the preview is shown, **適用** changes the bars and keys, bars 2-4 become visible, and `/reload` keeps everything.
6. [ ] **元に戻す** / `/sensei undo` restores the old bars and keys.
7. [ ] Mouseover mode: hovering a party frame and pressing `1` heals that player. With no mouseover, it heals the target. With no friendly target, it heals you.
8. [ ] Switching to **ターゲットを回復** replaces the macros with plain spells in the same slots, and back again.
9. [ ] Learning a higher rank (out of combat, or right after combat) changes the bar buttons to it and shows a toast. **元に戻す** on the toast puts the old rank back and keeps it. A mouseover macro (e.g. Healing Wave on `1`) casts the new rank: in `/sensei verify`, the macro lines under [Layout] show the same id after `casts` and `highest known`, and there is no `macro does not cast the highest rank` line. The game itself does not upgrade bar buttons (seen in game, v0.1.0).
10. [ ] Long texts (talent hint, cards, trainer list, report window) stay inside their windows, and the skill list's **カード** button opens the card with a working **配置する**.
11. [ ] At level 10 and later, an unspent talent point shows the next talent hint. **タレントを開く** opens the talent window, and the advice matches what is already spent.
12. [ ] Entering combat hides an open skill card, trainer list and talent hint. They come back after combat. A layout change started in combat is applied after combat.
13. [ ] Translation report flow (below) works: save, send, copy, mark as sent.
14. [ ] The minimap button can be dragged and hidden in settings, and the addon compartment entry works.

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

   If anything changed, it also bumps the patch version (TOC and `Core/Init.lua`), runs `make check`, and builds `dist/ForeverSensei-v<version>.zip`.
3. Handle `reports/open.md` (or ask an agent to, see below). Then commit the changed addon files (not `reports/`) and send the player the new zip.

### For agents: processing translation reports

When the user pastes a report block (starting `[ForeverSensei v`) or asks you to handle `reports/open.md`:

1. If it was pasted in chat, save it to a temporary file and run `python3 tools/reports.py --file <file>`. This applies valid suggestions and adds the rest to `reports/open.md`.
2. For each entry in `reports/open.md`, write a better Japanese line in `ForeverSensei/Locales/ja.lua`.
   - **Keep the format.** Edit only that ID's line. Keep one entry per line: `  ["id"] = "...",`.
   - **Read the sources.** Use the English source in `Locales/en.lua`; it is the fact source. Do not add facts that are not in the English text. If the English is wrong, fix it too, from a Forever source (see SOURCES.md).
   - **Names stay in English letters,** exactly as in the English text: spells, talents, items, places, people.
   - **Glossary katakana for game words:** シャーマン, トレーナー, トーテム, タレント, アクションバー, マウスオーバー, クエスト. Follow the WFJ glossary (`docs/glossary.md`, `pipeline/translation_glossary.tsv`) and style guide (`docs/content/translation-style-guide.md`) in [zyaga/wow-forever-japanese](https://github.com/zyaga/wow-forever-japanese).
   - **Avoid** ヘルス (use 体力), 知性 (use 知力) and 役割 (use ロール).
   - **Plain form (常体):** facts end like `回復する。`, advice ends like `使おう。` No です/ます, no slang.
   - **Punctuation:** use 、 and 。 No `/` (except in `/sensei` commands) and no `...`. Use `〜` for ranges (`1〜5`) and `・` between key names (`Q・E・R・F`).
   - **Placeholders:** keep every `{placeholder}` from the English text.
   - **Length:** keep it about as short as the current text. Card texts must fit the card.
   - **The player's note** says what was wrong; fix exactly that.
3. Run `make check`. It checks the text rules, font glyphs, placeholders and length, and runs every screen in a fake client. Fix anything it reports.
4. Delete the handled entries from `reports/open.md`. Bump the patch version in `ForeverSensei/ForeverSensei.toc` (`## Version`) and `ForeverSensei/Core/Init.lua` (`ns.VERSION`) if `reports.py` has not already done so. Run `make zip`.
5. Commit the addon changes, with no `Co-authored-by` trailer. Do not commit `reports/` (it is gitignored and stays local). Tell the user which zip to send.

## Development

- `make check` runs all offline checks. It needs Python 3 and `pip install --user lupa`, which provides a real Lua 5.1. It loads the whole addon in a fake WoW client (`tools/wow_stub.lua`) and drives every screen, button and command in Japanese and English (`tools/scenarios.lua`). It also checks:
  - **texts:** both languages have every ID; Japanese rules; font glyphs; placeholders; no raw IDs on screen;
  - **data:** spell and talent IDs, names and levels against the Forever client dump in `research/`;
  - **layout:** unique slots and keys, allowed keys only, heals on 1-5;
  - **talents:** one point per level, row requirements, max ranks, final 0/5/46;
  - **layout scenario:** apply → undo round-trip;
  - **reports:** round-trip of the report format.
- `make zip` builds `dist/ForeverSensei-v<version>.zip`.
- Layout of the addon:
  - `Core/`: init, events, font, settings, UI helpers;
  - `Data/Shaman/`: spells, layout, talents and guide, each with source and verified date;
  - `Locales/`: `en.lua` is the source, `ja.lua` the translation;
  - `Modules/`: cards, layout, talents, guide, feedback, verify, minimap.
- New classes go in `Data/<Class>/` with the same structure.
- The client is the 12.x API ("Camelot", `## Interface: 16001`). Use `C_*` namespaces and pcall-wrap anything that may not exist. Never touch bars or bindings in combat.

## Licence

The code is GPL-2.0-or-later (see [LICENSE](LICENSE)). The bundled font `ForeverSensei/Fonts/ipagui.ttf` (IPA UI Gothic) is under the IPA Font License v1.0 (see `ForeverSensei/Fonts/`).
