local Widget = require "widgets/widget"
local Text = require "widgets/text"
local ImageButton = require "widgets/imagebutton"
local TextButton = require "widgets/textbutton"
local BorderWidget = require "widgets/border_widget"

local WIDTH = 400
local PADDING = 24
local GAP = 12
local HOTKEY_FONT_SIZE = 32

local function AddText(parent, value, fontSize, maxLines)
  local text = parent:AddChild(Text(FALLBACK_FONT_FULL, fontSize, ""))
  text:SetClickable(false)
  local lines = text:SetMultilineTruncatedString(value, maxLines, WIDTH - PADDING * 2,
    nil, true, true, fontSize)
  local height = math.max(1, lines or 1) * fontSize
  text:SetRegionSize(WIDTH - PADDING * 2, height)
  text:SetHAlign(ANCHOR_LEFT)
  text:SetVAlign(ANCHOR_TOP)
  return text, height
end

local CommandDesc = Class(Widget, function(self, title, description, modeMaster)
  Widget._ctor(self, "KaltsitMon3trCommandDesc")
  self.modeMaster = modeMaster
  local interactive = modeMaster ~= nil
  self:SetClickable(interactive)
  if interactive then
    self.hoverFocusProxy = self:AddChild(ImageButton("images/ui.xml", "blank.tex", "blank.tex", "blank.tex",
      nil, nil, { 1, 1 }, { 0, 0 }))
    self.hoverFocusProxy:SetClickable(true)
    self.hoverFocusProxy:SetControl(CONTROL_PRIMARY)
    self.hoverFocusProxy.scale_on_focus = false
    self.hoverFocusProxy.move_on_click = false
  end
  local bg = self:AddChild(BorderWidget(WIDTH, 0, {
    borderWidth = 2,
    borderColor = { 0.45, 0.45, 0.45, 0.9 },
    backgroundColor = { 0.23, 0.23, 0.23, 0.7 },
  }))
  bg:SetClickable(false)
  -- 由底层透明代理接住空白区域焦点，装饰背景不参与命中。
  bg.borderImage:SetClickable(false)
  bg.innerImage:SetClickable(false)

  local name, nameHeight = AddText(self, title, 40, 2)
  local desc, descHeight = AddText(self, description, 32, 20)
  name:SetClickable(false)
  desc:SetClickable(false)
  local footerHeight = 0
  if interactive then
    self:CreateHotKeyFooter()
    footerHeight = GAP + HOTKEY_FONT_SIZE
  end
  local height = PADDING * 2 + nameHeight + GAP + descHeight + footerHeight
  -- 底边锚定在原点，整张卡片向上展开。
  bg:SetSize(WIDTH, height)
  bg:SetPosition(0, height / 2, 0)
  if self.hoverFocusProxy ~= nil then
    self.hoverFocusProxy:ForceImageSize(WIDTH, height)
    self.hoverFocusProxy:SetPosition(0, height / 2, 0)
    self.hoverFocusProxy:MoveToBack()
  end
  name:SetPosition(0, height - PADDING - nameHeight / 2, 0)
  desc:SetPosition(0, PADDING + footerHeight + descHeight / 2, 0)
end)

function CommandDesc:CreateHotKeyFooter()
  local foot = self:AddChild(Widget("mode_hotkey"))
  foot:SetPosition(0, PADDING + HOTKEY_FONT_SIZE / 2, 0)
  local strings = STRINGS.UI.ARK_SKILL
  local function AddButton(name, label, onClick)
    local button = foot:AddChild(TextButton(name))
    button:SetClickable(true)
    button:SetFont(FALLBACK_FONT_FULL)
    button:SetTextSize(HOTKEY_FONT_SIZE)
    button:SetText(label)
    button:SetOnClick(onClick)
    return button
  end
  local reset = AddButton("hotkeyReset", "[" .. strings.RESET .. "]", function()
    self:CancelSettingHotKey()
    self.modeMaster:RestoreDefaultModeHotkey()
    self:RefreshHotKey()
  end)
  self.hotKeyButton = AddButton("hotkeySetting", "[" .. strings.SETTING .. "]", function() self:SettingHotKey() end)
  self.cancelHotkeyButton = AddButton("cancelHotkey", strings.CANCEL, function() self:CancelSettingHotKey() end)
  self.cancelHotkeyButton:Hide()
  local rightEdge = WIDTH / 2 - PADDING
  local resetWidth = select(1, reset:GetSize())
  local settingWidth = math.max(select(1, self.hotKeyButton:GetSize()), select(1, self.cancelHotkeyButton:GetSize()))
  reset:SetPosition(rightEdge - resetWidth / 2, 0, 0)
  local buttonGap = 8
  local textGap = 8
  local settingX = rightEdge - resetWidth - buttonGap - settingWidth / 2
  self.hotKeyButton:SetPosition(settingX, 0, 0)
  self.cancelHotkeyButton:SetPosition(settingX, 0, 0)
  local buttonGroupLeft = rightEdge - resetWidth - buttonGap - settingWidth
  local textLeft = -WIDTH / 2 + PADDING
  self.hotKeyTextWidth = math.max(1, buttonGroupLeft - textGap - textLeft)
  self.hotKeyText = foot:AddChild(Text(FALLBACK_FONT_FULL, HOTKEY_FONT_SIZE, ""))
  self.hotKeyText:SetClickable(false)
  self.hotKeyText:SetPosition(textLeft + self.hotKeyTextWidth / 2, 0, 0)
  -- 文字右缘靠近设置按钮，与按钮组保持 8 像素间距。
  self.hotKeyText:SetHAlign(ANCHOR_RIGHT)
  self:RefreshHotKey()
