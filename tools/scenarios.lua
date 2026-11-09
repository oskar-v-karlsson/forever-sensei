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
  local data = ns.ClassData.SHAMAN
  local L = data.layout

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
  for _, tab in ipairs({ "role", "healing", "damage", "totems", "manners", "skills", "layout", "talents", "review", "settings" }) do
    try("guide " .. tab, ns.Guide.Open, tab)
  end
  for lv = 10, 60, 5 do
    STUB.level, STUB.unspent = lv, 1
    try("talent hint " .. lv, ns.Talents.ShowHint, true)
    fits("talent hint " .. lv, "ForeverSenseiTalentHint")
  end
  STUB.unspent = 0

  -- Readable talent tree: the player followed the path up to the point before this level → next is that level's step.
  local T = data.talents
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
  STUB.actions = { [1] = { "spell", 403 }, [2] = { "item", 6948 }, [7] = { "spell", 331 }, [13] = { "spell", 324 } }
  STUB.bindings = { ["Q"] = "STRAFELEFT", ["E"] = "STRAFERIGHT", ["1"] = "ACTIONBUTTON1", ["SHIFT-1"] = "ACTIONPAGE1" }
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
      local entry = ns.Spells.Get(s.spell)
      local a = STUB.actions[s.slot]
      if not a then
        fail(mode .. ": slot " .. s.slot .. " empty, expected " .. s.spell)
      elseif mode == "mouseover" and L.macros[s.spell] then
        local m = STUB.macros[a[2]]
        if a[1] ~= "macro" or not m or m.name ~= L.macros[s.spell] then
          fail(mode .. ": slot " .. s.slot .. " should hold macro " .. L.macros[s.spell])
        elseif not m.body:find(entry.name, 1, true) or not m.body:find("@mouseover", 1, true) then
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
  end

  ns.settings.targeting = "mouseover"
  if try("preview", ns.Layout.Preview) then
    local p = _G.ForeverSenseiPreview
    if not p or not p:IsShown() then
      fail("preview window not shown")
    else
      fits("preview", p)
      try("apply", function() p.apply:Click() end)
      checkLayout("mouseover")
    end
  end
  local planAfter = ns.Layout.BuildPlan()
  if not ns.Layout.IsEmptyPlan(planAfter) then fail("plan not empty after apply") end
  if STUB.cursor then fail("cursor not empty after apply") end

  try("targeting click", ns.Layout.SetTargeting, "click")
  checkLayout("click")
  try("targeting mouseover", ns.Layout.SetTargeting, "mouseover")
  checkLayout("mouseover")

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

  -- Place one spell (card button), with something else in its slot → asks first.
  STUB.actions = { [3] = { "spell", 403 } }
  local ch = ns.Spells.Get("chain_heal")
  try("place one", ns.Layout.PlaceOne, ch)
  local confirm = _G.ForeverSenseiConfirm
  fits("confirm", confirm)
  if confirm and confirm:IsShown() and confirm.yes then try("place confirm", function() confirm.yes:Click() end) end
  local a = STUB.actions[3]
  if not a or not ((a[1] == "macro" and STUB.macros[a[2]].name == "FS_CH") or (a[1] == "spell" and STUB.names[a[2]] == "Chain Heal")) then
    fail("place one: Chain Heal not in slot 3")
  end
  if STUB.bindings["3"] ~= "ACTIONBUTTON3" then fail("place one: key 3 not bound") end

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
