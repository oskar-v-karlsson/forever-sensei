-- Core/Init.lua: namespace, safe event bus, combat queue, saved variables and the /sensei command.
local ADDON, ns = ...
ns.ADDON = ADDON
ns.VERSION = "0.4.0"
do
  local getMeta = C_AddOns and C_AddOns.GetAddOnMetadata
  if getMeta then
    local ok, v = pcall(getMeta, ADDON, "Version")
    if ok and type(v) == "string" and v ~= "" then ns.VERSION = v end
  end
end

ns.missingEvents = {}
ns.errors = {}

-- English-only chat output (the client chat font may lack Japanese glyphs); Japanese goes to our own frames.
function ns.Print(msg)
  if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage("|cff33ccffForeverSensei|r: " .. tostring(msg)) end
end

function ns.Debug(msg)
  table.insert(ns.errors, date("%H:%M:%S") .. " " .. tostring(msg))
  if #ns.errors > 50 then table.remove(ns.errors, 1) end
  if ForeverSenseiDB and ForeverSenseiDB.settings and ForeverSenseiDB.settings.debug then ns.Print(msg) end
end

-- Resolve a global or dotted API name at runtime ("C_Spell.PickupSpell"). → function or nil
function ns.API(path)
  local obj = _G
  for part in string.gmatch(path, "[^%.]+") do
    if type(obj) ~= "table" then return nil end
    obj = obj[part]
  end
  if type(obj) == "function" then return obj end
  return nil
end

-- pcall an API by name. → ok, results...
function ns.Call(path, ...)
  local fn = ns.API(path)
  if not fn then return false, "missing " .. path end
  return pcall(fn, ...)
end

-- Event bus. RegisterEvent throws on events the client does not know, so every registration is protected.
local eventFrame = CreateFrame("Frame")
local handlers = {}
function ns.On(event, fn)
  if not handlers[event] then
    handlers[event] = {}
    local ok, err = pcall(eventFrame.RegisterEvent, eventFrame, event)
    if not ok then
      ns.missingEvents[event] = tostring(err)
      ns.Debug("cannot register " .. event .. ": " .. tostring(err))
    end
  end
  table.insert(handlers[event], fn)
end
eventFrame:SetScript("OnEvent", function(_, event, ...)
  local list = handlers[event]
  if not list then return end
  for _, fn in ipairs(list) do
    local ok, err = pcall(fn, ...)
    if not ok then ns.Debug(event .. ": " .. tostring(err)) end
  end
end)

-- Combat queue: bars, bindings and macros can only change out of combat.
function ns.InCombat()
  return InCombatLockdown and InCombatLockdown() or false
end

local queue, queueOrder = {}, {}
-- Run fn now, or once combat ends (same key replaces the earlier queued call). → true when run now
function ns.OutOfCombat(key, fn)
  if not ns.InCombat() then
    fn()
    return true
  end
  if not queue[key] then table.insert(queueOrder, key) end
  queue[key] = fn
  if ns.UI and ns.UI.Toast then ns.UI.Toast(ns.T("ui.queued")) end
  return false
end

ns.On("PLAYER_REGEN_ENABLED", function()
  local order = queueOrder
  queueOrder = {}
  for _, key in ipairs(order) do
    local fn = queue[key]
    queue[key] = nil
    if fn then
      local ok, err = pcall(fn)
      if not ok then ns.Debug("queued " .. key .. ": " .. tostring(err)) end
    end
  end
end)

