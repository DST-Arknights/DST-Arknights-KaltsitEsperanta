local Widget = require "widgets/widget"
local Image = require "widgets/image"

-- 只负责显示；本阶段不注册技能、不发送技能 RPC、不虚构充能或 buff 数据。
local SkillSlot = Class(Widget, function(self, atlas, texture, size)
  Widget._ctor(self, "KaltsitMon3trSkillSlot")
  self.size = size
  self.icon = self:AddChild(Image(atlas, texture))
  self.icon:SetSize(size, size)
  -- 保留 HUD 命中，避免点击尚未接入的技能图标时穿透到世界。
  self.icon:SetClickable(true)

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

-- charging: current 为当前能量；buff: current 为剩余秒数；total 为各自总量。
-- ready / charging / buff / locked 是显示状态，留给后续 ark_skill 数据接入。
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
  return true
end

return SkillSlot
