local function oncurrentdirty(self, value)
  self.inst.replica.kaltsit_intellect.state.current = value
end

local function onmaxdirty(self, value)
  self.inst.replica.kaltsit_intellect.state.max = value
end

local KaltsitIntellect = Class(function(self, inst)
  self.inst = inst
  self.current = 0
  self.max = 1
  self.next_build_free = false
  -- 精英晋升阈值表: index 即为精英等级(从1开始), value 为所需最大理智值
  --   elite_thresholds[1] = 1   → 精英1 (基础/初始)
  --   elite_thresholds[2] = 100 → 精英2
  --   elite_thresholds[3] = 200 → 精英3
  self.elite_thresholds = { 1, 100, 200 }
  self.on_apply_elite = nil
end, nil, {
  current = oncurrentdirty,
  max = onmaxdirty,
})

function KaltsitIntellect:SetOnApplyElite(fn)
  self.on_apply_elite = fn
end

function KaltsitIntellect:TryApplyElite(oldMax, newMax)
  -- 从高精英等级往低检查，确保一次性跨越多个门槛时高精英优先触发
  for i = #self.elite_thresholds, 1, -1 do
    local threshold = self.elite_thresholds[i]
    if oldMax < threshold and newMax >= threshold then
      if self.on_apply_elite then
        self.on_apply_elite(self.inst, i) -- 传入精英等级 (1-based, 即 index 本身)
      end
      return
    end
  end
end

function KaltsitIntellect:Delta(delta)
  self.current = math.clamp(self.current + delta, 0, self.max)
end

function KaltsitIntellect:DeltaMax(delta)
  local max = self.max
  self.max = math.max(self.max + delta, 1)   -- max 至少为1，避免除0错误
  self:TryApplyElite(max, self.max)     -- 尝试
end

-- 扣除10点并使下次制作消耗物品减半
function KaltsitIntellect:UseNextBuildFree()
  if self.current >= 10 then
    self:Delta(-10)
    self.next_build_free = true
  end
end

function KaltsitIntellect:OnSave()
  return {
    current = self.current,
    max = self.max,
  }
end

function KaltsitIntellect:OnLoad(data)
  if data == nil then return end
  if data.current ~= nil then
    self.current = data.current
  end
  if data.max ~= nil then
    self.max = data.max
  end
  self:TryApplyElite(0, self.max)   -- 加载时根据 max 尝试应用精英效果
end

return KaltsitIntellect
