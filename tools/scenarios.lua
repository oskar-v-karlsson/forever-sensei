-- tools/scenarios.lua: drives the addon through its windows and actions inside the fake client (tools/wow_stub.lua).
-- Returns run(ns, lang) → { errors = {...}, notes = {...}, report = <formatted report text> }.
return function(ns, lang)
  local errors, notes = {}, {}
  local function fail(msg) table.insert(errors, "[" .. lang .. "] " .. msg) end
  local function try(label, fn, ...)
    local ok, err = pcall(fn, ...)
    if not ok then fail(label .. ": " .. tostring(err)) end
    STUB.runTimers()
    return ok
  end
  ns.settings.language = lang
  if not ns.Active() or ns.class.classFile ~= "SHAMAN" or ns.specId ~= "RESTORATION" then
    fail("class pack: ForeverSensei_Shaman (Restoration) is not active")
    return { errors = errors, notes = notes }
  end
  local L = ns.spec.layout

  -- Popup layout: every text inside its window, wrapped, not overlapping (STUB.checkLayout).
  local layoutFails = 0
  local function fits(label, frame)
    if type(frame) == "string" then frame = _G[frame] end
    if not frame or not frame:IsShown() then return end
    for _, p in ipairs(STUB.checkLayout(frame)) do
      layoutFails = layoutFails + 1
      if layoutFails <= 25 then fail("layout " .. label .. ": " .. p) end
    end
  end

  -- Every skill card (as a new skill and from the skill list), the trainer list for every level, every guide tab,
  -- the talent hint.
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
  -- The pack's text tabs first, then the core's.
  local tabs = { "role", "healing", "damage", "totems", "manners", "skills", "layout", "talents", "review", "settings" }
  for i, tab in ipairs(tabs) do
    try("guide " .. tab, ns.Guide.Open, tab)
    if ns.Guide.Current and ns.Guide.Current() ~= tab then fail("guide: tab " .. tab .. " did not open") end
    if i == 1 and _G.ForeverSenseiGuide and not _G.ForeverSenseiGuide:IsShown() then fail("guide: window not shown") end
  end
  for lv = 10, 60, 5 do
    STUB.level, STUB.unspent = lv, 1
    try("talent hint " .. lv, ns.Talents.ShowHint, true)
    fits("talent hint " .. lv, "ForeverSenseiTalentHint")
  end
  STUB.unspent = 0

  -- Readable talent tree: the player followed the path up to the point before this level → next is that level's step.
  local T = ns.spec.talents
  for _, lv in ipairs({ 10, 25, 40, 60 }) do
    local ranks = {}
    for i = 1, lv - 10 do ranks[T.order[i].key] = (ranks[T.order[i].key] or 0) + 1 end
    local nodes = {}
    for _, t in ipairs(T.list) do table.insert(nodes, { spell = t.id, rank = ranks[t.key] or 0, max = t.max }) end
    table.insert(nodes, { spell = 99999, rank = lv == 40 and 1 or 0, max = 5 })
    STUB.traits, STUB.level = { nodes = nodes, unspent = 1 }, lv
    local s = ns.Talents.State()
    local want = T.order[lv - 9]
    if not s.readable then fail("talents: fake tree not readable")
    elseif not s.next or s.next.key ~= want.key or s.next.rank ~= want.rank then
      fail("talents: level " .. lv .. " next " .. tostring(s.next and s.next.key) .. ", expected " .. want.key)
    end
    if lv == 40 and (not s.offPlan or s.offPlan[1] ~= "Convection") then fail("talents: off-plan talent not reported") end
    try("talent hint traits " .. lv, ns.Talents.ShowHint, true)
    fits("talent hint traits " .. lv, "ForeverSenseiTalentHint")
  end
  STUB.traits = nil

  -- Full layout (mouseover macros): preview, apply, check, undo, check.
  STUB.level = 60
  for id in pairs(STUB.names) do STUB.known[id] = true end
  -- No key is the player's own since layout 7: buttons 5 and Shift+5 (slots 5, 65) and Action Bar 6's button 5
  -- (slot 149) are planned like the rest, and what was there moves to a spare button or is replaced.
  STUB.actions = { [1] = { "spell", 403 }, [2] = { "item", 6948 }, [7] = { "spell", 331 }, [13] = { "spell", 324 },
    [5] = { "item", 6948 }, [65] = { "spell", 324 }, [149] = { "spell", 403 } }
  STUB.bindings = { ["Q"] = "STRAFELEFT", ["E"] = "STRAFERIGHT", ["1"] = "ACTIONBUTTON1", ["SHIFT-1"] = "ACTIONPAGE1",
    ["CTRL-1"] = "SHAPESHIFTBUTTON1", ["5"] = "ACTIONBUTTON5", ["SHIFT-5"] = "MULTIACTIONBAR1BUTTON5",
    ["CTRL-5"] = "SHAPESHIFTBUTTON5" }
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
  local beforeA, beforeB = snapshot()

  local function checkLayout(mode)
    for _, s in ipairs(L.slots) do
      local entry = s.spell and ns.Spells.Get(s.spell)
      local a = STUB.actions[s.slot]
      if not a then
        fail(mode .. ": slot " .. s.slot .. " empty, expected " .. (s.spell or ("@" .. s.item)))
      elseif s.item then
        local m = a[1] == "macro" and STUB.macros[a[2]]
        local want = ns.ItemData.kinds[s.item].macro
        if not m or m.name ~= want or not m.body:find("/use item:", 1, true) then
          fail(mode .. ": slot " .. s.slot .. " should hold item macro " .. want)
        end
      elseif ns.Layout.UsesMacro(entry) then
        local m = STUB.macros[a[2]]
        local kind = L.macroKind[s.spell] or "help"
        if a[1] ~= "macro" or not m or m.name ~= L.macros[s.spell] then
          fail(mode .. ": slot " .. s.slot .. " should hold macro " .. L.macros[s.spell])
        elseif not m.body:find(entry.name, 1, true) or (m.body:find("@mouseover", 1, true) ~= nil) ~= (mode == "mouseover")
          or (kind == "interrupt" and not m.body:find("/stopcasting", 1, true))
          or (kind == "harm" and not m.body:find("harm", 1, true))
          or (kind == "nshw" and not m.body:find("/cast Nature's Swiftness\n", 1, true))
          or (kind == "nshw" and not m.body:find("Healing Wave", 1, true)) then
          fail(mode .. ": macro " .. m.name .. " body wrong: " .. m.body)
        end
      elseif a[1] ~= "spell" or STUB.names[a[2]] ~= entry.name then
        fail(mode .. ": slot " .. s.slot .. " holds " .. tostring(a[1]) .. ":" .. tostring(a[2]) .. ", expected " .. entry.name)
      end
      if s.key and STUB.bindings[s.key] ~= s.binding then
        fail(mode .. ": key " .. s.key .. " bound to " .. tostring(STUB.bindings[s.key]) .. ", expected " .. s.binding)
      end
    end
    for _, bar in ipairs(L.bars) do
      if bar.setting and STUB.settings[bar.setting] ~= true then fail(mode .. ": " .. bar.id .. " not shown") end
    end
    for _, bar in ipairs(L.retired) do
      if not bar.keepShown and STUB.settings[bar.setting] then fail(mode .. ": retired " .. bar.id .. " is shown") end
    end
  end

  ns.settings.targeting = "mouseover"
  if try("preview", ns.Layout.Preview) then
    local p = _G.ForeverSenseiPreview
    if not p or not p:IsShown() then
      fail("preview window not shown")
    else
      fits("preview", p)
      local text = table.concat(ns.Layout.Describe(ns.Layout.BuildPlan()), "\n")
      for _, want in ipairs({ ns.T("ui.preview.warn.stance", { key = "Ctrl+1, Ctrl+2, Ctrl+3, Ctrl+4, Ctrl+5" }),
        ns.T("ui.preview.warn.fps", { key = "Ctrl+R" }), ns.T("ui.preview.warn.mouse"),
        ns.T("ui.preview.warn.editmode", { bar = ns.T("ui.bar.bar6") }),
        ns.T("ui.preview.warn.middle", { key = ns.KeyLabel("BUTTON3") }) }) do
        if not text:find(want, 1, true) then fail("preview: missing the note " .. want) end
      end
      try("apply", function() p.apply:Click() end)
      checkLayout("mouseover")
      -- Every key of a keyed bar is bound, also spare ones (empty buttons): Ctrl is Action Bar 3, and the mouse
      -- buttons fire Action Bar 6 1-6.
      for _, sp in ipairs(L.spare) do
        if sp.key and STUB.bindings[sp.key] ~= sp.binding then fail("apply: spare key " .. sp.key .. " not bound to " .. sp.binding) end
      end
      for key, want in pairs({ ["CTRL-R"] = "MULTIACTIONBAR2BUTTON8", ["CTRL-4"] = "MULTIACTIONBAR2BUTTON4",
        ["CTRL-C"] = "MULTIACTIONBAR2BUTTON12", ["5"] = "ACTIONBUTTON5", ["SHIFT-5"] = "MULTIACTIONBAR1BUTTON5",
        ["BUTTON4"] = "MULTIACTIONBAR5BUTTON1", ["CTRL-BUTTON5"] = "MULTIACTIONBAR5BUTTON6",
        ["BUTTON3"] = "MULTIACTIONBAR5BUTTON9" }) do
        if STUB.bindings[key] ~= want then fail("apply: " .. key .. " should be bound to " .. want) end
      end
      -- Skyborne racials (layout 8): Walk on Air on the middle mouse button (Action Bar 6 button 9), Skysight clicked
      -- next to it; Shift and Ctrl+BUTTON3 stay unbound.
      for slot, key in pairs({ [153] = "walk_on_air", [154] = "skysight" }) do
        local a = STUB.actions[slot]
        if not a or a[1] ~= "spell" or a[2] ~= ns.Spells.Get(key).id then fail("apply: slot " .. slot .. " should hold " .. key) end
      end
      if STUB.bindings["SHIFT-BUTTON3"] or STUB.bindings["CTRL-BUTTON3"] then fail("apply: Shift or Ctrl+Mouse 3 got bound") end
      if not L.bySpell.lightning_shield or STUB.actions[L.bySpell.lightning_shield.slot] == nil then
        fail("apply: Lightning Shield not on its own button once Water Shield is known")
      end
      if STUB.settings.PROXY_SHOW_ACTIONBAR_6 ~= true then fail("apply: Action Bar 6 (mouse buttons) not shown") end
    end
  end
  local planAfter = ns.Layout.BuildPlan()
  if not ns.Layout.IsEmptyPlan(planAfter) then fail("plan not empty after apply") end
  if STUB.cursor then fail("cursor not empty after apply") end

  -- Mouse 4/5 over a party portrait (0.8.0): the frame takes those buttons, so it gets the bar buttons' actions.
  local function portrait(what, button, mod, wantT, wantV)
    local t, v, unit = STUB.unitClick(PartyFrame.MemberFrame1, button, mod)
    if t ~= wantT or v ~= wantV or unit ~= "party1" then
      fail("unit frames " .. what .. ": " .. (mod and (mod .. "-") or "") .. button .. " is " .. tostring(t) .. " " ..
        tostring(v) .. ", expected " .. tostring(wantT) .. " " .. tostring(wantV))
    end
  end
  local spellId = function(key) return ns.Spells.CurrentID(ns.Spells.Get(key)) end
  portrait("mouseover", "Button4", nil, "macro", "FS_RT")
  portrait("mouseover", "Button5", nil, "macro", "FS_NSHW")
  portrait("mouseover", "Button4", "shift", "macro", "FS_CP")
  portrait("mouseover", "Button5", "shift", "macro", "FS_CD")
  portrait("mouseover", "Button4", "ctrl", "spell", spellId("poison_cleansing_totem"))
  portrait("mouseover", "Button5", "ctrl", "spell", spellId("disease_cleansing_totem"))
  portrait("mouseover", "LeftButton", nil, "target", nil)
  portrait("mouseover", "RightButton", nil, "menu", nil)
  -- Walk on Air (middle mouse button) is self-only: a middle click on a portrait keeps the frame's own behaviour.
  portrait("mouseover", "MiddleButton", nil, nil, nil)
  portrait("mouseover", "MiddleButton", "shift", nil, nil)

  try("targeting click", ns.Layout.SetTargeting, "click")
  checkLayout("click")
  portrait("click", "Button4", nil, "spell", spellId("riptide"))
  try("targeting mouseover", ns.Layout.SetTargeting, "mouseover")
  checkLayout("mouseover")
  portrait("mouseover again", "Button4", nil, "macro", "FS_RT")

  -- Undo the targeting swaps and the full layout: back to the starting bars and keys.
  local undos = 0
  while ns.Layout.CanUndo() and undos < 10 do
    try("undo", ns.Layout.Undo)
    undos = undos + 1
  end
  local afterA, afterB = snapshot()
  local ok, why = same(beforeA, afterA)
  if not ok then fail("undo did not restore action slots: " .. why) end
  ok, why = same(beforeB, afterB)
  if not ok then fail("undo did not restore key bindings: " .. why) end
  if STUB.cursor then fail("cursor not empty after undo") end
  table.insert(notes, "undo steps: " .. undos)

  -- The Hearthstone was on main button 2 (now Flame Shock): it moves to the first spare button (one without a key).
  -- (Checked on the applied layout above through the undo: here only the destination rule.)
  STUB.actions = { [2] = { "item", 6948 } }
  local movePlan = ns.Layout.BuildPlan()
  local mv = movePlan.moves[1]
  if L.spare[1].key or not mv or mv.from ~= 2 or mv.toSlot.bar ~= L.spare[1].bar or mv.to ~= L.spare[1].slot then
    fail("layout: a displaced action should move to the first spare button, which has no key")
  end
  local needsBar = false
  for _, bar in ipairs(movePlan.bars) do needsBar = needsBar or bar.id == L.spare[1].bar end
  if not needsBar then fail("layout: the spare button's bar not shown although something moves there") end

  -- 0.4.0 (layout 3) players: Action Bars 6 and 7 are shown and hold the Ctrl and mouse spells, and their keys point
  -- there. Action Bar 6 is planned again (the mouse buttons); Action Bar 7 is retired: a full apply clears the plan's
  -- spells on its buttons and hides it, but keeps anything that isn't the plan's. The old Ctrl and mouse keys are
  -- bound to their new buttons. Undo restores it all.
  local function idOf(key) return ns.Spells.CurrentID(ns.Spells.Get(key)) end
  STUB.actions = { [145] = { "spell", idOf("totemic_recall") }, [157] = { "spell", idOf("riptide") },
    [158] = { "item", 6948 }, [163] = { "spell", 403 } }
  STUB.bindings = { ["CTRL-1"] = "MULTIACTIONBAR5BUTTON1", ["BUTTON4"] = "MULTIACTIONBAR6BUTTON1",
    ["CTRL-2"] = "MULTIACTIONBAR5BUTTON2", ["CTRL-5"] = "MULTIACTIONBAR5BUTTON5" }
  STUB.settings.PROXY_SHOW_ACTIONBAR_6, STUB.settings.PROXY_SHOW_ACTIONBAR_7 = true, true
  local function settingsSnap()
    local t = {}
    for k, v in pairs(STUB.settings) do t[k] = tostring(v) end
    return t
  end
  local migA, migB = snapshot()
  local migS = settingsSnap()
  local migPlan = ns.Layout.BuildPlan()
  local migText = table.concat(ns.Layout.Describe(migPlan), "\n")
  if #migPlan.hide ~= 1 or migPlan.hide[1].id ~= "bar7" or not migText:find(ns.T("ui.preview.hide"), 1, true) then
    fail("migration: the preview does not list Action Bar 7 (only) as hidden")
  end
  try("migration apply", ns.Layout.Execute, migPlan)
  checkLayout("mouseover") -- (migration)
  if STUB.actions[157] then fail("migration: layout 3's Riptide left on Action Bar 7") end
  if not (STUB.actions[158] and STUB.actions[158][2] == 6948 and STUB.actions[163] and STUB.actions[163][2] == 403) then
    fail("migration: a button on Action Bar 7 that isn't the plan's was cleared")
  end
  if STUB.settings.PROXY_SHOW_ACTIONBAR_6 ~= true or STUB.settings.PROXY_SHOW_ACTIONBAR_7 then
    fail("migration: Action Bar 6 should stay shown and Action Bar 7 be hidden")
  end
  for key, want in pairs({ ["CTRL-1"] = "MULTIACTIONBAR2BUTTON1", ["CTRL-2"] = "MULTIACTIONBAR2BUTTON2",
    ["CTRL-5"] = "MULTIACTIONBAR2BUTTON5", ["BUTTON4"] = "MULTIACTIONBAR5BUTTON1" }) do
    if STUB.bindings[key] ~= want then fail("migration: " .. key .. " not moved to " .. want) end
  end
  if not ns.Layout.IsEmptyPlan(ns.Layout.BuildPlan()) then fail("migration: plan not empty after apply") end
  try("migration undo", ns.Layout.Undo)
  local mA, mB = snapshot()
  ok, why = same(migA, mA)
  if not ok then fail("migration undo: action slots differ: " .. why) end
  ok, why = same(migB, mB)
  if not ok then fail("migration undo: key bindings differ: " .. why) end
  ok, why = same(migS, settingsSnap())
  if not ok then fail("migration undo: bar settings differ: " .. why) end

  -- Clean bars: asks first, empties only the buttons the addon configures (planned slots, including ones kept free for
  -- spells not learned yet, layout 6's buttons on Action Bar 5 and layout 3's on Action Bar 7), keeps spare buttons,
  -- the other buttons of the retired bars and everything else, and Undo puts everything back.
  local spare = L.spare[1].slot
  local unlearned = L.bySpell.chain_heal.slot
  local bar6Spare
  for _, sp in ipairs(L.spare) do if sp.bar == "bar6" then bar6Spare = bar6Spare or sp.slot end end
  for _, sl in ipairs(L.slots) do
    if sl.slot == spare or sl.slot == bar6Spare or sl.slot == 39 or sl.slot == 163 then
      fail("clean: test slot " .. sl.slot .. " is planned")
    end
  end
  local knownBefore = STUB.known
  STUB.known = {}
  for id in pairs(knownBefore) do STUB.known[id] = true end
  for _, id in ipairs(ns.Spells.Ranks(ns.Spells.Get("chain_heal"))) do STUB.known[id] = nil end
  if ns.Spells.IsKnown(ns.Spells.Get("chain_heal")) then
    fail("clean: Chain Heal should be unlearned here, to test a slot kept free for it")
  end
  -- Planned: 1 (Flame Shock), 30 (Action Bar 4 button 6), 45 (Action Bar 5 button 9, layout 6), 160 (Action Bar 7
  -- button 4, layout 3) and Chain Heal's button. Kept: 100, the first spare, a spare on Action Bar 6, Action Bar 5
  -- button 3 and Action Bar 7 button 7 (no layout filled them last).
  STUB.actions = { [1] = { "spell", 403 }, [30] = { "item", 6948 }, [45] = { "spell", 331 }, [160] = { "spell", 324 },
    [100] = { "spell", 403 }, [spare] = { "spell", 324 }, [bar6Spare] = { "spell", 403 }, [39] = { "item", 6948 },
    [163] = { "spell", 403 }, [unlearned] = { "spell", 403 } }
  local clA = snapshot()
  try("clean", ns.Layout.Clean)
  local cf = _G.ForeverSenseiConfirm
  if not cf or not cf:IsShown() or not (cf.text:GetText() or ""):find(ns.T("ui.clean.confirm", { n = 5 }), 1, true) then
    fail("clean: no confirmation for the 5 planned buttons shown")
  else
    fits("clean confirm", cf)
    try("clean confirm", function() cf.yes:Click() end)
  end
  local keepSlots = { [100] = true, [spare] = true, [bar6Spare] = true, [39] = true, [163] = true }
  for slot in pairs(clA) do
    local keep = keepSlots[slot] or false
    if (STUB.actions[slot] ~= nil) ~= keep then fail("clean: slot " .. slot .. (keep and " was emptied" or " still set")) end
  end
  try("clean undo", ns.Layout.Undo)
  ok, why = same(clA, (snapshot()))
  if not ok then fail("clean undo: action slots differ: " .. why) end
  STUB.actions = { [100] = { "spell", 403 }, [39] = { "item", 6948 }, [spare] = { "spell", 324 } }
  STUB.known = knownBefore
  if cf then cf:Hide() end
  try("clean nothing", ns.Layout.Clean)
  if cf and cf:IsShown() then fail("clean: asked although only buttons the addon doesn't configure hold something") end
  -- Something Undo can't restore (a mount) is named in the question.
  STUB.actions = { [L.bySpell.earthbind_totem.slot] = { "summonmount", 7 } }
  try("clean mount", ns.Layout.Clean)
  cf = _G.ForeverSenseiConfirm
  local nr = ns.T("ui.clean.norestore", { list = "" })
  if not cf or not (cf.text:GetText() or ""):find(nr:sub(1, 20), 1, true) then
    fail("clean: the question does not name what Undo can't restore")
  end
  if cf then cf:Hide() end

  -- Place one spell (card button), with something else in its slot → asks first.
  local ch = ns.Spells.Get("chain_heal")
  local chSlot, chKey = L.bySpell.chain_heal.slot, L.bySpell.chain_heal.key
  STUB.actions = { [chSlot] = { "spell", 403 } }
  try("place one", ns.Layout.PlaceOne, ch)
  local confirm = _G.ForeverSenseiConfirm
  fits("confirm", confirm)
  if confirm and confirm:IsShown() and confirm.yes then try("place confirm", function() confirm.yes:Click() end) end
  local a = STUB.actions[chSlot]
  if not a or not ((a[1] == "macro" and STUB.macros[a[2]].name == "FS_CH") or (a[1] == "spell" and STUB.names[a[2]] == "Chain Heal")) then
    fail("place one: Chain Heal not in slot " .. chSlot)
  end
  if STUB.bindings[chKey] ~= L.bySpell.chain_heal.binding then fail("place one: key " .. chKey .. " not bound") end

  -- Combat: nothing changes, actions are queued and run after combat.
  STUB.combat = true
  STUB.actions = {}
  try("combat place", ns.Layout.PlaceOne, ns.Spells.Get("healing_wave"))
  try("combat preview", ns.Layout.Preview)
  if next(STUB.actions) then fail("bars changed in combat") end
  STUB.combat = false
  STUB.fire("PLAYER_REGEN_ENABLED")
  STUB.runTimers()

  -- New skill learned while playing → card queued and shown.
  STUB.level = 20
  STUB.known = {}
  for id, lv in pairs(STUB.levels) do if lv <= 18 then STUB.known[id] = true end end
  ns.char.known, ns.char.initialised = {}, false
  try("scan initial", ns.NewSkill.Scan)
  local card = _G.ForeverSenseiCard
  if card then card:Hide() end
  local ws = ns.Spells.Get("water_shield")
  STUB.known[ws.id] = true
  STUB.fire("LEARNED_SPELL_IN_SKILL_LINE", ws.id, 1)
  STUB.runTimers()
  card = _G.ForeverSenseiCard
  if not card or not card:IsShown() or not card.entry or card.entry.key ~= "water_shield" then
    fail("no card for a newly learned spell (Water Shield)")
  end

  -- New rank learned. Bars hold Healing Wave rank 2 (its slot) and rank 4 (another slot); rank 5 is learned in
  -- combat → nothing changes until combat ends, then both buttons hold rank 5 and a toast offers undo.
  ns.settings.targeting = "click"
  local hw = ns.Spells.Get("healing_wave")
  local hwR = ns.Spells.Ranks(hw)
  local hwSlot = L.bySpell.healing_wave.slot
  local other = 100
  if #hwR < 7 then fail("ranks: Healing Wave has " .. #hwR .. " ranks") end
  if ns.Spells.KnownRank(hw) ~= 4 then fail("ranks: known Healing Wave rank " .. tostring(ns.Spells.KnownRank(hw)) .. ", expected 4") end
  if ns.Spells.CurrentID(hw) ~= hwR[4] then fail("ranks: CurrentID is not rank 4") end
  STUB.actions = { [hwSlot] = { "spell", hwR[2] }, [other] = { "spell", hwR[4] } }
  ns.char.keepRank = {}
  STUB.bindings[L.bySpell.healing_wave.key] = L.bySpell.healing_wave.binding
  local function holds(slot, id) return STUB.actions[slot] and STUB.actions[slot][2] == id end
  STUB.combat = true
  STUB.known[hwR[5]] = true
  STUB.fire("SPELLS_CHANGED")
  STUB.runTimers()
  if not holds(hwSlot, hwR[2]) or not holds(other, hwR[4]) then fail("ranks: bars changed in combat") end
  STUB.combat = false
  STUB.fire("PLAYER_REGEN_ENABLED")
  STUB.runTimers()
  if not holds(hwSlot, hwR[5]) or not holds(other, hwR[5]) then fail("ranks: buttons not upgraded to rank 5 after combat") end
  if STUB.cursor then fail("ranks: cursor not empty after upgrade") end
  local toast = _G.ForeverSenseiToast
  if not toast or not toast:IsShown() or not toast.button:IsShown() or not tostring(toast.text:GetText()):find("Rank 5", 1, true) then
    fail("ranks: no toast with undo for the new rank")
  else
    fits("rank toast", toast)
    try("rank undo", function() toast.button:Click() end)
  end
  if not holds(hwSlot, hwR[2]) or not holds(other, hwR[4]) then fail("ranks: undo did not restore the old ranks") end
  if ns.char.keepRank[hwSlot] ~= hwR[2] then fail("ranks: undo did not mark the slot to keep its rank") end
  try("rank login scan", ns.NewSkill.Scan, true)
  if not holds(hwSlot, hwR[2]) then fail("ranks: a kept rank was upgraded again") end
  if not ns.Layout.IsPlaced(hw) then fail("ranks: a kept rank does not count as placed") end
  -- Setting off: a new rank only gives the toast.
  ns.settings.autoRanks = false
  STUB.actions = { [other] = { "spell", hwR[5] } }
  STUB.known[hwR[6]] = true
  STUB.fire("SPELLS_CHANGED")
  STUB.runTimers()
  if not holds(other, hwR[5]) then fail("ranks: upgraded although auto ranks is off") end
  ns.settings.autoRanks = true
  try("rank login scan 2", ns.NewSkill.Scan, true)
  if not holds(other, hwR[6]) then fail("ranks: login scan did not upgrade an old rank") end

  -- Mouseover macro and ranks: if "/cast Healing Wave" casts rank 1, the macro names the highest rank; once the
  -- plain name works again it goes back to the plain name.
  ns.settings.targeting = "mouseover"
  local mname = L.macros.healing_wave
  try("macro create", ns.Layout.EnsureMacro, hw)
  STUB.macroPlainRank1 = true
  local okR, res = pcall(ns.Layout.CheckMacroRank, hw)
  local midx = GetMacroIndexByName(mname)
  local body = STUB.macros[midx] and STUB.macros[midx].body or ""
  if not okR or res ~= "ranked" or not body:find("Healing Wave(Rank 6)", 1, true) then
    fail("macro rank: expected 'ranked' and Healing Wave(Rank 6), got " .. tostring(res) .. " / " .. body)
  end
  if GetMacroSpell(midx) ~= hwR[6] then fail("macro rank: macro does not cast rank 6") end
  STUB.macroPlainRank1 = false
  okR, res = pcall(ns.Layout.CheckMacroRank, hw)
  if not okR or res ~= "ranked" then fail("macro rank: a working named rank should stay, got " .. tostring(res)) end
  STUB.known[hwR[7]] = true
  okR, res = pcall(ns.Layout.CheckMacroRank, hw)
  body = STUB.macros[midx] and STUB.macros[midx].body or ""
  if not okR or res ~= "ok" or body:find("(Rank", 1, true) then
    fail("macro rank: expected the plain name back, got " .. tostring(res) .. " / " .. body)
  end
  ns.settings.targeting = "click"

  -- Card from the skill list while a new-skill card is open: the list card shows (title "Skill", no Later button,
  -- Place it works for a learned skill), and the new-skill card comes back after closing it.
  STUB.actions = {}
  ns.char.keepRank = {}
  try("card new", ns.NewSkill.ShowCard, ws)
  try("card from list", ns.NewSkill.ShowCard, hw, true)
  card = _G.ForeverSenseiCard
  if card.entry.key ~= "healing_wave" or card.title:GetText() ~= ns.T("ui.card.view") or card.later:IsShown() then
    fail("card from list: wrong card, title or buttons")
  end
  if not card.place:IsEnabled() then fail("card from list: Place it disabled for a learned skill") end
  if card.status:GetText() ~= ns.T("ui.card.notplaced") then fail("card from list: no 'not placed' line") end
  try("card place", function() card.place:Click() end)
  if confirm and confirm:IsShown() then try("card place confirm", function() confirm.yes:Click() end) end
  if not holds(hwSlot, hwR[7]) then fail("card from list: Place it did not put the highest Healing Wave rank in its slot") end
  if card.status:GetText() ~= ns.T("ui.card.placed") then fail("card from list: placed line not updated") end
  fits("card from list", card)
  try("card from list close", function() card.close:Click() end)
  if not card:IsShown() or card.entry.key ~= "water_shield" or card.title:GetText() ~= ns.T("ui.card.title") then
    fail("card from list: the new-skill card did not come back")
  end
  try("card unknown from list", ns.NewSkill.ShowCard, ns.Spells.Get("chain_heal"), true)
  if card.place:IsEnabled() then fail("card from list: Place it enabled for a skill the player does not know") end
  card:Hide()

  -- Login bug (0.2.0): a totem closed with "Later" and then placed (Apply full layout or by hand) got its card back
  -- at every login. Now a placed skill leaves the "later" list, and at login no card opens for a "later" skill.
  local function relogin()
    if _G.ForeverSenseiToast then _G.ForeverSenseiToast:Hide() end
    if _G.ForeverSenseiConfirm then _G.ForeverSenseiConfirm:Hide() end
    -- A reload starts with an empty card queue (cards re-queued by the list cards above are session state).
    for _ = 1, 30 do ns.NewSkill.Next() end
    card:Hide()
    ns.ready = false -- a /reload starts a new Lua session
    STUB.fire("PLAYER_LOGIN")
    STUB.runTimers()
  end
  local stoneskin = ns.Spells.Get("stoneskin_totem")
  local ss = L.bySpell.stoneskin_totem
  STUB.known[stoneskin.id] = true
  ns.char.known.stoneskin_totem = true
  ns.char.ranks = ns.char.ranks or {}
  ns.char.ranks.stoneskin_totem = ns.Spells.CurrentID(stoneskin)
  STUB.actions = { [ss.slot] = { "spell", ns.Spells.CurrentID(stoneskin) } }
  STUB.bindings[ss.key] = ss.binding
  STUB.settings.PROXY_SHOW_ACTIONBAR_2, STUB.settings.PROXY_SHOW_ACTIONBAR_3 = true, true
  ns.char.postponed = { stoneskin_totem = true }
  ns.char.layoutVersion = L.version
  if ns.Layout.IsPlaced(stoneskin) ~= true then fail("login: Stoneskin Totem setup is not placed") end
  relogin()
  if card:IsShown() then fail("login: a card opened for a skill that is already in its slot (" .. tostring(card.entry and card.entry.key) .. ")") end
  if ns.char.postponed.stoneskin_totem then fail("login: a placed skill stayed on the 'later' list") end
  -- A "later" skill that is not placed: no card at login, a toast with a button that opens it.
  local purge = ns.Spells.Get("purge")
  STUB.known[purge.id] = true
  ns.char.known.purge = true
  ns.char.postponed = { purge = true }
  relogin()
  toast = _G.ForeverSenseiToast
  if card:IsShown() then fail("login: a card opened at login for a 'later' skill") end
  if not toast or not toast:IsShown() or toast.text:GetText() ~= ns.T("ui.card.postponed", { n = 1 }) then
    fail("login: no toast for the 'later' skills")
  else
    fits("later toast", toast)
    try("later toast show", function() toast.button:Click() end)
    if not card:IsShown() or card.entry.key ~= "purge" then fail("login: the toast button did not open the 'later' card") end
  end
  card:Hide()
  ns.char.postponed = {}
  -- Apply full layout takes placed skills off the "later" list too.
  ns.char.postponed = { stoneskin_totem = true }
  STUB.actions = {}
  try("later apply", function() ns.Layout.Execute(ns.Layout.BuildPlan("stoneskin_totem")) end)
  if ns.char.postponed.stoneskin_totem then fail("login: Apply did not take the placed skill off the 'later' list") end

  -- Players who had the old layout get one notice that offers the preview; nothing moves by itself.
  STUB.actions = { [1] = { "spell", ns.Spells.CurrentID(ns.Spells.Get("healing_wave")) } }
  local before = STUB.actions[1][2]
  ns.char.layoutVersion = nil
  relogin()
  confirm = _G.ForeverSenseiConfirm
  if not confirm or not confirm:IsShown() or confirm.text:GetText() ~= ns.T("ui.layout.changed") then
    fail("layout notice: not shown to a player with the old layout")
  else
    fits("layout notice", confirm)
    try("layout notice preview", function() confirm.yes:Click() end)
    if not _G.ForeverSenseiPreview or not _G.ForeverSenseiPreview:IsShown() then fail("layout notice: button did not open the preview") end
    _G.ForeverSenseiPreview:Hide()
  end
  if not STUB.actions[1] or STUB.actions[1][2] ~= before or STUB.actions[2] then fail("layout notice: bars changed by themselves") end
  if ns.char.layoutVersion ~= L.version then fail("layout notice: version not saved") end
  relogin()
  if confirm and confirm:IsShown() then fail("layout notice: shown twice") end
  ns.char.layoutVersion = nil
  ns.char.initialised = false
  ns.ready = false
  STUB.fire("PLAYER_LOGIN")
  if ns.char.layoutVersion ~= L.version then fail("layout notice: new character did not get the current version") end
  ns.char.initialised = true
  STUB.runTimers()
  if confirm and confirm:IsShown() then fail("layout notice: shown to a new character") end
  if _G.ForeverSenseiToast then _G.ForeverSenseiToast:Hide() end

  -- Item macros: the best potion in the bags the level allows; silent update after combat; fixed icon with none.
  STUB.level = 20
  STUB.bags, STUB.itemLevels = {}, {}
  local I = ns.Items
  local body, icon = I.MacroBody("mana")
  if body ~= "/use item:3385" or icon ~= ns.ItemData.kinds.mana.icon then
    fail("items: empty bags should give '/use item:3385' and the fixed icon, got " .. body .. " / " .. tostring(icon))
  end
  STUB.bags = { [2455] = 3, [3385] = 1, [3827] = 2 }
  if not I.Best("mana") or I.Best("mana").id ~= 3385 then fail("items: best mana potion at level 20 should be 3385") end
  STUB.itemLevels[3385] = 25
  if not I.Best("mana") or I.Best("mana").id ~= 2455 then fail("items: the client's required level should count") end
  STUB.itemLevels = {}
  STUB.macros = {}
  try("items macro", I.EnsureMacro, "mana")
  local mi = GetMacroIndexByName("FS_MANA")
  if mi == 0 or STUB.macros[mi].body ~= "#showtooltip\n/use item:3385" then fail("items: FS_MANA body wrong") end
  if toast then toast:Hide() end
  STUB.combat = true
  STUB.bags[3385] = nil
  STUB.fire("BAG_UPDATE_DELAYED")
  STUB.runTimers()
  if STUB.macros[mi].body ~= "#showtooltip\n/use item:3385" then fail("items: macro edited in combat") end
  if toast and toast:IsShown() then fail("items: a toast in combat for a bag change") end
  STUB.combat = false
  STUB.fire("PLAYER_REGEN_ENABLED")
  STUB.runTimers()
  if STUB.macros[mi].body ~= "#showtooltip\n/use item:2455" then fail("items: macro not updated after combat: " .. STUB.macros[mi].body) end
  STUB.bags = {}
  STUB.fire("BAG_UPDATE_DELAYED")
  if STUB.macros[mi].body ~= "/use item:3385" or STUB.macros[mi].icon ~= ns.ItemData.kinds.mana.icon then
    fail("items: no potions should give the fixed icon")
  end
  if GetMacroIndexByName("FS_HEALPOT") ~= 0 then fail("items: Refresh created a macro the player did not place") end
  -- A potion placed by hand belongs to the plan: it is replaced by the macro, not moved.
  STUB.actions = { [L.byItem.healpot.slot] = { "item", 929 } }
  local itemPlan = ns.Layout.BuildPlan()
  if #itemPlan.moves > 0 then fail("items: a healing potion on its own slot was moved instead of replaced") end
  local saved = { level = STUB.level, known = STUB.known, actions = STUB.actions, bags = STUB.bags }
  -- FS_HEALTH: a Healthstone first (best the level allows), else the best Healing Potion.
  STUB.level = 30
  STUB.bags = { [929] = 2, [5512] = 1, [5509] = 1 }
  if not I.Best("health") or I.Best("health").id ~= 5509 then fail("items: FS_HEALTH should prefer the Healthstone (5509)") end
  STUB.bags = { [929] = 2, [858] = 1 }
  if not I.Best("health") or I.Best("health").id ~= 929 then fail("items: FS_HEALTH without a Healthstone should use the best Healing Potion") end
  STUB.bags = {}
  if not I.MacroBody("health"):find("/use item:", 1, true) then fail("items: FS_HEALTH body without items wrong") end

  -- Before Water Shield (level 20) Lightning Shield stands in on X; once Water Shield is learned it takes X and
  -- Lightning Shield gets its own clickable button.
  STUB.level = 15
  STUB.known = {}
  for id, lv in pairs(STUB.levels) do if lv <= 15 then STUB.known[id] = true end end
  local ls, wsE = ns.Spells.Get("lightning_shield"), ns.Spells.Get("water_shield")
  local xSlot = L.bySpell.water_shield.slot
  STUB.actions = {}
  if ns.Spells.LayoutSlot(ls).slot ~= xSlot then fail("stand-in: Lightning Shield's slot should be X before Water Shield") end
  try("place stand-in", ns.Layout.PlaceOne, ls)
  local ax = STUB.actions[xSlot]
  if not ax or STUB.names[ax[2]] ~= "Lightning Shield" or STUB.bindings.X ~= L.bySpell.water_shield.binding then
    fail("stand-in: Lightning Shield not placed on X")
  end
  if not ns.Layout.IsPlaced(ls) then fail("stand-in: Lightning Shield on X not reported as placed") end
  STUB.known[wsE.id] = true
  local wsPlan = ns.Layout.BuildPlan()
  local onX, lsOwn
  for _, pl in ipairs(wsPlan.place) do
    if pl.where.slot == xSlot and pl.desired.entry.key == "water_shield" then onX = true end
    if pl.where.slot == L.bySpell.lightning_shield.slot and pl.desired.entry.key == "lightning_shield" then lsOwn = true end
  end
  if not onX or not lsOwn then fail("stand-in: after Water Shield, X should get Water Shield and Lightning Shield its own button") end
  if ns.Spells.LayoutSlot(ls).slot ~= L.bySpell.lightning_shield.slot then fail("stand-in: Lightning Shield's slot after Water Shield") end

  -- Earlier layouts' leftovers: a full apply clears an old button that still holds a spell that has its new place
  -- (Fire Nova on layout 6's Ctrl+R button, Action Bar 5) or now lives only in the spellbook (Sentry Totem, layout 4
  -- on Action Bar 4 button 12). Action Bar 5 button 5 held Mana Tide Totem in layout 4: cleared while it still holds
  -- exactly that, left alone once the player put something else there. Action Bar 5 stays shown.
  STUB.level = 60
  for id in pairs(STUB.names) do STUB.known[id] = true end
  local fn, es = ns.Spells.Get("fire_nova"), ns.Spells.Get("earth_shock")
  local st, mt = ns.Spells.Get("sentry_totem"), ns.Spells.Get("mana_tide_totem")
  STUB.actions = { [44] = { "spell", ns.Spells.CurrentID(fn) }, [36] = { "spell", st.id }, [41] = { "spell", mt.id },
    [40] = { "item", 6948 } }
  STUB.settings.PROXY_SHOW_ACTIONBAR_5 = true
  local oldPlan = ns.Layout.BuildPlan()
  local cleared, touched = {}, false
  for _, c in ipairs(oldPlan.clears) do
    cleared[c.where.slot] = true
    if c.where.slot == 40 then touched = true end
  end
  for _, m in ipairs(oldPlan.moves) do if m.from == 40 then touched = true end end
  for _, h in ipairs(oldPlan.hide) do if h.id == "bar5" then touched = true end end
  if not cleared[44] then fail("old leftover: layout 6's Fire Nova on Action Bar 5 button 8 not cleared") end
  if not cleared[36] then fail("old leftover: Sentry Totem (spellbook only now) on old slot 36 not cleared") end
  if not cleared[41] then fail("old leftover: layout 4's Mana Tide Totem on Action Bar 5 button 5 not cleared") end
  if touched then fail("old leftover: the player's own item on Action Bar 5, or the bar itself, was planned to change") end
  local mtSlot = L.bySpell.mana_tide_totem.slot
  try("old leftover apply", ns.Layout.Execute, oldPlan)
  if STUB.actions[41] or STUB.actions[44] then fail("old leftover: Action Bar 5 still holds an old spell after apply") end
  if not (STUB.actions[40] and STUB.actions[40][2] == 6948) then fail("old leftover: the player's item on Action Bar 5 was cleared") end
  if STUB.settings.PROXY_SHOW_ACTIONBAR_5 ~= true then fail("old leftover: Action Bar 5 was hidden") end
  if not STUB.actions[mtSlot] then fail("old leftover: Mana Tide Totem not on Shift+X after apply") end
  try("old leftover undo", ns.Layout.Undo)
  if not (STUB.actions[41] and STUB.actions[41][2] == mt.id) then fail("old leftover undo: Mana Tide Totem not back on Action Bar 5 button 5") end
  -- Something else of her own there (another spell, or an item) stays.
  for _, mine in ipairs({ { "spell", es.id }, { "item", 6948 } }) do
    STUB.actions = { [41] = mine, [44] = mine }
    for _, c in ipairs(ns.Layout.BuildPlan().clears) do
      if c.slot == 41 or c.slot == 44 then fail("old leftover: the player's own " .. mine[1] .. " on Action Bar 5 was planned to be cleared") end
    end
  end
  STUB.actions = { [44] = { "spell", ns.Spells.CurrentID(fn) }, [41] = { "spell", mt.id } }
  for _, c in ipairs(ns.Layout.BuildPlan("mana_tide_totem").clears) do
    if c.slot == 41 then fail("old leftover: placing one spell cleared Action Bar 5 button 5") end
  end
  for _, c in ipairs(ns.Layout.BuildPlan("fire_nova").clears) do
    if c.slot == 44 then fail("old leftover: placing one spell cleared an old button") end
  end
  STUB.level, STUB.known, STUB.actions, STUB.bags = saved.level, saved.known, saved.actions, saved.bags
  try("old leftover items", ns.Items.Refresh) -- the apply above wrote the item macros for the level-60 bags

  -- Update from layout 6 (0.6.1) to 7 (0.7.0, family blocks): Ctrl moves from Action Bar 5 to Action Bar 3, the mouse
  -- buttons from Action Bar 3 7-12 to Action Bar 6 1-6, and key 5 is planned. One notice, nothing moves by itself; a
  -- full apply moves the spells and keys, shows Action Bar 6, clears layout 6's spells on Action Bar 5 but leaves the
  -- bar shown, and 元に戻す puts back the spells, the keys and the bar settings.
  STUB.level = 60
  for id in pairs(STUB.names) do STUB.known[id] = true end
  local function cur(key) return ns.Spells.CurrentID(ns.Spells.Get(key)) end
  -- Layout 6: Totemic Call on 1, Purge on Shift+3, Totemic Recall Ctrl+1 (37), Fire Nova Ctrl+R (44), Mana Tide
  -- Ctrl+Z (46), Ghost Wolf Ctrl+C (48), Riptide on Mouse4 (Action Bar 3 button 7, 55), the elixir on Action Bar 3
  -- button 5 (53). The player's own Hearthstone on button 5 and on Action Bar 5 button 2.
  STUB.actions = { [1] = { "spell", cur("totemic_call") }, [63] = { "spell", cur("purge") },
    [37] = { "spell", cur("totemic_recall") }, [44] = { "spell", cur("fire_nova") },
    [46] = { "spell", cur("mana_tide_totem") }, [48] = { "spell", cur("ghost_wolf") },
    [55] = { "spell", cur("riptide") }, [5] = { "item", 6948 }, [38] = { "item", 6948 } }
  local savedBinds = {}
  for k, v in pairs(STUB.bindings) do savedBinds[k] = v end
  STUB.bindings = { ["CTRL-1"] = "MULTIACTIONBAR4BUTTON1", ["CTRL-R"] = "MULTIACTIONBAR4BUTTON8",
    ["BUTTON4"] = "MULTIACTIONBAR2BUTTON7", ["CTRL-BUTTON5"] = "MULTIACTIONBAR2BUTTON12", ["5"] = "ACTIONBUTTON5" }
  STUB.settings.PROXY_SHOW_ACTIONBAR_3, STUB.settings.PROXY_SHOW_ACTIONBAR_5 = true, true
  STUB.settings.PROXY_SHOW_ACTIONBAR_6 = false
  local v6A, v6B = snapshot()
  local v6S = settingsSnap()
  ns.char.layoutVersion = 6
  relogin()
  confirm = _G.ForeverSenseiConfirm
  if not confirm or not confirm:IsShown() or confirm.text:GetText() ~= ns.T("ui.layout.changed") then
    fail("layout 7: no notice for a player with layout 6")
  else
    confirm:Hide()
  end
  local nA, nB = snapshot()
  if not same(v6A, nA) or not same(v6B, nB) then fail("layout 7: the notice moved something by itself") end
  local v7Plan = ns.Layout.BuildPlan()
  local v7Cleared, v7Bars = {}, {}
  for _, c in ipairs(v7Plan.clears) do v7Cleared[c.slot] = true end
  for _, bar in ipairs(v7Plan.bars) do v7Bars[bar.id] = true end
  for _, slot in ipairs({ 37, 44, 46, 48 }) do
    if not v7Cleared[slot] then fail("layout 7: layout 6's spell on Action Bar 5 slot " .. slot .. " not cleared") end
  end
  if v7Cleared[38] then fail("layout 7: the player's own item on Action Bar 5 is planned to be cleared") end
  if not v7Bars.bar6 then fail("layout 7: the preview does not show Action Bar 6") end
  for _, h in ipairs(v7Plan.hide) do if h.id == "bar5" then fail("layout 7: Action Bar 5 is planned to be hidden") end end
  local v7Text = table.concat(ns.Layout.Describe(v7Plan), "\n")
  if not v7Text:find(ns.T("ui.preview.warn.editmode", { bar = ns.T("ui.bar.bar6") }), 1, true) then
    fail("layout 7: the preview does not tell the player to move Action Bar 6 in Edit Mode")
  end
  try("layout 7 apply", ns.Layout.Execute, v7Plan)
  checkLayout(ns.settings.targeting) -- (layout 7)
  for _, slot in ipairs({ 37, 44, 46, 48 }) do
    if STUB.actions[slot] then fail("layout 7: Action Bar 5 slot " .. slot .. " still holds layout 6's spell") end
  end
  if not (STUB.actions[38] and STUB.actions[38][2] == 6948) then fail("layout 7: the player's item on Action Bar 5 was cleared") end
  if STUB.settings.PROXY_SHOW_ACTIONBAR_5 ~= true or STUB.settings.PROXY_SHOW_ACTIONBAR_6 ~= true then
    fail("layout 7: Action Bar 5 should stay shown and Action Bar 6 be shown")
  end
  local hearth
  for _, sp in ipairs(L.spare) do
    if STUB.actions[sp.slot] and STUB.actions[sp.slot][2] == 6948 then hearth = sp.slot end
  end
  if not hearth then fail("layout 7: the Hearthstone from button 5 did not move to a spare button") end
  for key, want in pairs({ ["CTRL-1"] = "MULTIACTIONBAR2BUTTON1", ["CTRL-R"] = "MULTIACTIONBAR2BUTTON8",
    ["SHIFT-F"] = "MULTIACTIONBAR1BUTTON9", ["BUTTON4"] = "MULTIACTIONBAR5BUTTON1",
    ["CTRL-BUTTON5"] = "MULTIACTIONBAR5BUTTON6", ["5"] = "ACTIONBUTTON5" }) do
    if STUB.bindings[key] ~= want then fail("layout 7: " .. key .. " not bound to " .. want) end
  end
  if L.bySpell.fire_nova.key ~= "SHIFT-F" or L.bySpell.riptide.key ~= "BUTTON4" or L.bySpell.ghost_wolf.key ~= "CTRL-1" then
    fail("layout 7: Fire Nova Shift+F, Riptide Mouse4 and Ghost Wolf Ctrl+1 expected")
  end
  try("layout 7 undo", ns.Layout.Undo)
  local uA, uB = snapshot()
  ok, why = same(v6A, uA)
  if not ok then fail("layout 7 undo: action slots differ: " .. why) end
  ok, why = same(v6B, uB)
  if not ok then fail("layout 7 undo: key bindings differ: " .. why) end
  ok, why = same(v6S, settingsSnap())
  if not ok then fail("layout 7 undo: bar settings differ: " .. why) end
  STUB.bindings = savedBinds
  STUB.level, STUB.known, STUB.actions, STUB.bags = saved.level, saved.known, saved.actions, saved.bags
  try("layout 7 items", ns.Items.Refresh)

  -- Update from layout 7 (0.7.0-0.8.0) to 8 (0.8.1, Erika's request): Walk on Air on the middle mouse button (Action
  -- Bar 6 button 9), Skysight clicked on button 10. One notice, nothing moves by itself; a full apply places both and
  -- binds BUTTON3 (it was the player's own key), and 元に戻す puts back the buttons and the old BUTTON3 binding.
  STUB.level = 60
  for id in pairs(STUB.names) do STUB.known[id] = true end
  STUB.actions = {}
  STUB.bindings = {}
  try("layout 7 bars", ns.Layout.Execute, ns.Layout.BuildPlan())
  -- Layout 7 left Action Bar 6 buttons 9 and 10 empty; the player put a Hearthstone on button 9 and had a key on the
  -- middle mouse button.
  STUB.actions[153], STUB.actions[154] = { "item", 6948 }, nil
  STUB.bindings["BUTTON3"] = "TOGGLEAUTORUN"
  local v7A, v7B = snapshot()
  ns.char.layoutVersion = 7
  relogin()
  confirm = _G.ForeverSenseiConfirm
  if not confirm or not confirm:IsShown() or confirm.text:GetText() ~= ns.T("ui.layout.changed") then
    fail("layout 8: no notice for a player with layout 7")
  else
    confirm:Hide()
  end
  if ns.char.layoutVersion ~= 8 then fail("layout 8: version not saved after the notice") end
  nA, nB = snapshot()
  if not same(v7A, nA) or not same(v7B, nB) then fail("layout 8: the notice moved something by itself") end
  local v8Plan = ns.Layout.BuildPlan()
  local v8Text = table.concat(ns.Layout.Describe(v8Plan), "\n")
  if not v8Text:find(ns.T("ui.preview.warn.middle", { key = ns.KeyLabel("BUTTON3") }), 1, true) then
    fail("layout 8: the preview does not explain the middle mouse button")
  end
  try("layout 8 apply", ns.Layout.Execute, v8Plan)
  checkLayout(ns.settings.targeting) -- (layout 8)
  if STUB.bindings["BUTTON3"] ~= "MULTIACTIONBAR5BUTTON9" then fail("layout 8: BUTTON3 not bound to Action Bar 6 button 9") end
  local moved
  for _, sp in ipairs(L.spare) do
    if STUB.actions[sp.slot] and STUB.actions[sp.slot][2] == 6948 then moved = true end
  end
  if not moved then fail("layout 8: the Hearthstone from Action Bar 6 button 9 did not move to a spare button") end
  try("layout 8 undo", ns.Layout.Undo)
  uA, uB = snapshot()
  ok, why = same(v7A, uA)
  if not ok then fail("layout 8 undo: action slots differ: " .. why) end
  ok, why = same(v7B, uB)
  if not ok then fail("layout 8 undo: key bindings differ: " .. why) end
  STUB.bindings = savedBinds
  STUB.level, STUB.known, STUB.actions, STUB.bags = saved.level, saved.known, saved.actions, saved.bags
  try("layout 8 items", ns.Items.Refresh)

  -- Translation reports: save two, send, format.
  ns.db.reports = {}
  try("report save 1", ns.Feedback.Save, "spell.chain_heal.when", "unnatural", "2人以上が傷ついている時に使おう。", nil)
  try("report save 2", ns.Feedback.Save, "guide.healing.p3", "unclear", nil, "line one\nline two | x")
  -- The report dialog shows each text as written, placeholders included: not counted as shown text.
  local shownBefore = #STUB.shown
  for _, id in ipairs(ns.TextIds()) do
    try("report open " .. id, ns.Feedback.Open, id)
    fits("report " .. id, "ForeverSenseiReport")
  end
  for i = #STUB.shown, shownBefore + 1, -1 do STUB.shown[i] = nil end
  try("report open", ns.Feedback.Open, "spell.healing_wave.what")
  try("report send", ns.Feedback.Send)
  fits("send", "ForeverSenseiCopy")
  local report = ns.Feedback.Format(ns.Feedback.Pending(), ns.VERSION)

  try("verify", ns.Verify.Run)
  local vtext = ns.Verify.Run()
  if vtext:find("!! ", 1, true) and not vtext:find("problems: 0", 1, true) then
    for line in vtext:gmatch("[^\n]+") do
      if line:find("!! ", 1, true) and (line:find("rank", 1, true) or line:find("macro", 1, true)) then fail("verify: " .. line) end
    end
  end

  STUB.runLongTimers()

  -- Every clickable and hoverable thing, once (not in windows thrown away on a language change: hidden for good).
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

  -- Slash commands.
  for _, cmd in ipairs({ "", "guide", "skills", "layout", "order", "review", "settings", "card Chain Heal", "trainer",
                         "talents", "report", "verify", "help", "debug", "debug", "apply", "undo" }) do
    try("/sensei " .. cmd, SlashCmdList.FOREVERSENSEI, cmd)
  end
  ns.settings.language = lang

  for _, e in ipairs(ns.errors) do fail("ns.errors: " .. e) end
  ns.errors = {}
  return { errors = errors, notes = notes, report = report }
end
