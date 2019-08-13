local field = require "field"
local rules = require "rules"
local window = require "window"
local football = require "football"

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

camera.object = function(object)
  local x = object.x
  local y = object.y
  if object.item and object.item.x and object.item.y then
    x = object.item.x
    y = object.item.y
  end
  cam.new_x = (x+.5)*tile_size
  cam.new_y = (y+.5)*tile_size
end

camera.get_offset = function()
  local w, h = window.get_dimensions()
  local cam = camera.get()
  return math.floor(-cam.x+w/2), math.floor(-cam.y+h/2)
end

return camera
