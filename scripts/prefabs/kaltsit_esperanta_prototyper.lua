local TechTree = require("techtree")

local function GetTreesForLevel(level)
  if level == 2 then
    return TUNING.PROTOTYPER_TREES.KALTSIT_INTELLECT_1
  elseif level == 3 then
    return TUNING.PROTOTYPER_TREES.KALTSIT_INTELLECT_2
  end

  return TUNING.PROTOTYPER_TREES.KALTSIT_INTELLECT_0
end

local function GetMergedPrototyper(inst)
  local target = inst._merged_prototyper
  return target ~= nil
      and target:IsValid()
      and target.components.prototyper ~= nil
      and target
    or nil
end

local function RebuildTrees(inst)
  local target = GetMergedPrototyper(inst)
  local target_trees = target ~= nil and target.components.prototyper.trees or nil
  local trees = inst.components.prototyper.trees

  for _, tech in ipairs(TechTree.AVAILABLE_TECH) do
    trees[tech] = math.max(inst._base_trees[tech] or 0, target_trees ~= nil and target_trees[tech] or 0)
  end

  inst.components.prototyper.trees = trees
end

local function SetLevel(inst, level)
  inst._base_trees = GetTreesForLevel(level)
  RebuildTrees(inst)
end

local function SetMergedPrototyper(inst, target)
  inst._merged_prototyper = target
  RebuildTrees(inst)
end

local function OnActivate(inst, doer, recipe)
  local target = GetMergedPrototyper(inst)
  if target ~= nil then
    target.components.prototyper:Activate(doer, recipe)
  end
end

local function fn()
  local inst = CreateEntity()

  inst.entity:AddTransform()
  inst.entity:AddNetwork()

  inst:AddTag("prototyper")
  inst:AddTag("ancient_station")
  inst:AddTag("celestial_station")
  inst:AddTag("lunar_forge")
  inst:AddTag("shadow_forge")
  inst:AddTag("carpentry_station")
  inst:AddTag("hermitcrab")
  inst:AddTag("NOCLICK")
  inst:AddTag("kaltsit_esperanta_prototyper")

  inst.entity:SetPristine()

  if not TheWorld.ismastersim then
    return inst
  end

  inst.persists = false
  inst.SetLevel = SetLevel
  inst.SetMergedPrototyper = SetMergedPrototyper

  inst:AddComponent("prototyper")
  inst._base_trees = GetTreesForLevel(1)
  inst.components.prototyper.onactivate = OnActivate
  RebuildTrees(inst)

  -- Proxy station-only recipes from the one external prototyper currently merged in.
  inst:AddComponent("craftingstation")
  inst.components.craftingstation.nosave = true

  ArkHookFunction(inst.components.craftingstation, "GetRecipes", function(next, self, ...)
    local target = GetMergedPrototyper(inst)
    local station = target ~= nil and target.components.craftingstation or nil
    if station ~= nil then
      return station:GetRecipes(...)
    end
    return next(self, ...)
  end)

  ArkHookFunction(inst.components.craftingstation, "KnowsRecipe", function(next, self, recipe, ...)
    local target = GetMergedPrototyper(inst)
    local station = target ~= nil and target.components.craftingstation or nil
    if station ~= nil then
      return station:KnowsRecipe(recipe, ...)
    end
    return next(self, recipe, ...)
  end)

  ArkHookFunction(inst.components.craftingstation, "GetRecipeCraftingLimit", function(next, self, recipe, ...)
    local target = GetMergedPrototyper(inst)
    local station = target ~= nil and target.components.craftingstation or nil
    if station ~= nil then
      return station:GetRecipeCraftingLimit(recipe, ...)
    end
    return next(self, recipe, ...)
  end)

  return inst
end

return Prefab("kaltsit_esperanta_prototyper", fn)
