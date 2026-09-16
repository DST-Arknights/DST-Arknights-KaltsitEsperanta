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
local UPDATE_EN = [[]]

local UPDATE_ZH = [[]]

description = T({
    en = [[TODO:
]] .. UPDATE_EN,
    zh = [[TODO:
]] .. UPDATE_ZH,
})
author = ""
version = "0.0.1"
forumthread = "https://github.com/TohsakaKuro/DST-Arknights-KaltsitEsperanta/issues"

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
                en = "500 + 3% target max health (default)",
                zh = "500点 + 敌人最大生命值3%（默认）"
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
            description = "5 (default)",
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
