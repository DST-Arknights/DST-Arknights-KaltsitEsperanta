local medicine = require("kaltsit_clinical_medicine")
local DURATION = 120
local buffPrefab = "kaltsit_neuro_gel_buff"

local assets = {
  Asset("ANIM", "anim/kaltsit_neuro_gel.zip"),
  Asset("ATLAS", "images/inventoryimages/kaltsit_neuro_gel.xml"),
}
RegisterInventoryItemAtlas("images/inventoryimages/kaltsit_neuro_gel.xml", "kaltsit_neuro_gel.tex")

local function BuffOnTick(inst, target)
  local sanity = target.components.sanity
  if sanity ~= nil then
    sanity:DoDelta(sanity.max * 0.005)
  end
end

local function BuffOnAttached(inst, target)
  medicine.StartRegen(inst, target, BuffOnTick)
end

local function OnEaten(inst, eater)
  if medicine.CanConsume(eater) then
    eater:AddDebuff(buffPrefab, buffPrefab)
  end
end

local function Fn()
  local inst = CreateEntity()
  inst.entity:AddTransform()
  inst.entity:AddAnimState()
  inst.entity:AddNetwork()

  MakeInventoryPhysics(inst)
  inst.AnimState:SetBank("kaltsit_neuro_gel")
  inst.AnimState:SetBuild("kaltsit_neuro_gel")
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

return Prefab("kaltsit_neuro_gel", Fn, assets, { buffPrefab }), ArkMakeBuff({
  name = buffPrefab,
  duration = DURATION,
  keepondespawn = true,
  assets = assets,
  title = STRINGS.UI.KALTSIT_ESPERANTA_BUFFS.NEURO_GEL_TITLE,
  description = STRINGS.UI.KALTSIT_ESPERANTA_BUFFS.NEURO_GEL_DESCRIPTION,
  icon_atlas = "images/inventoryimages/kaltsit_neuro_gel.xml",
  icon_image = "kaltsit_neuro_gel.tex",
  OnAttached = BuffOnAttached,
  OnExtended = BuffOnAttached,
  OnDetached = medicine.StopRegen,
})
