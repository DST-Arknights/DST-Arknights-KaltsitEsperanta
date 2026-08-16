-- 生命修复单元 容器格子升级组件(服务端)
-- 照抄工坊 2484725102 (Upgradeable Chest) 的 chestupgrade 机制:
-- 不切容器定义, 而是动态生成 widget.slotpos, 用 ModCompat 直接改 container.widget + numslots。
-- 命名用 lru_upgrade 独立前缀, 与 chestupgrade 不冲突。
local LruUpgrade = Class(function(self, inst)
  self.inst = inst
  self.baselv = Vector3(2, 6, 1)   -- 基础 2列×6行 = 12 格
  self.chestlv = Vector3(2, 6, 1)
end)

function LruUpgrade:GetLv()
  return self.chestlv.x, self.chestlv.y
end

function LruUpgrade:SetBaseLv(x, y)
  self.baselv = Vector3(x, y, 1)
  self:SetChestLv(x, y)
end

function LruUpgrade:SetChestLv(x, y)
  self.chestlv = Vector3(x, y, 1)
  self.inst.replica.lru_upgrade:SetChestLv(self.chestlv)
  self:UpdateWidget()
  self.inst:PushEvent("onlruchestlvchange")
end

-- 直接改 container.widget + numslots(removesetter 解除只读, 改完恢复), 不触发 WidgetSetup
local function ModCompat(container, widget)
  removesetter(container, "widget")
  removesetter(container, "numslots")

  container.widget = widget
  container.numslots = widget.slotpos ~= nil and #widget.slotpos or 0
  container.inst.replica.lru_upgrade:UpdateWidget()

  makereadonly(container, "widget")
  makereadonly(container, "numslots")
end

-- 背包背景 ui_backpack_2x4 固有 4 行, 按当前格子行数向下拉长
local BGBASE_Y = 4

function LruUpgrade:UpdateWidget()
  local container = self.inst.components.container
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

  container:Close()
  ModCompat(container, widget)
end

function LruUpgrade:OnSave()
  local x, y = self:GetLv()
  return { chestlv = { x = x, y = y } }
end

function LruUpgrade:OnLoad(data)
  if data and data.chestlv then
    self:SetChestLv(data.chestlv.x or 2, data.chestlv.y or 6)
  end
end

return LruUpgrade
