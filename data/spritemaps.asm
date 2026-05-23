DATA_spritemap_player:
	; 0 - Stand
	dc.w 11,  0, $0, $A000|SPR_PLAYER_HEAD
	dc.w 7,   8, $6, $A000|SPR_PLAYER_TORSO_1
	dc.w 8,  32, $7, $A000|SPR_PLAYER_LEGS_1
	dc.w 0,   0, $0, 0

	; 1 - Walk frame 1
	dc.w 11,  0, $0, $A000|SPR_PLAYER_HEAD
	dc.w 7,   8, $6, $A000|SPR_PLAYER_TORSO_2
	dc.w 0,  32, $F, $A000|SPR_PLAYER_LEGS_2
	dc.w 0,   0, $0, 0

	; 2 - Walk frame 2
	dc.w 11,  0, $0, $A000|SPR_PLAYER_HEAD
	dc.w 7,   8, $6, $A000|SPR_PLAYER_TORSO_3
	dc.w 0,  32, $B, $A000|SPR_PLAYER_LEGS_3
	dc.w 0,   0, $0, 0

	; 3 - Walk frame 3
	dc.w 11,  0, $0, $A000|SPR_PLAYER_HEAD
	dc.w 7,   8, $6, $A000|SPR_PLAYER_TORSO_2
	dc.w 8,  32, $7, $A000|SPR_PLAYER_LEGS_4
	dc.w 0,   0, $0, 0

	; 4 - Walk frame 4
	dc.w 11,  0, $0, $A000|SPR_PLAYER_HEAD
	dc.w 7,   8, $6, $A000|SPR_PLAYER_TORSO_1
	dc.w 0,  32, $F, $A000|SPR_PLAYER_LEGS_5
	dc.w 0,   0, $0, 0

	; 5 - Walk frame 5
	dc.w 11,  0, $0, $A000|SPR_PLAYER_HEAD
	dc.w 7,   8, $6, $A000|SPR_PLAYER_TORSO_4
	dc.w 0,  32, $B, $A000|SPR_PLAYER_LEGS_6
	dc.w 0,   0, $0, 0

	; 6 - Walk frame 6
	dc.w 11,  0, $0, $A000|SPR_PLAYER_HEAD
	dc.w 7,   8, $6, $A000|SPR_PLAYER_TORSO_1
	dc.w 8,  32, $7, $A000|SPR_PLAYER_LEGS_7
	dc.w 0,   0, $0, 0

	; 7 - Jump
	dc.w 11,  0, $0, $A000|SPR_PLAYER_HEAD
	dc.w 7,   8, $6, $A000|SPR_PLAYER_TORSO_1
	dc.w 8,  32, $7, $A000|SPR_PLAYER_LEGS_8
	dc.w 0,   0, $0, 0

	; 8 - Slip frame 1
	dc.w 11,  0, $0, $A000|SPR_PLAYER_HEAD
	dc.w 7,   8, $6, $A000|SPR_PLAYER_TORSO_1
	dc.w 8,  32, $7, $A000|SPR_PLAYER_LEGS_1
	dc.w 0,   0, $0, 0

	; 9 - Slip frame 2
	dc.w 11,  0, $0, $A000|SPR_PLAYER_HEAD
	dc.w 7,   8, $6, $A000|SPR_PLAYER_TORSO_1
	dc.w 8,  32, $5, $A000|SPR_PLAYER_LEGS_13
	dc.w 16, 48, $5, $A000|SPR_PLAYER_FOOT_1

	; 10 - Slip frame 3
	dc.w 11,  0, $0, $A000|SPR_PLAYER_HEAD
	dc.w 7,   8, $6, $A000|SPR_PLAYER_TORSO_1
	dc.w 8,  32, $9, $A000|SPR_PLAYER_LEGS_14
	dc.w 32, 40, $5, $A000|SPR_PLAYER_FOOT_2

	; 11 - Slip frame 4
	dc.w 11,  0, $0, $A000|SPR_PLAYER_HEAD
	dc.w 7,   8, $6, $A000|SPR_PLAYER_TORSO_1
	dc.w 8,  32, $8, $A000|SPR_PLAYER_LEGS_15
	dc.w 32, 24, $5, $A000|SPR_PLAYER_FOOT_3

	; 12 - Throwback frame 1
	dc.w 11,  0, $0, $A000|SPR_PLAYER_HEAD
	dc.w 7,   8, $6, $A000|SPR_PLAYER_TORSO_3
	dc.w 8,  32, $7, $A000|SPR_PLAYER_LEGS_10
	dc.w 0,   0, $0, 0

	; 13 - Throwback frame 2
	dc.w 11,  0, $0, $A000|SPR_PLAYER_HEAD
	dc.w 7,   8, $6, $A000|SPR_PLAYER_TORSO_3
	dc.w 8,  32, $B, $A000|SPR_PLAYER_LEGS_11
	dc.w 0,   0, $0, 0

	; 14 - Throwback frame 3
	dc.w 11,  0, $0, $A000|SPR_PLAYER_HEAD
	dc.w 7,   8, $6, $A000|SPR_PLAYER_TORSO_3
	dc.w 8,  32, $B, $A000|SPR_PLAYER_LEGS_12
	dc.w 0,   0, $0, 0

	; 15 - Grabrope
	dc.w 11,  0, $0, $A000|SPR_PLAYER_HEAD
	dc.w 7,   8, $6, $A000|SPR_PLAYER_TORSO_5
	dc.w 8,  32, $7, $A000|SPR_PLAYER_LEGS_9
	dc.w 0,   0, $0, 0

