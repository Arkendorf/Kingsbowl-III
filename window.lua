local window = {w = 0, h = 0, scale = 2}

window.load = function()
  love.window.setTitle("Kingsbowl III")
  love.window.setMode(1600, 1200, {fullscreen = false})
  window.w = math.floor(love.graphics.getWidth()/window.scale)
  window.h = math.floor(love.graphics.getHeight()/window.scale)
  window.canvas = love.graphics.newCanvas(window.w, window.h)
end

window.get_dimensions = function()
  return window.w, window.h
end

window.get_mouse = function()
  local x, y = love.mouse.getPosition()
  return x/window.scale, y/window.scale
end

window.draw = function()
  love.graphics.draw(window.canvas, 0, 0, 0, window.scale, window.scale)
end

return window
