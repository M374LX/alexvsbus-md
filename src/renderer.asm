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
; renderer.asm
;
; Description:
; Rendering of graphics
;

; ------------------------------------------------------------------------------

renderer_init:
	; Load charset
	lea     VDP_DATA, a0
	lea     DATA_charset, a1
	move.w  #((DATA_charset_end-DATA_charset)/4)-1, d7 ; Tileset size
	move.l  #($40000000)|(($0020<<5)<<16), 4(a0)
.charset_load_loop:
	move.l  (a1)+, (a0)
	dbf     d7, .charset_load_loop

	addq.w  #4, a0       ; Point a0 to VDP control port
	move.w  #$8014, (a0) ; Enable HBL interrupt
	move.w  #$8124, (a0) ; Disable display and enable VBL interrupt
	move.w  #$8A07, (a0) ; Set HBL interrupt rate

	rts

; ------------------------------------------------------------------------------

renderer_draw:
	; Clear sprite buffer
	move.b  #78, (RAM_sprite_buffer_free_slots).w
	clr.w   (RAM_sprite_buffer_next_offs).w
	clr.l   (RAM_sprite_buffer).w
	clr.l   (RAM_sprite_buffer+4).w

	; Check if the screen type changed
	move.b  (RAM_screen_type_next).w, d0
	beq.s   .no_screen_change
	cmp.b   (RAM_screen_type).w, d0
	beq.s   .no_screen_change
	bra.s   handle_screen_change
.no_screen_change:

	cmpi.b  #SCR_PLAY, (RAM_screen_type).w
	beq.s   .scr_play
	cmpi.b  #SCR_MENU, (RAM_screen_type).w
	beq.s   .scr_menu

	bsr     wait_vblank
	bra.s   .scr_done
.scr_play:
	bsr     scr_draw_play
	bra.s   .scr_done
.scr_menu:
	bsr     scr_draw_menu
.scr_done:

	bsr     flush_sprites
	bra     renderer_handle_wipe

; ------------------------------------------------------------------------------

handle_screen_change:
	; Necessary to avoid graphical glitches
	bsr     wait_vblank

	; Disable display
	move.w  #$8124, VDP_CTRL

	; Hide window
	move.w  #$9200, VDP_CTRL

	bsr     clear_planes

	moveq   #0, d0
	move.b  (RAM_screen_type_next).w, d0
	move.b  d0, (RAM_screen_type).w
	clr.b   (RAM_screen_type_next).w

	add.w   d0, d0
	add.w   d0, d0
	jmp     .scr_jump_table(pc, d0.w)
.scr_jump_table:
	bra.w   .ret                ; SCR_NONE
	bra.w   scr_init_menu       ; SCR_MENU
	bra.w   scr_init_finalscore ; SCR_FINALSCORE
	bra.w   scr_init_play       ; SCR_PLAY

.ret:
	rts

; ------------------------------------------------------------------------------

flush_sprites:
	lea     VDP_DATA, a0

	; Set link field for each sprite
	moveq   #78, d7
	sub.b   (RAM_sprite_buffer_free_slots).w, d7
	subq.w  #2, d7
	blt.s   .skip_sprite_link_loop

	lea     (RAM_sprite_buffer+3).w, a1 ; Point to link field
	moveq   #1, d0
.sprite_link_loop:
	move.b  d0, (a1)
	lea     8(a1), a1
	addq.b  #1, d0
	dbf     d7, .sprite_link_loop
.skip_sprite_link_loop:

	moveq   #78, d7
	sub.b   (RAM_sprite_buffer_free_slots).w, d7
	bne.s   .table_not_empty

	; Sprite table location: $AC00
	move.l  #$6C000002, 4(a0)

	; Clear first sprite if the table is empty (to prevent a residual sprite
	; from showing up)
	moveq   #0, d0
	move.l  d0, (a0)
	move.l  d0, (a0)

	rts

.table_not_empty:
	subq.w  #1, d7
	lea     (RAM_sprite_buffer).w, a1

	; Sprite table location: $AC00
	move.l  #$6C000002, 4(a0)
.flush_sprites_loop:
	move.l  (a1)+, (a0)
	move.l  (a1)+, (a0)
	dbf     d7, .flush_sprites_loop

	rts

; ------------------------------------------------------------------------------

renderer_handle_wipe:
	tst.b   (RAM_wipe_delta).w
	beq.s   .do_wipe_cmd

	tst.b   (RAM_wipe_delay).w
	beq.s   .no_delay

	subq.b  #1, (RAM_wipe_delay).w
	bra.s   .do_wipe_cmd

.no_delay:
	cmpi.b  #(SCREEN_H/(8*2)), (RAM_wipe_value).w
	bhi.s   .do_wipe_cmd

	; Start wipe delay
	move.b  #1, (RAM_wipe_delay).w

	; Update wipe value
	move.b  (RAM_wipe_delta).w, d0
	add.b   d0, (RAM_wipe_value).w

	; Prevent wipe value from going negative
	tst.b   (RAM_wipe_value).w
	bge.s   .do_wipe_cmd
	clr.b   (RAM_wipe_value).w

.do_wipe_cmd:
	move.b  (RAM_wipe_cmd).w, d0
	beq.s   .wipe_cmd_done
	subq.b  #1, d0
	beq.s   .wipe_cmd_in    ; WIPECMD_IN
	subq.b  #1, d0
	beq.s   .wipe_cmd_out   ; WIPECMD_OUT
	subq.b  #1, d0
	beq.s   .wipe_cmd_clear ; WIPECMD_CLEAR

.wipe_cmd_in:
	move.b  #(SCREEN_H/(8*2)), (RAM_wipe_value).w
	move.b  #-1, (RAM_wipe_delta).w
	move.b  #1, (RAM_wipe_delay).w
	bra.s   .wipe_cmd_done

.wipe_cmd_out:
	clr.b   (RAM_wipe_value).w
	move.b  #1, (RAM_wipe_delta).w
	move.b  #1, (RAM_wipe_delay).w
	bra.s   .wipe_cmd_done

.wipe_cmd_clear:
	clr.b   (RAM_wipe_value).w
	clr.b   (RAM_wipe_delta).w
	clr.b   (RAM_wipe_delay).w

.wipe_cmd_done:
	clr.b   (RAM_wipe_cmd).w

	tst.b   (RAM_wipe_value).w
	beq.s   .dont_enable_wipe
	st.b    (RAM_wipe_enabled).w
.dont_enable_wipe:

	; Handle initial screen blanking
	move.w  #$8164, d0 ; Enable display and VBlank
	tst.b   (RAM_wipe_value).w
	beq.s   .no_blanking
	bclr.l  #6, d0 ; Disable display
.no_blanking:
	move.w  d0, VDP_CTRL

	rts

; ------------------------------------------------------------------------------

; Clears VDP planes (A, B, and Window) and resets scroll offsets to zero
clear_planes:
	lea     VDP_DATA, a0
	moveq   #0, d0

	; Clear planes A and B
	move.l  #$40000003, 4(a0)
	move.w  #(64*64*2)-1, d7
.clear_loop:
	move.w  d0, (a0)
	dbf     d7, .clear_loop

	; Clear window
	move.l  #$70000002, 4(a0)
	move.w  #(64*2)-1, d7
.window_clear_loop:
	move.w  d0, (a0)
	dbf     d7, .window_clear_loop

	; Reset horizontal offsets
	move.l  #$68000002, 4(a0)
	move.w  d0, (a0)
	move.w  d0, (a0)

	; Reset vertical offsets
	move.l  #$40000010, 4(a0)
	move.w  d0, (a0)
	move.w  d0, (a0)

	rts

; ------------------------------------------------------------------------------

wait_vblank:
	move.l  (RAM_vtimer).w, d0
.wait:
	cmp.l   (RAM_vtimer).w, d0
	beq.s   .wait

	clr.b   (RAM_wipe_enabled).w

	rts

; ------------------------------------------------------------------------------

scr_init_menu:
	lea     VDP_DATA, a0

	; Load palettes
	lea     DATA_palettes_menu, a1
	move.w  #(96/4)-1, d7 ; Palette size
	move.l  #$C0000000, 4(a0)
.palette_load_loop:
	move.l  (a1)+, (a0)
	dbf     d7, .palette_load_loop

	; Load logo tileset
	lea     DATA_tileset_logo, a1
	move.w  #((DATA_tileset_logo_end-DATA_tileset_logo)/4)-1, d7 ; Tileset size
	move.l  #($40000000)|(($0080<<5)<<16), 4(a0)
.logo_tileset_load_loop:
	move.l  (a1)+, (a0)
	dbf     d7, .logo_tileset_load_loop

	; Draw logo
	lea     DATA_tilemap_logo, a1
	move.w  #$608C, d5 ; Upper half of VDP command to set VRAM write address
	move.w  #8-1, d7   ; Number of lines minus one
.logo_line_draw_loop:
	move.w  #28-1, d6  ; Number of rows minus one
	move.w  d5, 4(a0)
	move.w  #3, 4(a0)
.logo_column_draw_loop:
	move.w  (a1)+, (a0)
	dbf     d6, .logo_column_draw_loop

	; Next line of logo
	addi.w  #$80, d5
	dbf     d7, .logo_line_draw_loop

	bra     draw_menu

; ------------------------------------------------------------------------------

scr_draw_menu:
	bsr     wait_vblank

	; Point a0 to VDP data port
	lea     VDP_DATA, a0

	; Write to VSRAM
	move.l  #$40000010, 4(a0)

	; Flicker selected level menu item by scrolling plane A vertically
	moveq   #0, d0
	btst.b  #1, (RAM_menu_flags).w
	beq.s   .level_item_visible
	subq.b  #1, d0
.level_item_visible:
	move.w  d0, (a0)

	; Show or hide the logo by scrolling plane B vertically (it is visible
	; only on the main menu)
	moveq   #0, d0
	tst.b   (RAM_menu_type).w
	beq.s   .logo_visible
	subq.b  #1, d0
.logo_visible:
	move.w  d0, (a0)

	; If a level has been just selected, redraw the entire menu
	btst.b  #0, (RAM_menu_flags).w
	beq.s   .no_selected_level
	btst.b  #0, (RAM_menu_flags_prev).w
	beq.s   draw_new_menu
.no_selected_level:

	; If the menu type has changed, redraw the entire menu
	move.b  (RAM_menu_type).w, d0
	cmp.b   (RAM_menu_type_prev).w, d0
	bne.s   draw_new_menu

	; If only the selected menu item has changed, redraw only the menu items
	move.b  (RAM_menu_selected_item).w, d0
	cmp.b   (RAM_menu_selected_item_prev).w, d0
	bne     draw_menu_items
	rts

; ------------------------------------------------------------------------------

; Clears the previous menu and then draws the new one
draw_new_menu:
;-------------;
; Clear title ;
;-------------;

	move.l  #$41080003, 4(a0)
	moveq   #0, d0
	moveq   #32-1, d7
.title_clear_loop:
	move.w  d0, (a0)
	dbf     d7, .title_clear_loop

