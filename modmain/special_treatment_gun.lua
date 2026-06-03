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

AddAction('SPECIAL_TREAT_HEAL', STRINGS.ACTIONS.HEAL.GENERIC, function(act)
    local doer   = act.doer
    local target = act.target
    if not doer or not target then return false end

    local gun = doer.components.inventory
        and doer.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
    if not gun or gun.prefab ~= "special_treatment_gun" or not gun:HasTag("ammoloaded") then
        return false
    end
    -- Mark next projectile as forced heal (overrides PvP enemy check)
    doer._next_shot_is_heal = true
    ArkLogger:Debug("SPECIAL_TREAT_HEAL action triggered by %s on %s with %s", doer, target, gun)
    return true
end)

-- 注册组件动作：右键点击玩家或玩家的宠物时显示"治疗"选项
AddComponentAction("EQUIPPED", "weapon", function(inst, doer, target, actions, right)
    if right or target == nil then
        return
    end
    if inst.prefab ~= "special_treatment_gun" then
        return
    end
    if target == doer or target:HasTag("player") then
        table.insert(actions, ACTIONS.SPECIAL_TREAT_HEAL)
    return end
    local leader = target.replica.follower and target.replica.follower:GetLeader()
    if leader and leader:HasTag("player") then
        table.insert(actions, ACTIONS.SPECIAL_TREAT_HEAL)
    return end
end)

-- 状态图动作处理器（适用于 wilson 系角色）
AddStategraphActionHandler("wilson", ActionHandler(ACTIONS.SPECIAL_TREAT_HEAL, "dolongaction"))
AddStategraphActionHandler("wilson_client", ActionHandler(ACTIONS.SPECIAL_TREAT_HEAL, "dolongaction"))
