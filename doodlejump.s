#####################################################################
#
# CSCB58 Fall 2020 Assembly Final Project
# University of Toronto, Scarborough
#
# Student: Ava Oveisi, 1006412482
#
# Bitmap Display Configuration:
# - Unit width in pixels: 16
# - Unit height in pixels: 16
# - Display width in pixels: 512
# - Display height in pixels: 512
# - Base Address for Display: 0x10008000 ($gp)
#
# Which milestone is reached in this submission?
# Milestone 1/2/3
# Milestone 4b: Level 1,2,3 was made. Level 1: default game, Level 2: speed increases Level 3: lasers (see video)
# Milestone 4c: dynamic increase in difficulty in level 2 by speed increase
# Milestone 5ci: Rocket suits
# Milestone 5dii: start/gameover/pause screen
# Milestone 5e: notifications
#
# Which approved additional features have been implemented?
# (See the assignment handout for the list of additional features)
# 1. 5ci: rocket suits appear every 2 levels
# 2. 5dii: start/game over/pause screens with cool graphics, blinking and background color change
# 3. 5ei: on screen notifications of WOW and YAY every 2 levels and selected at random
#
# Link to video demonstration for final submission:
# https://play.library.utoronto.ca/c95324b54d1c0526202e6680f36731b4
#
# Any additional information that the TA needs to know:
# - All additional information is in the Video
#
#####################################################################

.data
displayAddress: .word 0x10008000
buffer: .space 4096
#*************COLORS*************
skyColor: 	.word 0x324c5b		#blue
doodlerColor:	.word 0xee4266		#red
platformColor:	.word 0xb5ad64		#green
messageColor: 	.word 0xe6d348		#yellow		score:0x8ba590
laserColor: 	.word 0x1aa7ff
pauseScreenColor: .word 0x480000 	#brown
gameOverScreenColor: .word 0x000000	#black
gameOverMessageColor: .word 0xcc0000	#candy red
rocketColor: 	.word 0x000000
#*************DOODLER POSITION DATA*************
doodlerPos: .word 0			#pos of doodler wrsp to base address
#*************DOODLER MOTION*************
doodlerMotion: .word -1		#-1 for down, 0 for no motion, 1 for up, starts by moving down
pixelArraySize: .word 4096		#size of bytes of screen: 32 pixels * 32 pixels * 4 bytes/pixel
platformWidth:	.word 48		#12 pixels * 4 bytes/pixel = 48
#*************PLATFORM and ROCKET POSITION*************
platformPos:.word 0, 0, 0		#3 platforms in screen pos
rocketPos: .word 0		
#*****START RESTART GAMEOVER PAUSED STATE*******
gameOn: .word	-1			# -4: game is paused
					# -3: start screen of level 3
					# -2: start screen of level 2
					# -1: start screen of level 1
					# 0: game over (for any difficulty show 3 options)
					# 1: game running for level 1
					# 2: game running for level 2
					# 3: game running for level 3
#************SLEEP TIME DEFAULT***********
sleepTime: .word 100
#*************STORE LEVEL**********
level: .word 0
#*************LASER DATA************
laserTopPos: .word 0x10008000
#************SPRING DATA***********
rocketMode: .word 0	# 0 for off
			# 1 for on

.text
main:
#########################################I	NITIAL SETUP	####################################################
setUp:
	#STORE BASE ADDRESS FOR DISPLAY
	la $t0, buffer	#change to buffer, update afterwards with displayAddress 
	#STORE commonly used COLORS in REGISTERS
	lw $t1, skyColor	
	lw $t2, doodlerColor
	lw $t3, platformColor
	lw $t4, messageColor
	lw $t5, laserColor
	lw $t6, rocketColor
	#STORE LEVEL 	
	lw $t6, level
	#STORE POSITIONS 
	la $s0, doodlerPos
	la $s1, platformPos
	#STORE SLEEP TIME
	lw $s2, sleepTime
	#STORE MOTION DIRECTION
	lw $s3, doodlerMotion
	#LEVEL: every 5 level show WOW or YAY
	lw $s6, level	
	#STORE JUMP PIXEL COUNT: max height doodler can jump after hitting platform
	li $s7, 0
	#STORE RETURN VALUE of randomGeneratorForXposOfPlatform or initializeRandomLaserPos
	li $v0, 0
	#STORE RETURN ADDRESS for those overwritten by inner function call	
	move $v1, $ra 
	
	setPlatformInitialPosition:
		#10 pixel between platforms, first one at bottom
		#s1: random value from 0 to (32 - platformWidth) then add to distance from top of screen
		
		addi $t4, $t0, 1152			#platform 1 height: baseheight + 31*128
		jal randomGeneratorForXposOfPlatform	#generate random x pos for platform 1 stored in v0
		add $t4, $t4, $v0			#add to height from top of screen
		sw $t4, 0($s1)				#store in platformPos
		
		addi $t4, $t0, 2560			#platform 2 height: baseheight + (31-11)*128
		jal randomGeneratorForXposOfPlatform	
		add $t4, $t4, $v0
		sw $t4, 4($s1)		

		addi $t4, $t0, 3968			#platform 3 height: baseheight + (31-22)*128
		jal randomGeneratorForXposOfPlatform	
		add $t4, $t4, $v0
		sw $t4, 8($s1)		


	setInitialDoodlerPos:
		li $t4, 2876		#bottom middle of screen (approximate)
		add $t4, $t4, $t0	#add base address to it
		sw $t4, 0($s0)		#store x pos of doodler
	
	#store gameOn
	lw $t5, gameOn
	beq $t5, -1, setUpGameLvl1
	beq $t5, -2, setUpGameLvl2
	beq $t5, -3, setUpGameLvl2
	
	setUpGameLvl1:
		jal drawSky
		jal drawDoodler
		jal drawPlatforms
		lw $t4, messageColor
		jal drawLevel1
		jal drawLevelSign	
		jal initializeRandomRocketPos
		j end6
	setUpGameLvl2:
		jal drawSky
		jal drawDoodler
		jal drawPlatforms
		lw $t4, messageColor
		jal drawLevel2
		jal drawLevelSign
		jal initializeRandomRocketPos
		j end6
	
	setUpGameLvl3:
		jal drawSky
		jal drawDoodler
		jal drawPlatforms
		jal initializeRandomLaserPos
		lw $t4, messageColor
		jal drawLevel3
		jal drawLevelSign
		jal initializeRandomRocketPos
		j end6
	

	end6:
	j run
	
