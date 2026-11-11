-- Modules/Language.lua: the language window on a fresh install. Two big buttons, each labelled in its own language.
-- Until one is pressed nothing else starts (ns.Start in Core/Init.lua). The choice is account-wide and kept.
local _, ns = ...
local Picker = {}
ns.LanguagePicker = Picker
local UI = ns.UI

local win
local function build()
  win = UI.Window("ForeverSenseiLanguage", 380, 200,
    ns.Raw("ui.settings.language", "ja") .. " / " .. ns.Raw("ui.settings.language", "en"))
  win:SetFrameStrata("FULLSCREEN_DIALOG")
  win.ja = UI.Text(win, 13)
  win.ja:SetPoint("TOPLEFT", 16, -40)
  win.ja:SetWidth(348)
  win.ja:SetText(ns.Raw("ui.language.intro", "ja"))
  win.en = UI.Text(win, 12, "grey")
  win.en:SetPoint("TOPLEFT", win.ja, "BOTTOMLEFT", 0, -6)
  win.en:SetWidth(348)
  win.en:SetText(ns.Raw("ui.language.intro", "en"))
  local function choose(language)
    win:Hide()
    ns.SetLanguage(language)
  end
  win.jaButton = UI.Button(win, ns.Raw("ui.language.name", "ja"), 164, 40, function() choose("ja") end)
  win.jaButton:SetPoint("BOTTOMRIGHT", win, "BOTTOM", -6, 16)
  win.enButton = UI.Button(win, ns.Raw("ui.language.name", "en"), 164, 40, function() choose("en") end)
  win.enButton:SetPoint("BOTTOMLEFT", win, "BOTTOM", 6, 16)
  for _, b in ipairs({ win.jaButton, win.enButton }) do
    local fs = b:GetFontString()
    if fs then ns.Font.Apply(fs, 16) end
  end
  UI.AutoFit(win, function(self) self:SetHeight(40 + UI.H(self.ja) + 6 + UI.H(self.en) + 16 + 40 + 16) end)
end

function Picker.Show()
  if ns.settings.languageChosen then return end
  if not win then build() end
  win:ClearAllPoints()
  win:SetPoint("CENTER")
  win:Show()
  UI.Refit(win)
end

function Picker.IsShown()
  return win ~= nil and win:IsShown()
end

ns.OnLanguage(function() if win then win:Hide() end end)
