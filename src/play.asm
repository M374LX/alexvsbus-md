;
; Alex vs Bus (MD port)
; Copyright (C) 2021-2026 M374LX
;
; This program is free software: you can redistribute it and/or modify
; it under the terms of the GNU General Public License as published by
; the Free Software Foundation, either version 3 of the License, or
; (at your option) any later version.
;
; This program is distributed in the hope that it will be useful,
; but WITHOUT ANY WARRANTY; without even the implied warranty of
; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
; GNU General Public License for more details.
;
; You should have received a copy of the GNU General Public License
; along with this program.  If not, see <https://www.gnu.org/licenses/>.
;

;
; File:
; play.asm
;
; Description:
; Implementation of gameplay logic
;

; ------------------------------------------------------------------------------

play_clear:
	moveq   #0, d0
	moveq   #0, d1
	lea     (RAM_play_clear_start).w, a0
	move.w  #((RAM_play_clear_end-RAM_play_clear_start)/4)-1, d1
.play_clear_loop:
	move.l  d0, (a0)+
	dbf     d1, .play_clear_loop

	bset.b  #0, (RAM_play_flags).w ; Set "ignore user input" flag

	move.b  #$90, (RAM_time).w
	move.b  (FPSVAL_0_7_S).w, (RAM_crate_push_remaining).w

	; Set player initial position
	move.w  #96,  (RAM_player_x).w
	move.w  #204, (RAM_player_y).w

	; Set player initial state
	move.b  #NONE, (RAM_player_old_state).w
	clr.b   (RAM_player_state).w
	bsr     handle_player_state_change

	move.l  #(24<<16), (RAM_bus_x).w
	move.w  #24, (RAM_bus_init_x).w

	moveq   #NONE, d0

	move.b  d0, (RAM_grabbed_rope_obj).w
	move.b  d0, (RAM_cur_passageway).w

	; Clear moving banana peels
	move.b  d0, (RAM_moving_peels+(32*0+24)).w
	move.b  d0, (RAM_moving_peels+(32*1+24)).w

	; Make passing car and hen inactive
	move.l  d0, (RAM_passing_car_x).w
	move.l  d0, (RAM_hen_x).w

	; Clear gushes
	clr.b   (RAM_num_gushes).w
	lea     (RAM_gushes+12).w, a0
	moveq   #MAX_GUSHES-1, d7
.gushes_clear_loop:
	move.b  d0, (a0)
	lea     16(a0), a0
	dbf     d7, .gushes_clear_loop

	; Clear pushable crates
	lea     (RAM_pushable_crates+7).w, a0
	rept    MAX_PUSHABLE_CRATES
	move.b  d0, (a0)
	addq    #8, a0
	endr

	; Initialize animations
	moveq   #0, d0
	moveq   #NUM_ANIMS-1, d7
	lea     (RAM_anims).w, a0
	lea     DATA_anims_init, a1
.anims_init_loop:
	; Find delay
	movea.w (a1)+, a2
	move.b  (a2), d0

	move.b  (a1)+, 1(a0) ; Last frame (number of frames minus one)
	move.b  d0, 2(a0)    ; Delay
	move.b  d0, 3(a0)    ; Maximum delay
	move.b  (a1)+, 4(a0) ; Flags

	; Next animation
	addq.w  #ANIM_SIZE_BYTES, a0
	dbf     d7, .anims_init_loop

	move.b  (FPSVAL_1_S).w, (RAM_push_arrow_delay).w

	rts

; ------------------------------------------------------------------------------

play_set_input:
	; If user input is ignored, skip
	btst.b  #0, (RAM_play_flags).w
	bne.s   .ret

	; Store the previous state in d2
	move.b  (RAM_play_input_down).w, d2

	moveq   #0, d0
	move.w  (RAM_joystate_down).w, d1

	btst.l  #2, d1
	beq.s   .no_left
	bset.l  #PLAY_INPUT_LEFT, d0
.no_left:

	btst.l  #3, d1
	beq.s   .no_right
	bset.l  #PLAY_INPUT_RIGHT, d0
.no_right:

	andi.w  #$70, d1 ; A/B/C buttons
	beq.s   .no_jump
	bset.l  #PLAY_INPUT_JUMP, d0
.no_jump:

	move.b  d0, (RAM_play_input_down).w

	; Store hit buttons
	not.b   d2
	and.b   d0, d2
	move.b  d2, (RAM_play_input_hit).w

	; Check if the jump timeout needs to be reset
	btst.l  #PLAY_INPUT_JUMP, d2
	beq.s   .ret
	move.b  (FPSVAL_0_2_S).w, (RAM_jump_timeout).w

.ret:
	rts

; ------------------------------------------------------------------------------

play_update:
	bsr     begin_update
	bsr     update_remaining_time
	bsr     update_score_count
	bsr     move_objects
	bsr     handle_car_thrown_peel
	bsr     move_player
	bsr     handle_solids
	bsr     handle_passageways
	bsr     handle_player_interactions
	bsr     handle_triggers
	bsr     do_player_state_specifics
	bsr     handle_fall_sound
	bsr     handle_respawn
	bsr     handle_player_state_change
	bsr     move_camera
	bsr     keep_player_within_limits
	bsr     handle_player_animation_change
	bsr     update_animations
	bsr     move_push_arrow
	bra     update_sequence

; ------------------------------------------------------------------------------

position_camera:
	tst.b   (RAM_camera_follow_player).w
	beq.s   .horizontal_done
	tst.l   (RAM_camera_xvel).w
	bne.s   .horizontal_done

	move.w  (RAM_camera_x).w, d0
	addi.w  #104, d0
	cmp.w   (RAM_player_x).w, d0
	ble.s   .move_right

	move.w  (RAM_camera_x).w, d0
	addi.w  #32, d0
	cmp.w   (RAM_player_x).w, d0
	bge.s   .move_left
	bra.s   .horizontal_done

.move_right:
	move.l  (RAM_player_x).w, d0
	subi.l  #104<<16, d0
	move.l  d0, (RAM_camera_x).w

	bra.s   .horizontal_done

.move_left:
	move.l  (RAM_player_x).w, d0
	subi.l  #32<<16, d0
	move.l  d0, (RAM_camera_x).w
.horizontal_done:

	; Keep camera within level boundaries
	move.w  (RAM_camera_x).w, d0

	; Check camera left limit
	move.w  #40, d1
	cmp.w   d1, d0
	ble.s   .apply_camera_limit

	; Check camera right limit
	move.w  (RAM_camera_xmax).w, d1
	cmp.w   d1, d0
	bge.s   .apply_camera_limit

	bra.s   .skip_camera_limit

.apply_camera_limit:
	move.w  d1, (RAM_camera_x).w
	clr.w   (RAM_camera_x+2).w
	clr.l   (RAM_camera_xvel).w

.skip_camera_limit:
	rts

; ------------------------------------------------------------------------------

; Input:
; d0.w - x
; d1.w - y
;
; Breaks: d0-d3, a0
add_crack_particles:
	moveq   #0, d2
	move.b  (RAM_next_crack_particle).w, d2

	; Convert position from single words to 16.16 fixed point
	swap    d0
	clr.w   d0
	swap    d1
	clr.w   d1

	move.l  d2, d3
	add.w   d3, d3
	add.w   d3, d3
	add.w   d3, d3
	add.w   d3, d3
	lea     (RAM_crack_particles).w, a0
	adda.w  d3, a0

	; Particle #1
	move.l  d0, (a0)+
	move.l  d1, (a0)+
	move.l  (FPSVAL_M15_PXS).w, (a0)+
	move.l  (FPSVAL_M120_PXS).w, (a0)+

	addi.w  #16, d3
	andi.w  #((16*16)-1), d3
	lea     (RAM_crack_particles).w, a0
	adda.w  d3, a0

	; Particle #2
	move.l  d0, (a0)+
	move.l  d1, (a0)+
	move.l  (FPSVAL_M6_PXS).w, (a0)+
	move.l  (FPSVAL_M192_PXS).w, (a0)+

	addi.w  #16, d3
	andi.w  #((16*16)-1), d3
	lea     (RAM_crack_particles).w, a0
	adda.w  d3, a0

	; Particle #3
	move.l  d0, (a0)+
	move.l  d1, (a0)+
	move.l  (FPSVAL_15_PXS).w, (a0)+
	move.l  (FPSVAL_M120_PXS).w, (a0)+

	addi.w  #16, d3
	andi.w  #((16*16)-1), d3
	lea     (RAM_crack_particles).w, a0
	adda.w  d3, a0

	; Particle #4
	move.l  d0, (a0)+
	move.l  d1, (a0)+
	move.l  (FPSVAL_6_PXS).w, (a0)+
	move.l  (FPSVAL_M192_PXS).w, (a0)+

	addq.b  #4, d2
	andi.b  #16-1, d2
	move.b  d2, (RAM_next_crack_particle).w
	
	rts

; ------------------------------------------------------------------------------

move_bus_to_end:
	clr.l   (RAM_bus_acc).w
	clr.l   (RAM_bus_xvel).w

	move.w  (RAM_level_size_pixels).w, d0
	subi.w  #456, d0
	move.w  d0, (RAM_bus_x).w
	clr.w   (RAM_bus_x+2).w
	move.w  d0, (RAM_bus_init_x).w

	; Make rear door closed
	lea     (RAM_anims+ANIM_BUS_DOOR_REAR).w, a0
	clr.b   (a0)      ; Current frame
	move.b  #3, 1(a0) ; Last frame
	clr.b   4(a0)     ; Flags (not running, no reverse, no loop)

	; Make front door open
	lea     (RAM_anims+ANIM_BUS_DOOR_FRONT).w, a0
	move.b  #3, (a0)  ; Current frame
	move.b  #3, 1(a0) ; Last frame
	move.b  #2, 4(a0) ; Flags (not running, reverse, no loop)

	; Set bus route sign for the bus at the end of the level
	; Note: zero refers to the goal sign and, since there is no sign numbered
	; 1, the value 1 refers to sign 2 while the value 2 refers to sign 3 and
	; so on; so, if the level number is 1, the displayed sign is 2
	move.b  (RAM_level_num).w, (RAM_bus_route_sign).w
	btst.b  #6, (RAM_play_flags).w ; Check "last level" flag
	beq.s   .not_last_level
	clr.b   (RAM_bus_route_sign).w ; Display goal sign
.not_last_level:

	rts

; ------------------------------------------------------------------------------

show_player_in_bus:
	lea     (RAM_cutscene_objs).w, a0

	move.b  #COBJ_PLAYER_STAND, (a0)+
	st.b    (a0)+
	move.w  #342, (a0)+
	clr.w   (a0)+
	move.w  #(BUS_Y+36), (a0)+
	clr.w   (a0)+

	move.b  #PLAYER_STATE_INACTIVE, (RAM_player_state).w

	; Clear "visible" flag
	bclr.b  #0, (RAM_player_flags).w

	rts

; ------------------------------------------------------------------------------

start_score_count:
	bset.b  #4, (RAM_play_flags).w ; Set "counting score" flag
	move.b  (FPSVAL_0_1_S).w, (RAM_time_delay).w

	rts

; ------------------------------------------------------------------------------

begin_update:
	move.l  (RAM_player_x).w, (RAM_player_old_x).w
	move.l  (RAM_player_y).w, (RAM_player_old_y).w
	move.b  (RAM_player_state).w, (RAM_player_old_state).w
	move.b  (RAM_player_anim_type).w, (RAM_player_old_anim_type).w
	bclr.b  #1, (RAM_player_flags).w ; Clear "on floor" flag

	tst.b   (RAM_jump_timeout).w
	ble.s   .ret
	subq.b  #1, (RAM_jump_timeout).w

.ret:
	rts

; ------------------------------------------------------------------------------

update_remaining_time:
	; If time is not running, skip
	btst.b  #1, (RAM_play_flags).w
	beq.s   .ret

	subq.b  #1, (RAM_time_delay).w ; Subtract one from delay
	bgt.s   .ret                   ; If the delay has not ended, skip

	move.b  (FPSVAL_1_S).w, (RAM_time_delay).w ; Reset delay

	; If time is not over, skip
	tst.b   (RAM_time).w
	bne.s   .time_not_over

	bclr.b  #1, (RAM_play_flags).w ; Unset "time running" flag
	bset.b  #2, (RAM_play_flags).w ; Set "time up" flag

	rts

.time_not_over:
	; Subtract one from remaining time (BCD)
	andi.b  #0, ccr
	move.b  (RAM_time).w, d0
	moveq   #1, d1
	sbcd.b  d1, d0
	move.b  d0, (RAM_time).w

	cmpi.b  #$10, d0
	bhi.s   .ret

	move.w  #SFX_TIME, d0
	bsr     sound_play_sfx

.ret:
	rts

; ------------------------------------------------------------------------------

update_score_count:
	btst.b  #4, (RAM_play_flags).w ; Test "counting score" flag
	beq.s   .ret
	tst.b   (RAM_time_delay).w
	beq.s   .no_delay

	subq.b  #1, (RAM_time_delay).w

.ret:
	rts

.no_delay:
	move.b  (FPSVAL_0_1_S).w, (RAM_time_delay).w

	tst.b   (RAM_time).w
	bhi.s   .count_not_over

	bclr.b  #4, (RAM_play_flags).w ; Clear "counting score" flag
	rts

.count_not_over:
	; Subtract one from remaining time (BCD)
	andi.b  #0, ccr
	move.b  (RAM_time).w, d0
	moveq   #1, d1
	sbcd.b  d1, d0
	move.b  d0, (RAM_time).w

	; Add 10 to score (BCD)
	move.l  #$10, (RAM_score_add).w
	lea     (RAM_score+4).w, a0
	lea     (RAM_score_add+4).w, a1
	andi.b  #0, ccr
	abcd.b  -(a1), -(a0)
	abcd.b  -(a1), -(a0)
	abcd.b  -(a1), -(a0)
	abcd.b  -(a1), -(a0)

	move.w  #SFX_SCORE, d0
	bra     sound_play_sfx

; ------------------------------------------------------------------------------

move_objects:
	; Bus
	move.l  (RAM_bus_acc).w, d0
	add.l   d0, (RAM_bus_xvel).w
	move.l  (RAM_bus_xvel).w, d0
	add.l   d0, (RAM_bus_x).w

	; Moving banana peels
	moveq   #MAX_MOVING_PEELS-1, d7
	lea     (RAM_moving_peels).w, a0
.moving_peels_loop:
	; Move index of peel object within RAM_objs to d0
	moveq   #0, d0
	move.b  24(a0), d0

	; If there is no object, skip
	cmpi.b  #NONE, d0
	beq     .next_peel

	; Point a1 to the object within RAM_objs
	add.w   d0, d0
	add.w   d0, d0
	add.w   d0, d0
	lea     (RAM_objs).w, a1
	adda.w  d0, a1

	; Apply gravity
	move.l  16(a0), d0
	add.l   d0, 12(a0)

	; Update position
	move.l  8(a0), d0
	add.l   d0, (a0)
	move.l  12(a0), d0
	add.l   d0, 4(a0)

	; Check if the peel had reached the limit Y position or ydest
	move.w  4(a0), d0
	cmpi.w  #400, d0
	bgt     .deactivate_peel
	cmp.w   22(a0), d0
	bge     .apply_peel_ydest
	bra     .skip_peel_ydest

.deactivate_peel:
	clr.w   (a1) ; Set object type to zero (OBJ_NULL)
	move.b  #NONE, 24(a0)
	bra     .skip_peel_ydest

.apply_peel_ydest:
	; Stop the peel if it reaches ydest
	move.w  #OBJ_BANANA_PEEL, (a1)
	move.l  20(a0), (a0)  ; x = xdest
	clr.w   2(a0)
	move.l  22(a0), 4(a0) ; y = ydest
	clr.w   6(a0)
	move.b  #NONE, 24(a0)
