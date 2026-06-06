local function HasGun(inst)
  local equiped = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
  return equiped and equiped.prefab == "special_treatment_gun"
end
AddStategraphPostInit("wilson", function(sg)
  ArkHookFunction(sg.states["attack"], "onenter", function(next, inst, ...)
    if HasGun(inst) then
      inst.sg:GoToState("kaltsit_shoot")
      return
    end
    return next(inst, ...)
  end)
end)

AddStategraphState("wilson", State {
  name = "kaltsit_shoot",
  tags = { "attack", "notalking", "abouttoattack", "busy" },

  onenter = function(inst)
    if inst.components.rider:IsRiding() then
      inst.Transform:SetFourFaced()
    end
    local weapon = inst.components.combat:GetWeapon()
    if HasGun(inst) then
      inst.AnimState:PlayAnimation("kaltsit_hand_shoot")
    else
      inst.sg:GoToState("idle")
      return
    end

    if inst.components.combat.target then
      inst.components.combat:BattleCry()
      if inst.components.combat.target and inst.components.combat.target:IsValid() then
        inst:FacePoint(Point(inst.components.combat.target.Transform:GetWorldPosition()))
      end
    end
    inst.sg.statemem.target = inst.components.combat.target
    inst.components.combat:StartAttack()
    inst.components.locomotor:Stop()
  end,

  onexit = function(inst)
    if inst.components.rider:IsRiding() then
      inst.Transform:SetSixFaced()
    end
  end,

  timeline =
  {
    TimeEvent(17 * FRAMES, function(inst)
      inst.components.combat:DoAttack(inst.sg.statemem.target)
      inst.sg:RemoveStateTag("abouttoattack")
    end),
    TimeEvent(20 * FRAMES, function(inst)
      inst.sg:RemoveStateTag("attack")
    end),
  },

  events =
  {
    EventHandler("animover", function(inst)
      inst.sg:GoToState("idle")
    end),
  },
})
