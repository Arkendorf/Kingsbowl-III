local window = require "window"

local broadcast = {}

local max = 6
local buffer = 4
local list = {}
local canvas = false
local leave_t = 6
local garbage_t = 8

broadcast.load = function()
  list = {}

  local w, h = window.get_dimensions()
  canvas = love.graphics.newCanvas(window.get_dimensions())
end

broadcast.update = function(dt)
  for i, v in ipairs(list) do
    v.t = v.t + dt
    v.y = v.y + (i*font:getHeight()-v.y) * dt * 4
    if i > max or v.t > leave_t then
      v.x = v.x - (v.w+buffer+1-v.x) * dt * 4
      if (v.x+v.w+buffer) <= 0.1 or v.t > garbage_t then
        table.remove(list, i)
      end
    else
      v.x = v.x - v.x * dt * 4
    end
  end
end

broadcast.draw = function()
  love.graphics.setCanvas(canvas)
  love.graphics.clear()
  local w, h = window.get_dimensions()
  for i, v in ipairs(list) do
    love.graphics.setColor(colors[v.color])
    love.graphics.print(v.txt, buffer+v.x, h-math.floor(v.y)-buffer)
  end
  love.graphics.setColor(1, 1, 1)
  love.graphics.setCanvas(window.canvas)
  love.graphics.draw(canvas, 0, 0)
end

broadcast.new = function(txt, color)
  local w = font:getWidth(txt)
  table.insert(list, 1, {txt = txt, color = color, x = -w-buffer, y = 0, w = w, t = 0})
end

return broadcast
