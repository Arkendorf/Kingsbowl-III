local field = require "field"
local rules = require "rules"
local football = require "football"
local movement = require "movement"
local nui = require "nui"

local abilities = {}

abilities.load = function()
end

abilities.update_item = function(player, dt)
  if movement.update_object(player.item, dt) then
    if not player.item.active then
      player.item.visible = false
    end
    player.item.flourish = false
  end
end

abilities.draw_item = function(player, team, resolve)
  if player.item.visible and abilities.adjacent(player.tile_x, player.tile_y, player.item.tile_x, player.item.tile_y) then
    local quad = art.direction(player.tile_x, player.tile_y, player.item.tile_x, player.item.tile_y)
    art.draw_quad(player.item.type, art.quad.item[quad], player.item.x, player.item.y)
    art.draw_quad(player.item.type.."_overlay", art.quad.item[quad], player.item.x, player.item.y, 1, 1, 1, "color", palette[rules.get_color(player.team)])
  end
  if player.item.active and team == player.team and not resolve then
    local quad = art.direction(player.tile_x, player.tile_y, player.item.new_x, player.item.new_y)
    art.draw_quad(player.item.type, art.quad.item[quad], player.item.new_x, player.item.new_y, colors.white[1], colors.white[2], colors.white[3], "outline")
  end
end

abilities.update_hud = function(id, player, action, dt)
  if action == "position" then
    nui.edit.element("", "move", "content", {img = art.img.ability_icons, quad = art.quad.ability_icon[5]})
  else
    nui.edit.element("", "move", "content", {img = art.img.ability_icons, quad = art.quad.ability_icon[1]})
  end
  if abilities.type(id, player) == "throw" then
    nui.edit.element("", "ability", "content", {img = art.img.ability_icons, quad = art.quad.ability_icon[4]})
  elseif player.team == rules.get_offense() then
    nui.edit.element("", "ability", "content", {img = art.img.ability_icons, quad = art.quad.ability_icon[2]})
  else
    nui.edit.element("", "ability", "content", {img = art.img.ability_icons, quad = art.quad.ability_icon[3]})
  end
  if action == "position" then
    nui.edit.element("", "move", "type", 1)
    nui.edit.element("", "ability", "type", 2)
  elseif action == "ability" then
    nui.edit.element("", "ability", "type", 1)
  else
    nui.edit.element("", "move", "type", 1)
  end
end

abilities.use = function(id, player, x, y)
  if abilities.valid(player.tile_x, player.tile_y, x, y) then
    local type = abilities.type(id, player)
    if type then -- ball carrier cannot use an ability
      return abilities.start[type](player, x, y)
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
    abilities.reset[type](player, 0)
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

abilities.start.throw = function(player, x, y)
  if not football.thrown() then
    football.throw(player.x, player.y, x, y)
    return true
  end
  return false
end

abilities.preview_throw = function(player, x, y)
  if abilities.valid(player.tile_x, player.tile_y, x, y) then
    local path = movement.get_path(player.tile_x, player.tile_y, x, y)
    movement.draw_path(player.tile_x, player.tile_y, path, colors.green[1], colors.green[2], colors.green[3])
    local quad = art.direction(player.tile_x, player.tile_y, path[1].x, path[1].y)
    art.draw_quad("arrow", art.quad.item[quad], player.tile_x, player.tile_y, colors.green[1], colors.green[2], colors.green[3], "outline")
  else
    art.path_icon(4, x, y, colors.red[1], colors.red[2], colors.red[3])
  end
end

abilities.preview_item = function(id, player, players, x, y)
  if abilities.valid(player.tile_x, player.tile_y, x, y) and abilities.adjacent(player.tile_x, player.tile_y, x, y) then
    if not abilities.overlap(id, player, players, x, y) then
      local quad = art.direction(player.tile_x, player.tile_y, x, y)
      if player.team == rules.get_offense() then
        art.draw_quad("shield", art.quad.item[quad], x, y, colors.green[1], colors.green[2], colors.green[3], "outline")
      else
        art.draw_quad("sword", art.quad.item[quad], x, y, colors.green[1], colors.green[2], colors.green[3], "outline")
      end
    else
      art.path_icon(3, x, y, colors.red[1], colors.red[2], colors.red[3])
    end
  else
    art.path_icon(4, x, y, colors.red[1], colors.red[2], colors.red[3])
    art.path_border(player.tile_x, player.tile_y, 1.5, abilities.adjacent)
  end
