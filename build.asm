	include 'src/constants.asm'
	include 'src/ram.asm'

	include 'src/header.asm'
	include 'src/startup.asm'
	include 'src/interrupts.asm'
	include 'src/z80ctrl.asm'
	include 'src/main.asm'
	include 'src/menu.asm'
	include 'src/play.asm'
	include 'src/renderer.asm'
	include 'src/sound.asm'

	include 'data/sprite-constants.asm'
	include 'data/luts.asm'
	include 'data/fps-values.asm'
	include 'data/menu.asm'
	include 'data/cheat.asm'
	include 'data/palettes.asm'
	include 'data/sky-colors.asm'
	include 'data/obj-bounding-boxes.asm'
	include 'data/gush-move-patterns.asm'
	include 'data/levels.asm'
	include 'data/vehicle-types.asm'
	include 'data/spritemaps.asm'
	include 'data/animation.asm'
	include 'data/level-columns.asm'
	include 'data/level-blocks.asm'
	include 'data/tilemaps.asm'
	include 'data/tilesets.asm'
	include 'data/sound.asm'

	; Pad the ROM to 512 kB
	dcb.b   $07FFFE-*, 0
	dc.w    0

