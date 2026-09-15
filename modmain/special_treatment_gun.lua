local common = require("kaltsit_esperanta_common")

local function CanEnterSpecialTreatmentShootState(inst)
  if common.HasEquippedLoadedSpecialTreatmentGun(inst) then
    return true
  end

  return common.HasEquippedSpecialTreatmentGun(inst)
      and common.IsSpecialTreatmentDestroySkillActive(inst)
end

-- rider: 服务端有 components.rider, 客户端只有 replica.rider, 两边都用 replica 判定
local function IsRiding(inst)
  local rider = inst.replica.rider or inst.components.rider
  return rider ~= nil and rider:IsRiding()
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

-- ============================================================
-- 射击到达判定（customarrivecheck）
-- 联机版约定: customarrivecheck(doer, dest)，dest 是 locomotor 的 Dest（locomotor.dest），
-- 字段为 inst / pt / buffered_action，它有两种形态:
--   1) 客户端自己走向实体目标: LocoMotor:GoToEntity -> Dest(target)，dest.inst = 目标实体
--   2) 预测客户端把动作交回服务端: PlayerController:OnRemoteLeftClick 对 canforce 动作做
--      lmb:SetActionPoint(客户端预测位置) + lmb.forced = true，于是 LocoMotor:PushAction 走
--      forced 分支 -> GoToPoint(nil, ...)，Dest 只有 buffered_action，dest.inst == nil
-- 形态 2 只在“预测客户端”发生：非预测客户端的 non_preview_cb 会带 noforce = action.canforce，
-- 服务端因此不会改写动作点（playercontroller.lua OnLeftClick 两处 SendRPCToServer）。
-- 旧写法对形态 2 返回 (false, true)，而 invalid == true 会让 LocoMotor:OnUpdate 直接
-- Stop() + Clear() 丢掉整个动作（locomotor.lua OnUpdate 的 `if invalid then` 分支），
-- 表现就是“客户端播了射击动画，服务端没开火、没子弹、没伤害”。
-- 拿不到实体目标时按已到位处理，最终距离校验交给 combat:DoAttack / Combat:CanHitTarget。
local function ShootArriveCheck(doer, dest)
  if dest == nil or not dest:IsValid() then
    return false, true
  end

  -- 优先用实体目标判定；只有坐标时退回当前动作携带的目标实体
  local target = dest.inst
  if target == nil then
    local bufferedaction = doer.GetBufferedAction ~= nil and doer:GetBufferedAction() or nil
    target = bufferedaction ~= nil and bufferedaction.target or nil
  end
  if target == nil or not target:IsValid() then
    -- 坐标目标: 服务端只拿到客户端预测位置，判定为已到位，让动作正常派发
    return true, false
  end

  local combat = doer.replica.combat
  local range = (combat ~= nil and combat:GetAttackRangeWithWeapon())
      or TUNING.SPECIAL_TREATMENT_GUN_RANGE_SHOOT
      or 2
  return doer:GetDistanceSqToInst(target) <= range * range, false
end

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

-- canforce: 目标在枪的射程内时允许直接开枪，不必先走到目标跟前（同原版 ATTACK）。
-- 与 ShootArriveCheck 配合工作：客户端负责走近到射程内，服务端拿坐标目标时不再二次判定。
ACTIONS.SPECIAL_GUN_HEAL.canforce = true
ACTIONS.SPECIAL_GUN_HEAL.mount_valid = true
ACTIONS.SPECIAL_GUN_HEAL.invalid_hold_action = true
ACTIONS.SPECIAL_GUN_HEAL.customarrivecheck = ShootArriveCheck

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

ACTIONS.SPECIAL_GUN_DESTROY.mount_valid = true
ACTIONS.SPECIAL_GUN_DESTROY.invalid_hold_action = true
ACTIONS.SPECIAL_GUN_DESTROY.priority = 10
ACTIONS.SPECIAL_GUN_DESTROY.canforce = true
ACTIONS.SPECIAL_GUN_DESTROY.customarrivecheck = ShootArriveCheck

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

