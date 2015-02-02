--[[ 
Class: CS 194/294 IoET
Authors: Robert Bui, Tom McCormick, Kavan Sikand
Title: LED Pong 
Description: Two players use buttons K1 and K3 (K2
starts the game) to "hit a ball" back
and forth from LEDs D1-D4. Each
time a player fails to hit the button when
the ball reaches their LED (K1 = D1, K3 = D4), the
buzzer makes a sound and the score is displayed.
The game starts at 0 points. Player K1 wants to get
to 4 pts, and Player K3 wants to get to -4 pts.]]--

require("cord")
require("storm")
shield = require("starter")

LEDLocs = {[3] = "red2", [2] = "red", [1] = "green", [0] = "blue"}

LEDBlinkers = {[3] = nil, [2] = nil, [1] = nil, [0] = nil}

Pong = {}
ballLoc = 2
startDir = 1
ballDir = 1
score = 0 
winner = 'K3'
btnClicks = 0
duration=1000
Pong.gameHandle=nil
Pong.btn1Listener=nil
Pong.btn3Listener=nil


---  updateButtonPresses --- 
--[[counts the number of times
  game buttons are pressed and 
  increases speed of the game]] --- 
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

--- pressedButton ---
--[[changes direction
of the ball when game
buttons are pressed ]] -- 
pressedButton = function(LEDLoc)
	if(LEDLoc == 0 and ballLoc == 0 and ballDir == -1) then
		ballDir = 1
		updateButtonPresses()
	elseif (LEDLoc == 3 and ballLoc == 3 and ballDir == 1) then
		ballDir = -1
		updateButtonPresses()
	end 
end

---updateGame--- 
--[[ used to update the 
status of game when player 
fails to press button]]--
updateGame = function()
	shield.LED.off(LEDLocs[ballLoc]);
	ballLoc = ballLoc + ballDir
	if(ballLoc < 0) then
		score = score - 1
		winner = 'K3'
		updateScore()
		endGame()
		--print('setting listener')
		shield.Button.when(2, storm.io.RISING, startGame)
		return
	elseif (ballLoc > 3) then 
		score = score + 1
		winner = 'K1'
		updateScore()
		endGame()
		--print('setting listener')
		shield.Button.when(2, storm.io.RISING, startGame)
		return
	end
	shield.LED.on(LEDLocs[ballLoc]);
end

---updateScore---
--[[Displays the score
of the game using the LEDs
when each round ends]]--
updateScore = function()
	if (score == 4) then
		for i = 1, score-1, 1 do
			LEDBlinkers[i] = storm.os.invokePeriodically(500*storm.os.MILLISECOND, function() shield.LED.flash(LEDLocs[i], 250) end);
		end
		LEDBlinkers[0] = storm.os.invokePeriodically(200*storm.os.MILLISECOND, function() shield.LED.flash(LEDLocs[0], 100) end)
	elseif (score == -4) then
		for i = -2, score, -1 do
			LEDBlinkers[i+4] = storm.os.invokePeriodically(500*storm.os.MILLISECOND,function () shield.LED.flash(LEDLocs[i+4], 250) end);
		end
		LEDBlinkers[3] = storm.os.invokePeriodically(200*storm.os.MILLISECOND, function() shield.LED.flash(LEDLocs[3], 100) end) 
	elseif (score == 0) then
		LEDBlinkers[1] = storm.os.invokePeriodically(500*storm.os.MILLISECOND,function() shield.LED.flash(LEDLocs[1], 250) end);
		LEDBlinkers[2] = storm.os.invokePeriodically(500*storm.os.MILLISECOND,function() shield.LED.flash(LEDLocs[2], 250) end);
	elseif (score > 0) then
		for i = 0, score-1, 1 do
			LEDBlinkers[i] = storm.os.invokePeriodically(500*storm.os.MILLISECOND, function() shield.LED.flash(LEDLocs[i], 250) end);
		end
	else
		for i = -1, score, -1 do
			LEDBlinkers[i+4] = storm.os.invokePeriodically(500*storm.os.MILLISECOND,function() shield.LED.flash(LEDLocs[i+4], 250) end);
		end
	end
end 

---startGame---
--[[begins the game]]---
startGame = function() 	
	duration=1000
	startDir= -1 *startDir 
	ballDir = startDir 
	if (ballDir == -1) then 
		ballLoc = 2
	else 
		ballLoc = 1
	end 
	shield.LED.start() 
	for i = 0, 3, 1 do 
		if(LEDBlinkers[i] ~= nil) then
			storm.os.cancel(LEDBlinkers[i])
			LEDBlinkers[i]=nil
		end
		shield.LED.off(LEDLocs[i])
	end
	print('starting game')
	Pong.btn3Listener = shield.Button.whenever(3,storm.io.FALLING, function() pressedButton(3) end);
	Pong.btn1Listener = shield.Button.whenever(1,storm.io.FALLING, function() pressedButton(0) end);
	Pong.gameHandle = storm.os.invokePeriodically(duration*storm.os.MILLISECOND, updateGame)
end

---endGame---
--[[Ends the round and displays 
to console the results of round]]--
endGame = function()
        if(Pong.gameHandle ~= nil) then
		print('ending game')
		print('Score:', score)
		print('Round Winner:',winner,'\n') 
        	if (score == 4 or score == -4) then
			print ('Game Winner:',winner,'\n')
			score = 0;
		end 
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

--Game starts when button 2 is pressed-- 
shield.Button.start();
shield.Button.when(2, storm.io.RISING, startGame)

cord.enter_loop()
