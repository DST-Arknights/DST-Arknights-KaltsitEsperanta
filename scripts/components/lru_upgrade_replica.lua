-- 生命修复单元 容器格子升级 replica(客户端)
-- 照抄工坊 2484725102 的 chestupgrade_replica: net 同步格子尺寸, 客户端 UpdateWidget 改 replica widget。
local function OnChestLvDirty(inst)
  local lru_upgrade = inst.replica.lru_upgrade
  lru_upgrade.chestlv.x = lru_upgrade.net_clvx:value() or 2
  lru_upgrade.chestlv.y = lru_upgrade.net_clvy:value() or 6
  lru_upgrade:UpdateWidget()
end

local LruUpgrade = Class(function(self, inst)
  self.inst = inst
  self.baselv = Vector3(2, 6, 1)
  self.chestlv = Vector3(2, 6, 1)

  self.net_clvx = net_byte(inst.GUID, "lru_upgrade.clvx", "lru_upgrade_clvdirty")
  self.net_clvy = net_byte(inst.GUID, "lru_upgrade.clvy", "lru_upgrade_clvdirty")

  if not TheWorld.ismastersim then
    inst:ListenForEvent("lru_upgrade_clvdirty", OnChestLvDirty)
  end
end)

function LruUpgrade:GetLv()
  return self.chestlv.x, self.chestlv.y
end

function LruUpgrade:SetChestLv(chestlv)
  self.chestlv = chestlv
  self.net_clvx:set(chestlv.x)
  self.net_clvy:set(chestlv.y)
end

-- 客户端直接改 replica.container.widget + SetNumSlots + InitializeSlots(照抄 chestupgrade_replica)
local function ModCompat(container, widget)
  container.widget = widget
  container:SetNumSlots(widget.slotpos ~= nil and #widget.slotpos or 0)
  if container.classified ~= nil then
    container.classified:InitializeSlots(container:GetNumSlots())
  end
end

-- 背包背景 ui_backpack_2x4 固有 4 行, 按当前格子行数向下拉长
local BGBASE_Y = 4

function LruUpgrade:UpdateWidget()
  local container = self.inst.replica.container
  if container == nil then
    return
  end
  local lv_x, lv_y = self:GetLv()

  local widget = setmetatable({}, { __index = container.widget })
  if container.issidewidget then
    -- 侧边背包样式(穿戴在身上, 左对齐 2 列)
    widget.slotpos = {}
    for y = 0, lv_y - 1 do
      for x = 0, lv_x - 1 do
        table.insert(widget.slotpos, Vector3(-162 + 75 * x, -75 * y + 114, 0))
      end
    end
  else
    local sep = Vector3(75, 75)
    local init_x = -(lv_x + 1) * math.floor(sep.x / 2)
    local init_y = -(lv_y + 1) * math.floor(sep.y / 2)
    widget.slotpos = {}
    for y = lv_y, 1, -1 do
      for x = 1, lv_x do
        table.insert(widget.slotpos, Vector3(x * sep.x + init_x, y * sep.y + init_y, 0))
      end
    end
  end

  -- 背景向下拉长: 顶部对齐第一行槽位, 随行数缩放
  widget.bgscale = Vector3(1, lv_y / BGBASE_Y, 1)
  widget.bgshift = Vector3(0, (BGBASE_Y - lv_y) * 37.5, 0)

  ModCompat(container, widget)
end

return LruUpgrade
