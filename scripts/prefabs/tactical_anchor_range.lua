-- 战术锚点领域范围特效：生命法杖施法后的花丛
-- 在锚点周围生成一圈花丛（中心 1 朵 + 内圈 6 朵 + 外圈 9 朵），
-- 动画用原版 lavaarena_heal_flowers_fx（生命法杖花丛同款素材，无需自带资源）。
-- 容器随锚点销毁，onremove 时清理本地花朵实体。

local NUM_BLOOM_VARIATIONS = 6
local INNER_RADIUS = 9
local OUTER_RADIUS = 18
local INNER_COUNT = 12
local OUTER_COUNT = 24

-- 花丛环形布局（相对锚点中心，花量按半径同密度缩放）
local function BuildLayout()
  local layout = {} -- 中心不放花（锚点本体在那里，避免重叠）
  for i = 1, INNER_COUNT do
    local a = (i - 1) / INNER_COUNT * 2 * PI
    layout[#layout + 1] = { x = math.cos(a) * INNER_RADIUS, z = -math.sin(a) * INNER_RADIUS }
  end
  for i = 1, OUTER_COUNT do
    local a = (i - 1) / OUTER_COUNT * 2 * PI + PI / OUTER_COUNT -- 外圈错开半格，和内圈交错
    layout[#layout + 1] = { x = math.cos(a) * OUTER_RADIUS, z = -math.sin(a) * OUTER_RADIUS }
  end
  return layout
end
local LAYOUT = BuildLayout()

-- 生成一朵花（本地客户端特效，不跨端复制）
local function SpawnBloom(x, z)
  local bloom = CreateEntity()

  bloom.entity:AddTransform()
  bloom.entity:AddAnimState()

  bloom.AnimState:SetBank("lavaarena_heal_flowers")
  bloom.AnimState:SetBuild("lavaarena_heal_flowers_fx")
  bloom.AnimState:SetBloomEffectHandle("shaders/anim.ksh")

  local n = math.random(NUM_BLOOM_VARIATIONS)
  bloom.AnimState:PlayAnimation("in_" .. n)
  bloom.AnimState:PushAnimation("idle_" .. n)

  bloom:AddTag("FX")
  bloom:AddTag("NOCLICK")
  bloom.entity:SetCanSleep(false)
  bloom.persists = false

  bloom.Transform:SetPosition(x, 0, z)

  return bloom
end

local function fn()
  local inst = CreateEntity()

  inst.entity:AddTransform()
  inst.entity:AddNetwork()

  inst:AddTag("FX")
  inst:AddTag("NOCLICK")
  inst.entity:SetCanSleep(false)

  -- 专属服务器不生成本地花丛（无渲染端）
  if not TheNet:IsDedicated() then
    inst:DoTaskInTime(0, function()
      local parent = inst.entity:GetParent()
      local ax, az = 0, 0
      if parent ~= nil and parent.Transform ~= nil then
        local px, _, pz = parent.Transform:GetWorldPosition() -- 声明为局部，避免 strict 模式报全局 _ 赋值
        ax, az = px, pz
      end

      inst._blooms = {}
      for _, f in ipairs(LAYOUT) do
        inst._blooms[#inst._blooms + 1] = SpawnBloom(ax + f.x, az + f.z)
      end
    end)
  end

  -- 随锚点销毁时清理花丛
  inst:ListenForEvent("onremove", function()
    if inst._blooms ~= nil then
      for _, b in ipairs(inst._blooms) do
        if b ~= nil and b:IsValid() then
          b:Remove()
        end
      end
      inst._blooms = nil
    end
  end)

  inst.entity:SetPristine()
  if not TheWorld.ismastersim then
    return inst
  end

  inst.persists = false

  return inst
end

return Prefab("tactical_anchor_range", fn, {
  Asset("ANIM", "anim/lavaarena_heal_flowers_fx.zip"),
})
