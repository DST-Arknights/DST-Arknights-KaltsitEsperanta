-- ============================================================
-- 战术锚点：点击折跃（懒人魔杖 / The Lazy Explorer 风格）
-- ============================================================
-- 其他玩家（含凯尔希）点击锚点 -> 折跃到锚点位置。
-- 每个目标仅能折跃一次（锚点组件按目标 GUID 记录，经 OnSave/OnLoad 存档）。
--
-- 动作链路（源码验证）：
--   拾取器自动触发：PlayerActionPicker 拾取 -> DoAction -> LocoMotor:PushAction
--                    -> PushBufferedAction -> SG(quicktele) -> PerformBufferedAction -> fn
--   手动直接触发：PlayerController:DoAction(BufferedAction(...)) -> LocoMotor:PushAction
--                  -> PushBufferedAction -> SG -> PerformBufferedAction -> fn
--   两条链路汇合于同一 fn，最大化代码复用。
--
-- 折跃表现：复用原版懒人魔杖（orange staff）的 quicktele 状态（SGwilson/SGwilson_client
--   内建，服务端/客户端均已加载）。quicktele 播 atk_pre/atk 挥舞动画，fn 内模拟
--   blinkstaff:Blink（锚点不是魔杖，无 blinkstaff 组件，故直接内联实现）：
--   播完挥舞后隐藏角色 -> 0.25s 后 Physics:Teleport 到锚点 -> 重现 + sand_puff 特效。
--
-- 职责分离：
--   fn 只做折跃 + 记已折跃；"是否需要额外触发技能效果"放在 fn 成功后的
--   AddSuccessAction 回调里检查（点击锚点且 skill3 可用 -> 触发二段 buff）。
--   技能二段（热键/UI）内部判断能否触发后手动 DoAction 指定位置（锚点），
--   走同一 fn + SG；此时 fn 回调里 recast state 已置位，不会重复触发。
-- ============================================================

local common = require("kaltsit_esperanta_common")

local SKILL3_ID = "kaltsit_esperanta_skill3"
-- 定义动作：点击锚点折跃
AddAction("USE_TACTICAL_ANCHOR", STRINGS.ACTIONS.USE_TACTICAL_ANCHOR.GENERIC, function(act)
  ArkLogger:Debug("USE_TACTICAL_ANCHOR", act.doer, act.target)
  local target, doer = act.target, act.doer
  if target == nil or not target:IsValid() or doer == nil or not doer:IsValid() then
    return false
  end
  local ta = target.components.tactical_anchor
  if not ta:CanTargetTeleported(doer) then
    return false
  end
	local anchorPos = target:GetPosition()
  local x, y, z = doer.Transform:GetWorldPosition()
  -- 折跃可用性检查（同原版 blinkstaff:Blink）
  if not IsTeleportingPermittedFromPointToPoint(x, y, z, anchorPos.x, anchorPos.y, anchorPos.z)
    or not TheWorld.Map:IsPassableAtPoint(anchorPos:Get())
    or TheWorld.Map:IsGroundTargetBlocked(anchorPos) then
    return false
  end
  ta:MarkTeleported(doer)
  local skill3 = doer.components.ark_skill and doer.components.ark_skill:GetSkill(SKILL3_ID)
  if skill3 ~= nil and skill3:IsActivating() and skill3:GetState("anchor") == target and skill3:GetState("recast") == nil then
    common.ActiveDoctorsMonumentsBuff(doer, anchorPos, skill3:GetLevelParams())
  end

  -- 懒人魔杖式折跃：quicktele 状态已在 ActionHandler 进入（播 atk_pre/atk 挥舞动画）。
  -- 以下模拟原版 blinkstaff:Blink / OnBlinked —— 隐藏 -> 0.25s 后传送到锚点 -> 重现。
  doer.sg.statemem.onstartblinking = function()
    doer.sg:AddStateTag("noattack")
    if doer.components.health then doer.components.health:SetInvincible(true) end
    if doer.DynamicShadow then doer.DynamicShadow:Enable(false) end
    doer:Hide()
  end
  doer.sg.statemem.onstopblinking = function()
    doer.sg:RemoveStateTag("noattack")
    if doer.sg.statemem.endbusy then doer.sg:RemoveStateTag("busy") end
    if doer.components.health then doer.components.health:SetInvincible(false) end
    if doer.DynamicShadow then doer.DynamicShadow:Enable(true) end
    doer:Show()
  end
  -- 原地消散特效 + 音效
  SpawnPrefab("sand_puff_large_back").Transform:SetPosition(x, y - 0.1, z)
  SpawnPrefab("sand_puff_large_front").Transform:SetPosition(x, y, z)
  doer.SoundEmitter:PlaySound("dontstarve/common/staff_blink")
  doer.sg.statemem.onstartblinking()
  -- 0.25s 后传送到锚点并重现
  doer:DoTaskInTime(0.25, function(caster)
    if not caster:IsValid() or (caster.components.health and caster.components.health:IsDead()) then
      return
    end
    if caster.sg and caster.sg.statemem.onstopblinking then
      caster.sg.statemem.onstopblinking()
    end
    if caster.Physics then
      caster.Physics:Teleport(anchorPos:Get())
    end
    SpawnPrefab("sand_puff_large_back").Transform:SetPosition(anchorPos.x, anchorPos.y - 0.1, anchorPos.z)
    SpawnPrefab("sand_puff_large_front").Transform:SetPosition(anchorPos.x, anchorPos.y, anchorPos.z)
    caster.SoundEmitter:PlaySound("dontstarve/common/staff_blink")
  end)
  return true
end)
ACTIONS.USE_TACTICAL_ANCHOR.distance = 40
ACTIONS.USE_TACTICAL_ANCHOR.mount_valid = true

AddComponentAction('SCENE', 'tactical_anchor', function(inst, doer, actions, right)
  local replica = inst.replica.tactical_anchor
  if replica ~= nil and not replica:CanTargetTeleported(doer) then
    return  -- 已折跃，不显示折跃动作
  end
  table.insert(actions, ACTIONS.USE_TACTICAL_ANCHOR)
end)

AddStategraphActionHandler("wilson", ActionHandler(ACTIONS.USE_TACTICAL_ANCHOR, "quicktele"))
AddStategraphActionHandler("wilson_client", ActionHandler(ACTIONS.USE_TACTICAL_ANCHOR, "quicktele"))
