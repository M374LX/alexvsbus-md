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
; sound.asm
;
; Description:
; The sound system
;

; ------------------------------------------------------------------------------

SOUNDRAM_size:                  equ $80

; Flags:
; 0 - BGM paused
; 1 - Handling the SFX (not BGM) stream
; 2 - PAL system
SOUNDRAM_flags:                 equ RAM_sound+$00

; One bit for each channel
SOUNDRAM_locked_channels:       equ RAM_sound+$02

; Stream properties:
; +$00 (W) - Position
; +$02 (W) - Remaining ticks for next event
; +$04 (B) - Playing (boolean)
; +$06 (W) - Loop start position
; +$08 (L) - Start location
SOUNDRAM_stream_bgm:            equ RAM_sound+$10
SOUNDRAM_stream_sfx:            equ RAM_sound+$20

; Each byte keeps track of each channel's current instrument for music
SOUNDRAM_instrs:                equ RAM_sound+$30

; Memory area reserved for the states of the PSG envelopes
;
; Layout:
; +$00 (L) - Channel 1 envelope start pointer
; +$04 (B) - Channel 1 loop start position
; +$05 (B) - Channel 1 current envelope position
; +$06 (W) - Channel 1 frequency
;
; +$08 (L) - Channel 2 envelope start pointer
; +$0C (B) - Channel 2 loop start position
; +$0D (B) - Channel 2 current envelope position
; +$0E (W) - Channel 2 frequency
;
; +$10 (L) - Channel 3 envelope start pointer
; +$14 (B) - Channel 3 loop start position
; +$15 (B) - Channel 3 current envelope position
; +$16 (W) - Channel 3 frequency
;
; +$18 (L) - Channel 4 envelope start pointer
; +$1C (B) - Channel 4 loop start position
; +$1D (B) - Channel 4 current envelope position
; +$1E (W) - Channel 4 noise type
;
; For the frequency or noise type of each channel, $0000 means no change and
; $FFFF means note off
;
SOUNDRAM_psg_instrs:            equ RAM_sound+$40

; Two words (four bytes) for each of the PSG tone channels
;
; For each channel, the first word is the base frequency and the second word is
; the vibrato position
SOUNDRAM_vibrato:               equ RAM_sound+$60

; One bit for each PSG tone channel determining whether vibrato is enabled
SOUNDRAM_vibrato_enable:        equ RAM_sound+$70

; ------------------------------------------------------------------------------

PSG_DATA:                       equ $C00011
FM_DATA:                        equ $A04000

; Location of the "status" variable in Z80 RAM
Z80_STATUS_ADDR:                equ $A01FF0

; Z80 sample driver commands
Z80_CMD_PLAY:                   equ 1
Z80_CMD_STOP:                   equ 2

; ------------------------------------------------------------------------------

sound_init:
	; Silence all four PSG channels
	lea     PSG_DATA, a0
	move.b  #$9F, (a0)
	move.b  #$BF, (a0)
	move.b  #$DF, (a0)
	move.b  #$FF, (a0)

	; Clear sound RAM
	moveq   #0, d1
	lea     RAM_sound, a0
	moveq   #(SOUNDRAM_size/4)-1, d0
.soundram_clear_loop:
	move.l  d1, (a0)+
	dbf     d0, .soundram_clear_loop

	; Halt and reset the Z80
	move.w  #$100, Z80_BUSREQ
	move.w  #$100, Z80_RESET

	; Load the Z80 driver
	lea     z80_driver, a0
	lea     $A00000, a1
	move.l  #(z80_driver_end-z80_driver-1), d0
.z80_driver_load_loop:
	move.b  (a0)+, (a1)+
	dbf     d0, .z80_driver_load_loop

	; Determine if the system is PAL
	move.b  $A10001, d0
	btst.l  #6, d0
	beq.s   .not_pal
	bset.b  #2, SOUNDRAM_flags
.not_pal:

	; Write zero to all of the following YM2612 registers
	moveq   #0, d1

	; LFO off
	move.b  #$22, d0
	bsr     ym_write

	; Channel 3 normal mode
	move.b  #$27, d0
	bsr     ym_write

	; Enable left and right output for channels 1-3
	move.b  #$C0, d1
	move.b  #$B4, d0
	bsr     ym_write
	move.b  #$B5, d0
	bsr     ym_write
	move.b  #$B6, d0
	bsr     ym_write
	
	; Write all of the following registers to part II
	move.w  #$100, d0

	; Enable left and right output for channels 4-6
	move.b  #$C0, d1
	move.b  #$B4, d0
	bsr     ym_write
	move.b  #$B5, d0
	bsr     ym_write
	move.b  #$B6, d0
	bsr     ym_write

	; Enable the Z80
	move.w  #0, Z80_BUSREQ

	rts

; ------------------------------------------------------------------------------

