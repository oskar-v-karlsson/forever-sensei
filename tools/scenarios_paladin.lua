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
  -- The key page draws the auras on Action Bar 3 (Ctrl+1-5) and tells the player to move Action Bar 6 in Edit Mode.
  try("guide layout", ns.Guide.Open, "layout")
  local shown = table.concat(STUB.shown, "\n")
  if not shown:find(ns.T("ui.layout.editmode"), 1, true) then fail("guide layout: no Edit Mode note for Action Bar 6") end
  if not shown:find("Devotion Aura", 1, true) then fail("guide layout: the key page does not name the auras") end
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
    ["CTRL-4"] = "SHAPESHIFTBUTTON4", ["CTRL-5"] = "SHAPESHIFTBUTTON5" }
  -- Layout 2: the auras are on Action Bar 3 (Ctrl+1-5), not on the stance bar; Action Bar 5 is no longer filled.
  -- (An aura not learned yet keeps its key's default until it is placed.) own: Action Bar 5 slots he filled himself.
  local function auraKeys(what, own)
    for _, s in ipairs(L.slots) do
      if s.bar == "bar3" and s.button <= 5 and ns.Layout.DesiredFor(s) then
        if STUB.bindings[s.key] ~= "MULTIACTIONBAR2BUTTON" .. s.button then
          fail(what .. ": " .. s.key .. " bound to " .. tostring(STUB.bindings[s.key]) .. ", expected Action Bar 3 button " .. s.button)
        end
      end
    end
    for i = 37, 48 do
      if STUB.actions[i] and not (own and own[i]) then fail(what .. ": Action Bar 5 button " .. (i - 36) .. " was filled") end
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
    if STUB.settings.PROXY_SHOW_ACTIONBAR_7 then fail(mode .. ": Action Bar 7 shown") end
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
      if not text:find(ns.T("ui.preview.warn.stance", { key = "Ctrl+1, Ctrl+2, Ctrl+3, Ctrl+4, Ctrl+5" }), 1, true) then
        fail("preview: no note that Ctrl+1-5 leave the stance bar for the auras on Action Bar 3")
      end
      if not text:find(ns.T("ui.preview.warn.editmode", { bar = ns.T("ui.bar.bar6") }), 1, true) then
        fail("preview: no Edit Mode note for Action Bar 6")
      end
      try("apply", function() p.apply:Click() end)
    end
  end
  checkLayout("mouseover")
  auraKeys("apply")
  if STUB.settings.PROXY_SHOW_ACTIONBAR_6 ~= true then fail("apply: Action Bar 6 (mouse buttons) not shown") end
  for key, want in pairs({ ["5"] = "ACTIONBUTTON5", ["SHIFT-5"] = "MULTIACTIONBAR1BUTTON5", ["SHIFT-1"] = "MULTIACTIONBAR1BUTTON1",
    ["CTRL-Z"] = "MULTIACTIONBAR2BUTTON10", ["BUTTON4"] = "MULTIACTIONBAR5BUTTON1", ["BUTTON5"] = "MULTIACTIONBAR5BUTTON2",
    ["SHIFT-BUTTON4"] = "MULTIACTIONBAR5BUTTON3", ["SHIFT-BUTTON5"] = "MULTIACTIONBAR5BUTTON4",
    ["CTRL-BUTTON5"] = "MULTIACTIONBAR5BUTTON6", ["CTRL-Q"] = "MULTIACTIONBAR2BUTTON6", ["CTRL-R"] = "MULTIACTIONBAR2BUTTON8",
    ["CTRL-F"] = "MULTIACTIONBAR2BUTTON9" }) do
    if STUB.bindings[key] ~= want then fail("apply: " .. key .. " should be bound to " .. want) end
  end
  if not ns.Layout.IsEmptyPlan(ns.Layout.BuildPlan()) then fail("plan not empty after apply") end
  if STUB.cursor then fail("cursor not empty after apply") end
  -- The macros (0.7.1, Oskar: "aren't casting ... on my self if I am not mousing over any party member"): each help
  -- slot holds its FS_ macro, falling back to yourself (Blessing of Protection too since 0.7.1); Sacrifice never
  -- targets yourself; Hammer of Justice stops the cast; the opener fires Judgement, Swift Judgement, Holy Strike.
  local function selfMacro(what, key, slot)
    local a, m = STUB.actions[slot], macroAt(slot)
    if not m or m.name ~= L.macros[key] then
      fail(what .. ": slot " .. slot .. " should hold macro " .. L.macros[key] .. ", holds " .. (a and (a[1] .. ":" .. tostring(a[2])) or "nothing"))
    elseif not m.body:find("/cast [@mouseover,help,nodead][help,nodead][@player] " .. ns.Spells.Get(key).name, 1, true) then
      fail(what .. ": macro " .. m.name .. " has no self fallback: " .. m.body)
    end
  end
  for _, key in ipairs({ "lay_on_hands", "blessing_of_protection", "flash_of_light", "holy_light", "cleanse",
    "blessing_of_freedom" }) do
    selfMacro("mouseover", key, L.bySpell[key].slot)
  end
  do
    local b = bodyOf("blessing_of_sacrifice")
    if macroAt(L.bySpell.blessing_of_sacrifice.slot) == nil or b:find("@player", 1, true)
      or not b:find("[@mouseover,help,nodead][help,nodead] Blessing of Sacrifice", 1, true) then
      fail("macro Blessing of Sacrifice should have no self fallback: " .. b)
    end
  end
  -- The client reports a macro button as ("macro", spellID, "spell"); the layout still knows it by its name.
  if not ns.Layout.IsEmptyPlan(ns.Layout.BuildPlan()) then fail("macro buttons not recognised after apply") end
  -- /sensei verify flags a help button that holds the plain spell instead of its macro (no mouseover, no self
  -- fallback there); a full apply puts the macro back.
  do
    local slot = L.bySpell.lay_on_hands.slot
    STUB.actions[slot] = { "spell", ns.Spells.CurrentID(ns.Spells.Get("lay_on_hands")) }
    local ok, report = pcall(ns.Verify.Run)
    if not ok or type(report) ~= "string" or not report:find("slot " .. slot .. " (CTRL-Q): plain spell Lay on Hands, not macro FS_LOH", 1, true) then
      fail("verify: no warning for the plain Lay on Hands on Ctrl+Q")
    end
    try("apply over plain Lay on Hands", ns.Layout.Execute, ns.Layout.BuildPlan())
    selfMacro("re-apply", "lay_on_hands", slot)
  end
  local hoj = bodyOf("hammer_of_justice")
  if not hoj:find("/stopcasting\n/cast [@mouseover,harm,nodead][] Hammer of Justice", 1, true) then fail("macro HoJ: " .. hoj) end
  local op = macroAt(L.byCombo.opener.slot)
  if not op or op.name ~= "FS_OPEN" or op.body ~= "#showtooltip Swift Judgement\n/startattack\n/cast Judgement\n/cast Swift Judgement\n/cast Holy Strike" then
    fail("opener macro: " .. tostring(op and op.body))
  end
  if L.byCombo.opener.key ~= "R" or STUB.bindings["R"] ~= "ACTIONBUTTON8" then fail("opener: R not bound to Action Bar 1 button 8") end
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
  auraKeys("targeting")

  -- Clean: only the addon's buttons; a spare button and Action Bar 5 button 1 (no layout filled it) keep what he put
  -- there; Undo restores.
  local spare
  for _, sp in ipairs(L.spare) do
    if not spare and not STUB.actions[sp.slot] then spare = sp.slot end
  end
  STUB.actions[spare] = { "spell", 465 }
  -- (The Hearthstone from button 5 sits on a spare button since the apply: kept too.)
  local isSpare = {}
  for _, sp in ipairs(L.spare) do isSpare[sp.slot] = true end
  STUB.actions[37] = { "item", 6948 }
  local clA = snapshot()
  try("clean", ns.Layout.Clean)
  local cf = _G.ForeverSenseiConfirm
  if not cf or not cf:IsShown() then fail("clean: no confirmation") else
    fits("clean confirm", cf)
    try("clean confirm", function() cf.yes:Click() end)
  end
  for slot in pairs(clA) do
    local keep = slot == 37 or isSpare[slot] or false
    if (STUB.actions[slot] ~= nil) ~= keep then fail("clean: slot " .. slot .. (keep and " was emptied" or " still set")) end
  end
  try("clean undo", ns.Layout.Undo)
  local ok, why = same(clA, (snapshot()))
  if not ok then fail("clean undo: " .. why) end
  STUB.actions[spare], STUB.actions[37] = nil, nil

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

  -- Update from layout 1 (0.6.0-0.6.1) to 2 (0.7.0, family blocks): the auras leave the stance bar for Action Bar 3
  -- (Ctrl+1-5), the Ctrl row leaves Action Bar 5, the mouse buttons move from Action Bar 3 7-12 to Action Bar 6, and
  -- key 5 is planned. One notice, nothing moves by itself; a full apply moves it all, shows Action Bar 6, clears
  -- layout 1's spells on Action Bar 5 (the bar stays shown) and 元に戻す puts back the spells, keys and bar settings.
  do
    local function cur(key) return ns.Spells.CurrentID(ns.Spells.Get(key)) end
    local function settingsSnap()
      local t = {}
      for k, v in pairs(STUB.settings) do t[k] = tostring(v) end
      return t
    end
    STUB.actions = { [9] = { "spell", cur("seal_of_fury") }, [69] = { "spell", cur("seal_of_righteousness") },
      [44] = { "spell", cur("turn_undead") }, [45] = { "spell", cur("seal_of_the_crusader") },
      [47] = { "spell", cur("redemption") }, [48] = { "spell", cur("divine_protection") },
      [55] = { "spell", cur("blessing_of_protection") }, [56] = { "spell", cur("cleanse") },
      [57] = { "spell", cur("lay_on_hands") }, [5] = { "item", 6948 }, [38] = { "item", 6948 } }
    STUB.bindings = { ["CTRL-R"] = "MULTIACTIONBAR4BUTTON8", ["BUTTON4"] = "MULTIACTIONBAR2BUTTON7",
      ["BUTTON5"] = "MULTIACTIONBAR2BUTTON8", ["5"] = "ACTIONBUTTON5" }
    for k, v in pairs(stance) do STUB.bindings[k] = v end
    STUB.settings.PROXY_SHOW_ACTIONBAR_3, STUB.settings.PROXY_SHOW_ACTIONBAR_5 = true, true
    STUB.settings.PROXY_SHOW_ACTIONBAR_6 = false
    local v1A, v1B = snapshot()
    local v1S = settingsSnap()
    ns.char.layoutVersion = 1
    for _ = 1, 60 do ns.NewSkill.Next() end
    if _G.ForeverSenseiCard then _G.ForeverSenseiCard:Hide() end
    if _G.ForeverSenseiToast then _G.ForeverSenseiToast:Hide() end
    ns.ready = false
    STUB.fire("PLAYER_LOGIN")
    STUB.runTimers()
    for _ = 1, 60 do ns.NewSkill.Next() end
    if _G.ForeverSenseiCard then _G.ForeverSenseiCard:Hide() end
    local confirm = _G.ForeverSenseiConfirm
    if not confirm or not confirm:IsShown() or confirm.text:GetText() ~= ns.T("ui.layout.changed") then
      fail("layout 2: no notice for a player with layout 1")
    else
      fits("layout 2 notice", confirm)
      confirm:Hide()
    end
    if ns.char.layoutVersion ~= L.version then fail("layout 2: version not saved after the notice") end
    local nA, nB = snapshot()
    if not same(v1A, nA) or not same(v1B, nB) then fail("layout 2: the notice moved something by itself") end
    local plan = ns.Layout.BuildPlan()
    local cleared, bars = {}, {}
    for _, c in ipairs(plan.clears) do cleared[c.slot] = true end
    for _, bar in ipairs(plan.bars) do bars[bar.id] = true end
    for _, slot in ipairs({ 44, 45, 47, 48, 57 }) do
      if not cleared[slot] then fail("layout 2: layout 1's spell on slot " .. slot .. " not cleared") end
    end
    -- Layout 1's Action Bar 3 buttons 7-8 are the save block again since layout 4: replaced, not cleared.
    local placed = {}
    for _, pl in ipairs(plan.place) do placed[pl.slot] = true end
    if not placed[55] or not placed[56] then fail("layout 2: Ctrl+E and Ctrl+R not replaced by the save block") end
    if cleared[38] then fail("layout 2: his own item on Action Bar 5 is planned to be cleared") end
    if not bars.bar6 then fail("layout 2: the preview does not show Action Bar 6") end
    for _, h in ipairs(plan.hide) do if h.id == "bar5" then fail("layout 2: Action Bar 5 is planned to be hidden") end end
    local text = table.concat(ns.Layout.Describe(plan), "\n")
    if not text:find(ns.T("ui.preview.warn.stance", { key = "Ctrl+1, Ctrl+2, Ctrl+3, Ctrl+4, Ctrl+5" }), 1, true) then
      fail("layout 2: the preview does not explain that Ctrl+1-5 leave the stance bar")
    end
    try("layout 2 apply", ns.Layout.Execute, plan)
    checkLayout("layout 2")
    auraKeys("layout 2", { [38] = true })
    if not (STUB.actions[38] and STUB.actions[38][2] == 6948) then fail("layout 2: his item on Action Bar 5 was cleared") end
    if STUB.settings.PROXY_SHOW_ACTIONBAR_5 ~= true or STUB.settings.PROXY_SHOW_ACTIONBAR_6 ~= true then
      fail("layout 2: Action Bar 5 should stay shown and Action Bar 6 be shown")
    end
    local hearth
    for _, sp in ipairs(L.spare) do
      if STUB.actions[sp.slot] and STUB.actions[sp.slot][2] == 6948 then hearth = sp.slot end
    end
    if not hearth then fail("layout 2: the Hearthstone from button 5 did not move to a spare button") end
    if STUB.bindings["BUTTON4"] ~= "MULTIACTIONBAR5BUTTON1" or STUB.bindings["CTRL-R"] ~= "MULTIACTIONBAR2BUTTON8" then
      fail("layout 2: Mouse4 or Ctrl+R not moved to the new buttons")
    end
    try("layout 2 undo", ns.Layout.Undo)
    local uA, uB = snapshot()
    local ok2, why2 = same(v1A, uA)
    if not ok2 then fail("layout 2 undo: action slots differ: " .. why2) end
    ok2, why2 = same(v1B, uB)
    if not ok2 then fail("layout 2 undo: key bindings differ: " .. why2) end
    ok2, why2 = same(v1S, settingsSnap())
    if not ok2 then fail("layout 2 undo: bar settings differ: " .. why2) end
  end

  -- Update from layout 2 (0.7.0) to 3 (0.7.1, Oskar: "why isn't seal of justice on shift 4 next to the other seals?"):
  -- Shift+4 Seal of Justice, Shift+5 Seal of Wisdom, Seal of Light clicked on Action Bar 6 button 7. One notice,
  -- nothing moves by itself; a full apply changes only those three buttons (the keys stay) and 元に戻す restores them.
  do
    local function cur(key) return ns.Spells.CurrentID(ns.Spells.Get(key)) end
    STUB.actions, STUB.macros = {}, {}
    try("layout 3 setup", ns.Layout.Execute, ns.Layout.BuildPlan())
    local s4, s5, b7 = L.bySpell.seal_of_justice.slot, L.bySpell.seal_of_wisdom.slot, L.bySpell.seal_of_light.slot
    if s4 ~= 64 or s5 ~= 65 or b7 ~= 151 then fail("layout 3: seal slots are " .. s4 .. ", " .. s5 .. ", " .. b7) end
    STUB.actions[64] = { "spell", cur("seal_of_wisdom") }
    STUB.actions[65] = { "spell", cur("seal_of_light") }
    STUB.actions[151] = { "spell", cur("seal_of_justice") }
    local v2A, v2B = snapshot()
    ns.char.layoutVersion = 2
    ns.ready = false
    STUB.fire("PLAYER_LOGIN")
    STUB.runTimers()
    for _ = 1, 60 do ns.NewSkill.Next() end
    if _G.ForeverSenseiCard then _G.ForeverSenseiCard:Hide() end
    if _G.ForeverSenseiToast then _G.ForeverSenseiToast:Hide() end
    local confirm = _G.ForeverSenseiConfirm
    if not confirm or not confirm:IsShown() or confirm.text:GetText() ~= ns.T("ui.layout.changed") then
      fail("layout 3: no notice for a player with layout 2")
    else
      confirm:Hide()
    end
    if ns.char.layoutVersion ~= L.version then fail("layout 3: version not saved after the notice") end
    local nA, nB = snapshot()
    if not same(v2A, nA) or not same(v2B, nB) then fail("layout 3: the notice moved something by itself") end
    local plan = ns.Layout.BuildPlan()
    try("layout 3 apply", ns.Layout.Execute, plan)
    checkLayout("layout 3")
    local aA, aB = snapshot()
    local diff = {}
    for k, v in pairs(aA) do if v2A[k] ~= v then diff[#diff + 1] = k end end
    for k in pairs(v2A) do if aA[k] == nil then diff[#diff + 1] = k end end
    table.sort(diff)
    if table.concat(diff, ",") ~= "64,65,151" then fail("layout 3: apply changed slots " .. table.concat(diff, ",") .. ", expected 64,65,151") end
    local okB, whyB = same(v2B, aB)
    if not okB then fail("layout 3: apply changed key bindings: " .. whyB) end
    if STUB.bindings["SHIFT-4"] ~= "MULTIACTIONBAR1BUTTON4" then fail("layout 3: Shift+4 not on Action Bar 2 button 4") end
    if STUB.names[STUB.actions[64][2]] ~= "Seal of Justice" then fail("layout 3: Shift+4 is not Seal of Justice") end
    try("layout 3 undo", ns.Layout.Undo)
    local uA, uB = snapshot()
    local ok3, why3 = same(v2A, uA)
    if not ok3 then fail("layout 3 undo: action slots differ: " .. why3) end
    ok3, why3 = same(v2B, uB)
    if not ok3 then fail("layout 3 undo: key bindings differ: " .. why3) end
  end

  -- Update from layout 3 (0.7.1) to 4 (0.8.0, Oskar: "Having expensive/high risk spells on the mouse buttons are a bit
  -- risky ... the non shift mouse button should be placed paired next to each other"): Lay on Hands, Blessing of
  -- Protection and Sacrifice go to Ctrl+Q/E/R (Action Bar 3 buttons 6-8); Action Bar 6 buttons 1-6 are rebound in
  -- pairs and hold Cleanse, Freedom and Voice of Truth on 1-3. One notice, nothing moves by itself; a full apply
  -- changes only those buttons and the four mouse keys, and 元に戻す restores them.
  do
    STUB.actions, STUB.macros = {}, {}
    try("layout 4 setup", ns.Layout.Execute, ns.Layout.BuildPlan())
    local a = STUB.actions
    local loh, bop, bos = L.bySpell.lay_on_hands.slot, L.bySpell.blessing_of_protection.slot, L.bySpell.blessing_of_sacrifice.slot
    local cl, bof, vot = L.bySpell.cleanse.slot, L.bySpell.blessing_of_freedom.slot, L.bySpell.voice_of_truth.slot
    if loh ~= 54 or bop ~= 55 or bos ~= 56 or cl ~= 145 or bof ~= 146 or vot ~= 147 then
      fail("layout 4: save/free slots are " .. table.concat({ loh, bop, bos, cl, bof, vot }, ","))
    end
    -- Layout 3: Action Bar 6 column by column (Mouse4 BoP, Shift+Mouse4 LoH, Ctrl+Mouse4 BoS, Mouse5 Cleanse, ...).
    a[145], a[146], a[147], a[148], a[149], a[150] = a[bop], a[loh], a[bos], a[cl], a[bof], a[vot]
    a[54], a[55], a[56] = nil, nil, nil
    for i, key in ipairs({ "BUTTON4", "SHIFT-BUTTON4", "CTRL-BUTTON4", "BUTTON5", "SHIFT-BUTTON5", "CTRL-BUTTON5" }) do
      STUB.bindings[key] = "MULTIACTIONBAR5BUTTON" .. i
    end
    local v3A, v3B = snapshot()
    ns.char.layoutVersion = 3
    ns.ready = false
    STUB.fire("PLAYER_LOGIN")
    STUB.runTimers()
    for _ = 1, 60 do ns.NewSkill.Next() end
    if _G.ForeverSenseiCard then _G.ForeverSenseiCard:Hide() end
    if _G.ForeverSenseiToast then _G.ForeverSenseiToast:Hide() end
    local confirm = _G.ForeverSenseiConfirm
    if not confirm or not confirm:IsShown() or confirm.text:GetText() ~= ns.T("ui.layout.changed") then
      fail("layout 4: no notice for a player with layout 3")
    else
      fits("layout 4 notice", confirm)
      confirm:Hide()
    end
    if ns.char.layoutVersion ~= 4 then fail("layout 4: version not saved after the notice") end
    local nA, nB = snapshot()
    if not same(v3A, nA) or not same(v3B, nB) then fail("layout 4: the notice moved something by itself") end
    local plan = ns.Layout.BuildPlan()
    local cleared = {}
    for _, c in ipairs(plan.clears) do cleared[c.slot] = true end
    for _, slot in ipairs({ 148, 149, 150 }) do
      if not cleared[slot] then fail("layout 4: layout 3's spell on Action Bar 6 slot " .. slot .. " not cleared") end
    end
    try("layout 4 apply", ns.Layout.Execute, plan)
    checkLayout("layout 4")
    selfMacro("layout 4", "lay_on_hands", 54)
    selfMacro("layout 4", "blessing_of_protection", 55)
    selfMacro("layout 4", "cleanse", 145)
    selfMacro("layout 4", "blessing_of_freedom", 146)
    local bosM = macroAt(56)
    if not bosM or bosM.name ~= "FS_BOS" or bosM.body:find("@player", 1, true) then fail("layout 4: Ctrl+R is not FS_BOS without @player") end
    local aA, aB = snapshot()
    local diff = {}
    for k, v in pairs(aA) do if v3A[k] ~= v then diff[#diff + 1] = k end end
    for k in pairs(v3A) do if aA[k] == nil then diff[#diff + 1] = k end end
    table.sort(diff, function(x, y) return tostring(x) < tostring(y) end)
    local slots, keys = {}, {}
    for _, k in ipairs(diff) do
      if type(k) == "number" then slots[#slots + 1] = k else keys[#keys + 1] = k end
    end
    table.sort(slots)
    if table.concat(slots, ",") ~= "54,55,56,145,146,147,148,149,150" then
      fail("layout 4: apply changed slots " .. table.concat(slots, ",") .. ", expected 54-56 and 145-150")
    end
    local bdiff = {}
    for k, v in pairs(aB) do if v3B[k] ~= v then bdiff[#bdiff + 1] = k end end
    for k in pairs(v3B) do if aB[k] == nil then bdiff[#bdiff + 1] = k end end
    table.sort(bdiff, function(x, y) return tostring(x) < tostring(y) end)
    local bl = {}
    for _, k in ipairs(bdiff) do bl[#bl + 1] = tostring(k) end
    if table.concat(bl, ",") ~= "BUTTON5,CTRL-BUTTON4,SHIFT-BUTTON4,SHIFT-BUTTON5" then
      fail("layout 4: apply rebound " .. table.concat(bl, ",") .. ", expected the four mouse keys that moved")
    end
    if STUB.bindings["BUTTON5"] ~= "MULTIACTIONBAR5BUTTON2" or STUB.bindings["SHIFT-BUTTON4"] ~= "MULTIACTIONBAR5BUTTON3" then
      fail("layout 4: Mouse5 or Shift+Mouse4 not on Action Bar 6 buttons 2 and 3")
    end
    try("layout 4 undo", ns.Layout.Undo)
    local uA, uB = snapshot()
    local ok4, why4 = same(v3A, uA)
    if not ok4 then fail("layout 4 undo: action slots differ: " .. why4) end
    ok4, why4 = same(v3B, uB)
    if not ok4 then fail("layout 4 undo: key bindings differ: " .. why4) end
  end

  -- Mouse 4/5 over the unit frames (0.8.0, Oskar: "my mouse over purify doesn't seem to work on party portraits"):
  -- the frames take those buttons as their own click, so they get click attributes that do what the bar button does.
  do
    local P1, P2 = PartyFrame.MemberFrame1, PartyFrame.MemberFrame2
    local function clickIs(what, frame, button, mod, wantT, wantV)
      local t, v = STUB.unitClick(frame, button, mod)
      if t ~= wantT or v ~= wantV then
        fail("unit frames " .. what .. ": " .. (mod and (mod .. "-") or "") .. button .. " on " .. tostring(frame:GetAttribute("unit")) ..
          " is " .. tostring(t) .. " " .. tostring(v) .. ", expected " .. tostring(wantT) .. " " .. tostring(wantV))
      end
    end
    local vot = ns.Spells.CurrentID(ns.Spells.Get("voice_of_truth"))
    local cleanseId = ns.Spells.CurrentID(ns.Spells.Get("cleanse"))
    local function planned(what, frame)
      clickIs(what, frame, "Button4", nil, "macro", "FS_CLEANSE")
      clickIs(what, frame, "Button5", nil, "macro", "FS_BOF")
      clickIs(what, frame, "Button4", "shift", "spell", vot)
      clickIs(what, frame, "Button5", "shift", nil, nil)
      clickIs(what, frame, "Button4", "ctrl", nil, nil)
      clickIs(what, frame, "Button5", "ctrl", nil, nil)
      clickIs(what, frame, "LeftButton", nil, "target", nil)
      clickIs(what, frame, "RightButton", nil, "menu", nil)
    end
    STUB.actions, STUB.macros = {}, {}
    ns.settings.targeting = "mouseover"
    try("unit frames apply", ns.Layout.Execute, ns.Layout.BuildPlan())
    for _, f in ipairs({ P1, P2, PlayerFrame, TargetFrame }) do planned("apply", f) end
    -- Frames made later (the compact party frames) get them through the SecureUnitButton_OnLoad hook; in combat
    -- they wait for PLAYER_REGEN_ENABLED (setting them in combat would be blocked).
    STUB.combat = true
    local C1
    try("unit frames combat frame", function() C1 = STUB.unitFrame("CompactPartyFrameMember1", "party1") end)
    try("unit frames combat update", ns.UnitFrames.Update)
    if C1 then clickIs("combat", C1, "Button4", nil, nil, nil) end
    STUB.combat = false
    STUB.fire("PLAYER_REGEN_ENABLED")
    STUB.runTimers()
    if C1 then planned("after combat", C1) end
    -- An attribute something else set stays, and /sensei verify names the skip.
    local C2 = STUB.unitFrame("CompactPartyFrameMember2", "party2")
    C2:SetAttribute("type4", "focus")
    STUB.runTimers()
    clickIs("foreign", C2, "Button4", nil, "focus", nil)
    clickIs("foreign", C2, "Button5", nil, "macro", "FS_BOF")
    local report = table.concat(ns.UnitFrames.Report(), "\n")
    if not report:find("skipped CompactPartyFrameMember2 BUTTON4", 1, true) then fail("unit frames: verify does not list the skipped frame:\n" .. report) end
    if not report:find("keys: BUTTON4, BUTTON5, SHIFT-BUTTON4", 1, true) then fail("unit frames: verify keys:\n" .. report) end
    -- Click mode: plain spells, cast on the frame's unit.
    try("unit frames click mode", ns.Layout.SetTargeting, "click")
    clickIs("click mode", P1, "Button4", nil, "spell", cleanseId)
    try("unit frames mouseover mode", ns.Layout.SetTargeting, "mouseover")
    planned("mouseover again", P1)
    -- A key bound to something else gets nothing; GROUP_ROSTER_UPDATE puts it back once the key is back.
    STUB.bindings["BUTTON5"] = "TOGGLEAUTORUN"
    STUB.fire("UPDATE_BINDINGS")
    STUB.runTimers()
    clickIs("rebound", P1, "Button5", nil, nil, nil)
    STUB.bindings["BUTTON5"] = "MULTIACTIONBAR5BUTTON2"
    STUB.fire("GROUP_ROSTER_UPDATE")
    STUB.runTimers()
    clickIs("roster", P1, "Button5", nil, "macro", "FS_BOF")
    -- The setting and Clique switch it off (ours are cleared); Blizzard's left and right clicks always stay.
    ns.settings.unitFrameClicks = false
    try("unit frames off", ns.UnitFrames.Update)
    clickIs("setting off", P1, "Button4", nil, nil, nil)
    clickIs("setting off", P1, "LeftButton", nil, "target", nil)
    clickIs("setting off", C2, "Button4", nil, "focus", nil)
    ns.settings.unitFrameClicks = true
    STUB.loaded.Clique = true
    try("unit frames clique", ns.UnitFrames.Update)
    clickIs("clique", P1, "Button5", nil, nil, nil)
    if not table.concat(ns.UnitFrames.Report(), "\n"):find("Clique", 1, true) then fail("unit frames: verify does not say Clique") end
    STUB.loaded.Clique = nil
    try("unit frames on", ns.UnitFrames.Update)
    planned("on again", P1)
    -- 元に戻す empties the bars again: the frames lose ours.
    try("unit frames undo", ns.Layout.Undo)
    clickIs("undo", P1, "Button4", nil, nil, nil)
    clickIs("undo", C1, "Button4", "shift", nil, nil)
    clickIs("undo", P1, "RightButton", nil, "menu", nil)
  end

  -- Level 30: no Swift Judgement (talent at 37) → E empty but bound; no Cleanse (42) → Purify stands in on
  -- Mouse4 with its macro; no Holy Shield (talent at 42) → 3 stays empty.
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
  STUB.actions, STUB.macros = {}, {}
  try("apply 30", ns.Layout.Execute, ns.Layout.BuildPlan())
  checkLayout("level 30")
  auraKeys("level 30")
  if STUB.actions[L.byCombo.opener.slot] then fail("level 30: the opener was placed without Swift Judgement") end
  local m5 = macroAt(L.bySpell.cleanse.slot)
  if not m5 or m5.name ~= "FS_PURIFY" or not m5.body:find("Purify", 1, true) then fail("level 30: Purify not standing in on Mouse4") end
  local a3 = STUB.actions[L.bySpell.holy_shield.slot]
  if a3 then fail("level 30: 3 holds " .. a3[1] .. ":" .. tostring(a3[2]) .. " (" .. tostring(STUB.names[a3[2]]) .. ") before Holy Shield") end
  -- Learn Cleanse at 42: it takes Mouse4.
  STUB.level = 42
  for id, lv in pairs(STUB.levels) do if lv <= 42 then STUB.known[id] = true end end
  forgetTalents()
  try("apply 42", ns.Layout.Execute, ns.Layout.BuildPlan())
  local c5 = macroAt(L.bySpell.cleanse.slot)
  if not c5 or c5.name ~= "FS_CLEANSE" then fail("level 42: Cleanse did not take Mouse4") end

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
  -- An aura: its card points at Action Bar 3 and Ctrl+1.
  local ret = ns.Spells.Get("retribution_aura")
  local rw = ns.Spells.WhereText(ret) or ""
  if not rw:find(ns.KeyLabel("CTRL-1"), 1, true) or not rw:find(ns.T("ui.bar.bar3"), 1, true) then
    fail("card: an aura's place should be Action Bar 3, Ctrl+1: " .. rw)
  end

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
