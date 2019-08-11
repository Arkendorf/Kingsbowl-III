local window = require "window"

local nui = {}

local menus = {}
local elements = {}
local typing = {menu = false, id = false}
local sliding = {menu = false, id = false, offset = 0}

nui.info = {}

nui.info.menu = {
  img = "menu",
  mode = "scaleable",
  types = 2,
  w = 15,
  corner = 7,
  side = 1,
  sections = {}
}

nui.info.title = {
  img = "title",
  mode = "textable",
  types = 1,
  w = 11,
  h = 24,
  edge = 5,
  center = 1,
  sections = {}
}

nui.info.button = {
  img = "button",
  mode = "scaleable",
  types = 3,
  w = 13,
  corner = 6,
  side = 1,
  sections = {}
}

nui.info.textbox = {
  img = "textbox",
  mode = "textable",
  types = 3,
  w = 17,
  h = 24,
  edge = 8,
  center = 1,
  sections = {}
}

nui.info.text = {
  mode = "text"
}

nui.info.slider = {
  img = "slider",
  mode = "slider",
  types = 1,
  w = 24,
  bar_edge = 2,
  bar_center = 1,
  bar_h = 2,
  node_edge = 4,
  node_center = 1,
  node_h = 8,
  sections = {}
}

nui.load = function()
  love.keyboard.setKeyRepeat(true)
  for k, v in pairs(nui.info) do
    nui.quad[v.mode](v)
  end
end

nui.update = function(dt)
  local x, y = window.get_mouse()
  for k, v in pairs(elements) do
    nui.hover[v.element](x, y, v)
    if v.element == "button" then
      nui.update_button(v, dt)
    end
  end
  for k, v in pairs(menus) do
    for l, w in pairs(v.elements) do
      nui.hover[w.element](x, y, w, v)
      if w.element == "button" then
        nui.update_button(w, dt)
      end
    end
  end
  if sliding.id then
    if love.mouse.isDown(1) then
      local slider = nui.get.element(sliding.menu, sliding.id)
      slider.pos = (x-slider.x)*slider.matrix.x+(y-slider.y)*slider.matrix.y-sliding.offset
      local bar_size = slider.size+nui.info.slider.bar_edge*2
      local node_size = slider.node_size+nui.info.slider.node_edge*2
      if slider.pos < 0 then
        slider.pos = 0
      elseif slider.pos+node_size > bar_size then
        slider.pos = bar_size-node_size
      end
      slider.table[slider.index] = math.floor(slider.min + (slider.pos/(bar_size-node_size))*(slider.max-slider.min)+.5)
    else
      sliding.id = false
    end
  end
end

nui.update_button = function(v, dt)
  if v.t then
    if v.t > 0 then
      v.t = v.t - dt
    else
      v.active = false
    end
  end
end

nui.hover = {}

nui.hover.button = function(x, y, button, menu)
  if not button.active then
    if nui.element_collide(x, y, nui.hitbox(button, menu)) and (not menu or nui.element_collide(x, y, menu.x+nui.info.menu.corner, menu.y+nui.info.menu.corner, menu.w, menu.h)) then
      button.type = 3
    else
      button.type = 2
    end
  end
end

nui.hover.textbox = function(x, y, textbox, menu)
  nui.hover.button(x, y, textbox, menu)
end

nui.hover.text = function()
end

nui.hover.slider = function()
end

nui.hitbox = function(element, menu)
  local x = element.x
  local y = element.y-nui.get_scroll(element, menu)
  local w = element.w
  local h = element.h
  local info = nui.info[element.element]
  if info.mode == "scaleable" then
    w = w + info.corner*2
    h = h + info.corner*2
  elseif info.mode == "textable" then
    w = w + info.edge*2
  end
  if menu then
    x = x + menu.x + nui.info.menu.corner
    y = y + menu.y + nui.info.menu.corner
  end
  return x, y, w, h
end

nui.slider_hitbox = function(slider, menu)
  local x, y, w, h = nui.hitbox(slider, menu)
  x = x + slider.pos*slider.matrix.x
  y = y + slider.pos*slider.matrix.y
  w = (slider.node_size+(nui.info.slider.node_edge-nui.info.slider.bar_edge)*2)*slider.matrix.x + slider.w*slider.matrix.y
  h = (slider.node_size+(nui.info.slider.node_edge-nui.info.slider.bar_edge)*2)*slider.matrix.y + slider.h*slider.matrix.x
  return x, y, w, h
