# 凯尔希项目协作约定

## 共享规范与依赖

- 通用的 DST Lua、Prefab、状态图、客户端/主机分层、国际化、资源处理、发布和验证规范，统一遵循共享项目 `DST-Arknights-AICoding` 中与任务匹配的 skill；本文件只补充凯尔希项目特有约定。
- 本项目依赖 `DST-Arknights-Nexus`（源枢）。源枢的位置从记忆中查找；记忆不明确时先询问用户。保持 `modinfo.lua` 的依赖键和源枢提供的运行时 API 契约，不在本项目复制源枢实现。

## 入口与玩法范围

- `modmain.lua` 负责 Prefab 注册、双语 PO 注册、语音注册、配置读取和各功能模块导入。
- `modmain/kaltsit_esperanta_skill.lua`、`kaltsit_mon3tr_skill.lua`、`kaltsit_mon3tr_commands.lua`、`kaltsit_mon3tr_claw.lua` 和 `kaltsit_mon3tr_ui.lua` 共同维护凯尔希与 Mon3tr 的技能、指令和 UI。
- `modmain/special_treatment_gun.lua`、`special_treatment_bullet.lua`、`tactical_anchor_action.lua`、`kaltsit_intellect.lua`、`kaltsit_esperanta_tech.lua` 与 `kaltsit_animal_affinity.lua` 承载治疗枪、战术锚点、智识、科技和动物亲和等项目玩法。
- 新增或调整玩法时，保持 `modmain.lua` 的 `PrefabFiles`、`modimport`、PO/语音注册与实际脚本文件同步；配置项的中英文名称、说明和默认行为也要同步。

## 本项目资源与文案

- 运行时资源位于 `anim/`、`images/`、`sound/` 和 `bigportraits/`；可编辑来源分别优先使用 `animSource/`、`imageSource/` 和 `soundSource/`，不要把生成资源当作唯一来源。
- `languages/` 保存凯尔希项目的中英文 PO 和语音映射；新增可见文本时保持两种语言的键集合和语义一致。
- `docs/steam-description.md` 与 `docs/steam-description-steam.txt` 是工坊说明文件。说明应以玩家可见的角色、技能、装备和配置为主，避免写入内部实现细节。
- 资源、Prefab、图集、动画 bank/build 和 `PrefabFiles` 名称必须保持项目内一致；涉及 Mon3tr 联动时先确认源枢的公开接口，再调整调用方。

## 项目专属检查

- 修改技能、装备或 Prefab 后，检查 `modmain.lua` 的导入/注册、对应资源是否存在，以及中英文 PO 是否同时更新。
- 修改工坊文案或发布配置时，同时检查上述两份说明和 `tools/publish.ps1` 的项目配置；通用发布流程按 `DST-Arknights-AICoding` 的 skill 执行。