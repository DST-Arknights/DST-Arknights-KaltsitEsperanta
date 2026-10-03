local SpDamageUtil = require("components/spdamageutil")

local STATE_NAME = "kaltsit_mon3tr_assault"
local ANIM_SPEED = 2
local LAND_TIME = 15.2 * FRAMES / ANIM_SPEED
local DAMAGE_TAGS = { "_combat", "_health" }
local DAMAGE_NOTAGS = { "INLIMBO", "DECOR", "FX", "NOCLICK", "ghost", "playerghost", "noauradamage", "companion" }
local LAND_FX = { "groundpoundring_fx", "pine_needles_chop", "boss_ripple_fx" }

local function IsLivingPet(inst)
  if inst == nil or not inst:IsValid() or inst.prefab ~= "kaltsit_esperanta_mon3tr" then
    return false
  end
  local userid = inst.Network:GetUserID()
  return (userid == nil or userid == "") and not inst:HasAnyTag("playerghost", "corpse")
    and inst.components.health ~= nil and not inst.components.health:IsDead()
end

local function GetOwner(inst)
  local behavior = inst.components.kaltsit_mon3tr_behavior
  return behavior ~= nil and behavior:GetOwner() or nil
end

local function IsEnemy(inst, target)
  return target ~= nil and target:IsValid() and not target:IsInLimbo()
    and target ~= inst and target ~= GetOwner(inst) and target.entity:IsVisible()
    and not target:HasAnyTag(unpack(DAMAGE_NOTAGS))
    and target.components.health ~= nil and not target.components.health:IsDead()
    and target.components.combat ~= nil and target.components.minigame_participator == nil
    and inst.components.combat:CanTarget(target) and not inst.components.combat:IsAlly(target)
end

local function IsSafePoint(pos)
  return TheWorld.Map:IsPassableAtPoint(pos.x, 0, pos.z)
    and not TheWorld.Map:IsGroundTargetBlocked(pos)
end

local function CanActivate(skill, data)
  local inst = skill.inst
  if not IsLivingPet(inst) or GetOwner(inst) == nil or inst.sg == nil
    or inst.sg:HasAnyStateTag("busy", "attack", "abouttoattack", "nocommand")
    or not inst.components.combat.canattack
    or (inst.components.rider ~= nil and inst.components.rider:IsRiding()) then
    return false
  end
  local target = data ~= nil and data.target or nil
  local range = skill:GetLevelParams().range
  return IsEnemy(inst, target) and inst:GetDistanceSqToInst(target) <= range * range
    and IsSafePoint(target:GetPosition())
end

local function RestorePhysics(inst)
  local mem = inst.sg.statemem
  if mem.collisionmask ~= nil then
    inst.Physics:Stop()
    inst.Physics:SetMotorVel(0, 0, 0)
    inst.Physics:SetCollisionMask(mem.collisionmask)
    mem.collisionmask = nil
    -- 跳跃中断时不把实体留在海面或虚空；回退到起跳位置。
    local pos = inst:GetPosition()
    if not IsSafePoint(pos) then pos = mem.startpos end
    inst.Physics:Teleport(pos.x, 0, pos.z)
  end
end

local function Land(inst)
  local mem = inst.sg.statemem
  local cast = mem.cast
  if mem.landed then return end
  if not IsLivingPet(inst) or GetOwner(inst) ~= cast.owner or not IsSafePoint(cast.targetpos) then
    inst.sg:GoToState("idle")
    return
  end
  mem.landed = true
  RestorePhysics(inst)
  local pos = cast.targetpos
  inst.Physics:Teleport(pos.x, 0, pos.z)
  inst.SoundEmitter:PlaySound("dontstarve/movement/bodyfall_dirt")
  for _, prefab in ipairs(LAND_FX) do
    local fx = SpawnPrefab(prefab)
    if fx ~= nil then fx.Transform:SetPosition(pos.x, 0, pos.z) end
  end

  local combat = inst.components.combat
  for _, target in ipairs(TheSim:FindEntities(pos.x, 0, pos.z, cast.radius, DAMAGE_TAGS, DAMAGE_NOTAGS)) do
    if not IsLivingPet(inst) then break end
    if IsEnemy(inst, target) and target:GetDistanceSqToPoint(pos) <= cast.radius * cast.radius then
      -- 按每个目标计算自身普通伤害，再翻倍，包含附加伤害；护甲仍由 GetAttacked 结算。
      local damage, spdamage = combat:CalcDamage(target, nil)
      spdamage = SpDamageUtil.ApplyMult(spdamage, cast.damage_mult)
      inst:PushEvent("onareaattackother", { target = target })
      local hit = target.components.combat:GetAttacked(inst, damage * cast.damage_mult, nil, nil, spdamage)
      if hit and target:IsValid() and not target.components.health:IsDead() then
        target.components.combat:SetTarget(inst)
      end
    end
  end
end

local function MakeState()
  return State {
    name = STATE_NAME,
    tags = { "doing", "busy", "notalking", "nopredict", "nomorph" },
    onenter = function(inst, cast)
      if not IsLivingPet(inst) or cast == nil or GetOwner(inst) ~= cast.owner or not IsSafePoint(cast.targetpos) then
        inst.sg:GoToState("idle")
        return
      end
      inst.sg.statemem.cast = cast
      inst.sg.statemem.startpos = inst:GetPosition()
      inst:ClearBufferedAction()
      inst.components.locomotor:Clear()
      inst.components.locomotor:Stop()
      inst:ForceFacePoint(cast.targetpos:Get())
      inst.sg.statemem.collisionmask = inst.Physics:GetCollisionMask()
      inst.Physics:SetCollisionMask(COLLISION.GROUND)
      inst.AnimState:PlayAnimation("jumpout")
      inst.AnimState:SetDeltaTimeMultiplier(ANIM_SPEED)
      inst.sg.statemem.animspeed = true
      inst.Physics:SetMotorVel(math.sqrt(inst:GetDistanceSqToPoint(cast.targetpos)) / LAND_TIME, 0, 0)
      inst.sg:SetTimeout(30 * FRAMES / ANIM_SPEED)
    end,
    timeline = {
      TimeEvent(LAND_TIME, Land),
    },
    events = {
      EventHandler("animover", function(inst)
        if inst.AnimState:AnimDone() then inst.sg:GoToState("idle") end
      end),
    },
    ontimeout = function(inst) inst.sg:GoToState("idle") end,
    onexit = function(inst)
      RestorePhysics(inst)
      if inst.sg.statemem.animspeed then inst.AnimState:SetDeltaTimeMultiplier(1) end
    end,
  }
end

local function Activate(skill, data)
  if CanActivate(skill, data) then
    local params = skill:GetLevelParams()
    local pos = data.target:GetPosition()
    skill.inst.sg:GoToState(STATE_NAME, {
      owner = GetOwner(skill.inst),
      targetpos = Vector3(pos.x, 0, pos.z),
      radius = params.radius,
      damage_mult = params.damage_mult,
    })
  end
  -- 瞬发技能直接开始原有充能，冷却从起跳时计算。
  skill:SetEnergyRecovering()
end

return { CanActivate = CanActivate, Activate = Activate, MakeState = MakeState }
