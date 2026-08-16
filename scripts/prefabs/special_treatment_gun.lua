-- ============================================================
-- 物品图标注册
-- ============================================================
local common = require("kaltsit_esperanta_common")

RegisterInventoryItemAtlas("images/inventoryimages/special_treatment_gun.xml", "special_treatment_gun.tex")

-- ============================================================
-- TUNING
-- ============================================================
-- TUNING.SPECIAL_TREATMENT_GUN_ATTACK_PERIOD = 1.5 -- 攻速间隔（秒），越大越慢
TUNING.SPECIAL_TREATMENT_GUN_RANGE_SHOOT   = 5
TUNING.SPECIAL_TREATMENT_GUN_RANGE_MELEE   = 0
local SPECIAL_TREATMENT_DESTROY_PROJECTILE = "special_treatment_destroy_proj"
local gun_assets                           = {
  Asset("ANIM", "anim/special_treatment_gun.zip"),
  Asset("ANIM", "anim/swap_special_treatment_gun.zip"),
  Asset("ATLAS", "images/inventoryimages/special_treatment_gun.xml"),
}

local gun_prefabs                          = {
  SPECIAL_TREATMENT_DESTROY_PROJECTILE,
}

local function RefreshProjectile(inst)
  if inst.components.weapon == nil then
    return
  end

  local ammo = inst.components.container and inst.components.container:GetItemInSlot(1) or nil
  local owner = inst.components.inventoryitem and inst.components.inventoryitem:GetGrandOwner()
  local skill = owner and owner.components.ark_skill and owner.components.ark_skill:GetSkill("kaltsit_esperanta_skill2")
  local skill_activating = skill and skill:IsActivating()
  -- 特殊弹药（技能2）需装备生命修复单元才可发射；否则有普通弹药就走普通弹
  local destroy_ready = skill_activating and common.HasEquippedLifeRepairingUnits(owner)
  ArkLogger:Debug("Refreshing projectile, ammo:", ammo, "skill activating:", skill_activating, "destroy ready:", destroy_ready)
  if ammo ~= nil or destroy_ready then
    inst.components.weapon:SetRange(TUNING.SPECIAL_TREATMENT_GUN_RANGE_SHOOT,
      TUNING.SPECIAL_TREATMENT_GUN_RANGE_SHOOT + 5)
    if destroy_ready then
      inst.components.weapon:SetProjectile(SPECIAL_TREATMENT_DESTROY_PROJECTILE)
    else
      inst.components.weapon:SetProjectile(ammo.prefab .. "_proj")
    end
  else
    inst.components.weapon:SetRange(TUNING.SPECIAL_TREATMENT_GUN_RANGE_MELEE,
      TUNING.SPECIAL_TREATMENT_GUN_RANGE_MELEE + 1)
    inst.components.weapon:SetProjectile(nil)
  end
end

local function OnEquip(inst, owner)
  owner.AnimState:OverrideSymbol("swap_object", "swap_special_treatment_gun", "swap_special_treatment_gun")
  owner.AnimState:Show("ARM_carry")
  owner.AnimState:Hide("ARM_normal")

  if inst.components.container ~= nil then
    inst.components.container:Open(owner)
  end
  ArkLogger:Debug("Equipped, refreshing projectile")
  RefreshProjectile(inst)
  inst:ListenForEvent("ark_skill_activate_effect", inst._OnSkillActivating, owner)
  inst:ListenForEvent("ark_skill_deactivate", inst._OnSkillActivating, owner)
  -- 装备/卸下生命修复单元时刷新：特殊弹的发射前置条件会变化
  inst:ListenForEvent("equip", inst._OnEquipChanged, owner)
  inst:ListenForEvent("unequip", inst._OnEquipChanged, owner)
end