.skip_peel_ydest:

	; Update position of object within RAM_objs
	move.w  (a0), 2(a1)
	move.w  4(a0), 4(a1)

.next_peel:
	lea     32(a0), a0
	dbf     d7, .moving_peels_loop

	; Gushes
	moveq   #0, d7
	move.b  (RAM_num_gushes).w, d7
	beq.s   .no_gushes
	subq.b  #1, d7
	lea     (RAM_gushes).w, a0
.gushes_loop:
	; Point a1 to the object within RAM_objs corresponding to the gush
	moveq   #0, d0
	move.b  12(a0), d0
	add.w   d0, d0
	add.w   d0, d0
	add.w   d0, d0
	lea     (RAM_objs).w, a1
	adda.w  d0, a1

	moveq   #0, d2

	move.l  (a0), d0  ; y
	move.l  4(a0), d1 ; yvel
	move.w  8(a0), d2 ; ydest
	swap.w  d2

	add.l   d1, d0 ; Apply velocity to Y position

	tst.l   d1
	blt.s   .gush_moving_up
	bgt.s   .gush_moving_down
	bra.s   .next_gush

.gush_moving_up:
	cmp.l   d0, d2
	blt.s   .gush_update_y
	bra.s   .gush_reached_ydest

.gush_moving_down:
	cmp.l   d0, d2
	bgt.s   .gush_update_y

.gush_reached_ydest:
	; Set Y position to the Y destination (ydest)
	move.l  d2, d0

	; Advance gush movement pattern position and store it in d2
	moveq   #0, d2
	move.b  11(a0), d2
	addq.b  #4, d2

	; Point a2 to the next position of the movement pattern
	lea     (DATA_gush_move_patterns).w, a2
	moveq   #0, d1
	move.b  10(a0), d1
	add.w   d1, d1
	adda.w  (a2, d1.w), a2
	adda.w  d2, a2

	; Check if the movement pattern needs to be restarted
	tst.w   (a2)
	bne.s   .gush_dont_restart_movement

	; Restart movement pattern
	suba.w  d2, a2
	moveq   #0, d2
.gush_dont_restart_movement:

	; Set Y velocity and destination position from movement pattern
	movea.w (a2), a3
	move.l  (a3), 4(a0)
	move.w  2(a2), 8(a0)

	; Store next movement pattern position
	move.b  d2, 11(a0)

.gush_update_y:
	move.l  d0, (a0)  ; Update Y position within RAM_gushes
	swap.w  d0
	move.w  d0, 4(a1) ; Update Y position within RAM_objs

.next_gush:
	lea     16(a0), a0
	dbf     d7, .gushes_loop
.no_gushes:

	; Grabbed rope
	move.b  (RAM_grabbed_rope_obj).w, d0
	cmp.b   #NONE, d0
	beq.s   .no_grabbed_rope

	; Update rope position
	move.l  (RAM_grabbed_rope_xvel).w, d0
	add.l   d0, (RAM_grabbed_rope_x).w

	move.w  (RAM_grabbed_rope_x).w, d0
	cmp.w   (RAM_grabbed_rope_xmax).w, d0
	bge.s   .rope_xmax_reached
	cmp.w   (RAM_grabbed_rope_xmin).w, d0
	ble.s   .rope_xmin_reached
	bra.s   .rope_limits_done

.rope_xmax_reached:
	move.w  (RAM_grabbed_rope_xmax).w, (RAM_grabbed_rope_x).w
	clr.w   (RAM_grabbed_rope_x+2).w
	move.l  (FPSVAL_M192_PXS).w, (RAM_grabbed_rope_xvel).w
	bra.s   .rope_limits_done

.rope_xmin_reached:
	move.w  (RAM_grabbed_rope_xmax).w, (RAM_grabbed_rope_x).w
	clr.w   (RAM_grabbed_rope_x+2).w
	move.b  #NONE, (RAM_grabbed_rope_obj).w

.rope_limits_done:
	; Point a0 to the rope object within RAM_objs
	moveq   #0, d0
	move.b  (RAM_grabbed_rope_obj).w, d0
	add.w   d0, d0
	add.w   d0, d0
	add.w   d0, d0
	lea     (RAM_objs).w, a0
	adda.w  d0, a0

	; Update position of the rope object within RAM_objs
	move.w  (RAM_grabbed_rope_x).w, 2(a0)
.no_grabbed_rope:

	; Pushable crates
	lea     (RAM_pushable_crates).w, a0
	lea     (RAM_pushable_crate_solids).w, a1
	moveq   #MAX_PUSHABLE_CRATES-1, d7
.pushable_crates_loop:
	btst.b  #1, 6(a0) ; Test "moving" flag
	beq.s   .next_pushable_crate

	move.l  (a0), d0
	add.l   (FPSVAL_72_PXS).w, d0
	move.l  d0, (a0)

	; Discard fractional part of the X position
	swap.w  d0

	; Check if the crate has reached the limit X position
	cmp.w   4(a0), d0
	blt.s   .pushable_crate_x_limit_not_reached

	; Apply X position limit
	move.w  4(a0), d0
	move.w  d0, (a0)
	clr.w   2(a0)

	; Clear all flags except "pushed"
	move.b  #4, 6(a0)
.pushable_crate_x_limit_not_reached:

	; Find crate object within RAM_objs
	moveq   #0, d1
	move.b  7(a0), d1
	add.w   d1, d1
	add.w   d1, d1
	add.w   d1, d1
	lea     (RAM_objs).w, a2
	adda.w  d1, a2

	; Update X position of the object within RAM_objs
	move.w  d0, 2(a2)

	; Update position of crate solid
	move.w  d0, (a1)
	addi.w  #24, d0
	move.w  d0, 2(a1)

.next_pushable_crate:
	lea     8(a0), a0
	lea     10(a1), a1
	dbf     d7, .pushable_crates_loop

	; Passing car
	tst.l   (RAM_passing_car_x).w
	blt.s   .passing_car_done

	move.l  (FPSVAL_1200_PXS).w, d0
	add.l   d0, (RAM_passing_car_x).w

	; Check if the car has reached the limit X position
	move.w  (RAM_camera_x).w, d0
	addi.w   #544, d0
	cmp.w   (RAM_passing_car_x).w, d0
	bge.s   .passing_car_done

	; Deactivate car
	move.l  #NONE, (RAM_passing_car_x).w
.passing_car_done:

	; Hen
	tst.l   (RAM_hen_x).w
	blt.s   .hen_done

	; Update hen velocity
	move.l  (RAM_hen_acc).w, d0
	add.l   d0, (RAM_hen_xvel).w

	; Update hen X position
	move.l  (RAM_hen_xvel).w, d0
	add.l   d0, (RAM_hen_x).w

	; Check if the hen has reached the limit X position
	move.w  (RAM_camera_x).w, d0
	addi.w  #544, d0
	cmp.w   (RAM_hen_x).w, d0
	bge.s   .hen_done

	; Deactivate hen
	move.l  #-1, (RAM_hen_x).w
.hen_done:

	; Crack particles
	moveq   #MAX_CRACK_PARTICLES-1, d7
	lea     (RAM_crack_particles).w, a0
.crack_particles_loop:
	; Ignore inexistent particles
	tst.w   (a0)
	ble.s   .next_crack_particle

	; Apply gravity
	move.l  (FPSVAL_198_PXSS).w, d0
	add.l   d0, 12(a0)

	move.l  8(a0), d0
	add.l   d0, (a0)  ; x

	move.l  12(a0), d0
	add.l   d0, 4(a0) ; y

	; Check if the crack particle has reached the limit Y position (400) and
	; deactivate it if so
	cmpi.w  #400, 4(a0)
	blt     .next_crack_particle
	move.l  #NONE, (a0)

.next_crack_particle:
	lea     16(a0), a0
	dbf     d7, .crack_particles_loop

	; Cutscene objects
	moveq   #(2-1), d7
	lea     (RAM_cutscene_objs).w, a0
.cutscene_objs_loop:
	; If the object is inactive, skip
	tst.b   (a0)
	beq.s   .next_cutscene_obj

	; Apply acceleration
	move.l  18(a0), d0
	add.l   d0, 10(a0)

	; Apply gravity
	move.l  22(a0), d0
	add.l   d0, 14(a0)

	; Update X position from velocity
	move.l  10(a0), d0
	add.l   d0, 2(a0)

	; Update Y position from velocity
	move.l  14(a0), d0
	add.l   d0, 6(a0)

.next_cutscene_obj:
	lea     32(a0), a0
	dbf     d7, .cutscene_objs_loop

	rts

; ------------------------------------------------------------------------------

handle_car_thrown_peel:
	move.w  (RAM_passing_car_x).w, d0
	blt.s   .dont_throw_peel
	tst.b   (RAM_passing_car_threw_peel).w
	bne.s   .dont_throw_peel
	cmp.w   (RAM_passing_car_peel_throw_x).w, d0
	blt.s   .dont_throw_peel

	moveq   #0, d0
	move.b  (RAM_num_objs).w, d0
	add.w   d0, d0
	add.w   d0, d0
	add.w   d0, d0
	lea     (RAM_objs).w, a0
	adda.w  d0, a0

	clr.w   (a0) ; Clear object type

	; Second moving peel
	lea     (RAM_moving_peels+32).w, a0

	; Store initial peel X position in d0
	move.w  (RAM_passing_car_peel_throw_x).w, d0
	addi.w  #90, d0

	; Store peel destination X position in d1
	move.w  d0, d1
	addi.w  #70, d1

	move.w  d0, (a0)+      ; x
	clr.w   (a0)+
	move.w  #200, (a0)+    ; y
	clr.w   (a0)+
	move.l  (FPSVAL_144_PXS).w,  (a0)+ ; xvel
	move.l  (FPSVAL_M12_PXS).w,  (a0)+ ; yvel
	move.l  (FPSVAL_504_PXSS).w, (a0)+ ; grav
	move.w  d1, (a0)+      ; xdest
	move.w  #256, (a0)+    ; ydest
	move.b  (RAM_num_objs).w, (a0) ; obj

	move.b  #1, (RAM_passing_car_threw_peel).w
	addq.b  #1, (RAM_num_objs).w

.dont_throw_peel:
	rts

; ------------------------------------------------------------------------------

move_player:
	; If the player is in the inactive state, skip
	cmpi.b  #PLAYER_STATE_INACTIVE, (RAM_player_state).w
	beq     .ret

	; Deceleration and acceleration
	tst.l   (RAM_player_xvel).w
	ble.s   .decel_moving_left_check
	tst.l   (RAM_player_acc).w
	bgt.s   .decel_moving_left_check

	; The player character is decelerating while moving right
	move.l  (RAM_player_dec).w, d0
	sub.l   d0, (RAM_player_xvel).w

	; Prevent movement from reversing
	bgt.s   .decel_accel_done
	clr.l   (RAM_player_xvel).w
	bra.s   .decel_accel_done

.decel_moving_left_check:
	tst.l   (RAM_player_xvel).w
	bge.s   .accel
	tst.l   (RAM_player_acc).w
	blt.s   .accel

	; The player character is decelerating while moving left
	move.l  (RAM_player_dec).w, d0
	add.l   d0, (RAM_player_xvel).w

	; Prevent movement from reversing
	blt.s   .decel_accel_done
	clr.l   (RAM_player_xvel).w
	bra.s   .decel_accel_done

.accel:
	; The player character is accelerating
	move.l  (RAM_player_acc).w, d0
	add.l   d0, (RAM_player_xvel).w

	; Limit X velocity
	move.l  (RAM_player_xvel).w, d0
	move.l  (FPSVAL_210_PXS).w, d1
	cmp.l   d1, d0
	blt.s   .skip_right_limit
	move.l  d1, d0
.skip_right_limit:
	move.l  (FPSVAL_M90_PXS).w, d1
	cmp.l   d1, d0
	bgt.s   .skip_left_limit
	move.l  d1, d0
.skip_left_limit:
	move.l  d0, RAM_player_xvel
.decel_accel_done:

	; Apply gravity
	move.l  (RAM_player_yvel).w, d0
	add.l   (RAM_player_grav).w, d0
	move.l  (FPSVAL_300_PXS).w,  d1
	cmp.l   d1, d0
	ble.s   .skip_downwards_velocity_limit
	move.l  d1, d0
.skip_downwards_velocity_limit:
	move.l d0, (RAM_player_yvel).w

	; Update X position
	move.l  (RAM_player_xvel).w, d0
	add.l   d0, (RAM_player_x).w

	; Update Y position
	move.l  (RAM_player_yvel).w, d0
	add.l   d0, (RAM_player_y).w

	; Update position relative to rope if grabbing one
	cmpi.b  #PLAYER_STATE_GRABROPE, (RAM_player_state).w
	bne.s   .ret

	move.w  #167, d0
	cmp.w   (RAM_player_y).w, d0
	bgt.s   .above_rope_bottom

	move.w  d0, (RAM_player_y).w
	clr.w   (RAM_player_y+2).w
	clr.l   (RAM_player_yvel).w
.above_rope_bottom:

	move.l  (RAM_grabbed_rope_x).w, d0
	subi.l  #(19<<16), d0
	move.l  d0, (RAM_player_x).w

.ret:
	rts

; ------------------------------------------------------------------------------

handle_solids:
	; If there are no solids, nothing to do
	tst.b   (RAM_num_solids).w
	bne.s   .solids_present

	rts

.solids_present:
	moveq   #0, d3

	; Check if the player character has moved horizontally
	move.l  (RAM_player_old_x).w, d0
	cmp.l   (RAM_player_x).w, d0
	beq     .x_limit_done ; Skip if there is no horizontal movement

	; If the player character moved to the right, set all bits of the lowest
	; byte of d3
	slt.b   d3 

	; There are two sets of solids: one for the level's fixed solids (stored
	; in ROM) and another for the pushable crate solids, which move with the
	; respective crate when it is pushed (stored in RAM)

	; We start with the level's fixed solids

	; Keep only the lowest bit of d3; later, bit #1 will be set while
	; handling pushable crate solids instead of the level's fixed solids
	andi.b  #1, d3

	; Store previous left edge of the player character's bounding box in d5
	move.w  (RAM_player_old_x).w, d5
	addi.w  #PLAYER_BOX_OFFSET_X, d5
	moveq   #0, d6 ; Store horizontal limit in d6 (initially cleared)

	btst.l  #0, d3
	beq.s   .not_right_1

	; Store right edge of the player character's bounding box in d5
	addi.w  #PLAYER_BOX_WIDTH, d5

	; Store horizontal limit in d6 (initially a very high value)
	move.w  #30000, d6
.not_right_1:

	; Iterate through the solids to find the horizontal limit
	movea.l (RAM_ptr_level_solids).w, a0
	moveq   #0, d7
	move.b  (RAM_num_solids).w, d7
	subq.w  #1, d7
.solids_loop_x:
	; Ignore solids that are not of type SOL_FULL (whose value is zero)
	tst.w   8(a0)
	bne.s   .next_solid_x

	; Ignore solids that are out of the reach of the player character's
	; bounding box in the opposite axis (Y)
	move.w  (RAM_player_old_y).w, d0
	cmp.w   6(a0), d0
	bge.s   .next_solid_x
	add.w   (RAM_player_height).w, d0
	cmp.w   4(a0), d0
	ble.s   .next_solid_x

	btst.l  #0, d3
	beq.s   .not_right_2

	move.w  (a0), d0
	cmp.w   d0, d6
	blt.s   .next_solid_x
	cmp.w   d0, d5
	bgt.s   .next_solid_x

	move.w  d0, d6
	bra.s   .next_solid_x

.not_right_2:
	move.w  2(a0), d0

	cmp.w   d0, d6
	bgt.s   .next_solid_x
	cmp.w   d0, d5
	blt.s   .next_solid_x

	move.w  d0, d6

