local COMMANDS = require("mon3tr_command_defs")

local assets = {
  Asset("ANIM", "anim/kaltsit_calcite.zip"),
  Asset("ATLAS", "images/inventoryimages/kaltsit_calcite.xml"),
}

RegisterInventoryItemAtlas("images/inventoryimages/kaltsit_calcite.xml", "kaltsit_calcite.tex")

local SPELLBOOK_RADIUS = 100
local EMPTY_TABLE = {}

local function CLIENT_OnOpenSpellBook(_)
end
local function CLIENT_OnCloseSpellBook(_)
end

local function GetMon3trIntellectMax(owner)
  if owner ~= nil and owner.replica.kaltsit_intellect ~= nil then
    return owner.replica.kaltsit_intellect.state.max or 1
  end
  return 1
end

local function updatespells(inst, owner)
  if owner then
    if owner.HUD then owner.HUD:CloseSpellWheel() end
    local intellect_max = GetMon3trIntellectMax(owner)
    ArkLogger:Debug("Updating spells for owner", owner, "intellect_max", intellect_max)
    local items = COMMANDS.GetCommands(intellect_max)
    for i, item in ipairs(items) do
      ArkLogger:Debug(" - ", i, item.id)
    end
    inst.components.spellbook:SetItems(COMMANDS.GetCommands(intellect_max))
  else
    ArkLogger:Debug("No owner, clearing spells")
    inst.components.spellbook:SetItems(EMPTY_TABLE)
  end
end

local function OnOwnerUpdated(inst, owner)
  if owner ~= nil and owner.components.container ~= nil then
    -- We've been moved from an equipped backpack into a different container.
    if inst._container ~= nil and
        owner ~= inst._container and
        (inst._container.components.equippable ~= nil and inst._container.components.equippable:IsEquipped())
    then
      inst:RemoveEventCallback("unequipped", inst._onunequipped, inst._container)
    end

    inst._container = owner

    local grandowner = owner.components.inventoryitem ~= nil and owner.components.inventoryitem:GetGrandOwner()

    -- We've been put on an already equipped backpack.
    if owner.components.equippable ~= nil and owner.components.equippable:IsEquipped() and grandowner ~= nil then
      owner = grandowner

      inst:ListenForEvent("unequipped", inst._onunequipped, inst._container)

      -- We've been put on an unnequipped backpack.
    elseif owner.components.equippable ~= nil then
      inst:ListenForEvent("equipped", inst._onequipped, inst._container)
    else
      -- We're in a chest likely
      owner = nil
    end

    -- We've been dropped or put on a regular inventory.
  elseif inst._container ~= nil then
    if inst._container.components.equippable ~= nil and inst._container.components.equippable:IsEquipped() then
      inst:RemoveEventCallback("unequipped", inst._onunequipped, inst._container)
    end

    inst._container = nil
  end

  if owner ~= nil and owner ~= inst._owner then
    if inst._owner ~= nil and not inst._owner:HasTag("backpack") then
      -- inst:RemoveEventCallback("onactivateskill_server", inst._onskillrefresh_server, inst._owner)
      -- inst:RemoveEventCallback("ondeactivateskill_server", inst._onskillrefresh_server, inst._owner)
      inst:RemoveEventCallback("mon3tr_master_summoncomplete", inst._onsummonstatechanged_server, inst._owner)
      inst:RemoveEventCallback("mon3tr_master_recallcomplete", inst._onsummonstatechanged_server, inst._owner)
      inst:RemoveEventCallback("kaltsit_elite_up", inst._onsummonstatechanged_server, inst._owner) -- 移除精英晋升事件监听
    end

    inst._owner = owner

    inst._updatespells:push()
    updatespells(inst, inst._owner)

    if not inst._owner:HasTag("backpack") then
      -- inst:ListenForEvent("onactivateskill_server", inst._onskillrefresh_server, owner)
      -- inst:ListenForEvent("ondeactivateskill_server", inst._onskillrefresh_server, owner)
      inst:ListenForEvent("mon3tr_master_summoncomplete", inst._onsummonstatechanged_server, owner)
      inst:ListenForEvent("mon3tr_master_recallcomplete", inst._onsummonstatechanged_server, owner)
      inst:ListenForEvent("kaltsit_elite_up", inst._onsummonstatechanged_server, owner) -- 监听精英晋升事件，更新技能列表
    end
  elseif not owner and inst._owner then
    if not inst._owner:HasTag("backpack") then
      -- inst:RemoveEventCallback("onactivateskill_server", inst._onskillrefresh_server, inst._owner)
      -- inst:RemoveEventCallback("ondeactivateskill_server", inst._onskillrefresh_server, inst._owner)
      inst:RemoveEventCallback("mon3tr_master_summoncomplete", inst._onsummonstatechanged_server, inst._owner)
      inst:RemoveEventCallback("mon3tr_master_recallcomplete", inst._onsummonstatechanged_server, inst._owner)
      inst:RemoveEventCallback("kaltsit_elite_up", inst._onsummonstatechanged_server, inst._owner) -- 移除精英晋升事件监听
    end

    inst._owner = nil

    inst._updatespells:push()
    updatespells(inst, inst._owner)
  end
