local nui = require "nui"
local char = require "char"
local movement = require "movement"
local field = require "field"
local turn = require "turn"
local rules = require "rules"
local abilities = require "abilities"
local football = require "football"
local camera = require "camera"
local window = require "window"

local game = {}

game.load = function(menu_client_list, menu_client_info, menu_team_info, menu_settings)
  state = "game"
  nui.remove.all()
  if network_state == "server" then
    local callback = server:on("connect")
    server:removeCallback(connect)
  end

  rules.load(menu_client_list, menu_client_info, menu_team_info)
  football.load()
  char.load(menu_client_list, menu_client_info, menu_team_info)
  turn.load(menu_settings)
  abilities.load()
  camera.load()
  field.load()

  local w, h = window.get_dimensions()
  nui.add.button("", "move", w/2-52, h-64, 48, 48, {func = char.keypressed, args = "1"})
  nui.add.button("", "ability", w/2+20, h-64, 48, 48, {func = char.keypressed, args = "2"})
end

game.update = function(dt)
  char.update(dt)
  turn.update(dt)
  football.update(dt)
  camera.update(dt)
  char.update_hud(dt)
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
  turn.draw_hud()
end

game.keypressed = function(key)
  char.keypressed(key)
end

game.mousepressed = function(x, y, button)
  char.mousepressed(x, y, button)
end

return game
