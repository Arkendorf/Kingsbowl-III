local gui = require "gui"
local menu = require "menu"

local server_func = {}

server = nil
id = 0
local textboxes = {ip_port = "", desc = "", username = ""}
local default_desc = "Server"
local team_info = {}

server_func.load = function()
  ip_port = ""
  gui.remove_all()
  gui.new_textbox("username", 0, 0, 192, 16, "Username", textboxes, "username")
  gui.new_button("host", 192, 0, 64, 16, "Host", server_func.start_server)
  gui.new_textbox("desc", 0, 16, 256, 16, "Server Description", textboxes, "desc")
  server_func.hide_advanced()
  gui.new_button("main_menu", 64, 48, 128, 16, "Main Menu", server_func.main_menu)
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
  gui.remove_all()
  network_state = ""
  network.load()
end

server_func.leave_server = function()
  gui.remove_all()
  server_func.quit()
  server_func.load()
  state = "network"
end

server_func.start_server = function()
  if pcall(function() server_func.create_server(network.decode_ip_port(textboxes.ip_port)) end) then -- attempt to initialize server
    state = "menu"

    gui.remove_all()
    gui.new_button("leave", 0, 0, 128, 32, "Leave", server_func.leave_server)

    -- make sure username and description have a value
    if textboxes.username == "" then
      textboxes.username = default_username
    end
    if textboxes.desc == "" then
      textboxes.desc = default_desc
    end

    -- set up client for server
    menu.reset_info()
    menu.add_client(0, 0, textboxes.username, 1)

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

    menu.load()
  else -- if attempt produces error
    server = nil
  end
end

server_func.show_advanced = function()
  gui.remove_button("advanced")
  gui.new_textbox("ip_port", 0, 32, 192, 16, "I.P.", textboxes, "ip_port")
  gui.new_button("hide", 192, 32, 64, 16, "Hide", server_func.hide_advanced)
end

server_func.hide_advanced = function()
  gui.remove_textbox("ip_port")
  gui.remove_button("hide")
  gui.new_button("advanced", 0, 32, 256, 16, "Advanced", server_func.show_advanced)
end

server_func.create_server = function(ip, port)
  server = sock.newServer(ip, port)
end

return server_func
