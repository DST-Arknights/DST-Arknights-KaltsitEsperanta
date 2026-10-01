local VALID_MODES = {
  standby = true,
  attack = true,
  work = true,
}

local KaltsitMon3trBehavior = Class(function(self, inst)
  self.inst = inst
  self.mode = "standby"
end)

function KaltsitMon3trBehavior:GetMode()
  return self.mode
end

function KaltsitMon3trBehavior:SetMode(mode)
  if not VALID_MODES[mode] then
    return false
  end
  if self.mode == mode then
    return true
  end

  local oldmode = self.mode
  self.mode = mode
  self.inst:PushEvent("kaltsit_mon3tr_modechanged", { oldmode = oldmode, mode = mode })
  return true
end

function KaltsitMon3trBehavior:OnSave()
  return { mode = self.mode }
end

function KaltsitMon3trBehavior:OnLoad(data)
  if data ~= nil then
    self:SetMode(data.mode)
  end
end

function KaltsitMon3trBehavior:GetDebugString()
  return "mode: " .. self.mode
end

return KaltsitMon3trBehavior
