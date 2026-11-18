local common = require("kaltsit_esperanta_common")

local ICON_ATLAS = "images/ui_kaltsit_esperanta_buff.xml"
local assets = {
  Asset("ATLAS", ICON_ATLAS),
}

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

local function RefreshAnchorField(inst, target)
  local sources = inst._field_sources
  for anchor in pairs(sources) do
    if not anchor:IsValid() or anchor.components.tactical_anchor == nil then
      sources[anchor] = nil
    end
  end
  local anchor = inst._field_anchor
  if anchor == nil or sources[anchor] == nil then
    anchor = next(sources)
    inst._field_anchor = anchor
  end
  if anchor == nil then
    inst.components.debuff:Stop()
    return false
  end
  local field = sources[anchor]
  inst._field_health_percent = field.health_percent or 0.02
  if target.components.combat ~= nil then
    target.components.combat.externaldamagemultipliers:SetModifier(inst, 1 + (field.damage_multiplier or 0.2))
  end
  return true
end

local function UpdateAnchorFieldSource(inst, target, followsymbol, followoffset, data, anchor)
  if anchor ~= nil then
    inst._field_sources[anchor] = data ~= nil and data.field or {}
  end
  return RefreshAnchorField(inst, target)
end

local function RemoveAnchorFieldSource(inst, anchor)
  inst._field_sources[anchor] = nil
  RefreshAnchorField(inst, inst.components.debuff.target)
end

local buffers = { {
  name = "kaltsit_mon3tr_invulnerability_buff",
  -- 仅显示受击无敌，由 passive 的实际起止控制，不单独计时或抵挡一次后消失。
  prefabs = { "forcefieldfx" },
  title = STRINGS.UI.KALTSIT_ESPERANTA_BUFFS.MON3TR_INVULNERABILITY_TITLE,
  description = STRINGS.UI.KALTSIT_ESPERANTA_BUFFS.MON3TR_INVULNERABILITY_DESCRIPTION,
  icon_atlas = ICON_ATLAS,
  icon_image = "mon3tr_invulnerability.tex",
  OnAttached = ShowForcefield,
  OnDetached = HideForcefield,
}, {
  name = "doctors_monuments_invincible_buff",
  duration = 10,
  keepondespawn = true,
  prefabs = { "forcefieldfx" },
  title = STRINGS.UI.KALTSIT_ESPERANTA_BUFFS.DOCTORS_MONUMENTS_INVINCIBLE_TITLE,
  description = STRINGS.UI.KALTSIT_ESPERANTA_BUFFS.DOCTORS_MONUMENTS_INVINCIBLE_DESCRIPTION,
  icon_atlas = ICON_ATLAS,
  icon_image = "doctors_monuments_shield.tex",
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
  icon_atlas = ICON_ATLAS,
  icon_image = "doctors_monuments_treatment.tex",
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
  -- 不设 keepondespawn：玩家 despawn 时移除，由附近锚点 playerprox 重新施加。
  -- 读档缺少来源或锚点移除未触发 onfar 时，由周期检查清理失效来源。
  title = STRINGS.UI.KALTSIT_ESPERANTA_BUFFS.ANCHOR_FIELD_TITLE,
  description = STRINGS.UI.KALTSIT_ESPERANTA_BUFFS.ANCHOR_FIELD_DESCRIPTION,
  icon_atlas = ICON_ATLAS,
  icon_image = "anchor_field.tex",
  OnAttached = function(inst, target, followsymbol, followoffset, data, buffer)
    -- 重叠领域共用一个 buff；离开一个来源后继续使用其余来源，数值保持单份。
    -- 锚点引用仅存实例字段，buffData 保持纯数据。
    inst._field_sources = {}
    inst._field_anchor = buffer
    inst.RemoveAnchor = RemoveAnchorFieldSource
    -- 存档恢复时没有 buffer，先完成附着，再由周期检查清理或接收附近锚点。
    if buffer ~= nil and not UpdateAnchorFieldSource(inst, target, followsymbol, followoffset, data, buffer) then
      return
    end
    inst._field_task = inst:DoPeriodicTask(1, function()
      if not RefreshAnchorField(inst, target) then
        return
      end
      if target.components.health and not target.components.health:IsDead() then
        local heal = target.components.health:GetMaxWithPenalty() * inst._field_health_percent
        local anchor = inst._field_anchor
        local owner = anchor.components.tactical_anchor:GetOwner()
        if owner ~= nil then
          common.HealTarget(owner, target, heal, "kaltsit_anchor_field_buff", false)
        end
      end
    end)
  end,
  OnExtended = UpdateAnchorFieldSource,
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
  v.assets = assets
  table.insert(results, ArkMakeBuff(v))
end
return unpack(results)
