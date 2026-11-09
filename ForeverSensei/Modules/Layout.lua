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
  macroSpell = { "GetMacroSpell" },
  itemName = { "C_Item.GetItemNameByID", "GetItemInfo" },
  getSetting = { "Settings.GetValue" },
  setSetting = { "Settings.SetValue" },
}
Layout.API = API

-- Action slots that can hold her spells: bars 1-6 (1-120; 73-120 are unused stance pages for a Shaman) and the
-- extra bars 6-8 of the 12.x UI (145-180). 121-144 are override/vehicle bars and are never touched.
Layout.SLOTS = {}
for i = 1, 120 do table.insert(Layout.SLOTS, i) end
for i = 145, 180 do table.insert(Layout.SLOTS, i) end

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

-- slot (optional): an older rank she kept there on purpose (undid its upgrade) counts as a match.
function Layout.Matches(cur, d, slot)
  if not cur or not d then return false end
  if d.kind == "macro" then return cur.type == "macro" and cur.macroName == d.macro end
  if cur.type ~= "spell" or cur.planKey ~= d.entry.key then return false end
  if cur.id == d.id then return true end
  local keep = slot and ns.char and ns.char.keepRank
  return keep ~= nil and keep[slot] == cur.id
end

function Layout.DesiredLabel(d)
  if d.kind == "macro" then return ns.T("ui.preview.macro", { name = d.macro }) .. " (" .. d.entry.name .. ")" end
  return d.entry.name
end

-- The spell as the macro names it: the plain name (the client casts the highest rank), or "Name(Rank N)" when
-- CheckMacroRank found that the plain name does not cast the highest rank.
function Layout.MacroSpellName(entry)
  local rank = ns.char and ns.char.macroRank and ns.char.macroRank[entry.key]
  if rank then return entry.name .. "(" .. rank .. ")" end
  return entry.name
end

function Layout.MacroBody(entry)
  local name = Layout.MacroSpellName(entry)
  return (L().macroBody:gsub("{spell}", function() return name end))
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
      if not Layout.Matches(cur, d, s.slot) then
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

-- Is a known spell in its planned slot, with its key bound and its bar shown? nil when it has no slot or is unknown.
function Layout.IsPlaced(entry)
  if not Spells.LayoutSlot(entry) or not Spells.IsKnown(entry) then return nil end
  return Layout.IsEmptyPlan(Layout.BuildPlan(entry.key))
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

