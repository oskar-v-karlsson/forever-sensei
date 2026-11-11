-- Modules/Items.lua: the potion, elixir and Healthstone macros of the layout (FS_MANA, FS_HEALPOT, FS_ELIXIR,
-- FS_HEALTH).
-- Each macro uses the best item of its kind in the bags that the player's level allows (Data/Items.lua, best first),
-- else the best item of its fallback kind (FS_HEALTH: a Healthstone, else a Healing Potion).
-- Macros can only be edited out of combat: bag changes in combat (drinking a potion) are handled silently when combat
-- ends. With none in the bags the macro keeps a fixed icon, so the button stays easy to find.
local _, ns = ...
local Items = {}
ns.Items = Items

local function data(kind) return ns.ItemData.kinds[kind] end

local function count(id)
  local ok, n = ns.Call("C_Item.GetItemCount", id)
  if not ok then ok, n = ns.Call("GetItemCount", id) end
  return ok and type(n) == "number" and n or 0
end

-- Required level: the higher of the verified data and the client's item info (in case Forever changes it).
local function minLevel(item)
  local level = item.level or 0
  local ok, _, _, _, _, clientLevel = ns.Call("C_Item.GetItemInfo", item.id)
  if not ok then ok, _, _, _, _, clientLevel = ns.Call("GetItemInfo", item.id) end
  if ok and type(clientLevel) == "number" and clientLevel > level then level = clientLevel end
  return level
end

local function playerLevel()
  local ok, level = ns.Call("UnitLevel", "player")
  return ok and type(level) == "number" and level or 1
end

function Items.Kinds()
  local list = {}
  for kind in pairs(ns.ItemData.kinds) do table.insert(list, kind) end
  table.sort(list)
  return list
end

function Items.Get(kind) return data(kind) end

-- Kind of a known item id (e.g. a potion placed by hand). → kind or nil
local byId
function Items.KindOf(id)
  if not byId then
    byId = {}
    for kind, d in pairs(ns.ItemData.kinds) do
      for _, item in ipairs(d.list) do byId[item.id] = kind end
    end
  end
  return id and byId[id]
end

-- Kind of an item macro name. → kind or nil
function Items.KindOfMacro(name)
  for kind, d in pairs(ns.ItemData.kinds) do
    if d.macro == name then return kind end
  end
end

-- The best usable item of a kind in the bags, else of its fallback kind. → item ({ id, name, level }) or nil
function Items.Best(kind)
  local level = playerLevel()
  local d = data(kind)
  for _, item in ipairs(d.list) do
    if count(item.id) > 0 and minLevel(item) <= level then return item end
  end
  if d.fallback then return Items.Best(d.fallback) end
end

-- The best item of a kind the player could use now, in the bags or not (for the macro when the bags have none).
function Items.ForLevel(kind)
  local level = playerLevel()
  local list = data(kind).list
  for _, item in ipairs(list) do
    if (item.level or 0) <= level then return item end
  end
  return list[#list]
end

-- → body, icon
function Items.MacroBody(kind)
  local best = Items.Best(kind)
  if best then return "#showtooltip\n/use item:" .. best.id, "INV_MISC_QUESTIONMARK" end
  return "/use item:" .. Items.ForLevel(kind).id, data(kind).icon
end

local function macroIndex(name)
  local ok, idx = ns.Call("GetMacroIndexByName", name)
  if ok and type(idx) == "number" and idx > 0 then return idx end
end

-- Create or update the character macro of a kind (call only out of combat). → macro index or nil
function Items.EnsureMacro(kind)
  local d = data(kind)
  local body, icon = Items.MacroBody(kind)
  local idx = macroIndex(d.macro)
  if idx then
    local ok, newIdx = ns.Call("EditMacro", idx, d.macro, icon, body)
    if ok and type(newIdx) == "number" and newIdx > 0 then return newIdx end
    return idx
  end
  local ok, created = ns.Call("CreateMacro", d.macro, icon, body, true)
  if ok and type(created) == "number" and created > 0 then return created end
  ns.Debug("CreateMacro " .. d.macro .. ": " .. tostring(created))
  return nil
end

-- Update the existing item macros whose best item changed. Never creates macros (only the layout does).
local pending = false
function Items.Refresh()
  if not ns.char or not ns.IsShaman() then return end
  if ns.InCombat() then
    pending = true
    return
  end
  pending = false
  for _, kind in ipairs(Items.Kinds()) do
    local d = data(kind)
    local idx = macroIndex(d.macro)
    if idx then
      local body, icon = Items.MacroBody(kind)
      local ok, _, _, oldBody = ns.Call("GetMacroInfo", idx)
      if not ok or oldBody ~= body then ns.Call("EditMacro", idx, d.macro, icon, body) end
    end
  end
end

ns.OnLogin(function() C_Timer.After(2, Items.Refresh) end)
ns.On("BAG_UPDATE_DELAYED", function() if ns.ready then Items.Refresh() end end)
ns.On("PLAYER_LEVEL_UP", function() if ns.ready then C_Timer.After(1, Items.Refresh) end end)
ns.On("PLAYER_REGEN_ENABLED", function() if pending then Items.Refresh() end end)
