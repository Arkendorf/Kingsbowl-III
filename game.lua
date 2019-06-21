local game = {}

local players = {}
local started = false
local id = nil

local tile_size = 32
local turn_time = 4
local timer = turn_time
local turn_delay = {
  ball = 0,
  qb = .4, -- qb's state should only be qb as long as they have ball
  offense = .4,
  defense = .8,
  baller = .12
}
local move_speed = 3
local move_percent = .75

game.load = function(client, client_list)
  id = client
  for i, v in ipairs(client_list) do
    game.add_player(v)
  end
  started = true
end

game.update = function(dt)
  for k, v in pairs(players) do
    if not v.moved then
      if turn_time-timer >= turn_delay[v.state] then
        if v.state == "defense" then -- check for collisions
          local l, w = game.collision(k, v)
          if l then -- colliding
            if w.state == "qb" or w.state == "baller" then -- player tackles collider
            elseif w.state == "offense" then -- collider blocks player
              v.x_move = 0
              v.y_move = 0
            end
          end
        end
        v.x_move = 0
        v.y_move = 0
        v.grid_x = v.grid_x + v.x_move
        v.grid_y = v.grid_y + v.y_move
        v.old_x_move = v.x_move
        v.old_y_move = v.y_move
        v.x_move = 0
        v.y_move = 0
        v.moved = true
        v.speed = false
      else
        --insignificant, atmospheric motion (to make things feel fast-paced)
        if v.speed then
          v.x = v.x + v.x_move*v.speed*dt
          v.y = v.y + v.y_move*v.speed*dt
        end
      end
    else
      -- full motion up until almost the end, insignificant motion until end of turn (chars are constantly moving)
      if math.abs(v.grid_x-v.x) > 1-move_percent or math.abs(v.grid_y-v.y) > 1-move_percent then
        v.x = v.x + v.old_x_move*move_speed*dt
        v.y = v.y + v.old_y_move*move_speed*dt
      else
        if not v.speed then
          v.speed = (1-move_percent)/(turn_time-turn_delay[v.state]-(move_percent/move_speed))
        end
        v.x = v.x + v.old_x_move*v.speed*dt
        v.y = v.y + v.old_y_move*v.speed*dt
      end
    end
  end
  for k, v in pairs(players) do

  end
  timer = timer - dt
  if timer <= 0 then
    network.send("end_turn")
  end
end

game.draw = function()
  for k, v in pairs(players) do
    love.graphics.rectangle("line", v.grid_x*tile_size, v.grid_y*tile_size, tile_size, tile_size)
    love.graphics.rectangle("line", (v.grid_x+v.x_move)*tile_size, (v.grid_y+v.y_move)*tile_size, tile_size, tile_size)
    love.graphics.rectangle("fill", v.x*tile_size, v.y*tile_size, tile_size, tile_size)
  end
  love.graphics.print(timer, 100, 0)
end

game.mousepressed = function(x, y, button)
  if players[id].moved then
    local grid_x = math.floor(x/tile_size)
    local grid_y = math.floor(y/tile_size)
    if math.abs(grid_x-players[id].grid_x) <= 1 and math.abs(grid_y-players[id].grid_y) <= 1 then
      players[id].x_move = grid_x - players[id].grid_x
      players[id].y_move = grid_y - players[id].grid_y
    end
  end
end

game.add_player = function(id, pos)
  players[id] = {state = "defense", grid_x = 0, grid_y = 0, x_move = 0, y_move = 0, x = 0, y = 0, old_x_move = 0, old_y_move = 0, moved = false}
end

game.started = function()
  return started
end

game.get_timer = function()
  return timer
end

game.set_timer = function(num)
  timer = num
end

game.end_turn = function()
  for k, v in pairs(players) do
    v.x = v.grid_x
    v.y = v.grid_y
    v.moved = false
  end
  game.set_timer(turn_time)
end

game.collision = function(k, v)
  for l, w in pairs(players) do
    if l ~= k then
      if w.grid_x == v.grid_x+v.x_move and w.grid_y == v.grid_y+v.y_move then
        return k, v
      end
    end
  end
  return false
end

return game
