-- Modules/Feedback.lua: translation reports. She marks a text, saves a reason and an optional better Japanese,
-- then sends all pending reports at once by copying them from a pre-selected box into a chat with him.
-- The text format is parsed by tools/reports.py; keep both in sync.
local _, ns = ...
local Feedback = {}
ns.Feedback = Feedback

Feedback.REASONS = { "wrong", "unnatural", "typo", "unclear", "other" }
Feedback.DEFAULT_REASON = "unnatural"

-- Real line breaks become the two characters \n so every field stays on one line.
local function oneLine(s)
  s = tostring(s or "")
  s = s:gsub("\r\n", "\n"):gsub("\r", "\n")
  s = s:gsub("\n", "\\n")
  return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end
Feedback.OneLine = oneLine

-- reports: list of { id, reason, now, suggestion, note }. → text
function Feedback.Format(reports, version)
  local lines = {}
  table.insert(lines, string.format("[ForeverSensei v%s 報告 %d件]", version or ns.VERSION, #reports))
  for i, r in ipairs(reports) do
    table.insert(lines, string.format("#%d %s | %s", i, r.id, ns.Raw("ui.reason." .. (r.reason or Feedback.DEFAULT_REASON), "ja")))
    table.insert(lines, "今: " .. oneLine(r.now))
    if r.suggestion and oneLine(r.suggestion) ~= "" then table.insert(lines, "案: " .. oneLine(r.suggestion)) end
    if r.note and oneLine(r.note) ~= "" then table.insert(lines, "メモ: " .. oneLine(r.note)) end
  end
  return table.concat(lines, "\n")
end

function Feedback.Pending()
  return ns.db and ns.db.reports or {}
end

function Feedback.Save(id, reason, suggestion, note)
  local list = ns.db.reports
  for i = #list, 1, -1 do
    if list[i].id == id then table.remove(list, i) end
  end
  table.insert(list, {
    id = id,
    reason = reason or Feedback.DEFAULT_REASON,
    now = ns.Raw(id, "ja"),
    suggestion = suggestion,
    note = note,
    version = ns.VERSION,
    time = time and time() or 0,
  })
  ns.db.review[id] = "reported"
  if ns.Guide and ns.Guide.RefreshFooter then ns.Guide.RefreshFooter() end
end

local function existing(id)
  for _, r in ipairs(ns.db.reports) do
    if r.id == id then return r end
  end
  return nil
end

-- Report dialog.
local dlg
local fitDialog, layoutDialog
local function build()
  dlg = ns.UI.Window("ForeverSenseiReport", 540, 470, ns.T("ui.report.title"))
  dlg:SetFrameStrata("FULLSCREEN_DIALOG")
  local UI = ns.UI
  dlg.idText = UI.Text(dlg, 10, "grey")
  dlg.idText:SetPoint("TOPLEFT", 16, -36)
  dlg.idText:SetWidth(508)

  local nowLabel = UI.Text(dlg, 12, "gold")
  nowLabel:SetPoint("TOPLEFT", dlg.idText, "BOTTOMLEFT", 0, -6)
  nowLabel:SetWidth(508)
  nowLabel:SetText(ns.T("ui.report.now"))
  dlg.nowLabel = nowLabel
  dlg.now = UI.Text(dlg, 13)
  dlg.now:SetPoint("TOPLEFT", nowLabel, "BOTTOMLEFT", 0, -4)
  dlg.now:SetWidth(508)

  dlg.enLabel = UI.Text(dlg, 11, "gold")
  dlg.enLabel:SetWidth(508)
  dlg.enLabel:SetText(ns.T("ui.report.english"))
  dlg.en = UI.Text(dlg, 11, "grey")
  dlg.en:SetWidth(508)

  dlg.reasonLabel = UI.Text(dlg, 12, "gold")
  dlg.reasonLabel:SetWidth(508)
  dlg.reasonLabel:SetText(ns.T("ui.report.reason"))
  dlg.reasonButtons = {}
  for i, code in ipairs(Feedback.REASONS) do
    local b = UI.Button(dlg, "", 100, 22, function()
      dlg.reason = code
      for _, other in ipairs(dlg.reasonButtons) do other:Refresh() end
      layoutDialog()
    end)
    b.code = code
    function b:Refresh()
      local mark = (dlg.reason == self.code) and "● " or "○ "
      self:SetLabel(mark .. ns.T("ui.reason." .. self.code))
    end
    dlg.reasonButtons[i] = b
  end

  dlg.suggestLabel = UI.Text(dlg, 12, "gold")
  dlg.suggestLabel:SetWidth(508)
  dlg.suggestLabel:SetText(ns.T("ui.report.suggestion"))
  dlg.suggest = UI.Input(dlg, 508, 60, true)
  dlg.noteLabel = UI.Text(dlg, 12, "gold")
  dlg.noteLabel:SetWidth(508)
  dlg.noteLabel:SetText(ns.T("ui.report.note"))
  dlg.note = UI.Input(dlg, 508, 44, true)

  dlg.save = UI.Button(dlg, ns.T("ui.btn.save"), 140, 24, function()
    Feedback.Save(dlg.id, dlg.reason, dlg.suggest.edit:GetText(), dlg.note.edit:GetText())
    dlg:Hide()
    ns.UI.Toast(ns.T("ui.report.saved", { n = #ns.db.reports }))
  end)
  dlg.save:SetPoint("BOTTOMRIGHT", dlg, "BOTTOM", -6, 14)
  dlg.cancel = UI.Button(dlg, ns.T("ui.btn.cancel"), 140, 24, function() dlg:Hide() end)
  dlg.cancel:SetPoint("BOTTOMLEFT", dlg, "BOTTOM", 6, 14)
  UI.AutoFit(dlg, fitDialog)
end

function layoutDialog()
  dlg.enLabel:ClearAllPoints()
  dlg.enLabel:SetPoint("TOPLEFT", dlg.now, "BOTTOMLEFT", 0, -10)
  dlg.en:ClearAllPoints()
  dlg.en:SetPoint("TOPLEFT", dlg.enLabel, "BOTTOMLEFT", 0, -3)
  dlg.reasonLabel:ClearAllPoints()
  dlg.reasonLabel:SetPoint("TOPLEFT", dlg.en, "BOTTOMLEFT", 0, -12)
  -- Each reason button is as wide as its label; they flow into a new row when the line is full.
  local x, row = 0, 0
  for _, b in ipairs(dlg.reasonButtons) do
    local fs = b:GetFontString()
    local w = math.max(80, math.ceil((fs and fs:GetStringWidth() or 60) + 20))
    b:SetWidth(w)
    if x > 0 and x + w > 508 then x, row = 0, row + 1 end
    b:ClearAllPoints()
    b:SetPoint("TOPLEFT", dlg.reasonLabel, "BOTTOMLEFT", x, -4 - row * 26)
    x = x + w + 4
  end
  dlg.reasonRows = row + 1
  dlg.suggestLabel:ClearAllPoints()
  dlg.suggestLabel:SetPoint("TOPLEFT", dlg.reasonLabel, "BOTTOMLEFT", 0, -4 - dlg.reasonRows * 26 - 8)
  dlg.suggest:ClearAllPoints()
  dlg.suggest:SetPoint("TOPLEFT", dlg.suggestLabel, "BOTTOMLEFT", 0, -4)
  dlg.noteLabel:ClearAllPoints()
  dlg.noteLabel:SetPoint("TOPLEFT", dlg.suggest, "BOTTOMLEFT", 0, -10)
  dlg.note:ClearAllPoints()
  dlg.note:SetPoint("TOPLEFT", dlg.noteLabel, "BOTTOMLEFT", 0, -4)
end

function fitDialog(self)
  local H = ns.UI.H
  local h = 36 + H(self.idText) + 6 + H(self.nowLabel) + 4 + H(self.now) + 10 + H(self.enLabel) + 3 + H(self.en)
    + 12 + H(self.reasonLabel) + 4 + (self.reasonRows or 1) * 26 + 8 + H(self.suggestLabel) + 4 + 60 + 10 + H(self.noteLabel) + 4 + 44
    + 14 + 38
  self:SetHeight(h)
end

function Feedback.Open(id)
  if not dlg then build() end
  local old = existing(id)
  dlg.id = id
  dlg.idText:SetText(id)
  dlg.now:SetText(ns.Raw(id, "ja"))
  dlg.en:SetText(ns.Raw(id, "en"))
  dlg.reason = old and old.reason or Feedback.DEFAULT_REASON
  for _, b in ipairs(dlg.reasonButtons) do b:Refresh() end
  dlg.suggest.edit:SetText(old and old.suggestion or "")
  dlg.note.edit:SetText(old and old.note or "")
  layoutDialog()
  dlg:Show()
  ns.UI.Refit(dlg)
end

-- Send window: every pending report, already selected for Ctrl+C.
function Feedback.Send()
  local list = Feedback.Pending()
  if #list == 0 then
    ns.UI.Toast(ns.T("ui.report.none"))
    return
  end
  ns.UI.CopyBox(ns.T("ui.send.title"), ns.T("ui.send.intro"), Feedback.Format(list), ns.T("ui.send.done"), function()
    ns.UI.Confirm(ns.T("ui.send.confirm", { n = #list }), ns.T("ui.send.done"), function()
      ns.db.sentCount = (ns.db.sentCount or 0) + #ns.db.reports
      ns.db.reports = {}
      if ns.Guide and ns.Guide.RefreshFooter then ns.Guide.RefreshFooter() end
      ns.UI.Toast(ns.T("ui.send.cleared"))
    end)
  end)
end

ns.Command("report", function() Feedback.Send() end)
