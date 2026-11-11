-- Core/Class.lua: class packs. Every class lives in its own addon, ForeverSensei_<Class> (for example
-- ForeverSensei_Shaman), like the voice packs of WoW Forever Japanese (ADR-061): the pack depends on this addon and
-- registers through one global, ForeverSensei.RegisterClass(classFile, pack). The core runs without any pack.
-- Packs are LoadOnDemand: at login the core loads only the pack for the player's class (C_AddOns.LoadAddOn, documented
-- in the Forever UI code: Blizzard_APIDocumentationGenerated/AddOnsDocumentation.lua). A pack that is not
-- LoadOnDemand loads with the game and registers before login, which works the same way.
-- Without a pack for the class (missing, turned off or for another API version) the addon stays idle on that
-- character: no skill cards, no layout, no talent hints; /sensei opens with the translation check and settings.
local _, ns = ...

ns.API_VERSION = 1

-- Sources every class uses (src fields name these keys). A pack adds its own (pack.sources) when it is active.
ns.Sources = {
  wh_spell = "https://www.wowhead.com/forever/spell=",
  wh_item = "https://www.wowhead.com/forever/item=",
  ui = "Blizzard UI code for Forever 1.60.1 (github.com/reckhou/WoWBlzCode, folder Forever)",
}

-- ui texts the core shows in its windows but whose wording belongs to a class or spec. Every pack defines them.
ns.PackTexts = {
  "ui.where.totembar", "ui.preview.warn.own", "ui.layout.intro", "ui.layout.intro2", "ui.layout.items",
  "ui.layout.changed", "ui.layout.clean", "ui.targeting.mouseover.help", "ui.targeting.click.help",
  "ui.trainer.title", "ui.trainer.intro", "ui.talents.intro", "ui.preview.warn.stance",
}

local packs = {}
ns.packs = packs

-- "SHAMAN" → "ForeverSensei_Shaman"
function ns.PackName(classFile)
  classFile = tostring(classFile or "")
  return "ForeverSensei_" .. classFile:sub(1, 1) .. classFile:sub(2):lower()
end

-- "SHIFT-Q" → "Shift+Q", "CTRL-BUTTON4" → "Ctrl+Mouse 4"
function ns.KeyLabel(key)
  if not key then return nil end
  local label = key:gsub("^SHIFT%-", "Shift+"):gsub("^CTRL%-", "Ctrl+")
  label = label:gsub("BUTTON(%d)$", function(n) return ns.T("ui.key.mouse", { n = n }) end)
  return label
end

-- A spec layout from its plan: L.plan[bar id] = 12 entries (a spell key; "@kind" an item macro; "-" a spare button;
-- "#" the player's own button; "x" a button the addon never uses (not spare, never filled or bound); "!id" a multi-spell macro from L.combos; { "key", standIn = .., after = .. } a spell
-- with options). Builds L.slots, L.bySpell, L.byItem, L.byCombo, L.own (slot → true) and L.spare (unplanned buttons,
-- in L.spareOrder bar order: first choice for things moved out of a planned slot; key/binding for keyed bars).
-- A bar's keys entry false leaves that button unbound and the key on its game default (the paladin's Ctrl+1-4).
function ns.BuildLayout(L)
  L.slots, L.bySpell, L.byItem, L.byCombo, L.own, L.spare = {}, {}, {}, {}, {}, {}
  L.noSlot = L.noSlot or {}
  L.macros = L.macros or {}
  L.macroKind = L.macroKind or {}
  L.macroAlways = L.macroAlways or {}
  L.macroVars = L.macroVars or {}
  L.combos = L.combos or {}
  L.old = L.old or {}
  L.oldOwn = L.oldOwn or {}
  L.retired = L.retired or {}
  L.ownKeys = L.ownKeys or {}
  L.KeyLabel = ns.KeyLabel
  local spareByBar = {}
  for _, bar in ipairs(L.bars) do
    spareByBar[bar.id] = {}
    local row = L.plan[bar.id] or {}
    for i = 1, 12 do
      local what = row[i] or "-"
      local slotNo = bar.first + i - 1
      local key = bar.keys and bar.keys[i] or nil
      local binding = key and string.format(bar.binding, i) or nil
      if what == "#" then
        L.own[slotNo] = true
      elseif what == "x" then -- nothing: the addon leaves this button alone
      elseif what == "-" then
        table.insert(spareByBar[bar.id], { bar = bar.id, button = i, slot = slotNo, key = key, binding = binding })
      else
        local opts = type(what) == "table" and what or {}
        if type(what) == "table" then what = what[1] end
        local item = what:match("^@(%w+)$")
        local combo = what:match("^!(%w+)$")
        local slot = {
          bar = bar.id, button = i, slot = slotNo, key = key, binding = binding,
          spell = not item and not combo and what or nil, item = item, combo = combo,
          standIn = opts.standIn, after = opts.after,
        }
        table.insert(L.slots, slot)
        if item then
          L.byItem[item] = slot
        elseif combo then
          L.byCombo[combo] = slot
        else
          L.bySpell[what] = slot
        end
      end
    end
  end
  local order = L.spareOrder or {}
  if #order == 0 then
    for _, bar in ipairs(L.bars) do table.insert(order, bar.id) end
  end
  for _, id in ipairs(order) do
    for _, s in ipairs(spareByBar[id] or {}) do table.insert(L.spare, s) end
  end
  return L
