local gui = require "gui"

local menu = {}

local client_list = {}
local client_info = {}
local team_info = {}
local settings = false

menu.load = function()
  if state == "server" then
    gui.new_button("start", 128, 0, 128, 32, "Start Game", menu.start_game)
    menu.close_settings()
    menu.create_client_buttons()
  elseif state == "client" then
    client:setSchema("team_swap", {"id", "team"})
    client:on("team_swap", function(data)
      menu.decrease_team_size(client_info[data.id].team)
      menu.increase_team_size(data.team)
      client_info[data.id].team = data.team
    end)
  end
end

menu.draw = function()
  if not settings then
    local team_order = {0, 0}
    for i, v in ipairs(client_list) do
      local team = client_info[v].team
      love.graphics.setColor(team_info[team].color)
      love.graphics.print(client_info[v].username, (team-1)*128, 32+team_order[team]*16)
      team_order[team] = team_order[team] + 1
    end
  end
  love.graphics.setColor(1, 1, 1)
end

menu.add_client = function(id, index, username, team)
  menu.increase_team_size(team)
  client_list[#client_list+1] = id
  client_info[id] = {index = index, username = username, team = team}
  if state == "server" and not settings then
    menu.reset_client_buttons()
  end
end

menu.remove_client = function(id)
  menu.remove_client_buttons(id)
  menu.decrease_team_size(client_info[id].team)
  -- remove client from client list
  for i, v in ipairs(client_list) do
    if v == id then
      table.remove(client_list, i)
      break
    end
  end
  -- erase client's info
  client_info[id] = nil
end

menu.update_client = function(id, username)
  client_info[id].username = username
end

menu.get_client_info = function(id)
  return client_info[id]
end

menu.get_client_list = function()
  return client_list
end

menu.reset_info = function()
  client_list = {}
  team_info = {{size = 0, color = {255, 0, 0}}, {size = 0, color = {0, 0, 255}}}
end

menu.choose_team = function()
  if team_info[1].size > team_info[2].size then
    return 2
  else
    return 1
  end
end

menu.increase_team_size = function(team)
  team_info[team].size = team_info[team].size + 1
end

menu.decrease_team_size = function(team)
  team_info[team].size = team_info[team].size - 1
end

menu.swap_team = function(data)
  local new_team = 1
  if client_info[data.id].team == 1 then
    new_team = 2
  end
  menu.decrease_team_size(client_info[data.id].team)
  menu.increase_team_size(new_team)
  client_info[data.id].team = new_team
  server:sendToAll("team_swap", {data.id, new_team})
  menu.reset_client_buttons()
end

menu.kick = function(data)
  if data.id ~= 0 then
    server:sendToPeer(server:getPeerByIndex(client_info[data.id].index), "kick")
  end
end

menu.remove_client_buttons = function(id)
  gui.remove_button("swap"..tostring(id))
  gui.remove_button("kick"..tostring(id))
end

menu.create_client_buttons = function()
  local team_order = {0, 0}
  for i, v in ipairs(client_list) do
    local team = client_info[v].team
    gui.new_button("swap"..tostring(v), 64+(team-1)*128, 32+team_order[team]*16, 32, 16, "Swap", menu.swap_team, {id = v})
    if v ~= 0 then
      gui.new_button("kick"..tostring(v), 96+(team-1)*128, 32+team_order[team]*16, 32, 16, "Kick", menu.kick, {id = v})
    end
    team_order[team] = team_order[team] + 1
  end
end

menu.remove_client_buttons = function()
  for i, v in ipairs(client_list) do
    gui.remove_button("swap"..tostring(v))
    gui.remove_button("kick"..tostring(v))
  end
end

menu.reset_client_buttons = function()
  menu.remove_client_buttons()
  menu.create_client_buttons()
end

menu.close_settings = function()
  menu.create_client_buttons()
  gui.remove_button("close")
  gui.new_button("settings", 256, 0, 64, 32, "Settings", menu.open_settings)
  settings = false
end

menu.open_settings = function()
  menu.remove_client_buttons()
  gui.remove_button("settings")
  gui.new_button("close", 256, 0, 64, 32, "Close", menu.close_settings)
  settings = true
end

menu.start_game = function()
  if team_info[1].size > 0 and team_info[2].size > 0 then
    -- start game here
  end
end

return menu
