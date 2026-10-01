local MODE_IDS = { standby = 0, attack = 1, work = 2 }
local MODES = { [0] = "standby", [1] = "attack", [2] = "work" }

local KaltsitMon3trBehaviorReplica = Class(function(self, inst)
  self.inst = inst
  self._mode = net_tinybyte(inst.GUID, "kaltsit_mon3tr_behavior.mode", "kaltsit_mon3tr_modedirty")
end)

function KaltsitMon3trBehaviorReplica:GetMode()
  return MODES[self._mode:value()] or "standby"
end

function KaltsitMon3trBehaviorReplica:IsValidMode(mode)
  return type(mode) == "string" and MODE_IDS[mode] ~= nil
end

function KaltsitMon3trBehaviorReplica:SetMode(mode)
  if TheWorld.ismastersim and self:IsValidMode(mode) then
    self._mode:set(MODE_IDS[mode])
  end
end

KaltsitMon3trBehaviorReplica.MODE_IDS = MODE_IDS
KaltsitMon3trBehaviorReplica.MODES = MODES

return KaltsitMon3trBehaviorReplica
