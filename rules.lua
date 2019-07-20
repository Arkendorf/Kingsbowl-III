local rules = {}

local offense = 1
local team_info = {}
local qb = 0
local down = 1

rules.load = function(menu_client_list, menu_client_info, menu_team_info)
  offense = 1
  down = 1

  team_info = menu_team_info
  team_info[1].qb_list = {}
  team_info[2].qb_list = {}
  for i, v in ipairs(menu_client_list) do
    local team = menu_client_info[v].team
    team_info[team].qb_list[#team_info[team].qb_list+1] = v
  end
  team_info[1].qb = 1
  team_info[2].qb = 1
  rules.new_qb(offense)
end

rules.draw = function()
  love.graphics.print(down, 0, 24)
end

rules.get_offense = function()
  return offense
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

rules.incomplete = function()
  down = down + 1
  if down > 4 then
    rules.turnover()
  end
end

rules.turnover = function()
  down = 1
  if offense == 1 then
    offense = 2
  else
    offense = 1
  end
  rules.new_qb(offense)
end

return rules
