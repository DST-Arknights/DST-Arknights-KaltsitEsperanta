table.insert(Assets, Asset("ATLAS", "images/ui_kaltsit_experanta_mon3tr_skill.xml"))
table.insert(Assets, Asset("IMAGE", "images/ui_kaltsit_experanta_mon3tr_skill.tex"))
table.insert(Assets, Asset("ANIM", "anim/m3_ui_active_overlay.zip"))

if not TheNet:IsDedicated() then
  local Mon3trUI = require "widgets/kaltsit_mon3tr_ui"
  AddClassPostConstruct("widgets/controls", function(self)
    -- 主人 replica 决定是否显示；不依赖主人角色或客机宠物实体。
    self.kaltsitMon3trUi = self.inv.root:AddChild(Mon3trUI(self.owner, self))
  end)
end
