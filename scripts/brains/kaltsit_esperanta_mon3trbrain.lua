require "behaviours/doaction"
require "behaviours/follow"
require "behaviours/wander"

local COMBAT_TAGS = { "_combat", "_health" }
local COMBAT_NOTAGS = { "INLIMBO", "noauradamage", "companion" }
local DEFENSIVE_TAGS = { "monster", "prey" }
local AGGRESSIVE_TAGS = { "monster", "prey", "insect", "hostile", "character", "animal" }
local WORK_TAGS = { "CHOP_workable", "MINE_workable", "DIG_workable" }
local WORK_NOTAGS = { "fire", "smolder", "event_trigger", "waxedplant", "INLIMBO", "NOCLICK", "carnivalgame_part" }
local WORK_DIST, WORK_SEARCH_DIST, WORK_KEEP_DIST = 2, 10, 14

local function GetLeader(inst)
  local leader = inst.components.follower:GetLeader()
  return leader ~= nil and leader:IsValid() and leader or nil
end

local function IsBusy(inst)
  return inst.sg:HasStateTag("busy") or inst.sg:HasStateTag("attack")
    or inst.sg:HasStateTag("abouttoattack") or inst.components.combat:InCooldown()
end

local Mon3trBrain = Class(Brain, function(self, inst)
  Brain._ctor(self, inst)
end)

function Mon3trBrain:GetMode()
  return self.inst.components.kaltsit_mon3tr_behavior:GetMode()
end

function Mon3trBrain:IsActive()
  return not self.stopped and self.inst.brain == self
end

function Mon3trBrain:ClearAction()
  local locomotor = self.inst.components.locomotor
  if self.action ~= nil and self.inst:GetBufferedAction() == self.action then
    self.inst:ClearBufferedAction()
  end
  if (self.action ~= nil and locomotor.bufferedaction == self.action)
      or (self.inst:GetBufferedAction() == nil and locomotor.bufferedaction == nil) then
    locomotor:Clear()
    locomotor:Stop()
  end
  self.action = nil
end

function Mon3trBrain:ClearAI()
  self:ClearAction()
  if self.ai_target ~= nil and self.inst.components.combat.target == self.ai_target then
    self.inst.components.combat:SetTarget(nil)
  end
  self.ai_target, self.work_target, self.chase_started = nil, nil, nil
  self.ignored_target, self.ignore_until, self.next_retarget = nil, nil, nil
end

function Mon3trBrain:SetTarget(target)
  local combat = self.inst.components.combat
  combat:SetTarget(target)
  if combat.target ~= self.ai_target then
    self.ai_target, self.chase_started = combat.target, GetTime()
  end
end

function Mon3trBrain:CanTarget(target)
  return target ~= nil and target:IsValid() and not target:IsInLimbo()
    and target ~= self.inst and target ~= GetLeader(self.inst)
    and target.entity:IsVisible() and not target:HasAnyTag("ghost", "noauradamage")
    and target.components.minigame_participator == nil
    and self.inst.components.combat:CanTarget(target)
    and not self.inst.components.combat:IsAlly(target)
    and (target ~= self.ignored_target or GetTime() >= self.ignore_until)
end

