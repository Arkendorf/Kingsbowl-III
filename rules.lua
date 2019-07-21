field = require "field"

local rules = {}

local offense = 1
local team_info = {}
local qb = 0
local down = 1
local scrimmage = 0
local lineup_h = 7
local lineup_buffer = 1

rules.load = function(menu_client_list, menu_client_info, menu_team_info)
  offense = 1
  down = 1
  scrimmage = math.floor(field.get_dimensions()/2)
  team_info = menu_team_info
  -- team_info[1].list = {}
  -- team_info[2].list = {}
  -- for i, v in ipairs(menu_client_list) do
  --   local team = menu_client_info[v].team
  --   team_info[team].list[#team_info[team].list+1] = v
  -- end

  rules.set_lineup(1)
  rules.set_lineup(2)
end

rules.draw = function()
  love.graphics.print(down, 0, 24)
  local field_w, field_h = field.get_dimensions()
  love.graphics.line((scrimmage+1)*tile_size, 0, (scrimmage+1)*tile_size, field_h*tile_size)
  for team = 1, 2 do
    for i, v in ipairs(team_info[team].lineup) do
      love.graphics.rectangle("line", (v.x+scrimmage)*tile_size, v.y*tile_size, tile_size, tile_size)
    end
  end
end

rules.get_offense = function()
  return offense
end

rules.get_qb = function()
  return qb
end

rules.catch = function(player)
  if player.team ~= offense then
    rules.turnover()
  end
end

rules.incomplete = function()
  rules.end_down()
end

rules.tackle = function(id, player)
  scrimmage = player.tile_x
  rules.end_down()
end

rules.end_down = function()
  down = down + 1
  if down > 4 then
    rules.turnover()
  end
  qb = 0
  for team = 1, 2 do -- reset lineup positioning
    for i, v in ipairs(team_info[team].lineup) do
      v.taken = false
    end
  end
end

rules.turnover = function()
  down = 1
  if offense == 1 then
    offense = 2
  else
    offense = 1
  end
end

rules.set_position = function(id, player, tile_x, tile_y)
  for i, v in ipairs(team_info[player.team].lineup) do
    if v.x == tile_x-scrimmage and v.y == tile_y and not v.taken then
      rules.set_tile(id, player, i, v)
      return true
    end
  end
  return false
end

rules.set_tile = function(id, player, tile_num, tile)
  tile.taken = true
  tile.host = id
  player.tile_x = tile.x+scrimmage
  player.tile_y = tile.y
  player.x = player.tile_x
  player.y = player.tile_y
  if tile_num == 1 and player.team == offense then -- if player is standing in qb position, make them qb
    qb = id
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
