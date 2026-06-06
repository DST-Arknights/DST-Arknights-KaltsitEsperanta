-- ============================================================
-- Mon3tr 指令注册表
-- ============================================================
-- 每条指令携带解锁阈值、类型、san 消耗、冷却等信息。
-- 对外提供 GetCommands(intellect_max) 按智识上限过滤可用指令。
-- ============================================================

local ICON_SCALE = 0.6

local COMMAND_TYPE = {
    BASIC    = 1,  -- 互斥模式切换（待命/攻击/工作/解召）
    ADVANCED = 2,  -- 一次性技能（消耗 san + CD）
}

-- ============================================================
-- 基础指令（互斥，只能生效最后一个）
-- ============================================================

local BASIC_COMMANDS = {
    {
        id        = "standby",
        type      = COMMAND_TYPE.BASIC,
        threshold = 1,
        label     = STRINGS.MON3TR_COMMAND.STANDBY,
        bank      = "spell_icons_wendy",
        build     = "spell_icons_wendy",
        anims     = {
            idle  = { anim = "soothe" },
            focus = { anim = "soothe_focus", loop = true },
            down  = { anim = "soothe_pressed" },
        },
        widget_scale = ICON_SCALE,
    },
    {
        id        = "attack",
        type      = COMMAND_TYPE.BASIC,
        threshold = 1,
        label     = STRINGS.MON3TR_COMMAND.ATTACK,
        bank      = "spell_icons_wendy",
        build     = "spell_icons_wendy",
        anims     = {
            idle  = { anim = "rile" },
            focus = { anim = "rile_focus", loop = true },
            down  = { anim = "rile_pressed" },
        },
        widget_scale = ICON_SCALE,
    },
    {
        id        = "work",
        type      = COMMAND_TYPE.BASIC,
        threshold = 1,
        label     = STRINGS.MON3TR_COMMAND.WORK,
        bank      = "spell_icons_wendy",
        build     = "spell_icons_wendy",
        anims     = {
            idle  = { anim = "attack_at" },
            focus = { anim = "attack_at_focus", loop = true },
            down  = { anim = "attack_at_pressed" },
        },
        widget_scale = ICON_SCALE,
    },
    {
        id        = "unsummon",
        type      = COMMAND_TYPE.BASIC,
        threshold = 1,
        san_cost  = 100,
        label     = STRINGS.MON3TR_COMMAND.UNSUMMON,
        bank      = "spell_icons_wendy",
        build     = "spell_icons_wendy",
        anims     = {
            idle  = { anim = "unsummon" },
            focus = { anim = "unsummon_focus", loop = true },
            down  = { anim = "unsummon_pressed" },
        },
        widget_scale = ICON_SCALE,
    },
}

-- ============================================================
-- 进阶指令（不互斥，各自独立 CD）
-- ============================================================

local ADVANCED_COMMANDS = {
    {
        id        = "intimidate",
        type      = COMMAND_TYPE.ADVANCED,
        threshold = 1,
        san_cost  = 20,
        cooldown  = 30,
        label     = STRINGS.MON3TR_COMMAND.INTIMIDATE,
        bank      = "spell_icons_wendy",
        build     = "spell_icons_wendy",
        anims     = {
            idle     = { anim = "scare" },
            focus    = { anim = "scare_focus", loop = true },
            down     = { anim = "scare_pressed" },
            disabled = { anim = "scare_disabled" },
            cooldown = { anim = "scare_cooldown" },
        },
        widget_scale    = ICON_SCALE,
        checkcooldown   = function(doer)
            return doer ~= nil
                and doer.components.spellbookcooldowns
                and doer.components.spellbookcooldowns:GetSpellCooldownPercent("mon3tr_intimidate")
                or nil
        end,
        cooldowncolor = { 0.65, 0.65, 0.65, 0.75 },
    },
    {
        id        = "assault",
        type      = COMMAND_TYPE.ADVANCED,
        threshold = 50,
        san_cost  = 20,
        cooldown  = 10,
        label     = STRINGS.MON3TR_COMMAND.ASSAULT,
        bank      = "spell_icons_wendy",
        build     = "spell_icons_wendy",
        anims     = {
            idle     = { anim = "attack_at" },
            focus    = { anim = "attack_at_focus", loop = true },
            down     = { anim = "attack_at_pressed" },
            disabled = { anim = "attack_at_disabled" },
            cooldown = { anim = "attack_at_cooldown" },
        },
        widget_scale    = ICON_SCALE,
        checkcooldown   = function(doer)
            return doer ~= nil
                and doer.components.spellbookcooldowns
                and doer.components.spellbookcooldowns:GetSpellCooldownPercent("mon3tr_assault")
                or nil
        end,
        cooldowncolor = { 0.65, 0.65, 0.65, 0.75 },
    },
    {
        id        = "reinforce",
        type      = COMMAND_TYPE.ADVANCED,
        threshold = 100,
        san_cost  = 20,
        cooldown  = 60,
        label     = STRINGS.MON3TR_COMMAND.REINFORCE,
        bank      = "spell_icons_wendy",
        build     = "spell_icons_wendy",
        anims     = {
            idle     = { anim = "teleport" },
            focus    = { anim = "teleport_focus", loop = true },
            down     = { anim = "teleport_pressed" },
            disabled = { anim = "teleport_disabled" },
            cooldown = { anim = "teleport_cooldown" },
        },
        widget_scale    = ICON_SCALE,
        checkcooldown   = function(doer)
            return doer ~= nil
                and doer.components.spellbookcooldowns
                and doer.components.spellbookcooldowns:GetSpellCooldownPercent("mon3tr_reinforce")
                or nil
        end,
        cooldowncolor = { 0.65, 0.65, 0.65, 0.75 },
    },
    {
        id        = "castling",
        type      = COMMAND_TYPE.ADVANCED,
        threshold = 150,
        san_cost  = 20,
        cooldown  = 60,
        label     = STRINGS.MON3TR_COMMAND.CASTLING,
        bank      = "spell_icons_wendy",
        build     = "spell_icons_wendy",
        anims     = {
            idle     = { anim = "haunt" },
            focus    = { anim = "haunt_focus", loop = true },
            down     = { anim = "haunt_pressed" },
            cooldown = { anim = "haunt_cooldown" },
        },
        widget_scale    = ICON_SCALE,
        checkcooldown   = function(doer)
            return doer ~= nil
                and doer.components.spellbookcooldowns
                and doer.components.spellbookcooldowns:GetSpellCooldownPercent("mon3tr_castling")
                or nil
        end,
        cooldowncolor = { 0.65, 0.65, 0.65, 0.75 },
    },
    {
        id        = "meltdown",
        type      = COMMAND_TYPE.ADVANCED,
        threshold = 200,
        san_cost  = 20,
        cooldown  = 200,
        label     = STRINGS.MON3TR_COMMAND.MELTDOWN,
        bank      = "spell_icons_wendy",
        build     = "spell_icons_wendy",
        anims     = {
            idle     = { anim = "unsummon" },
            focus    = { anim = "unsummon_focus", loop = true },
            down     = { anim = "unsummon_pressed" },
        },
        widget_scale    = ICON_SCALE,
        checkcooldown   = function(doer)
            return doer ~= nil
                and doer.components.spellbookcooldowns
                and doer.components.spellbookcooldowns:GetSpellCooldownPercent("mon3tr_meltdown")
                or nil
        end,
        cooldowncolor = { 0.65, 0.65, 0.65, 0.75 },
    },
}

-- ============================================================
-- 按智识上限过滤可用指令
-- ============================================================

--- @param intellect_max number 凯尔希的智识上限
--- @return table 已解锁的指令列表（用于 spellbook:SetItems）
local function GetCommands(intellect_max)
    intellect_max = intellect_max or 1
    local result = {}
    for _, cmd in ipairs(BASIC_COMMANDS) do
        if intellect_max >= cmd.threshold then
            table.insert(result, cmd)
        end
    end
    for _, cmd in ipairs(ADVANCED_COMMANDS) do
        if intellect_max >= cmd.threshold then
            table.insert(result, cmd)
        end
    end
    return result
end

--- 按 id 查找单条指令定义
--- @param cmd_id string
--- @return table|nil
local function GetCommandDef(cmd_id)
    for _, cmd in ipairs(BASIC_COMMANDS) do
        if cmd.id == cmd_id then return cmd end
    end
    for _, cmd in ipairs(ADVANCED_COMMANDS) do
        if cmd.id == cmd_id then return cmd end
    end
    return nil
end

--- 获取所有进阶指令（供 commander 遍历 CD 用）
local function GetAdvancedCommands()
    return ADVANCED_COMMANDS
end

return {
    COMMAND_TYPE         = COMMAND_TYPE,
    BASIC_COMMANDS       = BASIC_COMMANDS,
    ADVANCED_COMMANDS    = ADVANCED_COMMANDS,
    GetCommands          = GetCommands,
    GetCommandDef        = GetCommandDef,
    GetAdvancedCommands  = GetAdvancedCommands,
}
