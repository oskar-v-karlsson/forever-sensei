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
  -- Buttons 5 and Shift+5 (slots 5, 65) and the keys 5, Shift+5, Ctrl+5 are the player's own; so is layout 3's Ctrl+5
  -- button on the retired Action Bar 6 (slot 149): a full apply never touches them.
  STUB.actions = { [1] = { "spell", 403 }, [2] = { "item", 6948 }, [7] = { "spell", 331 }, [13] = { "spell", 324 },
    [5] = { "item", 6948 }, [65] = { "spell", 324 }, [149] = { "spell", 403 } }
  STUB.bindings = { ["Q"] = "STRAFELEFT", ["E"] = "STRAFERIGHT", ["1"] = "ACTIONBUTTON1", ["SHIFT-1"] = "ACTIONPAGE1",
    ["CTRL-1"] = "SHAPESHIFTBUTTON1", ["5"] = "ACTIONBUTTON5", ["SHIFT-5"] = "MULTIACTIONBAR1BUTTON5",
    ["CTRL-5"] = "SHAPESHIFTBUTTON5" }
  local function ownUntouched(what)
    local a5, a65, a149 = STUB.actions[5], STUB.actions[65], STUB.actions[149]
    if not (a5 and a5[2] == 6948 and a65 and a65[2] == 324 and a149 and a149[2] == 403)
      or STUB.bindings["5"] ~= "ACTIONBUTTON5" or STUB.bindings["SHIFT-5"] ~= "MULTIACTIONBAR1BUTTON5"
      or STUB.bindings["CTRL-5"] ~= "SHAPESHIFTBUTTON5" then
      fail(what .. ": the player's own buttons or keys 5, Shift+5, Ctrl+5 were changed")
    end
  end
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
      if STUB.settings[bar.setting] then fail(mode .. ": retired " .. bar.id .. " is shown") end
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
      for _, want in ipairs({ ns.T("ui.preview.warn.stance", { key = "Ctrl+1, Ctrl+2, Ctrl+3, Ctrl+4" }),
        ns.T("ui.preview.warn.fps", { key = "Ctrl+R" }), ns.T("ui.preview.warn.mouse"), ns.T("ui.preview.warn.own") }) do
        if not text:find(want, 1, true) then fail("preview: missing the note " .. want) end
      end
      try("apply", function() p.apply:Click() end)
      checkLayout("mouseover")
      ownUntouched("apply")
      -- Every key of a keyed bar is bound, also spare ones (empty buttons): Ctrl mirrors Shift on Action Bar 5, and the
      -- mouse buttons fire Action Bar 3 7-12.
      for _, sp in ipairs(L.spare) do
        if sp.key and STUB.bindings[sp.key] ~= sp.binding then fail("apply: spare key " .. sp.key .. " not bound to " .. sp.binding) end
      end
      for key, want in pairs({ ["CTRL-R"] = "MULTIACTIONBAR4BUTTON8", ["CTRL-2"] = "MULTIACTIONBAR4BUTTON2",
        ["CTRL-C"] = "MULTIACTIONBAR4BUTTON12", ["BUTTON4"] = "MULTIACTIONBAR2BUTTON7", ["CTRL-BUTTON5"] = "MULTIACTIONBAR2BUTTON12" }) do
        if STUB.bindings[key] ~= want then fail("apply: " .. key .. " should be bound to " .. want) end
      end
      if not L.bySpell.lightning_shield or STUB.actions[L.bySpell.lightning_shield.slot] == nil then
        fail("apply: Lightning Shield not on its own button once Water Shield is known")
      end
    end
  end
  local planAfter = ns.Layout.BuildPlan()
  if not ns.Layout.IsEmptyPlan(planAfter) then fail("plan not empty after apply") end
  if STUB.cursor then fail("cursor not empty after apply") end

  try("targeting click", ns.Layout.SetTargeting, "click")
  checkLayout("click")
  try("targeting mouseover", ns.Layout.SetTargeting, "mouseover")
  checkLayout("mouseover")
  ownUntouched("targeting")

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
  -- there. A full apply clears those buttons, hides both bars and unbinds stale keys, but keeps the player's own
  -- Ctrl+5 key and layout 3's Ctrl+5 button (slot 149) and anything that isn't the plan's. Undo restores it all.
  local function idOf(key) return ns.Spells.CurrentID(ns.Spells.Get(key)) end
  STUB.actions = { [145] = { "spell", idOf("totemic_recall") }, [157] = { "spell", idOf("riptide") },
    [149] = { "spell", 403 }, [150] = { "item", 6948 } }
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
  if #migPlan.hide ~= 2 or not migText:find(ns.T("ui.preview.hide"), 1, true) then
    fail("migration: the preview does not list Action Bars 6 and 7 as hidden")
  end
  try("migration apply", ns.Layout.Execute, migPlan)
  checkLayout("mouseover") -- (migration)
  if STUB.actions[145] or STUB.actions[157] then fail("migration: layout 3 spells left on Action Bars 6/7") end
  if not (STUB.actions[149] and STUB.actions[149][2] == 403 and STUB.actions[150]) then
    fail("migration: the player's Ctrl+5 button or a non-plan button on Action Bar 6 was cleared")
  end
  if STUB.bindings["CTRL-2"] ~= "MULTIACTIONBAR4BUTTON2" or STUB.bindings["CTRL-5"] ~= "MULTIACTIONBAR5BUTTON5" then
    fail("migration: stale Action Bar 6/7 keys not moved to Action Bar 5, or the own Ctrl+5 key changed")
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
  -- spells not learned yet, and layout 3's buttons on Action Bars 6/7), keeps spare and own buttons and everything
  -- else, and Undo puts everything back.
  local spare = L.spare[1].slot
  local unlearned = L.bySpell.chain_heal.slot
  for _, sl in ipairs(L.slots) do
    if sl.slot == spare or sl.slot == 146 then fail("clean: test slot " .. sl.slot .. " is planned") end
  end
  local knownBefore = STUB.known
  STUB.known = {}
  for id in pairs(knownBefore) do STUB.known[id] = true end
  for _, id in ipairs(ns.Spells.Ranks(ns.Spells.Get("chain_heal"))) do STUB.known[id] = nil end
  if ns.Spells.IsKnown(ns.Spells.Get("chain_heal")) then
    fail("clean: Chain Heal should be unlearned here, to test a slot kept free for it")
  end
  STUB.actions = { [1] = { "spell", 403 }, [5] = { "item", 6948 }, [65] = { "spell", 324 }, [30] = { "item", 6948 },
    [45] = { "spell", 331 }, [149] = { "spell", 403 }, [160] = { "spell", 324 }, [100] = { "spell", 403 },
    [spare] = { "spell", 324 }, [146] = { "spell", 403 }, [unlearned] = { "spell", 403 } }
  local clA = snapshot()
  try("clean", ns.Layout.Clean)
  local cf = _G.ForeverSenseiConfirm
  if not cf or not cf:IsShown() or not (cf.text:GetText() or ""):find(ns.T("ui.clean.confirm", { n = 5 }), 1, true) then
    fail("clean: no confirmation for the 5 planned buttons shown")
  else
    fits("clean confirm", cf)
    try("clean confirm", function() cf.yes:Click() end)
  end
  local keepSlots = { [5] = true, [65] = true, [100] = true, [149] = true, [146] = true, [spare] = true }
  for slot in pairs(clA) do
    local keep = keepSlots[slot] or false
    if (STUB.actions[slot] ~= nil) ~= keep then fail("clean: slot " .. slot .. (keep and " was emptied" or " still set")) end
  end
  try("clean undo", ns.Layout.Undo)
  ok, why = same(clA, (snapshot()))
  if not ok then fail("clean undo: action slots differ: " .. why) end
  STUB.actions = { [5] = { "item", 6948 }, [65] = { "spell", 324 } }
  STUB.known = knownBefore
  if cf then cf:Hide() end
  try("clean nothing", ns.Layout.Clean)
  if cf and cf:IsShown() then fail("clean: asked although only the own buttons hold something") end
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
  STUB.settings.PROXY_SHOW_ACTIONBAR_2 = true
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
  -- (Call of the Elements, layout 2) or now lives only in the spellbook (Sentry Totem, layout 4); the player's own
  -- button 5 (Earth Shock in layout 2) stays. Ctrl+5's button held Mana Tide Totem in layout 4: cleared while it
  -- still holds exactly that, left alone once the player put something else there.
  STUB.level = 60
  for id in pairs(STUB.names) do STUB.known[id] = true end
  local cote, es = ns.Spells.Get("call_of_the_elements"), ns.Spells.Get("earth_shock")
  local st, mt = ns.Spells.Get("sentry_totem"), ns.Spells.Get("mana_tide_totem")
  STUB.actions = { [72] = { "spell", cote.id }, [36] = { "spell", st.id }, [5] = { "spell", es.id }, [41] = { "spell", mt.id } }
  local oldPlan = ns.Layout.BuildPlan()
  local cleared, touched = {}, false
  for _, c in ipairs(oldPlan.clears) do
    cleared[c.where.slot] = true
    if c.where.slot == 5 then touched = true end
  end
  for _, pl in ipairs(oldPlan.place) do if pl.where.slot == 5 or pl.where.slot == 41 then touched = true end end
  for _, m in ipairs(oldPlan.moves) do if m.from == 5 or m.from == 41 then touched = true end end
  if not cleared[72] then fail("old leftover: Call of the Elements on old slot 72 not cleared") end
  if not cleared[36] then fail("old leftover: Sentry Totem (spellbook only now) on old slot 36 not cleared") end
  if not cleared[41] then fail("old leftover: layout 4's Mana Tide Totem on Ctrl+5's button not cleared") end
  if touched then fail("old leftover: the player's own button 5 was planned to change, or Ctrl+5 other than cleared") end
  local mtSlot = L.bySpell.mana_tide_totem.slot
  try("old leftover apply", ns.Layout.Execute, oldPlan)
  if STUB.actions[41] then fail("old leftover: Ctrl+5's button still holds Mana Tide Totem after apply") end
  if not STUB.actions[mtSlot] then fail("old leftover: Mana Tide Totem not on Ctrl+Z after apply") end
  try("old leftover undo", ns.Layout.Undo)
  if not (STUB.actions[41] and STUB.actions[41][2] == mt.id) then fail("old leftover undo: Mana Tide Totem not back on Ctrl+5's button") end
  -- Something else of her own on Ctrl+5 (another spell, or an item) stays.
  for _, mine in ipairs({ { "spell", es.id }, { "item", 6948 } }) do
    STUB.actions = { [41] = mine }
    for _, c in ipairs(ns.Layout.BuildPlan().clears) do
      if c.slot == 41 then fail("old leftover: the player's own " .. mine[1] .. " on Ctrl+5 was planned to be cleared") end
    end
  end
  STUB.actions = { [72] = { "spell", cote.id }, [41] = { "spell", mt.id } }
  for _, c in ipairs(ns.Layout.BuildPlan("mana_tide_totem").clears) do
    if c.slot == 41 then fail("old leftover: placing one spell cleared Ctrl+5's button") end
  end
  local onePlan = ns.Layout.BuildPlan("call_of_the_elements")
  for _, c in ipairs(onePlan.clears) do
    if c.where.slot == 72 then fail("old leftover: placing one spell cleared an old button") end
  end
  STUB.level, STUB.known, STUB.actions, STUB.bags = saved.level, saved.known, saved.actions, saved.bags
  try("old leftover items", ns.Items.Refresh) -- the apply above wrote the item macros for the level-60 bags

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

  -- Every clickable and hoverable thing, once.
  for _, f in ipairs(STUB.frames) do
    for _, script in ipairs({ "OnEnter", "OnLeave", "OnClick" }) do
      local fn = f.__scripts[script]
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
