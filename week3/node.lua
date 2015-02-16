--[[
	implementation of being a Node with discovery and services
--]]
require "storm"
require "cord" -- scheduler / fiber library
require "string"
require "math"
local Node = {}

function Node:new(node_id, announcePort, invokePort, beaconingRate) 
	obj = { announcePort = announcePort or 1525,
			invokePort = invokePort or 1526,
			beaconingRate = beaconingRate or 1000,
			_serviceTable = {id=node_id or "A Really Cool Node"},
			_localServicesToFunctions = {},
			_remoteServiceTable = {} }
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
			--print (string.format("announcement from %s port %d: %s",from,port,payload))
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
				-- print (string.format("invoke from %s port %d: %s",from,port,payload))
				local cmd = storm.mp.unpack(payload)
				if(cmd[1] and self._localServicesToFunctions[cmd[1]]) then
					local value = self._localServicesToFunctions[cmd[1]](unpack(cmd[2]))
					storm.net.sendto(self.invokeSocket, storm.mp.pack({value}), from, port)
				else
					print (string.format("Error: invoke from %s port %d: %s cmd:%s",from,port,payload, cmd[1]))
					storm.net.sendto(self.invokeSocket, storm.mp.pack({"Service Error"}), from, port)
				end
			end)
		end)
end

--local Stuff
function Node:invokeLocalService(name, ...)
	return self._localServicesToFunctions[name](args)
end

function Node:addService(name, s, desc, funcName)
	self._serviceTable[name] = {s = s, desc = desc}
	self._localServicesToFunctions[name] = funcName
end

function Node:getServiceTable()
	return self._serviceTable
end

--must be run in a new thread
function Node:invokeNeighborService(name, ip, ...)
	local inv_manifest = {}
	local args = {...}
	local neighborEntry = self._remoteServiceTable[name][ip]
	inv_manifest[1] = name
	inv_manifest[2] = args
	local response = nil;
	local invSock = storm.net.udpsocket(math.random(1027,4000),
		function(payload, from, port)
			response = storm.mp.unpack(payload)
		end) 
	storm.net.sendto(invSock, storm.mp.pack(inv_manifest),ip,self.invokePort)
	for iter = 1,20 do
		cord.await(storm.os.invokeLater, 100*storm.os.MILLISECOND)
		if(response ~= nil) then
			storm.net.close(invSock)
			return response
		end
	end
	storm.net.close(invSock)
	print("invokation timeout")
	return nil
end

function Node.isError(v)
   return v == nil;
end

function Node:getRemoteServiceNames()
	local names = {}
	local n = 1
	for k, v in pairs(self._remoteServiceTable) do
		names[n] = k
		n = n + 1
	end
	return names
end

function Node:getNeighborsForService(name)
	if not self._remoteServiceTable[name] then
		return {}
	end
	local ips = {}
	local n = 1
	for k, v in pairs(self._remoteServiceTable[name]) do
		ips[n] = k
		n = n + 1
	end
	return ips
end

function Node:addNeighbor(announcementTable, ipaddr)
	--local timeDelta = storm.os.now(storm.os.SHIFT_16) - announcementTable.t
	for k,v in pairs(announcementTable) do
		if (k ~= "id" and k ~= "t")  then
			if (self._remoteServiceTable[k] == nil) then
				self._remoteServiceTable[k] =  {}
			end
			v.id = announcementTable.id
			self._remoteServiceTable[k][ipaddr] = v
		end
	end
end

function trSetup(ivkid, time, func, args)
   if _scheduledInvocations[ivkid] ~= nil then
      _scheduledInvocations[ivkid] =
	 storm.os.invokeLater(time*storm.os.SHIFT_16, func, unpack(args))
   end
   --return the ivkid as an ack.
   --TODO: how should we be sending the ack?
   return ivkid
end

function trAbort(ivkid)
   if _scheduledInvocations[ivkid] ~= nil then
      storm.os.cancel(_scheduledInvocations[ivkid])
	 _scheduledInvocations[ivkid] = nil
   end
   return ivkid
end

function getnow()
   return storm.os.getNow(storm.os.SHIFT_16)
end

Node:addService("trSetup", "", "setup a transaction", trSetup);
Node:addService("trAbort", "", "setup a transaction", trAbort);
Node:addService("getNow",  "getNumber", "get the local time", getNow);

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