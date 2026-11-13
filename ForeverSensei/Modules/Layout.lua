-- Modules/Layout.lua: putting skills on the planned slots and keys.
-- All bar, binding and macro changes run out of combat (ns.OutOfCombat) and push an undo record.
-- Legacy globals (PlaceAction, PickupAction, SetBinding, ...) are resolved at runtime; /sensei verify lists missing ones.
local _, ns = ...
local Layout = {}
ns.Layout = Layout

local function L() return ns.spec.layout end
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
  bindingKey = { "GetBindingKey" },
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

-- Action slots that can hold the player's spells: bars 1-6 (1-120; 73-120 are unused stance pages for a Shaman) and the
-- extra bars 6-8 of the 12.x UI (145-180). 121-144 are override/vehicle bars and are never touched.
Layout.SLOTS = {}
for i = 1, 120 do table.insert(Layout.SLOTS, i) end
for i = 145, 180 do table.insert(Layout.SLOTS, i) end

local macroKeys -- macro name → spell key, "@kind" for the item macros, "!id" for the multi-spell macros
local function macroKeyOf(name)
  if not macroKeys then
    macroKeys = {}
    for key, m in pairs(L().macros) do macroKeys[m] = key end
    for id, c in pairs(L().combos) do macroKeys[c.macro] = "!" .. id end
    for kind, d in pairs(ns.ItemData.kinds) do macroKeys[d.macro] = "@" .. kind end
  end
  return name and macroKeys[name]
end

-- What sits in an action slot now. → { type, id, name, macroName, planKey } or nil when empty
-- planKey: the plan entry it belongs to: a spell key, or "@kind" for an item macro or a potion/elixir of that kind.
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
    -- The Forever client reports a macro that shows a spell as ("macro", spellID, "spell"): id is only the macro
    -- index when there is no subType.
    if (not name or name == "") and (sub == nil or sub == "") then
      local ok3, n = call(API.macroInfo, id)
      name = ok3 and n or nil
    end
    cur.macroName = name
    cur.name = name
    cur.planKey = macroKeyOf(name)
  elseif t == "item" then
    local ok2, n = call(API.itemName, id)
    cur.name = ok2 and n or nil
    local kind = ns.Items.KindOf(id)
    cur.planKey = kind and ("@" .. kind)
  end
  return cur
end

function Layout.Label(cur)
  if not cur then return ns.T("ui.preview.empty") end
  if cur.type == "macro" then return ns.T("ui.preview.macro", { name = cur.macroName or "?" }) end
  return cur.name or (tostring(cur.type) .. " " .. tostring(cur.id))
end

function Layout.UsesMacro(entry)
  local layout = L()
  if not layout.macros[entry.key] then return false end
  return layout.macroAlways[entry.key] == true or ns.settings.targeting == "mouseover"
end

-- The action this spell should be in its slot. → { kind = "spell"|"macro", entry, id, macro, name } or nil when not known
function Layout.Desired(entry)
  if not entry or not Spells.IsKnown(entry) then return nil end
  if Layout.UsesMacro(entry) then
    return { kind = "macro", entry = entry, macro = L().macros[entry.key], name = entry.name }
  end
  return { kind = "spell", entry = entry, id = Spells.CurrentID(entry), name = entry.name }
end

-- An item slot always gets its macro, also with none in the bags (it shows a fixed icon then).
function Layout.DesiredItem(kind)
  local d = ns.Items.Get(kind)
  return { kind = "macro", item = kind, macro = d.macro, name = d.label }
end

