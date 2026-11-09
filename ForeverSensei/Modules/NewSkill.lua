-- Modules/NewSkill.lua: a card for every newly learned skill, a toast for new ranks, and a trainer list on level-up.
-- Detection compares the known spells with the saved list on SPELLS_CHANGED (also triggered by
-- LEARNED_SPELL_IN_SKILL_LINE), so it does not depend on one event's payload.
local _, ns = ...
local NewSkill = {}
ns.NewSkill = NewSkill
local Spells = ns.Spells
local UI = ns.UI

local queue = {}
local card, trainer
local hiddenForCombat = {}

local function charRanks()
  ns.char.ranks = ns.char.ranks or {}
  return ns.char.ranks
end

local function section(parent, labelId, width)
  local label = UI.Text(parent, 12, "gold")
  label:SetText(ns.T(labelId))
  local text = UI.Text(parent, 13)
  text:SetWidth(width)
  text:SetPoint("TOPLEFT", label, "BOTTOMLEFT", 0, -3)
  return label, text
end

local function buildCard()
  card = UI.Window("ForeverSenseiCard", 460, 380, ns.T("ui.card.title"))
  card:ClearAllPoints()
  card:SetPoint("RIGHT", UIParent, "RIGHT", -120, 40)
  card.icon = UI.SpellIcon(card, 48)
  card.icon:SetPoint("TOPLEFT", 16, -40)
  card.name = UI.Text(card, 17, "gold")
  card.name:SetPoint("TOPLEFT", card.icon, "TOPRIGHT", 10, -2)
  card.tags = UI.Text(card, 12)
  card.tags:SetPoint("TOPLEFT", card.name, "BOTTOMLEFT", 0, -6)
  card.tags:SetWidth(360)

  card.whatLabel, card.what = section(card, "ui.card.what", 400)
  card.whatLabel:SetPoint("TOPLEFT", card.icon, "BOTTOMLEFT", 0, -12)
  card.whatReport = UI.ReportButton(card, function() return "spell." .. card.entry.key .. ".what" end)
  card.whatReport:SetPoint("TOPRIGHT", card, "TOPRIGHT", -14, 0)

  card.whenLabel, card.when = section(card, "ui.card.when", 400)
  card.whenReport = UI.ReportButton(card, function() return "spell." .. card.entry.key .. ".when" end)

  card.whereLabel, card.where = section(card, "ui.card.where", 400)

  card.place = UI.Button(card, ns.T("ui.btn.place"), 130, 24, function()
    local e = card.entry
    ns.char.postponed[e.key] = nil
    ns.Layout.PlaceOne(e)
  end)
  card.place:SetPoint("BOTTOMLEFT", 16, 14)
  card.later = UI.Button(card, ns.T("ui.btn.later"), 130, 24, function()
    ns.char.postponed[card.entry.key] = true
    card:Hide()
    NewSkill.Next()
  end)
  card.later:SetPoint("LEFT", card.place, "RIGHT", 8, 0)
  card.guide = UI.Button(card, ns.T("ui.btn.guide"), 150, 24, function()
    if ns.Guide then ns.Guide.Open("skills") end
  end)
  card.guide:SetPoint("LEFT", card.later, "RIGHT", 8, 0)
  card.more = UI.Text(card, 11, "grey")
  card.more:SetPoint("BOTTOMRIGHT", card.guide, "TOPRIGHT", 0, 6)
  card.close:HookScript("OnClick", function()
    if card.entry then ns.char.postponed[card.entry.key] = nil end
    NewSkill.Next()
  end)
end

local function layoutCard()
  -- Report buttons sit at the right edge of their label row.
  card.whatReport:ClearAllPoints()
  card.whatReport:SetPoint("RIGHT", card, "RIGHT", -14, 0)
  card.whatReport:SetPoint("TOP", card.whatLabel, "TOP", 0, 2)
  card.whenLabel:ClearAllPoints()
  card.whenLabel:SetPoint("TOPLEFT", card.what, "BOTTOMLEFT", 0, -10)
  card.whenReport:ClearAllPoints()
  card.whenReport:SetPoint("RIGHT", card, "RIGHT", -14, 0)
  card.whenReport:SetPoint("TOP", card.whenLabel, "TOP", 0, 2)
  card.whereLabel:ClearAllPoints()
  card.whereLabel:SetPoint("TOPLEFT", card.when, "BOTTOMLEFT", 0, -10)
  local h = 40 + 48 + 12 + 3 * 20 + card.what:GetStringHeight() + card.when:GetStringHeight()
    + card.where:GetStringHeight() + 20 + 60
  card:SetHeight(math.max(300, h))
