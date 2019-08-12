local nui = require "nui"
local field = require "field"
local window = require "window"

local results = {}

local players = {}
local team_info = {}

results.load = function(game_players, game_team_info)
  state = "results"

  if network_state == "server" then -- disconnect all networking, no longer necessary
    server:destroy()
    server = nil
  elseif network_state == "client" then
    client:disconnectNow(1)
    client = nil
  end
  network_state = ""

  players = game_players
  team_info = game_team_info

  nui.remove.all()
  local w, h = window.get_dimensions()
  nui.add.button("", "leave", w/2-48, h/2+148, 96, 16, {content = "Main Menu", func = results.leave})
  for team = 1, 2 do
    nui.add.menu(team, team_info[team].name, 2, w/2-224+(team-1)*256, h/2-128, 192, 256, true, team_info[team].color)
    nui.add.text(team, "label", 4, 22, {text = "Stats:"})
    for i = 1, 3 do
      nui.add.image(team, "stat"..tostring(i), 116+(i-1)*24, 22, "stat_icons", art.quad.stat_icon[i])
    end
  end
  results.char_gui()

  if team_info[1].score > team_info[2].score then
    nui.add.menu("header", team_info[1].name.." Wins! "..tostring(team_info[1].score).." to "..tostring(team_info[2].score), 1, w/2, h/2-160, 1, 1, false, team_info[1].color)
  else
    nui.add.menu("header", team_info[2].name.." Wins! "..tostring(team_info[2].score).." to "..tostring(team_info[1].score), 1, w/2, h/2-160, 1, 1, false, team_info[2].color)
  end
end

results.draw = function()
  love.graphics.push()
  local w, h = window.get_dimensions()
  local field_w, field_h = field.get_dimensions()
  love.graphics.translate(-(field_w*tile_size-w)/2, -(field_h*tile_size-h)/2)
  field.draw()
  love.graphics.pop()
end

results.char_gui = function()
  local team_order = {0, 0}
  for k, v in pairs(players) do
    nui.add.text(v.team, "name"..tostring(k), 4, 54+team_order[v.team]*32, {table = v, index = "username"})
    for i = 1, 3 do
      nui.add.text(v.team, "stat"..tostring(i)..tostring(k), 116+(i-1)*24, 54+team_order[v.team]*32, {text = v.stats[i], w = 16, align = "center"})
    end
    team_order[v.team] = team_order[v.team] + 1
  end
end

results.leave = function()
  state = "network"
  network_state = ""
  reset = true
end

return results
