local Badge = require("widgets/badge")

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

RegisterArkBadge("kaltsit_intellect_badge", function(manager, owner)
  if not owner:HasTag("kaltsit_esperanta") then
    return nil
  end
  local badge = Badge(nil, owner, nil, "kaltsit_intellect_badge")
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
