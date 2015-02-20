--[[
	implementation of being a node with discovery and services
--]]
Node = require "node"
Temp = require "temp"
--LCD = require "lcdlite"

require "cord" -- scheduler / fiber library
require "table"
--require "math"

node = Node:new("Heater interfaced device")

local heaterPin = storm.io.D4
local heaterIsOn = false
local TEMP_DELTA = 1
local tempInited = false
local targetTemp = nil
local tempMonitorHandle = nil

storm.io.set_mode(storm.io.OUTPUT, heaterPin)
storm.io.set(storm.io.LOW, heaterPin)

function initTempSensor()
	temp = Temp:new()
	cord.new(function() 
		tempInited = temp:init()
		node:addService("getTemperature","getNumber","get temperature from sensor", getTemperature)
	end)
end

function getTemperature()
	if(tempInited) then
		return temp:getTemp()
	end
end

function getAverageTemperature()
	--return math.random(20)
	local neighbors = node:getNeighborsForService("getTemperature")
	local readings = storm.array.create(table.getn(neighbors)) --todo: confirm that this works

	if (node:getServiceTable()["getTemperature"]) then
		if not tempInited then
			node:invokeLocalService("initTempSensor");
		end
		temp = node:invokeLocalService("getTemperature");
		if not node:isError(temp) then
			readings:append(tonumber(temp))
		end
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

function setHeater(state)
   if state == 1 then
	   storm.io.set(storm.io.HIGH, heaterPin)
	   heaterIsOn = 1
   else
   		storm.io.set(storm.io.LOW, heaterPin)
   		heaterIsOn = 0
   end
end

function monitorTemperature()
	local currentTemp = getAverageTemperature()
	print("temperature: " .. currentTemp)
	if(targetTemp and currentTemp + TEMP_DELTA < targetTemp) then
		if heaterIsOn == false then
			print("turning on heater")
			setHeater(1)
		end
	elseif heaterIsOn == true then
		print("turning off heater")
		setHeater(0)
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

--[[function initLCD()
	lcd = LCD:new(storm.i2c.EXT, 0x7c, storm.i2c.EXT, 0xc4)
	cord.new(function()
		lcd:init(1, 1)
		lcd:setCursor(1,0)
	 end)
end

function displayTemp()
	cord.new(function()
		local currentTemp = getTemperature();
		lcd:setCursor(1,0)
		lcd:writeString(string.format("Temp: %d", currentTemp));
	end)
end--]]

node:addService("initTempSensor","getBool","initialize temp sensor", initTempSensor)
node:addService("setHeater","setBool","turn heater on/off", setHeater)
node:addService("setRoomTemperature","setNumber","set target temperature", setTargetTemp)
node:addService("cancelRoomTemperature","getBool","stop monitoring room temperature", stopMonitoringTemp)

-- enable a shell
sh = require "stormsh"
sh.start()
cord.enter_loop() -- start event/sleep loop