#########################################	RUN PROGRAM	####################################################
run:	
	jal drawBuffer	
	lw $t4, 0xffff0000		#check for keypress
	bne $t4, 1, noKeyPressed 
	
	isKeyPressed:
		lw $t4, 0xffff0004
		beq $t4, 0x73, startOrRestart
		beq $t4, 0x70, paused
		beq $t4, 0x6a, moveLeft
		beq $t4, 0x6b, moveRight
		beq $t4, 0x31, gameLevel1	#1: easy difficulty
		beq $t4, 0x32, gameLevel2	#2: medium difficulty: speed increases each level
		beq $t4, 0x33, gameLevel3	#3: high difficulty: lasers shoot

		j noKeyPressed			#no valid key pressed
	
	#"1" IS PRESSED: go to start screen of level 1
	gameLevel1:
		la $t4, gameOn		#turn gameOn to -1
		li $t6, -1
		sw $t6, 0($t4)
		#draw level 1 sign by first undrawing all level previously drawn
		move $t4, $t1				
		jal drawLevel2
		jal drawLevel3
		jal drawLevelSign
		lw $t4, messageColor
		jal drawLevel1
		jal drawLevelSign
		j noKeyPressed
	#"2" IS PRESSED: go to start screen of level 2
	gameLevel2:
		la $t4, gameOn		#turn gameOn to -2
		li $t6, -2
		sw $t6, 0($t4)
		#draw level 1 sign by first undrawing all level previously drawn
		move $t4, $t1					
		jal drawLevel1
		jal drawLevel3
		jal drawLevelSign
		lw $t4, messageColor
		jal drawLevel2
		jal drawLevelSign
		j noKeyPressed
	#"3" IS PRESSED: go to start screen of level 3
	gameLevel3:
		la $t4, gameOn		#turn gameOn to -3
		li $t6, -3
		sw $t6, 0($t4)
		#draw level 1 sign by first undrawing all level previously drawn
		move $t4, $t1				
		jal drawLevel1
		jal drawLevel2
		jal drawLevelSign
		lw $t4, messageColor
		jal drawLevel3
		jal drawLevelSign
		j noKeyPressed
	
	
	#"S" IS PRESSED: start/restsart
	startOrRestart:	
		la $t4, gameOn			#turn game on if off
		lw $t5, gameOn
		beq $t5, 1, stopGameLvl1		#stop game level 1 if running and go to its set up page
		beq $t5, 2, stopGameLvl2		#same for level 2 
		beq $t5, 3, stopGameLvl3		#same for level 3
		beqz $t5, startGameLvl1		#game over after any level: restart game level 1 always after drawing gameOver screen for 1 sec
		beq $t5, -1, startGameLvl1		#starting game level 1
		beq $t5, -2, startGameLvl2		#starting game level 2
		beq $t5, -3, startGameLvl3		#starting game level 3
		
		
		stopGameLvl1:
			li $t6, -1			
			sw $t6, 0($t4)	#o/w turn game off, setup 		
			j setUp
		stopGameLvl2:
			li $t6, -2
			sw $t6, 0($t4)	#o/w turn game off, setup 		
			j setUp
		stopGameLvl3:
			li $t6, -3
			sw $t6, 0($t4)	#o/w turn game off, setup 		
			j setUp
		startGameLvl1:	#turn gameOn to 1
			li $t6, 1
			sw $t6, 0($t4)
			lw $t1, skyColor
			jal drawSky		#to get rid of game over screen black color
			j noKeyPressed
		startGameLvl2:	#turn gameOn to 2
			li $t6, 2
			sw $t6, 0($t4)
			lw $t1, skyColor
			jal drawSky		#to get rid of game over screen black color
			j noKeyPressed
		startGameLvl3:	#turn gameOn to 3
			li $t6, 3
			sw $t6, 0($t4)
			lw $t1, skyColor
			jal drawSky		#to get rid of game over screen black color
			j noKeyPressed
	
	#"P" IS PRESSED: pause/unpause
	paused:
		la $t4, gameOn
		lw $t5, gameOn
		beq $t5, -4, unpause 		#if game is paused unpause it
		bne $t5, 1, noKeyPressed	#if its neither -4 nor 1 -> do nothing 
			#we are gameOn so turn to gamePaue which is -4 and change to pauseScreenColor
			li $t6, -4
			sw $t6, 0($t4)
			lw $t1, pauseScreenColor #***
			jal drawSky		#***
			jal drawPlatforms
			jal drawDoodler
			j noKeyPressed
		unpause:
			#turn back to gameon and change back to skyColor
			li $t6, 1
			sw $t6, 0($t4)
			lw $t1, skyColor	#***
			jal drawSky
		j noKeyPressed
	
	#"K" IS PRESSED: left
	moveLeft:
		lw $t9, doodlerPos	
		sw $t8, 0($t9)
		addi $t9, $t9, -4	#store right pixel in doodlerPos
		sw $t9, 0($s0)	
		j noKeyPressed
	
	#"J" IS PRESSED: right
	moveRight:
		lw $t9, doodlerPos	
		sw $t8, 0($t9)
		addi $t9, $t9, 4
		sw $t9, 0($s0)		#store left pixel in doodlerPos
		j noKeyPressed
	
	#NO VALID KEY PRESSED: run game based on conditions
	noKeyPressed:
		lw $t5, gameOn			#check if game has not yet started
		beq $t5, 1, runGameLevel1
		beq $t5, 2, runGameLevel2
		beq $t5, 3, runGameLevel3
		beqz $t5, notRestarted
		beq $t5, -1, notStartedScreen	#check if game has not yet restarted and draw game over screen
		beq $t5, -2, notStartedScreen
		beq $t5, -3, notStartedScreen
		beq $t5, -4, notUnpaused	#game is pasused
		
	runGameLevel1:
		jal moveUpDown
		jal drawDoodler
		jal drawPlatforms	#draw platform since doodler might go over them
		#jal drawLaser
		jal sleep
		la $t5, messageColor
		lw $t6, messageColor
		sw $t1, 0($t5) 		#move sky color to message color for undrawing 
		#bring back to message color
		sw $t6, 0($t5)	
		j drawRocketIfOn
	runGameLevel2:
		jal moveUpDown
		jal drawDoodler
		jal drawPlatforms	#draw platform since doodler might go over them
		#jal drawLaser
		jal sleep
		la $t5, messageColor
		lw $t6, messageColor
		sw $t1, 0($t5) 		#move sky color to message color for undrawing 
		#bring back to message color
		sw $t6, 0($t5)
		j drawRocketIfOn
	runGameLevel3:
		jal moveUpDown
		jal drawDoodler
		jal drawPlatforms	#draw platform since doodler might go over them
		jal drawLaser
		jal sleep
		la $t5, messageColor
		lw $t6, messageColor
		sw $t1, 0($t5) 		#move sky color to message color for undrawing 
		#bring back to message color
		sw $t6, 0($t5)	
		j drawRocketIfOn


	#GAME OVER SCREEN: blinking "S" and sad face
	notRestarted:				#display sad face andblinking "s" for restart
		#show gameOver screen for 1 sec
		lw $t1, gameOverScreenColor
		jal drawSky
		lw $t4, gameOverMessageColor
		jal drawGameOverMessage
		#make sure t1 has skyColor
		#lw $t1, skyColor
	
	#INITIAL SCREEN: blinking "S" to start game
	notStartedScreen:
		#if gameOn is 0 change to -1 
		lw $t4, gameOn
		bnez $t4, dontChangeGameOn
			la $t4, gameOn
			li $t5, -1
			sw $t5, 0($t4)
		dontChangeGameOn:
				
		#else messageColor is just default yellow message
		lw $t4, messageColor
		jal drawBlinkingS		#draw blinking s for both start and restsart
		jal drawBuffer
		move $t4, $t1 			#blink by undrawing 
		jal drawBlinkingS
		j end5
	notUnpaused:
		#diplay blinking p
		lw $t4, messageColor
		jal drawBlinkingP		#draw blinking s for both start and restsart
		jal drawBuffer
		move $t4, $t1			#blink by undrawing
		jal drawBlinkingP
	drawRocketIfOn:
		#if level is 0 draaw rocket: every 3 levels
		lw $t6, level
		beqz $t6, dontDrawRocket
			lw $t6, rocketColor
			jal drawRocket
			j end5
		dontDrawRocket:
		jal initializeRandomRocketPos
	end5: 
	j run

