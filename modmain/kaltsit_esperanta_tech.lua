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

local PROTOTYPER_TAGS = { "prototyper" }

local function CanUseExternalPrototyper(builder, inst)
    return inst ~= nil
        and inst:IsValid()
        and inst:HasTags(PROTOTYPER_TAGS)
        and not inst:HasOneOfTags(builder.exclude_tags)
        and not inst:HasTag("kaltsit_esperanta_prototyper")
        and inst.components.prototyper ~= nil
        and (inst.components.prototyper.restrictedtag == nil
            or builder.inst:HasTag(inst.components.prototyper.restrictedtag))
        and builder.inst:IsNear(inst, TUNING.RESEARCH_MACHINE_DIST)
end

local function FindExternalPrototyper(builder)
    local x, y, z = builder.inst.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x, y, z, TUNING.RESEARCH_MACHINE_DIST, { "prototyper" }, builder.exclude_tags)

    for _, ent in ipairs(ents) do
        if CanUseExternalPrototyper(builder, ent) then
            -- FindEntities is distance ordered; vanilla builder also uses the first valid station.
            return ent
        end
    end
end

local function SetExternalPrototyper(builder, intellect, external)
    local old_external = builder._kaltsit_merged_prototyper
    if old_external ~= external then
        if old_external ~= nil
            and old_external:IsValid()
            and old_external.components.prototyper ~= nil then
            old_external.components.prototyper:TurnOff(builder.inst)
        end
        if external ~= nil then
            external.components.prototyper:TurnOn(builder.inst)
        end
        builder._kaltsit_merged_prototyper = external
    end

    intellect:SetMergedPrototyper(external)
end

AddClassPostConstruct("components/builder_replica", function(self)
    ArkHookFunction(self, "OpenCraftingMenu", function(next, ...)
        local builder = self.inst.components.builder
        if builder ~= nil and builder._kaltsit_auto_override_running then
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
        local enabled = self.inst.player_classified == nil
            or self.inst.player_classified.iscraftingenabled:value()
        local intellect = self.inst.prototyper_ent
        if intellect == nil
            or not intellect:IsValid()
            or intellect.components.prototyper == nil then
            return next(self)
        end

        if not enabled then
            self._kaltsit_requested_prototyper = nil
            SetExternalPrototyper(self, intellect, nil)
            return next(self)
        end

        local requested = self.override_current_prototyper
        local requested_external = CanUseExternalPrototyper(self, requested) and requested or nil
        if requested == nil then
            self._kaltsit_requested_prototyper = nil
        elseif requested_external ~= nil then
            self._kaltsit_requested_prototyper = requested_external
        elseif not CanUseExternalPrototyper(self, self._kaltsit_requested_prototyper) then
            self._kaltsit_requested_prototyper = nil
        end

        local external = self._kaltsit_requested_prototyper or FindExternalPrototyper(self)
        SetExternalPrototyper(self, intellect, external)
        self.override_current_prototyper = intellect
        self._kaltsit_auto_override_running = true

        local ok, err = xpcall(function()
            return next(self)
        end, debug.traceback)

        self._kaltsit_auto_override_running = false

        if not ok then
            error(err)
        end

        if requested_external ~= nil then
            self.inst.replica.builder:OpenCraftingMenu()
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


AddCharacterRecipe(
    "mon3tr_signboard",
    { Ingredient("goldnugget", 3) },
    TECH.NONE,
    { placer = "mon3tr_signboard_placer" },
    { "CHARACTER", "MODS", "STRUCTURES", "LIGHT" }
)

-- 召唤石
-- AddCharacterRecipe("kaltsit_calcite", {
--     Ingredient("kaltsit_intellect", 10),
-- }, TECH.NONE, {
--     builder_tag = "kaltsit_esperanta",
-- })

-- 10齿轮, 10绿宝石, 100铥矿
AddCharacterRecipe("life_repairing_units", {
    Ingredient("gears", 10),
    Ingredient("greengem", 10),
    Ingredient("thulecite", 100),
}, TECH.NONE, {
    builder_tag = "kaltsit_esperanta",
    no_deconstruction = true,
})

-- Mon3tr 手持玩偶: 2月球环形山地皮 + 2牛毛 + 2蜘蛛丝
AddCharacterRecipe("mon3tr_handheld_doll", {
    Ingredient("turf_meteor", 2),
    Ingredient("beefalowool", 2),
    Ingredient("silk", 2),
}, TECH.NONE, {
    builder_tag = "kaltsit_esperanta",
})
