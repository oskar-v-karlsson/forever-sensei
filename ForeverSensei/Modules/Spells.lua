-- Modules/Spells.lua: runtime helpers for the class spell data (known check, current rank, icon, where it goes).
local _, ns = ...
local Spells = {}
ns.Spells = Spells

-- The active class pack (Core/Class.lua). Only called while a pack is active.
function Spells.Data()
  return ns.class
end

function Spells.List()
  return ns.class.spells
end

function Spells.Get(key)
  return ns.class.byKey[key]
end

-- Find an entry by English name (any case) or key.
function Spells.Find(text)
  if not text or text == "" then return nil end
  local lower = text:lower()
  for _, s in ipairs(Spells.List()) do
    if s.key == lower or s.name:lower() == lower then return s end
  end
  return nil
end

function Spells.ByName(name)
  if not name then return nil end
  for _, s in ipairs(Spells.List()) do
    if s.name == name then return s end
  end
  return nil
end

local function spellName(id)
  local ok, name = ns.Call("C_Spell.GetSpellName", id)
  if ok then return name end
  return nil
end
Spells.Name = spellName

-- Every rank's spell id, rank 1 first (the pack's Data/Ranks.lua; one id for single-rank spells).
function Spells.Ranks(entry)
  return ns.class.ranks[entry.key] or { entry.id }
end

-- Rank number of a spell id of this entry, or nil when the id is not one of its ranks.
function Spells.RankOf(entry, id)
  for i, r in ipairs(Spells.Ranks(entry)) do
    if r == id then return i end
  end
  return nil
end

local function knownId(id)
  local ok, known = ns.Call("C_SpellBook.IsSpellKnown", id)
  if ok and known then return true end
  ok, known = ns.Call("IsPlayerSpell", id)
  return ok and known and true or false
end

-- Highest known rank. → rank number, spell id (nil when no rank is known)
function Spells.KnownRank(entry)
  local list = Spells.Ranks(entry)
  for i = #list, 1, -1 do
    if knownId(list[i]) then return i, list[i] end
  end
  return nil
end

-- Known by the player (any rank)?
function Spells.IsKnown(entry)
  if Spells.KnownRank(entry) then return true end
  local ok, slot = ns.Call("C_SpellBook.FindSpellBookSlotForSpell", entry.name)
  return ok and slot and true or false
end

-- Highest known rank's spell id; else what the client resolves for the English name; else the rank 1 id.
function Spells.CurrentID(entry)
  local _, id = Spells.KnownRank(entry)
  if id then return id end
  local ok, info = ns.Call("C_Spell.GetSpellInfo", entry.name)
  if ok and type(info) == "table" and info.spellID and info.name == entry.name then return info.spellID end
  return entry.id
end

function Spells.Texture(entry)
  local ok, tex = ns.Call("C_Spell.GetSpellTexture", Spells.CurrentID(entry))
  if ok and tex then return tex end
  ok, tex = ns.Call("C_Spell.GetSpellTexture", entry.id)
  if ok then return tex end
  return nil
end

-- The planned slot of a spell. A spell that only gets its own slot "after" another one is learned stands in on
-- that spell's slot until then (Lightning Shield on X before Water Shield).
function Spells.LayoutSlot(entry)
  local layout = ns.spec.layout
  local slot = layout.bySpell[entry.key]
  if slot and slot.after and not Spells.IsKnown(Spells.Get(slot.after)) then return layout.bySpell[slot.after] end
  if slot then return slot end
  -- A spell without a slot of its own stands in on another spell's slot until that spell is learned (Purify on
  -- Cleanse's Mouse5); after that it lives where L.noSlot says.
  for _, s in ipairs(layout.slots) do
    if s.standIn == entry.key and not Spells.IsKnown(Spells.Get(s.spell)) then return s end
  end
  return nil
end

-- "メインバー・キー 1" / "アクションバー 3（クリック）" / Totem Bar / passive
function Spells.WhereText(entry)
  local layout = ns.spec.layout
  local slot = Spells.LayoutSlot(entry)
  if slot then
    local bar = ns.T("ui.bar." .. slot.bar)
    if slot.key then
      return ns.T("ui.where.key", { bar = bar, button = slot.button, key = ns.KeyLabel(slot.key) })
    end
    return ns.T("ui.where.click", { bar = bar, button = slot.button })
  end
  local kind = layout.noSlot[entry.key]
  if kind then return ns.T("ui.where." .. kind) end
  return "?"
end

function Spells.RoleText(entry)
  return ns.T("ui.role." .. entry.role)
end

function Spells.UseText(entry)
  return ns.T("ui.use." .. entry.use)
end

function Spells.PlayerLevel()
  return UnitLevel("player") or 1
end