end

-- Talent data: T.list (talents), T.path ({ talent key, first level, last level }) → T.byKey and the expanded
-- T.order[n] = { key, rank (after this point), level }.
function ns.BuildTalents(T)
  T.byKey = {}
  for _, t in ipairs(T.list) do T.byKey[t.key] = t end
  T.order = {}
  local ranks = {}
  for _, step in ipairs(T.path) do
    local key, first, last = step[1], step[2], step[3]
    for level = first, last do
      ranks[key] = (ranks[key] or 0) + 1
      table.insert(T.order, { key = key, rank = ranks[key], level = level })
    end
  end
  return T
end

-- The one global. pack = { api, spells, ranks, ranksSource, sources, items, locales = { en, ja }, localeOrder,
-- defaultSpec, specs = { <SPEC> = { layout, guide, talents, tabs } } }. → true when accepted
ForeverSensei = ForeverSensei or {}
ForeverSensei.API = ns.API_VERSION
function ForeverSensei.RegisterClass(classFile, pack)
  if type(classFile) ~= "string" or type(pack) ~= "table" then return false end
  if pack.api ~= ns.API_VERSION then
    ns.packRefused = ns.packRefused or {}
    ns.packRefused[classFile] = tostring(pack.api)
    ns.Debug("class pack " .. classFile .. " refused: API " .. tostring(pack.api) .. ", need " .. ns.API_VERSION)
    return false
  end
  pack.classFile = classFile
  pack.name = pack.name or ns.PackName(classFile)
  pack.byKey = {}
  for _, s in ipairs(pack.spells or {}) do pack.byKey[s.key] = s end
  pack.ranks = pack.ranks or {}
  pack.items = pack.items or {}
  pack.sources = pack.sources or {}
  pack.locales = pack.locales or {}
  pack.localeOrder = pack.localeOrder or {}
  for _, spec in pairs(pack.specs or {}) do
    if spec.layout then ns.BuildLayout(spec.layout) end
    if spec.talents then ns.BuildTalents(spec.talents) end
    spec.guide = spec.guide or {}
    spec.tabs = spec.tabs or {}
  end
  packs[classFile] = pack
  return true
end

local function metadata(name, field)
  local ok, v = ns.Call("C_AddOns.GetAddOnMetadata", name, field)
  if not ok then ok, v = ns.Call("GetAddOnMetadata", name, field) end
  if ok and type(v) == "string" and v ~= "" then return v end
  return nil
end

local function loadAddOn(name)
  local ok, loaded, reason = ns.Call("C_AddOns.LoadAddOn", name)
  if not ok then ok, loaded, reason = ns.Call("LoadAddOn", name) end
  if not ok then return false, tostring(loaded) end
  return loaded and true or false, reason
end

local function activate(pack)
  ns.class = pack
  ns.specId = pack.defaultSpec or next(pack.specs)
  ns.spec = pack.specs[ns.specId]
  for k, v in pairs(pack.sources) do
    if ns.Sources[k] == nil then ns.Sources[k] = v end
  end
  ns.ResetTextIds()
end

-- Called at PLAYER_LOGIN before the modules' login callbacks. Sets ns.class (the pack), ns.specId and ns.spec, or
-- ns.packNote when the character has no usable pack.
function ns.LoadClass()
  if ns.class then return true end
  local _, classFile = UnitClass("player")
  ns.classFile = classFile
  local name = ns.PackName(classFile)
  ns.packFolder = name
  if not packs[classFile] then
    local api = metadata(name, "X-ForeverSensei-API")
    if api and tonumber(api) ~= ns.API_VERSION then
      ns.packRefused = ns.packRefused or {}
      ns.packRefused[classFile] = api
    elseif not (ns.packRefused and ns.packRefused[classFile]) then
      local loaded, reason = loadAddOn(name)
      if not loaded then ns.Debug("LoadAddOn " .. name .. ": " .. tostring(reason)) end
    end
  end
  local pack = packs[classFile]
  if pack then
    activate(pack)
    ns.packNote = nil
    return true
  end
  if ns.packRefused and ns.packRefused[classFile] then
    ns.packNote = { id = "ui.pack.api", key = "api:" .. name .. ":" .. ns.packRefused[classFile] .. ":" .. ns.API_VERSION }
  else
    ns.packNote = { id = "ui.pack.missing", key = "missing:" .. name }
  end
  return false
end

-- True when a class pack drives this character.
function ns.Active()
  return ns.class ~= nil
end

-- language: nil for the player's language, "en" for chat (ns.Print is English only).
function ns.PackNoteText(language)
  if not ns.packNote then return nil end
  return (ns.Raw(ns.packNote.id, language):gsub("{folder}", ns.packFolder or "?"))
end

-- One quiet note per character (and per kind of problem), then the addon stays idle.
ns.OnLogin(function()
  local note = ns.packNote
  if not note or ns.char.packNote == note.key then return end
  ns.char.packNote = note.key
  C_Timer.After(4, function() ns.UI.Toast(ns.PackNoteText(), 20) end)
end)
