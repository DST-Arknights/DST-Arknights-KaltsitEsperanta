-- 生命修复单元的可投喂强化材料
-- 每个材料只能喂一次(stage[prefab] 置 1), 喂后按 stage 全量重算装备增益
-- 字段含义:
--   absorb            物理防御加成(小数, 0.05 = +5%)
--   planardefense     位面防御
--   walkspeed         移速加成(乘数, 0.05 = +5%)
--   fireproof         防火(fireimmune tag, 穿在身上时给穿戴者)
--   waterproof        防水
--   lightningproof    防雷
--   summerinsulation  夏季隔热
--   winterinsulation  冬季保暖
--   glow              发光(魔光护符同款)
--   infinitestack     容器无限堆叠(参考龙鳞箱 EnableInfiniteStackSize)
--   slots             目标格数(格子扩张需自定义 widget, 暂未接入)
local materials = {
  { prefab = "armorruins",       absorb = 0.05 },
  { prefab = "armor_lunarplant", absorb = 0.05, planardefense = 5 },
  { prefab = "armor_wagpunk",    walkspeed = 0.05, planardefense = 5 },

  { prefab = "armor_dragonfly",  fireproof = true },
  { prefab = "raincoat",         waterproof = true, lightningproof = true },
  { prefab = "hawaiianshirt",    summerinsulation = 240 },
  { prefab = "trunkvest_winter",        winterinsulation = 240 },
  { prefab = "beargervest",      winterinsulation = 240 },
  { prefab = "yellowamulet",     glow = true },

  -- 容器升级(切斯特式格子扩张, 升级即切换容器定义)
  { prefab = "armorslurper",       slots = 14 },                              -- 饥饿腰带
  { prefab = "chestupgrade_stacksize", slots = 16, infinitestack = true },    -- 弹性制造器
}

return materials
