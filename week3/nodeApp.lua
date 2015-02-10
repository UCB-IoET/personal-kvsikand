--[[
	implementation of being a node with discovery and services
--]]
Node = require "node"
require "cord" -- scheduler / fiber library


ipaddr = storm.os.getipaddr()
print("")
print("ip addr", ipaddr)
print("node id", storm.os.nodeid())
echoTwo = function(a, b)
	return a, b
end

addition = function(a, b)
	return a + b
end

setLight = function(onoff)
	local str = ""
	if onoff then
		str = "on"
	else
		str = "off"
	end
	print("Light is turned " .. str)
end

addRemote = function(a, b)
	local neighbors = node:getNeighborsForService("addition")
	for k,v in pairs(neighbors) do
		return node:invokeNeighborService("addition", v, a, b)
	end
end

echoTwo = function(a, b)
	local neighbors = node:getNeighborsForService("echoTwo")
	for k,v in pairs(neighbors) do
		node:invokeNeighborService("echoTwo", v, a, b)
	end
end

node = Node:new("jackofAllTrades")
node:addService("setLight","setBool","Turn on a light", setLight)
node:addService("echoTwo","add","Echo back a pair of numbers", echoTwo)
node:addService("addition","add","Add two numbers", addition)
node:addService("printOut","setString","Print to console", print)




printToNeighbor = function(string)
	local neighbors = node:getNeighborsForService("printOut")
	for k,v in pairs(neighbors) do
		node:invokeNeighborService("printOut", v, string)
	end
end

-- enable a shell
sh = require "stormsh"
sh.start()
cord.enter_loop() -- start event/sleep loop