#########################################	DOODLER UP DOWN MOTION	        ####################################################
moveUpDown:
	move $v1, $ra		#store return address
	lw $t5, doodlerPos	#store current doodler position	
	
	#DOODLER AT POS OF ROCKET so turn rocketMode on and motion to UP
	lw $t6, rocketPos
	bne $t6, $t5, rocketModeOff
	#turn rocket mode on
	la $t6, rocketMode
	li $t7, 1
	sw $t7, 0($t6)
	#turn motion up
	li $t6, 1
	move $s3, $t6
	rocketModeOff:
	
	#DOODLER AT BOTTOM OF SCREEN: Game Over
	move $t6, $t5		#t6: position of pixel exactly below doodler
	addi $t6, $t6, 128
	
	lw $t7, pixelArraySize		#if $t6 is offscreen, ie >= 128*32-1=4095 or arraysize -> game over
	add $t7, $t7, $t0
	slt $t8, $t7, $t6 		#checks $t6 > $t7, ie check bottom pixel is offscreen
	beq $t8, 1, gameOver		#game over if reached bottom of screen	
	#j gameNotOver			#TODO: remove this to acess laser checking
	

	#DOODLER HIT LASER: Game Over
	move $t6, $t5		
	addi $t6, $t5, 4		#store color of pixel to the right of doodler in t6
	lw $t7, laserColor		#check if right pixel is laser color -> gameover
	lw $t8, 0($t6)		
	beq $t8, $t7, gameOver	
	
	move $t6, $t5
	addi $t6, $t5, -4		#same process as above for left of doodler
	lw $t7, laserColor	
	lw $t8, 0($t6)		
	beq $t8, $t7,gameOver		
	
	j gameNotOver			#game is not over: not hitting laser of bottom of screen
	
	
	
	#GAME OVER: 
	gameOver:	
		la $t4, gameOn			#turn gameOn 0 if at bottom 
		sw $zero, 0($t4)
		#jal drawSadFace		#draw sad face for 2 seconds then draw blinking "s" for pressing to restart
		j setUp
	gameNotOver:
	
	
	
	#CHECK IF JUMP PIXEL REACHES 15 PIXELS IF ROCKETMODE IF OFF: go down
	move $t4, $s7
	addi $t4, $t4, -12			#jumps to 12 pixels after hitting platform
	bnez $t4, notReachedMaxPixelJump
	reachedMaxPixelJump:			#set jump pixel data to 0 and set motion to down
		li $s7, 0		#set pixel height counter to 0
		lw $t4, rocketMode	#if rocket mode is on dont set motion to -1
		bnez $t4, notReachedMaxPixelJump	#rpclet mode is on so keep going 	
		li  $s3, -1	
	notReachedMaxPixelJump:			#still moving up
	
			
	
	#PLATFORM COLLISION CHECK: CHANGE MOTION DIRECTION IF AT PLATFORM: check below doodler is platforom  
	checkPlatformCollision:
		move $t6, $t5		#t6: position of pixel exactly below doodler
		addi $t6, $t6, 128
		lw $t6, 0($t6)				#store color of bottom pixel in $t6
		bne $t6, $t3, noCollisionWithPlatform	#check if color is green, continue if not
		bne $s3, -1, noCollisionWithPlatform	#check if motion is down, continue if not (doodler is moving up and passing platform)
		li $s3, 1				#platform below so change motion to up
		li $s7, 0				#initilize jump pixel to 0 after collistion
	noCollisionWithPlatform:
	
	
	#IF DOODLER AT MAX HEIGHT CHANGE MOTION DIRECTION TO STOP and CHNAGE PLATFORM POS (if at row 4 from top -> max height)
	checkReachingMaxHeight:
		addi $t6, $t5, -640			#add to see if at bottom of stage
		slt $t6, $t6, $t0			#check $t6 > $t7 
		bne $t6, 1, notAtMaxHeight
		beqz $s3, keepPlatformPositions		#generate new 1st of platform height only at the beginning when motion is 1 and changing to 0
	
	
	#DOODLER AT MAX HEIGHT -> MOVE PLATFORMS
	screenScrolling:
		#rocket mode becomes 0
		la $t4, rocketMode
		sw $zero, 0($t4)
		#increae level by 1 and make it to 0 if at 3
		lw $t6, level
		la $t7, level
		addi $t6, $t6, 1	#increase
		sw $t6, 0($t7)
		bne $t6, 2, levelNotReached3
		#level equals 3 so display screen notifications for short time and set level to 0 and draw spring
			lw $t4, messageColor
			jal drawScreenNotificationsWOWandYAY
			jal drawBuffer
			#wait for some time
			li $v0, 32
			li $a0, 50
			syscall
			jal drawSky
			jal drawPlatforms
			jal drawDoodler
			#lw $t4, skyColor
			#jal drawScreenNotificationsWOWandYAY
			#change level to 0
			la $t7, level
			sw $zero, 0($t7)
			end10:
		levelNotReached3:
				
		move $t3, $t1			#remove old platforms by redrawing them with color blue: to remove old bottom platform
		jal drawPlatforms
		lw $t3, platformColor
		jal generateNewPlatformPos	#if equal to 0, then already changed platform pos no need to again
		#if game is level 2 increase speed each level
		lw $t6, gameOn
		bne $t6, 2, noIncreaseInSpeed
		jal increaseSpeed
		
		noIncreaseInSpeed:
		bne $t6, 3, noLasersInitiated
		jal initializeRandomLaserPos
		noLasersInitiated:
		
		
		
		
	keepPlatformPositions:
	li  $s3, 0		#reached top limit so change motion to stop
	notAtMaxHeight:		#NOT AT TOP OF THE SCREEN
	
	
	checkMotionDirection:
	beq $s3, -1, currentDown
	beq $s3, 1, currentUp
	beq $s3, 0, currentStop
	
	currentDown:	 
		lw $a0, doodlerPos	
		sw $t1, 0($a0)		#color current pos of doodler blue
		addi $a0, $a0, 128 	
		sw $a0, 0($s0)		#store it back in pos		
		j end
	currentUp:
		lw $a0, doodlerPos	
		sw $t1, 0($a0)		#color current pos of doodler blue
		addi $a0, $a0, -128 	
		sw $a0, 0($s0)		
		#update jump pixel by 1
		addi $s7, $s7, 1
		j end
	currentStop:
		#check 3rd platform is at bototm bottom if yes, then change motion to -1 and jump to currentDown
		lw $a0, 8($s1)		#store 3rd platform pos
		addi $a0, $a0, 128	#store pixel below platform
		#if a0 is offscreen, ie >= 128*32-1=4095 or arraysize then change motion to -1 and jump to currentDown
		lw $t7, pixelArraySize
		add $t7, $t7, $t0
		addi $t7, $t7, -1
		slt $t8, $t7, $a0 		#checks $t6 > $t7, ie check bottom pixel is offscreen
		bne $t8, 1, bringPlatformDown	#shiftPlatform if not offscreen (so platform not at bottom of screen)
		platformInCorrectPlace:
			li  $s3, -1		#change motion to down
			jal drawSky		#this is to get rid of the lasers
			jal drawPlatforms
			j currentDown	
		
		bringPlatformDown:		#platform must shift down by 128
			#remove old platforms by redrawing them with color blue: do again for new platforms to be moved
			move $t3, $t1
			jal drawPlatforms
			lw $t3, platformColor
			
			#shift down
			lw $a0, 0($s1)	
			addi $a0, $a0, 128
			sw $a0, 0($s1)
			
			lw $a0, 4($s1)	
			addi $a0, $a0, 128
			sw $a0, 4($s1)
			
			lw $a0, 8($s1)
			addi $a0, $a0, 128
			sw $a0, 8($s1)
		move $t8, $t1	#set t8 to blue
		li $s7, 0	#set jump count back to 0
		
	end:	
	#restore return adress
	move $ra, $v1
	
	jr $ra