DATA_spritemap_bus_stop_sign:
	dc.w 0,   0, $7, $A000|SPR_BUS_STOP_SIGN_TOP
	dc.w 4,  32, $3, $A000|SPR_BUS_STOP_SIGN_MIDDLE
	dc.w 4,  64, $3, $A000|SPR_BUS_STOP_SIGN_BOTTOM

DATA_spritemap_light_pole:
	dc.w 0,   0, $9, $0000|SPR_LIGHT_POLE_TOP
	dc.w 0,  16, $3, $0000|SPR_LIGHT_POLE_MIDDLE
	dc.w 0,  48, $3, $0000|SPR_LIGHT_POLE_MIDDLE
	dc.w 0,  80, $3, $0000|SPR_LIGHT_POLE_MIDDLE
	dc.w 0, 112, $2, $0000|SPR_LIGHT_POLE_BOTTOM

DATA_spritemap_bus_door:
	dc.w 0,   0, $B, $6000|SPR_BUS_DOOR_1_TOP
	dc.w 16,  0, $B, $6800|SPR_BUS_DOOR_1_TOP
	dc.w 0,  32, $A, $6000|SPR_BUS_DOOR_1_MIDDLE
	dc.w 16, 32, $A, $6800|SPR_BUS_DOOR_1_MIDDLE
	dc.w 0,  52, $B, $7000|SPR_BUS_DOOR_1_TOP
	dc.w 16, 52, $B, $7800|SPR_BUS_DOOR_1_TOP
	dc.w 0,   0, $0, $0000
	dc.w 0,   0, $0, $0000

	dc.w 0,   0, $7, $6000|SPR_BUS_DOOR_2_TOP
	dc.w 24,  0, $7, $6800|SPR_BUS_DOOR_2_TOP
	dc.w 0,  32, $6, $6000|SPR_BUS_DOOR_2_MIDDLE
	dc.w 24, 32, $6, $6800|SPR_BUS_DOOR_2_MIDDLE
	dc.w 0,  52, $7, $7000|SPR_BUS_DOOR_2_TOP
	dc.w 24, 52, $7, $7800|SPR_BUS_DOOR_2_TOP
	dc.w 0,   0, $0, $0000
	dc.w 0,   0, $0, $0000

	dc.w 0,   0, $3, $6000|SPR_BUS_DOOR_3_TOP
	dc.w 32,  0, $3, $6800|SPR_BUS_DOOR_3_TOP
	dc.w 0,  32, $2, $6000|SPR_BUS_DOOR_3_MIDDLE
	dc.w 32, 32, $2, $6800|SPR_BUS_DOOR_3_MIDDLE
	dc.w 0,  52, $3, $7000|SPR_BUS_DOOR_3_TOP
	dc.w 32, 52, $3, $7800|SPR_BUS_DOOR_3_TOP
	dc.w 0,   0, $0, $0000
	dc.w 0,   0, $0, $0000

	dc.w 0,   0, $3, $6000|SPR_BUS_DOOR_4_TOP
	dc.w 32,  0, $3, $6800|SPR_BUS_DOOR_4_TOP
	dc.w 0,  32, $2, $6000|SPR_BUS_DOOR_4_MIDDLE
	dc.w 32, 32, $2, $6800|SPR_BUS_DOOR_4_MIDDLE
	dc.w 0,  52, $3, $7000|SPR_BUS_DOOR_4_TOP
	dc.w 32, 52, $3, $7800|SPR_BUS_DOOR_4_TOP
	dc.w 0,   0, $0, $0000
	dc.w 0,   0, $0, $0000

