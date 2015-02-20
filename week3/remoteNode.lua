--[[
	implementation of being a node with discovery and services
--]]
Node = require "node"
Temp = require "temp"
Button = require "button"
--LCD = require "lcdlite"

require "cord" -- scheduler / fiber library
require "table"
--require "math"

node = Node:new("Heater Controller")

local desiredTemp

function initTempSensor()
	temp = Temp:new()
	cord.new(function() 
		tempInited = temp:init()
	end)
end

function getTemperature()
	if(tempInited) then
		return temp:getTemp()
	end
end

function setTargetTemp(t)
	targetTemp = t
	if not tempMonitorHandle then
		print("starting monitor")
		tempMonitorHandle = storm.os.invokePeriodically(10*storm.os.SECOND, monitorTemperature)
	end
end


function incrementTargetTemp(amt)
	desiredTemp = desiredTemp + amt
	ips = node:getNeighborsForService("setRoomTemperature")
	if(ips ~= {}) then
		node:invokeNeighborService("setRoomTemperature", ips[1], desiredTemp)
	end
end


btn1 = Button:new("D1")
btn3 = Button:new("D3")

btn1:whenever("RISING", function() incrementTargetTemp(1) end);
btn3:whenever("RISING", function() incrementTargetTemp(-1) end);

node:addService("initTempSensor","getBool","initialize temp sensor", initTempSensor)
node:addService("getTemperature","getNumber","get temperature from sensor", getTemperature)
-- enable a shell
sh = require "stormsh"
sh.start()
cord.enter_loop() -- start event/sleep loop
