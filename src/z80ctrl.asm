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
; z80ctrl.asm
;
; Description:
; Macros for controlling the operation of the Z80 coprocessor
;

; ------------------------------------------------------------------------------

Z80_BUSREQ: equ $A11100
Z80_RESET:  equ $A11200

z80_halt: macro
	move.w  #$100, Z80_BUSREQ
.wait\@:
	btst.b  #0, Z80_BUSREQ
	bne.s   .wait\@
	endm

z80_resume: macro
	move.w  #$000, Z80_BUSREQ
	endm

