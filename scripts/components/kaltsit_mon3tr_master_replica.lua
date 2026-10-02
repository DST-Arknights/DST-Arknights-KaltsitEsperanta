local BehaviorReplica = require("components/kaltsit_mon3tr_behavior_replica")
local CONSTANTS = require("ark_constants")
local skillconfig = require("kaltsit_mon3tr_skill_config")

local SKILL_DEFAULTS = {
  id = "",
  configPatch = "",
  status = CONSTANTS.SKILL_STATUS.LOCKED,
  level = 1,
  energyProgress = 0,
  buffProgress = 0,
  bulletCount = 0,
  activationStacks = 0,
  isTemporary = 0,
  limitTimeInitial = 0,
  limitRemaining = 0,
}
local SKILL_FIELDS = {
  "id", "configPatch", "status", "level", "energyProgress", "buffProgress",
  "bulletCount", "activationStacks", "isTemporary", "limitTimeInitial", "limitRemaining",
}

local KaltsitMon3trMasterReplica = Class(function(self, inst)
  self.inst = inst
  self._hasmon3tr = net_bool(inst.GUID, "kaltsit_mon3tr_master.hasmon3tr", "kaltsit_mon3tr_mastersnapshotdirty")
  self._mode = net_tinybyte(inst.GUID, "kaltsit_mon3tr_master.mode", "kaltsit_mon3tr_mastersnapshotdirty")
  self._onsnapshotdirty = function() inst:PushEvent("kaltsit_mon3tr_masterdirty") end
  inst:ListenForEvent("kaltsit_mon3tr_mastersnapshotdirty", self._onsnapshotdirty)
  self.states = {}
  for index = 1, #skillconfig.skills do
    local state = NetState(inst, "kaltsit_mon3tr_skill")
    self.states[index] = state
    state:Attach(inst)
    state:OnAttached(function() self:NotifySkillDirty(index) end)
    state:OnDetached(function() self:NotifySkillDirty(index) end)
    state:Watch(SKILL_FIELDS, function() self:NotifySkillDirty(index) end)
    if TheWorld.ismastersim then
      self:SetSkillSnapshot(index, nil)
    end
  end
  if not TheWorld.ismastersim then
    -- 初次反序列化可能已带快照，HUD 比 replica 先创建时也需要一次刷新。
    self._inittask = inst:DoTaskInTime(0, function()
      self._inittask = nil
      self._onsnapshotdirty()
      self:NotifySkillDirty()
    end)
  end
end)

function KaltsitMon3trMasterReplica:HasMon3tr()
  return self._hasmon3tr:value()
end

function KaltsitMon3trMasterReplica:GetSkillState(index)
  return self.states[index]
end

function KaltsitMon3trMasterReplica:NotifySkillDirty(index)
  if not self._removed then
    self.inst:PushEvent("kaltsit_mon3tr_masterskilldirty", { index = index })
  end
end

function KaltsitMon3trMasterReplica:SetSkillSnapshot(index, data)
  if not TheWorld.ismastersim then
    return false
  end
  local state = self.states[index]
  if state == nil then
    return false
  end
  for _, key in ipairs(SKILL_FIELDS) do
    local value = data ~= nil and data[key] or nil
    if value == nil then
      value = SKILL_DEFAULTS[key]
    end
    if state[key] ~= value then
      state[key] = value
    end
  end
  return true
end

function KaltsitMon3trMasterReplica:GetMode()
  return BehaviorReplica.MODES[self._mode:value()] or "standby"
end

function KaltsitMon3trMasterReplica:IsValidMode(mode)
  return type(mode) == "string" and BehaviorReplica.MODE_IDS[mode] ~= nil
end

function KaltsitMon3trMasterReplica:SetSnapshot(hasmon3tr, mode)
  if not TheWorld.ismastersim or not self:IsValidMode(mode) then
    return
  end
  self._hasmon3tr:set(hasmon3tr)
  self._mode:set(BehaviorReplica.MODE_IDS[mode])
end

function KaltsitMon3trMasterReplica:RequestMode(mode)
  if not self:IsValidMode(mode) or not self:HasMon3tr() or self.inst:HasTag("playerghost") then
    return false
  end
  if TheWorld.ismastersim then
    local master = self.inst.components.kaltsit_mon3tr_master
    return master ~= nil and master:SetMode(mode) or false
  end
  -- 服务端根据实际发送玩家找到当前受控对象，客机只提交模式。
  SendModRPCToServer(GetModRPC("kaltsit_esperanta", "mon3tr_set_mode"), mode)
  return true
end

function KaltsitMon3trMasterReplica:RequestSkill(key)
  local definition = skillconfig.by_key[key]
  if definition == nil or not definition.implemented or not self:HasMon3tr()
    or self.inst:HasTag("playerghost") then
    return false
  end
  local state = self:GetSkillState(definition.index)
  if state.status ~= CONSTANTS.SKILL_STATUS.ENERGY_RECOVERING or state.activationStacks <= 0 then
    return false
  end
  if TheWorld.ismastersim then
    local master = self.inst.components.kaltsit_mon3tr_master
    return master ~= nil and master:ActivateSkill(key) or false
  end
  SendModRPCToServer(GetModRPC("kaltsit_esperanta", "mon3tr_activate_skill"), key)
  return true
end

function KaltsitMon3trMasterReplica:OnRemoveEntity()
  self._removed = true
  if self._inittask ~= nil then
    self._inittask:Cancel()
    self._inittask = nil
  end
  self.inst:RemoveEventCallback("kaltsit_mon3tr_mastersnapshotdirty", self._onsnapshotdirty)
end

return KaltsitMon3trMasterReplica
