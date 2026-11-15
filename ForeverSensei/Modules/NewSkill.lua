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

local WIDTH = 460
local TEXT_W = WIDTH - 32

-- Label with a report button right after it, and the text below.
local function section(parent, labelId, reportId)
  local label = UI.Text(parent, 12, "gold")
  label:SetWidth(TEXT_W - 66)
  label:SetText(ns.T(labelId))
  local text = UI.Text(parent, 13)
  text:SetWidth(TEXT_W)
  text:SetPoint("TOPLEFT", label, "BOTTOMLEFT", 0, -3)
  local report
  if reportId then
    report = UI.ReportButton(parent, function()
      if card.entry.lower then return card.entry.texts[reportId] end
      return "spell." .. card.entry.key .. "." .. reportId
    end)
    report:SetPoint("TOPLEFT", label, "TOPRIGHT", 8, 2)
  end
  return label, text, report
end

-- Height follows the texts: icon/name block, three sections, placement line, "more" line, button row.
local function fitCard(self)
  local head = math.max(48, 2 + UI.H(self.name) + 6 + UI.H(self.tags))
  self.whatLabel:ClearAllPoints()
  self.whatLabel:SetPoint("TOPLEFT", 16, -(40 + head + 12))
  local h = 40 + head + 12
  h = h + UI.H(self.whatLabel) + 3 + UI.H(self.what) + 10
  h = h + UI.H(self.whenLabel) + 3 + UI.H(self.when) + 10
  h = h + UI.H(self.whereLabel) + 3 + UI.H(self.where)
  local status = UI.H(self.status)
  if status > 0 then h = h + 6 + status end
  local more = UI.H(self.more)
  h = h + 12 + (more > 0 and more + 6 or 0) + 44
  self:SetHeight(h)
end