#########################################	RANDOME GENERATORS	        ####################################################
initializeRandomLaserPos:
	li $t4, 4		#storing immediate 4 for multiplication
	
	li $v0, 42	
	li $a0, 12		#to generate kinda in the middle not at the edges
	li $a1, 20
	syscall
	mult $t4, $a0	#multiply by 4 bytes
	mflo $v0	#ran
	add $v0, $v0, $t0
	
	la $t5, laserTopPos	#write random value at top of screen to laserTopPos
	sw $v0 ,0($t5)
	jr $ra

initializeRandomRocketPos:
	li $v0, 42	
	li $a0, 5		
	li $a1, 25
	syscall
	
	li $t7, 4
	mult $t7, $a0
	mflo $a0
	add $a0, $a0, $t0
	addi $a0, $a0, 3644
	
	la $t5, rocketPos
	sw $a0, 0($t5)

	jr $ra


randomGeneratorForXposOfPlatform: 
	#32-12=20 where 12 is the platform width in pixels
	li $t5, 4		#storing immediate 4 for multiplication
		
	li $v0, 42	
	li $a0, 0
	li $a1, 20
	syscall
	
	mult $t5, $a0	#multiply by 4 bytes
	mflo $v0
	
	jr $ra
	

generateNewPlatformPos: 
	#store return address in diff register than return address stores in run
	move $t1, $ra
	
	jal randomGeneratorForXposOfPlatform	#generate random x pos for NEW platform 1 stored in v0
	
	#copy platform 1 and 2 position
	lw $s5, 0($s1)		#pos of platform 1 becoming 2
	
	#UPDATE PLATFORM 1
	move $s4, $t0  #platform 1 becomes baseheight + (31-33)*128=-256 since its 11 pixel higher than first platform default height 
	addi $s4, $s4, -128
	add $s4, $s4, $v0	#add random x offset from left of screen
	sw $s4, 0($s1)		#store in platform 1 pos
	
	#UPDATE PLATFORM 2: copy pos of platform 1
	lw $s4, 4($s1)		#pos of platform 2 becoming 3
	sw $s5, 4($s1)
	
	#UPDATE PLATFORM 3
	sw $s4, 8($s1)
	
	#restore return adress
	move $ra, $t1
	lw $t1, skyColor

	jr $ra



