local movement = require "movement"
local rules = require "rules"
local abilities = require "abilities"
local football = require "football"
local camera = require "camera"

local char = {}
local players = {}
local action = "move"
local move_dist = {
  qb = 12.5,
  carrier = 12.5,
  defense = 13,
  offense = 13.5
}
local resolve = false
local pos_select = false
local end_down = false
local end_info = {type = "", player = 0}

char.load = function(menu_client_list, menu_client_info, menu_team_info)
  if network_state == "server" then
    server:setSchema("new_tile", {"x", "y"})
    server:on("new_tile", function(data, client)
      if char.set_path(client.connectId, data.x, data.y) then
        abilities.cancel(client.connectId, players[client.connectId])
        network.server_send_except(client.connectId, "new_tile", {client.connectId, data.x, data.y})
      elseif #players[client.connectId].path > 0 then
        local tile = players[client.connectId].path[#players[client.connectId].path]
        network.server_send_client(client.connectId, "new_tile", {client.connectId, tile.x, tile.y})
      else
        network.server_send_client(client.connectId, "clear_path", client.connectId)
      end
    end)
    server:setSchema("ability", {"x", "y"})
    server:on("ability", function(data, client)
      if char.use_ability(client.connectId, data.x, data.y) then
        movement.cancel(players[client.connectId])
        network.server_send_except(client.connectId, "ability", {client.connectId, data.x, data.y})
      elseif players[client.connectId].item.active then
        local item = players[client.connectId].item
        network.server_send_client(client.connectId, "ability", {client.connectId, item.tile_x, item.tile_y})
      else
        network.server_send_client(client.connectId, "stop_ability", client.connectId)
      end
    end)
    server:setSchema("position", {"x", "y"})
    server:on("position", function(data, client)
      if rules.set_position(client.connectId, players[client.connectId], data.x, data.y) then
        network.server_send_except(client.connectId, "position", {client.connectId, data.x, data.y})
      elseif players[client.connectId].tile_x ~= math.huge or players[client.connectId].tile_y ~= math.huge then
        local player = players[client.connectId]
        network.server_send_client(client.connectId, "position", {client.connectId, player.tile_x, player.tile_y})
      else
        network.server_send_client(client.connectId, "reset_position", client.connectId)
      end
    end)
  elseif network_state == "client" then
    client:setSchema("new_tile", {"id", "x", "y"})
    client:on("new_tile", function(data)
      abilities.cancel(data.id, players[data.id])
      char.set_path(data.id, data.x, data.y)
    end)
    client:on("clear_path", function(data)
      players[data].path = {}
    end)
    client:setSchema("ability", {"id", "x", "y"})
    client:on("ability", function(data)
      movement.cancel(players[data.id])
      char.use_ability(data.id, data.x, data.y)
    end)
    client:on("stop_path", function(data)
      players[data].item.active = false
    end)
    client:setSchema("position", {"id", "x", "y"})
    client:on("position", function(data)
      rules.set_position(data.id, players[data.id], data.x, data.y)
    end)
    client:on("reset_position", function(data)
      players[data].tile_x = math.huge
      players[data].tile_y = math.huge
      players[data].x = players[data].tile_x
      players[data].y = players[data].tile_y
    end)
    client:setSchema("char_tile", {"id", "x", "y"})
    client:on("char_tile", function(data)
      players[data.id].tile_x = data.x
      players[data.id].tile_y = data.y
    end)
  end

  players = {}
  for i, v in ipairs(menu_client_list) do
    players[v] = {username = menu_client_info[v].username, team = menu_client_info[v].team, tile_x = 3+i, tile_y = 3+i, path = {}, x = 3+i, y = 3+i, xv = 0, yv = 0, item = {active = false}}
  end

  char.pos_prepare()
  football.visible(players[id].team)
  resolve = false
end

char.update = function(dt)
  for k, v in pairs(players) do
    movement.update_object(v, dt)
  end
  if pos_select then
    camera.scrimmage()
  else
    camera.player(players[id])
  end
end

char.draw = function()
  for k, v in pairs(players) do -- draw stationary players first
    if #v.path <= 0 then
      char.draw_char(k, v)
    end
  end
  for k, v in pairs(players) do -- draw moving players first
    if #v.path > 0 then
      if players[id].team == v.team then -- if on the same team, draw path
        for i, tile in ipairs(v.path) do
          love.graphics.rectangle("line", tile.x*tile_size, tile.y*tile_size, tile_size, tile_size)
        end
      end
      char.draw_char(k, v)
    end
  end
  for k, v in pairs(players) do -- draw items
    if v.item.active and (players[id].team == v.team or resolve) then
      local quad = "item"..tostring(abilities.direction(v))
      if resolve then
        art.draw_quad(v.item.type, quad, v.item.tile_x, v.item.tile_y)
      else
        art.draw_quad(v.item.type, quad, v.item.tile_x, v.item.tile_y, 1, 1, 1, "outline")
      end
    end
  end
end

char.draw_char = function(k, v)
  if pos_select then
    art.draw_img("helmet", v.x, v.y, 1, 1, 1, "outline")
  else
    art.draw_img("helmet", v.x, v.y)
  end
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
      if char.use_ability(id, tile_x, tile_y) then
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

char.use_ability = function(id, tile_x, tile_y)
  if abilities.type(id, players[id]) == "item" then
    for k, v in pairs(players) do -- make sure teammate hasn't put an item in the tile
      if v.item.active and v.team == players[id].team then
        if v.item.tile_x == tile_x and v.item.tile_y == tile_y then
          return false
        end
      end
    end
  end
  return abilities.use(id, players[id], tile_x, tile_y)
end

char.set_path = function(id, tile_x, tile_y)
  if movement.valid(players[id].tile_x, players[id].tile_y, tile_x, tile_y, move_dist[char.get_state(id, players[id])]) then
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

char.get_players = function()
  return players
end

char.prepare = function(step, step_time)
  local collision = true
  while collision do -- adjust paths based on collisions
    collision = false
    for k, v in pairs(players) do
      if movement.can_move(v, step) then -- players can only be bounced if they are moving
        for l, w in pairs(players) do
          if v.team ~= w.team and not w.dead then -- players can only collide with non-dead members of the opposite team
            if v.team ~= rules.get_offense() or not movement.can_move(w, step) then -- only defense can be bounced, unless offense is colliding with stationary player
              if movement.collision(v, w, step) then
                collision = true
                movement.bounce(v, step, step_time)
                v.path = {}
                if char.tackleable(k, v, step) then
                  char.tackle(v)
                end
                if char.tackleable(l, w, step) then
                  char.tackle(w)
                end
              end
            end
          end
        end
      end
    end
  end
  for k, v in pairs(players) do -- check to see if ball holder is tackled by an item
    char.check_tackle(k, v, step)
  end
  for k, v in pairs(players) do -- actual movement
    movement.prepare(v, step, step_time)
  end
end

char.finish = function(step)
  local ball = football.get_ball()
  for k, v in pairs(players) do
    -- ball catching
    if football.ball_active() and movement.collision(ball, v, step) then -- ball and player are colliding
      football.catch(k, v)
      v.carrier = true
    end
    -- check for td
    if movement.can_move(v, step) and char.tackleable(k, v, step) then
      if rules.check_td(v, step) then
        end_info.type = "touchdown"
        end_down = true
      end
    end
    movement.finish(v, step) -- finish move
    network.server_send("char_tile", {k, v.tile_x, v.tile_y})
  end
  -- ball incomplete
  if football.ball_active() and ball.tile >= #ball.full_path then -- incomplete
    end_info.type = "incomplete"
    end_down = true
    ball.caught = true
  end

  if end_down then
    char.end_down()
  end
  return end_down
end

char.tackle = function(player)
  player.path = {}
  player.dead = true
  end_info.type = "tackle"
  end_info.player = player
  end_down = true
end

char.check_tackle = function(id, player, step)
  if char.tackleable(id, player, step) then
    for l, w in pairs(players) do
      if player.team ~= w.team then
        if w.item.active and movement.collision(w.item, player, step) then
          char.tackle(player)
        end
      end
    end
  end
end

char.tackleable = function(id, player, step)
  if (not player.dead and (player.carrier or (not football.get_ball().thrown and id == rules.get_qb()))) then
    for k, v in pairs(players) do
      if v.team == player.team and k ~= id then
        if v.item.active and movement.collision(v.item, player, step) then
          return false
        end
      end
    end
    return true
  else
    return false
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
  for k, v in pairs(players) do -- resolve items
    if v.item.active then
      for l, w in pairs(players) do
        if w.item.active and v.team ~= w.team then -- items can collide
          if v.item.tile_x == w.item.tile_x and v.item.tile_y == w.item.tile_y then -- items occupy same tile, cancel out
            v.item.active = false
            w.item.active = false
          end
        end
      end
    end
  end
  for k, v in pairs(players) do --check for initial item tackle
    char.check_tackle(k, v, 0)
  end
end

char.end_resolve = function(step)
  resolve = false
  for k, v in pairs(players) do -- reset path and abilities
    v.path = {}
    v.item.active = false
    network.server_send("char_tile", {k, v.tile_x, v.tile_y})
  end
  if pos_select then
    pos_select = false
    action = "move"
  elseif end_down then
    rules[end_info.type](end_info.player)
    char.pos_prepare()
    football.clear()
    football.visible(players[id].team)
    end_down = false
  end
  return end_down
end

char.end_down = function()
  for k, v in pairs(players) do
    v.path = {}
    v.xv = 0
    v.yv = 0
  end
end

char.pos_prepare = function()
  action = "position"
  pos_select = true
  for k, v in pairs(players) do
    v.tile_x = math.huge
    v.tile_y = math.huge
    v.x = v.tile_x
    v.y = v.tile_y
    v.dead = false
  end
end

char.get_state = function(id, player)
  if id == rules.get_qb() and not football.get_ball().thrown then
    return "qb"
  elseif player.carrier then
    return "carrier"
  elseif player.team == rules.get_offense() then
    return "offense"
  else
    return "defense"
  end
end

return char
