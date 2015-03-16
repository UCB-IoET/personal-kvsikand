require "cord"
sh = require("stormsh")
TEMP = require("temp")
require"svcd"
local contactPinOut = storm.io.D2
local contactPinIn = storm.io.D3
local relayPin = storm.io.D8
local targetTemp = 24
cord.new(function()
	temp = TEMP:new()
	temp:init() 
end)

function updateHeaterState()
	cord.new( function()
		local contacted = getContact()
		print("updating heater state:")
		print(contacted)
		--logic
		if(contacted and temp:getTemp() < targetTemp) then
			setHeater(1)
		else
			setHeater(0)
		end
	end)
end

function getContact()
	return (storm.io.get(contactPinIn) == storm.io.HIGH)
end

function initContactSensor()
	storm.io.set_mode(storm.io.OUTPUT, contactPinOut)
	storm.io.set_mode(storm.io.INPUT, contactPinIn)
	storm.io.set_pull(storm.io.PULL_DOWN, contactPinIn)
	storm.io.set(storm.io.HIGH,contactPinOut)
	storm.io.watch_all(storm.io.CHANGE, contactPinIn, updateHeaterState)
	storm.os.invokePeriodically(3*storm.os.SECOND, updateHeaterState)
end

function setTargetTemperature(target)
	targetTemp = target
end

function setHeater(state)
	--turn heater on and off
	if(state == 1) then
	  storm.io.set(storm.io.HIGH, relayPin)
	else
	  storm.io.set(storm.io.LOW, relayPin)
	end
end

storm.io.set_mode(storm.io.OUTPUT, relayPin)

storm.n.svcd_init("footHeater", function () print("Looking for services") end)

sh.start()
cord.enter_loop()
