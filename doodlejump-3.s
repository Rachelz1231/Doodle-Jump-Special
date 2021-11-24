#####################################################################
#
# CSC258H5S Fall 2020 Assembly Final Project
# University of Toronto, St. George
#
# Student: Yuchen Zeng, 1006101825
#
# Bitmap Display Configuration:
# - Unit width in pixels: 8
# - Unit height in pixels: 8
# - Display width in pixels: 256
# - Display height in pixels: 256
# - Base Address for Display: 0x10008000 ($gp)
# 
# Which milestone is reached in this submission?
# (See the assignment handout for descriptions of the milestones)
# - Milestone 5
#
# Which approved additional features have been implemented? 
# 1. Scoreboard / score count
#		i. Display on the screen
#			1 score is given everytime the user jump to another platform
#			Can count up to 99. During Game, the lower digit is shown, higher digit represented by colour.
# 			When Game Over(GG), total score is shown. 
# 2. Game over / retry
# 		if the doodler fall to the bottom the game is over. Player can use s to restart game or q to quit the game.
# 3. Dynamic on-screen notifications:
#		i. "Good!", "Nice!", "Wow!", "King!"
#		ii. Notifications are in response to certain achievements.
#			"Good!", "Nice!", "Wow!", "King!" will be shown when player reaches score 10, 30, 60, 90 respectively.
# 4. Opponents / lethal creatures
#		Every time the user reaches 10 score, there will be a lethal creature on the screen and user cannot touch it (while falling) or the game will over
# 5. Shooting (of Doodler)
#		Doodler can shoot up to 5 balls by pressing a
# Any additional information that the TA needs to know: None
#
#####################################################################
.data
	doodler: .word 0x10008bb8 		#location of doodler
	Jcounter: .word	0x00000007		#Jumpcounter
	Scounter: .word	0x0000000a		#Scrollcounter
	PFcounter: .word 0x00000004		#Platformcounter
	StartSIndicator: .word 0x00000000 	#StartScrollindicator
	Sscaler: .word 0x0000000a
	Jscaler: .word 0x00000007
	PFScaler: .word 0x00000004
	Score: .word 0x00000000		#current score
	Score10: .word 0x00000000
	ScorecolourCounter: .word 0x00000000		#colour of score board
	lastplatformJumped: .word 0x00000000    #last platform ddodle jumped to(array position)
	NoticeCounter: .word	0x00000008		#Noticecounter
	Scorecolour: .word 0xffffff,0x000000, 0x800080, 0x0000ff, 0x00ff00, 0x00ffff, 0xffff00, 0xffa500, 0xffc0cb, 0xff0000
	# white -> black -> purple -> blue -> green -> cyan -> yello -> orange -> pink -> red
	Lethal:	 .word 0x00000000 #coord of lethal creature
	LethalIndicator: .word 0x00000000 
	platforms: .space 20
	shooting: .word 0:20 #every word is a ball
.text
j StartGame
ReStartGame: 	li $s0, 0x10008bb8
		sw $s0, doodler
		lw $s0, Jscaler
		sw $s0, Jcounter
		lw $s0, Sscaler
		sw $s0, Scounter
		li $s0, 0x00000008
		sw $s0, NoticeCounter
		li $s0, 0x00000000
		add $s1, $zero, $zero
		sw $s0, shooting($s1)
		add $s1, $s1, 4
		sw $s0, shooting($s1)
		add $s1, $s1, 4
		sw $s0, shooting($s1)
		add $s1, $s1, 4
		sw $s0, shooting($s1)
		add $s1, $s1, 4
		sw $s0, shooting($s1)
		sw $s0, ScorecolourCounter
		sw $s0, Lethal
		sw $s0, LethalIndicator
		sw $s0, Score
		sw $s0, Score10
		sw $s0, lastplatformJumped
		sw $s0, StartSIndicator
		lw $s0, PFScaler
		sw $s0, PFcounter
#---------------------------------------------------
StartGame: 	
		add $s0, $zero, 0x10008000
		li $s1, 0x425b5e
PaintBG:	beq $s0, 0x10009000, GeneratePF
		sw $s1, ($s0)
		add $s0, $s0, 4
		j PaintBG
GeneratePF:	
		add $t0, $zero, 0x10008d2c 	# 0x1008cac position of initial platform
		add $t1, $zero, $zero
		sw $t0, platforms($t1)
		lw $t1, PFcounter
		add $t2, $zero, $zero	   	# i==0
		add $s3, $zero, 4		# address in array
		add $s4, $zero, 0x10008000
		add $s4, $s4, 768
