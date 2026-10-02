-- 复用工坊 3703731465 的利爪显示动画，资源内部 Bank/Build 已重命名。
local NAME = "kaltsit_esperanta_mon3tr_claw"
local assets = {
  Asset("ANIM", "anim/" .. NAME .. ".zip"),
}

local function fn()
  local inst = CreateEntity()
  inst.entity:AddTransform()
  inst.entity:AddAnimState()
  inst.entity:AddFollower()
  inst.entity:AddNetwork()

  inst.Transform:SetFourFaced()
  inst.AnimState:SetBank(NAME)
  inst.AnimState:SetBuild(NAME)
  inst.AnimState:PlayAnimation("idle", true)
  inst.AnimState:SetScale(.8, .8)
  inst.AnimState:SetFinalOffset(1)

  inst:AddTag("FX")
  inst:AddTag("NOCLICK")
  inst:AddTag("NOBLOCK")
  inst.entity:SetPristine()
  inst.persists = false

  return inst
end

return Prefab(NAME, fn, assets)
