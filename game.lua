local gui = require "gui"
local char = require "char"
local movement = require "movement"
local field = require "field"
local turn = require "turn"
local rules = require "rules"
local abilities = require "abilities"
local football = require "football"

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
  turn.load()
  rules.load(menu_client_list, menu_client_info, menu_team_info)
  abilities.load()
  football.load()
end

game.update = function(dt)
  char.update(dt)
  turn.update(dt)
  football.update(dt)
end

game.draw = function()
  char.draw()
  field.draw()
  turn.draw()
  football.draw()
  rules.draw()
end

game.keypressed = function(key)
  char.keypressed(key)
end

game.mousepressed = function(x, y, button)
  char.mousepressed(x, y, button)
end

game.quit = function()
end


return game
