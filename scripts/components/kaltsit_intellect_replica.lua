local KaltsitIntellectReplica = Class(function(self, inst)
    self.inst = inst
    self.state = NetState(inst, "kaltsit_intellect")
    self.state:Attach(self.inst)
    self.state:Watch({"current", "max"}, function ()
      local badge = GetArkBadge("kaltsit_intellect_badge", self.inst)
      if badge then
        badge:SetPercent(self.state.current / self.state.max, self.state.max)
      end
    end)
end)

return KaltsitIntellectReplica