DATA_spritemap_bus_route_sign:
	; Goal
	dc.w 0, 4, $5, $0000|SPR_BUS_ROUTE_SIGN_GOAL

	; 2
	dc.w 0, 4, $5, $0000|SPR_BUS_ROUTE_SIGN_2

	; 3
	dc.w 0, 4, $5, $0000|SPR_BUS_ROUTE_SIGN_3

	; 4
	dc.w 0, 4, $5, $0000|SPR_BUS_ROUTE_SIGN_4

	; 5
	dc.w 0, 4, $5, $0000|SPR_BUS_ROUTE_SIGN_5

DATA_spritemap_banana_peel:
	dc.w 0, 0, $0, $A000|SPR_BANANA_PEEL

DATA_spritemap_coin_spark_silver:
	dc.w 0, 0, $0, $0000
	dc.w 0, 0, $0, $8000|SPR_SPARK_SILVER_3
	dc.w 0, 0, $0, $8000|SPR_SPARK_SILVER_2
	dc.w 0, 0, $0, $8000|SPR_SPARK_SILVER_1

DATA_spritemap_coin_spark_gold:
	dc.w 0, 0, $0, $0000
	dc.w 0, 0, $0, $C000|SPR_SPARK_GOLD_3
	dc.w 0, 0, $0, $C000|SPR_SPARK_GOLD_2
	dc.w 0, 0, $0, $C000|SPR_SPARK_GOLD_1

DATA_spritemap_crate:
	dc.w 0, 0, $6, $0000|SPR_CRATE
	dc.w 8, 0, $6, $1800|SPR_CRATE

DATA_spritemap_gush_crack:
	dc.w 0, 0, $4, $0000|SPR_GUSH_CRACK

DATA_spritemap_rope_vertical:
	dc.w 0,  0, $3, $0000|SPR_VERTICAL_ROPE_TOP
	dc.w 0, 32, $1, $0000|SPR_VERTICAL_ROPE_BOTTOM

DATA_spritemap_deep_hole_left_fg:
	dc.w 0, 0, $9, $0000|SPR_DEEP_HOLE_LEFT_FG

DATA_spritemap_passageway_left_fg:
	dc.w 0, 0, $9, $0000|SPR_PASSAGEWAY_LEFT_FG

DATA_spritemap_passageway_right_fg:
	dc.w 0, 0, $9, $0000|SPR_PASSAGEWAY_RIGHT_FG

DATA_spritemap_passageway_closed_exit:
	dc.w 0, 0, $9, $0000|SPR_PASSAGEWAY_RIGHT_CLOSED