.next_solid_x:
	lea     10(a0), a0
	dbf     d7, .solids_loop_x

	; If we are done handling the pushable crate solids, branch
	btst.l  #1, d3
	bne.s   .pushable_crate_solids_x_done

	; Otherwise, we are done handling the level's fixed solids and need to
	; move to the pushable crate solids
	bset.l  #1, d3
	lea     (RAM_pushable_crate_solids).w, a0
	moveq   #MAX_PUSHABLE_CRATES-1, d7
	bra.s   .solids_loop_x
.pushable_crate_solids_x_done:

	; Store new left edge of the player character's bounding box in d5
	move.w  (RAM_player_x).w, d5
	addi.w  #PLAYER_BOX_OFFSET_X, d5

	btst.l  #0, d3
	beq.s   .not_right_3

	; Store new right edge of the player character's bounding box in d5
	addi.w  #PLAYER_BOX_WIDTH, d5

	cmp.w   d6, d5 ; Did the player character move beyond the right limit?
	blt.s   .x_limit_done ; If not, branch

	; Otherwise, apply right limit
	move.w  #-(PLAYER_BOX_OFFSET_X+PLAYER_BOX_WIDTH), d0
	bra.s   .apply_x_limit

.not_right_3:
	cmp.w   d6, d5 ; Did the player character move beyond the left limit?
	bgt.s   .x_limit_done ; If not, branch

	; Otherwise, apply left limit
	move.l  #-PLAYER_BOX_OFFSET_X, d0

.apply_x_limit:
	add.w   d6, d0
	swap.w  d0
	move.l  d0, (RAM_player_x).w
	clr.l   (RAM_player_xvel).w
.x_limit_done:

	; Check if the player character has moved vertically
	move.l  (RAM_player_old_y).w, d0
	cmp.l   (RAM_player_y).w, d0
	beq     .y_limit_done

	; If the player character moved downwards, set all bits of the lowest
	; byte of d3
	slt.b   d3 

	; Keep only the lowest bit of d3; later, bit #1 will be set while
	; handling pushable crate solids instead of the level's fixed solids
	andi.b  #1, d3

	; Clear d4, which will be used to store the right side of the solid
	; the ledge the player character is in belongs to, if any
	moveq   #0, d4

	; Iterate through the solids to detect if the player character's
	; bounding box is on a ledge while the sprite appears to be standing on
	; the air, so we can prevent this weird visual effect
	movea.l (RAM_ptr_level_solids).w, a0
	moveq   #0, d7
	move.b  (RAM_num_solids).w, d7
	subq.w  #1, d7

.solids_loop_ledge:
	; Only solids of types SOL_FULL (whose value is zero)
	; and SOL_PASSAGEWAY_EXIT are taken into account
	tst.w   8(a0)
	beq.s   .valid_solid_ledge
	cmpi.w  #SOL_PASSAGEWAY_EXIT, 8(a0)
	beq.s   .valid_solid_ledge
	bra.s   .next_solid_ledge

.valid_solid_ledge:
	; Ignore solids that are out of the reach of the player character's
	; bounding box in the opposite axis (X)
	move.w  (RAM_player_x).w, d0
	addi.w  #PLAYER_BOX_OFFSET_X, d0
	cmp.w   2(a0), d0
	bge.s   .next_solid_ledge
	addi.w  #PLAYER_BOX_WIDTH, d0
	cmp.w   (a0), d0
	ble.s   .next_solid_ledge

	tst.l   (RAM_player_xvel).w
	bne.s   .next_solid_ledge

	move.w  (RAM_player_y).w, d0
	add.w   (RAM_player_height).w, d0
	cmp.w   4(a0), d0
	bne.s   .next_solid_ledge

	; If a ledge has been already detected, branch
	tst.w   d4
	bne.s   .on_ledge

	; Skip if the solid type is not SOL_FULL
	tst.w   8(a0)
	bne.s   .next_solid_ledge

	move.w  (RAM_player_x).w, d0
	addi.w  #(PLAYER_BOX_OFFSET_X+4), d0

	cmp.w   2(a0), d0
	ble.s   .next_solid_ledge

	; If the player character is on a ledge, store the solid's right side
	; in d4
	move.w  2(a0), d4

	bra.s   .next_solid_ledge

.on_ledge:
	; Skip if the solid type is not SOL_PASSAGEWAY_EXIT
	cmpi.w  #SOL_PASSAGEWAY_EXIT, 8(a0)
	bne.s   .next_solid_ledge

	; Prevent an undesirable ledge detection when the right side of
	; the player character's bounding box is on a passageway exit
	move.w  (RAM_player_x).w, d0
	addi.w  #(PLAYER_BOX_OFFSET_X+PLAYER_BOX_WIDTH), d0
	cmp.w   (a0), d0
	ble.s   .next_solid_ledge

	; Clear d4
	moveq   #0, d4

.next_solid_ledge:
	lea     10(a0), a0
	dbf     d7, .solids_loop_ledge

	; If we are done handling the pushable crate solids, branch
	btst.l  #1, d3
	bne.s   .pushable_crate_ledge_test_done

	; Otherwise, we are done handling the level's fixed solids and need to
	; move to the pushable crate solids
	bset.l  #1, d3
	lea     RAM_pushable_crate_solids, a0
	moveq   #MAX_PUSHABLE_CRATES-1, d7
	bra     .solids_loop_ledge
.pushable_crate_ledge_test_done:

	bclr.l  #1, d3

	; Store previous top edge of the player character's bounding box in d5
	move.w  (RAM_player_old_y).w, d5
	moveq   #0, d6 ; Store vertical limit in d6 (initially cleared)

	btst.l  #0, d3
	beq.s   .not_down_1

	; Store bottom edge of the player character's bounding box in d5
	add.w   (RAM_player_height).w, d5
	move.w  #30000, d6 ; Store vertical limit in d6
.not_down_1:

	; Iterate through the solids to find the vertical limit
	movea.l (RAM_ptr_level_solids).w, a0
	moveq   #0, d7
	move.b  (RAM_num_solids).w, d7
	subq.w  #1, d7
.solids_loop_y:
	; Ignore solids that are out of the reach of the player character's
	; bounding box in the opposite axis (X)
	move.w  (RAM_player_x).w, d0
	addi.w  #PLAYER_BOX_OFFSET_X, d0
	cmp.w   2(a0), d0
	bge     .next_solid_y
	addi.w  #PLAYER_BOX_WIDTH, d0
	cmp.w   (a0), d0
	ble     .next_solid_y

	btst.l  #0, d3
	beq     .not_down_2

	; When moving down, ignore passageway entry solids, which
	; are intended to prevent the player character from leaving
	; the passageway through the entry
	move.w  8(a0), d0
	cmpi.w  #SOL_PASSAGEWAY_ENTRY, d0
	beq     .next_solid_y

	; Skip solids that are entirely above the player character's bounding box
	move.w  (RAM_player_old_y).w, d0
	cmp.w   6(a0), d0
	bge     .next_solid_y

	move.w  4(a0), d2 ; Store top of solid in d2

	; Determine top of slope position the player character is at
	move.w  8(a0), d0
	cmpi.w  #SOL_SLOPE_DOWN, d0
	beq.s   .slope_down
	cmpi.w  #SOL_SLOPE_UP, d0
	beq.s   .slope_up
	bra.s   .skip_slope

.slope_down:
	move.w  (RAM_player_x).w, d0
	addi.w  #PLAYER_BOX_OFFSET_X, d0

	cmp.w   (a0), d0
	ble.s   .skip_slope

	move.w  (a0), d2
	sub.w   d0, d2
	neg.w   d2
	add.w   4(a0), d2

	bra.s   .skip_slope

.slope_up:
	move.w  (RAM_player_x).w, d0
	addi.w  #(PLAYER_BOX_OFFSET_X+PLAYER_BOX_WIDTH), d0

	cmp.w   2(a0), d0
	bge.s   .skip_slope

	move.w  (a0), d2
	sub.w   d0, d2
	add.w   6(a0), d2

.skip_slope:
	add.w   (RAM_player_height).w, d5

	; Determine if the limit should be checked
	cmp.w   d2, d5
	bge.s   .check_limit_down
	move.w  8(a0), d0
	cmpi.w  #SOL_SLOPE_UP, d0
	beq.s   .check_limit_down
	cmpi.w  #SOL_SLOPE_DOWN, d0
	beq.s   .check_limit_down
	cmpi.w  #SOL_KEEP_ON_TOP, d0
	beq.s   .check_limit_down

	bra.s   .next_solid_y

.check_limit_down:
	cmp.w   d2, d6
	blt.s   .next_solid_y
	move.w  d2, d6

	bra.s   .next_solid_y

.not_down_2:
	move.w  8(a0), d0
	cmpi.w  #SOL_PASSAGEWAY_EXIT, d0
	bne.s   .not_leaving_passageway
	move.l  (RAM_player_yvel).w, d0
	cmp.l   (FPSVAL_M162_PXS).w, d0
	bgt.s   .not_leaving_passageway
	bra.s   .next_solid_y

.not_leaving_passageway:
	move.w  6(a0), d0
	cmp.w   d0, d6
	bgt.s   .next_solid_y
	cmp.w   d0, d5
	blt.s   .next_solid_y

	move.w  d0, d6

.next_solid_y:
	lea     10(a0), a0
	dbf     d7, .solids_loop_y

	; If we are done handling the pushable crate solids, branch
	btst.l  #1, d3
	bne.s   .pushable_crate_solids_y_done

	; Otherwise, we are done handling the level's fixed solids and need to
	; move to the pushable crate solids
	bset.l  #1, d3
	lea     (RAM_pushable_crate_solids).w, a0
	moveq   #MAX_PUSHABLE_CRATES-1, d7

	bra    .solids_loop_y
.pushable_crate_solids_y_done:

	; Store new top edge of the player character's bounding box in d5
	move.w  (RAM_player_y).w, d5

	btst.l  #0, d3
	beq.s   .not_down_3

	; Store new bottom edge of the player character's bounding box in d5
	add.w   (RAM_player_height).w, d5

	cmp.w   d6, d5 ; Did the player character move beyond the bottom limit?
	blt.s   .y_limit_done ; If not, branch

	tst.w   d4 ; Is the player character on a ledge?
	beq.s   .not_on_ledge ; If not, branch

	; Handle the ledge the player character is on
	move.l  d4, d0
	subi.w  #PLAYER_BOX_OFFSET_X, d0
	swap.w  d0
	move.l  d0, (RAM_player_x).w
.not_on_ledge:

	bset.b  #1, (RAM_player_flags).w ; Set "on floor" flag

	; Apply bottom limit
	moveq   #0, d0
	move.w  (RAM_player_height).w, d0
	neg.w   d0
	bra.s   .apply_y_limit

.not_down_3:
	cmp.w   d6, d5 ; Did the player character move beyond the top limit?
	bgt.s   .y_limit_done ; If not, branch

	; Otherwise, apply top limit
	moveq   #0, d0

.apply_y_limit:
	add.w   d6, d0
	swap.w  d0
	move.l  d0, (RAM_player_y).w
	clr.l   (RAM_player_yvel).w
.y_limit_done:

	rts

; ------------------------------------------------------------------------------

handle_passageways:
	; Check if the player character is entering a passageway
	tst.b   (RAM_cur_passageway).w
	bge.s   .not_entering
	move.w  (RAM_player_y).w, d0
	add.w   (RAM_player_height).w, d0
	cmpi.w  #(FLOOR_Y+4), d0
	blt.s   .not_entering

	move.w  (RAM_player_x).w, d2
	addi.w  #PLAYER_BOX_OFFSET_X, d2

	moveq   #(MAX_PASSAGEWAYS-1), d7
	movea.l (RAM_ptr_passageways).w, a0
.passageways_loop:
	; Skip inexistent passageways
	tst.w   (a0)
	ble.s   .next_passageway

	; Store passageway left side in d3
	move.w  (a0), d3

	cmp.w   d3, d2
	ble.s   .next_passageway
	addi.w  #24, d3
	cmp.w   d3, d2
	bge.s   .next_passageway

	; Store passageway index
	moveq   #(MAX_PASSAGEWAYS-1), d0
	sub.b   d7, d0
	move.b  d0, (RAM_cur_passageway).w

	; On time up, do not move the camera vertically
	btst.b  #2, (RAM_play_flags).w
	bne.s   .next_passageway

	; Move camera down
	move.l  (FPSVAL_408_PXS).w, (RAM_camera_yvel).w

.next_passageway:
	addq.w  #4, a0
	dbf     d7, .passageways_loop

.not_entering:
	tst.b   (RAM_cur_passageway).w
	blt    .ret ; Not leaving

	; Point a0 to the current passageway
	moveq   #0, d0
	move.b  (RAM_cur_passageway).w, d0
	add.w   d0, d0
	add.w   d0, d0
	movea.l (RAM_ptr_passageways).w, a0
	adda.w  d0, a0

	move.w  2(a0), d3 ; Store passageway right side in d3
	subi.w  #32, d3

	move.w  (RAM_player_x).w, d0
	addi.w  #PLAYER_BOX_OFFSET_X, d0

	cmp.w   d3, d0
	blt.s   .ret

	; Check if the exit is being opened
	moveq   #0, d0
	move.b  (RAM_cur_passageway).w, d0
	btst.b  d0, (RAM_passageway_opened_exits).w
	bne.s   .not_opening_exit ; Already opened

	move.l  (FPSVAL_M162_PXS).w, d0
	cmp.l   (RAM_player_yvel).w, d0
	blt.s   .not_opening_exit

	cmpi.w  #(FLOOR_Y+8), (RAM_player_y).w
	bge.s   .not_opening_exit

	move.w  #SFX_HOLE, d0
	bsr     sound_play_sfx

	; Add crack particles
	move.w  d3, d0
	addi.w  #16, d0
	move.w  #276, d1
	bsr     add_crack_particles

	; Mark passageway exit as opened
	moveq   #0, d0
	move.b  (RAM_cur_passageway).w, d0
	bset.b  d0, (RAM_passageway_opened_exits).w
.not_opening_exit:

	move.w  (RAM_player_y).w, d0
	cmpi.w  #(FLOOR_Y-54), d0
	bgt.s   .ret

	move.b  #NONE, (RAM_cur_passageway).w

	; No vertical camera movement on time up
	btst.b  #2, (RAM_play_flags).w
	bne.s   .ret

	; Move camera up
	move.l  (FPSVAL_M408_PXS).w, (RAM_camera_yvel).w

.ret:
	rts

; ------------------------------------------------------------------------------

handle_player_interactions:
	cmpi.b  #PLAYER_STATE_INACTIVE, (RAM_player_state).w
	bne.s   .player_not_inactive

	rts
.player_not_inactive:

	; Use d5 for the following flags:
	; 0 - Player character collected a coin
	; 1 - Player character slipped
	; 2 - Player character thrown back by a gush
	; 3 - Player character hit a spring
	moveq   #0, d5

	; Use d7 to count the coins yet to be processed
	moveq   #0, d7
	move.b  (RAM_num_coins).w, d7
	beq     .coins_done

	lea     (RAM_coins).w, a2
	subq.w  #1, d7

	moveq   #2, d2 ; Left and top offset of coin bounding box
	moveq   #6, d3 ; Right and bottom offset of coin bounding box

