local temporary_control = require("kaltsit_temporary_control")
local ARMOR_RANGE = 12
local ARMOR_ABSORPTION = 0.5
local INVULNERABILITY_DURATION = 0.5
local INVULNERABILITY_COOLDOWN = 5
local INVULNERABILITY_BUFF = "kaltsit_mon3tr_invulnerability_buff"
local REGEN_CAUSE = "kaltsit_mon3tr_regen"
local SYMBIOSIS_CAUSE = "kaltsit_mon3tr_symbiosis"
local ARMOR_KEY = "kaltsit_mon3tr_beast_armor"
local FOOD_DAMAGE_KEY = "kaltsit_mon3tr_food_damage"
local RECONSTRUCT_HEALTH_COST = 300
local COLLAPSE_RADIUS = 20 -- 设定的 5 格地皮，每格 4 世界单位。
local COLLAPSE_DAMAGE = 1000
local COLLAPSE_STUN_DURATION = 2
local COLLAPSE_STUN_KEY = "kaltsit_mon3tr_collapse_stun"

local function KeepHealthDelta(_, amount)
  return amount
end

local function IsAlive(inst)
  return inst ~= nil and inst:IsValid() and not inst:HasAnyTag("playerghost", "corpse")
    and inst.components.health ~= nil and not inst.components.health:IsDead()
end

local function IsPlayerControlled(inst)
  local userid = inst.Network ~= nil and inst.Network:GetUserID() or nil
  return userid ~= nil and userid ~= ""
end

local KaltsitMon3trPassive = Class(function(self, inst)
  self.inst = inst
  self.owner = nil
  self.foods = {}
  self.invulnerability_until = 0
  self.invulnerability_cooldown_until = 0
  self._knockeddown = false
  self._regen_elapsed = 0
  self._ownerremoved = function() self:SetOwner(nil) end
  self._oneat = function(_, data) self:OnEat(data) end
  self._ondeath = function(_, data)
    self:SetInvulnerability(0)
    self:OnKnockedDown(data)
  end
  self._onattacked = function(_, data)
    if self:IsEnabled() and IsAlive(inst) and data ~= nil
      and ((data.damageresolved or data.damage or 0) > 0)
      and GetTime() >= self.invulnerability_cooldown_until then
      self.invulnerability_cooldown_until = GetTime() + INVULNERABILITY_COOLDOWN
      self:SetInvulnerability(self:GetInvulnerabilityDuration())
    end
  end
  self._petredirect = function(next, target, amount, overtime, cause, ignore_invincible, afflicter, ignore_absorb)
    local redirected = next(target, amount, overtime, cause, ignore_invincible, afflicter, ignore_absorb)
    if redirected or not self:IsEnabled() then return redirected end
    if amount > 0 and not self:CanReceiveHealing(afflicter, overtime, cause) then return true end
    if amount < 0 then
      self:RefreshArmor()
      if not ignore_invincible and self:IsInvulnerable() then return true end
    end
    return redirected
  end
  self._petattacked = function(next, combat, attacker, ...)
    if self:IsEnabled() and self:IsInvulnerable() then
      self:ReflectInvulnerableHit(attacker)
      return false
    end
    return next(combat, attacker, ...)
  end
  self._eat = function(next, eater, food, feeder, ...)
    local oldfeeding = self._ownerfeeding
    self._ownerfeeding = self:IsEnabled() and feeder == self.owner
    local result = next(eater, food, feeder, ...)
    self._ownerfeeding = oldfeeding
    return result
  end
  self._ownerdelta = function(next, owner, amount, overtime, cause, ignore_invincible, afflicter, ignore_absorb)
    local modified = next(owner, amount, overtime, cause, ignore_invincible, afflicter, ignore_absorb)
    if modified ~= nil then amount = modified end
    if not self:IsEnabled() or not IsAlive(inst) or not IsAlive(owner)
      or amount >= 0 or ignore_absorb or cause == "kaltsit_esperanta_skill1"
      or afflicter == owner or self._transferring then
      return amount
    end
    -- 此入口已结算主人护甲与减伤；原版尚未执行的单击上限先投影一次。
    local health = owner.components.health
    if health.maxdamagetakenperhit ~= nil and amount < health.maxdamagetakenperhit
      and not health._ignore_maxdamagetakenperhit then
      amount = health.maxdamagetakenperhit
    end
    self._transferring = true
    inst.components.health:DoDelta(amount * 0.5, overtime, SYMBIOSIS_CAUSE,
      ignore_invincible, afflicter, true)
    self._transferring = nil
    return amount * 0.5
  end
  ArkHookFunction(inst.components.health, "redirect", self._petredirect)
  -- 新版本普通攻击和范围攻击直接进入 Internal，旧版本沿用 GetAttacked。
  self._combatattacked = inst.components.combat.GetAttacked_Internal ~= nil
    and "GetAttacked_Internal" or "GetAttacked"
  ArkHookFunction(inst.components.combat, self._combatattacked, self._petattacked)
  ArkHookFunction(inst.components.eater, "Eat", self._eat)
  inst:ListenForEvent("oneat", self._oneat)
  inst:ListenForEvent("attacked", self._onattacked)
  inst:ListenForEvent("death", self._ondeath)
  self._task = inst:DoPeriodicTask(0.25, function()
    self:RefreshArmor()
    self._regen_elapsed = self._regen_elapsed + 0.25
    if self._regen_elapsed >= 1 then
      self._regen_elapsed = 0
      if self:IsEnabled() and IsAlive(inst) then
        inst.components.health:DoDelta(1, true, REGEN_CAUSE, nil, inst)
      end
    end
  end)
end)