RandomPF:	beq $t2, $t1, Game
		li $v0, 42			# generate a random col
		li $a0, 0
		li $a1, 25 			# 32 position each row/col, each platform vary by 4 vertically
		syscall
		add $s0, $zero, 4
		mult $a0, $s0   		# $s0 x 4, result is in lo
		mflo $s0
		li $v0, 42			# generate a random row
		li $a0, 0
		li $a1, 2			# 32 position each row/col, each platform 7 position long
		syscall
		add $s1, $zero, 128 
		mult $a0, $s1			# s1 x 128
		mflo $s1
		add $s1, $s1, $s4
		add $s4, $s1, 768		# go to next part of the screen 5 pixel
		add $s0, $s0, $s1
		sw $s0, platforms($s3)		# save into the array
		add $s3, $s3, 4
		add $t2, $t2, 1
		j RandomPF
		
# all the functions ----------------------------------------------
# Scrolling function ----------------------------------------------
ScrollDown:	lw $s0, PFcounter
		add $s1, $zero, $zero		# PF position counter
ScrollDownLoop:	beq $s0, $zero, SDterminate
		lw $s2, platforms($s1)
		CheckUpdate:			add $s4, $zero, 32	  	# i <= 4
						add $s5, $zero, $zero	   	# i == 0
						add $s6, $zero, 0x10008ffc      # if current coord = s6 -> Update
		CheckUpdateLoop:  		beq $s4, $s5, NotUpdateCompleted
						beq $s6, $s2, Update
						j NotUpdate
		Update:				li $v0, 42		# generate a random col
						li $a0, 0
						li $a1, 25 		# 32 position each row/col, each platform 7 pixel long, 25 position to choose to start
						syscall
						add $s3, $zero, 4
						mult $a0, $s3   		# $s0 x 4, result is in lo
						mflo $s3
						add $s2, $s3, 0x10008000
						j AfterUpdate
		NotUpdate:			add $s5, $s5, 1
						sub $s6, $s6, 4
						j CheckUpdateLoop
		NotUpdateCompleted: 		add $s2, $s2, 128
		AfterUpdate:			sw $s2, platforms($s1)
		add $s1, $s1, 4
		sub $s0, $s0, 1
		j ScrollDownLoop
SDterminate:	jr $ra
# DrawDoodle Function ----------------------------------------------
DrawDoodle:	lw $s1, doodler
		sw $s0, ($s1)   		# s0 is the current colour of the doodler (0xeeffac or 0x425b5e(BG))
		sw $s0, 124($s1) 
		sw $s0, 128($s1)  
		sw $s0, 132($s1) 
		sw $s0, 252($s1) 
		sw $s0, 260($s1) 
		jr $ra
# Draw Lethal Creature 
DrawLethal: 	lw $s0, Lethal
		sw $s1, ($s0)
		sw $s1, 8($s0)
		sw $s1, 132($s0)
		sw $s1, 256($s0)
		sw $s1, 264($s0)
		jr $ra
# DrawPF Function ----------------------------------------------
DrawPFLoop:	# $s0 stores the colour of platform
		lw $s1, PFcounter
		add $s2, $zero, $zero	   	# i == 0
		add $s3, $zero, $zero		# index 0
DrawPF:		beq $s1, $s2, DrawPFDone
		lw $s4, platforms($s3)
		sw $s0, ($s4)
		sw $s0, 4($s4)
		sw $s0, 8($s4)
		sw $s0, 12($s4)
		sw $s0, 16($s4)
		sw $s0, 20($s4)
		sw $s0, 24($s4)
		add $s2, $s2, 1
		add $s3, $s3, 4
		j DrawPF
DrawPFDone:	jr $ra	
# Draw Score --------------------------------------------
DrawScore:	
		add $t1, $zero, $zero
		beq $t0, $t1, Score0
		j ScoreCheck1
	Score0:		sw $s0, ($s1) 		#line 1
			sw $s0, 4($s1)
			sw $s0, 8($s1)
			sw $s0, 128($s1)	#2
			sw $s0, 136($s1)
			sw $s0, 256($s1)	#3
			sw $s0, 264($s1)
			sw $s0, 384($s1)
			sw $s0, 392($s1)
			sw $s0, 512($s1)	#5
			sw $s0, 516($s1)
			sw $s0, 520($s1)
			jr $ra
