local shader = require "shader"

local art = {}

tile_size = 32

art.load = function(dir)
  love.graphics.setDefaultFilter("nearest", "nearest")
  love.graphics.setLineStyle("rough")
  love.graphics.setLineWidth(2)

  art.img = {}
  art.load_folder(dir)

  art.quad = {}

  art.quad.item = art.set_quad("sword", 8)

  art.quad.path_icon = art.set_quad("path_icons", 6)

  art.quad.tiles = art.set_quad("tiles", 4)

  art.quad.markings = art.set_quad("markings", 20)

  art.quad.scoreboard_overlay = art.set_quad("scoreboard_overlay", 2)

  art.quad.possession = art.set_quad("possession", 2)

  art.quad.ability_icon = art.set_quad("ability_icons", 5)

  art.quad.char_icon = art.set_quad("char_icon", 2)

  art.quad.char = art.set_quad("char", 4, 2)

  art.quad.stat_icon = art.set_quad("stat_icons", 3)

  art.quad.cycle_icon = art.set_quad("cycle_icons", 2)

  art.quad.particle = art.set_quad("blood", 8)

  art.quad.confetti = art.set_quad("confetti", 18)

  art.quad.path_outline = {}
  for tile = 1, 4 do
    art.quad.path_outline[tile] = {}
    for y = 1, 2 do
      art.quad.path_outline[tile][y] = {}
      for x = 1, 2 do
        art.quad.path_outline[tile][y][x] = love.graphics.newQuad((x-1)*tile_size/2+(tile-1)*tile_size, (y-1)*tile_size/2, tile_size/2, tile_size/2, art.img.path_outline:getDimensions())
      end
    end
  end

  colors = {}
  colors.green = {144/255, 204/255, 71/255}
  colors.red = {229/255, 34/255, 66/255}
  colors.yellow = {255/255, 195255, 91/255}
  colors.white = {250/255, 255/255, 255/255}

  local w, h = art.img.palettes:getDimensions()
  local canvas = love.graphics.newCanvas(w, h)
  love.graphics.setCanvas(canvas)
  love.graphics.draw(art.img.palettes)
  love.graphics.setCanvas()
  local data = canvas:newImageData()
  palette = {}
  for x = 1, w do
    palette[x] = {}
    for y = 1, h do
      palette[x][y] = {data:getPixel(x-1, y-1)}
    end
  end

  font = love.graphics.newImageFont("art/font.png",
    " ABCDEFGHIJKLMNOPQRSTUVWXYZ" ..
    "abcdefghijklmnopqrstuvwxyz" ..
    "0123456789!?.,:-*()", 1)
  smallfont = love.graphics.newImageFont("art/smallfont.png",
    " ABCDEFGHIJKLMNOPQRSTUVWXYZ" ..
    "abcdefghijklmnopqrstuvwxyz" ..
    "0123456789!?.,:-*()")
  smallfont_overlay = love.graphics.newImageFont("art/smallfont_overlay.png",
    " ABCDEFGHIJKLMNOPQRSTUVWXYZ" ..
    "abcdefghijklmnopqrstuvwxyz" ..
    "0123456789!?.,:-*()")
  love.graphics.setFont(font)

  shader.load()
end

art.set_quad = function(img, x_num, y_num)
  local w = art.img[img]:getWidth()
  local h = art.img[img]:getHeight()
  local quad_w = math.ceil(w/x_num)
  local quads = {}
  if y_num and y_num > 1 then
    local quad_h = math.ceil(h/y_num)
    for quad_y = 1, y_num do
      quads[quad_y] = {}
      for quad_x = 1, x_num do
        quads[quad_y][quad_x] = love.graphics.newQuad((quad_x-1)*quad_w, (quad_y-1)*quad_h, quad_w, quad_h, w, h)
      end
    end
  else
    for quad_x = 1, x_num do
      quads[quad_x] = love.graphics.newQuad((quad_x-1)*quad_w, 0, quad_w, h, w, h)
    end
  end
  return quads
end

art.load_folder = function(dir)
  local files = love.filesystem.getDirectoryItems(dir)
  for i, v in ipairs(files) do
    local name = string.sub(v, 1, -5)
    local path = dir.."/"..v
    if love.filesystem.getInfo(path).type == "file" then
      art.img[name] = love.graphics.newImage(path)
    elseif love.filesystem.getInfo(path).type == "directory" then
      art.load_folder(path)
    end
  end
end

art.draw_img = function(img, x, y, r, g, b, shader_type, data)
  art.set_effects(r, g, b, img, shader_type, data)
  love.graphics.draw(art.img[img], math.floor(x*tile_size), math.floor(y*tile_size))
  art.clear_effects()
end

art.draw_quad = function(img, quad, x, y, r, g, b, shader_type, data)
  art.set_effects(r, g, b, img, shader_type, data)
  love.graphics.draw(art.img[img], quad, math.floor(x*tile_size), math.floor(y*tile_size))
  art.clear_effects()
end

art.set_effects = function(r, g, b, img, shader_type, data)
  if r and g and b then
    love.graphics.setColor(r, g, b)
    if img and shader_type then
      shader.prepare[shader_type](art.img[img], data)
      love.graphics.setShader(shader[shader_type])
    end
  end
end

art.clear_effects = function()
  love.graphics.setColor(1, 1, 1)
  love.graphics.setShader()
end

art.direction = function(x1, y1, x2, y2)
  local x = x2 - x1 + 1
  local y = y2 - y1 + 1
  local dir = y*3+x+1
  if dir > 5 then
    return dir-1
  else
    return dir
  end
end

art.line = function(x1, y1, x2, y2, r, g, b)
  art.set_effects(r, g, b)
  love.graphics.line(x1*tile_size, y1*tile_size, x2*tile_size, y2*tile_size)
  art.clear_effects()
end

art.rectangle = function(x, y, w, h, r, g, b)
  art.set_effects(r, g, b)
  love.graphics.rectangle("fill", x*tile_size, y*tile_size, w*tile_size, h*tile_size)
  art.clear_effects()
end

art.path_icon = function(num, x, y, r, g, b)
  art.draw_img("path_icon_border", x, y, r, g, b)
  art.draw_quad("path_icons", art.quad.path_icon[num], x+8/tile_size, y+8/tile_size, r, g, b)
end

art.ability_icon = function(type, back, x, y)
  love.graphics.draw(art.img.ability_background, art.quad.ability_background[back], math.floor(x), math.floor(y))
  love.graphics.setColor(colors.white)
  love.graphics.draw(art.img.ability_icons, art.quad.ability_icon[type], x+6, y+6)
  love.graphics.setColor(1, 1, 1)
end

art.path_border = function(x1, y1, radius, func, info)
  for y2 = y1-math.ceil(radius), y1+math.ceil(radius) do
    for x2 = x1-math.ceil(radius), x1+math.ceil(radius) do
      if func(x1, y1, x2, y2, info) then
        art.draw_quad("path_icons", art.quad.path_icon[5], x2+8/tile_size, y2+8/tile_size, colors.yellow[1], colors.yellow[2], colors.yellow[3])
        for y = 1, 2 do
          for x = 1, 2 do
            local x_dir = (x-1.5)*2
            local y_dir = (y-1.5)*2
            local hori = func(x1, y1, x2+x_dir, y2, info)
            local vert = func(x1, y1, x2, y2+y_dir, info)
            local diag = func(x1, y1, x2+x_dir, y2+y_dir, info)
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

return art
