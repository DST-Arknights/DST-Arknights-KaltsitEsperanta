local Badge = require("widgets/badge")

table.insert(Assets, Asset("ANIM", "anim/kaltsit_intellect_badge.zip"))

AddCharacterIngredient("kaltsit_intellect", {
  Has = function(inst, amount)
    local replica = inst.replica.kaltsit_intellect
    local current = replica and replica.state.current or 0
    return current >= amount, current
  end,
  Consume = function(inst, amount)
    if inst.components.kaltsit_intellect then
      inst.components.kaltsit_intellect:Delta(-amount)
    end
  end,
})

RegisterArkBadge("kaltsit_intellect_badge", function(manager, owner)
  if not owner:HasTag("kaltsit_esperanta") then
    return nil
  end
  local badge = Badge(nil, owner, nil, "kaltsit_intellect_badge")
  return badge
end)