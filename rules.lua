local rules = {}

local offense = 1
local team_info = {}
local qb = 0

rules.load = function(menu_client_list, menu_client_info, menu_team_info)
  possesion = 1

  team_info = menu_team_info
  team_info[1].qb_list = {}
  team_info[2].qb_list = {}
  for i, v in ipairs(menu_client_list) do
    local team = menu_client_info[v].team
    team_info[team].qb_list[#team_info[team].qb_list+1] = v
  end
  team_info[1].qb = 1
  team_info[2].qb = 1
  rules.new_qb(possesion)
end

rules.get_offense = function()
  return possesion
end

rules.new_qb = function(team)
  qb = team_info[team].qb_list[team_info[team].qb]
  team_info[team].qb = team_info[team].qb + 1
  if team_info[team].qb > #team_info[team].qb_list then
    team_info[team].qb = 1
  end
end

rules.get_qb = function()
  return qb
end

return rules
