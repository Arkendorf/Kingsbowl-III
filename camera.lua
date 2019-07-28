local field = require "field"
local rules = require "rules"

local camera = {}

local cam = {}

camera.load = function()
  cam = {x = 0, y = 0, new_x = 0, new_y = 0}
  camera.scrimmage()
  cam.x = cam.new_x
  cam.y = cam.new_y
end

camera.update = function(dt)
  cam.x = cam.x + (cam.new_x - cam.x)*4*dt
  cam.y = cam.y + (cam.new_y - cam.y)*4*dt
end

camera.get = function()
  return cam
end

camera.scrimmage = function()
  local scrimmage = rules.get_scrimmage()
  local field_w, field_h = field.get_dimensions()
  cam.new_x = (scrimmage+1)*tile_size
  cam.new_y = (field_h/2)*tile_size
end

camera.player = function(player)
  cam.new_x = (player.x+.5)*tile_size
  cam.new_y = (player.y+.5)*tile_size
end

return camera
