-- Modules/UI.lua: shared widgets. Every FontString gets the Japanese face (client fonts lack Japanese glyphs),
-- and Japanese hover text uses our own hint frame instead of GameTooltip for the same reason.
local _, ns = ...
local UI = {}
ns.UI = UI

local BACKDROP = {
  bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
  edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
  tile = true, tileSize = 16, edgeSize = 16,
  insets = { left = 4, right = 4, top = 4, bottom = 4 },
}

UI.COLORS = {
  heal = { 0.35, 0.95, 0.45 },
  damage = { 1.0, 0.45, 0.3 },
  support = { 0.45, 0.75, 1.0 },
  grey = { 0.65, 0.65, 0.65 },
  gold = { 1.0, 0.82, 0.0 },
  white = { 1, 1, 1 },
}

function UI.Text(parent, size, color, flags)
  local fs = parent:CreateFontString(nil, "OVERLAY")
  ns.Font.Apply(fs, size or 12, flags)
  fs:SetJustifyH("LEFT")
  fs:SetJustifyV("TOP")
  if fs.SetWordWrap then fs:SetWordWrap(true) end
  local c = UI.COLORS[color or "white"] or UI.COLORS.white
  fs:SetTextColor(c[1], c[2], c[3])
  return fs
end

function UI.Backdrop(f, alpha)
  if f.SetBackdrop then
    f:SetBackdrop(BACKDROP)
    f:SetBackdropColor(0.04, 0.06, 0.1, alpha or 0.95)
    f:SetBackdropBorderColor(0.4, 0.6, 0.9, 1)
  end
end

function UI.Window(name, width, height, title)
  local f = CreateFrame("Frame", name, UIParent, "BackdropTemplate")
  f:SetSize(width, height)
  f:SetPoint("CENTER")
  f:SetFrameStrata("DIALOG")
  f:SetToplevel(true)
  UI.Backdrop(f)
  f:EnableMouse(true)
  f:SetMovable(true)
  f:SetClampedToScreen(true)
  f:RegisterForDrag("LeftButton")
  f:SetScript("OnDragStart", f.StartMoving)
  f:SetScript("OnDragStop", f.StopMovingOrSizing)
  f.title = UI.Text(f, 15, "gold")
  f.title:SetPoint("TOPLEFT", 14, -12)
  f.title:SetPoint("RIGHT", f, "RIGHT", -36, 0)
  f.title:SetText(title or "")
  local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
  close:SetPoint("TOPRIGHT", -3, -3)
  f.close = close
  if name and UISpecialFrames then table.insert(UISpecialFrames, name) end
  f:Hide()
  return f
end

function UI.Button(parent, text, width, height, onClick)
  local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
  b:SetSize(width or 100, height or 24)
  function b:SetLabel(t)
    self:SetText(t)
    local fs = self:GetFontString()
    if fs then ns.Font.Apply(fs, 12) end
  end
  b:SetLabel(text or "")
  if onClick then b:SetScript("OnClick", onClick) end
  return b
end

-- Our own hover hint (Japanese-capable).
local hint
function UI.ShowHint(owner, text)
  if not hint then
    hint = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    hint:SetFrameStrata("TOOLTIP")
    UI.Backdrop(hint, 0.97)
    hint.text = UI.Text(hint, 12)
    hint.text:SetPoint("TOPLEFT", 8, -8)
    hint.text:SetWidth(260)
  end
  hint.text:SetText(text)
  hint:SetSize(276, hint.text:GetStringHeight() + 16)
  hint:ClearAllPoints()
  hint:SetPoint("BOTTOMLEFT", owner, "TOPRIGHT", 4, 4)
  hint:Show()
end

function UI.HideHint()
  if hint then hint:Hide() end
end

function UI.AddHint(frame, textOrFn)
  frame:HookScript("OnEnter", function(self)
    local t = type(textOrFn) == "function" and textOrFn(self) or textOrFn
    if t then UI.ShowHint(self, t) end
  end)
  frame:HookScript("OnLeave", UI.HideHint)
