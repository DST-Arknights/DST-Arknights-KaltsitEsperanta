local STATE_NAME = "kaltsit_mon3tr_jump"
local LAND_TIME = 15.2 * FRAMES
local FINISH_TIME = 30 * FRAMES
local RECALL_TIME = 12 * FRAMES
local RECALL_MIN_TIME = 4 * FRAMES
local RECALL_GAP = 0.2

local function IsJumpable(pet)
  if pet == nil or not pet:IsValid() or pet.prefab ~= "kaltsit_esperanta_mon3tr"
    or pet:HasAnyTag("playerghost", "corpse") or pet.sg == nil
    or pet.sg.sg.name ~= "wilson" or not pet.sg:HasState(STATE_NAME)
    or pet.Physics == nil or pet.components.health == nil or pet.components.locomotor == nil then
    return false
  end
  local userid = pet.Network:GetUserID()
  -- 原版死亡状态不允许退出；正常宠物死亡由外层 death 入口提前接管。
  local state = pet.sg.currentstate.name
  return (userid == nil or userid == "") and state ~= "death" and state ~= "death_hosted"
end

local function IsValidOwner(owner)
  return owner ~= nil and owner:IsValid() and owner.Transform ~= nil
end

local function GetTargetPosition(cast)
  local pos = cast.recalling and IsValidOwner(cast.owner) and cast.owner:GetPosition() or cast.targetpos
  return pos ~= nil and Vector3(pos.x, 0, pos.z) or nil
end

local function StopPhysics(inst)
  inst.Physics:Stop()
  inst.Physics:SetMotorVel(0, 0, 0)
end

local function QueueComplete(inst, cast)
  if cast.oncomplete == nil or cast.completed then return end
  cast.completed = true
  -- 下一帧交还 petleash，避免在 SG 切换/更新尚未返回时移除实体。
  inst:DoTaskInTime(0, function()
    if inst:IsValid() then cast.oncomplete(inst) end
  end)
end

local function FinishRecallJump(inst)
  local cast = inst.sg.statemem.cast
  if cast == nil or not cast.recalling or cast.completed then return end
  StopPhysics(inst)
  -- 在空中消失，保持跳跃保护直到 petleash 真正移除，不切回落地/idle 动作。
  inst:Hide()
  QueueComplete(inst, cast)
end

local function MoveTowardsTarget(inst)
  local mem = inst.sg.statemem
  local targetpos = GetTargetPosition(mem.cast)
  if targetpos == nil then
    inst.sg:GoToState("idle")
    return
  end
  local distance = math.sqrt(inst:GetDistanceSqToPoint(targetpos))
  inst:ForceFacePoint(targetpos:Get())
  local recallDistance
  if mem.cast.recalling then
    recallDistance = inst:GetPhysicsRadius(0) + mem.cast.owner:GetPhysicsRadius(0) + RECALL_GAP
    if distance <= recallDistance then
      StopPhysics(inst)
      -- 已经贴近主人时仍展示起跳，不再向她的碰撞范围移动。
      if inst.sg.timeinstate >= RECALL_MIN_TIME then FinishRecallJump(inst) end
      return
    end
  end
  local arrivalTime = mem.cast.recalling and RECALL_TIME or LAND_TIME
  local remaining = math.max(FRAMES, arrivalTime - inst.sg.timeinstate)
  -- 召回的飞行终点停在主人身前；提前消失的帧与到达时间一致。
  local travelDistance = distance - (recallDistance or 0)
  inst.Physics:SetMotorVel(travelDistance / remaining, 0, 0)
end

local function Land(inst)
  local mem = inst.sg.statemem
  if mem.landed or mem.cast == nil or mem.cast.recalling then return end
  local targetpos = GetTargetPosition(mem.cast)
  if targetpos == nil then
    inst.sg:GoToState("idle")
    return
  end
  mem.landed = true
  StopPhysics(inst)
  inst.Physics:Teleport(targetpos:Get())
  inst.SoundEmitter:PlaySound("dontstarve/movement/bodyfall_dirt")
