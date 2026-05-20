local function GetTreesForLevel(level)
  if level == 2 then
    return TUNING.PROTOTYPER_TREES.KALTSIT_INTELLECT_1
  elseif level == 3 then
    return TUNING.PROTOTYPER_TREES.KALTSIT_INTELLECT_2
  end

  return TUNING.PROTOTYPER_TREES.KALTSIT_INTELLECT_0
end

local function SetLevel(inst, level)
  inst.components.prototyper.trees = GetTreesForLevel(level)
end

local function fn()
  local inst = CreateEntity()

  inst.entity:AddTransform()
  inst.entity:AddNetwork()

  inst:AddTag("prototyper")
  inst:AddTag("ancient_station")
  inst:AddTag("celestial_station")
  inst:AddTag("lunar_forge")
  inst:AddTag("shadow_forge")
  inst:AddTag("carpentry_station")
  inst:AddTag("hermitcrab")
  inst:AddTag("NOCLICK")
  inst:AddTag("kaltsit_esperanta_prototyper")

  inst.entity:SetPristine()

  if not TheWorld.ismastersim then
    return inst
  end

  inst.persists = false
  inst.SetLevel = SetLevel

  inst:AddComponent("prototyper")
  inst.components.prototyper.trees = GetTreesForLevel(1)

  return inst
end

return Prefab("kaltsit_esperanta_prototyper", fn)