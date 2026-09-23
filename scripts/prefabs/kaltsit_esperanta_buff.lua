local SKILL2_PAUSE_SPEED_MULTIPLIER = 0.2
local SKILL2_PAUSE_SPEED_KEY = "kaltsit_esperanta_skill2_pause"

local function SpawnSkill2PauseShadowFx(target)
  if target == nil or not target:IsValid() then
    return
  end
  local fx = SpawnPrefab("slingshot_shadow_aoe_fx")
  if fx ~= nil then
    local x, _, z = target.Transform:GetWorldPosition()
    fx.Transform:SetPosition(x, 0, z)
  end
end

local function EnsureSkill2PauseSlowFx(inst, target)
  if inst._skill2_pause_fx ~= nil and inst._skill2_pause_fx:IsValid() then
    return
  end
  local fx = SpawnPrefab("slingshotammo_slow_debuff_fx")
  if fx ~= nil then
    fx.entity:SetParent(target.entity)
    if fx.StartFX ~= nil then
      fx:StartFX(target)
    end
    inst._skill2_pause_fx = fx
  end
end

local function OnSkill2PauseAttached(inst, target)
  if target.components.locomotor ~= nil then
    target.components.locomotor:SetExternalSpeedMultiplier(
      inst, SKILL2_PAUSE_SPEED_KEY, SKILL2_PAUSE_SPEED_MULTIPLIER)
  end
  EnsureSkill2PauseSlowFx(inst, target)
  SpawnSkill2PauseShadowFx(target)
end

local function OnSkill2PauseExtended(inst, target)
  if target.components.locomotor ~= nil then
    target.components.locomotor:SetExternalSpeedMultiplier(
      inst, SKILL2_PAUSE_SPEED_KEY, SKILL2_PAUSE_SPEED_MULTIPLIER)
  end
  EnsureSkill2PauseSlowFx(inst, target)
  SpawnSkill2PauseShadowFx(target)
end

local function OnSkill2PauseDetached(inst, target)
  if target.components.locomotor ~= nil then
    target.components.locomotor:RemoveExternalSpeedMultiplier(inst, SKILL2_PAUSE_SPEED_KEY)
  end
  if inst._skill2_pause_fx ~= nil then
    if inst._skill2_pause_fx:IsValid() then
      if inst._skill2_pause_fx.KillFX ~= nil then
        inst._skill2_pause_fx:KillFX()
      else
        inst._skill2_pause_fx:Remove()
      end
    end
    inst._skill2_pause_fx = nil
  end
end

