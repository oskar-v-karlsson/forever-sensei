-- Modules/Layout.lua: putting skills on the planned slots and keys.
-- All bar, binding and macro changes run out of combat (ns.OutOfCombat) and push an undo record.
-- Legacy globals (PlaceAction, PickupAction, SetBinding, ...) are resolved at runtime; /sensei verify lists missing ones.
local _, ns = ...
local Layout = {}
ns.Layout = Layout

local function L() return ns.ClassData.SHAMAN.layout end
local Spells = ns.Spells

-- Call the first API from the list that exists. → ok, results...
local function call(paths, ...)
  for _, p in ipairs(paths) do
    if ns.API(p) then return ns.Call(p, ...) end
  end
  return false, "missing " .. paths[1]
end

local API = {
  getAction = { "GetActionInfo", "C_ActionBar.GetActionInfo" },
  actionText = { "GetActionText", "C_ActionBar.GetActionText" },
  pickupAction = { "PickupAction", "C_ActionBar.PickupAction" },
  placeAction = { "PlaceAction", "C_ActionBar.PutActionInSlot" },
  pickupSpell = { "C_Spell.PickupSpell", "PickupSpell" },
  pickupMacro = { "PickupMacro" },
  pickupItem = { "C_Item.PickupItem", "PickupItem" },
  clearCursor = { "ClearCursor" },
  bindingAction = { "GetBindingAction" },
  setBinding = { "SetBinding" },
  saveBindings = { "SaveBindings" },
  bindingSet = { "GetCurrentBindingSet" },
  macroIndex = { "GetMacroIndexByName" },
  macroInfo = { "GetMacroInfo" },
  createMacro = { "CreateMacro" },
  editMacro = { "EditMacro" },
  itemName = { "C_Item.GetItemNameByID", "GetItemInfo" },
  getSetting = { "Settings.GetValue" },
  setSetting = { "Settings.SetValue" },
}
Layout.API = API

local macroKeys -- macro name → spell key
local function macroKeyOf(name)
  if not macroKeys then
    macroKeys = {}
    for key, m in pairs(L().macros) do macroKeys[m] = key end
  end
  return name and macroKeys[name]
end

-- What sits in an action slot now. → { type, id, name, macroName, planKey } or nil when empty
function Layout.Current(slot)
  local ok, t, id, sub = call(API.getAction, slot)
  if not ok or not t then return nil end
  local cur = { type = t, id = id, subType = sub }
  if t == "spell" then
    cur.name = Spells.Name(id)
    local e = Spells.ByName(cur.name)
    cur.planKey = e and e.key
  elseif t == "macro" then
    local ok2, text = call(API.actionText, slot)
    local name = ok2 and text or nil
    if not name or name == "" then
      local ok3, n = call(API.macroInfo, id)
      name = ok3 and n or nil
    end
    cur.macroName = name
    cur.name = name
    cur.planKey = macroKeyOf(name)
  elseif t == "item" then
    local ok2, n = call(API.itemName, id)
    cur.name = ok2 and n or nil
  end
  return cur
end

function Layout.Label(cur)
  if not cur then return ns.T("ui.preview.empty") end
  if cur.type == "macro" then return ns.T("ui.preview.macro", { name = cur.macroName or "?" }) end
  return cur.name or (tostring(cur.type) .. " " .. tostring(cur.id))
end

function Layout.UsesMacro(entry)
  return ns.settings.targeting == "mouseover" and L().macros[entry.key] ~= nil
end

-- The action this spell should be in its slot. → { kind = "spell"|"macro", entry, id, macro } or nil when not known
function Layout.Desired(entry)
  if not entry or not Spells.IsKnown(entry) then return nil end
  if Layout.UsesMacro(entry) then
    return { kind = "macro", entry = entry, macro = L().macros[entry.key] }
  end
  return { kind = "spell", entry = entry, id = Spells.CurrentID(entry) }
end

function Layout.Matches(cur, d)
  if not cur or not d then return false end
  if d.kind == "macro" then return cur.type == "macro" and cur.macroName == d.macro end
  return cur.type == "spell" and cur.planKey == d.entry.key and cur.id == d.id
end

function Layout.DesiredLabel(d)
  if d.kind == "macro" then return ns.T("ui.preview.macro", { name = d.macro }) .. " (" .. d.entry.name .. ")" end
  return d.entry.name
