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
; interrupts.asm
;
; Description:
; Implementation of interrupts
;

; ------------------------------------------------------------------------------

int_error:
	nop
	bra.s   int_error

; ------------------------------------------------------------------------------

int_hblank:
	tst.b   (RAM_wipe_enabled).w
	bne.s   .wiping
	rte

.wiping:
	movem.l d0-d1/a0, -(sp)

	lea     VDP_CTRL, a0
	moveq   #0, d0
	move.b  4(a0), d0

	; If we are not in active display, skip
	cmpi.b  #SCREEN_H, d0
	bhs.s   .ret

	move.w   (RAM_wipe_value).w, d1
	beq.s   .ret
	subq.w  #1, d1
	cmpi.w  #(SCREEN_H/2)-1, d1
	bhs.s   .ret

	cmp.w   d0, d1
	beq.s   .wipe_top

	move.w   #(SCREEN_H-1), d1
	sub.w    (RAM_wipe_value).w, d1

	cmp.w   d0, d1
	beq.s   .wipe_bottom

.ret:
	movem.l (sp)+, d0-d1/a0
	rte

.wipe_top:
	move.w  #$8164, (a0)
	bra.s   .ret

.wipe_bottom:
	move.w  #$8124, (a0)
	bra.s   .ret

; ------------------------------------------------------------------------------

int_vblank:
	movem.l d0-d7/a0-a6, -(sp)
	addq.l  #1, (RAM_vtimer).w
	bsr     sound_update
	movem.l (sp)+, d0-d7/a0-a6
	rte

