local Widget = require "widgets/widget"
local Image = require "widgets/image"
local ImageButton = require "widgets/imagebutton"
local UIAnim = require "widgets/uianim"
local SkillSlot = require "widgets/kaltsit_mon3tr_skill_slot"
local layout = require "kaltsit_mon3tr_ui_config"
local skillConfig = require "kaltsit_mon3tr_skill_config"

local MODES = { "standby", "attack", "work" }
local SKILLS = skillConfig.skills

local Mon3trUI = Class(Widget, function(self, owner, controls)
  Widget._ctor(self, "KaltsitMon3trUI")
  self.owner = owner
  self.controls = controls
  self.hooks = {}
  self.modeButtons = {}
  self.skillSlots = {}
  self.hasMon3tr = false

  self.clip = self:AddChild(Widget("mon3tr_clip"))
  self.clip:SetPosition(layout.bg_width / 2, 0, 0)
  local padding = layout.clip_padding
  self.clip:SetScissor(-layout.bg_width / 2 - padding, -layout.bg_height / 2 - padding,
    layout.bg_width + padding * 2, layout.bg_height + padding * 2)
  self.content = self.clip:AddChild(Widget("mon3tr_content"))
  self.hiddenY = -(layout.bg_height + padding * 2 + layout.slide_margin)
  self.content:SetPosition(0, self.hiddenY, 0)
  self.bg = self.content:AddChild(Image(layout.atlas, "bg.tex"))
  self.bg:SetSize(layout.bg_width, layout.bg_height)
  self.bg:SetClickable(false)

  local size = layout.icon_size
  local modeWidth = #MODES * size + (#MODES - 1) * layout.mode_gap
  local skillWidth = #SKILLS * size + (#SKILLS - 1) * layout.skill_gap
  local startX = -(modeWidth + layout.group_gap + skillWidth) / 2 + size / 2 + layout.row_x
  self.modeGroup = self.content:AddChild(Widget("mon3tr_modes"))
  self.modeGroup:SetPosition(startX, layout.row_y, 0)
  self.skillGroup = self.content:AddChild(Widget("mon3tr_skills"))
  self.skillGroup:SetPosition(startX + modeWidth + layout.group_gap, layout.row_y, 0)

  for index, mode in ipairs(MODES) do
    local button = self.modeGroup:AddChild(ImageButton(layout.atlas, mode .. ".tex"))
    button.scale_on_focus = false
    button.move_on_click = false
    button:ForceImageSize(size, size)
    button:SetPosition((index - 1) * (size + layout.mode_gap), 0, 0)
    button:SetOnClick(function()
      local master = self.owner.replica.kaltsit_mon3tr_master
      if master ~= nil and self.hasMon3tr and not self.sliding and self:IsVisible() then
        master:RequestMode(mode)
      end
    end)
    self.modeButtons[mode] = button
  end

  for index, skill in ipairs(SKILLS) do
    local slot = self.skillGroup:AddChild(SkillSlot(layout.atlas, skill.key .. ".tex", size))
    slot:SetPosition((index - 1) * (size + layout.skill_gap), 0, 0)
    slot:SetOnClick(function()
      local master = self.owner.replica.kaltsit_mon3tr_master
      if master ~= nil and self.hasMon3tr and not self.sliding and self:IsVisible() then
        master:RequestSkill(skill.key)
      end
    end)
    self.skillSlots[skill.key] = slot
  end

  self.activeFrame = self.modeGroup:AddChild(UIAnim())
  self.activeFrame:SetClickable(false)
  self.activeFrame:SetScale(layout.overlay_size / 192)
  local anim = self.activeFrame:GetAnimState()
  anim:SetBank("m3_ui_active_overlay")
  anim:SetBuild("m3_ui_active_overlay")
  anim:PlayAnimation("loop", true)
  self.activeFrame:Hide()
  self:SetCommandsEnabled(false)
  self:Hide()

  self.onMasterDirty = function() self:RefreshMaster() end
  self.inst:ListenForEvent("kaltsit_mon3tr_masterdirty", self.onMasterDirty, owner)
  self.onMasterSkillDirty = function(_, data) self:RefreshSkills(data ~= nil and data.index or nil) end
  self.inst:ListenForEvent("kaltsit_mon3tr_masterskilldirty", self.onMasterSkillDirty, owner)
  self:HookLayout(controls.inv, "Rebuild")
  local extend = controls.arkExtendUi
  if extend ~= nil then
    self:HookLayout(extend, "UpdateLayout")
    self:HookLayout(extend, "Show")
    self:HookLayout(extend, "Hide")
    if extend.buffIcons ~= nil then
      self:HookLayout(extend.buffIcons, "_UpdateLayout")
    end
  end
  self:HookLayout(controls, "ShowCraftingAndInventory")
  self:HookLayout(controls, "HideCraftingAndInventory")
  self:UpdatePosition()
  self:RefreshMaster()
  self:RefreshSkills()
end)

