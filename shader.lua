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
      return vec4(0.0, 0.0, 0.0, 0.0);
    }
  ]]

return shader
