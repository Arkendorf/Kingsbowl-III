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
    local x_dir, y_dir = 0, 0
    if object.xa ~= 0 or object.ya ~= 0 then
      x_dir = movement.dir(object.xa)
      y_dir = movement.dir(object.ya)
    else
      x_dir = movement.dir(object.xv)
      y_dir = movement.dir(object.yv)
    end
    -- if object.x * x_dir > object.goal_x * x_dir
  end
  if math.abs(object.x-object.tile_x) >= 1 or math.abs(object.y-object.tile_y) >= 1 then
    object.xv = 0
    object.yv = 0
    object.xa = 0
    object.ya = 0
  end
end

movement.dir = function(num)
  if num > 0 then
    return 1
  elseif num < 0 then
    return -1
  else
    return 0
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

movement.setup = function(object, step)
  object.goal_x = object.path[step].x
  object.goal_y = object.path[step].y
  return (object.goal_x - object.tile_x), (object.goal_y - object.tile_y)
end

movement.bounce = function(object, step, step_time)
  local x_dist, y_dist = movement.setup(object, step)
  object.xv = x_dist * 2 / step_time
  object.yv = y_dist * 2 / step_time
  object.xa = x_dist * -4 / (step_time * step_time)
  object.ya = y_dist * -4 / (step_time * step_time)
end

movement.prepare = function(object, step, step_time)
  if movement.can_move(object, step) then
    local x_dist, y_dist = movement.setup(object, step)
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
