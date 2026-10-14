local constants = require("ark_constants")

local KILLED_STATE = "meltdown_killed"
local RUNTIME_FIELD = "_kaltsit_mon3tr_meltdown"
local MAX_CREDIT_DEPTH = 5

local function IsLiving(inst)
  return inst ~= nil and inst:IsValid() and not inst:HasAnyTag("playerghost", "corpse")
    and inst.components.health ~= nil and not inst.components.health:IsDead()
end

local function GetOwner(inst)
  local behavior = inst.components.kaltsit_mon3tr_behavior
  return behavior ~= nil and behavior:GetOwner() or nil
end

local function IsPet(inst)
  if not IsLiving(inst) or inst.prefab ~= "kaltsit_esperanta_mon3tr" then return false end
  local userid = inst.Network:GetUserID()
  return userid == nil or userid == ""
end

local function CanActivate(skill)
  local inst = skill.inst
  local owner = GetOwner(inst)
  local sanity_cost = skill:GetLevelParams().sanity_cost
  return IsPet(inst) and IsLiving(owner) and owner ~= inst
    and owner.components.sanity ~= nil and owner.components.sanity.current >= sanity_cost
    and inst.sg ~= nil and not inst.sg:HasStateTag("nocommand")
    and (inst.components.rider == nil or not inst.components.rider:IsRiding())
end

local function ClearRuntime(skill)
  local runtime = skill[RUNTIME_FIELD]
  skill[RUNTIME_FIELD] = nil
  if runtime ~= nil then
    for _, token in ipairs(runtime.listeners) do skill:RemoveEventCallback(token) end
  end
  local inst = skill.inst
  local combat = inst.components.combat
  local health = inst.components.health
  if combat ~= nil then
    combat.externaldamagemultipliers:RemoveModifier(inst, skill.id)
    combat.truedamagemultipliers:RemoveModifier(inst, skill.id)
  end
  if health ~= nil then health.externalabsorbmodifiers:RemoveModifier(inst, skill.id) end
end

local function Abort(skill)
  -- Cancel(true) 会发 force=true 的结束事件；读档或卸载期间也可幂等清理。
  if skill:IsActivating() then skill:Cancel(true) end
  ClearRuntime(skill)
  skill:RemoveState(KILLED_STATE)
end

local function OwnsCast(skill, runtime)
  return IsPet(skill.inst) and IsLiving(runtime.owner)
    and GetOwner(skill.inst) == runtime.owner
end

local function IsKillSource(skill, source, victim)
  local visited = {}
  -- 与源枢奖励使用同一溯源边界；只接受实际经过本 Mon3tr 的来源链。
  for depth = 1, MAX_CREDIT_DEPTH do
    if source == nil or not source:IsValid() or visited[source] then break end
    if source == skill.inst then return true end
    visited[source] = true
    local transfer = source.components.ark_kill_transfer
    if transfer == nil then break end
    source = transfer:GetCreditTarget(victim)
  end
  return false
end

local function OnEntityDeath(skill, data)
  local runtime = skill[RUNTIME_FIELD]
  local victim = data ~= nil and data.inst or nil
  if runtime == nil or not OwnsCast(skill, runtime) or victim == nil
    or victim == skill.inst or victim == runtime.owner
    or victim.components.combat == nil or victim.components.health == nil
    or victim:HasAnyTag("companion", "playerghost")
    or skill.inst.components.combat:IsAlly(victim) then
    return
  end
  if IsKillSource(skill, data.afflicter, victim) then skill:SetState(KILLED_STATE, true) end
end

