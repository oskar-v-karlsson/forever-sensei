-- Core/Locale.lua: text lookup. Every text has a stable id; Locales/en.lua is the source, Locales/ja.lua the
-- translation. A class pack has its own Locales/en.lua and ja.lua with the ids it owns (every id lives in one
-- file); an English-only pack (## X-FS-Languages: en) has only en.lua, so its texts show in English in Japanese too.
-- Placeholders are {name} and are filled from the vars table.
local _, ns = ...

local function lang()
  local s = ns.settings
  return (s and s.language) or "ja"
end

-- The active class pack's texts (ForeverSensei_<Class>/Locales) come first, then the core's. → table or nil
local function packTexts(language)
  local pack = ns.class
  return pack and pack.locales and pack.locales[language]
end

-- Raw text for id in the given language (fallback English, then the id itself).
function ns.Raw(id, language)
  language = language or lang()
  local p = packTexts(language)
  local t = p and p[id]
  if t == nil then t = ns.Locales[language] and ns.Locales[language][id] end
  if t == nil then
    p = packTexts("en")
    t = p and p[id]
  end
  if t == nil then t = ns.Locales.en[id] end
  return t or id
end

function ns.T(id, vars)
  local text = ns.Raw(id)
  if vars then
    text = text:gsub("{(%w+)}", function(k)
      local v = vars[k]
      if v == nil then return "{" .. k .. "}" end
      return tostring(v)
    end)
  end
  return text
end

-- The active pack's folder when it owns id (pack texts can share ids, e.g. guide.role.p1), else nil.
function ns.TextPack(id)
  local p = packTexts("en")
  if p ~= nil and p[id] ~= nil then return ns.class.name end
  return nil
end

function ns.HasText(id)
  local p = packTexts("en")
  return ns.Locales.en[id] ~= nil or (p ~= nil and p[id] ~= nil)
end

-- Ids of every text in source order, for the review tab: the class pack's (skills, guide, talents) first, then the
-- core's. An English-only pack (no ja texts) has nothing to check.
local ids
-- A text as written, for the translation check and the report dialog: its placeholders ({key}) in light blue, so they
-- are easy to see and to keep in a suggestion.
function ns.Template(id, language)
  return (ns.Raw(id, language):gsub("{(%w+)}", "|cff59c0ff{%1}|r"))
end

function ns.TextIds()
  if not ids then
    ids = {}
    local pack = ns.class
    local packIds = pack and pack.locales and pack.locales.ja and pack.localeOrder or {}
    for _, id in ipairs(packIds) do table.insert(ids, id) end
    for _, id in ipairs(ns.LocaleOrder) do table.insert(ids, id) end
  end
  return ids
end

function ns.ResetTextIds()
  ids = nil
end
