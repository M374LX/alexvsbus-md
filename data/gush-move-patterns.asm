DATA_gush_move_patterns:
	dc.w    (DATA_gush_move_pattern_1-DATA_gush_move_patterns)
	dc.w    (DATA_gush_move_pattern_2-DATA_gush_move_patterns)

; For each pair of values, the first value is an absolute short pointer to a RAM
; address containing the vertical velocity (yvel) and the second value is the
; destination Y position (ydest)
;
; The value zero indicates the end of the pattern
DATA_gush_move_pattern_1:
	dc.w    FPSVAL_M60_PXS,  224, FPSVAL_60_PXS,  232
	dc.w    FPSVAL_M60_PXS,  224, FPSVAL_60_PXS,  232
	dc.w    FPSVAL_M60_PXS,  224, FPSVAL_60_PXS,  232
	dc.w    FPSVAL_M60_PXS,  224, FPSVAL_60_PXS,  232
	dc.w    FPSVAL_M60_PXS,  224, FPSVAL_60_PXS,  232
	dc.w    FPSVAL_M144_PXS, 200, FPSVAL_144_PXS, 232
	dc.w    0

DATA_gush_move_pattern_2:
	dc.w    FPSVAL_M60_PXS,  216, FPSVAL_60_PXS,  224
	dc.w    0

