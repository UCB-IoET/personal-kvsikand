----------------------------------------------
-- Starter Shield Module
--
-- Provides a module for each resource on the starter shield
-- in a cord-based concurrency model
-- and mapping to lower level abstraction provided
-- by storm.io @ toolchains/storm_elua/src/platform/storm/libstorm.c
----------------------------------------------

require("storm") -- libraries for interfacing with the board and kernel
require("cord") -- scheduler / fiber library
----------------------------------------------
-- Shield module for starter shield
----------------------------------------------
local shield = {}

----------------------------------------------
-- LED module
-- provide basic LED functions
----------------------------------------------
local LED = {}

LED.pins = {["blue"]="D2",["green"]="D3",["red"]="D4",["red2"]="D5"}

LED.start = function()
-- configure LED pins for output
   storm.io.set_mode(storm.io.OUTPUT, storm.io.D2,
		     storm.io.D3,
		     storm.io.D4,
		     storm.io.D5)
end

LED.stop = function()
-- configure pins to a low power state
   storm.io.set(0,storm.io.D2,storm.io.D3,storm.io.D4,storm.io.D5)
end

-- LED color functions
-- These should rarely be used as an active LED burns a lot of power
LED.on = function(color)
   storm.io.set(1,storm.io[LED.pins[color]])
end
LED.off = function(color)
   storm.io.set(0,storm.io[LED.pins[color]])
end

-- Flash an LED pin for a period of time
--    unspecified duration is default of 10 ms
--    this is dull for green, but bright for read and blue
--    assumes cord.enter_loop() is in effect to schedule filaments
LED.flash=function(color,duration)
    duration = duration or 10
    
    LED.on(color)
    storm.os.invokeLater(duration*storm.os.MILLISECOND, function() LED.off(color) end)
end

----------------------------------------------
-- Buzz module
-- provide basic buzzer functions
----------------------------------------------
local Buzz = {}

Buzz.pin = "D6"

Buzz.go = function(delay)
	delay = delay or 0
	storm.io.set_mode(storm.io.OUTPUT,storm.io[Buzz.pin])
	storm.io.set(1,storm.io[Buzz.pin]);
	
	--return storm.os.invokeLater(delay*storm.os.MILLISECOND, function() storm.io.set(1, storm.io[Buzz.pin]) end)
end

Buzz.stop = function()
	storm.io.set(0, storm.io[Buzz.pin])
end

----------------------------------------------
-- Button module
-- provide basic button functions
----------------------------------------------
local Button = {}

Button.buttons = {[1] = "D9", [2] = "D10", [3] = "D11" }

Button.start = function() 
	storm.io.set_mode(storm.io.INPUT, storm.io.D9, storm.io.D10, storm.io.D11)
	storm.io.set_pull(storm.io.PULL_UP, storm.io.D9, storm.io.D10, storm.io.D11)
end

-- Get the current state of the button
-- can be used when poling buttons
Button.pressed = function(button) 
	return storm.io.get(storm.io[Button.buttons[button]]);
end

-------------------
-- Button events
-- each registers a call back on a particular transition of a button
-- valid transitions are:
--   FALLING - when a button is pressed
--   RISING - when it is released
--   CHANGE - either case
-- only one transition can be in effect for a button
-- must be used with cord.enter_loop
-- none of these are debounced.
-------------------

Button.whenever = function(button, transition, action)
	return storm.io.watch_all(transition, storm.io[Button.buttons[button]], action)
end

Button.when = function(button, transition, action)
	return storm.io.watch_single(transition, storm.io[Button.buttons[button]], action)
end

Button.wait = function(button)
	
end

----------------------------------------------
shield.LED = LED
shield.Buzz = Buzz
shield.Button = Button
return shield


