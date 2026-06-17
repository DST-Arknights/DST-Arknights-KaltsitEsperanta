local prefabs = {
  {
    prefab = "铥矿护甲",
    OnAccept = function(inst, count)
      local old = inst.components.armor.absorb_percent
      local new = math.clamp(old + 0.05, 0, 0.1)
      inst.components.armor:SetAbsorption(new)
    end,
  },
  {
    prefab = "亮茄盔甲",
    OnAccept = function(inst, count)
      local old = inst.components.armor.absorb_percent
      local new = math.clamp(old + 0.05, 0, 0.1)
      inst.components.armor:SetAbsorption(new)
    end,
  }
}

return prefabs