#########################################	OTHER	        ####################################################
increaseSpeed:
	
	beq $s2, 32, end3	#check if sleep time is equal to 30 then dont increase speed anymore
	addi $s2, $s2, -4
	end3:
	jr $ra



sleep:
	li $v0, 32
	move $a0, $s2
	syscall
	jr $ra



#########################################	DRAW FUNCTIONS	        ####################################################
drawSky:
	add $t4, $zero, $zero	#initialize offset for screen coloring
	lw $t5, pixelArraySize	#load arraysize of screen
	colorSkyPixel:	
		add $t6, $t0, $t4	#adder of array + offset
		sw $t1, 0($t6)		#write color
	addi $t4, $t4, 4	#add 4 bytes to offset
	bne $t4, $t5, colorSkyPixel
	jr $ra

drawPlatforms:	#draws platforms based on x,y positions, stores 1 in v0 if at default height, 0 o/w
	#move platform y pos to regisers t4,t5,t6
	lw $t4, 0($s1)		#pos of platform 1
	lw $t5, 4($s1)		#pos of platform 2
	lw $t6, 8($s1)		#pos of platform 3

	add $a0, $zero, $zero	#counter for platform width set to 0
	
	lw $a1, platformWidth 	#store value platform width in a1
	
	li $a2, 0		#first add 0 to pixel for offset
	#load address of 
	colorPlatformPixel:
		add $t4, $t4, $a2	#add ofset of platform width
		add $t5, $t5, $a2	#add ofset of platform width
		add $t6, $t6, $a2	#add ofset of platform width
			
		sw $t3, 0($t4)		#write green color 
		sw $t3, 0($t5)
		sw $t3, 0($t6)
		
		li $a2, 4		#then add 4 each time for pixel offset
		
	addi $a0, $a0, 4		#add 4 bytes to counter 
	bne $a0, $a1, colorPlatformPixel 	#check counter reached platform width
	
	jr $ra

drawLaser:	#draw laser and the laserTopPos by one pixel 
	#load laser color and write to screen pixel and two screen pixel below it since laser is 3 pixels
	lw $t4, laserTopPos
	#move $t4, $t0
	la $t6, laserTopPos
	lw $t5, laserColor 
	sw $t5, 0($t4)		#write pixel color
	sw $t5, 128($t4)
	sw $t5, 256($t4)
	
	#erase pixel before it
	sw $t1, -128($t4)
	#increase laserTopPos by 1 pixel down
	addi $t4, $t4, 128
	sw $t4, 0($t6)
	
	jr $ra

drawRocket:
	#color with t6
	lw $t4, rocketPos
	sw $t6, 0($t4)
	addi $t4, $t4, 124
	sw $t6, 0($t4)
	addi $t4, $t4, 8
	sw $t6, 0($t4)
	jr $ra

