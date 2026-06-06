local MakePlayerCharacter = require "prefabs/player_common"

local prefabs = {}
local assets = {
  -- Asset("ATLAS", "images/map_icons/kaltsit_esperanta_mon3tr.xml"),
  Asset("ANIM", "anim/kaltsit_esperanta_mon3tr.zip"),
}

local start_inv = {}

local function onbecameghost(inst)
  if not IsPlayerControlling(inst) then
    inst:Remove()
  end
end

local function CommonPostInit(inst)
  -- Minimap icon
  inst.MiniMapEntity:SetIcon("kaltsit_esperanta_mon3tr.tex")
end

local function MasterPostInit(inst)
  -- inst.soundsname = "wilson"
  -- inst.talker_path_override = "dontstarve_DLC001/characters/kaltsit_esperanta/"

  -- 角色属性
  inst.components.health:SetMaxHealth(TUNING.KALTSIT_ESPERANTA_MON3TR_HEALTH)
  inst.components.hunger:SetMax(TUNING.KALTSIT_ESPERANTA_MON3TR_HUNGER)
  inst.components.hunger.burnratemodifiers:SetModifier("kaltsit_esperanta_mon3tr", -200)
  inst.components.sanity:SetMax(TUNING.KALTSIT_ESPERANTA_MON3TR_SANITY)
  inst.components.sanity.externalmodifiers:SetModifier("kaltsit_esperanta_mon3tr", 200)

  -- Mon3tr 技能指令管理
  inst:AddComponent("kaltsit_mon3tr_skills")
  inst:AddComponent("spellbookcooldowns")

  -- 灵魂状态变化
  inst:ListenForEvent("becameghost", onbecameghost)
end

return MakePlayerCharacter("kaltsit_esperanta_mon3tr", prefabs, assets, CommonPostInit, MasterPostInit, start_inv)