ScoreCheck1:	add $t1, $t1, 1
		beq $t0, $t1, Score1
		j ScoreCheck2
	Score1:		sw $s0, 8($s1)
			sw $s0, 136($s1)
			sw $s0, 264($s1)
			sw $s0, 392($s1)
			sw $s0, 520($s1)
			jr $ra
ScoreCheck2:	add $t1, $t1, 1
		beq $t0, $t1, Score2
		j ScoreCheck3
	Score2:		sw $s0, ($s1) 		#line 1
			sw $s0, 4($s1)
			sw $s0, 8($s1)
			sw $s0, 136($s1)
			sw $s0, 256($s1)	#3
			sw $s0, 260($s1)	#3
			sw $s0, 264($s1)
			sw $s0, 384($s1)	#4
			sw $s0, 512($s1)	#5
			sw $s0, 516($s1)
			sw $s0, 520($s1)
			jr $ra
ScoreCheck3:	add $t1, $t1, 1
		beq $t0, $t1, Score3
		j ScoreCheck4
	Score3:		sw $s0, ($s1) 		#line 1
			sw $s0, 4($s1)
			sw $s0, 8($s1)
			sw $s0, 136($s1)
			sw $s0, 256($s1)	#3
			sw $s0, 260($s1)	#3
			sw $s0, 264($s1)
			sw $s0, 392($s1)
			sw $s0, 512($s1)	#5
			sw $s0, 516($s1)	
			sw $s0, 520($s1)
			jr $ra
ScoreCheck4:	add $t1, $t1, 1
		beq $t0, $t1, Score4
		j ScoreCheck5
		Score4:		sw $s0, ($s1) 		#line 1
		sw $s0, 8($s1)
		sw $s0, 128($s1)	#2
		sw $s0, 136($s1)
		sw $s0, 256($s1)	#3
		sw $s0, 260($s1)	#3
		sw $s0, 264($s1)
		sw $s0, 392($s1)
		sw $s0, 520($s1)
		jr $ra
ScoreCheck5:	add $t1, $t1, 1
		beq $t0, $t1, Score5
		j ScoreCheck6
	Score5:		sw $s0, ($s1) 		#line 1
			sw $s0, 4($s1)
			sw $s0, 8($s1)
			sw $s0, 128($s1)	#2
			sw $s0, 256($s1)	#3
			sw $s0, 260($s1)	#3
			sw $s0, 264($s1)
			sw $s0, 392($s1)
			sw $s0, 512($s1)	#5
			sw $s0, 516($s1)
			sw $s0, 520($s1)
			jr $ra
ScoreCheck6:	add $t1, $t1, 1
		beq $t0, $t1, Score6
		j ScoreCheck7
	Score6:		sw $s0, ($s1) 		#line 1
			sw $s0, 4($s1)
			sw $s0, 8($s1)
			sw $s0, 128($s1)	#2
			sw $s0, 256($s1)	#3
			sw $s0, 260($s1)	#3
			sw $s0, 264($s1)
			sw $s0, 384($s1)	#4
			sw $s0, 392($s1)
			sw $s0, 512($s1)	#5
			sw $s0, 516($s1)
			sw $s0, 520($s1)
			jr $ra
ScoreCheck7:	add $t1, $t1, 1
		beq $t0, $t1, Score7
		j ScoreCheck8
	Score7:		sw $s0, ($s1) 		#line 1
			sw $s0, 4($s1)
			sw $s0, 8($s1)
			sw $s0, 136($s1)
			sw $s0, 264($s1)
			sw $s0, 392($s1)
			sw $s0, 520($s1)
			jr $ra
ScoreCheck8:	add $t1, $t1, 1
		beq $t0, $t1, Score8
		j ScoreCheck9
Score8:		sw $s0, ($s1) 		#line 1
		sw $s0, 4($s1)
		sw $s0, 8($s1)
		sw $s0, 128($s1)	#2
		sw $s0, 136($s1)
		sw $s0, 256($s1)	#3
		sw $s0, 260($s1)	#3
		sw $s0, 264($s1)
		sw $s0, 384($s1)	#4
		sw $s0, 392($s1)
		sw $s0, 512($s1)	#5
		sw $s0, 516($s1)
		sw $s0, 520($s1)
		jr $ra
