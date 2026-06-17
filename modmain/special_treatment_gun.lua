local common = require("kaltsit_esperanta_common")

local function CanEnterSpecialTreatmentShootState(inst)
  if common.HasEquippedLoadedSpecialTreatmentGun(inst) then
    return true
  end

  return common.HasEquippedSpecialTreatmentGun(inst)
      and common.IsSpecialTreatmentDestroySkillActive(inst)
end

-- scripts/prefabs/special_treatment_gun.lua
-- 特质治疗枪 + 三种治疗弹 + 各自独立投射物
-- 弹药机制: 枪上有 1 格物品槽，将治疗弹放入后方可发射

-- ============================================================
-- 容器定义（在 containers.data 中注册，供 WidgetSetup 使用）
-- ============================================================
local containers = require "containers"
containers.params.special_treatment_gun =
{
  widget =
  {
    slotpos =
    {
      Vector3(0, 32 + 4, 0),
    },
    slotbg =
    {
      { image = "slingshot_ammo_slot.tex" },
    },
    animbank = "ui_cookpot_1x2",
    animbuild = "ui_cookpot_1x2",
    pos = Vector3(0, 15, 0),
  },
  type = "hand_inv",
  excludefromcrafting = true,
  itemtestfn = function(container, item, slot)
    return not container.inst._unloading and item:HasTag("special_treatment_bullet")
  end,
}

-- 配方: 治疗枪 , 1齿轮1绿宝石10金子, 无需科技, 仅凯尔希可制作
AddCharacterRecipe("special_treatment_gun",
  { Ingredient("gears", 1), Ingredient("greengem", 1), Ingredient("goldnugget", 10) }, TECH.NONE, {
    builder_tag = "kaltsit_esperanta",
  })

AddAction('SPECIAL_GUN_HEAL', STRINGS.ACTIONS.HEAL.GENERIC, function(act)
  local doer   = act.doer
  local target = act.target
  if not doer or not target then return false end
  if not common.CanTriggerSpecialTreatmentHealAction(doer, target) then
    return false
  end
  act.doer.components.combat:DoAttack(act.target)
  return true
end)

ACTIONS.SPECIAL_GUN_HEAL.canforce = true
ACTIONS.SPECIAL_GUN_HEAL.mount_valid = true
ACTIONS.SPECIAL_GUN_HEAL.invalid_hold_action = true
ACTIONS.SPECIAL_GUN_HEAL.customarrivecheck = function(inst, dest)
  if not dest or not dest.inst then return false, true end
  local range = inst.replica.combat and inst.replica.combat:GetAttackRangeWithWeapon()
  local reached_dest = inst:GetDistanceSqToInst(dest.inst)
  if range then
    return reached_dest <= range * range, false
  end
  return reached_dest <= 2, false
end

AddAction("SPECIAL_GUN_DESTROY", STRINGS.ACTIONS.DESTROY.GENERIC, function(act)
  local doer   = act.doer
  local target = act.target
  if not doer or not target then return false end
  if not common.CanTriggerSpecialTreatmentDestroyAction(doer, target) then
    return false
  end
  -- local gun = PrepareDestroyProjectileForAttack(doer)
  act.doer.components.combat:DoAttack(act.target)
  -- RestoreProjectileAfterAttack(gun)
  return true
end)

ACTIONS.SPECIAL_GUN_DESTROY.canforce = true
ACTIONS.SPECIAL_GUN_DESTROY.mount_valid = true
ACTIONS.SPECIAL_GUN_DESTROY.invalid_hold_action = true
ACTIONS.SPECIAL_GUN_DESTROY.priority = 10
ACTIONS.SPECIAL_GUN_DESTROY.customarrivecheck = function(inst, dest)
  if not dest or not dest.inst then return false, true end
  local range = inst.replica.combat and inst.replica.combat:GetAttackRangeWithWeapon()
  local reached_dest = inst:GetDistanceSqToInst(dest.inst)
  if range then
    return reached_dest <= range * range, false
  end
  return reached_dest <= 2, false
end

-- 注册组件动作：点击玩家或玩家的宠物时显示"治疗"选项
AddComponentAction("EQUIPPED", "weapon", function(inst, doer, target, actions, right)
  if right or target == nil then
    return
  end
  if common.IsSpecialTreatmentGun(inst) and common.CanTriggerSpecialTreatmentHealAction(doer, target) then
    table.insert(actions, ACTIONS.SPECIAL_GUN_HEAL)
  elseif common.IsSpecialTreatmentGun(inst) and common.CanTriggerSpecialTreatmentDestroyAction(doer, target) then
    table.insert(actions, ACTIONS.SPECIAL_GUN_DESTROY)
  end
end)

