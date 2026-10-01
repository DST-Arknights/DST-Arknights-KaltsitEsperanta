local KaltsitMon3trMaster = Class(function(self, inst)
  self.inst = inst
  self.mon3tr = nil
  self._onmodechanged = function(pet)
    if pet == self.mon3tr then
      self:SyncMon3tr()
    end
  end
  self._onmon3trremoved = function(pet) self:ClearMon3tr(pet) end
end)

function KaltsitMon3trMaster:GetMon3tr()
  return self.mon3tr
end

function KaltsitMon3trMaster:SyncMon3tr()
  local pet = self.mon3tr
  local behavior = pet ~= nil and pet:IsValid() and pet.components.kaltsit_mon3tr_behavior or nil
  if behavior == nil or behavior:GetOwner() ~= self.inst then
    self:ClearMon3tr()
    return
  end
  self.inst.replica.kaltsit_mon3tr_master:SetSnapshot(true, behavior:GetMode())
end

local function DetachMon3tr(self)
  local pet = self.mon3tr
  self.mon3tr = nil
  if pet ~= nil then
    self.inst:RemoveEventCallback("kaltsit_mon3tr_modechanged", self._onmodechanged, pet)
    self.inst:RemoveEventCallback("onremove", self._onmon3trremoved, pet)
  end
end

function KaltsitMon3trMaster:SetMon3tr(pet)
  local behavior = pet ~= nil and pet:IsValid() and pet.components.kaltsit_mon3tr_behavior or nil
  if behavior == nil or behavior:GetOwner() ~= self.inst then
    return false
  end
  if self.mon3tr ~= pet then
    -- 更换对象只发布最终快照，避免同帧出现一次无宠物的 UI 状态。
    DetachMon3tr(self)
    self.mon3tr = pet
    self.inst:ListenForEvent("kaltsit_mon3tr_modechanged", self._onmodechanged, pet)
    self.inst:ListenForEvent("onremove", self._onmon3trremoved, pet)
  end
  self:SyncMon3tr()
  return true
end

function KaltsitMon3trMaster:ClearMon3tr(expectedpet)
  local pet = self.mon3tr
  if expectedpet ~= nil and pet ~= expectedpet then
    return false
  end
  DetachMon3tr(self)
  self.inst.replica.kaltsit_mon3tr_master:SetSnapshot(false, "standby")
  return true
end

function KaltsitMon3trMaster:SetMode(mode)
  if not self.inst.replica.kaltsit_mon3tr_master:IsValidMode(mode)
    or not self.inst:IsValid() or self.inst:HasTag("playerghost") then
    return false
  end
  local pet = self.mon3tr
  local behavior = pet ~= nil and pet:IsValid() and pet.components.kaltsit_mon3tr_behavior or nil
  if behavior == nil or behavior:GetOwner() ~= self.inst or pet:HasTag("playerghost") then
    return false
  end
  local ownerhealth = self.inst.components.health
  local pethealth = pet.components.health
  if (ownerhealth ~= nil and ownerhealth:IsDead()) or (pethealth ~= nil and pethealth:IsDead()) then
    return false
  end
  return behavior:SetMode(mode)
end

function KaltsitMon3trMaster:OnRemoveFromEntity()
  -- 主人端只清理指令关系；宠物生命周期仍由 petleash 管理，自管理也不能删除自己。
  self:ClearMon3tr()
end

KaltsitMon3trMaster.OnRemoveEntity = KaltsitMon3trMaster.OnRemoveFromEntity

return KaltsitMon3trMaster
