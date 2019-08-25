local server_func = require "server"
local client_func = require "client"
local nui = require "nui"
local menu = require "menu"
local window = require "window"
local replays = require "replays"
local info = require "info"
local settings = require "settings"

local network = {}

default_username = "Placeholder"
default_ip_prefix = "192.168.1."
default_port = 25565
network_state = ""

network.load = function()
  nui.remove.all()
  network.set_gui()
end

network.set_gui = function()
  local w, h = window.get_dimensions()
  local button_h = math.floor((h+art.img.splash:getHeight())/2)+14
  nui.add.button("", "host", w/2-94, button_h, 84, 32, {content = "Host", func = network.start_server})
  nui.add.button("", "join", w/2+10, button_h, 84, 32, {content = "Join", func = network.start_client})
  nui.add.button("", "replay", w/2-126, button_h+52, 48, 32, {content = "Replays", func = network.start_replays})
  nui.add.button("", "info", w/2-58, button_h+52, 48, 32, {content = "How to Play", func = info.load})
  nui.add.button("", "settings", w/2+10, button_h+52, 48, 32, {content = "Options", func = settings.load})
  nui.add.button("", "quit", w/2+78, button_h+52, 48, 32, {content = "Quit", func = love.event.quit, color = 1})
end

network.update = function(dt)
  if network_state == "server" then
    server_func.update(dt)
  elseif network_state == "client" then
    client_func.update(dt)
  end
  if window_change then
    network.set_gui()
  end
end

network.draw = function()
  if network_state == "server" then
    server_func.draw()
  elseif network_state == "client" then
    client_func.draw()
  end
  local w, h = window.get_dimensions()
  local splash_h = math.floor((h-art.img.splash:getHeight())/2)
  love.graphics.draw(art.img.splash, math.floor((w-art.img.splash:getWidth())/2), splash_h)
  love.graphics.draw(art.img.logo, math.floor((w-art.img.logo:getWidth())/2), splash_h-art.img.logo:getHeight()-4)
end

network.keypressed = function(key)
  if network_state == "server" then
    server_func.keypressed(key)
  elseif network_state == "client" then
    client_func.keypressed(key)
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
  nui.remove.all()
  network_state = "server"
  server_func.load()
end

network.start_client = function()
  nui.remove.all()
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

network.start_replays = function()
  state = "replays"
  replays.load()
end

network.server_callback = function(name, func, schema)
  if server then
    if schema then
      server:setSchema(name, schema)
    end
    server:on(name, func)
  end
end

network.client_callback = function(name, func, schema)
  if client then
    if schema then
      client:setSchema(name, schema)
    end
    client:on(name, func)
  end
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
