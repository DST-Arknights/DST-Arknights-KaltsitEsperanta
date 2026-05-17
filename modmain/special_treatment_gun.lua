-- scripts/prefabs/special_treatment_gun.lua
-- 特质治疗枪 + 三种治疗弹 + 各自独立投射物
-- 弹药机制: 枪上有 1 格物品槽，将治疗弹放入后方可发射

-- ============================================================
-- 容器定义（在 containers.data 中注册，供 WidgetSetup 使用）
-- ============================================================
local containers = require "containers"
containers.params.special_treatment_gun =
{
    widget =
    {
        slotpos =
        {
            Vector3(0, 32 + 4, 0),
        },
        slotbg =
        {
            { image = "slingshot_ammo_slot.tex" },
        },
        animbank = "ui_cookpot_1x2",
        animbuild = "ui_cookpot_1x2",
        pos = Vector3(0, 15, 0),
    },
    type = "hand_inv",
    excludefromcrafting = true,
}

-- 配方: 治疗枪 , 1齿轮1绿宝石10金子, 无需科技, 仅凯尔希可制作
AddCharacterRecipe("special_treatment_gun", { Ingredient("gears", 1), Ingredient("greengem", 1), Ingredient("goldnugget", 10) }, TECH.NONE, {
    builder_tag = "kaltsit_esperanta",
})
