local field = require "field"
local movement = require "movement"

local rules = {}

local offense = 1
local team_info = {}
local qb = 0
local down = 1
local scrimmage = 0
local goal = 0
local lineup_h = 7
local lineup_buffer = 1
local intercept = false
local pos_select = true
local char_team = 1
local down_suffix = {"st", "nd", "rd", "th"}
local yard_scale = 2

rules.load = function(menu_client_list, menu_client_info, menu_team_info)
  if network_state == "client" then
    client:setSchema("score", {"team", "score"})
    client:on("score", function(data)
      team_info[data.team].score = data.score
    end)
    client:on("qb", function(data)
      qb = data
    end)
  end
  pos_select = true
  offense = 1
  rules.set_scrimmage(math.floor(field.get_dimensions()/2)-1)
  rules.set_goal()
  yard_scale = 120/field.get_dimensions()
  down = 1
  team_info = menu_team_info
  team_info[1].score = 0
  team_info[2].score = 0

  rules.set_lineup(1)
  rules.set_lineup(2)

  field.set_color(team_info[1].color, team_info[2].color)
end

rules.draw = function()
  love.graphics.print(down, 0, 24)
  local field_w, field_h = field.get_dimensions()
  art.rectangle(scrimmage+1-3/tile_size, 0, 6/tile_size, field_h, colors.yellow[1], colors.yellow[2], colors.yellow[3])
  if goal then
    art.rectangle(goal+1-3/tile_size, 0, 6/tile_size, field_h, colors.green[1], colors.green[2], colors.green[3])
  end
  if pos_select then
    local x = team_info[char_team].lineup[1].x+scrimmage
    local y= team_info[char_team].lineup[1].y
    art.path_border(x, y, lineup_h/2, rules.valid_pos, char_team)
    art.path_icon(6, x, y, colors.green[1], colors.green[2], colors.green[3])
  end
end

rules.set_team = function(team)
  char_team = team
end

rules.get_offense = function()
  return offense
end

rules.get_qb = function()
  return qb
end

rules.get_score = function(team)
  return team_info[team].score
end

rules.get_info = function()
  return team_info
end

rules.get_color = function(team)
  return team_info[team].color
end

rules.catch = function(player)
  if player.team ~= offense then
    rules.turnover()
    intercept = true
  end
end

rules.incomplete = function()
  rules.end_down()
end

rules.tackle = function(x)
  rules.set_scrimmage(x)
  rules.set_goal()
  rules.end_down()
end

rules.touchdown = function()
  rules.reset()
  rules.end_down()
end

rules.set_scrimmage = function(x)
  scrimmage = x
  local scrim_min, scrim_max = rules.get_endzones()
  if scrimmage > scrim_max then
    scrimmage = scrim_max
  elseif scrimmage < scrim_min then
    scrimmage = scrim_min
  end
end

rules.set_goal = function()
  if offense == 1 and goal < scrimmage then
    goal = scrimmage + math.floor(field.get_dimensions()/12)
    down = 0
  elseif offense == 2 and goal > scrimmage then
    goal = scrimmage - math.floor(field.get_dimensions()/12)
    down = 0
  end
  local scrim_min, scrim_max = rules.get_endzones()
  if goal > scrim_max or scrimmage < scrim_min then
    goal = false
  end
end

rules.end_down = function()
  if intercept then -- if ball was just intercepted, set down to 1
    down = 1
    intercept = false
  else
    down = down + 1
    if down > 4 then
      rules.turnover()
      down = 1
    end
  end
  qb = 0
  for team = 1, 2 do -- reset lineup positioning
    for i, v in ipairs(team_info[team].lineup) do
      v.taken = false
    end
  end
end

rules.reset = function()
  rules.turnover()
  local field_w = field.get_dimensions()
  rules.set_scrimmage(math.floor(field_w/12*6)-1)
end

rules.turnover = function()
  if offense == 1 then
    offense = 2
  else
    offense = 1
  end
end

rules.get_endzones = function()
  local field_w = field.get_dimensions()
  return math.floor(field_w/12)-1, math.floor(field_w/12*11)-1
