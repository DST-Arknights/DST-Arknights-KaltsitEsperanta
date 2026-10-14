-- 只用于本项目的短暂控制；实体任务和字段不进入存档，不依赖未发布的源枢 API。
local M = {}

local function Apply(target, key, duration, speed, stun, fxprefab, hitfx)
  if target == nil or not target:IsValid() or target.components.health == nil
    or target.components.health:IsDead() then return end
  local field = "_" .. key
  local state = target[field]
  if state == nil then
    state = {}
    target[field] = state
    state.cleanup = function()
      if target[field] ~= state then return end
      target[field] = nil
      if state.task ~= nil then state.task:Cancel() end
      target:RemoveEventCallback("death", state.cleanup)
      target:RemoveEventCallback("onremove", state.cleanup)
      if target.components.locomotor ~= nil then
        target.components.locomotor:RemoveExternalSpeedMultiplier(target, key)
      end
      if stun then
        if target.components.combat ~= nil then
          ArkUnhookFunction(target.components.combat, "DoAttack", state.blockattack)
        end
        if target:IsValid() and not target.components.health:IsDead() then target:RestartBrain(key) end
      end
      if state.fx ~= nil and state.fx:IsValid() then
        if state.fx.KillFX ~= nil then state.fx:KillFX() else state.fx:Remove() end
      end
    end
    target:ListenForEvent("death", state.cleanup)
    target:ListenForEvent("onremove", state.cleanup)
    if stun then
      target:ClearBufferedAction()
      if target.components.locomotor ~= nil then target.components.locomotor:Stop() end
      if target.Physics ~= nil then target.Physics:Stop() end
      target:StopBrain(key)
      state.blockattack = function() return false end
      if target.components.combat ~= nil then
        ArkHookFunction(target.components.combat, "DoAttack", state.blockattack)
      end
    end
    if fxprefab ~= nil then
      state.fx = SpawnPrefab(fxprefab)
      if state.fx ~= nil then
        state.fx.entity:SetParent(target.entity)
        if state.fx.StartFX ~= nil then state.fx:StartFX(target) end
      end
    end
  elseif state.task ~= nil then
    state.task:Cancel()
  end
  if target.components.locomotor ~= nil then
    target.components.locomotor:SetExternalSpeedMultiplier(target, key, speed)
  end
  state.task = target:DoTaskInTime(duration, state.cleanup)
  if hitfx ~= nil then
    local fx = SpawnPrefab(hitfx)
    if fx ~= nil then fx.Transform:SetPosition(target.Transform:GetWorldPosition()) end
  end
  return state
end

function M.ApplyStun(target, duration, key)
  -- 不强切状态图；Boss 已经开始的特殊动作由原状态图继续管理。
  return Apply(target, key, duration, 0, true)
end

function M.ApplySkill2Pause(target)
  return Apply(target, "kaltsit_esperanta_skill2_pause", 5, 0.2, false,
    "slingshotammo_slow_debuff_fx", "slingshot_shadow_aoe_fx")
end

return M
