table.insert(Assets, Asset("ATLAS", "images/ui_kaltsit_esperanta_skill.xml"))

local ARK_CONSTANTS = require("ark_constants")
local common = require("kaltsit_esperanta_common")

local function OnSkill1ActivateTest(skill)
  local inst = skill.inst
  local levelParams = skill:GetLevelParams()
  -- 有生命值组件满足40生命值, 有精神力组件满足20点精神力
  if inst.components.health and inst.components.health.currenthealth < levelParams.health_cost then
    return false, 'SKILL_CANNOT_ACTIVATE'
  end
  if inst.components.sanity and inst.components.sanity.current < levelParams.sanity_cost then
    return false, 'SKILL_CANNOT_ACTIVATE'
  end
  return true
end

local function OnSkill1Activate(skill, data)
  -- 扫描附近玩家, 给予buff
  local levelParams = skill:GetLevelParams()
  local ents = common.FindFriendlyEntities(skill.inst, levelParams.range, function(ent)
    return not ent:HasTag("ghost")
  end)
  if skill.inst.components.health then
    skill.inst.components.health:DoDelta(-levelParams.health_cost, nil, "kaltsit_esperanta_skill1")
  end
  if skill.inst.components.sanity then
    skill.inst.components.sanity:DoDelta(-levelParams.sanity_cost)
  end
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

local function OnSkill2ActivateTest(skill)
  local inst = skill.inst
  -- 扣san
  local levelParams = skill:GetLevelParams()
  if inst.components.sanity and inst.components.sanity.current < levelParams.sanity_cost then
    return false, 'SKILL_CANNOT_ACTIVATE'
  end
  return true
end

local function OnSkill2Activate(skill, data)
  local inst = skill.inst
  local levelParams = skill:GetLevelParams()
  if inst.components.sanity then
    inst.components.sanity:DoDelta(-levelParams.sanity_cost)
  end
end

local function Skill2LevelDesc(skill)
  local params = skill:GetLevelParams()
  return string.format(STRINGS.UI.KALTSIT_ESPERANTA_SKILL.LEVEL_DESC[2], params.damage, params.health)
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
    params = { range = 20, health = 2, invincible_duration = 10, treatment_duration = 20, health_cost = 20, sanity_cost = 10 },
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
    {
      -- activationEnergy = 3 * 60,
      activationEnergy = 15,
      bulletCount = 10,
      desc = Skill2LevelDesc,
      params = { sanity_cost = 200, damage = 2000, aoeRange = 3, health = 80 },
    },
    {
      -- activationEnergy = 3 * 60,
      activationEnergy = 15,
      bulletCount = 10,
      desc = Skill2LevelDesc,
      params = { sanity_cost = 200, damage = 3000, aoeRange = 3, health = 80 },
    },
    {
      -- activationEnergy = 3 * 60,
      activationEnergy = 15,
      bulletCount = 10,
      desc = Skill2LevelDesc,
      params = { sanity_cost = 200, damage = 4000, aoeRange = 3, health = 80 },
    },
    {
      -- activationEnergy = 3 * 60,
      activationEnergy = 15,
      bulletCount = 10,
      desc = Skill2LevelDesc,
      params = { sanity_cost = 200, damage = 5000, aoeRange = 3, health = 80 },
    },
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
  OnActivateEffect = OnSkill3ActivateEffect,
  OnDeactivate = OnSkill3Deactivate,
  targeting = {
    mode = 'aoe',
    config = {
      reticule = {
        reticuleprefab = "kaltsit_esperanta_skill3_reticuleaoe",
        pingprefab = "kaltsit_esperanta_skill3_reticuleaoeping",
      },
      aoetargeting = {
        deployradius = 1,
        range = 20,
      },
    }
  },
  levels = { {
    -- activationEnergy = 4 * 60,
    activationEnergy = 10,
    desc = STRINGS.UI.KALTSIT_ESPERANTA_SKILL.LEVEL_DESC[3][1],
    params = { range = 20, health = 2, invincible_duration = 10, treatment_duration = 20, },
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
