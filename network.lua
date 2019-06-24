local server_func = require "server"
local client_func = require "client"
local gui = require "gui"

local network = {}

default_username = "Placeholder"
default_ip_prefix = "192.168.1."
default_port = 25565
state = ""

network.load = function()
  gui.new_button("host", 0, 0, 128, 32, "Host", network.start_server)
  gui.new_button("join", 128, 0, 128, 32, "Join", network.start_client)
end

network.update = function(dt)
  if state == "server" then
    server_func.update(dt)
  elseif state == "client" then
    client_func.update(dt)
  end
end

network.draw = function()
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

network.start_server = function()
  gui.remove_all()
  state = "server"
  server_func.load()
end

network.start_client = function()
  gui.remove_all()
  state = "client"
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

return network
