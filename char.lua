local movement = require "movement"
local rules = require "rules"
local abilities = require "abilities"
local football = require "football"
local camera = require "camera"
local field = require "field"
local window = require "window"
local broadcast = require "broadcast"
local particle = require "particle"
local nui = require "nui"

local char = {}

local show_usernames = false
local players = {}
local knights = {}
local knight_cycle = 1
local knight_id = 1
local action = "move"
local move_dist = {
  qb = 2.5,
  carrier = 2.5,
  defense = 3,
  offense = 3.5
}
local resolve = false
local pos_select = false
local end_down = false
local end_info = {type = "", x = 0}
local replay_active = false

char.load = function(menu_client_list, menu_client_info, menu_team_info, menu_settings, game_replay_active)
  if network_state == "server" then
    network.server_callback("path", function(data, client)
      if char.set_path(data.knight_id, data.x, data.y) then-- double check that the client's path is valid
        abilities.cancel(data.knight_id, knights[data.knight_id])
        network.server_send_except(client.connectId, "path", {data.knight_id, data.x, data.y})
      elseif #knights[data.knight_id].path > 0 then -- if not valid, check to see what the clients previous path was, and send it back
        local tile = knights[data.knight_id].path[#knights[data.knight_id].path]
        network.server_send_client(client.connectId, "path", {data.knight_id, tile.x, tile.y})
      else -- if client had no previous path, tell them to clear their path
        network.server_send_client(client.connectId, "clear_path", data.knight_id)
      end
    end, {"knight_id", "x", "y"})
    network.server_callback("ability", function(data, client)
      if char.use_ability(data.knight_id, data.x, data.y) then -- double check that the client can use an ability
        movement.cancel(knights[data.knight_id])
        network.server_send_except(client.connectId, "ability", {data.knight_id, data.x, data.y})
      elseif knights[data.knight_id].item.active then -- if not valid, check to see if the clients ability was active beforehand, and send them that value
        local item = knights[data.knight_id].item
        network.server_send_client(client.connectId, "ability", {data.knight_id, item.tile_x, item.tile_y})
      else -- if their ability wasn't active, tell them to stop their ability
        network.server_send_client(client.connectId, "stop_ability", data.knight_id)
      end
    end, {"knight_id", "x", "y"})
    network.server_callback("position", function(data, client)
      if rules.set_position(data.knight_id, knights[data.knight_id], data.x, data.y) then -- check if client's position is valid
        network.server_send_except(client.connectId, "position", {data.knight_id, data.x, data.y})
      elseif knights[data.knight_id].tile_x ~= math.huge or knights[data.knight_id].tile_y ~= math.huge then -- if it isn't send client's old position if it exists
        local knight = knights[data.knight_id]
        network.server_send_client(client.connectId, "position", {data.knight_id, knight.tile_x, knight.tile_y})
      else -- if client has not previously selected a position, tell them to reset their position
        network.server_send_client(client.connectId, "reset_position", data.knight_id)
      end
    end, {"knight_id", "x", "y"})
  elseif network_state == "client" then
    network.client_callback("path", function(data)
      abilities.cancel(data.knight_id, knights[data.knight_id])
      char.set_path(data.knight_id, data.x, data.y)
    end, {"knight_id", "x", "y"})
    network.client_callback("clear_path", function(data)
      movement.cancel(knights[data])
    end)
    network.client_callback("ability", function(data)
      movement.cancel(knights[data.knight_id])
      char.use_ability(data.knight_id, data.x, data.y)
    end, {"knight_id", "x", "y"})
    network.client_callback("stop_ability", function(data)
      abilities.cancel(data, knights[data])
    end)
    network.client_callback("position", function(data)
      rules.set_position(data.knight_id, knights[data.knight_id], data.x, data.y)
    end, {"knight_id", "x", "y"})
    network.client_callback("reset_position", function(data)
      knights[data].tile_x = math.huge
      knights[data].tile_y = math.huge
      knights[data].x = knights[data].tile_x
      knights[data].y = knights[data].tile_y
    end)
    network.client_callback("knight_tile", function(data)
      knights[data.knight_id].tile_x = data.x
      knights[data.knight_id].tile_y = data.y
    end, {"knight_id", "x", "y"})
    network.client_callback("pos_select", function(data)
      pos_select = data
    end)
    network.client_callback("tackle", function(data)
      char.tackle(data.knight_id, knights[data.knight_id], knights[data.tackle_id], data.step, data.step_time)
      abilities.flourish(knights[data.tackle_id], data.step_time, data.sheath)
      char.end_down(data.step_time)
    end, {"knight_id", "tackle_id", "step", "step_time", "sheath"})
    network.client_callback("catch", function(data)
      char.catch_broadcast(knights[data])
      char.catch(data, knights[data])
      knights[data].carrier = true
    end)
    network.client_callback("touchdown", function(data)
      char.touchdown(knights[data.knight_id])
      char.end_down(data.step_time)
    end, {"knight_id", "step_time"})
    network.client_callback("incomplete", function(data)
      char.incomplete()
      char.end_down(data)
    end)
    network.client_callback("start_select", function()
      char.start_select()
    end)
    network.client_callback("finish_select", function()
      char.finish_select()
    end)
  end

  players = {}
  knights = {}
  for i, v in ipairs(menu_client_list) do
    players[v] = {username = menu_client_info[v].username, team = menu_client_info[v].team, tile_x = 3+i, tile_y = 3+i, path = {}, x = 3+i, y = 3+i, xv = 0, yv = 0, item = {active = false}, stats = {0, 0, 0}, knights = {}}
    for j = 1, menu_settings.knights do
      local index = #knights+1
      knights[index] = {player = v, team = menu_client_info[v].team, tile_x = 3+i, tile_y = 3+i, path = {}, x = 3+i, y = 3+i, xv = 0, yv = 0, item = {active = false}}
      players[v].knights[j] = index
    end
  end
  knight_cycle = 1
  char.cycle_knight(0)

  replay_active = game_replay_active

  show_usernames = false

  char.pos_prepare()
  football.visible(players[id].team)
  rules.set_team(players[id].team)
  resolve = false
  end_down = false
end

char.update = function(dt)
  for i, v in ipairs(knights) do
    movement.update_object(v, dt)
    if v.item.visible then
      abilities.update_item(v, dt)
    end
  end
  -- camera
  local object = knights[knight_id]
  if replay_active then
    local ball = football.get_ball()
    if ball.thrown then
      if ball.carrier then
        object = knights[ball.carrier]
      else
        object = ball
      end
    else
      object = knights[rules.get_qb()]
    end
  end
  if not object or object.x == math.huge or object.y == math.huge then
    camera.scrimmage()
  else
    camera.object(object)
  end

  abilities.update_hud(knight_id, knights[knight_id], action, dt)
end


char.draw = function()
  for i, v in ipairs(knights) do -- draw stationary knights first
    if #v.path <= 0 then
      char.draw_char(i, v)
    end
  end
  for i, v in ipairs(knights) do -- draw moving knights first
    if #v.path > 0 then
      char.draw_char(i, v)
    end
  end
  for i, v in ipairs(knights) do -- draw items
    abilities.draw_item(v, players[id].team, resolve)
  end
  if not replay_active then
    char.draw_paths()
  end
end

char.draw_paths = function()
  char.preview()
  for i, v in ipairs(knights) do -- draw paths
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
    if action == "position" then
      rules.preview_position(knight_id, knights[knight_id], tile_x, tile_y)
    elseif action == "move" then
      char.preview_path(knight_id, tile_x, tile_y)
    elseif action == "ability" then
      local type = abilities.type(knight_id, knights[knight_id])
      if type == "throw" then
        abilities.preview_throw(knights[knight_id], tile_x, tile_y)
      elseif type == "item" then
        abilities.preview_item(knight_id, knights[knight_id], knights, tile_x, tile_y)
      else
        art.path_icon(4, tile_x, tile_y, colors.red[1], colors.red[2], colors.red[3])
      end
    end
  end
end

char.draw_char = function(i, v)
  local state = char.get_state(i, v)
  local quad = 1
  if not pos_select then
    if state == "qb" then
      quad = 2
    elseif state == "carrier" then
      quad = 3
    elseif v.dead then
      quad = 4
    end
  end
  if v.tile_x ~= math.huge and v.tile_y ~= math.huge then
    if not replay_active and i == knight_id then
      art.draw_quad("char", art.quad.char[v.team][quad], v.x-8/tile_size, v.y-8/tile_size, colors.white[1], colors.white[2], colors.white[3], "outline")
    end
    if not pos_select or v.team == players[id].team then
      art.draw_quad("char", art.quad.char[v.team][quad], v.x-8/tile_size, v.y-8/tile_size)
      art.draw_quad("char_overlay", art.quad.char[v.team][quad], v.x-8/tile_size, v.y-8/tile_size, 1, 1, 1, "color", palette[rules.get_color(v.team)])
    end
    if show_usernames then
      love.graphics.setFont(smallfont)
      love.graphics.printf(players[v.player].username, math.floor((v.x-1)*tile_size), math.floor(v.y*tile_size+12), tile_size*3, "center")
      love.graphics.setColor(palette[rules.get_color(v.team)][2])
      love.graphics.setFont(smallfont_overlay)
      love.graphics.printf(players[v.player].username, math.floor((v.x-1)*tile_size), math.floor(v.y*tile_size+12), tile_size*3, "center")
      love.graphics.setColor(1, 1, 1)
      love.graphics.setFont(font)
    end
  end
end

char.cycle_knight = function(dir)
  knight_cycle = knight_cycle + dir
  if knight_cycle > #players[id].knights then
    knight_cycle = 1
  elseif knight_cycle < 1 then
    knight_cycle = #players[id].knights
  end
  knight_id = players[id].knights[knight_cycle]
end

char.keypressed = function(key)
  if not pos_select then
    if key == "1" then
      action = "move"
    elseif key == "2" then
      action = "ability"
    end
  end
  if key == "space" then
    char.cycle_knight(1)
  elseif key == "lshift" then
    char.cycle_knight(-1)
  elseif key == "i" then
    char.toggle_usernames()
  end
end

char.mousepressed = function(x, y, button)
  if not resolve and not knights[knight_id].dead then
    local offset_x, offset_y = camera.get_offset()
    x = x-offset_x
    y = y-offset_y
    local tile_x = math.floor(x/tile_size)
    local tile_y = math.floor(y/tile_size)
    tile_x, tile_y = field.cap_tile(tile_x, tile_y)
    local valid = false
    if action == "move" then
      if char.set_path(knight_id, tile_x, tile_y) then
        abilities.cancel(knight_id, knights[knight_id])
        network.server_send("path", {knight_id, tile_x, tile_y})
        network.client_send("path", {knight_id, tile_x, tile_y})
        valid = true
      end
    elseif action == "ability" then
      if char.use_ability(knight_id, tile_x, tile_y) then
        movement.cancel(knights[knight_id])
        network.server_send("ability", {knight_id, tile_x, tile_y})
        network.client_send("ability", {knight_id, tile_x, tile_y})
        valid = true
      end
    elseif action == "position" then -- choose position to start next down
      if rules.set_position(knight_id, knights[knight_id], tile_x, tile_y) then
        network.server_send("position", {knight_id, tile_x, tile_y})
        network.client_send("position", {knight_id, tile_x, tile_y})
        valid = true
      end
    end
    if valid then
      particle.add("click", tile_x, tile_y, "green")
    else
      particle.add("click", tile_x, tile_y, "red")
    end
  end
end

char.use_ability = function(knight_id, tile_x, tile_y)
  if abilities.overlap(knight_id, knights[knight_id], knights, tile_x, tile_y) then
    return false
  end
  return abilities.use(knight_id, knights[knight_id], tile_x, tile_y)
end

char.set_path = function(knight_id, tile_x, tile_y)
  if movement.valid(knights[knight_id].tile_x, knights[knight_id].tile_y, tile_x, tile_y, move_dist[char.get_state(knight_id, knights[knight_id])]) then
    local path = movement.get_path(knights[knight_id].tile_x, knights[knight_id].tile_y, tile_x, tile_y)
    if path then
      if not char.path_collision(knight_id, path, knights[knight_id].team) then
        knights[knight_id].path = path
        return true
      end
    end
  end
  return false
end

char.preview_path = function(knight_id, tile_x, tile_y)
  local dist = move_dist[char.get_state(knight_id, knights[knight_id])]
  if movement.valid(knights[knight_id].tile_x, knights[knight_id].tile_y, tile_x, tile_y, dist) then
    local path = movement.get_path(knights[knight_id].tile_x, knights[knight_id].tile_y, tile_x, tile_y)
    if #path > 0 then
      local collide = char.path_collision(knight_id, path, knights[knight_id].team)
      if collide then
        path[collide].icon = 3
        movement.draw_path(knights[knight_id].tile_x, knights[knight_id].tile_y, path, colors.red[1], colors.red[2], colors.red[3])
      else
        local intersect = football.path_intersect(path)
        if intersect then
          path[intersect].icon = 2
        end
        movement.draw_path(knights[knight_id].tile_x, knights[knight_id].tile_y, path, colors.green[1], colors.green[2], colors.green[3])
      end
    end
  else
    art.path_icon(4, tile_x, tile_y, colors.red[1], colors.red[2], colors.red[3])
    art.path_border(knights[knight_id].tile_x, knights[knight_id].tile_y, dist, movement.valid, dist)
  end
end

char.step_num = function()
  local num = 0
  for i, v in ipairs(knights) do
    if #v.path > num then
      num = #v.path
    end
    if v.item.active and num <= 0 then
      num = 1
    end
  end
  return num
end

char.path_collision = function(knight_id, path, team)
  local step_num = char.step_num()
  for i, v in ipairs(knights) do
    if knight_id ~= i and v.team == team then
      if #v.path > 0 then
        for j = 1, step_num do
          if v.path[j] and path[j] then
            if v.path[j].x == path[j].x and v.path[j].y == path[j].y then -- check for overlapping intermediate steps in path
              return j
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

char.get_knights = function()
  return knights
end

char.prepare = function(step, step_time, max_step)
  local step_change = false
  local collision = true
  while collision do -- adjust paths based on collisions
    collision = false
    for i, v in ipairs(knights) do
      if movement.can_move(v, step) then -- knights can only be bounced if they are moving
        for j, w in ipairs(knights) do
          if i ~= j and not w.dead then -- knights can only collide with other non-dead knights
            if v.team ~= rules.get_offense() or not movement.can_move(w, step) then -- only defense can be bounced, unless offense is colliding with stationary knight
              if movement.collision(v, w, step) then
                if v.team ~= w.team and char.tackleable(i, v) and not char.shielded(i, v, step, step_time, max_step) then
                  char.tackle(i, v, w, step, step_time)
                  movement.cancel(w)
                elseif v.team ~= w.team and char.tackleable(j, w) and not char.shielded(j, w, step, step_time, max_step) then
                  char.tackle(j, w, v, step, step_time)
                  movement.cancel(v)
                elseif movement.can_move(v, step) then
                  movement.bounce(v, v.tile_x, v.tile_y, v.path[step].x, v.path[step].y, step_time, .5)
                  movement.cancel(v)
                end
                collision = true
                step_change = true
              end
            end
          end
        end
      end
    end
  end
  for i, v in ipairs(knights) do -- actual movement
    if movement.can_move(v, step) then
      movement.prepare(v, v.tile_x, v.tile_y, v.path[step].x, v.path[step].y, step_time)
    end
  end
  return step_change
end

char.finish = function(step, step_time, max_step)
  local ball = football.get_ball()
  for i, v in ipairs(knights) do
    movement.finish(v, step) -- finish move
    if network_state == "server" then
      network.server_send("knight_tile", {i, v.tile_x, v.tile_y})
      -- check for item tackle
      local tackle_id, tackler = char.check_tackle(i, v, step, step_time)
      if tackle_id then
        abilities.flourish(tackler, step_time, step >= max_step)
        network.server_send("tackle", {i, tackle_id, step, step_time, step >= max_step})
      end
      -- ball catching
      if football.ball_active() and movement.collision(ball, v, step) then -- ball and knight are colliding
        char.catch_broadcast(v)
        char.catch(i, v)
        v.carrier = true
        network.server_send("catch", i)
      end
      -- check for td
      if char.tackleable(i, v) then
        if rules.check_td(v, step) then
          char.touchdown(v)
          network.server_send("touchdown", {i, step_time})
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

char.catch = function(knight_id, knight)
  if football.catch(knight_id, knight) then
    local qb = rules.get_qb()
    players[knights[qb].player].stats[1] = players[knights[qb].player].stats[1] + 1
  end
  particle.add("catch", knight.tile_x, knight.tile_y)
end

char.incomplete = function()
  char.incomplete_broadcast()
  end_info.type = "incomplete"
  end_down = true
  local ball = football.get_ball()
  ball.caught = true
  particle.add("stuck", ball.tile_x, ball.tile_y)
end

char.touchdown = function(knight)
  char.touchdown_broadcast(knight)
  end_info.type = "touchdown"
  end_down = true
  particle.add("confetti", knight.tile_x, knight.tile_y, false, "color", palette[rules.get_color(knight.team)])
end

char.tackle = function(knight_id, knight, tackler, step, step_time)
  local x, y = movement.get_pos(knight, step)
  particle.add("stab", x, y)
  particle.add("blood", x, y)
  char.tackle_broadcast(knight_id, knight, tackler)
  knight.dead = true
  end_info.type = "tackle"
  end_info.x = knight.tile_x
  end_down = true
  if not tackler.item.active then
    abilities.stab(knight, tackler, step, step_time)
  end
  players[tackler.player].stats[2] = players[tackler.player].stats[2] + 1
end

char.check_tackle = function(knight_id, knight, step)
  if char.tackleable(knight_id, knight) then
    for i, v in ipairs(knights) do
      if knight.team ~= v.team then
        if v.item.active and movement.collision(v.item, knight, step) then
          char.tackle(knight_id, knight, v)
          movement.cancel(knight)
          return i, v
        end
      end
    end
  end
  return false
end

char.tackleable = function(knight_id, knight)
  return (not knight.dead and (knight.carrier or (not football.get_ball().thrown and knight_id == rules.get_qb())))
end

char.shielded = function(knight_id, knight, step, step_time, max_step)
  for i, v in ipairs(knights) do
    if v.team == knight.team and i ~= knight_id then
      if v.item.active and movement.collision(v.item, knight, step) then
        if step > 1 then
          abilities.flourish(v, step_time, step >= max_step)
        end
        char.shield(players[v.player], knight.tile_x, knight.tile_y)
        return true
      end
    end
  end
  return false
end

char.shield = function(player, x, y)
  player.stats[3] = player.stats[3] + 1
  particle.add("shield", x, y)
end

char.start_resolve = function(step_time)
  resolve = true
  if pos_select then -- assign positions and qb if not selected
    for i, v in ipairs(knights) do
      if v.tile_x == math.huge or v.tile_y == math.huge then -- knight never selected a tile
        rules.give_position(i, v)
      end
    end
    rules.ensure_qb(knights) -- make sure a qb exists
  end
  char.item_collide(step_time)
  for i, v in ipairs(knights) do --check for initial item tackle
    char.check_tackle(i, v, 0)
  end
end

char.item_collide = function(step_time)
  for i, v in ipairs(knights) do
    abilities.set(v, step_time)
  end
  for i, v in ipairs(knights) do
    if abilities.collide(i, v, knights, step_time) then
      for j, w in ipairs(knights) do
        if char.tackleable(j, w) and w.tile_x == v.item.new_x and w.tile_y == v.item.new_y then
          char.shield(players[v.player], w.tile_x, w.tile_y)
        end
      end
    end
  end
end

char.end_resolve = function(step, step_time)
  resolve = false
  for i, v in ipairs(knights) do -- reset path and abilities
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
  end_down = true
  for i, v in ipairs(knights) do
    movement.cancel(v)
    abilities.reset.item(v, step_time)
    v.carrier = false
  end
end

char.pos_prepare = function()
  pos_select = true
  action = "position"
  for i, v in ipairs(knights) do
    rules.prepare_position(i, v)
    v.dead = false
  end
end

char.get_state = function(knight_id, knight)
  if knight_id == rules.get_qb() and not football.get_ball().thrown then
    return "qb"
  elseif knight.carrier then
    return "carrier"
  elseif knight.team == rules.get_offense() then
    return "offense"
  else
    return "defense"
  end
end

char.get_move_dist = function()
  return move_dist
end

char.toggle_usernames = function()
  show_usernames = not show_usernames
  nui.active("", "username", show_usernames)
  nui.edit.element("", "username", "active", show_usernames)
end

char.save_turn = function()
  local turn_info = {}
  for i, v in ipairs(knights) do
    local action = false
    local click_x = false
    local click_y = false
    local ability_type = abilities.type(i, v)
    local ball = football.get_ball()
    if #v.path > 0 then -- normal movement
      action = "move"
      click_x = v.path[#v.path].x
      click_y = v.path[#v.path].y
    elseif (ability_type == "item" and v.item.active) then -- item use
      action = "ability"
      click_x = v.item.new_x
      click_y = v.item.new_y
    elseif (ability_type == "throw" and ball.primed and not ball.thrown) then -- throw ball
      action = "ability"
      click_x = ball.full_path[#ball.full_path].x
      click_y = ball.full_path[#ball.full_path].y
    elseif pos_select and v.tile_x ~= math.huge and v.tile_y ~= math.huge then -- pos select
      action = "position"
      click_x = v.tile_x
      click_y = v.tile_y
    end
    turn_info[i] = {tile_x = v.tile_x, tile_y = v.tile_y, action = action, click_x = click_x, click_y = click_y}
  end
  return turn_info
end

char.load_turn = function(turn_info)
  for i, v in ipairs(knights) do
    if not turn_info[i] then -- player must have left if no data is saved for them
      char.remove_player(v.player)
    end
  end
  for i, v in ipairs(turn_info) do
    knights[i].tile_x = v.tile_x
    knights[i].tile_y = v.tile_y
    knights[i].x = knights[i].tile_x
    knights[i].y = knights[i].tile_y
    if v.action then
      if v.action == "move" then
        char.set_path(i, v.click_x, v.click_y)
      elseif v.action == "ability" then
        char.use_ability(i, v.click_x, v.click_y)
      elseif v.action == "position" then
        rules.set_position(i, knights[i], v.click_x, v.click_y)
      end
    end
  end
end

char.remove_player = function(id)
  broadcast.new(tostring(players[id].username).. " has left", "yellow")
  for i, v in ipairs(players[id].knights) do
    if char.tackleable(v, knights[v]) then -- if player with ball leaves, reset down
      end_info.type = "tackle"
      end_info.x = knights[v].tile_x
      end_down = true
    end
    knights[v] = nil
  end
  local team = players[id].team
  players[id] = nil
  for k, v in pairs(players) do
    if v.team == team then
      return false
    end
  end
  return true
end

char.touchdown_broadcast = function(knight)
  char.broadcast(tostring(players[knight.player].username).." has scored a touchdown for "..rules.get_name(knight.team).."!", knight.team)
end

char.catch_broadcast = function(knight)
  if knight.team == rules.get_offense() then
    char.broadcast(tostring(players[knight.player].username).." has caught the ball", knight.team)
  else
    char.broadcast(tostring(players[knight.player].username).." has intercepted the ball!", knight.team)
  end
end

char.tackle_broadcast = function(knight_id, knight, tackler)
  if knight_id == rules.get_qb() then
    char.broadcast(tostring(players[knight.player].username).." has been sacked by "..tostring(players[tackler.player].username), tackler.team)
  else
    char.broadcast(tostring(players[knight.player].username).." has been tackled by "..tostring(players[tackler.player].username), tackler.team)
  end
end

char.incomplete_broadcast = function()
  if rules.get_offense() == 1 then
    char.broadcast("Incomplete", 2)
  else
    char.broadcast("Incomplete", 1)
  end
end

char.broadcast = function(txt, team)
  if team == players[id].team then
    broadcast.new(txt, "green")
  else
    broadcast.new(txt, "red")
  end
end

return char
