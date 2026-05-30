local assets = {
	Asset("ANIM", "anim/mon3tr_signboard.zip"),
  Asset("ATLAS", "images/inventoryimages/mon3tr_signboard.xml"),
}
RegisterInventoryItemAtlas("images/inventoryimages/mon3tr_signboard.xml", "mon3tr_signboard.tex")
local function OnHammered(inst, worker)
	if inst.components.lootdropper ~= nil then
		inst.components.lootdropper:DropLoot()
	end

	local x, y, z = inst.Transform:GetWorldPosition()
	local fx = SpawnPrefab("collapse_small")
	if fx ~= nil then
		fx.Transform:SetPosition(x, y, z)
		fx:SetMaterial("metal")
	end

	inst:Remove()
end

local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddLight()
	inst.entity:AddNetwork()

	MakeObstaclePhysics(inst, 0.2)

	inst.AnimState:SetBank("mon3tr_signboard")
	inst.AnimState:SetBuild("mon3tr_signboard")
	inst.AnimState:PlayAnimation("idle", true)
	inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")

	inst.Light:SetFalloff(0.7)
	inst.Light:SetIntensity(0.45)
	inst.Light:SetRadius(1.6)
	inst.Light:SetColour(180 / 255, 225 / 255, 255 / 255)
	inst.Light:Enable(true)

	inst:AddTag("structure")

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	inst:AddComponent("inspectable")

	inst:AddComponent("lootdropper")
	inst.components.lootdropper:SetLoot({ "goldnugget" })

	inst:AddComponent("workable")
	inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
	inst.components.workable:SetWorkLeft(2)
	inst.components.workable:SetOnFinishCallback(OnHammered)

	MakeHauntableWork(inst)

	return inst
end

return Prefab("mon3tr_signboard", fn, assets),
	MakePlacer("mon3tr_signboard_placer", "mon3tr_signboard", "mon3tr_signboard", "idle")