;------------;
; Clear text ;
;------------;

	; Find text for previous menu type
	moveq   #0, d0
	move.b  (RAM_menu_type_prev).w, d0
	add.w   d0, d0
	lea     DATA_menu_texts, a1
	adda.w  d0, a1
	move.w  (a1), d0

	; Skip if there is no text
	beq.s   .text_end

	lea     DATA_menu_texts, a1
	adda.w  d0, a1

	; Get screen position
	move.w  (a1)+, d2

.text_lines_loop:
	; Set VDP write address
	move.w  d2, d1
	add.w   #$4000, d1
	swap.w  d1
	move.w  #3, d1
	move.l  d1, 4(a0)

.text_chars_loop:
	moveq   #0, d1
	move.b  (a1)+, d1
	beq.s   .text_end
	cmpi.b  #$0A, d1 ; ASCII line feed
	beq.s   .text_next_line
	cmpi.b  #$1B, d1 ; ASCII escape (makes the text green)
	bne.s   .text_clear_char
	bra.s   .text_chars_loop

.text_clear_char:
	move.w  #0, (a0)
	bra.s   .text_chars_loop

.text_next_line:
	addi.w  #$0080, d2
	bra.s   .text_lines_loop

.text_end:

;-------------;
; Clear items ;
;-------------;

	moveq   #0, d6
	move.b  (RAM_menu_last_item_prev).w, d6

	moveq   #0, d0
	move.b  (RAM_menu_type_prev).w, d0
	add.w   d0, d0
	add.w   d0, d0
	lea     DATA_menu_items, a1
	adda.w  2(a1, d0.w), a1

	move.w  #' ', d1

.items_loop:
	; Set VDP write address
	move.w  (a1), d0
	add.w   #$4000, d0
	swap.w  d0
	move.w  #3, d0
	move.l  d0, 4(a0)

	moveq   #14-1, d7 ; Characters per item
.item_chars_loop:
	move.w  d1, (a0)
	dbf     d7, .item_chars_loop

	; Next item
	lea     16(a1), a1
	dbf     d6, .items_loop

	; Fallthrough

; ------------------------------------------------------------------------------

draw_menu:
	; If a level has been selected, only the menu item corresponding to it
	; is drawn
	btst.b  #0, (RAM_menu_flags).w
	bne     draw_menu_selected_item

;------------;
; Draw title ;
;------------;

	move.l  #$41080003, 4(a0)

	moveq   #0, d0
	move.b  (RAM_menu_type).w, d0
	add.w   d0, d0
	add.w   d0, d0
	add.w   d0, d0
	add.w   d0, d0
	add.w   d0, d0
	lea     DATA_menu_titles, a1
	adda.w  d0, a1

	; Skip if there is no title
	cmpi.b  #'-', (a1)
	beq.s   .skip_title

	moveq   #0, d0
	moveq   #32-1, d7
.title_loop:
	move.b  (a1)+, d0
	move.w  d0, (a0)

	dbf     d7, .title_loop
.skip_title:

;-----------;
; Draw text ;
;-----------;

	; Find text for menu type
	moveq   #0, d0
	move.b  (RAM_menu_type).w, d0
	add.w   d0, d0
	lea     DATA_menu_texts, a1
	adda.w  d0, a1
	move.w  (a1), d0

	; Skip if there is no text
	beq.s   .text_end

	lea     DATA_menu_texts, a1
	adda.w  d0, a1

	; Get screen position
	move.w  (a1)+, d2

.text_lines_loop:
	moveq   #0, d3

	; Set VDP write address
	move.w  d2, d1
	add.w   #$4000, d1
	swap.w  d1
	move.w  #3, d1
	move.l  d1, 4(a0)

.text_chars_loop:
	moveq   #0, d1
	move.b  (a1)+, d1
	beq.s   .text_end
	cmpi.b  #$0A, d1 ; ASCII line feed
	beq.s   .text_next_line
	cmpi.b  #$1B, d1 ; ASCII escape (makes the text green)
	bne.s   .text_draw_char

	move.w  #$2000, d3
	bra.s   .text_chars_loop

.text_draw_char:
	or.w    d3, d1
	move.w  d1, (a0)
	bra.s   .text_chars_loop

.text_next_line:
	addi.w  #$0080, d2
	bra.s   .text_lines_loop

.text_end:

	; Fallthrough

; ------------------------------------------------------------------------------

draw_menu_items:
	moveq   #0, d0
	move.b  (RAM_menu_type).w, d0
	add.w   d0, d0
	add.w   d0, d0
	lea     DATA_menu_items, a1
	adda.w  2(a1, d0.w), a1

	moveq   #0, d5
	moveq   #0, d6
	move.b  (RAM_menu_last_item).w, d6
.items_loop:
	moveq   #0, d0
	btst.b  d5, (RAM_menu_disabled_items).w
	beq.s   .item_not_disabled
	move.w  #$4000, d0
.item_not_disabled:
	bsr     draw_menu_item

	; Next item
	addq.b  #1, d5
	dbf     d6, .items_loop

	; Fallthrough

; ------------------------------------------------------------------------------

draw_menu_selected_item:
	moveq   #0, d0
	move.b  (RAM_menu_type).w, d0
	add.w   d0, d0
	add.w   d0, d0
	lea     DATA_menu_items, a1
	adda.w  2(a1, d0.w), a1

	; Mark selected item
	moveq   #0, d0
	move.b  (RAM_menu_selected_item).w, d0
	add.w   d0, d0
	add.w   d0, d0
	add.w   d0, d0
	add.w   d0, d0
	add.w   d0, a1

	; Set palette
	move.w  #$2000, d0

	; Fallthrough

; ------------------------------------------------------------------------------

; Input:
; d0 = palette
; a0 = VDP_DATA
; a1 = item location
draw_menu_item:
	; Set VDP write address
	move.w  (a1)+, d1
	add.w   #$4000, d1
	swap.w  d1
	move.w  #3, d1
	move.l  d1, 4(a0)

	moveq   #14-1, d7 ; Characters per item
.chars_loop:
	moveq   #0, d1
	move.b  (a1)+, d1
	or.w    d0, d1
	move.w  d1, (a0)
	dbf     d7, .chars_loop

	rts

; ------------------------------------------------------------------------------

scr_init_finalscore:
	lea     VDP_DATA, a0

	move.l  #$669A0003, 4(a0)
	move.w  #'S', (a0)
	move.w  #'C', (a0)
	move.w  #'O', (a0)
	move.w  #'R', (a0)
	move.w  #'E', (a0)
	move.w  #':', (a0)
	move.w  #' ', (a0)
	move.w  #' ', (a0)

	; Convert score to string
	lea     (RAM_num_str_buffer+6).w, a1
	moveq   #$0F, d2
	moveq   #'0', d3
	move.l  (RAM_score).w, d1
	move.b  d1, d0
	and.b   d2, d0
	add.b   d3, d0
	move.b  d0, -(a1)
	lsr.l   #4, d1
	move.b  d1, d0
	and.b   d2, d0
	add.b   d3, d0
	move.b  d0, -(a1)
	lsr.l   #4, d1
	move.b  d1, d0
	and.b   d2, d0
	add.b   d3, d0
	move.b  d0, -(a1)
	lsr.l   #4, d1
	move.b  d1, d0
	and.b   d2, d0
	add.b   d3, d0
	move.b  d0, -(a1)
	lsr.l   #4, d1
	move.b  d1, d0
	and.b   d2, d0
	add.b   d3, d0
	move.b  d0, -(a1)
	lsr.l   #4, d1
	move.b  d1, d0
	and.b   d2, d0
	add.b   d3, d0
	move.b  d0, -(a1)

	; Display score
	move.w  #$8000, d0
	move.b  (a1)+, d0
	move.w  d0, (a0)
	move.b  (a1)+, d0
	move.w  d0, (a0)
	move.b  (a1)+, d0
	move.w  d0, (a0)
	move.b  (a1)+, d0
	move.w  d0, (a0)
	move.b  (a1)+, d0
	move.w  d0, (a0)
	move.b  (a1)+, d0
	move.w  d0, (a0)

	; Find message corresponding to the difficulty
	moveq   #0, d0
	move.b  RAM_difficulty, d0
	add.w   d0, d0
	add.w   d0, d0
	add.w   d0, d0
	add.w   d0, d0
	add.w   d0, d0
	lea     .msg, a1
	adda.w  d0, a1

	move.l  #$67900003, 4(a0)
	moveq   #0, d0
	moveq   #32-1, d7
.msg_loop:
	move.b  (a1)+, d0
	move.w  d0, (a0)
	dbf     d7, .msg_loop

	rts

.msg:
	dc.b    "GET READY FOR HARD MODE!        "
	dc.b    "GET READY FOR SUPER MODE!       "
	dc.b    "        THE  END                "
	even

; ------------------------------------------------------------------------------

scr_init_play:
	lea     VDP_DATA, a0

	; Show window
	move.w  #$9202, 4(a0)

	; Load palettes
	lea     DATA_palettes_play, a1
	move.w  #(128/4)-1, d7 ; Palette size
	move.l  #$C0000000, 4(a0)
.palette_load_loop:
	move.l  (a1)+, (a0)
	dbf     d7, .palette_load_loop

	; Load background tileset
	lea     DATA_tileset_background, a1
	move.w  #((DATA_tileset_background_end-DATA_tileset_background)/4)-1, d7 ; Tileset size
	move.l  #($40000000)|(($0080<<5)<<16), 4(a0)
.background_tileset_load_loop:
	move.l  (a1)+, (a0)
	dbf     d7, .background_tileset_load_loop

	; Load bus tileset
	lea     DATA_tileset_bus, a1
	move.w  #((DATA_tileset_bus_end-DATA_tileset_bus)/4)-1, d7 ; Tileset size
	move.l  #($40000000)|(($00D0<<5)<<16), 4(a0)
.bus_tileset_load_loop:
	move.l  (a1)+, (a0)
	dbf     d7, .bus_tileset_load_loop

	; Load truck tileset
	lea     DATA_tileset_truck, a1
	move.w  #((DATA_tileset_truck_end-DATA_tileset_truck)/4)-1, d7 ; Tileset size
	move.l  #($40000000)|(($0150<<5)<<16), 4(a0)
.truck_tileset_load_loop:
	move.l  (a1)+, (a0)
	dbf     d7, .truck_tileset_load_loop

	; Load car tileset
	lea     DATA_tileset_car, a1
	move.w  #((DATA_tileset_car_end-DATA_tileset_car)/4)-1, d7 ; Tileset size
	move.l  #($40000000)|(($01B0<<5)<<16), 4(a0)
.car_tileset_load_loop:
	move.l  (a1)+, (a0)
	dbf     d7, .car_tileset_load_loop

	; Load tileset for sprites
	lea     DATA_sprites, a1
	move.w  #((DATA_sprites_end-DATA_sprites)/4)-1, d7 ; Tileset size
	move.l  #($40000000)|(($01F0<<5)<<16), 4(a0)