-- 联机版标准做法: 攻击进入哪个状态由 ATTACK 的 ActionHandler.deststate 决定
-- （SGwilson / SGwilson_client 里 slingshot -> "slingshot_shoot" 就是这一套）。
-- 旧写法 hook 了 attack 状态的 onenter 再 GoToState，等于“先进入 attack 再链式跳转”，
-- 服务端会白进一次 attack，预测客户端还会多一次状态切换（newstate 反向触发）。
-- 这里改成包一层 deststate: 装备可开火的治疗枪时直接返回 "kaltsit_shoot"，其余情况原样交还原实现。
local function RedirectAttackToShootState(sgname)
  AddStategraphPostInit(sgname, function(sg)
    local handler = sg.actionhandlers ~= nil and sg.actionhandlers[ACTIONS.ATTACK] or nil
    local original = handler ~= nil and handler.deststate or nil
    if type(original) ~= "function" then
      return
    end
    handler.deststate = function(inst, action)
      -- 与原版 ATTACK handler 一致: 已经在攻击同一个目标、或已死亡时不再进入新状态
      -- （SGwilson.lua 的 ATTACK ActionHandler / SGwilson_client.lua 的同名 handler）
      local playercontroller = inst.components.playercontroller
      local attack_tag =
          playercontroller ~= nil and
          playercontroller.remote_authority and
          playercontroller.remote_predicting and
          "abouttoattack" or
          "attack"
      local health = inst.replica.health or inst.components.health
      if inst.sg == nil
          or (inst.sg:HasStateTag(attack_tag) and action.target == inst.sg.statemem.attacktarget)
          or (health ~= nil and health:IsDead()) then
        return
      end
      if CanEnterSpecialTreatmentShootState(inst) then
        -- 与 SGwilson 的 ATTACK handler 保持一致，避免影响连击判定
        if inst.sg ~= nil then
          inst.sg.mem.localchainattack = not action.forced or nil
        end
        return "kaltsit_shoot"
      end
      return original(inst, action)
    end
  end)
end
RedirectAttackToShootState("wilson")
RedirectAttackToShootState("wilson_client")

AddStategraphState("wilson", State {
  name = "kaltsit_shoot",
  tags = { "attack", "notalking", "abouttoattack" },

  onenter = function(inst)
    ArkLogger:Debug("Entering kaltsit_shoot state for", inst)
    if IsRiding(inst) then
      inst.Transform:SetFourFaced()
    end
    if not CanEnterSpecialTreatmentShootState(inst) then
      inst:ClearBufferedAction()
      inst.sg:GoToState("idle")
      return
    end
    inst.AnimState:PlayAnimation("special_treatment_gun_shoot")

    -- 目标以当前动作为准（ATTACK / HEAL / DESTROY 都由动作携带目标），同原版 attack / slingshot_shoot。
    -- 朝向决定投射物出膛方向（weapon:SetProjectileOffset + projectile launchoffset 都按角色朝向算）。
    local buffaction = inst:GetBufferedAction()
    local target = (buffaction ~= nil and buffaction.target) or inst.components.combat.target
    if inst.components.combat.target ~= nil then
      inst.components.combat:BattleCry()
    end
    if target ~= nil and target:IsValid() then
      inst:FacePoint(Point(target.Transform:GetWorldPosition()))
    end
    inst.sg.statemem.target = target
    inst.sg.statemem.attacktarget = target
    inst.sg.statemem.retarget = target

    inst.components.combat:StartAttack()
    inst.components.locomotor:Stop()
  end,

  onexit = function(inst)
    if IsRiding(inst) then
      inst.Transform:SetSixFaced()
    end
    inst.sg.statemem.target = nil
    inst.sg.statemem.attacktarget = nil
    inst.sg.statemem.retarget = nil
    inst:ClearBufferedAction()
    -- 出手帧之前被打断: 取消这次攻击，同原版 SGwilson 的 attack 状态
    if inst.sg:HasStateTag("abouttoattack") and inst.components.combat ~= nil then
      inst.components.combat:CancelAttack()
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
    EventHandler("equip", function(inst) inst.sg:GoToState("idle") end),
    EventHandler("unequip", function(inst) inst.sg:GoToState("idle") end),
    EventHandler("animqueueover", function(inst)
      if inst.AnimState:AnimDone() then
        inst.sg:GoToState("idle")
      end
    end),
  },
})