end

function Layout.MacroBody(entry)
  return (L().macroBody:gsub("{spell}", entry.name))
end

-- Create or update the character macro for a spell. → macro index or nil
function Layout.EnsureMacro(entry)
  local name = L().macros[entry.key]
  if not name then return nil end
  local body = Layout.MacroBody(entry)
  local icon = "INV_MISC_QUESTIONMARK"
  local ok, idx = call(API.macroIndex, name)
  if ok and idx and idx > 0 then
    local ok2, newIdx = call(API.editMacro, idx, name, icon, body)
    if ok2 then return newIdx or idx end
    return idx
  end
  local ok3, created = call(API.createMacro, name, icon, body, true)
  if ok3 and created and created > 0 then return created end
  ns.Debug("CreateMacro " .. name .. ": " .. tostring(created))
  return nil
end

local function put(slot)
  call(API.placeAction, slot)
  call(API.clearCursor)
end

-- Place a desired action. → true, usedFallback
local function placeDesired(slot, d)
  if d.kind == "macro" then
    local idx = Layout.EnsureMacro(d.entry)
    if idx then
      call(API.pickupMacro, idx)
      put(slot)
      return true, false
    end
    call(API.pickupSpell, Spells.CurrentID(d.entry))
    put(slot)
    return true, true
  end
  call(API.pickupSpell, d.id)
  put(slot)
  return true, false
end

local function clearSlot(slot)
  call(API.pickupAction, slot)
  call(API.clearCursor)
end

local function info(cur)
  if not cur then return false end
  return { type = cur.type, id = cur.id, macroName = cur.macroName, label = Layout.Label(cur) }
end

local function restore(slot, saved)
  if saved == false then
    clearSlot(slot)
    return true
  end
  if saved.type == "spell" then
    call(API.pickupSpell, saved.id)
  elseif saved.type == "macro" then
    if not saved.macroName then return false end
    local ok, idx = call(API.macroIndex, saved.macroName)
    if not ok or type(idx) ~= "number" or idx == 0 then return false end
    call(API.pickupMacro, idx)
  elseif saved.type == "item" then
    call(API.pickupItem, saved.id)
  else
    return false
  end
  put(slot)
  return true
end

local function barById(id)
  for _, b in ipairs(L().bars) do
    if b.id == id then return b end
  end
end

local function bindingName(action)
  if not action or action == "" then return ns.T("ui.preview.none") end
  return _G["BINDING_NAME_" .. action] or action
end
Layout.BindingName = bindingName

local function slotWhere(s)
  return ns.T("ui.where.short", { bar = ns.T("ui.bar." .. s.bar), button = s.button })
end
Layout.SlotWhere = slotWhere