.coins_loop:
	; Ignore inexistent coins
	tst.w   (a2)
	beq     .next_coin

	; Check bounding box overlap (X axis)
	move.w  (RAM_player_x).w, d0
	addi.w  #PLAYER_BOX_OFFSET_X, d0
	move.w  (a2), d1 ; Coin right
	add.w   d2, d1
	add.w   d3, d1
	cmp.w   d1, d0
	bgt     .next_coin
	addi.w  #PLAYER_BOX_WIDTH, d0
	sub.w   d3, d1 ; Coin left
	cmp.w   d1, d0
	blt     .coins_done ; No more coins to check

	; Check bounding box overlap (Y axis)
	move.w  (RAM_player_y).w, d0
	add.w   (RAM_player_height).w, d0
	move.w  2(a2), d1
	bclr.l  #$F, d1 ; Clear gold bit
	add.w   d2, d1
	cmp.w   d1, d0
	blt     .next_coin
	sub.w   (RAM_player_height).w, d0
	move.w  2(a2), d1
	bclr.l  #$F, d1 ; Clear gold bit
	add.w   d3, d1
	cmp.w   d1, d0
	bgt.s   .next_coin

	bset.l  #0, d5 ; Set d5 flag

	; Add coin spark
	moveq   #0, d0
	move.b  (RAM_next_coin_spark).w, d0
	add.w   d0, d0
	add.w   d0, d0
	lea     (RAM_coin_sparks).w, a0
	adda.w  d0, a0

	move.l  #$50, (RAM_score_add).w ; Value to be added to the score (BCD)

	move.w  (a2), (a0)+ ; X
	move.w  2(a2), (a0) ; Y/gold
	btst.b  #$7, 2(a2)  ; Is this a gold coin?
	beq.s   .not_gold   ; If not, branch
	move.l  #$100, (RAM_score_add).w ; Value to be added to the score (BCD)
.not_gold:

	; Add score (BCD)
	lea     (RAM_score+4).w, a0
	lea     (RAM_score_add+4).w, a1
	andi.b  #0, ccr
	abcd.b  -(a1), -(a0)
	abcd.b  -(a1), -(a0)
	abcd.b  -(a1), -(a0)
	abcd.b  -(a1), -(a0)

	; Start coin spark animation
	moveq   #0, d0
	move.b  (RAM_next_coin_spark).w, d0
	add.w   d0, d0
	add.w   d0, d0
	add.w   d0, d0
	lea     (RAM_anims+ANIM_COIN_SPARK_1).w, a0
	adda.w  d0, a0
	move.b  #3, (a0)
	move.b  3(a0), 2(a0) ; Set delay
	move.b  #3, 4(a0)    ; Set "running" and "reverse" flags

	move.b  (RAM_next_coin_spark).w, d0
	addq.b  #1, d0
	andi.b  #$0F, d0
	move.b  d0, (RAM_next_coin_spark).w

	; Remove coin
	clr.w   (a2)

.next_coin:
	addq.w  #4, a2
	dbf     d7, .coins_loop
.coins_done:

	; Use d6 to keep track of the current object index
	moveq   #0, d6

	; Use d7 to count the objects yet to be processed
	moveq   #0, d7
	move.b  (RAM_num_objs).w, d7
	beq     .objs_done

	lea     (RAM_objs).w, a2
	subq.w  #1, d7

.objs_loop:
	; Ignore inexistent objects
	tst.w   (a2)
	beq     .next_obj

	; Find object bounding box
	lea     DATA_obj_bounding_boxes, a3
	move.w  (a2), d0
	add.w   d0, d0
	add.w   d0, d0
	add.w   d0, d0
	adda.w  d0, a3

	; The player character interacts with objects within RAM_objs only while
	; in the normal state
	tst.b   (RAM_player_state).w ; PLAYER_STATE_NORMAL = 0
	bne     .next_obj

	cmpi.w  #OBJ_ROPE, (a2)
	bne.s   .use_player_bounding_box

	; For ropes, check interaction using a point at offset (21, 28) from the
	; player character
	move.w  (RAM_player_x).w, d0
	addi.w  #21, d0
	move.w  2(a2), d1 ; Object left
	add.w   (a3), d1
	cmp.w   d1, d0
	blt     .next_obj
	add.w   2(a3), d1 ; Object right
	cmp.w   d1, d0
	bgt     .next_obj
	move.w  (RAM_player_y).w, d0
	addi.w  #28, d0
	move.w  4(a2), d1
	add.w   4(a3), d1 ; Object top
	cmp.w   d1, d0
	blt     .next_obj
	move.w  4(a2), d1 ; Object bottom
	add.w   6(a3), d1
	cmp.w   d1, d0
	bgt     .next_obj

	bra.s   .handle_interaction

.use_player_bounding_box:
	; For objects other than a rope, check interaction using the player
	; character's bounding box
	move.w  (RAM_player_x).w, d0
	addi.w  #(PLAYER_BOX_OFFSET_X+PLAYER_BOX_WIDTH), d0
	move.w  2(a2), d1 ; Object left
	add.w   (a3), d1
	cmp.w   d1, d0
	blt     .next_obj
	subi.w  #PLAYER_BOX_WIDTH, d0
	add.w   2(a3), d1
	cmp.w   d1, d0
	bgt     .next_obj
	move.w  (RAM_player_y).w, d0
	add.w   (RAM_player_height).w, d0
	move.w  4(a2), d1
	add.w   4(a3), d1
	cmp.w   d1, d0
	blt     .next_obj
	sub.w   (RAM_player_height).w, d0
	move.w  4(a2), d1
	add.w   6(a3), d1
	cmp.w   d1, d0
	bgt     .next_obj

.handle_interaction:
	; Jump table for object types
	move.w  (a2), d0
	add.w   d0, d0
	add.w   d0, d0
	jmp     .obj_jump_table(pc, d0.w)
.obj_jump_table:
	bra.w   .next_obj        ; OBJ_NULL
	bra.w   .obj_banana_peel ; OBJ_BANANA_PEEL
	bra.w   .obj_gush        ; OBJ_GUSH
	bra.w   .obj_gush_crack  ; OBJ_GUSH_CRACK
	bra.w   .next_obj        ; OBJ_PUSH_CRATE
	bra.w   .next_obj        ; OBJ_PUSH_CRATE_WITH_ARROW
	bra.w   .obj_rope        ; OBJ_ROPE
	bra.w   .obj_spring      ; OBJ_SPRING

.obj_banana_peel:
	; Set d5 flag
	bset.l  #1, d5

	clr.w   (a2) ; Clear object type
	lea     (RAM_moving_peels).w, a0

	; Set the index within RAM_moving_peels
	move.b  d6, 24(a0)

	; Position moving peel
	move.w  2(a2), (a0)+ ; x
	clr.w   (a0)+
	move.w  4(a2), (a0)+ ; y
	clr.w   (a0)+

	bra     .next_obj

.obj_gush:
	; Set d5 flag
	bset.l  #2, d5

	bra     .next_obj

.obj_gush_crack:
	; Set d5 flag
	bset.l  #2, d5

	move.w  #OBJ_GUSH, (a2)

	; Add crack particles
	move.w  2(a2), d0
	addi.w  #6, d0
	move.w  #276, d1
	bsr     add_crack_particles

	; Get address of next gush within RAM_gushes and store it in a0
	moveq   #0, d0
	move.b  (RAM_num_gushes).w, d0
	add.w   d0, d0
	add.w   d0, d0
	add.w   d0, d0
	add.w   d0, d0
	lea     (RAM_gushes).w, a0
	adda.w  d0, a0

	move.w  #266, (a0)+ ; y
	clr.w   (a0)+
	move.l  (FPSVAL_M144_PXS).w, (a0)+ ; yvel
	move.w  (DATA_gush_move_pattern_2+6).w, (a0)+ ; ydest
	move.b  #1, (a0)+   ; move_pattern_index
	clr.b   (a0)+       ; move_pattern_pos
	move.b  d6, (a0)    ; obj

	addi.b  #1, (RAM_num_gushes).w

	bra     .next_obj

.obj_rope:
	; Skip the check below if the rope being processed is not the same the
	; player character is grabbing or has just released
	cmp.b   (RAM_grabbed_rope_obj).w, d6
	bne.s   .not_this_rope

	; Cannot grab the same rope again right after releasing it
	move.w  (RAM_grabbed_rope_xmax).w, d0
	subi.w  #64, d0
	cmp.w   (RAM_grabbed_rope_x).w, d0
	ble     .next_obj
.not_this_rope:

	; If the player character is grabbing a rope but the previously grabbed
	; one has not returned to its initial X position, reset its X position
	; immediately
	cmp.b   (RAM_grabbed_rope_obj).w, d6
	beq.s   .rope_dont_reset_x
	cmpi.b  #NONE, (RAM_grabbed_rope_obj).w
	beq.s   .rope_dont_reset_x

	; Find rope object within RAM_objs
	moveq   #0, d0
	move.b  (RAM_grabbed_rope_obj).w, d0
	add.w   d0, d0
	add.w   d0, d0
	add.w   d0, d0
	lea     (RAM_objs).w, a0
	adda.w  d0, a0

	; Reset X position
	move.w  (RAM_grabbed_rope_xmin).w, d0
	move.w  d0, 2(a0)

	move.b  #NONE, (RAM_grabbed_rope_obj).w
.rope_dont_reset_x:

	; If the player character has grabbed the same rope again before it
	; returns to its initial position, the limits of the rope's horizontal
	; movement are already set
	cmpi.b  #NONE, (RAM_grabbed_rope_obj).w
	bne.s   .rope_dont_set_limits

	move.w  2(a2), d0
	move.w  d0, (RAM_grabbed_rope_xmin).w
	addi.w  #352, d0
	move.w  d0, (RAM_grabbed_rope_xmax).w
.rope_dont_set_limits:

	move.b  #PLAYER_STATE_GRABROPE, (RAM_player_state).w
	move.b  d6, (RAM_grabbed_rope_obj).w
	move.w  2(a2), (RAM_grabbed_rope_x).w
	clr.w   (RAM_grabbed_rope_x+2).w
	move.l  (FPSVAL_258_PXS).w, (RAM_grabbed_rope_xvel).w

	bra.s   .next_obj

.obj_spring:
	tst.l   (RAM_player_yvel).w
	blt.s   .next_obj

	; The player character has hit a spring
	move.l  (FPSVAL_M246_PXS).w, (RAM_player_yvel).w

	move.l  a2, (RAM_hit_spring).w

	lea     (RAM_anims+ANIM_HIT_SPRING).w, a0
	move.b  #5, (a0)
	move.b  3(a0), 2(a0) ; Set delay
	move.b  #3, 4(a0)    ; Set "running" and "reverse" flags

	; Set d5 flag
	bset.l  #3, d5

.next_obj:
	lea     8(a2), a2
	addq.b  #1, d6
	dbf     d7, .objs_loop
.objs_done:

	; Handle d5 flags
	btst.l  #0, d5
	beq.s   .player_no_coin_collected

	move.w  #SFX_COIN, d0
	bsr     sound_play_sfx
.player_no_coin_collected:

	btst.l  #1, d5
	beq.s   .player_no_slip

	; Make peel move
	lea     (RAM_moving_peels+8).w, a0
	move.l  (FPSVAL_150_PXS).w,  (a0)+ ; xvel
	move.l  (FPSVAL_M204_PXS).w, (a0)+ ; yvel
	move.l  (FPSVAL_504_PXSS).w, (a0)+ ; grav
	clr.w   (a0)+           ; xdest 
	move.w  #500, (a0)      ; ydest (below the Y limit, which is 400)

	move.b  #PLAYER_STATE_SLIP, (RAM_player_state).w

	move.w  #SFX_SLIP, d0
	bsr     sound_play_sfx
.player_no_slip:

	btst.l  #2, d5
	beq.s   .player_no_throwback
	move.b  #PLAYER_STATE_THROWBACK, (RAM_player_state).w

	move.w  #SFX_HIT, d0
	bsr     sound_play_sfx
.player_no_throwback:

	btst.l  #3, d5
	beq.s   .player_no_spring_hit
	move.w  #SFX_SPRING, d0
	bsr     sound_play_sfx
.player_no_spring_hit:

	; Handle pushable crates
	move.b  (RAM_play_input_down).w, d0
	btst.b  #PLAY_INPUT_RIGHT, (RAM_play_input_down).w
	bne.s   .dont_reset_crate_push_remaining
	move.b  (FPSVAL_0_7_S).w, (RAM_crate_push_remaining).w
.dont_reset_crate_push_remaining:

	; Store the X and Y positions of the point used to check if the player
	; character is pushing the crate in d2 and d3, respectively
	move.w  (RAM_player_x).w, d2
	addi.w  #24, d2
	move.w  (RAM_player_y).w, d3
	addi.w  #48, d3

	moveq   #MAX_PUSHABLE_CRATES-1, d7
	lea     (RAM_pushable_crates).w, a0
	lea     (RAM_pushable_crate_solids).w, a1
.pushable_crates_loop:
	btst.b  #2, 6(a0) ; Check if the "pushed" flag is set
	bne.s   .next_pushable_crate ; If the flag is set, skip it
	tst.w   (a0) ; If the X position of the crate zero?
	beq.s   .next_pushable_crate ; If so, skip it

	; Check if the point overlaps the solid
	cmp.w   (a1), d2
	blt.s   .next_pushable_crate
	cmp.w   2(a1), d2
	bgt.s   .next_pushable_crate
	cmp.w   4(a1), d3
	blt.s   .next_pushable_crate
	cmp.w   6(a1), d3
	bgt.s   .next_pushable_crate

	; If we got here, then the player character is pushing the crate
	subq.b  #1, (RAM_crate_push_remaining).w
	bgt.s   .next_pushable_crate

	; Finished pushing the crate
	move.b  (FPSVAL_0_7_S).w, (RAM_crate_push_remaining).w
	move.b  #6, 6(a0) ; Set crate's "pushed" and "moving" flags

	move.w  #SFX_CRATE, d0
	bsr     sound_play_sfx

.next_pushable_crate:
	addq.w  #8, a0
	lea     10(a1), a1
	dbf     d7, .pushable_crates_loop

	rts

; ------------------------------------------------------------------------------

handle_triggers:
	movea.l (RAM_ptr_next_trigger).w, a0
	move.w  (a0), d0

	; Nothing to do if we have reached the end of the list of triggers
	beq.s   .ret

	; Nothing to do if the player has not reached the trigger
	cmp.w   (RAM_player_x).w, d0
	bgt.s   .ret

	cmpi.w  #3, 2(a0)
	beq.s   .trigger_hen

	; If it is not a hen, then it is a car

	; Find car's initial X position
	moveq   #0, d1
	move.w  d0, d1
	subi.w  #368, d1
	swap.w  d1
	move.l  d1, (RAM_passing_car_x).w

	; Find car's X position at which the banana peel will be thrown
	move.w  d0, d1
	addi.w  #72, d1
	move.w  d1, (RAM_passing_car_peel_throw_x).w
	
	move.b  3(a0), (RAM_passing_car_color).w
	move.b  #0, (RAM_passing_car_threw_peel).w
	bset.b  #0, (RAM_anims+ANIM_CAR_WHEELS+4).w ; Set car wheel animation "running" flag

	bra.s   .next_trigger

.trigger_hen:
	; Find hen's initial X position
	moveq   #0, d1
	move.w  d0, d1
	subi.w  #208, d1
	swap.w  d1
	move.l  d1, (RAM_hen_x).w

	move.l  (FPSVAL_360_PXS).w, (RAM_hen_xvel).w
	clr.l   (RAM_hen_acc).w
	bset.b  #0, (RAM_anims+ANIM_HEN+4).w ; Set hen animation running flag

.next_trigger:
	addq.w  #4, a0
	move.l  a0, (RAM_ptr_next_trigger).w

.ret:
	rts

; ------------------------------------------------------------------------------

do_player_state_specifics:
	moveq   #0, d0
	moveq   #0, d2

	move.b  (RAM_player_state), d0
	cmp.b   (RAM_player_old_state).w, d0

	; If the state has just changed, set d2 to $FF
	sne.b   d2

	add.w   d0, d0
	add.w   d0, d0
	jmp     .jump_table(pc, d0.w)