end

abilities.overlap = function(id, player, players, x, y)
  if abilities.type(id, player) == "item" then
    for k, v in pairs(players) do -- make sure teammate hasn't put an item in the tile
      if v.item.active and v.team == player.team then
        if v.item.tile_x == x and v.item.tile_y == y then
          return false
        end
      end
    end
  end
end

abilities.start.item = function(player, x, y)
  if abilities.adjacent(player.tile_x, player.tile_y, x, y) then
    player.item.new_x = x
    player.item.new_y = y
    player.item.active = true
    if player.team == rules.get_offense() then
      player.item.type = "shield"
    else
      player.item.type = "sword"
    end
    return true
  else
    return false
  end
end

abilities.set = function(player, step_time)
  if player.item.active then
    player.item.visible = true
    player.item.tile_x = player.item.new_x
    player.item.tile_y = player.item.new_y
    player.item.x = player.tile_x
    player.item.y = player.tile_y
    movement.lerp(player.item, player.tile_x, player.tile_y, player.item.tile_x, player.item.tile_y, step_time/2)
  end
end

abilities.reset = {}

abilities.reset.throw = function(player)
  football.reset()
end

abilities.reset.item = function(player, step_time)
  player.item.active = false
  if player.item.visible then
    if player.item.flourish then
      abilities.sheath(player)
    else
      movement.lerp(player.item, player.item.tile_x, player.item.tile_y, player.tile_x, player.tile_y, step_time/2)
    end
  end
end

abilities.valid = function(x1, y1, x2, y2)
  return field.in_bounds(x2, y2) and not (x1 == x2 and y1 == y2)
end

abilities.adjacent = function(x1, y1, x2, y2)
  local x_dif = x2-x1
  local y_dif = y2-y1
  return (x_dif >= -1 and x_dif <= 1 and y_dif >= -1 and y_dif <= 1 and not (x1 == x2 and y1 == y2))
end

abilities.collide = function(k, v, players, step_time)
  if v.team == rules.get_offense() and v.item.active then
    for l, w in pairs(players) do
      if w.item.active and v.team ~= w.team then -- items can collide
        if v.item.new_x == w.item.new_x and v.item.new_y == w.item.new_y then -- items occupy same tile, cancel out
          abilities.reset.item(v, step_time)
          abilities.reset.item(w, step_time)
          movement.bounce(v.item, v.tile_x, v.tile_y, v.item.new_x, v.item.new_y, step_time, .75)
          movement.bounce(w.item, w.tile_x, w.tile_y, w.item.new_x, w.item.new_y, step_time, .75)
          return true
        end
      end
    end
  end
  return false
end

abilities.stab = function(player, tackler, step_time)
  abilities.start.item(tackler, player.tile_x, player.tile_y)
  abilities.set(tackler, step_time)
  movement.bounce(tackler.item, tackler.tile_x, tackler.tile_y, tackler.item.tile_x, tackler.item.tile_y, step_time, .75)
end

abilities.flourish = function(player, step_time, sheath)
  local x_dif = player.item.tile_x - player.tile_x
  local y_dif = player.item.tile_y - player.tile_y
  movement.bounce(player.item, player.item.tile_x, player.item.tile_y, player.item.tile_x+x_dif, player.item.tile_y+y_dif, step_time/2, .25)
  player.item.flourish = true
  if sheath then
    abilities.sheath(player)
  end
end

abilities.sheath = function(player)
  player.item.goal_x = player.tile_x
  player.item.goal_y = player.tile_y
end

return abilities
