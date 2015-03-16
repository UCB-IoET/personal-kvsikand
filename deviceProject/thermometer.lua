require "cord"
sh = require("stormsh")
require"svcd"
storm.n.svcd_init("thermometer", function()
	SVCD.add_service("RoomTemperature")
	SVCD.add_attribute(0x3005, 0x3540, function() 
		print("set the room temperature")
	end)
	
end)

sh.start()
cord.enter_loop()
