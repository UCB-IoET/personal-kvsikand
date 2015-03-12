frequency = 500;
require "cord"
sh = require("stormsh")

--storm.io.set_mode(storm.io.OUTPUT, storm.io.D2)
looping = false
loopPin = function()
	looping = not looping
	cord.new(function()
		while(looping) do 
			storm.io.set(storm.io.TOGGLE, storm.io.D2)
		end
	end)
end


sh.start()
cord.enter_loop()