ScoreCheck9:	sw $s0, ($s1) 		#line 1
		sw $s0, 4($s1)
		sw $s0, 8($s1)
		sw $s0, 128($s1)	#2
		sw $s0, 136($s1)
		sw $s0, 256($s1)	#3
		sw $s0, 260($s1)	#3
		sw $s0, 264($s1)
		sw $s0, 392($s1)
		sw $s0, 512($s1)	#5
		sw $s0, 516($s1)
		sw $s0, 520($s1)
		jr $ra
# Ball location
BallLocation:	add $s0, $zero, $zero # i=0
		add $s1, $zero, 5    # i<=4
		add $s2, $zero, $zero # ball memeory location
BallLocLoop:	beq $s0, $s1, LocDone
		lw $s3, shooting($s2)
		beq $s3, $zero, StoreLocation 
		j NoStore
StoreLocation:	
		lw $s4, doodler
		sub $s4, $s4, 256
		sw $s4, shooting($s2)
		jr $ra
NoStore:	add $s0, $s0, 1
		add $s2, $s2, 4
		j BallLocLoop
LocDone:	jr $ra
# notification function ----------------------------------------------
		# s0 colour s1 coordinate s2 which notification
Notification:	li $s1, 0x10009000
		add $s3, $zero, 1
		beq $s2, $s3, Good
		j NotGood
		Good: 			sub $s1, $s1, 616
					sw $s0, ($s1)
					sw $s0, 4($s1)
					sw $s0, 8($s1)
					sw $s0, 12($s1)
					sw $s0, 128($s1)
					sw $s0, 256($s1)	#3
					sw $s0, 264($s1)	#3
					sw $s0, 268($s1)
					sw $s0, 384($s1)	#4
					sw $s0, 396($s1)
					sw $s0, 512($s1)	#5
					sw $s0, 516($s1)
					sw $s0, 520($s1)
					sw $s0, 524($s1)
					add $s1, $s1, 20
					sw $s0, ($s1) 		#line 1
					sw $s0, 4($s1)
					sw $s0, 8($s1)
					sw $s0, 128($s1)	#2
					sw $s0, 136($s1)			
					sw $s0, 256($s1)	#3
					sw $s0, 264($s1)
					sw $s0, 384($s1)			
					sw $s0, 392($s1)
					sw $s0, 512($s1)	#5
					sw $s0, 516($s1)
					sw $s0, 520($s1)
					add $s1, $s1, 16
					sw $s0, ($s1) 		#line 1
					sw $s0, 4($s1)
					sw $s0, 8($s1)
					sw $s0, 128($s1)	#2
					sw $s0, 136($s1)			
					sw $s0, 256($s1)	#3
					sw $s0, 264($s1)
					sw $s0, 384($s1)			
					sw $s0, 392($s1)
					sw $s0, 512($s1)	#5
					sw $s0, 516($s1)
					sw $s0, 520($s1)
					add $s1, $s1, 16
					sw $s0, ($s1) 		#line 1
					sw $s0, 4($s1)
					sw $s0, 8($s1)
					sw $s0, 128($s1)	#2
					sw $s0, 140($s1)			
					sw $s0, 256($s1)	#3
					sw $s0, 268($s1)
					sw $s0, 384($s1)			
					sw $s0, 396($s1)
					sw $s0, 512($s1)	#5
					sw $s0, 516($s1)
					sw $s0, 520($s1)
					add $s1, $s1, 12
					sw $s0, 8($s1)
					sw $s0, 136($s1)
					sw $s0, 264($s1)
					sw $s0, 520($s1)
					jr $ra
NotGood:	add $s3, $s3, 2
		beq $s2, $s3, Nice
		j NotNice
