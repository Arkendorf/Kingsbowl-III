local movement = {}

movement.update = function(dt)
  for k, v in pairs(players) do
    if resolve then
      if timer <= (turn_order.max-turn_order[v.state]+1)*turn_delay then
        if not v.resolved then
          if v.state == "defense" then -- check for collisions
            local l, w = movement.collision(k, v)
            if l then -- colliding
              if w.state == "qb" or w.state == "baller" then -- player tackles collider
              elseif w.state == "offense" then -- collider blocks player
              end
            end
          end
          v.grid_x = v.grid_x + v.x_move
          v.grid_y = v.grid_y + v.y_move
          movement.resolve(v)
          network.send("new_pos", {k, v.grid_x, v.grid_y}, true)
        elseif timer >= (turn_order.max-turn_order[v.state])*turn_delay then
          local buffer = move_speed*(turn_time+(turn_order.max-turn_order[v.state])*turn_delay)
          local stolen = move_speed*turn_order[v.state]*turn_delay
          local speed = math.max(0, 1-buffer-stolen)/turn_delay
          movement.lerp(v, v.old_x_move, v.old_y_move, speed*dt)
        else
          movement.lerp(v, v.old_x_move, v.old_y_move, move_speed*dt)
        end
      else
        --insignificant, atmospheric motion (to make things feel fast-paced)
        movement.lerp(v, v.x_move, v.y_move, move_speed*dt)
      end
    else
      movement.lerp(v, v.old_x_move, v.old_y_move, move_speed*dt)
    end
  end
end

movement.mousepressed = function(x, y, button)
  local grid_x = math.floor(x/tile_size)
  local grid_y = math.floor(y/tile_size)
  if math.abs(grid_x-players[id].grid_x) <= 1 and math.abs(grid_y-players[id].grid_y) <= 1 then
    players[id].x_move = grid_x - players[id].grid_x
    players[id].y_move = grid_y - players[id].grid_y
    network.send("new_move", {id, players[id].x_move, players[id].y_move})
  end
end

movement.end_turn = function()
  for k, v in pairs(players) do
    v.x = v.grid_x
    v.y = v.grid_y
    v.resolved = false
  end
end

movement.collision = function(k, v)
  for l, w in pairs(players) do
    if l ~= k then
      if w.grid_x == v.grid_x+v.x_move and w.grid_y == v.grid_y+v.y_move then
        return k, v
      end
    end
  end
  return false
end

movement.lerp = function(v, xv, yv, speed)
  v.x = v.x + xv*speed
  v.y = v.y + yv*speed
end

movement.resolve = function(v)
  v.old_x_move = v.x_move
  v.old_y_move = v.y_move
  v.x_move = 0
  v.y_move = 0
  v.resolved = true
end

return movement
