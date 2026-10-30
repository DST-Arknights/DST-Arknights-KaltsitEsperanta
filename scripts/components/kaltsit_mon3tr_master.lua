local CONSTANTS = require("ark_constants")
local SKILLS = TUNING.KALTSIT_MON3TR_SKILLS
local SKILLS_BY_ID = TUNING.KALTSIT_MON3TR_SKILLS_BY_ID
local SKILLS_BY_KEY = TUNING.KALTSIT_MON3TR_SKILLS_BY_KEY
local DEBUG_UNLOCK_ALL_SKILLS = false
local NEXT_MODE = {
  standby = "attack",
  attack = "work",
  work = "standby",
}

local function UpdateHungerRate(self)
  local hunger = self.inst.components.hunger
  if hunger ~= nil and self.inst:HasTag("kaltsit_esperanta") then
    hunger.burnratemodifiers:SetModifier("kaltsit_esperanta_mon3tr", self.mon3tr ~= nil and 1.2 or 0.7)
  end
end

local KaltsitMon3trMaster = Class(function(self, inst)
  self.inst = inst
  self.mon3tr = nil
  self.mon3tr_progress = nil
  self._onprogresschanged = function(pet)
    if pet == self.mon3tr and pet.components.kaltsit_mon3tr_passive ~= nil then
      self.mon3tr_progress = pet.components.kaltsit_mon3tr_passive:GetProgress()
    end
  end
  self._onmodechanged = function(pet)
    if pet == self.mon3tr then
      self:SyncMon3tr()
    end
  end
  self._onmon3trremoved = function(pet) self:ClearMon3tr(pet) end
  self._onskillstatuschanged = function(pet, data)
    local config = data ~= nil and SKILLS_BY_ID[data.skillId] or nil
    if pet == self.mon3tr and config ~= nil then
      self:SyncSkill(config.index)
    end
  end
  self._onskilladded = function(pet, data)
    if pet == self.mon3tr and data ~= nil and SKILLS_BY_ID[data.id] ~= nil then
      self:SyncSkills()
    end
  end
  self._onskillactivated = function(pet, data)
    local config = data ~= nil and SKILLS_BY_ID[data.skillId] or nil
    local behavior = pet.components.kaltsit_mon3tr_behavior
    if pet ~= self.mon3tr or config == nil or behavior == nil or behavior:GetOwner() ~= self.inst
      or not self.inst:IsValid() or self.inst:HasTag("playerghost")
      or self.inst.components.health:IsDead() or self.inst.components.talker == nil then return end
    local line = STRINGS.UI.KALTSIT_MON3TR_SKILL.CAST_LINE[config.index]
    if line ~= nil then self.inst.components.talker:Say(line) end
  end
  self._onintellectchanged = function() self:SyncSkills() end
  UpdateHungerRate(self)
end)

function KaltsitMon3trMaster:GetMon3tr()
  return self.mon3tr
end

function KaltsitMon3trMaster:SyncMon3tr()
  local pet = self.mon3tr
  local behavior = pet ~= nil and pet:IsValid() and pet.components.kaltsit_mon3tr_behavior or nil
  if behavior == nil or behavior:GetOwner() ~= self.inst then
    self:ClearMon3tr()
    return
  end
  self.inst.replica.kaltsit_mon3tr_master:SetSnapshot(true, behavior:GetMode())
end

function KaltsitMon3trMaster:SyncSkill(index)
  local config = SKILLS[index]
  if config == nil then
    return
  end
  local pet = self.mon3tr
  local behavior = pet ~= nil and pet:IsValid() and pet.components.kaltsit_mon3tr_behavior or nil
  if behavior == nil or behavior:GetOwner() ~= self.inst then
    self:ClearMon3tr()
    return
  end
  local manager = pet.components.ark_skill
  local skill = manager ~= nil and manager:GetSkill(config.id) or nil
  local data = nil
  if skill ~= nil then
    data = {
      id = skill.id,
      configPatch = skill:GetConfigPatchString(),
      status = skill.data.status,
      level = skill:GetLevel(),
      energyProgress = skill.data.energyProgress,
      buffProgress = skill.data.buffProgress,
      bulletCount = skill.data.bulletCount,
      activationStacks = skill.data.activationStacks,
      isTemporary = skill.data.isTemporary and 1 or 0,
      limitTimeInitial = skill.data.limitTimeInitial,
      limitRemaining = skill.data.limitRemaining,
    }
  end
  self.inst.replica.kaltsit_mon3tr_master:SetSkillSnapshot(index, data)
