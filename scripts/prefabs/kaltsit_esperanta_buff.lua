local buffers = { {
  name = "doctors_monuments_invincible_buff",
  duration = 10,
  keepondespawn = true,
    icon_atlas = "images/ui_mon3tr_skill.xml",
    icon_image = "skill1.tex",
  OnAttached = function(inst, target)
    if target.components.health then
      target.components.health.externalabsorbmodifiers:SetModifier(inst, 1.0)
    end
  end,
  OnDetached = function(inst, target)
    if target.components.health then
      target.components.health.externalabsorbmodifiers:RemoveModifier(inst)
    end
  end,
}, {
  name = "doctors_monuments_treatment_buff",
  keepondespawn = true,
  duration = 20,
    icon_atlas = "images/ui_mon3tr_skill.xml",
    icon_image = "skill2.tex",
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
} }

local results = {}
for i, v in ipairs(buffers) do
  table.insert(results, ArkMakeBuff(v))
end
return unpack(results)
