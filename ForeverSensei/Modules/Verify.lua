-- Modules/Verify.lua: /sensei verify checks the addon's data and API assumptions against the running client
-- and shows an English report in a copy box (paste it to the maintainer). Nothing is changed.
local _, ns = ...
local Verify = {}
ns.Verify = Verify

local APIS = {
  "C_Spell.GetSpellInfo", "C_Spell.GetSpellName", "C_Spell.GetSpellTexture", "C_Spell.GetSpellSubtext",
  "C_Spell.PickupSpell", "C_Spell.GetSpellLevelLearned", "C_SpellBook.IsSpellKnown",
  "C_SpellBook.FindSpellBookSlotForSpell", "IsPlayerSpell",
  "GetActionInfo", "GetActionText", "PickupAction", "PlaceAction", "ClearCursor",
  "PickupMacro", "GetMacroIndexByName", "GetMacroInfo", "GetMacroSpell", "CreateMacro", "EditMacro",
  "C_Item.PickupItem", "C_Item.GetItemNameByID",
  "GetBindingAction", "GetBindingKey", "SetBinding", "SaveBindings", "GetCurrentBindingSet",
  "Settings.GetValue", "Settings.SetValue",
  "C_ClassTalents.GetActiveConfigID", "C_Traits.GetConfigInfo", "C_Traits.GetTreeNodes", "C_Traits.GetNodeInfo",
  "C_Traits.GetEntryInfo", "C_Traits.GetDefinitionInfo", "C_Traits.GetTreeCurrencyInfo",
  "PlayerSpellsUtil.ToggleClassTalentOrSpecFrame", "C_Timer.NewTimer", "InCombatLockdown",
}

