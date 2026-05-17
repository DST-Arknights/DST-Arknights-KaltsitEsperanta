GLOBAL.setmetatable(env, { __index = function(t, k) return GLOBAL.rawget(GLOBAL, k) end })
PrefabFiles = { "kaltsit_esperanta", "kaltsit_esperanta_none", "life_repairing_units", "special_treatment_gun", "special_treatment_bullet" }
Assets = {}


local kaltsit_esperanta_starting_items = {
  "special_treatment_gun",
  "norm_heal_bullet",
}
TUNING.GAMEMODE_STARTING_ITEMS.DEFAULT.KALTSIT_ESPERANTA = kaltsit_esperanta_starting_items
TUNING.GAMEMODE_STARTING_ITEMS.LAVAARENA.KALTSIT_ESPERANTA = kaltsit_esperanta_starting_items
TUNING.GAMEMODE_STARTING_ITEMS.QUAGMIRE.KALTSIT_ESPERANTA = kaltsit_esperanta_starting_items

TUNING.KALTSIT_ESPERANTA_HEALTH = 100
TUNING.KALTSIT_ESPERANTA_HUNGER = 100
TUNING.KALTSIT_ESPERANTA_SANITY = 800

modimport "modmain/special_treatment_gun.lua"
modimport "modmain/special_treatment_bullet.lua"

AddModCharacter("kaltsit_esperanta", "FEMALE", {
  {
    type = "ghost_skin",
    anim_bank = "ghost",
    idle_anim = "idle",
    scale = 0.75,
    offset = { 0, -25 }
  },
})
