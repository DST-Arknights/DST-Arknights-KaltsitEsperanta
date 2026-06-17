local LIFE_REPAIRING_UNITS_TRADABLE = require("life_repairing_units_tradable")

local assets = {
  Asset("Anim", "anim/life_repairing_units.zip"),
  Asset("ATLAS", "images/inventoryimages/life_repairing_units.xml"),
}
RegisterInventoryItemAtlas("images/inventoryimages/life_repairing_units.xml", "life_repairing_units.tex")

local function ApplyDapperness(inst)
  local base = TUNING.DAPPERNESS_HUGE / 2
  local step = base / 10
  local upgrade_count = table.count(inst.accepted_items) or 0
  return base + step * upgrade_count
end

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

local function GetUpgradeDef(prefab)
  for _, def in pairs(LIFE_REPAIRING_UNITS_TRADABLE) do
    if def.prefab == prefab then
      return def
    end
  end
end

local function ApplyUpgrade(inst, prefab, count)
  local def = GetUpgradeDef(prefab)
  if def and def.OnAccept then
    def.OnAccept(inst, count)
  end
  ApplyDapperness(inst)
end

local function AbleToAcceptTest(inst, item, giver, count)
  local count = count or 1
  local current = inst.accepted_items[item.prefab] or 0
  local def = GetUpgradeDef(item.prefab)
  if def.required then
    for req, num in pairs(def.required) do
      local accepted = inst.accepted_items[req] or 0
      if accepted < num then
        return false
      end
    end
  end
  local max = def and (def.max or 1) or 0
  return current + count <= max
end

local function OnAccept(inst, giver, item, count)
  count = count or 1
  if not inst.accepted_items[item.prefab] then
    inst.accepted_items[item.prefab] = 0
  end
  inst.accepted_items[item.prefab] = inst.accepted_items[item.prefab] + count
  ApplyUpgrade(inst, item.prefab, inst.accepted_items[item.prefab])
end

local function OnRefuse(inst, giver, item)
  SayAndVoice(inst, "LIFE_REPAIRING_UNITS_TRADABLE_REFUSE")
end

local function OnSave(inst, data)
  data.accepted_items = inst.accepted_items
end

local function OnLoad(inst, data)
  if data and data.accepted_items then
    inst.accepted_items = data.accepted_items
  end
  for k, v in pairs(inst.accepted_items) do
    ApplyUpgrade(inst, k, v)
  end
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
  inst.components.equippable.walkspeedmult = 1.1
  inst.components.equippable:SetOnEquip(OnEquip)
  inst.components.equippable:SetOnUnequip(OnUnEquip)
  ApplyDapperness(inst)

  inst.accepted_items = {}

  inst:AddComponent("trader")
  inst.components.trader:SetAbleToAcceptTest(AbleToAcceptTest)
  inst.components.trader:SetOnAccept(OnAccept)
  inst.components.trader:SetOnRefuse(OnRefuse)

  inst:AddComponent("armor")
  inst.components.armor:InitIndestructible(0.8)

  MakeHauntableLaunch(inst)

  inst.OnSave = OnSave
  inst.OnLoad = OnLoad

  return inst
end
return Prefab("life_repairing_units", fn, assets)