.sprites_load_loop:
	move.l  (a1)+, (a0)
	dbf     d7, .sprites_load_loop

	; Fill sky
	move.w  #(64*18)-1, d7
	move.w  #$81, d0
	move.l  #$61000003, 4(a0)
.fill_sky_loop:
	move.w  d0, (a0)
	dbf     d7, .fill_sky_loop

	; Fill first window row with spaces
	move.w  #' '|$8000, d0
	move.l  #$70000002, 4(a0)
	moveq   #40-1, d7
.fill_spaces_loop1:
	move.w  d0, (a0)
	dbf     d7, .fill_spaces_loop1

	; Fill second window row with spaces
	move.l  #$70800002, 4(a0)
	moveq   #40-1, d7
.fill_spaces_loop2:
	move.w  d0, (a0)
	dbf     d7, .fill_spaces_loop2

	; Display "SCORE" on window
	move.l  #$70000002, 4(a0)
	move.w  #$8000|'S', (a0)
	move.w  #$8000|'C', (a0)
	move.w  #$8000|'O', (a0)
	move.w  #$8000|'R', (a0)
	move.w  #$8000|'E', (a0)

	; Display "TIME" on window
	move.l  #$70240002, 4(a0)
	move.w  #$8000|'T', (a0)
	move.w  #$8000|'I', (a0)
	move.w  #$8000|'M', (a0)
	move.w  #$8000|'E', (a0)

	clr.w   (RAM_col32).w
	clr.w   (RAM_col32_prev).w

	rts

; ------------------------------------------------------------------------------

scr_draw_play:
	move.w  (RAM_camera_x).w, (RAM_draw_offset_x).w
	move.w  (RAM_camera_y).w, d0
	addi.w  #46, d0
	move.w  d0, (RAM_draw_offset_y).w

	move.w  (RAM_draw_offset_x).w, d0
	lsr.w   #5, d0
	move.w  d0, (RAM_col32).w
	add.w   d0, d0
	add.w   d0, d0
	move.w  d0, (RAM_col32_tiles).w

	; 510 is the multiple of 3 that is closest to 512 but still lower
	move.w  #510, d3
	move.w  #(510/3), d4

	move.w  (RAM_draw_offset_x).w, d1
	lsr.w   #3, d1

	moveq   #0, d2

	; Prevent an overflow, as the LUT has only 512 entries
.col24_check_lut_overflow:
	cmp.w   d3, d1
	blt.s   .col24_no_overflow
	sub.w   d3, d1
	add.w   d4, d2
	bra.s   .col24_check_lut_overflow
.col24_no_overflow:

	; Determine the X position of the camera in 24-pixel columns and store
	; it in RAM_col24
	lea     DATA_lut_div3, a0
	adda.w  d1, a0
	moveq   #0, d0
	move.b  (a0), d0
	add.w   d2, d0
	move.w  d0, (RAM_col24).w

	; Determine redraw mode
	lea     (RAM_redraw_mode).w, a0
	clr.b   (a0)

	tst.b   (RAM_force_full_redraw).w
	bne.s   .redraw_mode_full

	move.w  (RAM_col32).w, d0
	sub.w   (RAM_col32_prev).w, d0

	cmpi.w  #4, d0
	bge.s   .redraw_mode_full
	tst.w   d0
	bne.s   .redraw_mode_vehicles_and_column

	tst.l   (RAM_bus_xvel).w
	bne.s   .redraw_mode_only_vehicles

	bra.s   .redraw_mode_done

.redraw_mode_full:
	addq.b  #1, (a0)
.redraw_mode_vehicles_and_column:
	addq.b  #1, (a0)
.redraw_mode_only_vehicles:
	addq.b  #1, (a0)

	tst.w   d0
	ble.s   .redraw_mode_done

	bset.b  #2, (a0) ; Moved to the right
.redraw_mode_done:

	move.w  (RAM_col32).w, (RAM_col32_prev).w
	clr.b   (RAM_force_full_redraw).w

	bsr     update_vehicle_buffer
	bsr     add_play_sprites

	bsr     wait_vblank

	bsr     update_scroll
	bsr     update_hud

	; Check what needs to be redrawn on background planes
	move.b  (RAM_redraw_mode).w, d0
	andi.w  #3, d0
	beq.s   .redraw_done
	subq.b  #1, d0
	beq.s   .redraw_only_vehicles
	subq.b  #1, d0
	beq.s   .redraw_column

.redraw_full:
	; Set sky color
	lea     DATA_sky_colors, a1
	moveq   #0, d0
	move.b  (RAM_level_sky_color).w, d0
	add.w   d0, d0
	adda.w  d0, a1
	move.l  #$C01E0000, 4(a0)
	move.w  (a1), (a0)

	bsr     draw_all_columns
	bsr     draw_vehicle_buffer_full

	bra.s   .redraw_done

.redraw_column:
	moveq   #0, d0

	btst.b  #2, (RAM_redraw_mode).w
	beq.s   .moved_left_1

	moveq   #15, d0
.moved_left_1:
	bsr     prepare_draw_column
	bsr     draw_column

	moveq   #0, d0

	btst.b  #2, (RAM_redraw_mode).w
	beq.s   .moved_left_2

.redraw_only_vehicles:
	moveq   #56, d0
.moved_left_2:

	tst.l   (RAM_bus_xvel).w
	beq.s   .bus_not_moving
	moveq   #60, d0
.bus_not_moving:

	moveq   #(4-1), d7
	bsr     draw_vehicle_buffer

.redraw_done:
	rts

; ------------------------------------------------------------------------------

update_hud:
	lea     VDP_DATA, a0

	; Convert score to string
	lea     (RAM_num_str_buffer+6).w, a1
	moveq   #$0F, d2
	moveq   #'0', d3
	move.l  (RAM_score).w, d1
	move.b  d1, d0
	and.b   d2, d0
	add.b   d3, d0
	move.b  d0, -(a1)
	lsr.l   #4, d1
	move.b  d1, d0
	and.b   d2, d0
	add.b   d3, d0
	move.b  d0, -(a1)
	lsr.l   #4, d1
	move.b  d1, d0
	and.b   d2, d0
	add.b   d3, d0
	move.b  d0, -(a1)
	lsr.l   #4, d1
	move.b  d1, d0
	and.b   d2, d0
	add.b   d3, d0
	move.b  d0, -(a1)
	lsr.l   #4, d1
	move.b  d1, d0
	and.b   d2, d0
	add.b   d3, d0
	move.b  d0, -(a1)
	lsr.l   #4, d1
	move.b  d1, d0
	and.b   d2, d0
	add.b   d3, d0
	move.b  d0, -(a1)

	; Display score
	move.l  #$70800002, 4(a0)
	move.w  #$8000, d0
	move.b  (a1)+, d0
	move.w  d0, (a0)
	move.b  (a1)+, d0
	move.w  d0, (a0)
	move.b  (a1)+, d0
	move.w  d0, (a0)
	move.b  (a1)+, d0
	move.w  d0, (a0)
	move.b  (a1)+, d0
	move.w  d0, (a0)
	move.b  (a1)+, d0
	move.w  d0, (a0)

	; Convert remaining time to string
	lea     (RAM_num_str_buffer+2).w, a1
	move.b  (RAM_time).w, d1
	move.b  d1, d0
	andi.b  #$0F, d0
	addi.b  #'0', d0
	move.b  d0, -(a1)
	lsr.b   #4, d1
	move.b  d1, d0
	andi.b  #$0F, d0
	addi.b  #'0', d0
	move.b  d0, -(a1)

	; Check if it is the ending sequence
	btst.b  #7, (RAM_play_flags).w
	beq.s   .not_ending

	; If it is the ending sequence, display "--"
	move.l  #$70A60002, 4(a0)
	move.w  #'-', (a0)
	move.w  #'-', (a0)

	rts

.not_ending:
	; Otherwise, display remaining time
	move.l  #$70A60002, 4(a0)
	move.w  #$8000, d0
	move.b  (a1)+, d0
	move.w  d0, (a0)
	move.b  (a1)+, d0
	move.w  d0, (a0)

	rts

; ------------------------------------------------------------------------------

prepare_draw_column:
	moveq   #0, d1
	moveq   #0, d2

	move.w  (RAM_col32).w, d0
	btst.b  #2, (RAM_redraw_mode).w
	beq.s   .left_column
	addi.w  #14, d0 ; Right column
.left_column:

	lea     DATA_lut_mod3, a0
	adda.w  d0, a0
	move.b  (a0), d1

	lea     DATA_lut_div3, a0
	adda.w  d0, a0

	move.b  (a0), d2
	add.w   d2, d2
	add.w   d2, d2
	add.w   d1, d2

	add.w   d0, d0
	add.w   d0, d0
	andi.w  #$3F, d0

	move.w  d0, (RAM_draw_col_plane).w
	move.w  d1, (RAM_draw_col_tiles).w

	move.w  d2, d0

	; Fallthrough

; ------------------------------------------------------------------------------

; Retrieves the blocks from two consecutive level columns
;
; Input:
; d0 - column number
get_column_blocks:
	lea     (RAM_level_block_buffer).w, a0

	btst.b  #7, (RAM_play_flags).w
	beq.s   .not_ending

	; If it is the ending sequence, the blocks are always
	; (0, 1, 2, 3, 4, 5)

	moveq   #16, d2

	; First column
	moveq   #0, d1
	move.w  d1, (a0)+
	add.w   d2, d1
	move.w  d1, (a0)+
	add.w   d2, d1
	move.w  d1, (a0)+
	add.w   d2, d1
	move.w  d1, (a0)+
	add.w   d2, d1
	move.w  d1, (a0)+
	add.w   d2, d1
	move.w  d1, (a0)+

	; Second column
	lea     20(a0), a0
	moveq   #0, d1
	move.w  d1, (a0)+
	add.w   d2, d1
	move.w  d1, (a0)+
	add.w   d2, d1
	move.w  d1, (a0)+
	add.w   d2, d1
	move.w  d1, (a0)+
	add.w   d2, d1
	move.w  d1, (a0)+
	add.w   d2, d1
	move.w  d1, (a0)+

	rts
.not_ending:

	lea     DATA_level_column_hole_blocks, a4
	movea.l (RAM_ptr_level_columns).w, a5

	; Bit 16 determines whether it is the first (0) or second (1) column
	; being processed; we clear it because we start with the first column
	bclr.l  #16, d0

	; In case of an overflow, use the first column
	cmpi.w  #480, d0
	blt.s   .next_column
	moveq   #0, d0

.next_column:
	movea.l a5, a1
	adda.w  d0, a1

	; Set the blocks of the first four rows to (0, 1, 2, 3)
	movea.l a0, a2
	moveq   #0, d1
	moveq   #16, d2
	move.w  d1, (a2)+
	add.w   d2, d1
	move.w  d1, (a2)+
	add.w   d2, d1
	move.w  d1, (a2)+
	add.w   d2, d1
	move.w  d1, (a2)

	; Set the blocks for the floor and below it according to the hole type
	adda.w  #(9-4+2)*2, a2
	move.w  #(6-1), d7
