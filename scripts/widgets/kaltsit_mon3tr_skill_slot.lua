local Widget = require "widgets/widget"
local Image = require "widgets/image"
local ImageButton = require "widgets/imagebutton"
local Text = require "widgets/text"
local CONSTANTS = require "ark_constants"

local BLINK_DURATION = 0.3

local function SetMaskProgress(mask, size, ratio)
  ratio = math.max(0, math.min(1, ratio))
  -- 与 ark_skill 一致，蒙层上下各留 8% 的余量。
  mask:SetSize(size, size * (0.08 + 0.84 * ratio))
end

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
  self.dim:SetTint(1, 1, 1, 0.42)
  self.dim:SetClickable(false)

  self.lockedDim = self:AddChild(Image("images/ui.xml", "black.tex"))
  self.lockedDim:SetSize(size, size)
  self.lockedDim:SetTint(1, 1, 1, 0.6)
  self.lockedDim:SetClickable(false)

  self.charge = self:AddChild(Image("images/ui.xml", "white.tex"))
  self.charge:SetVRegPoint(ANCHOR_BOTTOM)
  self.charge:SetPosition(0, -size / 2, 0)
  self.charge:SetTint(0, 1, 0, 0.28)
  self.charge:SetClickable(false)

  self.buff = self:AddChild(Image("images/ui.xml", "white.tex"))
  self.buff:SetVRegPoint(ANCHOR_BOTTOM)
  self.buff:SetPosition(0, -size / 2, 0)
  self.buff:SetTint(1, 0.5, 0, 0.21)
  self.buff:SetClickable(false)

  self.lock = self:AddChild(Image("images/ark_skill.xml", "lock.tex"))
  self.lock:SetSize(size, size)
  self.lock:SetClickable(false)

  self.stop = self:AddChild(Image("images/ark_skill.xml", "stop.tex"))
  self.stop:SetSize(size, size)
  self.stop:SetClickable(false)

  self.autoActivation = self:AddChild(Image("images/ark_skill.xml", "auto_activation.tex"))
  self.autoActivation:SetScale(size / 64 / 2)
  self.autoActivation:SetClickable(false)
  self.autoActivation:Hide()

  self.blinkMask = self:AddChild(Image("images/ui.xml", "white.tex"))
  self.blinkMask:SetSize(size, size)
  self.blinkMask:SetTint(1, 1, 1, 0)
  self.blinkMask:SetClickable(false)
  self.blinkMask:Hide()

  self.stacks = self:AddChild(Widget("mon3tr_activation_stacks"))
  self.stacks:SetPosition(-size / 2, size / 2, 0)
  self.stacks:SetClickable(false)
  local stackBg = self.stacks:AddChild(Image("images/ark_item_ui.xml", "circle.tex"))
  stackBg:SetSize(20 * size / 64, 20 * size / 64)
  stackBg:SetTint(0, 0, 0, 0.8)
  stackBg:SetClickable(false)
  self.stacksText = self.stacks:AddChild(Text(SEGEOUI_ALPHANUM_ITALICFONT, 16 * size / 64))
  self.stacksText:SetClickable(false)
  self.stacks:Hide()

  self.limitBarBg = self:AddChild(Image("images/ui.xml", "white.tex"))
  self.limitBarBg:SetPosition(0, -size / 2 - 1, 0)
  self.limitBarBg:SetSize(size, 2)
  self.limitBarBg:SetTint(0.3, 0.3, 0.3, 1)
  self.limitBarBg:SetClickable(false)
  self.limitBarBg:Hide()
  self.limitBarFg = self:AddChild(Image("images/ui.xml", "white.tex"))
  self.limitBarFg:SetPosition(-size / 2, -size / 2 - 1, 0)
  self.limitBarFg:SetHRegPoint(ANCHOR_LEFT)
  self.limitBarFg:SetTint(1, 0.5, 0, 1)
  self.limitBarFg:SetClickable(false)
  self.limitBarFg:Hide()
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
-- ready / charging / buff / bullet / locked 是显示状态。
function SkillSlot:SetState(state, current, total)
  if state ~= "ready" and state ~= "charging" and state ~= "buff" and state ~= "bullet" and state ~= "locked" then
    return false
  end
  self.state = state
  self.charge:Hide()
  self.buff:Hide()
  self.lock:Hide()
  self.stop:Hide()
  self.dim:Hide()
  self.lockedDim:Hide()
  local auto = self.activationMode == CONSTANTS.ACTIVATION_MODE.AUTO
  local passive = self.activationMode == CONSTANTS.ACTIVATION_MODE.PASSIVE
  self.autoActivation:Hide()
  if auto and state ~= "locked" then
    self.autoActivation:Show()
  end
  if state ~= "locked" and not passive and (auto or state ~= "ready") then
    self.dim:Show()
  end
  if state == "locked" then
    self.lockedDim:Show()
    self.lock:Show()
    self:StopBlink()
  elseif state == "charging" or state == "buff" or state == "bullet" then
    local ratio = total and total > 0 and math.max(0, math.min(1, (current or 0) / total)) or 0
    local mask = state == "charging" and self.charge or self.buff
    SetMaskProgress(mask, self.size, ratio)
    mask:Show()
    if state == "bullet" then
      self.stop:Show()
    end
  end
  -- 多层技能已有可用层数时仍显示下一层的充能进度。
  if state == "ready" and self.progress ~= nil and self.total ~= nil then
    SetMaskProgress(self.charge, self.size, self.total > 0 and self.progress / self.total or 0)
    self.charge:Show()
  end
  self:UpdateButtonEnabled()
  return true