DATA_spritemap_spring:
	dc.w 0, 0, $1, $2000|SPR_SPRING_2
	dc.w 8, 0, $1, $2800|SPR_SPRING_2

	dc.w 0, 0, $1, $2000|SPR_SPRING_3
	dc.w 8, 0, $1, $2800|SPR_SPRING_3

	dc.w 0, 0, $1, $2000|SPR_SPRING_4
	dc.w 8, 0, $1, $2800|SPR_SPRING_4

	dc.w 0, 0, $1, $2000|SPR_SPRING_3
	dc.w 8, 0, $1, $2800|SPR_SPRING_3

	dc.w 0, 0, $1, $2000|SPR_SPRING_2
	dc.w 8, 0, $1, $2800|SPR_SPRING_2

	dc.w 0, 0, $1, $2000|SPR_SPRING_1
	dc.w 8, 0, $1, $2800|SPR_SPRING_1

DATA_spritemap_truck_wheel:
	; Note: truck and bus wheels use the same sprite
	dc.w 0, 0, $E, $0000|SPR_BUS_WHEEL_1
	dc.w 0, 0, $E, $0000|SPR_BUS_WHEEL_2
	dc.w 0, 0, $E, $0000|SPR_BUS_WHEEL_3
	dc.w 0, 0, $0, $0000

DATA_spritemap_car:
	; Blue car
	dc.w 24,  0, $D, $6000|SPR_CAR_TOP_1
	dc.w 56,  0, $D, $6000|SPR_CAR_TOP_2
	dc.w 0,  16, $F, $6000|SPR_CAR_MIDDLE_1
	dc.w 32, 16, $F, $6000|SPR_CAR_MIDDLE_2
	dc.w 64, 16, $F, $6000|SPR_CAR_MIDDLE_3
	dc.w 96, 16, $F, $6000|SPR_CAR_MIDDLE_4
	dc.w 16, 48, $8, $0000|SPR_CAR_WHEEL_BOTTOM
	dc.w 96, 48, $8, $0000|SPR_CAR_WHEEL_BOTTOM

	; Silver car
	dc.w 24,  0, $D, $4000|SPR_CAR_TOP_1
	dc.w 56,  0, $D, $4000|SPR_CAR_TOP_2
	dc.w 0,  16, $F, $4000|SPR_CAR_MIDDLE_1
	dc.w 32, 16, $F, $4000|SPR_CAR_MIDDLE_2
	dc.w 64, 16, $F, $4000|SPR_CAR_MIDDLE_3
	dc.w 96, 16, $F, $4000|SPR_CAR_MIDDLE_4
	dc.w 16, 48, $8, $0000|SPR_CAR_WHEEL_BOTTOM
	dc.w 96, 48, $8, $0000|SPR_CAR_WHEEL_BOTTOM

	; Yellow car
	dc.w 24,  0, $D, $2000|SPR_CAR_TOP_1
	dc.w 56,  0, $D, $2000|SPR_CAR_TOP_2
	dc.w 0,  16, $F, $2000|SPR_CAR_MIDDLE_1
	dc.w 32, 16, $F, $2000|SPR_CAR_MIDDLE_2
	dc.w 64, 16, $F, $2000|SPR_CAR_MIDDLE_3
	dc.w 96, 16, $F, $2000|SPR_CAR_MIDDLE_4
	dc.w 16, 48, $8, $0000|SPR_CAR_WHEEL_BOTTOM
	dc.w 96, 48, $8, $0000|SPR_CAR_WHEEL_BOTTOM

DATA_spritemap_car_wheels:
	dc.w 0, 0, $1, $0000|SPR_CAR_WHEEL_MIDDLE_1
	dc.w 0, 0, $1, $0000|SPR_CAR_WHEEL_MIDDLE_2

