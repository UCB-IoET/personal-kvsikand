--[[
	implementation of being a node with discovery and services
--]]

require "cord" -- scheduler / fiber library


ipaddr = storm.os.getipaddr()

print("ip addr", ipaddrs)
print("node id", storm.os.nodeid())

announcePort = 1525
invokePort = 1526

announceListener = function()
   announceSocket = storm.net.udpsocket(announcePort, 
			       function(payload, from, port)
				  print (string.format("announcement from %s port %d: %s",from,port,payload))
			       end)
end

announceListener()			-- every node runs the announcement protocol

invokeListener = function() 
    invokeSocket = storm.net.udpsocket(invokePort, 
			    function(payload, from, port)
			       print (string.format("invoke from %s port %d: %s",from,port,payload))
			    end)
end

invokeListener()			-- every node runs the invokaction protocol

-- enable a shell
sh = require "stormsh"
sh.start()
cord.enter_loop() -- start event/sleep loop
