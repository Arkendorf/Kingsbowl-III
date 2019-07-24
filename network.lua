local server_func = require "server"
local client_func = require "client"
local gui = require "gui"
local menu = require "menu"

local network = {}

default_username = "Placeholder"
default_ip_prefix = "192.168.1."
default_port = 25565
network_state = ""

network.load = function()
  gui.remove_all()
  gui.new_button("host", 0, 0, 128, 32, "Host", network.start_server)
  gui.new_button("join", 128, 0, 128, 32, "Join", network.start_client)
end

network.update = function(dt)
  if network_state == "server" then
    server_func.update(dt)
  elseif network_state == "client" then
    client_func.update(dt)
  end
end

network.draw = function()
  if network_state == "server" then
    server_func.draw()
  elseif network_state == "client" then
    client_func.draw()
  end
end

network.quit = function()
  if network_state == "server" then
    server_func.quit()
  elseif network_state == "client" then
    client_func.quit()
  end
end

network.start_server = function()
  gui.remove_all()
  network_state = "server"
  server_func.load()
end

network.start_client = function()
  gui.remove_all()
  network_state = "client"
  client_func.load()
end

network.decode_ip_port = function(ip_port, default_ip)
  local ip = "*"
  if default_ip then
    ip = default_ip
  end
  local new_ip = ip_port
  local port = default_port
  local port_pos = string.find(ip_port, ":") -- search for a given port
  if port_pos then
    new_ip = string.sub(ip_port, 1, port_pos-1)
    local new_port = tonumber(string.sub(ip_port, port_pos+1, -1))
    if new_port then
      port = new_port
    end
  end
  if new_ip ~= "" then
    ip = new_ip
  end
  return ip, port
end

network.server_send = function(event, data)
  if network_state == "server" and server then
    server:sendToAll(event, data)
  end
end

network.client_send = function(event, data)
  if network_state == "client" and client then
    client:send(event, data)
  end
end

network.server_send_client = function(id, event, data)
  if network_state == "server" and server then
    server:sendToPeer(server:getPeerByIndex(menu.get_client_info(id).index), event, data)
  end
end

network.server_send_except = function(id, event, data)
  if network_state == "server" and server then
    server:sendToAllBut(server:getClientByConnectId(id), event, data)
  end
end

network.server_send_team = function(team, event, data)
  if network_state == "server" and server then
    for i, v in ipairs(menu.get_client_list()) do
      if v ~= 0 then
        if menu.get_client_info(v).team == team then
          network.server_send_client(v, event, data)
        end
      end
    end
  end
end

return network
