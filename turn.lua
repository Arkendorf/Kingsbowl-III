local char = require "char"
local football = require "football"
local rules = require "rules"
local results = require "results"
local window = require "window"

local turn = {}

local turn_time = 3
local step_time = .5
local timer = turn_time
local resolve = false
local step = 0
local max_step = 0
local down_delay = false
local max_turns = 200
local turns_left = 0
local hud_canvas = love.graphics.newCanvas(320, 51)

turn.load = function(settings)
  if network_state == "client" then
    client:on("resolve", function(data)
      turn.resolve(data)
    end)
    client:on("new_step", function(data)
      turn.new_step(data)
    end)
    client:on("complete", function(data)
      turn.complete(data)
    end)
    client:on("results", function()
      state = "results"
      results.load(char.get_players(), rules.get_info())
    end)
    client:on('timer', function(data)
      timer = data
    end)
  end

  turn_time = settings.turn_time
  max_turns = settings.max_turns

  timer = turn_time
  resolve = false
  turns_left = max_turns
end

turn.update = function(dt)
  timer = timer - dt
  if timer < 0 then
    if network_state == "server" then
      if resolve then
        if step >= max_step then
          turn.complete(max_step)
          network.server_send("complete", max_step)
          turn.check_end()
        else
          local new_step = step+1
          turn.new_step(new_step)
          network.server_send("new_step", new_step)
        end
      else
        local step_num = math.max(char.step_num(), football.step_num())
        turn.resolve(step_num)
        network.server_send("resolve", step_num)
        if step_num <= 0 then
          turn.check_end()
        end
      end
    else
      timer = 0
    end
  end
end

turn.new_step = function(new_step)
  step = new_step
  timer = step_time

  if step > 1  then
    turn.finish(step-1)
  end
  if not down_delay then
    if turn.prepare(step) then -- returns true if collision has occured, which may alter the amount of steps needed
      max_step = math.max(char.step_num(), football.step_num())
    end
  end
end

turn.prepare = function(step)
  football.prepare(step, step_time)
  return char.prepare(step, step_time, max_step)
end

turn.finish = function(step)
  football.finish(step)
  if not down_delay and char.finish(step, step_time, max_step) then
    turn.delay_down()
    network.server_send("timer", timer)
  end
end

turn.complete = function(step)
  football.finish(step)
  if not down_delay and char.finish(step, step_time, max_step) then
    turn.delay_down()
  else
    down_delay = false
    resolve = false
    timer = turn_time
    char.end_resolve(step, step_time)
    football.end_resolve()
    turn.increment()
  end
end

turn.increment = function()
  if turns_left > 0 then
    turns_left = turns_left - 1
  end
end

turn.check_end = function()
  if turns_left <= 0  then -- and rules.get_score(1) ~= rules.get_score(2)
    network.server_send("results")
    server:update()
    state = "results"
    results.load(char.get_players(), rules.get_info())
  end
end

turn.delay_down = function()
  down_delay = true
  timer = step_time * 3
end

turn.resolve = function(step_num)
  max_step = step_num
  resolve = true
  turn.start_resolve()
  if max_step > 0 then -- if something is moving
    turn.new_step(1)
  else -- if nothing is moving, go right back to input phase
    turn.complete(0)
  end
end

turn.start_resolve = function()
  football.start_resolve()
  char.start_resolve(step_time)
end

turn.draw_hud = function(x, y)
  love.graphics.setCanvas(hud_canvas)
  love.graphics.clear()
  love.graphics.draw(art.img.scoreboard, art.img.scoreboard[rules.get_offense()])
  art.set_effects(1, 1, 1, "scoreboard_overlay", "color", palette[rules.get_color(1)])
  love.graphics.draw(art.img.scoreboard_overlay, art.quad.scoreboard_overlay[1])
  art.set_effects(1, 1, 1, "scoreboard_overlay", "color", palette[rules.get_color(2)])
  love.graphics.draw(art.img.scoreboard_overlay, art.quad.scoreboard_overlay[2], 160, 0)
  art.clear_effects()

  love.graphics.printf(rules.get_score(1), 5, 6, 18, "left")
  love.graphics.printf(rules.get_name(1), 24, 6, 96, "right")
  love.graphics.printf(rules.get_score(2), 297, 6, 18, "right")
  love.graphics.printf(rules.get_name(2), 199, 6, 96, "left")
  love.graphics.printf(turns_left, 132, 6, 34, "left")
  if resolve then
    love.graphics.printf("0", 168, 6, 18, "right")
  else
    love.graphics.printf(math.floor(timer)+1, 168, 6, 18, "right")
  end
  love.graphics.printf(rules.get_play_string(), 108, 33, 102, "center")

  love.graphics.setCanvas(window.canvas)

  local w, h = window.get_dimensions()
  love.graphics.draw(hud_canvas, w/2-art.img.scoreboard:getWidth()/4, 8)
end

turn.get_resolve_time = function()
  local move_dist = char.get_move_dist()
  return step_time*(move_dist.qb+move_dist.offense)/2
end

return turn
