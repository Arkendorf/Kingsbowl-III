local nui = require "nui"
local game = require "game"
local field = require "field"
local turn = require "turn"
local window = require "window"
local rules = require "rules"
local broadcast = require "broadcast"

local menu = {}

local client_list = {}
local client_info = {}
local team_info = {}
local settings = {turn_time = 3, max_turns = 200, knights = 1}
local time_suffix = {"s", "m", "h"}

menu.load = function(leave_func)
  menu.reset_info()

  nui.remove.all()
  local w, h = window.get_dimensions()
  if network_state == "server" then
    nui.add.button("", "leave", w/2-112, h/2+148, 64, 16, {content = "Leave", func = leave_func})
    nui.add.button("", "start", w/2-32, h/2+148, 64, 16, {content = "Start", func = menu.start_game})
    nui.add.button("", "settings", w/2+48, h/2+148, 64, 16, {content = "Settings", func = menu.open_settings, toggle = true, func2 = menu.close_settings})

    nui.add.menu("settings", "Settings", 2, w/2-96, h/2-128, 192, 256, true)
    for team = 1, 2 do
      local y_offset = (team-1)*96
      nui.add.text("settings", "team"..tostring(team), 0, 22+y_offset, {text= "Team "..tostring(team).." Settings:", w = 192, align = "center"})
      nui.add.textbox("settings", "name"..tostring(team), 48, 44+y_offset, 96, team_info[team], "name", "Team "..tostring(team).." Name", team_info[team].color)
      for i, v in ipairs(palette) do
        local y = math.floor((i-1)/#palette*2)
        local x = (i-y*#palette/2-1)
        nui.add.button("settings", tostring(i).."_"..tostring(team), 48+x*22, 70+y*22+y_offset, 8, 8, {color = i, func = menu.team_color, args = {team = team, color = i}})
      end
    end
    nui.add.text("settings", "game", 0, 214, {text= "Game Settings:", w = 192, align = "center"})

    nui.add.text("settings", "turn_time_label", 20, 230, {text= "Turn Time:"})
    nui.add.text("settings", "turn_time_num", 20, 230, {table = settings, index = "turn_time", w = 152, align = "right", suffix = "s"})
    nui.add.slider("settings", "turn_time_slider", 20, 248, "hori", 152, 8, settings, "turn_time", 1, 60)

    nui.add.text("settings", "max_turns_label", 20, 262, {text= "Total Turns:"})
    nui.add.text("settings", "max_turns_num", 20, 262, {table = settings, index = "max_turns", w = 152, align = "right"})
    nui.add.slider("settings", "max_turns_slider", 20, 280, "hori", 152, 8, settings, "max_turns", 0, 1000)

    nui.add.text("settings", "est_time", 0, 292, {text= "Game Time: 0s", w = 192, align = "center"})

    nui.add.text("settings", "knights_label", 20, 320, {text= "Knights Per Player:"})
    nui.add.text("settings", "knights_num", 20, 320, {table = settings, index = "knights", w = 152, align = "right"})
    nui.add.slider("settings", "knights_slider", 20, 338, "hori", 152, 12, settings, "knights", 1, 12)

    nui.hide_menu("settings")
  elseif network_state == "client" then
    nui.add.button("", "leave", w/2-32, h/2+148, 64, 16, {content = "Leave", func = leave_func})

    client:setSchema("team_swap", {"id", "team"})
    client:on("team_swap", function(data)
      menu.decrease_team_size(client_info[data.id].team)
      menu.increase_team_size(data.team)
      client_info[data.id].team = data.team
      menu.char_gui()
    end)
    client:setSchema("team_name", {"team", "name"})
    client:on("team_name", function(data)
      team_info[data.team].name = data.name
      nui.edit.menu(data.team, "title", data.name)
    end)
    client:setSchema("team_color", {"team", "color"})
    client:on("team_color", function(data)
      menu.team_color(data)
    end)
    client:setSchema("start_game", {"turn_time", "max_turns", "knights"})
    client:on("start_game", function(data)
      game.load(client_list, client_info, team_info, data)
    end)
  end

  nui.add.menu(1, team_info[1].name, 2, w/2-224, h/2-128, 192, 256, true, team_info[1].color)
  nui.add.menu(2, team_info[2].name, 2, w/2+32, h/2-128, 192, 256, true, team_info[2].color)
  menu.char_gui()

  field.load()
  broadcast.load()
end

menu.update = function(dt)
  for team = 1, 2 do
    local menu = nui.get.menu(team)
    if menu.title ~= team_info[team].name then
      nui.edit.menu(team, "title", team_info[team].name)
      network.server_send("team_name", {team, team_info[team].name})
    end
  end
  nui.edit.element("settings", "est_time", "text", "Game Time: "..menu.game_time())
  broadcast.update(dt)
end

menu.game_time = function()
  local num = (settings.turn_time+turn.get_resolve_time())*settings.max_turns
  local type = 1
  while true do
    if num > 60 then
      num = num / 60
      type = type + 1
    else
      if type == 3 then
        return tostring(math.floor(num*10)/10)..time_suffix[type]
      else
        return tostring(math.floor(num))..time_suffix[type]
      end
    end
  end
end

menu.draw = function()
  love.graphics.push()
  local w, h = window.get_dimensions()
  local field_w, field_h = field.get_dimensions()
  love.graphics.translate(-(field_w*tile_size-w)/2, -(field_h*tile_size-h)/2)
  field.draw()
  love.graphics.pop()
  broadcast.draw()
end

menu.add_client = function(id, index, username, team)
  if username ~= "" then
    broadcast.new(username.." has joined!", "green")
  end
  menu.increase_team_size(team)
  client_list[#client_list+1] = id
  client_info[id] = {index = index, username = username, team = team}
  menu.char_gui()
end

menu.remove_client = function(id)
  broadcast.new(client_info[id].username.." has left", "yellow")
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
  menu.char_gui()
end

menu.update_client = function(id, username)
  broadcast.new(username.." has joined!", "green")
  client_info[id].username = username
  menu.char_gui()
end

menu.get_client_info = function(id)
  return client_info[id]
end

menu.get_client_list = function()
  return client_list
end

menu.get_team_info = function(team)
  return team_info[team]
end

menu.reset_info = function()
  client_list = {}
  team_info = {{size = 0, color = 1, name = "Team 1"}, {size = 0, color = 2, name = "Team 2"}}
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

menu.team_color = function(data)
  if not ((data.team == 1 and team_info[2].color == data.color) or (data.team == 2 and team_info[1].color == data.color)) then
    team_info[data.team].color = data.color
    nui.edit.menu(data.team, "color", data.color)
    nui.edit.element("settings", "name"..tostring(data.team), "color", data.color)
    network.server_send("team_color", {data.team, data.color})
  end
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
  menu.char_gui()
end

menu.kick = function(data)
  if data.id ~= 0 then
    server:sendToPeer(server:getPeerByIndex(client_info[data.id].index), "kick")
  end
end

menu.char_gui = function()
  nui.remove.menu_elements(1)
  nui.remove.menu_elements(2)
  local team_order = {0, 0}
  for i, v in ipairs(client_list) do
    local team = client_info[v].team
    nui.add.text(team, "name"..tostring(v), 4, 22+team_order[team]*32, {table = client_info[v], index = "username"})
    if network_state == "server" then
      nui.add.button(team, "swap"..tostring(v), 126, 20+team_order[team]*32, 16, 16, {content = {img = art.img.char_icon, quad = art.quad.char_icon[1]}, func = menu.swap_team, args = {id = v}})
      if v ~= 0 then
        nui.add.button(team, "kick"..tostring(v), 158, 20+team_order[team]*32, 16, 16, {content = {img = art.img.char_icon, quad = art.quad.char_icon[2]}, func = menu.kick, args = {id = v}})
      end
    end
    team_order[team] = team_order[team] + 1
  end
end

menu.close_settings = function()
  nui.hide_menu("settings")

  nui.show_menu(1)
  nui.show_menu(2)
  menu.char_gui()
end

menu.open_settings = function()
  nui.hide_menu(1)
  nui.hide_menu(2)

  nui.show_menu("settings")
end

menu.start_game = function()
  for team = 1, 2 do
    if team_info[team].size <= 0 then
      broadcast.new(team_info[team].name.." must have at least one player!", "red")
      return
    elseif team_info[team].size*settings.knights > rules.max_players() then
      broadcast.new("Number of players on "..team_info[team].name.." * knights per player must be below "..tostring(rules.max_players()).."! (currently "..tostring(team_info[team].size*settings.knights)..")", "red")
      return
    end
  end
  game.load(client_list, client_info, team_info, settings)
  server:sendToAll("start_game", {settings.turn_time, settings.max_turns, settings.knights})
end

return menu
