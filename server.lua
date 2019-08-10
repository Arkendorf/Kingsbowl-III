local nui = require "nui"
local menu = require "menu"

local server_func = {}

server = nil
id = 0
local textboxes = {ip_port = "", desc = "", username = ""}
local default_desc = "Server"
local team_info = {}

server_func.load = function()
  nui.remove.all()
  local w, h = love.graphics.getDimensions()
  nui.add.menu("host", "Host Server", 2, w/2-96, h/2-128, 192, 256, false)
  nui.add.textbox("host", "username", 48, 28, 96, textboxes, "username", "Username")
  nui.add.textbox("host", "desc", 20, 66, 152, textboxes, "desc", "Server Description")
  nui.add.button("host", "show", 48, 110, 96, 16, {content = "Advanced", func = server_func.show_advanced, toggle = true, func2 = server_func.hide_advanced})
  nui.add.button("host", "start", 20, 222, 64, 16, {content = "Start", func = server_func.start_server})
  nui.add.button("host", "leave", 108, 222, 64, 16, {content = "Leave", func = server_func.main_menu})
  server_func.hide_advanced()
end

server_func.update = function(dt)
  if server then
    server:update()
  end
end

server_func.draw = function()
end

server_func.quit = function()
  if server then
    server:sendToAll("kick")
    server:update()
    server:destroy()
    server = nil
  end
end

server_func.main_menu = function()
  nui.remove.all()
  network_state = ""
  network.load()
end

server_func.leave_server = function()
  nui.remove.all()
  server_func.quit()
  server_func.load()
  state = "network"
end

server_func.start_server = function()
  if pcall(function() server_func.create_server(network.decode_ip_port(textboxes.ip_port)) end) then -- attempt to initialize server
    state = "menu"

    -- make sure username and description have a value
    if textboxes.username == "" then
      textboxes.username = default_username
    end
    if textboxes.desc == "" then
      textboxes.desc = default_desc
    end

    -- event calls for server
    server:on("connect", function(data, client)
      if state == "menu" then
        if data == 0 then -- client is checking for an active server
          server:sendToPeer(server:getPeerByIndex(client:getIndex()), "server_info", {textboxes.username, textboxes.desc, #menu.get_client_list()})
        elseif data == 1 then -- client has decided to join server
          local index = client:getIndex()
          local team = menu.choose_team()
          menu.add_client(client.connectId, index, "", team)
          server:sendToAllBut(client, "new_client", {client.connectId, index, "", team})
          local peer = server:getPeerByIndex(index)
          for i, v in ipairs(menu.get_client_list()) do
            local info = menu.get_client_info(v)
            server:sendToPeer(peer, "new_client", {v, info.index, info.username, info.team})
          end
        end
      else
        server:sendToPeer(server:getPeerByIndex(client:getIndex()), "kick")
      end
    end)
    server:on("disconnect", function(data, client)
      if state == "menu" then
        if data == 1 then -- make sure it's a genuine player who left
          menu.remove_client(client.connectId)
          -- inform other clients of departure
          server:sendToAll("client_quit", client.connectId)
        end
      end
    end)
    server:setSchema("client_info", {"username"})
    server:on("client_info", function(data, client)
      if state == "menu" then
        menu.update_client(client.connectId, data.username)
        server:sendToAll("client_info", {client.connectId, data.username})
      end
    end)

    menu.load(server_func.leave_server)
    menu.add_client(0, 0, textboxes.username, 1)
  else -- if attempt produces error
    server = nil
  end
end

server_func.show_advanced = function()
  nui.add.textbox("host", "ip", 20, 154, 152, textboxes, "ip_port", "I.P.")
end

server_func.hide_advanced = function()
  nui.remove.element("host", "ip")
end

server_func.create_server = function(ip, port)
  server = sock.newServer(ip, port)
end

return server_func
