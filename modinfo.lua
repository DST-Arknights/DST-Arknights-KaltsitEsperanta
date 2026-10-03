-- 对不支持的语言兜底到英文（DST 原版 ChooseTranslationTable 只回退到 tbl[1]，
-- 但我们用字典键值而非数字索引，非 en/zh 语言会返回 nil 导致崩溃）
local function T(tbl)
    return ChooseTranslationTable(tbl) or tbl["en"]
end

name = T({
    en = "Kaltsit Esperanta",
    zh = "凯尔希 思衡托"
})
-- 版本更新说明（由发布脚本自动维护，请勿手动编辑）
local UPDATE_EN = [[
v2.0.0 (2026-10-03)
- Mon3tr systems received major updates: added/synced skills, skill slot UI, summon skill, assault skill, intimidation waves, AI claw attacks, master command, work modes, and item collection/delivery, plus improved Kal'tsit behavior and brain logic; also adjusted hunger/death/ghost handling, base stats, 180-second cooldown, summon sanity, summon/recycle interaction with Kal'tsit healing, and jump animation presentation.
- Removed Mon3tr components and related functionality, including Kaltsit Calcite recipes/commands and related localization text.
- Healing gun now supports right-click self-healing and prevents ammo self-damage, limits destruction target loops, and improves tech checks.
- Disabled debug unlocks and locked unimplemented skills; updated Chinese/English text, skill slot mask, skill status display, mode/skill descriptions, and UI interaction.
- Adjusted sound playback priority and distance, and simplified config option descriptions.
]]

local UPDATE_ZH = [[
v2.0.0 (2026-10-03)
- Mon3tr 系统大幅更新：新增/同步技能、技能槽 UI、召唤技能、assault 技能、intimidation waves、AI 爪击、master command、工作模式与物品收集交付，并完善 Kal'tsit 行为与大脑逻辑；同时调整饥饿/死亡/幽灵处理、基础属性、180 秒冷却、召唤理智、召唤回收与 Kal'tsit 治疗交互及跳跃动作表现。
- 移除 Mon3tr 组件及相关功能，包括 Kaltsit Calcite 配方/命令与相关本地化文本。
- 治疗枪支持右键自疗并防止弹药自伤，限制破坏目标的循环次数，并优化科技判定。
- 关闭调试解锁并锁定未实现技能；更新中英文文案、技能栏遮罩、技能状态显示、模式和技能描述及 UI 交互。
- 调整声音播放优先级与距离，并简化配置选项描述。
]]

description = T({
    en = [[An Arknights character mod for Don't Starve Together, featuring Kal'tsit Esperanta, Intellect progression, advanced medical skills, and exclusive equipment. Design: 塔rua; Code: 望月心灵. Requires DST-ArknightsItemPackage. Feedback and discussion: QQ group 696891347.
]] .. UPDATE_EN,
    zh = [[饥荒联机版明日方舟角色模组：凯尔希·思衡托。通过「智识」培养解锁进阶技能，使用专属医疗装备。策划：塔rua；代码：望月心灵。需要前置模组 DST-ArknightsItemPackage。交流与反馈：QQ群 696891347。
]] .. UPDATE_ZH,
})
author = "望月心灵"
version = "2.0.0"
forumthread = "https://github.com/DST-Arknights/DST-Arknights-KaltsitEsperanta/issues"

api_version = 10

dont_starve_compatible = false
reign_of_giants_compatible = false

dst_compatible = true
all_clients_require_mod = true

icon_atlas = "modicon.xml"
icon = "modicon.tex"


server_filter_tags = {"character", "KaltsitEsperanta",  "kaltsit", "arknights", "明日方舟" }
configuration_options = {
    {
        name = "language",
        label = T({
            en = "Text Language",
            zh = "界面文本语言"
        }),
        hover = T({
            en = "Choose the mod's UI text language",
            zh = "选择模组界面文本的语言"
        }),
        options = {{
            description = T({
                en = "Auto (follow game)",
                zh = "自动 (跟随游戏)"
            }),
            data = "auto"
        }, {
            description = T({
                en = "Simplified Chinese",
                zh = "简体中文"
            }),
            data = "zh"
        }},
        default = "auto"
    },
    {
        name = "voice_language",
        label = T({
            en = "Voice Language",
            zh = "配音语言"
        }),
        hover = T({
            en = "Choose Kal'tsit Esperanta's voice language",
            zh = "选择凯尔希·思衡托的配音语言"
        }),
        options = {{
            description = T({
                en = "Chinese",
                zh = "中文"
            }),
            data = "zh"
        }, {
            description = T({
                en = "Japanese",
                zh = "日文"
            }),
            data = "jp"
        }},
        default = "jp"
    },
    {
        name = "skill2_damage_mode",
        label = T({
            en = "Skill 2 Damage Scheme",
            zh = "二技能伤害方案"
        }),
        hover = T({
            en = "Choose Skill 2's base damage. Each Skill 2 level adds 500 base damage.",
            zh = "选择二技能基础伤害方案；二技能每提升一段等级，基础伤害增加500点。"
        }),
        options = {{
            description = T({
                en = "1,000 fixed true damage",
                zh = "固定1000点真实伤害"
            }),
            data = "fixed_1000"
        }, {
            description = T({
                en = "2,000 fixed true damage",
                zh = "固定2000点真实伤害"
            }),
            data = "fixed_2000"
        }, {
            description = T({
                en = "500+3% target max health",
                zh = "500+敌人最大生命值3%"
            }),
            data = "percentage"
        }},
        default = "percentage"
    }, {
        name = "craft_hunger_cost",
        label = T({
            en = "Extra Hunger Cost When Crafting",
            zh = "制作时额外消耗饥饿值"
        }),
        hover = T({
            en = "Hunger is deducted the first time each recipe successfully produces an item; insufficient hunger does not block crafting.",
            zh = "每个配方首次成功生成物品时扣除饥饿值；饥饿值不足时不阻止制作。"
        }),
        options = {{
            description = "0",
            data = 0
        }, {
            description = "1",
            data = 1
        }, {
            description = "5",
            data = 5
        }, {
            description = "10",
            data = 10
        }},
        default = 5
    },
}


mod_dependencies = {
    {["DST-ArknightsItemPackage"] = false},
}
