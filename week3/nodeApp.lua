--[[
	implementation of being a node with discovery and services
--]]
Node = require "node"
require "cord" -- scheduler / fiber library


ipaddr = storm.os.getipaddr()
print("")
print("ip addr", ipaddr)
print("node id", storm.os.nodeid())


node = Node:new("jackofAllTrades")
node:addService("setLight","setBool","Turn on a light", setLight);
node:addService("printOut","setString","Print to console", print);

setLight = function(onoff)
	local str = ""
	if onoff then
		str = "on"
	else
		str = "off"
	end
	print("Light is turned " .. str)
end

printToNeighbor = function(string)
	local services = node:getNeighborServices()
	local neighbors = node:getNeighborsForService("printOut")
	for k,v in pairs(neighbors) do
		node:invokeNeighborService("printOut", v, string)
	end
end

-- enable a shell
sh = require "stormsh"
sh.start()
cord.enter_loop() -- start event/sleep loop
