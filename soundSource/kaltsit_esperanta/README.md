# 凯尔希·思衡托 技能音效源文件

来源：明日方舟 CN 解包 `解包0913`，角色内部代号 `char_1052_kalts2`
（音效名前缀 `khlrftcr`）。

## 编译目标

手动用 FMOD Designer 编译为本模组的：

- `sound/kaltsit_esperanta.fev`
- `sound/kaltsit_esperanta.fsb`

约定：

- FEV 事件组：`sfx`
- 事件名：当前目录 mp3 文件名去掉 `.mp3`
- 代码播放路径：`kaltsit_esperanta/sfx/<事件名>`

编译完成后重启游戏，`modmain.lua` 会直接加载音效包；发布模组时需同时带上这两个编译产物。

角色语音（CV）不在这个包里；后续按 `SayAndVoice` 机制单独接入。

## 命令行编译

本机 DST Mod Tools 自带 FMOD Designer 4.44.7：

```text
C:\Saved Games\Steam\steamapps\common\Don't Starve Mod Tools\mod_tools\FMOD_Designer\fmod_designercl.exe
```

先创建输出目录，然后在本目录执行：

```powershell
New-Item -ItemType Directory -Force "C:\Users\Tohsa\projects\DST-Arknights-KaltsitEsperanta\sound" | Out-Null

& "C:\Saved Games\Steam\steamapps\common\Don't Starve Mod Tools\mod_tools\FMOD_Designer\fmod_designercl.exe" `
  -pc `
  -b "C:\Users\Tohsa\projects\DST-Arknights-KaltsitEsperanta\sound" `
  "kaltsit_esperanta.fdp"
```

只检查输入/输出文件、不编译：

```powershell
& "C:\Saved Games\Steam\steamapps\common\Don't Starve Mod Tools\mod_tools\FMOD_Designer\fmod_designercl.exe" -pc -m kaltsit_esperanta.fdp
```

需要改事件、试听或调音量时，用同目录的 `fmod_designer.exe` 打开 `kaltsit_esperanta.fdp`。

## 已接入音效

| mp3 | 明日方舟原事件 | 用途 | 代码挂点 |
| --- | --- | --- | --- |
| `b_char_healboost.mp3` | `battle.ON_SKILL_START.skchr_kalts2_1` | 1技能开启（通用治疗/增益音效） | `modmain/kaltsit_esperanta_skill.lua` `OnSkill1Activate` |
| `p_skill_khlrftcr_h.mp3` | `battle.ON_SKILL_START.skchr_kalts2_2` | 2技能开启 | `OnSkill2Activate` |
| `p_skill_khlrftcr_s.mp3` | `battle.ON_SKILL_START.skchr_kalts2_3` | 3技能开启 | `OnSkill3Activate` |
| `p_skill_khlrftcrfd.mp3` | `battle.ON_BUFF_START.kalts2_respawn_range`（原游戏延迟 0.7 秒） | 3技能领域/复活范围展开 | `OnSkill3Activate`，延迟 0.7 秒播放 |
| `p_imp_khlrftcrmk.mp3` | `battle.ON_UNIT_BORN.token_10068_kalts2_mtship` | 3技能战术锚点召唤物出场 | `OnSkill3Activate`，生成 `tactical_anchor` 后 |
| `p_atk_khlrftcrdfr_h.mp3` | `battle.ON_ABILITY_ON.char_1052_kalts2.attack.4.1` | 2技能特殊弹发射 | `scripts/prefabs/special_treatment_gun.lua` `OnProjectileLaunched`（特殊弹就绪时） |
| `p_imp_khlrftcrd_h.mp3` | `battle.ON_PROJECTILE_REACH.projectile_chr_kalts2_s2_dmg` | 2技能特殊弹伤害命中 | `scripts/prefabs/special_treatment_bullet.lua` `MakeDestroyProjectileOnHit` |
| `p_imp_khlrftcrh_h.mp3` | `battle.ON_PROJECTILE_REACH.projectile_chr_kalts2_s2_heal` | 2技能特殊弹治疗命中 | 同上，实际治疗到友方时播放一次 |

## 暂未接入（待确认）

以下音效已在解包中确认属于 `char_1052_kalts2`，但和当前模组机制不是一一对应，先不强行接入：

| 音效 | 明日方舟事件 | 说明 |
| --- | --- | --- |
| `p_atk_khlrftcrfr_n.mp3` | `char_1052_kalts2.attack.0` | 普通远程攻击音效；当前模组是治疗枪，是否用于普通弹药待定 |
| `p_atk_khlrftcrfr_s.mp3` | `char_1052_kalts2.attack.1` | 1技能攻击音效；当前模组 1 技能只给 buff，没有攻击动作 |
| `p_atk_khlrftcrhfr_h.mp3` | `char_1052_kalts2.attack.4.2` | 2技能治疗弹发射；当前模组普通治疗弹和技能2特殊弹是两套机制，待定是否共用 |
| `p_atk_khlrftcrfls.mp3` / `p_imp_khlrftcrfls.mp3` | `char_1052_kalts2.T.-1` / `projectile_chr_kalts2_s3_2` | 3技能二段位移/传送相关候选；当前仍使用原版 `staff_blink` |
| `b_char_khlrftcr.mp3` | `battle.ON_UNIT_BORN.char_1052_kalts2` | 角色出场音效；不属于技能音效 |
| `b_char_boostclose.mp3` | `battle.ON_SKILL_SPECIAL_POINT.skchr_kalts2_2` | SP 特殊节点音效；当前模组没有对应机制 |

## 转码参数

使用 `C:\Users\Tohsa\freeapp\ffmpeg\bin\ffmpeg.exe` 转为：

- MP3 / 44100 Hz / 立体声 / 192 kbps
- 命令参数：`-vn -ar 44100 -ac 2 -c:a libmp3lame -b:a 192k -map_metadata -1`
