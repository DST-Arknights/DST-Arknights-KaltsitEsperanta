local function CanHitSpecialTreatmentHealTarget(inst, target)
  if not inst or not target then
    return false
  end
  if inst == target then
    return true
  end
  local leader = target.replica.follower and target.replica.follower:GetLeader()
  if leader == inst then
    return true
  end
  if not TheNet:GetPVPEnabled() and (target:HasTag("player") or (leader and leader:HasTag("player"))) then
    return true
  end
  return false
end

local function IsSpecialTreatmentGun(inst)
  return inst and inst.prefab == "special_treatment_gun"
      and inst.replica.container
end

local function GetEquippedSpecialTreatmentGun(inst)
  if not inst or not inst.replica.inventory then return nil end
  local equipped = inst.replica.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
  return IsSpecialTreatmentGun(equipped) and equipped or nil
end

local function HasEquippedSpecialTreatmentGun(inst)
  return GetEquippedSpecialTreatmentGun(inst) ~= nil
end

local function GetSpecialTreatmentGunLoadedAmmo(inst)
  return inst.replica.container and inst.replica.container:GetItemInSlot(1) or nil
end

local function HasEquippedLoadedSpecialTreatmentGun(inst)
  local gun = GetEquippedSpecialTreatmentGun(inst)
  return gun ~= nil and GetSpecialTreatmentGunLoadedAmmo(gun) ~= nil
end

local destroyableTags = { "CHOP_workable", "MINE_workable", "HAMMER_workable", "DIG_workable" }
local function IsSpecialTreatmentDestroyableTarget(inst)
  if inst == nil then
    return false
  end
  return inst:HasAnyTag(unpack(destroyableTags))
end

local function IsSpecialTreatmentDestroySkillActive(inst)
  local skill = inst.replica.ark_skill and inst.replica.ark_skill:GetSkill("kaltsit_esperanta_skill2")
  return skill and skill:IsActivating() and GetEquippedSpecialTreatmentGun(inst)
end

local function CanHitSpecialTreatmentDestroyTarget(inst, target)
  return IsSpecialTreatmentDestroySkillActive(inst) and IsSpecialTreatmentDestroyableTarget(target)
end

local function CanTriggerSpecialTreatmentHealAction(inst, target)
  return HasEquippedSpecialTreatmentGun(inst)
      and CanHitSpecialTreatmentHealTarget(inst, target)
end

local function CanTriggerSpecialTreatmentDestroyAction(inst, target)
  return HasEquippedSpecialTreatmentGun(inst)
      and CanHitSpecialTreatmentDestroyTarget(inst, target)
end

local function FindFriendlyEntities(instOrPos, range, fn)
  local inst = nil
  local pos = nil
  if EntityScript.is_instance(instOrPos) then
    inst = instOrPos
    pos = instOrPos:GetPosition()
  elseif Vector3.is_instance(instOrPos) then
    pos = instOrPos
  elseif type(instOrPos) == "table" then
    inst = instOrPos.inst
    pos = instOrPos.pos or instOrPos:GetPosition()
  end
  -- pvp 的时候, 友方单位只有自己的宠物与自己, 否则包含玩家以及有玩家主人的宠物
  return TheSim:FindEntities(pos.x, pos.y, pos.z, range, function(ent)
    local base = false
    local leader = ent.replica.follower and ent.replica.follower:GetLeader()
    if TheNet:GetPVPEnabled()then
      base = ent == inst or (inst and leader == inst)
    else
      base = ent:HasTag("player") or (leader and leader:HasTag("player"))
    end
    return base and (not fn or fn(ent))
  end, { "INLIMBO" })
end

return {
  CanHitSpecialTreatmentHealTarget = CanHitSpecialTreatmentHealTarget,
  CanHitSpecialTreatmentDestroyTarget = CanHitSpecialTreatmentDestroyTarget,
  CanTriggerSpecialTreatmentHealAction = CanTriggerSpecialTreatmentHealAction,
  CanTriggerSpecialTreatmentDestroyAction = CanTriggerSpecialTreatmentDestroyAction,
  HasEquippedSpecialTreatmentGun = HasEquippedSpecialTreatmentGun,
  GetEquippedSpecialTreatmentGun = GetEquippedSpecialTreatmentGun,
  IsSpecialTreatmentGun = IsSpecialTreatmentGun,
  GetSpecialTreatmentGunLoadedAmmo = GetSpecialTreatmentGunLoadedAmmo,
  HasEquippedLoadedSpecialTreatmentGun = HasEquippedLoadedSpecialTreatmentGun,
  IsSpecialTreatmentDestroySkillActive = IsSpecialTreatmentDestroySkillActive,
  destroyableTags = destroyableTags,
  FindFriendlyEntities = FindFriendlyEntities,
}