-- 状态图动作处理器（适用于 wilson 系角色）
AddStategraphActionHandler("wilson", ActionHandler(ACTIONS.SPECIAL_GUN_HEAL, "kaltsit_shoot"))
AddStategraphActionHandler("wilson_client", ActionHandler(ACTIONS.SPECIAL_GUN_HEAL, "kaltsit_shoot"))
AddStategraphActionHandler("wilson", ActionHandler(ACTIONS.SPECIAL_GUN_DESTROY, "kaltsit_shoot"))
AddStategraphActionHandler("wilson_client", ActionHandler(ACTIONS.SPECIAL_GUN_DESTROY, "kaltsit_shoot"))

table.insert(Assets, Asset("ANIM", "anim/special_treatment_gun_shoot.zip"))
AddPlayerPostInit(function(inst)
  inst.AnimState:AddOverrideBuild("special_treatment_gun_shoot")
end)

AddStategraphPostInit("wilson", function(sg)
  ArkHookFunction(sg.states["attack"], "onenter", function(next, inst, ...)
    if CanEnterSpecialTreatmentShootState(inst) then
      inst.sg:GoToState("kaltsit_shoot")
      return
    end
    return next(inst, ...)
  end)
end)
AddStategraphPostInit("wilson_client", function(sg)
  ArkHookFunction(sg.states["attack"], "onenter", function(next, inst, ...)
    if CanEnterSpecialTreatmentShootState(inst) then
      inst.sg:GoToState("kaltsit_shoot")
      return
    end
    return next(inst, ...)
  end)
end)

AddStategraphState("wilson", State {
  name = "kaltsit_shoot",
  tags = { "attack", "notalking", "abouttoattack" },

  onenter = function(inst)
    ArkLogger:Debug("Entering kaltsit_shoot state for", inst)
    if inst.components.rider:IsRiding() then
      inst.Transform:SetFourFaced()
    end
    if CanEnterSpecialTreatmentShootState(inst) then
      inst.AnimState:PlayAnimation("special_treatment_gun_shoot")
    else
      inst.sg:GoToState("idle")
      return
    end

    if inst.components.combat.target then
      inst.components.combat:BattleCry()
      if inst.components.combat.target and inst.components.combat.target:IsValid() then
        inst:FacePoint(Point(inst.components.combat.target.Transform:GetWorldPosition()))
      end
    end
    inst.sg.statemem.target = inst.components.combat.target
    inst.components.combat:StartAttack()
    inst.components.locomotor:Stop()
  end,

  onexit = function(inst)
    if inst.components.rider:IsRiding() then
      inst.Transform:SetSixFaced()
    end
  end,

  timeline =
  {
    TimeEvent(17 * FRAMES, function(inst)
      inst:PerformBufferedAction()
      inst.sg:RemoveStateTag("abouttoattack")
    end),
    TimeEvent(20 * FRAMES, function(inst)
      inst.sg:RemoveStateTag("attack")
    end),
  },

  events =
  {
    EventHandler("animover", function(inst)
      inst.sg:GoToState("idle")
    end),
  },
})

AddStategraphState("wilson_client", State {
  name = "kaltsit_shoot",
  tags = { "attack", "notalking", "abouttoattack" },

  onenter = function(inst)
    if inst.components.rider:IsRiding() then
      inst.Transform:SetFourFaced()
    end
    if CanEnterSpecialTreatmentShootState(inst) then
      inst.AnimState:PlayAnimation("special_treatment_gun_shoot")
    else
      inst.sg:GoToState("idle")
      return
    end

    -- 客户端仅播放动画，战斗逻辑由服务端处理
    inst.components.locomotor:Stop()
  end,

  onexit = function(inst)
    if inst.components.rider:IsRiding() then
      inst.Transform:SetSixFaced()
    end
  end,

  timeline =
  {
    TimeEvent(17 * FRAMES, function(inst)
      inst:PerformPreviewBufferedAction()
      inst.sg:RemoveStateTag("abouttoattack")
    end),
    TimeEvent(20 * FRAMES, function(inst)
      inst.sg:RemoveStateTag("attack")
    end),
  },

  events =
  {
    EventHandler("animover", function(inst)
      inst.sg:GoToState("idle")
    end),
  },
})

