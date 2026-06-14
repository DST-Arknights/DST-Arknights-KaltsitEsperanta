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
}

-- 配方: 治疗枪 , 1齿轮1绿宝石10金子, 无需科技, 仅凯尔希可制作
AddCharacterRecipe("special_treatment_gun",
  { Ingredient("gears", 1), Ingredient("greengem", 1), Ingredient("goldnugget", 10) }, TECH.NONE, {
    builder_tag = "kaltsit_esperanta",
  })

local function IsGun(inst)
  return inst and inst.prefab == "special_treatment_gun"
      and inst.replica.container
end

local function GetGunBullet(inst)
  return inst.replica.container and inst.replica.container:GetItemInSlot(1) or nil
end

local function IsGunAndBullet(inst)
  return IsGun(inst) and GetGunBullet(inst) ~= nil
end
local function HoldGun(inst)
  if not inst or not inst.replica.inventory then return false end
  local equiped = inst.replica.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
  return IsGun(equiped) and equiped
end

local function HoldGunAndBullet(inst)
  local gun = HoldGun(inst)
  return IsGunAndBullet(gun)
end

AddAction('SPECIAL_TREAT_HEAL', STRINGS.ACTIONS.HEAL.GENERIC, function(act)
  local doer   = act.doer
  local target = act.target
  if not doer or not target then return false end
  if not HoldGunAndBullet(doer) then
    return false
  end
  -- Mark next projectile as forced heal (overrides PvP enemy check)
  doer._next_shot_is_heal = true
  act.doer.components.combat:DoAttack(act.target)
  return true
end)

ACTIONS.SPECIAL_TREAT_HEAL.canforce = true
ACTIONS.SPECIAL_TREAT_HEAL.mount_valid = true
ACTIONS.SPECIAL_TREAT_HEAL.invalid_hold_action = true
ACTIONS.SPECIAL_TREAT_HEAL.customarrivecheck = function(inst, dest)
  if not dest or not dest.inst then return false, true end
  local range = inst.replica.combat and inst.replica.combat:GetAttackRangeWithWeapon()
  local reached_dest = inst:GetDistanceSqToInst(dest.inst)
  if range then
    return reached_dest <= range * range, false
  end
  return reached_dest <= 2, false
end

-- 注册组件动作：右键点击玩家或玩家的宠物时显示"治疗"选项
AddComponentAction("EQUIPPED", "weapon", function(inst, doer, target, actions, right)
  if right or target == nil then
    return
  end
  if not IsGunAndBullet(inst) then
    return
  end
  if target == doer or target:HasTag("player") then
    table.insert(actions, ACTIONS.SPECIAL_TREAT_HEAL)
    return
  end
  local leader = target.replica.follower and target.replica.follower:GetLeader()
  if leader and leader:HasTag("player") then
    table.insert(actions, ACTIONS.SPECIAL_TREAT_HEAL)
    return
  end
end)

-- 状态图动作处理器（适用于 wilson 系角色）
AddStategraphActionHandler("wilson", ActionHandler(ACTIONS.SPECIAL_TREAT_HEAL, "kaltsit_shoot"))
AddStategraphActionHandler("wilson_client", ActionHandler(ACTIONS.SPECIAL_TREAT_HEAL, "kaltsit_shoot"))

table.insert(Assets, Asset("ANIM", "anim/special_treatment_gun_shoot.zip"))
AddPlayerPostInit(function(inst)
  inst.AnimState:AddOverrideBuild("special_treatment_gun_shoot")
end)

-- ============================================================
-- 服务端状态图：拦截攻击状态，切换为凯尔希射击动画
-- ============================================================
AddStategraphPostInit("wilson", function(sg)
  ArkHookFunction(sg.states["attack"], "onenter", function(next, inst, ...)
    if HoldGunAndBullet(inst) then
      inst.sg:GoToState("kaltsit_shoot")
      return
    end
    return next(inst, ...)
  end)
end)

AddStategraphState("wilson", State {
  name = "kaltsit_shoot",
  tags = { "attack", "notalking", "abouttoattack"},

  onenter = function(inst)
    if inst.components.rider:IsRiding() then
      inst.Transform:SetFourFaced()
    end
    if HoldGunAndBullet(inst) then
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

-- ============================================================
-- 客户端状态图：同步显示凯尔希持枪射击动画
-- ============================================================
AddStategraphPostInit("wilson_client", function(sg)
  ArkHookFunction(sg.states["attack"], "onenter", function(next, inst, ...)
    if HoldGunAndBullet(inst) then
      inst.sg:GoToState("kaltsit_shoot")
      return
    end
    return next(inst, ...)
  end)
end)

AddStategraphState("wilson_client", State {
  name = "kaltsit_shoot",
  tags = { "attack", "notalking", "abouttoattack" },

  onenter = function(inst)
    if inst.components.rider:IsRiding() then
      inst.Transform:SetFourFaced()
    end
    if HoldGunAndBullet(inst) then
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

AddClassPostConstruct("components/combat_replica", function(self)
  ArkHookFunction(self, "CanBeAttacked", function(next, self, attacker)
    local weapon = attacker.replica.combat and attacker.replica.combat:GetWeapon()
    if IsGunAndBullet(weapon) then
      return true
    end
    return next(self, attacker)
  end)
end)

AddAction("RELOAD_SPECIAL_TREATMENT_GUN", STRINGS.ACTIONS.RELOAD_SPECIAL_TREATMENT_GUN.GENERIC, function(act)
  local doer = act.doer
  local target = act.target
  if not doer or not target then return false end
  local hold = HoldGun(doer)
  if not IsGun(hold) then return false end
  -- 弹药取出
  local bullet = doer.components.inventory:RemoveItem(target, true)
  if not bullet then return false end
  local loaded_bullet = GetGunBullet(hold)
  -- 检查持有弹药, 有不同类型的就取出
  if loaded_bullet and loaded_bullet.prefab ~= bullet.prefab then
    local unloaded_bullet = hold.components.container:RemoveItemBySlot(1, true)
    if unloaded_bullet then
      doer.components.inventory:GiveItem(unloaded_bullet)
    end
  end
  local stack_size = bullet.components.stackable and bullet.components.stackable:StackSize() or 1
  return hold.components.container:GiveItem(bullet, stack_size) 
end)

ACTIONS.RELOAD_SPECIAL_TREATMENT_GUN.priority = 10

AddComponentAction("INVENTORY", "special_treatment_bullet", function(inst, doer, actions, right)
  ArkLogger:Info("Checking reload action for", inst, "held by", doer, "right click?", right)
  if not right then return end
  local gun = HoldGun(doer)
  ArkLogger:Debug("Adding reload action for %s with gun %s", inst, gun)
  if not gun then return end
  table.insert(actions, ACTIONS.RELOAD_SPECIAL_TREATMENT_GUN)
end)

AddStategraphActionHandler("wilson", ActionHandler(ACTIONS.RELOAD_SPECIAL_TREATMENT_GUN, "doshortaction"))
AddStategraphActionHandler("wilson_client", ActionHandler(ACTIONS.RELOAD_SPECIAL_TREATMENT_GUN, "doshortaction"))
