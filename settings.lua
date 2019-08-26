local nui = require "nui"
local window = require "window"
local bitser = require "bitser"
local client_func = require "client"

local settings = {}

local active = false

local screen_w, screen_h = 0, 0
local res_list = {
  {w = 800, h = 600},
  {w = 1024, h = 768},
  {w = 1152, h = 864},
  {w = 1280, h = 720},
  {w = 1280, h = 768},
  {w = 1280, h = 800},
  {w = 1280, h = 960},
  {w = 1280, h = 1024},
  {w = 1360, h = 768},
  {w = 1366, h = 768},
  {w = 1600, h = 900},
  {w = 1600, h = 1024},
  {w = 1600, h = 1200},
  {w = 1680, h = 1050},
  {w = 1920, h = 1080},
  {w = 1920, h = 1200},
  {w = 1920, h = 1440},
  {w = 2048, h = 1536},
  {w = 2560, h = 1440},
  {w = 2560, h = 1600},
}

local wintype_list = {
  {txt = "Windowed", tags = {fullscreen = false}},
  {txt = "Borderless", tags = {borderless = true, fullscreen = true}},
  {txt = "Fullscreen", tags = {fullscreen = true}},
}

local info = {}

settings.load = function()
  nui.hide.all()

  settings.set_gui()
  screen_w, screen_h = love.window.getDesktopDimensions()

  active = true
end

settings.update = function(dt)
  if active then
    local res = res_list[info.res]
    if res.h/res.w == screen_h/screen_w then
      nui.edit.element("settings_menu", "res_txt", "text", tostring(res.w).."x"..tostring(res.h).."*")
    else
      nui.edit.element("settings_menu", "res_txt", "text", tostring(res.w).."x"..tostring(res.h))
    end
    local wintype = wintype_list[info.wintype]
    nui.edit.element("settings_menu", "wintype_txt", "text", wintype.txt)

    if window_change then
      nui.hide.all()
      nui.show.menu("settings_menu")
      nui.show.element("", "settings_leave")
      nui.show.element("", "settings_apply")
    end
  end
end

settings.keypressed = function(key)
  if key == "escape" then
    settings.leave()
  elseif key == "return" then
    settings.apply()
  end
end

settings.set_gui = function()
  local w, h = window.get_dimensions()
  nui.add.menu("settings_menu", "Options and Settings", 2, w/2-96, h/2-128, 192, 256, true)
  nui.add.button("", "settings_leave", w/2-72, h/2+148, 64, 16, {content = "Leave", func = settings.leave})
  nui.add.button("", "settings_apply", w/2+10, h/2+148, 64, 16, {content = "Apply", func = settings.apply})

  nui.add.text("settings_menu", "window_settings", 0, 22, {text= "Window Settings:", w = 192, align = "center"})

  nui.add.text("settings_menu", "wintype_label", 0, 44, {text= "Window Mode:", w = 192, align = "center"})
  nui.add.text("settings_menu", "wintype_txt", 0, 60, {text = "", w = 192, align = "center"})
  nui.add.button("settings_menu", "wintype_descrease", 20, 52, 16, 16, {content = {img = art.img.settings_icons, quad = art.quad.settings_icon[1]}, func = settings.value, args = {"wintype", -1, #wintype_list}})
  nui.add.button("settings_menu", "wintype_increase", 156, 52, 16, 16, {content = {img = art.img.settings_icons, quad = art.quad.settings_icon[2]}, func = settings.value, args = {"wintype", 1, #wintype_list}})

  nui.add.text("settings_menu", "res_label", 0, 82, {text= "Resolution:", w = 192, align = "center"})
  nui.add.text("settings_menu", "res_txt", 0, 98, {text = "", w = 192, align = "center"})
  nui.add.button("settings_menu", "res_descrease", 20, 90, 16, 16, {content = {img = art.img.settings_icons, quad = art.quad.settings_icon[1]}, func = settings.value, args = {"res", -1, #res_list}})
  nui.add.button("settings_menu", "res_increase", 156, 90, 16, 16, {content = {img = art.img.settings_icons, quad = art.quad.settings_icon[2]}, func = settings.value, args = {"res", 1, #res_list}})

  nui.add.text("settings_menu", "scale_label", 20, 120, {text= "Pixel Scale:"})
  nui.add.text("settings_menu", "scale_num", 20, 120, {table = info, index = "scale", w = 152, align = "right"})
  nui.add.slider("settings_menu", "scale_slider", 20, 138, "hori", 152, 12, info, "scale", 1, 4)

  nui.add.text("settings_menu", "network_settings", 0, 160, {text= "Network Settings:", w = 192, align = "center"})

  nui.add.text("settings_menu", "lan_label", 20, 182, {text= "Find Local Games:"})
  nui.add.button("settings_menu", "lan_toggle", 156, 182, 12, 12, {content = "", func = settings.toggle, args = {"lan", true}, func2 = settings.toggle, args2 = {"lan", false}, toggle = true})
  nui.active("settings_menu", "lan_toggle", info.lan)
  settings.toggle({"lan", info.lan})
  nui.add.text("settings_menu", "lan_note", 0, 204, {text= "(For private networks)", w = 192, align = "center"})
end

settings.apply = function()
  local res = res_list[info.res]
  local wintype = wintype_list[info.wintype]
  window.setup(res.w, res.h, info.scale, wintype.tags)
  settings.set_gui()
end

settings.value = function(data)
  info[data[1]] = info[data[1]] + data[2]
  if info[data[1]] < 1 then
    info[data[1]] = data[3]
  elseif info[data[1]] > data[3] then
    info[data[1]] = 1
  end
end

settings.toggle = function(data)
  info[data[1]] = data[2]
  if info[data[1]] then
    nui.edit.element("settings_menu", data[1].."_toggle", "content", art.img.check_icon)
  else
    nui.edit.element("settings_menu", data[1].."_toggle", "content", "")
  end
end

settings.leave = function()
  if active then
    client_func.lan_active(info.lan)

    settings.save()

    nui.remove.menu("settings_menu")
    nui.remove.element("", "settings_leave")
    nui.remove.element("", "settings_apply")
    nui.show.all()
    active = false
  end
end

settings.save = function()
  local data = bitser.dumps(info)
  love.filesystem.write("settings.txt", data)
end

settings.read = function()
  if love.filesystem.getInfo("settings.txt") then
    local file = love.filesystem.read("settings.txt")
    info = bitser.loads(file)
    settings.apply()
  else
    info.wintype = 3
    info.res = 1
    info.scale = 2
    info.lan = true
    settings.apply()
  end
end

return settings
