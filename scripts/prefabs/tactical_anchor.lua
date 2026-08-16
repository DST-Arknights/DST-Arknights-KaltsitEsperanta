local PlayerProx = require "components/playerprox"

local assets =
{
  Asset("ANIM", "anim/tactical_anchor.zip"),
}
local prefabs =
{
  "tactical_anchor_range",
}
local function fn()
  local inst = CreateEntity()

  inst.entity:AddTransform()
  inst.entity:AddAnimState()
  inst.entity:AddNetwork()

  inst.AnimState:SetBank("tactical_anchor")
  inst.AnimState:SetBuild("tactical_anchor")
  inst.AnimState:PlayAnimation("idle", true)
  inst.AnimState:SetScale(3, 3, 3)
  inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
  inst.entity:SetPristine()
  if not TheWorld.ismastersim then
    return inst
  end
  inst:AddComponent("inspectable")
  inst:AddComponent("tactical_anchor")
  inst:AddTag("reviver") -- 复活来源判定：source 带此 tag 时走原地复活

  -- 领域：playerprox 直接挂在实体上（不套组件），追踪 20 距离内进出领域的玩家，
  -- 进挂领域 buff，出移除。强度由技能放置时经 SetFieldParams 传入组件。
  local ta = inst.components.tactical_anchor
  inst:AddComponent("playerprox")
  inst.components.playerprox:SetDist(20, 21)
  -- AllPlayers：onnear/onfar 都以 player 为参数回调；默认 AnyPlayer 的 onfar 不带 player
  inst.components.playerprox:SetTargetMode(PlayerProx.TargetModes.AllPlayers)
  inst.components.playerprox:SetPlayerAliveMode(PlayerProx.AliveModes.AliveOnly)
  inst.components.playerprox:SetOnPlayerNear(function(_, player)
    if player ~= nil and not player:HasTag("playerghost") then
      -- 施术者（锚点）经 AddDebuff 第 6 参 buffer 传入，data 只放纯数据（领域强度）
      player:AddDebuff("kaltsit_anchor_field_buff", "kaltsit_anchor_field_buff", { field = ta._fieldParams }, nil, nil, inst)
    end
  end)
  inst.components.playerprox:SetOnPlayerFar(function(_, player)
    if player ~= nil and player:IsValid() then
      player:RemoveDebuff("kaltsit_anchor_field_buff")
    end
  end)
  inst:DoTaskInTime(0, function()
    local range_fx = SpawnPrefab("tactical_anchor_range")
    range_fx.entity:SetParent(inst.entity)
  end)
  -- inst.persists = false
  return inst
end
return Prefab("tactical_anchor", fn, assets, prefabs)
