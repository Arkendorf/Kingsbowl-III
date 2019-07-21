local field = {}

local field_w = 100
local field_h = 53

field.draw = function()
end

field.in_bounds = function(x, y)
  return (x >= 0 and x <= field_w and y >= 0 and y <= field_h)
end

field.get_dimensions = function()
  return field_w, field_h
end

return field
