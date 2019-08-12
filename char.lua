local movement = require "movement"
local rules = require "rules"
local abilities = require "abilities"
local football = require "football"
local camera = require "camera"
local field = require "field"
local window = require "window"

local char = {}
local players = {}
local action = "move"
local move_dist = {
  qb = 22.5,
  carrier = 2.5,
  defense = 3,
  offense = 23.5
}
local resolve = false
local pos_select = false
local end_down = false
local end_info = {type = "", player = 0}

char.load = function(menu_client_list, menu_client_info, menu_team_info)
  if network_state == "server" then
    server:setSchema("path", {"x", "y"})
    server:on("path", function(data, client)
      if char.set_path(client.connectId, data.x, data.y) then-- double check that the client's path is valid
        abilities.cancel(client.connectId, players[client.connectId])
        network.server_send_except(client.connectId, "path", {client.connectId, data.x, data.y})
      elseif #players[client.connectId].path > 0 then -- if not valid, check to see what the clients previous path was, and send it back
        local tile = players[client.connectId].path[#players[client.connectId].path]
        network.server_send_client(client.connectId, "path", {client.connectId, tile.x, tile.y})
      else -- if client had no previous path, tell them to clear their path
        network.server_send_client(client.connectId, "clear_path", client.connectId)
      end
    end)
    server:setSchema("ability", {"x", "y"})
    server:on("ability", function(data, client)
      if char.use_ability(client.connectId, data.x, data.y) then -- double check that the client can use an ability
        movement.cancel(players[client.connectId])
        network.server_send_except(client.connectId, "ability", {client.connectId, data.x, data.y})
      elseif players[client.connectId].item.active then -- if not valid, check to see if the clients ability was active beforehand, and send them that value
        local item = players[client.connectId].item
        network.server_send_client(client.connectId, "ability", {client.connectId, item.tile_x, item.tile_y})
      else -- if their ability wasn't active, tell them to stop their ability
        network.server_send_client(client.connectId, "stop_ability", client.connectId)
      end
    end)
    server:setSchema("position", {"x", "y"})
    server:on("position", function(data, client)
      if rules.set_position(client.connectId, players[client.connectId], data.x, data.y) then -- check if client's position is valid
        network.server_send_except(client.connectId, "position", {client.connectId, data.x, data.y})
      elseif players[client.connectId].tile_x ~= math.huge or players[client.connectId].tile_y ~= math.huge then -- if it isn't send client's old position if it exists
        local player = players[client.connectId]
        network.server_send_client(client.connectId, "position", {client.connectId, player.tile_x, player.tile_y})
      else -- if client has not previously selected a position, tell them to reset their position
        network.server_send_client(client.connectId, "reset_position", client.connectId)
      end
    end)
  elseif network_state == "client" then
    client:setSchema("path", {"id", "x", "y"})
    client:on("path", function(data)
      abilities.cancel(data.id, players[data.id])
      char.set_path(data.id, data.x, data.y)
    end)
    client:on("clear_path", function(data)
      movement.cancel(players[data])
    end)
    client:setSchema("ability", {"id", "x", "y"})
    client:on("ability", function(data)
      movement.cancel(players[data.id])
      char.use_ability(data.id, data.x, data.y)
    end)
    client:on("stop_ability", function(data)
      abilities.cancel(data, players[data])
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
    client:on("pos_select", function(data)
      pos_select = data
    end)
    client:setSchema("tackle", {"id", "tackle_id", "step_time", "sheath"})
    client:on("tackle", function(data)
      char.tackle(players[data.id], players[data.tackle_id], data.step_time)
      abilities.flourish(players[data.tackle_id], data.step_time, data.sheath)
      char.end_down(data.step_time)
    end)
    client:on("catch", function(data)
      football.catch(data, players[data], players)
      players[data].carrier = true
    end)
    client:on("touchdown", function(data)
      end_info.type = "touchdown"
      end_down = true
      char.end_down(data)
    end)
    client:on("incomplete", function(data)
      char.incomplete()
      char.end_down(data)
    end)
    client:on("start_select", function()
      char.start_select()
    end)
    client:on("finish_select", function()
      char.finish_select()
    end)
  end

  players = {}
  for i, v in ipairs(menu_client_list) do
    players[v] = {username = menu_client_info[v].username, team = menu_client_info[v].team, tile_x = 3+i, tile_y = 3+i, path = {}, x = 3+i, y = 3+i, xv = 0, yv = 0, item = {active = false}, stats = {0, 0, 0}}
  end

  char.pos_prepare()
  football.visible(players[id].team)
  rules.set_team(players[id].team)
  resolve = false
end

char.update = function(dt)
  for k, v in pairs(players) do
    movement.update_object(v, dt)
    if v.item.visible then
      abilities.update_item(v, dt)
    end
  end
  if pos_select then
    camera.scrimmage()
  else
    camera.player(players[id])
  end
end

char.update_hud = function(dt)
  abilities.update_hud(id, players[id], action, dt)
end

char.draw = function()
  char.draw_paths()
  for k, v in pairs(players) do -- draw stationary players first
    if #v.path <= 0 then
      char.draw_char(k, v)
    end
  end
  for k, v in pairs(players) do -- draw moving players first
    if #v.path > 0 then
      char.draw_char(k, v)
    end
  end
  for k, v in pairs(players) do -- draw items
    abilities.draw_item(v, players[id].team, resolve)
  end
end

char.draw_paths = function()
  char.preview()
  for k, v in pairs(players) do -- draw paths
    if not resolve and players[id].team == v.team then -- if on the same team, draw path
      movement.draw_path(v.tile_x, v.tile_y, v.path, colors.white[1], colors.white[2], colors.white[3])
    end
  end
end

char.preview = function()
  if not resolve then
    local x, y = window.get_mouse()
    local offset_x, offset_y = camera.get_offset()
    local tile_x = math.floor((x-offset_x)/tile_size)
    local tile_y = math.floor((y-offset_y)/tile_size)
    tile_x, tile_y = field.cap_tile(tile_x, tile_y)
    if action == "move" then
      char.preview_path(id, tile_x, tile_y)
    elseif action == "ability" then
      if abilities.type(id, players[id]) == "throw" then
        abilities.preview_throw(players[id], tile_x, tile_y)
      else
        abilities.preview_item(id, players[id], players, tile_x, tile_y)
      end
    end
  end
end

char.draw_char = function(k, v)
  local state = char.get_state(k, v)
  local quad = 1
  if state == "qb" then
    quad = 2
  elseif state == "carrier" then
    quad = 3
  elseif v.dead then
    quad = 4
  end
  if pos_select then
    if v.team == players[id].team then
      art.draw_quad("char", art.quad.char[v.team][1], v.x-8/tile_size, v.y-8/tile_size, colors.white[1], colors.white[2], colors.white[3], "outline")
    end
  else
    art.draw_quad("char", art.quad.char[v.team][quad], v.x-8/tile_size, v.y-8/tile_size)
    art.draw_quad("char_overlay", art.quad.char[v.team][quad], v.x-8/tile_size, v.y-8/tile_size, 1, 1, 1, "color", palette[rules.get_color(v.team)])
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
    local offset_x, offset_y = camera.get_offset()
    x = x-offset_x
    y = y-offset_y
    local tile_x = math.floor(x/tile_size)
    local tile_y = math.floor(y/tile_size)
    tile_x, tile_y = field.cap_tile(tile_x, tile_y)
    if action == "move" then
      if char.set_path(id, tile_x, tile_y) then
        abilities.cancel(id, players[id])
        network.server_send("path", {id, tile_x, tile_y})
        network.client_send("path", {tile_x, tile_y})
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
  if abilities.overlap(id, players[id], players, tile_x, tile_y) then
    return false
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

char.preview_path = function(id, tile_x, tile_y)
  local dist = move_dist[char.get_state(id, players[id])]
  if movement.valid(players[id].tile_x, players[id].tile_y, tile_x, tile_y, dist) then
    local path = movement.get_path(players[id].tile_x, players[id].tile_y, tile_x, tile_y)
    if #path > 0 then
      local collide = char.path_collision(id, path, players[id].team)
      if collide then
        path[collide].icon = 3
        movement.draw_path(players[id].tile_x, players[id].tile_y, path, colors.red[1], colors.red[2], colors.red[3])
      else
        local intersect = football.path_intersect(path)
        if intersect then
          path[intersect].icon = 2
        end
        movement.draw_path(players[id].tile_x, players[id].tile_y, path, colors.green[1], colors.green[2], colors.green[3])
      end
    end
  else
    art.path_icon(4, tile_x, tile_y, colors.red[1], colors.red[2], colors.red[3])
    art.path_border(players[id].tile_x, players[id].tile_y, dist, movement.valid, dist)
  end
end

char.step_num = function()
  local num = 0
  for k, v in pairs(players) do
    if #v.path > num then
      num = #v.path
    end
    if v.item.active and num <= 0 then
      num = 1
    end
  end
  return num
end

char.path_collision = function(id, path, team)
  local step_num = char.step_num()
  for k, v in pairs(players) do
    if id ~= k and v.team == team then
      if #v.path > 0 then
        for i = 1, step_num do
          if v.path[i] and path[i] then
            if v.path[i].x == path[i].x and v.path[i].y == path[i].y then -- check for overlapping intermediate steps in path
              return i
            end
          end
        end
        if v.path[#v.path].x == path[#path].x and v.path[#v.path].y == path[#path].y then -- check for overlapping final destinations
          return #path
        end
      elseif v.tile_x == path[#path].x and v.tile_y == path[#path].y then -- if teammate is stationary and wont move, make sure path doesn't end up on that tile
        return #path
      end
    end
  end
  return false
end

char.get_players = function()
  return players
end

char.prepare = function(step, step_time, max_step)
  local step_change = false
  local collision = true
  while collision do -- adjust paths based on collisions
    collision = false
    for k, v in pairs(players) do
      if movement.can_move(v, step) then -- players can only be bounced if they are moving
        for l, w in pairs(players) do
          if v.team ~= w.team and not w.dead then -- players can only collide with non-dead members of the opposite team
            if v.team ~= rules.get_offense() or not movement.can_move(w, step) then -- only defense can be bounced, unless offense is colliding with stationary player
              if movement.collision(v, w, step) then
                if char.tackleable(k, v) and not char.shielded(k, v, step, step_time, max_step) then
                  char.tackle(v, w, step_time)
                elseif char.tackleable(l, w) and not char.shielded(l, w, step, step_time, max_step) then
                  char.tackle(w, v, step_time)
                else
                  movement.bounce(v, v.tile_x, v.tile_y, v.path[step].x, v.path[step].y, step_time, .5)
                end
                movement.cancel(v)
                collision = true
                step_change = true
              end
            end
          end
        end
      end
    end
  end
  for k, v in pairs(players) do -- actual movement
    if movement.can_move(v, step) then
      movement.prepare(v, v.tile_x, v.tile_y, v.path[step].x, v.path[step].y, step_time)
    end
  end
  return step_change
end

char.finish = function(step, step_time, max_step)
  local ball = football.get_ball()
  for k, v in pairs(players) do
    movement.finish(v, step) -- finish move
    if network_state == "server" then
      network.server_send("char_tile", {k, v.tile_x, v.tile_y})
      -- check for item tackle
      local tackle_id, tackler = char.check_tackle(k, v, step, step_time)
      if tackle_id then
        abilities.flourish(tackler, step_time, step >= max_step)
        network.server_send("tackle", {k, tackle_id, step_time, step >= max_step})
      end
      -- ball catching
      if football.ball_active() and movement.collision(ball, v, step) then -- ball and player are colliding
        football.catch(k, v, players)
        v.carrier = true
        network.server_send("catch", k)
      end
      -- check for td
      if char.tackleable(k, v) then
        if rules.check_td(v, step) then
          end_info.type = "touchdown"
          end_down = true
          network.server_send("touchdown", step_time)
        end
      end
    end
  end
  -- ball incomplete
  if network_state == "server" then
    if football.ball_active() and ball.tile >= #ball.full_path then -- incomplete
      char.incomplete()
      network.server_send("incomplete", step_time)
    end
  end

  if end_down then
    char.end_down(step_time)
  end
  return end_down
end

char.incomplete = function()
  end_info.type = "incomplete"
  end_down = true
  local ball = football.get_ball()
  ball.caught = true
end

char.tackle = function(player, tackler, step_time)
  movement.cancel(player)
  player.dead = true
  end_info.type = "tackle"
  end_info.x = player.tile_x
  end_down = true
  if not tackler.item.active then
    abilities.stab(player, tackler, step_time)
  end
  tackler.stats[2] = tackler.stats[2] + 1
end

char.check_tackle = function(id, player, step)
  if char.tackleable(id, player) then
    for l, w in pairs(players) do
      if player.team ~= w.team then
        if w.item.active and movement.collision(w.item, player, step) then
          char.tackle(player, w)
          return l, w
        end
      end
    end
  end
  return false
end

char.tackleable = function(id, player)
  return (not player.dead and (player.carrier or (not football.get_ball().thrown and id == rules.get_qb())))
end

char.shielded = function(id, player, step, step_time, max_step)
  for k, v in pairs(players) do
    if v.team == player.team and k ~= id then
      if v.item.active and movement.collision(v.item, player, step) then
        if step > 1 then
          abilities.flourish(v, step_time, step >= max_step)
        end
        v.stats[3] = v.stats[3] + 1
        return true
      end
    end
  end
  return false
end

char.start_resolve = function(step_time)
  resolve = true
  if pos_select then -- assign positions and qb if not selected
    for k, v in pairs(players) do
      if v.tile_x == math.huge or v.tile_y == math.huge then -- player never selected a tile
        rules.give_position(k, v)
      end
    end
    rules.ensure_qb(players) -- make sure each team has a qb
  end
  char.item_collide(step_time)
  for k, v in pairs(players) do --check for initial item tackle
    char.check_tackle(k, v, 0)
  end
end

char.item_collide = function(step_time)
  for k, v in pairs(players) do
    abilities.set(v, step_time)
  end
  for k, v in pairs(players) do
    if abilities.collide(k, v, players, step_time) then
      for l, w in pairs(players) do
        if char.tackleable(l, w) and w.tile_x == v.item.new_x and w.tile_y == v.item.new_y then
          v.stats[3] = v.stats[3] + 1
        end
      end
    end
  end
end

char.end_resolve = function(step, step_time)
  resolve = false
  for k, v in pairs(players) do -- reset path and abilities
    movement.cancel(v)
    abilities.reset.item(v, step_time)
  end
  if network_state == "server" then
    if pos_select then
      char.finish_select()
      network.server_send("finish_select")
    elseif end_down then
      char.start_select()
      network.server_send("start_select")
    end
  end
end

char.start_select = function()
  rules[end_info.type](end_info.x)
  char.pos_prepare()
  football.clear()
  football.visible(players[id].team)
  end_down = false
  rules.start_select()
end

char.finish_select = function()
  pos_select = false
  action = "move"
  rules.finish_select()
end

char.end_down = function(step_time)
  for k, v in pairs(players) do
    movement.cancel(v)
    abilities.reset.item(v, step_time)
    v.carrier = false
  end
end

char.pos_prepare = function()
  pos_select = true
  action = "position"
  for k, v in pairs(players) do
    rules.prepare_position(k, v)
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

char.get_move_dist = function()
  return move_dist
end

return char