-- 预测状态的自结束兜底(秒)。动画本身结束时会先走 animqueueover，这里只在异常情况下兜底，
-- 取值与 SGwilson_client 的 TIMEOUT 一致，避免截断较长的动画。
local KALTSIT_SHOOT_TIMEOUT = 2

AddStategraphState("wilson_client", State {
  name = "kaltsit_shoot",
  tags = { "attack", "notalking", "abouttoattack" },

  onenter = function(inst)
    -- 与 SGwilson_client.attack 一致: 客户端自己也走攻击冷却，避免重复预测开火
    local combat = inst.replica.combat
    if combat == nil or combat:InCooldown() then
      inst.sg:RemoveStateTag("abouttoattack")
      inst:ClearBufferedAction()
      inst.sg:GoToState("idle", true)
      return
    end
    if not CanEnterSpecialTreatmentShootState(inst) then
      inst:ClearBufferedAction()
      inst.sg:GoToState("idle")
      return
    end
    if IsRiding(inst) then
      inst.Transform:SetFourFaced()
    end

    combat:StartAttack()
    inst.components.locomotor:Stop()
    inst.AnimState:PlayAnimation("special_treatment_gun_shoot")

    -- 联机版标准: 预测状态在 onenter 就把动作交给服务端
    -- （PerformPreviewBufferedAction -> PlayerController:RemoteBufferedAction -> preview_cb -> RPC）。
    -- 拖到出手帧才发，服务端开火会晚于客户端动画；动作中途被打断时还会整发丢失。
    local buffaction = inst:GetBufferedAction()
    if buffaction ~= nil then
      if buffaction.preview_cb ~= nil then
        inst:PerformPreviewBufferedAction()
      else
        -- 正常点击路径（PlayerController:OnLeftClick / 手柄）一定会带 preview_cb；
        -- 这里只是兜底，避免异常路径把动作直接抛进 RemoteBufferedAction 报错
        ArkLogger:Debug("kaltsit_shoot: buffered action has no preview_cb, skip RPC", buffaction.action)
      end
      if buffaction.target ~= nil and buffaction.target:IsValid() then
        inst:FacePoint(buffaction.target:GetPosition())
        inst.sg.statemem.attacktarget = buffaction.target
        inst.sg.statemem.retarget = buffaction.target
      end
    end

    inst.sg:SetTimeout(KALTSIT_SHOOT_TIMEOUT)
  end,

  ontimeout = function(inst)
    inst:ClearBufferedAction()
    inst.sg:GoToState("idle")
  end,

  onexit = function(inst)
    if IsRiding(inst) then
      inst.Transform:SetSixFaced()
    end
    -- 出手前就被打断: 取消这次攻击冷却（与 SGwilson_client.attack 的 onexit 一致）
    if inst.sg:HasStateTag("abouttoattack") and inst.replica.combat ~= nil then
      inst.replica.combat:CancelAttack()
    end
  end,

  timeline =
  {
    TimeEvent(17 * FRAMES, function(inst)
      -- 出手帧: 动作已在 onenter 上报给服务端，客户端只清理本地预测状态
      inst:ClearBufferedAction()
      inst.sg:RemoveStateTag("abouttoattack")
    end),
    TimeEvent(20 * FRAMES, function(inst)
      inst.sg:RemoveStateTag("attack")
    end),
  },

  events =
  {
    EventHandler("animqueueover", function(inst)
      if inst.AnimState:AnimDone() then
        inst.sg:GoToState("idle")
      end
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
