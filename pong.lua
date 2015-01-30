require("cord")
require("storm")
shield = require("starter")

LEDLocs = {[3] = "red2", [2] = "red", [1] = "green", [0] = "blue"}

Pong = {}

ballLoc=2
ballDir=1
btnClicks = 0
duration=1000
Pong.gameHandle=nil
Pong.btn1Listener=nil
Pong.btn3Listener=nil

updateButtonPresses=function()
        btnClicks = btnClicks + 1
        --print(btnClicks)
        if(btnClicks % 3 == 0) then
                duration = (duration * 2)/3  --crashes if duration is equal to 0 
                storm.os.cancel(Pong.gameHandle)
                Pong.gameHandle = storm.os.invokePeriodically(duration*storm.os.MILLISECOND, updateGame)
        end 
        --print(duration)
end

pressedButton = function(LEDLoc)
	if(LEDLoc == 0 and ballLoc == 0 and ballDir == -1) then
		ballDir = 1
		updateButtonPresses()
	elseif (LEDLoc == 3 and ballLoc == 3 and ballDir == 1) then
		ballDir = -1
		updateButtonPresses()
	end 
end

updateGame = function()
	shield.LED.off(LEDLocs[ballLoc]);
	ballLoc = ballLoc + ballDir
	if(ballLoc < 0 or ballLoc > 3) then
		endGame()
		--print('setting listener')
		shield.Button.when(2, storm.io.RISING, startGame)
		return
	end
	shield.LED.on(LEDLocs[ballLoc]);
end

startGame = function() 
	ballLoc=2 --initial led is D2 
	ballDir=-1 -- "ball" initially moves to direction of D1 
	duration=1000
	shield.LED.start() --sets LED pins as outputs. 
	print('starting game')
	Pong.btn3Listener = shield.Button.whenever(3,storm.io.FALLING, function() pressedButton(3) end);
	Pong.btn1Listener = shield.Button.whenever(1,storm.io.FALLING, function() pressedButton(0) end);
	Pong.gameHandle = storm.os.invokePeriodically(duration*storm.os.MILLISECOND, updateGame)
end

endGame = function()
        if(Pong.gameHandle ~= nil) then
		print('ending game\n');
        	shield.Buzz.go(5)
        	storm.os.invokeLater(500*storm.os.MILLISECOND,shield.Buzz.stop)
		storm.os.cancel(Pong.gameHandle)
        	Pong.gameHandle = nil
		--print('cancelled game\n');
	end
	if(Pong.btn1Listener ~= nil) then
		--print("cancelling listener 1")
        	storm.io.cancel_watch(Pong.btn1Listener)
        	Pong.btn1Listener = nil
		--print("cancelled listener 1")
	end
	if(Pong.btn3Listener ~= nil) then
		--print("cancelling listener 3")
        	storm.io.cancel_watch(Pong.btn3Listener)
        	Pong.btn3Listener = nil
		--print("cancelled listener 3") 
	end
end
--Game starts when button 2 is pressed. 
shield.Button.start();
shield.Button.when(2, storm.io.RISING, startGame)

cord.enter_loop()