-- Undo the newest change, or the given backup record (the rank toast's 元に戻す button).
function Layout.Undo(record)
  if not Layout.CanUndo() then
    ns.UI.Toast(ns.T("ui.layout.noundo"))
    return
  end
  ns.OutOfCombat("layout", function()
    local b
    if record then
      for i, r in ipairs(ns.char.backups) do
        if r == record then b = table.remove(ns.char.backups, i) end
      end
      if not b then
        ns.UI.Toast(ns.T("ui.layout.noundo"))
        return
      end
    else
      b = table.remove(ns.char.backups)
    end
    -- Undoing a rank upgrade means she wants the older rank in those slots: do not upgrade them again.
    if b.kind == "ranks" then
      for slot, saved in pairs(b.slots) do
        if saved and saved.type == "spell" then ns.char.keepRank[slot] = saved.id end
      end
    end
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
    preview.sf:SetPoint("TOPLEFT", preview.intro, "BOTTOMLEFT", 0, -12)
    preview.body = UI.Text(preview.content, 12)
    preview.body:SetPoint("TOPLEFT", 0, 0)
    preview.body:SetWidth(540)
    preview.apply = UI.Button(preview, ns.T("ui.btn.apply"), 160, 24)
    preview.apply:SetPoint("BOTTOMRIGHT", preview, "BOTTOM", -6, 14)
    preview.cancel = UI.Button(preview, ns.T("ui.btn.cancel"), 160, 24, function() preview:Hide() end)
    preview.cancel:SetPoint("BOTTOMLEFT", preview, "BOTTOM", 6, 14)
    UI.AutoFit(preview, function(self) self:SetHeight(40 + UI.H(self.intro) + 12 + 340 + 52) end)
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
  ns.UI.Refit(preview)
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

-- Slots holding an older rank than the highest one she knows, as a plain spell (macros are checked by
-- CheckMacroRank). Slots where she undid an upgrade keep their rank. → { { slot, entry, old, new } }
function Layout.OutdatedRanks()
  local list = {}
  local keep = ns.char and ns.char.keepRank or {}
  for _, slot in ipairs(Layout.SLOTS) do
    local cur = Layout.Current(slot)
    if cur and cur.type == "spell" and cur.planKey then
      if keep[slot] and keep[slot] ~= cur.id then keep[slot] = nil end
      local e = Spells.Get(cur.planKey)
      local have = Spells.RankOf(e, cur.id)
      local best, bestId = Spells.KnownRank(e)
      if have and best and have < best and keep[slot] ~= cur.id then
        table.insert(list, { slot = slot, entry = e, old = cur.id, new = bestId })
      end
    end
  end
  return list
end

-- Put the highest known rank in every outdated slot (call only out of combat). One undo record.
-- → number of buttons changed, backup record (nil when nothing changed)
function Layout.UpgradeRanks()
  local list = Layout.OutdatedRanks()
  if #list == 0 then return 0, nil end
  local backup = { kind = "ranks", time = time and time() or 0, moves = {}, slots = {}, binds = {}, bars = {} }
  for _, u in ipairs(list) do
    backup.slots[u.slot] = info(Layout.Current(u.slot))
    call(API.pickupSpell, u.new)
    put(u.slot)
  end
  pushBackup(backup)
  return #list, backup
end

-- Does the macro cast this rank? → true, false, or nil when the client cannot tell (GetMacroSpell missing/empty)
local function macroCasts(idx, id)
  local ok, spell = call(API.macroSpell, idx)
  if not ok or not spell then return nil end
  return spell == id
end

-- Make the spell's mouseover macro (if she has it) cast the highest known rank. "/cast <Name>" normally does;
-- if the client says it casts a lower rank, the macro names the rank instead ("Name(Rank N)"), and goes back to
-- the plain name if that does not help either. Call only out of combat. → "ok" | "ranked" | "unknown" | "failed" | nil
function Layout.CheckMacroRank(entry)
  local name = L().macros[entry.key]
  if not name or #Spells.Ranks(entry) < 2 then return nil end
  local ok, idx = call(API.macroIndex, name)
  if not ok or type(idx) ~= "number" or idx == 0 then return nil end
  local _, best = Spells.KnownRank(entry)
  if not best then return nil end
  local casts = macroCasts(idx, best)
  if casts == nil then return "unknown" end
  if casts then return ns.char.macroRank[entry.key] and "ranked" or "ok" end
  -- Candidates: the plain name (if the macro names a rank now), then the highest rank by name.
  local candidates = {}
  if ns.char.macroRank[entry.key] then table.insert(candidates, false) end
  local okS, sub = ns.Call("C_Spell.GetSpellSubtext", best)
  if okS and type(sub) == "string" and sub:match("%d") then table.insert(candidates, sub) end
  for _, rank in ipairs(candidates) do
    ns.char.macroRank[entry.key] = rank or nil
    local newIdx = Layout.EnsureMacro(entry)
    if newIdx and macroCasts(newIdx, best) then return rank and "ranked" or "ok" end
  end
  ns.char.macroRank[entry.key] = nil
  Layout.EnsureMacro(entry)
  ns.Debug("macro " .. name .. " does not cast " .. tostring(best))
  return "failed"
end

-- After learning a rank (and at login): upgrade the bar buttons and the macros, then confirm with a toast.
-- learned = entries with a new rank (nil at login: only a toast when buttons changed). Queued in combat.
function Layout.ApplyNewRanks(learned)
  ns.OutOfCombat("ranks", function()
    local n, backup = 0, nil
    if ns.settings.autoRanks then n, backup = Layout.UpgradeRanks() end
    for _, e in ipairs(Spells.List()) do
      if Spells.IsKnown(e) then Layout.CheckMacroRank(e) end
    end
    local lines = {}
    if learned and #learned > 0 then
      local names = {}
      for _, e in ipairs(learned) do
        local rank = Spells.KnownRank(e)
        table.insert(names, rank and (e.name .. " (Rank " .. rank .. ")") or e.name)
      end
      table.insert(lines, ns.T("ui.rank.learned", { names = table.concat(names, ", ") }))
    end
    if n > 0 then table.insert(lines, ns.T("ui.rank.upgraded", { n = n })) end
    if #lines == 0 then return end
    if backup then
      ns.UI.Toast(table.concat(lines, "\n"), 15, ns.T("ui.btn.undo"), function() Layout.Undo(backup) end)
    else
      ns.UI.Toast(table.concat(lines, "\n"), 8)
    end
    if ns.Guide and ns.Guide.Refresh then ns.Guide.Refresh() end
  end)
end

-- Switch between mouseover macros and plain spells, swapping what is on the bars in place.
function Layout.SetTargeting(mode)
  ns.settings.targeting = mode
  ns.OutOfCombat("targeting", function()
    local n, fallback = 0, false
    for _, slot in ipairs(Layout.SLOTS) do
      local cur = Layout.Current(slot)
      if cur and cur.planKey and L().macros[cur.planKey] then
        local d = Layout.Desired(Spells.Get(cur.planKey))
        if d and not Layout.Matches(cur, d, slot) then
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
