local sock = require "sock"
local game = require "game"

local server_func = {}

local server = nil
local id = 0
local client_data = {}
local client_list = {0}

local server_hooks = {
  connect = {
    event = function(data, client)
      server_func.update_client_list()
      client_data[client.connectId] = {index = client:getIndex()}
      server:sendToAll("client_list", {client_list, client.connectId, nil})

      if game.started() then
        game.add_player(client.connectId)
        server:sendToPeer(server:getPeerByIndex(client_data[client.connectId].index), "start_game")
      end
    end
  },
  disconnect = {
    event = function(data, client)
      server_func.update_client_list()
      client_data[client.connectId] = nil
      server:sendToAll("client_list", {client_list, nil, client.connectId})
    end
  },

  start_turn = {
    event = function(data, client)
      server:sendToPeer(server:getPeerByIndex(client_data[client.connectId].index), "timer", timer)
    end
  },
  end_turn = {
    event = function(data, client)
      server:sendToPeer(server:getPeerByIndex(client_data[client.connectId].index), "timer", timer)
    end
  },
  new_move = {
    schema = {"player", "x", "y"},
    event = function(data, client)
      server:sendToAll("new_move", {data.player, data.x, data.y})
      players[data.player].x_move = data.x
      players[data.player].y_move = data.y
    end
  },
}

server_func.load = function()
  if pcall(server_func.create_server) then
    server_func.load_hooks()
  else
    network.set_state("server error")
  end
end

server_func.create_server = function()
  server = sock.newServer("localhost", 25565)
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

server_func.keypressed = function(key)
  if key == "space" then
    server_func.start_game()
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
  client_list = {0}
  for i, v in ipairs(server:getClients()) do
    client_list[#client_list+1] = v.connectId
  end
end

server_func.start_game = function()
  server:sendToAll("start_game")
  game.load(id, client_list)
end

server_func.send = function(event, data)
  server:sendToAll(event, data)
end

return server_func
