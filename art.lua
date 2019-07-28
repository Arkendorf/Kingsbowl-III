local shader = require "shader"

local art = {}

art.load = function(dir)
  art.img = {}
  local files = love.filesystem.getDirectoryItems(dir)
  for i, v in ipairs(files) do
    local name = string.sub(v, 1, -5)
    art.img[name] = love.graphics.newImage(dir.."/"..v)
  end

  art.quad = {}
  for i = 1, 8 do
    art.quad["item"..tostring(i)] = love.graphics.newQuad((i-1)*tile_size, 0, tile_size, tile_size, art.img.sword:getDimensions())
  end

  shader.load()
end

art.draw_img = function(img, x, y, r, g, b, shader_type)
  art.set_effects(img, r, g, b, shader_type)
  love.graphics.draw(art.img[img], math.floor(x*tile_size), math.floor(y*tile_size))
  art.clear_effects()
end

art.draw_quad = function(img, quad, x, y, r, g, b, shader_type)
  art.set_effects(img, r, g, b, shader_type)
  love.graphics.draw(art.img[img], art.quad[quad], math.floor(x*tile_size), math.floor(y*tile_size))
  art.clear_effects()
end

art.set_effects = function(img, r, g, b, shader_type)
  if r and g and b then
    love.graphics.setColor(r, g, b)
    if shader then
      shader.prepare[shader_type](art.img[img])
      love.graphics.setShader(shader[shader_type])
    end
  end
end

art.clear_effects = function()
  love.graphics.setColor(1, 1, 1)
  love.graphics.setShader()
end

return art
