local KaltsitMon3trMasterReplica = Class(function(self, inst)
  self.inst = inst
  self._elite = net_byte(inst.GUID, "kaltsit_mon3tr_master.elite", "kaltsit_mon3tr_master._updateelite")
end)

function KaltsitMon3trMasterReplica:SetElite(elite)
  self._elite:set(elite)
end

function KaltsitMon3trMasterReplica:GetElite()
  return self._elite:value()
end

return KaltsitMon3trMasterReplica
