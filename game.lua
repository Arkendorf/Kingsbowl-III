local gui = require "gui"
local char = require "char"
local movement = require "movement"
local field = require "field"
local turn = require "turn"
local rules = require "rules"
local abilities = require "abilities"
local football = require "football"
local cam = require "cam"

local game = {}

tile_size = 32

game.load = function(menu_client_list, menu_client_info, menu_team_info)
  state = "game"
  gui.remove_all()
  if network_state == "server" then
    local callback = server:on("connect")
    server:removeCallback(connect)
  end

  rules.load(menu_client_list, menu_client_info, menu_team_info)
  char.load(menu_client_list, menu_client_info, menu_team_info)
  turn.load()
  abilities.load()
  football.load()
  cam.load()
  field.load()
end

game.update = function(dt)
  char.update(dt)
  turn.update(dt)
  football.update(dt)
  cam.update(dt)
end

game.draw = function()
  love.graphics.push()
  love.graphics.translate(game.get_offset())
  field.draw()
  char.draw()
  football.draw()
  rules.draw()
  love.graphics.pop()

  turn.draw()

end

game.keypressed = function(key)
  char.keypressed(key)
end

game.mousepressed = function(x, y, button)
  local offset_x, offset_y = game.get_offset()
  char.mousepressed(x-offset_x, y-offset_y, button)
end

game.quit = function()
end

game.get_offset = function()
  local w, h = love.graphics.getDimensions()
  local camera = cam.get()
  return -camera.x+w/2, -camera.y+h/2
end


return game