function Mon3trUI:HookLayout(object, method)
  local hook = function(next, ...)
    next(...)
    self:UpdatePosition()
    self:SetCommandsEnabled(self.hasMon3tr and not self.sliding and self:IsVisible())
  end
  ArkHookFunction(object, method, hook)
  table.insert(self.hooks, { object = object, method = method, fn = hook })
end

function Mon3trUI:SetCommandsEnabled(enabled)
  if not enabled then
    self:ClearFocus()
  end
  for _, button in pairs(self.modeButtons) do
    if enabled then
      button:Enable()
    else
      button:Disable()
    end
  end
  for _, skill in ipairs(SKILLS) do
    self.skillSlots[skill.key]:SetCommandEnabled(enabled and skill.implemented == true)
  end
end

-- 同属 inv.root，位置与尺寸都使用本地坐标，不重复乘库存/HUD缩放。
function Mon3trUI:UpdatePosition()
  local extend = self.controls.arkExtendUi
  local handBase = extend and extend.handBase
  local handScale = handBase and select(1, handBase:GetLooseScale()) or TUNING.ARK_CONFIG.hand_base_scale
  local scale = layout.scale * handScale
  self:SetScale(scale)
  local rowY = self.controls.inv.toprow and self.controls.inv.toprow:GetPosition().y or 0
  local x = layout.fallback_x
  local y = rowY + layout.fallback_y * handScale
  local topY
  if handBase ~= nil and handBase.shown then
    for _, key in ipairs({ "elite", "skills", "talents", "expBar" }) do
      local widget = extend[key]
      if widget ~= nil and widget.shown and widget.GetSize ~= nil then
        local width, height = widget:GetSize()
        if width > 0 and height > 0 then
          local widgetTop = widget:GetPosition().y + height * select(2, widget:GetLooseScale()) / 2
          topY = math.max(topY or widgetTop, widgetTop)
        end
      end
    end
    if extend.buffIcons ~= nil and #extend.buffIcons.groupOrder > 0 then
      local buffTop = extend.buffIcons:GetPosition().y + 16
      topY = math.max(topY or buffTop, buffTop)
    end
    if topY ~= nil then
      local pos = handBase:GetPosition()
      x = pos.x
      y = pos.y + (topY + layout.above_gap) * handScale + layout.bg_height * scale / 2
    end
  end
  self:SetPosition(x + layout.offset_x * handScale, y + layout.offset_y * handScale, 0)
end

function Mon3trUI:SetMode(mode, smooth)
  local button = self.modeButtons[mode]
  if button == nil or self.mode == mode then
    return
  end
  self.mode = mode
  local pos = button:GetPosition()
  local target = Vector3(pos.x + layout.overlay_x, pos.y + layout.overlay_y, 0)
  self.activeFrame:CancelMoveTo()
  if smooth and self.activeFrame.shown then
    self.activeFrame:MoveTo(self.activeFrame:GetPosition(), target, layout.overlay_move_time)
  else
    self.activeFrame:SetPosition(target)
  end
  self.activeFrame:Show()
end

function Mon3trUI:RefreshMaster()
  local master = self.owner.replica.kaltsit_mon3tr_master
  local visible = master ~= nil and master:HasMon3tr()
  if visible then
    self:SetMode(master:GetMode(), self.hasMon3tr)
  end
  if visible == self.hasMon3tr then
    return
  end
  self.hasMon3tr = visible
  self:RefreshSkills()
  self:SetCommandsEnabled(false)
  self.sliding = true
  self.content:CancelMoveTo()
  self:Show()
  self:UpdatePosition()
  self.content:MoveTo(self.content:GetPosition(), Vector3(0, visible and 0 or self.hiddenY, 0),
    layout.slide_time, function()
      self.sliding = false
      if self.hasMon3tr then
        self:SetCommandsEnabled(self:IsVisible())
      else
        self:Hide()
        self.activeFrame:Hide()
        self.mode = nil
      end
    end)
end

function Mon3trUI:RefreshSkills(index)
  local master = self.owner.replica.kaltsit_mon3tr_master
  for i, skill in ipairs(SKILLS) do
    if index == nil or index == i then
      local state = master ~= nil and master:HasMon3tr() and master:GetSkillState(i) or nil
      self.skillSlots[skill.key]:SyncSkillStatus(state, GetArkSkillConfigById(skill.id))
    end
  end
end

function Mon3trUI:SetSkillState(skill, state, current, total)
  local slot = self.skillSlots[skill]
  return slot ~= nil and slot:SetState(state, current, total) or false
end

function Mon3trUI:Kill()
  self.content:CancelMoveTo()
  self.activeFrame:CancelMoveTo()
  self.inst:RemoveEventCallback("kaltsit_mon3tr_masterdirty", self.onMasterDirty, self.owner)
  self.inst:RemoveEventCallback("kaltsit_mon3tr_masterskilldirty", self.onMasterSkillDirty, self.owner)
  for _, hook in ipairs(self.hooks) do
    ArkUnhookFunction(hook.object, hook.method, hook.fn)
  end
  Mon3trUI._base.Kill(self)
end

return Mon3trUI
