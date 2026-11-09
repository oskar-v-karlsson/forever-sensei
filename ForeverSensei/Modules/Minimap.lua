-- Modules/Minimap.lua: minimap button and the addon compartment entry (both: left click guide, right click send reports).
local _, ns = ...
local Minimap_ = {}
ns.Minimap = Minimap_
local UI = ns.UI

local button
local RADIUS = 105

local function hintText()
  return ns.T("ui.minimap.hint", { n = ns.db and #ns.db.reports or 0 })
end

local function click(mouseButton)
  if mouseButton == "RightButton" then
    ns.Feedback.Send()
  else
    ns.Guide.Toggle()
  end
end

local function place()
  local a = math.rad(ns.settings.minimapAngle or 200)
  button:ClearAllPoints()
  button:SetPoint("CENTER", Minimap, "CENTER", math.cos(a) * RADIUS, math.sin(a) * RADIUS)
end

local function build()
  button = CreateFrame("Button", "ForeverSenseiMinimapButton", Minimap)
  button:SetSize(31, 31)
  button:SetFrameStrata("MEDIUM")
  button:SetFrameLevel(8)
  button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
  button:RegisterForDrag("LeftButton")
  button:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
  local bg = button:CreateTexture(nil, "BACKGROUND")
  bg:SetTexture("Interface\\Minimap\\UI-Minimap-Background")
  bg:SetSize(20, 20)
  bg:SetPoint("TOPLEFT", 7, -5)
  local icon = button:CreateTexture(nil, "ARTWORK")
  icon:SetTexture("Interface\\Icons\\Spell_Nature_MagicImmunity")
  icon:SetSize(20, 20)
  icon:SetPoint("TOPLEFT", 7, -5)
  local border = button:CreateTexture(nil, "OVERLAY")
  border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
  border:SetSize(53, 53)
  border:SetPoint("TOPLEFT")
  button:SetScript("OnClick", function(_, b) click(b) end)
  button:SetScript("OnEnter", function(self) UI.ShowHint(self, hintText()) end)
  button:SetScript("OnLeave", UI.HideHint)
  button:SetScript("OnDragStart", function(self)
    self:SetScript("OnUpdate", function()
      local mx, my = Minimap:GetCenter()
      local cx, cy = GetCursorPosition()
      local scale = Minimap:GetEffectiveScale()
      ns.settings.minimapAngle = math.deg(math.atan2(cy / scale - my, cx / scale - mx))
      place()
    end)
  end)
  button:SetScript("OnDragStop", function(self) self:SetScript("OnUpdate", nil) end)
end

function Minimap_.Update()
  if not ns.settings.minimap then
    if button then button:Hide() end
    return
  end
  if not button then build() end
  place()
  button:Show()
end

ns.OnLogin(function() Minimap_.Update() end)

-- Addon compartment (## AddonCompartmentFunc* in the TOC).
function ForeverSensei_OnCompartmentClick(_, mouseButton)
  click(mouseButton)
end

function ForeverSensei_OnCompartmentEnter(_, frame)
  if frame then UI.ShowHint(frame, hintText()) end
end

function ForeverSensei_OnCompartmentLeave()
  UI.HideHint()
end