.floor_loop:
	moveq   #0, d1
	move.b  (a1), d1
	andi.w  #$38, d1
	add.w   d7, d1

	movea.l a4, a3
	adda.w  d1, a3
	adda.w  d1, a3
	move.w  (a3), -(a2)

	dbf     d7, .floor_loop

	; Check if there is a horizontal rope
	move.b  (a1), d1
	btst.l  #7, d1
	beq.s   .no_horizontal_rope
	move.w  #($16*16), (a0)
.no_horizontal_rope:

	; Determine number of crates in the column
	moveq   #0, d7
	move.b  (a1), d7
	andi.w  #7, d7

	; Skip if there are no crates
	beq.s   .no_crates

	; Point a2 to the lowest row that can contain a crate
	movea.l a0, a2
	adda.w  #(5*2), a2

	; $17 is the number of the level block with a crate
	move.w  #($17*16), d2

	; Add the corresponding number of crates
	subq.w  #1, d7
.crates_loop:
	move.w  d2, -(a2)
	dbf     d7, .crates_loop
.no_crates:

	; Finish if we have done the second column
	btst.l  #16, d0
	bne.s   .ret

	; Otherwise, move to the second column
	bset.l  #16, d0
	addq.w  #1, d0
	lea     32(a0), a0
	bra.s   .next_column

.ret:
	rts

; ------------------------------------------------------------------------------

draw_column:
	lea     VDP_DATA, a0
	lea     (RAM_level_block_buffer).w, a2
	lea     DATA_level_blocks, a4

	move.w  (RAM_draw_col_tiles).w, d1

	move.w  #(18*64), d2
	add.w   (RAM_draw_col_plane).w, d2
	add.w   d2, d2
	ori.w   #$6000, d2

	; Height of a level block in tiles (3) multiplied by 4
	moveq   #(3*4), d3

	; Set VDP autoincrement to (64*2)
	move.w  #$8F00|(64*2), 4(a0)

	moveq   #(4-1), d7
.row_loop:
	moveq   #0, d4
	moveq   #0, d5

	move.w  d2, 4(a0)
	move.w  #3, 4(a0)

	moveq   #(30-1), d6
.column_loop:
	movea.l a2, a1
	adda.w  d5, a1
	adda.w  d5, a1

	move.w  (a1), d0
	add.w   d4, d0
	add.w   d1, d0

	add.w   d0, d0
	movea.l a4, a3
	adda.w  d0, a3

	; Write tilemap entry
	move.w  (a3), (a0)

	addq.w  #4, d4
	cmp.w   d3, d4
	bne.s   .next_column

	addq.w  #1, d5
	moveq   #0, d4

.next_column:
	dbf     d6, .column_loop

	addq.w  #1, d1
	cmpi.w  #3, d1
	bne.s   .next_row

	moveq   #0, d1
	lea     32(a2), a2

.next_row:
	addq.w  #2, d2
	dbf     d7, .row_loop

	; Reset VDP autoincrement to 2
	move.w  #$8F02, 4(a0)

	rts

; ------------------------------------------------------------------------------

draw_all_columns:
	; Use a6 to keep track of the column to be drawn (because no data
	; registers are available)
	suba.l  a6, a6

.columns_loop:
	move.w  (RAM_col32).w, d0
	add.w   a6, d0

	lea     DATA_lut_mod3, a0
	adda.w  d0, a0
	moveq   #0, d2
	move.b  (a0), d2

	lea     DATA_lut_div3, a0
	adda.w  d0, a0

	moveq   #0, d1
	move.b  (a0), d1
	add.w   d1, d1
	add.w   d1, d1
	add.w   d2, d1

	add.w   d0, d0
	add.w   d0, d0
	andi.w  #$3F, d0

	move.w  d0, (RAM_draw_col_plane).w
	move.w  d2, (RAM_draw_col_tiles).w

	move.w  d1, d0
	bsr     get_column_blocks
	bsr     draw_column

	addq.w  #1, a6
	cmpa.w  #16, a6
	blo.s   .columns_loop

	rts

; ------------------------------------------------------------------------------

update_vehicle_buffer:
	; Clear the buffer
	moveq   #0, d0
	lea     (RAM_vehicle_buffer).w, a2
	move.w  #64-1, d7
.buffer_clear_loop:
	move.l  d0, (a2)+
	dbf     d7, .buffer_clear_loop

	lea     (RAM_vehicle_buffer).w, a2

	; No parked vehicles if it is the ending sequence
	btst.b  #7, (RAM_play_flags).w
	bne.s   .parked_vehicles_done

	; No parked vehicles appear if the bus is moving
	tst.l   (RAM_bus_xvel).w
	bne.s   .parked_vehicles_done

	; Add parked vehicles
	moveq   #0, d7
	move.b  (RAM_num_parked_vehicles).w, d7
	beq.s   .parked_vehicles_done

	movea.l (RAM_ptr_parked_vehicles).w, a1
	subq.b  #1, d7
.parked_vehicles_loop:
	move.w  (a1)+, d3 ; Vehicle type
	move.w  (a1)+, d4 ; Vehicle X position (in tiles)

	sub.w   (RAM_col32_tiles).w, d4

	; If the current vehicle is too far to the right, there are no more
	; vehicles to add to the buffer
	cmpi.w  #60, d4
	bge.s   .parked_vehicles_done

	; Determine vehicle width in tiles
	move.w  #16, d5
	cmpi.w  #VEH_PARKED_TRUCK, d3
	bne.s   .not_truck
	move.w  #35, d5
.not_truck:

	; If the current vehicle is too far to the left, move to the next one
	move.w  d4, d2
	add.w   d5, d4
	blt.s   .next_parked_vehicle
	sub.w   d5, d4

	bsr.s   add_vehicle_to_buffer

.next_parked_vehicle:
	dbf     d7, .parked_vehicles_loop
.parked_vehicles_done:

	move.w  (RAM_bus_init_x).w, d0
	lsr.w   #3, d0
	sub.w   (RAM_col32_tiles).w, d0
	move.w  (RAM_bus_x).w, d4
	sub.w   (RAM_bus_init_x).w, d4
	lsr.w   #3, d4
	add.w   d0, d4

	moveq   #VEH_BUS, d3
	moveq   #50, d5 ; Width of the bus in tiles

	; If the bus is too far to the right, skip
	cmpi.w  #60, d4
	bgt.s   .bus_done

	bsr.s   add_vehicle_to_buffer
.bus_done:

	; Add ending sequence cars
	btst.b  #7, (RAM_play_flags).w
	beq.s   .ending_cars_done

	moveq   #VEH_ENDING_CAR_BLUE, d3 ; Start with a blue car
	moveq   #16, d5 ; Width of a car in tiles

	addi.w  #(400/8), d4

	moveq   #6-1, d7 ; Number of cars minus one
.ending_cars_loop:
	; If the car is too far to the right, skip
	cmpi.w  #60, d4
	bgt.s   .ending_cars_done

	bsr.s   add_vehicle_to_buffer

	; Move to next car color
	addq.w  #1, d3
	cmpi.w  #VEH_ENDING_CAR_YELLOW, d3
	ble.s   .ending_car_not_yellow
	moveq   #VEH_ENDING_CAR_BLUE, d3
.ending_car_not_yellow:

	addi.w  #(136/8), d4
	dbf     d7, .ending_cars_loop
.ending_cars_done:

	rts

; ------------------------------------------------------------------------------

add_vehicle_to_buffer:
	moveq   #0, d6
.columns_loop:
	move.w  d4, d0
	add.w   d6, d0

	; Check if the current column is too far to the right
	cmpi.w  #60, d0
	bgt.s   .done

	; Check if the current column is too far to the left
	cmpi.w  #-4, d0
	blt.s   .next_column

	; If the current vehicle column is slightly to the left, wrap it to the
	; opposite side of the plane
	andi.w   #63, d0

	movea.l a2, a0
	adda.w  d0, a0
	adda.w  d0, a0

	move.b  d3, (a0)+
	move.b  d6, (a0)

.next_column:
	addq.w  #1, d6
	cmp.w   d5, d6
	blt.s   .columns_loop

.done:
	rts

; ------------------------------------------------------------------------------

draw_vehicle_buffer_full:
	moveq   #0, d0
	moveq   #(64-1), d7

	; Fallthrough

; ------------------------------------------------------------------------------

; Input
; d0 = column index
; d7 = number of columns minus one
draw_vehicle_buffer:
	lea     DATA_vehicle_types, a4
	lea     DATA_vehicle_tilemaps, a5

	lea     VDP_DATA, a0

	lea     (RAM_vehicle_buffer).w, a1
	adda.w  d0, a1
	adda.w  d0, a1

	move.w  (RAM_bus_x).w, d4
	sub.w   (RAM_bus_init_x).w, d4
	lsr.w   #3, d4
	neg.w   d4
	add.w   (RAM_col32_tiles).w, d4
	add.w   d0, d4

	; Set VDP autoincrement to (64*2)
	move.w  #$8F00|(64*2), 4(a0)

.column_loop:
	move.w  d4, d0
	addq.w  #1, d4

	tst.w   d0
	blt.s   .next_column

	; Set VRAM write address
	andi.w  #(64-1), d0
	addi.w  #(64*16), d0
	add.w   d0, d0
	ori.w   #$4000, d0
	move.w  d0, 4(a0)
	move.w  #3, 4(a0)

	; Read vehicle type
	moveq   #0, d0
	move.b  (a1)+, d0

	bne.s   .vehicle_present

	; If no vehicle is present, clear the column
	move.w  #(36-16-1), d6
.clear_loop:
	move.w  d0, (a0)
	dbf     d6, .clear_loop

	addq.w  #1, a1
	bra.s   .next_column

.vehicle_present:
	move.w  d0, d1

	; Point a2 to vehicle type data
	add.w   d0, d0
	add.w   d0, d0
	add.w   d0, d0
	movea.l    a4, a2
	adda.w  d0, a2

	move.w  d1, d0
	add.w   d0, d0
	add.w   d0, d0
	movea.l a5, a3
	adda.w  d0, a3
	movea.l (a3), a3

	; Get vehicle column from buffer
	moveq   #0, d0
	move.b  (a1)+, d0

	; Point a3 to the corresponding column within the tile map
	adda.w  d0, a3
	adda.w  d0, a3

	; Get vehicle initial screen line
	moveq   #0, d5
	move.b  2(a2), d5

	move.w  #(36-16-1), d6
.line_loop:
	moveq   #0, d0

	tst.b   d5
	blt.s   .empty_line
	cmp.b   3(a2), d5
	bge.s   .empty_line

	move.w  (a3), d0
	or.w    (a2), d0 ; Apply palette and priority

	moveq   #0, d1
	move.b  4(a2), d1
	add.w   d1, d1
	adda.w  d1, a3
.empty_line:

	move.w  d0, (a0)
	addq.b  #1, d5

	dbf     d6, .line_loop

.next_column:
	dbf     d7, .column_loop

	; Reset VDP autoincrement to 2
	move.w  #$8F02, 4(a0)

	rts

; ------------------------------------------------------------------------------

add_play_sprites:
;-----------------------------;
; Add sprites for coin sparks ;
;-----------------------------;

	moveq   #MAX_COIN_SPARKS-1, d7
	lea     (RAM_coin_sparks).w, a2
	lea     (RAM_anims+ANIM_COIN_SPARK_1).w, a3
.coin_sparks_loop:
	tst.b   (a3)
	beq     .next_coin_spark

	lea     DATA_spritemap_coin_spark_silver, a0
	btst.b  #7, 2(a2)
	beq     .not_gold
	lea     DATA_spritemap_coin_spark_gold, a0
.not_gold:

	; Find animation frame
	moveq   #0, d0
	move.b  (a3), d0
	add.w   d0, d0
	add.w   d0, d0
	add.w   d0, d0
	adda.w  d0, a0

	move.w  (a2), d0
	move.w  2(a2), d1
	bclr.l  #15, d1 ; Discard bit determining if it is silver or gold
	moveq   #0, d2
	bsr     add_spritemap

.next_coin_spark:
	addq.w  #4, a2
	addq.w  #ANIM_SIZE_BYTES, a3
	dbf     d7, .coin_sparks_loop

;---------------------------------;
; Add sprites for crack particles ;
;---------------------------------;

	moveq   #MAX_CRACK_PARTICLES-1, d7
	lea     RAM_crack_particles, a2

	; Determine spritemap for current animation frame
	lea     DATA_spritemap_crack_particles, a4
	moveq   #0, d0
	move.b  (RAM_anims+ANIM_CRACK_PARTICLES).w, d0
	beq.s   .crack_particles_not_frame_2
	addq.w  #8, a4
.crack_particles_not_frame_2:

.crack_particles_loop:
	move.w  (a2), d0
	move.w  4(a2), d1
	moveq   #0, d2
	movea.l a4, a0
	bsr     add_spritemap

	lea     16(a2), a2
	dbf     d7, .crack_particles_loop

;-----------------------------------;
; Add sprites for crate push arrows ;
;-----------------------------------;

	moveq   #MAX_PUSHABLE_CRATES-1, d7
	lea     (RAM_pushable_crates).w, a2

.push_arrow_crates_loop:
	; Check if the "show arrow" flag is set
	move.b  6(a2), d0
	btst.l  #0, d0
	beq.s   .push_arrow_next_crate

	; Draw arrow
	move.w  (a2), d0
	subi.w  #48, d0
	add.w   (RAM_push_arrow_xoffs).w, d0
	move.w  #FLOOR_Y-24, d1
	moveq   #1, d2
	lea     DATA_spritemap_push_arrow, a0
	bsr     add_spritemap

.push_arrow_next_crate:
	addq.w  #8, a2
	dbf     d7, .push_arrow_crates_loop

;-------------------------------------;
; Add sprites for moving banana peels ;
;-------------------------------------;

	lea     (RAM_moving_peels).w, a2

	; If the first peel is not moving, skip
	cmpi.b  #-1, 24(a2)
	beq.s   .moving_peels_second

	move.w  (a2), d0
	move.w  4(a2), d1
	moveq   #0, d2
	lea     DATA_spritemap_banana_peel, a0
	bsr     add_spritemap

.moving_peels_second:
	lea     32(a2), a2

	; If the second peel is not moving, skip
	cmpi.b  #-1, 24(a2)
	beq.s   .moving_peels_done

	move.w  (a2), d0
	move.w  4(a2), d1
	moveq   #0, d2
	lea     DATA_spritemap_banana_peel, a0
	bsr     add_spritemap
.moving_peels_done:

;-------------------------------------;
; Add sprites for overhead sign bases ;
;-------------------------------------;

	moveq   #0, d7
	move.b  (RAM_num_overhead_signs).w, d7
	beq.s   .overhead_sign_bases_done

	subq.w  #1, d7
	movea.l (RAM_ptr_overhead_signs).w, a2

	; Find location of next sprite within the buffer and store it in a0
	lea     (RAM_sprite_buffer).w, a0
	adda.w  (RAM_sprite_buffer_next_offs).w, a0

	; Maximum Y position of overhead sign base middle sprite, including the
	; (128, 128) offset used by the VDP
	move.w  #(248+128), d5
	sub.w   (RAM_draw_offset_y).w, d5

	; Height of the overhead sign base middle sprite
	move.w  #24, d6

.overhead_sign_bases_loop:
	move.w  (a2)+, d1 ; X
	move.w  (a2)+, d4 ; Y

	sub.w   (RAM_draw_offset_x).w, d1

	; Skip signs to the left of the visible area
	cmpi.w  #-32, d1
	ble.s  .overhead_sign_bases_next

	; If the sign is to the right of the visible area, then there are no
	; more visible signs, as the signs are always sorted by X position
	cmpi.w  #SCREEN_W, d1
	bge.s   .overhead_sign_bases_done

	sub.w   (RAM_draw_offset_y).w, d4

	addi.w  #(16+128), d1
	addi.w  #(8+128), d4

	; Add sign top right sprite
	move.w  #$2000|SPR_OVERHEAD_SIGN_TOP_RIGHT, d0
	move.w  d4, d2
	move.w  #$7, d3
	bsr     add_sprite_simple

	addq.w  #8, d1

	; Sprite size for base middle and bottom sprites
	moveq   #$2, d3

	; Draw base bottom sprite
	move.w  #$A000|SPR_OVERHEAD_SIGN_BOTTOM, d0
	move.w  d5, d2
	bsr     add_sprite_simple

	; Draw base middle sprites and ensure it is low priority if high enough
	; on the screen (so it does not appear over the HUD) and high priority
	; otherwise
	move.w  d4, d2
	move.w  #$2000|SPR_OVERHEAD_SIGN_MIDDLE, d0
.overhead_sign_bases_middle_next:
	add.w   d6, d2
	cmpi.w  #(32+128), d2
	blt.s   .overhead_sign_bases_middle_loprio
	bset.l  #$F, d0 ; High priority
.overhead_sign_bases_middle_loprio:
	cmp.w   d5, d2
	bge.s   .overhead_sign_bases_next
	bsr     add_sprite_simple
	bra.s   .overhead_sign_bases_middle_next

.overhead_sign_bases_next:
	dbf     d7, .overhead_sign_bases_loop
.overhead_sign_bases_done:

;----------------------------------------------------------;
; Add foreground sprites for holes (including passageways) ;
;----------------------------------------------------------;

	move.w  #16-1, d7 ; Number of level columns to check

	; Store initial column address in a5
	movea.l (RAM_ptr_level_columns).w, a5
	move.w  (RAM_col24).w, d0
	adda.w  d0, a5

	; Calculate X position of the first visible level column in pixels
	; (that is, multiply it by 24) and store the result in d0
	move.w  (RAM_col24).w, d0
	move.w  d0, d1
	add.w   d0, d0
	add.w   d1, d0
	add.w   d0, d0
	add.w   d0, d0
	add.w   d0, d0

	; Y position of the sprites
	move.w  #264, d1

.holes_fg_loop:
	; Extract hole type into d2
	move.b  (a5)+, d2
	andi.w  #$38, d2

	; Determine spritemap to draw
	cmpi.b  #(1*8), d2
	beq.s   .holes_fg_deep_left
	cmpi.b  #(4*8), d2
	beq.s   .holes_fg_passageway_left
	cmpi.b  #(6*8), d2
	beq.s   .holes_fg_passageway_right
	bra.s   .holes_fg_next_column

.holes_fg_deep_left:
	lea     DATA_spritemap_deep_hole_left_fg, a0
	bra.s   .holes_fg_add_sprite
.holes_fg_passageway_left:
	lea     DATA_spritemap_passageway_left_fg, a0
	bra.s   .holes_fg_add_sprite
.holes_fg_passageway_right:
	lea     DATA_spritemap_passageway_right_fg, a0

.holes_fg_add_sprite:
	moveq   #0, d2
	bsr     add_spritemap

.holes_fg_next_column:
	addi.w  #24, d0
	dbf     d7, .holes_fg_loop

;-----------------------;
; Add sprites for coins ;
;-----------------------;

	moveq   #0, d7
	move.b  (RAM_num_coins).w, d7
	beq.s   .coins_done

	lea     (RAM_coins).w, a2
	subq.w  #1, d7

	lea     (RAM_sprite_buffer).w, a0
	adda.w  (RAM_sprite_buffer_next_offs).w, a0

	move.w  #128, d4 ; (128, 128) offset used by the VDP
	moveq   #-8, d5
	move.w  #SCREEN_W, d6

	; Animation frames 1 and 3 are identical
	moveq   #0, d0
	move.b  (RAM_anims+ANIM_COINS).w, d0
	cmpi.b  #3, d0
	bne.s   .coin_anim_frame_not_3
	moveq   #1, d0
.coin_anim_frame_not_3:
	addi.w  #SPR_COIN_1, d0

.coins_loop:
	move.w  (a2), d1 ; X
	sub.w   (RAM_draw_offset_x).w, d1

	; Skip coins that are outside the screen (X axis)
	cmp.w   d5, d1
	ble.s   .coins_next
	cmp.w   d6, d1
	bge.s   .coins_done

	move.w  2(a2), d2 ; Y/gold
	bclr.l  #$F, d2   ; Clear gold bit
	sub.w   (RAM_draw_offset_y).w, d2

	; Skip coins that are outside the screen (Y axis)
	cmpi.w  #8, d2
	blt.s   .coins_next
	cmpi.w  #SCREEN_H, d2
	bge.s   .coins_next

	moveq   #0, d3    ; Sprite size

	bclr.l  #$D, d0   ; Palette 0
	btst.b  #7, 2(a2) ; Check if it is a gold coin
	beq.s   .coins_not_gold
	bset.l  #$D, d0   ; Palette 1
.coins_not_gold:

	; Add (128, 128) offset used by the VDP
	add.w   d4, d1
	add.w   d4, d2

	bsr     add_sprite_simple
.coins_next:
	addq.w  #4, a2
	dbf     d7, .coins_loop
.coins_done:

;--------------------------------------;
; Add sprites for the player character ;
;--------------------------------------;

	; Check if the player character is visible
	btst.b  #0, RAM_player_flags
	beq     .player_sprites_done

	; Determine spritemap for player character's current animation type
	moveq   #0, d0
	move.b  RAM_player_anim_type, d0
	add.w   d0, d0
	add.w   d0, d0
	add.w   d0, d0
	lea     DATA_player_anims, a2
	adda.w  d0, a2

	moveq   #0, d0
	move.b  5(a2), d0
	add.w   d0, d0
	add.w   d0, d0
	add.w   d0, d0
	add.w   d0, d0
	add.w   d0, d0
	lea     DATA_spritemap_player, a2
	adda.w  d0, a2

	; Determine spritemap offset for player character's current animation
	; frame
	moveq   #0, d0
	move.b  (RAM_anims).w, d0
	add.w   d0, d0
	add.w   d0, d0
	add.w   d0, d0
	add.w   d0, d0
	add.w   d0, d0
	adda.w  d0, a2

	; Determine base screen position (d5 = X; d6 = Y)
	move.w  (RAM_player_x).w, d5
	sub.w   (RAM_draw_offset_x).w, d5
	addi.w  #128, d5
	move.w  (RAM_player_y).w, d6
	sub.w   (RAM_draw_offset_y).w, d6
	addi.w  #128, d6

	; Find location of next sprite within the buffer and store it in a0
	lea     (RAM_sprite_buffer).w, a0
	adda.w  (RAM_sprite_buffer_next_offs).w, a0

	moveq   #4-1, d7
.player_sprites_loop:
	move.w  (a2)+, d1
	move.w  (a2)+, d2
	move.w  (a2)+, d3
	move.w  (a2)+, d0
	beq.s   .player_sprites_done

	add.w   d5, d1
	add.w   d6, d2

	; If the sprite is entirely offscreen, skip it
	cmpi.w  #(128-32), d1
	ble.s   .player_next_sprite
	cmpi.w  #(128+SCREEN_W), d1
	bge.s   .player_next_sprite
	cmpi.w  #(128-32), d2
	ble.s   .player_next_sprite
	cmpi.w  #(128+SCREEN_H), d2
	bge.s   .player_next_sprite

	; Adjust priority (so the sprite does not appear over the HUD)
	cmpi.w  #(128+16), d2
	bge.s   .player_high_priority
	bclr.l  #$F, d0 ; Clear priority bit
.player_high_priority:
	bsr     add_sprite_simple

.player_next_sprite:
	dbf     d7, .player_sprites_loop
.player_sprites_done:

;---------------------------------------------;
; Add sprites for ending sequence medal icons ;
;---------------------------------------------;

	btst.b  #3, (RAM_sequence_flags).w
	beq.s   .skip_medal_1

	lea     (RAM_cutscene_objs).w, a0
	move.w  2(a0), d0
	addq.w  #4, d0
	move.w  #160, d1
	moveq   #1, d2

	cmpi.b  #COBJ_PLAYER_RUN, (a0)
	bne.s   .medal_1_player_not_running

	addq.w  #8, d0
.medal_1_player_not_running:

	lea     DATA_spritemap_ending_medal_1, a0
	bsr     add_spritemap
.skip_medal_1:

	btst.b  #4, (RAM_sequence_flags).w
	beq.s   .skip_medal_2

	move.w  (RAM_hen_x).w, d0
	addq.w  #4, d0
	move.w  #184, d1
	moveq   #1, d2

	lea     DATA_spritemap_ending_medal_2, a0
	bsr     add_spritemap
.skip_medal_2:

	btst.b  #5, (RAM_sequence_flags).w
	beq.s   .skip_medal_3

	move.w  (RAM_bus_x).w, d0
	addi.w  #347, d0
	move.w  #120, d1
	moveq   #1, d2

	lea     DATA_spritemap_ending_medal_3, a0
	bsr     add_spritemap
.skip_medal_3:

;----------------------------------------------------------;
; Add sprites for cutscene objects that are not in the bus ;
;----------------------------------------------------------;

	lea    (RAM_cutscene_objs+32).w, a2
	lea    (RAM_anims+ANIM_CUTSCENE_OBJ_2).w, a3
	moveq  #(2-1), d7
.out_cutscene_objs_loop:
	tst.b  (a2)
	beq.s  .next_out_cutscene_obj
	tst.b  1(a2)
	bne.s  .next_out_cutscene_obj

	bsr     add_spritemap_cutscene_obj

.next_out_cutscene_obj:
	lea     -32(a2), a2
	subq.w  #8, a3
	dbf     d7, .out_cutscene_objs_loop

;--------------------------------;
; Add sprites for bus stop signs ;
;--------------------------------;

	move.w  (RAM_bus_stop_sign1_x).w, d0
	ble.s   .no_bus_stop_sign_1

	move.w  #BUS_STOP_SIGN_Y, d1
	moveq   #2, d2
	lea     DATA_spritemap_bus_stop_sign, a0
	bsr     add_spritemap
.no_bus_stop_sign_1:

	move.w  (RAM_bus_stop_sign2_x).w, d0
	ble.s   .no_bus_stop_sign_2

	move.w  #BUS_STOP_SIGN_Y, d1
	moveq   #2, d2
	lea     DATA_spritemap_bus_stop_sign, a0
	bsr     add_spritemap
.no_bus_stop_sign_2:

;----------------------------------------;
; Add sprites for objects using RAM_objs ;
;----------------------------------------;

	lea     (RAM_visible_gushes).w, a3
	clr.b   (RAM_num_visible_gushes).w

	moveq   #0, d7
	move.b  (RAM_num_objs).w, d7
	beq     .objs_done

	lea     (RAM_objs).w, a2
	subq.w  #1, d7

	moveq   #-32, d5
	move.w  #SCREEN_W, d6

.objs_loop:
	move.w  2(a2), d0 ; X
	sub.w   (RAM_draw_offset_x).w, d0

	; Skip objects that are outside the screen (X axis)
	cmp.w   d5, d0
	ble     .objs_next
	cmp.w   d6, d0
	bge     .objs_next

	move.w  4(a2), d1 ; Y
	sub.w   (RAM_draw_offset_y).w, d1

	; Skip objects that are outside the screen (Y axis)
	cmp.w   #SCREEN_H, d1
	bge     .objs_next

	add.w   (RAM_draw_offset_x).w, d0
	add.w   (RAM_draw_offset_y).w, d1

	moveq   #0, d2    ; Maximum number of map entries (minus one)

	; Jump to label corresponding to object type
	move.w  (a2), d3
	add.w   d3, d3
	jmp     .objs_jump_table(pc, d3.w)
.objs_jump_table:
	bra.s   .objs_next          ; OBJ_NULL
	bra.s   .objs_banana_peel   ; OBJ_BANANA_PEEL
	bra.s   .objs_gush          ; OBJ_GUSH
	bra.s   .objs_gush_crack    ; OBJ_GUSH_CRACK
	bra.s   .objs_push_crate    ; OBJ_PUSH_CRATE
	bra.s   .objs_push_crate    ; OBJ_PUSH_CRATE_WITH_ARROW
	bra.s   .objs_rope_vertical ; OBJ_ROPE
	bra.s   .objs_spring        ; OBJ_SPRING

.objs_banana_peel:
	lea     DATA_spritemap_banana_peel, a0
	bra.s   .objs_add_map

.objs_gush:
	; Add it to the list of visible gushes without drawing it for now
	move.w  2(a2), (a3)+ ; X
	move.w  4(a2), (a3)+ ; Y
	addq.b  #1, (RAM_num_visible_gushes).w
	bra.s   .objs_next

.objs_gush_crack:
	lea     DATA_spritemap_gush_crack, a0
	bra.s   .objs_add_map

.objs_push_crate:
	lea     DATA_spritemap_crate, a0
	moveq   #1, d2
	bra.s   .objs_add_map

.objs_rope_vertical:
	lea     DATA_spritemap_rope_vertical, a0
	moveq   #1, d2
	bra.s   .objs_add_map

.objs_spring:
	lea     DATA_spritemap_spring, a0
	moveq   #1, d2

	; If this is not the spring the player character has hit, do not animate
	cmpa.l  (RAM_hit_spring).w, a2
	bne.s   .objs_add_map

	moveq   #0, d3
	move.b  (RAM_anims+ANIM_HIT_SPRING).w, d3
	add.w   d3, d3
	add.w   d3, d3
	add.w   d3, d3
	add.w   d3, d3
	adda.w  d3, a0

.objs_add_map:
	bsr     add_spritemap
.objs_next:
	addq.w  #8, a2
	dbf     d7, .objs_loop
.objs_done:

;------------------------;
; Add sprites for gushes ;
;------------------------;

	tst.b   (RAM_num_visible_gushes).w
	beq     .no_gushes

	; Find location of next sprite within the buffer and store it in a0
	lea     (RAM_sprite_buffer).w, a0
	adda.w  (RAM_sprite_buffer_next_offs).w, a0

	lea     (RAM_visible_gushes).w, a2

	moveq   #0, d7
	move.b  (RAM_num_visible_gushes).w, d7
	subq.w  #1, d7

	; Store current gush animation frame in d4
	moveq   #0, d4
	move.b  (RAM_anims+ANIM_GUSHES).w, d4

.gushes_loop:
	; Store the X position of the gush in d1
	move.w  (a2)+, d1

	; Apply camera offset
	sub.w   (RAM_draw_offset_x).w, d1

	; Apply (128, 128) offset used by the VDP
	addi.w  #128, d1

	; Add gush hole sprite
	move.w  #(128+263), d2
	sub.w   (RAM_draw_offset_y).w, d2
	move.w  #SPR_GUSH_HOLE, d0
	moveq   #6, d3
	bsr     add_sprite_simple

	; Store the Y position of the gush in d2
	move.w  (a2)+, d2

	; Apply (128, 128) offset used by the VDP
	addi.w  #128, d2

	; Apply camera offset
	sub.w   (RAM_draw_offset_y).w, d2

	; Find sprite corresponding to gush top animation frame
	move.w  d4, d0
	add.w   d0, d0
	addi.w  #SPR_GUSH_TOP_1, d0

	; Set sprite size for gush top
	moveq   #4, d3

	; Add gush top sprite
	bsr     add_sprite_simple

	; Store maximum Y position for a gush middle sprite in d5
	move.w  #(128+264), d5
	sub.w   (RAM_draw_offset_y).w, d5

	; Find sprite corresponding to gush middle animation frame
	move.w  d4, d0
	add.w   d0, d0
	add.w   d0, d0
	add.w   d0, d0
	addi.w  #SPR_GUSH_MIDDLE_1, d0

	; Set sprite size for gush middle
	moveq   #7, d3

	; Add gush middle sprites
	cmp.w   d5, d2
	bge.s   .next_gush
	bsr     add_sprite_simple
	addi.w  #24, d2
	cmp.w   d5, d2
	bge.s   .next_gush
	bsr     add_sprite_simple
	addi.w  #24, d2
	cmp.w   d5, d2
	bge.s   .next_gush
	bsr     add_sprite_simple

.next_gush:
	dbf     d7, .gushes_loop
.no_gushes:

;-------------------------------------------;
; Add background sprites for overhead signs ;
;-------------------------------------------;

	moveq   #0, d7
	move.b  (RAM_num_overhead_signs).w, d7
	beq.s   .overhead_signs_bg_done

	subq.w  #1, d7
	movea.l (RAM_ptr_overhead_signs).w, a2

	; Find location of next sprite within the buffer and store it in a0
	lea     (RAM_sprite_buffer).w, a0
	adda.w  (RAM_sprite_buffer_next_offs).w, a0

.overhead_signs_bg_loop:
	move.w  (a2)+, d1 ; X
	move.w  (a2)+, d2 ; Y

	sub.w   (RAM_draw_offset_x).w, d1

	; Skip signs to the left of the visible area
	cmpi.w  #-32, d1
	ble.s   .overhead_signs_bg_next

	; If the sign is to the right of the visible area, then there are no
	; more visible signs, as the signs are always sorted by X position
	cmpi.w  #SCREEN_W, d1
	bge.s   .overhead_signs_bg_done

	sub.w   (RAM_draw_offset_y).w, d2

	; Apply (128, 128) offset used by the VDP
	addi.w  #128, d1
	addi.w  #128, d2

	; Add sign top left sprite
	move.w  #$2000|SPR_OVERHEAD_SIGN_TOP_LEFT, d0
	move.w  #$7, d3
	bsr     add_sprite_simple

.overhead_signs_bg_next:
	dbf     d7, .overhead_signs_bg_loop
.overhead_signs_bg_done:

;-----------------------------------------;
; Add sprites for wheels of parked trucks ;
;-----------------------------------------;

	moveq   #0, d7
	move.b  (RAM_num_parked_vehicles).w, d7
	beq.s   .parked_vehicle_wheels_done

	movea.l (RAM_ptr_parked_vehicles).w, a6
	subq.w  #1, d7

.parked_vehicle_wheels_loop:
	move.w  (a6)+, d2 ; Get type
	move.w  (a6)+, d3 ; Get X position (in tiles)

	; If it is not a truck, skip
	cmpi.w  #VEH_PARKED_TRUCK, d2
	bne.s   .parked_vehicle_wheels_next

	; If the truck is too far to the right, there are no more parked
	; vehicles to check
	move.w  d3, d0
	sub.w   (RAM_col32_tiles).w, d0
	cmpi.w  #60, d0
	bge.s   .parked_vehicle_wheels_done

	; If the truck is too far to the left, skip to the next vehicle
	addi.w  #35, d0
	blt.s   .parked_vehicle_wheels_next

	; Find X position of rear wheel
	move.w  d3, d0
	add.w   d0, d0
	add.w   d0, d0
	add.w   d0, d0
	addi.w  #48, d0

	lea     DATA_spritemap_truck_wheel, a2

	; Y position of wheels
	move.w  #232, d1

	; Add rear wheel sprite
	movea.l a2, a0
	moveq   #0, d2
	bsr     add_spritemap

	; Add front wheel sprite
	addi.w  #176, d0
	movea.l a2, a0
	moveq   #0, d2
	bsr     add_spritemap

.parked_vehicle_wheels_next:
	dbf     d7, .parked_vehicle_wheels_loop
.parked_vehicle_wheels_done:

;----------------------------------------------------;
; Add sprites for hydrants and horizontal rope edges ;
;----------------------------------------------------;

	; Skip if it is the ending sequence
	btst.b  #7, (RAM_play_flags).w
	bne     .hydrants_rope_edges_done

	move.w  #16-1, d7 ; Number of level columns to check minus one

	move.w  (RAM_col24).w, d6

	; Store initial column address in a1
	movea.l (RAM_ptr_level_columns).w, a1
	adda.w  d6, a1

	; Calculate X position of the first visible level column in pixels
	; (that is, multiply it by 24) and store the result in d6
	move.w  d6, d0
	add.w   d6, d6
	add.w   d0, d6
	add.w   d6, d6
	add.w   d6, d6
	add.w   d6, d6

	; Apply camera offset and the (128, 128) offset used by the VDP
	sub.w   (RAM_draw_offset_x).w, d6
	addi.w  #128, d6

	; Find location of next sprite within the buffer and store it in a0
	lea     (RAM_sprite_buffer).w, a0
	adda.w  (RAM_sprite_buffer_next_offs).w, a0

.hydrants_rope_edges_loop:
	; Check hydrant presence bit and skip if unset
	move.b  (a1), d4
	btst.l  #6, d4
	beq.s   .no_hydrant

	; Retrieve X position from d6
	move.w  d6, d1

	; Y position
	move.w  #(HYDRANT_Y+128), d2
	sub.w   (RAM_draw_offset_y).w, d2

	; Sprite number and flags
	move.w  #$2000|SPR_HYDRANT, d0

	; Sprite size
	move.w  #$6, d3

	; Add hydrant sprite
	bsr     add_sprite_simple
.no_hydrant:

	; Get the values of two level columns
	move.b  (a1), d1
	andi.w  #$80, d1
	move.b  1(a1), d2
	andi.w  #$80, d2

	; If the rope presence bit is equal for both columns, there is no edge
	cmp.b   d1, d2
	beq.s   .no_rope_edge

	; Determine whether it is the left or right edge
	move.w  #SPR_HORIZONTAL_ROPE_EDGE_LEFT, d0
	tst.b   d2
	bne.s   .not_right_edge
	move.w  #SPR_HORIZONTAL_ROPE_EDGE_RIGHT, d0
.not_right_edge:

	; Add sprite for rope edge
	move.w  d6, d1
	addi.w  #10, d1
	move.w  #(ROPE_Y+128), d2
	sub.w   (RAM_draw_offset_y).w, d2
	moveq   #$5, d3
	bsr     add_sprite_simple
.no_rope_edge:

	; Move to next level column
	addi.w  #24, d6
	addq.w  #1, a1
	dbf     d7, .hydrants_rope_edges_loop
.hydrants_rope_edges_done:

;-----------------------------;
; Add sprites for light poles ;
;-----------------------------;

	moveq   #16, d0  ; X position of first pole
	moveq   #-32, d1
	move.w  #384, d2 ; Distance between poles in pixels

	; Find first visible pole
	sub.w   (RAM_draw_offset_x).w, d0
.light_pole_find_loop:
	cmp.w   d1, d0
	bgt.s   .light_pole_found

	; Try next pole
	add.w   d2, d0
	bra.s   .light_pole_find_loop

.light_pole_found:
	moveq   #4, d2
	add.w   (RAM_draw_offset_x).w, d0
	moveq   #POLE_Y, d1
	lea     DATA_spritemap_light_pole, a0
	bsr     add_spritemap

;----------------------------------;
; Add sprites for passageway exits ;
;----------------------------------;

	movea.l (RAM_ptr_passageways).w, a2
	moveq   #0, d6 ; Current passageway index
	moveq   #(MAX_PASSAGEWAYS-1), d7 ; Remaining passageways counter

.passageways_loop:
	; If the passageway exit has been opened, skip to the next passageway
	btst.b  d6, (RAM_passageway_opened_exits).w
	bne.s   .next_passageway

	; Ignore inexistent passageways
	tst.w   (a2)
	ble.s   .next_passageway

	; Draw passageway closed exit
	move.w  2(a2), d0
	subi.w  #24, d0
	move.w  #256, d1
	moveq   #0, d2
	lea     DATA_spritemap_passageway_closed_exit, a0
	bsr     add_spritemap

.next_passageway:
	addq.w  #1, d6
	addq.w  #4, a2
	dbf     d7, .passageways_loop

;---------------------------------;
; Add sprites for the passing car ;
;---------------------------------;

	move.w  (RAM_passing_car_x).w, d0
	ble.s   .no_passing_car

	; Find spritemap corresponding to wheel animation frame
	lea     DATA_spritemap_car_wheels, a2
	tst.b   (RAM_anims+ANIM_CAR_WHEELS).w
	beq.s   .passing_car_not_wheel_frame_2
	addq.w  #8, a2
.passing_car_not_wheel_frame_2:

	; Draw rear wheel
	addi.w  #24, d0
	move.w  #(PASSING_CAR_Y+40), d1
	moveq   #0, d2
	movea.l a2, a0
	bsr     add_spritemap

	; Draw front wheel
	addi.w  #(104-24), d0
	moveq   #0, d2
	movea.l a2, a0
	bsr     add_spritemap

	; Find spritemap corresponding to car color
	moveq   #0, d0
	move.b  (RAM_passing_car_color).w, d0
	add.w   d0, d0
	add.w   d0, d0
	add.w   d0, d0
	add.w   d0, d0
	add.w   d0, d0
	add.w   d0, d0
	lea     DATA_spritemap_car, a0
	adda.w  d0, a0

	; Draw car body
	move.w  (RAM_passing_car_x).w, d0
	move.w  #PASSING_CAR_Y, d1
	moveq   #7, d2
	bsr     add_spritemap
.no_passing_car:

;-------------------------;
; Add sprites for the hen ;
;-------------------------;

	tst.w   (RAM_hen_x).w
	ble.s   .no_hen

	moveq   #0, d0
	move.b  (RAM_anims+ANIM_HEN).w, d0
	add.w   d0, d0
	add.w   d0, d0
	add.w   d0, d0
	add.w   d0, d0
	lea     DATA_spritemap_hen, a0
	adda.w  d0, a0

	move.w  (RAM_hen_x).w, d0
	move.w  #HEN_Y, d1
	moveq   #1, d2
	bsr     add_spritemap
.no_hen:

;--------------------------------------------;
; Add sprites for ending sequence car wheels ;
;--------------------------------------------;

	; Skip if it is not the ending sequence
	btst.b  #7, (RAM_play_flags).w
	beq.s   .ending_car_wheels_done

	; Find spritemap corresponding to wheel animation frame
	lea     DATA_spritemap_car_wheels, a2
	tst.b   (RAM_anims+ANIM_CAR_WHEELS).w
	beq.s   .ending_cars_not_wheel_frame_2
	addq.w  #8, a2
.ending_cars_not_wheel_frame_2:

	; Find X position of the rear wheel of the first car (calculated from
	; the X position of the bus)
	move.w  (RAM_bus_x).w, d0
	addi.w  #((50*8)+24), d0

	move.w  #(PASSING_CAR_Y+40), d1

	; Number of cars minus one
	moveq   #6-1, d7
.ending_car_wheels_loop:
	; Rear wheel
	moveq   #0, d2
	movea.l a2, a0
	bsr     add_spritemap

	; Front wheel
	addi.w  #80, d0
	moveq   #0, d2
	movea.l a2, a0
	bsr     add_spritemap

	; Next car
	addi.w  #(32+24), d0
	dbf     d7, .ending_car_wheels_loop
.ending_car_wheels_done:

;-------------------------------------------------------------------;
; Check if the bus is visible and skip sprites related to it if not ;
;-------------------------------------------------------------------;

	move.w  (RAM_bus_x).w, d0
	sub.w   (RAM_draw_offset_x).w, d0
	cmpi.w  #SCREEN_W, d0
	bgt     .bus_not_visible
	addi.w  #400, d0 ; Bus width in pixels
	blt     .bus_not_visible

