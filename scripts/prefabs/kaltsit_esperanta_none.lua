local assets =
{
	Asset( "ANIM", "anim/kaltsit_esperanta.zip" ),
	Asset( "ANIM", "anim/ghost_kaltsit_esperanta_build.zip" ),
}

local skins =
{
	normal_skin = "kaltsit_esperanta",
	ghost_skin = "ghost_kaltsit_esperanta_build",
}

return CreatePrefabSkin("kaltsit_esperanta_none",
{
	base_prefab = "kaltsit_esperanta",
	type = "base",
	assets = assets,
	skins = skins, 
	skin_tags = {"KALTSIT_ESPERANTA", "CHARACTER", "BASE"},
	build_name_override = "kaltsit_esperanta",
	rarity = "Character",
})