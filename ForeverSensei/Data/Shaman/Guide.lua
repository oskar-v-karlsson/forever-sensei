-- Data/Shaman/Guide.lua: guide panel sections. Each paragraph is guide.<section>.p<n> in Locales and names its
-- sources (keys in ns.Sources). Facts follow the Forever guides and the Forever client spell data only.
local _, ns = ...
local V = "2026-11-09"

ns.ClassData.SHAMAN.guide = {
  { id = "role", paragraphs = {
    { src = { "wh_overview", "moba" } },
    { src = { "wh_abilities" } },
    { src = { "simc" } },
    { src = { "moba" } },
    { src = { "moba" } },
  } },
  { id = "healing", paragraphs = {
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
  { id = "totems", paragraphs = {
    { src = { "moba" } },
    { src = { "simc" } },
    { src = { "wh_spell" } },
    { src = { "wh_spell" } },
    { src = { "moba", "simc" } },
    { src = { "moba" } },
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

for _, section in ipairs(ns.ClassData.SHAMAN.guide) do
  section.verified = V
end
