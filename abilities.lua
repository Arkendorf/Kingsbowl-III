local field = require "field"
local rules = require "rules"
local football = require "football"

local abilities = {}

abilities.load = function()
end

abilities.use = function(id, player, x, y)
  if abilities.valid(player.tile_x, player.tile_y, x, y) then
    local type = abilities.type(id, player)
    if type then -- ball carrier cannot use an ability
      return abilities.start[type](id, player, x, y)
    else
      return false
    end
  else
    abilities.cancel(id, player)
    return false
  end
end

abilities.cancel = function(id, player)
  local type = abilities.type(id, player)
  if type then
    abilities.reset[type](id, player)
  end
end

abilities.type = function(id, player)
  local qb = rules.get_qb()
  local offense = rules.get_offense()
  local ball = football.get_ball()
  if qb == id and not ball.thrown then
    return "throw"
  elseif not player.carrier then
    return "item"
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

abilities.start.item = function(id, player, x, y)
  if abilities.adjacent(player.tile_x, player.tile_y, x, y) then
    player.item.tile_x = x
    player.item.tile_y = y
    player.item.active = true
    return true
  else
    return false
  end
end

abilities.reset = {}

abilities.reset.throw = function(id, player)
  football.reset()
end

abilities.reset.item = function(id, player)
  player.item.active = false
end


abilities.valid = function(x1, y1, x2, y2)
  return field.in_bounds(x2, y2) and not (x1 == x2 and y1 == y2)
end

abilities.adjacent = function(x1, y1, x2, y2)
  local x_dif = x2-x1
  local y_dif = y2-y1
  return (x_dif >= -1 and x_dif <= 1 and y_dif >= -1 and y_dif <= 1)
end

return abilities
