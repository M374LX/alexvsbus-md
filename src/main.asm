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
; main.asm
;
; Description:
; The main source file, which includes the main loop
;

; ------------------------------------------------------------------------------

main:
	move.b  #SCR_NONE, d0
	move.b  d0, (RAM_screen_type).w
	move.b  d0, (RAM_screen_type_next).w

	bsr     sound_init
	bsr     renderer_init
	bsr     load_fps_values
	bsr     sram_load
	bsr     show_title

main_loop:
	bsr     joypad_update
	bsr     check_wait_input_up
	bsr     update_current_screen
	bsr     handle_delayed_action
	bsr     update_screen_wipe
	bsr     renderer_draw

	bra.s   main_loop 

; ------------------------------------------------------------------------------

check_wait_input_up:
	tst.b   (RAM_wait_input_up).w
	bne.s   .waiting
	rts

.waiting:
	tst.w   (RAM_joystate_down).w
	beq.s   .wait_ended

	clr.w   (RAM_joystate_down).w
	clr.w   (RAM_joystate_hit).w
	rts

.wait_ended:
	clr.b   (RAM_wait_input_up).w
	rts

; ------------------------------------------------------------------------------

update_current_screen:
	moveq   #0, d0
	move.b  (RAM_screen_type).w, d0
	add.w   d0, d0
	jmp     .screen_jump_table(pc, d0.w)

.screen_jump_table:
	bra.s   .nop      ; SCR_NONE
	bra.s   .scr_menu ; SCR_MENU
	bra.s   .nop      ; SCR_FINALSCORE
	bra.s   .scr_play ; SCR_PLAY

.nop:
	rts

.scr_menu:
	bsr     menu_update
	bra     handle_menu_action

.scr_play:
	bsr     play_set_input
	bsr     play_update
	bsr     check_game_progress
	bsr     handle_level_end
	bra     handle_pause

; ------------------------------------------------------------------------------

handle_menu_action:
	tst.b   (RAM_menu_action).w
	beq.s   .no_action

	bsr     menu_close_all
	st.b    (RAM_wait_input_up).w

	moveq   #0, d0
	move.b  (RAM_menu_action).w, d0
	add.w   d0, d0
	jmp     .menu_actions_jump_table(pc, d0.w)

.menu_actions_jump_table:
	bra.s   .no_action ; MENUACT_NONE
	bra.s   .title     ; MENUACT_TITLE
	bra.s   .play      ; MENUACT_PLAY
	bra.s   .resume    ; MENUACT_RESUME
	bra.s   .try_again ; MENUACT_TRY_AGAIN

.title:
	bra     show_title

.play:
	move.b  #DELACT_START_PLAY, (RAM_delayed_action_type).w
	move.b  (FPSVAL_0_7_S).w, (RAM_action_delay).w
	rts

.resume:
	move.b  #SCR_PLAY, (RAM_screen_type_next).w
	bset.b  #0, RAM_force_full_redraw
	rts

.try_again:
	clr.l   (RAM_score).w
	bsr     start_level
	bset.b  #0, (RAM_sequence_flags).w ; Set "skip initial sequence" flag

.no_action:
	rts

; ------------------------------------------------------------------------------

handle_delayed_action:
	; If there is no delayed action, skip
	tst.b   (RAM_delayed_action_type).w
	beq.s   .ret

	; If the delay for the action has ended, do the action
	tst.b   (RAM_action_delay).w
	beq.s   .do_action

	; Otherwise, decrease the delay
	subq.b  #1, (RAM_action_delay).w
	rts

.do_action:
	moveq   #0, d0
	move.b  (RAM_delayed_action_type).w, d0
	clr.b   (RAM_delayed_action_type).w
	add.w   d0, d0
	jmp     .delayed_actions_jump_table(pc, d0.w)

.delayed_actions_jump_table:
	bra.s   .ret             ; DELACT_NONE
	bra.s   .start_play      ; DELACT_START_PLAY
	bra.s   .next_difficulty ; DELACT_NEXT_DIFFICULTY
	bra.s   .title           ; DELACT_TITLE

.start_play:
	clr.l   (RAM_score).w
	bra     start_level

.next_difficulty:
	addq.b  #1, (RAM_difficulty).w
	move.b  #1, (RAM_level_num).w
	bra     start_level

.title:
	bra     show_title

.ret:
	rts

; ------------------------------------------------------------------------------

update_screen_wipe:
	move.b  (RAM_sequence_flags).w, d0
	btst.l  #1, d0
	beq.s   .no_wipe_in
	move.b  #WIPECMD_IN, (RAM_wipe_cmd).w