Nice:		sub $s1, $s1, 616
		sw $s0, ($s1)
		sw $s0, 12($s1)
		sw $s0, 128($s1)
		sw $s0, 132($s1)
		sw $s0, 140($s1)
		sw $s0, 256($s1)	#3
		sw $s0, 264($s1)	#3
		sw $s0, 268($s1)
		sw $s0, 384($s1)	#4
		sw $s0, 396($s1)
		sw $s0, 512($s1)	#5
		sw $s0, 524($s1)
		add $s1, $s1, 20
		sw $s0, ($s1) 		#line 1
		sw $s0, 4($s1)
		sw $s0, 8($s1)
		sw $s0, 132($s1)
		sw $s0, 260($s1)
		sw $s0, 388($s1)
		sw $s0, 512($s1)	#5
		sw $s0, 516($s1)
		sw $s0, 520($s1)
		add $s1, $s1, 16
		sw $s0, ($s1) 		#line 1
		sw $s0, 4($s1)
		sw $s0, 8($s1)
		sw $s0, 128($s1)			
		sw $s0, 256($s1)
		sw $s0, 384($s1)
		sw $s0, 512($s1)	#5
		sw $s0, 516($s1)
		sw $s0, 520($s1)
		add $s1, $s1, 16
		sw $s0, ($s1) 		#line 1
		sw $s0, 4($s1)
		sw $s0, 8($s1)
		sw $s0, 128($s1)			
		sw $s0, 256($s1)	#3
		sw $s0, 260($s1)
		sw $s0, 264($s1)
		sw $s0, 384($s1)
		sw $s0, 512($s1)	#5
		sw $s0, 516($s1)
		sw $s0, 520($s1)
		add $s1, $s1, 12
		sw $s0, 8($s1)
		sw $s0, 136($s1)
		sw $s0, 264($s1)
		sw $s0, 520($s1)
		jr $ra
NotNice:	add $s3, $s3, 3
		beq $s2, $s3, Wow
		j NotWow
Wow: 		sub $s1, $s1, 612
		sw $s0, ($s1)
		sw $s0, 16($s1)
		sw $s0, 128($s1)
		sw $s0, 136($s1)
		sw $s0, 144($s1)
		sw $s0, 256($s1)
		sw $s0, 264($s1)
		sw $s0, 272($s1)
		sw $s0, 384($s1)	#4
		sw $s0, 392($s1)
		sw $s0, 400($s1)
		sw $s0, 516($s1)
		sw $s0, 524($s1)
		add $s1, $s1, 24
		sw $s0, ($s1) 		#line 1
		sw $s0, 4($s1)
		sw $s0, 8($s1)
		sw $s0, 128($s1)	#2
		sw $s0, 136($s1)			
		sw $s0, 256($s1)	#3
		sw $s0, 264($s1)
		sw $s0, 384($s1)			
		sw $s0, 392($s1)
		sw $s0, 512($s1)	#5
		sw $s0, 516($s1)
		sw $s0, 520($s1)
		add $s1, $s1, 16
		sw $s0, ($s1)
		sw $s0, 16($s1)
		sw $s0, 128($s1)
		sw $s0, 136($s1)
		sw $s0, 144($s1)
		sw $s0, 256($s1)	#3
		sw $s0, 264($s1)
		sw $s0, 272($s1)
		sw $s0, 384($s1)	#4
		sw $s0, 392($s1)
		sw $s0, 400($s1)
		sw $s0, 516($s1)
		sw $s0, 524($s1)
		add $s1, $s1, 16
		sw $s0, 8($s1)
		sw $s0, 136($s1)
		sw $s0, 264($s1)
		sw $s0, 520($s1)
		jr $ra
NotWow:		add $s3, $s3, 3
		beq $s2, $s3, King
		jr $ra
King:		sub $s1, $s1, 616
		sw $s0, ($s1)
		sw $s0, 12($s1)
		sw $s0, 128($s1)
		sw $s0, 136($s1)
		sw $s0, 256($s1)	#3
		sw $s0, 260($s1)	#3
		sw $s0, 384($s1)	#4
		sw $s0, 392($s1)
		sw $s0, 512($s1)	#5
		sw $s0, 524($s1)
		add $s1, $s1, 20
		sw $s0, ($s1) 		#line 1
		sw $s0, 4($s1)
		sw $s0, 8($s1)
		sw $s0, 132($s1)
		sw $s0, 260($s1)
		sw $s0, 388($s1)	
		sw $s0, 512($s1)	#5
		sw $s0, 516($s1)
		sw $s0, 520($s1)
		add $s1, $s1, 16
		sw $s0, ($s1)
		sw $s0, 12($s1)
		sw $s0, 128($s1)
		sw $s0, 132($s1)
		sw $s0, 140($s1)
		sw $s0, 256($s1)	#3
		sw $s0, 264($s1)	#3
		sw $s0, 268($s1)
		sw $s0, 384($s1)	#4
		sw $s0, 396($s1)
		sw $s0, 512($s1)	#5
		sw $s0, 524($s1)	#5
		add $s1, $s1, 20
		sw $s0, ($s1)
		sw $s0, 4($s1)
		sw $s0, 8($s1)
		sw $s0, 12($s1)
		sw $s0, 128($s1)
		sw $s0, 256($s1)	#3
		sw $s0, 264($s1)	#3
		sw $s0, 268($s1)
		sw $s0, 384($s1)	#4
		sw $s0, 396($s1)
		sw $s0, 512($s1)	#5
		sw $s0, 516($s1)
		sw $s0, 520($s1)
		sw $s0, 524($s1)
		add $s1, $s1, 12
		sw $s0, 8($s1)
		sw $s0, 136($s1)
		sw $s0, 264($s1)
		sw $s0, 520($s1)
		jr $ra
