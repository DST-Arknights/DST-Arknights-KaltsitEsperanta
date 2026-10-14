local FOOD_TYPE = "KALTSIT_CLINICAL"

local function AppendFoodType(list)
  local result = {}
  local found = false
  for _, value in ipairs(list) do
    result[#result + 1] = value
    found = found or value == FOOD_TYPE
  end
  if not found then result[#result + 1] = FOOD_TYPE end
  return result
end

local function EnableEating(inst)
  local eater = inst.components.eater
  eater:SetDiet(AppendFoodType(eater.caneat), AppendFoodType(eater.preferseating))
  if eater.cacheedibletags ~= false then eater.cacheedibletags = nil end
end

local function CanConsume(inst)
  return inst ~= nil and inst:IsValid() and inst.prefab == "kaltsit_esperanta"
    and not inst:HasTag("playerghost") and inst.components.health ~= nil
    and not inst.components.health:IsDead()
end

local function GetMon3tr(owner)
  local master = owner.components.kaltsit_mon3tr_master
  local pet = master ~= nil and master:GetMon3tr() or nil
  local behavior = pet ~= nil and pet:IsValid() and pet.components.kaltsit_mon3tr_behavior or nil
  return behavior ~= nil and behavior:GetOwner() == owner
    and pet.components.health ~= nil and not pet.components.health:IsDead() and pet or nil
end

local function OnRegenTick(inst, target)
  inst._medicine_next_tick = GetTime() + 1
  if CanConsume(target) then
    inst._medicine_tick_fn(inst, target)
  else
    inst.components.debuff:Stop()
  end
end

local function StartRegen(inst, target, tickfn)
  if inst._medicine_task ~= nil then inst._medicine_task:Cancel() end
  inst._medicine_tick_fn = tickfn
  inst._medicine_next_tick = GetTime() + 1
  inst._medicine_task = inst:DoPeriodicTask(1, OnRegenTick, 1, target)
end

local function StopRegen(inst, target)
  -- 原版 timer 在同秒的周期任务之前结束时，补上到期的最后一次恢复。
  -- 手动移除、死亡或不足一秒的读档余量不会额外恢复。
  local timerkey = "ark_buff_timer_" .. inst.prefab
  if not inst.components.timer:TimerExists(timerkey)
    and inst._medicine_next_tick ~= nil and inst._medicine_next_tick <= GetTime() + 0.001
    and CanConsume(target) then
    inst._medicine_tick_fn(inst, target)
  end
  if inst._medicine_task ~= nil then
    inst._medicine_task:Cancel()
    inst._medicine_task = nil
  end
end

return {
  FOODTYPE = FOOD_TYPE,
  EnableEating = EnableEating,
  CanConsume = CanConsume,
  GetMon3tr = GetMon3tr,
  StartRegen = StartRegen,
  StopRegen = StopRegen,
}