.no_wipe_in:
	btst.l  #2, d0
	beq.s   .no_wipe_out
	move.b  #WIPECMD_OUT, (RAM_wipe_cmd).w

.no_wipe_out:
	rts

; ------------------------------------------------------------------------------

handle_pause:
	; Check "can pause" flag
	btst.b  #5, (RAM_play_flags).w
	beq.s   .no_pause

	; Check Start button
	move.w  (RAM_joystate_hit).w, d0
	btst.l  #7, d0
	beq.s   .no_pause

	st.b    (RAM_wait_input_up).w

	; Open pause menu
	move.b  #SCR_MENU, (RAM_screen_type_next).w
	moveq   #MENU_PAUSE, d0
	bra     menu_open

.no_pause:
	rts

; ------------------------------------------------------------------------------

handle_level_end:
	move.b  (RAM_sequence_step).w, d0
	cmpi.b  #SEQ_FINISHED, d0
	beq.s   .level_ended
	rts

.level_ended:
	move.b  (RAM_play_flags).w, d0

	btst.l  #2, d0 ; Check "time up" flag
	bne.s   .try_again
	btst.l  #6, d0 ; Check "is last level" flag
	bne.s   .last_level
	btst.l  #7, d0 ; Check "is ending sequence" flag
	bne.s   .final_score

	; Move to next level
	addq.b  #1, (RAM_level_num).w
	bra.s   start_level

.try_again:
	; Remove screen wipe
	move.b  #WIPECMD_CLEAR, (RAM_wipe_cmd).w

	bsr     sound_stop

	move.b  #SCR_MENU, (RAM_screen_type_next).w
	moveq   #MENU_TRY_AGAIN, d0
	bra     menu_open

.last_level:
	cmpi.b  #DIFFICULTY_MAX, (RAM_difficulty).w
	bge.s   .final_score

	bra     start_ending_sequence

.final_score:
	move.b  #SCR_FINALSCORE, (RAM_screen_type_next).w

	move.b  #DELACT_NEXT_DIFFICULTY, (RAM_delayed_action_type).w
	cmpi.b  #DIFFICULTY_MAX, (RAM_difficulty).w
	blt.s   .final_score_not_last_difficulty
	move.b  #DELACT_TITLE, (RAM_delayed_action_type).w
.final_score_not_last_difficulty:

	move.b  (FPSVAL_4_S).w, (RAM_action_delay).w

	; Remove screen wipe
	move.b  #WIPECMD_CLEAR, (RAM_wipe_cmd).w

	rts

; ------------------------------------------------------------------------------

show_title:
	bsr     menu_close_all

	move.b  #SCR_MENU, (RAM_screen_type_next).w
	moveq   #MENU_MAIN, d0
	bsr     menu_open

	clr.l   (RAM_score).w
	clr.b   (RAM_difficulty).w
	clr.b   (RAM_level_num).w

	bsr     sound_stop

	; Play title BGM
	moveq   #3, d0
	bsr     sound_play_bgm

	; Remove screen wipe
	move.b  #WIPECMD_CLEAR, (RAM_wipe_cmd).w

	rts

; ------------------------------------------------------------------------------

start_level:
	bsr     play_clear

	; Find pointer to level data and store it in a0
	moveq   #0, d0
	moveq   #0, d1
	move.b  (RAM_difficulty).w, d0
	add.b   d0, d0
	add.b   d0, d0
	add.b   d0, d0
	add.b   d0, d0
	move.b  (RAM_level_num).w, d1
	add.b   d1, d1
	add.b   d1, d0
	lea     DATA_levels, a0
	adda.w  d0, a0

	; Set route sign for the bus at the start of the level
	; Note: we subtract one from the level number because there is no sign
	; numbered one and thus value 1 refers to sign 2 while value 2 refers to
	; sign 3 and so on
	move.b  (RAM_level_num).w, (RAM_bus_route_sign).w
	subq.b  #1, (RAM_bus_route_sign).w

	; If the next level pointer is zero, this is the last level
	tst.w   2(a0)
	bne.s   .not_last_level
	bset.b  #6, (RAM_play_flags).w ; Set "last level" flag
.not_last_level:

	; Store level data location in a0
	move.w  (a0), d0
	lea     DATA_levels, a0
	adda.w  d0, a0

	; Set number of characters at bus rear door
	move.b  (RAM_level_num).w, d0
	subi.b  #2, d0
	bge.s   .bus_num_characters_not_negative
	moveq   #0, d0
.bus_num_characters_not_negative:
	btst.b  #6, (RAM_play_flags).w ; Check if it is the last level
	beq.s   .bus_num_characters_not_last_level
	move.b  #3, d0
