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
