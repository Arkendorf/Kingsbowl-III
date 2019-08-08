local gui = {}

local buttons = {}
local textboxes = {}
local textbox = nil

gui.load_graphics = function()
  gui.quad = {}

  gui.quad.menu = {}
  -- for color = 1, 2 do
  --   gui.quad.menu[color] = {}
  --   for y = 1, 3 do
  --     gui.quad.menu[color][y]
  --     for x = 1, 3 do
  --       local w = 7
  --       if x = 2 then
  --         w = 1
  --       end
  --       local h = 7
  --       if y = 2 then
  --         h = 1
  --       end
  --       gui.quad.menu[color][y][x] = love.graphics.newQuad(
  --     end
  --   end
  -- end
end

gui.load = function()
  love.keyboard.setKeyRepeat(true)
end

gui.update = function(dt)
end

gui.draw = function()
  for k, v in pairs(buttons) do
    love.graphics.rectangle("line", v.x, v.y, v.w, v.h)
    love.graphics.print(v.text, v.x, v.y)
  end
  for k, v in pairs(textboxes) do
    love.graphics.rectangle("line", v.x, v.y, v.w, v.h)
    if v.table[v.index] ~= "" then
      love.graphics.print(tostring(v.table[v.index]), v.x, v.y)
    else
      love.graphics.print(v.text, v.x, v.y)
    end
  end
end

gui.mousepressed = function(x, y, button)
  local click_used = false
  for k, v in pairs(buttons) do
    if x >= v.x and x <= v.x+v.w and y >= v.y and y <= v.y+v.h then
      v.func(v.args)
      click_used = true
      textbox = nil
      break
    end
  end
  if not click_used then
    for k, v in pairs(textboxes) do
      if x >= v.x and x <= v.x+v.w and y >= v.y and y <= v.y+v.h then
        textbox = k
        click_used = true
        break
      end
    end
  end
  if not click_used then
    textbox = nil
  end
end

gui.keypressed = function(key)
  if textbox and key == "backspace" then
    textboxes[textbox].table[textboxes[textbox].index] = string.sub(textboxes[textbox].table[textboxes[textbox].index], 1, -2)
  end
end

gui.textinput = function(text)
  if textbox then
    textboxes[textbox].table[textboxes[textbox].index] = textboxes[textbox].table[textboxes[textbox].index]..text
  end
end

gui.new_button = function(id, x, y, w, h, text, func, args)
  buttons[id] = {x = x, y = y, w = w, h = h, text = text, func = func, args = args}
end

gui.edit_button = function(id, item, value)
  if buttons[id] then
    buttons[id][item] = value
  end
end

gui.remove_button = function(id)
  buttons[id] = nil
end

gui.new_textbox = function(id, x, y, w, h, text, table, index)
  textboxes[id] = {x = x, y = y, w = w, h = h, text = text, table = table, index = index}
end

gui.edit_textbox = function(id, item, value)
  if textboxes[id] then
    textboxes[id][item] = value
  end
end

gui.remove_textbox  = function(id)
  textboxes[id] = nil
end

gui.remove_all = function()
  buttons = {}
  textboxes = {}
end

return gui