.bus_num_characters_not_last_level:
	move.b  d0, (RAM_bus_num_characters).w

	move.b  #SEQ_INITIAL, (RAM_sequence_step).w

	move.b  2(a0), (RAM_level_sky_color).w
	move.b  3(a0), (RAM_level_bgm).w
	move.b  4(a0), (RAM_level_goal_scene).w

	; Read number of level columns
	move.w  (a0), d0

	; Calculate total level width in pixels (that is, multiply the number of
	; level columns by 24) and store the result in d0
	move.w  d0, d1
	add.w   d0, d0
	add.w   d1, d0
	add.w   d0, d0
	add.w   d0, d0
	add.w   d0, d0

	; Store level width in pixels in RAM
	move.w  d0, (RAM_level_size_pixels).w

	; Position the first bus stop sign (absent if the level number is 1)
	clr.w   (RAM_bus_stop_sign1_x).w
	cmpi.b  #1, (RAM_level_num).w
	ble.s   .first_sign_absent
	move.w  #176, (RAM_bus_stop_sign1_x).w
.first_sign_absent:

	; Position the second bus stop signs
	move.w  d0, (RAM_bus_stop_sign2_x).w
	subi.w  #40, (RAM_bus_stop_sign2_x).w

	; Find camera's maximum X position
	subi.w  #SCREEN_W, d0
	move.w  d0, (RAM_camera_xmax).w

	lea     5(a0), a1

	move.b  (a1)+, (RAM_num_coins).w
	move.b  (a1)+, (RAM_num_objs).w
	move.b  (a1)+, (RAM_num_overhead_signs).w
	move.b  (a1)+, (RAM_num_parked_vehicles).w
	move.b  (a1)+, (RAM_num_respawn_points).w
	move.b  (a1)+, (RAM_num_solids).w
	move.b  (a1)+, (RAM_num_triggers).w

	move.l  a0, d0
	addi.l  #12, d0
	move.l  d0, (RAM_ptr_level_columns).w

	; Copy level coins to RAM
	moveq   #0, d1
	move.w  (a0), d1 ; Number of level columns
	add.l   d1, d0
	movea.l d0, a1
	lea     (RAM_coins).w, a0
	moveq   #0, d7
	move.b  (RAM_num_coins).w, d7
	subq.w  #1, d7
.coins_copy_loop:
	move.l  (a1)+, (a0)+
	dbf     d7, .coins_copy_loop

	; Copy level objects to RAM
	moveq   #0, d1
	move.b  (RAM_num_coins).w, d1
	add.w   d1, d1 ; Four bytes per coin
	add.w   d1, d1
	add.l   d1, d0
	movea.l d0, a1
	lea     (RAM_objs).w, a0
	moveq   #0, d7
	move.b  (RAM_num_objs).w, d7
	subq.w  #1, d7
.objs_copy_loop:
	move.l  (a1)+, (a0)+
	move.l  (a1)+, (a0)+
	dbf     d7, .objs_copy_loop

	; Find location of overhead signs (after level objects)
	moveq   #0, d1
	move.b  (RAM_num_objs).w, d1
	add.w   d1, d1 ; Eight bytes per object
	add.w   d1, d1
	add.w   d1, d1
	add.l   d1, d0
	move.l  d0, (RAM_ptr_overhead_signs).w

	; Find location of parked vehicles (after overhead signs)
	moveq   #0, d1
	move.b  (RAM_num_overhead_signs).w, d1
	add.w   d1, d1 ; Four bytes per sign
	add.w   d1, d1
	add.l   d1, d0
	move.l  d0, (RAM_ptr_parked_vehicles).w

	; Find location of passageways (after parked vehicles)
	moveq   #0, d1
	move.b  (RAM_num_parked_vehicles).w, d1
	add.w   d1, d1 ; Four bytes per vehicle
	add.w   d1, d1
	add.l   d1, d0
	move.l  d0, (RAM_ptr_passageways).w

	; Find location of respawn points (after passageways)
	addi.w  #(4*4), d0 ; Four fixed passageway entries with four bytes each
	move.l  d0, (RAM_ptr_respawn_points).w

	; Find location of level solids (after respawn points)
	moveq   #0, d1
	move.b  (RAM_num_respawn_points).w, d1
	add.w   d1, d1 ; Four bytes per respawn point
	add.w   d1, d1
	add.l   d1, d0
	move.l  d0, (RAM_ptr_level_solids).w

	; Find location of triggers (after level solids)
	moveq   #0, d1
	move.b  (RAM_num_solids).w, d1
	move.w  d1, d2 ; Ten bytes per solid
	add.w   d1, d1
	add.w   d1, d1
	add.w   d1, d1
	add.w   d2, d2
	add.w   d2, d1
	add.w   d1, d0
	move.l  d0, (RAM_ptr_next_trigger).w

	; Add gushes
	move.l  DATA_gush_move_pattern_1, d0
	move.w  DATA_gush_move_pattern_1+6, d1
	lea     (RAM_objs).w, a0
	lea     (RAM_gushes).w, a1
	moveq   #0, d6 ; Use d6 for index of current object
	moveq   #0, d7
	move.b  (RAM_num_objs).w, d7
	subq.b  #1, d7
