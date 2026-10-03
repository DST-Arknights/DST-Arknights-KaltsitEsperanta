local constants = require("ark_constants")
local assault = require("kaltsit_mon3tr_assault")
local strings = STRINGS.UI.KALTSIT_MON3TR_SKILL
local SKILL_ATLAS = "images/ui_kaltsit_experanta_mon3tr_skill.xml"
local INTIMIDATE_STATE = "kaltsit_mon3tr_intimidate"
local SCARE_CANT_TAGS = { "INLIMBO", "DECOR", "FX", "NOCLICK" }

local function CanIntimidate(inst)
  return inst ~= nil and inst:IsValid()
    and not inst:HasAnyTag("playerghost", "corpse")
    and inst.components.health ~= nil and not inst.components.health:IsDead()
    and inst.sg ~= nil and not inst.sg:HasStateTag("busy") and not inst.sg:HasStateTag("nocommand")
end

local function GetIntimidateOwner(pet)
  local behavior = pet.components.kaltsit_mon3tr_behavior
  return behavior ~= nil and behavior:GetOwner() or nil
end

local function OnIntimidateActivateTest(skill)
  local pet = skill.inst
  local owner = GetIntimidateOwner(pet)
  return CanIntimidate(pet) and CanIntimidate(owner)
end

local function IntimidateFrom(inst, cast)
  if cast == nil or not cast.pet:IsValid() or not cast.owner:IsValid()
    or GetIntimidateOwner(cast.pet) ~= cast.owner
    or inst.components.health:IsDead() then
    return
  end
  local x, y, z = inst.Transform:GetWorldPosition()
  local wave = SpawnPrefab("kaltsit_mon3tr_intimidate_fx")
  wave.Transform:SetPosition(x, 0, z)
  -- 与原版 groundpounder 一致：proxy 的 Transform 缩放重复生效，需开平方。
  local scale = math.sqrt(cast.range / 6)
  wave.Transform:SetScale(scale, scale, scale)
  for _, target in ipairs(TheSim:FindEntities(x, y, z, cast.range, nil, SCARE_CANT_TAGS)) do
    local hauntable = target.components.hauntable
    local health = target.components.health
    if target ~= cast.owner and target ~= cast.pet and not cast.scared[target]
      and target:IsValid() and hauntable ~= nil and hauntable.panicable
      and (health == nil or not health:IsDead()) then
      cast.scared[target] = true
      hauntable:Panic(cast.panic_duration)
      if target.components.sleeper ~= nil then
        target.components.sleeper:WakeUp()
      end
      local fx = SpawnPrefab("battlesong_instant_panic_fx")
      fx.Transform:SetPosition(target.Transform:GetWorldPosition())
    end
  end
end

AddStategraphState("wilson", State {
  name = INTIMIDATE_STATE,
  tags = { "busy", "notalking", "nopredict" },
  onenter = function(inst, cast)
    inst.sg.statemem.cast = cast
    inst:ClearBufferedAction()
    inst.components.locomotor:Stop()
    if inst.components.playercontroller ~= nil then
      inst.components.playercontroller:RemotePausePrediction()
    end
    -- 只复用动作，不进入 attack 状态或执行其伤害时间线。
    inst.AnimState:PlayAnimation("atk_pre")
    inst.AnimState:PushAnimation("atk", false)
  end,
  timeline = {
    TimeEvent(8 * FRAMES, function(inst)
      inst.SoundEmitter:PlaySound("dontstarve/wilson/attack_whoosh")
      IntimidateFrom(inst, inst.sg.statemem.cast)
    end),
  },
  events = {
    EventHandler("animqueueover", function(inst) inst.sg:GoToState("idle") end),
  },
})

AddStategraphState("wilson", assault.MakeState())

local function OnIntimidateActivate(skill)
  local pet = skill.inst
  local owner = GetIntimidateOwner(pet)
  if not CanIntimidate(pet) or not CanIntimidate(owner) then
    return
  end
  local params = skill:GetLevelParams()
  local cast = {
    owner = owner,
    pet = pet,
    range = params.range,
    panic_duration = params.panic_duration,
    scared = {},
  }
  pet.sg:GoToState(INTIMIDATE_STATE, cast)
  if owner ~= pet then
    owner.sg:GoToState(INTIMIDATE_STATE, cast)
  end
