d = require "display"
shield = require("starter")
--Node = require "node"
Temp = require "temp"

actual =  0 -- average room temp retrieved from the heater
temp_d0 = 8 -- target temp digit 0
temp_d1 = 0 -- target temp digit 1

--------------------------------------------------------------------------------
-- board temp service

--[[ not enough memory

function initTempSensor()
	temp = Temp:new()
	cord.new(function()
		tempInited = temp:init()
		Node:addService("getTemperature","getNumber","get temperature from sensor", getBoardTemp)
	end)
end

function getBoardTemp()
	if(tempInited) then
		return temp:getTemp()
	end
end

Node:addService("initTempSensor","getBool","initialize temp sensor", initTempSensor)
--]]
--------------------------------------------------------------------------------
-- target temperature setting and display

function display_temp()
   d:num(actual*100 + temp_d1 * 10 + temp_d0)
end

function increase_d0(button, mode)
   temp_d0 = (temp_d0 + 1) % 10
   display_temp()
end

function increase_d1(button, mode)
   temp_d1 = (temp_d1 + 1) % 10
   display_temp()
end

shield.Button.start()

shield.Button.whenever(1, "FALLING", increase_d0)
shield.Button.whenever(3, "FALLING", increase_d1)

d:init()
display_temp()

--shield.LED.start()

-----------------------------
sh = require "stormsh"
sh.start()
cord.enter_loop()
