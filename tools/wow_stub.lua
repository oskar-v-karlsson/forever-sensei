-- tools/wow_stub.lua: a small fake of the WoW client API, enough to load ForeverSensei and drive its windows
-- offline (tools/check.py). It simulates action slots, the cursor, key bindings, macros and settings so the
-- layout code can be exercised; it is not a model of real client behaviour (that is /sensei verify in-game).

STUB = {
  shown = {},      -- every text passed to SetText
  prints = {},
  timers = {},
  frames = {},
  level = 20,
  combat = false,
  known = {},      -- spell id → true
  names = {},      -- spell id → name
  levels = {},     -- spell id → level learned
  actions = {},    -- slot → { "spell"|"macro"|"item", id }
  cursor = nil,
  bindings = { ["Q"] = "STRAFELEFT", ["E"] = "STRAFERIGHT", ["1"] = "ACTIONBUTTON1", ["SHIFT-1"] = "ACTIONPAGE1" },
  macros = {},
  settings = { PROXY_SHOW_ACTIONBAR_2 = false, PROXY_SHOW_ACTIONBAR_3 = false, PROXY_SHOW_ACTIONBAR_4 = false },
  meta = {},
}

BINDING_NAME_STRAFELEFT = "Strafe Left"
BINDING_NAME_STRAFERIGHT = "Strafe Right"
BINDING_NAME_ACTIONBUTTON1 = "Action Button 1"
BINDING_NAME_ACTIONPAGE1 = "Action Page 1"

-- Frames ------------------------------------------------------------------------------------------
local Obj = {}
local methods = {}
Obj.__index = function(_, k)
  local m = methods[k]
  if m then return m end
  -- Unknown CamelCase names are client methods: accept and ignore. Lower-case names are addon fields: nil.
  if type(k) == "string" and k:match("^[A-Z]") then return function() end end
  return nil
end

local function new(kind, name, parent)
  local o = setmetatable({
    __kind = kind, __name = name, __parent = parent, __scripts = {}, __events = {}, __shown = true,
    __text = "", __w = 100, __h = 20, __checked = false, __enabled = true,
  }, Obj)
  table.insert(STUB.frames, o)
  return o
end
STUB.new = new

function methods:SetScript(n, f) self.__scripts[n] = f end
function methods:GetScript(n) return self.__scripts[n] end
function methods:HookScript(n, f)
  local old = self.__scripts[n]
  self.__scripts[n] = function(...) if old then old(...) end f(...) end
end
function methods:HasScript() return true end
function methods:RegisterEvent(e) self.__events[e] = true end
function methods:UnregisterEvent(e) self.__events[e] = nil end
function methods:UnregisterAllEvents() self.__events = {} end
function methods:Show() self.__shown = true; if self.__scripts.OnShow then self.__scripts.OnShow(self) end end
function methods:Hide() self.__shown = false; if self.__scripts.OnHide then self.__scripts.OnHide(self) end end
function methods:SetShown(v) if v then self:Show() else self:Hide() end end
function methods:IsShown() return self.__shown end
function methods:IsVisible() return self.__shown end
function methods:SetText(t)
  self.__text = t
  if t ~= nil then table.insert(STUB.shown, tostring(t)) end