local function UpdateModifiers(skill)
  local runtime = skill[RUNTIME_FIELD]
  local duration = skill:GetLevelConfig().buffDuration
  local second = math.floor(math.max(0, skill.data.buffProgress) + 0.000001)
  if runtime.second == second then return end
  runtime.second = second
  local fraction = math.max(0, 1 - second / duration)
  local params = skill:GetLevelParams()
  local inst = skill.inst
  -- 独立来源，与源枢/其他模组已有倍率共存；吸收按原版加算并在结算时封顶。
  inst.components.combat.externaldamagemultipliers:SetModifier(inst, 1 + params.damage_bonus * fraction, skill.id)
  inst.components.health.externalabsorbmodifiers:SetModifier(inst, params.absorb * fraction, skill.id)
end

local function Apply(skill)
  if not skill:IsActivating() then return end
  local runtime = skill[RUNTIME_FIELD]
  if runtime ~= nil then return end
  local owner = GetOwner(skill.inst)
  if not IsPet(skill.inst) or not IsLiving(owner) or owner == skill.inst then
    Abort(skill)
    return
  end
  runtime = { owner = owner, listeners = {} }
  skill[RUNTIME_FIELD] = runtime
  local function Listen(event, fn, source)
    runtime.listeners[#runtime.listeners + 1] = skill:ListenForEvent(event, fn, source)
  end
  local function OnOwnershipChanged()
    if not OwnsCast(skill, runtime) then Abort(skill) end
  end
  Listen("entity_death", function(_, data) OnEntityDeath(skill, data) end, TheWorld)
  Listen("death", function() Abort(skill) end)
  Listen("death", function() Abort(skill) end, owner)
  Listen("onremove", function() Abort(skill) end, owner)
  Listen("leaderchanged", OnOwnershipChanged)
  Listen("setowner", OnOwnershipChanged)
  -- 避免 EnableTrueDamage 的统一 key 覆盖其他真伤效果。
  skill.inst.components.combat.truedamagemultipliers:SetModifier(skill.inst, 1, skill.id)
  UpdateModifiers(skill)
end

local function Activate(skill)
  ClearRuntime(skill)
  skill:SetState(KILLED_STATE, false)
  if not CanActivate(skill) then
    Abort(skill)
    return
  end
  GetOwner(skill.inst).components.sanity:DoDelta(-skill:GetLevelParams().sanity_cost)
  skill.inst.components.kaltsit_mon3tr_behavior:SetMode("attack")
  Apply(skill)
end

local function LoadPostPass(skill)
  -- ark_skill 的 OnActivateEffect 在读档时恢复持续效果，不重置已有击杀标记。
  Apply(skill)
end

local function Step(skill)
  local runtime = skill[RUNTIME_FIELD]
  if runtime == nil then return end
  if not OwnsCast(skill, runtime) then
    Abort(skill)
  elseif skill:IsActivating() then
    -- 复用 ark_skill 的 buffProgress，逐秒衰减；不另建计时器。
    UpdateModifiers(skill)
  end
end

local function End(skill, payload)
  local runtime = skill[RUNTIME_FIELD]
  -- 自然到期由框架转为充能；Cancel、Lock、Remove、死亡和接管均不结算反噬。
  local punish = runtime ~= nil and OwnsCast(skill, runtime)
    and skill.data.status == constants.SKILL_STATUS.ENERGY_RECOVERING
    and payload ~= nil and payload.force ~= true and not skill._removing
    and skill:GetState(KILLED_STATE) ~= true
  ClearRuntime(skill)
  skill:RemoveState(KILLED_STATE)
  if punish then
    local health = skill.inst.components.health
    local params = skill:GetLevelParams()
    -- 生命消耗不被熔毁/被动吸收抵消，仍保留原版生命下限及其他 health 中间件。
    health:DoDelta(-health.maxhealth * params.penalty_health_percent, false, skill.id, true, nil, true)
  end
end

-- 配置：buffDuration=20；params={damage_bonus=2,absorb=0.5,penalty_health_percent=0.5,sanity_cost=20}。
return {
  CanActivate = CanActivate,
  Activate = Activate,
  End = End,
  LoadPostPass = LoadPostPass,
  Step = Step,
}
