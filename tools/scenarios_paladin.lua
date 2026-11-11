-- tools/scenarios_paladin.lua: the Protection Paladin flow inside the fake client (tools/wow_stub.lua), like
-- tools/scenarios.lua does for the Restoration Shaman. Returns run(ns, lang) → { errors = {...}, notes = {...} }.
return function(ns, lang)
  local errors, notes = {}, {}
  local function fail(msg) table.insert(errors, "[paladin " .. lang .. "] " .. msg) end
  local function try(label, fn, ...)
    local ok, err = pcall(fn, ...)
    if not ok then fail(label .. ": " .. tostring(err)) end
    STUB.runTimers()
    return ok
  end
  ns.settings.language = lang
  if not ns.Active() or ns.class.classFile ~= "PALADIN" or ns.specId ~= "PROTECTION" then
    fail("class pack: ForeverSensei_Paladin (Protection) is not active")
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

  -- Cards for every skill, the trainer list for every level, every guide tab, the talent hint.
  for _, e in ipairs(ns.Spells.List()) do
    try("card " .. e.key, ns.NewSkill.ShowCard, e)
    fits("card " .. e.key, "ForeverSenseiCard")
    try("card view " .. e.key, ns.NewSkill.ShowCard, e, true)
    fits("card view " .. e.key, "ForeverSenseiCard")
  end
  _G.ForeverSenseiCard:Hide()
  for lv = 1, 60 do
    try("trainer " .. lv, ns.NewSkill.ShowTrainer, lv)
    fits("trainer " .. lv, "ForeverSenseiTrainer")
  end
  local tabs = { "role", "rotation", "seals", "auras", "cooldowns", "manners", "skills", "layout", "talents", "review",
    "settings" }
  local got = ns.Guide.Tabs()
  if table.concat(got, ",") ~= table.concat(tabs, ",") then fail("guide tabs: " .. table.concat(got, ",")) end
  for _, tab in ipairs(tabs) do
    try("guide " .. tab, ns.Guide.Open, tab)
    if ns.Guide.Current() ~= tab then fail("guide: tab " .. tab .. " did not open") end
  end
  -- The key page names Ctrl+1-4 as the auras on the stance bar, and the auras in the stance bar line.
  try("guide layout", ns.Guide.Open, "layout")
  local shown = table.concat(STUB.shown, "\n")
  if not shown:find(ns.T("ui.layout.stancekeys"), 1, true) then fail("guide layout: no Ctrl+1-4 stance bar note") end
  if not shown:find("Devotion Aura", 1, true) then fail("guide layout: the stance bar line does not name the auras") end
  for lv = 10, 60, 5 do
    STUB.level, STUB.unspent = lv, 1
    try("talent hint " .. lv, ns.Talents.ShowHint, true)
    fits("talent hint " .. lv, "ForeverSenseiTalentHint")
  end
  STUB.unspent = 0
  local T = ns.spec.talents
  if #T.order ~= 51 then fail("talents: " .. #T.order .. " points in the order, expected 51 (10-60)") end
  for _, lv in ipairs({ 10, 32, 37, 52, 60 }) do
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
  for lv, key in pairs({ [32] = "templars_bulwark", [37] = "swift_judgement", [42] = "holy_shield", [52] = "shieldsworn",
    [56] = "sacred_arbiter" }) do
    if T.order[lv - 9].key ~= key then fail("talents: level " .. lv .. " should be " .. key) end
  end

  -- Helpers for the full layout.
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
  local stance = { ["CTRL-1"] = "SHAPESHIFTBUTTON1", ["CTRL-2"] = "SHAPESHIFTBUTTON2", ["CTRL-3"] = "SHAPESHIFTBUTTON3",
    ["CTRL-4"] = "SHAPESHIFTBUTTON4" }
  local function untouched(what)
    for k, v in pairs(stance) do
      if STUB.bindings[k] ~= v then fail(what .. ": " .. k .. " left the stance bar (" .. tostring(STUB.bindings[k]) .. ")") end
    end
    for i = 37, 40 do
      if STUB.actions[i] then fail(what .. ": Action Bar 5 button " .. (i - 36) .. " (Ctrl+1-4) was filled") end
    end
    local a5, a65 = STUB.actions[5], STUB.actions[65]
    if not (a5 and a5[2] == 6948 and a65 and a65[2] == 465) or STUB.bindings["5"] ~= "ACTIONBUTTON5"
      or STUB.bindings["SHIFT-5"] ~= "MULTIACTIONBAR1BUTTON5" or STUB.bindings["CTRL-5"] ~= "SHAPESHIFTBUTTON5" then
      fail(what .. ": his own buttons or keys 5, Shift+5, Ctrl+5 were changed")
    end
  end
  local function checkLayout(mode)
    for _, s in ipairs(L.slots) do
      local d = ns.Layout.DesiredFor(s)
      local a = STUB.actions[s.slot]
      local label = s.spell or s.item or s.combo
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
      if d and s.key and STUB.bindings[s.key] ~= s.binding then
        fail(mode .. ": key " .. s.key .. " bound to " .. tostring(STUB.bindings[s.key]) .. ", expected " .. s.binding)
      end
    end
    for _, sp in ipairs(L.spare) do
      if sp.key and STUB.bindings[sp.key] ~= sp.binding then fail(mode .. ": spare key " .. sp.key .. " not bound") end
    end
    for _, bar in ipairs(L.bars) do
      if bar.setting and STUB.settings[bar.setting] ~= true then fail(mode .. ": " .. bar.id .. " not shown") end
    end
    if STUB.settings.PROXY_SHOW_ACTIONBAR_6 or STUB.settings.PROXY_SHOW_ACTIONBAR_7 then
      fail(mode .. ": Action Bar 6 or 7 shown")
    end
  end
  local function bodyOf(key)
    local m = macroAt(L.bySpell[key].slot)
    return m and m.body or ""
  end

  -- Level 60, everything known: full layout in mouseover mode.
  STUB.level = 60
  for id in pairs(STUB.names) do STUB.known[id] = true end
  STUB.actions = { [1] = { "spell", 465 }, [5] = { "item", 6948 }, [65] = { "spell", 465 } }
  STUB.bindings = { ["1"] = "ACTIONBUTTON1", ["Q"] = "STRAFELEFT", ["CTRL-R"] = "TOGGLEFPS", ["5"] = "ACTIONBUTTON5",
    ["SHIFT-5"] = "MULTIACTIONBAR1BUTTON5", ["CTRL-5"] = "SHAPESHIFTBUTTON5" }
  for k, v in pairs(stance) do STUB.bindings[k] = v end
  local beforeA, beforeB = snapshot()
  ns.settings.targeting = "mouseover"
  if try("preview", ns.Layout.Preview) then
    local p = _G.ForeverSenseiPreview
    if not p or not p:IsShown() then
      fail("preview window not shown")
    else
      fits("preview", p)
      local text = table.concat(ns.Layout.Describe(ns.Layout.BuildPlan()), "\n")
      if not text:find(ns.T("ui.preview.warn.fps", { key = "Ctrl+R" }), 1, true) then fail("preview: no Ctrl+R warning") end
      if not text:find(ns.T("ui.preview.warn.mouse"), 1, true) then fail("preview: no mouse button warning") end
      if text:find(ns.T("ui.preview.warn.stance", { key = "Ctrl+1" }):sub(1, 12), 1, true) then
        fail("preview: warns about the stance bar keys, which the paladin layout keeps")
      end
      try("apply", function() p.apply:Click() end)
    end
  end
  checkLayout("mouseover")
  untouched("apply")
  if not ns.Layout.IsEmptyPlan(ns.Layout.BuildPlan()) then fail("plan not empty after apply") end
  if STUB.cursor then fail("cursor not empty after apply") end
  -- The macros: help with the self fallback, Protection and Sacrifice without, Hammer of Justice stops the cast, the
  -- opener fires Judgement, Swift Judgement, Holy Strike.
  for _, key in ipairs({ "flash_of_light", "holy_light", "lay_on_hands", "cleanse", "blessing_of_freedom" }) do
    local b = bodyOf(key)
    if not b:find("[@mouseover,help,nodead][help,nodead][@player] " .. ns.Spells.Get(key).name, 1, true) then
      fail("macro " .. key .. " body: " .. b)
    end
  end
  for _, key in ipairs({ "blessing_of_protection", "blessing_of_sacrifice" }) do
    local b = bodyOf(key)
    if b:find("@player", 1, true) or not b:find("[@mouseover,help,nodead][help,nodead] " .. ns.Spells.Get(key).name, 1, true) then
      fail("macro " .. key .. " should have no self fallback: " .. b)
    end
  end
  local hoj = bodyOf("hammer_of_justice")
  if not hoj:find("/stopcasting\n/cast [@mouseover,harm,nodead][] Hammer of Justice", 1, true) then fail("macro HoJ: " .. hoj) end
  local op = macroAt(L.byCombo.opener.slot)
  if not op or op.name ~= "FS_OPEN" or op.body ~= "#showtooltip Swift Judgement\n/startattack\n/cast Judgement\n/cast Swift Judgement\n/cast Holy Strike" then
    fail("opener macro: " .. tostring(op and op.body))
  end
  if STUB.bindings["CTRL-Q"] ~= "MULTIACTIONBAR4BUTTON6" then fail("opener: Ctrl+Q not bound to Action Bar 5 button 6") end
  local nMacros = 0
  for _ in pairs(STUB.macros) do nMacros = nMacros + 1 end
  if nMacros > 15 then fail("macros: " .. nMacros .. " made, over 15") end
  table.insert(notes, "macros: " .. nMacros)

  try("targeting click", ns.Layout.SetTargeting, "click")
  checkLayout("click")
  local fol = STUB.actions[L.bySpell.flash_of_light.slot]
  if not fol or fol[1] ~= "spell" then fail("click mode: Flash of Light should be the plain spell") end
  if not bodyOf("hammer_of_justice"):find("/stopcasting\n/cast Hammer of Justice", 1, true) then
    fail("click mode: Hammer of Justice should keep its stop-cast macro without the mouseover")
  end
  try("targeting mouseover", ns.Layout.SetTargeting, "mouseover")
  checkLayout("mouseover")
  untouched("targeting")

  -- Clean: only the addon's buttons; his own 5 and a spare button keep what he put there; Undo restores.
  local spare = L.spare[1].slot
  STUB.actions[spare] = { "spell", 465 }
  local clA = snapshot()
  try("clean", ns.Layout.Clean)
  local cf = _G.ForeverSenseiConfirm
  if not cf or not cf:IsShown() then fail("clean: no confirmation") else
    fits("clean confirm", cf)
    try("clean confirm", function() cf.yes:Click() end)
  end
  for slot in pairs(clA) do
    local keep = slot == 5 or slot == 65 or slot == spare
    if (STUB.actions[slot] ~= nil) ~= keep then fail("clean: slot " .. slot .. (keep and " was emptied" or " still set")) end
  end
  try("clean undo", ns.Layout.Undo)
  local ok, why = same(clA, (snapshot()))
  if not ok then fail("clean undo: " .. why) end
  STUB.actions[spare] = nil

  -- Undo everything: back to the starting bars and keys.
  local undos = 0
  while ns.Layout.CanUndo() and undos < 10 do
    try("undo", ns.Layout.Undo)
    undos = undos + 1
  end
  local afterA, afterB = snapshot()
  ok, why = same(beforeA, afterA)
  if not ok then fail("undo did not restore action slots: " .. why) end
  ok, why = same(beforeB, afterB)
  if not ok then fail("undo did not restore key bindings: " .. why) end

  -- Level 30: no Swift Judgement (talent at 37) → Ctrl+Q empty but bound; no Cleanse (42) → Purify stands in on
  -- Mouse5 with its macro; no Holy Shield (talent at 42) → 3 stays empty.
  STUB.level = 30
  STUB.known = {}
  for id, lv in pairs(STUB.levels) do if lv <= 30 then STUB.known[id] = true end end
  -- Talent spells come with the talent, not the level (the path takes them at 32, 37 and 42).
  local function forgetTalents()
    for _, e in ipairs(ns.Spells.List()) do
      if e.talent then
        for _, id in ipairs(ns.Spells.Ranks(e)) do STUB.known[id] = nil end
      end
    end
  end
  forgetTalents()
  STUB.actions, STUB.macros = { [5] = { "item", 6948 }, [65] = { "spell", 465 } }, {}
  try("apply 30", ns.Layout.Execute, ns.Layout.BuildPlan())
  checkLayout("level 30")
  untouched("level 30")
  if STUB.actions[L.byCombo.opener.slot] then fail("level 30: the opener was placed without Swift Judgement") end
  local m5 = macroAt(L.bySpell.cleanse.slot)
  if not m5 or m5.name ~= "FS_PURIFY" or not m5.body:find("Purify", 1, true) then fail("level 30: Purify not standing in on Mouse5") end
  local a3 = STUB.actions[L.bySpell.holy_shield.slot]
  if a3 then fail("level 30: 3 holds " .. a3[1] .. ":" .. tostring(a3[2]) .. " (" .. tostring(STUB.names[a3[2]]) .. ") before Holy Shield") end
  -- Learn Cleanse at 42: it takes Mouse5.
  STUB.level = 42
  for id, lv in pairs(STUB.levels) do if lv <= 42 then STUB.known[id] = true end end
  forgetTalents()
  try("apply 42", ns.Layout.Execute, ns.Layout.BuildPlan())
  local c5 = macroAt(L.bySpell.cleanse.slot)
  if not c5 or c5.name ~= "FS_CLEANSE" then fail("level 42: Cleanse did not take Mouse5") end

  -- A new skill while playing → its card, with the planned key.
  STUB.level = 20
  STUB.known = {}
  for id, lv in pairs(STUB.levels) do if lv <= 18 then STUB.known[id] = true end end
  ns.char.known, ns.char.initialised = {}, false
  try("scan initial", ns.NewSkill.Scan)
  if _G.ForeverSenseiCard then _G.ForeverSenseiCard:Hide() end
  local cons = ns.Spells.Get("consecration")
  STUB.known[cons.id] = true
  STUB.fire("LEARNED_SPELL_IN_SKILL_LINE", cons.id, 1)
  STUB.runTimers()
  local card = _G.ForeverSenseiCard
  if not card or not card:IsShown() or not card.entry or card.entry.key ~= "consecration" then
    fail("no card for a newly learned spell (Consecration)")
  end
  local where = ns.Spells.WhereText(cons) or ""
  if not where:find(ns.KeyLabel("2"), 1, true) then fail("card: Consecration's place does not name key 2: " .. where) end
  -- An aura: its card points at the stance bar.
  local ret = ns.Spells.Get("retribution_aura")
  local rw = ns.Spells.WhereText(ret)
  if rw ~= ns.T("ui.where.stancebar") then fail("card: an aura's place should be the stance bar: " .. tostring(rw)) end

  -- New rank: Holy Strike rank 1 on 1 becomes rank 2 after combat.
  ns.settings.targeting = "click"
  local hs = ns.Spells.Get("holy_strike")
  local hsR = ns.Spells.Ranks(hs)
  if #hsR < 2 then fail("ranks: Holy Strike has " .. #hsR .. " ranks") else
    local slot = L.bySpell.holy_strike.slot
    STUB.known = {}
    for id, lv in pairs(STUB.levels) do if lv <= 6 then STUB.known[id] = true end end
    STUB.actions = { [slot] = { "spell", hsR[1] } }
    STUB.known[hsR[2]] = true
    STUB.fire("SPELLS_CHANGED")
    STUB.runTimers()
    if not (STUB.actions[slot] and STUB.actions[slot][2] == hsR[2]) then fail("ranks: Holy Strike not upgraded to rank 2") end
  end
  ns.settings.targeting = "mouseover"

  -- Translation reports name the pack for its texts (the Shaman pack has a guide.role.p1 too), not for the core's.
  do
    local saved = ns.db.reports
    ns.db.reports = {}
    ns.Feedback.Save("guide.role.p1", "unclear", nil, "x")
    ns.Feedback.Save("ui.pack.missing", "typo", nil, "y")
    table.insert(ns.db.reports, { id = "guide.manners.p1", reason = "other", now = "z" }) -- saved before 0.6.0
    local text = ns.Feedback.Format(ns.Feedback.Pending(), ns.VERSION)
    if not text:find("#1 guide.role.p1 | [^\n]* | ForeverSensei_Paladin\n") then fail("report: guide.role.p1 without its pack:\n" .. text) end
    if text:find("#2 ui.pack.missing | [^\n]*ForeverSensei") then fail("report: a core text got a pack:\n" .. text) end
    if not text:find("#3 guide.manners.p1 | [^\n]* | ForeverSensei_Paladin\n") then fail("report: an old report did not get the pack in use:\n" .. text) end
    ns.db.reports = saved
  end

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
  for _, cmd in ipairs({ "", "guide", "skills", "layout", "order", "review", "settings", "card Consecration", "trainer",
                         "talents", "verify", "help", "apply", "undo" }) do
    try("/sensei " .. cmd, SlashCmdList.FOREVERSENSEI, cmd)
  end
  ns.settings.language = lang
  for _, e in ipairs(ns.errors) do fail("ns.errors: " .. e) end
  ns.errors = {}
  return { errors = errors, notes = notes }
end
