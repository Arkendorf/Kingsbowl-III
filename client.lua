local sock = require "sock"
local game = require "game"

local client_func = {}

local client = nil
local id = nil
local client_list = {0}

local client_hooks = {
  connect = {
    event = function()
      id = client:getConnectId()
    end
  },
  disconnect = {
    event = function()
      client:disconnect()
    end
  },
  quit = {
    event = function()
      client:disconnectNow()
    end
  },
  client_list = {
    schema = {"total", "added", "removed"},
    event = function(data)
      client_list = data.total
      if data.added and game.started() then
        game.add_player(data.added)
      end
    end
  },
  start_game = {
    event = function()
      game.load(id, client_list)
    end
  },

end_turn = {
    event = function()
      game.end_turn()
    end
  },
  timer = {
    event = function(data)
      game.set_timer(data)
    end
  },
}

client_func.load = function()
  client = sock.newClient("localhost", 25565)
  client_func.load_hooks()
  client:connect()
end

client_func.update = function(dt)
  client:update()
end

client_func.draw = function()
  love.graphics.print(client_func.get_status(), 0, 12)
  love.graphics.print(tostring(id), 0, 24)
  love.graphics.print("client list:", 0, 36)
  for i, v in ipairs(client_list) do
    love.graphics.print(v, 0, (i+3)*12)
  end
end

client_func.quit = function()
  if client then
    client:disconnectNow()
    client = nil
  end
end

client_func.load_hooks = function()
  for k, v in pairs(client_hooks) do
    if v.schema then
      client:setSchema(k, v.schema)
    end
    client:on(k, v.event)
  end
end

client_func.get_status = function()
  if client then
    return client:getState()
  else
    return "nonexistant"
  end
end

client_func.send = function(event, data)
  client:send(event, data)
end

return client_func