.jump_table:
	bra.w   .state_normal
	bra.w   .state_slip
	bra.w   .state_getup
	bra.w   .state_throwback
	bra.w   .state_grabrope
	bra.w   .state_flicker

.state_normal:
	move.b  (RAM_play_input_down).w, d7

	; Determine acceleration from input
	moveq   #0, d0
	btst.l  #PLAY_INPUT_RIGHT, d7
	bne.s   .acc_right
	btst.l  #PLAY_INPUT_LEFT, d7
	bne.s   .acc_left
	bra.s   .acc_apply

.acc_right:
	move.l  (FPSVAL_216_PXSS).w, d0
	bra.s  .acc_apply
.acc_left:
	move.l  (FPSVAL_M216_PXSS).w, d0
.acc_apply:
	move.l  d0, (RAM_player_acc).w

	; Handle jumps
	btst.b  #1, (RAM_player_flags).w ; Check "on floor" flag
	beq.s   .no_jump
	tst.b   (RAM_jump_timeout).w
	ble.s   .no_jump

	; Jump
	move.l  (FPSVAL_M156_PXS).w, (RAM_player_yvel).w
	clr.b   (RAM_jump_timeout).w
.no_jump:

	; Decide animation type
	move.b  #PLAYER_ANIM_STAND, d0 ; Default to standing animation
	btst.b  #1, (RAM_player_flags).w ; Check "on floor" flag
	beq.s   .anim_jump
	tst.l   (RAM_player_xvel).w
	bgt.s   .anim_walk
	blt.s   .anim_walkback
	bra.s   .set_anim
.anim_jump:
	move.b  #PLAYER_ANIM_JUMP, d0
	bra.s   .set_anim
.anim_walk:
	move.b  #PLAYER_ANIM_WALK, d0
	bra.s   .set_anim
.anim_walkback:
	move.b  #PLAYER_ANIM_WALKBACK, d0
.set_anim:
	move.b  d0, (RAM_player_anim_type).w
	rts

.state_slip:
	tst.b   d2 ; Has player's state just changed?
	bne     .ret ; If so, branch
	btst.b  #1, (RAM_player_flags).w ; Is player on floor?
	beq.s   .ret ; If not, branch

	move.l  #0, (RAM_player_xvel).w

	; If any button that causes a gameplay action has been just pressed,
	; skip
	tst.b   (RAM_play_input_hit).w
	beq.s   .ret

	; Otherwise, change to the "get up" state
	move.b  #PLAYER_STATE_GETUP, (RAM_player_state).w

	rts

.state_getup:
	; Prevent jump if the button is held until the character finishes
	; getting up
	clr.b   (RAM_jump_timeout).w

	tst.w   (RAM_player_yvel).w ; Is player character still moving upwards?
	blt.s   .ret ; If so, branch

	move.w  #PLAYER_HEIGHT_NORMAL, (RAM_player_height).w

	btst.b  #1, (RAM_player_flags).w ; Is player on floor?
	beq.s   .ret ; If not, branch

	clr.b   (RAM_player_state).w

	rts

.state_throwback:
	tst.b   d2 ; Has player's state just changed?
	bne.s   .ret ; If so, branch
	btst.b  #1, (RAM_player_flags).w ; Is player on floor?
	beq.s   .ret ; If not branch

	clr.b   (RAM_player_state).w ; Change to normal state

	rts

.state_grabrope:
	move.w  (RAM_grabbed_rope_xmax).w, d0
	subi.w  #16, d0
	cmp.w   (RAM_player_x).w, d0 ; Rope X limit reached?
	blt.s   .ret ; If not, branch
	tst.w   (RAM_grabbed_rope_xvel).w ; Is the rope moving to the left?
	bge.s   .ret ; If so, branch

	clr.b   (RAM_player_state).w ; Release the rope and return to normal state

	rts

.state_flicker:
	;Prevent jump if the button is held until the flicker finishes
	clr.b   (RAM_jump_timeout).w

	bchg.b  #0, (RAM_player_flags).w ; Toggle player character's visibility

	subq.b  #1, (RAM_player_flicker_delay).w
	bhi.s   .ret ; Branch if the delay is not over yet

	clr.b   (RAM_player_state).w ; Return to normal state

.ret:
	rts

; ------------------------------------------------------------------------------

handle_fall_sound:
	btst.b  #2, (RAM_play_flags).w ; Check "time up" flag
	bne.s   .ret
	btst.b  #2, (RAM_player_flags).w ; Check "fell" flag
	bne.s   .ret
	cmpi.b  #NONE, (RAM_cur_passageway).w
	bne.s   .ret
	tst.l   (RAM_player_yvel).w
	ble.s   .ret

	move.w  (RAM_player_y).w, d0
	add.w   (RAM_player_height).w, d0
	cmpi.w  #(FLOOR_Y+8), d0
	ble.s   .ret

	bset.b  #2, (RAM_player_flags).w ; Set "fell" flag

	move.w  #SFX_FALL, d0
	bra     sound_play_sfx

.ret:
	rts

; ------------------------------------------------------------------------------

handle_respawn:
	; No respawn on time up
	btst.b  #2, (RAM_play_flags).w
	bne.s   .ret

	; No respawn if the Y position of the player character is above 324
	move.w  (RAM_player_y).w, d0
	cmpi.w  #324, d0
	blt.s   .ret

	movea.l (RAM_ptr_respawn_points).w, a0
	moveq   #0, d2
	move.b  (RAM_num_respawn_points).w, d2
	move.w  d2, d0
	add.w   d0, d0
	add.w   d0, d0
	adda.w  d0, a0

	subq.w  #1, d2
	move.w  (RAM_player_x).w, d3
.respawn_point_loop:
	move.w  -(a0), d1 ; Y position
	move.w  -(a0), d0 ; X position

	; Check if the respawn point has a lower X position than the player
	; character
	cmp.w   d3, d0
	blt.s   .respawn_point_found

	dbf     d2, .respawn_point_loop

.respawn_point_found:
	; Convert respawn point position to fixed point
	swap.w  d0
	clr.w   d0
	swap.w  d1
	clr.w   d1

	; Set player character's position to the same as the respawn point
	move.l  d0, (RAM_player_x).w
	move.l  d1, (RAM_player_y).w
	move.l  d0, (RAM_player_old_x).w
	move.l  d1, (RAM_player_old_y).w

	move.b  #PLAYER_STATE_FLICKER, (RAM_player_state).w
	bclr.b  #2, (RAM_player_flags).w ; Clear "fell" flag

	; Discard fractional part of respawn point X position
	swap.w  d0

	; Retreat camera if needed
	subi.w  #64, d0
	cmp.w   (RAM_camera_x).w, d0
	bgt.s   .no_camera_retreat

	move.w  d0, (RAM_camera_xdest).w
	move.l  (FPSVAL_M720_PXS).w, (RAM_camera_xvel).w
.no_camera_retreat:

	move.w  #SFX_RESPAWN, d0
	bsr     sound_play_sfx

.ret:
	rts

; ------------------------------------------------------------------------------

handle_player_state_change:
	moveq   #0, d2
	move.b  (RAM_player_state).w, d2
	cmp.b   (RAM_player_old_state).w, d2
	bne.s   .state_changed
	rts

.state_changed:
	moveq   #0, d0
	move.l  d0, (RAM_player_acc).w
	move.l  d0, (RAM_player_dec).w
	bset.b  #0, (RAM_player_flags).w ; Set player visible flag
	move.w  #PLAYER_HEIGHT_NORMAL, (RAM_player_height).w

	add.w   d2, d2
	add.w   d2, d2
	jmp     .jump_table(pc, d2.w)
.jump_table:
	bra.w   .state_normal
	bra.w   .state_slip
	bra.w   .state_getup
	bra.w   .state_throwback
	bra.w   .state_grabrope
	bra.w   .state_flicker
	bra.w   .state_inactive

.state_normal:
	move.l  (FPSVAL_252_PXSS).w, (RAM_player_dec).w
	move.l  (FPSVAL_234_PXSS).w, (RAM_player_grav).w
	rts

.state_slip:
	move.l  (FPSVAL_M12_PXS).w, (RAM_player_xvel).w
	move.l  (FPSVAL_M24_PXS).w, (RAM_player_yvel).w
	move.w  #PLAYER_HEIGHT_SLIP, (RAM_player_height).w
	move.b  #PLAYER_ANIM_SLIP, (RAM_player_anim_type).w
	rts

.state_getup:
	clr.l   (RAM_player_xvel).w
	move.l  (FPSVAL_M120_PXS).w, (RAM_player_yvel).w
	move.w  #PLAYER_HEIGHT_SLIP, (RAM_player_height).w
	move.b  #PLAYER_ANIM_SLIPREV, (RAM_player_anim_type).w
	rts

.state_throwback:
	move.b  #PLAYER_ANIM_THROWBACK, (RAM_player_anim_type).w
	move.l  (FPSVAL_M102_PXS).w, (RAM_player_xvel).w
	move.l  (FPSVAL_M144_PXS).w, (RAM_player_yvel).w
	rts

.state_grabrope:
	clr.l   (RAM_player_grav).w
	clr.l   (RAM_player_xvel).w
	move.l  (FPSVAL_120_PXS).w, (RAM_player_yvel).w
	move.b  #PLAYER_ANIM_GRABROPE, (RAM_player_anim_type).w
	rts

.state_flicker:
	move.b  (FPSVAL_0_5_S).w, (RAM_player_flicker_delay).w
	moveq   #0, d0
	move.l  d0, (RAM_player_grav).w
	move.l  d0, (RAM_player_xvel).w
	move.l  d0, (RAM_player_yvel).w
	move.b  #PLAYER_ANIM_STAND, (RAM_player_anim_type).w
	rts

.state_inactive:
	moveq   #-1, d0
	move.l  d0, (RAM_player_x).w
	move.l  d0, (RAM_player_y).w
	moveq   #0, d0
	move.l  d0, (RAM_player_xvel).w
	move.l  d0, (RAM_player_yvel).w
	move.l  d0, (RAM_player_acc).w
	move.l  d0, (RAM_player_grav).w
	bclr.b  #0, (RAM_player_flags).w ; Clear "visible" flag
	rts

; ------------------------------------------------------------------------------

move_camera:
	move.l  (RAM_camera_xvel).w, d2
	move.l  (RAM_camera_yvel).w, d3

	add.l   d2, (RAM_camera_x).w
	add.l   d3, (RAM_camera_y).w

	move.w  (RAM_camera_x).w, d0

	tst.l   d2
	beq.s   .horizontal_move_done
	bgt.s   .move_right

	; Move left
	cmp.w   (RAM_camera_xdest).w, d0
	bgt.s   .horizontal_move_done
	bra.s   .xdest_reached

.move_right:
	cmp.w   (RAM_camera_xdest).w, d0
	blt.s   .horizontal_move_done

.xdest_reached:
	clr.l   (RAM_camera_xvel).w
	move.w  (RAM_camera_xdest).w, (RAM_camera_x).w
	clr.w   (RAM_camera_x+2).w
.horizontal_move_done:

	; Vertical movement
	move.w  (RAM_camera_y).w, d0

	tst.l   d3
	beq.s   .vertical_move_done
	bgt.s   .move_down

	; Move up
	moveq   #0, d1
	tst.w   d0
	bgt.s   .vertical_move_done
	bra.s   .vertical_dest_reached

.move_down:
	move.w  #95, d1 ; Destination Y position
	cmp.w   d1, d0
	blt.s   .vertical_move_done

.vertical_dest_reached:
	clr.l   (RAM_camera_yvel).w
	move.w  d1, (RAM_camera_y).w
	clr.w   (RAM_camera_y+2).w
.vertical_move_done:

	bra     position_camera

; ------------------------------------------------------------------------------

keep_player_within_limits:
	; If the player character is not past the left limit, skip
	move.l  #(48<<16), d0
	cmp.l   (RAM_player_x).w, d0
	blt.s   .ret

	; Apply limit
	move.l  d0, (RAM_player_x).w
	move.l  #0, (RAM_player_xvel).w

	btst.b  #1, (RAM_player_flags).w ; Test player on floor flag
	beq.s   .ret

	move.b  #PLAYER_ANIM_STAND, (RAM_player_anim_type).w

.ret:
	rts

; ------------------------------------------------------------------------------

handle_player_animation_change:
	; Store animation type in d0
	moveq   #0, d0
	move.b  (RAM_player_anim_type).w, d0

	; If the animation type did not change, skip
	cmp.b   (RAM_player_old_anim_type).w, d0
	beq.s   .ret

	; Find offset within DATA_player_anims for current animation type
	lea     DATA_player_anims, a0
	add.w   d0, d0
	add.w   d0, d0
	add.w   d0, d0
	adda.w  d0, a0

	lea     (RAM_anims).w, a1

	; Find delay
	movea.w (a0)+, a2
	move.b  (a2), d0

	; Start animation
	move.b  (a0)+, (a1)+ ; Current frame
	move.b  (a0)+, (a1)+ ; Last frame (number of frames minus one)
	move.b  d0, (a1)+    ; Delay
	move.b  d0, (a1)+    ; Maximum delay
	move.b  (a0),  (a1)  ; Flags

.ret:
	rts

; ------------------------------------------------------------------------------

update_animations:
	; Determine bus wheel animation delay
	lea     (RAM_anims+ANIM_BUS_WHEELS).w, a0

	bclr.b  #0, 4(a0) ; Clear "running" flag

	move.l  (RAM_bus_xvel).w, d0
	ble.s   .bus_not_moving

	cmp.l   (FPSVAL_132_PXS).w, d0
	bgt.s   .delay_low
	cmp.l   (FPSVAL_84_PXS).w, d0
	bgt.s   .delay_medium

	; High delay
	move.b  (FPSVAL_0_1_S).w, d1
	bra.s   .delay_determined
.delay_medium:
	move.b  (FPSVAL_0_05_S).w, d1
	bra.s   .delay_determined
.delay_low:
	move.b  (FPSVAL_0_02_S).w, d1
.delay_determined:

	bset.b  #0, 4(a0) ; Set "running" flag
	move.b  d1, 3(a0) ; Maximum delay

	move.b  2(a0), d0 ; Delay
	cmp.b   d1, d0
	ble.s   .no_delay_correction
	move.b  d1, 2(a0) ; Delay
.no_delay_correction:
.bus_not_moving:

	move.w  #NUM_ANIMS-1, d3
	lea     (RAM_anims).w, a3
.anims_loop:
	move.b  4(a3), d4    ; Store flags in d4

	btst.l  #0, d4       ; Is animation running?
	beq.s   .next_anim   ; If not, branch

	subq.b  #1, 2(a3)    ; Decrease delay
	bgt.s   .next_anim   ; Branch if it is not time to change the frame
	move.b  3(a3), 2(a3) ; Otherwise, restart delay

	btst.l  #1, d4       ; Is the animation in reverse?
	beq.s   .not_reverse ; If not, branch

	subq.b  #1, (a3)     ; Change to previous frame
	bge.s   .next_anim   ; Branch if the animation has not finished

	move.b  #0, (a3)
	btst.l  #2, d4       ; Is the animation looping?
	beq.s   .next_anim   ; If not, branch
	move.b  1(a3), (a3)  ; Restart animation

	bra.s   .next_anim

.not_reverse:
	addq.b  #1, (a3)     ; Change to next frame

	move.b  (a3), d0
	cmp.b   1(a3), d0    ; Is this the last frame?
	ble.s   .next_anim   ; If not, branch

	move.b  1(a3), (a3)
	btst.l  #2, d4       ; Is the animation looping?
	beq.s   .next_anim   ; If not, branch
	move.b  #0, (a3)     ; Restart animation

.next_anim:
	addq.w  #ANIM_SIZE_BYTES, a3
	dbf     d3, .anims_loop

	rts

; ------------------------------------------------------------------------------

