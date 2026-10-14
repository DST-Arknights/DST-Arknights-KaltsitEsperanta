local function IsMonkeyTrinket(item, curse)
  return curse == "MONKEY" or (item ~= nil and item.prefab == "cursed_monkey_token")
end

local function ClearMonkeyBinding(item, owner)
  local curseditem = item ~= nil and item.components.curseditem or nil
  if curseditem == nil then
    return
  end
  if curseditem.target == owner then
    curseditem.target = nil
  end
  if curseditem.cursed_target == owner then
    curseditem.cursed_target = nil
    item:RemoveTag("applied_curse")
  end
end

local function InstallMonkeyCurseImmunity(inst)
  if not TheWorld.ismastersim or inst.components.cursable == nil then
    return
  end

  local cursable = inst.components.cursable
  -- 原版自动追踪先查询 IsCursable，手动拾取则直接调用 ApplyCurse。
  ArkHookFunction(cursable, "IsCursable", function(next, self, item)
    if IsMonkeyTrinket(item) then
      return false
    end
    return next(self, item)
  end)
  ArkHookFunction(cursable, "ApplyCurse", function(next, self, item, curse)
    if IsMonkeyTrinket(item, curse) then
      ClearMonkeyBinding(item, self.inst)
      return
    end
    return next(self, item, curse)
  end)
  ArkHookFunction(cursable, "ForceOntoOwner", function(next, self, item)
    if IsMonkeyTrinket(item) then
      ClearMonkeyBinding(item, self.inst)
      return
    end
    return next(self, item)
  end)

  inst:ListenForEvent("itemget", function(owner, data)
    if data ~= nil and IsMonkeyTrinket(data.item) then
      ClearMonkeyBinding(data.item, owner)
    end
  end)
end

AddPrefabPostInit("kaltsit_esperanta", InstallMonkeyCurseImmunity)
AddPrefabPostInit("kaltsit_esperanta_mon3tr", InstallMonkeyCurseImmunity)
