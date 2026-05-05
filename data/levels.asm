DATA_levels:
	; Normal difficulty
	dc.w 0
	dc.w (DATA_level1n-DATA_levels)
	dc.w (DATA_level2n-DATA_levels)
	dc.w (DATA_level3n-DATA_levels)
	dc.w (DATA_level4n-DATA_levels)
	dc.w (DATA_level5n-DATA_levels)
	dc.w 0
	dc.w 0

	; Hard difficulty
	dc.w 0
	dc.w (DATA_level1h-DATA_levels)
	dc.w (DATA_level2h-DATA_levels)
	dc.w (DATA_level3h-DATA_levels)
	dc.w (DATA_level4h-DATA_levels)
	dc.w (DATA_level5h-DATA_levels)
	dc.w 0
	dc.w 0

	; Super difficulty
	dc.w 0
	dc.w (DATA_level1s-DATA_levels)
	dc.w (DATA_level2s-DATA_levels)
	dc.w (DATA_level3s-DATA_levels)
	dc.w 0
	dc.w 0
	dc.w 0
	dc.w 0

DATA_level1n:
	incbin 'data/level1n.bin'
	even

DATA_level2n:
	incbin 'data/level2n.bin'
	even

DATA_level3n:
	incbin 'data/level3n.bin'
	even

DATA_level4n:
	incbin 'data/level4n.bin'
	even

DATA_level5n:
	incbin 'data/level5n.bin'
	even

DATA_level1h:
	incbin 'data/level1h.bin'
	even

DATA_level2h:
	incbin 'data/level2h.bin'
	even

DATA_level3h:
	incbin 'data/level3h.bin'
	even

DATA_level4h:
	incbin 'data/level4h.bin'
	even

DATA_level5h:
	incbin 'data/level5h.bin'
	even

DATA_level1s:
	incbin 'data/level1s.bin'
	even

DATA_level2s:
	incbin 'data/level2s.bin'
	even

DATA_level3s:
	incbin 'data/level3s.bin'
	even

