d = require "display"
shield = require("starter")

actual = 58
temp_d0 = 8
temp_d1 = 0

function display_temp()
   d:num(actual*100 + temp_d1 * 10 + temp_d0)
end

function increase_d0(button, mode)
   temp_d0 = (temp_d0 + 1) % 10
   display_temp()
end

function increase_d1(button, mode)
   temp_d1 = (temp_d1 + 1) % 10
   display_temp()
end

shield.Button.start()

shield.Button.whenever(1, "FALLING", increase_d0)
shield.Button.whenever(3, "FALLING", increase_d1)

shield.LED.start()

d:init()
display_temp()

sh = require "stormsh"
sh.start()
cord.enter_loop()