end

nui.draw = function()
  for k, v in pairs(menus) do
    if not v.hide then
      love.graphics.setCanvas(v.canvas)
      love.graphics.clear()
      for l, w in pairs(v.elements) do
        nui.draw_element[w.element](w, v)
      end
      love.graphics.setCanvas(window.canvas)
      nui.draw_element.menu(v)
    end
  end
  for k, v in pairs(elements) do
    nui.draw_element[v.element](v)
  end
end

nui.mousepressed = function(x, y, button)
  if typing.id then
    nui.get.element(typing.menu, typing.id).active = false
    typing.id = false
  end
  local click = false
  if button == 1 then
    for k, v in pairs(elements) do
      if nui.pressed[v.element](x, y, k, v, "") then
        click = true
        break
      end
    end
    if not click then
      for k, v in pairs(menus) do
        if not v.hide then
          for l, w in pairs(v.elements) do
            if nui.element_collide(x, y, v.x+nui.info.menu.corner, v.y+nui.info.menu.corner, v.w, v.h) then
              if nui.pressed[w.element](x, y, l, w, k, v) then
                click = true
                break
              end
            end
          end
        end
      end
    end
  end
  return click
end

nui.pressed = {}

nui.pressed.button = function(x, y, id, button, menu_id, menu)
  if nui.element_collide(x, y, nui.hitbox(button, menu)) then
    if button.active then
      button.active = false
      if button.func2 then
        button.func2(button.args2)
      end
    else
      button.active = true
      if not button.toggle then
        button.t = .1
      end
      button.type = 1
      if button.func then
        button.func(button.args)
      end
    end
    return true
  end
  return false
end

nui.pressed.textbox = function(x, y, id, textbox, menu_id, menu)
  if nui.element_collide(x, y, nui.hitbox(textbox, menu)) then
    if textbox.active then
      textbox.active = false
    else
      if typing.id then
        nui.get.element(typing.menu, typing.id).active = false
      end
      textbox.active = true
      textbox.type = 1
      typing.menu = menu_id
      typing.id = id
    end
    return true
  end
  return false
end

nui.pressed.text = function()
end

nui.pressed.slider = function(x, y, id, slider, menu_id, menu)
  if nui.element_collide(x, y, nui.slider_hitbox(slider, menu)) then
    sliding.menu = menu_id
    sliding.id = id
    sliding.offset = (x-slider.x)*slider.matrix.x+(y-slider.y)*slider.matrix.y-slider.pos
    return true
  end
  return false
end

nui.keypressed = function(key)
  if typing.id and key == "backspace" then
    local textbox = nui.get.element(typing.menu, typing.id)
    textbox.table[textbox.index] = string.sub(textbox.table[textbox.index], 1, -2)
  end
end

nui.textinput = function(text)
  if typing.id then
    local textbox = nui.get.element(typing.menu, typing.id)
    local str = textbox.table[textbox.index]
    if font:getWidth(str..text) <= textbox.w then
      textbox.table[textbox.index] = textbox.table[textbox.index]..text
    end
  end
end

nui.get = {}

nui.get.element = function(menu_id, id)
  if menu_id ~= "" and menus[menu_id] then
    return menus[menu_id].elements[id]
  else
    return elements[id]
  end
end

nui.get.menu = function(id)
  return menus[id]
end

nui.element_collide = function(x1, y1, x2, y2, w, h)
  return (x1 > x2 and x1 < x2+w and y1 > y2 and y1 < y2+h)
end

nui.add = {}

nui.add.menu = function(id, title, type, x, y, w, h, scroll_active, color)
  menus[id] = {title = title, type = type, x = x-nui.info.menu.corner, y = y-nui.info.menu.corner, w = w, h = h, elements = {}, scroll = {active = scroll_active, y = 0}, color = color}
  local menu = menus[id]
  menu.canvas = love.graphics.newCanvas(w, h)
  if scroll_active then
    nui.add.slider(id, "scroll", menu.w-nui.info.slider.node_h, 0, "vert", menu.h-nui.info.slider.bar_edge*2, menu.h-nui.info.slider.node_edge*2-.1, menu.scroll, "y", 0, 0)
    menu.elements.scroll.lock = true
  end