function KaltsitMon3trPassive:IsEnabled()
  return self.owner ~= nil and self.owner ~= self.inst and self.owner:IsValid()
    and not IsPlayerControlled(self.inst)
end

function KaltsitMon3trPassive:SetOwner(owner)
  if owner == self.inst or IsPlayerControlled(self.inst)
    or (owner ~= nil and (not owner:IsValid() or owner.prefab ~= "kaltsit_esperanta")) then
    owner = nil
  end
  if owner == self.owner then
    self:RefreshArmor()
    self:RefreshInvulnerabilityBuff()
    return
  end
  local oldowner = self.owner
  if oldowner ~= nil then
    oldowner:RemoveEventCallback("onremove", self._ownerremoved)
    ArkUnhookFunction(oldowner.components.health, "deltamodifierfn", self._ownerdelta)
    if self._added_immune_stun then oldowner:RemoveTag("immune_stun") end
  end
  self.owner = owner
  self._added_immune_stun = nil
  self._ownerfeeding = nil
  self._regen_elapsed = 0
  if oldowner ~= nil or owner == nil then self:SetInvulnerability(0) end
  if owner ~= nil then
    -- 空链仍需返回数值；仅为缺失回调补基线，保留已有回调。
    if owner.components.health.deltamodifierfn == nil then
      owner.components.health.deltamodifierfn = KeepHealthDelta
    end
    ArkHookFunction(owner.components.health, "deltamodifierfn", self._ownerdelta)
    owner:ListenForEvent("onremove", self._ownerremoved)
    self._added_immune_stun = not owner:HasTag("immune_stun")
    if self._added_immune_stun then owner:AddTag("immune_stun") end
  end
  self:RefreshArmor()
  self:RefreshFoodDamage()
  self:RefreshInvulnerabilityBuff()
end

function KaltsitMon3trPassive:RefreshArmor()
  local health = self.inst.components.health
  if self:IsEnabled() and self.inst:IsNear(self.owner, ARMOR_RANGE) then
    health.externalabsorbmodifiers:SetModifier(self.inst, ARMOR_ABSORPTION, ARMOR_KEY)
  else
    health.externalabsorbmodifiers:RemoveModifier(self.inst, ARMOR_KEY)
  end
end

function KaltsitMon3trPassive:CanReceiveHealing(healer, overtime, cause)
  if not self:IsEnabled() then return true end
  if self._ownerfeeding or healer == self.owner or cause == REGEN_CAUSE then return true end
  if overtime and type(cause) == "string" and (cause == "regen" or string.sub(cause, 1, 6) == "regen_") then
    return true
  end
  if healer ~= nil and healer:IsValid() then
    if healer._owner == self.owner then return true end
    local follower = healer.components ~= nil and healer.components.follower or nil
    local inventoryitem = healer.components ~= nil and healer.components.inventoryitem or nil
    return (follower ~= nil and follower:GetLeader() == self.owner)
      or (inventoryitem ~= nil and inventoryitem:GetGrandOwner() == self.owner)
  end
  return false
end

