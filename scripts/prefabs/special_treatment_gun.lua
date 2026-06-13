-- ============================================================
-- 物品图标注册
-- ============================================================
RegisterInventoryItemAtlas("images/inventoryimages/special_treatment_gun.xml", "special_treatment_gun.tex")

-- ============================================================
-- TUNING
-- ============================================================
-- TUNING.SPECIAL_TREATMENT_GUN_ATTACK_PERIOD = 1.5 -- 攻速间隔（秒），越大越慢
TUNING.SPECIAL_TREATMENT_GUN_RANGE_SHOOT = 5
TUNING.SPECIAL_TREATMENT_GUN_RANGE_MELEE = 0
local gun_assets                       = {
  Asset("ANIM", "anim/special_treatment_gun.zip"),
  Asset("ANIM", "anim/swap_special_treatment_gun.zip"),
  Asset("ATLAS", "images/inventoryimages/special_treatment_gun.xml"),
}

local gun_prefabs                      = {
}

local function OnEquip(inst, owner)
  owner.AnimState:OverrideSymbol("swap_object", "swap_special_treatment_gun", "swap_special_treatment_gun")
  owner.AnimState:Show("ARM_carry")
  owner.AnimState:Hide("ARM_normal")

  if inst.components.container ~= nil then
    inst.components.container:Open(owner)
  end
end

local function OnUnequip(inst, owner)
  owner.AnimState:Hide("ARM_carry")
  owner.AnimState:Show("ARM_normal")
  owner.AnimState:ClearOverrideSymbol("swap_object")
  if inst.components.container ~= nil then
    inst.components.container:Close()
  end
end

-- 放入模型展示时（从地面捡起时的模型状态），关闭容器 UI
local function OnEquipToModel(inst, owner, from_ground)
  if inst.components.container ~= nil then
    inst.components.container:Close()
  end
end

local function OnAmmoLoaded(inst, data)
  if inst.components.weapon and data and data.item and data.slot == 1 then
    inst.components.weapon:SetRange(TUNING.SPECIAL_TREATMENT_GUN_RANGE_SHOOT, TUNING.SPECIAL_TREATMENT_GUN_RANGE_SHOOT + 1)
    inst.components.weapon:SetProjectile(data.item.prefab .. "_proj")
    inst:AddTag("ammoloaded")
    data.item:PushEvent("ammoloaded", { slingshot = inst })
  end
end

local function OnAmmoUnloaded(inst, data)
  if inst.components.weapon and data and data.slot == 1 then
    inst.components.weapon:SetRange(TUNING.SPECIAL_TREATMENT_GUN_RANGE_MELEE, TUNING.SPECIAL_TREATMENT_GUN_RANGE_MELEE + 1)
    inst.components.weapon:SetProjectile(nil)
    inst:RemoveTag("ammoloaded")
    if data.prev_item then
      data.prev_item:PushEvent("ammounloaded", { slingshot = inst })
    end
  end
end

local function OnProjectileLaunched(inst, attacker, target, proj)
  if inst.components.container then
    local ammo_stack = inst.components.container:GetItemInSlot(1)
    local item = inst.components.container:RemoveItem(ammo_stack, false)
    if item ~= nil then
      if item == ammo_stack then
        item:PushEvent("ammounloaded", { slingshot = inst })
      end
      item:Remove()
    end
  end
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
  inst:ListenForEvent("itemget", OnAmmoLoaded)
  inst:ListenForEvent("itemlose", OnAmmoUnloaded)
  MakeHauntableLaunch(inst)
  return inst
end

return Prefab("special_treatment_gun", gun_fn, gun_assets, gun_prefabs)