end

nui.add.button = function(menu_id, id, x, y, w, h, info) -- content, func, and args, color, toggle
  nui.add.element(menu_id, id, {element = "button", type = 2, x = x-nui.info.button.corner, y = y-nui.info.button.corner, w = w, h = h}, info)
end

nui.add.textbox = function(menu_id, id, x, y, w, table, index, text, color)
  nui.add.element(menu_id, id, {element = "textbox", type = 2, x = x-nui.info.textbox.edge, y = y-6, w = w, h = nui.info.textbox.h, table = table, index = index, color = color, text = text})
end

nui.add.text = function(menu_id, id, x, y, info) -- text, table, index, color
  if info and info.table then
    local str = tostring(info.table[info.index])
    nui.add.element(menu_id, id, {element = "text", x = x, y = y, w = font:getWidth(str), h = font:getHeight()}, info)
  else
    nui.add.element(menu_id, id, {element = "text", x = x, y = y, w = font:getWidth(info.text), h = font:getHeight()}, info)
  end
end

nui.add.slider = function(menu_id, id, x, y, dir, size, node_size, table, index, min, max)
  local matrix = {}
  if dir == "hori" then
    matrix = {x = 1, y = 0}
  else
    matrix = {x = 0, y = 1}
  end
  nui.add.element(menu_id, id, {element = "slider", x = x, y = y, w = size*matrix.x+nui.info.slider.node_h*matrix.y, h = size*matrix.y+nui.info.slider.node_h*matrix.x, dir = dir, size = size, node_size = node_size, pos = 0, table = table, index = index, min = min, max = max, matrix = matrix})
end

nui.add.element = function(menu_id, id, element, info)
  if menu_id ~= "" then
    menus[menu_id].elements[id] = element
    nui.add_info(menus[menu_id].elements[id], info)
    nui.adjust_scroll(menu_id)
  else
    elements[id] = element
    nui.add_info(elements[id], info)
  end
end

nui.add_info = function(element, info)
  if info then
    for k, v in pairs(info) do
      element[k] = v
    end
  end
end

nui.adjust_scroll = function(id)
  local menu = menus[id]
  if menu.scroll.active then
    local max_h = 0
    for k, v in pairs(menu.elements) do
      local x, y, w, h = nui.hitbox(v, menu)
      element_h = y+h-menu.y-nui.info.menu.corner
      if element_h > max_h then
        max_h = element_h
      end
    end
    if max_h > menu.h then
      nui.edit.element(id, "scroll", "node_size", menu.h/max_h*menu.h)
      nui.edit.element(id, "scroll", "max", max_h-menu.h)
    elseif menu.scroll.active then
      menu.scroll.y = 0
      nui.edit.element(id, "scroll", "node_size", menu.h-nui.info.slider.node_edge*2-.1)
      nui.edit.element(id, "scroll", "max", 0)
    end
  end
end

nui.edit = {}

nui.edit.element = function(menu_id, id, index, value)
  local element = nui.get.element(menu_id, id)
  if element then
    element[index] = value
  end
end

nui.edit.menu = function(id, index, value)
  menus[id][index] = value
end

nui.quad = {}

nui.quad.scaleable = function(info)
  local pos_scale = {0, info.corner, info.corner+info.side}
  local size_scale = {info.corner, info.side, info.corner}
  for type = 1, info.types do
    info.sections[type] = {}
    for x = 1, 3 do
      info.sections[type][x] = {}
      for y = 1, 3 do
        info.sections[type][x][y] = nui.create_section(pos_scale[x], pos_scale[y], size_scale[x], size_scale[y], info.img, type, info.w)
      end
    end
  end
end

nui.quad.textable = function(info)
  local pos_scale = {0, info.edge, info.edge+info.center}
  local size_scale = {info.edge, info.center, info.edge}
  for type = 1, info.types do
    info.sections[type] = {}
    for x = 1, 3 do
      info.sections[type][x] = nui.create_section(pos_scale[x], 0, size_scale[x], info.h, info.img, type, info.w)
    end
  end
end

nui.quad.text = function()
end