-- Work out every change. onlyKey limits it to one spell (the card's 配置する button).
-- → plan { place, moves, clears, lost, binds, bars }
function Layout.BuildPlan(onlyKey)
  local layout = L()
  local plan = { place = {}, moves = {}, clears = {}, lost = {}, binds = {}, bars = {} }
  local targets = {}
  for _, s in ipairs(layout.slots) do
    if not onlyKey or s.spell == onlyKey then
      local d = Layout.Desired(Spells.Get(s.spell))
      if d then targets[s.slot] = d end
    end
  end

  -- Empty slots reserved for spells she does not know yet take displaced actions, bar 4 then bar 3, right to left.
  local free = {}
  for _, barId in ipairs({ "bar4", "bar3" }) do
    for i = #layout.slots, 1, -1 do
      local s = layout.slots[i]
      if s.bar == barId and not targets[s.slot] and not Spells.IsKnown(Spells.Get(s.spell))
        and Layout.Current(s.slot) == nil then
        table.insert(free, s)
      end
    end
  end

  local barsNeeded = {}
  for _, s in ipairs(layout.slots) do
    local d = targets[s.slot]
    if d then
      local cur = Layout.Current(s.slot)
      if not Layout.Matches(cur, d) then
        if cur and not cur.planKey then
          local dest = table.remove(free, 1)
          if dest then
            table.insert(plan.moves, { from = s.slot, to = dest.slot, fromSlot = s, toSlot = dest, label = Layout.Label(cur) })
          else
            table.insert(plan.lost, { slot = s.slot, where = s, label = Layout.Label(cur) })
          end
        end
        table.insert(plan.place, { slot = s.slot, where = s, desired = d, old = cur })
      end
      if s.key then
        local ok, action = call(API.bindingAction, s.key)
        action = ok and action ~= "" and action or nil
        if action ~= s.binding then
          table.insert(plan.binds, { key = s.key, binding = s.binding, old = action, name = d.entry.name })
        end
      end
      barsNeeded[s.bar] = true
    end
  end

  -- Copies of planned spells in slots reserved for spells she does not know yet would become duplicates.
  for _, s in ipairs(layout.slots) do
    if not targets[s.slot] and not Spells.IsKnown(Spells.Get(s.spell)) then
      local cur = Layout.Current(s.slot)
      if cur and cur.planKey and (not onlyKey or cur.planKey == onlyKey) and Layout.Desired(Spells.Get(cur.planKey)) then
        table.insert(plan.clears, { slot = s.slot, where = s, label = Layout.Label(cur) })
      end
    end
  end

  for barId in pairs(barsNeeded) do
    local bar = barById(barId)
    if bar.setting then
      local ok, shown = call(API.getSetting, bar.setting)
      if not (ok and shown == true) then table.insert(plan.bars, bar) end
    end
  end
  table.sort(plan.bars, function(a, b) return a.id < b.id end)
  return plan
end

function Layout.IsEmptyPlan(plan)
  return #plan.place == 0 and #plan.moves == 0 and #plan.clears == 0 and #plan.binds == 0 and #plan.bars == 0
end

local function pushBackup(b)
  ns.char.backups = ns.char.backups or {}
  table.insert(ns.char.backups, b)
  while #ns.char.backups > 5 do table.remove(ns.char.backups, 1) end
end

-- Apply a plan (call only out of combat). → backup record
function Layout.Execute(plan)
  local backup = { time = time and time() or 0, moves = {}, slots = {}, binds = {}, bars = {} }
  local movedFrom = {}
  for _, m in ipairs(plan.moves) do
    call(API.pickupAction, m.from)
    put(m.to)
    table.insert(backup.moves, { from = m.from, to = m.to })
    movedFrom[m.from] = true
  end
  for _, c in ipairs(plan.clears) do
    backup.slots[c.slot] = info(Layout.Current(c.slot))
    clearSlot(c.slot)
  end
  local fallback = false
  for _, p in ipairs(plan.place) do
    if not movedFrom[p.slot] and backup.slots[p.slot] == nil then backup.slots[p.slot] = info(p.old) end
    local _, fb = placeDesired(p.slot, p.desired)
    fallback = fallback or fb
  end
  if #plan.binds > 0 then
    for _, b in ipairs(plan.binds) do
      backup.binds[b.key] = b.old or false
      call(API.setBinding, b.key, b.binding)
    end
    local ok, set = call(API.bindingSet)
    call(API.saveBindings, ok and set or 2)
  end
  for _, bar in ipairs(plan.bars) do
    local ok, old = call(API.getSetting, bar.setting)
    local ok2 = call(API.setSetting, bar.setting, true)
    if ok2 then
      backup.bars[bar.setting] = ok and old or false
    else
      ns.UI.Toast(ns.T("ui.bars.hidden", { bar = ns.T("ui.bar." .. bar.id) }), 12)
    end
  end
  pushBackup(backup)
  if fallback then ns.UI.Toast(ns.T("ui.layout.macrofail"), 12) end
  return backup
end

function Layout.CanUndo()
  return ns.char and ns.char.backups and #ns.char.backups > 0
end

function Layout.Undo()
  if not Layout.CanUndo() then
    ns.UI.Toast(ns.T("ui.layout.noundo"))
    return
  end
  ns.OutOfCombat("layout", function()
    local b = table.remove(ns.char.backups)
    local skip = {}
    for i = #b.moves, 1, -1 do
      local m = b.moves[i]
      call(API.pickupAction, m.to)
      put(m.from)
      skip[m.from] = true
    end
    local failed = {}
    for slot, saved in pairs(b.slots) do
      if not skip[slot] and not restore(slot, saved) then table.insert(failed, saved.label or "?") end
    end
    local anyBind = false
    for key, old in pairs(b.binds) do
      anyBind = true
      if old then call(API.setBinding, key, old) else call(API.setBinding, key) end
    end
    if anyBind then
      local ok, set = call(API.bindingSet)
      call(API.saveBindings, ok and set or 2)
    end
    for setting, old in pairs(b.bars) do call(API.setSetting, setting, old) end
    if #failed > 0 then
      ns.UI.Toast(ns.T("ui.layout.undone") .. "\n" .. ns.T("ui.layout.unrestorable", { list = table.concat(failed, ", ") }), 15)
    else
      ns.UI.Toast(ns.T("ui.layout.undone"))
    end
    if ns.Guide and ns.Guide.Refresh then ns.Guide.Refresh() end
  end)
end

-- Text lines describing a plan, for the preview window.
function Layout.Describe(plan)
  local lines = {}
  local function head(id) table.insert(lines, "|cffffd100" .. ns.T(id) .. "|r") end
  if #plan.place > 0 then
    head("ui.preview.place")
    for _, p in ipairs(plan.place) do
      table.insert(lines, ns.T("ui.preview.line", { where = slotWhere(p.where), old = Layout.Label(p.old), new = Layout.DesiredLabel(p.desired) }))
    end
  end
  if #plan.moves > 0 then
    head("ui.preview.move")
    for _, m in ipairs(plan.moves) do
      table.insert(lines, ns.T("ui.preview.line", { where = m.label, old = slotWhere(m.fromSlot), new = slotWhere(m.toSlot) }))
    end
  end
  if #plan.clears > 0 then
    head("ui.preview.clear")
    for _, c in ipairs(plan.clears) do
      table.insert(lines, ns.T("ui.preview.line", { where = slotWhere(c.where), old = c.label, new = ns.T("ui.preview.empty") }))
    end
  end
  if #plan.lost > 0 then
    head("ui.preview.lost")
    for _, l in ipairs(plan.lost) do
      table.insert(lines, slotWhere(l.where) .. ": " .. l.label)
    end
  end
  if #plan.binds > 0 then
    head("ui.preview.keys")
    for _, b in ipairs(plan.binds) do
      table.insert(lines, ns.T("ui.preview.keyline", { key = L().KeyLabel(b.key), old = bindingName(b.old), new = b.name }))
    end
  end
  if #plan.bars > 0 then
    head("ui.preview.bars")
    for _, bar in ipairs(plan.bars) do table.insert(lines, ns.T("ui.bar." .. bar.id)) end
  end
  return lines
end

-- Preview window for the full layout.
local preview
function Layout.Preview()
  if ns.InCombat() then
    ns.UI.Toast(ns.T("ui.combat.later"))
    return
  end
  local plan = Layout.BuildPlan()
  if Layout.IsEmptyPlan(plan) then
    ns.UI.Toast(ns.T("ui.preview.nothing"))
    return
  end
  if not preview then
    local UI = ns.UI
    preview = UI.Window("ForeverSenseiPreview", 600, 520, ns.T("ui.preview.title"))
    preview.intro = UI.Text(preview, 12)
    preview.intro:SetPoint("TOPLEFT", 16, -40)
    preview.intro:SetWidth(568)
    preview.intro:SetText(ns.T("ui.preview.intro"))
    preview.report = UI.ReportButton(preview, "ui.preview.intro")
    preview.report:SetPoint("TOPRIGHT", -36, -10)
    preview.sf, preview.content = UI.Scroll(preview, 548, 340)
    preview.sf:SetPoint("TOPLEFT", 16, -110)
    preview.body = UI.Text(preview.content, 12)
    preview.body:SetPoint("TOPLEFT", 0, 0)
    preview.body:SetWidth(540)
    preview.apply = UI.Button(preview, ns.T("ui.btn.apply"), 160, 24)
    preview.apply:SetPoint("BOTTOMRIGHT", preview, "BOTTOM", -6, 14)
    preview.cancel = UI.Button(preview, ns.T("ui.btn.cancel"), 160, 24, function() preview:Hide() end)
    preview.cancel:SetPoint("BOTTOMLEFT", preview, "BOTTOM", 6, 14)
  end
  preview.body:SetText(table.concat(Layout.Describe(plan), "\n"))
  preview.content:SetHeight(preview.body:GetStringHeight() + 10)
  preview.apply:SetScript("OnClick", function()
    preview:Hide()
    ns.OutOfCombat("layout", function()
      Layout.Execute(Layout.BuildPlan())
      ns.UI.Toast(ns.T("ui.layout.applied"), 12)
      if ns.Guide and ns.Guide.Refresh then ns.Guide.Refresh() end
    end)
  end)
  preview:Show()
end

-- The card's 配置する button: one spell, asks before replacing something else.
function Layout.PlaceOne(entry)
  local s = Spells.LayoutSlot(entry)
  if not s then
    ns.UI.Toast(ns.T("ui.place.nobar", { name = entry.name, where = Spells.WhereText(entry) }))
    return
  end
  if not Spells.IsKnown(entry) then
    ns.UI.Toast(ns.T("ui.place.unknown", { name = entry.name }))
    return
  end
  if ns.InCombat() then
    ns.UI.Toast(ns.T("ui.combat.later"))
    return
  end
  local plan = Layout.BuildPlan(entry.key)
  local where = Spells.WhereText(entry)
  if Layout.IsEmptyPlan(plan) then
    ns.UI.Toast(ns.T("ui.place.already", { name = entry.name, where = where }))
    return
  end
  local function go()
    ns.OutOfCombat("place-" .. entry.key, function()
      Layout.Execute(Layout.BuildPlan(entry.key))
      ns.UI.Toast(ns.T("ui.place.done", { name = entry.name, where = where }), 10)
      if ns.Guide and ns.Guide.Refresh then ns.Guide.Refresh() end
    end)
  end
  local warn = {}
  for _, p in ipairs(plan.place) do
    if p.old and p.old.planKey ~= entry.key then
      table.insert(warn, ns.T("ui.place.occupied", { where = slotWhere(p.where), old = Layout.Label(p.old) }))
    end
  end
  for _, m in ipairs(plan.moves) do
    table.insert(warn, ns.T("ui.place.moveto", { old = m.label, dest = slotWhere(m.toSlot) }))
  end
  for _, l in ipairs(plan.lost) do
    table.insert(warn, ns.T("ui.place.lost", { old = l.label }))
  end
  for _, b in ipairs(plan.binds) do
    if b.old and b.old ~= "" then
      table.insert(warn, ns.T("ui.place.keybusy", { key = L().KeyLabel(b.key), action = bindingName(b.old) }))
    end
  end
  if #warn == 0 then
    go()
  else
    ns.UI.Confirm(ns.T("ui.place.confirm", { name = entry.name }) .. "\n\n" .. table.concat(warn, "\n"), ns.T("ui.btn.place"), go)
  end
end

-- Slots (1-120) that hold an older rank of this spell as a plain spell. Macros cast by name and need no update.
function Layout.OldRankSlots(entry)
  local list = {}
  local id = Spells.CurrentID(entry)
  for slot = 1, 120 do
    local cur = Layout.Current(slot)
    if cur and cur.type == "spell" and cur.planKey == entry.key and cur.id ~= id then table.insert(list, slot) end
  end
  return list
end

function Layout.UpdateRank(entry)
  ns.OutOfCombat("rank-" .. entry.key, function()
    local id = Spells.CurrentID(entry)
    for _, slot in ipairs(Layout.OldRankSlots(entry)) do
      call(API.pickupSpell, id)
      put(slot)
    end
    ns.UI.Toast(ns.T("ui.rank.updated", { name = entry.name }))
  end)
end

-- Switch between mouseover macros and plain spells, swapping what is on the bars in place.
function Layout.SetTargeting(mode)
  ns.settings.targeting = mode
  ns.OutOfCombat("targeting", function()
    local n, fallback = 0, false
    for slot = 1, 120 do
      local cur = Layout.Current(slot)
      if cur and cur.planKey and L().macros[cur.planKey] then
        local d = Layout.Desired(Spells.Get(cur.planKey))
        if d and not Layout.Matches(cur, d) then
          local _, fb = placeDesired(slot, d)
          fallback = fallback or fb
          n = n + 1
        end
      end
    end
    ns.UI.Toast(ns.T(mode == "mouseover" and "ui.targeting.mouseover.done" or "ui.targeting.click.done", { n = n }), 10)
    if fallback then ns.UI.Toast(ns.T("ui.layout.macrofail"), 12) end
    if ns.Guide and ns.Guide.Refresh then ns.Guide.Refresh() end
  end)
end

ns.Command("apply", function() Layout.Preview() end)
ns.Command("undo", function() Layout.Undo() end)
