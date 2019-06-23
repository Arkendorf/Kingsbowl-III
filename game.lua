local movement = require "movement"

local game = {}

local started = false

players = {}
id = nil

tile_size = 32
turn_time = 3
timer = turn_time
states = {"defense", "offense", "qb", "baller"}
resolve = true

game.load = function(client, client_list)
  id = client
  for i, v in ipairs(client_list) do
    game.add_player(v)
  end
  started = true
end

game.update = function(dt)
  movement.update(dt)
  for k, v in pairs(players) do

  end
  timer = timer - dt
  if timer <= 0 then
    if resolve then
      network.send("start_turn", 0)
    else
      network.send("end_turn", 0)
    end
  end
end

game.draw = function()
  for k, v in pairs(players) do
    love.graphics.rectangle("line", v.grid_x*tile_size, v.grid_y*tile_size, tile_size, tile_size)
    love.graphics.rectangle("line", (v.grid_x+v.x_move)*tile_size, (v.grid_y+v.y_move)*tile_size, tile_size, tile_size)
    love.graphics.rectangle("fill", v.x*tile_size, v.y*tile_size, tile_size, tile_size)
  end
  love.graphics.print(timer, 100, 0)
  love.graphics.print(players[id].state, 100, 12)
end

game.mousepressed = function(x, y, button)
  if not resolve then
    movement.mousepressed(x, y, button)
  end
end

game.add_player = function(id, pos)
  players[id] = {state = states[math.random(1, 4)], grid_x = 16, grid_y = 16, x_move = 0, y_move = 0, x = 16, y = 16, old_x_move = 0, old_y_move = 0, resolved = false}
end

game.started = function()
  return started
end

game.network_func = {}

game.network_func.start_turn = function()
  resolve = false
  timer = turn_time
end

game.network_func.end_turn = function()
  movement.end_turn()
  resolve = true
end

return game