end
function methods:SetFormattedText(fmt, ...) self:SetText(string.format(fmt, ...)) end
function methods:GetText() return self.__text end
function methods:SetWidth(w) self.__w = w end
function methods:SetHeight(h) self.__h = h end
function methods:SetSize(w, h) self.__w, self.__h = w, h end
function methods:GetWidth() return self.__w end
function methods:GetHeight() return self.__h end
function methods:GetSize() return self.__w, self.__h end
function methods:GetStringWidth() return #tostring(self.__text or "") * 6 end
function methods:GetStringHeight() return 14 * (1 + math.floor(#tostring(self.__text or "") * 6 / (self.__w > 0 and self.__w or 100))) end
function methods:GetUnboundedStringWidth() return self:GetStringWidth() end
function methods:GetLineHeight() return 14 end
function methods:GetNumLines() return 1 end
function methods:CreateFontString(name) return new("FontString", name, self) end
function methods:CreateTexture(name) return new("Texture", name, self) end
function methods:CreateMaskTexture(name) return new("MaskTexture", name, self) end
function methods:CreateAnimationGroup() return new("AnimationGroup", nil, self) end
function methods:CreateAnimation() return new("Animation", nil, self) end
function methods:CreateLine() return new("Line", nil, self) end
function methods:GetName() return self.__name end
function methods:GetParent() return self.__parent end
function methods:SetParent(p) self.__parent = p end
function methods:GetObjectType() return self.__kind end
function methods:IsObjectType(t) return self.__kind == t end
function methods:GetFont() return self.__font or "Fonts\\FRIZQT__.TTF", self.__fontSize or 12, "" end
function methods:SetFont(path, size) self.__font, self.__fontSize = path, size; return true end
function methods:GetFontObject() return nil end
function methods:GetFontString()
  self.__fs = self.__fs or new("FontString", nil, self)
  return self.__fs
end
function methods:GetChildren() end
function methods:GetRegions() end
function methods:GetNumPoints() return 0 end
function methods:GetVerticalScroll() return 0 end
function methods:GetVerticalScrollRange() return 0 end
function methods:GetScrollChild() return self.__child end
function methods:SetScrollChild(c) self.__child = c end
function methods:GetEffectiveScale() return 1 end
function methods:GetScale() return 1 end
function methods:GetLeft() return 0 end
function methods:GetRight() return 100 end
function methods:GetTop() return 100 end
function methods:GetBottom() return 0 end
function methods:GetCenter() return 50, 50 end
function methods:IsMouseOver() return false end
function methods:HasFocus() return false end
function methods:GetNumLetters() return #tostring(self.__text or "") end
function methods:IsEnabled() return self.__enabled end
function methods:Enable() self.__enabled = true end
function methods:Disable() self.__enabled = false end
function methods:SetEnabled(v) self.__enabled = not not v end
function methods:GetChecked() return self.__checked end
function methods:SetChecked(v) self.__checked = not not v end
function methods:GetID() return self.__id or 0 end
function methods:SetID(id) self.__id = id end
function methods:GetFrameLevel() return 1 end
function methods:GetFrameStrata() return "MEDIUM" end
function methods:GetValue() return 0 end
function methods:GetCursorPosition() return 0 end
function methods:Click(button)
  local f = self.__scripts.OnClick
  if f then f(self, button or "LeftButton", false) end
end
function methods:NumLines() return 0 end
function methods:IsOwned() return false end
function methods:GetTexture() return self.__texture end
function methods:SetTexture(t) self.__texture = t end

function CreateFrame(kind, name, parent, template)
  local o = new(kind, name, parent)
  o.__template = template
  if name then _G[name] = o end
  return o
end
function CreateFont(name) local o = new("Font", name); if name then _G[name] = o end; return o end

UIParent = new("Frame", "UIParent")
Minimap = new("Frame", "Minimap")
GameTooltip = new("GameTooltip", "GameTooltip")
DEFAULT_CHAT_FRAME = { AddMessage = function(_, m) table.insert(STUB.prints, tostring(m)) end }
SlashCmdList = {}
UISpecialFrames = {}
GameFontNormal, GameFontHighlight, GameFontNormalLarge, GameFontHighlightSmall = CreateFont(), CreateFont(), CreateFont(), CreateFont()
STANDARD_TEXT_FONT = "Fonts\\FRIZQT__.TTF"

function STUB.fire(event, ...)
  for _, f in ipairs(STUB.frames) do
    if f.__events[event] and f.__scripts.OnEvent then f.__scripts.OnEvent(f, event, ...) end
  end
end

-- Lua helpers the client adds ---------------------------------------------------------------------
date = os.date
time = os.time
GetTime = os.clock
tinsert, tremove, wipe = table.insert, table.remove, function(t) for k in pairs(t) do t[k] = nil end return t end
format, floor, ceil, max, min, abs = string.format, math.floor, math.ceil, math.max, math.min, math.abs
strtrim = function(s) return (s:gsub("^%s+", ""):gsub("%s+$", "")) end
strsplit = function(sep, s)
  local out = {}
  for part in (s .. sep):gmatch("(.-)" .. sep:gsub("%p", "%%%0")) do table.insert(out, part) end
  return unpack(out)
end
strlenutf8 = function(s) local _, n = s:gsub("[^\128-\191]", ""); return n end
hooksecurefunc = function() end
PlaySound = function() end
SOUNDKIT = setmetatable({}, { __index = function() return 0 end })

-- Timers run when the harness calls STUB.runTimers().
C_Timer = {}
function C_Timer.After(_, fn) table.insert(STUB.timers, fn) end
function C_Timer.NewTimer(_, fn)
  local h = { cancelled = false }
  function h:Cancel() self.cancelled = true end
  table.insert(STUB.timers, function() if not h.cancelled then fn(h) end end)
  return h
end
function C_Timer.NewTicker(s, fn, n)
  local h = C_Timer.NewTimer(s, fn)
  return h
end
function STUB.runTimers()
  for _ = 1, 5 do
    local list = STUB.timers
    if #list == 0 then return end
    STUB.timers = {}
    for _, fn in ipairs(list) do fn() end
  end
  STUB.timers = {}
end

-- Player ------------------------------------------------------------------------------------------
function UnitName() return "Hana" end
function GetRealmName() return "Test" end
function UnitClass() return "Shaman", "SHAMAN", 7 end
function UnitLevel() return STUB.level end
function UnitCharacterPoints() return STUB.unspent or 0 end
function InCombatLockdown() return STUB.combat end
function GetBuildInfo() return "1.60.1", "70862", "Nov 4 2026", 16001 end
function GetCursorPosition() return 0, 0 end
function GetActiveSpecGroup() return 1 end
WOW_PROJECT_ID = 1

C_AddOns = {}
function C_AddOns.GetAddOnMetadata(_, field) return STUB.meta[field] end
function C_AddOns.IsAddOnLoaded() return false end

-- Spells ------------------------------------------------------------------------------------------
local function spellId(x)
  if type(x) == "number" then return x end
  for id, n in pairs(STUB.names) do if n == x then return id end end
  return nil
end
C_Spell = {}
function C_Spell.GetSpellInfo(x)
  local id = spellId(x)
  if not id or not STUB.names[id] then return nil end
  return { name = STUB.names[id], iconID = 136000 + id % 1000, spellID = id, castTime = 1500, minRange = 0, maxRange = 40 }
end
function C_Spell.GetSpellName(x) local id = spellId(x); return id and STUB.names[id] end
function C_Spell.GetSpellTexture(x) local id = spellId(x); return id and STUB.names[id] and 136000 end
function C_Spell.GetSpellSubtext() return "Rank 1" end
function C_Spell.GetSpellLevelLearned(x) local id = spellId(x); return id and STUB.levels[id] or 0 end
function C_Spell.PickupSpell(x) local id = spellId(x); if id then STUB.cursor = { "spell", id } end end
C_SpellBook = {}
function C_SpellBook.IsSpellKnown(id) return STUB.known[id] == true end
function C_SpellBook.FindSpellBookSlotForSpell(id) if STUB.known[id] then return 1, 0 end return nil end
function IsPlayerSpell(id) return STUB.known[id] == true end
function IsSpellKnown(id) return STUB.known[id] == true end

-- Action bars, cursor, macros ------------------------------------------------------------------------
function GetActionInfo(slot)
  local a = STUB.actions[slot]
  if not a then return nil end
  return a[1], a[2], a[1] == "spell" and "spell" or nil
end
function GetActionText(slot)
  local a = STUB.actions[slot]
  if a and a[1] == "macro" then return STUB.macros[a[2]] and STUB.macros[a[2]].name end
  return nil
end
function PickupAction(slot)
  STUB.cursor = STUB.actions[slot]
  STUB.actions[slot] = nil
end
function PlaceAction(slot)
  local old = STUB.actions[slot]
  STUB.actions[slot] = STUB.cursor
  STUB.cursor = old
end
function ClearCursor() STUB.cursor = nil end
function GetCursorInfo() if STUB.cursor then return STUB.cursor[1], STUB.cursor[2] end end
function PickupMacro(x)
  local idx = type(x) == "number" and x or GetMacroIndexByName(x)
  if idx and idx > 0 then STUB.cursor = { "macro", idx } end
end
function C_Item_PickupItem(id) STUB.cursor = { "item", id } end
C_Item = { PickupItem = C_Item_PickupItem, GetItemNameByID = function(id) return "Item " .. id end }
function GetMacroIndexByName(name)
  for i, m in pairs(STUB.macros) do if m.name == name then return i end end
  return 0
end
function GetMacroInfo(i) local m = STUB.macros[i]; if m then return m.name, m.icon, m.body end end
function CreateMacro(name, icon, body)
  local i = 121
  while STUB.macros[i] do i = i + 1 end
  STUB.macros[i] = { name = name, icon = icon, body = body }
  return i
end
function EditMacro(i, name, icon, body)
  STUB.macros[i] = { name = name, icon = icon, body = body }
  return i
end

-- Bindings and settings -----------------------------------------------------------------------------
function GetBindingAction(key) return STUB.bindings[key] or "" end
function SetBinding(key, action) STUB.bindings[key] = action; return true end
function SaveBindings() end
function GetCurrentBindingSet() return 2 end
Settings = {}
function Settings.GetValue(k) return STUB.settings[k] end
function Settings.SetValue(k, v) STUB.settings[k] = v end

-- Talents. With STUB.traits = nil the tree is unreadable (the addon falls back to the level-based plan). With
-- STUB.traits = { nodes = { { spell = id, rank = n, max = m } ... }, unspent = n } a one-tree C_Traits is faked.
-- Real reading is verify-in-game (/sensei verify).
C_ClassTalents = { GetActiveConfigID = function() return STUB.traits and 1 or nil end }
C_Traits = {}
function C_Traits.GetConfigInfo() return { treeIDs = { 7 } } end
function C_Traits.GetTreeNodes()
  local t = {}
  for i in ipairs(STUB.traits.nodes) do t[i] = i end
  return t
end
function C_Traits.GetNodeInfo(_, i)
  local n = STUB.traits.nodes[i]
  return { entryIDs = { i }, currentRank = n.rank, maxRanks = n.max, activeEntry = n.rank > 0 and { entryID = i } or nil }
end
function C_Traits.GetEntryInfo(_, e) return { definitionID = e } end
function C_Traits.GetDefinitionInfo(d) return { spellID = STUB.traits.nodes[d].spell } end
function C_Traits.GetTreeCurrencyInfo() return { { quantity = STUB.traits.unspent } } end
PlayerSpellsUtil = { ToggleClassTalentOrSpecFrame = function() end }
function ToggleTalentFrame() end
