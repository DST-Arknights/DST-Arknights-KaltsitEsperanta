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
local GIVE_DIST, ITEM_ACTION_TIMEOUT, ITEM_RETRY_TIME = 3, 10, 5

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
  local action = self.action
  self.action = nil -- 主动切换动作不计入寻路失败。
  if action ~= nil and self.inst:GetBufferedAction() == action then
    self.inst:ClearBufferedAction()
  end
  if (action ~= nil and locomotor.bufferedaction == action)
      or (self.inst:GetBufferedAction() == nil and locomotor.bufferedaction == nil) then
    locomotor:Clear()
    locomotor:Stop()
  end
end

function Mon3trBrain:ClearAI()
  self:ClearAction()
  if self.ai_target ~= nil and self.inst.components.combat.target == self.ai_target then
    self.inst.components.combat:SetTarget(nil)
  end
  self.ai_target, self.work_target, self.chase_started = nil, nil, nil
  self.ignored_target, self.ignore_until, self.next_retarget = nil, nil, nil
  self.ignored_pickups, self.give_retry_until, self.pickup_blocked = nil, nil, nil
  self.pickup_target = nil
end

function Mon3trBrain:SetAction(action, onfail)
  self:ClearAction()
  -- 实际战斗保留目标；工作挥爪（target=nil）及收集动作不继承战斗目标。
  if self:GetMode() == "work" and not (action.action == ACTIONS.ATTACK and action.target ~= nil) then
    self.inst.components.combat:SetTarget(nil)
  end
  self.action = action
  action:AddSuccessAction(function()
    if self.action == action then self.action = nil end
  end)
  if onfail ~= nil then
    action:AddFailAction(function()
      if self.action == action then onfail() end
    end)
  end
  return action
end

function Mon3trBrain:IgnorePickup(item)
  self.ignored_pickups = self.ignored_pickups or setmetatable({}, { __mode = "k" })
  self.ignored_pickups[item] = GetTime() + ITEM_RETRY_TIME
end

function Mon3trBrain:CanCollect(item)
  local inventoryitem = item ~= nil and item:IsValid() and item.components.inventoryitem or nil
  local ignored = self.ignored_pickups ~= nil and self.ignored_pickups[item] or nil
  local burnable = item ~= nil and item.components.burnable or nil
  return inventoryitem ~= nil and inventoryitem.canbepickedup and inventoryitem.cangoincontainer
    and inventoryitem.is_landed and not inventoryitem:IsHeld()
    and not item:IsInLimbo() and not item:HasTag("outofreach") and item.entity:IsVisible()
    and item.components.trap == nil and item:IsOnPassablePoint()
    and item:GetCurrentPlatform() == self.inst:GetCurrentPlatform()
    and (burnable == nil or not (burnable:IsBurning() or burnable:IsSmoldering()))
    and item:IsNear(GetLeader(self.inst) or self.inst, WORK_KEEP_DIST)
    and (ignored == nil or GetTime() >= ignored)
    and (self.inst.components.itemtyperestrictions == nil
      or self.inst.components.itemtyperestrictions:IsAllowed(item))
end

function Mon3trBrain:PickupAction()
  if not self:IsActive() or self:GetMode() ~= "work" then return nil end
  local inst, blocked = self.inst, nil
  local inventory = inst.components.inventory
  -- 在原版过滤完成后记录容量阻塞；实际容量仍由宠物库存计算。
  local capacity = { CanAcceptCount = function(_, item, count)
    local accepted = inventory:CanAcceptCount(item, count)
    if accepted <= 0 and blocked == nil then blocked = item end
    return accepted
  end }
  local target = FindPickupableItem(inst, WORK_SEARCH_DIST, false, nil, nil, nil, false, inst,
    function(_, item) return self:CanCollect(item) end, capacity)
  -- 返还腾空间后仍记得远处的掉落物，不因回到主人身边而丢失收集目标。
  if self:CanCollect(self.pickup_target) then
    if target == nil and inventory:CanAcceptCount(self.pickup_target, 1) > 0 then
      target = self.pickup_target
    elseif inventory:CanAcceptCount(self.pickup_target, 1) <= 0 then
      blocked = blocked or self.pickup_target
    end
  else
    self.pickup_target = nil
  end
  self.pickup_blocked = blocked
  if target == nil then return nil end
  self.pickup_target = target

  local expires = GetTime() + ITEM_ACTION_TIMEOUT
  local action = BufferedAction(inst, target, ACTIONS.PICKUP)
  action.validfn = function()
    if not self:IsActive() or self:GetMode() ~= "work" then return false end
    if GetTime() >= expires then
      self:IgnorePickup(target)
      return false
    end
    return self:CanCollect(target) and inventory:CanAcceptCount(target, 1) > 0
  end
  -- 原版 PICKUP 会拿走整堆；只在实际拾取帧拆出能收下的部分。
  local doAction = action.Do
  action.Do = function(act)
    if not act:IsValid() then return false end
    local stack = target.components.stackable
    local count = inventory:CanAcceptCount(target)
    if count <= 0 then return false end
    if stack ~= nil and count < stack:StackSize() then
      act.target = stack:Get(count)
      act.target.Transform:SetPosition(target.Transform:GetWorldPosition())
      act.initialtargetowner = act.target.components.inventoryitem.owner
    end
    local success, reason = doAction(act)
    if not success and act.target ~= target and act.target:IsValid()
      and not act.target.components.inventoryitem:IsHeld() and target:IsValid() then
      stack:Put(act.target, target:GetPosition())
      act.target = target
      act.initialtargetowner = target.components.inventoryitem.owner
    end
    return success, reason
  end
  return self:SetAction(action, function() self:IgnorePickup(target) end)