; Input
;   d0.w - BGM track number
;
; Breaks
;   d0-d1/a0
;
sound_play_bgm:
	bclr.b  #0, SOUNDRAM_flags ; Clear "paused" flag

	; Disable vibrato on all PSG tone channels
	clr.b   SOUNDRAM_vibrato_enable

	add.w   d0, d0
	add.w   d0, d0
	lea     DATA_bgm_list, a0
	adda.w  d0, a0
	move.l  (a0), d0

	lea     SOUNDRAM_stream_bgm, a0
	clr.l   (a0)+    ; Position and ticks
	st.b    (a0)+    ; Playing
	clr.b   (a0)+    ; Unused
	clr.w   (a0)+    ; Loop start
	move.l  d0, (a0) ; Start location

	bra.s   sound_silence_all_channels

; ------------------------------------------------------------------------------

sound_resume_bgm:
	btst.b  #0, SOUNDRAM_flags ; Test "paused" flag
	beq.s   .not_paused

	bclr.b  #0, SOUNDRAM_flags ; Clear "paused" flag
	st.b    SOUNDRAM_stream_bgm+4 ; Playing

.not_paused:
	rts

; ------------------------------------------------------------------------------

; Input
;   d0.w - SFX number
;
; Breaks
;   d0-d3/a0-a2
sound_play_sfx:
	; Find stream start location and store it in a2
	add.w   d0, d0
	add.w   d0, d0
	lea     DATA_sfx_list, a0
	movea.l (a0, d0.w), a2

	bsr     sound_stop_sfx

	lea     SOUNDRAM_stream_sfx, a1
	clr.l   (a1)+    ; Position and ticks
	st.b    (a1)+    ; Playing
	clr.b   (a1)+    ; Unused
	clr.w   (a1)+    ; Loop start
	move.l  a2, (a1) ; Start location

	rts

; ------------------------------------------------------------------------------

sound_pause:
	bset.b  #0, SOUNDRAM_flags ; Set "paused" flag

	; Fallthrough

; ------------------------------------------------------------------------------

sound_stop:
	clr.b   SOUNDRAM_stream_bgm+4 ; Playing
	clr.b   SOUNDRAM_stream_sfx+4 ; Playing
	clr.w   SOUNDRAM_locked_channels
	clr.b   SOUNDRAM_vibrato_enable

	; Fallthrough

; ------------------------------------------------------------------------------

; Breaks
;   d0-d1/a0
sound_silence_all_channels:
	; Silence all four PSG channels
	lea     PSG_DATA, a0
	move.b  #$9F, (a0)
	move.b  #$BF, (a0)
	move.b  #$DF, (a0)
	move.b  #$FF, (a0)

	move.w  #$FFFF, d0
	lea     SOUNDRAM_psg_instrs, a0
	move.w  d0, $06(a0)
	move.w  d0, $0E(a0)
	move.w  d0, $16(a0)
	move.w  d0, $1E(a0)

	z80_halt

	move.b  #Z80_CMD_STOP, Z80_STATUS_ADDR+1

	; Key off all FM channels
	move.w  #$28, d0 ; Word size in order to clear the part bit
	moveq   #0, d1
	bsr     ym_write
	moveq   #1, d1
	bsr     ym_write
	moveq   #2, d1
	bsr     ym_write
	moveq   #4, d1
	bsr     ym_write
	moveq   #5, d1
	bsr     ym_write
	moveq   #6, d1
	bsr     ym_write

	z80_resume

	rts

; ------------------------------------------------------------------------------

sound_update:
	z80_halt

	; Check if the Z80 is accessing the YM2612
	tst.b   Z80_STATUS_ADDR
	beq.s   .ym_available

	; Otherwise, resume the Z80, let it run for a short while, and try again
	z80_resume
	nop
	nop
	nop
	nop
	nop
	nop
	bra.s   sound_update

.ym_available:
	lea     SOUNDRAM_stream_bgm, a2
	tst.b   4(a2) ; Playing
	beq.s   .no_bgm
	bclr.b  #1, SOUNDRAM_flags ; Clear "handling SFX" flag
	bsr.s   sound_handle_events
.no_bgm:

	lea     SOUNDRAM_stream_sfx, a2
	tst.b   4(a2) ; Playing
	beq.s   .no_sfx
	bset.b  #1, SOUNDRAM_flags ; Set "handling SFX" flag
	bsr.s   sound_handle_events
.no_sfx:

	z80_resume

	bsr     sound_update_vibrato
	bra     sound_update_psg

; ------------------------------------------------------------------------------

; Input
;   a2.l - Stream location in RAM
sound_handle_events:
.next_event:
	; Check if we are currently in a delay
	tst.w   2(a2)     ; Delay
	beq.s   .no_delay

	; If so, decrease the delay and return
	subq.w  #1, 2(a2) ; Delay
	rts
