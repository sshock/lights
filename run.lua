fps = 40
oneTimeWait = 0

-- The default function for LOVE 11.0, tweaked as follows:
-- 1. Remove the sleep(0.001)
-- 2. Adjust speed dynamically based on desired fps.
function love.run()
	if love.load then love.load(love.arg.parseGameArguments(arg), arg) end
 
	-- We don't want the first frame's dt to include time taken by love.load.
	if love.timer then love.timer.step() end
 
	local dt = 0
 
	-- Main loop time.
	return function()
    local start_time = love.timer.getTime()

		-- Process events.
		if love.event then
			love.event.pump()
			for name, a,b,c,d,e,f in love.event.poll() do
				if name == "quit" then
					if not love.quit or not love.quit() then
						return a or 0
					end
				end
				love.handlers[name](a,b,c,d,e,f)
			end
		end
 
		-- Update dt, as we'll be passing it to update
		if love.timer then dt = love.timer.step() end
 
		-- Call update and draw
		if love.update then love.update(dt) end -- will pass 0 if love.timer is disabled
 
		if love.graphics and love.graphics.isActive() then
			love.graphics.origin()
			love.graphics.clear(love.graphics.getBackgroundColor())
 
			if love.draw then love.draw() end
 
			love.graphics.present()
		end
 
    -- Sleep till the end of the frame time.
    local frame_time = 1.0 / fps
    local elapsed_time = love.timer.getTime() - start_time
    if elapsed_time < frame_time then love.timer.sleep(frame_time - elapsed_time) end

    -- Handle one-time wait
    if oneTimeWait > 0 then love.timer.sleep(oneTimeWait) end
    oneTimeWait = 0
	end
end
