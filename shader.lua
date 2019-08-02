local shader = {}

shader.load = function()
end

shader.prepare = {}

shader.prepare.outline = function(img)
  shader.outline:send("w", img:getWidth())
  shader.outline:send("h", img:getHeight())
end
shader.outline = love.graphics.newShader[[
    extern number w;
    extern number h;
    vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords){
      vec4 pixel = Texel(texture, texture_coords);
      if (pixel.a == 1) {
        vec4 test = Texel(texture, vec2(texture_coords.x+1.0/w, texture_coords.y));
        if (test.a < 1.0) {
          return color;
        }
        test = Texel(texture, vec2(texture_coords.x, texture_coords.y+1.0/h));
        if (test.a < 1.0) {
          return color;
        }
        test = Texel(texture, vec2(texture_coords.x-1.0/w, texture_coords.y));
        if (test.a < 1.0) {
          return color;
        }
        test = Texel(texture, vec2(texture_coords.x, texture_coords.y-1.0/h));
        if (test.a < 1.0) {
          return color;
        }
      }
      else {
        vec4 test = Texel(texture, vec2(texture_coords.x+1.0/w, texture_coords.y));
        if (test.a > 0.0) {
          return color;
        }
        test = Texel(texture, vec2(texture_coords.x, texture_coords.y+1.0/h));
        if (test.a > 0.0) {
          return color;
        }
        test = Texel(texture, vec2(texture_coords.x-1.0/w, texture_coords.y));
        if (test.a > 0.0) {
          return color;
        }
        test = Texel(texture, vec2(texture_coords.x, texture_coords.y-1.0/h));
        if (test.a > 0.0) {
          return color;
        }
      }
      return vec4(0.0, 0.0, 0.0, 0.0);
    }
  ]]

  shader.prepare.color = function(img, data)
    for i, v in ipairs(data) do
      if i <= 5 then
        if v[4] then
          shader.color:send("color"..tostring(i), v)
        else
          shader.color:send("color"..tostring(i), {v[1], v[2], v[3], 1})
        end
      else
        break
      end
    end
  end
  shader.color = love.graphics.newShader[[
      extern vec4 color1;
      extern vec4 color2;
      extern vec4 color3;
      extern vec4 color4;
      extern vec4 color5;
      vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords){
        vec4 pixel = Texel(texture, texture_coords);
        if (pixel.a == 1) {
          if (pixel.r > .9) {
            return color1;
          }
          if (pixel.r > .7) {
            return color2;
          }
          if (pixel.r > .5) {
            return color3;
          }
          if (pixel.r > .3) {
            return color4;
          }
          if (pixel.r > .1) {
            return color5;
          }
        }
        return vec4(0.0, 0.0, 0.0, 0.0);
      }
    ]]

return shader
