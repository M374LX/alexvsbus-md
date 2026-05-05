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
; header.asm
;
; Description:
; The Motorola 68000 vectors followed by the Sega Genesis/Mega Drive ROM header
;

; ------------------------------------------------------------------------------

	; 68000 vectors
	dc.l $00000000,  startup,    int_error,  int_error
	dc.l int_error,  int_error,  int_error,  int_error
	dc.l int_error,  int_error,  int_error,  int_error
	dc.l int_error,  int_error,  int_error,  int_error

	dc.l int_error,  int_error,  int_error,  int_error
	dc.l int_error,  int_error,  int_error,  int_error
	dc.l int_error,  int_error,  int_error,  int_error
	dc.l int_hblank, int_error,  int_vblank, int_error

	dc.l int_error,  int_error,  int_error,  int_error
	dc.l int_error,  int_error,  int_error,  int_error
	dc.l int_error,  int_error,  int_error,  int_error
	dc.l int_error,  int_error,  int_error,  int_error

	dc.l int_error,  int_error,  int_error,  int_error
	dc.l int_error,  int_error,  int_error,  int_error
	dc.l int_error,  int_error,  int_error,  int_error
	dc.l int_error,  int_error,  int_error,  int_error

	; Sega Genesis ROM header
	dc.b "SEGA GENESIS    "
	dc.b "(C) 2026 M374LX "
	dc.b "ALEX VS BUS: THE RACE                           "
	dc.b "ALEX VS BUS: THE RACE                           "
	dc.b "GM 00000000-00"
	dc.w $0000
	dc.b "J               "
	dc.l $00000000
	dc.l $0007FFFF ; 512 kB
	dc.l $00FF0000
	dc.l $FFFFFFFF
	dc.b 'RA', $F8, $20
	dc.l $200001
	dc.l $2003FF
	dc.b "            "
	dc.b "                                        "
	dc.b "JUE"
	dc.b "             "