end

-- Spell icon: hover shows the game's own tooltip (translated by WoW Forever Japanese when installed).
function UI.SpellIcon(parent, size)
  local b = CreateFrame("Button", nil, parent)
  b:SetSize(size, size)
  b.tex = b:CreateTexture(nil, "ARTWORK")
  b.tex:SetAllPoints()
  b.tex:SetTexCoord(0.07, 0.93, 0.07, 0.93)
  function b:SetSpell(entry)
    self.entry = entry
    local id = entry and ns.Spells.CurrentID(entry)
    self.spellID = id
    local tex = id and ns.Spells.Texture(entry)
    self.tex:SetTexture(tex or 134400)
    if self.tex.SetDesaturated then self.tex:SetDesaturated(entry ~= nil and not ns.Spells.IsKnown(entry)) end
  end
  b:SetScript("OnEnter", function(self)
    if not self.spellID then return end
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    local ok = pcall(GameTooltip.SetSpellByID, GameTooltip, self.spellID)
    if not ok then GameTooltip:SetText(self.entry and self.entry.name or "?") end
    GameTooltip:Show()
  end)
  b:SetScript("OnLeave", function() GameTooltip:Hide() end)
  return b
end

-- Small "報告" button that opens the translation report dialog for a text id.
function UI.ReportButton(parent, idOrFn)
  local b = UI.Button(parent, ns.T("ui.report.button"), 46, 18, function(self)
    local id = type(idOrFn) == "function" and idOrFn(self) or idOrFn
    if id then ns.Feedback.Open(id) end
  end)
  local fs = b:GetFontString()
  if fs then ns.Font.Apply(fs, 10) end
  UI.AddHint(b, ns.T("ui.report.hint"))
  return b
end

-- Toast: short message at the top of the screen, optional single action button.
local toast
function UI.Toast(text, seconds, buttonText, onButton)
  if not toast then
    toast = CreateFrame("Frame", "ForeverSenseiToast", UIParent, "BackdropTemplate")
    toast:SetFrameStrata("HIGH")
    toast:SetPoint("TOP", UIParent, "TOP", 0, -140)
    UI.Backdrop(toast, 0.9)
    toast.text = UI.Text(toast, 13)
    toast.text:SetPoint("TOPLEFT", 12, -10)
    toast.text:SetWidth(336)
    toast.button = UI.Button(toast, "", 120, 22)
    toast.button:SetPoint("BOTTOMRIGHT", -10, 8)
    toast:EnableMouse(true)
    toast:SetScript("OnMouseUp", function(self) self:Hide() end)
  end
  toast.text:SetText(text)
  local h = toast.text:GetStringHeight() + 22
  if buttonText then
    toast.button:SetLabel(buttonText)
    toast.button:SetScript("OnClick", function()
      toast:Hide()
      onButton()
    end)
    toast.button:Show()
    h = h + 28
  else
    toast.button:Hide()
  end
  toast:SetSize(360, h)
  toast:Show()
  if toast.timer then toast.timer:Cancel() end
  toast.timer = C_Timer.NewTimer(seconds or 8, function() toast:Hide() end)
end

-- Yes/no dialog in our font.
local confirm
function UI.Confirm(text, yesText, onYes)
  if not confirm then
    confirm = UI.Window("ForeverSenseiConfirm", 420, 160, ns.T("ui.confirm.title"))
    confirm:SetFrameStrata("FULLSCREEN_DIALOG")
    confirm.text = UI.Text(confirm, 13)
    confirm.text:SetPoint("TOPLEFT", 16, -40)
    confirm.text:SetWidth(388)
    confirm.yes = UI.Button(confirm, "", 140, 24)
    confirm.yes:SetPoint("BOTTOMRIGHT", confirm, "BOTTOM", -6, 14)
    confirm.no = UI.Button(confirm, ns.T("ui.btn.cancel"), 140, 24, function() confirm:Hide() end)
    confirm.no:SetPoint("BOTTOMLEFT", confirm, "BOTTOM", 6, 14)
  end
  confirm.text:SetText(text)
  confirm:SetHeight(math.max(140, confirm.text:GetStringHeight() + 96))
  confirm.yes:SetLabel(yesText or ns.T("ui.btn.ok"))
  confirm.yes:SetScript("OnClick", function()
    confirm:Hide()
    onYes()
  end)
  confirm:Show()
