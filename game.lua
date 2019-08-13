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

local replay_active = false
local replay_info = false

game.load = function(menu_client_list, menu_client_info, menu_team_info, menu_settings, menu_replay_turns)
  state = "game"
  nui.remove.all()

  replay_info = {client_list = menu_client_list, client_info = menu_client_info, team_info = menu_team_info, settings = menu_settings, turns = {}}
  if menu_replay_turns then
    replay_info.turns = menu_replay_turns
    replay_active = true
  else
    replay_active = false
  end

  rules.load(menu_client_list, menu_client_info, menu_team_info, menu_settings, replay_active)
  football.load(replay_active)
  char.load(menu_client_list, menu_client_info, menu_team_info, menu_settings, replay_active)
  turn.load(menu_settings, replay_active, replay_info)
  abilities.load()
  camera.load()
  field.load()

  local w, h = window.get_dimensions()
  nui.add.button("", "move", w/2-52, h-64, 48, 48, {func = char.keypressed, args = "1"})
  nui.add.button("", "ability", w/2+20, h-64, 48, 48, {func = char.keypressed, args = "2"})

  nui.add.button("", "cycle_left", w/2-104, h-56, 32, 32, {func = char.cycle_knight, args = -1, content = {img = art.img.cycle_icons, quad = art.quad.cycle_icon[1]}})
  nui.add.button("", "cycle_right", w/2+88, h-56, 32, 32, {func = char.cycle_knight, args = -1, content = {img = art.img.cycle_icons, quad = art.quad.cycle_icon[2]}})
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
  love.graphics.pop()
  turn.draw_hud()
end

game.keypressed = function(key)
  if not replay_active then
    char.keypressed(key)
  end
end

game.mousepressed = function(x, y, button)
  if not replay_active then
    char.mousepressed(x, y, button)
  end
end

return game