move_push_arrow:
	move.l  (RAM_push_arrow_xvel).w, d0
	add.l   d0, (RAM_push_arrow_xoffs).w

	; Arrow right limit
	move.w  #8, d1

	move.w  (RAM_push_arrow_xoffs).w, d0
	cmp.w   d1, d0
	blt.s   .no_right_limit

	move.w  d1, (RAM_push_arrow_xoffs).w
	clr.w   (RAM_push_arrow_xoffs+2).w
	move.l  (FPSVAL_M30_PXS).w, (RAM_push_arrow_xvel).w
.no_right_limit:

	tst.l   (RAM_push_arrow_xvel).w
	bge.s   .no_left_limit
	tst.w   (RAM_push_arrow_xoffs).w
	bgt.s   .no_left_limit

	clr.l   (RAM_push_arrow_xoffs).w
	clr.l   (RAM_push_arrow_xvel).w
.no_left_limit:

	subq.b  #1, (RAM_push_arrow_delay).w
	bhi.s   .no_move_start

	clr.b   (RAM_push_arrow_delay).w

	tst.l   (RAM_push_arrow_xoffs).w
	bne.s   .no_move_start

	move.l  (FPSVAL_30_PXS).w, (RAM_push_arrow_xvel).w
	move.b  (FPSVAL_1_S).w, (RAM_push_arrow_delay).w
.no_move_start:

	rts

; ------------------------------------------------------------------------------

update_sequence:
	; Clear screen wipe flags
	andi.b  #$F9, (RAM_sequence_flags).w

	tst.b   (RAM_sequence_delay).w
	beq.s   .no_delay

	subq.b  #1, (RAM_sequence_delay).w
	rts

.no_delay:
	moveq   #0, d0
	move.b  (RAM_sequence_step).w, d0

	; Skip if the sequence step number is greater than the maximum used in
	; the jump table below
	cmpi.b  #125, d0
	bhi.w   .ret

	add.w   d0, d0
	add.w   d0, d0
	jmp     .seq_jump_table(pc, d0.w)
.seq_jump_table:
	bra.w   .seq_0   ; 0   - SEQ_NORMAL_PLAY_START
	bra.w   .seq_1   ; 1   - SEQ_NORMAL_PLAY
	bra.w   .ret     ; 2
	bra.w   .ret     ; 3
	bra.w   .ret     ; 4
	bra.w   .ret     ; 5
	bra.w   .ret     ; 6
	bra.w   .ret     ; 7
	bra.w   .ret     ; 8
	bra.w   .ret     ; 9
	bra.w   .seq_10  ; 10  - SEQ_INITIAL
	bra.w   .seq_11  ; 11
	bra.w   .ret     ; 12
	bra.w   .ret     ; 13
	bra.w   .ret     ; 14
	bra.w   .ret     ; 15
	bra.w   .ret     ; 16
	bra.w   .ret     ; 17
	bra.w   .ret     ; 18
	bra.w   .ret     ; 19
	bra.w   .seq_20  ; 20  - SEQ_BUS_LEAVING
	bra.w   .seq_21  ; 21
	bra.w   .seq_22  ; 22
	bra.w   .ret     ; 23
	bra.w   .ret     ; 24
	bra.w   .ret     ; 25
	bra.w   .ret     ; 26
	bra.w   .ret     ; 27
	bra.w   .ret     ; 28
	bra.w   .ret     ; 29
	bra.w   .seq_30  ; 30  - SEQ_TIMEUP_BUS_NEAR
	bra.w   .seq_31  ; 31
	bra.w   .ret     ; 32
	bra.w   .ret     ; 33
	bra.w   .ret     ; 34
	bra.w   .ret     ; 35
	bra.w   .ret     ; 36
	bra.w   .ret     ; 37
	bra.w   .ret     ; 38
	bra.w   .ret     ; 39
	bra.w   .seq_40  ; 40  - SEQ_TIMEUP_BUS_FAR
	bra.w   .seq_41  ; 41
	bra.w   .seq_42  ; 42
	bra.w   .ret     ; 43
	bra.w   .ret     ; 44
	bra.w   .ret     ; 45
	bra.w   .ret     ; 46
	bra.w   .ret     ; 47
	bra.w   .ret     ; 48
	bra.w   .ret     ; 49
	bra.w   .seq_50  ; 50  - SEQ_GOAL_REACHED
	bra.w   .seq_51  ; 51
	bra.w   .seq_52  ; 52
	bra.w   .ret     ; 53
	bra.w   .ret     ; 54
	bra.w   .ret     ; 55
	bra.w   .ret     ; 56
	bra.w   .ret     ; 57
	bra.w   .ret     ; 58
	bra.w   .ret     ; 59
	bra.w   .seq_60  ; 60  - SEQ_GOAL_REACHED_SCENE1
	bra.w   .seq_61  ; 61
	bra.w   .seq_62  ; 62
	bra.w   .seq_63  ; 63
	bra.w   .ret     ; 64
	bra.w   .ret     ; 65
	bra.w   .ret     ; 66
	bra.w   .ret     ; 67
	bra.w   .ret     ; 68
	bra.w   .ret     ; 69
	bra.w   .seq_70  ; 70  - SEQ_GOAL_REACHED_SCENE2
	bra.w   .seq_71  ; 71
	bra.w   .seq_72  ; 72
	bra.w   .seq_73  ; 73
	bra.w   .seq_74  ; 74
	bra.w   .seq_75  ; 75
	bra.w   .seq_76  ; 76
	bra.w   .seq_77  ; 77
	bra.w   .seq_78  ; 78
	bra.w   .seq_79  ; 79
	bra.w   .seq_80  ; 80  - SEQ_GOAL_REACHED_SCENE3
	bra.w   .seq_81  ; 81
	bra.w   .seq_82  ; 82
	bra.w   .seq_83  ; 83
	bra.w   .seq_84  ; 84
	bra.w   .seq_85  ; 85
	bra.w   .ret     ; 86
	bra.w   .ret     ; 87
	bra.w   .ret     ; 88
	bra.w   .ret     ; 89
	bra.w   .seq_90  ; 90  - SEQ_GOAL_REACHED_SCENE4
	bra.w   .seq_91  ; 91
	bra.w   .seq_92  ; 92
	bra.w   .seq_93  ; 93
	bra.w   .seq_94  ; 94
	bra.w   .seq_95  ; 95
	bra.w   .seq_96  ; 96
	bra.w   .seq_97  ; 97
	bra.w   .ret     ; 98
	bra.w   .ret     ; 99
	bra.w   .seq_100 ; 100 - SEQ_GOAL_REACHED_SCENE5
	bra.w   .seq_101 ; 101
	bra.w   .seq_102 ; 102
	bra.w   .seq_103 ; 103
	bra.w   .seq_104 ; 104
	bra.w   .seq_105 ; 105
	bra.w   .seq_106 ; 106
	bra.w   .ret     ; 107
	bra.w   .ret     ; 108
	bra.w   .ret     ; 109
	bra.w   .seq_110 ; 110 - SEQ_ENDING
	bra.w   .seq_111 ; 111
	bra.w   .seq_112 ; 112
	bra.w   .seq_113 ; 113
	bra.w   .seq_114 ; 114
	bra.w   .seq_115 ; 115
	bra.w   .seq_116 ; 116
	bra.w   .seq_117 ; 117
	bra.w   .seq_118 ; 118
	bra.w   .seq_119 ; 119
	bra.w   .seq_120 ; 120
	bra.w   .seq_121 ; 121
	bra.w   .seq_122 ; 122
	bra.w   .seq_123 ; 123
	bra.w   .seq_124 ; 124
	bra.w   .seq_125 ; 125

.ret:
	rts

.seq_0:   ; SEQ_NORMAL_PLAY_START
	bsr     move_bus_to_end

	bclr.b  #0, (RAM_play_flags).w    ; Ignore user input
	move.b  #1, (RAM_camera_follow_player).w
	bset.b  #1, (RAM_play_flags).w    ; Time running
	move.b  (FPSVAL_1_S).w, (RAM_time_delay).w
	bset.b  #5, (RAM_play_flags).w    ; Can pause
	addq.b  #1, (RAM_sequence_step).w ; Next sequence step

	rts

.seq_1:   ; SEQ_NORMAL_PLAY
	move.w  (RAM_level_size_pixels).w, d0
	subi.w  #426, d0
	cmp.w   (RAM_player_x).w, d0
	bge.s   .seq_1_goal_not_reached

	; Unset "time up" and set "goal reached" flags
	bclr.b  #2, (RAM_play_flags).w
	bset.b  #3, (RAM_play_flags).w

.seq_1_goal_not_reached:
	; Check "time up" and "goal reached" flags and skip if both are unset
	move.b  (RAM_play_flags).w, d0
	andi.b  #$C, d0
	beq.w   .ret

	bclr.b  #5, (RAM_play_flags).w ; Unset "can pause" flag
	bset.b  #0, (RAM_play_flags).w ; Set "ignore user input" flag
	bclr.b  #1, (RAM_play_flags).w ; Unset "time running" flag
	clr.b   (RAM_play_input_down).w
	clr.b   (RAM_play_input_hit).w
	clr.b   (RAM_jump_timeout).w

	btst.b  #2, (RAM_play_flags).w ; Check "time up" flag
	bne.s   .seq_1_time_up

	; Goal reached
	bset.b  #PLAY_INPUT_RIGHT, (RAM_play_input_down).w
	move.b  #SEQ_GOAL_REACHED, (RAM_sequence_step).w
	rts

.seq_1_time_up:
	move.b  (FPSVAL_1_S).w, (RAM_sequence_delay).w

	; Determine whether to set the next sequence step to SEQ_TIMEUP_BUS_FAR
	; or SEQ_TIMEUP_BUS_NEAR depending on the player character's distance
	; from the end of the level
	move.b  #SEQ_TIMEUP_BUS_FAR, (RAM_sequence_step).w
	move.w  (RAM_level_size_pixels).w, d0
	subi.w  #960, d0
	cmp.w   (RAM_player_x).w, d0
	bge     .ret

	move.b  #SEQ_TIMEUP_BUS_NEAR, (RAM_sequence_step).w
	rts

.seq_10:  ; SEQ_INITIAL
	; Start with bus rear door open
	lea     (RAM_anims+ANIM_BUS_DOOR_REAR).w, a0
	move.b  #3, (a0)  ; Current frame
	move.b  #3, 1(a0) ; Last frame
	clr.b   4(a0)     ; Flags (not running, no reverse, no loop)

	bset.b  #0, (RAM_play_flags).w    ; Ignore user input
	bclr.b  #1, (RAM_play_flags).w    ; Time running

	addq.b  #1, (RAM_sequence_step).w ; Next sequence step

	; Check if the initial sequence should be skipped
	cmpi.b  #1, (RAM_level_num).w
	beq.s   .seq_10_skip
	btst.b  #0, (RAM_sequence_flags).w ; Check "skip initial sequence" flag
	bne.s   .seq_10_skip
	bra.s   .seq_10_no_skip

.seq_10_skip:
	bclr.b  #0, (RAM_sequence_flags).w ; Clear "skip initial sequence" flag
	bsr     move_bus_to_end
	move.b  #SEQ_NORMAL_PLAY_START, (RAM_sequence_step).w
.seq_10_no_skip:

	move.b  (FPSVAL_1_S).w, (RAM_sequence_delay).w
	rts

.seq_11:
	; Start bus rear door animation
	move.b  #3, (RAM_anims+ANIM_BUS_DOOR_REAR+4).w ; Set "running" and "reverse" flags

	; Start bus movement
	move.l  (FPSVAL_252_PXSS).w, (RAM_bus_acc).w
	move.l  (FPSVAL_6_PXS).w, (RAM_bus_xvel).w

	move.b  (FPSVAL_2_S).w, (RAM_sequence_delay).w
	clr.b   (RAM_sequence_step).w ; SEQ_NORMAL_PLAY_START = 0
	rts

.seq_20:  ; SEQ_BUS_LEAVING
	; Bus leaves while closing the front door

	; Start bus movement
	move.l  (FPSVAL_252_PXSS).w, (RAM_bus_acc).w
	move.l  (FPSVAL_6_PXS).w, (RAM_bus_xvel).w

	; Close front door
	move.b  (FPSVAL_0_1_S).w, (RAM_anims+ANIM_BUS_DOOR_FRONT+2).w
	ori.b   #3, (RAM_anims+ANIM_BUS_DOOR_FRONT+4).w ; Set "running" and "reverse" flags

	move.b  (FPSVAL_2_S).w, (RAM_sequence_delay).w
	addq.b  #1, (RAM_sequence_step).w ; Next sequence step
	rts

.seq_21:
	; Screen wipes to black
	bset.b  #2, (RAM_sequence_flags).w
	move.b  (FPSVAL_1_S).w, (RAM_sequence_delay).w
	addq.b  #1, (RAM_sequence_step).w ; Next sequence step
	rts

.seq_22:
	move.b  #SEQ_FINISHED, (RAM_sequence_step).w
	rts

.seq_30:  ; SEQ_TIMEUP_BUS_NEAR
	; Skip if the passing car and hen are still visible
	tst.w   (RAM_passing_car_x).w
	bge     .ret
	tst.w   (RAM_hen_x).w
	bge     .ret

	; Stop camera from following player
	clr.b   (RAM_camera_follow_player).w

	; Move camera to end of level
	move.w  (RAM_level_size_pixels).w, d0
	subi.w  #SCREEN_W, d0
	move.w  d0, (RAM_camera_xdest).w
	move.l  (FPSVAL_720_PXS).w, (RAM_camera_xvel).w

	; Ensure the camera is not moving vertically
	clr.l   (RAM_camera_yvel).w

	addq.b  #1, (RAM_sequence_step).w ; Next sequence step
	rts

.seq_31:
	; Skip if the camera is still moving
	tst.l   (RAM_camera_xvel).w
	bne     .ret
	tst.l   (RAM_camera_yvel).w
	bne     .ret

	move.b  (FPSVAL_0_2_S).w, (RAM_sequence_delay).w
	move.b  #SEQ_BUS_LEAVING, (RAM_sequence_step).w
	rts

.seq_40:  ; SEQ_TIMEUP_BUS_FAR
	clr.b   (RAM_camera_follow_player).w
	clr.l   (RAM_camera_xvel).w
	clr.l   (RAM_camera_yvel).w
	bset.b  #2, (RAM_sequence_flags).w ; Wipe out screen
	move.b  (FPSVAL_0_5_S).w, (RAM_sequence_delay).w
	addq.b  #1, (RAM_sequence_step).w
	rts

.seq_41:
	move.b  #PLAYER_STATE_INACTIVE, (RAM_player_state).w

	moveq   #0, d0
	move.w  (RAM_level_size_pixels).w, d0
	subi.w  #SCREEN_W, d0
	swap.w  d0
	move.l  d0, (RAM_camera_x).w
	clr.l   (RAM_camera_y).w

	move.l  #NONE, (RAM_passing_car_x).w
	move.l  #NONE, (RAM_hen_x).w

	bset.b  #1, (RAM_sequence_flags).w ; Wipe in screen
	move.b  (FPSVAL_0_5_S).w, (RAM_sequence_delay).w
	addq.b  #1, (RAM_sequence_step).w
	rts

.seq_42:
	move.b  #SEQ_BUS_LEAVING, (RAM_sequence_step).w
	rts

.seq_50:  ; SEQ_GOAL_REACHED
	move.b  (RAM_level_goal_scene).w, d0
	cmpi.b  #2, d0
	beq.s   .seq_50_scene3
	cmpi.b  #3, d0
	beq.s   .seq_50_scene4

	addq.b  #1, (RAM_sequence_step).w ; Next sequence step
	rts