end

-- Vertical scroll area. → scrollFrame, content (set content height after filling)
function UI.Scroll(parent, width, height)
  local sf = CreateFrame("ScrollFrame", nil, parent, "UIPanelScrollFrameTemplate")
  sf:SetSize(width, height)
  local content = CreateFrame("Frame", nil, sf)
  content:SetSize(width, height)
  sf:SetScrollChild(content)
  return sf, content
end

-- Window with a pre-selected read-only text box, for copying reports and verify output.
local copy
function UI.CopyBox(title, intro, text, extraButtonText, onExtra)
  if not copy then
    copy = UI.Window("ForeverSenseiCopy", 560, 420, "")
    copy.intro = UI.Text(copy, 13)
    copy.intro:SetPoint("TOPLEFT", 16, -40)
    copy.intro:SetWidth(528)
    local sf = CreateFrame("ScrollFrame", nil, copy, "UIPanelScrollFrameTemplate")
    sf:SetPoint("TOPLEFT", 16, -96)
    sf:SetPoint("BOTTOMRIGHT", -36, 50)
    local eb = CreateFrame("EditBox", nil, sf)
    eb:SetMultiLine(true)
    eb:SetAutoFocus(false)
    eb:SetWidth(500)
    ns.Font.Apply(eb, 12)
    eb:SetScript("OnEscapePressed", function() copy:Hide() end)
    eb:SetScript("OnTextChanged", function(self, userInput)
      if userInput then
        self:SetText(copy.value or "")
        self:HighlightText()
      end
    end)
    eb:SetScript("OnMouseUp", function(self) self:HighlightText() end)
    sf:SetScrollChild(eb)
    copy.edit = eb
    copy.extra = UI.Button(copy, "", 170, 24)
    copy.extra:SetPoint("BOTTOMLEFT", 16, 14)
    copy.closeButton = UI.Button(copy, ns.T("ui.btn.close"), 120, 24, function() copy:Hide() end)
    copy.closeButton:SetPoint("BOTTOMRIGHT", -16, 14)
  end
  copy.title:SetText(title)
  copy.intro:SetText(intro or "")
  copy.value = text
  copy.edit:SetText(text)
  if extraButtonText then
    copy.extra:SetLabel(extraButtonText)
    copy.extra:SetScript("OnClick", function()
      copy:Hide()
      onExtra()
    end)
    copy.extra:Show()
  else
    copy.extra:Hide()
  end
  copy:Show()
  copy.edit:SetFocus()
  copy.edit:HighlightText()
  return copy
end

-- Input box (single or multi line) with a border.
function UI.Input(parent, width, height, multiLine)
  local holder = CreateFrame("Frame", nil, parent, "BackdropTemplate")
  holder:SetSize(width, height)
  UI.Backdrop(holder, 0.6)
  local eb = CreateFrame("EditBox", nil, holder)
  eb:SetPoint("TOPLEFT", 6, -5)
  eb:SetPoint("BOTTOMRIGHT", -6, 5)
  eb:SetAutoFocus(false)
  eb:SetMultiLine(multiLine and true or false)
  ns.Font.Apply(eb, 12)
  eb:SetTextColor(1, 1, 1)
  eb:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
  if not multiLine then eb:SetScript("OnEnterPressed", function(self) self:ClearFocus() end) end
  holder:EnableMouse(true)
  holder:SetScript("OnMouseDown", function() eb:SetFocus() end)
  holder.edit = eb
  return holder
end
