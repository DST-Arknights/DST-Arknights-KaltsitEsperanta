local DURATION = 120
local TICK_RATE = 1
local buffPrefab = "kaltsit_neuro_gel_buff"

local assets = {
  Asset("ANIM", "anim/kaltsit_neuro_gel.zip"),
  Asset("ATLAS", "images/inventoryimages/kaltsit_neuro_gel.xml"),
}
RegisterInventoryItemAtlas("images/inventoryimages/kaltsit_neuro_gel.xml",
  "kaltsit_neuro_gel.tex")

local function BuffOnTick(inst, target)
  if target.components.sanity ~= nil then
    -- 回复0.5%的最大精神值
    local sanity_delta = math.ceil(target.components.sanity.max * 0.005)
    target.components.sanity:DoDelta(sanity_delta)
  else
    inst.components.debuff:Stop()
  end
end

local function BuffOnAttached(inst, target)
  inst.entity:SetParent(target.entity)
  inst.Transform:SetPosition(0, 0, 0)
  inst.task = inst:DoPeriodicTask(TICK_RATE, BuffOnTick, nil, target)
  inst:ListenForEvent("death", function() inst.components.debuff:Stop() end, target)
end

local function BuffOnExtended(inst, target)
  if (inst.components.timer:GetTimeLeft("regenover") or 0) < DURATION then
    inst.components.timer:StopTimer("regenover")
    inst.components.timer:StartTimer("regenover", DURATION)
  end
  if inst.task ~= nil then
    inst.task:Cancel()
    inst.task = inst:DoPeriodicTask(TICK_RATE, BuffOnTick, nil, target)
  end
end

local function BuffOnTimerDone(inst, data)
  if data.name == "regenover" then
    inst.components.debuff:Stop()
  end
end

local function BuffFn()
  local inst = CreateEntity()

  if not TheWorld.ismastersim then
    --Not meant for client!
    inst:DoTaskInTime(0, inst.Remove)

    return inst
  end

  inst.entity:AddTransform()

  --[[Non-networked entity]]
  --inst.entity:SetCanSleep(false)
  inst.entity:Hide()
  inst.persists = false

  inst:AddTag("CLASSIFIED")

  inst:AddComponent("debuff")
  inst.components.debuff:SetAttachedFn(BuffOnAttached)
  inst.components.debuff:SetDetachedFn(inst.Remove)
  inst.components.debuff:SetExtendedFn(BuffOnExtended)
  inst.components.debuff.keepondespawn = true

  inst:AddComponent("timer")
  inst.components.timer:StartTimer("regenover", DURATION)
  inst:ListenForEvent("timerdone", BuffOnTimerDone)

  return inst
end

local function OnEaten(inst, eater)
  local id = buffPrefab
  eater:AddDebuff(id, buffPrefab)
end

local function Fn()
  local inst = CreateEntity()

  inst.entity:AddTransform()
  inst.entity:AddAnimState()
  inst.entity:AddNetwork()

  MakeInventoryPhysics(inst)
  inst.AnimState:SetBank("kaltsit_neuro_gel")
  inst.AnimState:SetBuild("kaltsit_neuro_gel")
  inst.AnimState:PlayAnimation("idle")

  inst:AddTag("potion")
  inst:AddTag("pre-preparedfood")
  inst:AddTag("fooddrink")

  MakeInventoryFloatable(inst, "small", 0.2, 0.4)
  inst.entity:SetPristine()

  if not TheWorld.ismastersim then
    return inst
  end
  inst:AddComponent("inspectable")
  inst:AddComponent("inventoryitem")
  inst:AddComponent("stackable")
  MakeHauntableLaunch(inst)
  inst:AddComponent("edible")
  inst.components.edible.foodtype = FOODTYPE.GOODIES
	inst.components.edible.healthvalue = 0
	inst.components.edible.hungervalue = 0
	inst.components.edible.sanityvalue = 0
  inst.components.edible:SetOnEatenFn(OnEaten)
  return inst
end

return Prefab("kaltsit_neuro_gel", Fn, assets), Prefab(buffPrefab, BuffFn)
