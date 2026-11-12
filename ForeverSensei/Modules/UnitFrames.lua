-- Modules/UnitFrames.lua: Mouse 4/5 over the Blizzard unit frames (player, target, party, raid).
-- The Forever unit frames call SecureUnitButton_OnLoad without clickArgs, which registers every mouse button
-- ("AnyUp", Blizzard_FrameXML/SecureTemplates.lua). Over a portrait the frame takes Mouse 4/5 as its own click, so
-- the Action Bar 6 key binding never fires there. This module gives those clicks the same action as the bar button:
-- type "macro" + the macro name (its [@mouseover] is the frame's unit), or type "spell" + the spell id (cast on the
-- frame's unit). Only out of combat, only for planned mouse keys whose slot and binding hold the planned action,
-- never over an attribute something else set, and not at all with Clique loaded.
local _, ns = ...
local UnitFrames = {}
ns.UnitFrames = UnitFrames

local UNITS = { "^player$", "^pet$", "^target$", "^focus$", "^targettarget$", "^party%d$", "^partypet%d$", "^raid%d+$",
  "^raidpet%d+$" }
local PREFIX = { [""] = "", ["SHIFT-"] = "shift-", ["CTRL-"] = "ctrl-" }
local CLICK_TYPES = { [1] = true, [2] = true, [4] = true } -- Enum.ClickBindingType Spell, Macro, PetAction

local frames = setmetatable({}, { __mode = "k" }) -- unit frames we found → true
local owned = setmetatable({}, { __mode = "k" })  -- frame → { attribute → the value we set }
local pending, scheduled = false, false
UnitFrames.status = { frames = 0, keys = {}, skipped = {} }

local function unitOk(unit)
  if type(unit) ~= "string" then return false end
  for _, p in ipairs(UNITS) do
    if unit:match(p) then return true end
  end
  return false
end

local function consider(frame, unit)
  if type(frame) ~= "table" or type(frame.SetAttribute) ~= "function" or frames[frame] then return end
  if frame.IsForbidden and frame:IsForbidden() then return end
  if unitOk(unit or frame:GetAttribute("unit")) then frames[frame] = true end
end

-- Frames that exist already; later ones come through the SecureUnitButton_OnLoad hook below.
local function scan()
  for _, name in ipairs({ "PlayerFrame", "PetFrame", "TargetFrame", "TargetFrameToT", "FocusFrame" }) do
    consider(_G[name])
  end
  local party = _G.PartyFrame
  if type(party) == "table" then
    for i = 1, 4 do
      local m = party["MemberFrame" .. i]
      if type(m) == "table" then
        consider(m)
        consider(m.PetFrame)
      end
    end
  end
  for i = 1, 5 do consider(_G["CompactPartyFrameMember" .. i]) end
  for i = 1, 40 do consider(_G["CompactRaidFrame" .. i]) end
  for g = 1, 8 do
    for m = 1, 5 do consider(_G["CompactRaidGroup" .. g .. "Member" .. m]) end
  end
end

local function frameLabel(frame)
  return frame:GetName() or tostring(frame:GetAttribute("unit") or "?")
end

-- Mouse buttons ("4", "5") that Blizzard Click Casting binds to a spell or macro: its binding runs first there.
local function clickCastButtons()
  local used = {}
  local ok, list = ns.Call("C_ClickBindings.GetProfileInfo")
  if ok and type(list) == "table" then
    for _, b in ipairs(list) do
      local n = type(b) == "table" and type(b.button) == "string" and b.button:match("^Button([45])$")
      if n and CLICK_TYPES[b.type] then used[n] = true end
    end
  end
  return used
end

-- What the planned mouse keys do now. → { { key, prefix, n, t = "macro"|"spell", value } }
local function wanted(skipped)
  local list = {}
  local busy = clickCastButtons()
  for _, s in ipairs(ns.spec.layout.slots) do
    local mod, n = (s.key or ""):match("^(%u*%-?)BUTTON([45])$")
    local prefix = mod and PREFIX[mod]
    if prefix then
      if busy[n] then
        table.insert(skipped, s.key .. ": " .. "Blizzard Click Casting uses this mouse button")
      else
        local cur = ns.Layout.Current(s.slot)
        local d = ns.Layout.DesiredFor(s)
        local okB, action = ns.Call("GetBindingAction", s.key)
        if d and ns.Layout.Matches(cur, d, s.slot) and okB and action == s.binding then
          if d.kind == "macro" then
            table.insert(list, { key = s.key, prefix = prefix, n = n, t = "macro", value = d.macro })
          else
            table.insert(list, { key = s.key, prefix = prefix, n = n, t = "spell", value = cur.id })
          end
        end
      end
    end
  end
  return list
end

local function blank(v)
  return v == nil or v == ""
end

-- Set our attributes on one frame and clear the ones we no longer want. → number of keys set
local function apply(frame, list, skipped)
  local mine = owned[frame]
  if not mine then
    mine = {}
    owned[frame] = mine
  end
  local want = {}
  for _, w in ipairs(list) do
    want[w.prefix .. "type" .. w.n] = w.t
    want[w.prefix .. w.t .. w.n] = w.value
  end
  for attr, v in pairs(mine) do
    if want[attr] ~= v then
      if frame:GetAttribute(attr) == v then frame:SetAttribute(attr, nil) end
      mine[attr] = nil
    end
  end
  local n = 0
  for _, w in ipairs(list) do
    local tAttr, vAttr = w.prefix .. "type" .. w.n, w.prefix .. w.t .. w.n
    local resolved = frame:GetAttribute(w.prefix, "type", w.n)
    local value = frame:GetAttribute(vAttr)
    local foreign = (not blank(resolved) and mine[tAttr] ~= resolved) or (not blank(value) and mine[vAttr] ~= value)
    if foreign then
      mine[tAttr], mine[vAttr] = nil, nil
      table.insert(skipped, frameLabel(frame) .. " " .. w.key .. ": " .. "attribute set by something else")
    else
      frame:SetAttribute(vAttr, w.value)
      frame:SetAttribute(tAttr, w.t)
      mine[tAttr], mine[vAttr] = w.t, w.value
      n = n + 1
    end
  end
  return n
end

-- Bring every unit frame in line with the bars now (out of combat), or once combat ends.
function UnitFrames.Update()
  if not ns.ready or not ns.Active() or not ns.spec then return end
  if ns.InCombat() then
    pending = true
    return
  end
  pending = false
  scan()
  local status = { frames = 0, keys = {}, skipped = {} }
  local list = {}
  local okC, clique = ns.Call("C_AddOns.IsAddOnLoaded", "Clique")
  if okC and clique then
    status.off = "off (Clique is loaded)"
  elseif not ns.settings.unitFrameClicks then
    status.off = "off (setting)"
  else
    list = wanted(status.skipped)
  end
  for _, w in ipairs(list) do table.insert(status.keys, w.key) end
  for frame in pairs(frames) do
    local ok = not (frame.IsForbidden and frame:IsForbidden()) and unitOk(frame:GetAttribute("unit"))
    if apply(frame, ok and list or {}, status.skipped) > 0 then status.frames = status.frames + 1 end
  end
  table.sort(status.skipped)
  UnitFrames.status = status
end

-- Debounced: a full apply changes many slots at once.
function UnitFrames.Refresh()
  if scheduled then return end
  scheduled = true
  C_Timer.After(0, function()
    scheduled = false
    UnitFrames.Update()
  end)
end

-- Unit frames made later (party frames from their pool, compact party/raid frames) set themselves up here.
if type(SecureUnitButton_OnLoad) == "function" and hooksecurefunc then
  hooksecurefunc("SecureUnitButton_OnLoad", function(frame, unit)
    if frames[frame] then return end
    consider(frame, unit)
    if frames[frame] then UnitFrames.Refresh() end
  end)
end

-- Verify output. → list of lines
function UnitFrames.Report()
  UnitFrames.Update()
  local s = UnitFrames.status
  local lines = {}
  local state = pending and "pending (combat)" or s.off or "on"
  table.insert(lines, string.format("  unit frames (Mouse 4/5): %s, %d frames, keys: %s", state, s.frames,
    #s.keys > 0 and table.concat(s.keys, ", ") or "-"))
  for _, k in ipairs(s.skipped) do table.insert(lines, "    skipped " .. k) end
  return lines
end

ns.OnLogin(UnitFrames.Refresh)
ns.On("GROUP_ROSTER_UPDATE", UnitFrames.Refresh)
ns.On("ACTIONBAR_SLOT_CHANGED", UnitFrames.Refresh)
ns.On("UPDATE_BINDINGS", UnitFrames.Refresh)
ns.On("PLAYER_REGEN_ENABLED", function()
  if pending then UnitFrames.Refresh() end
end)