# LethalLocation
LethalLocation: 				li $v0, 42		# generate a random col
						li $a0, 0
						li $a1, 25 		# 32 position each row/col, each platform 7 pixel long, 25 position to choose to start
						syscall
						add $s3, $zero, 4
						mult $a0, $s3   		# $s0 x 4, result is in lo
						mflo $s3
						add $s3, $s3, 0x10008000
						sw $s3, Lethal
						add $s3, $zero, 1
						sw $s3, LethalIndicator
						jr $ra
# End of functions ----------------------------------------------

Game:		li $s0, 0xeeffac
		jal DrawDoodle
		li $s0, 0x88c6a2 
		jal DrawPFLoop
		lw $s0, LethalIndicator
		bgtz $s0, LethalCheck
		j BallCheck
LethalCheck:	li $s1, 0xff0000
		jal DrawLethal
BallCheck:	add $s0, $zero, $zero
		add $s1, $zero, 5
		add $s2, $zero, $zero
		li $s4, 0xeeffac
		BallCheckLoop:	beq $s0, $s1, NoticeCheck
				lw $s3, shooting($s2)
				#li $s3, 0x10008000
				bne $s3, $zero, DrawBall
				j NoDrawBall
				DrawBall:	sw $s4, ($s3)
				NoDrawBall:	add $s0, $s0, 1
						add $s2, $s2, 4	
						j BallCheckLoop
NoticeCheck:	lw $s5, NoticeCounter
		bgtz $s5, ShowNotice
		j ScoreBoard
		ShowNotice:	li $s0, 0xffff00
				lw $s1, NoticeCounter
				lw $s2, Score10
				sub $s5, $s5, 1
				sw $s5, NoticeCounter
				beq $s5, $zero, Erase
				j Notice
		Erase:		li $s0, 0x425b5e
		Notice:		jal Notification
ScoreBoard:	lw $s2, ScorecolourCounter
		lw $s0, Scorecolour($s2)
		li $s1, 0x10009000
		sub $s1, $s1, 640
		lw $t0, Score
		jal DrawScore
AfterScore:	li $v0, 32
		li $a0, 100
		syscall
		li $s0, 0x425b5e 	# Erase
		jal DrawDoodle
		BallCheck2:	add $s0, $zero, $zero
				add $s1, $zero, 5
				add $s2, $zero, $zero
				li $s4, 0x425b5e
		BallCheckLoop2:	beq $s0, $s1, UpdateLocation
				lw $s3, shooting($s2)
				#li $s3, 0x10008000
				bne $s3, $zero, DrawBall2
				j NoDrawBall2
				DrawBall2:	sw $s4, ($s3)
						li $t0, 0x10008000
				BallEraseLoop:	beq $t0, 0x1000807c, NoEraseBall2
						beq $s3, $t0, EraseBall
						j NoEraseBall
				EraseBall:	sw $zero, shooting($s2)
						j BallCheckLoop2
				NoEraseBall:	add $t0, $t0, 4
						j BallEraseLoop
				NoEraseBall2:	sub $s3, $s3, 128
						sw $s3, shooting($s2)
				NoDrawBall2:	add $s0, $s0, 1
						add $s2, $s2, 4	
						j BallCheckLoop2
UpdateLocation: lw $s0, 0xffff0000
		beq $s0, 1, CheckKBInput1
		j Jump
CheckKBInput1:	lw $s1, 0xffff0004
		beq $s1, 0x6a, Left # if j is pressed, move to the left
		beq $s1, 0x6b, Right # if k is pressed, move to the left
		j CheckShoot
		Left:		lw $t8, doodler
				sub $t8, $t8, 4
				sw $t8, doodler
				j CheckShoot
		Right:		lw $t8, doodler
				add $t8, $t8, 4
				sw $t8, doodler
CheckShoot:	beq $s1, 0x61, Shoot # if a is pressed, shoot
		j Jump
Shoot:		# store new location for a ball
		li $s7, 0xff0000
		jal BallLocation
