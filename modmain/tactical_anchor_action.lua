-- ============================================================
-- 战术锚点：点击折跃
-- ============================================================
-- 其他玩家（含凯尔希）点击锚点 -> 折跃到锚点附近安全落点。
-- 每个目标仅能折跃一次（锚点组件按目标 GUID 记录，经 OnSave/OnLoad 存档）。
--
-- 动作链路（源码验证）：
--   拾取器自动触发：PlayerActionPicker 拾取 -> DoAction -> LocoMotor:PushAction
--                    -> PushBufferedAction -> SG(portal_jumpin_pre) -> PerformBufferedAction -> fn
--   手动直接触发：PlayerController:DoAction(BufferedAction(...)) -> LocoMotor:PushAction
--                  -> PushBufferedAction -> SG -> PerformBufferedAction -> fn
--   两条链路汇合于同一 fn，最大化代码复用。
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
	local act_pos = target:GetPosition()
  local anchorPos = target:GetPosition()
  ta:MarkTeleported(doer)
  local skill3 = doer.components.ark_skill and doer.components.ark_skill:GetSkill(SKILL3_ID)
  if skill3 ~= nil and skill3:IsActivating() and skill3:GetState("anchor") == target and skill3:GetState("recast") == nil then
    common.ActiveDoctorsMonumentsBuff(doer, anchorPos, skill3:GetLevelParams())
  end
  local platform = TheWorld.Map:GetPlatformAtPoint(act_pos.x, act_pos.z)
  local platformoffset
  if platform then
      platformoffset = platform:GetPosition() - act_pos
  end
  act.doer.sg:GoToState("portal_jumpin", {dest = act_pos, platform = platform, platformoffset = platformoffset,})
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

AddStategraphActionHandler("wilson", ActionHandler(ACTIONS.USE_TACTICAL_ANCHOR, "portal_jumpin_pre"))
AddStategraphActionHandler("wilson_client", ActionHandler(ACTIONS.USE_TACTICAL_ANCHOR, "portal_jumpin_pre"))