DATA_spritemap_hen:
	dc.w 0,  0, $D, $2000|SPR_HEN_UPPER_BODY
	dc.w 6, 16, $4, $2000|SPR_HEN_LEGS_1

	dc.w 0,  0, $D, $2000|SPR_HEN_UPPER_BODY
	dc.w 6, 16, $4, $2000|SPR_HEN_LEGS_2

	dc.w 0,  0, $D, $2000|SPR_HEN_UPPER_BODY
	dc.w 6, 16, $4, $2000|SPR_HEN_LEGS_3

	dc.w 0,  0, $D, $2000|SPR_HEN_UPPER_BODY
	dc.w 6, 16, $4, $2000|SPR_HEN_LEGS_2

DATA_spritemap_crack_particles:
	dc.w 0, 0, $0, $0000|SPR_CRACK_PARTICLE_1
	dc.w 0, 0, $0, $0000|SPR_CRACK_PARTICLE_2

DATA_spritemap_push_arrow:
	dc.w 0,  0, $E, $0000|SPR_PUSH_ARROW_1
	dc.w 32, 0, $3, $0000|SPR_PUSH_ARROW_2

DATA_spritemap_bus_character_1:
	dc.w 8,   0, $1, $6000|SPR_BUS_CHARACTER_1_HEAD
	dc.w 9,   0, $1, $6800|SPR_BUS_CHARACTER_1_HEAD
	dc.w 6,  16, $2, $6000|SPR_BUS_CHARACTER_1_TORSO
	dc.w 11, 16, $2, $6800|SPR_BUS_CHARACTER_1_TORSO
	dc.w 6,  40, $2, $6000|SPR_BUS_CHARACTER_1_LEGS
	dc.w 11, 40, $2, $6800|SPR_BUS_CHARACTER_1_LEGS

DATA_spritemap_bus_character_2:
	dc.w 6,   8, $1, $4000|SPR_BUS_CHARACTER_2_HEAD
	dc.w 11,  8, $1, $4800|SPR_BUS_CHARACTER_2_HEAD
	dc.w 6,  24, $1, $4000|SPR_BUS_CHARACTER_2_TORSO
	dc.w 11, 24, $1, $4800|SPR_BUS_CHARACTER_2_TORSO
	dc.w 6,  40, $2, $4000|SPR_BUS_CHARACTER_2_LEGS
	dc.w 11, 40, $2, $4800|SPR_BUS_CHARACTER_2_LEGS

DATA_spritemap_bus_character_3:
	dc.w 8,   0, $1, $4000|SPR_BUS_CHARACTER_3_HEAD
	dc.w 9,   0, $1, $4800|SPR_BUS_CHARACTER_3_HEAD
	dc.w 6,  16, $2, $4000|SPR_BUS_CHARACTER_3_TORSO
	dc.w 11, 16, $2, $4800|SPR_BUS_CHARACTER_3_TORSO
	dc.w 6,  40, $2, $4000|SPR_BUS_CHARACTER_3_LEGS
	dc.w 11, 40, $2, $4800|SPR_BUS_CHARACTER_3_LEGS

DATA_spritemap_bearded_man_stand:
	dc.w 14,  0, $1, $6000|SPR_BEARDED_MAN_HEAD
	dc.w 14,  9, $3, $6000|SPR_BEARDED_MAN_TORSO_1
	dc.w 8,  33, $7, $6800|SPR_PLAYER_LEGS_1
	dc.w 0,   0, $0, 0

