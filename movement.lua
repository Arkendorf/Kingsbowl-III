local field = require "field"

local movement = {}

movement.update_object = function(object, dt)
  object.x = object.x + object.xv * dt
  object.y = object.y + object.yv * dt
  if object.xa and object.ya then
    object.xv = object.xv + object.xa * dt
    object.yv = object.yv + object.ya * dt
  end
  if object.limit_x and object.limit_y then -- limits have been established
    if object.x > math.max(object.goal_x, object.limit_x) or object.x < math.min(object.goal_x, object.limit_x) or object.y > math.max(object.goal_y, object.limit_y) or object.y < math.min(object.goal_y, object.limit_y) then
      object.x = object.goal_x
      object.y = object.goal_y
      movement.stop(object)
      return true
    end
  end
  return false
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
  object.x = object.tile_x
  object.y = object.tile_y
end

movement.stop = function(object)
  object.limit_x = nil
  object.limit_y = nil
  object.xv = 0
  object.yv = 0
  object.xa = 0
  object.ya = 0
end

movement.valid = function(x1, y1, x2, y2, max_dist)
  return (movement.dist(x1, y1, x2, y2) <= max_dist and field.in_bounds(x2, y2)) and (x1 ~= x2 or y1 ~= y2)
end

movement.bounce = function(object, x1, y1, x2, y2, step_time, h)
  object.goal_x = x1
  object.goal_y = y1
  object.limit_x = x2
  object.limit_y = y2
  local x_dist = x2 - x1
  local y_dist = y2 - y1
  object.xv = x_dist * 4 * h / step_time
  object.yv = y_dist * 4 * h / step_time
  object.xa = x_dist * -8 * h / (step_time * step_time)
  object.ya = y_dist * -8 * h / (step_time * step_time)
end

movement.lerp = function(object, x1, y1, x2, y2, step_time)
  object.goal_x = x2
  object.goal_y = y2
  object.limit_x = x1
  object.limit_y = y1
  local x_dist = x2 - x1
  local y_dist = y2 - y1
  object.xv = x_dist * 2 / step_time
  object.yv = y_dist * 2 / step_time
  object.xa = x_dist * -2 / (step_time * step_time)
  object.ya = y_dist * -2 / (step_time * step_time)
end

movement.prepare = function(object, x1, y1, x2, y2, step_time)
  object.goal_x = x2
  object.goal_y = y2
  object.limit_x = x1
  object.limit_y = y1
  local x_dist = x2 - x1
  local y_dist = y2 - y1
  object.xv = x_dist / step_time
  object.yv = y_dist / step_time
  object.xa = 0
  object.ya = 0
end

movement.finish = function(object, step)
  if movement.can_move(object, step) then
    local tile_x = object.path[step].x
    local tile_y = object.path[step].y
    if network_state == "server" then
      object.tile_x = tile_x
      object.tile_y = tile_y
    end
    object.x = tile_x
    object.y = tile_y

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
  local x1, y1 = movement.get_pos(object1, step)
  local x2, y2 = movement.get_pos(object2, step)
  return (x1 == x2 and y1 == y2)
end

movement.get_pos = function(object, step)
  if movement.can_move(object, step) then
    return object.path[step].x, object.path[step].y
  else
    return object.tile_x, object.tile_y
  end
end

movement.draw_path = function(x, y, path, r, g, b)
  if #path > 0 then
    local x_dif = path[1].x - x
    local y_dif = path[1].y - y
    if path[1].icon or #path == 1 then
      art.line(x+.5+x_dif*.5, y+.5+y_dif*.5, path[1].x+.5-x_dif*.3, path[1].y+.5-y_dif*.3, r, g, b)
    else
      art.line(x+.5+x_dif*.5, y+.5+y_dif*.5, path[1].x+.5, path[1].y+.5, r, g, b)
    end
    for i, v in ipairs(path) do
      if i < #path then
        local x1 = v.x+.5
        local y1 = v.y+.5
        local x2 = path[i+1].x+.5
        local y2 = path[i+1].y+.5
        local x_dif = x2 - x1
        local y_dif = y2 - y1
        if v.icon then
          x1 = x1 + x_dif*.3
          y1 = y1 + y_dif*.3
          art.path_icon(v.icon, v.x, v.y, r, g, b)
        else
          art.draw_img("path_node", v.x, v.y, r, g, b)
        end
        if path[i+1].icon or i+1 >= #path then
          x2 = x2 - x_dif*.3
          y2 = y2 - y_dif*.3
        end
        art.line(x1, y1, x2, y2, r, g, b)
      elseif v.icon then
        art.path_icon(v.icon, v.x, v.y, r, g, b)
      else
        art.path_icon(5, v.x, v.y, r, g, b)
      end
    end
  end
end

return movement