.no_delay:

	moveq   #0, d0
	moveq   #0, d1
	moveq   #0, d2

	; Store address of next event in a0
	movea.l 8(a2), a0 ; Start position
	adda.w  (a2), a0  ; Position

	; Get next event
	move.b  (a0)+, d0

	; Check for a channel block, meaning we are handling music and the
	; channel is locked
	btst.b  #1, SOUNDRAM_flags ; Test "handling SFX" flag
	bne.s   .no_channel_block
	cmpi.b  #$50, d0
	bhs.s   .no_channel_block

	; Store channel number in d1
	move.b  d0, d1
	andi.w  #$0F, d1

	; Check if the channel is locked
	move.w  SOUNDRAM_locked_channels, d2
	btst.l  d1, d2
	beq.s   .no_channel_block

	; If the channel is locked, set the block flag (bit $10 of d0)
	bset.l  #$10, d0
.no_channel_block:

	moveq   #0, d2

	; Handle event
	cmpi.b  #$06, d0
	bls     .ev_note_on_fm
	cmpi.b  #$0A, d0
	bls     .ev_note_on_psg_tone
	cmpi.b  #$0B, d0
	beq     .ev_note_on_psg_noise
	cmpi.b  #$0C, d0
	beq     .ev_play_sample
	cmpi.b  #$16, d0
	bls     .ev_note_off_fm
	cmpi.b  #$1B, d0
	bls     .ev_note_off_psg
	cmpi.b  #$1C, d0
	bls     .ev_stop_sample
	cmpi.b  #$36, d0
	bls     .ev_set_freq_fm
	cmpi.b  #$3A, d0
	bls     .ev_set_freq_psg_tone
	cmpi.b  #$3B, d0
	beq     .ev_set_psg_noise_type
	cmpi.b  #$46, d0
	bls     .ev_set_instr_fm
	cmpi.b  #$4B, d0
	bls     .ev_set_instr_psg
	cmpi.b  #$BA, d0
	bls     .ev_enable_vibrato_psg
	cmpi.b  #$CA, d0
	bls     .ev_disable_vibrato_psg
	cmpi.b  #$DF, d0
	bls     .ev_delay_short
	cmpi.b  #$E6, d0
	bls     .ev_lock_channel_fm
	cmpi.b  #$EB, d0
	bls     .ev_lock_channel_psg
	cmpi.b  #$FC, d0
	beq     .ev_go_to_loop
	cmpi.b  #$FD, d0
	beq     .ev_set_loop_point
	cmpi.b  #$FE, d0
	beq     .ev_delay_long
	cmpi.b  #$FF, d0
	beq     .ev_stop

.ev_note_on_fm:
	; Advance to next event position
	addq.w  #2, (a2)

	; Check channel block
	btst.l  #$10, d0
	bne     .next_event

	; Move next parameter (the musical note) do d1
	move.b  (a0), d1

	; Keep octave in d2
	move.b  d1, d2
	andi.w  #$E0, d2
	lsl.w   #6, d2

	; Keep semitone in d1
	andi.w  #$1F, d1
	subq.w  #1, d1

	; Move note base frequency to d4
	lea     note_freqs_fm(pc), a0
	move.w  (a0, d1.w), d4

	; Apply octave
	add.w   d2, d4

	move.w  d0, d3     ; Channel number
	andi.w  #7, d3
	ori.w   #$0700, d3 ; Key off, key on, change frequency
	bsr     ym_update_freq

	bra     .next_event

.ev_note_on_psg_tone:
	; Advance to next event position
	addq.w  #2, (a2)

	; Check channel block
	btst.l  #$10, d0
	bne     .next_event

	; Move next parameter (the musical note) do d1
	move.b  (a0), d1

	; Keep channel number in d2
	move.b  d0, d2
	andi.w  #3, d2

	; Find frequency corresponding to note and store it in d1
	lea     note_freqs_psg(pc), a1
	move.w  (a1, d1.w), d1

	; Set base frequency for vibrato
	lea     SOUNDRAM_vibrato, a0
	move.w  d2, d0
	add.w   d0, d0
	add.w   d0, d0
	move.w  d1, (a0, d0.w)

	; Find address for channel within SOUNDRAM_psg_instrs
	lea     SOUNDRAM_psg_instrs, a0
	move.w  d2, d0
	lsl.w   #3, d0
	adda.w  d0, a0
	addq.w  #4, a0

	; Reset envelope
	clr.w   (a0)+

	; Set frequency
	move.w  d1, (a0)

	bra     .next_event

.ev_note_on_psg_noise:
	; Advance to next event position
	addq.w  #2, (a2)

	; Check channel block
	btst.l  #$10, d0
	bne     .next_event

	; Move next parameter (the noise type) do d1
	move.b  (a0), d1
	andi.w  #$FFFF, d1
	ori.b   #$E0, d1

	; Store the address for the noise channel within SOUNDRAM_psg_instrs
	; in a0
	lea     SOUNDRAM_psg_instrs+$1C, a0

	; Reset envelope
	clr.w   (a0)+

	; Set noise type
	move.w  d1, (a0)

	bra     .next_event

