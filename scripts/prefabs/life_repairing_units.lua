local assets = {
  Asset("Anim", "anim/life_repairing_units.zip"),
  Asset("ATLAS", "images/inventoryimages/life_repairing_units.xml"),
}
RegisterInventoryItemAtlas("images/inventoryimages/life_repairing_units.xml", "life_repairing_units.tex")

local function OnEquip(inst, owner)
  local skin_build = inst:GetSkinBuild()
  if skin_build ~= nil then
    owner:PushEvent("equipskinneditem", inst:GetSkinName())
    owner.AnimState:OverrideItemSkinSymbol("swap_body", skin_build, "swap_body", inst.GUID, "life_repairing_units")
  else
    owner.AnimState:OverrideSymbol("swap_body", "life_repairing_units", "swap_body")
  end
  if not owner.components.ark_flyer then
    owner:AddComponent("ark_flyer")
  end
  owner.components.ark_flyer:TakeOff()
end

local function OnUnEquip(inst, owner)
  owner.AnimState:ClearOverrideSymbol("swap_body")
  local skin_build = inst:GetSkinBuild()
  if skin_build ~= nil then
    owner:PushEvent("unequipskinneditem", inst:GetSkinName())
  end
  if not owner.components.ark_flyer then
    owner:AddComponent("ark_flyer")
  end
  owner.components.ark_flyer:Land()
end
local function fn()
  local inst = CreateEntity()

  inst.entity:AddTransform()
  inst.entity:AddAnimState()
  inst.entity:AddNetwork()

  MakeInventoryPhysics(inst)
  inst.AnimState:SetBank("life_repairing_units")
  inst.AnimState:SetBuild("life_repairing_units")
  inst.AnimState:PlayAnimation("anim")
  inst:AddTag("heavyarmor")
  inst:AddTag("hardarmor")
  inst.foleysound = "dontstarve/movement/foley/marblearmour"

  local swap_data = { bank = "life_repairing_units", anim = "anim" }
  MakeInventoryFloatable(inst, "large", 0.2, 0.80, nil, nil, swap_data)

  inst.entity:SetPristine()
  if not TheWorld.ismastersim then
    return inst
  end
  inst:AddComponent("inspectable")
  inst:AddComponent("inventoryitem")
  inst:AddComponent("equippable")
  inst.components.equippable.equipslot = EQUIPSLOTS.BODY
  inst.components.equippable.walkspeedmult = 1
  inst.components.equippable:SetOnEquip(OnEquip)
  inst.components.equippable:SetOnUnequip(OnUnEquip)

  MakeHauntableLaunch(inst)

  return inst
end
return Prefab("life_repairing_units", fn, assets)
