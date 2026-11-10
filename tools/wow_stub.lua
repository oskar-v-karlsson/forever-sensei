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
  bags = {},       -- item id → count
  itemLevels = {}, -- item id → required level the client reports (C_Item.GetItemInfo)
  settings = { PROXY_SHOW_ACTIONBAR_2 = false, PROXY_SHOW_ACTIONBAR_3 = false, PROXY_SHOW_ACTIONBAR_4 = false,
    PROXY_SHOW_ACTIONBAR_5 = false },
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
  if self.__fs then self.__fs.__text = t end  -- a button's label lives in its font string
  if t ~= nil then table.insert(STUB.shown, tostring(t)) end
end
function methods:SetFormattedText(fmt, ...) self:SetText(string.format(fmt, ...)) end
function methods:GetText() return self.__text end
function methods:SetWidth(w) self.__w, self.__wset = w, true end
function methods:SetHeight(h) self.__h, self.__hset = h, true end
function methods:SetSize(w, h) self.__w, self.__h, self.__wset, self.__hset = w, h, true, true end
function methods:SetNonSpaceWrap(v) self.__nsw = v end
function methods:SetWordWrap(v) self.__wrap = v end
function methods:SetJustifyH(v) self.__justifyH = v end
-- Anchors are recorded so STUB.checkLayout can work out where things are.
function methods:SetPoint(point, a, b, c, d)
  local rel, relPoint, x, y
  if type(a) == "number" or a == nil then
    rel, relPoint, x, y = self.__parent, point, a or 0, b or 0
  else
    if type(a) == "string" then a = _G[a] end
    rel = a
    if type(b) == "number" then relPoint, x, y = point, b, c or 0 else relPoint, x, y = b or point, c or 0, d or 0 end
  end
  self.__points = self.__points or {}
  table.insert(self.__points, { point, rel, relPoint, x, y })
end
function methods:SetAllPoints(rel)
  rel = rel or self.__parent
  self.__points = { { "TOPLEFT", rel, "TOPLEFT", 0, 0 }, { "BOTTOMRIGHT", rel, "BOTTOMRIGHT", 0, 0 } }
end
function methods:ClearAllPoints() self.__points = nil end
function methods:GetWidth() return self.__w end
function methods:GetHeight() return self.__h end
function methods:GetSize() return self.__w, self.__h end
-- Text size estimate: Latin 0.6 em, Japanese 1 em per character, line height 1.25 em, colour codes ignored.
local function plain(t)
  return (tostring(t or ""):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""):gsub("|T.-|t", ""))
