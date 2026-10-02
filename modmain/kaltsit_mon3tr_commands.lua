-- 与玩家自身 ark_skill 使用不同 schema，五个代理插槽的 classified 索引独立。
DefineNetState("kaltsit_mon3tr_skill", {
  id = "string:classified",
  configPatch = "string:classified",
  status = "int:classified",
  level = "int:classified",
  energyProgress = "float:classified",
  buffProgress = "float:classified",
  bulletCount = "int:classified",
  activationStacks = "int:classified",
  isTemporary = "int:classified",
  limitTimeInitial = "float:classified",
  limitRemaining = "float:classified",
})

AddReplicableComponent("kaltsit_mon3tr_behavior")
AddReplicableComponent("kaltsit_mon3tr_master")

AddPlayerPostInit(function(inst)
  if TheWorld.ismastersim and inst.components.kaltsit_mon3tr_master == nil then
    inst:AddComponent("kaltsit_mon3tr_master")
  end
end)

AddModRPCHandler("kaltsit_esperanta", "mon3tr_set_mode", function(player, mode)
  local master = player ~= nil and player.components.kaltsit_mon3tr_master or nil
  if master ~= nil then
    master:SetMode(mode)
  end
end)

AddModRPCHandler("kaltsit_esperanta", "mon3tr_activate_skill", function(player, key)
  local master = player ~= nil and player.components.kaltsit_mon3tr_master or nil
  if master ~= nil then
    master:ActivateSkill(key)
  end
end)