function Mon3trBrain:CanFight()
  if not self:IsActive() or self:GetMode() == "work" then return false end
  local inst, combat, now = self.inst, self.inst.components.combat, GetTime()
  local aggressive = self:GetMode() == "attack"
  local anchor = GetLeader(inst) or inst
  local maxdist = aggressive and TUNING.ABIGAIL_COMBAT_TARGET_DISTANCE + 2 or TUNING.ABIGAIL_DEFENSIVE_MAX_FOLLOW
  if inst:GetDistanceSqToInst(anchor) >= maxdist * maxdist or (combat.target ~= nil and not self:CanTarget(combat.target)) then
    if combat.target ~= nil or self.ai_target ~= nil then
      combat:GiveUp()
      self:ClearAction()
      self.ai_target, self.chase_started = nil, nil
    end
    return false
  end
  -- SGwilson clears combat.target on attack exit; keep the brain's valid retaliation target.
  if combat.target == nil and self.ai_target ~= nil then
    if not self:CanTarget(self.ai_target) then
      self:ClearAction()
      self.ai_target, self.chase_started = nil, nil
      return false
    end
    combat:SetTarget(self.ai_target)
  end
  if combat.target == nil and now >= (self.next_retarget or 0) then
    self.next_retarget = now + .5
    local radius = aggressive and TUNING.ABIGAIL_COMBAT_TARGET_DISTANCE or TUNING.ABIGAIL_DEFENSIVE_MAX_FOLLOW
    local x, y, z = inst.Transform:GetWorldPosition()
    for _, target in ipairs(TheSim:FindEntities(x, y, z, radius, COMBAT_TAGS, COMBAT_NOTAGS, aggressive and AGGRESSIVE_TAGS or DEFENSIVE_TAGS)) do
      if self:CanTarget(target) and target:IsNear(anchor, TUNING.ABIGAIL_COMBAT_TARGET_DISTANCE)
        and (aggressive or target.components.combat.target == anchor
          or target.components.combat.target == inst
          or (anchor.components.combat ~= nil and anchor.components.combat.target == target)) then
        self:SetTarget(target)
        break
      end
    end
  end
  local target = combat.target
  if target == nil then return false end
  if target ~= self.ai_target then
    self.ai_target, self.chase_started = target, now
  end
  local timeout = aggressive and TUNING.ABIGAIL_AGGRESSIVE_MAX_CHASE_TIME or TUNING.ABIGAIL_DEFENSIVE_MAX_CHASE_TIME
  if now - self.chase_started > timeout then
    combat:GiveUp()
    self:ClearAction()
    self.ai_target, self.chase_started = nil, nil
    -- Ignore only the target we failed to reach; new threats can still interrupt following.
    self.ignored_target, self.ignore_until, self.next_retarget = target, now + timeout, now + .5
    return false
  end
  return true
end

function Mon3trBrain:CombatAction()
  local target, mode = self.inst.components.combat.target, self:GetMode()
  if not self:IsActive() or mode == "work" or target == nil then return nil end
  local action = BufferedAction(self.inst, target, ACTIONS.ATTACK)
  action.validfn = function()
    local anchor = GetLeader(self.inst) or self.inst
    local maxdist = mode == "attack" and TUNING.ABIGAIL_COMBAT_TARGET_DISTANCE + 2 or TUNING.ABIGAIL_DEFENSIVE_MAX_FOLLOW
    return self:IsActive() and self:GetMode() == mode and self:CanTarget(target)
      and self.inst:GetDistanceSqToInst(anchor) < maxdist * maxdist
  end
  self.action = action
  return action
end

function Mon3trBrain:CanWork(target)
  if target == nil or not target:IsValid() or target:IsInLimbo()
    or target:HasAnyTag(unpack(WORK_NOTAGS)) or not target:IsOnValidGround()
    or not target.entity:IsVisible() or not target:IsNear(GetLeader(self.inst) or self.inst, WORK_KEEP_DIST) then
    return false
  end
  local workable, burnable = target.components.workable, target.components.burnable
  local action = workable ~= nil and workable:GetWorkAction() or nil
  return workable ~= nil and workable:CanBeWorked()
    and (action == ACTIONS.CHOP or action == ACTIONS.MINE or action == ACTIONS.DIG)
    and (burnable == nil or not (burnable:IsBurning() or burnable:IsSmoldering()))
end