.gushes_add_loop:
	cmpi.w  #OBJ_GUSH, (a0)
	bne.s   .gushes_next_obj

	move.w  #232, (a1)+; TODO: GUSH_INITIAL_Y constant
	clr.w   (a1)+
	move.l  d0,   (a1)+
	move.w  d1, (a1)+

	clr.b   (a1)+ ; Use first pattern
	clr.b   (a1)+
	move.b  d6, (a1)+
	addq.w  #3, a1

	addi.b  #1, (RAM_num_gushes).w

.gushes_next_obj:
	addq.b  #1, d6
	addq.w  #8, a0
	dbf     d7, .gushes_add_loop

	; Add pushable crates
	lea     (RAM_objs).w, a0
	lea     (RAM_pushable_crates).w, a1
	lea     (RAM_pushable_crate_solids).w, a2
	moveq   #0, d6 ; Use d6 for index of current object
	moveq   #0, d7
	move.b  (RAM_num_objs).w, d7
	subq.b  #1, d7

.pushable_crates_add_loop:
	cmpi.w  #OBJ_PUSH_CRATE, (a0)
	beq.s   .is_pushable_crate
	cmpi.w  #OBJ_PUSH_CRATE_WITH_ARROW, (a0)
	beq.s   .is_pushable_crate
	bra.s   .pushable_crates_next_obj

.is_pushable_crate:
	move.w  2(a0), d0

	move.w  d0, (a1)+
	clr.w   (a1)+
	addi.w  #24, d0
	move.w  d0, (a1)+
	clr.b   (a1)+
	move.b  d6, (a1)+

	; Add pushable crate solid
	move.w  2(a0), d0
	move.w  d0, (a2)+
	addi.w  #24, d0
	move.w  d0, (a2)+
	move.w  #240, (a2)+
	move.w  #240+24, (a2)+
	move.w  #0, (a2)+

	; Determine if an arrow is shown with the crate
	cmpi.w  #OBJ_PUSH_CRATE_WITH_ARROW, (a0)
	bne.s   .pushable_crates_next_obj

	move.b  #1, -2(a1) ; Set "show arrow" flag

.pushable_crates_next_obj:
	addq.b  #1, d6
	lea     8(a0), a0
	dbf     d7, .pushable_crates_add_loop

	clr.b   (RAM_progress_checked).w
	move.b  #SCR_PLAY, (RAM_screen_type_next).w
	bset.b  #0, (RAM_force_full_redraw).w

	moveq   #0, d0
	move.b  (RAM_level_bgm).w, d0
	bsr     sound_play_bgm

	; Wipe in screen
	move.b  #WIPECMD_IN, (RAM_wipe_cmd).w

	rts

; ------------------------------------------------------------------------------

start_ending_sequence:
	bsr     play_clear

	move.b  #SCR_PLAY, (RAM_screen_type_next).w
	bset.b  #0, (RAM_force_full_redraw).w

	; Set flag indicating it is the ending sequence
	bset.b  #7, (RAM_play_flags).w

	move.w  #(480*8), (RAM_level_size_pixels).w
	move.b  #2, (RAM_level_sky_color).w
	move.b  #2, (RAM_level_bgm).w

	move.w  #((480*8)-SCREEN_W), (RAM_camera_xmax).w

	move.b  #SEQ_ENDING, (RAM_sequence_step).w
	clr.b   (RAM_sequence_delay).w

	; Wipe in screen
	move.b  #WIPECMD_IN, (RAM_wipe_cmd).w

	moveq   #0, d0
	move.b  (RAM_level_bgm).w, d0
	bra     sound_play_bgm

; ------------------------------------------------------------------------------

check_game_progress:
	tst.b   (RAM_progress_checked).w
	bne.s   .ret

	; Check "goal reached" flag
	btst.b  #3, (RAM_play_flags).w
	beq.s   .ret

	move.b  #1, (RAM_progress_checked).w

	tst.b   (RAM_progress_cheat).w
	bne.s   .ret

	; No progress advance if it is the last level of the highest difficulty
	cmpi.b  #2, (RAM_progress_difficulty).w
	blo.s   .not_last_level
	cmpi.b  #3, (RAM_progress_level).w
	blo.s   .not_last_level
	bra.s   .ret

