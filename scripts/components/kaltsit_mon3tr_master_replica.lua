-- ============================================================
-- KaltsitMon3trMasterReplica
-- ============================================================
-- 精简后仅保留 master 的 net 状态同步（如需），
-- 精英等级已迁移至 kaltsit_mon3tr_commander（通过 kaltsit_intellect 阶数推断）。

local KaltsitMon3trMasterReplica = Class(function(self, inst)
    self.inst = inst
end)

return KaltsitMon3trMasterReplica