drawDoodler:	
	lw $t9, doodlerPos	#store position of doodler
	lw $t8, 0($t9)		#stores current color of pixel which doodler will move to in t8: to turn
				 	#back pixel which doodler was at before to org color
	bne $t8, $t2, storeCurrColor	#if that color is red, turn to blue, since that means its at the top not moving
	changeToBlue:
		move $t8, $t1
	storeCurrColor:
	sw $t2, 0($t9)		#write red color
	jr $ra


drawScreenNotificationsWOWandYAY:
	move $t5, $t0		#pixel to be colored
	lw $t6, messageColor	#load msg color
	#get random number between 0,1 to draw message YAY or WOW
	li $v0, 42	
	li $a0, 0		
	li $a1, 2
	syscall
	beq $a0, 0, drawWOW
	beq $a0, 1, drawYAY
	
	drawWOW:
	addi $t5, $t5, 1572
	sw $t4, 0($t5)
	addi $t5, $t5, 8
	sw $t4, 0($t5)
	addi $t5, $t5, 8
	sw $t4, 0($t5)
	addi $t5, $t5, 128
	sw $t4, 0($t5)
	addi $t5, $t5, -8
	sw $t4, 0($t5)
	addi $t5, $t5, -8
	sw $t4, 0($t5)
	addi $t5, $t5, 128
	sw $t4, 0($t5)
	addi $t5, $t5, 8
	sw $t4, 0($t5)
	addi $t5, $t5, 8
	sw $t4, 0($t5)
	addi $t5, $t5, 124
	sw $t4, 0($t5)
	addi $t5, $t5, -8
	sw $t4, 0($t5)
	
	addi $t5, $t5, -364
	sw $t4, 0($t5)
	addi $t5, $t5, 4
	sw $t4, 0($t5)
	addi $t5, $t5, 132
	sw $t4, 0($t5)
	addi $t5, $t5, -8
	sw $t4, 0($t5)
	addi $t5, $t5, 128
	sw $t4, 0($t5)
	addi $t5, $t5, 132
	sw $t4, 0($t5)
	addi $t5, $t5, 4
	sw $t4, 0($t5)
	addi $t5, $t5, -128
	sw $t4, 0($t5)
	addi $t5, $t5, -128
	sw $t4, 0($t5)
	
	addi $t5, $t5, -120
	sw $t4, 0($t5)
	addi $t5, $t5, 8
	sw $t4, 0($t5)
	addi $t5, $t5, 8
	sw $t4, 0($t5)
	addi $t5, $t5, 128
	sw $t4, 0($t5)
	addi $t5, $t5, -8
	sw $t4, 0($t5)
	addi $t5, $t5, -8
	sw $t4, 0($t5)
	addi $t5, $t5, 128
	sw $t4, 0($t5)
	addi $t5, $t5, 8
	sw $t4, 0($t5)
	addi $t5, $t5, 8
	sw $t4, 0($t5)
	addi $t5, $t5, 124
	sw $t4, 0($t5)
	addi $t5, $t5, -8
	sw $t4, 0($t5)
	j end8
	
	drawYAY:
	addi $t5, $t5, 1572
	sw $t4, 0($t5)
	addi $t5, $t5, 8
	sw $t4, 0($t5)
	addi $t5, $t5, 128
	sw $t4, 0($t5)
	addi $t5, $t5, -8
	sw $t4, 0($t5)
	addi $t5, $t5, 128
	sw $t4, 0($t5)
	addi $t5, $t5, 8
	sw $t4, 0($t5)
	addi $t5, $t5, 124
	sw $t4, 0($t5)
	addi $t5, $t5, 128
	sw $t4, 0($t5)
	
	addi $t5, $t5, -500
	sw $t4, 0($t5)
	addi $t5, $t5, 4
	sw $t4, 0($t5)
	addi $t5, $t5, 124
	sw $t4, 0($t5)
	addi $t5, $t5, 8
	sw $t4, 0($t5)
	addi $t5, $t5, 120
	sw $t4, 0($t5)
	addi $t5, $t5, 4
	sw $t4, 0($t5)
	addi $t5, $t5, 4
	sw $t4, 0($t5)
	addi $t5, $t5, 128
	sw $t4, 0($t5)
	addi $t5, $t5, -8
	sw $t4, 0($t5)
	addi $t5, $t5, 128
	sw $t4, 0($t5)
	addi $t5, $t5, 8
	sw $t4, 0($t5)
	
	addi $t5, $t5, -500
	sw $t4, 0($t5)
	addi $t5, $t5, 8
	sw $t4, 0($t5)
	addi $t5, $t5, 128
	sw $t4, 0($t5)
	addi $t5, $t5, -8
	sw $t4, 0($t5)
	addi $t5, $t5, 128
	sw $t4, 0($t5)
	addi $t5, $t5, 8
	sw $t4, 0($t5)
	addi $t5, $t5, 124
	sw $t4, 0($t5)
	addi $t5, $t5, 128
	sw $t4, 0($t5)
	
	end8:
	jr $ra

drawBlinkingS:		#for pressing start, draws s with messageColor1 for 0.5s
	move $t5, $t0	#pixel to be colored
	#t4 contains color to be draws:  based on redrawing or drawing
	addi $t5, $t5, 136
	sw $t4, 0($t5)
	addi $t5, $t5, 4
	sw $t4, 0($t5)
	addi $t5, $t5, 120
	sw $t4, 0($t5)
	addi $t5, $t5, 128
	sw $t4, 0($t5)
	addi $t5, $t5, 4 
	sw $t4, 0($t5)
	addi $t5, $t5, 4 
	sw $t4, 0($t5)
	addi $t5, $t5, 128
	sw $t4, 0($t5)
	addi $t5, $t5, 128
	addi $t5, $t5, -4
	sw $t4, 0($t5)
	addi $t5, $t5, -4
	sw $t4, 0($t5)
	
	li $v0, 32
	li $a0, 500
	syscall
	
	jr $ra	

