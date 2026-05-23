local easing = require("easing")
local MakePlayerCharacter = require "prefabs/player_common"
local assets =
{
  Asset("ATLAS", "images/map_icons/kaltsit_esperanta.xml"),
  Asset("ATLAS", "bigportraits/kaltsit_esperanta.xml"),
  Asset("ATLAS", "images/saveslot_portraits/kaltsit_esperanta.xml"),
  Asset("ATLAS", "images/selectscreen_portraits/kaltsit_esperanta.xml"),
  Asset("ATLAS", "images/selectscreen_portraits/kaltsit_esperanta_silho.xml"),
  Asset("ATLAS", "images/avatars/avatar_kaltsit_esperanta.xml"),
  Asset("ATLAS", "images/avatars/avatar_ghost_kaltsit_esperanta.xml"),
  Asset("ATLAS", "images/avatars/self_inspect_kaltsit_esperanta.xml"),
  Asset("ATLAS", "images/names_kaltsit_esperanta.xml"),
  Asset("ATLAS", "images/names_gold_kaltsit_esperanta.xml"),
}

local start_inv = {
  "special_treatment_gun",
  "norm_heal_bullet",
  "norm_heal_bullet",
  "norm_heal_bullet",
  "norm_heal_bullet",
  "norm_heal_bullet",
  "norm_heal_bullet",
  "norm_heal_bullet",
  "norm_heal_bullet",
  "norm_heal_bullet",
  "norm_heal_bullet", }
local prefabs = FlattenTree(start_inv, true)

local function CustomFoodStatsMod(inst, health_delta, hunger_delta, sanity_delta, food, feeder)
  if food.prefab == "seafoodgumbo" then
    sanity_delta = sanity_delta + 15
  end
  return health_delta, hunger_delta, sanity_delta
end

local function SetPrototyperLevel(inst, level)
  if not inst.prototyper_ent then
    return
  end
  inst.prototyper_ent:SetLevel(level)
end

local function OnApplyElite(inst, elite_level)
  -- 科技站
  SetPrototyperLevel(inst, elite_level)
end

-- When the character is revived from human
local function onbecamehuman(inst)
  -- Set speed when not a ghost (optional)
end

local function onbecameghost(inst)
  -- Remove speed modifier when becoming a ghost
end


-- When loading or spawning the character
local function Onload(inst)
  inst:ListenForEvent("ms_respawnedfromghost", onbecamehuman)
  inst:ListenForEvent("ms_becameghost", onbecameghost)

  if inst:HasTag("playerghost") then
    onbecameghost(inst)
  else
    onbecamehuman(inst)
  end
end

-- This initializes for both the server and client. Tags can be added here.
local CommonPostInit = function(inst)
  -- Minimap icon
  inst.MiniMapEntity:SetIcon("kaltsit_esperanta.tex")
  inst:AddTag("ark_character")
  inst:AddTag("kaltsit_esperanta")
  inst:AddTag("kaltsit_prototyper_no_priority")
  inst:AddTag("bookbuilder")
  inst:AddTag("reader")
  inst:AddTag("handyperson")
  inst:AddTag("kelshi_spotlight_builder")
  inst:AddTag("kelshi_spotlight_heated")
  inst:AddTag("kelshi_spotlight_ranged")
end

-- This initializes for the server only. Components are added here.
local masterPostInit = function(inst)
  -- choose which sounds this character will play
  inst.talksoundoverride = "kaltsit_esperanta/jp/talk_LP"

  -- Uncomment if "wathgrithr"(Wigfrid) or "webber" voice is used
  -- inst.talker_path_override = "dontstarve_DLC001/characters/"

  -- Stats	
  inst.components.health:SetMaxHealth(TUNING.KALTSIT_ESPERANTA_HEALTH)
  inst.components.hunger:SetMax(TUNING.KALTSIT_ESPERANTA_HUNGER)
  inst.components.sanity:SetMax(TUNING.KALTSIT_ESPERANTA_SANITY)

  -- 海鲜牛排+15 sanitydelta
  inst.components.eater.custom_stats_mod_fn = CustomFoodStatsMod

  -- 潮湿双倍温度负面效果
  inst.components.temperature.maxmoisturepenalty = inst.components.temperature.maxmoisturepenalty * 2
  -- 潮湿双倍精神负面效果
  inst.components.sanity.custom_rate_fn = function(inst2, dt)
    -- 再加一倍的 moisture_delta（等于总效果×2）
    return easing.inSine(
      inst2.components.moisture:GetMoisture(),
      0,
      TUNING.MOISTURE_SANITY_PENALTY_MAX,
      inst2.components.moisture:GetMaxMoisture()
    )
  end

  -- 去掉移速减益
  ArkHookFunction(inst.components.locomotor, "SetExternalSpeedMultiplier", function(next, self, source, key, m)
    if m ~= nil and m < 1 then
      m = 1
    end
    return next(self, source, key, m)
  end)
  -- 不会滑倒
  inst.components.locomotor.threshold = math.huge

  -- 理智影响减半
  inst.components.sanity.rate_modifier = 0.5
  -- Skills
  inst:AddComponent("ark_skill")
  inst:AddComponent("ark_currency")
  inst:AddComponent("i18n_talker")
  -- prototyper
  -- inst:AddComponent("prototyper")
  -- inst.components.prototyper.trees = TUNING.PROTOTYPER_TREES.KALTSIT_INTELLECT_0
  local ent = SpawnPrefab("kaltsit_esperanta_prototyper")
  ent.entity:SetParent(inst.entity)
  ent.Transform:SetPosition(0, 0, 0)

  inst.prototyper_ent = ent
  -- 智识
  inst:AddComponent("kaltsit_intellect")
  inst.components.kaltsit_intellect:SetOnApplyElite(OnApplyElite)

  -- 读书
  inst:AddComponent("reader")

  -- 亲和
  inst:DoPeriodicTask(3, function()
    inst:RemoveTag("scarytoprey")
    inst:AddTag("mermdisguise")
  end)

  inst.OnLoad = Onload
end

return MakePlayerCharacter("kaltsit_esperanta", prefabs, assets, CommonPostInit, masterPostInit, start_inv)
