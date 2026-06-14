local common = require("kaltsit_esperanta_common")

RegisterInventoryItemAtlas("images/inventoryimages/special_treatment_bullet.xml", "norm_heal_bullet.tex")
RegisterInventoryItemAtlas("images/inventoryimages/special_treatment_bullet.xml", "potent_heal_bullet.tex")
RegisterInventoryItemAtlas("images/inventoryimages/special_treatment_bullet.xml", "regen_heal_bullet.tex")
RegisterInventoryItemAtlas("images/inventoryimages/special_treatment_bullet.xml", "trait_heal_bullet.tex")

-- ============================================================
-- Assets
-- ============================================================
local assets = {
  Asset("ANIM", "anim/special_treatment_bullet.zip"),
  Asset("ATLAS", "images/inventoryimages/special_treatment_bullet.xml"),
}

local SpawnHitAllyFx = function(target)
  if target and target:IsValid() then
    local fx = SpawnPrefab("special_treatment_bullet_fx_ally")
    if fx then
      fx.Transform:SetPosition(target.Transform:GetWorldPosition())
    end
  end
end

local SpawnHitEnemyFx = function(target)
  if target and target:IsValid() then
    local fx = SpawnPrefab("special_treatment_bullet_fx_enemy")
    if fx then
      fx.Transform:SetPosition(target.Transform:GetWorldPosition())
    end
  end
end
-- ============================================================
-- Effect interfaces
-- ============================================================

-- ============================================================
-- Ammo definitions
-- ============================================================
-- 每个弹药定义必须提供 OnHealAlly 和 OnDestroy 两个回调。
-- OnHarmEnemy 为可选，不提供则对敌人无额外效果。
local ammo_defs = {

  -- 普通治疗弹
  {
    name      = "norm_heal_bullet",
    idle_anim = "norm_idle",
    fly_anim  = "norm_fly_loop",
    damage    = 10,
    OnHealAlly = function(attacker, target)
      if target.components.health then
        target.components.health:DoDelta(15, false, "norm_heal_bullet")
      end
    end,
    OnDestroy = function(attacker, target)
      ArkLogger:Debug("Special Destroy triggered on", target, "by", attacker)
    end,
  },

  -- 强效治疗弹
  {
    name      = "potent_heal_bullet",
    idle_anim = "potent_idle",
    fly_anim  = "potent_fly_loop",
    damage    = 15,
    OnHealAlly = function(attacker, target)
      local function DoHealTick(remaining)
        if not target:IsValid() then return end
        if target.components.health and not target.components.health:IsDead() then
          target.components.health:DoDelta(15, false, "potent_heal_bullet")
          if target.components.health.penalty ~= nil
              and target.components.health.penalty > 0 then
            local max_hp = target.components.health.maxhealth
            if max_hp and max_hp > 0 then
              target.components.health.penalty = math.max(0,
                  target.components.health.penalty - 15 / max_hp)
            end
          end
        end
        if remaining > 1 then
          target:DoTaskInTime(1, function() DoHealTick(remaining - 1) end)
        end
      end
      DoHealTick(4)
    end,
    OnDestroy = function(attacker, target)
      ArkLogger:Debug("Special Destroy triggered on", target, "by", attacker)
    end,
    OnHarmEnemy = function(attacker, target)
      local function DoDmgTick(remaining)
        if not target:IsValid() then return end
        if target.components.health
            and not target.components.health:IsDead()
            and target.components.combat then
          target.components.combat:GetAttacked(attacker, 0, nil, nil, {
            true_damage = 15,
          })
        end
        if remaining > 1 then
          target:DoTaskInTime(1, function() DoDmgTick(remaining - 1) end)
        end
      end
      target:DoTaskInTime(1, function() DoDmgTick(3) end)
    end,
  },

  -- 缓回治疗弹
  {
    name      = "regen_heal_bullet",
    idle_anim = "regen_idle",
    fly_anim  = "regen_fly_loop",
    damage    = 0,
    OnHealAlly = function(attacker, target)
      local function _AddImmunity()
        target._regen_bullet_stacks = (target._regen_bullet_stacks or 0) + 1
        if target._regen_bullet_stacks == 1 then
          target:AddTag("sleepimmune")
          target:AddTag("webimmune")
        end
      end
      local function _RemoveImmunity()
        if not target:IsValid() then return end
        target._regen_bullet_stacks = math.max(0, (target._regen_bullet_stacks or 1) - 1)
        if target._regen_bullet_stacks == 0 then
          target:RemoveTag("sleepimmune")
          target:RemoveTag("webimmune")
        end
      end
      _AddImmunity()
      local function DoTick(remaining)
        if not target:IsValid() then
          _RemoveImmunity()
          return
        end
        if target.components.health and not target.components.health:IsDead() then
          target.components.health:DoDelta(2, false, "regen_heal_bullet")
        end
        if remaining > 1 then
          target:DoTaskInTime(2, function() DoTick(remaining - 1) end)
        else
          _RemoveImmunity()
        end
      end
      DoTick(60)
    end,
    OnDestroy = function(attacker, target)
      ArkLogger:Debug("Special Destroy triggered on", target, "by", attacker)
    end,
    OnHarmEnemy = function(attacker, target)
      if target.components.locomotor then
        target.components.locomotor:SetExternalSpeedMultiplier(target, "kelshi_regen_slow", 0.6)
        target:DoTaskInTime(10, function()
          if target:IsValid() and target.components.locomotor then
            target.components.locomotor:RemoveExternalSpeedMultiplier(target, "kelshi_regen_slow")
          end
        end)
      end
      if target.components.sleeper then
        target.components.sleeper:AddSleepiness(40, 10)
      end
    end,
  },

  -- 特制治疗弹
  {
    name      = "trait_heal_bullet",
    idle_anim = "trait_idle",
    fly_anim  = "trait_fly_loop",
    damage    = 20,
    OnHealAlly = function(attacker, target)
      if target.components.health then
        target.components.health:DoDelta(30, false, "trait_heal_bullet")
      end
      if target.components.temperature then
        target.components.temperature:SetTemperature(20)
      end
    end,
    OnDestroy = function(attacker, target)
      ArkLogger:Debug("Special Destroy triggered on", target, "by", attacker)
    end,
    OnHarmEnemy = function(attacker, target)
      if target.components.locomotor then
        target.components.locomotor:SetExternalSpeedMultiplier(target, "kelshi_trait_slow", 0.7)
        target:DoTaskInTime(3, function()
          if target:IsValid() and target.components.locomotor then
            target.components.locomotor:RemoveExternalSpeedMultiplier(target, "kelshi_trait_slow")
          end
        end)
      end
    end,
  },
}

