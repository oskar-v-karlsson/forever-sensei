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
  "PickupMacro", "GetMacroIndexByName", "GetMacroInfo", "CreateMacro", "EditMacro",
  "C_Item.PickupItem", "C_Item.GetItemNameByID",
  "GetBindingAction", "SetBinding", "SaveBindings", "GetCurrentBindingSet",
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
  add("[Talents]")
  local ranks, unspent, source, maxRanks = ns.Talents.Read()
  if not ranks then
    bad("talent tree could not be read through C_Traits (advice follows the level only)")
  else
    add(string.format("  read via %s, unspent=%s", tostring(source), tostring(unspent)))
    for _, t in ipairs(ns.ClassData.SHAMAN.talents.list) do
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
  local layout = ns.ClassData.SHAMAN.layout
  for _, slot in ipairs(layout.slots) do
    local cur = ns.Layout.Current(slot.slot)
    local okB, action = false, nil
    if slot.key then okB, action = ns.Call("GetBindingAction", slot.key) end
    add(string.format("  slot %3d %-24s now: %-28s %s", slot.slot, slot.spell, ns.Layout.Label(cur),
      slot.key and (slot.key .. "=" .. tostring(okB and action or "?")) or ""))
  end
  for _, bar in ipairs(layout.bars) do
    if bar.setting then
      local ok, v = ns.Call("Settings.GetValue", bar.setting)
      add(string.format("  %s %s = %s", bar.id, bar.setting, ok and tostring(v) or ("error " .. tostring(v))))
    end
  end
  for key, name in pairs(layout.macros) do
    local ok, idx = ns.Call("GetMacroIndexByName", name)
    add(string.format("  macro %s (%s): %s", name, key, ok and tostring(idx) or "error"))
  end
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
end)
