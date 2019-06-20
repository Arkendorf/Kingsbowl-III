local sock = require "sock"

local server_func = {}

local server = nil
local client_data = {}
local client_list = {}

local server_hooks = {
  connect = {
    event = function(data, client)
      server_func.update_client_list()
      client_data[client.connectId] = {index = client:getIndex()}
      server:sendToAll("client_list", client_list)
    end
  },
  disconnect = {
    event = function(data, client)
      server_func.update_client_list()
      client_data[client.connectId] = nil
      server:sendToAll("client_list", client_list)
    end
  }
}

server_func.load = function()
  server = sock.newServer("localhost", 25565)
  server_func.load_hooks()
end

server_func.update = function(dt)
  server:update()
end

server_func.draw = function()
  love.graphics.print("connected clients:", 0, 12)
  for i, v in ipairs(client_list) do
    love.graphics.print(v, 0, (i+1)*12)
  end
end



server_func.quit = function()
  if server then
    server:sendToAll("quit", {})
    server:update()
    server:destroy()
    server = nil
  end
end

server_func.load_hooks = function()
  for k, v in pairs(server_hooks) do
    if v.schema then
      server:setSchema(k, v.schema)
    end
    server:on(k, v.event)
  end
end

server_func.update_client_list = function()
  client_list = {}
  for i, v in ipairs(server:getClients()) do
    client_list[#client_list+1] = v.connectId
  end
end

return server_func
