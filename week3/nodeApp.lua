--[[
	implementation of being a node with discovery and services
--]]
Node = require "node"
require "cord" -- scheduler / fiber library


ipaddr = storm.os.getipaddr()
print("")
print("ip addr", ipaddr)
print("node id", storm.os.nodeid())


node = Node:new(1525,1526,1000)

-- enable a shell
sh = require "stormsh"
sh.start()
cord.enter_loop() -- start event/sleep loop
