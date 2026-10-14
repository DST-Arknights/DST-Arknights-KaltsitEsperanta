local common = require("kaltsit_esperanta_common")
local medicine = require("kaltsit_clinical_medicine")
local DURATION = 30
local buffPrefab = "kaltsit_tissue_repair_solvent_buff"

local assets = {
  Asset("ANIM", "anim/kaltsit_tissue_repair_solvent.zip"),
  Asset("ATLAS", "images/inventoryimages/kaltsit_tissue_repair_solvent.xml"),
}
RegisterInventoryItemAtlas("images/inventoryimages/kaltsit_tissue_repair_solvent.xml", "kaltsit_tissue_repair_solvent.tex")

local function BuffOnTick(inst, target)
  common.HealTarget(target, target, target.components.health.maxhealth * 0.01, buffPrefab, true)
  local pet = medicine.GetMon3tr(target)
  if pet ~= nil then
    common.HealTarget(target, pet, 20, buffPrefab, true)
  end
end

local function BuffOnAttached(inst, target)
  medicine.StartRegen(inst, target, BuffOnTick)
end

local function OnEaten(inst, eater)
  if not medicine.CanConsume(eater) then return end
  -- 仅服用时瞬间恢复；读档重新挂载和中途召唤不重复触发。
  common.HealTarget(eater, eater, eater.components.health.maxhealth * 0.2, buffPrefab, false)
  local pet = medicine.GetMon3tr(eater)
  if pet ~= nil then
    common.HealTarget(eater, pet, 150, buffPrefab, false)
  end
  eater:AddDebuff(buffPrefab, buffPrefab)
end

local function Fn()
  local inst = CreateEntity()
  inst.entity:AddTransform()
  inst.entity:AddAnimState()
  inst.entity:AddNetwork()

  MakeInventoryPhysics(inst)
  inst.AnimState:SetBank("kaltsit_tissue_repair_solvent")
  inst.AnimState:SetBuild("kaltsit_tissue_repair_solvent")
  inst.AnimState:PlayAnimation("idle")

  inst:AddTag("potion")
  inst:AddTag("pre-preparedfood")
  inst:AddTag("fooddrink")
  inst:AddTag("edible_" .. medicine.FOODTYPE)

  MakeInventoryFloatable(inst, "small", 0.2, 0.4)
  inst.entity:SetPristine()
  if not TheWorld.ismastersim then return inst end

  inst:AddComponent("inspectable")
  inst:AddComponent("inventoryitem")
  inst:AddComponent("stackable")
  inst.components.stackable.maxsize = TUNING.STACK_SIZE_SMALLITEM
  MakeHauntableLaunch(inst)
  inst:AddComponent("edible")
  inst.components.edible.foodtype = medicine.FOODTYPE
  inst.components.edible.healthvalue = 0
  inst.components.edible.hungervalue = 0
  inst.components.edible.sanityvalue = 0
  inst.components.edible:SetOnEatenFn(OnEaten)
  return inst
end

return Prefab("kaltsit_tissue_repair_solvent", Fn, assets, { buffPrefab }), ArkMakeBuff({
  name = buffPrefab,
  duration = DURATION,
  keepondespawn = true,
  assets = assets,
  title = STRINGS.UI.KALTSIT_ESPERANTA_BUFFS.TISSUE_REPAIR_TITLE,
  description = STRINGS.UI.KALTSIT_ESPERANTA_BUFFS.TISSUE_REPAIR_DESCRIPTION,
  icon_atlas = "images/inventoryimages/kaltsit_tissue_repair_solvent.xml",
  icon_image = "kaltsit_tissue_repair_solvent.tex",
  OnAttached = BuffOnAttached,
  OnExtended = BuffOnAttached,
  OnDetached = medicine.StopRegen,
})
