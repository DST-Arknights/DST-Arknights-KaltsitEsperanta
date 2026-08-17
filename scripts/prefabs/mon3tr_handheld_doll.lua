-- Mon3tr 手持玩偶
-- 手持时每秒回理智(7/min)；喂步行手杖强化后, 手持时移速 +25%
local assets = {
  Asset("ANIM", "anim/mon3tr_handheld_doll.zip"),
  Asset("ANIM", "anim/swap_mon3tr_handheld_doll.zip"),
  Asset("ATLAS", "images/inventoryimages/mon3tr_handheld_doll.xml"),
}

RegisterInventoryItemAtlas("images/inventoryimages/mon3tr_handheld_doll.xml", "mon3tr_handheld_doll.tex")

local DAPPERNESS = 7 / 60        -- 手持每秒回理智 (7/min)
local WALKSPEED_BOOST = 1.25     -- 喂步行手杖强化后移速 +25%

local function OnEnhance(inst, item, doer)
  return "cane", 1
end

local function CanEnhance(inst, item, doer, stage)
  if item.prefab ~= "cane" then
    return false
  end
  if stage["cane"] ~= nil and stage["cane"] >= 1 then
    return false, "MATERIAL_AT_MAX"
  end
  return true
end

-- 从 stage 全量重算装备数值(幂等, 强化与读档结果一致)
local function OnEnhanceStageApply(inst, stage, old)
  local enhanced = stage["cane"] ~= nil and stage["cane"] >= 1
  inst.components.equippable.walkspeedmult = enhanced and WALKSPEED_BOOST or nil
end

local function OnEquip(inst, owner)
  owner.AnimState:OverrideSymbol("swap_object", "swap_mon3tr_handheld_doll", "swap_mon3tr_handheld_doll")
  owner.AnimState:Show("ARM_carry")
  owner.AnimState:Hide("ARM_normal")
end

local function OnUnequip(inst, owner)
  owner.AnimState:Hide("ARM_carry")
  owner.AnimState:Show("ARM_normal")
  owner.AnimState:ClearOverrideSymbol("swap_object")
end

local function fn()
  local inst = CreateEntity()

  inst.entity:AddTransform()
  inst.entity:AddAnimState()
  inst.entity:AddNetwork()

  MakeInventoryPhysics(inst)
  inst.AnimState:SetBank("mon3tr_handheld_doll")
  inst.AnimState:SetBuild("mon3tr_handheld_doll")
  inst.AnimState:PlayAnimation("idle")

  MakeInventoryFloatable(inst, "med", 0.05, 0.7)

  inst.entity:SetPristine()

  if not TheWorld.ismastersim then
    return inst
  end

  inst:AddComponent("inspectable")

  inst:AddComponent("inventoryitem")

  inst:AddComponent("equippable")
  inst.components.equippable.equipslot = EQUIPSLOTS.HANDS
  inst.components.equippable.dapperness = DAPPERNESS
  inst.components.equippable:SetOnEquip(OnEquip)
  inst.components.equippable:SetOnUnequip(OnUnequip)

  -- 喂步行手杖强化(强化后手持移速 +25%)
  inst:AddComponent("enhanceable")
  inst.components.enhanceable:SetEnhanceType("mon3tr_handheld_doll")
  inst.components.enhanceable:SetOnEnhanceFn(OnEnhance)
  inst.components.enhanceable:SetCanEnhanceFn(CanEnhance)
  inst.components.enhanceable:SetOnStageApplyFn(OnEnhanceStageApply)

  MakeHauntableLaunch(inst)

  return inst
end

return Prefab("mon3tr_handheld_doll", fn, assets)