-- Saved variables.
local DEFAULTS = {
  settings = {
    language = "ja",          -- "ja" or "en"
    targeting = "mouseover",  -- "mouseover" (macros) or "click" (plain spells)
    showCards = true,
    showTalentHints = true,
    autoRanks = true,         -- put a newly learned rank on the bars in place of the older rank
    minimap = true,
    minimapAngle = 200,
    debug = false,
  },
  reports = {},     -- pending translation reports
  sentCount = 0,
  review = {},      -- text id → "ok" | "reported"
  chars = {},       -- "Name-Realm" → per-character state
}
local CHAR_DEFAULTS = {
  known = {},       -- spell key → true
  initialised = false,
  postponed = {},   -- spell key → true (card closed with あとで)
  lastLevel = 0,
  keepRank = {},    -- action slot → spell id of an older rank the player chose to keep there (undo of a rank upgrade)
  macroRank = {},   -- spell key → "Rank N" when the macro has to name the rank (/cast <name> did not cast the highest)
  -- backup = { slots = {...}, bindings = {...}, time = ... } once the full layout was applied
  -- layoutVersion = layout version this character last saw (nil: from before 0.3.0); see Modules/Layout.lua
}

local function fill(dst, src)
  for k, v in pairs(src) do
    if dst[k] == nil then
      if type(v) == "table" then
        dst[k] = {}
        fill(dst[k], v)
      else
        dst[k] = v
      end
    elseif type(v) == "table" and type(dst[k]) == "table" then
      fill(dst[k], v)
    end
  end
end

function ns.CharKey()
  local name = UnitName and UnitName("player") or "?"
  local realm = GetRealmName and GetRealmName() or "?"
  return tostring(name) .. "-" .. tostring(realm)
end

ns.On("ADDON_LOADED", function(name)
  if name ~= ADDON then return end
  ForeverSenseiDB = ForeverSenseiDB or {}
  fill(ForeverSenseiDB, DEFAULTS)
  ns.db = ForeverSenseiDB
  ns.settings = ns.db.settings
end)

-- Modules run after the character is known.
ns.loginCallbacks = {}
function ns.OnLogin(fn)
  table.insert(ns.loginCallbacks, fn)
end

ns.On("PLAYER_LOGIN", function()
  local key = ns.CharKey()
  ns.db.chars[key] = ns.db.chars[key] or {}
  fill(ns.db.chars[key], CHAR_DEFAULTS)
  ns.char = ns.db.chars[key]
  ns.ready = true
  for _, fn in ipairs(ns.loginCallbacks) do
    local ok, err = pcall(fn)
    if not ok then ns.Debug("login: " .. tostring(err)) end
  end
end)

function ns.IsShaman()
  local _, classFile = UnitClass("player")
  return classFile == "SHAMAN"
end

-- /sensei
local commands = {}
function ns.Command(name, fn) commands[name] = fn end

local function help()
  ns.Print("/sensei              - guide")
  ns.Print("/sensei skills       - skill list")
  ns.Print("/sensei layout       - key layout")
  ns.Print("/sensei talents      - talent advice")
  ns.Print("/sensei report       - send translation reports")
  ns.Print("/sensei review       - translation check")
  ns.Print("/sensei verify       - check data against the game")
  ns.Print("/sensei card <Spell> - show a skill card (English name)")
  ns.Print("/sensei en | ja      - interface language")
  ns.Print("/sensei debug        - toggle debug output")
end

SLASH_FOREVERSENSEI1 = "/sensei"
SLASH_FOREVERSENSEI2 = "/foreversensei"
SlashCmdList.FOREVERSENSEI = function(msg)
  msg = (msg or ""):match("^%s*(.-)%s*$")
  local cmd, rest = msg:match("^(%S*)%s*(.-)$")
  cmd = (cmd or ""):lower()
  local fn = commands[cmd]
  if fn then
    local ok, err = pcall(fn, rest)
    if not ok then ns.Print("error: " .. tostring(err)) end
  else
    help()
  end
end
ns.Command("help", help)
ns.Command("debug", function()
  ns.settings.debug = not ns.settings.debug
  ns.Print("debug " .. (ns.settings.debug and "on" or "off"))
  for _, e in ipairs(ns.errors) do ns.Print(e) end
end)
ns.Command("en", function() ns.settings.language = "en"; ns.Print("language: English (type /reload to refresh open windows)") end)
ns.Command("ja", function() ns.settings.language = "ja"; ns.Print("language: Japanese (type /reload to refresh open windows)") end)
