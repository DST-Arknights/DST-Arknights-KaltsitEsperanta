local KaltsitMon3trBehavior = Class(function(self, inst)
  self.inst = inst
  self._onownerchanged = function() self:SyncOwner() end
  inst:ListenForEvent("leaderchanged", self._onownerchanged)
  inst:ListenForEvent("setowner", self._onownerchanged)
  inst.replica.kaltsit_mon3tr_behavior:SetMode("standby")
  -- AddComponent 构造期间尚未写入 inst.components；下一帧再绑定读档/玩家自身关系。
  self._inittask = inst:DoTaskInTime(0, function()
    self._inittask = nil
    self:SyncOwner()
  end)
end)

function KaltsitMon3trBehavior:GetOwner()
  if not self.inst:IsValid() then
    return nil
  end
  local userid = self.inst.Network:GetUserID()
  if userid ~= nil and userid ~= "" then
    return self.inst
  end
  local follower = self.inst.components.follower
  local owner = follower ~= nil and follower:GetLeader() or nil
  return owner ~= nil and owner:IsValid() and owner:HasTag("player") and owner or nil
end

function KaltsitMon3trBehavior:SyncOwner()
  local owner = self:GetOwner()
  local master = nil
  if owner ~= nil then
    -- 宠物可能先于玩家的 AddPlayerPostInit 完成归属绑定。
    if owner.components.kaltsit_mon3tr_master == nil then
      owner:AddComponent("kaltsit_mon3tr_master")
    end
    master = owner.components.kaltsit_mon3tr_master
  end
  if master ~= self._master then
    local oldmaster = self._master
    self._master = master
    if oldmaster ~= nil then
      oldmaster:ClearMon3tr(self.inst)
    end
  end
  if master ~= nil then
    -- 同一归属也重试幂等绑定，覆盖组件构造期间尚未进入 components 的情况。
    master:SetMon3tr(self.inst)
  end
end

function KaltsitMon3trBehavior:GetMode()
  return self.inst.replica.kaltsit_mon3tr_behavior:GetMode()
end

function KaltsitMon3trBehavior:SetMode(mode)
  if not self.inst.replica.kaltsit_mon3tr_behavior:IsValidMode(mode) then
    return false
  end
  local oldmode = self:GetMode()
  if oldmode == mode then
    return true
  end

  self.inst.replica.kaltsit_mon3tr_behavior:SetMode(mode)
  self.inst:PushEvent("kaltsit_mon3tr_modechanged", { oldmode = oldmode, mode = mode })
  return true
end

function KaltsitMon3trBehavior:OnSave()
  return { mode = self:GetMode() }
end

function KaltsitMon3trBehavior:OnLoad(data)
  if data ~= nil then
    self:SetMode(data.mode)
  end
end

function KaltsitMon3trBehavior:GetDebugString()
  return "mode: " .. self:GetMode()
end

function KaltsitMon3trBehavior:OnRemoveFromEntity()
  if self._inittask ~= nil then
    self._inittask:Cancel()
    self._inittask = nil
  end
  self.inst:RemoveEventCallback("leaderchanged", self._onownerchanged)
  self.inst:RemoveEventCallback("setowner", self._onownerchanged)
  if self._master ~= nil then
    self._master:ClearMon3tr(self.inst)
    self._master = nil
  end
end

KaltsitMon3trBehavior.OnRemoveEntity = KaltsitMon3trBehavior.OnRemoveFromEntity

return KaltsitMon3trBehavior
