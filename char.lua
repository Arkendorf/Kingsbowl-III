local movement = require "movement"
local rules = require "rules"
local abilities = require "abilities"
local football = require "football"
local cam = require "cam"

local char = {}

local players = {}
local action = "move"
local move_dist = 3.5
local resolve = false
local pos_select = false
local end_down = false

char.load = function(menu_client_list, menu_client_info, menu_team_info)
  if state == "server" then
    server:setSchema("new_tile", {"x", "y"})
    server:on("new_tile", function(data, client)
      if char.set_path(client.connectId, data.x, data.y) then
        abilities.cancel(client.connectId, players[client.connectId])
        network.server_send_except(client.connectId, "new_tile", {client.connectId, data.x, data.y})
      end
    end)
    server:setSchema("ability", {"x", "y"})
    server:on("ability", function(data, client)
      if abilities.use(client.connectId, players[client.connectId], data.x, data.y) then
        movement.cancel(players[client.connectId])
        network.server_send_except(client.connectId, "ability", {client.connectId, data.x, data.y})
      end
    end)
    server:setSchema("position", {"x", "y"})
    server:on("position", function(data, client)
      if rules.set_position(client.connectId, players[client.connectId], data.x, data.y) then
        network.server_send_except(client.connectId, "position", {client.connectId, data.x, data.y})
      end
    end)
  elseif state == "client" then
    client:setSchema("new_tile", {"id", "x", "y"})
    client:on("new_tile", function(data)
      abilities.cancel(data.id, players[data.id])
      char.set_path(data.id, data.x, data.y)
    end)
    client:setSchema("ability", {"id", "x", "y"})
    client:on("ability", function(data)
      movement.cancel(players[data.id])
      abilities.use(data.id, players[data.id], data.x, data.y)
    end)
    client:setSchema("position", {"id", "x", "y"})
    client:on("position", function(data)
      rules.set_position(data.id, players[data.id], data.x, data.y)
    end)
  end

  players = {}
  for i, v in ipairs(menu_client_list) do
    players[v] = {username = menu_client_info[v].username, team = menu_client_info[v].team, tile_x = 3+i, tile_y = 3+i, path = {}, x = 3+i, y = 3+i, xv = 0, yv = 0}
  end

  char.end_down()
  resolve = false
end

char.update = function(dt)
  for k, v in pairs(players) do
    movement.update_object(v, dt)
  end
  if pos_select then
    cam.scrimmage()
  else
    cam.player(players[id])
  end
end

char.draw = function()
  for k, v in pairs(players) do
    if not v.dead then
      love.graphics.rectangle("fill", v.x*tile_size, v.y*tile_size, tile_size, tile_size)
      for i, tile in ipairs(v.path) do
        love.graphics.rectangle("line", tile.x*tile_size, tile.y*tile_size, tile_size, tile_size)
      end
    end
  end
  love.graphics.print(action, 0, 12)
end

char.keypressed = function(key)
  if not pos_select then
    if key == "1" then
      action = "move"
    elseif key == "2" then
      action = "ability"
    end
  end
end

char.mousepressed = function(x, y, button)
  if not resolve and not players[id].dead then
    local tile_x = math.floor(x/tile_size)
    local tile_y = math.floor(y/tile_size)
    if action == "move" then
      if char.set_path(id, tile_x, tile_y) then
        abilities.cancel(id, players[id])
        network.server_send("new_tile", {id, tile_x, tile_y})
        network.client_send("new_tile", {tile_x, tile_y})
      end
    elseif action == "ability" then
      if abilities.use(id, players[id], tile_x, tile_y) then
        movement.cancel(players[id])
        network.server_send("ability", {id, tile_x, tile_y})
        network.client_send("ability", {tile_x, tile_y})
      end
    elseif action == "position" then -- choose position to start next down
      if rules.set_position(id, players[id], tile_x, tile_y) then
        network.server_send("position", {id, tile_x, tile_y})
        network.client_send("position", {tile_x, tile_y})
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
  for k, v in pairs(players) do
    -- collision and path modification
    if movement.can_move(v, step) and not v.dead then -- player is moving and alive, and thus can be moved
      for l, w in pairs(players) do -- if moving, check for collisions with other players
        if v.team ~= w.team and not w.dead and not w.carrier then -- make sure collision is happening between opposite teams (saves calculations), and that opponent isn't dead
          if v.team == rules.get_offense() or not movement.can_move(w, step) then
            if movement.collision(v, w, step) then -- finally check for an actual collision
              v.path = {}
            end
          end
        end
      end
    end
    -- actual movement
    movement.prepare(v, step, step_time)
  end
end

char.finish = function(step)
  local ball = football.get_ball()
  for k, v in pairs(players) do
    -- ball incomplete
    if football.ball_active() and ball.tile >= #ball.full_path then -- incomplete
      rules.incomplete(players)
      end_down = true
      ball.caught = true
    end
    -- ball catching
    if movement.collision(ball, v, step) then -- ball and player are colliding
      football.catch(k, v)
      v.carrier = true
    end
    -- tackling
    if v.carrier then
      for l, w in pairs(players) do -- if moving, check for collisions with other players
        if v.team ~= w.team then -- make sure collision is happening between opposite teams (saves calculations)
          if movement.collision(v, w, step) then -- finally check for an actual collision
            v.path = {}
            v.dead = true
            rules.tackle(k, v, players)
            end_down = true
            break
          end
        end
      end
    end
    movement.finish(v, step)
  end
end

char.start_resolve = function()
  resolve = true
  if pos_select then -- assign positions and qb if not selected
    for k, v in pairs(players) do
      if v.tile_x == math.huge or v.tile_y == math.huge then -- player never selected a tile
        rules.give_position(k, v)
      end
    end
    rules.ensure_qb(players) -- make sure each team has a qb
  end
end

char.end_resolve = function(step)
  char.finish(step)
  resolve = false
  if pos_select then
    action = "move"
    pos_select = false
  elseif end_down then
    char.end_down()
    football.clear()
    end_down = false
  end
end

char.end_down = function()
  action = "position"
  pos_select = true
  for k, v in pairs(players) do
    v.path = {}
    v.tile_x = math.huge
    v.tile_y = math.huge
    v.x = v.tile_x
    v.y = v.tile_y
    v.dead = false
  end
end

return char