function Verify.Run()
  local out, problems = {}, 0
  local function add(s) table.insert(out, s) end
  local function bad(s)
    problems = problems + 1
    add("  !! " .. s)
  end
  local _, build, _, toc = GetBuildInfo()
  add(string.format("ForeverSensei v%s verify  client %s  interface %s  project %s", ns.VERSION, tostring(build),
    tostring(toc), tostring(WOW_PROJECT_ID)))
  add(string.format("player: level %d %s  targeting=%s  font=%s", ns.Spells.PlayerLevel(), select(2, UnitClass("player")) or "?",
    ns.settings.targeting, ns.Font.PATH))

  add("")
  add("[API]")
  for _, path in ipairs(APIS) do
    if not ns.API(path) then bad("missing API " .. path) end
  end
  for event, err in pairs(ns.missingEvents) do bad("event " .. event .. ": " .. err) end

  add("")
  add("[Spells]  id/name/level checked against the client")
  for _, e in ipairs(ns.Spells.List()) do
    local name = ns.Spells.Name(e.id)
    if name ~= e.name then bad(string.format("%s: id %d is '%s' in the client", e.name, e.id, tostring(name))) end
    if not e.talent then
      local ok, lvl = ns.Call("C_Spell.GetSpellLevelLearned", e.id)
      if ok and type(lvl) == "number" and lvl > 0 and lvl ~= e.level then
        bad(string.format("%s: data level %d, client level %d", e.name, e.level, lvl))
      end
    end
    local known = ns.Spells.IsKnown(e)
    local cur = ns.Spells.CurrentID(e)
    local okR1, r1 = ns.Call("C_SpellBook.IsSpellKnown", e.id)
    local _, sub = ns.Call("C_Spell.GetSpellSubtext", cur)
    if known then
      add(string.format("  %-24s known  current id %s %s  IsSpellKnown(rank1)=%s", e.name, tostring(cur), tostring(sub or ""),
        okR1 and tostring(r1) or "error"))
    elseif e.level <= ns.Spells.PlayerLevel() and not e.talent then
      add(string.format("  %-24s not learned yet (level %d)", e.name, e.level))
    end
  end

  add("")
  add("[Ranks]  every rank id in " .. ns.class.name .. "/Data/Ranks.lua: name and 'Rank N' checked against the client")
  local rankIds = 0
  for _, e in ipairs(ns.Spells.List()) do
    local ranks = ns.Spells.Ranks(e)
    if #ranks > 1 then
      for r, id in ipairs(ranks) do
        rankIds = rankIds + 1
        local name = ns.Spells.Name(id)
        local okS, sub = ns.Call("C_Spell.GetSpellSubtext", id)
        if name ~= e.name then bad(string.format("%s rank %d: id %d is '%s' in the client", e.name, r, id, tostring(name))) end
        if okS and type(sub) == "string" and sub ~= "" and sub ~= "Rank " .. r and sub:match("%d") then
          bad(string.format("%s rank %d: id %d subtext '%s'", e.name, r, id, sub))
        end
      end
      local best, bestId = ns.Spells.KnownRank(e)
      if best then add(string.format("  %-24s highest known rank %d (id %d) of %d", e.name, best, bestId, #ranks)) end
    end
  end
  add(string.format("  %d rank ids checked", rankIds))

  add("")
  add("[Talents]")
  local ranks, unspent, source, maxRanks = ns.Talents.Read()
  if not ranks then
    bad("talent tree could not be read through C_Traits (advice follows the level only)")
  else
    add(string.format("  read via %s, unspent=%s", tostring(source), tostring(unspent)))
    for _, t in ipairs(ns.spec.talents.list) do
      if ranks[t.name] == nil then
        bad("talent not found in tree: " .. t.name)
      else
        if maxRanks[t.name] and maxRanks[t.name] ~= t.max then
          bad(string.format("%s: data max %d, client max %d", t.name, t.max, maxRanks[t.name]))
        end
        if ranks[t.name] > 0 then add(string.format("  %s %d/%d", t.name, ranks[t.name], t.max)) end
      end
    end
  end
  local s = ns.Talents.State()
  if s.next then add("  next: " .. s.next.key .. " rank " .. s.next.rank) end

  add("")
  add("[Layout]")
  local layout = ns.spec.layout
  for _, slot in ipairs(layout.slots) do
    local cur = ns.Layout.Current(slot.slot)
    local okB, action = false, nil
    if slot.key then okB, action = ns.Call("GetBindingAction", slot.key) end
    add(string.format("  slot %3d %-24s now: %-28s %s", slot.slot, slot.spell or (slot.item and ("@" .. slot.item)) or ("!" .. slot.combo), ns.Layout.Label(cur),
      slot.key and (slot.key .. "=" .. tostring(okB and action or "?")) or ""))
  end
  for _, bar in ipairs(layout.bars) do
    if bar.setting then
      local ok, v = ns.Call("Settings.GetValue", bar.setting)
      add(string.format("  %s %s = %s", bar.id, bar.setting, ok and tostring(v) or ("error " .. tostring(v))))
    end
  end
  -- Keys whose game default the layout may replace (the stance bar on Ctrl+1-5, the framerate on Ctrl+R) and the
  -- mouse keys on Action Bar 6 (research/keybind-layout-v4.md, "Verify in game").
  for _, key in ipairs({ "CTRL-1", "CTRL-2", "CTRL-3", "CTRL-4", "CTRL-5", "CTRL-R", "BUTTON4", "SHIFT-BUTTON4",
    "CTRL-BUTTON4" }) do
    local ok, action = ns.Call("GetBindingAction", key)
    add(string.format("  key %s = %s", key, ok and tostring(action) or "?"))
  end
  for _, bar in ipairs(layout.retired) do
    local ok, v = ns.Call("Settings.GetValue", bar.setting)
    add(string.format("  retired %s %s = %s", bar.id, bar.setting, ok and tostring(v) or ("error " .. tostring(v))))
  end
  -- In-game question: does "/cast Name" in a macro cast the highest rank? GetMacroSpell tells which id it casts.
  -- A body that also casts other spells (a macroVars {var}, like NS + Healing Wave's {heal}) is not compared.
  local function castsOthers(key)
    local body = layout.macroBodies[layout.macroKind[key] or "help"] or ""
    for var in body:gmatch("{(%w+)}") do
      if var ~= "spell" then return true end
    end
    return false
  end
  for key, name in pairs(layout.macros) do
    local ok, idx = ns.Call("GetMacroIndexByName", name)
    local line = string.format("  macro %s (%s): %s", name, key, ok and tostring(idx) or "error")
    if ok and type(idx) == "number" and idx > 0 then
      local e = ns.Spells.Get(key)
      local _, bestId = ns.Spells.KnownRank(e)
      local okM, casts = ns.Call("GetMacroSpell", idx)
      line = line .. string.format("  casts %s  highest known %s  named rank %s", okM and tostring(casts) or "?",
        tostring(bestId), tostring(ns.char.macroRank[key] or "-"))
      local okI, _, _, curBody = ns.Call("GetMacroInfo", idx)
      if okI and curBody ~= ns.Layout.MacroBody(e) then
        bad(line .. "  (macro body is not up to date)")
        line = nil
      elseif okM and casts and bestId and casts ~= bestId and not castsOthers(key) then
        bad(line .. "  (macro does not cast the highest rank)")
        line = nil
      end
    end
    if line then add(line) end
  end
  -- Multi-spell macros (the paladin's opener): does one press cast every spell? Only the game can tell.
  for id, c in pairs(layout.combos) do
    local ok, idx = ns.Call("GetMacroIndexByName", c.macro)
    local line = string.format("  combo macro %s (%s): %s", c.macro, id, ok and tostring(idx) or "error")
    if ok and type(idx) == "number" and idx > 0 then
      local okI, _, _, curBody = ns.Call("GetMacroInfo", idx)
      if okI and curBody ~= ns.Layout.ComboBody(id) then
        bad(line .. "  (macro body is not up to date)")
        line = nil
      end
    end
    if line then add(line) end
  end
  -- Item macros: the body names the best item in the bags; the icon is a verify-in-game question when there is none.
  for _, kind in ipairs(ns.Items.Kinds()) do
    local d = ns.Items.Get(kind)
    local best = ns.Items.Best(kind)
    local body, icon = ns.Items.MacroBody(kind)
    local ok, idx = ns.Call("GetMacroIndexByName", d.macro)
    local line = string.format("  item macro %s: best in bags %s  index %s  wanted icon %s  body %s", d.macro,
      best and (best.name .. " " .. best.id) or "none", ok and tostring(idx) or "error", icon, (body:gsub("\n", " | ")))
    if ok and type(idx) == "number" and idx > 0 then
      local okI, _, curIcon, curBody = ns.Call("GetMacroInfo", idx)
      line = line .. string.format("  now icon %s", okI and tostring(curIcon) or "?")
      if okI and curBody ~= body then
        bad(line .. "  (macro body is not up to date)")
        line = nil
      end
    end
    if line then add(line) end
  end
  for _, kind in ipairs(ns.Items.Kinds()) do
    for _, item in ipairs(ns.Items.Get(kind).list) do
      local ok, name = ns.Call("C_Item.GetItemNameByID", item.id)
      if ok and name and name ~= item.name then bad(string.format("  item %d: data %q, client %q", item.id, item.name, name)) end
    end
  end
  local outdated = ns.Layout.OutdatedRanks()
  add(string.format("  bar buttons with an older rank: %d  (auto ranks %s)", #outdated, tostring(ns.settings.autoRanks)))
  for _, u in ipairs(outdated) do add(string.format("    slot %d %s id %d -> %d", u.slot, u.entry.name, u.old, u.new)) end
  for slot, id in pairs(ns.char.keepRank or {}) do add(string.format("    slot %d keeps id %d (undone upgrade)", slot, id)) end
  add("  undo records: " .. tostring(ns.char and ns.char.backups and #ns.char.backups or 0))

  add("")
  add("[Recent errors]")
  for _, e in ipairs(ns.errors) do add("  " .. e) end

  table.insert(out, 2, string.format("problems: %d", problems))
  return table.concat(out, "\n"), problems
end

ns.Command("verify", function()
  local text, problems = Verify.Run()
  ns.Print(string.format("verify: %d problem(s). Copy the window text and send it to the maintainer.", problems))
  ns.UI.CopyBox("ForeverSensei verify", ns.T("ui.verify.intro"), text)
end, true)
