local Widget = require "widgets/widget"
local Image = require "widgets/image"
local ImageButton = require "widgets/imagebutton"
local CONSTANTS = require "ark_constants"

-- 主人端同步真实状态；本地计时只让蒙层平滑，是否就绪仍以服务器层数为准。
local SkillSlot = Class(Widget, function(self, atlas, texture, size)
  Widget._ctor(self, "KaltsitMon3trSkillSlot")
  self.size = size
  self.icon = self:AddChild(ImageButton(atlas, texture))
  self.icon.scale_on_focus = false
  self.icon.move_on_click = false
  self.icon:ForceImageSize(size, size)

  self.dim = self:AddChild(Image("images/ui.xml", "black.tex"))
  self.dim:SetSize(size, size)
  self.dim:SetTint(1, 1, 1, 0.6)
  self.dim:SetClickable(false)

  self.charge = self:AddChild(Image("images/ui.xml", "white.tex"))
  self.charge:SetVRegPoint(ANCHOR_BOTTOM)
  self.charge:SetPosition(0, -size / 2, 0)
  self.charge:SetTint(0, 1, 0, 0.4)
  self.charge:SetClickable(false)

  self.buff = self:AddChild(Image("images/ui.xml", "white.tex"))
  self.buff:SetVRegPoint(ANCHOR_BOTTOM)
  self.buff:SetPosition(0, -size / 2, 0)
  self.buff:SetTint(1, 0.5, 0, 0.3)
  self.buff:SetClickable(false)

  self.lock = self:AddChild(Image("images/ark_skill.xml", "lock.tex"))
  self.lock:SetSize(size, size)
  self.lock:SetClickable(false)
  self:SetState("locked")
end)

function SkillSlot:SetOnClick(fn)
  self.icon:SetOnClick(fn)
end

function SkillSlot:SetCommandEnabled(enabled)
  self.commandEnabled = enabled
  self:UpdateButtonEnabled()
end

function SkillSlot:UpdateButtonEnabled()
  if self.commandEnabled and self.state == "ready" then
    self.icon:Enable()
  else
    self.icon:Disable()
  end
end

-- charging: current 为当前能量；buff: current 为剩余秒数；total 为各自总量。
-- ready / charging / buff / locked 是显示状态。
function SkillSlot:SetState(state, current, total)
  if state ~= "ready" and state ~= "charging" and state ~= "buff" and state ~= "locked" then
    return false
  end
  self.state = state
  self.charge:Hide()
  self.buff:Hide()
  self.lock:Hide()
  self.dim:Hide()
  if state == "locked" then
    self.dim:Show()
    self.lock:Show()
  elseif state == "charging" or state == "buff" then
    local ratio = total and total > 0 and math.max(0, math.min(1, (current or 0) / total)) or 0
    local mask = state == "charging" and self.charge or self.buff
    self.dim:Show()
    mask:SetSize(self.size, math.max(0.001, self.size * ratio))
    if ratio > 0 then
      mask:Show()
    end
  end
  self:UpdateButtonEnabled()
  return true
end

function SkillSlot:SyncSkillStatus(state, config)
  self:StopUpdating()
  self.progress = nil
  self.total = nil
  local level = state ~= nil and config ~= nil and config.levels[state.level] or nil
  if level == nil or state.id == "" or state.status == CONSTANTS.SKILL_STATUS.LOCKED then
    self:SetState("locked")
  elseif state.status == CONSTANTS.SKILL_STATUS.BUFFING then
    self.total = level.buffDuration
    self.progress = math.max(0, self.total - state.buffProgress)
    self:SetState("buff", self.progress, self.total)
    if self.progress > 0 then
      self:StartUpdating()
    end
  elseif state.status == CONSTANTS.SKILL_STATUS.ENERGY_RECOVERING then
    if state.activationStacks > 0 then
      self:SetState("ready")
    else
      self.total = level.activationEnergy
      self.progress = state.energyProgress
      self:SetState("charging", self.progress, self.total)
      if config.energyRecoveryMode == CONSTANTS.ENERGY_RECOVERY_MODE.AUTO and self.progress < self.total then
        self:StartUpdating()
      end
    end
  else
    -- 此阶段五个技能均无弹药或临时技能状态。
    self:SetState("locked")
  end
end

function SkillSlot:OnUpdate(dt)
  if TheNet:IsServerPaused() or self.progress == nil then
    return
  end
  if self.state == "buff" then
    self.progress = math.max(0, self.progress - dt)
    if self.progress == 0 then
      self:StopUpdating()
    end
  elseif self.state == "charging" then
    self.progress = math.min(self.total, self.progress + dt)
    if self.progress == self.total then
      self:StopUpdating()
    end
  else
    self:StopUpdating()
    return
  end
  self:SetState(self.state, self.progress, self.total)
end

return SkillSlot
