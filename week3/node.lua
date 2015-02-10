--[[
	implementation of being a Node with discovery and services
--]]
require "storm"
require "cord" -- scheduler / fiber library
require "string"

local Node = {}


function Node:new(node_id, announcePort, invokePort, beaconingRate) 
	obj = { announcePort = announcePort or 1525,
			invokePort = invokePort or 1526,
			beaconingRate = beaconingRate or 1000,
			_serviceTable = {id=node_id or "A Really Cool Node"},
			_neighborTable = {} }
	setmetatable(obj, self)
	self.__index = self
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
			self:addNeighbor(storm.mp.unpack(payload), from)
		end)
end

function Node:announceLoop()
	storm.os.invokePeriodically(self.beaconingRate*storm.os.MILLISECOND, function()
		local svc_manifest = self:getServiceTable()
		svc_manifest.t=storm.os.now(storm.os.SHIFT_16)
		storm.net.sendto(self.announceSocket, storm.mp.pack(svc_manifest), "ff02::1", self.announcePort)
	end)
end

function Node:invokeListener() 
	print("starting to listen for invocations")
	self.invokeSocket = storm.net.udpsocket(self.invokePort, 
		function(payload, from, port)
			cord.new(function()
				print (string.format("invoke from %s port %d: %s",from,port,payload))
				local cmd = storm.mp.unpack(payload)
				cmd[1]unpack(cmd[2]) do
					cmdStr = cmdStr .. "," .. item
				end
				cmdStr = cmdStr .. ")"
				loadstring(cmdStr)
			end)
		end)
end

function Node:addService(name, s, desc)
	self._serviceTable[name] = {s = s, desc = desc}
end

function Node:getServiceTable()
	return self._serviceTable
end

function Node:addNeighbor(announcementTable, ipaddr)
	--local timeDelta = storm.os.now(storm.os.SHIFT_16) - announcementTable.t
	for k,v in pairs(announcementTable) do
		if (k ~= "id" and k ~= "t")  then
			if (self._neighborTable[k] == nil) then
				self._neighborTable[k] =  {}
			end
			v.id = announcementTable.id
			self._neighborTable[k][ipaddr] = v
		end
	end
end

function Node:printTable(level, value)
	if (type(value) == "table") then
		level = level or 1
		local returnString = "\n"
		for k,v in pairs(value) do
			returnString = returnString .. string.format("%s %s : %s\n", string.rep("\t",level), k, self:printTable(v))
		end
		return returnString
	elseif(value ~= nil) then
		return string.format("%s", value)
	else
		return ""
	end
end

return Node