-- ForeverSensei_Warrior/Data/Arms/Guide.lua: Arms guide sections. Each paragraph is guide.<section>.p<n> in this
-- pack's Locales and names its sources (keys in P.sources or the core's sources). Facts follow the Mobalytics Arms
-- Warrior guide and the Forever client spell data only (research/warrior-arms.md 5.1).
local _, P = ...
local V = "2026-11-14"
P.specs = P.specs or {}
P.specs.ARMS = P.specs.ARMS or {}
local spec = P.specs.ARMS

-- The guide's text tabs, top to bottom (ui.tab.<id> in this pack's Locales); one section each.
spec.tabs = { "role", "rotation", "stances", "rage", "cooldowns", "manners" }

spec.guide = {
  { id = "role", paragraphs = {
    { src = { "moba" } },
    { src = { "moba", "simc" } },
    { src = { "moba", "simc_race" } },
  } },
  { id = "rotation", paragraphs = {
    { src = { "moba" } },
    { src = { "moba" } },
    { src = { "moba", "simc" } },
    { src = { "moba" } },
    { src = { "moba", "simc" } },
  } },
  { id = "stances", paragraphs = {
    { src = { "moba", "simc" } },
    { src = { "simc", "ui" } },
    { src = { "simc" } },
  } },
  { id = "rage", paragraphs = {
    { src = { "simc" } },
    { src = { "moba", "simc" } },
    { src = { "moba" } },
  } },
  { id = "cooldowns", paragraphs = {
    { src = { "moba", "simc" } },
    { src = { "moba", "simc" } },
    { src = { "simc" } },
  } },
  { id = "manners", paragraphs = {
    { src = { "moba" } },
    { src = { "moba" } },
    { src = { "moba" } },
    { src = { "moba", "simc" } },
  } },
}

for _, section in ipairs(spec.guide) do
  section.verified = section.verified or V
end
