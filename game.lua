local gui = require "gui"
local char = require "char"
local movement = require "movement"
local field = require "field"

local game = {}

tile_size = 32

game.load = function(menu_client_list, menu_client_info, menu_team_info)
  gui.remove_all()
  if state == "server" then
  elseif state == "client" then
  end
  game_start = true

  char.load(menu_client_list, menu_client_info, menu_team_info)
  movement.load()
end

game.update = function(dt)
  char.update(dt)
end

game.draw = function()
  char.draw()
  field.draw()
end

game.keypressed = function(key)
end

game.mousepressed = function(x, y, button)
  char.mousepressed(x, y, button)
end

game.quit = function()
end


return game
