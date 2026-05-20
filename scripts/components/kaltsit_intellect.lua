local function oncurrentdirty(self, value)
  self.inst.replica.kaltsit_intellect.state.current = value
end

local function onmaxdirty(self, value)
  self.inst.replica.kaltsit_intellect.state.max = value
end

local function ondiscountdirty(self, value)
  self.inst.replica.kaltsit_intellect.state.next_build_discounted = value
end

-- ============================================================
-- 模块级事件回调（无闭包）
-- ============================================================
local function on_killed(inst, data)
    if data and data.victim then
        inst.components.kaltsit_intellect:AddKnowledge(data.victim.prefab)
    end
end

local function on_builditem(inst, data)
    ArkLogger:Debug("Received builditem/buildstructure/char_cooked_item event", data)
    if data and data.item then
        inst.components.kaltsit_intellect:AddKnowledge(data.item.prefab)
    end
end

local function on_stewdone(inst, data)
    ArkLogger:Debug("Received char_stew_done event", data)
    if data and data.product then
        inst.components.kaltsit_intellect:AddKnowledge(data.product.prefab)
    end
end

local function on_death(inst)
    inst.components.kaltsit_intellect:Delta(-10)
end

local function on_cycles(inst, cycles)
    inst.components.kaltsit_intellect:Delta(1)
end

local function on_consumeingredients(inst, data)
    inst.components.kaltsit_intellect:OnConsumeIngredients(data)
end

local KaltsitIntellect = Class(function(self, inst)
    self.inst = inst
    self.current = 1
    self.max = 1
    self.next_build_discounted = false

    -- 已解锁图鉴: { [prefab_name] = true }
    self.unlocked_prefabs = {}

    -- 精英晋升阈值表: index 即为精英等级(从1开始), value 为所需最大理智值
    --   elite_thresholds[1] = 1   → 精英1 (基础/初始)
    --   elite_thresholds[2] = 100 → 精英2
    --   elite_thresholds[3] = 200 → 精英3
    self.elite_thresholds = { 1, 100, 200 }
    self.on_apply_elite = nil

    -- 注册事件监听
    self:_RegisterEvents()
end, nil, {
    current = oncurrentdirty,
    max = onmaxdirty,
    next_build_discounted = ondiscountdirty,
})

-- ============================================================
-- 事件注册与卸载
-- ============================================================
function KaltsitIntellect:_RegisterEvents()
    local inst = self.inst
    inst:ListenForEvent("killed", on_killed)       -- 击杀新生物: +1 current, +1 max
    inst:ListenForEvent("builditem", on_builditem) -- 制作新物品: +1 current, +1 max
    inst:ListenForEvent("buildstructure", on_builditem) -- 建造新结构: +1 current, +1 max
    inst:ListenForEvent("death", on_death)         -- 死亡: -10 current
    inst:WatchWorldState("cycles", on_cycles)      -- 每天: +1 current
    inst:ListenForEvent("char_cooked_item", on_builditem) -- 烹饪新菜肴: +1 current, +1 max
    inst:ListenForEvent("char_stew_done", on_stewdone)   -- 烹饪锅/便携锅完成新菜肴: +1 current, +1 max
end

function KaltsitIntellect:OnRemoveFromEntity()
    local inst = self.inst
    inst:RemoveEventCallback("killed", on_killed)
    inst:RemoveEventCallback("builditem", on_builditem)
    inst:RemoveEventCallback("buildstructure", on_builditem)
    inst:RemoveEventCallback("death", on_death)
    inst:StopWatchingWorldState("cycles", on_cycles)
    inst:RemoveEventCallback("char_cooked_item", on_builditem)
    inst:RemoveEventCallback("char_stew_done", on_stewdone)
    inst:RemoveEventCallback("consumeingredients", on_consumeingredients)
end

-- ============================================================
-- 知识图鉴
-- ============================================================

