local field = require "field"
local rules = require "rules"
local football = require "football"
local movement = require "movement"
local nui = require "nui"

local abilities = {}

abilities.load = function()
end

abilities.update_item = function(knight, dt)
  if movement.update_object(knight.item, dt) then
    if not knight.item.active then
      knight.item.visible = false
    end
    knight.item.flourish = false
  end
end

abilities.draw_item = function(knight, team, resolve)
  if knight.item.visible and abilities.adjacent(knight.tile_x, knight.tile_y, knight.item.tile_x, knight.item.tile_y) then
    local quad = art.direction(knight.tile_x, knight.tile_y, knight.item.tile_x, knight.item.tile_y)
    art.draw_quad(knight.item.type, art.quad.item[quad], knight.item.x, knight.item.y)
    art.draw_quad(knight.item.type.."_overlay", art.quad.item[quad], knight.item.x, knight.item.y, 1, 1, 1, "color", palette[rules.get_color(knight.team)])
  end
  if knight.item.active and team == knight.team and not resolve then
    local quad = art.direction(knight.tile_x, knight.tile_y, knight.item.new_x, knight.item.new_y)
    art.draw_quad(knight.item.type, art.quad.item[quad], knight.item.new_x, knight.item.new_y, colors.white[1], colors.white[2], colors.white[3], "border")
  end
end

abilities.update_hud = function(knight_id, knight, action, dt)
  if action == "position" then
    nui.edit.element("", "move", "content", {img = art.img.ability_icons, quad = art.quad.ability_icon[5]})
  else
    nui.edit.element("", "move", "content", {img = art.img.ability_icons, quad = art.quad.ability_icon[1]})
  end
  if knight.carrier then
    nui.edit.element("", "ability", "content", {img = art.img.ability_icons, quad = art.quad.ability_icon[6]})
  elseif abilities.type(knight_id, knight) == "throw" then
    nui.edit.element("", "ability", "content", {img = art.img.ability_icons, quad = art.quad.ability_icon[4]})
  elseif knight.team == rules.get_offense() then
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

abilities.use = function(knight_id, knight, x, y)
  if abilities.valid(knight.tile_x, knight.tile_y, x, y) then
    local type = abilities.type(knight_id, knight)
    if type then -- ball carrier cannot use an ability
      return abilities.start[type](knight, x, y)
    else
      return false
    end
  else
    abilities.cancel(knight_id, knight)
    return false
  end
end

abilities.cancel = function(knight_id, knight)
  local type = abilities.type(knight_id, knight)
  if type then
    abilities.reset[type](knight, 0)
  end
end

abilities.type = function(knight_id, knight)
  local qb = rules.get_qb()
  local offense = rules.get_offense()
  local ball = football.get_ball()
  if qb == knight_id and not ball.thrown then
    return "throw"
  elseif not knight.carrier then
    return "item"
  end
end

abilities.start = {}

abilities.start.throw = function(knight, x, y)
  if not football.thrown() then
    football.throw(knight.x, knight.y, x, y)
    return true
  end
  return false
end

abilities.preview_throw = function(knight, x, y)
  if abilities.valid(knight.tile_x, knight.tile_y, x, y) then
    local path = movement.get_path(knight.tile_x, knight.tile_y, x, y)
    movement.draw_path(knight.tile_x, knight.tile_y, path, colors.green[1], colors.green[2], colors.green[3])
    local quad = art.direction(knight.tile_x, knight.tile_y, path[1].x, path[1].y)
    art.draw_quad("arrow", art.quad.item[quad], knight.tile_x, knight.tile_y, colors.green[1], colors.green[2], colors.green[3], "border")
  else
    art.path_icon(4, x, y, colors.red[1], colors.red[2], colors.red[3])
  end
end

abilities.preview_item = function(knight_id, knight, knights, x, y)
  if abilities.valid(knight.tile_x, knight.tile_y, x, y) and abilities.adjacent(knight.tile_x, knight.tile_y, x, y) then
    if not abilities.overlap(knight_id, knight, knights, x, y) then
      local quad = art.direction(knight.tile_x, knight.tile_y, x, y)
      if knight.team == rules.get_offense() then
        art.draw_quad("shield", art.quad.item[quad], x, y, colors.green[1], colors.green[2], colors.green[3], "border")
      else
        art.draw_quad("sword", art.quad.item[quad], x, y, colors.green[1], colors.green[2], colors.green[3], "border")
      end
    else
      art.path_icon(3, x, y, colors.red[1], colors.red[2], colors.red[3])
    end
  else
    art.path_icon(4, x, y, colors.red[1], colors.red[2], colors.red[3])
    art.path_border(knight.tile_x, knight.tile_y, 1.5, abilities.adjacent)
  end
end

abilities.overlap = function(knight_id, knight, knights, x, y)
  if abilities.type(knight_id, knight) == "item" then
    for i, v in ipairs(knights) do -- make sure teammate hasn't put an item in the tile
      if v.item.active and v.team == knight.team then
        if v.item.tile_x == x and v.item.tile_y == y then
          return false
        end
      end
    end
  end
end

abilities.start.item = function(knight, x, y)
  if abilities.adjacent(knight.tile_x, knight.tile_y, x, y) then
    knight.item.new_x = x
    knight.item.new_y = y
    knight.item.active = true
    if knight.team == rules.get_offense() then
      knight.item.type = "shield"
    else
      knight.item.type = "sword"
    end
    return true
  else
    return false
  end
end

abilities.set = function(knight, step_time)
  if knight.item.active then
    knight.item.visible = true
    knight.item.tile_x = knight.item.new_x
    knight.item.tile_y = knight.item.new_y
    knight.item.x = knight.tile_x
    knight.item.y = knight.tile_y
    movement.lerp(knight.item, knight.tile_x, knight.tile_y, knight.item.tile_x, knight.item.tile_y, step_time/2)
  end
end

abilities.reset = {}

abilities.reset.throw = function()
  football.reset()
end

abilities.reset.item = function(knight, step_time)
  knight.item.active = false
  if knight.item.visible then
    if knight.item.flourish then
      abilities.sheath(knight)
    else
      movement.lerp(knight.item, knight.item.tile_x, knight.item.tile_y, knight.tile_x, knight.tile_y, step_time/2)
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

abilities.collide = function(i, v, knights, step_time)
  if v.team == rules.get_offense() and v.item.active then
    for j, w in ipairs(knights) do
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

abilities.stab = function(knight, tackler, step_time)
  abilities.start.item(tackler, knight.tile_x, knight.tile_y)
  abilities.set(tackler, step_time)
  movement.bounce(tackler.item, tackler.tile_x, tackler.tile_y, tackler.item.tile_x, tackler.item.tile_y, step_time, .75)
end

abilities.flourish = function(knight, step_time, sheath)
  local x_dif = knight.item.tile_x - knight.tile_x
  local y_dif = knight.item.tile_y - knight.tile_y
  movement.bounce(knight.item, knight.item.tile_x, knight.item.tile_y, knight.item.tile_x+x_dif, knight.item.tile_y+y_dif, step_time/2, .25)
  knight.item.flourish = true
  if sheath then
    abilities.sheath(knight)
  end
end

abilities.sheath = function(knight)
  knight.item.goal_x = knight.tile_x
  knight.item.goal_y = knight.tile_y
end

return abilities