-- 友方以及树木可被持枪者发射弹药. 但这里不允许子弹触发伤害
AddComponentPostInit("combat", function(self)
  ArkHookFunction(self, "CanHitTarget", function(next, self, target, weapon)
    if common.IsSpecialTreatmentGun(weapon) then
      if common.CanHitSpecialTreatmentHealTarget(self.inst, target) then
        return true
      end
      if common.CanHitSpecialTreatmentDestroyTarget(self.inst, target) then
        return true
      end
    end
    local res = { next(self, target, weapon) }
    ArkLogger:Debug("Combat:CanHitTarget result for", self.inst, "attacking", target, "with weapon", weapon, "is", unpack(res))
    return unpack(res)
  end)
end)

-- 弹药装填
AddAction("RELOAD_SPECIAL_TREATMENT_GUN", STRINGS.ACTIONS.RELOAD_SPECIAL_TREATMENT_GUN.GENERIC, function(act)
  local doer = act.doer
  local target = act.invobject
  if not doer or not target then return false end
  local hold = common.GetEquippedSpecialTreatmentGun(doer)
  if not common.IsSpecialTreatmentGun(hold) then return false end
  -- 弹药取出
  local bullet = doer.components.inventory:RemoveItem(target, true)
  if not bullet then return false end
  local loaded_bullet = common.GetSpecialTreatmentGunLoadedAmmo(hold)
  -- 检查持有弹药, 有不同类型的就取出
  if loaded_bullet and loaded_bullet.prefab ~= bullet.prefab then
    local unloaded_bullet = hold.components.container:RemoveItem(loaded_bullet, true)
    if unloaded_bullet then
      unloaded_bullet.prevslot = bullet.prevslot
      unloaded_bullet.prevcontainer = bullet.prevcontainer
      local res = { hold.components.container:GiveItem(bullet) }
      doer.components.inventory:GiveItem(unloaded_bullet)
      return unpack(res)
    end
  end
  return hold.components.container:GiveItem(bullet)
end)

ACTIONS.RELOAD_SPECIAL_TREATMENT_GUN.priority = 10

-- 弹药卸下：打标记阻止容器回塞，从枪中取出弹药放入物品栏，满了则扔地上
AddAction("UNLOAD_SPECIAL_TREATMENT_GUN", STRINGS.ACTIONS.UNLOAD_SPECIAL_TREATMENT_GUN.GENERIC, function(act)
  local doer = act.doer
  local target = act.invobject
  if not doer or not target then return false end
  local hold = common.GetEquippedSpecialTreatmentGun(doer)
  if not common.IsSpecialTreatmentGun(hold) then return false end
  -- 只有当前已装填的弹药才能卸下
  local loaded_bullet = common.GetSpecialTreatmentGunLoadedAmmo(hold)
  if loaded_bullet ~= target then return false end
  -- 打上卸载标记，防止 GiveItem 把弹药重新塞回枪
  hold._unloading = true
  local bullet = hold.components.container:RemoveItem(target, true)
  if bullet then
    doer.components.inventory:GiveItem(bullet)
  end
  hold._unloading = nil
  return bullet ~= nil
end)

ACTIONS.UNLOAD_SPECIAL_TREATMENT_GUN.priority = 10

AddComponentAction("INVENTORY", "special_treatment_bullet", function(inst, doer, actions, right)
  local gun = common.GetEquippedSpecialTreatmentGun(doer)
  if not gun then return end
  local inGun = common.GetSpecialTreatmentGunLoadedAmmo(gun) == inst
  if inGun then
    -- 弹药在枪里：显示"卸下"
    table.insert(actions, ACTIONS.UNLOAD_SPECIAL_TREATMENT_GUN)
  else
    -- 弹药在物品栏：显示"装填"
    table.insert(actions, ACTIONS.RELOAD_SPECIAL_TREATMENT_GUN)
  end
end)

AddStategraphActionHandler("wilson", ActionHandler(ACTIONS.RELOAD_SPECIAL_TREATMENT_GUN, "doshortaction"))
AddStategraphActionHandler("wilson_client", ActionHandler(ACTIONS.RELOAD_SPECIAL_TREATMENT_GUN, "doshortaction"))
AddStategraphActionHandler("wilson", ActionHandler(ACTIONS.UNLOAD_SPECIAL_TREATMENT_GUN, "doshortaction"))
AddStategraphActionHandler("wilson_client", ActionHandler(ACTIONS.UNLOAD_SPECIAL_TREATMENT_GUN, "doshortaction"))
