local window = {w = 400, h = 300, scale = 2}

window.load = function()
  love.window.setFullscreen(true)
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
