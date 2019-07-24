local gui = require "gui"

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

  gui.remove_all()
  gui.new_button("leave", 0, 0, 128, 32, "Main Menu", results.leave)

  players = game_players
  team_info = game_team_info
end

results.draw = function()
  love.graphics.print(team_info[1].name..": "..tostring(team_info[1].score), 0, 32)
  love.graphics.print(team_info[2].name..": "..tostring(team_info[2].score), 128, 32)
  local team_order = {0, 0}
  for k, v in pairs(players) do
    love.graphics.setColor(team_info[v.team].color)
    love.graphics.print(v.username, (v.team-1)*128, 44+team_order[v.team]*16)
    team_order[v.team] = team_order[v.team] + 1
  end
  love.graphics.setColor(1, 1, 1)
end

results.leave = function()
  state = "network"
  network_state = ""
  reset = true
end

return results