DATA_spritemap_bearded_man_walk:
	; Frame 1
	dc.w 14,  0, $1, $6000|SPR_BEARDED_MAN_HEAD
	dc.w 14,  9, $7, $6000|SPR_BEARDED_MAN_TORSO_2
	dc.w 0,  33, $F, $6800|SPR_PLAYER_LEGS_2
	dc.w 0,   0, $0, 0

	; Frame 2
	dc.w 14,  0, $1, $6000|SPR_BEARDED_MAN_HEAD
	dc.w 14,  9, $7, $6000|SPR_BEARDED_MAN_TORSO_3
	dc.w 8,  33, $B, $6800|SPR_PLAYER_LEGS_3
	dc.w 0,   0, $0, 0

	; Frame 3
	dc.w 14,  0, $1, $6000|SPR_BEARDED_MAN_HEAD
	dc.w 14,  9, $7, $6000|SPR_BEARDED_MAN_TORSO_2
	dc.w 8,  33, $7, $6800|SPR_PLAYER_LEGS_4
	dc.w 0,   0, $0, 0

	; Frame 4
	dc.w 14,  0, $1, $6000|SPR_BEARDED_MAN_HEAD
	dc.w 14,  9, $3, $6000|SPR_BEARDED_MAN_TORSO_1
	dc.w 0,  33, $F, $6800|SPR_PLAYER_LEGS_5
	dc.w 0,   0, $0, 0

	; Frame 5
	dc.w 14,  0, $1, $6000|SPR_BEARDED_MAN_HEAD
	dc.w 10,  9, $7, $6000|SPR_BEARDED_MAN_TORSO_4
	dc.w 8,  33, $B, $6800|SPR_PLAYER_LEGS_6
	dc.w 0,   0, $0, 0

	; Frame 6
	dc.w 14,  0, $1, $6000|SPR_BEARDED_MAN_HEAD
	dc.w 14,  9, $3, $6000|SPR_BEARDED_MAN_TORSO_1
	dc.w 8,  33, $7, $6800|SPR_PLAYER_LEGS_7
	dc.w 0,   0, $0, 0

DATA_spritemap_bearded_man_jump:
	dc.w 14,  0, $1, $6000|SPR_BEARDED_MAN_HEAD
	dc.w 14,  9, $3, $6000|SPR_BEARDED_MAN_TORSO_1
	dc.w 8,  33, $7, $6800|SPR_PLAYER_LEGS_8
	dc.w 0,   0, $0, 0

