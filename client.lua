local nui = require "nui"
local menu = require "menu"
local window = require "window"
local game = require "game"

client_func = {}

local ip_test = {}
local servers = {}
client = nil
id = 0
local textboxes = {ip_port = "", username = ""}
local lan = false


client_func.load = function()

  -- gui
  nui.remove.all()
  local w, h = window.get_dimensions()
  if lan then
    client_func.test_for_servers()

    nui.add.menu("join", "Join Server", 2, w/2-224, h/2-128, 192, 256, false)

    nui.add.menu("lan", "Local Games", 2, w/2+32, h/2-128, 192, 256, true)
    nui.add.button("lan", "refresh", 64, 26, 64, 16, {content = "Refresh", func = client_func.refresh_test})
  else
    nui.add.menu("join", "Join Server", 2, w/2-96, h/2-128, 192, 256, false)
  end

  nui.add.textbox("join", "username", 48, 28, 96, textboxes, "username", "Username")
  nui.add.textbox("join", "ip", 20, 66, 152, textboxes, "ip_port", "I.P.")
  nui.add.button("join", "join", 20, 222, 64, 16, {content = "Join", func = client_func.direct_connect})
  nui.add.button("join", "leave", 108, 222, 64, 16, {content = "Leave", func = client_func.main_menu})

  id = 0
end

client_func.update = function(dt)
  if client then
    client:update()
  end
  for k, v in pairs(ip_test) do
    pcall(client_func.test_update, v)
    if v:isDisconnected() then
      client_func.destroy_test(k, v)
    end
  end
end

client_func.test_update = function(object)
  object:update()
end

client_func.draw = function()
end

client_func.keypressed = function(key)
  if key == "escape" then
    client_func.main_menu()
  end
end

client_func.quit = function()
  if client then
    client:disconnectNow(1)
    client_func.destroy()
  else
    client_func.clear_test()
  end
end

client_func.main_menu = function()
  nui.remove.all()
  client_func.clear_test()
  network_state = ""
  network.load()
end

client_func.leave_server = function()
  client:disconnectNow(1)
  client_func.destroy()
  client_func.load()
  state = "network"
end

client_func.destroy = function()
  client:destroy()
  client = nil
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
    client_func.clear_test()
    -- event calls once connected to a server
    client:on("connect", function()
      if client then
        client_func.start_menu()
        id = client.connectId
        client:send("client_info", {textboxes.username})
      end
    end)
  else
    client_func.destroy()
  end
end

client_func.start_menu = function()
  state = "menu"

  nui.remove.all()
  -- make sure username has a value
  if textboxes.username == "" then
    textboxes.username = default_username
  end

  menu.reset_info()

  client:on("kick", function()
    if client then
      client_func.leave_server()
    end
  end)
  client:setSchema("new_client", {"id", "index", "username", "team"})
  client:on("new_client", function(data)
    menu.add_client(data.id, data.index, data.username, data.team)
  end)
  client:on("client_quit", function(data)
    if state == "menu" then
      menu.remove_client(data)
    elseif state == "game" then
      game.remove_client(data)
    end
  end)
  client:setSchema("client_info", {"id", "username"})
  client:on("client_info", function(data)
    menu.update_client(data.id, data.username)
  end)

  menu.load(client_func.leave_server)
end

client_func.test_for_servers = function()
  ip_test = {}
  for i = 1, 254 do
    local ip = default_ip_prefix..tostring(i)
    ip_test[i] = sock.newClient(ip, default_port)
    if pcall(client_func.test_connect, ip_test[i]) then
      ip_test[i]:setTimeout(32, 200, 300)
      ip_test[i]:setSchema("server_info", {"username", "desc", "client_num"})
      ip_test[i]:on("server_info", function(data)
        local index = #servers+1
        servers[index] = {ip = ip, num = i, info = data}
        nui.add.button("lan", i, 20, 66+(index-1)*56, 152, 32, {content = data.username.."\n"..data.desc, func = client_func.join_server, args = {ip = ip, port = default_port}})
        ip_test[i]:disconnect(0)
        client_func.destroy_test(i, ip_test[i])
      end)
      ip_test[i]:on("kick", function()
        ip_test[i]:disconnect(0)
        client_func.refresh_test()
      end)
      ip_test[i]:on("start_game", function()
        ip_test[i]:disconnect(0)
        client_func.refresh_test()
      end)
    else
      client_func.destroy_test(i, ip_test[i])
    end
  end
end

client_func.test_connect = function(object)
  object:connect(0)
end

client_func.destroy_test = function(i, v)
  v:destroy()
  ip_test[i] = nil
end

client_func.stop_test = function()
  for k, v in pairs(ip_test) do
    v:disconnectNow(0)
    client_func.destroy_test(k, v)
  end
end

client_func.clear_test = function()
  client_func.stop_test()
  for i, v in ipairs(servers) do -- reset gui
    pcall(function() nui.remove.element("lan", v.num) end)
  end
  servers = {}
  ip_test = {}
end

client_func.refresh_test = function()
  client_func.clear_test()
  client_func.test_for_servers()
end

client_func.lan_active = function(active)
  lan = active
end

return client_func
