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
--   复活扫描：锚点存在期间周期性扫描周围 40 距离内已死亡（playerghost）的玩家，
--   向目标推 respawnfromghost（source=锚点，锚点带 reviver tag）走原版原地复活。
--   每个锚点对每位玩家仅能复活一次（_revivedSet 按 userid 记录），可复活多位
--   不同玩家。多锚点范围重叠时用模块级共享锁 AnchorReviveLock 防额外消耗：锚点
--   发起复活后把玩家 userid 加锁，其余锚点跳过；锁的释放监听挂在玩家实体上，
--   玩家复活完成（ms_respawnedfromghost）或下线（onremove）时解锁，允许另一锚点
--   在其再次死亡时接手。释放逻辑不依赖锚点本身，锚点销毁无需清理锁。
--
-- 记录键使用玩家 userid（跨端一致、重生后稳定），非玩家（无 userid）不限制。
-- 锚点实体的生命周期由技能组件（ark_skill）管理；本组件不监听 onremove，实体
-- 销毁后系统自动停止其 DoPeriodicTask。
-- ============================================================

local REVIVE_RADIUS = 40
local REVIVE_SCAN_INTERVAL = 0.5

-- 模块级共享锁：Lua 组件文件仅 require 一次，所有锚点实例共享此表。
-- key = 玩家 userid；锁定的玩家不会被其它锚点重复复活。
local AnchorReviveLock = {}

local TacticalAnchor = Class(function(self, inst)
  self.inst = inst
  self._revivedSet = {}  -- 本锚点已复活过的玩家 userid 集合（每锚点对每位玩家仅一次）
  self._scanTask = nil

  if TheWorld.ismastersim then
    self._scanTask = inst:DoPeriodicTask(REVIVE_SCAN_INTERVAL, function()
      self:_Scan()
    end)
  end
end)

-- 组件被单独移除（inst:RemoveComponent）时取消扫描任务：此时实体仍存在，
-- DoPeriodicTask 挂在实体上不会自动停止，不清理会继续持有组件并泄漏。
-- （实体本身销毁时系统自动停任务，无需在此处理。）
function TacticalAnchor:OnRemoveFromEntity()
  if self._scanTask ~= nil then
    self._scanTask:Cancel()
    self._scanTask = nil
  end
end

-- 周期扫描：找出周围已死亡、本锚点未救过、且未被其它锚点锁定的玩家，复活一位。
function TacticalAnchor:_Scan()
  local x, y, z = self.inst.Transform:GetWorldPosition()
  -- canttags = reviving：原版正在被复活（含心脏等其它来源）的玩家也跳过
  local ghosts = TheSim:FindEntities(x, y, z, REVIVE_RADIUS, { "playerghost" }, { "reviving" })
  for _, ghost in ipairs(ghosts) do
    local uid = ghost.userid
    if uid ~= nil and uid ~= "" and self._revivedSet[uid] ~= true and AnchorReviveLock[uid] == nil then
      -- 记已救过：即使复活流程中断，本锚点也不再救这位玩家
      self._revivedSet[uid] = true
      -- 加锁：阻止重叠范围内的其它锚点在本次复活期间额外消耗次数
      AnchorReviveLock[uid] = true

      -- 解锁挂在玩家实体上：复活完成或玩家下线即释放锁，允许另一锚点接手。
      -- 释放逻辑不引用锚点，锚点销毁（技能收回）后锁仍能正确清理。
      local function Unlock()
        AnchorReviveLock[uid] = nil
        if ghost:IsValid() then
          ghost:RemoveEventCallback("ms_respawnedfromghost", Unlock)
          ghost:RemoveEventCallback("onremove", Unlock)
        end
      end
      ghost:ListenForEvent("ms_respawnedfromghost", Unlock)
      ghost:ListenForEvent("onremove", Unlock) -- 玩家下线等兜底，避免锁残留

      ghost:PushEvent("respawnfromghost", { source = self.inst })
      return
    end
  end
end

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
