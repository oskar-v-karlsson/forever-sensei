-- ForeverSensei_Shaman/Data/Restoration/Guide.lua: Restoration guide sections. Each paragraph is
-- guide.<section>.p<n> in this pack's Locales and names its sources (keys in P.sources or the core's sources). Facts
-- follow the Forever guides and the Forever client spell data only.
local _, P = ...
local V = "2026-11-09"
P.specs = P.specs or {}
P.specs.RESTORATION = P.specs.RESTORATION or {}
local spec = P.specs.RESTORATION

-- The guide's text tabs, top to bottom (ui.tab.<id> in this pack's Locales); one section each.
spec.tabs = { "role", "healing", "damage", "totems", "manners" }

spec.guide = {
  { id = "role", paragraphs = {
    { src = { "wh_overview", "moba" } },
    { src = { "wh_abilities" } },
    { src = { "simc" } },
    { src = { "moba" } },
    { src = { "moba" } },
  } },
  { id = "healing", verified = "2026-11-11", paragraphs = {
    { src = { "moba", "simc" } },
    { src = { "moba" } },
    { src = { "moba" } },
    { src = { "moba", "simc" } },
    { src = { "moba", "simc" } },
    { src = { "moba", "simc" } },
    { src = { "moba" } },
    { src = { "moba" } },
  } },
  { id = "damage", paragraphs = {
    { src = { "moba" } },
    { src = { "moba", "simc" } },
    { src = { "moba", "simc" } },
    { src = { "simc" } },
    { src = { "moba" } },
    { src = { "simc" } },
  } },
  { id = "totems", verified = "2026-11-11", paragraphs = {
    { src = { "moba" } },
    { src = { "simc" } },
    { src = { "wh_spell", "moba", "simc" } },
    { src = { "wh_spell", "moba" } },
    { src = { "moba", "simc" } },
    { src = { "moba" } },
    { src = { "simc" } },
    { src = { "simc" } },
    { src = { "moba", "simc" } },
    { src = { "simc" } },
  } },
  { id = "manners", paragraphs = {
    { src = { "moba" } },
    { src = { "moba" } },
    { src = { "simc" } },
    { src = { "simc" } },
    { src = { "moba" } },
  } },
}

for _, section in ipairs(spec.guide) do
  section.verified = section.verified or V
end