-- ============================================================
-- OnHit factory
-- ============================================================
-- 通过工厂函数生成命中回调，避免把定义挂在预制体实例上。
local function MakeOnHit(def)
  return function(inst, attacker, target)
    if target == nil or not target:IsValid() then
      inst:Remove()
      return
    end
    if common.CanSpecialHealTarget(attacker, target) then
      if def.OnHealAlly then def.OnHealAlly(attacker, target) end
      SpawnHitAllyFx(target)
    elseif common.CanSpecialDestroyTarget(attacker, target) then
      if def.OnDestroy then def.OnDestroy(attacker, target) end
    else
      -- 基础伤害
      if def.damage and target.components.combat then
        target.components.combat:GetAttacked(attacker, def.damage)
      end
      if def.OnHarmEnemy then def.OnHarmEnemy(attacker, target) end
      SpawnHitEnemyFx(target)
    end
    if target.components.combat then
      target.components.combat:RemoveShouldAvoidAggro(attacker)
    end
    inst:Remove()
  end
end

local function OnMiss(inst, owner, target)
  inst:Remove()
end

-- ============================================================
-- Projectile factory
-- ============================================================
local function projectile_fn(def)
  local inst = CreateEntity()

  inst.entity:AddTransform()
  inst.entity:AddAnimState()
  inst.entity:AddSoundEmitter()
  inst.entity:AddNetwork()

  inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
  MakeProjectilePhysics(inst)

  inst.AnimState:SetBank("special_treatment_bullet")
  inst.AnimState:SetBuild("special_treatment_bullet")
  inst.AnimState:PlayAnimation(def.fly_anim, true)

  inst:AddTag("projectile")

  inst.entity:SetPristine()
  if not TheWorld.ismastersim then return inst end

  inst.persists = false

  inst:AddComponent("weapon")
  inst.components.weapon:SetDamage(0)

  inst:AddComponent("projectile")
  inst.components.projectile:SetSpeed(50)
  inst.components.projectile:SetHoming(false)
  inst.components.projectile:SetHitDist(1)
  inst.components.projectile:SetOnHitFn(MakeOnHit(def))
  inst.components.projectile:SetOnMissFn(OnMiss)
  inst.components.projectile:SetLaunchOffset(Vector3(1, 1, 0))
  inst.components.projectile.range = 30
  inst.components.projectile.has_damage_set = true

  return inst
end

-- ============================================================
-- Inventory item factory
-- ============================================================
local function inv_fn(def)
  local inst = CreateEntity()

  inst.entity:AddTransform()
  inst.entity:AddAnimState()
  inst.entity:AddSoundEmitter()
  inst.entity:AddNetwork()

  MakeInventoryPhysics(inst)
  inst.AnimState:SetRayTestOnBB(true)
  inst.AnimState:SetBank("special_treatment_bullet")
  inst.AnimState:SetBuild("special_treatment_bullet")
  inst.AnimState:PlayAnimation(def.idle_anim)
  MakeInventoryFloatable(inst, "small", .2, { .85, .9, .85 })

  inst.entity:SetPristine()
  if not TheWorld.ismastersim then return inst end

  inst:AddComponent("stackable")
  inst.components.stackable.maxsize = TUNING.STACK_SIZE_PELLET

  inst:AddComponent("inspectable")
  inst:AddComponent("inventoryitem")
  inst:AddComponent("tradable")
  inst:AddComponent("special_treatment_bullet")
  MakeHauntableLaunch(inst)

  return inst
end

-- ============================================================
-- Register prefabs + recipes
-- ============================================================
local all_prefabs = {}

for _, def in ipairs(ammo_defs) do
  table.insert(all_prefabs,
    Prefab(def.name, function() return inv_fn(def) end, assets, { def.name .. "_proj" }))
  table.insert(all_prefabs, Prefab(def.name .. "_proj", function() return projectile_fn(def) end, assets))
end

return unpack(all_prefabs)
