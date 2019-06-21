local sock = require "sock"
local server_func = require "server"
local client_func = require "client"
local game = require "game"

local network = {}

local state = "press 1 for server or 2 for client"

network.load = function()
end

network.update = function(dt)
  if state == "server" then
    server_func.update(dt)
  elseif state == "client" then
    client_func.update(dt)
  end
end

network.draw = function()
  love.graphics.print(state)

  if state == "server" then
    server_func.draw()
  elseif state == "client" then
    client_func.draw()
  end
end

network.quit = function()
  if state == "server" then
    server_func.quit()
  elseif state == "client" then
    client_func.quit()
  end
end

network.keypressed = function(key)
  if state == "server" then
    server_func.keypressed(key)
  end
end

network.set_state = function(str)
  state = str
  if state == "server" then
    server_func.load()
    client_func.quit()
  elseif state == "client" then
    client_func.load()
    server_func.quit()
  end
end

network.get_state = function()
  return state
end

network.send = function(event, data)
  if state == "server" then
    server_func.send(event, data)
    game[event](data)
  elseif state == "client" then
    client_func.send(event, data)
  end
end

return network
