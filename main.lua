sock = require "sock"
network = require "network"
art = require "art"
local menu = require "menu"
local nui = require "nui"
local game = require "game"
local results = require "results"
local info = require "info"
local window = require "window"
local replays = require "replays"
local settings = require "settings"

state = "network"
reset = false
window_change = false

love.load = function()
  art.load("art")
  nui.load()
  settings.read()
  window.load()

  state = "network"
  network.load()
end

love.update = function(dt)
  nui.update(dt)
  network.update(dt)
  if state == "game" then
    game.update(dt)
  elseif state == "menu" then
    menu.update(dt)
  end
  settings.update(dt)

  if reset then
    state = "network"
    network.load()
    reset = false
  end
  window_change = false
end

love.draw = function()
  love.graphics.setCanvas(window.canvas)
  love.graphics.clear()
  if state == "game" then
    game.draw()
  elseif state == "menu" then
    menu.draw()
  elseif state == "network" then
    network.draw()
  elseif state == "results" then
    results.draw()
  elseif state == "replays" then
    replays.draw()
  end
  nui.draw()
  love.graphics.setCanvas()
  window.draw()
end

love.mousepressed = function(x, y, button)
  local x, y = window.get_mouse()
  if not nui.mousepressed(x, y, button) then
    if state == "game" then
      game.mousepressed(x, y, button)
    end
  end
end

love.wheelmoved = function(x, y)
  nui.wheelmoved(x, y)
end

love.keypressed = function(key)
  nui.keypressed(key)
  if state == "game" then
    game.keypressed(key)
  elseif state == "menu" then
    menu.keypressed(key)
  elseif state == "network" then
    network.keypressed(key)
  elseif state == "replays" then
    replays.keypressed(key)
  end
  info.keypressed(key)
  settings.keypressed(key)
  if key == "`" then
    if not love.filesystem.getInfo("screenshots") then
      love.filesystem.createDirectory("screenshots")
    end
    love.graphics.captureScreenshot("screenshots/"..os.time()..".png")
  end
end

love.textinput = function(text)
  nui.textinput(text)
end

love.quit = function()
  network.quit()
end
