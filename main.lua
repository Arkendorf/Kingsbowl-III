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
  network.keypressed(key)
  if key == "1" and network.get_state() ~= "server"then
    network.set_state("server")
  elseif key == "2" and network.get_state() ~= "client" then
    network.set_state("client")
  end
end
