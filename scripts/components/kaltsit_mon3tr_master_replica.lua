local BehaviorReplica = require("components/kaltsit_mon3tr_behavior_replica")

local KaltsitMon3trMasterReplica = Class(function(self, inst)
  self.inst = inst
  self._hasmon3tr = net_bool(inst.GUID, "kaltsit_mon3tr_master.hasmon3tr", "kaltsit_mon3tr_mastersnapshotdirty")
  self._mode = net_tinybyte(inst.GUID, "kaltsit_mon3tr_master.mode", "kaltsit_mon3tr_mastersnapshotdirty")
  self._onsnapshotdirty = function() inst:PushEvent("kaltsit_mon3tr_masterdirty") end
  if not TheWorld.ismastersim then
    inst:ListenForEvent("kaltsit_mon3tr_mastersnapshotdirty", self._onsnapshotdirty)
    -- 初次反序列化可能已带快照，HUD 比 replica 先创建时也需要一次刷新。
    self._inittask = inst:DoTaskInTime(0, function()
      self._inittask = nil
      self._onsnapshotdirty()
    end)
  end
end)

function KaltsitMon3trMasterReplica:HasMon3tr()
  return self._hasmon3tr:value()
end

function KaltsitMon3trMasterReplica:GetMode()
  return BehaviorReplica.MODES[self._mode:value()] or "standby"
end

function KaltsitMon3trMasterReplica:IsValidMode(mode)
  return type(mode) == "string" and BehaviorReplica.MODE_IDS[mode] ~= nil
end

function KaltsitMon3trMasterReplica:SetSnapshot(hasmon3tr, mode)
  if not TheWorld.ismastersim or not self:IsValidMode(mode) then
    return
  end
  local changed = self:HasMon3tr() ~= hasmon3tr or self:GetMode() ~= mode
  self._hasmon3tr:set(hasmon3tr)
  self._mode:set(BehaviorReplica.MODE_IDS[mode])
  if changed then
    self._onsnapshotdirty()
  end
end

function KaltsitMon3trMasterReplica:RequestMode(mode)
  if not self:IsValidMode(mode) or not self:HasMon3tr() or self.inst:HasTag("playerghost") then
    return false
  end
  if TheWorld.ismastersim then
    local master = self.inst.components.kaltsit_mon3tr_master
    return master ~= nil and master:SetMode(mode) or false
  end
  -- 服务端根据实际发送玩家找到当前受控对象，客机只提交模式。
  SendModRPCToServer(GetModRPC("kaltsit_esperanta", "mon3tr_set_mode"), mode)
  return true
end

function KaltsitMon3trMasterReplica:OnRemoveEntity()
  if self._inittask ~= nil then
    self._inittask:Cancel()
    self._inittask = nil
  end
  self.inst:RemoveEventCallback("kaltsit_mon3tr_mastersnapshotdirty", self._onsnapshotdirty)
end

return KaltsitMon3trMasterReplica