end

local function UnlockOnInstall(skill)
  skill:Unlock()
end

local skills = {
  {
    key = "intimidate",
    id = "kaltsit_mon3tr_intimidate",
    implemented = true,
    intellect_threshold = 1,
    name = strings.NAME[1],
    lockedDesc = strings.LOCKED_DESC[1],
    energyRecoveryMode = constants.ENERGY_RECOVERY_MODE.AUTO,
    activationMode = constants.ACTIVATION_MODE.MANUAL,
    atlas = SKILL_ATLAS,
    image = "intimidate.tex",
    OnInstall = UnlockOnInstall,
    ActivateTest = OnIntimidateActivateTest,
    OnActivate = OnIntimidateActivate,
    levels = { {
      activationEnergy = 30,
      buffDuration = 0,
      desc = strings.LEVEL_DESC[1],
      params = { range = 10, panic_duration = 10 },
    } },
  }, {
    key = "assault",
    id = "kaltsit_mon3tr_assault",
    implemented = true,
    intellect_threshold = 50,
    name = strings.NAME[2],
    lockedDesc = strings.LOCKED_DESC[2],
    energyRecoveryMode = constants.ENERGY_RECOVERY_MODE.AUTO,
    activationMode = constants.ACTIVATION_MODE.AUTO,
    atlas = SKILL_ATLAS,
    image = "assault.tex",
    ActivateTest = assault.CanActivate,
    OnActivate = assault.Activate,
    levels = { {
      activationEnergy = 10,
      buffDuration = 0,
      desc = strings.LEVEL_DESC[2],
      params = { range = 8, radius = 4, damage_mult = 2 },
    } },
  }, {
    key = "reinforce",
    id = "kaltsit_mon3tr_reinforce",
    implemented = false,
    intellect_threshold = 100,
    name = strings.NAME[3],
    lockedDesc = strings.LOCKED_DESC[3],
    energyRecoveryMode = constants.ENERGY_RECOVERY_MODE.AUTO,
    activationMode = constants.ACTIVATION_MODE.MANUAL,
    atlas = SKILL_ATLAS,
    image = "reinforce.tex",
    levels = { {
      activationEnergy = 60,
      buffDuration = 30,
      desc = strings.LEVEL_DESC[3],
    } },
  }, {
    key = "castling",
    id = "kaltsit_mon3tr_castling",
    implemented = false,
    intellect_threshold = 150,
    name = strings.NAME[4],
    lockedDesc = strings.LOCKED_DESC[4],
    energyRecoveryMode = constants.ENERGY_RECOVERY_MODE.AUTO,
    activationMode = constants.ACTIVATION_MODE.MANUAL,
    atlas = SKILL_ATLAS,
    image = "castling.tex",
    levels = { {
      activationEnergy = 60,
      buffDuration = 0,
      desc = strings.LEVEL_DESC[4],
    } },
  }, {
    key = "meltdown",
    id = "kaltsit_mon3tr_meltdown",
    implemented = false,
    intellect_threshold = 200,
    name = strings.NAME[5],
    lockedDesc = strings.LOCKED_DESC[5],
    energyRecoveryMode = constants.ENERGY_RECOVERY_MODE.AUTO,
    activationMode = constants.ACTIVATION_MODE.MANUAL,
    atlas = SKILL_ATLAS,
    image = "meltdown.tex",
    levels = { {
      activationEnergy = 200,
      buffDuration = 20,
      desc = strings.LEVEL_DESC[5],
    } },
  },
}

-- 与凯尔希技能一样逐项定义；共享数量与查询索引供宠物、代理和 UI 使用。
TUNING.KALTSIT_MON3TR_SKILLS = skills
TUNING.KALTSIT_MON3TR_SKILL_COUNT = #skills
TUNING.KALTSIT_MON3TR_SKILLS_BY_ID = {}
TUNING.KALTSIT_MON3TR_SKILLS_BY_KEY = {}
for index, skill in ipairs(skills) do
  skill.index = index
  TUNING.KALTSIT_MON3TR_SKILLS_BY_ID[skill.id] = skill
  TUNING.KALTSIT_MON3TR_SKILLS_BY_KEY[skill.key] = skill
  RegisterArkSkill(skill)
end
