--[[
	implementation of being a node with discovery and services
--]]
Node = require "node"
Temp = require "temp"
--LCD = require "lcdlite"

require "cord" -- scheduler / fiber library
require "table"
--require "math"

node = Node:new("HeaterRemote")

local tempInited = false

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

function setRoomTemperature(t)
	local neighbors = node:getNeighborsForService("getTemperature")
	cord.new(function()
		for _,ip in pairs(neighbors) do
			resp = node:invokeNeighborService("setRoomTemperature",ip,t)
		end
	end)
end

function cancelRoomTemperature()
	local neighbors = node:getNeighborsForService("setRoomTemperature")
	cord.new(function()
		for _,ip in pairs(neighbors) do
			resp = node:invokeNeighborService("cancelRoomTemperature",ip)
		end
	end)
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

-- enable a shell
sh = require "stormsh"
sh.start()
cord.enter_loop() -- start event/sleep loop
