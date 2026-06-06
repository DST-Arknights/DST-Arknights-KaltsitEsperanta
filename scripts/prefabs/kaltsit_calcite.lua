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
    inst.components.spellbook:SetItems(COMMANDS.GetCommands(intellect_max))
  else
    inst.components.spellbook:SetItems(EMPTY_TABLE)
  end
end

local function OnOwnerUpdated(inst, owner)
  -- 第一步：找到 **真正能使用花的人**
  local real_owner = nil
  if owner ~= nil then
    if owner.components.inventoryitem ~= nil then
      -- owner 是容器/背包 → 递归查到最终人类持有者
      real_owner = owner.components.inventoryitem:GetGrandOwner()
    else
      -- owner 是玩家 → 直接用
      real_owner = owner
    end
  end

  -- 第二步：如果 real_owner 是背包（未装备状态）→ 视为无持有者
  if real_owner ~= nil and real_owner:HasTag("backpack") then
    real_owner = nil
  end

  -- 第三步：如果持有者没变，直接返回
  if real_owner == inst._owner then
    return
  end

  -- 第四步：解绑旧持有者的事件监听
  if inst._owner ~= nil then
    inst:RemoveEventCallback("mon3tr_master_summoncomplete", inst._onsummonstatechanged_server, inst._owner)
    inst:RemoveEventCallback("mon3tr_master_recallcomplete", inst._onsummonstatechanged_server, inst._owner)
    inst:RemoveEventCallback("intellect_changed", inst._onelitechanged_server, inst._owner)
  end

  -- 第五步：绑定新持有者的事件监听
  inst._owner = real_owner
  if real_owner ~= nil then
    inst:ListenForEvent("mon3tr_master_summoncomplete", inst._onsummonstatechanged_server, real_owner)
    inst:ListenForEvent("mon3tr_master_recallcomplete", inst._onsummonstatechanged_server, real_owner)
    inst:ListenForEvent("intellect_changed", inst._onelitechanged_server, real_owner)
  end

  -- 第六步：刷新法术列表 + 同步到客户端
  inst._updatespells:push()
  updatespells(inst, real_owner)
end

local function DoClientUpdateSpells(inst, force)
  local owner = (inst.replica.inventoryitem:IsHeld() and ThePlayer) or nil
  ArkLogger:Debug("DoClientUpdateSpells", "force", force, "owner", owner, "inst._owner", inst._owner)
  if owner ~= inst._owner then
    updatespells(inst, owner)
    inst._owner = owner
  end
end

local function OnUpdateSpellsDirty(inst)
  inst:DoTaskInTime(0, DoClientUpdateSpells, true)
end

local function topocket(inst, owner)
  -- 取消地面动画定时器...
  OnOwnerUpdated(inst, owner)
end

local function toground(inst)
  -- 启动地面动画定时器...
  OnOwnerUpdated(inst, nil)
end

local function onequipped(inst, container, owner)
  inst:RemoveEventCallback("equipped", inst._onequipped, container)
  OnOwnerUpdated(inst, container)
end

local function onunequipped(inst, container)
  inst:RemoveEventCallback("unequipped", inst._onunequipped, container)
  OnOwnerUpdated(inst, container)
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
  spellbook:SetItems(COMMANDS.GetCommands())
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

  -- 背包事件回调（不变，在 OnOwnerUpdated 内部动态注册/注销）
  inst._onequipped   = function(container, data) onequipped(inst, container, data.owner) end
  inst._onunequipped = function(container, data) onunequipped(inst, container) end
  MakeHauntableLaunch(inst)

  return inst
end

return Prefab("kaltsit_calcite", Fn, assets)
