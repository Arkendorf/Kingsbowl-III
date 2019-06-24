sock = require "sock"
network = require "network"

local gui = require "gui"

love.load = function()
  gui.load()
  network.load()
  love.window.setTitle("Network Testing")
end

love.update = function(dt)
  network.update(dt)
  gui.update(dt)
end

love.draw = function()
  love.graphics.print(love.timer.getFPS(), 764, 0)
  network.draw()
  gui.draw()
end

love.mousepressed = function(x, y, button)
  gui.mousepressed(x, y, button)
end

love.keypressed = function(key)
  gui.keypressed(key)
end

love.textinput = function(text)
  gui.textinput(text)
end

love.quit = function()
  network.quit()
end