end

function KaltsitMon3trMaster:SyncSkills()
  local pet = self.mon3tr
  local behavior = pet ~= nil and pet:IsValid() and pet.components.kaltsit_mon3tr_behavior or nil
  if behavior == nil or behavior:GetOwner() ~= self.inst then
    self:ClearMon3tr()
    return
  end
  local manager = pet.components.ark_skill
  local intellect = self.inst.components.kaltsit_intellect
  local maxintellect = intellect ~= nil and intellect.max or 0
  for index, config in ipairs(SKILLS) do
    local skill = manager ~= nil and manager:GetSkill(config.id) or nil
    if skill ~= nil then
      -- 未实现的技能保持锁定；已实现技能按智识门槛解锁。
      if skill:GetLevel() ~= 1 then
        skill:SetLevel(1)
      end
      local unlocked = config.implemented == true
        and (DEBUG_UNLOCK_ALL_SKILLS or index == 1 or maxintellect >= config.intellect_threshold)
      if unlocked and not skill:IsUnlocked() then
        skill:Unlock()
      elseif not unlocked and skill:IsUnlocked() then
        skill:Lock()
      end
    end
    self:SyncSkill(index)
  end
end

local function DetachMon3tr(self)
  local pet = self.mon3tr
  if pet ~= nil and pet.components.kaltsit_mon3tr_passive ~= nil then
    self.mon3tr_progress = pet.components.kaltsit_mon3tr_passive:GetProgress()
  end
  self.mon3tr = nil
  if pet ~= nil then
    self.inst:RemoveEventCallback("kaltsit_mon3tr_modechanged", self._onmodechanged, pet)
    self.inst:RemoveEventCallback("ark_skill_status_changed", self._onskillstatuschanged, pet)
    self.inst:RemoveEventCallback("ark_skill_added", self._onskilladded, pet)
    self.inst:RemoveEventCallback("ark_skill_activate", self._onskillactivated, pet)
    self.inst:RemoveEventCallback("onremove", self._onmon3trremoved, pet)
    self.inst:RemoveEventCallback("intellect_changed", self._onintellectchanged)
    self.inst:RemoveEventCallback("kaltsit_mon3tr_progresschanged", self._onprogresschanged, pet)
  end
end

function KaltsitMon3trMaster:SetMon3tr(pet)
  local behavior = pet ~= nil and pet:IsValid() and pet.components.kaltsit_mon3tr_behavior or nil
  if behavior == nil or behavior:GetOwner() ~= self.inst then
    return false
  end
  if self.mon3tr ~= pet then
    -- 更换对象只发布最终快照，避免同帧出现一次无宠物的 UI 状态。
    DetachMon3tr(self)
    self.mon3tr = pet
    if pet.components.kaltsit_mon3tr_passive ~= nil and self.mon3tr_progress ~= nil then
      pet.components.kaltsit_mon3tr_passive:SetProgress(self.mon3tr_progress)
    end
    self.inst:ListenForEvent("kaltsit_mon3tr_modechanged", self._onmodechanged, pet)
    self.inst:ListenForEvent("ark_skill_status_changed", self._onskillstatuschanged, pet)
    self.inst:ListenForEvent("ark_skill_added", self._onskilladded, pet)
    self.inst:ListenForEvent("ark_skill_activate", self._onskillactivated, pet)
    self.inst:ListenForEvent("onremove", self._onmon3trremoved, pet)
    self.inst:ListenForEvent("intellect_changed", self._onintellectchanged)
    self.inst:ListenForEvent("kaltsit_mon3tr_progresschanged", self._onprogresschanged, pet)
  end
  UpdateHungerRate(self)
  self:SyncMon3tr()
  self:SyncSkills()
  return true
