sock = require "sock"
network = require "network"
art = require "art"

local menu = require "menu"
local gui = require "gui"
local nui = require "nui"
local game = require "game"
local results = require "results"

state = "network"
reset = false

love.load = function()
  art.load("art")
  gui.load()
  nui.load()

  state = "network"
  network.load()

  love.window.setTitle("Kingsbowl 3")
end

love.update = function(dt)
  gui.update(dt)
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
  love.graphics.print(love.timer.getFPS(), 764, 0)
  if state == "game" then
    game.draw()
  elseif state == "menu" then
    menu.draw()
  elseif state == "network" then
    network.draw()
  elseif state == "results" then
    results.draw()
  end
  gui.draw()
  nui.draw()
end

love.mousepressed = function(x, y, button)
  gui.mousepressed(x, y, button)
  nui.mousepressed(x, y, button)
  if state == "game" then
    game.mousepressed(x, y, button)
  end
end

love.keypressed = function(key)
  gui.keypressed(key)
  nui.keypressed(key)
  if state == "game" then
    game.keypressed(key)
  end
end

love.textinput = function(text)
  gui.textinput(text)
  nui.textinput(text)
end

love.quit = function()
  network.quit()
end