drawBlinkingP:		#for pressing pause, draws p with messageColor1 for 0.5s
	move $t5, $t0	#pixel to be colored
	#t4 contains color to be drawn: based on redrawing or drawing
	addi $t5, $t5, 132
	sw $t4, 0($t5)
	addi $t5, $t5, 4
	sw $t4, 0($t5)
	addi $t5, $t5, 124
	sw $t4, 0($t5)
	addi $t5, $t5, 8
	sw $t4, 0($t5)
	addi $t5, $t5, 120
	sw $t4, 0($t5)
	addi $t5, $t5, 4 
	sw $t4, 0($t5)
	addi $t5, $t5, 4 
	sw $t4, 0($t5)
	addi $t5, $t5, -4
	addi $t5, $t5, 124 
	sw $t4, 0($t5)
	addi $t5, $t5, 128
	sw $t4, 0($t5)
	
	li $v0, 32
	li $a0, 500
	syscall
	
	jr $ra

drawLevel1:	
	move $t5, $t0	#pixel to be colored
	#t4 contains color to be drawn: based on redrawing or drawing
	addi $t5,$t5, 248
	sw $t4, 0($t5)
	addi $t5,$t5, 128
	sw $t4, 0($t5)
	addi $t5,$t5, -4
	sw $t4, 0($t5)
	addi $t5,$t5, 132
	sw $t4, 0($t5)
	addi $t5,$t5, 128
	sw $t4, 0($t5)
	addi $t5,$t5, 128
	sw $t4, 0($t5)
	jr $ra
	
drawLevel2:
	move $t5, $t0	#pixel to be colored
	addi $t5,$t5, 244

	move $t5, $t0	#pixel to be colored
	#t4 contains color to be drawn: based on redrawing or drawing
	addi $t5,$t5, 244
	sw $t4, 0($t5)
	addi $t5,$t5, -4
	sw $t4, 0($t5)
	addi $t5,$t5, 136
	sw $t4, 0($t5)
	addi $t5,$t5, 128
	sw $t4, 0($t5)
	addi $t5,$t5, -4
	sw $t4, 0($t5)
	addi $t5,$t5, 124
	sw $t4, 0($t5)
	addi $t5,$t5, 128
	sw $t4, 0($t5)
	addi $t5,$t5, 4
	sw $t4, 0($t5)
	addi $t5,$t5, 4
	sw $t4, 0($t5)
	jr $ra

drawLevel3:
	move $t5, $t0	#pixel to be colored
	#t4 contains color to be drawn: based on redrawing or drawing
	addi $t5,$t5, 244
	sw $t4, 0($t5)
	addi $t5,$t5, -4
	sw $t4, 0($t5)
	addi $t5,$t5, 136
	sw $t4, 0($t5)
	addi $t5,$t5, 124
	sw $t4, 0($t5)
	addi $t5,$t5, 132
	sw $t4, 0($t5)
	addi $t5,$t5, 128
	sw $t4, 0($t5)
	addi $t5,$t5, -4
	sw $t4, 0($t5)
	addi $t5,$t5, -4
	sw $t4, 0($t5)
	jr $ra

drawLevelSign:
	move $t5, $t0	#pixel to be colored
	addi $t5,$t5, 232
	sw $t4, 0($t5)
	addi $t5,$t5, 128
	sw $t4, 0($t5)
	addi $t5,$t5, 128
	sw $t4, 0($t5)
	addi $t5,$t5, 128
	sw $t4, 0($t5)
	addi $t5,$t5, 128
	sw $t4, 0($t5)
	addi $t5,$t5, -12
	sw $t4, 0($t5)
	addi $t5,$t5, -124
	sw $t4, 0($t5)
	addi $t5,$t5, -8
	sw $t4, 0($t5)
	addi $t5,$t5, -128
	sw $t4, 0($t5)
	addi $t5,$t5, 8
	sw $t4, 0($t5)
	addi $t5,$t5, -128
	sw $t4, 0($t5)
	addi $t5,$t5, -8
	sw $t4, 0($t5)
	addi $t5,$t5, -136
	sw $t4, 0($t5)
	addi $t5,$t5, 128
	sw $t4, 0($t5)
	addi $t5,$t5, 128
	sw $t4, 0($t5)
	addi $t5,$t5, 128
	sw $t4, 0($t5)
	addi $t5,$t5, 128
	sw $t4, 0($t5)
	jr $ra
	

