local field = require "field"
local rules = require "rules"

local cam = {}

local camera = {}

cam.load = function()
  camera = {x = 0, y = 0, new_x = 0, new_y = 0}
  cam.scrimmage()
  camera.x = camera.new_x
  camera.y = camera.new_y
end

cam.update = function(dt)
  camera.x = camera.x + (camera.new_x - camera.x)*4*dt
  camera.y = camera.y + (camera.new_y - camera.y)*4*dt
end

cam.get = function()
  return camera
end

cam.scrimmage = function()
  local scrimmage = rules.get_scrimmage()
  local field_w, field_h = field.get_dimensions()
  camera.new_x = (scrimmage+1)*tile_size
  camera.new_y = (field_h/2)*tile_size
end

cam.player = function(player)
  camera.new_x = (player.x+.5)*tile_size
  camera.new_y = (player.y+.5)*tile_size
end

return cam
