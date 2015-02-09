--[[
	implementation of being a Node with discovery and services
--]]
require "storm"
require "cord" -- scheduler / fiber library

local Node = {}


function Node:new(announcePort, invokePort, beaconingRate) 
	obj = {announcePort = announcePort or 1525,
			invokePort = invokePort or 1526,
			beaconingRate = beaconingRate or 1000}
	setmetatable(obj, self)
	self.__index = self
	obj:setServiceTable({})
	obj:announceListener()
	obj:announceLoop()
	obj:invokeListener()
	return obj
end

function Node:announceListener()
	print(string.format("starting to listen for announcements. Port:%d", self.announcePort))
	self.announceSocket = storm.net.udpsocket(self.announcePort, 
		function(payload, from, port)
			print (string.format("announcement from %s port %d: %s",from,port,payload))
		end)
end

function Node:announceLoop()
	storm.os.invokePeriodically(self.beaconingRate*storm.os.SECOND, function()
		storm.net.sendto(self.announceSocket, self:getPackedTable(), "ff02::1", self.announcePort)
	end)
end

function Node:invokeListener() 
	print("starting to listen for invocations")
	invokeSocket = storm.net.udpsocket(self.invokePort, 
		function(payload, from, port)
			print (string.format("invoke from %s port %d: %s",from,port,payload))
		end)
end

function Node:setServiceTable(table)
	self._serviceTable = table
	self._packedTable = storm.mp.pack(table)
end

function Node:getServiceTable()
	return self._serviceTable
end

function Node:getPackedTable()
	return self._packedTable
end

return Node