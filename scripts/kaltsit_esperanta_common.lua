local function CanSpecialHealTarget(inst, target)
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

local function IsGun(inst)
  return inst and inst.prefab == "special_treatment_gun"
      and inst.replica.container
end

local function HoldGun(inst)
  if not inst or not inst.replica.inventory then return false end
  local equiped = inst.replica.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
  return IsGun(equiped) and equiped
end

local function GetGunBullet(inst)
  return inst.replica.container and inst.replica.container:GetItemInSlot(1) or nil
end

local function IsGunAndBullet(inst)
  return IsGun(inst) and GetGunBullet(inst) ~= nil
end

local function HoldGunAndBullet(inst)
  local gun = HoldGun(inst)
  return IsGunAndBullet(gun)
end

local DestroyableTags = { "CHOP_workable", "MINE_workable", "HAMMER_workable", "DIG_workable" }
local function CanBeSpecialDestroy(inst)
  return inst:HasAnyTag(unpack(DestroyableTags))
end

local function CanSpecialDestroy(inst)
  return HoldGun(inst) and inst.replica.ark_skill and inst.replica.ark_skill:IsActivating("kaltsit_esperanta_skill2")
end


local function CanSpecialDestroyTarget(inst, target)
  if target.components.combat and target.components.combat:CanBeAttacked(inst) then
    return false
  end
  -- 只有二技能有子弹的情况下可以摧毁
  return CanSpecialDestroy(inst) and CanBeSpecialDestroy(target)
end

local function CanSpecialHarmTarget(inst, target)
  return not CanSpecialHealTarget(inst, target) and not CanSpecialDestroyTarget(inst, target)
end

local function CanPlayerShoot(inst)
  return HoldGunAndBullet(inst) or CanSpecialDestroy(inst)
end

return {
  CanSpecialHealTarget = CanSpecialHealTarget,
  CanSpecialDestroyTarget = CanSpecialDestroyTarget,
  CanSpecialHarmTarget = CanSpecialHarmTarget,
  CanSpecialDestroy = CanSpecialDestroy,
  HoldGun = HoldGun,
  IsGun = IsGun,
  GetGunBullet = GetGunBullet,
  IsGunAndBullet = IsGunAndBullet,
  HoldGunAndBullet = HoldGunAndBullet,
  CanPlayerShoot = CanPlayerShoot,
  CanBeSpecialDestroy = CanBeSpecialDestroy,
}