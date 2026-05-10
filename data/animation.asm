; Initial values for animations, with four bytes per entry in the following
; format:
;
; +$00 W - Absolute short pointer to the RAM location containing the delay
; +$02 B - Number of frames minus one
; +$03 B - Flags (1 = running; 2 = reverse; 4 = loop)
;
DATA_anims_init:
	; ANIM_PLAYER
	dc.w FPSVAL_0_1_S
	dc.b 1-1
	dc.b 0

	; ANIM_COIN
	dc.w FPSVAL_0_1_S
	dc.b 4-1
	dc.b 5

	; ANIM_GUSHES
	dc.w FPSVAL_0_05_S
	dc.b 3-1
	dc.b 5

	; ANIM_HIT_SPRING
	dc.w FPSVAL_0_05_S
	dc.b 6-1
	dc.b 2

	; ANIM_CRACK_PARTICLES
	dc.w FPSVAL_0_1_S
	dc.b 2-1
	dc.b 5

	; ANIM_BUS_WHEELS
	dc.w FPSVAL_0_1_S
	dc.b 3-1
	dc.b 4

	; ANIM_BUS_DOOR_REAR
	dc.w FPSVAL_0_1_S
	dc.b 4-1
	dc.b 0

	; ANIM_BUS_DOOR_FRONT
	dc.w FPSVAL_0_1_S
	dc.b 4-1
	dc.b 0

	; ANIM_CAR_WHEELS
	dc.w FPSVAL_0_05_S
	dc.b 2-1
	dc.b 4

	; ANIM_HEN
	dc.w FPSVAL_0_05_S
	dc.b 4-1
	dc.b 4

	; ANIM_COIN_SPARK_1
	dc.w FPSVAL_0_05_S
	dc.b 4-1
	dc.b 0

	; ANIM_COIN_SPARK_2
	dc.w FPSVAL_0_05_S
	dc.b 4-1
	dc.b 0

	; ANIM_COIN_SPARK_3
	dc.w FPSVAL_0_05_S
	dc.b 4-1
	dc.b 0

	; ANIM_COIN_SPARK_4
	dc.w FPSVAL_0_05_S
	dc.b 4-1
	dc.b 0

	; ANIM_COIN_SPARK_5
	dc.w FPSVAL_0_05_S
	dc.b 4-1
	dc.b 0

	; ANIM_COIN_SPARK_6
	dc.w FPSVAL_0_05_S
	dc.b 4-1
	dc.b 0

	; ANIM_COIN_SPARK_7
	dc.w FPSVAL_0_05_S
	dc.b 4-1
	dc.b 0

	; ANIM_COIN_SPARK_8
	dc.w FPSVAL_0_05_S
	dc.b 4-1
	dc.b 0

	; ANIM_COIN_SPARK_9
	dc.w FPSVAL_0_05_S
	dc.b 4-1
	dc.b 0

	; ANIM_COIN_SPARK_10
	dc.w FPSVAL_0_05_S
	dc.b 4-1
	dc.b 0

	; ANIM_COIN_SPARK_11
	dc.w FPSVAL_0_05_S
	dc.b 4-1
	dc.b 0

	; ANIM_COIN_SPARK_12
	dc.w FPSVAL_0_05_S
	dc.b 4-1
	dc.b 0

	; ANIM_COIN_SPARK_13
	dc.w FPSVAL_0_05_S
	dc.b 4-1
	dc.b 0

	; ANIM_COIN_SPARK_14
	dc.w FPSVAL_0_05_S
	dc.b 4-1
	dc.b 0

	; ANIM_COIN_SPARK_15
	dc.w FPSVAL_0_05_S
	dc.b 4-1
	dc.b 0

	; ANIM_COIN_SPARK_16
	dc.w FPSVAL_0_05_S
	dc.b 4-1
	dc.b 0

	; ANIM_CUTSCENE_OBJ_1
	dc.w FPSVAL_0_S
	dc.b 1-1
	dc.b 0

	; ANIM_CUTSCENE_OBJ_2
	dc.w FPSVAL_0_S
	dc.b 1-1
	dc.b 0

; Data about each of the player character's animation type, with eight bytes per
; entry in the following format:
;
; +$00 W - Absolute short pointer to the RAM location containing the delay
; +$02 B - Initial frame
; +$03 B - Number of frames minus one
; +$04 B - Flags (1 = running; 2 = reverse; 4 = loop)
; +$05 B - First frame within the spritemap
;
; The two remaining bytes are unused and present only for padding
;
DATA_player_anims:
	; PLAYER_ANIM_STAND
	dc.w FPSVAL_0_S
	dc.b 0
	dc.b 1-1
	dc.b 0
	dc.b 0
	dc.w 0

	; PLAYER_ANIM_WALK
	dc.w FPSVAL_0_1_S
	dc.b 0
	dc.b 6-1
	dc.b 5
	dc.b 1
	dc.w 0

	; PLAYER_ANIM_WALKBACK
	dc.w FPSVAL_0_1_S
	dc.b 6-1
	dc.b 6-1
	dc.b 7
	dc.b 1
	dc.w 0

	; PLAYER_ANIM_JUMP
	dc.w FPSVAL_0_S
	dc.b 0
	dc.b 1-1
	dc.b 0
	dc.b 7
	dc.w 0

	; PLAYER_ANIM_SLIP
	dc.w FPSVAL_0_05_S
	dc.b 0
	dc.b 4-1
	dc.b 1
	dc.b 8
	dc.w 0

	; PLAYER_ANIM_SLIPREV
	dc.w FPSVAL_0_05_S
	dc.b 4-1
	dc.b 4-1
	dc.b 3
	dc.b 8
	dc.w 0

	; PLAYER_ANIM_THROWBACK
	dc.w FPSVAL_0_05_S
	dc.b 0
	dc.b 3-1
	dc.b 1
	dc.b 12
	dc.w 0

	; PLAYER_ANIM_GRABROPE
	dc.w FPSVAL_0_S
	dc.b 0
	dc.b 1-1
	dc.b 0
	dc.b 15
	dc.w 0

