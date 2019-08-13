sock = require "sock"
network = require "network"
art = require "art"
local menu = require "menu"
local nui = require "nui"
local game = require "game"
local results = require "results"
local window = require "window"

state = "network"
reset = false

love.load = function()
  art.load("art")
  nui.load()
  window.load()

  state = "network"
  network.load()

  love.window.setTitle("Kingsbowl 3")
end

love.update = function(dt)
  nui.update(dt)
  network.update(dt)
  if state == "game" then
    game.update(dt)
  elseif state == "menu" then
    menu.update(dt)
  end

  if reset then
    state = "network"
    network.load()
    reset = false
  end
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
  end
  nui.draw()
  love.graphics.setCanvas()
  window.draw()
  love.graphics.print(love.timer.getFPS(), 8, 0)
end

love.mousepressed = function(x, y, button)
  local x, y = window.get_mouse()
  if not nui.mousepressed(x, y, button) then
    if state == "game" then
      game.mousepressed(x, y, button)
    end
  end
end

love.keypressed = function(key)
  nui.keypressed(key)
  if state == "game" then
    game.keypressed(key)
  end
  if key == "escape" then
    love.event.quit()
  end
end

love.textinput = function(text)
  nui.textinput(text)
end

love.quit = function()
  network.quit()
end
