-- Modules/Spells.lua: runtime helpers for the class spell data (known check, current rank, icon, where it goes).
local _, ns = ...
local Spells = {}
ns.Spells = Spells

function Spells.Data()
  return ns.ClassData.SHAMAN
end

function Spells.List()
  return ns.ClassData.SHAMAN.spells
end

function Spells.Get(key)
  return ns.ClassData.SHAMAN.byKey[key]
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

-- Known by the player (any rank)?
function Spells.IsKnown(entry)
  local ok, known = ns.Call("C_SpellBook.IsSpellKnown", entry.id)
  if ok and known then return true end
  ok, known = ns.Call("IsPlayerSpell", entry.id)
  if ok and known then return true end
  local ok2, slot = ns.Call("C_SpellBook.FindSpellBookSlotForSpell", entry.name)
  if ok2 and slot then return true end
  return false
end

-- Highest known rank's spell id (by English name), else the rank 1 id.
function Spells.CurrentID(entry)
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

function Spells.LayoutSlot(entry)
  return ns.ClassData.SHAMAN.layout.bySpell[entry.key]
end

-- "メインバー・キー 1" / "アクションバー 3（クリック）" / Totem Bar / passive
function Spells.WhereText(entry)
  local layout = ns.ClassData.SHAMAN.layout
  local slot = layout.bySpell[entry.key]
  if slot then
    local bar = ns.T("ui.bar." .. slot.bar)
    if slot.key then
      return ns.T("ui.where.key", { bar = bar, button = slot.button, key = layout.KeyLabel(slot.key) })
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
