-- 召唤动作
AddAction("CASTSUMMON_MON3TR", STRINGS.ACTIONS.CASTSUMMON_MON3TR.GENERIC, function(act)
  ArkLogger:Debug("CASTSUMMON_MON3TR action executed", act.invobject)
  if act.invobject ~= nil and act.invobject.components.summoningitem and act.doer ~= nil and act.doer.components.kaltsit_mon3tr_master ~= nil then
    return act.doer.components.kaltsit_mon3tr_master:Summon(act.invobject)
  end
end)
AddComponentAction('INVENTORY', 'summoningitem', function(inst, doer, actions)
  if doer:HasTag("mon3tr_master_notsummoned") then
    table.insert(actions, ACTIONS.CASTSUMMON_MON3TR)
  end
end)

AddStategraphActionHandler("wilson", ActionHandler(ACTIONS.CASTSUMMON_MON3TR, 'castspell'))
AddStategraphActionHandler("wilson_client", ActionHandler(ACTIONS.CASTSUMMON_MON3TR, 'castspell'))