-- A multi-spell macro (L.combos: the paladin's opener) is always a macro, available once its "needs" spell is known.
function Layout.DesiredCombo(id)
  local c = L().combos[id]
  if not c or not Spells.IsKnown(Spells.Get(c.needs)) then return nil end
  return { kind = "macro", combo = id, macro = c.macro, name = ns.T(c.label) }
end

-- The desired action of a planned slot. → desired or nil
-- standIn: the spell this slot holds until its own spell is learned (Lightning Shield on X before Water Shield).
-- after: the slot is only used once that spell is known (Lightning Shield's clickable slot after Water Shield).
function Layout.DesiredFor(s)
  if s.item then return Layout.DesiredItem(s.item) end
  if s.combo then return Layout.DesiredCombo(s.combo) end
  if s.after and not Spells.IsKnown(Spells.Get(s.after)) then return nil end
  local d = Layout.Desired(Spells.Get(s.spell))
  if not d and s.standIn then d = Layout.Desired(Spells.Get(s.standIn)) end
  return d
end

-- slot (optional): an older rank the player kept there on purpose (undid its upgrade) counts as a match.
function Layout.Matches(cur, d, slot)
  if not cur or not d then return false end
  if d.kind == "macro" then return cur.type == "macro" and cur.macroName == d.macro end
  if cur.type ~= "spell" or cur.planKey ~= d.entry.key then return false end
  if cur.id == d.id then return true end
  local keep = slot and ns.char and ns.char.keepRank
  return keep ~= nil and keep[slot] == cur.id
end

function Layout.DesiredLabel(d)
  if d.kind == "macro" then return ns.T("ui.preview.macro", { name = d.macro }) .. " (" .. d.name .. ")" end
  return d.name
end

-- The spell as the macro names it: the plain name (the client casts the highest rank), or "Name(Rank N)" when
-- CheckMacroRank found that the plain name does not cast the highest rank.
function Layout.MacroSpellName(entry)
  local rank = ns.char and ns.char.macroRank and ns.char.macroRank[entry.key]
  if rank then return entry.name .. "(" .. rank .. ")" end
  return entry.name
end

function Layout.MacroBody(entry)
  local layout = L()
  local kind = layout.macroKind[entry.key] or "help"
  if ns.settings.targeting ~= "mouseover" and layout.macroBodies[kind .. "_click"] then kind = kind .. "_click" end
  -- {spell} is the spell itself; the spec's macroVars name the other spells a body casts ({heal} = healing_wave).
  local vars = { spell = Layout.MacroSpellName(entry) }
  for var, key in pairs(layout.macroVars) do
    local other = Spells.Get(key)
    if other then vars[var] = Layout.MacroSpellName(other) end
  end
  return (layout.macroBodies[kind]:gsub("{(%w+)}", function(k) return vars[k] end))
end

-- A multi-spell macro's text: its body with {var} = the spells of its vars (as their own macros name them).
function Layout.ComboBody(id)
  local c = L().combos[id]
  local vars = {}
  for var, key in pairs(c.vars) do
    local e = Spells.Get(key)
    if e then vars[var] = Layout.MacroSpellName(e) end
  end
  return (c.body:gsub("{(%w+)}", function(k) return vars[k] end))
end

local function writeMacro(name, body)
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

-- Create or update the character macro for a spell. → macro index or nil
function Layout.EnsureMacro(entry)
  local name = L().macros[entry.key]
  if not name then return nil end
  return writeMacro(name, Layout.MacroBody(entry))
end

-- Create or update a multi-spell macro. → macro index or nil
function Layout.EnsureComboMacro(id)
  return writeMacro(L().combos[id].macro, Layout.ComboBody(id))
end

-- Bring the existing spell macros up to date (rank, targeting mode). Never creates macros (only the layout does).
-- Call only out of combat. → number of macros changed
function Layout.RefreshMacros()
  local n = 0
  local function refresh(name, body)
    local ok, idx = call(API.macroIndex, name)
    if ok and type(idx) == "number" and idx > 0 then
      local okI, _, _, cur = call(API.macroInfo, idx)
      if not okI or cur ~= body then
        call(API.editMacro, idx, name, "INV_MISC_QUESTIONMARK", body)
        n = n + 1
      end
    end
  end
  for key, name in pairs(L().macros) do refresh(name, Layout.MacroBody(Spells.Get(key))) end
  for id, c in pairs(L().combos) do refresh(c.macro, Layout.ComboBody(id)) end
  return n
end

local function put(slot)
  call(API.placeAction, slot)
  call(API.clearCursor)
end

-- Place a desired action. → true, usedFallback ("spell" or "item": the macro could not be created)
local function placeDesired(slot, d)
  if d.item then
    local idx = ns.Items.EnsureMacro(d.item)
    if idx then
      call(API.pickupMacro, idx)
      put(slot)
      return true, false
    end
    local best = ns.Items.Best(d.item)
    if best then
      call(API.pickupItem, best.id)
      put(slot)
    end
    return true, "item"
  end
  if d.combo then
    local idx = Layout.EnsureComboMacro(d.combo)
    if idx then
      call(API.pickupMacro, idx)
      put(slot)
      return true, false
    end
    call(API.pickupSpell, Spells.CurrentID(Spells.Get(L().combos[d.combo].needs)))
    put(slot)
    return true, "spell"
  end
  if d.kind == "macro" then
    local idx = Layout.EnsureMacro(d.entry)
    if idx then
      call(API.pickupMacro, idx)
      put(slot)
      return true, false
    end
    call(API.pickupSpell, Spells.CurrentID(d.entry))
    put(slot)
    return true, "spell"
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

-- A planned spell slot that has nothing to hold yet (its spell is not learned; item slots are always in use).
local function reservedUnknown(s)
  return s.spell ~= nil and not Layout.DesiredFor(s)
end

-- Is this plan key a known spell with its own planned slot? Only those are cleared as duplicates.
local function placedElsewhere(planKey)
  local e = planKey and Spells.Get(planKey)
  return e ~= nil and Spells.LayoutSlot(e) ~= nil and Layout.Desired(e) ~= nil
end

-- Has this plan key (a spell, "@kind" item macro or "!id" multi-spell macro) its own planned slot to go to?
local function hasHome(planKey)
  if type(planKey) ~= "string" then return false end
  local layout = L()
  local item = planKey:match("^@(%w+)$")
  if item then return layout.byItem[item] ~= nil end
  local combo = planKey:match("^!(%w+)$")
  if combo then return layout.byCombo[combo] ~= nil and Layout.DesiredCombo(combo) ~= nil end
  return placedElsewhere(planKey)
end

-- The bar and button of a slot on a planned or retired bar. → { bar, button, slot } or nil
local function whereOf(slot)
  local layout = L()
  for _, list in ipairs({ layout.bars, layout.retired }) do
    for _, bar in ipairs(list) do
      if slot >= bar.first and slot < bar.first + 12 then
        return { bar = bar.id, button = slot - bar.first + 1, slot = slot }
      end
    end
  end
end

-- The buttons of a retired bar that the addon used (all 12 when the bar does not list them).
local function retiredButtons(bar)
  if bar.assigned then return bar.assigned end
  local all = {}
  for i = 1, 12 do all[i] = i end
  return all
end

-- Work out every change. onlyKey limits it to one spell (the card's 配置する button).
-- → plan { place, moves, clears, lost, binds, bars, hide }
function Layout.BuildPlan(onlyKey)
  local layout = L()
  local plan = { place = {}, moves = {}, clears = {}, lost = {}, binds = {}, bars = {}, hide = {} }
  local targets = {}
  for _, s in ipairs(layout.slots) do
    local d = Layout.DesiredFor(s)
    -- A spell learned "after" another (Lightning Shield after Water Shield) moves with it, so it is not lost.
    -- A multi-spell macro comes with the spell it needs (the opener with Swift Judgement).
    if d and (not onlyKey or (d.entry and d.entry.key == onlyKey) or s.after == onlyKey
      or (s.combo and layout.combos[s.combo].needs == onlyKey)) then
      targets[s.slot] = d
    end
  end

  -- Displaced actions go to empty free slots: the spare buttons (in L.spareOrder bar order) first, then slots
  -- reserved for spells the player does not know yet, in the same bar order, right to left.
  local free = {}
  for _, s in ipairs(layout.spare) do
    if Layout.Current(s.slot) == nil then table.insert(free, s) end
  end
  for _, barId in ipairs(layout.spareOrder or { "bar4", "bar3" }) do
    for i = #layout.slots, 1, -1 do
      local s = layout.slots[i]
      if s.bar == barId and not targets[s.slot] and reservedUnknown(s) and Layout.Current(s.slot) == nil then
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
            barsNeeded[dest.bar] = true
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
          table.insert(plan.binds, { key = s.key, binding = s.binding, old = action, name = d.name })
        end
      end
      barsNeeded[s.bar] = true
    end
  end

  -- Copies of planned spells in slots reserved for spells the player does not know yet would become duplicates.
  for _, s in ipairs(layout.slots) do
    if not targets[s.slot] and reservedUnknown(s) then
      local cur = Layout.Current(s.slot)
      if cur and cur.planKey and (not onlyKey or cur.planKey == onlyKey) and placedElsewhere(cur.planKey) then
        table.insert(plan.clears, { slot = s.slot, where = s, label = Layout.Label(cur) })
      end
    end
  end
  -- Spare buttons with a key (Shift+2, Ctrl+R, ...), full apply only: bound to their empty button, so every key of
  -- the Shift and Ctrl bars works the same way.
  if not onlyKey then
    for _, s in ipairs(layout.spare) do
      if s.key then
        local ok, action = call(API.bindingAction, s.key)
        action = ok and action ~= "" and action or nil
        if action ~= s.binding then
          table.insert(plan.binds, { key = s.key, binding = s.binding, old = action, name = ns.T("ui.preview.sparekey") })
        end
      end
    end
  end
  -- Buttons that earlier layouts used and that the plan no longer fills (spare now, or on a retired bar): clear them
  -- only while they still hold exactly that layout's spell or macro and it has its new place or lives in the
  -- spellbook now. Anything else the player put there stays.
  local cleared = {}
  if not onlyKey then
    for _, c in ipairs(plan.clears) do cleared[c.slot] = true end
    local planned = {}
    for _, s in ipairs(layout.slots) do planned[s.slot] = true end
    for slot, keys in pairs(layout.old) do
      local cur = not planned[slot] and not cleared[slot] and Layout.Current(slot)
      local where = cur and cur.planKey and whereOf(slot)
      if where then
        for _, key in ipairs(type(keys) == "table" and keys or { keys }) do
          if cur.planKey == key and (hasHome(key) or layout.noSlot[key] == "spellbook") then
            table.insert(plan.clears, { slot = slot, where = where, label = Layout.Label(cur) })
            cleared[slot] = true
            break
          end
        end
      end
    end
  end
  -- Retired bars, full apply only. A hidden one (Action Bar 7, layout 3): clear the plan's spells on the buttons the
  -- addon used once they have their own slot, hide the bar and unbind keys that still point at its buttons. A bar
  -- that stays shown (keepShown: Action Bar 5) is the player's now; only L.old leftovers are cleared there.
  if not onlyKey then
    for _, bar in ipairs(layout.retired) do
      if not bar.keepShown then
        for _, i in ipairs(retiredButtons(bar)) do
          local slot = bar.first + i - 1
          local cur = not cleared[slot] and Layout.Current(slot)
          if cur and cur.planKey and placedElsewhere(cur.planKey) then
            table.insert(plan.clears, { slot = slot, where = { bar = bar.id, button = i, slot = slot }, label = Layout.Label(cur) })
            cleared[slot] = true
          end
        end
      end
    end
    local skip = {}
    for _, b in ipairs(plan.binds) do skip[b.key] = true end
    local candidates, seen = {}, {}
    local function add(k)
      if type(k) == "string" and k ~= "" and not seen[k] then
        seen[k] = true
        table.insert(candidates, k)
      end
    end
    for _, k in ipairs(layout.allowedKeys) do add(k) end
    for _, bar in ipairs(layout.retired) do
      if not bar.keepShown then
        for i = 1, 12 do
          local ok, k1, k2 = call(API.bindingKey, string.format(bar.binding, i))
          if ok then add(k1); add(k2) end
        end
        local ok, shown = call(API.getSetting, bar.setting)
        if ok and shown == true then table.insert(plan.hide, bar) end
      end
    end
    for _, key in ipairs(candidates) do
      if not skip[key] then
        local ok, action = call(API.bindingAction, key)
        if ok and type(action) == "string" and Layout.IsRetiredBinding(action) then
          table.insert(plan.binds, { key = key, old = action, name = ns.T("ui.preview.none") })
        end
      end
    end
  end
  table.sort(plan.clears, function(a, b) return a.slot < b.slot end)

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
    and #(plan.hide or {}) == 0
end

-- Is this binding action a button of a hidden retired bar ("MULTIACTIONBAR6BUTTON3")? Bars that stay shown
-- (keepShown) are the player's: keys that point there are left alone.
function Layout.IsRetiredBinding(action)
  for _, bar in ipairs(L().retired) do
    local prefix = not bar.keepShown and bar.binding:gsub("%%d", "")
    if prefix and action:sub(1, #prefix) == prefix and action:sub(#prefix + 1):match("^%d+$") then return true end
  end
  return false
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
  local fallback = {}
  for _, p in ipairs(plan.place) do
    if not movedFrom[p.slot] and backup.slots[p.slot] == nil then backup.slots[p.slot] = info(p.old) end
    local _, fb = placeDesired(p.slot, p.desired)
    if fb then fallback[fb] = true end
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
  for _, bar in ipairs(plan.hide or {}) do
    local ok, old = call(API.getSetting, bar.setting)
    if call(API.setSetting, bar.setting, false) then backup.bars[bar.setting] = ok and old or false end
  end
  pushBackup(backup)
  if fallback.spell then ns.UI.Toast(ns.T("ui.layout.macrofail"), 12) end
  if fallback.item then ns.UI.Toast(ns.T("ui.items.macrofail"), 12) end
  if ns.NewSkill then ns.NewSkill.PrunePostponed() end
  if ns.UnitFrames then ns.UnitFrames.Refresh() end
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
    -- Undoing a rank upgrade means the player wants the older rank in those slots: do not upgrade them again.
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
    if ns.UnitFrames then ns.UnitFrames.Refresh() end
    if ns.Guide and ns.Guide.Refresh then ns.Guide.Refresh() end
  end)
end

-- Notes on default bindings a plan replaces: the stance bar on Ctrl+1-4, the framerate display on Ctrl+R, the mouse
-- side buttons. → list of text lines, one per kind (its keys joined: "Ctrl+1, Ctrl+2")
function Layout.Warnings(plan)
  local order, keys = {}, {}
  local function add(id, key)
    if not keys[id] then
      keys[id] = {}
      table.insert(order, id)
    end
    if key then table.insert(keys[id], ns.KeyLabel(key)) end
  end
  for _, b in ipairs(plan.binds) do
    local id = L().defaultWarn[b.key]
    if not id and b.old then
      if b.old:match("^SHAPESHIFTBUTTON") then id = "ui.preview.warn.stance" end
      if b.old == "TOGGLEFPS" then id = "ui.preview.warn.fps" end
    end
    if id then add(id, b.key) end
    if b.key:match("BUTTON[45]$") then add("ui.preview.warn.mouse") end
  end
  local out = {}
  for _, id in ipairs(order) do table.insert(out, ns.T(id, { key = table.concat(keys[id], ", ") })) end
  return out
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
      table.insert(lines, ns.T("ui.preview.keyline", { key = ns.KeyLabel(b.key), old = bindingName(b.old), new = b.name }))
    end
  end
  if #plan.bars > 0 then
    head("ui.preview.bars")
    for _, bar in ipairs(plan.bars) do table.insert(lines, ns.T("ui.bar." .. bar.id)) end
  end
  if #(plan.hide or {}) > 0 then
    head("ui.preview.hide")
    for _, bar in ipairs(plan.hide) do table.insert(lines, ns.T("ui.bar." .. bar.id)) end
  end
  head("ui.preview.notes")
  for _, w in ipairs(Layout.Warnings(plan)) do table.insert(lines, w) end
  -- A bar that starts in the middle of the screen (Action Bar 6): tell the player to move it in Edit Mode.
  local moveBar
  for _, list in ipairs({ plan.place, plan.binds }) do
    for _, x in ipairs(list) do
      local bar = x.where and barById(x.where.bar)
      if not bar and x.binding then
        for _, b in ipairs(L().bars) do
          local prefix = b.binding:gsub("%%d", "")
          if x.binding:sub(1, #prefix) == prefix and x.binding:sub(#prefix + 1):match("^%d+$") then bar = b end
        end
      end
      if bar and bar.editMode then moveBar = moveBar or bar end
    end
  end
  if moveBar then table.insert(lines, ns.T("ui.preview.warn.editmode", { bar = ns.T("ui.bar." .. moveBar.id) })) end
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

ns.OnLanguage(function()
  if not preview then return end
  local shown = preview:IsShown()
  ns.UI.Discard(preview)
  preview = nil
  if shown then Layout.Preview() end
end)

-- The clean-up button: only the buttons the addon configures. Those are every slot of the plan (spells, item macros,
-- stand-ins, and slots kept free for spells not learned yet) and the buttons the last layout there filled on the
-- retired bars (L.retired assigned: Action Bar 5 from layouts 4-6 or the paladin's layout 1, Action Bar 7 from layout
-- 3). Spare buttons and any other button are never touched.
-- → plan with clears only (Execute backs them up, Undo restores them)
function Layout.BuildCleanPlan()
  local layout = L()
  local plan = { place = {}, moves = {}, clears = {}, lost = {}, binds = {}, bars = {}, hide = {} }
  local function add(slot, where)
    local cur = Layout.Current(slot)
    if cur then table.insert(plan.clears, { slot = slot, where = where, label = Layout.Label(cur) }) end
  end
  for _, s in ipairs(layout.slots) do add(s.slot, s) end
  for _, bar in ipairs(layout.retired) do
    for _, i in ipairs(bar.assigned) do
      local slot = bar.first + i - 1
      add(slot, { bar = bar.id, button = i, slot = slot })
    end
  end
  table.sort(plan.clears, function(a, b) return a.slot < b.slot end)
  return plan
end

-- Undo can put back spells, macros and items; anything else (a mount, a flyout, ...) is named in the question.
local RESTORABLE = { spell = true, macro = true, item = true }

function Layout.Clean()
  if ns.InCombat() then
    ns.UI.Toast(ns.T("ui.combat.later"))
    return
  end
  local plan = Layout.BuildCleanPlan()
  if #plan.clears == 0 then
    ns.UI.Toast(ns.T("ui.clean.nothing"))
    return
  end
  local text = ns.T("ui.clean.confirm", { n = #plan.clears })
  local other = {}
  for _, c in ipairs(plan.clears) do
    local cur = Layout.Current(c.slot)
    if cur and not RESTORABLE[cur.type] then table.insert(other, c.label) end
  end
  if #other > 0 then text = text .. "\n\n" .. ns.T("ui.clean.norestore", { list = table.concat(other, ", ") }) end
  ns.UI.Confirm(text, ns.T("ui.btn.clean"), function()
    ns.OutOfCombat("clean", function()
      Layout.Execute(Layout.BuildCleanPlan())
      ns.UI.Toast(ns.T("ui.clean.done"), 12)
      if ns.Guide and ns.Guide.Refresh then ns.Guide.Refresh() end
    end)
  end)
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
      table.insert(warn, ns.T("ui.place.keybusy", { key = ns.KeyLabel(b.key), action = bindingName(b.old) }))
    end
  end
  for _, w in ipairs(Layout.Warnings(plan)) do table.insert(warn, w) end
  if #warn == 0 then
    go()
  else
    ns.UI.Confirm(ns.T("ui.place.confirm", { name = entry.name }) .. "\n\n" .. table.concat(warn, "\n"), ns.T("ui.btn.place"), go)
  end
end

-- Slots holding an older rank than the highest one the player knows, as a plain spell (macros are checked by
-- CheckMacroRank). Slots where the player undid an upgrade keep their rank. → { { slot, entry, old, new } }
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

-- Make the spell's mouseover macro (if the player has it) cast the highest known rank. "/cast <Name>" normally does;
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
    Layout.RefreshMacros()
    if ns.UnitFrames then ns.UnitFrames.Refresh() end
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
    local n, fallback = 0, nil
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
    Layout.RefreshMacros()
    if ns.UnitFrames then ns.UnitFrames.Refresh() end
    ns.UI.Toast(ns.T(mode == "mouseover" and "ui.targeting.mouseover.done" or "ui.targeting.click.done", { n = n }), 10)
    if fallback then ns.UI.Toast(ns.T("ui.layout.macrofail"), 12) end
    if ns.Guide and ns.Guide.Refresh then ns.Guide.Refresh() end
  end)
end

ns.Command("apply", function() Layout.Preview() end, true)
ns.Command("undo", function() Layout.Undo() end, true)
ns.Command("clean", function() Layout.Clean() end, true)

-- One-time notice after an update that changed the layout (L.version). It only offers the preview: nothing moves
-- unless the player applies it there (with the usual backup and undo). New characters just get the current version.
ns.OnLogin(function()
  if not ns.Active() then return end
  local version = L().version
  if not ns.char.initialised then
    ns.char.layoutVersion = version
    return
  end
  if (ns.char.layoutVersion or 1) >= version then return end
  C_Timer.After(6, function()
    ns.OutOfCombat("layout-notice", function()
      ns.char.layoutVersion = version
      if Layout.IsEmptyPlan(Layout.BuildPlan()) then return end
      ns.UI.Confirm(ns.T("ui.layout.changed"), ns.T("ui.btn.applyall"), Layout.Preview)
    end)
  end)
end)
