local M = {}

local function IsAlive(inst)
  return inst ~= nil and inst:IsValid() and not inst:HasAnyTag("playerghost", "corpse", "INLIMBO")
    and inst.components.health ~= nil and not inst.components.health:IsDead()
end

local function GetOwner(skill)
  local behavior = skill.inst.components.kaltsit_mon3tr_behavior
  return behavior ~= nil and behavior:GetOwner() or nil
end

function M.CanActivate(skill)
  local pet = skill.inst
  local owner = GetOwner(skill)
  local userid = pet.Network:GetUserID()
  local cost = skill:GetLevelParams().sanity_cost or 20
  return (userid == nil or userid == "") and owner ~= pet and IsAlive(pet) and IsAlive(owner)
    and pet.sg ~= nil and not pet.sg:HasStateTag("busy") and not pet.sg:HasStateTag("nocommand")
    and owner.components.sanity ~= nil and owner.components.sanity.current >= cost
end

local function KeepHealthDelta(_, amount)
  return amount
end

local function AttachTarget(skill, target, key)
  local health = target.components.health
  if health.deltamodifierfn == nil then
    health.deltamodifierfn = KeepHealthDelta
  end
  local fn = function(next, inst, amount, overtime, cause, ignore_invincible, afflicter, ignore_absorb)
    amount = next(inst, amount, overtime, cause, ignore_invincible, afflicter, ignore_absorb)
    if not skill:IsActivating() or not IsAlive(inst) then
      return amount
    end
    local params = skill:GetLevelParams()
    if amount > 0 then
      -- DoDelta 的生命减伤/修改回调已执行；仅把实际将溢出的治疗转为盾。
      local overflow = math.max(0, health.currenthealth + amount - health:GetMaxWithPenalty())
      if overflow > 0 then
        skill:SetState(key, (skill:GetState(key) or 0) + overflow)
      end
    elseif amount < 0 and (not ignore_absorb or cause == "kaltsit_mon3tr_symbiosis") then
      local damage = -amount
      if not overtime then
        damage = math.min(damage, health:GetMaxWithPenalty() * params.damage_cap)
      end
      -- 先尊重原版已有的单次上限，护盾只消耗真正需要承受的伤害。
      if health.maxdamagetakenperhit ~= nil and not health._ignore_maxdamagetakenperhit then
        damage = math.min(damage, -health.maxdamagetakenperhit)
      end
      local shield = skill:GetState(key) or 0
      local absorbed = math.min(shield, damage)
      if absorbed > 0 then
        skill:SetState(key, shield - absorbed)
      end
      amount = -(damage - absorbed)
    end
    return amount
  end
  ArkHookFunction(health, "deltamodifierfn", fn)
  table.insert(skill._reinforce_targets, { target = target, health = health, fn = fn })
end

function M.Apply(skill)
  if not skill:IsActivating() or skill._reinforce_targets ~= nil then
    return
  end
  local pet = skill.inst
  local owner = GetOwner(skill)
  if not IsAlive(pet) or not IsAlive(owner) or owner == pet then
    skill:Cancel(true)
    return
  end
  skill._reinforce_targets = {}
  skill._reinforce_owner = owner
  owner._kaltsit_mon3tr_healing_skill = skill
  AttachTarget(skill, owner, "owner_shield")
  AttachTarget(skill, pet, "pet_shield")
end

function M.Activate(skill)
  skill:ClearState()
  local owner = GetOwner(skill)
  owner.components.sanity:DoDelta(-(skill:GetLevelParams().sanity_cost or 20))
end

function M.Step(skill)
  if skill:IsActivating() and skill._reinforce_targets ~= nil then
    local owner = skill._reinforce_owner
    local userid = skill.inst.Network:GetUserID()
    if not IsAlive(owner) or not IsAlive(skill.inst) or GetOwner(skill) ~= owner
      or (userid ~= nil and userid ~= "") then
      skill:Cancel(true)
    end
  end
end

function M.End(skill)
  if skill._reinforce_targets ~= nil then
    for _, entry in ipairs(skill._reinforce_targets) do
      ArkUnhookFunction(entry.health, "deltamodifierfn", entry.fn)
    end
    skill._reinforce_targets = nil
  end
  local owner = skill._reinforce_owner
  if owner ~= nil and owner._kaltsit_mon3tr_healing_skill == skill then
    owner._kaltsit_mon3tr_healing_skill = nil
  end
  skill._reinforce_owner = nil
  skill:RemoveState("owner_shield")
  skill:RemoveState("pet_shield")
end

-- 所有治疗仍走原版 DoDelta；施术者由本项目的治疗入口传入 afflicter。
function M.InstallHealingBonus(health)
  ArkHookFunction(health, "DoDelta", function(next, self, amount, overtime, cause, ignore_invincible, afflicter, ignore_absorb)
    local skill = afflicter ~= nil and afflicter._kaltsit_mon3tr_healing_skill or nil
    if amount > 0 and skill ~= nil and skill:IsActivating() then
      amount = amount * (skill:GetLevelParams().healing_mult or 2)
    end
    return next(self, amount, overtime, cause, ignore_invincible, afflicter, ignore_absorb)
  end)
end

return M
