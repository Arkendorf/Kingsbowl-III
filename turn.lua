local char = require "char"

local turn = {}

local turn_time = 3
local step_time = .5
local timer = turn_time
local resolve = false
local step = 0
local max_step = 0

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
          turn.complete()
          network.server_send("complete")
        else
          local new_step = step+1
          turn.new_step(new_step)
          network.server_send("new_step", new_step)
        end
      else
        local step_num = char.step_num()
        turn.resolve(step_num)
        network.server_send("resolve", step_num)
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

  char.finish(step - 1)
  char.prepare(step, step_time)
end

turn.complete = function()
  resolve = false
  timer = turn_time
  char.end_resolve(step)
end

turn.resolve = function(step_num)
  max_step = step_num
  resolve = true
  turn.new_step(1)
  char.start_resolve()
end

return turn
