local gui = require "gui"
local menu = require "menu"

client_func = {}

local ip_test = {}
local servers = {}
client = nil
local id = 0
local textboxes = {ip_port = "", username = ""}


client_func.load = function()
  client_func.test_for_servers()
  gui.remove_all()
  gui.new_textbox("username", 0, 0, 256, 16, "Username", textboxes, "username")
  gui.new_button("refresh", 192, 16, 64, 16, "Refresh", client_func.refresh_test)
  gui.new_button("main_menu", 64, 0, 128, 16, "Main Menu", client_func.main_menu)
  client_func.hide_advanced()
end

client_func.update = function(dt)
  if client then
    client:update()
  end
  for i, v in ipairs(ip_test) do
    v:update()
  end
end

client_func.draw = function()
  if client then
    menu.draw()
  else
    love.graphics.print("Servers open on LAN:", 0, 16)
    for i, v in ipairs(servers) do
      love.graphics.printf(v.info.username, 0, 32+(i-1)*32, 256, "left")
      love.graphics.printf("ping: "..tostring(ip_test[v.num]:getRoundTripTime()), 0, 32+(i-1)*32, 256, "right")
      love.graphics.printf(v.info.desc, 0, 32+(i-.5)*32, 256, "left")
      love.graphics.printf("players: "..tostring(v.info.client_num), 0, 32+(i-.5)*32, 256, "right")
    end
  end
end

client_func.quit = function()
  if client then
    client:disconnectNow(1)
    client = nil
  else
    client_func.stop_test()
  end
end

client_func.main_menu = function()
  gui.remove_all()
  client_func.stop_test()
  state = ""
  network.load()
end

client_func.leave_server = function()
  client:disconnectNow(1)
  client = nil
  client_func.load()
end

client_func.show_advanced = function()
  gui.remove_button("advanced")
  gui.new_textbox("ip_port", 0, 0, 128, 16, "I.P.", textboxes, "ip_port")
  gui.new_button("join", 128, 0, 64, 16, "Join", client_func.direct_connect)
  gui.new_button("hide", 192, 0, 64, 16, "Hide", client_func.hide_advanced)
  client_func.set_advanced_pos()
end

client_func.hide_advanced = function()
  gui.remove_textbox("ip_port")
  gui.remove_button("join")
  gui.remove_button("hide")
  gui.new_button("advanced", 0, 0, 256, 16, "Connect Manually", client_func.show_advanced)
  client_func.set_advanced_pos()
end

client_func.set_advanced_pos = function()
  local y = 32+(#servers)*32
  gui.edit_button("advanced", "y", y)
  gui.edit_textbox("ip_port", "y", y)
  gui.edit_button("join", "y", y)
  gui.edit_button("hide", "y", y)
  gui.edit_button("main_menu", "y", y+16)
end

client_func.direct_connect = function()
  local ip, port = network.decode_ip_port(textboxes.ip_port, "localhost")
  client_func.join_server({ip = ip, port = port})
end

client_func.connect = function()
  client:connect(1)
end

client_func.join_server = function(address)
  client_func.stop_test()
  client = sock.newClient(address.ip, address.port)
  if pcall(client_func.connect) then
    gui.remove_all()
    -- make sure username has a value
    if textboxes.username == "" then
      textboxes.username = default_username
    end

    menu.reset_info()

    -- event calls once connected to a server
    client:on("connect", function()
      if client then
        id = client.connectId
        client:send("client_info", {textboxes.username})
        gui.new_button("leave", 0, 0, 128, 32, "Leave", client_func.leave_server)
      end
    end)
    client:on("kick", function()
      if client then
        client:disconnectNow(1)
        client = nil
        client_func.load()
      end
    end)
    client:setSchema("new_client", {"id", "index", "username", "team"})
    client:on("new_client", function(data)
      menu.add_client(data.id, data.index, data.username, data.team)
    end)
    client:on("client_quit", function(data)
      menu.remove_client(data)
    end)
    client:setSchema("client_info", {"id", "username"})
    client:on("client_info", function(data)
      menu.update_client(data.id, data.username)
    end)

    menu.load()
  else
    client = nil
  end
end

client_func.test_for_servers = function()
  ip_test = {}
  for i = 1, 255 do
    local ip = default_ip_prefix..tostring(i)
    ip_test[i] = sock.newClient(ip, default_port)
    ip_test[i]:connect(0)
    ip_test[i]:setSchema("server_info", {"username", "desc", "client_num"})
    ip_test[i]:on("server_info", function(data)
      local index = #servers+1
      servers[index] = {ip = ip, num = i, info = data}
      gui.new_button(i, 0, 32+(index-1)*32, 256, 32, "", client_func.join_server, {ip = ip, port = default_port})
      client_func.set_advanced_pos()
    end)
  end
end

client_func.stop_test = function()
  for i, v in ipairs(ip_test) do
    v:disconnectNow(0)
    v = nil
  end
  for i, v in ipairs(servers) do -- reset gui
    gui.remove_button(v.num)
  end
  servers = {}
  ip_test = {}
  client_func.set_advanced_pos()
end

client_func.refresh_test = function()
  client_func.stop_test()
  client_func.test_for_servers()
end

return client_func