Jump:		lw $t9, Jcounter
		beq $t9, $zero, Fall # after jump 12 bits 
Jump2:		lw $t8, doodler
		sub $t8, $t8, 128
		sw $t8, doodler
		lw $t9, Jcounter
		sub $t9, $t9, 1
		sw $t9, Jcounter
		j Scroll
Fall:		lw $t8, doodler
		add $s0, $t8, 384
		lw $s1, PFcounter		# total number of platform need to be checked
		add $s2, $zero, $zero	   	# i == 0
		add $s3, $zero, $zero		# PF position
UDCheckLoop:	beq $s2, $s1, FailCheck
		lw $s4, platforms($s3)
		sub $s4, $s4, 4  		#pixel before pf
		add $s5, $zero, 9	  	# i <= 7+2(2 edge)
		add $s6, $zero, $zero	   	# i == 0
		CorrdCheckLoop1:		beq $s5, $s6, UDCheckLoop2
						beq $s4, $s0, InitialCheck
						j CorrdCheckLoop2
						InitialCheck:	beq $s3, $zero, SwitchUp
								lw $t7, StartSIndicator
								beq $t7, $zero, StartS
								j SwitchUp
						StartS: 	add $t7, $zero, 1
								sw $t7, StartSIndicator	
								j SwitchUp
		CorrdCheckLoop2:		add $s4, $s4, 4
						add $s6, $s6, 1
						j CorrdCheckLoop1
UDCheckLoop2:	add $s2, $s2, 1
		add $s3, $s3, 4
		j UDCheckLoop
SwitchUp:	
			ScoreCheck:		lw $t5, lastplatformJumped
						bne $s3, $t5, ScoreIncrease
						j SwitchUp2
			ScoreIncrease:		sw $s3, lastplatformJumped
						li $s0, 0x425b5e 	# Erase
						li $s1, 0x10009000
						sub $s1, $s1, 640
						lw $t0, Score
						jal DrawScore
						add $t6, $zero, 9
						beq $t0, $t6, NewLevel
						j NoNewLevel
			NewLevel:		lw $t4, ScorecolourCounter
						add $t4, $t4, 4
						sw $t4, ScorecolourCounter
						lw $t4, Score10
						beq $t4, $t6, LethalGenerator # reached max level
						add $t4, $t4, 1
						sw $t4, Score10
						sw $zero, Score
						add $t4, $zero, 8
						sw $t4, NoticeCounter
						add $t4, $zero, 3712
						sw $t4, LethalIndicator
						j LethalGenerator
			NoNewLevel:		add $t0, $t0, 1
						sw $t0, Score
						j SwitchUp2
			LethalGenerator:	jal LethalLocation # update the location of lethal
SwitchUp2:	lw $t9, Jcounter
		li $t9, 0x00000008
		sw $t9, Jcounter
		lw $t9, Sscaler
		sw $t9, Scounter
		j Scroll
FailCheck:	# Check lethal
		lw $s0, LethalIndicator
		bgtz $s0, FailLethal
		j NoFailLethal
		FailLethal:	lw $s0, Lethal
				lw $s1, doodler
				beq $s0, $s1, GG
				add $s0, $s0, 8
				beq $s0, $s1, GG
				add $s0, $s0, 124
				beq $s0, $s1, GG
				add $s0, $s0, 124
				beq $s0, $s1, GG
				add $s0, $s0, 8
				lw $s0, Lethal
				add $s1, $s1, 124
				beq $s0, $s1, GG
				add $s0, $s0, 8
				beq $s0, $s1, GG
				add $s0, $s0, 124
				beq $s0, $s1, GG
				add $s0, $s0, 124
				beq $s0, $s1, GG
				add $s0, $s0, 8
				lw $s0, Lethal
				add $s1, $s1, 8
				beq $s0, $s1, GG
				add $s0, $s0, 8
				beq $s0, $s1, GG
				add $s0, $s0, 124
				beq $s0, $s1, GG
				add $s0, $s0, 124
				beq $s0, $s1, GG
				add $s0, $s0, 8
				lw $s0, Lethal
				add $s1, $s1, 120
				beq $s0, $s1, GG
				add $s0, $s0, 8
				beq $s0, $s1, GG
				add $s0, $s0, 124
				beq $s0, $s1, GG
				add $s0, $s0, 124
				beq $s0, $s1, GG
				add $s0, $s0, 8
				lw $s0, Lethal
				add $s1, $s1, 8
				beq $s0, $s1, GG
				add $s0, $s0, 8
				beq $s0, $s1, GG
				add $s0, $s0, 124
				beq $s0, $s1, GG
				add $s0, $s0, 124
				beq $s0, $s1, GG
				add $s0, $s0, 8
		# check fail to bottom
