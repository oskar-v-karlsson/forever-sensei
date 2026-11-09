-- Core/Font.lua: Japanese font for every FontString the addon creates.
-- Adapted from WoW Forever Japanese (UI/Font.lua, GPL-2.0): the client refuses an addon font until a visible
-- FontString asks for the file, so a nearly transparent probe character is shown and refused fonts are retried.
local _, ns = ...
local Font = {}
ns.Font = Font

Font.OWN = "Interface\\AddOns\\" .. ns.ADDON .. "\\Fonts\\ipagui.ttf"
Font.WFJ = "Interface\\AddOns\\WoWForeverJapanese\\Fonts\\ipagui.ttf"
Font.CLIENT = "Fonts\\FRIZQT__.TTF"
Font.PATH = Font.OWN

local pending = setmetatable({}, { __mode = "k" })

local function choosePath()
  local isLoaded = C_AddOns and C_AddOns.IsAddOnLoaded
  if isLoaded then
    local ok, loaded = pcall(isLoaded, "WoWForeverJapanese")
    if ok and loaded then return Font.WFJ end
  end
  return Font.OWN
end

-- Give fs the Japanese face. A refusal is remembered and retried. → the SetFont result
function Font.Apply(fs, size, flags)
  size, flags = size or 12, flags or ""
  local ok = fs:SetFont(Font.PATH, size, flags)
  if ok == false then
    -- keep something readable for the Latin parts until the Japanese face loads
    fs:SetFont(Font.CLIENT, size, flags)
    pending[fs] = { size, flags }
  else
    pending[fs] = nil
  end
  return ok
end

local function retry()
  local n = 0
  for fs, f in pairs(pending) do
    if fs:SetFont(Font.PATH, f[1], f[2]) == false then
      n = n + 1
    else
      pending[fs] = nil
      -- the text was laid out with the fallback face; set it again so wrapping uses the new glyphs
      local t = fs:GetText()
      if t then fs:SetText(t) end
    end
  end
  return n
end

local probe
local function startProbe()
  if probe then return end
  probe = CreateFrame("Frame", nil, UIParent)
  probe:SetSize(16, 16)
  probe:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", 0, 0)
  local fs = probe:CreateFontString(nil, "OVERLAY")
  fs:SetPoint("CENTER")
  fs:SetFont(Font.CLIENT, 8, "")
  fs:SetTextColor(1, 1, 1, 0.02)
  fs:SetText("あ")
  Font.Apply(fs, 8, "")
  probe.fs = fs
  probe:Show()
end

local function stopProbe()
  if not probe then return end
  probe:Hide()
  pending[probe.fs] = nil
end

local tries = 0
local function tick()
  tries = tries + 1
  if retry() == 0 then
    stopProbe()
    return
  end
  if tries < 60 then C_Timer.After(1, tick) end
end

ns.On("ADDON_LOADED", function(name)
  if name == ns.ADDON then
    Font.PATH = choosePath()
    startProbe()
  end
end)

ns.On("PLAYER_ENTERING_WORLD", function()
  tries = 0
  C_Timer.After(1, tick)
end)
