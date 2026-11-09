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

  -- Every skill card, the trainer list for every level, every guide tab, the talent hint.
  for _, e in ipairs(ns.Spells.List()) do try("card " .. e.key, ns.NewSkill.ShowCard, e) end
  for lv = 1, 60 do try("trainer " .. lv, ns.NewSkill.ShowTrainer, lv) end
  for _, tab in ipairs({ "role", "healing", "damage", "totems", "manners", "skills", "layout", "talents", "review", "settings" }) do
    try("guide " .. tab, ns.Guide.Open, tab)
  end
  for lv = 10, 60, 5 do
    STUB.level, STUB.unspent = lv, 1
    try("talent hint " .. lv, ns.Talents.ShowHint, true)
  end
  STUB.unspent = 0

  -- Readable talent tree: she followed the path up to the point before this level → next is that level's step.
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

  -- Translation reports: save two, send, format.
  ns.db.reports = {}
  try("report save 1", ns.Feedback.Save, "spell.chain_heal.when", "unnatural", "2人以上が傷ついている時に使おう。", nil)
  try("report save 2", ns.Feedback.Save, "guide.healing.p3", "unclear", nil, "line one\nline two | x")
  try("report open", ns.Feedback.Open, "spell.healing_wave.what")
  try("report send", ns.Feedback.Send)
  local report = ns.Feedback.Format(ns.Feedback.Pending(), ns.VERSION)

  try("verify", ns.Verify.Run)

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