DATA_spritemap_player_clean_dung:
	; Frame 1
	dc.w 11, 10, $0, $0000|SPR_BIRD_DUNG_2
	dc.w 11,  0, $0, $A000|SPR_PLAYER_HEAD
	dc.w 7,   8, $6, $A000|SPR_PLAYER_TORSO_1
	dc.w 8,  32, $7, $A000|SPR_PLAYER_LEGS_1
	dc.w 0,   0, $0, 0
	dc.w 0,   0, $0, 0
	dc.w 0,   0, $0, 0
	dc.w 0,   0, $0, 0

	; Frame 2
	dc.w 11, 10, $0, $0000|SPR_BIRD_DUNG_3
	dc.w 12,  0, $0, $A000|SPR_PLAYER_HEAD_FRONT
	dc.w 7,   8, $6, $A000|SPR_PLAYER_CLEANING_1
	dc.w 16, 32, $0, $A000|SPR_PLAYER_CLEANING_HAND
	dc.w 7,  32, $7, $A000|SPR_PLAYER_CLEANING_LEGS
	dc.w 0,   0, $0, 0
	dc.w 0,   0, $0, 0
	dc.w 0,   0, $0, 0

	; Frame 3
	dc.w 11, 10, $0, $0000|SPR_BIRD_DUNG_3
	dc.w 12,  0, $0, $A000|SPR_PLAYER_HEAD_FRONT
	dc.w 7,   8, $6, $A000|SPR_PLAYER_CLEANING_2
	dc.w 7,  32, $7, $A000|SPR_PLAYER_CLEANING_LEGS
	dc.w 0,   0, $0, 0
	dc.w 0,   0, $0, 0
	dc.w 0,   0, $0, 0
	dc.w 0,   0, $0, 0

	; Frame 4
	dc.w 12,  0, $0, $A000|SPR_PLAYER_HEAD_FRONT
	dc.w 7,   8, $6, $A000|SPR_PLAYER_CLEANING_3
	dc.w 7,  32, $7, $A000|SPR_PLAYER_CLEANING_LEGS
	dc.w 0,   0, $0, 0
	dc.w 0,   0, $0, 0
	dc.w 0,   0, $0, 0
	dc.w 0,   0, $0, 0
	dc.w 0,   0, $0, 0

	; Frame 5
	dc.w 12,  0, $0, $A000|SPR_PLAYER_HEAD_FRONT
	dc.w 7,   8, $6, $A000|SPR_PLAYER_CLEANING_4
	dc.w 7,  32, $7, $A000|SPR_PLAYER_CLEANING_LEGS
	dc.w 0,   0, $0, 0
	dc.w 0,   0, $0, 0
	dc.w 0,   0, $0, 0
	dc.w 0,   0, $0, 0
	dc.w 0,   0, $0, 0

	; Frame 6
	dc.w 12,  0, $0, $A000|SPR_PLAYER_HEAD_FRONT
	dc.w 7,   8, $6, $A000|SPR_PLAYER_CLEANING_3
	dc.w 7,  32, $7, $A000|SPR_PLAYER_CLEANING_LEGS
	dc.w 0,   0, $0, 0
	dc.w 0,   0, $0, 0
	dc.w 0,   0, $0, 0
	dc.w 0,   0, $0, 0
	dc.w 0,   0, $0, 0

	; Frame 7
	dc.w 12,  0, $0, $A000|SPR_PLAYER_HEAD_FRONT
	dc.w 7,   8, $6, $A000|SPR_PLAYER_CLEANING_4
	dc.w 7,  32, $7, $A000|SPR_PLAYER_CLEANING_LEGS
	dc.w 0,   0, $0, 0
	dc.w 0,   0, $0, 0
	dc.w 0,   0, $0, 0
	dc.w 0,   0, $0, 0
	dc.w 0,   0, $0, 0

	; Frame 8
	dc.w 12,  0, $0, $A000|SPR_PLAYER_HEAD_FRONT
	dc.w 7,   8, $6, $A000|SPR_PLAYER_CLEANING_2
	dc.w 7,  32, $7, $A000|SPR_PLAYER_CLEANING_LEGS
	dc.w 0,   0, $0, 0
	dc.w 0,   0, $0, 0
	dc.w 0,   0, $0, 0
	dc.w 0,   0, $0, 0
	dc.w 0,   0, $0, 0

	; Frame 9
	dc.w 12,  0, $0, $A000|SPR_PLAYER_HEAD_FRONT
	dc.w 7,   8, $6, $A000|SPR_PLAYER_CLEANING_1
	dc.w 16, 32, $0, $A000|SPR_PLAYER_CLEANING_HAND
	dc.w 7,  32, $7, $A000|SPR_PLAYER_CLEANING_LEGS
	dc.w 0,   0, $0, 0
	dc.w 0,   0, $0, 0
	dc.w 0,   0, $0, 0
	dc.w 0,   0, $0, 0

