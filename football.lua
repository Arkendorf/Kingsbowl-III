local common = require "common"

local football = {}

local ball = {}
local max_dist = 4
local just_thrown = false

football.load = function()
  if state == "server" then
    server:setSchema("throw", {"x", "y"})
    server:on("throw", function(data, client)
      if client.connectId ~= qb or resolve then
        network.server_send_client(client.connectId, "false_throw", qb)
      else
        football.prepare_ball(data.x, data.y)
        network.server_send_team(players[client.connectId].team, "throw", {data.x, data.y})
      end
    end)
  elseif state == "client" then
    client:setSchema("throw", {"x", "y"})
    client:on("throw", function(data)
      football.prepare_ball(data.x, data.y)
    end)
    client:on("false_throw", function(data)
      qb = data
      ball.thrown = false
    end)
    client:on("caught", function()
      ball.caught = true
    end)
  end

  ball = {x = 0, y = 0, tile_x = 0, tile_y = 0, new_x = 0, new_y = 0, thrown = false, caught = false}
end

football.update = function(dt)
  if resolve and ball.thrown and not ball.caught then
    ball.x = ball.x + ball.xv*dt
    ball.y = ball.y + ball.yv*dt
    local tile = math.min(1+math.floor(ball.range*(1-timer/resolve_time)), ball.range)
    ball.tile_x = ball.path[ball.tile+tile].x
    ball.tile_y = ball.path[ball.tile+tile].y
  end
end

football.draw = function()
  if not just_thrown or players[id].team == possesion then -- prevent server from seeing ball and trajectory early
    if ball.thrown then
      love.graphics.circle("fill", (ball.x+.5)*tile_size, (ball.y+.5)*tile_size, tile_size/2, 24)
      love.graphics.circle("fill", (ball.tile_x+.5)*tile_size, (ball.tile_y+.5)*tile_size, tile_size/2-4, 24)
    end
    if ball.path and not ball.caught then
      for i, v in ipairs(ball.path) do
        love.graphics.circle("line", (v.x+.5)*tile_size, (v.y+.5)*tile_size, tile_size/2, 24)
      end
    end
  end
end

football.throw = function(x, y)
  if not ball.thrown then
    local tile_x = math.floor(x/tile_size)
    local tile_y = math.floor(y/tile_size)
    football.prepare_ball(tile_x, tile_y)
    network.server_send_team(players[id].team, "throw", {tile_x, tile_y})
    network.client_send("throw", {tile_x, tile_y})
  end
end

football.prepare_ball = function(x, y)
  ball.tile_x = players[qb].tile_x
  ball.tile_y = players[qb].tile_y
  ball.x = ball.tile_x
  ball.y = ball.tile_y
  ball.new_x = x
  ball.new_y = y
  ball.path = common.get_path(ball.tile_x, ball.tile_y, ball.new_x, ball.new_y)
  ball.range = football.ball_range(ball.tile_x, ball.tile_y, ball.new_x, ball.new_y)
  ball.tile = 1
  ball.thrown = true
  just_thrown = true
end

football.pre_resolve = function()
  if ball.thrown and just_thrown then
    network.server_send("throw", {ball.new_x, ball.new_y})
  end
end

football.move_ball = function()
  if ball.thrown and not ball.caught then
    just_thrown = false
    if ball.tile < #ball.path then
      if ball.tile+ball.range > #ball.path then
        ball.range = #ball.path-ball.tile
      end
      local goal = ball.path[ball.tile+ball.range]
      local dist = common.dist(ball.tile_x, ball.tile_y, goal.x, goal.y)
      ball.xv = (goal.x-ball.tile_x)/resolve_time
      ball.yv = (goal.y-ball.tile_y)/resolve_time
    end
  end
end

football.stop_ball = function()
  if ball.thrown and not ball.caught then
    ball.tile = ball.tile + ball.range
    ball.tile_x = ball.path[ball.tile].x
    ball.tile_y = ball.path[ball.tile].y
    ball.x = ball.tile_x
    ball.y = ball.tile_y
    if ball.tile == #ball.path then
      ball.caught = true
      network.server_send("caught")
    end
  end
end

football.new_qb = function(team)
  local qb = team_info[team].qb
  team_info[team].qb = team_info[team].qb + 1
  if team_info[team].qb > team_info[team].size then
    team_info[team].qb = 1
  end
  local i = 0
  for k, v in pairs(players) do
    if v.team == team then
      i = i + 1
      if i == qb then
        return k
      end
    end
  end
end

football.ball_range = function(x1, y1, x2, y2)
  local x_dif = (x2-x1)
  local y_dif = (y2-y1)
  local dist = common.dist(x1, y1, x2, y2)
  if math.abs(x_dif) >= math.abs(y_dif) then
    return math.floor(max_dist/math.abs(dist/x_dif))
  else
    return math.floor(max_dist/math.abs(dist/y_dif))
  end
end

return football
