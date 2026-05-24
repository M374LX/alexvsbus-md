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
; startup.asm
;
; Description:
; The startup code, which runs before everything else
;

; ------------------------------------------------------------------------------

startup:
	; Check TMSS
	move.b  $A10001, d0
	andi.b  #$0F, d0
	beq.s   .no_tmss
	move.l  #'SEGA', $A14000
.no_tmss:
	move.w  #$2700, sr ; Supervisor mode, interrupts disabled
	movea.l #0, sp ; Set stack pointer

	; Store VDP control port address in a0
	lea     VDP_CTRL, a0

	; Clear VDP status by doing a dummy read
	tst.w   (a0)

	; Initialize VDP registers
	move.w  #$8014, (a0)    ; Enable HBlank interrupt
	move.w  #$8114, (a0)    ; No display, no IRQ6, DMA OK, V28
	move.w  #$8200+($C000>>10), (a0) ; Plane A address
	move.w  #$8300+($B000>>10), (a0) ; Window address
	move.w  #$8400+($E000>>13), (a0) ; Plane B address
	move.w  #$8500+($AC00>>9),  (a0) ; Sprite table address
	move.w  #$8700, (a0)    ; Background color: palette 0, index 0
	move.w  #$8A07, (a0)    ; Horizontal interrupt rate
	move.w  #$8B00, (a0)    ; Full screen scroll, no external interrupts
	move.w  #$8C81, (a0)    ; H40, no S/H, no double-res, no interlace
	move.w  #$8D00+($A800>>10), (a0) ; HScroll data address
	move.w  #$8F02, (a0)    ; Autoincrement: 2 bytes per write
	move.w  #$9011, (a0)    ; Playfield size: 64x64
	move.w  #$9100, (a0)    ; Hide window plane
	move.w  #$9200, (a0)    ; Hide window plane

	; Clear RAM
	lea     $FF0000, a0
	moveq   #0, d0
	move.w  #(65536/4)-1, d1 ; RAM size
.ram_clear_loop:
	move.l  d0, (a0)+
	dbf     d1, .ram_clear_loop

	; Store VDP data port address in a0
	lea     VDP_DATA, a0

	; Clear VRAM
	moveq   #0, d0
	move.w  #(65536/4)-1, d1 ; VRAM size
	move.l  #$40000000, 4(a0)
.vram_clear_loop:
	move.l  d0, (a0)
	dbf     d1, .vram_clear_loop

	; Clear CRAM
	moveq   #0, d0
	move.w  #(128/4)-1, d1 ; CRAM size
	move.l  #$C0000000, 4(a0)
.cram_clear_loop:
	move.l  d0, (a0)
	dbf     d1, .cram_clear_loop

	; Clear VSRAM
	moveq   #0, d0
	move.w  #(80/4)-1, d1 ; VSRAM size
	move.l  #$40000010, 4(a0)
.vsram_clear_loop:
	move.l  d0, (a0)
	dbf     d1, .vsram_clear_loop

	; Initialize joypads
	move.b  #$40, $A10009
	move.b  #$40, $A10003

	; Clear data registers
	moveq   #0, d0
	moveq   #0, d1
	moveq   #0, d2
	moveq   #0, d3
	moveq   #0, d4
	moveq   #0, d5
	moveq   #0, d6
	moveq   #0, d7

	move.w  #$2300, sr ; Supervisor mode, interrupts enabled

	bra.s   main

