local ATTACK_STATE = "kaltsit_mon3tr_claw_attack"

local function HasClaw(inst)
  if inst.prefab ~= "kaltsit_esperanta_mon3tr" then
    return false
  end
  local userid = inst.Network:GetUserID()
  local claw = inst._kaltsit_mon3tr_claw
  return (userid == nil or userid == "") and claw ~= nil and claw:IsValid()
end

local function ResetClaw(inst)
  local claw = inst._kaltsit_mon3tr_claw
  if claw ~= nil and claw:IsValid() then
    claw.AnimState:PlayAnimation("idle", true)
    claw.AnimState:SetDeltaTimeMultiplier(1)
    claw.AnimState:SetFinalOffset(1)
  end
end

AddStategraphState("wilson", State {
  name = ATTACK_STATE,
  tags = { "attack", "notalking", "abouttoattack" },
  onenter = function(inst)
    local combat = inst.components.combat
    if not HasClaw(inst) or combat:InCooldown() then
      inst.sg:RemoveStateTag("abouttoattack")
      inst:ClearBufferedAction()
      inst.sg:GoToState("idle", true)
      return
    end

    local action = inst:GetBufferedAction()
    local target = action ~= nil and action.target or nil
    combat:SetTarget(target)
    combat:StartAttack()
    inst.components.locomotor:Stop()
    inst.sg.statemem.attacktarget = target
    inst.sg.statemem.retarget = target
    if target ~= nil and target:IsValid() then
      combat:BattleCry()
      inst:FacePoint(target:GetPosition())
    elseif action ~= nil then
      local point = action:GetActionPoint()
      if point ~= nil then
        inst:FacePoint(point)
      end
    end

    inst.AnimState:PlayAnimation("atk")
    -- 身体动作结束后回到待机表现，但仍等现有空手攻击间隔结束。
    inst.AnimState:PushAnimation("idle_loop", true)
    local claw = inst._kaltsit_mon3tr_claw
    claw.AnimState:PlayAnimation("atk")
    claw.AnimState:PushAnimation("idle", true)
    -- 原武装在第 7 帧命中；放慢至 7/8，配合现有第 8 帧出手。
    claw.AnimState:SetDeltaTimeMultiplier(31 / 13 * 7 / 8)
    claw.AnimState:SetFinalOffset(3)
    inst.sg:SetTimeout(math.max(combat.min_attack_period, 24 * FRAMES))
  end,
  timeline = {
    TimeEvent(8 * FRAMES, function(inst)
      if not HasClaw(inst) then
        inst:ClearBufferedAction()
        inst.sg:GoToState("idle")
        return
      end
      -- 工作模式的 ATTACK 成功回调也在这里执行，不能改为直接 DoAttack。
      inst.sg.statemem.recoilstate = "attack_recoil"
      inst:PerformBufferedAction()
      inst.sg:RemoveStateTag("abouttoattack")
      inst.SoundEmitter:PlaySound("dontstarve/wilson/attack_weapon", nil, nil, true)
    end),
  },
  ontimeout = function(inst)
    inst.sg:GoToState("idle")
  end,
  onexit = function(inst)
    inst.components.combat:SetTarget(nil)
    if inst.sg:HasStateTag("abouttoattack") then
      inst.components.combat:CancelAttack()
    end
    ResetClaw(inst)
  end,
  events = {
    EventHandler("equip", function(inst) inst.sg:GoToState("idle") end),
    EventHandler("unequip", function(inst) inst.sg:GoToState("idle") end),
  },
})

AddStategraphPostInit("wilson", function(sg)
  local handler = sg.actionhandlers[ACTIONS.ATTACK]
  ArkHookFunction(handler, "deststate", function(next, inst, action)
    -- 先保留原入口的死亡、连击及特殊武器判定，只替换普通 attack。
    local state = next(inst, action)
    return state == "attack" and HasClaw(inst) and ATTACK_STATE or state
  end)
end)
