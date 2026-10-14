local STATE_NAME = "kaltsit_mon3tr_castling"
local SHIELD_BUFF = "kaltsit_mon3tr_castling_shield_buff"
local PAUSE_FRAMES = 3

local function GetOwner(pet)
  local behavior = pet ~= nil and pet.components.kaltsit_mon3tr_behavior or nil
  return behavior ~= nil and behavior:GetOwner() or nil
end

local function IsReady(inst, prepared)
  -- Ents 只包含当前分片实体；迁移、死亡、收回和脱离当前世界都不能参与交换。
  if inst == nil or not inst:IsValid() or Ents[inst.GUID] ~= inst or inst:IsInLimbo()
    or inst:HasAnyTag("playerghost", "corpse") or inst.entity:GetParent() ~= nil
    or inst.components.health == nil or inst.components.health:IsDead()
    or inst.Physics == nil or inst.components.locomotor == nil or inst.sg == nil
    or (inst.components.rider ~= nil and inst.components.rider:IsRiding())
    or not inst:DebuffsEnabled() then
    return false
  end
  if prepared then return inst.sg.currentstate.name == STATE_NAME end
  return not inst.sg:HasAnyStateTag("busy", "nocommand", "nopredict")
end

local function IsSafePoint(pos)
  -- 沿用原版 blinkstaff：允许陆地和船，不允许海面、虚空或地面阻挡物。
  return TheWorld.Map:IsPassableAtPoint(pos.x, 0, pos.z)
    and not TheWorld.Map:IsGroundTargetBlocked(pos)
end

local function GetCast(skill, prepared)
  if TheWorld == nil or not TheWorld.ismastersim then return nil end
  local pet = skill.inst
  local owner = GetOwner(pet)
  if owner == pet or not IsReady(pet, prepared) or not IsReady(owner, prepared) then
    return nil
  end
  local cost = skill:GetLevelParams().sanity_cost or 20
  if owner.components.sanity == nil or owner.components.sanity.current < cost then
    return nil
  end
  local petpos, ownerpos = pet:GetPosition(), owner:GetPosition()
  if not IsSafePoint(petpos) or not IsSafePoint(ownerpos)
    or not IsTeleportingPermittedFromPointToPoint(ownerpos.x, 0, ownerpos.z, petpos.x, 0, petpos.z)
    or not IsTeleportingPermittedFromPointToPoint(petpos.x, 0, petpos.z, ownerpos.x, 0, ownerpos.z) then
    return nil
  end
  return { pet = pet, owner = owner, petpos = petpos, ownerpos = ownerpos, sanity_cost = cost }
end

local function CanActivate(skill)
  return GetCast(skill, false) ~= nil
end

local function MakeState()
  return State {
    name = STATE_NAME,
    tags = { "busy", "nopredict", "notalking", "nomorph", "nointerrupt" },
    onenter = function(inst)
      inst:ClearBufferedAction()
      inst.components.locomotor:Clear()
      inst.components.locomotor:Stop()
      if inst.components.playercontroller ~= nil then
        inst.components.playercontroller:RemotePausePrediction(PAUSE_FRAMES)
      end
      inst.AnimState:PlayAnimation("idle", true)
      inst.sg:SetTimeout(PAUSE_FRAMES * FRAMES)
    end,
    ontimeout = function(inst) inst.sg:GoToState("idle", true) end,
  }
end

local function RefreshPlatform(inst, pos)
  local oldplatform = inst:GetCurrentPlatform()
  local platform = TheWorld.Map:GetPlatformAtPoint(pos.x, 0, pos.z)
  if platform ~= oldplatform then
    -- 使用原版平台接口同步 follower；不直接写 inst.platform 或重设碰撞掩码。
    if oldplatform ~= nil and oldplatform:IsValid() then oldplatform:RemovePlatformFollower(inst) end
    if platform ~= nil then platform:AddPlatformFollower(inst) end
  end
  if inst.components.walkableplatformplayer ~= nil then
    inst.components.walkableplatformplayer:TestForPlatform()
  end
end

local function SpawnSwapFX(pos)
  local front = SpawnPrefab("sand_puff_large_front")
  if front ~= nil then front.Transform:SetPosition(pos.x, 0, pos.z) end
  local back = SpawnPrefab("sand_puff_large_back")
  if back ~= nil then back.Transform:SetPosition(pos.x, -.1, pos.z) end
end

local function RefundActivation(skill)
  -- OnActivate 在共享技能扣层后执行；若回调间条件失效，用公开充能接口归还这一层。
  skill:SetEnergyRecovering()
  skill:AddEnergyProgress(skill:GetLevelConfig().activationEnergy)
end

local function ExitPreparedState(inst)
  if inst ~= nil and inst:IsValid() and inst.sg ~= nil and inst.sg.currentstate.name == STATE_NAME then
    inst.sg:GoToState("idle", true)
  end
end

local function Activate(skill)
  local cast = GetCast(skill, false)
  if cast == nil then
    RefundActivation(skill)
    return false
  end
  -- 双方先暂停动作和客户端预测；位置在同一服务端回调内立即互换。
  cast.pet.sg:GoToState(STATE_NAME)
  cast.owner.sg:GoToState(STATE_NAME)
  local prepared = GetCast(skill, true)
  if prepared == nil or prepared.owner ~= cast.owner then
    ExitPreparedState(cast.pet)
    ExitPreparedState(cast.owner)
    RefundActivation(skill)
    return false
  end
  cast = prepared
  cast.pet.Physics:Teleport(cast.ownerpos.x, 0, cast.ownerpos.z)
  cast.owner.Physics:Teleport(cast.petpos.x, 0, cast.petpos.z)
  RefreshPlatform(cast.pet, cast.ownerpos)
  RefreshPlatform(cast.owner, cast.petpos)
  cast.pet:AddDebuff(SHIELD_BUFF, SHIELD_BUFF)
  cast.owner:AddDebuff(SHIELD_BUFF, SHIELD_BUFF)
  cast.owner.components.sanity:DoDelta(-cast.sanity_cost)
  SpawnSwapFX(cast.petpos)
  SpawnSwapFX(cast.ownerpos)
  if cast.owner.SoundEmitter ~= nil then cast.owner.SoundEmitter:PlaySound("dontstarve/common/staff_blink") end
  skill:SetEnergyRecovering()
  return true
end

return { CanActivate = CanActivate, Activate = Activate, MakeState = MakeState }