end

function SkillSlot:StartBlink()
  self.blinkTimer = 0
  self.blinkMask:SetTint(1, 1, 1, 0)
  self.blinkMask:Show()
end

function SkillSlot:StopBlink()
  self.blinkTimer = nil
  self.blinkMask:Hide()
end

function SkillSlot:UpdateLimitBar()
  if self.limitRemaining == nil then
    self.limitBarBg:Hide()
    self.limitBarFg:Hide()
    return
  end
  self.limitBarBg:Show()
  self.limitBarFg:Show()
  self.limitBarFg:SetSize(math.max(1, self.size * self.limitRemaining / self.limitTotal), 2)
end

function SkillSlot:RefreshUpdating()
  if self.tickingProgress or self.blinkTimer ~= nil or self.autoActivation.shown
    or (self.limitRemaining ~= nil and self.limitRemaining > 0) then
    self:StartUpdating()
  else
    self:StopUpdating()
  end
end

function SkillSlot:SyncSkillStatus(state, config)
  self.progress = nil
  self.total = nil
  self.tickingProgress = false
  self.limitRemaining = nil
  local level = state ~= nil and config ~= nil and config.levels[state.level] or nil
  if level == nil or state.id == "" or state.status == CONSTANTS.SKILL_STATUS.LOCKED then
    self.skillId = nil
    self.activationStacks = nil
    self.activationMode = config and config.activationMode or nil
    self.stacks:Hide()
    self:SetState("locked")
  else
    local stacks = state.activationStacks or 0
    if self.skillId == state.id and stacks > (self.activationStacks or 0) then
      self:StartBlink()
    elseif self.skillId ~= state.id then
      self:StopBlink()
    end
    self.skillId = state.id
    self.activationStacks = stacks
    self.activationMode = config.activationMode
    local maxStacks = level.maxActivationStacks or 1
    if maxStacks > 1 and stacks > 0 then
      self.stacksText:SetString(tostring(stacks))
      self.stacks:Show()
    else
      self.stacks:Hide()
    end
    if state.status == CONSTANTS.SKILL_STATUS.BUFFING then
      self.total = level.buffDuration
      self.progress = math.max(0, self.total - state.buffProgress)
      self.tickingProgress = self.progress > 0
      self:SetState("buff", self.progress, self.total)
    elseif state.status == CONSTANTS.SKILL_STATUS.BULLETING then
      self:SetState("bullet", state.bulletCount, level.bulletCount)
    elseif state.status == CONSTANTS.SKILL_STATUS.ENERGY_RECOVERING then
      if stacks < maxStacks then
        self.total = level.activationEnergy
        self.progress = math.min(self.total, state.energyProgress)
        self.tickingProgress = config.energyRecoveryMode == CONSTANTS.ENERGY_RECOVERY_MODE.AUTO
          and self.progress < self.total
      end
      self:SetState(stacks > 0 and "ready" or "charging", self.progress, self.total)
    else
      self:SetState("locked")
    end
    if state.isTemporary == 1 and state.limitTimeInitial > 0 then
      self.limitTotal = state.limitTimeInitial
      self.limitRemaining = math.max(0, math.min(self.limitTotal, state.limitRemaining))
    end
  end
  self:UpdateLimitBar()
  self:RefreshUpdating()
end

function SkillSlot:OnUpdate(dt)
  if TheNet:IsServerPaused() then
    return
  end
  if self.autoActivation.shown then
    self.autoActivation:SetRotation(self.autoActivation:GetRotation() - 360 * dt / 10)
  end
  if self.blinkTimer ~= nil then
    self.blinkTimer = self.blinkTimer + dt
    if self.blinkTimer >= BLINK_DURATION then
      self:StopBlink()
    else
      self.blinkMask:SetTint(1, 1, 1, math.sin(self.blinkTimer / BLINK_DURATION * math.pi) * 0.6)
    end
  end
  if self.tickingProgress then
    if self.state == "buff" then
      self.progress = math.max(0, self.progress - dt)
      self.tickingProgress = self.progress > 0
    else
      self.progress = math.min(self.total, self.progress + dt)
      self.tickingProgress = self.progress < self.total
    end
    self:SetState(self.state, self.progress, self.total)
  end
  if self.limitRemaining ~= nil and self.limitRemaining > 0 then
    self.limitRemaining = math.max(0, self.limitRemaining - dt)
    self:UpdateLimitBar()
  end
  self:RefreshUpdating()
end

return SkillSlot
