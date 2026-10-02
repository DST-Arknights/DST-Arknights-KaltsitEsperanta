local function GroundFx(inst)
  inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
  inst.AnimState:SetLayer(LAYER_BACKGROUND)
  inst.AnimState:SetSortOrder(3)
  inst.AnimState:SetFinalOffset(3)
end

local fxs = { {
  name = "special_treatment_bullet_fx_ally",
  bank = "stalker_shield",
  build = "stalker_shield",
  anim = "idle1",
  fn = function(inst)
    inst.AnimState:SetAddColour(0, 0.7, 0, 0.7)
  end,
}, {
  name = "special_treatment_bullet_fx_enemy",
  bank = "stalker_shield",
  build = "stalker_shield",
  anim = "idle1",
  fn = function(inst)
    inst.AnimState:SetAddColour(0.7, 0, 0, 0.7)
  end,
},
{
  name = "special_treatment_bullet_destroy_fx",
  bank = "stalker_shield",
  build = "stalker_shield",
  anim = "idle1",
  fn = function(inst)
    inst.AnimState:SetAddColour(0.7, 0.7, 0, 0.7)
  end,
},
{
  name = "kaltsit_mon3tr_intimidate_fx",
  bank = "mushroombomb_base",
  build = "mushroombomb_base",
  anim = "idle",
  nofaced = true,
  tint = Vector3(0, 0, 0),
  tintalpha = .5,
  -- 原版暗影陷阱：6 单位范围对应 AnimState 的 1.9 倍缩放。
  transform = Vector3(1.9, 1.9, 1.9),
  fn = GroundFx,
},
{
  name = "kaltsit_esperanta_skill1_range_fx",
  bank = "winona_catapult_placement",
  build = "winona_catapult_placement",
  anim = "idle_16d6",
  nofaced = true,
  bloom = true,
  -- 原版范围圈：16.6 单位范围对应 AnimState 的 1.5 倍缩放。
  transform = Vector3(1.5, 1.5, 1.5),
  ping = { duration = .5, scaleup = 1.036 },
  fn = function(inst)
    inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGroundFixed)
    inst.AnimState:SetLayer(LAYER_WORLD_BACKGROUND)
    inst.AnimState:SetSortOrder(3)
    inst.AnimState:SetLightOverride(1)
  end,
}
}

local results = {}
for i, v in ipairs(fxs) do
  table.insert(results, ArkMakeFx(v))
end

return unpack(results)