end

function KaltsitMon3trMaster:ClearMon3tr(expectedpet)
  local pet = self.mon3tr
  if expectedpet ~= nil and pet ~= expectedpet then
    return false
  end
  DetachMon3tr(self)
  UpdateHungerRate(self)
  self.inst.replica.kaltsit_mon3tr_master:SetSnapshot(false, "standby")
  for index = 1, TUNING.KALTSIT_MON3TR_SKILL_COUNT do
    self.inst.replica.kaltsit_mon3tr_master:SetSkillSnapshot(index, nil)
  end
  return true
end

function KaltsitMon3trMaster:SetMode(mode)
  if not self.inst.replica.kaltsit_mon3tr_master:IsValidMode(mode)
    or not self.inst:IsValid() or self.inst:HasTag("playerghost") then
    return false
  end
  local pet = self.mon3tr
  local behavior = pet ~= nil and pet:IsValid() and pet.components.kaltsit_mon3tr_behavior or nil
  if behavior == nil or behavior:GetOwner() ~= self.inst or pet:HasTag("playerghost") then
    return false
  end
  local ownerhealth = self.inst.components.health
  local pethealth = pet.components.health
  if (ownerhealth ~= nil and ownerhealth:IsDead()) or (pethealth ~= nil and pethealth:IsDead()) then
    return false
  end
  return behavior:SetMode(mode)
end

function KaltsitMon3trMaster:CycleMode()
  local pet = self.mon3tr
  local behavior = pet ~= nil and pet:IsValid() and pet.components.kaltsit_mon3tr_behavior or nil
  if behavior == nil then
    return false
  end
  -- 在服务端读取当前模式，连续请求也会依次推进；有效性检查沿用 SetMode。
  local mode = NEXT_MODE[behavior:GetMode()]
  return mode ~= nil and self:SetMode(mode) or false
end

function KaltsitMon3trMaster:ActivateSkill(key)
  local definition = SKILLS_BY_KEY[key]
  if definition == nil or not definition.implemented
    or definition.activationMode ~= CONSTANTS.ACTIVATION_MODE.MANUAL
    or not self.inst:IsValid() or self.inst:HasTag("playerghost") then
    return false
  end
  local pet = self.mon3tr
  local behavior = pet ~= nil and pet:IsValid() and pet.components.kaltsit_mon3tr_behavior or nil
  if behavior == nil or behavior:GetOwner() ~= self.inst or pet:HasTag("playerghost") then
    return false
  end
  local ownerhealth = self.inst.components.health
  local pethealth = pet.components.health
  if (ownerhealth ~= nil and ownerhealth:IsDead()) or (pethealth ~= nil and pethealth:IsDead()) then
    return false
  end
  local manager = pet.components.ark_skill
  local skill = manager ~= nil and manager:GetSkill(definition.id) or nil
  return skill ~= nil and skill:TryActivate() or false
end

function KaltsitMon3trMaster:OnRemoveFromEntity()
  -- 主人端只清理指令关系；宠物生命周期仍由 petleash 管理，自管理也不能删除自己。
  self:ClearMon3tr()
end

function KaltsitMon3trMaster:OnSave()
  local pet = self.mon3tr
  local passive = pet ~= nil and pet.components.kaltsit_mon3tr_passive or nil
  local progress = passive ~= nil and passive:GetProgress() or self.mon3tr_progress
  return progress ~= nil and { mon3tr_progress = progress } or nil
end

function KaltsitMon3trMaster:OnLoad(data)
  if data ~= nil and data.mon3tr_progress ~= nil then
    self.mon3tr_progress = data.mon3tr_progress
    local pet = self.mon3tr
    if pet ~= nil and pet.components.kaltsit_mon3tr_passive ~= nil then
      pet.components.kaltsit_mon3tr_passive:SetProgress(self.mon3tr_progress)
    end
  end
end

KaltsitMon3trMaster.OnRemoveEntity = KaltsitMon3trMaster.OnRemoveFromEntity

return KaltsitMon3trMaster
