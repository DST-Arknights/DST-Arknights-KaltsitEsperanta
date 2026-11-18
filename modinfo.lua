-- 对不支持的语言兜底到英文（DST 原版 ChooseTranslationTable 只回退到 tbl[1]，
-- 但我们用字典键值而非数字索引，非 en/zh 语言会返回 nil 导致崩溃）
local function T(tbl)
    return ChooseTranslationTable(tbl) or tbl["en"]
end

name = T({
    en = "Kaltsit Esperanta",
    zh = "凯尔希 思衡托"
})
version = "2.1.4"

-- 版本更新说明（由发布脚本自动维护，请勿手动编辑）
local UPDATE_EN = [[
v2.1.4 (2026-11-18)
- Fixed possible issues with Mon3tr's assault when combat components are missing.
- Fixed trader interactions with Kal'tsit's portable tech and restored her ability to receive gifts at the physical tech station.
- Fixed display or sync issues with Kal'tsit's skills, equipment, and multiplayer status.
---
v2.1.3 (2026-11-01)
- Updated the Mon3tr summon skill description: removed the old “only 1 summon at a time” and “180s charge after summon ends” notes, and noted that Kal'tsit's hunger rate rises from 0.7 to 1.2 during summoning.
- Added unique buff icons for Mon3tr invincibility, Medic Monument shield/healing, and Tactical Anchor field.
- Added the “Cash Ability” item and recipe, craftable only by Kal'tsit and listed in the character and magic tabs; cost reduced to 99 gold, and reading it grants +5 current and max Insight.
- Adjusted Mon3tr's near-ground hover, skill-height pause, work efficiency, and hunger drain before/after recall.
]]

local UPDATE_ZH = [[
v2.1.4 (2026-11-18)
- 修复 Mon3tr 突袭时因战斗组件缺失可能出现的异常。
- 修复交易商人与 Kal'tsit 随身科技的交互，并恢复她在实体科技站领取礼物。
- 修复 Kal'tsit 的技能、装备与联机状态显示或同步异常。
---
v2.1.3 (2026-11-01)
- 修正 Mon3tr 召唤技能说明：移除“同时只能召唤1只”和“召唤结束后充能180秒”的旧说明，并注明召唤期间 Kal'tsit 饥饿速率由 0.7 升至 1.2。
- 为 Mon3tr 无敌、医者丰碑护盾与治疗、战术锚点领域添加独立增益图标。
- 新增“钞能力”道具及配方，仅 Kal'tsit 可制作并加入角色栏/魔法栏；材料降至 99 金子，阅读后智识当前值和上限各 +5。
- 调整 Mon3tr 的近地悬浮、技能高度暂停、工作效率及召回前后的饥饿消耗。
]]

description = T({
    en = [[An Arknights character mod for Don't Starve Together, featuring Kal'tsit Esperanta, Intellect progression, advanced medical skills, and exclusive equipment. Design: 塔rua; Code: 望月心灵. Requires "Arknights: Nexus". Feedback and discussion: QQ group 696891347.

Current version: ]] .. version .. "\n" .. UPDATE_EN,
    zh = [[饥荒联机版明日方舟角色模组：凯尔希·思衡托。通过「智识」培养解锁进阶技能，使用专属医疗装备。策划：塔rua；代码：望月心灵。需要前置模组 源枢。交流与反馈：QQ群 696891347。

当前版本: ]] .. version .. "\n" .. UPDATE_ZH,
})
author = "望月心灵"
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
    {["DST-Arknights-Nexus"] = false},
}