nui.quad.slider = function(info)
  local bar_pos_scale = {0, info.bar_edge, info.bar_edge+info.bar_center}
  local bar_size_scale = {info.bar_edge, info.bar_center, info.bar_edge}
  local node_pos_scale = {0, info.node_edge, info.node_edge+info.node_center}
  local node_size_scale = {info.node_edge, info.node_center, info.node_edge}
  local hori_node_x = info.bar_edge*2+info.bar_center
  local vert_bar_x = hori_node_x+info.node_edge*2+info.node_center
  local vert_node_x = vert_bar_x+info.bar_h
  for type = 1, info.types do
    info.sections[type] = {hori = {bar = {}, node = {}}, vert = {bar = {}, node = {}}}
    for x = 1, 3 do
      info.sections[type].hori.bar[x] = nui.create_section(bar_pos_scale[x], 0, bar_size_scale[x], info.bar_h, info.img, type, info.w)
      info.sections[type].vert.bar[x] = nui.create_section(vert_bar_x, bar_pos_scale[x], info.bar_h, bar_size_scale[x], info.img, type, info.w)
      info.sections[type].hori.node[x] = nui.create_section(hori_node_x+node_pos_scale[x], 0, node_size_scale[x], info.node_h, info.img, type, info.w)
      info.sections[type].vert.node[x] = nui.create_section(vert_node_x, node_pos_scale[x], info.node_h, node_size_scale[x], info.img, type, info.w)
    end
  end
end

nui.create_section = function(x, y, w, h, img, type, type_w)
  return {x = x, y = y, w = w, h = h, quad = love.graphics.newQuad(x+(type-1)*type_w, y, w, h, art.img[img]:getDimensions())}
end

nui.draw_mode = {}

nui.draw_mode.scaleable = function(info, art_type, x, y, w, h, content, color)
  for section_x, column in ipairs(info.sections[art_type]) do
    for section_y, section in ipairs(column) do
      local section_w = 1
      local x_offset = 0
      if section_x == 2 then
        section_w = w
      elseif section_x > 2 then
        x_offset = w-info.side
      end
      local section_h = 1
      local y_offset = 0
      if section_y == 2 then
        section_h = h
      elseif section_y > 2 then
        y_offset = h-info.side
      end
      love.graphics.draw(art.img[info.img], section.quad, math.floor(x+x_offset+section.x), math.floor(y+y_offset+section.y), 0, math.floor(section_w), math.floor(section_h))
      if color then
        local overlay = info.img.."_overlay"
        art.set_effects(1, 1, 1, overlay, "color", palette[color])
        love.graphics.draw(art.img[overlay], section.quad, math.floor(x+x_offset+section.x), math.floor(y+y_offset+section.y), 0, math.floor(section_w), math.floor(section_h))
        art.clear_effects()
      end
    end
  end
  if content then
    if type(content) == "string" then
      local width, wrap = font:getWrap(content, w)
      local font_h = #wrap * font:getHeight()
      love.graphics.printf(content, x+info.corner, y+info.corner+(h-font_h)/2, w, "center")
    elseif type(content) == "table" then
      local quad_x, quad_y, quad_w, quad_h = content.quad:getViewport()
      love.graphics.draw(content.img, content.quad, math.floor(x+info.corner+(w-quad_w)/2), math.floor(y+info.corner+(h-quad_h)/2))
    else
      love.graphics.draw(content, math.floor(x+info.corner+(w-content:getWidth())/2), math.floor(y+info.corner+(h-content:getHeight())/2))
    end
  end
end

nui.draw_mode.textable = function(info, type, x, y, w, text, color)
  for section_x, section in ipairs(info.sections[type]) do
    local section_w = 1
    local x_offset = 0
    if section_x == 2 then
      section_w = w
    elseif section_x > 2 then
      x_offset = w-info.center
    end
    love.graphics.draw(art.img[info.img], section.quad, math.floor(x+x_offset+section.x), math.floor(y), 0, math.floor(section_w), 1)
    if color then
      local overlay = info.img.."_overlay"
      art.set_effects(1, 1, 1, overlay, "color", palette[color])
      love.graphics.draw(art.img[overlay], section.quad, math.floor(x+x_offset+section.x), math.floor(y), 0, math.floor(section_w), 1)
      art.clear_effects()
    end
  end
  love.graphics.printf(text, x+info.edge, y+6, w, "center")
end

nui.draw_element = {}

