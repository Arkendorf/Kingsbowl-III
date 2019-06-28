common = require "common"

local movement = {}

movement.load = function()
  if state == "server" then
    server:setSchema("new_pos", {"x", "y"})
    server:on("new_pos", function(data, client)
      if resolve then
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
    players[id].new_x = math.floor(x/tile_size)
    players[id].new_y = math.floor(y/tile_size)
    network.server_send_team(players[id].team, "new_pos", {id, players[id].new_x, players[id].new_y})
    network.client_send("new_pos", {players[id].new_x, players[id].new_y})
  end
end

movement.resolve_moves = function()
  for k, v in pairs(players) do
    movement.resolve_player(k)
  end
end

movement.resolve_player = function(id)
  local v = players[id]
  v.path = movement.get_path(v.tile_x, v.tile_y, v.new_x, v.new_y)
  local dist = common.dist(v.tile_x, v.tile_y, v.new_x, v.new_y)
  v.xv = (v.new_x-v.tile_x)/dist
  v.yv = (v.new_y-v.tile_y)/dist
  v.speed = dist/resolve_time
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
