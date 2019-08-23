local field = require "field"
local rules = require "rules"
local window = require "window"
local football = require "football"

local camera = {}

local cam = {}

local move_range = 16
local move_speed = 2.5

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
  if x < move_range or love.keyboard.isDown("a") or love.keyboard.isDown("left") then
    cam.new_x = cam.new_x - move_speed
  elseif x > w - move_range or love.keyboard.isDown("d") or love.keyboard.isDown("right") then
    cam.new_x = cam.new_x + move_speed
  end
  if y < move_range or love.keyboard.isDown("w") or love.keyboard.isDown("up") then
    cam.new_y = cam.new_y - move_speed
  elseif y > h - move_range or love.keyboard.isDown("s") or love.keyboard.isDown("down") then
    cam.new_y = cam.new_y + move_speed
  end
end

camera.get = function()
  return cam
end

camera.scrimmage = function()
  local scrimmage = rules.get_scrimmage()
  local field_w, field_h = field.get_dimensions()
  camera.set_position((scrimmage+1)*tile_size, (field_h/2)*tile_size)
end

camera.object = function(object)
  local x = object.x
  local y = object.y
  if object.item and object.item.visible and object.item.x and object.item.y then
    x = object.item.x
    y = object.item.y
  end
  camera.set_position(math.floor((x+.5)*tile_size), math.floor((y+.5)*tile_size))
end

camera.set_position = function(x, y)
  cam.new_x = x
  cam.new_y = y
  local w, h = window.get_dimensions()
  if math.abs(cam.new_x-cam.x) > w/2+tile_size or math.abs(cam.new_y-cam.y) > h/2+tile_size then
    cam.x = cam.new_x
    cam.y = cam.new_y
  end
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

camera.indicator = function(icon, type, x, y, color)
  local tile_x = (x+.5)*tile_size
  local tile_y = (y+.5)*tile_size
  local x_dif = math.floor(tile_x-cam.x)
  local y_dif = math.floor(tile_y-cam.y)
  local x_mag = math.abs(x_dif)
  local y_mag = math.abs(y_dif)
  local window_w, window_h = window.get_dimensions()
  local w = window_w/2-26
  local h = window_h/2-26
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
    local x = math.floor(window_w/2+x)
    local y = math.floor(window_h/2+y)
    love.graphics.draw(art.img.indicator_background, art.quad.indicator[type], x, y, 0, 1, 1, 14, 14)
    art.set_effects(1, 1, 1, art.img.indicator_overlay, "color", palette[color])
    love.graphics.draw(art.img.indicator_overlay, art.quad.indicator[type], x, y, 0, 1, 1, 14, 14)
    art.clear_effects()
    love.graphics.draw(art.img.indicator_icons, art.quad.indicator_icon[icon], x+6, y+6, 0, 1, 1, 14, 14)
    love.graphics.draw(art.img.indicator_arrow, x, y, angle, 1, 1, -12, 6)
  end
end

return camera
