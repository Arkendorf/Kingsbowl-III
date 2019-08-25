local nui = require "nui"
local window = require "window"

local info = {}

local current = 1
local active = false
local color = 9

info.load = function()
  nui.hide.all()

  local w, h = window.get_dimensions()
  nui.add.menu("info_tabs", "Sections", 2, w/2-224, h/2-128, 96, 256, true, color)

  info.sections = {}
  local tab_folders = love.filesystem.getDirectoryItems("info")
  for i = 1, #tab_folders do
    info.sections[i] = {}
    local section = info.sections[i]

    -- title
    local iterator = love.filesystem.lines("info/"..tostring(i).."/title.txt")
    local lines = {}
    for line in iterator do
      lines[#lines+1] = line
    end
    section.tab = lines[1]
    section.title = lines[2]
    nui.add.button("info_tabs", i, 11, 20+(i-1)*32, 64, 16, {content = section.tab, toggle = true, func = info.swap_section, func2 = info.active, args = i, args2 = i, color = color})

    -- content
    section.content = {}
    local j = 1
    while true do
      local path = "info/"..tostring(i).."/"..tostring(j)
      if love.filesystem.getInfo(path..".txt") then
        section.content[j] = {type = "txt", data = love.filesystem.read(path..".txt")}
      elseif love.filesystem.getInfo(path..".png") then
        section.content[j] = {type = "img", data = love.graphics.newImage(path..".png")}
      else
        break
      end
      j = j + 1
    end
    nui.add.menu("info_"..tostring(i), section.title, 2, w/2-96, h/2-128, 320, 256, true, color)
    nui.hide.menu("info_"..tostring(i))
    local y = 20
    for j, v in ipairs(section.content) do
      if v.type == "txt" then
        nui.add.text("info_"..tostring(i), j, 11, y, {text = v.data, w = 298})
        local w, lines = font:getWrap(v.data, 298)
        y = y + font:getHeight(v.data)*#lines
      elseif v.type == "img" then
        nui.add.image("info_"..tostring(i), j, (320-v.data:getWidth())/2, y+4, v.data)
        y = y + v.data:getHeight()+8
      end
    end
  end
  nui.add.button("", "info_leave", w/2-32, h/2+148, 64, 16, {content = "Leave", func = info.leave, color = color})

  current = 1
  info.swap_section(1)
  nui.active("info_tabs", 1, true)
  active = true
end

info.keypressed = function(key)
  if key == "escape" then
    info.leave()
  end
end

info.swap_section = function(num)
  nui.active("info_tabs", current, false)
  nui.hide.menu("info_"..tostring(current))
  nui.show.menu("info_"..tostring(num))
  current = num
end

info.active = function(num)
  nui.active("info_tabs", num, true)
end

info.leave = function()
  if active then
    nui.remove.menu("info_tabs")
    for i, v in ipairs(info.sections) do
      nui.remove.menu("info_"..tostring(i))
    end
    nui.remove.element("", "info_leave")
    nui.show.all()
    active = false
  end
end

return info