.not_last_level:
	move.b  (RAM_progress_level).w, d0
	move.b  (RAM_progress_difficulty).w, d1
	move.b  (RAM_level_num).w, d2
	move.b  (RAM_difficulty).w, d3

	; No progress advance if the level being played does not correspond to
	; the progress
	cmp.b   d1, d3
	bne.s   .ret
	cmp.b   d0, d2
	bne.s   .ret

	; Next level
	addq.b  #1, d0

	; Check if the next difficulty has been unlocked
	cmpi.b  #5, d0
	bls.s   .no_difficulty_advance

	; Move to the first level of the next difficulty
	moveq   #1, d0
	addq.b  #1, d1

.no_difficulty_advance:
	move.b  d0, (RAM_progress_level).w
	move.b  d1, (RAM_progress_difficulty).w
	bra     sram_save

.ret:
	rts

; ------------------------------------------------------------------------------

joypad_update:
	; Store the previous state in d2
	move.w  (RAM_joystate_down).w, d2

	lea     $A10003, a0 ; Joypad data address
	moveq   #0, d0
	moveq   #0, d1

	z80_halt

	move.b  #$40, (a0)
	nop
	nop
	move.b  (a0), d0
	andi.b  #$3F, d0

	move.b  #0, (a0)
	nop
	nop
	move.b  (a0), d1
	andi.b  #$30, d1
	add.b   d1, d1
	add.b   d1, d1

	z80_resume

	or.b    d1, d0
	not.b   d0

	move.w  d0, (RAM_joystate_down).w

	; Store hit buttons
	not.w   d2
	and.w   d0, d2
	move.w  d2, (RAM_joystate_hit).w

	rts

; ------------------------------------------------------------------------------

sram_save:
	moveq   #0, d0
	move.b  (RAM_progress_level).w, d0
	moveq   #0, d1
	move.b  (RAM_progress_difficulty).w, d1

	; Combine difficulty and level into a single byte
	add.b   d1, d1
	add.b   d1, d1
	add.b   d1, d1
	add.b   d1, d1
	or.b    d1, d0

	; Save progress to SRAM
	move.b  #1, SRAM_LOCK
	move.b  d0, SRAM_START+$21
	move.b  d0, SRAM_START+$41
	move.b  d0, SRAM_START+$61
	move.b  #0, SRAM_LOCK

	rts

; ------------------------------------------------------------------------------

sram_load:
	move.b  #1, SRAM_LOCK
	move.b  SRAM_START+$21, d1
	move.b  SRAM_START+$41, d2
	move.b  SRAM_START+$61, d3
	move.b  #0, SRAM_LOCK

	cmp.b   d1, d2
	beq.s   .use_d1
	cmp.b   d2, d3
	beq.s   .use_d2
	bra.s   .no_data

.use_d1:
	move.b  d1, d0
	beq.s   .load

.use_d2:
	move.b  d2, d0

.load:
	move.b  d0, d1

	; Keep level number in d0
	andi.b  #7, d0

	; Keep difficulty in d1
	lsr.b   #4, d1

	; Check if the saved difficulty is valid
	cmpi.b  #2, d1
	bhi.s   .no_data

	; Keep maximum level number in d2
	moveq   #5, d2
	cmpi.b  #2, d1
	bne.s   .check_level_number
	moveq   #3, d2

.check_level_number:
	; Check if the saved level number is valid
	tst.b   d0
	beq.s   .no_data
	cmp.b   d2, d0
	bhi.s   .no_data

	; Load data
	move.b  d0, (RAM_progress_level).w
	move.b  d1, (RAM_progress_difficulty).w
	rts

.no_data:
	clr.b   (RAM_progress_difficulty).w
	move.b  #1, (RAM_progress_level).w
	rts

; ------------------------------------------------------------------------------

; Load the values that depend on the frame rate (60 or 50 Hz) into RAM:
; time delays, velocities, and accelerations
load_fps_values:
	lea     DATA_fps_values_ntsc, a0
	move.b  $A10001, d0
	btst.l  #6, d0
	beq.s   .not_pal
	lea     DATA_fps_values_pal, a0
.not_pal:

	lea     (RAM_fpsvals).w, a1
	move.w  #FPSVALS_SIZE-1, d7
.values_load_loop:
	move.b  (a0)+, (a1)+
	dbf     d7, .values_load_loop

	rts