end

local function DoClientUpdateSpells(inst, force)
  local owner = (inst.replica.inventoryitem:IsHeld() and ThePlayer) or nil
  local intellect_max = GetMon3trIntellectMax(owner)
  if owner ~= inst._owner or intellect_max ~= inst._intellect_max then
    updatespells(inst, owner)
    inst._owner = owner
    inst._intellect_max = intellect_max
  end
end

local function OnUpdateSpellsDirty(inst)
  inst:DoTaskInTime(0, DoClientUpdateSpells, true)
end

local function topocket(inst, owner)
  OnOwnerUpdated(inst, owner)
end

local function toground(inst)
  -- 清理容器装备事件监听（物品被放置到地上时）
  if inst._container ~= nil then
    inst:RemoveEventCallback("equipped", inst._on_equipped, inst._container)
    inst:RemoveEventCallback("unequipped", inst._on_unequipped, inst._container)
  end
  inst._container = nil
  OnOwnerUpdated(inst, nil)
end

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

  local spellbook = inst:AddComponent("spellbook")
  spellbook:SetRequiredTag("mon3tr_master_summoned")
  spellbook:SetRadius(SPELLBOOK_RADIUS)
  spellbook:SetFocusRadius(SPELLBOOK_RADIUS)
  spellbook:SetItems(EMPTY_TABLE)
  spellbook:SetOnOpenFn(CLIENT_OnOpenSpellBook)
  spellbook:SetOnCloseFn(CLIENT_OnCloseSpellBook)
  spellbook.opensound = "meta5/wendy/skill_wheel_open"
  spellbook.closesound = "meta5/wendy/skill_wheel_close"
  inst._updatespells = net_event(inst.GUID, "kaltsit_calcite._updatespells")

  inst.entity:SetPristine()

  if not TheWorld.ismastersim then
    inst:ListenForEvent("kaltsit_calcite._updatespells", OnUpdateSpellsDirty)
    OnUpdateSpellsDirty(inst)
    return inst
  end

  inst._onsummonstatechanged_server = function(owner)
    inst._updatespells:push()
    updatespells(inst, owner)
  end

  inst._onelitechanged_server = function(owner, elite)
    inst._updatespells:push()
    updatespells(inst, owner)
  end

  inst:AddComponent("inspectable")

  inst:AddComponent("inventoryitem")
  inst:AddComponent("summoningitem")

  inst:ListenForEvent("onputininventory", topocket)
  inst:ListenForEvent("ondropped", toground)

  -- 容器装备事件的监听回调（在 OnOwnerUpdated 内部按需注册到具体容器）
  inst._on_equipped   = function() OnOwnerUpdated(inst, inst._container) end
  inst._on_unequipped = function() OnOwnerUpdated(inst, inst._container) end
  MakeHauntableLaunch(inst)

  return inst
end

return Prefab("kaltsit_calcite", Fn, assets)
