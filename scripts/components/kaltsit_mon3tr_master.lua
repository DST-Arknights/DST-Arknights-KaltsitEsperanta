local function setsummoned(self)
  self.inst:AddOrRemoveTag("mon3tr_master_summoned", self.summoned)
end

local function setnotsummoned(self)
  self.inst:AddOrRemoveTag("mon3tr_master_notsummoned", self.notsummoned)
end

local function setelite(self)
  self.inst.replica.kaltsit_mon3tr_master:SetElite(self.elite)
end

local KaltsitMon3trMaster = Class(function(self, inst)
  self.inst = inst
  self.mon3tr = nil
  self.summoned = false
  self.notsummoned = true
  self.elite = 1
  self.spawn_mon3tr_task = self.inst:DoTaskInTime(0, function() self:SpawnMon3tr() end)
  self._mon3tr_onremove = function() end
end, nil, {
  notsummoned = setnotsummoned,
  summoned = setsummoned,
  elite  = setelite,
})

function KaltsitMon3trMaster:ApplyElite(elite)
  
end

function KaltsitMon3trMaster:SpawnMon3tr(in_world)
  if not self.mon3tr then
    self.mon3tr = SpawnPrefab("kaltsit_esperanta_mon3tr")
  end
  local mon3tr = self.mon3tr
  -- mon3tr:LinkToPlayer(self.inst)
  self.inst:ListenForEvent("onremove", self._mon3tr_onremove, mon3tr)
  self.inst:ListenForEvent("death", self._mon3tr_death, mon3tr)
  self:ApplyElite(self.elite)
  if in_world then
    self:SummonComplete()
  else
    self:RecallComplete()
  end
end

function KaltsitMon3trMaster:Summon(summoning_item, pos)
  ArkLogger:Debug("Summon called with summoning_item=", summoning_item, "pos=", pos)
  if not self.mon3tr or not summoning_item then return false end
  self.mon3tr.entity:SetParent(nil)
  if pos then
    self.mon3tr.Transform:SetPosition(pos:Get())
  else
    self.mon3tr.Transform:SetPosition(self.inst.Transform:GetWorldPosition())
  end
  self.mon3tr:ReturnToScene()
  self.notsummoned = false
  self.summoned = true
  if self.onsummonfn then
    self.onsummonfn(self.inst, self.mon3tr)
  end
  return true
end

function KaltsitMon3trMaster:SummonComplete()
  self.notsummoned = false
  self.summoned = true

  if self.onsummoncompletefn ~= nil then
    self.onsummoncompletefn(self.inst, self.mon3tr)
  end
  self.inst:PushEvent("mon3tr_master_summoncomplete", self.mon3tr)
end

function KaltsitMon3trMaster:Recall(was_killed)
  if self.mon3tr ~= nil and self.summoned and not self.inst.sg:HasStateTag("dissipate") then
    self.summoned = false

    if self.onrecallfn ~= nil then
      self.onrecallfn(self.inst, self.mon3tr, was_killed)
    end

    return true
  end
end

function KaltsitMon3trMaster:RecallComplete()
  self.mon3tr:RemoveFromScene()
  self.mon3tr.entity:SetParent(self.inst.entity)
  self.mon3tr.Transform:SetPosition(0, 0, 0)

  self.summoned = false
  self.notsummoned = true

  if self.onrecallcompletefn ~= nil then
    self.onrecallcompletefn(self.inst, self.mon3tr)
  end
  self.inst:PushEvent("mon3tr_master_recallcomplete", self.mon3tr)
end

function KaltsitMon3trMaster:OnSave()
  return {
    mon3tr = self.mon3tr ~= nil and self.mon3tr:GetSaveRecord() or nil,
    mon3tr_in_world = self.mon3tr ~= nil and not self.mon3tr:IsInLimbo() or nil,
  }
end

function KaltsitMon3trMaster:OnLoad(data)
  if data == nil then return end
  if data.mon3tr then
    if self.spawn_mon3tr_task then
      self.spawn_mon3tr_task:Cancel()
      self.spawn_mon3tr_task = nil
    end
    self.mon3tr = SpawnSaveRecord(data.mon3tr)
    self:SpawnMon3tr(data.mon3tr_in_world)
  end
end

function KaltsitMon3trMaster:OnRemoveEntity()
  self.summoned = false
  self.notsummoned = false

  -- hack to remove mon3tr when spawned due to session state reconstruction for autosave snapshots
  if self.mon3tr ~= nil and self.mon3tr.spawntime == GetTime() then
    self.inst:RemoveEventCallback("onremove", self._mon3tr_onremove, self.mon3tr)
    self.mon3tr:Remove()
  end
end

return KaltsitMon3trMaster
