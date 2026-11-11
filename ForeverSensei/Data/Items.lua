-- Data/Items.lua: potions, elixirs and Healthstones the layout's item macros use (FS_MANA, FS_HEALPOT, FS_ELIXIR,
-- FS_HEALTH).
-- Every item was checked on Wowhead Forever (https://www.wowhead.com/forever/item=<id>, tooltip data from
-- nether.wowhead.com/forever/tooltip/item/<id>) on the verified date. List order is best first; the macro uses the
-- first one in the bags that the player's level allows. level = required level from the Forever tooltip (nil: none).
-- Left out on purpose: Discolored Healing Potions (they heal, then take 75% back as poison or disease), the PvP
-- Combat potions (need a PvP rank), Restored potions (restore a percentage) and Draughts.
local _, ns = ...

local V = "2026-11-11"

ns.ItemData = {
  verified = V,
  src = "wh_item",
  -- label: the item name the texts use for the kind; icon: shown when the bags have none (Forever tooltip icon).
  -- fallback: the kind to use when the bags have none of this kind.
  kinds = {
    mana = {
      macro = "FS_MANA",
      label = "Mana Potion",
      icon = "INV_Potion_72",
      list = {
        { id = 13444,  name = "Major Mana Potion",    level = 49 },
        { id = 13443,  name = "Superior Mana Potion", level = 41 },
        { id = 6149,   name = "Greater Mana Potion",  level = 31 },
        { id = 3827,   name = "Mana Potion",          level = 22 },
        { id = 3385,   name = "Lesser Mana Potion",   level = 14 },
        { id = 287969, name = "Lesser Mana Potion" },  -- Bind to Account, no required level
        { id = 2455,   name = "Minor Mana Potion",    level = 5 },
        { id = 287968, name = "Minor Mana Potion" },   -- Bind to Account, no required level
      },
    },
    healpot = {
      macro = "FS_HEALPOT",
      label = "Healing Potion",
      icon = "INV_Potion_51",
      list = {
        { id = 13446,  name = "Major Healing Potion",             level = 45 },
        { id = 3928,   name = "Superior Healing Potion",          level = 35 },
        { id = 1710,   name = "Greater Healing Potion",           level = 21 },
        { id = 287977, name = "Greater Healing Potion" },          -- Bind to Account
        { id = 929,    name = "Healing Potion",                   level = 12 },
        { id = 268883, name = "Perishable Healing Potion",        level = 12 },
        { id = 858,    name = "Lesser Healing Potion",            level = 3 },
        { id = 287967, name = "Lesser Healing Potion" },           -- Bind to Account
        { id = 268882, name = "Perishable Lesser Healing Potion", level = 3 },
        { id = 118,    name = "Minor Healing Potion" },            -- no required level on the tooltip
        { id = 287966, name = "Minor Healing Potion" },            -- Bind to Account
        { id = 268881, name = "Perishable Minor Healing Potion" },
      },
    },
    -- Healthstones are conjured by warlocks: Unique, "Instantly restores N life", 2 Min Cooldown on every Forever
    -- tooltip. Forever has three items per size; two heal the full amount and one a little less (e.g. Minor 5512 and
    -- 19005 heal 120, 19004 heals 110). Without a Healthstone the macro uses the best Healing Potion.
    health = {
      macro = "FS_HEALTH",
      label = "Healthstone",
      icon = "INV_Stone_04",
      fallback = "healpot",
      list = {
        { id = 9421,  name = "Major Healthstone",   level = 48 }, -- 1440
        { id = 19013, name = "Major Healthstone",   level = 48 }, -- 1440
        { id = 19012, name = "Major Healthstone",   level = 48 }, -- 1320
        { id = 5510,  name = "Greater Healthstone", level = 36 }, -- 960
        { id = 19011, name = "Greater Healthstone", level = 36 }, -- 960
        { id = 19010, name = "Greater Healthstone", level = 36 }, -- 880
        { id = 5509,  name = "Healthstone",         level = 24 }, -- 600
        { id = 19009, name = "Healthstone",         level = 24 }, -- 600
        { id = 19008, name = "Healthstone",         level = 24 }, -- 550
        { id = 5511,  name = "Lesser Healthstone",  level = 12 }, -- 300
        { id = 19007, name = "Lesser Healthstone",  level = 12 }, -- 300
        { id = 19006, name = "Lesser Healthstone",  level = 12 }, -- 275
        { id = 5512,  name = "Minor Healthstone" },               -- 120, no required level
        { id = 19005, name = "Minor Healthstone" },               -- 120
        { id = 19004, name = "Minor Healthstone" },               -- 110
      },
    },
    elixir = {
      macro = "FS_ELIXIR",
      label = "Arcane Elixir",
      icon = "INV_Potion_106",
      list = {
        { id = 13454,  name = "Greater Arcane Elixir", level = 47 }, -- +35 spell damage, 1 hour
        { id = 9155,   name = "Arcane Elixir",         level = 37 }, -- +20, 30 minutes
        { id = 250342, name = "Lesser Arcane Elixir",  level = 25 }, -- +15, 30 minutes (new in Forever)
        { id = 247754, name = "Minor Arcane Elixir" },               -- +5, 30 minutes (new in Forever)
      },
    },
  },
}
