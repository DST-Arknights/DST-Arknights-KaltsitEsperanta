local skills = {
  {
    key = "intimidate",
    id = "kaltsit_mon3tr_intimidate",
    implemented = true,
    intellect_threshold = 1,
    activation_energy = 30,
    buff_duration = 0,
  }, {
    key = "assault",
    id = "kaltsit_mon3tr_assault",
    intellect_threshold = 50,
    activation_energy = 10,
    buff_duration = 0,
  }, {
    key = "reinforce",
    id = "kaltsit_mon3tr_reinforce",
    intellect_threshold = 100,
    activation_energy = 60,
    buff_duration = 30,
  }, {
    key = "castling",
    id = "kaltsit_mon3tr_castling",
    intellect_threshold = 150,
    activation_energy = 60,
    buff_duration = 0,
  }, {
    key = "meltdown",
    id = "kaltsit_mon3tr_meltdown",
    intellect_threshold = 200,
    activation_energy = 200,
    buff_duration = 20,
  },
}

local by_id, by_key = {}, {}
for index, skill in ipairs(skills) do
  skill.index = index
  by_id[skill.id] = skill
  by_key[skill.key] = skill
end

return {
  skills = skills,
  by_id = by_id,
  by_key = by_key,
  atlas = "images/ui_kaltsit_experanta_mon3tr_skill.xml",
}
