-- Modules/Talents.lua: which talent to take next (Mobalytics Restoration path), with a Japanese reason.
-- Talent ranks are read from the C_Traits tree (Forever 1.60.1 uses one class tree). If that fails, the advice
-- falls back to the planned point for the player's level. /sensei verify reports which way worked.
local _, ns = ...
local Talents = {}
ns.Talents = Talents
local UI = ns.UI

local function data() return ns.spec.talents end

local function configID()
  local ok, id = ns.Call("C_ClassTalents.GetActiveConfigID")
  if ok and id then return id end
  local ok2, group = ns.Call("GetActiveSpecGroup")
  local ok3, cfg = ns.Call("C_SpecializationInfo.GetCombatConfigIDForSpecGroup", ok2 and group or 1)
  if ok3 and cfg then return cfg end
  return nil
end

-- → { [talent name] = rank }, unspent points or nil, source ("traits"|nil)
function Talents.Read()
  local cfg = configID()
  if not cfg then return nil end
  local ok, cfgInfo = ns.Call("C_Traits.GetConfigInfo", cfg)
  if not ok or type(cfgInfo) ~= "table" or not cfgInfo.treeIDs or not cfgInfo.treeIDs[1] then return nil end
  local tree = cfgInfo.treeIDs[1]
  local ok2, nodes = ns.Call("C_Traits.GetTreeNodes", tree)
  if not ok2 or type(nodes) ~= "table" then return nil end
  local ranks, maxRanks = {}, {}
  for _, nodeID in ipairs(nodes) do
    local ok3, node = ns.Call("C_Traits.GetNodeInfo", cfg, nodeID)
    if ok3 and type(node) == "table" and node.entryIDs then
      for _, entryID in ipairs(node.entryIDs) do
        local ok4, entry = ns.Call("C_Traits.GetEntryInfo", cfg, entryID)
        if ok4 and type(entry) == "table" and entry.definitionID then
          local ok5, def = ns.Call("C_Traits.GetDefinitionInfo", entry.definitionID)
          local spellID = ok5 and type(def) == "table" and (def.spellID or def.overriddenSpellID)
          local name = spellID and ns.Spells.Name(spellID)
          if name then
            local active = node.activeEntry and node.activeEntry.entryID == entryID
            local rank = (active or #node.entryIDs == 1) and (node.currentRank or node.activeRank or 0) or 0
            ranks[name] = math.max(ranks[name] or 0, rank)
            if node.maxRanks then maxRanks[name] = node.maxRanks end
          end
        end
      end
    end
  end
  local unspent
  local ok6, currencies = ns.Call("C_Traits.GetTreeCurrencyInfo", cfg, tree, false)
  if ok6 and type(currencies) == "table" and currencies[1] then unspent = currencies[1].quantity end
  return ranks, unspent, "traits", maxRanks
end

function Talents.Spent(ranks)
  local n = 0
  for _, r in pairs(ranks) do n = n + r end
  return n
end

-- Talent points earned at a level (one per level from 10).
function Talents.PointsAt(level)
  return math.max(0, level - 9)
end

-- → state { ranks, unspent, readable, next = order step or nil, offPlan = { names } }
function Talents.State()
  local level = ns.Spells.PlayerLevel()
  local ranks, unspent = Talents.Read()
  local state = { readable = ranks ~= nil, level = level }
  local T = data()
  if ranks then
    state.ranks = ranks
    if unspent == nil then
      local ok, pts = ns.Call("UnitCharacterPoints", "player")
      unspent = ok and pts or math.max(0, Talents.PointsAt(level) - Talents.Spent(ranks))
    end
    state.unspent = unspent
    for _, step in ipairs(T.order) do
      local t = T.byKey[step.key]
      if (ranks[t.name] or 0) < step.rank then
        state.next = step
        break
      end
    end
    -- Points in talents the path never takes.
    local planned = {}
    for _, t in ipairs(T.list) do planned[t.name] = true end
    state.offPlan = {}
    for name, r in pairs(ranks) do
      if r > 0 and not planned[name] then table.insert(state.offPlan, name) end
    end
    table.sort(state.offPlan)
  else
    -- Cannot read the tree: follow the planned point for the player's level.
    state.unspent = nil
    local n = Talents.PointsAt(level)
    state.next = T.order[n] or nil
    if n == 0 then state.next = T.order[1] end
  end
  return state
end

function Talents.StepText(step)
  local t = data().byKey[step.key]
  return ns.T("ui.talent.step", { name = t.name, tree = t.tree, row = t.row, rank = step.rank, max = t.max, level = step.level })
end

function Talents.OpenTalentFrame()
  if ns.InCombat() then return end
  local ok = ns.Call("PlayerSpellsUtil.ToggleClassTalentOrSpecFrame")
  if not ok then ns.Call("ToggleTalentFrame") end
end

-- Hint window.
local hint
local function buildHint()
  hint = UI.Window("ForeverSenseiTalentHint", 420, 230, ns.T("ui.talent.title"))
  hint:ClearAllPoints()
  hint:SetPoint("TOP", UIParent, "TOP", 0, -220)
  hint.head = UI.Text(hint, 13)
  hint.head:SetPoint("TOPLEFT", 16, -40)
  hint.head:SetWidth(388)
  hint.step = UI.Text(hint, 15, "gold")
  hint.step:SetWidth(388)
  hint.why = UI.Text(hint, 13)
  hint.why:SetWidth(388)
  hint.report = UI.ReportButton(hint, function() return hint.stepKey and ("talent." .. hint.stepKey .. ".why") end)
  hint.extra = UI.Text(hint, 11, "grey")
  hint.extra:SetWidth(388)
  hint.open = UI.Button(hint, ns.T("ui.btn.talents"), 150, 24, function() Talents.OpenTalentFrame() end)
  hint.open:SetPoint("BOTTOMLEFT", 16, 14)
  hint.all = UI.Button(hint, ns.T("ui.btn.order"), 150, 24, function()
    if ns.Guide then ns.Guide.Open("talents") end
  end)
  hint.all:SetPoint("LEFT", hint.open, "RIGHT", 8, 0)
  hint.step:SetPoint("TOPLEFT", hint.head, "BOTTOMLEFT", 0, -10)
  hint.why:SetPoint("TOPLEFT", hint.step, "BOTTOMLEFT", 0, -6)
  hint.extra:SetPoint("TOPLEFT", hint.why, "BOTTOMLEFT", 0, -8)
  hint.report:SetPoint("TOPRIGHT", hint, "TOPRIGHT", -36, -10)
  UI.AutoFit(hint, function(self)
    -- title area + texts and their gaps + button row
    self:SetHeight(40 + UI.H(self.head) + 10 + UI.H(self.step) + 6 + UI.H(self.why) + 8 + UI.H(self.extra) + 52)
  end)
end

function Talents.ShowHint(force)
  if not ns.Active() then return end
  local s = Talents.State()
  if not force and (not s.readable or not s.unspent or s.unspent <= 0) then
    if hint then hint:Hide() end
    return
  end
  if not hint then buildHint() end
  if s.readable then
    hint.head:SetText(ns.T("ui.talent.points", { n = s.unspent or 0 }))
  else
    hint.head:SetText(ns.T("ui.talent.unreadable"))
  end
  if s.next then
    hint.stepKey = s.next.key
    hint.step:SetText(Talents.StepText(s.next))
    hint.why:SetText(ns.T("talent." .. s.next.key .. ".why"))
    hint.report:Show()
  else
    hint.stepKey = nil
    hint.step:SetText(ns.T("ui.talent.done"))
    hint.why:SetText("")
    hint.report:Hide()
  end
  if s.offPlan and #s.offPlan > 0 then
    hint.extra:SetText(ns.T("ui.talent.offplan", { names = table.concat(s.offPlan, ", ") }))
  else
    hint.extra:SetText("")
  end
  if not ns.InCombat() then
    hint:Show()
    UI.Refit(hint)
  end
end

local function refresh()
  if not ns.ready or not ns.settings.showTalentHints then return end
  if hint and hint:IsShown() then
    Talents.ShowHint()
  end
end

ns.OnLogin(function()
  C_Timer.After(5, function()
    if ns.settings.showTalentHints then Talents.ShowHint() end
  end)
end)
ns.On("PLAYER_LEVEL_UP", function()
  if not ns.ready or not ns.settings.showTalentHints then return end
  C_Timer.After(3, function() Talents.ShowHint() end)
end)
ns.On("TRAIT_CONFIG_UPDATED", refresh)
ns.On("PLAYER_TALENT_UPDATE", refresh)
ns.On("PLAYER_REGEN_DISABLED", function() if hint then hint:Hide() end end)

ns.Command("talents", function() Talents.ShowHint(true) end, true)