.ev_play_sample:
	; Advance to next event position
	addq.w  #2, (a2)

	; Move next parameter (the sample number) do d2
	move.b  (a0), d2

	; Move sample address to d0
	move.b  d2, d0
	lea     DATA_samples_list, a0
	add.w   d0, d0
	add.w   d0, d0
	move.l  (a0, d0.w), d0

	; Command the Z80 driver to play a sample
	lea     Z80_STATUS_ADDR+1, a0
	move.b  #Z80_CMD_PLAY, (a0)+

	; Write sample address
	move.b  d0, (a0)+
	lsr.l   #8, d0
	move.b  d0, (a0)+
	lsr.l   #8, d0
	move.b  d0, (a0)+

	bra     .next_event

.ev_note_off_fm:
	; Advance to next event position
	addq.w  #1, (a2)

	; Check channel block
	btst.l  #$10, d0
	bne     .next_event

	; Keep channel number in d0
	andi.w  #7, d0

	move.w  d0, d3
	ori.w   #$0100, d3 ; Key off, no key on, no frequency change
	bsr     ym_update_freq

	bra     .next_event

.ev_note_off_psg:
	; Advance to next event position
	addq.w  #1, (a2)

	; Check channel block
	btst.l  #$10, d0
	bne     .next_event

	; Keep channel number in d2
	move.b  d0, d2
	andi.w  #3, d2

	; Find the address for the channel within SOUNDRAM_psg_instrs
	lea     SOUNDRAM_psg_instrs, a0
	move.w  d2, d0
	lsl.w   #3, d0
	adda.w  d0, a0
	addq.w  #4, a0

	; Reset envelope
	clr.w   (a0)+

	; Set channel's frequency to $FFFF, meaning silence
	move.w  #$FFFF, (a0)

	; No vibrato if it is the noise channel
	cmpi.w  #3, d2
	beq     .next_event

	; Clear vibrato base frequency
	lea     SOUNDRAM_vibrato, a0
	move.w  d2, d0
	add.w   d0, d0
	add.w   d0, d0
	clr.w   (a0, d0.w)

	bra     .next_event

.ev_stop_sample:
	; Advance to next event position
	addq.w  #1, (a2)

	move.b  #Z80_CMD_STOP, Z80_STATUS_ADDR+1

	bra     .next_event

.ev_set_freq_fm:
	; Advance to next event position
	addq.w  #3, (a2)

	; Check channel block
	btst.l  #$10, d0
	bne     .next_event

	; Move next parameter (the frequency) to d4 (two bytes)
	move.b  (a0)+, d4
	lsl.w   #8, d4
	move.b  (a0), d4

	move.w  d0, d3
	andi.w  #7, d3
	ori.w   #$0400, d3 ; No key on, no key off, change frequency
	bsr     ym_update_freq

	bra     .next_event

.ev_set_freq_psg_tone:
	; Advance to next event position
	addq.w  #3, (a2)

	; Check channel block
	btst.l  #$10, d0
	bne     .next_event

	; Move next parameter (the frequency) to d1 (two bytes)
	move.b  1(a0), d1
	lsl.w   #4, d1
	or.b    (a0), d1

	; Keep channel number in d2
	move.b  d0, d2
	andi.w  #3, d2

	; Set base frequency for vibrato
	lea     SOUNDRAM_vibrato, a0
	move.w  d2, d0
	add.w   d0, d0
	add.w   d0, d0
	move.w  d1, (a0, d0.w)

	; Find address for channel within SOUNDRAM_psg_instrs
	lea     SOUNDRAM_psg_instrs, a0
	move.w  d2, d0
	lsl.w   #3, d0
	adda.w  d0, a0
	addq.w  #6, a0

	; Set frequency
	move.w  d1, (a0)

	bra     .next_event

.ev_set_psg_noise_type:
	; Advance to next event position
	addq.w  #2, (a2)

	; Check channel block
	btst.l  #$10, d0
	bne     .next_event

	; Move next parameter (the noise type) to d0
	move.b  (a0), d1
	ori.b   #$E0, d1

	; Store the address for the channel's next noise in a0
	lea     SOUNDRAM_psg_instrs+$1E, a0

	; Store noise type
	move.w  d1, (a0)

	bra     .next_event

.ev_set_instr_fm:
	; Advance to next event position
	addq.w  #2, (a2)

	; Move next parameter (the instrument number) do d1
	move.b  (a0), d1

	; Keep channel number in d0
	andi.w  #7, d0

	btst.b  #1, SOUNDRAM_flags ; Test "handling SFX" flag
	bne.s   .ev_set_instr_fm_not_bgm

	; Store instrument number
	lea     SOUNDRAM_instrs, a0
	move.b  d1, (a0, d0.w)
