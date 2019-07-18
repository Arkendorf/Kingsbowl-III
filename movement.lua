local field = require "field"

local movement = {}

movement.load = function()
end

movement.update_object = function(object, dt)
  object.x = object.x + object.xv * dt
  object.y = object.y + object.yv * dt
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

movement.prepare = function(object, step, step_time)
  if movement.can_move(object, step) then
    local x_dist = (object.path[step].x - object.tile_x)
    local y_dist = (object.path[step].y - object.tile_y)
    object.xv = x_dist / step_time
    object.yv = y_dist / step_time
  end
end

movement.finish = function(object, step)
  if step > 0 then
    if movement.can_move(object, step) then
      object.tile_x = object.path[step].x
      object.tile_y = object.path[step].y
      object.x = object.tile_x
      object.y = object.tile_y
      object.xv = 0
      object.yv = 0

      if step >= #object.path then
        object.path = {}
      end
    end
  end
end

movement.can_move = function(object, step)
  return #object.path >= step
end

movement.collision = function(object1, object2, step)
  if movement.can_move(object2, step) then
    return (object1.path[step].x == object2.path[step].x and object1.path[step].y == object2.path[step].y)
  else
    return (object1.path[step].x == object2.tile_x and object1.path[step].y == object2.tile_y)
  end
end

return movement
