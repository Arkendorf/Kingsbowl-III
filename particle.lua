local particle = {}

particle.types = {}

particle.types.blood = {
  img = "blood",
  quad = "particle",
  frames = 8,
  speed = 6,
  mode = "linger",
}

particle.types.stuck = {
  img = "stuck",
  quad = "particle",
  frames = 8,
  speed = 24,
  mode = "linger",
}

particle.types.click = {
  img = "click",
  quad = "particle",
  frames = 8,
  speed = 32,
  mode = "vanish",
}

particle.types.catch = {
  img = "catch",
  quad = "particle",
  frames = 8,
  speed = 32,
  mode = "vanish",
}

particle.types.shield = {
  img = "shield_spark",
  quad = "particle",
  frames = 8,
  speed = 32,
  mode = "vanish",
}

particle.types.stab = {
  img = "stab",
  quad = "particle",
  frames = 8,
  speed = 32,
  mode = "vanish",
}

particle.types.confetti = {
  img = "confetti",
  quad = "confetti",
  frames = 18,
  speed = 32,
  mode = "vanish",
}

local list = {}

particle.load = function()
  list = {}
end

particle.update = function(dt)
  for k, v in pairs(list) do
    local info = particle.types[v.type]
    if v.frame <= info.frames then
      v.frame = v.frame + dt * info.speed
    elseif info.mode == "vanish" then
      list[k] = nil
    else
      v.frame = info.frames
    end
  end
end

particle.draw_particle = function(v, info)
  if v.color then
    art.set_effects(colors[v.color][1], colors[v.color][2], colors[v.color][3], info.img, v.shader, v.shader_info)
  else
    art.set_effects(1, 1, 1, info.img, v.shader, v.shader_info)
  end
  art.draw_quad(info.img, art.quad[info.quad][math.min(math.floor(v.frame), info.frames)], v.x, v.y)
  art.clear_effects()
end

particle.draw_bottom = function()
  for k, v in pairs(list) do
    local info = particle.types[v.type]
    if info.mode == "linger" then
      particle.draw_particle(v, info)
    end
  end
end

particle.draw_top = function()
  for k, v in pairs(list) do
    local info = particle.types[v.type]
    if info.mode == "vanish" then
      particle.draw_particle(v, info)
    end
  end
end

particle.add = function(type, x, y, color, shader, shader_info)
  list[#list+1] = {type = type, x = x, y = y, frame = 1, color = color, shader = shader, shader_info = shader_info}
end

particle.clear = function()
  list = {}
end

return particle
