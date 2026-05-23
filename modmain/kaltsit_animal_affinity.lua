-- 猪人不再逃跑
local function IsPlayerRunAwayNode(node)
  return node ~= nil
      and node.is_a ~= nil
      and GLOBAL.RunAway ~= nil
      and node:is_a(GLOBAL.RunAway)
      and node.huntertags ~= nil
      and table.contains(node.huntertags, "player")
end

local function AddRunAwayExcludeFn(node, should_exclude)
  if node._ark_runaway_exclude_fns == nil then
    node._ark_runaway_exclude_fns = {}

    local prev_shouldrunfn = node.shouldrunfn
    node.shouldrunfn = function(target, inst)
      for _, fn in ipairs(node._ark_runaway_exclude_fns) do
        if fn(target, inst, node) then
          return false
        end
      end

      if prev_shouldrunfn ~= nil then
        return prev_shouldrunfn(target, inst)
      end

      return true
    end
  end

  table.insert(node._ark_runaway_exclude_fns, should_exclude)
end

local function PatchPigPlayerRunAway(node)
  if node == nil then
    return
  end

  if IsPlayerRunAwayNode(node) and not node._ark_pig_exclude_kaltsit_esperanta then
    node._ark_pig_exclude_kaltsit_esperanta = true

    AddRunAwayExcludeFn(node, function(target, inst, runaway_node)
      return target ~= nil and target:HasTag("kaltsit_esperanta")
    end)
  end

  if node.children ~= nil then
    for _, child in ipairs(node.children) do
      PatchPigPlayerRunAway(child)
    end
  end
end

AddBrainPostInit("pigbrain", function(brain)
  if brain.bt ~= nil and brain.bt.root ~= nil then
    PatchPigPlayerRunAway(brain.bt.root)
  end
end)

-- 鸟类不会飞走
local BirdBrain = require("brains/birdbrain")
local tagsFind, SHOULDFLYAWAY_MUST_TAGS = ArkGetUpvalue(BirdBrain.OnStart, "SHOULDFLYAWAY_MUST_TAGS",
  { file = "brains/birdbrain.lua" })
if tagsFind then
  table.insert(SHOULDFLYAWAY_MUST_TAGS, "kaltsit_esperanta")
end

local function TargetAffinity(inst, target)
  return target ~= nil and target:HasTag("kaltsit_esperanta") and target.replica.combat and
      target.replica.combat:GetTarget() ~= inst
end

-- 兔人不会主动攻击玩家
AddPrefabPostInit("bunnyman", function(inst)
  if inst.replica.combat then
    ArkHookFunction(inst.replica.combat, "CanTarget", function(next, self, target)
      if TargetAffinity(self.inst, target) then
        return false
      end
      return next(self, target)
    end)
  end
end)


-- 系列鱼人

for _, name in ipairs({ "merm", "mermguard", "merm_shadow", "mermguard_shadow", "merm_lunar", "mermguard_lunar" }) do
  AddPrefabPostInit(name, function(inst)
    if inst.components.trader then
      ArkHookFunction(inst.components.trader, "test", function(next, inst, item, giver, count)
        if giver:HasTag("kaltsit_esperanta") then
          return ((item.components.equippable ~= nil and item.components.equippable.equipslot == EQUIPSLOTS.HEAD) or
            (item.components.edible and inst.components.eater and inst.components.eater:CanEat(item)) or
            (item:HasTag("fish") and not (TheWorld.components.mermkingmanager and TheWorld.components.mermkingmanager:IsCandidate(inst))))
        end
        return next(inst, item, giver, count)
      end)
    end
    local findTargetHooked = false
    if not findTargetHooked and inst.replica.combat and inst.components.combat.targetfn then
      ArkReplaceUpvalue(inst.components.combat.targetfn, "FindInvaderFn", function(previous)
        return function(guy, inst)
          if TargetAffinity(inst, guy) then
            return false
          end
          return previous(guy, inst)
        end
      end, { file = "prefabs/merm.lua" })
      findTargetHooked = true
    end
  end)
end
