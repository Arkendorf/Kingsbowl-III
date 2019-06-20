local network = require "network"

love.load = function()
  network.load()
end

love.update = function(dt)
  network.update(dt)
end

love.draw = function()
  network.draw()
end

love.quit = function()
  network.quit()
end

love.keypressed = function(key)
  if key == "1" then
    network.set_state("server")
  elseif key == "2" then
    network.set_state("client")
  end
end
