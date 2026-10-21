; Level blocks for each hole type in a column
DATA_level_column_hole_blocks:
	; Type 0 - None (normal floor)
	dc.w    $0040, $0050, $0060, $0060, $0060, $0060, $0000, $0000

	; Type 1 - Deep hole left
	dc.w    $0070, $0080, $0090, $0090, $0090, $0090, $0000, $0000

	; Type 2 - Deep hole middle
	dc.w    $00A0, $00B0, $00C0, $00C0, $00C0, $00C0, $0000, $0000

	; Type 3 - Deep hole right
	dc.w    $00D0, $00E0, $00F0, $00F0, $00F0, $00F0, $0000, $0000

	; Type 4 - Passageway left
	dc.w    $0100, $0110, $0120, $0120, $0120, $0060, $0000, $0000

	; Type 5 - Passageway middle
	dc.w    $0040, $0130, $00C0, $00C0, $00C0, $0060, $0000, $0000

	; Type 6 - Passageway right
	dc.w    $0140, $0150, $00F0, $00F0, $00F0, $0060, $0000, $0000

