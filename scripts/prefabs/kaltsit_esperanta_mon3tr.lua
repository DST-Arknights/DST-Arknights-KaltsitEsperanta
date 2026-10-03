local MakePlayerCharacter = require "prefabs/player_common"
local brain = require "brains/kaltsit_esperanta_mon3trbrain"
local PET_LIGHT_RADIUS = 0.5

local prefabs = {
  "yellowamuletlight",
  "battlesong_instant_panic_fx",
  "kaltsit_mon3tr_intimidate_fx",
  "kaltsit_esperanta_mon3tr_claw",
  "groundpoundring_fx",
  "pine_needles_chop",
  "boss_ripple_fx",
}
local assets = {
  -- Asset("ATLAS", "images/map_icons/kaltsit_esperanta_mon3tr.xml"),
  Asset("ANIM", "anim/kaltsit_esperanta_mon3tr.zip"),
}

local start_inv = {}

local function IsPlayerControlled(inst)
  local userid = inst.Network:GetUserID()
  return userid ~= nil and userid ~= ""
end

local function UpdateClaw(inst)
  local claw = inst._kaltsit_mon3tr_claw
  if IsPlayerControlled(inst) or inst:HasAnyTag("playerghost", "corpse")
    or inst.components.health:IsDead() then
    inst._kaltsit_mon3tr_claw = nil
    if claw ~= nil and claw:IsValid() then
      claw:Remove()
    end
    return
  end
  if claw == nil or not claw:IsValid() then
    claw = SpawnPrefab("kaltsit_esperanta_mon3tr_claw")
    inst:AddChild(claw)
    claw.Follower:FollowSymbol(inst.GUID, "swap_hat", 0, 120, 0)
    inst._kaltsit_mon3tr_claw = claw
  end
end

local function UpdateBrain(inst)
  local brainfn = not IsPlayerControlled(inst) and brain or nil
  if inst.brainfn ~= brainfn then
    inst:SetBrain(brainfn)
  end
end

local function OnSetOwner(inst)
  UpdateBrain(inst)
  UpdateClaw(inst)
  -- 接管时中止 AI 动作，由对应状态恢复移动、碰撞和动画速度。
  local state = inst.sg.currentstate.name
  if IsPlayerControlled(inst) and (state == "kaltsit_mon3tr_claw_attack"
    or state == "kaltsit_mon3tr_assault" or state == "kaltsit_mon3tr_jump") then
    inst:ClearBufferedAction()
    inst.sg:GoToState("idle")
  end
end

local function SetupPetEnvironment(inst)
  UpdateClaw(inst)
  if IsPlayerControlled(inst) then
    return
  end
  inst:AddTag("immune_stun")
  -- 独立子光源，避免 SGwilson 的电击状态关闭角色自带的 Light。
  local light = SpawnPrefab("yellowamuletlight")
  light.Light:SetRadius(PET_LIGHT_RADIUS)
  light.Light:SetIntensity(0.5)
  light.Light:SetFalloff(0.7)
  light.Light:SetColour(1, 1, 1)
  light.Light:Enable(true)
  inst:AddChild(light)
  light.Transform:SetPosition(0, 0, 0)

  local temperature = inst.components.temperature
  -- SetTemp 阻止环境升降温；上下限也锁定，阻止攻击等直接改温造成过冷过热。
  temperature.mintemp = TUNING.STARTING_TEMP
  temperature.maxtemp = TUNING.STARTING_TEMP
  temperature:SetTemp(TUNING.STARTING_TEMP)
end

local function onbecameghost(inst)
  UpdateClaw(inst)
  if not IsPlayerControlled(inst) then
    -- 原版在 ms_becameghost 返回后仍需访问 player_classified，下一帧再清理。
    inst:DoTaskInTime(0, function()
      if not IsPlayerControlled(inst) and inst:HasAnyTag("playerghost", "corpse") then
        -- AI 死亡兜底同样不播放上下线特效；玩家离开由原版入口处理。
        inst:Remove()
      end
    end)
  end
end

local function CommonPostInit(inst)
  -- Minimap icon
  inst.MiniMapEntity:SetIcon("kaltsit_esperanta_mon3tr.tex")
end

local function MasterPostInit(inst)
  -- inst.soundsname = "wilson"
  -- inst.talker_path_override = "dontstarve_DLC001/characters/kaltsit_esperanta/"

  -- 角色属性
  inst.components.health:SetMaxHealth(TUNING.KALTSIT_ESPERANTA_MON3TR_HEALTH)
  inst.components.locomotor.walkspeed = TUNING.KALTSIT_ESPERANTA_MON3TR_WALK_SPEED
  inst.components.locomotor.runspeed = TUNING.KALTSIT_ESPERANTA_MON3TR_RUN_SPEED
  inst.components.combat:SetDefaultDamage(TUNING.KALTSIT_ESPERANTA_MON3TR_DAMAGE)
  inst.components.hunger:SetMax(TUNING.KALTSIT_ESPERANTA_MON3TR_HUNGER)
  inst.components.hunger.burnratemodifiers:SetModifier("kaltsit_esperanta_mon3tr", -200)
  inst.components.sanity:SetMax(TUNING.KALTSIT_ESPERANTA_MON3TR_SANITY)
  inst.components.sanity.externalmodifiers:SetModifier("kaltsit_esperanta_mon3tr", 200)

  inst:AddComponent("ark_skill")
  for _, skill in ipairs(TUNING.KALTSIT_MON3TR_SKILLS) do
    inst.components.ark_skill:AddSkill(skill.id)
  end

  inst:AddComponent("follower")
  inst.components.follower:KeepLeaderOnAttacked()
  inst.components.follower.keepdeadleader = true

  inst:AddComponent("kaltsit_mon3tr_behavior")
  -- Network 的 owner 已更新时，userid 字段的 setowner 回调可能尚未执行。
  inst:ListenForEvent("setowner", OnSetOwner)
  UpdateBrain(inst)
  -- 等 setowner 与读档组件恢复完成后，再区分玩家和 AI 宠物。
  inst:DoTaskInTime(0, SetupPetEnvironment)

  -- 灵魂状态变化
  inst:ListenForEvent("ms_becameghost", onbecameghost)
end

return MakePlayerCharacter("kaltsit_esperanta_mon3tr", prefabs, assets, CommonPostInit, MasterPostInit, start_inv)
