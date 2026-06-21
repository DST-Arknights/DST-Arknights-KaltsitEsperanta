local function post_aoe(inst)
  local out = SpawnPrefab("kaltsit_esperanta_skill3_reticuleaoe_outline")
  out.entity:SetParent(inst.entity)
  out.Transform:SetPosition(0, 0, 0)
end

local function post_aoe_ping(inst)
  local out = SpawnPrefab("kaltsit_esperanta_skill3_reticuleaoeping_outline")
  out.entity:SetParent(inst.entity)
  out.Transform:SetPosition(0, 0, 0)
end

local function resize_outline(inst)
  local scale = TUNING.KALTSIT_ESPERANTA_SKILL3_RANGE / 16.6 * 1.5
  inst.AnimState:SetScale(scale, scale, scale)
end

return ArkMakeReticule("kaltsit_esperanta_skill3_reticuleaoe", "idle_target_1", true, post_aoe),
    ArkMakePing("kaltsit_esperanta_skill3_reticuleaoeping", "idle_target_1", true, 1.1, post_aoe_ping),
    ArkMakeReticule("kaltsit_esperanta_skill3_reticuleaoe_outline", {
      bank = "winona_catapult_placement",
      build = "winona_catapult_placement",
      anim = "idle_16d6",
    }, true, resize_outline),
    ArkMakePing("kaltsit_esperanta_skill3_reticuleaoeping_outline", {
      bank = "winona_catapult_placement",
      build = "winona_catapult_placement",
      anim = "idle_16d6",
    }, true, 1.1, resize_outline)
