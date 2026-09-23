GLOBAL.setmetatable(env, { __index = function(t, k) return GLOBAL.rawget(GLOBAL, k) end })
PrefabFiles = { "kaltsit_esperanta", "kaltsit_esperanta_none", "kaltsit_esperanta_prototyper", "life_repairing_units",
  "special_treatment_gun",
  "special_treatment_bullet", "kaltsit_neuro_gel", "kaltsit_tissue_repair_solvent", "kaltsit_calcite",
  "mon3tr_signboard", "kaltsit_calcite", "kaltsit_esperanta_mon3tr", "kaltsit_esperanta_fx", "kaltsit_esperanta_buff", "tactical_anchor", "tactical_anchor_range", "kaltsit_esperanta_reticule", "mon3tr_handheld_doll" }
Assets = {}

-- 凯尔希·思衡托技能音效：
-- 源文件在 soundSource/kaltsit_esperanta/*.mp3，手动编译为 sound/kaltsit_esperanta.fev + .fsb。
-- FEV 事件组使用 sfx，事件名与源文件名一致，播放路径为 kaltsit_esperanta/sfx/<事件名>。
table.insert(Assets, Asset("SOUNDPACKAGE", "sound/kaltsit_esperanta.fev"))
table.insert(Assets, Asset("SOUND", "sound/kaltsit_esperanta.fsb"))

-- 凯尔希·思衡托中文/日文配音包；语音事件组均为 kaltsit_esperanta。
table.insert(Assets, Asset("SOUNDPACKAGE", "sound/kaltsit_esperanta_voice_zh.fev"))
table.insert(Assets, Asset("SOUND", "sound/kaltsit_esperanta_voice_zh.fsb"))
table.insert(Assets, Asset("SOUNDPACKAGE", "sound/kaltsit_esperanta_voice_jp.fev"))
table.insert(Assets, Asset("SOUND", "sound/kaltsit_esperanta_voice_jp.fsb"))

assert(ARK_ITEM_PACKAGE_LOADED, "请安装前置模组: ark_item_package\n please install the required mod: ark_item_package\n[https://steamcommunity.com/sharedfiles/filedetails/?id=3677284770]")

ArkLogger:DeclareLogger("INFO", "K2CEsperanta")

AddMinimapAtlas("images/map_icons/kaltsit_esperanta.xml") --人物小地图显示

local kaltsit_esperanta_starting_items = {
  "special_treatment_gun",
  "norm_heal_bullet",
}

TUNING.GAMEMODE_STARTING_ITEMS.DEFAULT.KALTSIT_ESPERANTA = kaltsit_esperanta_starting_items
TUNING.GAMEMODE_STARTING_ITEMS.LAVAARENA.KALTSIT_ESPERANTA = kaltsit_esperanta_starting_items
TUNING.GAMEMODE_STARTING_ITEMS.QUAGMIRE.KALTSIT_ESPERANTA = kaltsit_esperanta_starting_items

TUNING.KALTSIT_ESPERANTA_HEALTH = 100
TUNING.KALTSIT_ESPERANTA_HUNGER = 100
TUNING.KALTSIT_ESPERANTA_SANITY = 800


TUNING.KALTSIT_ESPERANTA_MON3TR_HEALTH = 800
TUNING.KALTSIT_ESPERANTA_MON3TR_HUNGER = 800
TUNING.KALTSIT_ESPERANTA_MON3TR_SANITY = 800

TUNING.KALTSIT_ESPERANTA_SKILL3_RANGE = 20

local skill2_damage_mode = GetModConfigData("skill2_damage_mode")
if skill2_damage_mode ~= "fixed_1000"
    and skill2_damage_mode ~= "fixed_2000"
    and skill2_damage_mode ~= "percentage" then
  skill2_damage_mode = "percentage"
end
TUNING.KALTSIT_ESPERANTA_SKILL2_DAMAGE_MODE = skill2_damage_mode

local craft_hunger_cost = tonumber(GetModConfigData("craft_hunger_cost")) or 5
TUNING.KALTSIT_ESPERANTA_CRAFT_HUNGER_COST = math.max(0, craft_hunger_cost)

local voice_language = GetModConfigData("voice_language")
if voice_language ~= "zh" and voice_language ~= "jp" then
  voice_language = "jp"
end
TUNING.KALTSIT_ESPERANTA_VOICE_LANG = voice_language
RegisterVoice("kaltsit_esperanta", "languages/kaltsit_esperanta_voice", {
  voice_lang = voice_language,
  volume = 1,
})

-- UI 文本与配音语言独立；技能台词文字统一来自当前 UI 语言对应的 PO。
local text_language = GetModConfigData("language")
if text_language ~= "auto" and text_language ~= "zh" then
  -- 兼容之前误存的 jp 等旧配置；本项目没有日文 PO。
  text_language = "zh"
end
RegisterPOFile(text_language, {
  zh = "languages/kaltsit_esperanta_chinese_s.po",
  en = "languages/kaltsit_esperanta_english.po",
})

AddReplicableComponent("kaltsit_intellect")
AddReplicableComponent("kaltsit_mon3tr_master")
AddReplicableComponent("tactical_anchor")
AddReplicableComponent("lru_upgrade")

modimport "modmain/kaltsit_intellect.lua"
modimport "modmain/kaltsit_esperanta_tech.lua"
modimport "modmain/special_treatment_gun.lua"
modimport "modmain/special_treatment_bullet.lua"
modimport "modmain/kaltsit_animal_affinity.lua"
modimport "modmain/kaltsit_esperanta_mon3tr.lua"
modimport "modmain/kaltsit_esperanta_skill.lua"
modimport "modmain/tactical_anchor_action.lua"

AddModCharacter("kaltsit_esperanta", "FEMALE", {
  {
    type = "ghost_skin",
    anim_bank = "ghost",
    idle_anim = "idle",
    scale = 0.75,
    offset = { 0, -25 }
  },
})

DefineNetState("kaltsit_intellect", {
  current = "float:classified",
  max = "float:classified",
  next_build_discounted = "bool:classified",
})

local LIFE_REPAIRING_UNITS_TRADABLE = require("life_repairing_units_tradable")
local prefabs = {}
for _, def in pairs(LIFE_REPAIRING_UNITS_TRADABLE) do
  table.insert(prefabs, def.prefab)
end
RegisterEnhanceType("life_repairing_units", prefabs)

-- Mon3tr 手持玩偶: 喂步行手杖强化(强化后手持移速 +25%)
RegisterEnhanceType("mon3tr_handheld_doll", { "cane" })

-- 生命修复单元: 预声明容器定义(初始 12 格; 升级后的格子由 lru_upgrade 动态生成 widget)
local containers = require "containers"

-- 生命修复单元容器最大 16 格, 确保 container_classified 槽位池足够(照抄 upgradeable chest 的做法)
containers.MAXITEMSLOTS = math.max(containers.MAXITEMSLOTS, 16)

local function AddLifeRepairingUnitsContainer(name, cols, rows)
  local param = {
    widget = {
      slotpos = {},
      animbank = "ui_backpack_2x4",
      animbuild = "ui_backpack_2x4",
      pos = Vector3(-5, -80, 0),
    },
    issidewidget = true,
    type = "pack",
    openlimit = 1,
  }
  for y = 0, rows - 1 do
    for x = 0, cols - 1 do
      table.insert(param.widget.slotpos, Vector3(-162 + 75 * x, -75 * y + 114, 0))
    end
  end
  containers.params[name] = param
end

AddLifeRepairingUnitsContainer("life_repairing_units", 2, 6)  -- 12 格(实体prefab名, 客户端初始查这个)
-- 升级后的格子(14/16)由 lru_upgrade 组件动态生成 widget, 无需预声明

-- 容器打开时应用背景缩放/位移(lru_upgrade 动态拉长背包背景, 照抄 upgradeable chest 的 BGReScale)
AddClassPostConstruct("widgets/containerwidget", function(self)
  local _Open = self.Open
  self.Open = function(self, container, doer)
    _Open(self, container, doer)
    local widget = container.replica.container:GetWidget()
    if widget ~= nil then
      if widget.bgscale ~= nil then
        self.bganim:SetScale(widget.bgscale)
        self.bgimage:SetScale(widget.bgscale)
      end
      if widget.bgshift ~= nil then
        self.bganim:SetPosition(widget.bgshift)
        self.bgimage:SetPosition(widget.bgshift)
      end
    end
  end
end)

function IsPlayerControlling(inst)
  return inst.userid ~= nil
end
