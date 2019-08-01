local shader = require "shader"

local art = {}

tile_size = 32

art.load = function(dir)
  love.graphics.setLineStyle("rough")
  love.graphics.setLineWidth(2)

  art.img = {}
  local files = love.filesystem.getDirectoryItems(dir)
  for i, v in ipairs(files) do
    local name = string.sub(v, 1, -5)
    art.img[name] = love.graphics.newImage(dir.."/"..v)
  end

  art.quad = {}

  art.quad.item = {}
  for i = 1, 8 do
    art.quad.item[i] = love.graphics.newQuad((i-1)*tile_size, 0, tile_size, tile_size, art.img.sword:getDimensions())
  end

  art.quad.path_icon = {}
  for i = 1, 6 do
    art.quad.path_icon[i] = love.graphics.newQuad((i-1)*tile_size/2, 0, tile_size/2, tile_size/2, art.img.path_icons:getDimensions())
  end

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

  art.quad.tiles = {}
  for i = 1, 4 do
    art.quad.tiles[i] = love.graphics.newQuad((i-1)*tile_size, 0, tile_size, tile_size, art.img.tiles:getDimensions())
  end

  art.quad.markings = {}
  for i = 1, 20 do
    art.quad.markings[i] = love.graphics.newQuad((i-1)*tile_size, 0, tile_size, tile_size, art.img.markings:getDimensions())
  end

  art.quad.field_info = {}
  art.quad.field_info[1] = love.graphics.newQuad(0, 0, art.img.field_info:getWidth(), tile_size, art.img.field_info:getDimensions())
  art.quad.field_info[2] = love.graphics.newQuad(0, tile_size, art.img.field_info:getWidth(), tile_size, art.img.field_info:getDimensions())

  art.quad.scoreboard = {}
  local w = art.img.scoreboard:getWidth()
  local h = art.img.scoreboard:getHeight()
  art.quad.scoreboard[1] = love.graphics.newQuad(0, 0, w/2, h, w, h)
  art.quad.scoreboard[2] = love.graphics.newQuad(w/2, 0, w/2, h, w, h)

  art.quad.ability_icon = {}
  art.quad.ability_icon.move = love.graphics.newQuad(0*tile_size, 0, tile_size, tile_size, art.img.ability_icons:getDimensions())
  art.quad.ability_icon.shield = love.graphics.newQuad(1*tile_size, 0, tile_size, tile_size, art.img.ability_icons:getDimensions())
  art.quad.ability_icon.sword = love.graphics.newQuad(2*tile_size, 0, tile_size, tile_size, art.img.ability_icons:getDimensions())
  art.quad.ability_icon.throw = love.graphics.newQuad(3*tile_size, 0, tile_size, tile_size, art.img.ability_icons:getDimensions())
  art.quad.ability_icon.position = love.graphics.newQuad(4*tile_size, 0, tile_size, tile_size, art.img.ability_icons:getDimensions())
  art.quad.ability_background = {}
  for i = 1, 43 do
    art.quad.ability_background[i] = love.graphics.newQuad((i-1)*44, 0, 44, 44, art.img.ability_background:getDimensions())
  end

  colors = {}
  colors.green = {65/255, 255/255, 110/255}
  colors.red = {237/255, 76/255, 64/255}
  colors.yellow = {255/255, 245/255, 64/255}
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
    "0123456789!?.,:", 1)
  love.graphics.setFont(font)

  shader.load()
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
  love.graphics.draw(art.img.ability_background, art.quad.ability_background[back], x, y)
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
