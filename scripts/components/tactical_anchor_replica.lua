-- ============================================================
-- TacticalAnchorReplica
-- ============================================================
-- 战术锚点副本：已折跃玩家 userid 集合的唯一持有者（服务端与客户端通用）。
-- 记录/判断/存档读写的逻辑都集中在这里：
--   服务端组件 (tactical_anchor.lua) 只做薄转发 + OnSave/OnLoad 代理。
--   数据经 net_string 同步，客户端在 dirty 事件时解析刷新。
--
-- 记录键使用玩家 userid（跨端一致、重生后稳定）。非玩家（无 userid）
-- 无法限制，也不记录。
-- ============================================================

local SEP = ","

-- 玩家才有 userid；非玩家（守卫/生物）返回 nil
local function GetUserID(target)
  if target == nil then
    return nil
  end
  local uid = target.userid
  if uid ~= nil and uid ~= "" then
    return uid
  end
  return nil
end

local function OnTeleportedDirty(inst)
  inst.replica.tactical_anchor:_RefreshSet()
end

local TacticalAnchorReplica = Class(function(self, inst)
  self.inst = inst
  self._teleported = net_string(inst.GUID, "tactical_anchor.teleported", "tacticalanchorteleporteddirty")
  self._teleportedSet = {}  -- 已折跃玩家 userid 集合（唯一数据源）

  if not TheWorld.ismastersim then
    inst:ListenForEvent("tacticalanchorteleporteddirty", OnTeleportedDirty)
  end
end)

-- 内部：把集合同步到 net_string（仅服务端）
function TacticalAnchorReplica:_SyncToNet()
  if not TheWorld.ismastersim then
    return
  end
  local parts = {}
  for uid in pairs(self._teleportedSet) do
    table.insert(parts, uid)
  end
  table.sort(parts)
  self._teleported:set(table.concat(parts, SEP))
end

-- 记录一次折跃（仅玩家；非玩家不记录，无法限制）
function TacticalAnchorReplica:MarkTeleported(target)
  local uid = GetUserID(target)
  if uid == nil then
    return
  end
  if self._teleportedSet[uid] ~= true then
    self._teleportedSet[uid] = true
    self:_SyncToNet()
  end
end

-- 目标是否已折跃过（非玩家恒为 false，不限制）
function TacticalAnchorReplica:CanTargetTeleported(target)
  local uid = GetUserID(target)
  if not uid then
    return true
  end
  return not self._teleportedSet[uid]
end

-- 读取全部已折跃 userid（服务端组件 OnSave 代理用）
function TacticalAnchorReplica:GetTeleportedUserIDs()
  local res = {}
  for uid in pairs(self._teleportedSet) do
    table.insert(res, uid)
  end
  return res
end

-- 读档恢复：替换集合并同步（服务端组件 OnLoad 代理用）
function TacticalAnchorReplica:SetTeleportedUserIDs(userids)
  self._teleportedSet = {}
  for _, uid in ipairs(userids or {}) do
    self._teleportedSet[uid] = true
  end
  self:_SyncToNet()
end

-- 从 net_string 解析出 userid 集合（客户端 dirty 事件）
function TacticalAnchorReplica:_RefreshSet()
  local set = {}
  local raw = self._teleported:value()
  if raw ~= nil and raw ~= "" then
    for uid in string.gmatch(raw, "[^" .. SEP .. "]+") do
      set[uid] = true
    end
  end
  self._teleportedSet = set
end

return TacticalAnchorReplica
