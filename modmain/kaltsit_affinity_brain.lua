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