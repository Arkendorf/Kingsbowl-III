local field = require "field"

local movement = {}

movement.load = function()
end

movement.update_player = function(player, dt)
  player.x = player.x + player.xv * dt
  player.y = player.y + player.yv * dt
end


movement.dist = function(x1, y1, x2, y2)
  local x_dif = x2-x1
  local y_dif = y2-y1
  return math.sqrt(x_dif*x_dif+y_dif*y_dif)
end

movement.get_path = function(x1, y1, x2, y2)
  if field.in_bounds(x2, y2) then
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
    table.remove(path, 1) -- first tile in path is just the current location

    return path
  end
end

movement.valid = function(x1, y1, x2, y2, max_dist)
  return movement.dist(x1, y1, x2, y2) <= max_dist
end

movement.prepare = function(player, step, step_time)
  if #player.path >= step then
    local x_dist = (player.path[step].x - player.tile_x)
    local y_dist = (player.path[step].y - player.tile_y)
    player.xv = x_dist / step_time
    player.yv = y_dist / step_time
  end
end

movement.finish = function(player, step)
  if #player.path >= step then
    player.tile_x = player.path[step].x
    player.tile_y = player.path[step].y
    player.x = player.tile_x
    player.y = player.tile_y
    player.xv = 0
    player.yv = 0

    if step >= #player.path then
      player.path = {}
    end
  end
end

return movement
