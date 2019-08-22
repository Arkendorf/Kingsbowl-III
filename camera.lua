local field = require "field"
local rules = require "rules"
local window = require "window"
local football = require "football"

local camera = {}

local cam = {}

local move_range = 16

local shake = {t = 0, mag = 0}

camera.load = function()
  cam = {x = 0, y = 0, new_x = 0, new_y = 0, x_offset = 0, y_offset = 0}
  camera.scrimmage()
  cam.x = cam.new_x
  cam.y = cam.new_y
end

camera.update = function(dt)
  -- lerp
  cam.x = cam.x + (cam.new_x - cam.x)*4*dt
  cam.y = cam.y + (cam.new_y - cam.y)*4*dt
  -- screenshake
  if shake.t > 0 then
    shake.t = shake.t - dt
    cam.x_offset = math.random(-shake.mag, shake.mag)
    cam.y_offset = math.random(-shake.mag, shake.mag)
  end
  -- camera control
  local x, y = window.get_mouse()
  local w, h = window.get_dimensions()
  if x < move_range then
    cam.new_x = cam.new_x - 140*dt
  elseif x > w - move_range then
    cam.new_x = cam.new_x + 140*dt
  end
  if y < move_range then
    cam.new_y = cam.new_y - 140*dt
  elseif y > h - move_range then
    cam.new_y = cam.new_y + 140*dt
  end
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
  if object.item and object.item.visible and object.item.x and object.item.y then
    x = object.item.x
    y = object.item.y
  end
  cam.new_x = math.floor((x+.5)*tile_size)
  cam.new_y = math.floor((y+.5)*tile_size)
end

camera.get_offset = function()
  local w, h = window.get_dimensions()
  local cam = camera.get()
  return math.ceil(-cam.x-cam.x_offset+w/2), math.ceil(-cam.y-cam.y_offset+h/2)
end

camera.shake = function(mag, t)
  shake.mag = mag
  shake.t = t
end

camera.indicator = function(type, x, y, color)
  local tile_x = math.floor((x+.5)*tile_size)
  local tile_y = math.floor((y+.5)*tile_size)
  local x_dif = tile_x-cam.x
  local y_dif = tile_y-cam.y
  local x_mag = math.abs(x_dif)
  local y_mag = math.abs(y_dif)
  local window_w, window_h = window.get_dimensions()
  local w = window_w/2-24
  local h = window_h/2-24
  if x_mag > w or y_mag > h then
    local window_angle = math.atan2(h, w)
    local angle = math.atan2(y_dif, x_dif)
    local x, y = 0, 0
    if (angle < window_angle and angle > -window_angle) or angle > math.pi-window_angle or angle < -math.pi+window_angle then
      x = w * x_dif/x_mag
      y = math.tan(angle) * x
    else
      y = h * y_dif/y_mag
      x = y / math.tan(angle)
    end
    love.graphics.setColor(palette[color][2])
    love.graphics.draw(art.img.indicator_icons, art.quad.indicator_icon[type], math.floor(window_w/2+x), math.floor(window_h/2+y), 0, 1, 1, 12, 12)
    love.graphics.draw(art.img.indicator_arrow, math.floor(window_w/2+x), math.floor(window_h/2+y), angle, 1, 1, -14, 4)
    love.graphics.setColor(1, 1, 1)
  end
end

return camera
