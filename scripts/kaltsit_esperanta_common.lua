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

-- 是否装备生命修复单元（技能2的特殊弹药发射前置条件）
-- 遍历全部装备槽而非固定 BODY：五格/六格等扩展槽模组会把装备归到不同槽位
local function HasEquippedLifeRepairingUnits(inst)
  if not inst or not inst.replica.inventory then return false end
  local equips = inst.replica.inventory:GetEquips()
  if equips == nil then return false end
  for _, item in pairs(equips) do
    if item ~= nil and item.prefab == "life_repairing_units" then
      return true
    end
  end
  return false
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
  return skill and skill:IsActivating() and HasEquippedLifeRepairingUnits(inst) and GetEquippedSpecialTreatmentGun(inst)
end

local function CanHitSpecialTreatmentDestroyTarget(inst, target)
  return IsSpecialTreatmentDestroySkillActive(inst) and IsSpecialTreatmentDestroyableTarget(target)
end

local function CanTriggerSpecialTreatmentHealAction(inst, target)
  return (HasEquippedLoadedSpecialTreatmentGun(inst) or IsSpecialTreatmentDestroySkillActive(inst))
      and CanHitSpecialTreatmentHealTarget(inst, target)
end

local function CanTriggerSpecialTreatmentDestroyAction(inst, target)
  return HasEquippedSpecialTreatmentGun(inst)
      and CanHitSpecialTreatmentDestroyTarget(inst, target)
end

-- source_inst 与 pos 至少传一个：pos 缺省时用 source_inst 的位置。
-- source_inst 可空（如只有位置），但二者不能同时为空。
local function FindFriendlyEntities(source_inst, pos, range, fn)
  if range == nil or range <= 0 then
    return {}
  end
  if pos == nil then
    if source_inst ~= nil then
      pos = source_inst:GetPosition()
    else
      return {}
    end
  end
  local inst = source_inst
  -- pvp 的时候, 友方单位只有自己的宠物与自己, 否则包含玩家以及有玩家主人的宠物
  local ents = TheSim:FindEntities(pos.x, pos.y, pos.z, range, nil, { "INLIMBO" })
  local results = {}
  for i, ent in ipairs(ents) do
    local base = false
    local leader = ent.replica.follower and ent.replica.follower:GetLeader()
    if TheNet:GetPVPEnabled() then
      base = ent == inst or (inst and leader == inst)
    else
      base = ent:HasTag("player") or (leader and leader:HasTag("player"))
    end
    if base and (not fn or fn(ent)) then
      table.insert(results, ent)
    end
  end
  return results
end

-- 医者丰碑 buff：以 doer 为中心，覆盖 levelParams.range 内友方。
local function ActiveDoctorsMonumentsBuff(doer, pos, levelParams)
  local ents = FindFriendlyEntities(doer, pos, levelParams.range, function(ent)
    return not ent:HasTag("ghost")
  end)
  for _, ent in ipairs(ents) do
    ent:AddDebuff("doctors_monuments_invincible_buff", "doctors_monuments_invincible_buff", {
      buffConfig = {
        duration = levelParams.invincible_duration,
      }
    })
    ent:AddDebuff("doctors_monuments_treatment_buff", "doctors_monuments_treatment_buff", {
      health = levelParams.health,
      buffConfig = {
        duration = levelParams.treatment_duration,
      }
    })
  end
end

-- 凯尔希·思衡托技能音效
-- soundSource/kaltsit_esperanta/*.mp3 手动编译为 sound/kaltsit_esperanta.fev/.fsb。
-- FEV 事件组固定为 sfx，事件名与 mp3 文件名一致。
local SKILL_SFX_ROOT = "kaltsit_esperanta/sfx/"
local function PlaySkillSfx(inst, event, volume)
  if inst == nil or inst.SoundEmitter == nil then
    return
  end
  if volume == nil then
    volume = 0.35
  end
  inst.SoundEmitter:PlaySound(SKILL_SFX_ROOT .. event, nil, volume)
end

return {
  CanHitSpecialTreatmentHealTarget = CanHitSpecialTreatmentHealTarget,
  CanHitSpecialTreatmentDestroyTarget = CanHitSpecialTreatmentDestroyTarget,
  CanTriggerSpecialTreatmentHealAction = CanTriggerSpecialTreatmentHealAction,
  CanTriggerSpecialTreatmentDestroyAction = CanTriggerSpecialTreatmentDestroyAction,
  HasEquippedSpecialTreatmentGun = HasEquippedSpecialTreatmentGun,
  HasEquippedLifeRepairingUnits = HasEquippedLifeRepairingUnits,
  GetEquippedSpecialTreatmentGun = GetEquippedSpecialTreatmentGun,
  IsSpecialTreatmentGun = IsSpecialTreatmentGun,
  GetSpecialTreatmentGunLoadedAmmo = GetSpecialTreatmentGunLoadedAmmo,
  HasEquippedLoadedSpecialTreatmentGun = HasEquippedLoadedSpecialTreatmentGun,
  IsSpecialTreatmentDestroySkillActive = IsSpecialTreatmentDestroySkillActive,
  destroyableTags = destroyableTags,
  FindFriendlyEntities = FindFriendlyEntities,
  ActiveDoctorsMonumentsBuff = ActiveDoctorsMonumentsBuff,
  PlaySkillSfx = PlaySkillSfx,
}
