local rules = {}

local offense = 1

rules.load = function()
  possesion = 1
end

rules.get_offense = function()
  return possesion
end

return rules
