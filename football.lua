local movement = require "movement"
local rules = require "rules"

local football = {}

local resolve = false
local move_dist = 4
local ball = {}

football.load = function()
  if network_state == "client" then
    client:setSchema("ball_tile", {"x", "y"})
    client:on("ball_tile", function(data)
      ball.tile_x = data.x
      ball.tile_y = data.y
    end)
  end
  ball = {tile_x = 0, tile_y = 0, x = 0, y = 0, thrown = false, caught = false, full_path = {}, path = {}, range = 0, xv = 0, yv = 0, tile = 0, primed = false, preview = false}
end

football.update = function(dt)
  movement.update_object(ball, dt)
end

football.draw = function()
  if not ball.caught then
    local visible = false
    if ball.thrown then
      art.draw_quad("arrow", art.quad.item[ball.dir], ball.x, ball.y)
      visible = true
    elseif ball.primed and ball.preview then
      art.draw_quad("arrow", art.quad.item[ball.dir], ball.x, ball.y, colors.white[1], colors.white[2], colors.white[3], "outline")
      visible = true
    end
    if visible and not resolve then
      movement.draw_path(ball.tile_x, ball.tile_y, ball.path, colors.white[1], colors.white[2], colors.white[3])
      if ball.tile+ball.range >= #ball.full_path then -- if final tile of full path will be reached this turn, add icon to path
        ball.path[#ball.path].icon = 1
      else -- otherwise, draw the icon seperately
        local tile = ball.full_path[#ball.full_path]
        art.path_icon(1, tile.x, tile.y)
      end
    end
  end
end

football.throw = function(x1, y1, x2, y2)
  ball.full_path = movement.get_path(x1, y1, x2, y2)
  ball.range = football.ball_range(x1, y1, x2, y2)
  if network_state == "server" then
    ball.tile_x = x1
    ball.tile_y = y1
    network.server_send("ball_tile", {x1, y1})
  end
  ball.x = x1
  ball.y = y1
  ball.tile = 0
  ball.dir = art.direction(x1, y1, ball.full_path[1].x, ball.full_path[1].y)
  ball.primed = true
  football.sub_path()
end

football.reset = function()
  if not ball.thrown then
    ball.primed = false
  end
end

football.clear = function()
  ball.thrown = false
  ball.caught = false
  ball.primed = false
  ball.preview = false
  movement.cancel(ball)
end

football.ball_range = function(x1, y1, x2, y2)
  local x_dif = (x2-x1)
  local y_dif = (y2-y1)
  local dist = movement.dist(x1, y1, x2, y2)
  if math.abs(x_dif) >= math.abs(y_dif) then
    return math.floor(move_dist/math.abs(dist/x_dif))
  else
    return math.floor(move_dist/math.abs(dist/y_dif))
  end
end

football.ball_active = function()
  return ball.thrown and not ball.caught
end

football.thrown = function()
  return ball.thrown
end

football.prepare = function(step, step_time)
  if football.ball_active() and movement.can_move(ball, step) then
    movement.prepare(ball, ball.tile_x, ball.tile_y, ball.path[step].x, ball.path[step].y, step_time)
  end
end

football.finish = function(step)
  if football.ball_active() and movement.can_move(ball, step) then
    movement.finish(ball, step)
    network.server_send("ball_tile", {ball.tile_x, ball.tile_y})
    ball.tile = ball.tile+1
  end
end

football.start_resolve = function()
  resolve = true
  if ball.primed and not ball.thrown then
    ball.thrown = true
  end
end

football.sub_path = function()
  ball.path = {}
  for i = ball.tile+1, ball.tile+ball.range do
    if ball.full_path[i] then
      ball.path[#ball.path+1] = ball.full_path[i]
    else
      break
    end
  end
end

football.end_resolve = function()
  resolve = false
  football.sub_path()
end

football.visible = function(team)
  if team == rules.get_offense() then
    ball.preview = true
  end
end

football.step_num = function()
  if ball.primed or football.ball_active() then
    return math.min((#ball.full_path-ball.tile), ball.range)
  else
    return 0
  end
end

football.get_ball = function()
  return ball
end

football.catch = function(id, player)
  if not ball.caught then
    ball.caught = true
    ball.carrier = id
    ball.primed = false
  end
  rules.catch(player)
end

football.path_intersect = function(path)
  if ball.thrown or (ball.primed and ball.preview) and not ball.caught then
    for i, v in ipairs(path) do
      if ball.path[i] then
        if v.x == ball.path[i].x and v.y == ball.path[i].y then
          return i
        end
      end
    end
    if #path < #ball.path then
      if path[#path].x == ball.path[#ball.path].x and path[#path].y == ball.path[#ball.path].y then
        return #path
      end
    end
  end
  return false
end

return football
