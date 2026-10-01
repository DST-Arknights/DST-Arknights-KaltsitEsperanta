table.insert(Assets, Asset("ATLAS", "images/ui_kaltsit_esperanta_skill.xml"))

local ARK_CONSTANTS = require("ark_constants")
local common = require("kaltsit_esperanta_common")

local SKILL_VOICE_KEYS = {
  kaltsit_esperanta_skill1 = "KALTSIT_ESPERANTA_SKILL_1",
  kaltsit_esperanta_skill2 = "KALTSIT_ESPERANTA_SKILL_2",
  -- 思衡托作战中3/4：随机选择独立 key，使文字与语音严格对应。
  kaltsit_esperanta_skill3 = {
    "KALTSIT_ESPERANTA_SKILL_3_A",
    "KALTSIT_ESPERANTA_SKILL_3_B",
  },
}

local SKILL_VOICE_CHANNEL = "kaltsit_esperanta_skill_voice"

local function SaySkillVoice(inst, skill_id)
  local key = SKILL_VOICE_KEYS[skill_id]
  if type(key) == "table" then
    key = key[math.random(1, #key)]
  end
  SayAndVoice(inst, key, { voice_channel = SKILL_VOICE_CHANNEL })
end

-- 三技能范围选择器（预声明，targetSelector 引用）
RegisterTargetSelector("kaltsit_esperanta_skill3_aoe", AreaTargetSelector {
  range          = 20,
  deployradius   = 1,
  reticuleprefab = "kaltsit_esperanta_skill3_reticuleaoe",
  pingprefab     = "kaltsit_esperanta_skill3_reticuleaoeping",
})


local skill1DefaultParams = { range = 20, health = 2, invincible_duration = 10, treatment_duration = 20, health_cost = 40, sanity_cost = 40 }
local SKILL1_COOLDOWN = 2 * 60
local SKILL2_COOLDOWN = 2 * 60
local SKILL3_COOLDOWN = 10 * 60
local SKILL3_DURATION = 2 * 60
local SKILL4_COOLDOWN = 1 * 60 * 0.1
local MON3TR_PREFAB = "kaltsit_esperanta_mon3tr"

local function FindMon3tr(inst)
  for follower in pairs(inst.components.leader.followers) do
    if follower.prefab == MON3TR_PREFAB and follower:IsValid() then
      return follower
    end
  end
end

local function IsSafeSummonPoint(pos)
  local map = TheWorld.Map
  return map:IsPassableAtPoint(pos.x, 0, pos.z, false)
    and not map:IsGroundTargetBlocked(pos)
    and not map:IsPointNearHole(pos)
end

local function FindMon3trSummonPoint(inst)
  local pos = inst:GetPosition()
  local angle = inst.Transform:GetRotation() * DEGREES
  -- 沿用阿比盖尔的落点检查，额外避开海水和洞口；允许落在船的平台上。
  local offset = FindWalkableOffset(pos, angle, 2, 12, true, false, IsSafeSummonPoint, false, true)
  if offset ~= nil then
    return pos + offset
  end
  return IsSafeSummonPoint(pos) and pos or nil
end

local function OnSkill4Install(skill)
  -- owner 的删除先发 onremove，再清理组件；上下线交给 petleash。
  skill:ListenForEvent("onremove", function()
    skill._ownerRemoving = true
  end)
  skill:Unlock()
end

local function OnSkill4ActivateTest(skill)
  if FindMon3tr(skill.inst) ~= nil then
    return false, "KALTSIT_ESPERANTA_MON3TR_ALREADY_SUMMONED"
  end
  skill._summonPoint = FindMon3trSummonPoint(skill.inst)
  if skill._summonPoint == nil then
    return false, "KALTSIT_ESPERANTA_NEED_SAFE_GROUND"
  end
  return true
end

local function OnSkill4Activate(skill)
  skill:ClearState()
  local pos = skill._summonPoint or FindMon3trSummonPoint(skill.inst)
  skill._summonPoint = nil
  if pos ~= nil then
    skill._mon3tr = skill.inst.components.petleash:SpawnPetAt(pos.x, 0, pos.z, MON3TR_PREFAB)
  end
  if skill._mon3tr == nil then
    skill:CutBullet()
    skill:AddEnergyProgress(SKILL4_COOLDOWN)
  end
end

local function OnSkill4ActivateEffect(skill)
  if not skill:IsActivating() then
    return
  end
  -- petleash 已同步恢复宠物并 AddFollower；只从 leader 找回，绝不重复生成。
  local pet = FindMon3tr(skill.inst)
  if pet == nil then
    skill:CutBullet()
    return
  end
  if skill._mon3tr == pet and skill._mon3trRemoveListener ~= nil then
    return
  end
  skill:RemoveEventCallback(skill._mon3trRemoveListener)
  skill._mon3tr = pet
  pet.components.follower.neverexpire = true
  pet.components.follower.keepleaderduringminigame = true
  pet.components.follower:CancelLoyaltyTask()
  skill._mon3trRemoveListener = skill:ListenForEvent("onremove", function()
    -- 此时实体尚未 Retire，先清引用，避免结束技能再次 DespawnPet 造成重入。
    skill._mon3tr = nil
    skill._mon3trRemoveListener = nil
    if not skill._ownerRemoving and not skill._removing and skill:IsActivating() then
      skill:CutBullet()
    end
  end, pet)
end

local function OnSkill4Deactivate(skill)
  skill:RemoveEventCallback(skill._mon3trRemoveListener)
  skill._mon3trRemoveListener = nil
  local pet = skill._mon3tr
  skill._mon3tr = nil
  if not skill._ownerRemoving and pet ~= nil and pet:IsValid() then
    skill.inst.components.petleash:DespawnPet(pet)
  end
end

local function OnSkill1ActivateTest(skill)
  local inst = skill.inst
  local levelParams = skill:GetLevelParams()
  -- 生命值不足
  if inst.components.health ~= nil and
      inst.components.health.currenthealth < (levelParams.health_cost or 0) then
    return false, 'KALTSIT_ESPERANTA_NOT_ENOUGH_HEALTH'
  end
  -- 精神值不足
  if inst.components.sanity ~= nil and
      inst.components.sanity.current < (levelParams.sanity_cost or 0) then
    return false, 'KALTSIT_ESPERANTA_NOT_ENOUGH_SANITY'
  end
  return true
end

local function OnSkill1Activate(skill, data)
  SaySkillVoice(skill.inst, "kaltsit_esperanta_skill1")
  -- 扫描附近玩家, 给予buff
  local levelParams = skill:GetLevelParams()
  if skill.inst.components.health then
    skill.inst.components.health:DoDelta(-levelParams.health_cost, nil, "kaltsit_esperanta_skill1")
  end
  if skill.inst.components.sanity then
    skill.inst.components.sanity:DoDelta(-levelParams.sanity_cost)
  end
  common.ActiveDoctorsMonumentsBuff(skill.inst, nil, levelParams)
  common.PlaySkillSfx(skill.inst, "b_char_healboost")
end

local function OnSkill2ActivateTest(skill)
  local inst = skill.inst
  -- 启动前置：必须同时装备特质治疗枪与生命修复单元
  if not common.HasEquippedSpecialTreatmentGun(inst) then
    return false, 'KALTSIT_ESPERANTA_NEED_SPECIAL_TREATMENT_GUN'
  end
  if not common.HasEquippedLifeRepairingUnits(inst) then
    return false, 'KALTSIT_ESPERANTA_NEED_LIFE_REPAIRING_UNITS'
  end
  -- 精神值不足（启动时扣除 levelParams.sanity_cost）
  local levelParams = skill:GetLevelParams()
  if inst.components.sanity ~= nil and
      inst.components.sanity.current < (levelParams.sanity_cost or 0) then
    return false, 'KALTSIT_ESPERANTA_NOT_ENOUGH_SANITY'
  end
  return true
end

local function OnSkill2Activate(skill, data)
  local inst = skill.inst
  SaySkillVoice(inst, "kaltsit_esperanta_skill2")
  local levelParams = skill:GetLevelParams()
  if inst.components.sanity then
    inst.components.sanity:DoDelta(-levelParams.sanity_cost)
  end
  common.PlaySkillSfx(inst, "p_skill_khlrftcr_h")
end

local SKILL2_DAMAGE_PERCENT = 0.03
local SKILL2_DAMAGE_LEVEL_INCREMENT = 500
local SKILL2_DAMAGE_MODE_BASE = {
  fixed_1000 = 1000,
  fixed_2000 = 2000,
  percentage = 500,
}
local Skill2LevelDesc

local function MakeSkill2Level(level)
  local mode = TUNING.KALTSIT_ESPERANTA_SKILL2_DAMAGE_MODE or "percentage"
  local baseDamage = SKILL2_DAMAGE_MODE_BASE[mode] or SKILL2_DAMAGE_MODE_BASE.percentage
  return {
    activationEnergy = SKILL2_COOLDOWN,
    bulletCount = 10,
    desc = Skill2LevelDesc,
    params = {
      sanity_cost = 200,
      damage = baseDamage + (level - 1) * SKILL2_DAMAGE_LEVEL_INCREMENT,
      damage_percent = mode == "percentage" and SKILL2_DAMAGE_PERCENT or 0,
      aoeRange = 6,
      health = 80,
    },
  }
end

Skill2LevelDesc = function(skill)
  local params = skill:GetLevelParams()
  local damagePercent = params.damage_percent or 0
  local percentDesc = STRINGS.UI.KALTSIT_ESPERANTA_SKILL.LEVEL_DESC["2_PERCENT"]
  if damagePercent > 0 and percentDesc ~= nil then
    return string.format(percentDesc, params.damage, damagePercent * 100, params.health)
  end
  return string.format(STRINGS.UI.KALTSIT_ESPERANTA_SKILL.LEVEL_DESC[2], params.damage, params.health)
end

local function OnSkill3Activate(skill, data)
  skill:RemoveState("recast")
  local inst = skill.inst
  local pos = data.targetPos
  if not pos then
    return false, 'SKILL_CANNOT_ACTIVATE'
  end
  SaySkillVoice(inst, "kaltsit_esperanta_skill3")
  local anchor = SpawnPrefab("tactical_anchor")
  anchor.Transform:SetPosition(pos:Get())
  common.PlaySkillSfx(inst, "p_imp_khlrftcrmk")
  anchor.components.tactical_anchor:SetOwner(inst)
  -- 领域 buff 强度：每秒回最大生命 2% + 攻击力提升 20%（health_percent / damage_multiplier）
  anchor.components.tactical_anchor:SetFieldParams(skill:GetLevelParams())
  skill:SetState("anchor", anchor)
  local skill1 = inst.components.ark_skill:GetSkill("kaltsit_esperanta_skill1")
  local skill1Params = skill1 and skill1:GetLevelParams() or skill1DefaultParams
  common.ActiveDoctorsMonumentsBuff(inst, pos, skill1Params)
  common.PlaySkillSfx(inst, "p_skill_khlrftcr_s")
  inst:DoTaskInTime(0.7, function()
    common.PlaySkillSfx(inst, "p_skill_khlrftcrfd")
  end)
  inst.SoundEmitter:PlaySound("dontstarve/wilson/attack_whoosh", nil, nil, true)
  inst.sg:GoToState("quickcastspell")
  return true
end

local function OnSkill3Recast(skill, data)
  local inst = skill.inst
  local anchor = skill:GetState("anchor")
  if not anchor then
    return false
  end
  local ta = anchor.components.tactical_anchor
  if not ta:CanTargetTeleported(inst) then
    return false
  end
  if skill:GetState("recast") then
    return false
  end
  skill:SetState("recast", true)
  local anchorPos = anchor:GetPosition()
  local skill1 = skill.inst.components.ark_skill:GetSkill("kaltsit_esperanta_skill1")
  local skill1Params = skill1 and skill1:GetLevelParams() or skill1DefaultParams
  common.ActiveDoctorsMonumentsBuff(inst, anchorPos, skill1Params)
  local buff = BufferedAction(inst, anchor, ACTIONS.USE_TACTICAL_ANCHOR, nil, anchorPos, nil, nil, true)
  inst:PushBufferedAction(buff)
  return true
end

local function OnSkill3Deactivate(skill)
  local anchor = skill:GetState("anchor")
  if anchor then
    anchor:Remove()
    skill:SetState("anchor", nil)
  end
end

local function OnSkill3ActivateTest(skill, data)
  -- 三技能需要在指定位置部署锚点；没有有效落点时不要进入激活态（Activate 不检查回调返回值）
  if data == nil or data.targetPos == nil then
    return false, 'KALTSIT_ESPERANTA_NEED_VALID_TARGET'
  end
  return true
end

local skills = { {
  id = "kaltsit_esperanta_skill1",
  name = STRINGS.UI.KALTSIT_ESPERANTA_SKILL.NAME[1],
  energyRecoveryMode = ARK_CONSTANTS.ENERGY_RECOVERY_MODE.AUTO,
  activationMode = ARK_CONSTANTS.ACTIVATION_MODE.MANUAL,
  lockedDesc = STRINGS.UI.KALTSIT_ESPERANTA_SKILL.LOCKED_DESC[1],
  hotkey = KEY_Z,
  atlas = "images/ui_kaltsit_esperanta_skill.xml",
  image = "skill1.tex",
  recipe_atlas = "images/ui_kaltsit_esperanta_skill.xml",
  recipe_image = "skill1_recipe.tex",
  ActivateTest = OnSkill1ActivateTest,
  OnActivate = OnSkill1Activate,
  levels = { {
    activationEnergy = SKILL1_COOLDOWN,
    desc = STRINGS.UI.KALTSIT_ESPERANTA_SKILL.LEVEL_DESC[1][1],
    params = skill1DefaultParams,
  } }
}, {
  id = "kaltsit_esperanta_skill2",
  name = STRINGS.UI.KALTSIT_ESPERANTA_SKILL.NAME[2],
  energyRecoveryMode = ARK_CONSTANTS.ENERGY_RECOVERY_MODE.AUTO,
  activationMode = ARK_CONSTANTS.ACTIVATION_MODE.MANUAL,
  lockedDesc = STRINGS.UI.KALTSIT_ESPERANTA_SKILL.LOCKED_DESC[2],
  hotkey = KEY_X,
  atlas = "images/ui_kaltsit_esperanta_skill.xml",
  image = "skill2.tex",
  recipe_atlas = "images/ui_kaltsit_esperanta_skill.xml",
  recipe_image = "skill2_recipe.tex",
  ActivateTest = OnSkill2ActivateTest,
  OnActivate = OnSkill2Activate,
  levels = {
    MakeSkill2Level(1),
    MakeSkill2Level(2),
    MakeSkill2Level(3),
    MakeSkill2Level(4),
  }
}, {
  id = "kaltsit_esperanta_skill3",
  name = STRINGS.UI.KALTSIT_ESPERANTA_SKILL.NAME[3],
  energyRecoveryMode = ARK_CONSTANTS.ENERGY_RECOVERY_MODE.AUTO,
  activationMode = ARK_CONSTANTS.ACTIVATION_MODE.MANUAL,
  lockedDesc = STRINGS.UI.KALTSIT_ESPERANTA_SKILL.LOCKED_DESC[3],
  hotkey = KEY_C,
  atlas = "images/ui_kaltsit_esperanta_skill.xml",
  image = "skill3.tex",
  recipe_atlas = "images/ui_kaltsit_esperanta_skill.xml",
  recipe_image = "skill3_recipe.tex",
  ActivateTest = OnSkill3ActivateTest,
  OnActivate = OnSkill3Activate,
  OnRecast = OnSkill3Recast,
  OnDeactivate = OnSkill3Deactivate,
  targetSelector = "kaltsit_esperanta_skill3_aoe",
  levels = { {
    activationEnergy = SKILL3_COOLDOWN,
    buffDuration = SKILL3_DURATION,
    desc = STRINGS.UI.KALTSIT_ESPERANTA_SKILL.LEVEL_DESC[3][1],
    params = { range = 20, health_percent = 0.02, damage_multiplier = 0.2 }
  } }
}, {
  id = "kaltsit_esperanta_skill4",
  name = STRINGS.UI.KALTSIT_ESPERANTA_SKILL.NAME[4],
  energyRecoveryMode = ARK_CONSTANTS.ENERGY_RECOVERY_MODE.AUTO,
  activationMode = ARK_CONSTANTS.ACTIVATION_MODE.MANUAL,
  hotkey = KEY_V,
  atlas = "images/ui_kaltsit_esperanta_skill.xml",
  image = "skill4.tex",
  recipe_atlas = "images/ui_kaltsit_esperanta_skill.xml",
  recipe_image = "skill4.tex",
  OnInstall = OnSkill4Install,
  ActivateTest = OnSkill4ActivateTest,
  OnActivate = OnSkill4Activate,
  OnActivateEffect = OnSkill4ActivateEffect,
  OnDeactivate = OnSkill4Deactivate,
  levels = { {
    activationEnergy = SKILL4_COOLDOWN,
    bulletCount = 1,
    desc = STRINGS.UI.KALTSIT_ESPERANTA_SKILL.LEVEL_DESC[4][1],
  } }
} }

-- 第二个技能特殊些, 是从7级开始, 前面6个填充第7个
do
  local levels = skills[2].levels
  local pad = levels[1]
  for i = 2, 7 do
    table.insert(levels, i - 1, pad)
  end
end


for _, skill in ipairs(skills) do
  RegisterArkSkill(skill)
end

AddComponentPostInit("combat", function(self)
  ArkHookFunction(self, "GetAttacked", function(next, self, ...)
    local buff_name = "doctors_monuments_invincible_buff"
    if self.inst:HasDebuff(buff_name) then
      local fx = SpawnPrefab("shadow_shield1")
      fx.entity:SetParent(self.inst.entity)
      self.inst:RemoveDebuff(buff_name)
      return true
    end
    return next(self, ...)
  end)
end)