local buffers = { {
  name = "doctors_monuments_invincible_buff",
  duration = 10,
  keepondespawn = true,
  prefabs = { "forcefieldfx" },
  title = STRINGS.UI.KALTSIT_ESPERANTA_BUFFS.DOCTORS_MONUMENTS_INVINCIBLE_TITLE,
  description = STRINGS.UI.KALTSIT_ESPERANTA_BUFFS.DOCTORS_MONUMENTS_INVINCIBLE_DESCRIPTION,
  icon_atlas = "images/ui_kaltsit_esperanta_skill.xml",
  icon_image = "skill1.tex",
  OnAttached = function(inst, target)
    if target.components.health then
      target.components.health.externalabsorbmodifiers:SetModifier(inst, 1.0)
    end
    -- 铥矿皇冠同款力场护盾特效（forcefieldfx），无敌可见
    if inst._forcefield_fx == nil then
      inst._forcefield_fx = SpawnPrefab("forcefieldfx")
      inst._forcefield_fx.entity:SetParent(target.entity)
      inst._forcefield_fx.Transform:SetPosition(0, 0.2, 0)
      inst._forcefield_fx.Light:Enable(false)
    end
  end,
  OnDetached = function(inst, target)
    if target.components.health then
      target.components.health.externalabsorbmodifiers:RemoveModifier(inst)
    end
    if inst._forcefield_fx ~= nil then
      if inst._forcefield_fx:IsValid() and inst._forcefield_fx.kill_fx ~= nil then
        inst._forcefield_fx:kill_fx()
      end
      inst._forcefield_fx = nil
    end
  end,
}, {
  name = "doctors_monuments_treatment_buff",
  duration = 20,
  title = STRINGS.UI.KALTSIT_ESPERANTA_BUFFS.DOCTORS_MONUMENTS_TREATMENT_TITLE,
  description = STRINGS.UI.KALTSIT_ESPERANTA_BUFFS.DOCTORS_MONUMENTS_TREATMENT_DESCRIPTION,
  icon_atlas = "images/ui_kaltsit_esperanta_skill.xml",
  icon_image = "skill1.tex",
  OnAttached = function(inst, target, followsymbol, followoffset, data, buffer)
    -- 每秒回复的数值
    local health = data and data.health or 2
    inst._treatment_task = inst:DoPeriodicTask(1, function()
      if target.components.health and not target.components.health:IsDead() then
        target.components.health:DoDelta(health, false, "doctors_monuments_treatment_buff")
      end
    end)
  end,
  OnDetached = function(inst, target)
    if inst._treatment_task then
      inst._treatment_task:Cancel()
      inst._treatment_task = nil
    end
  end,
}, {
  name = "kaltsit_anchor_field_buff",
  -- 不设 duration：buff 由 playerprox 的 onnear（进入领域）挂载、onfar（离开领域）
  -- 或玩家死亡/锚点消失移除。设时长会在玩家停留领域内时到期被清掉，而 onnear 只触发一次。
  -- 不设 keepondespawn：buff 由锚点（他人）触发，不进玩家存档；玩家 despawn 后
  -- 由锚点 playerprox 重新施加。锚点移除时不触发 onfar，靠回血循环检查锚点源自动清理。
  title = STRINGS.UI.KALTSIT_ESPERANTA_BUFFS.ANCHOR_FIELD_TITLE,
  description = STRINGS.UI.KALTSIT_ESPERANTA_BUFFS.ANCHOR_FIELD_DESCRIPTION,
  icon_atlas = "images/ui_kaltsit_esperanta_skill.xml",
  icon_image = "skill3.tex",
  OnAttached = function(inst, target, followsymbol, followoffset, data, buffer)
    local field = data and data.field or {}
    local healthPercent = field.health_percent or 0.02  -- 每秒回最大生命比例
    local damageMult = field.damage_multiplier or 0.2   -- 攻击力提升比例
    -- 施术者（锚点）经 AddDebuff 的 buffer 传入：锚点消失（技能结束）时移除此 buff。
    -- 实体引用只存实例字段，不经 data 传递，data 保持纯数据不参与序列化。
    local anchor = buffer

    -- 攻击力提升：externaldamagemultipliers 乘算（原版 combat CalcDamage 会乘这个值）
    if target.components.combat then
      target.components.combat.externaldamagemultipliers:SetModifier(inst, 1 + damageMult)
    end

    -- 每秒回复最大生命百分比
    inst._field_task = inst:DoPeriodicTask(1, function()
      -- 锚点已消失（技能收回/移除）：自动移除此 buff，结束领域效果
      if anchor == nil or not anchor:IsValid() then
        inst.components.debuff:Stop()
        return
      end
      if target.components.health and not target.components.health:IsDead() then
        local heal = target.components.health:GetMaxWithPenalty() * healthPercent
        target.components.health:DoDelta(heal, false, "kaltsit_anchor_field_buff")
      end
    end)
  end,
  OnDetached = function(inst, target)
    if target.components.combat then
      target.components.combat.externaldamagemultipliers:RemoveModifier(inst)
    end
    if inst._field_task then
      inst._field_task:Cancel()
      inst._field_task = nil
    end
  end,
}, {
  name = "kaltsit_esperanta_skill2_pause_buff",
  duration = 5,
  prefabs = { "slingshotammo_slow_debuff_fx", "slingshot_shadow_aoe_fx" },
  title = STRINGS.UI.KALTSIT_ESPERANTA_BUFFS.SKILL2_PAUSE_TITLE,
  description = STRINGS.UI.KALTSIT_ESPERANTA_BUFFS.SKILL2_PAUSE_DESCRIPTION,
  OnAttached = OnSkill2PauseAttached,
  OnExtended = OnSkill2PauseExtended,
  OnDetached = OnSkill2PauseDetached,
} }

local results = {}
for i, v in ipairs(buffers) do
  table.insert(results, ArkMakeBuff(v))
end
return unpack(results)
