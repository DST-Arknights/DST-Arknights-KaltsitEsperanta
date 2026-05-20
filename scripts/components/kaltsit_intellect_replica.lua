local KaltsitIntellectReplica = Class(function(self, inst)
    self.inst = inst
    self.state = NetState(inst, "kaltsit_intellect")
    self.state:Attach(self.inst)
    self.state:Watch({"current", "max", "next_build_discounted"}, function ()
      local badge = GetArkBadge("kaltsit_intellect_badge", self.inst)
      if badge then
        local max = math.max(self.state.max, 1) -- 避免除以0
        badge:SetPercent(self.state.current / max, max)
      end
    end)
end)

return KaltsitIntellectReplica
