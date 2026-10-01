-- 所有尺寸均为 UI 本地坐标；默认按 bg.png (975 x 136) 的八个槽位对齐。
return {
  atlas = "images/ui_kaltsit_experanta_mon3tr_skill.xml",
  bg_width = 975,
  bg_height = 136,
  scale = 0.56,                 -- 原 0.7 的 80%，再乘前置模组的 hand_base_scale
  offset_x = 20,                -- 整栏相对前置栏左边缘的水平偏移
  offset_y = 0,                -- 整栏的垂直微调
  above_gap = 12,              -- 与前置栏顶部的距离（缩放前）
  fallback_x = -810,           -- 没有前置栏内容时的左边缘（库存 root 坐标）
  fallback_y = 110,            -- 没有前置栏内容时，相对库存第一行的高度

  icon_size = 975 * 192 / 2064,
  mode_gap = 975 * 48 / 2064,   -- 左组三个图标之间的边缘距离
  skill_gap = 975 * 48 / 2064,  -- 右组五个图标之间的边缘距离
  group_gap = 975 * 144 / 2064, -- 两组最近图标之间的边缘距离
  row_x = 0,                   -- 图标整行相对背景中心的偏移
  row_y = 0,
  overlay_size = 975 * 192 / 2064,
  overlay_x = 0,
  overlay_y = 0,
  overlay_move_time = 0.18,

  clip_padding = 4,            -- 裁剪框比背景每边多出的尺寸
  slide_margin = 4,            -- 完全下沉到裁剪框之外后再多移出的距离
  slide_time = 0.25,
}
