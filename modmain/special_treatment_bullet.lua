local builder_tag = "kaltsit_esperanta"
-- 普通治疗弹 	可以恢复10血，
-- 一次制作10个。	①	15蜘蛛腺体＋1金子
-- ②	5蝴蝶翅膀＋1金子
-- ③	10鸟蛋＋1金子
AddCharacterRecipe("norm_heal_bullet1", {
  Ingredient("spider_gland", 15),
  Ingredient("goldnugget", 1)
}, TECH.NONE, {
  builder_tag = builder_tag,
  numtogive = 10,
  product = "norm_heal_bullet",
  nameoverride = "norm_heal_bullet",
})

AddCharacterRecipe("norm_heal_bullet2", {
  Ingredient("butterfly_wing", 5),
  Ingredient("goldnugget", 1)
}, TECH.NONE, {
  builder_tag = builder_tag,
  numtogive = 10,
  product = "norm_heal_bullet",
  nameoverride = "norm_heal_bullet",

})

AddCharacterRecipe("norm_heal_bullet3", {
  Ingredient("bird_egg", 10),
  Ingredient("goldnugget", 1)
}, TECH.NONE, {
  builder_tag = builder_tag,
  numtogive = 10,
  product = "norm_heal_bullet",
  nameoverride = "norm_heal_bullet",
})

-- 特制治疗弹 	可以恢复20血
-- 且使目标温度重置至20度。
-- 一次制作10个	①	10番茄＋1金子
-- ②	10石榴＋1金子
AddCharacterRecipe("trait_heal_bullet", {
  Ingredient("tomato", 10),
  Ingredient("goldnugget", 1)
}, TECH.NONE, {
  builder_tag = builder_tag,
  numtogive = 10,
})

AddCharacterRecipe("trait_heal_bullet", {
  Ingredient("pomegranate", 10),
  Ingredient("goldnugget", 1)
}, TECH.NONE, {
  builder_tag = builder_tag,
  numtogive = 10,
})

-- 强效治疗弹 	在4秒内每秒恢复5血及血上限，
-- 可以回黑血，效果可叠加
-- 一次制作5个	①	10红蘑菇＋1金子
-- ②	10蜂蜜＋1金子，
-- ③	10蚊子血囊＋1金子
AddCharacterRecipe("potent_heal_bullet", {
  Ingredient("red_mushroom", 10),
  Ingredient("goldnugget", 1)
}, TECH.NONE, {
  builder_tag = builder_tag,
  numtogive = 5,
})

AddCharacterRecipe("potent_heal_bullet", {
  Ingredient("honey", 10),
  Ingredient("goldnugget", 1)
}, TECH.NONE, {
  builder_tag = builder_tag,
  numtogive = 5,
})

AddCharacterRecipe("potent_heal_bullet", {
  Ingredient("mosquito_blood_sac", 10),
  Ingredient("goldnugget", 1)
}, TECH.NONE, {
  builder_tag = builder_tag,
  numtogive = 5,
})

-- 缓回治疗弹
-- 	在 2 分钟内每 2 秒恢复 2血
-- 共恢复120血，效果可叠加
-- 持续时间内免疫减速与免疫昏睡
-- 一次制作5个	①	1蜂王浆＋1金子
-- ②	5高鸟蛋＋1金子
-- ③	10月娥翅膀＋1金子
AddCharacterRecipe("regen_heal_bullet", {
  Ingredient("royal_jelly", 1),
  Ingredient("goldnugget", 1)
}, TECH.NONE, {
  builder_tag = builder_tag,
  numtogive = 5,
})

AddCharacterRecipe("regen_heal_bullet", {
  Ingredient("high_bird_egg", 5),
  Ingredient("goldnugget", 1)
}, TECH.NONE, {
  builder_tag = builder_tag,
  numtogive = 5,
})

AddCharacterRecipe("regen_heal_bullet", {
  Ingredient("moonmoth_wing", 10),
  Ingredient("goldnugget", 1)
}, TECH.NONE, {
  builder_tag = builder_tag,
  numtogive = 5,
})