local function OnUnequip(inst, owner)
  owner.AnimState:Hide("ARM_carry")
  owner.AnimState:Show("ARM_normal")
  owner.AnimState:ClearOverrideSymbol("swap_object")
  if inst.components.container ~= nil then
    inst.components.container:Close()
  end
  RefreshProjectile(inst)
  inst:RemoveEventCallback("ark_skill_activate_effect", inst._OnSkillActivating, owner)
  inst:RemoveEventCallback("ark_skill_deactivate", inst._OnSkillActivating, owner)
  inst:RemoveEventCallback("equip", inst._OnEquipChanged, owner)
  inst:RemoveEventCallback("unequip", inst._OnEquipChanged, owner)
end

-- 放入模型展示时（从地面捡起时的模型状态），关闭容器 UI
local function OnEquipToModel(inst, owner, from_ground)
  if inst.components.container ~= nil then
    inst.components.container:Close()
  end
end

local function OnProjectileLaunched(inst, attacker, target, proj)
  local owner = inst.components.inventoryitem and inst.components.inventoryitem:GetGrandOwner()
  local skill = owner and owner.components.ark_skill and owner.components.ark_skill:GetSkill("kaltsit_esperanta_skill2")
  local skill_activating = skill and skill:IsActivating()
  -- 只有特殊弹药（技能2 + 生命修复单元）不消耗枪内弹药；普通弹药一律消耗
  local destroy_ready = skill_activating and common.HasEquippedLifeRepairingUnits(owner)
  if not destroy_ready then
    -- 如果是普通弹药，则消耗弹药
    local ammo_stack = inst.components.container:GetItemInSlot(1)
    local item = inst.components.container:RemoveItem(ammo_stack, false)
    if item ~= nil then
      item:Remove()
    end
  end
  RefreshProjectile(inst)
end

local function gun_fn()
  local inst = CreateEntity()

  inst.entity:AddTransform()
  inst.entity:AddAnimState()
  inst.entity:AddSoundEmitter()
  inst.entity:AddNetwork()
  MakeInventoryPhysics(inst)
  inst.AnimState:SetBank("special_treatment_gun")
  inst.AnimState:SetBuild("special_treatment_gun")
  inst.AnimState:PlayAnimation("idle")
  inst:AddTag("rangedweapon")
  inst:AddTag("weapon")

  MakeInventoryFloatable(inst, "med", 0.07, { 0.53, 0.5, 0.5 })
  inst.entity:SetPristine()
  if not TheWorld.ismastersim then return inst end

  inst._OnSkillActivating = function(owner, data)
    if data.skillId == "kaltsit_esperanta_skill2" then
      ArkLogger:Debug("Skill activating, refreshing projectile")
      RefreshProjectile(inst)
    end
  end

  -- owner 装备/卸下生命修复单元时刷新特殊弹可用状态
  inst._OnEquipChanged = function()
    RefreshProjectile(inst)
  end

  inst:AddComponent("inspectable")
  inst:AddComponent("inventoryitem")
  inst:AddComponent("equippable")
  inst.components.equippable.equipslot = EQUIPSLOTS.HANDS
  inst.components.equippable:SetOnEquip(OnEquip)
  inst.components.equippable:SetOnUnequip(OnUnequip)
  inst.components.equippable:SetOnEquipToModel(OnEquipToModel)

  inst:AddComponent("weapon")
  inst.components.weapon:SetDamage(5)
  inst.components.weapon:SetRange(TUNING.SPECIAL_TREATMENT_GUN_RANGE_MELEE, TUNING.SPECIAL_TREATMENT_GUN_RANGE_MELEE + 1)
  inst.components.weapon:SetOnProjectileLaunched(OnProjectileLaunched)
  inst.components.weapon:SetProjectile(nil)
  inst.components.weapon:SetProjectileOffset(1)


  -- 弹药槽（1 格，仅接受 heal_bullet 的物品）
  inst:AddComponent("container")
  inst.components.container:WidgetSetup("special_treatment_gun")
  inst.components.container.canbeopened = false
  inst.components.container.stay_open_on_hide = true
  inst:ListenForEvent("itemget", RefreshProjectile)
  inst:ListenForEvent("itemlose", RefreshProjectile)
  MakeHauntableLaunch(inst)
  return inst
end

return Prefab("special_treatment_gun", gun_fn, gun_assets, gun_prefabs)
