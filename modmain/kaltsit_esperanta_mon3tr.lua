-- 召唤动作
AddAction("CASTSUMMON_MON3TR", STRINGS.ACTIONS.CASTSUMMON_MON3TR.GENERIC, function(act)
  if act.invobject ~= nil and act.invobject.components.summoningitem and act.doer ~= nil and act.doer.components.kaltsit_mon3tr_leader ~= nil then
    return act.doer.components.kaltsit_mon3tr_leader:Summon(act.invobject.components.summoningitem.inst)
  end
end)
-- 指令动作
AddAction("COMMAND_MON3TR", STRINGS.ACTIONS.COMMAND_MON3TR.GENERIC, function(act)
  -- TODO: 弹出指令面板
end)

AddComponentAction('INVENTORY', 'summoningitem', function(inst, doer, actions)
  if doer:HasTag("mon3tr_notsummoned") then
    table.insert(actions, ACTIONS.CASTSUMMON_MON3TR)
  elseif doer:HasTag("mon3tr_summoned") then
    table.insert(actions, ACTIONS.COMMAND_MON3TR)
  end
end)
