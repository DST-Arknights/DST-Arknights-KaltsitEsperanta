local LIFE_REPAIRING_UNITS_TRADABLE = require("life_repairing_units_tradable")

local assets = {
  Asset("Anim", "anim/life_repairing_units.zip"),
  Asset("ATLAS", "images/inventoryimages/life_repairing_units.xml"),
}
RegisterInventoryItemAtlas("images/inventoryimages/life_repairing_units.xml", "life_repairing_units.tex")

-- 基础数值
local BASE_ABSORB = 0.8      -- 80% 物理防御
local MAX_ABSORB = 0.9       -- 强化满 90%
local BASE_WALKSPEED = 1.1   -- 移速 +10%
local INSULATION_AMOUNT = 240
local BASE_DAPPERNESS = TUNING.DAPPERNESS_HUGE / 2   -- 基础回理智
local DAPPERNESS_STEP = BASE_DAPPERNESS / 10         -- 每喂一个 +1 档

local function FindEnhanceDef(prefab)
  for _, def in pairs(LIFE_REPAIRING_UNITS_TRADABLE) do
    if def.prefab == prefab then
      return def
    end
  end
end

local function OnEnhance(inst, item, doer)
  return item.prefab, 1
end

-- 把当前 stage 汇总出的"穿戴者增益"同步到 owner 身上
local function SyncWearerBuffs(inst)
  local owner = inst._wearer_owner
  if owner == nil or not owner:IsValid() then
    return
  end
  local stage = inst.components.enhanceable.stage
  local has = function(p) return stage[p] ~= nil and stage[p] >= 1 end

  -- 防火(抄 armor_dragonfly): 装备作为 src 在 owner 的 health 上挂火伤减免 modifier
  if owner.components.health ~= nil then
    if has("armor_dragonfly") then
      owner.components.health.externalfiredamagemultipliers:SetModifier(inst, 1 - TUNING.ARMORDRAGONFLY_FIRE_RESIST)
    else
      owner.components.health.externalfiredamagemultipliers:RemoveModifier(inst)
    end
  end

  -- 发光(魔光护符同款)
  local light = inst._wearer_light
  if has("yellowamulet") then
    if light == nil or not light:IsValid() then
      inst._wearer_light = SpawnPrefab("yellowamuletlight")
      inst._wearer_light.entity:SetParent(owner.entity)
    end
  elseif light ~= nil then
    if light:IsValid() then
      light:Remove()
    end
    inst._wearer_light = nil
  end
end

-- 卸下/清除时还原穿戴者身上的临时增益
local function ClearWearerBuffs(inst)
  local owner = inst._wearer_owner
  if owner ~= nil and owner:IsValid() then
    if owner.components.health ~= nil then
      owner.components.health.externalfiredamagemultipliers:RemoveModifier(inst)
    end
  end
  if inst._wearer_light ~= nil then
    if inst._wearer_light:IsValid() then
      inst._wearer_light:Remove()
    end
    inst._wearer_light = nil
  end
  inst._wearer_owner = nil
end

local function OnEquip(inst, owner)
  local skin_build = inst:GetSkinBuild()

  -- 用跟随实体显示外观(follow symbol), 不占用 owner 的 swap_body 通道
  -- 这样与首饰/背包/防具等其他 body 装备可同时显示
  if inst._followfx == nil or not inst._followfx:IsValid() then
    inst._followfx = SpawnPrefab("life_repairing_units_fx")
  end
  local fx = inst._followfx
  fx.entity:SetParent(owner.entity)
  if skin_build ~= nil then
    owner:PushEvent("equipskinneditem", inst:GetSkinName())
    fx.AnimState:OverrideItemSkinSymbol("swap_body", skin_build, "swap_body", inst.GUID, "life_repairing_units")
  end
  fx.Follower:FollowSymbol(owner.GUID, "swap_body", 0, -200, 0, false)
  fx.components.highlightchild:SetOwner(owner)

  if owner.components.ark_flyer then
    owner.components.ark_flyer:TakeOff()
  end

  inst._wearer_owner = owner
  SyncWearerBuffs(inst)

  if inst.components.container ~= nil then
    inst.components.container:Open(owner)
  end
