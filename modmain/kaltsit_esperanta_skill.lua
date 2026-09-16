table.insert(Assets, Asset("ATLAS", "images/ui_kaltsit_esperanta_skill.xml"))

local ARK_CONSTANTS = require("ark_constants")
local common = require("kaltsit_esperanta_common")

-- 三技能范围选择器（预声明，targetSelector 引用）
RegisterTargetSelector("kaltsit_esperanta_skill3_aoe", AreaTargetSelector {
  range          = 20,
  deployradius   = 1,
  reticuleprefab = "kaltsit_esperanta_skill3_reticuleaoe",
  pingprefab     = "kaltsit_esperanta_skill3_reticuleaoeping",
})


local skill1DefaultParams = { range = 20, health = 2, invincible_duration = 10, treatment_duration = 20, health_cost = 40, sanity_cost = 40 }

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
    activationEnergy = 15,
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
  local anchor = SpawnPrefab("tactical_anchor")
  anchor.Transform:SetPosition(pos:Get())
  common.PlaySkillSfx(inst, "p_imp_khlrftcrmk")
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
    -- activationEnergy = 2 * 60,
    activationEnergy = 10,
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
    -- activationEnergy = 10 * 60,
    activationEnergy = 10,
    -- buffDuration = 120,
    buffDuration = 20,
    desc = STRINGS.UI.KALTSIT_ESPERANTA_SKILL.LEVEL_DESC[3][1],
    params = { range = 20, health_percent = 0.02, damage_multiplier = 0.2 }
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