nui.draw_element.menu = function(menu)
  nui.draw_mode.scaleable(nui.info.menu, menu.type, menu.x, menu.y, menu.w, menu.h, false, menu.color)
  love.graphics.draw(menu.canvas, math.floor(menu.x+nui.info.menu.corner), math.floor(menu.y+nui.info.menu.corner))
  local font_w = font:getWidth(menu.title)
  nui.draw_mode.textable(nui.info.title, 1, menu.x+math.floor((menu.w-font_w+nui.info.menu.corner)/2), menu.y-nui.info.title.h/2+math.floor(nui.info.menu.corner/2), font_w, menu.title, menu.color)
end

nui.draw_element.button = function(button, menu)
  nui.draw_mode.scaleable(nui.info.button, button.type, button.x, button.y-nui.get_scroll(button, menu), button.w, button.h, button.content, button.color)
end

nui.draw_element.textbox = function(textbox, menu)
  if tostring(textbox.table[textbox.index]) ~= "" then
    nui.draw_mode.textable(nui.info.textbox, textbox.type, textbox.x, textbox.y-nui.get_scroll(textbox, menu), textbox.w, textbox.table[textbox.index], textbox.color)
  else
    nui.draw_mode.textable(nui.info.textbox, textbox.type, textbox.x, textbox.y-nui.get_scroll(textbox, menu), textbox.w, textbox.text, textbox.color)
  end
end

nui.draw_element.text = function(text, menu)
  local str = ""
  if text.table then
    str = tostring(text.table[text.index])
    if text.suffix then
      str = str..text.suffix
    end
  else
    str = text.text
  end
  if text.color then
    love.graphics.setColor(palette[text.color][1])
  end
  if text.w then
    love.graphics.printf(str, math.floor(text.x), math.floor(text.y-nui.get_scroll(text, menu)), math.floor(text.w), text.align)
  else
    love.graphics.print(str, math.floor(text.x), math.floor(text.y-nui.get_scroll(text, menu)))
  end
  love.graphics.setColor(1, 1, 1)
end

nui.draw_element.slider = function(slider, menu)
  local info = nui.info.slider
  local bar_pos_scale = {0, info.bar_edge, info.bar_edge+slider.size-info.bar_center}
  local bar_size_scale = {0, slider.size-1, 0}
  local node_pos_scale = {0, info.node_edge, info.node_edge+slider.node_size-info.node_center}
  local node_size_scale = {0, slider.node_size-1, 0}
  for i = 1, 3 do
    love.graphics.draw(art.img[info.img], info.sections[1][slider.dir].bar[i].quad, math.floor(slider.x+bar_pos_scale[i]*slider.matrix.x+(info.node_h-info.bar_h)/2*slider.matrix.y), math.floor(slider.y+bar_pos_scale[i]*slider.matrix.y+(info.node_h-info.bar_h)/2*slider.matrix.x-nui.get_scroll(slider, menu)), 0, math.floor(1+bar_size_scale[i]*slider.matrix.x), math.floor(1+bar_size_scale[i]*slider.matrix.y))
  end
  for i = 1, 3 do
    love.graphics.draw(art.img[info.img], info.sections[1][slider.dir].node[i].quad, math.floor(slider.x+(slider.pos+node_pos_scale[i])*slider.matrix.x), math.floor(slider.y+(slider.pos+node_pos_scale[i])*slider.matrix.y-nui.get_scroll(slider, menu)), 0, math.floor(1+node_size_scale[i]*slider.matrix.x), math.floor(1+node_size_scale[i]*slider.matrix.y))
  end
end

nui.get_scroll = function(element, menu)
  if not element.lock and menu then
    return menu.scroll.y
  else
    return 0
  end
end

nui.remove = {}

nui.remove.menu = function(id)
  menus[id] = nil
end

nui.remove.element = function(menu_id, id)
  if menu_id ~= "" then
    menus[menu_id].elements[id] = nil
    nui.adjust_scroll(menu_id)
  else
    elements[id] = nil
  end
end

nui.remove.all = function()
  menus = {}
  elements = {}
end

nui.remove.menu_elements = function(menu_id)
  for k, v in pairs(menus[menu_id].elements) do
    if not v.lock then
      menus[menu_id].elements[k] = nil
    end
  end
end

nui.hide_menu = function(id)
  menus[id].hide = true
end

nui.show_menu = function(id)
  menus[id].hide = false
end

return nui
