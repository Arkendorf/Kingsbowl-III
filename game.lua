local gui = require "gui"
local char = require "char"
local movement = require "movement"
local field = require "field"
local turn = require "turn"
local rules = require "rules"
local abilities = require "abilities"
local football = require "football"
local camera = require "camera"

local game = {}

game.load = function(menu_client_list, menu_client_info, menu_team_info)
  state = "game"
  gui.remove_all()
  if network_state == "server" then
    local callback = server:on("connect")
    server:removeCallback(connect)
  end

  rules.load(menu_client_list, menu_client_info, menu_team_info)
  football.load()
  char.load(menu_client_list, menu_client_info, menu_team_info)
  turn.load()
  abilities.load()
  camera.load()
  field.load()
end

game.update = function(dt)
  char.update(dt)
  turn.update(dt)
  football.update(dt)
  camera.update(dt)
end

game.draw = function()
  love.graphics.push()
  love.graphics.translate(camera.get_offset())
  field.draw()
  rules.draw()
  char.draw()
  football.draw()
  char.draw_paths()
  love.graphics.pop()

  local w = love.graphics.getWidth()
  turn.draw_hud(w/2, 2)

end

game.keypressed = function(key)
  char.keypressed(key)
end

game.mousepressed = function(x, y, button)
  local offset_x, offset_y = camera.get_offset()
  char.mousepressed(x-offset_x, y-offset_y, button)
end

return game
