;----------------------------------------------------------
;
;	Z80 DAC sample driver for Sega Genesis
;	By M374LX
;
;	Sample rate: 11025 Hz
;
;----------------------------------------------------------

;----------------------------------------------------------
;	68000 communication variables
;----------------------------------------------------------

; Zero if the 68000 is free to access the YM2612; nonzero
; if the Z80 is acessing it and the 68000 needs to wait
status: equ $1FF0

; Command
; 1. Start playing a sample
; 2. Stop
cmd:    equ $1FF1

; Sample address
addr:   equ $1FF2

;----------------------------------------------------------
;       Driver entry point
;----------------------------------------------------------
start:
	jp      start_driver    ; Jump over interrupt handler

	dcb.b   $35             ; Pad

	ret                     ; Z80 interrupt address: $38

start_driver:
	di
	im      1
	ld      sp, $2000       ; Set stack

	; Point ix to the first YM2612 port
	ld      ix, $4000

	; Initialize DAC-related YM2612 registers
	ld      (ix+2), $B4     ; Enable stereo
	ld      (ix+3), $C0
	ld      (ix+0), $2B     ; Disable DAC by default
	ld      (ix+1), $00

	; Initialize the play flag and status with zero
	xor     a
	ld      (cmd), a
	ld      (status), a

main_loop:
	ld      a, (cmd)
	cp      1               ; Start playing a sample?
	jp      nz, main_loop

	; Reset the command
	xor     a
	ld      (cmd), a

;----------------------------------------------------------
;       Set bank address
;----------------------------------------------------------
	ld      hl, $6000

	ld      a, (addr+1)
	rlca
	ld      (hl), a         ; #1 (bit 7)

	ld      a, (addr+2)
	ld      (hl), a         ; #2 (bit 0)
	rrca
	ld      (hl), a         ; #3
	rrca
	ld      (hl), a         ; #4
	rrca
	ld      (hl), a         ; #5
	rrca
	ld      (hl), a         ; #6
	rrca
	ld      (hl), a         ; #7
	rrca
	ld      (hl), a         ; #8
	rrca
	ld      (hl), a         ; #9 (bit 7)

	; Point hl to sample address within $8000-$FFFF
	ld      a, (addr)
	ld      l, a
	ld      a, (addr+1)
	or      $80
	ld      h, a

	; Enable DAC
	ld      a, 1
	ld      (status), a
	ld      (ix+0), $2B
	ld      (ix+1), $80
	xor     a
	ld      (status), a

sample_loop:
	; Wait enough cycles for a sample rate of 11025 Hz
	ld      a, 13
wait:
	dec     a
	jp      nz, wait

	; Store sample byte in b
	ld      b, (hl)

	; Has the sample ended?
	inc     b
	jp      z, sample_ended

	ld      a, 1
	ld      (status), a
	ld      (ix+0), $2A     ; Write byte do DAC
	ld      (ix+1), b
	xor     a
	ld      (status), a

	; Has a command been sent before finishing
	; playing the sample?
	ld      a, (cmd)
	or      a
	jp      nz, sample_ended

	; Increment sample position
	inc     hl

	jp      sample_loop

sample_ended:
	; Disable DAC
	ld      a, 1
	ld      (status), a
	ld      (ix+0), $2B
	ld      (ix+1), $00
	xor     a
	ld      (status), a

	jp      main_loop