end

rules.check_td = function(player, step)
  local min, max = rules.get_endzones()
  local x= player.tile_x
  if movement.can_move(player, step) then
    x = player.path[step].x
  end
  if (player.team == 1 and x > max) or (player.team == 2 and x <= min) then
    if network_state == "server" then -- server has final say on touchdowns
      team_info[player.team].score = team_info[player.team].score + 7
      network.server_send("score", {player.team, team_info[player.team].score})
    end
    return true
  end
  return false
end

rules.start_select = function()
  pos_select = true
end

rules.finish_select = function()
  pos_select = false
end

rules.get_play_string = function()
  if goal then
    return tostring(down)..down_suffix[down].." and "..tostring(math.abs(goal-scrimmage)*yard_scale)
  else
    return tostring(down)..down_suffix[down].." and Goal"
  end
end

rules.get_name = function(team)
  return team_info[team].name
end

rules.valid_pos = function(x1, y1, x2, y2, team)
  for i, v in ipairs(team_info[team].lineup) do
    if i > 1 then
      if v.x == x2-scrimmage and v.y == y2 then
        return true
      end
    end
  end
  return false
end

rules.set_position = function(id, player, tile_x, tile_y)
  for i, v in ipairs(team_info[player.team].lineup) do
    if v.x == tile_x-scrimmage and v.y == tile_y and not v.taken then
      rules.remove_host(id, player)
      rules.set_tile(id, player, i, v)
      return true
    end
  end
  return false
end

rules.remove_host = function(id, player)
  for i, v in ipairs(team_info[player.team].lineup) do
    if v.host == id then
      v.taken = false
      v.host = false
      break
    end
  end
end

rules.set_tile = function(id, player, tile_num, tile)
  tile.taken = true
  tile.host = id
  local tile_x = tile.x+scrimmage
  local tile_y = tile.y
  if network_state == "server" then
    player.tile_x = tile_x
    player.tile_y = tile_y
    network.server_send("char_tile", {id, tile_x, tile_y})
  end
  player.x = tile_x
  player.y = tile_y
  if tile_num == 1 and player.team == offense then -- if player is standing in qb position, make them qb
    qb = id
    network.server_send("qb", qb)
  end
end

rules.give_position = function(id, player)
  for i, v in ipairs(team_info[player.team].lineup) do
    if not v.taken then
      rules.set_tile(id, player, i, v)
      break
    end
  end
end

rules.prepare_position = function(id, player)
  tile_x = math.huge
  tile_y = math.huge
  if network_state == "server" then
    player.tile_x = tile_x
    player.tile_y = tile_y
    network.server_send("char_tile", {id, tile_x, tile_y})
  end
  player.x = tile_x
  player.y = tile_y
end

rules.ensure_qb = function(players)
  if not team_info[offense].lineup[1].taken then
    for i, v in ipairs(team_info[offense].lineup) do
      if v.taken then
        rules.set_tile(v.host, players[v.host], 1, team_info[offense].lineup[1])
        break
      end
    end
  end
end

rules.set_lineup = function(team)
  local lineup = {}

  local center_y = math.ceil(lineup_h/2)
  local sign = (team-1.5)*2

  local field_w, field_h = field.get_dimensions()
  local y = math.floor((field_h-lineup_h)/2)-1
  local x = lineup_buffer+team-1 -- team 2 has an extra offset of one to account for the scrimmage marker being inbetween tiles but saved as one

  lineup[1] = {x = (x+1)*sign, y = y+center_y}
  lineup[2] = {x = x*sign, y = y+center_y}

  for i = 1, math.floor(lineup_h/2) do
    lineup[#lineup+1] = {x = (x+1)*sign, y = y+center_y+i}
    lineup[#lineup+1] = {x = (x+1)*sign, y = y+center_y-i}
    lineup[#lineup+1] = {x = x*sign, y = y+center_y+i}
    lineup[#lineup+1] = {x = x*sign, y = y+center_y-i}
  end
  team_info[team].lineup = lineup
end

rules.get_scrimmage = function()
  return scrimmage
end

return rules
