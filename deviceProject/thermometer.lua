require "cord"
sh = require("stormsh")
require"svcd"
local room_temp_id = 0x3055
SVCD.init("heater_control",
	  function()
	     --print("SVCD_INIT()")
	     SVCD.add_service(room_temp_id) --"RoomTemperature"
	     SVCD.add_attribute(room_temp_id,
				0x3540,
				function (payload, port, ip)
				   print("set the room temperature")
				end)
	  end)

-- true/false
function use_contact_sensor(on)
   SVCD.write("fe80::212:6d02:0:3039", 0x162e, 0x03e9, on, 500, function ()print("ok.") end)
end

-- 1/0
function set_heater_on(on)
   SVCD.write("fe80::212:6d02:0:3039", 0x0d80, 0x0001, on , 500, function ()print("ok.") end)
end

function set_target_temp(temp)
   SVCD.write("fe80::212:6d02:0:3039", 0x11d7, 0x03e9, temp , 500, function ()print("ok.") end)
end


sh.start()
cord.enter_loop()