end

local function OnUnEquip(inst, owner)
  if inst._followfx ~= nil then
    if inst._followfx:IsValid() then
      inst._followfx:Remove()
    end
    inst._followfx = nil
  end
  local skin_build = inst:GetSkinBuild()
  if skin_build ~= nil then
    owner:PushEvent("unequipskinneditem", inst:GetSkinName())
  end
  if owner.components.ark_flyer then
    owner.components.ark_flyer:Land()
  end

  if inst.components.container ~= nil then
    inst.components.container:Close(owner)
  end

  ClearWearerBuffs(inst)
end

-- 是否喂过带无限堆叠的材料(目前只有弹性制造器)
local function HasInfiniteStack(stage)
  for _, def in pairs(LIFE_REPAIRING_UNITS_TRADABLE) do
    if def.infinitestack and stage[def.prefab] ~= nil and stage[def.prefab] >= 1 then
      return true
    end
  end
  return false
end

-- 从 stage 全量重算装备自身数值(幂等, 喂材料与读档结果一致)
local function OnEnhanceStageApply(inst, stage, old)
  local absorb_bonus, planar, walkspeed_bonus, enhance_count = 0, 0, 0, 0
  for _, def in pairs(LIFE_REPAIRING_UNITS_TRADABLE) do
    if stage[def.prefab] ~= nil and stage[def.prefab] >= 1 then
      enhance_count = enhance_count + 1
      absorb_bonus = absorb_bonus + (def.absorb or 0)
      planar = planar + (def.planardefense or 0)
      walkspeed_bonus = walkspeed_bonus + (def.walkspeed or 0)
    end
  end

  inst.components.armor:SetAbsorption(math.clamp(BASE_ABSORB + absorb_bonus, 0, MAX_ABSORB))
  if inst.components.planardefense ~= nil then
    inst.components.planardefense:SetBaseDefense(planar)
  end
  inst.components.equippable.walkspeedmult = BASE_WALKSPEED + walkspeed_bonus
  inst.components.equippable.dapperness = BASE_DAPPERNESS + DAPPERNESS_STEP * enhance_count
  if inst.components.waterproofer ~= nil then
    inst.components.waterproofer:SetEffectiveness((stage["raincoat"] ~= nil and stage["raincoat"] >= 1) and 1 or 0)
  end

  -- 防雷(抄 raincoat): equippable.insulated 是装备自身属性, 穿戴时系统自动生效
  inst.components.equippable.insulated = (stage["raincoat"] ~= nil and stage["raincoat"] >= 1)

  -- 绝缘(装备自身): 花衬衫→夏隔, 松软背心/熊皮大衣→冬暖
  inst._insulation.winter = ((stage["trunkvest"] ~= nil and stage["trunkvest"] >= 1)
    or (stage["beargervest"] ~= nil and stage["beargervest"] >= 1)) and INSULATION_AMOUNT or 0
  inst._insulation.summer = (stage["hawaiianshirt"] ~= nil and stage["hawaiianshirt"] >= 1) and INSULATION_AMOUNT or 0

  -- 容器格子升级(饥饿腰带→2×7, 弹性制造器→2×8) + 无限堆叠(照抄 upgradeable chest)
  if inst.components.lru_upgrade ~= nil then
    local lv_y = 6
    if stage["chestupgrade_stacksize"] ~= nil and stage["chestupgrade_stacksize"] >= 1 then
      lv_y = 8
    elseif stage["armorslurper"] ~= nil and stage["armorslurper"] >= 1 then
      lv_y = 7
    end
    inst.components.lru_upgrade:SetChestLv(2, lv_y)
  end
  if inst.components.container ~= nil then
    inst.components.container:EnableInfiniteStackSize(HasInfiniteStack(stage))
  end

  SyncWearerBuffs(inst)
end

local function CanEnhance(inst, item, doer, stage)
  if FindEnhanceDef(item.prefab) == nil then
    return false
  end
  if stage[item.prefab] ~= nil and stage[item.prefab] >= 1 then
    return false, "MATERIAL_AT_MAX"
  end
  return true
end

