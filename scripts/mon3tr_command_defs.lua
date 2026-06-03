local ICON_SCALE = 0.6
local unsummon = {
  label = STRINGS.GHOSTCOMMANDS.UNSUMMON,
  onselect = function(inst)
    ArkLogger:Debug("unsummon selected")
  end,
  execute = function(inst)
    ArkLogger:Debug("unsummon executed")
  end,
  bank = "spell_icons_wendy",
  build = "spell_icons_wendy",
  anims =
  {
    idle = { anim = "unsummon" },
    focus = { anim = "unsummon_focus", loop = true },
    down = { anim = "unsummon_pressed" },
  },
  widget_scale = ICON_SCALE,
}

local defs = {
  { unsummon },                                    -- 精英1：1个指令
  { unsummon, unsummon },                          -- 精英2：2个指令
  { unsummon, unsummon, unsummon },                -- 精英3：3个指令
}

local function GetCommands(level)
  if level == nil then
    level = 1
  end
  level = math.clamp(level or 1, 1, #defs)
  return defs[level]
end
  

return {
  GetCommands = GetCommands
}