drawGameOverMessage: 
	move $t5, $t0	#pixel to be colored
	#t4 contains color to be drawn: based on redrawing or drawing
	addi $t5,$t5, 1560
	sw $t4, 0($t5)
	addi $t5,$t5, 4
	sw $t4, 0($t5)
	addi $t5,$t5, 4
	sw $t4, 0($t5)
	addi $t5,$t5, 120
	sw $t4, 0($t5)
	addi $t5,$t5, 128
	sw $t4, 0($t5)
	addi $t5,$t5, 8
	sw $t4, 0($t5)
	addi $t5,$t5, 128
	sw $t4, 0($t5)
	addi $t5,$t5, -8
	sw $t4, 0($t5)
	addi $t5,$t5, 132
	sw $t4, 0($t5)
	addi $t5,$t5, 4
	sw $t4, 0($t5)
	
	addi $t5,$t5, 8
	sw $t4, 0($t5)
	addi $t5,$t5, -128
	sw $t4, 0($t5)
	addi $t5, $t5, -128
	sw $t4, 0($t5)
	addi $t5, $t5, -128
	sw $t4, 0($t5)
	addi $t5, $t5, -128
	sw $t4, 0($t5)
	addi $t5, $t5, 4
	sw $t4, 0($t5)
	addi $t5, $t5, 132
	sw $t4, 0($t5)
	addi $t5, $t5, 128
	sw $t4, 0($t5)
	addi $t5, $t5, -4
	sw $t4, 0($t5)
	addi $t5, $t5, 132
	sw $t4, 0($t5)
	addi $t5, $t5, 128
	sw $t4, 0($t5)
	
	addi $t5, $t5, 8
	sw $t4, 0($t5)
	addi $t5, $t5, -128
	sw $t4, 0($t5)
	addi $t5, $t5, -128
	sw $t4, 0($t5)
	addi $t5, $t5, -128
	sw $t4, 0($t5)
	addi $t5, $t5, -128
	sw $t4, 0($t5)
	addi $t5, $t5, 4
	sw $t4, 0($t5)
	addi $t5, $t5, 8
	sw $t4, 0($t5)
	addi $t5, $t5, 132
	sw $t4, 0($t5)
	addi $t5, $t5, -8
	sw $t4, 0($t5)
	addi $t5, $t5, 128
	sw $t4, 0($t5)
	addi $t5, $t5, 8
	sw $t4, 0($t5)
	addi $t5, $t5, 128
	sw $t4, 0($t5)
	addi $t5, $t5, -8
	sw $t4, 0($t5)
	addi $t5, $t5, 128
	sw $t4, 0($t5)
	addi $t5, $t5, 8
	sw $t4, 0($t5)
	
	addi $t5, $t5, -120
	sw $t4, 0($t5)
	addi $t5, $t5, -128
	sw $t4, 0($t5)
	addi $t5, $t5, -128
	sw $t4, 0($t5)
	addi $t5, $t5, -128
	sw $t4, 0($t5)
	addi $t5, $t5, 4
	sw $t4, 0($t5)
	addi $t5, $t5, 256
	sw $t4, 0($t5)
	addi $t5, $t5, 256
	sw $t4, 0($t5)
	addi $t5, $t5, 4
	sw $t4, 0($t5)
	addi $t5, $t5, -512
	sw $t4, 0($t5)
	
	addi $t5, $t5, 708
	sw $t4, 0($t5)
	addi $t5, $t5, 128
	sw $t4, 0($t5)
	addi $t5, $t5, 128
	sw $t4, 0($t5)
	addi $t5, $t5, 128
	sw $t4, 0($t5)
	addi $t5, $t5, 132
	sw $t4, 0($t5)
	addi $t5, $t5, -512
	sw $t4, 0($t5)
	addi $t5, $t5, 132
	sw $t4, 0($t5)
	addi $t5, $t5, 128
	sw $t4, 0($t5)
	addi $t5, $t5, 128
	sw $t4, 0($t5)
	addi $t5, $t5, 128
	sw $t4, 0($t5)
	
	addi $t5, $t5, 12
	sw $t4, 0($t5)
	addi $t5, $t5, -132
	sw $t4, 0($t5)
	addi $t5, $t5, -128
	sw $t4, 0($t5)
	addi $t5, $t5, -128
	sw $t4, 0($t5)
	addi $t5, $t5, -128
	sw $t4, 0($t5)
	addi $t5, $t5, 8
	sw $t4, 0($t5)
	addi $t5, $t5, 128
	sw $t4, 0($t5)
	addi $t5, $t5, 128
	sw $t4, 0($t5)
	addi $t5, $t5, 128
	sw $t4, 0($t5)
	
	addi $t5, $t5, 8
	sw $t4, 0($t5)
	addi $t5, $t5, -128
	sw $t4, 0($t5)
	addi $t5, $t5, -128
	sw $t4, 0($t5)
	addi $t5, $t5, -128
	sw $t4, 0($t5)
	addi $t5, $t5, 4
	sw $t4, 0($t5)
	addi $t5, $t5, 256
	sw $t4, 0($t5)
	addi $t5, $t5, 256
	sw $t4, 0($t5)
	addi $t5, $t5, 4
	sw $t4, 0($t5)
	addi $t5, $t5, -512
	sw $t4, 0($t5)
	
	addi $t5, $t5, 520
	sw $t4, 0($t5)
	addi $t5, $t5, -128
	sw $t4, 0($t5)
	addi $t5, $t5, -128
	sw $t4, 0($t5)
	addi $t5, $t5, -128
	sw $t4, 0($t5)
	addi $t5, $t5, -128
	sw $t4, 0($t5)
	addi $t5, $t5, 4
	sw $t4, 0($t5)
	addi $t5, $t5, 256
	sw $t4, 0($t5)
	addi $t5, $t5, -124
	sw $t4, 0($t5)
	addi $t5, $t5, 256
	sw $t4, 0($t5)
	addi $t5, $t5, 128
	sw $t4, 0($t5)
	
	jr $ra

drawBuffer:
	#draw to displayAddress
	la $t4, buffer		#offset for buffer
	lw $t5, displayAddress	#offset for displayAddress
	li $t7, 0		#pixelCounter		
	
	#while loop until getting to 4096
	colorScreenPixelFromBuffer:
		#store color of buffer pixel
		lw $t6, 0($t4)
		#write color to displayAddress
		sw $t6, 0($t5)
		
		addi, $t4, $t4, 4	#move buffer offset
		addi, $t5, $t5, 4	#move displayAdress offset
		addi, $t7, $t7, 4	#move displayAdress offset
		bne $t7, 4096, colorScreenPixelFromBuffer
	jr $ra
	
	
	
	
	
