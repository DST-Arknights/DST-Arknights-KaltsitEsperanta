-- ============================================================
-- KaltsitMon3trSkills
-- ============================================================
-- 附着于 Mon3tr 实体上，管理：
--   - 技能/指令的解锁与执行
--   - Mon3tr 自身的精英属性加成
--   - 与 kaltsit_calcite spellbook 的联动（通过 master 的 intellect）
-- ============================================================

local COMMANDS = require("mon3tr_command_defs")
local eliteConfig = require("elite_config")

-- ============================================================
-- KaltsitMon3trSkills
-- ============================================================

local KaltsitMon3trSkills = Class(function(self, inst)
    self.inst = inst       -- Mon3tr 实体
    self.master = nil      -- Kaltsit 实体（由 master 组件注入）
    self.active_basic = "standby"

    -- 指令执行器（外部注入）
    self.executors = {}
end)

-- ============================================================
-- 初始化（由 master 组件调用）
-- ============================================================

function KaltsitMon3trSkills:SetMaster(master_inst)
    self.master = master_inst
    self:ApplyEliteBonuses()
    self:RefreshCommands()
end

-- ============================================================
-- 精英加成（仅 Mon3tr 自身属性）
-- ============================================================

function KaltsitMon3trSkills:ApplyEliteBonuses()
    if not self.master then return end
    local intellect = self.master.components.kaltsit_intellect
    local level = intellect and intellect:GetEliteLevel() or 1
    self:_ApplyBonusesForLevel(level)
end

function KaltsitMon3trSkills:_ApplyBonusesForLevel(level)
    local config = eliteConfig.Get(level)
    local modifierKey = "kaltsit_esperanta_elite"
    if self.inst.components.health then
        self.inst.components.health.maxhealthaddmodifiers:SetModifier(modifierKey, config.mon3trHealthBonus)
    end
    if self.inst.components.combat then
        self.inst.components.combat.defaultdamageaddmodifiers:SetModifier(modifierKey, config.mon3trAttackBonus)
    end
end

-- ============================================================
-- 指令查询（由 calcite spellbook 或客户端调用）
-- ============================================================

function KaltsitMon3trSkills:GetAvailableCommands()
    if not self.master then
        return {}
    end
    local intellect = self.master.components.kaltsit_intellect
    local max = intellect and intellect.max or 1
    return COMMANDS.GetCommands(max)
end

function KaltsitMon3trSkills:RefreshCommands()
    self.inst:PushEvent("mon3tr_skills_commands_changed", self:GetAvailableCommands())
end

-- ============================================================
-- 指令执行验证
-- ============================================================

function KaltsitMon3trSkills:CanExecuteCommand(cmd_id)
    if not self.master then
        return false, "no_master"
    end

    local cmd = COMMANDS.GetCommandDef(cmd_id)
    if not cmd then
        return false, "unknown_command"
    end

    -- 智识阈值检查
    local intellect = self.master.components.kaltsit_intellect
    local max = intellect and intellect.max or 1
    if max < cmd.threshold then
        return false, "intellect_insufficient"
    end

    -- San 值检查
    if cmd.san_cost then
        if not self.master.components.sanity
            or self.master.components.sanity.current < cmd.san_cost then
            return false, "sanity_insufficient"
        end
    end

    -- CD 检查（CD 追踪在 Mon3tr 自身）
    if cmd.cooldown then
        local cd = self.inst.components.spellbookcooldowns
        if cd and cd:IsInCooldown("mon3tr_" .. cmd_id) then
            return false, "cooldown"
        end
    end

    return true
end

-- ============================================================
-- 指令执行
-- ============================================================

function KaltsitMon3trSkills:ExecuteCommand(cmd_id, ...)
    local ok, reason = self:CanExecuteCommand(cmd_id)
    if not ok then
        ArkLogger:Debug("KaltsitMon3trSkills:ExecuteCommand blocked:", cmd_id, reason)
        return false
    end

    if not self.master then return false end
    local cmd = COMMANDS.GetCommandDef(cmd_id)

    -- 基础指令：切换互斥模式
    if cmd.type == COMMANDS.COMMAND_TYPE.BASIC then
        self.active_basic = cmd_id
    end

    -- 消耗 san（从 master 上扣）
    if cmd.san_cost and self.master.components.sanity then
        self.master.components.sanity:DoDelta(-cmd.san_cost)
    end

    -- 启动 CD（CD 追踪在 Mon3tr 自身）
    if cmd.cooldown then
        local cd = self.inst.components.spellbookcooldowns
        if cd then
            cd:RestartSpellCooldown("mon3tr_" .. cmd_id, cmd.cooldown)
        end
    end

    -- 调用外部注入的执行器
    local executor = self.executors[cmd_id]
    if executor then
        executor(self.inst, cmd, ...)
    end

    ArkLogger:Debug("KaltsitMon3trSkills:ExecuteCommand done:", cmd_id)
    return true
end

function KaltsitMon3trSkills:RegisterExecutor(cmd_id, fn)
    self.executors[cmd_id] = fn
end

-- ============================================================
-- 存档
-- ============================================================

function KaltsitMon3trSkills:OnSave()
    return {
        active_basic = self.active_basic,
    }
end

function KaltsitMon3trSkills:OnLoad(data)
    if data == nil then return end
    if data.active_basic ~= nil then
        self.active_basic = data.active_basic
    end
end

return KaltsitMon3trSkills
