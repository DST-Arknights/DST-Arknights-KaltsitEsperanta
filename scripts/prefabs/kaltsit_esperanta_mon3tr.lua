local MakePlayerCharacter = require "prefabs/player_common"
local brain = require "brains/kaltsit_esperanta_mon3trbrain"

local prefabs = {
  "spawn_fx_medium_static",
}
local assets = {
  -- Asset("ATLAS", "images/map_icons/kaltsit_esperanta_mon3tr.xml"),
  Asset("ANIM", "anim/kaltsit_esperanta_mon3tr.zip"),
}

local start_inv = {}

local function IsPlayerControlled(inst)
  local userid = inst.Network:GetUserID()
  return userid ~= nil and userid ~= ""
end

local function UpdateBrain(inst)
  local brainfn = not IsPlayerControlled(inst) and brain or nil
  if inst.brainfn ~= brainfn then
    inst:SetBrain(brainfn)
  end
end

local function onbecameghost(inst)
  if not IsPlayerControlled(inst) then
    -- 原版在 ms_becameghost 返回后仍需访问 player_classified，下一帧再清理。
    inst:DoTaskInTime(0, function()
      if not IsPlayerControlled(inst) and inst:HasAnyTag("playerghost", "corpse") then
        local fx = SpawnPrefab("spawn_fx_medium_static")
        fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
        inst:Remove()
      end
    end)
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

  inst:AddComponent("follower")
  inst.components.follower:KeepLeaderOnAttacked()
  inst.components.follower.keepdeadleader = true

  inst:AddComponent("kaltsit_mon3tr_behavior")
  -- Network 的 owner 已更新时，userid 字段的 setowner 回调可能尚未执行。
  inst:ListenForEvent("setowner", UpdateBrain)
  UpdateBrain(inst)

  -- 灵魂状态变化
  inst:ListenForEvent("ms_becameghost", onbecameghost)
end

return MakePlayerCharacter("kaltsit_esperanta_mon3tr", prefabs, assets, CommonPostInit, MasterPostInit, start_inv)
