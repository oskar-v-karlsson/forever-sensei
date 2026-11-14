-- ForeverSensei_Warrior/Register.lua: hands the Warrior data to ForeverSensei (the core addon), through its one global.
-- Loaded last. The core builds the lookups (spell byKey, layout slots and stance pages, talent order) and picks the
-- default spec. English only: there is no locales.ja, so the core shows the English texts (ns.Raw).
local _, P = ...

if type(ForeverSensei) ~= "table" or type(ForeverSensei.RegisterClass) ~= "function" then return end

ForeverSensei.RegisterClass("WARRIOR", {
  api = 1, -- ForeverSensei class pack API (also ## X-ForeverSensei-API in the TOC)
  name = "ForeverSensei_Warrior",
  spells = P.spells,
  ranks = P.ranks,
  ranksSource = P.ranksSource,
  sources = P.sources,
  -- Item macros this class's layouts use (kinds in ForeverSensei/Data/Items.lua).
  items = { "health", "bandage" },
  locales = P.locales,
  localeOrder = P.localeOrder,
  defaultSpec = "ARMS",
  specs = P.specs,
})