function KaltsitMon3trPassive:GetInvulnerabilityDuration()
  return self.owner ~= nil and self.owner:HasDebuff("kaltsit_neuro_gel_buff")
    and 1 or INVULNERABILITY_DURATION
end

function KaltsitMon3trPassive:IsInvulnerable()
  return GetTime() < self.invulnerability_until
end

function KaltsitMon3trPassive:RefreshInvulnerabilityBuff()
  if self:IsEnabled() and IsAlive(self.inst) and self:IsInvulnerable() then
    if not self.inst:HasDebuff(INVULNERABILITY_BUFF) then
      self.inst:AddDebuff(INVULNERABILITY_BUFF, INVULNERABILITY_BUFF)
    end
  else
    self.inst:RemoveDebuff(INVULNERABILITY_BUFF)
  end
end

function KaltsitMon3trPassive:SetInvulnerability(duration)
  if self._invulnerability_task ~= nil then
    self._invulnerability_task:Cancel()
    self._invulnerability_task = nil
  end
  self.invulnerability_until = GetTime() + duration
  if duration > 0 then
    self._invulnerability_task = self.inst:DoTaskInTime(duration, function()
      self._invulnerability_task = nil
      self:SetInvulnerability(0)
    end)
  end
  self:RefreshInvulnerabilityBuff()
end

function KaltsitMon3trPassive:IsEnemy(target)
  if target == nil or target == self.owner or target == self.inst or not IsAlive(target)
    or target.components.combat == nil or target:HasAnyTag("INLIMBO", "notarget", "invisible", "companion") then
    return false
  end
  local leader = target.components.follower ~= nil and target.components.follower:GetLeader() or nil
  if leader == self.owner or leader == self.inst then return false end
  if not TheNet:GetPVPEnabled() and (target:HasTag("player") or (leader ~= nil and leader:HasTag("player"))) then
    return false
  end
  local owncombat = self.owner ~= nil and self.owner.components.combat or nil
  return target:HasTag("hostile") or target:HasTag("monster")
    or target.components.combat.target == self.inst or target.components.combat.target == self.owner
    or self.inst.components.combat.target == target or (owncombat ~= nil and owncombat.target == target)
end

function KaltsitMon3trPassive:ReflectInvulnerableHit(attacker)
  if self._reflecting or self.owner == nil or not self.owner:HasDebuff("kaltsit_neuro_gel_buff")
    or not self:IsEnemy(attacker) then return end
  self._reflecting = true
  for _ = 1, 2 do
    if IsAlive(attacker) then
      local damage, spdamage = self.inst.components.combat:ConvertToTrueDamage(20)
      attacker.components.combat:GetAttacked(self.inst, damage, nil, nil, spdamage)
    end
  end
  self._reflecting = nil
end

function KaltsitMon3trPassive:GetProgress()
  local foods = {}
  for name in pairs(self.foods) do foods[name] = true end
  return { foods = foods }
end

function KaltsitMon3trPassive:SetProgress(data)
  self.foods = {}
  if data ~= nil and type(data.foods) == "table" then
    for name, eaten in pairs(data.foods) do
      if type(name) == "string" and eaten == true then self.foods[name] = true end
    end
  end
  self:RefreshFoodDamage()
end

function KaltsitMon3trPassive:RefreshFoodDamage()
  local count = 0
  for _ in pairs(self.foods) do count = count + 1 end
  local combat = self.inst.components.combat
  if self:IsEnabled() and count > 0 then
    combat.defaultdamageaddmodifiers:SetModifier(self.inst, count, FOOD_DAMAGE_KEY)
  else
    combat.defaultdamageaddmodifiers:RemoveModifier(self.inst, FOOD_DAMAGE_KEY)
  end
end

function KaltsitMon3trPassive:OnEat(data)
  local food = data ~= nil and data.food or nil
  if not self:IsEnabled() or data == nil or data.feeder ~= self.owner or food == nil
    or not food:HasTag("preparedfood") or self.foods[food.prefab] then return end
  self.foods[food.prefab] = true
  self:RefreshFoodDamage()
  if IsAlive(self.owner) and self.owner.components.sanity ~= nil then
    self.owner.components.sanity:DoDelta(20)
  end
  self.inst:PushEvent("kaltsit_mon3tr_progresschanged", self:GetProgress())
end

