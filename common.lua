local common = {}

common.dist = function(x1, y1, x2, y2)
  local x_dif = x2-x1
  local y_dif = y2-y1
  return math.sqrt(x_dif*x_dif+y_dif*y_dif)
end

common.get_path = function(x1, y1, x2, y2)
  local path = {}

  local x_dif = (x2-x1)
  local y_dif = (y2-y1)
  if math.abs(x_dif) >= math.abs(y_dif) then
    local slope = y_dif/x_dif
    for i = 0, x_dif, math.abs(x_dif)/x_dif do
      path[#path+1] = {x = x1+i, y = y1+math.floor(slope*i+.5)}
    end
  else
    local slope = x_dif/y_dif
    for i = 0, y_dif, math.abs(y_dif)/y_dif do
      path[#path+1] = {x = x1+math.floor(slope*i+.5), y = y1+i}
    end
  end

  return path
end

return common