--- 添加新知识条目（首次制作/击杀的 prefab）
--- @param prefab string 物品或生物的 prefab 名
--- @return boolean 是否为新条目（true = 获得了+1智识和上限）
function KaltsitIntellect:AddKnowledge(prefab)
    if prefab and not self.unlocked_prefabs[prefab] then
        self.unlocked_prefabs[prefab] = true
        self:Delta(1)
        self:DeltaMax(1)
        return true
    end
    return false
end

--- 检查是否已解锁某个知识条目
--- @param prefab string
--- @return boolean
function KaltsitIntellect:HasKnowledge(prefab)
    return self.unlocked_prefabs[prefab] == true
end

-- ============================================================
-- 精英晋升
-- ============================================================

function KaltsitIntellect:SetOnApplyElite(fn)
    self.on_apply_elite = fn
end

function KaltsitIntellect:TryApplyElite(oldMax, newMax)
    -- 从高精英等级往低检查，确保一次性跨越多个门槛时高精英优先触发
    for i = #self.elite_thresholds, 1, -1 do
        local threshold = self.elite_thresholds[i]
        if oldMax < threshold and newMax >= threshold then
            if self.on_apply_elite then
                self.on_apply_elite(self.inst, i) -- 传入精英等级 (1-based, 即 index 本身)
            end
            return
        end
    end
end

-- ============================================================
-- 数值操作
-- ============================================================

function KaltsitIntellect:Delta(delta)
    self.current = math.clamp(self.current + delta, 0, self.max)
end

function KaltsitIntellect:DeltaMax(delta)
    local max = self.max
    self.max = math.max(self.max + delta, 1) -- max 至少为1，避免除0错误
    self:TryApplyElite(max, self.max)        -- 尝试晋升
end

-- 激活折扣状态（内部复用）
function KaltsitIntellect:_ActivateDiscount()
    self.next_build_discounted = true
    if self.inst.components.builder then
        self.inst.components.builder.ingredientmodminmodifiers:SetModifier(self.inst, TUNING.GREENAMULET_INGREDIENTMOD, self.inst)
        self.inst:ListenForEvent("consumeingredients", on_consumeingredients)
    end
end

-- 扣除10点并使下次制作消耗物品减半
function KaltsitIntellect:UseNextBuildDiscount()
    if self.next_build_discounted then
        return -- 已经在折扣状态中，无需重复激活
    end
    if self.current >= 10 then
        self:Delta(-10)
        self:_ActivateDiscount()
    end
end

-- 消耗材料事件回调: 完成一次折扣使用后移除修改器
function KaltsitIntellect:OnConsumeIngredients(data)
    if self.next_build_discounted then
        if not (data ~= nil and data.discounted == false) then
            if self.inst.components.builder then
                self.inst.components.builder.ingredientmodminmodifiers:RemoveModifier(self.inst)
                self.inst:RemoveEventCallback("consumeingredients", on_consumeingredients)
            end
            if data ~= nil then
                data.kaltsit_intellect_discount_used = true -- 标记已使用折扣（供其他系统检查）
            end
            self.next_build_discounted = false
        end
    end
end

-- ============================================================
-- 存档
-- ============================================================

function KaltsitIntellect:OnSave()
    return {
        current = self.current,
        max = self.max,
        unlocked_prefabs = self.unlocked_prefabs,
        next_build_discounted = self.next_build_discounted or nil,
    }
end

function KaltsitIntellect:OnLoad(data)
    if data == nil then return end
    if data.current ~= nil then
        self.current = data.current
    end
    if data.max ~= nil then
        self.max = data.max
    end
    if data.unlocked_prefabs ~= nil then
        self.unlocked_prefabs = data.unlocked_prefabs
    end
    if data.next_build_discounted then
        self:_ActivateDiscount()
    end
    self:TryApplyElite(0, self.max) -- 加载时根据 max 尝试应用精英效果
end

return KaltsitIntellect
