table.insert(Assets, Asset("ATLAS", "images/ui_kaltsit_esperanta_skill.xml"))

local ARK_CONSTANTS = require("ark_constants")
local common = require("kaltsit_esperanta_common")

local function ActiveDoctorsMonumentsBuff(instOrPos, levelParams)
  local ents = common.FindFriendlyEntities(instOrPos, levelParams.range, function(ent)
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

local skill1DefaultParams = { range = 20, health = 2, invincible_duration = 10, treatment_duration = 20, health_cost = 40, sanity_cost = 40 }

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
  if skill.inst.components.health then
    skill.inst.components.health:DoDelta(-levelParams.health_cost, nil, "kaltsit_esperanta_skill1")
  end
  if skill.inst.components.sanity then
    skill.inst.components.sanity:DoDelta(-levelParams.sanity_cost)
  end
  ActiveDoctorsMonumentsBuff(skill.inst, levelParams)
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

local function OnSkill3Activate(skill, data)
  skill:RemoveState("recast")
  local inst = skill.inst
  local pos = data.targetPos
  if not pos then
    return false, 'SKILL_CANNOT_ACTIVATE'
  end
  local anchor = SpawnPrefab("tactical_anchor")
  anchor.Transform:SetPosition(pos:Get())
  skill:SetState("anchor", anchor)
  local skill1 = inst.components.ark_skill:GetSkill("kaltsit_esperanta_skill1")
  local skill1Params = skill1 and skill1:GetLevelParams() or skill1DefaultParams
  ActiveDoctorsMonumentsBuff({
    inst = inst,
    pos = pos,
  }, skill1Params)
  return true
end

local function OnSkill3Recast(skill, data)
  local inst = skill.inst
  local anchor = skill:GetState("anchor")
  if not anchor then
    return false
  end
  if skill:GetState("recast") then
    return false
  end
  skill:SetState("recast", true)
  local anchorPos = anchor:GetPosition()
  local skill1 = skill.inst.components.ark_skill:GetSkill("kaltsit_esperanta_skill1")
  local skill1Params = skill1 and skill1:GetLevelParams() or skill1DefaultParams
  ActiveDoctorsMonumentsBuff({
    inst = inst,
    pos = anchorPos,
  }, skill1Params)
  -- 在目标点可降落
  local teleportPos = anchorPos + Vector3(1, 0, 1)
  inst.Physics:Teleport(teleportPos:Get())
  return true
end

local function OnSkill3Deactivate(skill)
  local anchor = skill:GetState("anchor")
  if anchor then
    anchor:Remove()
    skill:SetState("anchor", nil)
  end
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
  OnActivate = OnSkill3Activate,
  OnRecast = OnSkill3Recast,
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
    -- activationEnergy = 10 * 60,
    activationEnergy = 10,
    -- buffDuration = 120,
    buffDuration = 20,
    desc = STRINGS.UI.KALTSIT_ESPERANTA_SKILL.LEVEL_DESC[3][1],
    params = { range = 20, health_percent = 0.02, damage_multiplier = 0.2}
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