end

function CommandDesc:SetHotKeyText(value)
  -- 截断依赖自动测量字宽；固定 RegionSize 会让截断循环的宽度无法缩小。
  self.hotKeyText:ResetRegionSize()
  self.hotKeyText:SetTruncatedString(value, self.hotKeyTextWidth)
  self.hotKeyText:SetRegionSize(self.hotKeyTextWidth, HOTKEY_FONT_SIZE)
end

function CommandDesc:RefreshHotKey()
  if self.hotKeyText == nil then
    return
  end
  local key = self.modeMaster:GetModeHotkey()
  local keyName = key ~= nil and (STRINGS.UI.CONTROLSSCREEN.INPUTS[1][key] or tostring(key))
    or STRINGS.UI.ARK_SKILL.NONE
  local label = STRINGS.UI.KALTSIT_MON3TR_MODE.HOTKEY_LABEL or STRINGS.UI.ARK_SKILL.HOT_KEY
  self:SetHotKeyText(label .. ": " .. keyName)
  local conflict = key ~= nil and GetHotKeyManager(self.modeMaster.inst):GetHotkeyHandlerCount(key) > 1
  self.hotKeyText:SetColour(1, conflict and 0.2 or 1, conflict and 0.2 or 1, 1)
end

function CommandDesc:SettingHotKey()
  if self._onKey ~= nil or self._settingHotKeyTask ~= nil then
    return
  end
  -- 等当前鼠标控件分发结束，再隐藏被点击的按钮并启动按键捕获。
  self._settingHotKeyTask = self.inst:DoTaskInTime(0, function()
    self._settingHotKeyTask = nil
    if self:IsVisible() then
      self:BeginSettingHotKey()
    end
  end)
end

function CommandDesc:BeginSettingHotKey()
  -- Hide() 不会清除 Widget 焦点，隐藏前先移除，避免焦点留在不可见按钮上。
  self.hotKeyButton:ClearFocus()
  self.cancelHotkeyButton:Show()
  self.hotKeyButton:Hide()
  self:SetHotKeyText(STRINGS.UI.ARK_SKILL.PRESS_ANY_KEY)
  local manager = GetHotKeyManager(self.modeMaster.inst)
  self._onKey = function(key, down)
    if down then
      local listener = self._onKey
      self._onKey = nil
      -- 先注销监听再更新状态，避免回调异常后残留监听吞掉后续键盘输入。
      manager:CancelListenOnce(listener)
      self.cancelHotkeyButton:ClearFocus()
      self.cancelHotkeyButton:Hide()
      self.hotKeyButton:Show()
      local ok, err = pcall(function()
        self.modeMaster:SetModeHotkey(key)
        self:RefreshHotKey()
      end)
      if not ok then
        print("[Kaltsit Mon3tr] Failed to set mode hotkey:", err)
      end
      -- 已手动注销；返回 false，避免分发器误删队列中的下一个监听。
      return false
    end
  end
  manager:ListenOnce(self._onKey)
end

function CommandDesc:CancelSettingHotKey()
  if self._settingHotKeyTask ~= nil then
    self._settingHotKeyTask:Cancel()
    self._settingHotKeyTask = nil
  end
  if self._onKey ~= nil then
    local manager = GetHotKeyManager(self.modeMaster.inst)
    manager:CancelListenOnce(self._onKey)
    self._onKey = nil
    self.cancelHotkeyButton:ClearFocus()
    self.cancelHotkeyButton:Hide()
    self.hotKeyButton:Show()
    self:RefreshHotKey()
  end
end

function CommandDesc:OnHide()
  self:CancelSettingHotKey()
end

function CommandDesc:Kill()
  self:CancelSettingHotKey()
  CommandDesc._base.Kill(self)
end

function CommandDesc:GetWidth()
  return WIDTH
end

function CommandDesc:OnControl(control, down)
  if CommandDesc._base.OnControl(self, control, down) then
    return true
  end
  -- 悬浮卡片只拦截鼠标左键空白点击，不吞掉键盘与手柄控制。
  return self.modeMaster ~= nil and self.focus and control == CONTROL_ACCEPT and TheFrontEnd.isprimary
end

return CommandDesc
