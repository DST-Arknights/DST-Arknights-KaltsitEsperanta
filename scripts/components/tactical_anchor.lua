-- ============================================================
-- TacticalAnchor
-- ============================================================
-- 战术锚点组件：已折跃玩家记录的唯一持有者是对应的副本组件
-- (tactical_anchor_replica.lua)，服务端组件只做薄转发，避免一套逻辑
-- 在两个地方各实现一份。
--
--   记录/判断：inst.replica.tactical_anchor 的 MarkTeleported / CanTargetTeleported
--   存档：OnSave/OnLoad 通过副本的 GetTeleportedUserIDs / SetTeleportedUserIDs 代理
--   （数据随锚点实体持久化；副本用 net_string 同步给客户端做条件前置判断）
--
-- 记录键使用玩家 userid（跨端一致、重生后稳定），非玩家（无 userid）不限制。
-- 锚点实体的生命周期由技能组件（ark_skill）管理，本组件不监听 onremove。
-- ============================================================

local TacticalAnchor = Class(function(self, inst)
  self.inst = inst
end)

-- 记录一次折跃（转发到副本）
function TacticalAnchor:MarkTeleported(target)
  self.inst.replica.tactical_anchor:MarkTeleported(target)
end

-- 目标是否已折跃过（转发到副本；非玩家恒为 false，不限制）
function TacticalAnchor:CanTargetTeleported(target)
  return self.inst.replica.tactical_anchor:CanTargetTeleported(target)
end

-- 存档：把已折跃玩家 userid 集合存到锚点实体的持久数据
function TacticalAnchor:OnSave()
  local userids = self.inst.replica.tactical_anchor:GetTeleportedUserIDs()
  if #userids <= 0 then
    return nil
  end
  return { teleportedUserIDs = userids }
end

-- 读档：恢复已折跃玩家 userid 集合（副本内部同步 net_string）
function TacticalAnchor:OnLoad(data)
  if data and data.teleportedUserIDs then
    self.inst.replica.tactical_anchor:SetTeleportedUserIDs(data.teleportedUserIDs)
  end
end

return TacticalAnchor
