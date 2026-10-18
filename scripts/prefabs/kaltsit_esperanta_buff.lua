local common = require("kaltsit_esperanta_common")

local function GetTreatmentHealer(inst)
  if inst._treatment_healer ~= nil and inst._treatment_healer:IsValid() then
    return inst._treatment_healer
  end
  local userid = inst.buffData ~= nil and inst.buffData.healer_userid or nil
  if userid ~= nil and userid ~= "" then
    for _, player in ipairs(AllPlayers) do
      if player.userid == userid then
        inst._treatment_healer = player
        return player
      end
    end
  end
end

local function ShowForcefield(inst, target)
  if inst._forcefield_fx == nil then
    inst._forcefield_fx = SpawnPrefab("forcefieldfx")
    inst._forcefield_fx.entity:SetParent(target.entity)
    inst._forcefield_fx.Transform:SetPosition(0, 0.2, 0)
    inst._forcefield_fx.Light:Enable(false)
  end
end

local function HideForcefield(inst)
  if inst._forcefield_fx ~= nil then
    if inst._forcefield_fx:IsValid() then
      inst._forcefield_fx:kill_fx()
    end
    inst._forcefield_fx = nil
  end
end

local buffers = { {
  name = "kaltsit_mon3tr_invulnerability_buff",
  -- 仅显示受击无敌，由 passive 的实际起止控制，不单独计时或抵挡一次后消失。
  prefabs = { "forcefieldfx" },
  title = STRINGS.UI.KALTSIT_ESPERANTA_BUFFS.MON3TR_INVULNERABILITY_TITLE,
  description = STRINGS.UI.KALTSIT_ESPERANTA_BUFFS.MON3TR_INVULNERABILITY_DESCRIPTION,
  icon_atlas = "images/ui_kaltsit_esperanta_skill.xml",
  icon_image = "skill1.tex",
  OnAttached = ShowForcefield,
  OnDetached = HideForcefield,
}, {
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
    ShowForcefield(inst, target)
  end,
  OnDetached = function(inst, target)
    if target.components.health then
      target.components.health.externalabsorbmodifiers:RemoveModifier(inst)
    end
    HideForcefield(inst)
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
    inst._treatment_healer = buffer
    inst._treatment_amount = health
    inst._treatment_task = inst:DoPeriodicTask(1, function()
      if target.components.health and not target.components.health:IsDead() then
        local healer = GetTreatmentHealer(inst)
        if healer ~= nil then
          common.HealTarget(healer, target, inst._treatment_amount, "doctors_monuments_treatment_buff", false)
        else
          target.components.health:DoDelta(inst._treatment_amount, false, "doctors_monuments_treatment_buff")
        end
      end
    end)
  end,
  OnExtended = function(inst, target, followsymbol, followoffset, data, buffer)
    inst._treatment_healer = buffer
    inst._treatment_amount = data and data.health or 2
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
        local owner = anchor.components.tactical_anchor:GetOwner()
        if owner ~= nil then
          common.HealTarget(owner, target, heal, "kaltsit_anchor_field_buff", false)
        end
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
} }

local results = {}
for i, v in ipairs(buffers) do
  table.insert(results, ArkMakeBuff(v))
end
return unpack(results)
