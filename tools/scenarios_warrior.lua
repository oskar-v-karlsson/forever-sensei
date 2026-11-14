-- tools/scenarios_warrior.lua: the Arms Warrior flow inside the fake client (tools/wow_stub.lua), like
-- tools/scenarios_paladin.lua. The character is a Tauren (tools/check.py sets STUB.race). The pack is English only.
-- Returns run(ns, lang) → { errors = {...}, notes = {...} }.
return function(ns, lang)
  local errors, notes = {}, {}
  local function fail(msg) table.insert(errors, "[warrior " .. lang .. "] " .. msg) end
  local function try(label, fn, ...)
    local ok, err = pcall(fn, ...)
    if not ok then fail(label .. ": " .. tostring(err)) end
    STUB.runTimers()
    return ok
  end
  ns.settings.language = lang
  if not ns.Active() or ns.class.classFile ~= "WARRIOR" or ns.specId ~= "ARMS" then
    fail("class pack: ForeverSensei_Warrior (Arms) is not active")
    return { errors = errors, notes = notes }
  end
  local L = ns.spec.layout
  local layoutFails = 0
  local function fits(label, frame)
    if type(frame) == "string" then frame = _G[frame] end
    if not frame or not frame:IsShown() then return end
    for _, p in ipairs(STUB.checkLayout(frame)) do
      layoutFails = layoutFails + 1
      if layoutFails <= 25 then fail("layout " .. label .. ": " .. p) end
    end
  end
  local function shownHas(text)
    for _, t in ipairs(STUB.shown) do
      if type(t) == "string" and t:find(text, 1, true) then return true end
    end
    return false
  end

  -- English only: with Japanese chosen the pack's texts are its English ones, and a toast says so once.
  local enWhat = ns.class.locales.en["spell.overpower.what"]
  if not enWhat or ns.class.locales.ja then fail("locales: the pack must have English and no Japanese") end
  if ns.T("spell.overpower.what") ~= enWhat then fail("texts: Overpower's card text is not the English one") end
  if lang == "ja" then
    if not shownHas(ns.T("ui.pack.enonly")) then fail("ja: no note that this class's texts are in English") end
    if not ns.char.enOnlyNote then fail("ja: the English-only note is not remembered") end
  elseif ns.char.enOnlyNote then
    fail("en: the English-only note was shown")
  end

  -- Cards for every skill, the trainer list for every level, every guide tab, the talent hint.
  for _, e in ipairs(ns.Spells.List()) do
    try("card " .. e.key, ns.NewSkill.ShowCard, e)
    fits("card " .. e.key, "ForeverSenseiCard")
  end
  _G.ForeverSenseiCard:Hide()
  for lv = 1, 60 do
    try("trainer " .. lv, ns.NewSkill.ShowTrainer, lv)
    fits("trainer " .. lv, "ForeverSenseiTrainer")
  end
  local tabs = { "role", "rotation", "stances", "rage", "cooldowns", "manners", "skills", "layout", "talents", "review",
    "settings" }
  local got = ns.Guide.Tabs()
  if table.concat(got, ",") ~= table.concat(tabs, ",") then fail("guide tabs: " .. table.concat(got, ",")) end
  for _, tab in ipairs(tabs) do
    try("guide " .. tab, ns.Guide.Open, tab)
    if ns.Guide.Current() ~= tab then fail("guide: tab " .. tab .. " did not open") end
  end
  try("guide layout", ns.Guide.Open, "layout")
  if not shownHas(ns.T("ui.layout.editmode")) then fail("guide layout: no Edit Mode note for Action Bar 6") end
  if not shownHas("Battle Stance") then fail("guide layout: the key page does not name the stances") end
  for lv = 10, 60, 5 do
    STUB.level, STUB.unspent = lv, 1
    try("talent hint " .. lv, ns.Talents.ShowHint, true)
    fits("talent hint " .. lv, "ForeverSenseiTalentHint")
  end
  STUB.unspent = 0
  local T = ns.spec.talents
  if #T.order ~= 51 then fail("talents: " .. #T.order .. " points in the order, expected 51 (10-60)") end
  for lv, key in pairs({ [10] = "improved_rend", [18] = "deep_wounds", [23] = "impale", [28] = "spearing_strike",
    [29] = "sweeping_strikes", [39] = "mortal_strike", [51] = "enrage", [56] = "reckless_swings", [60] = "improved_execute" }) do
    if T.order[lv - 9].key ~= key then fail("talents: level " .. lv .. " should be " .. key) end
  end
  for _, lv in ipairs({ 10, 23, 39, 60 }) do
    local ranks = {}
    for i = 1, lv - 10 do ranks[T.order[i].key] = (ranks[T.order[i].key] or 0) + 1 end
    local nodes = {}
    for _, t in ipairs(T.list) do table.insert(nodes, { spell = t.id, rank = ranks[t.key] or 0, max = t.max }) end
    STUB.traits, STUB.level = { nodes = nodes, unspent = 1 }, lv
    local s = ns.Talents.State()
    local want = T.order[lv - 9]
    if not s.readable or not s.next or s.next.key ~= want.key or s.next.rank ~= want.rank then
      fail("talents: level " .. lv .. " next " .. tostring(s.next and s.next.key) .. ", expected " .. want.key)
    end
    try("talent hint traits " .. lv, ns.Talents.ShowHint, true)
    fits("talent hint traits " .. lv, "ForeverSenseiTalentHint")
  end
  STUB.traits = nil

  -- Helpers.
  local function snapshot()
    local a, b = {}, {}
    for k, v in pairs(STUB.actions) do a[k] = v[1] .. ":" .. tostring(v[2]) end
    for k, v in pairs(STUB.bindings) do b[k] = v end
    return a, b
  end
  local function same(x, y)
    for k, v in pairs(x) do if y[k] ~= v then return false, tostring(k) .. " " .. tostring(v) .. " vs " .. tostring(y[k]) end end
    for k, v in pairs(y) do if x[k] ~= v then return false, tostring(k) .. " " .. tostring(x[k]) .. " vs " .. tostring(v) end end
    return true
  end
  local function macroAt(slot)
    local a = STUB.actions[slot]
    return a and a[1] == "macro" and STUB.macros[a[2]] or nil
  end
  local function bodyOf(key)
    local m = macroAt(L.bySpell[key].slot)
    return m and m.body or ""
  end
  local function act(slot)
    local a = STUB.actions[slot]
    return a and (a[1] .. ":" .. tostring(a[2])) or "-"
  end
  -- Every stance page of Action Bar 1 (Battle 73-84, Defensive 85-96, Berserker 97-108) holds what slots 1-12 hold.
  local function pagesSame(what)
    for _, page in ipairs(L.stancePages) do
      for b = 1, 12 do
        if act(page.first + b - 1) ~= act(b) then
          fail(what .. ": " .. page.spell .. " page button " .. b .. " holds " .. act(page.first + b - 1) .. ", Action Bar 1 " .. act(b))
        end
      end
    end
  end
  local function checkLayout(mode)
    local mirrors = 0
    for _, s in ipairs(L.slots) do
      local d = ns.Layout.DesiredFor(s)
      local a = STUB.actions[s.slot]
      local label = s.spell or s.item or s.combo
      if s.mirror then mirrors = mirrors + 1 end
      if not d then
        if a then fail(mode .. ": slot " .. s.slot .. " (" .. label .. ") should stay empty") end
      elseif not a then
        fail(mode .. ": slot " .. s.slot .. " empty, expected " .. label)
      elseif d.kind == "macro" then
        local m = macroAt(s.slot)
        if not m or m.name ~= d.macro then fail(mode .. ": slot " .. s.slot .. " should hold macro " .. d.macro) end
      elseif a[1] ~= "spell" or STUB.names[a[2]] ~= d.entry.name then
        fail(mode .. ": slot " .. s.slot .. " holds " .. tostring(a[2]) .. ", expected " .. d.entry.name)
      end
      if s.mirror and s.key then fail(mode .. ": stance page slot " .. s.slot .. " has a key") end
      if d and s.key and STUB.bindings[s.key] ~= s.binding then
        fail(mode .. ": key " .. s.key .. " bound to " .. tostring(STUB.bindings[s.key]) .. ", expected " .. s.binding)
      end
    end
    if mirrors ~= 36 then fail(mode .. ": " .. mirrors .. " stance page slots, expected 36 (3 pages of 12)") end
    for _, sp in ipairs(L.spare) do
      if sp.key and STUB.bindings[sp.key] ~= sp.binding then fail(mode .. ": spare key " .. sp.key .. " not bound") end
    end
    for _, bar in ipairs(L.bars) do
      if bar.setting and STUB.settings[bar.setting] ~= true then fail(mode .. ": " .. bar.id .. " not shown") end
    end
    pagesSame(mode)
  end
  local function cur(key) return ns.Spells.CurrentID(ns.Spells.Get(key)) end
  local stance = { ["CTRL-1"] = "SHAPESHIFTBUTTON1", ["CTRL-2"] = "SHAPESHIFTBUTTON2", ["CTRL-3"] = "SHAPESHIFTBUTTON3" }

  -- Level 23 (the player now): what he knows, a full apply. Spells learned later (Berserker Stance at 30, its stance
  -- macros, Mortal Strike) keep their buttons empty and their keys unbound until learned, like every pack.
  -- His Hearthstone sits on Action Bar 1 in no stance and on the Battle and Defensive pages: it moves once.
  STUB.level = 23
  STUB.actions = { [1] = { "spell", cur("heroic_strike") }, [73] = { "spell", cur("heroic_strike") },
    [2] = { "item", 6948 }, [74] = { "item", 6948 }, [86] = { "item", 6948 }, [75] = { "spell", cur("rend") } }
  STUB.bindings = { ["CTRL-R"] = "TOGGLEFPS" }
  for k, v in pairs(stance) do STUB.bindings[k] = v end
  local beforeA, beforeB = snapshot()
  ns.settings.targeting = "mouseover"
  do
    local plan = ns.Layout.BuildPlan()
    local hs = 0
    for _, m in ipairs(plan.moves) do
      if m.label == ns.Layout.Label(ns.Layout.Current(2)) then hs = hs + 1 end
    end
    if hs ~= 1 then fail("level 23 plan: the Hearthstone on three pages moves " .. hs .. " times, expected once") end
    local text = table.concat(ns.Layout.Describe(plan), "\n")
    if not text:find(ns.T("ui.preview.warn.stance", { key = "Ctrl+1, Ctrl+2" }), 1, true) then
      fail("preview: no note that Ctrl+1 and Ctrl+2 leave the stance bar for the stances on Action Bar 3")
    end
    if not text:find(ns.T("ui.preview.warn.fps", { key = "Ctrl+R" }), 1, true) then fail("preview: no Ctrl+R warning") end
    if not text:find(ns.T("ui.preview.warn.editmode", { bar = ns.T("ui.bar.bar6") }), 1, true) then
      fail("preview: no Edit Mode note for Action Bar 6")
    end
    if not text:find("Battle Stance", 1, true) then fail("preview: a stance page is not named by its stance") end
  end
  if try("preview 23", ns.Layout.Preview) then
    local p = _G.ForeverSenseiPreview
    if not p or not p:IsShown() then fail("preview window not shown") else
      fits("preview 23", p)
      try("apply 23", function() p.apply:Click() end)
    end
  end
  checkLayout("level 23")
  for key, want in pairs({ ["2"] = "FS_OP", ["1"] = "FS_REND", ["F"] = "FS_HAMS", ["CTRL-Q"] = "FS_TAUNT" }) do
    local s
    for _, x in ipairs(L.slots) do if x.key == key then s = x end end
    local m = s and macroAt(s.slot)
    if not m or m.name ~= want then fail("level 23: " .. key .. " should hold " .. want) end
  end
  if bodyOf("overpower") ~= "#showtooltip Overpower\n/cast [nostance:1] Battle Stance; Overpower" then
    fail("macro Overpower: " .. bodyOf("overpower"))
  end
  if bodyOf("rend") ~= "#showtooltip Rend\n/cast [stance:3] Battle Stance; Rend" then fail("macro Rend: " .. bodyOf("rend")) end
  if bodyOf("hamstring") ~= "#showtooltip Hamstring\n/cast [stance:2] Battle Stance; Hamstring" then
    fail("macro Hamstring: " .. bodyOf("hamstring"))
  end
  if bodyOf("taunt") ~= "#showtooltip Taunt\n/cast [nostance:2] Defensive Stance; Taunt" then fail("macro Taunt: " .. bodyOf("taunt")) end
  if bodyOf("charge") ~= "#showtooltip Charge\n/cast [nostance:1] Battle Stance; [@mouseover,harm,nodead][] Charge" then
    fail("macro Charge: " .. bodyOf("charge"))
  end
  for _, key in ipairs({ "whirlwind", "pummel", "intercept", "berserker_stance", "mortal_strike", "sweeping_strikes" }) do
    if STUB.actions[L.bySpell[key].slot] then fail("level 23: " .. key .. " is not known yet, its button should stay empty") end
  end
  if STUB.bindings["BUTTON4"] or STUB.bindings["CTRL-3"] ~= "SHAPESHIFTBUTTON3" then
    fail("level 23: Mouse4 (Pummel) and Ctrl+3 (Berserker Stance) should wait until their spells are learned")
  end
  if STUB.bindings["BUTTON5"] ~= "MULTIACTIONBAR5BUTTON2" then fail("level 23: Mouse5 should be War Stomp") end
  if not ns.Layout.IsEmptyPlan(ns.Layout.BuildPlan()) then fail("level 23: plan not empty after apply") end
  -- Undo: back to the starting bars, every stance page included, and keys.
  local undos = 0
  while ns.Layout.CanUndo() and undos < 10 do
    try("undo 23", ns.Layout.Undo)
    undos = undos + 1
  end
  local ok, why = same(beforeA, (snapshot()))
  if not ok then fail("level 23 undo did not restore action slots (stance pages included): " .. why) end
  ok, why = same(beforeB, select(2, snapshot()))
  if not ok then fail("level 23 undo did not restore key bindings: " .. why) end

  -- Level 60, everything known: a full apply in mouseover mode.
  STUB.level = 60
  for id in pairs(STUB.names) do STUB.known[id] = true end
  STUB.bags = { [14530] = 5, [1251] = 20, [13446] = 3 }
  STUB.actions = { [1] = { "spell", 6673 }, [97] = { "spell", 6673 }, [100] = { "item", 6948 }, [5] = { "item", 6948 } }
  STUB.bindings = { ["Q"] = "STRAFELEFT", ["CTRL-R"] = "TOGGLEFPS", ["5"] = "ACTIONBUTTON5" }
  for k, v in pairs(stance) do STUB.bindings[k] = v end
  beforeA, beforeB = snapshot()
  try("apply 60", ns.Layout.Execute, ns.Layout.BuildPlan())
  checkLayout("level 60")
  if not ns.Layout.IsEmptyPlan(ns.Layout.BuildPlan()) then fail("level 60: plan not empty after apply") end
  if STUB.cursor then fail("cursor not empty after apply") end
  for key, want in pairs({ ["BUTTON4"] = "MULTIACTIONBAR5BUTTON1", ["BUTTON5"] = "MULTIACTIONBAR5BUTTON2",
    ["SHIFT-BUTTON5"] = "MULTIACTIONBAR5BUTTON4", ["CTRL-BUTTON4"] = "MULTIACTIONBAR5BUTTON5",
    ["CTRL-BUTTON5"] = "MULTIACTIONBAR5BUTTON6", ["CTRL-1"] = "MULTIACTIONBAR2BUTTON1", ["CTRL-4"] = "MULTIACTIONBAR2BUTTON4",
    ["CTRL-R"] = "MULTIACTIONBAR2BUTTON8", ["SHIFT-5"] = "MULTIACTIONBAR1BUTTON5", ["Q"] = "ACTIONBUTTON6" }) do
    if STUB.bindings[key] ~= want then fail("apply 60: " .. key .. " should be bound to " .. want) end
  end
  local bodies = {
    pummel = "#showtooltip Pummel\n/stopcasting\n/cast [nostance:3] Berserker Stance; [@mouseover,harm,nodead][] Pummel",
    intercept = "#showtooltip Intercept\n/cast [nostance:3] Berserker Stance; [@mouseover,harm,nodead][] Intercept",
    whirlwind = "#showtooltip Whirlwind\n/cast [nostance:3] Berserker Stance; Whirlwind",
    execute = "#showtooltip Execute\n/cast [stance:2] Battle Stance; Execute",
    shield_wall = "#showtooltip Shield Wall\n/cast [nostance:2] Defensive Stance; Shield Wall",
    sweeping_strikes = "#showtooltip Sweeping Strikes\n/cast [nostance:1] Battle Stance; Sweeping Strikes",
  }
  for key, want in pairs(bodies) do
    if bodyOf(key) ~= want then fail("macro " .. key .. ": " .. bodyOf(key)) end
  end
  -- Spells every stance can cast are plain spells; the War Stomp racial too.
  for _, key in ipairs({ "slam", "mortal_strike", "heroic_strike", "cleave", "battle_shout", "war_stomp", "bloodrage" }) do
    local a = STUB.actions[L.bySpell[key].slot]
    if not a or a[1] ~= "spell" then fail("level 60: " .. key .. " should be the plain spell") end
  end
  local bandage = macroAt(L.byItem.bandage.slot)
  if not bandage or bandage.name ~= "FS_BANDAGE" or bandage.body ~= "#showtooltip\n/use [@player] item:14530" then
    fail("FS_BANDAGE: " .. tostring(bandage and bandage.body))
  end
  local nMacros = 0
  for _ in pairs(STUB.macros) do nMacros = nMacros + 1 end
  if nMacros ~= 23 then fail("macros: " .. nMacros .. " made, expected 23 (21 stance macros, FS_HEALTH, FS_BANDAGE)") end
  table.insert(notes, "macros: " .. nMacros)
  -- First Aid too low for Heavy Runecloth: the bandage macro takes the best one he can use (out of combat, on a bag
  -- change).
  STUB.unusable = { [14530] = true }
  STUB.fire("BAG_UPDATE_DELAYED")
  STUB.runTimers()
  if macroAt(L.byItem.bandage.slot).body ~= "#showtooltip\n/use [@player] item:1251" then
    fail("FS_BANDAGE with a too-high bandage: " .. macroAt(L.byItem.bandage.slot).body)
  end
  STUB.unusable = {}

  -- Click mode: the stance macros stay (macroAlways); Charge, Intercept and Pummel drop the mouseover.
  try("targeting click", ns.Layout.SetTargeting, "click")
  checkLayout("click")
  if bodyOf("pummel") ~= "#showtooltip Pummel\n/stopcasting\n/cast [nostance:3] Berserker Stance; Pummel" then
    fail("click mode Pummel: " .. bodyOf("pummel"))
  end
  if bodyOf("charge") ~= "#showtooltip Charge\n/cast [nostance:1] Battle Stance; Charge" then fail("click mode Charge: " .. bodyOf("charge")) end
  if bodyOf("overpower") ~= "#showtooltip Overpower\n/cast [nostance:1] Battle Stance; Overpower" then
    fail("click mode Overpower: " .. bodyOf("overpower"))
  end
  try("targeting mouseover", ns.Layout.SetTargeting, "mouseover")
  checkLayout("mouseover")

  -- Mutations: something changes one stance page, a stance macro body or a stance page binding; the plan, /sensei
  -- verify and RefreshMacros find it and a full apply puts it right.
  do
    local slot = 85 + 1 -- Defensive Stance page, button 2 (Overpower)
    STUB.actions[slot] = { "spell", cur("battle_shout") }
    local plan = ns.Layout.BuildPlan()
    local found = false
    for _, p in ipairs(plan.place) do if p.slot == slot then found = true end end
    if not found then fail("mutation: a changed stance page button is not in the plan") end
    local okV, report = pcall(ns.Verify.Run)
    if not okV or type(report) ~= "string" or not report:find("bonus bar offset 0", 1, true) then
      fail("verify: no bonus bar line")
    end
    try("apply over mutation", ns.Layout.Execute, plan)
    pagesSame("mutation fixed")
    local m = macroAt(L.bySpell.whirlwind.slot)
    m.body = "#showtooltip Whirlwind\n/cast Whirlwind"
    if ns.Layout.RefreshMacros() < 1 or bodyOf("whirlwind") ~= bodies.whirlwind then
      fail("mutation: RefreshMacros did not restore the Whirlwind stance macro")
    end
    STUB.actions[97 + 4] = nil -- Berserker page, button 5 (Execute) emptied
    if ns.Layout.IsEmptyPlan(ns.Layout.BuildPlan()) then fail("mutation: an emptied stance page button is not in the plan") end
    try("apply over empty page button", ns.Layout.Execute, ns.Layout.BuildPlan())
    pagesSame("mutation 2 fixed")
  end

  -- Clean: every planned button, the stance pages too; undo restores.
  local clA = snapshot()
  try("clean", ns.Layout.Clean)
  local cf = _G.ForeverSenseiConfirm
  if not cf or not cf:IsShown() then fail("clean: no confirmation") else
    fits("clean confirm", cf)
    try("clean confirm", function() cf.yes:Click() end)
  end
  for _, page in ipairs(L.stancePages) do
    for b = 1, 12 do
      if STUB.actions[page.first + b - 1] then fail("clean: " .. page.spell .. " page button " .. b .. " still set") end
    end
  end
  try("clean undo", ns.Layout.Undo)
  ok, why = same(clA, (snapshot()))
  if not ok then fail("clean undo: " .. why) end

  -- Undo everything: back to the starting bars (all four pages) and keys.
  undos = 0
  while ns.Layout.CanUndo() and undos < 20 do
    try("undo", ns.Layout.Undo)
    undos = undos + 1
  end
  local afterA, afterB = snapshot()
  ok, why = same(beforeA, afterA)
  if not ok then fail("undo did not restore action slots: " .. why) end
  ok, why = same(beforeB, afterB)
  if not ok then fail("undo did not restore key bindings: " .. why) end

  -- A stance card names the stance page rule; Charge's card names its key.
  try("card charge", ns.NewSkill.ShowCard, ns.Spells.Get("charge"))
  if not shownHas(ns.KeyLabel("CTRL-BUTTON4")) then fail("card Charge: its key Ctrl+Mouse4 is not shown") end
  _G.ForeverSenseiCard:Hide()

  STUB.runLongTimers()
  -- Every clickable and hoverable thing, once.
  local function discarded(f)
    while f do
      if f.discarded then return true end
      f = f.__parent
    end
    return false
  end
  for _, f in ipairs(STUB.frames) do
    for _, script in ipairs({ "OnEnter", "OnLeave", "OnClick" }) do
      local fn = not discarded(f) and f.__scripts[script]
      if fn then
        local ok2, err = pcall(fn, f, "LeftButton", false)
        if not ok2 then fail(script .. " " .. tostring(f.__name or f.__kind) .. ": " .. tostring(err)) end
        STUB.combat = false
        STUB.runTimers()
      end
    end
  end
  for _, cmd in ipairs({ "", "guide", "skills", "layout", "order", "review", "settings", "card Overpower", "trainer",
                         "talents", "verify", "help", "apply", "undo" }) do
    try("/sensei " .. cmd, SlashCmdList.FOREVERSENSEI, cmd)
  end
  ns.settings.language = lang
  for _, e in ipairs(ns.errors) do fail("ns.errors: " .. e) end
  ns.errors = {}
  return { errors = errors, notes = notes }
end
