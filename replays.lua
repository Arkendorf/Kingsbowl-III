local nui = require "nui"
local window = require "window"
local bitser = require 'bitser'
local game = require "game"

local replays = {}

-- replays are saved in results.lua (to prevent loops)

replays.load = function()
  state = "replays"
  nui.remove.all()
  local w, h = window.get_dimensions()
  nui.add.menu("list", "Replay List", 2, w/2-96, h/2-128, 192, 256, true)
  nui.add.button("", "leave", w/2-32, h/2+148, 64, 16, {content = "Leave", func = replays.leave})

  replays.file_buttons()
end

replays.draw = function()
  local w, h = window.get_dimensions()
  local splash_h = math.floor((h-art.img.splash:getHeight())/2)
  love.graphics.draw(art.img.splash, math.floor((w-art.img.splash:getWidth())/2), splash_h)
  love.graphics.draw(art.img.logo, math.floor((w-art.img.logo:getWidth())/2), splash_h-art.img.logo:getHeight()-4)
end

replays.keypressed = function(key)
  if key == "escape" then
    replays.leave()
  end
end

replays.file_buttons = function()
  nui.remove.menu_elements("list")
  local files = love.filesystem.getDirectoryItems("replays")
  for i, v in ipairs(files) do
    local name = string.sub(v, 1, -5)
    nui.add.button("list", "play"..tostring(i), 20, 22+(i-1)*56, 120, 32, {content = name, func = replays.play, args = v})
    nui.add.button("list", "delete"..tostring(i), 156, 30+(i-1)*56, 16, 16, {content = art.img.replay_button, func = replays.delete, args = v})
  end
end

replays.leave = function()
  reset = true
end

replays.play = function(file_name)
  local file = love.filesystem.read("replays/"..file_name)
  local replay = bitser.loads(file)
  network_state = "server"
  game.load(replay.client_list, replay.client_info, replay.team_info, replay.settings, replay.turns)
end

replays.delete = function(file_name)
  love.filesystem.remove("replays/"..file_name)
  replays.file_buttons()
end

return replays
