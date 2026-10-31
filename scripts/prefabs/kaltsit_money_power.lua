local assets = {
  Asset("ANIM", "anim/books.zip"),
  Asset("ANIM", "anim/swap_books.zip"),
}

local prefabs = {
  "fx_book_research_station",
  "fx_book_research_station_mount",
}

local function OnRead(inst, reader)
  local intellect = reader.components.kaltsit_intellect
  if intellect ~= nil then
    intellect:DeltaMax(5)
    intellect:Delta(5)
  end

  local mounted = reader.components.rider ~= nil and reader.components.rider:IsRiding()
  local fx = SpawnPrefab(mounted and "fx_book_research_station_mount" or "fx_book_research_station")
  fx.Transform:SetPosition(reader.Transform:GetWorldPosition())
  fx.Transform:SetRotation(reader.Transform:GetRotation())
  return true
end

local function fn()
  local inst = CreateEntity()

  inst.entity:AddTransform()
  inst.entity:AddAnimState()
  inst.entity:AddNetwork()

  MakeInventoryPhysics(inst)
  inst.AnimState:SetBank("books")
  inst.AnimState:SetBuild("books")
  inst.AnimState:PlayAnimation("book_research_station")
  inst.scrapbook_anim = "book_research_station"

  MakeInventoryFloatable(inst, "med", nil, 0.75)
  inst:AddTag("book")
  inst:AddTag("bookcabinet_item")

  inst.entity:SetPristine()
  if not TheWorld.ismastersim then
    return inst
  end

  inst.swap_build = "swap_books"
  inst.swap_prefix = "book_research_station"

  inst:AddComponent("inspectable")
  inst:AddComponent("inventoryitem")
  inst.components.inventoryitem.imagename = "book_research_station"
  inst.components.inventoryitem.atlasname = GetInventoryItemAtlas("book_research_station.tex")

  inst:AddComponent("book")
  inst.components.book:SetOnRead(OnRead)
  inst.components.book:SetOnPeruse(OnRead)
  inst.components.book:SetReadSanity(0)
  inst.components.book:SetPeruseSanity(0)

  inst:AddComponent("finiteuses")
  inst.components.finiteuses:SetMaxUses(1)
  inst.components.finiteuses:SetUses(1)
  inst.components.finiteuses:SetOnFinished(inst.Remove)

  inst:AddComponent("fuel")
  inst.components.fuel.fuelvalue = TUNING.MED_FUEL
  MakeSmallBurnable(inst, TUNING.MED_BURNTIME)
  MakeSmallPropagator(inst)
  MakeHauntableLaunch(inst)

  return inst
end

return Prefab("kaltsit_money_power", fn, assets, prefabs)
