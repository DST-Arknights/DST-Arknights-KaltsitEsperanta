table.insert(Assets, Asset("ATLAS", "images/ui_kaltsit_esperanta_skill.xml"))

local ARK_CONSTANTS = require("ark_constants")
local common = require("kaltsit_esperanta_common")

local function OnSkill1Activate(skill, data)
  -- 扫描附近玩家, 给予buff
  local levelParams = skill:GetLevelParams()
  local ents = common.FindFriendlyEntities(skill.inst, levelParams.range, function(ent)
    return not ent:HasTag("ghost")
  end)
  for _, ent in ipairs(ents) do
    ent:AddDebuff("doctors_monuments_invincible_buff", "doctors_monuments_invincible_buff", {
      buffConfig = {
        duration = levelParams.invincibleDuration,
      }
    })
    ent:AddDebuff("doctors_monuments_treatment_buff", "doctors_monuments_treatment_buff", {
      health = levelParams.health,
      buffConfig = {
        duration = levelParams.treatmentDuration,
      }
    })
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
  OnActivate = OnSkill1Activate,
  levels = { {
    -- activationEnergy = 2 * 60,
    activationEnergy = 10,
    desc = STRINGS.UI.KALTSIT_ESPERANTA_SKILL.LEVEL_DESC[1][1],
    params = { range = 20, health = 2, invincibleDuration = 10, treatmentDuration = 20, },
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
  levels = {
    {
      -- activationEnergy = 3 * 60,
      activationEnergy = 15,
      bulletCount = 10,
      desc = Skill2LevelDesc,
      params = { damage = 2000, aoeRange = 3, health = 80 },
    },
    {
      -- activationEnergy = 3 * 60,
      activationEnergy = 15,
      bulletCount = 10,
      desc = Skill2LevelDesc,
      params = { damage = 3000, aoeRange = 3, health = 80 },
    },
    {
      -- activationEnergy = 3 * 60,
      activationEnergy = 15,
      bulletCount = 10,
      desc = Skill2LevelDesc,
      params = { damage = 4000, aoeRange = 3, health = 80 },
    },
    {
      -- activationEnergy = 3 * 60,
      activationEnergy = 15,
      bulletCount = 10,
      desc = Skill2LevelDesc,
      params = { damage = 5000, aoeRange = 3, health = 80 },
    },
  }
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
