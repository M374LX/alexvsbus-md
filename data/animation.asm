; Initial values for animations
;
; Order of bytes: number of frames minus one, NTSC delay, PAL delay, flags
;
; The flags, which can be OR'd together, are: 1 = running; 2 = reverse; 4 = loop
;
; TODO: fix PAL delays
DATA_anims_init:
	dc.b 0, 0, 0, 0 ; ANIM_PLAYER
	dc.b 3, 6, 6, 5 ; ANIM_COIN
	dc.b 2, 3, 3, 5 ; ANIM_GUSHES
	dc.b 5, 2, 2, 2 ; ANIM_HIT_SPRING
	dc.b 1, 6, 6, 5 ; ANIM_CRACK_PARTICLES
	dc.b 2, 6, 6, 4 ; ANIM_BUS_WHEELS
	dc.b 3, 6, 6, 0 ; ANIM_BUS_DOOR_REAR
	dc.b 3, 6, 6, 0 ; ANIM_BUS_DOOR_FRONT
	dc.b 1, 3, 3, 4 ; ANIM_CAR_WHEELS
	dc.b 3, 3, 3, 4 ; ANIM_HEN
	dc.b 3, 3, 3, 0 ; ANIM_COIN_SPARK_1
	dc.b 3, 3, 3, 0 ; ANIM_COIN_SPARK_2
	dc.b 3, 3, 3, 0 ; ANIM_COIN_SPARK_3
	dc.b 3, 3, 3, 0 ; ANIM_COIN_SPARK_4
	dc.b 3, 3, 3, 0 ; ANIM_COIN_SPARK_5
	dc.b 3, 3, 3, 0 ; ANIM_COIN_SPARK_6
	dc.b 3, 3, 3, 0 ; ANIM_COIN_SPARK_7
	dc.b 3, 3, 3, 0 ; ANIM_COIN_SPARK_8
	dc.b 3, 3, 3, 0 ; ANIM_COIN_SPARK_9
	dc.b 3, 3, 3, 0 ; ANIM_COIN_SPARK_10
	dc.b 3, 3, 3, 0 ; ANIM_COIN_SPARK_11
	dc.b 3, 3, 3, 0 ; ANIM_COIN_SPARK_12
	dc.b 3, 3, 3, 0 ; ANIM_COIN_SPARK_13
	dc.b 3, 3, 3, 0 ; ANIM_COIN_SPARK_14
	dc.b 3, 3, 3, 0 ; ANIM_COIN_SPARK_15
	dc.b 3, 3, 3, 0 ; ANIM_COIN_SPARK_16
	dc.b 0, 0, 0, 0 ; ANIM_CUTSCENE_OBJ_1
	dc.b 0, 0, 0, 0 ; ANIM_CUTSCENE_OBJ_2

; Data about each of the player character's animation type
DATA_player_anims:
	; PLAYER_ANIM_STAND
	dc.b 0   ; Initial frame
	dc.b 0   ; Last frame (number of frames minus one)
	dc.w 0   ; Delay
	dc.b 0   ; Flags (not running, no reverse, no loop)
	dc.b 0   ; First frame within spritemap
	dc.w 0   ; Padding

	; PLAYER_ANIM_WALK
	dc.b 0   ; Initial frame
	dc.b 6-1 ; Last frame (number of frames minus one)
	dc.w 6   ; Delay
	dc.b 5   ; Flags (running, no reverse, loop)
	dc.b 1   ; First frame within spritemap
	dc.w 0   ; Padding

	; PLAYER_ANIM_WALKBACK
	dc.b 6-1 ; Initial frame
	dc.b 6-1 ; Last frame (number of frames minus one)
	dc.w 6   ; Delay
	dc.b 7   ; Flags (running, reverse, loop)
	dc.b 1   ; First frame within spritemap
	dc.w 0   ; Padding

	; PLAYER_ANIM_JUMP
	dc.b 0   ; Initial frame
	dc.b 0   ; Last frame (number of frames minus one)
	dc.w 0   ; Delay
	dc.b 0   ; Flags (not running, no reverse, no loop)
	dc.b 7   ; First frame within spritemap
	dc.w 0   ; Padding

	; PLAYER_ANIM_SLIP
	dc.b 0   ; Initial frame
	dc.b 3   ; Last frame (number of frames minus one)
	dc.w 3   ; Delay
	dc.b 1   ; Flags (running, no reverse, no loop)
	dc.b 8   ; First frame within spritemap
	dc.w 0   ; Padding

	; PLAYER_ANIM_SLIPREV
	dc.b 3   ; Initial frame
	dc.b 3   ; Last frame (number of frames minus one)
	dc.w 3   ; Delay
	dc.b 3   ; Flags (running, reverse, no loop)
	dc.b 8   ; First frame within spritemap
	dc.w 0   ; Padding

	; PLAYER_ANIM_THROWBACK
	dc.b 0   ; Initial frame
	dc.b 2   ; Last frame (number of frames minus one)
	dc.w 3   ; Delay
	dc.b 1   ; Flags (running, no reverse, no loop)
	dc.b 12  ; First frame within spritemap
	dc.w 0   ; Padding

	; PLAYER_ANIM_GRABROPE
	dc.b 0   ; Initial frame
	dc.b 0   ; Last frame (number of frames minus one)
	dc.w 0   ; Delay
	dc.b 0   ; Flags (not running, no reverse, no loop)
	dc.b 15  ; First frame within spritemap
	dc.w 0   ; Padding

