DATA_gush_move_patterns:
	dc.w (DATA_gush_move_pattern_1-DATA_gush_move_patterns)
	dc.w (DATA_gush_move_pattern_2-DATA_gush_move_patterns)

; For each pair of values, the first value is the vertical velocity (yvel)
; and the second value is the destination Y position (ydest)
;
; The value zero indicates the end of the pattern
;
; TODO: PAL values
DATA_gush_move_pattern_1:
	dc.l -65536,  224, 65536,  232
	dc.l -65536,  224, 65536,  232
	dc.l -65536,  224, 65536,  232
	dc.l -65536,  224, 65536,  232
	dc.l -65536,  224, 65536,  232
	dc.l -157286, 200, 157286, 232
	dc.l 0

DATA_gush_move_pattern_2:
	dc.l -65536,  216, 65536,  224
	dc.l 0

