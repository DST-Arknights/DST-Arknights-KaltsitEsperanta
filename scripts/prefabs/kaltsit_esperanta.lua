local MakePlayerCharacter = require "prefabs/player_common"
local assets =
{
  Asset("ATLAS", "images/map_icons/kaltsit_esperanta.xml"),
  Asset("ATLAS", "bigportraits/kaltsit_esperanta.xml"),
  Asset("ATLAS", "images/saveslot_portraits/kaltsit_esperanta.xml"),
  Asset("ATLAS", "images/selectscreen_portraits/kaltsit_esperanta.xml"),
  Asset("ATLAS", "images/selectscreen_portraits/kaltsit_esperanta_silho.xml"),
  Asset("ATLAS", "images/avatars/avatar_kaltsit_esperanta.xml"),
  Asset("ATLAS", "images/avatars/avatar_ghost_kaltsit_esperanta.xml"),
  Asset("ATLAS", "images/avatars/self_inspect_kaltsit_esperanta.xml"),
  Asset("ATLAS", "images/names_kaltsit_esperanta.xml"),
  Asset("ATLAS", "images/names_gold_kaltsit_esperanta.xml"),
}

local start_inv = {}
local prefabs = FlattenTree(start_inv, true)


-- When the character is revived from human
local function onbecamehuman(inst)
  -- Set speed when not a ghost (optional)
end

local function onbecameghost(inst)
  -- Remove speed modifier when becoming a ghost
end

-- When loading or spawning the character
local function Onload(inst)
  inst:ListenForEvent("ms_respawnedfromghost", onbecamehuman)
  inst:ListenForEvent("ms_becameghost", onbecameghost)

  if inst:HasTag("playerghost") then
    onbecameghost(inst)
  else
    onbecamehuman(inst)
  end
end

-- This initializes for both the server and client. Tags can be added here.
local CommonPostInit = function(inst)
  -- Minimap icon
  inst.MiniMapEntity:SetIcon("kaltsit_esperanta.tex")
  inst:AddTag("ark_character")
end

-- This initializes for the server only. Components are added here.
local masterPostInit = function(inst)
  -- choose which sounds this character will play
  inst.talksoundoverride = "kaltsit_esperanta/jp/talk_LP"

  -- Uncomment if "wathgrithr"(Wigfrid) or "webber" voice is used
  -- inst.talker_path_override = "dontstarve_DLC001/characters/"

  -- Stats	
  inst.components.health:SetMaxHealth(TUNING.KALTSIT_ESPERANTA_HEALTH)
  inst.components.hunger:SetMax(TUNING.KALTSIT_ESPERANTA_HUNGER)
  inst.components.sanity:SetMax(TUNING.KALTSIT_ESPERANTA_SANITY)

  -- Skills
  inst:AddComponent("ark_skill")
  inst:AddComponent("ark_currency")
  inst:AddComponent("i18n_talker")
  inst.OnLoad = Onload
end

return MakePlayerCharacter("kaltsit_esperanta", prefabs, assets, CommonPostInit, masterPostInit, start_inv)