local function buildCard()
  card = UI.Window("ForeverSenseiCard", WIDTH, 380, ns.T("ui.card.title"))
  -- Above the guide window (DIALOG), below the report and confirm dialogs (FULLSCREEN_DIALOG).
  card:SetFrameStrata("FULLSCREEN")
  card:ClearAllPoints()
  card:SetPoint("RIGHT", UIParent, "RIGHT", -120, 40)
  card.icon = UI.SpellIcon(card, 48)
  card.icon:SetPoint("TOPLEFT", 16, -40)
  card.name = UI.Text(card, 17, "gold")
  card.name:SetPoint("TOPLEFT", card.icon, "TOPRIGHT", 10, -2)
  card.name:SetWidth(WIDTH - 90)
  card.tags = UI.Text(card, 12)
  card.tags:SetPoint("TOPLEFT", card.name, "BOTTOMLEFT", 0, -6)
  card.tags:SetWidth(WIDTH - 90)

  card.whatLabel, card.what, card.whatReport = section(card, "ui.card.what", "what")
  card.whenLabel, card.when, card.whenReport = section(card, "ui.card.when", "when")
  card.whenLabel:SetPoint("TOPLEFT", card.what, "BOTTOMLEFT", 0, -10)
  card.whereLabel, card.where = section(card, "ui.card.where")
  card.whereLabel:SetPoint("TOPLEFT", card.when, "BOTTOMLEFT", 0, -10)
  card.status = UI.Text(card, 12)
  card.status:SetWidth(TEXT_W)
  card.status:SetPoint("TOPLEFT", card.where, "BOTTOMLEFT", 0, -6)

  card.place = UI.Button(card, ns.T("ui.btn.place"), 130, 24, function()
    local e = card.entry
    ns.char.postponed[e.key] = nil
    if e.lower then ns.Layout.PlaceLower(e.lower) else ns.Layout.PlaceOne(e) end
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
  card.more = UI.Text(card, 11, "grey")
  card.more:SetWidth(TEXT_W)
  card.more:SetJustifyH("RIGHT")
  card.more:SetPoint("BOTTOMRIGHT", card, "BOTTOMRIGHT", -16, 44)
  card.close:HookScript("OnClick", function()
    if card.entry and not card.fromList then ns.char.postponed[card.entry.key] = nil end
    NewSkill.Next()
  end)
  UI.AutoFit(card, fitCard)
end

-- A heal's lower-rank key (L.lower) as a card entry: key "~healing_wave", the heal itself in .base, and the text ids
-- its report buttons use.
local lowerEntries = {}
function NewSkill.LowerEntry(key)
  local base = Spells.Get(key)
  if not base or not ns.spec.layout.lower[key] then return nil end
  if not lowerEntries[key] then
    lowerEntries[key] = { key = "~" .. key, lower = key, base = base,
      texts = { what = ns.spec.layout.lower[key].what, when = ns.spec.layout.lower[key].when } }
  end
  return lowerEntries[key]
end

-- The level from which a lower-rank key has something to cast (its second rank, or minLevel if later).
local function lowerLevel(key)
  local lo = ns.spec.layout.lower[key]
  return math.max(lo.minLevel or 1, lo.levels and lo.levels[2] or 1)
end

local function lowerLine(key)
  local s = ns.spec.layout.byLower[key]
  return ns.T(ns.spec.layout.lower[key].what, { key = s and s.key and ns.KeyLabel(s.key) or Spells.SlotText(s) })
end

-- Parts that change when bars change: icon rank, placement line, place button, queue count.
local function fillState()
  local e = card.entry
  local placed
  if e.lower then
    card.icon:SetSpell(e.base)
    local _, id = ns.Layout.LowerRank(e.lower)
    if id then card.icon.spellID = id end
    card.where:SetText(Spells.SlotText(ns.spec.layout.byLower[e.lower]))
    if ns.Layout.LowerRank(e.lower) then placed = ns.Layout.LowerPlaced(e.lower) end
  else
    card.icon:SetSpell(e)
    local where = Spells.WhereText(e)
    if ns.spec.layout.lower[e.key] then where = where .. "\n" .. lowerLine(e.key) end
    card.where:SetText(where)
    placed = ns.Layout.IsPlaced(e)
  end
  if card.place.SetEnabled then card.place:SetEnabled(placed ~= nil) end
  if placed == true then
    card.status:SetText(ns.T("ui.card.placed"))
    card.status:SetTextColor(unpack(UI.COLORS.heal))
  elseif placed == false then
    card.status:SetText(ns.T("ui.card.notplaced"))
    card.status:SetTextColor(unpack(UI.COLORS.gold))
  else
    card.status:SetText("")
  end
  card.more:SetText(#queue > 0 and ns.T("ui.card.more", { n = #queue }) or "")
end

-- fromList: opened from the skill list or /sensei card to look at a skill again. It does not touch the queue of
-- new skills or the "later" list; a new-skill card that was open comes back when this one is closed.
function NewSkill.ShowCard(entry, fromList)
  if not card then buildCard() end
  fromList = fromList and true or false
  if fromList and card:IsShown() and card.entry and not card.fromList and card.entry.key ~= entry.key then
    table.insert(queue, 1, card.entry)
  end
  card.entry, card.fromList = entry, fromList
  card.title:SetText(ns.T(fromList and "ui.card.view" or "ui.card.title"))
  local base = entry.base or entry
  card.name:SetText(entry.lower and ns.T("ui.lower.card", { name = base.name }) or entry.name)
  local c = UI.COLORS[base.role]
  local color = string.format("|cff%02x%02x%02x", c[1] * 255, c[2] * 255, c[3] * 255)
  card.tags:SetText(color .. ns.T("ui.role." .. base.role) .. "|r   " .. ns.T("ui.use." .. base.use)
    .. "   " .. ns.T("ui.card.level", { level = entry.lower and lowerLevel(entry.lower) or entry.level }))
  if entry.lower then
    card.what:SetText(lowerLine(entry.lower))
    card.when:SetText(ns.T(entry.texts.when))
  else
    card.what:SetText(ns.T("spell." .. entry.key .. ".what"))
    card.when:SetText(ns.T("spell." .. entry.key .. ".when"))
  end
  card.later:SetShown(not fromList)
  card.guide:ClearAllPoints()
  card.guide:SetPoint("LEFT", fromList and card.place or card.later, "RIGHT", 8, 0)
  fillState()
  if ns.InCombat() then
    hiddenForCombat.card = true
  else
    card:Show()
    if card.Raise then card:Raise() end
    UI.Refit(card)
  end
end

function NewSkill.RefreshCard()
  if not card or not card.entry or not card:IsShown() then return end
  fillState()
  UI.Refit(card)
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
    NewSkill.RefreshCard()
    return
  end
  NewSkill.Next()
end

-- Compare known spells and ranks with the saved state. atLogin: also catch up on old ranks still on the bars.
function NewSkill.Scan(atLogin)
  if not ns.char or not ns.Active() then return end
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
    NewSkill.CheckLower(true)
    ns.char.initialised = true
    ns.UI.Toast(ns.T("ui.welcome"), 15, ns.T("ui.btn.guide"), function() ns.Guide.Open() end)
    return
  end
  NewSkill.CheckLower(true)
  showQueued()
  if #newRanks > 0 or atLogin then ns.Layout.ApplyNewRanks(newRanks) end
end

-- The first time a heal's lower-rank key has something to cast (Healing Wave at 10, Chain Heal at 46): a card that
-- offers to place it, unless it is in its slot already. A new character only notes it (its first full apply places
-- it); while the one-time layout notice is pending the key is left for that notice. noShow: only queue the card.
function NewSkill.CheckLower(noShow)
  if not ns.char or not ns.Active() then return end
  local layout = ns.spec.layout
  ns.char.lowerSeen = ns.char.lowerSeen or {}
  local keys = {}
  for key in pairs(layout.lower) do
    if not ns.char.lowerSeen[key] and ns.Layout.LowerRank(key) then table.insert(keys, key) end
  end
  table.sort(keys, function(a, b) return layout.byLower[a].slot < layout.byLower[b].slot end)
  local any = false
  for _, key in ipairs(keys) do
    if not ns.char.initialised or ns.Layout.LowerPlaced(key) then
      ns.char.lowerSeen[key] = true
    elseif (ns.char.layoutVersion or 1) >= layout.version then
      ns.char.lowerSeen[key] = true
      enqueue(NewSkill.LowerEntry(key))
      any = true
    end
  end
  if any and not noShow then showQueued() end
end

-- Skills the player can learn at their level but does not know yet (talents and racials excluded).
function NewSkill.Trainable(level)
  local list = {}
  for _, e in ipairs(Spells.List()) do
    if not e.talent and not e.races and e.level <= level and not Spells.IsKnown(e) then table.insert(list, e) end
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
  trainer.count = 0
  UI.AutoFit(trainer, function(self)
    local y = 40 + UI.H(self.intro) + 8
    for i = 1, self.count do
      local row = self.rows[i]
      local h = math.max(24, UI.H(row.text) + 6)
      row:SetHeight(h)
      row:ClearAllPoints()
      row:SetPoint("TOPLEFT", 16, -y)
      y = y + h + 2
    end
    self:SetHeight(y + 14)
  end)
end

function NewSkill.ShowTrainer(level)
  local list = NewSkill.Trainable(level or Spells.PlayerLevel())
  if #list == 0 then
    if not level then ns.UI.Toast(ns.T("ui.trainer.none")) end
    return
  end
  if not trainer then buildTrainer() end
  trainer.level = level
  trainer.intro:SetText(ns.T("ui.trainer.intro"))
  for i, e in ipairs(list) do
    local row = trainer.rows[i]
    if not row then
      row = CreateFrame("Frame", nil, trainer)
      row:SetSize(368, 24)
      row.icon = UI.SpellIcon(row, 22)
      row.icon:SetPoint("TOPLEFT")
      row.text = UI.Text(row, 12)
      row.text:SetPoint("TOPLEFT", row.icon, "TOPRIGHT", 6, -4)
      row.text:SetWidth(340)
      trainer.rows[i] = row
    end
    row.icon:SetSpell(e)
    row.text:SetText(string.format("Lv%d  %s  |cffaaaaaa%s|r", e.level, e.name, ns.T("ui.role." .. e.role)))
    row:Show()
  end
  for i = #list + 1, #trainer.rows do trainer.rows[i]:Hide() end
  trainer.count = #list
  if ns.InCombat() then
    hiddenForCombat.trainer = true
  else
    trainer:Show()
    UI.Refit(trainer)
  end
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

-- Drop "later" skills that are in their slot now (placed by Apply full layout or by hand): nothing left to do there.
function NewSkill.PrunePostponed()
  if not ns.char or not ns.char.postponed then return 0 end
  local n = 0
  for key in pairs(ns.char.postponed) do
    local lowerKey = key:match("^~(.+)$")
    local e = lowerKey and NewSkill.LowerEntry(lowerKey) or Spells.Get(key)
    local placed = e and (e.lower and ns.Layout.LowerPlaced(e.lower) or not e.lower and ns.Layout.IsPlaced(e) == true)
    if not e or placed then
      ns.char.postponed[key] = nil
    else
      n = n + 1
    end
  end
  return n
end

function NewSkill.ShowPostponed()
  NewSkill.PrunePostponed()
  local list = {}
  for key in pairs(ns.char.postponed) do
    local lowerKey = key:match("^~(.+)$")
    table.insert(list, lowerKey and NewSkill.LowerEntry(lowerKey) or Spells.Get(key))
  end
  local function level(e) return e.lower and lowerLevel(e.lower) or e.level end
  table.sort(list, function(a, b) return level(a) < level(b) or (level(a) == level(b) and a.key < b.key) end)
  for _, e in ipairs(list) do enqueue(e) end
  if card and card:IsShown() then NewSkill.RefreshCard() else NewSkill.Next() end
end

-- At login no card opens for a skill already seen: "later" skills only get a toast with a button to look at them.
-- Cards at login are only for skills learned while the addon was not running.
ns.OnLogin(function()
  if not ns.Active() then return end
  C_Timer.After(3, function()
    NewSkill.Scan(true)
    if not ns.char.initialised or not ns.settings.showCards then return end
    local n = NewSkill.PrunePostponed()
    if n > 0 then
      C_Timer.After(10, function()
        if ns.InCombat() or (card and card:IsShown()) then return end
        ns.UI.Toast(ns.T("ui.card.postponed", { n = n }), 15, ns.T("ui.btn.look"), NewSkill.ShowPostponed)
      end)
    end
  end)
end)
ns.On("SPELLS_CHANGED", function() if ns.ready then scheduleScan() end end)
ns.On("LEARNED_SPELL_IN_SKILL_LINE", function() if ns.ready then scheduleScan() end end)
ns.On("PLAYER_LEVEL_UP", function(level)
  if not ns.ready or not ns.Active() then return end
  ns.char.lastLevel = level
  C_Timer.After(2, function() NewSkill.ShowTrainer(level) end)
end)

-- Language change: open windows are built again in the new language.
ns.OnLanguage(function()
  if card then
    local shown, entry, fromList = card:IsShown() or hiddenForCombat.card, card.entry, card.fromList
    UI.Discard(card)
    card, hiddenForCombat.card = nil, nil
    if shown and entry then NewSkill.ShowCard(entry, fromList) end
  end
  if trainer then
    local shown, level = trainer:IsShown() or hiddenForCombat.trainer, trainer.level
    UI.Discard(trainer)
    trainer, hiddenForCombat.trainer = nil, nil
    if shown then NewSkill.ShowTrainer(level) end
  end
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
  NewSkill.ShowCard(e, true)
end, true)
ns.Command("trainer", function() NewSkill.ShowTrainer() end, true)