.seq_50_scene3:
	move.w  (RAM_bus_x).w, d0
	addi.w  #192, d0
	cmp.w   (RAM_player_x).w, d0
	bgt.w   .ret

	; A banana peel is thrown from the right side of the screen
	lea     (RAM_moving_peels+32).w, a0
	move.w  (RAM_level_size_pixels).w, (a0)+
	clr.w   (a0)+
	move.w  #(BUS_Y+72), (a0)+
	clr.w   (a0)+
	move.l  (FPSVAL_M510_PXS).w, (a0)+
	move.l  (FPSVAL_204_PXS).w,  (a0)+
	move.l  (FPSVAL_504_PXSS).w, (a0)+
	move.w  (RAM_bus_x).w, (a0)
	addi.w  #345, (a0)+
	move.w  #256, (a0)+
	clr.b   (a0)
	move.w  #OBJ_BANANA_PEEL, (RAM_objs).w

	addq.b  #1, (RAM_sequence_step).w ; Next sequence step
	rts

.seq_50_scene4:
	move.w  (RAM_bus_x).w, d0
	addi.w  #120, d0
	cmp.w   (RAM_player_x).w, d0
	bge     .ret

	; A bird appears
	lea     (RAM_cutscene_objs+32).w, a0
	move.b  #COBJ_BIRD, (a0)+
	clr.b   (a0)+
	move.w  (RAM_level_size_pixels).w, (a0)
	subi.w  #584, (a0)+
	clr.w   (a0)+
	move.w  #120, (a0)+
	clr.w   (a0)+
	move.l  (FPSVAL_300_PXS).w, (a0)

	; Set animation
	lea     (RAM_anims+ANIM_CUTSCENE_OBJ_2).w, a0
	clr.b   (a0)+
	move.b  #3, (a0)+
	move.b  (FPSVAL_0_1_S).w, (a0)+
	move.b  (FPSVAL_0_1_S).w, (a0)+
	move.b  #5, (a0)  ; Set "running" and "loop" flags

	addq.b  #1, (RAM_sequence_step).w ; Next sequence step
	rts

.seq_51:
	move.w  (RAM_bus_x).w, d0
	addi.w  #256, d0
	cmp.w   (RAM_player_x).w, d0
	bge     .ret

	; Player character decelerates
	move.w  d0, (RAM_player_x).w
	bclr.b  #PLAY_INPUT_RIGHT, (RAM_play_input_down).w
	addq.b  #1, (RAM_sequence_step).w
	rts

.seq_52:
	moveq   #0, d0
	move.b  (RAM_level_goal_scene).w, d0
	lea     .seq_52_scene_map(pc), a0
	move.b  (a0, d0.w), (RAM_sequence_step).w
	rts

.seq_52_scene_map:
	dc.b    SEQ_GOAL_REACHED_SCENE1
	dc.b    SEQ_GOAL_REACHED_SCENE2
	dc.b    SEQ_GOAL_REACHED_SCENE3
	dc.b    SEQ_GOAL_REACHED_SCENE4
	dc.b    SEQ_GOAL_REACHED_SCENE5
	even

.seq_60:  ; SEQ_GOAL_REACHED_SCENE1
	move.w  (RAM_bus_x).w, d0
	addi.w  #342, d0
	cmp.w   (RAM_player_x).w, d0
	blt.s   .seq_60_player_jump
	tst.l   (RAM_player_xvel).w
	ble.s   .seq_60_player_jump
	rts

.seq_60_player_jump:
	; Player character jumps into the bus
	move.w  d0, (RAM_player_x).w
	clr.w   (RAM_player_x+2).w
	clr.l   (RAM_player_xvel).w
	move.b  (FPSVAL_0_2_S).w, (RAM_jump_timeout).w ; Trigger a jump

	addq.b  #1, (RAM_sequence_step).w ; Next sequence step
	rts

.seq_61:
	tst.l   (RAM_player_yvel).w
	ble     .ret

	move.w  #BUS_Y, d0
	addi.w  #36, d0
	cmp.w   (RAM_player_y).w, d0
	bge     .ret

	; Player character is now in the bus and score count starts
	bsr     show_player_in_bus
	bsr     start_score_count
	addq.b  #1, (RAM_sequence_step).w
	rts

.seq_62:
	btst.b  #4, (RAM_play_flags).w ; Check "counting score" flag
	bne     .ret

	; Score count finished
	move.b  (FPSVAL_0_5_S).w, (RAM_sequence_delay).w
	addq.b  #1, (RAM_sequence_step).w ; Next sequence step
	rts

.seq_63:
	move.b  #SEQ_BUS_LEAVING, (RAM_sequence_step).w
	rts

.seq_70:  ; SEQ_GOAL_REACHED_SCENE2
	move.w  (RAM_bus_x).w, d0
	addi.w  #342, d0
	cmp.w   (RAM_player_x).w, d0
	blt.s   .seq_70_player_jump
	tst.l   (RAM_player_xvel).w
	ble.s   .seq_70_player_jump
	rts

.seq_70_player_jump:
	; Player character jumps into the bus
	move.w  d0, (RAM_player_x).w
	clr.w   (RAM_player_x+2).w
	clr.l   (RAM_player_xvel).w
	move.b  (FPSVAL_0_2_S).w, (RAM_jump_timeout).w ; Trigger a jump

	addq.b  #1, (RAM_sequence_step).w ; Next sequence step
	rts

.seq_71:
	tst.l   (RAM_player_yvel).w
	ble     .ret

	move.w  #BUS_Y, d0
	addi.w  #36, d0
	cmp.w   (RAM_player_y).w, d0
	bge     .ret

	bsr     show_player_in_bus
	bsr     start_score_count
	addq.b  #1, (RAM_sequence_step).w
	rts

.seq_72:
	btst.b  #4, (RAM_play_flags).w ; Check "counting score" flag
	bne     .ret

	; Score count finished
	move.b  (FPSVAL_0_5_S).w, (RAM_sequence_delay).w
	addq.b  #1, (RAM_sequence_step).w ; Next sequence step
	rts

.seq_73:
	; Close front door
	move.b  (FPSVAL_0_1_S).w, (RAM_anims+ANIM_BUS_DOOR_FRONT+2).w
	ori.b   #3, (RAM_anims+ANIM_BUS_DOOR_FRONT+4).w ; Set "running" and "reverse" flags

	move.b  (FPSVAL_0_5_S).w, (RAM_sequence_delay).w
	addq.b  #1, (RAM_sequence_step).w ; Next sequence step
	rts

.seq_74:
	; Hide player character
	clr.b   (RAM_cutscene_objs).w

	; Bearded man comes from the right side of the screen
	lea     (RAM_cutscene_objs+32).w, a0
	move.b  #COBJ_BEARDED_MAN_WALK, (a0)+ ; type
	clr.b   (a0)+ ; in_bus
	move.w  (RAM_level_size_pixels).w, (a0)+ ; x
	clr.w   (a0)+
	move.w  #203, (a0)+ ; y
	clr.w   (a0)+
	move.l  (FPSVAL_M150_PXS).w, (a0)+ ; xvel

	; Set animation
	lea     (RAM_anims+ANIM_CUTSCENE_OBJ_2).w, a0
	clr.b   (a0)+
	move.b  #5, (a0)+
	move.b  (FPSVAL_0_1_S).w, (a0)+
	move.b  (FPSVAL_0_1_S).w, (a0)+
	move.b  #5, (a0) ; Flags (running, no reverse, loop)

	addq.b  #1, (RAM_sequence_step).w ; Next sequence step
	rts

.seq_75:
	lea     (RAM_cutscene_objs+32).w, a0

	move.w  (RAM_bus_x).w, d0
	addi.w  #380, d0

	cmp.w   2(a0), d0
	ble     .ret

	; Bearded man decelerates
	move.w  d0, 2(a0)
	clr.w   4(a0)
	move.l  (FPSVAL_252_PXSS).w, 18(a0)

	addq.b  #1, (RAM_sequence_step).w ; Next sequence step
	rts

.seq_76:
	lea     (RAM_cutscene_objs+32).w, a0

	; Check if the bearded man has stopped
	tst.l   10(a0)
	bge.s   .seq_76_bearded_man_stopped
	move.w  (RAM_bus_x).w, d0
	addi.w  #337, d0
	cmp.w   2(a0), d0
	bge.s   .seq_76_bearded_man_stopped
	rts

.seq_76_bearded_man_stopped:
	lea     (RAM_cutscene_objs+32).w, a0

	; Find X position the bearded man stops at
	move.w  (RAM_bus_x).w, d0
	addi.w  #337, d0

	; Bearded man stops
	move.b  #COBJ_BEARDED_MAN_STAND, (a0)
	move.w  d0, 2(a0)
	clr.w   4(a0)
	clr.l   10(a0)
	clr.l   18(a0)

	; Bus front door opens
	move.b  (FPSVAL_0_1_S).w, (RAM_anims+ANIM_BUS_DOOR_FRONT+2).w
	move.b  #1, (RAM_anims+ANIM_BUS_DOOR_FRONT+4).w ; Set "running" flag

	move.b  (FPSVAL_0_5_S).w, (RAM_sequence_delay).w
	addq.b  #1, (RAM_sequence_step).w ; Next sequence step
	rts

.seq_77:
	lea     (RAM_cutscene_objs+32).w, a0

	; Bearded man jumps into the bus
	move.b  #COBJ_BEARDED_MAN_JUMP, (a0)
	move.l  (FPSVAL_M156_PXS).w, 14(a0)
	move.l  (FPSVAL_234_PXSS).w, 22(a0)

	addq.b  #1, (RAM_sequence_step).w ; Next sequence step
	rts

.seq_78:
	lea     (RAM_cutscene_objs+32).w, a0

	move.w  #(BUS_Y+35), d0
	cmp.w   6(a0), d0
	bge     .ret
	tst.l   14(a0)
	ble     .ret

	; Bearded man is now in the bus
	move.b  #COBJ_BEARDED_MAN_STAND, (a0)
	st.b    1(a0)
	clr.l   22(a0)
	clr.l   14(a0)
	move.w  d0, 6(a0)
	clr.w   8(a0)

	; Make bearded man's X position relative to the bus
	move.l  (RAM_bus_x).w, d0
	sub.l   d0, 2(a0)

	move.b  (FPSVAL_0_2_S).w, (RAM_sequence_delay).w
	addq.b  #1, (RAM_sequence_step).w ; Next sequence step
	rts

.seq_79:
	move.b  #SEQ_BUS_LEAVING, (RAM_sequence_step).w
	rts

.seq_80:  ; SEQ_GOAL_REACHED_SCENE3
	cmpi.b  #PLAYER_STATE_SLIP, (RAM_player_state).w
	bne     .ret

	move.b  (FPSVAL_0_7_S).w, (RAM_sequence_delay).w
	addq.b  #1, (RAM_sequence_step).w ; Next sequence step
	rts

.seq_81:
	bset.b  #PLAY_INPUT_RIGHT, (RAM_play_input_hit).w

	cmpi.b  #PLAYER_STATE_GETUP, (RAM_player_state).w
	bne     .ret

	; Player character gets up after slipping on a banana peel and starts
	; walking again
	bset.b  #PLAY_INPUT_RIGHT, (RAM_play_input_down).w
	bclr.b  #PLAY_INPUT_RIGHT, (RAM_play_input_hit).w

	addq.b  #1, (RAM_sequence_step).w ; Next sequence step
	rts

.seq_82:
	move.w  (RAM_bus_x).w, d0
	addi.w  #342, d0
	cmp.w   (RAM_player_x).w, d0
	bge     .ret

	; Player character jumps into the bus
	move.w  d0, (RAM_player_x).w
	clr.w   (RAM_player_x+2).w
	clr.l   (RAM_player_xvel).w
	bclr.b  #PLAY_INPUT_RIGHT, (RAM_play_input_down).w
	move.b  (FPSVAL_0_2_S).w, (RAM_jump_timeout).w ; Trigger a jump

	addq.b  #1, (RAM_sequence_step).w ; Next sequence step
	rts

.seq_83:
	bclr.b  #PLAY_INPUT_JUMP, (RAM_play_input_down).w

	tst.l   (RAM_player_yvel).w
	ble     .ret

	move.w  #BUS_Y, d0
	addi.w  #36, d0
	cmp.w   (RAM_player_y).w, d0
	bge     .ret

	; Player character is now in the bus and score count starts
	bsr     show_player_in_bus
	bsr     start_score_count
	addq.b  #1, (RAM_sequence_step).w
	rts

.seq_84:
	btst.b  #4, (RAM_play_flags).w
	bne     .ret

	; Score count finished
	move.b  (FPSVAL_0_5_S).w, (RAM_sequence_delay).w
	addq.b  #1, (RAM_sequence_step).w ; Next sequence step
	rts

.seq_85:
	move.b  #SEQ_BUS_LEAVING, (RAM_sequence_step).w
	rts

.seq_90:   ; SEQ_GOAL_REACHED_SCENE4
	move.w  (RAM_bus_x).w, d0
	addi.w  #342, d0
	cmp.w   (RAM_player_x).w, d0
	bge.s   .seq_90_player_dest_not_reached

	; Player character stops at bus front door
	swap.w  d0
	clr.w   d0
	move.l  d0, (RAM_player_x).w
	clr.l   (RAM_player_xvel).w
.seq_90_player_dest_not_reached:

	lea     (RAM_cutscene_objs+32).w, a0

	move.w  (RAM_bus_x).w, d0
	addi.w  #354, d0
	cmp.w   2(a0), d0
	bge     .ret

	; Bird dung appears
	lea     (RAM_cutscene_objs).w, a0
	move.b  #COBJ_DUNG, (a0)+
	clr.b   (a0)+
	swap.w  d0
	clr.w   d0
	move.l  d0, (a0)+
	move.w  #120, (a0)+
	clr.w   (a0)+
	clr.l   (a0)+
	move.l  (FPSVAL_252_PXS).w, (a0)

	addq.b  #1, (RAM_sequence_step).w ; Next sequence step
	rts

.seq_91:
	lea     (RAM_cutscene_objs).w, a0

	move.w  (RAM_player_y).w, d0
	addi.w  #12, d0
	cmp.w   6(a0), d0
	bge     .ret

	bclr.b  #0, (RAM_player_flags).w ; Clear "visible" flag

	; Bird dung hits the player character
	move.b  #COBJ_PLAYER_CLEAN_DUNG, (a0)+
	clr.b   (a0)+
	move.w  (RAM_player_x).w, (a0)+
	clr.w   (a0)+
	move.w  (RAM_player_y).w, (a0)+
	clr.w   (a0)+
	clr.l   (a0)+
	clr.l   (a0)

	move.b  (FPSVAL_0_2_S).w, (RAM_sequence_delay).w
	addq.b  #1, (RAM_sequence_step).w ; Next sequence step
	rts

.seq_92:
	; Player character cleans the dung
	lea     (RAM_anims+ANIM_CUTSCENE_OBJ_1).w, a0
	clr.b   (a0)+
	move.b  #8, (a0)+
	move.b  (FPSVAL_0_2_S).w, (a0)+
	move.b  (FPSVAL_0_2_S).w, (a0)+
	move.b  #1, (a0)   ; Set "running" flag

	move.b  (FPSVAL_2_S).w, (RAM_sequence_delay).w
	addq.b  #1, (RAM_sequence_step).w ; Next sequence step
	rts

.seq_93:
	; Player character finishes cleaning the dung
	bset.b  #0, (RAM_player_flags).w ; Set "visible" flag
	clr.b   (RAM_cutscene_objs).w

	move.b  (FPSVAL_0_2_S).w, (RAM_sequence_delay).w
	addq.b  #1, (RAM_sequence_step).w ; Next sequence step
	rts

.seq_94:
	move.b  (FPSVAL_0_2_S).w, (RAM_jump_timeout).w ; Trigger a jump

	addq.b  #1, (RAM_sequence_step).w ; Next sequence step
	rts