end

function Mon3trBrain:CanGive(leader, item)
  if leader == nil or not leader:IsValid() or leader ~= GetLeader(self.inst)
    or leader:HasTag("playerghost") or item == nil or not item:IsValid()
    or item.components.inventoryitem == nil or item.components.inventoryitem.islockedinslot
    or item.components.inventoryitem:GetGrandOwner() ~= self.inst then
    return false
  end
  local inventory, trader = leader.components.inventory, leader.components.trader
  return inventory ~= nil and trader ~= nil and inventory:IsOpenedBy(leader)
    and inventory:CanAcceptCount(item) > 0 and trader:AbleToAccept(item, self.inst)
    and trader:WantsToAccept(item, self.inst)
end

function Mon3trBrain:GiveAction(nearOnly, needSpace)
  if not self:IsActive() or self:GetMode() ~= "work"
    or GetTime() < (self.give_retry_until or 0) or (needSpace and not self.pickup_blocked) then
    return nil
  end
  local inst, leader = self.inst, GetLeader(self.inst)
  if leader == nil or (nearOnly and not inst:IsNear(leader, GIVE_DIST)) then return nil end
  local item = inst.components.inventory:FindItem(function(item) return self:CanGive(leader, item) end)
  if item == nil then return nil end
  if needSpace then self.pickup_target = self.pickup_blocked end
  local expires = GetTime() + ITEM_ACTION_TIMEOUT
  local action = BufferedAction(inst, leader, ACTIONS.GIVEALLTOPLAYER, item)
  action.validfn = function()
    if not self:IsActive() or self:GetMode() ~= "work" then return false end
    if GetTime() >= expires then
      self.give_retry_until = GetTime() + ITEM_RETRY_TIME
      return false
    end
    return self:CanGive(leader, item)
  end
  return self:SetAction(action, function() self.give_retry_until = GetTime() + ITEM_RETRY_TIME end)
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
  if not self:IsActive() then return false end
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
  if not self:IsActive() or target == nil then return nil end
  local action = BufferedAction(self.inst, target, ACTIONS.ATTACK)
  action.validfn = function()
    local anchor = GetLeader(self.inst) or self.inst
    local maxdist = mode == "attack" and TUNING.ABIGAIL_COMBAT_TARGET_DISTANCE + 2 or TUNING.ABIGAIL_DEFENSIVE_MAX_FOLLOW
    return self:IsActive() and self:GetMode() == mode and self:CanTarget(target)
      and self.inst:GetDistanceSqToInst(anchor) < maxdist * maxdist
  end
  return self:SetAction(action)
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
  -- 战斗分支优先处理威胁；工作挥爪不继承战斗目标，避免误伤生物。
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
  return self:SetAction(action)
end

function Mon3trBrain:OnAttacked(data)
  if not self:IsActive() then return end
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
    WhileNode(function() return self:GetMode() == "work" end, "Collect and work", PriorityNode({
      DoAction(self.inst, function() return self:GiveAction(true) end, "Give nearby owner", true),
      DoAction(self.inst, function() return self:PickupAction() end, "Collect nearby items", true),
      DoAction(self.inst, function() return self:GiveAction(false, true) end, "Return to make room", true),
      DoAction(self.inst, function() return self:WorkAction() end, "Work by attacking", true),
      DoAction(self.inst, function() return self:GiveAction() end, "Return after work", true),
      DoAction(self.inst, function() self:ClearAction(); return nil end, "Clear finished work route"),
    }, .25)),
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
