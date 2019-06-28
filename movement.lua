local common = require "common"

local movement = {}

local max_dist = 3.5

movement.load = function()
  if state == "server" then
    server:setSchema("new_pos", {"x", "y"})
    server:on("new_pos", function(data, client)
      if resolve or not movement.valid(client.connectId, data.x, data.y) then
        network.server_send_client(client.connectId, "new_pos", {client.connectId, players[client.connectId].new_x, players[client.connectId].new_y})
      else
        players[client.connectId].new_x = data.x
        players[client.connectId].new_y = data.y
        network.server_send_team(players[client.connectId].team, "new_pos", {client.connectId, data.x, data.y})
      end
    end)
  elseif state == "client" then
    client:setSchema("new_pos", {"id", "x", "y"})
    client:on("new_pos", function(data)
      players[data.id].new_x = data.x
      players[data.id].new_y = data.y
      if resolve then
        movement.resolve_player(data.id)
      end
    end)
    client:setSchema("tile_pos", {"id", "x", "y"})
    client:on("tile_pos", function(data)
      players[data.id].tile_x = data.x
      players[data.id].tile_y = data.y
    end)
  end
end

movement.update = function(dt)
  for k, v in pairs(players) do
    if resolve and v.path and #v.path > 1 then
      v.x = v.x + v.xv*v.speed*dt
      v.y = v.y + v.yv*v.speed*dt
      local tile = math.min(1+math.floor(#v.path*(1-timer/resolve_time)), #v.path)
      v.tile_x = v.path[tile].x
      v.tile_y = v.path[tile].y
    end
  end
end

movement.draw = function()
  if not resolve then
    for y = -math.ceil(max_dist), math.ceil(max_dist) do
      for x = -math.ceil(max_dist), math.ceil(max_dist) do
        if movement.valid(id, players[id].tile_x+x, players[id].tile_y+y) then
          love.graphics.rectangle("line", (players[id].tile_x+x)*tile_size+4, (players[id].tile_y+y)*tile_size+4, tile_size-8, tile_size-8)
        end
      end
    end
  end
  for k, v in pairs(players) do
    love.graphics.setColor(team_info[v.team].color)
    love.graphics.rectangle("fill", v.x*tile_size, v.y*tile_size, tile_size, tile_size)
    if v.team == players[id].team then
      love.graphics.rectangle("line", v.tile_x*tile_size, v.tile_y*tile_size, tile_size, tile_size)
      love.graphics.rectangle("line", v.new_x*tile_size+2, v.new_y*tile_size+2, tile_size-4, tile_size-4)
    end
  end
  love.graphics.setColor(1, 1, 1)
end

movement.mousepressed = function(x, y, button)
  if not resolve then
    local tile_x = math.floor(x/tile_size)
    local tile_y = math.floor(y/tile_size)
    if movement.valid(id, tile_x, tile_y) then
      players[id].new_x = tile_x
      players[id].new_y = tile_y
      network.server_send_team(players[id].team, "new_pos", {id, tile_x, tile_y})
      network.client_send("new_pos", {tile_x, tile_y})
    end
  end
end

movement.valid = function(id, x, y)
  local player = players[id]
  if common.dist(player.tile_x, player.tile_y, x, y) > max_dist then
    return false
  end
  for k, v in pairs(players) do
    if v.team == player.team and k ~= id then
      if x == v.new_x and y == v.new_y then
        return false
      end
    end
  end
  return true
end

movement.resolve_moves = function()
  for k, v in pairs(players) do
    movement.resolve_player(k)
  end
end

movement.resolve_player = function(id)
  local player = players[id]
  player.path = movement.get_path(player.tile_x, player.tile_y, player.new_x, player.new_y)
  local dist = common.dist(player.tile_x, player.tile_y, player.new_x, player.new_y)
  player.xv = (player.new_x-player.tile_x)/dist
  player.yv = (player.new_y-player.tile_y)/dist
  player.speed = dist/resolve_time
end

movement.start_moves = function()
  for k, v in pairs(players) do
    v.tile_x = v.new_x
    v.tile_y = v.new_y
    v.x = v.tile_x
    v.y = v.tile_y
    v.path = {}
    network.server_send("tile_pos", {k, v.tile_x, v.tile_y})
  end
end

movement.get_path = function(x1, y1, x2, y2)
  local path = {}

  local x_dif = (x2-x1)
  local y_dif = (y2-y1)
  if math.abs(x_dif) >= math.abs(y_dif) then
    local slope = y_dif/x_dif
    for i = 0, x_dif, math.abs(x_dif)/x_dif do
      path[#path+1] = {x = x1+i, y = y1+math.floor(slope*i+.5)}
    end
  else
    local slope = x_dif/y_dif
    for i = 0, y_dif, math.abs(y_dif)/y_dif do
      path[#path+1] = {x = x1+math.floor(slope*i+.5), y = y1+i}
    end
  end

  return path
end

return movement
