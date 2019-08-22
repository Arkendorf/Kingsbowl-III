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
local broadcast = require "broadcast"
local particle = require "particle"
local preview = require "preview"

local game = {}

local replay_active = false
local replay_info = false

local quit_t = 0
local stop = false

game.load = function(menu_client_list, menu_client_info, menu_team_info, menu_settings, menu_replay_turns)
  state = "game"
  stop = false
  nui.remove.all()

  replay_info = {client_list = menu_client_list, client_info = menu_client_info, team_info = menu_team_info, settings = menu_settings, turns = {}}
  if menu_replay_turns then
    id = 0
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
  broadcast.load()
  particle.load()
  preview.load()

  -- hud
  local w, h = window.get_dimensions()
  if not replay_active then
    nui.add.button("", "move", w/2-60, h-64, 48, 48, {func = char.keypressed, args = "1"})
    nui.add.button("", "ability", w/2+12, h-64, 48, 48, {func = char.keypressed, args = "2"})
    nui.add.button("", "cycle_left", w/2-112, h-56, 32, 32, {func = char.cycle_knight, args = -1, content = {img = art.img.cycle_icons, quad = art.quad.cycle_icon[1]}})
    nui.add.button("", "cycle_right", w/2+80, h-56, 32, 32, {func = char.cycle_knight, args = -1, content = {img = art.img.cycle_icons, quad = art.quad.cycle_icon[2]}})
  end
  nui.add.button("", "camera", w-112, h-56, 32, 32, {func = char.center_camera, content = {img = art.img.game_icons, quad = art.quad.game_icon[1]}})
  nui.add.button("", "username", w-56, h-56, 32, 32, {toggle = true, func = char.toggle_info, func2 = char.toggle_info, content = {img = art.img.game_icons, quad = art.quad.game_icon[2]}})
  nui.active("", "username", true)
end

game.update = function(dt)
  char.update(dt)
  rules.update(dt)
  turn.update(dt)
  football.update(dt)
  camera.update(dt)
  broadcast.update(dt)
  particle.update(dt)

  if love.keyboard.isDown("escape") then
    quit_t = quit_t + dt
    if quit_t > 1 then
      love.event.quit()
    end
  else
    quit_t = 0
  end
  if stop then
    turn.start_results()
  end
end

game.draw = function()
  love.graphics.push()
  love.graphics.translate(camera.get_offset())
  field.draw()
  preview.draw_bottom()
  particle.draw_bottom()
  rules.draw()
  char.draw()
  football.draw()
  preview.draw_top()
  particle.draw_top()
  love.graphics.pop()
  char.draw_hud()
  turn.draw_hud()
  broadcast.draw()
end

game.keypressed = function(key)
  char.keypressed(key)
  if network_state == "server" and key == "backspace" then
    stop = true
  end
end

game.mousepressed = function(x, y, button)
  if not replay_active then
    char.mousepressed(x, y, button)
  end
end

game.remove_client = function(id)
  if char.remove_player(id) then -- returns true of client's team has no other players
    stop = true
  end
end

return game
