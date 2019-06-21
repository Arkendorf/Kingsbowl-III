local game = {}

local players = {}
local started = false
local id = nil

game.load = function(id, client_list)
  id = id
  for i, v in ipairs(client_list) do
    game.add_player(v)
  end
  started = true
end

game.add_player = function(id, pos)
  players[#players+1] = {id = id}
end

game.started = function()
  return started
end

return game