end
local function lineWidth(line, size)
  local w = 0
  for ch in line:gmatch("[%z\1-\127\194-\244][\128-\191]*") do w = w + (#ch == 1 and 0.6 or 1) * size end
  return w
end
function STUB.textWidth(text, size)
  local best = 0
  for line in (plain(text) .. "\n"):gmatch("(.-)\n") do best = math.max(best, lineWidth(line, size or 12)) end
  return best
end
function STUB.textHeight(fs, width)
  local text = plain(fs.__text)
  if text == "" then return 0 end
  local size = fs.__fontSize or 12
  local lines = 0
  for line in (text .. "\n"):gmatch("(.-)\n") do
    local w = lineWidth(line, size) * 1.08 -- word wrap leaves some room at line ends
    lines = lines + ((width and width > 0) and math.max(1, math.ceil(w / width)) or 1)
  end
  return lines * math.ceil(size * 1.25)
end
function methods:GetStringWidth() return STUB.textWidth(self.__text, self.__fontSize) end
function methods:GetStringHeight() return STUB.textHeight(self, self.__wset and self.__w or nil) end
function methods:GetUnboundedStringWidth() return self:GetStringWidth() end
function methods:GetLineHeight() return 14 end
function methods:GetNumLines() return math.max(1, math.floor(STUB.textHeight(self, self.__wset and self.__w or nil) / math.ceil((self.__fontSize or 12) * 1.25))) end
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
  if not self.__fs then
    self.__fs = new("FontString", nil, self)
    self.__fs.__text = self.__text
  end
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
  if template == "UIPanelCloseButton" then o.__w, o.__h = 32, 32 end
  if name then _G[name] = o end
  return o
end
function CreateFont(name) local o = new("Font", name); if name then _G[name] = o end; return o end

UIParent = new("Frame", "UIParent")
UIParent.__w, UIParent.__h = 1024, 768
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
-- Cancellable timers (the toast's auto-hide) wait for STUB.runLongTimers, so tests can still see the toast.
STUB.longTimers = {}
function C_Timer.NewTimer(_, fn)
  local h = { cancelled = false }
  function h:Cancel() self.cancelled = true end
  table.insert(STUB.longTimers, function() if not h.cancelled then fn(h) end end)
  return h
end
function STUB.runLongTimers()
  local list = STUB.longTimers
  STUB.longTimers = {}
  for _, fn in ipairs(list) do fn() end
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
-- A name means its highest known rank (highest learn level), else its first rank.
local function spellId(x)
  if type(x) == "number" then return x end
  local best, bestKnown
  for id, n in pairs(STUB.names) do
    if n == x then
      local lv = STUB.levels[id] or 0
      if STUB.known[id] and (not bestKnown or lv > (STUB.levels[bestKnown] or 0)) then bestKnown = id end
      if not best or lv < (STUB.levels[best] or 0) then best = id end
    end
  end
  return bestKnown or best
end
STUB.spellId = spellId
STUB.subtext = {} -- spell id → "Rank N"
C_Spell = {}
function C_Spell.GetSpellInfo(x)
  local id = spellId(x)
  if not id or not STUB.names[id] then return nil end
  return { name = STUB.names[id], iconID = 136000 + id % 1000, spellID = id, castTime = 1500, minRange = 0, maxRange = 40 }
end
function C_Spell.GetSpellName(x) local id = spellId(x); return id and STUB.names[id] end
function C_Spell.GetSpellTexture(x) local id = spellId(x); return id and STUB.names[id] and 136000 end
function C_Spell.GetSpellSubtext(x) local id = spellId(x); return id and STUB.subtext[id] or "" end
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
C_Item = {
  PickupItem = C_Item_PickupItem,
  GetItemNameByID = function(id) return "Item " .. id end,
  GetItemCount = function(id) return STUB.bags[id] or 0 end,
  GetItemInfo = function(id) return "Item " .. id, nil, 1, 1, STUB.itemLevels[id] or 0 end,
  GetItemIconByID = function(id) return 100000 + id end,
}
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
-- Which spell id a macro casts: "Name(Rank N)" is that rank; a plain name is the highest known rank, or rank 1
-- when STUB.macroPlainRank1 is set (to test the fallback).
function GetMacroSpell(i)
  local m = STUB.macros[i]
  if not m then return nil end
  local spell = m.body:match("/cast [^\n]*%] *([^\n]+)") or m.body:match("/cast ([^\n]+)")
  if not spell then return nil end
  local name, rank = spell:match("^(.-)%((Rank %d+)%)$")
  if name then
    for id, n in pairs(STUB.names) do
      if n == name and STUB.subtext[id] == rank and STUB.known[id] then return id end
    end
    return nil
  end
  if STUB.macroPlainRank1 then
    for id, n in pairs(STUB.names) do
      if n == spell and STUB.subtext[id] == "Rank 1" then return id end
    end
  end
  local id = spellId(spell)
  return id and STUB.known[id] and id or nil
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

-- Layout check ------------------------------------------------------------------------------------------
-- Works out every region's rectangle from its anchors (y grows upwards, UIParent is 0..1024 x 0..768) and reports
-- text or buttons outside the window, text without a width that does not fit, labels wider than their button,
-- and overlapping texts/buttons. Regions inside a ScrollFrame are skipped (they scroll).
local H = { LEFT = "min", RIGHT = "max" }
local V = { TOP = "max", BOTTOM = "min" }
local function part(point, map)
  for k, v in pairs(map) do if point:find(k) then return v end end
  return "mid"
end

local function isText(f) return f.__kind == "FontString" end

function STUB.rect(f, cache)
  cache = cache or {}
  if f == UIParent then return { 0, 0, 1024, 768 } end
  if cache[f] ~= nil then return cache[f] or nil end
  cache[f] = false -- cycle guard
  local pts = f.__points
  if not pts or #pts == 0 then return nil end
  local function axis(map, lo, hi)
    local cons = {}
    for _, p in ipairs(pts) do
      local mine, theirs = part(p[1], map), part(p[3], map)
      local r = STUB.rect(p[2] or f.__parent, cache)
      if not r then return nil end
      local off = (map == H) and p[4] or p[5]
      local c = (theirs == "min" and r[lo]) or (theirs == "max" and r[hi]) or (r[lo] + r[hi]) / 2
      cons[mine] = c + off
    end
    return cons
  end
  local hc, vc = axis(H, 1, 3), axis(V, 2, 4)
  if not hc or not vc then return nil end
  local x1, x2
  if hc.min and hc.max then
    x1, x2 = hc.min, hc.max
  else
    local w = f.__w
    if isText(f) then w = f.__wset and f.__w or STUB.textWidth(f.__text, f.__fontSize) end
    if hc.min then x1, x2 = hc.min, hc.min + w
    elseif hc.max then x1, x2 = hc.max - w, hc.max
    elseif hc.mid then x1, x2 = hc.mid - w / 2, hc.mid + w / 2
    else return nil end
  end
  local y1, y2
  if vc.min and vc.max then
    y1, y2 = vc.min, vc.max
  else
    local h = f.__h
    if isText(f) then h = STUB.textHeight(f, x2 - x1) end
    if vc.max then y1, y2 = vc.max - h, vc.max
    elseif vc.min then y1, y2 = vc.min, vc.min + h
    elseif vc.mid then y1, y2 = vc.mid - h / 2, vc.mid + h / 2
    else return nil end
  end
  cache[f] = { x1, y1, x2, y2 }
  return cache[f]
end

function STUB.checkLayout(root)
  local problems, regions, cache = {}, {}, {}
  local rr = STUB.rect(root, cache)
  if not rr then return { "window has no position" } end
  local function inside(f)
    local p = f.__parent
    while p and p ~= root do
      if not p.__shown or p.__kind == "ScrollFrame" then return false end
      p = p.__parent
    end
    return p == root and f.__shown
  end
  local function name(f) return (f.__kind .. " '" .. plain(f.__text):sub(1, 40) .. "'") end
  for _, f in ipairs(STUB.frames) do
    if f ~= root and inside(f) then
      local text = plain(f.__text)
      if isText(f) and text ~= "" and not (f.__parent.__kind == "Button" and f.__parent.__fs == f) then
        if not f.__nsw then table.insert(problems, name(f) .. ": no SetNonSpaceWrap") end
        local r = STUB.rect(f, cache)
        if r then
          -- the text's own extent (left-aligned), not its whole box
          local w = math.min(r[3] - r[1], STUB.textWidth(f.__text, f.__fontSize))
          if f.__justifyH == "CENTER" then
            local m = (r[1] + r[3]) / 2
            r = { m - w / 2, r[2], m + w / 2, r[4] }
          elseif f.__justifyH ~= "RIGHT" then
            r = { r[1], r[2], r[1] + w, r[4] }
          end
          table.insert(regions, { f = f, r = r })
        end
      elseif f.__kind == "Button" and text ~= "" and f.__template == "UIPanelButtonTemplate" then
        if STUB.textWidth(f.__text, 12) > f.__w - 8 then
          table.insert(problems, name(f) .. string.format(": label %d px in a %d px button", STUB.textWidth(f.__text, 12), f.__w))
        end
        local r = STUB.rect(f, cache)
        if r then table.insert(regions, { f = f, r = r }) end
      elseif f.__kind == "ScrollFrame" or f.__kind == "EditBox" and f.__parent == root then
        local r = STUB.rect(f, cache)
        if r then table.insert(regions, { f = f, r = r }) end
      end
    end
  end
  for i, a in ipairs(regions) do
    local r = a.r
    if r[1] < rr[1] - 1 or r[3] > rr[3] + 1 or r[2] < rr[2] - 1 or r[4] > rr[4] + 1 then
      table.insert(problems, name(a.f) .. string.format(": outside the window (%d,%d)-(%d,%d) vs (%d,%d)-(%d,%d)",
        r[1], r[2], r[3], r[4], rr[1], rr[2], rr[3], rr[4]))
    end
    for j = i + 1, #regions do
      local b = regions[j].r
      if r[1] < b[3] - 1 and b[1] < r[3] - 1 and r[2] < b[4] - 1 and b[2] < r[4] - 1 then
        table.insert(problems, name(a.f) .. " overlaps " .. name(regions[j].f))
      end
    end
  end
  return problems
end
