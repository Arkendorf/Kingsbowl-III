sock = require "sock"
network = require "network"

local gui = require "gui"
local game = require "game"

game_start = false

love.load = function()
  gui.load()
  network.load()
  love.window.setTitle("Network Testing")
end

love.update = function(dt)
  network.update(dt)
  gui.update(dt)
  if game_start then
    game.update(dt)
  end
end

love.draw = function()
  love.graphics.print(love.timer.getFPS(), 764, 0)
  if game_start then
    game.draw()
  else
    network.draw()
  end
  gui.draw()
end

love.mousepressed = function(x, y, button)
  gui.mousepressed(x, y, button)
  if game_start then
    game.mousepressed(x, y, button)
  end
end

love.keypressed = function(key)
  gui.keypressed(key)
  if game_start then
    game.keypressed(key)
  end
end

love.textinput = function(text)
  gui.textinput(text)
end

love.quit = function()
  network.quit()
end
