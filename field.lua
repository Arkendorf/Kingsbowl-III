local field = {}

local field_w = 60
local field_h = 27
local canvas = false
local interval = math.floor(field_w/12)
local yard_mark_y = {1, field_h, math.ceil(field_h/2-interval), math.ceil(field_h/2+interval)}
local number_y = {interval, field_h-interval}

field.load = function()
  canvas = love.graphics.newCanvas((field_w+2)*tile_size, (field_h+2)*tile_size)
  field.draw_canvas(canvas)
end

field.draw = function()
  love.graphics.draw(canvas, -tile_size, -tile_size)
end

field.draw_canvas = function(canvas)
  love.graphics.setCanvas(canvas)
  for x = 1, field_w do -- draw basic tiles
    for y = 1, field_h do
      local type = 1+((x+y)/2-math.floor((x+y)/2))*2
      art.draw_quad("tiles", art.quad.tiles[type], x, y)
    end
  end
  for x = interval+1, field_w-interval do -- draw yard intervals
    for i, y in ipairs(yard_mark_y) do
      art.draw_quad("markings", art.quad.markings[4], x, y)
    end
  end
  for i = 1, 10 do -- draw 5 yard intervals
    local x = math.ceil((i+.5) * interval)
    for y = 1, field_h do
      art.draw_quad("markings", art.quad.markings[3], x, y)
    end
  end
  for i = 1, 11 do -- draw 10 yard intervals
    local x = i * interval
    for y = 1, field_h do
      art.draw_quad("markings", art.quad.markings[1], x, y)
      art.draw_quad("markings", art.quad.markings[2], x+1, y)
    end
  end
  for i = 1, 9 do -- draw yard numbers
    local x = (i + 1) * interval
    for j, y in ipairs(number_y) do
      if i <= 5 then
        art.draw_quad("markings", art.quad.markings[12+i], x, y)
        art.draw_quad("markings", art.quad.markings[19], x-1, y)
      else
        art.draw_quad("markings", art.quad.markings[22-i], x, y)
        art.draw_quad("markings", art.quad.markings[20], x+2, y)
      end
      art.draw_quad("markings", art.quad.markings[18], x+1, y)
    end
  end
  for x = 1, field_w do -- draw field borders on top and bottom
    art.draw_quad("markings", art.quad.markings[5], x, 0)
    art.draw_quad("markings", art.quad.markings[6], x, field_h+1)
  end
  for y = 1, field_h do
    art.draw_quad("markings", art.quad.markings[7], 0, y)
    art.draw_quad("markings", art.quad.markings[8], field_w+1, y)
  end
  art.draw_quad("markings", art.quad.markings[9], 0, 0) -- corners
  art.draw_quad("markings", art.quad.markings[10], field_w+1, 0)
  art.draw_quad("markings", art.quad.markings[11], field_w+1, field_h+1)
  art.draw_quad("markings", art.quad.markings[12], 0, field_h+1)
  love.graphics.setCanvas()
end

field.in_bounds = function(x, y)
  return (x >= 0 and x <= field_w and y >= 0 and y <= field_h)
end

field.get_dimensions = function()
  return field_w, field_h
end

field.cap_tile = function(x, y)
  if x < 0 then -- don't let tile_x exceed field
    x = 0
  elseif x > field_w then
    x = field_w
  end
  if y < 0 then
    y = 0
  elseif y > field_h then
    y = field_h
  end
  return x, y
end

return field
