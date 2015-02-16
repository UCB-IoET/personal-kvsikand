--[[
	implementation of being a node with discovery and services
--]]
Node = require "node"
require "cord" -- scheduler / fiber library
require "table"

ipaddr = storm.os.getipaddr()

node = Node:new("Heater interfaced device")

local heaterPin = storm.io.D4
local heaterIsOn = 0
storm.io.set(storm.io.LOW, heaterPin)

getAverageTemperature = function()

	local neighbors = node:getNeighborsForService("getTemperature")
	local readings = storm.array.create(table.getn(neighbors)) --todo: confirm that this works
	local n = 1

	if(node:getServiceTable()["getTemperature"]) then
		readings:set(n,tonumber(node:invokeLocalService("getTemperature")))
		n = n + 1
	end


	for _,ip in pairs(neighbors) do
		cord.new( function ()
			resp = node:invokeNeighborService("getTemperature", ip)
			if(!Node.isError(resp)) then
				readings:set(n,tonumber(resp))
				n = n + 1
			end
		end)
	end

	--todo: make a native c function to average an array
	local sum=0
	for i=1,readings:length() do
		sum = sum + readings:get(i)
	end
	return sum/n
end

function heaterOn()
   storm.io.set(storm.io.HIGH, heaterPin)
   heaterIsOn = 1;
end

function heaterOff()
   storm.io.set(storm.io.LOW, heaterPin)
   heaterIsOn = 0;
end

function setHeater(state)
   if state == 1 then
      heaterOn()
   else
      heaterOff()
   end
end

function setTargetTemp(temp)
   return nil --TODO
end

node:addService("setHeater","setBool","turn heater on/off", setHeater)
node:addService("setTemp","setNumber","set target temperature", setTargetTemp)

-- enable a shell
sh = require "stormsh"
sh.start()
cord.enter_loop() -- start event/sleep loop