function KaltsitMon3trPassive:TryResurrect(doer)
  local health = self.inst.components.health
  if not self:IsEnabled() or doer ~= self.owner or not doer:HasTag("playerghost")
    or doer:HasTag("reviving") or doer._kaltsit_mon3tr_reconstructing
    or not IsAlive(self.inst) or health.currenthealth < RECONSTRUCT_HEALTH_COST then return false end
  doer._kaltsit_mon3tr_reconstructing = true
  -- 监听归主人所有，300 血恰好致死并删除宠物时仍完成复活数值结算。
  local onrespawned
  local function cleanup()
    doer._kaltsit_mon3tr_reconstructing = nil
    doer:RemoveEventCallback("ms_respawnedfromghost", onrespawned)
    doer:RemoveEventCallback("onremove", cleanup)
  end
  onrespawned = function()
    cleanup()
    -- Scheduler 先复活主人，随后 SG 才处理宠物死亡并扣回召唤理智；
    -- 下一帧结算最终三维，避免恰好 300 血的重构再次被扣去 100 理智。
    doer:DoTaskInTime(0, function()
      if not IsAlive(doer) then return end
      doer.components.health:SetPenalty(0)
      doer.components.health:SetPercent(0.3)
      if doer.components.hunger ~= nil then doer.components.hunger:SetPercent(0.3) end
      if doer.components.sanity ~= nil then doer.components.sanity:SetPercent(0.3) end
    end)
  end
  doer:ListenForEvent("ms_respawnedfromghost", onrespawned)
  doer:ListenForEvent("onremove", cleanup)
  -- 无 source 走原版原地复活，避免 source 宠物恰好在扣血时被删除。
  doer:PushEvent("respawnfromghost", { user = doer })
  health:DoDelta(-RECONSTRUCT_HEALTH_COST, false, "kaltsit_mon3tr_reconstruct", true, doer, true)
  return true
end

function KaltsitMon3trPassive:OnKnockedDown()
  if self._knockeddown or not self:IsEnabled() then return end
  self._knockeddown = true
  local owner = self.owner
  local x, y, z = self.inst.Transform:GetWorldPosition()
  local targets = TheSim:FindEntities(x, y, z, COLLAPSE_RADIUS, { "_combat", "_health" },
    { "INLIMBO", "playerghost", "corpse", "FX", "NOCLICK" })
  for _, target in ipairs(targets) do
    if self:IsEnemy(target) then
      target.components.combat:GetAttacked(owner, 0, nil, nil, { true_damage = COLLAPSE_DAMAGE })
      if IsAlive(target) then
        temporary_control.ApplyStun(target, COLLAPSE_STUN_DURATION, COLLAPSE_STUN_KEY)
      end
    end
  end
end

function KaltsitMon3trPassive:OnSave()
  return {
    progress = self:GetProgress(),
    invulnerability_remaining = math.max(0, self.invulnerability_until - GetTime()),
    invulnerability_cooldown_remaining = math.max(0, self.invulnerability_cooldown_until - GetTime()),
    knockeddown = self._knockeddown,
  }
end

function KaltsitMon3trPassive:OnLoad(data)
  if data == nil then return end
  self:SetProgress(data.progress)
  self.invulnerability_cooldown_until = GetTime()
    + math.min(INVULNERABILITY_COOLDOWN, math.max(0, tonumber(data.invulnerability_cooldown_remaining) or 0))
  self:SetInvulnerability(math.min(1, math.max(0, tonumber(data.invulnerability_remaining) or 0)))
  self._knockeddown = data.knockeddown == true
end

function KaltsitMon3trPassive:OnRemoveFromEntity()
  self:SetInvulnerability(0)
  self:SetOwner(nil)
  if self._task ~= nil then self._task:Cancel(); self._task = nil end
  ArkUnhookFunction(self.inst.components.health, "redirect", self._petredirect)
  ArkUnhookFunction(self.inst.components.combat, self._combatattacked, self._petattacked)
  ArkUnhookFunction(self.inst.components.eater, "Eat", self._eat)
  self.inst:RemoveEventCallback("oneat", self._oneat)
  self.inst:RemoveEventCallback("attacked", self._onattacked)
  self.inst:RemoveEventCallback("death", self._ondeath)
end

KaltsitMon3trPassive.OnRemoveEntity = KaltsitMon3trPassive.OnRemoveFromEntity

return KaltsitMon3trPassive
