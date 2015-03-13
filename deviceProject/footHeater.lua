require "cord"
sh = require("stormsh")
TEMP = require("temp")
local contactPin1 = storm.io.D2
local contactPin2 = storm.io.D3
local targetTemp = 24
local temp = TEMP:new()
temp:init()

storm.os.invokePeriodically(2*storm.os.SECOND, function()
	if(temp:getTemp() > targetTemp) then
		setHeater(0)
	end
end)

function getContact()
	return (storm.io.get(contactPin2) == 0)
end

function contactChanged()
	local contacted = getContact()
	--logic
	if(contacted and temp:getTemp() < targetTemp) then
		setHeater(1)
	elseif not contacted
		setHeater(0)
	end
end

function initContactSensor()
	storm.io.set_mode(storm.io.OUTPUT, contactPin1)
	storm.io.set_mode(storm.io.INPUT, contactPin2)
	storm.io.set_pull(storm.io.INPUT, contactPin2)
	storm.io.set(1,contactPin1)
	storm.io.watch_all(storm.io.CHANGE, contactPin2, contactChanged)
end

function setTargetTemperature(target)
	targetTemp = target
end

function setHeater(state)
	--turn heater on and off (HOW??)
end


sh.start()
cord.enter_loop()