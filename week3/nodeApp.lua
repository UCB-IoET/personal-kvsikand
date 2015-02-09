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
node:addService("kavansService","Name of my service","Kavans service description")

-- enable a shell
sh = require "stormsh"
sh.start()
cord.enter_loop() -- start event/sleep loop
