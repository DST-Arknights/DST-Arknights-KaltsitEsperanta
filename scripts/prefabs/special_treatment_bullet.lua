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

-- ============================================================
-- Effect interfaces（待实现）
-- ============================================================

-- 普通治疗弹（norm_heal_bullet）：恢复目标 10 点生命值
local function OnHit_NormHeal(inst, attacker, target)
    if target ~= nil and target.components.health then
        target.components.health:DoDelta(10, false, "norm_heal_bullet")
    end
end

-- 强效治疗弹（potent_heal_bullet）：4 秒内每秒恢复 5 点生命值及黑血，效果可叠加
local function OnHit_PotentHeal(inst, attacker, target)
    if target == nil then return end
    local function DoTick(remaining)
        if not target:IsValid() then return end
        if target.components.health and not target.components.health:IsDead() then
            target.components.health:DoDelta(5, false, "potent_heal_bullet")
            -- 同步恢复黑血（health penalty）
            if target.components.health.penalty ~= nil
                and target.components.health.penalty > 0 then
                local max_hp = target.components.health.maxhealth
                if max_hp and max_hp > 0 then
                    target.components.health.penalty = math.max(0,
                        target.components.health.penalty - 5 / max_hp)
                end
            end
        end
        if remaining > 1 then
            target:DoTaskInTime(1, function() DoTick(remaining - 1) end)
        end
    end
    DoTick(4)
end

-- 缓回治疗弹（regen_heal_bullet）：2 分钟内每 2 秒恢复 2 点生命值（共 120 血），
-- 持续时间内免疫昏睡与蜘蛛网减速，效果可叠加
local function _RegenAddImmunity(target)
    target._regen_bullet_stacks = (target._regen_bullet_stacks or 0) + 1
    if target._regen_bullet_stacks == 1 then
        target:AddTag("sleepimmune")
        target:AddTag("webimmune")
    end
end

local function _RegenRemoveImmunity(target)
    if not target:IsValid() then return end
    target._regen_bullet_stacks = math.max(0, (target._regen_bullet_stacks or 1) - 1)
    if target._regen_bullet_stacks == 0 then
        target:RemoveTag("sleepimmune")
        target:RemoveTag("webimmune")
    end
end

local function OnHit_RegenHeal(inst, attacker, target)
    if target == nil then return end
    _RegenAddImmunity(target)
    local function DoTick(remaining)
        if not target:IsValid() then
            _RegenRemoveImmunity(target)
            return
        end
        if target.components.health and not target.components.health:IsDead() then
            target.components.health:DoDelta(2, false, "regen_heal_bullet")
        end
        if remaining > 1 then
            target:DoTaskInTime(2, function() DoTick(remaining - 1) end)
        else
            _RegenRemoveImmunity(target)
        end
    end
    DoTick(60)  -- 60 次 × 2 秒 = 120 秒 = 2 分钟，共恢复 120 血
end

-- 特制治疗弹（trait_heal_bullet）：恢复目标 20 点生命值，将目标体温重置为 20°C
local function OnHit_TraitHeal(inst, attacker, target)
    if target == nil then return end
    if target.components.health then
        target.components.health:DoDelta(20, false, "trait_heal_bullet")
    end
    if target.components.temperature then
        target.components.temperature:SetTemperature(20)
    end
end

-- ============================================================
-- Ammo definitions
-- ============================================================
local ammo_defs = {
  {
    name      = "norm_heal_bullet",
    idle_anim = "norm_idle",
    fly_anim  = "norm_fly_loop",
    onhit     = OnHit_NormHeal,
  },
  {
    name      = "potent_heal_bullet",
    idle_anim = "potent_idle",
    fly_anim  = "potent_fly_loop",
    onhit     = OnHit_PotentHeal,
  },
  {
    name      = "regen_heal_bullet",
    idle_anim = "regen_idle",
    fly_anim  = "regen_fly_loop",
    onhit     = OnHit_RegenHeal,
  },
  {
    name      = "trait_heal_bullet",
    idle_anim = "trait_idle",
    fly_anim  = "trait_fly_loop",
    onhit     = OnHit_TraitHeal,
  },
}

-- ============================================================
-- Shared handlers
-- ============================================================
local function OnAttack(inst, attacker, target)
  if target ~= nil and target:IsValid() and attacker ~= nil and attacker:IsValid() then
    if inst.ammo_def ~= nil and inst.ammo_def.onhit ~= nil then
      inst.ammo_def.onhit(inst, attacker, target)
    end
  end
end

local function OnHit(inst, attacker, target)
  if target ~= nil and target:IsValid() and target.components.combat ~= nil then
    target.components.combat:RemoveShouldAvoidAggro(attacker)
  end
  inst:Remove()
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
  inst.ammo_def = def

  inst.entity:SetPristine()
  if not TheWorld.ismastersim then return inst end

  inst.persists = false

  inst:AddComponent("weapon")
  inst.components.weapon:SetDamage(0)
  inst.components.weapon:SetOnAttack(OnAttack)

  inst:AddComponent("projectile")
  inst.components.projectile:SetSpeed(80)
  inst.components.projectile:SetHoming(false)
  inst.components.projectile:SetHitDist(0)
  inst.components.projectile:SetOnHitFn(OnHit)
  inst.components.projectile:SetOnMissFn(OnMiss)
  inst.components.projectile:SetLaunchOffset(Vector3(1, 1, 0))
  inst.components.projectile.range = 30

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

  inst.ammo_def = def

  inst:AddComponent("stackable")
  inst.components.stackable.maxsize = TUNING.STACK_SIZE_PELLET

  inst:AddComponent("inspectable")
  inst:AddComponent("inventoryitem")
  inst:AddComponent("tradable")
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
