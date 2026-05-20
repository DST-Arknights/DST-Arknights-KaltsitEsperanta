local Badge = require("widgets/badge")
local ImageButton = require "widgets/imagebutton"

table.insert(Assets, Asset("ANIM", "anim/kaltsit_intellect_badge.zip"))

AddCharacterIngredient("kaltsit_intellect", {
  Has = function(inst, amount)
    local replica = inst.replica.kaltsit_intellect
    local current = replica and replica.state.current or 0
    return current >= amount, current
  end,
  Consume = function(inst, amount)
    if inst.components.kaltsit_intellect then
      inst.components.kaltsit_intellect:Delta(-amount)
    end
  end,
})

AddModRPCHandler("kaltsit_esperanta", "use_next_build_discount", function(player, data)
  if player and player:IsValid() and player.components.kaltsit_intellect then
    player.components.kaltsit_intellect:UseNextBuildDiscount()
  end
end)

RegisterArkBadge("kaltsit_intellect_badge", function(manager, owner)
  if not owner:HasTag("kaltsit_esperanta") then
    return nil
  end
  local badge = Badge(nil, owner, nil, "kaltsit_intellect_badge")  badge._activated = false
  function badge:SetActivate(active)
    active = active == true

    if self._activated == active then
      return
    end

    self._activated = active

    if active then
      self:PulseGreen()
      self:StartWarning(0.45, 0.85, 1.0, 1.0)
    else
      self:StopWarning()
    end
  end


  badge.click_hitbox = badge:AddChild(ImageButton(
    "images/ui.xml",
    "blank.tex",
    "blank.tex",
    "blank.tex",
    nil,
    nil,
    { 1, 1 },
    { 0, 0 }
  ))
  badge.click_hitbox:SetPosition(0, 0)
  badge.click_hitbox:ForceImageSize(80, 80)
  badge.click_hitbox:SetImageNormalColour(1, 1, 1, 0)
  badge.click_hitbox:SetImageFocusColour(1, 1, 1, 0)
  badge.click_hitbox:SetImageSelectedColour(1, 1, 1, 0)
  badge.click_hitbox:SetOnClick(function()
    local intellect = owner.replica.kaltsit_intellect or nil
    if intellect ~= nil then
      intellect:UseNextBuildDiscount()
    end
  end)

  badge:SetActivate(false)
  return badge
end)

-- 路径一：篝火/烤肉叉等即时烹饪（cooker 组件）
AddComponentPostInit("cooker", function(self)
  ArkHookFunction(self, "CookItem", function(next, self, item, chef)
    local newitem = next(self, item, chef)
    if newitem ~= nil and chef ~= nil and chef:IsValid() then
      chef:PushEvent("char_cooked_item", { item = newitem, cooker = self.inst })
    end
    return newitem
  end)
end)

local dostew_patched = false
-- 路径二：烹饪锅/便携锅，玩家取出时（stewer 组件）
AddComponentPostInit("stewer", function(self)
  if dostew_patched then
    return
  end
  local ok, _dostew = ArkGetUpvalue(self.StartCooking, "dostew", {
    file = "components/stewer.lua",
  })
  if not ok then
    ArkLogger:Error("Failed to get upvalue 'dostew' from stewer StartCooking")
    return
  end
  ArkLogger:Debug("Hooking stewer dostew", _dostew)
  if _dostew ~= nil then
    local ok = ArkSetUpvalue(self.StartCooking, "dostew", function(inst, self)
      local player = UserToPlayer(self.chef_id)
      if player and player:IsValid() then
        player:PushEvent("char_stew_done", { product = self.product, cooker = inst })
      end
      _dostew(inst, self)
      -- 给制作者发事件
    end, {
      file = "components/stewer.lua",
    })
    if ok then
      ArkLogger:Debug("Successfully hooked stewer dostew")
      dostew_patched = true
    else
      ArkLogger:Error("Failed to hook stewer dostew")
    end
  end
end)

-- 处理绿宝石, 优先使用凯尔希智识的折扣
AddPrefabPostInit("greenamulet", function(inst)
  ArkHookFunction(inst.components.equippable, "onequipfn", function(next, inst, owner, from_ground)
    next(inst, owner, from_ground)
    local onitembuild = inst.onitembuild
    inst:RemoveEventCallback("consumeingredients", onitembuild, owner)
    inst.onitembuild = function(owner, data)
      inst:DoTaskInTime(0, function()
        if data and data.kaltsit_intellect_discount_used then
          return
        end
        onitembuild(owner, data)
      end)
    end
    inst:ListenForEvent("consumeingredients", inst.onitembuild, owner)
  end)
end)
