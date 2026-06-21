local assets =
{
  Asset("ANIM", "anim/tactical_anchor.zip"),
}
local prefabs =
{
}
local function fn()
  local inst = CreateEntity()

  inst.entity:AddTransform()
  inst.entity:AddAnimState()
  inst.entity:AddNetwork()

  inst.AnimState:SetBank("tactical_anchor")
  inst.AnimState:SetBuild("tactical_anchor")
  inst.AnimState:PlayAnimation("idle", true)
  -- inst.AnimState:SetScale(3, 3, 3)
  inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")

  if not TheWorld.ismastersim then
    return inst
  end
  inst:AddComponent("inspectable")
  -- 不存档
  inst.persists = false
  return inst
end
return Prefab("tactical_anchor", fn, assets, prefabs)
