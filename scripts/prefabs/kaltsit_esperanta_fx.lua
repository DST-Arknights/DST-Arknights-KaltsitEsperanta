local fxs = { {
  name = "special_treatment_bullet_fx_ally",
  bank = "stalker_shield",
  build = "stalker_shield",
  anim = "idle1",
  fn = function(inst)
    inst.AnimState:SetAddColour(0, 0.7, 0, 0.7)
  end,
}, {
  name = "special_treatment_bullet_fx_enemy",
  bank = "stalker_shield",
  build = "stalker_shield",
  anim = "idle1",
  fn = function(inst)
    inst.AnimState:SetAddColour(0.7, 0, 0, 0.7)
  end,
}
}

local results = {}
for i, v in ipairs(fxs) do
  table.insert(results, ArkMakeFx(v))
end

return unpack(results)
