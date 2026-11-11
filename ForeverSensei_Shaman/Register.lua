-- ForeverSensei_Shaman/Register.lua: hands the Shaman data to ForeverSensei (the core addon), through its one global.
-- Loaded last. The core builds the lookups (spell byKey, layout slots, talent order) and picks the default spec.
local _, P = ...

if type(ForeverSensei) ~= "table" or type(ForeverSensei.RegisterClass) ~= "function" then return end

ForeverSensei.RegisterClass("SHAMAN", {
  api = 1, -- ForeverSensei class pack API (also ## X-ForeverSensei-API in the TOC)
  name = "ForeverSensei_Shaman",
  spells = P.spells,
  ranks = P.ranks,
  ranksSource = P.ranksSource,
  sources = P.sources,
  -- Item macros this class's layouts use (kinds in ForeverSensei/Data/Items.lua).
  items = { "mana", "health", "healpot", "elixir" },
  locales = P.locales,
  localeOrder = P.localeOrder,
  defaultSpec = "RESTORATION",
  specs = P.specs,
})
