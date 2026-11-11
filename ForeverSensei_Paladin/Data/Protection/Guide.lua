-- ForeverSensei_Paladin/Data/Protection/Guide.lua: Protection guide sections. Each paragraph is
-- guide.<section>.p<n> in this pack's Locales and names its sources (keys in P.sources or the core's sources). Facts
-- follow the Forever guides and the Forever client spell data only.
local _, P = ...
local V = "2026-11-11"
P.specs = P.specs or {}
P.specs.PROTECTION = P.specs.PROTECTION or {}
local spec = P.specs.PROTECTION

-- The guide's text tabs, top to bottom (ui.tab.<id> in this pack's Locales); one section each.
spec.tabs = { "role", "rotation", "seals", "auras", "cooldowns", "manners" }

spec.guide = {
  { id = "role", paragraphs = {
    { src = { "moba", "wh_guide" } },
    { src = { "wh_tt" } },
    { src = { "wh_tt", "simc" } },
    { src = { "wh_tt", "moba" } },
    { src = { "wh_guide" } },
  } },
  { id = "rotation", paragraphs = {
    { src = { "moba" } },
    { src = { "moba", "wh_tt" } },
    { src = { "moba", "wh_guide" } },
    { src = { "moba", "wh_tt" } },
    { src = { "wh_guide", "wh_tt" } },
    { src = { "wh_guide", "wh_tt" } },
  } },
  { id = "seals", paragraphs = {
    { src = { "wh_tt" } },
    { src = { "wh_tt" } },
    { src = { "wh_tt" } },
    { src = { "wh_guide", "wh_tt" } },
    { src = { "wh_tt" } },
    { src = { "wh_tt", "simc" } },
  } },
  { id = "auras", paragraphs = {
    { src = { "simc", "ui" } },
    { src = { "wh_guide", "moba", "wh_tt" } },
    { src = { "wh_tt" } },
    { src = { "wh_tt" } },
    { src = { "wh_tt" } },
  } },
  { id = "cooldowns", paragraphs = {
    { src = { "wh_tt" } },
    { src = { "wh_tt" } },
    { src = { "wh_tt", "moba" } },
    { src = { "wh_tt" } },
    { src = { "wh_tt" } },
  } },
  { id = "manners", paragraphs = {
    { src = { "moba" } },
    { src = { "wh_tt" } },
    { src = { "wh_tt" } },
    { src = { "wh_tt" } },
    { src = { "wh_tt" } },
  } },
}

for _, section in ipairs(spec.guide) do
  section.verified = section.verified or V
end