DATA_spritemap_player_run:
	; Frame 1
	dc.w 19,  0, $0, $A000|SPR_PLAYER_HEAD
	dc.w 16,  8, $6, $A000|SPR_PLAYER_RUN_UPPER_BODY
	dc.w 0,  14, $5, $A000|SPR_PLAYER_RUN_ARM
	dc.w 0,  32, $F, $A000|SPR_PLAYER_RUN_LEGS_1
	dc.w 32, 51, $1, $A000|SPR_PLAYER_RUN_FOOT_1
	dc.w 0,   0, $0, 0
	dc.w 0,   0, $0, 0
	dc.w 0,   0, $0, 0

	; Frame 2
	dc.w 19,  0, $0, $A000|SPR_PLAYER_HEAD
	dc.w 16,  8, $6, $A000|SPR_PLAYER_RUN_UPPER_BODY
	dc.w 0,  14, $5, $A000|SPR_PLAYER_RUN_ARM
	dc.w 8,  32, $B, $A000|SPR_PLAYER_RUN_LEGS_2
	dc.w 0,   0, $0, 0
	dc.w 0,   0, $0, 0
	dc.w 0,   0, $0, 0
	dc.w 0,   0, $0, 0

	; Frame 3
	dc.w 19,  0, $0, $A000|SPR_PLAYER_HEAD
	dc.w 16,  8, $6, $A000|SPR_PLAYER_RUN_UPPER_BODY
	dc.w 0,  14, $5, $A000|SPR_PLAYER_RUN_ARM
	dc.w 0,  32, $F, $A000|SPR_PLAYER_RUN_LEGS_3
	dc.w 32, 51, $1, $A000|SPR_PLAYER_RUN_FOOT_2
	dc.w 0,   0, $0, 0
	dc.w 0,   0, $0, 0
	dc.w 0,   0, $0, 0

	; Frame 4
	dc.w 19,  0, $0, $A000|SPR_PLAYER_HEAD
	dc.w 16,  8, $6, $A000|SPR_PLAYER_RUN_UPPER_BODY
	dc.w 0,  14, $5, $A000|SPR_PLAYER_RUN_ARM
	dc.w 8,  32, $B, $A000|SPR_PLAYER_RUN_LEGS_4
	dc.w 0,   0, $0, 0
	dc.w 0,   0, $0, 0
	dc.w 0,   0, $0, 0
	dc.w 0,   0, $0, 0

DATA_spritemap_bird:
	dc.w 0,   0, $4, $0000|SPR_BIRD_1
	dc.w 0,   0, $4, $0000|SPR_BIRD_2
	dc.w 0,   0, $4, $0000|SPR_BIRD_3
	dc.w 0,   0, $4, $0000|SPR_BIRD_2

DATA_spritemap_dung:
	dc.w 0,   0, $0, $0000|SPR_BIRD_DUNG_1

DATA_spritemap_flagman:
	dc.w 40, 32, $5, $2000|SPR_FLAGMAN_ARM_2
	dc.w 52, 30, $7, $2000|SPR_FLAGMAN_UPPER_BODY
	dc.w 52, 62, $7, $2000|SPR_FLAGMAN_LOWER_BODY
	dc.w 16, 16, $E, $2000|SPR_FLAGMAN_FLAG_2

	dc.w 32, 40, $8, $2000|SPR_FLAGMAN_ARM_1
	dc.w 52, 30, $7, $2000|SPR_FLAGMAN_UPPER_BODY
	dc.w 52, 62, $7, $2000|SPR_FLAGMAN_LOWER_BODY
	dc.w 12, 40, $A, $2000|SPR_FLAGMAN_FLAG_1

	dc.w 40, 32, $5, $2000|SPR_FLAGMAN_ARM_2
	dc.w 52, 30, $7, $2000|SPR_FLAGMAN_UPPER_BODY
	dc.w 52, 62, $7, $2000|SPR_FLAGMAN_LOWER_BODY
	dc.w 16, 16, $E, $2000|SPR_FLAGMAN_FLAG_2

	dc.w 48, 24, $2, $2000|SPR_FLAGMAN_ARM_3
	dc.w 52, 30, $7, $2000|SPR_FLAGMAN_UPPER_BODY
	dc.w 52, 62, $7, $2000|SPR_FLAGMAN_LOWER_BODY
	dc.w 32,  2, $A, $2000|SPR_FLAGMAN_FLAG_3

DATA_spritemap_ending_medal_1:
	dc.w 7,   7, $5, $2000|SPR_ENDING_MEDAL_1
	dc.w 0,   0, $B, $0000|SPR_ENDING_MEDAL_CONTAINER

DATA_spritemap_ending_medal_2:
	dc.w 7,   7, $5, $4000|SPR_ENDING_MEDAL_2
	dc.w 0,   0, $B, $0000|SPR_ENDING_MEDAL_CONTAINER

DATA_spritemap_ending_medal_3:
	dc.w 7,   7, $5, $2000|SPR_ENDING_MEDAL_3
	dc.w 0,   0, $B, $0000|SPR_ENDING_MEDAL_CONTAINER