end

function NewSkill.ShowCard(entry)
  if not card then buildCard() end
  card.entry = entry
  card.icon:SetSpell(entry)
  card.name:SetText(entry.name)
  local c = UI.COLORS[entry.role]
  local color = string.format("|cff%02x%02x%02x", c[1] * 255, c[2] * 255, c[3] * 255)
  card.tags:SetText(color .. ns.T("ui.role." .. entry.role) .. "|r   " .. ns.T("ui.use." .. entry.use)
    .. "   " .. ns.T("ui.card.level", { level = entry.level }))
  card.what:SetText(ns.T("spell." .. entry.key .. ".what"))
  card.when:SetText(ns.T("spell." .. entry.key .. ".when"))
  card.where:SetText(Spells.WhereText(entry))
  local hasSlot = Spells.LayoutSlot(entry) ~= nil
  if card.place.SetEnabled then card.place:SetEnabled(hasSlot and Spells.IsKnown(entry)) end
  card.more:SetText(#queue > 0 and ns.T("ui.card.more", { n = #queue }) or "")
  layoutCard()
  if ns.InCombat() then
    hiddenForCombat.card = true
  else
    card:Show()
  end
end

function NewSkill.Next()
  if card and card:IsShown() then card:Hide() end
  local e = table.remove(queue, 1)
  if e then NewSkill.ShowCard(e) end
end

local function enqueue(entry)
  for _, q in ipairs(queue) do
    if q.key == entry.key then return end
  end
  table.insert(queue, entry)
end

local function showQueued()
  if not ns.settings.showCards then return end
  if card and card:IsShown() then
    card.more:SetText(#queue > 0 and ns.T("ui.card.more", { n = #queue }) or "")
    return
  end
  NewSkill.Next()
end

-- Compare known spells and ranks with the saved state.
function NewSkill.Scan()
  if not ns.char or not ns.IsShaman() then return end
  local known, ranks = ns.char.known, charRanks()
  local first = not ns.char.initialised
  local newRanks = {}
  for _, e in ipairs(Spells.List()) do
    if Spells.IsKnown(e) then
      local id = Spells.CurrentID(e)
      if not known[e.key] then
        known[e.key] = true
        if not first then enqueue(e) end
      elseif ranks[e.key] and ranks[e.key] ~= id then
        table.insert(newRanks, e)
      end
      ranks[e.key] = id
    end
  end
  if first then
    ns.char.initialised = true
    ns.UI.Toast(ns.T("ui.welcome"), 15, ns.T("ui.btn.guide"), function() ns.Guide.Open() end)
    return
  end
  showQueued()
  if #newRanks > 0 then NewSkill.RankToast(newRanks) end
end

function NewSkill.RankToast(list)
  local names, outdated = {}, {}
  for _, e in ipairs(list) do
    local ok, sub = ns.Call("C_Spell.GetSpellSubtext", Spells.CurrentID(e))
    local rank = ok and sub and sub ~= "" and (" (" .. sub .. ")") or ""
    table.insert(names, e.name .. rank)
    if #ns.Layout.OldRankSlots(e) > 0 then table.insert(outdated, e) end
  end
  local text = ns.T("ui.rank.learned", { names = table.concat(names, ", ") })
  if #outdated > 0 then
    ns.UI.Toast(text .. "\n" .. ns.T("ui.rank.old"), 20, ns.T("ui.btn.update"), function()
      for _, e in ipairs(outdated) do ns.Layout.UpdateRank(e) end
    end)
  else
    ns.UI.Toast(text, 8)
  end
end

-- Skills she can learn at her level but does not know yet (talents excluded).
function NewSkill.Trainable(level)
  local list = {}
  for _, e in ipairs(Spells.List()) do
    if not e.talent and e.level <= level and not Spells.IsKnown(e) then table.insert(list, e) end
  end
  table.sort(list, function(a, b)
    if a.level ~= b.level then return a.level < b.level end
    return a.name < b.name
  end)
  return list
end

local function buildTrainer()
  trainer = UI.Window("ForeverSenseiTrainer", 400, 200, ns.T("ui.trainer.title"))
  trainer:ClearAllPoints()
  trainer:SetPoint("LEFT", UIParent, "LEFT", 120, 60)
  trainer.intro = UI.Text(trainer, 12)
  trainer.intro:SetPoint("TOPLEFT", 16, -40)
  trainer.intro:SetWidth(368)
  trainer.report = UI.ReportButton(trainer, "ui.trainer.intro")
  trainer.report:SetPoint("TOPRIGHT", -36, -10)
  trainer.rows = {}
end

function NewSkill.ShowTrainer(level)
  local list = NewSkill.Trainable(level or Spells.PlayerLevel())
  if #list == 0 then
    if not level then ns.UI.Toast(ns.T("ui.trainer.none")) end
    return
  end
  if not trainer then buildTrainer() end
  trainer.intro:SetText(ns.T("ui.trainer.intro"))
  local top = 48 + trainer.intro:GetStringHeight()
  for i, e in ipairs(list) do
    local row = trainer.rows[i]
    if not row then
      row = CreateFrame("Frame", nil, trainer)
      row:SetSize(368, 24)
      row.icon = UI.SpellIcon(row, 22)
      row.icon:SetPoint("LEFT")
      row.text = UI.Text(row, 12)
      row.text:SetPoint("LEFT", row.icon, "RIGHT", 6, 0)
      row.text:SetWidth(330)
      trainer.rows[i] = row
    end
    row:ClearAllPoints()
    row:SetPoint("TOPLEFT", 16, -(top + (i - 1) * 26))
    row.icon:SetSpell(e)
    row.text:SetText(string.format("Lv%d  %s  |cffaaaaaa%s|r", e.level, e.name, ns.T("ui.role." .. e.role)))
    row:Show()
  end
  for i = #list + 1, #trainer.rows do trainer.rows[i]:Hide() end
  trainer:SetHeight(top + #list * 26 + 20)
  if ns.InCombat() then hiddenForCombat.trainer = true else trainer:Show() end
end

-- Events.
local scanPending = false
local function scheduleScan()
  if scanPending then return end
  scanPending = true
  C_Timer.After(1, function()
    scanPending = false
    NewSkill.Scan()
  end)
end

ns.OnLogin(function()
  if not ns.IsShaman() then return end
  for key in pairs(ns.char.postponed) do
    local e = Spells.Get(key)
    if e then enqueue(e) end
  end
  C_Timer.After(3, function()
    NewSkill.Scan()
    if ns.char.initialised then showQueued() end
  end)
end)
ns.On("SPELLS_CHANGED", function() if ns.ready then scheduleScan() end end)
ns.On("LEARNED_SPELL_IN_SKILL_LINE", function() if ns.ready then scheduleScan() end end)
ns.On("PLAYER_LEVEL_UP", function(level)
  if not ns.ready or not ns.IsShaman() then return end
  ns.char.lastLevel = level
  C_Timer.After(2, function() NewSkill.ShowTrainer(level) end)
end)

ns.On("PLAYER_REGEN_DISABLED", function()
  if card and card:IsShown() then
    hiddenForCombat.card = true
    card:Hide()
  end
  if trainer and trainer:IsShown() then
    hiddenForCombat.trainer = true
    trainer:Hide()
  end
end)
ns.On("PLAYER_REGEN_ENABLED", function()
  if hiddenForCombat.card and card then card:Show() end
  if hiddenForCombat.trainer and trainer then trainer:Show() end
  hiddenForCombat = {}
  if not (card and card:IsShown()) and #queue > 0 then showQueued() end
end)

ns.Command("card", function(rest)
  local e = Spells.Find(rest)
  if not e then
    ns.Print("unknown spell: " .. tostring(rest) .. " (use the English name, e.g. /sensei card Chain Heal)")
    return
  end
  NewSkill.ShowCard(e)
end)
ns.Command("trainer", function() NewSkill.ShowTrainer() end)
