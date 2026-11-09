-- Core/Locale.lua: text lookup. Every text has a stable id; Locales/en.lua is the source, Locales/ja.lua the
-- translation. Placeholders are {name} and are filled from the vars table.
local _, ns = ...

local function lang()
  local s = ns.settings
  return (s and s.language) or "ja"
end

-- Raw text for id in the given language (fallback English, then the id itself).
function ns.Raw(id, language)
  language = language or lang()
  local t = ns.Locales[language] and ns.Locales[language][id]
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

function ns.HasText(id)
  return ns.Locales.en[id] ~= nil
end

-- Ids of every text in source order, for the review tab.
function ns.TextIds()
  return ns.LocaleOrder
end
