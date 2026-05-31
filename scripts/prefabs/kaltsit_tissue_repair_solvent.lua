local DURATION = 120
local TICK_RATE = 1
local buffPrefab = "kaltsit_tissue_repair_solvent_buff"

local assets = {
  Asset("ANIM", "anim/kaltsit_tissue_repair_solvent.zip"),
  Asset("ATLAS", "images/inventoryimages/kaltsit_tissue_repair_solvent.xml"),
}
RegisterInventoryItemAtlas("images/inventoryimages/kaltsit_tissue_repair_solvent.xml",
  "kaltsit_tissue_repair_solvent.tex")

local function BuffOnTick(inst, target)
  if target.components.health ~= nil then
    -- 回复1%的最大生命值
    local health_delta = math.ceil(target.components.health.maxhealth * 0.01)
    target.components.health:DoDelta(health_delta)
  else
    inst.components.debuff:Stop()
  end
end

local function BuffOnAttached(inst, target)
  if target.components.health ~= nil then
    -- 回复20%的最大生命值
    local health_delta = math.ceil(target.components.health.maxhealth * 0.2)
    target.components.health:DoDelta(health_delta)
  end
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
  eater:AddDebuff(buffPrefab, buffPrefab)
end

local function Fn()
  local inst = CreateEntity()

  inst.entity:AddTransform()
  inst.entity:AddAnimState()
  inst.entity:AddNetwork()

  MakeInventoryPhysics(inst)
  inst.AnimState:SetBank("kaltsit_tissue_repair_solvent")
  inst.AnimState:SetBuild("kaltsit_tissue_repair_solvent")
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

return Prefab("kaltsit_tissue_repair_solvent", Fn, assets), Prefab(buffPrefab, BuffFn)