.ev_set_instr_fm_not_bgm:

	; Check channel block
	btst.l  #$10, d0
	bne     .next_event

	bsr     ym_load_instr

	bra     .next_event

.ev_set_instr_psg:
	; Advance to next event position
	addq.w  #2, (a2)

	; Move next parameter (the instrument number) to d1
	move.b  (a0), d1

	; Keep channel number in d0
	andi.w  #3, d0

	btst.b  #1, SOUNDRAM_flags ; Test "handling SFX" flag
	bne.s   .ev_set_instr_psg_not_bgm

	; Store instrument number
	lea     SOUNDRAM_instrs+8, a0
	move.b  d1, (a0, d0.w)
.ev_set_instr_psg_not_bgm:

	; Check channel block
	btst.l  #$10, d0
	bne     .next_event

	bsr     psg_load_instr

	bra     .next_event

.ev_enable_vibrato_psg:
	; Advance to next event position
	addq.w  #1, (a2)

	; Keep channel number in d2
	move.w  d0, d2
	andi.w  #7, d2

	; Enable vibrato
	bset.b  d2, SOUNDRAM_vibrato_enable

	; Reset vibrato position
	lea     SOUNDRAM_vibrato, a0
	move.w  d2, d0
	add.w   d0, d0
	add.w   d0, d0
	clr.b   (a0, d0.w)

	bra     .next_event

.ev_disable_vibrato_psg:
	; Advance to next event position
	addq.w  #1, (a2)

	; Keep channel number in d2
	move.w  d0, d2
	andi.w  #7, d2

	; Disable vibrato
	bclr.b  d2, SOUNDRAM_vibrato_enable

	bra     .next_event

.ev_delay_short:
	; Advance to next event position
	addq.w  #1, (a2)

	; Keep the delay in d0
	andi.w  #$0F, d0

	; Check if the delay needs to be corrected, which is the case if the
	; system is PAL and the BGM stream is the one being handled
	btst.b  #2, SOUNDRAM_flags ; PAL system
	beq.s   .ev_delay_short_no_correction
	btst.b  #1, SOUNDRAM_flags ; Handling the BGM stream
	bne.s   .ev_delay_short_no_correction

	lea     pal_delay_correction(pc), a0
	sub.b   (a0, d0.w), d0
.ev_delay_short_no_correction:

	; Set the delay
	move.w  d0, 2(a2) ; Ticks

	bra     .next_event

.ev_lock_channel_fm:
	andi.w  #$07, d0
	bset.b  d0, SOUNDRAM_locked_channels+1

	bra     .ev_note_off_psg

.ev_lock_channel_psg:
	andi.w  #3, d0
	bset.b  d0, SOUNDRAM_locked_channels

	bra     .ev_note_off_psg

.ev_go_to_loop:
	; Move loop start position to current position
	move.w  6(a2), (a2)

	; Advance to next event position
	addq.w  #1, (a2)

	bra     .next_event

.ev_set_loop_point:
	; Move current position to loop start position
	move.w  (a2), 6(a2)

	; Advance to next event position
	addq.w  #1, (a2)

	bra     .next_event

.ev_delay_long:
	; Advance to next event position
	addq.w  #2, (a2)

	; Set the delay
	moveq   #0, d0
	move.b  (a0), d0
	move.w  d0, 2(a2) ; Ticks

	bra     .next_event

.ev_stop:
	; If a sound effect has stopped, unlock all channels
	btst.b  #1, SOUNDRAM_flags ; Test "handling SFX" flag
	beq.s   .ev_stop_not_sfx
	bsr.s   sound_stop_sfx
.ev_stop_not_sfx:

	clr.b   4(a2) ; Playing
	rts

; ------------------------------------------------------------------------------

; Breaks
;   d0-d3/a0-a1
sound_stop_sfx:
	move.b  SOUNDRAM_locked_channels+1, d3

	; Restore instruments

	moveq   #0, d0
	btst.l  d0, d3
	beq.s   .fm_chan2
	bsr     restore_fm_instr

.fm_chan2:
	moveq   #1, d0
	btst.l  d0, d3
	beq.s   .fm_chan3
	bsr     restore_fm_instr

.fm_chan3:
	moveq   #2, d0
	btst.l  d0, d3
	beq.s   .fm_chan4
	bsr     restore_fm_instr

.fm_chan4:
	moveq   #4, d0
	btst.l  d0, d3
	beq.s   .fm_chan5
	bsr     restore_fm_instr

.fm_chan5:
	moveq   #5, d0
	btst.l  d0, d3
	beq.s   .fm_chan6
	bsr     restore_fm_instr

.fm_chan6:
	moveq   #6, d0
	btst.l  d0, d3
	beq.s   .psg
	bsr     restore_fm_instr

.psg:
	move.b  SOUNDRAM_locked_channels, d3

	moveq   #0, d0
	btst.l  d0, d3
	beq.s   .psg_chan2
	bsr.s   restore_psg_instr

.psg_chan2:
	moveq   #1, d0
	btst.l  d0, d3
	beq.s   .psg_chan3
	bsr.s   restore_psg_instr

.psg_chan3:
	moveq   #2, d0
	btst.l  d0, d3
	beq.s   .psg_chan4
	bsr.s   restore_psg_instr

.psg_chan4:
	moveq   #3, d0
	btst.l  d0, d3
	beq.s   .ret
	bsr.s   restore_psg_instr

.ret:
	clr.w   SOUNDRAM_locked_channels
	clr.b   SOUNDRAM_stream_sfx+4 ; Playing

	rts

; ------------------------------------------------------------------------------

; Subroutine to restore a PSG instrument used by the BGM track when a sound
; effect ends
;
; Input
;   d0.b - Channel number
;
; Breaks
;   d1-d2/a0
restore_psg_instr:
	; Silence channel
	moveq   #0, d1
	move.b  d0, d1
	add.w   d1, d1
	add.w   d1, d1
	add.w   d1, d1
	lea     SOUNDRAM_psg_instrs+6, a0
	move.w  #$FFFF, (a0, d1.w)

	moveq   #0, d1
	lea     SOUNDRAM_instrs+8, a0
	move.b  (a0, d0.w), d1

	; Fallthrough

; ------------------------------------------------------------------------------

; Input
;   d0.b - Channel number
;   d1.w - Instrument number
;
; Breaks
;   d1-d2/a0
psg_load_instr:
	; Store envelope location in d2
	lea     DATA_psg_instr_list, a0
	add.w   d1, d1
	add.w   d1, d1
	move.l  (a0, d1.w), d2

	; Find RAM offset for PSG channel status and store it in a0
	lea SOUNDRAM_psg_instrs, a0
	moveq   #0, d1
	move.b  d0, d1
	add.w   d1, d1
	add.w   d1, d1
	add.w   d1, d1
	adda.w  d1, a0

	; Store envelope location in PSG channel status
	move.l  d2, (a0)+

	; Clear envelope current and loop position
	clr.w   (a0)+

	; Silence channel
	move.w  #$FFFF, (a0)

	rts

; ------------------------------------------------------------------------------

; Subroutine to restore an FM instrument used by the BGM track when a sound
; effect ends
;
; Input
;   d0.w - channel number
;
; Breaks
;   d0-d2/a0-a1
restore_fm_instr:
	moveq   #0, d1
	lea     SOUNDRAM_instrs, a0
	move.b  (a0, d0.w), d1

	; Fallthrough

; ------------------------------------------------------------------------------

; Input
;   d0.w - Channel number (0-2, 4-6)
;   d1.w - Instrument number
;
; Breaks
;   d0-d2/a0-a1
ym_load_instr:
	; Point a1 to instrument data (in EIF format)
	lea     DATA_fm_instr_list, a1
	add.w   d1, d1
	add.w   d1, d1
	movea.l (a1, d1.w), a1

	; Key off
	move.w  d0, d1
	move.w  #$28, d0
	bsr     ym_write

	; Store channel number in d2
	moveq   #0, d2
	move.b  d1, d2

	; Check if the channel is in part II
	btst.l  #2, d2
	beq.s   .not_part_ii

	; If so, keep the channel number within the part in the lower byte and
	; set bit #8
	andi.w  #3, d2
	bset.l  #8, d2
.not_part_ii:

	moveq   #0, d0
	moveq   #0, d1

	; Feedback
	move.b  #$B0, d0
	or.w    d2, d0   ; Channel number and part
	move.b  (a1)+, d1
	bsr.s   ym_write

	move.b  #$30, d0 ; First YM2612 register to write to
	or.w    d2, d0   ; Channel number and part

	move.l  #27, d2  ; Number of registers to write minus one
.loop:
	move.b  (a1)+, d1
	bsr.s   ym_write
	addi.b  #4, d0
	dbf     d2, .loop

	rts

; ------------------------------------------------------------------------------

; Subroutine that changes the frequency and does a key on/key off on the YM2612
;
; Input
;   d3.w - The lower byte holds the channel number (0-2, 4-6), while bits 8-A
;          determine the actions to be performed:
;            #8 - Key off
;            #9 - Key on
;            #A - Change frequency
;   d4.w - Frequency (if bit A of d3 is set)
;
; Breaks
;   d0-d2/a0
ym_update_freq:
	; Channel number within part (0-2)
	move.b  d3, d2
	andi.w  #3, d2

	; Determine part
	btst.l  #2, d3
	beq.s   .not_part_ii
	bset.l  #8, d2
