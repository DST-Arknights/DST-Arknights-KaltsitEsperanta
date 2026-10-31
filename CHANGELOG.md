# 版本更新记录

## v2.1.3 (2026-11-01)

- 修正 Mon3tr 召唤技能说明：移除“同时只能召唤1只”和“召唤结束后充能180秒”的旧说明，并注明召唤期间 Kal'tsit 饥饿速率由 0.7 升至 1.2。
- 为 Mon3tr 无敌、医者丰碑护盾与治疗、战术锚点领域添加独立增益图标。
- 新增“钞能力”道具及配方，仅 Kal'tsit 可制作并加入角色栏/魔法栏；材料降至 99 金子，阅读后智识当前值和上限各 +5。
- 调整 Mon3tr 的近地悬浮、技能高度暂停、工作效率及召回前后的饥饿消耗。
---
- Updated the Mon3tr summon skill description: removed the old “only 1 summon at a time” and “180s charge after summon ends” notes, and noted that Kal'tsit's hunger rate rises from 0.7 to 1.2 during summoning.
- Added unique buff icons for Mon3tr invincibility, Medic Monument shield/healing, and Tactical Anchor field.
- Added the “Cash Ability” item and recipe, craftable only by Kal'tsit and listed in the character and magic tabs; cost reduced to 99 gold, and reading it grants +5 current and max Insight.
- Adjusted Mon3tr's near-ground hover, skill-height pause, work efficiency, and hunger drain before/after recall.

## v2.1.2 (2026-10-24)

- 修复召唤物的固定反击在 Meltdown 期间未沿用角色真实伤害比例的问题，使其继续转为真实伤害。
---
- Fixed summons' fixed counterattacks not inheriting the character's true damage ratio during Meltdown, so they continue to convert to true damage.

## v2.1.1 (2026-10-18)

- 将 Trinket Purification 移至 Intellect 制作，并改为 10:1 配方。
---
- Moved Trinket Purification to Intellect crafting and changed its recipe to 10:1.

## v2.1.0 (2026-10-18)

- 完善 Mon3tr 的采集、护盾、范围攻击、进阶技能与联动能力，注册宠物小地图图标并优化技能描述。
- 完善 Clinical Potion 与诅咒饰品净化。
- 更新 Kaltsit 技能解锁描述，补充 Insight 上限信息。
- 修复 Mon3tr 模式快捷键设置卡死；三种基础状态支持快捷键循环切换、自定义按键，并在描述卡显示切换快捷键。
- 修正悬浮卡片焦点与切换行为，避免按键文本截断时卡死，按钮改为 [设置]/[重置] 并补齐中英文提示。
---
- Improved Mon3tr's gathering, shields, area attacks, advanced skills, and linked abilities; registered the pet minimap icon and refined skill descriptions.
- Improved Clinical Potion and curse trinket purification.
- Updated Kaltsit's skill unlock description with Insight cap information.
- Fixed the Mon3tr mode hotkey settings freeze; the three basic states now support hotkey cycling and custom keys, with the switch hotkey shown on the description card.
- Fixed hover card focus and switching behavior, prevented freezes when key text is truncated, and changed the buttons to [Settings]/[Reset] with complete Chinese/English prompts.

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