function Mon3trBrain:WorkAction()
  if not self:IsActive() or self:GetMode() ~= "work" then return nil end
  local inst = self.inst
  -- Work mode is deliberately pure work, including when attacked.
  inst.components.combat:SetTarget(nil)
  if not self:CanWork(self.work_target) then
    self.work_target = nil
    local x, y, z = inst.Transform:GetWorldPosition()
    for _, target in ipairs(TheSim:FindEntities(x, y, z, WORK_SEARCH_DIST, nil, WORK_NOTAGS, WORK_TAGS)) do
      if self:CanWork(target) then self.work_target = target; break end
    end
  end
  local target = self.work_target
  if target == nil then return nil end
  local near = inst:IsNear(target, WORK_DIST)
  local action = near and BufferedAction(inst, nil, ACTIONS.ATTACK, nil, target:GetPosition(), nil, math.huge)
    or BufferedAction(inst, target, ACTIONS.WALKTO, nil, nil, nil, WORK_DIST)
  if not near then action.arrivedist = WORK_DIST end
  action.validfn = function()
    return self:IsActive() and self:GetMode() == "work" and self:CanWork(target)
      and (not near or (inst:IsNear(target, WORK_DIST) and inst.components.combat.target == nil))
  end
  if near then
    action:AddSuccessAction(function()
      if action.validfn() then target.components.workable:WorkedBy(inst, 1) end
    end)
  end
  self.action = action
  return action
end

function Mon3trBrain:OnAttacked(data)
  if not self:IsActive() or self:GetMode() == "work" then return end
  local attacker = data ~= nil and data.attacker or nil
  self.ignored_target, self.ignore_until = nil, nil
  if not self:CanTarget(attacker) then return end
  local anchor = GetLeader(self.inst) or self.inst
  if self:GetMode() == "attack" or (self.inst:IsNear(anchor, TUNING.ABIGAIL_DEFENSIVE_MAX_FOLLOW)
    and attacker:IsNear(anchor, TUNING.ABIGAIL_DEFENSIVE_MAX_FOLLOW)) then
    if not IsBusy(self.inst) then self:ClearAction() end
    self:SetTarget(attacker)
    self:ForceUpdate()
  end
end

function Mon3trBrain:OnStart()
  self.onmodechanged = function()
    self:ClearAI()
    self.bt:Reset()
    self:ForceUpdate()
  end
  self.onattacked = function(_, data) self:OnAttacked(data) end
  self.onattackother = function(_, data)
    if data ~= nil and data.target == self.ai_target then self.chase_started = GetTime() end
  end
  self.inst:ListenForEvent("kaltsit_mon3tr_modechanged", self.onmodechanged)
  self.inst:ListenForEvent("attacked", self.onattacked)
  self.inst:ListenForEvent("onattackother", self.onattackother)
  local function FollowDistance(defensive, aggressive)
    return function() return self:GetMode() == "attack" and aggressive or defensive end
  end
  self.bt = BT(self.inst, PriorityNode({
    WhileNode(function() return IsBusy(self.inst) end, "Finish current action", ConditionWaitNode(function() return not IsBusy(self.inst) end)),
    WhileNode(function() return self:CanFight() end, "Fight", DoAction(self.inst, function() return self:CombatAction() end, "Attack", true)),
    WhileNode(function() return self:GetMode() == "work" end, "Work", DoAction(self.inst, function() return self:WorkAction() end, "Work by attacking", true)),
    Follow(self.inst, GetLeader,
      FollowDistance(TUNING.ABIGAIL_DEFENSIVE_MIN_FOLLOW, TUNING.ABIGAIL_AGGRESSIVE_MIN_FOLLOW),
      FollowDistance(TUNING.ABIGAIL_DEFENSIVE_MED_FOLLOW, TUNING.ABIGAIL_AGGRESSIVE_MED_FOLLOW),
      FollowDistance(TUNING.ABIGAIL_DEFENSIVE_MAX_FOLLOW, TUNING.ABIGAIL_AGGRESSIVE_MAX_FOLLOW), true),
    Wander(self.inst, nil, nil, { minwaittime = 6, randwaittime = 6 }),
  }, .25))
end

function Mon3trBrain:OnStop()
  self.stopped = true
  self.inst:RemoveEventCallback("kaltsit_mon3tr_modechanged", self.onmodechanged)
  self.inst:RemoveEventCallback("attacked", self.onattacked)
  self.inst:RemoveEventCallback("onattackother", self.onattackother)
  self:ClearAI()
end

return Mon3trBrain
