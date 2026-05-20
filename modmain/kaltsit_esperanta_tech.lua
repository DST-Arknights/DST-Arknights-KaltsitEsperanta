table.insert(Assets, Asset("ATLAS", "images/kaltsit_crafting.xml"))
local TechTree = require('techtree')

local function AddCustomTechBranch(name, allow_bonus)
    name = string.upper(name)
    local lower = string.lower(name)

    if not table.contains(TechTree.AVAILABLE_TECH, name) then
        table.insert(TechTree.AVAILABLE_TECH, name)
    end

    TechTree.AVAILABLE_TECH_BONUS[name] = lower .. "_bonus"
    TechTree.AVAILABLE_TECH_TEMPBONUS[name] = lower .. "_tempbonus"
    TechTree.AVAILABLE_TECH_BONUS_CLASSIFIED[name] = lower .. "bonus"
    TechTree.AVAILABLE_TECH_TEMPBONUS_CLASSIFIED[name] = lower .. "tempbonus"
    TechTree.AVAILABLE_TECH_LEVEL_CLASSIFIED[name] = lower .. "level"

    if allow_bonus and not table.contains(TechTree.BONUS_TECH, name) then
        table.insert(TechTree.BONUS_TECH, name)
    end
end

AddCustomTechBranch("KALTSIT_INTELLECT", false)

TECH.KALTSIT_INTELLECT_ONE = TechTree.Create({
    KALTSIT_INTELLECT = 1,
})

TUNING.PROTOTYPER_TREES.KALTSIT_INTELLECT_0 = TechTree.Create({
    SCIENCE = 3,
    CARTOGRAPHY = 2,
    SEAFARING = 2,
    BOOKCRAFT = 1,
    MADSCIENCE = 1,
    KALTSIT_INTELLECT = 1,
})

TUNING.PROTOTYPER_TREES.KALTSIT_INTELLECT_1 = TechTree.Create({
    SCIENCE = 3,
    MAGIC = 3,
    CARTOGRAPHY = 2,
    SEAFARING = 2,
    BOOKCRAFT = 1,
    MADSCIENCE = 1,
    CARPENTRY = 3,
    KALTSIT_INTELLECT = 1,
})

TUNING.PROTOTYPER_TREES.KALTSIT_INTELLECT_2 = TechTree.Create({
    SCIENCE = 3,
    MAGIC = 3,
    ANCIENT = 4,
    CELESTIAL = 3,
    CARTOGRAPHY = 2,
    SEAFARING = 2,
    BOOKCRAFT = 1,
    MADSCIENCE = 1,
    CARPENTRY = 3,
    KALTSIT_INTELLECT = 1,
})


AddPrototyperDef("kaltsit_esperanta_prototyper", {
    icon_atlas = "images/kaltsit_crafting.xml",
    icon_image = "station_intellect.tex",
    is_crafting_station = true,
    filter_text = STRINGS.UI.CRAFTING_FILTERS.KALTSIT_INTELLECT,
    skip_default_station_focus = true,
})

local function CanBeOverrideTarget(builder, inst)
    return inst.components.prototyper ~= nil
        and not inst:HasTag("kaltsit_esperanta_prototyper")
        and (inst.components.prototyper.restrictedtag == nil or builder.inst:HasTag(inst.components.prototyper.restrictedtag))
end

local function FindNearestRealPrototyper(builder)
    local x, y, z = builder.inst.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x, y, z, TUNING.RESEARCH_MACHINE_DIST, { "prototyper" }, builder.exclude_tags)

    local best = nil
    local best_dist = nil

    for _, ent in ipairs(ents) do
        if CanBeOverrideTarget(builder, ent) then
            local dist = builder.inst:GetDistanceSqToInst(ent)
            if best == nil or dist < best_dist then
                best = ent
                best_dist = dist
            end
        end
    end

    return best
end

AddClassPostConstruct("components/builder_replica", function(self)
    ArkHookFunction(self, "OpenCraftingMenu", function(next, ...)
        if self.inst.components.builder._kaltsit_auto_override_running then
            return
        end
        return next(...)
    end)
end)

AddComponentPostInit("builder", function(self)
    if not self.inst:HasTag("kaltsit_prototyper_no_priority") then
        return
    end
    ArkHookFunction(self, "EvaluateTechTrees", function(next, self)
        local auto_target = nil

        if self.override_current_prototyper == nil then
            auto_target = FindNearestRealPrototyper(self)
            if auto_target ~= nil then
                self.override_current_prototyper = auto_target
            end
        end

        self._kaltsit_auto_override_running = auto_target ~= nil

        local ok, err = xpcall(function()
            return next(self)
        end, debug.traceback)

        self._kaltsit_auto_override_running = false

        if not ok then
            error(err)
        end
    end)
end)
