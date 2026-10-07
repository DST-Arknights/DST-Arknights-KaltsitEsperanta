# 版本更新记录

## v2.0.2 (2026-10-08)

- Mon3tr 主动回收时会优先将物品转交 Kal'tsit，支持库存、背包和堆叠；容量不足的部分直接掉落，且不占用鼠标物品。转交时保留原版锁槽与诅咒限制。
- Mon3tr 死亡回收、主人处于灵魂或尸体状态时仍直接掉落；技能回收会先处理剩余库存，避免物品随实体删除而消失。
- 调整 SkillSlot 的透明度，优化视觉效果。
---
- Active recall now prioritizes transferring Mon3tr's items to Kal'tsit, supporting inventory, backpacks, and stacks; overflow drops directly and does not occupy the mouse cursor. Transfers preserve vanilla locked-slot and curse restrictions.
- Mon3tr death recall and cases where the owner is in soul or corpse states still drop items directly; skill recalls handle leftover inventory before entity removal so items do not vanish with Mon3tr.
- Adjusted SkillSlot transparency for improved visuals.

## v2.0.1 (2026-10-03)

- 优化 Mon3tr 的饥饿管理，使其在 AI 状态下也会保持饥饿暂停。
---
- Improved Mon3tr's hunger management so it stays hunger-paused while under AI control.

本项目的所有重要变更。

## v2.0.0 (2026-10-03)

- Mon3tr 系统大幅更新：新增/同步技能、技能槽 UI、召唤技能、assault 技能、intimidation waves、AI 爪击、master command、工作模式与物品收集交付，并完善 Kal'tsit 行为与大脑逻辑；同时调整饥饿/死亡/幽灵处理、基础属性、180 秒冷却、召唤理智、召唤回收与 Kal'tsit 治疗交互及跳跃动作表现。
- 移除 Mon3tr 组件及相关功能，包括 Kaltsit Calcite 配方/命令与相关本地化文本。
- 治疗枪支持右键自疗并防止弹药自伤，限制破坏目标的循环次数，并优化科技判定。
- 关闭调试解锁并锁定未实现技能；更新中英文文案、技能栏遮罩、技能状态显示、模式和技能描述及 UI 交互。
- 调整声音播放优先级与距离，并简化配置选项描述。
---
- Mon3tr systems received major updates: added/synced skills, skill slot UI, summon skill, assault skill, intimidation waves, AI claw attacks, master command, work modes, and item collection/delivery, plus improved Kal'tsit behavior and brain logic; also adjusted hunger/death/ghost handling, base stats, 180-second cooldown, summon sanity, summon/recycle interaction with Kal'tsit healing, and jump animation presentation.
- Removed Mon3tr components and related functionality, including Kaltsit Calcite recipes/commands and related localization text.
- Healing gun now supports right-click self-healing and prevents ammo self-damage, limits destruction target loops, and improves tech checks.
- Disabled debug unlocks and locked unimplemented skills; updated Chinese/English text, skill slot mask, skill status display, mode/skill descriptions, and UI interaction.
- Adjusted sound playback priority and distance, and simplified config option descriptions.