NoFailLethal:	add $s0, $t8, 256
		add $s1, $zero, 32	  	# i <= 4
		add $s2, $zero, $zero	   	# i == 0
		add $s3, $zero, 0x10008ffc
FailCheckLoop:  beq $s1, $s2, NoFail
		beq $s3, $s0, GG
		add $s2, $s2, 1
		sub $s3, $s3, 4
		j FailCheckLoop
NoFail:		lw $t8, doodler
		add $t8, $t8, 128
		sw $t8, doodler
		j Scroll	
Scroll:			# if it left the first platform, start scrolling screen
			lw $t8, StartSIndicator
			bne $t8, $zero, CanScroll
			j Game
			CanScroll:			lw $t9, Scounter
							beq $t9, $zero, Game # scroll only Scounter time
							sub $t9, $t9, 1
							sw $t9, Scounter
							li $s0, 0x425b5e #Erase and Redraw
							jal DrawPFLoop
							
							lw $s0, LethalIndicator
							bgtz $s0, LethalCheck2
							j AfterScroll
					LethalCheck2:	li $s1, 0x425b5e
							jal DrawLethal
							lw $s1, Lethal # get location
							add $s1, $s1, 128 # go to next line
							sub $s0, $s0, 1
							sw $s1, Lethal
							sw $s0, LethalIndicator
					AfterScroll:	
							jal ScrollDown
							j Game


# Game Over ---------------------------------
GG:		li $s0, 0x425b5e 	# Erase
		li $s1, 0x10009000
		sub $s1, $s1, 640
		lw $t0, Score
		jal DrawScore
		li $s1, 0x10009000
		sub $s1, $s1, 572
		lw $s2, ScorecolourCounter
		lw $s0, Scorecolour($s2)
		jal DrawScore
		li $s1, 0x10009000
		sub $s1, $s1, 596
		lw $t0, Score10
		jal DrawScore
		li $s1, 0xffffff
		add $s0, $zero, 0x10008528
		sub $s0, $s0, 128
DrawLetter:	sw $s1, ($s0)
		sw $s1, 4($s0)
		sw $s1, 8($s0)
		sw $s1, 12($s0)
		sw $s1, 128($s0)
		sw $s1, 256($s0)
		sw $s1, 384($s0)
		sw $s1, 392($s0)
		sw $s1, 396($s0)
		sw $s1, 512($s0)
		sw $s1, 524($s0)
		sw $s1, 640($s0)
		sw $s1, 644($s0)
		sw $s1, 648($s0)
		sw $s1, 652($s0)
		add $s0, $s0, 32
		sw $s1, ($s0)
		sw $s1, 4($s0)
		sw $s1, 8($s0)
		sw $s1, 12($s0)
		sw $s1, 128($s0)
		sw $s1, 256($s0)
		sw $s1, 384($s0)
		sw $s1, 392($s0)
		sw $s1, 396($s0)
		sw $s1, 512($s0)
		sw $s1, 524($s0)
		sw $s1, 640($s0)
		sw $s1, 644($s0)
		sw $s1, 648($s0)
		sw $s1, 652($s0)
		add $s0, $zero, 0x10008a28
		sw $s1, 4($s0)
		sw $s1, 128($s0)
		sw $s1, 260($s0)
		sw $s1, 384($s0)
		sw $s1, 388($s0)
		sw $s1, 20($s0)
		sw $s1, 148($s0)
		sw $s1, 272($s0)
		sw $s1, 400($s0)
		sw $s1, 40($s0)
		sw $s1, 44($s0)
		sw $s1, 164($s0)
		sw $s1, 172($s0)
		sw $s1, 296($s0)
		sw $s1, 300($s0)
		sw $s1, 428($s0)
CheckLoop:	lw $s0, 0xffff0000
		beq $s0, 1, CheckKBInput2
CheckKBInput2:	lw $s1, 0xffff0004
		beq $s1, 0x73, ReStartGame # if s is pressed, restart the game move to the left e 65, s 73
		beq $s1, 0x71, Exit # if s is pressed, restart the game move to the left e 65, s 73
		j CheckLoop
Exit:
