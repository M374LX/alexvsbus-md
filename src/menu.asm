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
; menu.asm
;
; Description:
; Implementation of the game's menus
;

; ------------------------------------------------------------------------------

menu_update:
	move.b  (RAM_menu_flags).w, (RAM_menu_flags_prev).w
	clr.b   (RAM_menu_action).w

	; Check if a level has been selected
	btst.b  #0, (RAM_menu_flags).w
	beq.s   .level_not_selected

	; If so, toggle the visibility of the menu item corresponding to the
	; selected level
	bchg.b  #1, (RAM_menu_flags).w
	rts

.level_not_selected:
	move.b  (RAM_menu_type).w, (RAM_menu_type_prev).w
	move.b  (RAM_menu_last_item).w, (RAM_menu_last_item_prev).w
	clr.b   (RAM_menu_action).w

	move.w  (RAM_joystate_hit).w, d7
	move.b  (RAM_menu_disabled_items).w, d2
	move.b  (RAM_menu_last_item).w, d1
	move.b  (RAM_menu_selected_item).w, d0
	move.b  d0, (RAM_menu_selected_item_prev).w

	; Check if D-pad down is pressed
	btst.l  #1, d7
	beq.s   .check_up

.select_next:
	; Select next menu item
	addq.b  #1, d0

	; If the last item was selected, move to the first one
	cmp.b   d1, d0
	ble.s   .not_last
	moveq   #0, d0
.not_last:

	; Skip disabled items
	btst.l  d0, d2
	bne.s   .select_next

.check_up:
	; Check if D-pad up is pressed
	btst.l  #0, d7
	beq.s   .selection_done

.select_previous:
	; Select previous menu item
	subq.b  #1, d0

	; If the first item was selected, move to the last one
	bge.s   .not_first
	move.b  d1, d0
.not_first:

	; Skip disabled items
	btst.l  d0, d2
	bne.s   .select_previous

.selection_done:
	move.b  d0, (RAM_menu_selected_item).w

	; Store selected item on menu stack
	moveq   #0, d1
	move.b  (RAM_menu_stack_size).w, d1
	subq.b  #1, d1
	lea     (RAM_menu_stack).w, a0
	adda.w  d1, a0
	move.b  d0, (a0)

	; Play a sound effect if the selected item changed
	cmp.b   (RAM_menu_selected_item_prev).w, d0
	beq.s   .no_selection_change
	move.w  #SFX_SELECT, d0
	bsr     sound_play_sfx
.no_selection_change:

	; Return to previous menu by pressing B
	btst.l  #4, d7
	bne     menu_close

	; Confirm selection by pressing Start/A/C
	andi.b  #$E0, d7
	bne.s   menu_confirm

	rts

; ------------------------------------------------------------------------------

menu_confirm:
	moveq   #0, d0
	move.b  (RAM_menu_type).w, d0
	add.w   d0, d0
	add.w   d0, d0
	add.w   d0, d0
	add.w   d0, d0
	add.w   d0, d0

	moveq   #0, d1
	move.b  (RAM_menu_selected_item).w, d1
	add.w   d1, d1
	add.w   d1, d1
	add.w   d1, d0

	jmp     .menu_items_jump_table(pc, d0.w)
.menu_items_jump_table:
	; Main
	bra.w   .main_item_play
	bra.w   .main_item_jukebox
	bra.w   .main_item_about
	bra.w   .ret
	bra.w   .ret
	bra.w   .ret
	bra.w   .ret
	bra.w   .ret

	; Pause
	bra.w   .pause_item_resume
	bra.w   .pause_item_restart
	bra.w   .pause_item_quit
	bra.w   .ret
	bra.w   .ret
	bra.w   .ret
	bra.w   .ret
	bra.w   .ret

	; Difficulty
	bra.w   .difficulty_item_normal
	bra.w   .difficulty_item_hard
	bra.w   .difficulty_item_super
	bra.w   menu_close
	bra.w   .ret
	bra.w   .ret
	bra.w   .ret
	bra.w   .ret

	; Level select (5 levels)
	bra.w   .level_item_1
	bra.w   .level_item_2
	bra.w   .level_item_3
	bra.w   .level_item_4
	bra.w   .level_item_5
	bra.w   menu_close
	bra.w   .ret
	bra.w   .ret

	; Level select (3 levels)
	bra.w   .level_item_1
	bra.w   .level_item_2
	bra.w   .level_item_3
	bra.w   menu_close
	bra.w   .ret
	bra.w   .ret
	bra.w   .ret
	bra.w   .ret

	; Jukebox
	bra.w   .jukebox_item_1
	bra.w   .jukebox_item_2
	bra.w   .jukebox_item_3
	bra.w   .jukebox_item_4
	bra.w   menu_close
	bra.w   .ret
	bra.w   .ret
	bra.w   .ret

	; Restart
	bra.w   .restart_item_restart
	bra.w   menu_close
	bra.w   .ret
	bra.w   .ret
	bra.w   .ret
	bra.w   .ret
	bra.w   .ret
	bra.w   .ret

	; Try again
	bra.w   .try_again_item_try_again
	bra.w   .try_again_item_quit
	bra.w   .ret
	bra.w   .ret
	bra.w   .ret
	bra.w   .ret
	bra.w   .ret
	bra.w   .ret

	; Quit
	bra.w   .quit_item_quit
	bra.w   menu_close
	bra.w   .ret
	bra.w   .ret
	bra.w   .ret
	bra.w   .ret
	bra.w   .ret
	bra.w   .ret

	; About
	bra.w   .about_item_credits
	bra.w   menu_close
	bra.w   .ret
	bra.w   .ret
	bra.w   .ret
	bra.w   .ret
	bra.w   .ret
	bra.w   .ret

	; Credits
	bra.w   menu_close
	bra.w   .ret
	bra.w   .ret
	bra.w   .ret
	bra.w   .ret
	bra.w   .ret
	bra.w   .ret
	bra.w   .ret

.ret:
	rts

.main_item_play:
	moveq   #MENU_DIFFICULTY, d0
	bra     menu_open

.main_item_jukebox:
	moveq   #MENU_JUKEBOX, d0
	bra     menu_open

.main_item_about:
	moveq   #MENU_ABOUT, d0
	bra     menu_open

.pause_item_resume:
	move.b  #MENUACT_RESUME, (RAM_menu_action).w
	rts

.pause_item_restart:
	moveq   #MENU_RESTART, d0
	bra     menu_open

.pause_item_quit:
	moveq   #MENU_QUIT, d0
	bra     menu_open

.difficulty_item_normal:
	clr.b   (RAM_difficulty).w ; DIFFICULTY_NORMAL = 0
	moveq   #MENU_LEVEL5, d0
	bra     menu_open

.difficulty_item_hard:
	move.b  #DIFFICULTY_HARD, (RAM_difficulty).w
	moveq   #MENU_LEVEL5, d0
	bra     menu_open

.difficulty_item_super:
	move.b  #DIFFICULTY_SUPER, (RAM_difficulty).w
	moveq   #MENU_LEVEL3, d0
	bra     menu_open

.level_item_1:
	move.b  #1, (RAM_level_num).w
	bra.s   .confirm_level_selection

.level_item_2:
	move.b  #2, (RAM_level_num).w
	bra.s   .confirm_level_selection

.level_item_3:
	move.b  #3, (RAM_level_num).w
	bra.s   .confirm_level_selection

.level_item_4:
	move.b  #4, (RAM_level_num).w
	bra.s   .confirm_level_selection

.level_item_5:
	move.b  #5, (RAM_level_num).w

.confirm_level_selection:
	bset.b  #0, (RAM_menu_flags).w ; Set "level selected" flag
	move.b  #MENUACT_PLAY, (RAM_menu_action).w
	rts

.jukebox_item_1:
	moveq   #0, d0
	bra.s   .jukebox_selected

.jukebox_item_2:
	moveq   #1, d0
	bra.s   .jukebox_selected

.jukebox_item_3:
	moveq   #2, d0
	bra.s   .jukebox_selected

.jukebox_item_4:
	moveq   #3, d0

.jukebox_selected:
	bsr     sound_play_bgm
	bra     handle_cheat

.restart_item_restart:
	move.b  #MENUACT_TRY_AGAIN, (RAM_menu_action).w
	rts

.try_again_item_try_again:
	move.b  #MENUACT_TRY_AGAIN, (RAM_menu_action).w
	rts

.try_again_item_quit:
	move.b  #MENUACT_TITLE, (RAM_menu_action).w
	rts

.quit_item_quit:
	move.b  #MENUACT_TITLE, (RAM_menu_action).w
	rts

.about_item_credits:
	moveq   #MENU_CREDITS, d0
	bra     menu_open

; ------------------------------------------------------------------------------

handle_cheat:
	; If the cheat code is already activated, skip
	tst.b   (RAM_progress_cheat).w
	bne.s   .ret

	moveq   #0, d0
	move.b  (RAM_progress_cheat_pos).w, d0
	lea     DATA_cheat_sequence, a0
	adda.w  d0, a0

	move.b  (RAM_menu_selected_item).w, d0

	; If the selected item is incorrect, reset the sequence
	cmp.b   (a0), d0
	bne.s   .reset_cheat

	; Otherwise, move to the next position in the sequence
	addq.b  #1, (RAM_progress_cheat_pos).w
	addq.w  #1, a0

	; If the sequence is not over yet, skip
	tst.b   (a0)
	bge.s   .ret

	; Activate the cheat code
	move.b  #1, (RAM_progress_cheat).w

	; Play the coin sound effect
	move.w  #SFX_COIN, d0
	bra     sound_play_sfx

