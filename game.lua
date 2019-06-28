local gui = require "gui"
local movement = require "movement"

local game = {}

players = {}
tile_size = 32
local turn_time = 3
resolve_time = 1
resolve = false
timer = turn_time
team_info = {}

game.load = function(menu_client_list, menu_client_info, menu_team_info)
  movement.load()

  gui.remove_all()
  if state == "server" then
  elseif state == "client" then
    client:on("start_moves", function()
      game.start_moves()
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

  game_start = true
end

game.update = function(dt)
  movement.update(dt)

  timer = timer - dt
  if state == "server" then
    if timer <= 0 then
      if resolve then
        network.server_send("start_moves")
        game.start_moves()
      else
        for k, v in pairs(players) do
          network.server_send("new_pos", {k, v.new_x, v.new_y})
        end
        network.server_send("resolve_moves")
        game.resolve_moves()
      end
    end
  end
end

game.start_moves = function()
  resolve = false
  timer = turn_time
  movement.start_moves()
end

game.resolve_moves = function()
  resolve = true
  timer = resolve_time
  movement.resolve_moves()
end

game.draw = function()
  movement.draw()
end

game.mousepressed = function(x, y, button)
  movement.mousepressed(x, y, button)
end

return game
