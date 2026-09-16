-- 凯尔希·思衡托（char_1052_kalts2）语音表。
-- 资源来自 PRTS 思衡托语音记录页；voice_lang 由 modmain 的配置选择。
local function Voice(path, zh_duration, jp_duration)
  return {
    zh = {
      path = "kaltsit_esperanta_voice_zh/kaltsit_esperanta/" .. path,
      duration = zh_duration,
    },
    jp = {
      path = "kaltsit_esperanta_voice_jp/kaltsit_esperanta/" .. path,
      duration = jp_duration,
    },
  }
end

return {
  KALTSIT_ESPERANTA_SKILL_1 = Voice("skill1", 1.489, 2.247),
  KALTSIT_ESPERANTA_SKILL_2 = Voice("skill2", 1.672, 1.776),
  KALTSIT_ESPERANTA_SKILL_3_A = Voice("skill3a", 2.116, 2.586),
  KALTSIT_ESPERANTA_SKILL_3_B = Voice("skill3b", 3.082, 3.997),
}
