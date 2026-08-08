GLOBAL.setmetatable(env, { __index = function(t, k) return GLOBAL.rawget(GLOBAL, k) end })
PrefabFiles = { "kaltsit_esperanta", "kaltsit_esperanta_none", "kaltsit_esperanta_prototyper", "life_repairing_units",
  "special_treatment_gun",
  "special_treatment_bullet", "kaltsit_neuro_gel", "kaltsit_tissue_repair_solvent", "kaltsit_calcite",
  "mon3tr_signboard", "kaltsit_calcite", "kaltsit_esperanta_mon3tr", "kaltsit_esperanta_fx", "kaltsit_esperanta_buff", "tactical_anchor", "kaltsit_esperanta_reticule" }
Assets = {}

assert(ARK_ITEM_PACKAGE_LOADED, "请安装前置模组: ark_item_package\n please install the required mod: ark_item_package\n[https://steamcommunity.com/sharedfiles/filedetails/?id=3677284770]")

ArkLogger:DeclareLogger("INFO", "K2CEsperanta")

-- 加载语言包 (auto 跟随游戏语言, 无英文包时非中文自动回退 en 失败 → 返回 nil 不加载)
RegisterPOFile(GetModConfigData("language"), {
  zh = 'languages/kaltsit_esperanta_chinese_s.po',
})

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

TUNING.KALTSIT_ESPERANTA_SKILL3_RANGE = 20

AddReplicableComponent("kaltsit_intellect")
AddReplicableComponent("kaltsit_mon3tr_master")
AddReplicableComponent("tactical_anchor")

modimport "modmain/kaltsit_intellect.lua"
modimport "modmain/kaltsit_esperanta_tech.lua"
modimport "modmain/special_treatment_gun.lua"
modimport "modmain/special_treatment_bullet.lua"
modimport "modmain/kaltsit_animal_affinity.lua"
modimport "modmain/kaltsit_esperanta_mon3tr.lua"
modimport "modmain/kaltsit_esperanta_skill.lua"
modimport "modmain/tactical_anchor_action.lua"

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