local Widget = require "widgets/widget"
local Text = require "widgets/text"
local BorderWidget = require "widgets/border_widget"

local WIDTH = 400
local PADDING = 24
local GAP = 12

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

local CommandDesc = Class(Widget, function(self, title, description)
  Widget._ctor(self, "KaltsitMon3trCommandDesc")
  self:SetClickable(false)
  local bg = self:AddChild(BorderWidget(WIDTH, 0, {
    borderWidth = 2,
    borderColor = { 0.45, 0.45, 0.45, 0.9 },
    backgroundColor = { 0.23, 0.23, 0.23, 0.7 },
  }))
  bg:SetClickable(false)
  bg.borderImage:SetClickable(false)
  bg.innerImage:SetClickable(false)

  local name, nameHeight = AddText(self, title, 40, 2)
  local desc, descHeight = AddText(self, description, 32, 20)
  local height = PADDING * 2 + nameHeight + GAP + descHeight
  -- 底边锚定在原点，整张卡片向上展开。
  bg:SetSize(WIDTH, height)
  bg:SetPosition(0, height / 2, 0)
  name:SetPosition(0, height - PADDING - nameHeight / 2, 0)
  desc:SetPosition(0, PADDING + descHeight / 2, 0)
end)

function CommandDesc:GetWidth()
  return WIDTH
end

return CommandDesc
