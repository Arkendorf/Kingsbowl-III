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
  for i = 1, 5 do
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
  for i = 1, 2 do
    art.quad.tiles[i] = love.graphics.newQuad((i-1)*tile_size, 0, tile_size, tile_size, art.img.tiles:getDimensions())
  end
  art.quad.markings = {}
  for i = 1, 20 do
    art.quad.markings[i] = love.graphics.newQuad((i-1)*tile_size, 0, tile_size, tile_size, art.img.markings:getDimensions())
  end

  colors = {}
  colors.green = {65/255, 255/255, 110/255}
  colors.red = {237/255, 76/255, 64/255}
  colors.yellow = {255/255, 245/255, 64/255}
  colors.white = {250/255, 255/255, 255/255}

  shader.load()
end

art.draw_img = function(img, x, y, r, g, b, shader_type)
  art.set_effects(r, g, b, img, shader_type)
  love.graphics.draw(art.img[img], math.floor(x*tile_size), math.floor(y*tile_size))
  art.clear_effects()
end

art.draw_quad = function(img, quad, x, y, r, g, b, shader_type)
  art.set_effects(r, g, b, img, shader_type)
  love.graphics.draw(art.img[img], quad, math.floor(x*tile_size), math.floor(y*tile_size))
  art.clear_effects()
end

art.set_effects = function(r, g, b, img, shader_type)
  if r and g and b then
    love.graphics.setColor(r, g, b)
    if img and shader_type then
      shader.prepare[shader_type](art.img[img])
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

art.path_icon = function(num, x, y, r, g, b)
  art.draw_img("path_icon_border", x, y, r, g, b)
  art.draw_quad("path_icons", art.quad.path_icon[num], x+8/tile_size, y+8/tile_size, r, g, b)
end

art.path_border = function(x1, y1, dist, func)
  for y2 = y1-math.ceil(dist), y1+math.ceil(dist) do
    for x2 = x1-math.ceil(dist), x1+math.ceil(dist) do
      if func(x1, y1, x2, y2, dist) then
        art.draw_quad("path_icons", art.quad.path_icon[5], x2+8/tile_size, y2+8/tile_size, colors.yellow[1], colors.yellow[2], colors.yellow[3])
        for y = 1, 2 do
          for x = 1, 2 do
            local x_dir = (x-1.5)*2
            local y_dir = (y-1.5)*2
            local hori = func(x1, y1, x2+x_dir, y2, dist)
            local vert = func(x1, y1, x2, y2+y_dir, dist)
            local diag = func(x1, y1, x2+x_dir, y2+y_dir, dist)
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
