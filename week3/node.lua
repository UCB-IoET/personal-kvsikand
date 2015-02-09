--[[
	implementation of being a node with discovery and services
--]]

require "cord" -- scheduler / fiber library

node = {}

node.announcePort = 1525
node.invokePort = 1526

node.announceListener = function()
   print("starting to listen for announcements")
   announceSocket = storm.net.udpsocket(node.announcePort, 
			       function(payload, from, port)
				  print (string.format("announcement from %s port %d: %s",from,port,payload))
			       end)
end

node.invokeListener = function() 
    print("starting to listen for invocations")
    invokeSocket = storm.net.udpsocket(node.invokePort, 
			    function(payload, from, port)
			       print (string.format("invoke from %s port %d: %s",from,port,payload))
			    end)
end