;----------------------------;
; Add sprites for bus wheels ;
;----------------------------;

	; Point a2 to current animation frame within spritemap
	moveq   #0, d0
	move.b  (RAM_anims+ANIM_BUS_WHEELS).w, d0
	add.w   d0, d0
	add.w   d0, d0
	add.w   d0, d0
	lea     DATA_spritemap_truck_wheel, a2
	adda.w  d0, a2

	; Y position of the wheels
	move.w  #216, d1

	; Add rear wheel sprite
	move.w  (RAM_bus_x).w, d0
	addi.w  #112, d0
	moveq   #0, d2
	movea.l a2, a0
	bsr     add_spritemap

	; Add front wheel sprite
	addi.w  #192, d0
	moveq   #0, d2
	movea.l a2, a0
	bsr     add_spritemap

;---------------------------;
; Add sprites for bus doors ;
;---------------------------;

	; Find spritemap for current animation frame of rear door
	moveq   #0, d0
	move.b  (RAM_anims+ANIM_BUS_DOOR_REAR).w, d0
	add.w   d0, d0
	add.w   d0, d0
	add.w   d0, d0
	add.w   d0, d0
	add.w   d0, d0
	add.w   d0, d0
	lea     DATA_spritemap_bus_door, a0
	adda.w  d0, a0

	; Add rear door sprites
	move.w  (RAM_bus_x).w, d0
	addi.w  #64, d0
	move.w  #(BUS_Y+20), d1
	moveq   #(6-1), d2
	bsr     add_spritemap

	; Find spritemap for current animation frame of front door
	moveq   #0, d0
	move.b  (RAM_anims+ANIM_BUS_DOOR_FRONT).w, d0
	add.w   d0, d0
	add.w   d0, d0
	add.w   d0, d0
	add.w   d0, d0
	add.w   d0, d0
	add.w   d0, d0
	lea     DATA_spritemap_bus_door, a0
	adda.w  d0, a0

	; Add front door sprites
	move.w  (RAM_bus_x).w, d0
	addi.w  #344, d0
	move.w  #(BUS_Y+20), d1
	moveq   #(6-1), d2
	bsr     add_spritemap

;------------------------------------;
; Add sprites for the bus route sign ;
;------------------------------------;

	moveq   #0, d0
	move.b  (RAM_bus_route_sign).w, d0
	add.w   d0, d0
	add.w   d0, d0
	add.w   d0, d0

	lea     DATA_spritemap_bus_route_sign, a0
	adda.w  d0, a0
	move.w  (RAM_bus_x).w, d0
	addi.w  #308, d0
	move.w  #(BUS_Y+52), d1
	moveq   #0, d2
	bsr     add_spritemap

;-----------------------------------------------------;
; Add sprites for the characters at the bus rear door ;
;-----------------------------------------------------;

	; No characters to draw if the rear door is closed
	tst.b   (RAM_anims+ANIM_BUS_DOOR_REAR).w
	beq.s   .bus_characters_none

	; Determine number of characters to draw
	moveq   #0, d0
	move.b  (RAM_bus_num_characters).w, d0
	beq.s   .bus_characters_none
	subq.b  #1, d0
	beq.s   .bus_characters_one
	subq.b  #1, d0
	beq.s   .bus_characters_two

	; Three characters
	move.w  (RAM_bus_x).w, d0
	addi.w  #80, d0
	move.w  #(BUS_Y+24), d1
	move.w  #5, d2
	lea     DATA_spritemap_bus_character_3, a0
	bsr     add_spritemap

.bus_characters_two:
	move.w  (RAM_bus_x).w, d0
	addi.w  #64, d0
	move.w  #(BUS_Y+24), d1
	move.w  #5, d2
	lea     DATA_spritemap_bus_character_2, a0
	bsr     add_spritemap

.bus_characters_one:
	move.w  (RAM_bus_x).w, d0
	addi.w  #72, d0
	move.w  #(BUS_Y+24), d1
	move.w  #5, d2
	lea     DATA_spritemap_bus_character_1, a0
	bsr     add_spritemap

.bus_characters_none:
.bus_not_visible:

;------------------------------------------------------;
; Add sprites for cutscene objects that are in the bus ;
;------------------------------------------------------;

	lea    (RAM_cutscene_objs+32).w, a2
	lea    (RAM_anims+ANIM_CUTSCENE_OBJ_2).w, a3
	moveq  #(2-1), d7
.in_cutscene_objs_loop:
	tst.b  (a2)
	beq.s  .next_in_cutscene_obj
	tst.b  1(a2)
	beq.s  .next_in_cutscene_obj

	bsr.s   add_spritemap_cutscene_obj

.next_in_cutscene_obj:
	lea     -32(a2), a2
	subq.w  #8, a3
	dbf     d7, .in_cutscene_objs_loop

	rts

; ------------------------------------------------------------------------------

update_scroll:
	lea     VDP_DATA, a0

	; Set VRAM address for horizontal scroll ($A800)
	move.l  #$68000002, 4(a0)

	move.w  (RAM_bus_x).w, d1
	sub.w   (RAM_bus_init_x).w, d1

	; Plane A
	move.w  #512, d0
	sub.w   (RAM_draw_offset_x).w, d0
	add.w   d1, d0
	andi.w  #511, d0
	move.w  d0, (a0)

	; Plane B
	move.w  #512, d0
	sub.w   (RAM_draw_offset_x).w, d0
	andi.w  #511, d0
	move.w  d0, (a0)

	; Update vertical scroll
	move.w  (RAM_draw_offset_y).w, d0
	move.l  #$40000010, 4(a0)
	move.w  d0, (a0) ; Plane A
	move.w  d0, (a0) ; Plane B

	rts

; ------------------------------------------------------------------------------

; a2 = Cutscene object location within RAM_cutscene_objs
; a3 = Animation location within RAM_anims
add_spritemap_cutscene_obj:
	move.l  2(a2), d0
	move.w  6(a2), d1

	; Make X position relative to the bus if the object is in it
	tst.b   1(a2)
	beq.s   .not_in_bus
	add.l   (RAM_bus_x).w, d0
.not_in_bus:

	; Discard fractional part of X position
	clr.w   d0
	swap.w  d0

	; Get animation frame
	moveq   #0, d3
	move.b  (a3), d3

	moveq   #0, d2
	move.b  (a2), d2
	subq.b  #1, d2
	add.w   d2, d2
	jmp     .jump_table(pc, d2.w)
.jump_table:
	bra.s   .player_stand
	bra.s   .player_walk
	bra.s   .player_run
	bra.s   .player_clean_dung
	bra.s   .bearded_man_stand
	bra.s   .bearded_man_walk
	bra.s   .bearded_man_jump
	bra.s   .bird
	bra.s   .dung
	bra.s   .flagman

.player_stand:
	move.w  #2, d2
	lea     DATA_spritemap_player, a0
	bra.s   add_spritemap

.player_walk:
	move.w  #2, d2
	lea     DATA_spritemap_player+32, a0
	lsl.w   #5, d3
	adda.w  d3, a0
	bra.s   add_spritemap

.player_run:
	move.w  #4, d2
	lea     DATA_spritemap_player_run, a0
	lsl.w   #6, d3
	adda.w  d3, a0
	bra.s   add_spritemap

.player_clean_dung:
	move.w  #4, d2
	lea     DATA_spritemap_player_clean_dung, a0
	lsl.w   #6, d3
	adda.w  d3, a0
	bra.s   add_spritemap

.bearded_man_stand:
	move.w  #2, d2
	lea     DATA_spritemap_bearded_man_stand, a0
	bra.s   add_spritemap

.bearded_man_walk:
	move.w  #2, d2
	lea     DATA_spritemap_bearded_man_walk, a0
	lsl.w   #5, d3
	adda.w  d3, a0
	bra.s   add_spritemap

.bearded_man_jump:
	move.w  #2, d2
	lea     DATA_spritemap_bearded_man_jump, a0
	bra.s   add_spritemap

.bird:
	moveq   #0, d2
	lea     DATA_spritemap_bird, a0
	lsl.w   #3, d3
	adda.w  d3, a0
	bra.s   add_spritemap

.dung:
	moveq   #0, d2
	lea     DATA_spritemap_dung, a0
	bra.s   add_spritemap

.flagman:
	moveq   #3, d2
	lea     DATA_spritemap_flagman, a0
	lsl.w   #5, d3
	adda.w  d3, a0

	; Fallthrough

; ------------------------------------------------------------------------------

; Input
; d0 = X position
; d1 = Y position
; d2 = Maximum number of map entries minus one
; a0 = Pointer to spritemap
;
; Breaks
; d2-d4, a0-a1
add_spritemap:
	; Find location of next sprite within the buffer
	lea     (RAM_sprite_buffer).w, a1
	adda.w  (RAM_sprite_buffer_next_offs).w, a1

.add_spritemap_loop:
	; If the tile number is zero, end the list
	tst.w   6(a0)
	beq.s   .ret

	; Too many sprites?
	tst.b   (RAM_sprite_buffer_free_slots).w
	beq.s   .ret

	move.w  (a0), d3  ; X offset
	move.w  2(a0), d4 ; Y offset

	; Apply offsets
	add.w   d0, d3
	sub.w   (RAM_draw_offset_x).w, d3
	add.w   d1, d4
	sub.w   (RAM_draw_offset_y).w, d4

	; Skip if the position is out of the screen
	cmpi.w  #-32, d3
	ble.s   .next_map_entry
	cmpi.w  #SCREEN_W, d3
	bge.s   .next_map_entry
	cmpi.w  #-32, d4
	ble.s   .next_map_entry
	cmpi.w  #SCREEN_H, d4
	bge.s   .next_map_entry

	; Apply (128, 128) offset used by the VDP
	addi.w  #128, d3
	addi.w  #128, d4

	; Add sprite to buffer
	move.w  d4,    (a1)+ ; Y position
	move.b  5(a0), (a1)+ ; Size
	clr.b   (a1)+        ; Link (filled later)
	move.w  6(a0), (a1)+ ; Tile and flags
	move.w  d3,    (a1)+ ; X position

	; Update buffer next offset and number of free slots
	addq.w  #8, (RAM_sprite_buffer_next_offs).w
	subq.b  #1, (RAM_sprite_buffer_free_slots).w

.next_map_entry:
	addq.w  #8, a0
	dbf     d2, .add_spritemap_loop

.ret:
	rts

; ------------------------------------------------------------------------------

; Input
; d0 = tile and flags
; d1 = X position
; d2 = Y position
; d3 = size
; a0 = location of the sprite within RAM_sprite_buffer
;
; Output
; a0 = next available location within RAM_sprite_buffer
;
; Breaks
; a0
;
; Note: the camera and the (128, 128) offset used by the VDP are not handled
; automatically
add_sprite_simple:
	; Too many sprites?
	tst.b   (RAM_sprite_buffer_free_slots).w
	beq.s   .ret

	; Add sprite to buffer
	move.w  d2,   (a0)+ ; Y position
	move.b  d3,   (a0)+ ; Size
	clr.b   (a0)+       ; Link (filled later)
	move.w  d0,   (a0)+ ; Tile and flags
	move.w  d1,   (a0)+ ; X position

	; Update buffer next offset and number of free slots
	addq.w  #8, (RAM_sprite_buffer_next_offs).w
	subq.b  #1, (RAM_sprite_buffer_free_slots).w

.ret:
	rts

