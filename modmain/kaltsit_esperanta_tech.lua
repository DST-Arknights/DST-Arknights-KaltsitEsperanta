table.insert(Assets, Asset("ATLAS", "images/kaltsit_crafting.xml"))

AddTechBranch("KALTSIT_INTELLECT")
AddTechRequirement("KALTSIT_INTELLECT_ONE", "KALTSIT_INTELLECT", 1)
AddPrototyperTree('KALTSIT_INTELLECT_0', {
    SCIENCE = 3,
    MAGIC = 2,
    CARTOGRAPHY = 2,
    SEAFARING = 2,
    BOOKCRAFT = 1,
    KALTSIT_INTELLECT = 1,
})
AddPrototyperTree('KALTSIT_INTELLECT_1', {
    SCIENCE = 3,
    MAGIC = 3,
    CARTOGRAPHY = 2,
    SEAFARING = 2,
    BOOKCRAFT = 1,
    CARPENTRY = 3,
    KALTSIT_INTELLECT = 1,
})
AddPrototyperTree('KALTSIT_INTELLECT_2', {
    SCIENCE = 3,
    MAGIC = 3,
    CARTOGRAPHY = 2,
    SEAFARING = 2,
    BOOKCRAFT = 1,
    CARPENTRY = 3,
    ANCIENT = 4,
    CELESTIAL = 3,
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


local function AddKaltsitIntellectRecipe(product, ingredients)
    local name = product .. "_k"
    AddRecipe2(
        name,
        ingredients,
        TECH.KALTSIT_INTELLECT_ONE,
        { product = product, builder_tag = "kaltsit_esperanta", nounlock = true, numtogive = 1 },
        { "MODS", "CRAFTING_STATION" }
    )
end

-- 注册配方
AddKaltsitIntellectRecipe("greengem", {
    Ingredient("kaltsit_intellect", 10),
    Ingredient("spoiled_food", 400),
})
AddKaltsitIntellectRecipe("opalpreciousgem", {
    Ingredient("kaltsit_intellect", 10),
    Ingredient("redgem", 1),
    Ingredient("bluegem", 1),
    Ingredient("purplegem", 1),
    Ingredient("greengem", 1),
    Ingredient("orangegem", 1),
    Ingredient("yellowgem", 1),
})

AddKaltsitIntellectRecipe("cotl_trinket", {
    Ingredient("kaltsit_intellect", 10),
    Ingredient("redgem", 1),
    Ingredient("dreadstone", 9),
})

AddKaltsitIntellectRecipe("security_pulse_cage", {
    Ingredient("kaltsit_intellect", 20),
    Ingredient("opalpreciousgem", 1),
    Ingredient("moonrocknugget", 9),
    Ingredient("thulecite", 16),
    Ingredient("goldnugget", 25),
})

AddKaltsitIntellectRecipe("chestupgrade_stacksize", {
    Ingredient("kaltsit_intellect", 20),
    Ingredient("hivehat", 1),
    Ingredient("spiderhat", 2),
    Ingredient("bundlewrap", 4),
})

AddKaltsitIntellectRecipe("alterguardianhatshard", {
    Ingredient("kaltsit_intellect", 20),
    Ingredient("opalpreciousgem", 1),
    Ingredient("purebrilliance", 9),
    Ingredient("moonglass", 16),
})

AddKaltsitIntellectRecipe("shadowheart", {
    Ingredient("kaltsit_intellect", 100),
    Ingredient("reviver", 1),
    Ingredient("dreadstone", 9),
    Ingredient("horrorfuel", 16),
    Ingredient("nightmarefuel", 25),
})

AddKaltsitIntellectRecipe("kaltsit_neuro_gel", {
    Ingredient("livinglog", 1),
    Ingredient("moonglass", 10),
    Ingredient("pinecone", 10),
})

AddKaltsitIntellectRecipe("kaltsit_tissue_repair_solvent", {
    Ingredient("reviver", 1),
    Ingredient("forgetmelots", 10),
    Ingredient("pinecone", 10),
})


AddRecipe2(
    "mon3tr_signboard",
    { Ingredient("goldnugget", 3) },
    TECH.NONE,
    { placer = "mon3tr_signboard_placer" },
    { "MODS", "STRUCTURES", "LIGHT" }
)

AddCharacterRecipe("kaltsit_calcite", {
    Ingredient("kaltsit_intellect", 10),
}, TECH.NONE, {
    builder_tag = "kaltsit_esperanta",
})
