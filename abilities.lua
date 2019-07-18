local field = require "field"
local rules = require "rules"
local football = require "football"

local abilities = {}

abilities.load = function()
end

abilities.use = function(id, player, x, y)
  if abilities.valid(player.tile_x, player.tile_y, x, y) then
    local type = abilities.type(id, player)
    return abilities.start[type](id, player, x, y)
  else
    abilities.cancel()
    return false
  end
end

abilities.cancel = function(id, player)
  local type = abilities.type(id, player)
  abilities.reset[type](id, player)
end

abilities.type = function(id, player)
  local qb = rules.get_qb()
  local offense = rules.get_offense()
  if qb == id then
    return "throw"
  elseif player.team == offense then
    return "shield"
  else
    return "sword"
  end
end

abilities.start = {}

abilities.start.throw = function(id, player, x, y)
  if not football.thrown() then
    football.throw(player.x, player.y, x, y)
    return true
  end
  return false
end

abilities.start.shield = function(id, player, x, y)
  if abilities.adjacent(player.tile_x, player.tile_y, x, y) then
  else
    return false
  end
end

abilities.start.sword = function(id, player, x, y)
  if abilities.adjacent(player.tile_x, player.tile_y, x, y) then
  else
    return false
  end
end

abilities.reset = {}

abilities.reset.throw = function(id, player)
  football.reset()
end

abilities.reset.sword = function(id, player)
end

abilities.reset.shield = function(id, player)
end

abilities.valid = function(x1, y1, x2, y2)
  return field.in_bounds(x2, y2) and not (x1 == x2 and y1 == y2)
end

abilities.adjacent = function(x1, y1, x2, y2)
  return (math.abs(x2-x1) == 1 or math.abs(y2-y1) == 1)
end

return abilities
