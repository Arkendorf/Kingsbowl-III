local field = {}

local field_w = 60
local field_h = 27
local canvas = 0

field.load = function()
  canvas = love.graphics.newCanvas(field_w*tile_size, field_h*tile_size)
  field.draw_canvas(canvas)
end

field.draw = function()
  love.graphics.draw(canvas)
end

field.draw_canvas = function(canvas)
  love.graphics.setCanvas(canvas)
  for x = 0, field_w-1 do
    for y = 0, field_h-1 do
      local type = ((x+y)/2-math.floor((x+y)/2))*2
      if type == 1 then
        love.graphics.setColor(.2, .2, .2)
      else
        love.graphics.setColor(.1, .1, .1)
      end
      love.graphics.rectangle("fill", x*tile_size, y*tile_size, tile_size, tile_size)
      if type == 1 then
        love.graphics.setColor(.1, .1, .1)
      else
        love.graphics.setColor(.2, .2, .2)
      end
      love.graphics.print(x, x*tile_size+2, y*tile_size+2)
    end
  end
  love.graphics.setColor(1, 1, 1)
  love.graphics.setCanvas()
end

field.in_bounds = function(x, y)
  return (x >= 0 and x <= field_w and y >= 0 and y <= field_h)
end

field.get_dimensions = function()
  return field_w, field_h
end

return field
