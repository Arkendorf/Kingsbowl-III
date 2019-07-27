local field = require "field"

local movement = {}

movement.update_object = function(object, dt)
  object.x = object.x + object.xv * dt
  object.y = object.y + object.yv * dt
  if object.xa and object.ya then
    object.xv = object.xv + object.xa * dt
    object.yv = object.yv + object.ya * dt
  end
  if object.goal_x and object.goal_y then -- limits have been established
    local x_dir = object.xv
    local y_dir = object.yv
    if object.xa ~= 0 or object.ya ~= 0 then -- use the sign of acceleration if it exists instead of velocity
      x_dir = object.xa
      y_dir = object.ya
    end
    if (x_dir > 0 and object.x > object.goal_x) or (x_dir < 0  and object.x < object.goal_x) then -- if x position exceeds limit, then stop movement
      object.x = object.goal_x
      object.xv = 0
      object.xa = 0
    end
    if (y_dir > 0 and object.y > object.goal_y) or (y_dir < 0  and object.y < object.goal_y) then -- if y position exceeds limit, then stop movement
      object.y = object.goal_y
      object.yv = 0
      object.ya = 0
    end
  end
end

movement.dist = function(x1, y1, x2, y2)
  local x_dif = x2-x1
  local y_dif = y2-y1
  return math.sqrt(x_dif*x_dif+y_dif*y_dif)
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
  table.remove(path, 1) -- first tile in path is just the current location

  return path
end

movement.cancel = function(object)
  object.path = {}
end

movement.valid = function(x1, y1, x2, y2, max_dist)
  return (movement.dist(x1, y1, x2, y2) <= max_dist and field.in_bounds(x2, y2))
end

movement.bounce = function(object, step, step_time)
  object.goal_x = object.tile_x
  object.goal_y = object.tile_y
  local x_dist = object.path[step].x - object.tile_x
  local y_dist = object.path[step].y - object.tile_y
  object.xv = x_dist * 2 / step_time
  object.yv = y_dist * 2 / step_time
  object.xa = x_dist * -4 / (step_time * step_time)
  object.ya = y_dist * -4 / (step_time * step_time)
end

movement.prepare = function(object, step, step_time)
  if movement.can_move(object, step) then
    object.goal_x = object.path[step].x
    object.goal_y = object.path[step].y
    local x_dist = object.goal_x - object.tile_x
    local y_dist = object.goal_y - object.tile_y
    object.xv = x_dist / step_time
    object.yv = y_dist / step_time
    object.xa = 0
    object.ya = 0
  end
end

movement.finish = function(object, step)
  if movement.can_move(object, step) then
    object.tile_x = object.path[step].x
    object.tile_y = object.path[step].y
    object.x = object.tile_x
    object.y = object.tile_y

    if step >= #object.path then
      object.path = {}
    end
  else
    object.x = object.tile_x
    object.y = object.tile_y
  end
  object.xv = 0
  object.yv = 0
  object.xa = 0
  object.ya = 0
end

movement.can_move = function(object, step)
  if object.path and object.path[step] then
    if step > 0 then
      return #object.path >= step
    end
  end
  return false
end

movement.collision = function(object1, object2, step)
  local x1 = object1.tile_x
  local y1 = object1.tile_y
  if movement.can_move(object1, step) then
    x1 = object1.path[step].x
    y1 = object1.path[step].y
  end
  local x2 = object2.tile_x
  local y2 = object2.tile_y
  if movement.can_move(object2, step) then
    x2 = object2.path[step].x
    y2 = object2.path[step].y
  end
  return (x1 == x2 and y1 == y2)
end

return movement