.not_part_ii:

	; Determine if a key off should be performed
	btst.l  #8, d3
	beq.s   .skip_key_off

	; Key off
	moveq   #0, d0
	move.b  #$28, d0
	move.b  d3, d1 ; Channel number
	bsr.s   ym_write
.skip_key_off:

	; Determine if a frequency change should be performed
	btst.l  #$A, d3
	beq.s   .skip_freq_change

	; High bits of frequency
	move.w  d4, d1
	asr.w   #8, d1
	andi.w  #$3F, d1
	moveq   #0, d0
	move.w  d2, d0 ; Channel number and part
	or.b    #$A4, d0
	bsr.s   ym_write

	; Low bits of frequency
	move.w  d4, d1
	andi.w  #$FF, d1
	move.w  d2, d0 ; Channel number and part
	or.b    #$A0, d0
	bsr.s   ym_write
.skip_freq_change:

	; Determine if a key on should be performed
	btst.l  #9, d3
	beq.s   .skip_key_on

	; Key on
	moveq   #0, d0 ; Clear part bit
	move.b  #$28, d0
	move.b  #$F0, d1
	add.b   d3, d1 ; Channel number
	bsr.s   ym_write
.skip_key_on:

	rts

; ------------------------------------------------------------------------------

; Input
;   d0.w - Register number on lower byte; bit #8 to select part (I or II)
;   d1.w - Value to write
;
; Breaks
;   a0
ym_write:
	lea     FM_DATA, a0 ; Data port

	btst.l  #8, d0
	beq.s   .not_part_ii
	addq.w  #2, a0
.not_part_ii:

.wait1:
	btst.b  #7, FM_DATA
	bne.s   .wait1    ; Wait while the YM2612 is busy
	move.b  d0, (a0)+ ; Write register number

.wait2:
	btst.b  #7, FM_DATA
	bne.s   .wait2    ; Wait while the YM2612 is busy
	move.b  d1, (a0)  ; Write value to register

	rts

; ------------------------------------------------------------------------------

sound_update_vibrato:
	lea     SOUNDRAM_vibrato, a0
	lea     SOUNDRAM_psg_instrs, a1
	lea     psg_vibrato_table(pc), a2
	moveq   #0, d1     ; Channel number (0, 1, 2)
	moveq   #(3-1), d2 ; Number of PSG tone channels minus one
.channels_loop:
	; Skip channel if vibrato is not enabled on it
	btst.b  d1, SOUNDRAM_vibrato_enable
	beq.s   .next_channel

	; Skip channel if it is silent
	tst.w   (a0)
	beq.s   .next_channel

	; Apply vibrato
	move.w  d1, d0
	add.w   d0, d0
	add.w   d0, d0
	move.w  2(a0, d0.w), d0
	add.w   d0, d0
	move.w  (a2, d0.w), d0
	add.w   (a0), d0
	move.w  d0, 6(a1)

	; Advance vibrato position
	addq.w  #1, 2(a0)
	andi.w  #7, 2(a0)

.next_channel:
	addq.w  #1, d1
	addq.w  #4, a0
	addq.w  #8, a1
	dbf     d2, .channels_loop

	rts

; ------------------------------------------------------------------------------

sound_update_psg:
	lea     PSG_DATA, a1
	lea     SOUNDRAM_psg_instrs, a2
	moveq   #0, d3     ; Store PSG channel ($00, $20, $40, $60) in d3
	moveq   #(4-1), d4 ; Number of PSG channels minus one

.update_psg_channel:
	; If the current channel has no envelope, skip it
	tst.l   (a2)
	beq     .next_channel

	; Store new frequency in d1
	move.w  6(a2), d1

	; If there is no new frequency, skip
	tst.w   d1
	beq.s   .advance_envelope

	; Check for silent channel
	cmpi.w  #$FFFF, d1
	bne.s   .no_silence

	; Silence PSG channel
	move.b  d3, d0
	ori.b   #$9F, d0
	move.b  d0, (a1)

	bra.s   .next_channel

.no_silence:
	; Check if it is the noise channel (last iteration of the loop)
	tst.w   d4
	beq.s   .noise_channel

	; Otherwise, it is a tone channel

	; Write the new frequency value on the PSG
	move.w  d1, d2
	andi.w  #$0F, d2
	move.b  d3, d0
	or.b    d2, d0
	ori.b   #$80, d0
	move.b  d0, (a1)
	lsr.w   #4, d1
	move.b  d1, (a1)

	bra.s   .reset_new_note

.noise_channel:
	; Write the new noise type value on the PSG
	move.b  d1, d0
	ori.b   #$E0, d0
	move.b  d0, (a1)

.reset_new_note:
	clr.w   6(a2)

