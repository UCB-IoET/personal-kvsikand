--[[
	implementation of being a node with discovery and services
--]]
Node = require "node"
Temp = require "temp"
require "cord" -- scheduler / fiber library
require "table"
--require "math"

ipaddr = storm.os.getipaddr()

node = Node:new("Heater interfaced device")
temp = Temp:new()
local heaterPin = storm.io.D4
local heaterIsOn = false
local TEMP_DELTA = 1
local targetTemp = nil
local tempMonitorHandle = nil

storm.io.set_mode(storm.io.OUTPUT, heaterPin)
storm.io.set(storm.io.LOW, heaterPin)

function initTempSensor()
	return temp:init()
end

function getTemperature()
	return temp:getTemp()
end

function getAverageTemperature()
	--return math.random(20)
	local neighbors = node:getNeighborsForService("getTemperature")
	local readings = storm.array.create(table.getn(neighbors)) --todo: confirm that this works

	if (node:getServiceTable()["getTemperature"]) then
		readings:append(tonumber(node:invokeLocalService("getTemperature")))
	end

	for _,ip in pairs(neighbors) do
		cord.new( function ()
			resp = node:invokeNeighborService("getTemperature", ip)
			if(not Node.isError(resp)) then
				readings:append(tonumber(resp))
			end
		end)
	end

	return readings:sum()/n
end

function heaterOn()
   storm.io.set(storm.io.HIGH, heaterPin)
   heaterIsOn = 1
end

function heaterOff()
   storm.io.set(storm.io.LOW, heaterPin)
   heaterIsOn = 0
end

function setHeater(state)
   if state == 1 then
      heaterOn()
   else
      heaterOff()
   end
end

function monitorTemperature()
	local currentTemp = getAverageTemperature()
	print("temperature: " .. currentTemp)
	if(targetTemp and currentTemp + TEMP_DELTA < targetTemp) then
		if heaterIsOn == false then
			print("turning on heater")
			heaterOn()
		end
	elseif heaterIsOn == true then
		print("turning off heater")
		heaterOff()
	end
end


function setTargetTemp(t)
	targetTemp = t
	if not tempMonitorHandle then
		print("starting monitor")
		tempMonitorHandle = storm.os.invokePeriodically(10*storm.os.SECOND, monitorTemperature)
	end
end

function stopMonitoringTemp()
	if(tempMonitorHandle) then
		storm.os.cancel(tempMonitorHandle)
		tempMonitorHandle = nil
	end
	return true
end

node:addService("initTempSensor","getBool","initialize temp sensor", initTempSensor)
node:addService("getTemperature","getNumber","get temperature from sensor", getTemperature)
node:addService("setHeater","setBool","turn heater on/off", setHeater)
node:addService("setRoomTemperature","setNumber","set target temperature", setTargetTemp)
node:addService("stopMonitoringTemperature","getBool","stop monitoring room temperature", stopMonitoringTemp)

-- enable a shell
sh = require "stormsh"
sh.start()
cord.enter_loop() -- start event/sleep loop
