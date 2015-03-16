require "cord"
sh = require("stormsh")
TEMP = require("temp")
require"svcd"
local contactPinOut = storm.io.D2
local contactPinIn = storm.io.D3
local relayPin = storm.io.D8
local targetTemp = 24
local watchHandle = nil
local contactHandle = nil

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
	watchHandle = storm.io.watch_all(storm.io.CHANGE, contactPinIn, updateHeaterState)
	contactHandle = storm.os.invokePeriodically(3*storm.os.SECOND, updateHeaterState)
end

function disableContactSensor()
	if(contactHandle) then
		storm.os.cancel(contactHandle)
	end
	if(watchHandle) then
		storm.os.cancel_watch(watchHandle)
	end
end

function setTargetTemperature(target)
	targetTemp = target
	print(string.format("target temperature: %d",target))
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

SVCD.init("footHeater", function ()
	SVCD.add_service(3456)
	SVCD.add_attribute(3456,1,function (pay,srcip,srcport) 
		print("setting heater state")
		disableContactSensor()
		setHeater(pay)
	end)
	SVCD.add_service(4567)
	SVCD.add_attribute(4567,1001,function(pay, srcip,srcport)
		print("set target temperature")
		print(pay)
		setTargetTemperature(pay)
	end)
	SVCD.add_service(5678)
	SVCD.add_attribute(5678,1001,function(pay, srcip, srcport)
		print("use contact sensor?")
		print(pay)
		if(pay == true and not watchHandle) then
			initContactSensor()
		else
			disableContactSensor()
		end
	end)
end)


sh.start()
cord.enter_loop()
