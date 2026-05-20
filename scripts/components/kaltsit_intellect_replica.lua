local KaltsitIntellectReplica = Class(function(self, inst)
    self.inst = inst
    self.state = NetState(inst, "kaltsit_intellect")
    self.state:Attach(self.inst)
    self.state:Watch({"current", "max",}, function ()
      local badge = GetArkBadge("kaltsit_intellect_badge", self.inst)
      if badge then
        local max = math.max(self.state.max, 1) -- 避免除以0
        badge:SetPercent(self.state.current / max, max)
      end
    end)
    self.state:Watch("next_build_discounted", function ()
      local badge = GetArkBadge("kaltsit_intellect_badge", self.inst)
      if badge then
        badge:SetActivate(self.state.next_build_discounted)
      end
    end)
end)

function KaltsitIntellectReplica:UseNextBuildDiscount()
  if self.inst.components.kaltsit_intellect then
    self.inst.components.kaltsit_intellect:UseNextBuildDiscount()
  else
    SendModRPCToServer(GetModRPC("kaltsit_esperanta", "use_next_build_discount"))
  end
end

return KaltsitIntellectReplica
