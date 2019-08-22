local preview = {}

local icons = {}
local paths = {}
local path_order = {}
local border = false

local icon_tier = {
  1,
  2,
  3,
  4,
  5,
  6,
  7,
  8,
  9,
}

local color_tier = {
  green = 1,
  white = 2,
  red = 3,
}

local icon_cutoff = 1

preview.load = function()
  preview.clear()
end

preview.draw_bottom = function()
  if border then
    preview.draw_border()
  end
  for k, v in pairs(icons) do
    if icon_tier[v.type] <= icon_cutoff and not preview.icon_blocked(v) then
      preview.draw_icon(v)
    end
  end
end

preview.draw_top = function()
  for i, v in ipairs(path_order) do
    preview.draw_path(v, paths[v])
  end
  for k, v in pairs(icons) do
    if icon_tier[v.type] > icon_cutoff and not preview.icon_blocked(v) then
      preview.draw_icon(v)
    end
  end
end

preview.icon_blocked = function(icon)
  for k, v in pairs(icons) do
    if v.x == icon.x and v.y == icon.y then
      if icon_tier[v.type] > icon_tier[icon.type] then
        return true
      elseif icon_tier[v.type] == icon_tier[icon.type] then -- order based on color (hacky I know)
        if color_tier[preview.get_color(v.color)] > color_tier[preview.get_color(icon.color)] then
          return true
        end
      end
    end
  end
  return false
end

preview.add_icon = function(path_id, type, x, y, color)
  icons[#icons+1] = {type = type, x = x, y = y, path_id = path_id, color = color}
end

preview.add_path = function(path_id, steps, x, y, color)
  paths[path_id] = {steps = steps, x = x, y = y, color = color}
  table.insert(path_order, path_id)
  table.sort(path_order, preview.path_sort)
end

preview.path_sort = function(a, b)
  return color_tier[preview.get_color(paths[a].color)] < color_tier[preview.get_color(paths[b].color)]
end

preview.set_border = function(x, y, radius, func, info)
  border = {x = x, y = y, r = radius, func = func, info = info}
end

preview.remove_border = function()
  border = false
end

preview.remove_path = function(path_id)
  paths[path_id] = nil
  for k, v in pairs(icons) do
    if v.path_id == path_id then
      icons[k] = nil
    end
  end
  for i, v in ipairs(path_order) do
    if v == path_id then
      table.remove(path_order, i)
      break
    end
  end
end

preview.draw_icon = function(icon)
  local color = colors[preview.get_color(icon.color)]
  art.draw_img("path_icon_border", icon.x, icon.y, color[1], color[2], color[3])
  art.draw_quad("path_icons", art.quad.path_icon[icon.type], icon.x+8/tile_size, icon.y+8/tile_size, color[1], color[2], color[3])
end

preview.draw_path = function(path_id, path)
  local color = colors[preview.get_color(path.color)]
  if #path.steps > 0 then
    local x_dif = path.steps[1].x - path.x
    local y_dif = path.steps[1].y - path.y
    preview.draw_segment(path_id, path.x+x_dif*.5, path.y+y_dif*.5, path.steps[1].x, path.steps[1].y, color)
    for i, v in ipairs(path.steps) do
      if i < #path.steps then
        preview.draw_segment(path_id, v.x, v.y, path.steps[i+1].x, path.steps[i+1].y, color)
      end
    end
  end
end

preview.draw_segment = function(path_id, x1, y1, x2, y2, color)
  local x_sign, y_sign = 0, 0
  if x2 - x1 == 0 then
    x_sign = 0
  else
    x_sign = (x2-x1)/math.abs(x2-x1)
  end
  if y2 - y1 == 0 then
    y_sign = 0
  else
    y_sign = (y2-y1)/math.abs(y2-y1)
  end
  local icon = false
  for k, v in pairs(icons) do
    if v.x == x1 and v.y == y1 then
      x1 = x1 + .3 * x_sign
      y1 = y1 + .3 * y_sign
    elseif v.x == x2 and v.y == y2 then
      x2 = x2 - .3 * x_sign
      y2 = y2 - .3 * y_sign
      icon = true
    end
  end
  if not icon then
    art.draw_img("path_node", x2, y2, color[1], color[2], color[3])
  end
  art.line(x1+.5, y1+.5, x2+.5, y2+.5, color[1], color[2], color[3])
end

preview.get_color = function(color)
  if color then
    return color
  else
    return "white"
  end
end

preview.clear = function()
  icons = {}
  paths = {}
  path_order = {}
  border = false
end

preview.draw_border = function()
  for y2 = border.y-math.ceil(border.r), border.y+math.ceil(border.r) do
    for x2 = border.x-math.ceil(border.r), border.x+math.ceil(border.r) do
      if border.func(border.x, border.y, x2, y2, border.info) then
        for y = 1, 2 do
          for x = 1, 2 do
            local x_dir = (x-1.5)*2
            local y_dir = (y-1.5)*2
            local hori = border.func(border.x, border.y, x2+x_dir, y2, border.info)
            local vert = border.func(border.x, border.y, x2, y2+y_dir, border.info)
            local diag = border.func(border.x, border.y, x2+x_dir, y2+y_dir, border.info)
            if hori and vert and not diag then
              art.draw_quad("path_outline", art.quad.path_outline[2][y][x], x2+(x-1)*.5, y2+(y-1)*.5, colors.yellow[1], colors.yellow[2], colors.yellow[3])
            elseif hori and not vert then
              art.draw_quad("path_outline", art.quad.path_outline[3][y][x], x2+(x-1)*.5, y2+(y-1)*.5, colors.yellow[1], colors.yellow[2], colors.yellow[3])
            elseif vert and not hori then
              art.draw_quad("path_outline", art.quad.path_outline[4][y][x], x2+(x-1)*.5, y2+(y-1)*.5, colors.yellow[1], colors.yellow[2], colors.yellow[3])
            elseif not diag and not hori and not vert then
              art.draw_quad("path_outline", art.quad.path_outline[1][y][x], x2+(x-1)*.5, y2+(y-1)*.5, colors.yellow[1], colors.yellow[2], colors.yellow[3])
            end
          end
        end
      end
    end
  end
end

return preview
