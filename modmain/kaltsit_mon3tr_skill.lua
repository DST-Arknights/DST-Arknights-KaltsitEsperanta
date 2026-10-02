local constants = require("ark_constants")
local config = require("kaltsit_mon3tr_skill_config")
local strings = STRINGS.UI.KALTSIT_MON3TR_SKILL
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

for index, definition in ipairs(config.skills) do
  local params = { sanity_cost = 20 }
  if index == 1 then
    params.range = 10
    params.panic_duration = 10
  end
  RegisterArkSkill({
    id = definition.id,
    name = strings.NAME[index],
    lockedDesc = strings.LOCKED_DESC[index],
    energyRecoveryMode = constants.ENERGY_RECOVERY_MODE.AUTO,
    activationMode = constants.ACTIVATION_MODE.MANUAL,
    atlas = config.atlas,
    image = definition.key .. ".tex",
    OnInstall = index == 1 and UnlockOnInstall or nil,
    ActivateTest = index == 1 and OnIntimidateActivateTest or nil,
    OnActivate = index == 1 and OnIntimidateActivate or nil,
    levels = {
      {
        activationEnergy = definition.activation_energy,
        buffDuration = definition.buff_duration,
        desc = strings.LEVEL_DESC[index],
        -- 理智消耗暂不接入；其它四个技能仍仅配置框架运行状态。
        params = params,
      },
    },
  })
end
