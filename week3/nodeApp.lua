--[[
	implementation of being a node with discovery and services
--]]
require "node"
require "cord" -- scheduler / fiber library


ipaddr = storm.os.getipaddr()
print("")
print("ip addr", ipaddr)
print("node id", storm.os.nodeid())

node.announceListener()			-- every node runs the announcement protocol

node.invokeListener()			-- every node runs the invocation protocol

-- enable a shell
sh = require "stormsh"
sh.start()
cord.enter_loop() -- start event/sleep loop
