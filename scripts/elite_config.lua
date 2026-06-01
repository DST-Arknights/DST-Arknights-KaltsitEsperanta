local config = {
  {
    healthBonus = 0,
    hungerBonus = 0,
    sanityBonus = 0,
    mon3trHealthBonus = 0,
    mon3trAttackBonus = 0,
  }, {
    healthBonus = 20,
    hungerBonus = 20,
    sanityBonus = 20,
    mon3trHealthBonus = 100,
    mon3trAttackBonus = 10,
  }, {
    healthBonus = 50,
    hungerBonus = 50,
    sanityBonus = 50,
    mon3trHealthBonus = 100,
    mon3trAttackBonus = 10,
  }
}
local function Get(elite_level)
  elite_level = math.clamp(elite_level, 1, #config)
  return config[elite_level]
end

return {
  Get = Get,
  config = config
}