.advance_envelope:
	; Store current envelope position in d2
	moveq   #0, d2
	move.b  5(a2), d2

	; Find next envelope value and store it in d1
	movea.l (a2), a0
	adda.w  d2, a0
	moveq   #0, d1
	move.b  (a0), d1

	; Check if it is a loop start ($FE) or restart ($FF)
	cmpi.b  #$FE, d1
	beq.s   .set_loop_point
	cmpi.b  #$FF, d1
	beq.s   .go_to_loop
	bra.s   .set_volume

.set_loop_point:
	; Advance envelope position
	addq.b  #1, d2
	move.b  d2, 4(a2) ; Store loop position
	move.b  d2, 5(a2)
	bra.s   .advance_envelope

.go_to_loop:
	; Move back to loop start
	move.b  4(a2), d2
	move.b  d2, 5(a2)
	bra.s   .advance_envelope

.set_volume:
	; Write the new volume value on the PSG
	move.b  d3, d0
	or.b    d1, d0
	ori.b   #$90, d0
	move.b  d0, (a1)

	; Advance envelope position
	addq.b  #1, d2
	move.b  d2, 5(a2)

.next_channel:
	addq.w  #8, a2
	addi.b  #$20, d3
	dbf     d4, .update_psg_channel

	rts

; ------------------------------------------------------------------------------

psg_vibrato_table:
	dc.w    0
	dc.w    2
	dc.w    4
	dc.w    2
	dc.w    0
	dc.w    -2
	dc.w    -4
	dc.w    -2

; Value to be subtracted from each possible short delay (0-15) to prevent slower
; music on a PAL system
;
; Note: only delays found in the game's soundtrack have been tested
pal_delay_correction:
	dc.b    0
	dc.b    0
	dc.b    0
	dc.b    0
	dc.b    0
	dc.b    1
	dc.b    1
	dc.b    1
	dc.b    1
	dc.b    1
	dc.b    2
	dc.b    2
	dc.b    2
	dc.b    2
	dc.b    2
	dc.b    2

note_freqs_fm:
	dc.w    644  ; C
	dc.w    681  ; C#
	dc.w    722  ; D
	dc.w    765  ; D#
	dc.w    810  ; E
	dc.w    858  ; F
	dc.w    910  ; F#
	dc.w    964  ; G
	dc.w    1021 ; G#
	dc.w    1081 ; A
	dc.w    1146 ; A#
	dc.w    1214 ; B

note_freqs_psg:
	; Octave 3
	dc.w    851  ; C
	dc.w    803  ; C#
	dc.w    758  ; D
	dc.w    715  ; D#
	dc.w    675  ; E
	dc.w    637  ; F
	dc.w    601  ; F#
	dc.w    568  ; G
	dc.w    536  ; G#
	dc.w    506  ; A
	dc.w    477  ; A#
	dc.w    450  ; B

	; Octave 4
	dc.w    425  ; C
	dc.w    401  ; C#
	dc.w    379  ; D
	dc.w    357  ; D#
	dc.w    337  ; E
	dc.w    318  ; F
	dc.w    300  ; F#
	dc.w    284  ; G
	dc.w    268  ; G#
	dc.w    253  ; A
	dc.w    238  ; A#
	dc.w    225  ; B

	; Octave 5
	dc.w    212  ; C
	dc.w    200  ; C#
	dc.w    189  ; D
	dc.w    178  ; D#
	dc.w    168  ; E
	dc.w    159  ; F
	dc.w    150  ; F#
	dc.w    142  ; G
	dc.w    134  ; G#
	dc.w    126  ; A
	dc.w    119  ; A#
	dc.w    112  ; B

	; Octave 6
	dc.w    106  ; C
	dc.w    100  ; C#
	dc.w    94   ; D
	dc.w    89   ; D#
	dc.w    84   ; E
	dc.w    79   ; F
	dc.w    75   ; F#
	dc.w    71   ; G
	dc.w    67   ; G#
	dc.w    63   ; A
	dc.w    59   ; A#
	dc.w    56   ; B

	; Octave 7
	dc.w    53   ; C
	dc.w    50   ; C#
	dc.w    47   ; D
	dc.w    44   ; D#
	dc.w    42   ; E
	dc.w    39   ; F
	dc.w    37   ; F#
	dc.w    35   ; G
	dc.w    33   ; G#
	dc.w    31   ; A
	dc.w    29   ; A#
	dc.w    28   ; B

	; Octave 8
	dc.w    26   ; C
	dc.w    25   ; C#
	dc.w    23   ; D
	dc.w    22   ; D#
	dc.w    21   ; E
	dc.w    19   ; F
	dc.w    18   ; F#
	dc.w    17   ; G
	dc.w    16   ; G#
	dc.w    15   ; A
	dc.w    14   ; A#
	dc.w    14   ; B

z80_driver:
	incbin  'z80/z80.bin'
z80_driver_end:
	even

