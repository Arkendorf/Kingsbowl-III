local char = require "char"
local football = require "football"

local turn = {}

local turn_time = 3
local step_time = .5
local timer = turn_time
local resolve = false
local step = 0
local max_step = 0
local down_delay = false

turn.load = function()
  if state == "server" then
  elseif state == "client" then
    client:on("resolve", function(data)
      turn.resolve(data)
    end)
    client:on("new_step", function(data)
      turn.new_step(data)
    end)
    client:on("complete", function()
      turn.complete()
    end)
  end

  timer = turn_time
  resolve = false
end

turn.update = function(dt)
  timer = timer - dt
  if timer < 0 then
    if state == "server" then
      if resolve then
        if step >= max_step then
          turn.complete(max_step)
          network.server_send("complete")
        else
          local new_step = step+1
          turn.new_step(new_step)
          network.server_send("new_step", new_step)
        end
      else
        local step_num = math.max(char.step_num(), football.step_num())
        if step_num > 0 then -- if something is moving, create steps
          turn.resolve(step_num)
          network.server_send("resolve", step_num)
        else -- otherwise, go right back to gathering input
          turn.complete(0)
          network.server_send("complete")
        end
      end
    else
      timer = 0
    end
  end
end

turn.draw = function()
  love.graphics.print(timer)
end

turn.new_step = function(new_step)
  step = new_step
  timer = step_time

  if step > 1  then
    turn.finish(step-1)
  end
  if not down_delay then
    turn.prepare(step, step_time)
  end
end

turn.prepare = function(step, step_time)
  football.prepare(step, step_time)
  char.prepare(step, step_time)
end

turn.finish = function(step)
  football.finish(step)
  if char.finish(step) and not down_delay then
    turn.delay_down()
  end
end

turn.complete = function(step)
  football.finish(step)
  if char.finish(step) and not down_delay then
    turn.delay_down()
  else
    down_delay = false
    resolve = false
    timer = turn_time
    char.end_resolve(step)
  end
end

turn.delay_down = function()
  down_delay = true
  timer = timer + step_time * 3
end

turn.resolve = function(step_num)
  max_step = step_num
  resolve = true
  turn.start_resolve()
  turn.new_step(1)
end

turn.start_resolve = function()
  football.start_resolve()
  char.start_resolve()
end

return turn
