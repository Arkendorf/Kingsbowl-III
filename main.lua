network = require "network"
local game = require "game"

love.load = function()
  network.load()
end

love.update = function(dt)
  network.update(dt)
  if game.started() then
    game.update(dt)
  end
end

love.draw = function()
  network.draw()
  if game.started() then
    game.draw()
  end
end

love.quit = function()
  network.quit()
end

love.keypressed = function(key)
  network.keypressed(key)
  if key == "1" and network.get_state() ~= "server"then
    network.set_state("server")
  elseif key == "2" and network.get_state() ~= "client" then
    network.set_state("client")
  end
end

love.mousepressed = function(x, y, button)
  if game.started() then
    game.mousepressed(x, y, button)
  end
end
