-- ============================================================
-- 模块级事件回调（无闭包，便于 RemoveEventCallback 精确匹配）
-- ============================================================

-- Mon3tr 自身被移除时：清空 master 的引用
local function _onMon3trRemoved(master)
  master.mon3tr = nil
  master.summoned = false
  master.notsummoned = false
end

-- Mon3tr 死亡时：执行召回
local function _onMon3trDeath(master)
  master:Recall(true)
end

-- Kal'tsit（主人）被移除时（下线/离开）：清理 Mon3tr
local function _onMasterRemoved(master)
  if master.mon3tr and master.mon3tr:IsValid() then
    master.inst:RemoveEventCallback("onremove", master._onMon3trRemoved, master.mon3tr)
    master.inst:RemoveEventCallback("death", master._onMon3trDeath, master.mon3tr)
    master.mon3tr:Remove()
    master.mon3tr = nil
  end
  master.summoned = false
  master.notsummoned = false
end

-- ============================================================
-- net 变量 setter
-- ============================================================

local function setsummoned(self)
  self.inst:AddOrRemoveTag("mon3tr_master_summoned", self.summoned)
end

local function setnotsummoned(self)
  self.inst:AddOrRemoveTag("mon3tr_master_notsummoned", self.notsummoned)
end

local function setelite(self)
  self.inst.replica.kaltsit_mon3tr_master:SetElite(self.elite)
end

-- ============================================================
-- KaltsitMon3trMaster
-- ============================================================

local KaltsitMon3trMaster = Class(function(self, inst)
  self.inst = inst
  self.mon3tr = nil
  self.summoned = false
  self.notsummoned = true
  self.elite = 1

  -- 绑定模块级回调（每个实例一份 function ref，以便 RemoveEventCallback）
  self._onMon3trRemoved = function() _onMon3trRemoved(self) end
  self._onMon3trDeath   = function() _onMon3trDeath(self) end
  self._onMasterRemoved = function() _onMasterRemoved(self) end

  self.spawn_mon3tr_task = self.inst:DoTaskInTime(0, function() self:SpawnMon3tr() end)
end, nil, {
  notsummoned = setnotsummoned,
  summoned = setsummoned,
  elite  = setelite,
})

-- ============================================================
-- 精英
-- ============================================================

function KaltsitMon3trMaster:ApplyElite(elite)
  self.elite = elite
  if self.mon3tr and self.mon3tr:IsValid() then
    local eliteConfig = require("elite_config")
    local config = eliteConfig.Get(elite)
    local modifierKey = "kaltsit_esperanta_elite"
    if self.mon3tr.components.health then
      self.mon3tr.components.health.maxhealthaddmodifiers:SetModifier(modifierKey, config.mon3trHealthBonus)
    end
    if self.mon3tr.components.combat then
      self.mon3tr.components.combat.defaultdamageaddmodifiers:SetModifier(modifierKey, config.mon3trAttackBonus)
    end
  end
end

-- ============================================================
-- Mon3tr 生命周期
-- ============================================================

function KaltsitMon3trMaster:SpawnMon3tr(in_world)
  if not self.mon3tr then
    self.mon3tr = SpawnPrefab("kaltsit_esperanta_mon3tr")
  end
  local mon3tr = self.mon3tr
  if not mon3tr then return end

  -- Mon3tr 自身被移除 / 死亡
  self.inst:ListenForEvent("onremove", self._onMon3trRemoved, mon3tr)
  self.inst:ListenForEvent("death",    self._onMon3trDeath,   mon3tr)

  -- 主人下线时清理 Mon3tr
  self.inst:ListenForEvent("onremove", self._onMasterRemoved)

  self:ApplyElite(self.elite)

  if in_world then
    self:SummonComplete()
  else
    self:RecallComplete()
  end
end

-- ============================================================
-- 召唤 / 召回
-- ============================================================

function KaltsitMon3trMaster:Summon(summoning_item, pos)
  ArkLogger:Debug("Summon called with summoning_item=", summoning_item, "pos=", pos)
  if not self.mon3tr or not summoning_item then return false end
  self.mon3tr.entity:SetParent(nil)
  if pos then
    self.mon3tr.Transform:SetPosition(pos:Get())
  else
    self.mon3tr.Transform:SetPosition(self.inst.Transform:GetWorldPosition())
  end
  self.mon3tr:ReturnToScene()
  self.notsummoned = false
  self.summoned = true
  if self.onsummonfn then
    self.onsummonfn(self.inst, self.mon3tr)
  end
  return true
end

function KaltsitMon3trMaster:SummonComplete()
  self.notsummoned = false
  self.summoned = true
  if self.onsummoncompletefn ~= nil then
    self.onsummoncompletefn(self.inst, self.mon3tr)
  end
  self.inst:PushEvent("mon3tr_master_summoncomplete", self.mon3tr)
end

function KaltsitMon3trMaster:Recall(was_killed)
  if self.mon3tr ~= nil and self.summoned and not self.inst.sg:HasStateTag("dissipate") then
    self.summoned = false
    if self.onrecallfn ~= nil then
      self.onrecallfn(self.inst, self.mon3tr, was_killed)
    end
    return true
  end
end

function KaltsitMon3trMaster:RecallComplete()
  if not self.mon3tr then return end
  self.mon3tr:RemoveFromScene()
  self.mon3tr.entity:SetParent(self.inst.entity)
  self.mon3tr.Transform:SetPosition(0, 0, 0)
  self.summoned = false
  self.notsummoned = true
  if self.onrecallcompletefn ~= nil then
    self.onrecallcompletefn(self.inst, self.mon3tr)
  end
  self.inst:PushEvent("mon3tr_master_recallcomplete", self.mon3tr)
end

-- ============================================================
-- 存档
-- ============================================================

function KaltsitMon3trMaster:OnSave()
  return {
    mon3tr = self.mon3tr ~= nil and self.mon3tr:GetSaveRecord() or nil,
    mon3tr_in_world = self.mon3tr ~= nil and not self.mon3tr:IsInLimbo() or nil,
  }
end

function KaltsitMon3trMaster:OnLoad(data)
  -- 自行从 kaltsit_intellect 恢复精英等级，不依赖回调链
  local intellect = self.inst.components.kaltsit_intellect
  if intellect then
    self:ApplyElite(intellect:GetEliteLevel())
  end
  if data == nil then return end
  if data.mon3tr then
    if self.spawn_mon3tr_task then
      self.spawn_mon3tr_task:Cancel()
      self.spawn_mon3tr_task = nil
    end
    self.mon3tr = SpawnSaveRecord(data.mon3tr)
    self:SpawnMon3tr(data.mon3tr_in_world)
  end
end

-- ============================================================
-- 清理
-- ============================================================

function KaltsitMon3trMaster:OnRemoveEntity()
  self.summoned = false
  self.notsummoned = false

  if self.mon3tr and self.mon3tr:IsValid() then
    self.inst:RemoveEventCallback("onremove", self._onMon3trRemoved, self.mon3tr)
    self.inst:RemoveEventCallback("death",    self._onMon3trDeath,   self.mon3tr)
    self.mon3tr:Remove()
    self.mon3tr = nil
  end
  self.inst:RemoveEventCallback("onremove", self._onMasterRemoved)
end

return KaltsitMon3trMaster
