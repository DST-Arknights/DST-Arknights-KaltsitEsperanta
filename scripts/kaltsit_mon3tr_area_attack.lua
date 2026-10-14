local RADIUS = 4
local EXCLUDE_TAGS = {
  "INLIMBO", "DECOR", "FX", "NOCLICK", "ghost", "playerghost", "companion",
  "notarget", "noattack", "flight", "invisible", "noauradamage",
}

local function GetOwner(inst)
  local behavior = inst.components.kaltsit_mon3tr_behavior
  return behavior ~= nil and behavior:GetOwner() or nil
end

local function IsEnemy(inst, target, primary)
  local combat = inst.components.combat
  return target ~= nil and target ~= primary and target ~= inst and target ~= GetOwner(inst)
    and target:IsValid() and not target:IsInLimbo() and target.entity:IsVisible()
    and not target:HasAnyTag(unpack(EXCLUDE_TAGS))
    and target.components.health ~= nil and not target.components.health:IsDead()
    and target.components.combat ~= nil and target.components.minigame_participator == nil
    and combat:CanTarget(target) and not combat:IsAlly(target)
    and inst:GetDistanceSqToInst(target) <= RADIUS * RADIUS
end

local function Attack(inst, primary, weapon)
  local userid = inst.Network:GetUserID()
  if (userid ~= nil and userid ~= "") or primary == nil or GetOwner(inst) == nil
    or not inst:IsValid() or inst.components.health:IsDead() then
    return 0
  end
  -- 主目标已由原版 ATTACK 结算。仅追加以自身为圆心的范围命中，工作空挥不调用。
  -- 原版 DoAreaAttack 逐目标 CalcDamage/GetAttacked，保留熔毁、真伤与其他模组的修正。
  return inst.components.combat:DoAreaAttack(inst, RADIUS, weapon, function(target)
    return IsEnemy(inst, target, primary)
  end, nil, EXCLUDE_TAGS)
end

return { Attack = Attack }
