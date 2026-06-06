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

AddAction('SPECIAL_TREAT_HEAL', STRINGS.ACTIONS.HEAL.GENERIC, function(act)
  local doer   = act.doer
  local target = act.target
  if not doer or not target then return false end

  local gun = doer.components.inventory
      and doer.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
  if not gun or gun.prefab ~= "special_treatment_gun" or not gun:HasTag("ammoloaded") then
    return false
  end
  -- Mark next projectile as forced heal (overrides PvP enemy check)
  doer._next_shot_is_heal = true
  ArkLogger:Debug("SPECIAL_TREAT_HEAL action triggered by %s on %s with %s", doer, target, gun)
  return true
end)

-- 注册组件动作：右键点击玩家或玩家的宠物时显示"治疗"选项
AddComponentAction("EQUIPPED", "weapon", function(inst, doer, target, actions, right)
  if right or target == nil then
    return
  end
  if inst.prefab ~= "special_treatment_gun" then
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
AddStategraphActionHandler("wilson", ActionHandler(ACTIONS.SPECIAL_TREAT_HEAL, "dolongaction"))
AddStategraphActionHandler("wilson_client", ActionHandler(ACTIONS.SPECIAL_TREAT_HEAL, "dolongaction"))
table.insert(Assets, Asset("ANIM", "anim/special_treatment_gun_shoot.zip"))
AddPlayerPostInit(function(inst)
  inst.AnimState:AddOverrideBuild("special_treatment_gun_shoot")
end)

local function HasGunAndBullet(inst)
  local equiped = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
  if equiped and equiped.prefab == "special_treatment_gun" then
    if equiped.replica.container and equiped.replica.container:GetItemInSlot(1) then
      return true
    end
  end
  return false
end

-- ============================================================
-- 服务端状态图：拦截攻击状态，切换为凯尔希射击动画
-- ============================================================
AddStategraphPostInit("wilson", function(sg)
  ArkHookFunction(sg.states["attack"], "onenter", function(next, inst, ...)
    if HasGunAndBullet(inst) then
      inst.sg:GoToState("kaltsit_shoot")
      return
    end
    return next(inst, ...)
  end)
end)

AddStategraphState("wilson", State {
  name = "kaltsit_shoot",
  tags = { "attack", "notalking", "abouttoattack", "busy" },

  onenter = function(inst)
    if inst.components.rider:IsRiding() then
      inst.Transform:SetFourFaced()
    end
    local weapon = inst.components.combat:GetWeapon()
    if HasGunAndBullet(inst) then
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
    if HasGunAndBullet(inst) then
      inst.sg:GoToState("kaltsit_shoot")
      return
    end
    return next(inst, ...)
  end)
end)

AddStategraphState("wilson_client", State {
  name = "kaltsit_shoot",
  tags = { "attack", "notalking", "abouttoattack", "busy" },

  onenter = function(inst)
    if inst.components.rider:IsRiding() then
      inst.Transform:SetFourFaced()
    end
    if HasGunAndBullet(inst) then
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
