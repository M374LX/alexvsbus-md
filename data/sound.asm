DATA_bgm_list:
	dc.l bgm1
	dc.l bgm2
	dc.l bgm3
	dc.l bgmtitle

DATA_sfx_list:
	dc.l sfx_coin
	dc.l sfx_crate
	dc.l sfx_fall
	dc.l sfx_hit
	dc.l sfx_hole
	dc.l sfx_respawn
	dc.l sfx_score
	dc.l sfx_select
	dc.l sfx_slip
	dc.l sfx_spring
	dc.l sfx_time

DATA_fm_instr_list:
	dc.l instr_silence
	dc.l instr_bass
	dc.l instr_lead
	dc.l 0
	dc.l 0
	dc.l 0
	dc.l 0
	dc.l 0
	dc.l 0
	dc.l 0
	dc.l 0
	dc.l 0
	dc.l 0
	dc.l 0
	dc.l 0
	dc.l 0

DATA_psg_instr_list:
	dc.l psg_instr_00
	dc.l psg_instr_01
	dc.l psg_instr_02
	dc.l 0
	dc.l 0
	dc.l 0
	dc.l 0
	dc.l 0
	dc.l 0
	dc.l 0
	dc.l 0
	dc.l 0
	dc.l 0
	dc.l 0
	dc.l 0
	dc.l 0
	dc.l psg_instr_10
	dc.l psg_instr_11
	dc.l psg_instr_12
	dc.l psg_instr_13
	dc.l psg_instr_14
	dc.l psg_instr_15
	dc.l psg_instr_16
	dc.l psg_instr_17
	dc.l psg_instr_18
	dc.l psg_instr_19
	dc.l psg_instr_1A

DATA_samples_list:
	dc.l sample_kick
	dc.l sample_snare

; ------------------------------------------------------------------------------

bgm1:
	incbin 'data/bgm1.bin'
	even

bgm2:
	incbin 'data/bgm2.bin'
	even

bgm3:
	incbin 'data/bgm3.bin'
	even

bgmtitle:
	incbin 'data/bgmtitle.bin'
	even

sfx_coin:
	incbin 'data/sfx-coin.bin'
	even

sfx_crate:
	incbin 'data/sfx-crate.bin'
	even

sfx_fall:
	incbin 'data/sfx-fall.bin'
	even

sfx_hit:
	incbin 'data/sfx-hit.bin'
	even

sfx_hole:
	incbin 'data/sfx-hole.bin'
	even

sfx_respawn:
	incbin 'data/sfx-respawn.bin'
	even

sfx_score:
	incbin 'data/sfx-score.bin'
	even

sfx_select:
	incbin 'data/sfx-select.bin'
	even

sfx_slip:
	incbin 'data/sfx-slip.bin'
	even

sfx_spring:
	incbin 'data/sfx-spring.bin'
	even

sfx_time:
	incbin 'data/sfx-time.bin'
	even

instr_silence:
	incbin 'data/silence.eif'
	even

instr_bass:
	incbin 'data/bass.eif'
	even

instr_lead:
	incbin 'data/lead.eif'
	even

psg_instr_00:
	incbin 'data/silence.eef'
	even

psg_instr_01:
	incbin 'data/psg1.eef'
	even

psg_instr_02:
	incbin 'data/psg2.eef'
	even

psg_instr_10:
	incbin 'data/coin.eef'
	even

psg_instr_11:
	incbin 'data/crate.eef'
	even

psg_instr_12:
	incbin 'data/fall.eef'
	even

psg_instr_13:
	incbin 'data/hit.eef'
	even

psg_instr_14:
	incbin 'data/hole.eef'
	even

psg_instr_15:
	incbin 'data/respawn.eef'
	even

psg_instr_16:
	incbin 'data/score.eef'
	even

psg_instr_17:
	incbin 'data/select.eef'
	even

psg_instr_18:
	incbin 'data/slip.eef'
	even

psg_instr_19:
	incbin 'data/spring.eef'
	even

psg_instr_1A:
	incbin 'data/time.eef'
	even

sample_kick:
	incbin 'data/kick.ewf'
	even

sample_snare:
	incbin 'data/snare.ewf'
	even