local function fn()
  local inst = CreateEntity()

  inst.entity:AddTransform()
  inst.entity:AddAnimState()
  inst.entity:AddNetwork()

  MakeInventoryPhysics(inst)
  inst.AnimState:SetBank("life_repairing_units")
  inst.AnimState:SetBuild("life_repairing_units")
  inst.AnimState:PlayAnimation("anim")
  inst:AddTag("heavyarmor")
  inst:AddTag("hardarmor")
  inst:AddTag("backpack")
  inst:AddTag("armor")
  inst.foleysound = "dontstarve/movement/foley/marblearmour"

  local swap_data = { bank = "life_repairing_units", anim = "anim" }
  MakeInventoryFloatable(inst, "large", 0.2, 0.80, nil, nil, swap_data)

  inst.entity:SetPristine()
  if not TheWorld.ismastersim then
    return inst
  end
  inst:AddComponent("inspectable")
  inst:AddComponent("inventoryitem")
  inst:AddComponent("equippable")

  inst.components.equippable.equipslot = EQUIPSLOTS.BODY
  inst.components.equippable.walkspeedmult = BASE_WALKSPEED
  inst.components.equippable.dapperness = BASE_DAPPERNESS
  inst.components.equippable:SetOnEquip(OnEquip)
  inst.components.equippable:SetOnUnequip(OnUnEquip)

  inst:AddComponent("container")
  inst.components.container:WidgetSetup("life_repairing_units")
  inst:AddComponent("lru_upgrade")
  inst.components.lru_upgrade:SetBaseLv(2, 6)

  inst:AddComponent("enhanceable")
  inst.components.enhanceable:SetEnhanceType("life_repairing_units")
  inst.components.enhanceable:SetOnEnhanceFn(OnEnhance)
  inst.components.enhanceable:SetOnStageApplyFn(OnEnhanceStageApply)
  inst.components.enhanceable:SetCanEnhanceFn(CanEnhance)

  inst:AddComponent("armor")
  inst.components.armor:InitIndestructible(BASE_ABSORB)

  inst:AddComponent("planardefense")
  inst:AddComponent("waterproofer")
  inst.components.waterproofer:SetEffectiveness(0)

  -- 绝缘(隔热/保暖)挂装备自身 insulator 组件, 双季值由 OnEnhanceStageApply 按 stage 重算
  inst:AddComponent("insulator")
  inst._insulation = { winter = 0, summer = 0 }
  inst.components.insulator.GetInsulation = function(self)
    -- 原版 insulator 单 type, 这里按当前季节返回对应那季, 实现冬暖/夏隔共存
    local season = TheWorld.state.season
    if season == SEASONS.WINTER then
      return inst._insulation.winter, SEASONS.WINTER
    end
    return inst._insulation.summer, SEASONS.SUMMER
  end

  inst:ListenForEvent("onremove", function()
    if inst._followfx ~= nil then
      if inst._followfx:IsValid() then
        inst._followfx:Remove()
      end
      inst._followfx = nil
    end
    if inst.components.container ~= nil then
      inst.components.container:DropEverything()
    end
    ClearWearerBuffs(inst)
  end)

  MakeHauntableLaunch(inst)

  return inst
end

-- 跟随显示实体(follow symbol): 外观显示在独立实体上, 不占用 owner 的 body 通道
local function fxfn()
  local inst = CreateEntity()

  inst.entity:AddTransform()
  inst.entity:AddAnimState()
  inst.entity:AddFollower()
  inst.entity:AddNetwork()

  inst:AddTag("FX")

  inst.AnimState:SetBank("life_repairing_units")
  inst.AnimState:SetBuild("life_repairing_units")
  inst.AnimState:PlayAnimation("anim")
  inst.AnimState:SetFinalOffset(1)

  inst:AddComponent("highlightchild")

  inst.entity:SetPristine()

  if not TheWorld.ismastersim then
    return inst
  end

  inst:AddComponent("colouradder")
  inst:AddComponent("bloomer")

  inst.persists = false

  return inst
end

return Prefab("life_repairing_units", fn, assets),
  Prefab("life_repairing_units_fx", fxfn)