.reset_cheat:
	clr.b   (RAM_progress_cheat_pos).w
	
.ret:
	rts

; ------------------------------------------------------------------------------

determine_disabled_items:
	clr.b   (RAM_menu_disabled_items).w

	; No items are disabled if the progress cheat code is activated
	tst.b   (RAM_progress_cheat).w
	bne.s   .ret

	move.b  (RAM_menu_type).w, d0
	cmpi.b  #MENU_DIFFICULTY, d0
	beq.s   .difficulty
	cmpi.b  #MENU_LEVEL5, d0
	beq.s   .level
	cmpi.b  #MENU_LEVEL3, d0
	beq.s   .level
	rts

.difficulty:
	move.b  #6, (RAM_menu_disabled_items).w

	moveq   #0, d0
	move.b  (RAM_progress_difficulty).w, d1
	bra.s   .loop

.level:
	; All items are unlocked if the selected difficulty does not correspond
	; to the progress
	move.b  (RAM_progress_difficulty).w, d0
	cmp.b   (RAM_difficulty).w, d0
	bne.s   .ret

	move.b  #$1E, (RAM_menu_disabled_items).w

	; Ensure the last item (return) is always enabled
	moveq   #0, d0
	move.b  (RAM_menu_last_item).w, d0
	bclr.b  d0, (RAM_menu_disabled_items).w

	moveq   #0, d0
	move.b  (RAM_progress_level).w, d1
	subq.b  #1, d1

.loop:
	cmp.b   d1, d0
	bhi.s   .ret

	bclr.b  d0, (RAM_menu_disabled_items).w
	addq.b  #1, d0
	bra.s   .loop

.ret:
	rts

; ------------------------------------------------------------------------------

; Input:
; d0 = menu type
menu_open:
	move.b  d0, (RAM_menu_type).w
	clr.b   (RAM_menu_flags).w

	; Determine the index of the last item of the menu (the number of items
	; minus one)
	add.w   d0, d0
	add.w   d0, d0
	lea     DATA_menu_items, a0
	move.w  (a0, d0.w), d0
	move.b  d0, (RAM_menu_last_item).w

	; Add the just opened menu to the stack
	moveq   #0, d0
	move.b  (RAM_menu_stack_size).w, d0
	lea     (RAM_menu_stack).w, a0
	adda.w  d0, a0
	move.b  (RAM_menu_type).w, (a0)
	addq.b  #2, (RAM_menu_stack_size).w

	clr.b   (RAM_menu_selected_item).w
	clr.b   (RAM_menu_selected_item_prev).w

	bsr     determine_disabled_items

	; Handle the specifics of some menu types
	move.b  (RAM_menu_type).w, d0
	cmpi.b  #MENU_JUKEBOX, d0
	beq.s   .jukebox
	cmpi.b  #MENU_DIFFICULTY, d0
	beq.s   .default_highest
	cmpi.b  #MENU_LEVEL5, d0
	beq.s   .default_highest
	cmpi.b  #MENU_LEVEL3, d0
	beq.s   .default_highest
	rts

.jukebox:
	clr.b   (RAM_progress_cheat_pos).w
	bra     sound_stop

.default_highest:
	move.b  (RAM_menu_last_item).w, d0

.find_highest:
	; Select the last unlocked difficulty or level by default
	subq.b  #1, d0
	btst.b  d0, (RAM_menu_disabled_items).w
	bne.s   .find_highest

	move.b  d0, (RAM_menu_selected_item).w
	rts

; ------------------------------------------------------------------------------

menu_close:
	; If there is only one menu in the stack, skip
	cmpi.b  #2, (RAM_menu_stack_size).w
	bls.s   .ret

	cmpi.b  #MENU_JUKEBOX, (RAM_menu_type).w
	bne.s   .not_jukebox

	; Play title BGM
	moveq   #3, d0
	bsr     sound_play_bgm
.not_jukebox:

	subq.b  #2, (RAM_menu_stack_size).w
	moveq   #0, d0
	move.b  (RAM_menu_stack_size).w, d0
	subq.b  #2, d0
	lea     (RAM_menu_stack).w, a0
	adda.w  d0, a0

	move.b  (a0)+, d0
	move.b  d0, (RAM_menu_type).w
	move.b  (a0), (RAM_menu_selected_item).w
	move.b  (a0), (RAM_menu_selected_item_prev).w

	; Determine the index of the last item of the menu (the number of items
	; minus one)
	add.w   d0, d0
	add.w   d0, d0
	lea     DATA_menu_items, a0
	move.w  (a0, d0.w), d0
	move.b  d0, (RAM_menu_last_item).w

	bra     determine_disabled_items

.ret:
	rts

; ------------------------------------------------------------------------------

menu_close_all:
	clr.b   (RAM_menu_stack_size).w
	rts

