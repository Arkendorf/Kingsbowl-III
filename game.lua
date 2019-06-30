local gui = require "gui"
local movement = require "movement"
local football = require "football"

local game = {}

players = {}
tile_size = 32
local turn_time = 3
resolve_time = .5
resolve = false
timer = turn_time
team_info = {}
possesion = 1
qb = 0
local action = "move"

game.load = function(menu_client_list, menu_client_info, menu_team_info)
  movement.load()
  football.load()

  gui.remove_all()
  if state == "server" then
  elseif state == "client" then
    client:on("stop_resolve", function()
      game.stop_resolve()
    end)
    client:on("resolve_moves", function()
      game.resolve_moves()
    end)
  end

  players = {}
  for i, v in ipairs(menu_client_list) do
    players[v] = {x = 0, y = 0, username = menu_client_info[v].username, team = menu_client_info[v].team, tile_x = 0, tile_y = 0, new_x = 0, new_y = 0}
  end

  team_info = menu_team_info
  possesion = 1
  team_info[1].qb = 1
  team_info[2].qb = 1
  qb = football.new_qb(possesion)

  action = "move"

  game_start = true
end

game.update = function(dt)
  movement.update(dt)
  football.update(dt)

  timer = timer - dt
  if state == "server" then
    if timer <= 0 then
      if resolve then
        network.server_send("stop_resolve")
        game.stop_resolve()
      else
        movement.pre_resolve()
        football.pre_resolve()
        network.server_send("resolve_moves")
        game.resolve_moves()
      end
    end
  end
end

game.draw = function()
  movement.draw()
  football.draw()
  love.graphics.print(tostring(qb == id), 100, 0)
end

game.mousepressed = function(x, y, button)
  if action == "move" then
    movement.move(x, y, button)
  elseif action == "throw" then
    football.throw(x, y)
  end
end

game.keypressed = function(key)
  if id == qb then
    if key == "1" then
      action = "move"
    elseif key == "2" then
      action = "throw"
    end
  end
end

game.stop_resolve = function()
  resolve = false
  timer = turn_time
  movement.stop_resolve()
  football.stop_ball()
end

game.resolve_moves = function()
  resolve = true
  timer = resolve_time
  movement.resolve_moves()
  football.move_ball()
end

return game
