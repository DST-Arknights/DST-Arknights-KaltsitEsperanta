GLOBAL.setmetatable(env, { __index = function(t, k) return GLOBAL.rawget(GLOBAL, k) end })
PrefabFiles = { "kaltsit_esperanta", "kaltsit_esperanta_none", "kaltsit_esperanta_prototyper", "life_repairing_units",
  "special_treatment_gun",
  "special_treatment_bullet", "kaltsit_neuro_gel", "kaltsit_tissue_repair_solvent", "kaltsit_calcite",
  "mon3tr_signboard", "kaltsit_calcite", "kaltsit_esperanta_mon3tr", "kaltsit_esperanta_fx"}
Assets = {}

assert(ARK_ITEM_PACKAGE_LOADED, "请安装前置模组: ark_item_package\n please install the required mod: ark_item_package\n[https://steamcommunity.com/sharedfiles/filedetails/?id=3677284770]")

ArkLogger:DeclareLogger("INFO", "K2CEsperanta")

-- 加载中文语言包
MergePOFile('languages/kaltsit_esperanta_chinese_s.po', LOC.GetLocaleCode(LANGUAGE.CHINESE_S), true)

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


TUNING.KALTSIT_ESPERANTA_MON3TR_HEALTH = 800
TUNING.KALTSIT_ESPERANTA_MON3TR_HUNGER = 800
TUNING.KALTSIT_ESPERANTA_MON3TR_SANITY = 800

AddReplicableComponent("kaltsit_intellect")
AddReplicableComponent("kaltsit_mon3tr_master")

modimport "modmain/kaltsit_intellect.lua"
modimport "modmain/kaltsit_esperanta_tech.lua"
modimport "modmain/special_treatment_gun.lua"
modimport "modmain/special_treatment_bullet.lua"
modimport "modmain/kaltsit_animal_affinity.lua"
modimport "modmain/kaltsit_esperanta_mon3tr.lua"

AddModCharacter("kaltsit_esperanta", "FEMALE", {
  {
    type = "ghost_skin",
    anim_bank = "ghost",
    idle_anim = "idle",
    scale = 0.75,
    offset = { 0, -25 }
  },
})

DefineNetState("kaltsit_intellect", {
  current = "float:classified",
  max = "float:classified",
  next_build_discounted = "bool:classified",
})


function IsPlayerControlling(inst)
  return inst.userid ~= nil
end