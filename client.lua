local nui = require "nui"
local menu = require "menu"

client_func = {}

local ip_test = {}
local servers = {}
client = nil
id = 0
local textboxes = {ip_port = "", username = ""}


client_func.load = function()
  client_func.test_for_servers()

  -- gui
  nui.remove.all()
  local w, h = love.graphics.getDimensions()
  nui.add.menu("join", "Join Server", 2, w/2-224, h/2-128, 192, 256, false)
  nui.add.textbox("join", "username", 48, 28, 96, textboxes, "username", "Username")
  nui.add.textbox("join", "ip", 20, 66, 152, textboxes, "ip_port", "I.P.")
  nui.add.button("join", "join", 20, 222, 64, 16, {content = "Join", func = client_func.direct_connect})
  nui.add.button("join", "leave", 108, 222, 64, 16, {content = "Leave", func = client_func.main_menu})

  nui.add.menu("lan", "Local Games", 2, w/2+32, h/2-128, 192, 256, true)
  nui.add.button("lan", "refresh", 64, 26, 64, 16, {content = "Refresh", func = client_func.refresh_test})
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
  nui.remove.all()
  client_func.stop_test()
  network_state = ""
  network.load()
end

client_func.leave_server = function()
  client:disconnectNow(1)
  client = nil
  client_func.load()
  state = "network"
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
    state = "menu"

    nui.remove.all()
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
      end
    end)
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
      menu.remove_client(data)
    end)
    client:setSchema("client_info", {"id", "username"})
    client:on("client_info", function(data)
      menu.update_client(data.id, data.username)
    end)

    menu.load(client_func.leave_server)
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
      nui.add.button("lan", i, 20, 66+(index-1)*32, 152, 32, {content = data.username.."\n"..data.desc, func = client_func.join_server, args = {ip = ip, port = default_port}})
    end)
    ip_test[i]:on("kick", function()
      ip_test[i]:disconnect(0)
      client_func.refresh_test()
    end)
    ip_test[i]:on("start_game", function()
      ip_test[i]:disconnect(0)
      client_func.refresh_test()
    end)
  end
end

client_func.stop_test = function()
  for i, v in ipairs(ip_test) do
    v:disconnectNow(0)
    v = nil
  end
  for i, v in ipairs(servers) do -- reset gui
    nui.remove.element("lan", v.num)
  end
  servers = {}
  ip_test = {}
end

client_func.refresh_test = function()
  client_func.stop_test()
  client_func.test_for_servers()
end

return client_func
