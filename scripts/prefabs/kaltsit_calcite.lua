local assets = {
	Asset("ANIM", "anim/kaltsit_calcite.zip"),
	Asset("ATLAS", "images/inventoryimages/kaltsit_calcite.xml"),
}

RegisterInventoryItemAtlas("images/inventoryimages/kaltsit_calcite.xml", "kaltsit_calcite.tex")

local function Fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddNetwork()

	MakeInventoryPhysics(inst)
	inst.AnimState:SetBank("kaltsit_calcite")
	inst.AnimState:SetBuild("kaltsit_calcite")
	inst.AnimState:PlayAnimation("idle")

	MakeInventoryFloatable(inst, "small", 0.2, 0.4)
	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	inst:AddComponent("inspectable")

	inst:AddComponent("inventoryitem")

	MakeHauntableLaunch(inst)

	return inst
end

return Prefab("kaltsit_calcite", Fn, assets)