.seq_95:
	tst.l   (RAM_player_yvel).w
	ble     .ret

	move.w  #BUS_Y, d0
	addi.w  #36, d0
	cmp.w   (RAM_player_y).w, d0
	bge     .ret

	; Player character is now in the bus and score count starts
	bsr     show_player_in_bus
	bsr     start_score_count
	addq.b  #1, (RAM_sequence_step).w
	rts

.seq_96:
	btst.b  #4, (RAM_play_flags).w
	bne     .ret

	; Score count finished
	move.b  (FPSVAL_0_5_S).w, (RAM_sequence_delay).w
	addq.b  #1, (RAM_sequence_step).w ; Next sequence step
	rts

.seq_97:
	move.b  #SEQ_BUS_LEAVING, (RAM_sequence_step).w
	rts

.seq_100:  ; SEQ_GOAL_REACHED_SCENE5
	move.w  (RAM_bus_x).w, d0
	addi.w  #342, d0
	cmp.w   (RAM_player_x).w, d0
	blt.s   .seq_100_player_jump
	tst.l   (RAM_player_xvel).w
	ble.s   .seq_100_player_jump
	rts

.seq_100_player_jump:
	; Player character jumps into the bus
	move.w  d0, (RAM_player_x).w
	clr.w   (RAM_player_x+2).w
	clr.l   (RAM_player_xvel).w
	move.b  (FPSVAL_0_2_S).w, (RAM_jump_timeout).w ; Trigger a jump

	addq.b  #1, (RAM_sequence_step).w ; Next sequence step
	rts

.seq_101:
	; Bus leaves before the player character can enter it
	move.l  (FPSVAL_252_PXSS).w, (RAM_bus_acc).w
	move.l  (FPSVAL_6_PXS).w, (RAM_bus_xvel).w

	; Close front door
	move.b  (FPSVAL_0_1_S).w, (RAM_anims+ANIM_BUS_DOOR_FRONT+2).w
	ori.b   #3, (RAM_anims+ANIM_BUS_DOOR_FRONT+4).w ; Set "running" and "reverse" flags

	addq.b  #1, (RAM_sequence_step).w ; Next sequence step
	rts

.seq_102:
	; Wait until the bus is 32 pixels to the right of the level's boundary
	move.w  (RAM_level_size_pixels).w, d0
	addi.w  #32, d0
	cmp.w   (RAM_bus_x).w, d0
	bge     .ret

	lea     (RAM_cutscene_objs).w, a0

	; Player character starts running crazily
	clr.l   (RAM_bus_acc).w
	clr.l   (RAM_bus_xvel).w
	bclr.b  #0, (RAM_player_flags).w ; Clear "visible" flag
	move.b  #COBJ_PLAYER_RUN, (a0)
	move.l  (RAM_player_x).w, 2(a0)
	move.l  (RAM_player_y).w, 6(a0)
	move.l  (FPSVAL_126_PXS).w, 10(a0)
	move.l  (FPSVAL_504_PXSS).w, 18(a0)

	; Start player character running animation
	lea     (RAM_anims+ANIM_CUTSCENE_OBJ_1).w, a0
	clr.b   (a0)+
	move.b  #3, (a0)+
	move.b  (FPSVAL_0_1_S).w, (a0)+
	move.b  (FPSVAL_0_1_S).w, (a0)+
	move.b  #5, (a0)  ; Set "running" and "loop" flags

	addq.b  #1, (RAM_sequence_step).w ; Next sequence step
	rts

.seq_103:
	lea     (RAM_cutscene_objs).w, a0

	; Wait until the player character is 32 pixels to the right of the
	; level's boundary
	move.w  (RAM_level_size_pixels).w, d0
	addi.w  #32, d0
	cmp.w   2(a0), d0
	bge     .ret

	; Score count starts
	bsr     start_score_count
	clr.l   18(a0)
	clr.l   10(a0)

	addq.b  #1, (RAM_sequence_step).w ; Next sequence step
	rts

.seq_104:
	; Wait until the score count ends
	btst.b  #4, (RAM_play_flags).w
	bne     .ret

	move.b  (FPSVAL_0_5_S).w, (RAM_sequence_delay).w
	addq.b  #1, (RAM_sequence_step).w ; Next sequence step
	rts

.seq_105:
	; Screen wipes to black
	bset.b  #2, (RAM_sequence_flags).w
	move.b  (FPSVAL_1_S).w, (RAM_sequence_delay).w
	addq.b  #1, (RAM_sequence_step).w ; Next sequence step
	rts

.seq_106:
	move.b  #SEQ_FINISHED, (RAM_sequence_step).w
	rts

.seq_110:  ; SEQ_ENDING
	bclr.b  #0, (RAM_player_flags).w ; Clear "visible" flag
	move.b  #PLAYER_STATE_INACTIVE, (RAM_player_state).w

	move.w  #672, (RAM_camera_x).w

	move.w  #96, (RAM_bus_x).w
	move.w  #96, (RAM_bus_init_x).w
	clr.l   (RAM_bus_xvel).w

	lea     (RAM_cutscene_objs+32).w, a0
	move.b  #COBJ_FLAGMAN, (a0)+
	clr.b   (a0)+
	move.w  #992, (a0)+
	clr.w   (a0)+
	move.w  #180, (a0)

	; Setup flagman animation
	lea     (RAM_anims+ANIM_CUTSCENE_OBJ_2).w, a0
	move.b  #3, (a0)+
	move.b  #3, (a0)+
	move.b  (FPSVAL_0_1_S).w, (a0)+
	move.b  (FPSVAL_0_1_S).w, (a0)+
	clr.b   (a0) ; Clear all flags

	; Setup car wheels animation
	lea     (RAM_anims+ANIM_CAR_WHEELS).w, a0
	move.b  #0, (a0)+
	move.b  #1, (a0)+
	move.b  (FPSVAL_0_1_S).w, (a0)+
	move.b  (FPSVAL_0_1_S).w, (a0)+
	move.b  #4, (a0)  ; Set "loop" flag

	move.b  (FPSVAL_1_S).w, (RAM_sequence_delay).w
	addq.b  #1, (RAM_sequence_step).w ; Next sequence step
	rts

.seq_111:
	; Camera moves to the right
	move.l  (FPSVAL_180_PXS).w, (RAM_camera_xvel).w
	move.w  #992, (RAM_camera_xdest).w

	move.b  (FPSVAL_3_S).w, (RAM_sequence_delay).w
	addq.b  #1, (RAM_sequence_step).w ; Next sequence step
	rts

.seq_112:
	; Traffic jam starts moving
	move.l  (FPSVAL_72_PXS).w, (RAM_bus_xvel).w

	; Start car wheels animation
	bset.b  #0, (RAM_anims+ANIM_CAR_WHEELS+4).w

	addq.b  #1, (RAM_sequence_step).w ; Next sequence step
	rts

.seq_113:
	move.w  #232, d0
	cmp.w   (RAM_bus_x).w, d0
	bge     .ret

	; Traffic jam stops
	swap.w  d0
	clr.w   d0
	move.l  d0, (RAM_bus_x).w
	clr.l   (RAM_bus_xvel).w

	; Stop car wheels animation
	lea     (RAM_anims+ANIM_CAR_WHEELS).w, a0
	clr.b   (a0)
	bclr.b  #0, 4(a0)

	move.b  (FPSVAL_1_S).w, (RAM_sequence_delay).w
	addq.b  #1, (RAM_sequence_step).w ; Next sequence step
	rts

.seq_114:
	; Player character appears from the left side of the screen and is
	; running crazily
	lea     (RAM_cutscene_objs).w, a0
	move.b  #COBJ_PLAYER_RUN, (a0)+
	clr.b   (a0)+
	move.w  #744, (a0)+
	clr.w   (a0)+
	move.w  #204, (a0)+
	clr.w   (a0)+
	move.l  (FPSVAL_210_PXS).w, (a0)

	lea     (RAM_anims+ANIM_CUTSCENE_OBJ_1).w, a0
	clr.b   (a0)+
	move.b  #3, (a0)+
	move.b  (FPSVAL_0_1_S).w, (a0)+
	move.b  (FPSVAL_0_1_S).w, (a0)+
	move.b  #5, (a0)  ; Set "running" and "loop" flags

	addq.b  #1, (RAM_sequence_step).w ; Next sequence step
	rts

.seq_115:
	btst.b  #3, (RAM_sequence_flags).w
	bne.s   .seq_115_no_flag_swing

	lea     (RAM_cutscene_objs).w, a0
	move.w  2(a0), d0 ; X position of the player character
	lea     32(a0), a0
	move.w  2(a0), d1 ; X position of the flagman

	cmp.w   d0, d1
	bgt.s   .seq_115_no_flag_swing

	; Player character reaches the flagman, who swings the flag
	lea     (RAM_anims+ANIM_CUTSCENE_OBJ_2).w, a0
	clr.b   (a0)
	bset.b  #0, 4(a0) ; Set "running" flag
	bset.b  #3, (RAM_sequence_flags).w
.seq_115_no_flag_swing:

	lea     (RAM_cutscene_objs).w, a0

	move.w  #1128, d0
	cmp.w   2(a0), d0
	bge     .ret

	; Player character decelerates
	swap.w  d0
	clr.w   d0
	move.l  d0, 2(a0)
	move.l  (FPSVAL_M252_PXSS).w, 18(a0)

	addq.b  #1, (RAM_sequence_step).w ; Next sequence step
	rts

.seq_116:
	lea     (RAM_cutscene_objs).w, a0

	; Check if the player character's animation needs to be changed from
	; "running" to "walking"
	move.l  (FPSVAL_180_PXS).w, d0
	cmp.l   10(a0), d0
	ble.s   .seq_116_no_player_change
	cmpi.b  #COBJ_PLAYER_WALK, (a0)
	beq.s   .seq_116_no_player_change

	move.b  #COBJ_PLAYER_WALK, (a0)
	addi.l  #(8<<16), 2(a0)
.seq_116_no_player_change:

	move.w  #1216, d0
	cmp.w   2(a0), d0
	blt.s   .seq_116_player_stopped
	tst.l   10(a0)
	ble.s   .seq_116_player_stopped

	rts

.seq_116_player_stopped:
	; Player character stops
	move.b  #COBJ_PLAYER_STAND, (a0)
	swap.w  d0
	clr.w   d0
	move.l  d0, 2(a0)
	clr.l   10(a0)
	clr.l   18(a0)

	lea     (RAM_anims+ANIM_CUTSCENE_OBJ_1).w, a0
	clr.w   (a0)
	clr.b   4(a0) ; Clear all flags

	addq.b  #1, (RAM_sequence_step).w ; Next sequence step
	rts

.seq_117:
	; Traffic jam starts moving
	move.l  (FPSVAL_72_PXS).w, (RAM_bus_xvel).w

	; Start car wheels animation
	bset.b  #0, (RAM_anims+ANIM_CAR_WHEELS+4).w

	addq.b  #1, (RAM_sequence_step).w ; Next sequence step
	rts

.seq_118:
	move.w  #504, d0
	cmp.w   (RAM_bus_x).w, d0
	bge     .ret

	; Traffic jam stops
	swap.w  d0
	clr.w   d0
	move.l  d0, (RAM_bus_x).w
	clr.l   (RAM_bus_xvel).w

	; Stop car wheels animation
	lea     (RAM_anims+ANIM_CAR_WHEELS).w, a0
	clr.b   (a0)
	bclr.b  #0, 4(a0)

	move.b  (FPSVAL_1_S).w, (RAM_sequence_delay).w
	addq.b  #1, (RAM_sequence_step).w ; Next sequence step
	rts

.seq_119:
	move.w  #760, d0
	move.w  d0, (RAM_hen_x).w
	clr.w   (RAM_hen_x+2).w

	move.l  (FPSVAL_360_PXS).w, (RAM_hen_xvel).w

	lea     (RAM_anims+ANIM_HEN).w, a0
	clr.b   (a0)+
	move.b  #3, (a0)+
	move.b  (FPSVAL_0_05_S).w, (a0)+
	move.b  (FPSVAL_0_05_S).w, (a0)+
	move.b  #5, (a0)  ; Set "running" and "loop" flags

	addq.b  #1, (RAM_sequence_step).w ; Next sequence step
	rts

.seq_120:
	move.w  #944, d0
	cmp.w   (RAM_hen_x).w, d0
	bge     .ret

	; Hen decelerates
	swap.w  d0
	clr.w   d0
	move.l  d0, (RAM_hen_x).w
	move.l  (FPSVAL_M252_PXSS).w, (RAM_hen_acc).w

	addq.b  #1, (RAM_sequence_step).w ; Next sequence step
	rts

.seq_121:
	btst.b  #4, (RAM_sequence_flags).w
	bne.s   .seq_121_no_flag_swing

	move.w  (RAM_hen_x).w, d0 ; X position of the hen

	lea     (RAM_cutscene_objs+32).w, a0
	move.w  2(a0), d1 ; X position of the flagman

	cmp.w   d0, d1
	bgt.s   .seq_121_no_flag_swing

	; Hen reaches the flagman, who swings the flag
	lea     (RAM_anims+ANIM_CUTSCENE_OBJ_2).w, a0
	clr.b   (a0)
	bset.b  #0, 4(a0) ; Set "running" flag
	bset.b  #4, (RAM_sequence_flags).w
.seq_121_no_flag_swing:

	move.w  #1176, d0
	cmp.w   (RAM_hen_x).w, d0
	blt.s   .seq_121_hen_stopped
	tst.l   (RAM_hen_xvel).w
	ble.s   .seq_121_hen_stopped

	rts

.seq_121_hen_stopped:
	; Hen stops
	swap.w  d0
	clr.w   d0
	move.l  d0, (RAM_hen_x).w
	clr.l   (RAM_hen_xvel).w
	clr.l   (RAM_hen_acc).w

	lea     (RAM_anims+ANIM_HEN).w, a0
	move.b  #1, (a0)
	clr.b   4(a0) ; Clear all flags

	move.b  (FPSVAL_1_S).w, (RAM_sequence_delay).w
	addq.b  #1, (RAM_sequence_step).w ; Next sequence step
	rts

.seq_122:
	; Traffic jam starts moving
	move.l  (FPSVAL_72_PXS).w, (RAM_bus_xvel).w

	; Start car wheels animation
	bset.b  #0, (RAM_anims+ANIM_CAR_WHEELS+4).w

	addq.b  #1, (RAM_sequence_step).w ; Next sequence step
	rts

.seq_123:
	move.w  #764, d0
	cmp.w   (RAM_bus_x).w, d0
	bge     .ret

	; Bus reaches the flagman, who swings the flag
	lea     (RAM_anims+ANIM_CUTSCENE_OBJ_2).w, a0
	clr.b   (a0)
	bset.b  #0, 4(a0) ; Set "running" flag
	bset.b  #5, (RAM_sequence_flags).w

	; Traffic jam stops
	swap.w  d0
	clr.w   d0
	move.l  d0, (RAM_bus_x).w
	clr.l   (RAM_bus_xvel).w

	; Stop car wheels animation
	lea     (RAM_anims+ANIM_CAR_WHEELS).w, a0
	clr.b   (a0)
	bclr.b  #0, 4(a0)

	; Bus front door opens
	lea     (RAM_anims+ANIM_BUS_DOOR_FRONT).w, a0
	move.b  #1, 4(a0) ; Set "running" flag

	move.b  (FPSVAL_3_S).w, (RAM_sequence_delay).w
	addq.b  #1, (RAM_sequence_step).w ; Next sequence step
	rts

.seq_124:
	; Screen wipes to black
	bset.b  #2, (RAM_sequence_flags).w

	move.b  (FPSVAL_1_S).w, (RAM_sequence_delay).w
	addq.b  #1, (RAM_sequence_step).w ; Next sequence step
	rts

.seq_125:
	move.b  #SEQ_FINISHED, (RAM_sequence_step).w
	rts

