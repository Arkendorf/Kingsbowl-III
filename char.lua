local movement = require "movement"
local rules = require "rules"

local char = {}

local players = {}
local action = "move"
local move_dist = 3.5
local resolve = false

char.load = function(menu_client_list, menu_client_info, menu_team_info)
  if state == "server" then
    server:setSchema("new_tile", {"x", "y"})
    server:on("new_tile", function(data, client)
      if char.set_path(client.connectId, data.x, data.y) then
        network.server_send_except(client.connectId, "new_tile", {client.connectId, data.x, data.y})
      end
    end)
  elseif state == "client" then
    client:setSchema("new_tile", {"id", "x", "y"})
    client:on("new_tile", function(data)
      local path = movement.get_path(players[data.id].tile_x, players[data.id].tile_y, data.x, data.y)
      players[data.id].path = path
    end)
  end

  players = {}
  for i, v in ipairs(menu_client_list) do
    players[v] = {username = menu_client_info[v].username, team = menu_client_info[v].team, tile_x = 3+i, tile_y = 3+i, path = {}, x = 3+i, y = 3+i, xv = 0, yv = 0}
  end

  action = "move"
  resolve = false
end

char.update = function(dt)
  for k, v in pairs(players) do
    movement.update_player(v, dt)
  end
end

char.draw = function()
  for k, v in pairs(players) do
    love.graphics.rectangle("fill", v.x*tile_size, v.y*tile_size, tile_size, tile_size)
    for i, tile in ipairs(v.path) do
      love.graphics.rectangle("line", tile.x*tile_size, tile.y*tile_size, tile_size, tile_size)
    end
  end
end

char.keypressed = function(key)
  if key == "1" then
    action = "move"
  elseif key == "2" then
    action = "ability"
  end
end

char.mousepressed = function(x, y, button)
  if not resolve then
    if action == "move" then
      local tile_x = math.floor(x/tile_size)
      local tile_y = math.floor(y/tile_size)
      if char.set_path(id, tile_x, tile_y) then
        network.server_send("new_tile", {id, tile_x, tile_y})
        network.client_send("new_tile", {tile_x, tile_y})
      end
    end
  end
end

char.set_path = function(id, tile_x, tile_y)
  if movement.valid(players[id].tile_x, players[id].tile_y, tile_x, tile_y, move_dist) then
    local path = movement.get_path(players[id].tile_x, players[id].tile_y, tile_x, tile_y)
    if path then
      if not char.path_collision(id, path, players[id].team) then
        players[id].path = path
        return true
      end
    end
  end
  return false
end

char.step_num = function()
  local num = 0
  for k, v in pairs(players) do
    if #v.path > num then
      num = #v.path
    end
  end
  return num
end

char.path_collision = function(id, path, team)
  local step_num = char.step_num()
  for k, v in pairs(players) do
    if id ~= k and v.team == team and #v.path > 0 then
      for i = 1, step_num do
        if v.path[i] and path[i] then
          if v.path[i].x == path[i].x and v.path[i].y == path[i].y then -- check for overlapping intermediate steps in path
            return true
          end
        end
      end
      if v.path[#v.path].x == path[#path].x and v.path[#v.path].y == path[#path].y then -- check for overlapping final destinations
        return true
      end
    end
  end
  return false
end

char.prepare = function(step, step_time)
  -- collision and path modification
  for k, v in pairs(players) do
    if movement.moving(v, step) then -- player is moving, and thus can be moved
      for l, w in pairs(players) do -- if moving, check for collisions with other players
        if v.team ~= w.team then -- make sure collision is happening between opposite teams (saves calculations)
          if v.team == rules.get_offense() or not movement.moving(w, step) then
            if movement.collision(v, w, step) then -- finally check for an actual collision
              v.path = {}
            end
          end
        end
      end
    end
    movement.prepare(v, step, step_time)
  end
end

char.finish = function(step)
  if step > 0 then
    for k, v in pairs(players) do
      movement.finish(v, step)
    end
  end
end

char.start_resolve = function()
  resolve = true
end

char.end_resolve = function(step)
  char.finish(step)
  resolve = false
end

return char