end

local function MakeState()
  return State {
    name = STATE_NAME,
    tags = { "doing", "busy", "nopredict", "nomorph", "nointerrupt", "nocommand", "notalking" },
    onenter = function(inst, cast)
      if cast == nil or not IsJumpable(inst) or not IsValidOwner(cast.owner) then
        inst.sg:GoToState("idle")
        return
      end
      local mem = inst.sg.statemem
      mem.cast = cast
      mem.startpos = inst:GetPosition()
      mem.collisionmask = inst.Physics:GetCollisionMask()
      mem.invincible = inst.components.health.invincible
      mem.protected = true
      inst:ClearBufferedAction()
      inst.components.locomotor:Clear()
      inst.components.locomotor:Stop()
      if inst.components.health:IsDead() then inst.sg:AddStateTag("dead") end
      inst.components.health:SetInvincible(true)
      inst.Physics:SetCollisionMask(COLLISION.GROUND)
      inst.AnimState:PlayAnimation("jumpout")
      inst.sg:SetTimeout(FINISH_TIME)
      MoveTowardsTarget(inst)
    end,
    onupdate = function(inst)
      local mem = inst.sg.statemem
      if mem.cast ~= nil and not mem.cast.completed and not mem.landed then MoveTowardsTarget(inst) end
    end,
    timeline = {
      TimeEvent(RECALL_TIME, FinishRecallJump),
      TimeEvent(LAND_TIME, Land),
    },
    events = {
      EventHandler("death", function(inst)
        -- 召唤途中被 ForceKill 时仍交给全局死亡入口；已召回只忽略重复死亡。
        local cast = inst.sg.statemem.cast
        return cast ~= nil and cast.recalling
      end),
      EventHandler("animover", function(inst)
        if inst.AnimState:AnimDone() then
          if inst.sg.statemem.cast ~= nil and inst.sg.statemem.cast.recalling then
            FinishRecallJump(inst)
          else
            inst.sg:GoToState("idle")
          end
        end
      end),
    },
    ontimeout = function(inst)
      if inst.sg.statemem.cast ~= nil and inst.sg.statemem.cast.recalling then
        FinishRecallJump(inst)
      else
        inst.sg:GoToState("idle")
      end
    end,
    onexit = function(inst, nextstate)
      local mem = inst.sg.statemem
      local cast = mem.cast
      if cast == nil then return end
      StopPhysics(inst)
      if cast.recalling then
        FinishRecallJump(inst)
      elseif not mem.landed and nextstate ~= STATE_NAME then
        -- 中断召唤时退回起跳点，避免把实体留在飞行路径的海面或虚空。
        inst.Physics:Teleport(mem.startpos:Get())
      end
      if mem.protected then
        mem.protected = nil
        inst.Physics:SetCollisionMask(mem.collisionmask)
        inst.components.health:SetInvincible(mem.invincible)
      end
    end,
  }
end

local function Summon(pet, owner, targetpos)
  if not IsJumpable(pet) or not IsValidOwner(owner) or targetpos == nil then return false end
  if pet.sg.currentstate.name == STATE_NAME then return false end
  local startpos = owner:GetPosition()
  pet.Physics:Teleport(startpos.x, 0, startpos.z)
  pet.sg:GoToState(STATE_NAME, {
    owner = owner,
    targetpos = Vector3(targetpos.x, 0, targetpos.z),
  })
  return pet.sg.currentstate.name == STATE_NAME
end

local function Recall(pet, owner, oncomplete)
  if not IsJumpable(pet) or not IsValidOwner(owner) or type(oncomplete) ~= "function" then return false end
  if pet.sg.currentstate.name == STATE_NAME then
    local cast = pet.sg.statemem.cast
    if cast ~= nil and cast.recalling then return true end
  end
  pet.sg:GoToState(STATE_NAME, {
    owner = owner,
    recalling = true,
    oncomplete = oncomplete,
  })
  return pet.sg.currentstate.name == STATE_NAME
end

return { MakeState = MakeState, Summon = Summon, Recall = Recall }
