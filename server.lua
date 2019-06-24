local gui = require "gui"

local server_func = {}

local server = nil
local client_list = {}
local client_info = {}
local id = 0
local textboxes = {ip_port = "", desc = "", username = ""}
local default_desc = "Server"

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
  if server then
    for i, v in ipairs(client_list) do
      love.graphics.print(client_info[v].username, 0, 32+(i-1)*12)
    end
  end
end

server_func.quit = function()
  if server then
    server:sendToAll("server_closed")
    server:update()
    server:destroy()
    server = nil
  end
end

server_func.main_menu = function()
  gui.remove_all()
  state = ""
  network.load()
end

server_func.leave_server = function()
  gui.remove_all()
  server_func.quit()
  server_func.load()
end

server_func.start_server = function()
  if pcall(function() server_func.create_server(network.decode_ip_port(textboxes.ip_port)) end) then -- attempt to initialize server
    gui.remove_all()
    gui.new_button("leave", 0, 0, 128, 32, "Leave", server_func.leave_server)
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
  -- make sure username and description have a value
  if textboxes.username == "" then
    textboxes.username = default_username
  end
  if textboxes.desc == "" then
    textboxes.desc = default_desc
  end

  -- set up client for server
  client_list = {0}
  client_info[0] = {index = 0, username = textboxes.username}

  -- event calls for server
  server:on("connect", function(data, client)
    if data == 0 then -- client is checking for an active server
      server:sendToPeer(server:getPeerByIndex(client:getIndex()), "server_info", {client_info[0].username, textboxes.desc, #client_list})
    elseif data == 1 then -- client has decided to join server
      local index = client:getIndex()
      client_list[#client_list+1] = client.connectId
      client_info[client.connectId] = {index = index, username = ""}
      server:sendToAllBut(client, "new_client", {client.connectId, index, ""})
      local peer = server:getPeerByIndex(index)
      for i, v in ipairs(client_list) do
        server:sendToPeer(peer, "new_client", {v, client_info[v].index, client_info[v].username})
      end
    end
  end)
  server:on("disconnect", function(data, client)
    if data == 1 then -- make sure it's a genuine player who left
      -- remove client from client list
      for i, v in ipairs(client_list) do
        if v == client.connectId then
          table.remove(client_list, i)
          break
        end
      end
    end
    -- erase client's info
    client_info[client.connectId] = nil
    -- inform other clients of departure
    server:sendToAll("client_quit", client.connectId)
  end)
  server:setSchema("client_info", {"username"})
  server:on("client_info", function(data, client)
    client_info[client.connectId].username = data.username
    server:sendToAll("client_info", {client.connectId, data.username})
  end
  )
end

return server_func
